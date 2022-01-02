/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// SPDX-License-Identifier: MIT
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


// File contracts/PricingTable/PricingTable.sol

pragma solidity ^0.8.10;


/// @title Princing Table
/// @author Polytrade
contract PricingTable is IPricingTable, Ownable {
    mapping(bytes2 => PricingItem) private _pricingItems;
    mapping(bytes2 => bool) private _pricingStatus;

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
    ) external onlyOwner {
        require(!_pricingStatus[pricingId], "Already exists, please update");
        PricingItem memory _pricingItem;

        _pricingItem.minTenure = minTenure;
        _pricingItem.maxTenure = maxTenure;
        _pricingItem.minAmount = minAmount;
        _pricingItem.maxAmount = maxAmount;
        _pricingItem.maxAdvancedRatio = maxAdvancedRatio;
        _pricingItem.minDiscountFee = minDiscountRange;
        _pricingItem.minFactoringFee = minFactoringFee;
        _pricingItems[pricingId] = _pricingItem;
        _pricingStatus[pricingId] = true;
        emit NewPricingItem(_pricingItems[pricingId]);
    }

    /**
     * @notice Update an existing Pricing Item
     * @dev Only Owner is authorized to update a Pricing Item
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
    ) external onlyOwner {
        require(_pricingStatus[pricingId], "Invalid Pricing Item");

        _pricingItems[pricingId].minTenure = minTenure;
        _pricingItems[pricingId].maxTenure = maxTenure;
        _pricingItems[pricingId].minAmount = minAmount;
        _pricingItems[pricingId].maxAmount = maxAmount;
        _pricingItems[pricingId].maxAdvancedRatio = maxAdvancedRatio;
        _pricingItems[pricingId].minDiscountFee = minDiscountRange;
        _pricingItems[pricingId].minFactoringFee = minFactoringFee;
        _pricingStatus[pricingId] = status;
        emit UpdatedPricingItem(_pricingItems[pricingId]);
    }

    /**
     * @notice Remove a Pricing Item from the Pricing Table
     * @dev Only Owner is authorized to add a Pricing Item
     * @param id, id of the pricing Item
     */
    function removePricingItem(bytes2 id) external onlyOwner {
        delete _pricingItems[id];
        _pricingStatus[id] = false;
        emit RemovedPricingItem(id);
    }

    /**
     * @notice Returns the pricing Item
     * @param id, id of the pricing Item
     * @return returns the PricingItem (struct)
     */
    function getPricingItem(bytes2 id)
        external
        view
        override
        returns (PricingItem memory)
    {
        return _pricingItems[id];
    }

    /**
     * @notice Returns if the pricing Item is valid
     * @param id, id of the pricing Item
     * @return returns boolean if pricing is valid or not
     */
    function isPricingItemValid(bytes2 id)
        external
        view
        override
        returns (bool)
    {
        return _pricingStatus[id];
    }
}