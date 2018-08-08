pragma solidity ^0.4.24;

// File: contracts/libs/ERC223Receiver_Interface.sol

/**
 * @title ERC223-compliant contract interface.
 */
contract ERC223Receiver {
    constructor() internal {}

    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from Token sender address.
     * @param _value Amount of tokens.
     * @param _data Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/libs/ERC223Token.sol

/**
 * @title Implementation of the ERC223 standard token.
 * @dev See https://github.com/Dexaran/ERC223-token-standard
 */
contract ERC223Token is StandardToken {
    using SafeMath for uint;

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    modifier enoughBalance(uint _value) {
        require (_value <= balanceOf(msg.sender));
        _;
    }

     /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data Transaction metadata.
     * @return Success.
     */
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_to != address(0));

        return isContract(_to) ?
            transferToContract(_to, _value, _data) :
            transferToAddress(_to, _value, _data)
        ;
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @return Success.
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty;

        return transfer(_to, _value, empty);
    }

    /**
     * @dev Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
     * @return If the target is a contract.
     */
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;

        assembly {
            // Retrieve the size of the code on target address; this needs assembly
            length := extcodesize(_addr)
        }

        return (length > 0);
    }
    
    /**
     * @dev Helper function that transfers to address.
     * @return Success.
     */
    function transferToAddress(address _to, uint _value, bytes _data) private enoughBalance(_value) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balanceOf(_to).add(_value);

        emit Transfer(msg.sender, _to, _value, _data);

        return true;
    }

    /**
     * @dev Helper function that transfers to contract.
     * @return Success.
     */
    function transferToContract(address _to, uint _value, bytes _data) private enoughBalance(_value) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balanceOf(_to).add(_value);

        ERC223Receiver receiver = ERC223Receiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);

        emit Transfer(msg.sender, _to, _value, _data);

        return true;
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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol

/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

// File: contracts/libs/BaseToken.sol

/**
 * @title Base token contract for oracle.
 */
