/**
 *Submitted for verification at BscScan.com on 2021-07-22
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

    function getPrice(address base) external view returns (uint256 latestPrice, bool feasible);

    function getState(address base) external view returns (uint256 latestPrice, uint64 spread, uint128 coefficient,
        bool feasible);

    function getLatestPrice(address base) external view returns (uint256 latestPrice);

    function getSpread(address base) external view returns (uint64 spread);

    function getCoefficient(address base) external view returns (uint128 coeff);

    function isValid(address base) external view returns (bool valid);

    function isStale(address base) external view returns (bool stale);

    function isFeasible(address base) external view returns (bool feasible);

    function getTimestamp() external view returns (uint256 timestamp);
}

interface IWooracleAdvanced
{
    function getQuoteToken() external view returns (string memory);

    function getQuote() external view returns (address);

    function getPriceAdvanced(address base, address from) external view returns (uint256 latestPrice, bool feasible);

    function getStateAdvanced(address base, address from) external view returns (uint256 latestPrice, uint64 spread,
        uint128 coefficient, bool feasible);

    function getLatestPriceAdvanced(address base, address from) external view returns (uint256 latestPrice);

    function getSpreadAdvanced(address base, address from) external view returns (uint64 spread);

    function getCoefficientAdvanced(address base, address from) external view returns (uint128 coeff);

    function isValidAdvanced(address base, address from) external view returns (bool valid);

    function isStaleAdvanced(address base, address from) external view returns (bool stale);

    function isFeasibleAdvanced(address base, address from) external view returns (bool feasible);

    function isWhiteListed(address from) external view returns (bool whitelisted);

    function getTimestampAdvanced(address from) external view returns (uint256 timestamp);
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

    constructor() public {
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

    function getPrice(address base) external view returns (uint256 latestPrice, bool feasible)
    {
        return IWooracle(_Wooracle_).getPrice(base);
    }

    function getState(address base) external view returns (uint256 latestPrice, uint64 spread, uint128 coefficient,
        bool feasible)
    {
        return IWooracle(_Wooracle_).getState(base);
    }

    function getLatestPrice(address base) external view returns (uint256 latestPrice)
    {
        return IWooracle(_Wooracle_).getLatestPrice(base);
    }

    function getSpread(address base) external view returns (uint64 spread)
    {
        return IWooracle(_Wooracle_).getSpread(base);
    }

    function getCoefficient(address base) external view returns (uint128 coeff)
    {
        return IWooracle(_Wooracle_).getCoefficient(base);
    }

    function getIsValid(address base) external view returns (bool valid)
    {
        return IWooracle(_Wooracle_).isValid(base);
    }

    function getIsStale(address base) external view returns (bool isStale)
    {
        return IWooracle(_Wooracle_).isStale(base);
    }

    function getTimestamp() external view returns (uint256 timestamp)
    {
        return IWooracle(_Wooracle_).getTimestamp();
    }

    function getIsFeasible(address base) external view returns (bool feasible)
    {
        return IWooracle(_Wooracle_).isFeasible(base);
    }

    function getQuoteTokenAdvanced() public view returns (string memory)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getQuoteToken();
    }

    function getQuoteAdvanced() public view returns (address)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getQuote();
    }

    function getPriceAdvanced(address base) external view returns (uint256 latestPrice, bool feasible)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getPriceAdvanced(base, msg.sender);
    }

    function getStateAdvanced(address base) external view returns (uint256 latestPrice, uint64 spread, uint128 coeff,
        bool feasible)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getStateAdvanced(base, msg.sender);
    }

    function getSpreadAdvanced(address base) external view returns (uint64 spread)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getSpreadAdvanced(base, msg.sender);
    }

    function getCoefficientAdvanced(address base) external view returns (uint128 coeff)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getCoefficientAdvanced(base, msg.sender);
    }

    function getLatestPriceAdvanced(address base) external view returns (uint256 latestPrice)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getLatestPriceAdvanced(base, msg.sender);
    }

    function getIsValidAdvanced(address base) external view returns (bool isValid)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).isValidAdvanced(base, msg.sender);
    }

    function getIsStaleAdvanced(address base) external view returns (bool isStale)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).isStaleAdvanced(base, msg.sender);
    }

    function getTimestampAdvanced() external view returns (uint256 timestamp)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).getTimestampAdvanced(msg.sender);
    }

    function getIsFeasibleAdvanced(address base) external view returns (bool feasible)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).isFeasibleAdvanced(base, msg.sender);
    }

    function getIsWhiteListed() external view returns (bool whitelisted)
    {
        return IWooracleAdvanced(_WooracleAdvanced_).isWhiteListed(msg.sender);
    }
}