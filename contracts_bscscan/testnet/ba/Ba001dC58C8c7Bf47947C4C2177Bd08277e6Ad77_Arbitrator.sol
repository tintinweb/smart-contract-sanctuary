pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract Arbitrator  {

	using SafeMath for uint256;
	
	
	
	
	iMoonCoin PlatformTokenApp;
	pancakeInterface pancakeRouter;
	address[]   path;
	
	address payable public platformAddress;
	iMoonCoinFinance public MoonCoinFinance;	
	address payable public mooncoinAddress;
	
	
	address payable referrer;
    

	constructor(iMoonCoin _MoonCoin, iMoonCoinFinance _MoonCoinFinance, pancakeInterface _pancakeRouter, address[] memory _path, address payable _mooncoinAddress, address payable _referrer) public { 
		platformAddress=msg.sender;	
		PlatformTokenApp = _MoonCoin;
		MoonCoinFinance = _MoonCoinFinance;
		mooncoinAddress=_mooncoinAddress;
		referrer=_referrer;
		
		PlatformTokenApp.approve(address(_pancakeRouter), 1000000000000000000000000000000000000);		
		pancakeRouter=pancakeInterface(_pancakeRouter);
		path = _path;	
		
	}
	

	
	function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

	function invest() public payable {	
		uint256 initialBalance = address(this).balance;
		
		//invest to get MOONs
		MoonCoinFinance.invest{value: msg.value}(address(this), referrer);
		//claim MOONs
		MoonCoinFinance.claimTokens();
		// sell MOONs
		swapTokensForEth(PlatformTokenApp.balanceOf(address(this)));
		
		//uint256 newBalance = address(this).balance.sub(initialBalance);
		
		// send half to client
		//msg.sender.transfer(newBalance.div(2));
		//referrer.transfer(address(this).balance);
		
	}
	
	function swapTokensForEth(uint256 tokenAmount) private {
       
		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
		
  
    }

	
    receive() external payable {}
	

function recoverLostBNB() public  {
        require(msg.sender == platformAddress, "1");
		address payable owner = msg.sender;
        owner.transfer(address(this).balance);
    }	


/* old reference code
function balancerExecute(uint256 howManyNativeWorth) public payable{	
		uint256 tokensFromPlatform =  howManyNativeWorth.mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR); 
		uint256 tokensFromExchange = pancakeRouter.getAmountsOut(howManyNativeWorth,path)[1];
		require(tokensFromExchange < tokensFromPlatform); 
		uint256 oldBalance =  address(this).balance;
		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensFromExchange,0,reversePath,address(this),block.timestamp);
		uint256 newBalance =  address(this).balance;
		eventId++;
		emit Evt_balancerExecute(eventId, block.timestamp, msg.sender, howManyNativeWorth, tokensFromExchange, tokensFromPlatform, oldBalance, newBalance);
		
	}
	*/
	
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

interface iMoonCoin {
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	
}

interface iMoonCoinFinance {
	function invest(address msgSender, address referrer) external payable;
	function claimTokens() external ;	
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

