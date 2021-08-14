/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity ^0.4.18;

contract Greeter {
    
    struct GreateingMessage {
        string message;
        address owner;
    }
    address owner;
    GreateingMessage[] public greetings;
    modifier onlyOwner(){
              require(owner == msg.sender);
              _;
    }
    function Greeter() public {
        greetings.push(GreateingMessage("Hello Codefiction", msg.sender));
        owner = msg.sender;
    }
    
    function getGreting(uint idx)  public onlyOwner constant returns(string, address){
  
        GreateingMessage memory currentMessage = greetings[idx];    
        return (currentMessage.message, currentMessage.owner);
    }
    function setGreeting(string greetingMsg) public {
        greetings.push(GreateingMessage(greetingMsg, msg.sender));
    }
}