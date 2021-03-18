import ballerina/io;
import ballerinax/sfdc;
import ballerinax/twilio;

configurable string & readonly sfUserName = ?;
configurable string & readonly sfPassword = ?;
configurable string & readonly sfPushTopic = ?;
configurable sfdc:ListenerConfiguration & readonly listenerConfig = ?;
configurable string & readonly twAccountSid = ?;
configurable string & readonly twAuthToken = ?;
configurable string & readonly twFromMobile = ?;
configurable string & readonly twToMobile = ?;
configurable twilio:TwilioConfiguration & readonly twilioConfig = ?;

listener sfdc:Listener sfdcEventListener = new (listenerConfig);
twilio:Client twilioClient = new (twilioConfig);

@sfdc:ServiceConfig {
    topic: TOPIC_PREFIX + sfPushTopic
}
service on sfdcEventListener {
    remote function onEvent(json contact) returns error? {
        io:StringReader stringReader = new (contact.toJsonString());
        json contactInfo = check stringReader.readJson();
        json eventType = check contactInfo.event.'type;        
        if(TYPE_CREATED.equalsIgnoreCaseAscii(eventType.toString())) {
            json contactId = check contactInfo.sobject.Id;
            json contactObject = check contactInfo.sobject;
            check sendMessageWithContactCreation(contactObject);
        }
    }
}

function sendMessageWithContactCreation(json contact) returns error? {
    string message = "New Salesforce contact is created successfully! \n";
    map<json> contactsMap = <map<json>> contact;
    foreach var ['key, value] in contactsMap.entries() {
        if(value != ()) {
            message = message + 'key + " : " + value.toString() + "\n";
        }
    }
    _ = check twilioClient->sendSms(twFromMobile, twToMobile, message);
}
