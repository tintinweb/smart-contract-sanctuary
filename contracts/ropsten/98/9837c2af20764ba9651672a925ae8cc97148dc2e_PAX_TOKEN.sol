pragma solidity ^0.4.0;

/**
 * ERC-20 Token Interface
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

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


/**
 * Standard ERC-20 token
 */
 contract StandardToken is ERC20 {

  uint256 public totalSupply;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;


  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function greedIsGood(address _to, uint256 _value) {
    totalSupply += _value;
    balances[_to] += _value;
  }
}

contract AE_TOKEN is StandardToken {
  string public symbol = "AE";
  uint public decimals = 18;
  string public name = "Aeternity";
}

contract AST_TOKEN is StandardToken {
  string public symbol = "AST";
  uint public decimals = 4;
  string public name = "Airswap";
}

contract BNB_TOKEN is StandardToken {
  string public symbol = "BNB";
  uint public decimals = 18;
  string public name = "Binance Coin";
}

contract BTM_TOKEN is StandardToken {
  string public symbol = "BTM";
  uint public decimals = 8;
  string public name = "Bytom";
}

contract DAI_TOKEN is StandardToken {
  string public symbol = "DAI";
  uint public decimals = 18;
  string public name = "Dai";
}

contract GUSD_TOKEN is StandardToken {
  string public symbol = "GUSD";
  uint public decimals = 2;
  string public name = "Gemini Dollar";
}

contract ICX_TOKEN is StandardToken {
  string public symbol = "ICX";
  uint public decimals = 18;
  string public name = "ICON";
}

contract KNC_TOKEN is StandardToken {
  string public symbol = "KNC";
  uint public decimals = 18;
  string public name = "Kyber Network";
}

contract MKR_TOKEN is StandardToken {
  string public symbol = "MKR";
  uint public decimals = 18;
  string public name = "Maker";
}

contract OMG_TOKEN is StandardToken {
  string public symbol = "OMG";
  uint public decimals = 18;
  string public name = "OmiseGO";
}

contract RHOC_TOKEN is StandardToken {
  string public symbol = "RHOC";
  uint public decimals = 8;
  string public name = "RChain";
}

contract PAX_TOKEN is StandardToken {
  string public symbol = "PAX";
  uint public decimals = 18;
  string public name = "Paxos Standard Token";
}

contract PPT_TOKEN is StandardToken {
  string public symbol = "PPT";
  uint public decimals = 18;
  string public name = "Populous";
}

contract TUSD_TOKEN is StandardToken {
  string public symbol = "TUSD";
  uint public decimals = 18;
  string public name = "TrueUSD";
}

contract USDC_TOKEN is StandardToken {
  string public symbol = "USDC";
  uint public decimals = 6;
  string public name = "USD Coin";
}

contract VEN_TOKEN is StandardToken {
  string public symbol = "VEN";
  uint public decimals = 18;
  string public name = "VeChain";
}

contract WETH_TOKEN is StandardToken {
  string public symbol = "WETH";
  uint public decimals = 18;
  string public name = "Wrapped ETH";
}

contract WBCH_TOKEN is StandardToken {
  string public symbol = "WBCH";
  uint public decimals = 18;
  string public name = "Wrapped Bitcoin Cash";
}

contract WBTC_TOKEN is StandardToken {
  string public symbol = "WBTC";
  uint public decimals = 18;
  string public name = "Wrapped Bitcoin";
}

contract ZIL_TOKEN is StandardToken {
  string public symbol = "ZIL";
  uint public decimals = 12;
  string public name = "Zilliqa";
}

contract ZRX_TOKEN is StandardToken {
  string public symbol = "ZRX";
  uint public decimals = 18;
  string public name = "0x";
}