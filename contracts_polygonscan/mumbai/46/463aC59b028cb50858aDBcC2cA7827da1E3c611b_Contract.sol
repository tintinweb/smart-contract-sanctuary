/**
 *Submitted for verification at polygonscan.com on 2021-08-18
*/

pragma solidity ^0.6.12;

contract Contract {

  struct Giveaway {
    address creator;
    uint256 tweetId;
    address[] participants;
    address contractAddress;
    uint256 tokenId;
  }

  Giveaway[] public giveaways;

  mapping(address => string) public twitterOf;
  mapping(string => address) public addressOf;

  function createGiveaway(address creator, uint256 tweetId, address[] memory addresess, address contractAddress, uint256 tokenId) public returns(bool) {
    giveaways.push(Giveaway(creator, tweetId, addresess, contractAddress, tokenId));
    return true;
  }

  function joinGiveaway(uint256 giveawayId) public {
    require(msg.sender != giveaways[giveawayId].creator);
    giveaways[giveawayId].participants.push(msg.sender);
  }

}