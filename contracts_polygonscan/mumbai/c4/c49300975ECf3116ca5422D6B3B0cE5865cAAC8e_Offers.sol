// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "../interfaces/IPricingTable.sol";
import "../interfaces/IOffer.sol";
import "../utils/Ownable.sol";
import "../utils/Pausable.sol";

contract Offers is Ownable, Pausable {
    IPricingTable private _pricingTable;
    mapping(uint256 => OfferItem) private offers;
    mapping(uint256 => OfferItemAdvanceAllocated)
        private offersAdvancesAllocated;
    mapping(uint256 => OfferItemPaymentReceived) private offersPaymentsReceived;
    mapping(uint256 => OfferItemRefunded) private offersFundsRefunded;
    uint256 private offersCount;
    address private _treasuryAddress;

    // getter for one offer
    function getOneOffer(uint256 _id) external view returns (OfferItem memory) {
        return offers[_id];
    }

    // getter for offersCount
    function getOffersCount() external view returns (uint256) {
        return offersCount;
    }

    // getter for pricing table inctance
    function getPricingTable() public view returns (IPricingTable) {
        return _pricingTable;
    }

    function setNewTreasuryAddress(address _newAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_newAddress != address(0), "Address cannot be zero");
        emit TreasuryAddressSet(address(_treasuryAddress), _newAddress);
        _treasuryAddress = _newAddress;
        return true;
    }

    // setter for pricing table contract address
    function setPricingTable(address _newPricingTableAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _newPricingTableAddress != address(0),
            "Address cannot be zero"
        );
        emit PricingTableSet(address(_pricingTable), _newPricingTableAddress);
        _pricingTable = IPricingTable(_newPricingTableAddress);
        return true;
    }

    function isInMinMaxRange(
        uint256 _check,
        uint256 _min,
        uint256 _max
    ) private pure returns (bool) {
        return _check <= _max && _check >= _min;
    }

    // check that offer's arguments are fit selected pricing table item
    function offerFitsPricingTableItem(
        OfferItem memory offer,
        PricingTableItem memory pricing
    ) internal pure returns (bool) {
        return
            isInMinMaxRange(
                offer.amount,
                pricing.minAmount,
                pricing.maxAmount
            ) &&
            isInMinMaxRange(
                offer.tenure,
                pricing.minTenure,
                pricing.maxTenure
            ) &&
            offer.grade == pricing.grade &&
            pricing.actual &&
            isInMinMaxRange(
                offer.factoringFee,
                pricing.minFactoringFee,
                pricing.maxFactoringFee
            ) &&
            isInMinMaxRange(
                offer.discount,
                pricing.minDiscountRange,
                pricing.maxDiscountRange
            ) &&
            offer.advancePercentage + offer.reservePercentage == 100000;
    }

    // check that fund offer's state fits selected pricing table item
    function offerFundAllocateFitsPricingTableItem(
        OfferItemAdvanceAllocated memory offer,
        PricingTableItem memory pricing
    ) internal pure returns (bool) {
        return
            isInMinMaxRange(
                offer.actualAmount,
                pricing.minAmount,
                pricing.maxAmount
            ) &&
            offer.clientCreateDate > 0 &&
            offer.dueDate > offer.clientCreateDate;
        // TODO: what's more to check?
    }

    // check for offer state doesn't goes down step-by-step
    function updateOfferStatus(uint256 _offerId, uint8 _newStatus) internal {
        require(
            _newStatus == offers[_offerId].status + 1,
            "Wrong status state"
        );
        offers[_offerId].status = _newStatus;
        emit OfferStatusUpdated(_offerId, _newStatus);
    }

    // create new offer
    function newOffer(OfferItem memory _offer)
        public
        whenNotPaused
        onlyOwner
        returns (uint256)
    {
        require(
            _offer.amount > 0,
            "Wrong offer arguments"
        );
        require(
            offerFitsPricingTableItem(
                _offer,
                getPricingTable().getPricingTableItem(_offer.pricingId)
            ),
            "Not fits to pricing table"
        );
        _offer.status = 2;
        offersCount = offersCount + 1;
        offers[offersCount] = _offer;
        emit NewOffer(offersCount);
        return offersCount;
    }

    // new state for offer - fund allocation. after this step Treasury can use offer to send advance
    function offerFundAllocate(
        uint256 _id,
        OfferItemAdvanceAllocated memory _offer
    ) public whenNotPaused onlyOwner {
        offersAdvancesAllocated[_id] = _offer;
        offersAdvancesAllocated[_id].disbursingAdvanceDate = block.timestamp;

        require(
            offerFundAllocateFitsPricingTableItem(
                _offer,
                getPricingTable().getPricingTableItem(offers[_id].pricingId)
            ),
            "Not fits to pricing table"
        );

        emit OfferFundAllocated(_id, _offer);
        updateOfferStatus(_id, 3);
        // We are ready to send assets from treasury
        // now treasury can use offer
        // update offer's status
    }

    // new state for offer - back payment received.
    function offerPaymentReceived(
        uint256 _id,
        OfferItemPaymentReceived memory _offer
    ) public whenNotPaused onlyOwner {
        // TODO: may offer be paid twice or more? - only one pay for now
        offersPaymentsReceived[_id] = _offer;
        emit OfferPaymentReceived(_id, _offer);
        // update offer's status
        updateOfferStatus(_id, 5);
    }

    // new state for offer - we ready to send trade tokens to user
    function offerReserveFundAllocated(
        uint256 _id,
        OfferItemRefunded memory _offer
    ) public whenNotPaused onlyOwner {
        offersFundsRefunded[_id] = _offer;
        emit OfferReserveFundAllocated(_id, _offer);
        updateOfferStatus(_id, 6);
    }

    // getter for external calls from treasury
    function getAmountsForTransfers(uint256 _id)
        external
        view
        returns (
            address,
            uint256,
            address
        )
    {
        return (
            offers[_id].tokenAddress,
            offersAdvancesAllocated[_id].advancedAmount * 10**15,
            offers[_id].offerAddress
        );
    }

    function getAmountsForFinish(uint256 _id)
        external view
        returns (
            uint256,
            address
        )
    {
        return (
            offersFundsRefunded[_id].toPayTradeTokens * 10**15,
            offers[_id].offerAddress
        );
    }

    // Treasury can move offer to new state
    function changeStatusFromTreasury(uint256 _id, uint8 status)
        external
        returns (bool)
    {
        require(msg.sender == _treasuryAddress, "Wrong treasury address");
        updateOfferStatus(_id, status);
        return true;
    }

    //events
    event PricingTableSet(address oldAddress, address newAddress);
    event TreasuryAddressSet(address oldAddress, address newAddress);
    event OfferStatusUpdated(uint256 _id, uint256 newStatus);
    event NewOffer(uint256 _id);

    event OfferFundAllocated(uint256 _id, OfferItemAdvanceAllocated _offer);
    event OfferPaymentReceived(uint256 _id, OfferItemPaymentReceived _offer);
    event OfferReserveFundAllocated(uint256 _id, OfferItemRefunded _offer);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

