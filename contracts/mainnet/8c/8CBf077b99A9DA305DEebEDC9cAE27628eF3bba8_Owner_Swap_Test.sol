/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract Owner_Swap_Test {
  event Controller_Set(address new_controller);

  address public controller;
  constructor(){
    controller = msg.sender;
  }

  function set_controller(address new_controller) public only_controller {
    controller = new_controller;
    emit Controller_Set(new_controller);
  }

  /// @notice this modifier requires that msg.sender is the controller of this contract
  modifier only_controller {
     require( msg.sender == controller, "not controller" );
     _;
  }
}