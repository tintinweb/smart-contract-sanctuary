pragma solidity ^0.4.19;

contract CrowdsaleLimit {
  using SafeMath for uint256;

  // the UNIX timestamp start date of the crowdsale
  uint public startsAt;
  // the UNIX timestamp end date of the crowdsale
  uint public endsAt;
  // setting the max token 
  uint public TOKEN_MAX;
  // seting the wei value for one token in presale stage
  uint public PRESALE_TOKEN_IN_WEI = 9 finney;
  // total eth fund in presale stage
  uint public presale_eth_fund= 0;
  
  // seting the wei value for one token in crowdsale stage
  uint public CROWDSALE_TOKEN_IN_WEI = 10 finney;  
  
  // seting the max fund of presale with eth
  uint public PRESALE_ETH_IN_WEI_FUND_MAX = 0 ether; 
  // seting the min fund of crowdsale with eth
  uint public CROWDSALE_ETH_IN_WEI_FUND_MIN = 100 ether;
  // seting the max fund of crowdsale with eth
  uint public CROWDSALE_ETH_IN_WEI_FUND_MAX = 1000 ether;
  // seting the min acceptable invest with eth
  uint public CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN = 100 finney;   //0.1 ether
  // seting the gasprice to limit big buyer, default to disable
  uint public CROWDSALE_GASPRICE_IN_WEI_MAX = 0;
 
  // total eth fund
  uint public crowdsale_eth_fund= 0;
  // total eth refund
  uint public crowdsale_eth_refund = 0;
   
  // setting team list and set percentage of tokens
  mapping(address => uint) public team_addresses_token_percentage;
  mapping(uint => address) public team_addresses_idx;
  uint public team_address_count= 0;
  uint public team_token_percentage_total= 0;
  uint public team_token_percentage_max= 0;
    
  event EndsAtChanged(uint newEndsAt);
  event AddTeamAddress(address addr, uint release_time, uint token_percentage);
  event Refund(address investor, uint weiAmount);
    
  // limitation of buying tokens
  modifier allowCrowdsaleAmountLimit(){	
	if (msg.value == 0) revert();
	if (msg.value < CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN) revert();
	if((crowdsale_eth_fund.add(msg.value)) > CROWDSALE_ETH_IN_WEI_FUND_MAX) revert();
	if((CROWDSALE_GASPRICE_IN_WEI_MAX > 0) && (tx.gasprice > CROWDSALE_GASPRICE_IN_WEI_MAX)) revert();
	_;
  }  
   
  function CrowdsaleLimit(uint _start, uint _end, uint _token_max, uint _presale_token_in_wei, uint _crowdsale_token_in_wei, uint _presale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_fund_min, uint _crowdsale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_accepted_min, uint _crowdsale_gasprice_inwei_max, uint _team_token_percentage_max) {
	require(_start != 0);
	require(_end != 0);
	require(_start < _end);
	
	if( (_presale_token_in_wei == 0) ||
	    (_crowdsale_token_in_wei == 0) ||
		(_crowdsale_eth_inwei_fund_min == 0) ||
		(_crowdsale_eth_inwei_fund_max == 0) ||
		(_crowdsale_eth_inwei_accepted_min == 0) ||
		(_team_token_percentage_max >= 100))  //example 20%=20
		revert();
		
	startsAt = _start;
    endsAt = _end;
	
	TOKEN_MAX = _token_max;
		
	PRESALE_TOKEN_IN_WEI = _presale_token_in_wei;
	
	CROWDSALE_TOKEN_IN_WEI = _crowdsale_token_in_wei;	
	PRESALE_ETH_IN_WEI_FUND_MAX = _presale_eth_inwei_fund_max;
	CROWDSALE_ETH_IN_WEI_FUND_MIN = _crowdsale_eth_inwei_fund_min;
	CROWDSALE_ETH_IN_WEI_FUND_MAX = _crowdsale_eth_inwei_fund_max;
	CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN = _crowdsale_eth_inwei_accepted_min;
	CROWDSALE_GASPRICE_IN_WEI_MAX = _crowdsale_gasprice_inwei_max;
	
	team_token_percentage_max= _team_token_percentage_max;
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  CrowdsaleToken public token;
  
  /* tokens will be transfered from this address */
  address public multisigWallet;
    
  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;
  
  /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
  mapping (address => bool) public presaleWhitelist;
  
  bool public whitelist_enable= true;
  
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
  
  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);
  
  event createTeamTokenEvent(address addr, uint tokens);
  
  event Finalized();
  
  /** Modified allowing execution only if the crowdsale is currently running.  */
  modifier inState(State state) {
    if(getState() != state) revert();
    _;
  }

  function Crowdsale(address _token, address _multisigWallet, uint _start, uint _end, uint _token_max, uint _presale_token_in_wei, uint _crowdsale_token_in_wei, uint _presale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_fund_min, uint _crowdsale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_accepted_min, uint _crowdsale_gasprice_inwei_max, uint _team_token_percentage_max, bool _whitelist_enable) 
           CrowdsaleLimit(_start, _end, _token_max, _presale_token_in_wei, _crowdsale_token_in_wei, _presale_eth_inwei_fund_max, _crowdsale_eth_inwei_fund_min, _crowdsale_eth_inwei_fund_max, _crowdsale_eth_inwei_accepted_min, _crowdsale_gasprice_inwei_max, _team_token_percentage_max)
  {
    require(_token != 0x0);
    require(_multisigWallet != 0x0);
	
	token = CrowdsaleToken(_token);	
	multisigWallet = _multisigWallet;
	
	whitelist_enable= _whitelist_enable;
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
   
  /**
   * Allow addresses to do early participation.
   *
   * TODO: Fix spelling error in the name
   */
  function setPresaleWhitelist(address addr, bool status) onlyOwner inState(State.PreFunding) {
	require(whitelist_enable==true);

    presaleWhitelist[addr] = status;
    Whitelisted(addr, status);
  }
  
  //add new team percentage of tokens and lock their release time
  function addTeamAddress(address addr, uint release_time, uint token_percentage) onlyOwner inState(State.PreFunding) external {
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
  function () stopInEmergency allowCrowdsaleAmountLimit payable {
	require(msg.sender != 0x0);
    buyTokensCrowdsale(msg.sender);
  }

  // low level token purchase function
  function buyTokensCrowdsale(address receiver) internal /*stopInEmergency allowCrowdsaleAmountLimit payable*/ {
	uint256 weiAmount = msg.value;
	uint256 tokenAmount= 0;
	
	if(getState() == State.PreFunding) {
		if(whitelist_enable==true) {
			if(!presaleWhitelist[receiver]) {
				revert();
			}
		}
		
		if((PRESALE_ETH_IN_WEI_FUND_MAX > 0) && ((presale_eth_fund.add(weiAmount)) > PRESALE_ETH_IN_WEI_FUND_MAX)) revert();		
		
		tokenAmount = calculateTokenPresale(weiAmount, token.decimals());
		presale_eth_fund = presale_eth_fund.add(weiAmount);
	}
	else if((getState() == State.Funding) || (getState() == State.Success)) {
		tokenAmount = calculateTokenCrowsale(weiAmount, token.decimals());
		
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
	
	if((TOKEN_MAX > 0) && (tokensSold > TOKEN_MAX)) revert();

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
  
  function setEndsAt(uint time) onlyOwner {
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  bool public mintingFinished = false;
  
  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    if(!mintAgents[msg.sender]) {
        revert();
    }
    _;
  }
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyMintAgent canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
	
	Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyMintAgent public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;
  
  //dtco : time lock with specific address
  mapping(address => uint) public lock_addresses;
  
  event AddLockAddress(address addr, uint lock_time);  

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }
	else {
		//check time lock with team
		if(now < lock_addresses[_sender]) {
			revert();
		}
	}
    _;
  }
  
  function ReleasableToken() {
	releaseAgent = msg.sender;
  }
  
  //lock new team release time
  function addLockAddressInternal(address addr, uint lock_time) inReleaseState(false) internal {
	if(addr == 0x0) revert();
	lock_addresses[addr]= lock_time;
	AddLockAddress(addr, lock_time);
  }
  
  
  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }
  
  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }  

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

contract CrowdsaleToken is ReleasableToken, MintableToken {

  string public name;

  string public symbol;

  uint public decimals;
    
  /**
   * Construct the token.
   *
   * @param _name Token name
   * @param _symbol Token symbol - should be all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
   */
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable) {

    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply_ = _initialSupply;

    decimals = _decimals;

    balances[owner] = totalSupply_;

    if(totalSupply_ > 0) {
      Mint(owner, totalSupply_);
    }

    // No more new supply allowed after the token creation
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply_ == 0) {
        revert(); // Cannot create a token without supply and no minting
      }
    }
  }

  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }
  
  //lock team address by crowdsale
  function addLockAddress(address addr, uint lock_time) onlyMintAgent inReleaseState(false) public {
	super.addLockAddressInternal(addr, lock_time);
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}