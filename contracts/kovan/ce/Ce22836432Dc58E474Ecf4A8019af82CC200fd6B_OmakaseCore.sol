// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ClaimFacet} from "./modules/claim/ClaimFacet.sol";
import {FlightFacet} from "./modules/flight/FlightFacet.sol";
import {FlightPolicyFacet} from "./modules/flightPolicy/FlightPolicyFacet.sol";
import {KeeperFacet} from "./modules/keeper/KeeperFacet.sol";
import {OracleFacet} from "./modules/oracle/OracleFacet.sol";
import {OwnableFacet} from "./modules/ownable/OwnableFacet.sol";
import {PolicyFacet} from "./modules/policy/PolicyFacet.sol";
import {ProductFacet} from "./modules/product/ProductFacet.sol";
import {OracleStorage, LibOracleStorage} from "./modules/oracle/LibOracleStorage.sol";
import {AppStorage, LibAppStorage} from "./common/LibAppStorage.sol";

contract OmakaseCore is
    ClaimFacet,
    FlightFacet,
    FlightPolicyFacet,
    KeeperFacet,
    OracleFacet,
    OwnableFacet,
    PolicyFacet,
    ProductFacet
{
    constructor(address admin_, address oracle_) {
        AppStorage storage s = LibAppStorage.appStorage();

        s.admin = admin_;
        s.claimExpireTime = 30 days;

        OracleStorage storage oracleStorage = LibOracleStorage.oracleStorage();
        oracleStorage.oracle = oracle_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum Gender {
    Male,
    Female
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Policy} from "../modules/policy/Policy.sol";
import {Product} from "../modules/product/Product.sol";
import {Flight} from "../modules/flight/Flight.sol";

struct AppStorage {
    mapping(bytes32 => Policy) policies;
    mapping(bytes32 => Product) products;
    mapping(bytes32 => Flight) flights;
    uint256 totalPolicies;
    uint256 totalFlights;
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
pragma solidity ^0.8.10;

import {LibOracleService} from "../modules/oracle/LibOracleService.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";

abstract contract Modifiers {
    modifier onlyOracle() {
        LibOracleService.enforceCallerIsOracle();
        _;
    }

    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(msg.sender == s.admin, "Caller is not admin");
        _;
    }

    modifier oracleCallback(bytes32 requestId) {
        LibOracleService.handleOracleCallback(requestId);
        _;
    }
}

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
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs work on the contract. Executed by the keepers, via the registry.
     * @param performData is the data which was passed back from the checkData
     * simulation.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibBytes {
    function loopBytes32(bytes memory self, function(bytes32) func) internal {
        uint256 len = self.length / 32;
        bytes32 dataStartPos;
        bytes32 dataEndPos;
        assembly {
            dataStartPos := add(self, 32)
            dataEndPos := add(dataStartPos, mul(sub(len, 1), 32))
        }

        while (dataStartPos <= dataEndPos) {
            bytes32 item;
            assembly {
                item := mload(dataStartPos)
                dataStartPos := add(dataStartPos, 32)
            }

            func(item);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {Modifiers} from "../../common/Modifiers.sol";
import {BenefitName} from "../product/benefits/BenefitName.sol";
import {BenefitStatus} from "../product/benefits/BenefitStatus.sol";
import {Product, LibProduct} from "../product/Product.sol";
import {Policy, LibPolicy} from "../policy/Policy.sol";
import {LibFlightPolicyService} from "../flightPolicy/LibFlightPolicyService.sol";

contract ClaimFacet is Modifiers {
    using LibProduct for Product;
    using LibPolicy for Policy;

    event AdditionalPayout(
        bytes32 indexed policyId,
        bytes32 indexed requestId,
        BenefitName benefitName,
        uint64 amount
    );

    event ClaimExpireTimeChanged(uint64 previousTime, uint64 newTime);

    function getClaimedAmount(bytes32 policyId, BenefitName benefitName)
        external
        view
        returns (uint64)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.policies[policyId].claimedAmounts[benefitName];
    }

    function setClaimExpireTime(uint64 claimExpireTime) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        uint64 previousTime = s.claimExpireTime;
        s.claimExpireTime = claimExpireTime;

        emit ClaimExpireTimeChanged(previousTime, claimExpireTime);
    }

    function confirmProcessingClaim(bytes32 requestId, bytes32 policyId)
        external
        oracleCallback(requestId)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        s.policies[policyId].pendingClaims[requestId] = block.timestamp;
    }

    function completeClaim(
        bytes32 requestId,
        bytes32 policyId,
        bytes32 flightId,
        BenefitName benefitName,
        uint64 claimAmount,
        bool success
    ) external onlyOracle {
        AppStorage storage s = LibAppStorage.appStorage();
        Policy storage policy = s.policies[policyId];
        require(!policy.isEmpty(), "Invalid policy ID");
        require(policy.pendingClaims[requestId] != 0, "Unknown claim request");
        require(
            s.products[policy.productId].hasBenefit(benefitName),
            "Policy doesn't have the benefit"
        );

        if (
            !success ||
            block.timestamp >=
            (policy.pendingClaims[requestId] + s.claimExpireTime)
        ) {
            policy.claimedAmounts[BenefitName.FlightDelay] -= claimAmount;
            LibFlightPolicyService.setFlightPoliciesStatus(
                policyId,
                flightId,
                BenefitStatus.Expired
            );
        } else {
            LibFlightPolicyService.setFlightPoliciesStatus(
                policyId,
                flightId,
                BenefitStatus.Claimed
            );
        }

        delete policy.pendingClaims[requestId];
    }

    function addAdditionalPayout(
        bytes32 policyId,
        bytes32 requestId,
        BenefitName benefitName,
        uint64 additionalAmount
    ) external onlyOracle {
        AppStorage storage s = LibAppStorage.appStorage();
        Policy storage policy = s.policies[policyId];
        require(!policy.isEmpty(), "Invalid policy ID");
        require(
            s.products[policy.productId].hasBenefit(benefitName),
            "Policy doesn't have the benefit"
        );

        uint64 benefitMaximumAmount = 0;
        if (benefitName == BenefitName.FlightDelay) {
            benefitMaximumAmount = s
                .products[policy.productId]
                .benefitFlightDelay
                .maximumAmount;
        } else {
            revert("Benefit can't add any additional payout");
        }

        policy.claimedAmounts[BenefitName.FlightDelay] += additionalAmount;
        require(
            policy.claimedAmounts[BenefitName.FlightDelay] <=
                benefitMaximumAmount,
            "Invalid additional payout amount"
        );

        emit AdditionalPayout(
            policyId,
            requestId,
            benefitName,
            additionalAmount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error InvalidDepartureTime(uint64 departureTime);
error InvalidArrivalTime(uint64 arrivalTime);

struct Flight {
    uint64 scheduledDepartureTime;
    uint64 actualDepartureTime;
    uint64 nextCheck;
    uint256 idxInFlightsToCheck;
    bytes32[] policies; // starts at index 1
}

library LibFlight {
    function validateFlightData(
        uint64 scheduledDepartureTime,
        uint64 arrivalTime
    ) internal pure {
        if (scheduledDepartureTime == 0) {
            // revert InvalidDepartureTime(scheduledDepartureTime);
            revert("Invalid departure time");
        }
        if (arrivalTime == 0) {
            // revert InvalidArrivalTime(arrivalTime);
            revert("Invalid arrival time");
        }

        //
        // Disabled because of business reason
        //
        // require(
        //     block.timestamp < scheduledDepartureTime,
        //     "Flight already departed"
        // );
    }

    function initialize(Flight storage self, uint64 scheduledDepartureTime)
        internal
    {
        self.scheduledDepartureTime = scheduledDepartureTime;
        self.policies.push();
    }

    function isEmpty(Flight storage self) internal view returns (bool) {
        return self.scheduledDepartureTime == 0;
    }

    function addPolicy(Flight storage self, bytes32 policyId)
        internal
        returns (uint256)
    {
        self.policies.push(policyId);
        return self.policies.length - 1;
    }

    function removePolicy(Flight storage self, uint256 idx) internal {
        self.policies[idx] = self.policies[self.policies.length - 1];
        self.policies.pop();
    }

    function needCheck(Flight storage self) internal view returns (bool) {
        if (self.actualDepartureTime != 0) {
            return false;
        }

        // Gas eficient way to check if flight is valid
        // since `nextCheck` will always be assigned in creation
        // Otherwise, actualDepartureTime won't be zero
        uint64 nextCheck = self.nextCheck;
        if (nextCheck == 0) {
            revert("Unknown flight");
        }

        return block.timestamp > nextCheck;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Modifiers} from "../../common/Modifiers.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {LibFlightPolicyService} from "../flightPolicy/LibFlightPolicyService.sol";
import {Flight, LibFlight} from "./Flight.sol";
import {LibFlightsToCheck} from "./LibFlightsToCheck.sol";

contract FlightFacet is Modifiers {
    using LibFlight for Flight;

    event NewFlight(bytes32 indexed flightId);
    event FlightStatusUpdate(
        bytes32 requestId,
        bytes32 indexed flightId,
        bool departed,
        uint256 actualDepartureTime
    );

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.flights[flightId];
    }

    function hasFlight(bytes32 flightId) external view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return !s.flights[flightId].isEmpty();
    }

    function totalFlights() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.totalFlights;
    }

    function getFlightsToCheck() external pure returns (bytes32[] memory) {
        return LibFlightsToCheck.getArray();
    }

    function createFlight(
        bytes32 id,
        uint64 scheduledDepartureTime,
        uint64 arrivalTime
    ) external {
        AppStorage storage s = LibAppStorage.appStorage();

        require(id != 0, "Invalid flight ID");

        Flight storage flight = s.flights[id];
        require(flight.isEmpty(), "Flight already exists");

        LibFlight.validateFlightData(scheduledDepartureTime, arrivalTime);
        flight.initialize(scheduledDepartureTime);
        LibFlightsToCheck.insert(id, arrivalTime);

        s.totalFlights++;

        emit NewFlight(id);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        bool departed,
        uint256 actualDepartureTime
    ) external oracleCallback(requestId) {
        AppStorage storage s = LibAppStorage.appStorage();

        if (departed) {
            LibFlightPolicyService.evaluateDeparture(
                flightId,
                actualDepartureTime
            );
            s.flights[flightId].actualDepartureTime = uint64(
                actualDepartureTime
            );
        } else {
            LibFlightsToCheck.insert(
                flightId,
                uint64(block.timestamp + 2 hours)
            );
        }

        emit FlightStatusUpdate(
            requestId,
            flightId,
            departed,
            actualDepartureTime
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {Flight, LibFlight} from "../flight/Flight.sol";

library LibFlightsToCheck {
    using LibFlight for Flight;

    bytes32 constant DATA_STORAGE_POSITION =
        keccak256("omakase.flight.lib_flights_to_check.storage");

    function getArray() internal pure returns (bytes32[] storage arr) {
        bytes32 position = DATA_STORAGE_POSITION;
        assembly {
            arr.slot := position
        }
    }

    function insert(bytes32 flightId, uint64 timeToCheck) internal {
        Flight storage flight = LibAppStorage.appStorage().flights[flightId];
        bytes32[] storage arr = getArray();

        flight.nextCheck = timeToCheck;
        flight.idxInFlightsToCheck = arr.length;

        arr.push(flightId);
    }

    function remove(bytes32 flightId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32[] storage arr = getArray();

        uint256 idx = s.flights[flightId].idxInFlightsToCheck;
        delete s.flights[flightId].idxInFlightsToCheck;

        uint256 lastIdx = arr.length - 1;
        if (idx != lastIdx) {
            bytes32 replacementData = arr[lastIdx];
            arr[idx] = replacementData;
            s.flights[replacementData].idxInFlightsToCheck = idx;
        }

        arr.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LibPolicyService} from "../policy/LibPolicyService.sol";
import {CreatePolicyInput} from "../policy/LibPolicyService.sol";
import {Modifiers} from "../../common/Modifiers.sol";
import {LibFlightPolicyService} from "./LibFlightPolicyService.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {BenefitName} from "../product/benefits/BenefitName.sol";
import {Policy, LibPolicy} from "../policy/Policy.sol";
import {Flight, LibFlight} from "../flight/Flight.sol";
import {BenefitStatus} from "../product/benefits/BenefitStatus.sol";

error UnmatchedFlightsArrayLength(
    uint256 newFlightsLength,
    uint256 prevFlightsLength
);

contract FlightPolicyFacet is Modifiers {
    using LibPolicy for Policy;
    using LibFlight for Flight;

    event FlightPolicyAdded(bytes32 indexed policyId, bytes32 indexed flightId);

    event FlightPolicyRemoved(
        bytes32 indexed policyId,
        bytes32 indexed flightId
    );

    function getFlightBenefitStatus(bytes32 policyId, bytes32 flightId)
        external
        view
        returns (BenefitStatus)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.policies[policyId].flightPolicyStatuses[flightId];
    }

    function createPolicyWithFlights(
        bytes32 policyId,
        CreatePolicyInput calldata policyInput,
        bytes32[] calldata flightIds
    ) external onlyOracle {
        LibPolicyService.create(policyId, policyInput);
        _setFlightPolicies(policyId, flightIds);
    }

    function setFlightPolicies(bytes32 policyId, bytes32[] calldata flightIds)
        external
        onlyOracle
    {
        AppStorage storage s = LibAppStorage.appStorage();
        Policy storage policy = s.policies[policyId];

        require(!policy.isEmpty(), "Invalid policy ID");
        require(!policy.hasFlight, "Policy has flight already");

        _setFlightPolicies(policyId, flightIds);
    }

    function updateFlightPolicies(
        bytes32 policyId,
        bytes32[] calldata prevFlightIds,
        bytes32[] calldata newFlightIds
    ) external onlyOracle {
        AppStorage storage s = LibAppStorage.appStorage();
        require(!s.policies[policyId].isEmpty(), "Invalid policy");
        if (prevFlightIds.length != newFlightIds.length) {
            // revert UnmatchedFlightsArrayLength(
            //     prevFlightIds.length,
            //     newFlightIds.length
            // );
            revert("Unmatched flights array length");
        }

        for (uint256 i = 0; i < prevFlightIds.length; i++) {
            removeFlightPolicy(policyId, prevFlightIds[i]);
            addFlightPolicy(policyId, newFlightIds[i]);
        }
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function removeFlightPolicy(bytes32 policyId, bytes32 flightId) private {
        AppStorage storage s = LibAppStorage.appStorage();

        Policy storage policy = s.policies[policyId];
        Flight storage flight = s.flights[flightId];
        uint256 idxInFlight = policy.idxInFlight[flightId];

        require(
            flight.policies[idxInFlight] == policyId,
            "Invalid policy flight"
        );
        require(
            policy.flightPolicyStatuses[flightId] == BenefitStatus.Active,
            "Policy flight status in progress"
        );

        flight.removePolicy(idxInFlight);

        delete policy.idxInFlight[flightId];
        emit FlightPolicyRemoved(policyId, flightId);
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function addFlightPolicy(bytes32 policyId, bytes32 flightId) private {
        AppStorage storage s = LibAppStorage.appStorage();
        Flight storage flight = s.flights[flightId];

        require(!flight.isEmpty(), "Flight doesn't exists");

        s.policies[policyId].idxInFlight[flightId] = flight.addPolicy(policyId);

        emit FlightPolicyAdded(policyId, flightId);

        // Departed
        uint64 actualDepartureTime = flight.actualDepartureTime;
        if (actualDepartureTime != 0) {
            LibFlightPolicyService.evaluateDepartureForOnePolicy(
                flightId,
                actualDepartureTime,
                policyId
            );
        }
    }

    function _setFlightPolicies(bytes32 policyId, bytes32[] calldata flightIds)
        private
    {
        Policy storage policy = LibAppStorage.appStorage().policies[policyId];

        for (uint256 i = 0; i < flightIds.length; i++) {
            if (policy.hasSpecificFlight(flightIds[i])) {
                revert("FlightPolicyAlreadyExists()");
            }

            addFlightPolicy(policyId, flightIds[i]);
        }

        policy.hasFlight = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Flight, LibFlight} from "../flight/Flight.sol";
import {Policy, LibPolicy} from "../policy/Policy.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {BenefitStatus} from "../product/benefits/BenefitStatus.sol";
import {BenefitFlightDelay, LibBenefitFlightDelay} from "../product/benefits/LibBenefitFlightDelay.sol";
import {BenefitName} from "../product/benefits/BenefitName.sol";
import {LibOracleService} from "../oracle/LibOracleService.sol";

library LibFlightPolicyService {
    using LibFlight for Flight;
    using LibPolicy for Policy;
    using LibBenefitFlightDelay for BenefitFlightDelay;

    event FlightPolicyStatusUpdated(
        bytes32 indexed policyId,
        bytes32 indexed flightId,
        BenefitStatus status
    );

    function evaluateDeparture(bytes32 flightId, uint256 actualTime) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        Flight storage flight = s.flights[flightId];

        uint256 scheduledTime = flight.scheduledDepartureTime;

        if (actualTime <= scheduledTime) {
            return;
        }

        uint256 hourDifference = countHourDifference(scheduledTime, actualTime);

        uint256 nPolicies = flight.policies.length;
        for (uint256 i = 1; i < nPolicies; i++) {
            LibFlightPolicyService.claimBenefit(
                flight.policies[i],
                flightId,
                hourDifference
            );
        }
    }

    function evaluateDepartureForOnePolicy(
        bytes32 flightId,
        uint256 actualTime,
        bytes32 policyId
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        Flight storage flight = s.flights[flightId];

        uint256 scheduledTime = flight.scheduledDepartureTime;

        if (actualTime <= scheduledTime) {
            return;
        }

        uint256 hourDifference = countHourDifference(scheduledTime, actualTime);

        LibFlightPolicyService.claimBenefit(policyId, flightId, hourDifference);
    }

    function claimBenefit(
        bytes32 policyId,
        bytes32 flightId,
        uint256 hourDifference
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        Policy storage policy = s.policies[policyId];
        BenefitFlightDelay storage benefit = s
            .products[policy.productId]
            .benefitFlightDelay;

        if (
            policy.flightPolicyStatuses[flightId] != BenefitStatus.Active ||
            !eligibleForClaim(
                benefit,
                policy.claimedAmounts[BenefitName.FlightDelay],
                hourDifference
            )
        ) {
            setFlightPoliciesStatus(policyId, flightId, BenefitStatus.Expired);
            return;
        }

        uint256 indemnity = benefit.calculateIndemnity(
            policy.claimedAmounts[BenefitName.FlightDelay],
            hourDifference
        );
        policy.claimedAmounts[BenefitName.FlightDelay] += uint64(indemnity);
        setFlightPoliciesStatus(
            policyId,
            flightId,
            BenefitStatus.ClaimInProgress
        );

        LibOracleService.requestPayout(
            policyId,
            flightId,
            hourDifference,
            indemnity
        );
    }

    function setFlightPoliciesStatus(
        bytes32 policyId,
        bytes32 flightId,
        BenefitStatus status
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.policies[policyId].flightPolicyStatuses[flightId] = status;
        emit FlightPolicyStatusUpdated(policyId, flightId, status);
    }

    function eligibleForClaim(
        BenefitFlightDelay storage self,
        uint256 claimedAmount,
        uint256 hourDifference
    ) private view returns (bool) {
        if (claimedAmount >= self.maximumAmount) {
            return false;
        }

        return hourDifference >= self.delayInterval;
    }

    function countHourDifference(uint256 scheduledTime, uint256 actualTime)
        private
        pure
        returns (uint256)
    {
        return (actualTime - scheduledTime) / 1 hours;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {KeeperCompatibleInterface} from "../../dependencies/KeeperCompatibleInterface.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {LibOracleService} from "../oracle/LibOracleService.sol";
import {Flight, LibFlight} from "../flight/Flight.sol";
import "../../libraries/LibBytes.sol";
import {LibFlightsToCheck} from "../flight/LibFlightsToCheck.sol";

contract KeeperFacet is KeeperCompatibleInterface {
    using LibFlight for Flight;
    using LibBytes for bytes;

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        bytes32[] storage arr = LibFlightsToCheck.getArray();

        uint256 len = arr.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 flightId = arr[i];
            if (!s.flights[flightId].needCheck()) {
                continue;
            } else if (performData.length / 32 > 60) {
                break;
            }

            performData = abi.encodePacked(performData, flightId);
        }

        upkeepNeeded = performData.length >= 32;
    }

    function performUpkeep(bytes memory performData) external override {
        performData.loopBytes32(checkFlight);
    }

    function checkFlight(bytes32 flightId) private {
        AppStorage storage s = LibAppStorage.appStorage();
        Flight storage flight = s.flights[flightId];

        if (!flight.needCheck()) {
            return;
        }

        LibOracleService.requestStatusUpdate(flightId);
        LibFlightsToCheck.remove(flightId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {OracleJob} from "./OracleJob.sol";
import {OracleStorage, LibOracleStorage} from "./LibOracleStorage.sol";

library LibOracleService {
    event OracleRequested(bytes32 indexed requestId, OracleJob job, bytes data);
    event OracleFulfilled(bytes32 indexed requestId);

    function enforceCallerIsOracle() internal view {
        OracleStorage storage ds = LibOracleStorage.oracleStorage();
        require(msg.sender == ds.oracle, "Caller is not oracle");
    }

    function handleOracleCallback(bytes32 requestId) internal {
        OracleStorage storage ds = LibOracleStorage.oracleStorage();

        enforceCallerIsOracle();
        require(ds.pendingRequest[requestId] != 0, "Unknown oracle request");

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

    function createRequest() private returns (bytes32 requestId) {
        OracleStorage storage ds = LibOracleStorage.oracleStorage();

        ds.requestCount += 1;
        requestId = keccak256(abi.encodePacked(ds.requestCount));
        ds.pendingRequest[requestId] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {OracleJob} from "./OracleJob.sol";

struct OracleStorage {
    mapping(bytes32 => uint256) pendingRequest;
    uint256 requestCount;
    address oracle;
}

library LibOracleStorage {
    bytes32 constant ORACLE_STORAGE_POSITION =
        keccak256("omakase.lib_oracle.oracle_storage");

    function oracleStorage() internal pure returns (OracleStorage storage ds) {
        bytes32 position = ORACLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Modifiers} from "../../common/Modifiers.sol";
import {OracleStorage, LibOracleStorage} from "./LibOracleStorage.sol";

contract OracleFacet is Modifiers {
    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );

    function pendingRequest(bytes32 requestId) external view returns (uint256) {
        OracleStorage storage ds = LibOracleStorage.oracleStorage();
        return ds.pendingRequest[requestId];
    }

    function oracle() external view returns (address) {
        OracleStorage storage ds = LibOracleStorage.oracleStorage();
        return ds.oracle;
    }

    function setOracle(address _oracle) external onlyAdmin {
        OracleStorage storage ds = LibOracleStorage.oracleStorage();
        require(ds.oracle != address(0), "Invalid new oracle address");

        address oldOracle = ds.oracle;
        ds.oracle = _oracle;
        emit OracleChanged(oldOracle, _oracle);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum OracleJob {
    StatusUpdate,
    Payout
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {Modifiers} from "../../common/Modifiers.sol";

contract OwnableFacet is Modifiers {
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    function admin() external view returns (address) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.admin;
    }

    function setAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "Invalid new admin address");
        AppStorage storage s = LibAppStorage.appStorage();

        address oldAdmin = s.admin;
        s.admin = admin_;
        emit AdminChanged(oldAdmin, admin_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {Policy, LibPolicy} from "./Policy.sol";
import {Product, LibProduct} from "../product/Product.sol";

struct CreatePolicyInput {
    bytes32 userHash;
    bytes32 productId;
}

library LibPolicyService {
    using LibPolicy for Policy;
    using LibProduct for Product;

    event PolicyCreated(bytes32 indexed policyId);

    function create(bytes32 id, CreatePolicyInput calldata input) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(id != 0, "Invalid policy ID");
        require(!s.products[input.productId].isEmpty(), "Invalid product ID");
        require(input.userHash != 0, "Invalid user hash");

        Policy storage policy = s.policies[id];
        require(policy.isEmpty(), "Policy already exists");

        policy.initialize(input.userHash, input.productId);
        s.totalPolicies++;

        emit PolicyCreated(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BenefitStatus} from "../product/benefits/BenefitStatus.sol";
import {BenefitName} from "../product/benefits/BenefitName.sol";

struct Policy {
    bytes32 userHash;
    bytes32 productId;
    bool hasFlight;
    mapping(BenefitName => uint64) claimedAmounts;
    mapping(bytes32 => BenefitStatus) flightPolicyStatuses;
    mapping(bytes32 => uint256) pendingClaims;
    mapping(bytes32 => uint256) idxInFlight;
}

library LibPolicy {
    function initialize(
        Policy storage self,
        bytes32 userHash,
        bytes32 productId
    ) internal {
        self.userHash = userHash;
        self.productId = productId;
    }

    function isEmpty(Policy storage self) internal view returns (bool) {
        return self.userHash == 0;
    }

    function hasSpecificFlight(Policy storage self, bytes32 flightId)
        internal
        view
        returns (bool)
    {
        return self.idxInFlight[flightId] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LibPolicyService, CreatePolicyInput} from "./LibPolicyService.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {Gender} from "../../common/Gender.sol";
import {Modifiers} from "../../common/Modifiers.sol";
import {Policy, LibPolicy} from "../policy/Policy.sol";

contract PolicyFacet is Modifiers {
    using LibPolicy for Policy;

    function getPolicyUserHash(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.policies[policyId].userHash;
    }

    function getPolicyProductId(bytes32 policyId)
        external
        view
        returns (bytes32)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.policies[policyId].productId;
    }

    function createPolicy(bytes32 policyId, CreatePolicyInput calldata input)
        external
        onlyOracle
    {
        LibPolicyService.create(policyId, input);
    }

    function totalPolicies() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.totalPolicies;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BenefitName} from "./benefits/BenefitName.sol";
import {BenefitFlightDelay, LibBenefitFlightDelay} from "./benefits/LibBenefitFlightDelay.sol";
import {BenefitPersonalAccident, LibBenefitPersonalAccident} from "./benefits/LibBenefitPersonalAccident.sol";
import {BenefitBaggageDelay, LibBenefitBaggageDelay} from "./benefits/LibBenefitBaggageDelay.sol";
import {BenefitFlightPostponement, LibBenefitFlightPostponement} from "./benefits/LibBenefitFlightPostponement.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";

error DuplicateBenefit(BenefitName benefitName);

struct BenefitInitInput {
    BenefitName name;
    bytes data;
}

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

    function initialize(
        Product storage self,
        BenefitInitInput[] calldata benefits
    ) internal {
        for (uint256 i = 0; i < benefits.length; i++) {
            if (benefits[i].name == BenefitName.PersonalAccident) {
                if (!self.benefitPersonalAccident.isEmpty()) {
                    // revert DuplicateBenefit(benefits[i].name);
                    revert("DuplicateBenefit(0)");
                }

                self.benefitPersonalAccident.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightDelay) {
                if (!self.benefitFlightDelay.isEmpty()) {
                    // revert DuplicateBenefit(benefits[i].name);
                    revert("DuplicateBenefit(1)");
                }

                self.benefitFlightDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.BaggageDelay) {
                if (!self.benefitBaggageDelay.isEmpty()) {
                    // revert DuplicateBenefit(benefits[i].name);
                    revert("DuplicateBenefit(2)");
                }

                self.benefitBaggageDelay.initialize(benefits[i].data);
            } else if (benefits[i].name == BenefitName.FlightPostponement) {
                if (!self.benefitFlightPostponement.isEmpty()) {
                    // revert DuplicateBenefit(benefits[i].name);
                    revert("DuplicateBenefit(4)");
                }

                self.benefitFlightPostponement.initialize(benefits[i].data);
            } else if (
                benefits[i].name == BenefitName.TripCancellation
            ) {} else {
                revert("Unknown benefit name");
            }

            self.benefits.push(benefits[i].name);
        }
    }

    function hasBenefit(Product storage self, BenefitName benefitName)
        internal
        view
        returns (bool)
    {
        uint256 len = self.benefits.length;
        for (uint256 i = 0; i < len; i++) {
            if (self.benefits[i] == benefitName) {
                return true;
            }
        }

        return false;
    }

    function isEmpty(Product storage self) internal view returns (bool) {
        return self.benefitPersonalAccident.isEmpty();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Modifiers} from "../../common/Modifiers.sol";
import {AppStorage, LibAppStorage} from "../../common/LibAppStorage.sol";
import {BenefitName} from "./benefits/BenefitName.sol";
import {Product, LibProduct, BenefitInitInput} from "./Product.sol";
import {BenefitPersonalAccident, LibBenefitPersonalAccident} from "./benefits/LibBenefitPersonalAccident.sol";
import {BenefitFlightDelay, LibBenefitFlightDelay} from "./benefits/LibBenefitFlightDelay.sol";
import {BenefitBaggageDelay, LibBenefitBaggageDelay} from "./benefits/LibBenefitBaggageDelay.sol";
import {BenefitFlightPostponement, LibBenefitFlightPostponement} from "./benefits/LibBenefitFlightPostponement.sol";

error MissingBenefitPersonalAccident();

contract ProductFacet is Modifiers {
    using LibProduct for Product;
    using LibBenefitPersonalAccident for BenefitPersonalAccident;

    event NewProduct(bytes32 indexed productId, BenefitName[] benefits);

    function hasProduct(bytes32 productId) external view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return !s.products[productId].isEmpty();
    }

    function getBenefitPersonalAccident(bytes32 productId)
        external
        view
        returns (BenefitPersonalAccident memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.products[productId].benefitPersonalAccident;
    }

    function getBenefitFlightDelay(bytes32 productId)
        external
        view
        returns (BenefitFlightDelay memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.products[productId].benefitFlightDelay;
    }

    function getBenefitBaggageDelay(bytes32 productId)
        external
        view
        returns (BenefitBaggageDelay memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.products[productId].benefitBaggageDelay;
    }

    function getBenefitFlightPostponement(bytes32 productId)
        external
        view
        returns (BenefitFlightPostponement memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.products[productId].benefitFlightPostponement;
    }

    function getProductBenefits(bytes32 productId)
        external
        view
        returns (BenefitName[] memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.products[productId].benefits;
    }

    function createProduct(
        bytes32 productId,
        BenefitInitInput[] calldata benefits
    ) external onlyOracle {
        require(productId != 0, "Invalid product ID");

        AppStorage storage s = LibAppStorage.appStorage();
        Product storage product = s.products[productId];

        require(product.isEmpty(), "Product already exists");

        product.initialize(benefits);

        if (product.benefitPersonalAccident.isEmpty()) {
            // revert MissingBenefitPersonalAccident();
            revert("MissingBenefitPersonalAccident()");
        }

        emit NewProduct(productId, product.benefits);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum BenefitName {
    PersonalAccident,
    FlightDelay,
    BaggageDelay,
    TripCancellation,
    FlightPostponement
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum BenefitStatus {
    Active,
    ClaimInProgress,
    Claimed,
    Expired
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./errors/InvalidMaximumAmount.sol";

struct BenefitBaggageDelay {
    uint8 delayHour;
    uint64 maximumAmount;
}

library LibBenefitBaggageDelay {
    function initialize(BenefitBaggageDelay storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        uint8 delayHour;

        assembly {
            maximumAmount := mload(add(data, 8))
            delayHour := mload(add(data, 9))
        }

        require(delayHour > 0, "Invalid delay hour");
        if (maximumAmount == 0) {
            // revert InvalidMaximumAmount(maximumAmount);
            revert("InvalidMaximumAmount");
        }

        self.maximumAmount = maximumAmount;
        self.delayHour = delayHour;
    }

    function isEmpty(BenefitBaggageDelay storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./errors/InvalidMaximumAmount.sol";

struct BenefitFlightDelay {
    uint8 delayInterval;
    uint64 maximumAmount;
    uint64 amountPerInterval;
}

library LibBenefitFlightDelay {
    function initialize(BenefitFlightDelay storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        uint8 delayInterval;
        uint64 amountPerInterval;

        assembly {
            maximumAmount := mload(add(data, 8))
            delayInterval := mload(add(data, 9))
            amountPerInterval := mload(add(data, 17))
        }

        if (maximumAmount == 0) {
            // revert InvalidMaximumAmount(maximumAmount);
            revert("InvalidMaximumAmount");
        }
        require(delayInterval > 0, "Invalid delay interval");
        require(amountPerInterval > 0, "Invalid amount per interval");

        self.maximumAmount = uint64(maximumAmount);
        self.delayInterval = uint8(delayInterval);
        self.amountPerInterval = uint64(amountPerInterval);
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

    function isEmpty(BenefitFlightDelay storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./errors/InvalidMaximumAmount.sol";

struct BenefitFlightPostponement {
    uint64 maximumAmount;
}

library LibBenefitFlightPostponement {
    function initialize(
        BenefitFlightPostponement storage self,
        bytes memory data
    ) internal {
        uint64 maximumAmount;
        assembly {
            maximumAmount := mload(add(data, 8))
        }

        if (maximumAmount == 0) {
            // revert InvalidMaximumAmount(maximumAmount);
            revert("InvalidMaximumAmount");
        }

        self.maximumAmount = maximumAmount;
    }

    function isEmpty(BenefitFlightPostponement storage self)
        internal
        view
        returns (bool)
    {
        return self.maximumAmount == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./errors/InvalidMaximumAmount.sol";

struct BenefitPersonalAccident {
    uint64 maximumAmount;
}

library LibBenefitPersonalAccident {
    function initialize(BenefitPersonalAccident storage self, bytes memory data)
        internal
    {
        uint64 maximumAmount;
        assembly {
            maximumAmount := mload(add(data, 8))
        }

        if (maximumAmount == 0) {
            // revert InvalidMaximumAmount(maximumAmount);
            revert("InvalidMaximumAmount");
        }

        self.maximumAmount = maximumAmount;
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
pragma solidity ^0.8.10;

error InvalidMaximumAmount(uint256 maximumAmount);