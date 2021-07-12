// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StrategyIron.sol";

import "./IIronSwap.sol";

contract StrategyIron3Pool is StrategyIron {
    
    address ironSwapAddress;

    constructor(
        address _vaultChefAddress,
        address _uniRouterAddress,
        address _ironChefAddress,
        address _ironSwapAddress,
        uint256 _pid,
        address _wantAddress,
        address _token0Address,
        address _earnedAddress,
        address[] memory _earnedToWmaticPath,
        address[] memory _earnedToUsdcPath,
        address[] memory _earnedToFishPath,
        address[] memory _earnedToToken0Path
    ) public {
        govAddress = msg.sender;
        vaultChefAddress = _vaultChefAddress;

        wantAddress = _wantAddress;
        token0Address = _token0Address;

        uniRouterAddress = _uniRouterAddress;
        ironChefAddress = _ironChefAddress;
        ironSwapAddress = _ironSwapAddress;
        pid = _pid;
        earnedAddress = _earnedAddress;

        earnedToWmaticPath = _earnedToWmaticPath;
        earnedToUsdcPath = _earnedToUsdcPath;
        earnedToFishPath = _earnedToFishPath;
        earnedToToken0Path = _earnedToToken0Path;

        transferOwnership(vaultChefAddress);
        
        _resetAllowances();
    }
    
    function earn() external override nonReentrant whenNotPaused onlyGov {
        // Harvest farm tokens
        IIronChef(ironChefAddress).harvest(pid, address(this));

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (earnedAmt > 0) {
            earnedAmt = distributeFees(earnedAmt);
            earnedAmt = distributeRewards(earnedAmt);
            earnedAmt = buyBack(earnedAmt);
    
            if (earnedAddress != usdcAddress) {
                // Swap half earned to token0
                _safeSwap(
                    earnedAmt,
                    earnedToToken0Path,
                    address(this)
                );
            }
    
            // Get want tokens, ie. add liquidity
            uint256 tokenAmt = IERC20(usdcAddress).balanceOf(address(this));
            
            if (tokenAmt > 0) {
                uint256[] memory swapAmounts = new uint256[](3);
                swapAmounts[0] = tokenAmt; // USDC
                IIronSwap(ironSwapAddress).addLiquidity(
                    swapAmounts,
                    0,
                    now.add(600)
                );
            }
    
            lastEarnBlock = block.number;
    
            _farm();
        }
    }

    function _resetAllowances() internal override {
        IERC20(wantAddress).safeApprove(ironChefAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            ironChefAddress,
            uint256(-1)
        );

        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(0));
        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );

        IERC20(token0Address).safeApprove(uniRouterAddress, uint256(0));
        IERC20(token0Address).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );

        IERC20(usdcAddress).safeApprove(rewardAddress, uint256(0));
        IERC20(usdcAddress).safeIncreaseAllowance(
            rewardAddress,
            uint256(-1)
        );

        IERC20(usdcAddress).safeApprove(ironSwapAddress, uint256(0));
        IERC20(usdcAddress).safeIncreaseAllowance(
            ironSwapAddress,
            uint256(-1)
        );
    }
}