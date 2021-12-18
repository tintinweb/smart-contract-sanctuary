// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable, Context } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { BaseRelayRecipient } from "./utils/BaseRelayRecipient.sol";

interface ShowtimeERC1155 is IERC1155, IERC2981 {}

//////////////////////////////////////////////
//                                          //
//                    ▄▄                    //
//                   ▄██▄                   //
//                  ▄████▄                  //
//                ▄████████▄                //
//              ▄████████████▄              //
//            ▄████████████████▄            //
//        ▄████████████████████████▄        //
//   ▄██████████████████████████████████▄   //
//   ▀██████████████████████████████████▀   //
//       ████████████████████████████       //
//           ████████████████████           //
//              ██████████████              //
//                ██████████                //
//                 ████████                 //
//                  ██████                  //
//                   ████                   //
//                    ██                    //
//                                          //
//////////////////////////////////////////////

/// @title Showtime V1 Market for the Showtime ERC1155 Token
///
/// This is a non-escrow marketplace that allows users to list Showtime NFTs for sale
/// for a fixed price, using a configurable list of allowed ERC20 currencies.
///
/// @dev listings have no expiration date, but frontends may choose to hide old listings
///
/// Built with feedback from the community! ♥️ Big thanks to:
///     aaronsebesta chejazi chiuzon garythung mariobyn_eth MarkBeylin sina_eth_
///     StErMi theramblingboy timidan_x transmissions11 William94029369
contract ShowtimeV1Market is Ownable, Pausable, BaseRelayRecipient {
    using SafeERC20 for IERC20;
    using Address for address;

    /// the address of the ShowtimeMT NFT (ERC1155) contract
    ShowtimeERC1155 public immutable nft;

    /// @dev listings only contain a tokenId because we are implicitly only listing tokens from the ShowtimeMT contract
    struct Listing {
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        IERC20 currency;
        address seller;
    }

    /// ============ Mutable storage ============

    /// royalties payments can be turned on/off by the owner of the contract
    bool public royaltiesEnabled = true;

    /// the configurable cap on royalties, enforced during the sale (50% by default)
    uint256 public maxRoyaltiesBasisPoints = 50_00;

    /// the configurable list of accepted ERC20 contract addresses
    mapping(address => bool) public acceptedCurrencies;

    /// maps a listing id to the corresponding Listing
    mapping(uint256 => Listing) public listings;

    /// a simple counter to assign ids to new listings
    uint256 listingCounter;

    /// ============ Events ============

    /// marketplace and listing related events
    event ListingCreated(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId);
    event ListingDeleted(uint256 indexed listingId, address indexed seller);
    event RoyaltyPaid(address indexed receiver, IERC20 currency, uint256 amount);
    event SaleCompleted(
        uint256 indexed listingId,
        address indexed seller,
        address indexed buyer,
        address receiver,
        uint256 quantity
    );

    /// admin events
    event AcceptedCurrencyChanged(address indexed account, address currency, bool accepted);
    event RoyaltiesEnabledChanged(address indexed account, bool royaltiesEnabled);
    event MaxRoyaltiesUpdated(address indexed account, uint256 maxRoyaltiesBasisPoints);

    /// ============ Custom Errors ============

    error ListingDoesNotExist(uint256 listingId);
    error NotListingSeller(uint256 listingId);
    error NotContractAddress(address addr);
    error CurrencyNotAccepted(address currency);
    error SellerDoesNotOwnToken(uint256 tokenId, uint256 quantity);
    error NullAddress();
    error NullQuantity();
    error TokenIdMismatch(uint256 listedTokenId);
    error PriceMismatch(uint256 listedPrice);
    error CurrencyMismatch(address listedCurrency);
    error CanNotSellToSelf();
    error AvailableQuantityInsuficient(uint256 availableQuantity);
    error RoyaltiesTooHigh(uint256 royaltyAmount, uint256 totalPrice);
    error InvalidMaxRoyalties();

    /// ============ Modifiers ============

    modifier onlySeller(uint256 _id) {
        if (listings[_id].seller != _msgSender()) revert NotListingSeller(_id);
        _;
    }

    modifier listingExists(uint256 _id) {
        if (listings[_id].seller == address(0)) revert ListingDoesNotExist(_id);
        _;
    }

    /// ============ Constructor ============

    constructor(
        address _nft,
        address _trustedForwarder,
        address[] memory _initialCurrencies
    ) {
        /// initialize the address of the NFT contract
        if (!_nft.isContract()) revert NotContractAddress(_nft);
        nft = ShowtimeERC1155(_nft);

        for (uint256 i = 0; i < _initialCurrencies.length; i++) {
            address currency = _initialCurrencies[i];
            if (!currency.isContract()) revert NotContractAddress(currency);
            acceptedCurrencies[currency] = true;
        }

        /// set the trustedForwarder only once, see BaseRelayRecipient
        if (_trustedForwarder == address(0)) revert NullAddress();
        trustedForwarder = _trustedForwarder;
    }

    /// ============ Marketplace functions ============

    /// @notice `setApprovalForAll` before calling
    /// @notice creates a new Listing
    /// @param _quantity the number of tokens to be listed
    /// @param _price the price per token
    function createSale(
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _currency
    ) external whenNotPaused returns (uint256 listingId) {
        address seller = _msgSender();

        if (!acceptedCurrencies[_currency]) revert CurrencyNotAccepted(_currency);
        if (_quantity == 0) revert NullQuantity();
        if (nft.balanceOf(seller, _tokenId) < _quantity) revert SellerDoesNotOwnToken(_tokenId, _quantity);

        Listing memory listing = Listing({
            tokenId: _tokenId,
            quantity: _quantity,
            price: _price,
            currency: IERC20(_currency),
            seller: seller
        });

        listingId = listingCounter;
        listings[listingId] = listing;

        // no need to check for overflows here
        unchecked {
            listingCounter++;
        }

        emit ListingCreated(listingId, seller, _tokenId);
    }

    /// @notice cancel an active sale
    function cancelSale(uint256 _listingId) external listingExists(_listingId) onlySeller(_listingId) {
        delete listings[_listingId];

        emit ListingDeleted(_listingId, _msgSender());
    }

    /// @notice the seller may own fewer NFTs than the listed quantity
    function availableForSale(uint256 _listingId) public view listingExists(_listingId) returns (uint256) {
        Listing memory listing = listings[_listingId];
        return Math.min(nft.balanceOf(listing.seller, listing.tokenId), listing.quantity);
    }

    /// @notice Complete a sale
    /// @param _quantity the number of tokens to purchase
    /// @param _receiver the address that will receive the NFTs
    /// @dev we let the transaction complete even if the currency is no longer accepted in order to avoid stuck listings
    function buy(
        uint256 _listingId,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price,
        address _currency,
        address _receiver
    ) external listingExists(_listingId) whenNotPaused {
        /// 1. Checks
        if (_quantity == 0) revert NullQuantity();
        if (_receiver == address(0)) revert NullAddress();

        Listing memory listing = listings[_listingId];

        // to prevent issues with block reorgs, we need to make sure that the expectations of the buyer (tokenId,
        // price and currency) match with the listing
        if (listing.tokenId != _tokenId) revert TokenIdMismatch(listing.tokenId);
        if (listing.price != _price) revert PriceMismatch(listing.price);
        if (address(listing.currency) != _currency) revert CurrencyMismatch(address(listing.currency));

        // disable buying something from the seller for the seller
        // note that the seller can still buy from themselves as a gift for someone else
        // the difference with a transfer is that this will result in royalties being paid out
        if (_receiver == listing.seller) revert CanNotSellToSelf();

        uint256 availableQuantity = availableForSale(_listingId);
        if (_quantity > availableQuantity) revert AvailableQuantityInsuficient(availableQuantity);

        uint256 totalPrice = listing.price * _quantity;
        (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties(listing.tokenId, totalPrice);
        if (royaltyAmount > totalPrice) revert RoyaltiesTooHigh(royaltyAmount, totalPrice);

        /// 2. Effects
        updateListing(_listingId, availableQuantity - _quantity);

        emit SaleCompleted(_listingId, listing.seller, _msgSender(), _receiver, _quantity);

        /// 3. Interactions
        // transfer royalties
        if (royaltyAmount > 0) {
            emit RoyaltyPaid(royaltyReceiver, listing.currency, royaltyAmount);
            listing.currency.safeTransferFrom(_msgSender(), royaltyReceiver, royaltyAmount);
        }

        // the royalty amount is deducted from the price paid by the buyer
        listing.currency.safeTransferFrom(_msgSender(), listing.seller, totalPrice - royaltyAmount);

        // transfer the NFTs from the seller to the buyer
        nft.safeTransferFrom(listing.seller, _receiver, listing.tokenId, _quantity, "");
    }

    /// ============ Utility functions ============

    /// @notice update the listing with the remaining quantity, or delete it if newQuantity is zero
    function updateListing(uint256 listingId, uint256 newQuantity) private {
        if (newQuantity == 0) {
            address seller = listings[listingId].seller;
            delete listings[listingId];
            emit ListingDeleted(listingId, seller);
        } else {
            listings[listingId].quantity = newQuantity;
        }
    }

    function getRoyalties(uint256 tokenId, uint256 price)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!royaltiesEnabled) {
            return (address(0), 0);
        }

        (receiver, royaltyAmount) = nft.royaltyInfo(tokenId, price);

        // we ignore royalties to address 0, otherwise the transfer would fail
        // and it would result in NFTs that are impossible to sell
        if (receiver == address(0) || royaltyAmount == 0) {
            return (address(0), 0);
        }

        royaltyAmount = capRoyalties(price, royaltyAmount);
    }

    function capRoyalties(uint256 salePrice, uint256 royaltyAmount) private view returns (uint256) {
        uint256 maxRoyaltiesAmount = (salePrice * maxRoyaltiesBasisPoints) / 100_00;
        return Math.min(maxRoyaltiesAmount, royaltyAmount);
    }

    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    /// ============ Admin functions ============

    /// @notice switch royalty payments on/off
    function setRoyaltiesEnabled(bool newValue) external onlyOwner {
        royaltiesEnabled = newValue;

        emit RoyaltiesEnabledChanged(_msgSender(), royaltiesEnabled);
    }

    /// @notice sets the maximum royalties that will be paid during sales, in basis points
    /// ex: if a token requests 75% royalties but maxRoyaltiesBasisPoints is set to 60_00 (= 60%),
    ///    then 60% will be paid out instead of the 75% requested
    function setMaxRoyalties(uint256 newValue) external onlyOwner {
        if (newValue > 100_00) revert InvalidMaxRoyalties();
        maxRoyaltiesBasisPoints = newValue;

        emit MaxRoyaltiesUpdated(_msgSender(), maxRoyaltiesBasisPoints);
    }

    /// @notice add a currency to the accepted currency list
    function setAcceptedCurrency(address currency, bool accepted) external onlyOwner {
        if (accepted && !currency.isContract()) revert NotContractAddress(currency);
        acceptedCurrencies[currency] = accepted;

        emit AcceptedCurrencyChanged(_msgSender(), currency, accepted);
    }

    /// @notice pause the contract
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice unpause the contract
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier:MIT
pragma solidity =0.8.7;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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