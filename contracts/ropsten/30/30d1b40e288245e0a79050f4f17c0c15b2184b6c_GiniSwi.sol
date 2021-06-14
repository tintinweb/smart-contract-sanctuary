/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.24;

contract GiniSwi {
    string public boy;
    string public girl;



 
 
     
    constructor() public {
        boy = "swichen";
        girl = "giniho";
    }
    
    function setName(string _setName) public {
       boy = _setName;
    }
    
    function setName2(string _setName) public {
        girl = _setName;
    }
}