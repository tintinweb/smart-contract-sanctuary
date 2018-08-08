pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Token is Ownable {

  /// @return total amount of tokens
  function totalSupply() view public returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) public returns (bool success) {
      //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
      //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
      //Replace the if with this one instead.
      //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
      }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      //same as above. Replace this line with the following if you want to protect against wrapping uints.
      //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else { 
      return false;
      }
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;
}

contract Bitotal is StandardToken { 

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
  string public version = "1.0"; 
  uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
  uint256 public totalEthInWei;         // WEI is the smallest unit of ETH 
  address public fundsWallet;           // Where should the raised ETH go?
  uint256 public maxSupply;
  uint256 public maxTransferPerTimeframe;
  uint256 public timeFrame;
  bool public paused;
  bool public restrictTransfers;
  mapping (address => uint256) public lastTransfer;
  mapping (address => uint256) public transfered;

  modifier NotPaused() {
    require(!paused);
    _;
  }

  // This is a constructor function 
  // which means the following function name has to match the contract name declared above
  constructor() public {
    fundsWallet = msg.sender; 
    balances[fundsWallet] = 100000000;               
    totalSupply = 100000000;    
    maxSupply = 500000000;                    
    name = "Bitotal";                                   
    decimals = 2;                                               
    symbol = "TFUND";                                             
    unitsOneEthCanBuy = 15;                                       
    timeFrame = 86399;      
    maxTransferPerTimeframe = 300;                            
  }

  function() payable public {
    require(msg.value > 1 finney);
    totalEthInWei = totalEthInWei + msg.value;
    uint256 amount = msg.value * unitsOneEthCanBuy;
    amount = (amount * 100) / 1 ether;
    mintTokens(msg.sender, amount);
    fundsWallet.transfer(msg.value);                               
  }

  function mintTokens(address _to, uint256 _amount) private {
    require((totalSupply + _amount) <= maxSupply);
    balances[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(0x0, _to, _amount);
  }

  function setWalletAddress(address _newWallet) onlyOwner public {
    require(_newWallet != address(0x0));
    fundsWallet = _newWallet;
  }

  function pause(bool _paused) onlyOwner public {
    paused = _paused;
  }

  function setTimeFrame(uint256 _time) onlyOwner public {
    timeFrame = _time;
  }

  function restrict(bool _restricted) onlyOwner public {
    restrictTransfers = _restricted;
  }

  function maxTransferAmount(uint256 _amount) onlyOwner public {
    maxTransferPerTimeframe = _amount;
  }

  function transfer(address _to, uint256 _value) NotPaused public returns (bool success) {
    uint256 _lastTransfer;

    _lastTransfer = lastTransfer[msg.sender] + timeFrame;

    if ( _lastTransfer < now) {
        
      transfered[msg.sender] = 0;
      lastTransfer[msg.sender] = now;
    }
     
    if ((_value <= (maxTransferPerTimeframe - transfered[msg.sender])) || !restrictTransfers) {
      
      if (restrictTransfers) {
        transfered[msg.sender] += _value;
      }
      super.transfer(_to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) NotPaused public returns (bool success) {
    uint256 _lastTransfer;

    _lastTransfer = lastTransfer[_from] + timeFrame;
    if ( _lastTransfer < now) {
      transfered[_from] = 0;
      lastTransfer[_from] = now;
    }
    if ((_value <= (maxTransferPerTimeframe - transfered[_from])) || !restrictTransfers) {
      if (restrictTransfers) {
        transfered[_from] += _value;
      }
      super.transferFrom(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

}