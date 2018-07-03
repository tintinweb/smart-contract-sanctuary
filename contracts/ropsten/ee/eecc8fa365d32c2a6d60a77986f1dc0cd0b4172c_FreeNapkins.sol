pragma solidity ^0.4.18;

contract EthVerifyCore{
  mapping (address => bool) public verifiedUsers;
}
contract FreeNapkins{
  mapping (address => uint256) public napkinCount;
  EthVerifyCore public ethVerify=EthVerifyCore(0x286A090b31462890cD9Bf9f167b610Ed8AA8bD1a);

  function getFreeNapkins() public{
    //causes transaction to be reverted if user is not verified. Ensures fair napkin distribution.
    require(ethVerify.verifiedUsers(msg.sender));
    //50 napkin limit per user
    require(napkinCount[msg.sender]<=50);
    //give user 10 free free napkins
    napkinCount[msg.sender]+=10;
  }
}