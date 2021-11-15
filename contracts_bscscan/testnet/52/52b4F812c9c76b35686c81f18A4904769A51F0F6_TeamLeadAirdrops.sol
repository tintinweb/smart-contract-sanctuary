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
		
		struct Airdrop {
		address[]  receivers;
		uint256[]  amounts;
		address teamlead;
		uint256 done;
	}

	mapping (address => Airdrop) public airdrops;
		
	iMoonCoin public MoonCoinApp;
	
	
	address payable public platformAddress;
	event AirdropSummary(address indexed teamLead, uint256 noOfUsers, uint256 totalCost);
	event AirdropSent(address indexed from, address indexed to, uint256 value);

	constructor( iMoonCoin _MoonCoin) public { 
		platformAddress=msg.sender;	
		MoonCoinApp = _MoonCoin;
	}
	  receive() external payable {}
	  
	
	
	
	
		function sendAirdrop(address teamLeadAddress, uint256 option) public {
			if(option==1) {
				require(msg.sender == platformAddress, "1");
			}
			Airdrop storage airdrop = airdrops[teamLeadAddress];
			uint256 toSend;
			for (uint256 i = 0; i < airdrop.receivers.length; ++i) {	
				toSend = airdrop.amounts[i].mul(10**9);
				MoonCoinApp.transfer(airdrop.receivers[i], toSend);
				emit AirdropSent(airdrop.teamlead, airdrop.receivers[i], toSend);
			}
			delete airdrop.receivers;
			delete airdrop.amounts;	
			airdrop.done=0;			
		}
		
		

		
		function setAirdrop(address[] memory _receivers, uint256[] memory _amounts, uint256 _totalCost) public {
			Airdrop storage airdrop = airdrops[msg.sender];
			
			airdrop.receivers = _receivers;
			airdrop.amounts = _amounts;
			airdrop.teamlead = msg.sender;
			
			require(airdrop.done==0, "Pending airdrop");
			
			uint256 amountReceived;
			for (uint256 i = 0; i < airdrop.receivers.length; ++i) {				
				amountReceived = amountReceived.add(airdrop.amounts[i].mul(10**9));
			}			
			require(amountReceived==_totalCost, "totalCost Error");
						
			MoonCoinApp.transferFrom(msg.sender, address(this), _totalCost); 		
			airdrop.done=1;
			emit AirdropSummary(msg.sender, airdrop.receivers.length, _totalCost);
			
		}

		
		function deleteAirdrop(address teamLeadAddress) public {
		require(msg.sender == platformAddress, "1");
		Airdrop storage airdrop = airdrops[teamLeadAddress];
			delete airdrop.receivers;
			delete airdrop.amounts;
			airdrop.done=0;
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

	
	function getAirdropMemberSize(address teamLeadAddress) public view returns(uint256) {
			Airdrop storage airdrop = airdrops[teamLeadAddress];
			return (airdrop.receivers.length);	
		
	}
	
	function getAirdropAmount(address teamLeadAddress, uint256 number) public view returns(address, uint256) {
			Airdrop storage airdrop = airdrops[teamLeadAddress];
			return (airdrop.receivers[number], airdrop.amounts[number]);	
		
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

