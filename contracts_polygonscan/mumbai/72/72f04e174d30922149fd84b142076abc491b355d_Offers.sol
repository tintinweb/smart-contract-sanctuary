/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT
// File contracts/Offer/IOffer.sol

pragma solidity ^0.8.10;

/// Tenure is not within minimum and maximum authorized
/// @param tenure, actual tenure
/// @param minTenure, minimum tenure
/// @param maxTenure, maximum tenure
error InvalidTenure(uint8 tenure, uint8 minTenure, uint8 maxTenure);

/// AdvanceFee is higher than the maxAdvancedRatio
/// @param advanceFee, actual advanceFee
/// @param maxAdvancedRatio, maximum advanced ratio
error InvalidAdvanceFee(uint16 advanceFee, uint16 maxAdvancedRatio);

/// DiscountFee is lower than the minDiscountFee
/// @param discountFee, actual discountFee
/// @param minDiscountFee, minimum discount fee
error InvalidDiscountFee(uint16 discountFee, uint16 minDiscountFee);

/// FactoringFee is lower than the minDiscountFee
/// @param factoringFee, actual factoringFee
/// @param minFactoringFee, minimum factoring fee
error InvalidFactoringFee(uint16 factoringFee, uint16 minFactoringFee);

/// InvoiceAmount is not within minimum and maximum authorized
/// @param invoiceAmount, actual invoice amount
/// @param minAmount, minimum invoice amount
/// @param maxAmount, maximum invoice amount
error InvalidInvoiceAmount(uint invoiceAmount, uint minAmount, uint maxAmount);

/// Available Amount is higher than Invoice Amount
/// @param availableAmount, actual available amount
/// @param invoiceAmount, actual invoice amount
error InvalidAvailableAmount(uint availableAmount, uint invoiceAmount);

/// @title Offer
/// @author Polytrade
interface IOffer {
    struct OfferItem {
        uint advancedAmount;
        uint reserve;
        uint64 disbursingAdvanceDate;
        OfferParams params;
        OfferRefunded refunded;
    }

    struct OfferParams {
        uint8 gracePeriod;
        uint8 tenure;
        uint16 factoringFee;
        uint16 discountFee;
        uint16 advanceFee;
        address treasuryAddress;
        address stableAddress;
        uint invoiceAmount;
        uint availableAmount;
    }

    struct OfferRefunded {
        uint64 dueDate;
        uint16 lateFee;
        uint24 numberOfLateDays;
        uint totalCalculatedFees;
        uint netAmount;
        uint rewards;
    }

    /**
     * @dev Emitted when new offer is created
     */
    event OfferCreated(uint indexed offerId, bytes2 pricingId);

    /**
     * @dev Emitted when Reserve is refunded
     */
    event ReserveRefunded(uint indexed offerId, uint refundedAmount);

    /**
     * @dev Emitted when PricingTable Address is updated
     */
    event NewPricingTableContract(
        address oldPricingTableAddress,
        address newPricingTableAddress
    );

    /**
     * @dev Emitted when PriceFeed Address is updated
     */
    event NewPriceFeedContract(
        address oldPriceFeedAddress,
        address newPriceFeedAddress
    );

    /**
     * @dev Emitted when Oracle usage is ctivated
     */
    event OracleActivated();

    /**
     * @dev Emitted when Oracle usage is deactivated
     */
    event OracleDeactivated();
}


// File contracts/Chainlink/IPriceFeeds.sol

pragma solidity ^0.8.10;

/// @title Offer
/// @author Polytrade
interface IPriceFeeds {
    /**
     * @notice Link Stable Address to ChainLink Aggregator
     * @dev Add a mapping stableAddress to aggregator
     * @param stable, address of the ERC-20 stable smart contract
     * @param aggregator, address of the aggregator to map with the stableAddress
     */
    function setStableAggregator(address stable, address aggregator) external;

    /**
     * @notice Get the price of the stableAddress against USD dollar
     * @dev Query Chainlink aggregator to get Stable/USD price
     * @param stableAddress, address of the stable to be queried
     * @return price of the stable against USD dollar
     */
    function getPrice(address stableAddress) external view returns (uint);

    /**
     * @notice Returns the decimal used for the stable
     * @dev Query Chainlink aggregator to get decimal
     * @param stableAddress, address of the stable to be queried
     * @return decimals of the USD
     */
    function getDecimals(address stableAddress) external view returns (uint);
}


// File contracts/PricingTable/IPricingTable.sol

pragma solidity ^0.8.10;

/// @title Offer
/// @author Polytrade
interface IPricingTable {
    struct PricingItem {
        uint8 minTenure;
        uint8 maxTenure;
        uint16 maxAdvancedRatio;
        uint16 minDiscountFee;
        uint16 minFactoringFee;
        uint minAmount;
        uint maxAmount;
    }

