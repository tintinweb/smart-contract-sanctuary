/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.4 <0.9.0;

contract Storage {

    // Variables
    
    uint public totalSupply = 1000 * 10 ** 4;
    string public name = "meocoder Token";
    string public symbol = "MCTK";
    uint public decimals = 4;
    
    
    // Mappings
    
    mapping(address => uint) public blances;
    mapping(address => mapping(address => uint)) public allowance;
    
    // Event 
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    
    constructor(){
        blances[msg.sender] = totalSupply;
    }
    
    // Functions 
    
    function blanceOf(address owner) public view returns(uint){
        return blances[owner];
    }
    
    function transfer(address to, uint amount) public returns (bool) {
        require(blanceOf(msg.sender) >= amount, "So du khong du");
        blances[to] += amount;
        blances[msg.sender] -= amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool){
        require(blanceOf(from) >= amount, "So du khong du");
        require(allowance[from][msg.sender] >= amount, "So du khong du");
        blances[to] += amount;
        blances[msg.sender] -= amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

}