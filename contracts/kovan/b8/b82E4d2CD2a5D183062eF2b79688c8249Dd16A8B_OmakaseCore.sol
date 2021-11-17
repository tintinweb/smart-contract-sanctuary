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
pragma solidity ^0.8.9;

import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import {Flight, LibFlight} from "./libraries/LibFlight.sol";
import {Policy, PolicyBenefitData, PolicyInitArgs, LibPolicy} from "./libraries/LibPolicy.sol";
import {Product, LibProduct} from "./libraries/LibProduct.sol";
import {BenefitName} from "./benefits/BenefitName.sol";
import {BenefitStatus} from "./benefits/BenefitStatus.sol";
import {BenefitFlightDelay, LibBenefitFlightDelay} from "./benefits/LibBenefitFlightDelay.sol";
import {BenefitPersonalAccident, LibBenefitPersonalAccident} from "./benefits/LibBenefitPersonalAccident.sol";
import {BenefitBaggageDelay, LibBenefitBaggageDelay} from "./benefits/LibBenefitBaggageDelay.sol";
import {BenefitFlightPostponement, LibBenefitFlightPostponement} from "./benefits/LibBenefitFlightPostponement.sol";

import {AppStorage} from "./libraries/LibAppStorage.sol";
import {OracleJob, OracleStorage, LibOracle} from "./libraries/LibOracle.sol";
import {QueueData, PriorityQueue, LibPriorityQueue} from "./libraries/LibPriorityQueue.sol";
import {LibString} from "./libraries/LibString.sol";
import {LibNumber} from "./libraries/LibNumber.sol";

import {Errors} from "./constants/Errors.sol";

