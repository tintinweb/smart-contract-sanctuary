/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity 0.5.16;

// based on https://github.com/OpenZeppelin/openzeppelin-solidity/tree/v1.10.0
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}



/**
 * @title BEP20Basic
 * @dev Simpler version of BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract BEP20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Context, BEP20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  uint256 totalMaxSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_msgSender()]);

    balances[_msgSender()] = balances[_msgSender()].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_msgSender(), _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

/**
 * @title BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract BEP20 is BEP20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard BEP20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is Context, BEP20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][_msgSender()]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][_msgSender()] = allowed[_from][_msgSender()].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[_msgSender()][_spender] = _value;
    emit Approval(_msgSender(), _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[_msgSender()][_spender] = (
      allowed[_msgSender()][_spender].add(_addedValue));
    emit Approval(_msgSender(), _spender, allowed[_msgSender()][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[_msgSender()][_spender];
    if (_subtractedValue > oldValue) {
      allowed[_msgSender()][_spender] = 0;
    } else {
      allowed[_msgSender()][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(_msgSender(), _spender, allowed[_msgSender()][_spender]);
    return true;
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Context {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = _msgSender();
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_msgSender() == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Mintable token
 * @dev Simple BEP20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is Context, StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);

  bool public mintingFinished = false;
  uint public mintTotal = 0;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(_msgSender() == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    _mint(_to, _amount);
    return true;
  }

   /**
   * @dev Function to mint tokens internally
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   */
  function _mint(address _to, uint256 _amount) internal {
      require(_to != address(0), "Blockvila: mint to the zero address");
      uint256 tmpTotal = totalSupply_.add(_amount);
      require(tmpTotal <= totalMaxSupply_);
      mintTotal = mintTotal.add(_amount);
      totalSupply_ = totalSupply_.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Mint(_to, _amount);
      emit Transfer(address(0), _to, _amount);

  }

}



/**
 * @title Burnable token
 * @dev Simple BEP20 Token example, with burnable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/BurnableToken.sol
 */
contract BurnableToken is Context, StandardToken, Ownable {

  // @notice An address for the transfer event where the burned tokens are transferred in a faux Transfer event
  address public constant BURN_ADDRESS = address(0);

  /** How many tokens we burned */
  event Burned(address burner, uint256 amount);

  bool public burningFinished = false;
  uint public burnTotal = 0;

  modifier canBurn() {
    require(!burningFinished);
    _;
  }

  modifier hasBurnPermission() {
    require(_msgSender() == owner);
    _;
  }

  /**
  * @dev Function to burn tokens reducing the total supply.
  * @param _to The address to burn token from
  * @param _amount The amount of tokens to burn.
  * @return A boolean that indicates if the operation was successful.
  */
  function burn(
    address _to, 
    uint256 _amount
  ) 
    hasBurnPermission
    canBurn
    public 
    returns (bool) 
  {
    _burn(_to,_amount);
    return true;
  }


  /**
  * @dev Function to burn tokens reducing the total supply.
  * @param _to The address to burn token from
  * @param _amount The amount of tokens to burn.
  */
  function _burn(address _to, uint256 _amount) internal {
    require(_to != address(0), "Blockvila: burn from the zero address");

    balances[_to] = balances[_to].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
    burnTotal = burnTotal.add(_amount);
    emit Burned(_to, _amount);
    emit Transfer(_to, BURN_ADDRESS, _amount);
  }


}




/**
 * @title Staking Token
 * @notice Implements a StandardToken, Ownable, BurnableToken, MintableToken.
 */
