package com.bousselha.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {
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
                String userDir = System.getProperty("user.dir");
                registry.addResourceHandler("/uploads/**")
                        .addResourceLocations(
                                "file:src/main/resources/static/uploads/",
                                "file:" + userDir + "/src/main/resources/static/uploads/",
                                "file:uploads/",
                                "file:target/classes/static/uploads/"
                        );
            }
        };
    }
}
