pragma solidity ^0.4.6;

contract Child {
  address owner;

  function Child() {
    owner = msg.sender;
  }
}

contract Parent {

  address owner;


  function Parent(){
    owner = msg.sender;
  }

  function createChild() {
    Child child = new Child();
  }
}