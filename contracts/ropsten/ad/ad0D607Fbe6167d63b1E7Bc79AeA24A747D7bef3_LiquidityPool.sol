// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAssetParameters.sol";

import "./LiquidityPoolFactory.sol";
import "./LiquidityPool.sol";
import "./common/PureParameters.sol";
import "./PriceOracle.sol";

contract AssetParameters is Ownable, IAssetParameters {
    using PureParameters for PureParameters.Param;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    IPriceOracle private priceOracle;

    Registry private _registry;
    EnumerableSet.Bytes32Set private _supportedAssets;

    bytes32 public constant GOVERNANCE_TOKEN_KEY = bytes32("NDG");

    bytes32 public constant FREEZE_KEY = keccak256("FREEZE_KEY");
    bytes32 public constant ENABLE_COLLATERAL_KEY = keccak256("ENABLE_COLLATERAL_KEY");

    bytes32 public constant BASE_PERCENTAGE_KEY = keccak256("BASE_PERCENTAGE_KEY");
    bytes32 public constant FIRST_SLOPE_KEY = keccak256("FIRST_SLOPE_KEY");
    bytes32 public constant SECOND_SLOPE_KEY = keccak256("SECOND_SLOPE_KEY");
    bytes32 public constant UTILIZATION_BREAKING_POINT_KEY =
        keccak256("UTILIZATION_BREAKING_POINT_KEY");
    bytes32 public constant MAX_UTILIZATION_RATIO_KEY = keccak256("MAX_UTILIZATION_RATIO_KEY");

    bytes32 public constant MIN_SUPPLY_DISTRIBUTION_PART_KEY =
        keccak256("MIN_SUPPLY_DISTRIBUTION_PART_KEY");
    bytes32 public constant MIN_BORROW_DISTRIBUTION_PART_KEY =
        keccak256("MIN_BORROW_DISTRIBUTION_PART_KEY");

    struct InterestRateParams {
        uint256 basePercentage;
        uint256 firstSlope;
        uint256 secondSlope;
        uint256 utilizationBreakingPoint;
    }

    mapping(bytes32 => mapping(bytes32 => PureParameters.Param)) private _parameters;

    mapping(bytes32 => address) public availableAssets;
    mapping(bytes32 => address) public liquidityPools;
    mapping(address => bool) public existingLiquidityPools;

    modifier onlyExist(bytes32 _assetKey) {
        require(onlyExistingAsset(_assetKey), "AssetParameters: Asset doesn't exist.");
        _;
    }

    constructor(address _registryAddr, address _priceOracle) Ownable() {
        _registry = Registry(_registryAddr);
        priceOracle = IPriceOracle(_priceOracle);
    }

    function getSupportedAssets() external view returns (bytes32[] memory _resultArr) {
        uint256 _assetsCount = _supportedAssets.length();

        _resultArr = new bytes32[](_assetsCount);

        for (uint256 i = 0; i < _assetsCount; i++) {
            _resultArr[i] = _supportedAssets.at(i);
        }
    }

    function addUintParam(
        bytes32 _assetKey,
        bytes32 _paramKey,
        uint256 _value
    ) external onlyOwner onlyExist(_assetKey) {
        _addParam(_assetKey, _paramKey, PureParameters.makeUintParam(_value));
    }

    function addBytes32Param(
        bytes32 _assetKey,
        bytes32 _paramKey,
        bytes32 _value
    ) external onlyOwner onlyExist(_assetKey) {
        _addParam(_assetKey, _paramKey, PureParameters.makeBytes32Param(_value));
    }

    function addAddrParam(
        bytes32 _assetKey,
        bytes32 _paramKey,
        address _value
    ) external onlyOwner onlyExist(_assetKey) {
        _addParam(_assetKey, _paramKey, PureParameters.makeAdrressParam(_value));
    }

    function addBoolParam(
        bytes32 _assetKey,
        bytes32 _paramKey,
        bool _value
    ) external onlyOwner onlyExist(_assetKey) {
        require(
            _paramKey != ENABLE_COLLATERAL_KEY,
            "AssetParameters: Changing param in this way is not available."
        );
        _addParam(_assetKey, _paramKey, PureParameters.makeBoolParam(_value));
    }

    function _addParam(
        bytes32 _assetKey,
        bytes32 _paramKey,
        PureParameters.Param memory _param
    ) internal {
        _parameters[_assetKey][_paramKey] = _param;

        emit ParamAdded(_assetKey, _paramKey);
    }

    function getUintParam(bytes32 _assetKey, bytes32 _paramKey)
        external
        view
        override
        onlyExist(_assetKey)
        returns (uint256)
    {
        return _getParam(_assetKey, _paramKey).getUintFromParam();
    }

    function getBytes32Param(bytes32 _assetKey, bytes32 _paramKey)
        external
        view
        override
        onlyExist(_assetKey)
        returns (bytes32)
    {
        return _getParam(_assetKey, _paramKey).getBytes32FromParam();
    }

    function getAddressParam(bytes32 _assetKey, bytes32 _paramKey)
        external
        view
        override
        onlyExist(_assetKey)
        returns (address)
    {
        return _getParam(_assetKey, _paramKey).getAdrressFromParam();
    }

    function getBoolParam(bytes32 _assetKey, bytes32 _paramKey)
        external
        view
        override
        onlyExist(_assetKey)
        returns (bool)
    {
        return _getParam(_assetKey, _paramKey).getBoolFromParam();
    }

    function _getParam(bytes32 _assetKey, bytes32 _paramKey)
        internal
        view
        returns (PureParameters.Param memory)
    {
        require(
            PureParameters.paramExists(_parameters[_assetKey][_paramKey]),
            "AssetParameters: Param for this asset doesn't exist."
        );

        return _parameters[_assetKey][_paramKey];
    }

    function removeParam(bytes32 _assetKey, bytes32 _paramKey)
        external
        onlyOwner
        onlyExist(_assetKey)
    {
        require(
            PureParameters.paramExists(_parameters[_assetKey][_paramKey]),
            "AssetParameters: Param for this asset doesn't exist."
        );

        delete _parameters[_assetKey][_paramKey];

        emit ParamRemoved(_assetKey, _paramKey);
    }

    function setupInterestRateModel(
        bytes32 _assetKey,
        uint256 _basePercentage,
        uint256 _firstSlope,
        uint256 _secondSlope,
        uint256 _utilizationBreakingPoint,
        uint256 _maxUtilizationRatio
    ) external onlyOwner onlyExist(_assetKey) {
        require(_basePercentage <= ONE_PERCENT * 3, "AssetParameters: Invalid base percentage.");
        require(
            _firstSlope >= ONE_PERCENT * 3 && _firstSlope <= ONE_PERCENT * 10,
            "AssetParameters: Invalid first slope percentage."
        );
        require(
            _secondSlope >= ONE_PERCENT * 50 && _secondSlope <= DECIMAL,
            "AssetParameters: Invalid second slope percentage."
        );
        require(
            _utilizationBreakingPoint >= ONE_PERCENT * 60 &&
                _utilizationBreakingPoint <= ONE_PERCENT * 85,
            "AssetParameters: Invalid utilization breaking point percentage."
        );
        require(
            _maxUtilizationRatio >= ONE_PERCENT * 90 && _maxUtilizationRatio < DECIMAL,
            "AssetParameters: Invalid max utilization ratio percentage."
        );

        _addParam(_assetKey, BASE_PERCENTAGE_KEY, PureParameters.makeUintParam(_basePercentage));
        _addParam(_assetKey, FIRST_SLOPE_KEY, PureParameters.makeUintParam(_firstSlope));
        _addParam(_assetKey, SECOND_SLOPE_KEY, PureParameters.makeUintParam(_secondSlope));
        _addParam(
            _assetKey,
            UTILIZATION_BREAKING_POINT_KEY,
            PureParameters.makeUintParam(_utilizationBreakingPoint)
        );
        _addParam(
            _assetKey,
            MAX_UTILIZATION_RATIO_KEY,
            PureParameters.makeUintParam(_maxUtilizationRatio)
        );
    }

    function getInterestRateParams(bytes32 _assetKey)
        external
        view
        onlyExist(_assetKey)
        returns (InterestRateParams memory _params)
    {
        _params.basePercentage = PureParameters.getUintFromParam(
            _getParam(_assetKey, BASE_PERCENTAGE_KEY)
        );
        _params.firstSlope = PureParameters.getUintFromParam(
            _getParam(_assetKey, FIRST_SLOPE_KEY)
        );
        _params.secondSlope = PureParameters.getUintFromParam(
            _getParam(_assetKey, SECOND_SLOPE_KEY)
        );
        _params.utilizationBreakingPoint = PureParameters.getUintFromParam(
            _getParam(_assetKey, UTILIZATION_BREAKING_POINT_KEY)
        );
    }

    function setupDistributionsMinimums(
        bytes32 _assetKey,
        uint256 _minSupplyPart,
        uint256 _minBorrowPart
    ) external onlyOwner onlyExist(_assetKey) {
        require(
            _minSupplyPart <= ONE_PERCENT * 20,
            "AssetParameters: The distribution part of the minimum supply is too high."
        );
        require(
            _minBorrowPart <= ONE_PERCENT * 20,
            "AssetParameters: The distribution part of the minimum borrow is too high."
        );

        _addParam(
            _assetKey,
            MIN_SUPPLY_DISTRIBUTION_PART_KEY,
            PureParameters.makeUintParam(_minSupplyPart)
        );
        _addParam(
            _assetKey,
            MIN_BORROW_DISTRIBUTION_PART_KEY,
            PureParameters.makeUintParam(_minBorrowPart)
        );
    }

    function getDistributionMinimums(bytes32 _assetKey)
        external
        view
        returns (uint256 _minSupplyPart, uint256 _minBorrowPart)
    {
        _minSupplyPart = PureParameters.getUintFromParam(
            _getParam(_assetKey, MIN_SUPPLY_DISTRIBUTION_PART_KEY)
        );
        _minBorrowPart = PureParameters.getUintFromParam(
            _getParam(_assetKey, MIN_BORROW_DISTRIBUTION_PART_KEY)
        );
    }

    function getGovernanceLiquidityPool() external view returns (LiquidityPool) {
        return LiquidityPool(liquidityPools[GOVERNANCE_TOKEN_KEY]);
    }

    function freeze(bytes32 _assetKey) external onlyOwner onlyExist(_assetKey) {
        _addParam(_assetKey, FREEZE_KEY, PureParameters.makeBoolParam(true));

        emit Freezed(_assetKey);
    }

    function enableCollateral(bytes32 _assetKey) external onlyOwner {
        _addParam(_assetKey, ENABLE_COLLATERAL_KEY, PureParameters.makeBoolParam(true));
    }

    function addLiquidityPool(
        address _assetAddr,
        bytes32 _assetKey,
        string memory _tokenSymbol,
        bool _isCollateral
    ) external onlyOwner {
        require(_assetKey > 0, "AssetParameters: Unable to add an asset without a key.");
        require(
            _assetAddr != address(0),
            "AssetParameters: Unable to add an asset with a zero address."
        );
        require(
            !onlyExistingAsset(_assetKey),
            "AssetParameters: Liquidity pool with such a key already exists."
        );

        address _poolAddr =
            LiquidityPoolFactory(_registry.getLiquidityPoolFactoryContract()).newLiquidityPool(
                _assetAddr,
                _assetKey,
                _tokenSymbol
            );

        liquidityPools[_assetKey] = _poolAddr;
        availableAssets[_assetKey] = _assetAddr;

        _supportedAssets.add(_assetKey);
        _addParam(_assetKey, FREEZE_KEY, PureParameters.makeBoolParam(false));

        _addParam(_assetKey, ENABLE_COLLATERAL_KEY, PureParameters.makeBoolParam(_isCollateral));
        existingLiquidityPools[_poolAddr] = true;

        emit PoolAdded(_assetKey, _assetAddr, _poolAddr);
    }

    function withdrawAllReservedFunds(address _recipientAddr) external onlyOwner {
        uint256 _assetsCount = _supportedAssets.length();

        for (uint256 i = 0; i < _assetsCount; i++) {
            LiquidityPool(liquidityPools[_supportedAssets.at(i)]).withdrawReservedFunds(
                _recipientAddr,
                0,
                true
            );
        }
    }

    function withdrawReservedFunds(
        address _recipientAddr,
        bytes32 _assetKey,
        uint256 _amountToWithdraw
    ) external onlyOwner {
        require(onlyExistingAsset(_assetKey), "AssetParameters: Asset doesn't exist.");

        LiquidityPool(liquidityPools[_assetKey]).withdrawReservedFunds(
            _recipientAddr,
            _amountToWithdraw,
            false
        );
    }

    function onlyExistingAsset(bytes32 _assetKey) public view returns (bool) {
        return availableAssets[_assetKey] != address(0);
    }

    function getAssetPrice(bytes32 _assetKey) external view returns (uint256) {
        return priceOracle.getAssetPrice(_assetKey);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/DSMath.sol";
import "./common/Globals.sol";

contract CompoundRateKeeper is Ownable {
    struct CompoundRate {
        uint256 rate;
        uint256 lastUpdate;
    }

    CompoundRate public compoundRate;

    constructor() {
        compoundRate = CompoundRate(DECIMAL, block.timestamp);
    }

    function getCurrentRate() external view returns (uint256) {
        return compoundRate.rate;
    }

    function getLastUpdate() external view returns (uint256) {
        return compoundRate.lastUpdate;
    }

    function update(uint256 _interestRate) external onlyOwner returns (uint256) {
        uint256 _period = block.timestamp - compoundRate.lastUpdate;
        uint256 _newRate =
            (compoundRate.rate * (DSMath.rpow(_interestRate + DECIMAL, _period, DECIMAL))) /
                DECIMAL;

        compoundRate.rate = _newRate;
        compoundRate.lastUpdate = block.timestamp;

        return _newRate;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IDefiCore.sol";

import "./Registry.sol";
import "./SystemParameters.sol";
import "./AssetParameters.sol";
import "./LiquidityPool.sol";
import "./RewardsDistribution.sol";
import "./GovernanceToken.sol";
import "./common/Globals.sol";

contract DefiCore is IDefiCore {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    Registry private _registry;

    mapping(address => EnumerableSet.Bytes32Set) internal _supplyAssets;
    mapping(address => EnumerableSet.Bytes32Set) internal _borrowAssets;

    mapping(address => mapping(bytes32 => bool)) public disabledCollateralAssets;

    event LiquidityAdded(address _userAddr, bytes32 _assetKey, uint256 _liquidityAmount);
    event LiquidityWithdrawn(address _userAddr, bytes32 _assetKey, uint256 _liquidityAmount);
    event Borrowed(address _userAddr, bytes32 _assetKey, uint256 _borrowedAmount);
    event BorrowRepaid(address _userAddr, bytes32 _assetKey, uint256 _repaidAmount);
    event DistributionRewardWithdrawn(address _userAddr, uint256 _rewardAmount);

    modifier onlyLiquidityPools() {
        require(
            AssetParameters(_registry.getAssetParametersContract()).existingLiquidityPools(
                msg.sender
            ),
            "DefiCore: Caller not a LiquidityPool"
        );
        _;
    }

    constructor(address _registryAddr) {
        _registry = Registry(_registryAddr);
    }

    function getUserSupplyAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _availableAssets, bytes32[] memory _userSupplyAssets)
    {
        bytes32[] memory _allAssets =
            AssetParameters(_registry.getAssetParametersContract()).getSupportedAssets();

        uint256 _allAssetsCount = _allAssets.length;
        uint256 _supplyAssetsCount = _supplyAssets[_userAddr].length();

        _userSupplyAssets = new bytes32[](_supplyAssetsCount);
        _availableAssets = new bytes32[](_allAssetsCount - _supplyAssetsCount);

        uint256 _userSupplyAssetsIndex;
        uint256 _availableAssetsIndex;

        for (uint256 i = 0; i < _allAssetsCount; i++) {
            bytes32 _currentKey = _allAssets[i];

            if (_supplyAssets[_userAddr].contains(_currentKey)) {
                _userSupplyAssets[_userSupplyAssetsIndex++] = _currentKey;
            } else {
                _availableAssets[_availableAssetsIndex++] = _currentKey;
            }
        }
    }

    function getUserBorrowAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _availableAssets, bytes32[] memory _userBorrowAssets)
    {
        bytes32[] memory _allAssets =
            AssetParameters(_registry.getAssetParametersContract()).getSupportedAssets();

        uint256 _allAssetsCount = _allAssets.length;
        uint256 _borrowAssetsCount = _borrowAssets[_userAddr].length();

        _userBorrowAssets = new bytes32[](_borrowAssetsCount);
        _availableAssets = new bytes32[](_allAssetsCount - _borrowAssetsCount);

        uint256 _userBorrowAssetsIndex;
        uint256 _availableAssetsIndex;

        for (uint256 i = 0; i < _allAssetsCount; i++) {
            bytes32 _currentKey = _allAssets[i];

            if (_borrowAssets[_userAddr].contains(_currentKey)) {
                _userBorrowAssets[_userBorrowAssetsIndex++] = _currentKey;
            } else {
                _availableAssets[_availableAssetsIndex++] = _currentKey;
            }
        }
    }

    function getSupplyAssetsInfo(bytes32[] memory _assetsKeys, address _userAddr)
        external
        view
        returns (SupplyAssetInfo[] memory _resultArr)
    {
        uint256 _assetsCount = _assetsKeys.length;
        _resultArr = new SupplyAssetInfo[](_assetsCount);

        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());

        for (uint256 i = 0; i < _assetsCount; i++) {
            bytes32 _currentKey = _assetsKeys[i];

            LiquidityPool _currentLiquidityPool =
                LiquidityPool(
                    AssetParameters(_registry.getAssetParametersContract()).liquidityPools(
                        _currentKey
                    )
                );

            require(
                address(_currentLiquidityPool) != address(0),
                "DefiCore: LiquidityPool does not exists."
            );

            uint256 _userSupplyBalance =
                _currentLiquidityPool.getCurrentLiquidityAmount(_userAddr);
            (uint256 _userDistributionAPY, ) =
                _rewardsDistribution.getAPY(_userAddr, _currentLiquidityPool);

            _resultArr[i] = SupplyAssetInfo(
                _currentLiquidityPool.assetAddr(),
                _currentLiquidityPool.getAPY(),
                _userDistributionAPY,
                _currentLiquidityPool.getAmountInUSD(_userSupplyBalance),
                _userSupplyBalance,
                !disabledCollateralAssets[_userAddr][_currentKey]
            );
        }
    }

    function getBorrowAssetsInfo(bytes32[] memory _assetsKeys, address _userAddr)
        external
        view
        returns (BorrowAssetInfo[] memory _resultArr)
    {
        uint256 _assetsCount = _assetsKeys.length;
        _resultArr = new BorrowAssetInfo[](_assetsCount);

        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());

        for (uint256 i = 0; i < _assetsCount; i++) {
            bytes32 _currentKey = _assetsKeys[i];

            LiquidityPool _currentLiquidityPool =
                LiquidityPool(
                    AssetParameters(_registry.getAssetParametersContract()).liquidityPools(
                        _currentKey
                    )
                );

            require(
                address(_currentLiquidityPool) != address(0),
                "DefiCore: LiquidityPool does not exists."
            );

            uint256 _userBorrowedAmount = _currentLiquidityPool.getUserBorrowedAmount(_userAddr);
            (, uint256 _userDistributionAPY) =
                _rewardsDistribution.getAPY(_userAddr, _currentLiquidityPool);

            _resultArr[i] = BorrowAssetInfo(
                _currentLiquidityPool.assetAddr(),
                _currentLiquidityPool.getAnnualBorrowRate(),
                _userDistributionAPY,
                _currentLiquidityPool.getAmountInUSD(_userBorrowedAmount),
                _userBorrowedAmount,
                _currentLiquidityPool.getBorrowPercentage()
            );
        }
    }

    function getAssetsInfo(
        bytes32[] memory _assetsKeys,
        address _userAddr,
        bool _isSupply
    ) external view returns (AssetInfo[] memory _resultArr) {
        uint256 _assetsCount = _assetsKeys.length;
        _resultArr = new AssetInfo[](_assetsCount);

        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());

        for (uint256 i = 0; i < _assetsCount; i++) {
            bytes32 _currentKey = _assetsKeys[i];

            LiquidityPool _currentLiquidityPool =
                LiquidityPool(
                    AssetParameters(_registry.getAssetParametersContract()).liquidityPools(
                        _currentKey
                    )
                );

            require(
                address(_currentLiquidityPool) != address(0),
                "DefiCore: LiquidityPool does not exists."
            );

            address _assetAddres = _currentLiquidityPool.assetAddr();
            uint256 _userBalance = ERC20(_assetAddres).balanceOf(_userAddr);

            (uint256 _userSupplyAPY, uint256 _userBorrowAPY) =
                _rewardsDistribution.getAPY(_userAddr, _currentLiquidityPool);

            _resultArr[i] = AssetInfo(
                _assetAddres,
                _isSupply
                    ? _currentLiquidityPool.getAPY()
                    : _currentLiquidityPool.getAnnualBorrowRate(),
                _isSupply ? _userSupplyAPY : _userBorrowAPY,
                _currentLiquidityPool.getAmountInUSD(_userBalance),
                _userBalance,
                !disabledCollateralAssets[_userAddr][_currentKey]
            );
        }
    }

    function enableCollateral(bytes32 _assetKey) external returns (uint256) {
        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        require(
            _parameters.getBoolParam(_assetKey, _parameters.ENABLE_COLLATERAL_KEY()),
            "DefiCore: Asset is blocked for collateral."
        );

        require(
            disabledCollateralAssets[msg.sender][_assetKey],
            "DefiCore: Asset already enabled as collateral."
        );

        delete disabledCollateralAssets[msg.sender][_assetKey];

        return getBorrowLimitInUSD(msg.sender);
    }

    function disableCollateral(bytes32 _assetKey) external returns (uint256) {
        require(
            !disabledCollateralAssets[msg.sender][_assetKey],
            "DefiCore: Asset must be enabled as collateral."
        );

        (uint256 _availableLiquidity, ) = getAvailableLiquidity(msg.sender);
        uint256 _currentLimitPart =
            _getLimitPart(_getCurrentSupplyAmountInUSD(msg.sender, _assetKey));

        require(
            _availableLiquidity >= _currentLimitPart,
            "DefiCore: It is impossible to disable the asset as a collateral."
        );

        disabledCollateralAssets[msg.sender][_assetKey] = true;

        return getBorrowLimitInUSD(msg.sender);
    }

    function getTotalSupplyBalanceInUSD(address _userAddr) external view returns (uint256) {
        uint256 _totalSupplyBalance;
        uint256 _supplyAssetsCount = _supplyAssets[_userAddr].length();

        for (uint256 i = 0; i < _supplyAssetsCount; i++) {
            _totalSupplyBalance += _getCurrentSupplyAmountInUSD(
                _userAddr,
                _supplyAssets[_userAddr].at(i)
            );
        }

        return _totalSupplyBalance;
    }

    function getBorrowLimitInUSD(address _userAddr) public view returns (uint256) {
        uint256 _totalAmount;
        uint256 _supplyAssetsCount = _supplyAssets[_userAddr].length();

        for (uint256 i = 0; i < _supplyAssetsCount; i++) {
            bytes32 _currentAssetKey = _supplyAssets[_userAddr].at(i);
            if (!disabledCollateralAssets[_userAddr][_currentAssetKey]) {
                _totalAmount += _getCurrentSupplyAmountInUSD(_userAddr, _currentAssetKey);
            }
        }

        if (_totalAmount != 0) {
            _totalAmount = _getLimitPart(_totalAmount);
        }

        return _totalAmount;
    }

    function _getLimitPart(uint256 _amount) internal view returns (uint256) {
        SystemParameters _parameters = SystemParameters(_registry.getSystemParametersContract());

        return (_amount * DECIMAL) / _parameters.getUintParam(_parameters.COL_RATIO());
    }

    function _getCurrentSupplyAmountInUSD(address _userAddr, bytes32 _assetKey)
        internal
        view
        returns (uint256)
    {
        LiquidityPool _currentLiquidityPool =
            LiquidityPool(
                AssetParameters(_registry.getAssetParametersContract()).liquidityPools(_assetKey)
            );

        return
            _currentLiquidityPool.getAmountInUSD(
                _currentLiquidityPool.getCurrentLiquidityAmount(_userAddr)
            );
    }

    function getTotalBorrowBalanceInUSD(address _userAddr) public view returns (uint256) {
        uint256 _totalAmount;
        uint256 _borrowAssetsCount = _borrowAssets[_userAddr].length();

        for (uint256 i = 0; i < _borrowAssetsCount; i++) {
            bytes32 _currentAssetKey = _borrowAssets[_userAddr].at(i);
            LiquidityPool _currentLiquidityPool =
                LiquidityPool(
                    AssetParameters(_registry.getAssetParametersContract()).liquidityPools(
                        _currentAssetKey
                    )
                );

            _totalAmount += _currentLiquidityPool.getAmountInUSD(
                _currentLiquidityPool.getUserBorrowedAmount(_userAddr)
            );
        }

        return _totalAmount;
    }

    function getAvailableLiquidity(address _userAddr)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 _borrowedLimitInUSD = getBorrowLimitInUSD(_userAddr);
        uint256 _totalBorrowedAmountInUSD = getTotalBorrowBalanceInUSD(_userAddr);

        if (_borrowedLimitInUSD > _totalBorrowedAmountInUSD) {
            return (_borrowedLimitInUSD - _totalBorrowedAmountInUSD, 0);
        } else {
            return (0, _totalBorrowedAmountInUSD - _borrowedLimitInUSD);
        }
    }

    function addLiquidity(bytes32 _assetKey, uint256 _liquidityAmount) external returns (uint256) {
        require(_liquidityAmount > 0, "DefiCore: Liquidity amount must be greater than zero.");

        LiquidityPool _assetLiquidityPool = _getAssetLiquidityPool(_assetKey);

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateSupplyCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.addLiquidity(msg.sender, _liquidityAmount);
        emit LiquidityAdded(msg.sender, _assetKey, _liquidityAmount);

        _updateSupplyAssets(_assetKey, _assetLiquidityPool);

        return _assetLiquidityPool.getAmountInUSD(_liquidityAmount);
    }

    function withdrawLiquidity(bytes32 _assetKey, uint256 _liquidityAmount)
        external
        returns (uint256)
    {
        require(_liquidityAmount > 0, "DefiCore: Liquidity amount must be greater than zero.");

        LiquidityPool _assetLiquidityPool = _getAssetLiquidityPool(_assetKey);

        if (!disabledCollateralAssets[msg.sender][_assetKey]) {
            (uint256 _availableAmountInUSD, ) = getAvailableLiquidity(msg.sender);
            uint256 _currentAmountInUSD = _assetLiquidityPool.getAmountInUSD(_liquidityAmount);

            require(
                _availableAmountInUSD >= _currentAmountInUSD,
                "DefiCore: Not enough available liquidity."
            );
        }

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateSupplyCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.withdrawLiquidity(msg.sender, _liquidityAmount);
        emit LiquidityWithdrawn(msg.sender, _assetKey, _liquidityAmount);

        _updateSupplyAssets(_assetKey, _assetLiquidityPool);

        return _assetLiquidityPool.getAmountInUSD(_liquidityAmount);
    }

    function _getAssetLiquidityPool(bytes32 _assetKey) internal view returns (LiquidityPool) {
        LiquidityPool _assetLiquidityPool =
            LiquidityPool(
                AssetParameters(_registry.getAssetParametersContract()).liquidityPools(_assetKey)
            );

        require(
            address(_assetLiquidityPool) != address(0),
            "DefiCore: LiquidityPool doesn't exists."
        );

        return _assetLiquidityPool;
    }

    function _updateSupplyAssets(bytes32 _assetKey, LiquidityPool _assetLiquidityPool) internal {
        if (_assetLiquidityPool.getCurrentLiquidityAmount(msg.sender) == 0) {
            _supplyAssets[msg.sender].remove(_assetKey);
        } else {
            _supplyAssets[msg.sender].add(_assetKey);
        }
    }

    function _updateBorrowAssets(bytes32 _assetKey, LiquidityPool _assetLiquidityPool) internal {
        if (_assetLiquidityPool.getUserBorrowedAmount(msg.sender) == 0) {
            _borrowAssets[msg.sender].remove(_assetKey);
        } else {
            _borrowAssets[msg.sender].add(_assetKey);
        }
    }

    function addSupplyAsset(bytes32 _assetKey, address _userAddr) external onlyLiquidityPools {
        _supplyAssets[_userAddr].add(_assetKey);
    }

    function borrow(bytes32 _assetKey, uint256 _borrowAmount) external returns (uint256) {
        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        require(
            !_parameters.getBoolParam(_assetKey, _parameters.FREEZE_KEY()),
            "LiquidityPool: Pool is freeze for borrow operations."
        );

        require(_borrowAmount > 0, "DefiCore: Borrow amount must be greater than zero.");

        (uint256 _availableLiquidity, uint256 _debtAmount) = getAvailableLiquidity(msg.sender);

        require(_debtAmount == 0, "DefiCore: Unable to borrow because the account is in arrears.");

        LiquidityPool _assetLiquidityPool = _getAssetLiquidityPool(_assetKey);

        uint256 _borrowAmountInUSD = _assetLiquidityPool.getAmountInUSD(_borrowAmount);

        require(
            _availableLiquidity >= _borrowAmountInUSD,
            "DefiCore: Not enough available liquidity."
        );

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateBorrowCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.borrow(msg.sender, _borrowAmount);

        emit Borrowed(msg.sender, _assetKey, _borrowAmount);

        _updateBorrowAssets(_assetKey, _assetLiquidityPool);

        return _borrowAmountInUSD;
    }

    function repayBorrow(bytes32 _assetKey, uint256 _repayAmount) external returns (uint256) {
        require(_repayAmount > 0, "DefiCore: Zero amount cannot be repaid.");

        LiquidityPool _assetLiquidityPool = _getAssetLiquidityPool(_assetKey);

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateBorrowCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        uint256 _repayAmountInUSD = _assetLiquidityPool.repayBorrow(msg.sender, _repayAmount);

        emit BorrowRepaid(msg.sender, _assetKey, _repayAmount);

        _updateBorrowAssets(_assetKey, _assetLiquidityPool);

        return _repayAmountInUSD;
    }

    function claimDistributionRewards() external returns (uint256 _totalReward) {
        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());
        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        EnumerableSet.Bytes32Set storage _userSupplyAssets = _supplyAssets[msg.sender];

        bytes32 _currentKey;
        uint256 _assetsCount = _userSupplyAssets.length();

        for (uint256 i = 0; i < _assetsCount; i++) {
            _currentKey = _userSupplyAssets.at(i);

            _totalReward += _rewardsDistribution.withdrawUserReward(
                _currentKey,
                msg.sender,
                LiquidityPool(_parameters.liquidityPools(_currentKey))
            );
        }

        EnumerableSet.Bytes32Set storage _userBorrowAssets = _borrowAssets[msg.sender];
        _assetsCount = _userBorrowAssets.length();

        for (uint256 i = 0; i < _assetsCount; i++) {
            _currentKey = _userSupplyAssets.at(i);

            if (!_userBorrowAssets.contains(_currentKey)) {
                _totalReward += _rewardsDistribution.withdrawUserReward(
                    _currentKey,
                    msg.sender,
                    LiquidityPool(_parameters.liquidityPools(_currentKey))
                );
            }
        }

        GovernanceToken(_registry.getGovernanceTokenContract()).mintReward(
            msg.sender,
            _totalReward
        );

        emit DistributionRewardWithdrawn(msg.sender, _totalReward);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Registry.sol";

