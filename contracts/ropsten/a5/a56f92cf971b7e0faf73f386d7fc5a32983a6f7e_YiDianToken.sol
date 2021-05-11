/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

pragma solidity >=0.4.24;

contract YiDianToken {

    string public constant name = "YiDian Token";
    string public constant symbol = "YIDIAN";
    uint8 public constant decimals = 18;  // 18 is the most common number of decimal places
    uint _totalSupply;

    // Balances for each account stored using a mapping
    mapping(address => uint256) balances;

    // Owner of the account approves the allowance of another account
    // Create an allowance mapping
    // The first key is the owner of the tokens
    // In the 2nd mapping, its says who can spend on your behalf, and how many
    // So, we are creating a mapping, where the kep is an address,
    // The value is further a mapping of address to amount
    mapping(address => mapping (address => uint256)) allowance;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    // Called automatically when contract is initiated
    // Sets to total initial _totalSupply, as per the input argument
    // Also gives the initial supply to msg.sender...who creates the contract
    constructor(uint amount) public {
        _totalSupply = amount;
         balances[msg.sender] = amount;
    }

    // Returns the total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Get the token balance for account `tokenOwner`
    // Anyone can query and find the balance of an address
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // Transfer the balance from owner's account to another account
    // Decreases the balance of "from" account
    // Increases the balance of "to" account
    // Emits Transfer event
    function transfer(address to, uint tokens) public returns (bool success) {
        if(tokens < 1){
            revert("Not enough Ether provided.");
        }
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Send amount of tokens from address `from` to address `to`
    // The transferFrom method is used to allow contracts to spend
    // tokens on your behalf
    // Decreases the balance of "from" account
    // Decreases the allowance of "msg.sender"
    // Increases the balance of "to" account
    // Emits Transfer event
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from] - tokens;
        allowance[from][msg.sender] = allowance[from][msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    // Approves the `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // So the msg.sender is approving the spender to spend these many tokens
    // from msg.sender's account
    // Setting up allowance mapping accordingly
    // Emits approval event
    function approve(address spender, uint tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
}