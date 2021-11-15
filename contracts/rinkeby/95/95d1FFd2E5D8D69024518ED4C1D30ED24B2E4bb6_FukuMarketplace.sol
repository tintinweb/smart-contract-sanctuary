// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interface/ICryptoPunksMarket.sol";
import "../interface/IVault.sol";
import "../interface/IVaultRegistry.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
  @title FukuMarketplace (ETH)
  @dev Implementation of a custom marketplace to deposit ETH/WETH
  into yield-generating strategies
  After depositing, users can place limit bids on Cryptopunks
  Cryptopunk owners can view/accept open bids
  This is the main contract that users will interface with
*/
contract FukuMarketplace is Ownable, ReentrancyGuard {
    using Address for address;
    using Counters for Counters.Counter;

    // Counter to create unique identifier for each created bid.
    Counters.Counter private _bidIds;

    // Contains user's current deposited amount and active bids.
    // Will add in redemption token balance
    struct UserInfo {
        address user;
        uint256 depositedAmount;
        uint256 numOfBids;
    }

    // Contains info about a bid
    struct BidInfo {
        uint256 bidId;
        uint256 amount;
        uint256 punkIndex;
        address bidder;
        bytes32 vault;
        bool openBid;
        bool sold;
    }

    // Contains the list of bids and a mapping to keep track of the array indexes for removal purposes
    struct PunkBidList {
        uint256[] bids;
        mapping(uint256 => uint256) indexes;
    }

    // CryptoPunk token address
    address public immutable punkToken;

    // The vault registry
    IVaultRegistry public immutable vaultRegistry;

    // enter address to locate user info
    mapping(address => UserInfo) public userInfo;

    // User to mapping of vault balances
    mapping(address => mapping(bytes32 => uint256)) public userVaultBalances;

    // enter bid id to locate bid info
    mapping(uint256 => BidInfo) public idToBid;

    // enter punk index to return list of bids
    mapping(uint256 => PunkBidList) private punkToBidId;

    // events involving ETH
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // events related to Punk bids
    event PunkBidEntered(
        uint256 bidId,
        uint256 indexed punkIndex,
        uint256 amount,
        address indexed bidder,
        bool openBid,
        bool sold
    );

    event PunkBidAccepted(uint256 bidId, address indexed bidder, address indexed seller);

    event PunkBidWithdrawn(uint256 bidId, address indexed bidder);

    /**
     * @dev Initializes the contract during deployment.
     * @param _punkToken address for cryptopunk token contract
     * @param _vaultRegistry the vault registry
     */
    constructor(address _punkToken, IVaultRegistry _vaultRegistry) {
        punkToken = _punkToken;
        vaultRegistry = _vaultRegistry;
    }

    /**
     * @dev Main point of entry into the marketplace
     * User deposits ETH to the marketplace
     * User's depositedAmount is updated
     * Emit deposit
     * Transfers balance of marketplace contract to strategy manager
     * @param vaultName The name of the vault as registered in the registry
     */
    function deposit(bytes32 vaultName) public payable nonReentrant {
        address vault = vaultRegistry.getVault(vaultName);
        require(vault != address(0), "Vault does not exist");

        // Update user info
        UserInfo storage user = userInfo[msg.sender];
        user.depositedAmount = user.depositedAmount + msg.value;

        // Update user deposit information
        userVaultBalances[msg.sender][vaultName] += msg.value;
        IVault(vault).deposit{ value: msg.value }();

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw a specific amount of ETH from the marketplace.
     * Checks if amount to withdraw is less than amount deposited.
     * Withdraws from strategy manager and sent to user
     * User's deposited amount is updated
     * @param amount The amount to withdraw
     * @param vaultName The vault to withdraw from
     */
    function withdraw(uint256 amount, bytes32 vaultName) public nonReentrant {
        // verify the vault
        address vault = vaultRegistry.getVault(vaultName);
        require(vault != address(0), "Vault does not exist");

        // verify the user deposit information
        UserInfo storage user = userInfo[msg.sender];
        require(amount <= user.depositedAmount);
        require(amount <= userVaultBalances[msg.sender][vaultName]);

        // Check marketplace ETH balance before and after withdraw
        uint256 balBefore = address(this).balance;
        IVault(vault).withdraw(amount, payable(this));
        uint256 balAfter = address(this).balance;

        // Amount withdrawn may not be exactly what the user input
        uint256 amountWithdrawn = balAfter - balBefore;

        // Update user account
        user.depositedAmount -= amountWithdrawn;
        userVaultBalances[msg.sender][vaultName] -= amountWithdrawn;

        (bool success, ) = payable(msg.sender).call{ value: amountWithdrawn }("");
        require(success, "Transfer failed.");

        emit Withdraw(msg.sender, amountWithdrawn);
    }

    /**
     * @dev Places an artificial bid for the punk.
     * Checks if punk to bid on exists.
     * Checks if bid amount is less than deposited amount.
     * Creates a new bid id and pushes all entered info.
     * Increase user's number of open bids
     * Emits the PunkBidEntered event.
     * @param vaultName The vault to withdraw funds from
     * @param amount The bid amount
     * @param punkIndex The punk index
     */
    function placeBid(
        bytes32 vaultName,
        uint256 amount,
        uint256 punkIndex
    ) public {
        UserInfo storage user = userInfo[msg.sender];
        require(punkIndex < 10000, "punk not found");
        require(amount > 0, "insufficient bid amount");
        require(amount <= userVaultBalances[msg.sender][vaultName], "insufficient deposited funds");
        _bidIds.increment();
        uint256 bidId = _bidIds.current();
        idToBid[bidId] = BidInfo(bidId, amount, punkIndex, msg.sender, vaultName, true, false);
        user.numOfBids++;

        // Add bid to list
        _addBidToList(punkIndex, bidId);

        emit PunkBidEntered(bidId, amount, punkIndex, msg.sender, true, false);
    }

    /**
     * @dev Allows a user to place multiple bids within one transaction
     * Pass in arrays of punkIndexes and amounts
     * Individual bids will be created
     * @param vaultNames Array of vault names for each bid
     * @param amounts Array of amounts for each bid
     * @param punkIds Array of punk ids for each bid
     */
    function placeMultipleBids(
        bytes32[] memory vaultNames,
        uint256[] memory amounts,
        uint256[] memory punkIds
    ) public {
        // todo determine bid limit constant from gas usage
        require(
            (vaultNames.length == amounts.length) && (vaultNames.length == punkIds.length),
            "Array length mismatch"
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            placeBid(vaultNames[i], amounts[i], punkIds[i]);
        }
    }

    /**
     * @dev Allows a user to modify one of their existing bids
     * Pass in bidId to locate existing bid and new amount
     * Data within bid struct will be updated
     * @param bidId The bid id
     * @param amount The new bid amount
     */
    function modifyBid(uint256 bidId, uint256 amount) public {
        BidInfo storage bid = idToBid[bidId];
        require(bid.bidder == msg.sender, "not your bid");
        require(amount > 0, "insufficient bid amount");
        require(amount <= userVaultBalances[msg.sender][bid.vault], "insufficient deposited funds");
        idToBid[bidId] = BidInfo(bid.bidId, amount, bid.punkIndex, msg.sender, bid.vault, true, false);
    }

    /**
     * @dev Modify multiple existing bids within one transaction
     * Pass in arrays of bidIds and amounts
     * Individual bids will be updated
     * @param bidIds Array of bid Ids
     * @param amounts Array of amounts
     */
    function modifyMultipleBids(uint256[] memory bidIds, uint256[] memory amounts) public {
        // todo limit the amount of bids using constant derived from gas usage of a single bid
        require(bidIds.length == amounts.length, "Array length mismatch");
        for (uint256 i = 0; i < bidIds.length; i++) {
            modifyBid(bidIds[i], amounts[i]);
        }
    }

    /**
     * @dev Cancels an open bid by passing in the bidId.
     * Checks if the person withdrawing the bid is the bid creator.
     * Emits the PunkBidWithdrawn event.
     * Changes the bid to value of 0, bidder of 0x0 address, and openBid to false.
     * Decrease user's number of open bids
     * @param bidId The bid id
     */
    function withdrawBid(uint256 bidId) public {
        BidInfo storage bid = idToBid[bidId];
        UserInfo storage user = userInfo[msg.sender];
        require(bid.bidder == msg.sender, "not your bid");
        emit PunkBidWithdrawn(bidId, msg.sender);
        uint256 punkIndex = bid.punkIndex;
        idToBid[bidId] = BidInfo(bidId, 0, punkIndex, address(0), "", false, false);
        user.numOfBids--;

        // Remove bid from list
        _removeBidFromList(punkIndex, bidId);

        emit PunkBidWithdrawn(bid.bidId, bid.bidder);
    }

    /**
     * @dev Cancels multiple bids in one transaction
     * Pass in arrays of bidIds
     * Individual bids will be canceled
     * @param bidIds Array of bid Ids
     */
    function withdrawMultipleBids(uint256[] memory bidIds) public {
        // todo limit the amount of bids based on a constant from the gas usage of a single withdraw
        for (uint256 i = 0; i < bidIds.length; i++) {
            withdrawBid(bidIds[i]);
        }
    }

    /**
     * @dev Punk owner accepts an open bid on his/her punk after approving the bid.
     * Retrives bid info and bidder info
     * Checks if the bid is open
     * Withdraws bid amount from strategy manager
     * Updates bidder's deposited amount
     * Fuku Marketplace buys punk from original owner and sends the eth
     * Fuku Marketplace transfers the punk to the bidder
     * Decrease bidder's number of open bids
     * Modifies the openBid to false and sold to true
     * Emit PunkBidAccepted
     * @param bidId The bid id
     */
    function acceptBid(uint256 bidId) public {
        BidInfo storage bid = idToBid[bidId];
        require(ICryptoPunksMarket(punkToken).punkIndexToAddress(bid.punkIndex) == msg.sender, "Not your punk");
        require(bid.openBid == true);
        require(bid.amount <= userVaultBalances[bid.bidder][bid.vault], "Bid no longer valid");
        UserInfo storage user = userInfo[bid.bidder];
        IVault(vaultRegistry.getVault(bid.vault)).withdraw(bid.amount, payable(this));
        user.depositedAmount = user.depositedAmount - bid.amount;
        uint256 punkIndex = bid.punkIndex;
        ICryptoPunksMarket(punkToken).buyPunk{ value: bid.amount }(punkIndex);
        ICryptoPunksMarket(punkToken).transferPunk(bid.bidder, punkIndex);
        user.numOfBids--;

        // Remove bid from list
        _removeBidFromList(punkIndex, bidId);

        idToBid[bidId] = BidInfo(bid.bidId, bid.amount, bid.punkIndex, msg.sender, "", false, true);
        emit PunkBidAccepted(bidId, bid.bidder, msg.sender);
    }

    /**
     * @dev Enter punk index to return array of bidIds
     * @param punkIndex The punk index
     */
    function getPunkBids(uint256 punkIndex) public view returns (uint256[] memory) {
        return punkToBidId[punkIndex].bids;
    }

    function _addBidToList(uint256 punkIndex, uint256 bidId) internal {
        PunkBidList storage punkBids = punkToBidId[punkIndex];
        punkBids.bids.push(bidId);
        punkBids.indexes[bidId] = punkBids.bids.length - 1; // Last index of array
    }

    /**
     * This function removes a bid from the list of bids, and then resizes the list.
     * Examples:
     *
     * | bid1 | bid2 | bid3 |
     * After removing bid2
     * | bid1 | bid3 |
     *
     * | bid1 | bid2 | bid3 |
     * After removing bid1
     * | bid3 | bid2 |
     *
     * | bid1 | bid2 | bid3 |
     * After removing bid3
     * | bid1 | bid2 |
     *
     * Algorithm:
     * 1. Get the PunkBidList struct for punkIndex. This struct contains the array of bids, and also a mapping of the
     * bidId to its index in the array.
     * 2. Get the index in the array of the bidId using the indexes mapping in the PunkBidList struct.
     * 3. Assign the current last bidId in the array, to the position in the array of the bidId to remove.
     * 4. Pop the last element in the array, it has been copied to the previous index of the bidId that was removed.
     * 5. If the bid list array is empty, or it was the last element in the array that was removed, there's
     * no need to update indexes.
     * 6. In all other cases, we update the new index to the bidId that was swapped into the newly vacated index.
     * 7. Delete the entry in the index mapping for the bidId that was just removed..
     */
    function _removeBidFromList(uint256 punkIndex, uint256 bidId) internal {
        // Remove bid from list
        PunkBidList storage punkBids = punkToBidId[punkIndex];
        uint256 index = punkBids.indexes[bidId];
        punkBids.bids[index] = punkBids.bids[punkBids.bids.length - 1];
        punkBids.bids.pop();
        // Assign the new index
        if (punkBids.bids.length > 0 && index < punkBids.bids.length) {
            punkBids.indexes[punkBids.bids[index]] = index;
        }
        delete punkBids.indexes[bidId];
    }

    receive() external payable {}
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ICryptoPunksMarket {
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
    event PunkBidEntered(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
    event PunkBidWithdrawn(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
    event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    function setInitialOwner(address to, uint256 punkIndex) external;

    function setInitialOwners(address[] calldata addresses, uint256[] calldata indices) external;

    function allInitialOwnersAssigned() external;

    function getPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;

    function punkNoLongerForSale(uint256 punkIndex) external;

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei) external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function withdraw() external;

    function enterBidForPunk(uint256 punkIndex) external payable;

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

    function withdrawBidForPunk(uint256 punkIndex) external;

    function punkIndexToAddress(uint256 punkIndex) external returns (address);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

// Not sure this is even necessary but I think it makes sense
interface IVault {
    function deposit() external payable returns (uint256);

    function withdraw(uint256 amount, address payable recipient) external;

    function getMaxWithdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IVaultRegistry {
    function registerVault(bytes32 vaultName, address vaultAddress) external;

    function unregisterVault(bytes32 vaultName) external;

    function getVault(bytes32 vaultName) external view returns (address);

    function getVaultNames() external view returns (bytes32[] memory);
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

