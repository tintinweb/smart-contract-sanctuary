pragma solidity 0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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


/// @title   Token
/// @author  Jose Perez - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7e14110d1b500e1b0c1b043e1a171917101b06501d1113">[email&#160;protected]</a>>
/// @notice  ERC20 token
/// @dev     The contract allows to perform a number of token sales in different periods in time.
///          allowing participants in previous token sales to transfer tokens to other accounts.
///          Additionally, token locking logic for KYC/AML compliance checking is supported.

contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant name = "ZwoopToken";
    string public constant symbol = "ZWP";
    uint256 public constant decimals = 18;

    // Using same number of decimal figures as ETH (i.e. 18).
    uint256 public constant TOKEN_UNIT = 10 ** uint256(decimals);

    // Maximum number of tokens in circulation
    uint256 public constant MAX_TOKEN_SUPPLY = 2000000000 * TOKEN_UNIT;

    // Maximum number of tokens sales to be performed.
    uint256 public constant MAX_TOKEN_SALES = 1;

    // Maximum size of the batch functions input arrays.
    uint256 public constant MAX_BATCH_SIZE = 400;

    address public assigner;    // The address allowed to assign or mint tokens during token sale.
    address public locker;      // The address allowed to lock/unlock addresses.

    mapping(address => bool) public locked;        // If true, address&#39; tokens cannot be transferred.

    uint256 public currentTokenSaleId = 0;           // The id of the current token sale.
    mapping(address => uint256) public tokenSaleId;  // In which token sale the address participated.

    bool public tokenSaleOngoing = false;

    event TokenSaleStarting(uint indexed tokenSaleId);
    event TokenSaleEnding(uint indexed tokenSaleId);
    event Lock(address indexed addr);
    event Unlock(address indexed addr);
    event Assign(address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event LockerTransferred(address indexed previousLocker, address indexed newLocker);
    event AssignerTransferred(address indexed previousAssigner, address indexed newAssigner);

    /// @dev Constructor that initializes the contract.
    /// @param _assigner The assigner account.
    /// @param _locker The locker account.
    constructor(address _assigner, address _locker) public {
        require(_assigner != address(0));
        require(_locker != address(0));

        assigner = _assigner;
        locker = _locker;
    }

    /// @dev True if a token sale is ongoing.
    modifier tokenSaleIsOngoing() {
        require(tokenSaleOngoing);
        _;
    }

    /// @dev True if a token sale is not ongoing.
    modifier tokenSaleIsNotOngoing() {
        require(!tokenSaleOngoing);
        _;
    }

    /// @dev Throws if called by any account other than the assigner.
    modifier onlyAssigner() {
        require(msg.sender == assigner);
        _;
    }

    /// @dev Throws if called by any account other than the locker.
    modifier onlyLocker() {
        require(msg.sender == locker);
        _;
    }

    /// @dev Starts a new token sale. Only the owner can start a new token sale. If a token sale
    ///      is ongoing, it has to be ended before a new token sale can be started.
    ///      No more than `MAX_TOKEN_SALES` sales can be carried out.
    /// @return True if the operation was successful.
    function tokenSaleStart() external onlyOwner tokenSaleIsNotOngoing returns(bool) {
        require(currentTokenSaleId < MAX_TOKEN_SALES);
        currentTokenSaleId++;
        tokenSaleOngoing = true;
        emit TokenSaleStarting(currentTokenSaleId);
        return true;
    }

    /// @dev Ends the current token sale. Only the owner can end a token sale.
    /// @return True if the operation was successful.
    function tokenSaleEnd() external onlyOwner tokenSaleIsOngoing returns(bool) {
        emit TokenSaleEnding(currentTokenSaleId);
        tokenSaleOngoing = false;
        return true;
    }

    /// @dev Returns whether or not a token sale is ongoing.
    /// @return True if a token sale is ongoing.
    function isTokenSaleOngoing() external view returns(bool) {
        return tokenSaleOngoing;
    }

    /// @dev Getter of the variable `currentTokenSaleId`.
    /// @return Returns the current token sale id.
    function getCurrentTokenSaleId() external view returns(uint256) {
        return currentTokenSaleId;
    }

    /// @dev Getter of the variable `tokenSaleId[]`.
    /// @param _address The address of the participant.
    /// @return Returns the id of the token sale the address participated in.
    function getAddressTokenSaleId(address _address) external view returns(uint256) {
        return tokenSaleId[_address];
    }

    /// @dev Allows the current owner to change the assigner.
    /// @param _newAssigner The address of the new assigner.
    /// @return True if the operation was successful.
    function transferAssigner(address _newAssigner) external onlyOwner returns(bool) {
        require(_newAssigner != address(0));

        emit AssignerTransferred(assigner, _newAssigner);
        assigner = _newAssigner;
        return true;
    }

    /// @dev Function to mint tokens. It can only be called by the assigner during an ongoing token sale.
    /// @param _to The address that will receive the minted tokens.
    /// @param _amount The amount of tokens to mint.
    /// @return A boolean that indicates if the operation was successful.
    function mint(address _to, uint256 _amount) public onlyAssigner tokenSaleIsOngoing returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        require(totalSupply_ <= MAX_TOKEN_SUPPLY);

        if (tokenSaleId[_to] == 0) {
            tokenSaleId[_to] = currentTokenSaleId;
        }
        require(tokenSaleId[_to] == currentTokenSaleId);

        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /// @dev Mints tokens for several addresses in one single call.
    /// @param _to address[] The addresses that get the tokens.
    /// @param _amount address[] The number of tokens to be minted.
    /// @return A boolean that indicates if the operation was successful.
    function mintInBatches(address[] _to, uint256[] _amount) external onlyAssigner tokenSaleIsOngoing returns(bool) {
        require(_to.length > 0);
        require(_to.length == _amount.length);
        require(_to.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _to.length; i++) {
            mint(_to[i], _amount[i]);
        }
        return true;
    }

    /// @dev Function to assign any number of tokens to a given address.
    ///      Compared to the `mint` function, the `assign` function allows not just to increase but also to decrease
    ///      the number of tokens of an address by assigning a lower value than the address current balance.
    ///      This function can only be executed during initial token sale.
    /// @param _to The address that will receive the assigned tokens.
    /// @param _amount The amount of tokens to assign.
    /// @return True if the operation was successful.
    function assign(address _to, uint256 _amount) public onlyAssigner tokenSaleIsOngoing returns(bool) {
        require(currentTokenSaleId == 1);

        // The desired value to assign (`_amount`) can be either higher or lower than the current number of tokens
        // of the address (`balances[_to]`). To calculate the new `totalSupply_` value, the difference between `_amount`
        // and `balances[_to]` (`delta`) is calculated first, and then added or substracted to `totalSupply_` accordingly.
        uint256 delta = 0;
        if (balances[_to] < _amount) {
            // balances[_to] will be increased, so totalSupply_ should be increased
            delta = _amount.sub(balances[_to]);
            totalSupply_ = totalSupply_.add(delta);
        } else {
            // balances[_to] will be decreased, so totalSupply_ should be decreased
            delta = balances[_to].sub(_amount);
            totalSupply_ = totalSupply_.sub(delta);
        }
        require(totalSupply_ <= MAX_TOKEN_SUPPLY);

        balances[_to] = _amount;
        tokenSaleId[_to] = currentTokenSaleId;

        emit Assign(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /// @dev Assigns tokens to several addresses in one call.
    /// @param _to address[] The addresses that get the tokens.
    /// @param _amount address[] The number of tokens to be assigned.
    /// @return True if the operation was successful.
    function assignInBatches(address[] _to, uint256[] _amount) external onlyAssigner tokenSaleIsOngoing returns(bool) {
        require(_to.length > 0);
        require(_to.length == _amount.length);
        require(_to.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _to.length; i++) {
            assign(_to[i], _amount[i]);
        }
        return true;
    }

    /// @dev Allows the current owner to change the locker.
    /// @param _newLocker The address of the new locker.
    /// @return True if the operation was successful.
    function transferLocker(address _newLocker) external onlyOwner returns(bool) {
        require(_newLocker != address(0));

        emit LockerTransferred(locker, _newLocker);
        locker = _newLocker;
        return true;
    }

    /// @dev Locks an address. A locked address cannot transfer its tokens or other addresses&#39; tokens out.
    ///      Only addresses participating in the current token sale can be locked.
    ///      Only the locker account can lock addresses and only during the token sale.
    /// @param _address address The address to lock.
    /// @return True if the operation was successful.
    function lockAddress(address _address) public onlyLocker tokenSaleIsOngoing returns(bool) {
        require(tokenSaleId[_address] == currentTokenSaleId);
        require(!locked[_address]);

        locked[_address] = true;
        emit Lock(_address);
        return true;
    }

    /// @dev Unlocks an address so that its owner can transfer tokens out again.
    ///      Addresses can be unlocked any time. Only the locker account can unlock addresses
    /// @param _address address The address to unlock.
    /// @return True if the operation was successful.
    function unlockAddress(address _address) public onlyLocker returns(bool) {
        require(locked[_address]);

        locked[_address] = false;
        emit Unlock(_address);
        return true;
    }

    /// @dev Locks several addresses in one single call.
    /// @param _addresses address[] The addresses to lock.
    /// @return True if the operation was successful.
    function lockInBatches(address[] _addresses) external onlyLocker returns(bool) {
        require(_addresses.length > 0);
        require(_addresses.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _addresses.length; i++) {
            lockAddress(_addresses[i]);
        }
        return true;
    }

    /// @dev Unlocks several addresses in one single call.
    /// @param _addresses address[] The addresses to unlock.
    /// @return True if the operation was successful.
    function unlockInBatches(address[] _addresses) external onlyLocker returns(bool) {
        require(_addresses.length > 0);
        require(_addresses.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _addresses.length; i++) {
            unlockAddress(_addresses[i]);
        }
        return true;
    }

    /// @dev Checks whether or not the given address is locked.
    /// @param _address address The address to be checked.
    /// @return Boolean indicating whether or not the address is locked.
    function isLocked(address _address) external view returns(bool) {
        return locked[_address];
    }

    /// @dev Transfers tokens to the specified address. It prevents transferring tokens from a locked address.
    ///      Locked addresses can receive tokens.
    ///      Current token sale&#39;s addresses cannot receive or send tokens until the token sale ends.
    /// @param _to The address to transfer tokens to.
    /// @param _value The number of tokens to be transferred.
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(!locked[msg.sender]);

        if (tokenSaleOngoing) {
            require(tokenSaleId[msg.sender] < currentTokenSaleId);
            require(tokenSaleId[_to] < currentTokenSaleId);
        }

        return super.transfer(_to, _value);
    }

    /// @dev Transfers tokens from one address to another. It prevents transferring tokens if the caller is locked or
    ///      if the allowed address is locked.
    ///      Locked addresses can receive tokens.
    ///      Current token sale&#39;s addresses cannot receive or send tokens until the token sale ends.
    /// @param _from address The address to transfer tokens from.
    /// @param _to address The address to transfer tokens to.
    /// @param _value The number of tokens to be transferred.
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(!locked[msg.sender]);
        require(!locked[_from]);

        if (tokenSaleOngoing) {
            require(tokenSaleId[msg.sender] < currentTokenSaleId);
            require(tokenSaleId[_from] < currentTokenSaleId);
            require(tokenSaleId[_to] < currentTokenSaleId);
        }

        return super.transferFrom(_from, _to, _value);
    }
}


