pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    /*
	//Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
	*/
	
}

contract StakingFeeder  {
    using SafeMath for uint256;
	IERC20 public wbnb;
	
	iMoonCoinApp MoonCoinApp;
	iMoonCoinFinanceApp public MoonCoinFinanceApp;		
	
	pancakeInterface pancakeRouter;
	address[]   path;
	address[] reversePath;
	
	address payable public platformAddress;	
	
	uint256 public TIME_STEP = 10 seconds; // TBA 1 days
	uint256 public constant PERCENTS_DIVIDER = 1000;
	uint256 public FEED_PERCENT = 5; // 0.5% max 
	uint256 public EXCHANGE_APP_TOKENS ;
	uint256 public lastTriggerByPlatform;
	
	constructor(iMoonCoinApp _MoonCoin,  pancakeInterface _pancakeRouter) public { 
		platformAddress=msg.sender;	
		MoonCoinApp = _MoonCoin;
		pancakeRouter=pancakeInterface(_pancakeRouter);
		MoonCoinApp.approve(address(_pancakeRouter), 1000000000000000000000000000000000000);
		wbnb = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // TBA testnet
	}
	
	function setFeedPercent(uint256 _FEED_PERCENT) public { 
		require(msg.sender == platformAddress, "1");
		if(_FEED_PERCENT  <= 10 ) { 
			FEED_PERCENT=_FEED_PERCENT;
		}
	} 
	
	function setApps(iMoonCoinApp _MoonCoin, iMoonCoinFinanceApp _MoonCoinFinanceApp,  pancakeInterface _pancakeRouter, address[] memory _path,address[] memory _reversePath) public {
		require(msg.sender == platformAddress, "1");
		MoonCoinApp = _MoonCoin;
		MoonCoinFinanceApp = _MoonCoinFinanceApp;
		pancakeRouter=pancakeInterface(_pancakeRouter);
		path = _path;
		reversePath = _reversePath;
	}
	
	function getStakingAppRate() public view returns (uint256) {
		uint256 tokenIssueRate;
		(,,,tokenIssueRate)=MoonCoinFinanceApp.getterGlobal2();
		return tokenIssueRate.mul(10**9);
	}
	
	function getStakingAppTokens() public view returns (uint256) {
		uint256 stakingAppBalance;
		(,,,stakingAppBalance,,)=MoonCoinFinanceApp.getterGlobal1();
		return stakingAppBalance.mul(FEED_PERCENT).mul(getStakingAppRate()).div(PERCENTS_DIVIDER).div(10**18);
	}
	
	function updateExchangeStats() public {
		EXCHANGE_APP_TOKENS=getExchangeAppRate(getterPoolBalance().mul(FEED_PERCENT).div(PERCENTS_DIVIDER));
	}
	
	function getExchangeAppRate(uint256 howManyNativeWorth) public  returns (uint256) {
		return pancakeRouter.getAmountsOut(howManyNativeWorth,path)[1];
	}

	function getExchangeAppTokens() public view returns (uint256) {
		return EXCHANGE_APP_TOKENS;
	}
	function getPair() public view returns ( address pair ) {
        return ( MoonCoinApp.uniswapV2Pair());		
    }
	function getterPoolBalance() public view returns ( uint256 ) {
        return ( wbnb.balanceOf(getPair()));		
    }
	
	function triggerTheFeed() public payable{	
		require(msg.sender == platformAddress, "1");
		//require(block.timestamp.sub(lastTriggerByPlatform) > 1*TIME_STEP, "14");  // TBA max once daily
		lastTriggerByPlatform = block.timestamp;		
		updateExchangeStats();
		uint256 tokensToSwap = getExchangeAppTokens().add(getStakingAppTokens());
		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensToSwap,0,reversePath,address(this),block.timestamp);
	}
	
	/*
	function balancerExecute(uint256 howManyNativeWorth) public payable{	
		uint256 tokensFromPlatform =  howManyNativeWorth.mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR); 
		uint256 tokensFromExchange = pancakeRouter.getAmountsOut(howManyNativeWorth,path)[1];
		require(tokensFromExchange < tokensFromPlatform); 
		uint256 oldBalance =  address(this).balance;
		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensFromExchange,0,reversePath,address(this),block.timestamp);
		uint256 newBalance =  address(this).balance;
		
		
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
*/
	
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
		require(block.timestamp.sub(lastTriggerByPlatform) > 1*TIME_STEP, "14");  // TBA max once daily
		lastTriggerByPlatform = block.timestamp;
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
	function uniswapV2Pair() external view returns (address);
	
}

interface iMoonCoinFinanceApp {
		function getterGlobal2() external view returns(uint256,   uint256,uint256,uint256);
		function getterGlobal1() external view returns(  uint256, uint256, uint256,uint256, uint256, uint256);
	
}

