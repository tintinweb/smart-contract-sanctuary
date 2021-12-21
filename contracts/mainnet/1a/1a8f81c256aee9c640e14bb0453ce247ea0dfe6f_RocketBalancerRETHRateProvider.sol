/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |    DECENTRALISED STAKING PROTOCOL FOR ETHEREUM    |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind Ethereum staking pool protocol, designed to
  *  be community-owned, decentralised, and trustless.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface RocketTokenRETHInterface {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
}

contract RocketBalancerRETHRateProvider is IRateProvider {
    RocketTokenRETHInterface public immutable rocketTokenRETH;

    constructor (RocketTokenRETHInterface _rocketTokenRETH) {
        rocketTokenRETH = _rocketTokenRETH;
    }

    // Returns the ETH value of 1 rETH
    function getRate() external override view returns (uint256) {
        return rocketTokenRETH.getEthValue(1 ether);
    }
}