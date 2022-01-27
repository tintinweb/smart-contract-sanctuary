/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.10;


contract Mytoken  {
 
    mapping (address => uint) public myWallet;
    mapping (address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 500000000 *10 **18;
    uint public decimal ;
    string public name ;
    string public symbol;
   

    event Transfer(address indexed _from, address indexed _to, uint _val);
    event Approval(address indexed _owner,address indexed _spender, uint _val);
 

    constructor(){


        name = "IU Uaena"; // Sets the name of the token, i.e Ether
        symbol = "UAN"; // Sets the symbol of the token, i.e ETH
        decimal = 18; // Sets the number of decimal places

        myWallet[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);


       
    }

    function getMywallet(address _owner) public view returns(uint) {

            return myWallet[_owner];

    }

    function transfer(address _to, uint _val) public returns(bool){

        require(getMywallet(msg.sender) >= _val, "balance too low");
        myWallet[_to] += _val;
        myWallet[msg.sender] -= _val;
        emit Transfer(msg.sender,_to,_val);
        return true;
    }


    function transferFrom(address _from, address _to , uint _val) public returns(bool){

        require(getMywallet(_from) >= _val ,"balance too low");
        require(allowance[_from][msg.sender] >= _val, "allownce too low");
        myWallet[_from] -= _val;
        myWallet[_to] += _val;
        emit Transfer(_from,_to,_val);
        return true;
    }

    function approve(address _spender,uint _val) public returns(bool){

      allowance[msg.sender][_spender] = _val;
      emit Approval(msg.sender,_spender,_val);
      return true;
    }



}