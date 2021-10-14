// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "../ClamNFT/IClam.sol";
import "../RNG/IRNG.sol";
import "./IPearl.sol";
import "../IGemToken.sol";
import "../farming/IPearlProductionTimeReduction.sol";
import "../farming/IClamBonus.sol";
import "./IPearlFarm.sol";

/// @title PearlFarm
/// @notice Staking clams and giving birth to pearls
contract PearlFarm is Initializable, OwnableUpgradeable, IERC721ReceiverUpgradeable, IPearlFarm {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    IGemToken public gemToken;
    IPearl public pearl;
    IClam public clam;
    IRNG public rng;
    IPearlProductionTimeReduction public productionTimeReduction;
    IClamBonus public clamBonus;
    address public treasury;
    uint256 public pearlPrice;
    uint256 public burnRateProduction;
    uint256 public burnRateReclaim;
    uint256 public maximumNumberOfClamsStakedPerUser;

    mapping(address => mapping(uint256 => bytes32)) public rngRequestHashForProducedPearl;
    mapping(address => mapping(uint256 => bytes32)) public rngRequestHashForReclaiming;

    mapping(address => mapping(uint256 => uint256)) public gemsTransferred;

    mapping(uint256 => address) public clamIdToStaker;

    // Keeps track of clams that have generated bonus rewards
    // entries are not deleted because rewards are given out only once
    mapping(uint256 => bool) public clamBonusRewarded;
    mapping(uint256 => bool) public override productionTimeReduced;

    struct StakingInfo {
        uint256 timeSpentStaking;
        uint256 stakingStartDate;
        bool previouslyStaked;
    }

    struct StakedClamsSet {
        mapping(address => EnumerableSetUpgradeable.UintSet) stakedClams;
        mapping(uint256 => StakingInfo) stakingData;
    }

    StakedClamsSet private stakedClamsSet;

    event ClamStaked(address indexed farmer, uint256 clamId);
    event ClamUnstaked(address indexed farmer, uint256 clamId);
    event GemReclaimed(address indexed farmer, uint256 clamId);
    event PearlCollectionPrepared(address indexed farmer, uint256 clamId);
    event PearlCollected(address indexed farmer, uint256 clamId);
    event PearlPriceSet(uint256 price);
    event MaximumNumberOfClamsStakedPerUserSet(uint256 number);
    event BurnRateProductionSet(uint256 burnRateProduction);
    event BurnRateReclaimSet(uint256 burnRateReclaim);
    event TreasurySet(address treasury);
    event PearlProductionTimeReductionSet(address _pearlProductionTimeReduction);
    event RNGSet(address rngContractAddress);
    event RNGRequestHashSetToZero(address account, uint256 _clamId);

    modifier isPossibleToStake(uint256 clamId) {
        require(clam.ownerOf(clamId) == msg.sender, "PearlFarm: This isn't your clam. Naughty, naughty.");
        require(
            rngRequestHashForProducedPearl[msg.sender][clamId] == bytes32(0),
            "PearlFarm: This clam already has a pearl to be collected!"
        );
        require(clam.canStillProducePearls(clamId), "PearlFarm: Your clam can't produce pearls anymore.");
        _;
    }

    modifier canBeReclaimed(uint256 clamId) {
        require(clamIdToStaker[clamId] == address(0), "PearlFarm: Please unstake before reclaiming.");
        require(clam.ownerOf(clamId) == msg.sender, "PearlFarm: this isn't your clam. Naughty, naughty.");
        require(gemsTransferred[msg.sender][clamId] != 0, "PearlFarm: No Gem to reclaim for this clam.");
        _;
    }

    modifier senderIsStaker(uint256 clamId) {
        require(clamIdToStaker[clamId] == msg.sender, "PearlFarm: You are not tracked as a staker of this clam!");
        _;
    }

    function initialize(
        address _gemToken,
        address _pearl,
        address _clam,
        address _rng,
        address _productionTimeReduction,
        address _treasury,
        address _clamBonus,
        uint256 _pearlPrice,
        uint256 _burnRateProduction,
        uint256 _burnRateReclaim
    ) public initializer {
        require(
            _gemToken != address(0) &&
                _pearl != address(0) &&
                _clam != address(0) &&
                _rng != address(0) &&
                _productionTimeReduction != address(0) &&
                _treasury != address(0) &&
                _clamBonus != address(0),
            "PearlFarm: empty addresses"
        );

        __Ownable_init();
        gemToken = IGemToken(_gemToken);
        pearl = IPearl(_pearl); // add minter role for this in pearl contract
        clam = IClam(_clam);
        rng = IRNG(_rng); // add bonafide role for this in rng contract
        productionTimeReduction = IPearlProductionTimeReduction(_productionTimeReduction);
        clamBonus = IClamBonus(_clamBonus);
        treasury = _treasury;
        pearlPrice = _pearlPrice;
        burnRateProduction = _burnRateProduction;
        burnRateReclaim = _burnRateReclaim;
        maximumNumberOfClamsStakedPerUser = 20;
    }

    /// @notice moves the Gem attached to a staked Clam to the new owner,
    /// @notice removes the staking history as the reduction is applied to the internal Clam info.
    /// @param clamId Clam id
    /// @param oldOwner the new owner
    /// @param newOwner the old owner
    function registerClamTransfer(
        uint256 clamId,
        address oldOwner,
        address newOwner
    ) external override {
        require(address(clam) != address(0), "PearlFarm: clam address is not set");
        require(msg.sender == address(clam), "PearlFarm: !clam");
        // only act when a pearl is in production
        if (gemsTransferred[oldOwner][clamId] != 0) {
            productionTimeReduced[clamId] = true;
            gemsTransferred[newOwner][clamId] = gemsTransferred[oldOwner][clamId];
            gemsTransferred[oldOwner][clamId] = 0;
            removeFinallyFromStakedClams(clamId);
        }
    }

    function addToStakedClams(uint256 clamId) internal {
        bool added = stakedClamsSet.stakedClams[msg.sender].add(clamId);
        require(added, "PearlFarm: Clam is already staked.");
        require(
            stakedClamsSet.stakedClams[msg.sender].length() <= maximumNumberOfClamsStakedPerUser,
            "PearlFarm: Cannot stake more Clams"
        );

        uint256 previousStakingTime = 0;
        if (stakedClamsSet.stakingData[clamId].previouslyStaked) {
            previousStakingTime = stakedClamsSet.stakingData[clamId].timeSpentStaking;
        }
        stakedClamsSet.stakingData[clamId] = StakingInfo(previousStakingTime, block.timestamp, true);
    }

    function removeFromStakedClams(uint256 clamId) internal {
        bool removed = stakedClamsSet.stakedClams[msg.sender].remove(clamId);
        require(removed, "PearlFarm: Clam is currently not staked.");
        uint256 lastStakingPeriod = block.timestamp.sub(stakedClamsSet.stakingData[clamId].stakingStartDate);
        stakedClamsSet.stakingData[clamId].timeSpentStaking = stakedClamsSet.stakingData[clamId].timeSpentStaking.add(
            lastStakingPeriod
        );
        stakedClamsSet.stakingData[clamId].stakingStartDate = 0;
        clamBonus.removeRarityFromList(msg.sender, clamId);
    }

    function removeFinallyFromStakedClams(uint256 clamId) internal {
        address clamOwner = clam.ownerOf(clamId);
        stakedClamsSet.stakedClams[clamOwner].remove(clamId); // not checking return value as we definitely want to delete from stakingData
        delete stakedClamsSet.stakingData[clamId];

        productionTimeReduction.removeClamStakingInfo(clamOwner, clamId);
        clamBonus.removeRarityFromList(clamOwner, clamId);
    }

    function getStakedClamIds(address staker) external view returns (uint256[] memory) {
        uint256[] memory stakedIds = new uint256[](stakedClamsSet.stakedClams[staker].length());
        for (uint256 i = 0; i < stakedClamsSet.stakedClams[staker].length(); i++) {
            stakedIds[i] = stakedClamsSet.stakedClams[staker].at(i);
        }
        return stakedIds;
    }

    // @notice User, who has staked a unique clam, must have added GEM with the staking event. This is tracked in gemsTransferred.
    function hasClamBeenStakedBeforeByUser(address user, uint256 clamId) external view returns (bool) {
        return gemsTransferred[user][clamId] != 0;
    }

    function stakeClams(uint256[] memory clamIds) external payable {
        for (uint256 i = 0; i < clamIds.length; i++) {
            stakeClam(clamIds[i]);
        }
    }

    /// @notice Stake clam with gem (pearlPrice). Add bonus rewards if clam has not been rewarded bonus yet
    /// @param clamId Clam id
    function stakeClam(uint256 clamId) public payable isPossibleToStake(clamId) {
        require(
            gemsTransferred[msg.sender][clamId] == 0,
            "PearlFarm: This clam was already staked before, please call 'stakeClamAgain' instead."
        );

        gemToken.transferFrom(msg.sender, address(this), pearlPrice);
        gemsTransferred[msg.sender][clamId] = pearlPrice;

        clam.safeTransferFrom(msg.sender, address(this), clamId);
        clamIdToStaker[clamId] = msg.sender;
        addToStakedClams(clamId);
        clam.setNewProductionStart(clamId, block.timestamp);
        productionTimeReduction.registerClamStaking(msg.sender, clamId);

        if (!clamBonusRewarded[clamId]) {
            // If the user is not farming lp tokens in our bank contract, then no rewards are given
            // If a different clam, with the same rarity is already being staked, no rewards are given
            // The conditions above will be checked in ClamBonus.sol
            // Staking a clam can only generate rewards once, if conditions are not met, then the chance has passed
            clamBonusRewarded[clamId] = true;
            clamBonus.calcBonusAndSetRewards(msg.sender, clamId);
        }

        emit ClamStaked(msg.sender, clamId);
    }

    /// @notice Stake previously staked clam without gem (pearlPrice).
    /// @param clamId Clam id
    function stakeClamAgain(uint256 clamId) external payable isPossibleToStake(clamId) {
        require(
            gemsTransferred[msg.sender][clamId] != 0,
            "PearlFarm: This clam was not staked yet, please call 'stakeClam' instead."
        );

        clam.safeTransferFrom(msg.sender, address(this), clamId);
        productionTimeReduced[clamId] = false;
        clamIdToStaker[clamId] = msg.sender;
        addToStakedClams(clamId);
        productionTimeReduction.registerClamStaking(msg.sender, clamId);

        emit ClamStaked(msg.sender, clamId);
    }

    /// @notice Unstake multiple clams.
    /// @param clamIds Clam ids
    function unstakeClams(uint256[] memory clamIds) external {
        for (uint256 i = 0; i < clamIds.length; i++) {
            unstakeClam(clamIds[i]);
        }
    }

    /// @notice Unstake clam.
    /// @param clamId Clam id
    function unstakeClam(uint256 clamId) public senderIsStaker(clamId) {
        require(
            rngRequestHashForProducedPearl[msg.sender][clamId] == bytes32(0),
            "PearlFarm: This clam has a pearl to be collected!"
        );

        clam.safeTransferFrom(address(this), msg.sender, clamId);
        delete clamIdToStaker[clamId];
        removeFromStakedClams(clamId);
        productionTimeReduction.registerClamUnstaking(msg.sender, clamId);

        emit ClamUnstaked(msg.sender, clamId);
    }

    /// @notice Prepare the generation of a random number which will be used when reclaiming the attached Gem.
    /// @param clamId Clam id
    function prepareReclaiming(uint256 clamId) external payable canBeReclaimed(clamId) {
        uint256 oracleFee = rng.getOracleFee();
        require(msg.value >= oracleFee, "PearlFarm: Not enough BNB for the oracle fee");

        bytes32 hashRequest = rng.requestRNG{value: oracleFee}(msg.sender);
        rngRequestHashForReclaiming[msg.sender][clamId] = hashRequest;
    }

    /// @notice Reclaim the attached Gem (need to call 'prepareReclaiming' first).
    /// @param clamId Clam id
    function reclaimGems(uint256 clamId) external payable canBeReclaimed(clamId) {
        require(
            rngRequestHashForReclaiming[msg.sender][clamId] != bytes32(0),
            "PearlFarm: Please prepare reclaiming first!"
        );
        bytes32 requestHash = rngRequestHashForReclaiming[msg.sender][clamId];
        rngRequestHashForReclaiming[msg.sender][clamId] = bytes32(0);

        uint256 rand = rng.getRNGFromHashRequest(requestHash);
        require(
            rand != uint256(0),
            "PearlFarm: This clam does not allow to reclaim Gem tokens currently. Please try again in a few seconds."
        );
        clam.setNewProductionDelay(clamId, rand);

        //even though the clam is not staked anymore, it's staking data still needs to be deleted
        removeFinallyFromStakedClams(clamId);
        uint256 transferredGem = gemsTransferred[msg.sender][clamId];
        gemsTransferred[msg.sender][clamId] = 0;

        uint256 burnAmount = transferredGem.mul(burnRateReclaim).div(100);
        gemToken.burn(burnAmount);
        gemToken.transfer(msg.sender, transferredGem.sub(burnAmount));

        emit GemReclaimed(msg.sender, clamId);
    }

    /// @notice Prepare the collection of a produced Pearl.
    /// @param clamId Clam id
    function propClamOpenForPearl(uint256 clamId) external payable senderIsStaker(clamId) {
        require(
            rngRequestHashForProducedPearl[msg.sender][clamId] == bytes32(0),
            "PearlFarm: this clam already has a pearl to be collected!"
        );

        require(
            clam.canCurrentlyProducePearl(clamId),
            "PearlFarm: Your clam either can't produce anymore or is not ready yet to create pearls."
        );

        require(
            isPearlProductionTimeYet(clamId),
            "PearlFarm: Don't be greedy. Your clam needs more time to produce a pearl."
        );

        uint256 oracleFee = rng.getOracleFee();
        require(msg.value >= oracleFee, "PearlFarm: Not enough BNB for the oracle fee");

        bytes32 hashRequest = rng.requestRNG{value: oracleFee}(msg.sender);
        rngRequestHashForProducedPearl[msg.sender][clamId] = hashRequest;

        emit PearlCollectionPrepared(msg.sender, clamId);
    }

    /// @notice collect a pearly pearl from your Clam
    /// @dev handle gem attached to staked clam, unstake clam and collect pearl
    /// @param clamId Clam id
    function collectPearl(uint256 clamId) external senderIsStaker(clamId) {
        require(
            rngRequestHashForProducedPearl[msg.sender][clamId] != bytes32(0),
            "PearlFarm: Be sure to open your clam first!"
        );

        uint256 transferredGem = gemsTransferred[msg.sender][clamId];
        gemsTransferred[msg.sender][clamId] = 0;

        uint256 burnAmount = transferredGem.mul(burnRateProduction).div(100);
        gemToken.burn(burnAmount);
        gemToken.transfer(treasury, transferredGem.sub(burnAmount));

        bytes32 requestHash = rngRequestHashForProducedPearl[msg.sender][clamId];
        rngRequestHashForProducedPearl[msg.sender][clamId] = bytes32(0);

        uint256 rand = rng.getRNGFromHashRequest(requestHash);
        require(
            rand != uint256(0),
            "PearlFarm: This clam does not allow to collect pearls currently. Please try again in a few seconds."
        );

        IClam.ClamInfo memory clamInfo = clam.getClamData(clamId);
        uint256 pearlsRemaining = clamInfo.pearlProductionCapacity.sub(clamInfo.pearlsProduced);
        clam.setNewProductionDelay(clamId, rand);
        clam.setNewProductionStart(clamId, 0);

        clam.incrementPearlCounter(clamId, pearl.nextPearlId());
        clam.safeTransferFrom(address(this), msg.sender, clamId);
        productionTimeReduced[clamId] = false;
        removeFinallyFromStakedClams(clamId);
        (uint8[10] memory pearlBodyColorNumber, uint8[6] memory pearlShapeNumber) = clam.getPearlTraits(clamId);

        pearl.mint(msg.sender, rand, pearlsRemaining, pearlBodyColorNumber, pearlShapeNumber);

        emit PearlCollected(msg.sender, clamId);
    }

    /// @notice Calculates the remaining pearl production time, taking reduction effects into account.
    /// @param clamId Clam id
    /// @return the remaining time until pearl production is finished
    function getRemainingPearlProductionTime(uint256 clamId) public view override returns (uint256) {
        StakingInfo memory stakingInfo = stakedClamsSet.stakingData[clamId];
        uint256 initialProductionDelay = clam.getPearlProductionDelay(clamId);
        if (!stakingInfo.previouslyStaked) {
            return initialProductionDelay;
        }
        bool currentlyStaked = clamIdToStaker[clamId] != address(0);
        uint256 pearlProductionDelay;
        if (!productionTimeReduced[clamId]) {
            address staker = currentlyStaked ? clamIdToStaker[clamId] : clam.ownerOf(clamId);
            uint256 reduction = productionTimeReduction.calculateProductionTimeReduction(staker, clamId);
            //percentage formula: Y = X * P / 100 -> because P is in our case P * 100 -> Y = X * P / 10000
            uint256 reducedTime = initialProductionDelay.mul(reduction).div(10000);
            pearlProductionDelay = initialProductionDelay.sub(reducedTime);
        } else {
            pearlProductionDelay = initialProductionDelay;
        }

        uint256 pearlProductionTime;
        if (stakingInfo.timeSpentStaking > pearlProductionDelay) {
            pearlProductionTime = 0;
        } else if (currentlyStaked) {
            uint256 totalStakingTime = stakingInfo.timeSpentStaking.add(
                block.timestamp.sub(stakingInfo.stakingStartDate)
            );
            if (totalStakingTime > pearlProductionDelay) {
                pearlProductionTime = 0;
            } else {
                pearlProductionTime = pearlProductionDelay.sub(totalStakingTime);
            }
        } else {
            pearlProductionTime = pearlProductionDelay.sub(stakingInfo.timeSpentStaking);
        }
        return pearlProductionTime;
    }

    /// @notice Indicates whether pearl production time has arrived.
    /// @param clamId Clam id
    /// @return true or false
    function isPearlProductionTimeYet(uint256 clamId) public view returns (bool) {
        //getRemainingPearlProductionTime checks if currently or previously staked
        return getRemainingPearlProductionTime(clamId) == 0;
    }

    /// Setters

    function setPearlPrice(uint256 _price) external onlyOwner {
        pearlPrice = _price;

        emit PearlPriceSet(_price);
    }

    function setRng(address _rng) public onlyOwner {
        rng = IRNG(_rng);

        emit RNGSet(_rng);
    }

    function setBurnRateProduction(uint256 _burnRateProduction) external onlyOwner {
        require(_burnRateProduction <= 100, "PearlFarm: burn rate larger than 100");

        burnRateProduction = _burnRateProduction;

        emit BurnRateProductionSet(_burnRateProduction);
    }

    function setBurnRateReclaim(uint256 _burnRateReclaim) external onlyOwner {
        require(_burnRateReclaim <= 100, "PearlFarm: burn rate larger than 100");

        burnRateReclaim = _burnRateReclaim;
        emit BurnRateReclaimSet(_burnRateReclaim);
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0), "PearlFarm: empty address");

        treasury = _treasury;

        emit TreasurySet(_treasury);
    }

    function setMaximumNumberOfClamsStakedPerUser(uint256 _newNumber) external onlyOwner {
        maximumNumberOfClamsStakedPerUser = _newNumber;

        emit MaximumNumberOfClamsStakedPerUserSet(_newNumber);
    }

    function setPearlProductionTimeReduction(address _pearlProductionTimeReduction) external onlyOwner {
        require(_pearlProductionTimeReduction != address(0), "PearlFarm: empty address");

        productionTimeReduction = IPearlProductionTimeReduction(_pearlProductionTimeReduction);

        emit PearlProductionTimeReductionSet(_pearlProductionTimeReduction);
    }

    /// @dev used for when RNG has failed to deliver
    function setRngRequestHashForProducedPearlToZero(address _account, uint256 _clamId) external onlyOwner {
        rngRequestHashForProducedPearl[_account][
            _clamId
        ] = 0x0000000000000000000000000000000000000000000000000000000000000000;

        emit RNGRequestHashSetToZero(_account, _clamId);
    }

    /// @dev used for when RNG has failed to deliver
    function setRngRequestHashForReclaimingZero(address _account, uint256 _clamId) external onlyOwner {
        rngRequestHashForReclaiming[_account][
            _clamId
        ] = 0x0000000000000000000000000000000000000000000000000000000000000000;

        emit RNGRequestHashSetToZero(_account, _clamId);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
library SafeMathUpgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IClam is IERC721EnumerableUpgradeable {
    struct ClamInfo {
        bool isMaxima;
        bool isAlive;
        uint256 birthTime;
        uint256 pearlsProduced;
        uint256 pearlProductionDelay;
        uint256 pearlProductionCapacity;
        uint256 dna;
        uint256 pearlProductionStart;
        uint256[] producedPearlIds;
        uint256 gemBoost;
    }

    function mint(
        address,
        uint256,
        bool
    ) external;

    function mintMaxima(address, uint256) external;

    function mintCommunityReward(
        address,
        uint256,
        bool
    ) external;

    function canCurrentlyProducePearl(uint256) external returns (bool);

    function canStillProducePearls(uint256) external view returns (bool);

    function incrementPearlCounter(uint256, uint256) external;

    function setNewProductionDelay(uint256, uint256) external;

    function getPearlProductionDelay(uint256) external view returns (uint256);

    function setNewProductionStart(uint256, uint256) external;

    function getPearlProductionStart(uint256) external view returns (uint256);

    function getClamData(uint256) external view returns (ClamInfo memory);

    function getPearlTraits(uint256) external view returns (uint8[10] memory, uint8[6] memory);

    function burn(uint256) external;

    function calculateBonusRewards(
        uint256 baseGemRewards,
        uint256 size,
        uint256 lifespan,
        uint256 rarityValue
    ) external pure returns (uint256);

    function currentBaseGemRewards() external returns (uint256);

    function setCurrentBaseGemRewards(uint256 baseGemRewards) external;

    event ClamHarvested(address user, uint256 clamId);
    event IncubationTimeSet(uint256 incubationTime);
    event ProductionDelaySet(uint256 clamId);
    event ProductionStartSet(uint256 clamId, uint256 timestamp);
    event PearlCounterIncremented(uint256 clamId);
    event ClamMaximaMonthlyCapSet(uint256 newCap);
    event DNADecoderSet(address newDnaDecoder);
    event PriceForShellSet(uint256 clamPriceForShell, uint256 pearlPriceForShell);
    event ProductionCapacitySet(uint256 minPearlProductionCapacity, uint256 maxPearlProductionCapacity);
    event ProductionDelayRangeSet(uint256 minPearlProductionDelay, uint256 maxPearlProductionDelay);
    event CommunityRewardedClam(address recipient, uint256 dna);
    event ClamMaximaMinted(address recipient, uint256 dna);
    event SetCurrentBaseGemRewards(uint256 baseGemRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IRNG {
    function getOracleFee() external view returns (uint256);

    function requestRNG(address) external payable returns (bytes32);

    function getRNGFromHashRequest(bytes32) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IPearl is IERC721EnumerableUpgradeable {
    /// @notice Info about pearl
    /// `birthTime` block timestamp of birth
    /// `dna` random generated number
    /// `pearlsRemaining` amount of pearls that mother clam had left when giving birth to this pearl. The lower the amount, the rarer the pearl should be
    struct PearlInfo {
        uint256 birthTime;
        uint256 dna;
        uint256 pearlsRemaining;
        uint256 gemBoost;
    }

    function pearlData(uint256)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function mint(
        address,
        uint256,
        uint256,
        uint8[10] memory,
        uint8[6] memory
    ) external;

    function burn(uint256) external;

    function nextPearlId() external view returns (uint256);

    function setCurrentBaseGemRewards(uint256 baseGemRewards) external;

    function currentBaseGemRewards() external returns (uint256);

    function calculateBonusRewards(
        uint256 baseGemRewards,
        uint256 size,
        uint256 lustre,
        uint256 nacreQuality,
        uint256 surface,
        uint256 rarityValue
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./libs/IBEP20.sol";

interface IGemToken is IBEP20 {
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPearlProductionTimeReduction {
    function calculateProductionTimeReduction(address, uint256) external view returns (uint256);

    function registerTokenStaking(
        address,
        uint256,
        address
    ) external;

    function registerTokenUnstaking(
        address,
        uint256,
        address
    ) external;

    function registerClamStaking(address, uint256) external;

    function registerClamUnstaking(address, uint256) external;

    function removeClamStakingInfo(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IClamBonus {
    function calcBonusAndSetRewards(address, uint256) external;

    function removeRarityFromList(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPearlFarm {
    function productionTimeReduced(uint256) external view returns (bool);

    function getRemainingPearlProductionTime(uint256) external view returns (uint256);

    function registerClamTransfer(
        uint256,
        address,
        address
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     */
    function mint(address beneficiary, uint256 amount) external returns (bool);

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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address, uint256) external returns (bool);
}