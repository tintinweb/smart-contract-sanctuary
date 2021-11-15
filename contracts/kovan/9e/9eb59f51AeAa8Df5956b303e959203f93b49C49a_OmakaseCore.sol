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
pragma solidity ^0.8.4;

import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import {FlightQueue, LibFlightQueue} from "./models/FlightQueue.sol";
import {Flight, LibFlight} from "./models/Flight.sol";
import {Policy, LibPolicy} from "./models/Policy.sol";
import {InsurancePackage, LibInsurancePackage} from "./models/InsurancePackage.sol";

contract OmakaseCore is KeeperCompatibleInterface {
    using LibFlightQueue for FlightQueue;
    using LibFlight for Flight;
    using LibPolicy for Policy;
    using LibInsurancePackage for InsurancePackage;

    uint256 public totalPolicies;
    mapping(bytes32 => Policy) public _policies;
    mapping(bytes32 => InsurancePackage) public insurancePackages;

    uint256 public totalFlights;
    mapping(bytes32 => Flight) public _flights;

    FlightQueue public flightQueue;

    mapping(bytes32 => bytes32) public pendingRequest;
    uint256 public requestCount;

    address public oracle;
    address public admin;

    event NewPolicy(bytes32 indexed policyId, address creator);
    event PolicyFlightUpdate(
        bytes32 indexed policyId,
        bytes32 indexed flightId,
        address creator
    );

    event NewFlight(bytes32 indexed flightId, address creator);
    event FlightStatusUpdate(
        bytes32 requestId,
        bytes32 indexed flightId,
        bool departed,
        address updater
    );

    event RequestStatusUpdate(bytes32 requestId, bytes32 indexed flightId);
    event RequestPayout(
        bytes32 indexed policyId,
        bytes32 indexed flightId,
        uint256 amount
    );

    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyOracle() {
        require(msg.sender == oracle, "OmakaseCore: Caller is not the oracle");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "OmakaseCore: Caller is not the admin");
        _;
    }

    constructor(address admin_, address oracle_) {
        admin = admin_;
        oracle = oracle_;
    }

    function createPolicy(bytes32 policyId, bytes calldata policyData)
        external
        onlyOracle
    {
        _createPolicy(policyId, policyData);
    }

    function createPolicyWithFlight(
        bytes32 policyId,
        bytes calldata policyData,
        bytes32 flightId,
        uint64 departureTime
    ) external onlyOracle {
        _createPolicy(policyId, policyData);
        setPolicyFlight(policyId, flightId, departureTime);
    }

    function setPolicyFlight(
        bytes32 policyId,
        bytes32 flightId,
        uint64 departureTime
    ) public {
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
        bytes32 curr = flightQueue.head;
        uint256 count = 0;
        while (curr != 0 && block.timestamp >= _getFlight(curr).nextCheck) {
            count++;
            curr = flightQueue.next[curr];
        }

        upkeepNeeded = count > 0;
        performData = abi.encodePacked(count);
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 count = abi.decode(performData, (uint256));

        flightQueue.popHead(count, _checkFlight);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        bool departed,
        uint256 actualDepartureTime
    ) external onlyOracle {
        require(
            pendingRequest[requestId] == flightId,
            "OmakaseCore: Unknown request"
        );

        Flight storage flight = _getFlight(flightId);

        require(
            !flight.departed,
            "OmakaseCore: Flight has already been departed"
        );

        if (departed) {
            uint256 timeDifference = actualDepartureTime - flight.departureTime;

            for (uint256 i = 0; i < flight.policies.length; i++) {
                uint256 indemnity = insurancePackages[flight.policies[i]]
                    .calculateIndemnity(timeDifference);

                emit RequestPayout(requestId, flightId, indemnity);
            }
        } else {
            flight.rescheduleNextCheck();
            flightQueue.addFlightToQueue(flightId, _flights);
        }

        delete pendingRequest[requestId];
        emit FlightStatusUpdate(requestId, flightId, departed, msg.sender);
    }

    function addInsurancePackage(
        bytes32 packageId,
        uint8 delayInterval,
        uint64 indemnityPerInterval,
        uint64 maximumIndemnity
    ) external onlyOracle {
        insurancePackages[packageId] = InsurancePackage({
            delayInterval: delayInterval,
            indemnityPerInterval: indemnityPerInterval,
            maximumIndemnity: maximumIndemnity
        });
    }

    function setOracle(address oracle_) external onlyAdmin {
        require(
            oracle_ != address(0),
            "OmakaseCore: New oracle is the zero address"
        );

        address oldOracle = oracle;
        oracle = oracle_;
        emit OracleChanged(oldOracle, oracle_);
    }

    function setAdmin(address admin_) external onlyAdmin {
        require(
            admin_ != address(0),
            "OmakaseCore: New admin is the zero address"
        );

        address oldAdmin = admin;
        admin = admin_;
        emit AdminChanged(oldAdmin, admin_);
    }

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        return _getFlight(flightId);
    }

    function getPolicy(bytes32 policyId) external view returns (Policy memory) {
        return _getPolicy(policyId);
    }

    function getNextFlightQueue(bytes32 flightId)
        external
        view
        returns (bytes32)
    {
        return flightQueue.next[flightId];
    }

    function getPrevFlightQueue(bytes32 flightId)
        external
        view
        returns (bytes32)
    {
        return flightQueue.prev[flightId];
    }

    function _checkFlight(bytes32 flightId) private {
        require(
            block.timestamp >= _getFlight(flightId).nextCheck,
            "OmakaseCore: Invalid performData"
        );

        requestCount += 1;
        bytes32 requestId = keccak256(abi.encodePacked(requestCount, flightId));
        pendingRequest[requestId] = flightId;

        emit RequestStatusUpdate(requestId, flightId);
    }

    function _createPolicy(bytes32 policyId, bytes calldata policyData)
        private
    {
        Policy storage policy = _getPolicy(policyId);
        policy.initialize(policyData);

        totalPolicies++;

        emit NewPolicy(policyId, msg.sender);
    }

    function _createFlightIfNotExists(bytes32 flightId, uint64 departureTime)
        private
    {
        Flight storage flight = _getFlight(flightId);
        if (!flight.isEmpty()) {
            return;
        }

        flight.initialize(departureTime);

        flightQueue.addFlightToQueue(flightId, _flights);

        totalFlights++;

        emit NewFlight(flightId, msg.sender);
    }

    function _setPolicyFlight(bytes32 policyId, bytes32 flightId) private {
        Policy storage policy = _getPolicy(policyId);
        policy.flightId = flightId;

        _getFlight(flightId).addPolicy(
            policyId,
            insurancePackages[policy.packageId].delayInterval
        );

        emit PolicyFlightUpdate(policyId, flightId, msg.sender);
    }

    function _getFlight(bytes32 flightId)
        private
        view
        returns (Flight storage)
    {
        return _flights[flightId];
    }

    function _getPolicy(bytes32 policyId)
        private
        view
        returns (Policy storage)
    {
        return _policies[policyId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Flight {
    bool departed;
    uint8 checkInterval;
    uint64 nextCheck;
    uint64 departureTime;
    bytes32[] policies;
}

library LibFlight {
    function initialize(Flight storage self, uint64 departureTime) internal {
        require(isEmpty(self), "Flight: Already initialized");
        require(departureTime > block.timestamp, "Flight: Invalid flight time");

        self.nextCheck = departureTime;
        self.departureTime = departureTime;
    }

    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.departureTime == 0;
    }

    function addPolicy(
        Flight storage self,
        bytes32 policyId,
        uint8 delayInterval
    ) internal {
        require(
            self.nextCheck == self.departureTime,
            "Flight: Flight has already been checked"
        );

        if (delayInterval < self.checkInterval) {
            self.checkInterval = delayInterval;
        }

        self.policies.push(policyId);
    }

    function rescheduleNextCheck(Flight storage self) internal {
        self.nextCheck += self.checkInterval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Flight, LibFlight} from "../models/Flight.sol";

struct FlightQueue {
    bytes32 head;
    bytes32 tail;
    uint256 totalQueue;
    mapping(bytes32 => bytes32) next;
    mapping(bytes32 => bytes32) prev;
}

library LibFlightQueue {
    using LibFlight for Flight;

    function addFlightToQueue(
        FlightQueue storage self,
        bytes32 id,
        mapping(bytes32 => Flight) storage flights
    ) internal {
        require(
            !flights[id].isEmpty(),
            "FlightQueue: Flight has not been inserted"
        );
        Flight memory data = flights[id];

        bytes32 curr = self.head;

        if (curr == 0) {
            self.head = id;
            self.tail = id;
        } else if (data.nextCheck <= flights[curr].nextCheck) {
            self.head = id;
            self.next[id] = curr;

            self.prev[curr] = id;
        } else if (data.nextCheck >= flights[self.tail].nextCheck) {
            curr = self.tail;

            self.next[curr] = id;
            self.prev[id] = curr;

            self.tail = id;
        } else {
            bytes32 next;
            while (true) {
                next = self.next[curr];
                if (next == 0 || flights[next].nextCheck >= data.nextCheck) {
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

    function popHead(
        FlightQueue storage self,
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
                require(
                    i + 1 >= count,
                    "FlightQueue: Count exceeds the total data"
                );
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

struct InsurancePackage {
    uint8 delayInterval;
    uint64 indemnityPerInterval;
    uint64 maximumIndemnity;
}

library LibInsurancePackage {
    function calculateIndemnity(
        InsurancePackage memory self,
        uint256 timeDifference
    ) internal pure returns (uint256) {
        uint256 indemnity = (timeDifference / self.delayInterval);
        indemnity *= self.indemnityPerInterval;
        indemnity %= self.maximumIndemnity;
        return indemnity;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Policy {
    bytes32 flightId;
    bytes32 userHash;
    bytes32 packageId;
}

library LibPolicy {
    function initialize(Policy storage self, bytes calldata data) internal {
        require(isEmpty(self), "Policy: Policy has already been registered");

        (self.userHash, self.packageId) = abi.decode(data, (bytes32, bytes32));
    }

    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.flightId == 0;
    }
}

