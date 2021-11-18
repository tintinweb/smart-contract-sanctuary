/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// import "hardhat/console.sol"; 

/// @title A smartgraph to graph social relationships between addresses. 
/// @author MEM Protocol

contract MemSocialGraph {
  
  address[] followerArray;
  address[] followingArray;

  // every address needs to be mapped to a followerArray
  // and a followingArray
  // unsure of how "address => address[]" is going to work for now
  mapping(address => address[]) addressToFollowerArray;
  mapping(address => address[]) addressToFollowingArray;


  /// @notice modifiers to check/avoid unnecessary gas
  modifier followSelf(address _follower) {
    require(_follower != msg.sender);
    _;
  }

  // other modifiers?
  //

  // external vs. public
  // external seems to be better at returning larger data arrays
  // than public (costs less gas fees)

  // get list of addreses who you're following
  function getFollowingArray() external view returns (address[] memory) {
    return followingArray;
  }

  // follow function is if msg.sender wants to follow someone else
  function follow(address _followed) external followSelf(_followed) {
    // is this necessary?
    address[] storage currentFollowing = addressToFollowingArray[msg.sender];
    currentFollowing.push(_followed);
    addressToFollowingArray[msg.sender] = currentFollowing;

    // update _followed addresses followerArray
    // use mapping to point to _followed's followerArray
    // so you can update the other persons followerArray
    address[] storage currentFollower = addressToFollowerArray[_followed];
    currentFollower.push(msg.sender);
    addressToFollowerArray[_followed] = currentFollower;
  }

  function getNumberOfFollowing() public view returns (uint256) {
    return followingArray.length;
  }

  function getFollowing(address _address)
    public
    view
    returns (address[] memory)
  {
    return addressToFollowingArray[_address];
  }

  function getFollowers(address _address)
    public
    view
    returns (address[] memory)
  {
    return addressToFollowerArray[_address];
  }

  // function getListOfFollowAddresses(address _address) public view {}

  // function getListOfFollowersAddresses

  // function getTotalFollowers

  // function unfollow
}