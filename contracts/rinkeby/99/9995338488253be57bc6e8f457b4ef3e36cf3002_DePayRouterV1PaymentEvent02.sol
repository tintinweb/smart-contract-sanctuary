/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// Root file: contracts/DePayRouterV1PaymentEvent02.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6 <0.9.0;
pragma abicoder v2;

contract DePayRouterV1PaymentEvent02 {

  // The payment event.
  event Payment(
    address indexed sender,
    address payable indexed receiver,
    uint256 indexed amount,
    address token
  );

  // Indicates that this plugin does not require delegate call
  bool public immutable delegate = false;
  
  // Address of the router to make sure nobody else 
  // can call the payment event
  address public immutable router;

  // Pass the DePayRouterV1 address to make sure
  // only the original router can call this plugin.
  constructor (
    address _router
  ) {
    router = _router;
  }

  function execute(
    address[] calldata path,
    uint[] calldata amounts,
    address[] calldata addresses,
    string[] calldata data
  ) external payable returns(bool) {
    require(msg.sender == router, 'Only the DePayRouterV1 can call this plugin!');
    emit Payment(
      addresses[0], // sender
      payable(addresses[addresses.length-1]), // receiver
      amounts[1], // amount
      path[path.length-1] // path
    );
    return true;
  }
}