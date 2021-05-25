/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.5.16;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Kitties is Ownable{
    uint256 public mua = 123; 
    function setMua(uint256 _newMua) onlyOwner public {
        mua = _newMua;
        
    }

}


contract KittiesV2  is Kitties{
    function setMua(uint256 _newMua) onlyOwner public {
        mua = cond(_newMua);
        
    }
    
    function cond(uint i) public pure returns(uint)   {
        if (i == 2) {
            return 100;
        } else {
            return  0;
        }
    }
}