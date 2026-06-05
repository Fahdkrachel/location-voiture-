package com.bousselha;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class BousselhaApplication {
    public static void main(String[] args) {
        SpringApplication.run(BousselhaApplication.class, args);
    }
}
