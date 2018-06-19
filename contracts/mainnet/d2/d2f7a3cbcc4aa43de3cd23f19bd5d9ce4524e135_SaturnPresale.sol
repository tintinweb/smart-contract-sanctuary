pragma solidity ^0.4.18;

// SATURN strategic exchange program

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);

  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data);
}

contract ERC223Token is ERC223 {
  using SafeMath for uint;

  mapping(address => uint) balances;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;


  // Function to access name of token .
  function name() constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) returns (bool success) {

    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

contract SaturnPresale is ContractReceiver {
  using SafeMath for uint256;

  bool    public active = false;
  address public tokenAddress;
  uint256 public hardCap;
  uint256 public sold;

  struct Order {
    address owner;
    uint256 amount;
    uint256 lockup;
    bool    claimed;
  }

  mapping(uint256 => Order) private orders;
  uint256 private latestOrderId = 0;
  address private owner;
  address private treasury;

  event Activated(uint256 time);
  event Finished(uint256 time);
  event Purchase(address indexed purchaser, uint256 id, uint256 amount, uint256 purchasedAt, uint256 redeemAt);
  event Claim(address indexed purchaser, uint256 id, uint256 amount);

  function SaturnPresale(address token, address ethRecepient, uint256 presaleHardCap) public {
    tokenAddress  = token;
    owner         = msg.sender;
    treasury      = ethRecepient;
    hardCap       = presaleHardCap;
  }

  function tokenFallback(address /* _from */, uint _value, bytes /* _data */) public {
    // Accept only SATURN ERC223 token
    if (msg.sender != tokenAddress) { revert(); }
    // If the Presale is active do not accept incoming transactions
    if (active) { revert(); }
    // Only accept one transaction of the right amount
    if (_value != hardCap) { revert(); }

    active = true;
    Activated(now);
  }

  function amountOf(uint256 orderId) constant public returns (uint256 amount) {
    return orders[orderId].amount;
  }

  function lockupOf(uint256 orderId) constant public returns (uint256 timestamp) {
    return orders[orderId].lockup;
  }

  function ownerOf(uint256 orderId) constant public returns (address orderOwner) {
    return orders[orderId].owner;
  }

  function isClaimed(uint256 orderId) constant public returns (bool claimed) {
    return orders[orderId].claimed;
  }

  function () external payable {
    revert();
  }

  function shortBuy() public payable {
    // 10% bonus
    uint256 lockup = now + 12 weeks;
    uint256 priceDiv = 1818181818;
    processPurchase(priceDiv, lockup);
  }

  function mediumBuy() public payable {
    // 25% bonus
    uint256 lockup = now + 24 weeks;
    uint256 priceDiv = 1600000000;
    processPurchase(priceDiv, lockup);
  }

  function longBuy() public payable {
    // 50% bonus
    uint256 lockup = now + 52 weeks;
    uint256 priceDiv = 1333333333;
    processPurchase(priceDiv, lockup);
  }

  function processPurchase(uint256 priceDiv, uint256 lockup) private {
    if (!active) { revert(); }
    if (msg.value == 0) { revert(); }
    ++latestOrderId;

    uint256 purchasedAmount = msg.value.div(priceDiv);
    if (purchasedAmount == 0) { revert(); } // not enough ETH sent
    if (purchasedAmount > hardCap - sold) { revert(); } // too much ETH sent

    orders[latestOrderId] = Order(msg.sender, purchasedAmount, lockup, false);
    sold += purchasedAmount;

    treasury.transfer(msg.value);
    Purchase(msg.sender, latestOrderId, purchasedAmount, now, lockup);
  }

  function redeem(uint256 orderId) public {
    if (orderId > latestOrderId) { revert(); }
    Order storage order = orders[orderId];

    // only owner can withdraw
    if (msg.sender != order.owner) { revert(); }
    if (now < order.lockup) { revert(); }
    if (order.claimed) { revert(); }
    order.claimed = true;

    ERC223 token = ERC223(tokenAddress);
    token.transfer(order.owner, order.amount);

    Claim(order.owner, orderId, order.amount);
  }

  function endPresale() public {
    // only the creator of the smart contract
    // can end the crowdsale prematurely
    if (msg.sender != owner) { revert(); }
    // can only stop an active crowdsale
    if (!active) { revert(); }
    _end();
  }

  function _end() private {
    // if there are any tokens remaining - return them to the owner
    if (sold < hardCap) {
      ERC223 token = ERC223(tokenAddress);
      token.transfer(treasury, hardCap.sub(sold));
    }
    active = false;
    Finished(now);
  }
}