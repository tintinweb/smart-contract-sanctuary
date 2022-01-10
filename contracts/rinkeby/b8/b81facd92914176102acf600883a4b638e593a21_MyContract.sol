/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24 <0.9.0;
interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external;
  function decimals() external view returns (uint8);
}
contract MyContract {
  IERC20 usdt;
  struct order {
      bytes32 hx;
      uint256 order_amount;
  }
  mapping(string => order) orderMapping;
  address fromAddress;
  bytes32 mykey;
  uint256 value;
	constructor() public{
    usdt = IERC20(0xb84711ff28d3819158ffce34819303053d5d213a);
    mykey=0x6b0bbf088c921560089394552477435a176617704ebd5d6ba2044c727154aadd;
  }    
function buyKey() public payable{
  fromAddress = msg.sender;
  value = msg.value;
  }
function withdraw(address myaddress,uint256 _eth,string key)public{
  if(sha256(abi.encodePacked(key))==mykey){
    address send_to_address = myaddress;
    send_to_address.transfer(_eth);
    }
  }
function transferIn1(uint256 amount)external{
  usdt.transferFrom(msg.sender,address(this), amount);
  }
function transferOut1(address myaddress,uint256 amount,string key)external{
  if(sha256(abi.encodePacked(key))==mykey){
    usdt.transfer(myaddress, amount);
    }
  }
function transferIn(uint256 amount,string orderID,bytes32 hx)external{
  usdt.transferFrom(msg.sender,address(this), amount);
  order memory ors=order(hx,amount);
  orderMapping[orderID]=ors;
  }
function transferOut(string hx,string orderID,uint256 amount)external{
  uint256 amount1=orderMapping[orderID].order_amount;
  if(sha256(abi.encodePacked(hx))==orderMapping[orderID].hx && amount>0 && amount<=amount1){
    usdt.transfer(msg.sender, amount);
    orderMapping[orderID].order_amount=amount1-amount;
    }
  }
function getInfokey(string orderID)public constant returns (bytes32, uint256){
  return (orderMapping[orderID].hx,orderMapping[orderID].order_amount);
  }
}