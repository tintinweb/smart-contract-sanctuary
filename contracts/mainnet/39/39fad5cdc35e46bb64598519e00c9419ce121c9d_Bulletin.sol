pragma solidity ^0.4.13;
contract Bulletin {
    
    string public message = &quot;&quot;;
    address public owner;
    
    function Bulletin(){
        owner = msg.sender;
    }
    
    function setMessage(string _message){
        require(msg.sender == owner);
        message = _message;
    }
}