/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-21
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
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external returns (uint);
}

interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external returns (uint);
    function getAllPoolInUSD() external view returns (uint);
}

contract DeXStableStrategyFuji is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant JOE = IERC20Upgradeable(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);
    IERC20Upgradeable constant PNG = IERC20Upgradeable(0x60781C2586D68229fde47564546784ab3fACA982);
    IERC20Upgradeable constant LYD = IERC20Upgradeable(0x4C9B4E1AC6F24CdE3660D5E4Ef1eBF77C710C084);
    IERC20Upgradeable constant USDT = IERC20Upgradeable(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    IERC20Upgradeable constant USDC = IERC20Upgradeable(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    IERC20Upgradeable constant DAI = IERC20Upgradeable(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);

    IERC20Upgradeable constant JOEUSDC = IERC20Upgradeable(0x67926d973cD8eE876aD210fAaf7DFfA99E414aCf);
    IERC20Upgradeable constant PNGUSDT = IERC20Upgradeable(0x1fFB6ffC629f5D820DCf578409c2d26A2998a140);
    IERC20Upgradeable constant LYDDAI = IERC20Upgradeable(0x4EE072c5946B4cdc00CBdeB4A4E54A03CF6d08d3);

    IRouter constant joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IRouter constant pngRouter = IRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    IRouter constant lydRouter = IRouter(0xA52aBE4676dbfd04Df42eF7755F01A3c41f28D27);
    ICurve constant curve = ICurve(0x7f90122BF0700F9E7e1F688fe926940E8839F353); // av3pool

    IDaoL1Vault public JOEUSDCVault;
    IDaoL1Vault public PNGUSDTVault;
    IDaoL1Vault public LYDDAIVault;

    address public vault;

    event TargetComposition (uint JOEUSDCTargetPool, uint PNGUSDTTargetPool, uint LYDDAITargetPool);
    event CurrentComposition (uint JOEUSDCCCurrentPool, uint PNGUSDTCurrentPool, uint LYDDAICurrentPool);
    event InvestJOEUSDC(uint USDAmt, uint JOEUSDCAmt);
    event InvestPNGUSDT(uint USDAmt, uint PNGUSDTAmt);
    event InvestLYDDAI(uint USDAmt, uint LYDDAIAmt);
    event Withdraw(uint amount, uint USDAmt);
    event WithdrawJOEUSDC(uint lpTokenAmt, uint USDAmt);
    event WithdrawPNGUSDT(uint lpTokenAmt, uint USDAmt);
    event WithdrawLYDDAI(uint lpTokenAmt, uint USDAmt);
    event EmergencyWithdraw(uint USDAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        address _JOEUSDCVault, address _PNGUSDTVault, address _LYDDAIVault
    ) external initializer {

        JOEUSDCVault = IDaoL1Vault(_JOEUSDCVault);
        PNGUSDTVault = IDaoL1Vault(_PNGUSDTVault);
        LYDDAIVault = IDaoL1Vault(_LYDDAIVault);

        // USDC.safeApprove(address(joeRouter), type(uint).max);
        // USDC.safeApprove(address(curve), type(uint).max);
        // USDT.safeApprove(address(pngRouter), type(uint).max);
        // USDT.safeApprove(address(curve), type(uint).max);
        // DAI.safeApprove(address(lydRouter), type(uint).max);
        // DAI.safeApprove(address(curve), type(uint).max);
        // JOE.safeApprove(address(joeRouter), type(uint).max);
        // PNG.safeApprove(address(pngRouter), type(uint).max);
        // LYD.safeApprove(address(lydRouter), type(uint).max);

        // JOEUSDC.safeApprove(address(JOEUSDCVault), type(uint).max);
        // JOEUSDC.safeApprove(address(joeRouter), type(uint).max);
        // PNGUSDT.safeApprove(address(PNGUSDTVault), type(uint).max);
        // PNGUSDT.safeApprove(address(pngRouter), type(uint).max);
        // LYDDAI.safeApprove(address(LYDDAIVault), type(uint).max);
        // LYDDAI.safeApprove(address(lydRouter), type(uint).max);
    }

    function invest(uint USDTAmt, uint[] calldata amountsOutMin) external onlyVault {
        USDT.safeTransferFrom(vault, address(this), USDTAmt);

        uint[] memory pools = getEachPool();
        uint pool = pools[0] + pools[1] + pools[2] + USDTAmt;
        uint JOEUSDCTargetPool = pool * 8000 / 10000;
        uint PNGUSDTTargetPool = pool * 1000 / 10000;
        uint LYDDAITargetPool = pool * 1000 / 10000;

        // For this pool we don't rebalancing invest it first
        // since liquidity in PNG-USDT and LYD-DAI still quite low
        investJOEUSDC(USDTAmt * 8000 / 10000, amountsOutMin[1]);
        investPNGUSDT(USDTAmt * 1000 / 10000, amountsOutMin[2]);
        investLYDDAI(USDTAmt * 1000 / 10000, amountsOutMin[3]);

        // // Rebalancing invest
        // if (
        //     JOEUSDCTargetPool > pools[0] &&
        //     PNGUSDTTargetPool > pools[1] &&
        //     LYDDAITargetPool > pools[2]
        // ) {
        //     investJOEUSDC(JOEUSDCTargetPool - pools[0], amountsOutMin[3]);
        //     investPNGUSDT(PNGUSDTTargetPool - pools[1], amountsOutMin[4]);
        //     investLYDDAI(LYDDAITargetPool - pools[2], amountsOutMin[5]);
        // } else {
        //     uint furthest;
        //     uint farmIndex;
        //     uint diff;

        //     if (JOEUSDCTargetPool > pools[0]) {
        //         diff = JOEUSDCTargetPool - pools[0];
        //         furthest = diff;
        //         farmIndex = 0;
        //     }
        //     if (PNGUSDTTargetPool > pools[1]) {
        //         diff = PNGUSDTTargetPool - pools[1];
        //         if (diff > furthest) {
        //             furthest = diff;
        //             farmIndex = 1;
        //         }
        //     }
        //     if (LYDDAITargetPool > pools[2]) {
        //         diff = LYDDAITargetPool - pools[2];
        //         if (diff > furthest) {
        //             furthest = diff;
        //             farmIndex = 2;
        //         }
        //     }

        //     if (farmIndex == 0) investJOEUSDC(USDTAmt, amountsOutMin[1]);
        //     else if (farmIndex == 1) investPNGUSDT(USDTAmt, amountsOutMin[2]);
        //     else investLYDDAI(USDTAmt, amountsOutMin[3]);
        // }

        emit TargetComposition(JOEUSDCTargetPool, PNGUSDTTargetPool, LYDDAITargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2]);
    }

    function investJOEUSDC(uint USDTAmt, uint amountOutMin) private {
        uint USDCAmt = curve.exchange_underlying(
            getCurveId(address(USDT)), getCurveId(address(USDC)), USDTAmt, USDTAmt * 99 / 100
        );

        uint halfUSDC = USDCAmt / 2;
        uint JOEAmt = joeRouter.swapExactTokensForTokens(
            halfUSDC, amountOutMin, getPath(address(USDC), address(JOE)), address(this), block.timestamp
        )[1];

        (,,uint JOEUSDCAmt) = joeRouter.addLiquidity(
            address(JOE), address(USDC), JOEAmt, halfUSDC, 0, 0, address(this), block.timestamp
        );

        JOEUSDCVault.deposit(JOEUSDCAmt);

        emit InvestJOEUSDC(USDTAmt, JOEUSDCAmt);
    }

    function investPNGUSDT(uint USDTAmt, uint amountOutMin) private {
        uint halfUSDT = USDTAmt / 2;
        uint PNGAmt = pngRouter.swapExactTokensForTokens(
            halfUSDT, amountOutMin, getPath(address(USDT), address(PNG)), address(this), block.timestamp
        )[1];

        (,,uint PNGUSDTAmt) = pngRouter.addLiquidity(
            address(PNG), address(USDT), PNGAmt, halfUSDT, 0, 0, address(this), block.timestamp
        );

        PNGUSDTVault.deposit(PNGUSDTAmt);

        emit InvestPNGUSDT(USDTAmt, PNGUSDTAmt);
    }

    function investLYDDAI(uint USDTAmt, uint amountOutMin) private {
        uint DAIAmt = curve.exchange_underlying(
            getCurveId(address(USDT)), getCurveId(address(DAI)), USDTAmt, USDTAmt * 1e12 * 99 / 100
        );

        uint halfDAI = DAIAmt / 2;
        uint LYDAmt = lydRouter.swapExactTokensForTokens(
            halfDAI, amountOutMin, getPath(address(DAI), address(LYD)), address(this), block.timestamp
        )[1];

        (,,uint LYDDAIAmt) = lydRouter.addLiquidity(
            address(LYD), address(DAI), LYDAmt, halfDAI, 0, 0, address(this), block.timestamp
        );
        
        LYDDAIVault.deposit(LYDDAIAmt);

        emit InvestLYDDAI(USDTAmt, LYDDAIAmt);
    }

    /// @param amount Amount to withdraw in USD
    function withdraw(uint amount, uint[] calldata amountsOutMin) external onlyVault returns (uint USDTAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();

        uint USDTAmtBefore = USDT.balanceOf(address(this));
        withdrawJOEUSDC(sharePerc, amountsOutMin[1]);
        withdrawPNGUSDT(sharePerc, amountsOutMin[2]);
        withdrawLYDDAI(sharePerc, amountsOutMin[3]);
        USDTAmt = USDT.balanceOf(address(this)) - USDTAmtBefore;

        USDT.safeTransfer(vault, USDTAmt);

        emit Withdraw(amount, USDTAmt);
    }

    function withdrawJOEUSDC(uint sharePerc, uint amountOutMin) private {
        uint JOEUSDCAmt = JOEUSDCVault.withdraw(JOEUSDCVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint JOEAmt, uint USDCAmt) = joeRouter.removeLiquidity(
            address(JOE), address(USDC), JOEUSDCAmt, 0, 0, address(this), block.timestamp
        );

        USDCAmt += joeRouter.swapExactTokensForTokens(
            JOEAmt, amountOutMin, getPath(address(JOE), address(USDC)), address(this), block.timestamp
        )[1];
        
        uint USDTAmt = curve.exchange_underlying(
            getCurveId(address(USDC)), getCurveId(address(USDT)), USDCAmt, USDCAmt * 99 / 100
        );

        emit WithdrawJOEUSDC(JOEUSDCAmt, USDTAmt);
    }

    function withdrawPNGUSDT(uint sharePerc, uint amountOutMin) private {
        uint PNGUSDTAmt = PNGUSDTVault.withdraw(PNGUSDTVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint PNGAmt, uint USDTAmt) = pngRouter.removeLiquidity(
            address(PNG), address(USDT), PNGUSDTAmt, 0, 0, address(this), block.timestamp
        );

        USDTAmt += pngRouter.swapExactTokensForTokens(
            PNGAmt, amountOutMin, getPath(address(PNG), address(USDT)), address(this), block.timestamp
        )[1];

        emit WithdrawPNGUSDT(PNGUSDTAmt, USDTAmt);
    }

    function withdrawLYDDAI(uint sharePerc, uint amountOutMin) private {
        uint LYDDAIAmt = LYDDAIVault.withdraw(LYDDAIVault.balanceOf(address(this)) * sharePerc / 1e18);

        (uint LYDAmt, uint DAIAmt) = lydRouter.removeLiquidity(
            address(LYD), address(DAI), LYDDAIAmt, 0, 0, address(this), block.timestamp
        );

        DAIAmt += lydRouter.swapExactTokensForTokens(
            LYDAmt, amountOutMin, getPath(address(LYD), address(DAI)), address(this), block.timestamp
        )[1];

        uint USDTAmt = curve.exchange_underlying(
            getCurveId(address(DAI)), getCurveId(address(USDT)), DAIAmt, (DAIAmt / 1e12) * 99 / 100
        );

        emit WithdrawLYDDAI(LYDDAIAmt, USDTAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        withdrawJOEUSDC(1e18, 0);
        withdrawPNGUSDT(1e18, 0);
        withdrawLYDDAI(1e18, 0);

        uint USDTAmt = USDT.balanceOf(address(this));
        USDT.safeTransfer(vault, USDTAmt);

        emit EmergencyWithdraw(USDTAmt);
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

    function getCurveId(address token) private pure returns (int128) {
        if (token == address(USDT)) return 2;
        else if (token == address(USDC)) return 1;
        else return 0; // DAI
    }

    function getJOEUSDCPool() private view returns (uint) {
        uint JOEUSDCVaultPool = JOEUSDCVault.getAllPoolInUSD();
        if (JOEUSDCVaultPool == 0) return 0;
        return JOEUSDCVaultPool * JOEUSDCVault.balanceOf(address(this)) / JOEUSDCVault.totalSupply();
    }

    function getPNGUSDTPool() private view returns (uint) {
        uint PNGUSDTVaultPool = PNGUSDTVault.getAllPoolInUSD();
        if (PNGUSDTVaultPool == 0) return 0;
        return PNGUSDTVaultPool * PNGUSDTVault.balanceOf(address(this)) / PNGUSDTVault.totalSupply();
    }

    function getLYDDAIPool() private view returns (uint) {
        uint LYDDAIVaultPool = LYDDAIVault.getAllPoolInUSD();
        if (LYDDAIVaultPool == 0) return 0;
        return LYDDAIVaultPool * LYDDAIVault.balanceOf(address(this)) / LYDDAIVault.totalSupply();
    }

    function getEachPool() public view returns (uint[] memory pools) {
        pools = new uint[](3);
        pools[0] = getJOEUSDCPool();
        pools[1] = getPNGUSDTPool();
        pools[2] = getLYDDAIPool();
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint[] memory pools = getEachPool();
        return pools[0] + pools[1] + pools[2];
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