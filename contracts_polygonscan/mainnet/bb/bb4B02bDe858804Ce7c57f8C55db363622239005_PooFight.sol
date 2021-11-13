// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../abstractContracts/Fight.sol";

contract PooFight is Fight {

    constructor(address _constantsContract) Fight(_constantsContract) {}

    /**
    *
    * @dev
    * execute individual Poo vs Poo fight
    *
    */
    function fightIndividualPooVsPoo(uint _challengerId, uint _enemyId) public
    isValidPooChallenger(_challengerId) isValidPooEnemy(_enemyId)
    isNotSameId(_challengerId, _enemyId) isOwnerOfPoo(_challengerId)
    isPooAlive(_challengerId) isPooExhausted(_challengerId) {
        payByPoo(IConstants(constantsContract).pooTokenForFight());
        Structs.FightEntity memory challenger = createPooFightStruct(_challengerId);
        Structs.FightEntity memory enemy = createPooFightStruct(_enemyId);

        bool won = executeFight(challenger, enemy);

        settlePooFightResult(challenger.id, won);
        settlePooFightResult(enemy.id, !won);
        IStatistics(IConstants(constantsContract).statisticsContract()).increaseTotalFights();

        if (canGetRewardForFight(challenger.id)) {
            transferPooRewardsForFight(challenger.id, challenger.owner, IConstants(constantsContract).blocksBetweenPooRewardForIndividualFights());
        }

        emit BattleResult(Battle.PooVsPoo, won, won ? challenger.id : enemy.id, !won ? challenger.id : enemy.id);
    }

    /**
    *
    * @dev
    * execute individual Poo vs Dumpling fight
    *
    */
    function fightIndividualPooVsDumpling(uint _challengerId, uint _enemyId) public
    isValidPooChallenger(_challengerId) isValidDumplingEnemy(_enemyId) isOwnerOfPoo(_challengerId)
    isPooAlive(_challengerId) isPooExhausted(_challengerId) {
        payByPoo(IConstants(constantsContract).pooTokenForFight());
        Structs.FightEntity memory challenger = createPooFightStruct(_challengerId);
        Structs.FightEntity memory enemy = createDumplingFightStruct(_enemyId);

        bool won = executeFight(challenger, enemy);

        settlePooFightResult(challenger.id, won);
        settleDumplingFightResult(enemy.id, !won);
        IStatistics(IConstants(constantsContract).statisticsContract()).increaseTotalFights();

        if (canGetRewardForFight(challenger.id)) {
            transferPooRewardsForFight(challenger.id, challenger.owner, IConstants(constantsContract).blocksBetweenPooRewardForIndividualFights());
        }

        emit BattleResult(Battle.PooVsDumpling, won, won ? challenger.id : enemy.id, !won ? challenger.id : enemy.id);
    }

    /**
    *
    * @dev
    * execute random Poo vs Poo fight
    *
    */
    function fightRandomPooVsPoo(uint _challengerId) public
    isValidPooChallenger(_challengerId) isOwnerOfPoo(_challengerId)
    isPooAlive(_challengerId) isPooExhausted(_challengerId) {
        Structs.FightEntity memory challenger = createPooFightStruct(_challengerId);

        uint randomIndex = randModulus(IStatistics(IConstants(constantsContract).statisticsContract()).totalPoosStat(), challenger.basicDmg);

        Structs.FightEntity memory enemy = createPooFightStruct(randomIndex);

        bool won = executeFight(challenger, enemy);

        settlePooFightResult(challenger.id, won);
        settlePooFightResult(randomIndex, !won);
        IStatistics(IConstants(constantsContract).statisticsContract()).increaseTotalFights();

        if (canGetRewardForFight(challenger.id)) {
            transferPooRewardsForFight(challenger.id, challenger.owner, IConstants(constantsContract).blocksBetweenPooRewardForRandomFights());
        }

        emit BattleResult(Battle.PooVsPoo, won, won ? challenger.id : randomIndex, !won ? challenger.id : randomIndex);
    }

    /**
    *
    * @dev
    * execute random Poo vs Dumpling fight
    *
    */
    function fightRandomPooVsDumpling(uint _challengerId) public
    isValidPooChallenger(_challengerId) isOwnerOfPoo(_challengerId)
    isPooAlive(_challengerId) isPooExhausted(_challengerId) {

        Structs.FightEntity memory challenger = createPooFightStruct(_challengerId);

        uint randomIndex = randModulus(IStatistics(IConstants(constantsContract).statisticsContract()).totalDumplingsStat(), challenger.basicDmg);

        Structs.FightEntity memory enemy = createDumplingFightStruct(randomIndex);

        bool won = executeFight(challenger, enemy);

        settlePooFightResult(challenger.id, won);
        settleDumplingFightResult(randomIndex, !won);
        IStatistics(IConstants(constantsContract).statisticsContract()).increaseTotalFights();

        if (canGetRewardForFight(challenger.id)) {
            transferPooRewardsForFight(challenger.id, challenger.owner, IConstants(constantsContract).blocksBetweenPooRewardForRandomFights());
        }

        emit BattleResult(Battle.PooVsDumpling, won, won ? challenger.id : randomIndex, !won ? challenger.id : randomIndex);
    }

}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

