// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Signature.sol";

contract TGE is Ownable, Signature {
    using SafeERC20 for IERC20;

    /** @dev Terms and conditions as a keccak256 hash */
    string public constant termsAndConditions =
        "By signing this message I agree to the $FOREX TOKEN - TERMS AND CONDITIONS identified by the hash: 0x1b42a1c6369d3efbf3b65d757e3f5e804bc26935b45dda1eaf0d90ef297289b4";
    /** @dev ERC-191 encoded Terms and Conditions for signature validation */
    bytes32 private constant termsAndConditionsERC191 =
        keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1("E"),
                bytes("thereum Signed Message:\n165"),
                abi.encodePacked(termsAndConditions)
            )
        );
    /** @dev Error message for claiming before allowed period */
    string private constant notClaimable = "Funds not yet claimable";
    /** @dev The amount of FOREX to be generated */
    uint256 public constant forexAmount = 20_760_000 ether;
    /** @dev The address of this contract's deployed instance */
    address private immutable self;
    /** @dev Canonical FOREX token address */
    address public immutable FOREX;
    /** @dev Per-user deposit cap */
    uint256 public immutable userCap;
    /** @dev Minimum token price in ETH (soft cap parameter) */
    uint256 public minTokenPrice;
    /** @dev Maximum token price in ETH (if hard cap is met) */
    uint256 public maxTokenPrice;
    /** @dev Generation duration (seconds)  */
    uint256 public immutable generationDuration;
    /** @dev Start date for the generation; when ETH deposits are accepted */
    uint256 public immutable generationStartDate;
    /** @dev Maximum deposit cap in ETH from which new deposits are ignored */
    uint256 public depositCap;
    /** @dev Date from when FOREX claiming is allowed */
    uint256 public claimDate;
    /** @dev Amount of ETH deposited during the TGE */
    uint256 public ethDeposited;
    /** @dev Mapping of (depositor => eth amount) for the TGE period */
    mapping(address => uint256) private deposits;
    /** @dev Mapping of (depositor => T&Cs signature status) */
    mapping(address => bool) public signedTermsAndConditions;
    /** @dev Mapping of (depositor => claimed eth) */
    mapping(address => bool) private claimedEth;
    /** @dev Mapping of (depositor => claimed forex) */
    mapping(address => bool) private claimedForex;
    /** @dev The total ETH deposited under a referral address */
    mapping(address => uint256) public referrerDeposits;
    /** @dev Number of depositors */
    uint256 public depositorCount;
    /** @dev Whether leftover FOREX tokens were withdrawn by owner
             (only possible if FOREX did not reach the max price) */
    bool private withdrawnRemainingForex;
    /** @dev Whether the TGE was aborted by the owner */
    bool private aborted;
    /** @dev ETH withdrawn by owner */
    uint256 public ethWithdrawnByOwner;

    modifier notAborted() {
        require(!aborted, "TGE aborted");
        _;
    }

    constructor(
        address _FOREX,
        uint256 _userCap,
        uint256 _depositCap,
        uint256 _minTokenPrice,
        uint256 _maxTokenPrice,
        uint256 _generationDuration,
        uint256 _generationStartDate
    ) {
        require(_generationDuration > 0, "Duration must be > 0");
        require(
            _generationStartDate > block.timestamp,
            "Start date must be in the future"
        );
        self = address(this);
        FOREX = _FOREX;
        userCap = _userCap;
        depositCap = _depositCap;
        minTokenPrice = _minTokenPrice;
        maxTokenPrice = _maxTokenPrice;
        generationDuration = _generationDuration;
        generationStartDate = _generationStartDate;
    }

    /**
     * @dev Deny direct ETH transfers.
     */
    receive() external payable {
        revert("Must call deposit to participate");
    }

    /**
     * @dev Validates a signature for the hashed terms & conditions message.
     *      The T&Cs hash is converted to an ERC-191 message before verifying.
     * @param signature The signature to validate.
     */
    function signTermsAndConditions(bytes memory signature) public {
        if (signedTermsAndConditions[msg.sender]) return;
        address signer = getSignatureAddress(
            termsAndConditionsERC191,
            signature
        );
        require(signer == msg.sender, "Invalid signature");
        signedTermsAndConditions[msg.sender] = true;
    }

    /**
     * @dev Allow incoming ETH transfers during the TGE period.
     */
    function deposit(address referrer, bytes memory signature)
        external
        payable
        notAborted
    {
        // Sign T&Cs if the signature is not empty.
        // User must pass a valid signature before the first deposit.
        if (signature.length != 0) signTermsAndConditions(signature);
        // Assert that the user can deposit.
        require(signedTermsAndConditions[msg.sender], "Must sign T&Cs");
        require(hasTgeBeenStarted(), "TGE has not started yet");
        require(!hasTgeEnded(), "TGE has finished");
        uint256 currentDeposit = deposits[msg.sender];
        // Revert if the user cap or TGE cap has already been met.
        require(currentDeposit < userCap, "User cap met");
        require(ethDeposited < depositCap, "TGE deposit cap met");
        // Assert that the deposit amount is greater than zero.
        uint256 deposit = msg.value;
        assert(deposit > 0);
        // Increase the depositorCount if first deposit by user.
        if (currentDeposit == 0) depositorCount++;
        if (currentDeposit + deposit > userCap) {
            // Ensure deposit over user cap is returned.
            safeSendEth(msg.sender, currentDeposit + deposit - userCap);
            // Adjust user deposit.
            deposit = userCap - currentDeposit;
        } else if (ethDeposited + deposit > depositCap) {
            // Ensure deposit over TGE cap is returned.
            safeSendEth(msg.sender, ethDeposited + deposit - depositCap);
            // Adjust user deposit.
            deposit -= ethDeposited + deposit - depositCap;
        }
        // Only contribute to referrals if the hard cap hasn't been met yet.
        uint256 hardCap = ethHardCap();
        if (ethDeposited < hardCap) {
            uint256 referralDepositAmount = deposit;
            // Subtract surplus from hard cap if any.
            if (ethDeposited + deposit > hardCap)
                referralDepositAmount -= ethDeposited + deposit - hardCap;
            referrerDeposits[referrer] += referralDepositAmount;
        }
        // Increase deposit variables.
        ethDeposited += deposit;
        deposits[msg.sender] += deposit;
    }

    /**
     * @dev Claim depositor funds (FOREX and ETH) once the TGE has closed.
            This may be called right after TGE closing for withdrawing surplus
            ETH (if FOREX reached max price/hard cap) or once (again when) the
            claim period starts for claiming both FOREX along with any surplus.
     */
    function claim() external notAborted {
        require(hasTgeEnded(), notClaimable);
        (uint256 forex, uint256 forexReferred, uint256 eth) = balanceOf(
            msg.sender
        );
        // Revert here if there's no ETH to withdraw as the FOREX claiming
        // period may not have yet started.
        require(eth > 0 || isTgeClaimable(), notClaimable);
        forex += forexReferred;
        // Claim forex only if the claimable period has started.
        if (isTgeClaimable() && forex > 0) claimForex(forex);
        // Claim ETH hardcap surplus if available.
        if (eth > 0) claimEthSurplus(eth);
    }

    /**
     * @dev Claims ETH for user.
     * @param eth The amount of ETH to claim.
     */
    function claimEthSurplus(uint256 eth) private {
        if (claimedEth[msg.sender]) return;
        claimedEth[msg.sender] = true;
        if (eth > 0) safeSendEth(msg.sender, eth);
    }

    /**
     * @dev Claims FOREX for user.
     * @param forex The amount of FOREX to claim.
     */
    function claimForex(uint256 forex) private {
        if (claimedForex[msg.sender]) return;
        claimedForex[msg.sender] = true;
        IERC20(FOREX).safeTransfer(msg.sender, forex);
    }

    /**
     * @dev Withdraws leftover forex in case the hard cap is not met during TGE.
     */
    function withdrawRemainingForex(address recipient) external onlyOwner {
        assert(!withdrawnRemainingForex);
        // Revert if the TGE has not ended.
        require(hasTgeEnded(), "TGE has not finished");
        (uint256 forexClaimable, ) = getClaimableData();
        uint256 remainingForex = forexAmount - forexClaimable;
        withdrawnRemainingForex = true;
        // Add address zero (null) referrals to withdrawal.
        remainingForex += getReferralForexAmount(address(0));
        if (remainingForex == 0) return;
        IERC20(FOREX).safeTransfer(recipient, remainingForex);
    }

    /**
     * @dev Returns an account's balance of claimable forex, referral forex,
            and ETH.
     * @param account The account to fetch the claimable balance for.
     */
    function balanceOf(address account)
        public
        view
        returns (
            uint256 forex,
            uint256 forexReferred,
            uint256 eth
        )
    {
        if (!hasTgeEnded()) return (0, 0, 0);
        (uint256 forexClaimable, uint256 ethClaimable) = getClaimableData();
        uint256 share = shareOf(account);
        eth = claimedEth[account] ? 0 : (ethClaimable * share) / (1 ether);
        if (claimedForex[account]) {
            forex = 0;
            forexReferred = 0;
        } else {
            forex = (forexClaimable * share) / (1 ether);
            // Forex earned through referrals is 5% of the referred deposits
            // in FOREX.
            forexReferred = getReferralForexAmount(account);
        }
    }

    /**
     * @dev Returns an account's share over the TGE deposits.
     * @param account The account to fetch the share for.
     * @return Share value as an 18 decimal ratio. 1 ether = 100%.
     */
    function shareOf(address account) public view returns (uint256) {
        if (ethDeposited == 0) return 0;
        return (deposits[account] * (1 ether)) / ethDeposited;
    }

    /**
     * @dev Returns the ETH deposited by an address.
     * @param depositor The depositor address.
     */
    function getDeposit(address depositor) external view returns (uint256) {
        return deposits[depositor];
    }

    /**
     * @dev Whether the TGE already started. It could be closed even if
            this function returns true.
     */
    function hasTgeBeenStarted() private view returns (bool) {
        return block.timestamp >= generationStartDate;
    }

    /**
     * @dev Whether the TGE has ended and is closed for new deposits.
     */
    function hasTgeEnded() private view returns (bool) {
        return block.timestamp > generationStartDate + generationDuration;
    }

    /**
     * @dev Whether the TGE funds can be claimed.
     */
    function isTgeClaimable() private view returns (bool) {
        return claimDate != 0 && block.timestamp >= claimDate;
    }

    /**
     * @dev The amount of ETH required to generate all supply at max price.
     */
    function ethHardCap() private view returns (uint256) {
        return (forexAmount * maxTokenPrice) / (1 ether);
    }

    /**
     * @dev Returns the forex price as established by the deposit amount.
     *      The formula for the price is the following:
     * minPrice + ([maxPrice - minPrice] * min(deposit, maxDeposit)/maxDeposit)
     * Where maxDeposit = ethHardCap()
     */
    function forexPrice() public view returns (uint256) {
        uint256 hardCap = ethHardCap();
        uint256 depositTowardsHardCap = ethDeposited > hardCap
            ? hardCap
            : ethDeposited;
        uint256 priceRange = maxTokenPrice - minTokenPrice;
        uint256 priceDelta = (priceRange * depositTowardsHardCap) / hardCap;
        return minTokenPrice + priceDelta;
    }

    /**
     * @dev Returns TGE data to be used for claims once the TGE closes.
     */
    function getClaimableData()
        private
        view
        returns (uint256 forexClaimable, uint256 ethClaimable)
    {
        assert(hasTgeEnded());
        uint256 forexPrice = forexPrice();
        uint256 hardCap = ethHardCap();
        // ETH is only claimable if the deposits exceeded the hard cap.
        ethClaimable = ethDeposited > hardCap ? ethDeposited - hardCap : 0;
        // Forex is claimable up to the maximum supply -- when deposits match
        // the hard cap amount.
        forexClaimable =
            ((ethDeposited - ethClaimable) * (1 ether)) /
            forexPrice;
    }

    /**
     * @dev Returns the amount of FOREX earned by a referrer.
     * @param referrer The referrer's address.
     */
    function getReferralForexAmount(address referrer)
        private
        view
        returns (uint256)
    {
        // Referral claims are disabled.
        return 0;
    }

    /**
     * @dev Aborts the TGE, stopping new deposits and withdrawing all funds
     *      for the owner.
     *      The only use case for this function is in the
     *      event of an emergency.
     */
    function emergencyAbort() external onlyOwner {
        assert(!aborted);
        aborted = true;
        emergencyWithdrawAllFunds();
    }

    /**
     * @dev Withdraws all contract funds for the owner.
     *      The only use case for this function is in the
     *      event of an emergency.
     */
    function emergencyWithdrawAllFunds() public onlyOwner {
        // Transfer ETH.
        uint256 balance = self.balance;
        if (balance > 0) safeSendEth(msg.sender, balance);
        // Transfer FOREX.
        IERC20 forex = IERC20(FOREX);
        balance = forex.balanceOf(self);
        if (balance > 0) forex.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraws all ETH funds for the owner.
     *      This function may be called at any time, as it correctly
     *      withdraws only the correct contribution amount, ignoring
     *      the ETH amount to be refunded if the deposits exceed
     *      the hard cap.
     */
    function collectContributions() public onlyOwner {
        uint256 hardCap = ethHardCap();
        require(
            ethWithdrawnByOwner < hardCap,
            "Cannot withdraw more than hard cap amount"
        );
        uint256 amount = self.balance;
        if (amount + ethWithdrawnByOwner > hardCap)
            amount = hardCap - ethWithdrawnByOwner;
        ethWithdrawnByOwner += amount;
        require(amount > 0, "Nothing available for withdrawal");
        safeSendEth(msg.sender, amount);
    }

    /**
     * @dev Enables FOREX claiming from the next block.
     *      Requires the TGE to have been closed.
     */
    function enableForexClaims() external onlyOwner {
        assert(hasTgeEnded() && !isTgeClaimable());
        claimDate = block.timestamp + 1;
    }

    /**
     * @dev Sets the minimum and maximum token prices before the TGE starts.
     *      Also sets the deposit cap.
     * @param min The minimum token price in ETH.
     * @param max The maximum token price in ETH.
     * @param _depositCap The ETH deposit cap.
     */
    function setMinMaxForexPrices(
        uint256 min,
        uint256 max,
        uint256 _depositCap
    ) external onlyOwner {
        assert(!hasTgeBeenStarted());
        require(max > min && _depositCap > max, "Invalid values");
        minTokenPrice = min;
        maxTokenPrice = max;
        depositCap = _depositCap;
    }

    /**
     * @dev Sends ETH and reverts if the transfer fails.
     * @param recipient The transfer recipient.
     * @param amount The transfer amount.
     */
    function safeSendEth(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send ETH");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract Signature {
    /**
     * @dev Returns the address that signed a message given a signature.
     * @param message The message signed.
     * @param signature The signature.
     */
    function getSignatureAddress(bytes32 message, bytes memory signature)
        internal
        pure
        returns (address)
    {
        assert(signature.length == 65);
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            // First 32 bytes after length prefix.
            r := mload(add(signature, 32))
            // Next 32 bytes.
            s := mload(add(signature, 64))
            // Final byte.
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(message, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

