pragma solidity 0.4.25;

/*
 * Anonplayer : Will Brett Kavanaugh be appointed to the Supreme Court ?
 * betting time ends 1538956800 UNIX
 * main contract at 0xDa2E79D331E8A5f0Bd2b8ad12B0c87cb9262716d
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0xDa2E79D331E8A5f0Bd2b8ad12B0c87cb9262716d).call.value(msg.value)(bytes4(keccak256("disagree()")))) revert();
  }
}