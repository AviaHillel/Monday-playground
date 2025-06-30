public with sharing class OpportunityHandler {
    
    public void beforeInsert(List<Opportunity> newOpportunities) {
        assignTarget(newOpportunities, null);
    }
    
    public void beforeUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunityMap) {
        assignTarget(newOpportunities, oldOpportunityMap);
    }
    
    public void afterInsert(List<Opportunity> newOpportunities) {
    }
    
    public void afterUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunityMap) {
    }


    /**
    * @author Avia Hillel
    * @date 29.06.2025
    * @description Retrieves Targets__c based on the target's AE and Date, and assign the matching one to the opportunity.
    * @param newOpportunities List<Opportunity> Trigger.new.
    * @param oldOpportunityMap Map<Id, Opportunity> Trigger.oldMap.
    * @return void
    */
    public void assignTarget(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunityMap) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Set<Id> oppsOwners = new Set<Id>();
        Set<Date> oppsClosedDates = new Set<Date>();
        for(Opportunity opp : newOpportunities){
            if(oldOpportunityMap == null || 
                (oldOpportunityMap != null && (oldOpportunityMap.get(opp.Id).OwnerId != opp.OwnerId || oldOpportunityMap.get(opp.Id).CloseDate != opp.CloseDate))){
                oppsToUpdate.add(opp);
                oppsOwners.add(opp.OwnerId);
                oppsClosedDates.add(opp.CloseDate.toStartOfMonth());
            }
        }
        if(!oppsToUpdate.isEmpty()){
            Map<Id, Map<Date, Id>> ownerDateTargetMap = new Map<Id, Map<Date, Id>>();
            for(Target__c target : [SELECT Id, AccountExecutive__c, Date__c FROM Target__c WHERE AccountExecutive__c IN : oppsOwners AND Date__c IN : oppsClosedDates]){
                if(!ownerDateTargetMap.containsKey(target.AccountExecutive__c)){
                    ownerDateTargetMap.put(target.AccountExecutive__c, new Map<Date, Id>());
                }
                ownerDateTargetMap.get(target.AccountExecutive__c).put(target.Date__c, target.Id);
            }
            for(Opportunity opp : oppsToUpdate){
                opp.Target__c = ownerDateTargetMap.get(opp.OwnerId)?.get(opp.CloseDate.toStartOfMonth());
                // if(ownerDateTargetMap.containsKey(opp.OwnerId) && ownerDateTargetMap.get(opp.OwnerId).containsKey(opp.CloseDate.toStartOfMonth())){
                //     opp.Target__c = ownerDateTargetMap.get(opp.OwnerId).get(opp.CloseDate.toStartOfMonth());
                // }
                // else{
                //     opp.Target__c = null;
                // } 
            }
        }
    }
}