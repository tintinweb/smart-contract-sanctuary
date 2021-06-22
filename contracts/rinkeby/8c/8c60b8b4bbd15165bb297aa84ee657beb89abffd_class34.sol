/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.4.0;
contract class34 {
    uint constant x = 32**22 + 8;
    bytes32 constant myHash = keccak256("abc");
  
    uint time = 5;
    
    constructor() public {
        //x = 3;    // x is constant, so it can't be modified.
    }
    
    // use getTime() and setTime(uint32) to modify variable 
    function getTime() public view returns(uint){
        if(time <= 86400 && time >= 0)
         return time;
        else
         return 0;
    }    
    function setTime(uint32 key) public {
        if(time + key >= 86400)
            time = 86400;
        else
            time = time + key;
    }
}