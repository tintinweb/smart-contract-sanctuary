pragma solidity ^0.4.23;

// File: contracts/NokuPricingPlan.sol

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
contract NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/NokuCustomToken.sol

contract NokuCustomToken is Ownable {

    event LogBurnFinished();
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers for using Noku services
    NokuPricingPlan public pricingPlan;

    // The entity acting as Custom Token service provider i.e. Noku
    address public serviceProvider;

    // Flag indicating if Custom Token burning has been permanently finished or not.
    bool public burningFinished;

    /**
    * @dev Modifier to make a function callable only by service provider i.e. Noku.
    */
    modifier onlyServiceProvider() {
        require(msg.sender == serviceProvider, "caller is not service provider");
        _;
    }

    modifier canBurn() {
        require(!burningFinished, "burning finished");
        _;
    }

    constructor(address _pricingPlan, address _serviceProvider) internal {
        require(_pricingPlan != 0, "_pricingPlan is zero");
        require(_serviceProvider != 0, "_serviceProvider is zero");

        pricingPlan = NokuPricingPlan(_pricingPlan);
        serviceProvider = _serviceProvider;
    }

    /**
    * @dev Presence of this function indicates the contract is a Custom Token.
    */
    function isCustomToken() public pure returns(bool isCustom) {
        return true;
    }

    /**
    * @dev Stop burning new tokens.
    * @return true if the operation was successful.
    */
    function finishBurning() public onlyOwner canBurn returns(bool finished) {
        burningFinished = true;

        emit LogBurnFinished();

        return true;
    }

    /**
    * @dev Change the pricing plan of service fee to be paid in NOKU tokens.
    * @param _pricingPlan The pricing plan of NOKU token to be paid, zero means flat subscription.
    */
    function setPricingPlan(address _pricingPlan) public onlyServiceProvider {
        require(_pricingPlan != 0, "_pricingPlan is 0");
        require(_pricingPlan != address(pricingPlan), "_pricingPlan == pricingPlan");

        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/NokuTokenBurner.sol

contract BurnableERC20 is ERC20 {
    function burn(uint256 amount) public returns (bool burned);
}

/**
* @dev The NokuTokenBurner contract has the responsibility to burn the configured fraction of received
* ERC20-compliant tokens and distribute the remainder to the configured wallet.
*/
contract NokuTokenBurner is Pausable {
    using SafeMath for uint256;

    event LogNokuTokenBurnerCreated(address indexed caller, address indexed wallet);
    event LogBurningPercentageChanged(address indexed caller, uint256 indexed burningPercentage);

    // The wallet receiving the unburnt tokens.
    address public wallet;

    // The percentage of tokens to burn after being received (range [0, 100])
    uint256 public burningPercentage;

    // The cumulative amount of burnt tokens.
    uint256 public burnedTokens;

    // The cumulative amount of tokens transferred back to the wallet.
    uint256 public transferredTokens;

    /**
    * @dev Create a new NokuTokenBurner with predefined burning fraction.
    * @param _wallet The wallet receiving the unburnt tokens.
    */
    constructor(address _wallet) public {
        require(_wallet != address(0), "_wallet is zero");
        
        wallet = _wallet;
        burningPercentage = 100;

        emit LogNokuTokenBurnerCreated(msg.sender, _wallet);
    }

    /**
    * @dev Change the percentage of tokens to burn after being received.
    * @param _burningPercentage The percentage of tokens to be burnt.
    */
    function setBurningPercentage(uint256 _burningPercentage) public onlyOwner {
        require(0 <= _burningPercentage && _burningPercentage <= 100, "_burningPercentage not in [0, 100]");
        require(_burningPercentage != burningPercentage, "_burningPercentage equal to current one");
        
        burningPercentage = _burningPercentage;

        emit LogBurningPercentageChanged(msg.sender, _burningPercentage);
    }

    /**
    * @dev Called after burnable tokens has been transferred for burning.
    * @param _token THe extended ERC20 interface supported by the sent tokens.
    * @param _amount The amount of burnable tokens just arrived ready for burning.
    */
    function tokenReceived(address _token, uint256 _amount) public whenNotPaused {
        require(_token != address(0), "_token is zero");
        require(_amount > 0, "_amount is zero");

        uint256 amountToBurn = _amount.mul(burningPercentage).div(100);
        if (amountToBurn > 0) {
            assert(BurnableERC20(_token).burn(amountToBurn));
            
            burnedTokens = burnedTokens.add(amountToBurn);
        }

        uint256 amountToTransfer = _amount.sub(amountToBurn);
        if (amountToTransfer > 0) {
            assert(BurnableERC20(_token).transfer(wallet, amountToTransfer));

            transferredTokens = transferredTokens.add(amountToTransfer);
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol

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

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
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

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol

/* solium-disable security/no-block-members */

pragma solidity ^0.4.21;






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
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(
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
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

// File: contracts/NokuCustomERC20.sol

/**
* @dev The NokuCustomERC20Token contract is a custom ERC20-compliant token available in the Noku Service Platform (NSP).
* The Noku customer is able to choose the token name, symbol, decimals, initial supply and to administer its lifecycle
* by minting or burning tokens in order to increase or decrease the token supply.
*/
contract NokuCustomERC20 is NokuCustomToken, DetailedERC20, MintableToken, BurnableToken {
    using SafeMath for uint256;

    event LogNokuCustomERC20Created(
        address indexed caller,
        string indexed name,
        string indexed symbol,
        uint8 decimals,
        uint256 transferableFromBlock,
        uint256 lockEndBlock,
        address pricingPlan,
        address serviceProvider
    );
    event LogMintingFeeEnabledChanged(address indexed caller, bool indexed mintingFeeEnabled);
    event LogInformationChanged(address indexed caller, string name, string symbol);
    event LogTransferFeePaymentFinished(address indexed caller);
    event LogTransferFeePercentageChanged(address indexed caller, uint256 indexed transferFeePercentage);

    // Flag indicating if minting fees are enabled or disabled
    bool public mintingFeeEnabled;

    // Block number from which tokens are initially transferable
    uint256 public transferableFromBlock;

    // Block number from which initial lock ends
    uint256 public lockEndBlock;

    // The initially locked balances by address
    mapping (address => uint256) public initiallyLockedBalanceOf;

    // The fee percentage for Custom Token transfer or zero if transfer is free of charge
    uint256 public transferFeePercentage;

    // Flag indicating if fee payment in Custom Token transfer has been permanently finished or not. 
    bool public transferFeePaymentFinished;

    bytes32 public constant BURN_SERVICE_NAME = "NokuCustomERC20.burn";
    bytes32 public constant MINT_SERVICE_NAME = "NokuCustomERC20.mint";

    modifier canTransfer(address _from, uint _value) {
        require(block.number >= transferableFromBlock, "token not transferable");

        if (block.number < lockEndBlock) {
            uint256 locked = lockedBalanceOf(_from);
            if (locked > 0) {
                uint256 newBalance = balanceOf(_from).sub(_value);
                require(newBalance >= locked, "_value exceeds locked amount");
            }
        }
        _;
    }

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _transferableFromBlock,
        uint256 _lockEndBlock,
        address _pricingPlan,
        address _serviceProvider
    )
    NokuCustomToken(_pricingPlan, _serviceProvider)
    DetailedERC20(_name, _symbol, _decimals) public
    {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");
        require(_lockEndBlock >= _transferableFromBlock, "_lockEndBlock lower than _transferableFromBlock");

        transferableFromBlock = _transferableFromBlock;
        lockEndBlock = _lockEndBlock;
        mintingFeeEnabled = true;

        emit LogNokuCustomERC20Created(
            msg.sender,
            _name,
            _symbol,
            _decimals,
            _transferableFromBlock,
            _lockEndBlock,
            _pricingPlan,
            _serviceProvider
        );
    }

    function setMintingFeeEnabled(bool _mintingFeeEnabled) public onlyOwner returns(bool successful) {
        require(_mintingFeeEnabled != mintingFeeEnabled, "_mintingFeeEnabled == mintingFeeEnabled");

        mintingFeeEnabled = _mintingFeeEnabled;

        emit LogMintingFeeEnabledChanged(msg.sender, _mintingFeeEnabled);

        return true;
    }

    /**
    * @dev Change the Custom Token detailed information after creation.
    * @param _name The name to assign to the Custom Token.
    * @param _symbol The symbol to assign to the Custom Token.
    */
    function setInformation(string _name, string _symbol) public onlyOwner returns(bool successful) {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");

        name = _name;
        symbol = _symbol;

        emit LogInformationChanged(msg.sender, _name, _symbol);

        return true;
    }

    /**
    * @dev Stop trasfer fee payment for tokens.
    * @return true if the operation was successful.
    */
    function finishTransferFeePayment() public onlyOwner returns(bool finished) {
        require(!transferFeePaymentFinished, "transfer fee finished");

        transferFeePaymentFinished = true;

        emit LogTransferFeePaymentFinished(msg.sender);

        return true;
    }

    /**
    * @dev Change the transfer fee percentage to be paid in Custom tokens.
    * @param _transferFeePercentage The fee percentage to be paid for transfer in range [0, 100].
    */
    function setTransferFeePercentage(uint256 _transferFeePercentage) public onlyOwner {
        require(0 <= _transferFeePercentage && _transferFeePercentage <= 100, "_transferFeePercentage not in [0, 100]");
        require(_transferFeePercentage != transferFeePercentage, "_transferFeePercentage equal to current value");

        transferFeePercentage = _transferFeePercentage;

        emit LogTransferFeePercentageChanged(msg.sender, _transferFeePercentage);
    }

    function lockedBalanceOf(address _to) public constant returns(uint256 locked) {
        uint256 initiallyLocked = initiallyLockedBalanceOf[_to];
        if (block.number >= lockEndBlock) return 0;
        else if (block.number <= transferableFromBlock) return initiallyLocked;

        uint256 releaseForBlock = initiallyLocked.div(lockEndBlock.sub(transferableFromBlock));
        uint256 released = block.number.sub(transferableFromBlock).mul(releaseForBlock);
        return initiallyLocked.sub(released);
    }

    /**
    * @dev Get the fee to be paid for the transfer of NOKU tokens.
    * @param _value The amount of NOKU tokens to be transferred.
    */
    function transferFee(uint256 _value) public view returns(uint256 usageFee) {
        return _value.mul(transferFeePercentage).div(100);
    }

    /**
    * @dev Check if token transfer is free of any charge or not.
    * @return true if transfer is free of any charge.
    */
    function freeTransfer() public view returns (bool isTransferFree) {
        return transferFeePaymentFinished || transferFeePercentage == 0;
    }

    /**
    * @dev Override #transfer for optionally paying fee to Custom token owner.
    */
    function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns(bool transferred) {
        if (freeTransfer()) {
            return super.transfer(_to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transfer(owner, usageFee);
            bool netValueTransferred = super.transfer(_to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

    /**
    * @dev Override #transferFrom for optionally paying fee to Custom token owner.
    */
    function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns(bool transferred) {
        if (freeTransfer()) {
            return super.transferFrom(_from, _to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transferFrom(_from, owner, usageFee);
            bool netValueTransferred = super.transferFrom(_from, _to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

    /**
    * @dev Burn a specific amount of tokens, paying the service fee.
    * @param _amount The amount of token to be burned.
    */
    function burn(uint256 _amount) public canBurn {
        require(_amount > 0, "_amount is zero");

        super.burn(_amount);

        require(pricingPlan.payFee(BURN_SERVICE_NAME, _amount, msg.sender), "burn fee failed");
    }

    /**
    * @dev Mint a specific amount of tokens, paying the service fee.
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns(bool minted) {
        require(_to != 0, "_to is zero");
        require(_amount > 0, "_amount is zero");

        super.mint(_to, _amount);

        if (mintingFeeEnabled) {
            require(pricingPlan.payFee(MINT_SERVICE_NAME, _amount, msg.sender), "mint fee failed");
        }

        return true;
    }

    /**
    * @dev Mint new locked tokens, which will unlock progressively.
    * @param _to The address that will receieve the minted locked tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mintLocked(address _to, uint256 _amount) public onlyOwner canMint returns(bool minted) {
        initiallyLockedBalanceOf[_to] = initiallyLockedBalanceOf[_to].add(_amount);
        
        return mint(_to, _amount);
    }

    /**
     * @dev Mint timelocked tokens.
     * @param _to The address that will receieve the minted locked tokens.
     * @param _amount The amount of tokens to mint.
     * @param _releaseTime The token release time as timestamp from Unix epoch.
     * @return A boolean that indicates if the operation was successful.
     */
    /*function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime) public onlyOwner canMint
    returns (TokenTimelock tokenTimelock)
    {
        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        mint(timelock, _amount);

        return timelock;
    }*/

    /**
    * @dev Mint vested tokens.
    * @param _to The address that will receieve the minted vested tokens.
    * @param _amount The amount of tokens to mint.
    * @param _startTime When the vesting starts as timestamp in seconds from Unix epoch.
    * @param _duration The duration in seconds of the period in which the tokens will vest.
    * @return A boolean that indicates if the operation was successful.
    */
    /*function mintVested(address _to, uint256 _amount, uint256 _startTime, uint256 _duration) public onlyOwner canMint
    returns (TokenVesting tokenVesting)
    {
        TokenVesting vesting = new TokenVesting(_to, _startTime, 0, _duration, true);
        mint(vesting, _amount);

        return vesting;
    }*/

    /**
     * @dev Release vested tokens to beneficiary.
     * @param _vesting The token vesting to release.
     */
    /*function releaseVested(TokenVesting _vesting) public {
        require(_vesting != address(0));

        _vesting.release(this);
    }*/

    /**
     * @dev Revoke vested tokens. Just the token can revoke because it is the vesting owner.
     * @param _vesting The token vesting to revoke.
     */
    /*function revokeVested(TokenVesting _vesting) public onlyOwner {
        require(_vesting != address(0));

        _vesting.revoke(this);
    }*/
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/NokuCustomService.sol

contract NokuCustomService is Pausable {
    using AddressUtils for address;

    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers
    NokuPricingPlan public pricingPlan;

    constructor(address _pricingPlan) internal {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");

        pricingPlan = NokuPricingPlan(_pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");
        require(NokuPricingPlan(_pricingPlan) != pricingPlan, "_pricingPlan equal to current");
        
        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: contracts/NokuCustomERC20Service.sol

/**
* @dev The NokuCustomERC2Service contract .
*/
contract NokuCustomERC20Service is NokuCustomService {
    event LogNokuCustomERC20ServiceCreated(address caller, address indexed pricingPlan);

    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    uint8 public constant DECIMALS = 18;

    bytes32 public constant CUSTOM_ERC20_CREATE_SERVICE_NAME = "NokuCustomERC20.create";

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomERC20ServiceCreated(msg.sender, _pricingPlan);
    }

    // TODO: REMOVE
    function createCustomToken(string _name, string _symbol, uint8 /*_decimals*/) public returns(NokuCustomERC20 customToken) {
        customToken = new NokuCustomERC20(
            _name,
            _symbol,
            DECIMALS,
            block.number,
            block.number,
            pricingPlan,
            owner
        );

        // Transfer NokuCustomERC20 ownership to the client
        customToken.transferOwnership(msg.sender);

        require(pricingPlan.payFee(CUSTOM_ERC20_CREATE_SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }

    function createCustomToken(
        string _name,
        string _symbol,
        uint8 /*_decimals*/,
        uint256 transferableFromBlock,
        uint256 lockEndBlock
    )
    public returns(NokuCustomERC20 customToken)
    {
        customToken = new NokuCustomERC20(
            _name,
            _symbol,
            DECIMALS,
            transferableFromBlock,
            lockEndBlock,
            pricingPlan,
            owner
        );

        // Transfer NokuCustomERC20 ownership to the client
        customToken.transferOwnership(msg.sender);

        require(pricingPlan.payFee(CUSTOM_ERC20_CREATE_SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}