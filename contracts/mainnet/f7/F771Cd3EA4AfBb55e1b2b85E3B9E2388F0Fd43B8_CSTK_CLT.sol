pragma solidity ^0.4.24;

contract Owned {
  address public owner;

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner returns (address account) {
    owner = newOwner;
    return owner;
  }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ERC20 {
  function totalSupply() public constant returns (uint256);
  function balanceOf(address tokenOwner) public constant returns (uint256 balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract CSTKDropToken is ERC20, Owned {
  using SafeMath for uint256;

  string public symbol;
  string public  name;
  uint256 public decimals;
  uint256 _totalSupply;

  bool public started;

  address public token;

  struct Level {
    uint256 price;
    uint256 available;
  }

  Level[] levels;

  mapping(address => uint256) balances;
  mapping(address => mapping(string => uint256)) orders;

  event TransferETH(address indexed from, address indexed to, uint256 eth);
  event Sell(address indexed to, uint256 tokens, uint256 eth);

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor(string _symbol, string _name, uint256 _supply, uint256 _decimals, address _token) public {
    symbol = _symbol;
    name = _name;
    decimals = _decimals;
    token = _token;
    _totalSupply = _supply;
    balances[owner] = _totalSupply;
    started = false;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function destruct() public onlyOwner {
    ERC20 tokenInstance = ERC20(token);

    uint256 balance = tokenInstance.balanceOf(this);

    if (balance > 0) {
      tokenInstance.transfer(owner, balance);
    }

    selfdestruct(owner);
  }

  // ------------------------------------------------------------------------
  // Changes the address of the supported token
  // ------------------------------------------------------------------------
  function setToken(address newTokenAddress) public onlyOwner returns (bool success) {
    token = newTokenAddress;
    return true;
  }

  // ------------------------------------------------------------------------
  // Total supply
  // ------------------------------------------------------------------------
  function totalSupply() public view returns (uint256) {
    return _totalSupply.sub(balances[address(0)]);
  }

  // ------------------------------------------------------------------------
  // Changes the total supply value
  //
  // a new supply must be no less then the current supply
  // or the owner must have enough amount to cover supply reduction
  // ------------------------------------------------------------------------
  function changeTotalSupply(uint256 newSupply) public onlyOwner returns (bool success) {
    require(newSupply >= 0 && (
      newSupply >= _totalSupply || _totalSupply - newSupply <= balances[owner]
    ));
    uint256 diff = 0;
    if (newSupply >= _totalSupply) {
      diff = newSupply.sub(_totalSupply);
      balances[owner] = balances[owner].add(diff);
      emit Transfer(address(0), owner, diff);
    } else {
      diff = _totalSupply.sub(newSupply);
      balances[owner] = balances[owner].sub(diff);
      emit Transfer(owner, address(0), diff);
    }
    _totalSupply = newSupply;
    return true;
  }

  // ------------------------------------------------------------------------
  // Get the token balance for account `tokenOwner`
  // ------------------------------------------------------------------------
  function balanceOf(address tokenOwner) public view returns (uint256 balance) {
    return balances[tokenOwner];
  }

  // ------------------------------------------------------------------------
  // Start accept orders
  // ------------------------------------------------------------------------
  function start() public onlyOwner {
    started = true;
  }

  // ------------------------------------------------------------------------
  // Start accept orders
  // ------------------------------------------------------------------------
  function stop() public onlyOwner {
    started = false;
  }

  // ------------------------------------------------------------------------
  // Adds new Level to the levels array
  // ------------------------------------------------------------------------
  function addLevel(uint256 price, uint256 available) public onlyOwner {
    levels.push(Level(price, available));
  }

  // ------------------------------------------------------------------------
  // Removes a level with specified price from the levels array
  // ------------------------------------------------------------------------
  function removeLevel(uint256 price) public onlyOwner {
    if (levels.length < 1) {
      return;
    }

    Level[] memory tmp = levels;

    delete levels;

    for (uint i = 0; i < tmp.length; i++) {
      if (tmp[i].price != price) {
        levels.push(tmp[i]);
      }
    }
  }

  // ------------------------------------------------------------------------
  // Replaces a particular level index by a new Level values
  // ------------------------------------------------------------------------
  function replaceLevel(uint index, uint256 price, uint256 available) public onlyOwner {
    levels[index] = Level(price, available);
  }

  // ------------------------------------------------------------------------
  // Clears the levels array
  // ------------------------------------------------------------------------
  function clearLevels() public onlyOwner {
    delete levels;
  }

  // ------------------------------------------------------------------------
  // Finds a level with specified price and returns an amount of available tokens on the level
  // ------------------------------------------------------------------------
  function getLevelAmount(uint256 price) public view returns (uint256 available) {
    if (levels.length < 1) {
      return 0;
    }

    for (uint i = 0; i < levels.length; i++) {
      if (levels[i].price == price) {
        return levels[i].available;
      }
    }
  }

  // ------------------------------------------------------------------------
  // Returns a Level by it&#39;s array index
  // ------------------------------------------------------------------------
  function getLevelByIndex(uint index) public view returns (uint256 price, uint256 available) {
    price = levels[index].price;
    available = levels[index].available;
  }

  // ------------------------------------------------------------------------
  // Returns a count of levels
  // ------------------------------------------------------------------------
  function getLevelsCount() public view returns (uint) {
    return levels.length;
  }

  // ------------------------------------------------------------------------
  // Returns a Level by it&#39;s array index
  // ------------------------------------------------------------------------
  function getCurrentLevel() public view returns (uint256 price, uint256 available) {
    if (levels.length < 1) {
      return;
    }

    for (uint i = 0; i < levels.length; i++) {
      if (levels[i].available > 0) {
        price = levels[i].price;
        available = levels[i].available;
        break;
      }
    }
  }

  // ------------------------------------------------------------------------
  // Get the order&#39;s balance of tokens for account `customer`
  // ------------------------------------------------------------------------
  function orderTokensOf(address customer) public view returns (uint256 balance) {
    return orders[customer][&#39;tokens&#39;];
  }

  // ------------------------------------------------------------------------
  // Get the order&#39;s balance of ETH for account `customer`
  // ------------------------------------------------------------------------
  function orderEthOf(address customer) public view returns (uint256 balance) {
    return orders[customer][&#39;eth&#39;];
  }

  // ------------------------------------------------------------------------
  // Delete customer&#39;s order
  // ------------------------------------------------------------------------
  function cancelOrder(address customer) public onlyOwner returns (bool success) {
    orders[customer][&#39;eth&#39;] = 0;
    orders[customer][&#39;tokens&#39;] = 0;
    return true;
  }

  // ------------------------------------------------------------------------
  // Checks the order values by the customer&#39;s address and sends required
  // promo tokens based on the received amount of `this` tokens and ETH
  // ------------------------------------------------------------------------
  function _checkOrder(address customer) private returns (uint256 tokens, uint256 eth) {
    require(started);

    eth = 0;
    tokens = 0;

    if (getLevelsCount() <= 0 || orders[customer][&#39;tokens&#39;] <= 0 || orders[customer][&#39;eth&#39;] <= 0) {
      return;
    }

    ERC20 tokenInstance = ERC20(token);
    uint256 balance = tokenInstance.balanceOf(this);

    uint256 orderEth = orders[customer][&#39;eth&#39;];
    uint256 orderTokens = orders[customer][&#39;tokens&#39;] > balance ? balance : orders[customer][&#39;tokens&#39;];

    for (uint i = 0; i < levels.length; i++) {
      if (levels[i].available <= 0) {
        continue;
      }

      uint256 _tokens = (10**decimals) * orderEth / levels[i].price;

      // check if there enough tokens on the level
      if (_tokens > levels[i].available) {
        _tokens = levels[i].available;
      }

      // check the order tokens limit
      if (_tokens > orderTokens) {
        _tokens = orderTokens;
      }

      uint256 _eth = _tokens * levels[i].price / (10**decimals);
      levels[i].available -= _tokens;

      // accumulate total price and tokens
      eth += _eth;
      tokens += _tokens;

      // reduce remaining limits
      orderEth -= _eth;
      orderTokens -= _tokens;

      if (orderEth <= 0 || orderTokens <= 0 || levels[i].available > 0) {
        // order is calculated
        break;
      }
    }

    // charge required amount of the tokens and ETHs
    orders[customer][&#39;tokens&#39;] = orders[customer][&#39;tokens&#39;].sub(tokens);
    orders[customer][&#39;eth&#39;] = orders[customer][&#39;eth&#39;].sub(eth);

    tokenInstance.transfer(customer, tokens);

    emit Sell(customer, tokens, eth);
  }

  // ------------------------------------------------------------------------
  // public entry point for the `_checkOrder` function
  // ------------------------------------------------------------------------
  function checkOrder(address customer) public onlyOwner returns (uint256 tokens, uint256 eth) {
    return _checkOrder(customer);
  }

  // ------------------------------------------------------------------------
  // Transfer the balance from token owner&#39;s account to `to` account
  // - Owner&#39;s account must have sufficient balance to transfer
  // - 0 value transfers are allowed
  // - only owner is allowed to send tokens to any address
  // - not owners can transfer the balance only to owner&#39;s address
  // ------------------------------------------------------------------------
  function transfer(address to, uint256 tokens) public returns (bool success) {
    require(msg.sender == owner || to == owner || to == address(this));
    address receiver = msg.sender == owner ? to : owner;

    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[receiver] = balances[receiver].add(tokens);

    emit Transfer(msg.sender, receiver, tokens);

    if (receiver == owner) {
      orders[msg.sender][&#39;tokens&#39;] = orders[msg.sender][&#39;tokens&#39;].add(tokens);
      _checkOrder(msg.sender);
    }

    return true;
  }

  // ------------------------------------------------------------------------
  // `allowance` is not allowed
  // ------------------------------------------------------------------------
  function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
    tokenOwner;
    spender;
    return uint256(0);
  }

  // ------------------------------------------------------------------------
  // `approve` is not allowed
  // ------------------------------------------------------------------------
  function approve(address spender, uint tokens) public returns (bool success) {
    spender;
    tokens;
    return true;
  }

  // ------------------------------------------------------------------------
  // `transferFrom` is not allowed
  // ------------------------------------------------------------------------
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
    from;
    to;
    tokens;
    return true;
  }

  // ------------------------------------------------------------------------
  // Accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    owner.transfer(msg.value);
    emit TransferETH(msg.sender, address(this), msg.value);

    orders[msg.sender][&#39;eth&#39;] = orders[msg.sender][&#39;eth&#39;].add(msg.value);
    _checkOrder(msg.sender);
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
    return ERC20(tokenAddress).transfer(owner, tokens);
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out promo token
  // ------------------------------------------------------------------------
  function transferToken(uint256 tokens) public onlyOwner returns (bool success) {
    return transferAnyERC20Token(token, tokens);
  }

  // ------------------------------------------------------------------------
  // Owner can return specified amount from `tokenOwner`
  // ------------------------------------------------------------------------
  function returnFrom(address tokenOwner, uint256 tokens) public onlyOwner returns (bool success) {
    balances[tokenOwner] = balances[tokenOwner].sub(tokens);
    balances[owner] = balances[owner].add(tokens);
    emit Transfer(tokenOwner, owner, tokens);
    return true;
  }

  // ------------------------------------------------------------------------
  // Owner can return all tokens from `tokenOwner`
  // ------------------------------------------------------------------------
  function nullifyFrom(address tokenOwner) public onlyOwner returns (bool success) {
    return returnFrom(tokenOwner, balances[tokenOwner]);
  }
}

contract CSTK_CLT is CSTKDropToken(&#39;CSTK_CLT&#39;, &#39;CryptoStock CLT Promo Token&#39;, 100000 * 10**8, 8, 0x2001f2A0Cf801EcFda622f6C28fb6E10d803D969) {

}