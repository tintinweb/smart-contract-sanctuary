/**
 *Submitted for verification at hooscan.com on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.0;

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
  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


}

contract Random is Ownable {

    
    uint256 subNum = 7361;
    
    event LuckNum(uint256 luckNum);
    
    constructor(){
       
    }
 

    function getLucky(uint256 param) public onlyOwner{
        
        uint srcNum = block.timestamp;
      
        uint256 calcuNum = (srcNum*param*84)%subNum;
                
        emit LuckNum(calcuNum);
    }
 

}