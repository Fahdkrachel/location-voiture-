package com.bousselha.application.service;

import com.bousselha.application.dto.request.ContractRequest;
import com.bousselha.application.dto.response.ContractResponse;
import com.bousselha.domain.enums.CarStatus;
import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.model.Client;
import com.bousselha.domain.model.Contract;
import com.bousselha.domain.repository.CarRepository;
import com.bousselha.domain.repository.ClientRepository;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

@Service
@Transactional
public class ContractService {
    private static final Set<ContractStatus> OPEN_CONTRACT_STATUSES =
            EnumSet.of(ContractStatus.IN_PROGRESS, ContractStatus.ACTIVE);

    private final ContractRepository contractRepository;
    private final CarRepository carRepository;
    private final ClientRepository clientRepository;
    private final FinancialService financialService;
    private final OrphanClientService orphanClientService;

    public ContractService(
            ContractRepository contractRepository,
            CarRepository carRepository,
            ClientRepository clientRepository,
            FinancialService financialService,
            OrphanClientService orphanClientService
    ) {
        this.contractRepository = contractRepository;
        this.carRepository = carRepository;
        this.clientRepository = clientRepository;
        this.financialService = financialService;
        this.orphanClientService = orphanClientService;
    }

    public List<ContractResponse> findAll() {
        return contractRepository.findByDeletedFalse().stream().map(this::map).toList();
    }

    public List<ContractResponse> findAllByCarId(Long carId) {
        return contractRepository.findByDeletedFalseAndCarId(carId).stream().map(this::map).toList();
    }

    public ContractResponse findById(Long id) {
        return map(getContract(id));
    }

    public List<ContractResponse> findActive() {
        return contractRepository.findByDeletedFalseAndStatusIn(
                EnumSet.of(ContractStatus.IN_PROGRESS, ContractStatus.ACTIVE)
        ).stream().map(this::map).toList();
    }

    public ContractResponse create(ContractRequest request) {
        Car car = carRepository.findById(request.carId())
                .orElseThrow(() -> new ResourceNotFoundException("Car not found: " + request.carId()));
        if (car.getStatus() != CarStatus.AVAILABLE) {
            throw new IllegalArgumentException("Car is not available for rental: " + car.getMatricule());
        }
        if (contractRepository.existsByCarIdAndDeletedFalseAndStatusIn(car.getId(), OPEN_CONTRACT_STATUSES)) {
            throw new IllegalArgumentException("Car already has an open contract: " + car.getMatricule());
        }
        Client client = clientRepository.findById(request.clientId())
                .orElseThrow(() -> new ResourceNotFoundException("Client not found: " + request.clientId()));
        Contract contract = new Contract();
        contract.setCar(car);
        contract.setClient(client);
        contract.setStatus(ContractStatus.IN_PROGRESS);
        apply(contract, request);
        return map(contractRepository.save(contract));
    }

    public ContractResponse updateStatus(Long id, ContractStatus newStatus) {
        Contract contract = getContract(id);
        ContractStatus current = contract.getStatus();

        if (newStatus == ContractStatus.ACTIVE) {
            if (current != ContractStatus.IN_PROGRESS) {
                throw new IllegalArgumentException("Seul un contrat IN_PROGRESS peut passer en ACTIVE");
            }
            Car car = contract.getCar();
            if (car.getStatus() != CarStatus.AVAILABLE) {
                throw new IllegalArgumentException("La voiture n'est pas disponible: " + car.getMatricule());
            }
            car.setStatus(CarStatus.RENTED);
            contract.setStatus(ContractStatus.ACTIVE);
            financialService.ensureIncomeForContract(contract);
        } else if (newStatus == ContractStatus.COMPLETED) {
            if (current != ContractStatus.ACTIVE) {
                throw new IllegalArgumentException("Seul un contrat ACTIVE peut être terminé");
            }
            contract.setActualReturnDatetime(LocalDateTime.now());
            contract.setStatus(ContractStatus.COMPLETED);
            contract.getCar().setStatus(CarStatus.AVAILABLE);
            financialService.ensureIncomeForContract(contract);
        } else {
            throw new IllegalArgumentException("Transition de statut non autorisée vers " + newStatus);
        }

        return map(contractRepository.save(contract));
    }

    public ContractResponse registerReturn(Long id) {
        return updateStatus(id, ContractStatus.COMPLETED);
    }

