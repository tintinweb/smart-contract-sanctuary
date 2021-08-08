/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PseudoTicket {
    int price;
    
    int ticketsSold;
    
    int ticketsTotal;
    
    int tokenId;
    
    mapping (address => string) private userNames;
    mapping (string => address) private userAddresses;
    mapping (int => address) private userTokenIds;
    
    
    constructor () {
        price = 1234567890 wei;
        ticketsSold = 0;
        ticketsTotal = 10000;
        tokenId = 0;
    }
    
    
    function setPrice(int _price) public {
        price = _price;
    }

    function getUserNameById(int _id) public view returns (string memory) {
        return userNames[userTokenIds[_id]];
    }
    
    function getUserAddressById(int _id) public view returns (address) {
        return userTokenIds[_id];
    }
    
    
    function getUserNameByAddress (address _userAddress) public view returns (string memory) {
      return userNames[_userAddress];
    }
    
    function getUserAddressByName (string memory _userName)  public view returns (address) {
      return userAddresses[_userName];
    }
    

    function getPrice(address _eventContractAddress) public view returns (int) {
        require(_eventContractAddress != address(0), "Event can not be empty");
        return price;
    }
    
    function buyTicket (address _eventContractAddress, string memory _userName) public payable returns (int) {
      
      require(_eventContractAddress != address(0), "Event can not be empty");
      
      int priceLess = price * 95 / 100;
      
      require(msg.sender != address(0), "Address can not be empty");
      require((int(msg.value) >= priceLess), "Amount is not correct");
      require (ticketsSold <  ticketsTotal, "All tickets are sold!" );
      
      ticketsSold++;
      tokenId++;
      
      userNames[msg.sender] = _userName;
      userAddresses[_userName] = msg.sender;
      userTokenIds[tokenId] = msg.sender;

      return tokenId;
    }
}