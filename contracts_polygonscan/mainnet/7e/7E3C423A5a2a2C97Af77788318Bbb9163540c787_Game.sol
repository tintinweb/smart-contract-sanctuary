pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./WorkerNFT.sol";
import "./oracle.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Game is ReentrancyGuard {
    Oracle oracle;
    using Counters for Counters.Counter;
    event battleLog(uint256 indexed randomNumber, uint256 indexed battleResult);
    mapping(address => uint256) public playerLastTimeFought;
    mapping(address => uint256) public playerTokenInContract;
    address public tokenAddress;
    address public workerAddress;
    WorkerNFT workerInstance;
    Counters.Counter private monsterIds;
    Counters.Counter private randomCounts;
    address payable private admin;

    mapping(uint256 => Monster) public monsters;
    mapping(uint256 => WorkerHealth) public workerHealths;
    mapping(uint256 => bool) public workerFirstActivated;

    uint256 internal rewardTest;
    uint256 public damageTest;
    uint256 public monDamageTest;
    uint256 public monHpTest;
    uint256 public userHpTest;

    event firstActivate(uint256 indexed idActivated);

    constructor(address payable adminAddress) {
        admin = adminAddress;
    }

    struct Worker {
        uint256 elementType1;
        uint256 elementType2;
        uint256 elementType3;
        uint256 elementType1Stat;
        uint256 elementType2Stat;
        uint256 elementType3Stat;
        uint256 criRate;
        uint256 criDamage;
    }

    struct WorkerHealth {
        uint256 hp;
        uint16 durability;
        uint256 stamina;
    }

    struct Monster {
        uint256 elementAtkType;
        uint256 elementDefType;
        uint256 elementAtkStat;
        uint256 elementDefStat;
        uint256 criRate;
        uint256 criDamage;
        uint256 hp;
        uint16 durability;
    }

    function changeAdmin(address payable newAdminAddress) external {
        require(admin == msg.sender);
        admin = newAdminAddress;
    }

    function changeTokenAddress(address newTokenAddress) external {
        require(admin == msg.sender);
        tokenAddress = newTokenAddress;
    }

    function changeOracleAddress(address newOracleAddress) external {
        require(admin == msg.sender);
        oracle = Oracle(newOracleAddress);
    }

    function changeWorkerAddress(address newWorkerAddress) external {
        require(admin == msg.sender);
        workerInstance = WorkerNFT(newWorkerAddress);
    }

    function createMonster(
        uint256 _elementAtkType,
        uint256 _elementDefType,
        uint256 _elementAtkStat,
        uint256 _elementDefStat,
        uint256 _criRate,
        uint256 _criDamage,
        uint256 _hp,
        uint16 _durability
    ) external {
        require(admin == msg.sender, "you are not authorized to this function");
        monsters[monsterIds.current()] = Monster({
            elementAtkType: _elementAtkType,
            elementDefType: _elementDefType,
            elementAtkStat: _elementAtkStat,
            elementDefStat: _elementDefStat,
            criRate: _criRate,
            criDamage: _criDamage,
            hp: _hp,
            durability: _durability
        });

        monsterIds.increment();
    }

    function _substract(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 result)
    {
        if (a < b) {
            return result = 0;
        } else {
            return result = a - b;
        }
    }

    function firstActivateWorker(uint256 workerId) external {
        require(workerFirstActivated[workerId] == false, "already activated");
        _setDurability(workerId, 100);
        _setStamina(workerId, 100);
        _setHp(workerId, 10000);
        workerFirstActivated[workerId] = true;
        emit firstActivate(workerId);
    }

    function _setDurability(uint256 workerId, uint16 durabilityValue) internal {
        workerHealths[workerId].durability = durabilityValue;
    }

    function _setStamina(uint256 workerId, uint16 staminaValue) internal {
        workerHealths[workerId].stamina = staminaValue;
    }

    function _setHp(uint256 workerId, uint16 hpValue) internal {
        workerHealths[workerId].hp = hpValue;
    }

    function _setMonDurability(uint256 monId, uint16 monDurabilityValue)
        internal
    {
        monsters[monId].durability = monDurabilityValue;
    }

    function _random() internal returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    randomCounts.current()
                )
            )
        );
        randomCounts.increment();
        return randomHash % 100;
    }

    function _randomRewardEasy1() internal view returns (uint256) {
        // should pay reward according to player exp or investment
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, msg.sender)
            )
        );

        uint256 reward = (1000 + (randomHash % 2000) + 1) * 10**18;

        return reward;
    }

    function _elementAdvantage(uint256 userEle1, uint256 enemyEleDef)
        internal
        pure
        returns (uint256 advantage)
    {
        uint256 userElement = userEle1;

        // element1 : wood
        if (userElement == 1) {
            if (enemyEleDef == 1) {
                // no advantage (0%)
                return 0;
            }
            if (enemyEleDef == 2) {
                // disadvantage (-30%)
                return 3;
            }
            if (enemyEleDef == 3) {
                // advantage (+70%)
                return 1;
            }
            if (enemyEleDef == 4) {
                // disadvantage (-70%)
                return 4;
            }
            if (enemyEleDef == 5) {
                // advantage (+30%)
                return 2;
            }
        }
        // element2 : fire
        if (userElement == 2) {
            if (enemyEleDef == 2) {
                // no advantage (0%)
                return 0;
            }
            if (enemyEleDef == 3) {
                // disadvantage (-30%)
                return 3;
            }
            if (enemyEleDef == 4) {
                // advantage (+70%)
                return 1;
            }
            if (enemyEleDef == 5) {
                // disadvantage (-70%)
                return 4;
            }
            if (enemyEleDef == 1) {
                // advantage (+30%)
                return 2;
            }
        }
        // element3 : earth
        if (userElement == 3) {
            if (enemyEleDef == 3) {
                // no advantage (0%)
                return 0;
            }
            if (enemyEleDef == 4) {
                // disadvantage (-30%)
                return 3;
            }
            if (enemyEleDef == 5) {
                // advantage (+70%)
                return 1;
            }
            if (enemyEleDef == 1) {
                // disadvantage (-70%)
                return 4;
            }
            if (enemyEleDef == 2) {
                // advantage (+30%)
                return 2;
            }
        }

        // element4 : metal
        if (userElement == 4) {
            if (enemyEleDef == 4) {
                // no advantage (0%)
                return 0;
            }
            if (enemyEleDef == 5) {
                // disadvantage (-30%)
                return 3;
            }
            if (enemyEleDef == 1) {
                // advantage (+70%)
                return 1;
            }
            if (enemyEleDef == 2) {
                // disadvantage (-70%)
                return 4;
            }
            if (enemyEleDef == 3) {
                // advantage (+30%)
                return 2;
            }
        }

        // element5 : water
        if (userElement == 5) {
            if (enemyEleDef == 5) {
                // no advantage (0%)
                return 0;
            }
            if (enemyEleDef == 1) {
                // disadvantage (-30%)
                return 3;
            }
            if (enemyEleDef == 2) {
                // advantage (+70%)
                return 1;
            }
            if (enemyEleDef == 3) {
                // disadvantage (-70%)
                return 4;
            }
            if (enemyEleDef == 4) {
                // advantage (+30%)
                return 2;
            }
        }
    }

    function _advantageDamageCalculate3Atk(
        uint256 advStat,
        uint256 ele1Stat,
        uint256 ele2Stat,
        uint256 ele3Stat
    ) internal pure returns (uint256 advantageDamage) {
        uint256 baseDamage = ele1Stat + ele2Stat + ele3Stat;
        uint256 damageAfterAdv;
        if (advStat == 0) {
            damageAfterAdv = baseDamage;
        }

        if (advStat == 1) {
            damageAfterAdv = baseDamage + (baseDamage * 70) / 100;
        }

        if (advStat == 2) {
            damageAfterAdv = baseDamage + (baseDamage * 30) / 100;
        }

        if (advStat == 3) {
            damageAfterAdv = baseDamage - (baseDamage * 30) / 100;
        }

        if (advStat == 4) {
            damageAfterAdv = baseDamage - (baseDamage * 70) / 100;
        }

        return damageAfterAdv;
    }

    function _monsterAdvantageDamageCalculate3Atk(
        uint256 advStat,
        uint256 monsterAtkStat
    ) internal pure returns (uint256 monsterAdvantageDamage) {
        uint256 baseDamage = monsterAtkStat;
        uint256 damageAfterAdv;
        if (advStat == 0) {
            damageAfterAdv = baseDamage;
        }

        if (advStat == 1) {
            damageAfterAdv = baseDamage + (baseDamage * 70) / 100;
        }

        if (advStat == 2) {
            damageAfterAdv = baseDamage + (baseDamage * 30) / 100;
        }

        if (advStat == 3) {
            damageAfterAdv = baseDamage - (baseDamage * 30) / 100;
        }

        if (advStat == 4) {
            damageAfterAdv = baseDamage - (baseDamage * 70) / 100;
        }

        return damageAfterAdv;
    }

    function _criAttempt(
        uint256 damageAfterAdv,
        uint256 criRate,
        uint256 criDamage,
        uint256 attempNumber
    ) internal returns (uint256 _finalDamage) {
        uint256 finalDamage;
        if ((_random() / (attempNumber + 1)) % 100 <= criRate) {
            finalDamage = damageAfterAdv + ((damageAfterAdv * criDamage) / 100);
            return finalDamage;
        } else {
            return damageAfterAdv;
        }
    }

    function _attack(uint256 hp, uint256 damageReceive)
        internal
        pure
        returns (uint256 newHp)
    {
        return newHp = _substract(hp, damageReceive);
    }

    function _refillStamina(
        uint256 currentStamina,
        uint256 _playerLastTimeFought,
        uint256 timeNow
    ) internal pure returns (uint256 _stamina) {
        _stamina =
            currentStamina +
            (_substract(timeNow, _playerLastTimeFought) / 60) *
            60 *
            4;

        if (_stamina > 100) {
            _stamina = 100;
        }

        return _stamina;
    }

    function battleEasy1(
        // not use battlePosition yet, will use in other formation (2, 3)

        // 123
        // 132
        // 213
        // 231
        // 312
        // 321

        // Worker memory _worker,
        // WorkerHealth memory _workerHealth,
        uint256 _workerId,
        uint256 _monsterId,
        uint256 _formationNumber
    ) external nonReentrant {
        // require eletype 1 == 2 && eletype 1 == 3 not writen yet

        require(workerInstance.ownerOf(_workerId) == msg.sender);

        bool battleSucceed;
        uint256 workerId = _workerId;
        uint256 monsterId = _monsterId;
        Worker memory tempWorker;
        WorkerHealth memory tempWorkerHealth;
        Monster memory tempMonster;

        //stack to deep fix with { }
        {
            (
                uint256 a,
                uint256 b,
                uint256 c,
                uint256 d,
                uint256 e,
                uint256 f,
                uint256 g,
                uint256 h
            ) = workerInstance.workers(workerId);
            tempWorker = Worker(a, b, c, d, e, f, g, h);
            tempWorkerHealth = workerHealths[workerId];
            tempMonster = monsters[monsterId];
            // setDurability(_workerId, tempWorkerHealth.durability - 1);
            // tempWorkerHealth.durability = tempWorkerHealth.durability - 1;
        }

        if (playerLastTimeFought[msg.sender] != 0) {
            tempWorkerHealth.stamina = _refillStamina(
                tempWorkerHealth.stamina,
                playerLastTimeFought[msg.sender],
                block.timestamp
            );
        }

        require(
            tempWorkerHealth.stamina >= 20,
            "not enough stamina, please wait 4 hours to regenarate 1 stamina"
        );

        uint256 workerDamage;
        uint256 workerAdv;
        uint256 monDamage;
        uint256 monAdv;

        // calculate worker elemental advantage
        workerAdv = _elementAdvantage(
            tempWorker.elementType1,
            tempMonster.elementDefType
        );

        // calculate worker damage after advantage
        workerDamage = _advantageDamageCalculate3Atk(
            workerAdv,
            tempWorker.elementType1Stat,
            tempWorker.elementType2Stat,
            tempWorker.elementType3Stat
        );

        //calculate monster elemental advantage
        monAdv = _elementAdvantage(
            tempMonster.elementAtkType,
            tempWorker.elementType3
        );

        //calculate monster damage after advantage
        monDamage = _monsterAdvantageDamageCalculate3Atk(
            monAdv,
            tempMonster.elementAtkStat
        );

        // uint256 formationNumber = _formationNumber;

        if (_formationNumber == 1) {
            // uint256 tempMonHp = tempMonster.hp;
            // uint256 monHp = tempMonster.hp;
            // uint256 userHp = tempWorkerHealth.hp;

            for (uint256 i = 1; i <= 3; i++) {
                // Turn i start /////////////////////////////////
                uint256 tempWorkerDamage;
                uint256 tempMonDamage;
                // user turn

                //user cri random

                tempWorkerDamage = _criAttempt(
                    workerDamage,
                    tempWorker.criRate,
                    tempWorker.criDamage,
                    i
                );

                //user attack mon
                tempMonster.hp = _substract(tempMonster.hp, tempWorkerDamage);

                //check battle status if win payreward
                if (tempMonster.hp <= 0) {
                    battleSucceed = true;

                    if (tempMonster.durability == 0) {
                        //create new mon
                    }
                }

                if (tempMonster.hp <= 0) {
                    battleSucceed = false;
                }

                // // monster turn

                // monster cri random

                tempMonDamage = _criAttempt(
                    monDamage,
                    tempMonster.criRate,
                    tempMonster.criDamage,
                    i
                );

                // monster attack user
                tempWorkerHealth.hp = _substract(
                    tempWorkerHealth.hp,
                    tempMonDamage
                );

                // turn i end ////////////////////////////////////
            }

            //  if no one dies and if user hp < mon => user lose ? ...could be changed later
            if (tempMonster.hp >= tempWorkerHealth.hp) {
                battleSucceed = false;
            }

            if (tempMonster.hp < tempWorkerHealth.hp) {
                battleSucceed = true;
            }

            //end game set battle start time
            playerLastTimeFought[msg.sender] = block.timestamp;

            // deduct durability and stamina
            workerHealths[workerId].durability -= 1;
            workerHealths[workerId].stamina = tempWorkerHealth.stamina - 20;

            // pay reward

            if (battleSucceed == true) {
                playerTokenInContract[msg.sender] =
                    playerTokenInContract[msg.sender] +
                    _randomRewardEasy1();

                //transfer token reward
            }

            if (battleSucceed == false) {
                playerTokenInContract[msg.sender] =
                    playerTokenInContract[msg.sender] +
                    168 *
                    10**18;

                //transfer token reward
            }

            //for test
            userHpTest = tempWorkerHealth.hp;
            monHpTest = tempMonster.hp;
            damageTest = workerDamage;
            monDamageTest = monDamage;
        }
    }

    function playerLastTimeFoughtView(address playerAddress)
        external
        view
        returns (uint256 tokenAmount)
    {
        return playerLastTimeFought[playerAddress];
    }

    function playerTokenAmount(address playerAddress)
        public
        view
        returns (uint256 tokenAmount)
    {
        return playerTokenInContract[playerAddress];
    }

    function myTokenInContract() public view returns (uint256 tokenAmount) {
        return playerTokenInContract[msg.sender];
    }

    function withdrawToken(uint256 withdrawAmount) public nonReentrant {
        require(playerTokenInContract[msg.sender] >= withdrawAmount, "error");
        // uint user_withdrawBalanceAfterWithdraw = playerTokenInContract[msg.sender] - withdrawAmount;
        playerTokenInContract[msg.sender] -= withdrawAmount;
        ERC20(tokenAddress).transfer(msg.sender, withdrawAmount);
        //not sure if it will do assert if do multiple withdraw
        // assert(user_withdrawBalanceAfterWithdraw != playerTokenInContract[msg.sender] );
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./oracle.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PrimodialEnergy is ERC721Enumerable, ReentrancyGuard {
    //need reentrancy guard !
    using Strings for uint256;
    using Counters for Counters.Counter;
    Oracle oracle;
    Counters.Counter private randomCounts;
    address internal owner = 0x44df7e55c643c3cB048465E176A443Ad5670A6fa;

    uint256[] public gacha;
    string internal baseURI_0 =
        "https://raw.githubusercontent.com/Sirfalus/NFTmon/main/Pages/URI/";

    event GachaLanded(uint256 indexed result);

    constructor() ERC721("Primodial Crypto Energy", "PCE") ReentrancyGuard() {}

    struct Energy {
        uint256 elementType1;
        uint256 elementType2;
        uint256 elementType3;
        uint256 elementType4;
        uint256 elementType5;
        uint256 rarity;
    }

    mapping(uint256 => Energy) public energyAttribute;
    mapping(address => uint256) internal playerRandomCount;
    mapping(address => uint256) internal playerLastTimeRandom;
    uint256 internal inProgressNumber = 888888;

    function setOracle(address _oracleAddress) external {
        require(msg.sender == owner);
        oracle = Oracle(_oracleAddress);
    }

    function random() public view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    oracle.rand(),
                    randomCounts.current()
                )
            )
        );
        return randomHash;
    }

    function checkTokenOwner(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    function checkEnergyAttribute(uint256 tokenId)
        external
        view
        returns (Energy memory)
    {
        return energyAttribute[tokenId];
    }

    function rollGacha()
        external
        payable
        nonReentrant
        returns (uint256 tokenId)
    {
        // require(msg.value >= 1 * 10 * 18 wei);

        randomCounts.increment();
        uint256 randomNumber = random();
        uint256 randomTokenId = (randomNumber % 12500) + 1;
        require(
            gacha.length < 12500 && gacha.length >= 0,
            "sorry but all UCE have been sold already"
        );
        for (uint256 i = 0; i < gacha.length; i++) {
            if (gacha[i] == randomTokenId) {
                if (randomTokenId == 12500) {
                    randomTokenId = 0;
                }
                randomTokenId++;
            }
        }

        _safeMint(msg.sender, randomTokenId);
        uint256 rareNumber = ((randomNumber / 7) % 12500) + 1;
        uint256 rareNumberResult;

        if (rareNumber >= 1 && rareNumber <= 12) {
            rareNumberResult = 12;
        }

        if (rareNumber >= 13 && rareNumber <= 137) {
            rareNumberResult = 100;
        }

        if (rareNumber >= 138 && rareNumber <= 1387) {
            rareNumberResult = 2000;
        }

        if (rareNumber >= 1388 && rareNumber <= 5137) {
            rareNumberResult = 30000;
        }

        if (rareNumber >= 5138 && rareNumber <= 12500) {
            rareNumberResult = 400000;
        }

        energyAttribute[randomTokenId] = Energy(
            ((randomNumber / 2) % 5) + 1,
            ((randomNumber / 3) % 5) + 1,
            ((randomNumber / 4) % 5) + 1,
            ((randomNumber / 5) % 5) + 1,
            ((randomNumber / 6) % 5) + 1,
            rareNumberResult
        );

        gacha.push(randomTokenId);
        emit GachaLanded(randomTokenId);
        return randomTokenId;
    }

    function _randomAttributeA(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal view returns (uint256 randomStatA) {
        uint256 tempRandom = random();
        if (((tempRandom / 6) % 4) + 1 == 1) {
            return a;
        }

        if (((tempRandom / 6) % 4) + 1 == 2) {
            return b;
        }

        if (((tempRandom / 6) % 4) + 1 == 3) {
            return c;
        }

        if (((tempRandom / 6) % 4) + 1 == 4) {
            return d;
        }
    }

    function _randomAttributeB(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal view returns (uint256 randomStatB) {
        uint256 tempRandom = random();
        if (((tempRandom / 8) % 4) + 1 == 1) {
            return a;
        }

        if (((tempRandom / 8) % 4) + 1 == 2) {
            return b;
        }

        if (((tempRandom / 8) % 4) + 1 == 3) {
            return c;
        }

        if (((tempRandom / 8) % 4) + 1 == 4) {
            return d;
        }
    }

    function _randomAttributeC(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal view returns (uint256 randomStatC) {
        uint256 tempRandom = random();
        if (((tempRandom / 9) % 4) + 1 == 1) {
            return a;
        }

        if (((tempRandom / 9) % 4) + 1 == 2) {
            return b;
        }

        if (((tempRandom / 9) % 4) + 1 == 3) {
            return c;
        }

        if (((tempRandom / 9) % 4) + 1 == 4) {
            return d;
        }
    }

    // from stackoverflow use to convert int to string => https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity

    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function viewEnergyAttributeCombination(uint256 tokenId1, uint256 tokenId2)
        external
        view
        returns (string memory)
    {
        uint256 tempEleX1 = energyAttribute[tokenId1].elementType1;
        uint256 tempEleX2 = energyAttribute[tokenId1].elementType2;
        uint256 tempEleX3 = energyAttribute[tokenId1].elementType3;
        uint256 tempEleX4 = energyAttribute[tokenId1].elementType4;
        uint256 tempEleX5 = energyAttribute[tokenId1].elementType5;

        uint256 tempEleY1 = energyAttribute[tokenId2].elementType1;
        uint256 tempEleY2 = energyAttribute[tokenId2].elementType2;
        uint256 tempEleY3 = energyAttribute[tokenId2].elementType3;
        uint256 tempEleY4 = energyAttribute[tokenId2].elementType4;
        uint256 tempEleY5 = energyAttribute[tokenId2].elementType5;

        uint256 attributeA = _randomAttributeA(
            tempEleX1,
            tempEleX2,
            tempEleY1,
            tempEleY2
        );
        uint256 attributeB = _randomAttributeB(
            tempEleX3,
            tempEleX4,
            tempEleY3,
            tempEleY4
        );
        uint256 attributeC = _randomAttributeC(
            tempEleX1,
            tempEleX5,
            tempEleY1,
            tempEleY5
        );

        string memory _attributes = string(
            abi.encodePacked(
                _uint2str(attributeA),
                _uint2str(attributeB),
                _uint2str(attributeC)
            )
        );

        return _attributes;
    }

    function viewAllNFT() public view returns (uint256[] memory) {
        return gacha;
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

        string memory baseURI = _baseURI();
        string memory json = ".json";
        string memory tokenIdString = tokenId.toString();
        string memory URI0 = string(abi.encodePacked(baseURI, tokenIdString));
        string memory URI1 = string(abi.encodePacked(URI0, json));
        return URI1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_0;
    }

    function changeBaseURI(string memory newBaseUri) external {
        require(owner == msg.sender);
        baseURI_0 = newBaseUri;
    }

    function withdrawAll() external nonReentrant {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function ownerChange(address payable newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PrimodialEnergy.sol";
import "./oracle.sol";

contract WorkerNFT is ERC721Enumerable, ReentrancyGuard {
    Oracle oracle;
    PrimodialEnergy primodial;
    using Counters for Counters.Counter;
    using Strings for uint256;
    address internal owner = 0x44df7e55c643c3cB048465E176A443Ad5670A6fa;
    address internal gameContract;
    string internal baseURI_0 =
        "https://raw.githubusercontent.com/Sirfalus/NFTmon/main/Pages/URI/";
    address internal primodialContractAddress;

    Counters.Counter private workerIds;
    Counters.Counter private randomCounts;

    mapping(bytes32 => address) public players;
    mapping(address => uint256) public results;
    mapping(uint256 => Worker) public workers;

    event GachaLanded(uint256 indexed id);

    constructor() ERC721("Primodial Crypto Worker", "PCW") ReentrancyGuard() {}

    function changeGameContract(address newGameContract) external {
        require(msg.sender == owner);
        gameContract = newGameContract;
    }

    function changePrimodialContract(address newPrimodialContract) external {
        //   require(msg.sender == owner);
        primodial = PrimodialEnergy(newPrimodialContract);
    }

    function changeOracleContract(address newOracleContract) external {
        //   require(msg.sender == owner);
        oracle = Oracle(newOracleContract);
    }

    function testOracle() external view returns (uint256) {
        return oracle.rand();
    }

    struct Worker {
        uint256 elementType1;
        uint256 elementType2;
        uint256 elementType3;
        uint256 elementType1Stat;
        uint256 elementType2Stat;
        uint256 elementType3Stat;
        uint256 criRate;
        uint256 criDamage;
    }

    function _random() public view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    randomCounts.current(),
                    oracle.rand()
                )
            )
        );
        return randomHash;
    }

    function _randomCheap() public view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    randomCounts.current()
                )
            )
        );
        return randomHash;
    }

    function _statRandom(uint256 rareNumber)
        public
        view
        returns (uint256 result)
    {
        if (rareNumber == 1) {
            return result = 1000;
        }

        if (rareNumber >= 2 && rareNumber <= 11) {
            result = 900 + ((_random() / rareNumber) % 100);
            return result;
        }

        if (rareNumber >= 12 && rareNumber <= 111) {
            result = 700 + ((_random() / rareNumber) % 200);
            return result;
        }

        if (rareNumber >= 112 && rareNumber <= 1111) {
            result = 500 + ((_random() / rareNumber) % 200);
            return result;
        }

        if (rareNumber >= 1112 && rareNumber <= 10000) {
            result = 300 + ((_random() / rareNumber) % 200);
            return result;
        }
    }

    function _criRate(uint256 rareNumber) public view returns (uint256 result) {
        if (rareNumber == 1) {
            return result = 30;
        }

        if (rareNumber >= 2 && rareNumber <= 11) {
            result = 27 + ((_random() / rareNumber) % 3);
            return result;
        }

        if (rareNumber >= 12 && rareNumber <= 111) {
            result = 20 + ((_random() / rareNumber) % 6);
            return result;
        }

        if (rareNumber >= 112 && rareNumber <= 1111) {
            result = 12 + ((_random() / rareNumber) % 8);
            return result;
        }

        if (rareNumber >= 1112 && rareNumber <= 10000) {
            result = 6 + ((_random() / rareNumber) % 6);
            return result;
        }
    }

    function _criDmg(uint256 rareNumber) public view returns (uint256 result) {
        if (rareNumber == 1) {
            return result = 60;
        }

        if (rareNumber >= 2 && rareNumber <= 11) {
            result = 57 + ((_random() / rareNumber) % 3);
            return result;
        }

        if (rareNumber >= 12 && rareNumber <= 111) {
            result = 50 + ((_random() / rareNumber) % 6);
            return result;
        }

        if (rareNumber >= 112 && rareNumber <= 1111) {
            result = 42 + ((_random() / rareNumber) % 8);
            return result;
        }

        if (rareNumber >= 1112 && rareNumber <= 10000) {
            result = 36 + ((_random() / rareNumber) % 6);
            return result;
        }
    }

    function _stringToInt(string memory a)
        internal
        pure
        returns (uint256 StringTointValue)
    {
        if (
            keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked(("1")))
        ) {
            return 1;
        }

        if (
            keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked(("2")))
        ) {
            return 2;
        }

        if (
            keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked(("3")))
        ) {
            return 3;
        }

        if (
            keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked(("4")))
        ) {
            return 4;
        }

        if (
            keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked(("5")))
        ) {
            return 5;
        }
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function createWorker(uint256 nftSeed1, uint256 nftSeed2)
        public
        payable
        returns (uint256 newWorkerId)
    {
        require(
            primodial.checkTokenOwner(nftSeed1) == msg.sender &&
                primodial.checkTokenOwner(nftSeed2) == msg.sender &&
                nftSeed1 != nftSeed2,
            "you are not worth enough"
        );

        // dnaSeed.push(primodial.energyAttribute[nftSeed1].elementType1);
        //check money for start gacha
        // require(msg.value >= 1 * 10 ** 18);
        //check owner of nftSeed1 and nftSeed2
        //random nft attribute from nft seed1 and seed2
        randomCounts.increment();
        uint256 seedRandomUint = _random();
        string memory allAttribute = primodial.viewEnergyAttributeCombination(
            nftSeed1,
            nftSeed2
        );
        //convert string to uint

        workerIds.increment();
        uint256 currentWorkerIds = workerIds.current();
        _safeMint(msg.sender, currentWorkerIds);

        workers[currentWorkerIds].elementType1 = _stringToInt(
            _substring(allAttribute, 0, 1)
        );
        workers[currentWorkerIds].elementType2 = _stringToInt(
            _substring(allAttribute, 1, 2)
        );
        workers[currentWorkerIds].elementType3 = _stringToInt(
            _substring(allAttribute, 2, 3)
        );
        // need to adjust rarity range
        workers[currentWorkerIds].elementType1Stat = _statRandom(
            (seedRandomUint / 2) % (10000 + 1)
        );
        workers[currentWorkerIds].elementType2Stat = _statRandom(
            (seedRandomUint / 3) % (10000 + 1)
        );
        workers[currentWorkerIds].elementType3Stat = _statRandom(
            (seedRandomUint / 4) % (10000 + 1)
        );
        workers[currentWorkerIds].criRate = _criRate(
            (seedRandomUint / 5) % (10000 + 1)
        );
        workers[currentWorkerIds].criDamage = _criDmg(
            (seedRandomUint / 6) % (10000 + 1)
        );

        emit GachaLanded(currentWorkerIds);
        return currentWorkerIds;
    }

    function viewWorker(uint256 workerId)
        public
        view
        returns (Worker memory worker)
    {
        return workers[workerId];
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

        string memory baseURI = _baseURI();
        string memory json = ".json";
        string memory tokenIdString = tokenId.toString();
        string memory URI0 = string(abi.encodePacked(baseURI, tokenIdString));
        string memory URI1 = string(abi.encodePacked(URI0, json));
        return URI1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_0;
    }

    function changeBaseURI(string memory newBaseUri) external {
        require(owner == msg.sender);
        baseURI_0 = newBaseUri;
    }

    function withdrawAll() external {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function ownerChange(address payable newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
}

pragma solidity ^0.8.7;

contract Oracle {
    address private admin;
    uint256 public rand;

    constructor() {
        admin = msg.sender;
    }

    function feedRandomness(uint256 _rand) external {
        require(msg.sender == admin);
        rand = _rand;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}