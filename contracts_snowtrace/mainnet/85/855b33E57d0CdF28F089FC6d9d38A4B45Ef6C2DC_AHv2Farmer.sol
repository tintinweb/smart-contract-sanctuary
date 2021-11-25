// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../BaseStrategy.sol";
import "../common/Constants.sol";

// Uniswap router interface
interface IUni {
    function getAmountsOut(uint256 _amountIn, address[] calldata _path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint[] memory amounts);  
}

// Uniswap pool interface
interface IUniPool {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function totalSupply() external view returns (uint256);
}

// HomoraBank interface
interface IHomora {
    function execute(
        uint256 _positionId,
        address _spell,
        bytes memory _data
    ) external payable returns (uint256);

    function nextPositionId() external view returns (uint256);

    function borrowBalanceStored(uint256 _positionId, address _token)
        external
        view
        returns (uint256);

    function getPositionInfo(uint256 _positionId)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    function getPositionDebts(uint256 _positionId)
        external
        view
        returns (address[] memory tokens, uint256[] memory debts);

    function getCollateralETHValue(uint256 _positionId)
        external
        view
        returns (uint256);

    function getBorrowETHValue(uint256 _positionId)
        external
        view
        returns (uint256);
}

// AH master chef tracker interface
interface IWMasterChef {
    function balanceOf(address _account, uint256 _id)
        external
        view
        returns (uint256);

    function decodeId(uint256 _id)
        external
        pure
        returns (uint256 pid, uint256 sushiPerShare);
}

// Master chef interface
interface IMasterChef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accSushiPerShare
        );
}

/* @notice AHv2Farmer - Alpha Homora V2 yield aggregator strategy
 *
 *      Farming AHv2 Stable/AVAX positions.
 *
 *  ###############################################
 *      Strategy overview
 *  ###############################################
 *
 *  Gro Protocol Alpha Homora v2 impermanent loss strategy
 *
 *  Alpha homora (referred to as AHv2) offers leveraged yield farming by offering up to 7x leverage
 *      on users positions in various AMMs. The gro alpha homora v2 strategy (referred to as the strategy)
 *      aim to utilize AHv2 leverage to create and maintain market neutral positions (2x leverage)
 *      for as long as they are deemed profitable. This means that the strategy will supply want (stable coin)
 *      to AH, and borrow avax in a proportional amount. Under certian circumstances the strategy will stop
 *      it's borrowing, but will not ever attempt to borrow want from AH.
 *
 *  ###############################################
 *      Strategy specifications
 *  ###############################################
 *
 *  The strategy sets out to fulfill the following requirements:
 *      - Open new positions
 *  - Close active positions
 *  - Adjust active positions
 *  - Interact with Gro vault adapters (GVA):
 *          - Report gains/losses
 *      - Borrow assets from GVA to invest into AHv2
 *          - Repay debts to GVA
 *              - Accommodate withdrawals from GVA
 *
 * The strategy keeps track of the following:
 *   - Price changes in opening position
 *   - Collateral ratio of AHv2 position
 *
 * If any of these go out of a preset threshold, the strategy will attempt to close down the position.
 *  If the collateral factor move away from the ideal target, the strategy won't take on more debt from alpha
 *  homora when adding assets to the position.
 */
