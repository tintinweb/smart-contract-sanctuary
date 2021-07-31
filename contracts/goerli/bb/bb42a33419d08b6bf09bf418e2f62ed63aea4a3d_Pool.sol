/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity <=0.8.6;
contract Pool {
    struct Member{
      uint uid;
      address addr;
    }
  mapping (address => bool) addresses;
  mapping (uint => Member) members;
  uint member_cnt = 0;
  uint tx_cnt = 0;
  
  function isMember(address _addr) public view returns(bool){
      return addresses[_addr];
  }
  
  function enroll(address _addr) public{
      require(isMember(_addr) == false);
      addresses[_addr] = true;
      members[member_cnt] = Member({
          uid: member_cnt,
          addr: _addr
      });
  }
  
  receive() external payable{
      //require(isMember(msg.sender),"Not enrolled");
      //require(msg.value > 0,"units must bigger than 0");
  }
  
  function getBalance() public view returns(uint){
      return address(this).balance;
  }
  
  function withdraw() public{
      selfdestruct(payable(msg.sender));
  }
}