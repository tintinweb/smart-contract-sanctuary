pragma solidity ^0.4.24;

contract Test {
  mapping(address=>string) public emails;
  function Test() {

  }

  function getToken(string mail) {
    emails[msg.sender] = mail;
  }
}