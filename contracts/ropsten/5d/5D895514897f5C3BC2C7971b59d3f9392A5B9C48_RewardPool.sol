pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/Constants.sol";
import "./libs/IPancakeRouter02.sol";
import "./libs/IMasterChef.sol";
import "./libs/IRewardPool.sol";
// CHANGE FOR BSC
//import "./libs/SafeBEP20.sol";
//import "./libs/IBEP20.sol";
/*
Note: This contract is ownable, therefor the owner wields a good portion of power.
The owner will be able:
-   initiate the reward pool 
-   transfer BUSD to masterChef contract
-   remove liquidity to token pairs
-   swap tokens to BUSD
-   swap 20% of BUSD to LOTL
-   burn all present LOTL
The BUSD address is a set constant derived from ./libs/Constants.sol and not changeable.
Thus the owner has only the power to withhold all the funds in this contract
but can only transfer them to the masterChef contract in form of BUSD.
This contract uses the UniSwapRouter interfaces to: 
    removeAllLiquidity of LP tokens
    swap all tokens to BUSD
    swap 20% to Lotl
    burn that lotl
    transfer the remaining BUSD to MasterChef
    initiate reward distribution
*/
contract RewardPool is Ownable, Constants, IRewardPool {
    using SafeERC20 for IERC20;
    IMasterChef public chef;
    address public lotlToken;
    // Tokens associated with the LP pair. 
    struct LpTokenPair {
    	IERC20 tokenA;
        IERC20 tokenB;
    }
    // All different LP tokens registered.
    IERC20[] public lptoken;
	// All different tokens registered.
	IERC20[] public tokens; 
    // Swapping paths.
    mapping(address => mapping(address => address[])) paths;
	// Maps the LP pair to the tokens 
	mapping (IERC20 => LpTokenPair) public lpPairs;
	// Used to determine wether a pool has already been added.
    mapping(IERC20 => bool) public poolExistence;
    // Used to determine wether a token has already been added.
    mapping(IERC20 => bool) public tokenExistence;
    // Limits the Owner to a maximum of one burn per reward pool cycle.
    bool public hasSwappedToLotlThisCycle;
    // Modifier to allow only new pools being added.
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }
    event BurnLotl(address indexed lotl, uint256 amount);
    event TransferAllBUSD(address indexed user, uint256 amount);
    event DistributeRewardPool(address indexed);
    event CalculateRewards(address indexed);
  	constructor(address _chef, address _lotl) public {
  		chef = IMasterChef(_chef);
        lotlToken = _lotl;
        hasSwappedToLotlThisCycle = false;
  		 // Sell Tokens Paths BSC
         /*
		paths[wbnbAddr][busdAddr] = [wbnbAddr, busdAddr];
		paths[usdtAddr][busdAddr] = [usdtAddr, busdAddr];

		paths[btcbAddr][busdAddr] = [btcbAddr, wbnbAddr, busdAddr];
		paths[wethAddr][busdAddr] = [wethAddr, wbnbAddr, busdAddr];
		paths[daiAddr][busdAddr] = [daiAddr, busdAddr];
		paths[usdcAddr][busdAddr] = [usdcAddr, busdAddr];
		paths[dotAddr][busdAddr] = [dotAddr, wbnbAddr, busdAddr];
		paths[cakeAddr][busdAddr] = [cakeAddr, wbnbAddr, busdAddr];
		paths[worldAddr][busdAddr] = [worldAddr, wbnbAddr, busdAddr];
		paths[gnyAddr][busdAddr] = [gnyAddr, wbnbAddr, busdAddr];
		paths[vaiAddr][busdAddr] = [vaiAddr, ustAddr, wbnbAddr, busdAddr];
        */
        // Ropsten paths
        paths[wbnbAddr][busdAddr] = [wbnbAddr, busdAddr];
        paths[lotlToken][busdAddr] = [lotlToken, busdAddr];
        paths[busdAddr][lotlToken] = [busdAddr, lotlToken];
  		}
  	// Function to add router paths, needed if new LP pairs with new tokens are added.
  	function setRouterPath(address inputToken, address outputToken, address[] calldata _path, bool overwrite) external onlyOwner {
        address[] storage path = paths[inputToken][outputToken];
        uint256 length = _path.length;
        if (!overwrite) {
            require(length == 0, "setRouterPath: ALREADY EXIST");
        }
        for (uint8 i = 0; i < length; i++) {
            path.push(_path[i]);
        }
    }
    // Uses input token and output token to determine best swapping path.
    function getRouterPath(address inputToken, address outputToken) private view returns (address[] storage){
        address[] storage path = paths[inputToken][outputToken];
        require(path.length > 0, "getRouterPath: MISSING PATH");
        return path;
    }
    // Returns current time + 60 second.
    function getTxDeadline() private view returns (uint256){
        return block.timestamp + 60;
    }
    // Swaps BUSD to LOTL without concern about minimum/slippage.
    function swapToLotl() public onlyOwner{
        if(hasSwappedToLotlThisCycle){
            return;
        }
        IERC20(busdAddr).approve(routerAddr, IERC20(busdAddr).balanceOf(address(this))/5);
        IPancakeRouter02(routerAddr).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(busdAddr).balanceOf(address(this))/5,
            0,
            getRouterPath(busdAddr, lotlToken),
            address(this),
            getTxDeadline()
        );
        hasSwappedToLotlThisCycle = true;
    }
    // Transfers all BUSD to MasterChef
    function transferAllBUSD () public onlyOwner {
        IERC20(busdAddr).transfer(address(chef), IERC20(busdAddr).balanceOf(address(this)));
        emit TransferAllBUSD(msg.sender, IERC20(busdAddr).balanceOf(address(this)));
    }    

    // Initiates the reward calculation in the MasterChefContract
    function calculateRewards() public onlyOwner{
        chef.calculateRewardPool();
        emit CalculateRewards(msg.sender);
    }

    // Burns LOTL.
    function burnLotl () public onlyOwner {
        IERC20(lotlToken).transfer(burnAddr, IERC20(lotlToken).balanceOf(address(this)));
        emit BurnLotl(msg.sender, IERC20(lotlToken).balanceOf(address(this)));
    }
    // Swaps token to BUSD supporting fees on token.
    function swapToBusd(IERC20 _inputToken, uint256 _amount) private{
        if(_inputToken == IERC20 (busdAddr)){
            return;
        }
        _inputToken.approve(routerAddr, _amount);
        IPancakeRouter02(routerAddr).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            getRouterPath(address(_inputToken), busdAddr),
            address(this),
            getTxDeadline()
        );
    } 
    // Breaks up liquidity pools into tokens and swaps tokens to BUSD.
    function removeLiquidityExternal (IERC20 _lpToken, uint256 _amount) public override{
        require(msg.sender == address(chef) ,"chef: u no master");
        _lpToken.approve(routerAddr, _lpToken.balanceOf(address(this)));
        IERC20 _tokenA = lpPairs[_lpToken].tokenA;
        IERC20 _tokenB = lpPairs[_lpToken].tokenB;
        uint256 amountA;
        uint256 amountB;
        (amountA, amountB) = IPancakeRouter02(routerAddr).removeLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amount,
            0,
            0,
            address(this),
            getTxDeadline()
        );
        if(_tokenA != IERC20(busdAddr)){
            swapToBusd(_tokenA, amountA);
        }
        if(_tokenB != IERC20(busdAddr)){
            swapToBusd(_tokenB, amountB);
        } 
    }
    // Calls private function swapToBusd.
    function swapToBusdExternal(IERC20 _token,  uint256 _amount) public override{
        require(msg.sender == address(chef) ,"chef: u no master");
        swapToBusd(_token, _amount);
    }
    // Resets burn cycle, called by masterchef after reward distribution
    function resetBurnCycle() public override{
        require(msg.sender == address(chef) ,"chef: u no master");
        hasSwappedToLotlThisCycle = false;
    }
   	// Add new LP tokens and tokens to the existing storage, can only be called via MasterChef contract.
    function addLpToken(IERC20 _lpToken, IERC20 _tokenA, IERC20 _tokenB, bool isLPToken) public override nonDuplicated(_lpToken){
        require(msg.sender == address(chef) ,"chef: u no master");
        if(isLPToken)
        {
    		lptoken.push(_lpToken);
    		poolExistence[_lpToken] = true;
    		LpTokenPair storage lp = lpPairs[_lpToken];
    		lp.tokenA = _tokenA;
    		lp.tokenB = _tokenB;
    		if(!tokenExistence[_tokenB])
            {
    			tokens.push(_tokenB);
    			tokenExistence[_tokenB] = true;
    		}
    		if(!tokenExistence[_tokenA])
            {
    			tokens.push(_tokenA);
    			tokenExistence[_tokenA] = true;
    		}
        }
        else 
        {
            if(!tokenExistence[_lpToken])
            {
            tokens.push(_lpToken);
            tokenExistence[_lpToken] = true;
            }

    	}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract Constants {

    /* bsc constants
    address constant wbnbAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant busdAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant usdtAddr = 0x55d398326f99059fF775485246999027B3197955;
    address constant btcbAddr = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant wethAddr = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address constant daiAddr = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address constant usdcAddr = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant dotAddr = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;
    address constant cakeAddr = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address constant gnyAddr = 0xe4A4Ad6E0B773f47D28f548742a23eFD73798332;
    address constant worldAddr = 0x31FFbe9bf84b4d9d02cd40eCcAB4Af1E2877Bbc6;
    address constant vaiAddr = 0x4bd17003473389a42daf6a0a729f6fdb328bbbd7;
    address constant ustAddr = 0x23396cf899ca06c4472205fc903bdb4de249d6fc;
    address constant routerAddr = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    */
    // Ropsten Constants
    address constant wbnbAddr = 0x6123D16F767EB39936cDf92e17697764d13C9Dfc;
    address constant busdAddr = 0x4260E200A356bd15ed210ff4dA0D0e59bac1a38f;
    address constant routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant burnAddr = 0x000000000000000000000000000000000000dEaD;
}

pragma solidity ^0.8.0;

interface IMasterChef{
    function calculateRewardPool() external;
}

pragma solidity >=0.6.2<=0.9.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2<=0.9.0;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "./IBEP20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardPool{
    function addLpToken(IERC20 _lpToken, IERC20 _tokenA, IERC20 _tokenB, bool _isLPToken) external;
    function resetBurnCycle() external;
    function removeLiquidityExternal (IERC20 _lpToken, uint256 _amount) external;
    function swapToBusdExternal(IERC20 _token,  uint256 _amount) external;
    
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}