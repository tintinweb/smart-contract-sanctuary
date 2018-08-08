pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}






/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}



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









/// Gives the owner the ability to transfer ownership of the contract to a new
/// address and it requires the owner of the new address to accept the transfer.






/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



/// @title Admin functionality for TRVLToken.sol contracts.
contract Admin is Claimable{
    mapping(address => bool) public admins;

    event AdminAdded(address added);
    event AdminRemoved(address removed);

    /// @dev Verifies the msg.sender is a member of the admins mapping. Owner is by default an admin.
    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "msg.sender is not an admin!");
        _;
    }

    /// @notice Adds a list of addresses to the admins list.
    /// @dev Requires that the msg.sender is the Owner. Emits an event on success.
    /// @param _admins The list of addresses to add to the admins mapping.
    function addAddressesToAdmins(address[] _admins) external onlyOwner {
        require(_admins.length > 0, "Cannot add an empty list to admins!");
        for (uint256 i = 0; i < _admins.length; ++i) {
            address user = _admins[i];
            require(user != address(0), "Cannot add the zero address to admins!");

            if (!admins[user]) {
                admins[user] = true;

                emit AdminAdded(user);
            }
        }
    }

    /// @notice Removes a list of addresses from the admins list.
    /// @dev Requires that the msg.sender is an Owner. It is possible for the admins list to be empty, this is a fail safe
    /// in the event the admin accounts are compromised. The owner has the ability to lockout the server access from which
    /// TravelBlock is processing payments. Emits an event on success.
    /// @param _admins The list of addresses to remove from the admins mapping.
    function removeAddressesFromAdmins(address[] _admins) external onlyOwner {
        require(_admins.length > 0, "Cannot remove an empty list to admins!");
        for (uint256 i = 0; i < _admins.length; ++i) {
            address user = _admins[i];

            if (admins[user]) {
                admins[user] = false;

                emit AdminRemoved(user);
            }
        }
    }
}



/// @title Whitelist configurations for the TRVL Token contract.
contract Whitelist is Admin {
    mapping(address => bool) public whitelist;

    event WhitelistAdded(address added);
    event WhitelistRemoved(address removed);

    /// @dev Verifies the user is whitelisted.
    modifier isWhitelisted(address _user) {
        require(whitelist[_user] != false, "User is not whitelisted!");
        _;
    }

    /// @notice Adds a list of addresses to the whitelist.
    /// @dev Requires that the msg.sender is the Admin. Emits an event on success.
    /// @param _users The list of addresses to add to the whitelist.
    function addAddressesToWhitelist(address[] _users) external onlyAdmin {
        require(_users.length > 0, "Cannot add an empty list to whitelist!");
        for (uint256 i = 0; i < _users.length; ++i) {
            address user = _users[i];
            require(user != address(0), "Cannot add the zero address to whitelist!");

            if (!whitelist[user]) {
                whitelist[user] = true;

                emit WhitelistAdded(user);
            }
        }
    }

    /// @notice Removes a list of addresses from the whitelist.
    /// @dev Requires that the msg.sender is an Admin. Emits an event on success.
    /// @param _users The list of addresses to remove from the whitelist.
    function removeAddressesFromWhitelist(address[] _users) external onlyAdmin {
        require(_users.length > 0, "Cannot remove an empty list to whitelist!");
        for (uint256 i = 0; i < _users.length; ++i) {
            address user = _users[i];

            if (whitelist[user]) {
                whitelist[user] = false;

                emit WhitelistRemoved(user);
            }
        }
    }
}






/// Standard ERC20 token with the ability to freeze and unfreeze token transfer.











/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

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
    require(_value <= balances[msg.sender]);

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






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
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
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


/// Blocks ERC223 tokens and allows the smart contract to transfer ownership of
/// ERC20 tokens that are sent to the contract address.









/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}



/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d4a6b1b9b7bb94e6">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}



