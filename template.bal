import ballerina/io;
import ballerinax/sfdc;
import ballerinax/twilio;

// Twilio configuration parameters
configurable string tw_account_sid = ?;
configurable string tw_auth_token = ?;
configurable string tw_from_mobile = ?;
configurable string tw_to_mobile = ?;

twilio:TwilioConfiguration twilioConfig = {
    accountSId: tw_account_sid,
    authToken: tw_auth_token
};
twilio:Client twilioClient = new(twilioConfig);

// Salesforce configuration parameters
configurable string sf_username = ?;
configurable string sf_password = ?;
configurable string sf_push_topic = ?;

sfdc:ListenerConfiguration listenerConfig = {
    username: sf_username,
    password: sf_password
};
listener sfdc:Listener sfdcEventListener = new (listenerConfig);

@sfdc:ServiceConfig {
    topic: TOPIC_PREFIX + sf_push_topic
}
service on sfdcEventListener {
    remote function onEvent(json contact) returns error?{
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
    _ = check twilioClient->sendSms(tw_from_mobile, tw_to_mobile, message);
}
