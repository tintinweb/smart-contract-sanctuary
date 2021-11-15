pragma solidity 0.8.0;



import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IPancakeRouter02.sol";

/**
 * @notice BuyBack contract:
 *   Swaps want token to reward token and burns them.
 */
contract BuyBack {
    using SafeERC20 for IERC20;

    address[] private _path;

    /**
     * @notice Function to buy and burn Gym reward token
     * @param _wantAdd: Want token address
     * @param _wantAmt: Amount of want token for swap
     * @param _rewardToken: Address of reward token
     */
    function buyAndBurnToken(
        address _wantAdd,
        uint256 _wantAmt,
        address _rewardToken
    ) public returns (uint256) {
        if (_wantAdd != _rewardToken) {
            uint256 burnAmt = IERC20(_rewardToken).balanceOf(address(this));
            IERC20(_wantAdd).safeIncreaseAllowance(
                0x367633909278A3C91f4cB130D8e56382F00D1071,
                _wantAmt
            );
            _path = [_wantAdd, _rewardToken];

            IPancakeRouter02(0x367633909278A3C91f4cB130D8e56382F00D1071)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _wantAmt,
                0,
                _path,
                address(this),
                block.timestamp + 60
            );

            burnAmt = IERC20(_rewardToken).balanceOf(address(this)) - burnAmt;
            IERC20Burnable(_rewardToken).burn(uint96(burnAmt));

            return burnAmt;
        }

        IERC20Burnable(_rewardToken).burn(uint96(_wantAmt));

        return _wantAmt;
    }
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

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint96 _amount) external;

    function burnFrom(address _account, uint96 _amount) external;
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

pragma solidity 0.8.0;



import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IPancakeRouter01.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IAlpacaToken.sol";
import "./interfaces/IVaultConfig.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWETH.sol";


interface IFarm {
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 bonusDebt,
            uint256 fundedBy
        );
}

interface ITreasury {
    function notifyExternalReward(uint256 _amount) external;
}

interface IFairLaunch {
    function pendingAlpaca(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function harvest(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
contract GymVaultsStrategyAlpaca is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// This vault is purely for staking
    bool public isAutoComp; 
    bool public strategyStopped = false;
    bool public checkForUnlockReward = false;

    /// address of vault.
    address public vaultContractAddress; 
    /// address of farm
    address public farmContractAddress; 
    /// pid of pool in farmContractAddress
    uint256 public pid; 
    /// address of want token contract
    address public wantAddress;
    /// address of earn token contract
    address public earnedAddress;
    /// PancakeSwap: Router address
    address public uniRouterAddress =
        address(0x367633909278A3C91f4cB130D8e56382F00D1071); 
    /// WBNB address
    address public constant wbnbAddress =
        address(0xDfb1211E2694193df5765d54350e1145FD2404A1);
    /// BUSD address
    address public constant busdAddress =
        address(0x0266693F9Df932aD7dA8a9b44C2129Ce8a87E81f);

    address public operator;
    address public strategist;
    /// allow public to call earn() function
    bool public notPublic = false; 

    uint256 public lastEarnBlock = 0;
    uint256 public wantLockedTotal = 0;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 0;
    /// 100 = 1%
    uint256 public constant controllerFeeMax =
        10000; 
    uint256 public constant controllerFeeUL =
        300;
    /// 0% entrance fee (goes to pool + prevents front-running)
    uint256 public entranceFeeFactor =
        10000; 
    /// 100 = 1%
    uint256 public constant entranceFeeFactorMax =
        10000; 
    /// 0.5% is the max entrance fee settable. LL = lowerlimit
    uint256 public constant entranceFeeFactorLL =
        9950; 

    address[] public earnedToWantPath;
    address[] public earnedToBusdPath;
    address[] public wantToEarnedPath;

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Farm(uint256 amount);
    event Compound(
        address token0Address,
        uint256 token0Amt,
        address token1Address,
        uint256 token1Amt
    );
    event Earned(address earnedAddress, uint256 earnedAmt);
    event BuyBack(
        address earnedAddress,
        address buyBackToken,
        uint256 earnedAmt,
        uint256 buyBackAmt,
        address receiver
    );
    event DistributeFee(address earnedAddress, uint256 fee, address receiver);
    event ConvertDustToEarned(
        address tokenAddress,
        address earnedAddress,
        uint256 tokenAmt
    );
    event InCaseTokensGetStuck(
        address tokenAddress,
        uint256 tokenAmt,
        address receiver
    );
    event ExecuteTransaction(
        address indexed target,
        uint256 value,
        string signature,
        bytes data
    );

    // _controller:  BvaultsBank
    // _buyBackToken1Info[]: buyBackToken1, buyBackAddress1, buyBackToken1MidRouteAddress
    // _buyBackToken2Info[]: buyBackToken2, buyBackAddress2, buyBackToken2MidRouteAddress
    // _token0Info[]: token0Address, token0MidRouteAddress
    // _token1Info[]: token1Address, token1MidRouteAddress
    constructor(
        address _controller,
        bool _isAutoComp,
        address _vaultContractAddress,
        address _farmContractAddress,
        uint256 _pid,
        address _wantAddress,
        address _earnedAddress,
        address _uniRouterAddress
    ) public // address[] memory _token0Info,
    // address[] memory _token1Info
    {
        operator = msg.sender;
        strategist = msg.sender;
        // to call earn if public not allowed

        isAutoComp = _isAutoComp;
        wantAddress = _wantAddress;

        if (_uniRouterAddress != address(0))
            uniRouterAddress = _uniRouterAddress;

        if (isAutoComp) {
            vaultContractAddress = _vaultContractAddress;
            farmContractAddress = _farmContractAddress;
            pid = _pid;
            earnedAddress = _earnedAddress;
            uniRouterAddress = _uniRouterAddress;

            earnedToBusdPath = [earnedAddress, busdAddress];
            earnedToWantPath = [earnedAddress, _wantAddress];
            wantToEarnedPath = [_wantAddress, earnedAddress];
        }

        transferOwnership(_controller);
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyOperator() {
        require(
            operator == msg.sender,
            "GymVaultsStrategyAlpaca: caller is not the operator"
        );
        _;
    }

    modifier onlyStrategist() {
        require(
            strategist == msg.sender || operator == msg.sender,
            "GymVaultsStrategyAlpaca: caller is not the strategist"
        );
        _;
    }

    modifier strategyRunning() {
        require(
            !strategyStopped,
            "GymVaultsStrategyAlpaca: strategy is not running"
        );
        _;
    }

    /**
     * @notice  Function checks if user Autorised or not
     * @param _account Users address
    */
    function isAuthorised(address _account) public view returns (bool) {
        return (_account == operator) || (msg.sender == strategist);
    }

    /**
     * @notice  Adds deposit
     * @param _wantAmt Amount of want tokens that will be added to pool
    */    
    function deposit(address, uint256 _wantAmt)
        public
        onlyOwner
        whenNotPaused
        strategyRunning
        returns (uint256)
    {
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );
        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0) {
            sharesAdded =
                (_wantAmt * sharesTotal * entranceFeeFactor) /
                wantLockedTotal /
                entranceFeeFactorMax;
        }
        sharesTotal = sharesTotal + sharesAdded;

        if (isAutoComp) {
            _farm();
        } else {
            wantLockedTotal = wantLockedTotal + _wantAmt;
        }

        emit Deposit(_wantAmt);

        return sharesAdded;
    }

    function farm() public nonReentrant strategyRunning {
        _farm();
    }

    /**
     * @notice  Adds assets in vault
    */  
    function _farm() internal {
        // add to vault to get ibToken
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal + wantAmt;
        IERC20(wantAddress).safeIncreaseAllowance(
            vaultContractAddress,
            wantAmt
        );
        IVault(vaultContractAddress).deposit(wantAmt);
        // add ibToken to farm contract
        uint256 ibWantAmt = IERC20(vaultContractAddress).balanceOf(
            address(this)
        );
        IERC20(vaultContractAddress).safeIncreaseAllowance(
            farmContractAddress,
            ibWantAmt
        );
        IFairLaunch(farmContractAddress).deposit(address(this), pid, ibWantAmt);
        emit Farm(wantAmt);
    }
    
    /**
     * @notice  Function to withdraw assets
     * @param _wantAmt Amount of want tokens that will be withdrawn
    */ 
    function withdraw(address, uint256 _wantAmt)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "GymVaultsStrategyAlpaca: !_wantAmt");

