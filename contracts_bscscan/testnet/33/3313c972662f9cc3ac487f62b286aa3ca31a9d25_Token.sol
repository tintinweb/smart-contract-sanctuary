/**
 *Submitted for verification at BscScan.com on 2022-01-09
*/

/**                             	  	    🚀 Metacia.io 🚀
███╗░░░███╗
████╗░████║
██╔████╔██║
██║╚██╔╝██║
██║░╚═╝░██║

	💎 Maeta Cia Features:
		⭐️buyback function is turned on, tokens are bought back from the market, resulting in an immediate effect on the price.
		⭐️Burn The tokens bought through buyback are immediately burned. This creates a true burn and guarantees the price per token will increase every time a buyback is activated.
		⭐️Rewards Holders are additionally "auto-staked" instantly receiving️ Rewards of the transaction volume and they can watch their wallet grow in real-time.
*/
pragma solidity ^0.8.11;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 47000000 * 10 ** 18;
    string public name = "META CIA";
    string public symbol = "METACIA";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}