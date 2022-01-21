// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IYUSDToken.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/ISYETI.sol";
import "./Interfaces/IWhitelist.sol";
import "./Interfaces/IYetiRouter.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Interfaces/IERC20.sol";

/** 
 * BorrowerOperations is the contract that handles most of external facing trove activities that 
 * a user would make with their own trove, like opening, closing, adjusting, increasing leverage, etc.
 */

 /**
   A summary of Lever Up:
   Takes in a collateral token A, and simulates borrowing of YUSD at a certain collateral ratio and
   buying more token A, putting back into protocol, buying more A, etc. at a certain leverage amount.
   So if at 3x leverage and 1000$ token A, it will mint 1000 * 3x * 2/3 = $2000 YUSD, then swap for
   token A by using some router strategy, returning a little under $2000 token A to put back in the
   trove. The number here is 2/3 because the math works out to be that collateral ratio is 150% if
   we have a 3x leverage. They now have a trove with $3000 of token A and a collateral ratio of 150%.
  */

contract BorrowerOperations is LiquityBase, Ownable, CheckContract, IBorrowerOperations {
    string public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager public troveManager;

    address stabilityPoolAddress;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    ISYETI public sYETI;
    address public sYETIAddress;

    IYUSDToken public yusdToken;

    uint public constant BOOTSTRAP_PERIOD = 14 days;
    uint deploymentTime;

    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    struct CollateralData {
        address collateral;
        uint256 amount;
    }

    struct DepositFeeCalc {
        uint256 collateralYUSDFee;
        uint256 systemCollateralVC;
        uint256 collateralInputVC;
        uint256 systemTotalVC;
        address token;
    }

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */
    struct AdjustTrove_Params {
        address[] _collsIn;
        uint256[] _amountsIn;
        address[] _collsOut;
        uint256[] _amountsOut;
        uint256[] _maxSlippages;
        uint256 _YUSDChange;
        uint256 _totalYUSDDebtFromLever;
        bool _isDebtIncrease;
        bool _isUnlever;
        address _upperHint;
        address _lowerHint;
        uint256 _maxFeePercentage;
    }

    struct LocalVariables_adjustTrove {
        uint256 netDebtChange;
        bool isCollIncrease;
        uint256 collChange;
        uint256 currVC;
        uint256 newVC;
        uint256 debt;
        address[] currAssets;
        uint256[] currAmounts;
        address[] newAssets;
        uint256[] newAmounts;
        uint256 oldICR;
        uint256 newICR;
        uint256 newTCR;
        uint256 YUSDFee;
        uint256 variableYUSDFee;
        uint256 newDebt;
        uint256 VCin;
        uint256 VCout;
        uint256 maxFeePercentageFactor;
    }

    struct LocalVariables_openTrove {
        address[] collaterals;
        uint256[] prices;
        uint256 YUSDFee;
        uint256 netDebt;
        uint256 compositeDebt;
        uint256 ICR;
        uint256 arrayIndex;
        address collAddress;
        uint256 VC;
        uint256 newTCR;
        bool isRecoveryMode;
    }

    struct CloseTrove_Params {
        address[] _collsOut;
        uint256[] _amountsOut;
        uint256[] _maxSlippages;
        bool _isUnlever;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        IActivePool activePool;
        IYUSDToken yusdToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event YUSDTokenAddressChanged(address _yusdTokenAddress);
    event SYETIAddressChanged(address _sYETIAddress);

    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        address[] _tokens,
        uint256[] _amounts,
        BorrowerOperation operation
    );
    event YUSDBorrowingFeePaid(address indexed _borrower, uint256 _YUSDFee);

    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _sortedTrovesAddress,
        address _yusdTokenAddress,
        address _sYETIAddress,
        address _whitelistAddress
    ) external override onlyOwner {
        // This makes impossible to open a trove with zero withdrawn YUSD
        assert(MIN_NET_DEBT > 0);

        deploymentTime = block.timestamp;

        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_yusdTokenAddress);
        checkContract(_sYETIAddress);
        checkContract(_whitelistAddress);

        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        whitelist = IWhitelist(_whitelistAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        sYETIAddress = _sYETIAddress;

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit YUSDTokenAddressChanged(_yusdTokenAddress);
        emit SYETIAddressChanged(_sYETIAddress);

        _renounceOwnership();
    }

    // --- Borrower Trove Operations ---

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts
    ) external override {
        require(_amounts.length != 0, "Amounts == 0");
        _requireValidDepositCollateral(_colls, _amounts);
        _requireNoDuplicateColls(_colls); // Check that there is no overlap in _colls

        // transfer collateral into ActivePool
        require(
            _transferCollateralsIntoActivePool(msg.sender, _colls, _amounts),
            "BOps: Transfer collateral into ActivePool failed"
        );

        _openTroveInternal(
            msg.sender,
            _maxFeePercentage,
            _YUSDAmount,
            0,
            _upperHint,
            _lowerHint,
            _colls,
            _amounts
        );
    }

    // Lever up. Takes in a leverage amount (11x) and a token, and calculates the amount
    // of that token that would be at the specific collateralization ratio. Mints YUSD
    // according to the price of the token and the amount. Calls LeverUp.sol's
    // function to perform the swap through a router or our special staked tokens, depending
    // on the token. Then opens a trove with the new collateral from the swap, ensuring that
    // the amount is enough to cover the debt. There is no new debt taken out from the trove,
    // and the amount minted previously is attributed to this trove. Reverts if the swap was
    // not able to get the correct amount of collateral according to slippage passed in.
    // _leverage is like 11e18 for 11x. 
    // function openTroveLeverUp(
    //     uint256 _maxFeePercentage,
    //     uint256 _YUSDAmount,
    //     address _upperHint,
    //     address _lowerHint,
    //     address[] memory _colls,
    //     uint256[] memory _amounts, 
    //     uint256[] memory _leverages,
    //     uint256[] memory _maxSlippages
    // ) external override {
    //     require(_colls.length != 0, "Must pass in collateral");
    //     _requireValidDepositCollateral(_colls, _amounts);
    //     require(_colls.length == _leverages.length);
    //     require(_colls.length == _maxSlippages.length);
    //     _requireNoDuplicateColls(_colls);
    //     uint additionalTokenAmount;
    //     uint additionalYUSDDebt;
    //     uint totalYUSDDebtFromLever;
    //     for (uint i = 0; i < _colls.length; i++) {
    //         if (_leverages[i] != 0) {
    //             (additionalTokenAmount, additionalYUSDDebt) = _singleLeverUp(
    //                 _colls[i],
    //                 _amounts[i],
    //                 _leverages[i],
    //                 _maxSlippages[i]
    //             );
    //             // Transfer into active pool, non levered amount. 
    //             require(
    //                 _singleTransferCollateralIntoActivePool(msg.sender, _colls[i], _amounts[i]),
    //                 "BOps: Transfer collateral into ActivePool failed"
    //             );
    //             // additional token amount was set to the original amount * leverage. 
    //             _amounts[i] = additionalTokenAmount.add(_amounts[i]);
    //             totalYUSDDebtFromLever = totalYUSDDebtFromLever.add(additionalYUSDDebt);
    //         } else {
    //             // Otherwise skip and do normal transfer that amount into active pool. 
    //             require(
    //                 _singleTransferCollateralIntoActivePool(msg.sender, _colls[i], _amounts[i]),
    //                 "BOps: Transfer collateral into ActivePool failed"
    //             );
    //         }
    //     }
    //     _YUSDAmount = _YUSDAmount.add(totalYUSDDebtFromLever);
        
    //     _openTroveInternal(
    //         msg.sender,
    //         _maxFeePercentage,
    //         _YUSDAmount,
    //         totalYUSDDebtFromLever,
    //         _upperHint,
    //         _lowerHint,
    //         _colls,
    //         _amounts
    //     );
    // }

    // internal function for minting yusd at certain leverage and max slippage, and then performing 
    // swap with whitelist's approved router. 
    // function _singleLeverUp(address _token, 
    //     uint256 _amount, 
    //     uint256 _leverage, 
    //     uint256 _maxSlippage) 
    //     internal
    //     returns (uint256 _finalTokenAmount, uint256 _additionalYUSDDebt) {
    //     require(_leverage > 1e18, "leverage must be higher than 1");
    //     require(_maxSlippage <= 1e18, "max slippage must be less than 1");
    //     IYetiRouter router = IYetiRouter(whitelist.getDefaultRouterAddress(_token));
    //     // leverage is 5e18 for 5x leverage. Minus 1 for what the user already has in collateral value.
    //     uint _additionalTokenAmount = _amount.mul(_leverage.sub(1e18)).div(1e18); 
    //     uint _additionalYUSDDebt = whitelist.getValueVC(_token, _additionalTokenAmount);

    //     // 1/(1-1/ICR) = leverage. (1 - 1/ICR) = 1/leverage
    //     // 1 - 1/leverage = 1/ICR. ICR = 1/(1 - 1/leverage) = (1/((leverage-1)/leverage)) = leverage / (leverage - 1)
    //     // ICR = leverage / (leverage - 1)
        
    //     // ICR = VC value of collateral / debt 
    //     // debt = VC value of collateral / ICR.
    //     // debt = VC value of collateral * (leverage - 1) / leverage

    //     uint256 slippageAdjustedValue = _additionalTokenAmount.mul(DECIMAL_PRECISION.sub(_maxSlippage)).div(1e18);
        
    //     yusdToken.mint(address(this), _additionalYUSDDebt);
    //     yusdToken.approve(address(router), _additionalYUSDDebt);
    //     // route will swap the tokens and transfer it to the active pool automatically 
    //     _finalTokenAmount = router.route(address(this), address(yusdToken), _token, _additionalYUSDDebt, slippageAdjustedValue);
    //     // TODO do checks of raw balance? Currently is abstracted so the router handles it.
    //     return (_finalTokenAmount, _additionalYUSDDebt);
    // }


    // amounts should be a uint array giving the amount of each collateral
    // to be transferred in in order of the current whitelist
    // Should be called *after* collateral has been already sent to the active pool
    // Should confirm _colls, is valid collateral prior to calling this
    function _openTroveInternal(
        address _troveOwner,
        uint256 _maxFeePercentage,
        uint256 _YUSDAmount,
        uint256 _totalYUSDDebtFromLever,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal {
        LocalVariables_openTrove memory vars;

        vars.isRecoveryMode = _checkRecoveryMode();

        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, yusdToken);

        _requireValidMaxFeePercentage(_maxFeePercentage, vars.isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager, _troveOwner);

        vars.netDebt = _YUSDAmount;

        // For every collateral type in, calculate the VC and get the variable fee
        vars.VC = _getVC(_colls, _amounts);

        if (!vars.isRecoveryMode) {
            // when not in recovery mode, add in the 0.5% fee
            vars.YUSDFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.yusdToken,
                _YUSDAmount,
                vars.VC, // here it is just VC in, which is always larger than YUSD amount
                _maxFeePercentage
            );
            _maxFeePercentage = _maxFeePercentage.sub(vars.YUSDFee.mul(DECIMAL_PRECISION).div(vars.VC));
        }

        // Add in variable fee. Always present, even in recovery mode.
        vars.YUSDFee = vars.YUSDFee.add(
            _getTotalVariableDepositFee(_colls, _amounts, vars.VC, 0, vars.VC, _maxFeePercentage, contractsCache)
        );

        // Adds total fees to netDebt
        vars.netDebt = vars.netDebt.add(vars.YUSDFee); // The raw debt change includes the fee

        _requireAtLeastMinNetDebt(vars.netDebt);
        // ICR is based on the composite debt, i.e. the requested YUSD amount + YUSD borrowing fee + YUSD gas comp.
        // _getCompositeDebt returns  vars.netDebt + YUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);

        vars.ICR = LiquityMath._computeCR(vars.VC, vars.compositeDebt);
        if (vars.isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            vars.newTCR = _getNewTCRFromTroveChange(vars.VC, true, vars.compositeDebt, true); // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(vars.newTCR);
        }

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveStatus(_troveOwner, 1);

        contractsCache.troveManager.updateTroveColl(_troveOwner, _colls, _amounts);
        contractsCache.troveManager.increaseTroveDebt(_troveOwner, vars.compositeDebt);

        contractsCache.troveManager.updateTroveRewardSnapshots(_troveOwner);

        contractsCache.troveManager.updateStakeAndTotalStakes(_troveOwner);

        sortedTroves.insert(_troveOwner, vars.ICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(_troveOwner);
        emit TroveCreated(_troveOwner, vars.arrayIndex);

        contractsCache.activePool.receiveCollateral(_colls, _amounts);

        _withdrawYUSD(
            contractsCache.activePool,
            contractsCache.yusdToken,
            _troveOwner,
            _YUSDAmount.sub(_totalYUSDDebtFromLever),
            vars.netDebt
        );

        // Move the YUSD gas compensation to the Gas Pool
        _withdrawYUSD(
            contractsCache.activePool,
            contractsCache.yusdToken,
            gasPoolAddress,
            YUSD_GAS_COMPENSATION,
            YUSD_GAS_COMPENSATION
        );

        require(true == false, "reverts");

        emit TroveUpdated(
            _troveOwner,
            vars.compositeDebt,
            _colls,
            _amounts,
            BorrowerOperation.openTrove
        );
        emit YUSDBorrowingFeePaid(_troveOwner, vars.YUSDFee);
    }


    // add collateral to trove. Calls _adjustTrove with correct params. 
    function addColl(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address _upperHint,
        address _lowerHint, 
        uint256 _maxFeePercentage
    ) external override {
        AdjustTrove_Params memory params;
        params._collsIn = _collsIn;
        params._amountsIn = _amountsIn;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._maxFeePercentage = _maxFeePercentage;

        // check that all _collsIn collateral types are in the whitelist
        _requireValidDepositCollateral(params._collsIn, params._amountsIn);
        _requireNoDuplicateColls(params._collsIn); // Check that there is no overlap with in or out in itself

        // pull in deposit collateral
        require(
            _transferCollateralsIntoActivePool(msg.sender, params._collsIn, params._amountsIn),
            "BOps: Failed to transfer collateral into active pool"
        );
        _adjustTrove(params);
    }


    // add collateral to trove. Calls _adjustTrove with correct params.
    // function addCollLeverUp(
    //     address[] memory _collsIn,
    //     uint256[] memory _amountsIn,
    //     uint256[] memory _leverages,
    //     uint256[] memory _maxSlippages,
    //     uint256 _YUSDAmount,
    //     address _upperHint,
    //     address _lowerHint, 
    //     uint256 _maxFeePercentage
    // ) external override {
    //     AdjustTrove_Params memory params;
    //     params._upperHint = _upperHint;
    //     params._lowerHint = _lowerHint;
    //     params._maxFeePercentage = _maxFeePercentage;

    //     // check that all _collsIn collateral types are in the whitelist
    //     require(_collsIn.length != 0);
    //     _requireValidDepositCollateral(params._collsIn, params._amountsIn);
    //     require(_collsIn.length == _leverages.length);
    //     require(_collsIn.length == _maxSlippages.length);
    //     _requireNoDuplicateColls(params._collsIn); // Check that there is no overlap with in or out in itself

    //     uint additionalTokenAmount;
    //     uint additionalYUSDDebt;
    //     uint totalYUSDDebtFromLever;
    //     for (uint i = 0; i < _collsIn.length; i++) {
    //         if (_leverages[i] != 0) {
    //             (additionalTokenAmount, additionalYUSDDebt) = _singleLeverUp(
    //                 _collsIn[i],
    //                 _amountsIn[i],
    //                 _leverages[i],
    //                 _maxSlippages[i]
    //             );
    //             // Transfer into active pool, non levered amount. 
    //             require(
    //                 _singleTransferCollateralIntoActivePool(msg.sender, _collsIn[i], _amountsIn[i]),
    //                 "BOps: Transfer collateral into ActivePool failed"
    //             );
    //             // additional token amount was set to the original amount * leverage. 
    //             _amountsIn[i] = additionalTokenAmount.add(_amountsIn[i]);
    //             totalYUSDDebtFromLever = totalYUSDDebtFromLever.add(additionalYUSDDebt);
    //         } else {
    //             // Otherwise skip and do normal transfer that amount into active pool. 
    //             require(
    //                 _singleTransferCollateralIntoActivePool(msg.sender, _collsIn[i], _amountsIn[i]),
    //                 "BOps: Transfer collateral into ActivePool failed"
    //             );
    //         }
    //     }
    //     _YUSDAmount = _YUSDAmount.add(totalYUSDDebtFromLever);
    //     params._totalYUSDDebtFromLever = totalYUSDDebtFromLever;

    //     params._YUSDChange = _YUSDAmount;
    //     params._isDebtIncrease = true;

    //     params._collsIn = _collsIn;
    //     params._amountsIn = _amountsIn;
    //     _adjustTrove(params);
    // }

    // Withdraw collateral from a trove. Calls _adjustTrove with correct params. 

    function withdrawColl(
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        address _upperHint,
        address _lowerHint
    ) external override {
        AdjustTrove_Params memory params;
        params._collsOut = _collsOut;
        params._amountsOut = _amountsOut;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        _adjustTrove(params);
    }

    // Withdraw YUSD tokens from a trove: mint new YUSD tokens to the owner, and increase the trove's debt accordingly. 
    // Calls _adjustTrove with correct params. 
    function withdrawYUSD(
        uint256 _maxFeePercentage,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        AdjustTrove_Params memory params;
        params._YUSDChange = _YUSDAmount;
        params._maxFeePercentage = _maxFeePercentage;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._isDebtIncrease = true;
        _adjustTrove(params);
    }

    // Repay YUSD tokens to a Trove: Burn the repaid YUSD tokens, and reduce the trove's debt accordingly. 
    // Calls _adjustTrove with correct params. 
    function repayYUSD(
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        AdjustTrove_Params memory params;
        params._YUSDChange = _YUSDAmount;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._isDebtIncrease = false;
        _adjustTrove(params);
    }

    // Adjusts trove with multiple colls in / out. Calls _adjustTrove with correct params.
    function adjustTrove(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        uint256 _YUSDChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external override {
        // check that all _collsIn collateral types are in the whitelist
        _requireValidDepositCollateral(_collsIn, _amountsIn);
        _requireValidDepositCollateral(_collsOut, _amountsOut);
        _requireNoOverlapColls(_collsIn, _collsOut); // check that there are no overlap between _collsIn and _collsOut
        _requireNoDuplicateColls(_collsOut);

        // pull in deposit collateral
        require(
            _transferCollateralsIntoActivePool(msg.sender, _collsIn, _amountsIn),
            "BOps: Failed to transfer collateral into active pool"
        );
        uint256[] memory maxSlippages = new uint256[](0);

        AdjustTrove_Params memory params = AdjustTrove_Params(
            _collsIn,
            _amountsIn,
            _collsOut,
            _amountsOut,
            maxSlippages,
            _YUSDChange,
            0,
            _isDebtIncrease,
            false,
            _upperHint,
            _lowerHint,
            _maxFeePercentage
        );

        _adjustTrove(params);
    }

    /*
     * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
     * the ith element of _amountsIn and _amountsOut corresponds to the ith element of the addresses _collsIn and _collsOut passed in
     *
     * Should be called after the collsIn has been sent to ActivePool
     */
    function _adjustTrove(AdjustTrove_Params memory params) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, yusdToken);
        LocalVariables_adjustTrove memory vars;

        bool isRecoveryMode = _checkRecoveryMode();

        if (params._isDebtIncrease) {
            _requireValidMaxFeePercentage(params._maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(params._YUSDChange);
        }

        _requireNonZeroAdjustment(params._amountsIn, params._amountsOut, params._YUSDChange);
        _requireTroveisActive(contractsCache.troveManager, msg.sender);

        contractsCache.troveManager.applyPendingRewards(msg.sender);
        vars.netDebtChange = params._YUSDChange;

        vars.VCin = _getVC(params._collsIn, params._amountsIn);
        vars.VCout = _getVC(params._collsOut, params._amountsOut);

        if (params._isDebtIncrease) {
            vars.maxFeePercentageFactor = _max(vars.VCin, params._YUSDChange);
        } else {
            vars.maxFeePercentageFactor = vars.VCin;
        }
        
        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (params._isDebtIncrease && !isRecoveryMode) {
            vars.YUSDFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.yusdToken,
                params._YUSDChange,
                vars.maxFeePercentageFactor, // max of VC in and YUSD change here to see what the max borrowing fee is triggered on.
                params._maxFeePercentage
            );
            // passed in max fee minus actual fee percent applied so far
            params._maxFeePercentage = params._maxFeePercentage.sub(vars.YUSDFee.mul(DECIMAL_PRECISION).div(vars.maxFeePercentageFactor)); 
            vars.netDebtChange = vars.netDebtChange.add(vars.YUSDFee); // The raw debt change includes the fee
        }

        // get current portfolio in trove
        (vars.currAssets, vars.currAmounts) = contractsCache.troveManager.getTroveColls(msg.sender);
        // current VC based on current portfolio and latest prices
        vars.currVC = _getVC(vars.currAssets, vars.currAmounts);

        // get new portfolio in trove after changes. Will error if invalid changes:
        (vars.newAssets, vars.newAmounts) = _getNewPortfolio(
            vars.currAssets,
            vars.currAmounts,
            params._collsIn,
            params._amountsIn,
            params._collsOut,
            params._amountsOut
        );
        // new VC based on new portfolio and latest prices
        vars.newVC = _getVC(vars.newAssets, vars.newAmounts);

        vars.isCollIncrease = vars.newVC > vars.currVC;
        vars.collChange = 0;
        if (vars.isCollIncrease) {
            vars.collChange = (vars.newVC).sub(vars.currVC);
        } else {
            vars.collChange = (vars.currVC).sub(vars.newVC);
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(msg.sender);

        if (params._collsIn.length > 0) {
            vars.variableYUSDFee = _getTotalVariableDepositFee(
                    params._collsIn,
                    params._amountsIn,
                    vars.VCin,
                    vars.VCout,
                    vars.maxFeePercentageFactor,
                    params._maxFeePercentage,
                    contractsCache
            );
        }

        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.currVC, vars.debt);

        vars.debt = vars.debt.add(vars.variableYUSDFee); 

        vars.newICR = _getNewICRFromTroveChange(vars.newVC,
            vars.debt, // with variableYUSDFee already added. 
            vars.netDebtChange,
            params._isDebtIncrease 
        );

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(
            isRecoveryMode,
            params._amountsOut,
            params._isDebtIncrease,
            vars
        );

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough YUSD
        if (!params._isUnlever && !params._isDebtIncrease && params._YUSDChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt).sub(vars.netDebtChange));
            _requireValidYUSDRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientYUSDBalance(contractsCache.yusdToken, msg.sender, vars.netDebtChange);
        }

        if (params._collsIn.length > 0) {
            contractsCache.activePool.receiveCollateral(params._collsIn, params._amountsIn);
        }

        (vars.newVC, vars.newDebt) = _updateTroveFromAdjustment(
            contractsCache.troveManager,
            msg.sender,
            vars.newAssets,
            vars.newAmounts,
            vars.newVC,
            vars.netDebtChange,
            params._isDebtIncrease, 
            vars.variableYUSDFee
        );

        contractsCache.troveManager.updateStakeAndTotalStakes(msg.sender);

        // Re-insert trove in to the sorted list
        sortedTroves.reInsert(msg.sender, vars.newICR, params._upperHint, params._lowerHint);

        emit TroveUpdated(
            msg.sender,
            vars.newDebt,
            vars.newAssets,
            vars.newAmounts,
            BorrowerOperation.adjustTrove
        );
        emit YUSDBorrowingFeePaid(msg.sender, vars.YUSDFee);

        // in case of unlever up
        if (params._isUnlever) {
            // 1. withdraw the collateral from the active pool and perform the swap using single unlever up and corresponding router
            contractsCache.activePool.sendCollateralsUnwrap(msg.sender, params._collsOut, params._amountsOut, true);

            // 2. requires that the user has approved the contract to send its collateral if it is unlevering that amount. 
            for (uint i = 0; i < params._collsOut.length; i++) {
                if (params._maxSlippages[i] != 0) {
                    // add YUSD Amount from swap to total YUSD amount to repay debt
                    // _singleUnleverUp(params._collsOut[i], params._amountsOut[i], params._maxSlippages[i]); TODO UNCOMMENT
                    // TODO confirm amount transfered. Should we be transfering directly to active pool?
                } 
            }
            // 3. update the trove with the new collateral and debt, repaying the total amount of YUSD specified. 
            // require(finalYUSDAmount >= _YUSDAmount, "Unlever: Must have sold enough coll for YUSD");
            // if not enough coll sold for YUSD, must cover from user balance
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt).sub(params._YUSDChange));
            _requireValidYUSDRepayment(vars.debt, params._YUSDChange);
            _requireSufficientYUSDBalance(contractsCache.yusdToken, msg.sender, params._YUSDChange);
            _repayYUSD(contractsCache.activePool, contractsCache.yusdToken, msg.sender, params._YUSDChange);
        } else {
            // Use the unmodified _YUSDChange here, as we don't send the fee to the user
            _moveYUSD(
                contractsCache.activePool,
                contractsCache.yusdToken,
                msg.sender,
                params._YUSDChange.sub(params._totalYUSDDebtFromLever), // 0 in non lever case
                params._isDebtIncrease,
                vars.netDebtChange
            );

            // Additionally move the variable deposit fee to the active pool manually, as it is always an increase in debt
            _withdrawYUSD(
                contractsCache.activePool,
                contractsCache.yusdToken,
                msg.sender,
                0,
                vars.variableYUSDFee
            );

            // transfer withdrawn collateral to msg.sender from ActivePool
            activePool.sendCollateralsUnwrap(msg.sender, params._collsOut, params._amountsOut, true);
        }
    }

    // internal function for minting yusd at certain leverage and max slippage, and then performing TODO
    // swap with whitelist's approved router. 
    // function _singleUnleverUp(address _token, 
    //     uint256 _amount, 
    //     uint256 _maxSlippage) 
    //     internal
    //     returns (uint256 _finalYUSDAmount) {
    //     require(_maxSlippage <= 1e18, "max slippage must be less than 100%");
    //     // if wrapped token, then does i t automatically transfer to active pool?
    //     // It should actually transfer to the owner, who will have bOps pre approved
    //     // cause of original approve
    //     IYetiRouter router = IYetiRouter(whitelist.getDefaultRouterAddress(_token));
    //     // then calculate VC amount of expected YUSD output based on amount of token to sell

    //     uint VCofCollateral = whitelist.getValueVC(_token, _amount);
    //     uint256 slippageAdjustedValue = VCofCollateral.mul(DECIMAL_PRECISION.sub(_maxSlippage)).div(1e18);
    //     _finalYUSDAmount = router.unRoute(msg.sender, _token, address(yusdToken), _amount, slippageAdjustedValue);
    //     // TODO do checks of raw balances?
    //     return _finalYUSDAmount;
    // }


    // Withdraw collateral from a trove. Calls _adjustTrove with correct params.
    // Specifies amount of collateral to withdraw and how much debt to repay, 
    // Can withdraw coll and *only* pay back debt using this function. Will take 
    // the collateral given and send YUSD back to user. Then they will pay back debt
    // first transfers amount of collateral from active pool then sells. 
    // calls _singleUnleverUp() to perform the swaps using the wrappers. 
    // should have no fees. 
    // function withdrawCollUnleverUp(
    //     address[] memory _collsOut,
    //     uint256[] memory _amountsOut,
    //     uint256[] memory _maxSlippages,
    //     uint256 _YUSDAmount,
    //     address _upperHint,
    //     address _lowerHint
    //     ) external override {
    //     // check that all _collsIn collateral types are in the whitelist
    //     _requireValidDepositCollateral(_collsOut, _amountsOut);
    //     _requireNoDuplicateColls(_collsOut);

    //     AdjustTrove_Params memory params; 
    //     params._collsOut = _collsOut;
    //     params._amountsOut = _amountsOut;
    //     params._maxSlippages = _maxSlippages;
    //     params._YUSDChange = _YUSDAmount;
    //     params._upperHint = _upperHint;
    //     params._lowerHint = _lowerHint;
    //     params._isUnlever = true;

    //     _adjustTrove(params);
    // }

    // function closeTroveUnlever(
    //     address[] memory _collsOut,
    //     uint256[] memory _amountsOut,
    //     uint256[] memory _maxSlippages
    // ) external override {
    //     CloseTrove_Params memory params = CloseTrove_Params({
    //         _collsOut: _collsOut,
    //         _amountsOut: _amountsOut,
    //         _maxSlippages: _maxSlippages,
    //         _isUnlever: true
    //         }
    //     );
    //     _closeTrove(params);
    // }

    function closeTrove() external override {
        CloseTrove_Params memory params; // default false
        _closeTrove(params);
    }

    /** 
     * Closes trove by applying pending rewards, making sure that the YUSD Balance is sufficient, and transferring the 
     * collateral to the owner, and repaying the debt.
     * if it is a unlever, then it will transfer the collaterals / sell before. Otherwise it will just do it last. 
     */
    function _closeTrove(
        CloseTrove_Params memory params
        ) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, yusdToken);

        _requireTroveisActive(contractsCache.troveManager, msg.sender);
        _requireNotInRecoveryMode();

        contractsCache.troveManager.applyPendingRewards(msg.sender);

        uint256 troveVC = contractsCache.troveManager.getTroveVC(msg.sender); // should get the latest VC
        (address[] memory colls, uint256[] memory amounts) = contractsCache.troveManager.getTroveColls(
            msg.sender
        );
        uint256 debt = contractsCache.troveManager.getTroveDebt(msg.sender);

        // if unlever, will do extra.
        uint finalYUSDAmount;
        uint YUSDAmount;
        if (params._isUnlever) {
            contractsCache.activePool.sendCollateralsUnwrap(msg.sender, colls, amounts, true);
            // tracks the amount of YUSD that is received from swaps. Will send the _YUSDAmount back to repay debt while keeping remainder.
            
            // requires that the user has approved the contract to send its collateral if it is unlevering that amount. 
            for (uint i = 0; i < params._collsOut.length; i++) {
                if (params._maxSlippages[i] != 0) {
                    // add YUSD Amount from swap to total YUSD amount to repay debt
                    // _singleUnleverUp(params._collsOut[i], params._amountsOut[i], params._maxSlippages[i]); TODO uncomment
                    // TODO confirm amount transfered. Should we transfer directly to user?
                } 
            }   
        }

        // do check after unlever (if applies)
        _requireSufficientYUSDBalance(contractsCache.yusdToken, msg.sender, debt.sub(YUSD_GAS_COMPENSATION));
        uint256 newTCR = _getNewTCRFromTroveChange(troveVC, false, debt, false);
        _requireNewTCRisAboveCCR(newTCR);

        contractsCache.troveManager.removeStake(msg.sender);
        contractsCache.troveManager.closeTrove(msg.sender);

        address[] memory finalColls;
        uint256[] memory finalAmounts;

        emit TroveUpdated(msg.sender, 0, finalColls, finalAmounts, BorrowerOperation.closeTrove);

        // Burn the repaid YUSD from the user's balance and the gas compensation from the Gas Pool
        _repayYUSD(contractsCache.activePool, contractsCache.yusdToken, msg.sender, debt.sub(YUSD_GAS_COMPENSATION));
        _repayYUSD(contractsCache.activePool, contractsCache.yusdToken, gasPoolAddress, YUSD_GAS_COMPENSATION);

        // Send the collateral back to the user
        // Also sends the rewards
        if (!params._isUnlever) {
            contractsCache.activePool.sendCollateralsUnwrap(msg.sender, colls, amounts, true);
        }
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     * TODO: this function is optional, but the idea is that a borrower only needs to call this contract
     * to do all necessary interactions. Can delete if this is the only way to reduce size.
     */
    function claimCollateral() external override {
        // send collateral from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    /** 
     * Gets the variable deposit fee from the whitelist calculation. Multiplies the 
     * fee by the vc of the collateral.
     */
    function _getTotalVariableDepositFee(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256 _VCin,
        uint256 _VCout,
        uint256 _maxFeePercentageFactor, 
        uint256 _maxFeePercentage,
        ContractsCache memory _contractsCache
    ) internal returns (uint256 YUSDFee) {
        if (_VCin == 0) {
            return 0;
        }
        DepositFeeCalc memory vars;
        // active pool total VC at current state.
        vars.systemTotalVC = _contractsCache.activePool.getVC().add(
            defaultPool.getVC()
        );
        // active pool total VC post adding and removing all collaterals
        uint256 activePoolVCPost = vars.systemTotalVC.add(_VCin).sub(_VCout);
        uint256 whitelistFee;

        for (uint256 i = 0; i < _tokensIn.length; i++) {
            vars.token = _tokensIn[i];
            // VC value of collateral of this type inputted
            vars.collateralInputVC = whitelist.getValueVC(vars.token, _amountsIn[i]);

            // total value in VC of this collateral in active pool (post adding input)
            vars.systemCollateralVC = _contractsCache.activePool.getCollateralVC(vars.token).add(
                defaultPool.getCollateralVC(vars.token)
            );

            // (collateral VC In) * (Collateral's Fee Given Yeti Protocol Backed by Given Collateral)
            whitelistFee = 
                    whitelist.getFeeAndUpdate(
                        vars.token,
                        vars.collateralInputVC,
                        vars.systemCollateralVC,
                        vars.systemTotalVC,
                        activePoolVCPost
                    );
            if (_isBeforeFeeBootstrapPeriod()) {
                whitelistFee = _min(whitelistFee, 1e16); // cap at 1%
            } 
            vars.collateralYUSDFee = vars.collateralInputVC
                .mul(whitelistFee).div(1e18);

            YUSDFee = YUSDFee.add(vars.collateralYUSDFee);
        }
        _requireUserAcceptsFee(YUSDFee, _maxFeePercentageFactor, _maxFeePercentage);
        _triggerDepositFee(_contractsCache.yusdToken, YUSDFee);
        return YUSDFee;
    }

    // Transfer in collateral and send to ActivePool
    // (where collateral is held)
    function _transferCollateralsIntoActivePool(
        address _from,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal returns (bool) {
        uint256 len = _amounts.length;
        for (uint256 i = 0; i < len; i++) {
            address collAddress = _colls[i];
            uint256 amount = _amounts[i];
            bool transferredToActivePool = _singleTransferCollateralIntoActivePool(
                _from,
                collAddress,
                amount
            );
            if (!transferredToActivePool) {
                return false;
            }
        }
        return true;
    }

    function _singleTransferCollateralIntoActivePool(
        address _from,
        address _coll,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 coll = IERC20(_coll);
        bool transferredToActivePool = coll.transferFrom(_from, address(activePool), _amount);
        return transferredToActivePool;
    }

    /**
     * Triggers normal borrowing fee, calculated from base rate and on YUSD amount.
     */
    function _triggerBorrowingFee(
        ITroveManager _troveManager,
        IYUSDToken _yusdToken,
        uint256 _YUSDAmount,
        uint256 _maxFeePercentageFactor,
        uint256 _maxFeePercentage
    ) internal returns (uint256) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint256 YUSDFee = _troveManager.getBorrowingFee(_YUSDAmount);

        _requireUserAcceptsFee(YUSDFee, _maxFeePercentageFactor, _maxFeePercentage);

        // Send fee to sYETI contract
        _yusdToken.mint(sYETIAddress, YUSDFee);
        return YUSDFee;
    }

    function _triggerDepositFee(IYUSDToken _yusdToken, uint256 _YUSDFee) internal {
        // Send fee to sYETI contract
        _yusdToken.mint(sYETIAddress, _YUSDFee);
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment(
        ITroveManager _troveManager,
        address _borrower,
        address[] memory _finalColls,
        uint256[] memory _finalAmounts,
        uint256 _newVC,
        uint256 _debtChange,
        bool _isDebtIncrease, 
        uint256 _variableYUSDFee
    ) internal returns (uint256, uint256) {
        uint256 newDebt;
        _troveManager.updateTroveColl(_borrower, _finalColls, _finalAmounts);
        if (_isDebtIncrease) { // if debt increase, increase by both amounts
           newDebt = _troveManager.increaseTroveDebt(_borrower, _debtChange.add(_variableYUSDFee));
        } else {
            if (_debtChange > _variableYUSDFee) { // if debt decrease, and greater than variable fee, decrease 
                newDebt = _troveManager.decreaseTroveDebt(_borrower, _debtChange.sub(_variableYUSDFee));
            } else { // otherwise increase by opposite subtraction
                newDebt = _troveManager.increaseTroveDebt(_borrower, _variableYUSDFee.sub(_debtChange));
            }
        }

        return (_newVC, newDebt);
    }

    // gets the finalColls and finalAmounts after all deposits and withdrawals have been made
    // this function will error if trying to deposit a collateral that is not in the whitelist
    // or trying to withdraw more collateral of any type that is not in the trove
    function _getNewPortfolio(
        address[] memory _initialTokens,
        uint256[] memory _initialAmounts,
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        address[] memory _tokensOut,
        uint256[] memory _amountsOut
    ) internal view returns (address[] memory finalColls, uint256[] memory finalAmounts) {
        _requireValidDepositCollateral(_tokensIn, _amountsIn);
        _requireValidDepositCollateral(_tokensOut, _amountsOut);

        // Initial Colls + Input Colls
        newColls memory cumulativeIn = _sumColls(
            _initialTokens,
            _initialAmounts,
            _tokensIn,
            _amountsIn
        );

        newColls memory newPortfolio = _subColls(cumulativeIn, _tokensOut, _amountsOut);
        return (newPortfolio.tokens, newPortfolio.amounts);
    }

    // Moves the YUSD around based on whether it is an increase or decrease in debt.
    function _moveYUSD(
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        address _borrower,
        uint256 _YUSDChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    ) internal {
        if (_isDebtIncrease) {
            _withdrawYUSD(_activePool, _yusdToken, _borrower, _YUSDChange, _netDebtChange);
        } else {
            _repayYUSD(_activePool, _yusdToken, _borrower, _YUSDChange);
        }
    }

    // Issue the specified amount of YUSD to _account and increases the total active debt (_netDebtIncrease potentially includes a YUSDFee)
    function _withdrawYUSD(
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        address _account,
        uint256 _YUSDAmount,
        uint256 _netDebtIncrease
    ) internal {
        _activePool.increaseYUSDDebt(_netDebtIncrease);
        _yusdToken.mint(_account, _YUSDAmount);
    }

    // Burn the specified amount of YUSD from _account and decreases the total active debt
    function _repayYUSD(
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        address _account,
        uint256 _YUSD
    ) internal {
        _activePool.decreaseYUSDDebt(_YUSD);
        _yusdToken.burn(_account, _YUSD);
    }

    // --- 'Require' wrapper functions ---

    function _requireValidDepositCollateral(address[] memory _colls, uint256[] memory _amounts) internal view {
        require(
            _colls.length == _amounts.length,
            "Length of collateral arrays must be equal"
        );
        for (uint256 i = 0; i < _colls.length; i++) {
            require(whitelist.getIsActive(_colls[i]), "BOps: Collateral not in whitelist");
            require(_amounts[i] > 0, "BOps: Collateral amount must be greater than 0");
        }
    }

    function _requireNonZeroAdjustment(
        uint256[] memory _amountsIn,
        uint256[] memory _amountsOut,
        uint256 _YUSDChange
    ) internal pure {
        require(
            _arrayIsNonzero(_amountsIn) || _arrayIsNonzero(_amountsOut) || _YUSDChange != 0,
            "BorrowerOps: There must be either a collateral change or a debt change"
        );
    }

    function _arrayIsNonzero(uint256[] memory arr) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] != 0) {
                return true;
            }
        }
        return false;
    }

    function _isBeforeFeeBootstrapPeriod() internal view returns (bool) {
        return block.timestamp < deploymentTime.add(BOOTSTRAP_PERIOD);
    }

    function _requireTroveisActive(ITroveManager _troveManager, address _borrower) internal view {
        require(_troveManager.isTroveActive(_borrower), "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(ITroveManager _troveManager, address _borrower) internal view {
        require(!_troveManager.isTroveActive(_borrower), "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint256 _YUSDChange) internal pure {
        require(_YUSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireNoOverlapColls(address[] memory _colls1, address[] memory _colls2)
        internal
        pure
    {
        for (uint256 i = 0; i < _colls1.length; i++) {
            for (uint256 j = 0; j < _colls2.length; j++) {
                require(_colls1[i] != _colls2[j], "BorrowerOps: Collateral passed in overlaps");
            }
        }
    }


    function _requireNoDuplicateColls(address[] memory _colls) internal pure {
        for (uint256 i = 0; i < _colls.length; i++) {
            for (uint256 j = i + 1; j < _colls.length; j++) {
                require(_colls[i] != _colls[j], "BorrowerOps: Collateral passed in overlaps");
            }
        }
    }

    function _requireNotInRecoveryMode() internal view {
        require(!_checkRecoveryMode(), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(uint256[] memory _amountOut) internal pure {
        require(
            !_arrayIsNonzero(_amountOut),
            "BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
        );
    }

    function _requireValidAdjustmentInCurrentMode(
        bool _isRecoveryMode,
        uint256[] memory _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustTrove memory _vars
    ) internal view {
        /*
         *In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
         *
         * In Normal Mode, ensure:
         *
         * - The new ICR is above MCR
         * - The adjustment won't pull the TCR below CCR
         */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }
        } else {
            // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromTroveChange(
                _vars.collChange,
                _vars.isCollIncrease,
                _vars.netDebtChange,
                _isDebtIncrease
            );
            _requireNewTCRisAboveCCR(_vars.newTCR);
        }
    }

    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(
            _newICR >= MCR,
            "BorrowerOps: An operation that would result in ICR < MCR is not permitted"
        );
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR) internal pure {
        require(
            _newICR >= _oldICR,
            "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode"
        );
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(
            _newTCR >= CCR,
            "BorrowerOps: An operation that would result in TCR < CCR is not permitted"
        );
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal pure {
        require(
            _netDebt >= MIN_NET_DEBT,
            "BorrowerOps: Trove's net debt must be greater than minimum"
        );
    }

    function _requireValidYUSDRepayment(uint256 _currentDebt, uint256 _debtRepayment) internal pure {
        require(
            _debtRepayment <= _currentDebt.sub(YUSD_GAS_COMPENSATION),
            "BorrowerOps: Amount repaid must not be larger than the Trove's debt"
        );
    }

    function _requireSufficientYUSDBalance(
        IYUSDToken _yusdToken,
        address _borrower,
        uint256 _debtRepayment
    ) internal view {
        require(
            _yusdToken.balanceOf(_borrower) >= _debtRepayment,
            "BorrowerOps: Caller doesnt have enough YUSD to make repayment"
        );
    }

    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage, bool _isRecoveryMode)
        internal
        pure
    {
        if (_isRecoveryMode) {
            require(
                _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%"
            );
        } else {
            require(
                _maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%"
            );
        }
    }

    // checks lengths are all good and that all passed in routers are valid routers
    function _requireValidRouterParams(
        address[] memory _finalRoutedColls,
        uint[] memory _amounts,
        uint[] memory _minSwapAmounts,
        IYetiRouter[] memory _routers) internal view {
        require(_finalRoutedColls.length == _amounts.length);
        require(_amounts.length == _routers.length);
        require(_amounts.length == _minSwapAmounts.length);
        for (uint i = 0; i < _routers.length; i++) {
            require(whitelist.isValidRouter(address(_routers[i])));
        }
    }

    // requires that avax indices are in order
    function _requireRouterAVAXIndicesInOrder(uint[] memory _indices) internal pure {
        for (uint i = 0; i < _indices.length - 1; i++) {
            require(_indices[i] < _indices[i + 1]);
        }
    }


    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange(
        uint256 _newVC,
        uint256 _debt,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        uint256 newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

        uint256 newICR = LiquityMath._computeCR(_newVC, newDebt);
        return newICR;
    }

    function _getNewTCRFromTroveChange(
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal view returns (uint256) {
        uint256 totalColl = getEntireSystemColl();
        uint256 totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
        totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt.sub(_debtChange);

        uint256 newTCR = LiquityMath._computeCR(totalColl, totalDebt);
        return newTCR;
    }

    function getCompositeDebt(uint256 _debt) external pure override returns (uint256) {
        return _getCompositeDebt(_debt);
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _a : _b;
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Common interface for the Trove Manager.
interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event YUSDTokenAddressChanged(address _yusdTokenAddress);
    event SYETIAddressChanged(address _sYETIAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event YUSDBorrowingFeePaid(address indexed _borrower, uint _YUSDFee);

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _sortedTrovesAddress,
        address _yusdTokenAddress,
        address _sYETIAddress,
        address _whiteListAddress
    ) external;

    function openTrove(uint _maxFeePercentage, uint _YUSDAmount, address _upperHint,
        address _lowerHint,
        address[] calldata _colls,
        uint[] calldata _amounts) external;

    //     function openTroveLeverUp(
    //     uint256 _maxFeePercentage,
    //     uint256 _YUSDAmount,
    //     address _upperHint,
    //     address _lowerHint,
    //     address[] memory _colls,
    //     uint256[] memory _amounts, 
    //     uint256[] memory _leverages,
    //     uint256[] memory _maxSlippages
    // ) external;

    // function closeTroveUnlever(
    //     address[] memory _collsOut,
    //     uint256[] memory _amountsOut,
    //     uint256[] memory _maxSlippages
    // ) external;

    function closeTrove() external;

    function adjustTrove(
        address[] calldata _collsIn,
        uint[] calldata _amountsIn,
        address[] calldata _collsOut,
        uint[] calldata _amountsOut,
        uint _YUSDChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint _maxFeePercentage) external;

    function addColl(address[] memory _collsIn, uint[] memory _amountsIn, address _upperHint, address _lowerHint, uint _maxFeePercentage) external;

    // function addCollLeverUp(
    //     address[] memory _collsIn,
    //     uint256[] memory _amountsIn,
    //     uint256[] memory _leverages,
    //     uint256[] memory _maxSlippages,
    //     uint256 _YUSDAmount,
    //     address _upperHint,
    //     address _lowerHint, 
    //     uint256 _maxFeePercentage
    // ) external;

    function withdrawColl(address[] memory _collsOut, uint[] memory _amountsOut, address _upperHint, address _lowerHint) external;

    // function withdrawCollUnleverUp(
    //     address[] memory _collsOut,
    //     uint256[] memory _amountsOut,
    //     uint256[] memory _maxSlippages,
    //     uint256 _YUSDAmount,
    //     address _upperHint,
    //     address _lowerHint
    // ) external;

    function withdrawYUSD(uint _maxFeePercentage, uint _YUSDAmount, address _upperHint, address _lowerHint) external;

    function repayYUSD(uint _YUSDAmount, address _upperHint, address _lowerHint) external;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./IYUSDToken.sol";
import "./IYETIToken.sol";
import "./ISYETI.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";


// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event YUSDTokenAddressChanged(address _newYUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event YETITokenAddressChanged(address _yetiTokenAddress);
    event SYETIAddressChanged(address _sYETIAddress);

    event Liquidation(uint liquidatedAmount, uint totalYUSDGasCompensation, 
        address[] totalCollTokens, uint[] totalCollAmounts,
        address[] totalCollGasCompTokens, uint[] totalCollGasCompAmounts);
    event Redemption(uint _attemptedYUSDAmount, uint _actualYUSDAmount, uint YUSDfee, address[] tokens, uint[] amounts);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(address token, uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_YUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_YUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _yetiTokenAddress,
        address _sYETIAddress,
        address _whitelistAddress,
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    )
    external;

    function stabilityPool() external view returns (IStabilityPool);
    function yusdToken() external view returns (IYUSDToken);
    function yetiToken() external view returns (IYETIToken);
    function sYETI() external view returns (ISYETI);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getCurrentICR(address _borrower) external view returns (uint);

    function liquidate(address _borrower) external;

    function batchLiquidateTroves(address[] calldata _troveArray, address _liquidator) external;

    function redeemCollateral(
        uint _YUSDAmount,
        uint _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations
    ) external;

    function updateStakeAndTotalStakes(address _borrower) external;

    function updateTroveCollTMR(address  _borrower, address[] memory addresses, uint[] memory amounts) external;

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

//    function getPendingETHReward(address _borrower) external view returns (uint);
    function getPendingCollRewards(address _borrower) external view returns (address[] memory, uint[] memory);

    function getPendingYUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

//    function getEntireDebtAndColl(address _borrower) external view returns (
//        uint debt,
//        uint coll,
//        uint pendingYUSDDebtReward,
//        uint pendingETHReward
//    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function removeStakeTMR(address _borrower) external;
    function updateTroveDebt(address _borrower, uint debt) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint YUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _YUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);

    function isTroveActive(address _borrower) external view returns (bool);

    function getTroveStake(address _borrower, address _token) external view returns (uint);

    function getTotalStake(address _token) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getL_Coll(address _token) external view returns (uint);

    function getL_YUSD(address _token) external view returns (uint);

    function getRewardSnapshotColl(address _borrower, address _token) external view returns (uint);

    function getRewardSnapshotYUSD(address _borrower, address _token) external view returns (uint);

    // returns the VC value of a trove
    function getTroveVC(address _borrower) external view returns (uint);

    function getTroveColls(address _borrower) external view returns (address[] memory, uint[] memory);

    function getCurrentTroveState(address _borrower) external view returns (address[] memory, uint[] memory, uint);

    function setTroveStatus(address _borrower, uint num) external;

    function updateTroveColl(address _borrower, address[] memory _tokens, uint[] memory _amounts) external;

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint);

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint);

    function getTCR() external view returns (uint);

    function checkRecoveryMode() external view returns (bool);

    function closeTroveRedemption(address _borrower) external;

    function closeTroveLiquidation(address _borrower) external;

    function removeStakeTLR(address _borrower) external;

    function updateBaseRate(uint newBaseRate) external;

    function calcDecayedBaseRate() external view returns (uint);

    function redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, address[] memory _tokens, uint[] memory _amounts) external;

    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, address[] memory _tokens, uint[] memory _amounts) external;

    function getEntireDebtAndColls(address _borrower) external view
    returns (uint, address[] memory, uint[] memory, uint, address[] memory, uint[] memory);

    function movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _YUSD, address[] memory _tokens, uint[] memory _amounts, address _borrower) external;

    function collSurplusUpdate(address _account, address[] memory _tokens, uint[] memory _amounts) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface IYUSDToken is IERC20, IERC2612 {
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event YUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Dependencies/YetiCustomBase.sol";
import "./ICollateralReceiver.sol";


interface ICollSurplusPool is ICollateralReceiver {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _whitelistAddress
    ) external;

    function getCollVC() external view returns (uint);

    function getAmountClaimable(address _account, address _collateral) external view returns (uint);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function accountSurplus(address _account, address[] memory _tokens, uint[] memory _amounts) external;

    function claimColl(address _account) external;

    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress, address _troveManagerRedemptionsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getOldICR(address _id) external view returns (uint256);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ISYETI {
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function mint(uint256 amount) external returns (bool);
    function burn(address to, uint256 shares) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


interface IWhitelist {
    function getValidCollateral() view external returns (address[] memory);

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress, 
        address _borrowerOperationsAddress
    ) external;

    function isValidRouter(address _router) external view returns (bool);
    function getOracle(address _collateral) view external returns (address);
    function getRatio(address _collateral) view external returns (uint256);
    function getIsActive(address _collateral) view external returns (bool);
    function getPriceCurve(address _collateral) external view returns (address);
    function getDecimals(address _collateral) external view returns (uint256);
    function getFee(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);
    function getFeeAndUpdate(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);
    function getIndex(address _collateral) external view returns (uint256);
    function isWrapped(address _collateral) external view returns (bool);
    function setDefaultRouter(address _collateral, address _router) external;

    function getValueVC(address _collateral, uint _amount) view external returns (uint);
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);
    function getDefaultRouterAddress(address _collateral) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Interface which handles routing of tokens to between wrapped versions etc and YUSD or other ERC20s. 
interface IYetiRouter {

    // Goes from some token (YUSD likely) and gives a certain amount of token out.
    // Auto transfers to active pool. 
    // Goes from _startingTokenAddress to _endingTokenAddress, pulling tokens from _fromUser, of _amount, and gets _minSwapAmount out _endingTokenAddress
    function route(address _fromUser, address _startingTokenAddress, address _endingTokenAddress, uint _amount, uint _minSwapAmount) external returns (uint256 _amountOut);

    // Takes the address of the token required in, and gives a certain amount of any token (YUSD likely) out
    // User first withdraws that collateral from the active pool, then performs this swap. Unwraps tokens
    // for the user in that case. 
    // Goes from _startingTokenAddress to _endingTokenAddress, pulling tokens from _fromUser, of _amount, and gets _minSwapAmount out _endingTokenAddress. 
    // Use case: Takes token from trove debt which has been transfered to the owner and then swaps it for YUSD, intended to repay debt. 
    function unRoute(address _fromUser, address _startingTokenAddress, address _endingTokenAddress, uint _amount, uint _minSwapAmount) external returns (uint256 _amountOut);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./LiquityMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/ILiquityBase.sol";
import "../Interfaces/IWhitelist.sol";
import "./YetiCustomBase.sol";


/* 
* Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
* common functions. 
*/
contract LiquityBase is ILiquityBase, YetiCustomBase {

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    uint constant public _110pct = 1100000000000000000; // 1.1e18 == 110%

    // Minimum collateral ratio for individual troves
    uint constant public MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint constant public CCR = 1500000000000000000; // 150%

    // Amount of YUSD to be locked in gas pool on opening troves
    uint constant public YUSD_GAS_COMPENSATION = 200e18;

    // Minimum amount of net YUSD debt a must have
    uint constant public MIN_NET_DEBT = 1800e18;
    // uint constant public MIN_NET_DEBT = 0; 

    uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%
    uint constant public REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt.add(YUSD_GAS_COMPENSATION);
    }


    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt.sub(YUSD_GAS_COMPENSATION);
    }


    // Return the amount of collateral to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(newColls memory _coll) internal pure returns (newColls memory) {
        require(_coll.tokens.length == _coll.amounts.length, "_getCollGasCompensation(): Collateral length mismatch");

        uint[] memory amounts = new uint[](_coll.tokens.length);
        for (uint i = 0; i < _coll.tokens.length; i++) {
            amounts[i] = _coll.amounts[i] / PERCENT_DIVISOR;
        }
        return newColls(_coll.tokens, amounts);
    }

    // Return the system's Total Virtual Coin Balance
    // Virtual Coins are a way to keep track of the system collateralization given
    // the collateral ratios of each collateral type
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getVC();
        uint liquidatedColl = defaultPool.getVC();

        return activeColl.add(liquidatedColl);
    }


    function getEntireSystemDebt() public override view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getYUSDDebt();
        uint closedDebt = defaultPool.getYUSDDebt();

        return activeDebt.add(closedDebt);
    }


    function _getICRColls(newColls memory _colls, uint _debt) internal view returns (uint ICR) {
        uint totalVC = _getVCColls(_colls);
        ICR = LiquityMath._computeCR(totalVC, _debt);
        return ICR;
    }


    function _getVC(address[] memory _tokens, uint[] memory _amounts) internal view returns (uint totalVC) {
        require(_tokens.length == _amounts.length, "Not same length");
        for (uint i = 0; i < _tokens.length; i++) {
            uint tokenVC = whitelist.getValueVC(_tokens[i], _amounts[i]);
            totalVC = totalVC.add(tokenVC);
        }
        return totalVC;
    }


    function _getVCColls(newColls memory _colls) internal view returns (uint VC) {
        for (uint i = 0; i < _colls.tokens.length; i++) {
            uint valueVC = whitelist.getValueVC(_colls.tokens[i], _colls.amounts[i]);
            VC = VC.add(valueVC);
        }
        return VC;
    }


    function _getUSDColls(newColls memory _colls) internal view returns (uint USDValue) {
        for (uint i = 0; i < _colls.tokens.length; i++) {
            uint valueUSD = whitelist.getValueUSD(_colls.tokens[i], _colls.amounts[i]);
            USDValue = USDValue.add(valueUSD);
        }
        return USDValue;
    }


    function _getTCR() internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();
        
        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt);
        return TCR;
    }


    function _checkRecoveryMode() internal view returns (bool) {
        uint TCR = _getTCR();

        return TCR < CCR;
    }

    // fee and amount are denominated in dollar
    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }


    // get Colls struct for the given tokens and amounts
    function _getColls(address[] memory tokens, uint[] memory amounts) internal view returns (newColls memory coll) {
        require(tokens.length == amounts.length);
        coll.tokens = tokens;
        for (uint i = 0; i < tokens.length; i++) {
            coll.amounts[whitelist.getIndex(tokens[i])] = amounts[i];
        }
        return coll;
    }


    // checks coll has a nonzero balance of at least one token in coll.tokens
    function _CollsIsNonZero(newColls memory coll) internal pure returns (bool) {
        for (uint i = 0; i < coll.tokens.length; i++) {
            if (coll.amounts[i] > 0) {
                return true;
            }
        }
        return false;
    }


    function _sendColl(address _to, newColls memory _coll) internal returns (bool) {
        for (uint i = 0; i < _coll.tokens.length; i++) {
            IERC20 token = IERC20(_coll.tokens[i]);
            if (!token.transfer(_to, _coll.amounts[i])) {
                return false;
            }
        }
        return true;
    }


    // Check whether or not the system *would be* in Recovery Mode, given the entire system coll and debt.
    // returns true if the system would be in recovery mode and false if not
    function _checkPotentialRecoveryMode(uint _entireSystemColl, uint _entireSystemDebt)
    internal
    pure
    returns (bool)
    {
        uint TCR = LiquityMath._computeCR(_entireSystemColl, _entireSystemDebt);

        return TCR < CCR;
    }



}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPriceFeed.sol";


