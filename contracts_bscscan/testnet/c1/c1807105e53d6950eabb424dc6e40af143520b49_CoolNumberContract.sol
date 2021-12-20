/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity 0.5.10;

contract CoolNumberContract {
    uint public coolNumber = 10;
    
    function setCoolNumber(uint _coolNumber) public {
        coolNumber = _coolNumber;
    }
}