contract OmakaseCore is KeeperCompatibleInterface {
    using LibString for string;
    using LibNumber for uint256;
    using LibPriorityQueue for PriorityQueue;
    using LibFlight for Flight;
    using LibPolicy for Policy;
    using LibProduct for Product;
    using LibBenefitFlightDelay for BenefitFlightDelay;

    struct FlightArgs {
        bytes32 id;
        uint64 arrivalTime;
        uint64 departureTime;
    }

    enum Gender {
        Male,
        Female
    }

    AppStorage s;

    event NewPolicy(bytes32 indexed policyId, address creator);
    event PolicyFlightsUpdated(
        bytes32 indexed policyId,
        bytes32[] flights,
        address creator
    );

    event FlightStatusUpdate(
        bytes32 requestId,
        bytes32 indexed flightId,
        bool departed,
        uint256 actualDepartureTime,
        address updater
    );

    event NewProduct(
        bytes32 indexed productId,
        BenefitName[] benefits,
        address creator
    );
    event ClaimExpireTimeChanged(uint64 previousTime, uint64 newTime);

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyOracle() {
        LibOracle.enforceCallerIsOracle();
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == s.admin, Errors.OC_CALLER_NOT_ADMIN);
        _;
    }

    modifier oracleCallback(bytes32 requestId) {
        LibOracle.handleOracleCallback(requestId);
        _;
    }

    constructor(address admin_, address oracle_) {
        s.admin = admin_;
        s.claimExpireTime = 30 days;

        OracleStorage storage oracleStorage = LibOracle.oracleStorage();
        oracleStorage.oracle = oracle_;
    }

    function generatePolicyId(string calldata policyNo)
        external
        view
        returns (bytes32)
    {
        uint256 curr = block.timestamp;
        string memory strPolicyId = policyNo;

        while (!s.policies[strPolicyId.toBytes32()].isEmpty()) {
            strPolicyId = string(
                abi.encodePacked(strPolicyId, "-", curr.toString())
            );
            curr++;
        }

        return strPolicyId.toBytes32();
    }

    function generateUserHash(
        string calldata name,
        string calldata email,
        string calldata phoneNumber,
        Gender gender,
        string calldata birthDate // mm-dd-yyyy (en-us)
    ) external pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(name, email, phoneNumber, gender, birthDate)
            );
    }

    function generateFlightId(
        string calldata carrierIcaoCode,
        string calldata carrierIataCode,
        uint256 flightNumber,
        uint64 departureTime
    ) external pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    carrierIcaoCode,
                    carrierIataCode,
                    flightNumber,
                    departureTime
                )
            );
    }

    function generateBenefitPersonalAccidentInitializeData(
        uint256 maximumAmount
    ) external pure returns (bytes memory) {
        return LibBenefitPersonalAccident.generateInitializeData(maximumAmount);
    }

    function generateBenefitFlightDelayInitializeData(
        uint256 maximumAmount,
        uint256 delayInterval,
        uint256 amountPerInterval
    ) external pure returns (bytes memory) {
        return
            LibBenefitFlightDelay.generateInitializeData(
                maximumAmount,
                delayInterval,
                amountPerInterval
            );
    }

    function generateBenefitBaggageDelayInitializeData(
        uint256 maximumAmount,
        uint256 delayHour
    ) external pure returns (bytes memory) {
        return
            LibBenefitBaggageDelay.generateInitializeData(
                maximumAmount,
                delayHour
            );
    }

    function generateBenefitFlightPostponementInitializeData(
        uint256 maximumAmount
    ) external pure returns (bytes memory) {
        return
            LibBenefitFlightPostponement.generateInitializeData(maximumAmount);
    }

    function hasProduct(bytes32 productId) external view returns (bool) {
        return !s.products[productId].isEmpty();
    }

    function getBenefitPersonalAccident(bytes32 productId)
        external
        view
        returns (BenefitPersonalAccident memory)
    {
        return s.products[productId].benefitPersonalAccident;
    }

    function getBenefitFlightDelay(bytes32 productId)
        external
        view
        returns (BenefitFlightDelay memory)
    {
        return s.products[productId].benefitFlightDelay;
    }

    function getBenefitBaggageDelay(bytes32 productId)
        external
        view
        returns (BenefitBaggageDelay memory)
    {
        return s.products[productId].benefitBaggageDelay;
    }

    function getBenefitFlightPostponement(bytes32 productId)
        external
        view
        returns (BenefitFlightPostponement memory)
    {
        return s.products[productId].benefitFlightPostponement;
    }

    function getProductBenefits(bytes32 productId)
        external
        view
        returns (BenefitName[] memory)
    {
        return s.products[productId].benefits;
    }

    function createPolicy(bytes32 policyId, PolicyInitArgs calldata args)
        external
        onlyOracle
    {
        _createPolicy(policyId, args);
    }

    function createPolicyWithFlights(
        bytes32 policyId,
        PolicyInitArgs calldata policyArgs,
        FlightArgs[] calldata flightData
    ) external onlyOracle {
        _createPolicy(policyId, policyArgs);
        setPolicyFlights(policyId, flightData);
    }

    function setPolicyFlights(
        bytes32 policyId,
        FlightArgs[] calldata flightData
    ) public onlyOracle {
        Policy storage policy = s.policies[policyId];
        require(!policy.isEmpty(), Errors.OC_POLICY_EMPTY);
        require(policy.totalFlights() == 0, Errors.OC_POLICY_HAS_FLIGHT);

        for (uint256 i = 0; i < flightData.length; i++) {
            Flight storage flight = LibFlight.createFlightIfNotExists(
                flightData[i].id,
                flightData[i].departureTime,
                flightData[i].arrivalTime
            );

            s.flightQueue.addIfNotExists(
                flightData[i].id,
                flightData[i].arrivalTime
            );
            policy.addFlight(flightData[i].id);
            flight.addPolicy(policyId);
        }

        emit PolicyFlightsUpdated(policyId, policy.flights, msg.sender);
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
    ) external oracleCallback(requestId) {
        Flight storage flight = s.flights[flightId];

        require(!flight.departed, Errors.OC_FLIGHT_ALREADY_DEPARTED);

        if (departed) {
            _evaluateFlightDeparture(flightId, flight, actualDepartureTime);
            flight.departed = true;
        } else {
            s.flightQueue.addIfNotExists(flightId, block.timestamp + 2 hours);
        }

        emit FlightStatusUpdate(
            requestId,
            flightId,
            departed,
            actualDepartureTime,
            msg.sender
        );
    }

    function createProduct(
        bytes32 productId,
        LibProduct.BenefitInitializeArgs[] calldata benefits
    ) external onlyOracle {
        require(productId != 0, Errors.OC_PRODUCT_ID_ZERO);

        Product storage product = s.products[productId];
        require(product.isEmpty(), Errors.OC_PRODUCT_ALREADY_ADDED);

        product.initialize(benefits);

        emit NewProduct(productId, product.benefits, msg.sender);
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

    function setClaimExpireTime(uint64 claimExpireTime) external onlyAdmin {
        uint64 previousTime = s.claimExpireTime;
        s.claimExpireTime = claimExpireTime;

        emit ClaimExpireTimeChanged(previousTime, claimExpireTime);
    }

    function confirmProcessingClaim(bytes32 requestId, bytes32 policyId)
        external
        oracleCallback(requestId)
    {
        s.policies[policyId].pendingClaims[requestId] = block.timestamp;
    }

    function completeClaim(
        bytes32 requestId,
        bytes32 policyId,
        BenefitName benefitName,
        uint64 claimAmount,
        bool success
    ) external onlyOracle {
        Policy storage policy = s.policies[policyId];
        require(!policy.isEmpty(), Errors.OC_INVALID_INSURANCE_POLICY_ID);
        require(
            policy.pendingClaims[requestId] != 0,
            Errors.OC_UNKNOWN_CLAIM_REQUEST
        );
        require(
            LibProduct.hasBenefit(policy.productId, benefitName),
            Errors.OC_POLICY_DOES_NOT_HAVE_THE_BENEFIT
        );

        PolicyBenefitData storage benefitData = policy.benefitsData[
            benefitName
        ];

        if (
            !success ||
            block.timestamp >=
            (policy.pendingClaims[requestId] + s.claimExpireTime)
        ) {
            benefitData.claimedAmount -= claimAmount;
            benefitData.status = BenefitStatus.Expired;
        } else {
            benefitData.status = BenefitStatus.Claimed;
        }

        delete policy.pendingClaims[requestId];
    }

    function _getPolicyProduct(bytes32 policyId)
        private
        view
        returns (Product storage)
    {
        return s.products[s.policies[policyId].productId];
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
            !s.products[args.productId].isEmpty(),
            Errors.OC_INVALID_PRODUCT
        );

        Policy storage policy = s.policies[policyId];
        require(policy.isEmpty(), Errors.OC_POLICY_ALREADY_REGISTERED);

        policy.initialize(args);

        s.totalPolicies++;

        emit NewPolicy(policyId, msg.sender);
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
            bytes32 policyId = flight.policies[i];
            BenefitFlightDelay storage benefit = _getPolicyProduct(policyId)
                .benefitFlightDelay;

            PolicyBenefitData storage benefitData = s
                .policies[policyId]
                .benefitsData[BenefitName.FlightDelay];

            if (
                !benefit.eligibleForClaim(
                    benefitData.claimedAmount,
                    hourDifference
                )
            ) {
                continue;
            }

            uint256 indemnity = benefit.calculateIndemnity(
                benefitData.claimedAmount,
                hourDifference
            );
            benefitData.claimedAmount += uint64(indemnity);
            benefitData.status = BenefitStatus.ClaimInProgress;

            LibOracle.requestPayout(
                policyId,
                flightId,
                hourDifference,
                indemnity
            );
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

    function totalPolicies() external view returns (uint256) {
        return s.totalPolicies;
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

    /**
     * Policy Data
     */

    function getPolicyUserHash(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        return s.policies[policyId].userHash;
    }

    function getPolicyProductId(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        return s.policies[policyId].productId;
    }

    function getPolicyFlightIds(bytes32 policyId)
        external
        view
        returns (bytes32[] memory)
    {
        return s.policies[policyId].flights;
    }

    function getPolicyBenefitData(bytes32 policyId, BenefitName benefitName)
        external
        view
        returns (PolicyBenefitData memory)
    {
        return s.policies[policyId].benefitsData[benefitName];
    }

    /***/

    function admin() external view returns (address) {
        return s.admin;
    }

    function oracle() external view returns (address) {
        OracleStorage storage ds = LibOracle.oracleStorage();
        return ds.oracle;
    }

    function pendingRequest(bytes32 requestId) external view returns (uint256) {
        OracleStorage storage ds = LibOracle.oracleStorage();
        return ds.pendingRequest[requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum BenefitName {
    PersonalAccident,
    FlightDelay,
    BaggageDelay,
    TripCancellation,
    FlightPostponement
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum BenefitStatus {
    Active,
    ClaimInProgress,
    Claimed,
    Expired
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from "../constants/Errors.sol";

struct BenefitBaggageDelay {
    uint8 delayHour;
    uint64 maximumAmount;
}

library LibBenefitBaggageDelay {
    function generateInitializeData(uint256 maximumAmount, uint256 delayHour)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(maximumAmount, delayHour);
    }

    function initialize(BenefitBaggageDelay storage self, bytes memory data)
        internal
    {
        (uint256 maximumAmount, uint256 delayHour) = abi.decode(
            data,
            (uint256, uint256)
        );

        require(delayHour > 0, Errors.BBD_INVALID_DELAY_HOUR);

        self.maximumAmount = uint64(maximumAmount);
        self.delayHour = uint8(delayHour);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from "../constants/Errors.sol";

struct BenefitFlightDelay {
    uint8 delayInterval;
    uint64 maximumAmount;
    uint64 amountPerInterval;
}

library LibBenefitFlightDelay {
    function generateInitializeData(
        uint256 maximumAmount,
        uint256 delayInterval,
        uint256 amountPerInterval
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(maximumAmount, delayInterval, amountPerInterval);
    }

    function initialize(BenefitFlightDelay storage self, bytes memory data)
        internal
    {
        (
            uint256 maximumAmount,
            uint256 delayInterval,
            uint256 amountPerInterval
        ) = abi.decode(data, (uint256, uint256, uint256));

        require(delayInterval > 0, Errors.BFD_INVALID_DELAY_INTERVAL);

        self.maximumAmount = uint64(maximumAmount);
        self.delayInterval = uint8(delayInterval);
        self.amountPerInterval = uint64(amountPerInterval);
    }

    function eligibleForClaim(
        BenefitFlightDelay storage self,
        uint256 claimedAmount,
        uint256 hourDifference
    ) internal view returns (bool) {
        if (claimedAmount >= self.maximumAmount) {
            return false;
        }

        return hourDifference >= self.delayInterval;
    }

    /**
     * @dev Should only be called if it's `eligibleForClaim`.
     * Otherwise, it could throw a 'division by zero' error or
     * returns zero
     */
    function calculateIndemnity(
        BenefitFlightDelay storage self,
        uint64 claimedIndemnity,
        uint256 hourDifference
    ) internal view returns (uint256 indemnity) {
        indemnity =
            (hourDifference / self.delayInterval) *
            self.amountPerInterval;

        uint64 limit = self.maximumAmount - claimedIndemnity;
        if (indemnity >= limit) {
            indemnity = limit;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from "../constants/Errors.sol";

struct BenefitFlightPostponement {
    uint64 maximumAmount;
}

library LibBenefitFlightPostponement {
    function generateInitializeData(uint256 maximumAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(maximumAmount);
    }

    function initialize(
        BenefitFlightPostponement storage self,
        bytes memory data
    ) internal {
        uint256 maximumAmount = abi.decode(data, (uint256));

        self.maximumAmount = uint64(maximumAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BenefitStatus} from "./BenefitStatus.sol";

struct BenefitPersonalAccident {
    uint64 maximumAmount;
}

library LibBenefitPersonalAccident {
    function generateInitializeData(uint256 maximumAmount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(maximumAmount);
    }

    function initialize(BenefitPersonalAccident storage self, bytes memory data)
        internal
    {
        uint256 maximumAmount = abi.decode(data, (uint256));

        self.maximumAmount = uint64(maximumAmount);
    }

    function isEmpty(BenefitPersonalAccident storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Errors {
    // Insurance Package
    string constant INP_INVALID_INTERVAL =
        "Insurance Package: Invalid interval";

    // Flight.sol
    string constant FL_INVALID_FLIGHT_TIME = "Flight: Invalid flight time";
    string constant FL_FLIGHT_ALREADY_DEPARTED =
        "LibFlight: Flight has already departed";

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
        "OmakaseCore: Flight has already departed";
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
    string constant OC_PRODUCT_ALREADY_ADDED =
        "OmakaseCore: Product has already been added";
    string constant OC_PRODUCT_ID_ZERO =
        "OmakaseCore: Product ID cannot be zero";
    string constant OC_INVALID_PRODUCT = "OmakaseCore: Invalid product";
    string constant OC_POLICY_ALREADY_REGISTERED =
        "OmakaseCore: Policy has already been registered";
    string constant OC_POLICY_DOES_NOT_HAVE_THE_BENEFIT =
        "OmakaseCore: Policy does not have the benefit";
    string constant OC_UNKNOWN_CLAIM_REQUEST =
        "OmakaseCore: Unknown claim request";

    // BenefitFlightDelay
    string constant BFD_INVALID_DELAY_INTERVAL =
        "BenefitFlightDelay: Invalid delay interval";

    // BenefitBaggageDelay
    string constant BBD_INVALID_DELAY_HOUR =
        "BenefitBaggageDelay: Invalid delay hour";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Policy} from "./LibPolicy.sol";
import {Product} from "./LibProduct.sol";
import {Flight} from "./LibFlight.sol";
import {PriorityQueue} from "./LibPriorityQueue.sol";

struct AppStorage {
    mapping(bytes32 => Policy) policies;
    mapping(bytes32 => Product) products;
    mapping(bytes32 => Flight) flights;
    uint256 totalPolicies;
    uint256 totalFlights;
    PriorityQueue flightQueue;
    address admin;
    uint64 claimExpireTime;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {PriorityQueue, LibPriorityQueue} from "./LibPriorityQueue.sol";
import {Errors} from "../constants/Errors.sol";

struct Flight {
    bool departed;
    uint64 departureTime;
    uint64 arrivalTime;
    bytes32[] policies;
}

library LibFlight {
    using LibFlight for Flight;

    event NewFlight(bytes32 indexed flightId, address creator);

    function createFlightIfNotExists(
        bytes32 id,
        uint64 departureTime,
        uint64 arrivalTime
    ) internal returns (Flight storage flight) {
        AppStorage storage s = LibAppStorage.appStorage();

        require(id != 0, Errors.OC_INVALID_FLIGHT_ID);

        flight = s.flights[id];
        if (flight.isEmpty()) {
            //
            // Disabled because of business reason
            //
            // require(arrivalTime > departureTime, Errors.FL_INVALID_FLIGHT_TIME);
            // require(
            //     block.timestamp < departureTime,
            //     Errors.FL_FLIGHT_ALREADY_DEPARTED
            // );

            flight.departureTime = departureTime;
            flight.arrivalTime = arrivalTime;

            s.totalFlights++;

            emit NewFlight(id, msg.sender);
        }
    }

    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.departureTime == 0;
    }

    function addPolicy(Flight storage self, bytes32 policyId) internal {
        self.policies.push(policyId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibNumber {
    function toString(uint256 self) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (self == 0) {
            return "0";
        }
        uint256 temp = self;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (self != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(self % 10)));
            self /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from "../constants/Errors.sol";

enum OracleJob {
    StatusUpdate,
    Payout
}

struct OracleStorage {
    mapping(bytes32 => uint256) pendingRequest;
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

    function createRequest() private returns (bytes32 requestId) {
        OracleStorage storage ds = oracleStorage();

        ds.requestCount += 1;
        requestId = keccak256(abi.encodePacked(ds.requestCount));
        ds.pendingRequest[requestId] = block.timestamp;
    }

    function enforceCallerIsOracle() internal view {
        OracleStorage storage ds = oracleStorage();
        require(msg.sender == ds.oracle, Errors.OC_CALLER_NOT_ORACLE);
    }

    function handleOracleCallback(bytes32 requestId) internal {
        OracleStorage storage ds = oracleStorage();

        require(msg.sender == ds.oracle, Errors.OC_CALLER_NOT_ORACLE);
        require(ds.pendingRequest[requestId] != 0, Errors.OC_UNKNOWN_REQUEST);
        emit OracleFulfilled(requestId);
        delete ds.pendingRequest[requestId];
    }

    function requestStatusUpdate(bytes32 flightId) internal {
        bytes32 requestId = createRequest();

        emit OracleRequested(
            requestId,
            OracleJob.StatusUpdate,
            abi.encodePacked(flightId)
        );
    }

    function requestPayout(
        bytes32 policyId,
        bytes32 flightId,
        uint256 delayedHours,
        uint256 amount
    ) internal {
        bytes32 requestId = createRequest();

        emit OracleRequested(
            requestId,
            OracleJob.Payout,
            abi.encodePacked(policyId, flightId, delayedHours, amount)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BenefitStatus} from "../benefits/BenefitStatus.sol";
import {BenefitName} from "../benefits/BenefitName.sol";
import {Errors} from "../constants/Errors.sol";

struct PolicyBenefitData {
    BenefitStatus status;
    uint64 claimedAmount;
}

struct Policy {
    bytes32 userHash;
    bytes32 productId;
    bytes32[] flights;
    mapping(BenefitName => PolicyBenefitData) benefitsData;
    mapping(bytes32 => uint256) pendingClaims;
}

struct PolicyInitArgs {
    bytes32 userHash;
    bytes32 productId;
}

library LibPolicy {
    function initialize(Policy storage self, PolicyInitArgs calldata args)
        internal
    {
        self.userHash = args.userHash;
        self.productId = args.productId;
    }

    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.userHash == 0;
    }

    function addFlight(Policy storage self, bytes32 flightId) internal {
        self.flights.push(flightId);
    }

    function hasFlight(Policy storage self, bytes32 flightId)
        internal
        view
        returns (bool)
    {
        uint256 len = self.flights.length;
        for (uint256 i = 0; i < len; i++) {
            if (flightId == self.flights[i]) {
                return true;
            }
        }
        return false;
    }

    function totalFlights(Policy storage self) internal view returns (uint256) {
        return self.flights.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from "../constants/Errors.sol";

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
    function addIfNotExists(
        PriorityQueue storage self,
        bytes32 id,
        uint256 priority
    ) internal {
        QueueData storage insertData = self.datas[id];
        // isEmpty
        if (insertData.priority != 0) {
            return;
        }

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
pragma solidity ^0.8.9;

import {BenefitName} from "../benefits/BenefitName.sol";
import {BenefitFlightDelay, LibBenefitFlightDelay} from "../benefits/LibBenefitFlightDelay.sol";
import {BenefitPersonalAccident, LibBenefitPersonalAccident} from "../benefits/LibBenefitPersonalAccident.sol";
import {BenefitBaggageDelay, LibBenefitBaggageDelay} from "../benefits/LibBenefitBaggageDelay.sol";
import {BenefitFlightPostponement, LibBenefitFlightPostponement} from "../benefits/LibBenefitFlightPostponement.sol";

import {AppStorage, LibAppStorage} from "../libraries/LibAppStorage.sol";

struct Product {
    BenefitName[] benefits;
    BenefitPersonalAccident benefitPersonalAccident;
    BenefitFlightDelay benefitFlightDelay;
    BenefitBaggageDelay benefitBaggageDelay;
    BenefitFlightPostponement benefitFlightPostponement;
}

library LibProduct {
    using LibBenefitPersonalAccident for BenefitPersonalAccident;
    using LibBenefitFlightDelay for BenefitFlightDelay;
    using LibBenefitBaggageDelay for BenefitBaggageDelay;
    using LibBenefitFlightPostponement for BenefitFlightPostponement;

    struct BenefitInitializeArgs {
        BenefitName name;
        bytes data;
    }

    function hasBenefit(bytes32 productId, BenefitName benefitName)
        internal
        view
        returns (bool)
    {
        AppStorage storage s = LibAppStorage.appStorage();

        uint256 len = s.products[productId].benefits.length;
        for (uint256 i = 0; i < len; i++) {
            if (s.products[productId].benefits[i] == benefitName) {
                return true;
            }
        }

        return false;
    }

    function initialize(
        Product storage self,
        BenefitInitializeArgs[] calldata benefits
    ) internal {
        for (uint256 i = 0; i < benefits.length; i++) {
            if (benefits[i].name == BenefitName.PersonalAccident) {
                self.benefitPersonalAccident.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightDelay) {
                self.benefitFlightDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.BaggageDelay) {
                self.benefitBaggageDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightPostponement) {
                self.benefitFlightPostponement.initialize(benefits[i].data);
            }

            self.benefits.push(benefits[i].name);
        }
    }

    function isEmpty(Product storage self) internal view returns (bool) {
        return self.benefitPersonalAccident.isEmpty();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibString {
    using LibString for string;

    function length(string memory self) internal pure returns (uint256) {
        return bytes(self).length;
    }

    function toBytes32(string memory self)
        internal
        pure
        returns (bytes32 result)
    {
        require(self.length() <= 32, "LibString: Length must be lower than 32");
        assembly {
            result := mload(add(self, 32))
        }
    }
}