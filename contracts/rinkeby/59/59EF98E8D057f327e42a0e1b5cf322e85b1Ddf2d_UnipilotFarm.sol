//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

/// @title Unipilot Yield Farming
/// @author Asim Raza
/// @notice You can use this contract for gaining reward on locking nft
/// @dev All function calls are currently implemented without side effects

//Utility imports
import "./interfaces/IUnipilotFarm.sol";
import "./interfaces/uniswap/IUniswapLiquidityManager.sol";
import "./interfaces/IUnipilot.sol";
import "./libraries/LiquidityAmounts.sol";

//Uniswap v3 core imports
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

//Openzeppelin imports
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UnipilotFarm is IUnipilotFarm, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    // mapping farming data --> tokenId => pool add => bool
    mapping(uint256 => bool) public farmingActive;

    //mapping pool address => bool (Exist in whitelist or not)
    mapping(address => bool) public poolWhitelist;

    //mapping poolinfo add =>poolinfo struct
    mapping(address => PoolInfo) public poolInfo;

    //mapping userinfo user tokenId nft => user info
    mapping(uint256 => UserInfo) public userInfo;

    //user address => pool address => tokenId[]
    mapping(address => mapping(address => uint256[])) public userToPoolToTokenIds;

    modifier onlyGovernance() {
        require(governance == msg.sender, "NA");
        _;
    }

    modifier isActive() {
        require(isFarmingActive == true, "FNA");
        _;
    }

    modifier onlyOwner(uint256 tokenId) {
        require(IERC721(UNIPILOT).ownerOf(tokenId) == msg.sender, "NO");
        _;
    }

    modifier isRewardActive(address poolAddress) {
        require(poolInfo[poolAddress].isRewardActive == true, "RNA");
        _;
    }

    address internal ULM;
    address internal UNIPILOT;
    address internal PILOT_TOKEN;

    bool public isFarmingActive;
    address public governance;
    uint256 public globalFarmingReward;
    uint256 public farmingGrowthBlockLimit;
    //PILOT
    uint256 internal constant DEFAULT_REWARD_MULTIPLIER = 1e18;
    uint256 internal constant DEFAULT_PILOT_PER_BLOCK = 1e18;
    //ALT
    uint256 internal constant DEFAULT_ALT_PER_MULTIPLIER = 1e18;
    uint256 internal constant DEFAULT_ALT_PER_BLOCK = 1e18;

    constructor(
        address[] memory pools,
        address _ULM,
        address _UNIPILOT,
        address _PILOT_TOKEN
    ) {
        governance = msg.sender;

        ULM = _ULM;
        UNIPILOT = _UNIPILOT;
        PILOT_TOKEN = _PILOT_TOKEN;

        isFarmingActive = true;
        initializer(pools);
    }

    /// @notice withdraw NFT with reward
    /// @dev only owner of nft can withdraw
    /// @param tokenId unstake tokenID
    function withdrawNFT(uint256 tokenId) external override returns (bool isLeft) {
        address poolAddress = userInfo[tokenId].pool;
        withdrawReward(tokenId);
        poolInfo[poolAddress].totalLockedLiquidity = poolInfo[poolAddress]
            .totalLockedLiquidity
            .sub(userInfo[tokenId].liquidity);
        IERC721(UNIPILOT).safeTransferFrom(address(this), msg.sender, tokenId);

        farmingActive[tokenId] = false;

        emit WithdrawNFT(
            userInfo[tokenId].pool,
            userInfo[tokenId].user,
            tokenId,
            poolInfo[poolAddress].totalLockedLiquidity
        );

        if (poolInfo[poolAddress].totalLockedLiquidity == 0) {
            poolInfo[poolAddress].lastRewardBlock = block.number;
            poolInfo[poolAddress].startBlock = block.number;
            poolInfo[poolAddress].globalReward = 0;

            poolInfo[poolAddress].lastAltRewardBlock = block.number;
            poolInfo[poolAddress].startBlock = block.number;
            poolInfo[poolAddress].globalReward = 0;
        }

        uint256 index = callIndex(poolAddress, tokenId);
        delete userToPoolToTokenIds[msg.sender][poolAddress][index];
        delete userInfo[tokenId];

        isLeft = true;
    }

    /// @notice withdraw NFT without reward
    /// @param tokenId unstake tokenID
    function emergencyNFTWithdraw(uint256 tokenId) external {
        require(userInfo[tokenId].user == msg.sender, "NOO");
        IERC721(UNIPILOT).safeTransferFrom(
            address(this),
            userInfo[tokenId].user,
            tokenId
        );

        if (poolInfo[userInfo[tokenId].pool].totalLockedLiquidity == 0) {
            delete poolInfo[userInfo[tokenId].pool];
            insertPool(userInfo[tokenId].pool);
        }
        uint256 index = callIndex(userInfo[tokenId].pool, tokenId);
        delete userToPoolToTokenIds[msg.sender][userInfo[tokenId].pool][index];
        delete userInfo[tokenId];
    }

    /// @notice Migrate funds to Governance address or in new Contract
    /// @dev only governance can call this
    /// @param newContract address of new contract or wallet address
    /// @param tokenAddress address of token which want to migrate
    /// @param amount withdraw that amount which are required
    function migrateFunds(
        address newContract,
        address tokenAddress,
        uint256 amount
    ) external onlyGovernance {
        require(newContract != address(0), "Contract not exist");
        IERC20(tokenAddress).safeTransfer(newContract, amount);
    }

    function blacklistPools(address[] memory pools) external override onlyGovernance {
        for (uint256 i = 0; i < pools.length; i++) {
            poolWhitelist[pools[i]] = false;

            emit BlacklistPool(pools[i], poolWhitelist[pools[i]], block.timestamp);
        }
    }

    function updateULM(address _ULM) external override onlyGovernance {
        address old = ULM;
        ULM = _ULM;
        emit UpdateULM(old, ULM, block.timestamp);
    }

    function updateUnipilot(address _Unipilot) external override onlyGovernance {
        address old = UNIPILOT;
        UNIPILOT = _Unipilot;
        emit UpdateULM(old, UNIPILOT, block.timestamp);
    }

    function updatePilotPerBlock(address poolAddress, uint256 value)
        external
        override
        onlyGovernance
        returns (uint256)
    {
        PoolInfo storage poolState = poolInfo[poolAddress];

        uint256 currentGlobalReward = getGlobalReward(
            poolAddress,
            (block.number).sub(poolState.lastRewardBlock),
            poolState.rewardPerBlock,
            poolState.rewardMultiplier,
            poolState.globalReward
        );

        poolInfo[poolAddress].globalReward = currentGlobalReward;

        uint256 old = poolInfo[poolAddress].rewardPerBlock;
        poolInfo[poolAddress].rewardPerBlock = value;
        emit UpdatePilotPerBlock(poolAddress, old, poolInfo[poolAddress].rewardPerBlock);
        return poolInfo[poolAddress].rewardPerBlock;
    }

    function updateMultiplier(address poolAddress, uint256 value)
        external
        override
        onlyGovernance
    {
        PoolInfo storage poolState = poolInfo[poolAddress];

        uint256 currentGlobalReward = getGlobalReward(
            poolAddress,
            (block.number).sub(poolState.lastRewardBlock),
            poolState.rewardPerBlock,
            poolState.rewardMultiplier,
            poolState.globalReward
        );

        poolInfo[poolAddress].globalReward = currentGlobalReward;

        uint256 old = poolInfo[poolAddress].rewardMultiplier;
        poolInfo[poolAddress].rewardMultiplier = value;
        emit UpdateMultiplier(poolAddress, old, poolInfo[poolAddress].rewardMultiplier);
    }

    /// @notice User total nft(s) with respect to pool
    /// @param userAddress particular user address
    /// @param poolAddress particular pool address
    /// @return tokenCount Count of nft(s) and array of tokenID
    function totalUserNftWRTPool(address userAddress, address poolAddress)
        external
        view
        override
        returns (uint256 tokenCount, uint256[] memory tokenIds)
    {
        tokenCount = userToPoolToTokenIds[userAddress][poolAddress].length;
        tokenIds = userToPoolToTokenIds[userAddress][poolAddress];
    }

    function nftStatus(uint256 tokenId) external view override returns (bool) {
        return farmingActive[tokenId];
    }

    /// @notice User can call tx this to deposit nft
    /// @dev pool address must be exist in whitelisted pools
    /// @param tokenId tokenID which want to deposit
    /// @return status of farming is active for particular tokenID
    function depositNFT(uint256 tokenId)
        external
        override
        isActive
        onlyOwner(tokenId)
        returns (bool)
    {
        address sender = msg.sender;
        (, address poolAddress, uint256 liquidity, , , , ) = IUniswapLiquidityManager(ULM)
            .positions(tokenId);

        require(poolWhitelist[poolAddress] == true, "PNW");

        require(liquidity > 0, "ZL");

        uint256 lastGR = poolInfo[poolAddress].globalReward;

        // if (poolInfo[poolAddress].lastRewardBlock == poolInfo[poolAddress].startBlock) {
        //     poolInfo[poolAddress].globalReward = 0;
        // } else
        if (poolInfo[poolAddress].lastRewardBlock != poolInfo[poolAddress].startBlock) {
            uint256 blockDifference = (block.number).sub(
                poolInfo[poolAddress].lastRewardBlock
            );

            poolInfo[poolAddress].globalReward = getGlobalReward(
                poolAddress,
                blockDifference,
                poolInfo[poolAddress].rewardPerBlock,
                poolInfo[poolAddress].rewardMultiplier,
                poolInfo[poolAddress].globalReward
            );
        }

        poolInfo[poolAddress].totalLockedLiquidity = poolInfo[poolAddress]
            .totalLockedLiquidity
            .add(liquidity);

        userInfo[tokenId] = UserInfo({
            tokenId: tokenId,
            pool: poolAddress,
            liquidity: liquidity,
            user: sender,
            reward: poolInfo[poolAddress].globalReward,
            altReward: userInfo[tokenId].altReward
        });

        userToPoolToTokenIds[sender][poolAddress].push(userInfo[tokenId].tokenId);

        farmingActive[tokenId] = true; // user's farming active

        globalFarmingReward = globalFarmingReward.add(
            poolInfo[poolAddress].globalReward.sub(lastGR)
        );

        IERC721(UNIPILOT).safeTransferFrom(sender, address(this), tokenId);

        if (poolInfo[poolAddress].isAltActive == true) {
            altDeposit(poolAddress, tokenId);
        }

        poolInfo[poolAddress].lastRewardBlock = block.number;

        emit Deposit(
            poolAddress,
            userInfo[tokenId].tokenId,
            userInfo[tokenId].liquidity,
            poolInfo[poolAddress].totalLockedLiquidity,
            poolInfo[poolAddress].globalReward,
            poolInfo[poolAddress].rewardMultiplier,
            poolInfo[poolAddress].rewardPerBlock
        );
        return farmingActive[tokenId];
    }

    /// @notice Adding pools into whitelist of contract
    /// @dev onlyGovernance can call this
    /// @param pools The number of address of pools from ULM
    function initializer(address[] memory pools) public override onlyGovernance {
        for (uint256 i = 0; i < pools.length; i++) {
            if (poolWhitelist[pools[i]] == false) {
                insertPool(pools[i]);
            } else {
                poolInfo[pools[i]] = PoolInfo({
                    startBlock: block.number,
                    globalReward: 0,
                    lastRewardBlock: block.number,
                    totalLockedLiquidity: 0,
                    rewardMultiplier: DEFAULT_REWARD_MULTIPLIER,
                    rewardPerBlock: DEFAULT_PILOT_PER_BLOCK,
                    altRewardMultiplier: DEFAULT_ALT_PER_MULTIPLIER,
                    altRewardPerBlock: DEFAULT_ALT_PER_BLOCK,
                    altGlobalReward: 0,
                    isAltActive: poolInfo[pools[i]].isAltActive,
                    lastAltRewardBlock: block.number,
                    altToken: poolInfo[pools[i]].altToken,
                    isRewardActive: true
                });
            }
        }
    }

    /// @notice Generic function to calculating reward
    /// @param poolAddress pool address
    /// @param blockDifference difference of block from current block to last reward block
    /// @param rewardPerBlock reward on per block
    /// @param multiplier multiplier value
    /// @return globalReward
    function getGlobalReward(
        address poolAddress,
        uint256 blockDifference,
        uint256 rewardPerBlock,
        uint256 multiplier,
        uint256 _globalReward
    ) public view returns (uint256 globalReward) {
        uint256 temp = FullMath.mulDiv(rewardPerBlock, multiplier, 1e18);

        globalReward = FullMath
            .mulDiv(
                blockDifference.mul(temp),
                1e18,
                poolInfo[poolAddress].totalLockedLiquidity
            )
            .add(_globalReward);
    }

    /// @notice Generic function to calculating reward
    /// @param tokenId find current reward of tokenID
    /// @return pilotReward globalReward calculated pilot reward
    function currentReward(uint256 tokenId)
        public
        view
        override
        returns (uint256 pilotReward, uint256 globalReward)
    {
        address poolAddress = userInfo[tokenId].pool;
        uint256 blockDifference = (block.number).sub(
            poolInfo[poolAddress].lastRewardBlock
        );
        if (!isFarmingActive && block.number > farmingGrowthBlockLimit) {
            globalReward = poolInfo[poolAddress].globalReward;
        } else {
            globalReward = getGlobalReward(
                poolAddress,
                blockDifference,
                poolInfo[poolAddress].rewardPerBlock,
                poolInfo[poolAddress].rewardMultiplier,
                poolInfo[poolAddress].globalReward
            );
        }
        uint256 userReward = globalReward.sub(userInfo[tokenId].reward);

        pilotReward = (userReward.mul(userInfo[tokenId].liquidity)).div(1e18);
    }

    /// @notice Withdraw user's reward
    /// @dev only owner of nft can withdraw
    /// @param tokenId withdraw reward of this tokenID
    /// @return isSent status of sent
    function withdrawReward(uint256 tokenId)
        public
        override
        nonReentrant
        isRewardActive(userInfo[tokenId].pool)
        returns (bool isSent)
    {
        address poolAddress = userInfo[tokenId].pool;
        require(userInfo[tokenId].user == msg.sender, "NO");

        (uint256 pilotReward, uint256 globalReward) = currentReward(tokenId);
        require(IERC20(PILOT_TOKEN).balanceOf(address(this)) >= pilotReward, "IF");
        uint256 lastGR = poolInfo[poolAddress].globalReward;
        poolInfo[poolAddress].globalReward = globalReward;
        poolInfo[poolAddress].lastRewardBlock = block.number;
        userInfo[tokenId].reward = globalReward;
        globalFarmingReward = globalFarmingReward.add(
            poolInfo[poolAddress].globalReward.sub(lastGR)
        );

        IERC20(PILOT_TOKEN).safeTransfer(userInfo[tokenId].user, pilotReward);

        if (poolInfo[poolAddress].isAltActive == true) {
            altWithdraw(tokenId);
        }

        isSent = true;

        emit WithdrawReward(
            poolAddress,
            userInfo[tokenId].tokenId,
            userInfo[tokenId].liquidity,
            userInfo[tokenId].reward,
            poolInfo[poolAddress].globalReward,
            poolInfo[poolAddress].totalLockedLiquidity,
            pilotReward
        );
    }

    /// @notice internal function use for initialize struct values of single pool
    /// @dev generalFunction to add pools
    /// @param poolAddress pool address
    function insertPool(address poolAddress) internal {
        poolWhitelist[poolAddress] = true;
        poolInfo[poolAddress] = PoolInfo({
            startBlock: block.number,
            globalReward: 0,
            lastRewardBlock: block.number,
            totalLockedLiquidity: 0,
            rewardMultiplier: DEFAULT_REWARD_MULTIPLIER,
            rewardPerBlock: DEFAULT_PILOT_PER_BLOCK,
            altRewardMultiplier: DEFAULT_ALT_PER_MULTIPLIER,
            altRewardPerBlock: DEFAULT_ALT_PER_BLOCK,
            altGlobalReward: 0,
            isAltActive: poolInfo[poolAddress].isAltActive,
            lastAltRewardBlock: block.number,
            altToken: poolInfo[poolAddress].altToken,
            isRewardActive: true
        });
        emit NewPool(
            poolAddress,
            poolInfo[poolAddress].rewardPerBlock,
            poolInfo[poolAddress].rewardMultiplier,
            poolInfo[poolAddress].lastRewardBlock,
            poolWhitelist[poolAddress]
        );
    }

    /// @notice alt token Updating state
    /// @param poolAddress pool address for alt token
    function toggleActiveAlt(address poolAddress, address altTokenAddress)
        external
        onlyGovernance
        returns (bool)
    {
        emit UpdateActiveAlt(
            poolInfo[poolAddress].isAltActive,
            !poolInfo[poolAddress].isAltActive,
            poolAddress,
            altTokenAddress
        );
        if (poolInfo[poolAddress].isAltActive && altTokenAddress == address(0)) {
            poolInfo[poolAddress].isAltActive = !poolInfo[poolAddress].isAltActive;
            poolInfo[poolAddress].altToken = altTokenAddress;
        } else {
            poolInfo[poolAddress].altToken = altTokenAddress;
            poolInfo[poolAddress].isAltActive = true;
        }

        return poolInfo[poolAddress].isAltActive;
    }

    function altDeposit(address poolAddress, uint256 tokenId) internal {
        // if (
        //     poolInfo[poolAddress].lastAltRewardBlock == poolInfo[poolAddress].startBlock
        // ) {
        //     poolInfo[poolAddress].altGlobalReward = 0;
        // } else {
        if (
            poolInfo[poolAddress].lastAltRewardBlock != poolInfo[poolAddress].startBlock
        ) {
            uint256 blockDifference = (block.number).sub(
                poolInfo[poolAddress].lastAltRewardBlock
            );

            poolInfo[poolAddress].altGlobalReward = getGlobalReward(
                poolAddress,
                blockDifference,
                poolInfo[poolAddress].altRewardPerBlock,
                poolInfo[poolAddress].altRewardMultiplier,
                poolInfo[poolAddress].altGlobalReward
            );
        }

        poolInfo[poolAddress].lastAltRewardBlock = block.number;

        userInfo[tokenId].altReward = poolInfo[poolAddress].altGlobalReward;
    }

    function callIndex(address poolAddress, uint256 tokenId)
        internal
        view
        returns (uint256 index)
    {
        uint256[] memory tokens = userToPoolToTokenIds[msg.sender][poolAddress];
        for (uint256 i = 0; i <= tokens.length; i++) {
            if (tokenId == userToPoolToTokenIds[msg.sender][poolAddress][i]) {
                index = i;
                break;
            }
        }
        return index;
    }

    /// @notice Use for calculate current alt token reward
    /// @param tokenId check current reward fot this tokenID
    /// @return altReward altGlobalReward status of sent
    function currentAltReward(uint256 tokenId)
        public
        view
        override
        returns (uint256 altReward, uint256 altGlobalReward)
    {
        address poolAddress = userInfo[tokenId].pool;
        uint256 blockDifference = (block.number).sub(
            poolInfo[poolAddress].lastAltRewardBlock
        );
        if (!isFarmingActive && block.number > farmingGrowthBlockLimit) {
            altGlobalReward = poolInfo[poolAddress].altGlobalReward;
        } else {
            altGlobalReward = getGlobalReward(
                poolAddress,
                blockDifference,
                poolInfo[poolAddress].altRewardPerBlock,
                poolInfo[poolAddress].altRewardMultiplier,
                poolInfo[poolAddress].altGlobalReward
            );
        }
        uint256 userReward = altGlobalReward.sub(userInfo[tokenId].altReward);

        altReward = (userReward.mul(userInfo[tokenId].liquidity)).div(1e18);
    }

    function altWithdraw(uint256 tokenId) internal {
        address poolAddress = userInfo[tokenId].pool;
        (uint256 altReward, uint256 altGlobalReward) = currentAltReward(tokenId);
        require(
            IERC20(poolInfo[poolAddress].altToken).balanceOf(address(this)) >= altReward,
            "IF"
        );
        poolInfo[poolAddress].altGlobalReward = altGlobalReward;
        userInfo[tokenId].altReward = altGlobalReward;
        IERC20(poolInfo[poolAddress].altToken).safeTransfer(
            userInfo[tokenId].user,
            altReward
        );
        poolInfo[poolAddress].lastAltRewardBlock = block.number;
    }

    function updateAltPerBlock(address poolAddress, uint256 value)
        external
        onlyGovernance
        returns (uint256)
    {
        PoolInfo storage poolState = poolInfo[poolAddress];

        uint256 currentGlobalReward = getGlobalReward(
            poolAddress,
            (block.number).sub(poolState.lastAltRewardBlock),
            poolState.altRewardPerBlock,
            poolState.altRewardMultiplier,
            poolState.altGlobalReward
        );

        poolInfo[poolAddress].altGlobalReward = currentGlobalReward;

        uint256 old = poolInfo[poolAddress].altRewardPerBlock;
        poolInfo[poolAddress].altRewardPerBlock = value;
        emit UpdateAltPerBlock(poolAddress, old, poolInfo[poolAddress].altRewardPerBlock);
        return poolInfo[poolAddress].altRewardPerBlock;
    }

    function updateAltMultiplier(address poolAddress, uint256 value)
        external
        onlyGovernance
        returns (uint256)
    {
        PoolInfo storage poolState = poolInfo[poolAddress];

        uint256 currentGlobalReward = getGlobalReward(
            poolAddress,
            (block.number).sub(poolState.lastAltRewardBlock),
            poolState.altRewardPerBlock,
            poolState.altRewardMultiplier,
            poolState.altGlobalReward
        );

        poolInfo[poolAddress].altGlobalReward = currentGlobalReward;

        uint256 old = poolInfo[poolAddress].altRewardMultiplier;
        poolInfo[poolAddress].altRewardMultiplier = value;
        emit UpdateAltMultiplier(
            poolAddress,
            old,
            poolInfo[poolAddress].altRewardMultiplier
        );
        return poolInfo[poolAddress].altRewardMultiplier;
    }

    function toggleRewardStatus(address poolAddress) external override onlyGovernance {
        bool currentStatus = poolInfo[poolAddress].isRewardActive;
        poolInfo[poolAddress].isRewardActive = !poolInfo[poolAddress].isRewardActive;

        emit RewardStatus(
            poolAddress,
            currentStatus,
            poolInfo[poolAddress].isRewardActive
        );
    }

    function updateFarmingLimit(uint256 blockNumber) external onlyGovernance {
        require(blockNumber > block.number, "WN");
        require(isFarmingActive == false, "FA");
        uint256 old = farmingGrowthBlockLimit;
        farmingGrowthBlockLimit = blockNumber;
        emit UpdateFarmingLimit(old, farmingGrowthBlockLimit);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

interface IUnipilotFarm {
    struct PoolInfo {
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 totalLockedLiquidity;
        uint256 rewardMultiplier;
        uint256 rewardPerBlock;
        uint256 altGlobalReward;
        address altToken;
        bool isAltActive;
        uint256 altRewardMultiplier;
        uint256 altRewardPerBlock;
        uint256 lastAltRewardBlock;
        uint256 startBlock;
        bool isRewardActive;
    }

    struct UserInfo {
        uint256 tokenId;
        address pool;
        uint256 liquidity;
        address user;
        uint256 reward;
        uint256 altReward;
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
        address poolAddress,
        uint256 rewardPerBlock,
        uint256 rewardMultiplier,
        uint256 lastRewardBlock,
        bool status
    );

    event BlacklistPool(address poolAddress, bool status, uint256 time);

    event UpdateULM(address oldAddress, address newAddress, uint256);

    event UpdatePilotPerBlock(address poolAddress, uint256 old, uint256 updated);

    event UpdateMultiplier(address poolAddress, uint256 old, uint256 updated);

    event UpdateAltPerBlock(address poolAddress, uint256 old, uint256 updated);

    event UpdateAltMultiplier(address poolAddress, uint256 old, uint256 updated);

    event UpdateActiveAlt(bool old, bool updated, address poolAddress, address altToken);

    event UpdateFarmingLimit(uint256 old, uint256 updated);

    event UpdateAltToken(address poolAddress, address old, address updated);

    event RewardStatus(address poolAddress, bool old, bool updated);

    function initializer(address[] memory pools) external;

    function blacklistPools(address[] memory pools) external;

    function updatePilotPerBlock(address poolAddress, uint256 value)
        external
        returns (uint256);

    function updateMultiplier(address poolAddress, uint256 value) external;

    function updateULM(address _ULM) external;

    function updateUnipilot(address _Unipilot) external;

    function totalUserNftWRTPool(address userAddress, address poolAddress)
        external
        view
        returns (uint256 tokenCount, uint256[] memory tokenIds);

    function nftStatus(uint256 tokenId) external view returns (bool);

    function depositNFT(uint256 tokenId) external returns (bool);

    function withdrawNFT(uint256 tokenId) external returns (bool isLeft);

    function withdrawReward(uint256 tokenId) external returns (bool isSent);

    function currentReward(uint256 tokenId)
        external
        view
        returns (uint256 pilotReward, uint256 globalReward);

    function currentAltReward(uint256 tokenId)
        external
        view
        returns (uint256 altReward, uint256 altGlobalReward);

    function toggleRewardStatus(address poolAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IULMEvents.sol";
import "../IHandler.sol";

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
        uint256 currentTimestamp;
        uint256 gasUsed;
        uint256 pilotAmount;
    }

    struct WithdrawVars {
        address recipient;
        uint256 amount0Removed;
        uint256 amount1Removed;
        uint256 userAmount0;
        uint256 userAmount1;
        uint256 indexAmount0;
        uint256 indexAmount1;
        uint256 pilotAmount;
    }

    struct WithdrawTokenOwedParams {
        address token0;
        address token1;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
        uint256 feeGrowthGlobal0;
        uint256 feeGrowthGlobal1;
    }

    struct ReadjustFrequency {
        uint256 timestamp;
        uint256 counter;
        bool status;
    }

    struct MintCallbackData {
        address payer;
        address token0;
        address token1;
        uint24 fee;
    }

    struct PilotSustainabilityFund {
        address recipient;
        uint8 pilotPercentage;
        bool status;
    }

    struct SwapCallbackData {
        address token0;
        address token1;
        uint24 fee;
    }

    struct AddLiquidityParams {
        address sender;
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
        address sender;
        address pool;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 shares;
    }

    struct DepositVars {
        uint24 fee;
        uint256 tokenId;
        address pool;
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
    /// @param nftId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return pool Address of the uniswap V3 pool
    /// @return liquidity The liquidity of the position
    /// @return feeGrowth0 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowth1 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 nftId)
        external
        view
        returns (
            uint256 nonce,
            address pool,
            uint256 liquidity,
            uint256 feeGrowth0,
            uint256 feeGrowth1,
            uint256 tokensOwed0,
            uint256 tokensOwed1
        );

    /// @notice Returns the vault information of unipilot base & range orders
    /// @param pool Address of the Uniswap pool
    /// @return baseTickLower The lower tick of the base position
    /// @return baseTickUpper The upper tick of the base position
    /// @return baseLiquidity The total liquidity of the base position
    /// @return rangeTickLower The lower tick of the range position
    /// @return rangeTickUpper The upper tick of the range position
    /// @return rangeLiquidity The total liquidity of the range position
    /// @return fees0 Total amount of fees collected by unipilot positions in terms of token0
    /// @return fees1 Total amount of fees collected by unipilot positions in terms of token1
    /// @return feeGrowthGlobal0 The fee growth of token0 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// @return feeGrowthGlobal1 The fee growth of token1 collected per unit of liquidity for
    /// the entire life of the unipilot vault
    /// @return totalLiquidity Total amount of liquidity of vault including base & range orders
    function liquidityPositions(address pool)
        external
        view
        returns (
            int24 baseTickLower,
            int24 baseTickUpper,
            uint128 baseLiquidity,
            int24 rangeTickLower,
            int24 rangeTickUpper,
            uint128 rangeLiquidity,
            uint256 fees0,
            uint256 fees1,
            uint256 feeGrowthGlobal0,
            uint256 feeGrowthGlobal1,
            uint256 totalLiquidity
        );

    /// @notice Returns the user ID for the vault
    /// @param sender Address of the user
    /// @param pool Address of the pool
    /// @return tokenId ID of the unipilot vault
    function addressToNftId(address sender, address pool)
        external
        view
        returns (uint256 tokenId);

    /// @notice Calculates the vault's total holdings of token0 and token1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @param _pool Address of the uniswap pool
    /// @return fee0 Accumulated fees of vault in token0
    /// @return fee1 Accumulated fees of vault in token0
    /// @return amount0 Total amount of token0 in vault
    /// @return amount1 Total amount of token1 in vault
    /// @return totalLiquidity Total liquidity of the vault
    function updatePositionTotalAmounts(address _pool)
        external
        returns (
            uint256 fee0,
            uint256 fee1,
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

    /// @notice Calculates the vault's total holdings of token0 and token1 - in
    /// other words, how much of each token the vault would hold if it withdrew
    /// all its liquidity from Uniswap.
    /// @param pool Address of the uniswap pool
    /// @return fee0
    /// @return fee1
    /// @return amount0
    /// @return amount1
    /// @return totalLiquidity
    function getTotalAmounts(address pool)
        external
        view
        returns (
            uint256 fee0,
            uint256 fee1,
            uint256 amount0,
            uint256 amount1,
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
    /// @param sender Recipient of shares
    /// @param amount0Desired Max amount of token0 to deposit
    /// @param amount1Desired Max amount of token1 to deposit
    /// @param shares Number of shares minted
    /// @param data Necessary data needed to deposit
    /// @return amount0Base Base token0 amount added to the Unipilot
    /// @return amount1Base Base token1 amount added to the Unipilot
    /// @return amount0Range Range token0 amount added to the Unipilot
    /// @return amount1Range Range token1 amount added to the Unipilot
    /// @return mintedTokenId The ID of the token that represents the minted position
    function deposit(
        address token0,
        address token1,
        address sender,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 shares,
        bytes memory data
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
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

import "./IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
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

//SPDX-License-Identifier: UNLICENSED
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
        uint256 indexAmount0,
        uint256 indexAmount1,
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
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