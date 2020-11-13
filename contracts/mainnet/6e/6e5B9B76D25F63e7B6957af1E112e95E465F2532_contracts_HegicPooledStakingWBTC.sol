// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./HegicPooledStaking.sol";

contract HegicPooledStakingWBTC is HegicPooledStaking {

    IERC20 public immutable underlying;

    constructor(IERC20 _token, IHegicStaking _staking, IERC20 _underlying) public 
        HegicPooledStaking(_token, _staking, "WBTC Staked HEGIC", "sHEGICWBTC") {
        underlying = _underlying;
    }

     /**
     * @notice Support internal function. Calling it will transfer _amount WBTC to _account. 
     * If FEE > 0, a FEE% commission will be paid to FEE_RECIPIENT
     * @param _amount Amount to transfer
     * @param _account Account that will receive profit
     */
    function _transferProfit(uint _amount, address _account, uint _fee) internal override {
        uint netProfit = _amount.mul(uint(100).sub(_fee)).div(100);
        underlying.safeTransfer(_account, netProfit);
        underlying.safeTransfer(FEE_RECIPIENT, _amount.sub(netProfit));
    }

    /**
     * @notice claims profit from Hegic's Staking Contrats and splits it among all currently staked tokens
     */
    function updateProfit() public override {
        uint profit = staking.profitOf(address(this));
        if(profit > 0){ 
            profit = staking.claimProfit();
            if(lockedBalance <= 0) underlying.safeTransfer(FALLBACK_RECIPIENT, profit);
            else totalProfitPerToken = totalProfitPerToken.add(profit.mul(ACCURACY).div(lockedBalance));
        }
    }
}