// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyUniFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public uni = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    // WETH/<token1> pair
    address public token1;

    // How much UNI tokens to keep?
    uint256 public keepUNI = 0;
    uint256 public constant keepUNIMax = 10000;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
    }

    // **** Setters ****

    function setKeepUNI(uint256 _keepUNI) external {
        require(msg.sender == timelock, "!timelock");
        keepUNI = _keepUNI;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects UNI tokens
        IStakingRewards(rewards).getReward();
        uint256 _uni = IERC20(uni).balanceOf(address(this));
        if (_uni > 0) {
            // 10% is locked up for future gov
            uint256 _keepUNI = _uni.mul(keepUNI).div(keepUNIMax);
            IERC20(uni).safeTransfer(
                IController(controller).treasury(),
                _keepUNI
            );
            _swapUniswap(uni, weth, _uni.sub(_keepUNI));
        }

        // Swap half WETH for DAI
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swapUniswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for ETH/DAI
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);

            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back UNI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
