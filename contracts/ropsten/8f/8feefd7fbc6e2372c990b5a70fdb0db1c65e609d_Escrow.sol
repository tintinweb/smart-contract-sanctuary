pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  /**
  * Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  *  Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract IERC20Token {
  uint256 public totalSupply;

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender) public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);
  
  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer( address indexed from, address indexed to,  uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  event Burn(address indexed from, uint256 value);
}

contract Escrow {
    using SafeMath for uint256;
    
    address public admin = 0xb551fC0b211599A1B91fc1ACB0aAEF7E6f48Cc09;
    uint256 public minDeposit = 1000000;
    uint256 public fee = 120000;
    
    
    uint256 public feeBalance;
    
    constructor() public {
    }

    mapping(address => mapping(address => uint256)) public escrowBalance;
    mapping(address => mapping(address => uint256)) public sales;
    

    function deposit(IERC20Token token, uint256 amount) public {
        uint256 minVal = minDeposit + fee;
        require(amount >= minVal);
        require(token.transferFrom(msg.sender, this, amount));
        escrowBalance[msg.sender][token] = escrowBalance[msg.sender][token].add(amount);
    }

    event StartWithdrawal(address indexed account, address token);

    function startWithdrawal(IERC20Token token) public {
        emit StartWithdrawal(msg.sender, token);
    }

    function withdraw(IERC20Token token) public {
        uint256 amount = escrowBalance[msg.sender][token];
        escrowBalance[msg.sender][token] = 0;
        require(token.transfer(msg.sender, amount));
    }

    function transfer(
        address from,
        address to,
        IERC20Token token,
        uint256 tokens
    )
        internal
    {
        require(escrowBalance[from][token] >= tokens, "Insufficient balance.");

        escrowBalance[from][token] -= tokens;
        escrowBalance[to][token] += tokens;
    }
}