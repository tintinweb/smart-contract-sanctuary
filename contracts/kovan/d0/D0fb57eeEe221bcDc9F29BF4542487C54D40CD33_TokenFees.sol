// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ITokenFees {
    function getFlatFee() view external returns(uint256);
    function setFlatFee(uint _tokenFee) external;

    function getTotalSupplyFee() view external returns(uint256);
    function setTotalSupplyFee(uint _tokenFee) external;
    
    function getTokenFeeAddress() view external returns(address);
    function setTokenFeeAddress(address payable _tokenFeeAddress) external;
}

contract TokenFees is Ownable{
    
    struct Settings {
        uint256 FLAT_FEE;
        uint256 TS_FEE; // totalSupply fee
        address payable TOKEN_FEE_ADDRESS;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.FLAT_FEE = 1e18;
        SETTINGS.TS_FEE = 2;
        SETTINGS.TOKEN_FEE_ADDRESS = payable(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1);
    }
    
    function getFlatFee() view external returns(uint256) {
        return SETTINGS.FLAT_FEE;
    }
    
    function setFlatFee(uint _flatFee) external onlyOwner {
        SETTINGS.FLAT_FEE = _flatFee;
    }

    function getTotalSupplyFee() view external returns(uint256) {
        return SETTINGS.TS_FEE;
    }
    
    function setTotalSupplyFee(uint _tsFee) external onlyOwner {
        SETTINGS.TS_FEE = _tsFee;
    }
    
    function getTokenFeeAddress() view external returns(address) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setTokenFeeAddress(address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
}