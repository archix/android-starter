# Android Project — Claude Code Guide

> **For AI assistants:** Read this entire file before writing any code. Every rule here exists to prevent spaghetti code. When in doubt, follow the pattern already established in the codebase rather than inventing a new one.

---

## Project Overview

This is an Android app built with **Kotlin** and **Jetpack Compose**. The codebase follows **Clean Architecture** with **MVVM + Unidirectional Data Flow (UDF)**. All UI comes from Figma designs — never invent UI without a Figma reference.

**SDK targets:**
- `minSdk = 29` (Android 10)
- `targetSdk = 35` (Android 15)
- `compileSdk = 35`

---

## Tech Stack (Non-Negotiable)

| Concern | Library |
|---|---|
| UI | Jetpack Compose + Material 3 |
| Navigation | Compose Navigation (type-safe routes) |
| Dependency Injection | Hilt |
| Async / Reactive | Kotlin Coroutines + Flow |
| Networking | Retrofit + OkHttp |
| JSON | Kotlinx Serialization |
| Image Loading | Coil 3 |
| Local Storage | Room |
| State/Lifecycle | ViewModel + `StateFlow` |
| Build Config | Gradle Version Catalog (`libs.versions.toml`) |
| Testing | JUnit 6 + MockK + Turbine |

**Do not introduce new libraries without discussion.** If you need something that isn't here, flag it rather than reaching for a different library.

---

## Project Structure

```
app/src/main/java/com/starter/app/
├── core/
│   ├── designsystem/          # ALL design tokens, themes, and shared UI atoms
│   │   ├── color/             # AppColors.kt
│   │   ├── typography/        # AppTypography.kt
│   │   ├── shape/             # AppShapes.kt
│   │   ├── spacing/           # AppSpacing.kt
│   │   ├── icon/              # AppIcons.kt
│   │   ├── component/         # Reusable atomic components (Button, TextField, Avatar...)
│   │   └── theme/             # AppTheme.kt — entry point for MaterialTheme
│   ├── extensions/            # Kotlin extension functions
│   └── utils/                 # Pure utility classes
├── data/
│   ├── local/                 # Room DAOs, entities, database
│   ├── remote/                # Retrofit APIs, DTOs
│   └── repository/            # Repository implementations
├── domain/
│   ├── model/                 # Domain models (NO Android imports here)
│   ├── repository/            # Repository interfaces
│   └── usecase/               # Use cases
└── feature/
    └── [feature_name]/
        ├── ui/                # Composables: XxxScreen.kt, XxxComponents.kt
        └── viewmodel/         # XxxViewModel.kt, XxxUiState.kt, XxxEvent.kt
```

---

## Figma-First Development Rule

**Never design UI from scratch.** Every screen and component must come from Figma.

### Workflow for every new screen or component

1. **Ask for the Figma node URL** before writing any UI code.
2. **Fetch the design via MCP** — use the Figma MCP tool to get exact specs (colors, spacing, typography, corner radii, shadows).
3. **Map Figma tokens to design system tokens** — never hardcode values you get from Figma. If a value doesn't have a token yet, create one in the appropriate `AppXxx.kt` file.
4. **Build the composable** following the component patterns in this file.
5. **Cross-check with screenshot** — use the Figma MCP screenshot tool to visually compare your implementation.

### Reading Figma output

When Figma MCP returns design data:
- Colors → map to `AppColors` or `MaterialTheme.colorScheme.*`
- Text styles → map to `AppTypography` or `MaterialTheme.typography.*`
- Spacing/padding values → map to `AppSpacing.*`
- Corner radius → map to `AppShapes.*`
- Icons → check `AppIcons` first; add there if missing

**If a Figma value has no token, create the token. Never hardcode the raw value.**

---

## Design System

The design system lives entirely in `core/designsystem/`. It is the single source of truth for every visual decision. **Nothing outside this package should contain raw colors, sizes, or text styles.**

### AppColors

```kotlin
// core/designsystem/color/AppColors.kt
object AppColors {
    val Primary = Color(0xFF6200EE)         // from Figma token: color/primary
    val OnPrimary = Color(0xFFFFFFFF)
    val Surface = Color(0xFFFFFFFF)
    val OnSurface = Color(0xFF1C1B1F)
    // Dark variants
    val PrimaryDark = Color(0xFFBB86FC)
    // Add tokens as you encounter them in Figma
}
```