library Structs {

    struct Poo {
        uint id;
        uint level;
        uint currentExperience;
        uint experienceForNextLevel;
        string name;
        uint hitPoints;
        uint basicDmg;
        uint stamina;
        uint attackPower;
        uint defense;
        uint initiative;
        uint agility;
        uint luck;
        address payable owner;
        uint fightsWon;
        uint fightsLost;
        uint exhaustion;
        uint lastTimeRested;
        uint hunger;
        uint lastTimeFed;
        bool alive;
        uint price;
        uint[5] powerUps;
        bool hasPowerUps;
        uint restPoints;
        uint resCounter;
        uint lastSellPrice;
        uint nextPossibleMint;
        uint mintedDumplings;
    }

    struct Dumpling {
        uint id;
        uint level;
        uint currentExperience;
        uint experienceForNextLevel;
        string name;
        uint descendantOf;
        string parentType;
        uint hitPoints;
        uint basicDmg;
        uint stamina;
        uint attackPower;
        uint defense;
        uint initiative;
        uint agility;
        uint luck;
        address payable owner;
        uint fightsWon;
        uint fightsLost;
        uint exhaustion;
        uint lastTimeRested;
        uint hunger;
        uint lastTimeFed;
        bool alive;
        uint price;
        uint[5] powerUps;
        bool hasPowerUps;
        uint restPoints;
        uint resCounter;
        uint lastSellPrice;
    }

    struct UserAccountStruct {
        uint pooBalance;
        Poo[] pooArray;
        Dumpling[] dumplingArray;
    }

    struct NewDumplingEntity {
        uint id;
        uint parentId;
        uint hitPoints;
        uint basicDmg;
        uint stamina;
        uint attackPower;
        uint defense;
        uint initiative;
        uint agility;
    }

    struct PowerUps {
        uint percStam;
        uint percAp;
        uint percDef;
        uint percInit;
        uint percAgi;
    }

    struct FightEntity {
        uint id;
        address owner;
        uint currentExperience;
        uint experienceForNextLevel;
        uint hitPoints;
        uint basicDmg;
        uint stamina;
        uint attackPower;
        uint defense;
        uint initiative;
        uint agility;
    }
}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface ITamagotchi {
    function isPooAlive(uint _pooId) external view returns (bool _alive);

    function isPooExhausted(uint _pooId) external view returns (bool _exhausted);

    function getRestPoints(uint _id) external view returns (uint);

    function getHunger(uint _id) external view returns (uint _hungerLevel);
}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface IStatistics {
    function totalFights() external view returns (uint);

    function totalPoosStat() external view returns (uint);

    function totalPoosSales() external view returns (uint);

    function totalDumplingsStat() external view returns (uint);

    function totalDumplingsSales() external view returns (uint);

    function totalPowerUpsBought() external view returns (uint);

    function increaseTotalFights() external;

    function increaseTotalPoosStat() external;

    function increaseTotalDumplingsStat() external;

    function increaseTotalPoosSales() external;

    function increaseTotalDumplingsSales() external;

    function increaseTotalPowerUpsBought(uint _newPowerUpsBought) external;

    function getContractStatistics() external view returns (uint[8] memory);

}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface IPowerUpHandler {
    function removePowerUps(uint _pooId) external;
}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

