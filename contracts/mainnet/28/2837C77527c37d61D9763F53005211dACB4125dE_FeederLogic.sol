/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.2;


interface IPlatformIntegration {
    /**
     * @dev Deposit the given bAsset to Lending platform
     * @param _bAsset bAsset address
     * @param _amount Amount to deposit
     */
    function deposit(
        address _bAsset,
        uint256 _amount,
        bool isTokenFeeCharged
    ) external returns (uint256 quantityDeposited);

    /**
     * @dev Withdraw given bAsset from Lending platform
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        bool _hasTxFee
    ) external;

    /**
     * @dev Withdraw given bAsset from Lending platform
     */
    function withdraw(
        address _receiver,
        address _bAsset,
        uint256 _amount,
        uint256 _totalAmount,
        bool _hasTxFee
    ) external;

    /**
     * @dev Withdraw given bAsset from the cache
     */
    function withdrawRaw(
        address _receiver,
        address _bAsset,
        uint256 _amount
    ) external;

    /**
     * @dev Returns the current balance of the given bAsset
     */
    function checkBalance(address _bAsset) external returns (uint256 balance);

    /**
     * @dev Returns the pToken
     */
    function bAssetToPToken(address _bAsset) external returns (address pToken);
}

struct BassetPersonal {
    // Address of the bAsset
    address addr;
    // Address of the bAsset
    address integrator;
    // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
    bool hasTxFee; // takes a byte in storage
    // Status of the bAsset
    BassetStatus status;
}

struct BassetData {
    // 1 Basset * ratio / ratioScale == x Masset (relative value)
    // If ratio == 10e8 then 1 bAsset = 10 mAssets
    // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
    uint128 ratio;
    // Amount of the Basset that is held in Collateral
    uint128 vaultBalance;
}

