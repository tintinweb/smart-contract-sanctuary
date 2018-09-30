pragma solidity ^0.4.18;


library KudosStructs {
  struct Gratitude {
    uint256 kudos;
    string message;
    address from;
  }

  struct Result {
    uint256 kudos;
    address member;
  }
}