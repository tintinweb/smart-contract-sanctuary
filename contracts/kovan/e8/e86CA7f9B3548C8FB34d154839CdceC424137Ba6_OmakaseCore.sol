// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import {BCAOwnable} from "./access/BCAOwnable.sol";
import {FlightList, FlightListConfig} from "./models/FlightList.sol";
import {Flight, FlightConfig} from "./models/Flight.sol";
import {Policy, PolicyConfig} from "./models/Policy.sol";

contract OmakaseCore is BCAOwnable, KeeperCompatibleInterface {
    using FlightListConfig for FlightList;
    using FlightConfig for Flight;
    using PolicyConfig for Policy;

    uint256 public constant DELAY_INTERVAL = 12 hours;

    uint256 public totalPolicies;
    mapping(bytes32 => Policy) public policies;

    FlightList public flightList;

    mapping(bytes32 => bytes32) public pendingRequest;
    uint256 public requestCount;

    event NewPolicy(bytes32 indexed policyId, address creator);
    event NewFlight(bytes32 indexed flightId, address creator);
    event PolicyFlightUpdate(bytes32 indexed policyId, bytes32 indexed flightId, address creator);
    event RequestStatusUpdate(bytes32 requestId, bytes32 indexed flightId);
    event FlightStatusUpdate(bytes32 requestId, bytes32 indexed flightId, bool departed, address updater);

    function createPolicy(bytes32 policyId, bytes32 userHash) external onlyBCA {
        _createPolicy(policyId, userHash);
    }

    function createPolicyWithFlight(
        bytes32 policyId,
        bytes32 userHash,
        bytes32 flightId,
        uint256 departureTime
    ) external onlyBCA {
        _createPolicy(policyId, userHash);
        setPolicyFlight(policyId, flightId, departureTime);
    }

    function setPolicyFlight(bytes32 policyId, bytes32 flightId, uint256 departureTime) public {
        _createFlightIfNotExists(flightId, departureTime);
        _setPolicyFlight(policyId, flightId);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes32 curr = flightList.head;
        uint256 count = 0;
        while (curr != 0 && block.timestamp >= _getFlight(curr).nextCheck) {
            count++;
            curr = flightList.next[curr];
        }

        upkeepNeeded = count > 0;
        performData = abi.encodePacked(count);
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 count = abi.decode(performData, (uint256));

        flightList.popHeadWithCallback(count, _checkFlight);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        bool departed,
        uint256 actualDepartureTime
    ) external onlyBCA {
        require(pendingRequest[requestId] == flightId, "Unknown request");

        Flight storage flight = _getFlight(flightId);

        require(!flight.departed, "Flight has already been departed");

        if (departed) {
            uint256 delay = (actualDepartureTime - flight.departureTime) /
                DELAY_INTERVAL;
            if (delay > 0) {
                // TODO: Request Payout
            }
            flight.departed = true;
        } else {
            uint256 nextCheck = flight.nextCheck + DELAY_INTERVAL;

            flight.nextCheck = nextCheck;
            flightList.addFlightToQueue(flightId);
        }

        delete pendingRequest[requestId];
        emit FlightStatusUpdate(requestId, flightId, departed, msg.sender);
    }

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        return _getFlight(flightId);
    }

    function getNextFlightQueue(bytes32 flightId)
        external
        view
        returns (bytes32)
    {
        return flightList.next[flightId];
    }

    function getPrevFlightQueue(bytes32 flightId)
        external
        view
        returns (bytes32)
    {
        return flightList.prev[flightId];
    }

    function totalFlights() external view returns (uint256) {
        return flightList.totalFlights;
    }


    function _checkFlight(bytes32 flightId) private {
        require(
            block.timestamp >= _getFlight(flightId).nextCheck,
            "Invalid performData"
        );

        requestCount += 1;
        bytes32 requestId = keccak256(abi.encodePacked(requestCount, flightId));
        pendingRequest[requestId] = flightId;

        emit RequestStatusUpdate(requestId, flightId);
    }

    function _createPolicy(bytes32 policyId, bytes32 userHash) private {
        require(
            policies[policyId].isEmpty(),
            "Policy has already been registered"
        );

        policies[policyId].userHash = userHash;
        totalPolicies++;

        emit NewPolicy(policyId, msg.sender);
    }

    function _createFlightIfNotExists(bytes32 flightId, uint256 departureTime)
        private
    {
        if (!_getFlight(flightId).isEmpty()) {
            return;
        }

        Flight storage flight = flightList.addFlight(flightId);
        flight.initialize(departureTime);

        flightList.addFlightToQueue(flightId);

        emit NewFlight(flightId, msg.sender);
    }

    function _setPolicyFlight(bytes32 policyId, bytes32 flightId) private {
        policies[policyId].flightId = flightId;
        _getFlight(flightId).policies.push(policyId);

        emit PolicyFlightUpdate(policyId, flightId, msg.sender);
    }

    function _getFlight(bytes32 flightId)
        private
        view
        returns (Flight storage)
    {
        return flightList.flights[flightId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract BCAOwnable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @notice `owner` means BCA.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner (BCA).
     */
    modifier onlyBCA() {
        require(owner() == _msgSender(), "Ownable: caller is not BCA");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyBCA {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Flight {
    uint256 nextCheck;
    bool departed;
    uint256 departureTime;
    bytes32[] policies;
}

library FlightConfig {
    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.departureTime == 0;
    }

    function initialize(Flight storage self, uint256 departureTime) internal {
        require(departureTime > block.timestamp, "Invalid flight time");

        self.nextCheck = departureTime;
        self.departureTime = departureTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Flight, FlightConfig} from "../models/Flight.sol";

struct FlightList {
    bytes32 head;
    bytes32 tail;
    uint256 totalFlights;
    uint256 totalQueue;
    mapping(bytes32 => bytes32) next;
    mapping(bytes32 => bytes32) prev;
    mapping(bytes32 => Flight) flights;
}

library FlightListConfig {
    using FlightConfig for Flight;

    function addFlight(FlightList storage self, bytes32 id)
        internal
        returns (Flight storage)
    {
        require(self.flights[id].isEmpty(), "Flight has already been inserted");
        self.totalFlights++;
        return self.flights[id];
    }

    function addFlightToQueue(FlightList storage self, bytes32 id) internal {
        require(!self.flights[id].isEmpty(), "Flight has not been inserted");
        Flight memory data = self.flights[id];

        bytes32 curr = self.head;

        if (curr == 0) {
            self.head = id;
            self.tail = id;
        } else if (data.nextCheck <= self.flights[curr].nextCheck) {
            self.head = id;
            self.next[id] = curr;

            self.prev[curr] = id;
        } else if (data.nextCheck >= self.flights[self.tail].nextCheck) {
            curr = self.tail;

            self.next[curr] = id;
            self.prev[id] = curr;

            self.tail = id;
        } else {
            bytes32 next;
            while (true) {
                next = self.next[curr];
                if (
                    next == 0 || self.flights[next].nextCheck >= data.nextCheck
                ) {
                    break;
                }

                curr = next;
            }

            self.next[curr] = id;
            self.prev[next] = id;

            self.next[id] = next;
            self.prev[id] = curr;
        }

        self.totalQueue++;
    }

    function popHeadWithCallback(
        FlightList storage self,
        uint256 count,
        function(bytes32) internal callback
    ) internal {
        bytes32 tail = self.tail;
        bytes32 curr = self.head;

        for (uint256 i = 0; i < count; i++) {
            bytes32 next = self.next[curr];

            callback(curr);

            delete self.next[curr];
            delete self.prev[curr];

            if (curr == tail) {
                self.tail = curr = 0;
                require(i + 1 >= count, "Count exceeds the total data");
            } else {
                curr = next;
            }
        }

        self.head = curr;
        self.totalQueue -= count;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Policy {
    bytes32 flightId;
    bytes32 userHash;
}

library PolicyConfig {
    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.flightId == 0;
    }
}

