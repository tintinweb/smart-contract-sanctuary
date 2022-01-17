/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

 interface BEP20Interface {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
}



contract TimesStaking {
	using SafeMath for uint256;
	
	
	uint256 constant public PERCENTS_DIVIDER = 100;
    uint256 constant public MAX_Days = 200;
    uint256 constant public maturityPercentage = 200;
	uint256 constant public TIME_STEP =24 hours;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	
	address payable ownerAddress;
    BEP20Interface public tokenAddress=BEP20Interface(0x1e472984b06624Fad0E991d887C89dE6Ddcf3773);
  
	struct User {
		uint256 staked;
        bool isExist;
        uint256 withdrawn;
        uint256 start;
		uint256 checkpoint;
	}

	mapping (address => User) internal users;
	
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);


	constructor(address payable marketingAddr) {
       	require(!isContract(marketingAddr));
		ownerAddress = marketingAddr;
	   
	}
	
	
	
	function invest() public  {
		require(!users[msg.sender].isExist,"Allready Staked");
        uint256 _amount = 20*1e18;
		require(BEP20Interface(tokenAddress).transferFrom(msg.sender,address(this),_amount),"Token transfer failed");

		User storage user = users[msg.sender];
        users[msg.sender].isExist = true;
		 	totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		
		user.staked =  user.staked.add(_amount);
		totalInvested = totalInvested.add(_amount);
		totalDeposits = totalDeposits.add(1);
        user.start = block.timestamp;
        user.checkpoint = block.timestamp;

		emit NewDeposit(msg.sender, _amount);

	}
	
	

	function withdraw() public {
	   	User storage user = users[msg.sender];
		uint256 totalAmount;
		uint256 dividends;

		if (user.withdrawn < user.staked.mul(2)) {
    			    
		    uint256 time_end = user.start + MAX_Days * 86400;
            uint256 from = user.checkpoint > user.start ? user.checkpoint : user.start;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

			dividends = ((user.staked * (to - from) * maturityPercentage) /
                        MAX_Days /
                        TIME_STEP) /
                    PERCENTS_DIVIDER;

				if (user.withdrawn.add(dividends) > user.staked.mul(2)) {
					dividends = (user.staked.mul(2)).sub(user.withdrawn);
				}
			

				user.withdrawn = user.withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);
				user.checkpoint = block.timestamp;
			}
        
		require(totalAmount > 0, "User has no dividends");
		
		require(BEP20Interface(tokenAddress).transfer(msg.sender,totalAmount),"Token transfer failed");

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}
	

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		
		uint256 totalDividends;
		uint256 dividends;
		
		
			if (user.withdrawn <(user.staked.mul(maturityPercentage).div(PERCENTS_DIVIDER)).mul(MAX_Days)) {

			 uint256 time_end = user.start + MAX_Days * 86400;
            uint256 from = user.checkpoint > user.start ? user.checkpoint : user.start;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

				dividends = ((user.staked * (to - from) * maturityPercentage) /
                        MAX_Days /
                        TIME_STEP) /
                    PERCENTS_DIVIDER;

				if (user.withdrawn.add(dividends) > user.staked.mul(2)) {
					dividends = (user.staked.mul(2)).sub(user.withdrawn);
				}
				

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function
			}
		
		

		

		return totalDividends;
	}
	


	function getUserInfo(address userAddress) external view returns(uint256 invested,uint256 withdrawn)
	{
	    User storage user = users[userAddress];
        return (user.staked,user.withdrawn);
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    
     
    
   

}