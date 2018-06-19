/// @title Cryptocurrency  of the Ravensburg-Weingarten University of Applied Sciences ///(German: Hochschule Ravensburg-Weingarten) 
///@author Walther,Dominik 

pragma solidity ^0.4.13; contract owned { address public owner;
  function owned() {
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
/// receive other cryptocurrency
contract tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes extraData); }

/// the public variables of the HRWtoken
contract HRWtoken is owned { string public name; string public symbol; uint8 public decimals; uint256 public totalSupply; uint256 public sellPrice; uint256 public buyPrice;
///@notice create an array with all adresses and associated balances of the cryptocurrency

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

 ///@notice generate a event on the blockchain to show transfer information 
  event Transfer(address indexed from, address indexed to, uint256 value);

///@notice initialization of the contract and distribution of tokes to the creater
  function HRWtoken(
      uint256 initialSupply,
      string tokenName,
      uint8 decimalUnits,
      string tokenSymbol,
address centralMinter
      ) {
if(centralMinter != 0 ) owner = centralMinter;
      balanceOf[msg.sender] = initialSupply;       
      totalSupply = initialSupply;                        
      name = tokenName;                                   
      symbol = tokenSymbol;                               
      decimals = decimalUnits;                            
  }

  ///@notice only the contract can operate this internal funktion
  function _transfer(address _from, address _to, uint _value) internal {
      require (_to != 0x0);           
      require (balanceOf[_from] >= _value);            
      require (balanceOf[_to] + _value > balanceOf[_to]); 
      balanceOf[_from] -= _value;                         
      balanceOf[_to] += _value;                            
      Transfer(_from, _to, _value);
  }

  /// @notice transfer to account (_to) any value (_value)
  /// @param _to The address of the reciver
  /// @param _value value units from the cryptocurrency
  function transfer(address _to, uint256 _value) {
      _transfer(msg.sender, _to, _value);
  }

  /// @notice to dend the tokens the sender need the allowance 
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value value units to send
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require (_value < allowance[_from][msg.sender]);     
      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;
  }

  /// @notice the spender can only transfer the value units he own
  /// @param _spender the address authorized to transfer
  /// @param _value the max amount they can spend
  function approve(address _spender, uint256 _value)
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      return true;
  }

/// @notice funktion contains approve with the addition to follow the contract ///about the allowance
  /// @param _spender the address authorized to spend
  /// @param _value the max amount they can spend
  /// @param _extraData some extra information to send to the approved contract
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
          return true;
      }
  }        
/// @notice Create new token in addition to the initalsupply and send to target adress
  /// @param target address to receive the tokens
  /// @param mintedAmount ist the generated amount send to specified adress
  function mintToken(address target, uint256 mintedAmount) onlyOwner {
      balanceOf[target] += mintedAmount;
      totalSupply += mintedAmount;
      Transfer(0, this, mintedAmount);
      Transfer(this, target, mintedAmount);
  }
  /// @notice participants of the Ethereum Network can buy or sell this token in ///exchange to Ether
  /// @param newSellPrice price the users can sell to the contract
  /// @param newBuyPrice price users can buy from the contract
  function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
      sellPrice = newSellPrice;
      buyPrice = newBuyPrice;
  }

/// @notice The Ether send to the contract exchange by BuyPrice and send back  ///HRW Tokens
  function buy() payable {
      uint amount = msg.value / buyPrice;               
      _transfer(this, msg.sender, amount);              
  }

/// @notice the HRWToken send to the contract and exchange by SellPrice and ///send ether back
  /// @param amount HRW Token to sale
  function sell(uint256 amount) {
      require(this.balance >= amount * sellPrice);      
      _transfer(msg.sender, this, amount);              
      msg.sender.transfer(amount * sellPrice);          
  }
}