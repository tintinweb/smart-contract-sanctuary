/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

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

interface IVersion {
    /**
     * @dev Returns version based on semantic versioning format.
     */
    function version() external pure returns (string memory);
}

contract FlexPaymentDivider is Ownable, IVersion {
    using Address for address payable;

    uint256 private _recipientCount;
    mapping(uint256 => address payable) private _recipientsById;
    mapping(address => uint256) private _percentagesByRecipient;
    mapping(address => uint256) private _balancesByRecipient;
    mapping(address => uint256) private _changeByRecipient;
    mapping(address => bool) private _isWithdrawingByAccount;

    /**
     * @notice Sets recipients and the percentage of each deposit sent to them.
     * @dev {_setupRecipients} is only used once--here, upon deployment.
     * @param recipients_ Accounts to receive percentage of deposits.
     * @param percentages_ Percentage of deposit each account should receive.
     * Order matters.
     */
    constructor(
        address payable[] memory recipients_,
        uint256[] memory percentages_
    ) {
        _setupRecipients(recipients_, percentages_);
    }

    function version() external pure override returns (string memory) {
        return "1.1.0";
    }

    /**
     * @notice Returns the number of recipients each deposit is divided by.
     * @return Number of recipients.
     */
    function recipientCount() external view returns (uint256) {
        return _recipientCount;
    }

    /**
     * @notice Returns recipient with the given id.
     * @param id Integer.
     * @return Ethereum account address.
     */
    function recipientById(uint256 id) external view returns (address) {
        return _recipientsById[id];
    }

    /**
     * @notice Returns the percentage of each deposit the recipient receives.
     * @param recipient Ethereum account address.
     * @return Amount of 100.
     */
    function percentage(address recipient) external view returns (uint256) {
        return _percentagesByRecipient[recipient];
    }

    /**
     * @notice Returns the balance the recipient has accumulated.
     * @param recipient Ethereum account address.
     * @return Amount of wei.
     */
    function accumulatedBalance(address recipient) external view returns (uint256) {
        return _balancesByRecipient[recipient];
    }

    /**
     * @notice Returns the amount of change the recipient has accumulated.
     * @param recipient Ethereum account address.
     * @return Fraction of wei as an amount out of 100.
     */
    function accumulatedChange(address recipient) external view returns (uint256) {
        return _changeByRecipient[recipient];
    }

    /**
     * @notice Increases balance for each recipient by their designated
     * percentage of the Ether sent with this call.
     * @custom:require Caller must be owner.
     * @custom:require Message value must be greater than 0.
     * @dev Solidity rounds towards zero so we accumulate change here that is
     * transferred once it exceeds a fractional amount of wei.
     *
     * @custom:warning
     * ===============
     * Forwarding all gas opens the door to reentrancy vulnerabilities. Make
     * sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     */
    function deposit() public payable onlyOwner {
        require(
            msg.value > 0,
            "FlexPaymentDivider: Insufficient message value"
        );
        for (uint256 i = 0; i < _recipientCount; i++) {
            address payable recipient = _recipientsById[i];
            uint256 change = (msg.value * _percentagesByRecipient[recipient]) % 100;
            uint256 amount = (msg.value * _percentagesByRecipient[recipient]) / 100;
            uint256 totalChange = _changeByRecipient[recipient] + change;
            _changeByRecipient[recipient] = totalChange;
            if (totalChange >= 100) {
                _changeByRecipient[recipient] = totalChange % 100;
                amount += (totalChange / 100);
            }
            _balancesByRecipient[recipient] += amount;
        }
    }

    /**
     * @notice Transfers to each recipient their designated percenatage of the
     * Ether held by this contract.
     * @custom:require Caller must be owner.
     *
     * @custom:warning
     * ===============
     * A denial of service attack is possible if any of the recipients revert.
     * The {withdraw} method can be used in the event of this attack.
     *
     * @custom:warning
     * ===============
     * Forwarding all gas opens the door to reentrancy vulnerabilities. Make
     * sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     */
    function disperse() external onlyOwner {
        for (uint256 i = 0; i < _recipientCount; i++) {
            address payable recipient = _recipientsById[i];
            withdraw(recipient);
        }
    }

    /**
     * @notice Transfers to recipient their designated percentage of the Ether
     * held in this contract.
     * @custom:require Caller must not already be withdrawing.
     * @custom:require Balance to withdraw must be above 0.
     *
     * @custom:warning
     * ===============
     * Forwarding all gas opens the door to reentrancy vulnerabilities. Make
     * sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     */
    function withdraw(address payable recipient) public {
        require(
            !isWithdrawing(_msgSender()),
            "FlexPaymentDivider: Can not reenter"
        );
        _isWithdrawingByAccount[_msgSender()] = true;

        uint256 amount = _balancesByRecipient[recipient];
        // IMPORTANT: Do not revert here so `disperse` can not have DoS when a
        // recipient does not yet have a balance to withdraw.
        if (amount > 0) {
            _balancesByRecipient[recipient] = 0;
            recipient.sendValue(amount);
        }

        _isWithdrawingByAccount[_msgSender()] = false;
    }

    /* INTERNAL */

    /**
     * @dev Sets mappings for recipients and respective percentages.
     * This method is only used once in the constructor. Recipients and
     * percentages can not be modified after deployment.
     * @custom:require Input lengths must be equal. Order matters.
     * @custom:require Each percentage must be above 0 and below 100.
     * @custom:require The sum of all percentages must be 100.
     * @param recipients_ Account addresses receiving a percentage of deposited
     * funds.
     * @param percentages_ Amounts for accounts at the same index in the
     * {recipients} parameter to allocate from deposited funds.
     *
     * @custom:warning
     * ===============
     * Recipient accounts should be trusted.
     */
    function _setupRecipients(
        address payable[] memory recipients_,
        uint256[] memory percentages_
    ) internal {
        require(
            recipients_.length == percentages_.length,
            "FlexPaymentDivider: Unequal input lengths"
        );
        uint256 sum = 0;
        for (uint256 i = 0; i < recipients_.length; i++) {
            require(
                percentages_[i] > 0,
                "FlexPaymentDivider: Percentage must exceed 0"
            );
            require(
                percentages_[i] <= 100,
                "FlexPaymentDivider: Percentage must not exceed 100"
            );
            sum += percentages_[i];
            _recipientCount += 1;
            _recipientsById[i] = recipients_[i];
            _percentagesByRecipient[_recipientsById[i]] = percentages_[i];
        }
        require(sum == 100, "FlexPaymentDivider: Percentages must sum to 100");
    }

    function isWithdrawing(address account) internal view returns (bool) {
        return _isWithdrawingByAccount[account];
    }
}

/**
 * @notice Collects royalties.
 */
contract PupperNFTRoyaltyReceiver is Ownable {
    using Address for address payable;

    FlexPaymentDivider private immutable _paymentHandler;

    event Received(uint256 indexed amount);

    constructor(
        address payable[] memory payoutAccounts_,
        uint256[] memory payoutPercentages_
    ) {
        _paymentHandler = new FlexPaymentDivider(payoutAccounts_, payoutPercentages_);
    }

    receive() external payable {
        emit Received(msg.value);
    }

    function getPaymentHandler() external view returns (address) {
        return address(_paymentHandler);
    }

    function transfer(bool safeMode) external onlyOwner {
        require(address(this).balance > 0, "HotWallet: No funds to transfer");
        uint256 value = address(this).balance;
        if (safeMode) {
            _depositAsPull(value);
        } else {
            _depositAsPush(value);
        }
    }

    function _depositAsPull(uint256 value) private {
        _paymentHandler.deposit{value: value}();
    }

    function _depositAsPush(uint256 value) private {
        _paymentHandler.deposit{value: value}();
        _paymentHandler.disperse();
    }
}