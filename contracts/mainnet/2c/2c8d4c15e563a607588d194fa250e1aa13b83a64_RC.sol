pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
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

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
	function burn(uint256 _value) public returns(bool);
	uint256 public totalSupply;
	uint256 public decimals;
}

contract rateInterface {
    function readRate(string _currency) public view returns (uint256 oneEtherValue);
}

contract RC {
    using SafeMath for uint256;
    DaicoCoinCrowd tokenSaleContract;
    uint256 public startTime;
    uint256 public endTime;
    
    uint256 public etherMinimum;
    uint256 public soldTokens;
    uint256 public remainingTokens;
    
    uint256 public oneTokenInFiatWei;

    constructor(address _tokenSaleContract, uint256 _oneTokenInFiatWei, uint256 _remainingTokens, uint256 _etherMinimum, uint256 _startTime , uint256 _endTime) public {
        require ( _tokenSaleContract != 0, "Token Sale Contract can not be 0" );
        require ( _oneTokenInFiatWei != 0, "Token price can no be 0" );
        require( _remainingTokens != 0, "Remaining tokens can no be 0");
       
        
        
        tokenSaleContract = DaicoCoinCrowd(_tokenSaleContract);
        
        soldTokens = 0;
        remainingTokens = _remainingTokens;
        oneTokenInFiatWei = _oneTokenInFiatWei;
        etherMinimum = _etherMinimum;
        
        setTimeRC( _startTime, _endTime );
    }
    
    function setTimeRC(uint256 _startTime, uint256 _endTime ) internal {
        if( _startTime == 0 ) {
            startTime = tokenSaleContract.startTime();
        } else {
            startTime = _startTime;
        }
        if( _endTime == 0 ) {
            endTime = tokenSaleContract.endTime();
        } else {
            endTime = _endTime;
        }
    }
    
    modifier onlyTokenSaleOwner() {
        require(msg.sender == tokenSaleContract.owner(), "msg.sender == tokenSaleContract.owner()" );
        _;
    }
    
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyTokenSaleOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    
    function changeMinimum(uint256 _newEtherMinimum) public onlyTokenSaleOwner {
        etherMinimum = _newEtherMinimum;
    }
    
    function started() public view returns(bool) {
        return now > startTime || remainingTokens == 0;
    }
    
    function ended() public view returns(bool) {
        return now > endTime || remainingTokens == 0;
    }
    
    function startTime() public view returns(uint) {
        return startTime;
    }
    
    function endTime() public view returns(uint) {
        return endTime;
    }
    
    function totalTokens() public view returns(uint) {
        return remainingTokens.add(soldTokens);
    }
    
    function remainingTokens() public view returns(uint) {
        return remainingTokens;
    }
    
    function price() public view returns(uint) {
        uint256 oneEther = 1 ether;
        return oneEther.mul(10**18).div( tokenSaleContract.tokenValueInEther(oneTokenInFiatWei) );
    }
    
    event BuyRC(address indexed buyer, bytes trackID, uint256 value, uint256 soldToken, uint256 valueTokenInUsdWei );
	
    function () public payable {
        require( now > startTime, "now > startTime" );
        require( now < endTime, "now < endTime" );
        require( msg.value >= etherMinimum, "msg.value >= etherMinimum"); 
        require( remainingTokens > 0, "remainingTokens > 0" );
        
        uint256 tokenAmount = tokenSaleContract.buyFromRC.value(msg.value)(msg.sender, oneTokenInFiatWei, remainingTokens);
        
        remainingTokens = remainingTokens.sub(tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        
        emit BuyRC( msg.sender, msg.data, msg.value, tokenAmount, oneTokenInFiatWei );
    }
}

contract DaicoCoinCrowd is Ownable {
    using SafeMath for uint256;
    tokenInterface public tokenContract;
    rateInterface public rateContract;
    
    address public wallet;
    
	uint256 public decimals;
    
    uint256 public endTime;  // seconds from 1970-01-01T00:00:00Z
    uint256 public startTime;  // seconds from 1970-01-01T00:00:00Z
    
    uint256 public oneTokenInEur;

    mapping(address => bool) public rc;

    constructor(address _tokenAddress, address _rateAddress, uint256 _startTime, uint256 _endTime, uint256[] _time, uint256[] _funds, uint256 _oneTokenInEur, uint256 _activeSupply) public {
        tokenContract = tokenInterface(_tokenAddress);
        rateContract = rateInterface(_rateAddress);
        setTime(_startTime, _endTime); 
        decimals = tokenContract.decimals();
        oneTokenInEur = _oneTokenInEur;
        wallet = new MilestoneSystem(_tokenAddress, _time, _funds, _oneTokenInEur, _activeSupply);
    }
    
    function tokenValueInEther(uint256 _oneTokenInFiatWei) public view returns(uint256 tknValue) {
        uint256 oneEtherPrice = rateContract.readRate("eur");
        tknValue = _oneTokenInFiatWei.mul(10 ** uint256(decimals)).div(oneEtherPrice);
        return tknValue;
    } 
    
    modifier isBuyable() {
        require( wallet != address(0), "wallet != address(0)" );
        require( now > startTime, "now > startTime" ); // check if started
        require( now < endTime, "now < endTime"); // check if ended
        require( msg.value > 0, "msg.value > 0" );
		
		uint256 remainingTokens = tokenContract.balanceOf(this);
        require( remainingTokens > 0, "remainingTokens > 0" ); // Check if there are any remaining tokens 
        _;
    }
    
    event Buy(address buyer, uint256 value, address indexed ambassador);
    
    modifier onlyRC() {
        require( rc[msg.sender], "rc[msg.sender]" ); //check if is an authorized rcContract
        _;
    }
    
    function buyFromRC(address _buyer, uint256 _rcTokenValue, uint256 _remainingTokens) onlyRC isBuyable public payable returns(uint256) {
        uint256 oneToken = 10 ** uint256(decimals);
        uint256 tokenValue = tokenValueInEther(_rcTokenValue);
        uint256 tokenAmount = msg.value.mul(oneToken).div(tokenValue);
        address _ambassador = msg.sender;
        
        uint256 remainingTokens = tokenContract.balanceOf(this);
        if ( _remainingTokens < remainingTokens ) {
            remainingTokens = _remainingTokens;
        }
        
        if ( remainingTokens < tokenAmount ) {
            uint256 refund = tokenAmount.sub(remainingTokens).mul(tokenValue).div(oneToken);
            tokenAmount = remainingTokens;
            forward(msg.value.sub(refund));
			remainingTokens = 0; // set remaining token to 0
             _buyer.transfer(refund);
        } else {
			remainingTokens = remainingTokens.sub(tokenAmount); // update remaining token without bonus
            forward(msg.value);
        }
        
        tokenContract.transfer(_buyer, tokenAmount);
        emit Buy(_buyer, tokenAmount, _ambassador);
		
        return tokenAmount; 
    }
    
    function forward(uint256 _amount) internal {
        wallet.transfer(_amount);
    }

    event NewRC(address contr);
    
    function addRC(address _rc) onlyOwner public {
        rc[ _rc ]  = true;
        emit NewRC(_rc);
    }
    
    function setTime(uint256 _newStart, uint256 _newEnd) public onlyOwner {
        if ( _newStart != 0 ) startTime = _newStart;
        if ( _newEnd != 0 ) endTime = _newEnd;
    }
    
    function withdrawTokens(address to, uint256 value) public onlyOwner returns (bool) {
        return tokenContract.transfer(to, value);
    }
    
    function setTokenContract(address _tokenContract) public onlyOwner {
        tokenContract = tokenInterface(_tokenContract);
    }
    
    function setRateContract(address _rateAddress) public onlyOwner {
        rateContract = rateInterface(_rateAddress);
    }
	
	function claim(address _buyer, uint256 _amount) onlyRC public returns(bool) {
        return tokenContract.transfer(_buyer, _amount);
    }

    function () public payable {
        revert();
    }
}

contract MilestoneSystem {
    using SafeMath for uint256;
    tokenInterface public tokenContract;
    DaicoCoinCrowd public tokenSaleContract;
    
    uint256[] public time;
    uint256[] public funds;
    
    bool public locked = false; 
    uint256 public endTimeToReturnTokens; 
    
    uint8 public step = 0;
    
    uint256 public constant timeframeMilestone = 3 days; 
    uint256 public constant timeframeDeath = 30 days; 
    
    uint256 public activeSupply;
    
    uint256 public oneTokenInEur;
    
    mapping(address => mapping(uint8 => uint256) ) public balance;
    mapping(uint8 => uint256) public tokenDistrusted;
    
    constructor(address _tokenAddress, uint256[] _time, uint256[] _funds, uint256 _oneTokenInEur, uint256 _activeSupply) public {
        require( _time.length != 0, "_time.length != 0" );
        require( _time.length == _funds.length, "_time.length == _funds.length" );
        
        tokenContract = tokenInterface(_tokenAddress);
        tokenSaleContract = DaicoCoinCrowd(msg.sender);
        
        time = _time;
        funds = _funds;
        
        activeSupply = _activeSupply;
        oneTokenInEur = _oneTokenInEur;
    }
    
    modifier onlyTokenSaleOwner() {
        require(msg.sender == tokenSaleContract.owner(), "msg.sender == tokenSaleContract.owner()" );
        _;
    }
    
    event Distrust(address sender, uint256 amount);
    event Locked();
    
    function distrust(address _from, uint _value, bytes _data) public {
        require(msg.sender == address(tokenContract), "msg.sender == address(tokenContract)");
        
        if ( !locked ) {
            
            uint256 startTimeMilestone = time[step].sub(timeframeMilestone);
            uint256 endTimeMilestone = time[step];
            uint256 startTimeProjectDeath = time[step].add(timeframeDeath);
            bool unclaimedFunds = funds[step] > 0;
            
            require( 
                ( now > startTimeMilestone && now < endTimeMilestone ) || 
                ( now > startTimeProjectDeath && unclaimedFunds ), 
                "( now > startTimeMilestone && now < endTimeMilestone ) || ( now > startTimeProjectDeath && unclaimedFunds )" 
            );
        } else {
            require( locked && now < endTimeToReturnTokens ); //a timeframePost to deposit all tokens and then claim the refundMe method
        }
        
        balance[_from][step] = balance[_from][step].add(_value);
        tokenDistrusted[step] = tokenDistrusted[step].add(_value);
        
        emit Distrust(msg.sender, _value);
        
        if( tokenDistrusted[step] > activeSupply && !locked ) {
            locked = true;
            endTimeToReturnTokens = now.add(timeframeDeath);
            emit Locked();
        }
    }
    
    function tokenFallback(address _from, uint _value, bytes _data) public {
        distrust( _from, _value, _data);
    }
	
	function receiveApproval( address _from, uint _value, bytes _data) public {
	    require(msg.sender == address(tokenContract), "msg.sender == address(tokenContract)");
		require(msg.sender.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, this, _value));
        distrust( _from, _value, _data);
    }
    
    event Trust(address sender, uint256 amount);
    event Unlocked();
    
    function trust(uint8 _step) public {
        require( balance[msg.sender][_step] > 0 , "balance[msg.sender] > 0");
        
        uint256 amount = balance[msg.sender][_step];
        balance[msg.sender][_step] = 0;
        
        tokenDistrusted[_step] = tokenDistrusted[_step].sub(amount);
        tokenContract.transfer(msg.sender, amount);
        
        emit Trust(msg.sender, amount);
        
        if( tokenDistrusted[step] <= activeSupply && locked ) {
            locked = false;
            endTimeToReturnTokens = 0;
            emit Unlocked();
        }
    }
    
    event Refund(address sender, uint256 money);
    
    function refundMe() public {
        require(locked, "locked");
        require( now > endTimeToReturnTokens, "now > endTimeToReturnTokens" );
        
        uint256 ethTot = address(this).balance;
        require( ethTot > 0 , "ethTot > 0");
        
        uint256 tknAmount = balance[msg.sender][step];
        require( tknAmount > 0 , "tknAmount > 0");
        
        balance[msg.sender][step] = 0;
        
        tokenContract.burn(tknAmount);
        
        uint256 tknTot = tokenDistrusted[step];
        uint256 rate = tknAmount.mul(1 ether).div(tknTot);
        uint256 money = ethTot.mul(rate).div(1 ether);
        
        uint256 moneyMax = tknAmount.mul( tokenSaleContract.tokenValueInEther( oneTokenInEur )).div(1 ether) ;
        
        if ( money > moneyMax) { //This protects the project from the overvaluation of ether
            money = moneyMax;
        }
        
        if( money > address(this).balance ) {
		    money = address(this).balance;
		}
        msg.sender.transfer(money);
        
        emit Refund(msg.sender, money);
    }
    
    function OwnerWithdraw() public onlyTokenSaleOwner {
        require(!locked, "!locked");
        
        require(now > time[step], "now > time[step]");
        require(funds[step] > 0, "funds[step] > 0");
        
        uint256 amountApplied = funds[step];
        funds[step] = 0;
		step = step+1;
		
		uint256 value;
		if( amountApplied > address(this).balance || time.length == step+1)
		    value = address(this).balance;
		else {
		    value = amountApplied;
		}
		
        msg.sender.transfer(value);
    }
    
    function OwnerWithdrawTokens(address _tokenContract, address to, uint256 value) public onlyTokenSaleOwner returns (bool) { //for airdrop reason to distribute to CoinCrowd Token Holder
        require( _tokenContract != address(tokenContract), "_tokenContract != address(tokenContract)"); // the owner can withdraw tokens except CoinCrowd Tokens
        return tokenInterface(_tokenContract).transfer(to, value);
    }
    
    function () public payable {
        require(msg.sender == address(tokenSaleContract), "msg.sender == address(tokenSaleContract)");
    }
}