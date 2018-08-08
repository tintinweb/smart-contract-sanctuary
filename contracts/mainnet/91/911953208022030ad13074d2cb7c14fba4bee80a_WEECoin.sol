contract WeeMath {

    function subtractWee(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function multWee(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract ERC20Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Token {

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
	uint256 public totalSupply;
}


contract WEECoin is StandardToken, WeeMath {

    string public constant name = "WEE Token";
    string public constant symbol = "WEE";
    uint256 public constant decimals = 18;
    string public version = "1.0";
	
    address public WEEFundWallet;      
    address public account1Address;      
    address public account2Address;
    address public account3Address;
    
    bool public isFinalized;
    bool public isPreSale;    
    bool public isMainSale;
    uint public preSalePeriod;    
    uint256 public weeOneEthCanBuy = 0; 	
    uint256 public constant tokenSaleCap =  500 * (10**6) * 10**decimals;
    uint256 public constant tokenPreSaleCap = 150 * (10**6) * 10**decimals; 
	uint256 public constant tokensForFinalize =  150 * (10**6) * 10**decimals;
	uint256 public totalEthInWei;  
	
    event LogWEE(address indexed _to, uint256 _value);

    function WEECoin()
    {                      
      WEEFundWallet =  msg.sender;
      account1Address = 0xe98FF512B5886Ef34730b0C84624f63bAD0A5212;	                    
      account2Address = 0xDaB2365752B3Fe5E630d68F357293e26873288ff;	                    
      account3Address = 0xfF5706dcCbA47E12d8107Dcd3CA5EF62e355b31E;	                    
      isPreSale = false;
      isMainSale = false;
	  isFinalized = false;   
      totalSupply = ( (10**9) * 10**decimals ) + ( 100 * (10**6) * 10**decimals );
	  balances[WEEFundWallet] = totalSupply;         
    }

    function () payable 
	{      
      if ( (isFinalized) || (!isPreSale && !isMainSale) || (msg.value == 0) ) throw;
      
      uint256 tokens = multWee(msg.value, weeOneEthCanBuy); 
      uint256 verifiedLeftTokens = subtractWee(balances[WEEFundWallet], tokens);

	  if( (isMainSale) && (verifiedLeftTokens < (totalSupply - tokenSaleCap)) ) throw;
	  if (balances[WEEFundWallet] < tokens) throw;
	  
      if( (isPreSale) && (verifiedLeftTokens < (totalSupply - tokenPreSaleCap) ) )
	  {			
		isMainSale = true;
		weeOneEthCanBuy = 10000; 	
		isPreSale = false;		
	  }     	  
     
      balances[msg.sender] += tokens;  
	  balances[WEEFundWallet] -= tokens;
      LogWEE(msg.sender, tokens);  
	  
      WEEFundWallet.transfer(msg.value);   	 
	  totalEthInWei = totalEthInWei + msg.value;	  
    }

    function finalize() external {
      if( (isFinalized) || (msg.sender != WEEFundWallet) ) throw;
              
      balances[account1Address] += tokensForFinalize;
	  LogWEE(account1Address, tokensForFinalize);
	  
      balances[account2Address] += tokensForFinalize;
      LogWEE(account2Address, tokensForFinalize);
     
	  balances[account3Address] += tokensForFinalize;
	  LogWEE(account3Address, tokensForFinalize);
	  
	  balances[WEEFundWallet] -= (tokensForFinalize * 3);
	  
      isFinalized = true;  
    }
	
    function switchStage() external {
      if ( (isMainSale) || (msg.sender != WEEFundWallet) ) throw;
      	  
      if (!isPreSale){
        isPreSale = true;
        weeOneEthCanBuy = 20000;
      }
      else if (!isMainSale){
        isMainSale = true;
		isPreSale = false;
        weeOneEthCanBuy = 10000;       
      }
    }
}