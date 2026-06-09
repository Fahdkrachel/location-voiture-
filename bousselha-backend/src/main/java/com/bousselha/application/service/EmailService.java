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
    private final String fromAddress;
    private final String smtpHost;

    public EmailService(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.mail.from:no-reply@bousselha-cars.local}") String fromAddress,
            @Value("${spring.mail.host:}") String smtpHost
    ) {
        this.mailSenderProvider = mailSenderProvider;
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

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null || smtpHost == null || smtpHost.isBlank()) {
            log.info("Code de réinitialisation pour {}: {}", to, code);
            return;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(body);
        mailSender.send(message);
    }
}
