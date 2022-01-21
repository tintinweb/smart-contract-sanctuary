// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/

contract Box {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
    function valor() external returns(uint256){
      return val;
    }
    function setValor(uint256 _val) external returns(bool){
      val = _val;
    }

}