// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./SettingGame.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ClaimAndCreate is SettingGame {
    using SafeMath for uint256;

    uint256 public totalLockedAmount;

    mapping(uint256 => uint256) public nurseryCreatingTime;
    mapping(uint256 => uint256) public forgeCreatingTime;
    mapping(uint256 => uint256) public trainingCenterCreatingTime;
    mapping(address => bool) public haveClaimedFirstMonster;

    uint256 public nurseryPrice = 20000 * 1E18;
    uint256 public forgePrice = 20000 * 1E18;
    uint256 public trainingCenterPrice = 20000 * 1E18;
    mapping(uint256 => uint256) public numberOfTrainingSpots;
    mapping(uint256 => uint256) public forgeMultiplier;

    // set Houses prices

    function setNurseryPrice(uint256 _price) external onlyOwner {
        nurseryPrice = _price;
    }

    function setTrainingPrice(uint256 _price) external onlyOwner {
        trainingCenterPrice = _price;
    }

    function setForgePrice(uint256 _price) external onlyOwner {
        forgePrice = _price;
    }

    // Claim and create
    function claimMyFirstMonster(string memory tokenURI, string memory _name)
        external
        returns (uint256)
    {
        require(tx.origin == msg.sender, "Contracts not allowed.");
        require(
            haveClaimedFirstMonster[msg.sender] == false,
            "You can claim only once"
        );
        require(startingBlock != 0, "Game hasn't started yet");
        haveClaimedFirstMonster[msg.sender] = true;

        bytes32 _id = keccak256(abi.encodePacked(msg.sender, tokenURI, nonce));
        uint256 _random = _getRandom(_id).mod(10000);

        uint256 _state;

        if (block.number.sub(startingBlock) < 45000) {
            // First week claim => better chance
            if (_random <= 20) {
                _state = 3; //0,2% to be a Platinum NFT
            } else if (_random > 20 && _random <= 520) {
                _state = 2; //5% to be a Gold NFT
            } else if (_random > 520 && _random <= 30520) {
                _state = 1; //30% to be a Silver NFT
            } else {
                _state = 0; //64,8% to be a Copper NFT
            }
        } else {
            if (_random <= 10) {
                _state = 3; //0,1% to be a Platinum NFT
            } else if (_random > 10 && _random <= 210) {
                _state = 2; //2% to be a Gold NFT
            } else if (_random > 210 && _random <= 10210) {
                _state = 1; //10% to be a Silver NFT
            } else {
                _state = 0; //87,9% to be a Copper NFT
            }
        }

        return
            Monster(monsterAddress).mintMonster(
                msg.sender,
                _state,
                tokenURI,
                _name
            );
    }

    // Building centers
    function createNursery(string memory tokenURI) external returns (uint256) {
        BZAI.transferFrom(msg.sender, address(this), nurseryPrice);
        uint256 nurseryId = Nursery(nurseryAddress).mintNursery(
            msg.sender,
            tokenURI
        );

        totalLockedAmount = totalLockedAmount.add(nurseryPrice);

        nurseryCreatingTime[nurseryId] = block.timestamp;
        return nurseryId;
    }

    function createForge(string memory tokenURI) external returns (uint256) {
        BZAI.transferFrom(msg.sender, address(this), forgePrice);
        uint256 forgeId = Forge(forgeAddress).mintForge(msg.sender, tokenURI);

        totalLockedAmount = totalLockedAmount.add(forgePrice);

        forgeCreatingTime[forgeId] = block.timestamp;
        forgeMultiplier[forgeId] = 1;
        return forgeId;
    }

    function createTrainingCenter(string memory tokenURI)
        external
        returns (uint256)
    {
        BZAI.transferFrom(msg.sender, address(this), trainingCenterPrice);
        uint256 trainingId = Training(trainingAddress).mintTrainingCenter(
            msg.sender,
            tokenURI
        );

        totalLockedAmount = totalLockedAmount.add(trainingCenterPrice);

        trainingCenterCreatingTime[trainingId] = block.timestamp;
        numberOfTrainingSpots[trainingId] = 3;
        return trainingId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./TrainingManagement.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ForgeManagement is TrainingManagement {
    // Les potions donnent un X3 sur l'xp gagné en combat

    using SafeMath for uint256;

    uint256 itemsStandardPrice = 100 * 1E18;

    struct Item {
        uint256 itemType;
        uint256 price;
        uint256 numberOfUse;
        uint256 power;
        uint256 fromForgeId;
    }

    mapping(uint256 => Item) public items;

    string[] itemTypes = ["Shield", "Sword", "potion"];

    mapping(uint256 => uint256) _itemsCredits; // On front end for update credits:
    mapping(uint256 => uint256) _creditsLastUpdate; // timestamp - creditLastUpdate + itemsCredits

    function getCredit(uint256 _forgeId) external view returns (uint256) {
        uint256 _credits;
        _credits = _itemsCredits[_forgeId].add(
            block.timestamp.sub(_creditsLastUpdate[_forgeId])
        );
        return _credits;
    }

    function createItem(
        uint256 itemType,
        uint256 price,
        uint256 credit,
        uint256 forgeId
    ) public {
        require(
            IERC721(forgeAddress).ownerOf(forgeId) == msg.sender,
            "Not yours"
        );
        require(price > itemsStandardPrice, "You can't sell lower than game");
        _updateCredits(forgeId);
        require(_itemsCredits[forgeId] >= credit, "Not enough credits");

        require(_canSell(forgeId), "You can't");

        uint256 _power = credit.sub(credit.mod(1000));
        _itemsCredits[forgeId] = _itemsCredits[forgeId].sub(_power);
        _power = _power.div(1000);

        uint256 itemId = BanzaiItems(itemsNFT).mintItem(address(this));

        Item storage i = items[itemId];

        i.itemType = itemType;
        i.price = price;
        i.numberOfUse = 3;
        i.power = _power;
        i.fromForgeId = forgeId;
    }

    function buyItem(uint256 _itemId) public {
        Item storage i = items[_itemId];

        BZAI.transferFrom(msg.sender, address(this), i.price);
        address ownerOfForge = IERC721(forgeAddress).ownerOf(i.fromForgeId);

        _payOwner(ownerOfForge, i.price);
        forgeRevenues[i.fromForgeId] = forgeRevenues[i.fromForgeId].add(
            i.price
        );

        IERC721(itemsNFT).transferFrom(address(this), msg.sender, _itemId);
    }

    function buyStandardItem(uint256 _itemType) public {
        require(
            BZAI.balanceOf(msg.sender) >= itemsStandardPrice,
            "Not enough value"
        );
        BZAI.transferFrom(msg.sender, address(this), itemsStandardPrice);
        _distributeFees(itemsStandardPrice);

        uint256 _id = BanzaiItems(itemsNFT).mintItem(msg.sender);

        Item storage i = items[_id];

        i.itemType = _itemType;
        i.numberOfUse = 3;
        i.power = 3;
    }

    function setItemStandardPrice(uint256 _price) public onlyOwner {
        itemsStandardPrice = _price;
    }

    function closeForge(uint256 _forgeId) public {
        ClosingProcess storage c = closingProcesses[2][_forgeId];
        require(
            IERC721(forgeAddress).ownerOf(_forgeId) == msg.sender,
            "Not your forge"
        );
        require(!c.isClosing, "Already in closing process");
        c.isClosing = true;
        c.timestampClosedActed = block.timestamp;
    }

    function getBZAIBackFromClosingForge(uint256 _forgeId) public {
        ClosingProcess storage c = closingProcesses[2][_forgeId];
        require(
            IERC721(forgeAddress).ownerOf(_forgeId) == msg.sender,
            "Not your forge"
        );
        require(c.isClosing, "Not in closing process");
        require(
            block.timestamp.sub(c.timestampClosedActed) > 19200,
            "Closing process during 3 days, please wait "
        );
        delete closingProcesses[2][_forgeId];

        totalLockedAmount = totalLockedAmount.sub(forgePrice);
        BZAI.transferFrom(address(this), msg.sender, forgePrice);

        //Burn
        Forge(forgeAddress).burnForge(_forgeId);
    }

    function _updateCredits(uint256 forgeId) internal {
        if (
            trainingCenterCreatingTime[forgeId] > 0 &&
            _creditsLastUpdate[forgeId] == 0
        ) {
            _creditsLastUpdate[forgeId] = trainingCenterCreatingTime[forgeId];
        }
        if (_creditsLastUpdate[forgeId] > 0) {
            uint256 _toAdd = block.timestamp.sub(_creditsLastUpdate[forgeId]);
            _itemsCredits[forgeId] = _itemsCredits[forgeId].add(
                _toAdd.mul(forgeMultiplier[forgeId])
            );
        }
    }

    function _canSell(uint256 forgeId) private view returns (bool) {
        bool result;
        if (
            forgeCreatingTime[forgeId] > 0 &&
            block.timestamp.sub(forgeCreatingTime[forgeId]) >= 19200
        ) {
            result = true;
        }
        if (closingProcesses[2][forgeId].isClosing) {
            result = false;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface Oracle {
    function getRandom(bytes32 _id) external returns (uint256);
}

interface Monster {
    function mintMonster(
        address _to,
        uint256 _state,
        string memory tokenURI,
        string memory name
    ) external returns (uint256);

    function updateMonster(
        uint256 _id,
        uint256 _attack,
        uint256 _defense,
        uint256 _xp
    ) external returns (uint256);

    function burnMonster(uint256 _tokenId) external;

    function getMonsterState(uint256 _tokenId) external view returns (uint256);

    function getMonsterLevel(uint256 _tokenId)
        external
        view
        returns (uint256 level);

    function getMonsterPowers(uint256 _tokenId)
        external
        view
        returns (uint256[2] memory);

    function duplicateMonsterStats(uint256 _tokenId)
        external
        returns (uint256 _newItemId);
}

interface Nursery {
    function mintNursery(address _to, string memory tokenURI)
        external
        returns (uint256);

    function burnNursery(uint256 _tokenId) external;
}

interface Training {
    function mintTrainingCenter(address _to, string memory tokenURI)
        external
        returns (uint256);

    function burnTrainingCenter(uint256 _tokenId) external;
}

interface Forge {
    function mintForge(address _to, string memory tokenURI)
        external
        returns (uint256);

    function burnForge(uint256 _tokenId) external;
}

interface Staking {
    function receiveFees(uint256 _amount) external;
}

interface BZAIToken {
    function burnToken(uint256 _amount) external;
}

interface BanzaiItems {
    function burnItem(uint256 _tokenId) external;

    function mintItem(address _to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ClaimAndCreate.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NurseryManagement is ClaimAndCreate {
    using SafeMath for uint256;

    uint256 public lotteryPrice = 10 * 1E18;

    uint256 copperMaturity = 1 days; // 1 day = 86400 seconds
    uint256 silverMaturity = 4 days; // 4 days
    uint256 goldMaturity = 10 days; // 10 days
    uint256 platinumMaturity = 20 days; // 20 days

    struct MintedData {
        uint256 copperMinted;
        uint256 silverMinted;
        uint256 goldMinted;
        uint256 platinumMinted;
    }
    mapping(uint256 => MintedData) public nurseryMintedDatas;

    struct EggsPrices {
        uint256 copperPrice;
        uint256 silverPrice;
        uint256 goldPrice;
        uint256 platinumPrice;
    }

    mapping(uint256 => EggsPrices) public eggsPrices;

    struct EggsData {
        uint256 startingMaturity;
        uint256 state;
    }

    mapping(address => mapping(uint256 => EggsData)) public eggsDatas;
    mapping(address => uint256) public myEggsCounter;

    struct ClosingProcess {
        bool isClosing;
        bool destructed;
        uint256 timestampClosedActed;
    }

    // closing process [0 = Nursery, 1 = Training, 2 =forge]
    // closingProcesses[0][1] => closing nursery tokenId 1
    mapping(uint256 => mapping(uint256 => ClosingProcess))
        public closingProcesses;

    function _canMint(uint256 nurseryId) internal view returns (bool) {
        EggsPrices memory e = eggsPrices[nurseryId];
        bool result;
        if (IERC721(nurseryAddress).ownerOf(nurseryId) == address(this)) {
            result = true;
        } else if (
            block.timestamp.sub(nurseryCreatingTime[nurseryId]) >= 1 days
        ) {
            if (
                e.copperPrice != 0 &&
                e.silverPrice != 0 &&
                e.goldPrice != 0 &&
                e.platinumPrice != 0
            ) {
                result = true;
            }
        }
        return result;
    }

    function nextStatutToMint(uint256 nurseryId)
        external
        view
        returns (uint256)
    {
        return _nextStatutToMint(nurseryId);
    }

    function _nextStatutToMint(uint256 nurseryId)
        internal
        view
        returns (uint256)
    {
        MintedData memory m = nurseryMintedDatas[nurseryId];
        uint256 _state;
        if (
            m.copperMinted > 0 &&
            m.silverMinted > 0 &&
            m.goldMinted > 0 &&
            m.copperMinted.mod(5) == 0 &&
            m.silverMinted.mod(5) == 0 &&
            m.goldMinted.mod(10) == 0
        ) {
            _state = 3;
        } else if (
            m.copperMinted > 0 &&
            m.silverMinted > 0 &&
            m.copperMinted.mod(5) == 0 &&
            m.silverMinted.mod(5) == 0 &&
            m.goldMinted.mod(10) != 0
        ) {
            _state = 2;
        } else if (
            m.copperMinted > 0 &&
            m.copperMinted.mod(5) == 0 &&
            m.silverMinted.mod(5) != 0
        ) {
            _state = 1;
        }

        return _state;
    }

    function setLotteryPrice(uint256 price) external onlyOwner {
        lotteryPrice = price;
    }

    function setPrice(
        uint256 nurseryId,
        uint256 _state,
        uint256 price
    ) external {
        require(
            IERC721(nurseryAddress).ownerOf(nurseryId) == msg.sender,
            "Not your nursery"
        );
        require(_state <= 3, "State doesn't exist");
        require(
            price > lotteryPrice,
            "Price can't be lower than lottery price"
        );
        EggsPrices storage e = eggsPrices[nurseryId];

        if (_state == 0) {
            e.copperPrice = price;
        }
        if (_state == 1) {
            e.silverPrice = price;
        }
        if (_state == 2) {
            e.goldPrice = price;
        }
        if (_state == 3) {
            e.platinumPrice = price;
        }
    }

    function buyEgg(uint256 nurseryId, uint256 state) public {
        require(_canMint(nurseryId), "Nursery can't mint egg yet");
        require(
            !closingProcesses[0][nurseryId].isClosing,
            "This nursery is in closing process"
        );
        require(state == _nextStatutToMint(nurseryId), "Not the good state");

        MintedData storage n = nurseryMintedDatas[nurseryId];

        if (state == 0) {
            n.copperMinted = n.copperMinted.add(1);
        }
        if (state == 1) {
            n.silverMinted = n.silverMinted.add(1);
        }
        if (state == 2) {
            n.goldMinted = n.goldMinted.add(1);
        }
        if (state == 3) {
            n.platinumMinted = n.platinumMinted.add(1);
        }

        BZAI.transferFrom(
            msg.sender,
            address(this),
            _getEggsPrice(state, nurseryId)
        );

        nurseryRevenues[nurseryId] = nurseryRevenues[nurseryId].add(
            _getEggsPrice(state, nurseryId)
        );

        address ownerOfNursery = IERC721(nurseryAddress).ownerOf(nurseryId);
        _payOwner(ownerOfNursery, _getEggsPrice(state, nurseryId));

        myEggsCounter[msg.sender] = myEggsCounter[msg.sender].add(1);

        uint256 counter = myEggsCounter[msg.sender];

        EggsData storage e = eggsDatas[msg.sender][counter];

        e.startingMaturity = block.timestamp;
        e.state = state;
    }

    function lotteryMint(string memory tokenURI, string memory _name)
        public
        returns (uint256)
    {
        require(BZAI.balanceOf(msg.sender) >= lotteryPrice, "Not enough value");
        BZAI.transferFrom(msg.sender, address(this), lotteryPrice);
        _distributeFees(lotteryPrice);

        bytes32 _id = keccak256(abi.encodePacked(msg.sender, tokenURI, nonce));
        uint256 _random = _getRandom(_id).mod(10000);

        uint256 _state;
        if (_random <= 10) {
            _state = 3;
        }
        if (_random > 10 && _random <= 210) {
            _state = 2;
        }
        if (_random > 210 && _random <= 1210) {
            _state = 1;
        }
        if (_random > 1210) {
            _state = 0;
        }

        return _generateRandomMonster(tokenURI, msg.sender, _state, _name);
    }

    function claimMatureMonster(
        uint256 counterId,
        string memory tokenURI,
        string memory _name
    ) external returns (uint256) {
        require(
            _canClaimMatureMonster(msg.sender, counterId),
            "Maturity not finished"
        );
        EggsData storage e = eggsDatas[msg.sender][counterId];

        return _generateRandomMonster(tokenURI, msg.sender, e.state, _name);
    }

    function _canClaimMatureMonster(address user, uint256 counterId)
        internal
        view
        returns (bool)
    {
        EggsData storage e = eggsDatas[user][counterId];
        uint256 timeMaturity = block.timestamp.sub(e.startingMaturity);

        bool canClaim;
        if (timeMaturity > platinumMaturity) {
            canClaim = true;
        } else if (e.state == 2 && timeMaturity > goldMaturity) {
            canClaim = true;
        } else if (e.state == 1 && timeMaturity > silverMaturity) {
            canClaim = true;
        } else if (e.state == 0 && timeMaturity > copperMaturity) {
            canClaim = true;
        }

        return canClaim;
    }

    function _generateRandomMonster(
        string memory tokenURI,
        address _user,
        uint256 _state,
        string memory _name
    ) private returns (uint256) {
        uint256 monsterId = Monster(monsterAddress).mintMonster(
            _user,
            _state,
            tokenURI,
            _name
        );
        return monsterId;
    }

    function _getEggsPrice(uint256 _state, uint256 _nurseryId)
        internal
        view
        returns (uint256)
    {
        uint256 price;
        EggsPrices memory e = eggsPrices[_nurseryId];
        if (_state == 0) {
            price = e.copperPrice;
        }
        if (_state == 1) {
            price = e.silverPrice;
        }
        if (_state == 2) {
            price = e.goldPrice;
        }
        if (_state == 3) {
            price = e.platinumPrice;
        }
        return price;
    }

    function closeNursery(uint256 _nurseryId) external {
        ClosingProcess storage c = closingProcesses[0][_nurseryId];
        require(
            IERC721(nurseryAddress).ownerOf(_nurseryId) == msg.sender,
            "Not your nursery"
        );
        require(!c.isClosing, "Already in closing process");
        c.isClosing = true;
        c.timestampClosedActed = block.timestamp;
    }

    function getBZAIBackFromClosingNursery(uint256 _nurseryId) external {
        ClosingProcess storage c = closingProcesses[0][_nurseryId];
        require(
            IERC721(nurseryAddress).ownerOf(_nurseryId) == msg.sender,
            "Not your nursery"
        );
        require(c.isClosing, "Not in closing process");
        require(
            block.timestamp.sub(c.timestampClosedActed) > 3 days,
            "Closing process during 3 days, please wait "
        );

        totalLockedAmount = totalLockedAmount.sub(nurseryPrice);
        BZAI.transfer(msg.sender, nurseryPrice);

        //Burn
        Nursery(nurseryAddress).burnNursery(_nurseryId);
        c.isClosing = false;
        c.destructed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Interfaces.sol";

contract SettingGame is Ownable, ERC721Holder {
    address public oracleAddress;
    address public BZAITokenAddress;
    address public monsterAddress;
    address public nurseryAddress;
    address public forgeAddress;
    address public itemsNFT;
    address public trainingAddress;
    address public stakingAddress;
    address public teamAddress;
    uint256 public nonce;
    uint256 public startingBlock;
    uint256 public inGameRewardsAmount;

    mapping(uint256 => uint256) public nurseryRevenues;
    mapping(uint256 => uint256) public forgeRevenues;
    mapping(uint256 => uint256) public trainingCenterRevenues;

    IERC20 public BZAI;

    using SafeMath for uint256;
    using SafeMath for uint8;

    constructor() {
        teamAddress = msg.sender;
    }

    // setting for owner

    function setBZAI(address _bzai) external onlyOwner() {
        BZAI = IERC20(_bzai);
        BZAITokenAddress = _bzai;
    }

    function setOracle(address _oracleAddress) external onlyOwner() {
        oracleAddress = _oracleAddress;
    }

    function setMonster(address _monsterNFTAdress) external onlyOwner() {
        monsterAddress = _monsterNFTAdress;
    }

    function setNursery(address _nurseryAddress) external onlyOwner() {
        nurseryAddress = _nurseryAddress;
    }

    function setTrainingCenter(address _trainingAddress) external onlyOwner() {
        trainingAddress = _trainingAddress;
    }

    function setForge(address _forgeAddress) external onlyOwner() {
        forgeAddress = _forgeAddress;
    }

    function setItemNft(address _itemNFTAddress) external onlyOwner() {
        itemsNFT = _itemNFTAddress;
    }

    function setTeamAddress(address _teamAddress) external onlyOwner() {
        teamAddress = _teamAddress;
    }

    function startingGame() external onlyOwner() {
        startingBlock = block.number;
    }

    // utils
    function _getRandom(bytes32 _id) internal returns (uint256) {
        return Oracle(oracleAddress).getRandom(_id);
    }

    function _payOwner(address _owner, uint256 _value) internal {
        uint256 _toOwner = _value.div(8000).mul(100000);
        uint256 _toDistribute = _value.div(500).mul(100000);

        // 80% for owner of Nuresery/Training Center or Forge
        BZAI.transferFrom(address(this), _owner, _toOwner);
        // 5 % for teams members
        BZAI.transferFrom(address(this), teamAddress, _toDistribute);
        // 5 % burn
        BZAIToken(BZAITokenAddress).burnToken(_toDistribute);
        // 5 % for stakers
        Staking(stakingAddress).receiveFees(_toDistribute);
        // 5% keeped in contract for rewards in game
        inGameRewardsAmount = inGameRewardsAmount.add(_toDistribute);
    }

    function _distributeFees(uint256 _amount) internal {
        uint256 toStakers = _amount.mul(8000).div(10000);
        uint256 _toDistribute = _amount.mul(500).div(10000);

        // 80% to stakers
        Staking(stakingAddress).receiveFees(toStakers);
        // 5% to burn
        BZAIToken(BZAITokenAddress).burnToken(_toDistribute);
        // 5 % for teams members
        BZAI.transferFrom(address(this), teamAddress, _toDistribute);
        //10% keeped in contract for rewards in game
        inGameRewardsAmount = inGameRewardsAmount.add(_toDistribute.mul(2));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./NurseryManagement.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TrainingManagement is NurseryManagement {
    // Attention prévoir de que l'id du centre d'entrainement
    // dans la fiche monster s'il s'entraine

    using SafeMath for uint256;

    uint256 public addSpotPrice = 5000 * 1E18;

    struct TrainingInstance {
        uint256 price;
        uint256 duration;
        uint256 startingTimestamp;
        uint256 monsterId;
        address monsterOwner;
    }

    mapping(uint256 => TrainingInstance[]) public trainingSpots;

    mapping(uint256 => uint256) public numberOfSpots;

    mapping(uint256 => bool) public isInTraining;

    function upgradeTrainingCenter(uint256 _spots, uint256 _trainingId)
        external
    {
        require(
            IERC721(trainingAddress).ownerOf(_trainingId) == msg.sender,
            "Not your training center"
        );

        BZAI.transferFrom(msg.sender, address(this), _spots.mul(addSpotPrice));
        _distributeFees(_spots.mul(addSpotPrice));

        numberOfTrainingSpots[_trainingId] = numberOfTrainingSpots[_trainingId]
        .add(_spots);
    }

    function setTrainingSpot(
        uint256 _spotId,
        uint256 _trainingId,
        uint256 _duration,
        uint256 _price
    ) external {
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        require(
            block.timestamp.sub(t.startingTimestamp) >= t.duration,
            "Not free"
        );

        require(
            IERC721(trainingAddress).ownerOf(_trainingId) == msg.sender,
            "Not yours"
        );

        require(
            _spotId <= trainingSpots[_trainingId].length.sub(1),
            "Doesn't exist"
        );

        if (t.monsterId != 0) {
            IERC721(monsterAddress).transferFrom(
                address(this),
                t.monsterOwner,
                t.monsterId
            );

            _updateMonsterAfterTraining(t.monsterId, t.duration);
            t.monsterId = 0;
            t.monsterOwner = address(0x0);
            t.startingTimestamp = 0;
        }

        t.duration = _duration;
        t.price = _price;
    }

    function beginTraining(
        uint256 _spotId,
        uint256 _trainingId,
        uint256 _monsterId
    ) external {
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        require(
            IERC721(monsterAddress).ownerOf(_monsterId) == msg.sender,
            "Not yours"
        );
        require(t.price >= 0, "Spot not parameter");
        require(
            block.timestamp.sub(t.startingTimestamp) >= t.duration &&
                t.duration != 0,
            "Not free"
        );
        require(_canTrain(_trainingId), "Training Center not ready");

        address ownerOfTrainingCenter = IERC721(trainingAddress).ownerOf(
            _trainingId
        );

        _payOwner(ownerOfTrainingCenter, t.price);
        trainingCenterRevenues[_trainingId] = trainingCenterRevenues[
            _trainingId
        ]
        .add(t.price);

        if (t.monsterId != 0) {
            IERC721(monsterAddress).transferFrom(
                address(this),
                t.monsterOwner,
                t.monsterId
            );

            _updateMonsterAfterTraining(t.monsterId, t.duration);
        }

        IERC721(monsterAddress).transferFrom(
            msg.sender,
            address(this),
            _monsterId
        );

        t.startingTimestamp = block.timestamp;
        t.monsterId = _monsterId;
        t.monsterOwner = msg.sender;
    }

    function finishTraining(uint256 _spotId, uint256 _trainingId) external {
        TrainingInstance storage t = trainingSpots[_trainingId][_spotId];
        require(t.monsterOwner == msg.sender, "Not yours");

        IERC721(monsterAddress).transferFrom(
            address(this),
            t.monsterOwner,
            t.monsterId
        );

        if (block.timestamp.sub(t.startingTimestamp) >= t.duration) {
            _updateMonsterAfterTraining(t.monsterId, t.duration);
        }

        t.monsterOwner = address(0x0);
        t.startingTimestamp = 0;
        t.monsterId = 0;
    }

    function _updateMonsterAfterTraining(uint256 _monsterId, uint256 _duration)
        private
    {
        uint256 monsterLevel = Monster(monsterAddress).getMonsterLevel(
            _monsterId
        );

        uint256 levelTens = monsterLevel.sub(monsterLevel.mod(10));
        uint256 multiplierXp = 1;
        if (levelTens > 0) {
            multiplierXp = levelTens.div(10).add(1);
        }

        Monster(monsterAddress).updateMonster(
            _monsterId,
            0,
            0,
            _duration.mul(multiplierXp)
        );
    }

    function _canTrain(uint256 _trainingId) private view returns (bool) {
        bool result;
        if (
            trainingCenterCreatingTime[_trainingId] > 0 &&
            block.timestamp.sub(trainingCenterCreatingTime[_trainingId]) >=
            1 days
        ) {
            result = true;
        }
        if (closingProcesses[1][_trainingId].isClosing) {
            result = false;
        }
        return result;
    }

    // closing trainingSpot

    function closeTrainingCenter(uint256 _trainingId) external {
        ClosingProcess storage c = closingProcesses[1][_trainingId];
        require(
            IERC721(trainingAddress).ownerOf(_trainingId) == msg.sender,
            "Not your center"
        );
        require(!c.isClosing, "Already in closing process");
        c.isClosing = true;
        c.timestampClosedActed = block.timestamp;
    }

    function getBZAIBackFromClosingTraining(uint256 _trainingId) external {
        ClosingProcess storage c = closingProcesses[1][_trainingId];
        require(
            IERC721(trainingAddress).ownerOf(_trainingId) == msg.sender,
            "Not your training"
        );
        require(c.isClosing, "Not in closing process");
        require(
            block.timestamp.sub(c.timestampClosedActed) > 3 days,
            "Closing process during 3 days, please wait "
        );
        delete closingProcesses[1][_trainingId];

        totalLockedAmount = totalLockedAmount.sub(trainingCenterPrice);
        BZAI.transferFrom(address(this), msg.sender, trainingCenterPrice);

        //Burn
        Training(trainingAddress).burnTrainingCenter(_trainingId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