/// @title Reward Token contract that contains all reward token configurations.
contract RewardToken is PausableToken, Whitelist, HasNoTokens{
    /// @dev Any token balances added here must be removed from the balances map.
    mapping(address => uint256) public rewardBalances;

    uint256[] public rewardPercentage;
    uint256 public rewardPercentageDecimals;
    uint256 public rewardPercentageDivisor;

    event RewardPercentage(uint256 index, uint256 percentage);

    /// @dev Verifies the reward index is valid.
    modifier isValidRewardIndex(uint256 _index) {
        require(_index < rewardPercentage.length, "The reward percentage index does not exist!");
        _;
    }

    /// @dev Verifies the reward percentage is valid.
    modifier isValidRewardPercentage(uint256 _percentage) {
        require(_percentage <= rewardPercentageDivisor, "Cannot have a reward percentage greater than 100%!");
        _;
    }

    constructor(uint256 _rewardPercentageDecimals) public {
        rewardPercentageDecimals = _rewardPercentageDecimals;
        rewardPercentageDivisor = (10 ** uint256(_rewardPercentageDecimals)).mul(100);
    }

    /// @notice Adds a reward percentage to the list of available reward percentages, specific to 18 decimals.
    /// @dev To achieve an affective 5% bonus, the sender needs to use 5 x 10^18.
    /// Requires:
    ///     - Msg.sender is an admin
    ///     - Percentage is <= 100%
    /// @param _percentage The new percentage specific to 18 decimals.
    /// @return The index of the percentage added in the rewardPercentage array.
    function addRewardPercentage(uint256 _percentage) public onlyAdmin isValidRewardPercentage(_percentage) returns (uint256 _index) {
        _index = rewardPercentage.length;
        rewardPercentage.push(_percentage);

        emit RewardPercentage(_index, _percentage);
    }

    /// @notice Edits the contents of the percentage array, with the specified parameters.
    /// @dev Allows the owner to edit percentage array contents for a given index.
    /// Requires:
    ///     - Msg.sender is an admin
    ///     - The index must be within the bounds of the rewardPercentage array
    ///     - The new percentage must be <= 100%
    /// @param _index The index of the percentage to be edited.
    /// @param _percentage The new percentage to be used for the given index.
    function updateRewardPercentageByIndex(uint256 _index, uint256 _percentage)
        public
        onlyAdmin
        isValidRewardIndex(_index)
        isValidRewardPercentage(_percentage)
    {
        rewardPercentage[_index] = _percentage;

        emit RewardPercentage(_index, _percentage);
    }

    /// @dev Calculates the reward based on the reward percentage index.
    /// Requires:
    ///     - The index must be within the bounds of the rewardPercentage array
    /// @param _amount The amount tokens to be converted to rewards.
    /// @param _rewardPercentageIndex The location of reward percentage to be applied.
    /// @return The amount of tokens converted to reward tokens.
    function getRewardToken(uint256 _amount, uint256 _rewardPercentageIndex)
        internal
        view
        isValidRewardIndex(_rewardPercentageIndex)
        returns(uint256 _rewardToken)
    {
        _rewardToken = _amount.mul(rewardPercentage[_rewardPercentageIndex]).div(rewardPercentageDivisor);
    }
}



