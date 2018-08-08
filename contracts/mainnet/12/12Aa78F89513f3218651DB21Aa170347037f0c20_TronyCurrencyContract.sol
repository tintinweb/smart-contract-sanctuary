pragma solidity ^0.4.13;

contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Owned() {
        owner = msg.sender;
    }
    
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


contract tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
} 

contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TronyCurrencyContract is ERC20Token, Owned{

    /* Public variables of the token */
    string  public constant standard = "Trony currency V1.0";
    string  public constant name = "Trony Currency";
    string  public constant symbol = "TRC";
    uint256 public constant decimals = 6;
    uint256 private constant etherChange = 10**18;
    
    /* Variables of the token */
    uint256 public totalSupply;
    uint256 public totalRemainSupply;
    uint256 public TRCExchangeRate;
    bool    public crowdsaleIsOpen;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    address public multisigAddress;
    /* Events */
    event mintToken(address indexed _to, uint256 _value);
    event burnToken(address indexed _from, uint256 _value);
    
    function () payable {
        require (crowdsaleIsOpen == true);
        require(msg.value != 0);
        mintTRCToken(msg.sender, (msg.value * TRCExchangeRate * 10**decimals) / etherChange);
    }
    /* Initializes contract and  sets restricted addresses */
    function TronyCurrencyContract(uint256 _totalSupply, uint256 __TRCExchangeRate) {
        owner = msg.sender;
        totalSupply = _totalSupply * 10**decimals;
        TRCExchangeRate = __TRCExchangeRate;
        totalRemainSupply = totalSupply;
        crowdsaleIsOpen = true;
    }
    
    function setTRCExchangeRate(uint256 _TRCExchangeRate) onlyOwner {
        TRCExchangeRate = _TRCExchangeRate;
    }
    
    function crowdsaleOpen(bool _crowdsaleIsOpen) {
        crowdsaleIsOpen = _crowdsaleIsOpen;
    }
    /* Returns total supply of issued tokens */
    function TRCTotalSupply() returns (uint256) {   
        return totalSupply - totalRemainSupply;
    }

    /* Returns balance of address */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfers tokens from your address to other */
    function transfer(address _to, uint256 _value) returns (bool success) {
        require (balances[msg.sender] > _value);            // Throw if sender has insufficient balance
        require (balances[_to] + _value > balances[_to]);   // Throw if owerflow detected
        balances[msg.sender] -= _value;                     // Deduct senders balance
        balances[_to] += _value;                            // Add recivers blaance 
        Transfer(msg.sender, _to, _value);                  // Raise Transfer event
        return true;
    }

    /* Approve other address to spend tokens on your account */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowances[msg.sender][_spender] = _value;          // Set allowance         
        Approval(msg.sender, _spender, _value);             // Raise Approval event         
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */ 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {            
        tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract         
        approve(_spender, _value);                                      // Set approval to contract for _value         
        spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract         
        return true;     
    }     

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {      
        require (balances[_from] > _value);                // Throw if sender does not have enough balance     
        require (balances[_to] + _value > balances[_to]);  // Throw if overflow detected    
        require (_value > allowances[_from][msg.sender]);  // Throw if you do not have allowance       
        balances[_from] -= _value;                          // Deduct senders balance    
        balances[_to] += _value;                            // Add recipient blaance         
        allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address         
        Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;     
    }         

    /* Get the amount of allowed tokens to spend */     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {         
        return allowances[_owner][_spender];
    }     
        
    /*withdraw Ether to a multisig address*/
    function withdraw(address _multisigAddress) onlyOwner {    
        require(_multisigAddress != 0x0);
        multisigAddress = _multisigAddress;
        multisigAddress.transfer(this.balance);
    }  
    
    /* Issue new tokens */     
    function mintTRCToken(address _to, uint256 _amount) internal { 
        require (balances[_to] + _amount > balances[_to]);      // Check for overflows
        require (totalRemainSupply > _amount);
        totalRemainSupply -= _amount;                           // Update total supply
        balances[_to] += _amount;                               // Set minted coins to target
        mintToken(_to, _amount);                                // Create Mint event       
        Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
    }  
    
    function mintTokens(address _sendTo, uint256 _sendAmount) onlyOwner {
        mintTRCToken(_sendTo, _sendAmount);
    }
    
    /* Destroy tokens from owners account */
    function burnTokens(address _addr, uint256 _amount) onlyOwner {
        require (balances[msg.sender] < _amount);               // Throw if you do not have enough balance
        totalRemainSupply += _amount;                           // Deduct totalSupply
        balances[_addr] -= _amount;                             // Destroy coins on senders wallet
        burnToken(_addr, _amount);                              // Raise Burn event
        Transfer(_addr, 0x0, _amount);                          // Raise transfer to 0x0
    }
}