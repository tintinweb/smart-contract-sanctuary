pragma solidity ^0.4.11;


contract DoNotDeployThisGetTheRightOneCosParityPutsThisOnTop {
    uint256 nothing;

    function DoNotDeployThisGetTheRightOneCosParityPutsThisOnTop() {
        nothing = 27;
    }
}


//*************** Ownable

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

//***********Pausible

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require (paused) ;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

//*************ERC20

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

//*************** SafeMath

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

//**************** StandardToken

contract StandardToken is ERC20, SafeMath {

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32)  returns (bool success){
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract GBT {
  function parentChange(address,uint);
  function parentFees(address);
  function setHGT(address _hgt);
}

//************ HELLOGOLDTOKEN

contract HelloGoldToken is ERC20, SafeMath, Pausable, StandardToken {

  string public name;
  string public symbol;
  uint8  public decimals;

  GBT  goldtoken;
  

  function setGBT(address gbt_) onlyOwner {
    goldtoken = GBT(gbt_);
  }

  function GBTAddress() constant returns (address) {
    return address(goldtoken);
  }

  function HelloGoldToken(address _reserve) {
    name = "HelloGold Token";
    symbol = "HGT";
    decimals = 8;
 
    totalSupply = 1 * 10 ** 9 * 10 ** uint256(decimals);
    balances[_reserve] = totalSupply;
  }


  function parentChange(address _to) internal {
    require(address(goldtoken) != 0x0);
    goldtoken.parentChange(_to,balances[_to]);
  }
  function parentFees(address _to) internal {
    require(address(goldtoken) != 0x0);
    goldtoken.parentFees(_to);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
    parentFees(_from);
    parentFees(_to);
    success = super.transferFrom(_from,_to,_value);
    parentChange(_from);
    parentChange(_to);
    return;
  }

  function transfer(address _to, uint _value) whenNotPaused returns (bool success)  {
    parentFees(msg.sender);
    parentFees(_to);
    success = super.transfer(_to,_value);
    parentChange(msg.sender);
    parentChange(_to);
    return;
  }

  function approve(address _spender, uint _value) whenNotPaused returns (bool success)  {
    return super.approve(_spender,_value);
  }
}

//********* GOLDFEES ************************

contract GoldFees is SafeMath,Ownable {
    // e.g. if rate = 0.0054
    //uint rateN = 9999452055;
    uint rateN = 9999452054794520548;
    uint rateD = 19;
    uint public maxDays;
    uint public maxRate;

    
    function GoldFees() {
        calcMax();
    }

    function calcMax() {
        maxDays = 1;
        maxRate = rateN;
        
        
        uint pow = 2;
        do {
            uint newN = rateN ** pow;
            if (newN / maxRate != maxRate) {
                maxDays = pow / 2;
                break;
            }
            maxRate = newN;
            pow *= 2;
        } while (pow < 2000);
        
    }

    function updateRate(uint256 _n, uint256 _d) onlyOwner{
        rateN = _n;
        rateD = _d;
        calcMax();
    }
    
    function rateForDays(uint256 numDays) constant returns (uint256 rate) {
        if (numDays <= maxDays) {
            uint r = rateN ** numDays;
            uint d = rateD * numDays;
            if (d > 18) {
                uint div =  10 ** (d-18);
                rate = r / div;
            } else {
                div = 10 ** (18 - d);
                rate = r * div;
            }
        } else {
            uint256 md1 = numDays / 2;
            uint256 md2 = numDays - md1;
             uint256 r2;

            uint256 r1 = rateForDays(md1);
            if (md1 == md2) {
                r2 = r1;
            } else {
                r2 = rateForDays(md2);
            }
           

            //uint256 r1 = rateForDays(maxDays);
            //uint256 r2 = rateForDays(numDays-maxDays);
            rate  = safeMul( r1 , r2)  / 10 ** 18;
        }
        return; 
        
    }

    uint256 constant public UTC2MYT = 1483200000;

    function wotDay(uint256 time) returns (uint256) {
        return (time - UTC2MYT) / (1 days);
    }

    // minimum fee is 1 unless same day
    function calcFees(uint256 start, uint256 end, uint256 startAmount) constant returns (uint256 amount, uint256 fee) {
        if (startAmount == 0) return;
        uint256 numberOfDays = wotDay(end) - wotDay(start);
        if (numberOfDays == 0) {
            amount = startAmount;
            return;
        }
        amount = (rateForDays(numberOfDays) * startAmount) / (1 ether);
        if ((fee == 0) && (amount !=  0)) amount--;
        fee = safeSub(startAmount,amount);
    }
}

//******************** GoldBackedToken

contract GoldBackedToken is Ownable, SafeMath, ERC20, Pausable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event DeductFees(address indexed owner,uint256 amount);

  event TokenMinted(address destination, uint256 amount);
  event TokenBurned(address source, uint256 amount);
  
	string public name = "HelloGold Gold Backed Token";
	string public symbol = "GBT";
	uint256 constant public  decimals = 18;  // same as ETH
	uint256 constant public  hgtDecimals = 8;
		
	uint256 constant public allocationPool = 1 *  10**9 * 10**hgtDecimals;      // total HGT holdings
	uint256	constant public	maxAllocation  = 38 * 10**5 * 10**decimals;			// max GBT that can ever ever be given out
	uint256	         public	totAllocation;			// amount of GBT so far
	
	address			 public feeCalculator;
	address		     public HGT;					// HGT contract address



	function setFeeCalculator(address newFC) onlyOwner {
		feeCalculator = newFC;
	}


	function calcFees(uint256 from, uint256 to, uint256 amount) returns (uint256 val, uint256 fee) {
		return GoldFees(feeCalculator).calcFees(from,to,amount);
	}

	function GoldBackedToken(address feeCalc) {
		feeCalculator = feeCalc;
	}

    struct allocation { 
        uint256     amount;
        uint256     date;
    }
	
	allocation[]   public allocationsOverTime;
	allocation[]   public currentAllocations;

	function currentAllocationLength() constant returns (uint256) {
		return currentAllocations.length;
	}

	function aotLength() constant returns (uint256) {
		return allocationsOverTime.length;
	}

	
    struct Balance {
        uint256 amount;                 // amount through update or transfer
        uint256 lastUpdated;            // DATE last updated
        uint256 nextAllocationIndex;    // which allocationsOverTime record contains next update
        uint256 allocationShare;        // the share of allocationPool that this holder gets (means they hold HGT)
    }

	/*Creates an array with all balances*/
	mapping (address => Balance) public balances;
	mapping (address => mapping (address => uint)) allowed;
	
	function update(address where) internal {
        uint256 pos;
		uint256 fees;
		uint256 val;
        (val,fees,pos) = updatedBalance(where);
	    balances[where].nextAllocationIndex = pos;
	    balances[where].amount = val;
        balances[where].lastUpdated = now;
	}
	
	function updatedBalance(address where) constant public returns (uint val, uint fees, uint pos) {
		uint256 c_val;
		uint256 c_fees;
		uint256 c_amount;

		(val, fees) = calcFees(balances[where].lastUpdated,now,balances[where].amount);

	    pos = balances[where].nextAllocationIndex;
		if ((pos < currentAllocations.length) &&  (balances[where].allocationShare != 0)) {

			c_amount = currentAllocations[balances[where].nextAllocationIndex].amount * balances[where].allocationShare / allocationPool;

			(c_val,c_fees)   = calcFees(currentAllocations[balances[where].nextAllocationIndex].date,now,c_amount);

		} 

	    val  += c_val;
		fees += c_fees;
		pos   = currentAllocations.length;
	}

    function balanceOf(address where) constant returns (uint256 val) {
        uint256 fees;
		uint256 pos;
        (val,fees,pos) = updatedBalance(where);
        return ;
    }

	event Allocation(uint256 amount, uint256 date);
	event FeeOnAllocation(uint256 fees, uint256 date);

	event PartComplete();
	event StillToGo(uint numLeft);
	uint256 public partPos;
	uint256 public partFees;
	uint256 partL;
	allocation[]   public partAllocations;

	function partAllocationLength() constant returns (uint) {
		return partAllocations.length;
	}

	function addAllocationPartOne(uint newAllocation,uint numSteps) onlyOwner{
		uint256 thisAllocation = newAllocation;

		require(totAllocation < maxAllocation);		// cannot allocate more than this;

		if (currentAllocations.length > partAllocations.length) {
			partAllocations = currentAllocations;
		}

		if (totAllocation + thisAllocation > maxAllocation) {
			thisAllocation = maxAllocation - totAllocation;
			log0("max alloc reached");
		}
		totAllocation += thisAllocation;

		Allocation(thisAllocation,now);

        allocation memory newDiv;
        newDiv.amount = thisAllocation;
        newDiv.date = now;
		// store into history
	    allocationsOverTime.push(newDiv);
		// add this record to the end of currentAllocations
		partL = partAllocations.push(newDiv);
		// update all other records with calcs from last record
		if (partAllocations.length < 2) { // no fees to consider
			PartComplete();
			currentAllocations = partAllocations;
			FeeOnAllocation(0,now);
			return;
		}
		//
		// The only fees that need to be collected are the fees on location zero.
		// Since they are the last calculated = they come out with the break
		//
		for (partPos = partAllocations.length - 2; partPos >= 0; partPos-- ){
			(partAllocations[partPos].amount,partFees) = calcFees(partAllocations[partPos].date,now,partAllocations[partPos].amount);

			partAllocations[partPos].amount += partAllocations[partL - 1].amount;
			partAllocations[partPos].date    = now;
			if ((partPos == 0) || (partPos == partAllocations.length-numSteps)){
				break; 
			}
		}
		if (partPos != 0) {
			StillToGo(partPos);
			return; // not done yet
		}
		PartComplete();
		FeeOnAllocation(partFees,now);
		currentAllocations = partAllocations;
	}

	function addAllocationPartTwo(uint numSteps) onlyOwner {
		require(numSteps > 0);
		require(partPos > 0);
		for (uint i = 0; i < numSteps; i++ ){
			partPos--;
			(partAllocations[partPos].amount,partFees) = calcFees(partAllocations[partPos].date,now,partAllocations[partPos].amount);

			partAllocations[partPos].amount += partAllocations[partL - 1].amount;
			partAllocations[partPos].date    = now;
			if (partPos == 0) {
				break; 
			}
		}
		if (partPos != 0) {
			StillToGo(partPos);
			return; // not done yet
		}
		PartComplete();
		FeeOnAllocation(partFees,now);
		currentAllocations = partAllocations;
	}


	function setHGT(address _hgt) onlyOwner {
		HGT = _hgt;
	}

	function parentFees(address where) whenNotPaused {
		require(msg.sender == HGT);
	    update(where);		
	}
	
	function parentChange(address where, uint newValue) whenNotPaused { // called when HGT balance changes
		require(msg.sender == HGT);
	    balances[where].allocationShare = newValue;
	}
	
	/* send GBT */
	function transfer(address _to, uint256 _value) whenNotPaused returns (bool ok) {
	    update(msg.sender);              // Do this to ensure sender has enough funds.
		update(_to); 

        balances[msg.sender].amount = safeSub(balances[msg.sender].amount, _value);
        balances[_to].amount = safeAdd(balances[_to].amount, _value);

		Transfer(msg.sender, _to, _value); //Notify anyone listening that this transfer took place
        return true;
	}

	function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool success) {
		var _allowance = allowed[_from][msg.sender];

	    update(_from);              // Do this to ensure sender has enough funds.
		update(_to); 

		balances[_to].amount = safeAdd(balances[_to].amount, _value);
		balances[_from].amount = safeSub(balances[_from].amount, _value);
		allowed[_from][msg.sender] = safeSub(_allowance, _value);
		Transfer(_from, _to, _value);
		return true;
	}

  	function approve(address _spender, uint _value) whenNotPaused returns (bool success) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    	allowed[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);
    	return true;
  	}

  	function allowance(address _owner, address _spender) constant returns (uint remaining) {
    	return allowed[_owner][_spender];
  	}

	// Minting Functions 
	address public authorisedMinter;

	function setMinter(address minter) onlyOwner {
		authorisedMinter = minter;
	}
	
	function mintTokens(address destination, uint256 amount) {
		require(msg.sender == authorisedMinter);
		update(destination);
		balances[destination].amount = safeAdd(balances[destination].amount, amount);
		balances[destination].lastUpdated = now;
		balances[destination].nextAllocationIndex = currentAllocations.length;
		TokenMinted(destination,amount);
	}

	function burnTokens(address source, uint256 amount) {
		require(msg.sender == authorisedMinter);
		update(source);
		balances[source].amount = safeSub(balances[source].amount,amount);
		balances[source].lastUpdated = now;
		balances[source].nextAllocationIndex = currentAllocations.length;
		TokenBurned(source,amount);
	}
}