abstract contract IMasset {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        virtual
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        virtual
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view virtual returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external virtual returns (uint256 outputQuantity);

    function redeemMasset(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external virtual returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external virtual returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        virtual
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view virtual returns (uint256 mAssetAmount);

    // Views
    function getBasket() external view virtual returns (bool, bool);

    function getBasset(address _token)
        external
        view
        virtual
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        virtual
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    function bAssetIndexes(address) external view virtual returns (uint8);

    // SavingsManager
    function collectInterest() external virtual returns (uint256 swapFeesGained, uint256 newSupply);

    function collectPlatformInterest()
        external
        virtual
        returns (uint256 mintAmount, uint256 newSupply);

    // Admin
    function setCacheSize(uint256 _cacheSize) external virtual;

    function upgradeForgeValidator(address _newForgeValidator) external virtual;

    function setFees(uint256 _swapFee, uint256 _redemptionFee) external virtual;

    function setTransferFeesFlag(address _bAsset, bool _flag) external virtual;

    function migrateBassets(address[] calldata _bAssets, address _newIntegration) external virtual;
}

// Status of the Basset - has it broken its peg?
enum BassetStatus {
    Default,
    Normal,
    BrokenBelowPeg,
    BrokenAbovePeg,
    Blacklisted,
    Liquidating,
    Liquidated,
    Failed
}

struct BasketState {
    bool undergoingRecol;
    bool failed;
}

struct InvariantConfig {
    uint256 a;
    WeightLimits limits;
}

struct WeightLimits {
    uint128 min;
    uint128 max;
}

struct FeederConfig {
    uint256 supply;
    uint256 a;
    WeightLimits limits;
}

struct AmpData {
    uint64 initialA;
    uint64 targetA;
    uint64 rampStartTime;
    uint64 rampEndTime;
}

struct FeederData {
    uint256 swapFee;
    uint256 redemptionFee;
    uint256 govFee;
    uint256 pendingFees;
    uint256 cacheSize;
    BassetPersonal[] bAssetPersonal;
    BassetData[] bAssetData;
    AmpData ampData;
    WeightLimits weightLimits;
}

struct AssetData {
    uint8 idx;
    uint256 amt;
    BassetPersonal personal;
}

struct Asset {
    uint8 idx;
    address addr;
    bool exists;
}

library Root {
    /**
     * @dev Returns the square root of a given number
     * @param x Input
     * @return y Square root of Input
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint256(r < r1 ? r : r1);
        }
    }
}

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

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

library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

library MassetHelpers {
    using SafeERC20 for IERC20;

    function transferReturnBalance(
        address _sender,
        address _recipient,
        address _bAsset,
        uint256 _qty
    ) internal returns (uint256 receivedQty, uint256 recipientBalance) {
        uint256 balBefore = IERC20(_bAsset).balanceOf(_recipient);
        IERC20(_bAsset).safeTransferFrom(_sender, _recipient, _qty);
        recipientBalance = IERC20(_bAsset).balanceOf(_recipient);
        receivedQty = recipientBalance - balBefore;
    }

    function safeInfiniteApprove(address _asset, address _spender) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, 2**256 - 1);
    }
}

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e38 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                  RATIO FUNCS
    ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio) internal pure returns (uint256) {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x * ratio;
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled + RATIO_SCALE - 1;
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil / RATIO_SCALE;
    }

    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        // e.g. 1e14 * 1e8 = 1e22
        // return 1e22 / 1e12 = 1e10
        return (x * RATIO_SCALE) / ratio;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

// External
// Internal
// Libs
/**
 * @title   FeederLogic
 * @author  mStable
 * @notice  Logic contract for feeder pools that calculates trade output and updates core state.
 *          Includes modular invariant application code applying the StableSwap invariant first designed
 *          by Curve Finance and derived for mStable application in MIP-8 (https://mips.mstable.org/MIPS/mip-8)
 * @dev     VERSION: 1.0
 *          DATE:    2021-03-01
 */
library FeederLogic {
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant A_PRECISION = 100;

    /***************************************
                    MINT
    ****************************************/

    /**
     * @notice Transfers token in, updates internal balances and computes the fpToken output
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _input                Data on the bAsset to deposit for the minted fpToken.
     * @param _inputQuantity        Quantity in input token units.
     * @param _minOutputQuantity    Minimum fpToken quantity to be minted. This protects against slippage.
     * @return mintOutput           Quantity of fpToken minted from the deposited bAsset.
     */
    function mint(
        FeederData storage _data,
        FeederConfig calldata _config,
        Asset calldata _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity
    ) external returns (uint256 mintOutput) {
        BassetData[] memory cachedBassetData = _data.bAssetData;
        AssetData memory inputData =
            _transferIn(_data, _config, cachedBassetData, _input, _inputQuantity);
        // Validation should be after token transfer, as real input amt is unknown before
        mintOutput = computeMint(cachedBassetData, inputData.idx, inputData.amt, _config);
        require(mintOutput >= _minOutputQuantity, "Mint quantity < min qty");
    }

    /**
     * @notice Transfers tokens in, updates internal balances and computes the fpToken output.
     * Only fAsset & mAsset are supported in this path.
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _indices              Non-duplicate addresses of the bAssets to deposit for the minted fpToken.
     * @param _inputQuantities      Quantity of each input in input token units.
     * @param _minOutputQuantity    Minimum fpToken quantity to be minted. This protects against slippage.
     * @return mintOutput           Quantity of fpToken minted from the deposited bAsset.
     */
    function mintMulti(
        FeederData storage _data,
        FeederConfig calldata _config,
        uint8[] calldata _indices,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity
    ) external returns (uint256 mintOutput) {
        uint256 len = _indices.length;
        uint256[] memory quantitiesDeposited = new uint256[](len);
        // Load bAssets from storage into memory
        BassetData[] memory allBassets = _data.bAssetData;
        uint256 maxCache = _getCacheDetails(_data, _config.supply);
        // Transfer the Bassets to the integrator & update storage
        for (uint256 i = 0; i < len; i++) {
            if (_inputQuantities[i] > 0) {
                uint8 idx = _indices[i];
                BassetData memory bData = allBassets[idx];
                quantitiesDeposited[i] = _depositTokens(
                    _data.bAssetPersonal[idx],
                    bData.ratio,
                    _inputQuantities[i],
                    maxCache
                );

                _data.bAssetData[idx].vaultBalance =
                    bData.vaultBalance +
                    SafeCast.toUint128(quantitiesDeposited[i]);
            }
        }
        // Validate the proposed mint, after token transfer
        mintOutput = computeMintMulti(allBassets, _indices, quantitiesDeposited, _config);
        require(mintOutput >= _minOutputQuantity, "Mint quantity < min qty");
        require(mintOutput > 0, "Zero mAsset quantity");
    }

    /***************************************
                    SWAP
    ****************************************/

    /**
     * @notice Swaps two assets - either internally between fAsset<>mAsset, or between fAsset<>mpAsset by
     * first routing through the mAsset pool.
     * @param _data              Feeder pool storage state
     * @param _config            Core config for use in the invariant validator
     * @param _input             Data on bAsset to deposit
     * @param _output            Data on bAsset to withdraw
     * @param _inputQuantity     Units of input bAsset to swap in
     * @param _minOutputQuantity Minimum quantity of the swap output asset. This protects against slippage
     * @param _recipient         Address to transfer output asset to
     * @return swapOutput        Quantity of output asset returned from swap
     * @return localFee          Fee paid, in fpToken terms
     */
    function swap(
        FeederData storage _data,
        FeederConfig calldata _config,
        Asset calldata _input,
        Asset calldata _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 swapOutput, uint256 localFee) {
        BassetData[] memory cachedBassetData = _data.bAssetData;

        AssetData memory inputData =
            _transferIn(_data, _config, cachedBassetData, _input, _inputQuantity);
        // 1. [f/mAsset ->][ f/mAsset]               : Y - normal in, SWAP, normal out
        // 3. [mpAsset -> mAsset][ -> fAsset]        : Y - mint in  , SWAP, normal out
        if (_output.exists) {
            (swapOutput, localFee) = _swapLocal(
                _data,
                _config,
                cachedBassetData,
                inputData,
                _output,
                _minOutputQuantity,
                _recipient
            );
        }
        // 2. [fAsset ->][ mAsset][ -> mpAsset]      : Y - normal in, SWAP, mpOut
        else {
            address mAsset = _data.bAssetPersonal[0].addr;
            (swapOutput, localFee) = _swapLocal(
                _data,
                _config,
                cachedBassetData,
                inputData,
                Asset(0, mAsset, true),
                0,
                address(this)
            );
            swapOutput = IMasset(mAsset).redeem(
                _output.addr,
                swapOutput,
                _minOutputQuantity,
                _recipient
            );
        }
    }

    /***************************************
                    REDEEM
    ****************************************/

    /**
     * @notice Burns a specified quantity of the senders fpToken in return for a bAsset. The output amount is derived
     * from the invariant. Supports redemption into either the fAsset, mAsset or assets in the mAsset basket.
     * @param _data              Feeder pool storage state
     * @param _config            Core config for use in the invariant validator
     * @param _output            Data on bAsset to withdraw
     * @param _fpTokenQuantity   Quantity of fpToken to burn
     * @param _minOutputQuantity Minimum bAsset quantity to receive for the burnt fpToken. This protects against slippage.
     * @param _recipient         Address to transfer the withdrawn bAssets to.
     * @return outputQuantity    Quanity of bAsset units received for the burnt fpToken
     * @return localFee          Fee paid, in fpToken terms
     */
    function redeem(
        FeederData storage _data,
        FeederConfig calldata _config,
        Asset calldata _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity, uint256 localFee) {
        if (_output.exists) {
            (outputQuantity, localFee) = _redeemLocal(
                _data,
                _config,
                _output,
                _fpTokenQuantity,
                _minOutputQuantity,
                _recipient
            );
        } else {
            address mAsset = _data.bAssetPersonal[0].addr;
            (outputQuantity, localFee) = _redeemLocal(
                _data,
                _config,
                Asset(0, mAsset, true),
                _fpTokenQuantity,
                0,
                address(this)
            );
            outputQuantity = IMasset(mAsset).redeem(
                _output.addr,
                outputQuantity,
                _minOutputQuantity,
                _recipient
            );
        }
    }

    /**
     * @dev Credits a recipient with a proportionate amount of bAssets, relative to current vault
     * balance levels and desired fpToken quantity. Burns the fpToken as payment. Only fAsset & mAsset are supported in this path.
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _inputQuantity        Quantity of fpToken to redeem
     * @param _minOutputQuantities  Min units of output to receive
     * @param _recipient            Address to credit the withdrawn bAssets
     * @return scaledFee            Fee collected in fpToken terms
     * @return outputs              Array of output asset addresses
     * @return outputQuantities     Array of output asset quantities
     */
    function redeemProportionately(
        FeederData storage _data,
        FeederConfig calldata _config,
        uint256 _inputQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    )
        external
        returns (
            uint256 scaledFee,
            address[] memory outputs,
            uint256[] memory outputQuantities
        )
    {
        // Calculate mAsset redemption quantities
        scaledFee = _inputQuantity.mulTruncate(_data.redemptionFee);
        // cache = (config.supply - inputQuantity) * 0.2
        uint256 maxCache = _getCacheDetails(_data, _config.supply - _inputQuantity);

        // Load the bAsset data from storage into memory
        BassetData[] memory allBassets = _data.bAssetData;
        uint256 len = allBassets.length;
        outputs = new address[](len);
        outputQuantities = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            // Get amount out, proportionate to redemption quantity
            uint256 amountOut =
                (allBassets[i].vaultBalance * (_inputQuantity - scaledFee)) / _config.supply;
            require(amountOut > 1, "Output == 0");
            amountOut -= 1;
            require(amountOut >= _minOutputQuantities[i], "bAsset qty < min qty");
            // Set output in array
            (outputQuantities[i], outputs[i]) = (amountOut, _data.bAssetPersonal[i].addr);
            // Transfer the bAsset to the recipient
            _withdrawTokens(
                amountOut,
                _data.bAssetPersonal[i],
                allBassets[i],
                _recipient,
                maxCache
            );
            // Reduce vaultBalance
            _data.bAssetData[i].vaultBalance =
                allBassets[i].vaultBalance -
                SafeCast.toUint128(amountOut);
        }
    }

    /**
     * @dev Credits a recipient with a certain quantity of selected bAssets, in exchange for burning the
     *      relative fpToken quantity from the sender. Only fAsset & mAsset (0,1) are supported in this path.
     * @param _data                 Feeder pool storage state
     * @param _config               Core config for use in the invariant validator
     * @param _indices              Indices of the bAssets to receive
     * @param _outputQuantities     Units of the bAssets to receive
     * @param _maxInputQuantity     Maximum fpToken quantity to burn for the received bAssets. This protects against slippage.
     * @param _recipient            Address to receive the withdrawn bAssets
     * @return fpTokenQuantity      Quantity of fpToken units to burn as payment
     * @return localFee             Fee collected, in fpToken terms
     */
    function redeemExactBassets(
        FeederData storage _data,
        FeederConfig memory _config,
        uint8[] calldata _indices,
        uint256[] calldata _outputQuantities,
        uint256 _maxInputQuantity,
        address _recipient
    ) external returns (uint256 fpTokenQuantity, uint256 localFee) {
        // Load bAsset data from storage to memory
        BassetData[] memory allBassets = _data.bAssetData;

        // Validate redemption
        uint256 fpTokenRequired =
            computeRedeemExact(allBassets, _indices, _outputQuantities, _config);
        fpTokenQuantity = fpTokenRequired.divPrecisely(1e18 - _data.redemptionFee);
        localFee = fpTokenQuantity - fpTokenRequired;
        require(fpTokenQuantity > 0, "Must redeem some mAssets");
        fpTokenQuantity += 1;
        require(fpTokenQuantity <= _maxInputQuantity, "Redeem mAsset qty > max quantity");

        // Burn the full amount of Masset
        uint256 maxCache = _getCacheDetails(_data, _config.supply - fpTokenQuantity);
        // Transfer the Bassets to the recipient
        for (uint256 i = 0; i < _outputQuantities.length; i++) {
            _withdrawTokens(
                _outputQuantities[i],
                _data.bAssetPersonal[_indices[i]],
                allBassets[_indices[i]],
                _recipient,
                maxCache
            );
            _data.bAssetData[_indices[i]].vaultBalance =
                allBassets[_indices[i]].vaultBalance -
                SafeCast.toUint128(_outputQuantities[i]);
        }
    }

    /***************************************
                FORGING - INTERNAL
    ****************************************/

    /**
     * @dev Transfers an asset in and updates vault balance. Supports fAsset, mAsset and mpAsset.
     * Transferring an mpAsset requires first a mint in the main pool, and consequent depositing of
     * the mAsset.
     */
    function _transferIn(
        FeederData storage _data,
        FeederConfig memory _config,
        BassetData[] memory _cachedBassetData,
        Asset memory _input,
        uint256 _inputQuantity
    ) internal returns (AssetData memory inputData) {
        // fAsset / mAsset transfers
        if (_input.exists) {
            BassetPersonal memory personal = _data.bAssetPersonal[_input.idx];
            uint256 amt =
                _depositTokens(
                    personal,
                    _cachedBassetData[_input.idx].ratio,
                    _inputQuantity,
                    _getCacheDetails(_data, _config.supply)
                );
            inputData = AssetData(_input.idx, amt, personal);
        }
        // mpAsset transfers
        else {
            inputData = _mpMint(
                _data,
                _input,
                _inputQuantity,
                _getCacheDetails(_data, _config.supply)
            );
            require(inputData.amt > 0, "Must mint something from mp");
        }
        _data.bAssetData[inputData.idx].vaultBalance =
            _cachedBassetData[inputData.idx].vaultBalance +
            SafeCast.toUint128(inputData.amt);
    }

    /**
     * @dev Mints an asset in the main mAsset pool. Input asset must be supported by the mAsset
     * or else the call will revert. After minting, check if the balance exceeds the cache upper limit
     * and consequently deposit if necessary.
     */
    function _mpMint(
        FeederData storage _data,
        Asset memory _input,
        uint256 _inputQuantity,
        uint256 _maxCache
    ) internal returns (AssetData memory mAssetData) {
        mAssetData = AssetData(0, 0, _data.bAssetPersonal[0]);
        IERC20(_input.addr).safeTransferFrom(msg.sender, address(this), _inputQuantity);

        address integrator =
            mAssetData.personal.integrator == address(0)
                ? address(this)
                : mAssetData.personal.integrator;

        uint256 balBefore = IERC20(mAssetData.personal.addr).balanceOf(integrator);
        // Mint will revert if the _input.addr is not whitelisted on that mAsset
        IMasset(mAssetData.personal.addr).mint(_input.addr, _inputQuantity, 0, integrator);
        uint256 balAfter = IERC20(mAssetData.personal.addr).balanceOf(integrator);
        mAssetData.amt = balAfter - balBefore;

        // Route the mAsset to platform integration
        if (integrator != address(this)) {
            if (balAfter > _maxCache) {
                uint256 delta = balAfter - (_maxCache / 2);
                IPlatformIntegration(integrator).deposit(mAssetData.personal.addr, delta, false);
            }
        }
    }

    /**
     * @dev Performs a swap between fAsset and mAsset. If the output is an mAsset, do not
     * charge the swap fee.
     */
    function _swapLocal(
        FeederData storage _data,
        FeederConfig memory _config,
        BassetData[] memory _cachedBassetData,
        AssetData memory _inputData,
        Asset memory _output,
        uint256 _minOutputQuantity,
        address _recipient
    ) internal returns (uint256 swapOutput, uint256 scaledFee) {
        // Validate the swap
        (swapOutput, scaledFee) = computeSwap(
            _cachedBassetData,
            _inputData.idx,
            _output.idx,
            _inputData.amt,
            _output.idx == 0 ? 0 : _data.swapFee,
            _config
        );
        require(swapOutput >= _minOutputQuantity, "Output qty < minimum qty");
        require(swapOutput > 0, "Zero output quantity");
        // Settle the swap
        _withdrawTokens(
            swapOutput,
            _data.bAssetPersonal[_output.idx],
            _cachedBassetData[_output.idx],
            _recipient,
            _getCacheDetails(_data, _config.supply)
        );
        // Decrease output bal
        _data.bAssetData[_output.idx].vaultBalance =
            _cachedBassetData[_output.idx].vaultBalance -
            SafeCast.toUint128(swapOutput);
    }

    /**
     * @dev Performs a local redemption into either fAsset or mAsset.
     */
    function _redeemLocal(
        FeederData storage _data,
        FeederConfig memory _config,
        Asset memory _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) internal returns (uint256 outputQuantity, uint256 scaledFee) {
        BassetData[] memory allBassets = _data.bAssetData;
        // Subtract the redemption fee
        scaledFee = _fpTokenQuantity.mulTruncate(_data.redemptionFee);
        // Calculate redemption quantities
        outputQuantity = computeRedeem(
            allBassets,
            _output.idx,
            _fpTokenQuantity - scaledFee,
            _config
        );
        require(outputQuantity >= _minOutputQuantity, "bAsset qty < min qty");
        require(outputQuantity > 0, "Output == 0");

        // Transfer the bAssets to the recipient
        _withdrawTokens(
            outputQuantity,
            _data.bAssetPersonal[_output.idx],
            allBassets[_output.idx],
            _recipient,
            _getCacheDetails(_data, _config.supply - _fpTokenQuantity)
        );
        // Set vault balance
        _data.bAssetData[_output.idx].vaultBalance =
            allBassets[_output.idx].vaultBalance -
            SafeCast.toUint128(outputQuantity);
    }

    /**
     * @dev Deposits a given asset to the system. If there is sufficient room for the asset
     * in the cache, then just transfer, otherwise reset the cache to the desired mid level by
     * depositing the delta in the platform
     */
    function _depositTokens(
        BassetPersonal memory _bAsset,
        uint256 _bAssetRatio,
        uint256 _quantity,
        uint256 _maxCache
    ) internal returns (uint256 quantityDeposited) {
        // 0. If integration is 0, short circuit
        if (_bAsset.integrator == address(0)) {
            (uint256 received, ) =
                MassetHelpers.transferReturnBalance(
                    msg.sender,
                    address(this),
                    _bAsset.addr,
                    _quantity
                );
            return received;
        }

        // 1 - Send all to PI, using the opportunity to get the cache balance and net amount transferred
        uint256 cacheBal;
        (quantityDeposited, cacheBal) = MassetHelpers.transferReturnBalance(
            msg.sender,
            _bAsset.integrator,
            _bAsset.addr,
            _quantity
        );

        // 2 - Deposit X if necessary
        // 2.1 - Deposit if xfer fees
        if (_bAsset.hasTxFee) {
            uint256 deposited =
                IPlatformIntegration(_bAsset.integrator).deposit(
                    _bAsset.addr,
                    quantityDeposited,
                    true
                );

            return StableMath.min(deposited, quantityDeposited);
        }
        // 2.2 - Else Deposit X if Cache > %
        // This check is in place to ensure that any token with a txFee is rejected
        require(quantityDeposited == _quantity, "Asset not fully transferred");

        uint256 relativeMaxCache = _maxCache.divRatioPrecisely(_bAssetRatio);

        if (cacheBal > relativeMaxCache) {
            uint256 delta = cacheBal - (relativeMaxCache / 2);
            IPlatformIntegration(_bAsset.integrator).deposit(_bAsset.addr, delta, false);
        }
    }

    /**
     * @dev Withdraws a given asset from its platformIntegration. If there is sufficient liquidity
     * in the cache, then withdraw from there, otherwise withdraw from the lending market and reset the
     * cache to the mid level.
     */
    function _withdrawTokens(
        uint256 _quantity,
        BassetPersonal memory _personal,
        BassetData memory _data,
        address _recipient,
        uint256 _maxCache
    ) internal {
        if (_quantity == 0) return;

        // 1.0 If there is no integrator, send from here
        if (_personal.integrator == address(0)) {
            // If this is part of a cross-swap or cross-redeem, and there is no
            // integrator.. then we don't need to transfer anywhere
            if (_recipient == address(this)) return;
            IERC20(_personal.addr).safeTransfer(_recipient, _quantity);
        }
        // 1.1 If txFee then short circuit - there is no cache
        else if (_personal.hasTxFee) {
            IPlatformIntegration(_personal.integrator).withdraw(
                _recipient,
                _personal.addr,
                _quantity,
                _quantity,
                true
            );
        }
        // 1.2. Else, withdraw from either cache or main vault
        else {
            uint256 cacheBal = IERC20(_personal.addr).balanceOf(_personal.integrator);
            // 2.1 - If balance b in cache, simply withdraw
            if (cacheBal >= _quantity) {
                IPlatformIntegration(_personal.integrator).withdrawRaw(
                    _recipient,
                    _personal.addr,
                    _quantity
                );
            }
            // 2.2 - Else reset the cache to X, or as far as possible
            //       - Withdraw X+b from platform
            //       - Send b to user
            else {
                uint256 relativeMidCache = _maxCache.divRatioPrecisely(_data.ratio) / 2;
                uint256 totalWithdrawal =
                    StableMath.min(
                        relativeMidCache + _quantity - cacheBal,
                        _data.vaultBalance - SafeCast.toUint128(cacheBal)
                    );

                IPlatformIntegration(_personal.integrator).withdraw(
                    _recipient,
                    _personal.addr,
                    _quantity,
                    totalWithdrawal,
                    false
                );
            }
        }
    }

    /**
     * @dev Gets the max cache size, given the supply of fpToken
     * @return maxCache    Max units of any given bAsset that should be held in the cache
     */
    function _getCacheDetails(FeederData storage _data, uint256 _supply)
        internal
        view
        returns (uint256 maxCache)
    {
        maxCache = (_supply * _data.cacheSize) / 1e18;
    }

    /***************************************
                    INVARIANT
    ****************************************/

    /**
     * @notice Compute the amount of fpToken received for minting
     * with `quantity` amount of bAsset index `i`.
     * @param _bAssets      Array of all bAsset Data
     * @param _i            Index of bAsset with which to mint
     * @param _rawInput     Raw amount of bAsset to use in mint
     * @param _config       Generalised FeederConfig stored externally
     * @return mintAmount   Quantity of fpTokens minted
     */
    function computeMint(
        BassetData[] memory _bAssets,
        uint8 _i,
        uint256 _rawInput,
        FeederConfig memory _config
    ) public pure returns (uint256 mintAmount) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        uint256 scaledInput = (_rawInput * _bAssets[_i].ratio) / 1e8;
        require(scaledInput > 1e6, "Must add > 1e6 units");
        // 3. Add deposit to x and sum
        x[_i] += scaledInput;
        sum += scaledInput;
        // 4. Finalise mint
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        mintAmount = _computeMintOutput(x, sum, k0, _config);
    }

    /**
     * @notice Compute the amount of fpToken received for minting
     * with the given array of inputs.
     * @param _bAssets      Array of all bAsset Data
     * @param _indices      Indexes of bAssets with which to mint
     * @param _rawInputs    Raw amounts of bAssets to use in mint
     * @param _config       Generalised FeederConfig stored externally
     * @return mintAmount   Quantity of fpTokens minted
     */
    function computeMintMulti(
        BassetData[] memory _bAssets,
        uint8[] memory _indices,
        uint256[] memory _rawInputs,
        FeederConfig memory _config
    ) public pure returns (uint256 mintAmount) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Add deposits to x and sum
        uint256 len = _indices.length;
        uint8 idx;
        uint256 scaledInput;
        for (uint256 i = 0; i < len; i++) {
            idx = _indices[i];
            scaledInput = (_rawInputs[i] * _bAssets[idx].ratio) / 1e8;
            x[idx] += scaledInput;
            sum += scaledInput;
        }
        // 4. Finalise mint
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        mintAmount = _computeMintOutput(x, sum, k0, _config);
    }

    /**
     * @notice Compute the amount of bAsset received for swapping
     * `quantity` amount of index `input_idx` to index `output_idx`.
     * @param _bAssets      Array of all bAsset Data
     * @param _i            Index of bAsset to swap IN
     * @param _o            Index of bAsset to swap OUT
     * @param _rawInput     Raw amounts of input bAsset to input
     * @param _feeRate      Swap fee rate to apply to output
     * @param _config       Generalised FeederConfig stored externally
     * @return bAssetOutputQuantity   Raw bAsset output quantity
     * @return scaledSwapFee          Swap fee collected, in fpToken terms
     */
    function computeSwap(
        BassetData[] memory _bAssets,
        uint8 _i,
        uint8 _o,
        uint256 _rawInput,
        uint256 _feeRate,
        FeederConfig memory _config
    ) public pure returns (uint256 bAssetOutputQuantity, uint256 scaledSwapFee) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Add deposits to x and sum
        uint256 scaledInput = (_rawInput * _bAssets[_i].ratio) / 1e8;
        require(scaledInput > 1e6, "Must add > 1e6 units");
        x[_i] += scaledInput;
        sum += scaledInput;
        // 4. Calc total fpToken q
        uint256 k1 = _invariant(x, sum, _config.a);
        scaledSwapFee = ((k1 - k0) * _feeRate) / 1e18;
        // 5. Calc output bAsset
        uint256 newOutputReserve = _solveInvariant(x, _config.a, _o, k0 + scaledSwapFee);
        // Convert swap fee to fpToken terms
        // fpFee = fee * s / k
        scaledSwapFee = (scaledSwapFee * _config.supply) / k0;
        uint256 output = x[_o] - newOutputReserve - 1;
        bAssetOutputQuantity = (output * 1e8) / _bAssets[_o].ratio;
        // 6. Check for bounds
        x[_o] -= output;
        sum -= output;
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
    }

    /**
     * @notice Compute the amount of bAsset index `i` received for
     * redeeming `quantity` amount of fpToken.
     * @param _bAssets              Array of all bAsset Data
     * @param _o                    Index of output bAsset
     * @param _netRedeemInput       Net amount of fpToken to redeem
     * @param _config               Generalised FeederConfig stored externally
     * @return rawOutputUnits       Raw bAsset output returned
     */
    function computeRedeem(
        BassetData[] memory _bAssets,
        uint8 _o,
        uint256 _netRedeemInput,
        FeederConfig memory _config
    ) public pure returns (uint256 rawOutputUnits) {
        require(_netRedeemInput > 1e6, "Must redeem > 1e6 units");
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        uint256 kFinal = (k0 * (_config.supply - _netRedeemInput)) / _config.supply + 1;
        // 3. Compute bAsset output
        uint256 newOutputReserve = _solveInvariant(x, _config.a, _o, kFinal);
        uint256 output = x[_o] - newOutputReserve - 1;
        rawOutputUnits = (output * 1e8) / _bAssets[_o].ratio;
        // 4. Check for max weight
        x[_o] -= output;
        sum -= output;
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
    }

    /**
     * @notice Compute the amount of fpToken required to redeem
     * a given selection of bAssets.
     * @param _bAssets          Array of all bAsset Data
     * @param _indices          Indexes of output bAssets
     * @param _rawOutputs       Desired raw bAsset outputs
     * @param _config           Generalised FeederConfig stored externally
     * @return redeemInput      Amount of fpToken required to redeem bAssets
     */
    function computeRedeemExact(
        BassetData[] memory _bAssets,
        uint8[] memory _indices,
        uint256[] memory _rawOutputs,
        FeederConfig memory _config
    ) public pure returns (uint256 redeemInput) {
        // 1. Get raw reserves
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        // 2. Get value of reserves according to invariant
        uint256 k0 = _invariant(x, sum, _config.a);
        // 3. Sub deposits from x and sum
        uint256 len = _indices.length;
        uint256 ratioed;
        for (uint256 i = 0; i < len; i++) {
            ratioed = (_rawOutputs[i] * _bAssets[_indices[i]].ratio) / 1e8;
            x[_indices[i]] -= ratioed;
            sum -= ratioed;
        }
        require(_inBounds(x, sum, _config.limits), "Exceeds weight limits");
        // 4. Get new value of reserves according to invariant
        uint256 k1 = _invariant(x, sum, _config.a);
        // 5. Total fpToken is the difference between values
        redeemInput = (_config.supply * (k0 - k1)) / k0;
        require(redeemInput > 1e6, "Must redeem > 1e6 units");
    }

    /**
     * @notice Gets the price of the fpToken, and invariant value k
     * @param _bAssets  Array of all bAsset Data
     * @param _config   Generalised FeederConfig stored externally
     * @return price    Price of an fpToken
     * @return k        Total value of basket, k
     */
    function computePrice(BassetData[] memory _bAssets, FeederConfig memory _config)
        public
        pure
        returns (uint256 price, uint256 k)
    {
        (uint256[] memory x, uint256 sum) = _getReserves(_bAssets);
        k = _invariant(x, sum, _config.a);
        price = (1e18 * k) / _config.supply;
    }

    /***************************************
                    INTERNAL
    ****************************************/

    /**
     * @dev Computes the actual mint output after adding mint inputs
     * to the vault balances
     * @param _x            Scaled vaultBalances
     * @param _sum          Sum of vaultBalances, to avoid another loop
     * @param _k            Previous value of invariant, k, before addition
     * @param _config       Generalised FeederConfig stored externally
     * @return mintAmount   Amount of value added to invariant, in fpToken terms
     */
    function _computeMintOutput(
        uint256[] memory _x,
        uint256 _sum,
        uint256 _k,
        FeederConfig memory _config
    ) internal pure returns (uint256 mintAmount) {
        // 1. Get value of reserves according to invariant
        uint256 kFinal = _invariant(_x, _sum, _config.a);
        // 2. Total minted is the difference between values, with respect to total supply
        if (_config.supply == 0) {
            mintAmount = kFinal - _k;
        } else {
            mintAmount = (_config.supply * (kFinal - _k)) / _k;
        }
    }

    /**
     * @dev Simply scaled raw reserve values and returns the sum
     * @param _bAssets  All bAssets
     * @return x        Scaled vault balances
     * @return sum      Sum of scaled vault balances
     */
    function _getReserves(BassetData[] memory _bAssets)
        internal
        pure
        returns (uint256[] memory x, uint256 sum)
    {
        uint256 len = _bAssets.length;
        x = new uint256[](len);
        uint256 r;
        for (uint256 i = 0; i < len; i++) {
            BassetData memory bAsset = _bAssets[i];
            r = (bAsset.vaultBalance * bAsset.ratio) / 1e8;
            x[i] = r;
            sum += r;
        }
    }

    /**
     * @dev Checks that no bAsset reserves exceed max weight
     * @param _x            Scaled bAsset reserves
     * @param _sum          Sum of x, precomputed
     * @param _limits       Config object containing max and min weights
     * @return inBounds     Bool, true if all assets are within bounds
     */
    function _inBounds(
        uint256[] memory _x,
        uint256 _sum,
        WeightLimits memory _limits
    ) internal pure returns (bool inBounds) {
        uint256 len = _x.length;
        inBounds = true;
        uint256 w;
        for (uint256 i = 0; i < len; i++) {
            w = (_x[i] * 1e18) / _sum;
            if (w > _limits.max || w < _limits.min) return false;
        }
    }

    /***************************************
                    INVARIANT
    ****************************************/

    /**
     * @dev Compute the invariant f(x) for a given array of supplies `x`.
     * @param _x        Scaled vault balances
     * @param _sum      Sum of scaled vault balances
     * @param _a        Precise amplification coefficient
     * @return k        Cumulative value of all assets according to the invariant
     */
    function _invariant(
        uint256[] memory _x,
        uint256 _sum,
        uint256 _a
    ) internal pure returns (uint256 k) {
        if (_sum == 0) return 0;

        uint256 var1 = _x[0] * _x[1];
        uint256 var2 = (_a * var1) / (_x[0] + _x[1]) / A_PRECISION;
        // result = 2 * (isqrt(var2**2 + (A + A_PRECISION) * var1 // A_PRECISION) - var2) + 1
        k = 2 * (Root.sqrt((var2**2) + (((_a + A_PRECISION) * var1) / A_PRECISION)) - var2) + 1;
    }

    /**
     * @dev Solves the invariant for _i with respect to target K, given an array of reserves.
     * @param _x        Scaled reserve balances
     * @param _a        Precise amplification coefficient
     * @param _idx      Index of asset for which to solve
     * @param _targetK  Target invariant value K
     * @return y        New reserve of _i
     */
    function _solveInvariant(
        uint256[] memory _x,
        uint256 _a,
        uint8 _idx,
        uint256 _targetK
    ) internal pure returns (uint256 y) {
        require(_idx == 0 || _idx == 1, "Invalid index");

        uint256 x = _idx == 0 ? _x[1] : _x[0];
        uint256 var1 = _a + A_PRECISION;
        uint256 var2 = ((_targetK**2) * A_PRECISION) / var1;
        // var3 = var2 // (4 * x) + k * _a // var1 - x
        uint256 tmp = var2 / (4 * x) + ((_targetK * _a) / var1);
        uint256 var3 = tmp >= x ? tmp - x : x - tmp;
        //  result = (sqrt(var3**2 + var2) + var3) // 2
        y = ((Root.sqrt((var3**2) + var2) + tmp - x) / 2) + 1;
    }
}