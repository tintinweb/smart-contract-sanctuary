// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.11;

/**
 *  The Core Settings contract, which defines the global constants,
 *  which are used in the pool and related contracts (such as 
 *  OWNER_ADDRESS), and also defines the percentage simulation
 *  code, to use the same percentage precision across all contracts.
 */
contract CoreUniLotterySettings 
{
    // Percentage calculations.
    // As Solidity doesn't have floats, we have to use integers for
    // percentage arithmetics.
    // We set 1 percent to be equal to 1,000,000 - thus, we
    // simulate 6 decimal points when computing percentages.
    uint32 public constant PERCENT = 10 ** 6;
    uint32 constant BASIS_POINT = PERCENT / 100;

    uint32 constant _100PERCENT = 100 * PERCENT;

    /** The UniLottery Owner's address.
     *
     *  In the current version, The Owner has rights to:
     *  - Take up to 10% profit from every lottery.
     *  - Pool liquidity into the pool and remove it.
     *  - Start lotteries in auto or manual mode.
     */

    // Public Testnets: 0xb13CB9BECcB034392F4c9Db44E23C3Fb5fd5dc63 
    // MainNet:         0x1Ae51bec001a4fA4E3b06A5AF2e0df33A79c01e2

    address payable public constant OWNER_ADDRESS =
        address( uint160( 0x1Ae51bec001a4fA4E3b06A5AF2e0df33A79c01e2 ) );


    // Maximum lottery fee the owner can imburse on transfers.
    uint32 constant MAX_OWNER_LOTTERY_FEE = 1 * PERCENT;

    // Minimum amout of profit percentage that must be distributed
    // to lottery winners.
    uint32 constant MIN_WINNER_PROFIT_SHARE = 40 * PERCENT;

    // Min & max profits the owner can take from lottery net profit.
    uint32 constant MIN_OWNER_PROFITS = 3 * PERCENT;
    uint32 constant MAX_OWNER_PROFITS = 10 * PERCENT;

    // Min & max amount of lottery profits that the pool must get.
    uint32 constant MIN_POOL_PROFITS = 10 * PERCENT;
    uint32 constant MAX_POOL_PROFITS = 60 * PERCENT;

    // Maximum lifetime of a lottery - 1 month (4 weeks).
    uint32 constant MAX_LOTTERY_LIFETIME = 4 weeks;

    // Callback gas requirements for a lottery's ending callback,
    // and for the Pool's Scheduled Callback.
    // Must be determined empirically.
    uint32 constant LOTTERY_RAND_CALLBACK_GAS = 200000;
    uint32 constant AUTO_MODE_SCHEDULED_CALLBACK_GAS = 3800431;
}



