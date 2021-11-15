// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IDefiCore.sol";
import "./interfaces/ISystemParameters.sol";
import "./interfaces/IAssetParameters.sol";
import "./interfaces/IAssetsRegistry.sol";
import "./interfaces/ILiquidityPool.sol";

import "./libraries/AssetsHelperLibrary.sol";

import "./Registry.sol";
import "./RewardsDistribution.sol";
import "./GovernanceToken.sol";
import "./common/Globals.sol";

contract DefiCore is IDefiCore {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using AssetsHelperLibrary for bytes32;

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
            IAssetParameters(_registry.getAssetParametersContract()).existingLiquidityPools(
                msg.sender
            ),
            "DefiCore: Caller not a LiquidityPool"
        );
        _;
    }

    constructor(address _registryAddr) {
        _registry = Registry(_registryAddr);
    }

    function isCollateralAssetEnabled(address _userAddr, bytes32 _assetKey)
        public
        view
        override
        returns (bool)
    {
        if (
            IAssetParameters(_registry.getAssetParametersContract()).isAvailableAsCollateral(
                _assetKey
            ) && !disabledCollateralAssets[_userAddr][_assetKey]
        ) {
            return true;
        }

        return false;
    }

    function getMaxQuantity(
        address _userAddr,
        bytes32 _supplyAssetKey,
        bytes32 _borrowAssetKey
    ) external view returns (uint256) {
        IAssetParameters _assetParameters =
            IAssetParameters(_registry.getAssetParametersContract());

        return
            _supplyAssetKey.getMaxQuantity(
                _userAddr,
                ILiquidityPool(_assetParameters.liquidityPools(_supplyAssetKey)),
                ILiquidityPool(_assetParameters.liquidityPools(_borrowAssetKey)),
                _assetParameters,
                ISystemParameters(_registry.getSystemParametersContract())
            );
    }

    function getTotalSupplyBalanceInUSD(address _userAddr)
        external
        view
        returns (uint256 _totalSupplyBalance)
    {
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());
        bytes32[] memory _userSupplyAssets =
            IAssetsRegistry(_registry.getAssetsRegistryContract()).getUserSupplyAssets(_userAddr);

        for (uint256 i = 0; i < _userSupplyAssets.length; i++) {
            _totalSupplyBalance += _userSupplyAssets[i].getCurrentSupplyAmountInUSD(
                _userAddr,
                _parameters
            );
        }
    }

    function getTotalBorrowBalanceInUSD(address _userAddr)
        public
        view
        returns (uint256 _totalBorrowBalance)
    {
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());
        bytes32[] memory _userBorrowAssets =
            IAssetsRegistry(_registry.getAssetsRegistryContract()).getUserBorrowAssets(_userAddr);

        for (uint256 i = 0; i < _userBorrowAssets.length; i++) {
            _totalBorrowBalance += _userBorrowAssets[i].getCurrentBorrowAmountInUSD(
                _userAddr,
                _parameters
            );
        }
    }

    function getCurrentBorrowLimitInUSD(address _userAddr)
        public
        view
        returns (uint256 _currentBorrowLimit)
    {
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());
        bytes32[] memory _userSupplyAssets =
            IAssetsRegistry(_registry.getAssetsRegistryContract()).getUserSupplyAssets(_userAddr);

        for (uint256 i = 0; i < _userSupplyAssets.length; i++) {
            bytes32 _currentAssetKey = _userSupplyAssets[i];

            if (isCollateralAssetEnabled(_userAddr, _currentAssetKey)) {
                uint256 _currentTokensAmount =
                    _currentAssetKey.getCurrentSupplyAmountInUSD(_userAddr, _parameters);

                _currentBorrowLimit += _currentAssetKey.getLimitPart(
                    _currentTokensAmount,
                    _parameters
                );
            }
        }
    }

    function getNewBorrowLimitInUSD(
        address _userAddr,
        bytes32 _assetKey,
        uint256 _tokensAmount,
        bool _isAdding
    ) public view returns (uint256) {
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());

        uint256 _newLimit = getCurrentBorrowLimitInUSD(_userAddr);

        if (!isCollateralAssetEnabled(_userAddr, _assetKey)) {
            return _newLimit;
        }

        ILiquidityPool _liquidityPool = _assetKey.getAssetLiquidityPool(_parameters);

        uint256 _newAmount =
            _assetKey.getLimitPart(_liquidityPool.getAmountInUSD(_tokensAmount), _parameters);

        if (_isAdding) {
            _newLimit += _newAmount;
        } else if (_newAmount <= _newLimit) {
            _newLimit -= _newAmount;
        } else {
            _newLimit = 0;
        }

        return _newLimit;
    }

    function getAvailableLiquidity(address _userAddr)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 _borrowedLimitInUSD = getCurrentBorrowLimitInUSD(_userAddr);
        uint256 _totalBorrowedAmountInUSD = getTotalBorrowBalanceInUSD(_userAddr);

        if (_borrowedLimitInUSD > _totalBorrowedAmountInUSD) {
            return (_borrowedLimitInUSD - _totalBorrowedAmountInUSD, 0);
        } else {
            return (0, _totalBorrowedAmountInUSD - _borrowedLimitInUSD);
        }
    }

    function getUserDistributionRewards(address _userAddr)
        external
        view
        returns (RewardsDistributionInfo memory)
    {
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());
        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());

        bytes32[] memory _allAssets = _parameters.getSupportedAssets();

        uint256 _totalReward;

        for (uint256 i = 0; i < _allAssets.length; i++) {
            _totalReward += _rewardsDistribution.getUserReward(
                _allAssets[i],
                _userAddr,
                _allAssets[i].getAssetLiquidityPool(_parameters)
            );
        }

        ILiquidityPool _governancePool = ILiquidityPool(_parameters.getGovernanceLiquidityPool());
        IERC20 _governanceToken = IERC20(_registry.getGovernanceTokenContract());

        uint256 _userBalance = _governanceToken.balanceOf(_userAddr);

        return
            RewardsDistributionInfo(
                address(_governanceToken),
                _totalReward,
                _governancePool.getAmountInUSD(_totalReward),
                _userBalance,
                _governancePool.getAmountInUSD(_userBalance)
            );
    }

    function updateCompoundRate(bytes32 _assetKey) external {
        _assetKey
            .getAssetLiquidityPool(IAssetParameters(_registry.getAssetParametersContract()))
            .updateCompoundRate();
    }

    function enableCollateral(bytes32 _assetKey) external returns (uint256) {
        require(
            IAssetParameters(_registry.getAssetParametersContract()).isAvailableAsCollateral(
                _assetKey
            ),
            "DefiCore: Asset is blocked for collateral."
        );

        require(
            disabledCollateralAssets[msg.sender][_assetKey],
            "DefiCore: Asset already enabled as collateral."
        );

        delete disabledCollateralAssets[msg.sender][_assetKey];

        return getCurrentBorrowLimitInUSD(msg.sender);
    }

    function disableCollateral(bytes32 _assetKey) external returns (uint256) {
        require(
            !disabledCollateralAssets[msg.sender][_assetKey],
            "DefiCore: Asset must be enabled as collateral."
        );

        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());
        uint256 _currentSupplyAmount =
            _assetKey.getCurrentSupplyAmountInUSD(msg.sender, _parameters);

        if (_parameters.isAvailableAsCollateral(_assetKey) && _currentSupplyAmount > 0) {
            (uint256 _availableLiquidity, ) = getAvailableLiquidity(msg.sender);
            uint256 _currentLimitPart = _assetKey.getLimitPart(_currentSupplyAmount, _parameters);

            require(
                _availableLiquidity >= _currentLimitPart,
                "DefiCore: It is impossible to disable the asset as a collateral."
            );
        }

        disabledCollateralAssets[msg.sender][_assetKey] = true;

        return getCurrentBorrowLimitInUSD(msg.sender);
    }

    function addLiquidity(bytes32 _assetKey, uint256 _liquidityAmount) external {
        require(_liquidityAmount > 0, "DefiCore: Liquidity amount must be greater than zero.");

        ILiquidityPool _assetLiquidityPool =
            _assetKey.getAssetLiquidityPool(
                IAssetParameters(_registry.getAssetParametersContract())
            );

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateSupplyCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.addLiquidity(msg.sender, _liquidityAmount);
        emit LiquidityAdded(msg.sender, _assetKey, _liquidityAmount);

        IAssetsRegistry(_registry.getAssetsRegistryContract()).updateSupplyAssets(
            msg.sender,
            _assetKey,
            address(_assetLiquidityPool)
        );
    }

    function withdrawLiquidity(bytes32 _assetKey, uint256 _liquidityAmount) external {
        require(_liquidityAmount > 0, "DefiCore: Liquidity amount must be greater than zero.");

        ILiquidityPool _assetLiquidityPool =
            _assetKey.getAssetLiquidityPool(
                IAssetParameters(_registry.getAssetParametersContract())
            );

        if (isCollateralAssetEnabled(msg.sender, _assetKey)) {
            uint256 _newBorrowLimit =
                getNewBorrowLimitInUSD(msg.sender, _assetKey, _liquidityAmount, false);
            require(
                _newBorrowLimit >= getTotalBorrowBalanceInUSD(msg.sender),
                "DefiCore: Borrow limit used greater than 100%."
            );
        }

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateSupplyCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.withdrawLiquidity(msg.sender, _liquidityAmount);
        emit LiquidityWithdrawn(msg.sender, _assetKey, _liquidityAmount);

        IAssetsRegistry(_registry.getAssetsRegistryContract()).updateSupplyAssets(
            msg.sender,
            _assetKey,
            address(_assetLiquidityPool)
        );
    }

    function borrow(bytes32 _assetKey, uint256 _borrowAmount) external {
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());

        require(
            !_parameters.isPoolFrozen(_assetKey),
            "ILiquidityPool: Pool is freeze for borrow operations."
        );

        require(_borrowAmount > 0, "DefiCore: Borrow amount must be greater than zero.");

        (uint256 _availableLiquidity, uint256 _debtAmount) = getAvailableLiquidity(msg.sender);

        require(_debtAmount == 0, "DefiCore: Unable to borrow because the account is in arrears.");

        ILiquidityPool _assetLiquidityPool = _assetKey.getAssetLiquidityPool(_parameters);

        require(
            _availableLiquidity >= _assetLiquidityPool.getAmountInUSD(_borrowAmount),
            "DefiCore: Not enough available liquidity."
        );

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateBorrowCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.borrow(msg.sender, _borrowAmount);

        emit Borrowed(msg.sender, _assetKey, _borrowAmount);

        IAssetsRegistry(_registry.getAssetsRegistryContract()).updateBorrowAssets(
            msg.sender,
            _assetKey,
            address(_assetLiquidityPool)
        );
    }

    function repayBorrow(bytes32 _assetKey, uint256 _repayAmount) external {
        require(_repayAmount > 0, "DefiCore: Zero amount cannot be repaid.");

        ILiquidityPool _assetLiquidityPool =
            _assetKey.getAssetLiquidityPool(
                IAssetParameters(_registry.getAssetParametersContract())
            );

        RewardsDistribution(_registry.getRewardsDistributionContract()).updateBorrowCumulativeSum(
            msg.sender,
            _assetLiquidityPool
        );

        _assetLiquidityPool.repayBorrow(msg.sender, _repayAmount);

        emit BorrowRepaid(msg.sender, _assetKey, _repayAmount);

        IAssetsRegistry(_registry.getAssetsRegistryContract()).updateBorrowAssets(
            msg.sender,
            _assetKey,
            address(_assetLiquidityPool)
        );
    }

    function liquidation(
        address _userAddr,
        bytes32 _supplyAssetKey,
        bytes32 _borrowAssetKey,
        uint256 _liquidationAmount
    ) external {
        (, uint256 _debtAmount) = getAvailableLiquidity(_userAddr);
        require(_debtAmount != 0, "DefiCore: Not enough dept for liquidation.");

        require(_liquidationAmount > 0, "DefiCore: Liquidation amount should be more then zero.");

        IAssetParameters _assetParameters =
            IAssetParameters(_registry.getAssetParametersContract());

        ISystemParameters _systemParameters =
            ISystemParameters(_registry.getSystemParametersContract());

        ILiquidityPool _borrowAssetsPool =
            ILiquidityPool(_assetParameters.liquidityPools(_borrowAssetKey));

        ILiquidityPool _supplyAssetsPool =
            ILiquidityPool(_assetParameters.liquidityPools(_supplyAssetKey));

        require(
            _liquidationAmount <=
                _supplyAssetKey.getMaxQuantity(
                    _userAddr,
                    _supplyAssetsPool,
                    _borrowAssetsPool,
                    _assetParameters,
                    _systemParameters
                ),
            "DefiCore: Liquidation amount should be less then max quantity."
        );

        emit LiquidateBorrow(_borrowAssetKey, _userAddr, _liquidationAmount);

        uint256 _liquidationAmountInUsd =
            _borrowAssetsPool.liquidationBorrow(_userAddr, msg.sender, _liquidationAmount);

        uint256 _repayAmount =
            _supplyAssetKey.getRepayLiquidationAmount(
                _supplyAssetsPool.getAmountFromUSD(_liquidationAmountInUsd),
                _assetParameters
            );

        emit LiquidatorPay(_supplyAssetKey, msg.sender, _repayAmount);

        _supplyAssetsPool.liquidate(_userAddr, msg.sender, _repayAmount);
    }

    function claimPoolDistributionRewards(bytes32 _assetKey) external returns (uint256 _reward) {
        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());

        _reward = _rewardsDistribution.withdrawUserReward(
            _assetKey,
            msg.sender,
            ILiquidityPool(_parameters.liquidityPools(_assetKey))
        );

        require(_reward > 0, "DefiCore: User have not rewards from this pool");

        IERC20 _governanceToken = IERC20(_registry.getGovernanceTokenContract());

        require(
            _governanceToken.balanceOf(address(this)) >= _reward,
            "DefiCore: Not enough governance tokens on the contract."
        );

        _governanceToken.transfer(msg.sender, _reward);

        emit DistributionRewardWithdrawn(msg.sender, _reward);
    }

    function claimDistributionRewards() external returns (uint256 _totalReward) {
        RewardsDistribution _rewardsDistribution =
            RewardsDistribution(_registry.getRewardsDistributionContract());
        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());

        bytes32[] memory _assetKeys = _parameters.getSupportedAssets();

        for (uint256 i = 0; i < _assetKeys.length; i++) {
            _totalReward += _rewardsDistribution.withdrawUserReward(
                _assetKeys[i],
                msg.sender,
                ILiquidityPool(_parameters.liquidityPools(_assetKeys[i]))
            );
        }

        require(_totalReward > 0, "DefiCore: Nothing to claim.");

        IERC20 _governanceToken = IERC20(_registry.getGovernanceTokenContract());

        require(
            _governanceToken.balanceOf(address(this)) >= _totalReward,
            "DefiCore: Not enough governance tokens on the contract."
        );

        _governanceToken.transfer(msg.sender, _totalReward);

        emit DistributionRewardWithdrawn(msg.sender, _totalReward);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Registry.sol";

