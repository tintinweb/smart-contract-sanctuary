pragma solidity ^0.4.18;

contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract MintTokensInterface {
    
   function mintTokensExternal(address to, uint tokens) public;
    
}

contract TokenDistributor is Ownable {
    
  MintTokensInterface public crowdsale = MintTokensInterface(0x8DD9034f7cCC805bDc4D593A01f6A2E2EB94A67a);
    
  function mintBatch(address[] wallets, uint[] tokens) public onlyOwner {
    require(wallets.length == tokens.length);
    for(uint i=0; i<wallets.length; i++) crowdsale.mintTokensExternal(wallets[i], tokens[i]);
  }
    
}