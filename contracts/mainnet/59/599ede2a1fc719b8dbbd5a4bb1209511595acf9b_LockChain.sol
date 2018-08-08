pragma solidity ^0.4.11;

/* taking ideas from FirstBlood token */
contract SafeMath {

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

contract LockChain is StandardToken, SafeMath {

    // metadata
    string public constant name = "LockChain";
    string public constant symbol = "LOK";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public LockChainFundDeposit;      // deposit address for depositing tokens for owners
    address public account1Address;      // deposit address for depositing tokens for owners
    address public account2Address;
    address public creatorAddress;

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    bool public isPreSale;
    bool public isPrePreSale;
    bool public isMainSale;
    uint public preSalePeriod;
    uint public prePreSalePeriod;
    uint256 public tokenExchangeRate = 0; //  LockChain tokens per 1 ETH
    uint256 public constant tokenSaleCap =  155 * (10**6) * 10**decimals;
    uint256 public constant tokenPreSaleCap =  50 * (10**6) * 10**decimals;


    // events
    event CreateLOK(address indexed _to, uint256 _value);

    // constructor
    function LockChain()
    {
      isFinalized = false;                   //controls pre through crowdsale state
      LockChainFundDeposit = &#39;0x013aF31dc76255d3b33d2185A7148300882EbC7a&#39;;
      account1Address = &#39;0xe0F2653e7928e6CB7c6D3206163b3E466a29c7C3&#39;;
      account2Address = &#39;0x25BC70bFda877e1534151cB92D97AC5E69e1F53D&#39;;
      creatorAddress = &#39;0x953ebf6C38C58C934D58b9b17d8f9D0F121218BB&#39;;
      isPrePreSale = false;
      isPreSale = false;
      isMainSale = false;
      totalSupply = 0;
    }

    /// @dev Accepts ether and creates new LOK tokens.
    function () payable {
      if (isFinalized) throw;
      if (!isPrePreSale && !isPreSale && !isMainSale) throw;
      //if (!saleStarted) throw;
      if (msg.value == 0) throw;
      //create tokens
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we&#39;re not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      if(!isMainSale){
        if (tokenPreSaleCap < checkedSupply) throw;
      }

      // return money if something goes wrong
      if (tokenSaleCap < checkedSupply) throw;  // odd fractions won&#39;t be found
      totalSupply = checkedSupply;
      //All good. start the transfer
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreateLOK(msg.sender, tokens);  // logs token creation
    }

    /// LockChain Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != LockChainFundDeposit) throw; // locks finalize to the ultimate ETH owner
        uint256 newTokens = totalSupply;
        uint256 account1Tokens;
        uint256 account2Tokens;
        uint256 creatorTokens = 10000 * 10**decimals;
        uint256 LOKFundTokens;
        uint256 checkedSupply = safeAdd(totalSupply, newTokens);
        totalSupply = checkedSupply;
        if (newTokens % 2 == 0){
          LOKFundTokens = newTokens/2;
          account2Tokens = newTokens/2;
          account1Tokens = LOKFundTokens - creatorTokens;
          balances[account1Address] += account1Tokens;
          balances[account2Address] += account2Tokens;
        }
        else{
          uint256 makeEven = newTokens - 1;
          uint256 halfTokens = makeEven/2;
          LOKFundTokens = halfTokens;
          account2Tokens = halfTokens + 1;
          account1Tokens = LOKFundTokens - creatorTokens;
          balances[account1Address] += account1Tokens;
          balances[account2Address] += account2Tokens;
        }
        balances[creatorAddress] += creatorTokens;
        CreateLOK(creatorAddress, creatorTokens);
        CreateLOK(account1Address, account1Tokens);
        CreateLOK(account2Address, account2Tokens);
      // move to operational
      if(!LockChainFundDeposit.send(this.balance)) throw;
      isFinalized = true;  // send the eth to LockChain
    }
    function switchSaleStage() external {
      if (msg.sender != LockChainFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if(isMainSale) throw;
      if(!isPrePreSale){
        isPrePreSale = true;
        tokenExchangeRate = 1150;
      }
      else if (!isPreSale){
        isPreSale = true;
        tokenExchangeRate = 1000;
      }
      else if (!isMainSale){
        isMainSale = true;
        if (totalSupply < 10 * (10**6) * 10**decimals)
        {
          tokenExchangeRate = 750;
        }
        else if (totalSupply >= 10 * (10**6) * 10**decimals && totalSupply < 20 * (10**6) * 10**decimals)
        {
          tokenExchangeRate = 700;
        }
        else if (totalSupply >= 20 * (10**6) * 10**decimals && totalSupply < 30 * (10**6) * 10**decimals)
        {
          tokenExchangeRate = 650;
        }
        else if (totalSupply >= 30 * (10**6) * 10**decimals && totalSupply < 40 * (10**6) * 10**decimals)
        {
          tokenExchangeRate = 620;
        }
        else if (totalSupply >= 40 * (10**6) * 10**decimals && totalSupply <= 50 * (10**6) * 10**decimals)
        {
          tokenExchangeRate = 600;
        }

      }
    }


}