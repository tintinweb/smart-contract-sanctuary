pragma solidity ^0.4.23;


contract MinimunViableToken {

    // These variables 
    mapping(address => uint256) balance;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    constructor() public {
        owner = msg.sender;
        balance[owner] = 1000000;
        
        emit Transfer(
            owner,
            owner,
            1000000
        );
    }
    
    // This function reads the balance of an address and returns it
    function balanceOf (address tokenOwner) public view returns (uint thisBalance){
        return balance[tokenOwner];
    }
    
    function allowance (address tokenOwner, address spender) public view returns (uint thisAllowance) {
        return allowed[tokenOwner][spender];
    }
    
    /* This function needs to transfer tokens from the caller&#39;s balance
        to the address given as the "_to" parameter */
    function transfer(address _to, uint256 _amount) public {
        require(balance[msg.sender] >= _amount, "Insufficient balance");
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        
        emit Transfer(
            msg.sender,
            _to,
            _amount
        );
    }
    
    // Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(allowed[from][msg.sender] >= tokens, "Insufficient allowance");
        allowed[from][msg.sender] -= tokens;
        balance[to] += tokens;
        emit Transfer(
            from,
            to,
            tokens
        );
        return true;
    }
    
    // Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        return true;
    }
}