// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./external/IRouter.sol";
import "./external/Staking.sol";
import "./external/StakingToken.sol";
import "./interfaces/INidhiNFT.sol";
import "./utils/NidhiCollection.sol";
import "./utils/SafeNidhiCollection.sol";
import "./NidhiProfile.sol";

contract NidhiMarket is ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeNidhiCollection for NidhiCollection;
    using SafeNidhiCollection for mapping (address => NidhiCollection);

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint tokenId;
        address seller;
        address owner;
        address paymentToken;
        uint price;
        uint payoutAmount;
        uint stakedAmount;
        uint gons;
        bool listed;
    }

    struct MarketItemDetails {
        uint itemId;
        address nftContract;
        uint tokenId;
        address owner;
        string ownerName;
        bool listed;
        address seller;
        string sellerName;
        address paymentToken;
        uint price;
        uint payoutPercentage;
        uint totalValue;
        uint redeemableValue;
    }

    IERC20 public immutable GURU;
    StakingToken public immutable SGURU;
    Staking public immutable staking;
    NidhiProfile public immutable profile;
    IRouter public immutable router;

    mapping (address => uint) public minPrice;

    uint public minStakingPercentage = 1000; // 10%
    uint public fee; // 0%

    address public feeCollector;

    uint private _itemIds;
    address private _owner;

    mapping (address => bool) _isWhitelistedNFT;
    mapping (address => bool) _isPaymentToken;
    mapping (address => NidhiCollection) private _listedItemsByCreator;
    mapping (address => NidhiCollection) private _itemsByCreator;
    mapping (address => NidhiCollection) private _itemsByOwner;
    mapping (address => mapping (uint => uint)) private _tokenIdToItemId;
    mapping (uint => MarketItem) private _idToMarketItem;
    mapping (address => address[]) private _routerPaths;
    mapping (uint => mapping (address => bool)) _buyerWhitelist;

    address[] private _paymentTokens;

    NidhiCollection private _listedItems;
