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
import java.util.List;

@Service
@Transactional
public class ContractService {
    private final ContractRepository contractRepository;
    private final CarRepository carRepository;
    private final ClientRepository clientRepository;

    public ContractService(ContractRepository contractRepository, CarRepository carRepository, ClientRepository clientRepository) {
        this.contractRepository = contractRepository;
        this.carRepository = carRepository;
        this.clientRepository = clientRepository;
    }

    public List<ContractResponse> findAll() {
        return contractRepository.findByDeletedFalse().stream().map(this::map).toList();
    }

    public ContractResponse findById(Long id) {
        return map(getContract(id));
    }

    public List<ContractResponse> findActive() {
        return contractRepository.findByDeletedFalseAndStatus(ContractStatus.ACTIVE).stream().map(this::map).toList();
    }

    public ContractResponse create(ContractRequest request) {
        Car car = carRepository.findById(request.carId())
                .orElseThrow(() -> new ResourceNotFoundException("Car not found: " + request.carId()));
        Client client = clientRepository.findById(request.clientId())
                .orElseThrow(() -> new ResourceNotFoundException("Client not found: " + request.clientId()));
        Contract contract = new Contract();
        contract.setCar(car);
        contract.setClient(client);
        apply(contract, request);
        car.setStatus(CarStatus.RENTED);
        return map(contractRepository.save(contract));
    }

    public ContractResponse registerReturn(Long id) {
        Contract contract = getContract(id);
        contract.setActualReturnDatetime(LocalDateTime.now());
        contract.setStatus(ContractStatus.COMPLETED);
        Car car = contract.getCar();
        car.setStatus(CarStatus.AVAILABLE);
        return map(contractRepository.save(contract));
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
                c.getClient().getId(),
                c.getClient().getFullName(),
                c.getDepartureDatetime(),
                c.getExpectedReturnDatetime(),
                c.getActualReturnDatetime(),
                c.getTotalGeneral(),
                c.getStatus()
        );
    }
}
