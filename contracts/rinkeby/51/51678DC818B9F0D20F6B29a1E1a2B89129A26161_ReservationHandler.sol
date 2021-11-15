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

    function setRemote(address adr) public {
        require(owner == msg.sender, "NOT_OWNER");
        remote = adr;
    }
}

// SPDX-License-Keyentifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./interfaces/IProvider.sol";
import "./interfaces/IUnit.sol";
import "./interfaces/IReservation.sol";
import "./interfaces/IReservationHandler.sol";

contract ReservationHandler is Owned, IReservationHandler {
    IProvider internal provider;
    event LogNewProvider(address sender, IProvider.ProviderStruct provider);
    event LogProviderDeleted(address sender, bytes32 providerKey);

    IUnit internal unit;
    event LogNewUnit(address sender, IUnit.UnitStruct unit);
    event LogUnitDeleted(address sender, bytes32 unitKey);

    IReservation internal reservation;
    event LogNewReservation(
        address sender,
        IReservation.ReservationStruct reservation
    );
    event LogReservationDeleted(address sender, bytes32 reservationKey);
    event LogRefundReservation(
        address sender,
        IReservation.ReservationStruct reservation
    );

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

    function isProviderOwner(bytes32 providerKey) public view returns (bool) {
        return provider.isProviderOwner(msg.sender, providerKey);
    }

    function getAllProviders()
        external
        view
        returns (IProvider.ProviderStruct[] memory)
    {
        return provider.getAllProviders();
    }

    function createProvider(string calldata name) external {
        emit LogNewProvider(
            msg.sender,
            provider.createProvider(msg.sender, name)
        );
    }

    function deleteProvider(bytes32 providerKey) external {
        provider.deleteProvider(msg.sender, providerKey);
        emit LogProviderDeleted(msg.sender, providerKey);
    }

    //unit methodes
    function setUnitAddress(address adr) external onlyOwner {
        require(address(reservation) != address(0), "SET_RESERVATION_FIRST");
        unit = IUnit(adr);
        reservation.setUnitAddress(adr);
    }

    function isUnitOwner(bytes32 unitKey) public view returns (bool) {
        return unit.isUnitOwner(msg.sender, unitKey);
    }

    function getAllUnits() external view returns (IUnit.UnitStruct[] memory) {
        return unit.getAllUnits();
    }

    function createUnit(bytes32 providerKey, uint16 guestCount) external {
        emit LogNewUnit(
            msg.sender,
            unit.createUnit(msg.sender, providerKey, guestCount)
        );
    }

    function deleteUnit(bytes32 unitKey) external {
        emit LogUnitDeleted(msg.sender, unit.deleteUnit(msg.sender, unitKey));
    }

    //reservation methodes
    function setReservationAddress(address adr) external onlyOwner {
        reservation = IReservation(adr);
    }

    function getAllReservations()
        external
        view
        returns (IReservation.ReservationStruct[] memory)
    {
        return reservation.getAllReservations();
    }

    function createReservation(bytes32 unitKey) external payable {
        emit LogNewReservation(
            msg.sender,
            reservation.createReservation.value(msg.value)(msg.sender, unitKey)
        );
    }

    function deleteReservation(bytes32 reservationKey) external {
        emit LogReservationDeleted(
            msg.sender,
            reservation.deleteReservation(reservationKey)
        );
    }

    function refundReservation(bytes32 reservationKey, uint256 checkInKey)
        external
    {
        emit LogRefundReservation(
            msg.sender,
            reservation.refundReservation(
                msg.sender,
                reservationKey,
                checkInKey
            )
        );
    }

    function getCheckInKey(address sender, bytes32 reservationKey)
        external
        view
        returns (uint256){
            return reservation.getCheckInKey(sender, reservationKey);
        }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

interface IOwner {
    function setRemote(address adr) external;
}

// SPDX-License-Keyentifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IProvider {
    struct ProviderStruct {
        address owner;
        bytes32 providerKey;
        bytes32[] unitKeys;
        string name;
    }

    function isProviderOwner(address sender, bytes32 providerKey)
        external
        view
        returns (bool);

    function getAllProviders() external view returns (ProviderStruct[] memory);

    function createProvider(address sender, string calldata name)
        external
        returns (ProviderStruct memory);

    function deleteProvider(address sender, bytes32 providerKey) external returns (bytes32);
}

// SPDX-License-Keyentifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IReservation {
    struct ReservationStruct {
        bytes32 reservationKey;
        bytes32 unitKey;
        address owner;
    }

    function setUnitAddress(address adr) external;

    function getAllReservations()
        external
        view
        returns (ReservationStruct[] memory);

    function createReservation(address sender, bytes32 unitKey)
        external
        payable
        returns (ReservationStruct memory);

    function deleteReservation(bytes32 reservationKey)
        external
        returns (bytes32);

    function refundReservation(
        address sender,
        bytes32 reservationKey,
        uint256 checkInKey
    ) external returns (ReservationStruct memory);

    function getCheckInKey(address sender, bytes32 reservationKey)
        external
        view
        returns (uint256);
}

// SPDX-License-Keyentifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IProvider.sol";
import "./IUnit.sol";
import "./IReservation.sol";

interface IReservationHandler {
    ///provider
    function isProviderOwner(bytes32 providerKey) external view returns (bool);

    function getAllProviders()
        external
        view
        returns (IProvider.ProviderStruct[] memory);

    function createProvider(string calldata name) external;

    function deleteProvider(bytes32 providerKey) external;

    ///reservation
    function setUnitAddress(address adr) external;

    function getAllReservations()
        external
        view
        returns (IReservation.ReservationStruct[] memory);

    function createReservation(bytes32 unitKey) external payable;

    function deleteReservation(bytes32 reservationKey) external;

    function refundReservation(bytes32 reservationKey, uint256 checkInKey)
        external;

    function getCheckInKey(address sender, bytes32 reservationKey)
        external
        view
        returns (uint256);

    ///unit
    function setProviderAddress(address adr) external;

    function isUnitOwner(bytes32 unitKey)
        external
        view
        returns (bool);

    function getAllUnits() external view returns (IUnit.UnitStruct[] memory);

    function createUnit(bytes32 providerKey, uint16 guestCount)
        external;

    function deleteUnit(bytes32 unitKey) external;
}

// SPDX-License-Keyentifier: MIT
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./IOwner.sol";

interface IUnit {
    struct UnitStruct {
        bytes32 unitKey;
        bytes32 providerKey;
        bytes32[] reservationKeys;
        uint16 guestCount;
    }

    function setProviderAddress(address adr) external;

    function isUnitOwner(address sender, bytes32 unitKey)
        external
        view
        returns (bool);

    function getAllUnits() external view returns (UnitStruct[] memory);

    function createUnit(
        address sender,
        bytes32 providerKey,
        uint16 guestCount
    ) external returns (UnitStruct memory);

    function deleteUnit(address sender, bytes32 unitKey)
        external
        returns (bytes32);
}

