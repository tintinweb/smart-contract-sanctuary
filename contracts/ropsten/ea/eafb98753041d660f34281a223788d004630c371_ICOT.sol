/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity 0.4.24;

 /**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
    uint _numerator  = numerator * 10 ** (precision+1);
    uint _quotient =  ((_numerator / denominator) + 5) / 10;
    return (value*_quotient/1000000000000000000);
  }
}

contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  
  event CreateICOT(address indexed _to, uint256 _value);
}


contract ICOT is ERC20 { 
    
    using SafeMath for uint256;
    string public constant name     		= "ICOT";                    // Name of the token
    string public constant symbol   		= "ICOT";                       // Symbol of token
    uint8 public constant decimals  		= 18;                           // Decimal of token
    
	address public founder;      // deposit address for ETH for ICOT
	bool public isFinalized;              // switched to true in operational state
    bool public saleStarted; //switched to true during ICO
    uint public firstWeek;
    uint public secondWeek;
    uint public thirdWeek;
    uint256 public soldCoins;
    
  
    uint256 public constant founderFund = 5 * (10**6) * 10**decimals;   // 5M ICOT reserved for Owners
    uint256 public constant preMinedFund = 10 * (10**6) * 10**decimals;   // 10M ICOT reserved for Promotion, Exchange etc.
    uint256 public tokenExchangeRate = 2000; //  ICOT tokens per 1 ETH
	
	
	
   
    address public owner;                                           // Owner of this contract
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function ICOT() public {
		isFinalized = false;                   //controls pre through crowdsale state
      saleStarted = false;
      soldCoins = 0;
      founder = 0x6Be9ff4c8E54025D17A96bE74BbCBe3B2aa16E95;
	
        balances[msg.sender] = founderFund;
        Transfer(0, msg.sender, founderFund);
    }
    
    // what is the total supply
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = founderFund + preMinedFund;
    }
    
    // What is the balance of a particular account?
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom( address _from, address _to, uint256 _amount ) public returns (bool success) {
        require( _to != 0x0);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require( _spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        
        address _customerAddress = msg.sender;
                
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    // Transfer the balance from owner's account to another account
    function transferTokens(address _to, uint256 _amount) private returns (bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(address(this), _to, _amount);
        return true;
    }
 
    function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
	
	 /// @dev Accepts ether and creates new EVN tokens.
    function () payable {
      //bool isPreSale = true;
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
      //change exchange rate based on duration
      if (now > firstWeek && now < secondWeek){
        tokenExchangeRate = 1500;
      }
      else if (now > secondWeek && now < thirdWeek){
        tokenExchangeRate = 1000;
      }
      else if (now > thirdWeek){
        tokenExchangeRate = 500;
      }
      //create tokens
      uint256 tokens = SafeMath.mul(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = SafeMath.add(soldCoins, tokens);

      // return money if something goes wrong
      if (preMinedFund < checkedSupply) throw;  // odd fractions won't be found
      soldCoins = checkedSupply;
      //All good. start the transfer
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreateICOT(msg.sender, tokens);  // logs token creation
    }

    /// ICOT Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != founder) throw; // locks finalize to the ultimate ETH owner
      if (soldCoins < preMinedFund){
        uint256 remainingTokens = SafeMath.sub(preMinedFund, soldCoins);
        uint256 checkedSupply = SafeMath.add(soldCoins, remainingTokens);
        if (preMinedFund < checkedSupply) throw;
        soldCoins = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreateICOT(msg.sender, remainingTokens);
      }
      // move to operational
      if(!founder.send(this.balance)) throw;
      isFinalized = true;  // send the eth to ICOT
      
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != founder) throw; // locks start sale to the ultimate ETH owner
      firstWeek = now + 1 weeks; //sets duration of first cutoff
      secondWeek = firstWeek + 1 weeks; //sets duration of second cutoff
      thirdWeek = secondWeek + 1 weeks; //sets duration of third cutoff
      saleStarted = true; //start the sale
    }
}