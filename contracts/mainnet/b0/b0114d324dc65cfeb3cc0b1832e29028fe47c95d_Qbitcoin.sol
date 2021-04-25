/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.6.6;

contract Qbitcoin {
    string public name = "Qbitcoin";
    string public symbol = "Qbit";
    uint public decimals = 6;
    uint public totalSupply = 412000000 * 10 ** decimals;
    
    mapping (address => uint) public balanceOf;
    
    constructor () public {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer (address to, uint value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Not enough funds!"); 
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }
}