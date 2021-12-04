/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.8.7;

contract NftLeaks {
    mapping(address => uint) public balances;
    uint public totalSupply = 100000000000000 *10 ** 0;
    string public name = "NFT LEAKS";
    string public symbol = "NFTLEAK";
    uint public decimal = 0;

event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint){
    return balances[owner]; 
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
balances[msg.sender] -= value;
emit Transfer(msg.sender, to, value);
return true;
    }
}