pragma solidity ^0.4.13;

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

contract EasyMineToken is StandardToken {

  string public constant name = "easyMINE Token";
  string public constant symbol = "EMT";
  uint8 public constant decimals = 18;

  function EasyMineToken(address _icoAddress,
                         address _preIcoAddress,
                         address _easyMineWalletAddress,
                         address _bountyWalletAddress) {
    require(_icoAddress != 0x0);
    require(_preIcoAddress != 0x0);
    require(_easyMineWalletAddress != 0x0);
    require(_bountyWalletAddress != 0x0);

    totalSupply = 33000000 * 10**18;                     // 33.000.000 EMT

    uint256 icoTokens = 27000000 * 10**18;               // 27.000.000 EMT

    uint256 preIcoTokens = 2000000 * 10**18;             // 2.000.000 EMT

    uint256 easyMineTokens = 3000000 * 10**18;           // 1.500.000 EMT dev team +
                                                         // 500.000 EMT advisors +
                                                         // 1.000.000 EMT easyMINE corporation +
                                                         // = 3.000.000 EMT

    uint256 bountyTokens = 1000000 * 10**18;             // 1.000.000 EMT

    assert(icoTokens + preIcoTokens + easyMineTokens + bountyTokens == totalSupply);

    balances[_icoAddress] = icoTokens;
    Transfer(0, _icoAddress, icoTokens);

    balances[_preIcoAddress] = preIcoTokens;
    Transfer(0, _preIcoAddress, preIcoTokens);

    balances[_easyMineWalletAddress] = easyMineTokens;
    Transfer(0, _easyMineWalletAddress, easyMineTokens);

    balances[_bountyWalletAddress] = bountyTokens;
    Transfer(0, _bountyWalletAddress, bountyTokens);
  }

  function burn(uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      totalSupply -= _value;
      Transfer(msg.sender, 0x0, _value);
      return true;
    } else {
      return false;
    }
  }
}

contract EasyMineTokenWallet {

  uint256 constant public VESTING_PERIOD = 180 days;
  uint256 constant public DAILY_FUNDS_RELEASE = 15000 * 10**18; // 0.5% * 3M tokens = 15k tokens a day

  address public owner;
  address public withdrawalAddress;
  Token public easyMineToken;
  uint256 public startTime;
  uint256 public totalWithdrawn;

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function EasyMineTokenWallet() {
    owner = msg.sender;
  }

  function setup(address _easyMineToken, address _withdrawalAddress)
    public
    isOwner
  {
    require(_easyMineToken != 0x0);
    require(_withdrawalAddress != 0x0);

    easyMineToken = Token(_easyMineToken);
    withdrawalAddress = _withdrawalAddress;
    startTime = now;
  }

  function withdraw(uint256 requestedAmount)
    public
    isOwner
    returns (uint256 amount)
  {
    uint256 limit = maxPossibleWithdrawal();
    uint256 withdrawalAmount = requestedAmount;
    if (requestedAmount > limit) {
      withdrawalAmount = limit;
    }

    if (withdrawalAmount > 0) {
      if (!easyMineToken.transfer(withdrawalAddress, withdrawalAmount)) {
        revert();
      }
      totalWithdrawn += withdrawalAmount;
    }

    return withdrawalAmount;
  }

  function maxPossibleWithdrawal()
    public
    constant
    returns (uint256)
  {
    if (now < startTime + VESTING_PERIOD) {
      return 0;
    } else {
      uint256 daysPassed = (now - (startTime + VESTING_PERIOD)) / 86400;
      uint256 res = DAILY_FUNDS_RELEASE * daysPassed - totalWithdrawn;
      if (res < 0) {
        return 0;
      } else {
        return res;
      }
    }
  }

}