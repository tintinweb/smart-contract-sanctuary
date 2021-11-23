// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IVault.sol";

/**
 * @title Teller Contract
 */
contract Teller is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    /// @notice Event emitted on construction.
    event TellerDeployed();

    /// @notice Event emitted when teller status is toggled.
    event TellerToggled(address teller, bool status);

    /// @notice Event emitted when new commitment is added.
    event NewCommitmentAdded(
        uint256 bonus,
        uint256 time,
        uint256 penalty,
        uint256 deciAdjustment
    );

    /// @notice Event emitted when commitment status is toggled.
    event CommitmentToggled(uint256 index, bool status);

    /// @notice Event emitted when owner sets the dev address to get the break commitment fees.
    event PurposeSet(address devAddress);

    /// @notice Event emitted when a provider deposits lp tokens.
    event LpDeposited(address provider, uint256 amount);

    /// @notice Event emitted when a provider withdraws lp tokens.
    event Withdrew(address provider, uint256 amount);

    /// @notice Event emitted when a provider commits lp tokens.
    event Commited(address provider, uint256 commitedAmount);

    /// @notice Event emitted when a provider breaks the commitment.
    event CommitmentBroke(address provider, uint256 tokenSentAmount);

    /// @notice Event emitted when provider claimed rewards.
    event Claimed(address provider, bool success);

    struct Provider {
        uint256 LPDepositedRatio;
        uint256 userWeight;
        uint256 lastClaimedTime;
        uint256 commitmentIndex;
        uint256 committedAmount;
        uint256 commitmentEndTime;
    }

    struct Commitment {
        uint256 bonus;
        uint256 duration;
        uint256 penalty;
        uint256 deciAdjustment;
        bool isActive;
    }

    IVault public Vault;
    IERC20 public LpToken;

    uint256 public totalLP;
    uint256 public totalWeight;
    uint256 public tellerClosedTime;

    bool public tellerOpen;
    bool public purpose;

    address public devAddress;

    Commitment[] public commitmentInfo;

    mapping(address => Provider) public providerInfo;

    modifier isTellerOpen() {
        require(tellerOpen, "Teller: Teller is not open.");
        _;
    }

    modifier isProvider() {
        require(
            providerInfo[msg.sender].LPDepositedRatio != 0,
            "Teller: Caller is not a provider."
        );
        _;
    }

    modifier isTellerClosed() {
        require(!tellerOpen, "Teller: Teller is still active.");
        _;
    }

    /**
     * @dev Constructor function
     * @param _LpToken Interface of LP token
     * @param _Vault Interface of Vault
     */
    constructor(IERC20 _LpToken, IVault _Vault) {
        LpToken = _LpToken;
        Vault = _Vault;
        commitmentInfo.push();

        emit TellerDeployed();
    }

    /**
     * @dev External function to toggle the teller. This function can be called only by the owner.
     */
    function toggleTeller() external onlyOwner {
        tellerOpen = !tellerOpen;
        tellerClosedTime = block.timestamp;
        emit TellerToggled(address(this), tellerOpen);
    }

    /**
     * @dev External function to add a commitment option. This function can be called only by the owner.
     * @param _bonus Amount of bonus
     * @param _days Commitment duration in days
     * @param _penalty The penalty
     * @param _deciAdjustment Decimal percentage
     */
    function addCommitment(
        uint256 _bonus,
        uint256 _days,
        uint256 _penalty,
        uint256 _deciAdjustment
    ) external onlyOwner {
        Commitment memory holder;

        holder.bonus = _bonus;
        holder.duration = _days * 1 days;
        holder.penalty = _penalty;
        holder.deciAdjustment = _deciAdjustment;
        holder.isActive = true;

        commitmentInfo.push(holder);

        emit NewCommitmentAdded(_bonus, _days, _penalty, _deciAdjustment);
    }

    /**
     * @dev External function to toggle the commitment. This function can be called only by the owner.
     * @param _index Commitment index
     */
    function toggleCommitment(uint256 _index) external onlyOwner {
        require(
            0 < _index && _index < commitmentInfo.length,
            "Teller: Current index is not listed in the commitment array."
        );
        commitmentInfo[_index].isActive = !commitmentInfo[_index].isActive;

        emit CommitmentToggled(_index, commitmentInfo[_index].isActive);
    }

    /**
     * @dev External function to set the dev address to give that address the break commitment fees. This function can be called only by the owner.
     * @param _address Dev address
     * @param _status If purpose is active or not
     */
    function setPurpose(address _address, bool _status) external onlyOwner {
        purpose = _status;
        devAddress = _address;

        emit PurposeSet(devAddress);
    }

    /**
     * @dev External function for providers to deposit lp tokens. Teller must be open.
     * @param _amount LP token amount
     */
    function depositLP(uint256 _amount) external isTellerOpen {
        uint256 contractBalance = LpToken.balanceOf(address(this));
        LpToken.safeTransferFrom(msg.sender, address(this), _amount);

        Provider storage user = providerInfo[msg.sender];
        if (user.LPDepositedRatio != 0) {
            commitmentFinished();
            claim();
        } else {
            user.lastClaimedTime = block.timestamp;
        }
        if (contractBalance == totalLP || totalLP == 0) {
            user.LPDepositedRatio += _amount;
            totalLP += _amount;
        } else {
            uint256 _adjustedAmount = (_amount * totalLP) / contractBalance;
            user.LPDepositedRatio += _adjustedAmount;
            totalLP += _adjustedAmount;
        }

        user.userWeight += _amount;
        totalWeight += _amount;

        emit LpDeposited(msg.sender, _amount);
    }

    /**
     * @dev External function to withdraw lp token from the teller. This function can be called only by a provider.
     * @param _amount LP token amount
     */
    function withdraw(uint256 _amount) external isProvider nonReentrant {
        Provider storage user = providerInfo[msg.sender];
        uint256 contractBalance = LpToken.balanceOf(address(this));
        commitmentFinished();
        uint256 userTokens = (user.LPDepositedRatio * contractBalance) /
            totalLP;
        require(
            userTokens - user.committedAmount >= _amount,
            "Teller: Provider hasn't got enough deposited LP tokens to withdraw."
        );

        claim();

        uint256 _weightChange = (_amount * user.userWeight) / userTokens;
        user.userWeight -= _weightChange;
        totalWeight -= _weightChange;

        uint256 ratioChange = _amount * totalLP/contractBalance;
        user.LPDepositedRatio -= ratioChange;
        totalLP -= ratioChange;


        LpToken.safeTransfer(msg.sender, _amount);

        emit Withdrew(msg.sender, _amount);
    }

    /**
     * @dev External function to withdraw lp token when teller is closed. This function can be called only by a provider.
     */
    function tellerClosedWithdraw() external isTellerClosed isProvider {
        uint256 contractBalance = LpToken.balanceOf(address(this));
        require(contractBalance != 0, "Teller: Contract balance is zero.");

        claim();

        Provider memory user = providerInfo[msg.sender];

        uint256 userTokens = (user.LPDepositedRatio * contractBalance) /
            totalLP;
        totalLP -= user.LPDepositedRatio;
        totalWeight -= user.userWeight;

        providerInfo[msg.sender] = Provider(0, 0, 0, 0, 0, 0);

        LpToken.safeTransfer(msg.sender, userTokens);

        emit Withdrew(msg.sender, userTokens);
    }

    /**
     * @dev External function to commit lp token to gain a minor advantage for a selected period of time. This function can be called only by a provider.
     * @param _amount LP token amount
     * @param _commitmentIndex Index of commitment array
     */
    function commit(uint256 _amount, uint256 _commitmentIndex)
        external
        nonReentrant
        isProvider
    {
        require(
            commitmentInfo[_commitmentIndex].isActive,
            "Teller: Current commitment is not active."
        );

        Provider storage user = providerInfo[msg.sender];
        commitmentFinished();
        uint256 contractBalance = LpToken.balanceOf(address(this));
        uint256 userTokens = (user.LPDepositedRatio * contractBalance) /
            totalLP;

        require(
            userTokens - user.committedAmount >= _amount,
            "Teller: Provider hasn't got enough deposited LP tokens to commit."
        );

        if (user.committedAmount != 0) {
            require(
                _commitmentIndex == user.commitmentIndex,
                "Teller: Commitment index is not the same as providers'."
            );
        }

        uint256 newEndTime;

        if (
            user.commitmentEndTime >= block.timestamp &&
            user.committedAmount != 0
        ) {
            newEndTime = calculateNewEndTime(
                user.committedAmount,
                _amount,
                user.commitmentEndTime,
                _commitmentIndex
            );
        } else {
            newEndTime =
                block.timestamp +
                commitmentInfo[_commitmentIndex].duration;
        }

        uint256 weightToGain = (_amount * user.userWeight) / userTokens;
        uint256 bonusCredit = commitBonus(_commitmentIndex, weightToGain);

        claim();

        user.commitmentIndex = _commitmentIndex;
        user.committedAmount += _amount;
        user.commitmentEndTime = newEndTime;
        user.userWeight += bonusCredit;
        totalWeight += bonusCredit;

        emit Commited(msg.sender, _amount);
    }

    /**
     * @dev External function to break the commitment. This function can be called only by a provider.
     */
    function breakCommitment() external nonReentrant isProvider {
        Provider memory user = providerInfo[msg.sender];

        require(
            user.commitmentEndTime > block.timestamp,
            "Teller: No commitment to break."
        );

        uint256 contractBalance = LpToken.balanceOf(address(this));

        uint256 tokenToReceive = (user.LPDepositedRatio * contractBalance) /
            totalLP;

        Commitment memory currentCommit = commitmentInfo[user.commitmentIndex];

        uint256 fee = (user.committedAmount * currentCommit.penalty) /
            currentCommit.deciAdjustment;

        tokenToReceive -= fee;

        totalLP -= user.LPDepositedRatio;

        totalWeight -= user.userWeight;

        providerInfo[msg.sender] = Provider(0, 0, 0, 0, 0, 0);

        if (purpose) {
            LpToken.safeTransfer(devAddress, fee / 10);
        }

        LpToken.safeTransfer(msg.sender, tokenToReceive);

        emit CommitmentBroke(msg.sender, tokenToReceive);
    }

    /**
     * @dev Internal function to claim rewards.
     */
    function claim() internal {
        Provider storage user = providerInfo[msg.sender];
        uint256 timeGap = block.timestamp - user.lastClaimedTime;

        if (!tellerOpen) {
            timeGap = tellerClosedTime - user.lastClaimedTime;
        }

        if (timeGap > 365 * 1 days) {
            timeGap = 365 * 1 days;
        }

        uint256 timeWeight = timeGap * user.userWeight;

        user.lastClaimedTime = block.timestamp;

        Vault.payProvider(msg.sender, timeWeight, totalWeight);

        emit Claimed(msg.sender, true);
    }

    /**
     * @dev Internal function to return commit bonus.
     * @param _commitmentIndex Index of commitment array
     * @param _amount Commitment token amount
     */
    function commitBonus(uint256 _commitmentIndex, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        if (commitmentInfo[_commitmentIndex].isActive) {
            return
                (commitmentInfo[_commitmentIndex].bonus * _amount) /
                commitmentInfo[_commitmentIndex].deciAdjustment;
        }
        return 0;
    }

    /**
     * @dev Internal function to calculate the new ending time when the current end time is overflown.
     * @param _oldAmount Commitment lp token amount which provider has
     * @param _extraAmount Lp token amount which user wants to commit
     * @param _oldEndTime Previous commitment ending time
     * @param _commitmentIndex Index of commitment array
     */
    function calculateNewEndTime(
        uint256 _oldAmount,
        uint256 _extraAmount,
        uint256 _oldEndTime,
        uint256 _commitmentIndex
    ) internal view returns (uint256) {
        uint256 extraEndTIme = commitmentInfo[_commitmentIndex].duration +
            block.timestamp;
        uint256 newEndTime = ((_oldAmount * _oldEndTime) +
            (_extraAmount * extraEndTIme)) / (_oldAmount + _extraAmount);

        return newEndTime;
    }

    /**
     * @dev Internal function to finish a commitment when it has ended.
     */
    function commitmentFinished() internal {
        Provider storage user = providerInfo[msg.sender];
        if (user.commitmentEndTime <= block.timestamp) {
            user.committedAmount = 0;
            user.commitmentIndex = 0;
        }
    }

    /**
     * @dev External function to claim the reward token. This function can be called only by a provider and teller must be open.
     */
    function claimExternal() external isTellerOpen isProvider nonReentrant {
        commitmentFinished();
        claim();
    }

    /**
     * @dev External function to get User info. This function can be called from a msg.sender with active deposits.
     * @return Time of rest committed time
     * @return Committed amount
     * @return Committed Index
     * @return Amount to Claim
     * @return Total LP deposited
     */
    function getUserInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Provider memory user = providerInfo[msg.sender];

        if (user.LPDepositedRatio > 0) {
            uint256 claimAmount = (Vault.vidyaRate() *
                Vault.tellerPriority(address(this)) *
                (block.timestamp - user.lastClaimedTime) *
                user.userWeight) / (totalWeight * Vault.totalPriority());

            uint256 totalLPDeposited = (providerInfo[msg.sender]
                .LPDepositedRatio * LpToken.balanceOf(address(this))) / totalLP;

            if (user.commitmentEndTime > block.timestamp) {
                return (
                    user.commitmentEndTime - block.timestamp,
                    user.committedAmount,
                    user.commitmentIndex,
                    claimAmount,
                    totalLPDeposited
                );
            } else {
                return (0, 0, 0, claimAmount, totalLPDeposited);
            }
        } else {
            return (0, 0, 0, 0, 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/**
 * @title Vault Interface
 */
interface IVault {
    /**
     * @dev External function to get vidya rate.
     */
    function vidyaRate() external view returns (uint256);

    /**
     * @dev External function to get total priority.
     */
    function totalPriority() external view returns (uint256);

    /**
     * @dev External function to get teller priority.
     * @param tellerId Teller Id
     */
    function tellerPriority(address tellerId) external view returns (uint256);

    /**
     * @dev External function to add the teller. This function can be called by only owner.
     * @param teller Address of teller
     * @param priority Priority of teller
     */
    function addTeller(address teller, uint256 priority) external;

    /**
     * @dev External function to change the priority of teller. This function can be called by only owner.
     * @param teller Address of teller
     * @param newPriority New priority of teller
     */
    function changePriority(address teller, uint256 newPriority) external;

    /**
     * @dev External function to pay the Vidya token to investors. This function can be called by only teller.
     * @param provider Address of provider
     * @param providerTimeWeight Weight time of provider
     * @param totalWeight Sum of provider weight
     */
    function payProvider(
        address provider,
        uint256 providerTimeWeight,
        uint256 totalWeight
    ) external;

    /**
     * @dev External function to calculate the Vidya Rate.
     */
    function calculateRateExternal() external;
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