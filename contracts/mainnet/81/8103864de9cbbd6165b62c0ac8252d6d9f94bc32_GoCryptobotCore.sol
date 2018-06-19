pragma solidity ^0.4.18;

contract GoCryptobotAccessControl {
    address public owner;
    address public operator;

    bool public paused;

    modifier onlyOwner() {require(msg.sender == owner); _;}
    modifier onlyOperator() {require(msg.sender == operator); _;}
    modifier onlyOwnerOrOperator() {require(msg.sender == owner || msg.sender == operator); _;}

    modifier whenPaused() {require(paused); _;}
    modifier whenNotPaused() {require(!paused); _;}

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function transferOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0));
        operator = newOperator;
    }

    function pause() public onlyOwnerOrOperator whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract GoCryptobotRandom is GoCryptobotAccessControl {
    uint commitmentNumber;
    bytes32 randomBytes;

    function commitment() public onlyOperator {
        commitmentNumber = block.number;
    }

    function _initRandom() internal {
        require(commitmentNumber < block.number);

        if (commitmentNumber < block.number - 255) {
            randomBytes = block.blockhash(block.number - 1);
        } else {
            randomBytes = block.blockhash(commitmentNumber);
        }
    }

    function _shuffle(uint8[] deck) internal {
        require(deck.length < 256);

        uint8 deckLength = uint8(deck.length);
        uint8 random;
        for (uint8 i = 0; i < deckLength; i++) {
            if (i % 32 == 0) {
                randomBytes = keccak256(randomBytes);
            }
            random = uint8(randomBytes[i % 32]) % (deckLength - i);

            if (random != deckLength - 1 - i) {
                deck[random] ^= deck[deckLength - 1 - i];
                deck[deckLength - 1 - i] ^= deck[random];
                deck[random] ^= deck[deckLength - 1 - i];
            }
        }
    }

    function _random256() internal returns(uint256) {
        randomBytes = keccak256(randomBytes);
        return uint256(randomBytes);
    }
}

contract GoCryptobotScore is GoCryptobotRandom {
    // A part&#39;s skill consists of color and level. (Total 2 bytes)
    //   1   2
    // Skill
    // +---+---+
    // | C | L +
    // +---+---+
    //
    // C = Color, 0 ~ 4.
    // L = Level, 0 ~ 8.
    //
    uint256 constant PART_SKILL_SIZE = 2;

    // A part consists of level and 3 skills. (Total 7 bytes)
    //   1   2   3   4   5   6   7
    // Part
    // +---+---+---+---+---+---+---+
    // | L | Skill | Skill | Skill |
    // +---+---+---+---+---+---+---+
    //
    // L = Level, 1 ~ 50.
    //
    // A part doesn&#39;t contains color because individual color doesn&#39;t affect to
    // the score, but it is used to calculate player&#39;s theme color.
    //
    uint256 constant PART_BASE_SIZE = 1;
    uint256 constant PART_SIZE = PART_BASE_SIZE + 3 * PART_SKILL_SIZE;

    // A player consists of theme effect and 4 parts. (Total 29 bytes)
    //   1   2   3   4   5   6   7
    // Player
    // +---+
    // | C |
    // +---+---+---+---+---+---+---+
    // |         HEAD PART         |
    // +---+---+---+---+---+---+---+
    // |         BODY PART         |
    // +---+---+---+---+---+---+---+
    // |         LEGS PART         |
    // +---+---+---+---+---+---+---+
    // |         BOOSTER PART      |
    // +---+---+---+---+---+---+---+
    //
    // C = Whether player&#39;s theme effect is enabled or not, 1 or 0.
    //
    // The theme effect is set to 1 iff the theme of each part are identical.
    //
    uint256 constant PLAYER_BASE_SIZE = 1;
    uint256 constant PLAYER_SIZE = PLAYER_BASE_SIZE + PART_SIZE * 4;

    enum PartType {HEAD, BODY, LEGS, BOOSTER}
    enum EventType {BOWLING, HANGING, SPRINT, HIGH_JUMP}
    enum EventColor {NONE, YELLOW, BLUE, GREEN, RED}

    function _getPartLevel(bytes data, uint partOffset) internal pure returns(uint8) {
        return uint8(data[partOffset + 0]);
    }
    // NOTE: _getPartSkillColor is called up to 128 * 4 * 3 times. Explicit
    // conversion to EventColor could be costful.
    function _getPartSkillColor(bytes data, uint partOffset, uint skillIndex) internal pure returns(byte) {
        return data[partOffset + PART_BASE_SIZE + (skillIndex * PART_SKILL_SIZE) + 0];
    }
    function _getPartSkillLevel(bytes data, uint partOffset, uint skillIndex) internal pure returns(uint8) {
        return uint8(data[partOffset + PART_BASE_SIZE + (skillIndex * PART_SKILL_SIZE) + 1]);
    }

    function _getPlayerThemeEffect(bytes data, uint playerOffset) internal pure returns(byte) {
        return data[playerOffset + 0];
    }

    function _getPlayerEventScore(bytes data, uint playerIndex, EventType eventType, EventColor _eventMajorColor, EventColor _eventMinorColor) internal pure returns(uint) {
        uint partOffset = (PLAYER_SIZE * playerIndex) + PLAYER_BASE_SIZE + (uint256(eventType) * PART_SIZE);
        uint level = _getPartLevel(data, partOffset);
        uint majorSkillSum = 0;
        uint minorSkillSum = 0;

        byte eventMajorColor = byte(uint8(_eventMajorColor));
        byte eventMinorColor = byte(uint8(_eventMinorColor));
        for (uint i = 0; i < 3; i++) {
            byte skillColor = _getPartSkillColor(data, partOffset, i);
            if (skillColor == eventMajorColor) {
                majorSkillSum += _getPartSkillLevel(data, partOffset, i);
            } else if (skillColor == eventMinorColor) {
                minorSkillSum += _getPartSkillLevel(data, partOffset, i);
            }
        }
        byte playerThemeEffect = _getPlayerThemeEffect(data, PLAYER_SIZE * playerIndex);
        if (playerThemeEffect != 0) {
            return level + (majorSkillSum * 4) + (minorSkillSum * 2);
        } else {
            return level + (majorSkillSum * 3) + (minorSkillSum * 1);
        }
    }
}