contract BaseToken is ERC223Token, StandardBurnableToken {
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/ShintakuToken.sol

/**
 * @title Shintaku token contract
 * @dev Burnable ERC223 token with set emission curve.
 */
contract ShintakuToken is BaseToken, Ownable {
    using SafeMath for uint;

    string public constant symbol = "SHN";
    string public constant name = "Shintaku";
    uint8 public constant demicals = 18;

    // Unit of tokens
    uint public constant TOKEN_UNIT = (10 ** uint(demicals));

    // Parameters

    // Number of blocks for each period (100000 = ~2-3 weeks)
    uint public PERIOD_BLOCKS;
    // Number of blocks to lock owner balance (50x = ~2 years)
    uint public OWNER_LOCK_BLOCKS;
    // Number of blocks to lock user remaining balances (25x = ~1 year)
    uint public USER_LOCK_BLOCKS;
    // Number of tokens per period during tail emission
    uint public constant TAIL_EMISSION = 400 * (10 ** 3) * TOKEN_UNIT;
    // Number of tokens to emit initially: tail emission is 4% of this
    uint public constant INITIAL_EMISSION_FACTOR = 25;
    // Absolute cap on funds received per period
    // Note: this should be obscenely large to prevent larger ether holders
    //  from monopolizing tokens at low cost. This cap should never be hit in
    //  practice.
    uint public constant MAX_RECEIVED_PER_PERIOD = 10000 ether;

    /**
     * @dev Store relevant data for a period.
     */
    struct Period {
        // Block this period has started at
        uint started;

        // Total funds received this period
        uint totalReceived;
        // Locked owner balance, will unlock after a long time
        uint ownerLockedBalance;
        // Number of tokens to mint this period
        uint minting;

        // Sealed purchases for each account
        mapping (address => bytes32) sealedPurchaseOrders;
        // Balance received from each account
        mapping (address => uint) receivedBalances;
        // Locked balance for each account
        mapping (address => uint) lockedBalances;

        // When withdrawing, withdraw to an alias address (e.g. cold storage)
        mapping (address => address) aliases;
    }

    // Modifiers

    modifier validPeriod(uint _period) {
        require(_period <= currentPeriodIndex());
        _;
    }

    // Contract state

    // List of periods
    Period[] internal periods;

    // Address the owner can withdraw funds to (e.g. cold storage)
    address public ownerAlias;

    // Events

    event NextPeriod(uint indexed _period, uint indexed _block);
    event SealedOrderPlaced(address indexed _from, uint indexed _period, uint _value);
    event SealedOrderRevealed(address indexed _from, uint indexed _period, address indexed _alias, uint _value);
    event OpenOrderPlaced(address indexed _from, uint indexed _period, address indexed _alias, uint _value);
    event Claimed(address indexed _from, uint indexed _period, address indexed _alias, uint _value);

    // Functions

    constructor(address _alias, uint _periodBlocks, uint _ownerLockFactor, uint _userLockFactor) public {
        require(_alias != address(0));
        require(_periodBlocks >= 2);
        require(_ownerLockFactor > 0);
        require(_userLockFactor > 0);

        periods.push(Period(block.number, 0, 0, calculateMinting(0)));
        ownerAlias = _alias;

        PERIOD_BLOCKS = _periodBlocks;
        OWNER_LOCK_BLOCKS = _periodBlocks.mul(_ownerLockFactor);
        USER_LOCK_BLOCKS = _periodBlocks.mul(_userLockFactor);
    }

    /**
     * @dev Go to the next period, if sufficient time has passed.
     */
    function nextPeriod() public {
        uint periodIndex = currentPeriodIndex();
        uint periodIndexNext = periodIndex.add(1);
        require(block.number.sub(periods[periodIndex].started) > PERIOD_BLOCKS);

        periods.push(Period(block.number, 0, 0, calculateMinting(periodIndexNext)));

        emit NextPeriod(periodIndexNext, block.number);
    }

    /**
     * @dev Creates a sealed purchase order.
     * @param _from Account that will purchase tokens.
     * @param _period Period of purchase order.
     * @param _value Purchase funds, in wei.
     * @param _salt Random value to keep purchase secret.
     * @return The sealed purchase order.
     */
    function createPurchaseOrder(address _from, uint _period, uint _value, bytes32 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_from, _period, _value, _salt));
    }

    /**
     * @dev Submit a sealed purchase order. Wei sent can be different then sealed value.
     * @param _sealedPurchaseOrder The sealed purchase order.
     */
    function placePurchaseOrder(bytes32 _sealedPurchaseOrder) public payable {
        if (block.number.sub(periods[currentPeriodIndex()].started) > PERIOD_BLOCKS) {
            nextPeriod();
        }
        // Note: current period index may update from above call
        Period storage period = periods[currentPeriodIndex()];
        // Each address can only make a single purchase per period
        require(period.sealedPurchaseOrders[msg.sender] == bytes32(0));

        period.sealedPurchaseOrders[msg.sender] = _sealedPurchaseOrder;
        period.receivedBalances[msg.sender] = msg.value;

        emit SealedOrderPlaced(msg.sender, currentPeriodIndex(), msg.value);
    }

    /**
     * @dev Reveal a sealed purchase order and commit to a purchase.
     * @param _sealedPurchaseOrder The sealed purchase order.
     * @param _period Period of purchase order.
     * @param _value Purchase funds, in wei.
     * @param _period Period for which to reveal purchase order.
     * @param _salt Random value to keep purchase secret.
     * @param _alias Address to withdraw tokens and excess funds to.
     */
    function revealPurchaseOrder(bytes32 _sealedPurchaseOrder, uint _period, uint _value, bytes32 _salt, address _alias) public {
        // Sanity check to make sure user enters an alias
        require(_alias != address(0));
        // Can only reveal sealed orders in the next period
        require(currentPeriodIndex() == _period.add(1));
        Period storage period = periods[_period];
        // Each address can only make a single purchase per period
        require(period.aliases[msg.sender] == address(0));

        // Note: don&#39;t *need* to advance period here

        bytes32 h = createPurchaseOrder(msg.sender, _period, _value, _salt);
        require(h == _sealedPurchaseOrder);

        // The value revealed must not be greater than the value previously sent
        require(_value <= period.receivedBalances[msg.sender]);

        period.totalReceived = period.totalReceived.add(_value);
        uint remainder = period.receivedBalances[msg.sender].sub(_value);
        period.receivedBalances[msg.sender] = _value;
        period.aliases[msg.sender] = _alias;

        emit SealedOrderRevealed(msg.sender, _period, _alias, _value);

        // Return any extra balance to the alias
        _alias.transfer(remainder);
    }

    /**
     * @dev Place an unsealed purchase order immediately.
     * @param _alias Address to withdraw tokens to.
     */
    function placeOpenPurchaseOrder(address _alias) public payable {
        // Sanity check to make sure user enters an alias
        require(_alias != address(0));

        if (block.number.sub(periods[currentPeriodIndex()].started) > PERIOD_BLOCKS) {
            nextPeriod();
        }
        // Note: current period index may update from above call
        Period storage period = periods[currentPeriodIndex()];
        // Each address can only make a single purchase per period
        require(period.aliases[msg.sender] == address(0));

        period.totalReceived = period.totalReceived.add(msg.value);
        period.receivedBalances[msg.sender] = msg.value;
        period.aliases[msg.sender] = _alias;

        emit OpenOrderPlaced(msg.sender, currentPeriodIndex(), _alias, msg.value);
    }

    /**
     * @dev Claim previously purchased tokens for an account.
     * @param _from Account to claim tokens for.
     * @param _period Period for which to claim tokens.
     */
    function claim(address _from, uint _period) public {
        // Claiming can only be done at least two periods after submitting sealed purchase order
        require(currentPeriodIndex() > _period.add(1));
        Period storage period = periods[_period];
        require(period.receivedBalances[_from] > 0);

        uint value = period.receivedBalances[_from];
        delete period.receivedBalances[_from];

        (uint emission, uint spent) = calculateEmission(_period, value);
        uint remainder = value.sub(spent);

        address alias = period.aliases[_from];
        // Mint tokens based on spent funds
        mint(alias, emission);

        // Lock up remaining funds for account
        period.lockedBalances[_from] = period.lockedBalances[_from].add(remainder);
        // Lock up spent funds for owner
        period.ownerLockedBalance = period.ownerLockedBalance.add(spent);

        emit Claimed(_from, _period, alias, emission);
    }

    /*
     * @dev Users can withdraw locked balances after the lock time has expired, for an account.
     * @param _from Account to withdraw balance for.
     * @param _period Period to withdraw funds for.
     */
    function withdraw(address _from, uint _period) public {
        require(currentPeriodIndex() > _period);
        Period storage period = periods[_period];
        require(block.number.sub(period.started) > USER_LOCK_BLOCKS);

        uint balance = period.lockedBalances[_from];
        require(balance <= address(this).balance);
        delete period.lockedBalances[_from];

        address alias = period.aliases[_from];
        // Don&#39;t delete this, as a user may have unclaimed tokens
        //delete period.aliases[_from];
        alias.transfer(balance);
    }

    /**
     * @dev Contract owner can withdraw unlocked owner funds.
     * @param _period Period to withdraw funds for.
     */
    function withdrawOwner(uint _period) public onlyOwner {
        require(currentPeriodIndex() > _period);
        Period storage period = periods[_period];
        require(block.number.sub(period.started) > OWNER_LOCK_BLOCKS);

        uint balance = period.ownerLockedBalance;
        require(balance <= address(this).balance);
        delete period.ownerLockedBalance;

        ownerAlias.transfer(balance);
    }

    /**
     * @dev The owner can withdraw any unrevealed balances after the deadline.
     * @param _period Period to withdraw funds for.
     * @param _from Account to withdraw unrevealed funds against.
     */
    function withdrawOwnerUnrevealed(uint _period, address _from) public onlyOwner {
        // Must be past the reveal deadline of one period
        require(currentPeriodIndex() > _period.add(1));
        Period storage period = periods[_period];
        require(block.number.sub(period.started) > OWNER_LOCK_BLOCKS);

        uint balance = period.receivedBalances[_from];
        require(balance <= address(this).balance);
        delete period.receivedBalances[_from];

        ownerAlias.transfer(balance);
    }

    /**
     * @dev Calculate the number of tokens to mint during a period.
     * @param _period The period.
     * @return Number of tokens to mint.
     */
    function calculateMinting(uint _period) internal pure returns (uint) {
        // Every period, decrease emission by 5% of initial, until tail emission
        return
            _period < INITIAL_EMISSION_FACTOR ?
            TAIL_EMISSION.mul(INITIAL_EMISSION_FACTOR.sub(_period)) :
            TAIL_EMISSION
        ;
    }

    /**
     * @dev Helper function to get current period index.
     * @return The array index of the current period.
     */
    function currentPeriodIndex() public view returns (uint) {
        assert(periods.length > 0);

        return periods.length.sub(1);
    }

    /**
     * @dev Calculate token emission.
     * @param _period Period for which to calculate emission.
     * @param _value Amount paid. Emissions is proportional to this.
     * @return Number of tokens to emit.
     * @return The spent balance.
     */
    function calculateEmission(uint _period, uint _value) internal view returns (uint, uint) {
        Period storage currentPeriod = periods[_period];
        uint minting = currentPeriod.minting;
        uint totalReceived = currentPeriod.totalReceived;

        uint scaledValue = _value;
        if (totalReceived > MAX_RECEIVED_PER_PERIOD) {
            // If the funds received this period exceed the maximum, scale
            // emission to refund remaining
            scaledValue = _value.mul(MAX_RECEIVED_PER_PERIOD).div(totalReceived);
        }

        uint emission = scaledValue.mul(minting).div(MAX_RECEIVED_PER_PERIOD);
        return (emission, scaledValue);
    }

    /**
     * @dev Mints new tokens.
     * @param _account Account that will receive new tokens.
     * @param _value Number of tokens to mint.
     */
    function mint(address _account, uint _value) internal {
        balances[_account] = balances[_account].add(_value);
        totalSupply_ = totalSupply_.add(_value);
    }

    // Getters

    function getPeriodStarted(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].started;
    }

    function getPeriodTotalReceived(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].totalReceived;
    }

    function getPeriodOwnerLockedBalance(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].ownerLockedBalance;
    }

    function getPeriodMinting(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].minting;
    }

    function getPeriodSealedPurchaseOrderFor(uint _period, address _account) public view validPeriod(_period) returns (bytes32) {
        return periods[_period].sealedPurchaseOrders[_account];
    }

    function getPeriodReceivedBalanceFor(uint _period, address _account) public view validPeriod(_period) returns (uint) {
        return periods[_period].receivedBalances[_account];
    }

    function getPeriodLockedBalanceFor(uint _period, address _account) public view validPeriod(_period) returns (uint) {
        return periods[_period].lockedBalances[_account];
    }

    function getPeriodAliasFor(uint _period, address _account) public view validPeriod(_period) returns (address) {
        return periods[_period].aliases[_account];
    }
}