import "./IPoo.sol";
import "../structs/Structs.sol";

interface IPoos is IPoo {

    function getPooByIndex(uint _id) external view returns (Structs.Poo memory _poo);

    function getPoosBatch(uint _lowerBound, uint _upperbound) external view returns (Structs.Poo[] memory _poos);

    function checkPooHasPowerUps(uint _id) external view returns (bool _hasPowerUps);

    function executeExhaustionChange(uint _id, uint _newExhaustion) external;

    function executeAliveChange(uint _pooID, bool _aliveStatus) external;

    function executePowerUpChange(uint _id, uint[5] memory _powerUps, bool _powerUpStatus) external;

    function executeWinningStatChange(uint _id, uint _xp) external;

    function executeLosingStatChange(uint _id, uint _xp) external;

    function executeRest(uint _id, uint _restPoints) external;

    function executeResurrect(uint _id) external;

    function executeFeed(uint _id) external;

    function executeMintSetting(uint _id) external;

    function canMintDumpling(uint _pooId) external view returns (bool canMint);

    function getFullPooByIndex(uint _id) external view returns (Structs.Poo memory _poo);

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../interfaces/IERC20Burnable.sol";


interface IPooToken is IERC20Burnable {

    function mintAdditionalRewards(address _receiver, uint _amount) external;

