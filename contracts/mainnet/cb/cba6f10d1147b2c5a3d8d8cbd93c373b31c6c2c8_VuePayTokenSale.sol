pragma solidity^0.4.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable{
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
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

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
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract VuePayTokenSale is StandardToken, Ownable {
	using SafeMath for uint256;
	// Events
	event CreatedVUP(address indexed _creator, uint256 _amountOfVUP);
	event VUPRefundedForWei(address indexed _refunder, uint256 _amountOfWei);
	event print(uint256 vup);
	// Token data
	string public constant name = "VuePay Token";
	string public constant symbol = "VUP";
	uint256 public constant decimals = 18;  // Since our decimals equals the number of wei per ether, we needn&#39;t multiply sent values when converting between VUP and ETH.
	string public version = "1.0";
	
	// Addresses and contracts
	address public executor;
	//Vuepay Multisig Wallet
	address public vuePayETHDestination=0x8B8698DEe100FC5F561848D0E57E94502Bd9318b;
	//Vuepay Development activities Wallet
	address public constant devVUPDestination=0x31403fA55aEa2065bBDd2778bFEd966014ab0081;
	//VuePay Core Team reserve Wallet
	address public constant coreVUPDestination=0x22d310194b5ac5086bDacb2b0f36D8f0a5971b23;
	//VuePay Advisory and Promotions (PR/Marketing/Media etcc.) wallet
	address public constant advisoryVUPDestination=0x991ABE74a1AC3d903dA479Ca9fede3d0954d430B;
	//VuePay User DEvelopment Fund Wallet
	address public constant udfVUPDestination=0xf4307C073451b80A0BaD1E099fD2B7f0fe38b7e9;
	//Vuepay Cofounder Wallet
	address public constant cofounderVUPDestination=0x863B2217E80e6C6192f63D3716c0cC7711Fad5b4;
	//VuePay Unsold Tokens wallet
	address public constant unsoldVUPDestination=0x5076084a3377ecDF8AD5cD0f26A21bA848DdF435;
	//Total VuePay Sold
	uint256 public totalVUP;
	
	// Sale data
	bool public saleHasEnded;
	bool public minCapReached;
	bool public preSaleEnded;
	bool public allowRefund;
	mapping (address => uint256) public ETHContributed;
	uint256 public totalETHRaised;
	uint256 public preSaleStartBlock;
	uint256 public preSaleEndBlock;
	uint256 public icoEndBlock;
	
    uint public constant coldStorageYears = 10 years;
    uint public coreTeamUnlockedAt;
    uint public unsoldUnlockedAt;
    uint256 coreTeamShare;
    uint256 cofounderShare;
    uint256 advisoryTeamShare;
    
	// Calculate the VUP to ETH rate for the current time period of the sale
	uint256 curTokenRate = VUP_PER_ETH_BASE_RATE;
	uint256 public constant INITIAL_VUP_TOKEN_SUPPLY =1000000000e18;
	uint256 public constant VUP_TOKEN_SUPPLY_TIER1 =150000000e18;
    uint256 public constant VUP_TOKEN_SUPPLY_TIER2 =270000000e18;
	uint256 public constant VUP_TOKEN_SUPPLY_TIER3 =380000000e18;
	uint256 public constant VUP_TOKEN_SUPPLY_TIER4 =400000000e18;
	
	uint256 public constant PRESALE_ICO_PORTION =400000000e18;  // Total for sale in Pre Sale and ICO In percentage
	uint256 public constant ADVISORY_TEAM_PORTION =50000000e18;  // Total Advisory share In percentage
	uint256 public constant CORE_TEAM_PORTION =50000000e18;  // Total core Team share  percentage
	uint256 public constant DEV_TEAM_PORTION =50000000e18;  // Total dev team share In percentage
	uint256 public constant CO_FOUNDER_PORTION = 350000000e18;  // Total cofounder share In percentage
	uint256 public constant UDF_PORTION =100000000e18;  // Total user deve fund share In percentage
	
	uint256 public constant VUP_PER_ETH_BASE_RATE = 2000;  // 2000 VUP = 1 ETH during normal part of token sale
	uint256 public constant VUP_PER_ETH_PRE_SALE_RATE = 3000; // 3000 VUP @ 50%  discount in pre sale
	
	uint256 public constant VUP_PER_ETH_ICO_TIER2_RATE = 2500; // 2500 VUP @ 25% discount
	uint256 public constant VUP_PER_ETH_ICO_TIER3_RATE = 2250;// 2250 VUP @ 12.5% discount
	
	
	function VuePayTokenSale () public payable
	{

	    totalSupply = INITIAL_VUP_TOKEN_SUPPLY;

		//Start Pre-sale approx on the 6th october 8:00 GMT
	    preSaleStartBlock=4340582;
	    //preSaleStartBlock=block.number;
	    preSaleEndBlock = preSaleStartBlock + 37800;  // Equivalent to 14 days later, assuming 32 second blocks
	    icoEndBlock = preSaleEndBlock + 81000;  // Equivalent to 30 days , assuming 32 second blocks
		executor = msg.sender;
		saleHasEnded = false;
		minCapReached = false;
		allowRefund = false;
		advisoryTeamShare = ADVISORY_TEAM_PORTION;
		totalETHRaised = 0;
		totalVUP=0;

	}

	function () payable public {
		
		//minimum .05 Ether required.
		require(msg.value >= .05 ether);
		// If sale is not active, do not create VUP
		require(!saleHasEnded);
		//Requires block to be >= Pre-Sale start block 
		require(block.number >= preSaleStartBlock);
		//Requires block.number to be less than icoEndBlock number
		require(block.number < icoEndBlock);
		//Has the Pre-Sale ended, after 14 days, Pre-Sale ends.
		if (block.number > preSaleEndBlock){
		    preSaleEnded=true;
		}
		// Do not do anything if the amount of ether sent is 0
		require(msg.value!=0);

		uint256 newEtherBalance = totalETHRaised.add(msg.value);
		//Get the appropriate rate which applies
		getCurrentVUPRate();
		// Calculate the amount of VUP being purchase
		
		uint256 amountOfVUP = msg.value.mul(curTokenRate);
	
        //Accrue VUP tokens
		totalVUP=totalVUP.add(amountOfVUP);
	    // if all tokens sold out , sale ends.
		require(totalVUP<= PRESALE_ICO_PORTION);
		
		// Ensure that the transaction is safe
		uint256 totalSupplySafe = totalSupply.sub(amountOfVUP);
		uint256 balanceSafe = balances[msg.sender].add(amountOfVUP);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);
		
		// Update individual and total balances
		totalSupply = totalSupplySafe;
		balances[msg.sender] = balanceSafe;

		totalETHRaised = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;

		CreatedVUP(msg.sender, amountOfVUP);
	}
	
	function getCurrentVUPRate() internal {
	        //default to the base rate
	        curTokenRate = VUP_PER_ETH_BASE_RATE;

	        //if VUP sold < 100 mill and still in presale, use Pre-Sale rate
	        if ((totalVUP <= VUP_TOKEN_SUPPLY_TIER1) && (!preSaleEnded)) {    
			        curTokenRate = VUP_PER_ETH_PRE_SALE_RATE;
	        }
		    //If VUP Sold < 100 mill and Pre-Sale ended, use Tier2 rate
	        if ((totalVUP <= VUP_TOKEN_SUPPLY_TIER1) && (preSaleEnded)) {
			     curTokenRate = VUP_PER_ETH_ICO_TIER2_RATE;
		    }
		    //if VUP Sold > 100 mill, use Tier 2 rate irrespective of Pre-Sale end or not
		    if (totalVUP >VUP_TOKEN_SUPPLY_TIER1 ) {
			    curTokenRate = VUP_PER_ETH_ICO_TIER2_RATE;
		    }
		    //if VUP sold more than 200 mill use Tier3 rate
		    if (totalVUP >VUP_TOKEN_SUPPLY_TIER2 ) {
			    curTokenRate = VUP_PER_ETH_ICO_TIER3_RATE;
		        
		    }
            //if VUP sod more than 300mill
		    if (totalVUP >VUP_TOKEN_SUPPLY_TIER3){
		        curTokenRate = VUP_PER_ETH_BASE_RATE;
		    }
	}
    // Create VUP tokens from the Advisory bucket for marketing, PR, Media where we are 
    //paying upfront for these activities in VUP tokens.
    //Clients = Media, PR, Marketing promotion etc.
    function createCustomVUP(address _clientVUPAddress,uint256 _value) public onlyOwner {
	    //Check the address is valid
	    require(_clientVUPAddress != address(0x0));
		require(_value >0);
		require(advisoryTeamShare>= _value);
	   
	  	uint256 amountOfVUP = _value;
	  	//Reduce from advisoryTeamShare
	    advisoryTeamShare=advisoryTeamShare.sub(amountOfVUP);
        //Accrue VUP tokens
		totalVUP=totalVUP.add(amountOfVUP);
		//Assign tokens to the client
		uint256 balanceSafe = balances[_clientVUPAddress].add(amountOfVUP);
		balances[_clientVUPAddress] = balanceSafe;
		//Create VUP Created event
		CreatedVUP(_clientVUPAddress, amountOfVUP);
	
	}
    
	function endICO() public onlyOwner{
		// Do not end an already ended sale
		require(!saleHasEnded);
		// Can&#39;t end a sale that hasn&#39;t hit its minimum cap
		require(minCapReached);
		
		saleHasEnded = true;

		// Calculate and create all team share VUPs
	
	    coreTeamShare = CORE_TEAM_PORTION;
	    uint256 devTeamShare = DEV_TEAM_PORTION;
	    cofounderShare = CO_FOUNDER_PORTION;
	    uint256 udfShare = UDF_PORTION;
	
	    
		balances[devVUPDestination] = devTeamShare;
		balances[advisoryVUPDestination] = advisoryTeamShare;
		balances[udfVUPDestination] = udfShare;
       
        // Locked time of approximately 9 months before team members are able to redeeem tokens.
        uint nineMonths = 9 * 30 days;
        coreTeamUnlockedAt = now.add(nineMonths);
        // Locked time of approximately 10 years before team members are able to redeeem tokens.
        uint lockTime = coldStorageYears;
        unsoldUnlockedAt = now.add(lockTime);

		CreatedVUP(devVUPDestination, devTeamShare);
		CreatedVUP(advisoryVUPDestination, advisoryTeamShare);
		CreatedVUP(udfVUPDestination, udfShare);

	}
	function unlock() public onlyOwner{
	   require(saleHasEnded);
       require(now > coreTeamUnlockedAt || now > unsoldUnlockedAt);
       if (now > coreTeamUnlockedAt) {
          balances[coreVUPDestination] = coreTeamShare;
          CreatedVUP(coreVUPDestination, coreTeamShare);
          balances[cofounderVUPDestination] = cofounderShare;
          CreatedVUP(cofounderVUPDestination, cofounderShare);
         
       }
       if (now > unsoldUnlockedAt) {
          uint256 unsoldTokens=PRESALE_ICO_PORTION.sub(totalVUP);
          require(unsoldTokens > 0);
          balances[unsoldVUPDestination] = unsoldTokens;
          CreatedVUP(coreVUPDestination, unsoldTokens);
         }
    }

	// Allows VuePay to withdraw funds
	function withdrawFunds() public onlyOwner {
		// Disallow withdraw if the minimum hasn&#39;t been reached
		require(minCapReached);
		require(this.balance > 0);
		if(this.balance > 0) {
			vuePayETHDestination.transfer(this.balance);
		}
	}

	// Signals that the sale has reached its minimum funding goal
	function triggerMinCap() public onlyOwner {
		minCapReached = true;
	}

	// Opens refunding.
	function triggerRefund() public onlyOwner{
		// No refunds if the sale was successful
		require(!saleHasEnded);
		// No refunds if minimum cap is hit
		require(!minCapReached);
		// No refunds if the sale is still progressing
	    require(block.number >icoEndBlock);
		require(msg.sender == executor);
		allowRefund = true;
	}

	function claimRefund() external {
		// No refunds until it is approved
		require(allowRefund);
		// Nothing to refund
		require(ETHContributed[msg.sender]!=0);

		// Do the refund.
		uint256 etherAmount = ETHContributed[msg.sender];
		ETHContributed[msg.sender] = 0;

		VUPRefundedForWei(msg.sender, etherAmount);
		msg.sender.transfer(etherAmount);
	}
    //Allow changing the Vuepay MultiSig wallet incase of emergency
	function changeVuePayETHDestinationAddress(address _newAddress) public onlyOwner {
		vuePayETHDestination = _newAddress;
	}
	
	function transfer(address _to, uint _value) public returns (bool) {
		// Cannot transfer unless the minimum cap is hit
		require(minCapReached);
		return super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) public returns (bool) {
		// Cannot transfer unless the minimum cap is hit
		require(minCapReached);
		return super.transferFrom(_from, _to, _value);
	}

	
}