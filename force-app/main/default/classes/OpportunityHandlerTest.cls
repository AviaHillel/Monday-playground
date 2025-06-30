@isTest
public class OpportunityHandlerTest {


    @TestSetup
    static void setupTestData() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Target__c target = new Target__c(Name = 'test target for tests', AccountExecutive__c = testUser.Id, Date__c = Date.today().toStartOfMonth(), TargetAmmount__c = 50000);
        insert target;
    }

    @isTest
    static void testInsertOpportunity_AssignTarget() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = testUser.Id
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        Target__c target = [SELECT Id FROM Target__c WHERE Name = 'test target for tests' LIMIT 1];
        Opportunity insertedOpp = [SELECT Id, Target__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(target.Id, insertedOpp.Target__c, 'Target should be assigned on insert.');
    }

    @isTest
    static void testUpdateOpportunity_AssignNewTarget() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = testUser.Id
        );
        insert opp;

        Target__c target = [SELECT Id FROM Target__c WHERE Name = 'test target for tests' LIMIT 1];
        Opportunity insertedOpp = [SELECT Id, Target__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(target.Id, insertedOpp.Target__c, 'Existing target should be assigned on insert.');

        
        Date newTargetDate = Date.today().addMonths(1).toStartOfMonth();
        Target__c newTarget = new Target__c(AccountExecutive__c = testUser.Id, Date__c = newTargetDate, TargetAmmount__c = 80000);
        insert newTarget;

        opp.CloseDate = Date.today().addMonths(1);

        Test.startTest();
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Target__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(newTarget.Id, updatedOpp.Target__c, 'Target should be updated to the new Target.');
    }

    @isTest
    static void testUpdateOpportunity_NoMatchingTarget() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = testUser.Id
        );
        insert opp;

        opp.CloseDate = Date.today().addMonths(2);

        Test.startTest();
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Target__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.Target__c, 'Target should be cleared when no matching Target exists.');
    }
}
