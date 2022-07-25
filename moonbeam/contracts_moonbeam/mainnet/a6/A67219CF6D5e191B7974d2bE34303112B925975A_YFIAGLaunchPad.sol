// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/SafeERC20.sol";
import "./ERC20.sol";
import "./interfaces/IYFIAGNftMarketplace.sol";
import "./utils/Address.sol";

contract YFIAGLaunchPad is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using Address for address;

    // CONSTANTS

    // number of decimals of rollover factors
    uint64 constant ROLLOVER_FACTOR_DECIMALS = 10**18;

    // STRUCTS

    // A checkpoint for marking stake info at a given block
    struct UserCheckpoint {
        // block number of checkpoint
        uint80 blockNumber;
        // amount staked at checkpoint
        uint104 staked;
        // amount of stake weight at checkpoint
        uint192 stakeWeight;
        // number of finished sales at time of checkpoint
        uint24 numFinishedSales;
    }

    // A checkpoint for marking stake info at a given block
    struct LaunchpadCheckpoint {
        // block number of checkpoint
        uint80 blockNumber;
        // amount staked at checkpoint
        uint104 totalStaked;
        // amount of stake weight at checkpoint
        uint192 totalStakeWeight;
        // number of finished sales at time of checkpoint
        uint24 numFinishedSales;
    }

    // Info of each launchpad. These parameters cannot be changed.
    struct LaunchpadInfo {
        // name of launchpad
        string name;
        // token to stake (e.g., IDIA)
        ERC20 stakeToken;
        // weight accrual rate for this launchpad (stake weight increase per block per stake token)
        uint24 weightAccrualRate;
        //the root id that the stake participant will receive
        uint256 rootIdToken;
        // start time of launchpad
        uint256 startTime;
        // end time of launchpad
        uint256 endTime;
        // maximum total stake for a user in this launchpad
        uint104 minTotalStake;
    }

    // INFO FOR FACTORING IN ROLLOVERS

    // the number of checkpoints of a launchpad -- (launchpad, finished sale count) => block number
    mapping(uint24 => mapping(uint24 => uint80)) public launchpadFinishedSaleBlocks;

    // Launchpad INFO

    // array of launchpad information
    LaunchpadInfo[] public launchpads;

    // whether launchpad is disabled -- (launchpad) => disabled status
    mapping(uint24 => bool) public launchpadDisabled;

    // emergency launchpad flag -- (launchpad) => emergency status
    mapping(uint24 => bool) public launchpadEmergency;

    // number of unique stakers on launchpad -- (launchpad) => staker count
    mapping(uint24 => uint256) public numLaunchPadStakers;

    // array of unique stakers on launchpad -- (launchpad) => address array
    // users are only added on first checkpoint to maintain unique
    mapping(uint24 => address[]) public launchpadStakers;

    // the number of checkpoints of a launchpad -- (launchpad) => checkpoint count
    mapping(uint24 => uint32) public launchpadCheckpointCount;

    // launchpad checkpoint mapping -- (launchpad, checkpoint number) => LaunchpadCheckpoint
    mapping(uint24 => mapping(uint32 => LaunchpadCheckpoint))
        public launchpadCheckpoints;

    // USER INFO

    // the number of checkpoints of a user for a launchpad -- (launchpad, user address) => checkpoint count
    mapping(uint24 => mapping(address => uint32)) public userCheckpointCounts;

    // user checkpoint mapping -- (launchpad, user address, checkpoint number) => UserCheckpoint
    mapping(uint24 => mapping(address => mapping(uint32 => UserCheckpoint)))
        public userCheckpoints;
    // winner mapping -- (launchpad, user address) => is winner of launchpad?
    mapping(uint24 => mapping(address => bool)) public winners;

    //YFIAGNftMarketplace
    address public YFIAGNftMarketplace;

    // balance of Fee launchpad--(launchpad) => balances
    mapping (uint24 => uint256) balanceOfLaunchpad;

    // check already claim --(launchpad, sender) => bool (is claimed)
    mapping (uint24 => mapping(address => bool)) isClaimed;

    // check is stakers --(launchpad, sender) => bool(is staked)
    mapping(uint24 => mapping(address => bool)) isStakers;

    // EVENTS

    event AddLaunchpad(uint24 indexed launchpadId,string indexed name, address indexed token, uint256 rootIdToken);
    event DisableLaunchpad(uint24 indexed launchpadId);
    event AddUserCheckpoint(uint24 indexed launchpadId, uint80 blockNumber);
    event AddLaunchpadCheckpoint(uint24 indexed launchpadId, uint80 blockNumber);
    event Stake(uint24 indexed launchpadId, address indexed user, uint104 amount);
    event Unstake(uint24 indexed launchpadId, address indexed user, uint104 amount);
    event Claim(uint24 indexed launchpadId, address indexed user, uint256 indexed rootIdToken);

    // MODIFIER

    modifier launchpadNotFound(uint24 launchpadId){
        require(launchpadId <= launchpads.length, "LP isn't exist");
        _;
    }

    // CONSTRUCTOR

    constructor(address _YFIAGNftMarketplace) {
        YFIAGNftMarketplace = _YFIAGNftMarketplace;
    }

    // FUNCTIONS

    // number of Launchpads
    function launchpadCount() external view returns (uint24) {
        return uint24(launchpads.length);
    }

    function getBalancesOfLaunchpad(uint24 launchpadId) public view returns(uint256){
        return balanceOfLaunchpad[launchpadId];
    }

    // get closest PRECEDING user checkpoint
    function getClosestUserCheckpoint(
        uint24 launchpadId,
        address user,
        uint80 blockNumber
    ) private view returns (UserCheckpoint memory cp) {
        // get total checkpoint count for user
        uint32 nCheckpoints = userCheckpointCounts[launchpadId][user];

        if (
            userCheckpoints[launchpadId][user][nCheckpoints - 1].blockNumber <=
            blockNumber
        ) {
            // First check most recent checkpoint

            // return closest checkpoint
            return userCheckpoints[launchpadId][user][nCheckpoints - 1];
        } else if (
            userCheckpoints[launchpadId][user][0].blockNumber > blockNumber
        ) {
            // Next check earliest checkpoint

            // If specified block number is earlier than user"s first checkpoint,
            // return null checkpoint
            return
                UserCheckpoint({
                    blockNumber: 0,
                    staked: 0,
                    stakeWeight: 0,
                    numFinishedSales: 0
                });
        } else {
            // binary search on checkpoints
            uint32 lower = 0;
            uint32 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                UserCheckpoint memory tempCp = userCheckpoints[launchpadId][user][
                    center
                ];
                if (tempCp.blockNumber == blockNumber) {
                    return tempCp;
                } else if (tempCp.blockNumber < blockNumber) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            // return closest checkpoint
            return userCheckpoints[launchpadId][user][lower];
        }
    }

    // gets a user"s stake weight within a launchpad at a particular block number
    // logic extended from Compound COMP token `getPriorVotes` function
    function getUserStakeWeight(
        uint24 launchpadId,
        address user,
        uint80 blockNumber
    ) public view returns (uint192) {
        require(blockNumber <= block.number, "block # too high");

        // if launchpad is disabled, stake weight is 0
        if (launchpadDisabled[launchpadId]) return 0;

        // check number of user checkpoints
        uint32 nUserCheckpoints = userCheckpointCounts[launchpadId][user];
        if (nUserCheckpoints == 0) {
            return 0;
        }

        // get closest preceding user checkpoint
        UserCheckpoint memory closestUserCheckpoint = getClosestUserCheckpoint(
            launchpadId,
            user,
            blockNumber
        );

        // check if closest preceding checkpoint was null checkpoint
        if (closestUserCheckpoint.blockNumber == 0) {
            return 0;
        }

        // get closest preceding launchpad checkpoint

        LaunchpadCheckpoint memory closestLaunchpadCp = getClosestLaunchpadCheckpoint(
            launchpadId,
            blockNumber
        );

        // get number of finished sales between user"s last checkpoint blockNumber and provided blockNumber
        uint24 numFinishedSalesDelta = closestLaunchpadCp.numFinishedSales -
            closestUserCheckpoint.numFinishedSales;

        // get launchpad info
        LaunchpadInfo memory launchpad = launchpads[launchpadId];

        // calculate stake weight given above delta
        uint192 stakeWeight;
        if (numFinishedSalesDelta == 0) {
            // calculate normally without rollover decay

            uint80 elapsedBlocks = blockNumber -
                closestUserCheckpoint.blockNumber;

            stakeWeight =
                closestUserCheckpoint.stakeWeight +
                (uint192(elapsedBlocks) *
                    launchpad.weightAccrualRate *
                    closestUserCheckpoint.staked) /
                10**18;

            return stakeWeight;
        } else {
            // calculate with rollover decay

            // starting stakeweight
            stakeWeight = closestUserCheckpoint.stakeWeight;
            // current block for iteration
            uint80 currBlock = closestUserCheckpoint.blockNumber;

            // for each finished sale in between, get stake weight of that period
            // and perform weighted sum
            for (uint24 i = 0; i < numFinishedSalesDelta; i++) {
                // get number of blocks passed at the current sale number
                uint80 elapsedBlocks = launchpadFinishedSaleBlocks[launchpadId][
                    closestUserCheckpoint.numFinishedSales + i
                ] - currBlock;

                // update stake weight
                stakeWeight =
                    stakeWeight +
                    (uint192(elapsedBlocks) *
                        launchpad.weightAccrualRate *
                        closestUserCheckpoint.staked) /
                    10**18;


                // factor in passive and active rollover decay
                stakeWeight =
                    // decay passive weight
                    ((stakeWeight)) /
                    ROLLOVER_FACTOR_DECIMALS;

                // update currBlock for next round
                currBlock = launchpadFinishedSaleBlocks[launchpadId][
                    closestUserCheckpoint.numFinishedSales + i
                ];
            }

            // add any remaining accrued stake weight at current finished sale count
            uint80 remainingElapsed = blockNumber -
                launchpadFinishedSaleBlocks[launchpadId][
                    closestLaunchpadCp.numFinishedSales - 1
                ];
            stakeWeight +=
                (uint192(remainingElapsed) *
                    launchpad.weightAccrualRate *
                    closestUserCheckpoint.staked) /
                10**18;
        }

        // return
        return stakeWeight;
    }

    // get closest PRECEDING launchpad checkpoint
    function getClosestLaunchpadCheckpoint(uint24 launchpadId, uint80 blockNumber)
        private
        view
        returns (LaunchpadCheckpoint memory cp)
    {
        // get total checkpoint count for launchpad
        uint32 nCheckpoints = launchpadCheckpointCount[launchpadId];

        if (
            launchpadCheckpoints[launchpadId][nCheckpoints - 1].blockNumber <=
            blockNumber
        ) {
            // First check most recent checkpoint

            // return closest checkpoint
            return launchpadCheckpoints[launchpadId][nCheckpoints - 1];
        } else if (launchpadCheckpoints[launchpadId][0].blockNumber > blockNumber) {
            // Next check earliest checkpoint

            // If specified block number is earlier than launchpad"s first checkpoint,
            // return null checkpoint
            return
                LaunchpadCheckpoint({
                    blockNumber: 0,
                    totalStaked: 0,
                    totalStakeWeight: 0,
                    numFinishedSales: 0
                });
        } else {
            // binary search on checkpoints
            uint32 lower = 0;
            uint32 upper = nCheckpoints - 1;
            while (upper > lower) {
                uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
                LaunchpadCheckpoint memory tempCp = launchpadCheckpoints[launchpadId][
                    center
                ];
                if (tempCp.blockNumber == blockNumber) {
                    return tempCp;
                } else if (tempCp.blockNumber < blockNumber) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

            // return closest checkpoint
            return launchpadCheckpoints[launchpadId][lower];
        }
    }

    // gets total stake weight within a launchpad at a particular block number
    // logic extended from Compound COMP token `getPriorVotes` function
    function getTotalStakeWeight(uint24 launchpadId, uint80 blockNumber)
        external
        view
        returns (uint192)
    {
        require(blockNumber <= block.number, "block # too high");

        // if launchpad is disabled, stake weight is 0
        if (launchpadDisabled[launchpadId]) return 0;

        // get closest launchpad checkpoint
        LaunchpadCheckpoint memory closestCheckpoint = getClosestLaunchpadCheckpoint(
            launchpadId,
            blockNumber
        );

        // check if closest preceding checkpoint was null checkpoint
        if (closestCheckpoint.blockNumber == 0) {
            return 0;
        }

        // calculate blocks elapsed since checkpoint
        uint80 additionalBlocks = (blockNumber - closestCheckpoint.blockNumber);

        // get launchpad info
        LaunchpadInfo storage launchpadInfo = launchpads[launchpadId];

        // calculate marginal accrued stake weight
        uint192 marginalAccruedStakeWeight = (uint192(additionalBlocks) *
            launchpadInfo.weightAccrualRate *
            closestCheckpoint.totalStaked) / 10**18;

        // return
        return closestCheckpoint.totalStakeWeight + marginalAccruedStakeWeight;
    }

    function getTotalStakedLaunchpad(uint24 launchpadId) public view returns(uint104) {
        // get launchpad checkpoint count
        uint32 nCheckpointsLaunchpad = launchpadCheckpointCount[launchpadId];

        // get latest launchpad checkpoint
        LaunchpadCheckpoint memory launchpadCp = launchpadCheckpoints[launchpadId][
            nCheckpointsLaunchpad - 1
        ];

        return launchpadCp.totalStaked;
    }

    function getTotalStakedUser(uint24 launchpadId, address user) public view returns(uint104) {
         // get number of user"s checkpoints within this launchpad
        uint32 userCheckpointCount = userCheckpointCounts[launchpadId][
            user
        ];

        if(userCheckpointCount == 0){
            return 0;
        }

        // get user"s latest checkpoint
        UserCheckpoint storage checkpoint = userCheckpoints[launchpadId][
            user
        ][userCheckpointCount - 1];

        return checkpoint.staked;
    }

    function amountRefundToken(uint24 launchpadId, address user) public view returns(uint104) {
        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        // get number of user"s checkpoints within this launchpad
        uint32 userCheckpointCount = userCheckpointCounts[launchpadId][
            user
        ];

        if(userCheckpointCount == 0){
            return 0;
        }

        // get user"s latest checkpoint
        UserCheckpoint storage checkpoint = userCheckpoints[launchpadId][
            user
        ][userCheckpointCount - 1];

        if(launchpadDisabled[launchpadId]){
            if(winners[launchpadId][user]){
                return uint104(checkpoint.staked - launchpad.minTotalStake);
            }else{
                return uint104(checkpoint.staked);
            }
        }

        if(!launchpadDisabled[launchpadId]){
            return uint104(checkpoint.staked - launchpad.minTotalStake);
        }
        return 0;
    }

    function getAllStakers(uint24 launchpadId) public view returns(address[] memory){
        return launchpadStakers[launchpadId];
    }

    function addUserCheckpoint(
        uint24 launchpadId,
        uint104 amount,
        bool addElseSub
    ) internal {
        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        // get user checkpoint count
        uint32 nCheckpointsUser = userCheckpointCounts[launchpadId][_msgSender()];

        // get launchpad checkpoint count
        uint32 nCheckpointsLaunchpad = launchpadCheckpointCount[launchpadId];

        // get latest launchpad checkpoint
        LaunchpadCheckpoint memory LaunchpadCp = launchpadCheckpoints[launchpadId][
            nCheckpointsLaunchpad - 1
        ];

        // if this is first checkpoint
        if (nCheckpointsUser == 0) {
            // check if amount exceeds maximum
            require(amount >= launchpad.minTotalStake, "exceeds staking cap");

            // add user to stakers list of launchpad
            launchpadStakers[launchpadId].push(_msgSender());

            // increment stakers count on launchpad
            numLaunchPadStakers[launchpadId]++;

            // add a first checkpoint for this user on this launchpad
            userCheckpoints[launchpadId][_msgSender()][0] = UserCheckpoint({
                blockNumber: uint80(block.number),
                staked: amount,
                stakeWeight: 0,
                numFinishedSales: LaunchpadCp.numFinishedSales
            });

            // increment user"s checkpoint count
            userCheckpointCounts[launchpadId][_msgSender()] = nCheckpointsUser + 1;
        } else {
            // get previous checkpoint
            UserCheckpoint storage prev = userCheckpoints[launchpadId][
                _msgSender()
            ][nCheckpointsUser - 1];


            // ensure block number downcast to uint80 is monotonically increasing (prevent overflow)
            // this should never happen within the lifetime of the universe, but if it does, this prevents a catastrophe
            require(
                prev.blockNumber <= uint80(block.number),
                "block # overflow"
            );

            // add a new checkpoint for user within this launchpad
            // if no blocks elapsed, just update prev checkpoint (so checkpoints can be uniquely identified by block number)
            if (prev.blockNumber == uint80(block.number)) {
                prev.staked = addElseSub
                    ? prev.staked + amount
                    : prev.staked - amount;
                prev.numFinishedSales = LaunchpadCp.numFinishedSales;
            } else {
                userCheckpoints[launchpadId][_msgSender()][
                    nCheckpointsUser
                ] = UserCheckpoint({
                    blockNumber: uint80(block.number),
                    staked: addElseSub
                        ? prev.staked + amount
                        : prev.staked - amount,
                    stakeWeight: getUserStakeWeight(
                        launchpadId,
                        _msgSender(),
                        uint80(block.number)
                    ),
                    numFinishedSales: LaunchpadCp.numFinishedSales
                });

                // increment user"s checkpoint count
                userCheckpointCounts[launchpadId][_msgSender()] =
                    nCheckpointsUser +
                    1;
            }
        }

        // emit
        emit AddUserCheckpoint(launchpadId, uint80(block.number));
    }

    function addLaunchpadCheckpoint(
        uint24 launchpadId, // launchpad number
        uint104 amount, // delta on staked amount
        bool addElseSub, // true = adding; false = subtracting
        bool _bumpSaleCounter // whether to increase sale counter by 1
    ) internal {
        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        // get launchpad checkpoint count
        uint32 nCheckpoints = launchpadCheckpointCount[launchpadId];

        // if this is first checkpoint
        if (nCheckpoints == 0) {
            // add a first checkpoint for this launchpad
            launchpadCheckpoints[launchpadId][0] = LaunchpadCheckpoint({
                blockNumber: uint80(block.number),
                totalStaked: amount,
                totalStakeWeight: 0,
                numFinishedSales: _bumpSaleCounter ? 1 : 0
            });

            // increase new launchpad"s checkpoint count by 1
            launchpadCheckpointCount[launchpadId]++;
        } else {
            // get previous checkpoint
            LaunchpadCheckpoint storage prev = launchpadCheckpoints[launchpadId][
                nCheckpoints - 1
            ];

            // get whether launchpad is disabled
            bool isDisabled = launchpadDisabled[launchpadId];

            if (isDisabled) {
                // if previous checkpoint was disabled, then cannot increase stake going forward
                require(!addElseSub, "disabled: cannot add stake");
            }

            // ensure block number downcast to uint80 is monotonically increasing (prevent overflow)
            // this should never happen within the lifetime of the universe, but if it does, this prevents a catastrophe
            require(
                prev.blockNumber <= uint80(block.number),
                "block # overflow"
            );

            // calculate blocks elapsed since checkpoint
            uint80 additionalBlocks = (uint80(block.number) - prev.blockNumber);

            // calculate marginal accrued stake weight
            uint192 marginalAccruedStakeWeight = (uint192(additionalBlocks) *
                launchpad.weightAccrualRate *
                prev.totalStaked) / 10**18;

            // calculate new stake weight
            uint192 newStakeWeight = prev.totalStakeWeight +
                marginalAccruedStakeWeight;

            // add a new checkpoint for this launchpad
            // if no blocks elapsed, just update prev checkpoint (so checkpoints can be uniquely identified by block number)
            if (additionalBlocks == 0) {
                prev.totalStaked = addElseSub
                    ? prev.totalStaked + amount
                    : prev.totalStaked - amount;
                prev.totalStakeWeight = isDisabled
                    ? (
                        prev.totalStakeWeight < newStakeWeight
                            ? prev.totalStakeWeight
                            : newStakeWeight
                    )
                    : newStakeWeight;
                prev.numFinishedSales = _bumpSaleCounter
                    ? prev.numFinishedSales + 1
                    : prev.numFinishedSales;
            } else {
                launchpadCheckpoints[launchpadId][nCheckpoints] = LaunchpadCheckpoint({
                    blockNumber: uint80(block.number),
                    totalStaked: addElseSub
                        ? prev.totalStaked + amount
                        : prev.totalStaked - amount,
                    totalStakeWeight: isDisabled
                        ? (
                            prev.totalStakeWeight < newStakeWeight
                                ? prev.totalStakeWeight
                                : newStakeWeight
                        )
                        : newStakeWeight,
                    numFinishedSales: _bumpSaleCounter
                        ? prev.numFinishedSales + 1
                        : prev.numFinishedSales
                });

                // increase new launchpad"s checkpoint count by 1
                launchpadCheckpointCount[launchpadId]++;
            }
        }

        // emit
        emit AddLaunchpadCheckpoint(launchpadId, uint80(block.number));
    }

    // adds a new launchpad
    function addLaunchPad(
        string calldata name,
        ERC20 stakeToken,
        uint24 _weightAccrualRate,
        uint256 _rootId,
        uint256 _startTime,
        uint256 _endTime,
        uint104 _minTotalStake
    ) external onlyOwner {
        require(_weightAccrualRate != 0, "accrual rate = 0");
        require(_endTime > _startTime, "Invalid time");
        require(_endTime > block.timestamp, "Invalid time");

        // add launchpad
        launchpads.push(
            LaunchpadInfo({
                name: name, // name of launchpad
                stakeToken: stakeToken, // token to stake (e.g., IDIA)
                weightAccrualRate: _weightAccrualRate, // rate of stake weight accrual
                rootIdToken: _rootId, // root id token
                startTime: _startTime, // time start launchpad
                endTime: _endTime, // time end launchpad
                minTotalStake: _minTotalStake // max total stake
            })
        );

        // add first launchpad checkpoint
        addLaunchpadCheckpoint(
            uint24(launchpads.length - 1), // latest launchpad
            0, // initialize with 0 stake
            false, // add or sub does not matter
            false // do not bump finished sale counter
        );

        // emit
        emit AddLaunchpad(uint24(launchpads.length - 1),name, address(stakeToken), _rootId);
    }

    // disables a launchpad
    function disableLaunchpad(uint24 launchpadId) external onlyOwner launchpadNotFound(launchpadId){
        // set disabled
        launchpadDisabled[launchpadId] = true;

         // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        // set Emegency
        if(launchpad.startTime < block.timestamp && block.timestamp < launchpad.endTime){
            launchpadEmergency[launchpadId] = true;
        }        

        // emit
        emit DisableLaunchpad(launchpadId);
    }

    // stake
    function stake(uint24 launchpadId, uint104 amount) external nonReentrant {
        // stake amount must be greater than 0
        require(amount > 0, "amount is 0");

        // require msg.sender is wallet
        require(!_msgSender().isContract(), "Sender == contr address");

        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        //check expired startTime
        require(launchpad.startTime < block.timestamp,"staking time has !started");

        //check expried endTime
        require(block.timestamp < launchpad.endTime, "staking time has expired");

        // get whether launchpad is disabled
        bool isDisabled = launchpadDisabled[launchpadId];

        // cannot stake into disabled launchpad
        require(!isDisabled, "launchpad is disabled");

        // transfer the specified amount of stake token from user to this contract
        launchpad.stakeToken.safeTransferFrom(_msgSender(), address(this), amount);

        // add user checkpoint
        addUserCheckpoint(launchpadId, amount, true);

        // add launchpad checkpoint
        addLaunchpadCheckpoint(launchpadId, amount, true, false);

        isStakers[launchpadId][_msgSender()] = true;

        // emit
        emit Stake(launchpadId, _msgSender(), amount);
    }

    // unstake
    function unstake(uint24 launchpadId) external nonReentrant {
        // require msg.sender is wallet
        require(!_msgSender().isContract(), "Sender == contr address");

        // require launchpad is disabled
        require(launchpadDisabled[launchpadId], "launchpad !disabled");

        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        if(!launchpadEmergency[launchpadId]){
            // require not winners
            require(!winners[launchpadId][_msgSender()], "!winners");
        }

        // get number of user"s checkpoints within this launchpad
        uint32 userCheckpointCount = userCheckpointCounts[launchpadId][
            _msgSender()
        ];

        //check staked
        require(userCheckpointCount > 0, "not staked");

        // get user"s latest checkpoint
        UserCheckpoint storage checkpoint = userCheckpoints[launchpadId][
            _msgSender()
        ][userCheckpointCount - 1];


        // check staked
        require(checkpoint.staked > 0, "staked < 0");

        // add user checkpoint
        addUserCheckpoint(launchpadId, checkpoint.staked, false);

        // add launchpad checkpoint
        addLaunchpadCheckpoint(launchpadId, checkpoint.staked, false, false);

        // transfer the specified amount of stake token from this contract to user
        launchpad.stakeToken.safeTransfer(_msgSender(), checkpoint.staked);

        // emit
        emit Unstake(launchpadId, _msgSender(), checkpoint.staked);
    }

    //set Winers
    function setWinners(uint24 launchpadId, address[] memory _winners) public onlyOwner() launchpadNotFound(launchpadId) nonReentrant{
        // require launchpad is disabled
        require(!launchpadDisabled[launchpadId], "launchpad disabled");

        //set launchpad disable
        launchpadDisabled[launchpadId] = true;

        for(uint256 i=0; i< _winners.length; ++i){
            require(isStakers[launchpadId][_winners[i]], "!stakers");

            winners[launchpadId][_winners[i]] = true;
        }

    }

    function claim(uint24 launchpadId) external nonReentrant{
        // require msg.sender is wallet
        require(!_msgSender().isContract(), "Sender == contr address");

        // require launchpad is disabled
        require(launchpadDisabled[launchpadId], "launchpad !disabled");

        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        //check is winners
        require(winners[launchpadId][_msgSender()], "!losser");

        //check claimed
        require(!isClaimed[launchpadId][_msgSender()], "already claimed");

        // get number of user"s checkpoints within this launchpad
        uint32 userCheckpointCount = userCheckpointCounts[launchpadId][
            _msgSender()
        ];

        //check staked
        require(userCheckpointCount > 0, "not staked");

        // get user"s latest checkpoint
        UserCheckpoint storage checkpoint = userCheckpoints[launchpadId][
            _msgSender()
        ][userCheckpointCount - 1];

        //get amount refund
        uint104 amountRefund = checkpoint.staked - launchpad.minTotalStake;

        // check staked
        require(amountRefund >= 0, "staked < minTotalStake");

        // set balance launchpad
        balanceOfLaunchpad[launchpadId] += launchpad.minTotalStake;

        // transfer amountRefund for sender
        if(amountRefund > 0){
            launchpad.stakeToken.safeTransfer(_msgSender(), amountRefund);
        }

        // mintFragment for sender
        IYFIAGNftMarketplace(YFIAGNftMarketplace).mintFragment(_msgSender(), launchpad.rootIdToken);

        // sender only claim once
        isClaimed[launchpadId][_msgSender()] = true;

        // emit
        emit Claim(launchpadId, _msgSender(), launchpad.rootIdToken);
        emit Unstake(launchpadId, _msgSender(), amountRefund);

    }

    function withdraw(uint24[] memory launchpadIds) external onlyOwner() nonReentrant{
        for(uint256 i = 0; i< launchpadIds.length; ++i){
            // check balances of launchpad
            require(balanceOfLaunchpad[launchpadIds[i]] > 0, "total 0");

            LaunchpadInfo storage launchpad = launchpads[launchpadIds[i]];

            address _self = address(this);
            uint256 _balance = launchpad.stakeToken.balanceOf(_self);

            // check balances this >= balances launchpad
            require(_balance >= balanceOfLaunchpad[launchpadIds[i]], "balance !enought");

            launchpad.stakeToken.safeTransfer(_msgSender(), balanceOfLaunchpad[launchpadIds[i]]);
            balanceOfLaunchpad[launchpadIds[i]] = 0; 
        }
    }

    function setAddressMarketplace(address _YFIAGNftMarketplace) public onlyOwner(){
        YFIAGNftMarketplace = _YFIAGNftMarketplace;
    }

    function editTimeLaunchpad(uint24 launchpadId,uint256 _newStartTime, uint256 _newEndTime) public onlyOwner() launchpadNotFound(launchpadId){
        require(_newEndTime > _newStartTime, "Invalid time");
        require(_newEndTime > block.timestamp, "Invalid time");

        // get whether launchpad is disabled
        bool isDisabled = launchpadDisabled[launchpadId];
        // disabled launchpad
        require(!isDisabled, "launchpad is disabled");


        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];

        if(block.timestamp > launchpad.startTime){
            // set new end time
            launchpad.endTime = _newEndTime;
        }else{
            // set new start time
            launchpad.startTime = _newStartTime;

            // set new end time
            launchpad.endTime = _newEndTime; 
        }
  
    }

    function deleteLaunchpad(uint24 launchpadId) external onlyOwner() launchpadNotFound(launchpadId){
        // get whether launchpad is disabled
        bool isDisabled = launchpadDisabled[launchpadId];
        // disabled launchpad
        require(!isDisabled, "launchpad is disabled");
        // get launchpad info
        LaunchpadInfo storage launchpad = launchpads[launchpadId];
        //burn root token of this launchpad
        IYFIAGNftMarketplace(YFIAGNftMarketplace).burnByLaunchpad(owner(),launchpad.rootIdToken);
        //set disable
        launchpadDisabled[launchpadId] = true;
        // set Emegency
        if(launchpad.startTime < block.timestamp && block.timestamp < launchpad.endTime){
            launchpadEmergency[launchpadId] = true;
        }  
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

 import "./Address.sol";
 import "../interfaces/IERC20.sol";

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
import "./utils/Context.sol";
import "./interfaces/IERC20.sol";
import "./extensions/IERC20Metadata.sol";

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

interface IYFIAGNftMarketplace {
    // Event =================================================================================
    event PriceChanged(uint256 _tokenId, uint256 _price, address _tokenAddress, address _user);
    event RoyaltyChanged(uint256 _tokenId, uint256 _royalty, address _user);
    event FundsTransfer(uint256 _tokenId, uint256 _amount, address _user);


    //Function ================================================================================

    function withdraw() external;

    function withdraw(address _user, uint256 _amount) external;

    function withdraw(address _tokenErc20, address _user) external;

    function setPlatformFee(uint256 _newFee) external;

    function getBalance() external view returns(uint256);

    function mint(address _to,address _token, string memory _uri, uint256 _royalty, bool _isRoot) external;

    function mintFragment(address _to,uint256 _rootTokenId) external;

    function setPriceAndSell(uint256 _tokenId, uint256 _price) external;

    function buy(uint256 _tokenId) external payable;

    function isForSale(uint256 _tokenId) external view returns(bool);

    function getAmountEarn(address _user, address _tokenAddress) external view returns(uint256);

    function setDefaultAmountEarn(address _user, address _tokenAddress) external;

    function setPlatformFeeAddress(address newPlatformFeeAddess) external;

    function burnByLaunchpad(address account,uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function buyAndBurn(uint256 _tokenId) external payable;

    function mintByCrosschain(address _to,address _token, string memory _uri, uint256 _royalty, address _creator) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;

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

pragma solidity >=0.8.4 <=0.8.6;

import "../interfaces/IERC20.sol";

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