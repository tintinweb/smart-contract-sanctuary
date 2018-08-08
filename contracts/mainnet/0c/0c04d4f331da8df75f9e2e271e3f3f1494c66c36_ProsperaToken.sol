pragma solidity ^0.4.11;

contract Token {
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
}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner returns (address _owner) {
        owner = newOwner;
        return owner;
    }
}

contract ProsperaToken is StandardToken, Owned {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.


    function ProsperaToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
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


    /* Batch token transfer. Used by contract creator to distribute initial coins to holders */
    function batchTransfer(address[] _recipients, uint256[] _values) returns (bool success) {
      if ((_recipients.length == 0) || (_recipients.length != _values.length)) throw;

      for(uint8 i = 0; i < _recipients.length; i += 1) {
        if (!transfer(_recipients[i], _values[i])) throw;
      }
      return true;
    }



    address minterContract;
    event Mint(address indexed _account, uint256 _amount);

    modifier onlyMinter {
        if (msg.sender != minterContract) throw;
         _;
    }

    function setMinter (address newMinter) onlyOwner returns (bool success) {
      minterContract = newMinter;
      return true;
    }

    function mintToAccount(address _account, uint256 _amount) onlyMinter returns (bool success) {
        // Checks for variable overflow
        if (balances[_account] + _amount < balances[_account]) throw;
        balances[_account] += _amount;
        Mint(_account, _amount);
        return true;
    }

    function incrementTotalSupply(uint256 _incrementValue) onlyMinter returns (bool success) {
        totalSupply += _incrementValue;
        return true;
    }
}

contract Minter is Owned {

  uint256 public lastMintingTime = 0;
  uint256 public lastMintingAmount;
  address public prosperaTokenAddress;
  ProsperaToken public prosperaToken;

  modifier allowedMinting() {
    if (block.timestamp >= lastMintingTime + 30 days) {
      _;
    }
  }

  function Minter (uint256 _lastMintingAmount, address _ownerContract) {
    lastMintingAmount = _lastMintingAmount;
    prosperaTokenAddress = _ownerContract;
    prosperaToken = ProsperaToken(_ownerContract);
  }

  // increases 2.95% from last minting
  function calculateMintAmount() returns (uint256 amount){
   return lastMintingAmount * 10295 / 10000;
  }

  function updateMintingStatus(uint256 _mintedAmount) internal {
    lastMintingAmount = _mintedAmount;
    lastMintingTime = block.timestamp;
    prosperaToken.incrementTotalSupply(_mintedAmount);
  }

  function mint() allowedMinting onlyOwner returns (bool success) {
    uint256 value = calculateMintAmount();
    prosperaToken.mintToAccount(msg.sender, value);
    updateMintingStatus(value);
    return true;
  }
}