/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

contract TendieToken {
    /*
    *
    *   Soon, may the tendie man come, to send our rocket into the sun,
    *   one day when the trading is done, we'll take our gains and go.
    *
    */
    
    address private minter;
    
    mapping (address => uint256) public balanceOf;  // Track how many tendies are owned by each address.
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = "Tendie Token";
    string public symbol = "TDT";
    uint8 public decimals = 21;

    uint256 public totalSupply = 69 * (uint256(10) ** decimals);

    constructor() public {
        minter = msg.sender;        
        balanceOf[msg.sender] = totalSupply;  // assign all tendies to contract creator
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct tendies from sender's balance
        balanceOf[to] += value;          // add tendies to recipient's balance
        emit Transfer(msg.sender, to, value);
        
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function withdraw(uint amount)  public returns (bool success) {
        require(msg.sender == minter);
        if ( amount > address(this).balance ) {
            amount = address(this).balance;
        }
        msg.sender.transfer(amount);
        
        return true;
        
    }
}