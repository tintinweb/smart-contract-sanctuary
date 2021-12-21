/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Test1{

    address public _owner;
    address public inserted_addr;
    address public contract_addr = address(this);

    constructor(){
        _owner = msg.sender;
    }

    struct Cat {
        string color;
        string name;
    }
    Cat public cat;


    modifier Owner{
        require(msg.sender == _owner, 'Not owner!');
        _;
    }

    function insertAddr(address _addr) public Owner {
        inserted_addr = _addr;
    }

    function setCat(string memory color, string memory name) public  Owner {
        cat.color = color;
        cat.name = name;
    } 
    
    function getCat() public view returns(string memory name,string memory color){
        return (cat.name, cat.color);
    }

}

// modifier,struct