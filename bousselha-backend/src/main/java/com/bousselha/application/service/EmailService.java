package com.bousselha.application.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final com.bousselha.domain.repository.CompanySettingsRepository settingsRepository;
    private final String fromAddress;
    private final String smtpHost;

    public EmailService(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            com.bousselha.domain.repository.CompanySettingsRepository settingsRepository,
            @Value("${app.mail.from:no-reply@bousselha-cars.local}") String fromAddress,
            @Value("${spring.mail.host:}") String smtpHost
    ) {
        this.mailSenderProvider = mailSenderProvider;
        this.settingsRepository = settingsRepository;
        this.fromAddress = fromAddress;
        this.smtpHost = smtpHost;
    }

    public void sendPasswordResetCode(String to, String code) {
        String subject = "Réinitialisation de votre mot de passe";
        String body = """
                Bonjour,

                Vous avez demandé la réinitialisation de votre mot de passe.

                Votre code de vérification est :

                %s

                Ce code expire dans 10 minutes.

                Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.

                BOUSSELHA CARS
                """.formatted(code);

        JavaMailSender mailSender = null;
        String from = fromAddress;

        try {
            com.bousselha.domain.model.CompanySettings s = settingsRepository.findById(1L).orElse(null);
            if (s != null && Boolean.TRUE.equals(s.getSmtpActive()) && s.getSmtpHost() != null && !s.getSmtpHost().isBlank()) {
                org.springframework.mail.javamail.JavaMailSenderImpl impl = new org.springframework.mail.javamail.JavaMailSenderImpl();
                impl.setHost(s.getSmtpHost());
                if (s.getSmtpPort() != null) {
                    impl.setPort(s.getSmtpPort());
                } else {
                    impl.setPort(587);
                }
                impl.setUsername(s.getSmtpUsername());
                impl.setPassword(s.getSmtpPassword());

                java.util.Properties props = impl.getJavaMailProperties();
                props.put("mail.transport.protocol", "smtp");
                props.put("mail.smtp.auth", Boolean.TRUE.equals(s.getSmtpAuth()) ? "true" : "false");
                props.put("mail.smtp.starttls.enable", Boolean.TRUE.equals(s.getSmtpStarttls()) ? "true" : "false");
                props.put("mail.smtp.ssl.trust", s.getSmtpHost());

                mailSender = impl;
                from = s.getSmtpUsername();
            }
        } catch (Exception e) {
            log.error("Erreur lors de l'application des paramètres SMTP dynamiques : {}", e.getMessage());
        }

        if (mailSender == null) {
            mailSender = mailSenderProvider.getIfAvailable();
            if (mailSender == null || smtpHost == null || smtpHost.isBlank()) {
                log.info("Code de réinitialisation pour {}: {}", to, code);
                return;
            }
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(body);
        mailSender.send(message);
    }
}
