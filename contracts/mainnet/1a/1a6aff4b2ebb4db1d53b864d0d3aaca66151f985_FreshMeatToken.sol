pragma solidity ^0.4.24;

// File: contracts\openzeppelin-solidity\contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
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
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts\openzeppelin-solidity\contracts\lifecycle\Pausable.sol

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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
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
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts\AccountLockableToken.sol

/**
 * @title Account Lockable Token
 */
contract AccountLockableToken is Ownable {
    mapping(address => bool) public lockStates;

    event LockAccount(address indexed lockAccount);
    event UnlockAccount(address indexed unlockAccount);

    /**
     * @dev Throws if called by locked account
     */
    modifier whenNotLocked() {
        require(!lockStates[msg.sender]);
        _;
    }

    /**
     * @dev Lock target account
     * @param _target Target account to lock
     */
    function lockAccount(address _target) public
        onlyOwner
        returns (bool)
    {
        require(_target != owner);
        require(!lockStates[_target]);

        lockStates[_target] = true;

        emit LockAccount(_target);

        return true;
    }

    /**
     * @dev Unlock target account
     * @param _target Target account to unlock
     */
    function unlockAccount(address _target) public
        onlyOwner
        returns (bool)
    {
        require(_target != owner);
        require(lockStates[_target]);

        lockStates[_target] = false;

        emit UnlockAccount(_target);

        return true;
    }
}

// File: contracts\WithdrawableToken.sol

/**
 * @title Withdrawable token
 * @dev Token that can be the withdrawal.
 */
contract WithdrawableToken is BasicToken, Ownable {
    using SafeMath for uint256;

    bool public withdrawingFinished = false;

    event Withdraw(address _from, address _to, uint256 _value);
    event WithdrawFinished();

    modifier canWithdraw() {
        require(!withdrawingFinished);
        _;
    }

    modifier hasWithdrawPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Withdraw the amount of tokens to onwer.
     * @param _from address The address which owner want to withdraw tokens form.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function withdraw(address _from, uint256 _value) public
        hasWithdrawPermission
        canWithdraw
        returns (bool)
    {
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[owner] = balances[owner].add(_value);

        emit Transfer(_from, owner, _value);
        emit Withdraw(_from, owner, _value);

        return true;
    }

    /**
     * @dev Withdraw the amount of tokens to another.
     * @param _from address The address which owner want to withdraw tokens from.
     * @param _to address The address which owner want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function withdrawFrom(address _from, address _to, uint256 _value) public
        hasWithdrawPermission
        canWithdraw
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit Withdraw(_from, _to, _value);

        return true;
    }

    /**
     * @dev Function to stop withdrawing new tokens.
     * @return True if the operation was successful.
     */
    function finishingWithdrawing() public
        onlyOwner
        canWithdraw
        returns (bool)
    {
        withdrawingFinished = true;

        emit WithdrawFinished();

        return true;
    }
}

// File: contracts\MilestoneLockToken.sol

/**
 * @title Milestone Lock Token
 * @dev Token lock that can be the milestone policy applied.
 */