        if (isAutoComp && !strategyStopped) {
            IFairLaunch(farmContractAddress).withdraw(
                address(this),
                pid,
                _wantAmt
            );
            IVault(vaultContractAddress).withdraw(_wantAmt);
            if (
                IVault(0xf9d32C5E10Dd51511894b360e6bD39D7573450F9).token() ==
                IVaultConfig(0x037F4b0d074B83d075EC3B955F69BaB9977bdb05)
                .getWrappedNativeAddr()
                // address(this).balance > 0
            ) {
                IWETH(0xDfb1211E2694193df5765d54350e1145FD2404A1).deposit{
                    value: _wantAmt
                }();
            }
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        uint256 sharesRemoved = (_wantAmt * sharesTotal) / wantLockedTotal;
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal - sharesRemoved;
        wantLockedTotal = wantLockedTotal - _wantAmt;

        IERC20(wantAddress).safeTransfer(address(msg.sender), _wantAmt);
        emit Withdraw(_wantAmt);

        return sharesRemoved;
    }
 
    /**
     *  1. Harvest farm tokens
     *  2. Converts farm tokens into want tokens
     *  3. Deposits want tokens
    */ 
    function earn() public whenNotPaused {
        require(isAutoComp, "GymVaultsStrategyAlpaca: !isAutoComp");
        require(
            !notPublic || isAuthorised(msg.sender),
            "GymVaultsStrategyAlpaca: !authorised"
        );

        // Harvest farm tokens
        IFairLaunch(farmContractAddress).harvest(pid);
        // Check if there is any unlocked amount
        if (checkForUnlockReward) {
            if (
                IAlpacaToken(earnedAddress).canUnlockAmount(address(this)) > 0
            ) {
                IAlpacaToken(earnedAddress).unlock();
            }
        }

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        emit Earned(earnedAddress, earnedAmt);

        uint256 _distributeFee = distributeFees(earnedAmt);

        earnedAmt = earnedAmt - _distributeFee;

        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            earnedAmt
        );

        if (earnedAddress != wantAddress) {
            // Swap half earned to token0
            IPancakeRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                earnedAmt,
                0,
                earnedToWantPath,
                address(this),
                block.timestamp + 60
            );
        }

        // Get want tokens, ie. add liquidity
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (wantAmt > 0) {
            emit Compound(wantAddress, wantAmt, address(0), 0);
        }

        lastEarnBlock = block.number;

        _farm();
    }
 
    /**
     * @notice  Function to distribute Fees 
     * @param _earnedAmt Amount of earned tokens that will be sent to operator ass fee
    */ 
    function distributeFees(uint256 _earnedAmt)
        internal
        returns (uint256 _fee)
    {
        if (_earnedAmt > 0) {
            // Performance fee
            if (controllerFee > 0) {
                _fee = (_earnedAmt * controllerFee) / controllerFeeMax;
                IERC20(earnedAddress).safeTransfer(operator, _fee);
                emit DistributeFee(earnedAddress, _fee, operator);
            }
        }
    }

    /**
     * @notice  Converts dust tokens into earned tokens, which will be reinvested on the next earn(). 
    */ 
    function convertDustToEarned() public whenNotPaused {
        require(isAutoComp, "GymVaultsStrategyAlpaca: !isAutoComp");

        // Converts token0 dust (if any) to earned tokens
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (wantAddress != earnedAddress && wantAmt > 0) {
            IERC20(wantAddress).safeIncreaseAllowance(
                uniRouterAddress,
                wantAmt
            );

            // Swap all dust tokens to earned tokens
            IPancakeRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                wantAmt,
                0,
                wantToEarnedPath,
                address(this),
                block.timestamp + 60
            );
            emit ConvertDustToEarned(wantAddress, earnedAddress, wantAmt);
        }
    }

    function uniExchangeRate(uint256 _tokenAmount, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amounts = IPancakeRouter02(uniRouterAddress)
        .getAmountsOut(_tokenAmount, _path);
        return amounts[amounts.length - 1];
    }

    function pendingHarvest() public view returns (uint256) {
        uint256 _earnedBal = IERC20(earnedAddress).balanceOf(address(this));
        return
            IFairLaunch(farmContractAddress).pendingAlpaca(pid, address(this)) +
            _earnedBal;
    }

    function pendingHarvestDollarValue() public view returns (uint256) {
        uint256 _pending = pendingHarvest();
        return
            (_pending == 0) ? 0 : uniExchangeRate(_pending, earnedToBusdPath);
    }

    function balanceInPool() public view returns (uint256) {
        (uint256 amount, , , ) = IFarm(farmContractAddress).userInfo(
            pid,
            address(this)
        );
        return amount;
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setStrategist(address _strategist) external onlyOperator {
        strategist = _strategist;
    }

    /**
     * @notice  Function to set entrance fee
     * @param _entranceFeeFactor 100 = 1%
    */ 
    function setEntranceFeeFactor(uint256 _entranceFeeFactor)
        external
        onlyOperator
    {
        require(
            _entranceFeeFactor > entranceFeeFactorLL,
            "GymVaultsStrategyAlpaca: !safe - too low"
        );
        require(
            _entranceFeeFactor <= entranceFeeFactorMax,
            "GymVaultsStrategyAlpaca: !safe - too high"
        );
        entranceFeeFactor = _entranceFeeFactor;
    }

    /**
     * @notice  Function to set controller fee
     * @param _controllerFee 100 = 1%
    */
    function setControllerFee(uint256 _controllerFee) external onlyOperator {
        require(
            _controllerFee <= controllerFeeUL,
            "GymVaultsStrategyAlpaca: too high"
        );
        controllerFee = _controllerFee;
    }

    function setNotPublic(bool _notPublic) external onlyOperator {
        notPublic = _notPublic;
    }

    function setCheckForUnlockReward(bool _checkForUnlockReward)
        external
        onlyOperator
    {
        checkForUnlockReward = _checkForUnlockReward;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
        emit InCaseTokensGetStuck(_token, _amount, _to);
    }

    function emergencyWithraw() external onlyOperator {
        (uint256 _wantAmt, , , ) = IFarm(farmContractAddress).userInfo(
            pid,
            address(this)
        );
        IFairLaunch(farmContractAddress).withdraw(address(this), pid, _wantAmt);
        IVault(vaultContractAddress).withdraw(_wantAmt);
        strategyStopped = true;
    }

    function resumeStrategy() external onlyOperator {
        strategyStopped = false;
        farm();
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IAlpacaToken {
    function canUnlockAmount(address _account) external view returns (uint256);
    function unlock() external;
}

pragma solidity 0.8.0;



interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the address of fair launch contract.
  function getFairLaunchAddr() external view returns (address);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address caller) external returns (bool);

  /// @dev Return whether the given address is a worker.
  function isWorker(address worker) external view returns (bool);

  /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  function acceptDebt(address worker) external view returns (bool);

  /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function workFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function killFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the portion of reward that will be transferred to treasury account after successfully killing a position.
  function getKillTreasuryBps() external view returns (uint256);

  /// @dev Return the address of treasury account
  function getTreasuryAddr() external view returns (address);
}

pragma solidity 0.8.0;



interface IVault {

  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;

  /// @dev Request funds from user through Vault
  function requestFunds(address targetedToken, uint amount) external;

