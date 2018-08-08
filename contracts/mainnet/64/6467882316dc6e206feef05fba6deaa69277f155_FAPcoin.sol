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

contract FAPcoin is StandardToken, SafeMath {

    // metadata
    string public constant name = "FAPcoin";
    string public constant symbol = "FAP";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for FAP
    address public FAPFounder;
    address public FAPFundDeposit1;      // deposit address for depositing tokens for owners
    address public FAPFundDeposit2;      // deposit address for depositing tokens for owners
    address public FAPFundDeposit3;      // deposit address for depositing tokens for owners
    address public FAPFundDeposit4;      // deposit address for depositing tokens for owners
    address public FAPFundDeposit5;      // deposit address for depositing tokens for owners

    // crowdsale parameters
    uint public firstStage;
    uint public secondStage;
    uint public thirdStage;
    uint public fourthStage;
    bool public isFinalized;              // switched to true in operational state
    bool public saleStarted; //switched to true during ICO
    uint256 public constant FAPFund = 50 * (10**6) * 10**decimals;   // FAPcoin reserved for Owners
    uint256 public constant FAPFounderFund = 150 * (10**6) * 10**decimals;   // FAPcoin reserved for Owners
    uint256 public tokenExchangeRate = 1500; //  FAPcoin tokens per 1 ETH
    uint256 public constant tokenCreationCap =  500 * (10**6) * 10**decimals;


    // events
    event CreateFAP(address indexed _to, uint256 _value);

    // constructor
    function FAPcoin()
    {
      isFinalized = false;                   //controls pre through crowdsale state
      saleStarted = false;
      FAPFounder = &#39;0x97F5eD1c6af0F45B605f4Ebe62Bae572B2e2198A&#39;;
      FAPFundDeposit1 = &#39;0xF946cB03dC53Bfc13a902022C1c37eA830F8E35B&#39;;
      FAPFundDeposit2 = &#39;0x19Eb1FE8Fdc51C0f785F455D8aB3BD22Af50cf11&#39;;
      FAPFundDeposit3 = &#39;0xaD349885e35657956859c965670c41EE9A044b84&#39;;
      FAPFundDeposit4 = &#39;0x4EEbfDEe9141796AaaA65b53A502A6DcFF21d397&#39;;
      FAPFundDeposit5 = &#39;0x20a0A5759a56aDE253cf8BF3683923D7934CC84a&#39;;
      ethFundDeposit = &#39;0x6404B11A733b8a62Bd4bf3A27d08e40DD13a5686&#39;;
      totalSupply = safeMult(FAPFund,5);
      totalSupply = safeAdd(totalSupply,FAPFounderFund);
      balances[FAPFundDeposit1] = FAPFund;    // Deposit tokens for Owners
      balances[FAPFundDeposit2] = FAPFund;    // Deposit tokens for Owners
      balances[FAPFundDeposit3] = FAPFund;    // Deposit tokens for Owners
      balances[FAPFundDeposit4] = FAPFund;    // Deposit tokens for Owners
      balances[FAPFundDeposit5] = FAPFund;    // Deposit tokens for Owners
      balances[FAPFounder] = FAPFounderFund;    // Deposit tokens for Owners
      CreateFAP(FAPFundDeposit1, FAPFund);  // logs Owners deposit
      CreateFAP(FAPFundDeposit2, FAPFund);  // logs Owners deposit
      CreateFAP(FAPFundDeposit3, FAPFund);  // logs Owners deposit
      CreateFAP(FAPFundDeposit4, FAPFund);  // logs Owners deposit
      CreateFAP(FAPFundDeposit5, FAPFund);  // logs Owners deposit
      CreateFAP(FAPFounder, FAPFounderFund);  // logs Owners deposit
    }

    /// @dev Accepts ether and creates new FAP tokens.
    function () payable {
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
      //change exchange rate based on duration
      if (now > firstStage && now <= secondStage){
        tokenExchangeRate = 1300;
      }
      else if (now > secondStage && now <= thirdStage){
        tokenExchangeRate = 1100;
      }
      if (now > thirdStage && now <= fourthStage){
        tokenExchangeRate = 1050;
      }
      if (now > fourthStage){
        tokenExchangeRate = 1000;
      }
      //create tokens
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we&#39;re not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won&#39;t be found
      totalSupply = checkedSupply;
      //All good. start the transfer
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreateFAP(msg.sender, tokens);  // logs token creation
    }

    /// FAPcoin Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if (totalSupply < tokenCreationCap){
        uint256 remainingTokens = safeSubtract(tokenCreationCap, totalSupply);
        uint256 checkedSupply = safeAdd(totalSupply, remainingTokens);
        if (tokenCreationCap < checkedSupply) throw;
        totalSupply = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreateFAP(msg.sender, remainingTokens);
      }
      // move to operational
      if(!ethFundDeposit.send(this.balance)) throw;
      isFinalized = true;  // send the eth to FAPcoin
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != ethFundDeposit) throw; // locks start sale to the ultimate ETH owner
      firstStage = now + 15 days; //sets duration of first cutoff
      secondStage = firstStage + 15 days; //sets duration of second cutoff
      thirdStage = secondStage + 7 days; //sets duration of third cutoff
      fourthStage = thirdStage + 6 days; //sets duration of third cutoff
      saleStarted = true; //start the sale
    }


}