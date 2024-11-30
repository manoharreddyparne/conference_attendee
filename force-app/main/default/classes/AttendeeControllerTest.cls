@isTest
public class AttendeeControllerTest {
    @testSetup
    static void setup() {
        Session__c session = new Session__c();
        session.Name = 'Test Session';
        insert session;
    }

    @isTest
    static void testCreateAttendeeSuccess() {
        String name = 'Test Attendee';
        String email = 'test@example.com';
        String affiliation = 'Test Company';
        Id sessionId = [SELECT Id FROM Session__c WHERE Name = 'Test Session' LIMIT 1].Id;

        AttendeeController.createAttendee(name, email, affiliation, sessionId);

        Attendee__c attendee = [SELECT Id FROM Attendee__c WHERE Name = :name LIMIT 1];
        System.assert(attendee != null);
    }

    @isTest
    static void testCreateAttendee_EmptyName() {
        Test.startTest();
        try {
            AttendeeController.createAttendee('', 'test@example.com', 'Test Company', null);
            System.assert(false, 'Expected an exception');
        } catch (AuraHandledException e) {
            // Expected exception
        } finally {
            Test.stopTest();
        }
    }

    @isTest
    static void testCreateAttendee_InvalidEmail() {
        // Test with an invalid email address
        Test.startTest();
        try {
            AttendeeController.createAttendee('Test Attendee', 'invalid_email', 'Test Company', null);
            System.assert(false, 'Expected an exception');
        } catch (AuraHandledException e) {
            // Expected exception
        } finally {
            Test.stopTest();
        }
    }
}