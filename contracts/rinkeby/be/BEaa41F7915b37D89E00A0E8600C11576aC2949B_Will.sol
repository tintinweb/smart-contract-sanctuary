/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Will{
    address _admin;
    mapping(address =>address) _heir;
    mapping(address=> uint) _balances;
    event Create(address indexed owner,address indexed heir,uint amount);
    event Deceased(address indexed owner,address indexed heir,uint amount);

    constructor(){
        _admin =msg.sender;
    }

    function create(address heir) public payable{
        require(msg.value >0 ,"amount is zero");
        require(_balances[msg.sender] <= 0 ,"already exists");


        _heir[msg.sender]=heir;
        _balances[msg.sender]=msg.value;
        emit Create(msg.sender,heir,msg.value);
    }
    function deceased(address owner) public payable{
        require(msg.sender== _admin ,"unauthorized");
        require(_balances[owner]>0,"no testament");

        emit Deceased(owner,_heir[owner],_balances[owner]);
        payable(_heir[owner]).transfer(_balances[owner]);
        _heir[owner]=address(0);
        _balances[owner]=0;
    }

    function contracts(address owner) public view returns(address heir,uint balances){
        return(_heir[owner],_balances[owner]);
    }
}