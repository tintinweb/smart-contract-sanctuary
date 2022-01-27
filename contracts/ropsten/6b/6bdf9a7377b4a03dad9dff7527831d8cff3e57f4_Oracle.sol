/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Oracle {
struct offer{
    string title;
    string description;
    uint256 reward;
    uint256 numberOfOracles;
    uint256 oracleLockValue;
    uint256 deadline;
    uint256 id;
}

struct moreInfo {
    address owner;
}
mapping(uint256 => offer) offers;
mapping(uint256 => moreInfo) moreinfo;
uint256 offersCount;
uint256 activeOffersCount;

event newOffer(offer);

function createOffer(string calldata title,
    string calldata description,
    uint256 reward,
    uint256 numberOfOracles,
    uint256 oracleLockValue,
    uint256 activeDays) public returns (uint256)  {
        offer storage o = offers[++offersCount];
        o.title = title;
        o.description = description;
        o.reward = reward;
        o.numberOfOracles = numberOfOracles;
        o.oracleLockValue = oracleLockValue;
        o.deadline = block.timestamp + (activeDays * 24 * 60 * 60);
        o.id = offersCount;

        moreInfo storage i = moreinfo[offersCount];
        i.owner=msg.sender;
        activeOffersCount++;
        emit newOffer(o);
        return offersCount;
    }
function getOffer(uint256 number) public view returns (offer memory){
    return offers[number];

}
function getActiveOffers() public view returns (offer[] memory){
    offer[] memory activeoffers= new offer[](activeOffersCount);
    uint256 j = 0;
for (uint256 i = 0; i<= offersCount; i++) {
    if(block.timestamp < offers[i].deadline){
        activeoffers[j]=offers[i];
        j++;
    }
  
}
return activeoffers;
}
}