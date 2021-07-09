/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

interface ERC20 {
   function transfer(address to, uint256 value) external returns (bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
   function balanceOf(address account) external view returns (uint256);
  }
  


contract Ownable{    
 // Variable that maintains
 // owner address
  address private _owner;

  event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

  uint256 public tokenAmount = 100000000000000000000; // 18 decimals
  uint256 constant public waitTime = 240 minutes;

// Sets the original owner of
// contract when it is deployed
 constructor()
  {
    _owner = msg.sender;
  }

 // Publicly exposes who is the
 // owner of this contract
function owner() public view returns(address)
 {
    return _owner;
 } 
 
 // onlyOwner modifier that validates only
// if caller of function is contract owner,
// otherwise not

 modifier onlyOwner()
 {
    require(isOwner(),
    "Function accessible only by the owner !!");
    _;
 }

// function for owners to verify their ownership.
// Returns true for owners otherwise false
 function isOwner() public view returns(bool)
 {
    return msg.sender == _owner;
 }

 /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Faucet is Ownable {

  mapping(address => uint256) lastAccessTime;
  
   ERC20 public tokenInstance; 
   
 function requestTokens() public {
    require(allowedToWithdraw(msg.sender));
    tokenInstance.transfer(msg.sender, tokenAmount);
    lastAccessTime[msg.sender] = block.timestamp + waitTime;
 }

 function allowedToWithdraw(address _address) public view returns (bool) {
    if(lastAccessTime[_address] == 0) {
        return true;
    } else if(block.timestamp >= lastAccessTime[_address]) {
        return true;
    } else if (ERC20(tokenInstance).balanceOf(_address) >= 1000) {
        return true;
    }
    return false;
 }
 
}