// todo add payment token to events
    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint price,
        uint payoutAmount,
        uint stakedAmount
    );

    event MarketItemSold(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address buyer,
        uint price,
        uint stakedAmount,
        uint feeAmount
    );

    event MarketItemDelisted(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId
    );

    event MarketItemImported(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId
    );

    event PassiveIncomeRedeemed(
        uint indexed itemId,
        address indexed owner,
        uint value,
        uint newStakedAmount
    );

    constructor(
        address tokenAddress,
        address stakingTokenAddress,
        address stakingContractAddress,
        address profileContractAddress,
        address routerAddress
    ) {
        _owner = msg.sender;
        _listedItems = new NidhiCollection();
        GURU = IERC20(tokenAddress);
        SGURU = StakingToken(stakingTokenAddress);
        staking = Staking(stakingContractAddress);
        profile = NidhiProfile(profileContractAddress);
        router = IRouter(routerAddress);
        _paymentTokens.push(tokenAddress);
        _isPaymentToken[tokenAddress] = true;
        minPrice[tokenAddress] = 1e9;
    }

    function addWhitelistedNFT(address nftContract) external onlyOwner {
        _isWhitelistedNFT[nftContract] = true;
    }

    function removeWhitelistedNFT(address nftContract) external onlyOwner {
        delete _isWhitelistedNFT[nftContract];
    }

    /**
     * @dev Sets the minimum price for new market items.
     * The minimum price must be greater than 0.
     */
    function setMinPrice(address token, uint minPrice_) external onlyOwner {
        require(_isPaymentToken[token], "invalid payment token");
        require(minPrice_ > 0, "minimum price too low");
        minPrice[token] = minPrice_;
    }

    /**
     * @dev Sets the minimum staking percentage for new market items.
     * The minimum staking percentage must be greater than 0 and less
     * then or equal to 100.
     * The provided value is the actual percentage multiplied by 100.
     */
    function setMinStakingPercentage(uint minStakingPercentage_) external onlyOwner {
        require(minStakingPercentage_ <= 10000, "minimum percentage too high");
        minStakingPercentage = minStakingPercentage_;
    }

    /**
     * @dev Sets the TX fee that is applied to each purchase.
     */
    function setFee(uint fee_) external onlyOwner {
        require(feeCollector != address(0), "fee collector not set");
        require(fee_ <= 10000, "invalid fee");
        fee = fee_;
    }

    /**
     * @dev Sets the address where TX fees are being sent to.
     */
    function setFeeCollector(address feeCollector_) external onlyOwner {
        require(feeCollector_ != address(0) || fee == 0, "invalid fee collector");
        feeCollector = feeCollector_;
    }

    /**
     * @dev Transfers the contract ownership.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Adds a new token as payment option.
     */
    function addPaymentToken(
        address tokenAddress,
        uint minPrice_,
        address[] memory routerPath
    ) external onlyOwner {
        require(minPrice_ > 0, "minimum price too low");
        require(
            (tokenAddress == address(GURU) && routerPath.length == 0) ||
            (tokenAddress != address(GURU) &&
             routerPath[0] == tokenAddress &&
             routerPath[routerPath.length - 1] == address(GURU)),
            "invalid route"
        );
        if (!_isPaymentToken[tokenAddress]) {
            _paymentTokens.push(tokenAddress);
            _isPaymentToken[tokenAddress] = true;
        }
        minPrice[tokenAddress] = minPrice_;
        _routerPaths[tokenAddress] = routerPath;
    }

    /**
     * @dev Removes a token from payment options.
     */
    function removePaymentToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(GURU));
        delete _isPaymentToken[tokenAddress];
        delete _routerPaths[tokenAddress];
        delete minPrice[tokenAddress];
        uint len = _paymentTokens.length;
        bool shift;
        for (uint i = 0; i < len; i++) {
            if (shift) {
                _paymentTokens[i - 1] = _paymentTokens[i];
            } else if (_paymentTokens[i] == tokenAddress) {
                shift = true;
            }
        }
        if (shift) _paymentTokens.pop();
    }

    /**
     * @dev Returns all valid payment tokens.
     */
    function getPaymentTokens() external view returns (address[] memory) {
        return _paymentTokens;
    }

    /**
     * @dev Whitelists a list of buyer addresses for the provided item.
     * This will only affect the initial sale.
     */
    function addToBuyerWhitelist(
        uint itemId,
        address[] calldata buyerAddresses
    ) external {
        uint len = buyerAddresses.length;
        require(len > 0, "empty buyer list");
        MarketItem storage item = _idToMarketItem[itemId];
        address creator = INidhiNFT(item.nftContract).creatorOf(item.tokenId);
        require(creator == msg.sender, "caller is not the creator");
        address self = address(this);
        require(!_buyerWhitelist[itemId][self], "not initial listing");
        _buyerWhitelist[itemId][address(0)] = true;
        for (uint i = 0; i < len; i++) {
            address ba = buyerAddresses[i];
            _buyerWhitelist[itemId][buyerAddresses[i]] = ba != self;
        }
    }

    /**
     * @dev Resets the whitelist for the provided item. This will allow anyone
     * to purchase this item.
     */
    function resetBuyerWhitelist(uint itemId) external {
        MarketItem storage item = _idToMarketItem[itemId];
        address creator = INidhiNFT(item.nftContract).creatorOf(item.tokenId);
        require(msg.sender == creator, "caller is not the creator");
        delete _buyerWhitelist[itemId][address(0)];
    }

    /**
     * @dev Adds the token to the creator's collection.
     * This function can only be called from whitelisted NFT contracts.
     */
    function addTokenToCreatorCollection(
        address creator,
        address nftContract,
        uint tokenId
    ) external {
        require(_isWhitelistedNFT[msg.sender], "caller is not whitelisted");
        uint itemId = _tokenIdToItemId[nftContract][tokenId];
        if (itemId != 0) {
            if (address(_itemsByCreator[creator]) == address(0)) {
                _itemsByCreator[creator] = new NidhiCollection();
            }
            _itemsByCreator[creator].append(itemId);
        }
    }

    /**
     * @dev Lists an item for sale on the marketplace.
     * The item itself will be transferred to the marketplace.
     */
    function listMarketItem(
        address nftContract,
        uint tokenId,
        address paymentToken,
        uint price,
        uint16 stakingPercentage
    )
        external nonReentrant
    {
        address seller = msg.sender;

        IERC721 erc721 = IERC721(nftContract);

        require(_isPaymentToken[paymentToken], "invalid payment token");
        require(erc721.ownerOf(tokenId) == seller, "caller is not the owner");
        require(price >= minPrice[paymentToken], "price too low");
        require(stakingPercentage <= 10000, "staking percentage too high");
        require(stakingPercentage >= minStakingPercentage, "staking percentage too low");

        uint staked = (price * stakingPercentage) / 10000;
        uint payout = price - staked;
        uint itemId = _tokenIdToItemId[nftContract][tokenId];

        if (itemId == 0) {
            itemId = _tokenIdToItemId[nftContract][tokenId] = ++_itemIds;
            _idToMarketItem[itemId] = MarketItem(
                itemId,
                nftContract,
                tokenId,
                seller,
                address(this),
                paymentToken,
                price,
                payout,
                0,
                0,
                true
            );
        } else {
            MarketItem storage item = _idToMarketItem[itemId];
            item.seller = seller;
            item.owner = address(this);
            item.paymentToken = paymentToken;
            item.price = price;
            item.payoutAmount = payout;
            item.listed = true;
        }

        INidhiNFT(nftContract).approvePublicTrading(tokenId, true);

        erc721.transferFrom(seller, address(this), tokenId);

        _itemsByOwner[seller].safeRemove(itemId);
        _listedItems.append(itemId);

        address creator = INidhiNFT(nftContract).creatorOf(tokenId);
        _listedItemsByCreator.safeAdd(creator, itemId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            seller,
            address(0),
            price,
            payout,
            staked
        );
    }

    /**
     * @dev Delists an item from the marketplace.
     * The item itself will be transferred back to the seller.
     */
    function delistMarketItem(uint itemId) external nonReentrant {

        MarketItem storage item = _idToMarketItem[itemId];

        address seller = item.seller;

        require(item.itemId == itemId, "invalid item id");
        require(seller == msg.sender, "caller is not the seller");

        address nftContract = item.nftContract;
        uint tokenId = item.tokenId;

        IERC721 nft = IERC721(nftContract);

        nft.transferFrom(address(this), item.seller, tokenId);

        item.seller = address(0);
        item.owner = address(seller);
        //item.price = 0;
        //item.payoutAmount = 0;
        item.listed = false;

        _itemsByOwner.safeAdd(seller, itemId);
        _listedItems.remove(itemId);

        address creator = INidhiNFT(nftContract).creatorOf(tokenId);
        _listedItemsByCreator[creator].safeRemove(itemId);

        if (item.stakedAmount == 0) {
            INidhiNFT(nftContract).approvePublicTrading(tokenId, false);
        }

        emit MarketItemDelisted(
            item.itemId,
            item.nftContract,
            item.tokenId
        );
    }

    /**
     * @dev Adds an arbitrary NFT to the user's collection.
     */
    function importMarketItem(address nftContract, uint tokenId) external {

        require(
            _isWhitelistedNFT[msg.sender],
            "caller is not whitelisted"
        );

        address owner = IERC721(nftContract).ownerOf(tokenId);
        uint itemId = _tokenIdToItemId[nftContract][tokenId];

        if (itemId == 0) {
            itemId = _tokenIdToItemId[nftContract][tokenId] = ++_itemIds;
            _idToMarketItem[itemId] = MarketItem(
                itemId,
                nftContract,
                tokenId,
                address(0),
                owner,
                address(0),
                0,
                0,
                0,
                0,
                false
            );
        } else {
            MarketItem storage item = _idToMarketItem[itemId];
            item.seller = address(0);
            item.owner = owner;
            //item.price = 0;
            //item.payoutAmount = 0;
            item.listed = false;
        }

        _itemsByOwner.safeAdd(owner, itemId);

        emit MarketItemImported(
            itemId,
            nftContract,
            tokenId
        );
    }

    /**
     * @dev Sells the market item.
     * Funds will be transferred to the seller and the staking contract.
     * The ownership of the item will be transferred to the buyer.
     */
    function purchaseMarketItem(
        uint itemId
    ) external nonReentrant {

        MarketItem storage item = _idToMarketItem[itemId];

        require(
            item.itemId == itemId && item.listed,
            "invalid item"
        );

        address buyer = msg.sender;
        uint feeAmount;

        require(
            !_buyerWhitelist[itemId][address(0)]
            || _buyerWhitelist[itemId][buyer],
            "not whitelisted"
        );

        uint price = item.price;
        uint staked = price - item.payoutAmount;

        if (price > 0) {
            IERC20 paymentToken = IERC20(item.paymentToken);
            address[] storage path = _routerPaths[item.paymentToken];
            if (path.length == 0) {
                paymentToken.safeTransferFrom(buyer, address(this), price);
            } else {
                paymentToken.safeTransferFrom(
                    buyer,
                    address(this),
                    price);
                paymentToken.approve(address(router), staked);
                uint[] memory amounts = router.swapExactTokensForTokens(
                    staked,
                    0,
                    path,
                    address(this),
                    block.timestamp);
                staked = amounts[amounts.length - 1];
            }

            // pay seller
            if (item.payoutAmount > 0) {
                if (fee > 0) {
                    feeAmount = (item.payoutAmount * fee) / 10000;
                    uint payout = item.payoutAmount - feeAmount;
                    paymentToken.transfer(item.seller, payout);
                    paymentToken.transfer(feeCollector, feeAmount);
                } else {
                    paymentToken.transfer(item.seller, item.payoutAmount);
                }
            }

            // stake
            if (staked > 0) {
                GURU.approve(address(staking), staked);
                staking.stake(staked, address(this));
                staking.claim(address(this));
                item.stakedAmount = (item.gons > 0 ? SGURU.balanceForGons(item.gons) : 0) + staked;
                item.gons = SGURU.gonsForBalance(item.stakedAmount);
            }
        }

        // transfer NFT to new owner
        IERC721(item.nftContract).safeTransferFrom(address(this), buyer, item.tokenId);

        item.owner = buyer;
        item.listed = false;

        _listedItems.remove(itemId);
        _itemsByOwner.safeAdd(buyer, itemId);

        address creator = INidhiNFT(item.nftContract).creatorOf(item.tokenId);
        _listedItemsByCreator[creator].safeRemove(itemId);

        delete _buyerWhitelist[itemId][address(0)];
        _buyerWhitelist[itemId][address(this)] = true;

        emit MarketItemSold(
            itemId,
            item.nftContract,
            item.tokenId,
            buyer,
            item.price,
            item.stakedAmount,
            feeAmount
        );
    }

    /**
     * @dev Transfers the redeemable value to the current owner.
     */
    function redeem(uint itemId, uint amount) external {
        MarketItem storage item = _idToMarketItem[itemId];
        address owner = IERC721(item.nftContract).ownerOf(item.tokenId);
        require(msg.sender == owner, "caller is not the owner");
        (uint iv, uint rv) = _itemCoreValues(itemId);
        require(amount <= rv, "amount exceeds balance");
        SafeERC20.safeTransfer(SGURU, owner, amount);
        uint remaining = rv - amount;
        item.gons = SGURU.gonsForBalance(iv + remaining);
        item.stakedAmount = iv - remaining;
        emit PassiveIncomeRedeemed(
            itemId,
            owner,
            rv,
            iv
        );
    }

    /**
     * @dev Called by any Nidhi NFT after it was burned.
     * This will initiate the transfer of all SGURU tokens held by this
     * token and delete all index entries associated with this token.
     * Since this function's visibility is external, it will verify that
     * the token was in fact burned.
     */
    function afterBurnToken(
        address creator,
        address nftContract,
        uint tokenId
    ) external {
        uint itemId = _tokenIdToItemId[nftContract][tokenId];
        if (itemId != 0) {
            require(_isBurned(nftContract, tokenId), "token is not burned");
            _itemsByCreator[creator].safeRemove(itemId);
            MarketItem storage item = _idToMarketItem[itemId];
            uint balance = SGURU.balanceForGons(item.gons);
            if (balance > 0) {
                SafeERC20.safeTransfer(SGURU, item.owner, balance);
            }
            if (address(_itemsByOwner[item.owner]) != address(0)) {
                _itemsByOwner[item.owner].remove(itemId);
            }
            delete _idToMarketItem[itemId];
            delete _tokenIdToItemId[nftContract][tokenId];
        }
    }

    /**
     * @dev Removes the provided token from the owner's collection.
     * This function can be called by the owner or the contract of
     * the NFT that should be removed. The latter should only remove
     * the token, if there was an external token ownership transfer.
     */
    function removeTokenFromOwnerCollection(
        address nftAddress,
        uint tokenId
    ) external {
        uint itemId = _tokenIdToItemId[nftAddress][tokenId];
        if (itemId != 0) {
            address owner = _idToMarketItem[itemId].owner;
            require(
                msg.sender == owner || msg.sender == nftAddress,
                "owner has not changed"
            );
            _itemsByOwner[owner].safeRemove(itemId);
        }
    }

    /**
     * @dev Returns the market item id for the provided NFT.
     * If the token is not on the marketplace, this function will return 0.
     */
    function getMarketItemId(address nftAddress, uint tokenId)
        external view returns (uint)
    {
        return _tokenIdToItemId[nftAddress][tokenId];
    }

    /**
     * @dev Returns the market item for the provided id.
     */
    function getMarketItem(uint itemId)
        external view returns (MarketItemDetails memory)
    {
        return _getMarketItemDetails(_idToMarketItem[itemId]);
    }

    /**
      * @dev Returns a page of listed market items.
      */
    function fetchMarketItems(uint page, uint pageSize, bool ascending)
        external view returns (MarketItemDetails[] memory items)
    {
        uint itemCount = _listedItems.size();
        uint skip = page * pageSize;
        if (skip < itemCount) {
            uint remaining = itemCount - skip;
            if (remaining > 0) {
                uint take = remaining >= pageSize ? pageSize : remaining;
                items = new MarketItemDetails[](take);
                NidhiCollection.Item memory current = _listedItems.first(ascending);
                for (uint i = 0; i < skip; i++) {
                    current = _listedItems.getNext(current, ascending);
                }
                for (uint i = 0; i < take; i++) {
                    items[i] = _getMarketItemDetails(_idToMarketItem[current.itemId]);
                    current = _listedItems.getNext(current, ascending);
                }
            }
        }
    }

    /**
      * @dev Returns a page of items by creator.
      */
    function fetchItemsByCreator(
        address creator,
        uint page,
        uint pageSize,
        bool ascending
    )
        external view returns (MarketItemDetails[] memory items)
    {
        NidhiCollection createdItems = _itemsByCreator[creator];
        if (creator != address(0) && address(createdItems) != address(0)) {
            uint itemCount = createdItems.size();
            uint skip = page * pageSize;
            if (skip < itemCount) {
                uint remaining = itemCount - skip;
                if (remaining > 0) {
                    uint take = remaining >= pageSize ? pageSize : remaining;
                    items = new MarketItemDetails[](take);
                    NidhiCollection.Item memory current = createdItems.first(ascending);
                    for (uint i = 0; i < skip; i++) {
                        current = createdItems.getNext(current, ascending);
                    }
                    for (uint i = 0; i < take; i++) {
                        items[i] = _getMarketItemDetails(_idToMarketItem[current.itemId]);
                        current = createdItems.getNext(current, ascending);
                    }
                }
            }
        }
    }

    /**
      * @dev Returns a page of listed market items.
      */
    function fetchItemsByOwner(
        address owner,
        uint page,
        uint pageSize,
        bool ascending
    )
        public view returns (MarketItemDetails[] memory items)
    {
        NidhiCollection collection = _itemsByOwner[owner];
        if (address(collection) != address(0)) {
            uint itemCount = collection.size();
            uint skip = page * pageSize;
            uint skipped;
            NidhiCollection.Item memory current = collection.first(ascending);
            for (uint i = 0; i < itemCount && skipped < skip; i++) {
                MarketItem storage item = _idToMarketItem[current.itemId];
                if (IERC721(item.nftContract).ownerOf(item.tokenId) == owner) {
                    skipped++;
                }
                current = collection.getNext(current, ascending);
            }
            uint remaining = itemCount - skipped;
            if (remaining > 0) {
                NidhiCollection.Item memory first = current;
                MarketItem storage item = _idToMarketItem[current.itemId];
                uint resultSize;
                for (uint i = 0; i < remaining && resultSize < pageSize; i++) {
                    item = _idToMarketItem[current.itemId];
                    if (IERC721(item.nftContract).ownerOf(item.tokenId) == owner) {
                        resultSize++;
                    }
                    current = collection.getNext(current, ascending);
                }
                if (resultSize > 0) {
                    items = new MarketItemDetails[](resultSize);
                    current = first;
                    uint j = 0;
                    for (uint i = 0; i < resultSize; i++) {
                        item = _idToMarketItem[current.itemId];
                        if (IERC721(item.nftContract).ownerOf(item.tokenId) == owner) {
                            items[j++] = _getMarketItemDetails(item);
                        }
                        current = collection.getNext(current, ascending);
                    }
                }
            }
        }
    }

    /**
      * @dev Returns a list of items.
      */
    function fetchItems(uint[] calldata itemIds)
        public view returns (MarketItemDetails[] memory items)
    {
        uint len = itemIds.length;
        if (len > 0) {
            items = new MarketItemDetails[](len);
            for (uint i = 0; i < len; i++) {
                items[i] = _getMarketItemDetails(_idToMarketItem[itemIds[i]]);
            }
        }
    }

    /**
     * @dev Returns the intrinsic value of the given market item.
     */
    function intrinsicValue(uint itemId) external view returns (uint) {
        (uint iv, ) = _itemCoreValues(itemId);
        return iv;
    }

    /**
     * @dev Returns the redeemable value of the given market item.
     */
    function redeemable(uint itemId) external view returns (uint) {
        (, uint rv) = _itemCoreValues(itemId);
        return rv;
    }

    /**
     * @dev Returns the total value for all items of the given owner.
     */
    function totalValueByOwner(
        address owner
    )
        external view returns (uint total, uint redeemable_)
    {
        NidhiCollection collection = _itemsByOwner[owner];
        if (address(collection) != address(0)) {
            NidhiCollection.Item memory item = collection.head();
            while (item.itemId != 0) {
                (uint iv, uint rv) = _itemCoreValues(item.itemId);
                total += iv + rv;
                redeemable_ += rv;
                item = collection.get(item.next);
            }
        }
    }

    function _getMarketItemDetails(
        MarketItem storage item
    ) private view returns (MarketItemDetails memory details) {
        details.itemId = item.itemId;
        details.nftContract = item.nftContract;
        details.tokenId = item.tokenId;
        details.paymentToken = item.paymentToken;
        uint price = details.price = item.price;
        if (details.listed = item.listed) {
            details.seller = item.seller;
            details.sellerName = profile.nameOf(item.seller);
            details.payoutPercentage = (item.payoutAmount * 10000) / price;
            (details.totalValue, ) = _itemCoreValues(item.itemId);
        } else {
            details.owner = IERC721(item.nftContract).ownerOf(item.tokenId);
            details.ownerName = profile.nameOf(details.owner);
            (uint iv, uint rv) = _itemCoreValues(item.itemId);
            details.totalValue = iv + rv;
            details.redeemableValue = rv;
        }
    }

    function _isBurned(
        address nftContract,
        uint tokenId
    ) private view returns (bool) {
        try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
            return owner == address(0);
        } catch {
            return true;
        }
    }

    function _itemValue(
        MarketItem storage item
    ) private view returns (uint, uint) {
        uint total = SGURU.balanceForGons(item.gons);
        return (total, item.stakedAmount);
    }

    function _itemCoreValues(uint itemId) private view returns (uint, uint) {
        MarketItem storage item = _idToMarketItem[itemId];
        (uint total, uint staked) = _itemValue(item);
        uint rv = (total - staked) / 2;
        uint iv = total - rv;
        return (iv, rv);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IRouter {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

abstract contract Staking {
    function stake(uint amount, address recipient) external virtual returns (bool);
    function claim(address recipient) public virtual;
    function rebase() public virtual;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract StakingToken is IERC20 {
    function balanceForGons(uint gons) public virtual view returns (uint);
    function gonsForBalance(uint amount) public virtual view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface INidhiNFT {
    function creatorOf(uint tokenId) external view returns (address);
    function approvePublicTrading(uint tokenId, bool approve) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

contract NidhiCollection {

    struct Item {
        uint prev;
        uint next;
        uint itemId;
    }

    uint public size;
    uint private _head;
    uint private _tail;

    address private immutable _owner;

    mapping (uint => Item) private _items;

    constructor() {
        _owner = msg.sender;
    }

    function append(uint itemId) public onlyOwner {
        Item memory item;
        item.itemId = itemId;
        if (size++ == 0) {
            _head = _tail = itemId;
        } else {
            item.prev = _tail;
            _items[_tail].next = itemId;
            _tail = itemId;
        }
        _items[itemId] = item;
    }

    function remove(uint itemId) public onlyOwner {
        uint prev = _items[itemId].prev;
        uint next = _items[itemId].next;
        if (--size == 0) {
            _head = _tail = 0;
        } else {
            if (_head == itemId) {
                _head = _items[itemId].next;
            }
            if (_tail == itemId) {
                _tail = _items[itemId].prev;
            }
            _items[prev].next = next;
            _items[next].prev = prev;
        }
        delete _items[itemId];
    }

    function get(uint id) public view returns (Item memory) {
        return _items[id];
    }

    function getNext(Item memory current, bool ascending)
        public
        view
        returns (Item memory)
    {
        return get(ascending ? current.next : current.prev);
    }

    function head() public view returns (Item memory) {
        return _items[_head];
    }

    function tail() public view returns (Item memory) {
        return _items[_tail];
    }

    function first(bool ascending) public view returns (Item memory) {
        return ascending ? head() : tail();
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./NidhiCollection.sol";

library SafeNidhiCollection {

    function safeAdd(
        mapping (address => NidhiCollection) storage collections,
        address who,
        uint itemId
    ) public {
        NidhiCollection collection = collections[who];
        if (address(collection) == address(0)) {
            collections[who] = collection = new NidhiCollection();
        }
        collection.append(itemId);
    }

    function safeRemove(NidhiCollection collection, uint itemId) public {
        if (address(collection) != address(0)) {
            collection.remove(itemId);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

contract NidhiProfile {

    struct Profile {
        string name;
        string imageURL;
        string deeplink;
        string description;
        string url;
        string discord;
        string twitter;
        string instagram;
        string medium;
        string telegram;
    }

    mapping (address => Profile) public userProfiles;
    mapping (string => address) public deeplinkToAddress;

    function update(Profile memory profile)
        external validDeeplink(profile.deeplink)
    {
        address owner = msg.sender;
        string storage currentDeeplink = userProfiles[owner].deeplink;
        if (bytes(currentDeeplink).length != 0) {
            delete deeplinkToAddress[currentDeeplink];
            deeplinkToAddress[profile.deeplink] = owner;
        } else if (bytes(profile.deeplink).length != 0) {
            deeplinkToAddress[profile.deeplink] = owner;
        }
        userProfiles[owner] = profile;
    }

    function remove() external {
        delete deeplinkToAddress[userProfiles[msg.sender].deeplink];
        delete userProfiles[msg.sender];
    }

    function nameOf(address owner) external view returns (string memory) {
        return userProfiles[owner].name;
    }

    modifier validDeeplink(string memory deeplink) {
        if (bytes(deeplink).length != 0) {
            address currentAddress = deeplinkToAddress[deeplink];
            require(
                currentAddress == address(0) || currentAddress == msg.sender,
                "deeplink already in use"
            );
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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