contract StakingToken is StandardToken, Ownable, BurnableToken, MintableToken  {
    
    event Staked(address sender, uint256 amount, string plan, uint256 duration);

    event Unstaked(address sender, uint256 amount, string plan);

    // We usually require to know who are all the stakeholders.
    address[] internal stakeholders;

    string[] internal planlist;

    uint256 internal currentTimestamp = now;

    struct Stake {
        uint256 amount;
        uint256 duration; // The duration in weeks of how long the stake should be locked from unstaking
        uint256 created_at; // Timestamp of when stake was created
        uint256 updated_at; // Timestamp of when stake was last modified
        string  plan; 
        bool    valid;
    }

    struct Reward {
        uint256 amount;
        uint256 duration; // The duration in weeks of how long the reward should be locked from withdrawing
        uint256 count; // The number of times reward dropped
        uint256 created_at; // Timestamp of when reward was created
        uint256 updated_at; // Timestamp of when reward was last modified
        uint256 last_withdraw_at;
        bool    valid;
    }


    struct Plan {
        string  name; //The name of the plan, should be a single word in lowercase
        uint256 duration_in_weeks; // The duration in weeks of the plan in weeks
        uint256 total_reward_percentage; //The total reward percentage of the plan
        uint256 minimum_stake; //The minimum amount a stakeholder can stake
        uint256 reward_halving; //Will halve reward every 2 year untill the 6th year if activated
        uint256 created_at; // Timestamp of when plan was created
        uint256 updated_at; // Timestamp of when plan was last modified
        bool    valid;
    }

    //The stakes for each stakeholder.
    mapping(address => Stake) internal stakes;

    // The accumulated rewards for each stakeholder.
    mapping(address => Reward) internal rewards;

    //The plans for each planlist.
    mapping(string => Plan) internal plans;



    // ---------- STAKES ----------
    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     * @param _plan The type of stake to be created.
     */
    function createStake(uint256 _stake, string memory _plan) public {
        
        require(_stake > 0, "Blockvila: Insufficient amount of stakes");
        
        require(balances[_msgSender()] >= _stake, "Blockvila: Your Balance is not enough to stake");

        _isValidPlan(_plan);

        Plan storage plan = plans[_plan];

        require(plan.valid, "Blockvila: Invalid staking plan");
        
        require(_stake >= plan.minimum_stake, "Blockvila: Stake is below minimum allowed stake");
        
        Stake storage stake = stakes[_msgSender()];
    
        require(!stake.valid, "Blockvila: Stake already exist for this stakeholder");
        
        if (!stake.valid) {
            _burn(_msgSender(), _stake);
            addStakeholder(_msgSender());
            stake.amount = stake.amount.add(_stake);
            stake.plan = _plan;
            stake.duration = plan.duration_in_weeks;
            stake.created_at = currentTimestamp;
            stake.updated_at = currentTimestamp;
            stake.valid = true;

            //Add a record for tracking stakeholders reward
            Reward storage reward = rewards[_msgSender()];

            if (!reward.valid) {
              reward.amount = 0;
              reward.count = 0;
              reward.valid = true;
            }
            
            reward.duration = plan.duration_in_weeks;
            reward.created_at = currentTimestamp;
            reward.updated_at = currentTimestamp;

            emit Staked(_msgSender(), stake.amount, _plan, plan.duration_in_weeks);
        }
    }


     /**
     * @notice A method for a stakeholder to increase their stake.
     * @param _stake The size of the stake to be created.
     */
    function increaseStake(uint256 _stake) public payable {
        require(_stake > 0, "Blockvila: Insufficient amount of stakes");
        
        require(balances[_msgSender()] >= _stake, "Blockvila: Your Balance is not enough to stake");

        Stake storage stake = stakes[_msgSender()];
        if (stake.valid) {
            _burn(_msgSender(), _stake);
            stake.amount = stake.amount.add(_stake);
            stake.updated_at = currentTimestamp;
        }
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake) public  {
        require(_stake > 0, "Blockvila: Insufficient amount of stakes");

        Stake storage stake = stakes[_msgSender()];

        require(stake.valid, "Blockvila: No stake found.");

        require(_isExpired(stake.created_at, stake.duration), "Blockvila: You can't unstake untill the stake duration is over.");
       
        require(stake.amount >= _stake, "Blockvila: Insufficient amount of stakes");

        stake.amount = stake.amount.sub(_stake); 
        if (stake.amount == 0) removeStakeholder(_msgSender());
        _mint(_msgSender(), _stake);

        emit Unstaked(_msgSender(), _stake, stake.plan);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder) public view returns (uint256) {
        require(_stakeholder != address(0), "Blockvila: Invalid stakeholder");
        
        Stake storage stake = stakes[_stakeholder];
        
        require(stake.valid, "Blockvila: No stake found.");
        
        return stake.amount;
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            Stake storage stake = stakes[stakeholders[s]];
            _totalStakes = _totalStakes.add(stake.amount);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

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
        }
    }

    // ---------- REWARDS ----------

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) public view returns (uint256) {
        Reward storage reward = rewards[_stakeholder];
        return reward.amount;
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards() public view returns (uint256) {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            address stakeholder = stakeholders[s];
            Reward storage reward = rewards[stakeholder];
            _totalRewards = _totalRewards.add(reward.amount);
        }
        return _totalRewards;
    }
    
    
    function calculateTotalHalvedReward(address _stakeholder) public view returns (uint256) {
            
        require(_stakeholder != address(0), "Blockvila: Invalid stakeholder");

        Stake storage stake = stakes[_stakeholder];

        require(stake.valid, "Blockvila: Stake not found");

        Plan storage plan = plans[stake.plan];

        require(plan.valid, "Blockvila: Invalid staking plan");
        
        uint256 reward = stake.amount / (100 * (10 ** 18));
        
        uint256 total_reward = reward.mul(plan.total_reward_percentage);
        
        uint256 total_halved_reward = total_reward;
        
        if(plan.reward_halving > 0){
         
            if (now >= plan.created_at + 104 weeks) {
            
                total_halved_reward = total_reward/2;
                
                if(now >= plan.created_at + 208 weeks){
                    
                    total_halved_reward = total_reward/4;
                    
                    if(now >= plan.created_at + 312 weeks){
                    
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
        require(_stakeholder != address(0), "Blockvila: Invalid stakeholder");

        Stake storage stake = stakes[_stakeholder];

        require(stake.valid, "Blockvila: Stake not found");

        Plan storage plan = plans[stake.plan];

        require(plan.valid, "Blockvila: Invalid staking plan");
        
        return calculateTotalHalvedReward(_stakeholder);
    }


     /**
     * @notice A simple method that calculates the weekly rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateWeeklyReward(address _stakeholder) public view returns (uint256) {
        require(_stakeholder != address(0), "Blockvila: Invalid stakeholder");
        
        Stake storage stake = stakes[_stakeholder];

        require(stake.valid, "Blockvila: Stake not found");
        
        Plan storage plan = plans[stake.plan];

        require(plan.valid, "Blockvila: Invalid staking plan");
        
        uint256 total_reward = calculateTotalReward(_stakeholder);

        uint256 weekly_reward = total_reward / plan.duration_in_weeks;
        
        return weekly_reward;
    }
    
    
    /**
     * @notice A simple method that calculates the daily rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateDailyReward(address _stakeholder) public view returns (uint256) {
        require(_stakeholder != address(0), "Blockvila: Invalid stakeholder");
        
        Stake storage stake = stakes[_stakeholder];

        require(stake.valid, "Blockvila: Stake not found");
        
        Plan storage plan = plans[stake.plan];

        require(plan.valid, "Blockvila: Invalid staking plan");
        
        uint256 weekly_reward = calculateWeeklyReward(_stakeholder);

        uint256 daily_reward = weekly_reward / 7;
        
        return daily_reward;
    }
    
    
    /**
     * @notice A method to distribute total rewards to all stakeholders.
     */
    function distributeTotalRewards() public payable onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {

            address stakeholder = stakeholders[s];

            Stake storage stake = stakes[stakeholder];

            Reward storage reward = rewards[stakeholder];

            if(stake.valid && reward.valid){
                
                uint256 _reward = calculateTotalReward(stakeholder);
                
                uint256 _next_reward_in_days = 7;
                
                uint256 _max_reward_count = reward.duration.mul(_next_reward_in_days);
                
                //check if staking period for stakeholder has not expired
                if (!_isExpired(stake.created_at, stake.duration) && _reward > reward.amount) {
                    if (reward.count < _max_reward_count) {
 
                        reward.amount = _reward;

                        reward.count = reward.count.add(_max_reward_count);

                        reward.updated_at = currentTimestamp;

                    }
                }
            }
        }
    }


     /**
     * @notice A method to distribute weekly rewards to all stakeholders.
     */
    function distributeWeeklyRewards() public payable onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {

            address stakeholder = stakeholders[s];

            Stake storage stake = stakes[stakeholder];

            Reward storage reward = rewards[stakeholder];

            if(stake.valid && reward.valid){
                
                uint256 _total_reward = calculateTotalReward(stakeholder);
                
                uint256 _reward = calculateWeeklyReward(stakeholder);

                uint256 _next_reward_in_days = 7; 
                
                uint256 _check_reward_count_exceeded = reward.count + _next_reward_in_days; 
                
                uint256 _max_reward_count = reward.duration.mul(_next_reward_in_days);
                
                //check if staking period for stakeholder has not expired
                if (!_isExpired(stake.created_at, stake.duration)) {
                    if (reward.count < _max_reward_count && _check_reward_count_exceeded <= _max_reward_count && _isExpiredInDays(reward.updated_at, _next_reward_in_days)  && _total_reward > reward.amount) {

                        reward.amount = reward.amount.add(_reward);
                        reward.count = reward.count.add(_next_reward_in_days);
                        reward.updated_at = currentTimestamp;

                    }
                }
            }
        }
    }
    
    
    /**
     * @notice A method to distribute daily rewards to all stakeholders.
     */
    function distributeDailyRewards() public payable onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {

            address stakeholder = stakeholders[s];

            Stake storage stake = stakes[stakeholder];

            Reward storage reward = rewards[stakeholder];

            if(stake.valid && reward.valid){
                
                uint256 _total_reward = calculateTotalReward(stakeholder);
                
                uint256 _reward = calculateDailyReward(stakeholder);

                uint256 _next_reward_in_days = 1;
                
                uint256 _check_reward_count_exceeded = reward.count + _next_reward_in_days;
                
                uint256 _max_reward_count = reward.duration.mul(_next_reward_in_days);
                
                //check if staking period for stakeholder has not expired
                if (!_isExpired(stake.created_at, stake.duration)) {
                    if (reward.count < _max_reward_count && _check_reward_count_exceeded <= _max_reward_count && _isExpiredInDays(reward.updated_at, _next_reward_in_days)  && _total_reward > reward.amount) {

                        reward.amount = reward.amount.add(_reward);
                        reward.count = reward.count.add(_next_reward_in_days);
                        reward.updated_at = currentTimestamp;

                    }
                }
            }
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public {

        Reward storage reward = rewards[_msgSender()];

        require(reward.valid, "Blockvila: No reward found.");

        require(_isExpired(reward.created_at, reward.duration), "Blockvila: Can't withdraw reward until the holding duration is over.");

        if (_isExpired(reward.created_at, reward.duration)) {

          _mint(_msgSender(), reward.amount);
          reward.amount = 0; //reset amount
          reward.count = 0; //reset count
          reward.last_withdraw_at = currentTimestamp;
        }
    }
    

    // ---------- PLANS ----------


    /**
     * @notice A method for a contract owner to create a staking plan.
     * @param _name The name of the plan to be created.
     * @param _minimum_stake The minimum a stakeholder can stake.
     * @param _duration The duration in weeks of the plan to be created.
     * @param _reward_percentage The total reward percentage of the plan to be created
     * @param _reward_halving Whether to activate reward halving or not. 1 to activate | 0 to deactivate
     */
    function createPlan(string memory _name, uint256 _minimum_stake, uint256 _duration,  uint256 _reward_percentage, uint256 _reward_halving) public onlyOwner {

        require(_duration > 0, "Blockvila: Duration in weeks can't be zero");
        
        require(_minimum_stake > 0, "Blockvila: Minimum stake can't be zero");

        require(_reward_percentage > 0, "Blockvila: Total reward percentage can't be zero");
     
        Plan storage plan = plans[_name];
        if (!plan.valid) {
            _addPlan(_name);
            plan.name = _name;
            plan.minimum_stake = _minimum_stake;
            plan.duration_in_weeks = _duration;
            plan.total_reward_percentage = _reward_percentage;
            plan.reward_halving = (_reward_halving > 0)? 1 : 0;
            plan.created_at = currentTimestamp;
            plan.valid = true;
        }
    }


     /**
      * @notice A method for a contract owner to update a staking plan.
      * @param _name The name of the plan to be updated.
      * @param _minimum_stake The minimum a stakeholder can stake.
      * @param _duration The duration in weeks of the plan to be created.
      * @param _reward_percentage The total reward percentage of the plan to be created
      * @param _reward_halving Whether to activate reward halving or not. 1 to activate | 0 to deactivate
     */
    function updatePlan(string memory _name, uint256 _minimum_stake, uint256 _duration,  uint256 _reward_percentage, uint256 _reward_halving) public onlyOwner {
        
        require(_duration > 0, "Blockvila: Duration in weeks can't be zero");
        
        require(_minimum_stake > 0, "Blockvila: Minimum stake can't be zero");

        require(_reward_percentage > 0, "Blockvila: Total reward percentage can't be zero"); 

        Plan storage plan = plans[_name];
        
        require(plan.valid, "Blockvila: No plan found.");
   
        plan.name = _name;
        plan.minimum_stake = _minimum_stake;
        plan.duration_in_weeks = _duration;
        plan.total_reward_percentage = _reward_percentage;
        plan.reward_halving = (_reward_halving > 0)? 1 : 0;
        plan.updated_at = currentTimestamp;
        
    }

    /**
     * @notice A method for a contract owner to remove a staking plan.
     * @param _name The name of the plan to be removed.
     */
    function removePlan(string memory _name) public onlyOwner {

        Plan storage plan = plans[_name];
        
        require(plan.valid, "Blockvila: No plan found.");
      
        (bool _isPlan, uint256 s) = isPlan(_name);
        if (_isPlan) {
            
             //remove the plan first before reverting stakeholders stakes
            delete plans[_name];
            planlist[s] = planlist[planlist.length - 1];
            planlist.pop();
            
            for (uint256 i = 0; i < stakeholders.length; i += 1) {
                address _stakeholder = stakeholders[i];
                
                Stake storage stake = stakes[_stakeholder];
                
                uint256 _stake = stake.amount;
                
                stake.amount = stake.amount.sub(_stake);
                
                if (stake.amount == 0) removeStakeholder(_stakeholder);
                _mint(_stakeholder, _stake);
            }
           
        }

    }

    /**
     * @notice A method to retrieve the plan with the name.
     * @param _name The plan to retrieve
     */
    function planOf(string memory _name) public view returns (string memory, uint256, uint256, uint256, uint256){
        Plan storage plan = plans[_name];
        
        require(plan.valid, "Blockvila: No plan found.");
        
        return (plan.name, plan.minimum_stake, plan.duration_in_weeks, plan.total_reward_percentage, plan.reward_halving);
    }


    /**
     * @notice A method to check if a plan exist.
     * @param _name The name to verify.
     * @return bool, uint256 Whether the name exist,
     * and if so its position in the planlist array.
     */
    function isPlan(string memory _name) public view returns (bool, uint256) {
        for (uint256 s = 0; s < planlist.length; s += 1) {
            if (_compareStrings(_name,planlist[s])) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a plan.
     * @param _name The name to add.
     */
    function _addPlan(string memory _name) internal {
        (bool _isPlan,) = isPlan(_name);
        if (!_isPlan) planlist.push(_name);
    }


    // ---------- UTILS ----------

    function _isValidPlan (string memory _plan) internal view {
      (bool _isPlan, ) = isPlan(_plan);
      require(_isPlan, "Blockvila: Invalid stake plan");
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

        if (now >= _time + _duration * 1 weeks) {
            return true;
        } else {
            return false;
        }     
    }
    
    function _isExpiredInDays(uint256 _time, uint256 _duration) internal view returns(bool){

        if (now >= _time + _duration * 1 days) {
            return true;
        } else {
            return false;
        }     
    }
    
}




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title Pausable token
 * @dev StakingToken modified with pausable transfers.
 **/
contract PausableToken is StakingToken, Pausable{

  function transfer(address _to,uint256 _value) public whenNotPaused returns (bool){
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){
    return super.transferFrom(_from, _to, _value);
  }

  function approve( address _spender, uint256 _value) public whenNotPaused returns (bool){
    return super.approve(_spender, _value);
  }

  function increaseApproval( address _spender, uint _addedValue) public whenNotPaused returns (bool success){
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval( address _spender, uint _subtractedValue) public whenNotPaused returns (bool success){
    return super.decreaseApproval(_spender, _subtractedValue);
  }
    
  function createStake(uint256 _stake, string memory _plan) public whenNotPaused{
    super.createStake(_stake, _plan);
  }
  
  function increaseStake(uint256 _stake) public payable whenNotPaused {
    super.increaseStake(_stake);
  }
  
  function removeStake(uint256 _stake) public whenNotPaused {
    super.removeStake(_stake);
  }
  
  function withdrawReward() public whenNotPaused {
    super.withdrawReward();
  }

}


contract Blockvila is PausableToken {
    // public variables
    string public name = "Blockvila";
    string public symbol = "VILA";
    uint8 public decimals = 18;

    constructor() public {
        totalMaxSupply_ = 30000000 * (10 ** uint256(decimals));
    }

    function () external payable {
        revert();
    }
    
    function totalMaxSupply() public view returns (uint256) {
        return totalMaxSupply_;
    }
}