/// @title  ExchangeRate
/// @author Jose Perez - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e08a8f9385ce908592859aa0848987898e8598ce838f8d">[email&#160;protected]</a>>
/// @notice Tamper-proof record of exchange rates e.g. BTC/USD, ETC/USD, etc.
/// @dev    Exchange rates are updated from off-chain server periodically. Rates are taken from a
//          publicly available third-party provider, such as Coinbase, CoinMarketCap, etc.
contract ExchangeRate is Ownable {
    event RateUpdated(string id, uint256 rate);
    event UpdaterTransferred(address indexed previousUpdater, address indexed newUpdater);

    address public updater;

    mapping(string => uint256) internal currentRates;

    /// @dev The ExchangeRate constructor.
    /// @param _updater Account which can update the rates.
    constructor(address _updater) public {
        require(_updater != address(0));
        updater = _updater;
    }

    /// @dev Throws if called by any account other than the updater.
    modifier onlyUpdater() {
        require(msg.sender == updater);
        _;
    }

    /// @dev Allows the current owner to change the updater.
    /// @param _newUpdater The address of the new updater.
    function transferUpdater(address _newUpdater) external onlyOwner {
        require(_newUpdater != address(0));
        emit UpdaterTransferred(updater, _newUpdater);
        updater = _newUpdater;
    }

    /// @dev Allows the current updater account to update a single rate.
    /// @param _id The rate identifier.
    /// @param _rate The exchange rate.
    function updateRate(string _id, uint256 _rate) external onlyUpdater {
        require(_rate != 0);
        currentRates[_id] = _rate;
        emit RateUpdated(_id, _rate);
    }

    /// @dev Allows anyone to read the current rate.
    /// @param _id The rate identifier.
    /// @return The current rate.
    function getRate(string _id) external view returns(uint256) {
        return currentRates[_id];
    }
}


