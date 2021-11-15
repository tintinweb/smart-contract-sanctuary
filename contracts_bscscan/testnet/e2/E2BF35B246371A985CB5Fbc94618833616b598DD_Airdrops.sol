pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract Airdrops  {


/*
design
just add numbers to wallet address
*/

	using SafeMath for uint256;
		
		uint256 public TIME_STEP = 2 minutes; // TBA 1 days
		uint256 public ALLOCATE_PERCENT = 10;
		uint256 public constant PERCENTS_DIVIDER = 1000;	
		
		struct User {
		uint256 issued;
		uint256 claimed;
		uint256 joined;
		uint256 userId;
		uint256 allocated;
		uint256 pastClaims;
		uint256 allocateTime;
	}
	
	mapping (address => User) public users;
	mapping(uint => address) internal idToAddress;
	uint256 public lastUserId = 2;	
	iMoonCoin public MoonCoinApp;
	
	
	address payable public platformAddress;
	
	constructor( iMoonCoin _MoonCoin) public { 
		platformAddress=msg.sender;	
		MoonCoinApp = _MoonCoin;
		
		User storage user = users[platformAddress];        
        user.userId=1;		
        idToAddress[1] = platformAddress;
	}
	  receive() external payable {}
	  
		function joinAirdrop() public {
			User storage user = users[msg.sender];
			require(user.joined==0, "joined");
			user.joined = 1;
			user.allocateTime=block.timestamp;
			user.userId=lastUserId;					
			idToAddress[lastUserId] = msg.sender;
			lastUserId++;	
		}
		
		function addAirdrops(uint256[] memory _receivers, uint256[] memory _amounts, uint256 _totalCost) public {
			require(msg.sender == platformAddress, "1"); // TBA
			uint256 amountReceived;
			uint256 toAdd;
			for (uint256 i = 0; i < _receivers.length; ++i) {				
				User storage user = users[idToAddress[_receivers[i]]];
				if(user.joined==0) {
					user.joined=1;
					user.allocateTime=block.timestamp;
				}
				toAdd=_amounts[i].mul(10**9);				
				user.issued = user.issued.add(toAdd);
				amountReceived = amountReceived.add(toAdd);
			}			
			require(amountReceived==_totalCost, "totalCost Error");
			MoonCoinApp.transferFrom(msg.sender, address(this), _totalCost); 
		}
		
		function addAllocation(address userAddress, uint256 allocateValue) public {
			User storage user = users[userAddress];
			user.allocated = user.allocated.add(allocateValue);			
			MoonCoinApp.transferFrom(msg.sender, address(this), allocateValue); 
		}

		function claimAirdrops() public {
			User storage user = users[msg.sender];
			require(user.joined==1, "not joined");
			
			uint256 pastClaims = getPastClaims(msg.sender);
			user.pastClaims = user.pastClaims.add(pastClaims);
			user.allocateTime=block.timestamp; // TBA need to do it somewhere
			
			
			uint256 toClaim;
			toClaim=user.issued.sub(user.claimed);			
			user.claimed = user.claimed.add(toClaim);
			
			toClaim=toClaim.add(pastClaims);
			
			require(toClaim > 0, "no claim");
			MoonCoinApp.transfer(msg.sender, toClaim);	
		}
		
		function getPastClaims(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		if(user.allocateTime > 0){
			uint256 secPassed = block.timestamp.sub(user.allocateTime);
			uint256 calculateProfit;
			if (secPassed > 0) {
				calculateProfit = (user.allocated.mul(ALLOCATE_PERCENT).div(PERCENTS_DIVIDER)).mul(secPassed).div(TIME_STEP);
			}
			if (calculateProfit >= user.allocated.sub(user.pastClaims)){
				return user.allocated.sub(user.pastClaims);
			}
			else{
				return calculateProfit;
			}
			
			
		} else {
			return 0;
		}
	}
		
		function getAirdropDetails(uint256 userId) public view returns( uint256, uint256, uint256,uint256,uint256, uint256, uint256) {
			User storage user = users[idToAddress[userId]];			
			return (user.issued, user.claimed, user.joined, user.allocated, user.pastClaims,user.allocateTime, MoonCoinApp.balanceOf(address(this)));	
		
	}
	

	
	
	function getRemainingMoons() public { 	// TBA	
		require(msg.sender == platformAddress, "1");
		MoonCoinApp.transfer(msg.sender, MoonCoinApp.balanceOf(address(this)));		
	} 


function recoverLostBNB() public  {
        require(msg.sender == platformAddress, "1");
		address payable owner = msg.sender;
        owner.transfer(address(this).balance);
    }	

	
	
	
	
	
}


interface iMoonCoin {
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}




library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

