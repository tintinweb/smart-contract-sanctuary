import "./Token.sol";

pragma solidity 0.6.0;

contract Factory {

  address owner;
  address[] public children; // public, list, get a child address at row #
  event LogCreatedChild(address child); // maybe listen for events

  constructor() public{
    owner = msg.sender;
  }

  function createChild() external {
    Token child = new Token();
    emit LogCreatedChild(address(child)); // emit an event - another way to monitor this
    children.push(address(child)); // you can use the getter to fetch child addresses
  }
}