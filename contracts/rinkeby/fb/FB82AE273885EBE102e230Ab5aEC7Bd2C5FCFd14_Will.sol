/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Will {
    address _admin;
    mapping(address => address) _heirs;
    mapping(address => uint) _balance;
    event Create(address indexed owner,address indexed heir,uint amount);
    event Deceased(address indexed owner,address indexed heir,uint amount);
    
    constructor(){
        _admin = msg.sender;
    }
    
    function create(address heir) public payable {
        require(msg.value > 0,"amount is zero");
        require(_balance[msg.sender] <= 0, "already exists");
        
        _heirs[msg.sender] = heir;
        _balance[msg.sender] = msg.value;
        emit Create(msg.sender,heir,msg.value);
    }
    
    function deceased(address owner) public {
        require(msg.sender == _admin, "unauthorized");
        require(_balance[owner] > 0 ,"no testament");
        
        emit Deceased(owner, _heirs[owner], _balance[owner]);
        payable(_heirs[owner]).transfer(_balance[owner]);
        _heirs[owner] = address(0);
        _balance[owner] = 0;
        
    }
    
    function contracts(address owner) public view returns(address heir,uint balance){
        return (_heirs[owner],_balance[owner]);
    }
}