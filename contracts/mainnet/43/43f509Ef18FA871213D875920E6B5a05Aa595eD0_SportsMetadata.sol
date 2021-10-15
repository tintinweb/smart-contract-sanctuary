// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SportsMetadata {

  string[] private cities = [
    'Arizona',
    'Atlanta',
    'Baltimore',
    'Buffalo',
    'Carolina',
    'Cincinnati',
    'Chicago',
    'Cleveland',
    'Dallas',
    'Denver',
    'Detroit',
    'Houston',
    'Green Bay',
    'Indianapolis',
    'Los Angeles',
    'Jacksonville',
    'Minnesota',
    'Kansas City',
    'New Orleans',
    'Las Vegas',
    'New York',
    'Los Angeles',
    'Philadelphia',
    'Miami',
    'San Francisco',
    'New England',
    'Seattle',
    'Tampa Bay',
    'Pittsburgh',
    'Washington',
    'Tennessee',
    'Hamilton',
    'Montreal',
    'Ottawa',
    'Toronto',
    'Vancouver',
    'Calgary',
    'Edmonton',
    'Regina',
    'Winnipeg'
  ];

  string[] private sports = [
    "Football",
    "Basketball",
    "Soccer",
    "Baseball",
    "Hockey",
    "Cricket",
    "Rugby Union",
    "Field Hockey",
    "Volleyball",
    "Rugby League"
  ];

  function sportName(uint256 tokenId) public view returns(string memory) {
    return sports[sportId(tokenId)];
  }

  function cityName(uint256 tokenId) public view returns(string memory) {
    return cities[cityId(tokenId)];
  }

  function sportId(uint256 tokenId) public pure returns(uint8) {
    return uint8(tokenId >> 24);
  }

  function cityId(uint256 tokenId) public pure returns(uint16) {
    return uint16(tokenId >> 32);
  }

  function getCities() public view returns(string[] memory) {
    return cities;
  }

  function getSports() public view returns(string[] memory) {
    return sports;
  }
}