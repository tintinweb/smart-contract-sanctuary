/**
 *Submitted for verification at BscScan.com on 2021-10-11
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

/**
 * @dev Interface of the TokensVesting contract.
 */
interface ITokensVesting {
    /**
     * @dev Returns the total amount of tokens in vesting plan.
     */
    function total() external view returns (uint256);

    /**
     * @dev Returns the total amount of private sale tokens in vesting plan.
     */
    function privateSale() external view returns (uint256);

    /**
     * @dev Returns the total amount of public sale tokens in vesting plan.
     */
    function publicSale() external view returns (uint256);

    /**
     * @dev Returns the total amount of team tokens in vesting plan.
     */
    function team() external view returns (uint256);

    /**
     * @dev Returns the total amount of advisor tokens in vesting plan.
     */
    function advisor() external view returns (uint256);

    /**
     * @dev Returns the total amount of liquidity tokens in vesting plan.
     */
    function liquidity() external view returns (uint256);

    /**
     * @dev Returns the total amount of incentives tokens in vesting plan.
     */
    function incentives() external view returns (uint256);

    /**
     * @dev Returns the total amount of marketing tokens in vesting plan.
     */
    function marketing() external view returns (uint256);

    /**
     * @dev Returns the total amount of reserve tokens in vesting plan.
     */
    function reserve() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of tokens.
     */
    function releasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of private sale tokens.
     */
    function privateSaleReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of public sale tokens.
     */
    function publicSaleReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of team tokens.
     */
    function teamReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of advisor tokens.
     */
    function advisorReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of liquidity tokens.
     */
    function liquidityReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of incentives tokens.
     */
    function incentivesReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of marketing tokens.
     */
    function marketingReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of reserve tokens.
     */
    function reserveReleasable() external view returns (uint256);

    /**
     * @dev Returns the total released amount of tokens.
     */
    function released() external view returns (uint256);

    /**
     * @dev Returns the total released amount of private sale tokens.
     */
    function privateSaleReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of public sale tokens.
     */
    function publicSaleReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of team tokens
     */
    function teamReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of advisor tokens.
     */
    function advisorReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of liquidity tokens.
     */
    function liquidityReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of incentives tokens.
     */
    function incentivesReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of marketing tokens.
     */
    function marketingReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of reserve tokens.
     */
    function reserveReleased() external view returns (uint256);

    /**
     * @dev Unlocks all releasable amount of tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseAll() external;

    /**
     * @dev Unlocks all releasable amount of private sale tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releasePrivateSale() external;

    /**
     * @dev Unlocks all releasable amount of public sale tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releasePublicSale() external;

    /**
     * @dev Unlocks all releasable amount of team tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseTeam() external;

    /**
     * @dev Unlocks all releasable amount of advisor tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseAdvisor() external;

    /**
     * @dev Unlocks all releasable amount of liquidity tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseLiquidity() external;

    /**
     * @dev Unlocks all releasable amount of incentives tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseIncentives() external;

    /**
     * @dev Unlocks all releasable amount of marketing tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseMarketing() external;

    /**
     * @dev Unlocks all releasable amount of reserve tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseReserve() external;

    /**
     * @dev Emitted when having amount of tokens are released.
     */
    event TokensReleased(address indexed beneficiary, uint256 amount);
}

/**
 * @dev Implementation of the {ITokenVesting} interface.
 */
