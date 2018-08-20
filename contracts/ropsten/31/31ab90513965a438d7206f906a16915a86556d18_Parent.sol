pragma solidity ^0.4.24;

contract Child {
  address public owner;

  constructor () public {
    owner = msg.sender;
  }
}

contract Parent {

  address public owner;
  address[] public investorlist;


  constructor () public {
    owner = msg.sender;
  }

    function createChild(uint num) public {
        for(uint i=0;i<num;i++){
            Child child = new Child();
            investorlist.push(address(child)) -1;
        }
    }
}