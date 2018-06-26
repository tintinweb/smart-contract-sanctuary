pragma solidity ^0.4.24;

contract Test {
  address public add;
  function () {
    add = msg.sender;
  }
}