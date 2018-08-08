pragma solidity ^0.4.21;

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
		return a / b;
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

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}

contract StandardToken is ERC20, BasicToken {
	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}


contract Ownable {
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == address(0x630CC4c83fCc1121feD041126227d25Bbeb51959)) );
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}


contract A2AToken is Ownable, StandardToken {
	// ERC20 requirements
	string public name;
	string public symbol;
	uint8 public decimals;

	uint256 public totalSupply;
	bool public releasedForTransfer;
	
	// Max supply of A2A token is 600M
	uint256 constant public maxSupply = 600*(10**6)*(10**8);
	
	mapping(address => uint256) public vestingAmount;
	mapping(address => uint256) public vestingBeforeBlockNumber;
	mapping(address => bool) public icoAddrs;

	function A2AToken() public {
		name = "A2A STeX Exchange Token";
		symbol = "A2A";
		decimals = 8;
		releasedForTransfer = false;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(releasedForTransfer);
		// Cancel transaction if transfer value more then available without vesting amount
		if ( ( vestingAmount[msg.sender] > 0 ) && ( block.number < vestingBeforeBlockNumber[msg.sender] ) ) {
			if ( balances[msg.sender] < _value ) revert();
			if ( balances[msg.sender] <= vestingAmount[msg.sender] ) revert();
			if ( balances[msg.sender].sub(_value) < vestingAmount[msg.sender] ) revert();
		}
		// ---
		return super.transfer(_to, _value);
	}
	
	function setVesting(address _holder, uint256 _amount, uint256 _bn) public onlyOwner() returns (bool) {
		vestingAmount[_holder] = _amount;
		vestingBeforeBlockNumber[_holder] = _bn;
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _value, uint256 _vestingBlockNumber) public onlyOwner() returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);			
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if ( _vestingBlockNumber > 0 ) {
			vestingAmount[_to] = _value;
			vestingBeforeBlockNumber[_to] = _vestingBlockNumber;
		}
		
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	function issueDuringICO(address _to, uint256 _amount) public returns (bool) {
		require( icoAddrs[msg.sender] );
		require( totalSupply.add(_amount) < maxSupply );
		balances[_to] = balances[_to].add(_amount);
		totalSupply = totalSupply.add(_amount);
		
		emit Transfer(this, _to, _amount);
		return true;
	}
	
	function setICOaddr(address _addr, bool _value) public onlyOwner() returns (bool) {
		icoAddrs[_addr] = _value;
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(releasedForTransfer);
		return super.transferFrom(_from, _to, _value);
	}

	function release() public onlyOwner() {
		releasedForTransfer = true;
	}
	
	function lock() public onlyOwner() {
		releasedForTransfer = false;
	}
}


contract HasManager is Ownable {
	address public manager;

	modifier onlyManager {
		require( (msg.sender == manager) || (msg.sender == owner) );
		_;
	}

	function transferManager(address _newManager) public onlyManager() {
		require(_newManager != address(0));
		manager = _newManager;
	}
}


// WINGS ICrowdsaleProcessor
contract ICrowdsaleProcessor is HasManager {
	modifier whenCrowdsaleAlive() {
		require(isActive());
		_;
	}

	modifier whenCrowdsaleFailed() {
		require(isFailed());
		_;
	}

	modifier whenCrowdsaleSuccessful() {
		require(isSuccessful());
		_;
	}

	modifier hasntStopped() {
		require(!stopped);
		_;
	}

	modifier hasBeenStopped() {
		require(stopped);
		_;
	}

	modifier hasntStarted() {
		require(!started);
		_;
	}

	modifier hasBeenStarted() {
		require(started);
		_;
	}

	// Minimal acceptable hard cap
	uint256 constant public MIN_HARD_CAP = 1 ether;

	// Minimal acceptable duration of crowdsale
	uint256 constant public MIN_CROWDSALE_TIME = 3 days;

	// Maximal acceptable duration of crowdsale
	uint256 constant public MAX_CROWDSALE_TIME = 50 days;

	// Becomes true when timeframe is assigned
	bool public started;

	// Becomes true if cancelled by owner
	bool public stopped;

	// Total collected Ethereum: must be updated every time tokens has been sold
	uint256 public totalCollected;

	// Total amount of project&#39;s token sold: must be updated every time tokens has been sold
	uint256 public totalSold;

	// Crowdsale minimal goal, must be greater or equal to Forecasting min amount
	uint256 public minimalGoal;

	// Crowdsale hard cap, must be less or equal to Forecasting max amount
	uint256 public hardCap;

	// Crowdsale duration in seconds.
	// Accepted range is MIN_CROWDSALE_TIME..MAX_CROWDSALE_TIME.
	uint256 public duration;

	// Start timestamp of crowdsale, absolute UTC time
	uint256 public startTimestamp;

	// End timestamp of crowdsale, absolute UTC time
	uint256 public endTimestamp;

	// Allows to transfer some ETH into the contract without selling tokens
	function deposit() public payable {}

	// Returns address of crowdsale token, must be ERC20 compilant
	function getToken() public returns(address);

	// Transfers ETH rewards amount (if ETH rewards is configured) to Forecasting contract
	function mintETHRewards(address _contract, uint256 _amount) public onlyManager();

	// Mints token Rewards to Forecasting contract
	function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();

	// Releases tokens (transfers crowdsale token from mintable to transferrable state)
	function releaseTokens() public onlyOwner() hasntStopped() whenCrowdsaleSuccessful();

	// Stops crowdsale. Called by CrowdsaleController, the latter is called by owner.
	// Crowdsale may be stopped any time before it finishes.
	function stop() public onlyManager() hasntStopped();

	// Validates parameters and starts crowdsale
	function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress) public onlyManager() hasntStarted() hasntStopped();

	// Is crowdsale failed (completed, but minimal goal wasn&#39;t reached)
	function isFailed() public constant returns (bool);

	// Is crowdsale active (i.e. the token can be sold)
	function isActive() public constant returns (bool);

	// Is crowdsale completed successfully
	function isSuccessful() public constant returns (bool);
}


