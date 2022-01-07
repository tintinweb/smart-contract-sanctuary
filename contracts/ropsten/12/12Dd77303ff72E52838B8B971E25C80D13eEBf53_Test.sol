/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity ^0.5.2;

contract Test {
    uint256 amount = 0;
    event SetAmount(uint256 before_, uint256 after_, uint256 a);
    function getAmount() public view returns (uint256) {
        return amount;
    }
    function setAmount(uint256 a) public {
        uint temp1 = amount;
        amount = amount + a;
        emit SetAmount(temp1, amount, a);
    }
}