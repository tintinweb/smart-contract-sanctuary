/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-22
*/

pragma solidity 0.6.8;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
}

contract Sale {
  using SafeMath for uint256;

  ERC20 public Token;
  address payable public owner;
  uint256 public tcontributed;
  bool private _closed = true;
  mapping (address => uint256) private _totalsent;

  constructor(address tokenaddy) public {
    owner = msg.sender;
    Token = ERC20(tokenaddy);
  }

  uint256 amount;
 
  receive () external payable {
    require(!_closed, "closed");
    require(_totalsent[msg.sender].add(msg.value) <= 5 ether, "5 max");
    require(Token.balanceOf(address(this)) > 0, "nothing left");
    require(msg.value >= 1 ether && msg.value <= 5 ether, "value must be between 1 and 5");
    amount = msg.value.div(10).mul(50);
    tcontributed = tcontributed.add(msg.value);
    Token.transfer(msg.sender, amount);
    _totalsent[msg.sender] = _totalsent[msg.sender].add(msg.value);
  }


  function withdraw() public {
    require(msg.sender == owner);
    require(_closed == true);
    owner.transfer(tcontributed);
  }

  function emergencyWithdraw() public {
      require(msg.sender == owner);
      selfdestruct(owner);
  }

  function start() public {
    require(msg.sender == owner);
    _closed = false;
  }
  
  function end() public {
    require(msg.sender == owner);
    _closed = true;
  }

  function burnLeftover() public {
    require(msg.sender == owner);
    require(Token.balanceOf(address(this)) > 0 && _closed);
    Token.transfer(0x000000000000000000000000000000000000dEaD, Token.balanceOf(address(this)));
  }
  
  
  function available() public view returns(uint256) {
    return Token.balanceOf(address(this));
  }
}