pragma solidity ^0.4.8;

// The implementation for the Credo ICO smart contract was inspired by
// the Ethereum token creation tutorial, the FirstBlood token, and the BAT token.

///////////////
// SAFE MATH //
///////////////

contract SafeMath {

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }      // assert no longer needed once solidity is on 0.4.10

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

////////////////////
// STANDARD TOKEN //
////////////////////

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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

/////////////////////
// CREDO ICO TOKEN //
/////////////////////

contract CredoIco is StandardToken, SafeMath {
    // Descriptive properties
    string public constant name = "Credo ICO Token";
    string public constant symbol = "CREDOICO";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // Account for ether proceed.
    address public etherProceedsAccount;

    // These params specify the start, end, min, and max of the sale.
    bool public isFinalized;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    uint256 public constant tokenCreationCap =  375200000 * 10**decimals;
    uint256 public constant tokenCreationMin =  938000 * 10**decimals;

    // Setting the exchange rate for the first part of the ICO.
    uint256 public constant credoEthExchangeRate = 3752;

    // Events for logging refunds and token creation.
    event LogRefund(address indexed _to, uint256 _value);
    event CreateCredoIco(address indexed _to, uint256 _value);

    // constructor
    function CredoIco(address _etherProceedsAccount, uint256 _fundingStartBlock, uint256 _fundingEndBlock)
    {
      isFinalized                    = false;
      etherProceedsAccount           = _etherProceedsAccount;
      fundingStartBlock              = _fundingStartBlock;
      fundingEndBlock                = _fundingEndBlock;
      totalSupply                    = 0;
    }

    function createTokens() payable external {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;

      uint256 tokens = safeMult(msg.value, credoEthExchangeRate);
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      if (tokenCreationCap < checkedSupply) throw;

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;
      CreateCredoIco(msg.sender, tokens);
    }

    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != etherProceedsAccount) throw;
      if (totalSupply < tokenCreationMin) throw;
      if (block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;

      isFinalized = true;

      if (!etherProceedsAccount.send(this.balance)) throw;
    }

    function refund() external {
      if (isFinalized) throw;
      if (block.number <= fundingEndBlock) throw;
      if (totalSupply >= tokenCreationMin) throw;
      uint256 credoVal = balances[msg.sender];
      if (credoVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, credoVal);
      uint256 ethVal = credoVal / credoEthExchangeRate;
      LogRefund(msg.sender, ethVal);
      if (!msg.sender.send(ethVal)) throw;
    }

}