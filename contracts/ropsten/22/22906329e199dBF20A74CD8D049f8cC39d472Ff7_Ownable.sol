/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity ^0.8.4;contract Ownable{address private m_Owner;event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);constructor(){m_Owner=msg.sender;emit OwnershipTransferred(address(0),msg.sender);}function owner()public view returns(address){return m_Owner;}function transferOwnership(address _address)public virtual{require(msg.sender==m_Owner);m_Owner=_address;emit OwnershipTransferred(msg.sender,_address);}}