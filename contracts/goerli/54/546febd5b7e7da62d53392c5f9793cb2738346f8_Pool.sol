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
   struct Transaction{
        address addr;
        uint balance;
        uint time;
        bytes32 hash;
    }
    address public owner;
    constructor(){
        owner = msg.sender;
    }
  mapping (address => bool) addresses;
  mapping (uint => Member) members;
  mapping (address => uint) memberNo;
  mapping (uint => Transaction) transactions;
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
      memberNo[_addr] = member_cnt;
      member_cnt++;
  }
  
  function getMemberID(address _addr) public view returns(uint){
      return memberNo[_addr];
  }
  
  receive() external payable{
      require(isMember(msg.sender),"Not enrolled");
      transactions[tx_cnt++] = Transaction({
         addr: msg.sender,
         balance: msg.value,
         time: block.timestamp,
         hash: keccak256(abi.encodePacked(block.difficulty,block.timestamp))
      });
  }
  
  function getBalance() public view returns(uint){
      return address(this).balance;
  }
  
  function getTx(uint _uid) public view returns(Transaction memory){
      return transactions[_uid];
  }
  
  function withdraw() public payable{
      require(msg.sender == owner);
      require(address(this).balance > 0);
      selfdestruct(payable(msg.sender));
  }
}