pragma solidity ^0.8.0;

import "./helpers.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CoreInternals is Helpers {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct OverallPosition {
        address pool_;
        address token0_;
        address token1_;
        address poolAddr_;
        uint128 liquidity_;
        uint totalSupplyInUsd_;
        uint totalNormalSupplyInUsd_;
        uint totalBorrowInUsd_;
        uint totalNormalBorrowInUsd_;
    }

    /**
    * @dev deposit's NFT and creates a debt position against it.
    * @param owner_ owner of the NFT.
    * @param NFTID_ ID of NFT.
    */
    function deposit(address owner_, uint256 NFTID_) internal {
        _position[owner_][NFTID_] = true;
        (
            ,
            ,
            address token0_,
            address token1_,
            uint24 fee_,
            int24 tickLower_,
            int24 tickUpper_,
            ,
            ,
            ,
            ,
        ) = nftManager.positions(NFTID_);
        address pool_ = getPoolAddress(token0_, token1_, fee_);
        require(poolEnabled_[pool_], "NFT-pool-not-enabled");
        require(uint24(tickUpper_ - tickLower_) > _minTick[pool_], "less-ticks-difference");

        emit depositLog(owner_, NFTID_);
    }

    /**
    * @dev remove liquidity from an NFT. Called when owner withdraws or liquidator liquidates.
    * @param NFTID_ NFT ID
    * @param liquidity_ liquidity to withdraw
    * @param amount0Min_ minimum amount0 to withdraw
    * @param amount1Min_ minimum amount1 to withdraw
    * @param isLiquidate_ position got liquidated or just a normal withdrawal
    */
    function _removeLiquidity(
        uint96 NFTID_,
        uint256 liquidity_,
        uint256 amount0Min_,
        uint256 amount1Min_,
        bool isLiquidate_
    )
        internal
        returns (uint256 exactAmount0_, uint256 exactAmount1_)
    {
        (exactAmount0_, exactAmount1_) = _decreaseLiquidity(
            NFTID_,
            liquidity_,
            0,
            0
        );
        require(exactAmount0_ > amount0Min_, "less-than-min-amount");
        require(exactAmount1_ > amount1Min_, "less-than-min-amount");
            address token0_;
        address token1_;
        if (isLiquidate_) {
            (,, token0_, token1_,,,,,,,,) = nftManager.positions(NFTID_);
        } else {
            address pool_;
            uint totalSupplyInUsd_;
            uint totalNormalSupplyInUsd_;
            uint totalBorrowInUsd_;
            uint totalNormalBorrowInUsd_;
            (
                pool_,
                token0_,
                token1_,
                ,
                totalSupplyInUsd_,
                totalNormalSupplyInUsd_,
                totalBorrowInUsd_,
                totalNormalBorrowInUsd_
            ) = getOverallPosition(
                NFTID_
            );
            bool isOk_ = liquidationCheck(
                pool_,
                totalSupplyInUsd_,
                totalBorrowInUsd_,
                totalNormalSupplyInUsd_,
                totalNormalBorrowInUsd_
            );
            require(isOk_, "position-will-liquidate");
        }
        _collect(NFTID_, type(uint128).max, type(uint128).max);
    }

    /**
    * @dev collect fee accrued of an NFT. Throws if on withdrawing fees position is going to Liquidate.
    * @param NFTID_ NFT ID.
    * @return amount0_ amount0 collected.
    * @return amount1_ amount1 collected.
    */
    function _collectFees(uint96 NFTID_, bool isLiquidate_)
        internal
        returns (uint256 amount0_, uint256 amount1_)
    {
        (amount0_, amount1_) = _collect(NFTID_, type(uint128).max, type(uint128).max);
        address token0_;
        address token1_;
        if (isLiquidate_) {
            (,, token0_, token1_,,,,,,,,) = nftManager.positions(NFTID_);
        } else {
            address pool_;
            uint totalSupplyInUsd_;
            uint totalNormalSupplyInUsd_;
            uint totalBorrowInUsd_;
            uint totalNormalBorrowInUsd_;
            (
                pool_,
                token0_,
                token1_,
                ,
                totalSupplyInUsd_,
                totalNormalSupplyInUsd_,
                totalBorrowInUsd_,
                totalNormalBorrowInUsd_
            ) = getOverallPosition(
                NFTID_
            );
            bool isOk_ = liquidationCheck(
                pool_,
                totalSupplyInUsd_,
                totalBorrowInUsd_,
                totalNormalSupplyInUsd_,
                totalNormalBorrowInUsd_
            );
            require(isOk_, "position-will-liquidate");
        }
        IERC20 token0 = IERC20(token0_);
        IERC20 token1 = IERC20(token1_);
        token0.safeTransfer(msg.sender, amount0_);
        token1.safeTransfer(msg.sender, amount1_);
    }

    /**
    * @dev Liquidate an NFT. Only applicable when position crosses borrow limit. Owner loses entire collateral.
    * @param NFTID_ NFT ID
    * @param amount0Min_ amount0 min acceptable amount on withdraw
    * @return exactAmount0_ exact amount 0 retuned.
    * @return exactAmount1_ exact amount 1 retuned.
    * @return markets_ array of borrow tokens for the NFT pool.
    * @return paybackAmts_ array of payed back amounts.
    */
    function _liquidate(
        uint96 NFTID_,
        uint amount0Min_,
        uint amount1Min_
    ) internal returns (
        uint exactAmount0_,
        uint exactAmount1_,
        address[] memory markets_,
        uint[] memory paybackAmts_
    ) {
        OverallPosition memory overallPosition_;
        (
            overallPosition_.pool_,
            ,
            ,
            overallPosition_.liquidity_,
            overallPosition_.totalSupplyInUsd_,
            overallPosition_.totalNormalSupplyInUsd_,
            overallPosition_.totalBorrowInUsd_,
            overallPosition_.totalNormalBorrowInUsd_
        ) = getOverallPosition(
            NFTID_
        );
        verifyOracles(overallPosition_.pool_);
        bool isOk_ = liquidationCheck(
            overallPosition_.pool_,
            overallPosition_.totalSupplyInUsd_,
            overallPosition_.totalBorrowInUsd_,
            overallPosition_.totalNormalSupplyInUsd_,
            overallPosition_.totalNormalBorrowInUsd_
        );
        require(!isOk_, "position-will-liquidate");
        for (uint i = 0; i < markets_.length; i++) {
            markets_ = _poolMarkets[overallPosition_.pool_];
            paybackAmts_ = new uint[](markets_.length);

            (paybackAmts_[i]) = _payback(
                NFTID_,
                markets_[i],
                type(uint).max
            );
            if (paybackAmts_[i] > 0) {
                IERC20 token_ = IERC20(markets_[i]);
                token_.safeTransferFrom(msg.sender, address(this), paybackAmts_[i]);
                token_.approve(address(liquidity), paybackAmts_[i]);
                liquidity.payback(markets_[i], paybackAmts_[i]);
            }
        }
        (exactAmount0_, exactAmount1_) = _removeLiquidity(
            NFTID_,
            overallPosition_.liquidity_, // in percent, 1e18 = 100% withdrawal
            amount0Min_,
            amount1Min_,
            true
        );
        (uint amount0Fee_, uint amount1Fee_) = _collectFees(NFTID_, true);

        emit liquidateLog(
            NFTID_,
            (exactAmount0_ + amount0Fee_),
            (exactAmount1_ + amount1Fee_),
            markets_,
            paybackAmts_
        );
    }

    function _stake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint256 tokenId_
    ) internal {
        (
            address token0_,
            address token1_,
            uint24 fee_
        ) = getNftTokenPairAddresses(tokenId_);

        address poolAddr_ = getPoolAddress(token0_, token1_, fee_);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr_);
        IUniswapV3Staker.IncentiveKey memory _key = IUniswapV3Staker
            .IncentiveKey(
                IERC20Minimal(rewardToken_),
                pool,
                startTime_,
                endTime_,
                refundee_
            );
        
        staker.stakeToken(_key, tokenId_);
    }

    struct TokenPair {
        address token0;
        address token1;
        uint24 fee;
    }

    function _unstake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) internal {
        TokenPair memory tp_;
        (
            tp_.token0,
            tp_.token1,
            tp_.fee
        ) = getNftTokenPairAddresses(NFTID_);
        
        address poolAddr_ = getPoolAddress(tp_.token0, tp_.token1, tp_.fee);

        IERC20Minimal rewardTokenContract_ = IERC20Minimal(rewardToken_);

        IUniswapV3Pool pool_ = IUniswapV3Pool(poolAddr_);
        IUniswapV3Staker.IncentiveKey memory key_ = IUniswapV3Staker
            .IncentiveKey(
                rewardTokenContract_,
                pool_,
                startTime_,
                endTime_,
                refundee_
            );

        uint initialReward_ = staker.rewards(rewardTokenContract_, address(this));

        staker.unstakeToken(key_, NFTID_);

        uint finalReward_ = staker.rewards(rewardTokenContract_, address(this));
        _rewardAccrued[NFTID_][rewardToken_] += (finalReward_ - initialReward_);
    }

    function _claimRewards(
        IERC20Minimal rewardToken_,
        address to_,
        uint256 amountRequested_
    ) internal {
        staker.claimReward(rewardToken_, to_, amountRequested_);
    }

}

