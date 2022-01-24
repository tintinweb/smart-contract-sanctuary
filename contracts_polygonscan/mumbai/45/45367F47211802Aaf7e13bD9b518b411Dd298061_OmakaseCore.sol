// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./facets/AccessControlFacet.sol";
import "./facets/ClaimFacet.sol";
import "./facets/DataFacet.sol";
import "./facets/FlightStatusFacet.sol";
import "./facets/PolicyCreationFacet.sol";
import "./facets/ProductCreationFacet.sol";

contract OmakaseCore is
    AccessControlFacet,
    ClaimFacet,
    DataFacet,
    FlightStatusFacet,
    PolicyCreationFacet,
    ProductCreationFacet
{
    constructor(address admin_, address oracle_) {
        s.admin = admin_;
        s.claimExpireTime = 30 days;
        s.oracle = oracle_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibAppStorage.sol";

abstract contract InheritedStorage {
    AppStorage internal s;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibOracle.sol";
import "../libraries/LibAppStorage.sol";

abstract contract Modifiers {
    modifier onlyOracle() {
        LibOracle.enforceCallerIsOracle();
        _;
    }

    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(msg.sender == s.admin, "Caller is not admin");
        _;
    }

    modifier oracleCallback(bytes32 requestId) {
        LibOracle.handleOracleCallback(requestId);
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

enum OracleJob {
    StatusUpdate,
    Payout
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error InvalidMaximumAmount(uint256 maximumAmount);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/LibAppStorage.sol";

contract AccessControlFacet is Modifiers, InheritedStorage {
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event OracleChanged(
        address indexed previousOracle,
        address indexed newOracle
    );

    function oracle() external view returns (address) {
        return s.oracle;
    }

    function setOracle(address _oracle) external onlyAdmin {
        require(_oracle != address(0), "Invalid new oracle address");

        address oldOracle = s.oracle;
        s.oracle = _oracle;
        emit OracleChanged(oldOracle, _oracle);
    }

    function admin() external view returns (address) {
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

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Claim.sol";
import "../libraries/LibFlightPolicy.sol";

contract ClaimFacet is Modifiers, InheritedStorage {
    using LibProduct for Product;
    using LibPolicy for Policy;
    using LibClaim for Claim;

    event AdditionalPayout(
        bytes32 indexed policyId,
        bytes32 indexed requestId,
        BenefitName benefitName,
        uint64 amount
    );

    event ClaimExpireTimeChanged(uint64 previousTime, uint64 newTime);

    function setClaimExpireTime(uint64 claimExpireTime) external onlyAdmin {
        uint64 previousTime = s.claimExpireTime;
        s.claimExpireTime = claimExpireTime;

        emit ClaimExpireTimeChanged(previousTime, claimExpireTime);
    }

    function completeClaim(
        bytes32 requestId,
        bytes32 policyId,
        bytes32 flightId,
        BenefitName benefitName
    ) external oracleCallback(requestId) {
        Policy storage policy = s.policies[policyId];
        Claim storage claim = policy.pendingClaims[requestId];

        require(!policy.isEmpty(), "Invalid policy ID");
        require(!claim.isEmpty(), "Unknown claim request");
        require(
            s.products[policy.productId].hasBenefit(benefitName),
            "Policy doesn't have the benefit"
        );

        if (claim.isExpired()) {
            policy.claimedAmounts[BenefitName.FlightDelay] -= claim.amount;
            LibFlightPolicy.setFlightPoliciesStatus(
                policyId,
                flightId,
                BenefitStatus.Expired
            );
        } else {
            LibFlightPolicy.setFlightPoliciesStatus(
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

import "../common/InheritedStorage.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/entities/BenefitPersonalAccident.sol";
import "../libraries/entities/BenefitFlightDelay.sol";
import "../libraries/entities/BenefitBaggageDelay.sol";
import "../libraries/entities/BenefitFlightPostponement.sol";
import "../libraries/LibFlightsToCheck.sol";

contract DataFacet is InheritedStorage {
    using LibProduct for Product;
    using LibFlight for Flight;

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

    /*-------------------------------------------------------------------------*/
    // Oracle

    function pendingRequest(bytes32 requestId) external view returns (uint256) {
        return s.pendingRequest[requestId];
    }

    /*-------------------------------------------------------------------------*/
    // Policy

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

    function totalPolicies() external view returns (uint256) {
        return s.totalPolicies;
    }

    function getFlightBenefitStatus(bytes32 policyId, bytes32 flightId)
        external
        view
        returns (BenefitStatus)
    {
        return s.policies[policyId].flightPolicyStatuses[flightId];
    }

    /*-------------------------------------------------------------------------*/
    // Claim

    function getClaimedAmount(bytes32 policyId, BenefitName benefitName)
        external
        view
        returns (uint64)
    {
        return s.policies[policyId].claimedAmounts[benefitName];
    }

    /*-------------------------------------------------------------------------*/
    // Flight

    function getFlight(bytes32 flightId) external view returns (Flight memory) {
        return s.flights[flightId];
    }

    function hasFlight(bytes32 flightId) external view returns (bool) {
        return !s.flights[flightId].isEmpty();
    }

    function totalFlights() external view returns (uint256) {
        return s.totalFlights;
    }

    function getFlightsToCheck() external pure returns (bytes32[] memory) {
        return LibFlightsToCheck.getArray();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../dependencies/KeeperCompatibleInterface.sol";
import "../libraries/LibFlightsToCheck.sol";
import "../libraries/LibOracle.sol";
import "../libraries/helpers/LibBytes.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/LibFlightPolicy.sol";

contract FlightStatusFacet is
    Modifiers,
    InheritedStorage,
    KeeperCompatibleInterface
{
    using LibFlight for Flight;
    using LibBytes for bytes;

    event FlightStatusUpdate(
        bytes32 requestId,
        bytes32 indexed flightId,
        bool departed,
        uint256 actualDepartureTime
    );

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
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
        Flight storage flight = s.flights[flightId];

        if (!flight.needCheck()) {
            return;
        }

        LibOracle.requestStatusUpdate(flightId);
        LibFlightsToCheck.remove(flightId);
    }

    function updateFlightStatus(
        bytes32 requestId,
        bytes32 flightId,
        bool departed,
        uint256 actualDepartureTime
    ) external oracleCallback(requestId) {
        if (departed) {
            LibFlightPolicy.evaluateDeparture(flightId, actualDepartureTime);
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

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";
import "../libraries/LibFlightPolicy.sol";
import "../libraries/LibFlightsToCheck.sol";

struct CreatePolicyInput {
    bytes32 userHash;
    bytes32 productId;
}

struct CreateFlightInput {
    bytes32 id;
    uint64 scheduledDepartureTime;
    uint64 arrivalTime;
}

contract PolicyCreationFacet is Modifiers, InheritedStorage {
    using LibPolicy for Policy;
    using LibProduct for Product;
    using LibFlight for Flight;

    event PolicyCreated(bytes32 indexed policyId);
    event NewFlight(bytes32 indexed flightId);

    event FlightPolicyAdded(bytes32 indexed policyId, bytes32 indexed flightId);
    event FlightPolicyRemoved(
        bytes32 indexed policyId,
        bytes32 indexed flightId
    );

    function createPolicy(bytes32 policyId, CreatePolicyInput calldata input)
        external
        onlyOracle
    {
        _createPolicy(policyId, input);
    }

    function createPolicyWithFlights(
        bytes32 policyId,
        CreatePolicyInput calldata policyInput,
        CreateFlightInput[] calldata flightsInput
    ) external onlyOracle {
        _createPolicy(policyId, policyInput);
        _setFlightPolicies(policyId, flightsInput);
    }

    function setFlightPolicies(
        bytes32 policyId,
        CreateFlightInput[] calldata flightsInput
    ) external onlyOracle {
        Policy storage policy = s.policies[policyId];

        require(!policy.isEmpty(), "Invalid policy ID");
        require(!policy.hasFlight, "Policy has flight already");

        _setFlightPolicies(policyId, flightsInput);
    }

    function updateFlightPolicies(
        bytes32 policyId,
        bytes32[] calldata prevFlightIds,
        CreateFlightInput[] calldata newFlightsInput
    ) external onlyOracle {
        require(!s.policies[policyId].isEmpty(), "Invalid policy");
        if (prevFlightIds.length != newFlightsInput.length) {
            // revert UnmatchedFlightsArrayLength(
            //     prevFlightIds.length,
            //     newFlightIds.length
            // );
            revert("Unmatched flights array length");
        }

        for (uint256 i = 0; i < prevFlightIds.length; i++) {
            removeFlightPolicy(policyId, prevFlightIds[i]);
            addFlightPolicy(policyId, newFlightsInput[i]);
        }
    }

    function _createPolicy(bytes32 id, CreatePolicyInput calldata input)
        private
    {
        require(id != 0, "Invalid policy ID");
        require(!s.products[input.productId].isEmpty(), "Invalid product ID");
        require(input.userHash != 0, "Invalid user hash");

        Policy storage policy = s.policies[id];
        require(policy.isEmpty(), "Policy already exists");

        policy.initialize(input.userHash, input.productId);
        s.totalPolicies++;

        emit PolicyCreated(id);
    }

    function _setFlightPolicies(
        bytes32 policyId,
        CreateFlightInput[] calldata flightsInput
    ) private {
        Policy storage policy = s.policies[policyId];

        for (uint256 i = 0; i < flightsInput.length; i++) {
            if (policy.hasSpecificFlight(flightsInput[i].id)) {
                revert("FlightPolicyAlreadyExists()");
            }

            addFlightPolicy(policyId, flightsInput[i]);
        }

        policy.hasFlight = true;
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function addFlightPolicy(
        bytes32 policyId,
        CreateFlightInput calldata flightInput
    ) private {
        Flight storage flight = s.flights[flightInput.id];
        if (flight.isEmpty()) {
            createFlight(
                flightInput.id,
                flightInput.scheduledDepartureTime,
                flightInput.arrivalTime
            );
        }

        s.policies[policyId].idxInFlight[flightInput.id] = flight.addPolicy(
            policyId
        );

        emit FlightPolicyAdded(policyId, flightInput.id);

        // Departed
        uint64 actualDepartureTime = flight.actualDepartureTime;
        if (actualDepartureTime != 0) {
            LibFlightPolicy.evaluateDeparture(
                flightInput.id,
                actualDepartureTime
            );
        }
    }

    /**
     * @dev Flight is expected to be empty
     */
    function createFlight(
        bytes32 id,
        uint64 scheduledscheduledDepartureTime,
        uint64 arrivalTime
    ) private {
        require(id != 0, "Invalid flight ID");

        Flight storage flight = s.flights[id];

        LibFlight.validateFlightData(
            scheduledscheduledDepartureTime,
            arrivalTime
        );
        flight.initialize(scheduledscheduledDepartureTime);
        LibFlightsToCheck.insert(id, arrivalTime);

        s.totalFlights++;

        emit NewFlight(id);
    }

    /**
     * @dev PolicyId is expected to be valid
     */
    function removeFlightPolicy(bytes32 policyId, bytes32 flightId) private {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../common/Modifiers.sol";
import "../common/InheritedStorage.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/BenefitPersonalAccident.sol";

error MissingBenefitPersonalAccident();

contract ProductCreationFacet is Modifiers, InheritedStorage {
    using LibProduct for Product;
    using LibBenefitPersonalAccident for BenefitPersonalAccident;

    event NewProduct(bytes32 indexed productId, BenefitName[] benefits);

    function createProduct(
        bytes32 productId,
        BenefitInitInput[] calldata benefits
    ) external onlyOracle {
        require(productId != 0, "Invalid product ID");

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

import "../libraries/entities/Policy.sol";
import "../libraries/entities/Product.sol";
import "../libraries/entities/Flight.sol";

struct AppStorage {
    mapping(bytes32 => Policy) policies;
    mapping(bytes32 => Product) products;
    mapping(bytes32 => Flight) flights;
    uint256 totalPolicies;
    uint256 totalFlights;
    address admin;
    uint64 claimExpireTime;
    // Oracle
    mapping(bytes32 => uint256) pendingRequest;
    uint256 requestCount;
    address oracle;
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

import "./LibAppStorage.sol";
import "./LibOracle.sol";
import "./entities/Flight.sol";
import "./entities/Policy.sol";
import "./entities/BenefitFlightDelay.sol";
import "../enums/BenefitStatus.sol";
import "../enums/BenefitName.sol";

library LibFlightPolicy {
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

        uint256 hourDifference = (actualTime - scheduledTime) / 1 hours;

        uint256 nPolicies = flight.policies.length;
        for (uint256 i = 1; i < nPolicies; i++) {
            LibFlightPolicy.claimBenefit(
                flight.policies[i],
                flightId,
                hourDifference
            );
        }
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

        uint64 indemnity = uint64(
            benefit.calculateIndemnity(
                policy.claimedAmounts[BenefitName.FlightDelay],
                hourDifference
            )
        );
        setFlightPoliciesStatus(
            policyId,
            flightId,
            BenefitStatus.ClaimInProgress
        );

        bytes32 claimId = LibOracle.requestPayout(
            policyId,
            flightId,
            hourDifference,
            indemnity
        );
        policy.createPendingClaim(claimId, BenefitName.FlightDelay, indemnity);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../libraries/LibAppStorage.sol";
import "./entities/Flight.sol";

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

import "../enums/OracleJob.sol";
import "./LibAppStorage.sol";

library LibOracle {
    event OracleRequested(bytes32 indexed requestId, OracleJob job, bytes data);
    event OracleFulfilled(bytes32 indexed requestId);

    function enforceCallerIsOracle() internal view {
        AppStorage storage s = LibAppStorage.appStorage();
        require(msg.sender == s.oracle, "Caller is not oracle");
    }

    function handleOracleCallback(bytes32 requestId) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        enforceCallerIsOracle();
        require(s.pendingRequest[requestId] != 0, "Unknown oracle request");

        emit OracleFulfilled(requestId);
        delete s.pendingRequest[requestId];
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
    ) internal returns (bytes32 requestId) {
        requestId = createRequest();

        emit OracleRequested(
            requestId,
            OracleJob.Payout,
            abi.encodePacked(policyId, flightId, delayedHours, amount)
        );
    }

    function createRequest() private returns (bytes32 requestId) {
        AppStorage storage s = LibAppStorage.appStorage();

        s.requestCount += 1;
        requestId = keccak256(abi.encodePacked(s.requestCount));
        s.pendingRequest[requestId] = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../errors/InvalidMaximumAmount.sol";

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

import "../../errors/InvalidMaximumAmount.sol";

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

import "../../errors/InvalidMaximumAmount.sol";

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

import "../../errors/InvalidMaximumAmount.sol";

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

import "../LibAppStorage.sol";

struct Claim {
    uint64 amount;
    uint64 createdAt;
}

library LibClaim {
    function isEmpty(Claim storage self) internal view returns (bool) {
        return self.createdAt == 0;
    }

    function isExpired(Claim storage self) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return block.timestamp >= (self.createdAt + s.claimExpireTime);
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

import "../../enums/BenefitStatus.sol";
import "../../enums/BenefitName.sol";
import "./Claim.sol";

struct Policy {
    bytes32 userHash;
    bytes32 productId;
    bool hasFlight;
    mapping(BenefitName => uint64) claimedAmounts;
    mapping(bytes32 => BenefitStatus) flightPolicyStatuses;
    mapping(bytes32 => Claim) pendingClaims;
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

    function createPendingClaim(
        Policy storage self,
        bytes32 claimId,
        BenefitName benefit,
        uint64 amount
    ) internal {
        self.claimedAmounts[benefit] += amount;
        self.pendingClaims[claimId] = Claim({
            amount: amount,
            createdAt: uint64(block.timestamp)
        });
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

import "../../enums/BenefitName.sol";
import "./BenefitFlightDelay.sol";
import "./BenefitPersonalAccident.sol";
import "./BenefitBaggageDelay.sol";
import "./BenefitFlightPostponement.sol";
import "../LibAppStorage.sol";

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