pragma solidity ^0.4.23;

import './Erc20.sol';
import './SafeMath.sol';

contract BatchTransferContract{
  using SafeMath for uint256;
  
  address owner;
  
  event EtherTransfer(address from, uint256 value);
  event TokenTransfer(address from, uint256 value,address token);
  event EtherClaim(address owner,uint256 value);
  event TokenClaim(address owner,uint256 value,address token);
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  constructor() public{
    owner = msg.sender;
  }
  
  function() public payable {}
  
  function sendEther(address[] recipients,uint256[] values) public payable{
    uint256 total = msg.value;
    uint256 i=0;
    for(i;i<recipients.length;i++){
      require(total >= values[i]);
      total = total.sub(values[i]);
      recipients[i].transfer(values[i]);
    }    
    emit EtherTransfer(msg.sender,msg.value);
  }
  
  function sendToken(address token,address[] recipients,uint256[] values) public payable{
    uint256 total = 0;
    ERC20 erc20 = ERC20(token);
    uint256 i = 0;
    for(i;i < recipients.length;i++){
      erc20.transferFrom(msg.sender,recipients[i],values[i]);
      total += values[i];
    }
    emit TokenTransfer(msg.sender,total,token);
    
  }
  
  function claimEther() public onlyOwner{
    uint256 balance = address(this).balance;
    owner.transfer(balance);
    emit EtherClaim(owner,balance);
  }
  
  function claimToken(address token) public onlyOwner{
    ERC20 erc20 = ERC20(token);
    uint256 balance = erc20.balanceOf(this);
    erc20.transfer(owner,balance);
    emit TokenClaim(owner,balance,token);
  }
  
}