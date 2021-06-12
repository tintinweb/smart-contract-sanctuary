/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.11;
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
  constructor () public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token { function transfer(address receiver, uint amount) external; }

contract TokenMultiSender is Ownable{
  event Message(string message);
  
  token tokenReward;
  
  address public addressOfTokenUsedAsReward;
  function setTokenReward(address _addr) public onlyOwner {
    tokenReward = token(_addr);
    addressOfTokenUsedAsReward = _addr;
  }
  
  function distributeTokens(address[] memory _addrs, uint[] memory _bals,string memory message) public onlyOwner{
		emit Message(message);
		for(uint i = 0; i < _addrs.length; ++i){
			tokenReward.transfer(_addrs[i],_bals[i]);
		}
	}
  
  function distributeEth(address payable[] memory _addrs, uint[] memory _bals, string memory message) public onlyOwner {
    for(uint i = 0; i < _addrs.length; ++i) {
        _addrs[i].transfer(_bals[i]);
    }
    emit Message(message);
  }
  
  // accept ETH
  receive () payable external {}

  function withdrawEth(uint _value) public onlyOwner {
    address(uint160(owner)).transfer(_value);
  }
  
  function withdrawTokens(uint _amount) public onlyOwner {
	tokenReward.transfer(owner,_amount);
  }
}