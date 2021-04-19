pragma solidity ^0.8.0;


contract CryptoBrawlRegistry  {

    struct Character {
        uint8 level;
        uint256 fightsCount;
        uint256 winsCount;
        uint8 fullHp;
        uint8 damage;
        bytes32 fightId;
        uint8 currentXP;
        uint256 tokenId;
        address tokenAddress;
        address owner;
    }

    mapping (bytes32 => Character) public chars;
    address public brawlMaster;

    Character private defaultChar = Character(
        1, // defaultLevel
        0, // fightsCount
        0, // winsCount
        45, // default fullHP
        15, // default damage
        bytes32(0), // fightId
        100, // XP
        0, // tokenID
        address (0), // tokenAddress
        address (0) // owner
    );

    constructor (address _brawlMaster) public {
        brawlMaster = _brawlMaster;
    }


    function initChar(bytes32 charID, address tokenAddress,  uint256 tokenId, address owner) onlyBrawlMaster public {
        chars[charID] = defaultChar;
        chars[charID].tokenAddress = tokenAddress;
        chars[charID].tokenId = tokenId;
        chars[charID].owner = owner;
    }


    function getFightId(bytes32 charID) public view returns (bytes32) {
        return chars[charID].fightId;
    }

    function getLevel(bytes32 charID) public view returns (uint){
        return chars[charID].level;
    }

    function getCharsOwner(bytes32 charID) public view returns (address){
        return chars[charID].owner;
    }

    function levelUp(bytes32 charID) internal {
        chars[charID].level += 1;
        chars[charID].fullHp += 10;
        chars[charID].damage += 1;
    }

    function finishFight(bytes32 winnerCharID, bytes32 looserCharID) onlyBrawlMaster public {
        chars[winnerCharID].fightsCount +=1;
        chars[looserCharID].fightsCount +=1;
        chars[winnerCharID].fightId = bytes32(0);
        chars[looserCharID].fightId = bytes32(0);
        chars[winnerCharID].winsCount += 1;
        levelUp(winnerCharID);
    }

    function setFightId(bytes32 charId1, bytes32 charId2, bytes32 fightId) onlyBrawlMaster public {
        chars[charId1].fightId = fightId;
        chars[charId2].fightId = fightId;
    }


    modifier onlyBrawlMaster() {
        require(msg.sender == brawlMaster);
        _;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}