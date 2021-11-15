// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./interfaces/IOwner.sol";

contract Owned is IOwner {
    address public owner;
    address public remote;

    modifier onlyOwner() {
        require(
            owner == msg.sender ||
                address(this) == msg.sender ||
                remote == msg.sender,
            "NOT_OWNER needed"
        );
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addRemote(address adr) public {
        require(owner == msg.sender, "NOT_OWNER");
        remote = adr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./interfaces/IProvider.sol";
import "./interfaces/IUnit.sol";
import "./interfaces/IReservation.sol";
import "./interfaces/IReservationHandler.sol";

contract ReservationHandler is Owned, IReservationHandler {
    IProvider internal provider;
    IUnit internal unit;
    IReservation internal reservation;

    constructor(
        address adrProvider,
        address adrUnit,
        address adrReservation
    ) public {
        provider = IProvider(adrProvider);
        unit = IUnit(adrUnit);
        reservation = IReservation(adrReservation);
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

    function isProviderOwner(bytes32 providerId) public view returns (bool) {
        return provider.isProviderOwner(msg.sender, providerId);
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

    function getAllProviders()
        external
        view
        returns (IProvider.ProviderStruct[] memory)
    {
        return provider.getAllProviders();
    }

    function createProvider(string calldata name) external returns (bool) {
        return (provider.createProvider(msg.sender, name));
    }

    function deleteProvider(bytes32 providerId) external returns (bool) {
        return (provider.deleteProvider(msg.sender, providerId));
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

    function getAllUnits() external view returns (IUnit.UnitStruct[] memory) {
        return unit.getAllUnits();
    }

    function createUnit(bytes32 providerId, uint16 guestCount)
        external
        returns (bool)
    {
        return (unit.createUnit(msg.sender, providerId, guestCount));
    }

    function deleteUnit(bytes32 unitId) external returns (bool) {
        return (unit.deleteUnit(msg.sender, unitId));
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
        returns (IReservation.ReservationStruct[] memory)
    {
        return reservation.getAllReservations();
    }

    function createReservation(bytes32 unitId) external payable returns (bool) {
        return (reservation.createReservation.value(msg.value)(msg.sender, unitId));
    }

    function deleteReservation(bytes32 reservationId) external returns (bool) {
        return (reservation.deleteReservation(msg.sender, reservationId));
    }

    function refundReservation(bytes32 reservationId, uint256 checkInKey)
        external
        returns (bool)
    {
        return (
            reservation.refundReservation(msg.sender, reservationId, checkInKey)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

interface IOwner {
    function addRemote(address adr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerId;
        bytes32[] unitKeys;
        string name;
    }

    function getProviderCount() external view returns (uint256);

    function isProvider(bytes32 providerId) external view returns (bool);

    function isProviderOwner(address sender, bytes32 providerId)
        external
        view
        returns (bool);

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256);

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function createProvider(address sender, string calldata name)
        external
        returns (bool);

    function deleteProvider(address sender, bytes32 providerId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IReservation {
    struct ReservationStruct {
        bytes32 reservationId;
        bytes32 unitKey;
        address owner;
    }

    function setUnitAddress(address adr) external;

    function getReservationCount() external view returns (uint256);

    function isReservation(bytes32 reservationId) external view returns (bool);

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory);

    function createReservation(address sender, bytes32 unitId)
        external
        payable
        returns (bool);

    function deleteReservation(address sender, bytes32 reservationId) external returns (bool);

    function refundReservation(
        address sender,
        bytes32 reservationId,
        uint256 checkInKey
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IProvider.sol";
import "./IUnit.sol";
import "./IReservation.sol";

interface IReservationHandler {
    ///provider
    function getProviderCount() external view returns (uint256);

    function isProviderOwner(bytes32 providerId) external view returns (bool);

    function getProviderUnitCount(bytes32 providerId)
        external
        view
        returns (uint256);

    function getProviderUnitAtIndex(bytes32 providerId, uint256 row)
        external
        view
        returns (bytes32);

    function getAllProviders()
        external
        view
        returns (IProvider.ProviderStruct[] memory);

    function createProvider(string calldata name) external returns (bool);

    function deleteProvider(bytes32 providerId) external returns (bool);

    ///reservation
    function setUnitAddress(address adr) external;

    function getReservationCount() external view returns (uint256);

    function isReservation(bytes32 reservationId) external view returns (bool);

    function getAllReservations()
        external
        view
        returns (IReservation.ReservationStruct[] memory);

    function createReservation(bytes32 unitId) external payable returns (bool);

    function deleteReservation(bytes32 reservationId) external returns (bool);

    function refundReservation(bytes32 reservationId, uint256 checkInKey)
        external
        returns (bool);

    ///unit
    function setProviderAddress(address adr) external;

    function getUnitCount() external view returns (uint256);

    function isUnit(bytes32 unitId) external view returns (bool);

    function getAllUnits() external view returns (IUnit.UnitStruct[] memory);

    function createUnit(bytes32 providerId, uint16 guestCount)
        external
        returns (bool);

    function deleteUnit(bytes32 unitId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IOwner.sol";

interface IUnit {
    struct UnitStruct {
        bytes32 unitId;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        uint16 guestCount;
    }

    function setProviderAddress(address adr) external;

    function getUnitCount() external view returns (uint256);

    function isUnit(bytes32 unitId) external view returns (bool);

    function getAllUnits() external view returns (UnitStruct[] memory);

    function createUnit(address sender, bytes32 providerId, uint16 guestCount)
        external
        returns (bool);

    function deleteUnit(address sender, bytes32 unitId) external returns (bool);
}

