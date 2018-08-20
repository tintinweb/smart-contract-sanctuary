pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9efaffe8fbdefff5f1f3fcffb0fdf1f3">[email&#160;protected]</a>
// released under Apache 2.0 licence
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
contract CoinLoanCS is ERC20, Owned {
  using SafeMath for uint256;

  string public symbol;
  string public  name;
  uint256 public decimals;
  uint256 _totalSupply;

  address public token;
  uint256 public price;

  mapping(address => uint256) balances;
  mapping(address => mapping(string => uint256)) orders;

  event TransferETH(address indexed from, address indexed to, uint256 eth);
  event Sell(address indexed to, uint256 tokens);

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
    symbol = "CLT_CS";
    name = "CoinLoan CryptoStock Promo Token";
    decimals = 8;
    token = 0x2001f2A0Cf801EcFda622f6C28fb6E10d803D969;
    price = 3000000;  // = 0.03000000
    _totalSupply = 100000 * 10**decimals;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  // ------------------------------------------------------------------------
  // Changes the address of the supported token
  // ------------------------------------------------------------------------
  function setToken(address newTokenAddress) public onlyOwner returns (bool success) {
    token = newTokenAddress;
    return true;
  }

  // ------------------------------------------------------------------------
  // Return a contract address of the supported token
  // ------------------------------------------------------------------------
  function getToken() public view returns (address) {
    return token;
  }

  // ------------------------------------------------------------------------
  // Sets `price` value
  // ------------------------------------------------------------------------
  function setPrice(uint256 newPrice) public onlyOwner returns (bool success) {
    price = newPrice;
    return true;
  }

  // ------------------------------------------------------------------------
  // Returns current price (without decimals)
  // ------------------------------------------------------------------------
  function getPrice() public view returns (uint256) {
    return price;
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
  function _checkOrder(address customer) private returns (uint256) {
    require(price > 0);
    if (orders[customer][&#39;tokens&#39;] <= 0 || orders[customer][&#39;eth&#39;] <= 0) {
      return 0;
    }

    uint256 decimalsDiff = 10 ** (18 - 2 * decimals);
    uint256 eth = orders[customer][&#39;eth&#39;];
    uint256 tokens = orders[customer][&#39;eth&#39;] / price / decimalsDiff;

    if (orders[customer][&#39;tokens&#39;] < tokens) {
      tokens = orders[customer][&#39;tokens&#39;];
      eth = tokens * price * decimalsDiff;
    }

    ERC20 tokenInstance = ERC20(token);

    // complete the order
    require(tokenInstance.balanceOf(this) >= tokens);

    // charge required amount of the tokens and ETHs
    orders[customer][&#39;tokens&#39;] = orders[customer][&#39;tokens&#39;].sub(tokens);
    orders[customer][&#39;eth&#39;] = orders[customer][&#39;eth&#39;].sub(eth);

    tokenInstance.transfer(customer, tokens);

    emit Sell(customer, tokens);

    return tokens;
  }

  // ------------------------------------------------------------------------
  // public entry point for the `_checkOrder` function
  // ------------------------------------------------------------------------
  function checkOrder(address customer) public onlyOwner returns (uint256) {
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
    orders[msg.sender][&#39;eth&#39;] = orders[msg.sender][&#39;eth&#39;].add(msg.value);
    _checkOrder(msg.sender);
    emit TransferETH(msg.sender, address(this), msg.value);
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
  // Owner can returns all tokens from `tokenOwner`
  // ------------------------------------------------------------------------
  function nullifyFrom(address tokenOwner) public onlyOwner returns (bool success) {
    return returnFrom(tokenOwner, balances[tokenOwner]);
  }
}