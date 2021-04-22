/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Mastering_Blockchain_Guestbook {

  address private owner;
  string private messagefromauthors;
  mapping (uint256 => string) private guestbookmessage;
  uint256 private bookcounter;

 constructor () {
    owner = msg.sender;    
    bookcounter = 0;
  }

  /* Modifiers */
  /* Require the address interacting with the smart contract is the same as the owner address*/
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  /* Add New Message From Readers, anyone can set */
  function setmessagefromreader (string memory _messagefromreader) public {
    guestbookmessage[bookcounter] = _messagefromreader;
    bookcounter ++;
  }

  /*get message from reader*/  
  function getmessagefromreader(uint256 _bookentrynumber) public view returns (string memory _messagefromreader) {
    return guestbookmessage[_bookentrynumber];
  }

  /*get total number of messages from reader*/
  function getnumberofmessagesfromreaders() public view returns (uint256 _numberofmessages) {
    return bookcounter;
  }

  /* Set Message From Authors, only contract owner can set */
  function setmessagefromauthors (string memory _messagefromauthors) onlyOwner() public {
    messagefromauthors = _messagefromauthors;
  }

  /*get message from authors*/
  function getmessagefromauthors() public view returns (string memory _name) {
    return messagefromauthors;
  }


}