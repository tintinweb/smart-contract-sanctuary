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

contract Phoenix is StandardToken, SafeMath {

    // metadata
    string public constant name = "Phoenix";
    string public constant symbol = "PHX";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Phoenix
    address public PhoenixFundDeposit;      // deposit address for depositing tokens for owners
    address public PhoenixExchangeDeposit;      // deposit address depositing tokens for promotion, Exchange

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    bool public saleStarted; //switched to true during ICO
    uint public firstWeek;
    uint public secondWeek;
    uint public thirdWeek;
    uint public fourthWeek;
    uint256 public bonus;
    uint256 public constant PhoenixFund = 125 * (10**5) * 10**decimals;   // 12.5m Phoenix reserved for Owners
    uint256 public constant PhoenixExchangeFund = 125 * (10**5) * 10**decimals;   // 12.5m Phoenix reserved for Promotion, Exchange etc.
    uint256 public tokenExchangeRate = 55; //  Phoenix tokens per 1 ETH
    uint256 public constant tokenCreationCap =  50 * (10**6) * 10**decimals;
    uint256 public constant tokenPreSaleCap =  375 * (10**5) * 10**decimals;


    // events
    event CreatePHX(address indexed _to, uint256 _value);

    // constructor
    function Phoenix()
    {
      isFinalized = false;                   //controls pre through crowdsale state
      saleStarted = false;
      PhoenixFundDeposit = &#39;0xCA0664Cc0c1E1EE6CF4507670C9060e03f16F508&#39;;
      PhoenixExchangeDeposit = &#39;0x7A0B7a6c058b354697fbC5E641C372E877593631&#39;;
      ethFundDeposit = &#39;0xfF0b05152A8477A92E5774685667e32484A76f6A&#39;;
      totalSupply = PhoenixFund + PhoenixExchangeFund;
      balances[PhoenixFundDeposit] = PhoenixFund;    // Deposit tokens for Owners
      balances[PhoenixExchangeDeposit] = PhoenixExchangeFund;    // Deposit tokens for Exchange and Promotion
      CreatePHX(PhoenixFundDeposit, PhoenixFund);  // logs Owners deposit
      CreatePHX(PhoenixExchangeDeposit, PhoenixExchangeFund);  // logs Exchange deposit
    }

    /// @dev Accepts ether and creates new BAT tokens.
    function () payable {
      bool isPreSale = true;
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
      //change exchange rate based on duration
      if (now > firstWeek && now < secondWeek){
        tokenExchangeRate = 41;
      }
      else if (now > secondWeek && now < thirdWeek){
        tokenExchangeRate = 29;
      }
      else if (now > thirdWeek && now < fourthWeek){
        tokenExchangeRate = 25;
      }
      else if (now > fourthWeek){
        tokenExchangeRate = 18;
        isPreSale = false;
      }
      //create tokens
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we&#39;re not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      // return money if something goes wrong
      if(isPreSale && tokenPreSaleCap < checkedSupply) throw;
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won&#39;t be found
      totalSupply = checkedSupply;
      //All good. start the transfer
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreatePHX(msg.sender, tokens);  // logs token creation
    }

    /// Phoenix Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if (totalSupply < tokenCreationCap){
        uint256 remainingTokens = safeSubtract(tokenCreationCap, totalSupply);
        uint256 checkedSupply = safeAdd(totalSupply, remainingTokens);
        if (tokenCreationCap < checkedSupply) throw;
        totalSupply = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreatePHX(msg.sender, remainingTokens);
      }
      // move to operational
      if(!ethFundDeposit.send(this.balance)) throw;
      isFinalized = true;  // send the eth to Phoenix
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != ethFundDeposit) throw; // locks start sale to the ultimate ETH owner
      firstWeek = now + 1 weeks; //sets duration of first cutoff
      secondWeek = firstWeek + 1 weeks; //sets duration of second cutoff
      thirdWeek = secondWeek + 1 weeks; //sets duration of third cutoff
      fourthWeek = thirdWeek + 1 weeks; //sets duration of fourth cutoff
      saleStarted = true; //start the sale
    }


}