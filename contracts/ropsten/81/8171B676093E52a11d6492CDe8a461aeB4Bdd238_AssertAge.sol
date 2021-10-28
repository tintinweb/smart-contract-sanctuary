/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.8.0;

contract AssertAge {
    uint256 public amount;
    address contractWallet;
    
    constructor() payable {
        amount = msg.value;
    }
    
    function validation(int256 age) public {
        assert(age >= 18);
        payable(msg.sender).transfer(amount);
        amount = 0;
    }
    
}