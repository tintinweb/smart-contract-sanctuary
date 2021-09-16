// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "./interfaces/swaps/IUniswapV2Router02.sol";
import {IRewardPool} from "./interfaces/IRewardPool.sol";
import {Governable} from "./lib/Governable.sol";

/// @title Beluga FeeRewardForwarder
/// @author Chainvisions
/// @notice Contract for handling the conversion of Beluga's protocol fees.

contract FeeRewardForwarder is Governable {
    using SafeERC20 for IERC20;

    /// @notice BELUGA token, immutable as the address varies from chain-to-chain.
    address public immutable BELUGA;

    /// @notice Percentage of fees to use to buyback BELUGA.
    uint256 public belugaBuybackNumerator;

    /// @notice Precision for calculating BELUGA buybacks.
    uint256 public belugaBuybackDenominator = 10000; // 1e4 precision, allowing for percentages down to 0.01%.

    /// @notice Multisig to receive BELUGA buybacks.
    address public belugaMultisig;

    /// @notice Token to inject into the profitshare pool.
    address public profitshareRewardToken;
    
    /// @notice Pool to inject profitshare rewards into.
    address public profitsharePool;

    /// @notice Needed for tokens with transfer fees.
    mapping(address => bool) public transferFeeTokens;

    /// @notice Route for token conversion.
    mapping(address => mapping(address => address[])) public tokenConversionRoute;

    /// @notice Router to use for token conversion.
    mapping(address => mapping(address => address)) public tokenConversionRouter;

    /// @notice If a route uses more than one router, this is needed.
    mapping(address => mapping(address => address[])) public tokenConversionRouters;

    /// @notice Allows for management through the multisig.
    modifier onlyGovernanceOrMultisig {
        require(
            msg.sender == governance() || 
            msg.sender == belugaMultisig,
            "FeeRewardForwarder: Caller is not Governance or Beluga Multisig"
        );
        _;
    }

    constructor(
        address _store,
        address _BELUGA,
        address _belugaMultisig,
        address _profitshareReward,
        address _profitshareRewardPool
    ) Governable(_store) {
        BELUGA = _BELUGA;
        belugaBuybackNumerator = 1000; // Start off with 10% buyback.
        belugaMultisig = _belugaMultisig;
        profitshareRewardToken = _profitshareReward;
        profitsharePool = _profitshareRewardPool;

        // Predefined routes.
        address psReward = profitshareRewardToken;

        address gfi = address(0x874e178A2f3f3F9d34db862453Cd756E7eAb0381);
        address pyq = address(0x5a3064CbDCCF428ae907796cF6aD5a664CD7F3d8);
        address dino = address(0xAa9654BECca45B5BDFA5ac646c939C62b527D394);

        address usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

        address gravityRouter = address(0x57dE98135e8287F163c59cA4fF45f1341b680248);
        address sushiRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

        transferFeeTokens[pyq] = true;

        tokenConversionRoute[gfi][psReward] = [gfi, psReward];
        tokenConversionRoute[pyq][psReward] = [pyq, usdc, psReward];
        tokenConversionRoute[dino][psReward] = [dino, usdc, psReward];

        tokenConversionRouter[gfi][psReward] = gravityRouter;
        tokenConversionRouter[pyq][psReward] = sushiRouter;
        tokenConversionRouter[dino][psReward] = sushiRouter;
    }

    /// @notice Converts `_tokenFrom` into Beluga's target tokens.
    /// @param _tokenFrom Token to convert from.
    /// @param _fee Performance fees to convert into the target tokens.
    function performTokenConversion(address _tokenFrom, uint256 _fee) external {
        address psReward = profitshareRewardToken;
        address psPool = profitsharePool;
        // If the token is the profitshare reward token, inject into the pool.
        if(_tokenFrom == psReward) {
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, psPool, _fee);
            IRewardPool(psPool).notifyRewardAmount(_fee);
            return;
        }
        // Else, the token needs to be converted to the PS reward token.
        address[] memory targetRouteToReward = tokenConversionRoute[_tokenFrom][psReward]; // Save to memory to save gas.
        if(targetRouteToReward.length > 1) {
            // Perform conversion if a route to BELUGA from `_tokenFrom` is specified.
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, address(this), _fee);
            uint256 feeAfter = IERC20(_tokenFrom).balanceOf(address(this)); // In-case the token has transfer fees.
            address targetRouter = tokenConversionRouter[_tokenFrom][psReward];
            if(targetRouter != address(0)) {
                // We can safely perform a regular swap.
                uint256 endAmount = _performSwap(targetRouter, _tokenFrom, feeAfter, targetRouteToReward);
                IERC20(psReward).safeTransfer(psPool, endAmount);
                IRewardPool(psPool).notifyRewardAmount(endAmount);
            } else {
                // Else, we need to perform a cross-dex liquidation.
                address[] memory targetRouters = tokenConversionRouters[_tokenFrom][psReward];
                uint256 endAmount = _performMultidexSwap(targetRouters, _tokenFrom, feeAfter, targetRouteToReward);
                IERC20(psReward).safeTransfer(psPool, endAmount);
                IRewardPool(psPool).notifyRewardAmount(endAmount);
            }
        } else {
            // Else, leave the funds in the Controller.
            return;
        }
    }

    /// @notice Salvages any tokens that are stuck in the contract.
    /// @param _token Token to salvage from the contract.
    /// @param _amount Amount to salvage from the contract.
    function salvage(address _token, uint256 _amount) external onlyGovernanceOrMultisig {
        IERC20(_token).safeTransfer(belugaMultisig, _amount);
    }

    /// @notice Sets the percentage of fees that are to be used for BELUGA buybacks
    /// @param _belugaBuybackNumerator Percentage to use for buybacks.
    function setBelugaBuybackNumerator(uint256 _belugaBuybackNumerator) public onlyGovernanceOrMultisig {
        require(_belugaBuybackNumerator <= belugaBuybackDenominator, "FeeRewardForwarder: New numerator is higher than the denominator");
        belugaBuybackNumerator = _belugaBuybackNumerator;
    }

    /// @notice Sets the precision for BELUGA buybacks.
    /// @param _belugaBuybackDenominator Precision used for buyback calculations.
    function setBelugaBuybackDenominator(uint256 _belugaBuybackDenominator) public onlyGovernanceOrMultisig {
        require(_belugaBuybackDenominator >= belugaBuybackNumerator, "FeeRewardForwarder: New denominator is lower than the numerator");
        belugaBuybackDenominator = _belugaBuybackDenominator;
    }

    /// @notice Sets the address of the Beluga Multisig.
    /// @param _belugaMultisig New multisig address.
    function setBelugaMultisig(address _belugaMultisig) public onlyGovernance {
        belugaMultisig = _belugaMultisig;
    }

    /// @notice Adds a token to the list of transfer fee tokens.
    /// @param _transferFeeToken Token to add to the list.
    function addTransferFeeToken(address _transferFeeToken) public onlyGovernanceOrMultisig {
        transferFeeTokens[_transferFeeToken] = true;
    }

    /// @notice Removes a token from the transfer fee tokens list.
    /// @param _transferFeeToken Address of the transfer fee token.
    function removeTransferFeeToken(address _transferFeeToken) public onlyGovernanceOrMultisig {
        transferFeeTokens[_transferFeeToken] = false;
    }

    /// @notice Sets the route for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _route Route used for conversion.
    function setTokenConversionRoute(
        address _tokenFrom,
        address _tokenTo,
        address[] memory _route
    ) public onlyGovernance {
        tokenConversionRoute[_tokenFrom][_tokenTo] = _route;
    }

    /// @notice Sets the router for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _router Target router for the swap.
    function setTokenConversionRouter(
        address _tokenFrom,
        address _tokenTo,
        address _router
    ) public onlyGovernance {
        tokenConversionRouter[_tokenFrom][_tokenTo] = _router;
    }

    /// @notice Sets the routers used for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _routers Target routers for the swap.
    function setTokenConversionRouters(
        address _tokenFrom,
        address _tokenTo,
        address[] memory _routers
    ) public onlyGovernance {
        tokenConversionRouters[_tokenFrom][_tokenTo] = _routers;
    }

    function _performSwap(
        address _router,
        address _tokenFrom,
        uint256 _amount,
        address[] memory _route
    ) internal returns (uint256 endAmount) {
        IERC20(_tokenFrom).safeApprove(_router, 0);
        IERC20(_tokenFrom).safeApprove(_router, _amount);
        if(!transferFeeTokens[_tokenFrom]) {
            uint256[] memory amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(_amount, 0, _route, address(this), (block.timestamp + 600));
            endAmount = amounts[amounts.length - 1];
        } else {
            IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, _route, address(this), (block.timestamp + 600));
            endAmount = IERC20(_route[_route.length - 1]).balanceOf(address(this));
        }
    }

    function _performMultidexSwap(
        address[] memory _routers,
        address _tokenFrom,
        uint256 _amount,
        address[] memory _route
    ) internal returns (uint256 endAmount) {
        for(uint256 i = 0; i < _routers.length; i++) {
            // Create swap route.
            address swapRouter = _routers[i];
            address[] memory conversionRoute = new address[](2);
            conversionRoute[0] = _route[i];
            conversionRoute[1] = _route[i+1];

            // Fetch balances.
            address routeStart = conversionRoute[0];
            uint256 routeStartBalance;
            if(routeStart == _tokenFrom) {
                routeStartBalance = _amount;
            } else {
                routeStartBalance = IERC20(routeStart).balanceOf(address(this));
            }
            
            // Perform swap.
            if(conversionRoute[1] != _route[_route.length - 1]) {
                _performSwap(swapRouter, routeStart, routeStartBalance, conversionRoute);
            } else {
                endAmount = _performSwap(swapRouter, routeStart, routeStartBalance, conversionRoute);
            }
        }
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 {
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRewardPool {
    function rewardToken() external view returns (address);
    function lpToken() external view returns (address);
    function duration() external view returns (uint256);

    function periodFinish() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);

    function stake(uint256 amountWei) external;

    // `balanceOf` would give the amount staked. 
    // As this is 1 to 1, this is also the holder's share
    function balanceOf(address holder) external view returns (uint256);
    // Total shares & total lpTokens staked
    function totalSupply() external view returns(uint256);

    function withdraw(uint256 amountWei) external;
    function exit() external;

    // Get claimed rewards
    function earned(address holder) external view returns (uint256);

    // Claim rewards
    function getReward() external;

    // Notifies rewards to the pool
    function notifyRewardAmount(uint256 _amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 */

contract Governable {

  Storage public store;

  constructor(address _store) {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 150
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}