### AppTypography

```kotlin
// core/designsystem/typography/AppTypography.kt
val AppTypography = Typography(
    headlineLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        lineHeight = 40.sp
    ),
    // Map all Figma text styles here
)
```

### AppSpacing

```kotlin
// core/designsystem/spacing/AppSpacing.kt
object AppSpacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp
    val xxl = 48.dp
    val screenHorizontalPadding = 20.dp
    val cardPadding = 16.dp
}
```

### AppShapes

```kotlin
// core/designsystem/shape/AppShapes.kt
val AppShapes = Shapes(
    small = RoundedCornerShape(4.dp),
    medium = RoundedCornerShape(8.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(24.dp)
)
```

### AppIcons

```kotlin
// core/designsystem/icon/AppIcons.kt
// Centralize all icon references — never import Icons.* directly in feature code
object AppIcons {
    val ArrowBack = Icons.AutoMirrored.Filled.ArrowBack
    val Close = Icons.Default.Close
    val Profile = Icons.Default.Person
    // Add icons here as needed
}
```

### AppTheme — the entry point

```kotlin
// core/designsystem/theme/AppTheme.kt
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) darkColorScheme(...) else lightColorScheme(...)
    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}
```

`AppTheme` wraps the entire app in `MainActivity`. Every composable in the app automatically has access to `MaterialTheme.colorScheme`, `MaterialTheme.typography`, and `MaterialTheme.shapes` through it.

---

## Component Rules

This is the most critical section. Violating these rules creates spaghetti code.

### The Three Layers of UI

| Layer | Where | What it does |
|---|---|---|
| **Atoms** | `core/designsystem/component/` | Primitive building blocks — Button, TextField, Avatar, Badge, Chip. No business logic, no ViewModel references. |
| **Organisms** | `feature/[x]/ui/XxxComponents.kt` | Composed from atoms for a specific feature — `UserProfileCard`, `SessionTimerRow`. Stateless (data passed via params). |
| **Screens** | `feature/[x]/ui/XxxScreen.kt` | Full-screen composables. Collect state from ViewModel, pass data down to organisms. |

**Never skip a layer.** Don't build feature-specific logic in an atom. Don't put ViewModel calls inside an organism.

### Atoms — when to create vs use Material 3 directly

**Use Material 3 directly** (no wrapper needed) when:
- The component appears once or twice across the whole app
- No custom styling beyond `MaterialTheme` tokens is needed
- You're inside a Screen or Organism, not building another component

**Create a custom atom** in `core/designsystem/component/` when:
- The same visual pattern appears 3+ times across different features
- The component has custom styling (shape, size, icon placement) beyond Material 3 defaults
- You need to enforce consistent constraints (min touch target, padding, avatar fallback behavior)

Examples of **always use Material 3 directly**: `CircularProgressIndicator`, `LinearProgressIndicator`, `Divider`, `Spacer`.

Examples of **always create a custom atom**: app-styled buttons, avatar with fallback initials, tag/chip matching Figma's exact radius, bottom navigation items with custom indicators.

### Atom template

```kotlin
// core/designsystem/component/PrimaryButton.kt
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier.heightIn(min = 48.dp),
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary
        )
    ) {
        Text(text = text, style = MaterialTheme.typography.labelLarge)
    }
}

@Preview @Composable
private fun PrimaryButtonPreview() {
    AppTheme { PrimaryButton(text = "Get Started", onClick = {}) }
}
```

Rules for atoms:
- `modifier: Modifier = Modifier` is always the last parameter (or before content lambdas)
- Always support `enabled: Boolean = true` on interactive atoms
- Always have a `@Preview`
- Use `MaterialTheme.*` for all styling — never `AppColors.*` directly in atoms

### Organism template

```kotlin
// feature/profile/ui/ProfileComponents.kt
@Composable
fun UserProfileCard(
    user: ProfileData,
    onFollowClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = MaterialTheme.shapes.large
    ) {
        Row(
            modifier = Modifier.padding(AppSpacing.cardPadding),
            verticalAlignment = Alignment.CenterVertically
        ) {
            UserAvatar(imageUrl = user.avatarUrl, size = 48.dp)      // atom
            Spacer(modifier = Modifier.width(AppSpacing.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(user.displayName, style = MaterialTheme.typography.titleMedium)
                Text(user.handle, style = MaterialTheme.typography.bodySmall)
            }
            PrimaryButton(text = "Follow", onClick = onFollowClick)  // atom
        }
    }
}
```