    /**
     * @notice Add a Pricing Item to the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param pricingId, pricingId (hex format)
     * @param minTenure, minimum tenure expressed in percentage
     * @param maxTenure, maximum tenure expressed in percentage
     * @param maxAdvancedRatio, maximum advanced ratio expressed in percentage
     * @param minDiscountRange, minimum discount range expressed in percentage
     * @param minFactoringFee, minimum Factoring fee expressed in percentage
     * @param minAmount, minimum amount
     * @param maxAmount, maximum amount
     */
    function addPricingItem(
        bytes2 pricingId,
        uint8 minTenure,
        uint8 maxTenure,
        uint16 maxAdvancedRatio,
        uint16 minDiscountRange,
        uint16 minFactoringFee,
        uint minAmount,
        uint maxAmount
    ) external;

    /**
     * @notice Add a Pricing Item to the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param pricingId, pricingId (hex format)
     * @param minTenure, minimum tenure expressed in percentage
     * @param maxTenure, maximum tenure expressed in percentage
     * @param maxAdvancedRatio, maximum advanced ratio expressed in percentage
     * @param minDiscountRange, minimum discount range expressed in percentage
     * @param minFactoringFee, minimum Factoring fee expressed in percentage
     * @param minAmount, minimum amount
     * @param maxAmount, maximum amount
     */
    function updatePricingItem(
        bytes2 pricingId,
        uint8 minTenure,
        uint8 maxTenure,
        uint16 maxAdvancedRatio,
        uint16 minDiscountRange,
        uint16 minFactoringFee,
        uint minAmount,
        uint maxAmount,
        bool status
    ) external;

    /**
     * @notice Remove a Pricing Item from the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param id, id of the pricing Item
     */
    function removePricingItem(bytes2 id) external;

    /**
     * @notice Returns the pricing Item
     * @param id, id of the pricing Item
     * @return returns the PricingItem (struct)
     */
    function getPricingItem(bytes2 id)
        external
        view
        returns (PricingItem memory);

    /**
     * @notice Returns if the pricing Item is valid
     * @param id, id of the pricing Item
     * @return returns boolean if pricing is valid or not
     */
    function isPricingItemValid(bytes2 id) external view returns (bool);