interface ILiquityBase {

    function getEntireSystemDebt() external view returns (uint entireSystemDebt);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ICollateralReceiver.sol";

/*
 * The Stability Pool holds YUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its YUSD debt gets offset with
 * YUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of YUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a YUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total YUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- YETI ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An YETI issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued YETI in proportion to the deposit as a share of total deposits. The YETI earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#yeti-issuance-to-stability-providers
 */
interface IStabilityPool is ICollateralReceiver {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolYUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event YUSDTokenAddressChanged(address _newYUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _YUSDLoss);
    event YETIPaidToDepositor(address indexed _depositor, uint _YETI);
    event YETIPaidToFrontEnd(address indexed _frontEnd, uint _YETI);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _whitelistAddress,
        address _troveManagerLiquidationsAddress
    )
        external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;


    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the YUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, address[] memory _assets, uint[] memory _amountsAdded) external;

//    /*
//     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
//     * to exclude edge cases like ETH received from a self-destruct.
//     */
//    function getETH() external view returns (uint);
    
     //*
//     * Calculates and returns the total gains a depositor has accumulated 
//     */
    function  getDepositorGains(address _depositor) external view returns (address[] memory assets, uint[] memory amounts);


    /*
     * Returns the total amount of VC held by the pool, accounted for by multipliying the
     * internal balances of collaterals by the price that is found at the time getVC() is called.
     */
    function getVC() external view returns (uint);

    /*
     * Returns YUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalYUSDDeposits() external view returns (uint);

    /*
     * Calculate the YETI gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorYETIGain(address _depositor) external view returns (uint);

    /*
     * Return the YETI gain earned by the front end.
     */
    function getFrontEndYETIGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedYUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);

    /*
     * Add collateral type to totalColl 
     */
    function addCollateralType(address _collateral) external;

    function getDepositSnapshotS(address depositor, address collateral) external view returns (uint);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IERC20.sol";
