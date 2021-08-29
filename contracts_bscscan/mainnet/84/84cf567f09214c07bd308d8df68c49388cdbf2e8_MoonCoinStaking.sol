/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract MoonCoinStaking  {

	using SafeMath for uint256;
	
	
	iMoonCoinApp MoonCoinApp;
	iMoonCoinFinanceApp public MoonCoinFinanceApp;	
	iAirdropsApp public AirdropsApp;
	
	uint256 public GAS_BONUS = 200*10**6*10**9;


	
	
	address payable public platformAddress;		
	
	event Evt_Invest(address indexed investor, address indexed referrer, uint256 investOption, uint256 allocationPercent, uint256 comboStakePercent, uint256 msgValue);
	
	constructor(iMoonCoinApp _MoonCoin, iAirdropsApp _AirdropsApp) public { 
		platformAddress=msg.sender;	
		MoonCoinApp = _MoonCoin;
		AirdropsApp = _AirdropsApp;
		MoonCoinApp.approve(address(AirdropsApp), 1000000000000000000000000000000000000);
	}
	
	function setApps(iMoonCoinApp _MoonCoin, iMoonCoinFinanceApp _MoonCoinFinanceApp, iAirdropsApp _AirdropsApp) external {
		require(msg.sender == platformAddress, "1");
		MoonCoinApp = _MoonCoin;
		MoonCoinFinanceApp = _MoonCoinFinanceApp;
		AirdropsApp = _AirdropsApp;
	}
	
	function setGasBonus(uint256 _GAS_BONUS) external { 
		require(msg.sender == platformAddress, "1");
		GAS_BONUS=_GAS_BONUS;
	} 


	function invest(address investor, address referrer, uint256 investOption, uint256 allocationPercent, uint256 comboStakePercent) public payable  {	
		
		uint256 msgValue;
		uint256 initialTokenBalance=MoonCoinApp.balanceOf(address(this));		
		
		if(investOption==1) {
			msgValue = msg.value.mul(comboStakePercent).div(100);
			MoonCoinFinanceApp.invest{value: msgValue}(investor, referrer);
			MoonCoinApp.transfer(investor, MoonCoinApp.balanceOf(address(this)).sub(initialTokenBalance).add(GAS_BONUS));
		
		}
		if(investOption==2) {
			msgValue = msg.value.mul(comboStakePercent).div(100);
			MoonCoinFinanceApp.invest{value: msgValue}(investor, referrer);
			uint256 allocateValue = MoonCoinApp.balanceOf(address(this)).sub(initialTokenBalance).mul(2).add(GAS_BONUS).div(10**9);
			AirdropsApp.addAllocation(investor, allocateValue, allocationPercent);
		}
		
		emit Evt_Invest(investor, referrer, investOption, allocationPercent, comboStakePercent, msgValue);
		
	}
	
	
	
    receive() external payable {}
	
function getRemainingMoons() public { 	// TBA	
		require(msg.sender == platformAddress, "1");
		MoonCoinApp.transfer(msg.sender, MoonCoinApp.balanceOf(address(this)));		
	} 
function getRemainingNative() public  {
        require(msg.sender == platformAddress, "1");
		address payable owner = msg.sender;
        owner.transfer(address(this).balance);
    }	


	
	
	
}



interface pancakeInterface {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
		
		
		 function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
	
	function getAmountsOut(uint amountIn, address[] calldata path) external returns (uint[] memory amounts);
}

interface iMoonCoinApp {
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	
}

interface iMoonCoinFinanceApp {
	function invest(address msgSender, address referrer) external payable;
	
}

interface iAirdropsApp {
	function addAllocation(address userAddress, uint256 allocateValue, uint256 _allocationPercent) external payable;
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