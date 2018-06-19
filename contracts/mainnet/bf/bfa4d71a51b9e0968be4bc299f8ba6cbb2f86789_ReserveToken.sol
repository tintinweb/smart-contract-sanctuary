pragma solidity ^0.4.13;
// Last compiled with 0.4.13+commit.0fb4cb1a

contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

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
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}

contract ReserveToken is StandardToken, SafeMath {
    string public name;
    string public symbol;
    uint public decimals = 18;
    address public minter;
    function ReserveToken(string name_, string symbol_) {
      name = name_;
      symbol = symbol_;
      minter = msg.sender;
    }
    function create(address account, uint amount) {
      require(msg.sender == minter);
      balances[account] = safeAdd(balances[account], amount);
      totalSupply = safeAdd(totalSupply, amount);
    }
    function destroy(address account, uint amount) {
      require(msg.sender == minter);
      require(balances[account] >= amount);
      balances[account] = safeSub(balances[account], amount);
      totalSupply = safeSub(totalSupply, amount);
    }
}

contract YesNo is SafeMath {

  ReserveToken public yesToken;
  ReserveToken public noToken;

  string public name;
  string public symbol;

  //Reality Keys:
  bytes32 public factHash;
  address public ethAddr;
  string public url;

  uint public outcome;
  bool public resolved = false;

  address public feeAccount;
  uint public fee; //percentage of 1 ether

  event Create(address indexed account, uint value);
  event Redeem(address indexed account, uint value, uint yesTokens, uint noTokens);
  event Resolve(bool resolved, uint outcome);

  function YesNo(string name_, string symbol_, string namey_, string symboly_, string namen_, string symboln_, bytes32 factHash_, address ethAddr_, string url_, address feeAccount_, uint fee_) {
    name = name_;
    symbol = symbol_;
    yesToken = new ReserveToken(namey_, symboly_);
    noToken = new ReserveToken(namen_, symboln_);
    factHash = factHash_;
    ethAddr = ethAddr_;
    url = url_;
    feeAccount = feeAccount_;
    fee = fee_;
  }

  function() payable {
    create();
  }

  function create() payable {
    //send X Ether, get X Yes tokens and X No tokens
    yesToken.create(msg.sender, msg.value);
    noToken.create(msg.sender, msg.value);
    Create(msg.sender, msg.value);
  }

  function redeem(uint tokens) {
    feeAccount.transfer(safeMul(tokens,fee)/(1 ether));
    if (!resolved) {
      yesToken.destroy(msg.sender, tokens);
      noToken.destroy(msg.sender, tokens);
      msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
      Redeem(msg.sender, tokens, tokens, tokens);
    } else if (resolved) {
      if (outcome==0) { //no
        noToken.destroy(msg.sender, tokens);
        msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
        Redeem(msg.sender, tokens, 0, tokens);
      } else if (outcome==1) { //yes
        yesToken.destroy(msg.sender, tokens);
        msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
        Redeem(msg.sender, tokens, tokens, 0);
      }
    }
  }

  function resolve(uint8 v, bytes32 r, bytes32 s, bytes32 value) {
    require(ecrecover(sha3(factHash, value), v, r, s) == ethAddr);
    require(!resolved);
    uint valueInt = uint(value);
    require(valueInt==0 || valueInt==1);
    outcome = valueInt;
    resolved = true;
    Resolve(resolved, outcome);
  }
}

/*
contract Option is SafeMath {

  ReserveToken public callToken;
  ReserveToken public putToken;

  string public name;
  string public symbol;
  uint public strikeCall; //times (1 ether)
  uint public strikePut; //times (1 ether)
  //a call is always paired with a put.
  //strikeCall must be less than strikePut.
  //the difference bewteen them represents the in-the-money limit.

  //Reality Keys:
  bytes32 public factHash;
  address public ethAddr;
  string public url;

  uint public outcome;
  bool public resolved = false;

  address public feeAccount;
  uint public fee; //percentage of 1 ether

  event Create(address indexed account, uint value);
  event Redeem(address indexed account, uint value, uint callTokens, uint putTokens);
  event Resolve(bool resolved, uint outcome);

  function Option(uint strikeCall_, uint strikePut_, string name_, string symbol_, string namecall_, string symbolcall_, string nameput_, string symbolput_, bytes32 factHash_, address ethAddr_, string url_, address feeAccount_, uint fee_) {
    assert(strikeCall_ < strikePut_);
    strikeCall = strikeCall_;
    strikePut = strikePut_;
    name = name_;
    symbol = symbol_;
    callToken = new ReserveToken(namecall_, symbolcall_);
    putToken = new ReserveToken(nameput_, symbolput_);
    factHash = factHash_;
    ethAddr = ethAddr_;
    url = url_;
    feeAccount = feeAccount_;
    fee = fee_;
  }

  function () payable {
    create();
  }

  function create() payable {
    //send X Ether, get X call tokens and X put tokens
    callToken.create(msg.sender, msg.value);
    putToken.create(msg.sender, msg.value);
    Create(msg.sender, msg.value);
  }

  function redeem(uint tokens) {
    if (!resolved) {
      feeAccount.transfer(safeMul(tokens,fee)/(1 ether));
      callToken.destroy(msg.sender, tokens);
      putToken.destroy(msg.sender, tokens);
      msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
      Redeem(msg.sender, tokens, tokens, tokens);
    } else if (resolved) {
      uint callTokenBalance = callToken.balanceOf(msg.sender);
      uint putTokenBalance = putToken.balanceOf(msg.sender);
      callToken.destroy(msg.sender, callTokenBalance);
      putToken.destroy(msg.sender, putTokenBalance);
      uint value = 0;
      if (outcome <= strikeCall) {
        value = safeMul(putTokenBalance, (strikeCall - strikePut)) / (1 ether);
      } else if (outcome >= strikePut) {
        value = safeMul(callTokenBalance, (strikeCall - strikePut)) / (1 ether);
      } else {
        value = safeMul(callTokenBalance, (outcome - strikeCall)) / (1 ether) + safeMul(putTokenBalance, (strikePut - outcome)) / (1 ether);
      }
      feeAccount.transfer(safeMul(value,fee)/(1 ether));
      msg.sender.transfer(safeMul(value,(1 ether)-fee)/(1 ether));
      Redeem(msg.sender, value, callTokenBalance, putTokenBalance);
    }
  }

  function resolve(uint8 v, bytes32 r, bytes32 s, bytes32 value) {
    require(ecrecover(sha3(factHash, value), v, r, s) == ethAddr);
    require(!resolved);
    uint valueInt = uint(value);
    require (valueInt==0 || valueInt==1);
    outcome = valueInt;
    resolved = true;
    Resolve(resolved, outcome);
  }
}
*/