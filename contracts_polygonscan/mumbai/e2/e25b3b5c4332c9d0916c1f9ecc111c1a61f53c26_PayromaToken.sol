// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "BEP20.sol";


contract PayromaToken is BEP20('Payroma Wallet', 'PYA') {
    //uint256 private _totalSupply = 20000000 * (10**18);

    uint256 private presaleAmount = 10000000 * (10**18);
    uint256 private privateSaleAmount = 1000000 * (10**18);
    uint256 private liquidityPoolAmount = 4000000 * (10**18);
    uint256 private partnershipsAmount = 1000000 * (10**18);
    uint256 private teamAmount = 3000000 * (10**18);
    uint256 private marketingAmount = 1000000 * (10**18);

    address private presaleWallet = 0xAE4620Dd16C7a4e05cEcA70F22Fb597F80B65eD0;
    address private privateSaleWallet = 0x801BF1FB7E4B4093bC3885433Dae76BCb747A957;
    address private partnershipsWallet = 0xe77B534470c8c7ae23ee1A40eA8E2b19DE31D75A;
    address private teamWallet = 0xa048750be2069f139c0ed288224671150c5a26c6;
    address private marketingWallet = 0x6c9097a1e568f02f02812b4d5DFC67f75ac0C1CC;

    constructor() public {
        //_mint(_msgSender(), _totalSupply);

        _mint(presaleWallet, presaleAmount);
        _mint(privateSaleWallet, privateSaleAmount);
        _mint(partnershipsWallet, partnershipsAmount);
        _mint(teamWallet, teamAmount.add(liquidityPoolAmount));
        _mint(marketingWallet, marketingAmount);
    }
    
    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) public returns(bool) {
        require(addresses.length == amounts.length,"Mismatch between addresses and amounts count");

        uint256 totalAmount = 0;
        for (uint i=0; i < addresses.length; i++) {
            totalAmount = totalAmount + amounts[i];
        }

        require(balanceOf(_msgSender()) >= totalAmount, "Balance is not enough");

        for (uint i=0; i < addresses.length; i++) {
            transfer(addresses[i], amounts[i]);
        }

        return true;
    }
}