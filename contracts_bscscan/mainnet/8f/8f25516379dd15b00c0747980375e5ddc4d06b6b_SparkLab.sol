/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/
/*
███████╗██████╗  █████╗ ██████╗ ██╗  ██╗██╗      █████╗ ██████╗                ██████╗ ███████╗███████╗██╗ ██████╗██╗ █████╗ ██╗     
██╔════╝██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║     ██╔══██╗██╔══██╗              ██╔═══██╗██╔════╝██╔════╝██║██╔════╝██║██╔══██╗██║     
███████╗██████╔╝███████║██████╔╝█████╔╝ ██║     ███████║██████╔╝    █████╗    ██║   ██║█████╗  █████╗  ██║██║     ██║███████║██║     
╚════██║██╔═══╝ ██╔══██║██╔══██╗██╔═██╗ ██║     ██╔══██║██╔══██╗    ╚════╝    ██║   ██║██╔══╝  ██╔══╝  ██║██║     ██║██╔══██║██║     
███████║██║     ██║  ██║██║  ██║██║  ██╗███████╗██║  ██║██████╔╝              ╚██████╔╝██║     ██║     ██║╚██████╗██║██║  ██║███████╗
╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝                ╚═════╝ ╚═╝     ╚═╝     ╚═╝ ╚═════╝╚═╝╚═╝  ╚═╝╚══════╝
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*
SparkLab - Official
https://www.thesparklab.io
https://t.me/SparkLabOfficialChannel

More than a simple price-tracking platform,
SparkLab is aiming to help traders and investors
to spot opportunities across the Binance Smart Chain
while always keeping an eye on their investments.

@SparkLabChina
@SparkLabJapan
*/

contract SparkLab {
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "SparkLab";
    string public symbol = "SPARK";
    uint public decimals = 18;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
}