contract GovernanceToken is ERC20 {
    Registry private _registry;

    constructor(address _registryAddr) ERC20("New DeFi Governance token", "NDG") {
        _registry = Registry(_registryAddr);
    }

    modifier onlyDefiCore {
        require(
            _registry.getDefiCoreContract() == msg.sender,
            "GovernanceToken: Caller not a DefiCore"
        );
        _;
    }

    function mintReward(address _recipientAddr, uint256 _mintAmount) external onlyDefiCore {
        _mint(_recipientAddr, _mintAmount);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract InterestRateLibrary is Ownable {
    // interest rate percent per year => interest rate percent per second
    mapping(uint256 => uint256) public ratesPerSecond;

    uint256 public maxSupportedPercentage;

    constructor(uint256[] memory _ratesPerSecond) Ownable() {
        _addRates(0, _ratesPerSecond);
    }

    function addNewRates(uint256 _startPercentage, uint256[] memory _ratesPerSecond)
        external
        onlyOwner
    {
        require(
            _startPercentage == maxSupportedPercentage + 1,
            "InterestRateLibrary: Incorrect starting percentage to add."
        );

        _addRates(_startPercentage, _ratesPerSecond);
    }

    function _addRates(uint256 _startPercentage, uint256[] memory _ratesPerSecond) internal {
        uint256 _listLength = _ratesPerSecond.length;

        for (uint256 i = 0; i < _listLength; i++) {
            ratesPerSecond[_startPercentage + i] = _ratesPerSecond[i];
        }

        maxSupportedPercentage = _startPercentage + _listLength - 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./DefiCore.sol";
import "./Registry.sol";
import "./SystemParameters.sol";
import "./AssetParameters.sol";
import "./CompoundRateKeeper.sol";
import "./InterestRateLibrary.sol";
import "./common/Globals.sol";

contract LiquidityPool is ERC20 {
    Registry private _registry;

    CompoundRateKeeper public compoundRateKeeper;

    uint256 public constant UPDATE_RATE_INTERVAL = 12 hours;

    address public assetAddr;
    bytes32 public assetKey;

    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 normalizedAmount;
    }

    mapping(address => uint256) public liquidityAmounts;
    mapping(address => BorrowInfo) public borrowInfos;

    uint256 public aggregatedLiquidityAmount;
    uint256 public aggregatedBorrowedAmount;
    uint256 public aggregatedNormalizedBorrowedAmount;
    uint256 public totalReserves;

    event FundsWithdrawn(address _recipient, address _liquidityPool, uint256 _amount);

    modifier onlyDefiCore() {
        require(
            _registry.getDefiCoreContract() == msg.sender,
            "LiquidityPool: Caller not a DefiCore."
        );
        _;
    }

    modifier onlyAssetParameters() {
        require(
            _registry.getAssetParametersContract() == msg.sender,
            "LiquidityPool: Caller not an AssetParameters."
        );
        _;
    }

    constructor(
        address _registryAddr,
        address _assetAddr,
        bytes32 _assetKey,
        string memory _tokenSymbol
    ) ERC20("", string(abi.encodePacked("n", _tokenSymbol))) {
        _registry = Registry(_registryAddr);
        compoundRateKeeper = new CompoundRateKeeper();
        assetAddr = _assetAddr;
        assetKey = _assetKey;
    }

    function getCurrentLiquidityAmount(address _userAddr) external view returns (uint256) {
        return _convertNTokensToAsset(balanceOf(_userAddr));
    }

    function getTotalSupplyAmount() external view returns (uint256) {
        return aggregatedLiquidityAmount + aggregatedBorrowedAmount;
    }

    function getBorrowPercentage() public view returns (uint256) {
        return _getBorrowPercentage(0);
    }

    function _getBorrowPercentage(uint256 _additionalBorrowAmount) public view returns (uint256) {
        uint256 _absoluteBorrowAmount =
            _getAbsoluteAmount(
                aggregatedNormalizedBorrowedAmount,
                compoundRateKeeper.getCurrentRate()
            ) + _additionalBorrowAmount;
        uint256 _aggregatedLiquidityAmount = aggregatedLiquidityAmount - _additionalBorrowAmount;

        if (_aggregatedLiquidityAmount == 0 && _absoluteBorrowAmount == 0) {
            return 0;
        }

        return
            (_absoluteBorrowAmount * DECIMAL) /
            (_absoluteBorrowAmount + _aggregatedLiquidityAmount);
    }

    function exchangeRate() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            return DECIMAL;
        }

        uint256 _absoluteBorrowedAmount =
            _getAbsoluteAmount(
                aggregatedNormalizedBorrowedAmount,
                compoundRateKeeper.getCurrentRate()
            );

        return ((aggregatedLiquidityAmount + _absoluteBorrowedAmount) * DECIMAL) / _totalSupply;
    }

    function _convertAssetToNTokens(uint256 _assetAmount) internal view returns (uint256) {
        return (_assetAmount * DECIMAL) / exchangeRate();
    }

    function _convertNTokensToAsset(uint256 _nTokensAmount) internal view returns (uint256) {
        return (_nTokensAmount * exchangeRate()) / DECIMAL;
    }

    function getAnnualBorrowRate() public view returns (uint256 _annualBorrowRate) {
        uint256 _utilizationRatio = getBorrowPercentage();

        if (_utilizationRatio == 0) {
            return 0;
        }

        AssetParameters.InterestRateParams memory _params =
            AssetParameters(_registry.getAssetParametersContract()).getInterestRateParams(
                assetKey
            );
        uint256 _utilizationBreakingPoint = _params.utilizationBreakingPoint;

        if (_utilizationRatio < _utilizationBreakingPoint) {
            _annualBorrowRate = _getAnnualRate(
                0,
                _params.firstSlope,
                _utilizationRatio,
                0,
                _utilizationBreakingPoint
            );
        } else {
            _annualBorrowRate = _getAnnualRate(
                _params.firstSlope,
                _params.secondSlope,
                _utilizationRatio,
                _utilizationBreakingPoint,
                DECIMAL
            );
        }
    }

    function _getAnnualRate(
        uint256 _lowInterestPercentage,
        uint256 _highInterestPercentage,
        uint256 _currentUR,
        uint256 _lowURPercentage,
        uint256 _highURPercentage
    ) internal pure returns (uint256) {
        uint256 _interestPerPercent =
            ((_highInterestPercentage - _lowInterestPercentage) * DECIMAL) /
                (_highURPercentage - _lowURPercentage);

        return
            (_interestPerPercent * (_currentUR - _lowURPercentage)) /
            DECIMAL +
            _lowInterestPercentage;
    }

    function _convertToRatePerSecond(uint256 _interestRatePerYear)
        internal
        view
        returns (uint256)
    {
        InterestRateLibrary _library =
            InterestRateLibrary(_registry.getInterestRateLibraryContract());

        require(
            _interestRatePerYear <= _library.maxSupportedPercentage() * ONE_PERCENT,
            "LiquidityPool: Interest rate is not supported."
        );

        uint256 _leftBorder = _interestRatePerYear / ONE_PERCENT;
        uint256 _rightBorder = _leftBorder + 1;

        if (_interestRatePerYear % ONE_PERCENT == 0) {
            return _library.ratesPerSecond(_leftBorder);
        }

        uint256 _firstRatePerSecond = _library.ratesPerSecond(_leftBorder);
        uint256 _secondRatePerSecond = _library.ratesPerSecond(_rightBorder);

        return
            ((_secondRatePerSecond - _firstRatePerSecond) *
                (_interestRatePerYear - _leftBorder * ONE_PERCENT)) /
            ONE_PERCENT +
            _firstRatePerSecond;
    }

    function getAPY() external view returns (uint256) {
        SystemParameters _parameters = SystemParameters(_registry.getSystemParametersContract());
        uint256 _totalBorrowedAmount = aggregatedBorrowedAmount;
        uint256 _currentTotalSupply = totalSupply();

        if (_currentTotalSupply == 0) {
            return 0;
        }

        uint256 _currentInterest =
            _getPercentageOfNumber(_totalBorrowedAmount, DECIMAL + getAnnualBorrowRate()) -
                _totalBorrowedAmount;

        return
            (_currentInterest *
                (DECIMAL - _parameters.getUintParam(_parameters.RESERVE_FACTOR()))) /
            _currentTotalSupply;
    }

    function _getPercentageOfNumber(uint256 _number, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_number * _percentage) / DECIMAL;
    }

    function updateCompoundRate() public returns (uint256) {
        if (compoundRateKeeper.getLastUpdate() + UPDATE_RATE_INTERVAL > block.timestamp) {
            return compoundRateKeeper.getCurrentRate();
        }

        return compoundRateKeeper.update(_convertToRatePerSecond(getAnnualBorrowRate()));
    }

    function getFreezeStatus() public view returns (bool) {
        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        return _parameters.getBoolParam(assetKey, _parameters.FREEZE_KEY());
    }

    function getCurrentRate() external view returns (uint256) {
        return compoundRateKeeper.getCurrentRate();
    }

    function getUserBorrowedAmount(address _userAddr) external view returns (uint256) {
        return
            _getAbsoluteAmount(
                borrowInfos[_userAddr].normalizedAmount,
                compoundRateKeeper.getCurrentRate()
            );
    }

    function getAmountInUSD(uint256 _assetAmount) public view returns (uint256) {
        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        return
            (_assetAmount * _parameters.getAssetPrice(assetKey)) / 10**ERC20(assetAddr).decimals();
    }

    function addLiquidity(address _userAddr, uint256 _liquidityAmount) external onlyDefiCore {
        require(
            IERC20(assetAddr).balanceOf(_userAddr) >= _liquidityAmount,
            "LiquidityPool: Not enough tokens on account."
        );

        uint256 _mintAmount = _convertAssetToNTokens(_liquidityAmount);

        _mint(_userAddr, _mintAmount);

        IERC20(assetAddr).transferFrom(_userAddr, address(this), _liquidityAmount);

        aggregatedLiquidityAmount += _liquidityAmount;
        liquidityAmounts[_userAddr] += _liquidityAmount;
    }

    function withdrawLiquidity(address _userAddr, uint256 _liquidityAmount) external onlyDefiCore {
        require(
            aggregatedLiquidityAmount >= _liquidityAmount,
            "LiquidityPool: Not enough liquidity available on the contract."
        );

        uint256 _burnAmount = _convertAssetToNTokens(_liquidityAmount);

        require(
            balanceOf(_userAddr) >= _burnAmount,
            "LiquidityPool: Not enough nTokens to withdraw liquidity."
        );

        aggregatedLiquidityAmount -= _liquidityAmount;
        liquidityAmounts[_userAddr] -= _liquidityAmount;

        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        require(
            getBorrowPercentage() <
                _parameters.getUintParam(assetKey, _parameters.MAX_UTILIZATION_RATIO_KEY()),
            "LiquidityPool: Utilization ratio after withdraw cannot be greater than the maximum."
        );

        _burn(_userAddr, _burnAmount);

        IERC20(assetAddr).transfer(_userAddr, _liquidityAmount);
    }

    function borrow(address _userAddr, uint256 _amountToBorrow) external onlyDefiCore {
        uint256 _availableLiquidityAmount = aggregatedLiquidityAmount;

        require(
            _availableLiquidityAmount >= _amountToBorrow,
            "LiquidityPool: Not enough available to borrow amount."
        );

        require(!getFreezeStatus(), "LiquidityPool: Pool is freeze for borrow operations.");

        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        require(
            _getBorrowPercentage(_amountToBorrow) <
                _parameters.getUintParam(assetKey, _parameters.MAX_UTILIZATION_RATIO_KEY()),
            "LiquidityPool: Utilization ratio after borrow cannot be greater than the maximum."
        );

        uint256 _currentRate = compoundRateKeeper.getCurrentRate();

        borrowInfos[_userAddr] = BorrowInfo(
            borrowInfos[_userAddr].borrowAmount + _amountToBorrow,
            _getNormalizedAmount(
                borrowInfos[_userAddr].normalizedAmount,
                _amountToBorrow,
                _currentRate,
                true
            )
        );

        aggregatedLiquidityAmount = _availableLiquidityAmount - _amountToBorrow;
        aggregatedBorrowedAmount += _amountToBorrow;

        aggregatedNormalizedBorrowedAmount = _getNormalizedAmount(
            aggregatedNormalizedBorrowedAmount,
            _amountToBorrow,
            _currentRate,
            true
        );

        IERC20(assetAddr).transfer(_userAddr, _amountToBorrow);
    }

    function _getNormalizedAmount(
        uint256 _normalizedAmount,
        uint256 _additionalAmount,
        uint256 _currentRate,
        bool _isAdding
    ) internal pure returns (uint256) {
        uint256 _currentAbsoluteAmount = _getAbsoluteAmount(_normalizedAmount, _currentRate);

        uint256 _currentTotalAmount =
            _isAdding
                ? _currentAbsoluteAmount + _additionalAmount
                : _currentAbsoluteAmount - _additionalAmount;

        return (_currentTotalAmount * DECIMAL) / _currentRate;
    }

    function repayBorrow(address _userAddr, uint256 _repayAmount)
        external
        onlyDefiCore
        returns (uint256)
    {
        uint256 _currentRate = compoundRateKeeper.getCurrentRate();
        uint256 _currentNormalizedAmount = borrowInfos[_userAddr].normalizedAmount;
        uint256 _currentAbsoluteAmount =
            _getAbsoluteAmount(_currentNormalizedAmount, _currentRate);

        if (_currentAbsoluteAmount == 0) {
            return 0;
        }

        _repayAmount = Math.min(_currentAbsoluteAmount, _repayAmount);

        aggregatedNormalizedBorrowedAmount = _getNormalizedAmount(
            aggregatedNormalizedBorrowedAmount,
            _repayAmount,
            _currentRate,
            false
        );

        uint256 _currentInterest = _currentAbsoluteAmount - borrowInfos[_userAddr].borrowAmount;

        if (_repayAmount > _currentInterest) {
            borrowInfos[_userAddr].borrowAmount = _currentAbsoluteAmount - _repayAmount;

            aggregatedBorrowedAmount -= _repayAmount - _currentInterest;
        }

        borrowInfos[_userAddr].normalizedAmount = _getNormalizedAmount(
            _currentNormalizedAmount,
            _repayAmount,
            _currentRate,
            false
        );

        SystemParameters _parameters = SystemParameters(_registry.getSystemParametersContract());

        uint256 _reserveFunds =
            _getPercentageOfNumber(
                _currentInterest,
                _parameters.getUintParam(_parameters.RESERVE_FACTOR())
            );

        totalReserves += _reserveFunds;
        aggregatedLiquidityAmount += _repayAmount - _reserveFunds;

        IERC20(assetAddr).transferFrom(_userAddr, address(this), _repayAmount);

        return getAmountInUSD(_repayAmount);
    }

    function _getAbsoluteAmount(uint256 _normalizedAmount, uint256 _currentRate)
        internal
        pure
        returns (uint256)
    {
        return (_normalizedAmount * _currentRate) / DECIMAL;
    }

    function withdrawReservedFunds(
        address _recipientAddr,
        uint256 _amountToWithdraw,
        bool _isAllFunds
    ) external onlyAssetParameters {
        uint256 _currentReserveAmount = totalReserves;

        if (_isAllFunds) {
            _amountToWithdraw = _currentReserveAmount;
        } else {
            require(
                _amountToWithdraw <= _currentReserveAmount,
                "LiquidityPool: Not enough reserved funds."
            );
        }

        totalReserves = _currentReserveAmount - _amountToWithdraw;

        IERC20(assetAddr).transfer(_recipientAddr, _amountToWithdraw);

        emit FundsWithdrawn(_recipientAddr, address(this), _amountToWithdraw);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            DefiCore _defiCore = DefiCore(_registry.getDefiCoreContract());

            if (!_defiCore.disabledCollateralAssets(from, assetKey)) {
                (uint256 _availableAmountInUSD, uint256 _debtAmount) =
                    _defiCore.getAvailableLiquidity(from);

                require(
                    _debtAmount == 0,
                    "LiquidityPool: It is impossible to send tokens with a debt."
                );

                uint256 _amountInUSDToTransfer = getAmountInUSD(_convertNTokensToAsset(amount));

                require(
                    _availableAmountInUSD >= _amountInUSDToTransfer,
                    "LiquidityPool: Insufficient liquidity available for transfer."
                );
            }

            if (to != address(0)) {
                _defiCore.addSupplyAsset(assetKey, to);
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./LiquidityPool.sol";
import "./Registry.sol";

contract LiquidityPoolFactory {
    Registry private _registry;

    constructor(address _registryAddr) {
        _registry = Registry(_registryAddr);
    }

    modifier onlyAssetParameters() {
        require(
            _registry.getAssetParametersContract() == msg.sender,
            "LiquidityPool: Caller not an AssetParameters."
        );
        _;
    }

    function newLiquidityPool(
        address _assetAddr,
        bytes32 _assetKey,
        string memory _tokenSymbol
    ) external onlyAssetParameters returns (address) {
        return address(new LiquidityPool(address(_registry), _assetAddr, _assetKey, _tokenSymbol));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Ownable {
    // add mock oracle for every price
    mapping(bytes32 => uint256) currPrice;

    constructor() Ownable() {}

    function getAssetPrice(bytes32 _assetKey) external view override returns (uint256) {
        return currPrice[_assetKey];
    }

    //delete in future
    function setPrice(bytes32 _assetKey, uint256 _newPrice) external onlyOwner {
        currPrice[_assetKey] = _newPrice;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Registry is AccessControl {
    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant SYSTEM_PARAMETERS_NAME = keccak256("SYSTEM_PARAMETERS");
    bytes32 public constant ASSET_PARAMETERS_NAME = keccak256("ASSET_PARAMETERS");
    bytes32 public constant DEFI_CORE_NAME = keccak256("DEFI_CORE");
    bytes32 public constant INTEREST_RATE_LIBRARY_NAME = keccak256("INTEREST_RATE_LIBRARY");
    bytes32 public constant LIQUIDITY_POOL_FACTORY_NAME = keccak256("LIQUIDITY_POOL_FACTORY");
    bytes32 public constant GOVERNANCE_TOKEN_NAME = keccak256("GOVERNANCE_TOKEN");
    bytes32 public constant REWARDS_DISTRIBUTION_NAME = keccak256("REWARDS_DISTRIBUTION");

    mapping(bytes32 => address) private _contracts;

    modifier onlyAdmin() {
        require(hasRole(REGISTRY_ADMIN_ROLE, msg.sender), "Registry: Caller is not an admin");
        _;
    }

    constructor() {
        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);
    }

    function getSystemParametersContract() external view returns (address) {
        return getContract(SYSTEM_PARAMETERS_NAME);
    }

    function getAssetParametersContract() external view returns (address) {
        return getContract(ASSET_PARAMETERS_NAME);
    }

    function getDefiCoreContract() external view returns (address) {
        return getContract(DEFI_CORE_NAME);
    }

    function getInterestRateLibraryContract() external view returns (address) {
        return getContract(INTEREST_RATE_LIBRARY_NAME);
    }

    function getLiquidityPoolFactoryContract() external view returns (address) {
        return getContract(LIQUIDITY_POOL_FACTORY_NAME);
    }

    function getGovernanceTokenContract() external view returns (address) {
        return getContract(GOVERNANCE_TOKEN_NAME);
    }

    function getRewardsDistributionContract() external view returns (address) {
        return getContract(REWARDS_DISTRIBUTION_NAME);
    }

    function getContract(bytes32 _name) public view returns (address) {
        require(_contracts[_name] != address(0), "Registry: This mapping doesn't exist");

        return _contracts[_name];
    }

    function addContract(bytes32 _contractKey, address _contractAddr) external onlyAdmin {
        require(_contractAddr != address(0), "Registry: Null address is forbidden");

        _contracts[_contractKey] = _contractAddr;
    }

    function deleteContract(bytes32 _contractKey) external onlyAdmin {
        require(_contracts[_contractKey] != address(0), "Registry: This mapping doesn't exist");

        delete _contracts[_contractKey];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Registry.sol";
import "./AssetParameters.sol";
import "./LiquidityPool.sol";
import "./common/Globals.sol";

contract RewardsDistribution is Ownable {
    Registry private _registry;

    struct LiquidityPoolInfo {
        uint256 rewardPerBlock;
        DistributionInfo supplyDistributionInfo;
        DistributionInfo borrowDistributionInfo;
    }

    struct DistributionInfo {
        uint256 cumulativeSum;
        uint256 lastUpdate;
    }

    struct UserDistributionInfo {
        uint256 lastSupplyCumulativeSum;
        uint256 lastBorrowCumulativeSum;
        uint256 aggregatedReward;
    }

    mapping(bytes32 => LiquidityPoolInfo) public liquidityPoolsInfo;
    mapping(bytes32 => mapping(address => UserDistributionInfo)) public usersDistributionInfo;

    constructor(address _registryAddr) Ownable() {
        _registry = Registry(_registryAddr);
    }

    modifier onlyDefiCore {
        require(
            _registry.getDefiCoreContract() == msg.sender,
            "RewardsDistribution: Caller not a DefiCore"
        );
        _;
    }

    function updateSupplyCumulativeSum(address _userAddr, LiquidityPool _liquidityPool)
        external
        onlyDefiCore
    {
        bytes32 _assetKey = _liquidityPool.assetKey();
        uint256 _newCumulativeSum =
            _updateCumulativeSum(_assetKey, _liquidityPool, _getSupplyAttributes);

        if (_newCumulativeSum != 0) {
            _updateUserSupplyReward(_assetKey, _userAddr, _liquidityPool, _newCumulativeSum);
        }
    }

    function updateBorrowCumulativeSum(address _userAddr, LiquidityPool _liquidityPool)
        external
        onlyDefiCore
    {
        bytes32 _assetKey = _liquidityPool.assetKey();
        uint256 _newCumulativeSum =
            _updateCumulativeSum(_assetKey, _liquidityPool, _getBorrowAttributes);

        if (_newCumulativeSum != 0) {
            _updateUserBorrowReward(_assetKey, _userAddr, _liquidityPool, _newCumulativeSum);
        }
    }

    function withdrawUserReward(
        bytes32 _assetKey,
        address _userAddr,
        LiquidityPool _liquidityPool
    ) external onlyDefiCore returns (uint256 _userReward) {
        LiquidityPoolInfo storage poolInfo = liquidityPoolsInfo[_assetKey];
        UserDistributionInfo storage userInfo = usersDistributionInfo[_assetKey][_userAddr];

        _updateUserSupplyReward(
            _assetKey,
            _userAddr,
            _liquidityPool,
            poolInfo.supplyDistributionInfo.cumulativeSum
        );
        _updateUserBorrowReward(
            _assetKey,
            _userAddr,
            _liquidityPool,
            poolInfo.borrowDistributionInfo.cumulativeSum
        );

        _userReward = userInfo.aggregatedReward;

        if (_userReward > 0) {
            delete userInfo.aggregatedReward;
        }
    }

    function getAPY(address _userAddr, LiquidityPool _liquidityPool)
        external
        view
        returns (uint256 _supplyAPY, uint256 _borrowAPY)
    {
        bytes32 _assetKey = _liquidityPool.assetKey();

        if (_liquidityPool.getTotalSupplyAmount() > 0) {
            uint256 _lastCumulativeSum =
                usersDistributionInfo[_assetKey][_userAddr].lastSupplyCumulativeSum;
            _supplyAPY = _getAPY(
                _liquidityPool,
                _getSupplyAttributes,
                _liquidityPool.liquidityAmounts(_userAddr),
                _lastCumulativeSum
            );

            (uint256 _borrowAmount, ) = _liquidityPool.borrowInfos(_userAddr);

            _lastCumulativeSum = usersDistributionInfo[_assetKey][_userAddr]
                .lastBorrowCumulativeSum;
            _borrowAPY = _getAPY(
                _liquidityPool,
                _getBorrowAttributes,
                _borrowAmount,
                _lastCumulativeSum
            );
        }
    }

    function setupRewardsPerBlockBatch(
        bytes32[] calldata _assetKeys,
        uint256[] calldata _rewardsPerBlock
    ) external onlyOwner {
        uint256 _assetsCount = _assetKeys.length;
        require(_assetsCount == _rewardsPerBlock.length, "RewardsDistribution: Length mismatch.");

        AssetParameters _parameters = AssetParameters(_registry.getAssetParametersContract());

        for (uint256 i = 0; i < _assetsCount; i++) {
            bytes32 _currentKey = _assetKeys[i];

            _updateRewardPerBlock(
                _currentKey,
                _rewardsPerBlock[i],
                LiquidityPool(_parameters.liquidityPools(_currentKey))
            );
        }
    }

    function _updateRewardPerBlock(
        bytes32 _assetKey,
        uint256 _newRewardPerBlock,
        LiquidityPool _liquidityPool
    ) internal {
        uint256 _prevRewardPerBlock = liquidityPoolsInfo[_assetKey].rewardPerBlock;

        liquidityPoolsInfo[_assetKey].rewardPerBlock = _newRewardPerBlock;

        if (_prevRewardPerBlock != 0) {
            _updateCumulativeSum(_assetKey, _liquidityPool, _getSupplyAttributes);
            _updateCumulativeSum(_assetKey, _liquidityPool, _getBorrowAttributes);
        }
    }

    function _updateCumulativeSum(
        bytes32 _assetKey,
        LiquidityPool _liquidityPool,
        function(bytes32, LiquidityPool)
            view
            returns (DistributionInfo storage, uint256, uint256) _getAttributes
    ) internal returns (uint256 _newCumulativeSum) {
        (DistributionInfo storage _distributionInfo, uint256 _totalPool, uint256 _rewardPerBlock) =
            _getAttributes(_assetKey, _liquidityPool);

        uint256 _lastUpdate = _distributionInfo.lastUpdate;
        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool != 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                _rewardPerBlock,
                _totalPool,
                _distributionInfo.cumulativeSum,
                block.number - _lastUpdate
            );

            _distributionInfo.cumulativeSum = _newCumulativeSum;
        }

        _distributionInfo.lastUpdate = block.number;
    }

    function _getNewCumulativeSum(
        uint256 _rewardPerBlock,
        uint256 _totalPool,
        uint256 _prevAP,
        uint256 _blocksDelta
    ) internal pure returns (uint256) {
        uint256 _newPrice = (_rewardPerBlock * DECIMAL) / _totalPool;
        return _blocksDelta * _newPrice + _prevAP;
    }

    function _updateUserSupplyReward(
        bytes32 _assetKey,
        address _userAddr,
        LiquidityPool _liquidityPool,
        uint256 _cumulativeSum
    ) internal {
        UserDistributionInfo storage userInfo = usersDistributionInfo[_assetKey][_userAddr];

        uint256 _liquidityAmount = _liquidityPool.liquidityAmounts(_userAddr);

        if (_liquidityAmount > 0) {
            userInfo.aggregatedReward +=
                ((_cumulativeSum - userInfo.lastSupplyCumulativeSum) * _liquidityAmount) /
                DECIMAL;
        }

        userInfo.lastSupplyCumulativeSum = _cumulativeSum;
    }

    function _updateUserBorrowReward(
        bytes32 _assetKey,
        address _userAddr,
        LiquidityPool _liquidityPool,
        uint256 _cumulativeSum
    ) internal {
        UserDistributionInfo storage userInfo = usersDistributionInfo[_assetKey][_userAddr];

        (uint256 _borrowAmount, ) = _liquidityPool.borrowInfos(_userAddr);

        if (_borrowAmount > 0) {
            userInfo.aggregatedReward +=
                ((_cumulativeSum - userInfo.lastBorrowCumulativeSum) * _borrowAmount) /
                DECIMAL;
        }

        userInfo.lastBorrowCumulativeSum = _cumulativeSum;
    }

    function _getSupplyAttributes(bytes32 _assetKey, LiquidityPool _liquidityPool)
        internal
        view
        returns (
            DistributionInfo storage _distributionInfo,
            uint256 _totalPool,
            uint256 _rewardPerBlock
        )
    {
        _distributionInfo = liquidityPoolsInfo[_assetKey].supplyDistributionInfo;
        _totalPool = _liquidityPool.getTotalSupplyAmount();
        (_rewardPerBlock, ) = _getRewardsPerBlock(_assetKey, _liquidityPool.getBorrowPercentage());
    }

    function _getBorrowAttributes(bytes32 _assetKey, LiquidityPool _liquidityPool)
        internal
        view
        returns (
            DistributionInfo storage _distributionInfo,
            uint256 _totalPool,
            uint256 _rewardPerBlock
        )
    {
        _distributionInfo = liquidityPoolsInfo[_assetKey].borrowDistributionInfo;
        _totalPool = _liquidityPool.aggregatedBorrowedAmount();
        (, _rewardPerBlock) = _getRewardsPerBlock(_assetKey, _liquidityPool.getBorrowPercentage());
    }

    function _getAPY(
        LiquidityPool _liquidityPool,
        function(bytes32, LiquidityPool)
            view
            returns (DistributionInfo storage, uint256, uint256) _getAttributes,
        uint256 _userAmount,
        uint256 _lastCumulativeSum
    ) internal view returns (uint256 _resultAPY) {
        bytes32 _assetKey = _liquidityPool.assetKey();

        if (_userAmount > 0) {
            (
                DistributionInfo memory _distributionInfo,
                uint256 _totalPool,
                uint256 _rewardPerBlock
            ) = _getAttributes(_assetKey, _liquidityPool);

            uint256 _newCumulativeSum =
                _getNewCumulativeSum(
                    _rewardPerBlock,
                    _totalPool,
                    _distributionInfo.cumulativeSum,
                    BLOCKS_PER_YEAR
                );

            uint256 _totalReward =
                ((_newCumulativeSum - _lastCumulativeSum) * _userAmount) / DECIMAL;

            LiquidityPool _governanceLP =
                AssetParameters(_registry.getAssetParametersContract())
                    .getGovernanceLiquidityPool();

            _resultAPY =
                (_governanceLP.getAmountInUSD(_totalReward) * DECIMAL) /
                _liquidityPool.getAmountInUSD(_userAmount);
        }
    }

    function _getRewardsPerBlock(bytes32 _assetKey, uint256 _currentUR)
        internal
        view
        returns (uint256 _supplyRewardPerBlock, uint256 _borrowRewardPerBlock)
    {
        (uint256 _minSupplyPart, uint256 _minBorrowPart) =
            AssetParameters(_registry.getAssetParametersContract()).getDistributionMinimums(
                _assetKey
            );

        uint256 _totalRewardPerBlock = liquidityPoolsInfo[_assetKey].rewardPerBlock;

        uint256 _supplyRewardPerBlockPart =
            ((DECIMAL - _minBorrowPart - _minSupplyPart) * _currentUR) / DECIMAL + _minSupplyPart;

        _supplyRewardPerBlock = (_totalRewardPerBlock * _supplyRewardPerBlockPart) / DECIMAL;
        _borrowRewardPerBlock = _totalRewardPerBlock - _supplyRewardPerBlock;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISystemParameters.sol";
import "./LiquidityPool.sol";
import "./common/PureParameters.sol";

contract SystemParameters is Ownable, ISystemParameters {
    using PureParameters for PureParameters.Param;

    address private _registryAddr;

    bytes32 public constant COL_RATIO = keccak256("COL_RATIO");
    bytes32 public constant RESERVE_FACTOR = keccak256("RESERVE_FACTOR");

    mapping(bytes32 => PureParameters.Param) private _parameters;

    constructor(address registryAddr_) Ownable() {
        _registryAddr = registryAddr_;
    }

    function addUintParam(bytes32 _paramKey, uint256 _value) external {
        _addParam(_paramKey, PureParameters.makeUintParam(_value));
    }

    function addBytes32Param(bytes32 _paramKey, bytes32 _value) external {
        _addParam(_paramKey, PureParameters.makeBytes32Param(_value));
    }

    function addAddrParam(bytes32 _paramKey, address _value) external {
        _addParam(_paramKey, PureParameters.makeAdrressParam(_value));
    }

    function _addParam(bytes32 _paramKey, PureParameters.Param memory _param) internal onlyOwner {
        _parameters[_paramKey] = _param;

        emit ParamAdded(_paramKey);
    }

    function getUintParam(bytes32 _paramKey) external view override returns (uint256) {
        return _getParam(_paramKey).getUintFromParam();
    }

    function getBytes32Param(bytes32 _paramKey) external view override returns (bytes32) {
        return _getParam(_paramKey).getBytes32FromParam();
    }

    function getAddressParam(bytes32 _paramKey) external view override returns (address) {
        return _getParam(_paramKey).getAdrressFromParam();
    }

    function getBoolParam(bytes32 _paramKey) external view override returns (bool) {
        return _getParam(_paramKey).getBoolFromParam();
    }

    function _getParam(bytes32 _paramKey) internal view returns (PureParameters.Param memory) {
        require(
            PureParameters.paramExists(_parameters[_paramKey]),
            "SystemParameters: Param for this asset doesn't exist."
        );

        return _parameters[_paramKey];
    }

    function removeParam(bytes32 _paramKey) external onlyOwner {
        require(
            PureParameters.paramExists(_parameters[_paramKey]),
            "SystemParameters: Param for this asset doesn't."
        );

        delete _parameters[_paramKey];

        emit ParamRemoved(_paramKey);
    }
}

// SPDX-License-Identifier: ALGPL-3.0-or-later-or-later
// from https://github.com/makerdao/dss/blob/master/src/jug.sol
pragma solidity 0.8.3;

library DSMath {
    /// @dev github.com/makerdao/dss implementation
    /// of exponentiation by squaring
    //  nth power of x mod b
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := b
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := b
                        }
                        default {
                            z := x
                        }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

library PureParameters {
    enum Types {NOT_EXIST, UINT, ADDRESS, BYTES32, BOOL}

    struct Param {
        uint256 uintParam;
        address addressParam;
        bytes32 bytes32Param;
        bool boolParam;
        Types currentType;
    }

    function makeUintParam(uint256 _num) internal pure returns (Param memory) {
        return
            Param({
                uintParam: _num,
                currentType: Types.UINT,
                addressParam: address(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getUintFromParam(Param memory _param) internal pure returns (uint256) {
        require(_param.currentType == Types.UINT, "PureParameters: Parameter not contain uint.");

        return _param.uintParam;
    }

    function makeAdrressParam(address _address) internal pure returns (Param memory) {
        return
            Param({
                addressParam: _address,
                currentType: Types.ADDRESS,
                uintParam: uint256(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getAdrressFromParam(Param memory _param) internal pure returns (address) {
        require(
            _param.currentType == Types.ADDRESS,
            "PureParameters: Parameter not contain address."
        );

        return _param.addressParam;
    }

    function makeBytes32Param(bytes32 _hash) internal pure returns (Param memory) {
        return
            Param({
                bytes32Param: _hash,
                currentType: Types.BYTES32,
                addressParam: address(0),
                uintParam: uint256(0),
                boolParam: false
            });
    }

    function getBytes32FromParam(Param memory _param) internal pure returns (bytes32) {
        require(
            _param.currentType == Types.BYTES32,
            "PureParameters: Parameter not contain bytes32."
        );

        return _param.bytes32Param;
    }

    function makeBoolParam(bool _bool) internal pure returns (Param memory) {
        return
            Param({
                boolParam: _bool,
                currentType: Types.BOOL,
                addressParam: address(0),
                uintParam: uint256(0),
                bytes32Param: bytes32(0)
            });
    }

    function getBoolFromParam(Param memory _param) internal pure returns (bool) {
        require(_param.currentType == Types.BOOL, "PureParameters: Parameter not contain bool.");

        return _param.boolParam;
    }

    function paramExists(Param memory _param) internal pure returns (bool) {
        return (_param.currentType != Types.NOT_EXIST);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IAssetParameters {
    event ParamAdded(bytes32 _assetKey, bytes32 _paramKey);
    event ParamRemoved(bytes32 _assetKey, bytes32 _paramKey);
    event PoolAdded(bytes32 _assetKey, address _assetAddr, address _poolAddr);
    event PoolDeleted(bytes32 _assetKey);
    event Freezed(bytes32 _assetKey);

    function getUintParam(bytes32 _assetKey, bytes32 _paramKey) external view returns (uint256);

    function getBytes32Param(bytes32 _assetKey, bytes32 _paramKey) external view returns (bytes32);

    function getAddressParam(bytes32 _assetKey, bytes32 _paramKey) external view returns (address);

    function getBoolParam(bytes32 _assetKey, bytes32 _paramKey) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IDefiCore {
    function getAvailableLiquidity(address _userAddr) external view returns (uint256, uint256);

    struct SupplyAssetInfo {
        address assetAddr;
        uint256 supplyAPY;
        uint256 distributionSupplyAPY;
        uint256 userSupplyBalanceInUSD;
        uint256 userSupplyBalance;
        bool isCollateralEnabled;
    }

    struct BorrowAssetInfo {
        address assetAddr;
        uint256 borrowAPY;
        uint256 distributionBorrowAPY;
        uint256 userBorrowBalanceInUSD;
        uint256 userBorrowBalance;
        uint256 borrowPercentage;
    }

    struct AssetInfo {
        address assetAddr;
        uint256 apy;
        uint256 distributionAPY;
        uint256 userBalanceInUSD;
        uint256 userBalance;
        bool isCollateralEnabled;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IPriceOracle {
    function getAssetPrice(bytes32 _assetKey) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ISystemParameters {
    event ParamAdded(bytes32 _paramKey);
    event ParamRemoved(bytes32 _paramKey);

    function getUintParam(bytes32 _paramKey) external view returns (uint256);

    function getBytes32Param(bytes32 _paramKey) external view returns (bytes32);

    function getAddressParam(bytes32 _paramKey) external view returns (address);

    function getBoolParam(bytes32 _paramKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}