pragma solidity ^0.4.15;

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

// Based on TokenFactory(https://github.com/ConsenSys/Token-Factory)

contract SnipCoin is StandardToken {
    /* Public variables of the token */

    string public tokenName;       // Token name
    uint public decimals;          // Decimal points for token
    string public tokenSymbol;          // Token identifier
    uint public totalEthReceivedInWei; // The total amount of Ether received during the sale in WEI
    uint public totalUsdReceived; // The total amount of Ether received during the sale in USD terms
    string public version = "1.0"; // Code version
    address public saleWalletAddress;  // The wallet address where the Ether from the sale will be stored
    address public ownerAddress; // Address of the contract owner.

    // Multiplier for the decimals
    uint private constant DECIMALS_MULTIPLIER = 1000000000000000000;    
    uint private constant WEI_IN_ETHER = 1000 * 1000 * 1000 * 1000 * 1000 * 1000; // Number of wei in 1 eth
    uint private constant WEI_TO_USD_EXCHANGE_RATE = WEI_IN_ETHER / 255; // Eth to USD exchange rate. Verify this figure before the sale starts. 

    function initializeSaleWalletAddress()
    {
        saleWalletAddress = 0x686f152dad6490df93b267e319f875a684bd26e2;
    }

    function initializeEthReceived()
    {
        totalEthReceivedInWei = 14500 * WEI_IN_ETHER; // Ether received before public sale. Verify this figure before the sale starts.
    }

    function initializeUsdReceived()
    {
        totalUsdReceived = 4000000; // USD received before public sale. Verify this figure before the sale starts.
    }

    function getBalance(address addr) returns(uint)
    {
        return balances[addr];
    }

    function SnipCoin()
    {
        initializeSaleWalletAddress();
        initializeEthReceived();
        initializeUsdReceived();
        totalSupply = 10000000000;                                      // In total, 10 billion tokens
        balances[msg.sender] = totalSupply * DECIMALS_MULTIPLIER;        // Initially give owner all of the tokens 
        
        tokenName = "SnipCoin";                              // Name of token
        decimals = 18;                                       // Amount of decimals for display purposes
        tokenSymbol = "SNP";                                      // Set the symbol for display purposes
    }

    function sendCoin(address receiver, uint amount) returns(bool sufficient)
    {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Transfer(msg.sender, receiver, amount);
        return true;
    }

    function () payable
    {
        if (!saleWalletAddress.send(msg.value)) revert();
        totalEthReceivedInWei = totalEthReceivedInWei + msg.value;
        totalUsdReceived = totalUsdReceived + msg.value / WEI_TO_USD_EXCHANGE_RATE;
    }
}