/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

pragma solidity ^0.6.6;

contract CoolNumberContract {
    uint public coolNumber = 10;
    
    function setCoolNumber(uint _coolNumber) public {
        coolNumber = _coolNumber;
    }
}