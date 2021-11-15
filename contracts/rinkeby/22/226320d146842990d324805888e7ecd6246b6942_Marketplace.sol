// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./IMarketplace.sol";
import "../base/Base.sol";
import "./BaseUpgradeableMarketPlaceInitializer.sol";
import "../access/Accessible.sol";

import "../libs/ECRecoverLib.sol";

contract Marketplace is BaseUpgradeableMarketPlaceInitializer, IMarketplace {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using ECRecoverLib for ECRecoverLib.ECDSAVariables;

    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

    mapping(bytes => bool) public inactiveOrders;
    mapping(bytes => bool) public inactiveAuctions;
    mapping(bytes => bool) public inactiveBids;

    address public feeReceiver;

    function initialize(
        address marketplaceSettingsAddress,
        address platformSettingsAddress,
        address accessListAddress
    ) public override initializer {
        super.initialize(marketplaceSettingsAddress, platformSettingsAddress, accessListAddress);
        feeReceiver = address(this);
    }

    function acceptOffchainBid(
        OffchainAuction memory auction,
        OffchainBid memory bid,
        ECRecoverLib.ECDSAVariables memory sellerECDSA,
        ECRecoverLib.ECDSAVariables memory bidderECDSA
    )
        public
        whenPlatformIsNotPaused
        whenMarketplaceIsNotPaused
        onlyAccountGrantedAccess(msg.sender)
        onlyProjectGrantedAccess(auction.nftContract)
    {
        require(!inactiveAuctions[auction.id], "AUCTION_NO_LONGER_ACTIVE");
        require(auction.seller == msg.sender, "ONLY_SELLER_CAN_ACCEPT_BIDS");
        require(block.timestamp < auction.expiresAt, "THE_AUCTION_HAS_EXPIRED");
        require(!inactiveBids[bid.id], "BID_NO_LONGER_ACTIVE");
        require(auction.startingPrice <= bid.price, "BID_TOO_LOW");

        bytes32 sellerHash = keccak256(
            abi.encodePacked(
                auction.id,
                auction.nftContract,
                auction.tokenId,
                auction.startingPrice,
                auction.expiresAt
            )
        );
        uint256 auctionFingerprint = uint256(sellerHash);
        bytes32 bidderHash = keccak256(
            abi.encodePacked(
                bid.id,
                bid.price,
                auctionFingerprint,
                auction.nftContract,
                auction.tokenId,
                auction.startingPrice,
                auction.expiresAt
            )
        );

        // Prove to contract that seller signed to create this auction
        sellerECDSA.verifySign(auction.seller, sellerHash);

        // Prove to contract that bidder signed to bid this price on this auction
        bidderECDSA.verifySign(bid.bidder, bidderHash);

        // deactivate auction
        _inactivateAuction(auction.id);

        // deactivate bid
        _inactivateBid(bid.id);

        // swap goods
        _requireERC721(auction.nftContract);

        _transferShares(bid.bidder, bid.price);

        // Transfer sale amount to seller
        require(
            ERC20Interface(_getAcceptedToken()).transferFrom(
                bid.bidder,
                auction.seller,
                bid.price - _getShares(bid.price)
            ),
            "SALE_AMOUNT_TRANSFER_FAILED"
        );

        // Transfer asset owner
        ERC721Interface(auction.nftContract).safeTransferFrom(
            auction.seller,
            bid.bidder,
            auction.tokenId
        );

        emit AuctionSuccessful(
            auction.id,
            auction.seller,
            auction.nftContract,
            auction.tokenId,
            bid.bidder,
            bid.price
        );
    }

    function purchaseOffchainDutchAuction(
        OffchainDutchAuction memory auction,
        ECRecoverLib.ECDSAVariables memory sellerECDSA,
        uint256 price
    )
        public
        whenPlatformIsNotPaused
        whenMarketplaceIsNotPaused
        onlyAccountGrantedAccess(msg.sender)
        onlyProjectGrantedAccess(auction.nftContract)
    {
        require(!inactiveOrders[auction.id], "AUCTION_NO_LONGER_ACTIVE");
        require(auction.expiresAt > auction.beginsAt, "END_TIME_MUST_BE_GREATER_THAN_START_TIME");
        require(
            auction.startingPrice > auction.endingPrice,
            "START_PRICE_MUST_BE_GREATER_THAN_END_PRICE"
        );
        require(block.timestamp < auction.expiresAt, "THE_AUCTION_HAS_EXPIRED");
        require(block.timestamp >= auction.beginsAt, "THE_AUCTION_HAS_NOT_STARTED");

        require(price >= auction.endingPrice, "OFFER_PRICE_IS_TOO_LOW");
        require(price <= auction.startingPrice, "OFFER_PRICE_IS_TOO_HIGH");

        uint256 currentPrice = _getCurrentDutchPrice(auction);

        require(price >= currentPrice, "OFFER_PRICE_IS_LOWER_THAN_CURRENT_PRICE");

        // Prove to contract that seller signed to create this auction
        bytes32 sellerHash = keccak256(
            abi.encodePacked(
                auction.id,
                auction.nftContract,
                auction.tokenId,
                auction.startingPrice,
                auction.endingPrice,
                auction.beginsAt,
                auction.expiresAt
            )
        );

        sellerECDSA.verifySign(auction.seller, sellerHash);

        _inactivateOrder(auction.id);

        _requireERC721(auction.nftContract);

        _transferShares(msg.sender, price);

        // Transfer sale amount to seller
        require(
            ERC20Interface(_getAcceptedToken()).transferFrom(
                msg.sender,
                auction.seller,
                price.sub(_getShares(price))
            ),
            "SALE_AMOUNT_TRANSFER_FAILED"
        );

        // Transfer asset owner
        ERC721Interface(auction.nftContract).safeTransferFrom(
            auction.seller,
            msg.sender,
            auction.tokenId
        );

        emit DutchAuctionExecutionSuccessful(
            auction.id,
            auction.seller,
            auction.nftContract,
            auction.tokenId,
            msg.sender,
            price
        );
    }

    function purchaseOffchainOrder(
        OffchainOrder memory order,
        ECRecoverLib.ECDSAVariables memory sellerECDSA
    )
        public
        whenPlatformIsNotPaused
        whenMarketplaceIsNotPaused
        onlyAccountGrantedAccess(msg.sender)
        onlyProjectGrantedAccess(order.nftContract)
    {
        require(!inactiveOrders[order.id], "ORDER_NO_LONGER_ACTIVE");
        require(block.timestamp < order.expiresAt, "THE_ORDER_HAS_EXPIRED");

        // Prove to contract that seller signed to create this auction
        bytes32 sellerHash = keccak256(
            abi.encodePacked(order.id, order.nftContract, order.tokenId, order.expiresAt)
        );

        sellerECDSA.verifySign(order.seller, sellerHash);

        _inactivateOrder(order.id);

        // swap goods
        _requireERC721(order.nftContract);

        _transferShares(msg.sender, order.price);

        // Transfer sale amount to seller
        require(
            ERC20Interface(_getAcceptedToken()).transferFrom(
                msg.sender,
                order.seller,
                order.price - _getShares(order.price)
            ),
            "SALE_AMOUNT_TRANSFER_FAILED"
        );

        // Transfer asset owner
        ERC721Interface(order.nftContract).safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );

        emit OrderExecutionSuccessful(
            order.id,
            order.seller,
            order.nftContract,
            order.tokenId,
            msg.sender,
            order.price
        );
    }

    function inactivateAuction(bytes memory id) external onlyOwner(msg.sender) {
        _inactivateAuction(id);
    }

    function inactivateBid(bytes memory id) external onlyOwner(msg.sender) {
        _inactivateBid(id);
    }

    function inactivateOrder(bytes memory id) external onlyOwner(msg.sender) {
        _inactivateOrder(id);
    }

    function setFeeReceiver(address newFeeReceiver) external onlyConfigurator(msg.sender) {
        require(
            newFeeReceiver != address(0x0) && newFeeReceiver != feeReceiver,
            "NEW_FEE_RECEIVER_INVALID"
        );
        address oldFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(oldFeeReceiver, newFeeReceiver);
    }

    /* Internal Funcctions  */

    function _transferShares(address bidder, uint256 price) internal {
        if (_getOwnerCutPerMillion() > 0) {
            uint256 saleShareAmount = _getShares(price);
            // Transfer share amount for marketplace Owner
            require(
                ERC20Interface(_getAcceptedToken()).transferFrom(
                    bidder,
                    feeReceiver,
                    saleShareAmount
                ),
                "FAILED_SHARE_TRANSFER"
            );
        }
    }

    function _requireERC721(address nftAddress) internal view {
        require(nftAddress.isContract(), "NFT_ADDRESS_MUST_BE_A_CONTRACT");
        ERC721Interface nftRegistry = ERC721Interface(nftAddress);
        require(
            nftRegistry.supportsInterface(ERC721_Interface),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }

    // Calculate sale share
    function _getShares(uint256 price) internal view returns (uint256) {
        return (price.mul(_getOwnerCutPerMillion())).div(1000000);
    }

    function _inactivateAuction(bytes memory id) internal {
        inactiveAuctions[id] = true;
        emit AuctionInactivated(id);
    }

    function _inactivateBid(bytes memory id) internal {
        inactiveBids[id] = true;
        emit BidInactivated(id);
    }

    function _inactivateOrder(bytes memory id) internal {
        inactiveOrders[id] = true;
        emit OrderInactivated(id);
    }

    function _getCurrentDutchPrice(OffchainDutchAuction memory order)
        internal
        view
        returns (uint256)
    {
        uint256 auctionCompletionPercentage = block.timestamp.sub(order.beginsAt).mul(100).div(
            order.expiresAt.sub(order.beginsAt)
        );
        uint256 dutchPriceRange = order.startingPrice.sub(order.endingPrice);
        uint256 ductPriceRangePercentage = dutchPriceRange
            .mul(uint256(100).sub(auctionCompletionPercentage))
            .div(100);
        return order.endingPrice.add(ductPriceRangePercentage);
    }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

/**
 * @title Interface for contracts conforming to ERC-20
 */
interface ERC20Interface {
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);
}

