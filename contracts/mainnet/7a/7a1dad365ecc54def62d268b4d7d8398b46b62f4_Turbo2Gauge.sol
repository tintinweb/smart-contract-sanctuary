// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./DoubleGauge.sol";
import "./TurboGauge.sol";

contract Turbo2Gauge is DoubleGauge, TurboGauge {
	function initialize(address governor, address _minter, address _lp_token, address _reward_contract, address _rewarded_token, address _staking) virtual public initializer {
	    super.initialize(governor, _minter, _lp_token, _reward_contract, _rewarded_token);
	    staking = _staking;
	}
    
    function _deposit(address from, uint amount) virtual override(SExactGauge, DoubleGauge) internal {
        super._deposit(from, amount);
    }

    function _withdraw(address to, uint amount) virtual override(SExactGauge, DoubleGauge) internal {
        super._withdraw(to, amount);
    }
    
    function _checkpoint_rewards(address addr, bool _claim_rewards) virtual override(SExactGauge, DoubleGauge) internal {
        super._checkpoint_rewards(addr, _claim_rewards);
    }
    
    function claim_rewards(address to) virtual override(SExactGauge, DoubleGauge) public {
        super.claim_rewards(to);
    }

    function claimable_reward(address addr) virtual override(SExactGauge, DoubleGauge) public view returns (uint r) {
        return super.claimable_reward(addr);
    }
    
    function claimable_tokens(address addr) virtual override(SExactGauge, TurboGauge) public view returns (uint r) {
        return super.claimable_tokens(addr);
    }
    
    function _checkpoint(address addr, bool _claim_rewards) virtual override(SExactGauge, TurboGauge) internal {
        super._checkpoint(addr, _claim_rewards);
    }
}


