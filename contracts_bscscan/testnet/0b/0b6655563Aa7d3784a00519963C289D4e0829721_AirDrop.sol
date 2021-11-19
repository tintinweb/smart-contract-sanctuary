/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

pragma solidity ^0.4.24;

/**
 * @title Token
 * @dev Simpler version of ERC20 interface
 */
contract Token {
  function balanceOf(address owner) public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract AirDrop is Ownable {

  // This declares a state variable that would store the contract address
  Token public tokenInstance;

  /*
    constructor function to set token address
   */
  constructor(address _tokenAddress) public {
    tokenInstance = Token(_tokenAddress);
  }

  /*
    Airdrop function which take up a array of address, indvidual token amount and eth amount
   */
   function sendBatch(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
         require(_recipients.length == _values.length);
         for (uint i = 0; i < _values.length; i++) {
             tokenInstance.transfer(_recipients[i], _values[i]);
         }
         return true;
   }


  function withdraw() onlyOwner public returns (bool) {
    uint256 balance_ = tokenInstance.balanceOf(address(this));
    tokenInstance.transfer(msg.sender, balance_);
    return true;
  }

}