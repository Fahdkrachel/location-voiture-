package com.bousselha.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI bousselhaOpenApi() {
        return new OpenAPI().info(new Info()
                .title("BOUSSELHA CARS API")
                .version("1.0.0")
                .description("API de gestion de location de voitures")
                .contact(new Contact().name("BOUSSELHA CARS").email("bousselhaa@gmail.com")));
    }
}
