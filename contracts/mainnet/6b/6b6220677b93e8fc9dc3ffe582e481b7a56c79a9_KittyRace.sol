pragma solidity ^0.4.21;

contract KittyRace {
    struct Race {
        uint32 blockJoinedFirstRacer;
        uint32 blockJoinedLastRacer;
        Racer[] racers;
    }

    struct Racer {
        address kittyOwner;
        uint256 kittyId;
    }

    event RegisterEvent(
        uint32 raceId,
        address kittyAddress,
        uint256 kittyId,
        uint256 position
    );

    event RaceEvent(
        uint32 raceId,
        uint256 numRacers,
        uint256 winnerKittyId
    );

    event PayoutEvent(
        uint32 raceId,
        address winnerKittyAddress,
        uint256 winnerAmount,
        bool winnerTxError,
        address processingAddress,
        uint256 processingAmount,
        bool processingTxError
    );

    // Contract owner
    address public owner;

    // KittyCore contract reference
    address public kittyCoreAddress;
    KittyCoreI kittyCore;

    // Pause button
    bool gameOn = true;

    // Precise payment value required to registerForRace(). This can be
    // updated by the owner role as the gas or fiat prices adjust.
    uint256 public entryFee = 0.005 ether;
    uint256 public processingFee = 0.0005 ether; // paid from each entry fee to whoever successfully calls race() function
    uint8 public registrationPeriod = 25; // number of blocks after race creation others can join
    uint8 public maxRacers = 10; // maximum number of racers allowed for single race

    uint32 public raceId = 0;
    mapping (uint256 => Race) public races;
    mapping (uint256 => bool) public activeRacers;
    mapping (uint256 => bool) public completedRaces;

    // Slight advantage for Kitties with the following genes
    // Array of arrays: [ gene mask, gene value, skill value ]
    uint256[][] geneMasks = [
        [ uint256(0x0000000000000000000000000000000000000000001f00000000000000000000), uint256(0x0000000000000000000000000000000000000000000500000000000000000000), uint256(2) ], // mauveover (D) - colorprimary
        [ uint256(0x000000000000000000000000000000000000000003e000000000000000000000), uint256(0x000000000000000000000000000000000000000000a000000000000000000000), uint256(1) ], // mauveover (R1) - colorprimary
        [ uint256(0x000000000000000000000000000000000000000000000001f000000000000000), uint256(0x0000000000000000000000000000000000000000000000019000000000000000), uint256(2) ], // wingtips (D) - eyes
        [ uint256(0x00000000000000000000000000000000000000000000003e0000000000000000), uint256(0x0000000000000000000000000000000000000000000000320000000000000000), uint256(1) ], // wingtips (R1) - eyes
        [ uint256(0x00000000000000000000000000000000000001f0000000000000000000000000), uint256(0x00000000000000000000000000000000000000c0000000000000000000000000), uint256(2) ], // coffee (D) - colorsecondary
        [ uint256(0x0000000000000000000000000000000000003e00000000000000000000000000), uint256(0x0000000000000000000000000000000000001800000000000000000000000000), uint256(1) ], // coffee (R1) - colorsecondary
        [ uint256(0x0000000000000000000000000000000000000000000000000000000001f00000), uint256(0x0000000000000000000000000000000000000000000000000000000000900000), uint256(2) ], // luckystripe (D) - pattern
        [ uint256(0x000000000000000000000000000000000000000000000000000000003e000000), uint256(0x0000000000000000000000000000000000000000000000000000000012000000), uint256(1) ], // luckystripe (R1) - pattern
        [ uint256(0x0000000000000000000000000000000000000000000000000000000001f00000), uint256(0x0000000000000000000000000000000000000000000000000000000000b00000), uint256(2) ], // jaguar (D) - pattern
        [ uint256(0x000000000000000000000000000000000000000000000000000000003e000000), uint256(0x0000000000000000000000000000000000000000000000000000000016000000), uint256(1) ]  // jaguar (R1) - pattern
    ];

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function KittyRace(address _kittyCoreAddress) public {
        owner = msg.sender;
        kittyCoreAddress = _kittyCoreAddress;
        kittyCore = KittyCoreI(kittyCoreAddress);
    }

    function kill() public onlyOwner {
        // Contract cannot be killed after midnight, April 1, 2018 (Pacific)
        require(now < 1522566000);

        selfdestruct(owner);
    }

    function setEntryFee(uint256 _entryFee) public onlyOwner { entryFee = _entryFee; }
    function setProcessingFee(uint256 _processingFee) public onlyOwner { processingFee = _processingFee; }
    function setRegistrationPeriod(uint8 _registrationPeriod) public onlyOwner { registrationPeriod = _registrationPeriod; }
    function setMaxRacers(uint8 _maxRacers) public onlyOwner { maxRacers = _maxRacers; }
    function setGameOn(bool _gameOn) public onlyOwner { gameOn = _gameOn; }

    function setKittyCoreAddress(address _kittyCoreAddress)
        public
        onlyOwner
    {
        kittyCoreAddress = _kittyCoreAddress;
        kittyCore = KittyCoreI(kittyCoreAddress);
    }

    function getRace(uint32 _raceId)
        public
        view
        returns (uint256 blockJoinedFirstRacer, uint256 blockJoinedLastRacer, uint256 numRacers)
    {
        return (races[_raceId].blockJoinedFirstRacer, races[_raceId].blockJoinedLastRacer, races[_raceId].racers.length);
    }

    function getRacer(uint32 _raceId, uint256 _racerIndex)
        public
        view
        returns (address kittyOwner, uint256 kittyId)
    {
        Racer storage racer = races[_raceId].racers[_racerIndex];
        return (racer.kittyOwner, racer.kittyId);
    }

    function registerForRace(uint256 _kittyId)
        external
        payable
        returns (uint256)
    {
        require(gameOn);

        // Confirm precise entry fee was provided
        require(msg.value == entryFee);

        // Confirm sender owns the Kitty
        require(msg.sender == kittyCore.ownerOf(_kittyId));

        // Confirm Kitty is not currently in another race
        require(activeRacers[_kittyId] != true);

        Race storage race = races[raceId];

        // Create new race if current race is completed or full
        if (completedRaces[raceId] || race.racers.length >= maxRacers) {
            raceId += 1;
            race = races[raceId];
        }

        // Separated from statement above to function for first racer of first race
        if (race.racers.length == 0) {
            race.blockJoinedFirstRacer = uint32(block.number);
        }
        race.blockJoinedLastRacer = uint32(block.number);

        Racer memory racer = Racer({
            kittyOwner: msg.sender,
            kittyId: _kittyId
        });

        race.racers.push(racer);

        activeRacers[_kittyId] = true;

        emit RegisterEvent(
            raceId,
            racer.kittyOwner,
            racer.kittyId,
            race.racers.length - 1 // Race position
        );

        return raceId;
    }

    function race(uint32 _raceId)
        external
        returns (uint256)
    {
        uint256 numRacers = races[_raceId].racers.length;

        // Is race full, if not, have racers had enough time to join?
        require(numRacers >= maxRacers || block.number > races[_raceId].blockJoinedFirstRacer + registrationPeriod);

        // Enough unique block hashes to provide random roll for each racer?
        require(block.number > races[_raceId].blockJoinedLastRacer + numRacers);

        Racer memory racer;
        Racer memory winner = races[_raceId].racers[0];
        uint8 raceScore;
        uint8 highScore = 0;

        // Calc finishing order
        for(uint i = 0; i < numRacers; i++) {
            racer = races[_raceId].racers[i];
            // Genetic skill score
            raceScore = getKittySkillScore(racer.kittyId);
            // Random chance score
            raceScore += uint8(block.blockhash(races[_raceId].blockJoinedLastRacer + numRacers - i)) % 20;
            // First and second entry incentives
            if (i == 0) { raceScore += 2; } // First to join
            if (i == 1) { raceScore += 1; } // Second to join

            if (raceScore > highScore) {
                winner = racer;
                highScore = raceScore;
            }

            delete activeRacers[racer.kittyId];
        }

        emit RaceEvent(
            _raceId,
            numRacers,
            winner.kittyId
        );

        emit PayoutEvent(
            _raceId,
            winner.kittyOwner,
            (entryFee * numRacers) - (processingFee * numRacers),
            !winner.kittyOwner.send((entryFee * numRacers) - (processingFee * numRacers)),
            msg.sender,
            processingFee * numRacers,
            !msg.sender.send(processingFee * numRacers)
        );

        completedRaces[_raceId] = true;
        delete races[_raceId];

        return winner.kittyId;
    }

    function getKittySkillScore(uint256 _kittyId)
        private
        view
        returns (uint8)
    {
        uint256 genes;
        ( , , , , , , , , , genes) = kittyCore.getKitty(_kittyId);

        uint8 skillScore;
        for(uint8 i = 0; i < geneMasks.length; i++) {
            if (genes & geneMasks[i][0] == geneMasks[i][1]) {
                skillScore += uint8(geneMasks[i][2]);
            }
        }

        return skillScore;
    }
}

// Barebones interface to CryptoKitties contract
contract KittyCoreI {
    function getKitty(uint _id) public returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );

    function ownerOf(uint256 _tokenId) public view returns (address owner);
}