// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../racers/Racer.sol";
import "./Race.sol";
import "./KeeperInterface.sol";

contract GameLoop is KeeperCompatibleInterface {
    modifier onlyManager() {
        require(manager == msg.sender, "Only callable by manager");
        _;
    }

    address public manager;
    address public raceContract;

    mapping(uint256 => bool) public registered; // registered[raceID] returns whether registered or not
    mapping(uint256 => uint256) public registeredIndex; // registeredIndex[raceID] saves index within registeredRaces
    uint256[] public registeredRaces; // all races to be updated on performUpkeep
    uint256[] public openSlots = [0];

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    uint256 public maxRaces;
    uint256 public totalRaces;

    constructor(uint256 updateInterval, address raceContractAddress) {
        raceContract = raceContractAddress;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        manager = msg.sender;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        //TODO:
        // ensure seeds have been sent to unhash hashed moves before performing upkeep
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
        //performData = abi.encode(1235,24,13);
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;

        Race r = Race(raceContract);
        for (uint256 i = 0; i < registeredRaces.length; i++) {
            r.startUpdates(registeredRaces[i]);
        }
    }

    function register(uint256 raceID) public {
        require(maxRaces > totalRaces, "Maximum races registered");
        require(!registered[raceID], "Race is already registered");
        require(
            Race(raceContract).getCoordinator(raceID) == msg.sender,
            "only race coordinator can register race"
        );

        if (openSlots.length > 0) {
            // get last open slot
            uint256 availableSlot = openSlots[(openSlots.length - 1)];

            // instert race into slot
            if (registeredRaces.length > 0) {
                registeredRaces[availableSlot] = raceID;
            } else {
                registeredRaces.push(raceID);
            }
            registeredIndex[raceID] = availableSlot;

            // remove last slot from array
            openSlots.pop();
        } else {
            uint256 availableSlot = registeredRaces.length;
            registeredRaces.push(raceID);
            registeredIndex[raceID] = availableSlot;
        }

        registered[raceID] = true;
        totalRaces++;
    }

    function getOpenSlots() public view returns (uint256) {
        return openSlots.length;
    }

    function deregister(uint256 raceID) public {
        require(
            Race(raceContract).getCoordinator(raceID) == msg.sender,
            "only race coordinator can deregister race"
        );
        require(registered[raceID], "Race not registered");
        uint256 index = registeredIndex[raceID];
        registeredIndex[raceID] = 0;
        delete registeredRaces[index];
        openSlots.push(index);
        registered[raceID] = false;
        totalRaces--;
    }

    function setMaxRaces(uint256 _maxRaces) public onlyManager {
        maxRaces = _maxRaces;
    }

    // override for emergency cancellation, should not be called unless absolutely necessary
    function deregisterRace(uint256 raceID) public onlyManager {
        require(registered[raceID], "Race not registered");
        uint256 index = registeredIndex[raceID];
        registeredIndex[raceID] = 0;
        delete registeredRaces[index];
        openSlots.push(index);
        registered[raceID] = false;
        totalRaces--;
    }

    function progressLoop() public onlyManager {
        // force the loop forward if something happens with keeper
        lastTimeStamp = block.timestamp;
        Race r = Race(raceContract);
        for (uint256 i = 0; i < registeredRaces.length; i++) {
            r.startUpdates(registeredRaces[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../polygon/tunnel/FxBaseChildTunnel.sol";

contract WrappedRacerRegistryChild is
    AccessControlEnumerable,
    FxBaseChildTunnel
{
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    // _isRegistered[NFT Address][NFT ID]
    mapping(address => mapping(uint256 => bool)) private _isRegistered;

    uint256 public latestStateId;
    address public latestRootMessageSender;
    bytes public latestData;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        latestStateId = stateId;
        latestRootMessageSender = sender;
        latestData = data;
    }

    function sendMessageToRoot(bytes memory message) public {
        _sendMessageToRoot(message);
    }

    function addRegistrar(address registrarAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(REGISTRAR_ROLE, registrarAddress);
    }

    function isRegistered(address nftContractAddress, uint256 nftId)
        public
        view
        returns (bool)
    {
        return _isRegistered[nftContractAddress][nftId];
    }

    function registerRacer(address nftAddress, uint256 nftId)
        public
        onlyRole(REGISTRAR_ROLE)
    {
        _isRegistered[nftAddress][nftId] = true;
    }

    function deregisterRacer(address nftAddress, uint256 nftId)
        public
        onlyRole(REGISTRAR_ROLE)
    {
        _isRegistered[nftAddress][nftId] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library RacerTokenUtilities {
    using SafeMath for uint256;

    function mapValuesToPool3(
        uint256 poolPoints,
        uint256 input1,
        uint256 input2,
        uint256 input3
    )
        public
        pure
        returns (
            uint256 poolValue1,
            uint256 poolValue2,
            uint256 poolValue3
        )
    {
        uint256 inputTotal = input1.add(input2).add(input3);
        uint256 multiplier = 10000;

        // Pool Values * multiplier for precision comparison //
        uint256 pv1 = ((poolPoints * (input1 * multiplier)) / inputTotal);
        uint256 pv2 = ((poolPoints * (input2 * multiplier)) / inputTotal);
        uint256 pv3 = ((poolPoints * (input3 * multiplier)) / inputTotal);

        // final values minus leftovers
        poolValue1 = pv1 / multiplier;
        poolValue2 = pv2 / multiplier;
        poolValue3 = pv3 / multiplier;

        uint256 dif = diff(poolPoints, poolValue1, poolValue2, poolValue3);

        if (dif != 0) {
            // apply leftover points to pools
            if (pv1 == pv2 && pv2 == pv3) {
                if (dif == 3) {
                    poolValue1 += 1;
                    poolValue2 += 1;
                    poolValue3 += 1;
                } else if (dif == 2) {
                    poolValue1 += 1;
                    poolValue2 += 1;
                } else {
                    poolValue1 += 1;
                }
            } else if (pv1 != pv2 && pv2 != pv3) {
                uint256[3] memory poolOrder = sort3([pv1, pv2, pv3]);
                for (uint256 i = 0; i < dif; i++) {
                    if (poolOrder[i] == pv1) {
                        poolValue1 += 1;
                    } else if (poolOrder[i] == pv2) {
                        poolValue2 += 1;
                    } else if (poolOrder[i] == pv3) {
                        poolValue3 += 1;
                    }
                }
            } else if (pv1 == pv2 || pv1 == pv3 || pv2 == pv3) {
                if (pv1 == pv2) {
                    if (dif == 3) {
                        poolValue1 += 2;
                        poolValue2 += 1;
                    } else if (dif == 2) {
                        poolValue1 += 1;
                        poolValue2 += 1;
                    } else {
                        poolValue1 += 1;
                    }
                } else if (pv1 == pv3) {
                    if (dif == 3) {
                        poolValue1 += 2;
                        poolValue3 += 1;
                    } else if (dif == 2) {
                        poolValue1 += 1;
                        poolValue3 += 1;
                    } else {
                        poolValue1 += 1;
                    }
                } else if (pv2 == pv3) {
                    if (dif == 3) {
                        poolValue2 += 2;
                        poolValue3 += 1;
                    } else if (dif == 2) {
                        poolValue2 += 1;
                        poolValue3 += 1;
                    } else {
                        poolValue2 += 1;
                    }
                }
            }
        }
    }

    function diff(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) public pure returns (uint256) {
        if (a >= (b + c + d)) {
            return a - b - c - d;
        } else {
            return 0;
        }
    }

    function sort3(uint256[3] memory values)
        public
        pure
        returns (uint256[3] memory sortedValues)
    {
        if (values[0] > values[1]) {
            sortedValues[1] = values[0];
            sortedValues[0] = values[1];
        } else {
            sortedValues[0] = values[0];
            sortedValues[1] = values[1];
        }
        if (sortedValues[1] > values[2]) {
            sortedValues[2] = sortedValues[1];
            sortedValues[1] = values[2];
        } else {
            sortedValues[2] = values[2];
        }
        if (sortedValues[0] > sortedValues[1]) {
            uint256 holding = sortedValues[1];
            sortedValues[1] = sortedValues[0];
            sortedValues[0] = holding;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../libraries/Utilities.sol";
import "./RacerTokenUtilities.sol";
import "./RacerChild.sol";

contract RacerData is VRFConsumerBase, AccessControlEnumerable {
    RacerChild RACER_CHILD;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256[] public randomSeeds;
    uint256[] public seedStarts; // correlate with randomSeeds, i.e. randomSeed[i] is valid starting from tokenID seedStarts[i]
    bytes32[] public requestIds;
    uint256 constant _totalAttributes = 16;

    uint256 constant POOL_POINTS = 12;

    /*
    DNA Digits: 
    0,1 = Vehicle
    2,3 = Racer
    4,5 = Wheels 
    6,7 = Goggles
    8,9 = Hat
    10,11 = Side Attachment,
    12,13 = Background,
    14,15 = WheelsColor,
    16,17 = VehicleColor,
    18,19 = RacerColor,
    20,21 = GogglesColor,
    22,23 = HatColor,
    24,25 = SideAttachmentColor,
    26,27 = TopSpeed,
    28,29 = Handling,
    30,31 = Acceleration
    */

    enum Attribute {
        Vehicle,
        Racer,
        Wheels,
        Goggles,
        Hat,
        SideAttachment,
        Background,
        WheelsColor,
        VehicleColor,
        RacerColor,
        GogglesColor,
        HatColor,
        SideAttachmentColor,
        TopSpeed,
        Acceleration,
        Handling
    }

    constructor(
        address _racerChildAddress,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        RACER_CHILD = RacerChild(_racerChildAddress);
        keyHash = _keyHash;
        fee = _fee;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function requestNewSeed()
        public
        onlyRole(MANAGER_ROLE)
        returns (bytes32 requestId)
    {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestId = requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        requestIds.push(requestId);
        randomSeeds.push(randomness);
        if (seedStarts.length == 0) {
            seedStarts.push(0);
        } else {
            uint256 nextID = RACER_CHILD.nextTokenId();
            seedStarts.push(nextID);
        }
    }

    function withdrawLinkTo(address toAddress, uint256 amount)
        public
        onlyRole(MANAGER_ROLE)
    {
        if (amount == 0) {
            //withdraw all link
            LINK.transfer(toAddress, LINK.balanceOf(address(this)));
        } else {
            LINK.transfer(toAddress, amount);
        }
    }

    function getDNA(uint256 tokenID) public view returns (uint256 dna) {
        uint256 existingDNA = RACER_CHILD.getDNA(tokenID);
        if (existingDNA != 0) {
            dna = existingDNA;
        } else {
            // combine seed + ID and take mod # factors for DNA
            uint256 dnaBase = uint256(
                keccak256(abi.encode(seedForId(tokenID), tokenID))
            );
            uint256 modValue = 10**(_totalAttributes * 2) + 1;
            dna = dnaBase % modValue;
            if (dna == 0) {
                dna = 1;
            }
            while (dna < 10**((_totalAttributes * 2) - 1)) {
                dna = dna * 10;
            }
        }
    }

    function seedForId(uint256 tokenID) public view returns (uint256) {
        // this will fail if not at least one seedStart / seed in
        require(
            seedStarts.length > 0 && seedStarts.length == randomSeeds.length,
            "seed starts & seeds length mismatch or null"
        );
        uint256 seedIndex = 0;
        for (uint256 i = seedStarts.length - 1; i > 0; i--) {
            if (tokenID >= seedStarts[i]) {
                seedIndex = i;
                break;
            }
        }
        return randomSeeds[seedIndex];
    }

    function getDNAString(uint256 tokenID)
        public
        view
        returns (string memory dnaString)
    {
        dnaString = Utilities.uintToString(getDNA(tokenID));
        if (Utilities.stringLength(dnaString) < (_totalAttributes * 2)) {
            uint256 remainingDigits = (_totalAttributes * 2) -
                Utilities.stringLength(dnaString);
            while (remainingDigits > 0) {
                dnaString = string(abi.encodePacked(dnaString, "0"));
                remainingDigits--;
            }
        }
    }

    function attributeDescriptionFromValue(Attribute a, uint256 attributeValue)
        public
        pure
        returns (string memory description)
    {
        if (a == Attribute.Vehicle) {
            description = vehicleDescription(attributeValue);
        } else if (a == Attribute.Racer) {
            description = racerDescription(attributeValue);
        } else if (a == Attribute.Wheels) {
            description = wheelsDescription(attributeValue);
        } else if (a == Attribute.Goggles) {
            description = gogglesDescription(attributeValue);
        } else if (a == Attribute.Hat) {
            description = hatDescription(attributeValue);
        } else if (a == Attribute.SideAttachment) {
            description = sideAttachmentDescription(attributeValue);
        } else if (a == Attribute.Background) {
            description = backgroundDescription(attributeValue);
        } else if (a == Attribute.WheelsColor) {
            description = wheelsColorDescription(attributeValue);
        } else if (a == Attribute.VehicleColor) {
            description = vehicleColorDescription(attributeValue);
        } else if (a == Attribute.RacerColor) {
            description = racerColorDescription(attributeValue);
        } else if (a == Attribute.GogglesColor) {
            description = gogglesColorDescription(attributeValue);
        } else if (a == Attribute.HatColor) {
            description = hatColorDescription(attributeValue);
        } else if (a == Attribute.SideAttachmentColor) {
            description = sideAttachmentColorDescription(attributeValue);
        } else {
            return "";
        }
    }

    function vehicleDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 10) {
            description = "lunar rover";
        } else if (value < 20) {
            description = "shark";
        } else if (value < 30) {
            description = "banana";
        } else if (value < 40) {
            description = "skull";
        } else if (value < 50) {
            description = "loaf of bread";
        } else if (value < 60) {
            description = "barrel";
        } else if (value < 70) {
            description = "ice cream cone";
        } else if (value < 80) {
            description = "cloud";
        } else if (value < 90) {
            description = "pumpkin";
        } else {
            description = "sandwich";
        }
    }

    function racerDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 34) {
            description = "queen bee";
        } else if (value < 67) {
            description = "dude";
        } else {
            description = "worm";
        }
    }

    function wheelsDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 10) {
            description = "pizza";
        } else if (value < 20) {
            description = "cog";
        } else if (value < 30) {
            description = "dartboard";
        } else if (value < 40) {
            description = "wood pallet";
        } else if (value < 50) {
            description = "saw blade";
        } else if (value < 60) {
            description = "vinyl record";
        } else if (value < 70) {
            description = "wagon wheel";
        } else if (value < 80) {
            description = "shirt button";
        } else if (value < 90) {
            description = "donut";
        } else {
            description = "sushi";
        }
    }

    function gogglesDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 10) {
            description = "monocle";
        } else if (value < 20) {
            description = "sunglasses";
        } else if (value < 30) {
            description = "ski";
        } else if (value < 40) {
            description = "heart";
        } else if (value < 50) {
            description = "flower";
        } else if (value < 60) {
            description = "opera";
        } else if (value < 70) {
            description = "groucho marx";
        } else if (value < 80) {
            description = "scuba";
        } else if (value < 90) {
            description = "spring eyes";
        } else {
            description = "angry";
        }
    }

    function hatDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 10) {
            description = "top hat";
        } else if (value < 20) {
            description = "propeller hat";
        } else if (value < 30) {
            description = "cat ears";
        } else if (value < 40) {
            description = "flower pot";
        } else if (value < 50) {
            description = "wizard";
        } else if (value < 60) {
            description = "fez";
        } else if (value < 70) {
            description = "tricorn";
        } else if (value < 80) {
            description = "jester";
        } else if (value < 90) {
            description = "viking";
        } else {
            description = "hard hat";
        }
    }

    function sideAttachmentDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 10) {
            description = "baloon";
        } else if (value < 20) {
            description = "search light";
        } else if (value < 30) {
            description = "umbrella";
        } else if (value < 40) {
            description = "nuclear tower";
        } else if (value < 50) {
            description = "disco ball";
        } else if (value < 60) {
            description = "carrot and stick";
        } else if (value < 70) {
            description = "selfie stick";
        } else if (value < 80) {
            description = "weathervane";
        } else if (value < 90) {
            description = "pot plant";
        } else {
            description = "tentacle";
        }
    }

    function backgroundDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 50) {
            description = "bg1";
        } else if (value < 98) {
            description = "bg2";
        } else {
            description = "superrarebg";
        }
    }

    function wheelsColorDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 34) {
            description = "blue";
        } else if (value < 67) {
            description = "black";
        } else {
            description = "rainbow";
        }
    }

    function vehicleColorDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 40) {
            description = "red";
        } else if (value < 70) {
            description = "clear";
        } else {
            description = "rainbow";
        }
    }

    function racerColorDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 50) {
            description = "pink";
        } else if (value < 80) {
            description = "purple";
        } else {
            description = "diamond";
        }
    }

    function gogglesColorDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 40) {
            description = "white";
        } else if (value < 90) {
            description = "cream";
        } else {
            description = "pearl";
        }
    }

    function hatColorDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 40) {
            description = "brown";
        } else if (value < 90) {
            description = "purple";
        } else {
            description = "silver";
        }
    }

    function sideAttachmentColorDescription(uint256 value)
        internal
        pure
        returns (string memory description)
    {
        require(value < 100, "value must be between 0-99");
        if (value < 20) {
            description = "red";
        } else if (value < 95) {
            description = "green";
        } else {
            description = "invisible";
        }
    }

    function getAttribute(uint256 tokenID, Attribute a)
        public
        view
        returns (string memory attributeDescription)
    {
        uint256 aNumber = uint256(a);
        uint256 startValue = (aNumber * 2) + 1;
        string memory aString = Utilities.substring(
            getDNAString(tokenID),
            startValue,
            startValue + 2
        );
        if (
            a == Attribute.TopSpeed ||
            a == Attribute.Acceleration ||
            a == Attribute.Handling
        ) {
            (
                uint256 balancedTopSpeed,
                uint256 balancedAcceleration,
                uint256 balancedHandling
            ) = getBalancedData(tokenID);
            if (a == Attribute.TopSpeed) {
                return Utilities.uintToString(balancedTopSpeed);
            } else if (a == Attribute.Acceleration) {
                return Utilities.uintToString(balancedAcceleration);
            } else if (a == Attribute.Handling) {
                return Utilities.uintToString(balancedHandling);
            } else {
                return "";
            }
        } else {
            return
                attributeDescriptionFromValue(
                    a,
                    Utilities.stringToUint(aString)
                );
        }
    }

    function getAttributeValue(uint256 tokenID, Attribute a)
        public
        view
        returns (uint256 attributeValue)
    {
        uint256 aNumber = uint256(a);
        uint256 startValue = (aNumber * 2) + 1;
        string memory aString = Utilities.substring(
            getDNAString(tokenID),
            startValue,
            startValue + 2
        );
        return Utilities.stringToUint(aString);
    }

    function getAttributeValues(uint256 tokenID)
        public
        view
        returns (uint256[_totalAttributes] memory attributes)
    {
        string memory dna = getDNAString(tokenID);
        for (uint256 i = 0; i < _totalAttributes * 2; i += 2) {
            attributes[(i / 2)] = Utilities.stringToUint(
                Utilities.substring(dna, i + 1, i + 3)
            );
        }
    }

    function getAttributeString(uint256 tokenID, Attribute a)
        public
        view
        returns (string memory attributeString)
    {
        uint256 aNumber = uint256(a);
        uint256 startValue = (aNumber * 2) + 1;
        string memory dnaString = getDNAString(tokenID);
        attributeString = Utilities.substring(
            dnaString,
            startValue,
            startValue + 2
        );
    }

    function getAttributeDescriptions(uint256 tokenID)
        public
        view
        returns (string[_totalAttributes] memory attributes)
    {
        string memory dna = getDNAString(tokenID);
        (
            uint256 topSpeed,
            uint256 acceleration,
            uint256 handling
        ) = getBalancedData(tokenID);
        for (uint256 i = 0; i < _totalAttributes * 2; i += 2) {
            if (i == 26) {
                attributes[(i / 2)] = Utilities.uintToString(topSpeed);
            } else if (i == 28) {
                attributes[(i / 2)] = Utilities.uintToString(acceleration);
            } else if (i == 30) {
                attributes[(i / 2)] = Utilities.uintToString(handling);
            } else {
                attributes[(i / 2)] = attributeDescriptionFromValue(
                    Attribute(i / 2),
                    Utilities.stringToUint(
                        Utilities.substring(dna, i + 1, i + 3)
                    )
                );
            }
        }
    }

    function getAttributeNames()
        public
        pure
        returns (string[_totalAttributes] memory)
    {
        return [
            "Vehicle",
            "Racer",
            "Wheels",
            "Goggles",
            "Hat",
            "SideAttachment",
            "Background",
            "WheelsColor",
            "VehicleColor",
            "RacerColor",
            "GogglesColor",
            "HatColor",
            "SideAttachmentColor",
            "TopSpeed",
            "Acceleraction",
            "Handling"
        ];
    }

    function getBalancedData(uint256 tokenID)
        public
        view
        returns (
            uint256 balancedTopSpeed,
            uint256 balancedAcceleration,
            uint256 balancedHandling
        )
    {
        uint256 speedInput = getAttributeValue(tokenID, Attribute.TopSpeed);
        uint256 accelerationInput = getAttributeValue(
            tokenID,
            Attribute.Acceleration
        );
        uint256 handlingInput = getAttributeValue(tokenID, Attribute.Handling);
        (
            balancedTopSpeed,
            balancedAcceleration,
            balancedHandling
        ) = RacerTokenUtilities.mapValuesToPool3(
            POOL_POINTS,
            speedInput,
            accelerationInput,
            handlingInput
        );
    }

    function getBalancedDataFromValues(
        uint256 topSpeed,
        uint256 acceleration,
        uint256 handling
    )
        public
        pure
        returns (
            uint256 balancedTopSpeed,
            uint256 balancedAcceleration,
            uint256 balancedHandling
        )
    {
        (
            balancedTopSpeed,
            balancedAcceleration,
            balancedHandling
        ) = RacerTokenUtilities.mapValuesToPool3(
            POOL_POINTS,
            topSpeed,
            acceleration,
            handling
        );
    }

    function isOwner(address ownerTest, uint256 racerID)
        public
        view
        returns (bool)
    {
        return RACER_CHILD.ownerOf(racerID) == ownerTest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../polygon/IChildToken.sol";
import "./Racer.sol";
import "./WrappedRacerRegistryChild.sol";

//import "../libraries/Utilities.sol";

contract RacerChild is Racer, IChildToken {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

    string private _revertMsg;

    mapping(uint256 => bool) public withdrawnTokens;

    // limit batching of tokens due to gas limit restrictions
    uint256 public constant BATCH_LIMIT = 20;

    mapping(uint256 => string[3]) internal _characterAttributes;
    mapping(uint256 => uint256) internal _meltTokensInToken;
    mapping(uint256 => uint256[]) internal _parents;

    uint256 internal _allocatedMeltTokens;
    uint256 internal _minimumMeltValue = 1000 * 10**18;

    address public meltTokenAddress; // ERC20 token used to bake value into tokens

    IERC20 internal _MELT;

    address internal _wrappedRacerRegistryChild;

    event WithdrawnBatch(address indexed user, uint256[] tokenIds);
    event TransferWithMetadata(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        bytes metaData
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _meltTokenAddress,
        address _childChainManager
    ) Racer(_name, _symbol, _baseTokenURI) {
        _setupContractId("RacerChild");
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, _childChainManager);
        _tokenIdTracker.increment(); // start ID @ 1 (0 is for origin parents - no racer will have this ID)

        meltTokenAddress = _meltTokenAddress;
        _allocatedMeltTokens = 0;
        _MELT = IERC20(_meltTokenAddress);
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId(s) for user
     * Should set `withdrawnTokens` mapping to `false` for the tokenId being deposited
     * Minting can also be done by other functions
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded tokenIds. Batch deposit also supported.
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        only(DEPOSITOR_ROLE)
    {
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            withdrawnTokens[tokenId] = false;
            _mint(user, tokenId);

            // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                withdrawnTokens[tokenIds[i]] = false;
                _mint(user, tokenIds[i]);
            }
        }
    }

    /**
     * @notice called when user wants to withdraw token back to root chain
     * @dev Should handle withraw by burning user's token.
     * Should set `withdrawnTokens` mapping to `true` for the tokenId being withdrawn
     * This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external {
        require(
            _msgSender() == ownerOf(tokenId),
            "ChildMintableERC721: INVALID_TOKEN_OWNER"
        );
        withdrawnTokens[tokenId] = true;

        // Encoding metadata associated with tokenId & emitting event
        emit TransferWithMetadata(
            ownerOf(tokenId),
            address(0),
            tokenId,
            this.encodeTokenMetadata(tokenId)
        );

        _burn(tokenId);
    }

    /**
     * @notice called when user wants to withdraw multiple tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param tokenIds tokenId list to withdraw
     */
    function withdrawBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        require(
            length <= BATCH_LIMIT,
            "ChildMintableERC721: EXCEEDS_BATCH_LIMIT"
        );

        // Iteratively burn ERC721 tokens, for performing
        // batch withdraw
        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                _msgSender() == ownerOf(tokenId),
                string(
                    abi.encodePacked(
                        "ChildMintableERC721: INVALID_TOKEN_OWNER ",
                        tokenId
                    )
                )
            );
            withdrawnTokens[tokenId] = true;
            // Encoding metadata associated with tokenId & emitting event
            emit TransferWithMetadata(
                ownerOf(tokenId),
                address(0),
                tokenId,
                this.encodeTokenMetadata(tokenId)
            );
            _burn(tokenId);
        }

        // At last emit this event, which will be used
        // in MintableERC721 predicate contract on L1
        // while verifying burn proof
        emit WithdrawnBatch(_msgSender(), tokenIds);
    }

    /**
     * @notice called when user wants to withdraw token back to root chain with token URI
     * @dev Should handle withraw by burning user's token.
     * Should set `withdrawnTokens` mapping to `true` for the tokenId being withdrawn
     * This transaction will be verified when exiting on root chain
     *
     * @param tokenId tokenId to withdraw
     */
    function withdrawWithMetadata(uint256 tokenId) external {
        require(
            _msgSender() == ownerOf(tokenId),
            "ChildMintableERC721: INVALID_TOKEN_OWNER"
        );
        withdrawnTokens[tokenId] = true;

        // Encoding metadata associated with tokenId & emitting event
        emit TransferWithMetadata(
            ownerOf(tokenId),
            address(0),
            tokenId,
            this.encodeTokenMetadata(tokenId)
        );

        _burn(tokenId);
    }

    /**
     * @notice This method is supposed to be called by client when withdrawing token with metadata
     * and pass return value of this function as second paramter of `withdrawWithMetadata` method
     *
     * It can be overridden by clients to encode data in a different form, which needs to
     * be decoded back by them correctly during exiting
     *
     * @param tokenId Token for which URI to be fetched
     */
    function encodeTokenMetadata(uint256 tokenId)
        external
        view
        virtual
        returns (bytes memory)
    {
        // You're always free to change this default implementation
        // and pack more data in byte array which can be decoded back
        // in L1
        return abi.encode(getDNA(tokenId));
        //return abi.encode(tokenURI(tokenId));
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Must have pauser role to unpause"
        );
        _unpause();
    }

    function newToken(
        uint256 dna,
        address tokenReceiver,
        uint256 tokensAllocated,
        string memory descriptiveAttr1,
        string memory descriptiveAttr2,
        string memory descriptiveAttr3
    ) public only(MINTER_ROLE) whenNotPaused {
        require(
            tokensAllocated >= _minimumMeltValue,
            "Must contain minimum melt value"
        );

        require(
            unallocatedBalance() >= tokensAllocated,
            "Not enough melt tokens in contract to mint new token"
        );

        uint256 currentID = _tokenIdTracker.current();
        _dna[currentID] = dna;
        _meltTokensInToken[currentID] = tokensAllocated;
        _allocatedMeltTokens += tokensAllocated;
        _characterAttributes[currentID] = [
            descriptiveAttr1,
            descriptiveAttr2,
            descriptiveAttr3
        ];
        _parents[currentID] = [0, 0];
        _associatedERC721Address[currentID] = address(this);
        _associatedERC721Id[currentID] = currentID;

        _mint(tokenReceiver, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function newToken(
        uint256 dna,
        address tokenReceiver,
        uint256 tokensAllocated,
        string memory descriptiveAttr1,
        string memory descriptiveAttr2,
        string memory descriptiveAttr3,
        address wrappedNFTAddress,
        uint256 wrappedNFTId
    ) public only(MINTER_ROLE) whenNotPaused {
        require(
            tokensAllocated >= _minimumMeltValue,
            "Must contain minimum melt value"
        );

        require(
            unallocatedBalance() >= tokensAllocated,
            "Not enough melt tokens in contract to mint new token"
        );

        uint256 currentID = _tokenIdTracker.current();
        _dna[currentID] = dna;
        _meltTokensInToken[currentID] = tokensAllocated;
        _allocatedMeltTokens += tokensAllocated;
        _characterAttributes[currentID] = [
            descriptiveAttr1,
            descriptiveAttr2,
            descriptiveAttr3
        ];
        _parents[currentID] = [0, 0];
        _associatedERC721Address[currentID] = wrappedNFTAddress;
        _associatedERC721Id[currentID] = wrappedNFTId;

        _mint(tokenReceiver, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function newToken(
        uint256 dna,
        address tokenReceiver,
        uint256 tokensAllocated,
        string memory descriptiveAttr1,
        string memory descriptiveAttr2,
        string memory descriptiveAttr3,
        address wrappedNFTAddress,
        uint256 wrappedNFTId,
        uint256 parentA,
        uint256 parentB
    ) public only(MINTER_ROLE) whenNotPaused {
        require(
            tokensAllocated >= _minimumMeltValue,
            "Must contain minimum melt value"
        );

        require(
            unallocatedBalance() >= tokensAllocated,
            "Not enough melt tokens in contract to mint new token"
        );

        uint256 currentID = _tokenIdTracker.current();
        _dna[currentID] = dna;
        _meltTokensInToken[currentID] = tokensAllocated;
        _allocatedMeltTokens += tokensAllocated;
        _characterAttributes[currentID] = [
            descriptiveAttr1,
            descriptiveAttr2,
            descriptiveAttr3
        ];
        _parents[currentID] = [parentA, parentB];
        _associatedERC721Address[currentID] = wrappedNFTAddress;
        _associatedERC721Id[currentID] = wrappedNFTId;

        _mint(tokenReceiver, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /* ADMIN FUNCTIONS */

    function setWrappedRacerRegistryChild(address wrrcAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        _wrappedRacerRegistryChild = wrrcAddress;
    }

    function setNewMinter(address newMinter, address revokeAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINTER_ROLE, revokeAddress);
        grantRole(MINTER_ROLE, newMinter);
    }

    function setNewMinter(address newMinter) public only(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, newMinter);
    }

    function setNewPauser(address newPauser, address revokeAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(PAUSER_ROLE, revokeAddress);
        grantRole(PAUSER_ROLE, newPauser);
    }

    function setNewPauser(address newPauser) public only(DEFAULT_ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, newPauser);
    }

    function setNewDepositor(address depositor, address revokeAddress)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(DEPOSITOR_ROLE, revokeAddress);
        grantRole(DEPOSITOR_ROLE, depositor);
    }

    function setNewDepositor(address depositor)
        public
        only(DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEPOSITOR_ROLE, depositor);
    }

    /* TOKEN INTERACTIONS */

    function meltToken(uint256 tokenID) public {
        burn(tokenID);
        _MELT.transfer(_msgSender(), _meltTokensInToken[tokenID]);
        _allocatedMeltTokens -= _meltTokensInToken[tokenID];
        _meltTokensInToken[tokenID] = 0;

        if (_wrappedRacerRegistryChild != address(0)) {
            WrappedRacerRegistryChild wrrc = WrappedRacerRegistryChild(
                _wrappedRacerRegistryChild
            );
            wrrc.deregisterRacer(
                _associatedERC721Address[tokenID],
                _associatedERC721Id[tokenID]
            );
        }

        _characterAttributes[tokenID] = ["", "", ""];
        _parents[tokenID] = [0, 0];
        _dna[tokenID] = 0;
        _associatedERC721Address[tokenID] = address(0);
        _associatedERC721Id[tokenID] = 0;

        // TODO:
        // emit event
    }

    function meltTokenBalance() public view returns (uint256 totalBalance) {
        return (_MELT.balanceOf(address(this)));
    }

    function unallocatedBalance() internal view returns (uint256 balance) {
        if (_MELT.balanceOf(address(this)) > _allocatedMeltTokens) {
            balance = _MELT.balanceOf(address(this)) - _allocatedMeltTokens;
        } else {
            balance = 0;
        }
    }

    /* CHARACTER INTERACTIONS*/

    function requestNewAttributes(uint256 token) public {
        // TODO: re-roll character attributes (for payment)
        // Must have more than minimum _MELT in token to request attribute
    }

    function getDNA(uint256 tokenID) public view returns (uint256 dna) {
        return _dna[tokenID];
    }

    // called to add directly from user's wallet to melt token
    function addMeltTokensToToken(uint256 tokenID, uint256 amountToSend)
        public
    {
        // this only works if this contract is first authorized to spend user's Melt token.
        // Should call authorize on ERC20 token directly from front end (user) first
        require(
            _MELT.allowance(_msgSender(), address(this)) >= amountToSend,
            "contract not allowed to spend user tokens"
        );
        _MELT.transferFrom(_msgSender(), address(this), amountToSend);
        _meltTokensInToken[tokenID] += amountToSend;
        _allocatedMeltTokens += amountToSend;
    }

    function withdrawMeltTokensTo(
        address toAddress,
        uint256 amount,
        uint256 tokenID
    ) public onlyRole(SPENDER_ROLE) {
        require(
            getMeltValue(tokenID) >= (_minimumMeltValue + amount),
            "Not enough tokens in NFT"
        );
        _MELT.transfer(toAddress, amount);
        _meltTokensInToken[tokenID] -= amount;
        _allocatedMeltTokens -= amount;
    }

    function allocateMeltTokens(uint256 tokenID, uint256 amount)
        public
        onlyRole(SPENDER_ROLE)
    {
        require(
            unallocatedBalance() >= amount,
            "Not enough unallocated tokens in contract"
        );
        _meltTokensInToken[tokenID] += amount;
        _allocatedMeltTokens += amount;
    }

    function deallocateMeltTokens(uint256 tokenID, uint256 amount)
        public
        onlyRole(SPENDER_ROLE)
    {
        require(
            _meltTokensInToken[tokenID] >= (_minimumMeltValue + amount),
            "Not enough tokens in NFT to deallocate"
        );
        _meltTokensInToken[tokenID] -= amount;
        _allocatedMeltTokens -= amount;
    }

    function withdrawUnallocatedTokensTo(address toAddress, uint256 amount)
        public
        onlyRole(SPENDER_ROLE)
    {
        require(
            unallocatedBalance() >= amount,
            "Not enough unallocated tokens in contract"
        );
        _MELT.transfer(toAddress, amount);
    }

    function getMeltValue(uint256 tokenID) public view returns (uint256 value) {
        return (_meltTokensInToken[tokenID]);
    }

    function nextTokenId() public view returns (uint256 nextId) {
        nextId = _tokenIdTracker.current();
    }

    function getCharacterAttributes(uint256 tokenID)
        public
        view
        returns (
            string memory attr1,
            string memory attr2,
            string memory attr3
        )
    {
        string[3] memory attrs = _characterAttributes[tokenID];
        return (attrs[0], attrs[1], attrs[2]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "../libraries/Utilities.sol";
import "../polygon/AccessControlMixin.sol";
import "../polygon/NativeMetaTransaction.sol";
import "../polygon/ContextMixin.sol";
import "../polygon/IMintableERC721.sol";

contract Racer is
    IMintableERC721,
    AccessControlMixin,
    ContextMixin,
    NativeMetaTransaction,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    Ownable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    address internal _predicate;

    Counters.Counter internal _tokenIdTracker;

    string internal _baseTokenURI;

    // Mappings from token ID to value
    mapping(uint256 => uint256) internal _dna;
    mapping(uint256 => address) internal _associatedERC721Address;
    mapping(uint256 => uint256) internal _associatedERC721Id;
    mapping(uint256 => string) internal _canonicalURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupContractId("Racer");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _setupRole(URI_SETTER_ROLE, _msgSender());
        _initializeEIP712(name);
    }

    function setCanonicalURI(string memory uri, uint256 tokenId)
        public
        onlyRole(URI_SETTER_ROLE)
    {
        _canonicalURI[tokenId] = uri;
    }

    function setCanonicalURIs(string[] memory uris, uint256[] memory tokenIds)
        public
        onlyRole(URI_SETTER_ROLE)
    {
        require(uris.length == tokenIds.length, "arrays different sizes");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _canonicalURI[tokenIds[i]] = uris[i];
        }
    }

    function setNewPredicate(address newPredicate) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have admin role to set predicate"
        );
        revokeRole(PREDICATE_ROLE, _predicate);
        grantRole(PREDICATE_ROLE, newPredicate);
        _predicate = newPredicate;
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use __msgSender() instead
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {IMintableERC721-mint}.
     */
    function mint(address user, uint256 tokenId)
        external
        override
        only(PREDICATE_ROLE)
    {
        _mint(user, tokenId);
    }

    /**
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method, to be invoked
     * when minting token back on L1, during exit
     */
    function setTokenMetadata(uint256 tokenId, bytes memory data)
        internal
        virtual
    {
        // This function should decode metadata obtained from L2
        // and attempt to set it for this `tokenId`
        //
        // Following is just a default implementation, feel
        // free to define your own encoding/ decoding scheme
        // for L2 -> L1 token metadata transfer
        uint256 dna = abi.decode(data, (uint256));
        _dna[tokenId] = dna;
    }

    /**
     * @dev See {IMintableERC721-mint}.
     *
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method
     */
    function mint(
        address user,
        uint256 tokenId,
        bytes calldata metaData
    ) external override only(PREDICATE_ROLE) {
        _mint(user, tokenId);

        setTokenMetadata(tokenId, metaData);
    }

    /**
     * @dev See {IMintableERC721-exists}.
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /* ERC721 Mint / Pause / Burn */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory returnString;
        if (bytes(_canonicalURI[tokenId]).length > 0) {
            returnString = _canonicalURI[tokenId];
        } else {
            string memory baseURI = _baseURI();
            returnString = bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
        }
        return returnString;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* ADMIN FUNCTIONS */

    function setNewAdmin(address newAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have admin role to set pauser"
        );
        revokeRole(DEFAULT_ADMIN_ROLE, getRoleMember(DEFAULT_ADMIN_ROLE, 0));
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
        transferOwnership(newAdmin);
    }

    /* DEPRECATED FUNCTIONS */

    // function getRacerInfo(uint256 tokenID)
    //     public
    //     pure
    //     returns (
    //         string memory racerName,
    //         uint256 racerMaxSpeed,
    //         uint256 racerAcceleration
    //     )
    // {
    //     //return (name[tokenID], maxSpeed[tokenID], acceleration[tokenID]);
    //     // don't store helpers in contract
    //     racerName = "Racer";
    //     racerMaxSpeed = 10;
    //     racerAcceleration = 5;
    // }

    // function getStats(uint256 tokenID)
    //     public
    //     pure
    //     returns (uint256 racerMaxSpeed, uint256 racerAcceleration)
    // {
    //     //return(maxSpeed[tokenID], acceleration[tokenID]);
    //     // dont store helpers in contract
    //     racerMaxSpeed = 10;
    //     racerAcceleration = 5;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IMintableERC721 is IERC721 {
    /**
     * @notice called by predicate contract to mint tokens while withdrawing
     * @dev Should be callable only by MintableERC721Predicate
     * Make sure minting is done only by this function
     * @param user user address for whom token is being minted
     * @param tokenId tokenId being minted
     */
    function mint(address user, uint256 tokenId) external;

    /**
     * @notice called by predicate contract to mint tokens while withdrawing with metadata from L2
     * @dev Should be callable only by MintableERC721Predicate
     * Make sure minting is only done either by this function/ 👆
     * @param user user address for whom token is being minted
     * @param tokenId tokenId being minted
     * @param metaData Associated token metadata, to be decoded & set using `setTokenMetadata`
     *
     * Note : If you're interested in taking token metadata from L2 to L1 during exit, you must
     * implement this method
     */
    function mint(
        address user,
        uint256 tokenId,
        bytes calldata metaData
    ) external;

    /**
     * @notice check if token already exists, return true if it does exist
     * @dev this check will be used by the predicate to determine if the token needs to be minted or transfered
     * @param tokenId tokenId being checked
     */
    function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IChildToken {
    function deposit(address user, bytes calldata depositData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract AccessControlMixin is AccessControlEnumerable {
    string private _revertMsg;

    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(
            abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS")
        );
    }

    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), _revertMsg);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Utilities {
    using SafeMath for uint256;

    /* Utilities */

    //TODO: use openzeppelin strings for uintToString

    function uintToString(uint256 v) public pure returns (string memory str) {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint256 j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function stringToUint(string memory s)
        public
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        uint8 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function stringLength(string memory s)
        public
        pure
        returns (uint256 length)
    {
        return bytes(s).length;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) public pure returns (string memory s) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function average(uint256 a, uint256 b) public pure returns (uint256) {
        return (a + b) / 2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library RaceUtilities {
    function relativeDistance(
        uint256 absoluteSpace1,
        uint256 absoluteSpace2,
        uint256 spacesPerLap
    ) public pure returns (uint256 rDistance, uint256 further) {
        uint256 distance = absoluteSpace1 > absoluteSpace2
            ? absoluteSpace1 - absoluteSpace2
            : absoluteSpace2 - absoluteSpace1;
        uint256[2] memory comparison1;
        uint256[2] memory comparison2;
        //uint256 spaces = race.spaces;
        if (distance >= spacesPerLap) {
            //objects are in different laps
            if (absoluteSpace1 > absoluteSpace2) {
                // move comparison 2 to lane 2 & comparison 1 to lane 1
                comparison1 = [2, lapPosition(absoluteSpace1, spacesPerLap)[1]];
                comparison2 = [1, lapPosition(absoluteSpace2, spacesPerLap)[1]];
            } else {
                comparison1 = [1, lapPosition(absoluteSpace1, spacesPerLap)[1]];
                comparison2 = [2, lapPosition(absoluteSpace2, spacesPerLap)[1]];
            }
            uint256 aComparison1 = lapPositionToAbsoluteSpace(
                comparison1,
                spacesPerLap
            );
            uint256 aComparison2 = lapPositionToAbsoluteSpace(
                comparison2,
                spacesPerLap
            );
            if (aComparison2 > aComparison1) {
                rDistance = aComparison2 - aComparison1;
                further = 2;
            } else {
                rDistance = aComparison1 - aComparison2;
                further = 1;
            }
        } else {
            if (absoluteSpace2 > absoluteSpace1) {
                rDistance = absoluteSpace2 - absoluteSpace1;
                further = 2;
            } else {
                rDistance = absoluteSpace1 - absoluteSpace2;
                further = 1;
            }
        }
    }

    function positionToLapLanePosition(
        uint256[2] memory position,
        uint256 spacesPerLap
    ) public pure returns (uint256[3] memory) {
        // [lap, space, lane]
        uint256[2] memory lp = lapPosition(position[0], spacesPerLap);
        return [lp[0], lp[1], position[1]];
    }

    function lapPosition(uint256 absoluteSpace, uint256 spacesPerLap)
        public
        pure
        returns (uint256[2] memory lapSpace)
    {
        if (spacesPerLap == 0) {
            return [uint256(0), uint256(0)];
        } else {
            uint256 lap = (absoluteSpace / spacesPerLap);
            uint256 spaceInLap = absoluteSpace - (lap * spacesPerLap);
            return [(lap + 1), spaceInLap];
        }
        //
        //Note: laps start at 1, position & lane start at 0. First space in second lap would be [2,0]
    }

    function lapPositionToAbsoluteSpace(
        uint256[2] memory lapSpace,
        uint256 spacesPerLap
    ) public pure returns (uint256) {
        //[lap, space] to space
        return ((spacesPerLap * (lapSpace[0] - 1)) + lapSpace[1]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Race.sol";
import "./KeeperInterface.sol";

contract UpdateQueue is KeeperCompatibleInterface, Ownable {
    mapping(address => bool) public authorized; // authorized[raceContract]
    mapping(uint256 => bool) private _inQueue; // _inQueue[raceID] // returns if already in the queue
    uint256[] public queue; // stores ID of races in need of update
    address private _raceContract;
    bool private _needsCleanup = false;
    address private _owner;
    bool private _forceUpdate;

    constructor(address raceContractAddress, address ownerAddress) {
        _raceContract = raceContractAddress;
        transferOwnership(ownerAddress);
    }

    function cleanupQueue() public {
        for (uint256 i = 0; i < queue.length; i++) {
            if (queue[i] == 0 && queue.length > 1) {
                // shift everything into open slot
                for (uint256 j = i; j < queue.length - 1; j++) {
                    queue[j] = queue[(j + 1)];
                }
                queue.pop();
            }
        }
        _needsCleanup = false;
    }

    function removeItemFromQueue(uint256 index) public onlyOwner {
        // dangerous, only do this in emergency
        _inQueue[(queue[index])] = false;
        delete queue[index];
    }

    function setNeedsCleanup(bool needsCleanup) public onlyOwner {
        _needsCleanup = needsCleanup;
    }

    function setForceUpdate(bool forceUpdate) public onlyOwner {
        // use this to force the next keeper update to cleanupQueue
        // (_needsCleanup also must be true or this will reset to false)
        _forceUpdate = forceUpdate;
    }

    function setAuthorization(bool isAuthorized, address contractAddress)
        public
        onlyOwner
    {
        authorized[contractAddress] = isAuthorized;
    }

    function requestUpdate(uint256 raceID) public {
        //require(authorized[msg.sender], "requester not authorized");
        //require(_inQueue[raceID] == false, "update already in queue");
        queue.push(raceID);
        _inQueue[raceID] = true;
    }

    function updateNeeded()
        public
        view
        returns (bool shouldUpdate, uint256 updateIndex)
    {
        shouldUpdate = false;
        updateIndex = 0;
        for (uint256 i = 0; i < queue.length; i++) {
            if (queue[i] != 0) {
                shouldUpdate = true;
                updateIndex = i;
                break;
            }
        }
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        //performData = abi.encode(1235,24,13);
        bool update;
        uint256 index;
        performData = checkData;
        (update, index) = updateNeeded();
        upkeepNeeded = update;
        if (update) {
            performData = abi.encode(index);
        } else if (_forceUpdate) {
            upkeepNeeded = true;
            performData = abi.encode(0);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if (_forceUpdate) {
            if (_needsCleanup) {
                cleanupQueue();
            }
            _forceUpdate = false;
        } else {
            uint256 index = abi.decode(performData, (uint256));
            uint256 raceID = queue[index];
            if (raceID != 0) {
                updateRace(raceID);
                delete queue[index];
                _inQueue[raceID] = false;
                // Make sure this is no more that 2,00,000 gas
            } else {
                if (_needsCleanup) {
                    cleanupQueue();
                }
            }
        }
    }

    function pushUpdate(uint256 updateIndex) public {
        uint256 raceID = queue[updateIndex];
        if (raceID != 0) {
            updateRace(raceID);
            delete queue[updateIndex];
            _inQueue[raceID] = false;
        }
    }

    function updateRace(uint256 raceID) private {
        Race r = Race(_raceContract);
        r.updateRace(raceID);
    }

    function getQueue() public view returns (uint256[] memory) {
        return queue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./Race.sol";

contract Track {
    uint256 _currentID = 0;

    mapping(uint256 => uint256[4][][]) public spaces; // spaces[trackID]; *see spaces description below
    mapping(uint256 => uint256) public lanes; // lanes[trackID] returns total number of lanes
    mapping(uint256 => address) public trackOwner; //trackOwner[trackID]
    mapping(address => uint256[]) public tracks; //tracks[address]
    mapping(Item => Race.Action) public itemAction; // itemAction[item] returns equivalent action to be applied
    mapping(Terrain => Race.Action) public terrainAction; // terrainAction[terrain] returns equivalent action to be applied
    /*
spaces:
[
    [//space0
        [ // lane0 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
        [ // lane1 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
        [ // lane2 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
        [ // lane3 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
    ],
    [//space1
        [ // lane0 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
        [ // lane1 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
        [ // lane2 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
        [ // lane3 attributes
            item, enabled, terrain, terrainIgnoresInvincibility
        ],
    ]
]

*/

    enum Terrain {
        Default,
        Sand,
        Slime,
        Slick,
        SpeedBoost
    }
    uint256 private totalTerrains = 5;

    enum Item {
        None,
        Banana,
        SpeedBoost,
        Mushroom,
        MysteryBox,
        Invincibility,
        Missile
    }
    uint256 private totalItems = 7;

    constructor() {
        // Initialize all possible items
        itemAction[Item.None] = Race.Action.None;
        itemAction[Item.Banana] = Race.Action.LaneSwitchLeft;
        itemAction[Item.SpeedBoost] = Race.Action.IncreaseSpeed;
        itemAction[Item.Mushroom] = Race.Action.IncreaseSpeed;
        itemAction[Item.MysteryBox] = Race.Action.ReceiveRandomItem;
        itemAction[Item.Invincibility] = Race.Action.Invincibility;
        itemAction[Item.Missile] = Race.Action.ShootMissile;

        // Initialize terrain actions
        terrainAction[Terrain.Default] = Race.Action.None;
        terrainAction[Terrain.Sand] = Race.Action.SlowDown;
        terrainAction[Terrain.Slime] = Race.Action.SpinoutLeft;
        terrainAction[Terrain.Slick] = Race.Action.SpinoutRight;
        terrainAction[Terrain.SpeedBoost] = Race.Action.IncreaseSpeed;
    }

    function initiateTrack(uint256 numLanes) public returns (uint256 trackID) {
        require(numLanes > 0, "must have at least 1 lane");
        _currentID++;
        trackOwner[_currentID] = msg.sender;
        tracks[msg.sender].push(_currentID);
        lanes[_currentID] = numLanes;
        return _currentID;
    }

    /*function initiateTrackWithSpaces(Item[] memory items,
                                     bool[] memory enabled,
                                     uint[] memory chances,
                                     Terrain[] memory terrains) public returns(uint){
        require(items.length == enabled.length &&
                items.length == chances.length &&
                items.length == terrains.length, "arrays must be equal lengths");
        _currentID++;
        trackOwner[_currentID] = msg.sender;
        tracks[msg.sender].push(_currentID);
        Space[] storage trackSpaces = spaces[_currentID];
        for (uint i = 0; i < items.length; i++) {
            Space memory newSpace = Space({
                                    item: items[i],
                                    itemEnabled: enabled[i],
                                    itemChance: chances[i],
                                    terrain: terrains[i]});
            trackSpaces.push(newSpace);
        }

        return _currentID;
    }*/

    function addSpace(
        Item[] memory items,
        bool[] memory enabled,
        Terrain[] memory terrains,
        bool[] memory terrainIgnoresInvincibility,
        uint256 trackID
    ) public {
        require(
            trackOwner[trackID] == msg.sender,
            "Must own track to add spaces"
        );
        require(
            items.length == enabled.length && items.length == terrains.length,
            "Arrays must be same length"
        );
        require(
            items.length == lanes[trackID],
            "Incorrect number of lane items"
        );

        uint256[4][] memory newSpace = new uint256[4][](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            //[item, enabled, terrain, terrainIgnoresInvincibility]
            newSpace[i] = [
                uint256(items[i]),
                enabled[i] ? 1 : 0,
                uint256(terrains[i]),
                terrainIgnoresInvincibility[i] ? 1 : 0
            ];
        }
        spaces[trackID].push(newSpace);
    }

    function addSpaces(
        Item[][] memory items,
        bool[][] memory enabled,
        Terrain[][] memory terrains,
        bool[][] memory terrainIgnoresInvincibility,
        uint256 trackID
    ) public {
        require(
            trackOwner[trackID] == msg.sender,
            "Must own track to add spaces"
        );
        require(
            items.length == enabled.length && items.length == terrains.length,
            "Arrays must be same length"
        );
        require(
            items[0].length == enabled[0].length &&
                items[0].length == terrains[0].length,
            "Arrays must be same length"
        );
        require(
            items[0].length == lanes[trackID],
            "Incorrect number of lane items"
        );

        for (uint256 i = 0; i < items.length; i++) {
            uint256[4][] memory newSpace = new uint256[4][](items[i].length);
            for (uint256 j = 0; j < items[i].length; j++) {
                //[item, enabled, terrain, terrainIgnoresInvincibility]
                newSpace[j] = [
                    uint256(items[i][j]),
                    enabled[i][j] ? 1 : 0,
                    uint256(terrains[i][j]),
                    terrainIgnoresInvincibility[i][j] ? 1 : 0
                ];
            }
            spaces[trackID].push(newSpace);
        }
    }

    function removeLastSpace(uint256 trackID) public {
        require(
            trackOwner[trackID] == msg.sender,
            "Must own track to remove spaces"
        );
        require(spaces[trackID].length > 0, "no spaces to remove");
        spaces[trackID].pop();
    }

    function removeLastNSpaces(uint256 n, uint256 trackID) public {
        require(
            trackOwner[trackID] == msg.sender,
            "Must own track to remove spaces"
        );
        require(spaces[trackID].length > 0, "no spaces to remove");
        uint256[4][][] storage trackSpaces = spaces[trackID];
        uint256 totalPops = trackSpaces.length < n ? trackSpaces.length : n;
        for (uint256 i = 0; i < totalPops; i++) {
            trackSpaces.pop();
        }
    }

    function getMyTracks() public view returns (uint256[] memory myTracks) {
        return tracks[msg.sender];
    }

    function getSpaces(uint256 trackID)
        public
        view
        returns (uint256[4][][] memory trackSpaces)
    {
        return spaces[trackID];
    }

    function getTotalSpaces(uint256 trackID)
        public
        view
        returns (uint256 numSpaces)
    {
        numSpaces = spaces[trackID].length;
    }

    function getTotalLanes(uint256 trackID)
        public
        view
        returns (uint256 numLanes)
    {
        numLanes = lanes[trackID];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./Track.sol";
import "../racers/RacerData.sol";
import "../libraries/RaceUtilities.sol";
import "./UpdateQueue.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Race is VRFConsumerBase, Ownable {
    mapping(uint256 => RaceLog) public races; //races[raceId]
    mapping(Action => int256[5]) private actions; //returns [speedAdjust, accelerationAdjust, laneAdjust, lifespan, actionType]
    mapping(uint256 => mapping(uint256 => Track.Item[])) private itemInventory; //itemInventory[raceID][racerID]
    mapping(uint256 => mapping(uint256 => Action[])) private actionsQueue; // actionsQueue[raceID][racerID] = [action, action, action]
    mapping(uint256 => mapping(uint256 => uint256)) private laneChangesQueue; //laneChangesQueue[raceID][racerID] = newLane
    mapping(uint256 => mapping(uint256 => bool)) private wantsLaneChange; //wantsLaneChange[raceID][racerID]
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Action)))
        private environmentActions; // environemntActions[raceID][spaceID][lane#]; returns Action

    mapping(uint256 => mapping(uint256 => uint256)) private currentSpeed; // currentSpeed[raceID][racerID];
    mapping(uint256 => mapping(uint256 => uint256[2])) private currentPosition; //currentPosition[raceID][racerID]; returns [absolute space, lane];
    mapping(uint256 => mapping(uint256 => bool)) private completedRace; //completedRace[raceID][racerID] true if through with final lap.
    mapping(uint256 => bool) public allRacersFinished; //allRacersFinished[raceID]

    mapping(Action => Action) private _appliedAction; // _appliedAction[Action] = Boost action equivalent that can be applied to self

    mapping(uint256 => uint256[5][]) private activeProjectiles; //activeProjectiles[raceID] = [[Action, absolute space, lane, remainingLifespan, current speed], [Action, space, lane, remainingLifespan, current speed]]
    mapping(Action => uint256[2]) private projectileSpeedAcceleration; /// [max speed, acceleraction]

    mapping(bytes32 => uint256) private randomRequestRaceID; // randomRequestRaceID[requestID] = RaceID to apply random number + update

    mapping(uint256 => bool) public _updating; // _updating[raceID] returns whether race is currently updating

    uint256 _currentID = 0;
    mapping(address => uint256[]) public registeredRaces;
    RacerData internal racerData;
    address public trackContract;
    bytes32 internal _vrfKeyHash;
    uint256 internal _vrfFee;
    uint256 public randomResult;

    struct RaceLog {
        uint256 id;
        address coordinator;
        address gameLoop;
        uint256 trackId;
        uint8 laps; // number of laps
        uint256 spaces; // number of spaces per lap
        uint256[] racers;
        uint256[3][] itemsAcquired; // [[update, racer, item], [update, racer, item]]
        uint256[3][] actionsUsed; //[[udpate, racer, action], [update, racer, action]]
        uint256[3][] laneChanges; //[[update, racer, toLane]]
        uint256[][] randomNumbers; // random number generated for each turn, used for determining outcomes in race reconstruction
        uint256[2][] results; //[][carID, finalPosition][carID, finalPosition]]
        uint256 entryFee;
        uint256 updates; // total updates that have been applied
        uint256 lastUpdate; // timestamp of most recent update
        address updateQueue; //address of update queue
    }

    enum Phase {
        None,
        Play,
        Processing,
        Complete
    }

    mapping(uint256 => Phase) internal currentPhase; // currentPhase[raceID]

    //TODO: check for current phase at player choice submissions
    // ensure players can only submit one time

    enum Action {
        // Boost Actions
        None,
        IncreaseSpeed,
        SlowDown,
        //Projectile Actions
        ShootMissile,
        ShootSlowDown,
        //Environment Actions
        DropMine,
        LaneSwitchLeft,
        LaneSwitchRight,
        SpinoutLeft,
        SpinoutRight,
        //Invincibility Actions
        Invincibility,
        //ReceiveItem Actions
        ReceiveRandomItem,
        // Applied Actions (boost equivalents of environment actions)
        Explode,
        MoveLeft,
        MoveRight,
        SlowDownMoveLeft,
        SlowDownMoveRight,
        NoneBoost
    }
    uint8 private _possibleActions = 16;

    enum ActionType {
        None,
        Boost,
        Environment,
        Projectile,
        Invincibility,
        ReceiveItem
    }

    // Action Types:
    // Boost = applied to self
    // Environment = placed on space as environment action - doesn't move.
    // Projectile = shoot something
    // Invincibility = unaffected by other attacks

    event RaceStart(uint256 indexed raceID);
    event RaceComplete(uint256 indexed raceID);
    event PhaseStart(uint256 indexed raceID, string phase);
    event PhaseEnd(uint256 indexed raceID, string phase);

    //emit PhaseStart(raceID, "play");
    //emit PhaseEnd(raceID, "processing");

    constructor(
        address racerDataContractAddress,
        address trackContractAddress,
        bytes32 vrfKeyHash,
        uint256 vrfFee,
        address vrfCoordinator,
        address linkToken,
        address owner
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        _vrfKeyHash = vrfKeyHash;
        _vrfFee = vrfFee;
        racerData = RacerData(racerDataContractAddress);
        trackContract = trackContractAddress;
        transferOwnership(owner);

        // Some sample values for actions
        //[speed adjustment, acceleration adjustment, lane adjustment, lifespan, action type]
        actions[Action.None] = [
            int256(0),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.None))
        ];

        // Boost Actions (can be applied to self)
        actions[Action.IncreaseSpeed] = [
            int256(2),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];
        actions[Action.SlowDown] = [
            int256(-2),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];

        // Projectile Actions (shot at others)
        actions[Action.ShootMissile] = [
            int256(-3),
            int256(0),
            int256(0),
            int256(20),
            int256(uint256(ActionType.Projectile))
        ];
        actions[Action.ShootSlowDown] = [
            int256(-2),
            int256(0),
            int256(0),
            int256(15),
            int256(uint256(ActionType.Projectile))
        ];
        //Set Projectile Speeds
        projectileSpeedAcceleration[Action.ShootMissile] = [5, 5];
        projectileSpeedAcceleration[Action.ShootSlowDown] = [5, 5];

        // Environment Actions (placed in environment)
        actions[Action.LaneSwitchRight] = [
            int256(0),
            int256(-1),
            int256(1),
            int256(0),
            int256(uint256(ActionType.Environment))
        ];
        actions[Action.LaneSwitchLeft] = [
            int256(0),
            int256(-1),
            int256(-1),
            int256(0),
            int256(uint256(ActionType.Environment))
        ];
        actions[Action.DropMine] = [
            int256(-3),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.Environment))
        ];
        actions[Action.SpinoutLeft] = [
            int256(-4),
            int256(-4),
            int256(-1),
            int256(0),
            int256(uint256(ActionType.Environment))
        ];
        actions[Action.SpinoutRight] = [
            int256(-4),
            int256(-4),
            int256(1),
            int256(0),
            int256(uint256(ActionType.Environment))
        ];

        // Invincibility Actions
        actions[Action.Invincibility] = [
            int256(0),
            int256(0),
            int256(0),
            int256(1),
            int256(uint256(ActionType.Invincibility))
        ];

        // Specialty Actions
        actions[Action.ReceiveRandomItem] = [
            int256(0),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.ReceiveItem))
        ];

        // Applied Actions (Boost equivalents of Evironment Actions)
        actions[Action.MoveRight] = [
            int256(0),
            int256(-1),
            int256(1),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];
        actions[Action.MoveLeft] = [
            int256(0),
            int256(-1),
            int256(-1),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];
        actions[Action.Explode] = [
            int256(-3),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];
        actions[Action.NoneBoost] = [
            int256(0),
            int256(0),
            int256(0),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];
        actions[Action.SlowDownMoveLeft] = [
            int256(-4),
            int256(-4),
            int256(-1),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];
        actions[Action.SlowDownMoveRight] = [
            int256(-4),
            int256(-4),
            int256(1),
            int256(0),
            int256(uint256(ActionType.Boost))
        ];

        _appliedAction[Action.LaneSwitchRight] = Action.MoveRight;
        _appliedAction[Action.LaneSwitchLeft] = Action.MoveLeft;
        _appliedAction[Action.DropMine] = Action.Explode;
        _appliedAction[Action.ShootMissile] = Action.Explode;
        _appliedAction[Action.ShootSlowDown] = Action.SlowDown;
        _appliedAction[Action.None] = Action.NoneBoost;
        _appliedAction[Action.SpinoutLeft] = Action.SlowDownMoveLeft;
        _appliedAction[Action.SpinoutRight] = Action.SlowDownMoveRight;
    }

    function withdrawLink() public onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) > _vrfFee,
            "Not enough LINK in contract"
        );
        return requestRandomness(_vrfKeyHash, _vrfFee);
    }

    function getRace(uint256 raceID) public view returns (RaceLog memory race) {
        return races[raceID];
    }

    function getEnvironmentAction(
        uint256 raceID,
        uint256 space,
        uint256 lane
    ) public view returns (Action) {
        return environmentActions[raceID][space][lane];
    }

    function getActiveProjectiles(uint256 raceID)
        public
        view
        returns (uint256[5][] memory projectiles)
    {
        projectiles = activeProjectiles[raceID];
        for (uint256 i = 0; i < projectiles.length; i++) {
            projectiles[i][1] = RaceUtilities.lapPosition(
                projectiles[i][1],
                races[raceID].spaces
            )[1];
        }
    }

    function submitUserChoices(
        uint256 itemIndex,
        uint256 newLane,
        uint256 raceID,
        uint256 racerID
    ) public {
        // require(
        //     currentPhase[raceID] == Phase.Play,
        //     "Can only submit moves during play phase"
        // );
        //TODO: require ownership / car is in race
        //require(msg.sender == Racer(racerContract).ownerOf(racerID), "Must own car to submit choices");
        if (itemIndex < 3) {
            useItem(itemIndex, raceID, racerID);
        }
        RaceLog memory race = races[raceID];
        if (newLane < Track(trackContract).lanes(race.trackId)) {
            chooseNewLane(newLane, raceID, racerID);
        }
    }

    // Adds item to actionQueue, will be applied on next update
    function useItem(
        uint256 itemIndex,
        uint256 raceID,
        uint256 racerID
    ) private {
        Track.Item[] storage inventory = itemInventory[raceID][racerID];
        Action selectedAction = Track(trackContract).itemAction(
            inventory[itemIndex]
        );

        require(uint256(selectedAction) < _possibleActions, "action not found");

        ActionType aType = ActionType(actions[selectedAction][4]);

        if (aType == ActionType.Boost || aType == ActionType.Invincibility) {
            // Add Boost / Invincibility Actions to Actions Queue
            actionsQueue[raceID][racerID].push(selectedAction);
            logActionUsed(selectedAction, raceID, racerID, 1);
        } else if (aType == ActionType.Environment) {
            // Add Evironment Action to Environment Actions
            uint256[2] memory lapSpace = RaceUtilities.lapPosition(
                currentPosition[raceID][racerID][0],
                races[raceID].spaces
            );
            environmentActions[raceID][lapSpace[1]][
                currentPosition[raceID][racerID][1]
            ] = selectedAction;
            logActionUsed(selectedAction, raceID, racerID, 0);
        } else if (aType == ActionType.Projectile) {
            // Add Projectile Action to Active Projectiles
            uint256[2] memory position = currentPosition[raceID][racerID];
            activeProjectiles[raceID].push(
                [
                    uint256(selectedAction),
                    position[0],
                    position[1],
                    uint256(actions[selectedAction][3]),
                    0
                ]
            );
            logActionUsed(selectedAction, racerID, racerID, 0);
        }

        // Remove action from itemInventory
        // only worry about first 3 slots
        if (inventory.length > 1 && itemIndex < (inventory.length - 1)) {
            inventory[itemIndex] = inventory[(inventory.length - 1)];
        }
        inventory.pop();
    }

    function chooseNewLane(
        uint256 newLane,
        uint256 raceID,
        uint256 racerID
    ) private {
        RaceLog memory race = races[raceID];
        uint256 numLanes = Track(trackContract).lanes(race.trackId);
        if (newLane >= 0 && newLane < numLanes) {
            laneChangesQueue[raceID][racerID] = newLane;
            wantsLaneChange[raceID][racerID] = true;
        }
    }

    function logActionUsed(
        Action a,
        uint256 raceID,
        uint256 racerID,
        uint256 updateOffset
    ) private {
        //[update, racer, action]
        if (a != Action.None && a != Action.NoneBoost) {
            RaceLog storage race = races[raceID];
            race.actionsUsed.push(
                [(race.updates + updateOffset), racerID, uint256(a)]
            );
        }
    }

    function startUpdates(uint256 raceID) external {
        //require(!_updating[raceID], "race already updating");
        //TODO: should only be callable from gameLoop contract.
        currentPhase[raceID] = Phase.Processing;
        _updating[raceID] = true;
        bytes32 reqId = getRandomNumber();
        randomRequestRaceID[reqId] = raceID;
        // callback will update race (must have enough LINK stored to update race on callback);
        emit PhaseEnd(raceID, "play");
        emit PhaseStart(raceID, "processing");
    }

    /**.......
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        uint256 raceID = randomRequestRaceID[requestId];
        RaceLog storage race = races[raceID];

        // save random number to use on update
        race.randomNumbers.push([(race.updates + 1), randomness]);

        // request update from update queue
        UpdateQueue(race.updateQueue).requestUpdate(raceID);
    }

    function expandRandomNumber(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function updateRace(uint256 raceID) public {
        //should only be called once random number is returned
        //TODO: Require UpdateQueue is only contract that can call this

        if (!allRacersFinished[raceID]) {
            RaceLog storage race = races[raceID];
            race.updates++;

            for (
                uint256 racerIndex = 0;
                racerIndex < race.racers.length;
                racerIndex++
            ) {
                uint256 racer = race.racers[racerIndex];
                if (!completedRace[raceID][racer]) {
                    int256[3] memory effects;
                    (
                        uint256 maxSpeed,
                        uint256 acceleration,
                        uint256 handling
                    ) = racerData.getBalancedData(racer);
                    if (currentPosition[raceID][racer][0] != 0) {
                        //apply pending actions
                        effects = applyPendingActions(raceID, racer);

                        if (int256(acceleration) + effects[1] > 0) {
                            acceleration = (
                                uint256(int256(acceleration) + effects[1])
                            );
                        } else {
                            acceleration = 0;
                        }
                    }
                    // Add speed boost after max potential speed is reached
                    if (currentSpeed[raceID][racer] + acceleration > maxSpeed) {
                        uint256 finalSpeed = maxSpeed;
                        currentSpeed[raceID][racer] = (int256(finalSpeed) +
                            effects[0]) > 0
                            ? uint256(int256(finalSpeed) + effects[0])
                            : 0;
                    } else {
                        uint256 finalSpeed = currentSpeed[raceID][racer] +
                            acceleration;
                        currentSpeed[raceID][racer] = (int256(finalSpeed) +
                            effects[0]) > 0
                            ? uint256(int256(finalSpeed) + effects[0])
                            : 0;
                    }

                    //apply user initiated lane changes
                    // use 1 speed for every lane changed
                    uint256 newLane = wantsLaneChange[raceID][racer]
                        ? laneChangesQueue[raceID][racer]
                        : currentPosition[raceID][racer][1];
                    uint256 distance = (currentPosition[raceID][racer][1] >
                        newLane)
                        ? currentPosition[raceID][racer][1] - newLane
                        : newLane - currentPosition[raceID][racer][1];
                    if (distance > currentSpeed[raceID][racer]) {
                        distance = currentSpeed[raceID][racer];
                        newLane = (currentPosition[raceID][racer][1] > newLane)
                            ? currentPosition[raceID][racer][1] - distance
                            : currentPosition[raceID][racer][1] + distance;
                    }

                    // move racer sideways to lane + forward to new space, totaling "speed" # of moves
                    moveRacer(
                        raceID,
                        racer,
                        (currentPosition[raceID][racer][0] +
                            (currentSpeed[raceID][racer] - distance)),
                        newLane
                    );
                    race.laneChanges.push([race.updates, racer, newLane]);

                    if (currentPosition[raceID][racer][0] != 0) {
                        //environment actions
                        applyEnvironmentActions(raceID, racer, effects[2]);
                    }
                }
            }

            applyProjectileActions(raceID);

            race.lastUpdate = block.timestamp;

            // adjust race order and mark as finished

            checkForFinishers(raceID);

            if (allRacersFinished[raceID]) {
                currentPhase[raceID] = Phase.Complete;
                emit RaceComplete(raceID);
            } else {
                currentPhase[raceID] = Phase.Play;
                emit PhaseStart(raceID, "play");
            }

            _updating[raceID] = false;
        }
    }

    function applyEnvironmentActions(
        uint256 raceID,
        uint256 racerID,
        int256 invincible
    ) internal {
        // apply environment actions (actions landed on will execute at start of next turn)
        logActionUsed(
            _appliedAction[
                environmentActions[raceID][
                    RaceUtilities.lapPosition(
                        currentPosition[raceID][racerID][0],
                        races[raceID].spaces
                    )[1]
                ][currentPosition[raceID][racerID][1]]
            ],
            raceID,
            racerID,
            1
        );

        bool isInvincible = invincible == 1 ? true : false;
        if (!isInvincible) {
            // move environment actions into actions queue
            actionsQueue[raceID][racerID].push(
                _appliedAction[
                    environmentActions[raceID][
                        RaceUtilities.lapPosition(
                            currentPosition[raceID][racerID][0],
                            races[raceID].spaces
                        )[1]
                    ][currentPosition[raceID][racerID][1]]
                ]
            );
        }

        //TODO: apply to all cars at space
        // reset space since action has been used
        environmentActions[raceID][
            RaceUtilities.lapPosition(
                currentPosition[raceID][racerID][0],
                races[raceID].spaces
            )[1]
        ][currentPosition[raceID][racerID][1]] = Action.None;

        // apply environment actions from track spaces (permanent actions)
        Track tContract = Track(trackContract);
        RaceLog storage race = races[raceID];

        //position = [lap, space, lane]
        uint256[3] memory position = RaceUtilities.positionToLapLanePosition(
            currentPosition[raceID][racerID],
            races[raceID].spaces
        );

        //space = [item, enabled, terrain, terrainIgnoresInvincibility]
        uint256[4] memory space = tContract.getSpaces(race.trackId)[
            (position[1])
        ][(position[2])];

        // add to actionsQueue if not invincible or if invincibility is ignored
        bool performTerrainAction = isInvincible
            ? space[3] == 0 ? false : true
            : true;
        if (performTerrainAction) {
            Action tAction = tContract.terrainAction(Track.Terrain(space[2]));
            actionsQueue[raceID][racerID].push(tAction);
            logActionUsed(tAction, raceID, racerID, 1);
        }

        //pick up item if available
        if (space[1] == 1 && space[0] != 0) {
            Track.Item itemPickup;
            // add to inventory & log in race
            if (Track.Item(space[0]) == Track.Item.MysteryBox) {
                //TODO: use random number for given lane to determine what item to receive
                uint256 baseRandomness = race.randomNumbers[
                    (race.randomNumbers.length - 1)
                ][1];
                uint256 customRandomness = uint256(
                    keccak256(abi.encode(baseRandomness, racerID))
                );
                Track.Item[5] memory mysteryBoxPossibilities = [
                    Track.Item.Banana,
                    Track.Item.SpeedBoost,
                    Track.Item.Mushroom,
                    Track.Item.Invincibility,
                    Track.Item.Missile
                ];
                uint256 itemIndex = customRandomness %
                    (mysteryBoxPossibilities.length);
                itemPickup = mysteryBoxPossibilities[itemIndex];
            } else {
                itemPickup = Track.Item(space[0]);
            }

            if (itemPickup != Track.Item.None) {
                Track.Item[] storage inventory = itemInventory[raceID][racerID];
                if (itemInventory[raceID][racerID].length >= 3) {
                    //can only hold 3 items, remove oldest item and shift rest down
                    inventory[0] = inventory[1];
                    inventory[1] = inventory[2];
                    inventory[2] = itemPickup;
                } else {
                    inventory.push(itemPickup);
                }
                race.itemsAcquired.push(
                    [race.updates, racerID, uint256(itemPickup)]
                );
            }
        }
    }

    function applyPendingActions(uint256 raceID, uint256 racerID)
        internal
        returns (int256[3] memory)
    {
        int256[3] memory effects;
        Action[] storage aQueue = actionsQueue[raceID][racerID];
        if (aQueue.length > 0) {
            for (uint256 i = aQueue.length - 1; i >= 0; i--) {
                Action a = aQueue[i];
                int256[5] memory actionProps = actions[a]; // [speedAdjust, accelerationAdjust, laneAdjust, lifespan, actionType]
                //good to here...
                ActionType aType = ActionType(actionProps[4]);

                // Should only be of types Boost or invincible
                // (Environment and Projectile actions use separate queues)
                if (aType == ActionType.Boost) {
                    // apply boost to self if not invincible
                    effects[0] += actionProps[0];
                    effects[1] += actionProps[1];
                } else if (aType == ActionType.Invincibility) {
                    // set flag to invincible effect for this turn
                    effects[2] = 1;
                }

                aQueue.pop();
                if (i == 0) {
                    break;
                }
            }
        }
        return effects;
    }

    function applyProjectileActions(uint256 raceID) private {
        uint256[5][] storage projectiles = activeProjectiles[raceID];
        if (projectiles.length > 0) {
            for (uint256 i = projectiles.length - 1; i >= 0; i--) {
                //uint256[5][] public activeProjectiles; // [[Action, space, lane, remainingLifespan, currentSpeed], [Action, space, lane, remainingLifespan]]
                //mapping(Action => uint256[2]) public projectileSpeedAcceleration

                // move forward
                uint256[5] storage projectile = projectiles[i];
                uint256[2]
                    memory speedAcceleration = projectileSpeedAcceleration[
                        Action(projectile[0])
                    ];
                uint256 pSpeed = projectile[4] + speedAcceleration[1] >
                    speedAcceleration[0]
                    ? speedAcceleration[0]
                    : projectile[4] + speedAcceleration[1];

                // adjust to remaining lifespan if necessary
                if (pSpeed > projectile[3]) {
                    pSpeed = projectile[3];
                }

                // [absolute start space, absolute end space]
                uint256[2] memory projectilePath = [
                    projectile[1],
                    projectile[1] + pSpeed
                ];

                bool used = applyProjectileToRacers(
                    raceID,
                    projectile,
                    projectilePath
                );

                // if projectile didn't get used in flight...
                if (!used) {
                    if (projectile[3] > pSpeed) {
                        //reduce lifespan
                        projectile[3] -= pSpeed;
                        projectile[1] += pSpeed;
                        projectile[4] = pSpeed;
                    } else {
                        // remove from projectiles
                        projectiles.pop();
                    }
                } else {
                    // used on racer(s)
                    projectiles.pop();
                }
                if (i == 0) {
                    break;
                }
            }
        }
    }

    function applyProjectileToRacers(
        uint256 raceID,
        uint256[5] memory projectile,
        uint256[2] memory projectilePath
    ) public returns (bool shouldDelete) {
        RaceLog memory race = races[raceID];
        shouldDelete = false;

        for (uint256 j = 0; j < race.racers.length; j++) {
            if (!completedRace[raceID][race.racers[j]]) {
                uint256 racerSpace = currentPosition[raceID][race.racers[j]][0];
                uint256 rDistance;
                uint256 further;

                // compare car end and missile end (should put racer space as first argument)
                (rDistance, further) = RaceUtilities.relativeDistance(
                    racerSpace,
                    projectilePath[1],
                    races[raceID].spaces
                );
                if (further == 1) {
                    // racer space is further
                    // projectile does not interact
                } else {
                    (rDistance, further) = RaceUtilities.relativeDistance(
                        racerSpace,
                        projectilePath[0],
                        races[raceID].spaces
                    );
                    // projectile path end is past vehicle
                    // check starting point
                    if (further == 1) {
                        // vehicle started after projectile, projectile affects vehicle
                        actionsQueue[raceID][race.racers[j]].push(
                            _appliedAction[Action(projectile[0])]
                        );
                        shouldDelete = true;
                    }
                }
            }
        }
    }

    function checkForFinishers(uint256 raceID) private {
        RaceLog storage race = races[raceID];
        bool allFinished = allRacersFinished[raceID];
        if (!allFinished) {
            uint256 finalSpace = (race.spaces * race.laps) - 1;
            for (uint256 i = 0; i < race.racers.length; i++) {
                if (!completedRace[raceID][race.racers[i]]) {
                    uint256 racerSpace = currentPosition[raceID][
                        race.racers[i]
                    ][0];
                    if (racerSpace > finalSpace) {
                        completedRace[raceID][race.racers[i]] = true;
                        race.results.push([race.racers[i], racerSpace]);
                    }
                }
            }
            allFinished = true;
            for (uint256 i = 0; i < race.racers.length; i++) {
                if (!completedRace[raceID][race.racers[i]]) {
                    allFinished = false;
                    break;
                }
            }

            if (allFinished) {
                allRacersFinished[raceID] = true;
            }
        }
    }

    function moveRacer(
        uint256 raceID,
        uint256 racerID,
        uint256 space,
        uint256 lane
    ) internal {
        currentPosition[raceID][racerID] = [space, lane];
    }

    function registerRace(
        uint256 trackID,
        uint256 entryFee,
        uint8 numLaps,
        address gameLoop,
        address updateQueue
    ) public returns (uint256 raceID) {
        _currentID++;
        uint256 spaces = Track(trackContract).getSpaces(trackID).length;
        // # spaces locked in at time of race registration
        // prevents tracks from changing after races started
        raceID = _currentID;
        RaceLog memory newLog;
        newLog.id = _currentID;
        newLog.coordinator = msg.sender;
        newLog.trackId = trackID;
        newLog.entryFee = entryFee;
        newLog.spaces = spaces;
        newLog.laps = numLaps;
        newLog.lastUpdate = block.timestamp;
        newLog.gameLoop = gameLoop;
        newLog.updateQueue = updateQueue;
        races[_currentID] = newLog;
        registeredRaces[msg.sender].push(raceID);
        _updating[_currentID] = false;
    }

    function startRace(uint256 raceID) public {
        //TODO:
        //require(races[raceID].coordinator == msg.sender());
        //require(currentPhase[raceID] == Phase.None);
        currentPhase[raceID] = Phase.Play;
        emit RaceStart(raceID);
    }

    function getMyRaces() public view returns (uint256[] memory myRaces) {
        return registeredRaces[msg.sender];
    }

    function isInRace(uint256 raceID)
        public
        view
        returns (bool inRace, uint256 racerID)
    {
        inRace = false;
        for (uint256 i = 0; i < races[raceID].racers.length; i++) {
            if (racerData.isOwner(msg.sender, races[raceID].racers[i])) {
                inRace = true;
                racerID = races[raceID].racers[i];
                break;
            }
        }
    }

    function enterRace(
        uint256 raceID,
        uint256 racerID,
        uint256 startingLane
    ) public {
        //TODO:
        // change to external, should only be called from RaceQueue
        RaceLog storage race = races[raceID];
        race.racers.push(racerID);

        //TODO: set initial racer position somehow
        uint256 totalLanes = Track(trackContract).getTotalLanes(race.trackId);
        if (startingLane < totalLanes) {
            currentPosition[raceID][racerID] = [0, startingLane];
        } else {
            currentPosition[raceID][racerID] = [0, 0];
        }
    }

    //returns [[racer, lap, space, lane], [racer, lap, space,lane]]
    function getCurrentPositions(uint256 raceID)
        public
        view
        returns (uint256[4][] memory racerPositions)
    {
        RaceLog memory race = races[raceID];
        uint256[4][] memory positions = new uint256[4][](race.racers.length);
        for (uint256 i = 0; i < race.racers.length; i++) {
            uint256 c = race.racers[i];
            uint256[3] memory llp = RaceUtilities.positionToLapLanePosition(
                currentPosition[raceID][c],
                races[raceID].spaces
            );
            positions[i] = [c, llp[0], llp[1], llp[2]];
        }
        return positions;
    }

    function getCurrentStats(uint256 raceID, uint256 racerID)
        public
        view
        returns (uint256 speed, uint256[3] memory lapLanePosition)
    {
        return (
            currentSpeed[raceID][racerID],
            RaceUtilities.positionToLapLanePosition(
                currentPosition[raceID][racerID],
                races[raceID].spaces
            )
        );
    }

    function getItemInventory(uint256 raceID, uint256 racerID)
        public
        view
        returns (Track.Item[] memory inventory)
    {
        return itemInventory[raceID][racerID];
    }

    function getRacers(uint256 raceID) public view returns (uint256[] memory) {
        return races[raceID].racers;
    }

    function getCoordinator(uint256 raceID)
        public
        view
        returns (address raceCoordinator)
    {
        return races[raceID].coordinator;
    }

    function isRaceFinished(uint256 raceID)
        public
        view
        returns (bool isFinished)
    {
        return allRacersFinished[raceID];
    }

    function getResults(uint256 raceID)
        public
        view
        returns (uint256[2][] memory)
    {
        return races[raceID].results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}