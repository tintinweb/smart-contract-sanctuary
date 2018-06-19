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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract IntermediateWallet is Ownable {
    
  address public wallet;
  
  function IntermediateWallet() public {
    wallet = owner;
  }
  
  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20Basic alienToken = ERC20Basic(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

  function () payable public {
    wallet.transfer(msg.value);
  }

}