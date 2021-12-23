/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedDonation {
    address payable private _beneficiaryWallet;
    string private _beneficiaryName;
    string private _beneficiaryAddress;
    string private _beneficiaryDescription;

    constructor(address payable beneficiaryWallet_, string memory beneficiaryName_, string memory beneficiaryAddress_,
        string memory beneficiaryDescription_)
    {
        _beneficiaryWallet = beneficiaryWallet_;
        _beneficiaryName = beneficiaryName_;
        _beneficiaryAddress = beneficiaryAddress_;
        _beneficiaryDescription = beneficiaryDescription_;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0);

        (bool success,) = _beneficiaryWallet.call{value : balance}("");
        require(success, "Transfer failed.");
    }
}