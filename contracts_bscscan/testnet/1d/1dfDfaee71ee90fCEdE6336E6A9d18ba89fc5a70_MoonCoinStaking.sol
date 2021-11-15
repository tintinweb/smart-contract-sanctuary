pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract MoonCoinStaking  {

	using SafeMath for uint256;
	
	
	iMoonCoinApp MoonCoinApp;
	iMoonCoinFinanceApp public MoonCoinFinanceApp;	
	iAirdropsApp public AirdropsApp;
	
	uint256 public GAS_BONUS = 100*10**6*10**9;
	uint256 public ALLOCATION_PERCENT = 10;
	
	pancakeInterface pancakeRouter;
	address[]   path;
	address[] reversePath;
	
	address payable public platformAddress;		
	
	
	constructor(iMoonCoinApp _MoonCoin, iAirdropsApp _AirdropsApp, pancakeInterface _pancakeRouter) public { 
		platformAddress=msg.sender;	
		MoonCoinApp = _MoonCoin;
		AirdropsApp = _AirdropsApp;
		pancakeRouter=pancakeInterface(_pancakeRouter);
		MoonCoinApp.approve(address(_pancakeRouter), 1000000000000000000000000000000000000);
		MoonCoinApp.approve(address(AirdropsApp), 1000000000000000000000000000000000000);
	}
	
	function setApps(iMoonCoinApp _MoonCoin, iMoonCoinFinanceApp _MoonCoinFinanceApp, iAirdropsApp _AirdropsApp, pancakeInterface _pancakeRouter, address[] memory _path,address[] memory _reversePath) external {
		MoonCoinApp = _MoonCoin;
		MoonCoinFinanceApp = _MoonCoinFinanceApp;
		AirdropsApp = _AirdropsApp;
		pancakeRouter=pancakeInterface(_pancakeRouter);
		path = _path;
		reversePath = _reversePath;
	}
	
	function setGasBonus(uint256 _GAS_BONUS) external { 
		require(msg.sender == platformAddress, "1");
		GAS_BONUS=_GAS_BONUS;
	} 
	function setAllocationPercent(uint256 _ALLOCATION_PERCENT) external { 
		require(msg.sender == platformAddress, "1");
		ALLOCATION_PERCENT=_ALLOCATION_PERCENT;
	} 

	function invest(address investor, address referrer, uint256 investOption) public payable {	
		
		uint256 msgValue;
		uint256 initialTokenBalance=MoonCoinApp.balanceOf(address(this));		
		if(investOption==1) {
			msgValue = msg.value;
			MoonCoinFinanceApp.invest{value: msgValue}(investor, referrer);
			MoonCoinApp.transfer(investor, MoonCoinApp.balanceOf(address(this)).sub(initialTokenBalance).add(GAS_BONUS));
		}
		if(investOption==2) {
			msgValue = msg.value.mul(9).div(10);
			MoonCoinFinanceApp.invest{value: msgValue}(investor, referrer);
			MoonCoinApp.transfer(investor, MoonCoinApp.balanceOf(address(this)).sub(initialTokenBalance).add(GAS_BONUS));
		
		}
		if(investOption==3) {
			msgValue = msg.value.mul(9).div(10);
			MoonCoinFinanceApp.invest{value: msgValue}(investor, referrer);
			uint256 allocateValue = MoonCoinApp.balanceOf(address(this)).sub(initialTokenBalance).mul(2).add(GAS_BONUS).div(10**9);
			AirdropsApp.addAllocation(investor, allocateValue, ALLOCATION_PERCENT);
		}
		
		/*
		uint256 initialBalance = address(this).balance;
		
		//invest to get MOONs
		MoonCoinFinanceApp.invest{value: msg.value}(address(this), referrer);
		
		// sell MOONs
		swapTokensForEth(MoonCoinApp.balanceOf(address(this)));
		
		//uint256 newBalance = address(this).balance.sub(initialBalance);
		
		// send half to client
		//investor.transfer(newBalance.div(2));
		*/
		
	}
	
	/*
	function swapTokensForEth(uint256 tokenAmount) private {
       
		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
		
  
    }
*/
	
    receive() external payable {}
	
function getRemainingMoons() public { 	// TBA	
		require(msg.sender == platformAddress, "1");
		MoonCoinApp.transfer(msg.sender, MoonCoinApp.balanceOf(address(this)));		
	} 
function recoverLostBNB() public  {
        require(msg.sender == platformAddress, "1");
		address payable owner = msg.sender;
        owner.transfer(address(this).balance);
    }	


/* old reference code

function deadWalletTransfer(uint256 _tokenToBurn) private {
		PlatformTokenApp.transfer(address(0x000000000000000000000000000000000000dEaD), _tokenToBurn); 
	}
	
	
	function tokenBurn() private  {	
						
		uint256 howMuchToBuyAtDex = buyBackAmount;	// all buyback amount is used to swap for tokens and burn	
		uint256 tokenToBurn = pancakeRouter.swapExactETHForTokens{value: howMuchToBuyAtDex}(1,path,address(this),now + 100000000)[1];
		buyBackAmount = 0;
		buyBackBurned = buyBackBurned.add(tokenToBurn);
		eventId++;
		emit Custom_BuyBackTokenBurn(eventId, block.timestamp, msg.sender, tokenToBurn, howMuchToBuyAtDex, buyBackBurned);
		deadWalletTransfer(tokenToBurn); 
		
	}
	
	
// buy code
function balancerBurn() public   {	
		require(msg.sender == platformAddress, "13");		
		require(block.timestamp.sub(lastBurnByPlatform) > 1*TIME_STEP, "14");  // TBA max once daily
		lastBurnByPlatform = block.timestamp;
		uint256 howMuchToBuyAtDex = address(this).balance.mul(BALANCER_BURN_PERCENT).div(1000);		// max 2% , note the devider is 1000 , can be set to 0-20 ie 0-2%
		uint256 tokenToBurn = pancakeRouter.swapExactETHForTokens{value: howMuchToBuyAtDex}(1,path,address(this),now + 100000000)[1];
		buyBackAmount = 0;
		buyBackBurned = buyBackBurned.add(tokenToBurn);
		deadWalletTransfer(tokenToBurn); 
	}
	
	//sell
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
	
	function balancerExecute(uint256 howManyNativeWorth) public payable{	
		uint256 tokensFromPlatform =  howManyNativeWorth.mul(tokenIssueRate).div(10**9); // TBA check this formula 
		uint256 tokensFromExchange = pancakeRouter.getAmountsOut(howManyNativeWorth,path)[1];
		require(tokensFromExchange < tokensFromPlatform); // TBA we will test this later
		pancakeRouter.swapExactTokensForBNBSupportingFeeOnTransferTokens(tokensFromExchange,0,reversePath,address(this),block.timestamp);
		
	}
	
	*/
	
	/* buy code
	function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
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

