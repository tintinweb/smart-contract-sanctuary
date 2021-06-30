// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;


import "./ERC20.sol";


contract TeamToken is ERC20 {

    modifier checkIsAddressValid(address ethAddress)
    {
        require(ethAddress != address(0), "[Validation] invalid address");
        require(ethAddress == address(ethAddress), "[Validation] invalid address");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 supply,
        address owner,
        address feeWallet
    ) public checkIsAddressValid(owner) checkIsAddressValid(feeWallet) ERC20(name, symbol) {
        require(decimals >=8 && decimals <= 18, "[Validation] Not valid decimals");
        require(supply > 0, "[Validation] inital supply should be greater than 0");

        _setupDecimals(decimals);
        _mint(owner, supply * 995/1000);
        _mint(feeWallet, supply * 5/1000);       
    }
}