contract UserModule is CoreInternals {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    /**
    * @dev modifier the verify owner of NFT position. msg.sender should be an owner.
    * @param NFTID_ ID of NFT.
    */
    modifier isPositionOwner(uint96 NFTID_) {
        require(_position[msg.sender][NFTID_], "not-an-owner");
        _;
    }

    /**
    * @dev Triggers when an ERC721 token receives to this contract.
    * @param _operator Person who initiated the transfer of NFT.
    * @param _from owner of NFT.
    * @param _id ID of NFT.
    */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata
    ) external nonReentrant returns (bytes4) {
        require(_operator == _from, "operator-should-be-the-owner");
        require(msg.sender == nftManagerAddr, "Not-Uniswap-V3-NFT");
        deposit(_from, _id);
        return 0x150b7a02;
    }

    /**
    * @dev Withdraws the NFT from contract. NFT should have 0 debt.
    * @param NFTID_ NFT ID
    */
    function withdraw(uint96 NFTID_) external isPositionOwner(NFTID_) nonReentrant {
        bool has_ = hasDebt(NFTID_);
        require(!has_, "debt-should-be-0");
        _position[msg.sender][NFTID_] = false;
        nftManager.safeTransferFrom(address(this), msg.sender, NFTID_);

        emit withdrawLog(NFTID_);
    }

    /**
    * @dev add more liquidity to NFT. Open function - anyone can call.
    * @param NFTID_ NFT ID
    * @param amount0_ desired amount0 to deposit
    * @param amount1_ desired amount1 to withdraw
    * @param minAmount0_ minimum amount0 to deposit
    * @param minAmount1_ minimum amount1 to deposit
    * @param deadline_ deadline of transaction
    * @return exactAmount0_ exact amount0 deposited
    * @return exactAmount1_ exact amount1 deposited
    */
    function addLiquidity(
        uint96 NFTID_,
        uint256 amount0_,
        uint256 amount1_,
        uint256 minAmount0_,
        uint256 minAmount1_,
        uint256 deadline_
    ) external nonReentrant  returns (uint256 exactAmount0_, uint256 exactAmount1_) {
        (address token0Addr_, address token1Addr_, ) = getNftTokenPairAddresses(NFTID_);
        IERC20 token0_ = IERC20(token0Addr_);
        IERC20 token1_ = IERC20(token1Addr_);
        token0_.safeTransferFrom(msg.sender, address(this), amount0_);
        token1_.safeTransferFrom(msg.sender, address(this), amount1_);
        token0_.safeApprove(nftManagerAddr, amount0_);
        token1_.safeApprove(nftManagerAddr, amount1_);
        (, exactAmount0_, exactAmount1_) = _addLiquidity(
            NFTID_,
            amount0_,
            amount1_,
            minAmount0_,
            minAmount1_,
            deadline_
        );
        require(exactAmount0_ > minAmount0_, "less-than-min-amount");
        require(exactAmount1_ > minAmount1_, "less-than-min-amount");
        token0_.safeTransfer(msg.sender, amount0_ - exactAmount0_);
        token1_.safeTransfer(msg.sender, amount1_ - exactAmount1_);

        emit addLiquidityLog(
            NFTID_,
            exactAmount0_,
            exactAmount1_,
            deadline_
        );
    }

    /**
    * @dev removes liquidity from an NFT.
    * @param NFTID_ NFT ID
    * @param liquidity_ liquidity to withdraw
    * @param amount0Min_ minimum amount0 to withdraw
    * @param amount1Min_ minimum amount1 to withdraw
    * @return exactAmount0_ exact amount0 withdrawn
    * @return exactAmount1_ exact amount1 withdrawn
    */
    function removeLiquidity(
        uint96 NFTID_,
        uint256 liquidity_,
        uint256 amount0Min_,
        uint256 amount1Min_
    )
        external
        nonReentrant
        isPositionOwner(NFTID_)
        returns (uint256 exactAmount0_, uint256 exactAmount1_)
    {
        (exactAmount0_, exactAmount1_) = _removeLiquidity(
            NFTID_,
            liquidity_,
            amount0Min_,
            amount1Min_,
            false
        );

        emit removeLiquidityLog(NFTID_, exactAmount0_, exactAmount1_);
    }

    /**
    * @dev borrow against an NFT debt position. Throws if borrow more than borrow limit.
    * @param NFTID_ NFT ID
    * @param token_ token to borrow
    * @param amount_ amount to borrow
    */
    function borrow(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    ) external isPositionOwner(NFTID_) nonReentrant {
        _borrow(NFTID_, token_, amount_);
        (
            address pool_,
            ,
            ,
            ,
            uint totalSupplyInUsd_,
            uint totalNormalSupplyInUsd_,
            uint totalBorrowInUsd_,
            uint totalNormalBorrowInUsd_
        ) = getOverallPosition(
            NFTID_
        );
        require(_borrowAllowed[pool_][token_], "token-not-allowed-for-borrow");
        bool isOk_ = liquidationCheck(
            pool_,
            totalSupplyInUsd_,
            totalBorrowInUsd_,
            totalNormalSupplyInUsd_,
            totalNormalBorrowInUsd_
        );
        require(isOk_, "position-will-liquidate");
        liquidity.borrow(token_, amount_);

        IERC20(token_).safeTransfer(msg.sender, amount_);

        emit borrowLog(NFTID_, token_, amount_);
    }

    /**
    * @dev payback debt of an NFT debt position.
    * @param NFTID_ NFT ID.
    * @param token_ token to payback.
    * @param amount_ amount to payback.
    * @return exactAmount_ exact amount payed back.
    */
    function payback(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    ) external nonReentrant returns (uint exactAmount_) {
        IERC20 tokenContract_ = IERC20(token_);
        exactAmount_ = _payback(
            NFTID_,
            token_,
            amount_
        );
        if (exactAmount_ > 0) {
            tokenContract_.safeTransferFrom(msg.sender, address(this), exactAmount_);
            tokenContract_.safeApprove(address(liquidity), exactAmount_);
            liquidity.payback(token_, exactAmount_);
        }

        emit paybackLog(NFTID_, token_, amount_);
    }

    /**
    * @dev collect fee accrued of an NFT. Throws if on withdrawing fees position is going to Liquidate.
    * @param NFTID_ NFT ID.
    * @return amount0_ amount0 collected.
    * @return amount1_ amount1 collected.
    */
    function collectFees(uint96 NFTID_)
        external
        isPositionOwner(NFTID_)
        nonReentrant
        returns (uint256 amount0_, uint256 amount1_)
    {
        (amount0_, amount1_) = _collectFees(NFTID_, false);

        emit collectFeeLog(NFTID_, amount0_, amount1_);
    }

    /**
    * @dev Liquidate an NFT. Only applicable when position crosses borrow limit. Owner loses entire collateral.
    * @param NFTID_ NFT ID
    * @param amount0Min_ amount0 min acceptable amount on withdraw
    * @param amount1Min_ amount1 min acceptable amount on withdraw
    * @return exactAmount0_ exact amount 0 retuned.
    * @return exactAmount1_ exact amount 1 retuned.
    * @return markets_ array of borrow tokens for the NFT pool.
    * @return paybackAmts_ array of payed back amounts.
    */
    function liquidate(
        uint96 NFTID_,
        uint amount0Min_,
        uint amount1Min_
    ) external nonReentrant returns (
        uint exactAmount0_,
        uint exactAmount1_,
        address[] memory markets_,
        uint[] memory paybackAmts_
    ) {
        (
            exactAmount0_,
            exactAmount1_,
            markets_,
            paybackAmts_
        ) = _liquidate(
            NFTID_,
            amount0Min_,
            amount1Min_
        );
    }

    struct LiquidateVariables {
        uint exactAmount0;
        uint exactAmount1;
        address[] markets;
        uint[] paybackAmts;
    }

    /**
    * @dev Liquidate an NFT. Only applicable when position crosses borrow limit. Owner loses entire collateral.
    * @param NFTID_ NFT ID
    * @param amount0Min_ amount0 min acceptable amount on withdraw
    * @param amount1Min_ amount1 min acceptable amount on withdraw
    * @param rewardTokens_ reward tokens for which to unstake
    * @param startTime_ start time of rewards for which to unstake
    * @param endTime_ end time of rewards for which to unstake
    * @param refundee_ refundee of rewards for which to unstake
    */
    function liquidate(
        uint96 NFTID_,
        uint amount0Min_,
        uint amount1Min_,
        address[] memory rewardTokens_,
        uint256[] memory startTime_,
        uint256[] memory endTime_,
        address[] memory refundee_
    ) external nonReentrant returns (LiquidateVariables memory v_) {
        require(_isStaked[NFTID_], "NFT-not-staked");
        for (uint i = 0; i < rewardTokens_.length; i++) {
            _unstake(rewardTokens_[i], startTime_[i], endTime_[i], refundee_[i], NFTID_);
        }
        staker.withdrawToken(NFTID_, address(this), "");
        _isStaked[NFTID_] = false;
        (
            v_.exactAmount0,
            v_.exactAmount1,
            v_.markets,
            v_.paybackAmts
        ) = _liquidate(
            NFTID_,
            amount0Min_,
            amount1Min_
        );
        return v_;
    }

    /**
     * @dev Deposit NFT token
     * @notice Transfer deposited NFT token
     * @param NFTID_ NFT LP Token ID
     */
    function depositNFT(uint96 NFTID_)
        external
        isPositionOwner(NFTID_) nonReentrant
    {
        _isStaked[NFTID_] = true;
        nftManager.safeTransferFrom(
            address(this),
            address(staker),
            NFTID_
        );
    }

    /**
     * @dev Withdraw NFT LP token
     * @notice Withdraw NFT LP token from staking pool
     * @param NFTID_ NFT LP Token ID
     */
    function withdrawNFT(uint96 NFTID_)
        external
        isPositionOwner(NFTID_) nonReentrant
    {
        staker.withdrawToken(NFTID_, address(this), "");
        _isStaked[NFTID_] = false;
    }

    /**
     * @dev Stake NFT LP token
     * @notice Stake NFT LP Position
     * @param rewardToken_ _rewardToken address
     * @param startTime_ stake start time
     * @param endTime_ stake end time
     * @param refundee_ refundee address
     * @param NFTID_ NFT LP token id
     */
    function stake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    )
        external
        isPositionOwner(NFTID_) nonReentrant
    {
        _stake(rewardToken_, startTime_, endTime_, refundee_, NFTID_);
    }

    /**
     * @dev Unstake NFT LP token
     * @notice Unstake NFT LP Position
     * @param rewardToken_ _rewardToken address
     * @param startTime_ stake start time
     * @param endTime_ stake end time
     * @param refundee_ refundee address
     * @param NFTID_ NFT LP token id
     */
    function unstake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    )
        external
        isPositionOwner(NFTID_) nonReentrant
    {
        _unstake(rewardToken_, startTime_, endTime_, refundee_, NFTID_);
    }

    /**
     * @dev Claim rewards
     * @notice Claim rewards
     * @param rewardToken_ _rewardToken address
     * @param NFTID_ NFT ID
     */
    function claimRewards(
        address rewardToken_,
        uint96 NFTID_
    )
        external
        isPositionOwner(NFTID_) nonReentrant
        returns (uint256 rewards_)
    {
        rewards_ = _rewardAccrued[NFTID_][rewardToken_];
        _rewardAccrued[NFTID_][rewardToken_] = 0;
        _claimRewards(
            IERC20Minimal(rewardToken_),
            msg.sender,
            rewards_
        );
    }

}