    public ContractResponse update(Long id, ContractRequest request) {
        Contract contract = getContract(id);
        if (contract.getStatus() == ContractStatus.ACTIVE || contract.getStatus() == ContractStatus.COMPLETED) {
            throw new IllegalArgumentException("Impossible de modifier un contrat en location ou déjà terminé");
        }

        Car car = carRepository.findById(request.carId())
                .orElseThrow(() -> new ResourceNotFoundException("Car not found: " + request.carId()));
        Client client = clientRepository.findById(request.clientId())
                .orElseThrow(() -> new ResourceNotFoundException("Client not found: " + request.clientId()));

        if (contract.getStatus() == ContractStatus.ACTIVE && !contract.getCar().getId().equals(request.carId())) {
            throw new IllegalArgumentException("Cannot change assigned car while contract is active");
        }
        if (contract.getStatus() == ContractStatus.IN_PROGRESS && !contract.getCar().getId().equals(request.carId())) {
            Car newCar = car;
            if (newCar.getStatus() != CarStatus.AVAILABLE) {
                throw new IllegalArgumentException("Car is not available: " + newCar.getMatricule());
            }
        }

        contract.setCar(car);
        contract.setClient(client);
        apply(contract, request);

        if (contract.getStatus() == ContractStatus.ACTIVE) {
            contract.getCar().setStatus(CarStatus.RENTED);
        }

        return map(contractRepository.save(contract));
    }

    public void softDelete(Long id) {
        Contract contract = getContract(id);
        if (contract.getStatus() == ContractStatus.ACTIVE) {
            throw new IllegalArgumentException("Impossible : terminez le contrat avant de le supprimer");
        }
        if (contract.getStatus() == ContractStatus.COMPLETED) {
            financialService.ensureIncomeForContract(contract);
        }
        Long clientId = contract.getClient().getId();
        contract.setDeleted(true);
        contractRepository.save(contract);
        orphanClientService.removeClientIfOrphan(clientId);
    }

    private Contract getContract(Long id) {
        return contractRepository.findById(id)
                .filter(c -> !c.isDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Contract not found: " + id));
    }

    private void apply(Contract c, ContractRequest r) {
        c.setAdditionalDriverName(r.additionalDriverName());
        c.setAdditionalDriverLicense(r.additionalDriverLicense());
        c.setAdditionalDriverPassport(r.additionalDriverPassport());
        c.setDeparturePlace(r.departurePlace());
        c.setReturnPlace(r.returnPlace());
        c.setDepartureDatetime(r.departureDatetime());
        c.setExpectedReturnDatetime(r.expectedReturnDatetime());
        c.setActualReturnDatetime(r.actualReturnDatetime());
        c.setDurationDays(r.durationDays());
        c.setPricePerDay(r.pricePerDay());
        c.setPricePerWeek(r.pricePerWeek());
        c.setPricePerMonth(r.pricePerMonth());
        c.setPricePerHour(r.pricePerHour());
        c.setWithInsurance(Boolean.TRUE.equals(r.withInsurance()));
        c.setTotalPrice(r.totalPrice());
        c.setSupplement(r.supplement());
        c.setTotalGeneral(r.totalGeneral());
        c.setPaymentCash(r.paymentCash());
        c.setPaymentCheck(r.paymentCheck());
        c.setPaymentDeposit(r.paymentDeposit());
        c.setVehicleConditionDeparture(r.vehicleConditionDeparture());
        c.setVehicleConditionReturn(r.vehicleConditionReturn());
        c.setDamagesIdentified(r.damagesIdentified());
    }

    private ContractResponse map(Contract c) {
        return new ContractResponse(
                c.getId(),
                c.getCar().getId(),
                c.getCar().getBrand() + " - " + c.getCar().getMatricule(),
                c.getCar().getBrand(),
                c.getCar().getMatricule(),
                c.getCar().getFuelType(),
                c.getDeparturePlace(),
                c.getReturnPlace(),
                c.getClient().getId(),
                c.getClient().getFullName(),
                c.getClient().getBirthDate(),
                c.getClient().getAddressMorocco(),
                c.getClient().getAddressAbroad(),
                c.getClient().getProfession(),
                c.getClient().getDrivingLicenseNumber(),
                c.getClient().getDrivingLicenseIssuedAt(),
                c.getClient().getCinNumber(),
                c.getClient().getPassportNumber(),
                c.getClient().getPassportIssuedAt(),
                c.getClient().getPhone(),
                c.getAdditionalDriverName(),
                c.getAdditionalDriverLicense(),
                c.getClient().getAdditionalDriverDrivingLicenseIssuedAt() == null ? null : c.getClient().getAdditionalDriverDrivingLicenseIssuedAt().toString(),
                c.getAdditionalDriverPassport(),
                c.getDepartureDatetime(),
                c.getExpectedReturnDatetime(),
                c.getActualReturnDatetime(),
                c.getDurationDays(),
                c.getPricePerHour(),
                c.getPricePerDay(),
                c.getPricePerWeek(),
                c.getPricePerMonth(),
                c.getWithInsurance(),
                c.getTotalPrice(),
                c.getSupplement(),
                c.getTotalGeneral(),
                c.getPaymentCash(),
                c.getPaymentCheck(),
                c.getPaymentDeposit(),
                c.getVehicleConditionDeparture(),
                c.getVehicleConditionReturn(),
                c.getDamagesIdentified(),
                c.getCreatedAt(),
                c.getStatus()
        );
    }
}
