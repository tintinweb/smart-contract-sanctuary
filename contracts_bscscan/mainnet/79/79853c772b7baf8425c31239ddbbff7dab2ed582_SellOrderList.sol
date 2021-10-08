// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../libraries/helpers/SellOrderListErrors.sol";
import "../libraries/logic/SellOrderLogic.sol";
import "../interfaces/mini-interfaces/MiniIAddressesProvider.sol";
import "../interfaces/mini-interfaces/MiniINFTList.sol";
import "../libraries/helpers/ArrayLib.sol";

/**
 * @title SellOrderList contract
 * @dev The place user create sell order nft
 * - Owned by the PiProtocol
 * @author PiProtocol
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
        SellOrderType.SellOrder memory sellOrder =
            SellOrderLogic.newSellOrder(sellId, nftAddress, tokenId, amount, seller, price, token);

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
            _inforToSellIdERC1155[sellOrder.seller][sellOrder.nftAddress][
                sellOrder.tokenId
            ] = sellId;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library SellOrderListErrors {
    string public constant CALLER_NOT_MARKET = "Caller is not the market";
    string public constant RANGE_IS_INVALID = "Range is invalid"; // 'The range must be valid'
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../types/SellOrderType.sol";

library SellOrderLogic {
    /**
     * @dev Create a sell order object
     * @param sellId Id of sell order
     * @param nftAddress Nft Address
     * @param tokenId TokenId
     * @param amount The amount of nft the seller wants to sell
     * @param seller Seller address
     * @param price Number of tokens that the seller wants to receive
     * @param token Token that the seller wants to be paid for
     **/
    function newSellOrder(
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 price,
        address token
    ) internal view returns (SellOrderType.SellOrder memory) {
        address[] memory emptyBuyers;
        uint256[] memory emptyBuyTimes;
        return
            SellOrderType.SellOrder({
                sellId: sellId,
                nftAddress: nftAddress,
                tokenId: tokenId,
                amount: amount,
                soldAmount: 0,
                seller: seller,
                price: price,
                token: token,
                isActive: true,
                sellTime: block.timestamp,
                buyers: emptyBuyers,
                buyTimes: emptyBuyTimes
            });
    }

    /**
     * @dev Deactive a sell order
     * @param sellOrder Sell order object
     **/
    function deactive(SellOrderType.SellOrder storage sellOrder) internal {
        sellOrder.isActive = false;
    }

    /**
     * @dev Complete a sell order
     * @param sellOrder Sell order object
     * @param buyer Buyer address
     * @param amount The amount that buyer wants to buy
     **/
    function complete(
        SellOrderType.SellOrder storage sellOrder,
        address buyer,
        uint256 amount
    ) internal {
        sellOrder.buyTimes.push(block.timestamp);
        sellOrder.buyers.push(buyer);
        sellOrder.soldAmount = sellOrder.soldAmount + amount;
    }

    /**
     * @dev Update price of a sell order
     * @param sellOrder Sell order object
     * @param newPrice New price of the sell order
     **/
    function updatePrice(SellOrderType.SellOrder storage sellOrder, uint256 newPrice) internal {
        sellOrder.price = newPrice;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface of AddressesProvider contract
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
interface MiniIAddressesProvider {
    function getAddress(bytes32 id) external view returns (address);

    function getNFTList() external view returns (address);

    function getMarket() external view returns (address);

    function getSellOrderList() external view returns (address);

    function getExchangeOrderList() external view returns (address);

    function getVault() external view returns (address);

    function getCreativeStudio() external view returns (address);

    function getAdmin() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../libraries/types/NFTInfoType.sol";

/**
 * @title Interface of NFTList contract
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
interface MiniINFTList {
    function isERC1155(address nftAddress) external view returns (bool);

    function getNFTInfo(address nftAddress) external view returns (NFTInfoType.NFTInfo memory);

    function getNFTCount() external view returns (uint256);

    function getAcceptedNFTs() external view returns (address[] memory);

    function isAcceptedNFT(address nftAddress) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Calculation library for Array
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
library ArrayLib {
    /**
     * @dev Find a value in array
     * @param array The  array
     * @param value Value to find
     * @return (index, found)
     **/
    function find(uint256[] memory array, uint256 value) internal pure returns (uint256, bool) {
        require(array.length > 0, "Array is empty");
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * @dev Remove element at index
     * @param array The array
     * @param index Index to remove
     **/
    function removeAtIndex(uint256[] storage array, uint256 index) internal {
        require(array.length > index, "Invalid index");

        if (array.length > 1) {
            array[index] = array[array.length - 1];
        }

        array.pop();
    }

    /**
     * @dev Remove the first element whose value is equal to value
     * @param array The  array
     * @param value Value to remove
     **/
    function removeAtValue(uint256[] storage array, uint256 value) internal {
        require(array.length > 0, "Array is empty");

        (uint256 index, bool found) = find(array, value);

        if (found == true) {
            removeAtIndex(array, index);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library SellOrderType {
    struct SellOrder {
        //the id of sell order in array
        uint256 sellId;
        // the address of the nft
        address nftAddress;
        // the tokenId
        uint256 tokenId;
        // amount to sell
        uint256 amount;
        // sold amount
        uint256 soldAmount;
        // seller
        address payable seller;
        // unit price
        uint256 price;
        // token
        address token;
        // is active to buy
        bool isActive;
        // time create a sell order
        uint256 sellTime;
        // buyers
        address[] buyers;
        // buy time
        uint256[] buyTimes;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library NFTInfoType {
    struct NFTInfo {
        // the id of the nft in array
        uint256 id;
        // nft address
        address nftAddress;
        // is ERC1155
        bool isERC1155;
        // is registered
        bool isRegistered;
        // is accepted by admin
        bool isAccepted;
        // registrant
        address registrant;
    }
}