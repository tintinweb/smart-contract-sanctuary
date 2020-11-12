// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./SToken.sol";
import "./Governable.sol";

import "./TransferHelper.sol";


interface Minter {
    event Minted(address indexed recipient, address reward_contract, uint minted);

    function token() external view returns (address);
    function controller() external view returns (address);
    function minted(address, address) external view returns (uint);
    function allowed_to_mint_for(address, address) external view returns (bool);
    
    function mint(address gauge) external;
    function mint_many(address[8] calldata gauges) external;
    function mint_for(address gauge, address _for) external;
    function toggle_approve_mint(address minting_user) external;
}

interface LiquidityGauge {
    event Deposit(address indexed provider, uint value);
    event Withdraw(address indexed provider, uint value);
    event UpdateLiquidityLimit(address user, uint original_balance, uint original_supply, uint working_balance, uint working_supply);

    function user_checkpoint (address addr) external returns (bool);
    function claimable_tokens(address addr) external view returns (uint);
    function claimable_reward(address addr) external view returns (uint);
    function integrate_checkpoint()         external view returns (uint);

    function kick(address addr) external;
    function set_approve_deposit(address addr, bool can_deposit) external;
    function deposit(uint _value) external;
    function deposit(uint _value, address addr) external;
    function withdraw(uint _value) external;
    function withdraw(uint _value, bool claim_rewards) external;
    function claim_rewards() external;
    function claim_rewards(address addr) external;

