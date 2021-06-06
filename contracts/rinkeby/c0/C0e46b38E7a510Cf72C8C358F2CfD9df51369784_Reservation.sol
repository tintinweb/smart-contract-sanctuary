// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IReservation.sol";
import "./IPublicLock.sol";

import "./Owned.sol";
import "./Unit.sol";

contract Reservation is IReservation, Owned {
    uint256 counter;

    struct ReservationInternalStruct {
        uint256 reservationListPointer;
        bytes32 unitKey;
        //custom data
        uint256 checkInKey;
    }

    event LogNewReservation(
        address sender,
        bytes32 reservationId,
        bytes32 unitId
    );
    event LogNewReservation(
        address sender,
        bytes32 reservationId,
        bytes unitId
    );
    event LogReservationDeleted(address sender, bytes32 reservationId);
    event LogPurchaseReservation(address sender, bytes32 reservationId);
    event LogRefundReservation(address sender, bytes32 reservationId);

    Unit internal unit;
    IPublicLock internal lock;

    mapping(bytes32 => ReservationInternalStruct) public reservationStructs;
    bytes32[] public reservationList;

    constructor(address adrUnit) public {
        unit = Unit(adrUnit);
        lock = IPublicLock(0x2D7Fa4dbdF5E7bfBC87523396aFfD6d38c9520fa);
        //lock.updateRefundPenalty(1000, 0);
    }

    function setUnitAddress(address adr) external onlyOwner {
        unit = Unit(adr);
    }

    function setLockAddress(address payable adr) external onlyOwner {
        lock = IPublicLock(adr);
    }

    function getReservationCount() public view returns (uint256) {
        return reservationList.length;
    }

    function isReservation(bytes32 reservationId) public view returns (bool) {
        if (reservationList.length == 0) return false;
        return
            reservationList[
                reservationStructs[reservationId].reservationListPointer
            ] == reservationId;
    }

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory)
    {
        ReservationStruct[] memory array =
            new ReservationStruct[](getReservationCount());

        for (uint256 i = 0; i < array.length; i++) {
            array[i].reservationId = reservationList[i];
            array[i].unitKey = reservationStructs[array[i].reservationId]
                .unitKey;
        }
        return array;
    }

    function createReservation(address sender, bytes32 unitId)
        public
        payable
        returns (bool)
    {
        require(createReservation(sender, bytes32(counter++), unitId));
        return true;
    }

    function createReservation(
        address sender,
        bytes32 reservationId,
        bytes32 unitId
    ) public returns (bool) {
        require(unit.isUnit(unitId), "UNIT_DOES_NOT_EXIST");
        require(!isReservation(reservationId), "DUPLICATE_RESERVATION_KEY"); // duplicate key prohibited
        require(purchaseReservation(sender, reservationId), "PURCHASE_FAILED");

        reservationList.push(reservationId);
        reservationStructs[reservationId].reservationListPointer =
            reservationList.length -
            1;
        reservationStructs[reservationId].unitKey = unitId;
        reservationStructs[reservationId].checkInKey = generateRandomCheckInKey(
            block.number + uint256(unitId)
        );

        unit.addReservation(unitId, reservationId);
        emit LogNewReservation(sender, reservationId, unitId);
        return true;
    }

    function deleteReservation(address sender, bytes32 reservationId)
        public
        returns (bool)
    {
        require(isReservation(reservationId), "RESERVATION_DOES_NOT_EXIST");

        // delete from table
        uint256 rowToDelete =
            reservationStructs[reservationId].reservationListPointer;
        bytes32 keyToMove = reservationList[reservationList.length - 1];
        reservationList[rowToDelete] = keyToMove;
        reservationStructs[reservationId].reservationListPointer = rowToDelete;
        reservationList.pop();

        bytes32 unitId = reservationStructs[reservationId].unitKey;
        unit.removeReservation(unitId, reservationId);
        emit LogReservationDeleted(sender, reservationId);
        return true;
    }

    function purchaseReservation(address sender, bytes32 reservationId)
        internal
        returns (bool)
    {
        require(msg.value >= lock.keyPrice(), "VALUE_TOO_SMALL");
        lock.purchase.value(msg.value)(
            lock.keyPrice(),
            sender,
            address(0),
            "0x00"
        );
        uint256 tokenId = lock.getTokenIdFor(sender);
        lock.setKeyManagerOf(tokenId, address(this));
        require(
            lock.keyManagerOf(tokenId) == address(this),
            "LOCK_MANAGER_NOT_SET_TO_RESERVATION_CONTRACT"
        );
        emit LogPurchaseReservation(sender, reservationId);
        return true;
    }

    function refundReservation(
        address sender,
        bytes32 reservationId,
        uint256 checkInKey
    ) external returns (bool) {
        require(
            reservationStructs[reservationId].checkInKey == checkInKey,
            "CHECK_IN_KEY_WRONG"
        );
        uint256 tokenId = lock.getTokenIdFor(sender);
        lock.cancelAndRefund(tokenId);

        deleteReservation(sender, reservationId);

        emit LogRefundReservation(sender, reservationId);

        return true;
    }

    function generateRandomCheckInKey(uint256 id)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(id))) % 10**8;
    }
}