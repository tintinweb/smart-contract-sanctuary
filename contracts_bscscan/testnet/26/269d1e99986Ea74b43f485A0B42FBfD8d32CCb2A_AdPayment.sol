/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Symple payment contract for ads. Stores adTransactionIdentifiers for easy transaction validation
contract AdPayment {
    uint128 private devPercentage;
    address private devWallet;
    address private owner;

    mapping(string => address) public adTransactionIdentifiers;

    constructor(uint128 _devPercentage, address _devWallet) {
        devPercentage = _devPercentage;
        devWallet = _devWallet;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this.");
        _;
    }

    modifier onlyStakeholders {
        require(msg.sender == owner || msg.sender == devWallet, "Only stakeholders can call this.");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdrawAllFunds() public onlyStakeholders {
        uint256 devAmount = address(this).balance * devPercentage / 100;
        uint256 ownerAmount = address(this).balance - devAmount;

        payable(devWallet).transfer(devAmount);
        payable(owner).transfer(ownerAmount);
    }

    function transferWei(string calldata _adTransactionIdentifier) public payable {        
        adTransactionIdentifiers[_adTransactionIdentifier] = msg.sender;
    }

    function checkAdTransaction (string calldata _adTransactionIdentifier) public view returns (address) {
        return adTransactionIdentifiers[_adTransactionIdentifier];
    }
}