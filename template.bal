import ballerina/log;
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
    remote function onEvent(json contact) {
        io:StringReader sr = new (contact.toJsonString());
        json|error contactInfo = sr.readJson();
        if(contactInfo is json) {   
            json|error eventType = contactInfo.event.'type;        
            if(eventType is json) {
                if(TYPE_CREATED.equalsIgnoreCaseAscii(eventType.toString())) {
                    json|error contactId = contactInfo.sobject.Id;
                    if(contactId is json) {
                        json|error contactObject = contactInfo.sobject;
                        if(contactObject is json) {
                            sendMessageWithContactCreation(contactObject);
                        } else {
                            log:printError(contactObject.message());
                        }
                    } else {
                        log:printError(contactId.message());
                    }
                }
            } else {
                log:printError(eventType.message());
            }
        } else {
            log:printError(contactInfo.message());
        }
    }
}

function sendMessageWithContactCreation(json contact) {
    string message = "New Salesforce contact is created successfully! \n";
    map<json> contactsMap = <map<json>> contact;
    foreach var [key, value] in contactsMap.entries() {
        if(value != ()) {
            message = message + key + " : " + value.toString() + "\n";
        }
    }
    var result = twilioClient->sendSms(from_mobile, to_mobile, message);
    if (result is twilio:SmsResponse) {
        log:print("SMS sent successfully for the contact creation || " + "SMS_SID: " + result.sid.toString() + 
            "|| Body: " + result.body.toString());
    } else {
        log:printError(result.message());
    }
}
