pragma solidity 0.4.25;

/*
 * Anonplayer : Will Brett Kavanaugh be appointed to the Supreme Court ? 
 * betting time ends 1541908097 UNIX
 * main contract at 0x09dc77474762f8EC90Cb730eDc072080F218896D
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0x09dc77474762f8EC90Cb730eDc072080F218896D).call.value(msg.value)(bytes4(keccak256("disagree()")), msg.sender)) revert();
  }
}