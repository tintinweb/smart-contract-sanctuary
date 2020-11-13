// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-uni-farm-base.sol";

contract StrategyUniEthDaiLpV4 is StrategyUniFarmBase {
    // Token addresses
    address public uni_rewards = 0xa1484C3aa22a66C62b77E0AE78E15258bd0cB711;
    address public uni_eth_dai_lp = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyUniFarmBase(
            dai,
            uni_rewards,
            uni_eth_dai_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyUniEthDaiLpV4";
    }
}
