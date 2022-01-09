/**
 *Submitted for verification at snowtrace.io on 2022-01-09
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

interface ICurve {
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external returns (uint);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external returns (uint);
}

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInAVAX() external view returns (uint);
    function getAllPoolInUSD() external view returns (uint);
}

contract StableAvaxStrategy is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant USDT = IERC20Upgradeable(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    IERC20Upgradeable constant USDC = IERC20Upgradeable(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    IERC20Upgradeable constant DAI = IERC20Upgradeable(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);
    IERC20Upgradeable constant MIM = IERC20Upgradeable(0x130966628846BFd36ff31a822705796e8cb8C18D);
    IERC20Upgradeable constant WAVAX = IERC20Upgradeable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    IERC20Upgradeable constant USDTAVAX = IERC20Upgradeable(0x5Fc70cF6A4A858Cf4124013047e408367EBa1ace);
    IERC20Upgradeable constant USDCAVAX = IERC20Upgradeable(0xbd918Ed441767fe7924e99F6a0E0B568ac1970D9);
    IERC20Upgradeable constant DAIAVAX = IERC20Upgradeable(0x87Dee1cC9FFd464B79e058ba20387c1984aed86a); // Depreciated
    IERC20Upgradeable constant MIMAVAX = IERC20Upgradeable(0x239aAE4AaBB5D60941D7DFFAeaFE8e063C63Ab25); // Replace DAIAVAX

    IRouter constant joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IRouter constant pngRouter = IRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    IRouter constant lydRouter = IRouter(0xA52aBE4676dbfd04Df42eF7755F01A3c41f28D27);
    ICurve constant curve = ICurve(0xAEA2E71b631fA93683BCF256A8689dFa0e094fcD); // 3poolV2

    IDaoL1Vault public USDTAVAXVault;
    IDaoL1Vault public USDCAVAXVault;
    IDaoL1Vault public DAIAVAXVault; // Depreciated

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    // Newly added variable after upgrade
    IDaoL1Vault public MIMAVAXVault; // Replace DAIAVAXVault

    event InvestUSDTAVAX(uint USDAmt, uint USDTAVAXAmt);
    event InvestUSDCAVAX(uint USDAmt, uint USDCAVAXAmt);
    event InvestMIMAVAX(uint USDAmt, uint MIMAVAXAmt);
    event Withdraw(uint amount, uint USDAmt);
    event WithdrawUSDTAVAX(uint lpTokenAmt, uint USDAmt);
    event WithdrawUSDCAVAX(uint lpTokenAmt, uint USDAmt);
    event WithdrawMIMAVAX(uint lpTokenAmt, uint USDAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event EmergencyWithdraw(uint USDAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    // function initialize(
    //     address _USDTAVAXVault, address _USDCAVAXVault, address _DAIAVAXVault
    // ) external initializer {

    //     USDTAVAXVault = IDaoL1Vault(_USDTAVAXVault);
    //     USDCAVAXVault = IDaoL1Vault(_USDCAVAXVault);
    //     DAIAVAXVault = IDaoL1Vault(_DAIAVAXVault);

    //     USDT.safeApprove(address(lydRouter), type(uint).max);
    //     USDT.safeApprove(address(curve), type(uint).max);
    //     USDC.safeApprove(address(pngRouter), type(uint).max);
    //     USDC.safeApprove(address(curve), type(uint).max);
    //     DAI.safeApprove(address(joeRouter), type(uint).max);
    //     DAI.safeApprove(address(curve), type(uint).max);
    //     WAVAX.safeApprove(address(lydRouter), type(uint).max);
    //     WAVAX.safeApprove(address(pngRouter), type(uint).max);
    //     WAVAX.safeApprove(address(joeRouter), type(uint).max);

    //     USDTAVAX.safeApprove(address(USDTAVAXVault), type(uint).max);
    //     USDTAVAX.safeApprove(address(lydRouter), type(uint).max);
    //     USDCAVAX.safeApprove(address(USDCAVAXVault), type(uint).max);
    //     USDCAVAX.safeApprove(address(pngRouter), type(uint).max);
    //     DAIAVAX.safeApprove(address(DAIAVAXVault), type(uint).max);
    //     DAIAVAX.safeApprove(address(joeRouter), type(uint).max);
    // }

    function invest(uint USDTAmt, uint[] calldata amountsOutMin) external onlyVault {
        USDT.safeTransferFrom(vault, address(this), USDTAmt);

        // Stablecoins-AVAX farm don't need rebalance invest
        investUSDTAVAX(USDTAmt * 500 / 10000, amountsOutMin[1]);
        investUSDCAVAX(USDTAmt * 8000 / 10000, amountsOutMin[2]);
        investMIMAVAX(USDTAmt * 1500 / 10000, amountsOutMin[3]);
    }

    function investUSDTAVAX(uint USDTAmt, uint amountOutMin) private {
        uint halfUSDT = USDTAmt / 2;

        uint WAVAXAmt = lydRouter.swapExactTokensForTokens(
            halfUSDT, amountOutMin, getPath(address(USDT), address(WAVAX)), address(this), block.timestamp
        )[1];

        (,,uint USDTAVAXAmt) = lydRouter.addLiquidity(
            address(USDT), address(WAVAX), halfUSDT, WAVAXAmt, 0, 0, address(this), block.timestamp
        );

        USDTAVAXVault.deposit(USDTAVAXAmt);

        emit InvestUSDTAVAX(USDTAmt, USDTAVAXAmt);
    }

    function investUSDCAVAX(uint USDTAmt, uint amountOutMin) private {
        uint USDCAmt = curve.exchange(
            getCurveId(address(USDT)), getCurveId(address(USDC)), USDTAmt, USDTAmt * 99 / 100
        );
        uint halfUSDC = USDCAmt / 2;

        uint WAVAXAmt = pngRouter.swapExactTokensForTokens(
            halfUSDC, amountOutMin, getPath(address(USDC), address(WAVAX)), address(this), block.timestamp
        )[1];

        (,,uint USDCAVAXAmt) = pngRouter.addLiquidity(
            address(USDC), address(WAVAX), halfUSDC, WAVAXAmt, 0, 0, address(this), block.timestamp
        );

        USDCAVAXVault.deposit(USDCAVAXAmt);

        emit InvestUSDCAVAX(USDTAmt, USDCAVAXAmt);
    }

    function investMIMAVAX(uint USDTAmt, uint amountOutMin) private {
        uint MIMAmt = curve.exchange(
            getCurveId(address(USDT)), getCurveId(address(MIM)), USDTAmt, (USDTAmt * 1e12) * 99 / 100
        );
        uint halfMIM = MIMAmt / 2;

        uint WAVAXAmt = pngRouter.swapExactTokensForTokens(
            halfMIM, amountOutMin, getPath(address(MIM), address(WAVAX)), address(this), block.timestamp
        )[1];

        (,,uint MIMAVAXAmt) = pngRouter.addLiquidity(
            address(MIM), address(WAVAX), halfMIM, WAVAXAmt, 0, 0, address(this), block.timestamp
        );

        MIMAVAXVault.deposit(MIMAVAXAmt);

        emit InvestMIMAVAX(USDTAmt, MIMAVAXAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata amountsOutMin) external onlyVault returns (uint USDTAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();

        uint USDTAmtBefore = USDT.balanceOf(address(this));
        withdrawUSDTAVAX(sharePerc, amountsOutMin[1]);
        withdrawUSDCAVAX(sharePerc, amountsOutMin[2]);
        withdrawMIMAVAX(sharePerc, amountsOutMin[3]);
        USDTAmt = USDT.balanceOf(address(this)) - USDTAmtBefore;
        
        USDT.safeTransfer(vault, USDTAmt);

        emit Withdraw(amount, USDTAmt);
    }

    function withdrawUSDTAVAX(uint sharePerc, uint amountOutMin) private {
        uint USDTAVAXAmt = USDTAVAXVault.withdraw(USDTAVAXVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint WAVAXAmt, uint USDTAmt) = lydRouter.removeLiquidity(
            address(WAVAX), address(USDT), USDTAVAXAmt, 0, 0, address(this), block.timestamp
        );

        USDTAmt += lydRouter.swapExactTokensForTokens(
            WAVAXAmt, amountOutMin, getPath(address(WAVAX), address(USDT)), address(this), block.timestamp
        )[1];

        emit WithdrawUSDTAVAX(USDTAVAXAmt, USDTAmt);
    }

    function withdrawUSDCAVAX(uint sharePerc, uint amountOutMin) private {
        uint USDCAVAXAmt = USDCAVAXVault.withdraw(USDCAVAXVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint USDCAmt, uint WAVAXAmt) = pngRouter.removeLiquidity(
            address(USDC), address(WAVAX), USDCAVAXAmt, 0, 0, address(this), block.timestamp
        );

        USDCAmt += pngRouter.swapExactTokensForTokens(
            WAVAXAmt, amountOutMin, getPath(address(WAVAX), address(USDC)), address(this), block.timestamp
        )[1];

        uint USDTAmt = curve.exchange(
            getCurveId(address(USDC)), getCurveId(address(USDT)), USDCAmt, USDCAmt * 99 / 100
        );

        emit WithdrawUSDCAVAX(USDCAVAXAmt, USDTAmt);
    }

    function withdrawMIMAVAX(uint sharePerc, uint amountOutMin) private {
        uint MIMAVAXAmt = MIMAVAXVault.withdraw(MIMAVAXVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint MIMAmt, uint WAVAXAmt) = pngRouter.removeLiquidity(
            address(MIM), address(WAVAX), MIMAVAXAmt, 0, 0, address(this), block.timestamp
        );

        MIMAmt += pngRouter.swapExactTokensForTokens(
            WAVAXAmt, amountOutMin, getPath(address(WAVAX), address(MIM)), address(this), block.timestamp
        )[1];

        uint USDTAmt = curve.exchange(
            getCurveId(address(MIM)), getCurveId(address(USDT)), MIMAmt, (MIMAmt / 1e12) * 99 / 100
        );

        emit WithdrawMIMAVAX(MIMAVAXAmt, USDTAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawUSDTAVAX(1e18, 0);
        withdrawUSDCAVAX(1e18, 0);
        withdrawMIMAVAX(1e18, 0);

        uint USDTAmt = USDT.balanceOf(address(this));
        USDT.safeTransfer(vault, USDTAmt);
        watermark = 0;

        emit EmergencyWithdraw(USDTAmt);
    }

    function collectProfitAndUpdateWatermark() external onlyVault returns (uint fee, uint allPoolInUSD) {
        uint currentWatermark = getAllPoolInUSD();
        uint lastWatermark = watermark;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / 10000;
            watermark = currentWatermark;
        }
        allPoolInUSD = currentWatermark;

        emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) external onlyVault {
        uint lastWatermark = watermark;
        watermark = signs == true ? watermark + amount : watermark - amount;

        emit AdjustWatermark(watermark, lastWatermark);
    }

    /// @notice This function switch DAIAVAXVault to MIMAVAXVault
    function switchVaultL1(IDaoL1Vault _MIMAVAXVault) external {
        require(msg.sender == 0x3f68A3c1023d736D8Be867CA49Cb18c543373B99, "Not authorized");

        // Set MIMAVAXVault
        MIMAVAXVault = _MIMAVAXVault;

        // Withdraw from DAIAVAXVault;
        uint DAIAVAXAmt = DAIAVAXVault.withdraw(DAIAVAXVault.balanceOf(address(this)));
        (uint DAIAmt, uint WAVAXAmt) = joeRouter.removeLiquidity(
            address(DAI), address(WAVAX), DAIAVAXAmt, 0, 0, address(this), block.timestamp
        );

        // Approve all Stablecoins to new curve 3poolV2
        USDT.safeApprove(address(curve), type(uint).max);
        USDC.safeApprove(address(curve), type(uint).max);
        MIM.safeApprove(address(curve), type(uint).max);
        // Approve MIMAVAX to Pangolin router
        MIMAVAX.safeApprove(address(pngRouter), type(uint).max);

        // Swap DAI to MIM
        ICurve av3CRV = ICurve(0x7f90122BF0700F9E7e1F688fe926940E8839F353);
        uint USDCAmt = av3CRV.exchange_underlying(
            0, 1, DAIAmt, (DAIAmt / 1e12) * 99 / 100
        );
        uint MIMAmt = curve.exchange(
            getCurveId(address(USDC)), getCurveId(address(MIM)), USDCAmt, (USDCAmt * 1e12) * 99 / 100
        );

        // Add liquidity into MIMAVAX on Pangolin
        MIM.safeApprove(address(pngRouter), type(uint).max);
        (,,uint MIMAVAXAmt) = pngRouter.addLiquidity(
            address(MIM), address(WAVAX), MIMAmt, WAVAXAmt, 0, 0, address(this), block.timestamp
        );

        // Deposit into MIMAVAXVault
        MIMAVAX.safeApprove(address(MIMAVAXVault), type(uint).max);
        MIMAVAXVault.deposit(MIMAVAXAmt);
    }

    function setVault(address _vault) external {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyVault {
        profitFeePerc = _profitFeePerc;
    }

    function getPath(address tokenA, address tokenB) private pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
    }

    function getCurveId(address token) private pure returns (int128) {
        if (token == address(USDT)) return 1;
        else if (token == address(USDC)) return 2;
        else return 0; // MIM
    }

    function getUSDTAVAXPool() private view returns (uint) {
        uint USDTAVAXVaultPool = USDTAVAXVault.getAllPoolInUSD();
        if (USDTAVAXVaultPool == 0) return 0;
        return USDTAVAXVaultPool * USDTAVAXVault.balanceOf(address(this)) / USDTAVAXVault.totalSupply();
    }

    function getUSDCAVAXPool() private view returns (uint) {
        uint USDCAVAXVaultPool = USDCAVAXVault.getAllPoolInUSD();
        if (USDCAVAXVaultPool == 0) return 0;
        return USDCAVAXVaultPool * USDCAVAXVault.balanceOf(address(this)) / USDCAVAXVault.totalSupply();
    }

    function getMIMAVAXPool() private view returns (uint) {
        uint MIMAVAXVaultPool = MIMAVAXVault.getAllPoolInUSD();
        if (MIMAVAXVaultPool == 0) return 0;
        return MIMAVAXVaultPool * MIMAVAXVault.balanceOf(address(this)) / MIMAVAXVault.totalSupply();
    }

    function getEachPool() public view returns (uint[] memory pools) {
        pools = new uint[](3);
        pools[0] = getUSDTAVAXPool();
        pools[1] = getUSDCAVAXPool();
        pools[2] = getMIMAVAXPool();
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint[] memory pools = getEachPool();
        return pools[0] + pools[1] + pools[2];
    }
}