/// @title TRVLToken smart contract
contract TRVLToken is RewardToken {
    string public constant name = "TRVL Token";
    string public constant symbol = "TRVL";
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_CAP = 600000000 * (10 ** uint256(decimals));

    event TransferReward(address from, address to, uint256 value);

    /// @dev Verifies the user has enough tokens to cover the payment.
    modifier senderHasEnoughTokens(uint256 _regularTokens, uint256 _rewardTokens) {
        require(rewardBalances[msg.sender] >= _rewardTokens, "User does not have enough reward tokens!");
        require(balances[msg.sender] >= _regularTokens, "User does not have enough regular tokens!");
        _;
    }

    /// @dev Verifies the amount is > 0.
    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "The amount specified is 0!");
        _;
    }

    /// @dev The TRVL Token is an ERC20 complaint token with a built in reward system that
    /// gives users back a percentage of tokens spent on travel. These tokens are
    /// non-transferable and can only be spent on travel through the TravelBlock website.
    /// The percentages are defined in the rewardPercentage array and can be modified by
    /// the TravelBlock team. The token is created with the entire balance being owned by the address that deploys.
    constructor() RewardToken(decimals) public {
        totalSupply_ = TOTAL_CAP;
        balances[owner] = totalSupply_;
        emit Transfer(0x0, owner, totalSupply_);
    }

    /// @notice Process a payment that prioritizes the use of regular tokens.
    /// @dev Uses up all of the available regular tokens, before using rewards tokens to cover a payment. Pushes the calculated amounts
    /// into their respective function calls.
    /// @param _amount The total tokens to be paid.
    function paymentRegularTokensPriority (uint256 _amount, uint256 _rewardPercentageIndex) public {
        uint256 regularTokensAvailable = balances[msg.sender];

        if (regularTokensAvailable >= _amount) {
            paymentRegularTokens(_amount, _rewardPercentageIndex);

        } else {
            if (regularTokensAvailable > 0) {
                uint256 amountOfRewardsTokens = _amount.sub(regularTokensAvailable);
                paymentMixed(regularTokensAvailable, amountOfRewardsTokens, _rewardPercentageIndex);
            } else {
                paymentRewardTokens(_amount);
            }
        }
    }

    /// @notice Process a payment that prioritizes the use of reward tokens.
    /// @dev Uses up all of the available reward tokens, before using regular tokens to cover a payment. Pushes the calculated amounts
    /// into their respective function calls.
    /// @param _amount The total tokens to be paid.
    function paymentRewardTokensPriority (uint256 _amount, uint256 _rewardPercentageIndex) public {
        uint256 rewardTokensAvailable = rewardBalances[msg.sender];

        if (rewardTokensAvailable >= _amount) {
            paymentRewardTokens(_amount);
        } else {
            if (rewardTokensAvailable > 0) {
                uint256 amountOfRegularTokens = _amount.sub(rewardTokensAvailable);
                paymentMixed(amountOfRegularTokens, rewardTokensAvailable, _rewardPercentageIndex);
            } else {
                paymentRegularTokens(_amount, _rewardPercentageIndex);
            }
        }
    }

    /// @notice Process a TRVL tokens payment with a combination of regular and rewards tokens.
    /// @dev calls the regular/rewards payment methods respectively.
    /// @param _regularTokenAmount The amount of regular tokens to be processed.
    /// @param _rewardTokenAmount The amount of reward tokens to be processed.
    function paymentMixed (uint256 _regularTokenAmount, uint256 _rewardTokenAmount, uint256 _rewardPercentageIndex) public {
        paymentRewardTokens(_rewardTokenAmount);
        paymentRegularTokens(_regularTokenAmount, _rewardPercentageIndex);
    }

    /// @notice Process a payment using only regular TRVL Tokens with a specified reward percentage.
    /// @dev Adjusts the balances accordingly and applies a reward token bonus. The accounts must be whitelisted because the travel team must own the address
    /// to make transfers on their behalf.
    /// Requires:
    ///     - The contract is not paused
    ///     - The amount being processed is greater than 0
    ///     - The reward index being passed is valid
    ///     - The sender has enough tokens to cover the payment
    ///     - The sender is a whitelisted address
    /// @param _regularTokenAmount The amount of regular tokens being used for the payment.
    /// @param _rewardPercentageIndex The index pointing to the percentage of reward tokens to be applied.
    function paymentRegularTokens (uint256 _regularTokenAmount, uint256 _rewardPercentageIndex)
        public
        validAmount(_regularTokenAmount)
        isValidRewardIndex(_rewardPercentageIndex)
        senderHasEnoughTokens(_regularTokenAmount, 0)
        isWhitelisted(msg.sender)
        whenNotPaused
    {
        // 1. Pay the specified amount with from the balance of the user/sender.
        balances[msg.sender] = balances[msg.sender].sub(_regularTokenAmount);

        // 2. distribute reward tokens to the user.
        uint256 rewardAmount = getRewardToken(_regularTokenAmount, _rewardPercentageIndex);
        rewardBalances[msg.sender] = rewardBalances[msg.sender].add(rewardAmount);
        emit TransferReward(owner, msg.sender, rewardAmount);

        // 3. Update the owner balance minus the reward tokens.
        balances[owner] = balances[owner].add(_regularTokenAmount.sub(rewardAmount));
        emit Transfer(msg.sender, owner, _regularTokenAmount.sub(rewardAmount));
    }

    /// @notice Process a payment using only reward TRVL Tokens.
    /// @dev Adjusts internal balances accordingly. The accounts must be whitelisted because the travel team must own the address
    /// to make transfers on their behalf.
    /// Requires:
    ///     - The contract is not paused
    ///     - The amount being processed is greater than 0
    ///     - The sender has enough tokens to cover the payment
    ///     - The sender is a whitelisted address
    /// @param _rewardTokenAmount The amount of reward tokens being used for the payment.
    function paymentRewardTokens (uint256 _rewardTokenAmount)
        public
        validAmount(_rewardTokenAmount)
        senderHasEnoughTokens(0, _rewardTokenAmount)
        isWhitelisted(msg.sender)
        whenNotPaused
    {
        rewardBalances[msg.sender] = rewardBalances[msg.sender].sub(_rewardTokenAmount);
        rewardBalances[owner] = rewardBalances[owner].add(_rewardTokenAmount);

        emit TransferReward(msg.sender, owner, _rewardTokenAmount);
    }

    /// @notice Convert a specific amount of regular TRVL tokens from the owner, into reward tokens for a user.
    /// @dev Converts the regular tokens into reward tokens at a 1-1 ratio.
    /// Requires:
    ///     - Owner has enough tokens to convert
    ///     - The specified user is whitelisted
    ///     - The amount being converted is greater than 0
    /// @param _user The user receiving the converted tokens.
    /// @param _amount The amount of tokens to be converted.
    function convertRegularToRewardTokens(address _user, uint256 _amount)
        external
        onlyOwner
        validAmount(_amount)
        senderHasEnoughTokens(_amount, 0)
        isWhitelisted(_user)
    {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        rewardBalances[_user] = rewardBalances[_user].add(_amount);

        emit TransferReward(msg.sender, _user, _amount);
    }
}