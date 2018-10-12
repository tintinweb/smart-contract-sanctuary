pragma solidity ^0.4.24;

// File: contracts/ZeroExExchangeInterface.sol

contract ZeroExExchangeInterface {

  // Error Codes
  enum Errors {
    ORDER_EXPIRED,                    // Order has already expired
    ORDER_FULLY_FILLED_OR_CANCELLED,  // Order has already been fully filled or cancelled
    ROUNDING_ERROR_TOO_LARGE,         // Rounding error too large
    INSUFFICIENT_BALANCE_OR_ALLOWANCE // Insufficient balance or allowance for token transfer
  }

  address public ZRX_TOKEN_CONTRACT;
  address public TOKEN_TRANSFER_PROXY_CONTRACT;

  /// @dev Fills the input order.
  /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
  /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
  /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
  /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfer will fail before attempting.
  /// @param v ECDSA signature parameter v.
  /// @param r ECDSA signature parameters r.
  /// @param s ECDSA signature parameters s.
  /// @return Total amount of takerToken filled in trade.
  function fillOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint fillTakerTokenAmount,
    bool shouldThrowOnInsufficientBalanceOrAllowance,
    uint8 v,
    bytes32 r,
    bytes32 s)
  public
  returns (uint filledTakerTokenAmount);

  /// @dev Cancels the input order.
  /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
  /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
  /// @param cancelTakerTokenAmount Desired amount of takerToken to cancel in order.
  /// @return Amount of takerToken cancelled.
  function cancelOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint cancelTakerTokenAmount)
  public
  returns (uint);

  /*
  * Wrapper functions
  */

  /// @dev Fills an order with specified parameters and ECDSA signature, throws if specified amount not filled entirely.
  /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
  /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
  /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
  /// @param v ECDSA signature parameter v.
  /// @param r ECDSA signature parameters r.
  /// @param s ECDSA signature parameters s.
  function fillOrKillOrder(
    address[5] orderAddresses,
    uint[6] orderValues,
    uint fillTakerTokenAmount,
    uint8 v,
    bytes32 r,
    bytes32 s)
  public;

  /// @dev Synchronously executes multiple fill orders in a single transaction.
  /// @param orderAddresses Array of address arrays containing individual order addresses.
  /// @param orderValues Array of uint arrays containing individual order values.
  /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
  /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
  /// @param v Array ECDSA signature v parameters.
  /// @param r Array of ECDSA signature r parameters.
  /// @param s Array of ECDSA signature s parameters.
  function batchFillOrders(
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] fillTakerTokenAmounts,
    bool shouldThrowOnInsufficientBalanceOrAllowance,
    uint8[] v,
    bytes32[] r,
    bytes32[] s)
  public;

  /// @dev Synchronously executes multiple fillOrKill orders in a single transaction.
  /// @param orderAddresses Array of address arrays containing individual order addresses.
  /// @param orderValues Array of uint arrays containing individual order values.
  /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
  /// @param v Array ECDSA signature v parameters.
  /// @param r Array of ECDSA signature r parameters.
  /// @param s Array of ECDSA signature s parameters.
  function batchFillOrKillOrders(
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] fillTakerTokenAmounts,
    uint8[] v,
    bytes32[] r,
    bytes32[] s)
  public;

  /// @dev Synchronously executes multiple fill orders in a single transaction until total fillTakerTokenAmount filled.
  /// @param orderAddresses Array of address arrays containing individual order addresses.
  /// @param orderValues Array of uint arrays containing individual order values.
  /// @param fillTakerTokenAmount Desired total amount of takerToken to fill in orders.
  /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
  /// @param v Array ECDSA signature v parameters.
  /// @param r Array of ECDSA signature r parameters.
  /// @param s Array of ECDSA signature s parameters.
  /// @return Total amount of fillTakerTokenAmount filled in orders.
  function fillOrdersUpTo(
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint fillTakerTokenAmount,
    bool shouldThrowOnInsufficientBalanceOrAllowance,
    uint8[] v,
    bytes32[] r,
    bytes32[] s)
  public
  returns (uint);

  /// @dev Synchronously cancels multiple orders in a single transaction.
  /// @param orderAddresses Array of address arrays containing individual order addresses.
  /// @param orderValues Array of uint arrays containing individual order values.
  /// @param cancelTakerTokenAmounts Array of desired amounts of takerToken to cancel in orders.
  function batchCancelOrders(
    address[5][] orderAddresses,
    uint[6][] orderValues,
    uint[] cancelTakerTokenAmounts)
  public;

  /*
  * Constant public functions
  */

  /// @dev Calculates Keccak-256 hash of order with specified parameters.
  /// @param orderAddresses Array of order&#39;s maker, taker, makerToken, takerToken, and feeRecipient.
  /// @param orderValues Array of order&#39;s makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
  /// @return Keccak-256 hash of order.
  function getOrderHash(address[5] orderAddresses, uint[6] orderValues)
  public
  constant
  returns (bytes32);

  /// @dev Verifies that an order signature is valid.
  /// @param signer address of signer.
  /// @param hash Signed Keccak-256 hash.
  /// @param v ECDSA signature parameter v.
  /// @param r ECDSA signature parameters r.
  /// @param s ECDSA signature parameters s.
  /// @return Validity of order signature.
  function isValidSignature(
    address signer,
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s)
  public
  constant
  returns (bool);

  /// @dev Checks if rounding error > 0.1%.
  /// @param numerator Numerator.
  /// @param denominator Denominator.
  /// @param target Value to multiply with numerator/denominator.
  /// @return Rounding error is present.
  function isRoundingError(uint numerator, uint denominator, uint target)
  public
  constant
  returns (bool);

  /// @dev Calculates partial value given a numerator and denominator.
  /// @param numerator Numerator.
  /// @param denominator Denominator.
  /// @param target Value to calculate partial of.
  /// @return Partial value of target.
  function getPartialAmount(uint numerator, uint denominator, uint target)
  public
  constant
  returns (uint);

  /// @dev Calculates the sum of values already filled and cancelled for a given order.
  /// @param orderHash The Keccak-256 hash of the given order.
  /// @return Sum of values already filled and cancelled.
  function getUnavailableTakerTokenAmount(bytes32 orderHash)
  public
  constant
  returns (uint);

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