  function token() external view returns (address);
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IBuyBack.sol";
import "./interfaces/IFairLaunch.sol";
import "./interfaces/IVault.sol";
import "./Relationship.sol";


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice GymVaultsBank contract:
 * - Users can:
 *   # Deposit token
 *   # Deposit BNB
 *   # Withdraw assets
 */

contract GymVaultsBank is ReentrancyGuard, Ownable, Relationship {
    using SafeERC20 for IERC20;

    /**
        * @notice Info of each user
        * @param shares: How many LP tokens the user has provided
        * @param rewardDebt: Reward debt. See explanation below
        * @dev Any point in time, the amount of UTACOs entitled to a user but is pending to be distributed is:
        *   amount = user.shares / sharesTotal * wantLockedTotal
        *   pending reward = (amount * pool.accRewardPerShare) - user.rewardDebt
        *   Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        *   1. The pool's `accRewardPerShare` (and `lastStakeTime`) gets updated.
        *   2. User receives the pending reward sent to his/her address.
        *   3. User's `amount` gets updated.
        *   4. User's `rewardDebt` gets updated.
    */
    struct UserInfo {
        uint256 shares;
        uint256 rewardDebt;
        uint256 lastStakeTime;
    }
    /**
     * @notice Info of each pool
     * @param want: Address of want token contract
     * @param allocPoint: How many allocation points assigned to this pool. GYM to distribute per block
     * @param lastRewardBlock: Last block number that reward distribution occurs
     * @param accUTacoPerShare: Accumulated rewardPool per share, times 1e18
     * @param strategy: Address of strategy contract
     */
    struct PoolInfo {
        IERC20 want;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        address strategy;
    }

      /**
     * @notice Info of each rewartPool
     * @param rewardToken: Address of reward token contract
     * @param rewardPerBlock: How many reward tokens will user get per block
     * @param totalPaidRewards: Total amount of reward tokens was paid
     */

    struct RewardPoolInfo {
        address rewardToken;
        uint256 rewardPerBlock;
        uint256 totalPaidRewards;
    }

    /// Startblock number
    uint256 public startBlock; 
    
    /// Info of each pool.
    PoolInfo[] public poolInfo;
    /// Info of each user that stakes want tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; 
    /// Info of reward pool
    RewardPoolInfo public rewardPoolInfo;
    /// Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint ; 
    /// Percent of amount that will be sent to relationship contract
    uint256 public constant RELATIONSHIP_REWARD = 45;
    /// Percent of amount that will be sent to vault contract
    uint256 public constant VAULTS_SAVING = 45;
    /// Percent of amount that will be sent to buyBack contract
    uint256 public constant BUY_AND_BURN_GYM = 10;

    /// 100 = 1%
    uint256 public withdrawFeeUl = 10000;
    uint256 public withdrawFee;
    /// PancakeSwap: Router
    address public constant routerAddress = 0x367633909278A3C91f4cB130D8e56382F00D1071; 
    ///buy and burn contract address
    address public buyBack; 
    /// Treasury address where will be sent all unused assets
    address public treasuryAddress;
    
    address[] private alpacaToWBNB;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(
        address indexed token,
        address indexed user,
        uint256 amount
    );
    
    constructor(
        uint256 _startBlock,
        address _gym,
        uint256 _gymRewardRate
    ){
        require(block.number < _startBlock, "GymVaultsBank: Late");
        require(RELATIONSHIP_REWARD + VAULTS_SAVING + BUY_AND_BURN_GYM == 100, "GymVaultsBank: Percentage error");
        startBlock = _startBlock;
        totalAllocPoint = 0;
        // add(IERC20($(GYM_VAULTS_BANK_CORE_POOL_WANT_ADDRESS)), $(GYM_VAULTS_BANK_CORE_POOL_ALLOC_POINT), $(GYM_VAULTS_BANK_CORE_POOL_WITH_UPDATE), $(GYM_VAULTS_BANK_CORE_POOL_STRATEGY_ADDRESS));
        rewardPoolInfo = RewardPoolInfo({
            rewardToken: _gym, 
            rewardPerBlock: _gymRewardRate, 
            totalPaidRewards: 0
        });
        alpacaToWBNB = [0x354b3a11D5Ea2DA89405173977E271F58bE2897D, 0xDfb1211E2694193df5765d54350e1145FD2404A1];
        emit Initialized(msg.sender, block.number);
    }
    receive() external payable {}
    fallback() external payable {}
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Function to set buyBack address
     * @param _buyBack: Address of BuyBack contract
     */
    function setBuyBackAddress(address _buyBack) external onlyOwner{
        buyBack = _buyBack;
    }

    /**
     * @notice Function to Add pool
     * @param _want: Address of want token contract
     * @param _allocPoint: AllocPoint for new pool
     * @param _withUpdate: If true will call massUpdatePools function
     * @param _strategy: Address of Strategy contract
     */
    function add(
        IERC20 _want,
        uint256 _allocPoint,
        bool _withUpdate,
        address _strategy
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
                PoolInfo({
                    want: _want,
                    allocPoint: _allocPoint,
                    lastRewardBlock: lastRewardBlock,
                    accRewardPerShare: 0,
                    strategy: _strategy
                })
            );
    }

    /**
     * @notice Update the given pool's reward allocation point. Can only be called by the owner
     * @param _pid: Pool id that will be updated
     * @param _allocPoint: New allocPoint for pool
     */
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        massUpdatePools();
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @notice Update the given pool's strategy. Can only be called by the owner
     * @param _pid: Pool id that will be updated
     * @param _strategy: New strategy contract address for pool
     */
    function resetStrategy(uint256 _pid, address _strategy)
        external
        onlyOwner
    {
        PoolInfo storage pool = poolInfo[_pid];
        require(
        IERC20(pool.want).balanceOf(poolInfo[_pid].strategy) == 0 ||
                pool.accRewardPerShare == 0,
            "GymVaultsBank: Strategy not empty"
        );
        poolInfo[_pid].strategy = _strategy;
    }

    /**
     * @notice Migrates all assets to new strategy. Can only be called by the owner
     * @param _pid: Pool id that will be updated
     * @param _newStrategy: New strategy contract address for pool
     */
    function migrateStrategy(uint256 _pid, address _newStrategy)
        external
        onlyOwner
    {
        require(
            IStrategy(_newStrategy).wantLockedTotal() == 0 &&
                IStrategy(_newStrategy).sharesTotal() == 0,
            "GymVaultsBank: New strategy not empty"
        );
        PoolInfo storage pool = poolInfo[_pid];
        address _oldStrategy = pool.strategy;
        uint256 _oldSharesTotal = IStrategy(_oldStrategy).sharesTotal();
        uint256 _oldWantAmt = IStrategy(_oldStrategy).wantLockedTotal();
        IStrategy(_oldStrategy).withdraw(address(this), _oldWantAmt);
        pool.want.transfer(_newStrategy, _oldWantAmt);
        IStrategy(_newStrategy).migrateFrom(
            _oldStrategy,
            _oldWantAmt,
            _oldSharesTotal
        );
        pool.strategy = _newStrategy;
    }

