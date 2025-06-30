public with sharing class SignupLeadsService {

    /**
    * @author
    * @date
    * @description This method gets all signups within a date range and creates leads for the ones with valid data.
    * @param fromDT DateTime - get signeup from this date.
    * @param toDT DateTime - get signeup to this date.
    * @return void
    */
    public static void getSignups(Datetime fromDT, Datetime toDT){
        HttpResponse res = BigBrainAPI.pullSignups(fromDT, toDT); // call REST api to get all signups in the defined time frame.
        if(res.getStatusCode() == 200){ //if the request was successful.
            List<Signup> su_list = JSON.deserialize(res.getBody(),List<Signup>.class); //deserialize the response body by the Signup class wrapper.
            List<Lead> newLeads_list = new List<Lead>(); //initialize a list of leads to be inserted.
            for(Signup su: su_list){ //loop through the signups.
                if (su.account == null || su.account.data == null) { //if the account in the signup is null or it has no data in it, skip this signup.
                    continue;
                }
                String currentEmail = su.user?.data?.email; //save the email from this signup. using safe navigation to avoid null pointer exception.
                if (String.isBlank(currentEmail) || !isEmailValid(currentEmail)) { //if the email is blank or not valid, skip this signup.
                    continue; 
                }
                newLeads_list.add(createLead(su)); //convert the signup to a lead object and add it to the list to be inserted later. (only signups with account data and valid email will be created).
            }
            if(!newLeads_list.isEmpty()) { //if the list of leads is not empty.
                insert dedupByEmail(newLeads_list); //call dedupByEmail method to remove leads with existing emails before insertion.
            }
        }
    }


    /**
    * @author
    * @date
    * @description This method remove leads that has an email that already exist in one of the leads in the org.
    * @param inputLeads List<Lead> - the list of leads to check for duplicates.
    * @return List<Lead> - list of leads after removing duplicates by email.
    */
    private static List<Lead> dedupByEmail(List<Lead> inputLeads) {
        set<string> existing_emails = new set<string>(); //set of all the leads' emails to check for duplicates.
        map<string,lead> leadsByEmailAndCompany = new map<string,lead>(); //map of the leads with their email as a key.
        for(lead leadRec: inputLeads){ //loop through the leads to populate the set and map.
            if(!String.isBlank(leadRec.email)) {
                existing_emails.add(leadRec.email); //add the email to the set
                leadsByEmailAndCompany.put(leadRec.email, leadRec); //put the lead in the map with its email as the key
            }
        }
        list<lead> existingLeads = [select email, account.name from Lead where
                                    email in: existing_emails]; //query all existing leads with an email that matches one in the set.
        if (existingLeads.isEmpty()) {
            return inputLeads; //if there are no matches, return the input list to insert them all.
        } 
        else { //there is at least one duplicate
            for(lead leadRec: existingLeads){ //loop through the exisitng leads
                if(existing_emails.containsKey(leadRec.email)){
                    leadsByEmailAndCompany.remove(leadRec.email); //remove the lead from the map, since a lead with this email already exists in the org.
                }
            }
            return leadsByEmailAndCompany.values(); //return the list of leads without the duplicates for insertion.
        }
        /***
        * if(!String.isBlank(leadRec.email)) - will never be blank, since you skip empty emails on the previous method.
        * SOQL key words should be in upper case.
        * I wouldn't use existing_emails set since the leadsByEmailAndCompany keySet is this set.
        You can simplify the code by using only the leadsByEmailAndCompany map and directly removing duplicates 
        with leadsByEmailAndCompany.remove(leadRec.email); when looping through existingLeads.
        ***/
    }



    /**
    * @author
    * @date
    * @description This method remove leads that has an email and a company that already exist in one of the leads in the org.
    * @param inputLeads List<Lead> - the list of leads to check for duplicates.
    * @return List<Lead> - list of leads after removing duplicates.
    */
    private static List<Lead> dedupByEmailAndCompany(List<Lead> inputLeads){
        Map<String,Lead> leadsByEmailAndCompany = new Map<String,Lead>();
        set<string> existing_emails = new set<string>();
        Map<String,Lead> companyByEmail = new Map<String,Lead>();
        for(Lead leadRec: inputLeads){
            if(!String.isBlank(leadRec.Email)){
                existing_emails.add(leadRec.email);
                leadsByEmailAndCompany.put(leadRec.Email + leadRec.Account?.Name, leadRec);
            }
        }
        List<Lead> existingLeads = [SELECT Email, Account.Name FROM Lead WHERE Email IN: existing_emails];
        if (existingLeads.isEmpty()){
            return inputLeads;
        } 
        else {
            for(lead leadRec: existingLeads){
                if(leadsByEmailAndCompany.containsKey(leadRec.Email + leadRec.Account?.Name)){
                    leadsByEmailAndCompany.remove(leadRec.Email + leadRec.Account?.Name);
                }
            }
            return leadsByEmailAndCompany.values();
        }
    }
}