/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.8.7;

contract AndyToken{

    string public name = "Andrew Testing Token";
    string public symbol = "ATT";
    address public owner;
    uint public totalSupply = 50000;
    mapping(address=>user) public userBal;

    constructor(){
        owner = msg.sender;
    }

    struct user{

        uint balance;

    }

    

    function transfer(address to, uint amount) external{

        require(userBal[owner].balance >= amount, "Insufficient Balance");
        
        userBal[owner].balance -= amount;
        userBal[to].balance += amount;

    }

    function searchUserBalance( address usr) external view returns(uint){
        return userBal[usr].balance;
    }

    function currentUserBalance() external view returns(uint){
        return userBal[owner].balance;
    }

    function addTokensToTS(uint amount) external{
        totalSupply += amount;
    }

    function burnTokenFromTS(uint amount) external{
        totalSupply -= amount;
    }


    //allocate token manually from total supply
    function manualGiftToken(address to, uint amount) external {
        require(totalSupply >= amount, "Not enough coins in supply!");
        userBal[to].balance += amount;
        totalSupply -= amount;

    }

}