    function cap() external view returns (uint256);

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPoo is IERC721 {

    function approve(address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function approveForMarketplace(address to, uint256 tokenId, uint256 price) external;

    function transferMarketplaceFrom(address from, address to, uint256 tokenId, uint256 price) external;

    function checkAddressHasPoo(address _address) external view returns (bool _hasPoo);

    function executeLevelUp(uint256 _id, uint[11] memory _newStats) external;

    function getAllPooIDsByAddress(address _address) external view returns (uint[] memory _id);

    function isNameTaken(string calldata name) external view returns (bool);
}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface ILevelHandler {
    function checkLevelUp(uint _id, uint _newExperience) external;
}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

import "./IPoos.sol";
import "../structs/Structs.sol";

interface IDumplings is IPoo {

    function getDumplingByIndex(uint _id) external view returns (Structs.Dumpling memory _dumpling);

    function getDumplingsBatch(uint _lowerBound, uint _upperbound) external view returns (Structs.Dumpling[] memory _dumplings);

    function executeAliveChange(uint _id, bool _aliveStatus) external;

    function checkDumplingHasPowerUps(uint _id) external view returns (bool _hasPowerUps);

    function executeExhaustionChange(uint _id, uint _newExhaustion) external;

    function executePowerUpChange(uint _id, uint[5] memory _powerUps, bool _powerUpStatus) external;

    function executeWinningStatChange(uint _id, uint _xp) external;

    function executeLosingStatChange(uint _id, uint _xp) external;

    function executeRest(uint _id, uint _restPoints) external;

    function executeResurrect(uint _id) external;

    function executeFeed(uint _id) external;

    function getFullDumplingByIndex(uint _id) external view returns (Structs.Dumpling memory _dumpling);

}

// SPDX-License-Identifier: POOMANIA

pragma solidity ^0.8.9;

interface IConstants {

    function statisticsContract() external view returns (address);

    function helpersContract() external view returns (address);

    function PooFightContract() external view returns (address);

    function DumplingFightContract() external view returns (address);

    function pooTokenContract() external view returns (address);

    function userAccountContract() external view returns (address);

    function PoosContract() external view returns (address);

    function PooLevelHandlerContract() external view returns (address);

    function PoosMarketplaceContract() external view returns (address);

    function PooPowerUpHandlerContract() external view returns (address);

    function PooTamagotchiContract() external view returns (address);

    function DumplingsContract() external view returns (address);

    function DumplingLevelHandlerContract() external view returns (address);

    function DumplingsMarketplaceContract() external view returns (address);

    function DumplingPowerUpHandlerContract() external view returns (address);

    function DumplingTamagotchiContract() external view returns (address);

    function tokenAmountForMint() external view returns (uint);

    function pooTokenForFeed() external view returns (uint);

    function pooTokenForInstantExhaustionReset() external view returns (uint);

    function pooTokenForResurrect() external view returns (uint);

    function pooTokenForRenamePoo() external view returns (uint);

    function pooTokenForFight() external view returns (uint);

    function pooTokenForDumplingMint() external view returns (uint);

    function pooTokenForHundredPowerUp() external view returns (uint);

    function pooTokenForTwoHundredPowerUp() external view returns (uint);

    function pooTokenForThreeHundredPowerUp() external view returns (uint);

    function winnerXp() external view returns (uint);

    function loserXp() external view returns (uint);

    function owner() external view returns (address);

    function rev() external view returns (address);

    function blocksBetweenRestPoint() external view returns (uint);

    function blocksBetweenHungerPointForPoo() external view returns (uint);

    function blocksBetweenHungerPointForDumpling() external view returns (uint);

    function saleFeePercentage() external view returns (uint);

    function fightExhaustion() external view returns (uint);

    function dumplingsPercentageOfParent() external view returns (uint);

    function blocksBetweenDumplingMintForPoo() external view returns (uint);

    function blocksBetweenPooRewardForRandomFights() external view returns (uint);

    function blocksBetweenPooRewardForIndividualFights() external view returns (uint);

    function pooRewardForFight() external view returns (uint);

    function baseBlockBetweenDumplingMint() external view returns (uint);

    function ownerRewardPercentage() external view returns (uint);

    function revRewardPercentage() external view returns (uint);

    function maxMintableDumplingsForPoo() external view returns (uint);

    function pooMintCosts() external view returns (uint);

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

abstract contract Random {
    uint internal nonce;

    /**
     *
     * @dev
     * nonce setter
     *
     */
    function setNonce(uint _seed) internal {
        nonce = nonce + _seed;
        if (nonce % 123456789151231230285002825 == 0) {
            nonce = 1;
        }
    }

    /**
     *
     * @dev
     * rand calculation
     *
     */
    function randModulus(uint _mod, uint _seed) internal returns (uint _rand) {
        uint rand = uint(keccak256(abi.encodePacked(msg.sender, nonce + _seed))) % _mod;
        if (rand == 0) {
            rand = 1;
        }
        setNonce(rand);
        return rand;
    }


    function compoundInterest(uint _basis, uint _percentage, uint _periods) internal pure returns (uint _result) {
        uint result = _basis;

        for (uint x = 0; x < _periods; x++) {
            result = result + calcInterest(result, _percentage);
        }

        return result;
    }

    function calcInterest(uint _basis, uint _percentage) internal pure returns (uint _interest) {
        return (_basis * _percentage) / 100;
    }

}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../structs/Structs.sol";
import "../interfaces/IPoos.sol";
import "../interfaces/IDumplings.sol";
import "../interfaces/IStatistics.sol";
import "../interfaces/IPowerUpHandler.sol";
import "../interfaces/ITamagotchi.sol";
import "../interfaces/ILevelHandler.sol";
import "../abstractContracts/Random.sol";
import "./Base.sol";

abstract contract Fight is Base, Random {

    mapping(uint => uint) public blockForNextPooReward;

    event BattleResult(Battle _battle, bool indexed won, uint indexed _winner, uint indexed _loser);
    event BlockForNextPooRewardChanged(uint indexed _id, uint indexed _block);

    constructor(address _constantsContract) Base(_constantsContract) {}

    enum Battle {PooVsPoo, PooVsDumpling, DumplingVsDumpling, DumplingVsPoo}

    /**
    *
    * @dev
    * creates an struct from Poo for the fights
    *
    */
    function createPooFightStruct(uint _id) internal view returns (Structs.FightEntity memory _fightingPoo) {
        address PoosContract = IConstants(constantsContract).PoosContract();
        Structs.Poo memory Poo = IPoos(PoosContract).getPooByIndex(_id);

        _fightingPoo = Structs.FightEntity(Poo.id, Poo.owner, Poo.currentExperience, Poo.experienceForNextLevel,
            Poo.hitPoints, Poo.basicDmg, Poo.stamina,
            Poo.attackPower, Poo.defense, Poo.initiative,
            Poo.agility);

        if (Poo.hasPowerUps) {
            return addPowerUpsToFightStruct(_fightingPoo, Poo.powerUps);
        }
        return _fightingPoo;
    }

    /**
    *
    * @dev
    * creates an struct from Dumpling for the fights
    *
    */
    function createDumplingFightStruct(uint _id) internal view returns (Structs.FightEntity memory _fightingDumpling) {
        address DumplingsContract = IConstants(constantsContract).DumplingsContract();
        Structs.Dumpling memory Dumpling = IDumplings(DumplingsContract).getDumplingByIndex(_id);

        _fightingDumpling = Structs.FightEntity(Dumpling.id, Dumpling.owner, Dumpling.currentExperience, Dumpling.experienceForNextLevel,
            Dumpling.hitPoints, Dumpling.basicDmg, Dumpling.stamina,
            Dumpling.attackPower, Dumpling.defense, Dumpling.initiative,
            Dumpling.agility);

        if (Dumpling.hasPowerUps) {
            return addPowerUpsToFightStruct(_fightingDumpling, Dumpling.powerUps);
        }
        return _fightingDumpling;
    }

    /**
    *
    * @dev
    * add power up to fight struct
    *
    */
    function addPowerUpsToFightStruct(Structs.FightEntity memory _fightingPoo, uint[5] memory _powerUps) internal pure returns (Structs.FightEntity memory _fightStruct) {
        uint j = 5;
        for (uint i = 0; i < _powerUps.length; i++) {
            if (_powerUps[i] > 0) {
                if (i == 0) {
                    _fightingPoo.hitPoints = _fightingPoo.hitPoints + (_fightingPoo.stamina + ((_fightingPoo.stamina * _powerUps[0]) / 100));
                }
                if (i == 1) {
                    _fightingPoo.attackPower = _fightingPoo.attackPower + ((_fightingPoo.attackPower * _powerUps[1]) / 100);
                }
                if (i == 2) {
                    _fightingPoo.defense = _fightingPoo.defense + ((_fightingPoo.defense * _powerUps[2]) / 100);
                }
                if (i == 3) {
                    _fightingPoo.initiative = _fightingPoo.initiative + ((_fightingPoo.initiative * _powerUps[3]) / 100);
                }
                if (i == 4) {
                    _fightingPoo.agility = _fightingPoo.agility + ((_fightingPoo.agility * _powerUps[4]) / 100);
                }
            }
            j = j + 1;
        }
        return _fightingPoo;
    }

    /**
    *
    * @dev
    * execute the fight between to  Poos
    *
    */
    function executeFight(Structs.FightEntity memory _challenger, Structs.FightEntity memory _enemy) internal returns (bool _won) {
        Structs.FightEntity memory attacker;
        Structs.FightEntity memory defender;
        Structs.FightEntity memory dummy;
        uint winner = 0;
        uint loser = 0;

        if (_challenger.initiative >= _enemy.initiative) {
            attacker = _challenger;
            defender = _enemy;
        } else {
            attacker = _enemy;
            defender = _challenger;
        }

        uint breaker = 1;

        do {
            if (attacker.agility >= randModulus(attacker.agility + defender.agility, defender.currentExperience)) {
                uint damage = 1;
                uint attack = attacker.basicDmg + (attacker.attackPower / 3);
                if (attack > defender.defense) {
                    damage = attack - defender.defense;
                }
                if (damage < defender.defense) {
                    defender.hitPoints = defender.hitPoints - damage;
                } else {
                    defender.hitPoints = 0;
                }
            }

            if (defender.hitPoints > 0) {
                dummy = attacker;
                attacker = defender;
                defender = dummy;
            } else {
                winner = attacker.id;
                loser = defender.id;
            }

            breaker = breaker + 1;

            if (breaker % 3 == 0) {
                if (attacker.hitPoints < 3) {
                    attacker.hitPoints = 0;
                } else {
                    attacker.hitPoints = attacker.hitPoints / 3;
                }

                if (defender.hitPoints < 3) {
                    defender.hitPoints = 0;
                } else {
                    defender.hitPoints = defender.hitPoints / 3;
                }
            }
        }
        while (winner == 0 && loser == 0);

        return (winner == _challenger.id);
    }

    /**
    *
    * @dev
    * settle all new Dumpling values from fight
    *
    */
    function settlePooFightResult(uint _id, bool _won) internal {
        address PoosContract = IConstants(constantsContract).PoosContract();

        uint newXp;

        if (_won) {
            newXp = IPoos(PoosContract).getPooByIndex(_id).currentExperience + IConstants(constantsContract).winnerXp();
            IPoos(PoosContract).executeWinningStatChange(_id, newXp);
        } else {
            newXp = IPoos(PoosContract).getPooByIndex(_id).currentExperience + IConstants(constantsContract).loserXp();
            IPoos(PoosContract).executeLosingStatChange(_id, newXp);
        }

        IPoos(PoosContract).executeExhaustionChange(_id, IConstants(constantsContract).fightExhaustion());

        IPowerUpHandler(IConstants(constantsContract).PooPowerUpHandlerContract()).removePowerUps(_id);
        ILevelHandler(IConstants(constantsContract).PooLevelHandlerContract()).checkLevelUp(_id, newXp);
    }

    /**
    *
    * @dev
    * settle all new Dumpling values from fight
    *
    */
    function settleDumplingFightResult(uint _id, bool _won) internal {
        address DumplingContract = IConstants(constantsContract).DumplingsContract();

        uint newXp;

        if (_won) {
            newXp = IDumplings(DumplingContract).getDumplingByIndex(_id).currentExperience + IConstants(constantsContract).winnerXp();
            IDumplings(DumplingContract).executeWinningStatChange(_id, newXp);
        } else {
            newXp = IDumplings(DumplingContract).getDumplingByIndex(_id).currentExperience + IConstants(constantsContract).loserXp();
            IDumplings(DumplingContract).executeLosingStatChange(_id, newXp);
        }

        IDumplings(DumplingContract).executeExhaustionChange(_id, IConstants(constantsContract).fightExhaustion());

        IPowerUpHandler(IConstants(constantsContract).DumplingPowerUpHandlerContract()).removePowerUps(_id);
        ILevelHandler(IConstants(constantsContract).DumplingLevelHandlerContract()).checkLevelUp(_id, newXp);
    }

    /**
    *
    * @dev
    * check if token id can get reward for fight
    *
    */
    function canGetRewardForFight(uint _challengerId) internal view returns (bool) {
        return blockForNextPooReward[_challengerId] <= block.number;
    }

    /**
    *
    * @dev
    * check initiate the token reward transfer
    *
    */
    function transferPooRewardsForFight(uint _id, address _owner, uint _blocksTillNextReward) internal {
        IPooToken(IConstants(constantsContract).pooTokenContract()).mintAdditionalRewards(_owner, IConstants(constantsContract).pooRewardForFight());
        blockForNextPooReward[_id] = block.number + _blocksTillNextReward;
        emit BlockForNextPooRewardChanged(_id, blockForNextPooReward[_id]);
    }

    /**
    *
    * @dev
    * check if valid Poo challenger id provide
    *
    */
    modifier isValidPooChallenger(uint _id) {
        require(isValidPooId(_id), "The provided challenger ID is not valid.");
        _;
    }

    /**
    *
    * @dev
    * check if valid Poo enemy id provide
    *
    */
    modifier isValidPooEnemy(uint _id) {
        require(isValidPooId(_id), "The provided enemy ID is not valid.");
        _;
    }

    /**
    *
    * @dev
    * check if valid Dumpling challenger id provide
    *
    */
    modifier isValidDumplingChallenger(uint _id) {
        require(isValidDumplingId(_id), "The provided challenger ID is not valid.");
        _;
    }

    /**
    *
    * @dev
    * check if valid Dumpling enemy id provide
    *
    */
    modifier isValidDumplingEnemy(uint _id) {
        require(isValidDumplingId(_id), "The provided enemy ID is not valid.");
        _;
    }

    /**
    *
    * @dev
    * check if msg.sender is owner of Poo
    *
    */
    modifier isOwnerOfPoo(uint _id) {
        require(IPoos(IConstants(constantsContract).PoosContract()).ownerOf(_id) == msg.sender, "The sender of this transaction does not own this Poo.");
        _;
    }

    /**
    *
    * @dev
    * check if msg.sender is owner of Dumpling
    *
    */
    modifier isOwnerOfDumpling(uint _id) {
        require(IDumplings(IConstants(constantsContract).DumplingsContract()).ownerOf(_id) == msg.sender, "The sender of this transaction does not own this Dumpling.");
        _;
    }

    /**
    *
    * @dev
    * check if Poo is alive
    *
    */
    modifier isPooAlive(uint _id) {
        require(ITamagotchi(IConstants(constantsContract).PooTamagotchiContract()).isPooAlive(_id), "The Poo of the sender is dead.");
        _;
    }

    /**
    *
    * @dev
    * check if Dumpling is alive
    *
    */
    modifier isDumplingAlive(uint _id) {
        require(ITamagotchi(IConstants(constantsContract).DumplingTamagotchiContract()).isPooAlive(_id), "The Dumpling of the sender is dead.");
        _;
    }

    /**
    *
    * @dev
    * check if Poo has enough energy for fight
    *
    */
    modifier isPooExhausted(uint _id) {
        require(!ITamagotchi(IConstants(constantsContract).PooTamagotchiContract()).isPooExhausted(_id), "The Poo of the message sender is too exhausted.");
        _;
    }

    /**
    *
    * @dev
    * check if Dumpling has enough energy for fight
    *
    */
    modifier isDumplingExhausted(uint _id) {
        require(!ITamagotchi(IConstants(constantsContract).DumplingTamagotchiContract()).isPooExhausted(_id), "The Poo of the message sender is too exhausted.");
        _;
    }

    /**
    *
    * @dev
    * check if challenger is not enemy
    *
    */
    modifier isNotSameId(uint _challenger, uint _enemy) {
        require(_challenger != _enemy, "Challenger is enemy.");
        _;
    }

    function isValidPooId(uint _id) internal view returns (bool _valid) {
        return _id <= IStatistics(IConstants(constantsContract).statisticsContract()).totalPoosStat() && _id > 0;
    }

    function isValidDumplingId(uint _id) internal view returns (bool _valid) {
        return _id <= IStatistics(IConstants(constantsContract).statisticsContract()).totalDumplingsStat() && _id > 0;
    }
}

// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../interfaces/IPooToken.sol";
import "../interfaces/IConstants.sol";

abstract contract Base {

    event AllowedContractAdded(address indexed _contract);
    event AllowedContractRemoved(address indexed _contract);
    event ConstantsContractChanged(address indexed _contract);

    address public constantsContract;
    mapping(address => bool) public allowedContracts;

    constructor(address _constants) {
        constantsContract = _constants;
    }

    modifier onlyOwner {
        require(msg.sender == IConstants(constantsContract).owner(), "The sender of the message needs to be the contract owner.");
        _;
    }

    modifier onlyAllowedContracts {
        require(allowedContracts[msg.sender] == true, "The sender of the message needs to be an allowed contract.");
        _;
    }

    /**
     *
     * @dev
     * allows the owner to set the external addresses which are allowed to call the functions of this contract
     *
     */
    function addAllowedContract(address _allowedContract) public onlyOwner {
        allowedContracts[_allowedContract] = true;
        emit AllowedContractAdded(_allowedContract);
    }

    /**
     *
     * @dev
     * allows the owner to remove one external addresses which is no longer allowed to call the functions of this contract
     *
     */
    function removeAllowedContract(address _allowedContractToRemove) public onlyOwner {
        allowedContracts[_allowedContractToRemove] = false;
        emit AllowedContractRemoved(_allowedContractToRemove);
    }

    function setConstantsContract(address _newConstantsContract) public onlyOwner {
        constantsContract = _newConstantsContract;
        emit ConstantsContractChanged(_newConstantsContract);
    }

    function payByPoo(uint amount) internal {
        address pooContract = IConstants(constantsContract).pooTokenContract();
        require(IPooToken(pooContract).allowance(msg.sender, address(this)) >= amount, "Not enough allowance.");
        IPooToken(pooContract).burnFrom(msg.sender, amount);
    }

    function transferValueToOwner(uint value) internal {
        payable(IConstants(constantsContract).owner()).transfer(value);
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