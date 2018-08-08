//
/* SunContract Token Smart Contract v1.0 */   
//

contract owned {

  address public owner;

  function owned() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) throw;
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
} 

contract IERC20Token {

  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 totalSupply);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of tokens to be transferred
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

contract SunContractToken is IERC20Token, owned{

  /* Public variables of the token */
  string public standard = "SunContract token v1.0";
  string public name = "SunContract";
  string public symbol = "SNC";
  uint8 public decimals = 18;
  address public icoContractAddress;
  uint256 public tokenFrozenUntilBlock;

  /* Private variables of the token */
  uint256 supply = 0;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;
  mapping (address => bool) restrictedAddresses;

  /* Events */
  event Mint(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event TokenFrozen(uint256 _frozenUntilBlock, string _reason);

  /* Initializes contract and  sets restricted addresses */
  function SunContractToken(address _icoAddress) {
    restrictedAddresses[0x0] = true;
    restrictedAddresses[_icoAddress] = true;
    restrictedAddresses[address(this)] = true;
    icoContractAddress = _icoAddress;
  }

  /* Returns total supply of issued tokens */
  function totalSupply() constant returns (uint256 totalSupply) {
    return supply;
  }

  /* Returns balance of address */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  /* Transfers tokens from your address to other */
  function transfer(address _to, uint256 _value) returns (bool success) {
    if (block.number < tokenFrozenUntilBlock) throw;    // Throw if token is frozen
    if (restrictedAddresses[_to]) throw;                // Throw if recipient is restricted address
    if (balances[msg.sender] < _value) throw;           // Throw if sender has insufficient balance
    if (balances[_to] + _value < balances[_to]) throw;  // Throw if owerflow detected
    balances[msg.sender] -= _value;                     // Deduct senders balance
    balances[_to] += _value;                            // Add recivers blaance 
    Transfer(msg.sender, _to, _value);                  // Raise Transfer event
    return true;
  }

  /* Approve other address to spend tokens on your account */
  function approve(address _spender, uint256 _value) returns (bool success) {
    if (block.number < tokenFrozenUntilBlock) throw;    // Throw if token is frozen        
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
    if (block.number < tokenFrozenUntilBlock) throw;    // Throw if token is frozen
    if (restrictedAddresses[_to]) throw;                // Throw if recipient is restricted address  
    if (balances[_from] < _value) throw;                // Throw if sender does not have enough balance     
    if (balances[_to] + _value < balances[_to]) throw;  // Throw if overflow detected    
    if (_value > allowances[_from][msg.sender]) throw;  // Throw if you do not have allowance       
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

  /* Issue new tokens */     
  function mintTokens(address _to, uint256 _amount) {         
    if (msg.sender != icoContractAddress) throw;            // Only ICO address can mint tokens        
    if (restrictedAddresses[_to]) throw;                    // Throw if user wants to send to restricted address       
    if (balances[_to] + _amount < balances[_to]) throw;     // Check for overflows
    supply += _amount;                                      // Update total supply
    balances[_to] += _amount;                               // Set minted coins to target
    Mint(_to, _amount);                                     // Create Mint event       
    Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
  }     
  
  /* Destroy tokens from owners account */
  function burnTokens(uint256 _amount) onlyOwner {
    if(balances[msg.sender] < _amount) throw;               // Throw if you do not have enough balance
    if(supply < _amount) throw;                             // Throw if overflow detected

    supply -= _amount;                                      // Deduct totalSupply
    balances[msg.sender] -= _amount;                        // Destroy coins on senders wallet
    Burn(msg.sender, _amount);                              // Raise Burn event
    Transfer(msg.sender, 0x0, _amount);                     // Raise transfer to 0x0
  }

  /* Stops all token transfers in case of emergency */
  function freezeTransfersUntil(uint256 _frozenUntilBlock, string _reason) onlyOwner {      
    tokenFrozenUntilBlock = _frozenUntilBlock;
    TokenFrozen(_frozenUntilBlock, _reason);
  }

  function isRestrictedAddress(address _querryAddress) constant returns (bool answer){
    return restrictedAddresses[_querryAddress];
  }

  //
  /* This part is here only for testing and will not be included into final version */
  //

  //function changeICOAddress(address _newAddress) onlyOwner{
  //  icoContractAddress = _newAddress;
  //  restrictedAddresses[_newAddress] = true;   
  //}

  //function killContract() onlyOwner{
  //  selfdestruct(msg.sender);
  //}
}