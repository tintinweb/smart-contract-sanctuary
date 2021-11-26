// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "VRFConsumerBase.sol";

contract RegisteredBillionairesChainlinkVRFConsumer is
    Ownable,
    VRFConsumerBase
{
    struct AirDropEvent {
        string name;
        bool registrationLocked;
        mapping(uint256 => bool) registeredBillionaireIds;
        uint256 registeredBillionaireCount;
        uint256 lockedBlockNumber;
    }

    struct RandomSeedInfo {
        bytes32 chainLinkRequestId;
        uint256 createdBlockNumber;
        uint256 seedValue;
    }

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public currentRandomIndex;
    uint256 public constant BB_SUPPLY = 13337;
    mapping(uint256 => RandomSeedInfo) public randomSeedHistory;
    mapping(string => AirDropEvent) public _events;

    /**
     * Constructor inherits VRFConsumerBase
     */

    //UNCOMMENT FOR POLYGON MAINNET
    constructor()
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1 // LINK Token
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10**18; // 0.1 Polygon (Varies by network)
    }

    // //UNCOMMENT FOR Mumbai TESTNET
    // constructor()
    //     VRFConsumerBase(
    //         0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
    //         0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
    //     )
    // {
    //     keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    //     fee = 0.0001 * 10**18; // 0.1 Polygon (Varies by network)
    // }

    /**
     * Requests randomness
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 newIndex = ++currentRandomIndex;
        randomSeedHistory[newIndex].chainLinkRequestId = requestId;
        randomSeedHistory[newIndex].createdBlockNumber = block.number;
        randomSeedHistory[newIndex].seedValue = randomness;
    }

    /**
     * Use solidity PRNG to generate random number for a given Chainlink seed
     */
    function randomNumberFromSeedIndex(uint256 seedIndex, uint256 rollNumber)
        public
        view
        returns (uint256)
    {
        uint256 seed = randomSeedHistory[seedIndex].seedValue;
        require(seed > 0, "No seed exists at the provided index");
        uint256 random = uint256(
            keccak256(abi.encodePacked("Seed:", seed, "Roll:", rollNumber))
        );
        return random;
    }

    /**
     * Use solidity PRNG to generate random number for a given Chainlink seed
     */
    function randomNumberFromSeedIndex(
        uint256 seedIndex,
        uint256 rollNumber,
        uint256 iterationNumber
    ) internal view returns (uint256) {
        uint256 seed = randomSeedHistory[seedIndex].seedValue;
        require(seed > 0, "No seed exists at the provided index");
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    "Seed:",
                    seed,
                    "Roll:",
                    rollNumber,
                    "Iteration:",
                    iterationNumber
                )
            )
        );
        return random;
    }

    function convertRandomNumberToBillionaireIndex(uint256 random)
        public
        pure
        returns (uint256)
    {
        return (random % BB_SUPPLY) + 1;
    }

    function getBillionaireForGiveaway(
        uint256 seedIndex,
        uint256 rollNumber,
        string calldata airdropEventTag
    ) public view returns (uint256) {
        AirDropEvent storage airDropEvent = _events[airdropEventTag];
        require(
            airDropEvent.registrationLocked,
            "The registration list for this giveaway is not yet confirmed"
        );
        require(
            airDropEvent.registeredBillionaireCount > 1,
            "The registration list for this giveaway is not yet uploaded"
        );
        uint256 winningBillionaireIndex = 0;
        //Can't use billionaireID as the input for iteration, as there's a small chance of infinite loop
        uint256 iterationNumber = 0;
        //If the mapping is false then our current winner isn't registered (oof) so we roll a new one until we hit a registered Id
        while (
            !airDropEvent.registeredBillionaireIds[winningBillionaireIndex]
        ) {
            uint256 randomRolledNumber = randomNumberFromSeedIndex(
                seedIndex,
                rollNumber,
                ++iterationNumber
            );
            winningBillionaireIndex = convertRandomNumberToBillionaireIndex(
                randomRolledNumber
            );
        }
        return winningBillionaireIndex;
    }

    function getBillionaireRegistered(
        string calldata eventName,
        uint256 billionaireId
    ) public view returns (bool) {
        AirDropEvent storage ev = _events[eventName];
        return ev.registeredBillionaireIds[billionaireId];
    }

    function createAirDropEvent(string calldata eventName) public onlyOwner {
        require(
            keccak256(bytes(eventName)) != keccak256(bytes("")),
            "Please enter an event name"
        );
        AirDropEvent storage ev = _events[eventName];
        require(
            keccak256(bytes(ev.name)) != keccak256(bytes(eventName)),
            "Already an AirDrop event with this name"
        );
        require(!ev.registrationLocked, "Registration locked for this event");
        ev.name = eventName;
    }

    function lockAirDropEvent(string calldata eventName) public onlyOwner {
        require(
            keccak256(bytes(eventName)) != keccak256(bytes("")),
            "Please enter an event name"
        );
        AirDropEvent storage ev = _events[eventName];
        require(
            ev.registeredBillionaireCount > 1,
            "No registrations for event yet"
        );
        require(!ev.registrationLocked, "Registration locked for this event");
        ev.registrationLocked = true;
        ev.lockedBlockNumber = block.number;
    }

    function addRegistrationsToEvent(
        uint256[] calldata billionaireIds,
        string calldata eventName
    ) public onlyOwner {
        require(
            keccak256(bytes(eventName)) != keccak256(bytes("")),
            "Please enter an event name"
        );
        AirDropEvent storage ev = _events[eventName];
        require(!ev.registrationLocked, "Registration locked for this event");
        require(
            keccak256(bytes(ev.name)) != keccak256(bytes("")),
            "The named event does not exist"
        );

        for (uint256 i = 0; i < billionaireIds.length; i++) {
            ev.registeredBillionaireIds[billionaireIds[i]] = true;
            ev.registeredBillionaireCount++;
        }
    }
}