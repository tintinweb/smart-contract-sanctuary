pragma solidity ^0.4.2;

// File: contracts/SafeMath.sol

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/ERC20.sol

contract ERC20Interface {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Interface {

    // who owns how many tokens
    mapping(address => uint256) balances;

    // account "A" allows account "B" to extract "X" amount
    mapping(address => mapping(address => uint256)) internal allowed;

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(balances[msg.sender] >= value);

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(from != address(0));
        require(balances[from] >= value);
        require(allowed[from][msg.sender] >= value);

        balances[from] = SafeMath.sub(balances[from], value);
        balances[to] = SafeMath.add(balances[to], value);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], value);

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
}

// File: contracts/MZToken.sol

contract MZToken is ERC20 {
    string public constant name = "Martin Zugnoni Token";
    string public constant symbol = "MZT";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 1000 * (10**6);  // 1 billion

    address private owner;

    function MZToken() public {
        owner = msg.sender;

        // creator of the Token owns all tokens
        balances[owner] = totalSupply();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}