    /**
     * @notice Updates amount of reward tokens  per block that user will get. Can only be called by the owner
     * @param _rewardPerBlock: Pool id that will be updated
     */
    function updateRewardPerBlock( uint256 _rewardPerBlock)
        external
        nonReentrant
        onlyOwner
    {
        massUpdatePools();
        rewardPoolInfo.rewardPerBlock = _rewardPerBlock;
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _pid: Pool id where user has assets
     * @param _user: Users address
     */
    function pendingReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 sharesTotal = IStrategy(pool.strategy).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 _multiplier = block.number - pool.lastRewardBlock;
            uint256 _rewardPerBlock = rewardPoolInfo.rewardPerBlock;
            uint256 _reward =
                (_multiplier * _rewardPerBlock * pool.allocPoint) /
                    totalAllocPoint;
            _accRewardPerShare =
                _accRewardPerShare +
                ((_reward * 1e18) / sharesTotal);
        }
        return
            (user.shares * _accRewardPerShare) /
            1e18 -
            user.rewardDebt;
    }

    /**
     * @notice View function to see staked Want tokens on frontend.
     * @param _pid: Pool id where user has assets
     * @param _user: Users address
     */
    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 sharesTotal = IStrategy(pool.strategy).sharesTotal();
        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strategy).wantLockedTotal();
        if (sharesTotal == 0) {
            return 0;
        }
        return (user.shares * wantLockedTotal) / sharesTotal;
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid: Pool id that will be updated
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = IStrategy(pool.strategy).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardBlock;
        if (multiplier <= 0) {
            return;
        }
        uint256 _rewardPerBlock = rewardPoolInfo.rewardPerBlock;
        uint256 _reward =
            (multiplier * _rewardPerBlock * pool.allocPoint) /
                totalAllocPoint;
        pool.accRewardPerShare =
            pool.accRewardPerShare +
            ((_reward * 1e18) / sharesTotal);
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Calculates amount of reward user will get.
     * @param _pid: Pool id 
     */
    function _getReward(uint256 _pid) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _user = userInfo[_pid][msg.sender];
        uint256 _pending =
            (_user.shares * _pool.accRewardPerShare) /
                (1e18) -
                (_user.rewardDebt);
        if (_pending > 0) {
            address _rewardToken = rewardPoolInfo.rewardToken;
            safeRewardTransfer(_rewardToken, msg.sender, _pending);
            rewardPoolInfo.totalPaidRewards =
                rewardPoolInfo.totalPaidRewards +
                (_pending);
            emit RewardPaid(
                _rewardToken,
                msg.sender,
                _pending
            );
        }
    }

    /**
     * @notice Deposit in given pool
     * @param _pid: Pool id 
     * @param _wantAmt: Amount of want token that user wants to deposit 
     * @param _referrer: Referrer address  
     */
    function deposit(uint256 _pid, uint256 _wantAmt, address _referrer) external {
        addRelationship(msg.sender, _referrer);
        _deposit(_pid, _wantAmt, true);
    }

    /**
     * @notice Deposit in given pool
     * @param _pid: Pool id 
     * @param _wantAmt: Amount of want token that user wants to deposit 
     */
    function deposit(uint256 _pid, uint256 _wantAmt) external nonReentrant onlyOnRelationship {
        _deposit(_pid, _wantAmt, true);
    }

    /**
     * @notice Deposit BNB in core pool
     * @param _referrer: Referrer address  
     */
    function depositBNB( address _referrer) external payable{
        addRelationship(msg.sender, _referrer);
        depositBNB();
    }

    /**
     * @notice Deposit BNB in core pool
     */
    function depositBNB() public payable nonReentrant onlyOnRelationship{
        distributeRewards( msg.value * RELATIONSHIP_REWARD / 100, address(0), msg.sender, false, owner());
        IWETH(0xDfb1211E2694193df5765d54350e1145FD2404A1).deposit{value: (msg.value - msg.value * RELATIONSHIP_REWARD / 100)}();
        _deposit(0, msg.value, false);
    }

     /**
     * @notice Private deposit function 
     * @param _pid: Pool id 
     * @param _wantAmt: Amount of want token that user wants to deposit 
     * @param _isToken: If false` given asset is BNB
     */
    function _deposit(uint256 _pid, uint256 _wantAmt, bool _isToken) private {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.shares > 0) {
            _getReward(_pid);
        }
        if (_wantAmt > 0) {
            if(_isToken){
                pool.want.safeTransferFrom(
                    address(msg.sender),
                    address(this),
                    _wantAmt
                );
            distributeRewards(_wantAmt * RELATIONSHIP_REWARD / 100, address(pool.want), msg.sender, true, owner());
            }

            pool.want.safeTransfer(buyBack, _wantAmt * BUY_AND_BURN_GYM / 100);
            IBuyBack(buyBack).buyAndBurnToken(address(pool.want), _wantAmt * BUY_AND_BURN_GYM / 100, rewardPoolInfo.rewardToken);

            _wantAmt = _wantAmt * VAULTS_SAVING / 100;
            pool.want.safeIncreaseAllowance(pool.strategy, _wantAmt);
            uint256 sharesAdded =
                IStrategy(poolInfo[_pid].strategy).deposit(
                    msg.sender,
                    _wantAmt
                );

            user.shares = user.shares + sharesAdded;
            user.lastStakeTime = block.timestamp;
        }
        user.rewardDebt =
            (user.shares * (pool.accRewardPerShare)) /
            (1e18);
        emit Deposit(msg.sender, _pid, _wantAmt);
        if(_isToken)
        {
            pool.want.safeTransfer(treasuryAddress, pool.want.balanceOf(address(this)));
        }else{
            IWETH(0xDfb1211E2694193df5765d54350e1145FD2404A1).withdraw(IERC20(0xDfb1211E2694193df5765d54350e1145FD2404A1).balanceOf(address(this)));
            payable(treasuryAddress).transfer(address(this).balance);
        }
    }
    /**
     * @notice Withdraw user`s assets from pool 
     * @param _pid: Pool id 
     * @param _wantAmt: Amount of want token that user wants to withdraw 
     */
    function withdraw(uint256 _pid, uint256 _wantAmt) external nonReentrant {
        _withdraw(_pid, _wantAmt, true);
    }

    /**
     * @notice Withdraw user`s assets from core pool
     * @param _wantAmt: Amount of BNB that user wants to withdraw 
     */

    function withdrawBNB(uint256 _wantAmt) external nonReentrant {
        _withdraw(0, _wantAmt, false);
    }

     /**
     * @notice Private withdraw function 
     * @param _pid: Pool id 
     * @param _wantAmt: Amount of want token that user wants to withdraw 
     * @param _isToken: If false` given asset is BNB
     */
    function _withdraw(uint256 _pid, uint256 _wantAmt, bool _isToken) private { 
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strategy).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strategy).sharesTotal();

        require(user.shares > 0, "GymVaultsBank: user.shares is 0");
        require(sharesTotal > 0, "GymVaultsBank: sharesTotal is 0");

        _getReward(_pid);

        // Withdraw want tokens
        uint256 amount = (user.shares * (wantLockedTotal)) / (sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved =
                IStrategy(poolInfo[_pid].strategy).withdraw(
                    msg.sender,
                    _wantAmt
                );
            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares - (sharesRemoved);
            }
            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }

            if (_wantAmt > 0) {
                if(_isToken){
                    pool.want.safeTransfer(address(msg.sender), _wantAmt * withdrawFee / withdrawFeeUl);
                    pool.want.safeTransfer(treasuryAddress, pool.want.balanceOf(address(this)));

                }else{
                    IWETH(0xDfb1211E2694193df5765d54350e1145FD2404A1).withdraw(_wantAmt);
                    payable(msg.sender).transfer(_wantAmt * withdrawFee / withdrawFeeUl);
                    payable(treasuryAddress).transfer(address(this).balance);
                }
            }
        }
        user.rewardDebt =
            (user.shares * (pool.accRewardPerShare)) /
            (1e18);
        
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) external {
        _withdraw(_pid, type(uint256).max, true);
    }

    function withdrawAllBNB() external {
        _withdraw(0, type(uint256).max, false);
    }

     /**
     * @notice View function, returns amount of BNB that user will get 
     * @param _user Address of user
     */
    function getBNBAmount(address _user) public view returns (uint256){
        PoolInfo memory pool = poolInfo[0];
        UserInfo memory user = userInfo[0][_user];
        uint256 wantLockedTotal = IStrategy(pool.strategy).wantLockedTotal();
        uint256 pendingAlpacaContract = IFairLaunchV1(0xac2fefDaF83285EA016BE3f5f1fb039eb800F43D).pendingAlpaca(1, pool.strategy);
        uint256 totalToken = IVault(0xf9d32C5E10Dd51511894b360e6bD39D7573450F9).totalToken();
        uint256 totalSupply = IERC20(0xf9d32C5E10Dd51511894b360e6bD39D7573450F9).totalSupply();
        uint256[] memory alpacaToBNBAmount = IPancakeRouter02(routerAddress).getAmountsOut(pendingAlpacaContract, alpacaToWBNB);
        uint256 pendingBNBUser = user.shares * alpacaToBNBAmount[1] / wantLockedTotal;
        uint256 pendingIbBNB = pendingBNBUser * totalSupply / totalToken;

        uint256 userAmount = user.shares * IFairLaunchV1(0xac2fefDaF83285EA016BE3f5f1fb039eb800F43D).userInfo(1, pool.strategy).amount / wantLockedTotal;
        
        return totalToken * (userAmount + pendingIbBNB) / totalSupply;
    }

    /**
     * @notice  Safe transfer function for reward tokens 
     * @param _rewardToken Address of reward token contract
     * @param _to Address of reciever
     * @param _amount Amount of reward tokens to transfer
     */
    function safeRewardTransfer(
        address _rewardToken,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _bal = IERC20(_rewardToken).balanceOf(address(this));
        if (_amount > _bal) {
            IERC20(_rewardToken).transfer(_to, _bal);
        } else {
            IERC20(_rewardToken).transfer(_to, _amount);
        }
    }

    /**
     * @notice  Function to set Treasury address
     * @param _treasuryAddress Address of treasury address
    */
    function setTreasuryAddress(address _treasuryAddress)
        external
        nonReentrant
        onlyOwner
    {
        treasuryAddress = _treasuryAddress;
    } 

    /**
     * @notice  Function to set withdraw fee
     * @param _fee 100 = 1%
    */
    function setWithdrawFee(uint256 _fee) 
        external 
        nonReentrant
        onlyOwner
        {
            withdrawFee = _fee;
        }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IStrategy {
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    function wantAddress() external view returns (address);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    function earnedAddress() external view returns (address);

    function ratio0() external view returns (uint256);

    function ratio1() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);

    function migrateFrom(address _oldStrategy, uint256 _oldWantLockedTotal, uint256 _oldSharesTotal) external;

    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external;
}

