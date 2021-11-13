// SPDX-License-Identifier: POOMANIA
pragma solidity ^0.8.9;

import "../structs/Structs.sol";
import "../interfaces/IPoos.sol";
import "../interfaces/IStatistics.sol";
import "../interfaces/IHelpers.sol";
import "../interfaces/IDumplings.sol";
import "../interfaces/ITamagotchi.sol";
import "../abstractContracts/Base.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Dumplings is ERC721, Base, IDumplings {

    /**
    * @dev override see {IERC721-approve}.
    */
    function approve(address to, uint256 tokenId) public virtual override(ERC721, IPoo) {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        if (to == address(0)) {
            _resetDumplingPrice(tokenId);
        }

        _approve(to, tokenId);
    }

    /**
    * @dev override see {IERC721-transferFrom}.
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IPoo) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        _changeDumplingOwner(from, to, tokenId);
        _resetDumplingPrice(tokenId);
    }

    /**
    * @dev override see {IERC721-safeTransferFrom}.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IPoo) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
    * @dev override see {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IPoo) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        _changeDumplingOwner(from, to, tokenId);
        _resetDumplingPrice(tokenId);
    }

    function _resetDumplingPrice(uint256 tokenId) internal {
        indexToDumpling[tokenId].price = 0;
    }

    function _changeDumplingOwner(address from, address to, uint256 tokenId) internal {
        uint256[] memory changedTokenArray = new uint256[](addressToDumplings[from].length - 1);
        uint arrayCounter = 0;
        for (uint i = 0; i < addressToDumplings[from].length; i++) {
            if (addressToDumplings[from][i] != tokenId) {
                changedTokenArray[arrayCounter] = addressToDumplings[from][i];
                arrayCounter++;
            }
        }
        addressToDumplings[from] = changedTokenArray;
        addressToDumplings[to].push(tokenId);
        indexToDumpling[tokenId].owner = payable(to);
    }

    function approveForMarketplace(address to, uint256 tokenId, uint256 price) public virtual onlyAllowedContracts {
        require(price > 999999999999, "The price needs to be higher than 999999999999 wei");
        indexToDumpling[tokenId].price = price;
        _approve(to, tokenId);
    }

    function transferMarketplaceFrom(address from, address to, uint256 tokenId, uint256 price) public virtual onlyAllowedContracts {
        indexToDumpling[tokenId].lastSellPrice = price;
        transferFrom(from, to, tokenId);
    }

    event ExecutedLevelUp(uint indexed _id, uint _level);
    event ExecutedFeed(uint indexed _id, uint _lastTimeFed);
    event ExecutedRest(uint indexed _id, uint _lastTimeRested);
    event ExecutedResurrect(uint indexed _id);
    event ExecutedAliveChange(uint indexed _id, bool _aliveStatus);
    event ExecutedExhaustionChange(uint indexed _id, uint _newExhaustion);
    event ExecutedWinningStat(uint indexed _id);
    event ExecutedLosingStat(uint indexed _id);
    event NewDumplingMinted(uint indexed _id);
    event DumplingRenamed(uint indexed _id, string _newName);
    event ExecutedPowerUpChange(uint indexed _id);

    using Address for address;

    uint public dumplingCount;

    mapping(address => uint[]) public addressToDumplings;
    mapping(uint => Structs.Dumpling) indexToDumpling;
    mapping(string => bool) nameTaken;

    constructor(address _constantsContract) Base(_constantsContract) ERC721(" Poos", "Dumpling Poos") {}

    function calcAttributeValue(uint _value) internal view returns (uint) {
        uint newValue = (_value * IConstants(constantsContract).dumplingsPercentageOfParent()) / 100;
        if (newValue < 1) {
            newValue = 1;
        }
        return newValue;
    }

    /*
    * @dev
    * After a migration, make sure to pull the countDumplingsOfPoo mapping from the old contract
    */
    function createNewDumplingFromPoo(uint _idOfParent) public {
        address PoosContract = IConstants(constantsContract).PoosContract();
        require(IPoos(PoosContract).getPooByIndex(_idOfParent).alive, "Not allowed to mint Dumpling with dead Poo.");
        require(IPoos(PoosContract).canMintDumpling(_idOfParent), "Please wait till the the mint is allowed.");
        address statisticsContract = IConstants(constantsContract).statisticsContract();
        payByPoo(IConstants(constantsContract).pooTokenForDumplingMint());
        require(IPoos(PoosContract).ownerOf(_idOfParent) == msg.sender, "The sender of the message is not the owner of the Poo with the provided id");

        Structs.Poo memory Poo;
        Poo = IPoos(PoosContract).getPooByIndex(_idOfParent);

        dumplingCount = dumplingCount + 1;

        Structs.Dumpling memory dumpling = createDumpling(
            Structs.NewDumplingEntity(dumplingCount, Poo.id, Poo.hitPoints, Poo.basicDmg, Poo.stamina, Poo.attackPower, Poo.defense, Poo.initiative, Poo.agility)
        );

        dumpling.parentType = "Poo";

        nameTaken[dumpling.name] = true;

        addressToDumplings[msg.sender].push(dumplingCount);
        indexToDumpling[dumplingCount] = dumpling;

        _mint(msg.sender, dumplingCount);
        IStatistics(statisticsContract).increaseTotalDumplingsStat();

        IPoos(PoosContract).executeMintSetting(_idOfParent);

        emit NewDumplingMinted(dumplingCount);
    }

    function createDumpling(Structs.NewDumplingEntity memory stats) internal view returns (Structs.Dumpling memory _dumpling) {
        Structs.Dumpling memory dumpling;
        dumpling.id = stats.id;
        dumpling.level = 1;
        dumpling.currentExperience = 0;
        dumpling.experienceForNextLevel = 100;

        dumpling.name = IHelpers(IConstants(constantsContract).helpersContract()).concat("Dumpling #", dumpling.id);
        dumpling.descendantOf = stats.parentId;
        dumpling.hitPoints = calcAttributeValue(stats.hitPoints);
        dumpling.basicDmg = calcAttributeValue(stats.basicDmg);
        dumpling.stamina = calcAttributeValue(stats.stamina);
        dumpling.attackPower = calcAttributeValue(stats.attackPower);
        dumpling.defense = calcAttributeValue(stats.defense);
        dumpling.initiative = calcAttributeValue(stats.initiative);
        dumpling.agility = calcAttributeValue(stats.agility);
        dumpling.luck = 1;
        dumpling.owner = payable(msg.sender);
        dumpling.fightsWon = 0;
        dumpling.fightsLost = 0;
        dumpling.exhaustion = 0;
        dumpling.lastTimeRested = block.number;
        dumpling.hunger = 0;
        dumpling.lastTimeFed = block.number;
        dumpling.alive = true;
        dumpling.price = 0;
        dumpling.powerUps = [uint(0), uint(0), uint(0), uint(0), uint(0)];
        dumpling.hasPowerUps = false;
        dumpling.restPoints = 0;
        dumpling.resCounter = 0;
        dumpling.lastSellPrice = 0;

        return dumpling;
    }

    function checkAddressHasPoo(address _address) public override view returns (bool _hasPoo) {
        return addressToDumplings[_address].length > 0;
    }

    function getDumplingByIndex(uint _id) public override view returns (Structs.Dumpling memory _dumpling) {
        return indexToDumpling[_id];
    }

    function getFullDumplingByIndex(uint _id) public override view returns (Structs.Dumpling memory _dumpling) {
        _dumpling = indexToDumpling[_id];
        _dumpling.restPoints = ITamagotchi(IConstants(constantsContract).DumplingTamagotchiContract()).getRestPoints(_id);
        _dumpling.hunger = ITamagotchi(IConstants(constantsContract).DumplingTamagotchiContract()).getHunger(_id);
        if (_dumpling.hunger == 100) {
            _dumpling.alive = false;
        }
        return _dumpling;
    }

    function getAllPooIDsByAddress(address _address) public override view returns (uint[] memory _id) {
        return addressToDumplings[_address];
    }

    function checkDumplingHasPowerUps(uint _id) public override view returns (bool _hasPowerUps) {
        return indexToDumpling[_id].hasPowerUps;
    }

    function isNameTaken(string calldata name) public override view returns (bool) {
        return nameTaken[name];
    }

    /**
    *
    * @dev
    * Retrieves the batch of Poos which IDs are within the lower and upper bounds
    *
    */
    function getDumplingsBatch(uint _lowerBound, uint _upperbound) public view returns (Structs.Dumpling[] memory _dumpling) {
        address statisticsContract = IConstants(constantsContract).statisticsContract();
        uint totalDumplings = IStatistics(statisticsContract).totalDumplingsStat();
        require(_lowerBound > 0 && _lowerBound <= _upperbound && _upperbound <= totalDumplings, "Invalid set of bounds provided.");
        Structs.Dumpling[] memory dumplingArray = new Structs.Dumpling[](_upperbound - _lowerBound + 1);
        uint arrayCounter = 0;
        while (_lowerBound <= _upperbound) {
            Structs.Dumpling memory dumpling = getFullDumplingByIndex(_lowerBound);
            dumplingArray[arrayCounter] = dumpling;
            _lowerBound++;
            arrayCounter++;
        }

        return dumplingArray;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://Poos.fi/PooMetadata/Dumplings/";
    }

    function renameDumpling(uint _id, string calldata _newName) public {
        require(msg.sender == ownerOf(_id), "Sender is not owner.");
        require(!nameTaken[_newName], "Dumpling name already taken.");
        payByPoo(IConstants(constantsContract).pooTokenForRenamePoo());
        indexToDumpling[_id].name = IHelpers(IConstants(constantsContract).helpersContract()).limitNameLength(_newName);
        emit DumplingRenamed(_id, _newName);
    }

    function executeLevelUp(uint _id, uint[11] memory _newStats) public override onlyAllowedContracts {
        indexToDumpling[_id].level = _newStats[0];
        indexToDumpling[_id].currentExperience = _newStats[1];
        indexToDumpling[_id].experienceForNextLevel = _newStats[2];
        indexToDumpling[_id].hitPoints = _newStats[3];
        indexToDumpling[_id].basicDmg = _newStats[4];
        indexToDumpling[_id].stamina = _newStats[5];
        indexToDumpling[_id].attackPower = _newStats[6];
        indexToDumpling[_id].defense = _newStats[7];
        indexToDumpling[_id].initiative = _newStats[8];
        indexToDumpling[_id].agility = _newStats[9];
        indexToDumpling[_id].luck = _newStats[10];

        emit ExecutedLevelUp(_id, _newStats[0]);
    }

    function executeFeed(uint _id) public override onlyAllowedContracts {
        indexToDumpling[_id].hunger = 0;
        indexToDumpling[_id].lastTimeFed = block.number;
        emit ExecutedFeed(_id, indexToDumpling[_id].lastTimeFed);
    }

    function executeRest(uint _id, uint _restPoints) public override onlyAllowedContracts {
        uint256 exhaustion = indexToDumpling[_id].exhaustion;

        if (_restPoints > exhaustion) {
            indexToDumpling[_id].exhaustion = 0;
        } else {
            indexToDumpling[_id].exhaustion = exhaustion - _restPoints;
        }
        indexToDumpling[_id].lastTimeRested = block.number;
        emit ExecutedRest(_id, indexToDumpling[_id].lastTimeRested);
    }

    function executeResurrect(uint _id) public override onlyAllowedContracts {
        indexToDumpling[_id].hunger = 0;
        indexToDumpling[_id].lastTimeFed = block.number;
        indexToDumpling[_id].alive = true;
        indexToDumpling[_id].resCounter = indexToDumpling[_id].resCounter + 1;
        emit ExecutedResurrect(_id);
    }

    function executeAliveChange(uint _id, bool _aliveStatus) public override onlyAllowedContracts {
        indexToDumpling[_id].alive = _aliveStatus;
        emit ExecutedAliveChange(_id, _aliveStatus);
    }

    function executePowerUpChange(uint _id, uint[5] memory _powerUps, bool _powerUpStatus) public override onlyAllowedContracts {
        indexToDumpling[_id].powerUps = _powerUps;
        indexToDumpling[_id].hasPowerUps = _powerUpStatus;
        emit ExecutedPowerUpChange(_id);
    }

    function executeExhaustionChange(uint _id, uint _exhaustionToAdd) public override onlyAllowedContracts {
        uint256 exhaustion = indexToDumpling[_id].exhaustion;

        if (exhaustion + _exhaustionToAdd > 100) {
            indexToDumpling[_id].exhaustion = 100;
        } else {
            indexToDumpling[_id].exhaustion = exhaustion + _exhaustionToAdd;
        }
        emit ExecutedExhaustionChange(_id, indexToDumpling[_id].exhaustion);
    }

    function executeWinningStatChange(uint _id, uint _xp) public override onlyAllowedContracts {
        indexToDumpling[_id].fightsWon = indexToDumpling[_id].fightsWon + 1;
        indexToDumpling[_id].currentExperience = _xp;
        emit ExecutedWinningStat(_id);
    }

    function executeLosingStatChange(uint _id, uint _xp) public override onlyAllowedContracts {
        indexToDumpling[_id].fightsLost = indexToDumpling[_id].fightsLost + 1;
        indexToDumpling[_id].currentExperience = _xp;
        emit ExecutedLosingStat(_id);
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

import "../structs/Structs.sol";

interface IHelpers {
    function limitNameLength(string memory source) external pure returns (string memory);

    function uint2str(uint _i) external pure returns (string memory _uintAsString);

    function concat(string memory a, uint b) external pure returns (string memory);

    function concat(string memory a, string memory b) external pure returns (string memory);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
                return retval == IERC721Receiver.onERC721Received.selector;
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