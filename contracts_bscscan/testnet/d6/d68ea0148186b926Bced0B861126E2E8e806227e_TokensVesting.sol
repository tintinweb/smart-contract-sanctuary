/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
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
        return msg.data;
    }
}

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

interface ITokensVesting {
    function privateSale() external view returns (uint256);

    function publicSale() external view returns (uint256);

    function team() external view returns (uint256);

    function advisor() external view returns (uint256);

    function liquidity() external view returns (uint256);

    function incentives() external view returns (uint256);

    function marketing() external view returns (uint256);

    function development() external view returns (uint256);

    function privateSaleReleased() external view returns (uint256);

    function publicSaleReleased() external view returns (uint256);

    function teamReleased() external view returns (uint256);

    function advisorReleased() external view returns (uint256);

    function liquidityReleased() external view returns (uint256);

    function incentivesReleased() external view returns (uint256);

    function marketingReleased() external view returns (uint256);

    function developmentReleased() external view returns (uint256);

    function releasePrivateSale() external;

    function releasePublicSale() external;

    function releaseTeam() external;

    function releaseAdvisor() external;

    function releaseLiquidity() external;

    function releaseIncentives() external;

    function releaseMarketing() external;

    function releaseDevelopment() external;

    event TokensReleased(uint256 amount);
    event TokensVestingRevoked(address receiver, uint256 amount);
}

