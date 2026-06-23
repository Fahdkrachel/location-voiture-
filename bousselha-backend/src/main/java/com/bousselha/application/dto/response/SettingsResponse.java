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
    private String smtpHost;
    private Integer smtpPort;
    private String smtpUsername;
    private String smtpPassword;
    private Boolean smtpAuth;
    private Boolean smtpStarttls;
    private Boolean smtpActive;
    private LocalDateTime updatedAt;

    public SettingsResponse() {}

    public SettingsResponse(Long id, String companyName, String address, String phone,
                            String fax, String gsm, String email, String website,
                            String logoUrl, String smtpHost, Integer smtpPort,
                            String smtpUsername, String smtpPassword, Boolean smtpAuth,
                            Boolean smtpStarttls, Boolean smtpActive, LocalDateTime updatedAt) {
        this.id = id;
        this.companyName = companyName;
        this.address = address;
        this.phone = phone;
        this.fax = fax;
        this.gsm = gsm;
        this.email = email;
        this.website = website;
        this.logoUrl = logoUrl;
        this.smtpHost = smtpHost;
        this.smtpPort = smtpPort;
        this.smtpUsername = smtpUsername;
        this.smtpPassword = smtpPassword;
        this.smtpAuth = smtpAuth;
        this.smtpStarttls = smtpStarttls;
        this.smtpActive = smtpActive;
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

    public String getSmtpHost() { return smtpHost; }
    public void setSmtpHost(String smtpHost) { this.smtpHost = smtpHost; }

    public Integer getSmtpPort() { return smtpPort; }
    public void setSmtpPort(Integer smtpPort) { this.smtpPort = smtpPort; }

    public String getSmtpUsername() { return smtpUsername; }
    public void setSmtpUsername(String smtpUsername) { this.smtpUsername = smtpUsername; }

    public String getSmtpPassword() { return smtpPassword; }
    public void setSmtpPassword(String smtpPassword) { this.smtpPassword = smtpPassword; }

    public Boolean getSmtpAuth() { return smtpAuth; }
    public void setSmtpAuth(Boolean smtpAuth) { this.smtpAuth = smtpAuth; }

    public Boolean getSmtpStarttls() { return smtpStarttls; }
    public void setSmtpStarttls(Boolean smtpStarttls) { this.smtpStarttls = smtpStarttls; }

    public Boolean getSmtpActive() { return smtpActive; }
    public void setSmtpActive(Boolean smtpActive) { this.smtpActive = smtpActive; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
