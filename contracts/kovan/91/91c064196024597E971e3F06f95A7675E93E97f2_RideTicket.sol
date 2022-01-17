//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

import {IRideTicket} from "../../interfaces/core/IRideTicket.sol";

contract RideTicket is IRideTicket {
    function getUserToTixId(address _user)
        external
        view
        override
        returns (bytes32)
    {
        return RideLibTicket._storageTicket().userToTixId[_user];
    }

    function getTixIdToTicket(bytes32 _tixId)
        external
        view
        override
        returns (RideLibTicket.Ticket memory)
    {
        return RideLibTicket._storageTicket().tixIdToTicket[_tixId];
    }

    function getTixToDriverEnd(bytes32 _tixId)
        external
        view
        override
        returns (RideLibTicket.DriverEnd memory)
    {
        return RideLibTicket._storageTicket().tixToDriverEnd[_tixId];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibTicket {
    bytes32 constant STORAGE_POSITION_TICKET = keccak256("ds.ticket");

    /**
     * @dev if a ticket exists (details not 0) in tixIdToTicket, then it is considered active
     *
     * @custom:TODO: Make it loopable so that can list to drivers?
     */
    struct Ticket {
        address passenger;
        address driver;
        uint256 badge;
        bool strict;
        uint256 metres;
        bytes32 keyLocal;
        bytes32 keyPay;
        uint256 requestFee;
        uint256 fare;
        bool tripStart;
        uint256 forceEndTimestamp;
    }

    /**
     * *Required to confirm if driver did initiate destination reached or not
     */
    struct DriverEnd {
        address driver;
        bool reached;
    }

    struct StorageTicket {
        mapping(address => bytes32) userToTixId;
        mapping(bytes32 => Ticket) tixIdToTicket;
        mapping(bytes32 => DriverEnd) tixToDriverEnd;
    }

    function _storageTicket() internal pure returns (StorageTicket storage s) {
        bytes32 position = STORAGE_POSITION_TICKET;
        assembly {
            s.slot := position
        }
    }

    function _requireNotActive() internal view {
        require(
            _storageTicket().userToTixId[msg.sender] == 0,
            "caller is active"
        );
    }

    event TicketCleared(address indexed sender, bytes32 indexed tixId);

    /**
     * _cleanUp clears ticket information and set active status of users to false
     *
     * @param _tixId Ticket ID
     * @param _passenger passenger's address
     * @param _driver driver's address
     *
     * @custom:event TicketCleared
     */
    function _cleanUp(
        bytes32 _tixId,
        address _passenger,
        address _driver
    ) internal {
        StorageTicket storage s1 = _storageTicket();
        delete s1.tixIdToTicket[_tixId];
        delete s1.tixToDriverEnd[_tixId];
        delete s1.userToTixId[_passenger];
        delete s1.userToTixId[_driver];

        emit TicketCleared(msg.sender, _tixId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

interface IRideTicket {
    function getUserToTixId(address _user) external view returns (bytes32);

    function getTixIdToTicket(bytes32 _tixId)
        external
        view
        returns (RideLibTicket.Ticket memory);

    function getTixToDriverEnd(bytes32 _tixId)
        external
        view
        returns (RideLibTicket.DriverEnd memory);

    event TicketCleared(address indexed sender, bytes32 indexed tixId);
}