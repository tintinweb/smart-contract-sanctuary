/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


struct PricingTableItem {
    uint256 minAmount;
    uint256 maxAmount;
    uint256 grade;
    uint256 minTenure;
    uint256 maxTenure;
    uint256 minAdvancedRatio;
    uint256 maxAdvancedRatio;
    uint256 minDiscountRange;
    uint256 maxDiscountRange;
    uint256 minFactoringFee;
    uint256 maxFactoringFee;
    bool actual;
}

interface IPricingTable {
    function getPricingTableItem(uint256 _id)
        external
        view
        returns (PricingTableItem memory);
}


contract PricingTable is Ownable, Pausable {
    mapping(uint256 => PricingTableItem) private pricingTable;
    uint256 private pricingCount;

    // getter for one pricing table item
    function getPricingTableItem(uint256 _id)
        external
        view
        whenNotPaused
        returns (PricingTableItem memory)
    {
        return pricingTable[_id];
    }

    // add new pricing table item to storage
    function addPricingTableItem(PricingTableItem memory _newPricingTableItem)
        public
        whenNotPaused
        onlyOwner
        returns (uint256)
    {
        // 100.000 == 100%, precision is 3
        require(
            _newPricingTableItem.minAdvancedRatio > 0 &&
                _newPricingTableItem.minAdvancedRatio <= 100000 &&
                _newPricingTableItem.maxAdvancedRatio > 0 &&
                _newPricingTableItem.maxAdvancedRatio <= 100000 &&
                _newPricingTableItem.minDiscountRange > 0 &&
                _newPricingTableItem.minDiscountRange <= 100000 &&
                _newPricingTableItem.maxDiscountRange > 0 &&
                _newPricingTableItem.maxDiscountRange <= 100000 &&
                _newPricingTableItem.minFactoringFee <= 100000 &&
                _newPricingTableItem.minFactoringFee > 0 &&
                _newPricingTableItem.maxFactoringFee <= 100000 &&
                _newPricingTableItem.maxFactoringFee > 0 &&
                _newPricingTableItem.actual // check that added pricing is actual
        );
        pricingTable[pricingCount++] = _newPricingTableItem;
        emit NewPricing(pricingCount);
        return pricingCount;
    }

    // deprecate pricing table item
    function deprecatePricingTableItem(uint256 _id)
        public
        whenNotPaused
        onlyOwner
        returns (bool)
    {
        pricingTable[_id].actual = false;
        emit PricingDeprecated(_id);
        return true;
    }

    event PricingDeprecated(uint256 id);
    event NewPricing(uint256 id);
}