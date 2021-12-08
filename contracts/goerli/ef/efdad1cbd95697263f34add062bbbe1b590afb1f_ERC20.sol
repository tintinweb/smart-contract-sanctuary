/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.8.0;

contract ERC20 {
    mapping(address => uint256) public balances;
    string public name;
    string public symbol;
    uint8 public decimals = 0;

    
    constructor() {
        name = "Vulnerable token";
        symbol = "VULN";
        balances[msg.sender] = 21_000_000;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        unchecked {
            balances[sender] = balances[sender] - amount;
        }
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}