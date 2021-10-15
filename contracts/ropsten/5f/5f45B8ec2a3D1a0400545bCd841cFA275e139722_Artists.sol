/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// File: contracts/Artists.sol

/**
 *Submitted for verification at Etherscan.io on 2018-04-15
*/

pragma solidity ^0.4.15;

/*
  https://cryptogs.io
  --Austin Thomas Griffith for ETHDenver
  This contract is used to get Artists' work signaled to be minted to Togs
*/



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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Artists is Ownable {

  uint public priceToMint = 10000000000000000;
  uint public priceToMintStack = 40000000000000000;

  function Artists() public { }

  function setPrice(uint _priceToMint,uint _priceToMintStack) public onlyOwner returns (bool) {
    priceToMint=_priceToMint;
    priceToMintStack=_priceToMintStack;
    return true;
  }

  function mint(bytes32 image) public payable returns (bool) {
    require( msg.value >= priceToMint );
    Mint(msg.sender,image,msg.value,now);
  }
  event Mint(address indexed sender, bytes32 image, uint256 value, uint256 time);

  function mintStack(bytes32 image) public payable returns (bool) {
    require( msg.value >= priceToMintStack );
    MintStack(msg.sender,image,msg.value,now);
  }
  event MintStack(address indexed sender, bytes32 image, uint256 value, uint256 time);

  function withdraw(uint256 _amount) public onlyOwner returns (bool) {
    require(this.balance >= _amount);
    assert(owner.send(_amount));
    return true;
  }

  function withdrawToken(address _token,uint256 _amount) public onlyOwner returns (bool) {
    StandardToken token = StandardToken(_token);
    token.transfer(msg.sender,_amount);
    return true;
  }

}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}