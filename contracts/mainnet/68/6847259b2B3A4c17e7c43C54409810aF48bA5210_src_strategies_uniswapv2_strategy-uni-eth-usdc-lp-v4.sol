// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../strategy-uni-farm-base.sol";

contract StrategyUniEthUsdcLpV4 is StrategyUniFarmBase {
    // Token addresses
    address public uni_rewards = 0x7FBa4B8Dc5E7616e59622806932DBea72537A56b;
    address public uni_eth_usdc_lp = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyUniFarmBase(
            usdc,
            uni_rewards,
            uni_eth_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyUniEthUsdcLpV4";
    }
}
