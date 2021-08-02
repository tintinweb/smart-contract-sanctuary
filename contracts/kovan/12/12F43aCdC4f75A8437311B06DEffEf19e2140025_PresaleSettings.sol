// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Forked from Ethereum mainnet for Julswap on Binance Smart Chain with no code changes
// WETH = WBNB
// ETH = BNB

// Settings to initialize presale contracts and edit fees.

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

contract PresaleSettings is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private EARLY_ACCESS_TOKENS;
    mapping(address => uint256) public EARLY_ACCESS_MAP;
    
    EnumerableSet.AddressSet private ALLOWED_REFERRERS;
    
    struct Settings {
        uint256 BASE_FEE; // base fee divided by 1000
        uint256 TOKEN_FEE; // token fee divided by 1000
        uint256 REFERRAL_FEE; // a referrals percentage of the presale profits divided by 1000
        address payable ETH_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        uint256 ETH_CREATION_FEE; // fee to generate a presale contract on the platform
        uint256 ROUND1_LENGTH; // length of round 1 in blocks
        uint256 MAX_PRESALE_LENGTH; // maximum difference between start and endblock
        address UNCL_ADDRESS;
        uint256 UNCL_ALLOCATION_AMOUNT; // amount of UNCL required for guaranteed allocation
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.BASE_FEE = 18; // 1.8%
        SETTINGS.TOKEN_FEE = 18; // 1.8%
        SETTINGS.REFERRAL_FEE = 200; // 20%
        SETTINGS.ETH_CREATION_FEE = 1e18;
        SETTINGS.ETH_FEE_ADDRESS = payable(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1);
        SETTINGS.TOKEN_FEE_ADDRESS = payable(0x0d9B1e53CBb251572D982d9F96520E8D40d22bb0);
        SETTINGS.ROUND1_LENGTH = 533; // 553 blocks = 2 hours
        SETTINGS.MAX_PRESALE_LENGTH = 93046; // 2 weeks
        SETTINGS.UNCL_ADDRESS = 0x08Bcd52219a0A5E7751Eeb54eF0B2523da0C2016;
        SETTINGS.UNCL_ALLOCATION_AMOUNT = 2e18;
    }

    function getUNCLInfo () external view returns (address, uint256) {
      return (SETTINGS.UNCL_ADDRESS, SETTINGS.UNCL_ALLOCATION_AMOUNT);
    }
    
    function getRound1Length () external view returns (uint256) {
        return SETTINGS.ROUND1_LENGTH;
    }

    function getMaxPresaleLength () external view returns (uint256) {
        return SETTINGS.MAX_PRESALE_LENGTH;
    }
    
    function getBaseFee () external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }
    
    function getTokenFee () external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    function getReferralFee () external view returns (uint256) {
        return SETTINGS.REFERRAL_FEE;
    }
    
    function getEthCreationFee () external view returns (uint256) {
        return SETTINGS.ETH_CREATION_FEE;
    }
    
    function getEthAddress () external view returns (address payable) {
        return SETTINGS.ETH_FEE_ADDRESS;
    }
    
    function getTokenAddress () external view returns (address payable) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setFeeAddresses(address payable _ethAddress, address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.ETH_FEE_ADDRESS = _ethAddress;
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
    
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee, uint256 _referralFee) external onlyOwner {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        SETTINGS.REFERRAL_FEE = _referralFee;
        SETTINGS.ETH_CREATION_FEE = _ethCreationFee;
    }

    function setUNCLAllocationAmount(uint256 _amount) external onlyOwner {
        SETTINGS.UNCL_ALLOCATION_AMOUNT = _amount;
    }
    
    function setRound1Length(uint256 _round1Length) external onlyOwner {
        SETTINGS.ROUND1_LENGTH = _round1Length;
    }

    function setMaxPresaleLength(uint256 _maxLength) external onlyOwner {
        SETTINGS.MAX_PRESALE_LENGTH = _maxLength;
    }
    
    function editAllowedReferrers(address payable _referrer, bool _allow) external onlyOwner {
        if (_allow) {
            ALLOWED_REFERRERS.add(_referrer);
        } else {
            ALLOWED_REFERRERS.remove(_referrer);
        }
    }
    
    function editEarlyAccessTokens(address _token, uint256 _holdAmount, bool _allow) external onlyOwner {
        if (_allow) {
            EARLY_ACCESS_TOKENS.add(_token);
        } else {
            EARLY_ACCESS_TOKENS.remove(_token);
        }
        EARLY_ACCESS_MAP[_token] = _holdAmount;
    }
    
    // there will never be more than 10 items in this array. Care for gas limits will be taken.
    // We are aware too many tokens in this unbounded array results in out of gas errors.
    function userHoldsSufficientRound1Token (address _user) external view returns (bool) {
        if (earlyAccessTokensLength() == 0) {
            return true;
        }
        for (uint i = 0; i < earlyAccessTokensLength(); i++) {
          (address token, uint256 amountHold) = getEarlyAccessTokenAtIndex(i);
          if (IERC20(token).balanceOf(_user) >= amountHold) {
              return true;
          }
        }
        return false;
    }
    
    function getEarlyAccessTokenAtIndex(uint256 _index) public view returns (address, uint256) {
        address tokenAddress = EARLY_ACCESS_TOKENS.at(_index);
        return (tokenAddress, EARLY_ACCESS_MAP[tokenAddress]);
    }
    
    function earlyAccessTokensLength() public view returns (uint256) {
        return EARLY_ACCESS_TOKENS.length();
    }
    
    // Referrers
    function allowedReferrersLength() external view returns (uint256) {
        return ALLOWED_REFERRERS.length();
    }
    
    function getReferrerAtIndex(uint256 _index) external view returns (address) {
        return ALLOWED_REFERRERS.at(_index);
    }
    
    function referrerIsValid(address _referrer) external view returns (bool) {
        return ALLOWED_REFERRERS.contains(_referrer);
    }
    
}