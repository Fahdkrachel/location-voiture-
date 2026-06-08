package com.bousselha.application.dto.response;

import java.time.LocalDateTime;

public class SettingsResponse {

    private Long id;
    private String companyName;
    private String address;
    private String phone;
    private String fax;
    private String gsm;
    private String email;
    private String website;
    private String logoUrl;
    private LocalDateTime updatedAt;

    public SettingsResponse() {}

    public SettingsResponse(Long id, String companyName, String address, String phone,
                            String fax, String gsm, String email, String website,
                            String logoUrl, LocalDateTime updatedAt) {
        this.id = id;
        this.companyName = companyName;
        this.address = address;
        this.phone = phone;
        this.fax = fax;
        this.gsm = gsm;
        this.email = email;
        this.website = website;
        this.logoUrl = logoUrl;
        this.updatedAt = updatedAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getFax() { return fax; }
    public void setFax(String fax) { this.fax = fax; }

    public String getGsm() { return gsm; }
    public void setGsm(String gsm) { this.gsm = gsm; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }

    public String getLogoUrl() { return logoUrl; }
    public void setLogoUrl(String logoUrl) { this.logoUrl = logoUrl; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
