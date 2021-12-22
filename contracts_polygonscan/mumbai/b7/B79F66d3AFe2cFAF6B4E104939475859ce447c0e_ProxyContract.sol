/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

//defined interface needed to interact with other contract
interface Ibusinesslogic {
  function getYear() external pure returns(uint);
}

contract ProxyContract {
  //set an admin address
  address public admin;
  //interface contract address
  Ibusinesslogic public businesslogic;
  //the admin is the owner
  constructor() {
    admin = msg.sender;
  }

 
  // upgrade contract to point to execute function
  function upgrade(address _businesslogic) external {
    require(msg.sender == admin, 'only admin');
    businesslogic = Ibusinesslogic(_businesslogic);
  }


  //get year function using the businesslogic function
  function getYear() external view returns(uint) {
    return businesslogic.getYear();
  }
}