// File: paradigm-solidity/contracts/SubContract.sol

contract SubContract {
    using SafeMath for uint;

    string public makerArguments;
    string public takerArguments;

    function participate(bytes32[] makerData, bytes32[] takerData) public returns (bool);

    function ratioFor(uint value, uint numerator, uint denominator) internal pure returns (uint) {
        return value.mul(numerator).div(denominator);
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
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/Token.sol

contract Token is StandardToken {

  string public name;
  string public symbol;
  uint8 public decimals = 18;

  constructor(string _name, string _symbol) public {
    balances[msg.sender] = 100000 ether;
    totalSupply_ = 100000 ether;
    name = _name;
    symbol = _symbol;
  }
}

contract Exchange is ZeroExExchangeInterface {}
// File: contracts/ZeroExSubContract.sol

contract ZeroExSubContract is SubContract {

  Exchange public exchange;
  address public zeroExProxy;

  constructor(address _exchange, address _proxy, string _makerArguments, string _takerArguments) public {
    exchange = Exchange(_exchange);
    zeroExProxy = _proxy;
    makerArguments = _makerArguments;
    takerArguments = _takerArguments;
  }

  function participate(bytes32[] makerData, bytes32[] takerData) public returns (bool) {
    address taker = address(takerData[2]);
    Token takerToken = Token(address(makerData[3]));
    Token makerToken = Token(address(makerData[2]));
    uint takerTokenToTrade = uint(takerData[0]);
    uint makerTokenCount = uint(makerData[5]);
    uint takerTokenCount = uint(makerData[6]);

    takerToken.transferFrom(taker, this, takerTokenToTrade);
    takerToken.approve(zeroExProxy, uint(takerData[0]));

    uint takerTokensTransferred = fillOrder(makerData, takerData);
    uint makerTokensToOutput = exchange.getPartialAmount(makerTokenCount, takerTokenCount, takerTokensTransferred);

    if(takerTokensTransferred > 0) {
      return makerToken.transfer(taker, makerTokensToOutput);
    } else {
      return false;
    }
  }

  function fillOrder(bytes32[] makerData, bytes32[] takerData) internal returns (uint) {
    return exchange.fillOrder(
      getAddresses(makerData),
      getNumbers(makerData),
      uint(takerData[0]), uint(takerData[1]) != 0, uint8(makerData[11]), makerData[12], makerData[13]);
  }

  function getAddresses(bytes32[] makerData) internal pure returns (address[5]) {
    address[5] memory addresses;
    addresses[0] = address(makerData[0]);
    addresses[1] = address(makerData[1]);
    addresses[2] = address(makerData[2]);
    addresses[3] = address(makerData[3]);
    addresses[4] = address(makerData[4]);
    return addresses;
  }
  function getNumbers(bytes32[] makerData) internal pure returns (uint[6]) {
    uint[6] memory numbers;

    numbers[0] = uint(makerData[5]);
    numbers[1] = uint(makerData[6]);
    numbers[2] = uint(makerData[7]);
    numbers[3] = uint(makerData[8]);
    numbers[4] = uint(makerData[9]);
    numbers[5] = uint(makerData[10]);

    return numbers;
  }
}