contract A2ACrowdsale is ICrowdsaleProcessor {
    using SafeMath for uint256;
    
	event CROWDSALE_START(uint256 startTimestamp, uint256 endTimestamp, address fundingAddress);

	address public fundingAddress;
	address internal bountyAddress = 0x10945A93914aDb1D68b6eFaAa4A59DfB21Ba9951;
	
	A2AToken public token;
	
	mapping(address => bool) public partnerContracts;
	
	uint256 public icoPrice; // A2A tokens per 1 ether
	uint256 public icoBonus; // % * 10000
	
	uint256 constant public wingsETHRewardsPercent = 2 * 10000; // % * 10000
	uint256 constant public wingsTokenRewardsPercent = 2 * 10000; // % * 10000	
	uint256 public wingsETHRewards;
	uint256 public wingsTokenRewards;
	
	uint256 constant public maxTokensWithBonus = 500*(10**6)*(10**8);
	uint256 public bountyPercent;
		
	address[2] internal foundersAddresses = [
		0x2f072F00328B6176257C21E64925760990561001,
		0x2640d4b3baF3F6CF9bB5732Fe37fE1a9735a32CE
	];

	function A2ACrowdsale() public {
		owner = msg.sender;
		manager = msg.sender;
		icoPrice = 2000;
		icoBonus = 100 * 10000;
		wingsETHRewards = 0;
		wingsTokenRewards = 0;
		minimalGoal = 1000 ether;
		hardCap = 50000 ether;
		bountyPercent = 23 * 10000;
	}

	function mintETHRewards( address _contract, uint256 _amount ) public onlyManager() {
		require(_amount <= wingsETHRewards);
		require(_contract.call.value(_amount)());
		wingsETHRewards -= _amount;
	}
	
	function mintTokenRewards(address _contract, uint256 _amount) public onlyManager() {
		require( token != address(0) );
		require(_amount <= wingsTokenRewards);
		require( token.issueDuringICO(_contract, _amount) );
		wingsTokenRewards -= _amount;
	}

	function stop() public onlyManager() hasntStopped()	{
		stopped = true;
	}

	function start( uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress ) public onlyManager() hasntStarted() hasntStopped() {
		require(_fundingAddress != address(0));
		require(_startTimestamp >= block.timestamp);
		require(_endTimestamp > _startTimestamp);
		duration = _endTimestamp - _startTimestamp;
		require(duration >= MIN_CROWDSALE_TIME && duration <= MAX_CROWDSALE_TIME);
		startTimestamp = _startTimestamp;
		endTimestamp = _endTimestamp;
		started = true;
		emit CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
	}

	// must return true if crowdsale is over, but it failed
	function isFailed() public constant returns(bool) {
		return (
			// it was started
			started &&

			// crowdsale period has finished
			block.timestamp >= endTimestamp &&

			// but collected ETH is below the required minimum
			totalCollected < minimalGoal
		);
	}

	// must return true if crowdsale is active (i.e. the token can be bought)
	function isActive() public constant returns(bool) {
		return (
			// it was started
			started &&

			// hard cap wasn&#39;t reached yet
			totalCollected < hardCap &&

			// and current time is within the crowdfunding period
			block.timestamp >= startTimestamp &&
			block.timestamp < endTimestamp
		);
	}

	// must return true if crowdsale completed successfully
	function isSuccessful() public constant returns(bool) {
		return (
			// either the hard cap is collected
			totalCollected >= hardCap ||

			// ...or the crowdfunding period is over, but the minimum has been reached
			(block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
		);
	}
	
	function setToken( A2AToken _token ) public onlyOwner() {
		token = _token;
	}
	
	function getToken() public returns(address) {
	    return address(token);
	}
	
	function setPrice( uint256 _icoPrice ) public onlyOwner() returns(bool) {
		icoPrice = _icoPrice;
		return true;
	}
	
	function setBonus( uint256 _icoBonus ) public onlyOwner() returns(bool) {
		icoBonus = _icoBonus;
		return true;
	}
	
	function setBountyAddress( address _bountyAddress ) public onlyOwner() returns(bool) {
		bountyAddress = _bountyAddress;
		return true;
	}
	
	function setBountyPercent( uint256 _bountyPercent ) public onlyOwner() returns(bool) {
		bountyPercent = _bountyPercent;
		return true;
	}
	
	function setPartnerContracts( address _contract ) public onlyOwner() returns(bool) {
		partnerContracts[_contract] = true;
		return true;
	}	
		
	function deposit() public payable { }
		
	function() internal payable {
		ico( msg.sender, msg.value );
	}
	
	function ico( address _to, uint256 _val ) internal returns(bool) {
		require( token != address(0) );
		require( isActive() );
		require( _val >= ( 1 ether / 10 ) );
		require( totalCollected < hardCap );
		
		uint256 tokensAmount = _val.mul( icoPrice ) / 10**10;
		if ( ( icoBonus > 0 ) && ( totalSold.add(tokensAmount) < maxTokensWithBonus ) ) {
			tokensAmount = tokensAmount.add( tokensAmount.mul(icoBonus) / 1000000 );
		} else {
			icoBonus = 0;
		}
		require( totalSold.add(tokensAmount) < token.maxSupply() );
		require( token.issueDuringICO(_to, tokensAmount) );
		
		wingsTokenRewards = wingsTokenRewards.add( tokensAmount.mul( wingsTokenRewardsPercent ) / 1000000 );
		wingsETHRewards = wingsETHRewards.add( _val.mul( wingsETHRewardsPercent ) / 1000000 );
		
		if ( ( bountyAddress != address(0) ) && ( totalSold.add(tokensAmount) < maxTokensWithBonus ) ) {
			require( token.issueDuringICO(bountyAddress, tokensAmount.mul(bountyPercent) / 1000000) );
			tokensAmount = tokensAmount.add( tokensAmount.mul(bountyPercent) / 1000000 );
		}

		totalCollected = totalCollected.add( _val );
		totalSold = totalSold.add( tokensAmount );
		
		return true;
	}
	
	function icoPartner( address _to, uint256 _val ) public returns(bool) {
		require( partnerContracts[msg.sender] );
		require( ico( _to, _val ) );
		return true;
	}
	
	function calculateRewards() public view returns(uint256,uint256) {
		return (wingsETHRewards, wingsTokenRewards);
	}
	
	function releaseTokens() public onlyOwner() hasntStopped() whenCrowdsaleSuccessful() {
		
	}
	
	function withdrawToFounders(uint256 _amount) public whenCrowdsaleSuccessful() onlyOwner() returns(bool) {
		require( address(this).balance.sub( _amount ) >= wingsETHRewards );
        
		uint256 amount_to_withdraw = _amount / foundersAddresses.length;
		uint8 i = 0;
		uint8 errors = 0;        
		for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
		
		return true;
	}
}


contract A2ACrowdsalePartner is Ownable {
	using SafeMath for uint256;
	A2ACrowdsale public crowdsale;
	
	uint256 public partnerETHRewardsPercent; // % * 10000
	address public partnerAddress;
	
	address[2] internal foundersAddresses = [
		0x2f072F00328B6176257C21E64925760990561001,
		0x2640d4b3baF3F6CF9bB5732Fe37fE1a9735a32CE
	];
	
	function A2ACrowdsalePartner() public {
		partnerETHRewardsPercent = 8 * 10000;
	}
		
	function setCrowdsale( A2ACrowdsale _crowdsale ) public onlyOwner() returns(bool) {
		crowdsale = _crowdsale;
		return true;
	}
	
	function setPartnerETHRewardsPercent( uint256 _partnerETHRewardsPercent ) public onlyOwner() returns(bool) {
		partnerETHRewardsPercent = _partnerETHRewardsPercent;
		return true;
	}
	
	function setPartnerAddress( A2ACrowdsale _partnerAddress ) public onlyOwner() returns(bool) {
		partnerAddress = _partnerAddress;
		return true;
	}
	
	function() internal payable {
		require( crowdsale != address(0) );
		require( partnerAddress != address(0) );
		require( crowdsale.icoPartner( msg.sender, msg.value ) );
		
		uint256 partnerETHRewards = msg.value.mul( partnerETHRewardsPercent ) / 1000000;
		
		require( partnerAddress.send(partnerETHRewards) );
	}
	
	function withdrawToFounders(uint256 _amount) public onlyOwner() returns(bool) {
		require( address(this).balance >= _amount );

		uint256 amount_to_withdraw = _amount / foundersAddresses.length;
		uint8 i = 0;
		uint8 errors = 0;        
		for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
		
		return true;
	}
}