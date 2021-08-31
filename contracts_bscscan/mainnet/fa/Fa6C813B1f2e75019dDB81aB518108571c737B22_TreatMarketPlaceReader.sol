/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface TreatNftMinter {
    function balanceOf(address ownerAddress, uint256 nftId) external view returns (uint256);
}

interface TreatMarketPlace {
    struct Order {
        address payable seller;
        address payable creator;
        uint256 nftId;
        uint256 quantity;
        uint256 price;
        uint256 listDate;
        uint256 expiresDate;
        uint256 closedDate;
    }
    function orderBook(uint256 nftId, address sellerAddress) external view returns (Order memory);
    function getOpenOrdersForNft(uint256 nftId) external view returns (address[] memory);
    function getOpenOrdersForSeller(address seller) external view returns (uint256[] memory);
}

contract TreatMarketPlaceReader is Ownable {
    TreatMarketPlace public treatMarketPlace;
    TreatNftMinter public treatNftMinter;

    constructor(TreatMarketPlace _TreatMarketplaceAddress, TreatNftMinter _TreatNftMinterAddress) public {
        treatMarketPlace = TreatMarketPlace(_TreatMarketplaceAddress);
        treatNftMinter = TreatNftMinter(_TreatNftMinterAddress);
    }
    
    function readNftRangeBalance(address ownerAddress, uint256 startNftId, uint256 endNftId) public view returns (uint256[] memory nftIds, uint256[] memory nftBalances) {
        uint256 returnArrayLen = endNftId - startNftId + 1;
        uint256[] memory nftIdBalances = new uint256[](returnArrayLen);
        uint256[] memory nftIdsChecked = new uint256[](returnArrayLen);
        uint256 nftIndex = 0;
        for(uint256 i = startNftId; i <= endNftId; i++) {
            nftIdsChecked[nftIndex] = i;
            nftIdBalances[nftIndex] = treatNftMinter.balanceOf(ownerAddress, i);
            nftIndex++;
        }
        return (nftIdsChecked, nftIdBalances);
    }
    
    function readAllOrdersForSeller(address sellerAddress) public view returns (address[] memory creators, uint256[] memory nftIds, uint256[] memory quantitys, uint256[] memory prices) {
        uint256[] memory nftOrdersForSeller = treatMarketPlace.getOpenOrdersForSeller(sellerAddress);
        address[] memory ordersCreators = new address[](nftOrdersForSeller.length);
        uint256[] memory ordersNftIds = new uint256[](nftOrdersForSeller.length);
        uint256[] memory ordersQuantitys = new uint256[](nftOrdersForSeller.length);
        uint256[] memory ordersPrices = new uint256[](nftOrdersForSeller.length);
        for(uint j = 0; j < nftOrdersForSeller.length; j++) {
            ordersCreators[j] = treatMarketPlace.orderBook(nftOrdersForSeller[j], sellerAddress).creator;
            ordersNftIds[j] = treatMarketPlace.orderBook(nftOrdersForSeller[j], sellerAddress).nftId;
            ordersQuantitys[j] = treatMarketPlace.orderBook(nftOrdersForSeller[j], sellerAddress).quantity;
            ordersPrices[j] = treatMarketPlace.orderBook(nftOrdersForSeller[j], sellerAddress).price;
        }
        return (ordersCreators, ordersNftIds, ordersQuantitys, ordersPrices);
    }
    
    function readAllOrdersForNft(uint256 nftId) public view returns (address[] memory creators, address[] memory sellers, uint256[] memory quantitys, uint256[] memory prices) {
        address[] memory nftOrdersBySeller = treatMarketPlace.getOpenOrdersForNft(nftId);
        address[] memory ordersSellers = new address[](nftOrdersBySeller.length);
        address[] memory ordersCreators = new address[](nftOrdersBySeller.length);
        uint256[] memory ordersQuantitys = new uint256[](nftOrdersBySeller.length);
        uint256[] memory ordersPrices = new uint256[](nftOrdersBySeller.length);
        for(uint j = 0; j < nftOrdersBySeller.length; j++) {
            ordersSellers[j] = treatMarketPlace.orderBook(nftId, nftOrdersBySeller[j]).seller;
            ordersCreators[j] = treatMarketPlace.orderBook(nftId, nftOrdersBySeller[j]).creator;
            ordersQuantitys[j] = treatMarketPlace.orderBook(nftId, nftOrdersBySeller[j]).quantity;
            ordersPrices[j] = treatMarketPlace.orderBook(nftId, nftOrdersBySeller[j]).price;
        }
        return (ordersCreators, ordersSellers, ordersQuantitys, ordersPrices);
    }
    
    function readOrderPricesForNftRange(uint256 nftId, uint256 endNftId) public view returns (address[] memory sellers, uint256[] memory nftIds, uint256[] memory prices, uint256[] memory listDates) {
        uint256 thearraylen = 0;
        for(uint256 x = nftId; x <= endNftId; x++) {
            address[] memory nftOrdersBySellerCheck = treatMarketPlace.getOpenOrdersForNft(x);
            thearraylen = thearraylen + nftOrdersBySellerCheck.length;
        }
        address[] memory ordersSellers = new address[](thearraylen);
        uint256[] memory ordersNftIds = new uint256[](thearraylen);
        uint256[] memory ordersPrices = new uint256[](thearraylen);
        uint256[] memory ordersTimesListed = new uint256[](thearraylen);
        uint256 theIndex = 0;
        for(uint256 i = nftId; i <= endNftId; i++) {
            address[] memory nftOrdersBySeller = treatMarketPlace.getOpenOrdersForNft(i);
            for(uint256 j = 0; j < nftOrdersBySeller.length; j++) {
                ordersSellers[theIndex] = treatMarketPlace.orderBook(i, nftOrdersBySeller[j]).seller;
                ordersNftIds[theIndex] = treatMarketPlace.orderBook(i, nftOrdersBySeller[j]).nftId;
                ordersPrices[theIndex] = treatMarketPlace.orderBook(i, nftOrdersBySeller[j]).price;
                ordersTimesListed[theIndex] = treatMarketPlace.orderBook(i, nftOrdersBySeller[j]).listDate;
                theIndex++;
            }
        }
        return (ordersSellers, ordersNftIds, ordersPrices, ordersTimesListed);
    }

}