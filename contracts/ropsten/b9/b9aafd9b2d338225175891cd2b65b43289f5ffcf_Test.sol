pragma solidity ^0.4.24;

contract Test {
  address add;
  function () {
    add = msg.sender;
  }
}