    function minter()                       external view returns (address);
    function crv_token()                    external view returns (address);
    function lp_token()                     external view returns (address);
    function controller()                   external view returns (address);
    function voting_escrow()                external view returns (address);
    function balanceOf(address)             external view returns (uint);
    function totalSupply()                  external view returns (uint);
    function future_epoch_time()            external view returns (uint);
    function approved_to_deposit(address, address)   external view returns (bool);
    function working_balances(address)      external view returns (uint);
    function working_supply()               external view returns (uint);
    function period()                       external view returns (int128);
    function period_timestamp(uint)         external view returns (uint);
    function integrate_inv_supply(uint)     external view returns (uint);
    function integrate_inv_supply_of(address) external view returns (uint);
    function integrate_checkpoint_of(address) external view returns (uint);
    function integrate_fraction(address)    external view returns (uint);
    function inflation_rate()               external view returns (uint);
    function reward_contract()              external view returns (address);
    function rewarded_token()               external view returns (address);
    function reward_integral()              external view returns (uint);
    function reward_integral_for(address)   external view returns (uint);
    function rewards_for(address)           external view returns (uint);
    function claimed_rewards_for(address)   external view returns (uint);
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewards(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    // Mutative
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
    // Events
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

interface IStakingRewards2 is IStakingRewards {
	function totalMinted() external view returns (uint);
	function weightOfGauge(address gauge) external view returns (uint);
	function stakingPerLPT(address gauge) external view returns (uint);
	
	function stakeTimeOf(address account) external view returns (uint);
	function stakeAgeOf(address account) external view returns (uint);
	function factorOf(address account) external view returns (uint);

	function spendTimeOf(address account) external view returns (uint);
	function spendAgeOf(address account) external view returns (uint);
	function coinAgeOf(address account) external view returns (uint);
	
    function spendCoinAge(address account, uint coinAge) external returns (uint);
    
    event SpentCoinAge(address indexed gauge, address indexed account, uint coinAge);
}

contract SSimpleGauge is LiquidityGauge, Configurable {
    using SafeMath for uint;
    using TransferHelper for address;

    address override public minter;
    address override public crv_token;
    address override public lp_token;
    address override public controller;
    address override public voting_escrow;
    mapping(address => uint) override public balanceOf;
    uint override public totalSupply;
    uint override public future_epoch_time;
    
    // caller -> recipient -> can deposit?
    mapping(address => mapping(address => bool)) override public approved_to_deposit;
    
    mapping(address => uint) override public working_balances;
    uint override public working_supply;
    
    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    int128 override public period;
    uint256[100000000000000000000000000000] override public period_timestamp;
    
    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    uint256[100000000000000000000000000000] override public integrate_inv_supply;  // bump epoch when rate() changes
    
    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint) override public integrate_inv_supply_of;
    mapping(address => uint) override public integrate_checkpoint_of;
    
    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units: rate * t = already number of coins per address to issue
    mapping(address => uint) override public integrate_fraction;
    
    uint override public inflation_rate;
    
    // For tracking external rewards
    address override public reward_contract;
    address override public rewarded_token;
    
    uint override public reward_integral;
    mapping(address => uint) override public reward_integral_for;
    mapping(address => uint) override public rewards_for;
    mapping(address => uint) override public claimed_rewards_for;
    

	uint public span;
	uint public end;

	function initialize(address governor, address _minter, address _lp_token) public initializer {
	    super.initialize(governor);
	    
	    minter      = _minter;
	    crv_token   = Minter(_minter).token();
	    lp_token    = _lp_token;
	    IERC20(lp_token).totalSupply();          // just check
	}
    
    function setSpan(uint _span, bool isLinear) virtual external governance {
        span = _span;
        if(isLinear)
            end = now + _span;
        else
            end = 0;
    }
    
    function kick(address addr) virtual override external {
        _checkpoint(addr, true);
    }
    
    function set_approve_deposit(address addr, bool can_deposit) virtual override external {
        approved_to_deposit[addr][msg.sender] = can_deposit;
    }
    
    function deposit(uint amount) virtual override external {
        deposit(amount, msg.sender);
    }
    function deposit(uint amount, address addr) virtual override public {
        require(addr == msg.sender || approved_to_deposit[msg.sender][addr], 'Not approved');

        _checkpoint(addr, true);
        
        _deposit(addr, amount);
        
        balanceOf[addr] = balanceOf[addr].add(amount);
        totalSupply = totalSupply.add(amount);
        
        emit Deposit(addr, amount);
    }
    function _deposit(address addr, uint amount) virtual internal {
        lp_token.safeTransferFrom(addr, address(this), amount);
    }
    
    function withdraw() virtual  external {
        withdraw(balanceOf[msg.sender], true);
    }
    function withdraw(uint amount) virtual override external {
        withdraw(amount, true);
    }
    function withdraw(uint amount, bool claim_rewards) virtual override public {
        _checkpoint(msg.sender, claim_rewards);
        
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        
        _withdraw(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }
    function _withdraw(address to, uint amount) virtual internal {
        lp_token.safeTransfer(to, amount);
    }
    
    function claimable_reward(address) virtual override public view returns (uint) {
        return 0;
    }

    function claim_rewards() virtual override public {
        return claim_rewards(msg.sender);
    }
    function claim_rewards(address) virtual override public {
        return;
    }
    function _checkpoint_rewards(address, bool) virtual internal {
        return;
    }
    
    function claimable_tokens(address addr) virtual override public view returns (uint amount) {
        if(span == 0 || totalSupply == 0)
            return 0;
        
        amount = SMinter(minter).quotas(address(this));
        amount = amount.mul(balanceOf[addr]).div(totalSupply);
        
        uint lasttime = integrate_checkpoint_of[addr];
        if(end == 0) {                                                         // isNonLinear, endless
            if(now.sub(lasttime) < span)
                amount = amount.mul(now.sub(lasttime)).div(span);
        }else if(now < end)
            amount = amount.mul(now.sub(lasttime)).div(end.sub(lasttime));
        else if(lasttime >= end)
            amount = 0;
    }
    
    function _checkpoint(address addr, uint amount) virtual internal {
        if(amount > 0) {
            integrate_fraction[addr] = integrate_fraction[addr].add(amount);
            
            address teamAddr = address(config['teamAddr']);
            uint teamRatio = config['teamRatio'];
            if(teamAddr != address(0) && teamRatio != 0)
                integrate_fraction[teamAddr] = integrate_fraction[teamAddr].add(amount.mul(teamRatio).div(1 ether));
        }
    }

    function _checkpoint(address addr, bool _claim_rewards) virtual internal {
        uint amount = claimable_tokens(addr);
        _checkpoint(addr, amount);
        _checkpoint_rewards(addr, _claim_rewards);
    
        integrate_checkpoint_of[addr] = now;
    }
    
    function user_checkpoint(address addr) virtual override external returns (bool) {
        _checkpoint(addr, true);
        return true;
    }

    function integrate_checkpoint() override external view returns (uint) {
        return now;
    }
} 

contract SExactGauge is LiquidityGauge, Configurable {
    using SafeMath for uint;
    using TransferHelper for address;
    
    bytes32 internal constant _devAddr_         = 'devAddr';
    bytes32 internal constant _devRatio_        = 'devRatio';
    bytes32 internal constant _ecoAddr_         = 'ecoAddr';
    bytes32 internal constant _ecoRatio_        = 'ecoRatio';
    bytes32 internal constant _claim_rewards_   = 'claim_rewards';
    
    address override public minter;
    address override public crv_token;
    address override public lp_token;
    address override public controller;
    address override public voting_escrow;
    mapping(address => uint) override public balanceOf;
    uint override public totalSupply;
    uint override public future_epoch_time;
    
    // caller -> recipient -> can deposit?
    mapping(address => mapping(address => bool)) override public approved_to_deposit;
    
    mapping(address => uint) override public working_balances;
    uint override public working_supply;
    
    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    int128 override public period;
    uint256[100000000000000000000000000000] override public period_timestamp;
    
    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    uint256[100000000000000000000000000000] override public integrate_inv_supply;  // bump epoch when rate() changes
    
    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint) override public integrate_inv_supply_of;
    mapping(address => uint) override public integrate_checkpoint_of;
    
    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units: rate * t = already number of coins per address to issue
    mapping(address => uint) override public integrate_fraction;
    
    uint override public inflation_rate;
    
    // For tracking external rewards
    address override public reward_contract;
    address override public rewarded_token;
    
    mapping(address => uint) public reward_integral_;                             // rewarded_token => reward_integral
    mapping(address => mapping(address => uint)) public reward_integral_for_;     // recipient => rewarded_token => reward_integral_for
    mapping(address => mapping(address => uint)) public rewards_for_; 
    mapping(address => mapping(address => uint)) public claimed_rewards_for_; 

	uint public span;
	uint public end;
	mapping(address => uint) public sumMiningPerOf;
	uint public sumMiningPer;
	uint public bufReward;
	uint public lasttime;
	
	function initialize(address governor, address _minter, address _lp_token) public initializer {
	    super.initialize(governor);
	    
	    minter      = _minter;
	    crv_token   = Minter(_minter).token();
	    lp_token    = _lp_token;
	    IERC20(lp_token).totalSupply();                 // just check
	}
    
    function setSpan(uint _span, bool isLinear) virtual external governance {
        span = _span;
        if(isLinear)
            end = now + _span;
        else
            end = 0;
            
        if(lasttime == 0)
            lasttime = now;
    }
    
    function kick(address addr) virtual override external {
        _checkpoint(addr, true);
    }
    
    function set_approve_deposit(address addr, bool can_deposit) virtual override external {
        approved_to_deposit[addr][msg.sender] = can_deposit;
    }
    
    function deposit(uint amount) virtual override external {
        deposit(amount, msg.sender);
    }
    function deposit(uint amount, address addr) virtual override public {
        require(addr == msg.sender || approved_to_deposit[msg.sender][addr], 'Not approved');

        _checkpoint(addr, config[_claim_rewards_] == 0 ? false : true);
        
        _deposit(addr, amount);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        
        emit Deposit(msg.sender, amount);
    }
    function _deposit(address addr, uint amount) virtual internal {
        lp_token.safeTransferFrom(addr, address(this), amount);
    }
    
    function withdraw() virtual external {
        withdraw(balanceOf[msg.sender]);
    }
    function withdraw(uint amount) virtual override public {
        withdraw(amount, config[_claim_rewards_] == 0 ? false : true);
    }
    function withdraw(uint amount, bool _claim_rewards) virtual override public {
        _checkpoint(msg.sender, _claim_rewards);
        
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        
        _withdraw(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }
    function _withdraw(address to, uint amount) virtual internal {
        lp_token.safeTransfer(to, amount);
    }
    
    function claimable_reward(address addr) virtual override public view returns (uint) {
        addr;
        return 0;
    }

    function claim_rewards() virtual override public {
        return claim_rewards(msg.sender);
    }
    function claim_rewards(address) virtual override public {
        return;
    }
    function _checkpoint_rewards(address, bool) virtual internal {
        return;
    }
    
    function claimable_tokens(address addr) virtual override public view returns (uint r) {
        r = integrate_fraction[addr].sub(Minter(minter).minted(addr, address(this)));
        r = r.add(_claimable_last(addr, claimableDelta(), sumMiningPer, sumMiningPerOf[addr]));
    }
    
    function _claimable_last(address addr, uint delta, uint sumPer, uint lastSumPer) virtual internal view returns (uint amount) {
        if(span == 0 || totalSupply == 0)
            return 0;
        
        amount = sumPer.sub(lastSumPer);
        amount = amount.add(delta.mul(1 ether).div(totalSupply));
        amount = amount.mul(balanceOf[addr]).div(1 ether);
    }
    function claimableDelta() virtual internal view returns(uint amount) {
        if(span == 0 || totalSupply == 0)
            return 0;
        
        amount = SMinter(minter).quotas(address(this)).sub(bufReward);

        if(end == 0) {                                                         // isNonLinear, endless
            if(now.sub(lasttime) < span)
                amount = amount.mul(now.sub(lasttime)).div(span);
        }else if(now < end)
            amount = amount.mul(now.sub(lasttime)).div(end.sub(lasttime));
        else if(lasttime >= end)
            amount = 0;
    }

    function _checkpoint(address addr, uint amount) virtual internal {
        if(amount > 0) {
            integrate_fraction[addr] = integrate_fraction[addr].add(amount);
            
            addr = address(config[_devAddr_]);
            uint ratio = config[_devRatio_];
            if(addr != address(0) && ratio != 0)
                integrate_fraction[addr] = integrate_fraction[addr].add(amount.mul(ratio).div(1 ether));

            addr = address(config[_ecoAddr_]);
            ratio = config[_ecoRatio_];
            if(addr != address(0) && ratio != 0)
                integrate_fraction[addr] = integrate_fraction[addr].add(amount.mul(ratio).div(1 ether));
        }
    }
    
    function _checkpoint(address addr, bool _claim_rewards) virtual internal {
        if(span == 0 || totalSupply == 0)
            return;
        
        uint delta = claimableDelta();
        uint amount = _claimable_last(addr, delta, sumMiningPer, sumMiningPerOf[addr]);
        
        if(delta != amount)
            bufReward = bufReward.add(delta).sub(amount);
        if(delta > 0)
            sumMiningPer = sumMiningPer.add(delta.mul(1 ether).div(totalSupply));
        if(sumMiningPerOf[addr] != sumMiningPer)
            sumMiningPerOf[addr] = sumMiningPer;
        lasttime = now;

        _checkpoint(addr, amount);
        _checkpoint_rewards(addr, _claim_rewards);
    }

    function user_checkpoint(address addr) virtual override external returns (bool) {
        _checkpoint(addr, config[_claim_rewards_] == 0 ? false : true);
        return true;
    }

    function integrate_checkpoint() override external view returns (uint) {
        return lasttime;
    }
    
    function reward_integral() virtual override external view returns (uint) {
        return reward_integral_[rewarded_token];
    }
    
    function reward_integral_for(address addr) virtual override external view returns (uint) {
        return reward_integral_for_[addr][rewarded_token];
    }
    
    function rewards_for(address addr) virtual override external view returns (uint) {
        return rewards_for_[addr][rewarded_token];
    }
    
    function claimed_rewards_for(address addr) virtual override external view returns (uint) {
        return claimed_rewards_for_[addr][rewarded_token];
    }
} 


contract SNestGauge is SExactGauge {
	address[] public rewards;
	//mapping(address => mapping(address =>uint)) internal sumRewardPerOf_;      // recipient => rewarded_token => can sumRewardPerOf            // obsolete, instead of reward_integral_
	//mapping(address => uint) internal sumRewardPer_;                           // rewarded_token => can sumRewardPerOf                         // obsolete, instead of reward_integral_for_

	function initialize(address governor, address _minter, address _lp_token, address _nestGauge, address[] memory _moreRewards) public initializer {
	    super.initialize(governor, _minter, _lp_token);
	    
	    reward_contract = _nestGauge;
	    rewarded_token  = LiquidityGauge(_nestGauge).crv_token();
	    rewards         = _moreRewards;
	    rewards.push(rewarded_token);
	    address rewarded_token2 = LiquidityGauge(_nestGauge).rewarded_token();
	    if(rewarded_token2 != address(0))
    	    rewards.push(rewarded_token2);
	    
	    LiquidityGauge(_nestGauge).integrate_checkpoint();      // just check
	    for(uint i=0; i<_moreRewards.length; i++)
	        IERC20(_moreRewards[i]).totalSupply();              // just check
	}
    
    function _deposit(address from, uint amount) virtual override internal {
        super._deposit(from, amount);                           // lp_token.safeTransferFrom(from, address(this), amount);
        lp_token.safeApprove(reward_contract, amount);
        LiquidityGauge(reward_contract).deposit(amount);
    }

    function _withdraw(address to, uint amount) virtual override internal {
        LiquidityGauge(reward_contract).withdraw(amount);
        super._withdraw(to, amount);                            // lp_token.safeTransfer(to, amount);
    }
    
    function claim_rewards(address to) virtual override public {
        if(span == 0 || totalSupply == 0)
            return;
        
        _checkpoint_rewards(to, true);
        
        for(uint i=0; i<rewards.length; i++) {
            uint amount = rewards_for_[to][rewards[i]].sub(claimed_rewards_for_[to][rewards[i]]);
            if(amount > 0) {
                rewards[i].safeTransfer(to, amount);
                claimed_rewards_for_[to][rewards[i]] = rewards_for_[to][rewards[i]];
            }
        }
    }

    function _checkpoint_rewards(address addr, bool _claim_rewards) virtual override internal {
        if(span == 0 || totalSupply == 0)
            return;
        
        uint[] memory drs = new uint[](rewards.length);
        
        if(_claim_rewards) {
            for(uint i=0; i<drs.length; i++)
                drs[i] = IERC20(rewards[i]).balanceOf(address(this));
                
            Minter(LiquidityGauge(reward_contract).minter()).mint(reward_contract);
            LiquidityGauge(reward_contract).claim_rewards();
            
            for(uint i=0; i<drs.length; i++)
                drs[i] = IERC20(rewards[i]).balanceOf(address(this)).sub(drs[i]);
        }

        for(uint i=0; i<drs.length; i++) {
            uint amount = _claimable_last(addr, drs[i], reward_integral_[rewards[i]], reward_integral_for_[addr][rewards[i]]);
            if(amount > 0)
                rewards_for_[addr][rewards[i]] = rewards_for_[addr][rewards[i]].add(amount);
            
            if(drs[i] > 0)
                reward_integral_[rewards[i]] = reward_integral_[rewards[i]].add(drs[i].mul(1 ether).div(totalSupply));
            if(reward_integral_for_[addr][rewards[i]] != reward_integral_[rewards[i]])
                reward_integral_for_[addr][rewards[i]] = reward_integral_[rewards[i]];
        }
    }

    function claimable_reward(address addr) virtual override public view returns (uint r) {
        //uint delta = LiquidityGauge(reward_contract).claimable_tokens(address(this));     // Error: Mutable call in static context
        uint delta = LiquidityGauge(reward_contract).integrate_fraction(address(this)).sub(Minter(LiquidityGauge(reward_contract).minter()).minted(address(this), reward_contract));
        r = _claimable_last(addr, delta, reward_integral_[rewarded_token], reward_integral_for_[addr][rewarded_token]);
        r = r.add(rewards_for_[addr][rewarded_token].sub(claimed_rewards_for_[addr][rewarded_token]));
    }
    
    function claimable_reward2(address addr) virtual public view returns (uint r) {
        uint delta = LiquidityGauge(reward_contract).claimable_reward(address(this)).sub(LiquidityGauge(reward_contract).claimed_rewards_for(address(this)));
        address reward2 = LiquidityGauge(reward_contract).rewarded_token();
        r = _claimable_last(addr, delta, reward_integral_[reward2], reward_integral_for_[addr][reward2]);
        r = r.add(rewards_for_[addr][reward2].sub(claimed_rewards_for_[addr][reward2]));
    }    

    function claimable_reward(address addr, address reward) virtual public view returns (uint r) {
        r = _claimable_last(addr, 0, reward_integral_[reward], reward_integral_for_[addr][reward]);
        r = r.add(rewards_for_[addr][reward].sub(claimed_rewards_for_[addr][reward]));
    }
    
    function claimed_rewards_for2(address addr) virtual public view returns (uint) {
        return claimed_rewards_for_[addr][LiquidityGauge(reward_contract).rewarded_token()];
    }
    
    function rewards_for2(address addr) virtual public view returns (uint) {
        return rewards_for_[addr][LiquidityGauge(reward_contract).rewarded_token()];
    }
    
}


contract SMinter is Minter, Configurable {
    using SafeMath for uint;
    using Address for address payable;
    using TransferHelper for address;
    
	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';

    address override public token;
    address override public controller;
    mapping(address => mapping(address => uint)) override public minted;                    // user => reward_contract => value
    mapping(address => mapping(address => bool)) override public allowed_to_mint_for;       // minter => user => can mint?
    mapping(address => uint) public quotas;                                                 // reward_contract => quota;

    function initialize(address governor, address token_) public initializer {
        super.initialize(governor);
        token = token_;
    }
    
    function setGaugeQuota(address gauge, uint quota) public governance {
       quotas[gauge] = quota;
    }
    
    function mint(address gauge) virtual override public {
        mint_for(gauge, msg.sender);   
    }
    
    function mint_many(address[8] calldata gauges) virtual override external {
        for(uint i=0; i<gauges.length; i++)
            mint(gauges[i]);
    }
    
    function mint_many(address[] calldata gauges) virtual external {
        for(uint i=0; i<gauges.length; i++)
            mint(gauges[i]);
    }
    
    function mint_for(address gauge, address _for) virtual override public {
        require(_for == msg.sender || allowed_to_mint_for[msg.sender][_for], 'Not approved');
        require(quotas[gauge] > 0, 'No quota');
        
        require(getConfig(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfig(_allowlist_, msg.sender) != 0, 'No allowContract');

        LiquidityGauge(gauge).user_checkpoint(_for);
        uint total_mint = LiquidityGauge(gauge).integrate_fraction(_for);
        uint to_mint = total_mint.sub(minted[_for][gauge]);
    
        if(to_mint != 0) {
            quotas[gauge] = quotas[gauge].sub(to_mint);
            token.safeTransfer(_for, to_mint);
            minted[_for][gauge] = total_mint;
    
            emit Minted(_for, gauge, total_mint);
        }
    }
    
    function toggle_approve_mint(address minting_user) virtual override external {
        allowed_to_mint_for[minting_user][msg.sender] = !allowed_to_mint_for[minting_user][msg.sender];
    }
}

/*
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
*/
