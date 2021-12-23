// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "contracts/interfaces/IAMM.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/ILPToken.sol";
import "contracts/interfaces/IFutureVault.sol";
import "contracts/interfaces/IFutureWallet.sol";
import "contracts/interfaces/IController.sol";
import "./library/AMMMaths.sol";
import "contracts/RoleCheckable.sol";

contract AMM is IAMM, RoleCheckable {
    using AMMMathsUtils for uint256;
    using SafeERC20Upgradeable for IERC20;

    // ERC-165 identifier for the main token standard.
    bytes4 public constant ERC1155_ERC165 = 0xd9b67a26;

    uint64 public override ammId;

    IFutureVault private futureVault;
    uint256 public swapFee;

    IERC20 private ibt;
    IERC20 private pt;
    IERC20 private underlyingOfIBT;
    IERC20 private fyt;

    address internal feesRecipient;

    ILPToken private poolTokens;

    uint256 private constant BASE_WEIGHT = 5 * 10**17;

    enum AMMGlobalState { Created, Activated, Paused }
    AMMGlobalState private state;

    uint256 public currentPeriodIndex;
    uint256 public lastBlockYieldRecorded;
    uint256 public lastYieldRecorded;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    mapping(uint256 => mapping(uint256 => uint256)) private poolToUnderlyingAtPeriod;
    mapping(uint256 => uint256) private generatedYieldAtPeriod;
    mapping(uint256 => uint256) private underlyingSavedPerPeriod;
    mapping(uint256 => mapping(uint256 => uint256)) private totalLPSupply;

    mapping(uint256 => Pair) private pairs;
    mapping(address => uint256) private tokenToPairID;

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

    event AMMStateChanged(AMMGlobalState _newState);
    event PairCreated(uint256 indexed _pairID, address _token);
    event LiquidityCreated(address _user, uint256 _pairID);
    event PoolJoined(address _user, uint256 _pairID, uint256 _poolTokenAmount);
    event PoolExited(address _user, uint256 _pairID, uint256 _poolTokenAmount);
    event LiquidityIncreased(address _from, uint256 _pairID, uint256 _tokenID, uint256 _amount);
    event LiquidityDecreased(address _to, uint256 _pairID, uint256 _tokenID, uint256 _amount);
    event Swapped(
        address _user,
        uint256 _pairID,
        uint256 _tokenInID,
        uint256 _tokenOutID,
        uint256 _tokenAmountIn,
        uint256 _tokenAmountOut,
        address _to
    );
    event PeriodSwitched(uint256 _newPeriodIndex);
    event WeightUpdated(address _token, uint256[2] _newWeights);
    event ExpiredTokensWithdrawn(address _user, uint256 _amount);
    event SwappingFeeSet(uint256 _swapFee);

    /* General State functions */

    /**
     * @notice AMM initializer
     * @param _ammId We might need to create an AMMFactory to maintain a counter index which can be passed as _ammId
     * @param _underlyingOfIBTAddress the address of the IBT underlying
     * @param _futureVault the address of the future vault
     * @param _poolTokens ERC1155 contract to maintain LPTokens
     * @param _admin the address of the contract admin
     */
    function initialize(
        uint64 _ammId,
        address _underlyingOfIBTAddress,
        address _futureVault,
        ILPToken _poolTokens,
        address _admin,
        address _feesRecipient
    ) public virtual initializer {
        require(_poolTokens.supportsInterface(ERC1155_ERC165), "AMM: Interface not supported");
        require(_underlyingOfIBTAddress != address(0), "AMM: Invalid underlying address");
        require(_futureVault != address(0), "AMM: Invalid future address");
        require(_admin != address(0), "AMM: Invalid admin address");
        require(_feesRecipient != address(0), "AMM: Invalid fees recipient address");

        ammId = _ammId;
        poolTokens = _poolTokens;
        feesRecipient = _feesRecipient;
        futureVault = IFutureVault(_futureVault);
        ibt = IERC20(futureVault.getIBTAddress());

        address _ptAddress = futureVault.getPTAddress();

        // Initialize first PT x Underlying pool
        underlyingOfIBT = IERC20(_underlyingOfIBTAddress);
        pt = IERC20(_ptAddress);

        // Instantiate weights of first pool
        tokenToPairID[_ptAddress] = 0;
        _createPair(uint256(0), _underlyingOfIBTAddress);
        _status = _NOT_ENTERED;
        // Role initialization
        _setupRole(ADMIN_ROLE, _admin);

        state = AMMGlobalState.Created; // waiting to be finalized
    }

    function _createPair(uint256 _pairID, address _tokenAddress) internal {
        pairs[_pairID] = Pair({
            tokenAddress: _tokenAddress,
            weights: [BASE_WEIGHT, BASE_WEIGHT],
            balances: [uint256(0), uint256(0)],
            liquidityIsInitialized: false
        });
        tokenToPairID[_tokenAddress] = _pairID;
        emit PairCreated(_pairID, _tokenAddress);
    }

    function togglePauseAmm() external override isAdmin {
        require(state != AMMGlobalState.Created, "AMM: Not Initialized");
        state = state == AMMGlobalState.Activated ? AMMGlobalState.Paused : AMMGlobalState.Activated;
        emit AMMStateChanged(state);
    }

    /**
     * @notice finalize the initialization of the amm
     * @dev must be called during the first period the amm is supposed to be active, will initialize fyt address
     */
    function finalize() external override isAdmin {
        require(state == AMMGlobalState.Created, "AMM: Already Finalized");
        currentPeriodIndex = futureVault.getCurrentPeriodIndex();
        require(currentPeriodIndex >= 1, "AMM: Invalid period ID");

        address fytAddress = futureVault.getFYTofPeriod(currentPeriodIndex);
        fyt = IERC20(fytAddress);

        _createPair(uint256(1), fytAddress);

        state = AMMGlobalState.Activated;
        emit AMMStateChanged(AMMGlobalState.Activated);
    }

    /**
     * @notice switch period
     * @dev must be called after each new period switch
     * @dev the switch will auto renew part of the tokens and update the weights accordingly
     */
    function switchPeriod() external override {
        ammIsActive();
        require(futureVault.getCurrentPeriodIndex() > currentPeriodIndex, "AMM: Invalid period index");
        _renewUnderlyingPool();
        _renewFYTPool();
        generatedYieldAtPeriod[currentPeriodIndex] = futureVault.getYieldOfPeriod(currentPeriodIndex);
        currentPeriodIndex = futureVault.getCurrentPeriodIndex();
        emit PeriodSwitched(currentPeriodIndex);
    }

    function _renewUnderlyingPool() internal {
        underlyingSavedPerPeriod[currentPeriodIndex] = pairs[0].balances[1];
        uint256 oldIBTBalance = ibt.balanceOf(address(this));
        uint256 ptBalance = pairs[0].balances[0];
        if (ptBalance != 0) {
            IController(futureVault.getControllerAddress()).withdraw(address(futureVault), ptBalance);
        }
        _saveExpiredIBTs(0, ibt.balanceOf(address(this)).sub(oldIBTBalance), currentPeriodIndex);
        _resetPair(0);
    }

    function _renewFYTPool() internal {
        address fytAddress = futureVault.getFYTofPeriod(futureVault.getCurrentPeriodIndex());
        pairs[1].tokenAddress = fytAddress;
        fyt = IERC20(fytAddress);
        uint256 oldIBTBalance = ibt.balanceOf(address(this));
        uint256 ptBalance = pairs[1].balances[0];
        if (ptBalance != 0) {
            IFutureWallet(futureVault.getFutureWalletAddress()).redeemYield(currentPeriodIndex); // redeem ibt from expired ibt
            IController(futureVault.getControllerAddress()).withdraw(address(futureVault), ptBalance); // withdraw current pt and generated fyt
        }
        _saveExpiredIBTs(1, ibt.balanceOf(address(this)).sub(oldIBTBalance), currentPeriodIndex);
        _resetPair(1);
    }

    function _resetPair(uint256 _pairID) internal {
        pairs[_pairID].balances = [uint256(0), uint256(0)];
        pairs[_pairID].weights = [BASE_WEIGHT, BASE_WEIGHT];
        pairs[_pairID].liquidityIsInitialized = false;
    }

    function _saveExpiredIBTs(
        uint256 _pairID,
        uint256 _ibtGenerated,
        uint256 _periodID
    ) internal {
        poolToUnderlyingAtPeriod[_pairID][_periodID] = futureVault.convertIBTToUnderlying(_ibtGenerated);
    }

    /**
     * @notice update the weights at each new block depending on the generated yield
     */
    function _updateWeightsFromYieldAtBlock() internal {
        (uint256 newUnderlyingWeight, uint256 yieldRecorded) = _getUpdatedUnderlyingWeightAndYield();

        if (newUnderlyingWeight != pairs[0].weights[1]) {
            lastYieldRecorded = yieldRecorded;
            lastBlockYieldRecorded = block.number;
            pairs[0].weights = [AMMMaths.UNIT - newUnderlyingWeight, newUnderlyingWeight];

            emit WeightUpdated(pairs[0].tokenAddress, pairs[0].weights);
        }
    }

    function getPTWeightInPair() external view override returns (uint256) {
        (uint256 newUnderlyingWeight, ) = _getUpdatedUnderlyingWeightAndYield();
        return AMMMaths.UNIT - newUnderlyingWeight;
    }

    function _getUpdatedUnderlyingWeightAndYield() internal view returns (uint256, uint256) {
        uint256 inverseSpotPrice = (AMMMaths.SQUARED_UNIT).div(getSpotPrice(0, 1, 0));
        uint256 yieldRecorded = futureVault.convertIBTToUnderlying(futureVault.getUnrealisedYieldPerPT());
        if (lastBlockYieldRecorded != block.number && lastYieldRecorded != yieldRecorded) {
            uint256 newSpotPrice =
                ((AMMMaths.UNIT + yieldRecorded).mul(AMMMaths.SQUARED_UNIT)).div(
                    ((AMMMaths.UNIT + lastYieldRecorded).mul(inverseSpotPrice))
                );
            if (newSpotPrice < AMMMaths.UNIT) {
                uint256[2] memory balances = pairs[0].balances;
                uint256 newUnderlyingWeight =
                    balances[1].mul(AMMMaths.UNIT).div(balances[1].add(balances[0].mul(newSpotPrice).div(AMMMaths.UNIT)));
                return (newUnderlyingWeight, yieldRecorded);
            } else {
                return (pairs[0].weights[1], yieldRecorded);
            }
        } else {
            return (pairs[0].weights[1], yieldRecorded);
        }
    }

    /* Renewal functions */

    /**
     * @notice Withdraw expired LP tokens
     */
    function withdrawExpiredToken(address _user, uint256 _lpTokenId) public override nonReentrant {
        _withdrawExpiredToken(_user, _lpTokenId);
    }

    function _withdrawExpiredToken(address _user, uint256 _lpTokenId) internal {
        (uint256 redeemableTokens, uint256 lastPeriodId, uint256 pairId) = getExpiredTokensInfo(_user, _lpTokenId);
        require(redeemableTokens > 0, "AMM: no redeemable token");
        uint256 userTotal = poolTokens.balanceOf(_user, _lpTokenId);
        uint256 tokenSupply = totalLPSupply[pairId][lastPeriodId];

        totalLPSupply[pairId][lastPeriodId] = totalLPSupply[pairId][lastPeriodId].sub(userTotal);
        poolTokens.burnFrom(_user, _lpTokenId, userTotal);

        if (pairId == 0) {
            uint256 userUnderlyingAmount = underlyingSavedPerPeriod[lastPeriodId].mul(userTotal).div(tokenSupply);
            underlyingOfIBT.safeTransfer(_user, userUnderlyingAmount);
        }
        ibt.safeTransfer(_user, redeemableTokens);

        emit ExpiredTokensWithdrawn(_user, redeemableTokens);
    }

    /**
     * @notice Getter for redeemable expired tokens info
     * @param _user the address of the user to check the redeemable tokens of
     * @param _lpTokenId the lp token id
     * @return the amount, the period id and the pair id of the expired tokens of the user
     */
    function getExpiredTokensInfo(address _user, uint256 _lpTokenId)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(poolTokens.getAMMId(_lpTokenId) == ammId, "AMM: invalid amm id");
        uint256 pairID = poolTokens.getPairId(_lpTokenId);
        require(pairID < 2, "AMM: invalid pair id");
        uint256 periodIndex = poolTokens.getPeriodIndex(_lpTokenId);
        require(periodIndex <= currentPeriodIndex, "AMM: invalid period id");
        if (periodIndex == 0 || periodIndex == currentPeriodIndex) return (0, periodIndex, pairID);
        uint256 redeemable =
            poolTokens
                .balanceOf(_user, getLPTokenId(ammId, periodIndex, pairID))
                .mul(poolToUnderlyingAtPeriod[pairID][periodIndex])
                .div(totalLPSupply[pairID][periodIndex]);
        for (uint256 i = periodIndex.add(1); i < currentPeriodIndex; i++) {
            redeemable = redeemable
                .mul(AMMMaths.UNIT.add(futureVault.convertIBTToUnderlying(generatedYieldAtPeriod[i])))
                .div(AMMMaths.UNIT);
        }
        return (
            futureVault.convertUnderlyingtoIBT(
                redeemable.add(
                    redeemable.mul(futureVault.convertIBTToUnderlying(futureVault.getUnrealisedYieldPerPT())).div(
                        AMMMaths.UNIT
                    )
                )
            ),
            periodIndex,
            pairID
        );
    }

    function _getRedeemableExpiredTokens(address _user, uint256 _lpTokenId) internal view returns (uint256) {}

    /* Swapping functions */
    function swapExactAmountIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _tokenOut,
        uint256 _minAmountOut,
        address _to
    ) external override nonReentrant returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        tokenIdsAreValid(_tokenIn, _tokenOut);
        _updateWeightsFromYieldAtBlock();

        (tokenAmountOut, spotPriceAfter) = calcOutAndSpotGivenIn(
            _pairID,
            _tokenIn,
            _tokenAmountIn,
            _tokenOut,
            _minAmountOut
        );

        _pullToken(msg.sender, _pairID, _tokenIn, _tokenAmountIn);
        _pushToken(_to, _pairID, _tokenOut, tokenAmountOut);
        emit Swapped(msg.sender, _pairID, _tokenIn, _tokenOut, _tokenAmountIn, tokenAmountOut, _to);
        return (tokenAmountOut, spotPriceAfter);
    }

    function calcOutAndSpotGivenIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _tokenOut,
        uint256 _minAmountOut
    ) public view override returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        tokenIdsAreValid(_tokenIn, _tokenOut);
        uint256[2] memory balances = pairs[_pairID].balances;
        uint256[2] memory weights = pairs[_pairID].weights;
        require(weights[_tokenIn] > 0 && weights[_tokenOut] > 0, "AMM: Invalid token address");

        uint256 spotPriceBefore =
            AMMMaths.calcSpotPrice(balances[_tokenIn], weights[_tokenIn], balances[_tokenOut], weights[_tokenOut], swapFee);

        tokenAmountOut = AMMMaths.calcOutGivenIn(
            balances[_tokenIn],
            weights[_tokenIn],
            balances[_tokenOut],
            weights[_tokenOut],
            _tokenAmountIn,
            swapFee
        );
        require(tokenAmountOut >= _minAmountOut, "AMM: Min amount not reached");

        spotPriceAfter = AMMMaths.calcSpotPrice(
            balances[_tokenIn].add(_tokenAmountIn),
            weights[_tokenIn],
            balances[_tokenOut].sub(tokenAmountOut),
            weights[_tokenOut],
            swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "AMM: Math approximation error");
    }

    function swapExactAmountOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _maxAmountIn,
        uint256 _tokenOut,
        uint256 _tokenAmountOut,
        address _to
    ) external override nonReentrant returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        tokenIdsAreValid(_tokenIn, _tokenOut);
        _updateWeightsFromYieldAtBlock();

        (tokenAmountIn, spotPriceAfter) = calcInAndSpotGivenOut(_pairID, _tokenIn, _maxAmountIn, _tokenOut, _tokenAmountOut);

        _pullToken(msg.sender, _pairID, _tokenIn, tokenAmountIn);
        _pushToken(_to, _pairID, _tokenOut, _tokenAmountOut);
        emit Swapped(msg.sender, _pairID, _tokenIn, _tokenOut, tokenAmountIn, _tokenAmountOut, _to);

        return (tokenAmountIn, spotPriceAfter);
    }

    function calcInAndSpotGivenOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _maxAmountIn,
        uint256 _tokenOut,
        uint256 _tokenAmountOut
    ) public view override returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        tokenIdsAreValid(_tokenIn, _tokenOut);
        uint256 inTokenBalance = pairs[_pairID].balances[_tokenIn];
        uint256 outTokenBalance = pairs[_pairID].balances[_tokenOut];
        uint256 tokenWeightIn = pairs[_pairID].weights[_tokenIn];
        uint256 tokenWeightOut = pairs[_pairID].weights[_tokenOut];
        require(tokenWeightIn > 0 && tokenWeightOut > 0, "AMM: Invalid token address");

        uint256 spotPriceBefore =
            AMMMaths.calcSpotPrice(inTokenBalance, tokenWeightIn, outTokenBalance, tokenWeightOut, swapFee);

        tokenAmountIn = AMMMaths.calcInGivenOut(
            inTokenBalance,
            tokenWeightIn,
            outTokenBalance,
            tokenWeightOut,
            _tokenAmountOut,
            swapFee
        );
        require(tokenAmountIn <= _maxAmountIn, "AMM: Max amount in reached");

        spotPriceAfter = AMMMaths.calcSpotPrice(
            inTokenBalance.add(tokenAmountIn),
            tokenWeightIn,
            outTokenBalance.sub(_tokenAmountOut),
            tokenWeightOut,
            swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "AMM: Math approximation error");
    }

    function joinSwapExternAmountIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _minPoolAmountOut
    ) external override nonReentrant returns (uint256 poolAmountOut) {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);

        require(_tokenIn < 2, "AMM: Invalid Token Id");
        _updateWeightsFromYieldAtBlock();

        Pair memory pair = pairs[_pairID];

        uint256 inTokenBalance = pair.balances[_tokenIn];
        uint256 tokenWeightIn = pair.weights[_tokenIn];

        require(tokenWeightIn > 0, "AMM: Invalid token address");
        require(_tokenAmountIn <= inTokenBalance.mul(AMMMaths.MAX_IN_RATIO) / AMMMaths.UNIT, "AMM: Max in ratio reached");

        poolAmountOut = AMMMaths.calcPoolOutGivenSingleIn(
            inTokenBalance,
            tokenWeightIn,
            totalLPSupply[_pairID][currentPeriodIndex],
            AMMMaths.UNIT,
            _tokenAmountIn,
            swapFee
        );

        require(poolAmountOut >= _minPoolAmountOut, "AMM: Min amount not reached");

        _pullToken(msg.sender, _pairID, _tokenIn, _tokenAmountIn);
        _joinPool(msg.sender, poolAmountOut, _pairID);
        return poolAmountOut;
    }

    function joinSwapPoolAmountOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _poolAmountOut,
        uint256 _maxAmountIn
    ) external override nonReentrant returns (uint256 tokenAmountIn) {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        require(_tokenIn < 2, "AMM: Invalid Token Id");
        _updateWeightsFromYieldAtBlock();
        Pair memory pair = pairs[_pairID];

        uint256 inTokenBalance = pair.balances[_tokenIn];
        uint256 tokenWeightIn = pair.weights[_tokenIn];

        require(tokenWeightIn > 0, "AMM: Invalid token address");
        tokenAmountIn = AMMMaths.calcSingleInGivenPoolOut(
            inTokenBalance,
            tokenWeightIn,
            totalLPSupply[_pairID][currentPeriodIndex],
            AMMMaths.UNIT,
            _poolAmountOut,
            swapFee
        );

        require(tokenAmountIn <= inTokenBalance.mul(AMMMaths.MAX_IN_RATIO) / AMMMaths.UNIT, "AMM: Max in ratio reached");
        require(tokenAmountIn != 0, "AMM: Math approximation error");
        require(tokenAmountIn <= _maxAmountIn, "AMM: Max amount in reached");

        _pullToken(msg.sender, _pairID, _tokenIn, tokenAmountIn);
        _joinPool(msg.sender, _poolAmountOut, _pairID);
        return tokenAmountIn;
    }

    function exitSwapPoolAmountIn(
        uint256 _pairID,
        uint256 _tokenOut,
        uint256 _poolAmountIn,
        uint256 _minAmountOut
    ) external override nonReentrant returns (uint256 tokenAmountOut) {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        require(_tokenOut < 2, "AMM: Invalid Token Id");

        _updateWeightsFromYieldAtBlock();
        Pair memory pair = pairs[_pairID];

        uint256 outTokenBalance = pair.balances[_tokenOut];
        uint256 tokenWeightOut = pair.weights[_tokenOut];
        require(tokenWeightOut > 0, "AMM: Invalid token address");

        tokenAmountOut = AMMMaths.calcSingleOutGivenPoolIn(
            outTokenBalance,
            tokenWeightOut,
            totalLPSupply[_pairID][currentPeriodIndex],
            AMMMaths.UNIT,
            _poolAmountIn,
            swapFee
        );

        require(tokenAmountOut <= outTokenBalance.mul(AMMMaths.MAX_OUT_RATIO) / AMMMaths.UNIT, "AMM: Max out ratio reached");
        require(tokenAmountOut >= _minAmountOut, "AMM: Min amount not reached");

        _exitPool(msg.sender, _poolAmountIn, _pairID);
        _pushToken(msg.sender, _pairID, _tokenOut, tokenAmountOut);
        return tokenAmountOut;
    }

    function exitSwapExternAmountOut(
        uint256 _pairID,
        uint256 _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _maxPoolAmountIn
    ) external override nonReentrant returns (uint256 poolAmountIn) {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        require(_tokenOut < 2, "AMM: Invalid Token Id");

        _updateWeightsFromYieldAtBlock();
        Pair memory pair = pairs[_pairID];

        uint256 outTokenBalance = pair.balances[_tokenOut];
        uint256 tokenWeightOut = pair.weights[_tokenOut];
        require(tokenWeightOut > 0, "AMM: Invalid token address");
        require(
            _tokenAmountOut <= outTokenBalance.mul(AMMMaths.MAX_OUT_RATIO) / AMMMaths.UNIT,
            "AMM: Max out ratio reached"
        );

        poolAmountIn = AMMMaths.calcPoolInGivenSingleOut(
            outTokenBalance,
            tokenWeightOut,
            totalLPSupply[_pairID][currentPeriodIndex],
            AMMMaths.UNIT,
            _tokenAmountOut,
            swapFee
        );

        require(poolAmountIn != 0, "AMM: Math approximation error");
        require(poolAmountIn <= _maxPoolAmountIn, "AMM: Max amount is reached");

        _exitPool(msg.sender, poolAmountIn, _pairID);
        _pushToken(msg.sender, _pairID, _tokenOut, _tokenAmountOut);
        return poolAmountIn;
    }

    /* Liquidity-related functions */

    /**
     * @notice Create liquidity on the pair setting an initial price
     */
    function createLiquidity(uint256 _pairID, uint256[2] memory _tokenAmounts) external override nonReentrant {
        ammIsActive();
        require(!pairs[_pairID].liquidityIsInitialized, "AMM: Liquidity already present");
        require(_tokenAmounts[0] != 0 && _tokenAmounts[1] != 0, "AMM: Tokens Liquidity not exists");
        _pullToken(msg.sender, _pairID, 0, _tokenAmounts[0]);
        _pullToken(msg.sender, _pairID, 1, _tokenAmounts[1]);
        _joinPool(msg.sender, AMMMaths.UNIT, _pairID);
        pairs[_pairID].liquidityIsInitialized = true;
        emit LiquidityCreated(msg.sender, _pairID);
    }

    function _pullToken(
        address _sender,
        uint256 _pairID,
        uint256 _tokenID,
        uint256 _amount
    ) internal {
        address _tokenIn = _tokenID == 0 ? address(pt) : pairs[_pairID].tokenAddress;
        pairs[_pairID].balances[_tokenID] = pairs[_pairID].balances[_tokenID].add(_amount);
        IERC20(_tokenIn).safeTransferFrom(_sender, address(this), _amount);
        emit LiquidityIncreased(_sender, _pairID, _tokenID, _amount);
    }

    function _pushToken(
        address _recipient,
        uint256 _pairID,
        uint256 _tokenID,
        uint256 _amount
    ) internal {
        address _tokenIn = _tokenID == 0 ? address(pt) : pairs[_pairID].tokenAddress;
        pairs[_pairID].balances[_tokenID] = pairs[_pairID].balances[_tokenID].sub(_amount);
        IERC20(_tokenIn).safeTransfer(_recipient, _amount);
        emit LiquidityDecreased(_recipient, _pairID, _tokenID, _amount);
    }

    function addLiquidity(
        uint256 _pairID,
        uint256 _poolAmountOut,
        uint256[2] memory _maxAmountsIn
    ) external override nonReentrant {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        require(_poolAmountOut != 0, "AMM: Amount cannot be 0");
        _updateWeightsFromYieldAtBlock();

        uint256 poolTotal = totalLPSupply[_pairID][currentPeriodIndex];

        for (uint256 i; i < 2; i++) {
            uint256 amountIn = _computeAmountWithShares(pairs[_pairID].balances[i], _poolAmountOut, poolTotal);
            require(amountIn != 0, "AMM: Math approximation error");
            require(amountIn <= _maxAmountsIn[i], "AMM: Max amount in reached");
            _pullToken(msg.sender, _pairID, i, amountIn);
        }
        _joinPool(msg.sender, _poolAmountOut, _pairID);
    }

    function removeLiquidity(
        uint256 _pairID,
        uint256 _poolAmountIn,
        uint256[2] memory _minAmountsOut
    ) external override nonReentrant {
        ammIsActive();
        pairLiquidityIsInitialized(_pairID);
        require(_poolAmountIn != 0, "AMM: Amount cannot be 0");
        _updateWeightsFromYieldAtBlock();

        uint256 poolTotal = totalLPSupply[_pairID][currentPeriodIndex];

        for (uint256 i; i < 2; i++) {
            uint256 amountOut = _computeAmountWithShares(pairs[_pairID].balances[i], _poolAmountIn, poolTotal);
            require(amountOut != 0, "AMM: Math approximation error");
            require(amountOut >= _minAmountsOut[i], "AMM: Min amount not reached");
            _pushToken(msg.sender, _pairID, i, amountOut.mul(AMMMaths.UNIT.sub(AMMMaths.EXIT_FEE)).div(AMMMaths.UNIT));
        }
        _exitPool(msg.sender, _poolAmountIn, _pairID);
    }

    function _joinPool(
        address _user,
        uint256 _amount,
        uint256 _pairID
    ) internal {
        poolTokens.mint(_user, ammId, uint64(currentPeriodIndex), uint32(_pairID), _amount, bytes(""));
        totalLPSupply[_pairID][currentPeriodIndex] = totalLPSupply[_pairID][currentPeriodIndex].add(_amount);
        emit PoolJoined(_user, _pairID, _amount);
    }

    function _exitPool(
        address _user,
        uint256 _amount,
        uint256 _pairID
    ) internal {
        uint256 lpTokenId = getLPTokenId(ammId, currentPeriodIndex, _pairID);

        uint256 exitFee = _amount.mul(AMMMaths.EXIT_FEE).div(AMMMaths.UNIT);
        uint256 userAmount = _amount.sub(exitFee);
        poolTokens.burnFrom(_user, lpTokenId, userAmount);
        poolTokens.safeTransferFrom(_user, feesRecipient, lpTokenId, exitFee, "");

        totalLPSupply[_pairID][currentPeriodIndex] = totalLPSupply[_pairID][currentPeriodIndex].sub(userAmount);
        emit PoolExited(_user, _pairID, _amount);
    }

    function setSwappingFees(uint256 _swapFee) external override isAdmin {
        require(_swapFee < AMMMaths.UNIT, "AMM: Fee must be < 1");
        swapFee = _swapFee;
        emit SwappingFeeSet(_swapFee);
    }

    // Emergency withdraw - will only rescue funds mistakenly sent to the address
    function rescueFunds(IERC20 _token, address _recipient) external isAdmin {
        uint256 pairId = tokenToPairID[address(_token)];
        bool istokenPresent = false;
        if (pairId == 0) {
            if (_token == pt || address(_token) == pairs[0].tokenAddress) {
                istokenPresent = true;
            }
        } else {
            istokenPresent = true;
        }
        require(!istokenPresent, "AMM: Token is present");
        uint256 toRescue = _token.balanceOf(address(this));
        require(toRescue > 0, "AMM: No funds to rescue");
        _token.safeTransfer(_recipient, toRescue);
    }

    /* Utils*/
    function _computeAmountWithShares(
        uint256 _amount,
        uint256 _sharesAmount,
        uint256 _sharesTotalAmount
    ) internal pure returns (uint256) {
        return _sharesAmount.mul(_amount).div(_sharesTotalAmount);
    }

    /* Getters */

    /**
     * @notice Getter for the spot price of a pair
     * @param _pairID the id of the pair
     * @param _tokenIn the id of the tokens sent
     * @param _tokenOut the id of the tokens received
     * @return the sport price of the pair
     */
    function getSpotPrice(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenOut
    ) public view override returns (uint256) {
        return
            AMMMaths.calcSpotPrice(
                pairs[_pairID].balances[_tokenIn],
                pairs[_pairID].weights[_tokenIn],
                pairs[_pairID].balances[_tokenOut],
                pairs[_pairID].weights[_tokenOut],
                swapFee
            );
    }

    /**
     * @notice Getter for the paused state of the AMM
     * @return true if the AMM is paused, false otherwise
     */
    function getAMMState() external view returns (AMMGlobalState) {
        return state;
    }

    /**
     * @notice Getter for the address of the corresponding future vault
     * @return the address of the future vault
     */
    function getFutureAddress() external view override returns (address) {
        return address(futureVault);
    }

    /**
     * @notice Getter for the pt address
     * @return the pt address
     */
    function getPTAddress() external view override returns (address) {
        return address(pt);
    }

    /**
     * @notice Getter for the address of the underlying token of the ibt
     * @return the address of the underlying token of the ibt
     */
    function getUnderlyingOfIBTAddress() external view override returns (address) {
        return address(underlyingOfIBT);
    }

    /**
     * @notice Getter for the address of the ibt
     * @return the address of the ibt token
     */
    function getIBTAddress() external view returns (address) {
        return address(ibt);
    }

    /**
     * @notice Getter for the fyt address
     * @return the fyt address
     */
    function getFYTAddress() external view override returns (address) {
        return address(fyt);
    }

    /**
     * @notice Getter for the pool token address
     * @return the pool tokens address
     */
    function getPoolTokenAddress() external view returns (address) {
        return address(poolTokens);
    }

    function getPairWithID(uint256 _pairID) external view override returns (Pair memory) {
        return pairs[_pairID];
    }

    function getTotalSupplyWithTokenId(uint256 _tokenId) external view returns (uint256) {
        uint256 pairId = poolTokens.getPairId(_tokenId);
        uint256 periodId = poolTokens.getPeriodIndex(_tokenId);
        return totalLPSupply[pairId][periodId];
    }

    function getPairIDForToken(address _tokenAddress) external view returns (uint256) {
        if (tokenToPairID[_tokenAddress] == 0)
            require(pairs[0].tokenAddress == _tokenAddress || _tokenAddress == address(pt), "AMM: invalid token address");
        return tokenToPairID[_tokenAddress];
    }

    function getLPTokenId(
        uint256 _ammId,
        uint256 _periodIndex,
        uint256 _pairID
    ) public pure override returns (uint256) {
        return (_ammId << 192) | (_periodIndex << 128) | (_pairID << 96);
    }

    /* Modifier functions */

    /**
     * @notice Check state of AMM
     */
    function ammIsActive() private view {
        require(state == AMMGlobalState.Activated, "AMM: AMM not active");
    }

    /**
     * @notice Check liquidity is initilized for the given _pairId
     * @param _pairID the id of the pair
     */
    function pairLiquidityIsInitialized(uint256 _pairID) private view {
        require(pairs[_pairID].liquidityIsInitialized, "AMM: Pair not active");
    }

    /**
     * @notice Check valid Token ID's
     * @param _tokenIdInd the id of token In
     * @param _tokenIdOut the id of token Out
     */
    function tokenIdsAreValid(uint256 _tokenIdInd, uint256 _tokenIdOut) private pure {
        require(_tokenIdInd < 2 && _tokenIdOut < 2 && _tokenIdInd != _tokenIdOut, "AMM: Invalid Token ID");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

interface IAMM {
    /* Struct */
    struct Pair {
        address tokenAddress; // first is always PT
        uint256[2] weights;
        uint256[2] balances;
        bool liquidityIsInitialized;
    }

    /**
     * @notice finalize the initialization of the amm
     * @dev must be called during the first period the amm is supposed to be active
     */
    function finalize() external;

    /**
     * @notice switch period
     * @dev must be called after each new period switch
     * @dev the switch will auto renew part of the tokens and update the weights accordingly
     */
    function switchPeriod() external;

    /**
     * @notice toggle amm pause for pausing/resuming all user functionalities
     */
    function togglePauseAmm() external;

    /**
     * @notice Withdraw expired LP tokens
     */
    function withdrawExpiredToken(address _user, uint256 _lpTokenId) external;

    /**
     * @notice Getter for redeemable expired tokens info
     * @param _user the address of the user to check the redeemable tokens of
     * @param _lpTokenId the lp token id
     * @return the amount, the period id and the pair id of the expired tokens of the user
     */
    function getExpiredTokensInfo(address _user, uint256 _lpTokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function swapExactAmountIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _tokenOut,
        uint256 _minAmountOut,
        address _to
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _maxAmountIn,
        uint256 _tokenOut,
        uint256 _tokenAmountOut,
        address _to
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    /**
     * @notice Create liquidity on the pair setting an initial price
     */
    function createLiquidity(uint256 _pairID, uint256[2] memory _tokenAmounts) external;

    function addLiquidity(
        uint256 _pairID,
        uint256 _poolAmountOut,
        uint256[2] memory _maxAmountsIn
    ) external;

    function removeLiquidity(
        uint256 _pairID,
        uint256 _poolAmountIn,
        uint256[2] memory _minAmountsOut
    ) external;

    function joinSwapExternAmountIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinSwapPoolAmountOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _poolAmountOut,
        uint256 _maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitSwapPoolAmountIn(
        uint256 _pairID,
        uint256 _tokenOut,
        uint256 _poolAmountIn,
        uint256 _minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitSwapExternAmountOut(
        uint256 _pairID,
        uint256 _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function setSwappingFees(uint256 _swapFee) external;

    /* Getters */
    function calcOutAndSpotGivenIn(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _tokenOut,
        uint256 _minAmountOut
    ) external view returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function calcInAndSpotGivenOut(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _maxAmountIn,
        uint256 _tokenOut,
        uint256 _tokenAmountOut
    ) external view returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    /**
     * @notice Getter for the spot price of a pair
     * @param _pairID the id of the pair
     * @param _tokenIn the id of the tokens sent
     * @param _tokenOut the id of the tokens received
     * @return the sport price of the pair
     */
    function getSpotPrice(
        uint256 _pairID,
        uint256 _tokenIn,
        uint256 _tokenOut
    ) external view returns (uint256);

    /**
     * @notice Getter for the address of the corresponding future vault
     * @return the address of the future vault
     */
    function getFutureAddress() external view returns (address);

    /**
     * @notice Getter for the pt address
     * @return the pt address
     */
    function getPTAddress() external view returns (address);

    /**
     * @notice Getter for the address of the underlying token of the ibt
     * @return the address of the underlying token of the ibt
     */
    function getUnderlyingOfIBTAddress() external view returns (address);

    /**
     * @notice Getter for the fyt address
     * @return the fyt address
     */
    function getFYTAddress() external view returns (address);

    /**
     * @notice Getter for the PT weight in the first pair (0)
     * @return the weight of the pt
     */
    function getPTWeightInPair() external view returns (uint256);

    function getPairWithID(uint256 _pairID) external view returns (Pair memory);

    function getLPTokenId(
        uint256 _ammId,
        uint256 _periodIndex,
        uint256 _pairID
    ) external pure returns (uint256);

    function ammId() external returns (uint64);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20 is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

import "contracts/interfaces/IERC1155.sol";

pragma solidity ^0.7.6;

interface ILPToken is IERC1155 {
    function amms(uint64 _ammId) external view returns (address);

    /**
     * @notice Getter for AMM id
     * @param _id the id of the LP Token
     * @return AMM id
     */
    function getAMMId(uint256 _id) external pure returns (uint64);

    /**
     * @notice Getter for PeriodIndex
     * @param _id the id of the LP Token
     * @return period index
     */
    function getPeriodIndex(uint256 _id) external pure returns (uint64);

    /**
     * @notice Getter for PairId
     * @param _id the index of the Pair
     * @return pair index
     */
    function getPairId(uint256 _id) external pure returns (uint32);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/interfaces/IPT.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/interfaces/IFutureWallet.sol";

interface IFutureVault {
    /* Events */
    event NewPeriodStarted(uint256 _newPeriodIndex);
    event FutureWalletSet(address _futureWallet);
    event RegistrySet(IRegistry _registry);
    event FundsDeposited(address _user, uint256 _amount);
    event FundsWithdrawn(address _user, uint256 _amount);
    event PTSet(IPT _pt);
    event LiquidityTransfersPaused();
    event LiquidityTransfersResumed();
    event DelegationCreated(address _delegator, address _receiver, uint256 _amount);
    event DelegationRemoved(address _delegator, address _receiver, uint256 _amount);

    /* Params */
    /**
     * @notice Getter for the PERIOD future parameter
     * @return returns the period duration of the future
     */
    function PERIOD_DURATION() external view returns (uint256);

    /**
     * @notice Getter for the PLATFORM_NAME future parameter
     * @return returns the platform of the future
     */
    function PLATFORM_NAME() external view returns (string memory);

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() external;

    /**
     * @notice Update the state of the user and mint claimable pt
     * @param _user user adress
     */
    function updateUserState(address _user) external;

    /**
     * @notice Send the user their owed FYT (and pt if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user, uint256 _amount) external;

    /**
     * @notice Deposit funds into ongoing period
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev part of the amount deposited will be used to buy back the yield already generated proportionally to the amount deposited
     */
    function deposit(address _user, uint256 _amount) external;

    /**
     * @notice Sender unlocks the locked funds corresponding to their pt holding
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdraw(address _user, uint256 _amount) external;

    /**
     * @notice Create a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to delegate
     */
    function createFYTDelegationTo(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Remove a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to remove from the delegation
     */
    function withdrawFYTDelegationFrom(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /* Getters */

    /**
     * @notice Getter the total number of FYTs on address is delegating
     * @param _delegator the delegating address
     * @return totalDelegated the number of FYTs delegated
     */
    function getTotalDelegated(address _delegator) external view returns (uint256 totalDelegated);

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for current period index
     * @return current period index
     * @dev index starts at 1
     */
    function getCurrentPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for the amount of pt that the user can claim
     * @param _user user to check the check the claimable pt of
     * @return the amount of pt claimable by the user
     */
    function getClaimablePT(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount (in underlying) of premium redeemable with the corresponding amount of fyt/pt to be burned
     * @param _user user adress
     * @return premiumLocked the premium amount unlockage at this period (in underlying), amountRequired the amount of pt/fyt required for that operation
     */
    function getUserEarlyUnlockablePremium(address _user)
        external
        view
        returns (uint256 premiumLocked, uint256 amountRequired);

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user the user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user the user to check the claimable FYT of
     * @param _periodIndex period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodIndex) external view returns (uint256);

    /**
     * @notice Getter for the yield currently generated by one pt for the current period
     * @return the amount of yield (in IBT) generated during the current period
     */
    function getUnrealisedYieldPerPT() external view returns (uint256);

    /**
     * @notice Getter for the number of pt that can be minted for an amoumt deposited now
     * @param _amount the amount to of IBT to deposit
     * @return the number of pt that can be minted for that amount
     */
    function getPTPerAmountDeposited(uint256 _amount) external view returns (uint256);

    /**
     * @notice Getter for premium in underlying tokens that can be redeemed at the end of the period of the deposit
     * @param _amount the amount of underlying deposited
     * @return the number of underlying of the ibt deposited that will be redeemable
     */
    function getPremiumPerUnderlyingDeposited(uint256 _amount) external view returns (uint256);

    /**
     * @notice Getter for total underlying deposited in the vault
     * @return the total amount of funds deposited in the vault (in underlying)
     */
    function getTotalUnderlyingDeposited() external view returns (uint256);

    /**
     * @notice Getter for the total yield generated during one period
     * @param _periodID the period id
     * @return the total yield in underlying value
     */
    function getYieldOfPeriod(uint256 _periodID) external view returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() external view returns (address);

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() external view returns (address);

    /**
     * @notice Getter for future pt address
     * @return pt address
     */
    function getPTAddress() external view returns (address);

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex) external view returns (address);

    /**
     * @notice Getter for the terminated state of the future
     * @return true if this vault is terminated
     */
    function isTerminated() external view returns (bool);

    /**
     * @notice Getter for the performance fee factor of the current period
     * @return the performance fee factor of the futureVault
     */
    function getPerformanceFeeFactor() external view returns (uint256);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the vault
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllVaultRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemVaultRewards(address _rewardToken) external;

    /**
     * @notice Add a token to the list of reward tokens
     * @param _token the reward token to add to the list
     * @dev the token must be different than the ibt
     */
    function addRewardsToken(address _token) external;

    /**
     * @notice Getter to check if a token is in the reward tokens list
     * @param _token the token to check if it is in the list
     * @return true if the token is a reward token
     */
    function isRewardToken(address _token) external view returns (bool);

    /**
     * @notice Getter for the reward token at an index
     * @param _index the index of the reward token in the list
     * @return the address of the token at this index
     */
    function getRewardTokenAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for the size of the list of reward tokens
     * @return the number of token in the list
     */
    function getRewardTokensCount() external view returns (uint256);

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;

    /* Admin functions */

    /**
     * @notice Set futureWallet address
     */
    function setFutureWallet(IFutureWallet _futureWallet) external;

    /**
     * @notice Set Registry
     */
    function setRegistry(IRegistry _registry) external;

    /**
     * @notice Pause liquidity transfers
     */
    function pauseLiquidityTransfers() external;

    /**
     * @notice Resume liquidity transfers
     */
    function resumeLiquidityTransfers() external;

    /**
     * @notice Convert an amount of IBTs in its equivalent in underlying tokens
     * @param _amount the amount of IBTs
     * @return the corresponding amount of underlying
     */
    function convertIBTToUnderlying(uint256 _amount) external view returns (uint256);

    /**
     * @notice Convert an amount of underlying tokens in its equivalent in IBTs
     * @param _amount the amount of underlying tokens
     * @return the corresponding amount of IBTs
     */
    function convertUnderlyingtoIBT(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IFutureWallet {
    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the ACR admin
     */
    function initialize(address _futureAddress, address _adminAddress) external;

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) external;

    /**
     * @notice redeem the yield of the underlying yield of the FYT held by the sender
     * @param _periodIndex the index of the period to redeem the yield from
     */
    function redeemYield(uint256 _periodIndex) external;

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _tokenHolder the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _tokenHolder) external view returns (uint256);

    /**
     * @notice getter for the address of the future corresponding to this future wallet
     * @return the address of the future
     */
    function getFutureAddress() external view returns (address);

    /**
     * @notice getter for the address of the IBT corresponding to this future wallet
     * @return the address of the IBT
     */
    function getIBTAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IController {
    /* Getters */

    function STARTING_DELAY() external view returns (uint256);

    /* Future Settings Setters */

    /**
     * @notice Change the delay for starting a new period
     * @param _startingDelay the new delay (+-) to start the next period
     */
    function setPeriodStartingDelay(uint256 _startingDelay) external;

    /**
     * @notice Set the next period switch timestamp for the future with corresponding duration
     * @param _periodDuration the duration of a period
     * @param _nextPeriodTimestamp the next period switch timestamp
     */
    function setNextPeriodSwitchTimestamp(uint256 _periodDuration, uint256 _nextPeriodTimestamp) external;

    /* User Methods */

    /**
     * @notice Deposit funds into ongoing period
     * @param _futureVault the address of the future to be deposit the funds in
     * @param _amount the amount to deposit on the ongoing period
     * @dev part of the amount depostied will be used to buy back the yield already generated proportionaly to the amount deposited
     */
    function deposit(address _futureVault, uint256 _amount) external;

    /**
     * @notice Withdraw deposited funds from APWine
     * @param _futureVault the address of the future to withdraw the IBT from
     * @param _amount the amount to withdraw
     */
    function withdraw(address _futureVault, uint256 _amount) external;

    /**
     * @notice Claim FYT of the msg.sender
     * @param _futureVault the future from which to claim the FYT
     */
    function claimFYT(address _futureVault) external;

    /**
     * @notice Getter for the registry address of the protocol
     * @return the address of the protocol registry
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Getter for the symbol of the PT of one future
     * @param _ibtSymbol the IBT of the external protocol
     * @param _platform the external protocol name
     * @param _periodDuration the duration of the periods for the future
     * @return the generated symbol of the PT
     */
    function getFutureIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) external pure returns (string memory);

    /**
     * @notice Getter for the symbol of the FYT of one future
     * @param _ptSymbol the PT symbol for this future
     * @param _periodDuration the duration of the periods for this future
     * @return the generated symbol of the FYT
     */
    function getFYTSymbol(string memory _ptSymbol, uint256 _periodDuration) external view returns (string memory);

    /**
     * @notice Getter for the period index depending on the period duration of the future
     * @param _periodDuration the periods duration
     * @return the period index
     */
    function getPeriodIndex(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for beginning timestamp of the next period for the futures with a defined periods duration
     * @param _periodDuration the periods duration
     * @return the timestamp of the beginning of the next period
     */
    function getNextPeriodStart(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for the next performance fee factor of one futureVault
     * @param _futureVault the address of the futureVault
     * @return the next performance fee factor of the futureVault
     */
    function getNextPerformanceFeeFactor(address _futureVault) external view returns (uint256);

    /**
     * @notice Getter for the performance fee factor of one futureVault
     * @param _futureVault the address of the futureVault
     * @return the performance fee factor of the futureVault
     */
    function getCurrentPerformanceFeeFactor(address _futureVault) external view returns (uint256);

    /**
     * @notice Getter for the list of future durations registered in the contract
     * @return the list of futures duration
     */
    function getDurations() external view returns (uint256[] memory);

    /**
     * @notice Register a newly created future in the registry
     * @param _futureVault the address of the new future
     */
    function registerNewFutureVault(address _futureVault) external;

    /**
     * @notice Unregister a future from the registry
     * @param _futureVault the address of the future to unregister
     */
    function unregisterFutureVault(address _futureVault) external;

    /**
     * @notice Start all the futures that have a defined periods duration to synchronize them
     * @param _periodDuration the periods duration of the futures to start
     */
    function startFuturesByPeriodDuration(uint256 _periodDuration) external;

    /**
     * @notice Getter for the futures by periods duration
     * @param _periodDuration the periods duration of the futures to return
     */
    function getFuturesWithDuration(uint256 _periodDuration) external view returns (address[] memory);

    /**
     * @notice Claim the FYTs of the corresponding futures
     * @param _user the address of the user
     * @param _futureVaults the addresses of the futures to claim the fyts from
     */
    function claimSelectedFYTS(address _user, address[] memory _futureVaults) external;

    function getRoleMember(bytes32 role, uint256 index) external view returns (address); // OZ ACL getter

    /**
     * @notice Getter for the future deposits state
     * @param _futureVault the address of the future
     * @return true is new deposits are paused, false otherwise
     */
    function isDepositsPaused(address _futureVault) external view returns (bool);

    /**
     * @notice Getter for the future withdrawals state
     * @param _futureVault the address of the future
     * @return true is new withdrawals are paused, false otherwise
     */
    function isWithdrawalsPaused(address _futureVault) external view returns (bool);

    /**
     * @notice Getter for the future period state
     * @param _futureVault the address of the future
     * @return true if the future is set to be terminated
     */
    function isFutureSetToBeTerminated(address _futureVault) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.7.6;

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol
library AMMMathsUtils {
    uint256 internal constant UNIT = 10**18;
    uint256 internal constant MIN_POW_BASE = 1 wei;
    uint256 internal constant MAX_POW_BASE = (2 * UNIT) - 1 wei;
    uint256 internal constant POW_PRECISION = UNIT / 10**10;

    function powi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : UNIT;
        for (n /= 2; n != 0; n /= 2) {
            a = div(mul(a, a), UNIT);
            if (n % 2 != 0) {
                z = div(mul(z, a), UNIT);
            }
        }
        return z;
    }

    function pow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_POW_BASE, "ERR_POW_BASE_TOO_LOW");
        require(base <= MAX_POW_BASE, "ERR_POW_BASE_TOO_HIGH");
        uint256 whole = mul(div(exp, UNIT), UNIT);
        uint256 remain = sub(exp, whole);
        uint256 wholePow = powi(base, div(whole, UNIT));
        if (remain == 0) {
            return wholePow;
        }
        uint256 partialResult = powApprox(base, remain, POW_PRECISION);
        return div(mul(wholePow, partialResult), UNIT);
    }

    function subSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        return (a >= b) ? (a - b, false) : (b - a, true);
    }

    function powApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = subSign(base, UNIT);
        uint256 term = UNIT;
        uint256 sum = term;
        bool negative = false;
        for (uint256 i = 1; term >= precision; ++i) {
            uint256 bigK = mul(i, UNIT);
            (uint256 c, bool cneg) = subSign(a, sub(bigK, UNIT));
            term = div(mul(term, div(mul(c, x), UNIT)), UNIT);
            term = div(mul(UNIT, term), bigK);
            if (term == 0) break;
            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sub(sum, term);
            } else {
                sum = add(sum, term);
            }
        }
        return sum;
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
        require(c >= a, "AMMMaths: addition overflow");
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
        require(b <= a, "AMMMaths: subtraction overflow");
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
        require(c / a == b, "AMMMaths: multiplication overflow");
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
        require(b > 0, "AMMMaths: division by zero");
        return a / b;
    }
}

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BMath.sol
library AMMMaths {
    using AMMMathsUtils for uint256;
    uint256 internal constant UNIT = 10**18;
    uint256 internal constant SQUARED_UNIT = UNIT * UNIT;
    uint256 internal constant EXIT_FEE = 0;

    uint256 internal constant MAX_IN_RATIO = UNIT / 2;
    uint256 internal constant MAX_OUT_RATIO = (UNIT / 3) + 1 wei;

    function calcOutGivenIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenWeightIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _tokenAmountIn,
        uint256 _swapFee
    ) internal pure returns (uint256) {
        return
            calcOutGivenIn(
                _tokenBalanceIn,
                _tokenWeightIn,
                _tokenBalanceOut,
                _tokenWeightOut,
                _tokenAmountIn,
                _swapFee,
                UNIT
            );
    }

    function calcOutGivenIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenWeightIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _tokenAmountIn,
        uint256 _swapFee,
        uint256 _slippageFactor
    ) internal pure returns (uint256) {
        uint256 slippageBase = UNIT.mul(UNIT).div(_slippageFactor);
        uint256 weightRatio = slippageBase.mul(_tokenWeightIn).div(_tokenWeightOut);
        uint256 adjustedIn = _tokenAmountIn.mul(UNIT.sub(_swapFee)).div(UNIT);
        uint256 y = UNIT.mul(_tokenBalanceIn).div(_tokenBalanceIn.add(adjustedIn));
        uint256 bar = UNIT.sub(AMMMathsUtils.pow(y, weightRatio));
        return _tokenBalanceOut.mul(bar).div(UNIT);
    }

    function calcInGivenOut(
        uint256 _tokenBalanceIn,
        uint256 _tokenWeightIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _tokenAmountOut,
        uint256 _swapFee
    ) internal pure returns (uint256) {
        return
            calcInGivenOut(
                _tokenBalanceIn,
                _tokenWeightIn,
                _tokenBalanceOut,
                _tokenWeightOut,
                _tokenAmountOut,
                _swapFee,
                UNIT
            );
    }

    function calcInGivenOut(
        uint256 _tokenBalanceIn,
        uint256 _tokenWeightIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _tokenAmountOut,
        uint256 _swapFee,
        uint256 _slippageFactor
    ) internal pure returns (uint256) {
        uint256 slippageBase = UNIT.mul(UNIT).div(_slippageFactor);
        uint256 weightRatio = slippageBase.mul(_tokenWeightOut).div(_tokenWeightIn);
        uint256 y = UNIT.mul(_tokenBalanceOut).div(_tokenBalanceOut.sub(_tokenAmountOut));
        uint256 foo = AMMMathsUtils.pow(y, weightRatio).sub(UNIT);
        return _tokenBalanceIn.mul(foo).div(UNIT.sub(_swapFee));
    }

    function calcPoolOutGivenSingleIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenWeightIn,
        uint256 _poolSupply,
        uint256 _totalWeight,
        uint256 _tokenAmountIn,
        uint256 _swapFee
    ) internal pure returns (uint256) {
        uint256 normalizedWeight = UNIT.mul(_tokenWeightIn).div(_totalWeight);
        uint256 zaz = (UNIT.sub(normalizedWeight)).mul(_swapFee).div(UNIT);
        uint256 tokenAmountInAfterFee = _tokenAmountIn.mul(UNIT.sub(zaz)).div(UNIT);
        uint256 newTokenBalanceIn = _tokenBalanceIn.add(tokenAmountInAfterFee);
        uint256 tokenInRatio = UNIT.mul(newTokenBalanceIn).div(_tokenBalanceIn);
        uint256 poolRatio = AMMMathsUtils.pow(tokenInRatio, normalizedWeight);
        uint256 newPoolSupply = poolRatio.mul(_poolSupply).div(UNIT);
        return newPoolSupply.sub(_poolSupply);
    }

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) internal pure returns (uint256 tokenAmountIn) {
        uint256 normalizedWeight = UNIT.mul(tokenWeightIn).div(totalWeight);
        uint256 newPoolSupply = poolSupply.add(poolAmountOut);
        uint256 poolRatio = UNIT.mul(newPoolSupply).div(poolSupply);

        //uint256 newBalTi = poolRatio^(1/weightTi) * balTi;
        uint256 boo = UNIT.mul(UNIT).div(normalizedWeight);
        uint256 tokenInRatio = AMMMathsUtils.pow(poolRatio, boo);
        uint256 newTokenBalanceIn = tokenInRatio.mul(tokenBalanceIn).div(UNIT);
        uint256 tokenAmountInAfterFee = newTokenBalanceIn.sub(tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint256 tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint256 zar = (UNIT.sub(normalizedWeight)).mul(swapFee).div(UNIT);
        tokenAmountIn = UNIT.mul(tokenAmountInAfterFee).div(UNIT.sub(zar));
        return tokenAmountIn;
    }

    function calcSpotPrice(
        uint256 _tokenBalanceIn,
        uint256 _tokenWeightIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _swapFee
    ) internal pure returns (uint256) {
        uint256 numer = UNIT.mul(_tokenBalanceIn).div(_tokenWeightIn);
        uint256 denom = UNIT.mul(_tokenBalanceOut).div(_tokenWeightOut);
        uint256 ratio = UNIT.mul(numer).div(denom);
        uint256 scale = UNIT.mul(UNIT).div(UNIT.sub(_swapFee));
        return ratio.mul(scale).div(UNIT);
    }

    function calcSingleOutGivenPoolIn(
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _poolSupply,
        uint256 _totalWeight,
        uint256 _poolAmountIn,
        uint256 _swapFee
    ) internal pure returns (uint256) {
        uint256 normalizedWeight = UNIT.mul(_tokenWeightOut).div(_totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee = _poolAmountIn.mul(UNIT.sub(EXIT_FEE)).div(UNIT);
        uint256 newPoolSupply = _poolSupply.sub(poolAmountInAfterExitFee);
        uint256 poolRatio = UNIT.mul(newPoolSupply).div(_poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = AMMMathsUtils.pow(poolRatio, UNIT.mul(UNIT).div(normalizedWeight));
        uint256 newTokenBalanceOut = tokenOutRatio.mul(_tokenBalanceOut).div(UNIT);

        uint256 tokenAmountOutBeforeSwapFee = _tokenBalanceOut.sub(newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint256 tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * _swapFee)
        uint256 zaz = (UNIT.sub(normalizedWeight)).mul(_swapFee).div(UNIT);
        return tokenAmountOutBeforeSwapFee.mul(UNIT.sub(zaz)).div(UNIT);
    }

    function calcPoolInGivenSingleOut(
        uint256 _tokenBalanceOut,
        uint256 _tokenWeightOut,
        uint256 _poolSupply,
        uint256 _totalWeight,
        uint256 _tokenAmountOut,
        uint256 _swapFee
    ) internal pure returns (uint256) {
        // charge swap fee on the output token side
        uint256 normalizedWeight = UNIT.mul(_tokenWeightOut).div(_totalWeight);
        //uint256 tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * _swapFee) ;
        uint256 zoo = UNIT.sub(normalizedWeight);
        uint256 zar = zoo.mul(_swapFee).div(UNIT);
        uint256 tokenAmountOutBeforeSwapFee = UNIT.mul(_tokenAmountOut).div(UNIT.sub(zar));

        uint256 newTokenBalanceOut = _tokenBalanceOut.sub(tokenAmountOutBeforeSwapFee);
        uint256 tokenOutRatio = UNIT.mul(newTokenBalanceOut).div(_tokenBalanceOut);

        //uint256 newPoolSupply = (ratioTo ^ weightTo) * _poolSupply;
        uint256 poolRatio = AMMMathsUtils.pow(tokenOutRatio, normalizedWeight);
        uint256 newPoolSupply = poolRatio.mul(_poolSupply).div(UNIT);
        uint256 poolAmountInAfterExitFee = _poolSupply.sub(newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        return UNIT.mul(poolAmountInAfterExitFee).div(UNIT.sub(EXIT_FEE));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract RoleCheckable is Initializable {
    /* ACR Roles*/
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    // keccak256("ADMIN_ROLE");
    bytes32 internal constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
    mapping(bytes32 => RoleData) private _roles;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    /* Modifiers */
    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    modifier isAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "RoleCheckable: Caller should be ADMIN");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function grantRole(bytes32 role, address account) external;

    function MINTER_ROLE() external view returns (bytes32);

    function mint(
        address to,
        uint64 _ammId,
        uint64 _periodIndex,
        uint32 _pairId,
        uint256 amount,
        bytes memory data
    ) external returns (uint256 id);

    function burnFrom(
        address account,
        uint256 id,
        uint256 value
    ) external;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/interfaces/IERC20.sol";

interface IPT is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @notice Returns the current balance of one user (without the claimable amount)
     * @param account the address of the account to check the balance of
     * @return the current pt balance of this address
     */
    function recordedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Returns the current balance of one user including the pt that were not claimed yet
     * @param account the address of the account to check the balance of
     * @return the total pt balance of one address
     */
    function balanceOf(address account) external view override returns (uint256);

    /**
     * @notice Getter for the future vault link to this pt
     * @return the address of the future vault
     */
    function futureVault() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRegistry {
    /**
     * @notice Initializer of the contract
     * @param _admin the address of the admin of the contract
     */
    function initialize(address _admin) external;

    /* Setters */
    /**
     * @notice Setter for the treasury address
     * @param _newTreasury the address of the new treasury
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice Setter for the controller address
     * @param _newController the address of the new controller
     */
    function setController(address _newController) external;

    /**
     * @notice Setter for the APW token address
     * @param _newAPW the address of the APW token
     */
    function setAPW(address _newAPW) external;

    /**
     * @notice Setter for the proxy factory address
     * @param _proxyFactory the address of the new proxy factory
     */
    function setProxyFactory(address _proxyFactory) external;

    /**
     * @notice Setter for the APWine IBT logic address
     * @param _PTLogic the address of the new APWine IBT logic
     */
    function setPTLogic(address _PTLogic) external;

    /**
     * @notice Setter for the APWine FYT logic address
     * @param _FYTLogic the address of the new APWine FYT logic
     */
    function setFYTLogic(address _FYTLogic) external;

    /**
     * @notice Setter for the maths utils address
     * @param _mathsUtils the address of the new math utils
     */
    function setMathsUtils(address _mathsUtils) external;

    /**
     * @notice Setter for the naming utils address
     * @param _namingUtils the address of the new naming utils
     */
    function setNamingUtils(address _namingUtils) external;

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for the treasury address
     * @return the address of the treasury
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @notice Getter for the tokens factory address
     * @return the address of the tokens factory
     */
    function getTokensFactoryAddress() external view returns (address);

    /**
     * @notice Getter for the DAO address
     * @return the address of the DAO that has admin rights on the APW token
     */
    function getDAOAddress() external returns (address);

    /**
     * @notice Getter for the APW token address
     * @return the address the APW token
     */
    function getAPWAddress() external view returns (address);

    /**
     * @notice Getter for the AMM factory address
     * @return the AMM factory address
     */
    function getAMMFactoryAddress() external view returns (address);

    /**
     * @notice Getter for the token factory address
     * @return the token factory address
     */
    function getTokenFactoryAddress() external view returns (address);

    /**
     * @notice Getter for the proxy factory address
     * @return the proxy factory address
     */
    function getProxyFactoryAddress() external view returns (address);

    /**
     * @notice Getter for APWine IBT logic address
     * @return the APWine IBT logic address
     */
    function getPTLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine FYT logic address
     * @return the APWine FYT logic address
     */
    function getFYTLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine AMM logic address
     * @return the APWine AMM logic address
     */
    function getAMMLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine AMM LP token logic address
     * @return the APWine AMM LP token logic address
     */
    function getAMMLPTokenLogicAddress() external view returns (address);

    /**
     * @notice Getter for math utils address
     * @return the math utils address
     */
    function getMathsUtils() external view returns (address);

    /**
     * @notice Getter for naming utils address
     * @return the naming utils address
     */
    function getNamingUtils() external view returns (address);

    /* Futures */
    /**
     * @notice Add a future to the registry
     * @param _future the address of the future to add to the registry
     */
    function addFuture(address _future) external;

    /**
     * @notice Remove a future from the registry
     * @param _future the address of the future to remove from the registry
     */
    function removeFuture(address _future) external;

    /**
     * @notice Getter to check if a future is registered
     * @param _future the address of the future to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFuture(address _future) external view returns (bool);

    /**
     * @notice Getter to check if an AMM is registered
     * @param _ammAddress the address of the amm to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredAMM(address _ammAddress) external view returns (bool);

    /**
     * @notice Getter for the future registered at an index
     * @param _index the index of the future to return
     * @return the address of the corresponding future
     */
    function getFutureAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future registered
     * @return the number of future registered
     */
    function futureCount() external view returns (uint256);
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