contract TokensVesting is Ownable, ITokensVesting {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable genesisTimestamp;
    uint256 private constant DEFAULT_BASIS = 30 days;

    uint256 public revokedAmount = 0;
    uint256 public revokedAmountWithdrawn = 0;

    enum Participant {
        Unknown,
        PrivateSale,
        PublicSale,
        Team,
        Advisor,
        Liquidity,
        Incentives,
        Marketing,
        Reserve,
        OutOfRange
    }

    enum Status {
        Inactive,
        Active,
        Revoked
    }

    struct VestingInfo {
        address beneficiary;
        uint256 totalAmount;
        uint256 tgeAmount;
        uint256 cliff;
        uint256 duration;
        uint256 releasedAmount;
        Participant participant;
        Status status;
        uint256 basis;
    }

    VestingInfo[] private _beneficiaries;

    event BeneficiaryAdded(address indexed beneficiary, uint256 amount);
    event BeneficiaryActivated(uint256 index, address indexed beneficiary);
    event BeneficiaryRevoked(
        uint256 index,
        address indexed beneficiary,
        uint256 amount
    );

    event Withdraw(address indexed receiver, uint256 amount);
    event EmergencyWithdraw(address indexed receiver, uint256 amount);

    /**
     * @dev Sets the values for {token} and {genesisTimestamp}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address token_, uint256 genesisTimestamp_) {
        require(
            token_ != address(0),
            "TokensVesting::constructor: token_ is the zero address!"
        );
        require(
            genesisTimestamp_ >= block.timestamp,
            "TokensVesting::constructor: genesis too soon!"
        );

        token = IERC20(token_);
        genesisTimestamp = genesisTimestamp_;
    }

    /**
     * @dev Get beneficiary by index_.
     */
    function getBeneficiary(uint256 index_)
        public
        view
        returns (VestingInfo memory)
    {
        return _beneficiaries[index_];
    }

    /**
     * @dev Add beneficiary to vesting plan.
     * @param beneficiary_ recipient address.
     * @param totalAmount_ total amount of tokens will be vested.
     * @param tgeAmount_ an amount of tokens will be vested at tge.
     * @param cliff_ cliff duration.
     * @param duration_ linear vesting duration.
     * @param participant_ specific type of {Participant}.
     */
    function addBeneficiary(
        address beneficiary_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint8 participant_
    ) public {
        addBeneficiary(
            beneficiary_,
            totalAmount_,
            tgeAmount_,
            cliff_,
            duration_,
            participant_,
            DEFAULT_BASIS
        );
    }

    /**
     * @dev Add beneficiary to vesting plan.
     * @param beneficiary_ recipient address.
     * @param totalAmount_ total amount of tokens will be vested.
     * @param tgeAmount_ an amount of tokens will be vested at tge.
     * @param cliff_ cliff duration.
     * @param duration_ linear vesting duration.
     * @param participant_ specific type of {Participant}.
     * @param basis_ basis duration for linear vesting.
     */
    function addBeneficiary(
        address beneficiary_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint8 participant_,
        uint256 basis_
    ) public onlyOwner {
        require(
            beneficiary_ != address(0),
            "TokensVesting::addBeneficiary: beneficiary_ is the zero address!"
        );
        require(
            totalAmount_ >= tgeAmount_,
            "TokensVesting::addBeneficiary: totalAmount_ must be greater than or equal to tgeAmount_!"
        );
        require(
            Participant(participant_) > Participant.Unknown &&
                Participant(participant_) < Participant.OutOfRange,
            "TokensVesting::addBeneficiary: participant_ out of range!"
        );
        require(
            genesisTimestamp + cliff_ + duration_ <= type(uint256).max,
            "TokensVesting::addBeneficiary: out of uint256 range!"
        );
        require(
            basis_ > 0,
            "TokensVesting::addBeneficiary: basis_ must be greater than 0!"
        );

        VestingInfo storage info = _beneficiaries.push();
        info.beneficiary = beneficiary_;
        info.totalAmount = totalAmount_;
        info.tgeAmount = tgeAmount_;
        info.cliff = cliff_;
        info.duration = duration_;
        info.participant = Participant(participant_);
        info.status = Status.Inactive;
        info.basis = basis_;

        emit BeneficiaryAdded(beneficiary_, totalAmount_);
    }

    /**
     * @dev See {ITokensVesting-total}.
     */
    function total() public view returns (uint256) {
        return _getTotalAmount();
    }

    /**
     * @dev See {ITokensVesting-privateSale}.
     */
    function privateSale() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-publicSale}.
     */
    function publicSale() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-team}.
     */
    function team() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-advisor}.
     */
    function advisor() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-liquidity}.
     */
    function liquidity() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-incentives}.
     */
    function incentives() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-marketing}.
     */
    function marketing() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-reserve}.
     */
    function reserve() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Reserve);
    }

    /**
     * @dev Activate specific beneficiary by index_.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activate(uint256 index_) public onlyOwner {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::activate: index_ out of range!"
        );

        _activate(index_);
    }

    /**
     * @dev Activate all of beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateAll() public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _activate(i);
        }
    }

    /**
     * @dev Activate all of private sale beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activatePrivateSale() public onlyOwner {
        return _activateParticipant(Participant.PrivateSale);
    }

    /**
     * @dev Activate all of public sale beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activatePublicSale() public onlyOwner {
        return _activateParticipant(Participant.PublicSale);
    }

    /**
     * @dev Activate all of team beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateTeam() public onlyOwner {
        return _activateParticipant(Participant.Team);
    }

    /**
     * @dev Activate all of advisor beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateAdvisor() public onlyOwner {
        return _activateParticipant(Participant.Advisor);
    }

    /**
     * @dev Activate all of liquidity beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateLiquidity() public onlyOwner {
        return _activateParticipant(Participant.Liquidity);
    }

    /**
     * @dev Activate all of incentives beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateIncentives() public onlyOwner {
        return _activateParticipant(Participant.Incentives);
    }

    /**
     * @dev Activate all of marketing beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateMarketing() public onlyOwner {
        return _activateParticipant(Participant.Marketing);
    }

    /**
     * @dev Activate all of reserve beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateReserve() public onlyOwner {
        return _activateParticipant(Participant.Reserve);
    }

    /**
     * @dev Revoke specific beneficiary by index_.
     *
     * Revoked beneficiaries cannot vest tokens anymore.
     */
    function revoke(uint256 index_) public onlyOwner {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::revoke: index_ out of range!"
        );

        _revoke(index_);
    }

    /**
     * @dev See {ITokensVesting-releasable}.
     */
    function releasable() public view returns (uint256) {
        uint256 _releasable = 0;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            VestingInfo storage info = _beneficiaries[i];
            _releasable =
                _releasable +
                _releasableAmount(
                    info.totalAmount,
                    info.tgeAmount,
                    info.cliff,
                    info.duration,
                    info.releasedAmount,
                    info.status,
                    info.basis
                );
        }

        return _releasable;
    }

    /**
     * @dev Returns the total releasable amount of tokens for the specific beneficiary by index.
     */
    function releasable(uint256 index_) public view returns (uint256) {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::release: index_ out of range!"
        );

        VestingInfo storage info = _beneficiaries[index_];
        uint256 _releasable = _releasableAmount(
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        return _releasable;
    }

    /**
     * @dev See {ITokensVesting-privateSaleReleasable}.
     */
    function privateSaleReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-publicSaleReleasable}.
     */
    function publicSaleReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-teamReleasable}.
     */
    function teamReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-advisorReleasable}.
     */
    function advisorReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-liquidityReleasable}.
     */
    function liquidityReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-incentivesReleasable}.
     */
    function incentivesReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-marketingReleasable}.
     */
    function marketingReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-reserveReleasable}.
     */
    function reserveReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Reserve);
    }

    /**
     * @dev See {ITokensVesting-released}.
     */
    function released() public view returns (uint256) {
        return _getReleasedAmount();
    }

    /**
     * @dev See {ITokensVesting-privateSaleReleased}.
     */
    function privateSaleReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-publicSaleReleased}.
     */
    function publicSaleReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-teamReleased}.
     */
    function teamReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-advisorReleased}.
     */
    function advisorReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-liquidityReleased}.
     */
    function liquidityReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-incentivesReleased}.
     */
    function incentivesReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-marketingReleased}.
     */
    function marketingReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-reserveReleased}.
     */
    function reserveReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Reserve);
    }

    /**
     * @dev See {ITokensVesting-releaseAll}.
     */
    function releaseAll() public {
        uint256 _releasable = releasable();
        require(
            _releasable > 0,
            "TokensVesting::releaseAll: no tokens are due!"
        );

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _release(i);
        }
    }

    /**
     * @dev See {ITokensVesting-releasePrivateSale}.
     */
    function releasePrivateSale() public {
        return _releaseParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-releasePublicSale}.
     */
    function releasePublicSale() public {
        return _releaseParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-releaseTeam}.
     */
    function releaseTeam() public {
        return _releaseParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-releaseAdvisor}.
     */
    function releaseAdvisor() public {
        return _releaseParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-releaseLiquidity}.
     */
    function releaseLiquidity() public {
        return _releaseParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-releaseIncentives}.
     */
    function releaseIncentives() public {
        return _releaseParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-releaseMarketing}.
     */
    function releaseMarketing() public {
        return _releaseParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-releaseReserve}.
     */
    function releaseReserve() public {
        return _releaseParticipant(Participant.Reserve);
    }

    /**
     * @dev Release all releasable amount of tokens for the sepecific beneficiary by index.
     *
     * Emits a {TokensReleased} event.
     */
    function release(uint256 index_) public {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::release: index_ out of range!"
        );

        VestingInfo storage info = _beneficiaries[index_];
        uint256 unreleased = _releasableAmount(
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        require(unreleased > 0, "TokensVesting::release: no tokens are due!");

        info.releasedAmount = info.releasedAmount + unreleased;
        token.safeTransfer(info.beneficiary, unreleased);
        emit TokensReleased(info.beneficiary, unreleased);
    }

    /**
     * @dev Withdraw revoked tokens out of contract.
     *
     * Withdraw amount of tokens upto revoked amount.
     */
    function withdraw(uint256 amount_) public onlyOwner {
        require(amount_ > 0, "TokensVesting::withdraw: Bad params!");
        require(
            amount_ <= revokedAmount - revokedAmountWithdrawn,
            "TokensVesting::withdraw: Amount exceeded revoked amount withdrawable!"
        );

        revokedAmountWithdrawn = revokedAmountWithdrawn + amount_;
        token.safeTransfer(_msgSender(), amount_);
        emit Withdraw(_msgSender(), amount_);
    }

    /**
     * @dev EMERGENCY ONLY.
     *
     * Withdraw all amount of tokens in contract.
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 currentBalance = token.balanceOf(address(this));
        require(
            currentBalance > 0,
            "TokensVesting::emergencyWithdraw: No tokens are in contract!"
        );

        token.safeTransfer(_msgSender(), currentBalance);
        emit EmergencyWithdraw(_msgSender(), currentBalance);
    }

    /**
     * @dev Release all releasable amount of tokens for the sepecific beneficiary by index.
     *
     * Emits a {TokensReleased} event.
     */
    function _release(uint256 index_) private {
        VestingInfo storage info = _beneficiaries[index_];
        uint256 unreleased = _releasableAmount(
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        if (unreleased > 0) {
            info.releasedAmount = info.releasedAmount + unreleased;
            token.safeTransfer(info.beneficiary, unreleased);
            emit TokensReleased(info.beneficiary, unreleased);
        }
    }

    function _getTotalAmount() private view returns (uint256) {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            totalAmount = totalAmount + _beneficiaries[i].totalAmount;
        }
        return totalAmount;
    }

    function _getTotalAmountByParticipant(Participant participant_)
        private
        view
        returns (uint256)
    {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].participant == participant_) {
                totalAmount = totalAmount + _beneficiaries[i].totalAmount;
            }
        }
        return totalAmount;
    }

    function _getReleasedAmount() private view returns (uint256) {
        uint256 releasedAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            releasedAmount = releasedAmount + _beneficiaries[i].releasedAmount;
        }
        return releasedAmount;
    }

    function _getReleasedAmountByParticipant(Participant participant_)
        private
        view
        returns (uint256)
    {
        require(
            Participant(participant_) > Participant.Unknown &&
                Participant(participant_) < Participant.OutOfRange,
            "TokensVesting::_getReleasedAmountByParticipant: participant_ out of range!"
        );

        uint256 releasedAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].participant == participant_)
                releasedAmount =
                    releasedAmount +
                    _beneficiaries[i].releasedAmount;
        }
        return releasedAmount;
    }

    function _releasableAmount(
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint256 releasedAmount_,
        Status status_,
        uint256 basis_
    ) private view returns (uint256) {
        if (status_ == Status.Inactive) {
            return 0;
        }

        if (status_ == Status.Revoked) {
            return totalAmount_ - releasedAmount_;
        }

        return
            _vestedAmount(totalAmount_, tgeAmount_, cliff_, duration_, basis_) -
            releasedAmount_;
    }

    function _vestedAmount(
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint256 basis_
    ) private view returns (uint256) {
        require(
            totalAmount_ >= tgeAmount_,
            "TokensVesting::_vestedAmount: Bad params!"
        );

        if (block.timestamp < genesisTimestamp) {
            return 0;
        }

        uint256 timeLeftAfterStart = block.timestamp - genesisTimestamp;

        if (timeLeftAfterStart < cliff_) {
            return tgeAmount_;
        }

        uint256 linearVestingAmount = totalAmount_ - tgeAmount_;
        if (timeLeftAfterStart >= cliff_ + duration_) {
            return linearVestingAmount + tgeAmount_;
        }

        uint256 gaps = (timeLeftAfterStart - cliff_) / basis_ + 1;
        uint256 totalGaps = duration_ / basis_;
        return (linearVestingAmount / totalGaps) * gaps + tgeAmount_;
    }

    function _activate(uint256 index_) private {
        VestingInfo storage info = _beneficiaries[index_];
        if (info.status == Status.Inactive) {
            info.status = Status.Active;
            emit BeneficiaryActivated(index_, info.beneficiary);
        }
    }

    function _activateParticipant(Participant participant_) private {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            VestingInfo storage info = _beneficiaries[i];
            if (info.participant == participant_) {
                _activate(i);
            }
        }
    }

    function _revoke(uint256 index_) private {
        VestingInfo storage info = _beneficiaries[index_];
        if (info.status == Status.Revoked) {
            return;
        }

        uint256 _releasable = _releasableAmount(
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        uint256 oldTotalAmount = info.totalAmount;
        info.totalAmount = info.releasedAmount + _releasable;

        uint256 revokingAmount = oldTotalAmount - info.totalAmount;
        if (revokingAmount > 0) {
            info.status = Status.Revoked;
            revokedAmount = revokedAmount + revokingAmount;
            emit BeneficiaryRevoked(index_, info.beneficiary, revokingAmount);
        }
    }

    function _getReleasableByParticipant(Participant participant_)
        private
        view
        returns (uint256)
    {
        uint256 _releasable = 0;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            VestingInfo storage info = _beneficiaries[i];
            if (info.participant == participant_) {
                _releasable =
                    _releasable +
                    _releasableAmount(
                        info.totalAmount,
                        info.tgeAmount,
                        info.cliff,
                        info.duration,
                        info.releasedAmount,
                        info.status,
                        info.basis
                    );
            }
        }

        return _releasable;
    }

    function _releaseParticipant(Participant participant_) private {
        uint256 _releasable = _getReleasableByParticipant(participant_);
        require(
            _releasable > 0,
            "TokensVesting::_releaseParticipant: no tokens are due!"
        );

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].participant == participant_) {
                _release(i);
            }
        }
    }
}