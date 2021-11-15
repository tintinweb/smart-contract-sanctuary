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

import {Flight, FlightInitArgs, FlightMethods} from "./libraries/models/Flight.sol";
import {Policy, PolicyInitArgs, PolicyMethods} from "./libraries/models/Policy.sol";
import {InsurancePackage, InsurancePackageMethods} from "./libraries/models/InsurancePackage.sol";

import {AppStorage} from "./libraries/LibAppStorage.sol";
import {OracleJob, OracleStorage, LibOracle} from "./libraries/LibOracle.sol";
import {QueueData, PriorityQueue, LibPriorityQueue} from "./libraries/LibPriorityQueue.sol";
import {Errors} from "./libraries/constants/Errors.sol";

contract OmakaseCore is KeeperCompatibleInterface {
    using LibPriorityQueue for PriorityQueue;
    using FlightMethods for Flight;
    using PolicyMethods for Policy;
    using InsurancePackageMethods for InsurancePackage;

    AppStorage s;

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

    event NewInsurancePackage(bytes32 indexed packageId, address creator);

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * These events will be removed in the future.
     * Leaving here just for Web3 to recognize
     */
    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );
    event OracleRequested(bytes32 indexed requestId, OracleJob job, bytes data);
    event OracleFulfilled(bytes32 indexed requestId);
    event RequestStatusUpdate(bytes32 requestId, bytes32 indexed flightId);
    event RequestPayout(
        bytes32 indexed requestId,
        bytes32 indexed flightId,
        uint256 amount
    );

    modifier onlyOracle() {
        LibOracle.enforceCallerIsOracle();
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == s.admin, Errors.OC_CALLER_NOT_ADMIN);
        _;
    }

    modifier oracleCallback(bytes32 requestId, bytes32 flightId) {
        LibOracle.handleOracleCallback(requestId, flightId);
        _;
    }

    constructor(address admin_, address oracle_) {
        s.admin = admin_;

        OracleStorage storage oracleStorage = LibOracle.oracleStorage();
        oracleStorage.oracle = oracle_;
    }

    function createPolicy(bytes32 policyId, PolicyInitArgs calldata args)
        external
        onlyOracle
    {
        _createPolicy(policyId, args);
    }

    function createPolicyWithFlight(
        bytes32 policyId,
        PolicyInitArgs calldata policyArgs,
        bytes32 flightId,
        FlightInitArgs calldata flightArgs
    ) external onlyOracle {
        _createPolicy(policyId, policyArgs);
        setPolicyFlight(policyId, flightId, flightArgs);
    }

    function setPolicyFlight(
        bytes32 policyId,
        bytes32 flightId,
        FlightInitArgs calldata flightArgs
    ) public {
        Policy storage policy = s.policies[policyId];
        require(!policy.isEmpty(), Errors.OC_POLICY_EMPTY);
        require(policy.flightId == 0, Errors.OC_POLICY_HAS_FLIGHT);

        Flight storage flight = _createFlightIfNotExists(flightId, flightArgs);
        require(
            block.timestamp < flight.departureTime,
            Errors.OC_FLIGHT_ALREADY_DEPARTED
        );

        policy.flightId = flightId;

        flight.addPolicy(policyId);

        emit PolicyFlightUpdate(policyId, flightId, msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes32 curr = s.flightQueue.head;
        uint256 count = 0;
        while (
            curr != 0 && block.timestamp >= s.flightQueue.datas[curr].priority
        ) {
            count++;
            curr = s.flightQueue.datas[curr].next;
        }

        upkeepNeeded = count > 0;
        performData = abi.encodePacked(count);
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 count = abi.decode(performData, (uint256));

        s.flightQueue.popHead(count, _checkFlight);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        bool departed,
        uint256 actualDepartureTime
    ) external oracleCallback(requestId, flightId) {
        Flight storage flight = s.flights[flightId];

        require(!flight.departed, Errors.OC_FLIGHT_ALREADY_DEPARTED);

        if (departed) {
            _evaluateFlightDeparture(flightId, flight, actualDepartureTime);
            flight.departed = true;
        } else {
            s.flightQueue.addFlightToQueue(flightId, block.timestamp + 2 hours);
        }

        emit FlightStatusUpdate(requestId, flightId, departed, msg.sender);
    }

    function addInsurancePackage(
        bytes32 packageId,
        uint8 delayInterval,
        uint64 indemnityPerInterval,
        uint64 maximumIndemnity
    ) external onlyOracle {
        require(packageId != 0, Errors.OC_INSURANCE_PACKAGE_ID_ZERO);

        InsurancePackage storage insPackage = s.insurancePackages[packageId];
        require(
            insPackage.isEmpty(),
            Errors.OC_INSURANCE_PACKAGE_ALREADY_ADDED
        );

        insPackage.initialize(
            delayInterval,
            indemnityPerInterval,
            maximumIndemnity
        );

        emit NewInsurancePackage(packageId, msg.sender);
    }

    function setOracle(address oracle_) external onlyAdmin {
        LibOracle.setOracle(oracle_);
    }

    function setAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), Errors.OC_NEW_ADMIN_ZERO_ADDRESS);

        address oldAdmin = s.admin;
        s.admin = admin_;
        emit AdminChanged(oldAdmin, admin_);
    }

    function _checkFlight(bytes32 flightId) private {
        require(
            block.timestamp >= s.flightQueue.datas[flightId].priority,
            Errors.OC_INVALID_PERFORM_DATA
        );

        LibOracle.requestStatusUpdate(flightId);
    }

    function _createPolicy(bytes32 policyId, PolicyInitArgs calldata args)
        private
    {
        require(policyId != 0, Errors.OC_INVALID_INSURANCE_POLICY_ID);
        require(
            !s.insurancePackages[args.packageId].isEmpty(),
            Errors.OC_INVALID_INSURANCE_PACKAGE
        );

        Policy storage policy = s.policies[policyId];
        require(policy.isEmpty(), Errors.OC_POLICY_ALREADY_REGISTERED);

        policy.initialize(args);

        s.totalPolicies++;

        emit NewPolicy(policyId, msg.sender);
    }

    function _createFlightIfNotExists(
        bytes32 flightId,
        FlightInitArgs calldata args
    ) private returns (Flight storage flight) {
        require(flightId != 0, Errors.OC_INVALID_FLIGHT_ID);

        flight = s.flights[flightId];
        if (flight.isEmpty()) {
            flight.initialize(args);

            s.flightQueue.addFlightToQueue(flightId, args.arrivalTime);

            s.totalFlights++;

            emit NewFlight(flightId, msg.sender);
        }
    }

    function _evaluateFlightDeparture(
        bytes32 flightId,
        Flight memory flight,
        uint256 actualDepartureTime
    ) private {
        if (actualDepartureTime <= flight.departureTime) {
            return;
        }

        uint256 hourDifference = (actualDepartureTime - flight.departureTime) /
            1 hours;

        for (uint256 i = 0; i < flight.policies.length; i++) {
            InsurancePackage memory package = s.insurancePackages[
                s.policies[flight.policies[i]].packageId
            ];

            if (!package.eligibleForClaim(hourDifference)) {
                continue;
            }

            uint256 indemnity = package.calculateIndemnity(hourDifference);
            LibOracle.requestPayout(flightId, indemnity);
        }
    }

    /**
     * Getters
     */

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        return s.flights[flightId];
    }

    function totalFlights() external view returns (uint256) {
        return s.totalFlights;
    }

    function getPolicy(bytes32 policyId) external view returns (Policy memory) {
        return s.policies[policyId];
    }

    function totalPolicies() external view returns (uint256) {
        return s.totalPolicies;
    }

    function getInsurancePackage(bytes32 insPackageId)
        external
        view
        returns (InsurancePackage memory)
    {
        return s.insurancePackages[insPackageId];
    }

    function getQueueHead() external view returns (bytes32) {
        return s.flightQueue.head;
    }

    function getQueueTail() external view returns (bytes32) {
        return s.flightQueue.tail;
    }

    function getQueueTotal() external view returns (uint256) {
        return s.flightQueue.totalQueue;
    }

    function getQueueData(bytes32 flightId)
        external
        view
        returns (QueueData memory)
    {
        return s.flightQueue.datas[flightId];
    }

    function admin() external view returns (address) {
        return s.admin;
    }

    function oracle() external view returns (address) {
        OracleStorage storage ds = LibOracle.oracleStorage();
        return ds.oracle;
    }

    function pendingRequest(bytes32 requestId) external view returns (bytes32) {
        OracleStorage storage ds = LibOracle.oracleStorage();
        return ds.pendingRequest[requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Policy} from "./models/Policy.sol";
import {InsurancePackage} from "./models/InsurancePackage.sol";
import {Flight} from "./models/Flight.sol";
import {PriorityQueue} from "./LibPriorityQueue.sol";

struct AppStorage {
    mapping(bytes32 => Policy) policies;
    mapping(bytes32 => InsurancePackage) insurancePackages;
    mapping(bytes32 => Flight) flights;
    uint256 totalPolicies;
    uint256 totalFlights;
    PriorityQueue flightQueue;
    address admin;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Errors} from "./constants/Errors.sol";

enum OracleJob {
    StatusUpdate,
    Payout
}

struct OracleStorage {
    mapping(bytes32 => bytes32) pendingRequest;
    uint256 requestCount;
    address oracle;
}

library LibOracle {
    bytes32 constant ORACLE_STORAGE_POSITION =
        keccak256("omakase.lib_oracle.oracle_storage");

    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );

    event OracleRequested(bytes32 indexed requestId, OracleJob job, bytes data);
    event OracleFulfilled(bytes32 indexed requestId);

    // @deprecated in favor of `OracleRequested`
    event RequestStatusUpdate(bytes32 requestId, bytes32 indexed flightId);

    // @deprecated in favor of `OracleRequested`
    event RequestPayout(
        bytes32 indexed requestId,
        bytes32 indexed flightId,
        uint256 amount
    );

    function oracleStorage() internal pure returns (OracleStorage storage ds) {
        bytes32 position = ORACLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setOracle(address oracle) internal {
        OracleStorage storage ds = oracleStorage();
        require(ds.oracle != address(0), Errors.OC_NEW_ORACLE_ZERO_ADDRESS);

        address oldOracle = ds.oracle;
        ds.oracle = oracle;
        emit OracleChanged(oldOracle, oracle);
    }

    function createRequest(bytes32 flightId)
        private
        returns (bytes32 requestId)
    {
        OracleStorage storage ds = oracleStorage();

        ds.requestCount += 1;
        requestId = keccak256(abi.encodePacked(ds.requestCount, flightId));
        ds.pendingRequest[requestId] = flightId;
    }

    function enforceCallerIsOracle() internal view {
        OracleStorage storage ds = oracleStorage();
        require(msg.sender == ds.oracle, Errors.OC_CALLER_NOT_ORACLE);
    }

    function handleOracleCallback(bytes32 requestId, bytes32 flightId)
        internal
    {
        OracleStorage storage ds = oracleStorage();

        require(msg.sender == ds.oracle, Errors.OC_CALLER_NOT_ORACLE);
        require(
            ds.pendingRequest[requestId] == flightId,
            Errors.OC_UNKNOWN_REQUEST
        );
        emit OracleFulfilled(requestId);
        delete ds.pendingRequest[requestId];
    }

    function requestStatusUpdate(bytes32 flightId) internal {
        bytes32 requestId = createRequest(flightId);

        emit OracleRequested(
            requestId,
            OracleJob.StatusUpdate,
            abi.encodePacked(flightId)
        );

        // @deprecated in favor of `OracleRequested`
        emit RequestStatusUpdate(requestId, flightId);
    }

    function requestPayout(bytes32 flightId, uint256 amount) internal {
        bytes32 requestId = createRequest(flightId);

        emit OracleRequested(
            requestId,
            OracleJob.Payout,
            abi.encodePacked(flightId, amount)
        );

        // @deprecated in favor of `OracleRequested`
        emit RequestPayout(requestId, flightId, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Errors} from "./constants/Errors.sol";

struct QueueData {
    uint256 priority;
    bytes32 next;
    bytes32 prev;
}

struct PriorityQueue {
    bytes32 head;
    bytes32 tail;
    uint256 totalQueue;
    mapping(bytes32 => QueueData) datas;
}

library LibPriorityQueue {
    function addFlightToQueue(
        PriorityQueue storage self,
        bytes32 id,
        uint256 priority
    ) internal {
        QueueData storage insertData = self.datas[id];
        insertData.priority = priority;

        bytes32 curr = self.head;

        if (curr == 0) {
            self.head = id;
            self.tail = id;
        } else if (priority <= self.datas[curr].priority) {
            self.head = id;
            insertData.next = curr;

            self.datas[curr].prev = id;
        } else if (priority >= self.datas[self.tail].priority) {
            curr = self.tail;

            self.datas[curr].next = id;
            insertData.prev = curr;

            self.tail = id;
        } else {
            bytes32 next;
            while (true) {
                next = self.datas[curr].next;
                if (next == 0 || self.datas[next].priority >= priority) {
                    break;
                }

                curr = next;
            }

            self.datas[curr].next = id;
            self.datas[next].prev = id;

            insertData.next = next;
            insertData.prev = curr;
        }

        self.totalQueue++;
    }

    function popHead(
        PriorityQueue storage self,
        uint256 count,
        function(bytes32) internal callback
    ) internal {
        bytes32 tail = self.tail;
        bytes32 curr = self.head;

        for (uint256 i = 0; i < count; i++) {
            bytes32 next = self.datas[curr].next;

            callback(curr);

            delete self.datas[curr];

            if (curr == tail) {
                self.tail = curr = 0;
                require(i + 1 >= count, Errors.PQ_COUNT_EXCEEDS_TOTAL);
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

library Errors {
    // Insurance Package
    string constant INP_INVALID_INTERVAL =
        "Insurance Package: Invalid interval";

    // Flight.sol
    string constant FL_INVALID_FLIGHT_TIME = "Flight: Invalid flight time";

    // PriorityQueue
    string constant PQ_COUNT_EXCEEDS_TOTAL =
        "PriorityQueue: Count exceeds the total data";

    // OmakaseCore.sol
    string constant OC_CALLER_NOT_ORACLE =
        "OmakaseCore: Caller is not the oracle";
    string constant OC_CALLER_NOT_ADMIN =
        "OmakaseCore: Caller is not the admin";
    string constant OC_UNKNOWN_REQUEST = "OmakaseCore: Unknown request";
    string constant OC_FLIGHT_ALREADY_DEPARTED =
        "OmakaseCore: Flight has already been departed";
    string constant OC_NEW_ORACLE_ZERO_ADDRESS =
        "OmakaseCore: New oracle is the zero address";
    string constant OC_NEW_ADMIN_ZERO_ADDRESS =
        "OmakaseCore: New admin is the zero address";
    string constant OC_INVALID_PERFORM_DATA =
        "OmakaseCore: Invalid performData";
    string constant OC_INVALID_INSURANCE_POLICY_ID =
        "OmakaseCore: Invalid insPolicyId";
    string constant OC_INVALID_FLIGHT_ID = "OmakaseCore: Invalid flightId";
    string constant OC_POLICY_EMPTY = "OmakaseCore: Policy is empty";
    string constant OC_POLICY_HAS_FLIGHT =
        "OmakaseCore: Policy has flight already";
    string constant OC_INSURANCE_PACKAGE_ALREADY_ADDED =
        "OmakaseCore: Insurance Package has already been added";
    string constant OC_INSURANCE_PACKAGE_ID_ZERO =
        "OmakaseCore: Insurance Package ID cannot be zero";
    string constant OC_INVALID_INSURANCE_PACKAGE =
        "OmakaseCore: Invalid insurancePackage";
    string constant OC_POLICY_ALREADY_REGISTERED =
        "OmakaseCore: Policy has already been registered";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Errors} from "../constants/Errors.sol";

struct Flight {
    bool departed;
    uint64 departureTime;
    uint64 arrivalTime;
    bytes32[] policies;
}

struct FlightInitArgs {
    uint64 departureTime;
    uint64 arrivalTime;
}

library FlightMethods {
    function initialize(Flight storage self, FlightInitArgs calldata args)
        internal
    {
        require(
            args.departureTime > block.timestamp &&
                args.arrivalTime > block.timestamp,
            Errors.FL_INVALID_FLIGHT_TIME
        );

        self.departureTime = args.departureTime;
        self.arrivalTime = args.arrivalTime;
    }

    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.departureTime == 0;
    }

    function addPolicy(Flight storage self, bytes32 policyId) internal {
        self.policies.push(policyId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Errors} from "../constants/Errors.sol";

struct InsurancePackage {
    uint8 delayInterval;
    uint64 indemnityPerInterval;
    uint64 maximumIndemnity;
}

library InsurancePackageMethods {
    function initialize(
        InsurancePackage storage self,
        uint8 delayInterval,
        uint64 indemnityPerInterval,
        uint64 maximumIndemnity
    ) internal {
        require(delayInterval > 0, Errors.INP_INVALID_INTERVAL);

        self.delayInterval = delayInterval;
        self.indemnityPerInterval = indemnityPerInterval;
        self.maximumIndemnity = maximumIndemnity;
    }

    function isEmpty(InsurancePackage storage self)
        internal
        view
        returns (bool)
    {
        return self.delayInterval == 0;
    }

    function eligibleForClaim(
        InsurancePackage memory self,
        uint256 hourDifference
    ) internal pure returns (bool) {
        return hourDifference >= self.delayInterval;
    }

    /**
     * @dev Should only be called if the `hourDifference`
     * is more than the `delayInterval`
     */
    function calculateIndemnity(
        InsurancePackage memory self,
        uint256 hourDifference
    ) internal pure returns (uint256) {
        uint256 indemnity = (hourDifference / self.delayInterval);
        indemnity *= self.indemnityPerInterval;

        if (indemnity >= self.maximumIndemnity) {
            return self.maximumIndemnity;
        }

        return indemnity;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {InsurancePackage, InsurancePackageMethods} from "./InsurancePackage.sol";
import {Errors} from "../constants/Errors.sol";

struct Policy {
    bytes32 flightId;
    bytes32 userHash;
    bytes32 packageId;
}

struct PolicyInitArgs {
    bytes32 userHash;
    bytes32 packageId;
}

library PolicyMethods {
    using InsurancePackageMethods for InsurancePackage;

    function initialize(Policy storage self, PolicyInitArgs calldata args)
        internal
    {
        self.userHash = args.userHash;
        self.packageId = args.packageId;
    }

    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.userHash == 0;
    }
}

