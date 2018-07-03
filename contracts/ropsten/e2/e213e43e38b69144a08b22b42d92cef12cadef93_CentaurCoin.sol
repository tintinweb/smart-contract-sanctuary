pragma solidity ^0.4.23;

// Source:
// https://hashnode.com/post/how-to-build-your-own-ethereum-based-erc20-token-and-launch-an-ico-in-next-20-minutes-cjbcpwzec01c93awtbij90uzn
contract Token {

    /// @return total amount of tokens
    function totalSupply() public view returns (uint256 supply) {}

    /// @param owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address owner) public view returns (uint256 balance) {}

    /// @notice send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address to, uint256 value) public returns (bool success) {}

    /// @notice send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {}

    /// @notice `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address spender, uint256 value) public returns (bool success) {}

    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spend
    function allowance(address owner, address spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is Token {

    function transfer(address to, uint256 value) public returns (bool success) {
        // Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        // If your token leaves out totalSupply and can issue more tokens as time goes on,
        // you need to check if it doesn&#39;t wrap.
        // Replace the if with this one instead.
        // if (balances[msg.sender] >= value && 
        //     balances[to] + value > balances[to]) {
        if (balances[msg.sender] >= value && value > 0) {
            balances[msg.sender] -= value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else { 
            return false; 
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        // same as above. Replace this line with the following if you want to protect against 
        // wrapping uints.
        // if (balances[from] >= value &&
        //     allowed[msg.sender][from] >= value &&
        //     balances[to] + value > balances[to]) {
        if (balances[from] >= value && allowed[msg.sender][from] >= value && value > 0) {
            balances[to] += value;
            balances[from] -= value;
            allowed[msg.sender][from] -= value;
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    uint256 public totalSupply;
    mapping (address => uint256) internal balances; // token balances
    mapping (address => mapping (address => uint256)) internal allowed;
}

contract CentaurCoin is StandardToken {

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // Token name
    uint8 public decimals;                // How many decimals to show. To be standard compliant, keep it 18
    string public symbol;                 // An identifier: eg SBX, XPR etc..
    string public version = &quot;1.0&quot;; 
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC).
                                          // We&#39;ll store the total ETH raised via our ICO here.
    address public fundsWallet;           // Where should the raised ETH go?


    constructor() public {
        fundsWallet = msg.sender;                                    // The owner of the contract gets ETH
        balances[fundsWallet] = 1000000000000000000000;              // Give the creator all initial tokens.
                                                                     // This is set to 1000 for example.
                                                                     // If you want your initial tokens to be X and your decimal is 5, 
                                                                     // set this value to X * 100000.
        totalSupply = 1000000000000000000000;                        // Update total supply (1000 for example)
        name = &quot;CentaurCoin&quot;;                                        // Set the name for display purposes
        decimals = 18;                                               // Amount of decimals for display purposes
        symbol = &quot;CNTR&quot;;                                             // Set the symbol for display purposes
        unitsOneEthCanBuy = 10;                                      // Set the price of your token for the ICO
    }

    /// fallback function
    /// `msg.sender` buys tokens for `msg.value` WEI
    function() public payable{
        totalEthInWei += msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy; // amount in tokens
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] -= amount;
        balances[msg.sender] += amount;

        emit Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer the WEI earned to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    /// Approves and then calls the receiving contract
    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        // Call the receiveApproval function on the contract you want to be notified. 
        // This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        // `receiveApproval(address from, uint256 value, address tokenContract, bytes extraData)`
        // It is assumed that when one does this the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!spender.call(
            bytes4(bytes32(keccak256(&quot;receiveApproval(address,uint256,address,bytes)&quot;))),
            msg.sender,
            value,
            this,
            extraData))
        {
            revert();
        }
        return true;
    }
}