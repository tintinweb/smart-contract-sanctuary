// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";

import "./SellOrderListErrors.sol";
import "./SellOrderLogic.sol";
import "./MiniIAddressesProvider.sol";
import "./MiniINFTList.sol";
import "./ArrayLib.sol";

/**
 * @title SellOrderList contract
 * @dev The place user create sell order nft
 * - Owned by the MochiLab
 * @author MochiLab
 **/
contract SellOrderList is Initializable {
    using SellOrderLogic for SellOrderType.SellOrder;
    using ArrayLib for uint256[];

    MiniIAddressesProvider public addressesProvider;
    MiniINFTList public nftList;

    // All sell orders
    SellOrderType.SellOrder[] internal _sellOrders;

    // The sell orders nft is of type ERC721 available
    uint256[] internal _availableSellOrdersERC721;

    // The sell orders nft is of type ERC1155 available
    uint256[] internal _availableSellOrdersERC1155;

    // All sell order of a user
    mapping(address => uint256[]) internal _sellerToOrders;

    // The available sell orders nft is of type ERC721  of a user
    mapping(address => uint256[]) internal _sellerToAvailableOrdersERC721;

    // The available sell orders nft is of type ERC1155 of a user
    mapping(address => uint256[]) internal _sellerToAvailableOrdersERC1155;

    // All sell orders of a nft address
    mapping(address => uint256[]) internal _nftToOrders;

    // The available sell orders of a nft address
    mapping(address => uint256[]) internal _nftToAvailableOrders;

    // All sell orders was purchased by user
    mapping(address => uint256[]) internal _buyerToSellOrders;

    // Latest sell order of a nft is of type ERC721
    // nftAddress => tokenId => latest sellId
    mapping(address => mapping(uint256 => uint256)) internal _inforToSellIdERC721;

    // Latest sell order of a nft is of type ERC1155
    // seller => nftAddress => tokenId => latest sellId
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal _inforToSellIdERC1155;

    event Initialized(address indexed provider);
    event SellOrderAdded(
        address indexed seller,
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address token
    );
    event SellOrderDeactive(
        uint256 sellId,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address token
    );
    event SellOrderCompleted(
        uint256 sellId,
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 amount,
        address token
    );
    event PriceChanged(uint256 sellId, uint256 newPrice);

    modifier onlyMarket() {
        require(addressesProvider.getMarket() == msg.sender, SellOrderListErrors.CALLER_NOT_MARKET);
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the SellOrderList contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the AddressesProvider
     **/
    function initialize(address provider) external initializer {
        addressesProvider = MiniIAddressesProvider(provider);
        nftList = MiniINFTList(addressesProvider.getNFTList());
        emit Initialized(provider);
    }

    /**
     * @dev Add sell order to the list
     * - Can only be called by Market
     * @param nftAddress The address of nft
     * @param tokenId The tokenId of nft
     * @param amount The amount of nft
     * @param seller The address of seller
     * @param price The unit price at which the seller wants to sell
     * @param token Token that the seller wants to be paid
     **/
    function addSellOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 price,
        address token
    ) external onlyMarket {
        uint256 sellId = _sellOrders.length;
        SellOrderType.SellOrder memory sellOrder = SellOrderLogic.newSellOrder(
            sellId,
            nftAddress,
            tokenId,
            amount,
            seller,
            price,
            token
        );

        _addSellOrderToList(sellOrder);

        emit SellOrderAdded(seller, sellId, nftAddress, tokenId, price, token);
    }

    /**
     * @dev Deactive a sell order
     * - Can only be called by Market
     * @param sellId Sell order id
     */
    function deactiveSellOrder(uint256 sellId) external onlyMarket {
        _sellOrders[sellId].deactive();
        _removeSellOrderFromList(sellId);
        emit SellOrderDeactive(
            sellId,
            _sellOrders[sellId].seller,
            _sellOrders[sellId].nftAddress,
            _sellOrders[sellId].tokenId,
            _sellOrders[sellId].price,
            _sellOrders[sellId].token
        );
    }

    /**
     * @dev Complete a sell order
     * - Can only be called by Market
     * @param sellId Sell order id
     * @param buyer Buyer address
     * @param amount The amount of nft purchased by the buyer
     */
    function completeSellOrder(
        uint256 sellId,
        address buyer,
        uint256 amount
    ) external onlyMarket {
        _sellOrders[sellId].complete(buyer, amount);
        _buyerToSellOrders[buyer].push(sellId);
        if (_sellOrders[sellId].soldAmount == _sellOrders[sellId].amount) {
            _sellOrders[sellId].isActive = false;
            _removeSellOrderFromList(sellId);
        }
        emit SellOrderCompleted(
            sellId,
            _sellOrders[sellId].seller,
            buyer,
            _sellOrders[sellId].nftAddress,
            _sellOrders[sellId].tokenId,
            _sellOrders[sellId].price,
            amount,
            _sellOrders[sellId].token
        );
    }

    /**
     * @dev Update price of a sell order
     * - Can only be called by Market
     * @param sellId Sell order id
     * @param newPrice The new price of sell order
     */
    function updatePrice(uint256 sellId, uint256 newPrice) external onlyMarket {
        _sellOrders[sellId].updatePrice(newPrice);
        emit PriceChanged(sellId, newPrice);
    }

    /**
     * @dev Get information of a sell order by id
     * @param sellId Sell order id
     * @return Information of sell order
     */
    function getSellOrderById(uint256 sellId)
        external
        view
        returns (SellOrderType.SellOrder memory)
    {
        return _sellOrders[sellId];
    }

    /**
     * @dev Get information of the sell orders by id list
     * @param idList The list of id of sell orders
     */
    function getSellOrdersByIdList(uint256[] memory idList)
        external
        view
        returns (SellOrderType.SellOrder[] memory result)
    {
        result = new SellOrderType.SellOrder[](idList.length);

        for (uint256 i = 0; i < idList.length; i++) {
            result[i] = _sellOrders[idList[i]];
        }
    }

    /**
     * @dev Get the number of sell order
     * @return The number of sell order
     */
    function getSellOrderCount() external view returns (uint256) {
        return _sellOrders.length;
    }

    /**
     * @dev Get list of id of available sell orders
     */
    function getAvailableSellOrdersIdList()
        external
        view
        returns (uint256[] memory resultERC721, uint256[] memory resultERC1155)
    {
        resultERC721 = new uint256[](_availableSellOrdersERC721.length);

        for (uint256 i = 0; i < _availableSellOrdersERC721.length; i++) {
            resultERC721[i] = _availableSellOrdersERC721[i];
        }

        resultERC1155 = new uint256[](_availableSellOrdersERC1155.length);

        for (uint256 i = 0; i < _availableSellOrdersERC1155.length; i++) {
            resultERC1155[i] = _availableSellOrdersERC1155[i];
        }
    }

    /**
     * @dev Get list of id of sell orders of a user
     */
    function getAllSellOrdersIdListByUser(address user)
        external
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](_sellerToOrders[user].length);

        for (uint256 i = 0; i < _sellerToOrders[user].length; i++) {
            result[i] = _sellerToOrders[user][i];
        }
    }

    /**
     * @dev Get list of id of available sell orders of a user
     */
    function getAvailableSellOrdersIdListByUser(address user)
        external
        view
        returns (uint256[] memory resultERC721, uint256[] memory resultERC1155)
    {
        resultERC721 = new uint256[](_sellerToAvailableOrdersERC721[user].length);
        for (uint256 i = 0; i < _sellerToAvailableOrdersERC721[user].length; i++) {
            resultERC721[i] = _sellerToAvailableOrdersERC721[user][i];
        }

        resultERC1155 = new uint256[](_sellerToAvailableOrdersERC1155[user].length);
        for (uint256 i = 0; i < _sellerToAvailableOrdersERC1155[user].length; i++) {
            resultERC1155[i] = _sellerToAvailableOrdersERC1155[user][i];
        }
    }

    /**
     * @dev Get list of id of sell orders of a nft address
     */
    function getAllSellOrdersIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](_nftToOrders[nftAddress].length);

        for (uint256 i = 0; i < _nftToOrders[nftAddress].length; i++) {
            result[i] = _nftToOrders[nftAddress][i];
        }
    }

    /**
     * @dev Get list of id of available sell orders of a nft address
     */
    function getAvailableSellOrdersIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory result)
    {
        result = new uint256[](_nftToAvailableOrders[nftAddress].length);

        for (uint256 i = 0; i < _nftToAvailableOrders[nftAddress].length; i++) {
            result[i] = _nftToAvailableOrders[nftAddress][i];
        }
    }

    /**
     * @dev Get list of id of sell orders was purchased by a user
     * @return List of id of sell orders was purchased by a user
     */
    function getSellOrdersBoughtIdListByUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _buyerToSellOrders[user];
    }

    /**
     * @dev Get latest sellId of a nft  is of type ERC721
     * @param nftAddress The address of nft contract
     * @param tokenId The tokenId of nft
     * @return found (true, false) and latest sellId
     */
    function getLatestSellIdERC721(address nftAddress, uint256 tokenId)
        external
        view
        returns (bool found, uint256 id)
    {
        uint256 sellId = _inforToSellIdERC721[nftAddress][tokenId];

        if (
            _sellOrders[sellId].nftAddress == nftAddress && _sellOrders[sellId].tokenId == tokenId
        ) {
            found = true;
            id = sellId;
        } else {
            found = false;
            id = sellId;
        }
    }

    /**
     * @dev Get latest sellId of a nft  is of type ERC1155
     * @param nftAddress The address of nft contract
     * @param tokenId The tokenId of nft
     * @return found (true, false) and latest sellId
     */
    function getLatestSellIdERC1155(
        address seller,
        address nftAddress,
        uint256 tokenId
    ) external view returns (bool found, uint256 id) {
        uint256 sellId = _inforToSellIdERC1155[seller][nftAddress][tokenId];

        if (
            _sellOrders[sellId].nftAddress == nftAddress &&
            _sellOrders[sellId].tokenId == tokenId &&
            _sellOrders[sellId].seller == seller
        ) {
            found = true;
            id = sellId;
        } else {
            found = false;
            id = sellId;
        }
    }

    /**
     * @dev Check sell order of a nft ERC721 is duplicate or not
     * @param nftAddress The address of nft contract
     * @param tokenId The tokenId of nft
     * @param seller The address of seller
     */
    function checkDuplicateERC721(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool) {
        for (uint256 i = 0; i < _sellerToAvailableOrdersERC721[seller].length; i++) {
            if (
                _sellOrders[_sellerToAvailableOrdersERC721[seller][i]].nftAddress == nftAddress &&
                _sellOrders[_sellerToAvailableOrdersERC721[seller][i]].tokenId == tokenId
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Check sell order of a nft ERC1155 is duplicate or not
     * @param nftAddress The address of nft contract
     * @param tokenId The tokenId of nft
     * @param seller The address of seller
     */
    function checkDuplicateERC1155(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool) {
        for (uint256 i = 0; i < _sellerToAvailableOrdersERC1155[seller].length; i++) {
            if (
                _sellOrders[_sellerToAvailableOrdersERC1155[seller][i]].nftAddress == nftAddress &&
                _sellOrders[_sellerToAvailableOrdersERC1155[seller][i]].tokenId == tokenId
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Add sell order to
     - _sellOrders,
     - _availableSellOrders,
     - _sellerToOrders,
     - _sellerToAvailableOrdersERC1155,
     - _sellerToAvailableOrdersERC721,
     - _nftToOrders,
     - _nftToAvailableOrders
     * - internal function called inside addSellOrder() function
     * @param sellOrder sell order object
     */
    function _addSellOrderToList(SellOrderType.SellOrder memory sellOrder) internal {
        uint256 sellId = sellOrder.sellId;

        _sellOrders.push(sellOrder);

        _sellerToOrders[sellOrder.seller].push(sellId);

        _nftToOrders[sellOrder.nftAddress].push(sellId);

        _nftToAvailableOrders[sellOrder.nftAddress].push(sellId);

        if (nftList.isERC1155(sellOrder.nftAddress) == true) {
            _availableSellOrdersERC1155.push(sellId);
            _sellerToAvailableOrdersERC1155[sellOrder.seller].push(sellId);
            _inforToSellIdERC1155[sellOrder.seller][sellOrder.nftAddress][sellOrder
                .tokenId] = sellId;
        } else {
            _availableSellOrdersERC721.push(sellId);
            _sellerToAvailableOrdersERC721[sellOrder.seller].push(sellId);
            _inforToSellIdERC721[sellOrder.nftAddress][sellOrder.tokenId] = sellId;
        }
    }

    /**
     * @dev Remove sell order from
     - _availableSellOrders,
     - _sellerToAvailableOrdersERC1155 or _sellerToAvailableOrdersERC721,
     - _nftToAvailableOrders
     * - internal function called inside completeSellOrder() and deactiveSellOrder() function
     * @param sellId Id of sell order
     */
    function _removeSellOrderFromList(uint256 sellId) internal {
        SellOrderType.SellOrder memory sellOrder = _sellOrders[sellId];

        _nftToAvailableOrders[sellOrder.nftAddress].removeAtValue(sellId);

        if (nftList.isERC1155(sellOrder.nftAddress) == true) {
            _availableSellOrdersERC1155.removeAtValue(sellId);
            _sellerToAvailableOrdersERC1155[sellOrder.seller].removeAtValue(sellId);
        } else {
            _availableSellOrdersERC721.removeAtValue(sellId);
            _sellerToAvailableOrdersERC721[sellOrder.seller].removeAtValue(sellId);
        }
    }
}