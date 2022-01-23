/**
 *Submitted for verification at FtmScan.com on 2022-01-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OuranosWL {
    uint whitelistCount;
    uint whitelistAllocation;
    uint totalFund;
    address owner;

    address [] addressList;

    
    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint256) currentPayments;

    constructor() {
        owner = msg.sender;

        whitelistCount = 0;
        whitelistAllocation = 219000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setWhitelistAllocation(uint _whitelistAllocation) external onlyOwner{
        whitelistAllocation = _whitelistAllocation;
    }

    function getWhitelistAllocation() view public returns(uint) {
        return whitelistAllocation;
    }

    function getAddressCurrentPayments(address _address) view public returns(uint) {
        return currentPayments[_address];
    }

    function payWL() public payable {
        require(whitelistedAddresses[msg.sender], "You need to be whitelisted");
        require(msg.value + currentPayments[msg.sender] <= whitelistAllocation, "Payment above maximum allocation");
        currentPayments[msg.sender] += msg.value;
        totalFund += msg.value;
    }

    function addWhitelistAddress(address _address) external onlyOwner {
        if (whitelistedAddresses[_address] != true) {
            whitelistedAddresses[_address] = true;
            whitelistCount ++;
        }
    }

    function addMultipleAddresses(address[] memory addAddressList) external onlyOwner{
        for (uint i=0; i < addAddressList.length; i++) {
            if (whitelistedAddresses[addAddressList[i]] != true) {
                whitelistedAddresses[addAddressList[i]] = true;
                whitelistCount ++;
            }
        }
    }

    function removeWhitelistAddress(address _address) external onlyOwner {
        whitelistedAddresses[_address] = false;
        whitelistCount --;
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

    function IsWhitelisted(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function getCurrentBalance() view public returns(uint) {
        return address(this).balance;
    }

    function getTotalFund() view public returns(uint) {
        return totalFund;
    }

    function getWhitelistCount() view public returns(uint) {
        return whitelistCount;
    }

    function getOwner() view public returns(address) {
        return owner;
    }

}