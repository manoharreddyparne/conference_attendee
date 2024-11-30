public class SessionController {
    @AuraEnabled(cacheable=true)
    public static List<Session__c> getSessions() {
        try {
            // Fetch all sessions
            List<Session__c> sessions = [SELECT Id, Name FROM Session__c ORDER BY Name];
            return sessions;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sessions: ' + e.getMessage());
        }
    }
}