/// @title  VestingTrustee
/// @author Jose Perez - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="86ece9f5e3a8f6e3f4e3fcc6e2efe1efe8e3fea8e5e9eb">[email&#160;protected]</a>>
/// @notice Vesting trustee contract for Diginex ERC20 tokens. Tokens are granted to specific
///         addresses and vested under certain criteria (vesting period, cliff period, etc.)
///         Tokens must be transferred to the VestingTrustee contract address prior to granting them.
contract VestingTrustee is Ownable {
    using SafeMath for uint256;

    // ERC20 contract.
    Token public token;

    // The address allowed to grant and revoke tokens.
    address public vester;

    // Vesting grant for a specific holder.
    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 installmentLength; // In seconds.
        uint256 transferred;
        bool revocable;
    }

    // Holder to grant information mapping.
    mapping (address => Grant) public grants;

    // Total tokens available for vesting.
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event TokensUnlocked(address indexed _to, uint256 _value);
    event GrantRevoked(address indexed _holder, uint256 _refund);
    event VesterTransferred(address indexed previousVester, address indexed newVester);

    /// @dev Constructor that initializes the VestingTrustee contract.
    /// @param _diginexCoin The address of the previously deployed ERC20 token contract.
    /// @param _vester The vester address.
    constructor(Token _diginexCoin, address _vester) public {
        require(_diginexCoin != address(0));
        require(_vester != address(0));

        token = _diginexCoin;
        vester = _vester;
    }

    // @dev Prevents being called by any account other than the vester.
    modifier onlyVester() {
        require(msg.sender == vester);
        _;
    }

    /// @dev Allows the owner to change the vester.
    /// @param _newVester The address of the new vester.
    /// @return True if the operation was successful.
    function transferVester(address _newVester) external onlyOwner returns(bool) {
        require(_newVester != address(0));

        emit VesterTransferred(vester, _newVester);
        vester = _newVester;
        return true;
    }
    

    /// @dev Grant tokens to a specified address. All time units are in seconds since Unix epoch.
    ///      Tokens must be transferred to the VestingTrustee contract address prior to calling this
    ///      function. The number of tokens assigned to the VestingTrustee contract address must
    //       always be equal or greater than the total number of vested tokens.
    /// @param _to address The holder address.
    /// @param _value uint256 The amount of tokens to be granted.
    /// @param _start uint256 The beginning of the vesting period.
    /// @param _cliff uint256 Time, between _start and _end, when the first installment is made.
    /// @param _end uint256 The end of the vesting period.
    /// @param _installmentLength uint256 The length of each vesting installment.
    /// @param _revocable bool Whether the grant is revocable or not.
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, bool _revocable)
        external onlyVester {

        require(_to != address(0));
        require(_to != address(this)); // Don&#39;t allow holder to be this contract.
        require(_value > 0);

        // Require that every holder can be granted tokens only once.
        require(grants[_to].value == 0);

        // Require for time ranges to be consistent and valid.
        require(_start <= _cliff && _cliff <= _end);

        // Require installment length to be valid and no longer than (end - start).
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

        // Grant must not exceed the total amount of tokens currently available for vesting.
        require(totalVesting.add(_value) <= token.balanceOf(address(this)));

        // Assign a new grant.
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: 0,
            revocable: _revocable
        });

        // Since tokens have been granted, increase the total amount of vested tokens.
        // This indirectly reduces the total amount available for vesting.
        totalVesting = totalVesting.add(_value);

        emit NewGrant(msg.sender, _to, _value);
    }

    /// @dev Revoke the grant of tokens of a specified grantee address.
    ///      The vester can arbitrarily revoke the tokens of a revocable grant anytime.
    ///      However, the grantee owns `calculateVestedTokens` number of tokens, even if some of them
    ///      have not been transferred to the grantee yet. Therefore, the `revoke` function should
    ///      transfer all non-transferred tokens to their rightful owner. The rest of the granted tokens
    ///      should be transferred to the vester.
    /// @param _holder The address which will have its tokens revoked.
    function revoke(address _holder) public onlyVester {
        Grant storage holderGrant = grants[_holder];

        // Grant must be revocable.
        require(holderGrant.revocable);

        // Calculate number of tokens to be transferred to vester and to holder:
        // holderGrant.value = toVester + vested = toVester + ( toHolder + holderGrant.transferred )
        uint256 vested = calculateVestedTokens(holderGrant, now);
        uint256 toVester = holderGrant.value.sub(vested);
        uint256 toHolder = vested.sub(holderGrant.transferred);

        // Remove grant information.
        delete grants[_holder];

        // Update totalVesting.
        totalVesting = totalVesting.sub(toHolder);
        totalVesting = totalVesting.sub(toVester);

        // Transfer tokens.
        token.transfer(_holder, toHolder);
        token.transfer(vester, toVester);
        
        emit GrantRevoked(_holder, toVester);
    }

    /// @dev Calculate amount of vested tokens at a specifc time.
    /// @param _grant Grant The vesting grant.
    /// @param _time uint256 The time to be checked
    /// @return a uint256 Representing the amount of vested tokens of a specific grant.
    function calculateVestedTokens(Grant _grant, uint256 _time) private pure returns (uint256) {
        // If we&#39;re before the cliff, then nothing is vested.
        if (_time < _grant.cliff) {
            return 0;
        }

        // If we&#39;re after the end of the vesting period - everything is vested;
        if (_time >= _grant.end) {
            return _grant.value;
        }

        // Calculate amount of installments past until now.
        // NOTE: result gets floored because of integer division.
        uint256 installmentsPast = _time.sub(_grant.start).div(_grant.installmentLength);

        // Calculate amount of days in entire vesting period.
        uint256 vestingDays = _grant.end.sub(_grant.start);

        // Calculate and return installments that have passed according to vesting days that have passed.
        return _grant.value.mul(installmentsPast.mul(_grant.installmentLength)).div(vestingDays);
    }

    /// @dev Calculate the total amount of vested tokens of a holder at a given time.
    /// @param _holder address The address of the holder.
    /// @param _time uint256 The specific time to calculate against.
    /// @return a uint256 Representing a holder&#39;s total amount of vested tokens.
    function vestedTokens(address _holder, uint256 _time) external view returns (uint256) {
        Grant memory holderGrant = grants[_holder];

        if (holderGrant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(holderGrant, _time);
    }

    /// @dev Unlock vested tokens and transfer them to their holder.
    /// @param _holder address The address of the holder.
    function unlockVestedTokens(address _holder) external {
        Grant storage holderGrant = grants[_holder];

        // Require that there will be funds left in grant to transfer to holder.
        require(holderGrant.value.sub(holderGrant.transferred) > 0);

        // Get the total amount of vested tokens, according to grant.
        uint256 vested = calculateVestedTokens(holderGrant, now);
        if (vested == 0) {
            return;
        }

        // Make sure the holder doesn&#39;t transfer more than what he already has.
        uint256 transferable = vested.sub(holderGrant.transferred);
        if (transferable == 0) {
            return;
        }

        // Update transferred and total vesting amount, then transfer remaining vested funds to holder.
        holderGrant.transferred = holderGrant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        token.transfer(_holder, transferable);

        emit TokensUnlocked(_holder, transferable);
    }
}