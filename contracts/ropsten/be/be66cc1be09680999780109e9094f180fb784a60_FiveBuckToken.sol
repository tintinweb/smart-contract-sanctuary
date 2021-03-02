// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Basic.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Template token that can be purchased
 * @dev World's smallest crowd sale
 */
contract FiveBuckToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  string public constant name = "Five Buck Token";
  string public constant symbol = "5ive";
  uint8 public constant decimals = 18;
  uint256 totalSupply_ = 500000000*(10**decimals);

    constructor () 
    {
       balances[msg.sender] = totalSupply_;
       emit Transfer(address(0), msg.sender, totalSupply_);
    }
    
  /**
  * @dev Total number of tokens in existence
  */
  function  totalSupply() override public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token to a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) override public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) override public view returns (uint256) {
    return balances[_owner];
  }
  
   // Make sure this contract cannot receive ETH.
    fallback() external payable 
    {
        revert("The contract cannot receive ETH payments.");
    }

    receive() external payable 
    {
        revert("The contract cannot receive ETH payments.");
    }
}