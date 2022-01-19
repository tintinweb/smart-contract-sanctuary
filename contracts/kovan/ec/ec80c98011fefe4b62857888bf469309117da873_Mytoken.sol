/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Mytoken{

    string public constant name = "Dakul";
    string public constant symbol = "DKL";
    uint8 public constant decimals = 18;

    //Event to listen on
    event Transfer(address indexed from, address indexed to, uint tokens);

    //Event for delegation approval
    event Approve(address indexed tokenOwner, address indexed spender, uint tokens );


    //Address and balances
    mapping(address=>uint256) balances;
    //For delegation purpose
    mapping(address => mapping(address=>uint256)) allowed;


    //Owner of the smart contract
    address owner;

    uint256 totalSupply_;
    constructor(uint256 supply){
        //Assigning the owner
        owner = msg.sender;
        totalSupply_ = supply;
        //Assigning the deployer all the token
        balances[msg.sender] = totalSupply_;
        
    }

    //Function to get the total total_supply
    function totalSupply() public view returns(uint256){
        return totalSupply_;
    }

    //Function to get balance of the owner
    function balanceOf()public view returns(uint256){
        return balances[owner];
    }

    //Transfer ownership
    function transferOwnership(address toOwner) public returns(bool){
        require(msg.sender == owner,"You do not have the privilege to transfer ownership");
        owner = toOwner;
        return true;
    }

    //Transfer token to another account
    function transfer(address toAccount, uint256 amount) public returns(bool){
        require(amount <= balances[msg.sender]);
        balances[toAccount] = balances[toAccount] + amount; //Incrementing balance
        balances[msg.sender] = balances[msg.sender] - amount;
        emit Transfer(msg.sender,toAccount,amount);
        return true;
    }

    //Delegation approval 
    function approve(address delegate, uint256 tokens)public returns(bool) {
        //Allowing delegation ability to the address
        allowed[msg.sender][delegate] = tokens;
        emit Approve(msg.sender, delegate, tokens);
        return true;
    }

    //Function to get delegated amount to an address
    function allowance(address tokenOwner, address delegate) public view returns(uint){
        return allowed[tokenOwner][delegate];
    }

    //Transfer token by Delegated account
    function transferFrom(address tokenOwner,address destination, uint256 tokens)public returns(bool){
        require(tokens <= balances[tokenOwner],"Insufficient balance");
        require(tokens <= allowed[tokenOwner][msg.sender],"Token amount exceeds approved delgated amount");

        balances[tokenOwner] = balances[tokenOwner] - tokens;
        allowed[tokenOwner][msg.sender] = allowed[tokenOwner][msg.sender] - tokens;
        balances[destination] = balances[destination] + tokens;
        
        emit Transfer(tokenOwner,destination,tokens);
        return true;
    }

}