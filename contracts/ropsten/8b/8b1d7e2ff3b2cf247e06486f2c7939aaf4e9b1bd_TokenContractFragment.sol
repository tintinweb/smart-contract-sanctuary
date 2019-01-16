pragma solidity ^0.4.16;




contract TokenContractFragment {

     string public constant name = "Token Name testovoe";
    string public constant symbol = "KAA";
    uint8 public constant decimals = 18;  
    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account

 
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
       // Transfer(msg.sender, to, tokens);
        return true;
    }
 
    constructor() public {
        
        balances[msg.sender] = 10000000000000000000000;
    }

}