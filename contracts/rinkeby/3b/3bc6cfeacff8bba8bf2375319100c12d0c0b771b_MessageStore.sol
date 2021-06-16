pragma solidity >=0.4.24 <0.6.0;

import "./Ownable.sol";
contract MessageStore {
    
    string private message;
    
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
    
    function getMessage()  public view returns(string memory) {
        return message;
    }

}