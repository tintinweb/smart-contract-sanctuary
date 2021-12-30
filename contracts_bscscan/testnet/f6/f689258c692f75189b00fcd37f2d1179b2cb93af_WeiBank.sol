/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// User transfers money to another wallet and bank keeps 5%
contract WeiBank {
    uint256 public maxAmountWei; // 18 decimals on BSC BNB
    uint256 public comission;
    uint256 public totalTransactions;
    address private owner;

    constructor(uint256 _maxAmountWei, uint256 _commission) {
        maxAmountWei = _maxAmountWei;
        comission = _commission;
        totalTransactions = 0;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this.");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdrawAllComissions() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function transferWei(address _destination) public payable {
        require(msg.value <= maxAmountWei, "You can't send that much.");
        
        uint256 totalToTransfer = msg.value * (100 - comission) / 100;
        payable(_destination).transfer(totalToTransfer);
        totalTransactions += 1;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalTransactions() public view returns (uint256) {
        return totalTransactions;
    }
}