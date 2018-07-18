pragma solidity ^0.4.24;

// written by garry from Team Chibi Fighters
// find us at https://chibifighters.io
// chibifighters@gmail.com
// version 1.0.0


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface ERC20Interface {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external;
    function balanceOf(address _owner) external view returns (uint256 _balance);
}

interface ERC20InterfaceClassic {
    function transfer(address to, uint tokens) external returns (bool success);
}

contract DailyRewards is Owned {

	event RewardClaimed(
		address indexed buyer,
		uint256 day
	);
	
	// what day the player is on in his reward chain
	mapping (address => uint) private daysInRow;

	// timeout after which row is broken
	mapping (address => uint) private timeout;
	
	// how often the reward can be claimed, e.g. every 24h
	uint waitingTime = 24 hours;
	// window of claiming, if it expires day streak resets to day 1
	uint waitingTimeBuffer = 48 hours;
	
	
	constructor() public {
	    // Explore Chibis and their universe
	    // Off chain battles, real Ether fights, true on chain ownership
	    // Leaderboards, tournaments, roleplay elements, we got it all
	}
	
	
	function requestReward() public returns (uint _days) {
	    require (msg.sender != address(0));
	    require (now > timeout[msg.sender]);
	    
	    // waited too long, reset
	    if (now > timeout[msg.sender] + waitingTimeBuffer) {
	        daysInRow[msg.sender] = 1;    
	    } else {
	        // no limit to being logged in, looking forward to the longest streak
	        daysInRow[msg.sender]++;
	    }
	    
	    timeout[msg.sender] = now + waitingTime;
	    
	    emit RewardClaimed(msg.sender, daysInRow[msg.sender]);
	    
	    return daysInRow[msg.sender];
	}
	
	
	/**
	 * @dev Query stats of next reward, checks for expired time, too
	 **/
	function nextReward() public view returns (uint _day, uint _nextClaimTime, uint _nextClaimExpire) {
	    uint _dayCheck;
	    if (now > timeout[msg.sender] + waitingTimeBuffer) _dayCheck = 1; else _dayCheck = daysInRow[msg.sender] + 1;
	    
	    return (_dayCheck, timeout[msg.sender], timeout[msg.sender] + waitingTimeBuffer);
	}
	
	
	function queryWaitingTime() public view returns (uint _waitingTime) {
	    return waitingTime;
	}
	
	function queryWaitingTimeBuffer() public view returns (uint _waitingTimeBuffer) {
	    return waitingTimeBuffer;
	}
	

	/**
	 * @dev Sets the interval for daily rewards, e.g. 24h = 86400
	 * @param newTime New interval time in seconds
	 **/
	function setWaitingTime(uint newTime) public onlyOwner returns (uint _newWaitingTime) {
	    waitingTime = newTime;
	    return waitingTime;
	}
	
	
	/**
	 * @dev Sets buffer for daily rewards. So user have time to claim it. e.g. 1h = 3600
	 * @param newTime New buffer in seconds
	 **/
	function setWaitingTimeBuffer(uint newTime) public onlyOwner returns (uint _newWaitingTimeBuffer) {
	    waitingTimeBuffer = newTime;
	    return waitingTimeBuffer;
	}


    /**
    * @dev Send Ether to owner
    * @param _address Receiving address
    * @param _amountWei Amount in WEI to send
    **/
    function weiToOwner(address _address, uint _amountWei) public onlyOwner returns (bool) {
        require(_amountWei <= address(this).balance);
        _address.transfer(_amountWei);
        return true;
    }

    function ERC20ToOwner(address _to, uint256 _amount, ERC20Interface _tokenContract) public onlyOwner {
        _tokenContract.transfer(_to, _amount);
    }

    function ERC20ClassicToOwner(address _to, uint256 _amount, ERC20InterfaceClassic _tokenContract) public onlyOwner {
        _tokenContract.transfer(_to, _amount);
    }

}