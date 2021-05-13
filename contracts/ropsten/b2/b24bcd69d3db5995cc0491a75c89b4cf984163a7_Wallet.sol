/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.4.18;


contract ERC20Interface {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract Wallet {

  address public parentAddress;
  event Deposited(address from, uint value, bytes data);

  constructor()  public {
    parentAddress = msg.sender;
  }

  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

  function() public payable {
    parentAddress.transfer(msg.value);
    emit Deposited(msg.sender, msg.value, msg.data);
  }

  function flushTokens(address tokenContractAddress) public onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    uint WalletBalance = instance.balanceOf(address(this));
    if (WalletBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, WalletBalance)) {
      revert();
    }
  }

  function flush() public {
    parentAddress.transfer(address(this).balance);
  }
  function getHot() public {
    return WalletManage(parentAddress).transfer(address(this).balance);
  }
  
}


contract WalletManage {
  address[] public listAddresss;
  address public hotAddress;

  function createWallet() public {
    address listAddress = new Wallet();
    listAddresss.push(listAddress);
  }

  function setHot(address data) public {
   hotAddress=data;
  }
  
  
  function() public payable {

  }
}