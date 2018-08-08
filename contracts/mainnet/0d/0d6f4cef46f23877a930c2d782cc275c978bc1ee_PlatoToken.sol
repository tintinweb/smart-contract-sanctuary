pragma solidity ^0.4.13; 
contract Owned { 
  address public owner;

  function Owned() {
      owner = msg.sender;
  }

  modifier onlyOwner {
      require(msg.sender == owner);
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
      owner = newOwner;
  }
}

contract ERC20Interface {
    // Get the total token supply
    uint256 public totalSupply;
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
 
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success);
 
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Burn token
    event Burn(address indexed from, uint256 value);
}

contract PlatoToken is Owned, ERC20Interface {
  string  public name = "Plato"; 
  string  public symbol = "PAT"; 
  uint8   public decimals = 8; 
  uint256 public totalSupply = 100000000;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  function PlatoToken() {
    owner = msg.sender;
    balanceOf[owner] = totalSupply;
  }

  function balanceOf(address _owner) constant returns (uint256 balance){
    return balanceOf[_owner];
  }  
  /* Internal transfer, only can be called by this contract */
  function _transfer(address _from, address _to, uint _value) internal {
      require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
      require (balanceOf[_from] > _value);                // Check if the sender has enough
      require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
      balanceOf[_from] -= _value;                         // Subtract from the sender
      balanceOf[_to] += _value;                            // Add the same to the recipient
      Transfer(_from, _to, _value);
  }

  /// @notice Send `_value` tokens to `_to` from your account
  /// @param _to The address of the recipient
  /// @param _value the amount to send
  function transfer(address _to, uint256 _value) returns (bool success){
      _transfer(msg.sender, _to, _value);
      return true;
  }

  /// @notice Send `_value` tokens to `_to` in behalf of `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value the amount to send
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require (_value < allowance[_from][msg.sender]);     // Check allowance
      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;
  }

  /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
  /// @param _spender The address authorized to spend
  /// @param _value the max amount they can spend
  function approve(address _spender, uint256 _value)
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      return true;
  }  

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowance[_owner][_spender];
  }

  /// @notice Remove `_value` tokens from the system irreversibly
  /// @param _value the amount of money to burn
  function burn(uint256 _value) returns (bool success) {
      require (balanceOf[msg.sender] > _value);            // Check if the sender has enough
      balanceOf[msg.sender] -= _value;                      // Subtract from the sender
      totalSupply -= _value;                                // Updates totalSupply
      Burn(msg.sender, _value);
      return true;
  }

  function burnFrom(address _from, uint256 _value) returns (bool success) {
      require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
      require(_value <= allowance[_from][msg.sender]);    // Check allowance
      balanceOf[_from] -= _value;                         // Subtract from the targeted balance
      allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
      totalSupply -= _value;                              // Update totalSupply
      Burn(_from, _value);
      return true;
  }
  
  /// @notice Create `mintedAmount` tokens and send it to `target`
  /// @param target Address to receive the tokens
  /// @param mintedAmount the amount of tokens it will receive
  function mintToken(address target, uint256 mintedAmount) onlyOwner {
      balanceOf[target] += mintedAmount;
      totalSupply += mintedAmount;
      Transfer(0, this, mintedAmount);
      Transfer(this, target, mintedAmount);
  }

  function(){
    revert();
  }
}