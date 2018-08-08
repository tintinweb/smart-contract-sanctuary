pragma solidity ^0.4.4;

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract BrainLegitCoin is StandardToken { // CHANGE THIS. Update the contract name.

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
    string public version = &#39;BL1.0&#39;; 
    uint256 public unitsOneEthCanBuybefore;     // How many units of coin can be bought by 1 ETH during ICO?
    uint256 public unitsOneEthCanBuyafter;     // How many units of coin can be bought by 1 ETH after ICO?
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.  
    address public fundsWallet;          // Where should the raised ETH go?
    uint public deadline;
uint256 public ecosystemtoken;
uint public preIcoStart;
uint public preIcoEnds;
uint public Icostart;
uint public Icoends;


  // Token Distribution
  // =============================
  uint256 public maxTokens = 1000000000000000000000000000; // There will be total 1Billion LegitCoin Tokens
  uint256 public tokensForplutonics = 200000000000000000000000000; // 200million legitt coin for utility ecosystem
  uint256 public tokensForfortis = 150000000000000000000000000;    //150Million Legitt coin for fortis projects
  uint256 public tokensFortorch = 10000000000000000000000000;     // 100 million legitt coin for Torch
    uint256 public tokensForEcosystem = 10000000000000000000000000;  // 100 million legittcoin for ecosystem
  uint256 public totalTokensForSale = 450000000000000000000000000; // 450Million LGT will be sold in Crowdsale

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function BrainLegitCoin() {
        balances[msg.sender] = maxTokens;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE THIS)
        totalSupply = maxTokens;                        // Update total supply (1000 for example) (CHANGE THIS)
      
        name = "LegittCoin";                                   // Set the name for display purposes (CHANGE THIS)
        decimals = 18;                                               // Amount of decimals for display purposes (CHANGE THIS)
        symbol = "LGT";                                             // Set the symbol for display purposes (CHANGE THIS)
        unitsOneEthCanBuybefore = 30000;                                      // Set the price of your token for the ICO (CHANGE THIS)
       unitsOneEthCanBuyafter=15000;
        fundsWallet = msg.sender;  
   preIcoStart=now + 10080 * 1 minutes;
   preIcoEnds = now + 25920 * 1 minutes;
   Icostart = now + 27360 * 1 minutes;
   Icoends= now + 72000 * 1 minutes;
   
                         
    }

    function() payable{
       
      if(now > Icoends) throw;
      if ((balances[fundsWallet] > 300000000000000000000000000) && ((now >= preIcoStart) && (now <= preIcoEnds))){
              totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuybefore;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
      } else if( (now >= Icostart) && (now <= Icoends)){
       totalEthInWei = totalEthInWei + msg.value;
        uint256 amountb = msg.value * unitsOneEthCanBuyafter;
        require(tokensForEcosystem >= amountb);

        tokensForEcosystem = tokensForEcosystem - amountb;
        balances[msg.sender] = balances[msg.sender] + amountb;

        Transfer(fundsWallet, msg.sender, amountb); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
      }
              
     
       
      
        
       
                                   
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}