/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.7.0;

contract bank{
    uint256 private bal = 0;

    function deposit(uint256 amt) public {
        bal += amt;
    }

    function withdraw(uint256 amt) public {
        bal -= amt;
    }

    function getBalance() public view returns(uint256) {
        return bal;
    }
}