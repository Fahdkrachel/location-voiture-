package com.bousselha.infrastructure.controller;

import com.bousselha.application.dto.response.ContractResponse;
import com.bousselha.application.dto.response.DashboardResponse;
import com.bousselha.application.service.DashboardService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {
    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/stats")
    public DashboardResponse stats() {
        return dashboardService.stats();
    }

    @GetMapping("/calendar")
    public List<ContractResponse> calendar() {
        return dashboardService.calendar();
    }
}