### Screen template

Every screen follows this exact pattern — no exceptions:

```kotlin
// feature/profile/ui/ProfileScreen.kt

// 1. Public entry point — connects ViewModel to UI
@Composable
fun ProfileScreen(
    viewModel: ProfileViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    ProfileContent(
        uiState = uiState,
        onEvent = viewModel::onEvent,
        onNavigateBack = onNavigateBack
    )
}

// 2. Stateless content — testable and previewable
@Composable
private fun ProfileContent(
    uiState: ProfileUiState,
    onEvent: (ProfileEvent) -> Unit,
    onNavigateBack: () -> Unit
) {
    when (uiState) {
        is ProfileUiState.Loading -> LoadingContent()
        is ProfileUiState.Error -> ErrorContent(message = uiState.message)
        is ProfileUiState.Success -> ProfileSuccessContent(data = uiState.data, onEvent = onEvent)
    }
}

// 3. Always provide both light and dark previews
@Preview(showBackground = true)
@Preview(showBackground = true, uiMode = UI_MODE_NIGHT_YES)
@Composable
private fun ProfileScreenPreview() {
    AppTheme {
        ProfileContent(
            uiState = ProfileUiState.Success(fakeProfileData()),
            onEvent = {},
            onNavigateBack = {}
        )
    }
}
```

**Every screen must have both light and dark `@Preview` annotations.**

---

## UiState, Event, and ViewModel Pattern

### The three files for every feature

**`ProfileUiState.kt`**
```kotlin
sealed interface ProfileUiState {
    data object Loading : ProfileUiState
    data class Error(val message: String) : ProfileUiState
    data class Success(val data: ProfileData) : ProfileUiState
}

data class ProfileData(
    val userId: String,
    val displayName: String,
    val avatarUrl: String?,
    val isFollowing: Boolean
)
```

**`ProfileEvent.kt`**
```kotlin
sealed interface ProfileEvent {
    data class FollowUser(val userId: String) : ProfileEvent
    data object RetryLoad : ProfileEvent
}
```

**`ProfileViewModel.kt`**
```kotlin
@HiltViewModel
class ProfileViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val getUserProfileUseCase: GetUserProfileUseCase
) : ViewModel() {

    private val userId: String = checkNotNull(savedStateHandle["userId"])

    private val _uiState = MutableStateFlow<ProfileUiState>(ProfileUiState.Loading)
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    init { loadProfile() }

    fun onEvent(event: ProfileEvent) {
        when (event) {
            is ProfileEvent.FollowUser -> followUser(event.userId)
            ProfileEvent.RetryLoad -> loadProfile()
        }
    }

    private fun loadProfile() {
        viewModelScope.launch {
            _uiState.value = ProfileUiState.Loading
            getUserProfileUseCase(userId)
                .onSuccess { _uiState.value = ProfileUiState.Success(it.toDisplayModel()) }
                .onFailure { _uiState.value = ProfileUiState.Error(it.message ?: "Error") }
        }
    }
}
```

---

## Architecture Rules

### Layer dependencies (one direction only)

```
Screen → ViewModel → Use Case → Repository Interface ← Repository Impl → Data Sources
```

- **Domain layer** has zero `android.*` or `androidx.*` imports. Pure Kotlin.
- **ViewModels** depend on Use Cases only — never directly on repositories.
- **Repositories** map all exceptions — domain never sees `HttpException` or `SQLException`.

### Use Cases

One use case = one action. Named as `VerbNounUseCase`.

```kotlin
class GetUserProfileUseCase @Inject constructor(
    private val userRepository: UserRepository
) {
    suspend operator fun invoke(userId: String): Result<UserProfile> =
        userRepository.getUserProfile(userId)
}
```

### Repositories

```kotlin
// domain/repository/UserRepository.kt — interface
interface UserRepository {
    suspend fun getUserProfile(userId: String): Result<UserProfile>
}

// data/repository/UserRepositoryImpl.kt — implementation
class UserRepositoryImpl @Inject constructor(private val api: UserApi) : UserRepository {
    override suspend fun getUserProfile(userId: String): Result<UserProfile> =
        runCatching { api.getUser(userId).toDomain() }
}
```

