pragma solidity 0.4.25;

/*
 * Anonplayer : What best describes Nitin ?(deep|dweep)
 * betting time ends 1539561600 UNIX
 * main contract at 0xfC33A9eB8E4cA863b64ea0975cEbd716d24DC9D7
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0xfC33A9eB8E4cA863b64ea0975cEbd716d24DC9D7).call.value(msg.value)(bytes4(keccak256("disagree()")))) revert();
  }
}