pragma solidity 0.4.25;

/*
 * Anonplayer : Will Brett Kavanaugh be appointed to the Supreme Court ? 
 * betting time ends 1542108097 UNIX
 * main contract at 0xA4735b86aedFf304B351029245ff0780b442e09D
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0xA4735b86aedFf304B351029245ff0780b442e09D).call.value(msg.value)(bytes4(keccak256("disagree()")), msg.sender)) revert();
  }
}