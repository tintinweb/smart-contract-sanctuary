pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./Burnable.sol";
import "./Mintable.sol";
import "./Pausable.sol";
import "./Lockable.sol";



/**
 * @title EarnCart
 * @dev Implements Ownable, Burnable, Mintable, Pausable and Lockable.
 **/
contract EarnCart is Ownable, Burnable, Mintable, Pausable, Lockable {
    // public variables
    string public name = "EarnCart";
    string public symbol = "CART";
    uint8 public decimals = 18;

    constructor() {
        totalSupply_ = 500000000 * (10 ** uint256(decimals));

        // Add all the tokens created to the creator of the token
        balances[msg.sender] = totalSupply_;
    }

    receive() payable external {
        revert();
    }


    function transfer(address _to,uint256 _value) public whenNotPaused whenNotLocked override returns (bool){
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused whenNotLocked override returns (bool){
      return super.transferFrom(_from, _to, _value);
    }

    function approve( address _spender, uint256 _value) public whenNotPaused whenNotLocked override returns (bool){
      return super.approve(_spender, _value);
    }

    function increaseApproval( address _spender, uint _addedValue) public whenNotPaused whenNotLocked override returns (bool success){
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval( address _spender, uint _subtractedValue) public whenNotPaused whenNotLocked override returns (bool success){
      return super.decreaseApproval(_spender, _subtractedValue);
    }

}