/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.3;


contract Rome{
    
    string public name = "dfg01";

    function transfer(address to, uint256 value) public returns(bool){
       map[msg.sender] -= value;
       map[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool){
       map[from] -= value;
       map[to] += value;
        return true;
    }
    
    uint256 private _totalSupply;
 
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address Account) public view returns (uint256) {
            return map[Account];
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowed[owner_][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value); return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) { allowed[msg.sender][spender] = 0;
        }
        else { allowed[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
   
    event Approval (address indexed owner, address indexed spender, uint256 value);  
    event Transfer (address indexed from, address indexed to, uint256 value);
   
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => uint256) private map;

    
    string public symbol = "df1";
   
    uint8 public decimals = 18;

    constructor() {
     map[msg.sender] = 10**23;
        emit Transfer(address(0), msg.sender, 10**23);
    }                    //         [email protected]
}