contract MilestoneLockToken is StandardToken, Ownable {
    using SafeMath for uint256;

    struct Policy {
        uint256 kickOff;
        uint256[] periods;
        uint8[] percentages;
    }

    struct MilestoneLock {
        uint8[] policies;
        uint256[] standardBalances;
    }

    uint8 constant MAX_POLICY = 100;
    uint256 constant MAX_PERCENTAGE = 100;

    mapping(uint8 => Policy) internal policies;
    mapping(address => MilestoneLock) internal milestoneLocks;

    event SetPolicyKickOff(uint8 policy, uint256 kickOff);
    event PolicyAdded(uint8 policy);
    event PolicyRemoved(uint8 policy);
    event PolicyAttributeAdded(uint8 policy, uint256 period, uint8 percentage);
    event PolicyAttributeRemoved(uint8 policy, uint256 period);
    event PolicyAttributeModified(uint8 policy, uint256 period, uint8 percentage);

    /**
     * @dev Transfer token for a specified address when enough available unlock balance.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public
        returns (bool)
    {
        require(getAvailableBalance(msg.sender) >= _value);

        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another when enough available unlock balance.
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool)
    {
        require(getAvailableBalance(_from) >= _value);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Distribute the amounts of tokens to from owner&#39;s balance with the milestone policy to a policy-free user.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _policy index of milestone policy to apply.
     */
    function distributeWithPolicy(address _to, uint256 _value, uint8 _policy) public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[owner]);
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));

        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);

        _setMilestoneTo(_to, _value, _policy);

        emit Transfer(owner, _to, _value);

        return true;
    }

    /**
     * @dev add milestone policy.
     * @param _policy index of the milestone policy you want to add.
     * @param _periods periods of the milestone you want to add.
     * @param _percentages unlock percentages of the milestone you want to add.
     */
    function addPolicy(uint8 _policy, uint256[] _periods, uint8[] _percentages) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);
        require(!_checkPolicyEnabled(_policy));
        require(_periods.length > 0);
        require(_percentages.length > 0);
        require(_periods.length == _percentages.length);

        policies[_policy].periods = _periods;
        policies[_policy].percentages = _percentages;

        emit PolicyAdded(_policy);

        return true;
    }

    /**
     * @dev remove milestone policy.
     * @param _policy index of the milestone policy you want to remove.
     */
    function removePolicy(uint8 _policy) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);

        delete policies[_policy];

        emit PolicyRemoved(_policy);

        return true;
    }

    /**
     * @dev get milestone policy information.
     * @param _policy index of milestone policy.
     */
    function getPolicy(uint8 _policy) public
        view
        returns (uint256 kickOff, uint256[] periods, uint8[] percentages)
    {
        require(_policy < MAX_POLICY);

        return (
            policies[_policy].kickOff,
            policies[_policy].periods,
            policies[_policy].percentages
        );
    }

    /**
     * @dev set milestone policy&#39;s kickoff time.
     * @param _policy index of milestone poicy.
     * @param _time kickoff time of policy.
     */
    function setKickOff(uint8 _policy, uint256 _time) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));

        policies[_policy].kickOff = _time;

        return true;
    }

    /**
     * @dev add attribute to milestone policy.
     * @param _policy index of milestone policy.
     * @param _period period of policy attribute.
     * @param _percentage percentage of unlocking when reaching policy.
     */
    function addPolicyAttribute(uint8 _policy, uint256 _period, uint8 _percentage) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));

        Policy storage policy = policies[_policy];

        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.periods[i] == _period) {
                revert();
                return false;
            }
        }

        policy.periods.push(_period);
        policy.percentages.push(_percentage);

        emit PolicyAttributeAdded(_policy, _period, _percentage);

        return true;
    }

    /**
     * @dev remove attribute from milestone policy.
     * @param _policy index of milestone policy attribute.
     * @param _period period of target policy.
     */
    function removePolicyAttribute(uint8 _policy, uint256 _period) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);

        Policy storage policy = policies[_policy];
        
        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.periods[i] == _period) {
                _removeElementAt256(policy.periods, i);
                _removeElementAt8(policy.percentages, i);

                emit PolicyAttributeRemoved(_policy, _period);

                return true;
            }
        }

        revert();

        return false;
    }

    /**
     * @dev modify attribute from milestone policy.
     * @param _policy index of milestone policy.
     * @param _period period of target policy attribute.
     * @param _percentage percentage to modified.
     */
    function modifyPolicyAttribute(uint8 _policy, uint256 _period, uint8 _percentage) public
        onlyOwner
        returns (bool)
    {
        require(_policy < MAX_POLICY);

        Policy storage policy = policies[_policy];
        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.periods[i] == _period) {
                policy.percentages[i] = _percentage;

                emit PolicyAttributeModified(_policy, _period, _percentage);

                return true;
            }
        }

        revert();

        return false;
    }

    /**
     * @dev get policy&#39;s locked percentage of milestone policy from now.
     * @param _policy index of milestone policy for calculate locked percentage.
     */
    function getPolicyLockedPercentage(uint8 _policy) public view
        returns (uint256)
    {
        require(_policy < MAX_POLICY);

        Policy storage policy = policies[_policy];

        if (policy.periods.length == 0) {
            return 0;
        }
        
        if (policy.kickOff == 0 ||
            policy.kickOff > now) {
            return MAX_PERCENTAGE;
        }

        uint256 unlockedPercentage = 0;
        for (uint256 i = 0; i < policy.periods.length; i++) {
            if (policy.kickOff.add(policy.periods[i]) <= now) {
                unlockedPercentage =
                    unlockedPercentage.add(policy.percentages[i]);
            }
        }

        if (unlockedPercentage > MAX_PERCENTAGE) {
            return 0;
        }

        return MAX_PERCENTAGE.sub(unlockedPercentage);
    }

    /**
     * @dev change account&#39;s milestone policy.
     * @param _from address for milestone policy applyed from.
     * @param _prevPolicy index of original milestone policy.
     * @param _newPolicy index of milestone policy to be changed.
     */
    function modifyMilestoneFrom(address _from, uint8 _prevPolicy, uint8 _newPolicy) public
        onlyOwner
        returns (bool)
    {
        require(_from != address(0));
        require(_prevPolicy != _newPolicy);
        require(_prevPolicy < MAX_POLICY);
        require(_checkPolicyEnabled(_prevPolicy));
        require(_newPolicy < MAX_POLICY);
        require(_checkPolicyEnabled(_newPolicy));

        uint256 prevPolicyIndex = _getAppliedPolicyIndex(_from, _prevPolicy);
        require(prevPolicyIndex < MAX_POLICY);

        _setMilestoneTo(_from, milestoneLocks[_from].standardBalances[prevPolicyIndex], _newPolicy);

        milestoneLocks[_from].standardBalances[prevPolicyIndex] = 0;

        return true;
    }

    /**
     * @dev remove milestone policy from account.
     * @param _from address for applied milestone policy removes from.
     * @param _policy index of milestone policy remove. 
     */
    function removeMilestoneFrom(address _from, uint8 _policy) public
        onlyOwner
        returns (bool)
    {
        require(_from != address(0));
        require(_policy < MAX_POLICY);

        uint256 policyIndex = _getAppliedPolicyIndex(_from, _policy);
        require(policyIndex < MAX_POLICY);

        milestoneLocks[_from].standardBalances[policyIndex] = 0;

        return true;
    }

    /**
     * @dev get accounts milestone policy state information.
     * @param _account address for milestone policy applied.
     */
    function getUserMilestone(address _account) public
        view
        returns (uint8[] accountPolicies, uint256[] standardBalances)
    {
        return (
            milestoneLocks[_account].policies,
            milestoneLocks[_account].standardBalances
        );
    }

    /**
     * @dev available unlock balance.
     * @param _account address for available unlock balance.
     */
    function getAvailableBalance(address _account) public
        view
        returns (uint256)
    {
        return balances[_account].sub(getTotalLockedBalance(_account));
    }

    /**
     * @dev calcuate locked balance of milestone policy from now.
     * @param _account address for lock balance.
     * @param _policy index of applied milestone policy.
     */
    function getLockedBalance(address _account, uint8 _policy) public
        view
        returns (uint256)
    {
        require(_policy < MAX_POLICY);

        uint256 policyIndex = _getAppliedPolicyIndex(_account, _policy);
        if (policyIndex >= MAX_POLICY) {
            return 0;
        }

        MilestoneLock storage milestoneLock = milestoneLocks[_account];
        if (milestoneLock.standardBalances[policyIndex] == 0) {
            return 0;
        }

        uint256 lockedPercentage =
            getPolicyLockedPercentage(milestoneLock.policies[policyIndex]);
        return milestoneLock.standardBalances[policyIndex].div(MAX_PERCENTAGE).mul(lockedPercentage);
    }

    /**
     * @dev calcuate locked balance of milestone policy from now.
     * @param _account address for lock balance.
     */
    function getTotalLockedBalance(address _account) public
        view
        returns (uint256)
    {
        MilestoneLock storage milestoneLock = milestoneLocks[_account];

        uint256 totalLockedBalance = 0;
        for (uint256 i = 0; i < milestoneLock.policies.length; i++) {
            totalLockedBalance = totalLockedBalance.add(
                getLockedBalance(_account, milestoneLock.policies[i])
            );
        }

        return totalLockedBalance;
    }

    /**
     * @dev check for policy is enabled
     * @param _policy index of milestone policy.
     */
    function _checkPolicyEnabled(uint8 _policy) internal
        view
        returns (bool)
    {
        return (policies[_policy].periods.length > 0);
    }

    /**
     * @dev get milestone policy index applied to a user.
     * @param _to address The address which you want get to.
     * @param _policy index of milestone policy applied.
     */
    function _getAppliedPolicyIndex(address _to, uint8 _policy) internal
        view
        returns (uint8)
    {
        require(_policy < MAX_POLICY);

        MilestoneLock storage milestoneLock = milestoneLocks[_to];
        for (uint8 i = 0; i < milestoneLock.policies.length; i++) {
            if (milestoneLock.policies[i] == _policy) {
                return i;
            }
        }

        return MAX_POLICY;
    }

    /**
     * @dev set milestone policy applies to a user.
     * @param _to address The address which 
     * @param _value The amount to apply
     * @param _policy index of milestone policy to apply.
     */
    function _setMilestoneTo(address _to, uint256 _value, uint8 _policy) internal
    {
        uint8 policyIndex = _getAppliedPolicyIndex(_to, _policy);
        if (policyIndex < MAX_POLICY) {
            milestoneLocks[_to].standardBalances[policyIndex] = 
                milestoneLocks[_to].standardBalances[policyIndex].add(_value);
        } else {
            milestoneLocks[_to].policies.push(_policy);
            milestoneLocks[_to].standardBalances.push(_value);
        }
    }

    /**
     * @dev utility for uint256 array
     * @param _array target array
     * @param _index array index to remove
     */
    function _removeElementAt256(uint256[] storage _array, uint256 _index) internal
        returns (bool)
    {
        if (_array.length <= _index) {
            return false;
        }

        for (uint256 i = _index; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
        }

        delete _array[_array.length - 1];
        _array.length--;

        return true;
    }

    /**
     * @dev utility for uint8 array
     * @param _array target array
     * @param _index array index to remove
     */
    function _removeElementAt8(uint8[] storage _array, uint256 _index) internal
        returns (bool)
    {
        if (_array.length <= _index) {
            return false;
        }

        for (uint256 i = _index; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
        }

        delete _array[_array.length - 1];
        _array.length--;

        return true;
    }
}

