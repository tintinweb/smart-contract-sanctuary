// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
//import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
//import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

//import "../interfaces/IStakeRegistry.sol";
import "../interfaces/IStakeUniswapV3.sol";
import "../interfaces/IAutoRefactorCoinageWithTokenId.sol";
import "../interfaces/IIStake2Vault.sol";
import {DSMath} from "../libraries/DSMath.sol";
import "../common/AccessibleCommon.sol";
import "../stake/StakeUniswapV3Storage.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/SafeMath32.sol";

/// @title StakeUniswapV3
/// @notice Uniswap V3 Contract for staking LP and mining TOS
contract StakeUniswapV3 is
    StakeUniswapV3Storage,
    AccessibleCommon,
    IStakeUniswapV3,
    DSMath
{
    using SafeMath for uint256;
    using SafeMath32 for uint32;

    struct PositionInfo {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

    /// @dev event on staking
    /// @param to the sender
    /// @param poolAddress the pool address of uniswapV3
    /// @param tokenId the uniswapV3 Lp token
    /// @param amount the amount of staking
    event Staked(
        address indexed to,
        address indexed poolAddress,
        uint256 tokenId,
        uint256 amount
    );

    /// @dev event on claim
    /// @param to the sender
    /// @param poolAddress the pool address of uniswapV3
    /// @param tokenId the uniswapV3 Lp token
    /// @param miningAmount the amount of mining
    /// @param nonMiningAmount the amount of non-mining
    event Claimed(
        address indexed to,
        address poolAddress,
        uint256 tokenId,
        uint256 miningAmount,
        uint256 nonMiningAmount
    );

    /// @dev event on withdrawal
    /// @param to the sender
    /// @param tokenId the uniswapV3 Lp token
    /// @param miningAmount the amount of mining
    /// @param nonMiningAmount the amount of non-mining
    event WithdrawalToken(
        address indexed to,
        uint256 tokenId,
        uint256 miningAmount,
        uint256 nonMiningAmount
    );

    /// @dev event on mining in coinage
    /// @param curTime the current time
    /// @param miningInterval mining period (sec)
    /// @param miningAmount the mining amount
    /// @param prevTotalSupply Total amount of coinage before mining
    /// @param afterTotalSupply Total amount of coinage after being mined
    /// @param factor coinage's Factor
    event MinedCoinage(
        uint256 curTime,
        uint256 miningInterval,
        uint256 miningAmount,
        uint256 prevTotalSupply,
        uint256 afterTotalSupply,
        uint256 factor
    );

    /// @dev event on burning in coinage
    /// @param curTime the current time
    /// @param tokenId the token id
    /// @param burningAmount the buring amount
    /// @param prevTotalSupply Total amount of coinage before mining
    /// @param afterTotalSupply Total amount of coinage after being mined
    event BurnedCoinage(
        uint256 curTime,
        uint256 tokenId,
        uint256 burningAmount,
        uint256 prevTotalSupply,
        uint256 afterTotalSupply
    );

    /// @dev constructor of StakeCoinage
    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);

        miningIntervalSeconds = 15;
    }

    /// @dev receive ether - revert
    receive() external payable {
        revert();
    }

    /// @dev Mining interval setting (seconds)
    /// @param _intervalSeconds the mining interval (sec)
    function setMiningIntervalSeconds(uint256 _intervalSeconds)
        external
        onlyOwner
    {
        miningIntervalSeconds = _intervalSeconds;
    }

    /// @dev reset coinage's last mining time variable for tes
    function resetCoinageTime() external onlyOwner {
        coinageLastMintBlockTimetamp = 0;
    }

    /// @dev set sale start time
    /// @param _saleStartTime sale start time
    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        require(
            _saleStartTime > 0 && saleStartTime != _saleStartTime,
            "StakeUniswapV3: zero or same _saleStartTime"
        );
        saleStartTime = _saleStartTime;
    }

    /// @dev calculate the factor of coinage
    /// @param source tsource
    /// @param target target
    /// @param oldFactor oldFactor
    function _calcNewFactor(
        uint256 source,
        uint256 target,
        uint256 oldFactor
    ) internal pure returns (uint256) {
        return rdiv(rmul(target, oldFactor), source);
    }

    /// @dev delete user's token storage of index place
    /// @param _owner tokenId's owner
    /// @param tokenId tokenId
    /// @param _index owner's tokenId's index
    function deleteUserToken(
        address _owner,
        uint256 tokenId,
        uint256 _index
    ) internal {
        uint256 _tokenid = userStakedTokenIds[_owner][_index];
        require(_tokenid == tokenId, "StakeUniswapV3: mismatch token");
        uint256 lastIndex = (userStakedTokenIds[_owner].length).sub(1);
        if (tokenId > 0 && _tokenid == tokenId) {
            if (_index < lastIndex) {
                uint256 tokenId_lastIndex =
                    userStakedTokenIds[_owner][lastIndex];
                userStakedTokenIds[_owner][_index] = tokenId_lastIndex;
                depositTokens[tokenId_lastIndex].idIndex = _index;
            }
            userStakedTokenIds[_owner].pop();
        }
    }

    /// @dev mining on coinage, Mining conditions :  the sale start time must pass,
    /// the stake start time must pass, the vault mining start time (sale start time) passes,
    /// the mining interval passes, and the current total amount is not zero,
    function miningCoinage() public lock {
        if (saleStartTime == 0 || saleStartTime > block.timestamp) return;
        if (stakeStartTime == 0 || stakeStartTime > block.timestamp) return;
        if (
            IIStake2Vault(vault).miningStartTime() > block.timestamp ||
            IIStake2Vault(vault).miningEndTime() < block.timestamp
        ) return;

        if (coinageLastMintBlockTimetamp == 0)
            coinageLastMintBlockTimetamp = stakeStartTime;

        if (
            block.timestamp >
            (coinageLastMintBlockTimetamp.add(miningIntervalSeconds))
        ) {
            uint256 miningInterval =
                block.timestamp.sub(coinageLastMintBlockTimetamp);
            uint256 miningAmount =
                miningInterval.mul(IIStake2Vault(vault).miningPerSecond());
            uint256 prevTotalSupply =
                IAutoRefactorCoinageWithTokenId(coinage).totalSupply();

            if (miningAmount > 0 && prevTotalSupply > 0) {
                uint256 afterTotalSupply =
                    prevTotalSupply.add(miningAmount.mul(10**9));
                uint256 factor =
                    IAutoRefactorCoinageWithTokenId(coinage).setFactor(
                        _calcNewFactor(
                            prevTotalSupply,
                            afterTotalSupply,
                            IAutoRefactorCoinageWithTokenId(coinage).factor()
                        )
                    );
                coinageLastMintBlockTimetamp = block.timestamp;

                emit MinedCoinage(
                    block.timestamp,
                    miningInterval,
                    miningAmount,
                    prevTotalSupply,
                    afterTotalSupply,
                    factor
                );
            }
        }
    }

    /// @dev view mining information of tokenId
    /// @param tokenId  tokenId
    function getMiningTokenId(uint256 tokenId)
        public
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint160 secondsInside,
            uint256 secondsInsideDiff256,
            uint256 liquidity,
            uint256 balanceOfTokenIdRay,
            uint256 minableAmountRay,
            uint256 secondsInside256,
            uint256 secondsAbsolute256
        )
    {
        if (
            stakeStartTime < block.timestamp && stakeStartTime < block.timestamp
        ) {
            LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
                depositTokens[tokenId];
            liquidity = _depositTokens.liquidity;

            uint32 secondsAbsolute = 0;
            balanceOfTokenIdRay = IAutoRefactorCoinageWithTokenId(coinage)
                .balanceOf(tokenId);

            if (_depositTokens.liquidity > 0 && balanceOfTokenIdRay > 0) {
                if (balanceOfTokenIdRay > liquidity.mul(10**9)) {
                    minableAmountRay = balanceOfTokenIdRay.sub(
                        liquidity.mul(10**9)
                    );
                    minableAmount = minableAmountRay.div(10**9);
                }
                if (minableAmount > 0) {
                    (, , secondsInside) = IUniswapV3Pool(poolAddress)
                        .snapshotCumulativesInside(
                        _depositTokens.tickLower,
                        _depositTokens.tickUpper
                    );
                    secondsInside256 = uint256(secondsInside);

                    if (_depositTokens.claimedTime > 0)
                        secondsAbsolute = uint32(block.timestamp).sub(
                            _depositTokens.claimedTime
                        );
                    else
                        secondsAbsolute = uint32(block.timestamp).sub(
                            _depositTokens.startTime
                        );
                    secondsAbsolute256 = uint256(secondsAbsolute);

                    if (secondsAbsolute > 0) {
                        if (_depositTokens.secondsInsideLast > 0) {
                            secondsInsideDiff256 = secondsInside256.sub(
                                uint256(_depositTokens.secondsInsideLast)
                            );
                        } else {
                            secondsInsideDiff256 = secondsInside256.sub(
                                uint256(_depositTokens.secondsInsideInitial)
                            );
                        }

                        if (
                            secondsInsideDiff256 < secondsAbsolute256 &&
                            secondsInsideDiff256 > 0
                        ) {
                            miningAmount = minableAmount
                                .mul(secondsInsideDiff256)
                                .div(secondsAbsolute256);
                            nonMiningAmount = minableAmount.sub(miningAmount);
                        } else if(secondsInsideDiff256 > 0){
                            miningAmount = minableAmount;
                        } else {
                            nonMiningAmount = minableAmount;
                        }
                    }
                }
            }
        }
    }

    /// @dev With the given tokenId, information is retrieved from nonfungiblePositionManager,
    ///      and the pool address is calculated and set.
    /// @param tokenId  tokenId
    function setPoolAddress(uint256 tokenId)
        external
        onlyOwner
        nonZeroAddress(token)
        nonZeroAddress(vault)
        nonZeroAddress(stakeRegistry)
        nonZeroAddress(poolToken0)
        nonZeroAddress(poolToken1)
        nonZeroAddress(address(nonfungiblePositionManager))
        nonZeroAddress(uniswapV3FactoryAddress)
    {
        require(poolAddress == address(0), "StakeUniswapV3: already set");
        (, , address token0, address token1, uint24 fee, , , , , , , ) =
            nonfungiblePositionManager.positions(tokenId);

        require(
            (token0 == poolToken0 && token1 == poolToken1) ||
                (token0 == poolToken1 && token1 == poolToken0),
            "StakeUniswapV3: different token"
        );
        poolToken0 = token0;
        poolToken1 = token1;

        poolAddress = PoolAddress.computeAddress(
            uniswapV3FactoryAddress,
            PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
        );
        poolFee = fee;
    }

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    /// @param deadline the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function stakePermit(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        nonZeroAddress(token)
        nonZeroAddress(vault)
        nonZeroAddress(stakeRegistry)
        nonZeroAddress(poolToken0)
        nonZeroAddress(poolToken1)
        nonZeroAddress(address(nonfungiblePositionManager))
        nonZeroAddress(uniswapV3FactoryAddress)
    {
        require(
            saleStartTime < block.timestamp,
            "StakeUniswapV3: before start"
        );

        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3: end mining"
        );

        require(
            nonfungiblePositionManager.ownerOf(tokenId) == msg.sender,
            "StakeUniswapV3: not owner"
        );

        nonfungiblePositionManager.permit(
            address(this),
            tokenId,
            deadline,
            v,
            r,
            s
        );

        _stake(tokenId);
    }

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    function stake(uint256 tokenId)
        external
        override
        nonZeroAddress(token)
        nonZeroAddress(vault)
        nonZeroAddress(stakeRegistry)
        nonZeroAddress(poolToken0)
        nonZeroAddress(poolToken1)
        nonZeroAddress(address(nonfungiblePositionManager))
        nonZeroAddress(uniswapV3FactoryAddress)
    {
        require(
            saleStartTime < block.timestamp,
            "StakeUniswapV3: before start"
        );
        require(
            block.timestamp < IIStake2Vault(vault).miningEndTime(),
            "StakeUniswapV3: end mining"
        );
        require(
            nonfungiblePositionManager.ownerOf(tokenId) == msg.sender,
            "StakeUniswapV3: not owner"
        );

        _stake(tokenId);
    }

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    function _stake(uint256 tokenId) internal {
        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];

        require(
            _depositTokens.owner == address(0),
            "StakeUniswapV3: Already staked"
        );

        uint256 _tokenId = tokenId;
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);

        require(
            (token0 == poolToken0 && token1 == poolToken1) ||
                (token0 == poolToken1 && token1 == poolToken0),
            "StakeUniswapV3: different token"
        );

        require(liquidity > 0, "StakeUniswapV3: zero liquidity");

        if (poolAddress == address(0)) {
            poolAddress = PoolAddress.computeAddress(
                uniswapV3FactoryAddress,
                PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
            );
        }

        require(poolAddress != address(0), "StakeUniswapV3: zero poolAddress");

        (, int24 tick, , , , , bool unlocked) =
            IUniswapV3Pool(poolAddress).slot0();
        require(unlocked, "StakeUniswapV3: unlocked pool");
        require(
            tickLower < tick && tick < tickUpper,
            "StakeUniswapV3: out of tick range"
        );

        (, , uint32 secondsInside) =
            IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
                tickLower,
                tickUpper
            );

        uint256 tokenId_ = _tokenId;

        // initial start time
        if (stakeStartTime == 0) stakeStartTime = block.timestamp;

        _depositTokens.owner = msg.sender;
        _depositTokens.idIndex = userStakedTokenIds[msg.sender].length;
        _depositTokens.liquidity = liquidity;
        _depositTokens.tickLower = tickLower;
        _depositTokens.tickUpper = tickUpper;
        _depositTokens.startTime = uint32(block.timestamp);
        _depositTokens.claimedTime = 0;
        _depositTokens.secondsInsideInitial = secondsInside;
        _depositTokens.secondsInsideLast = 0;

        nonfungiblePositionManager.transferFrom(
            msg.sender,
            address(this),
            tokenId_
        );

        // save tokenid
        userStakedTokenIds[msg.sender].push(tokenId_);

        totalStakedAmount = totalStakedAmount.add(liquidity);
        totalTokens = totalTokens.add(1);

        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        if (!_userTotalStaked.staked) totalStakers = totalStakers.add(1);
        _userTotalStaked.staked = true;
        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .add(liquidity);

        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId_];
        _stakedCoinageTokens.amount = liquidity;
        _stakedCoinageTokens.startTime = uint32(block.timestamp);

        //mint coinage of user amount
        IAutoRefactorCoinageWithTokenId(coinage).mint(
            msg.sender,
            tokenId_,
            uint256(liquidity).mul(10**9)
        );

        miningCoinage();

        emit Staked(msg.sender, poolAddress, tokenId_, liquidity);
    }

    /// @dev The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///       has been provided since recent mining
    /// @param tokenId  tokenId
    function claim(uint256 tokenId) external override {
        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];

        require(
            _depositTokens.owner == msg.sender,
            "StakeUniswapV3: not staker"
        );

        require(
            _depositTokens.claimedTime <
                uint32(block.timestamp.sub(miningIntervalSeconds)),
            "StakeUniswapV3: already claimed"
        );

        require(_depositTokens.claimLock == false, "StakeUniswapV3: claiming");
        _depositTokens.claimLock = true;

        miningCoinage();

        (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint160 secondsInside,
            ,
            ,
            ,
            uint256 minableAmountRay,
            ,

        ) = getMiningTokenId(tokenId);

        require(miningAmount > 0, "StakeUniswapV3: zero miningAmount");

        _depositTokens.claimedTime = uint32(block.timestamp);
        _depositTokens.secondsInsideLast = secondsInside;

        IAutoRefactorCoinageWithTokenId(coinage).burn(
            msg.sender,
            tokenId,
            minableAmountRay
        );

        // storage  stakedCoinageTokens
        LibUniswapV3Stake.StakedTokenAmount storage _stakedCoinageTokens =
            stakedCoinageTokens[tokenId];
        _stakedCoinageTokens.claimedTime = uint32(block.timestamp);
        _stakedCoinageTokens.claimedAmount = _stakedCoinageTokens
            .claimedAmount
            .add(miningAmount);
        _stakedCoinageTokens.nonMiningAmount = _stakedCoinageTokens
            .nonMiningAmount
            .add(nonMiningAmount);

        // storage  StakedTotalTokenAmount
        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        _userTotalStaked.totalMiningAmount = _userTotalStaked
            .totalMiningAmount
            .add(miningAmount);
        _userTotalStaked.totalNonMiningAmount = _userTotalStaked
            .totalNonMiningAmount
            .add(nonMiningAmount);

        // total
        miningAmountTotal = miningAmountTotal.add(miningAmount);
        nonMiningAmountTotal = nonMiningAmountTotal.add(nonMiningAmount);

        require(
            IIStake2Vault(vault).claimMining(
                msg.sender,
                minableAmount,
                miningAmount,
                nonMiningAmount
            )
        );

        _depositTokens.claimLock = false;
        emit Claimed(
            msg.sender,
            poolAddress,
            tokenId,
            miningAmount,
            nonMiningAmount
        );
    }

    /// @dev withdraw the deposited token.
    ///      The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///      has been provided since recent mining
    /// @param tokenId  tokenId
    function withdraw(uint256 tokenId) external override {
        LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
            depositTokens[tokenId];
        require(
            _depositTokens.owner == msg.sender,
            "StakeUniswapV3: not staker"
        );

        require(
            _depositTokens.withdraw == false,
            "StakeUniswapV3: withdrawing"
        );
        _depositTokens.withdraw = true;

        miningCoinage();

        if (totalStakedAmount >= _depositTokens.liquidity)
            totalStakedAmount = totalStakedAmount.sub(_depositTokens.liquidity);

        if (totalTokens > 0) totalTokens = totalTokens.sub(1);

        (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = getMiningTokenId(tokenId);

        IAutoRefactorCoinageWithTokenId(coinage).burnTokenId(
            msg.sender,
            tokenId
        );

        // storage  StakedTotalTokenAmount
        LibUniswapV3Stake.StakedTotalTokenAmount storage _userTotalStaked =
            userTotalStaked[msg.sender];
        _userTotalStaked.totalDepositAmount = _userTotalStaked
            .totalDepositAmount
            .sub(_depositTokens.liquidity);
        _userTotalStaked.totalMiningAmount = _userTotalStaked
            .totalMiningAmount
            .add(miningAmount);
        _userTotalStaked.totalNonMiningAmount = _userTotalStaked
            .totalNonMiningAmount
            .add(nonMiningAmount);

        // total
        miningAmountTotal = miningAmountTotal.add(miningAmount);
        nonMiningAmountTotal = nonMiningAmountTotal.add(nonMiningAmount);

        deleteUserToken(_depositTokens.owner, tokenId, _depositTokens.idIndex);

        delete depositTokens[tokenId];
        delete stakedCoinageTokens[tokenId];

        if (_userTotalStaked.totalDepositAmount == 0) {
            totalStakers = totalStakers.sub(1);
            delete userTotalStaked[msg.sender];
        }

        if (minableAmount > 0)
            require(
                IIStake2Vault(vault).claimMining(
                    msg.sender,
                    minableAmount,
                    miningAmount,
                    nonMiningAmount
                )
            );

        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit WithdrawalToken(
            msg.sender,
            tokenId,
            miningAmount,
            nonMiningAmount
        );
    }

    /// @dev Get the list of staked tokens of the user
    /// @param user  user address
    function getUserStakedTokenIds(address user)
        external
        view
        override
        returns (uint256[] memory ids)
    {
        return userStakedTokenIds[user];
    }

    /// @dev tokenId's deposited information
    /// @param tokenId   tokenId
    /// @return _poolAddress   poolAddress
    /// @return tick tick,
    /// @return liquidity liquidity,
    /// @return args liquidity,  startTime, claimedTime, startBlock, claimedBlock, claimedAmount
    /// @return secondsPL secondsPerLiquidityInsideInitialX128, secondsPerLiquidityInsideX128Las
    function getDepositToken(uint256 tokenId)
        external
        view
        override
        returns (
            address _poolAddress,
            int24[2] memory tick,
            uint128 liquidity,
            uint256[5] memory args,
            uint160[2] memory secondsPL
        )
    {
        LibUniswapV3Stake.StakeLiquidity memory _depositTokens =
            depositTokens[tokenId];
        LibUniswapV3Stake.StakedTokenAmount memory _stakedCoinageTokens =
            stakedCoinageTokens[tokenId];

        return (
            poolAddress,
            [_depositTokens.tickLower, _depositTokens.tickUpper],
            _depositTokens.liquidity,
            [
                _depositTokens.startTime,
                _depositTokens.claimedTime,
                _stakedCoinageTokens.startTime,
                _stakedCoinageTokens.claimedTime,
                _stakedCoinageTokens.claimedAmount
            ],
            [
                _depositTokens.secondsInsideInitial,
                _depositTokens.secondsInsideLast
            ]
        );
    }

    /// @dev user's staked total infos
    /// @param user  user address
    /// @return totalDepositAmount  total deposited amount
    /// @return totalMiningAmount total mining amount ,
    /// @return totalNonMiningAmount total non-mining amount,
    function getUserStakedTotal(address user)
        external
        view
        override
        returns (
            uint256 totalDepositAmount,
            uint256 totalMiningAmount,
            uint256 totalNonMiningAmount
        )
    {
        return (
            userTotalStaked[user].totalDepositAmount,
            userTotalStaked[user].totalMiningAmount,
            userTotalStaked[user].totalNonMiningAmount
        );
    }

    /// @dev totalSupply of coinage
    function totalSupplyCoinage() external view returns (uint256) {
        return IAutoRefactorCoinageWithTokenId(coinage).totalSupply();
    }

    /// @dev balanceOf of tokenId's coinage
    function balanceOfCoinage(uint256 tokenId) external view returns (uint256) {
        return IAutoRefactorCoinageWithTokenId(coinage).balanceOf(tokenId);
    }

    /// @dev Give the infomation of this stakeContracts
    /// @return return1  [token, vault, stakeRegistry, coinage]
    /// @return return2  [poolToken0, poolToken1, nonfungiblePositionManager, uniswapV3FactoryAddress]
    /// @return return3  [totalStakers, totalStakedAmount, miningAmountTotal,nonMiningAmountTotal]
    function infos()
        external
        view
        override
        returns (
            address[4] memory,
            address[4] memory,
            uint256[4] memory
        )
    {
        return (
            [token, vault, stakeRegistry, coinage],
            [
                poolToken0,
                poolToken1,
                address(nonfungiblePositionManager),
                uniswapV3FactoryAddress
            ],
            [
                totalStakers,
                totalStakedAmount,
                miningAmountTotal,
                nonMiningAmountTotal
            ]
        );
    }

    /*
    /// @dev pool's infos
    /// @return factory  pool's factory address
    /// @return token0  token0 address
    /// @return token1  token1 address
    /// @return fee  fee
    /// @return tickSpacing  tickSpacing
    /// @return maxLiquidityPerTick  maxLiquidityPerTick
    /// @return liquidity  pool's liquidity
    function poolInfos()
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing,
            uint128 maxLiquidityPerTick,
            uint128 liquidity
        )
    {
        liquidity = IUniswapV3Pool(poolAddress).liquidity();
        factory = IUniswapV3Pool(poolAddress).factory();
        token0 = IUniswapV3Pool(poolAddress).token0();
        token1 = IUniswapV3Pool(poolAddress).token1();
        fee = IUniswapV3Pool(poolAddress).fee();
        tickSpacing = IUniswapV3Pool(poolAddress).tickSpacing();
        maxLiquidityPerTick = IUniswapV3Pool(poolAddress).maxLiquidityPerTick();
    }
    */
    /*
    /// @dev key's info
    /// @param key hash(owner, tickLower, tickUpper)
    /// @return _liquidity  key's liquidity
    /// @return feeGrowthInside0LastX128  key's feeGrowthInside0LastX128
    /// @return feeGrowthInside1LastX128  key's feeGrowthInside1LastX128
    /// @return tokensOwed0  key's tokensOwed0
    /// @return tokensOwed1  key's tokensOwed1
    function poolPositions(bytes32 key)
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (
            _liquidity,
            feeGrowthInside0LastX128,
            feeGrowthInside1LastX128,
            tokensOwed0,
            tokensOwed1
        ) = IUniswapV3Pool(poolAddress).positions(key);
    }
    */

    /// @dev pool's slot0 (current position)
    /// @return sqrtPriceX96  The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick  The current tick of the pool
    /// @return observationIndex  The index of the last oracle observation that was written,
    /// @return observationCardinality  The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext  The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol  The protocol fee for both tokens of the pool
    /// @return unlocked  Whether the pool is currently locked to reentrancy
    function poolSlot0()
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        (
            sqrtPriceX96,
            tick,
            observationIndex,
            observationCardinality,
            observationCardinalityNext,
            feeProtocol,
            unlocked
        ) = IUniswapV3Pool(poolAddress).slot0();
    }

    /*
    /// @dev _tokenId's position
    /// @param _tokenId  tokenId
    /// @return nonce  the nonce for permits
    /// @return operator  the address that is approved for spending this token
    /// @return token0  The address of the token0 for pool
    /// @return token1  The address of the token1 for pool
    /// @return fee  The fee associated with the pool
    /// @return tickLower  The lower end of the tick range for the position
    /// @return tickUpper  The higher end of the tick range for the position
    /// @return liquidity  The liquidity of the position
    /// @return feeGrowthInside0LastX128  The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128  The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0  The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1  The uncollected amount of token1 owed to the position as of the last computation
    function npmPositions(uint256 _tokenId)
        external
        view
        override
        nonZeroAddress(address(nonfungiblePositionManager))
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
        )
    {
        return nonfungiblePositionManager.positions(_tokenId);
    }
    */
    /*
    /// @dev snapshotCumulativesInside
    /// @param tickLower  The lower tick of the range
    /// @param tickUpper  The upper tick of the range
    /// @return tickCumulativeInside  The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128  The snapshot of seconds per liquidity for the range
    /// @return secondsInside  The snapshot of seconds per liquidity for the range
    /// @return curTimestamps  current Timestamps
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside,
            uint32 curTimestamps
        )
    {
        tickCumulativeInside;
        secondsPerLiquidityInsideX128;
        secondsInside;
        curTimestamps = uint32(block.timestamp);

        (
            tickCumulativeInside,
            secondsPerLiquidityInsideX128,
            secondsInside
        ) = IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
            tickLower,
            tickUpper
        );
    }
    */
    /// @dev mining end time
    /// @return endTime mining end time
    function miningEndTime()
        external
        view
        override
        nonZeroAddress(vault)
        returns (uint256)
    {
        return IIStake2Vault(vault).miningEndTime();
    }

    /// @dev get price
    /// @param decimals pool's token1's decimals (ex. 1e18)
    /// @return price price
    function getPrice(uint256 decimals)
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (uint256 price)
    {
        (uint160 sqrtPriceX96, , , , , , ) =
            IUniswapV3Pool(poolAddress).slot0();

        return
            uint256(sqrtPriceX96).mul(uint256(sqrtPriceX96)).mul(decimals) >>
            (96 * 2);
    }

    /// @dev Liquidity provision time (seconds) at a specific point in time since the token was recently mined
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.) set it to the current time.
    /// @return secondsAbsolute Absolute duration (in seconds) from the latest mining to the time of expectTime
    /// @return secondsInsideDiff256 The time (in seconds) that the token ID provided liquidity from the last claim (or staking time) to the present time.
    /// @return expectTime time used in the calculation
    function currentliquidityTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        public
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 secondsAbsolute,
            uint256 secondsInsideDiff256,
            uint256 expectTime
        )
    {
        secondsAbsolute = 0;
        secondsInsideDiff256 = 0;
        expectTime = 0;

        if (
            stakeStartTime > 0 &&
            expectBlocktimestamp > coinageLastMintBlockTimetamp
        ) {
            expectTime = expectBlocktimestamp;

            LibUniswapV3Stake.StakeLiquidity storage _depositTokens =
                depositTokens[tokenId];
            (, , uint160 secondsInside) =
                IUniswapV3Pool(poolAddress).snapshotCumulativesInside(
                    _depositTokens.tickLower,
                    _depositTokens.tickUpper
                );

            if (
                expectTime > _depositTokens.claimedTime &&
                expectTime > _depositTokens.startTime
            ) {
                if (_depositTokens.claimedTime > 0) {
                    secondsAbsolute = expectTime.sub(
                        (uint256)(_depositTokens.claimedTime)
                    );
                } else {
                    secondsAbsolute = expectTime.sub(
                        (uint256)(_depositTokens.startTime)
                    );
                }

                if (secondsAbsolute > 0) {
                    if (_depositTokens.secondsInsideLast > 0) {
                        secondsInsideDiff256 = uint256(secondsInside).sub(
                            uint256(_depositTokens.secondsInsideLast)
                        );
                    } else {
                        secondsInsideDiff256 = uint256(secondsInside).sub(
                            uint256(_depositTokens.secondsInsideInitial)
                        );
                    }
                }
            }
        }
    }

    /// @dev Coinage balance information that tokens can receive in the future
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return currentTotalCoinage Current Coinage Total Balance
    /// @return afterTotalCoinage Total balance of Coinage at a future point in time
    /// @return afterBalanceTokenId The total balance of the coin age of the token at a future time
    /// @return expectTime future time
    /// @return addIntervalTime Duration (in seconds) between the future time and the recent mining time
    function currentCoinageBalanceTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        public
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 currentTotalCoinage,
            uint256 afterTotalCoinage,
            uint256 afterBalanceTokenId,
            uint256 expectTime,
            uint256 addIntervalTime
        )
    {
        currentTotalCoinage = 0;
        afterTotalCoinage = 0;
        afterBalanceTokenId = 0;
        expectTime = 0;
        addIntervalTime = 0;

        if (
            stakeStartTime > 0 &&
            expectBlocktimestamp > coinageLastMintBlockTimetamp
        ) {
            expectTime = expectBlocktimestamp;

            uint256 miningEndTime_ = IIStake2Vault(vault).miningEndTime();
            if (expectTime > miningEndTime_) expectTime = miningEndTime_;

            currentTotalCoinage = IAutoRefactorCoinageWithTokenId(coinage)
                .totalSupply();
            (uint256 balance, uint256 refactoredCount, uint256 remain) =
                IAutoRefactorCoinageWithTokenId(coinage).balancesTokenId(
                    tokenId
                );

            uint256 coinageLastMintTime = coinageLastMintBlockTimetamp;
            if (coinageLastMintTime == 0) coinageLastMintTime = stakeStartTime;

            addIntervalTime = expectTime.sub(coinageLastMintTime);
            if (
                miningIntervalSeconds > 0 &&
                addIntervalTime > miningIntervalSeconds
            ) addIntervalTime = addIntervalTime.sub(miningIntervalSeconds);

            if (addIntervalTime > 0) {
                uint256 miningPerSecond_ =
                    IIStake2Vault(vault).miningPerSecond();
                uint256 addAmountCoinage =
                    addIntervalTime.mul(miningPerSecond_);
                afterTotalCoinage = currentTotalCoinage.add(
                    addAmountCoinage.mul(10**9)
                );
                uint256 factor_ =
                    IAutoRefactorCoinageWithTokenId(coinage).factor();
                uint256 infactor =
                    _calcNewFactor(
                        currentTotalCoinage,
                        afterTotalCoinage,
                        factor_
                    );

                uint256 count = 0;
                uint256 f = infactor;
                for (; f >= 10**28; f = f.div(2)) {
                    count = count.add(1);
                }
                uint256 afterBalanceTokenId_ =
                    applyCoinageFactor(balance, refactoredCount, f, count);

                afterBalanceTokenId = afterBalanceTokenId_.add(remain);
            }
        }
    }

    /// @dev Estimated additional claimable amount on a specific time
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return miningAmount Amount you can claim
    /// @return nonMiningAmount The amount that burn without receiving a claim
    /// @return minableAmount Total amount of mining allocated at the time of claim
    /// @return minableAmountRay Total amount of mining allocated at the time of claim (ray unit)
    /// @return expectTime time used in the calculation
    function expectedPlusClaimableAmount(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        override
        nonZeroAddress(poolAddress)
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint256 minableAmountRay,
            uint256 expectTime
        )
    {
        miningAmount = 0;
        nonMiningAmount = 0;
        minableAmount = 0;
        minableAmountRay = 0;
        expectTime = 0;

        if (
            stakeStartTime > 0 &&
            expectBlocktimestamp > coinageLastMintBlockTimetamp
        ) {
            expectTime = expectBlocktimestamp;
            uint256 afterBalanceTokenId = 0;
            uint256 secondsAbsolute = 0;
            uint256 secondsInsideDiff256 = 0;

            uint256 currentBalanceOfTokenId =
                IAutoRefactorCoinageWithTokenId(coinage).balanceOf(tokenId);

            (secondsAbsolute, secondsInsideDiff256, ) = currentliquidityTokenId(
                tokenId,
                expectTime
            );

            (, , afterBalanceTokenId, , ) = currentCoinageBalanceTokenId(
                tokenId,
                expectTime
            );

            if (
                currentBalanceOfTokenId > 0 &&
                afterBalanceTokenId > currentBalanceOfTokenId
            ) {
                minableAmountRay = afterBalanceTokenId.sub(
                    currentBalanceOfTokenId
                );
                minableAmount = minableAmountRay.div(10**9);
            }
            if (minableAmount > 0 && secondsAbsolute > 0 && secondsInsideDiff256 > 0 ) {
                if (
                    secondsInsideDiff256 < secondsAbsolute &&
                    secondsInsideDiff256 > 0
                ) {
                    miningAmount = minableAmount.mul(secondsInsideDiff256).div(
                        secondsAbsolute
                    );
                    nonMiningAmount = minableAmount.sub(miningAmount);
                } else {
                    miningAmount = minableAmount;
                }
            } else if(secondsInsideDiff256 == 0){
                nonMiningAmount = minableAmount;
            }
        }
    }

    function applyCoinageFactor(
        uint256 v,
        uint256 refactoredCount,
        uint256 _factor,
        uint256 refactorCount
    ) internal pure returns (uint256) {
        if (v == 0) {
            return 0;
        }

        v = rmul2(v, _factor);

        for (uint256 i = refactoredCount; i < refactorCount; i++) {
            v = v * (2);
        }

        return v;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeUniswapV3 {
    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    /// @param deadline the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function stakePermit(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @dev stake tokenId of UniswapV3
    /// @param tokenId  tokenId
    function stake(uint256 tokenId) external;

    /// @dev view mining information of tokenId
    /// @param tokenId  tokenId
    function getMiningTokenId(uint256 tokenId)
        external
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint160 secondsInside,
            uint256 secondsInsideDiff256,
            uint256 liquidity,
            uint256 balanceOfTokenIdRay,
            uint256 minableAmountRay,
            uint256 secondsInside256,
            uint256 secondsAbsolute256
        );

    /// @dev withdraw the deposited token.
    ///      The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///      has been provided since recent mining
    /// @param tokenId  tokenId
    function withdraw(uint256 tokenId) external;

    /// @dev The amount mined with the deposited liquidity is claimed and taken.
    ///      The amount of mining taken is changed in proportion to the amount of time liquidity
    ///       has been provided since recent mining
    /// @param tokenId  tokenId
    function claim(uint256 tokenId) external;

    // function setPool(
    //     address token0,
    //     address token1,
    //     string calldata defiInfoName
    // ) external;

    /// @dev
    function getUserStakedTokenIds(address user)
        external
        view
        returns (uint256[] memory ids);

    /// @dev tokenId's deposited information
    /// @param tokenId   tokenId
    /// @return poolAddress   poolAddress
    /// @return tick tick,
    /// @return liquidity liquidity,
    /// @return args liquidity,  startTime, claimedTime, startBlock, claimedBlock, claimedAmount
    /// @return secondsPL secondsPerLiquidityInsideInitialX128, secondsPerLiquidityInsideX128Las
    function getDepositToken(uint256 tokenId)
        external
        view
        returns (
            address poolAddress,
            int24[2] memory tick,
            uint128 liquidity,
            uint256[5] memory args,
            uint160[2] memory secondsPL
        );

    function getUserStakedTotal(address user)
        external
        view
        returns (
            uint256 totalDepositAmount,
            uint256 totalClaimedAmount,
            uint256 totalUnableClaimAmount
        );

    /// @dev Give the infomation of this stakeContracts
    /// @return return1  [token, vault, stakeRegistry, coinage]
    /// @return return2  [poolToken0, poolToken1, nonfungiblePositionManager, uniswapV3FactoryAddress]
    /// @return return3  [totalStakers, totalStakedAmount, rewardClaimedTotal,rewardNonLiquidityClaimTotal]
    function infos()
        external
        view
        returns (
            address[4] memory,
            address[4] memory,
            uint256[4] memory
        );

    /*
    /// @dev pool's infos
    /// @return factory  pool's factory address
    /// @return token0  token0 address
    /// @return token1  token1 address
    /// @return fee  fee
    /// @return tickSpacing  tickSpacing
    /// @return maxLiquidityPerTick  maxLiquidityPerTick
    /// @return liquidity  pool's liquidity
    function poolInfos()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing,
            uint128 maxLiquidityPerTick,
            uint128 liquidity
        );

    /// @dev key's info
    /// @param key hash(owner, tickLower, tickUpper)
    /// @return _liquidity  key's liquidity
    /// @return feeGrowthInside0LastX128  key's feeGrowthInside0LastX128
    /// @return feeGrowthInside1LastX128  key's feeGrowthInside1LastX128
    /// @return tokensOwed0  key's tokensOwed0
    /// @return tokensOwed1  key's tokensOwed1
    function poolPositions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    */

    /// @dev pool's slot0 (current position)
    /// @return sqrtPriceX96  The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick  The current tick of the pool
    /// @return observationIndex  The index of the last oracle observation that was written,
    /// @return observationCardinality  The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext  The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol  The protocol fee for both tokens of the pool
    /// @return unlocked  Whether the pool is currently locked to reentrancy
    function poolSlot0()
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

    /*
    /// @dev _tokenId's position
    /// @param _tokenId  tokenId
    /// @return nonce  the nonce for permits
    /// @return operator  the address that is approved for spending this token
    /// @return token0  The address of the token0 for pool
    /// @return token1  The address of the token1 for pool
    /// @return fee  The fee associated with the pool
    /// @return tickLower  The lower end of the tick range for the position
    /// @return tickUpper  The higher end of the tick range for the position
    /// @return liquidity  The liquidity of the position
    /// @return feeGrowthInside0LastX128  The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128  The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0  The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1  The uncollected amount of token1 owed to the position as of the last computation
    function npmPositions(uint256 _tokenId)
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

    /// @dev snapshotCumulativesInside
    /// @param tickLower  The lower tick of the range
    /// @param tickUpper  The upper tick of the range
    /// @return tickCumulativeInside  The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128  The snapshot of seconds per liquidity for the range
    /// @return secondsInside  The snapshot of seconds per liquidity for the range
    /// @return curTimestamps  current Timestamps
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside,
            uint32 curTimestamps
        );
    */
    /// @dev mining end time
    /// @return endTime mining end time
    function miningEndTime() external view returns (uint256 endTime);

    /// @dev get price
    /// @param decimals pool's token1's decimals (ex. 1e18)
    /// @return price price
    function getPrice(uint256 decimals) external view returns (uint256 price);

    /// @dev Liquidity provision time (seconds) at a specific point in time since the token was recently mined
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.) set it to the current time.
    /// @return secondsAbsolute Absolute duration (in seconds) from the latest mining to the time of expectTime
    /// @return secondsInsideDiff256 The time (in seconds) that the token ID provided liquidity from the last claim (or staking time) to the present time.
    /// @return expectTime time used in the calculation
    function currentliquidityTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        returns (
            uint256 secondsAbsolute,
            uint256 secondsInsideDiff256,
            uint256 expectTime
        );

    /// @dev Coinage balance information that tokens can receive in the future
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return currentTotalCoinage Current Coinage Total Balance
    /// @return afterTotalCoinage Total balance of Coinage at a future point in time
    /// @return afterBalanceTokenId The total balance of the coin age of the token at a future time
    /// @return expectTime future time
    /// @return addIntervalTime Duration (in seconds) between the future time and the recent mining time
    function currentCoinageBalanceTokenId(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        returns (
            uint256 currentTotalCoinage,
            uint256 afterTotalCoinage,
            uint256 afterBalanceTokenId,
            uint256 expectTime,
            uint256 addIntervalTime
        );

    /// @dev Estimated additional claimable amount on a specific time
    /// @param tokenId token id
    /// @param expectBlocktimestamp The specific time you want to know (It must be greater than the last mining time.)
    /// @return miningAmount Amount you can claim
    /// @return nonMiningAmount The amount that burn without receiving a claim
    /// @return minableAmount Total amount of mining allocated at the time of claim
    /// @return minableAmountRay Total amount of mining allocated at the time of claim (ray unit)
    /// @return expectTime time used in the calculation
    function expectedPlusClaimableAmount(
        uint256 tokenId,
        uint256 expectBlocktimestamp
    )
        external
        view
        returns (
            uint256 miningAmount,
            uint256 nonMiningAmount,
            uint256 minableAmount,
            uint256 minableAmountRay,
            uint256 expectTime
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IAutoRefactorCoinageWithTokenId {
    function factor() external view returns (uint256);

    function _factor() external view returns (uint256);

    function refactorCount() external view returns (uint256);

    function balancesTokenId(uint256 tokenId)
        external
        view
        returns (
            uint256 balance,
            uint256 refactoredCount,
            uint256 remain
        );

    function setFactor(uint256 factor_) external returns (uint256);

    function burn(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount
    ) external;

    function mint(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(uint256 tokenId) external view returns (uint256);

    function burnTokenId(address tokenOwner, uint256 tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

//pragma abicoder v2;
//import "../libraries/LibTokenStake1.sol";

interface IIStake2Vault {
    /// @dev  of according to request from(staking contract)  the amount of mining is paid to to.
    /// @param to the address that will receive the reward
    /// @param minableAmount minable amount
    /// @param miningAmount amount mined
    /// @param nonMiningAmount Amount not mined
    function claimMining(
        address to,
        uint256 minableAmount,
        uint256 miningAmount,
        uint256 nonMiningAmount
    ) external returns (bool);

    /// @dev mining per second
    function miningPerSecond() external view returns (uint256);

    /// @dev mining start time
    function miningStartTime() external view returns (uint256);

    /// @dev mining end time
    function miningEndTime() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/dapphub/ds-math/blob/de45767/src/math.sol
/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wmul2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / WAD;
    }

    function rmul2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function wdiv2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, WAD) / y;
    }

    function rdiv2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //  x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //  floor[(n-1) / 2] = floor[n / 2].
    //
    function wpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract AccessibleCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "../libraries/LibUniswapV3Stake.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

/// @title The base storage of stakeContract
contract StakeUniswapV3Storage {
    /// @dev reward token : TOS
    address public token;

    /// @dev registry
    address public stakeRegistry;

    /// @dev A vault that holds tos rewards.
    address public vault;

    /// @dev the total minied amount
    uint256 public miningAmountTotal;

    /// @dev Rewards have been allocated,
    ///      but liquidity is lost, and burned amount .
    uint256 public nonMiningAmountTotal;

    /// @dev the total staked amount
    uint256 public totalStakedAmount;

    /// @dev user's tokenIds
    mapping(address => uint256[]) public userStakedTokenIds;

    /// @dev  Deposited token ID information
    mapping(uint256 => LibUniswapV3Stake.StakeLiquidity) public depositTokens;

    /// @dev Amount that Token ID put into Coinage
    mapping(uint256 => LibUniswapV3Stake.StakedTokenAmount)
        public stakedCoinageTokens;

    /// @dev Total staked information of users
    mapping(address => LibUniswapV3Stake.StakedTotalTokenAmount)
        public userTotalStaked;

    /// @dev total stakers
    uint256 public totalStakers;

    /// @dev lock
    uint256 internal _lock;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev stakeStartTime is set when staking for the first time
    uint256 public stakeStartTime;

    /// @dev saleStartTime
    uint256 public saleStartTime;

    /// @dev Mining interval can be given to save gas cost.
    uint256 public miningIntervalSeconds;

    /// @dev pools's token
    address public poolToken0;
    address public poolToken1;
    address public poolAddress;
    uint256 public poolFee;

    /// @dev Rewards per second liquidity inside (3년간 8000000 TOS)
    /// uint256 internal MINING_PER_SECOND = 84559445290038900;

    /// @dev UniswapV3 Nonfungible position manager
    INonfungiblePositionManager public nonfungiblePositionManager;

    /// @dev UniswapV3 pool factory
    address public uniswapV3FactoryAddress;

    /// @dev coinage for reward 리워드 계산을 위한 코인에이지
    address public coinage;

    /// @dev  recently mined time (in seconds)
    uint256 public coinageLastMintBlockTimetamp;

    /// @dev total tokenIds
    uint256 public totalTokens;

    ///@dev for migrate L2
    bool public migratedL2;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "StakeUniswapV3Storage: zero address");
        _;
    }
    modifier lock() {
        require(_lock == 0, "StakeUniswapV3Storage: LOCKED");
        _lock = 1;
        _;
        _lock = 0;
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
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint32 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
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

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
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
library EnumerableSet {
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibUniswapV3Stake {
    struct StakeLiquidity {
        address owner;
        uint256 idIndex;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
        uint32 startTime;
        uint32 claimedTime;
        uint160 secondsInsideInitial;
        uint160 secondsInsideLast;
        bool claimLock;
        bool withdraw;
    }

    struct StakedTokenAmount {
        uint256 amount;
        uint32 startTime;
        uint32 claimedTime;
        uint256 claimedAmount;
        uint256 nonMiningAmount;
    }

    struct StakedTotalTokenAmount {
        bool staked;
        uint256 totalDepositAmount;
        uint256 totalMiningAmount;
        uint256 totalNonMiningAmount;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
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

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
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

