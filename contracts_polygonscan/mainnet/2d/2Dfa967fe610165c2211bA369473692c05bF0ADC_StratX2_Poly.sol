/**
 *Submitted for verification at BscScan.com on 2021-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StratX2.sol";

interface IQuickswapFarm {
    // Deposit LP tokens to MasterChef for CAKE allocation.
    function stake(uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) external;
    
    function getReward() external;
}

contract StratX2_Poly is StratX2 {
    constructor(
        address[] memory _addresses,
        uint256 _pid,
        bool[] memory _flags,
        address[] memory _earnedToCHERRYPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _entranceFeeFactor,
        uint256 _distributionRatio,
        uint256 _withdrawFeeFactor
    ) public {
        wbnbAddress = _addresses[0];
        govAddress = _addresses[1];
        cherryFarmAddress = _addresses[2];
        CHERRYAddress = _addresses[3];

        wantAddress = _addresses[4];
        token0Address = _addresses[5];
        token1Address = _addresses[6];
        earnedAddress = _addresses[7];

        farmContractAddress = _addresses[8];
        pid = _pid;
        isCAKEStaking = _flags[0];
        isSameAssetDeposit = _flags[1];
        isCherryComp = _flags[2];
        isVaultComp = _flags[3];

        uniRouterAddress = _addresses[9];
        earnedToCHERRYPath = _earnedToCHERRYPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;

        controllerFee = _controllerFee;
        rewardsAddress = _addresses[10];
        buyBackRate = _buyBackRate;
        buyBackAddress = _addresses[11];
        depositFeeFundAddress = _addresses[12];
        delegateFundAddress = _addresses[13];
        entranceFeeFactor = _entranceFeeFactor;
        distributionDepositRatio = _distributionRatio;
        withdrawFeeFactor = _withdrawFeeFactor;

        transferOwnership(cherryFarmAddress);
    }
    
    function _farm() internal override {
        require(isCherryComp, "!isCherryComp");
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal.add(wantAmt);
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        IQuickswapFarm(farmContractAddress).stake(wantAmt);
    }

    function _unfarm(uint256 _wantAmt) internal override {
        IQuickswapFarm(farmContractAddress).withdraw(_wantAmt);
    }
    
    function earn() public override nonReentrant whenNotPaused {
        require(isCherryComp, "!isCherryComp");
        if (onlyGov) {
            require(msg.sender == govAddress, "!gov");
        }

        // Harvest farm tokens
        IQuickswapFarm(farmContractAddress).getReward();

        if (earnedAddress == wbnbAddress) {
            _wrapBNB();
        }

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        if (isVaultComp) {
            earnedAmt = distributeFees(earnedAmt);

            if (isCAKEStaking || isSameAssetDeposit) {
                lastEarnBlock = block.number;
                _farm();
                return;
            }

            IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
            IERC20(earnedAddress).safeIncreaseAllowance(
                uniRouterAddress,
                earnedAmt
            );

            if (earnedAddress != token0Address) {
                // Swap half earned to token0
                _safeSwap(
                    uniRouterAddress,
                    earnedAmt.div(2),
                    slippageFactor,
                    earnedToToken0Path,
                    address(this),
                    block.timestamp.add(600)
                );
            }

            if (earnedAddress != token1Address) {
                // Swap half earned to token1
                _safeSwap(
                    uniRouterAddress,
                    earnedAmt.div(2),
                    slippageFactor,
                    earnedToToken1Path,
                    address(this),
                    block.timestamp.add(600)
                );
            }

            // Get want tokens, ie. add liquidity
            uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
            uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
            if (token0Amt > 0 && token1Amt > 0) {
                IERC20(token0Address).safeIncreaseAllowance(
                    uniRouterAddress,
                    token0Amt
                );
                IERC20(token1Address).safeIncreaseAllowance(
                    uniRouterAddress,
                    token1Amt
                );
                IPancakeRouter02(uniRouterAddress).addLiquidity(
                    token0Address,
                    token1Address,
                    token0Amt,
                    token1Amt,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(600)
                );
            }

            lastEarnBlock = block.number;

            _farm();
        } else {
            delegateFees(earnedAmt);
        }
    }

}