// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IRoyalties.sol";
import "../role-manager/LibRole.sol";
import "./LibTransfer.sol";

contract UltiMarketplace is ERC721HolderUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using ERC165CheckerUpgradeable for address;
    using LibTransfer for address payable;

    bytes4 public constant CURRENCY_TYPE_BNB = bytes4(keccak256("CURRENCY_TYPE_BNB"));
    bytes4 public constant CURRENCY_TYPE_ERC20 = bytes4(keccak256("CURRENCY_TYPE_ERC20"));

    struct Amount {
        uint256 value;
        address currency;
    }

    struct Auction {
        address payable seller;
        uint256 startPrice;
        uint256 buyNowPrice;
        address currency;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address payable highestBidder;
    }

    string public name;
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => bytes4) private _availableCurrencies;
    LibShare.Share private _marketplaceFee;
    IRoleManager private _roleManager;

    event AuctionCreated(address nftAddress, uint256 tokenId);
    event AuctionFinalized(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address indexed caller,
        address indexed recipient
    );
    event BidPlaced(address nftAddress, uint256 tokenId, uint256 bidAmount, address indexed bidder);
    event BuyNowCompleted(address nftAddress, uint256 tokenId, uint256 price, address indexed purchaser);

    modifier onlyRole(bytes32 role) {
        require(_roleManager.accountHasRole(msg.sender, role), "Invalid role");
        _;
    }

    function initialize(
        LibShare.Share calldata fee,
        IRoleManager roleManager,
        address ultiCoin
    ) external initializer {
        __ERC721Holder_init();
        __ReentrancyGuard_init();
        __UltiMarketplace_init_unchained(fee, roleManager, ultiCoin);
    }

    function __UltiMarketplace_init_unchained(
        LibShare.Share calldata fee,
        IRoleManager roleManager,
        address ultiCoin
    ) internal initializer {
        _marketplaceFee = fee;
        _roleManager = roleManager;
        name = "Ulti Marketplace";

        _addCurrency(ultiCoin, CURRENCY_TYPE_ERC20);
    }

    function setMarketplaceFee(LibShare.Share calldata fee) external onlyRole(LibRole.ADMIN_ROLE) {
        _marketplaceFee = fee;
    }

    function getMarketplaceFeeShare() external view returns (uint32) {
        return _marketplaceFee.value;
    }

    function addCurrency(address currencyAddress, bytes4 currencyType) external onlyRole(LibRole.ADMIN_ROLE) {
        require(_availableCurrencies[currencyAddress] == 0, "Currency already exists");
        _addCurrency(currencyAddress, currencyType);
    }

    function removeCurrency(address currencyAddress) external onlyRole(LibRole.ADMIN_ROLE) {
        require(_availableCurrencies[currencyAddress] != 0, "Currency does not exist");
        _removeCurrency(currencyAddress);
    }

    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 buyNowPrice,
        address currency,
        uint256 startTime,
        uint256 endTime
    ) external {
        _validateNftAddress(nftAddress);
        _validateAuctionCreation(nftAddress, tokenId, startPrice, buyNowPrice, currency, startTime, endTime);

        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        auctions[nftAddress][tokenId] = Auction({
            seller: payable(msg.sender),
            startPrice: startPrice,
            buyNowPrice: buyNowPrice,
            currency: currency,
            tokenId: tokenId,
            startTime: startTime,
            endTime: endTime,
            highestBid: 0,
            highestBidder: payable(address(0))
        });

        emit AuctionCreated(nftAddress, tokenId);
    }

    function bid(
        address nftAddress,
        uint256 tokenId,
        Amount memory amount
    ) external payable nonReentrant {
        _validateNftAddress(nftAddress);

        Auction storage auction = auctions[nftAddress][tokenId];
        _validateBid(auction, amount);

        if (auction.buyNowPrice > 0 && amount.value == auction.buyNowPrice) {
            _payOffLastBidder(auction);
            _finalizeAuction(nftAddress, tokenId, amount, auction.seller, msg.sender);
            emit BuyNowCompleted(nftAddress, tokenId, amount.value, msg.sender);
        } else {
            _placeBid(auction, amount, msg.sender);
            emit BidPlaced(nftAddress, tokenId, amount.value, msg.sender);
        }
    }

    function buyNow(
        address nftAddress,
        uint256 tokenId,
        Amount memory amount
    ) external payable nonReentrant {
        _validateNftAddress(nftAddress);

        Auction storage auction = auctions[nftAddress][tokenId];
        _validateBuyNow(auction, amount);

        _payOffLastBidder(auction);
        if (_availableCurrencies[amount.currency] == CURRENCY_TYPE_ERC20) {
            IERC20Upgradeable(amount.currency).transferFrom(msg.sender, address(this), amount.value);
        }
        _finalizeAuction(nftAddress, tokenId, amount, auction.seller, msg.sender);
        emit BuyNowCompleted(nftAddress, tokenId, amount.value, msg.sender);
    }

    function finalize(address nftAddress, uint256 tokenId) external nonReentrant {
        _validateNftAddress(nftAddress);

        Auction storage auction = auctions[nftAddress][tokenId];
        _validateFinalizing(auction);

        address purchaser;
        Amount memory amount;
        if (auction.highestBidder != address(0)) {
            purchaser = auction.highestBidder;
            amount = Amount(auction.highestBid, auction.currency);
        } else {
            purchaser = auction.seller;
            amount = Amount(0, auction.currency);
        }
        _finalizeAuction(nftAddress, tokenId, amount, auction.seller, purchaser);

        emit AuctionFinalized(nftAddress, tokenId, amount.value, msg.sender, purchaser);
    }

    function _placeBid(
        Auction storage auction,
        Amount memory amount,
        address bidder
    ) internal {
        _payOffLastBidder(auction);
        if (_availableCurrencies[amount.currency] == CURRENCY_TYPE_ERC20) {
            IERC20Upgradeable(amount.currency).transferFrom(bidder, address(this), amount.value);
        }
        auction.highestBid = amount.value;
        auction.highestBidder = payable(bidder);
    }

    function _finalizeAuction(
        address nftAddress,
        uint256 tokenId,
        Amount memory amount,
        address payable seller,
        address buyer
    ) internal {
        uint256 transferred = _transferMarketplaceFee(amount);
        transferred += _transferRoyalties(nftAddress, tokenId, amount);
        _transfer(seller, amount.value - transferred, amount.currency);

        IERC721(nftAddress).safeTransferFrom(address(this), buyer, tokenId);

        delete auctions[nftAddress][tokenId];
    }

    function _validateNftAddress(address nftAddress) internal view {
        require(nftAddress.isContract(), "NFT address is not a contract");
        require(nftAddress.supportsInterface(type(IERC721).interfaceId), "NFT contract does not implement IERC721");
    }

    function _validateAuctionCreation(
        address nftAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 buyNowPrice,
        address currency,
        uint256 startTime,
        uint256 endTime
    ) internal view {
        require(msg.sender == IERC721(nftAddress).ownerOf(tokenId), "Auction creation caller is not a token owner");
        require(_availableCurrencies[currency] != 0, "Auction creation query with non existing currency");
        require(startPrice > 0, "Auction creation query with non positive start price");

        if (buyNowPrice > 0) {
            require(buyNowPrice >= startPrice, "Auction creation query with buy now price lower than start price");
        } else {
            require(endTime > block.timestamp, "Auction creation query with invalid end time");
        }

        if (startTime > 0) {
            require(startTime > block.timestamp, "Auction creation query with past start time");
            require(endTime == 0 || endTime > startTime, "Auction creation query with invalid end time");
        } else {
            require(endTime == 0 || endTime > block.timestamp, "Auction creation query with invalid end time");
        }

        uint256 fees = _marketplaceFee.value;
        if (nftAddress.supportsInterface(type(IRoyalties).interfaceId)) {
            LibShare.Share[] memory royalties = IRoyalties(nftAddress).getRoyalties(tokenId);
            for (uint256 i = 0; i < royalties.length; i++) {
                fees += royalties[i].value;
            }
        }
        require(fees < 10000, "Sum of fees exceeds a limit");
    }

    function _validateBid(Auction storage auction, Amount memory amount) internal view {
        require(msg.sender != auction.seller, "Bid caller is a token owner");
        require(block.timestamp >= auction.startTime, "Bid query before auction started");
        require(auction.endTime > 0, "Bid query for infinite auction");
        require(block.timestamp <= auction.endTime, "Bid query after auction ended");
        require(amount.currency == auction.currency, "Bid and auction currencies do not match");
        if (_availableCurrencies[amount.currency] == CURRENCY_TYPE_BNB) {
            require(amount.value == msg.value, "Bid query with invalid BNB amount sent");
        }
        require(amount.value > auction.startPrice && amount.value > auction.highestBid, "Bid is too low");
        if (auction.buyNowPrice > 0) {
            require(amount.value <= auction.buyNowPrice, "Bid amount is greater than buy now price");
        }
    }

    function _validateBuyNow(Auction storage auction, Amount memory amount) internal view {
        require(msg.sender != auction.seller, "Buy now caller is a token owner");
        require(auction.endTime == 0 || block.timestamp <= auction.endTime, "Buy now query after auction ended");
        require(amount.currency == auction.currency, "Buy now and auction currencies do not match");
        if (_availableCurrencies[amount.currency] == CURRENCY_TYPE_BNB) {
            require(amount.value == msg.value, "Buy now query with invalid BNB amount sent");
        }
        require(amount.value >= auction.buyNowPrice, "Buy now query with insufficient amount");
    }

    function _validateFinalizing(Auction storage auction) internal view {
        if (auction.endTime == 0) {
            require(msg.sender == auction.seller, "Cannot finalize infinite auction if not seller");
        }
        require(block.timestamp >= auction.endTime, "Auction finalization query before auction is ended");
    }

    function _addCurrency(address currencyAddress, bytes4 currencyType) private {
        _availableCurrencies[currencyAddress] = currencyType;
    }

    function _removeCurrency(address currencyAddress) private {
        _availableCurrencies[currencyAddress] = 0;
    }

    function _transfer(
        address payable recipient,
        uint256 value,
        address currency
    ) internal {
        bytes4 currencyType = _availableCurrencies[currency];
        if (currencyType == CURRENCY_TYPE_BNB) {
            recipient.transferBNB(value);
        } else if (currencyType == CURRENCY_TYPE_ERC20) {
            recipient.transferERC20(value, IERC20Upgradeable(currency));
        }
    }

    function _payOffLastBidder(Auction storage auction) private {
        if (auction.highestBid > 0) {
            _transfer(auction.highestBidder, auction.highestBid, auction.currency);
        }
    }

    function _transferMarketplaceFee(Amount memory totalAmount) private returns (uint256) {
        uint256 fee = (totalAmount.value * _marketplaceFee.value) / LibShare.SHARE_DIVISOR;
        _transfer(payable(_marketplaceFee.account), fee, totalAmount.currency);
        return fee;
    }

    function _transferRoyalties(
        address nftAddress,
        uint256 tokenId,
        Amount memory totalAmount
    ) private returns (uint256) {
        uint256 transferred = 0;

        if (nftAddress.supportsInterface(type(IRoyalties).interfaceId)) {
            LibShare.Share[] memory royalties = IRoyalties(nftAddress).getRoyalties(tokenId);
            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 value = (totalAmount.value * royalties[i].value) / LibShare.SHARE_DIVISOR;
                _transfer(payable(address(royalties[i].account)), value, totalAmount.currency);
                transferred += value;
            }
        }
        return transferred;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IRoleManager {
    function accountHasRole(address account, bytes32 role) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../tokens/LibShare.sol";

interface IRoyalties {
    function getRoyalties(uint256 tokenId) external view returns (LibShare.Share[] memory);

    function transferRoyaltyShare(
        uint256 tokenId,
        address from,
        address to
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library LibRole {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library LibTransfer {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function transferBNB(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "BNB transfer failed");
    }

    function transferERC20(
        address payable recipient,
        uint256 amount,
        IERC20Upgradeable erc20Token
    ) internal {
        erc20Token.safeTransfer(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library LibShare {
    uint32 public constant SHARE_DIVISOR = 10000;

    struct Share {
        address account;
        uint32 value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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