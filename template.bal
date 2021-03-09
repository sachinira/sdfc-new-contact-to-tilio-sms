import ballerina/io;
import ballerinax/sfdc;
import ballerinax/twilio;

// Twilio configuration parameters
configurable string account_sid = ?;
configurable string auth_token = ?;
configurable string from_mobile = ?;
configurable string to_mobile = ?;

twilio:TwilioConfiguration twilioConfig = {
    accountSId: account_sid,
    authToken: auth_token
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
        io:StringReader sr = new (contact.toJsonString());
        json contactInfo = check sr.readJson();
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
    _ = check twilioClient->sendSms(from_mobile, to_mobile, message);
}