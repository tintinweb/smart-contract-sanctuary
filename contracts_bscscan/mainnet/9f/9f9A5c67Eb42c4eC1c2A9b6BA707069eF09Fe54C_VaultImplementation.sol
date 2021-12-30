// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IVToken.sol';
import './IComptroller.sol';
import '../token/IERC20.sol';
import '../library/SafeERC20.sol';
import '../utils/NameVersion.sol';

contract VaultImplementation is NameVersion {

    using SafeERC20 for IERC20;

    uint256 constant ONE = 1e18;

    address public immutable pool;

    address public immutable comptroller;

    address public immutable vTokenETH;

    address public immutable tokenXVS;

    uint256 public immutable vaultLiquidityMultiplier;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'VaultImplementation: only pool');
        _;
    }

    constructor (
        address pool_,
        address comptroller_,
        address vTokenETH_,
        uint256 vaultLiquidityMultiplier_
    ) NameVersion('VaultImplementation', '3.0.1') {
        pool = pool_;
        comptroller = comptroller_;
        vTokenETH = vTokenETH_;
        vaultLiquidityMultiplier = vaultLiquidityMultiplier_;
        tokenXVS = IComptroller(comptroller_).getXVSAddress();

        require(
            IComptroller(comptroller_).isComptroller(),
            'VaultImplementation.constructor: not comptroller'
        );
        require(
            IVToken(vTokenETH_).isVToken(),
            'VaultImplementation.constructor: not vToken'
        );
        require(
            keccak256(abi.encodePacked(IVToken(vTokenETH_).symbol())) == keccak256(abi.encodePacked('vBNB')),
            'VaultImplementation.constructor: not vBNB'
        );
    }

    function getVaultLiquidity() external view returns (uint256) {
        (uint256 err, uint256 liquidity, uint256 shortfall) = IComptroller(comptroller).getAccountLiquidity(address(this));
        require(err == 0 && shortfall == 0, 'VaultImplementation.getVaultLiquidity: error');
        return liquidity * vaultLiquidityMultiplier / ONE;
    }

    function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens)
    external view returns (uint256)
    {
        (uint256 err, uint256 liquidity, uint256 shortfall) =
        IComptroller(comptroller).getHypotheticalAccountLiquidity(address(this), vTokenModify, redeemVTokens, 0);
        require(err == 0 && shortfall == 0, 'VaultImplementation.getHypotheticalVaultLiquidity: error');
        return liquidity * vaultLiquidityMultiplier / ONE;
    }

    function isInMarket(address vToken) public view returns (bool) {
        return IComptroller(comptroller).checkMembership(address(this), vToken);
    }

    function getMarketsIn() external view returns (address[] memory) {
        return IComptroller(comptroller).getAssetsIn(address(this));
    }

    function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance) {
        vTokenBalance = IVToken(vToken).balanceOf(address(this));
        if (vTokenBalance != 0) {
            uint256 exchangeRate = IVToken(vToken).exchangeRateStored();
            underlyingBalance = vTokenBalance * exchangeRate / ONE;
        }
    }

    function enterMarket(address vToken) external _onlyPool_ {
        if (vToken != vTokenETH) {
            IERC20 underlying = IERC20(IVToken(vToken).underlying());
            uint256 allowance = underlying.allowance(address(this), vToken);
            if (allowance != type(uint256).max) {
                if (allowance != 0) {
                    underlying.safeApprove(vToken, 0);
                }
                underlying.safeApprove(vToken, type(uint256).max);
            }
        }
        address[] memory markets = new address[](1);
        markets[0] = vToken;
        uint256[] memory res = IComptroller(comptroller).enterMarkets(markets);
        require(res[0] == 0, 'VaultImplementation.enterMarket: error');
    }

    function exitMarket(address vToken) external _onlyPool_ {
        if (vToken != vTokenETH) {
            IERC20 underlying = IERC20(IVToken(vToken).underlying());
            uint256 allowance = underlying.allowance(address(this), vToken);
            if (allowance != 0) {
                underlying.safeApprove(vToken, 0);
            }
        }
        require(
            IComptroller(comptroller).exitMarket(vToken) == 0,
            'VaultImplementation.exitMarket: error'
        );
    }

    function mint() external payable _onlyPool_ {
        IVToken(vTokenETH).mint{value: msg.value}();
    }

    function mint(address vToken, uint256 amount) external _onlyPool_ {
        require(IVToken(vToken).mint(amount) == 0, 'VaultImplementation.mint: error');
    }

    function redeem(address vToken, uint256 amount) public _onlyPool_ {
        require(IVToken(vToken).redeem(amount) == 0, 'VaultImplementation.redeem: error');
    }

    function redeemAll(address vToken) external _onlyPool_ {
        uint256 balance = IVToken(vToken).balanceOf(address(this));
        if (balance != 0) {
            redeem(vToken, balance);
        }
    }

    function redeemUnderlying(address vToken, uint256 amount) external _onlyPool_ {
        require(
            IVToken(vToken).redeemUnderlying(amount) == 0,
            'VaultImplementation.redeemUnderlying: error'
        );
    }

    function transfer(address underlying, address to, uint256 amount) public _onlyPool_ {
        if (underlying == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'VaultImplementation.transfer: send ETH fail');
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    function transferAll(address underlying, address to) external _onlyPool_ returns (uint256) {
        uint256 amount = underlying == address(0) ?
                         address(this).balance :
                         IERC20(underlying).balanceOf(address(this));
        transfer(underlying, to, amount);
        return amount;
    }

    function claimVenus(address account) external _onlyPool_ {
        IComptroller(comptroller).claimVenus(address(this));
        uint256 balance = IERC20(tokenXVS).balanceOf(address(this));
        if (balance != 0) {
            IERC20(tokenXVS).safeTransfer(account, balance);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVToken {

    function isVToken() external view returns (bool);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function comptroller() external view returns (address);

    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable;

    function mint(uint256 amount) external returns (uint256 error);

    function redeem(uint256 amount) external returns (uint256 error);

    function redeemUnderlying(uint256 amount) external returns (uint256 error);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IComptroller {

    function isComptroller() external view returns (bool);

    function checkMembership(address account, address vToken) external view returns (bool);

    function getAssetsIn(address account) external view returns (address[] memory);

    function getAccountLiquidity(address account) external view returns (uint256 error, uint256 liquidity, uint256 shortfall);

    function getHypotheticalAccountLiquidity(address account, address vTokenModify, uint256 redeemTokens, uint256 borrowAmount)
    external view returns (uint256 error, uint256 liquidity, uint256 shortfall);

    function enterMarkets(address[] memory vTokens) external returns (uint256[] memory errors);

    function exitMarket(address vToken) external returns (uint256 error);

    function getXVSAddress() external view returns (address);

    function claimVenus(address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "./Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}