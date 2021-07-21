/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.6.6;

contract CoolNumberContract {
    uint public coolNumber = 10;
    
    function setCoolNumber(uint _coolNumber) public {
        coolNumber = _coolNumber;
    }
}