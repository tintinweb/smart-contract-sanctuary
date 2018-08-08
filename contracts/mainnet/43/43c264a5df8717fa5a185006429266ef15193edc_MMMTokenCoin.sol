pragma solidity ^0.4.19;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  
 
}


contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

 
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
 
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
 
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }
 
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  

 
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function  transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }
  

 
}
 
 
 
 

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  
  
   function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    if(b==0) return 1;
    assert(b>=0);
    uint256 c = a ** b;
    assert(c>=a );
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  
function compoundInterest(uint256 depo, uint256 stage2, uint256 start, uint256 current)  internal pure returns (uint256)  {
            if(current<start || start<stage2 || current<stage2) return depo;

            uint256 ret=depo; uint256 g; uint256 d;
            stage2=stage2/1 days;
            start=start/1 days;
            current=current/1 days;
    
			uint256 dpercent=100;
			uint256 i=start;
			
			if(i-stage2>365) dpercent=200;
			if(i-stage2>730) dpercent=1000;			
			
			while(i<current)
			{

				g=i-stage2;			
				if(g>265 && g<=365) 
				{		
				    d=365-g;
					if(d>=(current-start))  d=(current-start);
					ret=fracExp(ret, dpercent, d, 8);
				    i+=d;
					dpercent=200;
				}
				if(g>630 && g<=730) 
				{				
					d=730-g;	
					if(d>=(current-start))  d=(current-start);					
					ret=fracExp(ret, dpercent, d, 8);
					i+=d;
					dpercent=1000;					
				}
				else if(g>730) dpercent=1000;				
				else if(g>365) dpercent=200;
				
				if(i+100<current) ret=fracExp(ret, dpercent, 100, 8);
				else return fracExp(ret, dpercent, current-i, 8);
				i+=100;
				
			}

			return ret;
			
			
    
    
	}


function fracExp(uint256 depo, uint256 percent, uint256 period, uint256 p)  internal pure returns (uint256) {
  uint256 s = 0;
  uint256 N = 1;
  uint256 B = 1;
  

  
  for (uint256 i = 0; i < p; ++i){
    s += depo * N / B / (percent**i);
    N  = N * (period-i);
    B  = B * (i+1);
  }
  return s;
}







}



