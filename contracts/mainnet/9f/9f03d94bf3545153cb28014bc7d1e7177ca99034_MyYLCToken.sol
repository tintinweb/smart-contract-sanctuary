pragma solidity ^0.4.13;
contract owned {
  address public owner;

  function owned() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
  /* Public variables of the token */
  string public standard = &#39;Token 0.1&#39;;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  /* This creates an array with all balances */
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  /* This generates a public event on the blockchain that will notify clients */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  function token(
  uint256 initialSupply,
  string tokenName,
  uint8 decimalUnits,
  string tokenSymbol
  ) {
    balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    totalSupply = initialSupply;                        // Update total supply
    name = tokenName;                                   // Set the name for display purposes
    symbol = tokenSymbol;                               // Set the symbol for display purposes
    decimals = decimalUnits;                            // Amount of decimals for display purposes
  }

  /* Send coins */
  function transfer(address _to, uint256 _value) {
    assert (balanceOf[msg.sender] >= _value);            // Check if the sender has enough
    assert (balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
    balanceOf[msg.sender] -= _value;                     // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
  }

  /* Allow another contract to spend some tokens in your behalf */
  function approve(address _spender, uint256 _value)
  returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    return true;
  }

  /* Approve and then communicate the approved contract in a single tx */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
  returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  /* A contract attempts to get the coins */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    assert (balanceOf[_from] >= _value);                 // Check if the sender has enough
    assert (balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
    assert (_value <= allowance[_from][msg.sender]);     // Check allowance
    balanceOf[_from] -= _value;                          // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  /* This unnamed function is called whenever someone tries to send ether to it */
  function () {
    assert(false);     // Prevents accidental sending of ether
  }
}

contract MyYLCToken is owned, token {

  uint256 public sellPrice;
  uint256 public buyPrice;

  mapping (address => bool) public frozenAccount;

  /* This generates a public event on the blockchain that will notify clients */
  event FrozenFunds(address target, bool frozen);

  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint256 value);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  function MyYLCToken(
  uint256 initialSupply,
  string tokenName,
  uint8 decimalUnits,
  string tokenSymbol
  ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

  /* Send coins */
  function transfer(address _to, uint256 _value) {
    assert (balanceOf[msg.sender] >= _value);           // Check if the sender has enough
    assert (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
    assert (!frozenAccount[msg.sender]);                // Check if frozen
    balanceOf[msg.sender] -= _value;                     // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
  }


  /* A contract attempts to get the coins */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    assert (!frozenAccount[_from]);                      // Check if frozen
    assert (balanceOf[_from] >= _value);                 // Check if the sender has enough
    assert (balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
    assert (_value <= allowance[_from][msg.sender]);     // Check allowance
    balanceOf[_from] -= _value;                          // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  function mintToken(address target, uint256 mintedAmount) onlyOwner {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
  }

  function freezeAccount(address target, bool freeze) onlyOwner {
    frozenAccount[target] = freeze;
    FrozenFunds(target, freeze);
  }

  function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
    sellPrice = newSellPrice;
    buyPrice = newBuyPrice;
  }

  function buy() payable {
    uint amount = msg.value / buyPrice;                // calculates the amount
    assert (balanceOf[this] >= amount);                // checks if it has enough to sell
    balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
    balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
    Transfer(this, msg.sender, amount);                // execute an event reflecting the change
  }

  function sell(uint256 amount) {
    assert (balanceOf[msg.sender] >= amount );         // checks if the sender has enough to sell
    balanceOf[this] += amount;                         // adds the amount to owner&#39;s balance
    balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
    assert (msg.sender.send(amount * sellPrice));      // sends ether to the seller. It&#39;s important
                                                       // to do this last to avoid recursion attacks
    Transfer(msg.sender, this, amount);                // executes an event reflecting on the change
  }

  function burn(uint256 amount) onlyOwner returns (bool success) {
    assert (balanceOf[msg.sender] >= amount);             // Check if the sender has enough
    balanceOf[msg.sender] -= amount;                      // Subtract from the sender
    totalSupply -= amount;                                // Updates totalSupply
    Burn(msg.sender, amount);
    return true;
  }

}