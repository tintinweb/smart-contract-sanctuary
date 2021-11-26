// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";
import "./Random.sol";
import "./_BnbPool.sol";
import "./_LcPool.sol";

contract Farming is Auth, Random {
    event MintedLummy(address player, Box box, Lummy lummy);

    struct Box {
        uint256 price;
        Rarity rarity;
        uint256 oneStarChance;
        uint256 twoStarChance;
        uint256 threeStarChance;
        uint256 fourStarChance;
        uint256 fiveStarChance;
    }

    mapping(Rarity => Box) public boxes;

    address public dev;
    _BnbPool public bnbPool;
    _LcPool public lcPool;

    uint256 public invested;
    uint256 public wonLc;

    // Common       0
    // Unccomon     1
    // Rare         2
    // Epic         3
    // Legendary    4
    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }
    enum Stars { One, Two, Three, Four, Five }

//    Phase public currentPhase = Phase.Open;
    bool public REQUIRE_WHITELIST = true;
    bool public REQUIRE_REFERRAL = true;
    bool public ENABLED_BOXES = false;
    bool public ENABLED_FARM = false;

    uint256 public _counter = 0;

    struct Lummy {
        uint256 id;
        address owner;
        Rarity rarity;
        Stars stars;
        uint256 power;
        bool farming;
        uint256 farmed;
        uint256 farmLimit;
        uint256 lastPickup;
    }

    mapping(uint256 => Lummy) public lummies;

    struct Player {
        bool whitelist;
        bool isPlayer;
        address referrer;
        address referrerOfReferrer;
        uint256 referrals;
        uint256[] lummies;
        uint256[6] slots;
    }

    mapping(address => Player) players;
    address[] playerAddresses;

    modifier onlyNonPlayer() {
        require(!players[msg.sender].isPlayer, "ONLY_NON_PLAYER");
        _;
    }

    modifier onlyPlayer() {
        require(players[msg.sender].isPlayer, "ONLY_PLAYER");
        _;
    }

    constructor(address _dev_) Auth(msg.sender) {
        dev = _dev_;

        boxes[Rarity.Common] = Box(0.1 * 10 ** 18, Rarity.Common, 0, 10, 20, 30, 40);
        boxes[Rarity.Uncommon] = Box(0.2 * 10 ** 18, Rarity.Uncommon, 0, 10, 20, 30, 40);
        boxes[Rarity.Rare] = Box(0.3 * 10 ** 18, Rarity.Rare, 0, 10, 20, 30, 40);
        boxes[Rarity.Epic] = Box(0.4 * 10 ** 18, Rarity.Epic, 0, 10, 20, 30, 40);
        boxes[Rarity.Legendary] = Box(0.5 * 10 ** 18, Rarity.Legendary, 0, 10, 20, 30, 40);

        players[_dev_].whitelist = true;
        players[_dev_].isPlayer = true;
        playerAddresses.push(_dev_);

        _randomize();
    }

    function setUpPools(address _bnbPool_, address _lcPool_) external onlyOwner {
        bnbPool = _BnbPool(_bnbPool_);
        lcPool = _LcPool(_lcPool_);
    }

    function setUpRequireWhitelist(bool _value_) external onlyOwner {
        REQUIRE_WHITELIST = _value_;
    }

    function setUpRequireReferral(bool _value_) external onlyOwner {
        REQUIRE_REFERRAL = _value_;
    }

    function setUpEnabledBoxes(bool _value_) external onlyOwner {
        ENABLED_BOXES = _value_;
    }

    function setUpEnabledFarm(bool _value_) external onlyOwner {
        ENABLED_FARM = _value_;
    }

    function setUpBox(Rarity _rarity_, uint256 _price_, uint256 _oneStarChance_, uint256 _twoStarChance_, uint256 _threeStarChance_, uint256 _fourStarChance_, uint256 _fiveStarChance_) external onlyOwner {
        require(_oneStarChance_ + _twoStarChance_ + _threeStarChance_ + _fourStarChance_ + _fiveStarChance_ == 100, 'INVALID_CHANCES');
        boxes[_rarity_] = Box(_price_, _rarity_, _oneStarChance_, _twoStarChance_, _threeStarChance_, _fourStarChance_, _fiveStarChance_);
    }

    function invite(address _player_) external onlyOwner {
        players[_player_].whitelist = true;
    }

    function buyBox(address _referrer_, Rarity _rarity_) external payable {
        Box memory box = boxes[_rarity_];

        require(ENABLED_BOXES, 'BOXES_NOT_ENABLED');
        require(!REQUIRE_WHITELIST || (REQUIRE_WHITELIST && players[msg.sender].whitelist), 'REQUIRE_WHITELIST');
        require(!REQUIRE_REFERRAL || (REQUIRE_REFERRAL && players[_referrer_].isPlayer), 'INVALID_REFERRER');
        require(msg.value == box.price, 'INVALID_AMOUNT');

        if (!players[msg.sender].isPlayer) {
            _addReferrals(_referrer_);
        }
        _bnbFees();

        Lummy memory lummy = _mint(box);

        players[msg.sender].isPlayer = true;
        players[msg.sender].lummies.push(lummy.id);

        lummies[_counter] = lummy;

        invested += msg.value;

        emit MintedLummy(msg.sender, boxes[_rarity_], lummy);
    }

    function buyBoxLc(Rarity _rarity_) external {
        require(ENABLED_BOXES, 'BOXES_NOT_ENABLED');

        Box memory box = boxes[_rarity_];

        uint256 rewards = box.price * 10 / 100;

        lcPool.transferToPlayer(msg.sender, dev, rewards * 5000);
        lcPool.transferToContract(msg.sender, address(bnbPool), (box.price - rewards) * 5000);

        Lummy memory lummy = _mint(box);

        players[msg.sender].lummies.push(lummy.id);

        lummies[_counter] = lummy;

        invested += box.price;

        emit MintedLummy(msg.sender, boxes[_rarity_], lummy);
    }

    function _addReferrals(address _referrer_) internal {
        Player storage player = players[msg.sender];
        Player storage referrer = players[_referrer_];

        if (referrer.isPlayer) {
            player.referrer = _referrer_;
            referrer.referrals += 1;

            Player storage referrerOfReferrer = players[referrer.referrer];
            if (referrerOfReferrer.isPlayer) {
                player.referrerOfReferrer = referrer.referrer;
                referrerOfReferrer.referrals += 1;
            }
        }

        playerAddresses.push(msg.sender);
    }

    function _bnbFees() internal {
        uint256 rewards = msg.value * 5 / 100;
        Player memory player = players[msg.sender];

        if (player.referrerOfReferrer == address(0)) {
            lcPool.deposit{ value: rewards * 2 }(dev);
            lcPool.deposit{ value: rewards }(player.referrer);
            lcPool.deposit{ value: rewards }(player.referrerOfReferrer);
            bnbPool.deposit{ value: msg.value - (rewards * 4) }();
        } else if (player.referrer == address(0)) {
            lcPool.deposit{ value: rewards * 2 }(dev);
            lcPool.deposit{ value: rewards }(player.referrer);
            bnbPool.deposit{ value: msg.value - (rewards * 3) }();
        } else {
            lcPool.deposit{ value: rewards * 2 }(dev);
            bnbPool.deposit{ value: msg.value - (rewards * 2) }();
        }
    }

    function _mint(Box memory _box_) internal returns(Lummy memory) {
        uint256 random = _randomize();

        uint256 one = _box_.oneStarChance;
        uint256 two = one + _box_.twoStarChance;
        uint256 three = two + _box_.threeStarChance;
        uint256 four = three + _box_.fourStarChance;

        _counter++;

        if (random <= one) {
            uint256 power = _box_.price / 90 / 86400;
//            uint256 power = _box_.price / 90 / 60;
            return Lummy(_counter, msg.sender, _box_.rarity, Stars.One, power, false, 0, _box_.price * 2, 0);
        } else if (random <= two) {
            uint256 power = _box_.price / 75 / 86400;
//            uint256 power = _box_.price / 75 / 60;
            return Lummy(_counter, msg.sender, _box_.rarity, Stars.Two, power, false, 0, _box_.price * 2, 0);
        } else if (random <= three) {
            uint256 power = _box_.price / 60 / 86400;
//            uint256 power = _box_.price / 60 / 60;
            return Lummy(_counter, msg.sender, _box_.rarity, Stars.Three, power, false, 0, _box_.price * 2, 0);
        } else if (random <= four) {
            uint256 power = _box_.price / 45 / 86400;
//            uint256 power = _box_.price / 45 / 60;
            return Lummy(_counter, msg.sender, _box_.rarity, Stars.Four, power, false, 0, _box_.price * 2, 0);
        } else {
            uint256 power = _box_.price / 30 / 86400;
//            uint256 power = _box_.price / 30 / 60;
            return Lummy(_counter, msg.sender, _box_.rarity, Stars.Five, power, false, 0, _box_.price * 2, 0);
        }
    }

    function collected(uint256 _lummyId_) external view onlyPlayer returns(uint256) {
        Lummy memory lummy = lummies[_lummyId_];

        require(lummy.owner == msg.sender, 'NOT_ALLOWED');

        if (lummy.lastPickup == 0) {
            return 0;
        } else {
            uint256 secondFromLastPickup = currentTime() - lummy.lastPickup;
            uint256 farm = lummy.power * secondFromLastPickup;
            uint256 maxRoundFarm = lummy.farmLimit * 25 / 1000;

            if (farm > maxRoundFarm) {
                farm = maxRoundFarm;
            }

            return farm;
        }
    }

    function addToSlot(uint256 _slot_, uint256 _lummyId_) external onlyPlayer {
        require(ENABLED_FARM, 'FARM_NOT_ENABLED');

        Player storage player = players[msg.sender];
        Lummy storage lummy = lummies[_lummyId_];

        require(lummy.owner == msg.sender, 'NOT_ALLOWED');
        require(lummy.farming == false, 'ALREADY_FARMING');

        if (player.slots[_slot_] != 0) {
            uint256 lummyIdToReplace = player.slots[_slot_];
            Lummy storage lummyToReplace = lummies[lummyIdToReplace];
            lummyToReplace.farming = false;
            lummyToReplace.lastPickup = 0;
        }

        lummy.farming = true;
        lummy.lastPickup = currentTime();
        player.slots[_slot_] = lummy.id;
    }

    function claim(uint256 _lummyId_) external onlyPlayer {
        require(ENABLED_FARM, 'FARM_NOT_ENABLED');

        Lummy storage lummy = lummies[_lummyId_];

        require(lummy.owner == msg.sender, 'NOT_ALLOWED');

        if (lummy.lastPickup == 0) {
            lummy.lastPickup = currentTime();
        } else {
            uint256 secondFromLastPickup = currentTime() - lummy.lastPickup;
            uint256 farm = lummy.power * secondFromLastPickup;
            uint256 maxRoundFarm = lummy.farmLimit * 25 / 1000;

            if (farm > maxRoundFarm) {
                farm = maxRoundFarm;
            }

            lummy.farmed += farm;
            lummy.lastPickup = currentTime();

            wonLc += farm;

            bnbPool.claimBnbAndTransferToLc(msg.sender, farm);
        }
    }

    function getPlayerAddresses() external view onlyOwner returns(address[] memory) {
        return playerAddresses;
    }

    function countPlayers() external view returns(uint256) {
        return playerAddresses.length;
    }

    function getPlayerByIndex(uint256 _index_) external view onlyOwner returns(Player memory) {
        return players[playerAddresses[_index_]];
    }

    function getPlayerByAddress(address _player_) external view returns(Player memory) {
        return players[_player_];
    }

    function getLummiesByAddress(address _player_) external view returns(Lummy[] memory) {
        Player memory player = players[_player_];
        Lummy[] memory playerLummies = new Lummy[](player.lummies.length);

        for (uint i = 0; i < player.lummies.length; i += 1) {
            playerLummies[i] = lummies[player.lummies[i]];
        }

        return playerLummies;
    }

    function currentTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

}