---

## Model Mapping Rules

There are three distinct model types. Never mix them.

| Type | Location | Purpose |
|---|---|---|
| `UserDto` | `data/remote/dto/` | Matches API JSON exactly |
| `UserProfile` | `domain/model/` | Business logic model |
| `ProfileData` | `feature/.../viewmodel/` | UI display model with formatted strings |

Mapping functions are extension functions: `UserDto.toDomain()` and `UserProfile.toDisplayModel()`.

---

## Navigation

```kotlin
// core/navigation/AppRoutes.kt — all routes in one place
@Serializable data object HomeRoute
@Serializable data object MapRoute
@Serializable data class ProfileRoute(val userId: String)
@Serializable data class SessionRoute(val sessionId: String)
```

```kotlin
// core/navigation/AppNavGraph.kt — all composable() entries in one place
@Composable
fun AppNavGraph(navController: NavHostController) {
    NavHost(navController = navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onNavigateToProfile = { navController.navigate(ProfileRoute(it)) })
        }
        composable<ProfileRoute> {
            ProfileScreen(onNavigateBack = { navController.popBackStack() })
        }
    }
}
```

Never use string-based navigation routes.

---

## Dependency Injection

```kotlin
@HiltViewModel class XxxViewModel @Inject constructor(...) : ViewModel()

@Module @InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository
}
```

---

## Security

- Tokens in `EncryptedSharedPreferences` — never plain `SharedPreferences`
- Never log tokens, passwords, or user PII — even in debug builds
- `network_security_config.xml` must block cleartext traffic in release builds
- Enable certificate pinning for production API endpoints

---

## Accessibility

- All interactive composables need `contentDescription`
- Minimum touch target: 48dp × 48dp — use `Modifier.minimumInteractiveComponentSize()`
- Test every new screen with TalkBack before considering it done

---

## Testing

All JUnit artifacts (Platform, Jupiter, Vintage) use the same version —
do not mix versions across junit dependencies.

- Unit test all Use Cases — they are pure logic
- Unit test ViewModels with `kotlinx-coroutines-test` + Turbine
- Test naming: `given_[state]_when_[action]_then_[result]`

---

## What NOT to Do — The Spaghetti Code List

| Never | Instead |
|---|---|
| Hardcode any color, size, or font | Use design system tokens |
| Copy a Figma hex value directly into code | Map it to `AppColors` first |
| Invent UI without checking Figma | Always fetch Figma design first |
| Put business logic in a Composable | Move it to ViewModel or Use Case |
| Call a repository directly from ViewModel | Always go through a Use Case |
| Import `android.*` in `domain/` | Domain is pure Kotlin only |
| Use `LiveData` | Use `StateFlow` / `Flow` |
| Use `GlobalScope` | Use `viewModelScope` |
| Use KAPT | Use KSP |
| Navigate from inside a Composable | Hoist navigation via lambdas |
| Create a component without checking `core/designsystem/component/` first | Check, then reuse or add there |
| Write XML layouts | Jetpack Compose only |
| Use string route navigation | Use type-safe `@Serializable` routes |
| Store credentials in plain SharedPreferences | Use `EncryptedSharedPreferences` |
| Name a composable `renderX()` or `buildX()` | Composable names are PascalCase nouns |
| File longer than 300 lines | Split it |
| Function longer than 40 lines | Extract private functions |
| Add a new dependency without discussion | Flag it and discuss first |

---

## Checklist Before Submitting Any Code

- [ ] UI matches Figma design (verify with MCP screenshot comparison)
- [ ] No hardcoded colors, sizes, or text styles anywhere
- [ ] Light + Dark `@Preview` annotations on every new screen
- [ ] New reusable components added to `core/designsystem/component/`
- [ ] ViewModel exposes a single `uiState: StateFlow<XxxUiState>`
- [ ] Use Case exists for every new business action
- [ ] Domain layer has zero Android imports
- [ ] No unhandled exceptions bubble up to ViewModel
- [ ] All interactive elements have `contentDescription`
- [ ] Touch targets are at least 48dp
