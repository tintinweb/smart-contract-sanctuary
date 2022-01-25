/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

//SPDX-License-Identifier:MIT
pragma solidity = 0.8.1;

contract Trust{
    mapping(address => uint) public amounts;
    mapping(address => uint) public maturities;
    mapping(address => bool) public paid;
    address public admin;

    constructor(){
        admin = msg.sender;
    }

    function addKid(address kid, uint timeToMaturity) external payable{
        require(msg.sender == admin , "only admin is allowed to ad kids");
        require(amounts[kid] == 0, "the kid already exists");
        amounts[kid] = msg.value;
        maturities[kid] = block.timestamp + timeToMaturity;
    }


    function withdraw() external {
        require(amounts[msg.sender] > 0, "kid not in the list to withdraw");
        require(maturities[msg.sender] >= block.timestamp, "Too early to withdraw");
        require(paid[msg.sender] == false, "Kid has already withdrawn");
        paid[msg.sender] = true;
        payable(msg.sender).transfer(amounts[msg.sender]);
    }
    
    
}