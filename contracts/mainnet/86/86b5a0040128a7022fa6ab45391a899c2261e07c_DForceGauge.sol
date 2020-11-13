// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./SMinter.sol";

interface RewardPool {
    function df() external returns (address);
    function stake(uint) external;
    function withdraw(uint) external;
    function getReward() external;
    function earned(address) external view returns (uint);
}

contract DForceGauge is SExactGauge {

	function initialize(address governor, address _minter, address _lp_token, address rewardPool) public initializer {
	    super.initialize(governor, _minter, _lp_token);
	    
	    reward_contract = rewardPool;
	    rewarded_token  = RewardPool(rewardPool).df();
	}
    
    function _deposit(address from, uint amount) virtual override internal {
        super._deposit(from, amount);                           // lp_token.safeTransferFrom(from, address(this), amount);
        lp_token.safeApprove(reward_contract, amount);
        RewardPool(reward_contract).stake(amount);
    }

    function _withdraw(address to, uint amount) virtual override internal {
        RewardPool(reward_contract).withdraw(amount);
        super._withdraw(to, amount);                            // lp_token.safeTransfer(to, amount);
    }
    
    function claim_rewards(address to) virtual override public {
        if(span == 0 || totalSupply == 0)
            return;
        
        _checkpoint_rewards(to, true);

        uint amount = rewards_for_[to][rewarded_token].sub(claimed_rewards_for_[to][rewarded_token]);
        if(amount > 0) {
            rewarded_token.safeTransfer(to, amount);
            claimed_rewards_for_[to][rewarded_token] = rewards_for_[to][rewarded_token];
        }
    }

    function _checkpoint_rewards(address addr, bool _claim_rewards) virtual override internal {
        if(span == 0 || totalSupply == 0)
            return;
        
        uint dr = 0;
        
        if(_claim_rewards) {
            dr = IERC20(rewarded_token).balanceOf(address(this));
            RewardPool(reward_contract).getReward();
            dr = IERC20(rewarded_token).balanceOf(address(this)).sub(dr);
        }

        uint amount = _claimable_last(addr, dr, reward_integral_[rewarded_token], reward_integral_for_[addr][rewarded_token]);
        if(amount > 0)
            rewards_for_[addr][rewarded_token] = rewards_for_[addr][rewarded_token].add(amount);
        
        if(dr > 0)
            reward_integral_[rewarded_token] = reward_integral_[rewarded_token].add(dr.mul(1 ether).div(totalSupply));
            
        if(reward_integral_for_[addr][rewarded_token] != reward_integral_[rewarded_token])
            reward_integral_for_[addr][rewarded_token] = reward_integral_[rewarded_token];
    }

    function claimable_reward(address addr) virtual override public view returns (uint r) {
        uint delta = RewardPool(reward_contract).earned(address(this));
        r = _claimable_last(addr, delta, reward_integral_[rewarded_token], reward_integral_for_[addr][rewarded_token]);
        r = r.add(rewards_for_[addr][rewarded_token].sub(claimed_rewards_for_[addr][rewarded_token]));
    }
    
}