struct OfferItem {
    uint256 amount;
    uint8 status;
    uint256 duration;
    uint8 grade;
    uint256 tenure;
    uint256 pricingId;
    address offerAddress;
    uint256 factoringFee;
    uint256 discount;
    uint256 advancePercentage;
    uint256 reservePercentage;
    uint256 gracePeriod;
    address tokenAddress;
}

struct OfferItemAdvanceAllocated {
    string polytradeInvoiceNo;
    uint256 clientCreateDate;
    uint256 actualAmount;
    uint256 disbursingAdvanceDate;
    uint256 advancedAmount;
    uint256 reserveHeldAmount;
    uint256 dueDate;
    uint256 amountDue;
    uint256 totalFee;
}

struct OfferItemPaymentReceived {
    uint256 paymentDate;
    string paymentRefNo;
    uint256 receivedAmount;
    string appliedToInvoiceRefNo;
    int256 unAppliedOrShortAmount;
}
struct OfferItemRefunded {
    string invoiceRefNo;
    uint256 invoiceAmount;
    uint256 amountReceived;
    uint256 paymentReceivedDate;
    uint256 numberOfLateDays;
    uint256 fee;
    uint256 lateFee;
    uint256 netAmount;
    uint256 dateClosed;
    uint256 toPayTradeTokens;
}

interface IOffer {
    function getAmountsForTransfers(uint256 _id)
        external
        returns (
            address _tokenAddress,
            uint256 _amount,
            address _address
        );

    function getAmountsForFinish(uint256 _id)
        external
        returns (
            uint256 _amount,
            address _address
        );

    function changeStatusFromTreasury(uint256 _id, uint8 status)
        external
        returns (bool);
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import './Ownable.sol';

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

