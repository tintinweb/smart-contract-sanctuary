/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity 0.8.0;

//SPDX-License-Identifier: UNLICENSED

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      uint256 c = a - b;
      return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}


/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract myToken is Ownable {
    string public constant name = "Flesh";
    string public constant symbol = "Flesh";
    uint8 public constant decimals = 18;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    uint256 totalSupply_;
    
    constructor() {
        totalSupply_ = 1000000 * 10 ** uint(decimals);
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns(uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public returns(bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public returns(bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns(uint) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns(bool) {
        require(numTokens >= balances[owner]);
        require(numTokens >= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 substractedValue) public returns(bool) {
        allowed[msg.sender][spender] -= substractedValue;
        emit Approval(msg.sender, spender, substractedValue);
        return true;
    }
    
    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Can not be the 0 address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "Invalid Value");
        balances[account] -= amount;
        totalSupply_ -= amount;
        emit Transfer(account, address(0), amount);
    }
    
    function mint(address account, uint256 amount) external onlyOwner{
        require(account != address(0), "Cant not be the 0 address");
        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    
}