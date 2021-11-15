//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./commons/GameCurrency.sol";
import "./commons/WanakaBase.sol";
import "./commons/PermissionRight.sol";

import "./erc20/WaiToken.sol";
import "./interfaces/IOrderContract.sol";

contract OrderContract is
    PermissionRight,
    Pausable,
    WanakaStorage,
    IOrderContract,
    ReentrancyGuard,
    GameCurrency
{
    using SafeERC20 for IERC20;
    using Address for address;

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _exchangeCurrency - Address of the ERC20 accepted for this marketplace
     * @param _gameCurrency - Address of the ERC20 accepted for this game
     * @param _listingFeeHolder - Address of fee holder
     * @param _shareProfitHolder - Address of profit holder
     * @param _listingFeeInBps - Listing fee per order creation
     * @param _shareProfitInBps - Share profit per each transaction for holder : sample: 50
     * @param _shareProfitToBasePriceInBps - Share profit per each transaction to increase the price of NFT: sample: 200
     * @param _owner - owner of this contract
     */
    constructor(
        IERC20 _exchangeCurrency,
        WaiToken _gameCurrency,
        address _listingFeeHolder,
        address _shareProfitHolder,
        uint32 _listingFeeInBps,
        uint32 _shareProfitInBps,
        uint32 _shareProfitToBasePriceInBps,
        address _owner
    ) public GameCurrency(_exchangeCurrency, _gameCurrency) {
        _setShareProfit(_listingFeeInBps, _shareProfitInBps, _shareProfitToBasePriceInBps);
        _setFeeHolder(_listingFeeHolder, _shareProfitHolder);
        _addAdminUser(_owner);
        transferOwnership(_owner);
    }

    /**
     * @dev Sets the listing fee that's charged to users to publish items
     * @param _listingFeeHolder - The address listing fee holder
     * @param _shareProfitHolder - The address share profit holder
     */
    function setFeeHolder(address _listingFeeHolder, address _shareProfitHolder)
        external
        onlyAdmin
    {
        _setFeeHolder(_listingFeeHolder, _shareProfitHolder);
    }

    /**
     * @dev Sets the fee config
     * @param _listingFeeInBps - Listing fee per order creation
     * @param _shareProfitInBps - Share profit per each transaction for holder : sample: 50
     * @param _shareProfitToBasePriceInBps - Share profit per each transaction to increase the price of NFT: sample: 200
     */
    function setFeeConfig(
        uint32 _listingFeeInBps,
        uint32 _shareProfitInBps,
        uint32 _shareProfitToBasePriceInBps
    ) external onlyAdmin {
        _setShareProfit(_listingFeeInBps, _shareProfitInBps, _shareProfitToBasePriceInBps);
    }

    function setWLandContract(address contractAddress) external onlyAdmin {
        require(_validateContract(contractAddress), "Wanaka: Land contract address is in-valid");
        wLandContractAddress = contractAddress;
        emit WLandContractChanged(contractAddress);
    }

    function setWItemContract(address contractAddress) external onlyAdmin {
        require(_validateContract(contractAddress), "Wanaka: Item contract address is in-valid");
        wItemContractAddress = contractAddress;
        emit WItemContractChanged(contractAddress);
    }

    /**
     * @dev Returns true if order exists
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     */
    function orderExist(address contractAddress, uint256 itemId)
        external
        view
        override
        returns (bool)
    {
        return orderByItemId[contractAddress][itemId].id != bytes32(0);
    }

    /**
     * @dev Returns listing fee if setted
     * @param orderPrice - Price of Order
     */
    function listingFeeInWei(uint256 orderPrice) external view override returns (uint256) {
        return _getListingFeeInWei(orderPrice);
    }

    /**
     * @dev Creates a new order
     * @param contractAddress - Address of the published NFT
     * @param itemId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order (in hours)
     */
    function createOrder(
        address contractAddress,
        uint256 itemId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external override nonReentrant whenNotPaused {
        _createOrder(contractAddress, itemId, priceInWei, expiresAt);
    }

    function cancelOrder(address contractAddress, uint256 itemId)
        external
        override
        nonReentrant
        whenNotPaused
    {
        address sender = _msgSender();
        Order memory order = orderByItemId[contractAddress][itemId];
        require(order.id != 0, "Wanaka: Order is not listed");
        // require sender is seller if actor is seller
        require(order.seller == sender, "Wanaka: Unauthorized user");
        _cancelOrder(order);
    }

    function executeOrder(
        address contractAddress,
        uint256 itemId,
        uint256 price
    ) external override nonReentrant whenNotPaused {
        _executeOrder(contractAddress, itemId, price);
    }

    function createOffer(
        address contractAddress,
        uint256 itemId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external override nonReentrant whenNotPaused {
        _createOffer(contractAddress, itemId, priceInWei, expiresAt);
    }

    function cancelOffer(address contractAddress, uint256 itemId)
        external
        override
        nonReentrant
        whenNotPaused
    {
        _cancelOffer(contractAddress, _msgSender(), itemId);
    }

    function takeOffer(
        address contractAddress,
        address buyer,
        uint256 itemId,
        uint256 price
    ) external override nonReentrant whenNotPaused {
        _takeOffer(contractAddress, buyer, itemId, price);
    }

    function _setFeeHolder(address _listingFeeHolder, address _shareProfitHolder) private {
        require(
            _listingFeeHolder != address(this) && _listingFeeHolder != address(0),
            "Wanaka: _listingFeeHolder is invalid"
        );
        require(
            _shareProfitHolder != address(this) && _shareProfitHolder != address(0),
            "Wanaka: _shareProfitHolder is invalid"
        );
        feeConfig.listingFeeHolder = _listingFeeHolder;
        feeConfig.shareProfitHolder = _shareProfitHolder;
        emit ChangedFeeHolder(_listingFeeHolder, _shareProfitHolder);
    }

    function _setShareProfit(
        uint32 _listingFeeInBps,
        uint32 _shareProfitInBps,
        uint32 _shareProfitToBasePriceInBps
    ) private {
        require(
            _listingFeeInBps <= LISTING_FEE_MAXIMUM,
            "Wanaka: _listingFeeInBps is over the maximum"
        );
        require(
            _shareProfitInBps + _shareProfitToBasePriceInBps <= SHARE_PROFIT_MAXIMUM,
            "Wanaka: _shareProfitInBps + _shareProfitToBasePriceInBps is over the maximum"
        );
        feeConfig.listingFeeInBps = _listingFeeInBps;
        feeConfig.shareProfitInBps = _shareProfitInBps;
        feeConfig.shareProfitToBasePriceInBps = _shareProfitToBasePriceInBps;

        emit ChangedFeeConfig(_listingFeeInBps, _shareProfitInBps, _shareProfitToBasePriceInBps);
    }

    /**
     * @dev Creates a new order for NFT
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order (in hours)
     */
    function _createOrder(
        address contractAddress,
        uint256 itemId,
        uint256 priceInWei,
        uint256 expiresAt
    ) internal {
        address seller = _msgSender();
        NFTDetail memory detail = _getDetails(contractAddress, itemId);
        require(seller == detail.ownerOfItem, "Wanaka: Only the owner can create orders");
        require(detail.inInventory, "Wanaka: Should move the item to inventory first");
        require(priceInWei > detail.floorPrice, "Wanaka: Price should be greater than floorPrice");
        require(
            expiresAt > block.timestamp + MIN_ORDER_DURATION,
            "Wanaka: Listing should be more than 5 minutes in the future"
        );
        _requireApproved(contractAddress, seller, itemId);

        uint256 _listingFeeInWei = 0;
        Order memory existedOrder = orderByItemId[contractAddress][itemId];
        if (existedOrder.id != bytes32(0)) {
            _cancelOrder(existedOrder);
        }
        // Check if there's a listing fee and
        // transfer the amount to marketplace owner
        if (feeConfig.listingFeeInBps > 0) {
            _listingFeeInWei = _getListingFeeInWei(priceInWei);
            exchangeCurrency.safeTransferFrom(seller, address(this), _listingFeeInWei);
        }
        AssetType assetTypeEnum = _getAssetType(contractAddress);
        bytes32 orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                detail.ownerOfItem,
                uint256(assetTypeEnum),
                itemId,
                contractAddress,
                priceInWei
            )
        );

        orderByItemId[contractAddress][itemId] = Order({
            id: orderId,
            assetType: assetTypeEnum,
            seller: seller,
            nftContractAddress: contractAddress,
            itemId: itemId,
            quantity: 1,
            price: priceInWei,
            expiresAt: expiresAt,
            listingFeeBacked: _listingFeeInWei
        });

        emit OrderCreated(orderId, itemId, seller, contractAddress, priceInWei, expiresAt);
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller
     * @param order - Order of the NFT
     */
    function _cancelOrder(Order memory order) internal {
        // Check if there's a listing fee and
        // transfer the amount back to NFT owner
        if (order.listingFeeBacked > 0) {
            exchangeCurrency.safeTransfer(order.seller, order.listingFeeBacked);
        }

        emit OrderCancelled(order.id, order.itemId, order.seller, order.nftContractAddress);
        _emptyOrder(order.nftContractAddress, order.itemId);
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     * @param price - Order price this ensures that the NFT price does not change when the order is accepted.
     */
    function _executeOrder(
        address contractAddress,
        uint256 itemId,
        uint256 price
    ) internal returns (Order memory order) {
        address buyer = _msgSender();
        order = orderByItemId[contractAddress][itemId];
        require(order.id != 0, "Wanaka: Item is not listed");
        require(order.seller != address(0), "Wanaka: Invalid address");
        require(order.seller != buyer, "Wanaka: Unauthorized user");

        NFTDetail memory detail = _getDetails(contractAddress, itemId);
        require(detail.inInventory, "Wanaka: The Item must be in the inventory");
        require(order.seller == detail.ownerOfItem, "Wanaka: The seller is no longer the owner");
        require(order.price == price, "Wanaka: The price is not correct");
        require(block.timestamp < order.expiresAt, "Wanaka: The order expired");

        if (bidByBidder[contractAddress][itemId][buyer].id != bytes32(0)) {
            // cancel the previous offer
            _cancelOffer(contractAddress, buyer, itemId);
        }
        if (order.listingFeeBacked > 0) {
            exchangeCurrency.safeTransfer(feeConfig.listingFeeHolder, order.listingFeeBacked);
        }
        uint256 saleShareAmount = 0;
        // The amount will be adding to the base price if NFT is Land type.
        uint256 incPriceAmount = 0;
        if (feeConfig.shareProfitInBps > 0) {
            // Calculate sale share
            saleShareAmount += (price * feeConfig.shareProfitInBps) / BPS;
            // Transfer share amount to profit holder
            exchangeCurrency.safeTransferFrom(buyer, feeConfig.shareProfitHolder, saleShareAmount);
        }
        // only land for this logic
        // each transation will share a little amount to the base price
        AssetType assetTypeEnum = _getAssetType(contractAddress);
        if (assetTypeEnum == AssetType.WLand && feeConfig.shareProfitToBasePriceInBps > 0) {
            // Calculate sale share
            incPriceAmount += (price * feeConfig.shareProfitToBasePriceInBps) / BPS;
            // keep a little amount to the the base price of NFT
            exchangeCurrency.safeTransferFrom(buyer, wLandContractAddress, incPriceAmount);
            // increase the base price
            // each transation will share a little amount to the base price
            uint256 newPrice = detail.floorPrice + incPriceAmount;
            WLandInterfaceLight(wLandContractAddress).increaseBasePrice(itemId, newPrice);
        }
        // Transfer sale amount to seller
        exchangeCurrency.safeTransferFrom(
            buyer,
            order.seller,
            price - (saleShareAmount + incPriceAmount)
        );
        // Transfer Land owner
        _doTransfer(contractAddress, order.seller, buyer, assetTypeEnum, itemId);

        emit OrderSuccessful(order.id, itemId, order.seller, contractAddress, price, buyer);

        _emptyOrder(contractAddress, itemId);
    }

    /**
     * @dev Creates a new order for NFT
     * Buyer can create only once offer for each item at a time
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order (in hours)
     */
    function _createOffer(
        address contractAddress,
        uint256 itemId,
        uint256 priceInWei,
        uint256 expiresAt
    ) internal {
        address buyer = _msgSender();
        NFTDetail memory detail = _getDetails(contractAddress, itemId);

        require(buyer != detail.ownerOfItem, "Wanaka: Can not create offer for Item you own");
        require(priceInWei > detail.floorPrice, "Wanaka: Price should be greater than floorPrice");
        require(
            expiresAt > block.timestamp + MIN_ORDER_DURATION,
            "Wanaka: Listing should be more than 5 minutes in the future"
        );

        Offer memory currentOffer = bidByBidder[contractAddress][itemId][buyer];
        // check offer exists
        if (currentOffer.id != bytes32(0)) {
            require(currentOffer.price != priceInWei, "Wanaka: Duplicated offer");
            if (currentOffer.price > priceInWei) {
                // buyer decrease the offer's price, refund the different amount
                exchangeCurrency.safeTransfer(buyer, currentOffer.price - priceInWei);
            } else {
                // buyer increase the offer's price, collect the different amount
                exchangeCurrency.safeTransferFrom(
                    buyer,
                    address(this),
                    priceInWei - currentOffer.price
                );
            }
            delete bidByBidder[contractAddress][itemId][buyer];
            emit OfferCancelled(currentOffer.id, contractAddress, itemId, buyer);
        } else {
            exchangeCurrency.safeTransferFrom(buyer, address(this), priceInWei);
        }

        bytes32 id = keccak256(
            abi.encodePacked(block.timestamp, contractAddress, buyer, itemId, priceInWei)
        );

        bidByBidder[contractAddress][itemId][buyer] = Offer({
            id: id,
            assetType: detail.assetType,
            nftContractAddress: contractAddress,
            itemId: itemId,
            quantity: 1,
            price: priceInWei,
            expiresAt: expiresAt
        });
        emit OfferCreated(
            id,
            contractAddress,
            itemId,
            buyer,
            detail.ownerOfItem,
            priceInWei,
            expiresAt
        );
    }

    /**
     * @dev Cancel an already published offer
     *  can only be canceled by buyer
     * @param contractAddress - Address of the NFT
     * @param buyer - Address of the buyer
     * @param itemId - ID of the published NFT
     */
    function _cancelOffer(
        address contractAddress,
        address buyer,
        uint256 itemId
    ) private returns (Offer memory offer) {
        offer = bidByBidder[contractAddress][itemId][buyer];
        require(offer.id != bytes32(0), "Wanaka: Offer does not exists");

        exchangeCurrency.safeTransfer(buyer, offer.price);
        // emit BidCancelled event
        emit OfferCancelled(offer.id, contractAddress, itemId, buyer);

        // remove currentOffer from the cached
        delete bidByBidder[contractAddress][itemId][buyer];
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param contractAddress - Address of the NFT
     * @param buyer - Address of the buyer
     * @param itemId - ID of the published NFT
     * @param minPrice - Offer min price
     */
    function _takeOffer(
        address contractAddress,
        address buyer,
        uint256 itemId,
        uint256 minPrice
    ) private returns (Offer memory offer) {
        address seller = _msgSender();
        require(seller != buyer, "Wanaka: Can not take offer you own");
        NFTDetail memory detail = _getDetails(contractAddress, itemId);
        require(detail.inInventory, "Wanaka: The Item must be in the inventory");
        require(seller == detail.ownerOfItem, "Wanaka: The seller is no longer the owner");
        offer = bidByBidder[contractAddress][itemId][buyer];
        require(offer.id != bytes32(0), "Wanaka: Offer does not exists");
        require(
            offer.price >= minPrice,
            "Wanaka: The price of offer has been changed, please check again"
        );
        require(block.timestamp < offer.expiresAt, "Wanaka: The offer expired");
        _requireApproved(contractAddress, seller, itemId);

        uint256 saleShareAmount = 0;
        // The amount will be adding to the base price if NFT is Land type.
        uint256 incPriceAmount = 0;
        if (feeConfig.shareProfitInBps > 0) {
            // Calculate sale share
            saleShareAmount += (offer.price * feeConfig.shareProfitInBps) / BPS;
            // Transfer share amount to profit holder
            exchangeCurrency.safeTransfer(feeConfig.shareProfitHolder, saleShareAmount);
        }
        // only land for this logic
        // each transation will share a little amount to the base price
        AssetType assetTypeEnum = _getAssetType(contractAddress);
        if (assetTypeEnum == AssetType.WLand && feeConfig.shareProfitToBasePriceInBps > 0) {
            // Calculate sale share
            incPriceAmount += (offer.price * feeConfig.shareProfitToBasePriceInBps) / BPS;
            // keep a little amount to the the base price of NFT
            exchangeCurrency.safeTransfer(wLandContractAddress, incPriceAmount);
            // change the base price
            // each transation will share a little amount to the base price
            uint256 newPrice = detail.floorPrice + incPriceAmount;
            WLandInterfaceLight(wLandContractAddress).increaseBasePrice(itemId, newPrice);
        }
        uint256 actualPrice = offer.price - (saleShareAmount + incPriceAmount);
        // Transfer sale amount to seller
        exchangeCurrency.safeTransfer(seller, actualPrice);

        // cancel order from Order Contract if its exist
        Order memory order = orderByItemId[contractAddress][itemId];
        if (order.id != bytes32(0)) {
            _cancelOrder(order);
        }
        // Transfer item owner
        _doTransfer(contractAddress, seller, buyer, assetTypeEnum, itemId);

        // remove currentOffer from the cached
        delete bidByBidder[contractAddress][itemId][buyer];

        emit OfferAccepted(
            offer.id,
            contractAddress,
            itemId,
            buyer,
            seller,
            offer.price,
            saleShareAmount
        );
    }

    function _getListingFeeInWei(uint256 orderPrice) private view returns (uint256) {
        return (feeConfig.listingFeeInBps * orderPrice) / BPS;
    }

    function _doTransfer(
        address contractAddress,
        address seller,
        address buyer,
        AssetType assetType,
        uint256 itemId
    ) private {
        W721InterfaceLight wContract = W721InterfaceLight(contractAddress);
        wContract.safeTransferFrom(seller, buyer, itemId);
        emit ItemTransferred(seller, buyer, assetType, itemId);
    }

    function _emptyOrder(address addr, uint256 itemId) private {
        orderByItemId[addr][itemId].id = bytes32(0);
        delete orderByItemId[addr][itemId];
    }

    function _requireApproved(
        address contractAddress,
        address seller,
        uint256 itemId
    ) private view {
        W721InterfaceLight wContract = W721InterfaceLight(contractAddress);
        require(
            wContract.getApproved(itemId) == address(this) ||
                wContract.isApprovedForAll(seller, address(this)),
            "Wanaka: The contract is not authorized, please approve it before"
        );
    }

    function _getDetails(address contractAddress, uint256 itemId)
        private
        view
        returns (NFTDetail memory detail)
    {
        detail.assetType = _getAssetType(contractAddress);
        if (detail.assetType == AssetType.WLand) {
            WLandInterfaceLight wContract = WLandInterfaceLight(contractAddress);
            (detail.ownerOfItem, detail.floorPrice, , , detail.inInventory, ) = wContract
                .getLandData(itemId);
        }
        if (detail.assetType == AssetType.WItem) {
            WItemInterfaceLight wContract = WItemInterfaceLight(contractAddress);
            (detail.ownerOfItem, detail.floorPrice, , ) = wContract.getItemData(itemId);
            detail.inInventory = true;
        }
    }

    function _getAssetType(address contractAddress) private view returns (AssetType assetType) {
        if (contractAddress == wLandContractAddress) {
            assetType = AssetType.WLand;
        } else if (contractAddress == wItemContractAddress) {
            assetType = AssetType.WItem;
        } else {
            revert("Wanaka: contract address does not supports");
        }
    }

    function _validateContract(address contractAddress) private view returns (bool) {
        if (contractAddress == address(0)) return false;
        if (!contractAddress.isContract()) return false;
        return true;
    }
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
    constructor () {
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

    constructor () {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PermissionRight.sol";
import "../erc20/WaiToken.sol";

contract GameCurrency is PermissionRight {
    // Token as a currency it will be using for rewarding in the game.
    WaiToken public gameCurrency;
    // Token as a currency it will be using for exchange in the market.
    IERC20 public exchangeCurrency;

    constructor(IERC20 _exchangeCurrency, WaiToken _gameCurrency) {
        exchangeCurrency = _exchangeCurrency;
        gameCurrency = _gameCurrency;
    }

    /**
     * @notice Sets currency token using in the game.
     */
    function setGameCurrency(WaiToken tokenAddr) external onlyOwner {
        require(address(tokenAddr) != address(0));
        gameCurrency = tokenAddr;
    }

    /**
     * @notice Sets exchange token using in the marketplace.
     */
    function setExchangeCurrency(IERC20 tokenAddr) external onlyOwner {
        require(address(tokenAddr) != address(0));
        exchangeCurrency = tokenAddr;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface W721InterfaceLight {
    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/**
 * @title Light Interface for contracts conforming to ERC-721
 */
interface WLandInterfaceLight {
    function getLandData(uint256 itemId)
        external
        view
        returns (
            address ownerOfItem,
            uint256 salePrice,
            uint256 level,
            uint256 releaseVersion,
            bool inInventory,
            string memory name
        );

    function increaseBasePrice(uint256 itemId, uint256 incPrice) external;
}

/**
 * @title Light Interface for contracts conforming to ERC-721
 */
interface WItemInterfaceLight {
    function getItemData(uint256 itemId)
        external
        view
        returns (
            address ownerOfItem,
            uint256 salePrice,
            uint256 rarity,
            string memory name
        );
}

contract WanakaStorage {
    /// @title The Land's types
    enum Environment {
        Basic,
        Forest,
        Sea
    }
    enum AssetType {
        WLand,
        WItem
    }

    struct Order {
        // Order ID
        bytes32 id;
        // Asset type
        AssetType assetType;
        // Owner of the NFT
        address seller;
        // NFT contract address
        address nftContractAddress;
        // NFT's quantity, required if NFT item
        uint16 quantity;
        // NFT's ID
        uint256 itemId;
        // Price (in wei) for the listed item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
        // Cached The listing fee, it will be used when canceling order
        uint256 listingFeeBacked;
    }

    struct Offer {
        bytes32 id;
        // Asset type
        AssetType assetType;
        // NFT contract address
        address nftContractAddress;
        // NFT's ID
        uint256 itemId;
        // NFT's quantity, required if NFT item
        uint16 quantity;
        // Price (in wei) for the listed item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
    }

    struct NFTDetail {
        AssetType assetType;
        address ownerOfItem;
        bool inInventory;
        uint256 floorPrice;
    }

    struct FeeConfig {
        address listingFeeHolder;
        // The fee that seller have to pay for market to list on market
        // and must be <= LISTING_FEE_MAXIMUM
        uint32 listingFeeInBps;
        address shareProfitHolder;
        // The profit percent that seller will share for the owner of contract
        // based on UNIT_FOR_SHARE_PROFIT
        // shareProfitInBps + shareProfitToBasePriceInBps <= SHARE_PROFIT_MAXIMUM
        uint32 shareProfitInBps;
        // The profit to add to basePrice of NFT
        // based on UNIT_FOR_SHARE_PROFIT
        uint32 shareProfitToBasePriceInBps;
    }

    uint256 public constant LISTING_FEE_MAXIMUM = 50; // equivalent 0.5%
    uint256 internal constant MIN_ORDER_DURATION = 5 minutes;
    uint256 public constant BPS = 10000;
    // the maximum of share fee that ensure that every transaction is safe
    // total share profit = SHARE_PROFIT_MAXIMUM / UNIT_FOR_SHARE_PROFIT = 2.5 %
    uint256 public constant SHARE_PROFIT_MAXIMUM = 250;
    // Order by address => itemId => Order
    mapping(address => mapping(uint256 => Order)) public orderByItemId;
    // Bid by token address => token id => buyer address => bid
    mapping(address => mapping(uint256 => mapping(address => Offer))) public bidByBidder;
    FeeConfig public feeConfig;
    address public wLandContractAddress;
    address public wItemContractAddress;

    // EVENTS
    event OrderCreated(
        bytes32 id,
        uint256 indexed itemId,
        address indexed seller,
        address indexed nftContractAddress,
        uint256 priceInWei,
        uint256 expiresAt
    );
    event OrderSuccessful(
        bytes32 id,
        uint256 indexed itemId,
        address indexed seller,
        address indexed nftContractAddress,
        uint256 totalPrice,
        address buyer
    );
    event OrderCancelled(
        bytes32 id,
        uint256 indexed itemId,
        address indexed seller,
        address indexed nftContractAddress
    );

    event OfferCreated(
        bytes32 id,
        address indexed nftContractAddress,
        uint256 indexed itemId,
        address indexed buyer,
        address seller,
        uint256 price,
        uint256 expiresAt
    );
    event OfferAccepted(
        bytes32 id,
        address indexed nftContractAddress,
        uint256 indexed itemId,
        address indexed buyer,
        address seller,
        uint256 price,
        uint256 fee
    );
    event OfferCancelled(
        bytes32 id,
        address indexed nftContractAddress,
        uint256 indexed itemId,
        address indexed buyer
    );

    event ChangedFeeHolder(address indexed listingFeeHolder, address indexed profitShareHolder);
    event ChangedFeeConfig(
        uint32 listingFeeInBps,
        uint32 shareProfitInBps,
        uint32 shareProfitToBasePriceInBps
    );

    event ItemsTransferred(
        address seller,
        address buyer,
        uint256 itemId,
        AssetType assetType,
        uint256[] ids,
        uint256[] quantities
    );
    event ItemTransferred(address seller, address buyer, AssetType assetType, uint256 itemId);
    event ItemDetached(uint256 itemId, uint256 assetType, uint256 id, uint256 quantity);
    event ItemAttached(uint256 itemId, uint256 assetType, uint256 id, uint256 quantity);

    event WLandContractChanged(address indexed newContractAddress);
    event WItemContractChanged(address indexed newContractAddress);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PermissionRight is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal adminGroup;
    EnumerableSet.AddressSet internal operatorGroup;

    event AdminUserAdded(address indexed candidate);
    event AdminUserRemoved(address indexed account);
    event OperatorUserAdded(address indexed candidate);
    event OperatorUserRemoved(address indexed account);

    modifier onlyAdmin() {
        require(
            adminGroup.contains(_msgSender()),
            "PermissionRight: You're not in the admin group"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            operatorGroup.contains(_msgSender()),
            "PermissionRight: You're not in the operator group"
        );
        _;
    }

    function inAdminGroup() internal view returns (bool) {
        return adminGroup.contains(_msgSender());
    }

    function inOperatorGroup() internal view returns (bool) {
        return inOperatorGroup(_msgSender());
    }

    function inOperatorGroup(address user) internal view returns (bool) {
        return operatorGroup.contains(user);
    }

    function listAdminUser() external view onlyOwner returns (address[] memory _users) {
        _users = new address[](adminGroup.length());
        for (uint256 i = 0; i < adminGroup.length(); i++) {
            _users[i] = adminGroup.at(i);
        }
    }

    function listOperatorUser() external view onlyOwner returns (address[] memory _users) {
        _users = new address[](operatorGroup.length());
        for (uint256 i = 0; i < operatorGroup.length(); i++) {
            _users[i] = operatorGroup.at(i);
        }
    }

    // Adds an candidate to admin group.
    function addAdminUser(address candidate) external onlyOwner {
        _addAdminUser(candidate);
    }

    // Removes an address from admin group.
    function removeAdminUser(address user) external onlyOwner {
        adminGroup.remove(user);
        emit AdminUserRemoved(user);
    }

    // Adds an candidate to operator group.
    function addOperatorUser(address candidate) external onlyAdmin {
        _addOperatorUser(candidate);
    }

    // Removes an address from operator group.
    function removeOperatorUser(address user) external onlyAdmin {
        operatorGroup.remove(user);
        emit OperatorUserRemoved(user);
    }

    function _addOperatorUser(address candidate) internal {
        operatorGroup.add(candidate);
        emit OperatorUserAdded(candidate);
    }

    function _addAdminUser(address candidate) internal {
        adminGroup.add(candidate);
        emit AdminUserAdded(candidate);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "../commons/PermissionRight.sol";

contract WaiToken is ERC20Burnable, Ownable, PermissionRight {
    constructor(
        address _owner, 
        string memory _tokenName, 
        string memory _tokenSymbol
    ) 
    public 
    ERC20(_tokenName, _tokenSymbol) {
        _addAdminUser(_owner);
        _addOperatorUser(_owner);
        transferOwnership(_owner);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
    function mint(address account, uint256 amount) external onlyOperator {
        super._mint(account, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IOrderContract {
    /**
     * @dev Returns true if order exists
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     */
    function orderExist(address contractAddress, uint256 itemId) external returns (bool);

    /**
     * @dev Returns listing fee if setted from the order Price
     * @param orderPrice - Price of Order
     */
    function listingFeeInWei(uint256 orderPrice) external returns (uint256);

    /**
     * @dev Creates a new order
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order
     */
    function createOrder(
        address contractAddress,
        uint256 itemId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external;

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     */
    function cancelOrder(address contractAddress, uint256 itemId) external;

    /**
     * @dev Executes the sale for a published NFT
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     * @param price - Order minPrice this ensures that the NFT price does not change when the order is accepted.
     */
    function executeOrder(
        address contractAddress,
        uint256 itemId,
        uint256 price
    ) external;

    /**
     * @dev Creates a new offer
     * Buyer can create only once offer for each item at a time
     * If exist it will be replaced
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the order (in hours)
     */
    function createOffer(
        address contractAddress,
        uint256 itemId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external;

    /**
     * @dev Cancel an already published offer
     *  can only be canceled by seller
     * @param contractAddress - Address of the NFT
     * @param itemId - ID of the published NFT
     */
    function cancelOffer(address contractAddress, uint256 itemId) external;

    /**
     * @dev Executes the sale for a published NFT
     * @param contractAddress - Address of the NFT
     * @param buyer - Address of the buyer
     * @param itemId - ID of the published NFT
     * @param price - Order price
     * required:
     * quantity >=1 with NFT item
     */
    function takeOffer(
        address contractAddress,
        address buyer,
        uint256 itemId,
        uint256 price
    ) external;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

