/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.7.4;

// @name Rich
// @dev Contract to track richest owner and name and take ownership by paying cost
contract Rich {
  string public richest = ""; // Name of richest
  uint public cost = 0.001 ether; // Cost to take ownership
  address payable public currentOwner; // Current richest owner

  // Event to emit on owner change
  event NewRichest(address indexed to, uint cost);

  // On deployment
  constructor() {
    // Set initial richest to Anish
    richest = "Anish Agnihotri";
    currentOwner = msg.sender;
  }

  // @dev take ownership and become the richest
  // @param _name to set as richest
  function takeOwnership(string calldata _name) external payable {
    require(msg.value == cost, "Rich: Insufficient paid value"); // Require payment
    require(msg.sender != currentOwner, "Rich: Cannot be current owner"); // Ensure no duplicacy

    currentOwner.transfer(msg.value); // Transfer fees to old owner
    richest = _name; // Update name of richest
    currentOwner = msg.sender; // Change current owner
    cost = cost * 3 / 2; // Multiply cost of ownership by 1.5

    // Emit new owner event
    emit NewRichest(msg.sender, cost);
  }
}