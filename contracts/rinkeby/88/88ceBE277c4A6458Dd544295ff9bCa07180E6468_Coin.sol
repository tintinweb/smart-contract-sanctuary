/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Coin {
    
    //variables
    
    string public name;
    string public tiker;
    uint public total_supply;
    uint public Circulatory_supply;
    address public minter;
    mapping(address => uint) public balance;
    mapping(address => uint) allowance;
    
    
    
    //events
    
    event transfer(address indexed _from, address indexed to,uint amount);
    event approved (address indexed reciver, uint amount);
    event allowance_added (address indexed for_, uint amount);
    event allowance_request(address indexed from_,uint amount);
    event allowance_approved(address indexed for_,uint amount);
    
    
    //functions
    
    constructor(string memory name_, string memory symbol, uint supply_, uint decimals){
        
        minter = msg.sender;
        name = name_;
        tiker = symbol;
        total_supply = supply_ * (10 ** decimals);
        mint();
    }
    
    modifier restricted{
        
        require(msg.sender == minter, "only minter can perform this function");
        _;
    }
    
        
    //internal minting function    
        
    function mint() internal{
       balance[minter] = total_supply;
    }
    
    
    
    
    //to view he circulatory supply
    
    function transfer_(address sender, address reciver, uint amount) internal{
        balance[sender] -= amount;
        balance[reciver] += amount;
    }
    
    
    function CirculatorySupply() external view returns(uint){
        return total_supply - balance[minter] ;
        
    }
    
    
    
    
    // to transfer funds between accounts
    
    function Transfer(address _address, uint amount) public returns(bool success){
        require(balance[msg.sender] >= amount, "Insufficient balance");
        
        transfer_(msg.sender, _address, amount);
        return true;
    }
    
    
    
    
    
    //For teh minter to add allowances
    
    function AddAlowance(address _address,uint  amount) public restricted{ 
        
        allowance[_address] += amount;
        emit allowance_added(_address, amount);
        
    }
    
    
    
    //For allowance holders to request allowance
    
    function RequestAllowance(uint amount) public{
        require(allowance[msg.sender] >= amount, "You have no allowance to request.");
        
        emit allowance_request(msg.sender, amount);
        
    } 
    
    
    
    //For the minter to approve the allowance requests
    
    function Approve(address reciever, uint amount) public restricted returns(bool){
        
        transfer_(minter, reciever, amount);
        allowance[reciever] -= amount;
        
        emit allowance_approved(reciever, amount);
        return true;
    }
    
    
    
}