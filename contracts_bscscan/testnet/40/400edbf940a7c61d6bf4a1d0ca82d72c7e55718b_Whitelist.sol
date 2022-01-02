/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Whitelist {

    address owner;

    mapping(address => bool) whitelistedAddresses;
    mapping(address => uint256) public desposits;

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

    function desposit(address payee) public isWhitelisted(msg.sender) payable {
      uint256 amount = msg.value;
      desposits[payee] = desposits[payee] + amount;
    }

    function withdraw(address payable payee) public onlyOwner {
      uint256 payment = desposits[payee];
      desposits[payee] = 0;
      payee.transfer(payment);
    }

}