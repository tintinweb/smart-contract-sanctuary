//File: node_modules\openzeppelin-solidity\contracts\ownership\Ownable.sol
pragma solidity ^0.4.24;


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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol
pragma solidity ^0.4.24;


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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol
pragma solidity ^0.4.24;




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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\SafeERC20.sol
pragma solidity ^0.4.24;





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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\TokenTimelock.sol
pragma solidity ^0.4.24;




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

    token.safeTransfer(beneficiary, amount);
  }
}

//File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol
pragma solidity ^0.4.24;


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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\TokenVesting.sol
/* solium-disable security/no-block-members */

pragma solidity ^0.4.24;







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

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20 token which is being vested
   */
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

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

    _token.safeTransfer(owner, refund);

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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\BasicToken.sol
pragma solidity ^0.4.24;






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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\StandardToken.sol
pragma solidity ^0.4.24;





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

//File: contracts\ico\TileToken.sol
/**
* @title TILE Token - LOOMIA
* @author Pactum IO <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9bfffeeddbebfaf8efeef6b5f2f4">[email&#160;protected]</a>>
*/
pragma solidity ^0.4.24;





contract TileToken is StandardToken {
    string public constant NAME = "LOOMIA TILE";
    string public constant SYMBOL = "TILE";
    uint8 public constant DECIMALS = 18;

    uint256 public totalSupply = 109021227 * 1e18; // Supply is 109,021,227 plus the conversion to wei

    constructor() public {
        balances[msg.sender] = totalSupply;
    }
}

//File: contracts\ico\TileDistribution.sol
/**
 * @title TILE Token Distribution - LOOMIA
 * @author Pactum IO <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="583c3d2e1828393b2c2d35763137">[email&#160;protected]</a>>
 */
pragma solidity ^0.4.24;







contract TileDistribution is Ownable {
    using SafeMath for uint256;

    /*** CONSTANTS ***/
    uint256 public constant VESTING_DURATION = 2 * 365 days;
    uint256 public constant VESTING_START_TIME = 1504224000; // Friday, September 1, 2017 12:00:00 AM
    uint256 public constant VESTING_CLIFF = 26 weeks; // 6 month cliff-- 52 weeks/2

    uint256 public constant TIMELOCK_DURATION = 365 days;

    address public constant LOOMIA1_ADDR = 0x1c59Aa1ec35Cfcc222B0e860066796Ccddbe10c8;
    address public constant LOOMIA2_ADDR = 0x4c728E555E647214D834E4eBa37844424C0b7eFD;
    address public constant LOOMIA_LOOMIA_REMAINDER_ADDR = 0x8b91Eaa35E694524274178586aCC7701CC56cd35;
    address public constant BRANDS_ADDR = 0xe4D876bf0b67Bf4547DD6c55559097cC62058726;
    address public constant ADVISORS_ADDR = 0x886E7DE436df0fA4593a8534b798995624DB5837;
    address public constant THIRD_PARTY_LOCKUP_ADDR = 0x03a41aD81834E8831fFc65CdC3F61Cf04A31806E;

    uint256 public constant LOOMIA1 = 3270636.80 * 1e18;
    uint256 public constant LOOMIA2 = 3270636.80 * 1e18;
    uint256 public constant LOOMIA_REMAINDER = 9811910 * 1e18;
    uint256 public constant BRANDS = 10902122.70 * 1e18;
    uint256 public constant ADVISORS = 5451061.35 * 1e18;
    uint256 public constant THIRD_PARTY_LOCKUP = 5451061.35 * 1e18;


    /*** VARIABLES ***/
    ERC20Basic public token; // The token being distributed
    address[3] public tokenVestingAddresses; // address array for easy of access
    address public tokenTimelockAddress;

    /*** EVENTS ***/
    event AirDrop(address indexed _beneficiaryAddress, uint256 _amount);

    /*** MODIFIERS ***/
    modifier validAddressAmount(address _beneficiaryWallet, uint256 _amount) {
        require(_beneficiaryWallet != address(0));
        require(_amount != 0);
        _;
    }

    /**
     * @dev Constructor
     */
    constructor () public {
        token = createTokenContract();
        createVestingContract();
        createTimeLockContract();
    }

    /**
    * @dev fallback function - do not accept payment
    */
    function () external payable {
        revert();
    }

    /*** PUBLIC || EXTERNAL ***/
    /**
     * @dev This function is the batch send function for Token distribution. It accepts an array of addresses and amounts
     * @param _beneficiaryWallets the address where tokens will be deposited into
     * @param _amounts the token amount in wei to send to the associated beneficiary
     */
    function batchDistributeTokens(address[] _beneficiaryWallets, uint256[] _amounts) external onlyOwner {
        require(_beneficiaryWallets.length == _amounts.length);
        for (uint i = 0; i < _beneficiaryWallets.length; i++) {
            distributeTokens(_beneficiaryWallets[i], _amounts[i]);
        }
    }

    /**
     * @dev Single token airdrop function. It is for a single transfer of tokens to beneficiary
     * @param _beneficiaryWallet the address where tokens will be deposited into
     * @param _amount the token amount in wei to send to the associated beneficiary
     */
    function distributeTokens(address _beneficiaryWallet, uint256 _amount) public onlyOwner validAddressAmount(_beneficiaryWallet, _amount) {
        token.transfer(_beneficiaryWallet, _amount);
        emit AirDrop(_beneficiaryWallet, _amount);
    }

    /*** INTERNAL || PRIVATE ***/
    /**
     * @dev Creates the Vesting contracts to secure a percentage of tokens to be redistributed incrementally over time.
     */
    function createVestingContract() private {
        TokenVesting newVault = new TokenVesting(
            LOOMIA1_ADDR, VESTING_START_TIME, VESTING_CLIFF, VESTING_DURATION, false);

        tokenVestingAddresses[0] = address(newVault);
        token.transfer(address(newVault), LOOMIA1);

        TokenVesting newVault2 = new TokenVesting(
            LOOMIA2_ADDR, VESTING_START_TIME, VESTING_CLIFF, VESTING_DURATION, false);

        tokenVestingAddresses[1] = address(newVault2);
        token.transfer(address(newVault2), LOOMIA2);

        TokenVesting newVault3 = new TokenVesting(
            LOOMIA_LOOMIA_REMAINDER_ADDR, VESTING_START_TIME, VESTING_CLIFF, VESTING_DURATION, false);

        tokenVestingAddresses[2] = address(newVault3);
        token.transfer(address(newVault3), LOOMIA_REMAINDER);
    }

     /**
     * @dev Creates the Timelock contract to secure a precentage of tokens for the predefined duration.
     */
    function createTimeLockContract() private {
        TokenTimelock timelock = new TokenTimelock(token, THIRD_PARTY_LOCKUP_ADDR, now.add(TIMELOCK_DURATION));
        tokenTimelockAddress = address(timelock);
        token.transfer(tokenTimelockAddress, THIRD_PARTY_LOCKUP);
    }

    /**
     * Creates the Tile token contract
     * Called by the constructor
     */
    function createTokenContract() private returns (ERC20Basic) {
        return new TileToken();
    }
}