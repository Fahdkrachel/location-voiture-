package com.bousselha.application.dto.request;

import com.bousselha.domain.enums.ContractStatus;
import jakarta.validation.constraints.NotNull;

public record ContractStatusRequest(@NotNull ContractStatus status) {
}