contract GovernanceToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 69_000_000 * 10**18;

    constructor(address _recipient) ERC20("New DeFi Governance", "NDG") {
        _mint(_recipient, TOTAL_SUPPLY);
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
    bytes32 public constant PRICE_MANAGER_NAME = keccak256("PRICE_MANAGER");
    bytes32 public constant ASSETS_REGISTRY_NAME = keccak256("ASSETS_REGISTRY");

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

    function getPriceManagerContract() external view returns (address) {
        return getContract(PRICE_MANAGER_NAME);
    }

    function getAssetsRegistryContract() external view returns (address) {
        return getContract(ASSETS_REGISTRY_NAME);
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

import "./interfaces/IAssetParameters.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/ILiquidityPool.sol";

import "./common/Globals.sol";
import "./Registry.sol";

contract RewardsDistribution is IRewardsDistribution, Ownable {
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

    function updateSupplyCumulativeSum(address _userAddr, ILiquidityPool _liquidityPool)
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

    function updateBorrowCumulativeSum(address _userAddr, ILiquidityPool _liquidityPool)
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
        ILiquidityPool _liquidityPool
    ) external onlyDefiCore returns (uint256 _userReward) {
        _updateUserSupplyReward(
            _assetKey,
            _userAddr,
            _liquidityPool,
            _updateCumulativeSum(_assetKey, _liquidityPool, _getSupplyAttributes)
        );
        _updateUserBorrowReward(
            _assetKey,
            _userAddr,
            _liquidityPool,
            _updateCumulativeSum(_assetKey, _liquidityPool, _getBorrowAttributes)
        );

        UserDistributionInfo storage userInfo = usersDistributionInfo[_assetKey][_userAddr];

        _userReward = userInfo.aggregatedReward;

        if (_userReward > 0) {
            delete userInfo.aggregatedReward;
        }
    }

    function getAPY(address _userAddr, address _liquidityPoolAddr)
        external
        view
        override
        returns (uint256 _supplyAPY, uint256 _borrowAPY)
    {
        ILiquidityPool _liquidityPool = ILiquidityPool(_liquidityPoolAddr);
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

        IAssetParameters _parameters = IAssetParameters(_registry.getAssetParametersContract());

        for (uint256 i = 0; i < _assetsCount; i++) {
            bytes32 _currentKey = _assetKeys[i];

            _updateRewardPerBlock(
                _currentKey,
                _rewardsPerBlock[i],
                ILiquidityPool(_parameters.liquidityPools(_currentKey))
            );
        }
    }

    function _updateRewardPerBlock(
        bytes32 _assetKey,
        uint256 _newRewardPerBlock,
        ILiquidityPool _liquidityPool
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
        ILiquidityPool _liquidityPool,
        function(bytes32, ILiquidityPool)
            view
            returns (DistributionInfo storage, uint256, uint256) _getAttributes
    ) internal returns (uint256 _newCumulativeSum) {
        (DistributionInfo storage _distributionInfo, uint256 _totalPool, uint256 _rewardPerBlock) =
            _getAttributes(_assetKey, _liquidityPool);

        uint256 _lastUpdate = _distributionInfo.lastUpdate;
        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool != 0 && _lastUpdate != block.timestamp) {
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
        ILiquidityPool _liquidityPool,
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
        ILiquidityPool _liquidityPool,
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

    function _getSupplyAttributes(bytes32 _assetKey, ILiquidityPool _liquidityPool)
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

    function _getBorrowAttributes(bytes32 _assetKey, ILiquidityPool _liquidityPool)
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
        ILiquidityPool _liquidityPool,
        function(bytes32, ILiquidityPool)
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

            ILiquidityPool _governanceLP =
                ILiquidityPool(
                    IAssetParameters(_registry.getAssetParametersContract())
                        .getGovernanceLiquidityPool()
                );

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
            IAssetParameters(_registry.getAssetParametersContract()).getDistributionMinimums(
                _assetKey
            );

        uint256 _totalRewardPerBlock = liquidityPoolsInfo[_assetKey].rewardPerBlock;

        uint256 _supplyRewardPerBlockPart =
            ((DECIMAL - _minBorrowPart - _minSupplyPart) * _currentUR) / DECIMAL + _minSupplyPart;

        _supplyRewardPerBlock = (_totalRewardPerBlock * _supplyRewardPerBlockPart) / DECIMAL;
        _borrowRewardPerBlock = _totalRewardPerBlock - _supplyRewardPerBlock;
    }

    function _getUserReward(
        bytes32 _assetKey,
        ILiquidityPool _liquidityPool,
        uint256 _amount,
        uint256 _lastCumulativeSum,
        function(bytes32, ILiquidityPool)
            view
            returns (DistributionInfo storage, uint256, uint256) _getAttributes
    ) internal view returns (uint256 _newReward) {
        (DistributionInfo storage _distributionInfo, uint256 _totalPool, uint256 _rewardPerBlock) =
            _getAttributes(_assetKey, _liquidityPool);

        uint256 _lastUpdate = _distributionInfo.lastUpdate;
        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        uint256 _newCumulativeSum = 0;

        if (_totalPool != 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                _rewardPerBlock,
                _totalPool,
                _distributionInfo.cumulativeSum,
                block.number - _lastUpdate
            );
        }

        if (_amount > 0) {
            _newReward = ((_newCumulativeSum - _lastCumulativeSum) * _amount) / DECIMAL;
        }
    }

    function getUserReward(
        bytes32 _assetKey,
        address _userAddr,
        ILiquidityPool _liquidityPool
    ) external view returns (uint256 _result) {
        UserDistributionInfo storage userInfo = usersDistributionInfo[_assetKey][_userAddr];

        _result = userInfo.aggregatedReward;

        (uint256 _borrowAmount, ) = _liquidityPool.borrowInfos(_userAddr);

        _result += _getUserReward(
            _assetKey,
            _liquidityPool,
            _borrowAmount,
            userInfo.lastBorrowCumulativeSum,
            _getBorrowAttributes
        );

        uint256 _liquidityAmount = _liquidityPool.liquidityAmounts(_userAddr);

        _result += _getUserReward(
            _assetKey,
            _liquidityPool,
            _liquidityAmount,
            userInfo.lastSupplyCumulativeSum,
            _getSupplyAttributes
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint8 constant PRICE_DECIMALS = 8;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IAssetParameters {
    event PoolAdded(bytes32 _assetKey, address _assetAddr, address _poolAddr);

    event UintParamUpdated(bytes32 _assetKey, bytes32 _paramKey, uint256 _newValue);
    event BoolParamUpdated(bytes32 _assetKey, bytes32 _paramKey, bool _newValue);

    struct InterestRateParams {
        uint256 basePercentage;
        uint256 firstSlope;
        uint256 secondSlope;
        uint256 utilizationBreakingPoint;
    }

    /**
     * @notice Returns the address of the liquidity pool by the asset key
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return address of the liquidity pool
     */
    function liquidityPools(bytes32 _assetKey) external view returns (address);

    /**
     * @notice Indicates whether the address is a liquidity pool
     * @param _poolAddr Address of the liquidity pool
     * @return true if the passed address is a liquidity pool, false otherwise
     */
    function existingLiquidityPools(address _poolAddr) external view returns (bool);

    /**
     * @notice Shows whether the pool is frozen by the given key
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return true if the liquidation pool is frozen, false otherwise
     */
    function isPoolFrozen(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Shows the ability of an aset to be a collateral
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return true if the liquidation pool is frozen, false otherwise
     */
    function isAvailableAsCollateral(bytes32 _assetKey) external view returns (bool);

    /**
     * @notice Returns the keys of all aspects that the system supports
     * @return _resultArr - keys array
     */
    function getSupportedAssets() external view returns (bytes32[] memory _resultArr);

    /**
     * @notice Returns the address of the liquidity pool for the governance token
     * @return liquidity pool address for the governance token
     */
    function getGovernanceLiquidityPool() external view returns (address);

    /**
     * @notice Returns parameters for calculating interest rates on a loan
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return _params - structure object with parameters for calculating interest rates
     */
    function getInterestRateParams(bytes32 _assetKey)
        external
        view
        returns (InterestRateParams memory _params);

    /**
     * @notice Returns the maximum possible utilization ratio
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return maximum possible utilization ratio
     */
    function getMaxUtilizationRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the discount for the liquidator in the desired pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return liquidation discount
     */
    function getLiquidationDiscount(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the minimum percentages of the parties for the distribution of governance tokens
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return _minSupplyPart the minimum part that goes to depositors
     * @return _minBorrowPart the minimum part that goes to borrowers
     */
    function getDistributionMinimums(bytes32 _assetKey)
        external
        view
        returns (uint256 _minSupplyPart, uint256 _minBorrowPart);

    /**
     * @notice Returns the collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current collateralization ratio value
     */
    function getColRatio(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the collateralization ratio for the required pool
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return current reserve factor value
     */
    function getReserveFactor(bytes32 _assetKey) external view returns (uint256);

    /**
     * @notice Returns the price of a token in dollars
     * @param _assetKey Asset key obtained by converting the asset character to bytes
     * @return asset price
     */
    function getAssetPrice(bytes32 _assetKey, uint8 _assetDecimals)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IAssetsRegistry {
    struct SupplyAssetInfo {
        address assetAddr;
        uint256 supplyAPY;
        uint256 distributionSupplyAPY;
        uint256 userSupplyBalanceInUSD;
        uint256 userSupplyBalance;
        bool isPossibleToBeCollateral;
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
        bool isPossibleToBeCollateral;
        bool isCollateralEnabled;
    }

    function getUserSupplyAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _userSupplyAssets);

    function getUserBorrowAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _userBorrowAssets);

    function getSupplyAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _availableAssets, bytes32[] memory _userSupplyAssets);

    function getBorrowAssets(address _userAddr)
        external
        view
        returns (bytes32[] memory _availableAssets, bytes32[] memory _userBorrowAssets);

    function getSupplyAssetsInfo(bytes32[] memory _assetsKeys, address _userAddr)
        external
        view
        returns (SupplyAssetInfo[] memory _resultArr);

    function getBorrowAssetsInfo(bytes32[] memory _assetsKeys, address _userAddr)
        external
        view
        returns (BorrowAssetInfo[] memory _resultArr);

    function getAssetsInfo(
        bytes32[] memory _assetsKeys,
        address _userAddr,
        bool _isSupply
    ) external view returns (AssetInfo[] memory _resultArr);

    function addSupplyAsset(bytes32 _assetKey, address _userAddr) external;

    function updateSupplyAssets(
        address _userAddr,
        bytes32 _assetKey,
        address _liquidityPoolAddr
    ) external;

    function updateBorrowAssets(
        address _userAddr,
        bytes32 _assetKey,
        address _liquidityPoolAddr
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IDefiCore {
    struct RewardsDistributionInfo {
        address assetAddr;
        uint256 distributionReward;
        uint256 distributionRewardInUSD;
        uint256 userBalance;
        uint256 userBalanceInUSD;
    }

    event LiquidateBorrow(bytes32 _paramKey, address _userAddr, uint256 _amount);
    event LiquidatorPay(bytes32 _paramKey, address _liquidatorAddr, uint256 _amount);

    function isCollateralAssetEnabled(address _userAddr, bytes32 _assetKey)
        external
        view
        returns (bool);

    function getAvailableLiquidity(address _userAddr) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ILiquidityPool {
    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 normalizedAmount;
    }

    function assetAddr() external view returns (address);

    function assetKey() external view returns (bytes32);

    function liquidityAmounts(address _userAddr) external view returns (uint256);

    function borrowInfos(address _userAddr)
        external
        view
        returns (uint256 _borrowAmount, uint256 _normalizedAmount);

    function aggregatedLiquidityAmount() external view returns (uint256);

    function aggregatedBorrowedAmount() external view returns (uint256);

    function getTotalSupplyAmount() external view returns (uint256);

    function getCurrentLiquidityAmount(address _userAddr) external view returns (uint256);

    function getUserBorrowedAmount(address _userAddr) external view returns (uint256);

    function getBorrowPercentage() external view returns (uint256);

    function getAnnualBorrowRate() external view returns (uint256 _annualBorrowRate);

    function getAPY() external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getAmountInUSD(uint256 _assetAmount) external view returns (uint256);

    function getAmountFromUSD(uint256 _usdAmount) external view returns (uint256);

    function getFreezeStatus() external view returns (bool);

    function getCurrentRate() external view returns (uint256);

    function updateCompoundRate() external returns (uint256);

    function addLiquidity(address _userAddr, uint256 _liquidityAmount) external;

    function withdrawLiquidity(address _userAddr, uint256 _liquidityAmount) external;

    function borrow(address _userAddr, uint256 _amountToBorrow) external;

    function repayBorrow(address _userAddr, uint256 _repayAmount) external returns (uint256);

    function liquidate(
        address _userAddr,
        address _liquidatorAddr,
        uint256 _liquidityAmount
    ) external;

    function liquidationBorrow(
        address _userAddr,
        address _liquidatorAddr,
        uint256 _amountToLiquidate
    ) external returns (uint256);

    function withdrawReservedFunds(
        address _recipientAddr,
        uint256 _amountToWithdraw,
        bool _isAllFunds
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IRewardsDistribution {
    function getAPY(address _userAddr, address _liquidityPoolAddr)
        external
        view
        returns (uint256 _supplyAPY, uint256 _borrowAPY);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ISystemParameters {
    event UintParamUpdated(bytes32 _paramKey, uint256 _newValue);

    /**
     * @notice Getter for parameter by key LIQUIDATION_BOUNDARY_KEY
     * @return current liquidation boundary parameter value
     */
    function getLiquidationBoundaryParam() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IAssetParameters.sol";
import "../interfaces/ISystemParameters.sol";
import "../interfaces/ILiquidityPool.sol";

import "../common/Globals.sol";

library AssetsHelperLibrary {
    function getLimitPart(
        bytes32 _assetKey,
        uint256 _amount,
        IAssetParameters _parameters
    ) internal view returns (uint256) {
        return (_amount * DECIMAL) / _parameters.getColRatio(_assetKey);
    }

    function getCurrentSupplyAmountInUSD(
        bytes32 _assetKey,
        address _userAddr,
        IAssetParameters _parameters
    ) internal view returns (uint256) {
        ILiquidityPool _currentLiquidityPool =
            ILiquidityPool(_parameters.liquidityPools(_assetKey));

        return
            _currentLiquidityPool.getAmountInUSD(
                _currentLiquidityPool.getCurrentLiquidityAmount(_userAddr)
            );
    }

    function getCurrentBorrowAmountInUSD(
        bytes32 _assetKey,
        address _userAddr,
        IAssetParameters _parameters
    ) internal view returns (uint256) {
        ILiquidityPool _currentLiquidityPool =
            ILiquidityPool(_parameters.liquidityPools(_assetKey));

        return
            _currentLiquidityPool.getAmountInUSD(
                _currentLiquidityPool.getUserBorrowedAmount(_userAddr)
            );
    }

    function getAssetLiquidityPool(bytes32 _assetKey, IAssetParameters _parameters)
        internal
        view
        returns (ILiquidityPool)
    {
        ILiquidityPool _assetLiquidityPool = ILiquidityPool(_parameters.liquidityPools(_assetKey));

        require(
            address(_assetLiquidityPool) != address(0),
            "AssetsHelperLibrary: LiquidityPool doesn't exists."
        );

        return _assetLiquidityPool;
    }

    function getRepayLiquidationAmount(
        bytes32 _liquidateAssetKey,
        uint256 _liquidationAmount,
        IAssetParameters _parameters
    ) internal view returns (uint256) {
        uint256 _discount = DECIMAL - _parameters.getLiquidationDiscount(_liquidateAssetKey);

        return (_liquidationAmount * DECIMAL) / _discount;
    }

    function getMaxQuantity(
        bytes32 _supplyAssetKey,
        address _userAddr,
        ILiquidityPool _supplyAssetsPool,
        ILiquidityPool _borrowAssetsPool,
        IAssetParameters _assetParameters,
        ISystemParameters _systemParameters
    ) internal view returns (uint256) {
        uint256 _liquidateLimitBySupply =
            (_supplyAssetsPool.getCurrentLiquidityAmount(_userAddr) *
                (DECIMAL - _assetParameters.getLiquidationDiscount(_supplyAssetKey))) / DECIMAL;

        uint256 _liquidateLimitByBorrow =
            (_borrowAssetsPool.getUserBorrowedAmount(_userAddr) *
                _systemParameters.getLiquidationBoundaryParam()) / DECIMAL;

        return
            Math.min(
                _borrowAssetsPool.getAmountFromUSD(
                    _supplyAssetsPool.getAmountInUSD(_liquidateLimitBySupply)
                ),
                _liquidateLimitByBorrow
            );
    }
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

