/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: AGPL-3.0-or-later


interface ISavingsContractV2 {
    // DEPRECATED but still backwards compatible
    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    function creditBalances(address) external view returns (uint256); // V1 & V2 (use balanceOf)

    // --------------------------------------------

    function depositInterest(uint256 _amount) external; // V1 & V2

    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued); // V1 & V2

    function depositSavings(uint256 _amount, address _beneficiary)
        external
        returns (uint256 creditsIssued); // V2

    function redeemCredits(uint256 _amount) external returns (uint256 underlyingReturned); // V2

    function redeemUnderlying(uint256 _amount) external returns (uint256 creditsBurned); // V2

    function exchangeRate() external view returns (uint256); // V1 & V2

    function balanceOfUnderlying(address _user) external view returns (uint256 balance); // V2

    function underlyingToCredits(uint256 _credits) external view returns (uint256 underlying); // V2

    function creditsToUnderlying(uint256 _underlying) external view returns (uint256 credits); // V2
}

interface MassetStructs {
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

    struct AmpData {
        uint64 initialA;
        uint64 targetA;
        uint64 rampStartTime;
        uint64 rampEndTime;
    }
}

abstract contract IMasset is MassetStructs {
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin, // calculated off chain
        address[] calldata path, // also worked out off chain
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IBasicToken {
    function decimals() external view returns (uint8);
}

interface IBoostedSavingsVault {
    function stake(address _beneficiary, uint256 _amount) external;
}

// 3 FLOWS
// 0 - SAVE
// 1 - MINT AND SAVE
// 2 - BUY AND SAVE (ETH via Uni)
contract SaveWrapper {

    using SafeERC20 for IERC20;

    // Constants - add to bytecode during deployment
    address public immutable save;
    address public immutable vault;
    address public immutable mAsset;

    IUniswapV2Router02 public immutable uniswap;

    constructor(
        address _save,
        address _vault,
        address _mAsset,
        address[] memory _bAssets,
        address _uniswapAddress
    ) {
        require(_save != address(0), "Invalid save address");
        save = _save;
        require(_vault != address(0), "Invalid vault address");
        vault = _vault;
        require(_mAsset != address(0), "Invalid mAsset address");
        mAsset = _mAsset;
        require(_uniswapAddress != address(0), "Invalid uniswap address");
        uniswap = IUniswapV2Router02(_uniswapAddress);

        IERC20(_mAsset).safeApprove(_save, 2**256 - 1);
        IERC20(_save).approve(_vault, 2**256 - 1);
        for(uint256 i = 0; i < _bAssets.length; i++ ) {
            IERC20(_bAssets[i]).safeApprove(_mAsset, 2**256 - 1);
        }
    }


    /**
     * @dev 0. Simply saves an mAsset and then into the vault
     * @param _amount Units of mAsset to deposit to savings
     */
    function saveAndStake(uint256 _amount) external {
        IERC20(mAsset).transferFrom(msg.sender, address(this), _amount);
        _saveAndStake(_amount, true);
    }

    /**
     * @dev 1. Mints an mAsset and then deposits to SAVE
     * @param _bAsset       bAsset address
     * @param _amt          Amount of bAsset to mint with
     * @param _minOut       Min amount of mAsset to get back
     * @param _stake        Add the imUSD to the Savings Vault?
     */
    function saveViaMint(address _bAsset, uint256 _amt, uint256 _minOut, bool _stake) external {
        // 1. Get the input bAsset
        IERC20(_bAsset).transferFrom(msg.sender, address(this), _amt);
        // 2. Mint
        IMasset mAsset_ = IMasset(mAsset);
        uint256 massetsMinted = mAsset_.mint(_bAsset, _amt, _minOut, address(this));
        // 3. Mint imUSD and optionally stake in vault
        _saveAndStake(massetsMinted, _stake);
    }


    /**
     * @dev 2. Buys a bAsset on Uniswap with ETH then mUSD on Curve
     * @param _amountOutMin  Min uniswap output in bAsset units
     * @param _path          Sell path on Uniswap (e.g. [WETH, DAI])
     * @param _minOutMStable Min amount of mUSD to receive
     * @param _stake         Add the imUSD to the Savings Vault?
     */
    function saveViaUniswapETH(
        uint256 _amountOutMin,
        address[] calldata _path,
        uint256 _minOutMStable,
        bool _stake
    ) external payable {
        // 1. Get the bAsset
        uint[] memory amounts = uniswap.swapExactETHForTokens{value: msg.value}(
            _amountOutMin,
            _path,
            address(this),
            block.timestamp + 1000
        );
        // 2. Purchase mUSD
        uint256 massetsMinted = IMasset(mAsset).mint(_path[_path.length-1], amounts[amounts.length-1], _minOutMStable, address(this));
        // 3. Mint imUSD and optionally stake in vault
        _saveAndStake(massetsMinted, _stake);
    }

    /**
     * @dev Gets estimated mAsset output from a WETH > bAsset > mAsset trade
     */
    function estimate_saveViaUniswapETH(
        uint256 _ethAmount,
        address[] calldata _path,
        int128 _curvePosition
    )
        external
        view
        returns (uint256 out)
    {
        uint256 estimatedBasset = _getAmountOut(_ethAmount, _path);
        return IMasset(mAsset).getMintOutput(_path[_path.length-1], estimatedBasset);
    }

    /** @dev Internal func to deposit into SAVE and optionally stake in the vault */
    function _saveAndStake(
        uint256 _amount,
        bool _stake
    ) internal {
        if(_stake){
            uint256 credits = ISavingsContractV2(save).depositSavings(_amount, address(this));
            IBoostedSavingsVault(vault).stake(msg.sender, credits);
        } else {
            ISavingsContractV2(save).depositSavings(_amount, msg.sender);
        }
    }

    /** @dev Internal func to get esimtated Uniswap output from WETH to token trade */
    function _getAmountOut(uint256 _amountIn, address[] memory _path) internal view returns (uint256) {
        uint256[] memory amountsOut = uniswap.getAmountsOut(_amountIn, _path);
        return amountsOut[amountsOut.length - 1];
    }
}