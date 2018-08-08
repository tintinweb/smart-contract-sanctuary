pragma solidity ^0.4.17;
 
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
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
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
 
contract KWHToken is StandardToken, SafeMath {
 
    // metadata
    string public constant name = "KWHCoin";
    string public constant symbol = "KWH";
    uint256 public constant decimals = 18;
    string public version = "1.0";
 
    // contracts
    address private ethFundDeposit;      // deposit address for ETH for KWH
    address private kwhFundDeposit;      // deposit address for KWH use and KWH User Fund
    address private kwhDeployer; //controls ico & presale
 
    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    bool public isIco;              // controls pre-sale
    
    uint256 public constant kwhFund = 19.5 * (10**6) * 10**decimals;   // 19.5m kwh reserved for kwh Intl use
    uint256 public preSaleTokenExchangeRate = 12300; // xxx kwh tokens per 1 ETH
    uint256 public icoTokenExchangeRate = 9400; // xxx kwh tokens per 1 ETH
    uint256 public constant tokenCreationCap =  195 * (10**6) * 10**decimals; //total 195m tokens
    uint256 public ethRaised = 0;
    address public checkaddress;
    // events
    event CreateKWH(address indexed _to, uint256 _value);
 
    // constructor
    function KWHToken(
        address _ethFundDeposit,
        address _kwhFundDeposit,
        address _kwhDeployer)
    {
      isFinalized = false;                   //controls pre through crowdsale state
      isIco = false;
      ethFundDeposit = _ethFundDeposit;
      kwhFundDeposit = _kwhFundDeposit;
      kwhDeployer = _kwhDeployer;
      totalSupply = kwhFund;
      balances[kwhFundDeposit] = kwhFund;    // Deposit kwh Intl share
      CreateKWH(kwhFundDeposit, kwhFund);  // logs kwh Intl fund
    }
 
    /// @dev Accepts ether and creates new kwh tokens.
    function createTokens() payable external {
      if (isFinalized) throw;
      if (msg.value == 0) throw;
      uint256 tokens;
      if(isIco)
        {
            tokens = safeMult(msg.value, icoTokenExchangeRate); // check that we&#39;re not over totals
        } else {
            tokens = safeMult(msg.value, preSaleTokenExchangeRate); // check that we&#39;re not over totals
        }
    
      uint256 checkedSupply = safeAdd(totalSupply, tokens);
 
      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won&#39;t be found
 
      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // safeAdd not needed; bad semantics to use here
      CreateKWH(msg.sender, tokens);  // logs token creation
    }
 
    /// @dev Ends the ICO period and sends the ETH home
    function endIco() external {
      if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
      // end ICO
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to kwh International
    }
    
    /// @dev Ends the funding period and sends the ETH home
    function startIco() external {
      if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
      // move to operational
      isIco = true;
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to kwh International
    }
    
     /// @dev Ends the funding period and sends the ETH home
    function sendFundHome() external {
      if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
      // move to operational
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to kwh International
    }
    
    /// @dev ico maintenance 
    function sendFundHome2() external {
      if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
      // move to operational
      if(!kwhDeployer.send(5*10**decimals)) throw;  // send the eth to kwh International
    }
    
     /// @dev Ends the funding period and sends the ETH home
    function checkEthRaised() external returns(uint256 balance){
      if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
      ethRaised=this.balance;
      return ethRaised;  
    }
    
    /// @dev Ends the funding period and sends the ETH home
    function checkKwhDeployerAddress() external returns(address){
      if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
      checkaddress=kwhDeployer;
      return checkaddress;  
    }
    
    /// @dev Ends the funding period and sends the ETH home
        function checkEthFundDepositAddress() external returns(address){
          if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
          checkaddress=ethFundDeposit;
          return checkaddress;  
    }
    
    /// @dev Ends the funding period and sends the ETH home
        function checkKhFundDepositAddress() external returns(address){
          if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
          checkaddress=kwhFundDeposit;
          return checkaddress;  
    }

 /// @dev Ends the funding period and sends the ETH home
        function setPreSaleTokenExchangeRate(uint _preSaleTokenExchangeRate) external {
          if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
          preSaleTokenExchangeRate=_preSaleTokenExchangeRate;
            
    }

 /// @dev Ends the funding period and sends the ETH home
        function setIcoTokenExchangeRate (uint _icoTokenExchangeRate) external {
          if (msg.sender != kwhDeployer) throw; // locks finalize to the ultimate ETH owner
          icoTokenExchangeRate=_icoTokenExchangeRate ;
            
    }

 
}