contract GoCryptobotRounds is GoCryptobotScore {
    event RoundFinished(EventType eventType, EventColor eventMajorColor, EventColor eventMinorColor, uint scoreA, uint scoreB, uint scoreC, uint scoreD);
    event AllFinished(uint scoreA, uint scoreB, uint scoreC, uint scoreD);
    event WinnerTeam(uint8[4] candidates, uint8 winner);

    function run(bytes playerData, uint8[4] eventTypes, uint8[2][4] eventColors) public onlyOperator {
        require(playerData.length == 128 * PLAYER_SIZE);

        _initRandom();

        uint8[] memory colorSelection = new uint8[](8);
        colorSelection[0] = 0;
        colorSelection[1] = 1;
        colorSelection[2] = 0;
        colorSelection[3] = 1;
        colorSelection[4] = 0;
        colorSelection[5] = 1;
        colorSelection[6] = 0;
        colorSelection[7] = 1;

        _shuffle(colorSelection);

        uint[4] memory totalScores;
        for (uint8 i = 0; i < 4; i++) {
            uint8 majorColor = eventColors[i][colorSelection[i]];
            uint8 minorColor = eventColors[i][colorSelection[i]^1];
            uint[4] memory roundScores = _round(playerData, EventType(eventTypes[i]), EventColor(majorColor), EventColor(minorColor));
            totalScores[0] += roundScores[0];
            totalScores[1] += roundScores[1];
            totalScores[2] += roundScores[2];
            totalScores[3] += roundScores[3];
        }
        AllFinished(totalScores[0], totalScores[1], totalScores[2], totalScores[3]);

        uint maxScore;
        uint maxCount;
        uint8[4] memory candidates;
        for (i = 0; i < 4; i++) {
            if (maxScore < totalScores[i]) {
                maxScore = totalScores[i];
                maxCount = 0;
                candidates[maxCount++] = i + 1;
            } else if (maxScore == totalScores[i]) {
                candidates[maxCount++] = i + 1;
            }
        }
        assert(maxCount > 0);
        if (maxCount == 1) {
            WinnerTeam(candidates, candidates[0]);
        } else {
            WinnerTeam(candidates, candidates[_random256() % maxCount]);
        }
    }

    function _round(bytes memory playerData, EventType eventType, EventColor eventMajorColor, EventColor eventMinorColor) internal returns(uint[4]) {
        uint numOfPlayers = playerData.length / PLAYER_SIZE;
        uint[4] memory scores;
        for (uint i = 0; i < numOfPlayers; i++) {
            scores[i / (numOfPlayers / 4)] += _getPlayerEventScore(playerData, i, eventType, eventMajorColor, eventMinorColor);
        }
        RoundFinished(eventType, eventMajorColor, eventMinorColor, scores[0], scores[1], scores[2], scores[3]);
        return scores;
    }
}

contract GoCryptobotCore is GoCryptobotRounds {
    function GoCryptobotCore() public {
        paused = false;

        owner = msg.sender;
        operator = msg.sender;
    }
}