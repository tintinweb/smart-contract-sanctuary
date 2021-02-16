// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "IIdeaTokenFactory.sol";

/**
 * @title AddMarketSpell
 * @author Alexander Schlindwein
 *
 * Spell to add a market
 */
contract AddMarketSpell {

    /**
     * Adds a market to the factory
     *
     * @param factory The address of the IdeaTokenFactory
     * @param marketName The name of the market
     * @param nameVerifier The address of the name verifier
     * @param baseCost The base cost
     * @param priceRise The price rise
     * @param hatchTokens The amount of hatch tokens
     * @param tradingFeeRate The trading fee
     * @param platformFeeRate The platform fee
     * @param allInterestToPlatform: If true, all interest goes to the platform instead of the token owner
     */
    function execute(address factory, string calldata marketName, address nameVerifier,
                     uint baseCost, uint priceRise, uint hatchTokens,
                     uint tradingFeeRate, uint platformFeeRate, bool allInterestToPlatform) external {

        IIdeaTokenFactory(factory).addMarket(marketName, nameVerifier,
                                              baseCost, priceRise, hatchTokens,
                                              tradingFeeRate, platformFeeRate, allInterestToPlatform);
    }
}