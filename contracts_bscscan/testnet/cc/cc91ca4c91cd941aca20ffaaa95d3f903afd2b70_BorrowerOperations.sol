// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IBorrowerOperations.sol";
import "./IDFLRStaking.sol";
import "./INestManager.sol";
import "./IYUSDToken.sol";
import "./ICollSurplusPool.sol";
import "./ISortedNests.sol";
import "./FlareLoansStableBase.sol";
import "./Ownable.sol";
import "./Address.sol";

contract BorrowerOperations is FlareLoansStableBase, Ownable, IBorrowerOperations {
    string constant public NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    INestManager public nestManager;
    address stabilityPoolAddress;
    address gasPoolAddress;
    ICollSurplusPool collSurplusPool;
    IYUSDToken public yusdToken;
    ISortedNests public sortedNests; // A doubly linked list of Nests, sorted by their collateral ratios
    address public override kakeiboAddress;
    address public override dflrStakingAddress;

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

     struct LocalVariables_adjustNest {
        uint price;
        uint collChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint oldICR;
        uint newICR;
        uint newTCR;
        uint YUSDFee;
        uint newDebt;
        uint newColl;
        uint stake;
    }

    struct LocalVariables_openNest {
        uint price;
        uint YUSDFee;
        uint netDebt;
        uint compositeDebt;
        uint ICR;
        uint NICR;
        uint stake;
        uint arrayIndex;
    }

    struct ContractsCache {
        INestManager nestManager;
        IActivePool activePool;
        IYUSDToken yusdToken;
    }

    enum BorrowerOperation {
        openNest,
        closeNest,
        adjustNest
    }

    event NestUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, BorrowerOperation operation);
    
    constructor(address owner, address _loansStableSettings) Ownable(owner) FlareLoansStableBase(_loansStableSettings) { }

    // --- Dependency setters ---

    function setAddresses(
        address _nestManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedNestsAddress,
        address _yusdTokenAddress,
        address _kakeiboAddress,
        address _dflrStakingAddress
    )
        external
        override
        onlyOwner
    {
        // This makes impossible to open a nest with zero withdrawn YUSD
        assert(MIN_NET_DEBT > 0);

        Address.checkContract(_nestManagerAddress);
        Address.checkContract(_activePoolAddress);
        Address.checkContract(_defaultPoolAddress);
        Address.checkContract(_stabilityPoolAddress);
        Address.checkContract(_gasPoolAddress);
        Address.checkContract(_collSurplusPoolAddress);
        Address.checkContract(_priceFeedAddress);
        Address.checkContract(_sortedNestsAddress);
        Address.checkContract(_yusdTokenAddress);
        Address.checkContract(_kakeiboAddress);
        Address.checkContract(_dflrStakingAddress);

        nestManager = INestManager(_nestManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedNests = ISortedNests(_sortedNestsAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        kakeiboAddress = _kakeiboAddress;
        dflrStakingAddress = _dflrStakingAddress;

        emit NestManagerAddressChanged(_nestManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedNestsAddressChanged(_sortedNestsAddress);
        emit YUSDTokenAddressChanged(_yusdTokenAddress);
        emit KakeiboAddressChanged(_kakeiboAddress);
        emit DFLRStakingAddressChanged(_dflrStakingAddress);
    }

    // --- Borrower Nest Operations ---

    function openNest(uint _maxFeePercentage, uint _YUSDAmount, address _upperHint, address _lowerHint) external payable override {
        ContractsCache memory contractsCache = ContractsCache(nestManager, activePool, yusdToken);
        LocalVariables_openNest memory vars;

        vars.price = priceFeed.fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireNestisNotActive(contractsCache.nestManager, msg.sender);

        vars.YUSDFee;
        vars.netDebt = _YUSDAmount;

        if (!isRecoveryMode) {
            vars.YUSDFee = _triggerBorrowingFee(contractsCache.nestManager, contractsCache.yusdToken, _YUSDAmount, _maxFeePercentage);
            vars.netDebt += vars.YUSDFee;
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested YUSD amount + YUSD borrowing fee + YUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);
        
        vars.ICR = FlareLoansStableMath._computeCR(msg.value, vars.compositeDebt, vars.price);
        vars.NICR = FlareLoansStableMath._computeNominalCR(msg.value, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint newTCR = _getNewTCRFromNestChange(msg.value, true, vars.compositeDebt, true, vars.price);  // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR); 
        }

        // Set the nest struct's properties
        contractsCache.nestManager.setNestStatus(msg.sender, 1);
        contractsCache.nestManager.increaseNestColl(msg.sender, msg.value);
        contractsCache.nestManager.increaseNestDebt(msg.sender, vars.compositeDebt);

        contractsCache.nestManager.updateNestRewardSnapshots(msg.sender);
        vars.stake = contractsCache.nestManager.updateStakeAndTotalStakes(msg.sender);

        sortedNests.insert(msg.sender, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.nestManager.addNestOwnerToArray(msg.sender);
        emit NestCreated(msg.sender, vars.arrayIndex);

        // Move the ether to the Active Pool, and mint the YUSDAmount to the borrower
        _activePoolAddColl(contractsCache.activePool, msg.value);
        _withdrawYUSD(contractsCache.activePool, contractsCache.yusdToken, msg.sender, _YUSDAmount, vars.netDebt);
        // Move the YUSD gas compensation to the Gas Pool
        _withdrawYUSD(contractsCache.activePool, contractsCache.yusdToken, gasPoolAddress, YUSD_GAS_COMPENSATION, YUSD_GAS_COMPENSATION);

        emit NestUpdated(msg.sender, vars.compositeDebt, msg.value, vars.stake, BorrowerOperation.openNest);
        emit YUSDBorrowingFeePaid(msg.sender, vars.YUSDFee);
    }

    // Send FLR as collateral to a nest
    function addColl(address _upperHint, address _lowerHint) external payable override {
        _adjustNest(msg.sender, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Send FLR as collateral to a nest. Called by only the Stability Pool.
    function moveFLRGainToNest(address _borrower, address _upperHint, address _lowerHint) external payable override {
        _requireCallerIsStabilityPool();
        _adjustNest(_borrower, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw FLR collateral from a nest
    function withdrawColl(uint _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustNest(msg.sender, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw YUSD tokens from a nest: mint new YUSD tokens to the owner, and increase the nest's debt accordingly
    function withdrawYUSD(uint _maxFeePercentage, uint _YUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustNest(msg.sender, 0, _YUSDAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay YUSD tokens to a Nest: Burn the repaid YUSD tokens, and reduce the nest's debt accordingly
    function repayYUSD(uint _YUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustNest(msg.sender, 0, _YUSDAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustNest(uint _maxFeePercentage, uint _collWithdrawal, uint _YUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint) external payable override {
        _adjustNest(msg.sender, _collWithdrawal, _YUSDChange, _isDebtIncrease, _upperHint, _lowerHint, _maxFeePercentage);
    }

    /*
    * _adjustNest(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal. 
    *
    * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
    *
    * If both are positive, it will revert.
    */
    function _adjustNest(address _borrower, uint _collWithdrawal, uint _YUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(nestManager, activePool, yusdToken);
        LocalVariables_adjustNest memory vars;

        vars.price = priceFeed.fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_YUSDChange);
        }
        _requireSingularCollChange(_collWithdrawal);
        _requireNonZeroAdjustment(_collWithdrawal, _YUSDChange);
        _requireNestisActive(contractsCache.nestManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own nest, or a pure FLR transfer from the Stability Pool to a nest
        assert(msg.sender == _borrower || (msg.sender == stabilityPoolAddress && msg.value > 0 && _YUSDChange == 0));

        contractsCache.nestManager.applyPendingRewards(_borrower);

        // Get the collChange based on whether or not FLR was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(msg.value, _collWithdrawal);

        vars.netDebtChange = _YUSDChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) { 
            vars.YUSDFee = _triggerBorrowingFee(contractsCache.nestManager, contractsCache.yusdToken, _YUSDChange, _maxFeePercentage);
            vars.netDebtChange += vars.YUSDFee; // The raw debt change includes the fee
        }

        vars.debt = contractsCache.nestManager.getNestDebt(_borrower);
        vars.coll = contractsCache.nestManager.getNestColl(_borrower);
        
        // Get the nest's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = FlareLoansStableMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromNestChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.price);
        assert(_collWithdrawal <= vars.coll); 

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);
            
        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough YUSD
        if (!_isDebtIncrease && _YUSDChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt) - vars.netDebtChange);
            _requireValidYUSDRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientYUSDBalance(contractsCache.yusdToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateNestFromAdjustment(contractsCache.nestManager, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        vars.stake = contractsCache.nestManager.updateStakeAndTotalStakes(_borrower);

        // Re-insert nest in to the sorted list
        uint newNICR = _getNewNominalICRFromNestChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        sortedNests.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit NestUpdated(_borrower, vars.newDebt, vars.newColl, vars.stake, BorrowerOperation.adjustNest);
        emit YUSDBorrowingFeePaid(msg.sender,  vars.YUSDFee);

        // Use the unmodified _YUSDChange here, as we don't send the fee to the user
        _moveTokensAndFLRfromAdjustment(
            contractsCache.activePool,
            contractsCache.yusdToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _YUSDChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeNest() external override {
        INestManager nestManagerCached = nestManager;
        IActivePool activePoolCached = activePool;
        IYUSDToken yusdTokenCached = yusdToken;

        _requireNestisActive(nestManagerCached, msg.sender);
        uint price = priceFeed.fetchPrice();
        _requireNotInRecoveryMode(price);

        nestManagerCached.applyPendingRewards(msg.sender);

        uint coll = nestManagerCached.getNestColl(msg.sender);
        uint debt = nestManagerCached.getNestDebt(msg.sender);

        _requireSufficientYUSDBalance(yusdTokenCached, msg.sender, debt - YUSD_GAS_COMPENSATION);

        uint newTCR = _getNewTCRFromNestChange(coll, false, debt, false, price);
        _requireNewTCRisAboveCCR(newTCR);

        nestManagerCached.removeStake(msg.sender);
        nestManagerCached.closeNest(msg.sender);

        emit NestUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeNest);

        // Burn the repaid YUSD from the user's balance and the gas compensation from the Gas Pool
        _repayYUSD(activePoolCached, yusdTokenCached, msg.sender, debt - YUSD_GAS_COMPENSATION);
        _repayYUSD(activePoolCached, yusdTokenCached, gasPoolAddress, YUSD_GAS_COMPENSATION);

        // Send the collateral back to the user
        activePoolCached.sendFLR(msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send FLR from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(INestManager _nestManager, IYUSDToken _yusdToken, uint _YUSDAmount, uint _maxFeePercentage) internal returns (uint) {
        _nestManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint YUSDFee = _nestManager.getBorrowingFee(_YUSDAmount);

        _requireUserAcceptsFee(YUSDFee, _YUSDAmount, _maxFeePercentage);
        
        // Send fee to Kakeibo (APY Cloud)
        ILoansStableSettings loansStableSettingsCache = loansStableSettings;
        uint dflrStakingFee = YUSDFee * loansStableSettingsCache.dflrStakingFeeRate()  / 1e18;
        _yusdToken.mint(dflrStakingAddress, dflrStakingFee);
        _yusdToken.mint(kakeiboAddress, YUSDFee * loansStableSettingsCache.kakeiboFeeRate() / 1e18);
        IDFLRStaking(dflrStakingAddress).increaseF_YUSD(dflrStakingFee);

        return YUSDFee;
    }

    function _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
        uint usdValue = _price * _coll / DECIMAL_PRECISION;

        return usdValue;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update nest's coll and debt based on whether they increase or decrease
    function _updateNestFromAdjustment
    (
        INestManager _nestManager,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? _nestManager.increaseNestColl(_borrower, _collChange)
                                        : _nestManager.decreaseNestColl(_borrower, _collChange);
        uint newDebt = (_isDebtIncrease) ? _nestManager.increaseNestDebt(_borrower, _debtChange)
                                        : _nestManager.decreaseNestDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndFLRfromAdjustment
    (
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _YUSDChange,
        bool _isDebtIncrease,
        uint _netDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawYUSD(_activePool, _yusdToken, _borrower, _YUSDChange, _netDebtChange);
        } else {
            _repayYUSD(_activePool, _yusdToken, _borrower, _YUSDChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_activePool, _collChange);
        } else {
            _activePool.sendFLR(_borrower, _collChange);
        }
    }

    // Send FLR to Active Pool and increase its recorded FLR balance
    function _activePoolAddColl(IActivePool _activePool, uint _amount) internal {
        (bool success, ) = address(_activePool).call{value: _amount}("");
        require(success, "BorrowerOps: Sending FLR to ActivePool failed");
    }

    // Issue the specified amount of YUSD to _account and increases the total active debt (_netDebtIncrease potentially includes a YUSDFee)
    function _withdrawYUSD(IActivePool _activePool, IYUSDToken _yusdToken, address _account, uint _YUSDAmount, uint _netDebtIncrease) internal {
        _activePool.increaseYUSDDebt(_netDebtIncrease);
        _yusdToken.mint(_account, _YUSDAmount);
    }

    // Burn the specified amount of YUSD from _account and decreases the total active debt
    function _repayYUSD(IActivePool _activePool, IYUSDToken _yusdToken, address _account, uint _YUSD) internal {
        _activePool.decreaseYUSDDebt(_YUSD);
        _yusdToken.burn(_account, _YUSD);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint _collWithdrawal) internal view {
        require(msg.value == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(msg.sender == _borrower, "BorrowerOps: Caller must be the borrower for a withdrawal");
    }

    function _requireNonZeroAdjustment(uint _collWithdrawal, uint _YUSDChange) internal view {
        require(msg.value != 0 || _collWithdrawal != 0 || _YUSDChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireNestisActive(INestManager _nestManager, address _borrower) internal view {
        uint status = _nestManager.getNestStatus(_borrower);
        require(status == 1, "BorrowerOps: Nest does not exist or is closed");
    }

    function _requireNestisNotActive(INestManager _nestManager, address _borrower) internal view {
        uint status = _nestManager.getNestStatus(_borrower);
        require(status != 1, "BorrowerOps: Nest is active");
    }

    function _requireNonZeroDebtChange(uint _YUSDChange) internal pure {
        require(_YUSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }
   
    function _requireNotInRecoveryMode(uint _price) internal view {
        require(!_checkRecoveryMode(_price), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(uint _collWithdrawal) internal pure {
        require(_collWithdrawal == 0, "BorrowerOps: Collateral withdrawal not permitted Recovery Mode");
    }

    function _requireValidAdjustmentInCurrentMode 
    (
        bool _isRecoveryMode,
        uint _collWithdrawal,
        bool _isDebtIncrease, 
        LocalVariables_adjustNest memory _vars
    ) 
        internal 
        view 
    {
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
        } else { // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromNestChange(_vars.collChange, _vars.isCollIncrease, _vars.netDebtChange, _isDebtIncrease, _vars.price);
            _requireNewTCRisAboveCCR(_vars.newTCR);  
        }
    }

    function _requireICRisAboveMCR(uint _newICR) internal view {
        require(_newICR >= loansStableSettings.MCR(), "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveCCR(uint _newICR) internal view {
        require(_newICR >= loansStableSettings.CCR(), "BorrowerOps: Operation must leave nest with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint _newICR, uint _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Nest's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint _newTCR) internal view {
        require(_newTCR >= loansStableSettings.CCR(), "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint _netDebt) internal pure {
        require (_netDebt >= MIN_NET_DEBT, "BorrowerOps: Nest's net debt must be greater than minimum");
    }

    function _requireValidYUSDRepayment(uint _currentDebt, uint _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt - YUSD_GAS_COMPENSATION, "BorrowerOps: Amount repaid must not be larger than the Nest's debt");
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

     function _requireSufficientYUSDBalance(IYUSDToken _yusdToken, address _borrower, uint _debtRepayment) internal view {
        require(_yusdToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough YUSD to make repayment");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage, bool _isRecoveryMode) internal pure {
        if (_isRecoveryMode) {
            require(_maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%");
        } else {
            require(_maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%");
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromNestChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewNestAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newNICR = FlareLoansStableMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromNestChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewNestAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newICR = FlareLoansStableMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewNestAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        pure
        returns (uint, uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll + _collChange :  _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }

    function _getNewTCRFromNestChange
    (
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        internal
        view
        returns (uint)
    {
        uint totalColl = getEntireSystemColl();
        uint totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl + _collChange : totalColl - _collChange;
        totalDebt = _isDebtIncrease ? totalDebt + _debtChange : totalDebt - _debtChange;

        uint newTCR = FlareLoansStableMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(uint _debt) external pure override returns (uint) {
        return _getCompositeDebt(_debt);
    }
}