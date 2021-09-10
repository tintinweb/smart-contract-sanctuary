/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.8.7;

contract KingOfTheWall{
    
    string public currentProclamation;
    uint public currentTribute;
    
    event Broadcast(string proclamation);
    
    constructor() public {
        currentProclamation = "Initial Message";
        currentTribute = 0;
        emit Broadcast(currentProclamation);
    }
    
    function shout(string memory newProclamation) payable public {
        if(msg.value > currentTribute){
            currentProclamation = newProclamation;
            currentTribute = msg.value;
            emit Broadcast(currentProclamation);
        }
    }
    
    function getCurrentTribute() public view returns(uint){
        return currentTribute;
    }
    
    function getCurrentProclamation() public view returns(string memory){
        return currentProclamation;
    }
}