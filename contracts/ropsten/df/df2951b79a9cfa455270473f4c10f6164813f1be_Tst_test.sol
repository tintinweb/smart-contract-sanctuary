pragma solidity ^0.4.24;


contract Tst_test {
  address public admin; //the admin address
  constructor() public {
    admin = msg.sender;
  }
  
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
  //fall back
  function() payable public {
      
  }
  function withdrawAll() onlyAdmin() public {
    msg.sender.transfer(address(this).balance);
  }
}