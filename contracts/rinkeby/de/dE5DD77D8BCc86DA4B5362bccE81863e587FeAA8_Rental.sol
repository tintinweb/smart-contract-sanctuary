/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity >=0.7.0 <0.9.0;

contract Rental {
    address payable []  public  houseOwners;
    
    
    constructor(address payable owner1, address payable owner2)  {
        houseOwners.push(owner1);
        houseOwners.push(owner2);
    }

    receive() external payable { 
        uint amount = msg.value;
        houseOwners[0].transfer(amount/2);
        houseOwners[1].transfer(amount/2);
    }
}