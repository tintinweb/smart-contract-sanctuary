/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;



// Part: IBridgeReceiver

interface IBridgeReceiver {
    function getTokens() external returns (uint256);
}

// Part: ICompactFactory

interface ICompactFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function feeReceiver() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function vampire() external view returns (address);

    function setVampire(address) external;
}

// Part: ICompactPair

interface ICompactPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimeLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address tokenA, address tokenB) external;

    function addLpIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external;

    function addVolumeIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external;
}

// Part: IERC20

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// Part: IStakingRewards

interface IStakingRewards {
    function startTime() external view returns (uint256);

    function stakingToken() external view returns (address);

    function userWeight(address _user) external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function getWeek() external view returns (uint256);

    function weeklyTotalWeight(uint256 _week) external view returns (uint256);

    function weeklyWeightOf(address _user, uint256 _week)
        external
        view
        returns (uint256);

    function mintLockTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks,
        bool _penalty
    ) external returns (address);

    function depositFee(address _token, uint256 _amount)
        external
        returns (bool);

    function depositLockTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks,
        bool _penalty
    ) external returns (bool);
}

// Part: Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;
    address public pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferInitiated(
        address indexed owner,
        address indexed pendingOwner
    );

    /**
     * @dev Initializes the contract setting a given address as the initial owner.
     */
    constructor(address owner) internal {
        // we do not just use msg.sender because it isn't compatible with using the SingletonDeployer
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
        @dev Initiates a transfer of ownership. The transfer must be confirmed
        by `_pendingOwner` by calling to `acceptOwnership`.
     */
    function transferOwnership(address _pendingOwner) public onlyOwner {
        pendingOwner = _pendingOwner;
        emit OwnershipTransferInitiated(_owner, _pendingOwner);
    }

    /**
        @dev Accepts a pending transfer of ownership. Splitting the transfer
        across two transactions provides a sanity check in case of an incorrect
        `pendingOwner`. The transaction cannot always easily be simulated, e.g.
        if the owner is a Gnosis safe.
     */
    function acceptOwnership() public {
        require(msg.sender == pendingOwner, "Ownable: caller is not new owner");
        emit OwnershipTransferred(_owner, pendingOwner);
        _owner = pendingOwner;
    }
}

// Part: SafeMath

/// @title a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// Part: IncentiveVoting

/**
    @title Incentive Voting
    @dev This contract allows PACT lockers to vote on where to direct
         future PACT emissions. PACT is received into the contract
         via a bridge receiver, and then released to individual pool
         contracts via the weekly emissions votes.
 */
