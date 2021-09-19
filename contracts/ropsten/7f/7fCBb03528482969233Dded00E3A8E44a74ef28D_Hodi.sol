/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity ^0.4.25;


contract Hodi{
    address creator;
    string message;
   
     constructor() public {
        creator = msg.sender;
    }
    function say() public constant returns (string)  {
        return message;
    }

    function setMessage(string _newMsg) public {
        message = _newMsg;
    }

    function f(uint start, uint daysAfter) public 
    {
        if (now >= start + daysAfter * 365 days) {
                selfdestruct(creator); 
            }
    }


}