// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/BearsDeluxeI.sol";
import "../interfaces/HoneyTokenI.sol";
import "../interfaces/BeesDeluxeI.sol";
import "../interfaces/HoneyHiveDeluxeI.sol";

contract HoneyFarmQueenDeluxe is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint32 public constant HONEY_BEARS_REWARDS_PER_ROUND = 100; //this is 1

    uint32 public constant HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH = 13; //this is 0.13

    uint32 public constant HONEY_STAKED_BEE_REWARDS_PER_EPOCH = 9; //this is 0.09

    uint8 public constant MAX_USAGE_PER_HIVE = 3;

    uint32 public constant REWARD_FOR_BURNING_BEE = 1200; //this is 12

    uint32 public constant BURN_AMOUNT_FOR_STAKING_BEE = 700; //this is 7

    uint32 public constant MIN_AMOUNT_FOR_ACTIVATE_BEE = 700; //this is 7

    uint32 public constant AMOUNT_TO_KEEP_ACTIVE = 23; //this is 0.23

    uint256 public constant MIN_BURN_AMOUNT_FOR_CLAIMING_BEE = 2300; //this is 23

    uint256 public constant AMOUNT_FOR_ACTIVATE_HIVE = 6900; //this is 69

    // solhint-disable-next-line
    uint16 public EPOCHS_BEFORE_INACTIVE_BEE; //number of epochs that a bee can claim honey before becoming inactive

    uint16 private lowestBeeId;

    //Used to keep track of how many were minted so far because bees can be burnt
    uint16 public totalMintedBees;

    uint256 public EPOCH_LENGTH;

    uint256 public HIVE_CLAIM_EPOCH_LENGTH;

    uint256 public STARTING_POINT;

    BearsDeluxeI public bears;

    HoneyTokenI public honey;

    HoneyHiveDeluxeI public hive;

    BeesDeluxeI public bees;

    Pause public paused;

    mapping(uint16 => uint256) private lastRewardOfHoneyPerBears;
    mapping(uint16 => uint256) private lastTimeClaimedBeePerHive;
    mapping(uint16 => Bee) private idsAndBees;

    struct Bee {
        uint256 id;
        uint8 active;
        //used to know how many epochs this bee can claim honey before becoming inactive.
        //in case it gets inactive, user must burn honey.
        //in case bee is staked, claim counter does not matter
        uint16 epochsLeft;
        uint8 staked;
        uint256 becameInactiveTime;
        //last time a bee claimed honey
        uint256 lastRewardTime;
        //last time a bee was fed (burnt honey to activate)
        uint256 lastTimeFed;
    }

    struct Pause {
        uint8 pauseBee;
        uint8 pauseHive;
        uint8 pauseBears;
    }

    /***********Events**************/
    event HoneyClaimed(address indexed _to, uint256 _amount);
    event HoneyHiveClaimed(address indexed _to, uint256 _amount);
    event BeeClaimed(address indexed _to, uint256 _amount);
    event HiveActivated(address indexed _owner, uint256 indexed _hiveId);
    event BeeActivated(address indexed _owner, uint256 indexed _beeId);
    event BeeKeptActive(address indexed _owner, uint256 indexed _beeId);
    event BeeBurnt(address indexed _owner, uint256 indexed _beeId);
    event BeeStaked(address indexed _owner, uint256 indexed _beeId);
    event BeeUnstaked(address indexed _owner, uint256 indexed _beeId);
    event StartingPointChanged(uint256 startingPoint);
    event SetContract(string indexed _contract, address _target);
    event EpochChange(string indexed epochType, uint256 _newValue);
    event PauseChanged(uint8 _pauseBears, uint8 _pauseHives, uint8 _pauseBees);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        EPOCHS_BEFORE_INACTIVE_BEE = 10; //number of rounds that a bee can claim honey before becoming inactive

        // solhint-disable-next-line
        // we set it to 2^16 = 65,536 as bees max supply is 20700 so the first id that is generated, will be lower than this
        lowestBeeId = type(uint16).max;

        EPOCH_LENGTH = 86400; //one day

        HIVE_CLAIM_EPOCH_LENGTH = 86400; //one day

        STARTING_POINT = 1635005744;
    }

    /***********External**************/

    /**
     * @dev claiming honey by owning a bear
     */
    function claimBearsHoney(uint16[] calldata _bearsIds) external nonReentrant {
        require(STARTING_POINT < block.timestamp, "Rewards didn't start");

        require(paused.pauseBears == 0, "Paused");

        uint256 amount;
        for (uint16 i = 0; i < _bearsIds.length; i++) {
            uint16 id = _bearsIds[i];

            //if not owner of the token then no rewards, usecase when someone tries to get rewards for
            //a token that isn't his or when he tries to get the rewards for an old token
            if (!bears.exists(id)) continue;
            if (bears.ownerOf(id) != msg.sender) continue;

            uint256 epochsToReward;
            uint256 lastReward = lastRewardOfHoneyPerBears[id];
            if (lastReward > 0 && lastReward > STARTING_POINT) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                epochsToReward = (block.timestamp - lastReward) / EPOCH_LENGTH;
            } else {
                // if no rewards claimed so far, then he gets rewards from when the rewards started.
                epochsToReward = (block.timestamp - STARTING_POINT) / EPOCH_LENGTH;
            }

            //accumulating honey to mint
            amount += HONEY_BEARS_REWARDS_PER_ROUND * epochsToReward;
            lastRewardOfHoneyPerBears[id] = block.timestamp;
        }
        require(amount > 0, "Nothing to claim");
        amount = amount * 1e16;

        //can not mint more than maxSupply
        if (honey.totalSupply() + amount > honey.maxSupply()) {
            amount = (honey.maxSupply() - honey.totalSupply());
        }

        honey.mint(msg.sender, amount);
        emit HoneyClaimed(msg.sender, amount);
    }

    /**
     * @dev claiming honey by owning a bee
     */
    // solhint-disable-next-line
    function claimBeesHoney(uint16[] calldata _beesIds) external nonReentrant {
        require(STARTING_POINT < block.timestamp, "Rewards didn't start");

        require(paused.pauseBee == 0, "Paused");

        uint256 amount = 0;

        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 id = _beesIds[i];

            if (!bees.exists(id)) continue;
            if (bees.ownerOf(id) != msg.sender) continue;
            Bee storage bee = idsAndBees[id];

            if (bee.id == 0 || bee.active == 0) continue;

            uint256 epochsToReward;
            uint256 lastReward = bee.lastRewardTime;

            if (lastReward > 0 && lastReward > STARTING_POINT) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                epochsToReward = (block.timestamp - lastReward) / EPOCH_LENGTH;
            } else {
                // if no rewards claimed so far, then he gets rewards from when the rewards started.
                epochsToReward = (block.timestamp - STARTING_POINT) / EPOCH_LENGTH;
            }

            //if bee not staked and someone has unclaimed honey for longer than the claim counter
            //then we can give him rewards just for the leftovers epochs.
            if (bee.staked == 0 && epochsToReward > bee.epochsLeft) {
                bee.active = 0;
                bee.becameInactiveTime = block.timestamp;
                epochsToReward = bee.epochsLeft;
            }

            if (bee.staked == 0) {
                amount += HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
                bee.epochsLeft -= uint16(epochsToReward);
                if (bee.epochsLeft == 0) {
                    bee.active = 0;
                    bee.becameInactiveTime = block.timestamp;
                }
            } else {
                amount += HONEY_STAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
            }

            bee.lastRewardTime = block.timestamp;
        }
        require(amount > 0, "Nothing to claim");
        amount = amount * 1e16;

        //can not mint more than maxSupply
        if (honey.totalSupply() + amount > honey.maxSupply()) {
            amount = (honey.maxSupply() - honey.totalSupply());
        }

        honey.mint(msg.sender, amount);
        emit HoneyClaimed(msg.sender, amount);
    }

    /**
     * @dev mints a Honey Hive by having a bear. You need to be the holder of the bear.
     */
    function mintHive(uint16 _bearsId) external nonReentrant {
        require(paused.pauseHive == 0, "Paused");

        require(msg.sender != address(0), "Can not mint to address 0");

        hive.mint(msg.sender, _bearsId);
        emit HoneyHiveClaimed(msg.sender, _bearsId);
    }

    /**
     * @dev mints a Bee by having a hive. You need to be the holder of the hive.
     */
    function mintBee(uint16 _hiveId) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        require(msg.sender != address(0), "Can not mint to address 0");

        require(hive.ownerOf(_hiveId) == msg.sender, "No Hive owned");

        require(honey.balanceOf(msg.sender) >= MIN_BURN_AMOUNT_FOR_CLAIMING_BEE * 1e16, "Not enough Honey");

        require(lastTimeClaimedBeePerHive[_hiveId] < block.timestamp - HIVE_CLAIM_EPOCH_LENGTH, "Mint bee cooldown");

        uint16 beeId = randBeeId();
        require(beeId > 0, "Mint failed");

        lastTimeClaimedBeePerHive[_hiveId] = block.timestamp;
        idsAndBees[beeId] = Bee(beeId, 1, EPOCHS_BEFORE_INACTIVE_BEE, 0, 0, block.timestamp, 0);
        totalMintedBees++;

        hive.increaseUsageOfMintingBee(_hiveId);

        honey.burn(msg.sender, MIN_BURN_AMOUNT_FOR_CLAIMING_BEE * 1e16);
        bees.mint(msg.sender, beeId);

        emit BeeClaimed(msg.sender, beeId);
    }

    /**
     * @dev after MAX_USAGE_PER_HIVE, a hive becomes inactive so it needs to be activated so we can mint more Bees
     */
    function activateHive(uint16 _hiveId) external nonReentrant {
        require(paused.pauseHive == 0, "Paused");

        require(hive.ownerOf(_hiveId) == msg.sender, "Not your hive");
        require(hive.getUsageOfMintingBee(_hiveId) >= MAX_USAGE_PER_HIVE, "Cap not reached");
        require(honey.balanceOf(msg.sender) >= AMOUNT_FOR_ACTIVATE_HIVE * 1e16, "Not enough Honey");

        honey.burn(msg.sender, AMOUNT_FOR_ACTIVATE_HIVE * 1e16);
        hive.resetUsageOfMintingBee(_hiveId);

        emit HiveActivated(msg.sender, _hiveId);
    }

    /**
     * @dev Exactly like in real world, bees become hungry for honey so,
     * after EPOCHS_BEFORE_INACTIVE_BEE epochs a bee needs
     * to be fed to become active again and start collecting Honey
     * Corresponds with Revive Bees
     */
    function activateBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;

            /**
             * when we activate a bee we do the following:
             * - we set active = 1 (meaning true)
             * - reset epochsLeft to MIN_USAGE_PER_BEE which is the max claiming before it becomes inactive
             * - set reward time as now so in case bee is staked, to not claim before this
             *   because on staking, we ignore the claim counter
             * - we set lastTimeFed for UI
             */
            amountOfHoney += MIN_AMOUNT_FOR_ACTIVATE_BEE;
            bee.active = 1;
            bee.epochsLeft = EPOCHS_BEFORE_INACTIVE_BEE;
            bee.lastRewardTime = block.timestamp;
            bee.lastTimeFed = block.timestamp;
            emit BeeActivated(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to activate");
        amountOfHoney = amountOfHoney * 1e16;

        require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        honey.burn(msg.sender, amountOfHoney);
    }

    /**
     * @dev If you want your bee to not become inactive and burn more Honey to fed it, you can
     * use this function to keep an Active bee, Active. Once this is called,
     * Honey will be burnt and bee can claim Honey again for EPOCHS_BEFORE_INACTIVE_BEE.
     * Corresponds with Feed Bees
     */
    function keepBeesActive(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            //this bee can not be kept active as it is inactive already, need to burn 7 honey
            if (bee.active == 0) continue;

            amountOfHoney += AMOUNT_TO_KEEP_ACTIVE;
            bee.epochsLeft = EPOCHS_BEFORE_INACTIVE_BEE;
            bee.lastTimeFed = block.timestamp;
            emit BeeKeptActive(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to keep active");
        amountOfHoney = amountOfHoney * 1e16;

        require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        honey.burn(msg.sender, amountOfHoney);
    }

    /**
     * @dev In case you got bored of one of your Bee, or it got too old, you can burn it and receive Honey
     */
    function burnBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];

            //in case a bee is burnt from BeesDeluxe contract, should neved happen.
            if (bees.ownerOf(_beeId) == address(0)) {
                delete idsAndBees[_beeId];
                return;
            }
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            delete idsAndBees[_beeId];
            amountOfHoney += REWARD_FOR_BURNING_BEE;
            bees.burnByQueen(_beeId);
            emit BeeBurnt(msg.sender, _beeId);
        }
        amountOfHoney = amountOfHoney * 1e16;

        require(amountOfHoney > 0, "Nothing to burn");
        require(honey.totalSupply() + amountOfHoney <= honey.maxSupply(), "Honey cap reached");

        honey.mint(msg.sender, amountOfHoney);
    }

    /**
     * @dev In case you are a long term player, you can stake your Bee to avoid the bee being inactivated.
     * Of course this comes with a downside, the amount of Honey you can claim, shrinks
     * Corresponds with Put Bees to Work
     */
    function stakeBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        uint256 amountOfHoney = 0;
        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bee.active == 0) continue;
            if (bee.staked == 1) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            amountOfHoney += BURN_AMOUNT_FOR_STAKING_BEE;
            bee.staked = 1;
            emit BeeStaked(msg.sender, _beeId);
        }

        require(amountOfHoney > 0, "Nothing to stake");
        amountOfHoney = amountOfHoney * 1e16;

        require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough honey");
        if (amountOfHoney > 0) honey.burn(msg.sender, amountOfHoney);
    }

    /**
     * @dev You got enough of your staked bee, you can unstake it to get back to the normal rewards but also
     * with the possibility to get inactivated
     * Corresponds with Stop Work
     */
    function unstakeBees(uint16[] calldata _beesIds) external nonReentrant {
        require(paused.pauseBee == 0, "Paused");

        for (uint16 i = 0; i < _beesIds.length; i++) {
            uint16 _beeId = _beesIds[i];
            Bee storage bee = idsAndBees[_beeId];
            if (bee.id == 0) continue;
            if (bee.staked == 0) continue;
            if (bees.ownerOf(_beeId) != msg.sender) continue;
            bee.staked = 0;
            bee.lastTimeFed = block.timestamp;
            emit BeeUnstaked(msg.sender, _beeId);
        }
    }

    /***********Internal**************/

    // solhint-disable-next-line
    function randBeeId() internal returns (uint16 _id) {
        uint16 entropy;
        uint16 maxSupply = uint16(bees.getMaxSupply());
        require(totalMintedBees < maxSupply, "MAX_SUPPLY reached");
        while (true) {
            uint16 rand = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            block.difficulty,
                            block.timestamp,
                            block.number,
                            totalMintedBees,
                            entropy
                        )
                    )
                )
            );
            _id = rand % maxSupply;
            entropy++;
            if (_id == 0) _id = maxSupply;

            if (idsAndBees[_id].id == 0) {
                if (_id < lowestBeeId) lowestBeeId = _id;
                return _id;
            }
            if (entropy > 2) {
                bool wentOverOnce;
                while (idsAndBees[lowestBeeId].id > 0) {
                    lowestBeeId++;
                    if (lowestBeeId == maxSupply) {
                        if (wentOverOnce) return 0;
                        wentOverOnce = true;
                        lowestBeeId = 1;
                    }
                }
                _id = lowestBeeId;
                return _id;
            }
        }
    }

    /***********Views**************/
    /**
     * @dev Get a time when the Bear was last rewarded with honey
     */
    function getLastRewardedByBear(uint16 _bearId) external view returns (uint256) {
        return lastRewardOfHoneyPerBears[_bearId];
    }

    /**
     * @dev Get a time when the Bee was last rewarded with honey
     */
    function getLastRewardedByBee(uint16 _beeId) external view returns (uint256) {
        return idsAndBees[_beeId].lastRewardTime;
    }

    /**
     * @dev Get the whole state of the bee
     */
    function getBeeState(uint16 _beeId) external view returns (Bee memory) {
        return idsAndBees[_beeId];
    }

    /**
     * @dev Get last time you claimed a bee
     */
    function getLastTimeBeeClaimed(uint16 _hiveId) external view returns (uint256) {
        return lastTimeClaimedBeePerHive[_hiveId];
    }

    /**
     * @dev Get states of multiple Bees
     */
    function getBeesState(uint16[] calldata _beesIds) external view returns (Bee[] memory beesToReturn) {
        beesToReturn = new Bee[](_beesIds.length);
        for (uint16 i = 0; i < _beesIds.length; i++) {
            beesToReturn[i] = idsAndBees[_beesIds[i]];
        }
        return beesToReturn;
    }

    /**
     * @dev Get total unclaimed Honey for a holder
     */
    function getUnclaimedHoneyForBears(address _owner) external view returns (uint256 amount) {
        uint256[] memory bearsIds = bears.tokensOfOwner(_owner);
        for (uint16 i = 0; i < bearsIds.length; i++) {
            uint16 id = uint16(bearsIds[i]);

            //if not owner of the token then no rewards, usecase when someone tries to get rewards for
            //a token that isn't his or when he tries to get the rewards for an old token
            if (!bears.exists(id)) continue;
            if (bears.ownerOf(id) != _owner) continue;

            uint256 epochsToReward;
            uint256 lastReward = lastRewardOfHoneyPerBears[id];
            if (lastReward > 0 && lastReward > STARTING_POINT) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                epochsToReward = (block.timestamp - lastReward) / EPOCH_LENGTH;
            } else {
                if (block.timestamp < STARTING_POINT)
                    //if the starting point it's in the future then return 0
                    epochsToReward = 0;
                    // if no rewards claimed so far, then he gets rewards from when the rewards started.
                else epochsToReward = (block.timestamp - STARTING_POINT) / EPOCH_LENGTH;
            }

            //accumulating honey to mint
            amount += HONEY_BEARS_REWARDS_PER_ROUND * epochsToReward;
        }
        amount = amount * 1e16;
    }

    /**
     * @dev Get total unclaimed Honey for a holder
     */
    // solhint-disable-next-line
    function getUnclaimedHoneyForBees(address _owner) external view returns (uint256 amount) {
        uint256[] memory beesIds = bees.tokensOfOwner(_owner);
        for (uint16 i = 0; i < beesIds.length; i++) {
            uint16 id = uint16(beesIds[i]);

            if (!bees.exists(id)) continue;
            if (bees.ownerOf(id) != _owner) continue;
            Bee storage bee = idsAndBees[id];

            if (bee.id == 0 || bee.active == 0) continue;

            uint256 epochsToReward;
            uint256 lastReward = bee.lastRewardTime;

            if (lastReward > 0 && lastReward > STARTING_POINT) {
                // solhint-disable-next-line
                //we get whole numbers for example if someone claims after 1 round and a half, he should be rewarded for 1 round.
                epochsToReward = (block.timestamp - lastReward) / EPOCH_LENGTH;
            } else {
                if (block.timestamp < STARTING_POINT)
                    //if the starting point it's in the future then return 0
                    epochsToReward = 0;
                    // if no rewards claimed so far, then he gets rewards from when the rewards started.
                else epochsToReward = (block.timestamp - STARTING_POINT) / EPOCH_LENGTH;
            }

            //if bee not staked and someone has unclaimed honey before hive becoming inactive
            if (bee.staked == 0 && epochsToReward > bee.epochsLeft) {
                epochsToReward = bee.epochsLeft;
            }

            if (bee.staked == 0) {
                amount += HONEY_UNSTAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
            } else {
                amount += HONEY_STAKED_BEE_REWARDS_PER_EPOCH * epochsToReward;
            }
        }
        amount = amount * 1e16;
    }

    /***********Settes & Getters**************/

    function setBears(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        bears = BearsDeluxeI(_contract);
        emit SetContract("BearsDeluxe", _contract);
    }

    function setHoney(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        honey = HoneyTokenI(_contract);
        emit SetContract("HoneyToken", _contract);
    }

    function setHive(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        hive = HoneyHiveDeluxeI(_contract);
        emit SetContract("HoneyHive", _contract);
    }

    function setBees(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        bees = BeesDeluxeI(_contract);
        emit SetContract("BeesDeluxe", _contract);
    }

    function setInitialStartingPoint(uint256 _startingPoint) external onlyOwner {
        STARTING_POINT = _startingPoint;
        emit StartingPointChanged(_startingPoint);
    }

    function getInitialStartingPoint() external view returns (uint256) {
        return STARTING_POINT;
    }

    function setHoneyEpochLength(uint256 _epochLength) external onlyOwner {
        EPOCH_LENGTH = _epochLength;
        emit EpochChange("HoneyEpochLength", _epochLength);
    }

    function setHiveClaimEpochLength(uint256 _epochLength) external onlyOwner {
        HIVE_CLAIM_EPOCH_LENGTH = _epochLength;
        emit EpochChange("HiveEpochLength", _epochLength);
    }

    function setNoOfEpochsBeforeInactiveBee(uint16 _epochs) external onlyOwner {
        EPOCHS_BEFORE_INACTIVE_BEE = _epochs;
        emit EpochChange("NoOfEpochBeforeInactiveBee", _epochs);
    }

    /**
     * @dev Sets the activitiy of the Bears/Bee/Hive as paused or not, only use in case of emergency.
     * 1 = Paused
     * 0 = Active
     */
    function setPauseState(
        uint8 _pauseBears,
        uint8 _pauseHives,
        uint8 _pauseBees
    ) external onlyOwner {
        paused.pauseBears = _pauseBears;
        paused.pauseHive = _pauseHives;
        paused.pauseBee = _pauseBees;
        emit PauseChanged(_pauseBears, _pauseHives, _pauseBees);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract BearsDeluxeI is Ownable, IERC721 {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint256);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract HoneyTokenI is Ownable, IERC20 {
    function mint(address _owner, uint256 _amount) external virtual;
    function burn(address _owner, uint256 _amount) external virtual;

    function maxSupply() external pure virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract BeesDeluxeI is Ownable, IERC721, IERC721Enumerable {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external view virtual returns (uint256);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function totalSupply() public view virtual returns (uint256);

    function burnByQueen(uint256 _tokenId) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract HoneyHiveDeluxeI is Ownable, IERC721 {
    function mint(address _owner, uint256 _bearId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint256);

    function increaseUsageOfMintingBee(uint256 _hiveId) external virtual;

    function getUsageOfMintingBee(uint256 _hiveId) external view virtual returns (uint8);

    function resetUsageOfMintingBee(uint256 _hiveId) external virtual;

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function totalSupply() public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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