/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

// File: contracts/LOTTO2.sol



pragma solidity >=0.7.0 <0.9.0;

contract Whitelist {

    address owner;

    mapping(address => bool) whitelistedAddresses;

    constructor() {
      owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "Ownable: caller is not the owner");
      _;
    }

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address], "Whitelist: You need to be whitelisted");
      _;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
      whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    function exampleFunction() public view isWhitelisted(msg.sender) returns(bool){
      return (true);
    }

}