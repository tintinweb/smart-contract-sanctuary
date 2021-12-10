pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Lockable.sol";

/**
 * @title StakePool
 * @notice Implements a StandardToken, Ownable, Burnable, Mintable.
 */
contract StakePool is Ownable, Pausable, Lockable, ReentrancyGuard  {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // We usually require to know who are all the stakeholders.
    address[] internal stakeholders;

    string[] internal poollist;

    uint256 internal currentTimestamp = block.timestamp;

    struct Stake {
        uint256 amount;
        uint256 duration; // The duration in weeks of how long the stake should be locked from unstaking
        address referral;
        string  pool; 
        uint256 reward;
        uint256 reward_paid;
        uint256 reward_count;
        uint256 reward_claimable_after_duration;
        uint256 bonus;
        uint256 bonus_paid;
        uint256 bonus_claimable_after_duration;
        uint256 bonus_updated_at;
        uint256 reward_updated_at;
        uint256 bonus_last_withdraw_at;
        uint256 reward_last_withdraw_at;
        uint256 last_withdraw_at;
        uint256 created_at; // Timestamp of when stake was created
        uint256 updated_at; // Timestamp of when stake was last modified
        bool    valid;
    }

    struct Pool {
        string  name; //The name of the pool, should be a single word in lowercase
        address staking_token;
        address reward_token;
        address bonus_token;
        uint256 duration_in_weeks; // The duration in weeks of the pool
        uint256 reward_percentage; //The total reward percentage of the pool
        uint256 minimum_stake; //The minimum amount a stakeholder can stake
        uint256 reward_halving; //Will halve reward every 2 year untill the 6th year if activated
        uint256 referral_bonus_percentage;
        uint256 reward_claimable_after_duration;
        uint256 bonus_claimable_after_duration;
        uint256 created_at; // Timestamp of when pool was created
        uint256 updated_at; // Timestamp of when pool was last modified
        bool    valid;
    }

    //The stakes for each stakeholder.
    mapping(address => Stake) internal stakes;

    //The pools for each poollist.
    mapping(string => Pool) internal pools;
    

    mapping(address => uint256) private _balances;


    uint256 private _totalSupply;


    uint256 public balance;


    constructor() {
    }

    receive() payable external {
        balance += msg.value;
        emit TransferReceived(_msgSender(), msg.value);
    }    


    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }


    /* ==========   STAKES METHODS ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param amount The size of the stake to be created.
     * @param _pool The pool to stake in.
     * @param _affiliate An affiliate address to benefit from the stake.
     */

    function createStake(uint256 amount, string memory _pool, address _affiliate) external nonReentrant whenNotPaused whenNotLocked {

        require(amount > 0, "Insufficient stake amount");

        Stake storage stake = stakes[_msgSender()];
       
        if (!stake.valid) {

            _isValidPool(_pool);

            Pool memory pool = pools[_pool];

            require(pool.valid, "Invalid pool");
            
            require(amount >= pool.minimum_stake, "Stake is below minimum allowed stake");

            _totalSupply = _totalSupply.add(amount);
            _balances[_msgSender()] = _balances[_msgSender()].add(amount);

            IBEP20(pool.staking_token).safeTransferFrom(_msgSender(), address(this), amount);

            addStakeholder(_msgSender());

            stake.amount = stake.amount.add(amount);
            stake.pool = _pool;
            stake.duration = pool.duration_in_weeks;
            stake.reward_claimable_after_duration = pool.reward_claimable_after_duration;
            stake.bonus_claimable_after_duration = pool.bonus_claimable_after_duration;
            stake.created_at = currentTimestamp;
            stake.updated_at = currentTimestamp;
            stake.valid = true;

            stake.reward = stake.reward.add(0);
            stake.reward_count = 0;
            stake.bonus = stake.bonus.add(0);

             //check if the referral is a stakeholder and also if _msgSender is not the referral
            (bool _isReferralStakeholder,) = isStakeholder(_affiliate);
            if (_isReferralStakeholder && _msgSender() != _affiliate){

              uint256 referral_bonus = stake.amount / (100 * (10 ** 18));
        
              uint256 affiliate_bonus = referral_bonus.mul(pool.referral_bonus_percentage);

              stake.bonus = stake.bonus.add(affiliate_bonus);

              stake.referral = _affiliate;

            } 

            emit Staked(_msgSender(), amount, pool.name);
            
        }else{

            Pool memory pool = pools[stake.pool];

            require(pool.valid, "Invalid pool");

            _totalSupply = _totalSupply.add(amount);
            _balances[_msgSender()] = _balances[_msgSender()].add(amount);

            IBEP20(pool.staking_token).safeTransferFrom(_msgSender(), address(this), amount);

            stake.amount = stake.amount.add(amount);
            stake.updated_at = currentTimestamp;

            emit Staked(_msgSender(), amount, pool.name);
          
        }

        
    }





    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param amount The size of the stake to be removed.
     */
    function withdraw(uint256 amount) public nonReentrant whenNotPaused whenNotLocked {

        require(amount > 0, "Cannot withdraw 0");

        Stake storage stake = stakes[_msgSender()];

        require(stake.valid, "No stake found.");

        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");

        require(_isExpired(stake.created_at, stake.duration), "You can't withdraw untill the stake duration is over.");
       
        require(stake.amount >= amount, "Insufficient amount of stakes");

        stake.amount = stake.amount.sub(amount); 
        if (stake.amount == 0) removeStakeholder(_msgSender());

        _totalSupply = _totalSupply.sub(amount);
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);

        IBEP20(pool.staking_token).safeTransfer(_msgSender(), amount);

        emit Withdrawn(_msgSender(), amount, stake.pool);
    }

 
    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder) public view returns (uint256, string memory) {
        require(_stakeholder != address(0), "Invalid stakeholder");
        
        Stake memory stake = stakes[_stakeholder];
        
        require(stake.valid, "No stake found.");
        
        return (stake.amount,stake.pool);
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            Stake memory stake = stakes[stakeholders[s]];
            _totalStakes = _totalStakes.add(stake.amount);
        }
        return _totalStakes;
    }

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder,
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address) public view returns (bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

   

    function exit() external {
        withdraw(_balances[_msgSender()]);
        getReward();
        getBonus();
    }
    



    /* ==========  REWARD METHODS  ========== */

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns (uint256) {
        Stake memory stake = stakes[_stakeholder];
        return stake.reward;
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns (uint256) {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            address stakeholder = stakeholders[s];
            Stake memory stake = stakes[stakeholder];
            _totalRewards = _totalRewards.add(stake.reward);
        }
        return _totalRewards;
    }
    
    
    function calculateTotalHalvedReward(address _stakeholder) public view returns (uint256) {
            
        require(_stakeholder != address(0), "Invalid stakeholder");

        Stake memory stake = stakes[_stakeholder];

        require(stake.valid, "Stake not found");

        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");
        
        uint256 reward = stake.amount / (100 * (10 ** 18));
        
        uint256 total_reward = reward.mul(pool.reward_percentage);

        uint256 total_halved_reward = total_reward;
        
        if(pool.reward_halving > 0){
         
            if (block.timestamp >= pool.created_at + 104 weeks) {
            
                total_halved_reward = total_reward/2;
                
                if(block.timestamp >= pool.created_at + 208 weeks){
                    
                    total_halved_reward = total_reward/4;
                    
                    if(block.timestamp >= pool.created_at + 312 weeks){
                    
                        total_halved_reward = total_reward;
                    }
                }
            }
        }
        return total_halved_reward;
    }



    /**
     * @notice A simple method that calculates the total rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateTotalReward(address _stakeholder) public view returns (uint256) {
        require(_stakeholder != address(0), "Invalid stakeholder");

        Stake memory stake = stakes[_stakeholder];

        require(stake.valid, "Stake not found");

        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");
        
        return calculateTotalHalvedReward(_stakeholder);
    }



    /**
     * @notice A simple method that calculates the weekly rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateWeeklyReward(address _stakeholder) public view returns (uint256) {
        require(_stakeholder != address(0), "Invalid stakeholder");
        
        Stake memory stake = stakes[_stakeholder];

        require(stake.valid, "Stake not found");
        
        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");
        
        uint256 total_reward = calculateTotalReward(_stakeholder);

        uint256 weekly_reward = total_reward / pool.duration_in_weeks;
        
        return weekly_reward;
    }
    
    
     /**
     * @notice A simple method that calculates the daily rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateDailyReward(address _stakeholder) public view returns (uint256) {
        require(_stakeholder != address(0), "Invalid stakeholder");
        
        Stake memory stake = stakes[_stakeholder];

        require(stake.valid, "Stake not found");
        
        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");
        
        uint256 weekly_reward = calculateWeeklyReward(_stakeholder);

        uint256 daily_reward = weekly_reward / 7;
        
        return daily_reward;
    }
    



     /**
     * @notice A method to distribute total rewards to all stakeholders.
     */
    function distributeTotalRewards() public payable onlyOwner {

        uint256 _totalRewards = 0;

        for (uint256 s = 0; s < stakeholders.length; s += 1) {

            address stakeholder = stakeholders[s];

            Stake storage stake = stakes[stakeholder];

            if(stake.valid){
                
                uint256 _reward = calculateTotalReward(stakeholder);
                
                uint256 _next_reward_in_days = 7;
                
                uint256 _max_reward_count = stake.duration.mul(_next_reward_in_days);
                
                if (_reward > stake.reward) {
                    if (stake.reward_count < _max_reward_count) {
 
                        stake.reward = _reward;

                        stake.reward_count = stake.reward_count.add(_max_reward_count);

                        stake.reward_updated_at = currentTimestamp;

                        _totalRewards = _totalRewards.add(_reward);

                    }
                }
            }
        }

        emit TotalRewardDistributed(_totalRewards);
    }

    

    /**
     * @notice A method to distribute weekly rewards to all stakeholders.
     */
    function distributeWeeklyRewards() public payable onlyOwner {

        uint256 _totalRewards = 0;

        for (uint256 s = 0; s < stakeholders.length; s += 1) {

            address stakeholder = stakeholders[s];

            Stake storage stake = stakes[stakeholder];

            if(stake.valid){
                
                uint256 _total_reward = calculateTotalReward(stakeholder);
                
                uint256 _reward = calculateWeeklyReward(stakeholder);

                uint256 _next_reward_in_days = 7; 
                
                uint256 _check_reward_count_exceeded = stake.reward_count + _next_reward_in_days; 
                
                uint256 _max_reward_count = stake.duration.mul(_next_reward_in_days);
                
                //check if staking period for stakeholder has not expired
                if (!_isExpired(stake.created_at, stake.duration)) {
                    if (stake.reward_count < _max_reward_count && _check_reward_count_exceeded <= _max_reward_count && _isExpiredInDays(stake.reward_updated_at, _next_reward_in_days)  && _total_reward > stake.reward) {

                        stake.reward = stake.reward.add(_reward);
                        stake.reward_count = stake.reward_count.add(_next_reward_in_days);
                        stake.reward_updated_at = currentTimestamp;
                        _totalRewards = _totalRewards.add(_reward);

                    }
                }
            }
        }

        emit WeeklyRewardDistributed(_totalRewards);
    }
    
    
    /**
     * @notice A method to distribute daily rewards to all stakeholders.
     */
    function distributeDailyRewards() public payable onlyOwner {

        uint256 _totalRewards = 0;

        for (uint256 s = 0; s < stakeholders.length; s += 1) {

            address stakeholder = stakeholders[s];

            Stake storage stake = stakes[stakeholder];

            if(stake.valid){
                
                uint256 _total_reward = calculateTotalReward(stakeholder);
                
                uint256 _reward = calculateDailyReward(stakeholder);

                uint256 _next_reward_in_days = 1;
                
                uint256 _check_reward_count_exceeded = stake.reward_count + _next_reward_in_days;
                
                uint256 _max_reward_count = stake.duration.mul(_next_reward_in_days);
                
                //check if staking period for stakeholder has not expired
                if (!_isExpired(stake.created_at, stake.duration)) {
                    if (stake.reward_count < _max_reward_count && _check_reward_count_exceeded <= _max_reward_count && _isExpiredInDays(stake.reward_updated_at, _next_reward_in_days)  && _total_reward > stake.reward) {

                        stake.reward = stake.reward.add(_reward);
                        stake.reward_count = stake.reward_count.add(_next_reward_in_days);
                        stake.reward_updated_at = currentTimestamp;
                        _totalRewards = _totalRewards.add(_reward);

                    }
                }
            }
        }

        emit DailyRewardDistributed(_totalRewards);
    }


    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function getReward() public nonReentrant whenNotPaused whenNotLocked {

        Stake storage stake = stakes[_msgSender()];

        require(stake.valid, "No stake found.");

        require(_isExpired(stake.created_at, stake.reward_claimable_after_duration), "Can't withdraw reward until the holding duration is over.");

        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");

        uint256 _reward = stake.reward;

        if (_reward > 0) {

            IBEP20(pool.reward_token).safeTransfer(_msgSender(), _reward);
            stake.reward = 0; //reset amount
            stake.reward_count = 0; //reset count
            stake.reward_last_withdraw_at = currentTimestamp;
            stake.reward_paid = stake.reward_paid.add(_reward);

            emit RewardPaid(_msgSender(), _reward);

        }
    }



     /* ==========  REFERRAL BONUS METHODS  ========== */


    /**
     * @notice A method to allow a stakeholder to check his bonus.
     * @param _stakeholder The stakeholder to check bonus for.
     */
    function bonusOf(address _stakeholder) public view returns (uint256) {
        Stake memory stake = stakes[_stakeholder];
        return stake.bonus;
    }

    /**
     * @notice A method to the aggregated bonuses from all stakeholders.
     * @return uint256 The aggregated bonuses from all stakeholders.
     */
    function totalBonuses() public view returns (uint256) {
        uint256 _totalBonuses = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            address stakeholder = stakeholders[s];
            Stake memory stake = stakes[stakeholder];
            _totalBonuses = _totalBonuses.add(stake.bonus);
        }
        return _totalBonuses;
    }

      /**
     * @notice A method to allow a stakeholder to withdraw his bonus.
     */
    function getBonus() public nonReentrant whenNotPaused whenNotLocked {

        Stake storage stake = stakes[_msgSender()];

        require(stake.valid, "No stake found.");

        require(_isExpired(stake.created_at, stake.bonus_claimable_after_duration), "Can't withdraw reward until the holding duration is over.");

        Pool memory pool = pools[stake.pool];

        require(pool.valid, "Invalid pool");

        uint256 _bonus = stake.bonus;

        if (_bonus > 0) {

            IBEP20(pool.bonus_token).safeTransfer(_msgSender(), _bonus);
            stake.bonus = 0; //reset amount
            stake.bonus_last_withdraw_at = currentTimestamp;
            stake.bonus_paid = stake.bonus_paid.add(_bonus);

            emit BonusPaid(_msgSender(), _bonus);

        }

    }



    /* ========== POOL METHODS ========== */


    /**
     * @notice A method for a contract owner to create a staking pool.
     * @param _name The name of the pool to be created.
     * @param _minimum_stake The minimum a stakeholder can stake.
     * @param _duration The duration in weeks of the pool to be created.
     * @param _reward_percentage The total reward percentage of the pool to be created
     * @param _reward_halving Whether to activate reward halving or not. 1 to activate | 0 to deactivate
     * @param _referral_bonus_percentage The referral bonus percentage of the pool to be created
     * @param _reward_claimable_after When the reward will be claimable after specified weeks 
     * @param _bonus_claimable_after When the bonus will be claimable after specified weeks
     * @param _staking_token The staking token contract address
     * @param _reward_token The reward token contract address
     * @param _bonus_token The bonus token contract address
     */
    function createPool(string memory _name, uint256 _minimum_stake, uint256 _duration,  uint256 _reward_percentage, uint256 _reward_halving, uint256 _referral_bonus_percentage, uint256 _reward_claimable_after, uint256 _bonus_claimable_after, address _staking_token, address _reward_token, address _bonus_token) public onlyOwner {

        require(_duration > 0, "Duration in weeks can't be zero");
        
        require(_minimum_stake > 0, "Minimum stake can't be zero");

        require(_reward_percentage > 0, "Total reward percentage can't be zero");
     
        Pool storage pool = pools[_name];
        if (!pool.valid) {
            _addPool(_name);
            pool.name = _name;
            pool.minimum_stake = _minimum_stake;
            pool.duration_in_weeks = _duration;
            pool.reward_percentage = _reward_percentage;
            pool.reward_halving = (_reward_halving > 0)? 1 : 0;
            pool.referral_bonus_percentage = _referral_bonus_percentage;
            pool.reward_claimable_after_duration = _reward_claimable_after;
            pool.bonus_claimable_after_duration = _bonus_claimable_after;
            pool.staking_token = _staking_token;
            pool.reward_token = _reward_token;
            pool.bonus_token = _bonus_token;
            pool.created_at = currentTimestamp;
            pool.valid = true;
        }

         emit PoolAdded(pool.name, _duration);
    }


     /**
      * @notice A method for a contract owner to update a staking pool.
      * @param _name The name of the pool to be updated.
      * @param _minimum_stake The minimum a stakeholder can stake.
      * @param _duration The duration in weeks of the pool to be created.
      * @param _reward_percentage The reward percentage of the pool to be created
      * @param _reward_halving Whether to activate reward halving or not. 1 to activate | 0 to deactivate
      * @param _referral_bonus_percentage The referral bonus percentage of the pool to be created
      * @param _reward_claimable_after When the reward will be claimable after specified weeks 
      * @param _bonus_claimable_after When the bonus will be claimable after specified weeks
      * @param _staking_token The staking token contract address
      * @param _reward_token The reward token contract address
      * @param _bonus_token The bonus token contract address
     */
    function updatePool(string memory _name, uint256 _minimum_stake, uint256 _duration,  uint256 _reward_percentage, uint256 _reward_halving, uint256 _referral_bonus_percentage, uint256 _reward_claimable_after, uint256 _bonus_claimable_after, address _staking_token, address _reward_token, address _bonus_token) public onlyOwner {
        
        require(_duration > 0, "Duration in weeks can't be zero");
        
        require(_minimum_stake > 0, "Minimum stake can't be zero");

        require(_reward_percentage > 0, "Total reward percentage can't be zero"); 

        Pool storage pool = pools[_name];
        
        require(pool.valid, "No pool found.");
   
        pool.name = _name;
        pool.minimum_stake = _minimum_stake;
        pool.duration_in_weeks = _duration;
        pool.reward_percentage = _reward_percentage;
        pool.reward_halving = (_reward_halving > 0)? 1 : 0;
        pool.referral_bonus_percentage = _referral_bonus_percentage;
        pool.reward_claimable_after_duration = _reward_claimable_after;
        pool.bonus_claimable_after_duration = _bonus_claimable_after;
        pool.staking_token = _staking_token;
        pool.reward_token = _reward_token;
        pool.bonus_token = _bonus_token;
        pool.updated_at = currentTimestamp;

        emit PoolUpdated(pool.name, _duration);
        
    }

    /**
     * @notice A method for a contract owner to remove a staking pool.
     * @param _name The name of the pool to be removed.
     */
    function removePool(string memory _name) public onlyOwner {

        Pool storage pool = pools[_name];
        
        require(pool.valid, "No pool found.");
      
        (bool _isPool, uint256 s) = isPool(_name);
        if (_isPool) {
            
            //revert stakeholders stakes before removing the pool
            for (uint256 i = 0; i < stakeholders.length; i += 1) {
                address _stakeholder = stakeholders[i];
                
                Stake storage stake = stakes[_stakeholder];
                
                uint256 _stake = stake.amount;
                
                stake.amount = stake.amount.sub(_stake);
                
                if (stake.amount == 0) removeStakeholder(_stakeholder);
                
                _totalSupply = _totalSupply.sub(_stake);
                _balances[_stakeholder] = _balances[_stakeholder].sub(_stake);

                IBEP20(pool.staking_token).safeTransfer(_stakeholder, _stake);

            }

            
            delete pools[_name];
            poollist[s] = poollist[poollist.length - 1];
            poollist.pop();
           
            emit PoolDeleted(pool.name);
        }

    }

    /**
     * @notice A method to retrieve the pool with the name.
     * @param _name The pool to retrieve
     */
    function poolOf(string memory _name) public view returns (string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, address, address){
        Pool memory pool = pools[_name];
        
        require(pool.valid, "No pool found.");
        
        return (pool.name, pool.minimum_stake, pool.duration_in_weeks, pool.reward_percentage, pool.reward_halving,pool.referral_bonus_percentage, pool.reward_claimable_after_duration, pool.bonus_claimable_after_duration, pool.staking_token,pool.reward_token,pool.bonus_token);
    }




    function poolStakes(string memory _pool) public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            Stake memory stake = stakes[stakeholders[s]];
            if(_compareStrings(stake.pool,_pool)){
              _totalStakes = _totalStakes.add(stake.amount);
            }
        }
        return _totalStakes;
    }



    /**
     * @notice A method to check if a pool exist.
     * @param _name The name to verify.
     * @return bool, uint256 Whether the name exist,
     * and if so its position in the poollist array.
     */
    function isPool(string memory _name) public view returns (bool, uint256) {
        for (uint256 s = 0; s < poollist.length; s += 1) {
            if (_compareStrings(_name,poollist[s])) return (true, s);
        }
        return (false, 0);
    }



    /* ==========  UTILS METHODS  ========== */



    function withdrawNative(uint amount, address payable destAddr) public onlyOwner {
        require(amount <= balance, "Insufficient funds");
        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(_msgSender(), destAddr, amount);
    }

    
    function transferToken(address token, address to, uint256 amount) public onlyOwner {
        uint256 bep20balance = IBEP20(token).balanceOf(address(this));
        require(amount <= bep20balance, "balance is low");
        IBEP20(token).safeTransfer(to, amount);
        emit TransferSent(_msgSender(), to, amount);
    }    



    function balanceOfToken(address token) public view returns (uint256) {
        uint256 tokenBal = IBEP20(token).balanceOf(address(this));
        return tokenBal;
    }


    function balanceOfNative() public view returns (uint256) {
        uint256 nativeBal = address(this).balance;
        return nativeBal;
    }


    /* ==========  INTERNAL METHODS  ========== */


    /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder,) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
            Stake storage stake = stakes[_stakeholder];
            stake.valid = false;
        }
    }



    /**
     * @notice A method to add a pool.
     * @param _name The name to add.
     */
    function _addPool(string memory _name) internal {
        (bool _isPool,) = isPool(_name);
        if (!_isPool) poollist.push(_name);
    }


    function _isValidPool (string memory _pool) internal view {
      (bool _isPool, ) = isPool(_pool);
      require(_isPool, "Invalid stake pool");
    }
    

    function _compareStrings(string memory _a, string memory _b) internal pure returns (bool) {
        return (keccak256(bytes(_a)) == keccak256(bytes(_b)));
    }


    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function _isExpired(uint256 _time, uint256 _duration) internal view returns(bool){

        if (block.timestamp >= _time + _duration * 1 weeks) {
            return true;
        } else {
            return false;
        }     
    }


    function _isExpiredInDays(uint256 _time, uint256 _duration) internal view returns(bool){

        if (block.timestamp >= _time + _duration * 1 days) {
            return true;
        } else {
            return false;
        }     
    }


    /* ========== EVENTS ========== */

    event Staked(address indexed sender, uint256 amount, string pool);

    event Withdrawn(address indexed sender, uint256 amount, string pool);

    event RewardPaid(address indexed user, uint256 reward);

    event DailyRewardDistributed(uint256 reward);

    event WeeklyRewardDistributed(uint256 reward);

    event TotalRewardDistributed(uint256 reward);

    event BonusPaid(address indexed user, uint256 bonus);

    event PoolAdded(string pool, uint256 duration);

    event PoolUpdated(string pool, uint256 duration);

    event PoolDeleted(string pool);

    event TransferReceived(address _from, uint _amount);

    event TransferSent(address _from, address _destAddr, uint _amount);
    
}