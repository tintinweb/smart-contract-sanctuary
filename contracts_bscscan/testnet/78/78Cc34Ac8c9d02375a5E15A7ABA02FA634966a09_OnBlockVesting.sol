// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";                                             
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";                                             


/**
 *
 * @dev A generic vesting contract.
 *
 */
contract OnBlockVesting is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant TEN_YRS_DAYS = 3650; // CKP-12
    uint256 constant TEN_YRS_SECONDS = TEN_YRS_DAYS * SECONDS_PER_DAY;
    uint256 constant MAX_VAULT_FEE = 1000000000000000000; // max 1 unit native currency

    string constant public name = "OnBlockVesting"; // CKP-07
    string constant public version = "v0.1"; // CKP-07

    enum LockType {
        FIXED,
        LINEAR
    }

    enum VoteAction {
        WITHDRAW,
        ADDVOTER,
        REMOVEVOTER,
        FEEUPDATE
    }

    struct Beneficiary {
        // the receiving address of the beneficiary
        address account;

        // the amount to receive
        uint256 amount;

        // released amount
        uint256 released;

        // start timestamp
        uint256 startTime;

        // end timestamp
        uint256 endTime;

        // duration in days
        uint256 duration;

        // cliff timestamp
        uint256 cliff;
        
        // lock type
        LockType lockType;
    }

    struct Vault {
        // the vault id
        uint256 id;

        // The token to be locked
        IERC20 token;

        // A mapping of all beneficiaries
        mapping(address => Beneficiary) beneficiaries;
    }

    struct Vote {

        VoteAction voteType;

        // The address to vote on, either a withdraw address or a new voter to be added or existing voter to be removed
        address onVote;

        uint256 newFee;

        // A mapping of all vote results, at least 3/4 of all voters have to vote for the same address 
        mapping(address => bytes32) results;
    }

    // votes 
    mapping(address => Vote) public votes;

    // Mapping to hold all vaults
    mapping(IERC20 => Vault) private vaults;

    // active voters
    address[] public voters;
    mapping(address => bool) activeVoters;

    // Array to track all active token vaults
    IERC20[] private activeVaults;

    // Globals
    uint256 private ID_COUNTER;
    uint256 private VAULT_FEE;
    uint256 private FEE_SUM;
    uint256 private MIN_VOTES_FOR_APPROVAL;

    // Events
    event Debug(string arg1);
    event Debug2(string arg1, bytes32 arg2, bytes32 arg3);
    event Debug3(uint256 arg1, uint256 arg2);
    event VaultCreated(uint256 vaultId, IERC20 token, uint256 fee);
    event Release(uint256 vaultId, address account, uint256 amount, uint256 released);
    event Fulfilled(uint256 vaultId, address account, uint256 amount, uint256 released);
    event FeeWithdraw(address initiator, address receiver, uint256 amount);
    event FeeUpdated(address updater, uint256 newFee);
    event VoteRequested(address requester, address onVote, uint256 newFee, VoteAction action);
    event Voted(address sender, address onVote, address voteAddress, uint256 voteFee, VoteAction action);
    event VoteState(address sender, address voteAddress, uint256 voteFee, uint256 voteCount, uint256 minVotes, VoteAction action);
    event AddedBeneficiary(uint256 vaultId, address account, uint256 amount, uint256 startTime, uint256 duration,
                           LockType lockType);

    modifier onlyVoter() {
        require(activeVoters[msg.sender], "Sender is not an active voter");
        _;
    }

    constructor(uint256 vaultFee_, address[] memory voters_) {
        require(vaultFee_ <= MAX_VAULT_FEE, 'Vault fee is too high'); // CKP-01
        require(voters_.length >= 4, 'Contract needs at least four signers');
        VAULT_FEE = vaultFee_;
        ID_COUNTER = 0;
        FEE_SUM = 0;
        voters = voters_;
        for (uint i = 0; i < voters.length; i++) {
            activeVoters[voters[i]] = true;
        }

        // 3/4 need to approve
        MIN_VOTES_FOR_APPROVAL = voters.length / 4 * 3;
    }

    /*
     * fallback and receive functions to disable
     * direct transfers to the contract
    */

    fallback () external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    function getActiveVaults() external view returns (IERC20[] memory) { // CKP-06
        return activeVaults;
    }

    function getVaultFee() external view returns (uint256) { // CKP-06
        return VAULT_FEE;
    }

    function isVoter(address address_) external view returns (bool) {
        return activeVoters[address_];
    }

    function finalizeVote(VoteAction action, address voteAddress, uint256 fee) private onlyVoter returns (bool) {
        if (action == VoteAction.WITHDRAW || action == VoteAction.ADDVOTER || action == VoteAction.REMOVEVOTER) {
            Vote storage activeVote;
            for (uint i = 0; i < voters.length; i++) {
                activeVote = votes[voters[i]];
                if (activeVote.voteType == action && activeVote.onVote == voteAddress) {
                    delete votes[voters[i]];
                }
            }
            return true;

        } else if (action == VoteAction.FEEUPDATE) {
            Vote storage activeVote;
            for (uint i = 0; i < voters.length; i++) {
                activeVote = votes[voters[i]];
                if (activeVote.voteType == action && activeVote.newFee == fee) {
                    delete votes[voters[i]];
                }
            }
            return true;
        }

        return false;
    }

    function isVoteDone(VoteAction action, address voteAddress, uint256 fee) public onlyVoter returns (bool) {
        uint256 voteResult = 0;
        if (action == VoteAction.WITHDRAW || action == VoteAction.ADDVOTER || action == VoteAction.REMOVEVOTER) {
            bytes memory addressBytes = abi.encode(voteAddress);
            Vote storage activeVote;
            for (uint i = 0; i < voters.length; i++) {
                activeVote = votes[voters[i]];
                if (activeVote.voteType == action && activeVote.onVote == voteAddress) {
                    for (uint j = 0; j < voters.length; j++) {
                        // emit Debug2("good", activeVote.results[voters[j]], keccak256(addressBytes));
                        if (activeVote.results[voters[j]] == keccak256(addressBytes)) {
                            voteResult += 1;
                        }
                    }
                }
            }

            emit VoteState(msg.sender, voteAddress, 0, voteResult, MIN_VOTES_FOR_APPROVAL, action);
            return voteResult >= MIN_VOTES_FOR_APPROVAL;

        } else if (action == VoteAction.FEEUPDATE) {
            bytes memory feeBytes = abi.encode(fee);
            Vote storage activeVote;
            for (uint i = 0; i < voters.length; i++) {
                activeVote = votes[voters[i]];
                if (activeVote.voteType == action && activeVote.newFee == fee) {
                    for (uint j = 0; j < voters.length; j++) {
                        if (activeVote.results[voters[j]] == keccak256(feeBytes)) {
                            voteResult += 1;
                        }
                    }
                }
            }

            emit VoteState(msg.sender, address(0), fee, voteResult, MIN_VOTES_FOR_APPROVAL, action);
            return voteResult >= MIN_VOTES_FOR_APPROVAL;
        }

        return false;
    }

    function requestVote(VoteAction action_, address address_, uint256 newFee_) external onlyVoter {
        // Setup the vote
        Vote storage entity = votes[msg.sender];
        entity.onVote = address_;
        entity.newFee = newFee_;
        entity.voteType = action_;

        if (entity.voteType == VoteAction.FEEUPDATE) {
            bytes memory feeBytes = abi.encode(newFee_);
            entity.results[msg.sender] = keccak256(feeBytes);
        } else {
            // Vote creator is the first voter
            bytes memory addressBytes = abi.encode(address_);
            entity.results[msg.sender] = keccak256(addressBytes);
        }

        emit VoteRequested(msg.sender, entity.onVote, entity.newFee, entity.voteType);
    }

    function vote(VoteAction action_, address creator_, address address_, uint256 newFee_) external onlyVoter {
        // Get the vote, key is the vote creators address
        Vote storage entity = votes[creator_];

        if (entity.voteType == action_) {

            if (entity.voteType == VoteAction.FEEUPDATE) {
                bytes memory feeBytes = abi.encode(newFee_);
                entity.results[msg.sender] = keccak256(feeBytes);
            } else {
                // Vote creator is the first voter
                bytes memory addressBytes = abi.encode(address_);
                entity.results[msg.sender] = keccak256(addressBytes);
            }
        }

        emit Voted(msg.sender, entity.onVote, address_, newFee_, entity.voteType);
    }

    function setVaultFee(uint256 newFee_) external onlyVoter { // CKP-06
        require(newFee_ > 0, 'New vault fee has to be > 0');
        require(newFee_ <= MAX_VAULT_FEE, ' Vault fee is too high'); // CKP-01

        require(isVoteDone(VoteAction.FEEUPDATE, address(0), newFee_), "Vote was not successful yet");

        VAULT_FEE = newFee_;
        emit FeeUpdated(msg.sender, VAULT_FEE); // CKP-09
        finalizeVote(VoteAction.FEEUPDATE, address(0), newFee_);
    }

    function withdrawVaultFee(address payable receiver_) external onlyVoter nonReentrant { // CKP-06 // CKP-16
        require(isVoteDone(VoteAction.WITHDRAW, receiver_, 0), "Vote was not successful yet");
        receiver_.transfer(FEE_SUM);
        emit FeeWithdraw(msg.sender, receiver_, FEE_SUM);
        FEE_SUM = 0;
        finalizeVote(VoteAction.WITHDRAW, receiver_, 0);
    }

    function feeBalance() external view returns (uint256) { // CKP-06
        return FEE_SUM;
    }

    function createVault(IERC20 token_) external payable returns (uint256) { // CKP-06
        require(vaults[token_].id == 0, "Vault exists already");
        require(msg.value >= VAULT_FEE, "Not enough fee attached");

        FEE_SUM += msg.value;

        // Create new Vault
        Vault storage entity = vaults[token_];
        entity.id = getID();
        entity.token = token_;

        activeVaults.push(token_);

        emit VaultCreated(entity.id, token_, msg.value);
        return entity.id;
    }

    function addBeneficiary(IERC20 token_, address account_, uint256 amount_, uint256 startTime_, uint256 duration_, 
                           uint256 cliff_, LockType lockType_) external { // CKP-06
        addBeneficiary(token_, account_, amount_, startTime_, duration_, cliff_, lockType_, true); // CKP-11
    }

    function addBeneficiary(IERC20 token_, address account_, uint256 amount_, uint256 startTime_, uint256 duration_, 
                           uint256 cliff_, LockType lockType_, bool sanity) public nonReentrant { // CKP-03
        require(vaults[token_].id > 0, "Vault does not exist"); // CKP-05
        require(vaults[token_].beneficiaries[account_].account == address(0), "Beneficiary already exists");
        require(startTime_ > block.timestamp, "StartTime has to be in the future ");
        require(amount_ > 0, "Amount has to be > 0");

        // Check the duration for a simple sanity check, if the vesting schedule is > 10 years, make sure the sanity flag is passed.
        if (sanity && duration_ > TEN_YRS_SECONDS) {
            require(duration_ < 3650 days, "If you are sure to have a lock time greater than 10 years use the overloaded function");
        }

        uint256 allowance = token_.allowance(msg.sender, address(this));
        require(allowance >= amount_, "Token allowance check failed");

        uint256 balanceBefore = token_.balanceOf(address(this));

        token_.safeTransferFrom(msg.sender, address(this), amount_);

        uint256 balanceAfter = token_.balanceOf(address(this));

        if (balanceAfter.sub(balanceBefore) != amount_) {
            // the token is deflationary, we don't support that.
            revert("Deflationary tokens are not supported!");
        }

        Beneficiary storage beneficiary = getBeneficiary(token_, account_);

        beneficiary.account = account_;
        beneficiary.amount = amount_;
        beneficiary.startTime = startTime_;
        beneficiary.endTime = startTime_.add(duration_);
        beneficiary.duration = duration_;
        beneficiary.cliff = startTime_.add(cliff_);
        beneficiary.released = 0;
        beneficiary.lockType = lockType_;

        vaults[token_].beneficiaries[account_] = beneficiary;

        emit AddedBeneficiary(vaults[token_].id, beneficiary.account, beneficiary.amount, beneficiary.startTime,
                              beneficiary.duration, beneficiary.lockType);
    }

    function getBeneficiary(IERC20 token_, address account_) private view returns (Beneficiary storage) {
        Vault storage entity = vaults[token_];
        Beneficiary storage beneficiary = entity.beneficiaries[account_];
        return beneficiary;
    }

    function getID() private returns(uint256) {
        return ++ID_COUNTER;
    }

    function readBeneficiary(IERC20 token_, address account_) external view returns (Beneficiary memory) { // CKP-06
        Vault storage vault = vaults[token_];
        return vault.beneficiaries[account_];
    }

    /**
     * @notice Transfers tokens held by the vault to the beneficiary.
     */
    function release(IERC20 token_, address account_) external nonReentrant { // CKP-06 // CKP-08 //CKP-13
        Vault storage vault = vaults[token_];
        Beneficiary storage beneficiary = vault.beneficiaries[account_];

        if (beneficiary.lockType == LockType.FIXED) {
            require(block.timestamp >= beneficiary.endTime, "EndTime not reached yet, try again later");
        }

        uint256 amountToRelease = releasableAmount(token_, account_);

        require(amountToRelease > 0, "Nothing to release");

        token_.safeTransfer(beneficiary.account, amountToRelease);

        beneficiary.released += amountToRelease;

        if (beneficiary.released == beneficiary.amount) {
            emit Fulfilled(vault.id, account_, amountToRelease, beneficiary.released);
            delete vault.beneficiaries[account_];
        } else {
            emit Release(vault.id, account_, amountToRelease, beneficiary.released);
        }
    }

    /**
     * @notice Returns the releaseable amount per vault/address.
     */
    function releasableAmount(IERC20 token_, address account_) public view returns (uint256) {
        Beneficiary storage beneficiary = getBeneficiary(token_, account_);
        return vestedAmount(beneficiary).sub(beneficiary.released);
    }

    /**
     * @notice Calculates the vested amount based on the beneficiaries parameters.
     */
    function vestedAmount(Beneficiary memory beneficiary) private view returns (uint256) {
        if (block.timestamp < beneficiary.cliff || block.timestamp < beneficiary.startTime) {
            return 0;
        } 

        if (block.timestamp >= beneficiary.endTime) {
            return beneficiary.amount;
        }

        if (beneficiary.lockType == LockType.LINEAR) {
            return beneficiary.amount.mul(block.timestamp.sub(beneficiary.startTime)).div(beneficiary.duration);
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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