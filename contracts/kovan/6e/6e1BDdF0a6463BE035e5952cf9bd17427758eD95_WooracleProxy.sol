/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

/*

    Copyright 2020 Wootrade.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IWooracle {
    function getQuoteToken() external view returns (string memory);
    function getQuote() external view returns (address);
    function getPrice(address base) external view returns (string memory baseSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp);
}

interface IWooracleAdvanced {
    function getQuoteToken() external view returns (string memory);
    function getQuote() external view returns (address);
    function getPriceAdvanced(address base, string memory apikey) external view returns (string memory baseSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp);
}

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

contract WooracleProxy is InitializableOwnable {
    address private _Wooracle_;
    address private _WooracleAdvanced_;

    constructor() public{
        initOwner(msg.sender);
    }

    function reset(address addr, address advAddr) public onlyOwner
    {
        _Wooracle_ = addr;
        _WooracleAdvanced_ = advAddr;
    }

    function updateWooacle(address addr) public onlyOwner
    {
        _Wooracle_ = addr;
    }

    function updateWooacleAdvanced(address addr) public onlyOwner
    {
        _WooracleAdvanced_ = addr;
    }

    function getQuoteToken() public view returns (string memory)
    {
        return IWooracle(_Wooracle_).getQuoteToken();
    }

    function getQuote() public view returns (address)
    {
        return IWooracle(_Wooracle_).getQuote();
    }

    function getPrice(address base) external view returns (string memory baseSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp)
    {
        return IWooracle(_Wooracle_).getPrice(base);
    }

    function getQuoteTokenAdvanced() public view returns (string memory)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getQuoteToken();
    }

    function getQuoteAdvanced() public view returns (address)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getQuote();
    }

    function getPriceAdvanced(address base, string memory apikey) external view returns (string memory baseSymbol,uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getPriceAdvanced(base, apikey);
    }

}