pragma solidity 0.8.0;



interface IBuyBack {
    function buyAndBurnToken(
        address,
        uint256,
        address
    ) external returns (uint256);
}

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;




interface IFairLaunchV1 {
  // Data structure
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 bonusDebt;
    address fundedBy;
  }
  struct PoolInfo {
    address stakeToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accAlpacaPerShare;
    uint256 accAlpacaPerShareTilBonusEnd;
  }

  // Information query functions
  function alpacaPerBlock() external view returns (uint256);
  function totalAllocPoint() external view returns (uint256);
  function poolInfo(uint256 pid) external view returns (IFairLaunchV1.PoolInfo memory);
  function userInfo(uint256 pid, address user) external view returns (IFairLaunchV1.UserInfo memory);
  function poolLength() external view returns (uint256);

  // OnlyOwner functions
  function setAlpacaPerBlock(uint256 _alpacaPerBlock) external;
  function setBonus(uint256 _bonusMultiplier, uint256 _bonusEndBlock, uint256 _bonusLockUpBps) external;
  function manualMint(address _to, uint256 _amount) external;
  function addPool(uint256 _allocPoint, address _stakeToken, bool _withUpdate) external;
  function setPool(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

  // User's interaction functions
  function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);
  function updatePool(uint256 _pid) external;
  function deposit(address _for, uint256 _pid, uint256 _amount) external;
  function withdraw(address _for, uint256 _pid, uint256 _amount) external;
  function withdrawAll(address _for, uint256 _pid) external;
  function harvest(uint256 _pid) external;
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Relationship {
    mapping(address => address) public userToReferrer;
    uint8[10]
        private RELATIONSHIP_DIRECT_REFERRAL_BONUS;

    constructor() {
        RELATIONSHIP_DIRECT_REFERRAL_BONUS = [50, 20, 10, 4, 4, 3, 3, 2, 2, 2];
        userToReferrer[msg.sender] = msg.sender;
    }


    modifier onlyOnRelationship() {
        require(
            userToReferrer[msg.sender] != address(0),
            "Relationship::Don't have Relationship"
        );
        _;
    }


    /**
     * @notice  Function to add relationship 
     * @param _user Address of user
     * @param _referrer Address of referrer
    */ 
    function addRelationship(address _user, address _referrer) internal {
        require(
            _user != address(0),
            "Relationship::user address can't be zero"
        );
        require(
            _referrer != address(0),
            "Relationship::referrer address can't be zero"
        );
        require(
            userToReferrer[_referrer] != address(0),
            "Relationship::referrer with given address does't exist"
        );

        if (userToReferrer[_user] != address(0)) {
            return;
        }

        userToReferrer[_user] = _referrer;
    }

    /**
     * @notice  Function to distribute rewards to referrers
     * @param _wantAmt Amount of assets that will be distributed
     * @param _wantAddr Address of want token contract
     * @param _user Address of user
     * @param _isToken If false, will trasfer BNB
     * @param _owner Address of banks owner
    */
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user,
        bool _isToken,
        address _owner
    ) internal {
        uint8 _index;
        uint256 length = RELATIONSHIP_DIRECT_REFERRAL_BONUS.length;
        IERC20 token = IERC20(_wantAddr);
        while (
            _index < length &&
            userToReferrer[_user] != _owner
        ) {
            if (_isToken) {
                token.transfer(
                    userToReferrer[_user],
                    (_wantAmt * RELATIONSHIP_DIRECT_REFERRAL_BONUS[_index]) /
                        100
                );
            } else {
                payable(userToReferrer[_user]).transfer(
                    (_wantAmt * RELATIONSHIP_DIRECT_REFERRAL_BONUS[_index]) /
                        100
                );
            }
            _user = userToReferrer[_user];
            if (userToReferrer[_user] == address(0x0)) {
                break;
            }
            _index++;
        }
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPancakeswapFarm.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/ITreasury.sol";

contract GymVaultsStrategy is Ownable, ReentrancyGuard, Pausable {
    // Maximises yields in pancakeswap

    using SafeERC20 for IERC20;

    bool public isCAKEStaking; // only for staking CAKE using pancakeswap's native CAKE staking contract.
    bool public isAutoComp; // this vault is purely for staking. eg. WBNB-GYM staking vault.

    address public farmContractAddress; // address of farm
    uint256 public pid; // pid of pool in farmContractAddress
    address public wantAddress;
    address public token0Address;
    address public token1Address;
    address public earnedAddress;
    address public uniRouterAddress = address(0x367633909278A3C91f4cB130D8e56382F00D1071); // PancakeSwap: Router

    address public constant wbnbAddress = address(0xDfb1211E2694193df5765d54350e1145FD2404A1);
    address public constant busdAddress = address(0x0266693F9Df932aD7dA8a9b44C2129Ce8a87E81f);

    address public operator;
    address public strategist;
    bool public notPublic = false; // allow public to call earn() function

    uint256 public lastEarnBlock = 0;
    uint256 public wantLockedTotal = 0;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 0;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 300;

    uint256 public entranceFeeFactor = 10000; // 0% entrance fee (goes to pool + prevents front-running)
    uint256 public constant entranceFeeFactorMax = 10000; // 100 = 1%
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    address[] public earnedToBusdPath;

    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Farm(uint256 amount);
    event Compound(address token0Address, uint256 token0Amt, address token1Address, uint256 token1Amt);
    event Earned(address earnedAddress, uint256 earnedAmt);
    event DistributeFee(address earnedAddress, uint256 fee, address receiver);
    event ConvertDustToEarned(address tokenAddress, address earnedAddress, uint256 tokenAmt);
    event InCaseTokensGetStuck(address tokenAddress, uint256 tokenAmt, address receiver);

    // _controller:  BvaultsBank
    // _token0Info[]: token0Address, token0MidRouteAddress
    // _token1Info[]: token1Address, token1MidRouteAddress
    constructor(
        address _controller,
        bool _isCAKEStaking,
        bool _isAutoComp,
        address _farmContractAddress,
        uint256 _pid,
        address _uniRouterAddress,
        address _wantAddress,
        address _earnedAddress,
        address[] memory _token0Info,
        address[] memory _token1Info
    ) {
        operator = msg.sender;
        strategist = msg.sender; // to call earn if public not allowed

        isCAKEStaking = _isCAKEStaking;
        isAutoComp = _isAutoComp;
        wantAddress = _wantAddress;

        if (_uniRouterAddress != address(0)) uniRouterAddress = _uniRouterAddress;

        if (isAutoComp) {
            if (!isCAKEStaking) {
                token0Address = _token0Info[0];
                token1Address = _token1Info[0];
            }

            farmContractAddress = _farmContractAddress;
            pid = _pid;
            earnedAddress = _earnedAddress;

            uniRouterAddress = _uniRouterAddress;

            earnedToBusdPath = [earnedAddress, busdAddress];

            if (_token0Info[1] == address(0)) _token0Info[1] = wbnbAddress;
            earnedToToken0Path = [earnedAddress, _token0Info[1], token0Address];
            if (_token0Info[1] == token0Address) {
                earnedToToken0Path = [earnedAddress, _token0Info[1]];
            }

            if (_token1Info[1] == address(0)) _token1Info[1] = wbnbAddress;
            earnedToToken1Path = [earnedAddress, _token1Info[1], token1Address];
            if (_token1Info[1] == token1Address) {
                earnedToToken1Path = [earnedAddress, _token1Info[1]];
            }

            token0ToEarnedPath = [token0Address, _token0Info[1], earnedAddress];
            if (_token0Info[1] == token0Address) {
                token0ToEarnedPath = [_token0Info[1], earnedAddress];
            }

            token1ToEarnedPath = [token1Address, _token1Info[1], earnedAddress];
            if (_token1Info[1] == token1Address) {
                token1ToEarnedPath = [_token1Info[1], earnedAddress];
            }
        }

        transferOwnership(_controller);
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "GymVaultsStrategy: caller is not the operator");
        _;
    }

    modifier onlyStrategist() {
        require(strategist == msg.sender || operator == msg.sender, "GymVaultsStrategy: caller is not the strategist");
        _;
    }

    function isAuthorised(address _account) public view returns (bool) {
        return (_account == operator) || (msg.sender == strategist);
    }

    // Receives new deposits from user
    function deposit(address, uint256 _wantAmt) public onlyOwner whenNotPaused returns (uint256) {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0) {
            sharesAdded = _wantAmt * sharesTotal * entranceFeeFactor / wantLockedTotal / entranceFeeFactorMax;
        }
        sharesTotal = sharesTotal + sharesAdded;

        if (isAutoComp) {
            _farm();
        } else {
            wantLockedTotal = wantLockedTotal + _wantAmt;
        }

        emit Deposit(_wantAmt);

        return sharesAdded;
    }

    function farm() public nonReentrant {
        _farm();
    }

    function _farm() internal {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal + wantAmt;
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        if (isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).enterStaking(wantAmt); // Just for CAKE staking, we dont use deposit()
            lastEarnBlock = block.number;
        } else {
            IPancakeswapFarm(farmContractAddress).deposit(pid, wantAmt);
        }

        emit Farm(wantAmt);
    }

    function withdraw(address, uint256 _wantAmt) public onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "GymVaultsStrategy: !_wantAmt");

        if (isAutoComp) {
            if (isCAKEStaking) {
                IPancakeswapFarm(farmContractAddress).leaveStaking(_wantAmt); // Just for CAKE staking, we dont use withdraw()
            } else {
                IPancakeswapFarm(farmContractAddress).withdraw(pid, _wantAmt);
            }
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        uint256 sharesRemoved = _wantAmt * sharesTotal / wantLockedTotal;
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal - sharesRemoved;
        wantLockedTotal = wantLockedTotal - _wantAmt;

        IERC20(wantAddress).safeTransfer(address(msg.sender), _wantAmt);

        emit Withdraw(_wantAmt);

        return sharesRemoved;
    }

    // 1. Harvest farm tokens
    // 2. Converts farm tokens into want tokens
    // 3. Deposits want tokens

    function earn() public whenNotPaused {
        require(isAutoComp, "GymVaultsStrategy: !isAutoComp");
        require(!notPublic || isAuthorised(msg.sender), "GymVaultsStrategy: !authorised");

        // Harvest farm tokens
        if (isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).leaveStaking(0); // Just for CAKE staking, we dont use withdraw()
        } else {
            IPancakeswapFarm(farmContractAddress).withdraw(pid, 0);
        }

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        emit Earned(earnedAddress, earnedAmt);

        uint256 _distributeFee = distributeFees(earnedAmt);

        earnedAmt = earnedAmt - _distributeFee;

        if (isCAKEStaking) {
            lastEarnBlock = block.number;
            _farm();
            return;
        }

        IERC20(earnedAddress).safeIncreaseAllowance(uniRouterAddress, earnedAmt);

        if (earnedAddress != token0Address) {
            // Swap half earned to token0
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(earnedAmt / 2, 0, earnedToToken0Path, address(this), block.timestamp + 60);
        }

        if (earnedAddress != token1Address) {
            // Swap half earned to token1
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(earnedAmt / 2, 0, earnedToToken1Path, address(this), block.timestamp + 60);
        }
        // Get want tokens, ie. add liquidity
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));

        if (token0Amt > 0 && token1Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(uniRouterAddress, token0Amt);
            IERC20(token1Address).safeIncreaseAllowance(uniRouterAddress, token1Amt);
            IPancakeRouter02(uniRouterAddress).addLiquidity(token0Address, token1Address, token0Amt, token1Amt, 0, 0, address(this), block.timestamp + 60);
            emit Compound(token0Address, token0Amt, token1Address, token1Amt);
        }

        lastEarnBlock = block.number;

        _farm();
    }

    function distributeFees(uint256 _earnedAmt) internal returns (uint256 _fee) {
        if (_earnedAmt > 0) {
            // Performance fee
            if (controllerFee > 0) {
                _fee = _earnedAmt * controllerFee / controllerFeeMax;
                IERC20(earnedAddress).safeTransfer(operator, _fee);
                emit DistributeFee(earnedAddress, _fee, operator);
            }
        }
    }

    function convertDustToEarned() public whenNotPaused {
        require(isAutoComp, "GymVaultsStrategy: !isAutoComp");
        require(!isCAKEStaking, "GymVaultsStrategy: isCAKEStaking");

        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        if (token0Address != earnedAddress && token0Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(uniRouterAddress, token0Amt);

            // Swap all dust tokens to earned tokens
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(token0Amt, 0, token0ToEarnedPath, address(this), block.timestamp + 60);
            emit ConvertDustToEarned(token0Address, earnedAddress, token0Amt);
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token1Address != earnedAddress && token1Amt > 0) {
            IERC20(token1Address).safeIncreaseAllowance(uniRouterAddress, token1Amt);

            // Swap all dust tokens to earned tokens
            IPancakeRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(token1Amt, 0, token1ToEarnedPath, address(this), block.timestamp + 60);
            emit ConvertDustToEarned(token1Address, earnedAddress, token1Amt);
        }
    }

    function uniExchangeRate(uint256 _tokenAmount, address[] memory _path) public view returns (uint256) {
        uint256[] memory amounts = IPancakeRouter02(uniRouterAddress).getAmountsOut(_tokenAmount, _path);
        return amounts[amounts.length - 1];
    }

    function pendingHarvest() public view returns (uint256) {
        uint256 _earnedBal = IERC20(earnedAddress).balanceOf(address(this));
        return IPancakeswapFarm(farmContractAddress).pendingShare(pid, address(this)) + _earnedBal;
    }

    function pendingHarvestDollarValue() public view returns (uint256) {
        uint256 _pending = pendingHarvest();
        return (_pending == 0) ? 0 : uniExchangeRate(_pending, earnedToBusdPath);
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setStrategist(address _strategist) external onlyOperator {
        strategist = _strategist;
    }

    function setEntranceFeeFactor(uint256 _entranceFeeFactor) external onlyOperator {
        require(_entranceFeeFactor > entranceFeeFactorLL, "GymVaultsStrategy: !safe - too low");
        require(_entranceFeeFactor <= entranceFeeFactorMax, "GymVaultsStrategy: !safe - too high");
        entranceFeeFactor = _entranceFeeFactor;
    }

    function setControllerFee(uint256 _controllerFee) external onlyOperator {
        require(_controllerFee <= controllerFeeUL, "GymVaultsStrategy: too high");
        controllerFee = _controllerFee;
    }

    function setNotPublic(bool _notPublic) external onlyOperator {
        notPublic = _notPublic;
    }

    function setEarnedToBusdPath(address[] memory _path) external onlyOperator {
        earnedToBusdPath = _path;
    }

    function setEarnedToToken0Path(address[] memory _path) external onlyOperator {
        earnedToToken0Path = _path;
    }

    function setEarnedToToken1Path(address[] memory _path) external onlyOperator {
        earnedToToken1Path = _path;
    }

    function setToken0ToEarnedPath(address[] memory _path) external onlyOperator {
        token0ToEarnedPath = _path;
    }

    function setToken1ToEarnedPath(address[] memory _path) external onlyOperator {
        token1ToEarnedPath = _path;
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external onlyOperator {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
        emit InCaseTokensGetStuck(_token, _amount, _to);
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



interface IPancakeswapFarm {
    function poolLength() external view returns (uint256);

    function userInfo() external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function pendingMDO(uint256 _pid, address _user) external view returns (uint256);
    function pendingShare(uint256 _pid, address _user) external view returns (uint256);
    function pendingBDO(uint256 _pid, address _user) external view returns (uint256);
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function pendingBELT(uint256 _pid, address _user) external view returns (uint256);
    function pendingBusd(uint256 _pid, address _user) external view returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

pragma solidity 0.8.0;


// SPDX-License-Identifier: MIT



interface ITreasury {
    function notifyExternalReward(uint256 _amount) external;
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "../interfaces/IStrategy.sol";

contract StrategyMock is IStrategy {
    using SafeERC20 for IERC20;

    address public want;
    uint256 private _wantLockedTotal;
    uint256 private _sharesTotal;

    constructor(address _want) {
        want = _want;
    }

    receive() external payable {}
    fallback() external payable {}
    // Total want tokens managed by strategy
    function wantLockedTotal() external override view returns (uint256) {
        return _wantLockedTotal;
    }

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external override view returns (uint256) {
        return _sharesTotal;
    }

    function wantAddress() external override view returns (address) {
        return want;
    }

    function token0Address() external override view returns (address) {
        revert("No implementation");
    }

    function token1Address() external override view returns (address) {
        revert("No implementation");
    }

    function earnedAddress() external override view returns (address) {
        revert("No implementation");
    }

    function ratio0() external override view returns (uint256) {
        revert("No implementation");
    }

    function ratio1() external override view returns (uint256) {
        revert("No implementation");
    }

    function getPricePerFullShare() public override view returns (uint256) {
        return (_sharesTotal == 0) ? 1e18 : _wantLockedTotal * 1e18 / _sharesTotal;
    }

    function earn() external override {
        uint256 _earned = _wantLockedTotal / 100;
        IERC20(want).safeTransferFrom(msg.sender, address(this), _earned);
        _wantLockedTotal = _wantLockedTotal + _earned;
    }

    function deposit(address, uint256 _wantAmt) external override returns (uint256 _sharedAdded) {
        IERC20(want).safeTransferFrom(msg.sender, address(this), _wantAmt);
        _sharedAdded = _wantAmt * 1e18  / getPricePerFullShare();
        _sharesTotal = _sharesTotal + _sharedAdded;
        _wantLockedTotal = _wantLockedTotal + _wantAmt;
    }

    function withdraw(address, uint256 _wantAmt) external override returns (uint256 _sharesRemoved) {
        IERC20(want).safeTransfer(msg.sender, _wantAmt);
        _sharesRemoved = _wantAmt* 1e18 / getPricePerFullShare();
        _sharesTotal = _sharesTotal  - _sharesRemoved;
        _wantLockedTotal = _wantLockedTotal - _wantAmt;
    }

    function migrateFrom(address _oldStrategy, uint256 _oldWantLockedTotal, uint256 _oldSharesTotal) external override {
        require(_wantLockedTotal == 0 && _sharesTotal == 0, "strategy is not empty");
        require(want == IStrategy(_oldStrategy).wantAddress(), "!wantAddress");
        uint256 _wantAmt = IERC20(want).balanceOf(address(this));
        require(_wantAmt >= _oldWantLockedTotal, "short of wantLockedTotal");
        _sharesTotal = _oldSharesTotal;
        _wantLockedTotal = _wantLockedTotal + _wantAmt;
    }

    function inCaseTokensGetStuck(address, uint256, address) external override {
        revert("No implementation");
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategy.sol";


contract BankMock {
    receive() external payable {}
    fallback() external payable {}
    function deposit(address _strategy, uint256 _wantAmt) public {
        address _wantAddress = IStrategy(_strategy).wantAddress();
        IERC20(_wantAddress).approve(_strategy, _wantAmt);
        IStrategy(_strategy).deposit(msg.sender, _wantAmt);
    }

    function withdraw(address _strategy, uint256 _wantAmt) public {
        IStrategy(_strategy).withdraw(msg.sender, _wantAmt);
    }
}

pragma solidity 0.8.0;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract VaultMock is ERC20("ibToken", "IT"){
    address wantToken;
  constructor(
    // address _ibToken,
    address _wantToken
  ) {
    // ibToken = _ibToken;
    wantToken = _wantToken;
    // decimals(18);
  }

  /// @dev Add more token to the lending pool. Hope to get some good returns.
  function deposit(uint256 amountToken)
    external
  {
      IERC20(wantToken).transferFrom(msg.sender, address(this), amountToken);
      _mint(msg.sender, amountToken);
  }

  function withdraw(uint256 share) external {
    // IERC20(ibToken)._burn(msg.sender, share);
    IERC20(wantToken).transfer(msg.sender, share);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract RouterMock {
    address lpToken;

    constructor (address _lpToken) {
        lpToken = _lpToken;
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[path.length -1]).transfer(to, amountIn);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
        IERC20(lpToken).transfer(to, 10000);

        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = 10000;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FarmMock {
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    PoolInfo[] public poolInfo;

    address earnToken;

    constructor(
        address want,
        address _earnToken
    ) {
        poolInfo.push(
            PoolInfo({
                lpToken: want,
                allocPoint: 10,
                lastRewardBlock: block.number,
                accCakePerShare: 0
            })
        );

        earnToken = _earnToken;
        
    }

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        IERC20(pool.lpToken).transferFrom(msg.sender, address(this), _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        if (_amount > IERC20(pool.lpToken).balanceOf(address(this))) {
            _amount = IERC20(pool.lpToken).balanceOf(address(this));
        }
        IERC20(pool.lpToken).transfer(msg.sender, _amount);
        IERC20(earnToken).transfer(msg.sender, 10000);
    }

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external {
        PoolInfo storage pool = poolInfo[0];
        IERC20(pool.lpToken).transferFrom(msg.sender, address(this), _amount);
    }

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external {
        PoolInfo storage pool = poolInfo[0];
        if (_amount > IERC20(pool.lpToken).balanceOf(address(this))) {
            _amount = IERC20(pool.lpToken).balanceOf(address(this));
        }
        IERC20(pool.lpToken).transfer(msg.sender, _amount);
        IERC20(pool.lpToken).transfer(msg.sender, 10000);
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./GymToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
interface IMigrator {
    // Perform LP token migration from legacy UniswapV2 to TacoSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // TacoSwap must mint EXACTLY the same amount of TacoSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

/**
 * @title GymMasterChef is the master of gym
 * @notice GymMasterChef contract:
 * - Users can:
 *   # Deposit
 *   # Harvest
 *   # Withdraw
 */

contract GymMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /**
    * @notice Info of each user
    * @param amount: How many LP tokens the user has provided
    * @param rewardDebt: Reward debt. See explanation below
    * @dev Any point in time, the amount of gyms entitled to a user but is pending to be distributed is:
    *    pending reward = (user.amount * pool.accGymPerShare) - user.rewardDebt

    *    Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    *      1. The pool's `accGymPerShare` (and `lastRewardBlock`) gets updated.
    *      2. User receives the pending reward sent to his/her address.
    *      3. User's `amount` gets updated.
    *      4. User's `rewardDebt` gets updated.
    */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /**
     * @notice Info of each pool
     * @param lpToken: Address of LP token contract
     * @param allocPoint: How many allocation points assigned to this pool. gyms to distribute per block
     * @param lastRewardBlock: Last block number that gyms distribution occurs
     * @param accGymPerShare: Accumulated gyms per share, times 1e12. See below
     */
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. gyms to distribute per block.
        uint256 lastRewardBlock; // Last block number that gyms distribution occurs.
        uint256 accGymPerShare; // Accumulated gyms per share, times 1e12. See below.
    }
    /// The gym TOKEN!
    GymToken public gym;
    /// Dev address.
    address public devaddr;
    ///  Block number when bonus gym period ends.
    uint256 public endBlock;
    ///  gym tokens created in first block.
    uint256 public gymForBlock;
    /// The migrator contract. Can only be set through governance (owner).
    IMigrator public migrator;
    /// Info of each pool.
    PoolInfo[] public poolInfo;
    /// Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public isPoolExist;
    /// Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    /// The block number when gym mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Migrator(address migratorAddress);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }
    constructor(
        GymToken _gym,
        address _devaddr,
        uint256 _gymForBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        require(address(_gym) != address(0x0), "GymMasterChef::set zero address");
        require(_devaddr != address(0x0), "GymMasterChef::set zero address");

        gym = _gym;
        devaddr = _devaddr;
        gymForBlock = _gymForBlock;
        endBlock = _endBlock;
        startBlock = _startBlock;
    }

    /// @return All pools amount
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Add a new lp to the pool. Can only be called by the owner
     * @param _allocPoint: allocPoint for new pool
     * @param _lpToken: address of lpToken for new pool
     * @param _withUpdate: if true, update all pools
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(
            !isPoolExist[address(_lpToken)],
            "GymMasterChef:: LP token already added"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGymPerShare: 0
            })
        );
        isPoolExist[address(_lpToken)] = true;
    }

    /**
     * @notice Update the given pool's gym allocation point. Can only be called by the owner
     */
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @notice Set the migrator contract. Can only be called by the owner
     * @param _migrator: migrator contract
     */
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
        emit Migrator(address(_migrator));
    }

    /**
     * @notice Migrate lp token to another lp contract. Can be called by anyone
     * @param _pid: ID of pool which message sender wants to migrate
     */
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    /**
     * @param _from: block number from which the reward is calculated
     * @param _to: block number before which the reward is calculated
     * @return Return reward multiplier over the given _from to _to block
     */
    function getReward(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        require(
            _from <= _to,
            "GymMasterChef:: from should be less or equal than to"
        );
        if (_to > endBlock) {
            _to = endBlock;
        }
        return
            (_to.sub(_from)).mul(gymForBlock);
    }

    /**
     * @notice View function to see pending gyms on frontend
     * @param _pid: pool ID for which reward must be calculated
     * @param _user: user address for which reward must be calculated
     * @return Return reward for user
     */
    function pendingGym(uint256 _pid, address _user)
        external
        view
        validatePoolByPid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGymPerShare = pool.accGymPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getReward(pool.lastRewardBlock, block.number);
            uint256 gymReward =
                multiplier.mul(pool.allocPoint).div(totalAllocPoint);
            accGymPerShare = accGymPerShare.add(
                gymReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accGymPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @notice Update reward vairables for all pools
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date
     * @param _pid: pool ID for which the reward variables should be updated
     */
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getReward(pool.lastRewardBlock, block.number);
        uint256 gymReward =
            multiplier.mul(pool.allocPoint).div(totalAllocPoint);
        safeGymTransfer(devaddr, gymReward.div(10));
        // gymReward = gymReward.mul(9).div(10);
        // safeGymTransfer(address(this), gymReward); instant send 33% : 66%
        pool.accGymPerShare = pool.accGymPerShare.add(
            gymReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Deposit LP tokens to GymMasterChef for gym allocation
     * @param _pid: pool ID on which LP tokens should be deposited
     * @param _amount: the amount of LP tokens that should be deposited
     */
    function deposit(uint256 _pid, uint256 _amount)
        public
        validatePoolByPid(_pid)
    {
        updatePool(_pid);
        poolInfo[_pid].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        _deposit(_pid, _amount);
    }

    /**
     * @notice Function for updating user info
     */
    function _deposit(uint256 _pid, uint256 _amount) private {
        UserInfo storage user = userInfo[_pid][msg.sender];
        harvest ( _pid ) ;
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(poolInfo[_pid].accGymPerShare).div(
            1e12
        );
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice Function which send accumulated gym tokens to messege sender
     * @param _pid: pool ID from which the accumulated gym tokens should be received
     */
    function harvest(uint256 _pid) public validatePoolByPid(_pid) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 accGymPerShare = poolInfo[_pid].accGymPerShare;
        uint256 accumulatedgym = user.amount.mul(accGymPerShare).div(1e12);
        uint256 pending = accumulatedgym.sub(user.rewardDebt);

        safeGymTransfer(msg.sender, pending);

        user.rewardDebt = user.amount.mul(accGymPerShare).div(1e12);

        emit Harvest(msg.sender, _pid, pending);
    }

    /**
     * @notice Function which send accumulated gym tokens to messege sender from all pools
     */
    function harvestAll() public {
        uint256 length = poolInfo.length;
        for (uint256 i = 0; i < length; i++) {
            harvest(i);
        }
    }

    /**
     * @notice Function which withdraw LP tokens to messege sender with the given amount
     * @param _pid: pool ID from which the LP tokens should be withdrawn
     * @param _amount: the amount of LP tokens that should be withdrawn
     */
    function withdraw(uint256 _pid, uint256 _amount)
        public
        validatePoolByPid(_pid)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accGymPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeGymTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGymPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @notice Function which withdraw all LP tokens to messege sender without caring about rewards
     */
    function emergencyWithdraw(uint256 _pid) public validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @notice Function which transfer gym tokens to _to with the given amount
     * @param _to: transfer reciver address
     * @param _amount: amount of gym token which should be transfer
     */
    function safeGymTransfer(address _to, uint256 _amount) internal {
        uint256 gymBal = gym.balanceOf(address(this));
        if (_amount > gymBal) {
            gym.transfer(_to, gymBal);
        } else {
            gym.transfer(_to, _amount);
        }
    }

    /**
     * @notice Function which should be update dev address by the previous dev
     * @param _devaddr: new dev address
     */
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "GymMasterChef: dev wut?");
        require(_devaddr == address(0), "GymMasterChef: dev address can't be zero");
        devaddr = _devaddr;
    }

    /**
     * @notice Function which migrate pool to GymMasterChef. Can only be called by the migrator
     */
    function setPools(
        IERC20 _lpToken,
        uint256 _allocPoint,
        uint256 _lastRewardBlock,
        uint256 _accGymPerShare,
        uint256 _totalAllocPoint
    ) public {
        require(
            msg.sender == address(migrator),
            "GymMasterChef: Only migrator can call"
        );
        poolInfo.push(
            PoolInfo(
                IERC20(_lpToken),
                _allocPoint,
                _lastRewardBlock,
                _accGymPerShare
            )
        );
        totalAllocPoint = _totalAllocPoint;
    }

    /**
     * @notice Function which migrate user to GymMasterChef
     */
    function setUser(
        uint256 _pid,
        address _user,
        uint256 _amount,
        uint256 _rewardDebt
    ) public {
        require(
            msg.sender == address(migrator),
            "GymMasterChef: Only migrator can call"
        );
        require(poolInfo.length != 0, "GymMasterChef: Pools must be migrated");
        updatePool(_pid);
        userInfo[_pid][_user] = UserInfo(_amount, _rewardDebt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity 0.8.0;

// SPDX-License-Identifier: MITS


// pragma experimental ABIEncoderV2;


contract GymToken {
    /// @notice EIP-20 token name for this token
    string public constant name = "GYM TOKEN";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "GYM";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 600000000000000000000000000; // 80 million Gym

    /// @dev Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @dev Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Gym token
     * @param account The initial account to grant all the tokens
     */

    constructor(address account) {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "GymToken::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "GymToken::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "GymToken::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "GymToken::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }
     /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     */
    function burn(uint96 amount) public {
        _burn(msg.sender, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     */
    function burnFrom(address account, uint96 amount) public {
        uint96 currentAllowance = allowances[account][msg.sender];
        require(currentAllowance >= amount, "GymToken: burn amount exceeds allowance");
        allowances[account][msg.sender] = currentAllowance - amount;
        _burn(account, amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GymToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "GymToken::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "GymToken::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "GymToken::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _burn(address account, uint96 amount) internal {
        require(account != address(0), "GymToken: burn from the zero address");

        uint96 accountBalance = balances[account];
        require(accountBalance >= amount, "GymToken: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;
        _moveDelegates(account, address(0), amount);

        emit Transfer(account, address(0), amount);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "GymToken::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "GymToken::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "GymToken::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "GymToken::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "GymToken::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "GymToken::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "GymToken::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

pragma solidity 0.8.0;



import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// FairLaunch is a smart contract for distributing ALPACA by asking user to stake the ERC20-based token.
contract FairLaunchMock {
  using SafeERC20 for IERC20;

  function deposit(address _for, uint256 _pid, uint256 _amount) external {
    IERC20(0xf9d32C5E10Dd51511894b360e6bD39D7573450F9).safeTransferFrom(msg.sender, address(this), _amount);
  }

  // Withdraw Staking tokens from FairLaunchToken.
  function withdraw(address _for, uint256 _pid, uint256 _amount) external  {
    _withdraw(_for, _pid, _amount);
  }

  function _withdraw(address _for, uint256 _pid, uint256 _amount) internal {
      IERC20(0xf9d32C5E10Dd51511894b360e6bD39D7573450F9).safeTransfer(address(msg.sender), _amount);
  }

  // Harvest ALPACAs earn from the pool.
  function harvest(uint256 _pid) external {
      IERC20(0x354b3a11D5Ea2DA89405173977E271F58bE2897D).safeTransfer(address(msg.sender), 500);
  }
}

