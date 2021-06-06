// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./IProvider.sol";
import "./IUnit.sol";
import "./IReservation.sol";

contract ReservationHandler is Owned, IProvider, IUnit, IReservation {
    IProvider internal provider;
    IUnit internal unit;
    IReservation internal reservation;
    address public providerAddress;

    constructor(
        address adrProvider,
        address adrUnit,
        address adrReservation
    ) public {
        providerAddress = adrProvider;
        provider = IProvider(adrProvider);
        unit = IUnit(adrUnit);
        reservation = IReservation(adrReservation);
    }

    function getProviderAddress() public view returns (address){
        return address(provider);
    }

    //provider methodes
    function setProviderAddress(address adr) external onlyOwner {
        require(address(unit) != address(0), "SET_UNIT_FIRST");
        provider = IProvider(adr);
        unit.setProviderAddress(adr);
    }

    function getProviderCount() external view returns (uint256) {
        return provider.getProviderCount();
    }

    function isProvider(bytes32 providerId) external view returns (bool) {
        return provider.isProvider(providerId);
    }

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256)
    {
        return provider.getProviderUnitCount(providerId);
    }

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32)
    {
        return provider.getProviderUnitAtIndex(providerId, row);
    }

    function getAllProviders() external view returns (ProviderStruct[] memory) {
        return provider.getAllProviders();
    }

    function createProvider(string calldata name) external returns (bool) {
        return (provider.createProvider(name));
    }

    function deleteProvider(bytes32 providerId) external returns (bool) {
        return (provider.deleteProvider(providerId));
    }

    //unit methodes
    function setUnitAddress(address adr) external onlyOwner {
        require(address(reservation) != address(0), "SET_RESERVATION_FIRST");
        unit = IUnit(adr);
        reservation.setUnitAddress(adr);
    }

    function getUnitCount() external view returns (uint256) {
        return unit.getUnitCount();
    }

    function isUnit(bytes32 unitId) external view returns (bool) {
        return unit.isUnit(unitId);
    }

    function getAllUnits() external view returns (UnitStruct[] memory) {
        return unit.getAllUnits();
    }

    function createUnit(bytes32 providerId, uint16 guestCount)
        external
        returns (bool)
    {
        return (unit.createUnit(providerId, guestCount));
    }

    function deleteUnit(bytes32 unitId) external returns (bool) {
        return (unit.deleteUnit(unitId));
    }

    //reservation methodes
    function setReservationAddress(address adr) external onlyOwner {
        reservation = IReservation(adr);
    }

    function getReservationCount() external view returns (uint256) {
        return reservation.getReservationCount();
    }

    function isReservation(bytes32 reservationId) external view returns (bool) {
        return reservation.isReservation(reservationId);
    }

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory)
    {
        return reservation.getAllReservations();
    }

    function createReservation(bytes32 unitId) external returns (bool) {
        return (reservation.createReservation(unitId));
    }

    function deleteReservation(bytes32 reservationId) external returns (bool) {
        return (reservation.deleteReservation(reservationId));
    }

    function refundReservation(bytes32 reservationId, uint256 checkInKey)
        external
        returns (bool)
    {
        return (reservation.refundReservation(reservationId, checkInKey));
    }
}