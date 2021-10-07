// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IDragonLair.sol";
import "./IStakingRewards.sol";
import "./IUniPair.sol";

import "./BaseStrategyLPSingle.sol";

contract StrategyQuickSwap is BaseStrategyLPSingle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant dQuick = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;
    address public stakingAddress;

    constructor(
        address _vaultChefAddress,
        address _uniRouterAddress,
        address _stakingAddress,
        address _wantAddress,
        address _earnedAddress,
        address[] memory _earnedToWmaticPath,
        address[] memory _earnedToUsdcPath,
        address[] memory _earnedToPawPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path
    ) public {
        govAddress = msg.sender;
        vaultChefAddress = _vaultChefAddress;

        wantAddress = _wantAddress;
        token0Address = IUniPair(wantAddress).token0();
        token1Address = IUniPair(wantAddress).token1();

        uniRouterAddress = _uniRouterAddress;
        stakingAddress = _stakingAddress;
        earnedAddress = _earnedAddress;

        earnedToWmaticPath = _earnedToWmaticPath;
        earnedToUsdcPath = _earnedToUsdcPath;
        earnedToPawPath = _earnedToPawPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;

        transferOwnership(vaultChefAddress);
        
        _resetAllowances();
    }

    function _vaultDeposit(uint256 _amount) internal override {
        IStakingRewards(stakingAddress).stake(_amount);
    }
    
    function _vaultWithdraw(uint256 _amount) internal override {
        IStakingRewards(stakingAddress).withdraw(_amount);
    }
    
    function _vaultHarvest() internal override {
        IStakingRewards(stakingAddress).getReward();
        IDragonLair(dQuick).leave(IERC20(dQuick).balanceOf(address(this)));
    }
    
    function vaultSharesTotal() public override view returns (uint256) {
        return IStakingRewards(stakingAddress).balanceOf(address(this));
    }
    
    function wantLockedTotal() public override view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this))
            .add(IStakingRewards(stakingAddress).balanceOf(address(this)));
    }

    function _resetAllowances() internal override {
        super._resetAllowances();

        IERC20(wantAddress).safeApprove(stakingAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            stakingAddress,
            uint256(-1)
        );

        IERC20(token0Address).safeApprove(uniRouterAddress, uint256(0));
        IERC20(token0Address).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );

        IERC20(token1Address).safeApprove(uniRouterAddress, uint256(0));
        IERC20(token1Address).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );
    }
    
    function _emergencyVaultWithdraw() internal override {
        IStakingRewards(stakingAddress).withdraw(vaultSharesTotal());
    }
}