/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

// File: contracts/Whitelist.sol

/**
 *Develop by CPTRedHawk
 *
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.7;


contract Whitelist {
    
    uint256 private withdrawableBalance;
    address owner;
    address[] public whitelister;

    mapping(address => bool) whitelistedAddresses;
    

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

    
    function manager() public view returns(address){ 
        return owner; }


    function withdrawLockedAvax(address payable to) external onlyOwner() {
        withdrawableBalance = address(this).balance;
        uint256 amount = withdrawableBalance;
        withdrawableBalance = 0;
        to.transfer(amount);
       
    }

    function enter() public isWhitelisted(msg.sender) payable {
        require(msg.value > 1 ether);
        whitelister.push(msg.sender);
    }

}