pragma solidity ^0.8.0;

import "../common/variables.sol";
import "./events.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/TickMath.sol";
import "./libraries/FullMath.sol";
import "./libraries/FixedPoint128.sol";
import "./libraries/LiquidityAmounts.sol";
import "./libraries/PositionKey.sol";
import "./interfaces.sol";


contract UniswapHelpers is Variables, Events {
    using SafeMath for uint256;

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address internal constant nftManagerAddr =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    INonfungiblePositionManager internal constant nftManager =
        INonfungiblePositionManager(nftManagerAddr);
    IUniswapV3Staker internal constant staker =
        IUniswapV3Staker(0xe34139463bA50bD61336E0c446Bd8C0867c6fE65);
    address internal constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    struct Position {
        uint24 fee_;
        int24 tickLower_;
        int24 tickUpper_;
        uint256 feeGrowthInside0LastX128_;
        uint256 feeGrowthInside1LastX128_;
        uint128 tokensOwed0_;
        uint128 tokensOwed1_;
        uint256 amount0_;
        uint256 amount1_;
        uint256 feeAccrued0_;
        uint256 feeAccrued1_;
    }

    /**
     * @dev computes the address of pool
     * @param factory_ factory address
     * @param key_ PoolKey struct
     */
    function computeAddress(address factory_, PoolKey memory key_)
        internal
        pure
        returns (address pool_)
    {
        require(key_.token0 < key_.token1);
        pool_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory_,
                            keccak256(
                                abi.encode(key_.token0, key_.token1, key_.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev returns pool address.
     * @param token0_ token 0 address
     * @param token1_ token 1 address
     * @param fee_ fee of pool
     * @return poolAddr_ pool address
     */
    function getPoolAddress(
        address token0_,
        address token1_,
        uint24 fee_
    ) internal view returns (address poolAddr_) {
        poolAddr_ = computeAddress(
            nftManager.factory(),
            PoolKey({token0: token0_, token1: token1_, fee: fee_})
        );
    }

    /**
     * @dev Returns token pairs from NFT ID
     * @param NFTID_ NFT ID
     * @return token0_ token 0 address
     * @return token1_ token 1 address
     */
    function getNftTokenPairAddresses(uint256 NFTID_)
        internal
        view
        returns (address token0_, address token1_, uint24 fee_)
    {
        (
            ,
            ,
            token0_,
            token1_,
            fee_,
            ,
            ,
            ,
            ,
            ,
            ,
        ) = nftManager.positions(NFTID_);
    }
}

contract OraclesHelpers is UniswapHelpers {
    using SafeMath for uint256;

    /**
     * Returns the (latest price in USD in 18 decimals & token decimals) via chainlink oracle
     * @param token_ address of token
     * @return token price in USD in 18 decimals
     */
    function getPriceInUsd(address token_)
        internal
        view
        returns (uint256)
    {
        ChainLinkOracle oracle_ = ChainLinkOracle(_chainlinkOracle[token_]);
        return uint256(uint(oracle_.latestAnswer())) * 10**(18 - oracle_.decimals());
    }

    /**
     * Returns multiple tokens (latest price in USD in 18 decimals & token decimals) via chainlink oracle
     * @param tokens_ array of token addresses
     * @return amounts_ array of prices in USD in 18 decimals
     */
    function getPricesInUsd(address[] memory tokens_)
        internal
        view
        returns (uint256[] memory amounts_)
    {
        amounts_ = new uint256[](tokens_.length);
        for (uint256 i = 0; i < tokens_.length; i++) {
            amounts_[i] = getPriceInUsd(tokens_[i]);
        }
    }

    /**
     * returns the price of token0 w.r.t to price of token1. Eg:- 1 ETH = 3300 USDC.
     * @param token0_ Token for which the price needs to calculate
     * @param token1_ Token in which price is needed
     */
    function getOraclePrice(address token0_, address token1_)
        internal
        view
        returns (uint256)
    {
        uint price0_ = getPriceInUsd(token0_);
        uint price1_ = getPriceInUsd(token1_);
        uint token0Decimals_ = TokenInterface(token0_).decimals();
        uint token1Decimals_ = TokenInterface(token1_).decimals();
        return price0_.mul(1e18).div(price1_).mul(10 ** token1Decimals_).div(10 ** token0Decimals_);
    }

    /**
     * returns array of ticks at different checkpoints from Uniswap oracle.
     * @param pool_ Uniswap pool for which the price needs to be calculate.
     * @param secondsAgos_ Array of seconds ago (checkpoints, only admin can set it)
     * @return ticks_ array of ticks at different points
     */
    function getUniswapOracleTicksWithSecondsAgos(
        IUniswapV3Pool pool_,
        uint32[] memory secondsAgos_
    ) internal view returns (int56[] memory ticks_) {
        // eg: of secondAgos_ [0, 10, 30, 60, 120, 300]
        (int56[] memory tickCumulatives_, ) = pool_.observe(secondsAgos_);
        ticks_ = new int56[](secondsAgos_.length - 1);
        for (uint256 i = 1; i < secondsAgos_.length; i++) {
            ticks_[i - 1] = (tickCumulatives_[i] - tickCumulatives_[0]) / int56(uint56(secondsAgos_[i] - secondsAgos_[0]));
        }
    }

    /**
     * Verify ticks slippages to avoid any manipulated liquidations. Compares prices with past few check points.
     * Calls getUniswapOracleTicksWithSecondsAgos() to fetch prices at different checkpoints.
     * Throws if the tick slippage is more for that particular check point.
     * @param pool_ Uniswap pool.
     * @return currentTick_ current tick of the pool.
     */
    function verifyTicksSlippage(IUniswapV3Pool pool_)
        internal
        view
        returns (int24 currentTick_)
    {
        (, currentTick_, , , , , ) = pool_.slot0();
        TickCheck memory tickCheck_ = _tickCheck[address(pool_)];
        uint32[] memory secondsAgos_ = new uint32[](6);
        secondsAgos_[0] = 0;
        secondsAgos_[1] = tickCheck_.secsAgo1;
        secondsAgos_[2] = tickCheck_.secsAgo2;
        secondsAgos_[3] = tickCheck_.secsAgo3;
        secondsAgos_[4] = tickCheck_.secsAgo4;
        secondsAgos_[5] = tickCheck_.secsAgo5;
        int56[] memory ticks_ = getUniswapOracleTicksWithSecondsAgos(
            pool_,
            secondsAgos_
        );
        uint56[] memory dif_ = new uint56[](5);
        for (uint256 i = 0; i < 5; i++) {
            dif_[i] = currentTick_ < ticks_[i]
                ? uint56(ticks_[i] - currentTick_)
                : uint56(currentTick_ - ticks_[i]);
        }
        require(dif_[0] < tickCheck_.tickSlippage1, "excess-tick-slippage1");
        require(dif_[1] < tickCheck_.tickSlippage2, "excess-tick-slippage2");
        require(dif_[2] < tickCheck_.tickSlippage3, "excess-tick-slippage3");
        require(dif_[3] < tickCheck_.tickSlippage4, "excess-tick-slippage4");
        require(dif_[4] < tickCheck_.tickSlippage5, "excess-tick-slippage5");
    }

    /**
     * Converts tick to current price. token0 price w.r.t token1.
     * @param tick_ current tick
     * @return price_ price at current tick. token0 price w.r.t token1.
     */
    function tickToPrice(int24 tick_) internal pure returns (uint256 price_) {
        // TODO: verify the price in proper decimals
        uint256 sqrtPriceX96_ = TickMath.getSqrtRatioAtTick(int24(tick_));
        return
            uint256(sqrtPriceX96_).mul(uint256(sqrtPriceX96_)).mul(1e18) >>
            (96 * 2);
    }

    /**
     * Compares Uniswap & Chainlink oracle price to avoid manipulated liquidations.
     * Throws if the chainlink price in not within Uniswap slippage limit.
     * @param pool_ Uniswap pool
     * @param uniswapOraclePrice_ current tick
     */
    function comparePrice(IUniswapV3Pool pool_, uint256 uniswapOraclePrice_)
        internal
        view
    {
        address base_ = pool_.token0();
        address quote_ = pool_.token1();
        uint256 oraclePrice_ = getOraclePrice(base_, quote_);
        // TODO: Verify in what decimals should price slippage be
        uint256 slippageLimits_ = uniswapOraclePrice_
            .mul(_priceSlippage[address(pool_)])
            .div(10000);
        require(
            uniswapOraclePrice_.sub(slippageLimits_) < oraclePrice_,
            "price-outside-of-range"
        );
        require(
            uniswapOraclePrice_.add(slippageLimits_) > oraclePrice_,
            "price-outside-of-range"
        );
    }

    /**
     * Verifies oracles & ticks by calling the above functions.
     * Liquidate() function calls this to verify oracles before liquidations.
     * @param poolAddr_ Uniswap pool address
     */
    function verifyOracles(address poolAddr_) internal view {
        IUniswapV3Pool pool_ = IUniswapV3Pool(poolAddr_);
        int24 currentTick_ = verifyTicksSlippage(pool_);
        uint256 uniswapOraclePrice_ = tickToPrice(currentTick_);
        comparePrice(pool_, uniswapOraclePrice_);
    }

    function tokenDecimals(address[] memory tokens_) internal view returns (uint[] memory decimals_) {
        uint length_ = tokens_.length;
        decimals_ = new uint[](length_);
        for (uint i = 0; i < length_; i++) {
            decimals_[i] = TokenInterface(tokens_[i]).decimals();
        }
    }

}

contract CoreReadHelpers is OraclesHelpers {
    using SafeMath for uint256;

    /**
     * returns fee accrued by an NFT.
     * @param poolAddr_ address of Uniswap pool.
     * @param tickLower_ Lower tick of the NFT.
     * @param tickUpper_ Upper tick of the NFT.
     * @param liquidity_ Liquidity of the NFT.
     * @param feeGrowthInside0LastX128_ Last updated fee0 of the NFT.
     * @param feeGrowthInside1LastX128_ Last updated fee1 of the NFT.
     * @param tokensOwed0_ existing token 0 owed to an NFT (from withdraw liquidity or collected fees but not yet claimed by the NFT owner)
     * @param tokensOwed1_ existing token 0 owed to an NFT (from withdraw liquidity or collected fees but not yet claimed by the NFT owner)
     * @return amount0_ actual collected amount 0.
     * @return amount1_ actual collected amount 1.
     */
    function getFeeAccrued(
        address poolAddr_,
        int24 tickLower_,
        int24 tickUpper_,
        uint128 liquidity_,
        uint256 feeGrowthInside0LastX128_,
        uint256 feeGrowthInside1LastX128_,
        uint128 tokensOwed0_, // TODO: @bajram what is this?
        uint128 tokensOwed1_ // TODO: @bajram what is this?
    ) internal view returns (uint256 amount0_, uint256 amount1_) {
        IUniswapV3Pool pool_ = IUniswapV3Pool(poolAddr_);

        (
            ,
            uint256 feeGrowthInside0LastX128Total_,
            uint256 feeGrowthInside1LastX128Total_,
            ,

        ) = pool_.positions(
                PositionKey.compute(nftManagerAddr, tickLower_, tickUpper_)
            );

        tokensOwed0_ += uint128(
            FullMath.mulDiv(
                feeGrowthInside0LastX128Total_ - feeGrowthInside0LastX128_,
                liquidity_,
                FixedPoint128.Q128
            )
        );
        tokensOwed1_ += uint128(
            FullMath.mulDiv(
                feeGrowthInside1LastX128Total_ - feeGrowthInside1LastX128_,
                liquidity_,
                FixedPoint128.Q128
            )
        );

        amount0_ = tokensOwed0_;
        amount1_ = tokensOwed1_;
    }

    function getFeeAccruedWrapper(uint256 NFTID_, address poolAddr_)
        public
        view
        returns (uint256 amount0_, uint256 amount1_)
    {
        Position memory position_;
        uint128 liquidity_;
        (
            ,
            ,
            ,
            ,
            ,
            position_.tickLower_,
            position_.tickUpper_,
            liquidity_,
            position_.feeGrowthInside0LastX128_,
            position_.feeGrowthInside1LastX128_,
            position_.tokensOwed0_,
            position_.tokensOwed1_
        ) = nftManager.positions(NFTID_);
        (amount0_, amount1_) = getFeeAccrued(
            poolAddr_,
            position_.tickLower_,
            position_.tickUpper_,
            liquidity_,
            position_.feeGrowthInside0LastX128_,
            position_.feeGrowthInside1LastX128_,
            position_.tokensOwed0_,
            position_.tokensOwed1_
        );
    }

    /**
     * returns liquidity of the NFT in amount0 & amount1 (just liquidity without fee).
     * @param poolAddr_ address of Uniswap pool.
     * @param tickLower_ Lower tick of the NFT.
     * @param tickUpper_ Upper tick of the NFT.
     * @param liquidity_ Liquidity of the NFT.
     * @return amount0Total_ total amount 0.
     * @return amount1Total_ total amount 1.
     */
    function getNetNFTLiquidity(
        address poolAddr_,
        int24 tickLower_,
        int24 tickUpper_,
        uint128 liquidity_
    ) public view returns (uint256 amount0Total_, uint256 amount1Total_) {
        IUniswapV3Pool pool_ = IUniswapV3Pool(poolAddr_);
        (uint160 sqrtPriceX96_, , , , , , ) = pool_.slot0();
        // active liquidity in NFT
        (uint256 amount0_, uint256 amount1_) = LiquidityAmounts
            .getAmountsForLiquidity(
                sqrtPriceX96_,
                TickMath.getSqrtRatioAtTick(tickLower_),
                TickMath.getSqrtRatioAtTick(tickUpper_),
                liquidity_
            );
        amount0Total_ = amount0_;
        amount1Total_ = amount1_;
    }

    /**
     * returns net borrow balances. Returns array of borrowed token amounts.
     * @param NFTID_ NFT ID.
     * @param poolAddr_ address of Uniswap pool.
     * @return borrowBalances_ array of borrowed tokens amounts.
     */
    function getNetNFTDebt(uint256 NFTID_, address poolAddr_)
        public
        view
        returns (uint256[] memory borrowBalances_)
    {
        address[] memory markets_ = _poolMarkets[poolAddr_];
        borrowBalances_ = new uint256[](markets_.length);
        for (uint256 i = 0; i < markets_.length; i++) {
            address token_ = markets_[i];
            uint256 borrowBalRaw_ = _borrowBalRaw[NFTID_][token_];
            if (borrowBalRaw_ >= 0) {
                (, uint256 exchangePrice_) = liquidity.updateInterest(token_);
                borrowBalances_[i] = borrowBalRaw_.mul(exchangePrice_).div(1e18);
            } else {
                borrowBalances_[i] = 0;
            }
        }
    }

    /**
     * Get supply in USD. Extended & Normal.
     * @param amount0_ total amount 0.
     * @param amount1_ total amount 1.
     * @param amount0Normal_ amount 0 normal. (token0Collateral > token0Debt ? token0Collateral - token0Debt : 0)
     * @param amount1Normal_ amount 1 normal. (token1Collateral > token1Debt ? token1Collateral - token1Debt : 0)
     * @param token0Price_ token 0 price in USD in 18 decimals.
     * @param token1Price_ token 1 price in USD in 18 decimals.
     * @param token0Decimal_ token 0 decimals.
     * @param token1Decimal_ token 1 decimals.
     * @return totalSupplyInUsd_ total supply in USD (amount0 in USD + amount1 in USD)
     * @return totalNormalSupplyInUsd_ total normal supply in USD (amount0 normal in USD + amount1 normal in USD)
     */
    function getSupplyInUsd(
        uint256 amount0_,
        uint256 amount1_,
        uint256 amount0Normal_,
        uint256 amount1Normal_,
        uint256 token0Price_,
        uint256 token1Price_,
        uint256 token0Decimal_,
        uint256 token1Decimal_
    )
        internal
        pure
        returns (uint256 totalSupplyInUsd_, uint256 totalNormalSupplyInUsd_)
    {
        uint256 amount0InUsd_ = amount0_.mul(token0Price_).div(
            10**token0Decimal_
        );
        uint256 amount1InUsd_ = amount1_.mul(token1Price_).div(
            10**token1Decimal_
        );
        uint256 amount0NormalInUsd_ = amount0Normal_.mul(token0Price_).div(
            10**token0Decimal_
        );
        uint256 amount1NormalInUsd_ = amount1Normal_.mul(token1Price_).div(
            10**token1Decimal_
        );
        totalSupplyInUsd_ = amount0InUsd_.add(amount1InUsd_);
        totalNormalSupplyInUsd_ = amount0NormalInUsd_.add(amount1NormalInUsd_);
    }

    /**
     * Get debt in USD. Extended & Normal.
     * @param borrowAmts_ array of debt tokens amount.
     * @param borrow0Normal_ normal borrow amount of token0. (token0Debt > token0Collateral ? token0Debt - token0Collateral : 0)
     * @param borrow1Normal_ normal borrow amount of token1. (token0Debt > token0Collateral ? token0Debt - token0Collateral : 0)
     * @param tokenPrices_ array of borrow tokens price.
     * @param tokenDecimals_ array of borrow tokens decimals.
     * @return totalDebtInUsd_ total debt in USD. (sum of all borrow tokens in USD)
     * @return totalNormalDebtInUsd_ total normal debt in USD. (sum of all borrow tokens in USD other than token0 & token1, take borrow0Normal_ & borrow1Normal_ in USD for token0 & token1)
     */
    function getDebtInUsd(
        uint256[] memory borrowAmts_,
        uint256 borrow0Normal_,
        uint256 borrow1Normal_,
        uint256[] memory tokenPrices_,
        uint[] memory tokenDecimals_
    )
        internal
        pure
        returns (uint256 totalDebtInUsd_, uint256 totalNormalDebtInUsd_)
    {
        for (uint256 i = 0; i < borrowAmts_.length; i++) {
            uint256 tokenDebtInUsd_ = borrowAmts_[i].mul(tokenPrices_[i]).div(
                10**tokenDecimals_[i]
            );
            totalDebtInUsd_ = totalDebtInUsd_.add(tokenDebtInUsd_);
            if (i == 0) {
                totalNormalDebtInUsd_ = totalNormalDebtInUsd_.add(
                    borrow0Normal_.mul(tokenPrices_[i]).div(
                        10**tokenDecimals_[i]
                    )
                );
            } else if (i == 1) {
                totalNormalDebtInUsd_ = totalNormalDebtInUsd_.add(
                    borrow1Normal_.mul(tokenPrices_[i]).div(
                        10**tokenDecimals_[i]
                    )
                );
            } else {
                totalNormalDebtInUsd_ = totalNormalDebtInUsd_.add(tokenDebtInUsd_);
            }
        }
    }

    struct GetOverallPosInternalsStruct {
        uint256 amount0Normal;
        uint256 amount1Normal;
        uint256 borrow0Normal;
        uint256 borrow1Normal;
    }

    /**
     * Get overall user's NFT debt position.
     * @param amount0_ token0 total amount (active liquidity and fee accrued)
     * @param amount1_ token1 total amount (active liquidity and fee accrued)
     * @param borrowBals_ array of borrow tokens amounts.
     * @param poolAddr_ address of pool.
     * @return totalSupplyInUsd_ total supply in USD (amount0 in USD + amount1 in USD)
     * @return totalNormalSupplyInUsd_ total normal supply in USD (amount0 normal in USD + amount1 normal in USD)
     * @return totalBorrowInUsd_ total debt in USD. (sum of all borrow tokens in USD)
     * @return totalNormalBorrowInUsd_ total normal debt in USD. (sum of all borrow tokens in USD other than token0 & token1, take borrow0Normal_ & borrow1Normal_ in USD for token0 & token1)
     */
    function _getOverallPosition(
        uint256 amount0_,
        uint256 amount1_,
        uint256[] memory borrowBals_,
        address poolAddr_
    )
        internal
        view
        returns (
            uint256 totalSupplyInUsd_,
            uint256 totalNormalSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalBorrowInUsd_
        )
    {
        GetOverallPosInternalsStruct memory internalStruct_;
        if (amount0_ > borrowBals_[0]) {
            internalStruct_.amount0Normal = amount0_ - borrowBals_[0];
        } else {
            internalStruct_.borrow0Normal = borrowBals_[0] - amount0_;
        }
        if (amount1_ > borrowBals_[1]) {
            internalStruct_.amount1Normal = amount1_ - borrowBals_[1];
        } else {
            internalStruct_.borrow1Normal = borrowBals_[1] - amount1_;
        }
        address[] memory markets_ = _poolMarkets[poolAddr_];
        uint256[] memory tokenPrices_ = getPricesInUsd(markets_);
        uint[] memory tokenDecimals_ = tokenDecimals(markets_);
        (totalSupplyInUsd_, totalNormalSupplyInUsd_) = getSupplyInUsd(
            amount0_,
            amount1_,
            internalStruct_.amount0Normal,
            internalStruct_.amount1Normal,
            tokenPrices_[0],
            tokenPrices_[1],
            tokenDecimals_[0],
            tokenDecimals_[1]
        );
        (totalBorrowInUsd_, totalNormalBorrowInUsd_) = getDebtInUsd(
            borrowBals_,
            internalStruct_.borrow0Normal,
            internalStruct_.borrow1Normal,
            tokenPrices_,
            tokenDecimals_
        );
    }

    /**
     * Get overall user's NFT debt position used by most of the core functions and calls all the above functions to calculate.
     * @param NFTID_ NFT ID.
     * @return poolAddr_ address of pool.
     * @return token0_ address of token0.
     * @return token1_ address of token1.
     * @return liquidity_ liquidity of NFT.
     * @return totalSupplyInUsd_ total supply in USD (amount0 in USD + amount1 in USD)
     * @return totalNormalSupplyInUsd_ total normal supply in USD (amount0 normal in USD + amount1 normal in USD)
     * @return totalBorrowInUsd_ total debt in USD. (sum of all borrow tokens in USD)
     * @return totalNormalBorrowInUsd_ total normal debt in USD. (sum of all borrow tokens in USD other than token0 & token1, take borrow0Normal_ & borrow1Normal_ in USD for token0 & token1)
     */
    function getOverallPosition(uint256 NFTID_)
        public
        view
        returns (
            address poolAddr_,
            address token0_,
            address token1_,
            uint128 liquidity_,
            uint256 totalSupplyInUsd_,
            uint256 totalNormalSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalBorrowInUsd_
        )
    {
        Position memory position_;
        (
            ,
            ,
            token0_,
            token1_,
            position_.fee_,
            position_.tickLower_,
            position_.tickUpper_,
            liquidity_,
            ,
            ,
            ,

        ) = nftManager.positions(NFTID_);
        poolAddr_ = getPoolAddress(token0_, token1_, position_.fee_);
        (position_.amount0_, position_.amount1_) = getNetNFTLiquidity(
            poolAddr_,
            position_.tickLower_,
            position_.tickUpper_,
            liquidity_
        );
        (position_.feeAccrued0_, position_.feeAccrued1_) = getFeeAccruedWrapper(
            NFTID_,
            poolAddr_
        );
        uint256[] memory borrowBals_ = getNetNFTDebt(NFTID_, poolAddr_);
        (
            totalSupplyInUsd_,
            totalNormalSupplyInUsd_,
            totalBorrowInUsd_,
            totalNormalBorrowInUsd_
        ) = _getOverallPosition(
            position_.amount0_.add(position_.feeAccrued0_),
            position_.amount1_.add(position_.feeAccrued1_),
            borrowBals_,
            poolAddr_
        );
    }

    /**
     * Checks if user has any debt.
     * @param NFTID_ NFT ID
     * @return has_ true if has any debt.
     */
    function hasDebt(uint256 NFTID_) internal view returns (bool has_) {
        (
            ,
            ,
            address token0_,
            address token1_,
            uint24 fee_,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = nftManager.positions(NFTID_);
        address pool_ = getPoolAddress(token0_, token1_, fee_);
        address[] memory markets_ = _poolMarkets[pool_];
        for (uint256 i = 0; i < markets_.length; i++) {
            has_ = _borrowBalRaw[NFTID_][markets_[i]] == 0 ? false : true;
            if (has_) break;
        }
    }

    /**
     * Liquidation check.
     * @param poolAddr_ pool address
     * @param totalSupplyInUsd_ total supply in USD (amount0 in USD + amount1 in USD)
     * @param totalNormalSupplyInUsd_ total normal supply in USD (amount0 normal in USD + amount1 normal in USD)
     * @param totalBorrowInUsd_ total debt in USD. (sum of all borrow tokens in USD)
     * @param totalNormalBorrowInUsd_ total normal debt in USD. (sum of all borrow tokens in USD other than token0 & token1, take borrow0Normal_ & borrow1Normal_ in USD for token0 & token1)
     * @return isOk_ true is not going to liquidate.
     */
    function liquidationCheck(
        address poolAddr_,
        uint256 totalSupplyInUsd_,
        uint256 totalBorrowInUsd_,
        uint256 totalNormalSupplyInUsd_,
        uint256 totalNormalBorrowInUsd_
    ) internal view returns (bool isOk_) {
        BorrowLimit memory borrowLimit_ = _borrowLimit[poolAddr_];
        isOk_ =
            totalBorrowInUsd_ <=
            totalSupplyInUsd_.mul(borrowLimit_.extended).div(10000) &&
            totalNormalBorrowInUsd_ <=
            totalNormalSupplyInUsd_.mul(borrowLimit_.normal).div(10000);
    }

}

contract Helpers is CoreReadHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * Gives approval of a token.
     * @param token_ token address
     * @param spender_ address which we need to approve
     * @param amount_ amount of approval
     */
    function approve(
        TokenInterface token_,
        address spender_,
        uint256 amount_
    ) internal {
        try token_.approve(spender_, amount_) {} catch {
            IERC20 tokenContract_ = IERC20(address(token_));
            tokenContract_.safeApprove(spender_, 0);
            tokenContract_.safeApprove(spender_, amount_);
        }
    }

    /**
     * Adds liquidity to an NFT.
     * @param NFTID_ NFT ID.
     * @param amount0_ amount0 to add.
     * @param amount1_ amount1 to add.
     * @param amount0Min_ amount0 minimum limit to add.
     * @param amount1Min_ amount1 minimum limit to add.
     * @param deadline_ deadline at which transaction should fail.
     * @return liquidity_ exact amount of liquidity added.
     * @return amount0Exact_ exact amount 0 added.
     * @return amount1Exact_ exact amount 1 added.
     */
    function _addLiquidity(
        uint256 NFTID_,
        uint256 amount0_,
        uint256 amount1_,
        uint256 amount0Min_,
        uint256 amount1Min_,
        uint256 deadline_
    )
        internal
        returns (
            uint128 liquidity_,
            uint256 amount0Exact_,
            uint256 amount1Exact_
        )
    {
        IncreaseLiquidityParams memory params_ = IncreaseLiquidityParams(
            NFTID_,
            amount0_,
            amount1_,
            amount0Min_,
            amount1Min_,
            deadline_
        );

        (liquidity_, amount0Exact_, amount1Exact_) = nftManager
            .increaseLiquidity(params_);
    }

    /**
     * remove Liquidity of an NFT
     * @param NFTID_ NFT ID.
     * @param liquidity_ liquidity to remove
     * @param amount0Min_ amount0 minimum limit.
     * @param amount1Min_ amount1 minimum limit.
     * @return amount0_ exact amount 0 removed.
     * @return amount1_ exact amount 1 removed.
     */
    function _decreaseLiquidity(
        uint256 NFTID_,
        uint256 liquidity_,
        uint256 amount0Min_,
        uint256 amount1Min_
    ) internal returns (uint256 amount0_, uint256 amount1_) {
        DecreaseLiquidityParams memory params_ = DecreaseLiquidityParams(
            NFTID_,
            uint128(liquidity_),
            amount0Min_,
            amount1Min_,
            block.timestamp
        );
        (amount0_, amount1_) = nftManager.decreaseLiquidity(params_);
    }

    /**
     * borrows a token. Only updates the storage, does not transfer borrow token to user.
     * @param NFTID_ NFT ID.
     * @param token_ token to borrow.
     * @param amount_ amount to borrow.
     */
    function _borrow(
        uint256 NFTID_,
        address token_,
        uint256 amount_
    ) internal {
        (, uint updateExchangePrice_) = liquidity.updateInterest(token_);
        uint256 amountRaw_ = amount_.mul(1e18).div(updateExchangePrice_);
        uint256 borrowBalRaw_ = _borrowBalRaw[NFTID_][token_];
        _borrowBalRaw[NFTID_][token_] = borrowBalRaw_.add(amountRaw_);
    }

    /**
     * payback debt on an NFT. type(uint).max for max payback.
     * @param NFTID_ NFT ID.
     * @param token_ token to payback.
     * @param amount_ amount to payback.
     * @return exactAmount_ exact amount payed back.
     */
    function _payback(
        uint256 NFTID_,
        address token_,
        uint256 amount_
    ) internal returns (uint256 exactAmount_) {
        (, uint updateExchangePrice_) = liquidity.updateInterest(token_);
        uint256 borrowBalRaw_ = _borrowBalRaw[NFTID_][token_];
        if (amount_ != type(uint256).max) {
            uint256 amountRaw_ = amount_
                .mul(1e18)
                .div(updateExchangePrice_);
            // throws is amountRaw_ is greater than borrowBalRaw_
            _borrowBalRaw[NFTID_][token_] = borrowBalRaw_.sub(amountRaw_);
            exactAmount_ = amount_;
        } else {
            exactAmount_ = borrowBalRaw_.mul(updateExchangePrice_).div(1e18);
            _borrowBalRaw[NFTID_][token_] = 0;
        }
    }

    /**
     * collect fees on an NFT
     * @param NFTID_ NFT ID.
     * @param amount0Max_ amount0 max to collect.
     * @param amount1Max_ amount1 max to collect.
     * @return amount0_ exact amount0 collected.
     * @return amount1_ exact amount1 collected.
     */
    function _collect(
        uint256 NFTID_,
        uint128 amount0Max_,
        uint128 amount1Max_
    ) internal returns (uint256 amount0_, uint256 amount1_) {
        CollectParams memory params_ = CollectParams(
            NFTID_,
            msg.sender,
            amount0Max_,
            amount1Max_
        );
        (amount0_, amount1_) = nftManager.collect(params_);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

pragma solidity ^0.8.0;


import "../../common/ILiquidity.sol";

contract Variables {

    // status for re-entrancy. 1 = allow/non-entered, 2 = disallow/entered
    uint256 internal _status;

    ILiquidity constant internal liquidity = ILiquidity(address(0xAFA64764FE83E6796df18De44b739074D68Fd715)); // TODO: add the core liquidity address

    // pool => bool. To enable a pool
    mapping (address => bool) internal poolEnabled_;

    // owner => NFT ID => borrow Position details
    mapping (address => mapping (uint => bool)) internal _position;

    // NFT ID => staked Position details
    mapping (uint => bool) internal _isStaked;

    // rewards accrued at the time of unstaking. NFTID -> token address -> reward amount
    mapping (uint => mapping(address => uint)) internal _rewardAccrued;

    // pool => minimum tick. Minimum tick difference a position should have to deposit (upperTick - lowerTick)
    mapping (address => uint) internal _minTick;

    // NFT ID => token => uint
    mapping (uint => mapping (address => uint)) internal _borrowBalRaw;

    // pool => token => bool
    mapping (address => mapping (address => bool)) internal _borrowAllowed;

    // pool => array or tokens. Market of borrow tokens for particular pool.
    // first 2 markets are always token0 & token1
    mapping(address => address[]) internal _poolMarkets;

    // normal. 8500 = 0.85.
    // extended. 9500 = 0.95.
    // extended meaning max totalborrow/totalsupply ratio
    // normal meaning canceling the same token borrow & supply and calculate ratio from rest of the token meaining
    // if NFT has 1 ETH & 4000 USDC (at 1 ETH = 4000 USDC) and debt of 0.5 ETH & 5000 USDC then the ratio would be
    // extended = (2000 + 5000) / (4000 + 4000) = 7/8
    // normal = (0 + 1000) / (2000) = 1/2
    struct BorrowLimit {
        uint128 normal;
        uint128 extended;
    }

    // pool address => Borrow limit
    mapping (address => BorrowLimit) internal _borrowLimit;

    // pool => _priceSlippage
    // 1 = 0.01%. 10000 = 100%
    // used to check Uniswap and chainlink price
    mapping (address => uint) internal _priceSlippage;

    // Tick checkpoints
    // 5 checkpoints Eg:-
    // Past 10 sec.
    // Past 30 sec.
    // Past 60 sec.
    // Past 120 sec.
    // Past 300 sec.
    struct TickCheck {
        uint24 tickSlippage1;
        uint24 secsAgo1;
        uint24 tickSlippage2;
        uint24 secsAgo2;
        uint24 tickSlippage3;
        uint24 secsAgo3;
        uint24 tickSlippage4;
        uint24 secsAgo4;
        uint24 tickSlippage5;
        uint24 secsAgo5;
    }

    // pool => TickCheck
    mapping (address => TickCheck) internal _tickCheck;

    // token => oracle contract. Price in USD.
    mapping (address => address) internal _chainlinkOracle;

}

pragma solidity ^0.8.0;


contract Events {

    event depositLog(address owner_, uint256 NFTID_);

    event withdrawLog(uint96 NFTID_);

    event addLiquidityLog(
        uint96 NFTID_,
        uint256 exactAmount0_,
        uint256 exactAmount1_,
        uint256 deadline_
    );

    event removeLiquidityLog(
        uint96 NFTID_,
        uint256 exactAmount0_,
        uint256 exactAmount1_
    );

    event borrowLog(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    );

    event paybackLog(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    );

    event collectFeeLog(
        uint96 NFTID_,
        uint256 amount0_,
        uint256 amount1_
    );

    event liquidateLog(
        uint96 NFTID_,
        uint exactAmount0_,
        uint exactAmount1_,
        address[] markets_,
        uint[] paybackAmts_
    );

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
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
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

pragma solidity >=0.5.0;
import "./FullMath.sol";
import "./FixedPoint96.sol";
library LiquidityAmounts {
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

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

    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

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

pragma solidity >=0.5.0;

library PositionKey {
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol';

interface TokenInterface {
    function approve(address, uint256) external;

    function decimals() external view returns (uint256);
}

interface INonfungiblePositionManager {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function factory() external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function token0() external view returns (address);

    function token1() external view returns (address);

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

/// @title Uniswap V3 Staker Interface
/// @notice Allows staking nonfungible liquidity tokens in exchange for reward tokens
interface IUniswapV3Staker is IERC721Receiver, IMulticall {
    /// @param rewardToken The token being distributed as a reward
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param refundee The address which receives any remaining reward tokens when the incentive is ended
    struct IncentiveKey {
        IERC20Minimal rewardToken;
        IUniswapV3Pool pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    /// @notice The nonfungible position manager with which this staking contract is compatible
    function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

    /// @notice Represents a staking incentive
    /// @param incentiveId The ID of the incentive computed from its parameters
    /// @return totalRewardUnclaimed The amount of reward token not yet claimed by users
    /// @return totalSecondsClaimedX128 Total liquidity-seconds claimed, represented as a UQ32.128
    /// @return numberOfStakes The count of deposits that are currently staked for the incentive
    function incentives(bytes32 incentiveId)
        external
        view
        returns (
            uint256 totalRewardUnclaimed,
            uint160 totalSecondsClaimedX128,
            uint96 numberOfStakes
        );

    /// @notice Returns information about a deposited NFT
    /// @return owner The owner of the deposited NFT
    /// @return numberOfStakes Counter of how many incentives for which the liquidity is staked
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function deposits(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint48 numberOfStakes,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Returns information about a staked liquidity NFT
    /// @param tokenId The ID of the staked token
    /// @param incentiveId The ID of the incentive for which the token is staked
    /// @return secondsPerLiquidityInsideInitialX128 secondsPerLiquidity represented as a UQ32.128
    /// @return liquidity The amount of liquidity in the NFT as of the last time the rewards were computed
    function stakes(uint256 tokenId, bytes32 incentiveId)
        external
        view
        returns (uint160 secondsPerLiquidityInsideInitialX128, uint128 liquidity);

    /// @notice Returns amounts of reward tokens owed to a given address according to the last time all stakes were updated
    /// @param rewardToken The token for which to check rewards
    /// @param owner The owner for which the rewards owed are checked
    /// @return rewardsOwed The amount of the reward token claimable by the owner
    function rewards(IERC20Minimal rewardToken, address owner) external view returns (uint256 rewardsOwed);

    /// @notice Creates a new liquidity mining incentive program
    /// @param key Details of the incentive to create
    /// @param reward The amount of reward tokens to be distributed
    function createIncentive(IncentiveKey memory key, uint256 reward) external;

    /// @notice Ends an incentive after the incentive end time has passed and all stakes have been withdrawn
    /// @param key Details of the incentive to end
    /// @return refund The remaining reward tokens when the incentive is ended
    function endIncentive(IncentiveKey memory key) external returns (uint256 refund);

    /// @notice Withdraws a Uniswap V3 LP token `tokenId` from this contract to the recipient `to`
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param to The address where the LP token will be sent
    /// @param data An optional data array that will be passed along to the `to` address via the NFT safeTransferFrom
    function withdrawToken(
        uint256 tokenId,
        address to,
        bytes memory data
    ) external;

    /// @notice Stakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to stake the NFT
    /// @param tokenId The ID of the token to stake
    function stakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Unstakes a Uniswap V3 LP token
    /// @param key The key of the incentive for which to unstake the NFT
    /// @param tokenId The ID of the token to unstake
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external;

    /// @notice Transfers `amountRequested` of accrued `rewardToken` rewards from the contract to the recipient `to`
    /// @param rewardToken The token being distributed as a reward
    /// @param to The address where claimed rewards will be sent to
    /// @param amountRequested The amount of reward tokens to claim. Claims entire reward amount if set to 0.
    /// @return reward The amount of reward tokens claimed
    function claimReward(
        IERC20Minimal rewardToken,
        address to,
        uint256 amountRequested
    ) external returns (uint256 reward);

}

struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
}

interface ChainLinkOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function totalSupplyRaw(address token_) external view returns (uint256);

    function totalBorrowRaw(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}