import "./IERC2612.sol";

interface IYETIToken is IERC20, IERC2612 {

    function sendToSYETI(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

    
interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolYUSDDebtUpdated(uint _YUSDDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---
    
    function sendCollaterals(address _to, address[] memory _tokens, uint[] memory _amounts) external returns (bool);
    function sendCollateralsUnwrap(
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts,
        bool _collectRewards) external returns (bool);
    function getCollateralVC(address collateralAddress) external view returns (uint);
    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolYUSDDebtUpdated(uint _YUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---
    
    function sendCollsToActivePool(address[] memory _collaterals, uint[] memory _amounts, address _borrower) external;
    function addCollateralType(address _collateral) external;
    function getCollateralVC(address collateralAddress) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // --- Function ---
    // function fetchPrice() external returns (uint);

    function fetchPrice_v() view external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ICollateralReceiver.sol";

// Common interface for the Pools.
interface IPool is ICollateralReceiver {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event YUSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event WhitelistAddressChanged(address _newWhitelistAddress);
    event EtherSent(address _to, uint _amount);
    event CollateralSent(address _collateral, address _to, uint _amount);

    // --- Functions ---

    function getVC() external view returns (uint);

    function getCollateral(address collateralAddress) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getYUSDDebt() external view returns (uint);

    function increaseYUSDDebt(uint _amount) external;

    function decreaseYUSDDebt(uint _amount) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./BaseMath.sol";
import "./SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IWhitelist.sol";


contract YetiCustomBase is BaseMath {
    using SafeMath for uint256;

    IWhitelist whitelist;

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    // Collateral math

    // gets the sum of _coll1 and _coll2
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        newColls memory coll3;

        coll3.tokens = whitelist.getValidCollateral();
        coll3.amounts = new uint256[](coll3.tokens.length);

        uint256 n = 0;
        for (uint256 i = 0; i < _coll1.tokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_coll1.tokens[i]);
            if (_coll1.amounts[i] > 0) {
                n++;
                coll3.amounts[tokenIndex] = _coll1.amounts[i];
            }
        }

        for (uint256 i = 0; i < _coll2.tokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_coll2.tokens[i]);
            if (_coll2.amounts[i] > 0) {
                if (coll3.amounts[tokenIndex] == 0) {
                    n++;
                }
                coll3.amounts[tokenIndex] = coll3.amounts[tokenIndex].add(_coll2.amounts[i]);
            }
        }

        address[] memory sumTokens = new address[](n);
        uint256[] memory sumAmounts = new uint256[](n);
        uint256 j = 0;

        // should only find n amounts over 0
        for (uint256 i = 0; i < coll3.tokens.length; i++) {
            if (coll3.amounts[i] > 0) {
                sumTokens[j] = coll3.tokens[i];
                sumAmounts[j] = coll3.amounts[i];
                j++;
            }
        }
        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }


    // gets the sum of coll1 with tokens and amounts
    function _sumColls(
        newColls memory _coll1,
        address[] memory tokens,
        uint256[] memory amounts
    ) internal view returns (newColls memory) {
        newColls memory coll2 = newColls(tokens, amounts);
        return _sumColls(_coll1, coll2);
    }


    function _sumColls(
        address[] memory tokens1,
        uint256[] memory amounts1,
        address[] memory tokens2,
        uint256[] memory amounts2
    ) internal view returns (newColls memory) {
        newColls memory coll1 = newColls(tokens1, amounts1);
        return _sumColls(coll1, tokens2, amounts2);
    }


    // Function for summing colls when coll1 includes all the tokens in the whitelist
    // Used in active, default, stability, and surplus pools
    // assumes _coll1.tokens = all whitelisted tokens
    function _leftSumColls(
        newColls memory _coll1,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint[] memory) {
        uint[] memory sumAmounts = _getArrayCopy(_coll1.amounts);

        // assumes that sumAmounts length = whitelist tokens length.
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint tokenIndex = whitelist.getIndex(_tokens[i]);
            sumAmounts[tokenIndex] = sumAmounts[tokenIndex].add(_amounts[i]);
        }

        return sumAmounts;
    }


    // Function for summing colls when one list is all tokens. Used in active, default, stability, and surplus pools
    function _leftSubColls(newColls memory _coll1, address[] memory _subTokens, uint[] memory _subAmounts)
        internal
        view
        returns (uint[] memory)
    {
        uint[] memory diffAmounts = _getArrayCopy(_coll1.amounts);

        //assumes that coll1.tokens = whitelist tokens. Keeps all of coll1's tokens, and subtracts coll2's amounts
        for (uint256 i = 0; i < _subTokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_subTokens[i]);
            diffAmounts[tokenIndex] = diffAmounts[tokenIndex].sub(_subAmounts[i]);
        }
        return diffAmounts;
    }
    