// File: contracts\FreshMeatToken.sol

/**
 * @title Hena token
 */
contract FreshMeatToken is
    Pausable,
    MintableToken,
    BurnableToken,
    AccountLockableToken,
    WithdrawableToken,
    MilestoneLockToken
{
    uint256 constant MAX_SUFFLY = 1000000000;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor() public
    {
        name = "Fresh Meat Token";
        symbol = "FMT";
        decimals = 18;
        totalSupply_ = MAX_SUFFLY * (10 ** uint(decimals));

        balances[owner] = totalSupply_;

        emit Transfer(address(0), owner, totalSupply_);
    }

    function() public
    {
        revert();
    }

    /**
     * @dev Transfer token for a specified address when if not paused and not locked account
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to anther when if not paused and not locked account
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        require(!lockStates[_from]);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
       when if not paused and not locked account
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender when if not paused and not locked account
     * @param _spender address which will spend the funds.
     * @param _addedValue amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender address which will spend the funds.
     * @param _subtractedValue amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    /**
     * @dev Distribute the amount of tokens to owner&#39;s balance.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function distribute(address _to, uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(owner, _to, _value);

        return true;
    }

    /**
     * @dev Burns a specific amount of tokens by owner.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public
        onlyOwner
    {
        super.burn(_value);
    }

    /**
     * @dev batch to the policy to account&#39;s available balance.
     * @param _policy index of milestone policy to apply.
     * @param _addresses The addresses to apply.
     */
    function batchToApplyMilestone(uint8 _policy, address[] _addresses) public
        onlyOwner
        returns (bool[])
    {
        require(_policy < MAX_POLICY);
        require(_checkPolicyEnabled(_policy));
        require(_addresses.length > 0);

        bool[] memory results = new bool[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            results[i] = false;
            if (_addresses[i] != address(0)) {
                uint256 availableBalance = getAvailableBalance(_addresses[i]);
                results[i] = (availableBalance > 0);
                if (results[i]) {
                    _setMilestoneTo(_addresses[i], availableBalance, _policy);
                }
            }
        }

        return results;
    }
}