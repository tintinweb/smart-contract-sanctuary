pragma solidity ^0.4.18;

/**

PinkDate Token-Share Contract (PDP)
Using code generously from https://github.com/OpenZeppelin/zeppelin-solidity/

The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract Ownable {
  address public owner;

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

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

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
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

// --- BEGIN Custom Code ---
// Up until here things have been stock from OpenZeppelin
contract CappedBurnToken is StandardToken, Ownable {

  uint256 public cap;

  function CappedBurnToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  event Mint(address indexed to, uint256 amount);
  event Unmint(address indexed from, uint256 amount);

  function mint(address _to, uint256 _amount) onlyOwner external returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  event Burn(address indexed burner, uint256 value);

  /// Permanently destroy tokens
  function burn(uint256 _value) external {
    address burner = msg.sender;
    require(_value <= balances[burner]);
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    cap = cap.sub(_value);
    Burn(burner, _value);
    Transfer(msg.sender, address(0), _value);
  }

  /// Same as burn without reducing cap, allows re-minting
  function unmint(uint256 _value) external {
    address burner = msg.sender;
    require(_value <= balances[burner]);
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Unmint(burner, _value);
    Transfer(msg.sender, address(0), _value);
  }

}

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

contract PDP is CappedBurnToken(144200000), DetailedERC20, CanReclaimToken { 
  uint256 public saleMinShares;
  uint256 public salePriceWei;
  uint256 public saleSharesAvail;
  address internal saleWallet;
  uint256 public saleSharesSold;

  function PDP() DetailedERC20("PinkDate Platform Token-Share", "PDP", 0) public { 
      saleWallet = address(0);
      salePriceWei = 0;
      saleSharesAvail = 0;
      saleSharesSold = 0;
  }

  event Purchase(address indexed to, uint256 shares);

  /// Tokens are manually issued to addresses that have sent ether
  /// The contract sells a limited amount to ensure no oversale happens due to off-chain purchases
  function() external payable { 
      require(saleWallet != address(0)); // Other checks are done on setSale
      uint256 shareTarget = msg.value / salePriceWei;
      require(shareTarget >= saleMinShares);
      require(shareTarget <= saleSharesAvail);
      saleSharesAvail = saleSharesAvail.sub(shareTarget);
      saleSharesSold = saleSharesSold.add(shareTarget);
      Purchase(msg.sender, shareTarget);
      saleWallet.transfer(msg.value);
  }

  function setSale(uint256 newPriceWei, uint256 newSharesAvail, uint256 newMinShares, address newWallet) onlyOwner external {
    // This may be called multiple time to allow more sales on-chain or to change parameters
    // Call with 0 to end sale
    if (newWallet == address(0)) {
      // End sale
      saleWallet = address(0);
      salePriceWei = 0;
      saleSharesAvail = 0;
      saleMinShares = 0;
    } else {
      // These checks are just to be a bit safer and avoid typo mistake
      require(totalSupply_ + saleSharesSold + newSharesAvail <= cap); // Do not exceed cap
      require(newSharesAvail > 100 && newSharesAvail < 10000000); // Between 100 and 10M at a time
      require(newMinShares < 20000); // Min purchase should not be too high
      require(newPriceWei > 100000000000000); // At least around $0.10 / share
      saleMinShares = newMinShares;
      salePriceWei = newPriceWei;
      saleSharesAvail = newSharesAvail;
      saleWallet = newWallet;
    }
  }

  /// Only to be used in case tokens are distributed to allow setSale to issue more in case cap would be hit
  function clearSaleSharesSold(uint256 confirm) onlyOwner external {
    // Checks are just for a bit of safety
    require(confirm == 1);
    require(saleWallet == address(0)); // Sale must be over
    // Next check is not perfect in light of multiple sale rounds but should work for main single round 
    require(totalSupply_ >= saleSharesSold); // All sold tokens must be distributed
    saleSharesSold = 0;
  }

}