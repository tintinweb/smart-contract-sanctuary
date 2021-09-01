/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed from, address indexed to, uint256 value);
}

contract Token is Ownable,  ERC20 {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;

    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;


    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}

    function getTotalSupply() view public returns (uint256) {return totalSupply;}
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
      require(_to != address(0), "Invalid address");
      require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to].add(_amount)>balances[_to]);
      balances[msg.sender]=balances[msg.sender].sub(_amount);
      balances[_to]=balances[_to].add(_amount);
      emit Transfer(msg.sender,_to,_amount);
      return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
      require(_from != address(0), "Invalid address");
      require(_to != address(0), "Invalid address");
      require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to].add(_amount)>balances[_to]);
      balances[_from]=balances[_from].sub(_amount);
      allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
      balances[_to]=balances[_to].add(_amount);
      emit Transfer(_from, _to, _amount);
      return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
      require(_spender != address(0), "Invalid address");
      allowed[msg.sender][_spender]=_amount;
      emit Approval(msg.sender, _spender, _amount);
      return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

contract VTOKEN is Token {  
    constructor() public{
      symbol = "V-TOKEN";
      name = "V-TOKEN Credit";
      decimals = 18;
    }
    
    function mint(address account, uint256 amount) onlyOwner public {
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }
}