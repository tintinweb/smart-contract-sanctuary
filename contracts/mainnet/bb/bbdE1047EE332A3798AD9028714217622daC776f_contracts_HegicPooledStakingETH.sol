// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./HegicPooledStaking.sol";

contract HegicPooledStakingETH is HegicPooledStaking {

    constructor(IERC20 _token, IHegicStaking _staking) public HegicPooledStaking(_token, _staking, "ETH Staked HEGIC", "sHEGICETH") {
    }

    function _transferProfit(uint _amount, address _account, uint _fee) internal override{
        uint netProfit = _amount.mul(uint(100).sub(_fee)).div(100);
        payable(_account).transfer(netProfit);
        FEE_RECIPIENT.transfer(_amount.sub(netProfit));
    }

    function updateProfit() public override {
        uint profit = staking.profitOf(address(this));
        if(profit > 0) profit = staking.claimProfit();
        if(lockedBalance <= 0) FALLBACK_RECIPIENT.transfer(profit);
        else totalProfitPerToken = totalProfitPerToken.add(profit.mul(ACCURACY).div(lockedBalance));
    }
}