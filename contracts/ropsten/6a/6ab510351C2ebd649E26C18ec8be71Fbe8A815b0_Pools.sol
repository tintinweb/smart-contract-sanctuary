// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/SafeERC20.sol";
import "./interfaces/iERC20.sol";
import "./interfaces/iGovernorAlpha.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iROUTER.sol";
import "./interfaces/iFACTORY.sol";

contract Pools {
    using SafeERC20 for ExternalERC20;

    // Parameters
    uint256 public pooledVADER;
    uint256 public pooledUSDV;

    uint256 public vaderLimit;
    uint256 public usdvLimit;

    address public immutable VADER;

    mapping(address => bool) internal _isAsset;
    mapping(address => bool) internal _isAnchor;

    mapping(address => uint256) public mapToken_Units;
    mapping(address => mapping(address => uint256)) public mapTokenMember_Units;
    mapping(address => uint256) public mapToken_baseAmount;
    mapping(address => uint256) public mapToken_tokenAmount;

    // Events
    event AddLiquidity(
        address indexed member,
        address indexed base,
        uint256 baseAmount,
        address indexed token,
        uint256 tokenAmount,
        uint256 liquidityUnits
    );
    event RemoveLiquidity(
        address indexed member,
        address indexed base,
        uint256 baseAmount,
        address indexed token,
        uint256 tokenAmount,
        uint256 liquidityUnits,
        uint256 totalUnits
    );
    event Swap(
        address indexed member,
        address indexed inputToken,
        uint256 inputAmount,
        address indexed outputToken,
        uint256 outputAmount,
        uint256 swapFee
    );
    event Sync(address indexed token, address indexed pool, uint256 addedAmount);
    event MintSynth(
        address indexed member,
        address indexed base,
        uint256 baseAmount,
        address indexed token,
        uint256 synthAmount
    );
    event BurnSynth(
        address indexed member,
        address indexed base,
        uint256 baseAmount,
        address indexed token,
        uint256 synthAmount
    );
    event SynthSync(address indexed token, uint256 burntSynth, uint256 deletedUnits);

    // Only SYSTEM can execute
    modifier onlySystem() {
        require((msg.sender == ROUTER() || msg.sender == VAULT() || msg.sender == LENDER()), "!SYSTEM");
        _;
    }
    // Only Admin or TIMELOCK can execute
    modifier onlyAdminOrTIMELOCK() {
        require(msg.sender == iVADER(VADER).Admin() || msg.sender == TIMELOCK(), "!Admin && !TIMELOCK");
        _;
    }

    //=====================================CREATION=========================================//

    constructor(address _vader) {
        VADER = _vader;
    }

    //====================================LIQUIDITY=========================================//

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken,
        address member
    ) external onlySystem returns (uint256 liquidityUnits) {
        require(isBase(base), "!Base");
        require(!isBase(token), "USDV || VADER"); // Prohibited
        // uint256 _actualInputBase;
        if (base == VADER) {
            require(getSynth(token) == address(0), "Synth!");
            if (!_isAnchor[token]) {
                // If new Anchor
                _isAnchor[token] = true;
            }
            pooledVADER += inputBase;
            require(pooledVADER <= vaderLimit, "VADER Limit Error");
        } else {
            if (!_isAsset[token]) {
                // If new Asset
                _isAsset[token] = true;
            }
            pooledUSDV += inputBase;
            require(pooledUSDV <= usdvLimit, "USDV Limit Error");
        }

        liquidityUnits = iUTILS(UTILS()).calcLiquidityUnits(
            inputBase,
            mapToken_baseAmount[token],
            inputToken,
            mapToken_tokenAmount[token],
            mapToken_Units[token]
        );
        mapTokenMember_Units[token][member] += liquidityUnits; // Add units to member
        mapToken_Units[token] += liquidityUnits; // Add in total
        mapToken_baseAmount[token] += inputBase; // Add BASE
        mapToken_tokenAmount[token] += inputToken; // Add token
        emit AddLiquidity(member, base, inputBase, token, inputToken, liquidityUnits);
    }

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints,
        address member
    ) external onlySystem returns (uint256 units, uint256 outputBase, uint256 outputToken) {
        require(isBase(base), "!Base");
        (units, outputBase, outputToken) = iUTILS(UTILS()).getMemberShare(basisPoints, token, member);
        mapToken_Units[token] -= units;
        mapTokenMember_Units[token][member] -= units;
        mapToken_baseAmount[token] -= outputBase;
        mapToken_tokenAmount[token] -= outputToken;
        emit RemoveLiquidity(member, base, outputBase, token, outputToken, units, mapToken_Units[token]);
        transferOut(base, outputBase, member);
        transferOut(token, outputToken, member);
    }

    //=======================================SWAP===========================================//

    // Called only by a router
    function swap(
        address base,
        address token,
        uint256 amount,
        address member,
        bool toBase
    ) external onlySystem returns (uint256 outputAmount) {
        require(isBase(base), "!Base");
        if (toBase) {
            outputAmount = iUTILS(UTILS()).calcSwapOutput(
                amount,
                mapToken_tokenAmount[token],
                mapToken_baseAmount[token]
            );
            uint256 _swapFee =
                iUTILS(UTILS()).calcSwapFee(amount, mapToken_tokenAmount[token], mapToken_baseAmount[token]);
            mapToken_tokenAmount[token] += amount;
            mapToken_baseAmount[token] -= outputAmount;
            emit Swap(member, token, amount, base, outputAmount, _swapFee);
            transferOut(base, outputAmount, member);
        } else {
            outputAmount = iUTILS(UTILS()).calcSwapOutput(
                amount,
                mapToken_baseAmount[token],
                mapToken_tokenAmount[token]
            );
            uint256 _swapFee =
                iUTILS(UTILS()).calcSwapFee(amount, mapToken_baseAmount[token], mapToken_tokenAmount[token]);
            mapToken_baseAmount[token] += amount;
            mapToken_tokenAmount[token] -= outputAmount;
            emit Swap(member, base, amount, token, outputAmount, _swapFee);
            transferOut(token, outputAmount, member);
        }
    }

    // Add to balances directly (must send first)
    function sync(address token, uint256 inputToken, address pool) external {
        if (token == VADER) {
            pooledVADER += inputToken;
            require(pooledVADER <= vaderLimit, "VADER Limit Error");
        } else if (token == USDV()) {
            pooledUSDV += inputToken;
            require(pooledUSDV <= usdvLimit, "USDV Limit Error");
        }
        if (isBase(token)) {
            mapToken_baseAmount[pool] += inputToken;
        } else {
            mapToken_tokenAmount[pool] += inputToken;
        }
        emit Sync(token, pool, inputToken);
    }

    //======================================SYNTH=========================================//

    // Should be done with intention, is gas-intensive
    function deploySynth(address token) external {
        require(!isBase(token) && !isAnchor(token), "VADER || USDV || ANCHOR");
        iFACTORY(FACTORY()).deploySynth(token);
    }

    // Mint a Synth against its own pool
    function mintSynth(address token, uint256 inputBase, address member) external onlySystem returns (uint256 outputAmount) {
        address synth = getSynth(token);
        require(synth != address(0), "!Synth");
        pooledUSDV += inputBase;
        require(pooledUSDV <= usdvLimit, "USDV Limit Error");
        outputAmount = iUTILS(UTILS()).calcSwapOutput(
            inputBase,
            mapToken_baseAmount[token],
            mapToken_tokenAmount[token]
        ); // Get output
        mapToken_baseAmount[token] += inputBase; // Add BASE
        emit MintSynth(member, USDV(), inputBase, token, outputAmount); // Mint Synth Event
        iFACTORY(FACTORY()).mintSynth(synth, member, outputAmount); // Ask factory to mint to member
    }

    // Burn a Synth to get out BASE
    function burnSynth (address token, address member) external onlySystem returns (uint256 outputBase) {
        address synth = getSynth(token);
        uint256 _actualInputSynth = iERC20(synth).balanceOf(address(this)); // Get input
        iERC20(synth).burn(_actualInputSynth); // Burn it
        outputBase = iUTILS(UTILS()).calcSwapOutput(
            _actualInputSynth,
            mapToken_tokenAmount[token],
            mapToken_baseAmount[token]
        ); // Get output
        mapToken_baseAmount[token] -= outputBase; // Remove BASE
        emit BurnSynth(member, USDV(), outputBase, token, _actualInputSynth); // Burn Synth Event
        transferOut(USDV(), outputBase, member); // Send USDV to member
    }

    // Remove a synth, make other LPs richer
    function syncSynth(address token) external {
        address synth = getSynth(token);
        uint256 _actualInputSynth = iERC20(synth).balanceOf(address(this)); // Get input
        uint256 _unitsToDelete =
            iUTILS(UTILS()).calcShare(
                _actualInputSynth,
                iERC20(synth).totalSupply(),
                mapTokenMember_Units[token][address(this)]
            ); // Pro rata
        iERC20(synth).burn(_actualInputSynth); // Burn it
        mapTokenMember_Units[token][address(this)] -= _unitsToDelete; // Delete units for self
        mapToken_Units[token] -= _unitsToDelete; // Delete units
        emit SynthSync(token, _actualInputSynth, _unitsToDelete);
    }

    //======================================LENDING=========================================//

    // // Assign units to Router
    // function lockUnits(
    //     uint256 units,
    //     address token,
    //     address member
    // ) external onlySystem {
    //     mapTokenMember_Units[token][member] -= units;
    //     mapTokenMember_Units[token][msg.sender] += units; // Assign to Router
    // }

    // // Remove units from Router
    // function unlockUnits(
    //     uint256 units,
    //     address token,
    //     address member
    // ) external onlySystem {
    //     mapTokenMember_Units[token][msg.sender] -= units;
    //     mapTokenMember_Units[token][member] += units;
    // }

    //======================================HELPERS=========================================//

    function transferOut(
        address _token,
        uint256 _amount,
        address _recipient
    ) internal {
        if (_token == VADER) {
            pooledVADER = pooledVADER - _amount; // Accounting
        } else if (_token == USDV()) {
            pooledUSDV = pooledUSDV - _amount; // Accounting
        }
        if (_recipient != address(this)) {
            ExternalERC20(_token).safeTransfer(_recipient, _amount);
        }
    }

    // Adjust VADER Limit
    function setVaderLimit(uint256 newLimit) external onlyAdminOrTIMELOCK {
        vaderLimit = newLimit;
    }

    // Adjust USDV Limit
    function setUsdvLimit(uint256 newLimit) external onlyAdminOrTIMELOCK {
        usdvLimit = newLimit;
    }

    // Increase VADER Limit
    function increaseVaderLimit(uint256 amount) external onlyAdminOrTIMELOCK {
        vaderLimit += amount;
    }

    // Decrease VADER Limit
    function decreaseVaderLimit(uint256 amount) external onlyAdminOrTIMELOCK {
        if (vaderLimit < amount) {
            vaderLimit = 0;
        } else {
            vaderLimit -= amount;
        }
    }

    // Increase USDV Limit
    function increaseUsdvLimit(uint256 amount) external onlyAdminOrTIMELOCK {
        usdvLimit += amount;
    }

    // Decrease USDV Limit
    function decreaseUsdvLimit(uint256 amount) external onlyAdminOrTIMELOCK {
        if (usdvLimit < amount) {
            usdvLimit = 0;
        } else {
            usdvLimit -= amount;
        }
    }

    function isBase(address token) public view returns (bool base) {
        return token == VADER || token == USDV();
    }

    function isAsset(address token) public view returns (bool) {
        return _isAsset[token];
    }

    function isAnchor(address token) public view returns (bool) {
        return _isAnchor[token];
    }

    function getPoolAmounts(address token) external view returns (uint256, uint256) {
        return (getBaseAmount(token), getTokenAmount(token));
    }

    function getBaseAmount(address token) public view returns (uint256) {
        return mapToken_baseAmount[token];
    }

    function getTokenAmount(address token) public view returns (uint256) {
        return mapToken_tokenAmount[token];
    }

    function getUnits(address token) external view returns (uint256) {
        return mapToken_Units[token];
    }

    function getMemberUnits(address token, address member) external view returns (uint256) {
        return mapTokenMember_Units[token][member];
    }

    function getSynth(address token) public view returns (address) {
        return iFACTORY(FACTORY()).getSynth(token);
    }

    function isSynth(address token) external view returns (bool) {
        return iFACTORY(FACTORY()).isSynth(token);
    }

    function GovernorAlpha() internal view returns (address) {
        return iVADER(VADER).GovernorAlpha();
    }

    function USDV() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).USDV();
    }

    function ROUTER() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).ROUTER();
    }

    function VAULT() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).VAULT();
    }

    function LENDER() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).LENDER();
    }

    function FACTORY() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).FACTORY();
    }

    function UTILS() public view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).UTILS();
    }

    function TIMELOCK() internal view returns (address) {
        return iGovernorAlpha(GovernorAlpha()).TIMELOCK();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.1.0
//
// NOTE: All references to the standard `IERC20` type have been renamed to `ExternalERC20`
//

pragma solidity 0.8.3;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ExternalERC20 {
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ExternalERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(ExternalERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ExternalERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {ExternalERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ExternalERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ExternalERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ExternalERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(ExternalERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iGovernorAlpha {
    function VETHER() external view returns(address);
    function VADER() external view returns(address);
    function USDV() external view returns(address);
    function RESERVE() external view returns(address);
    function VAULT() external view returns(address);
    function ROUTER() external view returns(address);
    function LENDER() external view returns(address);
    function POOLS() external view returns(address);
    function FACTORY() external view returns(address);
    function UTILS() external view returns(address);
    function TIMELOCK() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function isBase(address token) external view returns (bool base);

    function calcValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcValueInToken(address token, uint256 amount) external view returns (uint256);

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) external view returns (uint256);

    function calcSwapValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcSwapValueInToken(address token, uint256 amount) external view returns (uint256);

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view;

    function getMemberShare(uint256 basisPoints, address token, address member) external view returns(uint256 units, uint256 outputBase, uint256 outputToken);

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare);

    function getReducedShare(uint256 amount) external view returns (uint256);

    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection);

    function getCoverage(address member, address token) external view returns (uint256);

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external returns (uint256 debt, uint256 baseValue);

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256);

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external returns (uint256 interestOwed);

    function getInterestPayment(address collateralAsset, address debtAsset) external view returns (uint256);

    function getDebtLoading(address collateralAsset, address debtAsset) external view returns (uint256);

    function calcPart(uint256 bp, uint256 total) external pure returns (uint256);

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) external pure returns (uint256);

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256);

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external view returns (uint256);

    function getSlipAdustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) external view returns (uint256);

    function calcSynthUnits(
        uint256 b,
        uint256 B,
        uint256 P
    ) external view returns (uint256);

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) external pure returns (uint256);

    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) external pure returns (uint256);

    function sortArray(uint256[] memory array) external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {

    function GovernorAlpha() external view returns (address);

    function Admin() external view returns (address);

    function UTILS() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function era() external view returns(uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newSeconds, uint256 newCurve, uint256 newTailEmissionEra) external;

    function setReserve(address newReserve) external;

    function changeUTILS(address newUTILS) external;

    function changeGovernorAlpha(address newGovernorAlpha) external;

    function purgeGovernorAlpha() external;

    function upgrade(uint256 amount) external;

    function convertToUSDV(uint256 amount) external returns (uint256);

    function convertToUSDVForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeemToVADER(uint256 amount) external returns (uint256);

    function redeemToVADERForMember(address member, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit,
        uint256 newInterval
    ) external;
    function setAnchorParams(
        uint256 newLimit,
        uint256 newInside,
        uint256 newOutside
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 units, uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function curatePool(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function listAnchor(address token) external;

    function replaceAnchor(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function isBase(address token) external view returns (bool base);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iFACTORY {
    function deploySynth(address) external returns (address);

    function mintSynth(
        address,
        address,
        uint256
    ) external returns (bool);

    function getSynth(address) external view returns (address);

    function isSynth(address) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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