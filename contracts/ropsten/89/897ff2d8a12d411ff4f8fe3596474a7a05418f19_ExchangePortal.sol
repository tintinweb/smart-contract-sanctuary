pragma solidity ^0.4.24;


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



contract KyberNetworkInterface {
  function trade(
    ERC20 src,
    uint srcAmount,
    ERC20 dest,
    address destAddress,
    uint maxDestAmount,
    uint minConversionRate,
    address walletId
  )
    public
    payable
    returns(uint);

  function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
    returns (uint expectedRate, uint slippageRate);
}



contract ExchangePortalInterface {

  event Trade(address src, uint256 srcAmount, address dest, uint256 destReceived);
  
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] _additionalArgs
  )
    external
    payable
    returns (uint256);

  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256);
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256);
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
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/*
* The ExchangePortal contract is an implementation of ExchangePortalInterface that allows
* SmartFunds to exchange and calculate their value via KyberNetwork
*/
contract ExchangePortal is ExchangePortalInterface, Ownable {
  using SafeMath for uint256;

  enum ExchangeType { Kyber }

  KyberNetworkInterface public kyber;

  // KyberExchange recognizes ETH by this address
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  mapping (address => bool) disabledTokens;

  event Trade(address trader, address src, uint256 srcAmount, address dest, uint256 destReceived, uint8 exchangeType);

  // Modifier to check that trading this token is not disabled
  modifier tokenEnabled(ERC20 _token) {
    require(!disabledTokens[address(_token)]);
    _;
  }

  /**
  * @dev contructor
  *
  * @param _kyber    Address of Kyber exchange to trade with
  */
  constructor(address _kyber) public {
    kyber = KyberNetworkInterface(address(_kyber));
  }

  /**
  * @dev Facilitates a trade for a SmartFund
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert from (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with
  * @param _additionalArgs    Array of bytes32 additional arguments
  *
  * @return The amount of _destination received from the trade
  */
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] _additionalArgs
  )
    external
    payable
    tokenEnabled(_destination)
    returns (uint256)
  {

    require(_source != _destination);

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    if (_type == uint(ExchangeType.Kyber)) {
      uint256 maxDestinationAmount = uint256(_additionalArgs[0]);
      uint256 minConversionRate = uint256(_additionalArgs[1]);
      address walletId = address(_additionalArgs[2]);

      receivedAmount = _tradeKyber(
        _source,
        _sourceAmount,
        _destination,
        maxDestinationAmount,
        minConversionRate,
        walletId
      );
    } else {
      // unknown exchange type
      revert();
    }

    // Check if Ether was received
    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      _destination.transfer(msg.sender, receivedAmount);
    }

    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS) ? this.balance : _source.balanceOf(this);

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
        (msg.sender).transfer(endAmount);
      } else {
        _source.transfer(msg.sender, endAmount);
      }
    }

    emit Trade(msg.sender, _source, _sourceAmount, _destination, receivedAmount, uint8(_type));

    return receivedAmount;
  }

  /**
  * @dev Facilitates a trade between this contract and KyberExchange
  *
  * @param _source                  ERC20 token to convert from
  * @param _sourceAmount            Amount to convert from (in _source token)
  * @param _destination             ERC20 token to convert to
  * @param _maxDestinationAmount    The maximum amount of _destination to receive in this trade
  * @param _minConversionRate       The minimum conversion rate we&#39;re willing to trade for
  * @param _walletId                Address of the wallet that will receive a cut of the trade
  *
  * @return The amount of _destination received from the trade
  */
  function _tradeKyber(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _maxDestinationAmount,
    uint256 _minConversionRate,
    address _walletId
  )
    public
    returns (uint256)
  {
    uint256 destinationReceived;

    if (_source == ETH_TOKEN_ADDRESS) {
      destinationReceived = kyber.trade.value(_sourceAmount)(
        _source,
        _sourceAmount,
        _destination,
        this,
        _maxDestinationAmount,
        _minConversionRate,
        _walletId
      );
    } else {
      _transferFromSenderAndApproveTo(_source, _sourceAmount, kyber);
      destinationReceived = kyber.trade(
        _source,
        _sourceAmount,
        _destination,
        this,
        _maxDestinationAmount,
        _minConversionRate,
        _walletId
      );
    }

    return destinationReceived;
  }

  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(ERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, this, _sourceAmount));

    _source.approve(_to, _sourceAmount);
  }

  /**
  * @dev Gets the value of a given amount of some token
  *
  * @param _from      Address of token we&#39;re converting from
  * @param _to        Address of token we&#39;re getting the value in
  * @param _amount    The amount of _from
  *
  * @return The value of `_amount` amount of _from in terms of _to
  */
  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256) {
    (uint256 expectedRate, ) = kyber.getExpectedRate(ERC20(_from), ERC20(_to), _amount);
    uint256 value = expectedRate * _amount / (10 ** uint256(DetailedERC20(_from).decimals()));

    return value;
  }

  /**
  * @dev Gets the total value of array of tokens and amounts
  *
  * @param _fromAddresses    Addresses of all the tokens we&#39;re converting from
  * @param _amounts          The amounts of all the tokens
  * @param _to               The token who&#39;s value we&#39;re converting to
  *
  * @return The total value of _fromAddresses and _amounts in terms of _to
  */
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256) {
    uint256 sum = 0;

    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getValue(_fromAddresses[i], _to, _amounts[i]));
    }

    return sum;
  }

  /**
  * @dev Allows the owner to disable/enable the buying of a token
  *
  * @param _token      Token address whos trading permission is to be set
  * @param _enabled    New token permission
  */
  function setToken(address _token, bool _enabled) external onlyOwner {
    disabledTokens[_token] = _enabled;
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}

}