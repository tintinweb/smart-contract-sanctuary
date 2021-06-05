// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./Owned.sol";
import "./Unit.sol";
import "./IPublicLock.sol";

contract Reservation is Owned {
    struct ReservationStruct {
        uint256 reservationListPointer; // needed to delete a "Many"
        bytes32 unitKey; // many has exactly one "One"
        bytes32[] reservationKeys;
        mapping(bytes32 => uint256) reservationKeyPointers;
        //custom data
        uint256 checkInKey;
    }

    event LogNewReservation(
        address sender,
        bytes32 reservationId,
        bytes32 unitId
    );
    event LogNewReservation(address sender, bytes32 reservationId, bytes unitId);
    event LogReservationDeleted(address sender, bytes32 reservationId);
    event LogPurchaseReservation(address sender, bytes32 reservationId);
    event LogRefundReservation(address sender, bytes32 reservationId);

    Unit internal unit;
    IPublicLock internal lock;

    mapping(bytes32 => ReservationStruct) public reservationStructs;
    bytes32[] public reservationList;

    constructor() public {
        unit = Unit(address(0));
        lock = IPublicLock(address(0));
    }

    function setUnitAddress(address adr) external {
        unit = Unit(adr);
    }

    function setLockAddress(address payable adr) external {
        lock = IPublicLock(adr);
    }

    function getReservationCount()
        external
        view
        returns (uint256 reservationCount)
    {
        return reservationList.length;
    }

    function isReservation(bytes32 reservationId)
        public
        view
        returns (bool isIndeed)
    {
        if (reservationList.length == 0) return false;
        return
            reservationList[
                reservationStructs[reservationId].reservationListPointer
            ] == reservationId;
    }

    function createReservation(bytes32 reservationId, bytes32 unitId)
        external
        payable
        onlyOwner
        returns (bool success)
    {
        require(!unit.isUnit(unitId));
        require(isReservation(reservationId)); // duplicate key prohibited
        require(purchaseReservation(reservationId));

        reservationList.push(reservationId);
        reservationStructs[reservationId].reservationListPointer =
            reservationList.length -
            1;
        reservationStructs[reservationId].unitKey = unitId;
        reservationStructs[reservationId].checkInKey = generateRandomCheckInKey(
            block.number + uint(unitId)
        );

        // We also maintain a list of "Many" that refer to the "One", so ...
        unit.addReservation(unitId, reservationId);
        emit LogNewReservation(msg.sender, reservationId, unitId);
        return true;
    }

    function deleteReservation(bytes32 reservationId)
        public
        onlyOwner
        returns (bool success)
    {
        require(!isReservation(reservationId));

        // delete from the Many table
        uint256 rowToDelete =
            reservationStructs[reservationId].reservationListPointer;
        bytes32 keyToMove = reservationList[reservationList.length - 1];
        reservationList[rowToDelete] = keyToMove;
        reservationStructs[reservationId].reservationListPointer = rowToDelete;
        reservationList.pop();

        // we ALSO have to delete this key from the list in the ONE
        bytes32 unitId = reservationStructs[reservationId].unitKey;
        unit.removeReservation(unitId, reservationId);
        emit LogReservationDeleted(msg.sender, reservationId);
        return true;
    }

    function purchaseReservation(bytes32 reservationId)
        internal
        returns (bool)
    {
        require(msg.value >= lock.keyPrice());
        lock.purchase.value(msg.value)(
            lock.keyPrice(),
            msg.sender,
            address(0),
            "0x00"
        );
        emit LogPurchaseReservation(msg.sender, reservationId);
        return true;
    }

    function refundReservation(bytes32 reservationId, uint checkInKey)
        external
    {
        require(reservationStructs[reservationId].checkInKey == checkInKey);
        uint256 tokenId = lock.getTokenIdFor(msg.sender);
        lock.setKeyManagerOf(tokenId, address(this));
        lock.cancelAndRefund(tokenId);

        deleteReservation(reservationId);

        emit LogRefundReservation(msg.sender, reservationId);
    }

    function generateRandomCheckInKey(uint256 id)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(id))) % 10**8;
    }
}