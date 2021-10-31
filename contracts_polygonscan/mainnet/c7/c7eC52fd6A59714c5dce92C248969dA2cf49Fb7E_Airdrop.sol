/**
 *Submitted for verification at polygonscan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.4.26;

contract ERC20 {
  function transfer(address _recipient, uint256 _value) public returns (bool success);
}

contract Airdrop {
    address private _owner;
    
    constructor() public {
        _owner = msg.sender;
    }
    
  function drop(ERC20 token, address[] recipients, uint256[] values) public {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
}