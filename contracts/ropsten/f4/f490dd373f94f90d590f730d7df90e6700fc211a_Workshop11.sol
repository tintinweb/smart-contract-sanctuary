/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.4.24;

contract Workshop11 {
    uint public balances;
    uint public rate_percent = 5;
    
    function update(uint _balances) public { 
        balances = _balances;
    }
    function getInterest() public view returns (uint) {
        uint interest = balances * rate_percent / 100;
        return interest;
    }    
}