/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.4.0;
contract SmartContract {
     address private owner;
     address private override;
     uint private blocklock;
     string public encryptionPublicKey;
     string public signingPublickey;
     uint constant BLOCK_HEIGHT =20;
      uint constant INFO_EVENT = 4;
     uint constant SIG_CHANGE_EVENT = 3;
    
    struct User  {
    string user_id;        
    string first_name;
    string last_name;
    string  gender;
    string email;
    string phone_number;
    string user_address;
    }
    
    
    mapping(bytes32 => User) public users;
      event userGenerated(bytes32 _userId);
       event ChangeNotification(address indexed sender, uint status, bytes32 notificationMsg);
      
      function sendEvent(uint _status, bytes32 _notification) internal returns(bool) {
        ChangeNotification(owner, _status, _notification);
        return true;
    }
      
    
    function SmartContract() {
        owner = msg.sender;
        override = owner;
        blocklock = block.number - BLOCK_HEIGHT;
       }
    
      modifier onlyBy(address _account) {
        if (msg.sender != _account) {
            revert();
        }
        _;
    }
    
    modifier checkBlockLock() {
        if (blocklock + BLOCK_HEIGHT > block.number) {
            revert();
        }
        _;
    }
    
     modifier blockLock() {
        blocklock = block.number;
        _;
    }
    
    struct Attribute {
        bytes32 hash;
        mapping(bytes32 => Endorsement) endorsements;
    }
    
    struct Endorsement {
        address endorser;
        bytes32 hash;
        bool accepted;
    }
    
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0*0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }
    
     function generateUser(
        string  memory _user_id,
        string memory _first_name,
        string  memory _last_name, 
        string memory _gender, 
        string memory _email,
        string memory _phone_number,
        string memory _user_address) public {
             bytes32 byte_user_id = stringToBytes32(_user_id);
            users[byte_user_id] = User( _user_id, _first_name, _last_name, _gender, _email, _phone_number, _user_address);
            emit userGenerated(byte_user_id);
            
        }
        
    function getData(string memory _id) public view returns(string memory, string memory, string memory, string memory, string memory, string memory) {
        bytes32 byte_id = stringToBytes32(_id);
        User memory temp = users[byte_id];
        return (temp.first_name, temp.last_name, temp.gender, temp.email, temp.phone_number, temp.user_address);
         emit userGenerated(byte_id);
    }
    
   

    
    
     function setEncryptionPublicKey(string _myEncryptionPublicKey) onlyBy(owner) checkBlockLock() returns(bool) {
        encryptionPublicKey = _myEncryptionPublicKey;
        sendEvent(SIG_CHANGE_EVENT, "Encryption key added");
        return true;
    }
    
     
   
     
    
 
}