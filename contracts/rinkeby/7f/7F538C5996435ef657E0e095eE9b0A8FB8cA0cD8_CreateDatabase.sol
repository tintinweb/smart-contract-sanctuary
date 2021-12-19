pragma solidity >=0.7.0;

import './Database.sol';

contract CreateDatabase{
    address[] private databaseAddress;
    
     function createDatabase() public payable returns(uint) {
         Database BD = new Database (msg.sender); 
         databaseAddress.push (address(BD));
         return databaseAddress.length -1;
     }
     function getDatabase(uint id) public view returns(address) {
         return databaseAddress [id];
     }

}