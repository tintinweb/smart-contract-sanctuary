/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.8.0;

contract Store {
  event ItemSet(bytes32 key, bytes32 value);

  mapping (bytes32 => bytes32) public items;

  function setItem(bytes32 key, bytes32 value) external {
    items[key] = value;
    emit ItemSet(key, value);
  }

  function msgSender(address target) public view returns(address ret){
    if ( msg.data.length >= 24 ){
      assembly{
        ret := shr(96,calldataload(sub(calldatasize(),20)))
      }
    } else {
      return msg.sender;
    }
    target = address(this);
  }
}