//**************** HelloGoldSale

contract HelloGoldSale is Pausable, SafeMath {

  uint256 public decimals = 8;

  uint256 public startDate = 1503892800;      // Monday, August 28, 2017 12:00:00 PM GMT+08:00
  uint256 public endDate   = 1504497600;      // Monday, September 4, 2017 12:00:00 PM GMT+08:00

  uint256 tranchePeriod = 1 weeks;

  // address of HGT Token. HGT must Approve this contract to disburse 180M tokens
  HelloGoldToken          token;

  uint256 constant MaxCoinsR1      =  80 * 10**6 * 10**8;   // 180M HGT
  uint256 public coinsRemaining    =  80 * 10**6 * 10**8; 
  uint256 coinsPerTier             =  16 * 10**6 * 10**8;   // 40M HGT
  uint256 public coinsLeftInTier   =  16 * 10**6 * 10**8;

  uint256 public minimumCap        =  0;    // presale achieved

  uint256 numTiers               = 5;
  uint16  public tierNo;
  uint256 public preallocCoins;   // used for testing against cap (inc placement)
  uint256 public purchasedCoins;  // used for testing against tier pricing
  uint256 public ethRaised;
  uint256 public personalMax     = 10 ether;     // max ether per person during public sale
  uint256 public contributors;

  address public cs;
  address public multiSig;
  address public HGT_Reserve;
  
  struct csAction  {
      bool        passedKYC;
      bool        blocked;
  }

  /* This creates an array with all balances */
  mapping (address => csAction) public permissions;
  mapping (address => uint256)  public deposits;

  modifier MustBeEnabled(address x) {
      require (!permissions[x].blocked) ;
      require (permissions[x].passedKYC) ;
      
      _;
  }

  function HelloGoldSale(address _cs, address _hgt, address _multiSig, address _reserve) {
    cs          = _cs;
    token       = HelloGoldToken(_hgt);
    multiSig    = _multiSig;
    HGT_Reserve = _reserve;
  }

  // We only expect to use this to set/reset the start of the contract under exceptional circumstances
  function setStart(uint256 when_) onlyOwner {
      startDate = when_;
      endDate = when_ + tranchePeriod;
  }

  modifier MustBeCs() {
      require (msg.sender == cs) ;
      
      _;
  }


  // 1 ether = N HGT tokens 
  uint256[5] public hgtRates = [1248900000000,1196900000000,1144800000000,1092800000000,1040700000000];
                      

    /* Approve the account for operation */
    function approve(address user) MustBeCs {
        permissions[user].passedKYC = true;
    }
    
    function block(address user) MustBeCs {
        permissions[user].blocked = true;
    }

    function unblock(address user) MustBeCs {
         permissions[user].blocked = false;
    }

    function newCs(address newCs) onlyOwner {
        cs = newCs;
    }

    function setPeriod(uint256 period_) onlyOwner {
        require (!funding()) ;
        tranchePeriod = period_;
        endDate = startDate + tranchePeriod;
        if (endDate < now + tranchePeriod) {
            endDate = now + tranchePeriod;
        }
    }

    function when()  constant returns (uint256) {
        return now;
    }

  function funding() constant returns (bool) {     
    if (paused) return false;               // frozen
    if (now < startDate) return false;      // too early
    if (now > endDate) return false;        // too late
    if (coinsRemaining == 0) return false;  // no more coins
    if (tierNo >= numTiers ) return false;  // passed end of top tier. Tiers start at zero
    return true;
  }

  function success() constant returns (bool succeeded) {
    if (coinsRemaining == 0) return true;
    bool complete = (now > endDate) ;
    bool didOK = (coinsRemaining <= (MaxCoinsR1 - minimumCap)); // not even 40M Gone?? Aargh.
    succeeded = (complete && didOK)  ;  // (out of steam but enough sold) 
    return ;
  }

  function failed() constant returns (bool didNotSucceed) {
    bool complete = (now > endDate  );
    bool didBad = (coinsRemaining > (MaxCoinsR1 - minimumCap));
    didNotSucceed = (complete && didBad);
    return;
  }

  
  function () payable MustBeEnabled(msg.sender) whenNotPaused {    
    createTokens(msg.sender,msg.value);
  }

  function linkCoin(address coin) onlyOwner {
    token = HelloGoldToken(coin);
  }

  function coinAddress() constant returns (address) {
      return address(token);
  }

  // hgtRates in whole tokens per ETH
  // max individual contribution in whole ETH
  function setHgtRates(uint256 p0,uint256 p1,uint256 p2,uint256 p3,uint256 p4, uint256 _max ) onlyOwner {
              require (now < startDate) ;
              hgtRates[0]   = p0 * 10**8;
              hgtRates[1]   = p1 * 10**8;
              hgtRates[2]   = p2 * 10**8;
              hgtRates[3]   = p3 * 10**8;
              hgtRates[4]   = p4 * 10**8;
              personalMax = _max * 1 ether;           // max ETH per person
  }

  
  event Purchase(address indexed buyer, uint256 level,uint256 value, uint256 tokens);
  event Reduction(string msg, address indexed buyer, uint256 wanted, uint256 allocated);
  event MaxFunds(address sender, uint256 taken, uint256 returned);
  
  function createTokens(address recipient, uint256 value) private {
    uint256 totalTokens;
    uint256 hgtRate;
    require (funding()) ;
    require (value >= 1 finney) ;
    require (deposits[recipient] < personalMax);

    uint256 maxRefund = 0;
    if ((deposits[recipient] + value) > personalMax) {
        maxRefund = deposits[recipient] + value - personalMax;
        value -= maxRefund;
        MaxFunds(recipient,value,maxRefund);
    }  

    uint256 val = value;

    ethRaised = safeAdd(ethRaised,value);
    if (deposits[recipient] == 0) contributors++;
    
    
    do {
      hgtRate = hgtRates[tierNo];                 // hgtRate must include the 10^8
      uint tokens = safeMul(val, hgtRate);      // (val in eth * 10^18) * #tokens per eth
      tokens = safeDiv(tokens, 1 ether);      // val is in ether, msg.value is in wei
   
      if (tokens <= coinsLeftInTier) {
        uint256 actualTokens = tokens;
        uint refund = 0;
        if (tokens > coinsRemaining) { //can&#39;t sell desired # tokens
            Reduction("in tier",recipient,tokens,coinsRemaining);
            actualTokens = coinsRemaining;
            refund = safeSub(tokens, coinsRemaining ); // refund amount in tokens
            refund = safeDiv(refund*1 ether,hgtRate );  // refund amount in ETH
            // need a refund mechanism here too
            coinsRemaining = 0;
            val = safeSub( val,refund);
        } else {
            coinsRemaining  = safeSub(coinsRemaining,  actualTokens);
        }
        purchasedCoins  = safeAdd(purchasedCoins, actualTokens);

        totalTokens = safeAdd(totalTokens,actualTokens);

        require (token.transferFrom(HGT_Reserve, recipient,totalTokens)) ;

        Purchase(recipient,tierNo,val,actualTokens); // event

        deposits[recipient] = safeAdd(deposits[recipient],val); // in case of refund - could pull off etherscan
        refund += maxRefund;
        if (refund > 0) {
            ethRaised = safeSub(ethRaised,refund);
            recipient.transfer(refund);
        }
        if (coinsRemaining <= (MaxCoinsR1 - minimumCap)){ // has passed success criteria
            if (!multiSig.send(this.balance)) {                // send funds to HGF
                log0("cannot forward funds to owner");
            }
        }
        coinsLeftInTier = safeSub(coinsLeftInTier,actualTokens);
        if ((coinsLeftInTier == 0) && (coinsRemaining != 0)) { // exact sell out of non final tier
            coinsLeftInTier = coinsPerTier;
            tierNo++;
            endDate = now + tranchePeriod;
        }
        return;
      }
      // check that coinsLeftInTier >= coinsRemaining

      uint256 coins2buy = min256(coinsLeftInTier , coinsRemaining); 

      endDate = safeAdd( now, tranchePeriod);
      // Have bumped levels - need to modify end date here
      purchasedCoins = safeAdd(purchasedCoins, coins2buy);  // give all coins remaining in this tier
      totalTokens    = safeAdd(totalTokens,coins2buy);
      coinsRemaining = safeSub(coinsRemaining,coins2buy);

      uint weiCoinsLeftInThisTier = safeMul(coins2buy,1 ether);
      uint costOfTheseCoins = safeDiv(weiCoinsLeftInThisTier, hgtRate);  // how much did that cost?

      Purchase(recipient, tierNo,costOfTheseCoins,coins2buy); // event

      deposits[recipient] = safeAdd(deposits[recipient],costOfTheseCoins);
      val    = safeSub(val,costOfTheseCoins);
      tierNo = tierNo + 1;
      coinsLeftInTier = coinsPerTier;
    } while ((val > 0) && funding());

    // escaped because we passed the end of the universe.....
    // so give them their tokens
    require (token.transferFrom(HGT_Reserve, recipient,totalTokens)) ;

    if ((val > 0) || (maxRefund > 0)){
        Reduction("finished crowdsale, returning ",recipient,value,totalTokens);
        // return the remainder !
        recipient.transfer(val+maxRefund); // if you can&#39;t return the balance, abort whole process
    }
    if (!multiSig.send(this.balance)) {
        ethRaised = safeSub(ethRaised,this.balance);
        log0("cannot send at tier jump");
    }
  }
  
  function allocatedTokens(address grantee, uint256 numTokens) onlyOwner {
    require (now < startDate) ;
    if (numTokens < coinsRemaining) {
        coinsRemaining = safeSub(coinsRemaining, numTokens);
       
    } else {
        numTokens = coinsRemaining;
        coinsRemaining = 0;
    }
    preallocCoins = safeAdd(preallocCoins,numTokens);
    require (token.transferFrom(HGT_Reserve,grantee,numTokens));
  }

  function withdraw() { // it failed. Come and get your ether.
      if (failed()) {
          if (deposits[msg.sender] > 0) {
              uint256 val = deposits[msg.sender];
              deposits[msg.sender] = 0;
              msg.sender.transfer(val);
          }
      }
  }

  function complete() onlyOwner {  // this should not have to be called. Extreme measures.
      if (success()) {
          uint256 val = this.balance;
          if (val > 0) {
            if (!multiSig.send(val)) {
                log0("cannot withdraw");
            } else {
                log0("funds withdrawn");
            }
          } else {
              log0("nothing to withdraw");
          }
      }
  }

}