/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

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

interface IERC20{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LmhToken is IERC20{
    using SafeMath for uint;
    string public name;
    string public symable;
    uint public decimals;
    uint  _totalSupply; 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor () public {
        name = "LmhToken";
        symable = "Lmh";
        decimals = 6;
        _totalSupply = 1*100000000**6;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }

    function totalSupply() public override view returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public override view returns (uint256){
        return balances[account];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns (uint256){
        return allowed[owner][spender];
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
        require(balances[sender] >= amount);
        balances[sender] = balances[sender].sub(amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender,recipient,amount);
        return true;
    }

    
    function transfer(address recipient, uint256 amount) public override returns (bool){
        require(balances[msg.sender] > 0);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender,recipient,amount);
        return true;
    }


    

}