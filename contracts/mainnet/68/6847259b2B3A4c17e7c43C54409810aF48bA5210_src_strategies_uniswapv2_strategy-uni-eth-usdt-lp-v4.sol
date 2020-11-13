// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-uni-farm-base.sol";

contract StrategyUniEthUsdtLpV4 is StrategyUniFarmBase {
    // Token addresses
    address public uni_rewards = 0x6C3e4cb2E96B01F4b866965A91ed4437839A121a;
    address public uni_eth_usdt_lp = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyUniFarmBase(
            usdt,
            uni_rewards,
            uni_eth_usdt_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyUniEthUsdtLpV4";
    }
}