/**
 * @title Interface for contracts conforming to ERC-721
 */
interface ERC721Interface {
    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function approve(address _to, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function supportsInterface(bytes4) external view returns (bool);
}

interface IMarketplace {
    struct OffchainOrder {
        bytes id;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        uint256 expiresAt;
    }

    struct OffchainAuction {
        bytes id;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 expiresAt;
    }

    struct OffchainDutchAuction {
        bytes id;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 beginsAt;
        uint256 expiresAt;
    }

    struct OffchainBid {
        bytes id;
        address bidder;
        uint256 price;
    }

    // EVENTS
    event AuctionSuccessful(
        bytes id,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        address bidder,
        uint256 price
    );

    event OrderExecutionSuccessful(
        bytes id,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        address buyer,
        uint256 price
    );

    event DutchAuctionExecutionSuccessful(
        bytes id,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        address buyer,
        uint256 price
    );

    event ChangedPublicationFee(uint256 publicationFee);

    event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);

    event OrderInactivated(bytes id);

    event AuctionInactivated(bytes id);

    event BidInactivated(bytes id);

    event FeeReceiverUpdated(address indexed oldFeeReceiver, address indexed newFeeReceiver);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/MarketplaceSettingsConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../settings/IMarketplaceSettings.sol";
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract Base {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address public platformSettings;
    address public marketplaceSettings;

    /* Modifiers */

    modifier whenPlatformIsPaused() {
        require(_platformSettings().isPaused(), "PLATFORM_ISNT_PAUSED");
        _;
    }

    modifier whenPlatformIsNotPaused() {
        require(!_platformSettings().isPaused(), "PLATFORM_IS_PAUSED");
        _;
    }

    modifier whenMarketplaceIsPaused() {
        require(_marketplaceSettings().isPaused(), "MARKETPLACE_ISNT_PAUSED");
        _;
    }

    modifier whenMarketplaceIsNotPaused() {
        require(!_marketplaceSettings().isPaused(), "MARKETPLACE_IS_PAUSED");
        _;
    }

    modifier whenMarketplaceNewOrdersArePaused() {
        require(_marketplaceSettings().areNewOrdersPaused(), "MARKETPLACE_NEW_ORDERS_ARENT_PAUSED");
        _;
    }

    modifier whenMarketplaceNewOrdersAreNotPaused() {
        require(!_marketplaceSettings().areNewOrdersPaused(), "MARKETPLACE_NEW_ORDERS_ARE_PAUSED");
        _;
    }

    modifier onlyOwner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyConfigurator(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    modifier onlyPauser(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    /* Constructor */

    constructor(address marketplaceSettingsAddress, address platformSettingsAddress) {
        require(marketplaceSettingsAddress.isContract(), "MARKETPLACE_SETTINGS_MUST_BE_CONTRACT");
        require(platformSettingsAddress.isContract(), "PLATFORM_SETTINGS_MUST_BE_CONTRACT");
        platformSettings = platformSettingsAddress;
        marketplaceSettings = marketplaceSettingsAddress;
    }

    function setMarketplaceSettings(address newSettings) external onlyOwner(msg.sender) {
        require(newSettings.isContract(), "MARKETPLACE_SETTINGS_MUST_BE_CONTRACT");
        require(newSettings != platformSettings, "MARKETPLACE_SETTINGS_MUST_BE_NEW");
        address oldSettings = platformSettings;
        marketplaceSettings = newSettings;
        emit MarketplaceSettingsUpdated(oldSettings, newSettings);
    }

    function setPlatformSettings(address newSettings) external onlyOwner(msg.sender) {
        require(newSettings.isContract(), "PLATFORM_SETTINGS_MUST_BE_CONTRACT");
        require(newSettings != platformSettings, "PLATFORM_SETTINGS_MUST_BE_NEW");
        address oldSettings = platformSettings;
        platformSettings = newSettings;
        emit PlatformSettingsUpdated(oldSettings, newSettings);
    }

    /** Internal Functions */

    function _marketplaceSettings() internal view returns (IMarketplaceSettings) {
        return IMarketplaceSettings(marketplaceSettings);
    }

    function _marketplaceSettingsConsts() internal view returns (MarketplaceSettingsConsts) {
        return MarketplaceSettingsConsts(_marketplaceSettings().consts());
    }

    function _platformSettings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(platformSettings);
    }

    function _platformSettingsConsts() internal view returns (PlatformSettingsConsts) {
        return PlatformSettingsConsts(_platformSettings().consts());
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(platformSettings).rolesManager());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }

    function _getMarketplaceSettingsValue(bytes32 name) internal view returns (uint256) {
        return _marketplaceSettings().getSettingValue(name);
    }

    function _getPlatformSettingsValue(bytes32 name) internal view returns (uint256) {
        return _platformSettings().getSettingValue(name);
    }

    /**
        @return The marketplace operator's cut per million wei on all excuted orders
     */
    function _getOwnerCutPerMillion() internal view returns (uint256) {
        return _getMarketplaceSettingsValue(_marketplaceSettingsConsts().OWNER_CUT_PER_MILLION());
    }

    /**
        @return The marketplace fee that's charged to users to publish new orders
     */
    function _getPublicationFeeInWei() internal view returns (uint256) {
        return _getMarketplaceSettingsValue(_marketplaceSettingsConsts().PUBLICATION_FEE_IN_WEI());
    }

    /**
        @return The marketplace ERC20 token used in transactions
     */
    function _getAcceptedToken() internal view returns (address) {
        return _marketplaceSettings().getAcceptedToken();
    }

    /** Events */
    event MarketplaceSettingsUpdated(address indexed oldSettings, address indexed newSettings);
    event PlatformSettingsUpdated(address indexed oldSettings, address indexed newSettings);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../access/Accessible.sol";

contract BaseUpgradeableMarketPlaceInitializer is
    Accessible,
    Initializable,
    ContextUpgradeable
{
    function initialize(
        address marketplaceSettingsAddress,
        address platformSettingsAddress,
        address accessListAddress
    ) public virtual override initializer {
        __MarketPlace_init(marketplaceSettingsAddress, platformSettingsAddress, accessListAddress);
    }

    function __MarketPlace_init(
        address marketplaceSettingsAddress,
        address platformSettingsAddress,
        address accessListAddress
    ) internal initializer {
        Accessible.initialize(
            marketplaceSettingsAddress,
            platformSettingsAddress,
            accessListAddress
        );
        __Context_init_unchained();
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/MarketplaceSettingsConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "../settings/IMarketplaceSettings.sol";
import "../settings/IPlatformSettings.sol";
import "../access/IAccessList.sol";
import "../roles/IRolesManager.sol";
import "../base/BaseUpgradeable.sol";

abstract contract Accessible is BaseUpgradeable{
    using AddressUpgradeable for address;


    enum AccessStatus {
        notDenied,
        onlyAllowed
    }

    /* Constant Variables */


    /* State Variables */
    AccessStatus public accountAccessStatus;
    AccessStatus public projectAccessStatus;
  
    address public accessList;
    

    /* Modifiers */

    modifier onlyAccountGrantedAccess(address account) {
        require(_requireHasAccess(account, _getAccountAccessType()), "ACCOUNT_HASNT_ACCESS");
        _;
    }

    modifier onlyProjectGrantedAccess(address project) {
        require(_requireHasAccess(project, _getProjectAccessType()), "PROJECT_HASNT_ACCESS");
        _;
    }

    /* Constructor */
    function initialize(
        address marketplaceSettingsAddress,
        address platformSettingsAddress,
        address accessListAddress
    ) public virtual {
        require(accessListAddress.isContract(), "ACCESS_LIST_MUST_BE_CONTRACT");
        BaseUpgradeable.initialize(marketplaceSettingsAddress, platformSettingsAddress);
        accessList = accessListAddress;
        accountAccessStatus = AccessStatus.notDenied;
        projectAccessStatus = AccessStatus.notDenied;
    }


    // TODO: Add setAccesList function

    function setAccountAccessStatus(AccessStatus status) external onlyConfigurator(msg.sender) {
        accountAccessStatus = status;
        emit AccountAccessStatusChanged(status);
    }

    function setProjectAccessStatus(AccessStatus status) external onlyConfigurator(msg.sender) {
        projectAccessStatus = status;
        emit ProjectAccessStatusChanged(status);
    }


    /** Internal Functions */

    function _accessList() internal view returns (IAccessList) {
        return IAccessList(accessList);
    }


    function _requireHasAccess(address account, IAccessList.AccessListType accessListType)
        internal
        view
        returns (bool)
    {
        if (accessListType == IAccessList.AccessListType.deniedList) {
            return !_accessList().isAddressInList(account, accessListType);
        } else {
            return _accessList().isAddressInList(account, accessListType);
        }
    }

    function _getAccountAccessType() internal view returns (IAccessList.AccessListType) {
        //  IAccessList.AccessListType accessListType;
        if (accountAccessStatus == AccessStatus.notDenied) {
            return IAccessList.AccessListType.deniedList;
        } else {
            return IAccessList.AccessListType.allowedList;
        }
    }

    function _getProjectAccessType() internal view returns (IAccessList.AccessListType) {
        //  IAccessList.AccessListType accessListType;
        if (projectAccessStatus == AccessStatus.notDenied) {
            return IAccessList.AccessListType.deniedList;
        } else {
            return IAccessList.AccessListType.allowedList;
        }
    }

    /** Events */
    event AccountAccessStatusChanged(AccessStatus status);
    event ProjectAccessStatusChanged(AccessStatus status);
    
}

//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity <0.9.0;

library ECRecoverLib {
    string private constant SIGNATURE_HEADER = "\x19Ethereum Signed Message:\n32";

    struct ECDSAVariables {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function verifySign(
        ECDSAVariables memory self,
        address signer,
        bytes32 signerHash
    ) internal pure {
        require(
            signer ==
                ecrecover(
                    keccak256(abi.encodePacked(SIGNATURE_HEADER, signerHash)),
                    self.v,
                    self.r,
                    self.s
                ),
            "NOT_SIGNED_ACTION"
        );
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

contract MarketplaceSettingsConsts {
    bytes32 public constant OWNER_CUT_PER_MILLION = "OwnerCutPerMillion";

    bytes32 public constant PUBLICATION_FEE_IN_WEI = "PublicationFeeInWei";
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

contract PlatformSettingsConsts {
    bytes32 public constant FEE = "Fee";

    bytes32 public constant BONUS_MULTIPLIER = "BonusMultiplier";

    bytes32 public constant ALLOW_ONLY_EOA = "AllowOnlyEOA";

    bytes32 public constant RATE_TOKEN_PAUSED = "RATETokenPaused";
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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IMarketplaceSettings {
    event MarketplacePaused(address indexed pauser);

    event MarketplaceUnpaused(address indexed unpauser);

    event MarketplaceNewOrdersPaused(address indexed pauser);

    event MarketplaceNewOrdersUnpaused(address indexed unpauser);

    event MarketplaceSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    );

    event MarketplaceSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event MarketplaceSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    event MarketplaceAcceptedTokenUpdated(
        address indexed remover,
        address oldValue,
        address newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function areNewOrdersPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function requireNewOrdersArePaused() external view;

    function requireNewOrdersAreNotPaused() external view;

    function consts() external view returns (address);

    function pause() external;

    function unpause() external;

    function pauseNewOrders() external;

    function unpauseNewOrders() external;

    function getAcceptedToken() external view returns (address);

    function updateAcceptedToken(address _acceptedToken) external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IPlatformSettings {
    event PlatformPaused(address indexed pauser);

    event PlatformUnpaused(address indexed unpauser);

    event PlatformSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    );

    event PlatformSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event PlatformSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function consts() external view returns (address);

    function pause() external;

    function unpause() external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

interface IRolesManager {
    event MaxMultiItemsUpdated(address indexed updater, uint8 oldValue, uint8 newValue);

    function setMaxMultiItems(uint8 newMaxMultiItems) external;

    function multiGrantRole(bytes32 role, address[] calldata accounts) external;

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function consts() external view returns (address);

    function maxMultiItems() external view returns (uint8);

    function requireHasRole(bytes32 role, address account) external view;

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

library SettingsLib {
    /**
        It defines a setting. It includes: value, min, and max values.
     */
    struct Setting {
        uint256 value;
        uint256 min;
        uint256 max;
        bool exists;
    }

    /**
        @notice It creates a new setting given a name, min and max values.
        @param value initial value for the setting.
        @param min min value allowed for the setting.
        @param max max value allowed for the setting.
     */
    function create(
        Setting storage self,
        uint256 value,
        uint256 min,
        uint256 max
    ) internal {
        requireNotExists(self);
        require(value >= min, "VALUE_MUST_BE_GT_MIN_VALUE");
        require(value <= max, "VALUE_MUST_BE_LT_MAX_VALUE");
        self.value = value;
        self.min = min;
        self.max = max;
        self.exists = true;
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the setting already exists.
        @param self the current setting.
     */
    function requireNotExists(Setting storage self) internal view {
        require(!self.exists, "SETTING_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the current setting doesn't exist.
        @param self the current setting.
     */
    function requireExists(Setting storage self) internal view {
        require(self.exists, "SETTING_NOT_EXISTS");
    }

    /**
        @notice It updates a current setting.
        @dev It throws a require error if:
            - The new value is equal to the current value.
            - The new value is not lower than the max value.
            - The new value is not greater than the min value
        @param self the current setting.
        @param newValue the new value to set in the setting.
     */
    function update(Setting storage self, uint256 newValue) internal returns (uint256 oldValue) {
        requireExists(self);
        require(self.value != newValue, "NEW_VALUE_REQUIRED");
        require(newValue >= self.min, "NEW_VALUE_MUST_BE_GT_MIN_VALUE");
        require(newValue <= self.max, "NEW_VALUE_MUST_BE_LT_MAX_VALUE");
        oldValue = self.value;
        self.value = newValue;
    }

    /**
        @notice It removes a current setting.
        @param self the current setting to remove.
     */
    function remove(Setting storage self) internal {
        requireExists(self);
        self.value = 0;
        self.min = 0;
        self.max = 0;
        self.exists = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

interface IAccessList {
    enum AccessListType {
        allowedList,
        deniedList
    }

    enum ActionType {
        addAddress,
        removeAddress
    }

    enum AccessAddressType {
        partnerAddress,
        nftTokenAddress,
        ethAccountAddress
    }

    struct DeniedListStruct {
        address deniedListedAddress;
        AccessAddressType deniedListedAddressType;
        address addressOfRequestor;
        bool exists;
    }

    struct AccessListStruct {
        address inputAddress;
        AccessAddressType clientAddressType;
        address addressOfRequestor;
        bool exists;
    }

    function addAddressToList(
        address inputAddress,
        AccessAddressType inputAddressType,
        AccessListType accessListType
    ) external;

    function isAddressInList(address inputAddress, AccessListType accessListType)
        external
        view
        returns (bool);

    function removeAddressFromList(
        address inputAddress,
        AccessAddressType inputAddressType,
        AccessListType accessListType
    ) external;

    event PartnerAddressAddedToList(
        address indexed partnerAddress,
        AccessListType indexed accessListType
    );
    event PartnerAddressRemovedFromList(
        address indexed partnerAddress,
        AccessListType indexed accessListType
    );
    event NFTAddressAddedToList(address indexed nftAddress, AccessListType indexed accessListType);
    event NFTAddressRemovedFromList(
        address indexed partnerAddress,
        AccessListType indexed accessListType
    );
    event EthAccountAddressAddedToList(
        address indexed partnerAddress,
        AccessListType indexed accessListType
    );
    event EthAccountAddressRemovedFromList(
        address indexed partnerAddress,
        AccessListType indexed accessListType
    );
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <0.9.0;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/MarketplaceSettingsConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "../settings/IMarketplaceSettings.sol";
import "../settings/IPlatformSettings.sol";
import "../access/IAccessList.sol";
import "../roles/IRolesManager.sol";

abstract contract BaseUpgradeable {
    using AddressUpgradeable for address;

    /* Constant Variables */

    /* State Variables */
    address public platformSettings;
    address public marketplaceSettings;

    /* Modifiers */

    modifier whenPlatformIsPaused() {
        require(_platformSettings().isPaused(), "PLATFORM_ISNT_PAUSED");
        _;
    }

    modifier whenPlatformIsNotPaused() {
        require(!_platformSettings().isPaused(), "PLATFORM_IS_PAUSED");
        _;
    }

    modifier whenMarketplaceIsPaused() {
        require(_marketplaceSettings().isPaused(), "MARKETPLACE_ISNT_PAUSED");
        _;
    }

    modifier whenMarketplaceIsNotPaused() {
        require(!_marketplaceSettings().isPaused(), "MARKETPLACE_IS_PAUSED");
        _;
    }

    modifier whenMarketplaceNewOrdersArePaused() {
        require(_marketplaceSettings().areNewOrdersPaused(), "MARKETPLACE_NEW_ORDERS_ARENT_PAUSED");
        _;
    }

    modifier whenMarketplaceNewOrdersAreNotPaused() {
        require(!_marketplaceSettings().areNewOrdersPaused(), "MARKETPLACE_NEW_ORDERS_ARE_PAUSED");
        _;
    }

    modifier onlyOwner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyConfigurator(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    modifier onlyPauser(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    /* Constructor */
    function initialize(
        address marketplaceSettingsAddress,
        address platformSettingsAddress
    ) public virtual {
        require(marketplaceSettingsAddress.isContract(), "MARKETPLACE_SETTINGS_MUST_BE_CONTRACT");
        require(platformSettingsAddress.isContract(), "PLATFORM_SETTINGS_MUST_BE_CONTRACT");
        platformSettings = platformSettingsAddress;
        marketplaceSettings = marketplaceSettingsAddress;
    }

    function setMarketplaceSettings(address newSettings) external onlyOwner(msg.sender) {
        require(newSettings.isContract(), "MARKETPLACE_SETTINGS_MUST_BE_CONTRACT");
        require(newSettings != platformSettings, "MARKETPLACE_SETTINGS_MUST_BE_NEW");
        address oldSettings = platformSettings;
        marketplaceSettings = newSettings;
        emit MarketplaceSettingsUpdated(oldSettings, newSettings);
    }

    function setPlatformSettings(address newSettings) external onlyOwner(msg.sender) {
        require(newSettings.isContract(), "PLATFORM_SETTINGS_MUST_BE_CONTRACT");
        require(newSettings != platformSettings, "PLATFORM_SETTINGS_MUST_BE_NEW");
        address oldSettings = platformSettings;
        platformSettings = newSettings;
        emit PlatformSettingsUpdated(oldSettings, newSettings);
    }

    // TODO: Add setAccesList function

    /** Internal Functions */

    function _marketplaceSettings() internal view returns (IMarketplaceSettings) {
        return IMarketplaceSettings(marketplaceSettings);
    }

    function _marketplaceSettingsConsts() internal view returns (MarketplaceSettingsConsts) {
        return MarketplaceSettingsConsts(_marketplaceSettings().consts());
    }

    function _platformSettings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(platformSettings);
    }

    function _platformSettingsConsts() internal view returns (PlatformSettingsConsts) {
        return PlatformSettingsConsts(_platformSettings().consts());
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(platformSettings).rolesManager());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }

    function _getPlatformSettingsValue(bytes32 name) internal view returns (uint256) {
        return _platformSettings().getSettingValue(name);
    }

    function _getMarketplaceSettingsValue(bytes32 name) internal view returns (uint256) {
        return _marketplaceSettings().getSettingValue(name);
    }

    /**
        @return The marketplace operator's cut per million wei on all excuted orders
     */
    function _getOwnerCutPerMillion() internal view returns (uint256) {
        return _getMarketplaceSettingsValue(_marketplaceSettingsConsts().OWNER_CUT_PER_MILLION());
    }

    /**
        @return The marketplace fee that's charged to users to publish new orders
     */
    function _getPublicationFeeInWei() internal view returns (uint256) {
        return _getMarketplaceSettingsValue(_marketplaceSettingsConsts().PUBLICATION_FEE_IN_WEI());
    }

    /**
        @return The marketplace ERC20 token used in transactions
     */
    function _getAcceptedToken() internal view returns (address) {
        return _marketplaceSettings().getAcceptedToken();
    }

    /** Events */
    event MarketplaceSettingsUpdated(address indexed oldSettings, address indexed newSettings);
    event PlatformSettingsUpdated(address indexed oldSettings, address indexed newSettings);
}

