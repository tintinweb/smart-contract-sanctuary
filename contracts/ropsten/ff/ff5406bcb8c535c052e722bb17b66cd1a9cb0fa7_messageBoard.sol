pragma solidity ^0.4.0;
 
 
contract messageBoard {
    string public message;
    
    function messageBoard1 (string initMessage) public {
        message = initMessage;
    }
    function editMessage (string _editMessage) public {
        message = _editMessage;
    }
     
 
}