contract MMMTokenCoin is StandardToken, Ownable {
    using SafeMath for uint256;
    
    string public constant name = "Make More Money";
    string public constant symbol = "MMM";
    uint32 public constant decimals = 2;
    
	
	// Dates
	uint256 public stage2StartTime;					// timestamp when compound interest will begin
    uint256 globalInterestDate;             // last date when amount of tokens with interest was changed
    uint256 globalInterestAmount;           // amount of tokens with interest
	mapping(address => uint256) dateOfStart;     // timestamp of last operation, from which interest calc will be started
	uint256 public currentDate;						// current date timestamp
	uint256 public debugNow=0;



    // Crowdsale 
    uint256 public totalSupply=99900000000;			
 uint256 public  softcap;
    uint256 public  step0Rate=100000;       // rate of our tokens. 1 eth = 1000 MMM coins = 100000 tokens (seen as 1000,00 because of decimals)
    uint256 public  currentRate=100000;   
    uint256 public constant tokensForOwner=2000000000;   // tokens for owner won&#39;t dealt with compound interest
    uint256 public tokensFromEther=0;
    uint public saleStatus=0;      // 0 - sale is running, 1 - sale failed, 2 - sale successful
    address multisig=0x8216A5958f05ad61898e3A6F97ae5118C0e4b1A6;
    // counters of tokens for futher refund
    mapping(address => uint256) boughtWithEther;                // tokens, bought with ether. can be refunded to ether
    mapping(address => uint256) boughtWithOther;    			// tokens, bought with other payment systems. can be refunded to other payment systems, using site
    mapping(address => uint256) bountyAndRefsWithEther;  		// bounty tokens, given to some people. can be converted to ether, if ico is succeed
  
    

		
		
    // events
    event RefundEther(address indexed to, uint256 tokens, uint256 eth); 
    event DateUpdated(uint256 cdate);    
    event DebugLog(string what, uint256 param);
    event Sale(address indexed to, uint256 amount);
    event Step0Finished();
    event RateSet(uint256 newRate);	
    event Burn(address indexed who, uint256 amount);
   // DEBUG

    bool bDbgEnabled=false;
	
	
	
    function MMMTokenCoin() public   {  
        // Crowdsale     
        currentDate=(getNow()/1 days)*1 days;
        stage2StartTime=getNow()+61 days;
        
        balances[owner]=tokensForOwner;
        globalInterestAmount=0;
        
        if(bDbgEnabled) softcap=20000;
        else  softcap=50000000;
    }
	
	
	function debugSetNow(uint256 n) public
	{
	    require(bDbgEnabled);
		debugNow=n;
	}
	
	
	 /**
     * @dev Returns current timestamp. In case of debugging, this function can return timestamp representing any other time
     */
     
     
	function getNow() public view returns (uint256)
	{
	    
	    if(!bDbgEnabled) return now;
	    
	    if(debugNow==0) return now;
		else return debugNow;
//		return now;
	}
   
    /**
     * @dev Sets date from which interest will be calculated for specified address
     * @param _owner - address of balance owner
     */
   
    
    function updateDate(address _owner) private {
        if(currentDate<stage2StartTime) dateOfStart[_owner]=stage2StartTime;
        else dateOfStart[_owner]=currentDate;
    }
    

	
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of. 
    * @return An uint25664 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) 
    { 
        
         return balanceWithInterest(_owner);
    }   
   
	
    /**
     * @dev Gets balance including interest for specified address
   	 * @param _owner The address to query the the balance of. 
     */
		
		
    function balanceWithInterest(address _owner)  private constant returns (uint256 ret)
    {
        if( _owner==owner || saleStatus!=2) return balances[_owner]; 
        return balances[_owner].compoundInterest(stage2StartTime, dateOfStart[_owner], currentDate);
    }
    
    
    
    
    


    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
		 
  function transfer(address _to, uint256 _value)  public returns (bool) {
    if(msg.sender==owner) {
    	// if owner sends tokens before sale finish, consider then as ether-refundable bonus
    	// else as simple transfer
        if(saleStatus==0) {
            	transferFromOwner(_to, _value,1);
            	tokensFromEther=tokensFromEther.add(_value);
				bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add(_value);
        	}
        	else transferFromOwner(_to, _value,0);
        	
        	increaseGlobalInterestAmount(_value);
        	return true;   
    }
    
    balances[msg.sender] = balanceWithInterest(msg.sender).sub(_value);

    emit Transfer(msg.sender, _to, _value);
    if(_to==address(this)) {
		// make refund if tokens sent to contract
        uint256 left; left=processRefundEther(msg.sender, _value);
        balances[msg.sender]=balances[msg.sender].add(left);
    }
    else {
        balances[_to] = balanceWithInterest(_to).add(_value);
        updateDate(_to);
    }
    
    if(_to==owner) 
    {
    	// before sale finish, tokens can&#39;t be sent to owner
        require(saleStatus!=0);
        decreaseGlobalInterestAmount(_value);
    }
    
    updateDate(msg.sender);
    return true;
  }
  
  
  /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transfered
    */
	  
  
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
           require(_to!=owner);
    uint256 _allowance = allowed[_from][msg.sender];

     allowed[_from][msg.sender] = _allowance.sub(_value);

    if(_from==owner) {
        if(saleStatus==0) {
            transferFromOwner(_to, _value,1);
            tokensFromEther=tokensFromEther.add(_value);
			bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add(_value);			
        }
        else transferFromOwner(_to, _value,0);
      
        increaseGlobalInterestAmount(_value);
        return true;
    }
     
     
    balances[_from] = balanceWithInterest(_from).sub(_value);

     emit Transfer(_from, _to, _value);

    if(_to==address(this)) {
		// make refund if tokens sent to contract		   
        uint256 left; left=processRefundEther(_from, _value);
        balances[_from]=balances[_from].add(left);
    }
    else {
        balances[_to] = balanceWithInterest(_to).add(_value);
        updateDate(_to);
    }
    
    if(_to==owner) 
    {
        require(saleStatus!=0);
        decreaseGlobalInterestAmount(_value);
    }

    updateDate(_from);

    return true;
  }
  
  
  
    /**
    * @dev Burns tokens
    * @param _amount amount of tokens to burn
    */
	  
	  
	  
  function burn(uint256 _amount) public 
  {
	  	require(_amount>0);
        balances[msg.sender]=balanceOf(msg.sender).sub(_amount);
		decreaseGlobalInterestAmount(_amount);
        emit Burn(msg.sender, _amount);
  }
   
   //// SALE ////
   
    /**
     * @dev updates rate with whic tokens are being sold
     */

 	function setRate(uint256 r) public {
		require(saleStatus!=0);
		currentRate=r;
		emit RateSet(currentRate);
	}

    /**
     * @dev updates current date value. For compound interest calculation
     */
    
    function newDay() public   returns (bool b)
    {
        
       uint256 g; uint256 newDate;
       require(getNow()>=stage2StartTime);
       require(getNow()>=currentDate);
       newDate=(getNow()/1 days)*1 days;
        if(getNow()>=stage2StartTime && saleStatus==0)
        {
            if(tokensForOwner.sub(balances[owner])>=softcap) saleStatus=2;
            else saleStatus=1;
         
            emit Step0Finished();
        }
      
	   // check if overall compound interest of tokens will be less than total supply
	  
       g=globalInterestAmount.compoundInterest(stage2StartTime, globalInterestDate, newDate);
       if(g<=totalSupply && saleStatus==2) {
             currentDate=(getNow()/1 days)*1 days; 
             globalInterestAmount=g;
             globalInterestDate=currentDate;
             emit DateUpdated(currentDate);
             return true;
       }
       else if(saleStatus==1) currentDate=(getNow()/1 days)*1 days; 
       
       return false;
    }
    
    
    /**
     * @dev Sends collected ether to owner. If sale is not success, contract will hold ether for half year, and after, ether can be sent to owner
     * @return amount of owner&#39;s ether
     */
     
    function sendEtherToMultisig() public  returns(uint256 e) {
        uint256 req;
        require(msg.sender==owner || msg.sender==multisig);
        require(saleStatus!=0);

        if(saleStatus==2) {
        	// calculate ether for refunds
        	req=tokensFromEther.mul(1 ether).div(step0Rate).div(2);

        	if(bDbgEnabled) emit DebugLog("This balance is", this.balance);
        	if(req>=this.balance) return 0;
    	}
    	else if(saleStatus==1) {
    		require(getNow()-stage2StartTime>15768000);
    		req=0; 
    	}
        uint256 amount;
        amount=this.balance.sub(req);
        multisig.transfer(amount);
        return amount;
        
    }
    
	


	
	
	/**
		Refund functions. 
		If ico is success, anyone can get 0.000005 eth for 1 token,  else 00001 eth
		
	*/
	
    /**
     * @dev Refunds ether to sender if he trasnfered tokens to contract address. Calculates max possible amount of refund. If sent tokens>refund amound, tokens will be returned to sender.
     * @param _to Address of refund receiver
     * @param _value Tokens requested for refund
     */
	
    function processRefundEther(address _to, uint256 _value) private returns (uint256 left)
    {
        require(saleStatus!=0);
        require(_value>0);
        uint256 Ether=0; uint256 bounty=0;  uint256 total=0;

        uint256 rate2=saleStatus;

        
        if(_value>=boughtWithEther[_to]) {Ether=Ether.add(boughtWithEther[_to]); _value=_value.sub(boughtWithEther[_to]); }
        else {Ether=Ether.add(_value); _value=_value.sub(Ether);}
        boughtWithEther[_to]=boughtWithEther[_to].sub(Ether);
        
        if(rate2==2) {        
            if(_value>=bountyAndRefsWithEther[_to]) {bounty=bounty.add(bountyAndRefsWithEther[_to]); _value=_value.sub(bountyAndRefsWithEther[_to]); }
            else { bounty=bounty.add(_value); _value=_value.sub(bounty); }
            bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].sub(bounty);
        }
        total=Ether.add(bounty);
     //   if(_value>total) _value=_value.sub(total);
        tokensFromEther=tokensFromEther.sub(total);
       uint256 eth=total.mul(1 ether).div(step0Rate).div(rate2);
         _to.transfer(eth);
        if(bDbgEnabled) emit DebugLog("Will refund ", eth);

        emit RefundEther(_to, total, eth);
        decreaseGlobalInterestAmount(total);
        return _value;
    }
    
    
	

	     /**
     * @dev Returns info about refundable tokens- bought with ether, payment systems, and bonus tokens convertable to ether
     */
	
	function getRefundInfo(address _to) public returns (uint256, uint256, uint256)
	{
	    return  ( boughtWithEther[_to],  boughtWithOther[_to],  bountyAndRefsWithEther[_to]);
	    
	}
	
    
    /**
     * @dev Withdraw tokens  refunded to other payment systems.
     * @param _to Address of refund receiver
     */
    
    function refundToOtherProcess(address _to, uint256 _value) public onlyOwner returns (uint256 o) {
        require(saleStatus!=0);
        //uint256 maxValue=refundToOtherGet(_to);
        uint256 maxValue=0;
        require(_value<=maxValue);
        
        uint256 Other=0; uint256 bounty=0; 



        
        if(_value>=boughtWithOther[_to]) {Other=Other.add(boughtWithOther[_to]); _value=_value.sub(boughtWithOther[_to]); }
        else {Other=Other.add(_value); _value=_value.sub(Other);}
        boughtWithOther[_to]=boughtWithOther[_to].sub(Other);

       
        balances[_to]=balanceOf(_to).sub(Other).sub(bounty);
        updateDate(_to);
        decreaseGlobalInterestAmount(Other.add(bounty));
        return _value;
        
        
    }
    
 
    /**
     * @dev Converts ether to our tokens 
     */
		  
    
    function createTokensFromEther()  private   {
               
        assert(msg.value >= 1 ether / 1000);
       
         uint256 tokens = currentRate.mul(msg.value).div(1 ether);


        transferFromOwner(msg.sender, tokens,2);
      
       if(saleStatus==0) {
           boughtWithEther[msg.sender]=boughtWithEther[msg.sender].add(tokens);
            tokensFromEther=tokensFromEther.add(tokens);
       }
      
    }
	
	
    /**
     * @dev Converts other payments system payment to  tokens. Main logic is on site
     */
    
    function createTokensFromOther(address _to, uint256 howMuch, address referer) public  onlyOwner   { 
      
        require(_to!=address(this));
         transferFromOwner(_to, howMuch,2);
         if(referer!=0 && referer!=address(this) && referer!=0x0000000000000000000000000000000000000000 && howMuch.div(10)>0) {
             transferFromOwner(referer, howMuch.div(10),1);
	         if(saleStatus==0) {
	             	tokensFromEther=tokensFromEther.add( howMuch.div(10));
	 				bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add( howMuch.div(10));
	         	}
         }
         if(saleStatus==0) boughtWithOther[_to]= boughtWithOther[_to].add(howMuch);
    }

	   /**
     * @dev Gives refs tokens through payment on site. Main logic is on site
     * @param _to Address of  receiver
     * @param _amount Amount of tokens		
	 * @param t type of transfer. 0 is transfer, 1 bonus tokens, 2 - sale
     */
	
	function transferFromOwner(address _to, uint256 _amount, uint t) private {
	   require(_to!=address(this) && _to!=address(owner) );
        balances[owner]=balances[owner].sub(_amount); 
        balances[_to]=balanceOf(_to).add(_amount);
        updateDate(_to);

        increaseGlobalInterestAmount(_amount);
	    
	   
	     if(t==2) emit Sale(_to, _amount);
        emit Transfer(owner, _to, _amount);	     
	}
	

    function increaseGlobalInterestAmount(uint256 c) private 
    {
        globalInterestAmount=globalInterestAmount.add(c);
		
    }
    
    function decreaseGlobalInterestAmount(uint256 c) private
    {
        if(c<globalInterestAmount) {
            globalInterestAmount=globalInterestAmount.sub(c);
        }
            
        
    }
    
    function() external payable {
        createTokensFromEther();
    }

    
}