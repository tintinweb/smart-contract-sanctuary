/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity ^0.4.24;

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

contract BEP20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract Unitech is BEP20 { 
    
    using SafeMath for uint256;
    string public constant name     		= "Unitech";                  // Name of the token
    string public constant symbol   		= "UTC";                       // Symbol of token
    uint8 public constant decimals  		= 18;                           // Decimal of token
    uint public preminedexchangefund       	= 8200000 * 10 ** 18;           // 8.2 million for preminedexchange
    uint public founderfund          		= 4100000 * 10 ** 18;           // 4.1 million for Founder
    uint public useinognfund          		= 4100000 * 10 ** 18;          // 4.1  million for use in ongo
    uint public airdropfund          		= 4100000 * 10 ** 18;          // 4.1 million for airdrop
    uint public ecosystemfund          		= 20500000 * 10 ** 18;          // 20.5 million for ecosystem	
   
    
    address public owner;     
	address public preminedexchange;
	address public founder;
	address public useinogn;
	address public airdrop;
	address public ecosystem;
	
	
	mapping(address => uint256) internal tokenBalanceLedger_;
  
	
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
	
	//Genesis Mining start
	
    uint256 public initialSupplyPerAddress;
    uint256 public initialBlockCount;
    uint256 private minedBlocks;
    uint256 public rewardPerBlockPerAddress;
    uint256 private availableAmount;
	uint256 private availableAmountpreminedexchange;
	uint256 private availableAmountfounder;
	uint256 private availableAmountuseinogn;
	uint256 private availableAmountairdrop;
    uint256 private availableAmountecosystem;
  
	
	
    uint256 private availableBalance;
    uint256 private totalMaxAvailableAmount;
     mapping (address => bool) public genesisAddress;
	 
	 uint256 public founderperblock;
	 uint256 public useinognperblock;
	 uint256 public airdropperblock;
	 uint256 public ecosystemperblock;
	
	 
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function Unitech() {
	
		
		preminedexchange= 0xf3a0372542c2d36e1e2da7882699d60D3B96117f;
		founder= 0xE3892e410d53B9b67E270e82b4a2B586f8153AC0;
		useinogn= 0x50C33ca79f6FB7d8adac6F3254A5BE6bf6bce413;
		airdrop= 0xCC0a1A2BDE0ccc906fd10d8691Cd5b88350A7812;
		ecosystem= 0xE78AD07151465ac6AEe94259ed3C744501A70a30;
		
		
		      
		
		balances[preminedexchange] = preminedexchangefund;
        Transfer(0, preminedexchange, preminedexchangefund);
		
				
		founderperblock   	= 78000000000000000;
		useinognperblock    = 78000000000000000;
		airdropperblock  	= 78000000000000000;
		ecosystemperblock  	= 390000000000000000;
		
		balances[founder] 	= founderfund;
		balances[useinogn] 	= useinognfund;
		balances[airdrop] 	= airdropfund;
		balances[ecosystem] = ecosystemfund;
				
		
		
		initialBlockCount = block.number;
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

    
	
	 function transfer(address _to, uint256 _value)
    {
      
      if (balances[msg.sender] < _value) throw;

      if (balances[_to] + _value < balances[_to]) throw;

     
	  
	  //founder transfer
	  if (msg.sender == founder)
      {
    	   minedBlocks = block.number - initialBlockCount;
         if(minedBlocks % 2 != 0){
           minedBlocks = minedBlocks - 1;
         }
    	    if (minedBlocks < 52560000)
    	     {
    		       availableAmount = founderperblock*minedBlocks;
    		       totalMaxAvailableAmount = founderfund - availableAmount;
    		       availableBalance = balances[msg.sender] - totalMaxAvailableAmount;
    		       if (_value > availableBalance) throw;
    	     }
      }
	  
	   //useinogn transfer
	  if (msg.sender == useinogn)
      {
    	   minedBlocks = block.number - initialBlockCount;
         if(minedBlocks % 2 != 0){
           minedBlocks = minedBlocks - 1;
         }
    	    if (minedBlocks < 52560000)
    	     {
    		       availableAmount = useinognperblock*minedBlocks;
    		       totalMaxAvailableAmount = useinognfund - availableAmount;
    		       availableBalance = balances[msg.sender] - totalMaxAvailableAmount;
    		       if (_value > availableBalance) throw;
    	     }
      }
	  
	   //airdrop transfer
	  if (msg.sender == airdrop)
      {
    	   minedBlocks = block.number - initialBlockCount;
         if(minedBlocks % 2 != 0){
           minedBlocks = minedBlocks - 1;
         }
    	    if (minedBlocks < 52560000)
    	     {
    		       availableAmount = airdropperblock*minedBlocks;
    		       totalMaxAvailableAmount = airdropfund - availableAmount;
    		       availableBalance = balances[msg.sender] - totalMaxAvailableAmount;
    		       if (_value > availableBalance) throw;
    	     }
      }
	  
	  
	  
	  //ecosystem transfer
	  if (msg.sender == ecosystem)
      {
    	   minedBlocks = block.number - initialBlockCount;
         if(minedBlocks % 2 != 0){
           minedBlocks = minedBlocks - 1;
         }
    	    if (minedBlocks < 52560000)
    	     {
    		       availableAmount = ecosystemperblock*minedBlocks;
    		       totalMaxAvailableAmount = ecosystemfund - availableAmount;
    		       availableBalance = balances[msg.sender] - totalMaxAvailableAmount;
    		       if (_value > availableBalance) throw;
    	     }
      }
	  
	  
	  
	  
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
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
	
	function currentEthBlock() constant returns (uint256 blockNumber)
    {
    	return block.number;
    }

    function currentBlock() constant returns (uint256 blockNumber)
    {
      if(initialBlockCount == 0){
        return 0;
      }
      else{
      return block.number - initialBlockCount;
    }
    }
	
	
	  function availableBalanceOf(address _address) constant returns (uint256 Balance)
    {
    	
    			
		//founder availableBalance
		if (_address == founder)
    	{
    		minedBlocks = block.number - initialBlockCount;
        if(minedBlocks % 2 != 0){
          minedBlocks = minedBlocks - 1;
        }

    		if (minedBlocks >= 52560000) return balances[_address];
    		  availableAmount = founderperblock*minedBlocks;
    		  totalMaxAvailableAmount = founderfund - availableAmount;
          availableBalance = balances[_address] - totalMaxAvailableAmount;
          return availableBalance;
    	}
		
		//useingo availableBalance
		else if (_address == useinogn)
    	{
    		minedBlocks = block.number - initialBlockCount;
        if(minedBlocks % 2 != 0){
          minedBlocks = minedBlocks - 1;
        }

    		if (minedBlocks >= 52560000) return balances[_address];
    		  availableAmount = useinognperblock*minedBlocks;
    		  totalMaxAvailableAmount = useinognfund - availableAmount;
          availableBalance = balances[_address] - totalMaxAvailableAmount;
          return availableBalance;
    	}
		
		//airdrop availableBalance
		else if (_address == useinogn)
    	{
    		minedBlocks = block.number - initialBlockCount;
        if(minedBlocks % 2 != 0){
          minedBlocks = minedBlocks - 1;
        }

    		if (minedBlocks >= 52560000) return balances[_address];
    		  availableAmount = airdropperblock*minedBlocks;
    		  totalMaxAvailableAmount = airdropfund - availableAmount;
          availableBalance = balances[_address] - totalMaxAvailableAmount;
          return availableBalance;
    	}
    	
    			
		//ecosystem availableBalance
		else if (_address == ecosystem)
    	{
    		minedBlocks = block.number - initialBlockCount;
        if(minedBlocks % 2 != 0){
          minedBlocks = minedBlocks - 1;
        }

    		if (minedBlocks >= 52560000) return balances[_address];
    		  availableAmount = ecosystemperblock*minedBlocks;
    		  totalMaxAvailableAmount = ecosystemfund - availableAmount;
          availableBalance = balances[_address] - totalMaxAvailableAmount;
          return availableBalance;
    	}
    	
		
    	else {
    		return balances[_address];
		}
		
		
    }

    function totalSupply() constant returns (uint256 totalSupply)
    {
      if (initialBlockCount != 0)
      {
      minedBlocks = block.number - initialBlockCount;
      if(minedBlocks % 2 != 0){
        minedBlocks = minedBlocks - 1;
      }
    	availableAmount = rewardPerBlockPerAddress*minedBlocks;
    	availableAmountfounder = founderperblock*minedBlocks;
    	availableAmountuseinogn = useinognperblock*minedBlocks;
    	availableAmountairdrop = airdropperblock*minedBlocks;
    	availableAmountecosystem = ecosystemperblock*minedBlocks;
    }
    else{
      availableAmount = 0;
	  availableAmountfounder = 0;
    	availableAmountuseinogn = 0;
    	availableAmountairdrop = 0;
    	availableAmountecosystem = 0;
    }
    	return availableAmountfounder+availableAmountuseinogn+availableAmountairdrop+availableAmountecosystem+preminedexchangefund;
    }

    function maxTotalSupply() constant returns (uint256 maxSupply)
    {
    	return founderfund+useinognfund+airdropfund+ecosystemfund+preminedexchangefund;
    }
	

    function ownershare() internal onlyOwner {
        owner.transfer(this.balance);
    }
}