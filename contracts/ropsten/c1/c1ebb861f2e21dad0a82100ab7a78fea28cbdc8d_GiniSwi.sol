/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.4.24;

contract GiniSwi {

        uint public girl;
        string public setName;
        bool a1;
    
    constructor() public {
    }
    
    function setNum(uint boy) public {
        girl = boy; //測試中文
    }
    
    function setName2(string _setName) public {
        setName = _setName;
    }
    
    
}