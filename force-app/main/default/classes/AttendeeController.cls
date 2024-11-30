public class AttendeeController {

    // Method to fetch available sessions for the dropdown
    @AuraEnabled(cacheable=true)
    public static List<Session__c> getSessions() {
        try {
            return [SELECT Id, Name FROM Session__c];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sessions: ' + e.getMessage());
        }
    }

    // Method to initiate registration and generate OTP
    @AuraEnabled
    public static void initiateRegistration(String name, String email, String affiliation, Id sessionId) {
        try {
            // Check if the email is already registered in the Attendee__c object
            if ([SELECT COUNT() FROM Attendee__c WHERE Email__c = :email] > 0) {
                throw new AuraHandledException('An attendee with this email already exists.');
            }

            // Generate a 6-digit OTP
            String otp = generateOTP();

            // Create a temporary Attendee_OTP__c record to store OTP and email
            Attendee_OTP__c otpRecord = new Attendee_OTP__c();
            otpRecord.Email__c = email;
            otpRecord.OTP__c = otp;
            otpRecord.Session__c = sessionId;
            insert otpRecord;

            // Send the OTP via email
            sendConfirmationEmail(otp, email);
        } catch (DmlException e) {
            throw new AuraHandledException('An error occurred while processing registration: ' + e.getMessage());
        }
    }

    // Method to generate a 6-digit OTP as a string
    private static String generateOTP() {
        Integer otp = Math.mod(Math.abs(Crypto.getRandomInteger()), 900000) + 100000;
        return String.valueOf(otp); // Ensure it's returned as a string
    }

    // Method to send OTP confirmation email
    private static void sendConfirmationEmail(String otp, String email) {
    try {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Set the recipient's email address
        mail.setToAddresses(new String[] { email });
        
        // Set the email subject
        mail.setSubject('This email is for Conference Registration');
        
        // Set the email body
        String body = 'Dear Attendee,\n\n' +
                      'Thank you for initiating the registration process for the conference.\n\n' +
                      'This email contains the OTP (One-Time Password) required to complete your registration. Please find your OTP below:\n\n' +
                      'Your OTP: ' + otp + '\n\n' +
                      'Kindly enter this OTP in the registration form to proceed with your registration.\n\n' +
                      'If you encounter any issues during the registration process or have any questions, feel free to reach out to us at:\n\n' +
                      'Email: 2211CS010446@mallareddyuniversity.ac.in\n\n' +
                      'Thank you for your participation, and we look forward to your involvement in the conference.\n\n' +
                      'Best regards,\n' +
                      'Manohar Reddy and Team\n' +
                      'Malla Reddy University';
        
        // Set the plain text body of the email
        mail.setPlainTextBody(body);
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    	}catch (EmailException e) {
            if (e.getMessage().contains('SINGLE_EMAIL_LIMIT_EXCEEDED')) {
                throw new AuraHandledException('Email sending limit exceeded. Please try again later.');
            } else {
                throw new AuraHandledException('Error sending OTP email: ' + e.getMessage());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error while sending email: ' + e.getMessage());
        }
    }

    // Method to verify OTP and store details in Attendee__c object
    @AuraEnabled
    public static String verifyOTP(String email, String enteredOTP, String name, String affiliation, Id sessionId) {
        try {
            // Get the latest OTP record for the email
            List<Attendee_OTP__c> otpRecords = [SELECT Id, OTP__c FROM Attendee_OTP__c WHERE Email__c = :email ORDER BY CreatedDate DESC LIMIT 1];

            if (otpRecords.isEmpty()) {
                throw new AuraHandledException('No OTP found for the provided email.');
            }

            // Check if the entered OTP matches the generated OTP
            if (otpRecords[0].OTP__c != enteredOTP) {
                throw new AuraHandledException('Incorrect OTP. Please check your email and enter the correct OTP.');
            }

            // Create the final Attendee__c record
            Attendee__c attendee = new Attendee__c();
            attendee.Name = name;
            attendee.Email__c = email;
            attendee.Affiliation__c = affiliation;
            attendee.Session__c = sessionId;
            insert attendee;

            // Optionally, delete the OTP record after successful verification
            delete otpRecords;

            // Send registration confirmation email after successful OTP verification
            sendConfirmationEmailAfterRegistration(email);

            return 'Attendee registration successful!';
        } catch (AuraHandledException e) {
            throw e; // Directly rethrow known handled exception
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error during OTP verification: ' + e.getMessage());
        }
    }

    // Method to send confirmation email after successful registration
        private static void sendConfirmationEmailAfterRegistration(String email) {
    try {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Set the recipient's email address
        mail.setToAddresses(new String[] { email });
        
        // Set the email subject
        mail.setSubject('Congratulations! Your Registration is Confirmed');
        
        // Set the email body
        String body = 'Dear Attendee,\n\n' +
                      'Congratulations! Your registration for the conference has been successfully confirmed.\n\n' +
                      'We are excited to have you participate in the upcoming event and look forward to seeing you there!\n\n' +
                      'If you have any questions or need further assistance, feel free to contact us at:\n\n' +
                      'Email: 2211CS010446@mallareddyuniversity.ac.in\n\n' +
                      'Thank you for registering!\n\n' +
                      'Best regards,\n' +
                      'Manohar Reddy and Team\n' +
                      'Malla Reddy University';
        
        // Set the plain text body of the email
        mail.setPlainTextBody(body);
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    } catch (Exception e) {
        throw new AuraHandledException('Error sending registration confirmation email: ' + e.getMessage());
    }
}

}
