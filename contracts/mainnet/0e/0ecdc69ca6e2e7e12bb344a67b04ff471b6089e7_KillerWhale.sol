pragma solidity ^0.4.20;


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Token {

    /// @return total amount of tokens
    function totalSupply() public view returns (uint);

    /// @param tokenOwner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address tokenOwner) public view returns (uint balance);

    /// @notice send `tokens` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param tokens The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    /// reverts/fails the transaction if conditions are not met
    function transfer(address to, uint tokens) public returns (bool success);

    /// @notice send `tokens` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param tokens The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    /// reverts/fails the transaction if conditions are not met
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    /// @notice `msg.sender` approves `spender` to spend `tokens` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param tokens The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    /// reverts/fails the transaction if conditions are not met
    function approve(address spender, uint tokens) public returns (bool success);

    /// @param tokenOwner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    
  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {
    
    using SafeMath for uint;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens > 0);
        require(balances[msg.sender] >= tokens); 
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require(spender != address(0));
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(from != address(0));
        require(to != address(0));
        require(tokens > 0);
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Get the totalSupply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}

contract KillerWhale is StandardToken { // CHANGE THIS. Update the contract name.

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // Token Name
    uint8 public decimals;                // How many decimals to show. To be standard complicant keep it 18
    string public symbol;                 // An identifier: eg SBX, XPR etc..
    string public version = &#39;H1.0&#39;; 
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.  
    address public fundsWallet;           // Where should the raised ETH go?

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function KillerWhale() {
        name = "KillerWhale";                                          // Set the name for display purposes (CHANGE THIS)
        decimals = 18;                                               // Amount of decimals for display purposes (CHANGE THIS)
        symbol = "KWT";                                             // Set the symbol for display purposes (CHANGE THIS)
        unitsOneEthCanBuy = 100;                                      // Set the price of your token for the ICO (CHANGE THIS)
        fundsWallet = 0x3f17dE50F2D1CA4209c2028677B328E34581d4Dc;                                    // The owner of the contract gets ETH
        totalSupply = 88000000 * 10 ** uint256(decimals);                        // Update total supply (1000 for example) (CHANGE THIS)
        balances[0x3f17dE50F2D1CA4209c2028677B328E34581d4Dc] = totalSupply;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE THIS)
        
        emit Transfer(address(0),0x3f17dE50F2D1CA4209c2028677B328E34581d4Dc,totalSupply);
    }


    function() public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;

        // wallet should have enough tokens to fund
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        emit Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                               
    }


    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}