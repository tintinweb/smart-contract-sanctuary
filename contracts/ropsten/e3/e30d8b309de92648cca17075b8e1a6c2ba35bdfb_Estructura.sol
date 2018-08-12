pragma solidity^0.4.8;

contract Estructura {
struct Bid {
  address bidOwner;
  uint bidAmount;
  bytes32 nameEntity;
}

mapping(bytes32 => Bid[]) highestBidder;

function getBidCount(bytes32 name) public constant returns (uint) {
    return highestBidder[name].length;
}

function getBid(bytes32 name, uint index) public constant returns (address, uint, bytes32) {
    Bid storage bid = highestBidder[name][index];

    return (bid.bidOwner, bid.bidAmount, bid.nameEntity);
}

}