contract AHv2Farmer is BaseStrategy {
    using SafeERC20 for IERC20;

    // Base constants
    uint256 public constant DEFAULT_DECIMALS_FACTOR = 1E18;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = 1E4;
    // collateral constants - The collateral ratio is calculated by using
    // the homoraBank to establish the AVAX value of the debts vs the AVAX value
    // of the collateral.
    uint256 public constant targetCollateralRatio = 7950; // ideal collateral ratio
    uint256 public constant collateralThreshold = 8900; // max collateral raio
    // LP Pool token
    IUniPool public immutable pool;
    address public constant wavax =
        address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    // Full repay
    uint256 constant REPAY = type(uint256).max;

    // UniV2 or Sushi swap style router
    IUni public immutable uniSwapRouter;
    // comment out if uniSwap spell is used
    address public constant yieldToken =
        address(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);
    address public constant homoraBank =
        address(0x376d16C7dE138B01455a51dA79AD65806E9cd694);
    address public constant masterChef =
        address(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    IWMasterChef public constant wMasterChef =
        IWMasterChef(0xB41DE9c1f50697cC3Fd63F24EdE2B40f6269CBcb);
    address public immutable spell;

    // strategies current position
    uint256 public activePosition;
    // How much change we accept in AVAX price before closing or adjusting the position
    uint256 public ilThreshold;

    // Min amount of tokens to open/adjust positions or sell
    uint256 public minWant;
    uint256 public constant minAVAXToSell = 0;
    // comment out if uniSwap spell is used
    uint256 public constant minYieldTokenToSell = 0;

    // Limits the size of a position based on how much is available to borrow
    uint256 public borrowLimit;

    event LogNewPositionOpened(
        uint256 indexed positionId,
        uint256[] price,
        uint256 collateralSize,
        uint256[] debts
    );
    event LogPositionClosed(
        uint256 indexed positionId,
        uint256 wantRecieved,
        uint256[] price
    );
    event LogPositionAdjusted(
        uint256 indexed positionId,
        uint256[] amounts,
        uint256 collateralSize,
        uint256[] debts,
        bool withdrawal
    );
    event LogAVAXSold(uint256[] AVAXSold);
    event LogYieldTokenSold(uint256[] yieldTokenSold);

    event NewFarmer(
        address vault,
        address spell,
        address router,
        address pool,
        uint256 poolId
    );
    event LogNewReserversSet(uint256 reserve);
    event LogNewIlthresholdSet(uint256 ilThreshold);
    event LogNewMinWantSet(uint256 minWawnt);
    event LogNewBorrowLimit(uint256 newLimit);

    struct positionData {
        uint256[] wantClose; // AVAX value of position when closed [want => AVAX]
        uint256 totalClose; // total value of position on close
        uint256[] wantOpen; // AVAX value of position when opened [want => AVAX]
        uint256 collId; // collateral ID
        uint256 collateral; // collateral amount
        uint256[] debt; // borrowed token amount
        bool active; // is position active
    }

    struct Amounts {
        uint256 aUser; // Supplied tokenA amount
        uint256 bUser; // Supplied tokenB amount
        uint256 lpUser; // Supplied LP token amount
        uint256 aBorrow; // Borrow tokenA amount
        uint256 bBorrow; // Borrow tokenB amount
        uint256 lpBorrow; // Borrow LP token amount
        uint256 aMin; // Desired tokenA amount (slippage control)
        uint256 bMin; // Desired tokenB amount (slippage control)
    }

    struct RepayAmounts {
        uint256 lpTake; // Take out LP token amount (from Homora)
        uint256 lpWithdraw; // Withdraw LP token amount (back to caller)
        uint256 aRepay; // Repay tokenA amount
        uint256 bRepay; // Repay tokenB amount
        uint256 lpRepay; // Repay LP token amount
        uint256 aMin; // Desired tokenA amount
        uint256 bMin; // Desired tokenB amount
    }

    // strategy positions
    mapping(uint256 => positionData) positions;

    // function headers for generating signatures for encoding function calls
    // AHv2 homorabank uses encoded spell function calls in order to cast spells
    string constant spellOpen =
        "addLiquidityWMasterChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),uint256)";
    string constant spellClose =
        "removeLiquidityWMasterChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256))";

    // poolId for masterchef - can be commented out for non sushi spells
    uint256 immutable poolId;

    constructor(
        address _vault,
        address _spell,
        address _router,
        address _pool,
        uint256 _poolId
    ) BaseStrategy(_vault) {
        profitFactor = 1000;
        debtThreshold = 1_000_000 * 1e18;
        // approve the homora bank to use our want
        want.safeApprove(homoraBank, type(uint256).max);
        // approve the router to use our yieldToken
        IERC20(yieldToken).safeApprove(_router, type(uint256).max);
        spell = _spell;
        uniSwapRouter = IUni(_router);
        pool = IUniPool(_pool);
        poolId = _poolId;

        uint256 _minWant = 10000 * (10**VaultAPI(_vault).decimals());
        minWant = 0; // dont open or adjust a position unless less than...
        ilThreshold = 400; // 4%
        emit NewFarmer(_vault, _spell, _router, _pool, _poolId);
        emit LogNewMinWantSet(_minWant);
        emit LogNewIlthresholdSet(400);
    }

    /// Strategy name
    function name() external pure override returns (string memory) {
        return "AHv2 strategy";
    }

    // Strategy will recieve AVAX from closing/adjusting positions, do nothing with the AVAX here
    receive() external payable {}

    // Default getter for public structs done return dynamics arrays, so we add this here
    function getPosition(uint256 _positionId) external view returns (positionData memory) {
        return positions[_positionId];
    }

    /*
     * @notice set minimum want required to adjust position
     * @param _minWant minimum amount of want
     */
    function setMinWant(uint256 _minWant) external onlyOwner {
        minWant = _minWant;
        emit LogNewMinWantSet(_minWant);
    }

    /*
     * @notice set minimum want required to adjust position
     * @param _minWant minimum amount of want
     */
    function setBorrowLimit(uint256 _newLimt) external onlyAuthorized {
        borrowLimit = _newLimt;
        emit LogNewBorrowLimit(_newLimt);
    }

    /*
     * @notice set impermanent loss threshold - this indicates when a position should be closed or adjusted
     *  based on price differences between the original position and
     * @param _newThreshold new il threshold
     */
    function setIlThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold <= 10000, "setIlThreshold: !newThreshold");
        ilThreshold = _newThreshold;
        emit LogNewIlthresholdSet(_newThreshold);
    }

    /*
     * @notice Estimate amount of yield tokens that will be claimed if position is closed
     * @param _positionId ID of a AHv2 position
     */
    function pendingYieldToken(uint256 _positionId) public view returns (uint256) {
        if (_positionId == 0) {
            return 0;
        }
        uint256 _collId = positions[_positionId].collId;
        // get balance of collateral
        uint256 amount = positions[_positionId].collateral;
        (uint256 pid, uint256 stYieldTokenPerShare) = wMasterChef.decodeId(_collId);
        (, , , uint256 enYieldTokenPerShare) = IMasterChef(masterChef).poolInfo(pid);
        uint256 stYieldToken = (stYieldTokenPerShare * amount - 1) / 1e12;
        uint256 enYieldToken = (enYieldTokenPerShare * amount) / 1e12;
        if (enYieldToken > stYieldToken) {
            return enYieldToken - stYieldToken;
        }
        return 0;
    }

    /*
     * @notice Estimate price of yield tokens
     * @param _positionId ID active position
     * @param _balance contracts current yield token balance
     */
    function _valueOfYieldToken(uint256 _positionId, uint256 _balance)
        internal
        view
        returns (uint256)
    {
        uint256 estimatedYieldToken = pendingYieldToken(_positionId) + _balance;
        if (estimatedYieldToken > 0) {
            uint256[] memory yieldTokenWantValue = _uniPrice(estimatedYieldToken, yieldToken);
            return yieldTokenWantValue[1];
        } else {
            return 0;
        }
    }

    /*
     * @notice make an adjustment to the current position - this will either add to or remove assets
     *      from the current position.
     *      Removing from position:
     *          Removals will occur when the vault adapter atempts to withdraw assets from the strategy,
     *          the position will attempt to withdraw only want. If AVAX ends up being withdrawn, this will
     *          not be sold when adjusting the position.
     *      Adding to position:
     *          If additional funds have been funneled into the strategy, and a position already is running,
     *          the strategy will add the available funds to the strategy. This adjusts the current position
     *          impermanent loss and the positions price in relation to calculate the ilThreshold
     * @param _positionId ID of active position
     * @param amounts amount to adjust position by [want, AVAX], when withdrawing we will atempt to repay
     *      the AVAX amount, when adding we will borrow this amount
     * @param _collateral collateral to remove (0 if adding to position)
     * @param _borrow Will we atempt to borrow when adding to the position
     * @param _withdraw Will we add to or remove assets from the position
     */
    function _adjustPosition(
        uint256 _positionId,
        uint256[] memory _amounts,
        uint256 _collateral,
        bool _borrow,
        bool _withdraw
    ) internal {
        // adjust by removing
        if (_withdraw) {
            uint256[] memory minAmounts = new uint256[](2);
            // AHv2 std slippage = 100 BP
            minAmounts[1] =
                (_amounts[0] * (PERCENTAGE_DECIMAL_FACTOR - 100)) /
                PERCENTAGE_DECIMAL_FACTOR;
            minAmounts[0] = 0;

            // minAmount we want to get out, collateral we will burn and amount we want to repay
            RepayAmounts memory amt = _formatClose(
                minAmounts,
                _collateral,
                _amounts[1]
            );
            IHomora(homoraBank).execute(
                _positionId,
                spell,
                abi.encodeWithSignature(spellClose, address(want), wavax, amt)
            );
            // adjust by adding
        } else {
            Amounts memory amt = _formatOpen(_amounts, _borrow);
            IHomora(homoraBank).execute(
                _positionId,
                spell,
                abi.encodeWithSignature(
                    spellOpen,
                    address(want),
                    wavax,
                    amt,
                    poolId
                )
            );
        }
        // update the position data
        _setPositionData(_positionId, _amounts, false, _withdraw);
    }

    /*
     * @notice Open a new AHv2 position with market neutral leverage
     * @param amount amount of want to provide to prosition
     */
    function _openPosition(uint256 _amount) internal {
        (uint256[] memory amounts, ) = _calcSingleSidedLiq(_amount, false);
        Amounts memory amt = _formatOpen(amounts, true);
        uint256 positionId = IHomora(homoraBank).execute(
            0,
            spell,
            abi.encodeWithSignature(spellOpen, address(want), wavax, amt, poolId)
        );
        _setPositionData(positionId, amounts, true, false);
    }

    /*
     * @notice Create or update the position data for indicated position
     * @param _positionId ID of position
     * @param _amounts Amounts add/withdrawn from position
     * @param _newPosition Is the position a new one
     * @param _withdraw Was the action a withdrawal
     */
    function _setPositionData(
        uint256 _positionId,
        uint256[] memory _amounts,
        bool _newPosition,
        bool _withdraw
    ) internal {
        // get position data
        (, , uint256 collId, uint256 collateralSize) = IHomora(homoraBank)
            .getPositionInfo(_positionId);
        (address[] memory tokens, uint256[] memory debts) = IHomora(homoraBank)
            .getPositionDebts(_positionId);

        positionData storage pos = positions[_positionId];
        if (_newPosition) {
            activePosition = _positionId;
            pos.active = true;
            pos.wantOpen = _amounts;
            pos.collId = collId;
            pos.collateral = collateralSize;
            pos.debt = debts;
            emit LogNewPositionOpened(
                _positionId,
                _amounts,
                collateralSize,
                debts
            );
        } else {
            if (!_withdraw) {
                // previous position price
                uint256[] memory _openPrice = pos.wantOpen;
                _openPrice[0] += _amounts[0];
                _openPrice[1] += _amounts[1];
                pos.wantOpen = _openPrice;
            }
            pos.collateral = collateralSize;
            pos.debt = debts;
            emit LogPositionAdjusted(
                _positionId,
                _amounts,
                collateralSize,
                debts,
                _withdraw
            );
        }
    }

    /*
     * @notice Manually wind down an AHv2 position
     * @param _positionId ID of position to close
     * @param _check amount used to check AMM
     * @param _minAmount min amount to expect back from AMM (AVAX)
     */
    function forceClose(
        uint256 _positionId,
        uint256 _check,
        uint256 _minAmount
    ) external onlyAuthorized {
        uint256[] memory amounts = _uniPrice(_check, address(want));
        require(amounts[1] >= _minAmount, "forceClose: !_minAmount");
        _closePosition(_positionId, true);
    }

    /*
     * @notice Close and active AHv2 position
     * @param _positionId ID of position to close
     * @param _force Force close position, set minAmount to 0/0
     */
    function _closePosition(uint256 _positionId, bool _force) internal {
        // active position data
        positionData storage pd = positions[_positionId];
        uint256 collateral = pd.collateral;
        RepayAmounts memory amt;
        if (!_force) {
            uint256[] memory debts = pd.debt;
            // Calculate amount we expect to get out by closing the position
            // Note, expected will be [AVAX, want], as debts always will be [AVAX] and solidity doesnt support
            // sensible operations like [::-1] or zip...
            amt = _formatClose(
                _calcAvailable(collateral, debts),
                collateral,
                0
            );
        } else {
            amt = _formatClose(new uint256[](2), collateral, 0);
        }
        uint256 wantBal = want.balanceOf(address(this));
        IHomora(homoraBank).execute(
            _positionId,
            spell,
            abi.encodeWithSignature(spellClose, address(want), wavax, amt)
        );
        // Do not sell after closing down the position, AVAX/yieldToken are sold during
        //  the early stages for the harvest flow (see prepareReturn)
        // total amount of want retrieved from position
        wantBal = want.balanceOf(address(this)) - wantBal;
        positionData storage pos = positions[_positionId];
        pos.active = false;
        pos.totalClose = wantBal;
        uint256[] memory _wantClose = _uniPrice(pos.wantOpen[0], address(want));
        pos.wantClose = _wantClose;
        activePosition = 0;
        emit LogPositionClosed(_positionId, wantBal, _wantClose);
    }

    /*
     * @notice Manually sell AVAX
     * @param _minAmount min amount to recieve from the AMM
     */
    function sellAVAX(uint256 _minAmount) external onlyAuthorized {
        _sellAVAX(false, _minAmount);
    }

    /*
     * @notice sell the contracts AVAX for want if there enough to justify the sell
     * @param _useMinThreshold Use min threshold when selling, or sell everything
     */
    function _sellAVAX(bool _useMinThreshold, uint256 _minAmount)
        internal
        returns (uint256[] memory)
    {
        uint256 balance = address(this).balance;

        // check if we have enough AVAX to sell
        if (balance == 0) {
            return new uint256[](2);
        } else if (_useMinThreshold && (balance < minAVAXToSell)) {
            return new uint256[](2);
        }
        address[] memory path = new address[](2);
        path[0] = wavax;
        path[1] = address(want);

        
        // Use a call to the uniswap router contract to swap exact AVAX for want
        // note, minwant could be set to 0 here as it doesnt matter, this call
        // cannot prevent any frontrunning and the transaction should be executed
        // using a private host. When lacking a private host it needs to rely on the
        // AMM check or ues the manual see function between harvest.
        uint256[] memory amounts = uniSwapRouter.swapExactAVAXForTokens{value:balance}(
                _minAmount,
                path,
                address(this),
                block.timestamp
        );
        emit LogAVAXSold(amounts);
        return amounts;
    }

    /*
     * @notice Manually sell yield tokens
     * @param _minAmount min amount to recieve from the AMM
     */
    function sellYieldToken(uint256 _minAmount) external onlyAuthorized {
        _sellYieldToken(false, _minAmount);
    }

    /*
     * @notice sell the contracts yield tokens for want if there enough to justify the sell - can remove this method if uni swap spell
     * @param _useMinThreshold Use min threshold when selling, or sell everything
     */
    function _sellYieldToken(bool _useMinThreshold, uint256 _minAmount)
        internal
        returns (uint256[] memory)
    {
        uint256 balance = IERC20(yieldToken).balanceOf(address(this));
        if (balance == 0) {
            return new uint256[](2);
        } else if (_useMinThreshold && (balance < minYieldTokenToSell)) {
            return new uint256[](2);
        }
        address[] memory path = new address[](2);
        path[0] = yieldToken;
        path[1] = address(want);

        uint256[] memory amounts = uniSwapRouter.swapExactTokensForTokens(
            balance,
            _minAmount,
            path,
            address(this),
            block.timestamp
        );
        emit LogYieldTokenSold(amounts);
        return amounts;
    }

    /*
     * @notice format the open position input struct
     * @param _amounts Amounts for position
     * @param _borrow Decides if we want to borrow ETH or not
     */
    function _formatOpen(uint256[] memory _amounts, bool _borrow)
        internal
        pure
        returns (Amounts memory amt)
    {
        amt.aUser = _amounts[0];
        // Unless we borrow we only supply a value for the want we provide
        if (_borrow) {
            amt.bBorrow = _amounts[1];
        }
        // apply 100 BP slippage
        // NOTE: Temp fix to handle adjust position without borrow
        //      - As these transactions are run behind a private node or flashbot, it shouldnt
        //      impact anything to set minaAmount to 0
        amt.aMin = 0;
        amt.bMin = 0;
        // amt.aMin = amounts[0] * (PERCENTAGE_DECIMAL_FACTOR - 100) / PERCENTAGE_DECIMAL_FACTOR;
        // amt.bMin = amounts[1] * (PERCENTAGE_DECIMAL_FACTOR - 100) / PERCENTAGE_DECIMAL_FACTOR;
    }

    /*
     * @notice format the close position input struct
     * @param _expect expected return amounts
     * @param _collateral collateral to remove from position
     * @param _repay amount to repay - default to max value if closing position
     */
    function _formatClose(
        uint256[] memory _expected,
        uint256 _collateral,
        uint256 _repay
    ) internal pure returns (RepayAmounts memory amt) {
        _repay = (_repay == 0) ? REPAY : _repay;
        amt.lpTake = _collateral;
        amt.bRepay = _repay;
        amt.aMin = _expected[1];
        amt.bMin = _expected[0];
    }

    /*
     * @notice calculate want and AVAX value of lp position
     *      value of lp is defined by (in uniswap routerv2):
     *          lp = Math.min(input0 * poolBalance / reserve0, input1 * poolBalance / reserve1)
     *      which in turn implies:
     *          input0 = reserve0 * lp / poolBalance
     *          input1 = reserve1 * lp / poolBalance
     * @param _collateral lp amount
     * @dev Note that we swap the order of want and AVAX in the return array, this is because
     *      the debt position always will be in AVAX, and to save gas we dont add a 0 value for the
     *      want debt. So when doing repay calculations we need to remove the debt from the AVAX amount,
     *      which becomes simpler if the AVAX position comes first.
     */
    function _calcLpPosition(uint256 _collateral)
        internal
        view
        returns (uint256[] memory)
    {
        (uint112 resA, uint112 resB, ) = IUniPool(pool).getReserves();
        uint256 poolBalance = IUniPool(pool).totalSupply();
        uint256[] memory lpPosition = new uint256[](2);

        lpPosition[1] =
            ((_collateral * uint256(resA) * DEFAULT_DECIMALS_FACTOR) /
                poolBalance) /
            DEFAULT_DECIMALS_FACTOR;
        lpPosition[0] =
            ((_collateral * uint256(resB) * DEFAULT_DECIMALS_FACTOR) /
                poolBalance) /
            DEFAULT_DECIMALS_FACTOR;

        return lpPosition;
    }

    /*
     * @notice calc want value of AVAX
     * @param _AVAX amount amount of AVAX
     */
    function _calcWant(uint256 _AVAX) private view returns (uint256) {
        uint256[] memory swap = _uniPrice(_AVAX, wavax);
        return swap[1];
    }

    /*
     * @notice get swap price in uniswap pool
     * @param _amount amount of token to swap
     * @param _start token to swap out
     */
    function _uniPrice(uint256 _amount, address _start)
        internal
        view
        returns (uint256[] memory)
    {
        if (_amount == 0) {
            return new uint256[](2);
        }
        address[] memory path = new address[](2);
        if (_start == address(want)) {
            path[0] = _start;
            path[1] = wavax;
        } else {
            path[0] = _start;
            path[1] = address(want);
        }
        uint256[] memory amounts = uniSwapRouter.getAmountsOut(
            _amount,
            path
        );

        return amounts;
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        (uint256 totalAssets, ) = _estimatedTotalAssets(activePosition);
        return totalAssets;
    }

    /*
     * @notice Get the estimated total assets of this strategy in want.
     *      This method is only used to pull out debt if debt ratio has changed.
     * @param _positionId active position
     * @return Total assets in want this strategy has invested into underlying protocol and
     *      the balance of this contract as a seperate variable
     */
    function _estimatedTotalAssets(uint256 _positionId)
        private
        view
        returns (uint256, uint256)
    {
        // get the value of the current position supplied by this strategy (total - borrowed)
        uint256 yieldTokenBalance = IERC20(yieldToken).balanceOf(address(this));
        uint256[] memory _valueOfAVAX = _uniPrice(address(this).balance, wavax);
        uint256 _reserve = want.balanceOf(address(this));

        if (_positionId == 0) {
            return (
                _valueOfYieldToken(_positionId, yieldTokenBalance) +
                    _valueOfAVAX[1] +
                    _reserve,
                _reserve
            );
        }
        return (
            _reserve +
                _calcEstimatedWant(_positionId) +
                _valueOfYieldToken(_positionId, yieldTokenBalance) +
                _valueOfAVAX[1],
            _reserve
        );
    }

    /*
     * @notice expected profit/loss of the strategy
     */
    function expectedReturn() external view returns (int256) {
        return int256(estimatedTotalAssets()) - int256(vault.strategyDebt());
    }

    /*
     * @notice want value of position
     */
    function calcEstimatedWant() external view returns (uint256) {
        uint256 _positionId = activePosition;
        if (_positionId == 0) return 0;
        return _calcEstimatedWant(_positionId);
    }

    /*
     * @notice get collateral and borrowed AVAX value of position
     * @dev This value is based on Alpha homoras calculation which can
     *     be found in the homoraBank and homora Oracle (0xeed9cfb1e69792aaee0bf55f6af617853e9f29b8)
     *     (tierTokenFactors). This value can range from 0 to > 10000, where 10000 indicates liquidation
     */
    function _getCollateralFactor(uint256 _positionId)
        private
        view
        returns (uint256)
    {
        uint256 deposit = IHomora(homoraBank).getCollateralETHValue(
            _positionId
        );
        uint256 borrow = IHomora(homoraBank).getBorrowETHValue(_positionId);
        return (borrow * PERCENTAGE_DECIMAL_FACTOR) / deposit;
    }

    /*
     * @notice Calculate strategies current loss, profit and amount if can repay
     * @param _debtOutstanding amount of debt remaining to be repaid
     */
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 _positionId = activePosition;
        if (_positionId == 0) {
            // only try to sell if there is no active position
            _sellAVAX(true, 0);
            _sellYieldToken(true, 0);
            uint256 _wantBalance = want.balanceOf(address(this));
            _debtPayment = Math.min(_wantBalance, _debtOutstanding);
            return (_profit, _loss, _debtPayment);
        }

        (uint256 balance, uint256 wantBalance) = _estimatedTotalAssets(
            _positionId
        );

        uint256 debt = vault.strategies(address(this)).totalDebt;

        // Balance - Total Debt is profit
        if (balance > debt) {
            _profit = balance - debt;

            if (wantBalance < _profit) {
                // all reserve is profit
                _profit = wantBalance;
            } else if (wantBalance > _profit + _debtOutstanding) {
                _debtPayment = _debtOutstanding;
            } else {
                _debtPayment = wantBalance - _profit;
            }
        } else {
            _loss = debt - balance;
            _debtPayment = Math.min(wantBalance, _debtOutstanding);
        }
    }

    /*
     * @notice Check if price change is outside the accepted range,
     *      in which case the the opsition needs to be closed or adjusted
     */
    function volatilityCheck() public view returns (bool) {
        if (activePosition == 0) {
            return false;
        }
        uint256[] memory openPrice = positions[activePosition].wantOpen;
        (uint256[] memory currentPrice, ) = _calcSingleSidedLiq(
            openPrice[0],
            false
        );
        uint256 difference;
        if (openPrice[1] < currentPrice[1]) {
            difference =
                ((currentPrice[1] * PERCENTAGE_DECIMAL_FACTOR) / openPrice[1]) -
                PERCENTAGE_DECIMAL_FACTOR;
        } else {
            difference =
                ((openPrice[1] * PERCENTAGE_DECIMAL_FACTOR) / currentPrice[1]) -
                PERCENTAGE_DECIMAL_FACTOR;
        }
        if (difference >= ilThreshold) return true;
        return false;
    }

    /*
     * @notice calculate how much expected returns we will get when closing down our position,
     *      this involves calculating the value of the collateral for the position (lp),
     *      and repaying the existing debt to Alpha homora. Two potential outcomes can come from this:
     *          - the position returns more AVAX than debt:
     *              in which case the strategy will collect the AVAX and atempt to sell it
     *          - the position returns less AVAX than the debt:
     *              Alpha homora will repay the debt by swapping part of the want to AVAX, we
     *              need to reduce the expected return amount of want by how much we will have to repay
     * @param _collateral lp value of position
     * @param _debts debts to repay (should always be AVAX)
     */
    function _calcAvailable(uint256 _collateral, uint256[] memory _debts)
        private
        view
        returns (uint256[] memory)
    {
        // get underlying value of lp postion [AVAX, want]
        uint256[] memory lpPosition = _calcLpPosition(_collateral);
        uint256[] memory expected = new uint256[](2);

        // standrad AH exit applies 1% slippage to close position
        lpPosition[0] =
            (lpPosition[0] * (PERCENTAGE_DECIMAL_FACTOR - 100)) /
            PERCENTAGE_DECIMAL_FACTOR;
        lpPosition[1] =
            (lpPosition[1] * (PERCENTAGE_DECIMAL_FACTOR - 100)) /
            PERCENTAGE_DECIMAL_FACTOR;

        // if the AVAX debt is greater than the positions AVAX value, we need to reduce the the expected want by the amount
        // that will be used to repay the whole AVAX loan
        if (lpPosition[0] < _debts[0]) {
            uint256[] memory change = _uniPrice(
                _debts[0] - lpPosition[0],
                wavax
            );
            expected[1] = lpPosition[1] - change[1];
            expected[0] = 0;
        } else {
            // repay AVAX debt
            expected[0] = lpPosition[0] - _debts[0];
            expected[1] = lpPosition[1];
        }

        return expected;
    }

    /*
     * @notice calculate how much want our collateral - debt is worth
     * @param _positionId id of position
     */
    function _calcEstimatedWant(uint256 _positionId)
        private
        view
        returns (uint256)
    {
        positionData storage pos = positions[_positionId];
        // get underlying value of lp postion [AVAX, want]
        uint256[] memory lpPosition = _calcLpPosition(pos.collateral);
        uint256[] memory debt = pos.debt;
        int256 AVAXPosition = int256(lpPosition[0]) - int256(debt[0]);
        return
            (AVAXPosition > 0)
                ? lpPosition[1] + _calcWant(uint256(AVAXPosition))
                : lpPosition[1] - _calcWant(uint256(AVAXPosition * -1));
    }

    /*
     * @notice Calculate how much AVAX needs to be provided for a set amount of want
     *      when adding liquidity - This is used to estimate how much to borrow from AH.
     *      We need to get amtA * resB - amtB * resA = 0 to solve the AH optimal swap
     *      formula for 0, so we use same as uniswap rouer quote function:
     *          amountA * reserveB / reserveA
     * @param _amount amount of want
     * @param _withdraw we need to calculate the liquidity amount if withdrawing
     * @dev We uesr the uniswap formula to calculate liquidity
     *          lp = Math.min(input0 * poolBalance / reserve0, input1 * poolBalance / reserve1)
     */
    function _calcSingleSidedLiq(uint256 _amount, bool _withdraw)
        internal
        view
        returns (uint256[] memory, uint256)
    {
        (uint112 reserve0, uint112 reserve1, ) = IUniPool(pool).getReserves();
        uint256[] memory amt = new uint256[](2);
        amt[1] = (_amount * reserve1) / reserve0;
        amt[0] = _amount; //amt[1] * reserve0 / reserve1;
        if (_withdraw) {
            uint256 poolBalance = IUniPool(pool).totalSupply();
            uint256 liquidity = Math.min(
                (amt[0] * poolBalance) / reserve0,
                (amt[1] * poolBalance) / reserve1
            );
            return (amt, liquidity);
        }
        return (amt, 0);
    }

    /*
     * @notice partially removes or closes the current AH v2 position in order to repay a requested amount
     * @param _amountNeeded amount needed to be withdrawn from strategy
     * @dev This function will atempt to remove part of the current position in order to repay debt or accomodate a withdrawal,
     *      This is a gas costly operation, should not be atempted unless the amount being withdrawn warrants it.
     */
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256, uint256)
    {
        uint256 _amountFreed = 0;
        uint256 _loss = 0;
        // want in contract + want value of position based of AVAX value of position (total - borrowed)
        uint256 _positionId = activePosition;

        (uint256 assets, uint256 _balance) = _estimatedTotalAssets(_positionId);

        uint256 debt = vault.strategyDebt();

        // cannot repay the entire debt
        if (debt > assets) {
            _loss = debt - assets;
            if (_loss >= _amountNeeded) {
                _loss = _amountNeeded;
                _amountFreed = 0;
                return (_amountFreed, _loss);
            }
            _amountNeeded = _amountNeeded - _loss;
        }

        // if the asset value of our position is less than what we need to withdraw, close the position
        if (assets < _amountNeeded) {
            if (activePosition != 0) {
                _closePosition(_positionId, false);
            }
            _sellAVAX(false, 0);
            _sellYieldToken(false, 0);
            _amountFreed = Math.min(
                _amountNeeded,
                want.balanceOf(address(this))
            );
            return (_amountFreed, _loss);
        } else {
            // do we have enough assets in strategy to repay?
            int256 changeFactor = int256(_getCollateralFactor(_positionId)) -
                int256(targetCollateralRatio);
            if (_balance < _amountNeeded) {
                uint256 remainder;
                if (changeFactor > 500) {
                    _closePosition(_positionId, false);
                    _amountFreed = Math.min(
                        _amountNeeded,
                        want.balanceOf(address(this))
                    );
                    return (_amountFreed, _loss);
                }
                // because pulling out assets from AHv2 tends to give us less assets than
                // we want specify, so lets see if we can pull out a bit in excess to be
                // able to pay back the full amount
                if (assets > _amountNeeded - _balance / 2) {
                    remainder = _amountNeeded - _balance / 2;
                } else {
                    // but if not possible just pull the original amount
                    remainder = _amountNeeded - _balance;
                }

                // if we want to remove 80% or more of the position, just close it
                if ((remainder * PERCENTAGE_DECIMAL_FACTOR) / assets >= 8000) {
                    _closePosition(_positionId, false);
                } else {
                    (
                        uint256[] memory repay,
                        uint256 lpAmount
                    ) = _calcSingleSidedLiq(remainder, true);
                    _adjustPosition(_positionId, repay, lpAmount, false, true);
                }

                // dont return more than was asked for
                _amountFreed = Math.min(
                    _amountNeeded,
                    want.balanceOf(address(this))
                );
            } else {
                _amountFreed = _amountNeeded;
            }
            return (_amountFreed, _loss);
        }
    }

    /*
     * @notice adjust current position, repaying any debt
     * @param _debtOutstanding amount of outstanding debt the strategy holds
     * @dev _debtOutstanding should always be 0 here, but we should handle the
     *      eventuality that something goes wrong in the reporting, in which case
     *      this strategy should act conservative and atempt to repay any outstanding amount
     */
    function _adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in liquidatePosition
        if (emergencyExit) {
            return;
        }

        uint256 _positionId = activePosition;
        if (_positionId > 0 && volatilityCheck()) {
            _closePosition(_positionId, false);
            return;
        }
        //we are spending all our cash unless we have debt outstanding
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal < _debtOutstanding && _positionId != 0) {
            // just close the position if the collateralisation ratio is to high
            if (_getCollateralFactor(_positionId) > collateralThreshold) {
                _closePosition(_positionId, false);
                // otherwise do a partial withdrawal
            } else {
                (
                    uint256[] memory repay,
                    uint256 lpAmount
                ) = _calcSingleSidedLiq(_debtOutstanding - _wantBal, true);
                _adjustPosition(_positionId, repay, lpAmount, false, true);
            }
            return;
        }

        // check if the current want amount is large enough to justify opening/adding
        // to an existing position, else do nothing
        if (_wantBal > minWant) {
            if (_positionId == 0) {
                _wantBal = _wantBal > borrowLimit ? borrowLimit : _wantBal;
                _openPosition(_wantBal);
            } else {
                int256 changeFactor = int256(
                    _getCollateralFactor(_positionId)
                ) - int256(targetCollateralRatio);
                // collateralFactor is real bad close the position
                if (
                    changeFactor >
                    int256(collateralThreshold - targetCollateralRatio)
                ) {
                    _closePosition(_positionId, false);
                    return;
                    // collateral factor is bad (5% above target), dont loan any more assets
                } else if (changeFactor > 500) {
                    // we expect to swap out half of the want to AVAX
                    (uint256[] memory newPosition, ) = _calcSingleSidedLiq(
                        (_wantBal) / 2,
                        false
                    );
                    newPosition[0] = _wantBal;
                    _adjustPosition(_positionId, newPosition, 0, false, false);
                } else {
                    // TODO logic to lower the colateral ratio
                    // When adding to the position we will try to stabilize the collateralization ratio, this
                    //  will be possible if we owe more than originally, as we just need to borrow less AVAX
                    //  from AHv2. The opposit will currently not work as we want to avoid taking on want
                    //  debt from AHv2.

                    // else if (changeFactor > 0) {
                    //     // See what the % of the position the current pos is
                    //     uint256 assets = _calcEstimatedWant(_positionId);
                    //     uint256[] memory oldPrice = positions[_positionId].openWant;
                    //     uint256 newPercentage = (newPosition[0] * PERCENTAGE_DECIMAL_FACTOR / oldPrice[0])
                    // }
                    uint256 posWant = positions[_positionId].wantOpen[0];
                    _wantBal = _wantBal + posWant > borrowLimit
                        ? borrowLimit - posWant
                        : _wantBal;
                    (uint256[] memory newPosition, ) = _calcSingleSidedLiq(
                        _wantBal,
                        false
                    );
                    _adjustPosition(_positionId, newPosition, 0, true, false);
                }
            }
        }
    }

    /*
     * @notice tokens that cannot be removed from this strategy (on top of want which is protected by default)
     */
    function _protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
        protected[0] = yieldToken;
        return protected;
    }

    /*
     * @notice tokens that cannot be removed from this strategy (on top of want which is protected by default)
     * @param _callCost Cost of calling tend in want (not used here)
     */
    function tendTrigger(uint256 _callCost)
        public
        view
        override
        returns (bool)
    {
        if (activePosition == 0) return false;
        if (volatilityCheck()) return true;
        if (_getCollateralFactor(activePosition) > collateralThreshold)
            return true;
        return false;
    }

    /*
     * @notice prepare this strategy for migrating to a new
     * @param _newStrategy address of migration target (not used here)
     */
    function _prepareMigration(address _newStrategy) internal override {
        require(activePosition == 0, "prepareMigration: active position");
        _sellAVAX(false, 0);
        _sellYieldToken(false, 0);
    }

    /*
     * @notice Check that an external minAmount is achived when interacting with the AMM
     * @param amount amount to swap
     * @param _minAmount expected minAmount to get out from swap
     */
    function ammCheck(uint256 _amount, uint256 _minAmount)
        external
        view
        override
        returns (bool)
    {
        uint256[] memory amounts = _uniPrice(_amount, address(want));
        return (amounts[1] >= _minAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct StrategyParams {
    uint256 activation;
    bool active;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI {
    function decimals() external view returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    function strategyDebt() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    function owner() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function tendTrigger(uint256 _callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 _callCost) external view returns (bool);

    function harvest() external;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */
abstract contract BaseStrategy {
    using SafeERC20 for IERC20;

    VaultAPI public vault;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
    event UpdatedKeeper(address newKeeper);
    event UpdatedRewards(address rewards);
    event UpdatedMinReportDelay(uint256 delay);
    event UpdatedMaxReportDelay(uint256 delay);
    event UpdatedProfitFactor(uint256 profitFactor);
    event UpdatedDebtThreshold(uint256 debtThreshold);
    event EmergencyExitEnabled();

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `_callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == keeper || msg.sender == _owner(), "!authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner(), "!authorized");
        _;
    }

    constructor(address _vault) {
        vault = VaultAPI(_vault);
        want = IERC20(VaultAPI(_vault).token());
        want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
        rewards = msg.sender;
        keeper = msg.sender;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;
    }

    function name() external view virtual returns (string memory);

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "setKeeper: _keeper == 0x");
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        require(
            _delay < maxReportDelay,
            "setMinReportDelay: _delay > maxReportDelay"
        );
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        require(
            _delay > minReportDelay,
            "setMaxReportDelay: _delay < minReportDelay"
        );
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        require(_profitFactor <= 1000, "setProfitFactor: _profitFactor > 1000");
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold)
        external
        virtual
        onlyAuthorized
    {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * Resolve owner address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function _owner() internal view returns (address) {
        return vault.owner();
    }

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to owner to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return
            vault.strategies(address(this)).debtRatio > 0 ||
            estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 profit,
            uint256 loss,
            uint256 debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `_prepareReturn()`.
     */
    function _adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     * This function is used during emergency exit instead of `_prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     *
     * NOTE: The invariant `liquidatedAmount + loss <= _amountNeeded` should always be maintained
     */
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 liquidatedAmount, uint256 loss);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `_callCost` must be priced in terms of `want`.
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param _callCost The keeper's estimated cast cost to call `tend()`.
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 _callCost) public view virtual returns (bool);

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `_adjustPosition()`.
     *
     */
    function tend() external onlyAuthorized {
        // Don't take profits with this call, but adjust for better gains
        _adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `_callCost` must be priced in terms of `want`.
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold`
     *  -controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param _callCost The keeper's estimated cast cost to call `harvest()`.
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 _callCost)
        public
        view
        virtual
        returns (bool)
    {
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if Strategy is not activated
        if (params.activation == 0) return false;

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp - params.lastReport < minReportDelay) return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp - params.lastReport >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total + debtThreshold < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total - params.totalDebt; // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor * _callCost < credit + profit);
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external {
        require(msg.sender == address(vault), "harvest: !vault");
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 totalAssets = estimatedTotalAssets();
            // NOTE: use the larger of total assets or debt outstanding to book losses properly
            (debtPayment, loss) = _liquidatePosition(
                totalAssets > debtOutstanding ? totalAssets : debtOutstanding
            );
            // NOTE: take up any remainder here as profit
            if (debtPayment > debtOutstanding) {
                profit = debtPayment - debtOutstanding;
                debtPayment = debtOutstanding;
            }
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = _prepareReturn(debtOutstanding);
        }
        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        _adjustPosition(debtOutstanding);

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, loss) = _liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        if (amountFreed > 0) want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function _prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by owner or the Vault.
     * @dev
     *  The new Strategy's Vault must be the same as this Strategy's Vault.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        _prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     *
     *    function _protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     */
    function _protectedTokens()
        internal
        view
        virtual
        returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `_owner()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by owner.
     * @dev
     *  Implement `_protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyOwner {
        require(_token != address(want), "sweep: !want");
        require(_token != address(vault), "sweep: !shares");

        address[] memory protectedTokens = _protectedTokens();
        for (uint256 i; i < protectedTokens.length; i++)
            require(_token != protectedTokens[i], "sweep: !protected");

        IERC20(_token).safeTransfer(
            _owner(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    function ammCheck(uint256 _amount, uint256 _minAmount)
        external
        view
        virtual
        returns (bool)
    {
        return true;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

contract Constants {
    uint8 internal constant DEFAULT_DECIMALS = 18;
    uint256 internal constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 internal constant PERCENTAGE_DECIMALS = 4;
    uint256 internal constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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