// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./IdeaTokenFactory.sol"; 

/**
 * @title IdeaTokenFactoryStateTransfer
 * @author Alexander Schlindwein
 *
 * Replaces the L1 IdeaTokenFactory logic for the state transfer to Optimism L2.
 * 
 * This implementation will disable most methods.
 */
contract IdeaTokenFactoryStateTransfer is IdeaTokenFactory {

    /* **********************************************
     * ************  Disabled functions  ************
     * ********************************************** 
     */

    function initialize(address owner, address ideaTokenExchange, address ideaTokenLogic) external override {
        owner; ideaTokenExchange; ideaTokenLogic;
        revert("x");
    }

    function addMarket(string calldata marketName, address nameVerifier,
                       uint baseCost, uint priceRise, uint hatchTokens,
                       uint tradingFeeRate, uint platformFeeRate, bool allInterestToPlatform) external override {
        marketName; nameVerifier; baseCost; priceRise; hatchTokens; tradingFeeRate; platformFeeRate; allInterestToPlatform;
        revert("x");
    }

    function emitNewMarketEvent(MarketDetails memory marketDetails) internal override {
        marketDetails;
        revert("x");
    }

    function addToken(string calldata tokenName, uint marketID, address lister) external override {
        tokenName; marketID; lister;
        revert("x");
    }

    function isValidTokenName(string calldata tokenName, uint marketID) public view override returns (bool) {
        tokenName; marketID;
        revert("x");
    }

    function setTradingFee(uint marketID, uint tradingFeeRate) external override {
        marketID; tradingFeeRate;
        revert("x");
    }

    function setPlatformFee(uint marketID, uint platformFeeRate) external override {
        marketID; platformFeeRate;
        revert("x");
    }

    function setNameVerifier(uint marketID, address nameVerifier) external override {
        marketID; nameVerifier;
        revert("x");
    }
}