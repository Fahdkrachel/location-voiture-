package com.bousselha.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

    @Value("${app.uploads.dir}")
    private String baseUploadsDir;

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                        .allowedOrigins("*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS");
            }

            @Override
            public void addResourceHandlers(org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry registry) {
                String uploadsPath = java.nio.file.Paths.get(baseUploadsDir).toAbsolutePath().toUri().toString();
                if (!uploadsPath.endsWith("/")) {
                    uploadsPath += "/";
                }
                registry.addResourceHandler("/uploads/**")
                        .addResourceLocations(uploadsPath);
            }
        };
    }
}
