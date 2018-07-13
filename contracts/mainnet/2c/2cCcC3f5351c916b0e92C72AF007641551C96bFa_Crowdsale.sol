pragma solidity ^0.4.19;

contract CrowdsaleTokenInterface {

  uint public decimals;
   
  function addLockAddress(address addr, uint lock_time) public;
  function mint(address _to, uint256 _amount) public returns (bool);
  function finishMinting() public returns (bool);
}

contract CrowdsaleLimit {
  using SafeMath for uint256;

  // the UNIX timestamp start date of the crowdsale
  uint public startsAt;
  // the UNIX timestamp end date of the crowdsale
  uint public endsAt;
  
  uint public token_decimals = 8;
    
  uint public TOKEN_RATE_PRESALE  = 7200;
  uint public TOKEN_RATE_CROWDSALE= 6000;
  
  // setting the wei value for one token in presale stage
  uint public PRESALE_TOKEN_IN_WEI = 1 ether / TOKEN_RATE_PRESALE;  
  // setting the wei value for one token in crowdsale stage
  uint public CROWDSALE_TOKEN_IN_WEI = 1 ether / TOKEN_RATE_CROWDSALE;
  
  // setting the max fund of presale with eth
  uint public PRESALE_ETH_IN_WEI_FUND_MAX = 40000 ether; 
  // setting the min fund of crowdsale with eth
  uint public CROWDSALE_ETH_IN_WEI_FUND_MIN = 22000 ether;
  // setting the max fund of crowdsale with eth
  uint public CROWDSALE_ETH_IN_WEI_FUND_MAX = 90000 ether;
  
  // setting the min acceptable invest with eth in presale
  uint public PRESALE_ETH_IN_WEI_ACCEPTED_MIN = 1 ether; 
  // setting the min acceptable invest with eth in pubsale
  uint public CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN = 100 finney;
  
  // setting the gasprice to limit big buyer, default to disable
  uint public CROWDSALE_GASPRICE_IN_WEI_MAX = 0;
 
 // total eth fund in presale stage
  uint public presale_eth_fund= 0;
  // total eth fund
  uint public crowdsale_eth_fund= 0;
  // total eth refund
  uint public crowdsale_eth_refund = 0;
   
  // setting team list and set percentage of tokens
  mapping(address => uint) public team_addresses_token_percentage;
  mapping(uint => address) public team_addresses_idx;
  uint public team_address_count= 0;
  uint public team_token_percentage_total= 0;
  uint public team_token_percentage_max= 40;
    
  event EndsAtChanged(uint newEndsAt);
  event AddTeamAddress(address addr, uint release_time, uint token_percentage);
  event Refund(address investor, uint weiAmount);
    
  // limitation of buying tokens
  modifier allowCrowdsaleAmountLimit(){	
	if (msg.value == 0) revert();
	if((crowdsale_eth_fund.add(msg.value)) > CROWDSALE_ETH_IN_WEI_FUND_MAX) revert();
	if((CROWDSALE_GASPRICE_IN_WEI_MAX > 0) && (tx.gasprice > CROWDSALE_GASPRICE_IN_WEI_MAX)) revert();
	_;
  }
   
  function CrowdsaleLimit(uint _start, uint _end) public {
	require(_start != 0);
	require(_end != 0);
	require(_start < _end);
			
	startsAt = _start;
    endsAt = _end;
  }
    
  // caculate amount of token in presale stage
  function calculateTokenPresale(uint value, uint decimals) /*internal*/ public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(PRESALE_TOKEN_IN_WEI);
  }
  
  // caculate amount of token in crowdsale stage
  function calculateTokenCrowsale(uint value, uint decimals) /*internal*/ public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(CROWDSALE_TOKEN_IN_WEI);
  }
  
  // check if the goal is reached
  function isMinimumGoalReached() public constant returns (bool) {
    return crowdsale_eth_fund >= CROWDSALE_ETH_IN_WEI_FUND_MIN;
  }
  
  // add new team percentage of tokens
  function addTeamAddressInternal(address addr, uint release_time, uint token_percentage) internal {
	if((team_token_percentage_total.add(token_percentage)) > team_token_percentage_max) revert();
	if((team_token_percentage_total.add(token_percentage)) > 100) revert();
	if(team_addresses_token_percentage[addr] != 0) revert();
	
	team_addresses_token_percentage[addr]= token_percentage;
	team_addresses_idx[team_address_count]= addr;
	team_address_count++;
	
	team_token_percentage_total = team_token_percentage_total.add(token_percentage);

	AddTeamAddress(addr, release_time, token_percentage);
  }
   
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endsAt;
  }
}

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract Crowdsale is CrowdsaleLimit, Haltable {
  using SafeMath for uint256;

  CrowdsaleTokenInterface public token;
    
  /* tokens will be transfered from this address */
  address public multisigWallet;
    
  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;
     
  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;
  
  /* How many distinct addresses have invested */
  uint public investorCount = 0;
  
  /* How much wei we have returned back to the contract after a failed crowdfund. */
  uint public loadedRefund = 0;
  
  /* Has this crowdsale been finalized */
  bool public finalized;
  
  enum State{Unknown, PreFunding, Funding, Success, Failure, Finalized, Refunding}
    
  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount);
    
  event createTeamTokenEvent(address addr, uint tokens);
  
  event Finalized();
  
  /** Modified allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    if(getState() != state) revert();
    _;
  }

  function Crowdsale(address _token, address _multisigWallet, uint _start, uint _end) CrowdsaleLimit(_start, _end) public
  {
    require(_token != 0x0);
    require(_multisigWallet != 0x0);
	
	token = CrowdsaleTokenInterface(_token);	
	if(token_decimals != token.decimals()) revert();
	
	multisigWallet = _multisigWallet;
  }
  
  /* Crowdfund state machine management. */
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (now < startsAt) return State.PreFunding;
    else if (now <= endsAt && !isMinimumGoalReached()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && crowdsale_eth_fund > 0 && loadedRefund >= crowdsale_eth_fund) return State.Refunding;
    else return State.Failure;
  }
    
  //add new team percentage of tokens and lock their release time
  function addTeamAddress(address addr, uint release_time, uint token_percentage) onlyOwner inState(State.PreFunding) public {
	super.addTeamAddressInternal(addr, release_time, token_percentage);
	token.addLockAddress(addr, release_time);  //not use delegatecall
  }
  
  //generate team tokens in accordance with percentage of total issue tokens, not preallocate
  function createTeamTokenByPercentage() onlyOwner internal {
	//uint total= token.totalSupply();
	uint total= tokensSold;
	
	//uint tokens= total.mul(100).div(100-team_token_percentage_total).sub(total);
	uint tokens= total.mul(team_token_percentage_total).div(100-team_token_percentage_total);
	
	for(uint i=0; i<team_address_count; i++) {
		address addr= team_addresses_idx[i];
		if(addr==0x0) continue;
		
		uint ntoken= tokens.mul(team_addresses_token_percentage[addr]).div(team_token_percentage_total);
		token.mint(addr, ntoken);		
		createTeamTokenEvent(addr, ntoken);
	}
  }
  
  // fallback function can be used to buy tokens
  function () stopInEmergency allowCrowdsaleAmountLimit payable public {
	require(msg.sender != 0x0);
    buyTokensCrowdsale(msg.sender);
  }

  // low level token purchase function
  function buyTokensCrowdsale(address receiver) internal /*stopInEmergency allowCrowdsaleAmountLimit payable*/ {
	uint256 weiAmount = msg.value;
	uint256 tokenAmount= 0;
	
	if(getState() == State.PreFunding) {
		if (weiAmount < PRESALE_ETH_IN_WEI_ACCEPTED_MIN) revert();
		if((PRESALE_ETH_IN_WEI_FUND_MAX > 0) && ((presale_eth_fund.add(weiAmount)) > PRESALE_ETH_IN_WEI_FUND_MAX)) revert();		
		
		tokenAmount = calculateTokenPresale(weiAmount, token_decimals);
		presale_eth_fund = presale_eth_fund.add(weiAmount);
	}
	else if((getState() == State.Funding) || (getState() == State.Success)) {
		if (weiAmount < CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN) revert();
		
		tokenAmount = calculateTokenCrowsale(weiAmount, token_decimals);
		
    } else {
      // Unwanted state
      revert();
    }
	
	if(tokenAmount == 0) {
		revert();
	}	
	
	if(investedAmountOf[receiver] == 0) {
       investorCount++;
    }
    
	// Update investor
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
	
    // Update totals
	crowdsale_eth_fund = crowdsale_eth_fund.add(weiAmount);
	tokensSold = tokensSold.add(tokenAmount);
	
    token.mint(receiver, tokenAmount);

    if(!multisigWallet.send(weiAmount)) revert();
	
	// Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount);
  }
 
  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) revert();
    loadedRefund = loadedRefund.add(msg.value);
  }
  
  /**
   * Investors can claim refund.
   *
   * Note that any refunds from proxy buyers should be handled separately,
   * and not through this contract.
   */
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) revert();
    investedAmountOf[msg.sender] = 0;
    crowdsale_eth_refund = crowdsale_eth_refund.add(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) revert();
  }
  
  function setEndsAt(uint time) onlyOwner public {
    if(now > time) {
      revert();
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }
  
  // should be called after crowdsale ends, to do
  // some extra finalization work
  function doFinalize() public inState(State.Success) onlyOwner stopInEmergency {
    
	if(finalized) {
      revert();
    }

	createTeamTokenByPercentage();
    token.finishMinting();	
        
    finalized = true;
	Finalized();
  }
  
}

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