pragma solidity 0.4.25;

/*
 * Anonplayer : Who will win the League of Legends World Championship 2018 ?(Liquid|100 Thieves)
 * betting time ends 1535979600 UNIX
 * main contract at 0x328FB7305CE97791a46B5a707f395C14a6f2d11c
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

contract Disagree {
  function() public payable {
    if (!(0x328FB7305CE97791a46B5a707f395C14a6f2d11c).call.value(msg.value)(bytes4(keccak256("disagree()")))) revert();
  }
}