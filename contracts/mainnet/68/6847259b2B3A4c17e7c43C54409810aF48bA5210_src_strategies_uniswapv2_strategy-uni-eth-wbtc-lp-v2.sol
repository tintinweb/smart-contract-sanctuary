// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-uni-farm-base.sol";

contract StrategyUniEthWBtcLpV2 is StrategyUniFarmBase {
    // Token addresses
    address public uni_rewards = 0xCA35e32e7926b96A9988f61d510E038108d8068e;
    address public uni_eth_wbtc_lp = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyUniFarmBase(
            wbtc,
            uni_rewards,
            uni_eth_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyUniEthWBtcLpV2";
    }
}
