/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract HydraEngine {
  enum Artifacts {artifactQ, artifactW, artifactE, artifactR, artifactT, artifactY}
  enum Components {componentA, componentS, componentD, componentF, componentG, componentH}
  enum Treasures {treasureZ, treasureX, treasureC, treasureV, treasureB, treasureN}
  enum Tools {toolJ, toolK, toolL}

  struct Map {
    uint8[6][6][6] regions;
    uint8[4] eventInRegions;
  }

  struct Workshop {
    uint8[16][6] artifactFragments;
    uint8[10] wastebasket;
    uint[6][6] linkPaths;
  }

  struct Actor {
    // 3[0]->favorited; 3[1]->activated; 3[2]->used
    bool[6][3] artifactsStates;
    bool[6][3] treasuresStates;
    bool[3][3] toolsStates;
    int8 hitPoints;
    bool isOutdoorOrInWorkshop;
    uint8[2] inMapIndex;
  }

  struct TimeTrack {
    uint8 spentFreedays;
    uint8 handOfGodEnergy;
    uint8 delayedDoomsday;
  }

  mapping(address => Map) private _mapOfAllPlayers; // player address => map data
  mapping(address => Workshop) private _workshopOfAllPlayers; // player address => workshop data
  mapping(address => Actor) private _actorOfAllPlayers; // player address => actor data
  mapping(address => TimeTrack) private _timeTrackOfAllPlayers; // player address => timeTrack data
  mapping(address => bool) private _isGameOver; // player address => is game end

  constructor() {
    
  }

  modifier isGameOver() {
      require(
          _isGameOver[msg.sender] == false,
          "GAME OVER"
      );
      _;
  }

  function combination(uint32[] memory arrayA, uint32[] memory arrayB) public pure returns (uint32[] memory) {
    uint32 arrayCount;
    for (uint32 i; i < arrayA.length; i++) {
      arrayCount++;
    }
    for (uint32 i; i < arrayB.length; i++) {
      arrayCount++;
    }

    uint32[] memory tempArray = new uint32[](arrayCount);
    for (uint32 i; i < arrayA.length; i++) {
      tempArray[i] = arrayA[i];
    }
    for (uint256 i = arrayA.length; i < arrayCount; i++) {
      tempArray[i] = arrayB[i];
    }
    return tempArray;
  }

  function createMemoryArray(uint32 element) private pure returns (uint32[] memory) {
    uint32[] memory memoryArray = new uint32[](1);
    memoryArray[1] = element;
    return memoryArray;
  }

  // function moveActorTo(bool isOutdoorOrInWorkshop, uint8 inMapRegionIndex) external isGameOver returns (uint32[] memory) {
  //   bool _isOutdoorOrInWorkshop = _actorOfAllPlayers[msg.sender].isOutdoorOrInWorkshop;
  //   if (_isOutdoorOrInWorkshop == isOutdoorOrInWorkshop) {
  //     uint8[2] memory _inMapIndex = _actorOfAllPlayers[msg.sender].inMapIndex;
  //     require(
  //       _inMapIndex[0] != inMapRegionIndex,
  //       "invalid move actor"
  //     );
  //     uint32[] memory eraseAllProgressMarksRCode = eraseAllProgressMarksFrom(_inMapIndex[0]);
  //     uint32[] memory usedOneDayRCode = usedOneDay();
  //     return combination(usedOneDayRCode, eraseAllProgressMarksRCode);
  //   }
  //   // move workshop
  //   _actorOfAllPlayers[msg.sender].isOutdoorOrInWorkshop = isOutdoorOrInWorkshop;
  //   if (isOutdoorOrInWorkshop == true) {
  //     _actorOfAllPlayers[msg.sender].inMapIndex[0] = inMapRegionIndex;
  //     _actorOfAllPlayers[msg.sender].inMapIndex[1] = 0;
  //     uint32[] memory usedOneDayRCode = usedOneDay();
  //     uint32[] memory temp = [50400]; // + uint32(inMapRegionIndex)];
  //     return combination(usedOneDayRCode, temp);
  //   } else {
  //     uint32[] memory usedOneDayRCode = usedOneDay();
  //     uint32[] memory eraseAllProgressMarksRCode = eraseAllProgressMarksFrom(_actorOfAllPlayers[msg.sender][0]);
  //     uint32[] memory happendRCode = combination(usedOneDayRCode, eraseAllProgressMarksRCode);
  //     return combination(happendRCode, [50500]);
  //   }
  // }

  // function eraseAllProgressMarksFrom(uint8 inMapRegionIndex) private returns (uint32[] memory) {
  //   if (inMapRegionIndex == 0) {
  //     return new uint32[]();
  //   }
  //   uint8[6][6] memory boxes;
  //   _mapOfAllPlayers[msg.sender].regions[inMapRegionIndex] = boxes;
  //   return [50300 + uint32(inMapRegionIndex)];
  // }

  // function usedOneDay() private returns (uint32[] memory) {
  //   _actorOfAllPlayers[msg.sender].spentFreedays += 1;

  //   string[] memory checkDoomsdayRCode = checkDoomsday();
  //   if (checkDoomsdayRCode != []) {
  //     return combination(checkDoomsdayRCode, [20000]);
  //   }

  //   return [20000];
  // }

  // function mapEventHappend() private returns (uint32[] memory) {
  //   uint8 spentFreedays = _actorOfAllPlayers[msg.sender].spentFreedays;

  //   uint8[7] memory _eventdaysIndex = eventdaysIndex();
  //   for (uint8 i; i < 7; i++) {
  //     if (_eventdaysIndex[i] == spentFreedays) {
  //       // TODO: 随机数和事件格式统一
  //       uint8[4] memory randomEvents = [1, 2, 3, 4];
  //       _mapOfAllPlayers[msg.sender].eventInRegions = randomEvents;
  //       uint32[4] memory mapEventHappendRCode;
  //       for (uint32 j; j < 4; j++) {
  //         mapEventHappendRCode[j] = 50200 + j * 10 + uint32(randomEvents[j]);
  //       }
  //       return mapEventHappendRCode;
  //     }
  //   }
  //   return [];
  // }

  // function checkDoomsday() private returns (uint32[] memory) {
  //   uint8 timeTrack = _timeTrackOfAllPlayers[msg.sender];
  //   uint8 _doomsdayCountdown = doomsdayCountdown();

  //   if (timeTrack.spentFreedays - timeTrack.delayedDoomsday > _doomsdayCountdown) {
  //     uint32[] memory gameOverRCode = gameOver();
  //     return combination(gameOverRCode, [20100]);
  //   }
  //   return [];
  // }

  function gameOver() private returns (uint32[] memory) {
    _isGameOver[msg.sender] = true;
    return createMemoryArray(10000);
  }

  function mockRandomNumbers(uint256 randomValue) public view returns (uint8[2] memory randomNumbers) {
    uint8[2] memory expandedValues;
    for (uint256 i; i < 2; i++) {
        expandedValues[i] = uint8(uint256(keccak256(abi.encode(randomValue + i, block.timestamp, msg.sender))) % 6 + 1);
    }
    return expandedValues;
  }
  
  function startGame() external {
    initGame();
  }

  function reStartGame() external {
    initGame();
    reloadGameData();
  }

  function initGame() private {

  }

  function reloadGameData() private {
    // raload game
    _isGameOver[msg.sender] = true;
    // raload Map - regions
    uint8[6][6][6] memory regions;
    _mapOfAllPlayers[msg.sender].regions = regions;
    // reload Map - eventInRegions
    _mapOfAllPlayers[msg.sender].eventInRegions = [0, 0, 0, 0];
    // reload Workshop - artifactFragments
    uint8[16][6] memory artifactFragments;
    _workshopOfAllPlayers[msg.sender].artifactFragments = artifactFragments;
    // reload Workshop - wastebasket
    uint8[10] memory wastebasket;
    _workshopOfAllPlayers[msg.sender].wastebasket = wastebasket;
    // reload Workshop - linkPaths
    uint[6][6] memory linkPaths;
    _workshopOfAllPlayers[msg.sender].linkPaths = linkPaths;
    // reload Actor - artifacts treasures tools states
    bool[6][3] memory artifactsStates;
    _actorOfAllPlayers[msg.sender].artifactsStates = artifactsStates;

    bool[6][3] memory treasuresStates;
    _actorOfAllPlayers[msg.sender].treasuresStates = treasuresStates;

    bool[3][3] memory toolsStates;
    _actorOfAllPlayers[msg.sender].toolsStates = toolsStates;
    // reload Actor - hitPoints
    _actorOfAllPlayers[msg.sender].hitPoints = 0;
    // reload Actor - location
    _actorOfAllPlayers[msg.sender].isOutdoorOrInWorkshop = false;
    uint8[2] memory inMapIndex;
    _actorOfAllPlayers[msg.sender].inMapIndex = inMapIndex;
    // reload TimeTrack - 
    _timeTrackOfAllPlayers[msg.sender].spentFreedays = 0;
    _timeTrackOfAllPlayers[msg.sender].handOfGodEnergy = 0;
    _timeTrackOfAllPlayers[msg.sender].delayedDoomsday = 0;
  }

  function allSpentTimes() public pure returns (uint8[6][6] memory) {
    uint8[6][6] memory _allSpentTimes;
    _allSpentTimes[0] = [1, 1, 0, 1, 0, 0];
    _allSpentTimes[1] = [1, 0, 0, 1, 0, 0];
    _allSpentTimes[2] = [1, 0, 1, 0, 1, 0];
    _allSpentTimes[3] = [1, 1, 0, 1, 0, 0];
    _allSpentTimes[4] = [1, 0, 1, 0, 1, 0];
    _allSpentTimes[5] = [1, 1, 1, 0, 1, 0];
    return _allSpentTimes;
  }

  // [6]true->hit; 2[0]->ragdoll / 2[1]->actor; 5->Lvl
  function combatHitDices() public pure returns (bool[6][2][5] memory) {
    bool[6][5] memory ragdollHitDices;
    ragdollHitDices[0] = [true, false, false, false, false, false];
    ragdollHitDices[1] = [true, false, false, false, false, false];
    ragdollHitDices[2] = [true, true, false, false, false, false];
    ragdollHitDices[3] = [true, true, true, false, false, false];
    ragdollHitDices[4] = [true, true, true, true, false, false];

    bool[6][5] memory actorHitDices;
    actorHitDices[0] = [false, false, false, false, true, true];
    actorHitDices[1] = [false, false, false, false, false, true];
    actorHitDices[2] = [false, false, false, false, false, true];
    actorHitDices[3] = [false, false, false, false, false, true];
    actorHitDices[4] = [false, false, false, false, false, true];

    bool[6][2][5] memory _CombatHitDices;
    for (uint8 i = 0; i < 5; i++) {
      _CombatHitDices[i][0] = ragdollHitDices[i];
      _CombatHitDices[i][1] = actorHitDices[i];
    }
    return _CombatHitDices;
  }

  function artifactCheckValue() public pure returns (uint8[6] memory) {
    return [4, 4, 4, 4, 4, 4];
  }

  function deathHitPoint() public pure returns (int8) {
    return -6;
  }

  function eventdaysIndex() public pure returns (uint8[7] memory) {
    return [2, 5, 8, 11, 14, 17, 20];
  }

  function doomsdayCountdown() public pure returns (uint8) {
    return 14;
  }

  function mapOfAllPlayers(address playerAddress) external view returns (Map memory) {
    return _mapOfAllPlayers[playerAddress];
  }

  function workshopOfAllPlayers(address playerAddress) external view returns (Workshop memory) {
    return _workshopOfAllPlayers[playerAddress];
  }

  function actorOfAllPlayers(address playerAddress) external view returns (Actor memory) {
    return _actorOfAllPlayers[playerAddress];
  }

  function timeTrackOfAllPlayers(address playerAddress) external view returns (TimeTrack memory) {
    return _timeTrackOfAllPlayers[playerAddress];
  }

}