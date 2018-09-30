pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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



/**
 * @title Whitelist contract
 * @dev Whitelist for wallets.
*/
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;

    uint256 public whitelistLength = 0;

    address private addressApi;

    modifier onlyPrivilegeAddresses {
        require(msg.sender == addressApi || msg.sender == owner);
        _;
    }

    /**
    * @dev Set backend Api address.
    * @dev Accept request from the owner only.
    * @param _api The address of backend API to set.
    */
    function setApiAddress(address _api) public onlyOwner {
        require(_api != address(0));
        addressApi = _api;
    }

    /**
    * @dev Add wallet to whitelist.
    * @dev Accept request from the privileged addresses only.
    * @param _wallet The address of wallet to add.
    */  
    function addWallet(address _wallet) public onlyPrivilegeAddresses {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }

    /**
    * @dev Remove wallet from whitelist.
    * @dev Accept request from the owner only.
    * @param _wallet The address of whitelisted wallet to remove.
    */  
    function removeWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet] = false;
        whitelistLength--;
    }

    /**
    * @dev Check the specified wallet whether it is in the whitelist.
    * @param _wallet The address of wallet to check.
    */ 
    function isWhitelisted(address _wallet) public view returns (bool) {
        return whitelist[_wallet];
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

contract VeiagToken is StandardToken, Ownable, Pausable {
    string constant public name = "Veiag Token";
    string constant public symbol = "VEIAG";
    uint8 constant public decimals = 18;

    uint256 constant public INITIAL_TOTAL_SUPPLY = 1e9 * (uint256(10) ** decimals);

    address private addressIco;

    modifier onlyIco() {
        require(msg.sender == addressIco);
        _;
    }
    
    /**
    * @dev Create VeiagToken contract and set pause
    * @param _ico The address of ICO contract.
    */
    function VeiagToken (address _ico) public {
        require(_ico != address(0));

        addressIco = _ico;

        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
        balances[_ico] = balances[_ico].add(INITIAL_TOTAL_SUPPLY);
        Transfer(address(0), _ico, INITIAL_TOTAL_SUPPLY);

        pause();
    }

     /**
    * @dev Transfer token for a specified address with pause feature for owner.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another with pause feature for owner.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Transfer tokens from ICO address to another address.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFromIco(address _to, uint256 _value) public onlyIco returns (bool) {
        super.transfer(_to, _value);
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.transfer(beneficiary, amount);
  }
}



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



contract LockedOutTokens is TokenTimelock {
    function LockedOutTokens(
        ERC20Basic _token,
        address _beneficiary,
        uint256 _releaseTime
    ) public TokenTimelock(_token, _beneficiary, _releaseTime)
    {
    }

    function release() public {
        require(beneficiary == msg.sender);

        super.release();
    }
}
/* solium-disable security/no-block-members */


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  function setStart(uint256 _start) onlyOwner public {
    start = _start;  
  }
  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20 token which is being vested
   */
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.transfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param _token ERC20 token which is being vested
   */
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.transfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param _token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

contract VeiagTokenVesting is TokenVesting {
    ERC20Basic public token;

    function VeiagTokenVesting(
        ERC20Basic _token,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable) public
    {
        require(_token != address(0));

        token = _token;
    }

    function grant() public {
        release(token);
    }

    function release(ERC20Basic _token) public {
        require(beneficiary == msg.sender);
        super.release(_token);
    }
}

contract Whitelistable {
    Whitelist public whitelist;

    modifier whenWhitelisted(address _wallet) {
   //     require(whitelist.isWhitelisted(_wallet));
        _;
    }

    /**
    * @dev Constructor for Whitelistable contract.
    */
    function Whitelistable() public {
        whitelist = new Whitelist();
    }
}

contract VeiagCrowdsale is Pausable, Whitelistable {
    using SafeMath for uint256;

    uint256 constant private DECIMALS = 18;

    uint256 constant public RESERVED_LOCKED_TOKENS = 250e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_TEAMS_TOKENS = 100e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_FOUNDERS_TOKENS = 100e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_MARKETING_TOKENS = 50e6 * (10 ** DECIMALS);

    uint256 constant public MAXCAP_TOKENS_PRE_ICO = 100e6 * (10 ** DECIMALS);
    
    uint256 constant public MAXCAP_TOKENS_ICO = 400e6 * (10 ** DECIMALS);

    uint256 constant public MIN_INVESTMENT = (10 ** 16);   // 0.01  ETH

    uint256 constant public MAX_INVESTMENT = 100 * (10 ** DECIMALS); // 100  ETH

    uint256 public startTimePreIco = 0;
    uint256 public endTimePreIco = 0;

    uint256 public startTimeIco = 0;
    uint256 public endTimeIco = 0;

    // rate = 0.005 ETH, 1 ETH = 200 tokens
    uint256 public exchangeRatePreIco = 200;

    uint256 public icoFirstWeekRate = 150;
    uint256 public icoSecondWeekRate = 125;
    uint256 public icoThirdWeekRate = 110;
    // rate = 0.01 ETH, 1 ETH = 100 tokens
    uint256 public icoRate = 100;

    uint256 public tokensRemainingPreIco = MAXCAP_TOKENS_PRE_ICO;
    uint256 public tokensRemainingIco = MAXCAP_TOKENS_ICO;

    uint256 public tokensSoldPreIco = 0;
    uint256 public tokensSoldIco = 0;
    uint256 public tokensSoldTotal = 0;

    uint256 public weiRaisedPreIco = 0;
    uint256 public weiRaisedIco = 0;
    uint256 public weiRaisedTotal = 0;

    VeiagToken public token = new VeiagToken(this);
    LockedOutTokens public lockedTokens;
    VeiagTokenVesting public teamsTokenVesting;
    VeiagTokenVesting public foundersTokenVesting;

    mapping (address => uint256) private totalInvestedAmount;

    modifier beforeReachingPreIcoMaxCap() {
        require(tokensRemainingPreIco > 0);
        _;
    }

    modifier beforeReachingIcoMaxCap() {
        require(tokensRemainingIco > 0);
        _;
    }

    /**
    * @dev Constructor for VeiagCrowdsale contract.
    * @dev Set the owner who can manage whitelist and token.
    * @param _startTimePreIco The pre-ICO start time.
    * @param _endTimePreIco The pre-ICO end time.
    * @param _startTimeIco The ICO start time.
    * @param _endTimeIco The ICO end time.
    * @param _lockedWallet The address for future sale.
    * @param _teamsWallet The address for reserved tokens for teams.
    * @param _foundersWallet The address for reserved tokens for founders.
    * @param _marketingWallet The address for reserved tokens for marketing.
    */
    function VeiagCrowdsale(
        uint256 _startTimePreIco,
        uint256 _endTimePreIco, 
        uint256 _startTimeIco,
        uint256 _endTimeIco,
        address _lockedWallet,
        address _teamsWallet,
        address _foundersWallet,
        address _marketingWallet
    ) public Whitelistable()
    {
        require(_lockedWallet != address(0) && _teamsWallet != address(0) && _foundersWallet != address(0) && _marketingWallet != address(0));
        require(_startTimePreIco > now && _endTimePreIco > _startTimePreIco);
        require(_startTimeIco > _endTimePreIco && _endTimeIco > _startTimeIco);
        startTimePreIco = _startTimePreIco;
        endTimePreIco = _endTimePreIco;

        startTimeIco = _startTimeIco;
        endTimeIco = _endTimeIco;

        lockedTokens = new LockedOutTokens(token, _lockedWallet, RESERVED_LOCKED_TOKENS);
        teamsTokenVesting = new VeiagTokenVesting(token, _teamsWallet, 0, 1 days, 365 days, false);
        foundersTokenVesting = new VeiagTokenVesting(token, _foundersWallet, 0, 1 days, 100 days, false);

        token.transferFromIco(lockedTokens, RESERVED_LOCKED_TOKENS);
        token.transferFromIco(teamsTokenVesting, RESERVED_TEAMS_TOKENS);
        token.transferFromIco(foundersTokenVesting, RESERVED_FOUNDERS_TOKENS);
        token.transferFromIco(_marketingWallet, RESERVED_MARKETING_TOKENS);
        teamsTokenVesting.transferOwnership(this);
        foundersTokenVesting.transferOwnership(this);        
        
        whitelist.transferOwnership(msg.sender);
        token.transferOwnership(msg.sender);
    }
	function SetStartVesting(uint256 _startTimeVestingForFounders) public onlyOwner{
	    require(now > endTimeIco);
	    require(_startTimeVestingForFounders > endTimeIco);
	    teamsTokenVesting.setStart(_startTimeVestingForFounders);
	    foundersTokenVesting.setStart(endTimeIco);
        teamsTokenVesting.transferOwnership(msg.sender);
        foundersTokenVesting.transferOwnership(msg.sender);	    
	}

	function SetStartTimeIco(uint256 _startTimeIco) public onlyOwner{
        uint256 deltaTime;  
        require(_startTimeIco > now && startTimeIco > now);
        if (_startTimeIco > startTimeIco){
          deltaTime = _startTimeIco.sub(startTimeIco);
	      endTimePreIco = endTimePreIco.add(deltaTime);
	      startTimeIco = startTimeIco.add(deltaTime);
	      endTimeIco = endTimeIco.add(deltaTime);
        }
        if (_startTimeIco < startTimeIco){
          deltaTime = startTimeIco.sub(_startTimeIco);
          endTimePreIco = endTimePreIco.sub(deltaTime);
	      startTimeIco = startTimeIco.sub(deltaTime);
	      endTimeIco = endTimeIco.sub(deltaTime);
        }  
    }
	
	
    
    /**
    * @dev Fallback function can be used to buy tokens.
    */
    function() public payable {
        if (isPreIco()) {
            sellTokensPreIco();
        } else if (isIco()) {
            sellTokensIco();
        } else {
            revert();
        }
    }

    /**
    * @dev Check whether the pre-ICO is active at the moment.
    */
    function isPreIco() public view returns (bool) {
        return now >= startTimePreIco && now <= endTimePreIco;
    }

    /**
    * @dev Check whether the ICO is active at the moment.
    */
    function isIco() public view returns (bool) {
        return now >= startTimeIco && now <= endTimeIco;
    }

    /**
    * @dev Calculate rate for ICO phase.
    */
    function exchangeRateIco() public view returns(uint256) {
        require(now >= startTimeIco && now <= endTimeIco);

        if (now < startTimeIco + 1 weeks)
            return icoFirstWeekRate;

        if (now < startTimeIco + 2 weeks)
            return icoSecondWeekRate;

        if (now < startTimeIco + 3 weeks)
            return icoThirdWeekRate;

        return icoRate;
    }
	
    function setExchangeRatePreIco(uint256 _exchangeRatePreIco) public onlyOwner{
	  exchangeRatePreIco = _exchangeRatePreIco;
	} 
	
    function setIcoFirstWeekRate(uint256 _icoFirstWeekRate) public onlyOwner{
	  icoFirstWeekRate = _icoFirstWeekRate;
	} 	
	
    function setIcoSecondWeekRate(uint256 _icoSecondWeekRate) public onlyOwner{
	  icoSecondWeekRate = _icoSecondWeekRate;
	} 
	
    function setIcoThirdWeekRate(uint256 _icoThirdWeekRate) public onlyOwner{
	  icoThirdWeekRate = _icoThirdWeekRate;
	}
	
    function setIcoRate(uint256 _icoRate) public onlyOwner{
	  icoRate = _icoRate;
	}
	
    /**
    * @dev Sell tokens during Pre-ICO stage.
    */
    function sellTokensPreIco() public payable whenWhitelisted(msg.sender) beforeReachingPreIcoMaxCap whenNotPaused {
        require(isPreIco());
        require(msg.value >= MIN_INVESTMENT);
        uint256 senderTotalInvestment = totalInvestedAmount[msg.sender].add(msg.value);
        require(senderTotalInvestment <= MAX_INVESTMENT);

        uint256 weiAmount = msg.value;
        uint256 excessiveFunds = 0;

        uint256 tokensAmount = weiAmount.mul(exchangeRatePreIco);

        if (tokensAmount > tokensRemainingPreIco) {
            uint256 weiToAccept = tokensRemainingPreIco.div(exchangeRatePreIco);
            excessiveFunds = weiAmount.sub(weiToAccept);

            tokensAmount = tokensRemainingPreIco;
            weiAmount = weiToAccept;
        }

        addPreIcoPurchaseInfo(weiAmount, tokensAmount);

        owner.transfer(weiAmount);

        token.transferFromIco(msg.sender, tokensAmount);

        if (excessiveFunds > 0) {
            msg.sender.transfer(excessiveFunds);
        }
    }

    /**
    * @dev Sell tokens during ICO stage.
    */
    function sellTokensIco() public payable whenWhitelisted(msg.sender) beforeReachingIcoMaxCap whenNotPaused {
        require(isIco());
        require(msg.value >= MIN_INVESTMENT);
        uint256 senderTotalInvestment = totalInvestedAmount[msg.sender].add(msg.value);
        require(senderTotalInvestment <= MAX_INVESTMENT);

        uint256 weiAmount = msg.value;
        uint256 excessiveFunds = 0;

        uint256 tokensAmount = weiAmount.mul(exchangeRateIco());

        if (tokensAmount > tokensRemainingIco) {
            uint256 weiToAccept = tokensRemainingIco.div(exchangeRateIco());
            excessiveFunds = weiAmount.sub(weiToAccept);

            tokensAmount = tokensRemainingIco;
            weiAmount = weiToAccept;
        }

        addIcoPurchaseInfo(weiAmount, tokensAmount);

        owner.transfer(weiAmount);

        token.transferFromIco(msg.sender, tokensAmount);

        if (excessiveFunds > 0) {
            msg.sender.transfer(excessiveFunds);
        }
    }

    /**
    * @dev Manual send tokens to the specified address.
    * @param _address The address of a investor.
    * @param _tokensAmount Amount of tokens.
    */
    function manualSendTokens(address _address, uint256 _tokensAmount) public whenWhitelisted(_address) onlyOwner {
        require(_address != address(0));
        require(_tokensAmount > 0);
        
        if (isPreIco() && _tokensAmount <= tokensRemainingPreIco) {
            token.transferFromIco(_address, _tokensAmount);
            addPreIcoPurchaseInfo(0, _tokensAmount);
        } else if (isIco() && _tokensAmount <= tokensRemainingIco) {
            token.transferFromIco(_address, _tokensAmount);
            addIcoPurchaseInfo(0, _tokensAmount);
        } else {
            revert();
        }
    }

    /**
    * @dev Update the pre-ICO investments statistic.
    * @param _weiAmount The investment received from a pre-ICO investor.
    * @param _tokensAmount The tokens that will be sent to pre-ICO investor.
    */
    function addPreIcoPurchaseInfo(uint256 _weiAmount, uint256 _tokensAmount) internal {
        totalInvestedAmount[msg.sender] = totalInvestedAmount[msg.sender].add(_weiAmount);

        tokensSoldPreIco = tokensSoldPreIco.add(_tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(_tokensAmount);
        tokensRemainingPreIco = tokensRemainingPreIco.sub(_tokensAmount);

        weiRaisedPreIco = weiRaisedPreIco.add(_weiAmount);
        weiRaisedTotal = weiRaisedTotal.add(_weiAmount);
    }

    /**
    * @dev Update the ICO investments statistic.
    * @param _weiAmount The investment received from a ICO investor.
    * @param _tokensAmount The tokens that will be sent to ICO investor.
    */
    function addIcoPurchaseInfo(uint256 _weiAmount, uint256 _tokensAmount) internal {
        totalInvestedAmount[msg.sender] = totalInvestedAmount[msg.sender].add(_weiAmount);

        tokensSoldIco = tokensSoldIco.add(_tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(_tokensAmount);
        tokensRemainingIco = tokensRemainingIco.sub(_tokensAmount);

        weiRaisedIco = weiRaisedIco.add(_weiAmount);
        weiRaisedTotal = weiRaisedTotal.add(_weiAmount);
    }
}
contract Factory {
    VeiagCrowdsale public crowdsale;

    function createCrowdsale (
        uint256 _startTimePreIco,
        uint256 _endTimePreIco,
        uint256 _startTimeIco,
        uint256 _endTimeIco,
        address _lockedWallet,
        address _teamsWallet,
        address _foundersWallet,
        address _marketingWallet
    ) public
    {
        crowdsale = new VeiagCrowdsale(
            _startTimePreIco,
            _endTimePreIco,
            _startTimeIco,
            _endTimeIco,
            _lockedWallet,
            _teamsWallet,
            _foundersWallet,
            _marketingWallet
        );

        Whitelist whitelist = crowdsale.whitelist();
        whitelist.transferOwnership(msg.sender);

        VeiagToken token = crowdsale.token();
        token.transferOwnership(msg.sender);
        crowdsale.transferOwnership(msg.sender);
    }
}