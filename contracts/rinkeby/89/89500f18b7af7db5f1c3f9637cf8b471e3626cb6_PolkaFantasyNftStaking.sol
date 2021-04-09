/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.6.8;

interface IERC20 {

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}



pragma solidity >=0.6.0 <0.8.0;


library SafeCast {

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}



pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}



pragma solidity >=0.6.0 <0.8.0;

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    function mul(int256 a, int256 b) internal pure returns (int256) {
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}



pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



pragma solidity >=0.6.0 <0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity >=0.6.0 <0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



pragma solidity >=0.6.0 <0.8.0;


abstract contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}



pragma solidity 0.6.8;

interface IERC1155TokenReceiver {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}



pragma solidity 0.6.8;



abstract contract ERC1155TokenReceiver is IERC1155TokenReceiver, ERC165 {

    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    bytes4 internal constant _ERC1155_REJECTED = 0xffffffff;

    constructor() internal {
        _registerInterface(type(IERC1155TokenReceiver).interfaceId);
    }
}



pragma solidity 0.6.8;







abstract contract NftStakingV2 is ERC1155TokenReceiver, Ownable {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using ERC1155721SafeTransferFallback for IERC1155721Transferrable;

    event RewardsAdded(uint256 startPeriod, uint256 endPeriod, uint256 rewardsPerCycle);

    event Started();

    event NftStaked(address staker, uint256 cycle, uint256 tokenId, uint256 weight);
    event NftsBatchStaked(address staker, uint256 cycle, uint256[] tokenIds, uint256[] weights);

    event NftUnstaked(address staker, uint256 cycle, uint256 tokenId, uint256 weight);
    event NftsBatchUnstaked(address staker, uint256 cycle, uint256[] tokenIds, uint256[] weights);

    event RewardsClaimed(address staker, uint256 cycle, uint256 startPeriod, uint256 periods, uint256 amount);

    event HistoriesUpdated(address staker, uint256 startCycle, uint256 stakerStake, uint256 globalStake);

    event Disabled();

    struct TokenInfo {
        address owner;
        uint64 weight;
        uint16 depositCycle;
        uint16 withdrawCycle;
    }

    struct Snapshot {
        uint128 stake;
        uint128 startCycle;
    }

    struct NextClaim {
        uint16 period;
        uint64 globalSnapshotIndex;
        uint64 stakerSnapshotIndex;
    }

    struct ComputedClaim {
        uint16 startPeriod;
        uint16 periods;
        uint256 amount;
    }

    bool public enabled = true;

    uint256 public totalRewardsPool;

    uint256 public startTimestamp;

    IERC20 public immutable rewardsTokenContract;
    IERC1155721Transferrable public immutable whitelistedNftContract;

    uint32 public immutable cycleLengthInSeconds;
    uint16 public immutable periodLengthInCycles;

    Snapshot[] public globalHistory;

    mapping(address => Snapshot[]) public stakerHistories;

    mapping(address => NextClaim) public nextClaims;

    mapping(uint256 => TokenInfo) public tokenInfos;

    mapping(uint256 => uint256) public rewardsSchedule;

    mapping(uint256 => bool) public withdrawnLostCycles;

    modifier hasStarted() {
        require(startTimestamp != 0, "NftStaking: staking not started");
        _;
    }

    modifier hasNotStarted() {
        require(startTimestamp == 0, "NftStaking: staking has started");
        _;
    }

    modifier isEnabled() {
        require(enabled, "NftStaking: contract is not enabled");
        _;
    }

    modifier isNotEnabled() {
        require(!enabled, "NftStaking: contract is enabled");
        _;
    }

    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IERC1155721Transferrable whitelistedNftContract_,
        IERC20 rewardsTokenContract_
    ) internal {
        require(cycleLengthInSeconds_ >= 1 minutes, "NftStaking: invalid cycle length");
        require(periodLengthInCycles_ >= 2, "NftStaking: invalid period length");

        cycleLengthInSeconds = cycleLengthInSeconds_;
        periodLengthInCycles = periodLengthInCycles_;
        whitelistedNftContract = whitelistedNftContract_;
        rewardsTokenContract = rewardsTokenContract_;
    }


    function addRewardsForPeriods(
        uint16 startPeriod,
        uint16 endPeriod,
        uint256 rewardsPerCycle
    ) external onlyOwner {
        require(startPeriod != 0 && startPeriod <= endPeriod, "NftStaking: wrong period range");

        uint16 periodLengthInCycles_ = periodLengthInCycles;

        if (startTimestamp != 0) {
            require(
                startPeriod >= _getCurrentPeriod(periodLengthInCycles_),
                "NftStaking: already committed reward schedule"
            );
        }

        for (uint256 period = startPeriod; period <= endPeriod; ++period) {
            rewardsSchedule[period] = rewardsSchedule[period].add(rewardsPerCycle);
        }

        uint256 addedRewards = rewardsPerCycle.mul(periodLengthInCycles_).mul(endPeriod - startPeriod + 1);

        totalRewardsPool = totalRewardsPool.add(addedRewards);

        require(
            rewardsTokenContract.transferFrom(_msgSender(), address(this), addedRewards),
            "NftStaking: failed to add funds to the reward pool"
        );

        emit RewardsAdded(startPeriod, endPeriod, rewardsPerCycle);
    }

    function start() public onlyOwner hasNotStarted {
        startTimestamp = now;
        emit Started();
    }

    function disable() public onlyOwner {
        enabled = false;
        emit Disabled();
    }

    function withdrawRewardsPool(uint256 amount) public onlyOwner isNotEnabled {
        require(
            rewardsTokenContract.transfer(_msgSender(), amount),
            "NftStaking: failed to withdraw from the rewards pool"
        );
    }

    function withdrawLostCycleRewards(address to, uint16 cycle, int256 globalSnapshotIndex) external onlyOwner {
        require(to != address(0), "NftStaking: zero address");
        require(cycle < _getCycle(now), "NftStaking: non-past cycle");
        require(withdrawnLostCycles[cycle] == false, "NftStaking: already withdrawn");
        if (globalSnapshotIndex == -1) {
            require(
                globalHistory.length == 0 ||
                cycle < globalHistory[0].startCycle,
                "NftStaking: cycle has snapshot"
            );
        } else if (globalSnapshotIndex >= 0) {
            uint256 snapshotIndex = uint256(globalSnapshotIndex);
            Snapshot memory snapshot = globalHistory[snapshotIndex];
            require(
                cycle >= snapshot.startCycle,
                "NftStaking: cycle < snapshot"
            );
            require(
                globalHistory.length == snapshotIndex + 1 || // last snapshot
                cycle < globalHistory[snapshotIndex + 1].startCycle,
                "NftStaking: cycle > snapshot"
            );
            require(snapshot.stake == 0, "NftStaking: non-lost cycle");
        } else {
            revert("NftStaking: wrong index value");
        }

        uint16 period = _getPeriod(cycle, periodLengthInCycles);
        uint256 cycleRewards = rewardsSchedule[period];
        require(cycleRewards != 0, "NftStaking: rewardless cycle");
        withdrawnLostCycles[cycle] = true;
        rewardsTokenContract.transfer(to, cycleRewards);
    }


    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256, /*value*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(address(whitelistedNftContract) == _msgSender(), "NftStaking: contract not whitelisted");
        _stakeNft(id, from);
        return _ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(address(whitelistedNftContract) == _msgSender(), "NftStaking: contract not whitelisted");
        _batchStakeNfts(ids, from);
        return _ERC1155_BATCH_RECEIVED;
    }


    function unstakeNft(uint256 tokenId) external virtual {
        TokenInfo memory tokenInfo = tokenInfos[tokenId];

        require(tokenInfo.owner == _msgSender(), "NftStaking: not staked for owner");

        uint16 currentCycle = _getCycle(now);
        uint64 weight = tokenInfo.weight;

        if (enabled) {
            require(currentCycle - tokenInfo.depositCycle >= 2, "NftStaking: token still frozen");

            _updateHistories(_msgSender(), -int128(weight), currentCycle);

            tokenInfo.owner = address(0);

            tokenInfo.withdrawCycle = currentCycle;

            tokenInfos[tokenId] = tokenInfo;
        }

        whitelistedNftContract.safeTransferFromWithFallback(address(this), _msgSender(), tokenId, 1, "");
        emit NftUnstaked(_msgSender(), currentCycle, tokenId, weight);
        _onUnstake(_msgSender(), weight);
    }

    function batchUnstakeNfts(uint256[] calldata tokenIds) external {
        uint256 numTokens = tokenIds.length;
        require(numTokens != 0, "NftStaking: no tokens");

        uint16 currentCycle = _getCycle(now);
        int128 totalUnstakedWeight = 0;
        uint256[] memory values = new uint256[](numTokens);
        uint256[] memory weights = new uint256[](numTokens);

        for (uint256 index = 0; index < numTokens; ++index) {
            uint256 tokenId = tokenIds[index];

            TokenInfo memory tokenInfo = tokenInfos[tokenId];

            require(tokenInfo.owner == _msgSender(), "NftStaking: not staked for owner");

            if (enabled) {
                require(currentCycle - tokenInfo.depositCycle >= 2, "NftStaking: token still frozen");

                tokenInfos[tokenId].owner = address(0);

                uint64 weight = tokenInfo.weight;
                totalUnstakedWeight += weight; // this is safe
                weights[index] = weight;
            }

            values[index] = 1;
        }

        if (enabled) {
            _updateHistories(_msgSender(), -totalUnstakedWeight, currentCycle);
        }

        whitelistedNftContract.safeBatchTransferFromWithFallback(address(this), _msgSender(), tokenIds, values, "");
        emit NftsBatchUnstaked(_msgSender(), currentCycle, tokenIds, weights);
        _onUnstake(_msgSender(), uint256(totalUnstakedWeight));
    }

    function estimateRewards(uint16 maxPeriods)
        external
        view
        isEnabled
        hasStarted
        returns (
            uint16 startPeriod,
            uint16 periods,
            uint256 amount
        )
    {
        (ComputedClaim memory claim, ) = _computeRewards(_msgSender(), maxPeriods);
        startPeriod = claim.startPeriod;
        periods = claim.periods;
        amount = claim.amount;
    }

    function claimRewards(uint16 maxPeriods) external isEnabled hasStarted {
        NextClaim memory nextClaim = nextClaims[_msgSender()];

        (ComputedClaim memory claim, NextClaim memory newNextClaim) = _computeRewards(_msgSender(), maxPeriods);

        Snapshot[] storage stakerHistory = stakerHistories[_msgSender()];
        while (nextClaim.stakerSnapshotIndex < newNextClaim.stakerSnapshotIndex) {
            delete stakerHistory[nextClaim.stakerSnapshotIndex++];
        }

        if (claim.periods == 0) {
            return;
        }

        if (nextClaims[_msgSender()].period == 0) {
            return;
        }

        Snapshot memory lastStakerSnapshot = stakerHistory[stakerHistory.length - 1];

        uint256 lastClaimedCycle = (claim.startPeriod + claim.periods - 1) * periodLengthInCycles;
        if (
            lastClaimedCycle >= lastStakerSnapshot.startCycle && // the claim reached the last staker snapshot
            lastStakerSnapshot.stake == 0 // and nothing is staked in the last staker snapshot
        ) {
            delete nextClaims[_msgSender()];
        } else {
            nextClaims[_msgSender()] = newNextClaim;
        }

        if (claim.amount != 0) {
            require(rewardsTokenContract.transfer(_msgSender(), claim.amount), "NftStaking: failed to transfer rewards");
        }

        emit RewardsClaimed(_msgSender(), _getCycle(now), claim.startPeriod, claim.periods, claim.amount);
    }


    function getCurrentCycle() external view returns (uint16) {
        return _getCycle(now);
    }

    function getCurrentPeriod() external view returns (uint16) {
        return _getCurrentPeriod(periodLengthInCycles);
    }

    function lastGlobalSnapshotIndex() external view returns (uint256) {
        uint256 length = globalHistory.length;
        require(length != 0, "NftStaking: empty global history");
        return length - 1;
    }

    function lastStakerSnapshotIndex(address staker) external view returns (uint256) {
        uint256 length = stakerHistories[staker].length;
        require(length != 0, "NftStaking: empty staker history");
        return length - 1;
    }


    function _stakeNft(uint256 tokenId, address owner) internal isEnabled hasStarted {
        uint64 weight = _validateAndGetNftWeight(tokenId);

        uint16 periodLengthInCycles_ = periodLengthInCycles;
        uint16 currentCycle = _getCycle(now);

        _updateHistories(owner, int128(weight), currentCycle);

        if (nextClaims[owner].period == 0) {
            uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles_);
            nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
        }

        uint16 withdrawCycle = tokenInfos[tokenId].withdrawCycle;
        require(currentCycle != withdrawCycle, "NftStaking: unstaked token cooldown");

        tokenInfos[tokenId] = TokenInfo(owner, weight, currentCycle, 0);

        emit NftStaked(owner, currentCycle, tokenId, weight);
        _onStake(owner, weight);
    }

    function _batchStakeNfts(uint256[] memory tokenIds, address owner) internal isEnabled hasStarted {
        uint256 numTokens = tokenIds.length;
        require(numTokens != 0, "NftStaking: no tokens");

        uint16 currentCycle = _getCycle(now);
        uint128 totalStakedWeight = 0;
        uint256[] memory weights = new uint256[](numTokens);

        for (uint256 index = 0; index < numTokens; ++index) {
            uint256 tokenId = tokenIds[index];
            require(currentCycle != tokenInfos[tokenId].withdrawCycle, "NftStaking: unstaked token cooldown");
            uint64 weight = _validateAndGetNftWeight(tokenId);
            totalStakedWeight += weight; // This is safe
            weights[index] = weight;
            tokenInfos[tokenId] = TokenInfo(owner, weight, currentCycle, 0);
        }

        _updateHistories(owner, int128(totalStakedWeight), currentCycle);

        if (nextClaims[owner].period == 0) {
            uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles);
            nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
        }

        emit NftsBatchStaked(owner, currentCycle, tokenIds, weights);
        _onStake(owner, totalStakedWeight);
    }

    function _computeRewards(address staker, uint16 maxPeriods)
        internal
        view
        returns (ComputedClaim memory claim, NextClaim memory nextClaim)
    {
        if (maxPeriods == 0) {
            return (claim, nextClaim);
        }

        if (globalHistory.length == 0) {
            return (claim, nextClaim);
        }

        nextClaim = nextClaims[staker];
        claim.startPeriod = nextClaim.period;

        if (claim.startPeriod == 0) {
            return (claim, nextClaim);
        }

        uint16 periodLengthInCycles_ = periodLengthInCycles;
        uint16 endClaimPeriod = _getCurrentPeriod(periodLengthInCycles_);

        if (nextClaim.period == endClaimPeriod) {
            return (claim, nextClaim);
        }

        Snapshot[] memory stakerHistory = stakerHistories[staker];

        Snapshot memory globalSnapshot = globalHistory[nextClaim.globalSnapshotIndex];
        Snapshot memory stakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex];
        Snapshot memory nextGlobalSnapshot;
        Snapshot memory nextStakerSnapshot;

        if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
            nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
        }
        if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
            nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
        }

        claim.periods = endClaimPeriod - nextClaim.period;

        if (maxPeriods < claim.periods) {
            claim.periods = maxPeriods;
        }

        endClaimPeriod = nextClaim.period + claim.periods;

        while (nextClaim.period != endClaimPeriod) {
            uint16 nextPeriodStartCycle = nextClaim.period * periodLengthInCycles_ + 1;
            uint256 rewardPerCycle = rewardsSchedule[nextClaim.period];
            uint256 startCycle = nextPeriodStartCycle - periodLengthInCycles_;
            uint256 endCycle = 0;

            while (endCycle != nextPeriodStartCycle) {
                if (globalSnapshot.startCycle > startCycle) {
                    startCycle = globalSnapshot.startCycle;
                }
                if (stakerSnapshot.startCycle > startCycle) {
                    startCycle = stakerSnapshot.startCycle;
                }

                endCycle = nextPeriodStartCycle;
                if ((nextGlobalSnapshot.startCycle != 0) && (nextGlobalSnapshot.startCycle < endCycle)) {
                    endCycle = nextGlobalSnapshot.startCycle;
                }

                if ((globalSnapshot.stake != 0) && (stakerSnapshot.stake != 0) && (rewardPerCycle != 0)) {
                    uint256 snapshotReward = (endCycle - startCycle).mul(rewardPerCycle).mul(stakerSnapshot.stake);
                    snapshotReward /= globalSnapshot.stake;

                    claim.amount = claim.amount.add(snapshotReward);
                }

                if (nextGlobalSnapshot.startCycle == endCycle) {
                    globalSnapshot = nextGlobalSnapshot;
                    ++nextClaim.globalSnapshotIndex;

                    if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
                        nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
                    } else {
                        nextGlobalSnapshot = Snapshot(0, 0);
                    }
                }

                if (nextStakerSnapshot.startCycle == endCycle) {
                    stakerSnapshot = nextStakerSnapshot;
                    ++nextClaim.stakerSnapshotIndex;

                    if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
                        nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
                    } else {
                        nextStakerSnapshot = Snapshot(0, 0);
                    }
                }
            }

            ++nextClaim.period;
        }

        return (claim, nextClaim);
    }

    function _updateHistories(
        address staker,
        int128 stakeDelta,
        uint16 currentCycle
    ) internal {
        uint256 stakerSnapshotIndex = _updateHistory(stakerHistories[staker], stakeDelta, currentCycle);
        uint256 globalSnapshotIndex = _updateHistory(globalHistory, stakeDelta, currentCycle);

        emit HistoriesUpdated(
            staker,
            currentCycle,
            stakerHistories[staker][stakerSnapshotIndex].stake,
            globalHistory[globalSnapshotIndex].stake
        );
    }

    function _updateHistory(
        Snapshot[] storage history,
        int128 stakeDelta,
        uint16 currentCycle
    ) internal returns (uint256 snapshotIndex) {
        uint256 historyLength = history.length;
        uint128 snapshotStake;

        if (historyLength != 0) {
            snapshotIndex = historyLength - 1;
            Snapshot storage snapshot = history[snapshotIndex];
            snapshotStake = uint256(int256(snapshot.stake).add(stakeDelta)).toUint128();

            if (snapshot.startCycle == currentCycle) {
                snapshot.stake = snapshotStake;
                return snapshotIndex;
            }

            snapshotIndex += 1;
        } else {

            snapshotStake = uint128(stakeDelta);
        }

        Snapshot memory snapshot;
        snapshot.stake = snapshotStake;
        snapshot.startCycle = currentCycle;

        history.push(snapshot);
    }


    function _getCycle(uint256 timestamp) internal view returns (uint16) {
        require(timestamp >= startTimestamp, "NftStaking: timestamp preceeds contract start");
        return (((timestamp - startTimestamp) / uint256(cycleLengthInSeconds)) + 1).toUint16();
    }

    function _getPeriod(uint16 cycle, uint16 periodLengthInCycles_) internal pure returns (uint16) {
        require(cycle != 0, "NftStaking: cycle cannot be zero");
        return (cycle - 1) / periodLengthInCycles_ + 1;
    }

    function _getCurrentPeriod(uint16 periodLengthInCycles_) internal view returns (uint16) {
        return _getPeriod(_getCycle(now), periodLengthInCycles_);
    }


    function _validateAndGetNftWeight(uint256 tokenId) internal virtual view returns (uint64);

    function _onStake(
        address owner,
        uint256 totalWeight
    ) internal virtual {}

    function _onUnstake(
        address owner,
        uint256 totalWeight
    ) internal virtual {}
}

interface IERC1155721Transferrable {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

library ERC1155721SafeTransferFallback {
    function safeBatchTransferFromWithFallback(
        IERC1155721Transferrable self,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        try self.safeBatchTransferFrom(from, to, ids, values, data)  {} catch {
            uint256 length = ids.length;
            for (uint256 i = 0; i < length; ++i) {
                self.transferFrom(from, to, ids[i]);
            }
        }
    }

    function safeTransferFromWithFallback(
        IERC1155721Transferrable self,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        try self.safeTransferFrom(from, to, id, value, data)  {} catch {
            self.transferFrom(from, to, id);
        }
    }
}



pragma solidity 0.6.8;



contract PolkaFantasyNftStaking is NftStakingV2 {

    mapping(uint256 => uint64) public weightByTokenAttribute;

    constructor(
        uint32 cycleLengthInSeconds_,
        uint16 periodLengthInCycles_,
        IERC1155721Transferrable whitelistedNftContract_,
        IERC20 rewardsTokenContract_,
        uint256[] memory tokenAttribute,
        uint64[] memory weights
    ) NftStakingV2(
        cycleLengthInSeconds_,
        periodLengthInCycles_,
        whitelistedNftContract_,
        rewardsTokenContract_
    ) public {
        require(tokenAttribute.length == weights.length, "PolkaFantasyNftStaking: inconsistent array lengths");
        for (uint256 i = 0; i < tokenAttribute.length; i++) {
            weightByTokenAttribute[tokenAttribute[i]] = weights[i];
        }
    }

    function setTokenWeight(uint256 tokenId, uint64 weight) public onlyOwner{
        weightByTokenAttribute[tokenId] = weight;
    }

     function setTokenWeightBatch(uint256[] memory tokenIds, uint64[] memory weights) public onlyOwner{
        for (uint256 i = 0; i < tokenIds.length; i++) {
            weightByTokenAttribute[tokenIds[i]] = weights[i];
        }
    }

    function _validateAndGetNftWeight(uint256 nftId) internal virtual override view returns (uint64) {
        return weightByTokenAttribute[nftId];
    }
}