    event NewPricingItem(PricingItem id);
    event UpdatedPricingItem(PricingItem id);
    event RemovedPricingItem(bytes2 id);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/Offer/Offer.sol

pragma solidity ^0.8.10;







/// @title Offer
/// @author Polytrade
contract Offers is IOffer, Ownable {
    using SafeERC20 for IERC20;

    IPricingTable public pricingTable;
    IPriceFeeds public priceFeed;

    uint private _countId;
    uint private _precision = 1E4;
    bool public toggleOracle;

    uint public totalAdvanced;
    uint public totalRefunded;

    mapping(uint => bytes2) private _offerToPricingId;
    mapping(uint => OfferItem) public offers;

    constructor(address pricingTableAddress, address priceFeedAddress) {
        pricingTable = IPricingTable(pricingTableAddress);
        priceFeed = IPriceFeeds(priceFeedAddress);
    }

    /**
     * @dev Activate usage of the Oracle
     */
    function activateOracle() external onlyOwner {
        toggleOracle = true;
        emit OracleActivated();
    }

    /**
     * @dev De-activate usage of the Oracle
     */
    function deactivateOracle() external onlyOwner {
        toggleOracle = false;
        emit OracleDeactivated();
    }

    /**
     * @dev Set PricingTable linked to the contract to a new PricingTable (`pricingTable`)
     * Can only be called by the owner
     */
    function setPricingTableAddress(address _newPricingTable)
        external
        onlyOwner
    {
        address oldPricingTable = address(pricingTable);
        pricingTable = IPricingTable(_newPricingTable);
        emit NewPricingTableContract(oldPricingTable, _newPricingTable);
    }

    /**
     * @dev Set PriceFeed linked to the contract to a new PriceFeed (`priceFeed`)
     * Can only be called by the owner
     */
    function setPriceFeedAddress(address _newPriceFeed) external onlyOwner {
        address oldPriceFeed = address(priceFeed);
        priceFeed = IPriceFeeds(_newPriceFeed);
        emit NewPriceFeedContract(oldPriceFeed, _newPriceFeed);
    }

    /**
     * @notice check if params fit with the pricingItem
     * @dev checks every params and returns a custom Error
     * @param pricingId, Id of the pricing Item
     * @param tenure, tenure expressed in number of days
     * @param advanceFee, ratio for the advance Fee
     * @param discountFee, ratio for the discount Fee
     * @param factoringFee, ratio for the factoring Fee
     * @param invoiceAmount, amount for the invoice
     * @param availableAmount, amount for the available amount
     */
    function checkOfferValidity(
        bytes2 pricingId,
        uint8 tenure,
        uint16 advanceFee,
        uint16 discountFee,
        uint16 factoringFee,
        uint invoiceAmount,
        uint availableAmount
    ) external view returns (bool) {
        return
            _checkParams(
                pricingId,
                tenure,
                advanceFee,
                discountFee,
                factoringFee,
                invoiceAmount,
                availableAmount
            );
    }

    /**
     * @notice Create an offer, check if it fits pricingItem requirements and send Advance to treasury
     * @dev calls _checkParams and returns Error if params don't fit with the pricingID
     * @dev only `Owner` can create a new offer
     * @dev emits OfferCreated event
     * @dev send Advance Amount to treasury
     * @param pricingId, Id of the pricing Item
     * @param params, OfferParams(gracePeriod, tenure, factoringFee, discountFee, advanceFee, invoiceAmount, availableAmount)
     */
    function createOffer(bytes2 pricingId, OfferParams memory params)
        public
        onlyOwner
        returns (uint)
    {
        require(
            _checkParams(
                pricingId,
                params.tenure,
                params.advanceFee,
                params.discountFee,
                params.factoringFee,
                params.invoiceAmount,
                params.availableAmount
            ),
            "Invalid offer parameters"
        );

        OfferItem memory offer;
        offer.advancedAmount = _calculateAdvancedAmount(
            params.availableAmount,
            params.advanceFee
        );

        offer.reserve = (params.invoiceAmount - offer.advancedAmount);
        offer.disbursingAdvanceDate = uint64(block.timestamp);

        require(
            (offer.advancedAmount + offer.reserve) == params.invoiceAmount,
            "advanced + reserve != invoice"
        );

        _countId++;
        _offerToPricingId[_countId] = pricingId;
        offer.params = params;
        offers[_countId] = offer;

        IERC20 stable = IERC20(offer.params.stableAddress);
        uint8 decimals = IERC20Metadata(address(stable)).decimals();

        uint amount = offers[_countId].advancedAmount * (10**(decimals - 2));

        if (toggleOracle) {
            uint amountToTransfer = (amount *
                (10**priceFeed.getDecimals(address(stable)))) /
                (priceFeed.getPrice(address(stable)));
            totalAdvanced += amountToTransfer;
            stable.safeTransfer(offer.params.treasuryAddress, amountToTransfer);
        } else {
            totalAdvanced += amount;
            stable.safeTransfer(offer.params.treasuryAddress, amount);
        }

        emit OfferCreated(_countId, pricingId);
        return _countId;
    }

    /**
     * @notice Send the reserve Refund to the treasury
     * @dev checks if Offer exists and if not refunded yet
     * @dev only `Owner` can call reserveRefund
     * @dev emits OfferReserveRefunded event
     * @param offerId, Id of the offer
     * @param dueDate, due date
     * @param lateFee, late fees (ratio)
     */
    function reserveRefund(
        uint offerId,
        uint64 dueDate,
        uint16 lateFee
    ) public onlyOwner {
        require(_offerToPricingId[offerId] != 0, "Offer doesn't exists");
        require(
            offers[offerId].refunded.netAmount == 0,
            "Offer already refunded"
        );

        OfferItem memory offer = offers[offerId];
        OfferRefunded memory refunded;

        refunded.lateFee = lateFee;
        refunded.dueDate = dueDate;

        uint lateAmount = 0;
        if (
            block.timestamp > (dueDate + offer.params.gracePeriod) &&
            block.timestamp - dueDate > offer.params.gracePeriod
        ) {
            refunded.numberOfLateDays = _calculateLateDays(
                dueDate,
                offer.params.gracePeriod
            );
            lateAmount = _calculateLateAmount(
                offer.advancedAmount,
                lateFee,
                refunded.numberOfLateDays
            );
        }

        uint factoringAmount = _calculateFactoringAmount(
            offer.params.invoiceAmount,
            offer.params.factoringFee
        );

        uint discountAmount = _calculateDiscountAmount(
            offer.advancedAmount,
            offer.params.discountFee,
            offer.params.tenure
        );

        refunded.totalCalculatedFees = (lateAmount +
            factoringAmount +
            discountAmount);
        refunded.netAmount = offer.reserve - refunded.totalCalculatedFees;

        offers[offerId].refunded = refunded;

        IERC20 stable = IERC20(offer.params.stableAddress);
        uint8 decimals = IERC20Metadata(address(stable)).decimals();

        uint amount = offers[offerId].refunded.netAmount * (10**(decimals - 2));

        totalRefunded += amount;
        stable.safeTransfer(offer.params.treasuryAddress, amount);

        emit ReserveRefunded(offerId, amount);
    }

    /**
     * @notice check if params fit with the pricingItem
     * @dev checks every params and returns a custom Error
     * @param pricingId, Id of the pricing Item
     * @param tenure, tenure expressed in number of days
     * @param advanceFee, ratio for the advance Fee
     * @param discountFee, ratio for the discount Fee
     * @param factoringFee, ratio for the factoring Fee
     * @param invoiceAmount, amount for the invoice
     * @param availableAmount, amount for the available amount
     */
    function _checkParams(
        bytes2 pricingId,
        uint8 tenure,
        uint16 advanceFee,
        uint16 discountFee,
        uint16 factoringFee,
        uint invoiceAmount,
        uint availableAmount
    ) private view returns (bool) {
        IPricingTable.PricingItem memory pricing = pricingTable.getPricingItem(
            pricingId
        );
        if (tenure < pricing.minTenure || tenure > pricing.maxTenure)
            revert InvalidTenure(tenure, pricing.minTenure, pricing.maxTenure);
        if (advanceFee > pricing.maxAdvancedRatio)
            revert InvalidAdvanceFee(advanceFee, pricing.maxAdvancedRatio);
        if (discountFee < pricing.minDiscountFee)
            revert InvalidDiscountFee(discountFee, pricing.minDiscountFee);
        if (factoringFee < pricing.minFactoringFee)
            revert InvalidFactoringFee(factoringFee, pricing.minFactoringFee);
        if (
            invoiceAmount < pricing.minAmount ||
            invoiceAmount > pricing.maxAmount
        )
            revert InvalidInvoiceAmount(
                invoiceAmount,
                pricing.minAmount,
                pricing.maxAmount
            );
        if (invoiceAmount < availableAmount)
            revert InvalidAvailableAmount(availableAmount, invoiceAmount);
        return true;
    }

    /**
     * @notice calculate the advanced Amount (availableAmount * advanceFee)
     * @dev calculate based on `(availableAmount * advanceFee)/ _precision` formula
     * @param availableAmount, amount for the available amount
     * @param advanceFee, ratio for the advance Fee
     * @return uint amount of the advanced
     */
    function _calculateAdvancedAmount(uint availableAmount, uint16 advanceFee)
        private
        view
        returns (uint)
    {
        return (availableAmount * advanceFee) / _precision;
    }

    /**
     * @notice calculate the Factoring Amount (invoiceAmount * factoringFee)
     * @dev calculate based on `(invoiceAmount * factoringFee) / _precision` formula
     * @param invoiceAmount, amount for the invoice amount
     * @param factoringFee, ratio for the factoring Fee
     * @return uint amount of the factoring
     */
    function _calculateFactoringAmount(uint invoiceAmount, uint16 factoringFee)
        private
        view
        returns (uint)
    {
        return (invoiceAmount * factoringFee) / _precision;
    }

    /**
     * @notice calculate the Discount Amount ((advancedAmount * discountFee) / 365) * tenure)
     * @dev calculate based on `((advancedAmount * discountFee) / 365) * tenure) / _precision` formula
     * @param advancedAmount, amount for the advanced amount
     * @param discountFee, ratio for the discount Fee
     * @param tenure, tenure
     * @return uint amount of the Discount
     */
    function _calculateDiscountAmount(
        uint advancedAmount,
        uint16 discountFee,
        uint8 tenure
    ) private view returns (uint) {
        return (((advancedAmount * discountFee) / 365) * tenure) / _precision;
    }

    /**
     * @notice calculate the Late Amount (((lateFee * advancedAmount) / 365) * lateDays)
     * @dev calculate based on `(((lateFee * advancedAmount) / 365) * lateDays) / _precision` formula
     * @param advancedAmount, amount for the advanced amount
     * @param lateFee, ratio for the late Fee
     * @param lateDays, number of late days
     * @return uint, Late Amount
     */
    function _calculateLateAmount(
        uint advancedAmount,
        uint16 lateFee,
        uint24 lateDays
    ) private view returns (uint) {
        return (((lateFee * advancedAmount) / 365) * lateDays) / _precision;
    }

    /**
     * @notice calculate the number of Late Days (Now - dueDate - gracePeriod)
     * @dev calculate based on `(block.timestamp - dueDate - gracePeriod) / 1 days` formula
     * @param dueDate, due date -> epoch timestamps format
     * @param gracePeriod, grace period -> expressed in seconds
     * @return uint24, number of late Days
     */
    function _calculateLateDays(uint dueDate, uint gracePeriod)
        private
        view
        returns (uint24)
    {
        return uint24(block.timestamp - dueDate - gracePeriod) / 1 days;
    }
}