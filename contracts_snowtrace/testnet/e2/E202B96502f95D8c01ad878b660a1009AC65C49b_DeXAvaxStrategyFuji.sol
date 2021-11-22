/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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













/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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





/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInAVAX() external view returns (uint);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract DeXAvaxStrategyFuji is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant WAVAX = IERC20Upgradeable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20Upgradeable constant JOE = IERC20Upgradeable(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);
    IERC20Upgradeable constant PNG = IERC20Upgradeable(0x60781C2586D68229fde47564546784ab3fACA982);
    IERC20Upgradeable constant LYD = IERC20Upgradeable(0x4C9B4E1AC6F24CdE3660D5E4Ef1eBF77C710C084);

    IERC20Upgradeable constant JOEAVAX = IERC20Upgradeable(0x454E67025631C065d3cFAD6d71E6892f74487a15);
    IERC20Upgradeable constant PNGAVAX = IERC20Upgradeable(0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367);
    IERC20Upgradeable constant LYDAVAX = IERC20Upgradeable(0xFba4EdaAd3248B03f1a3261ad06Ad846A8e50765);

    IRouter constant joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IRouter constant pngRouter = IRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    IRouter constant lydRouter = IRouter(0xA52aBE4676dbfd04Df42eF7755F01A3c41f28D27);

    IDaoL1Vault public JOEAVAXVault;
    IDaoL1Vault public PNGAVAXVault;
    IDaoL1Vault public LYDAVAXVault;

    address public vault;

    event TargetComposition (uint JOEAVAXTargetPool, uint PNGAVAXTargetPool, uint LYDAVAXTargetPool);
    event CurrentComposition (uint JOEAVAXCCurrentPool, uint PNGAVAXCurrentPool, uint LYDAVAXCurrentPool);
    event InvestJOEAVAX(uint WAVAXAmt, uint JOEAVAXAmt);
    event InvestPNGAVAX(uint WAVAXAmt, uint PNGAVAXAmt);
    event InvestLYDAVAX(uint WAVAXAmt, uint LYDAVAXAmt);
    event Withdraw(uint amount, uint WAVAXAmt);
    event WithdrawJOEAVAX(uint lpTokenAmt, uint WAVAXAmt);
    event WithdrawPNGAVAX(uint lpTokenAmt, uint WAVAXAmt);
    event WithdrawLYDAVAX(uint lpTokenAmt, uint WAVAXAmt);
    event EmergencyWithdraw(uint WAVAXAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        address _JOEAVAXVault, address _PNGAVAXVault, address _LYDAVAXVault
    ) external initializer {

        JOEAVAXVault = IDaoL1Vault(_JOEAVAXVault);
        PNGAVAXVault = IDaoL1Vault(_PNGAVAXVault);
        LYDAVAXVault = IDaoL1Vault(_LYDAVAXVault);

        // WAVAX.safeApprove(address(joeRouter), type(uint).max);
        // WAVAX.safeApprove(address(pngRouter), type(uint).max);
        // WAVAX.safeApprove(address(lydRouter), type(uint).max);
        // JOE.safeApprove(address(joeRouter), type(uint).max);
        // PNG.safeApprove(address(pngRouter), type(uint).max);
        // LYD.safeApprove(address(lydRouter), type(uint).max);

        // JOEAVAX.safeApprove(address(JOEAVAXVault), type(uint).max);
        // JOEAVAX.safeApprove(address(joeRouter), type(uint).max);
        // PNGAVAX.safeApprove(address(PNGAVAXVault), type(uint).max);
        // PNGAVAX.safeApprove(address(pngRouter), type(uint).max);
        // LYDAVAX.safeApprove(address(LYDAVAXVault), type(uint).max);
        // LYDAVAX.safeApprove(address(lydRouter), type(uint).max);
    }

    function invest(uint WAVAXAmt, uint[] calldata amountsOutMin) external onlyVault {
        WAVAX.safeTransferFrom(vault, address(this), WAVAXAmt);

        uint[] memory pools = getEachPool();
        uint pool = pools[0] + pools[1] + pools[2] + WAVAXAmt;
        uint JOEAVAXTargetPool = pool * 4500 / 10000; // 45%
        uint PNGAVAXTargetPool = JOEAVAXTargetPool; // 45%
        uint LYDAVAXTargetPool = pool * 1000 / 10000; // 10%

        // Rebalancing invest
        if (
            JOEAVAXTargetPool > pools[0] &&
            PNGAVAXTargetPool > pools[1] &&
            LYDAVAXTargetPool > pools[2]
        ) {
            investJOEAVAX(JOEAVAXTargetPool - pools[0], amountsOutMin[1]);
            investPNGAVAX(PNGAVAXTargetPool - pools[1], amountsOutMin[2]);
            investLYDAVAX(LYDAVAXTargetPool - pools[2], amountsOutMin[3]);
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (JOEAVAXTargetPool > pools[0]) {
                diff = JOEAVAXTargetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (PNGAVAXTargetPool > pools[1]) {
                diff = PNGAVAXTargetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (LYDAVAXTargetPool > pools[2]) {
                diff = LYDAVAXTargetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }

            if (farmIndex == 0) investJOEAVAX(WAVAXAmt, amountsOutMin[1]);
            else if (farmIndex == 1) investPNGAVAX(WAVAXAmt, amountsOutMin[2]);
            else investLYDAVAX(WAVAXAmt, amountsOutMin[3]);
        }

        emit TargetComposition(JOEAVAXTargetPool, PNGAVAXTargetPool, LYDAVAXTargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2]);
    }

    function investJOEAVAX(uint WAVAXAmt, uint amountOutMin) private {
        uint halfWAVAX = WAVAXAmt / 2;

        uint JOEAmt = joeRouter.swapExactTokensForTokens(
            halfWAVAX, amountOutMin, getPath(address(WAVAX), address(JOE)), address(this), block.timestamp
        )[1];

        (,,uint JOEAVAXAmt) = joeRouter.addLiquidity(
            address(JOE), address(WAVAX), JOEAmt, halfWAVAX, 0, 0, address(this), block.timestamp
        );

        JOEAVAXVault.deposit(JOEAVAXAmt);

        emit InvestJOEAVAX(WAVAXAmt, JOEAVAXAmt);
    }

    function investPNGAVAX(uint WAVAXAmt, uint amountOutMin) private {
        uint halfWAVAX = WAVAXAmt / 2;

        uint PNGAmt = pngRouter.swapExactTokensForTokens(
            halfWAVAX, amountOutMin, getPath(address(WAVAX), address(PNG)), address(this), block.timestamp
        )[1];

        (,,uint PNGAVAXAmt) = pngRouter.addLiquidity(
            address(PNG), address(WAVAX), PNGAmt, halfWAVAX, 0, 0, address(this), block.timestamp
        );

        PNGAVAXVault.deposit(PNGAVAXAmt);

        emit InvestPNGAVAX(WAVAXAmt, PNGAVAXAmt);
    }

    function investLYDAVAX(uint WAVAXAmt, uint amountOutMin) private {
        uint halfWAVAX = WAVAXAmt / 2;

        uint LYDAmt = lydRouter.swapExactTokensForTokens(
            halfWAVAX, amountOutMin, getPath(address(WAVAX), address(LYD)), address(this), block.timestamp
        )[1];

        (,,uint LYDAVAXAmt) = lydRouter.addLiquidity(
            address(LYD), address(WAVAX), LYDAmt, halfWAVAX, 0, 0, address(this), block.timestamp
        );

        LYDAVAXVault.deposit(LYDAVAXAmt);

        emit InvestLYDAVAX(WAVAXAmt, LYDAVAXAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata amountsOutMin) external onlyVault returns (uint WAVAXAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();

        uint WAVAXAmtBefore = WAVAX.balanceOf(address(this));
        withdrawJOEAVAX(sharePerc, amountsOutMin[1]);
        withdrawPNGAVAX(sharePerc, amountsOutMin[2]);
        withdrawLYDAVAX(sharePerc, amountsOutMin[3]);
        WAVAXAmt = WAVAX.balanceOf(address(this)) - WAVAXAmtBefore;

        WAVAX.safeTransfer(vault, WAVAXAmt);

        emit Withdraw(amount, WAVAXAmt);
    }

    function withdrawJOEAVAX(uint sharePerc, uint amountOutMin) private {
        uint JOEAVAXAmt = JOEAVAXVault.withdraw(JOEAVAXVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint JOEAmt, uint WAVAXAmt) = joeRouter.removeLiquidity(
            address(JOE), address(WAVAX), JOEAVAXAmt, 0, 0, address(this), block.timestamp
        );

        uint _WAVAXAmt = joeRouter.swapExactTokensForTokens(
            JOEAmt, amountOutMin, getPath(address(JOE), address(WAVAX)), address(this), block.timestamp
        )[1];

        emit WithdrawJOEAVAX(JOEAVAXAmt, WAVAXAmt + _WAVAXAmt);
    }

    function withdrawPNGAVAX(uint sharePerc, uint amountOutMin) private {
        uint PNGAVAXAmt = PNGAVAXVault.withdraw(PNGAVAXVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint PNGAmt, uint WAVAXAmt) = pngRouter.removeLiquidity(
            address(PNG), address(WAVAX), PNGAVAXAmt, 0, 0, address(this), block.timestamp
        );

        uint _WAVAXAmt = pngRouter.swapExactTokensForTokens(
            PNGAmt, amountOutMin, getPath(address(PNG), address(WAVAX)), address(this), block.timestamp
        )[1];

        emit WithdrawPNGAVAX(PNGAVAXAmt, WAVAXAmt + _WAVAXAmt);
    }

    function withdrawLYDAVAX(uint sharePerc, uint amountOutMin) private {
        uint LYDAVAXAmt = LYDAVAXVault.withdraw(LYDAVAXVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint LYDAmt, uint WAVAXAmt) = lydRouter.removeLiquidity(
            address(LYD), address(WAVAX), LYDAVAXAmt, 0, 0, address(this), block.timestamp
        );

        uint _WAVAXAmt = lydRouter.swapExactTokensForTokens(
            LYDAmt, amountOutMin, getPath(address(LYD), address(WAVAX)), address(this), block.timestamp
        )[1];

        emit WithdrawLYDAVAX(LYDAVAXAmt, WAVAXAmt + _WAVAXAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawJOEAVAX(1e18, 0);
        withdrawPNGAVAX(1e18, 0);
        withdrawLYDAVAX(1e18, 0);

        uint WAVAXAmt = WAVAX.balanceOf(address(this));
        WAVAX.safeTransfer(vault, WAVAXAmt);
        
        emit EmergencyWithdraw(WAVAXAmt);
    }

    function setVault(address _vault) external {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getJOEAVAXPool() private view returns (uint) {
        uint JOEAVAXVaultPool = JOEAVAXVault.getAllPoolInAVAX();
        if (JOEAVAXVaultPool == 0) return 0;
        return JOEAVAXVaultPool * JOEAVAXVault.balanceOf(address(this)) / JOEAVAXVault.totalSupply();
    }

    function getPNGAVAXPool() private view returns (uint) {
        uint PNGAVAXVaultPool = PNGAVAXVault.getAllPoolInAVAX();
        if (PNGAVAXVaultPool == 0) return 0;
        return PNGAVAXVaultPool * PNGAVAXVault.balanceOf(address(this)) / PNGAVAXVault.totalSupply();
    }

    function getLYDAVAXPool() private view returns (uint) {
        uint LYDAVAXVaultPool = LYDAVAXVault.getAllPoolInAVAX();
        if (LYDAVAXVaultPool == 0) return 0;
        return LYDAVAXVaultPool * LYDAVAXVault.balanceOf(address(this)) / LYDAVAXVault.totalSupply();
    }

    function getEachPool() public view returns (uint[] memory pools) {
        pools = new uint[](3);
        pools[0] = getJOEAVAXPool();
        pools[1] = getPNGAVAXPool();
        pools[2] = getLYDAVAXPool();
    }

    /// @notice This function return only farms TVL in AVAX
    function getAllPoolInAVAX() public view returns (uint) {
        uint[] memory pools = getEachPool();
        return pools[0] + pools[1] + pools[2];
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint AVAXPriceInUSD = uint(IChainlink(0x0A77230d17318075983913bC2145DB16C7366156).latestAnswer()); // 8 decimals
        require(AVAXPriceInUSD > 0, "ChainLink error");
        return getAllPoolInAVAX() * AVAXPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPool();
        uint allPool = pools[0] + pools[1] + pools[2];
        percentages = new uint[](3);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
    }
}