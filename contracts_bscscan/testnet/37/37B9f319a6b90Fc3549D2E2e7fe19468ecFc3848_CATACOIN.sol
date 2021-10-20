/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
interface ERC20Interface {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address _account) external view returns (uint);
    
    function decimals() external view returns (uint8);
    
    function transfer(address _recipient, uint _amount) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint);

    function approve(address _spender, uint _amount) external returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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



contract CATACOIN is ERC20Interface {
  using SafeMath for uint256;
  
  uint8 private _decimals;
  string public name;
  string public symbol;
  uint256 private supply;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;


  constructor() public {
        name = "CATACOIN";
        symbol = "CATA";
        _decimals = 8;
        supply = 10 * 10**9 * 10**9;
        balances[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }

  function totalSupply() external view returns (uint256) {
    return supply;
  }


  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
    function decimals() external view returns (uint8) {
    return _decimals;
  }

  function transfer(address _recipient, uint _amount) external returns (bool){
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      balances[_recipient] = balances[_recipient].add(_amount);
      emit Transfer(msg.sender, _recipient, _amount);
      return true;
  }

    function allowance(address _owner, address _spender) external view returns (uint){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _amount) external returns (bool){
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) external returns (bool){
        balances[_sender] = balances[_sender].sub(_amount);
        allowed[_sender][msg.sender] = allowed[_sender][msg.sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }
}