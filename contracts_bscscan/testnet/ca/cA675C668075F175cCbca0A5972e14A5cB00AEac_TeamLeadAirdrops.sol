pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract TeamLeadAirdrops  {


/*
design
let add team leader to make an entry (require done = 0)
-compeltion 3 types:
	1) admin can complete and update done =1, also delete arrays
	2) teamlead can complete and update done =1 also delete arrays
	3) admin can grab data and put into web, then done=1
*/

	using SafeMath for uint256;
		
		struct TeamLeadAirdrop {
		address[]  receivers;
		uint256[]  amounts;
		uint256 totalCost;
		address teamlead;
		uint256 done;
	}

	mapping (address => TeamLeadAirdrop) public teamlead_airdrops;
		
	iMoonCoin public MoonCoinApp;
	
	
	address payable public platformAddress;
	event TeamLeadAirdropSummary(address indexed teamLead, uint256 noOfUsers, uint256 totalCost, uint256 amountReceived);
	event TeamLeadAirdropSent(address indexed from, address indexed to, uint256 value);

	constructor( iMoonCoin _MoonCoin) public { 
		platformAddress=msg.sender;	
		MoonCoinApp = _MoonCoin;
	}
	  receive() external payable {}
	  
	
	
	
	
		function sendTeamLeadAirdrop(address teamLeadAddress, uint256 option) public {
			if(option==2) {
				require(msg.sender == platformAddress, "1");
			}
			TeamLeadAirdrop storage teamlead_airdrop = teamlead_airdrops[teamLeadAddress];
			require(teamlead_airdrop.done==1, "No Pending teamlead_airdrop");
			uint256 toSend;
			for (uint256 i = 0; i < teamlead_airdrop.receivers.length; ++i) {	
				toSend = teamlead_airdrop.amounts[i].mul(10**9);
				MoonCoinApp.transfer(teamlead_airdrop.receivers[i], toSend);
				emit TeamLeadAirdropSent(teamlead_airdrop.teamlead, teamlead_airdrop.receivers[i], toSend);
			}
			delete teamlead_airdrop.receivers;
			delete teamlead_airdrop.amounts;	
			teamlead_airdrop.done=0;		
			teamlead_airdrop.totalCost=0;			
		}
		
		
		function multiSend(address[] memory _receivers, uint256[] memory _amounts) public {
			require(msg.sender == platformAddress, "1"); // TBA
			
			uint256 toSend;
			for (uint256 i = 0; i < _receivers.length; ++i) {	
				toSend = _amounts[i].mul(10**9);
				MoonCoinApp.transfer(_receivers[i], toSend);
			}		
			
		}
		
		function setTeamLeadAirdrop(address[] memory _receivers, uint256[] memory _amounts, uint256 _totalCost) public {
			TeamLeadAirdrop storage teamlead_airdrop = teamlead_airdrops[msg.sender];
			
			teamlead_airdrop.receivers = _receivers;
			teamlead_airdrop.amounts = _amounts;
			teamlead_airdrop.teamlead = msg.sender;
			
			require(teamlead_airdrop.done==0, "Pending teamlead_airdrop");
			
			uint256 amountReceived;
			for (uint256 i = 0; i < teamlead_airdrop.receivers.length; ++i) {				
				amountReceived = amountReceived.add(teamlead_airdrop.amounts[i].mul(10**9));
			}			
			require(amountReceived==_totalCost.mul(10**9), "totalCost Error");
			teamlead_airdrop.totalCost = _totalCost.mul(10**9);
						
			MoonCoinApp.transferFrom(msg.sender, address(this), _totalCost.mul(10**9)); 		
			teamlead_airdrop.done=1;
			emit TeamLeadAirdropSummary(msg.sender, teamlead_airdrop.receivers.length, _totalCost.mul(10**9), amountReceived);
			
		}

		
		function deleteTeamLeadAirdrop(address teamLeadAddress) public {
		
		require(msg.sender == platformAddress, "1"); // TBA
		TeamLeadAirdrop storage teamlead_airdrop = teamlead_airdrops[teamLeadAddress];
		require(teamlead_airdrop.done==1, "No Pending teamlead_airdrop");
			delete teamlead_airdrop.receivers;
			delete teamlead_airdrop.amounts;
			teamlead_airdrop.done=0;
			teamlead_airdrop.totalCost=0;
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

	
	function getTeamLeadAirdropDetails(address teamLeadAddress) public view returns(address, uint256, uint256, uint256, uint256) {
			TeamLeadAirdrop storage teamlead_airdrop = teamlead_airdrops[teamLeadAddress];
			
			uint256 amountReceived;
			for (uint256 i = 0; i < teamlead_airdrop.receivers.length; ++i) {				
				amountReceived = amountReceived.add(teamlead_airdrop.amounts[i].mul(10**9));
			}	
			
			return (teamlead_airdrop.teamlead, teamlead_airdrop.receivers.length, teamlead_airdrop.done, amountReceived, teamlead_airdrop.totalCost);	
		
	}
	
	function getTeamLeadAirdropAmount(address teamLeadAddress, uint256 number) public view returns(address, uint256) {
			TeamLeadAirdrop storage teamlead_airdrop = teamlead_airdrops[teamLeadAddress];
			return (teamlead_airdrop.receivers[number], teamlead_airdrop.amounts[number]);	
		
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

