package com.bousselha.application.dto.request;

public class SettingsRequest {

    private String companyName;
    private String address;
    private String phone;
    private String fax;
    private String gsm;
    private String email;
    private String website;
    private String smtpHost;
    private Integer smtpPort;
    private String smtpUsername;
    private String smtpPassword;
    private Boolean smtpAuth;
    private Boolean smtpStarttls;
    private Boolean smtpActive;

    public SettingsRequest() {}

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
}
