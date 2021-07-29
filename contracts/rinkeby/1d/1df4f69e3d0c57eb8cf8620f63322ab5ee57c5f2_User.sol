/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.8.0;
contract User {
     address private owner;
     uint private blocklock;
     uint constant BLOCK_HEIGHT =20;
     uint constant INFO_EVENT = 4;
      struct User{
            
        string email_id; 
    }
     mapping(bytes32=>User) public users;
     
     event userGenerated(string _email_id);
       event ChangeNotification(address indexed sender, uint status, bytes32 notificationMsg);
      
      function sendEvent(uint _status, bytes32 _notification) internal returns(bool) {
      
        return true;
    }
      
    
   
    
      modifier onlyBy(address _user) {
        if (msg.sender != _user) {
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
        string memory _email_id) public {
            bytes32 byte_email_id = stringToBytes32(_email_id);
           users[byte_email_id] = User(_email_id);
            emit userGenerated(_email_id);
        }
         function getData(string memory _email_id) public view returns(string memory) {
              bytes32 byte_email_id = stringToBytes32(_email_id);
             User memory temp = users[byte_email_id];
             return (temp.email_id);
         }
    
}