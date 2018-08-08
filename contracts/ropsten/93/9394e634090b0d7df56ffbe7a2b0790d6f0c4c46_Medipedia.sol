pragma solidity 0.4.24;

/**
    This smart contract represents the POC of Medipedia platform that deals with finding the
    matching doctors and sending the medical requests to all the matched doctors or clinics.
*/

contract Medipedia {
    address public owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    modifier restricted() {
        require(msg.sender == owner);
        _;
    }
    
    event addMessageRequestEvent(address userAddress, string msgReqst);
    event addMessageReplyEvent(address userAddress, string reply);
    event userStatusUpdated(address userAddress, string eventMsg);
    /**
        Message holds the encrypted hash of Medical Request
        raised by patients and encrypted hash of replies 
        from matching Medical Service Providers.
     */
    struct Message{
        uint id;
        string messageRequestHash;
        string replyHash;
        address medproviderAddress;
    }

    /**
        Each message communication will be held by an user.
        An user is medical servicer provider or patient.
     */
    mapping (address => Message[]) messages;
    
    /**
     * userStatus makes sure that information will be updated 
     * only authorized Consumers and Medical Providers.
     * userStatus is active if it is 1 other 0 as deactivated account.
    */
    
    mapping (address => uint) userStatus;
     
    function addMessageRequest(address _consumerAddress, address[] _providerAddresses, string _msgRequestHash) public{
        if(userStatus[_consumerAddress] == 1){
            uint _noOfProviders = _providerAddresses.length;
            for (uint i = 0; i<_noOfProviders; i++) {
                if(userStatus[_providerAddresses[i]] == 1){
                    addRequest(_consumerAddress,  _msgRequestHash,  "", _providerAddresses[i]);
                    addRequest(_providerAddresses[i],  _msgRequestHash,  "", address(0));
                }
            }
        }
    }
    
    /**
        addRequest adds medical request and replies to Struct
        data structure. It is only accessible to authorized users.
     */
    function addRequest(address userAddress, string msgRequestHash, string repHash, address _medproviderAddress) private {
        
        Message[] storage msgs = messages[userAddress];
        uint arrayLength = msgs.length;
        Message memory message;
        uint id = arrayLength + 1;
        message = Message(id, msgRequestHash, repHash, _medproviderAddress);
        msgs.push(message);
        emit addMessageRequestEvent(userAddress, "New Message request added.");
    }

    function addReplies(address _consumerAddress, address[] _providerAddresses, string _msgRequestHash, string _repHash) public{
        if(userStatus[_consumerAddress] == 1){
            addPatientReply(_consumerAddress,  _msgRequestHash,  _repHash, _providerAddresses[0]);
            uint _noOfProviders = _providerAddresses.length;
            for (uint i = 0; i<_noOfProviders; i++) {
                if(userStatus[_providerAddresses[i]] == 1){
                    addMedicalProviderReply(_providerAddresses[i],  _msgRequestHash,  _repHash);
                }
            }
        }
    }

    function addPatientReply(address userAddress, string msgRequestHash, string repHash, address _medproviderAddress) private {
        
        Message[] storage msgs = messages[userAddress];

        uint arrayLength = msgs.length;
        
        for (uint i = 0; i<arrayLength; i++) {
            if(_medproviderAddress == msgs[i].medproviderAddress){
                if(bytes(repHash).length > 0 && 
                    keccak256(abi.encodePacked(msgs[i].messageRequestHash)) == keccak256(abi.encodePacked(msgRequestHash))){
                    msgs[i].replyHash = repHash;
                    emit addMessageReplyEvent(userAddress, "A new reply added");
                    break;
                }
            }
            
        }
    }

    /**
        addReply adds medical request and replies to Struct
        data structure. It is only accessible to authorized users.
     */
    function addMedicalProviderReply(address userAddress, string msgRequestHash, string repHash) private {
        
        Message[] storage msgs = messages[userAddress];

        uint arrayLength = msgs.length;
        
        for (uint i = 0; i<arrayLength; i++) {

            if(bytes(repHash).length > 0 && 
                keccak256(abi.encodePacked(msgs[i].messageRequestHash)) == keccak256(abi.encodePacked(msgRequestHash))){
                msgs[i].replyHash = repHash;
                emit addMessageReplyEvent(userAddress, "A new reply added");
                break;
            }
        }

    }

    /**
        getNoOfMsgs returns number of message communications.
     */
    function getNoOfMsgs(address userAddress) public view returns(uint){
        return messages[userAddress].length;
    }

    /**
        getMessageCommunicationHash returns all communications between an user
        and a provider.
     */
    function getMessageCommunicationHash(address userAddress, uint id) public view returns(string){
        Message[] storage msgs = messages[userAddress];
        string storage msgHash = msgs[id-1].replyHash;

        if(bytes(msgHash).length == 0){
            return "";
        }

        return msgHash;
    }
    /**
        getMessageRequestHash returns a medical request
     */
    function getMessageRequestHash(address userAddress, uint id) public view returns(string){
        Message[] storage msgs = messages[userAddress];
        return msgs[id-1].messageRequestHash;
    }

    /**
        getMessageRequestHashUsingProviderAddress returns a medical request
     */
    function getMessageRequestHashUsingProviderAddress(address userAddress, uint id, address _medproviderAddress) public view returns(string){
        Message[] storage msgs = messages[userAddress];

        uint arrayLength = msgs.length;
        for (uint i = 0; i<arrayLength; i++) {
            if(_medproviderAddress == msgs[i].medproviderAddress){
                string storage reqHash = msgs[id-1].messageRequestHash;
                return reqHash;
            }
        }

        return "";
    }
    
    function setUserStatus(address userAddress, uint status) public restricted{
        userStatus[userAddress] = status;
        emit userStatusUpdated(userAddress, "User status updated.");
    }

    function getUserStatus(address userAddress) public restricted view returns(uint){
        return userStatus[userAddress];
    }

    function deleteAllMessages(address userAddress) public{
        delete messages[userAddress];
    }
    
    function kill() public restricted{
        if (msg.sender == owner) selfdestruct(owner);
    }

}