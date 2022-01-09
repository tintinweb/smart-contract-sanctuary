/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: Bank.sol

contract Bank {
    mapping(address => uint256) public addressToAmount;

    function deposit() public payable {
        addressToAmount[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public payable {
        require(addressToAmount[msg.sender] >= _amount, "not enough funds");
        payable(msg.sender).transfer(_amount);
    }

    function assets() public view returns (uint256) {
        return address(this).balance;
    }
}