contract IncentiveVoting is Ownable {
    using SafeMath for uint256;

    struct TokenApprovalVote {
        mapping(address => bool) hasVoted;
        address token;
        uint40 startTime;
        uint16 week;
        uint256 requiredWeight;
        uint256 givenWeight;
        string ipfsCid;
    }

    // token -> week -> weight allocated
    mapping(address => mapping(uint256 => uint256)) public poolVotes;

    // user -> week -> weight used
    mapping(address => mapping(uint256 => uint256)) public userVotes;

    // week -> total weight allocated
    mapping(uint256 => uint256) public totalVotes;

    // pool -> last week rewards were distributed
    mapping(address => uint256) public lastRewardedWeek;

    // data about token approval votes
    TokenApprovalVote[] public tokenApprovalVotes;

    // minimum support required in an approval vote, as a % out of 100
    uint256 public tokenApprovalQuorumPct;

    // user -> timestamp of last created token approval vote
    mapping(address => uint256) public lastVote;

    // token -> is approved to receive PACT emissions?
    mapping(address => bool) public approvedTokens;

    // pool -> are both tokens within the pool approved to receive PACT emissions?
    mapping(address => bool) public approvedPools;

    uint256 constant WEEK = 86400 * 7;
    uint256 public startTime;

    ICompactFactory public factory;
    IStakingRewards public stakingRewards;
    address public stakingToken;

    // PACT is minted on Ethereum, send over a bridge and received in
    // `bridgeReceiver`, and then pulled into this contract.
    IBridgeReceiver public bridgeReceiver;

    // The total amount of PACT distributed each week. The length of the
    // array updates as new PACT is received from the bridge receiver.
    uint256[] public weeklyEmissions;

    event TokenApprovalVoteCreated(
        address indexed creator,
        address indexed token,
        uint256 startTime,
        uint256 week,
        uint256 requiredWeight,
        uint256 voteIndex,
        string ipfsCid
    );

    event VotedForTokenApproval(
        address indexed voter,
        uint256 indexed voteIndex,
        uint256 votedWeight,
        uint256 givenWeight,
        uint256 requiredWeight,
        bool isApproved
    );

    event VotedForPoolIncentives(
        address indexed voter,
        address indexed pool,
        uint256 voteWeight,
        uint256 usedWeight,
        uint256 totalWeight
    );

    event IncentivesPushed(
        address indexed pool,
        uint256 indexed week,
        uint256 amount,
        uint256 lockWeeks
    );

    event IncentivesReceived(address caller, uint256 week, uint256 perWeek);

    event BridgeReceiverSet(
        address caller,
        IBridgeReceiver oldBridgeReceiver,
        IBridgeReceiver newBridgeReceiver
    );

    event ApprovalQuorumSet(
        address caller,
        uint256 oldQuorumPct,
        uint256 newQuorumPct
    );

    constructor(
        ICompactFactory _factory,
        IStakingRewards _stakingRewards,
        address[] memory _approvedTokens,
        uint256 _quorumPct,
        address _owner
    ) public Ownable(_owner) {
        factory = _factory;
        stakingRewards = _stakingRewards;
        stakingToken = _stakingRewards.stakingToken();
        tokenApprovalQuorumPct = _quorumPct;
        // start at +1 week to handle the default value in `lastRewardedWeek`
        // without this, pools would not receive PACT in the first week
        startTime = _stakingRewards.startTime() - WEEK;

        IERC20(stakingToken).approve(address(_stakingRewards), uint256(-1));

        uint256 length = _approvedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            approvedTokens[_approvedTokens[i]] = true;
        }
    }

    function getWeek() public view returns (uint256) {
        if (startTime >= block.timestamp) return 0;
        return (block.timestamp - startTime) / 604800;
    }

    /**
        @notice Given a week number (per `getWeek`) returns the duration in weeks
                used when minting RewardPACT for incentivizing pools
     */
    function getRewardPactDurationAtWeek(uint256 _week)
        public
        pure
        returns (uint256)
    {
        if (_week < 26) {
            // 8 weeks for the first half a year
            return 8;
        } else if (_week < 156) {
            // +4 weeks every 3 months
            return 8 + (((_week - 13) / 13) * 4);
        } else {
            // 3 years after launch, maxes out at 52 weeks
            return 52;
        }
    }

    /**
        @notice Get the amount of unused weight for for the current week being voted on
        @param _user Address to query
        @return uint Amount of unused weight
     */
    function availableVoteWeight(address _user)
        external
        view
        returns (uint256)
    {
        uint256 week = getWeek();
        uint256 usedWeight = userVotes[_user][week];
        uint256 totalWeight = stakingRewards.userWeight(_user);
        return totalWeight.sub(usedWeight);
    }

    /**
        @notice Allocate weight toward a pool to receive PACT incentives in the following week
        @dev A user may vote as many times as they like within a week, so long as their total
             available weight is not exceeded. If they receive additional weight by locking more
             PACT within `StakingRewards`, they can vote immediately.

             Vote weight can only be added - not modified or removed. Votes only apply to the
             following week - they do not carry over. A user must resubmit their vote each
             week.
        @param _pool Address of the pool to vote for
        @param _weight Amount of weight to allocated to this pool. This value is additive,
                       it does not include previous votes. For example, if you have already
                       allocated a weight of 100 and wish to allocated a total of 300,
                       `_weight` should be given as 200.
     */
    function voteForPool(address _pool, uint256 _weight) external {
        if (!approvedPools[_pool]) {
            // verify that tokens are whitelisted and add pool to `approvedPools`
            address token0 = ICompactPair(_pool).token0();
            address token1 = ICompactPair(_pool).token1();
            require(
                approvedTokens[token0] && approvedTokens[token1],
                "Unapproved token"
            );
            require(
                factory.getPair(token0, token1) == _pool,
                "Pool not in factory"
            );
            approvedPools[_pool] = true;
        }

        // transfer any pending PACT incentives to `_pool`
        // included here in case nobody decides to explicitly push them by
        // directly calling `pushIncentives`.
        pushIncentives(_pool);

        // make sure user has not exceeded available weight
        uint256 week = getWeek();
        uint256 usedWeight = userVotes[msg.sender][week].add(_weight);
        uint256 totalWeight = stakingRewards.userWeight(msg.sender);
        require(usedWeight <= totalWeight, "Available weight exceeded");

        // update accounting for this week's votes
        poolVotes[_pool][week] = poolVotes[_pool][week].add(_weight);
        userVotes[msg.sender][week] = usedWeight;
        totalVotes[week] = totalVotes[week].add(_weight);

        emit VotedForPoolIncentives(
            msg.sender,
            _pool,
            _weight,
            usedWeight,
            totalWeight
        );
    }

    /**
        @notice Create a new vote to enable PACT emissions on a given token
        @dev PACT emissions are only available to pools where both tokens within
             the pool have been approved. This prevents incentives on malicious
             tokens. We trust PACT lockers to vote in the best longterm interests
             of the protocol :)
        @param _token Token address to create a vote for
        @param _ipfsCid IPFS CID pointing at a description of the vote
        @return _voteIndex uint Index value used to reference the vote
     */
    function createTokenApprovalVote(address _token, string calldata _ipfsCid)
        external
        returns (uint256 _voteIndex)
    {
        require(!approvedTokens[_token], "Already approved");
        uint256 week = stakingRewards.getWeek();
        require(week > 0, "Cannot make vote in first week");
        week -= 1;
        uint256 weight = stakingRewards.weeklyWeightOf(msg.sender, week);

        // minimum weight of 52,000 and max one vote per week to prevent spamming votes
        require(weight >= 52000 * 10**18, "Not enough weight");
        require(
            lastVote[msg.sender].add(WEEK) <= block.timestamp,
            "One new vote per week"
        );
        lastVote[msg.sender] = block.timestamp;

        uint256 required = stakingRewards
            .weeklyTotalWeight(week)
            .mul(tokenApprovalQuorumPct)
            .div(100);
        tokenApprovalVotes.push(
            TokenApprovalVote({
                token: _token,
                startTime: uint40(block.timestamp),
                week: uint16(week),
                requiredWeight: required,
                givenWeight: 0,
                ipfsCid: _ipfsCid
            })
        );

        uint256 voteIdx = tokenApprovalVotes.length - 1;
        emit TokenApprovalVoteCreated(
            msg.sender,
            _token,
            block.timestamp,
            week,
            required,
            voteIdx,
            _ipfsCid
        );
        return voteIdx;
    }

    /**
        @notice Vote in favor of approving a new token for PACT emissions
        @dev Votes last for one week. Weight for voting is based on the last
             completed week at the time the vote was created. A vote passes
             once the percent of weight given exceeds `tokenApprovalQuorumPct`.
             It is not possible to vote against a proposed token, users who
             wish to do so should instead abstain from voting.
        @param _voteIndex Array index referencing the vote
     */
    function voteForTokenApproval(uint256 _voteIndex) external {
        TokenApprovalVote storage vote = tokenApprovalVotes[_voteIndex];
        require(!vote.hasVoted[msg.sender], "Already voted");
        require(vote.startTime > block.timestamp.sub(WEEK), "Vote has ended");

        vote.hasVoted[msg.sender] = true;
        uint256 weight = stakingRewards.weeklyWeightOf(msg.sender, vote.week);
        vote.givenWeight = vote.givenWeight.add(weight);

        bool isApproved = vote.givenWeight >= vote.requiredWeight;
        if (isApproved) {
            approvedTokens[vote.token] = true;
        }

        emit VotedForTokenApproval(
            msg.sender,
            _voteIndex,
            weight,
            vote.givenWeight,
            vote.requiredWeight,
            isApproved
        );
    }

    /**
        @dev Transfer PACT incentives to a pool based on the outcome of
        a completed incentives vote. Should be called once per week per pool
        that received a non-zero vote weight.
     */
    function pushIncentives(address _pool) public {
        uint256 week = getWeek();

        if (week > weeklyEmissions.length) {
            // if `receiveEmissions` has not been called in more than 4 weeks,
            // do not attempt to update beyond the latest received emissions.
            week = weeklyEmissions.length;
        }

        if (week > 0) {
            require(approvedPools[_pool], "Unknown pool");
            uint256 lastReward = lastRewardedWeek[_pool];
            if (lastReward == week - 1) return;
            uint256 amount;
            for (uint256 i = lastReward + 1; i < week; i++) {
                uint256 votes = poolVotes[_pool][i];
                if (votes == 0) continue;
                uint256 weeklyAmount = weeklyEmissions[i].mul(votes) /
                    totalVotes[i];
                amount = amount.add(weeklyAmount);
            }
            lastRewardedWeek[_pool] = week - 1;

            // need at least 14 tokens (7 days, 1 token for volume, 1 token for liquidity)
            if (amount < 14) return;

            uint256 lockWeeks = getRewardPactDurationAtWeek(week);
            address rewardToken = stakingRewards.mintLockTokens(
                address(this),
                amount,
                lockWeeks,
                true
            );
            IERC20(rewardToken).approve(_pool, amount);
            ICompactPair(_pool).addLpIncentive(rewardToken, 7, amount / 2);
            ICompactPair(_pool).addVolumeIncentive(rewardToken, 7, amount / 2);

            emit IncentivesPushed(_pool, week, amount, lockWeeks);
        }
    }

    /**
        @dev Receive PACT from the bridge receiver and update local accounting.
        PACT arrives once every 4 weeks and is distributed evenly over the next 4 weeks.
     */
    function receiveEmissions() external onlyOwner {
        uint256 week = getWeek();
        if (week < weeklyEmissions.length) {
            /*
            Calling receiveEmissions multiple times for the same week would break our accounting.

            Sending PACT incentives onward to individual pools requires reading from weeklyEmissions
            which means it will revert until after receiveEmissions is called. However, if called
            maliciously (by first transferring a small balance of PACT to the bridge receiver so that
            there is some nonzero balance received), the contract will record an incorrect balance and
            thus each call to pushIncentives sends an insufficient balance onward.
            */
            revert("already received");
        }

        uint256 perWeek = bridgeReceiver.getTokens().div(4);

        // add a month of emissions
        while (weeklyEmissions.length < week + 4) {
            weeklyEmissions.push();
        }
        for (uint256 i = week; i < week + 4; i++) {
            weeklyEmissions[i] = weeklyEmissions[i] = perWeek;
        }

        emit IncentivesReceived(msg.sender, week, perWeek);
    }

    /**
        @dev Set the bridge receiver. The receiver may be modified in case
        there is an update or issue with a bridge that neccessitates it.
     */
    function setBridgeReceiver(IBridgeReceiver _bridgeReceiver)
        external
        onlyOwner
    {
        emit BridgeReceiverSet(msg.sender, bridgeReceiver, _bridgeReceiver);
        bridgeReceiver = _bridgeReceiver;
    }

    /**
        @dev Modify the required quorum for token approval votes.
        Hopefully this is never needed.
     */
    function setTokenApprovalQuorum(uint256 _quorumPct) external onlyOwner {
        emit ApprovalQuorumSet(msg.sender, tokenApprovalQuorumPct, _quorumPct);
        tokenApprovalQuorumPct = _quorumPct;
    }
}

// File: IncentiveVotingDev.sol

/// @title Development-only version of IncentiveVoting
contract IncentiveVotingDev is IncentiveVoting {
    constructor(
        ICompactFactory _factory,
        IStakingRewards _stakingRewards,
        address[] memory _approvedTokens,
        uint256 _quorumPct,
        address _owner
    )
        public
        IncentiveVoting(
            _factory,
            _stakingRewards,
            _approvedTokens,
            _quorumPct,
            _owner
        )
    {}

    /// @notice Development-only function to override timestamps
    /// @dev this will be shifted to the start of the last epoch week
    function devSetTimes(uint256 _startTime) external onlyOwner {
        startTime = (_startTime / WEEK) * WEEK - WEEK;
        require(startTime == _startTime - WEEK, "!epoch week");
    }
}