    // Returns _coll1 minus _tokens and _amounts
    // will error if _tokens include a token not in _coll1.tokens
    function _subColls(newColls memory _coll1, address[] memory _tokens, uint[] memory _amounts)
        internal
        view
        returns (newColls memory finalColls)
    {
        require(_tokens.length == _amounts.length, "Sub Colls invalid input");

        newColls memory coll3;
        coll3.tokens = whitelist.getValidCollateral();
        coll3.amounts = new uint256[](coll3.tokens.length);
        uint256 n = 0;

        for (uint256 i = 0; i < _coll1.tokens.length; i++) {
            if (_coll1.amounts[i] > 0) {
                uint256 tokenIndex = whitelist.getIndex(_coll1.tokens[i]);
                coll3.amounts[tokenIndex] = _coll1.amounts[i];
                n++;
            }
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_tokens[i]);
            require(coll3.amounts[tokenIndex] >= _amounts[i], "illegal sub");
            coll3.amounts[tokenIndex] = coll3.amounts[tokenIndex].sub(_amounts[i]);
            if (coll3.amounts[tokenIndex] == 0) {
                n--;
            }
        }

        address[] memory diffTokens = new address[](n);
        uint256[] memory diffAmounts = new uint256[](n);
        uint256 j = 0;

        for (uint256 i = 0; i < coll3.tokens.length; i++) {
            if (coll3.amounts[i] > 0) {
                diffTokens[j] = coll3.tokens[i];
                diffAmounts[j] = coll3.amounts[i];
                j++;
            }
        }
        finalColls.tokens = diffTokens;
        finalColls.amounts = diffAmounts;
    }

    function _getArrayCopy(uint[] memory _arr) internal pure returns (uint[] memory){
        uint[] memory copy = new uint[](_arr.length);
        for (uint i = 0; i < _arr.length; i++) {
            copy[i] = _arr[i];
        }
        return copy;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;


contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./SafeMath.sol";

library LiquityMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    //  _coll should be the amount of VC and _debt is debt of YUSD\
    // new collateral ratio is 10**18 times the collateral ratio. (150% => 1.5e18)
    function _computeCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(10**18).div(_debt);
            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }

}