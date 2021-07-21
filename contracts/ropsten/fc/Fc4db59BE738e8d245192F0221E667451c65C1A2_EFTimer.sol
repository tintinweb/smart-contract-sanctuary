/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.17;



// Part: TrustListInterface

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}

// Part: TrustListTools

contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: Timer.sol

contract EFTimer is TrustListTools{
    uint256 prev_action;

    constructor (address trustlist_addr) TrustListTools(trustlist_addr) public {
        prev_action = block.timestamp;
    }

    function trigger_timer() public is_trusted(msg.sender) {
        require(block.timestamp > prev_action, "EFTimer: trigger_timer: too frequent action, plz wait for next block");
        prev_action = block.timestamp;
    }
}