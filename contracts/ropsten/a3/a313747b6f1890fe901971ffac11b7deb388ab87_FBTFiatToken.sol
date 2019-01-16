pragma solidity ^0.4.11;

// File: contracts/ERC223ReceivingContract.sol

/*
 * Contract that is working with ERC223 tokens
 */
contract ERC223ReceivingContract {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}

// File: contracts/SafeMath.sol

/**
 * Math operations with safety checks
 */
library SafeMath {
  function sub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function min(uint a, uint b) pure internal returns (uint) {
    if(a > b)
      return b;
    else
      return a;
  }
}

// File: contracts/ERC223Token.sol

contract ERC223Token {
  using SafeMath for uint;

  // token constants
  string public name;
  string public symbol;
  uint8 public decimals;
  uint public totalSupply;

  // token balances
  mapping(address => uint) public balanceOf;

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address to, uint value, bytes data) public {
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    uint codeLength;

    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(to)
    }

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      receiver.tokenFallback(msg.sender, value, data);
    }
    emit Transfer(msg.sender, to, value, data);
  }

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address to, uint value) public {
    uint codeLength;

    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(to)
    }

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      bytes memory empty;
      receiver.tokenFallback(msg.sender, value, empty);
    }
    emit Transfer(msg.sender, to, value, empty);
  }

  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

// File: contracts/ERC223MintableToken.sol

contract ERC223MintableToken is ERC223Token {
  using SafeMath for uint;
  uint internal circulatingSupply;

  function mint(address to, uint value) internal {
    uint codeLength;

    assembly {
      // Retrieve the size of the code on target address, this needs assembly .
      codeLength := extcodesize(to)
    }

    circulatingSupply += value;

    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      bytes memory empty;
      receiver.tokenFallback(msg.sender, value, empty);
    }
    emit Mint(to, value);
  }

  event Mint(address indexed to, uint value);
}

// File: contracts/FBTFiatToken.sol

contract FBTFiatToken is ERC223MintableToken {
  // uint public circulatingSupply;

  address owner;

  /**
   * FBTFiatToken contructor.
   *
   */
  function contructor() public {
    name = "FBT USD Token";
    symbol = "sUSD"; // smart USD
    decimals = 18;

    owner = msg.sender;
  }

  function mintTokens(address _dest, uint _value) public onlyOwner {
    mint(_dest, _value);
  }


  // modifiers
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}