contract TokensVesting is Ownable, ITokensVesting {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable genesisTimestamp;
    uint256 private constant GAP = 30 days;

    uint256 private constant PRIVATESALE = 12000000e18;
    uint256 private constant PRIVATESALE_TGE = 1200000e18;
    uint256 private constant PRIVATESALE_CLIFF = 30 days;
    uint256 private constant PRIVATESALE_DURATION = 540 days;
    address constant PRIVATESALE_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant PUBLICSALE = 2000000e18;
    uint256 private constant PUBLICSALE_TGE = 2000000e18;
    uint256 private constant PUBLICSALE_CLIFF = 0;
    uint256 private constant PUBLICSALE_DURATION = 0;
    address constant PUBLICSALE_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant TEAM = 10000000e18;
    uint256 private constant TEAM_TGE = 0;
    uint256 private constant TEAM_CLIFF = 360 days;
    uint256 private constant TEAM_DURATION = 540 days;
    address constant TEAM_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant ADVISOR = 5000000e18;
    uint256 private constant ADVISOR_TGE = 0;
    uint256 private constant ADVISOR_CLIFF = 180 days;
    uint256 private constant ADVISOR_DURATION = 540 days;
    address constant ADVISOR_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant LIQUIDITY = 5000000e18;
    uint256 private constant LIQUIDITY_TGE = 5000000e18;
    uint256 private constant LIQUIDITY_CLIFF = 0;
    uint256 private constant LIQUIDITY_DURATION = 0;
    address constant LIQUIDITY_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant INCENTIVES = 5000000e18;
    uint256 private constant INCENTIVES_TGE = 0;
    uint256 private constant INCENTIVES_CLIFF = 60 days;
    uint256 private constant INCENTIVES_DURATION = 540 days;
    address constant INCENTIVES_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant MARKETING = 18000000e18;
    uint256 private constant MARKETING_TGE = 0;
    uint256 private constant MARKETING_CLIFF = 60 days;
    uint256 private constant MARKETING_DURATION = 540 days;
    address constant MARKETING_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private constant DEVELOPMENT = 12000000e18;
    uint256 private constant DEVELOPMENT_TGE = 0;
    uint256 private constant DEVELOPMENT_CLIFF = 60 days;
    uint256 private constant DEVELOPMENT_DURATION = 540 days;
    address constant DEVELOPMENT_BENEFICIARY =
        0x9948cF6323C5A41Bf673ADb9CFDf9D39a65A86e1;

    uint256 private _privateSaleReleased = 0;
    uint256 private _publicSaleReleased = 0;
    uint256 private _teamReleased = 0;
    uint256 private _advisorReleased = 0;
    uint256 private _liquidityReleased = 0;
    uint256 private _incentivesReleased = 0;
    uint256 private _marketingReleased = 0;
    uint256 private _developmentReleased = 0;

    constructor(address token_, uint256 genesisTimestamp_) {
        require(
            token_ != address(0),
            "TokenVesting::constructor: token_ is the zero address!"
        );
        require(
            genesisTimestamp_ >= block.timestamp,
            "TokenVesting::constructor: genesis too soon"
        );

        token = IERC20(token_);
        genesisTimestamp = genesisTimestamp_;
    }

    function privateSale() external pure returns (uint256) {
        return PRIVATESALE;
    }

    function publicSale() external pure returns (uint256) {
        return PUBLICSALE;
    }

    function team() external pure returns (uint256) {
        return TEAM;
    }

    function advisor() external pure returns (uint256) {
        return ADVISOR;
    }

    function liquidity() external pure returns (uint256) {
        return LIQUIDITY;
    }

    function incentives() external pure returns (uint256) {
        return INCENTIVES;
    }

    function marketing() external pure returns (uint256) {
        return MARKETING;
    }

    function development() external pure returns (uint256) {
        return DEVELOPMENT;
    }

    function privateSaleReleased() external view returns (uint256) {
        return _privateSaleReleased;
    }

    function publicSaleReleased() external view returns (uint256) {
        return _publicSaleReleased;
    }

    function teamReleased() external view returns (uint256) {
        return _teamReleased;
    }

    function advisorReleased() external view returns (uint256) {
        return _advisorReleased;
    }

    function liquidityReleased() external view returns (uint256) {
        return _liquidityReleased;
    }

    function incentivesReleased() external view returns (uint256) {
        return _incentivesReleased;
    }

    function marketingReleased() external view returns (uint256) {
        return _marketingReleased;
    }

    function developmentReleased() external view returns (uint256) {
        return _developmentReleased;
    }

    function releasePrivateSale() public {
        uint256 unreleased = _privateSaleReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releasePrivateSale: No tokens are due!"
        );

        _privateSaleReleased = _privateSaleReleased + unreleased;
        token.safeTransfer(PRIVATESALE_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releasePublicSale() public {
        uint256 unreleased = _publicSaleReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releasePublicSale: No tokens are due!"
        );

        _publicSaleReleased = _publicSaleReleased + unreleased;
        token.safeTransfer(PUBLICSALE_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releaseTeam() public {
        uint256 unreleased = _teamReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releaseTeam: No tokens are due!"
        );

        _teamReleased = _teamReleased + unreleased;
        token.safeTransfer(TEAM_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releaseAdvisor() public {
        uint256 unreleased = _advisorReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releaseAvisor: No tokens are due!"
        );

        _advisorReleased = _advisorReleased + unreleased;
        token.safeTransfer(ADVISOR_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releaseLiquidity() public {
        uint256 unreleased = _liquidityReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releaseLiquidity: No tokens are due!"
        );

        _liquidityReleased = _liquidityReleased + unreleased;
        token.safeTransfer(LIQUIDITY_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releaseIncentives() public {
        uint256 unreleased = _incentivesReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releaseIncentives: No tokens are due!"
        );

        _incentivesReleased = _incentivesReleased + unreleased;
        token.safeTransfer(INCENTIVES_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releaseMarketing() public {
        uint256 unreleased = _marketingReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releaseMarketing: No tokens are due!"
        );

        _marketingReleased = _marketingReleased + unreleased;
        token.safeTransfer(MARKETING_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function releaseDevelopment() public {
        uint256 unreleased = _developmentReleasableAmount();
        require(
            unreleased > 0,
            "TokensVesting::releaseDevelopment: No tokens are due!"
        );

        _developmentReleased = _developmentReleased + unreleased;
        token.safeTransfer(DEVELOPMENT_BENEFICIARY, unreleased);

        emit TokensReleased(unreleased);
    }

    function _vestedAmount(
        uint256 totalAmount,
        uint256 tgeAmount,
        uint256 cliff,
        uint256 duration
    ) private view returns (uint256) {
        if (block.timestamp < genesisTimestamp) {
            return 0;
        } else if (block.timestamp >= genesisTimestamp + cliff + duration) {
            return totalAmount;
        } else {
            uint256 timeLeftAfterStart = block.timestamp - genesisTimestamp;
            if (timeLeftAfterStart < cliff) {
                return tgeAmount;
            } else {
                uint256 gaps = (timeLeftAfterStart - cliff) / GAP + 1;
                return ((gaps * (totalAmount - tgeAmount)) / duration) * GAP;
            }
        }
    }

    function _privateSaleReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                PRIVATESALE,
                PRIVATESALE_TGE,
                PRIVATESALE_CLIFF,
                PRIVATESALE_DURATION
            ) - _privateSaleReleased;
    }

    function _publicSaleReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                PUBLICSALE,
                PUBLICSALE_TGE,
                PUBLICSALE_CLIFF,
                PUBLICSALE_DURATION
            ) - _publicSaleReleased;
    }

    function _teamReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(TEAM, TEAM_TGE, TEAM_CLIFF, TEAM_DURATION) -
            _teamReleased;
    }

    function _advisorReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                ADVISOR,
                ADVISOR_TGE,
                ADVISOR_CLIFF,
                ADVISOR_DURATION
            ) - _advisorReleased;
    }

    function _liquidityReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                LIQUIDITY,
                LIQUIDITY_TGE,
                LIQUIDITY_CLIFF,
                LIQUIDITY_DURATION
            ) - _liquidityReleased;
    }

    function _incentivesReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                INCENTIVES,
                INCENTIVES_TGE,
                INCENTIVES_CLIFF,
                INCENTIVES_DURATION
            ) - _incentivesReleased;
    }

    function _marketingReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                MARKETING,
                MARKETING_TGE,
                MARKETING_CLIFF,
                MARKETING_DURATION
            ) - _marketingReleased;
    }

    function _developmentReleasableAmount() private view returns (uint256) {
        return
            _vestedAmount(
                DEVELOPMENT,
                DEVELOPMENT_TGE,
                DEVELOPMENT_CLIFF,
                DEVELOPMENT_DURATION
            ) - _developmentReleased;
    }
}