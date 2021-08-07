// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";

/**
 * @dev Basically another fork of sushi/goose/pancake pool but without a Masterchef owning and managing the pool, rewards to the pool will be sent by owner
 * @notice this pool has been done mainly to stake MULTI tokens(no redistribution fee, no minting)
 */
contract StakingPool is Ownable{
    
    using SafeERC20 for IERC20;
    uint256 private allocation_divisor = 1e12;

    /** structs to handle info */
    struct User {
        uint256 amount_staked;
        uint256 rewards_pending;
    }

    /**
     * A pool struct including all state variables
     */
    struct Pool{
        IERC20 token_to_stake; // The Token to stake. In PolyDefi case it will be MULTI token
        IERC20 token_to_earn; // The token that will be earned as reward.
        uint256 start_block; // The block where rewards will start
        uint256 last_block; // The block when reward distribution will be over
        uint256 last_block_reward_was_given; // A variable to check on what block the reward was calculated last time.
        uint256 allocation_points; // Allocation pools for the pool. We only have one pool so no total allocation points
        uint256 reward_per_block; // The amount of tokens per block that are given as reward
        uint256 accRewardTokenPerShare; // The share of every user in stake
        uint256 total_staked; // the amount of staked tokens, using this instead of balanceOf to prevent manipulation of rewards by sending tokens to the contract without deposit
    }
    /** variables */
    // Private pool info, getters and setters will be coded below
    Pool private _pool;
    // a mapping to track staking
    mapping(address => User) public users_in_stake;


    /** events */
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event RewardsDeposited(uint256 amount);

    constructor(
        IERC20 _token_to_stake,
        IERC20 _token_to_earn,
        uint256 _start_block,
        uint256 _last_block,
        uint256 _last_block_reward_was_given,
        uint256 _allocation_points,
        uint256 _reward_per_block
        ) {
            _pool = Pool({
                token_to_stake: _token_to_stake,
                token_to_earn: _token_to_earn,
                start_block: _start_block,
                last_block: _last_block,
                last_block_reward_was_given: _last_block_reward_was_given, // set the last block=start block so when updating the pool the first time it starts running
                allocation_points: _allocation_points,
                reward_per_block: _reward_per_block,
                accRewardTokenPerShare : 0,
                total_staked : 0
                });
        }

    function get_multiplier(uint256 _from, uint256 _to) public view returns(uint256){
        uint256 lrb = _pool.last_block;
        if(_to <= lrb) return (_to - _from);
        else if (_from >= lrb) return 0;
        else return (lrb - _from);
    }


    function updatePool() public{
        if (block.number <= _pool.last_block_reward_was_given) return;
        // get the current staked value
        //uint256 _staked = _pool.token_to_stake.balanceOf(address(this));
        // if theres nothing staked, then set the last block that updated as the current block
        if ( _pool.total_staked == 0) {
            _pool.last_block_reward_was_given = block.number;
            return;
        }
        // fancy math
        uint256 multiplier = get_multiplier(_pool.last_block_reward_was_given, block.number);
        uint256 rewards = multiplier * _pool.reward_per_block;// _pool.allocation_points / _pool.allocation_points;
        _pool.accRewardTokenPerShare =  _pool.accRewardTokenPerShare + rewards * allocation_divisor / _pool.total_staked;
        _pool.last_block_reward_was_given = block.number; // para indicar la ultima vez q se actualizo
        return;
    }


    /**
        @dev stake the tokens into the pool, functionality has been forked from pancakeswap and goosedefi
        @param _amount quantity of tokens to stake
        @notice rewards will be harvested on stake
     */
    function stake(uint256 _amount) public {
        // look for the user in the mapping
        User storage user = users_in_stake[msg.sender];
        // update pool info before do any action
        updatePool();
        //If user already staked
        if (user.amount_staked > 0){
            // Check if user has pending rewards
            uint256 pending = user.amount_staked * _pool.accRewardTokenPerShare / allocation_divisor - user.rewards_pending;
            if(pending > 0){
                // In case user has pending rewards, safetransfer the rewards from contract to user and emit an event to check on the block explorer
                _pool.token_to_earn.safeTransfer(msg.sender, pending);
                emit Harvest(msg.sender, _amount);
            }
        }
        // stake the tokens
        if(_amount > 0 ){
            _pool.token_to_stake.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount_staked = user.amount_staked + _amount;
            _pool.total_staked = _pool.total_staked + _amount;
        }
        // start calculating the rewards again 
        user.rewards_pending = user.amount_staked * _pool.accRewardTokenPerShare / allocation_divisor;
        emit Stake(_msgSender(), _amount);
    }
    /**
        @dev unstake the tokens from the pool , functionality has been forked from pancakeswap and goosedefi
        @param _amount quantity of tokens to unstake
        @notice rewards will be harvested on unstake
     */
    function unstake(uint256 _amount) public {
        // look for the user in the mapping
        User storage user  = users_in_stake[_msgSender()];
        // Require that user can't unstake more than it has staked in
        require(user.amount_staked >= _amount);
        // update pool info before do any action
        updatePool();
        // Check if user has pending rewards
        uint256 pending = user.amount_staked * _pool.accRewardTokenPerShare / allocation_divisor - user.rewards_pending;
        if (pending > 0){ 
            // In case user has pending rewards, safetransfer the rewards from contract to user and emit an event to check on the block explorer
            _pool.token_to_earn.safeTransfer(msg.sender, _amount);
            emit Harvest(msg.sender, _amount);
        }
        // Unstake the tokens
        if(_amount > 0 ){
            user.amount_staked = user.amount_staked - _amount;
            _pool.token_to_stake.safeTransfer(_msgSender(), _amount);
            _pool.total_staked = _pool.total_staked - _amount;
            emit Unstake(_msgSender(), _amount);  
        }
        // start calculating rewards again
        user.rewards_pending = user.amount_staked * _pool.accRewardTokenPerShare / allocation_divisor;
    }


    /** function to calculate rewards on frontend */
    function pending_rewards(address _user) external view returns(uint256){
        User storage user = users_in_stake[_user];
        uint256 accRewardTokenPerShare = _pool.accRewardTokenPerShare;
        if (block.number > _pool.last_block_reward_was_given){
            uint256 multiplier = get_multiplier(_pool.last_block_reward_was_given,block.number);
            uint256 tokenReward = multiplier * _pool.reward_per_block / _pool.allocation_points;
            accRewardTokenPerShare = accRewardTokenPerShare + tokenReward * allocation_divisor / _pool.total_staked;
        }
        return user.amount_staked * accRewardTokenPerShare / allocation_divisor - user.rewards_pending;
    }



    /** getters */
    function token_to_stake() public view returns(address){return address(_pool.token_to_stake);}
    function token_to_earn() public view returns(address){return address(_pool.token_to_earn);}
    function start_block() public view returns(uint256){return _pool.start_block;}
    function last_block() public view returns(uint256){return _pool.last_block;}
    function last_block_reward_was_given() public view returns(uint256){return _pool.last_block_reward_was_given;}
    function allocation_points() public view returns(uint256){return _pool.allocation_points;}
    function total_stake() public view  returns(uint256){ return _pool.total_staked; }


    /** admin functions */
    function deposit_reward_token_into_contract(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        _pool.token_to_earn.safeTransferFrom(_msgSender(), address(this), _amount);
        emit RewardsDeposited(_amount);
    }
    function set_start_block(uint256 _start_block) public onlyOwner{_pool.start_block = _start_block;  }
    function set_reward_per_block(uint256 _reward_per_block) public onlyOwner{ _pool.reward_per_block = _reward_per_block; }
    function set_last_block(uint256 _last_block) public onlyOwner{_pool.last_block = _last_block;}
    function set_last_block_reward_was_given(uint256 _last_block_reward_was_given) public onlyOwner{_pool.last_block_reward_was_given = _last_block_reward_was_given;}
    function set_allocation_points(uint256 _allocation_points) public onlyOwner{_pool.allocation_points = _allocation_points;}
    function set_allocation_divisor(uint256 _allocation_divisor) public onlyOwner{allocation_divisor = _allocation_divisor;}

    /** emergency functions */
    
    function emergencyWithdraw() external {
        User storage user = users_in_stake[msg.sender];
        _pool.token_to_stake.safeTransfer(_msgSender(), user.amount_staked);
        _pool.total_staked = _pool.total_staked - user.amount_staked;
        user.amount_staked = 0;
        user.rewards_pending = 0;
        emit EmergencyWithdraw(msg.sender, user.amount_staked);
    }

    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= _pool.token_to_earn.balanceOf(address(this)), 'not enough rewards');
        // Withdraw rewards
        _pool.token_to_earn.safeTransfer(_msgSender(), _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }


}