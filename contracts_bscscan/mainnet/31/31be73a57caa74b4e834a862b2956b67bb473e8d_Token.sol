/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

pragma solidity ^0.8.9;  /* set to version of Solana Used */

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000 * 10 ** 18; /* total supply of tokens this is set to 1 trillion */
    string public name = "Trevors Poo coin";  /* Long form Token Name */
    string public symbol = "TPC";  /* Abbriviated token id/symbol */
    uint public decimals =18;  /* decimals */
    
     /* event definitions */
    
    event Transfer(address indexed from, address indexed to, uint value); 
    event Approval(address indexed owner, address indexed spender, uint value);
    
     /* begin */
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balancesOf(address owner) public view returns(uint) {
        return balances[owner];
    }
      /* more advanced section */
      
    function transfer(address to, uint value) public returns(bool) {
        require(balancesOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     /* dedicated transfer section */
     function transferFrom(address from, address to, uint value) public returns(bool) {
         require(balancesOf(from) >= value, 'balance too low');
         require(allowance[from][msg.sender] >= value, 'allowance too low');
         balances[to] += value;
         balances[from] -= value;
         emit Transfer(from, to, value);
         return true;
     }
     
     function approved(address spender, uint value) public returns(bool) {
         allowance[msg.sender][spender] = value;
         emit Approval(msg.sender, spender, value);
         return true;
     }
     
    
}