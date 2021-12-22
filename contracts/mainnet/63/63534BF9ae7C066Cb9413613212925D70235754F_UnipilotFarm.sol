//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

/// @title Unipilot Yield Farming
/// @author Asim Raza
/// @notice You can use this contract for earn reward on staking nft
/// @dev All function calls are currently implemented without side effects

//Utility imports
import "./interfaces/IUnipilotFarm.sol";
import "./interfaces/uniswap/IUniswapLiquidityManager.sol";
import "./interfaces/IUnipilot.sol";
import "./interfaces/IFarmV1.sol";
import "./interfaces/IUnipilotStake.sol";

//Uniswap v3 core imports
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

//Openzeppelin imports
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./ReentrancyGuard.sol";

contract UnipilotFarm is IUnipilotFarm, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isFarmingActive;
    bool public backwardCompatible;
    address public governance;
    uint256 public pilotPerBlock = 1e18;
    uint256 public farmingGrowthBlockLimit;
    uint256 public totalRewardSent;

    address private ulm;
    address private stakeContract;
    address[2] private deprecated;

    address private constant PILOT_TOKEN = 0x37C997B35C619C21323F3518B9357914E8B99525; 
    address private constant UNIPILOT = 0xde5bF92E3372AA59C73Ca7dFc6CEc599E1B2b08C;

    address[] public poolListed;

    // farming status --> tokenId => bool
    mapping(uint256 => bool) public farmingActive;

    // exist in whitelist or not --> pool address => bool
    mapping(address => bool) public poolWhitelist;

    // poolinfo address =>Poolinfo struct
    mapping(address => PoolInfo) public poolInfo;

    // poolAltInfo address => PoolAltInfo struct
    mapping(address => PoolAltInfo) public poolAltInfo;

    // userinfo user --> tokenId nft => userInfo struct
    mapping(uint256 => UserInfo) public userInfo;

    //user address => pool address => tokenId[]
    mapping(address => mapping(address => uint256[])) public userToPoolToTokenIds;
    modifier onlyGovernance() {
        require(msg.sender == governance, "NA");
        _;
    }

    modifier isActive() {
        require(isFarmingActive, "FNA");
        _;
    }

    modifier isLimitActive() {
        require(farmingGrowthBlockLimit == 0, "LA");
        _;
    }

    modifier onlyOwner(uint256 _tokenId) {
        require(IERC721(UNIPILOT).ownerOf(_tokenId) == msg.sender, "NO");
        _;
    }

    modifier isPoolRewardActive(address pool) {
        require(poolInfo[pool].isRewardActive, "RNA");
        _;
    }

    modifier onlyStake() {
        require(msg.sender == stakeContract, "NS");
        _;
    }

    constructor(
        address _ulm,
        address _governance,
        address[2] memory _deprecated
    ) {
        governance = _governance;

        ulm = _ulm;

        isFarmingActive = true;

        deprecated = _deprecated;

        backwardCompatible = true;
    }

    /// @notice withdraw NFT with reward
    /// @dev only owner of nft can withdraw
    /// @param _tokenId unstake tokenID
    function withdrawNFT(uint256 _tokenId) external override {
        UserInfo storage userState = userInfo[_tokenId];

        PoolInfo storage poolState = poolInfo[userState.pool];

        PoolAltInfo storage poolAltState = poolAltInfo[userState.pool];

        withdrawReward(_tokenId);

        poolState.totalLockedLiquidity = poolState.totalLockedLiquidity.sub(
            userState.liquidity
        );

        IERC721(UNIPILOT).safeTransferFrom(address(this), msg.sender, _tokenId);

        farmingActive[_tokenId] = false;

        emit WithdrawNFT(
            userState.pool,
            userState.user,
            _tokenId,
            poolState.totalLockedLiquidity
        );

        if (poolState.totalLockedLiquidity == 0) {
            poolState.startBlock = block.number;
            poolState.lastRewardBlock = block.number;
            poolState.globalReward = 0;

            poolAltState.startBlock = block.number;
            poolAltState.lastRewardBlock = block.number;
            poolAltState.globalReward = 0;
        }

        uint256 index = callIndex(userState.pool, _tokenId);

        updateNFTList(index, userState.user, userState.pool);

        delete userInfo[_tokenId];
    }

    /// @notice withdraw NFT without reward claiming
    /// @param _tokenId unstake this tokenID
    function emergencyNFTWithdraw(uint256 _tokenId) external {
        UserInfo storage userState = userInfo[_tokenId];

        require(userState.user == msg.sender, "NOO");

        PoolInfo storage poolState = poolInfo[userState.pool];

        PoolAltInfo storage poolAltState = poolAltInfo[userState.pool];

        poolState.totalLockedLiquidity = poolState.totalLockedLiquidity.sub(
            userState.liquidity
        );

        IERC721(UNIPILOT).safeTransferFrom(address(this), userState.user, _tokenId);

        if (poolState.totalLockedLiquidity == 0) {
            poolState.startBlock = block.number;
            poolState.lastRewardBlock = block.number;
            poolState.globalReward = 0;

            poolAltState.startBlock = block.number;
            poolAltState.lastRewardBlock = block.number;
            poolAltState.globalReward = 0;
        }
        uint256 index = callIndex(userState.pool, _tokenId);
        updateNFTList(index, userState.user, userState.pool);
        delete userInfo[_tokenId];
    }

    /// @notice Migrate funds to Governance address or in new Contract
    /// @dev only governance can call this
    /// @param _newContract address of new contract or wallet address
    /// @param _tokenAddress address of token which want to migrate
    /// @param _amount withdraw that amount which are required
    function migrateFunds(
        address _newContract,
        address _tokenAddress,
        uint256 _amount
    ) external onlyGovernance {
        require(_newContract != address(0), "CNE");
        IERC20(_tokenAddress).safeTransfer(_newContract, _amount);
        emit MigrateFunds(_newContract, _tokenAddress, _amount);
    }

    /// @notice Use to blacklist pools
    /// @dev only governance can call this
    /// @param _pools addresses to be blacklisted
    function blacklistPools(address[] memory _pools) external override onlyGovernance {
        for (uint256 i = 0; i < _pools.length; i++) {
            poolWhitelist[_pools[i]] = false;
            poolInfo[_pools[i]].rewardMultiplier = 0;    
            emit BlacklistPool(_pools[i], poolWhitelist[_pools[i]], block.timestamp);
        }
    }

    /// @notice Use to update ULM address
    /// @dev only governance can call this
    /// @param _ulm new address of ULM
    function updateULM(address _ulm) external override onlyGovernance {
        emit UpdateULM(ulm, ulm = _ulm, block.timestamp);
    }

    /// @notice Updating pilot per block for every pool
    /// @dev only governance can call this
    /// @param _value new value of pilot per block
    function updatePilotPerBlock(uint256 _value) external override onlyGovernance {
        address[] memory pools = poolListed;
        pilotPerBlock = _value;
        for (uint256 i = 0; i < pools.length; i++) {
            if (poolWhitelist[pools[i]]) {
                if (poolInfo[pools[i]].totalLockedLiquidity != 0) {
                    updatePoolState(pools[i]);
                }
                emit UpdatePilotPerBlock(pools[i], pilotPerBlock);
            }
        }
    }

    /// @notice Updating multiplier for single pool
    /// @dev only governance can call this
    /// @param _pool pool address
    /// @param _value new value of multiplier of pool
    function updateMultiplier(address _pool, uint256 _value)
        external
        override
        onlyGovernance
    {
        updatePoolState(_pool);

        emit UpdateMultiplier(
            _pool,
            poolInfo[_pool].rewardMultiplier,
            poolInfo[_pool].rewardMultiplier = _value
        );
    }

    /// @notice User total nft(s) with respect to pool
    /// @param _user particular user address
    /// @param _pool particular pool address
    /// @return tokenCount count of nft(s)
    /// @return tokenIds array of tokenID
    function totalUserNftWRTPool(address _user, address _pool)
        external
        view
        override
        returns (uint256 tokenCount, uint256[] memory tokenIds)
    {
        tokenCount = userToPoolToTokenIds[_user][_pool].length;
        tokenIds = userToPoolToTokenIds[_user][_pool];
    }

    /// @notice NFT token ID farming status
    /// @param _tokenId particular tokenId
    function nftStatus(uint256 _tokenId) external view override returns (bool) {
        return farmingActive[_tokenId];
    }

    /// @notice User can call tx to deposit nft
    /// @dev pool address must be exist in whitelisted pools
    /// @param _tokenId tokenID which want to deposit
    /// @return status of farming is active for particular tokenID
    function depositNFT(uint256 _tokenId)
        external
        override
        isActive
        isLimitActive
        onlyOwner(_tokenId)
        returns (bool)
    {
        address sender = msg.sender;
        IUniswapLiquidityManager.Position memory positions = IUniswapLiquidityManager(ulm)
            .userPositions(_tokenId);

        (address pool, uint256 liquidity) = (positions.pool, positions.liquidity);

        require(poolWhitelist[pool], "PNW");

        IUniswapLiquidityManager.LiquidityPosition
            memory liquidityPositions = IUniswapLiquidityManager(ulm).poolPositions(pool);

        uint256 totalLiquidity = liquidityPositions.totalLiquidity;

        require(totalLiquidity >= liquidity && liquidity > 0, "IL");

        PoolInfo storage poolState = poolInfo[pool];

        if (poolState.lastRewardBlock != poolState.startBlock) {
            uint256 blockDifference = (block.number).sub(poolState.lastRewardBlock);

            poolState.globalReward = getGlobalReward(
                pool,
                blockDifference,
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );
        }

        poolState.totalLockedLiquidity = poolState.totalLockedLiquidity.add(liquidity);

        userInfo[_tokenId] = UserInfo({
            pool: pool,
            liquidity: liquidity,
            user: sender,
            reward: poolState.globalReward,
            altReward: userInfo[_tokenId].altReward,
            boosterActive: false
        });
        userToPoolToTokenIds[sender][pool].push(_tokenId);

        farmingActive[_tokenId] = true; // user's farming active

        IERC721(UNIPILOT).safeTransferFrom(sender, address(this), _tokenId);

        if (poolState.isAltActive) {
            altGR(pool, _tokenId);
        }

        poolState.lastRewardBlock = block.number;

        emit Deposit(
            pool,
            _tokenId,
            userInfo[_tokenId].liquidity,
            poolState.totalLockedLiquidity,
            poolState.globalReward,
            poolState.rewardMultiplier,
            pilotPerBlock
        );
        return farmingActive[_tokenId];
    }

    /// @notice toggle alt token state on pool
    /// @dev only governance can call this
    /// @param _pool pool address for alt token
    function toggleActiveAlt(address _pool) external onlyGovernance returns (bool) {
        require(poolAltInfo[_pool].altToken != address(0), "TNE");
        emit UpdateAltState(
            poolInfo[_pool].isAltActive,
            poolInfo[_pool].isAltActive = !poolInfo[_pool].isAltActive,
            _pool
        );

        if (poolInfo[_pool].isAltActive) {
            updateAltPoolState(_pool);
        } else {
            poolAltInfo[_pool].lastRewardBlock = block.number;
        }

        return poolInfo[_pool].isAltActive;
    }

    ///@notice Updating address of alt token
    ///@dev only Governance can call this
    function updateAltToken(address _pool, address _altToken) external onlyGovernance {
        emit UpdateActiveAlt(
            poolAltInfo[_pool].altToken,
            poolAltInfo[_pool].altToken = _altToken,
            _pool
        );

        PoolAltInfo memory poolAltState = poolAltInfo[_pool];
        poolAltState = PoolAltInfo({
            globalReward: 0,
            lastRewardBlock: block.number,
            altToken: poolAltInfo[_pool].altToken,
            startBlock: block.number
        });

        poolAltInfo[_pool] = poolAltState;
    }

    /// @dev onlyGovernance can call this
    /// @param _pools The pools to make whitelist or initialize
    /// @param _multipliers multiplier of pools
    function initializer(address[] memory _pools, uint256[] memory _multipliers)
        public
        override
        onlyGovernance
    {
        require(_pools.length == _multipliers.length, "LNS");
        for (uint256 i = 0; i < _pools.length; i++) {
            if (
                !poolWhitelist[_pools[i]] && poolInfo[_pools[i]].startBlock == 0
            ) {
                insertPool(_pools[i], _multipliers[i]);
            } else {
                poolWhitelist[_pools[i]] = true;
                poolInfo[_pools[i]].rewardMultiplier = _multipliers[i];
            }
        }
    }

    /// @notice Generic function to calculating global reward
    /// @param pool pool address
    /// @param blockDifference difference of block from current block to last reward block
    /// @param rewardPerBlock reward on per block
    /// @param multiplier multiplier value
    /// @return globalReward calculating global reward
    function getGlobalReward(
        address pool,
        uint256 blockDifference,
        uint256 rewardPerBlock,
        uint256 multiplier,
        uint256 _globalReward
    ) public view returns (uint256 globalReward) {
        uint256 tvl;
        if (backwardCompatible) {
            for(uint i = 0; i < deprecated.length; i++){
               uint256 prevTvl=(IUnipilotFarmV1(deprecated[i]).poolInfo(pool).totalLockedLiquidity);
               tvl=tvl.add(prevTvl); 
            }
            tvl = tvl.add(poolInfo[pool].totalLockedLiquidity);
        } else {
            tvl = poolInfo[pool].totalLockedLiquidity;
        }
        uint256 temp = FullMath.mulDiv(rewardPerBlock, multiplier, 1e18);
        globalReward = FullMath.mulDiv(blockDifference.mul(temp), 1e18, tvl).add(
            _globalReward
        );
    }

    /// @notice Generic function to calculating reward of tokenId
    /// @param _tokenId find current reward of tokenID
    /// @return pilotReward calculate pilot reward
    /// @return globalReward calculate global reward
    /// @return globalAltReward calculate global reward of alt token
    /// @return altReward calculate reward of alt token
    function currentReward(uint256 _tokenId)
        public
        view
        override
        returns (
            uint256 pilotReward,
            uint256 globalReward,
            uint256 globalAltReward,
            uint256 altReward
        )
    {
        UserInfo memory userState = userInfo[_tokenId];
        PoolInfo memory poolState = poolInfo[userState.pool];
        PoolAltInfo memory poolAltState = poolAltInfo[userState.pool];

        DirectTo check = DirectTo.GRforPilot;

        if (isFarmingActive) {
            globalReward = checkLimit(_tokenId, check);

            if (poolState.isAltActive) {
                check = DirectTo.GRforAlt;
                globalAltReward = checkLimit(_tokenId, check);
            } else {
                globalAltReward = poolAltState.globalReward;
            }
        } else {
            globalReward = poolState.globalReward;
            globalAltReward = poolAltState.globalReward;
        }

        uint256 userReward = globalReward.sub(userState.reward);
        uint256 _reward = (userReward.mul(userState.liquidity)).div(1e18);
        if (userState.boosterActive) {
            uint256 multiplier = IUnipilotStake(stakeContract).getBoostMultiplier(
                userState.user,
                userState.pool,
                _tokenId
            );
            uint256 boostedReward = (_reward.mul(multiplier)).div(1e18);
            pilotReward = _reward.add((boostedReward));
        } else {
            pilotReward = _reward;
        }

        _reward = globalAltReward.sub(userState.altReward);
        altReward = (_reward.mul(userState.liquidity)).div(1e18);
    }

    /// @notice Generic function to check limit of global reward of token Id
    function checkLimit(uint256 _tokenId, DirectTo _check)
        internal
        view
        returns (uint256 globalReward)
    {
        address pool = userInfo[_tokenId].pool;

        TempInfo memory poolState;

        if (_check == DirectTo.GRforPilot) {
            poolState = TempInfo({
                globalReward: poolInfo[pool].globalReward,
                lastRewardBlock: poolInfo[pool].lastRewardBlock,
                rewardMultiplier: poolInfo[pool].rewardMultiplier
            });
        } else if (_check == DirectTo.GRforAlt) {
            poolState = TempInfo({
                globalReward: poolAltInfo[pool].globalReward,
                lastRewardBlock: poolAltInfo[pool].lastRewardBlock,
                rewardMultiplier: poolInfo[pool].rewardMultiplier
            });
        }

        if (
            poolState.lastRewardBlock < farmingGrowthBlockLimit &&
            block.number > farmingGrowthBlockLimit
        ) {
            globalReward = getGlobalReward(
                pool,
                farmingGrowthBlockLimit.sub(poolState.lastRewardBlock),
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );
        } else if (
            poolState.lastRewardBlock > farmingGrowthBlockLimit &&
            farmingGrowthBlockLimit > 0
        ) {
            globalReward = poolState.globalReward;
        } else {
            uint256 blockDifference = (block.number).sub(poolState.lastRewardBlock);
            globalReward = getGlobalReward(
                pool,
                blockDifference,
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );
        }
    }

    /// @notice Withdraw reward of token Id
    /// @dev only owner of nft can withdraw
    /// @param _tokenId withdraw reward of this tokenID
    function withdrawReward(uint256 _tokenId)
        public
        override
        nonReentrant
        isPoolRewardActive(userInfo[_tokenId].pool)
    {
        UserInfo storage userState = userInfo[_tokenId];
        PoolInfo storage poolState = poolInfo[userState.pool];

        require(userState.user == msg.sender, "NO");
        (
            uint256 pilotReward,
            uint256 globalReward,
            uint256 globalAltReward,
            uint256 altReward
        ) = currentReward(_tokenId);

        require(IERC20(PILOT_TOKEN).balanceOf(address(this)) >= pilotReward, "IF");

        poolState.globalReward = globalReward;
        poolState.lastRewardBlock = block.number;
        userState.reward = globalReward;

        totalRewardSent += pilotReward;

        IERC20(PILOT_TOKEN).safeTransfer(userInfo[_tokenId].user, pilotReward);

        if (poolState.isAltActive) {
            altWithdraw(_tokenId, globalAltReward, altReward);
        }

        emit WithdrawReward(
            userState.pool,
            _tokenId,
            userState.liquidity,
            userState.reward,
            poolState.globalReward,
            poolState.totalLockedLiquidity,
            pilotReward
        );
    }

    /// @notice internal function use for initialize struct values of single pool
    /// @dev generalFunction to add pools
    /// @param _pool pool address
    function insertPool(address _pool, uint256 _multiplier) internal {
        poolWhitelist[_pool] = true;
        poolListed.push(_pool);
        poolInfo[_pool] = PoolInfo({
            startBlock: block.number,
            globalReward: 0,
            lastRewardBlock: block.number,
            totalLockedLiquidity: 0,
            rewardMultiplier: _multiplier,
            isRewardActive: true,
            isAltActive: poolInfo[_pool].isAltActive
        });

        emit NewPool(
            _pool,
            pilotPerBlock,
            poolInfo[_pool].rewardMultiplier,
            poolInfo[_pool].lastRewardBlock,
            poolWhitelist[_pool]
        );
    }

    /// @notice Use to update state of alt token
    function altGR(address _pool, uint256 _tokenId) internal {
        PoolAltInfo storage poolAltState = poolAltInfo[_pool];

        if (poolAltState.lastRewardBlock != poolAltState.startBlock) {
            uint256 blockDifference = (block.number).sub(poolAltState.lastRewardBlock);

            poolAltState.globalReward = getGlobalReward(
                _pool,
                blockDifference,
                pilotPerBlock,
                poolInfo[_pool].rewardMultiplier,
                poolAltState.globalReward
            );
        }

        poolAltState.lastRewardBlock = block.number;

        userInfo[_tokenId].altReward = poolAltState.globalReward;
    }

    /// @notice Use for pool tokenId to find its index
    function callIndex(address pool, uint256 _tokenId)
        internal
        view
        returns (uint256 index)
    {
        uint256[] memory tokens = userToPoolToTokenIds[msg.sender][pool];
        for (uint256 i = 0; i <= tokens.length; i++) {
            if (_tokenId == userToPoolToTokenIds[msg.sender][pool][i]) {
                index = i;
                break;
            }
        }
        return index;
    }

    /// @notice Use to update list of NFT(s)
    function updateNFTList(
        uint256 _index,
        address user,
        address pool
    ) internal {
        require(_index < userToPoolToTokenIds[user][pool].length, "IOB");
        uint256 temp = userToPoolToTokenIds[user][pool][
            userToPoolToTokenIds[user][pool].length.sub(1)
        ];
        userToPoolToTokenIds[user][pool][_index] = temp;
        userToPoolToTokenIds[user][pool].pop();
    }

    /// @notice Use to toggle farming state of contract
    function toggleFarmingActive() external override onlyGovernance {
        emit FarmingStatus(
            isFarmingActive,
            isFarmingActive = !isFarmingActive,
            block.timestamp
        );
    }

    /// @notice Use to withdraw alt tokens of token Id (internal)
    function altWithdraw(
        uint256 _tokenId,
        uint256 altGlobalReward,
        uint256 altReward
    ) internal {
        PoolAltInfo storage poolAltState = poolAltInfo[userInfo[_tokenId].pool];
        require(
            IERC20(poolAltState.altToken).balanceOf(address(this)) >= altReward,
            "IF"
        );
        poolAltState.lastRewardBlock = block.number;
        poolAltState.globalReward = altGlobalReward;
        userInfo[_tokenId].altReward = altGlobalReward;
        IERC20(poolAltState.altToken).safeTransfer(userInfo[_tokenId].user, altReward);
    }

    /// @notice Use to toggle state of reward of pool
    function toggleRewardStatus(address _pool) external override onlyGovernance {
        if (poolInfo[_pool].isRewardActive) {
            updatePoolState(_pool);
        } else {
            poolInfo[_pool].lastRewardBlock = block.number;
        }

        emit RewardStatus(
            _pool,
            poolInfo[_pool].isRewardActive,
            poolInfo[_pool].isRewardActive = !poolInfo[_pool].isRewardActive
        );
    }

    /// @notice Use to update pool state (internal)
    function updatePoolState(address _pool) internal {
        PoolInfo storage poolState = poolInfo[_pool];
        if (poolState.totalLockedLiquidity > 0) {
            uint256 currentGlobalReward = getGlobalReward(
                _pool,
                (block.number).sub(poolState.lastRewardBlock),
                pilotPerBlock,
                poolState.rewardMultiplier,
                poolState.globalReward
            );

            poolState.globalReward = currentGlobalReward;
            poolState.lastRewardBlock = block.number;
        }
    }

    /// @notice Use to update alt token state (internal)
    function updateAltPoolState(address _pool) internal {
        PoolAltInfo storage poolAltState = poolAltInfo[_pool];
        if (poolInfo[_pool].totalLockedLiquidity > 0) {
            uint256 currentGlobalReward = getGlobalReward(
                _pool,
                (block.number).sub(poolAltState.lastRewardBlock),
                pilotPerBlock,
                poolInfo[_pool].rewardMultiplier,
                poolAltState.globalReward
            );

            poolAltState.globalReward = currentGlobalReward;
            poolAltState.lastRewardBlock = block.number;
        }
    }

    /// @notice Use to stop staking NFT(s) in contract after block limit
    function updateFarmingLimit(uint256 _blockNumber) external onlyGovernance {
        emit UpdateFarmingLimit(
            farmingGrowthBlockLimit,
            farmingGrowthBlockLimit = _blockNumber
        );
    }

    /// @notice toggle booster status of token Id
    function toggleBooster(uint256 tokenId) external onlyStake {
        emit ToggleBooster(
            tokenId,
            userInfo[tokenId].boosterActive,
            userInfo[tokenId].boosterActive = !userInfo[tokenId].boosterActive
        );
    }

    /// @notice set stake contract address
    function setStake(address _stakeContract) external onlyGovernance {
        emit Stake(stakeContract, stakeContract = _stakeContract);
    }

    /// @notice toggle backward compayibility status of FarmingV1
    function toggleBackwardCompatibility() external onlyGovernance {
        emit BackwardCompatible(
            backwardCompatible,
            backwardCompatible = !backwardCompatible
        );
    }

    /// @notice governance can update new address of governance
    function updateGovernance(address _governance) external onlyGovernance {
        emit GovernanceUpdated(governance, governance = _governance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {
        //payable
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

interface IUnipilotFarm {
    struct PoolInfo {
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 totalLockedLiquidity;
        uint256 rewardMultiplier;
        bool isRewardActive;
        bool isAltActive;
    }

    struct PoolAltInfo {
        address altToken;
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
    }

    struct UserInfo {
        bool boosterActive;
        address pool;
        address user;
        uint256 reward;
        uint256 altReward;
        uint256 liquidity;
    }

    struct TempInfo {
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 rewardMultiplier;
    }

    enum DirectTo {
        GRforPilot,
        GRforAlt
    }

    event Deposit(
        address pool,
        uint256 tokenId,
        uint256 liquidity,
        uint256 totalSupply,
        uint256 globalReward,
        uint256 rewardMultiplier,
        uint256 rewardPerBlock
    );
    event WithdrawReward(
        address pool,
        uint256 tokenId,
        uint256 liquidity,
        uint256 reward,
        uint256 globalReward,
        uint256 totalSupply,
        uint256 lastRewardTransferred
    );
    event WithdrawNFT(
        address pool,
        address userAddress,
        uint256 tokenId,
        uint256 totalSupply
    );

    event NewPool(
        address pool,
        uint256 rewardPerBlock,
        uint256 rewardMultiplier,
        uint256 lastRewardBlock,
        bool status
    );

    event BlacklistPool(address pool, bool status, uint256 time);

    event UpdateULM(address oldAddress, address newAddress, uint256 time);

    event UpdatePilotPerBlock(address pool, uint256 updated);

    event UpdateMultiplier(address pool, uint256 old, uint256 updated);

    event UpdateActiveAlt(address old, address updated, address pool);

    event UpdateAltState(bool old, bool updated, address pool);

    event UpdateFarmingLimit(uint256 old, uint256 updated);

    event RewardStatus(address pool, bool old, bool updated);

    event MigrateFunds(address account, address token, uint256 amount);

    event FarmingStatus(bool old, bool updated, uint256 time);

    event Stake(address old, address updated);

    event ToggleBooster(uint256 tokenId, bool old, bool updated);

    event UserBooster(uint256 tokenId, uint256 booster);

    event BackwardCompatible(bool old, bool updated);

    event GovernanceUpdated(address old, address updated);

    function initializer(address[] memory pools, uint256[] memory _multipliers) external;

    function blacklistPools(address[] memory pools) external;

    function updatePilotPerBlock(uint256 value) external;

    function updateMultiplier(address pool, uint256 value) external;

    function updateULM(address _ULM) external;

    function totalUserNftWRTPool(address userAddress, address pool)
        external
        view
        returns (uint256 tokenCount, uint256[] memory tokenIds);

    function nftStatus(uint256 tokenId) external view returns (bool);

    function depositNFT(uint256 tokenId) external returns (bool);

    function withdrawNFT(uint256 tokenId) external;

    function withdrawReward(uint256 tokenId) external;

    function currentReward(uint256 _tokenId)
        external
        view
        returns (
            uint256 pilotReward,
            uint256 globalReward,
            uint256 globalAltReward,
            uint256 altReward
        );

    function toggleRewardStatus(address pool) external;

    function toggleFarmingActive() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IULMEvents.sol";

interface IUniswapLiquidityManager is IULMEvents {
    struct LiquidityPosition {
        // base order position
        int24 baseTickLower;
        int24 baseTickUpper;
        uint128 baseLiquidity;
        // range order position
        int24 rangeTickLower;
        int24 rangeTickUpper;
        uint128 rangeLiquidity;
        // accumulated fees
        uint256 fees0;
        uint256 fees1;
        uint256 feeGrowthGlobal0;
        uint256 feeGrowthGlobal1;
        // total liquidity
        uint256 totalLiquidity;
        // pool premiums
        bool feesInPilot;
        // oracle address for tokens to fetch prices from
        address oracle0;
        address oracle1;
        // rebase
        uint256 timestamp;
        uint8 counter;
        bool status;
        bool managed;
    }

    struct Position {
        uint256 nonce;
        address pool;
        uint256 liquidity;
        uint256 feeGrowth0;
        uint256 feeGrowth1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    struct ReadjustVars {
        bool zeroForOne;
        address poolAddress;
        int24 currentTick;
        uint160 sqrtPriceX96;
        uint160 exactSqrtPriceImpact;
        uint160 sqrtPriceLimitX96;
        uint128 baseLiquidity;
        uint256 amount0;
        uint256 amount1;
        uint256 amountIn;
        uint256 amount0Added;
        uint256 amount1Added;
        uint256 amount0Range;
        uint256 amount1Range;
        uint256 currentTimestamp;
        uint256 gasUsed;
        uint256 pilotAmount;
    }

    struct VarsEmerency {
        address token;
        address pool;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    struct WithdrawVars {
        address recipient;
        uint256 amount0Removed;
        uint256 amount1Removed;
        uint256 userAmount0;
        uint256 userAmount1;
        uint256 pilotAmount;
    }

    struct WithdrawTokenOwedParams {
        address token0;
        address token1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    struct MintCallbackData {
        address payer;
        address token0;
        address token1;
        uint24 fee;
    }

    struct UnipilotProtocolDetails {
        uint8 swapPercentage;
        uint24 swapPriceThreshold;
        uint256 premium;
        uint256 gasPriceLimit;
        uint256 userPilotPercentage;
        uint256 feesPercentageIndexFund;
        uint24 readjustFrequencyTime;
        uint16 poolCardinalityDesired;
        address pilotWethPair;
        address oracle;
        address indexFund; // 10%
        address uniStrategy;
        address unipilot;
    }

    struct SwapCallbackData {
        address token0;
        address token1;
        uint24 fee;
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    struct RemoveLiquidity {
        uint256 amount0;
        uint256 amount1;
        uint128 liquidityRemoved;
        uint256 feesCollected0;
        uint256 feesCollected1;
    }

    struct Tick {
        int24 baseTickLower;
        int24 baseTickUpper;
        int24 bidTickLower;
        int24 bidTickUpper;
        int24 rangeTickLower;
        int24 rangeTickUpper;
    }

    struct TokenDetails {
        address token0;
        address token1;
        uint24 fee;
        int24 currentTick;
        uint16 poolCardinality;
        uint128 baseLiquidity;
        uint128 bidLiquidity;
        uint128 rangeLiquidity;
        uint256 amount0Added;
        uint256 amount1Added;
    }

    struct DistributeFeesParams {
        bool pilotToken;
        bool wethToken;
        address pool;
        address recipient;
        uint256 tokenId;
        uint256 liquidity;
        uint256 amount0Removed;
        uint256 amount1Removed;
    }

    struct AddLiquidityManagerParams {
        address pool;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 shares;
    }

    struct DepositVars {
        uint24 fee;
        address pool;
        uint256 amount0Base;
        uint256 amount1Base;
        uint256 amount0Range;
        uint256 amount1Range;
    }

    struct RangeLiquidityVars {
        address token0;
        address token1;
        uint24 fee;
        uint128 rangeLiquidity;
        uint256 amount0Range;
        uint256 amount1Range;
    }

    struct IncreaseParams {
        address token0;
        address token1;
        uint24 fee;
        int24 currentTick;
        uint128 baseLiquidity;
        uint256 baseAmount0;
        uint256 baseAmount1;
        uint128 rangeLiquidity;
        uint256 rangeAmount0;
        uint256 rangeAmount1;
    }

    /// @notice Pull in tokens from sender. Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay to the pool for the minted liquidity.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;

    /// @notice Called to `msg.sender` after minting swaping from IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay to the pool for swap.
    /// @param amount0Delta The amount of token0 due to the pool for the swap
    /// @param amount1Delta The amount of token1 due to the pool for the swap
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;

    /// @notice Returns the user position information associated with a given token ID.
    /// @param tokenId The ID of the token that represents the position
    /// @return Position
    /// - nonce The nonce for permits
    /// - pool Address of the uniswap V3 pool
    /// - liquidity The liquidity of the position
    /// - feeGrowth0 The fee growth of token0 as of the last action on the individual position
    /// - feeGrowth1 The fee growth of token1 as of the last action on the individual position
    /// - tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// - tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function userPositions(uint256 tokenId) external view returns (Position memory);

    /// @notice Returns the vault information of unipilot base & range orders
    /// @param pool Address of the Uniswap pool
    /// @return LiquidityPosition
    /// - baseTickLower The lower tick of the base position
    /// - baseTickUpper The upper tick of the base position
    /// - baseLiquidity The total liquidity of the base position
    /// - rangeTickLower The lower tick of the range position
    /// - rangeTickUpper The upper tick of the range position
    /// - rangeLiquidity The total liquidity of the range position
    /// - fees0 Total amount of fees collected by unipilot positions in terms of token0
    /// - fees1 Total amount of fees collected by unipilot positions in terms of token1
    /// - feeGrowthGlobal0 The fee growth of token0 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// - feeGrowthGlobal1 The fee growth of token1 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// - totalLiquidity Total amount of liquidity of vault including base & range orders
    function poolPositions(address pool) external view returns (LiquidityPosition memory);

    /// @notice Calculates the vault's total holdings of token0 and token1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @param _pool Address of the uniswap pool
    /// @return amount0 Total amount of token0 in vault
    /// @return amount1 Total amount of token1 in vault
    /// @return totalLiquidity Total liquidity of the vault
    function updatePositionTotalAmounts(address _pool)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        );

    /// @notice Calculates the vault's total holdings of TOKEN0 and TOKEN1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @dev Updates the position and return the latest reserves & liquidity.
    /// @param token0 token0 of the pool
    /// @param token0 token1 of the pool
    /// @param data any necessary data needed to get reserves
    /// @return totalAmount0 Amount of token0 in the pool of unipilot
    /// @return totalAmount1 Amount of token1 in the pool of unipilot
    /// @return totalLiquidity Total liquidity available in unipilot pool
    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        returns (
            uint256 totalAmount0,
            uint256 totalAmount1,
            uint256 totalLiquidity
        );

    /// @notice Creates a new pool & then initializes the pool
    /// @param _token0 The contract address of token0 of the pool
    /// @param _token1 The contract address of token1 of the pool
    /// @param data Necessary data needed to create pool
    /// In data we will provide the `fee` amount of the v3 pool for the specified token pair,
    /// also `sqrtPriceX96` The initial square root price of the pool
    /// @return _pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address
    function createPair(
        address _token0,
        address _token1,
        bytes memory data
    ) external returns (address _pool);

    /// @notice Deposits tokens in proportion to the Unipilot's current ticks, mints them
    /// `Unipilot`s NFT.
    /// @param token0 The first of the two tokens of the pool, sorted by address
    /// @param token1 The second of the two tokens of the pool, sorted by address
    /// @param amount0Desired Max amount of token0 to deposit
    /// @param amount1Desired Max amount of token1 to deposit
    /// @param shares Number of shares minted
    /// @param tokenId Token Id of Unipilot
    /// @param isTokenMinted Boolean to check the minting of new tokenId of Unipilot
    /// @param data Necessary data needed to deposit
    function deposit(
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes memory data
    ) external payable;

    /// @notice withdraws the desired shares from the vault with accumulated user fees and transfers to recipient.
    /// @param pilotToken whether to recieve fees in PILOT or not (valid if user is not reciving fees in token0, token1)
    /// @param wethToken whether to recieve fees in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param liquidity The amount by which liquidity will be withdrawn
    /// @param tokenId The ID of the token for which liquidity is being withdrawn
    /// @param data Necessary data needed to withdraw liquidity from Unipilot
    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    /// @notice Collects up to a maximum amount of fees owed to a specific user position to the recipient
    /// @dev User have both options whether to recieve fees in PILOT or in pool token0 & token1
    /// @param pilotToken whether to recieve fees in PILOT or not (valid if user is not reciving fees in token0, token1)
    /// @param wethToken whether to recieve fees in WETH or ETH (only valid for WETH/ALT pairs)
    /// @param tokenId The ID of the Unpilot NFT for which tokens will be collected
    /// @param data Necessary data needed to collect fees from Unipilot
    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes memory data
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IHandler.sol";

interface IUnipilot {
    struct DepositVars {
        uint256 totalAmount0;
        uint256 totalAmount1;
        uint256 totalLiquidity;
        uint256 shares;
        uint256 amount0;
        uint256 amount1;
    }

    function governance() external view returns (address);

    function mintPilot(address recipient, uint256 amount) external;

    function mintUnipilotNFT(address sender) external returns (uint256 mintedTokenId);

    function deposit(IHandler.DepositParams memory params, bytes memory data)
        external
        payable
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range,
            uint256 mintedTokenId
        );

    function createPoolAndDeposit(
        IHandler.DepositParams memory params,
        bytes[2] calldata data
    )
        external
        payable
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range,
            uint256 mintedTokenId
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUnipilotFarmV1 {
    struct PoolInfo {
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 totalLockedLiquidity;
        uint256 rewardMultiplier;
        bool isRewardActive;
        bool isAltActive;
    }
    function poolInfo(address pool) external view returns (PoolInfo memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IUnipilotStake {
    function getBoostMultiplier(
        address userAddress,
        address poolAddress,
        uint256 tokenId
    ) external view returns (uint256);

    function userMultiplier(address userAddress, address poolAddress)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ReentrancyGuard {
    uint8 private _unlocked = 1;

    modifier nonReentrant() {
        require(_unlocked == 1, "ReentrancyGuard: reentrant call");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IULMEvents {
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address indexed pool,
        uint24 fee,
        uint160 sqrtPriceX96
    );

    event PoolReajusted(
        address pool,
        uint128 baseLiquidity,
        uint128 rangeLiquidity,
        int24 newBaseTickLower,
        int24 newBaseTickUpper,
        int24 newRangeTickLower,
        int24 newRangeTickUpper
    );

    event Deposited(
        address indexed pool,
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );

    event Collect(
        uint256 tokenId,
        uint256 userAmount0,
        uint256 userAmount1,
        uint256 pilotAmount,
        address pool,
        address recipient
    );

    event Withdrawn(
        address indexed pool,
        address indexed recipient,
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

/// @notice IHandler is a generalized interface for all the liquidity managers
/// @dev Contains all necessary methods that should be available in liquidity manager contracts
interface IHandler {
    struct DepositParams {
        address sender;
        address exchangeAddress;
        address token0;
        address token1;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    struct WithdrawParams {
        bool pilotToken;
        bool wethToken;
        address exchangeAddress;
        uint256 liquidity;
        uint256 tokenId;
    }

    struct CollectParams {
        bool pilotToken;
        bool wethToken;
        address exchangeAddress;
        uint256 tokenId;
    }

    function createPair(
        address _token0,
        address _token1,
        bytes calldata data
    ) external;

    function deposit(
        address token0,
        address token1,
        address sender,
        uint256 amount0,
        uint256 amount1,
        uint256 shares,
        bytes calldata data
    )
        external
        returns (
            uint256 amount0Base,
            uint256 amount1Base,
            uint256 amount0Range,
            uint256 amount1Range,
            uint256 mintedTokenId
        );

    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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