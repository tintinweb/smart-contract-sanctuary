// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./SMinter.sol";

contract TurboGauge is SExactGauge {
    address public staking;
    mapping(address => uint) public lastTurboOf;
    uint public lastTurboSupply;

	function initialize(address governor, address _minter, address _lp_token, address _staking) virtual public initializer {
	    super.initialize(governor, _minter, _lp_token);
	    staking = _staking;
	}
    
	function ratioStaking(address addr) public view returns (uint r) {
        r = IStakingRewards2(staking).balanceOf(addr);
        r = r.mul(1 ether).div(IStakingRewards2(staking).stakingPerLPT(address(this)));
        r = r.mul(1 ether).div(balanceOf[addr]);
        if(now > lasttime)
            r = r.mul(IStakingRewards2(staking).spendAgeOf(addr)).div(now.sub(lasttime));
	}
	
	function factorOf(address addr) public view returns (uint f) {
	    f = IStakingRewards2(staking).factorOf(addr);
	    uint r = ratioStaking(addr);
	    if(r < 1 ether)
	        f = f.sub(1 ether).mul(r).div(1 ether).add(1 ether);
	}

    
    function virtualBalanceOf(address addr) virtual public view returns (uint) {
        if(span == 0 || totalSupply == 0)
            return balanceOf[addr];
        if(now == lasttime)
            return balanceOf[addr].add(lastTurboOf[addr]);
        return balanceOf[addr].mul(factorOf(addr)).div(1 ether);
    }
    
    function virtualTotalSupply() virtual public view returns (uint) {
        return totalSupply.add(lastTurboSupply);
    }
    
    function _virtualTotalSupply(address addr, uint vbo) virtual internal view returns (uint) {
        return virtualTotalSupply().add(vbo).sub(balanceOf[addr].add(lastTurboOf[addr]));
    }
    
    function _virtual_claimable_last(uint delta, uint sumPer, uint lastSumPer, uint vbo, uint _vts) virtual internal view returns (uint amount) {
        if(span == 0 || totalSupply == 0)
            return 0;
        
        amount = sumPer.sub(lastSumPer);
        amount = amount.add(delta.mul(1 ether).div(_vts));
        amount = amount.mul(vbo).div(1 ether);
    }

    function _checkpoint(address addr, bool _claim_rewards) virtual override internal {
        if(span == 0 || totalSupply == 0)
            return;
        
        uint vbo = virtualBalanceOf(addr);
        uint _vts = _virtualTotalSupply(addr, vbo);
        
        uint delta = claimableDelta();
        uint amount = _virtual_claimable_last(delta, sumMiningPer, sumMiningPerOf[addr], vbo, _vts);
        
        if(delta != amount)
            bufReward = bufReward.add(delta).sub(amount);
        if(delta > 0)
            sumMiningPer = sumMiningPer.add(delta.mul(1 ether).div(_vts));
        if(sumMiningPerOf[addr] != sumMiningPer)
            sumMiningPerOf[addr] = sumMiningPer;
        if(lastTurboOf[addr] != vbo.sub(balanceOf[addr]))
            lastTurboOf[addr] = vbo.sub(balanceOf[addr]);
        if(lastTurboSupply != _vts.sub(totalSupply))
            lastTurboSupply = _vts.sub(totalSupply);
        if(now > lasttime) {
            uint coinAge = balanceOf[addr].mul(IStakingRewards2(staking).stakingPerLPT(address(this)).div(1 ether).mul(now.sub(lasttime)));
            IStakingRewards2(staking).spendCoinAge(addr, coinAge);
        }
        lasttime = now;

        _checkpoint(addr, amount);
        _checkpoint_rewards(addr, _claim_rewards);
    }

}


