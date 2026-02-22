package com.starter.app.core.designsystem.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import com.starter.app.core.designsystem.color.AppColors
import com.starter.app.core.designsystem.shape.AppShapes
import com.starter.app.core.designsystem.typography.AppTypography

private val LightColorScheme = lightColorScheme(
    primary = AppColors.Primary,
    onPrimary = AppColors.OnPrimary,
    primaryContainer = AppColors.PrimaryContainer,
    onPrimaryContainer = AppColors.OnPrimaryContainer,
    secondary = AppColors.Secondary,
    onSecondary = AppColors.OnSecondary,
    surface = AppColors.Surface,
    onSurface = AppColors.OnSurface,
    surfaceVariant = AppColors.SurfaceVariant,
    onSurfaceVariant = AppColors.OnSurfaceVariant,
    background = AppColors.Background,
    onBackground = AppColors.OnBackground,
    error = AppColors.Error,
    onError = AppColors.OnError,
    outline = AppColors.Outline
)

private val DarkColorScheme = darkColorScheme(
    primary = AppColors.PrimaryDark,
    onPrimary = AppColors.OnPrimaryDark,
    primaryContainer = AppColors.PrimaryContainerDark,
    onPrimaryContainer = AppColors.OnPrimaryContainerDark,
    secondary = AppColors.SecondaryDark,
    onSecondary = AppColors.OnSecondaryDark,
    surface = AppColors.SurfaceDark,
    onSurface = AppColors.OnSurfaceDark,
    surfaceVariant = AppColors.SurfaceVariantDark,
    onSurfaceVariant = AppColors.OnSurfaceVariantDark,
    background = AppColors.BackgroundDark,
    onBackground = AppColors.OnBackgroundDark,
    error = AppColors.ErrorDark,
    onError = AppColors.OnErrorDark,
    outline = AppColors.OutlineDark
)

@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}
