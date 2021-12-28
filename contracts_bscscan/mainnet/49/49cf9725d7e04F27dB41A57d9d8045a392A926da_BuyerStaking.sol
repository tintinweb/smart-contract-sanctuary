// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Mining.sol";

contract BuyerStaking is DoublePool {
    bytes32 internal constant _limit_           = 'limit';
    bytes32 internal constant _DOTC_            = 'DOTC';
    bytes32 internal constant _punishTo_        = 'punishTo';
    bytes32 internal constant _expiry_          = 'expiry';

    mapping(address=>uint) stakeTimes;

    function __BuyerStaking_init_unchained(uint limit_, address DOTC_, address punishTo_, uint expiry_) public governance {
	    config[_limit_]     = limit_;
        config[_DOTC_]      = uint(DOTC_);
        config[_punishTo_]  = uint(punishTo_);
        config[_expiry_]    = expiry_;//now.add(expiry_);
	}
    
    function limit() virtual public view returns(uint) {
        return config[_limit_];
    }
    
    function enough(address buyer) virtual external view returns(bool) {
        return _balances[buyer] >= limit();
    }

    function punish(address buyer) virtual external updateReward2(buyer) updateReward2(address(config[_punishTo_])) {
        require(msg.sender == address(config[_DOTC_]), 'only DOTC');
        address punishTo = address(config[_punishTo_]);
        uint amt = _balances[buyer];
        _balances[buyer] = 0;
        _balances[punishTo] = _balances[punishTo].add(amt);

        emit Punish(buyer, amt);
    }
    event Punish(address buyer, uint amt);

    function stake(uint amount) virtual override public {
        require(_balances[msg.sender] == 0, 'already');
        require(amount == limit(), 'limit');
        stakeTimes[msg.sender] = now;

        super.stake(amount);
    }

    function withdrawEnable(address account) public view returns (bool){
        return ((now > stakeTimes[account].add(config[_expiry_]))&&(IDOTC(address(config[_DOTC_])).biddingN(account) == 0));
    }

    function withdraw(uint amount) virtual override public {
        require(amount == _balances[msg.sender], 'limit');
        require(now > stakeTimes[msg.sender].add(config[_expiry_]), 'only expired');
        require(IDOTC(address(config[_DOTC_])).biddingN(msg.sender) == 0, 'bidding');

        super.withdraw(amount);
    }
}

interface IDOTC {
    function biddingN(address buyer) external view returns(uint);
}