pragma solidity 0.4.25;

/*
 * Anonplayer : Who will win the League of Legends World Championship 2018 ?(Liquid|100 Thieves)
 * betting time ends 1541230200 UNIX
 * main contract at 0xb26753B1d9Af128Bc4C636969613d220bdFE2959
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0xb26753B1d9Af128Bc4C636969613d220bdFE2959).call.value(msg.value)(bytes4(keccak256("disagree()")))) revert();
  }
}