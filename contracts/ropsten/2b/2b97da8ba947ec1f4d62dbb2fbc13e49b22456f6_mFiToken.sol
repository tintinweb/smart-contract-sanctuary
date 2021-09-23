/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

//SPDX-License-Identifier: UNLICENSED
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract mFiToken {
    uint256 public count;
    uint256 public lastExecuted;
  
    struct User{
      uint amount;
      address user;
      
    }
    //User[] public users;
    constructor(address _random){}

     
     mapping(address => User) userStructs;
     address[] public userAddresses;
    
    function request(uint _requestAmount, address _user) external {

    userStructs[msg.sender].amount = _requestAmount;
    
    userStructs[msg.sender].user = _user;
    
    userAddresses.push(msg.sender);
    
    }
    
    function zero(uint amount) external {
    require(((block.timestamp - lastExecuted) > 50), "Counter: increaseCount: Time not elapsed");
    
    if(userAddresses.length != 0){
       
    } else {
    count += amount;
    lastExecuted = block.timestamp;
    }
    }
    /*
    function increaseCount(uint amount) external {
       require(((block.timestamp - lastExecuted) > 180), "Counter: increaseCount: Time not elapsed"); 
    count += amount;
    lastExecuted = block.timestamp;
     }

    function getAllUsers() external view returns (address[] memory) {
       return userAddresses;
    }
  /*  
    // do we have to mint fixed amount of Tokens or as much as we wants???
    function mint(uint mintAmount) external {
       
       _mint(msg.sender, mintAmount);
    }
    
    function burn(uint burnAmount) external {
        _burn(msg.sender, burnAmount);
    }
*/
}