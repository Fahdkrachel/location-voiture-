package com.bousselha.application.dto.request;

public class SettingsRequest {

    private String companyName;
    private String address;
    private String phone;
    private String fax;
    private String gsm;
    private String email;
    private String website;

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
}
