/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.8.7;

contract CoolNumberContract {
    uint public coolNumber = 10;
    
    function setCoolNumber(uint _coolNumber) public {
        coolNumber = _coolNumber;
    }
}