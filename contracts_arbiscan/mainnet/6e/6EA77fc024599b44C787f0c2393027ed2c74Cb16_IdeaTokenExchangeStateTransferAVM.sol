// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./IIdeaTokenExchangeStateTransferAVM.sol";
import "./IInterestManagerStateTransferAVM.sol";
import "./IdeaTokenExchangeAVM.sol"; 

/**
 * @title IdeaTokenExchangeStateTransferAVM
 * @author Alexander Schlindwein
 *
 * Replaces the L2 IdeaTokenExchange logic for the state transfer from L1.
 * 
 * This implementation will disable all state-altering methods and adds state transfer
 * methods which can be called by the bridge contract.
 */
contract IdeaTokenExchangeStateTransferAVM is IdeaTokenExchangeAVM, IIdeaTokenExchangeStateTransferAVM {

    /**
     * Sets _tradingFeeInvested. Can only be called by the bridge.
     *
     * @param tradingFeeInvested The _tradingFeeInvested from L1
     */
    function setStaticVars(uint tradingFeeInvested) external override onlyBridge {
        _tradingFeeInvested = tradingFeeInvested;
        IInterestManagerStateTransferAVM(address(_interestManager)).addToTotalShares(tradingFeeInvested);

        emit InvestedState(0, address(0), 0, 0, tradingFeeInvested, 0, 0);
    }

    /**
     * Sets a market's state. Can only be called by the bridge.
     *
     * @param marketID The market's ID
     * @param dai The market's dai
     * @param invested The market's invested
     * @param platformFeeInvested The market's platformFeeInvested
     */
    function setPlatformVars(uint marketID, uint dai, uint invested, uint platformFeeInvested) external override onlyBridge {
        ExchangeInfo storage exchangeInfo = _platformsExchangeInfo[marketID];
        exchangeInfo.dai = dai;
        exchangeInfo.invested = invested;

        _platformFeeInvested[marketID] = platformFeeInvested;

        IInterestManagerStateTransferAVM(address(_interestManager)).addToTotalShares(invested.add(platformFeeInvested));

        emit InvestedState(marketID, address(0), dai, invested, _tradingFeeInvested, platformFeeInvested, 0);    }

    /**
     * Sets a tokens state and mints the existing supply to the bridge. Can only be called by the bridge.
     *
     * @param marketID The market's ID
     * @param tokenID The token's ID
     * @param supply The token's supply
     * @param dai The token's dai
     * @param invested The token's invested
     */
    function setTokenVarsAndMint(uint marketID, uint tokenID, uint supply, uint dai, uint invested) external override onlyBridge {
        TokenInfo memory tokenInfo = _ideaTokenFactory.getTokenInfo(marketID, tokenID);
        require(tokenInfo.exists, "not-exist");

        IIdeaToken ideaToken = tokenInfo.ideaToken;
        address ideaTokenAddress = address(ideaToken);

        _tokensExchangeInfo[ideaTokenAddress] = ExchangeInfo({
            dai: dai,
            invested: invested
        });

        if(invested > 0) {
            // When invested > 0 then supply > 0
            IInterestManagerStateTransferAVM(address(_interestManager)).addToTotalShares(invested);
            ideaToken.mint(msg.sender, supply);
        }
        
        emit InvestedState(marketID, ideaTokenAddress, dai, invested, _tradingFeeInvested, _platformFeeInvested[marketID], 0);
    }

    /* **********************************************
     * ************  Disabled functions  ************
     * ********************************************** 
     */
    function sellTokens(address ideaToken, uint amount, uint minPrice, address recipient) external override {
        ideaToken;
        amount;
        minPrice;
        recipient;

        revert("state-transfer");
    }

    function buyTokens(address ideaToken, uint amount, uint fallbackAmount, uint cost, address recipient) external override {
        ideaToken;
        amount;
        fallbackAmount;
        cost;
        recipient;

        revert("state-transfer");
    }

    function withdrawTokenInterest(address token) external override {
        token;

        revert("state-transfer");
    }

    function withdrawPlatformInterest(uint marketID) external override {
        marketID;

        revert("state-transfer");
    }

    function withdrawPlatformFee(uint marketID) external override {
        marketID;

        revert("state-transfer");
    }

    function withdrawTradingFee() external override {
        revert("state-transfer");
    }

    function setTokenOwner(address token, address owner) external override {
        token;
        owner;

        revert("state-transfer");
    }

    function setPlatformOwner(uint marketID, address owner) external override {
        marketID;
        owner;

        revert("state-transfer");
    }
}