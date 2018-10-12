pragma solidity 0.4.25;

/*
 * Anonplayer : What best describes Nitin ?(deep|dweep)
 * betting time ends 1537401600 UNIX
 * main contract at 0xE99CF587CFb4CA9aCed749775F7a036DA625256b
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0xE99CF587CFb4CA9aCed749775F7a036DA625256b).call.value(msg.value)(bytes4(keccak256("disagree()")))) revert();
  }
}