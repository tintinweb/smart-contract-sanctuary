/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { AaveV2 } from "../integration/lib/AaveV2.sol";
import { IAToken } from "../../interfaces/external/aave-v2/IAToken.sol";
import { IController } from "../../interfaces/IController.sol";
import { IDebtIssuanceModule } from "../../interfaces/IDebtIssuanceModule.sol";
import { IExchangeAdapter } from "../../interfaces/IExchangeAdapter.sol";
import { ILendingPool } from "../../interfaces/external/aave-v2/ILendingPool.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/external/aave-v2/ILendingPoolAddressesProvider.sol";
import { IModuleIssuanceHook } from "../../interfaces/IModuleIssuanceHook.sol";
import { IProtocolDataProvider } from "../../interfaces/external/aave-v2/IProtocolDataProvider.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { IVariableDebtToken } from "../../interfaces/external/aave-v2/IVariableDebtToken.sol";
import { ModuleBase } from "../lib/ModuleBase.sol";

/**
 * @title AaveLeverageModule
 * @author Set Protocol 
 * @notice Smart contract that enables leverage trading using Aave as the lending protocol. 
 * @dev Do not use this module in conjunction with other debt modules that allow Aave debt positions as it could lead to double counting of
 * debt when borrowed assets are the same.
 */
contract AaveLeverageModule is ModuleBase, ReentrancyGuard, Ownable, IModuleIssuanceHook {
    using AaveV2 for ISetToken;

    /* ============ Structs ============ */

    struct EnabledAssets {        
        address[] collateralAssets;             // Array of enabled underlying collateral assets for a SetToken
        address[] borrowAssets;                 // Array of enabled underlying borrow assets for a SetToken
    }

    struct ActionInfo {
        ISetToken setToken;                      // SetToken instance
        ILendingPool lendingPool;                // Lending pool instance, we grab this everytime since it's best practice not to store
        IExchangeAdapter exchangeAdapter;        // Exchange adapter instance
        uint256 setTotalSupply;                  // Total supply of SetToken
        uint256 notionalSendQuantity;            // Total notional quantity sent to exchange
        uint256 minNotionalReceiveQuantity;      // Min total notional received from exchange
        IERC20 collateralAsset;                  // Address of collateral asset
        IERC20 borrowAsset;                      // Address of borrow asset
        uint256 preTradeReceiveTokenBalance;     // Balance of pre-trade receive token balance
    }

    struct ReserveTokens {
        IAToken aToken;                         // Reserve's aToken instance
        IVariableDebtToken variableDebtToken;   // Reserve's variable debt token instance
    }
    
    /* ============ Events ============ */

    /**
     * @dev Emitted on lever()
     * @param _setToken             Instance of the SetToken being levered
     * @param _borrowAsset          Asset being borrowed for leverage
     * @param _collateralAsset      Collateral asset being levered
     * @param _exchangeAdapter      Exchange adapter used for trading
     * @param _totalBorrowAmount    Total amount of `_borrowAsset` borrowed
     * @param _totalReceiveAmount   Total amount of `_collateralAsset` received by selling `_borrowAsset`
     * @param _protocolFee          Protocol fee charged
     */
    event LeverageIncreased(
        ISetToken indexed _setToken,
        IERC20 indexed _borrowAsset,
        IERC20 indexed _collateralAsset,
        IExchangeAdapter _exchangeAdapter,
        uint256 _totalBorrowAmount,
        uint256 _totalReceiveAmount,
        uint256 _protocolFee
    );

    /**
     * @dev Emitted on delever() and deleverToZeroBorrowBalance()
     * @param _setToken             Instance of the SetToken being delevered
     * @param _collateralAsset      Asset sold to decrease leverage
     * @param _repayAsset           Asset being bought to repay to Aave
     * @param _exchangeAdapter      Exchange adapter used for trading
     * @param _totalRedeemAmount    Total amount of `_collateralAsset` being sold
     * @param _totalRepayAmount     Total amount of `_repayAsset` being repaid
     * @param _protocolFee          Protocol fee charged
     */
    event LeverageDecreased(
        ISetToken indexed _setToken,
        IERC20 indexed _collateralAsset,
        IERC20 indexed _repayAsset,
        IExchangeAdapter _exchangeAdapter,
        uint256 _totalRedeemAmount,
        uint256 _totalRepayAmount,
        uint256 _protocolFee
    );

    /**
     * @dev Emitted on addCollateralAssets() and removeCollateralAssets()
     * @param _setToken Instance of SetToken whose collateral assets is updated
     * @param _added    true if assets are added false if removed
     * @param _assets   Array of collateral assets being added/removed
     */
    event CollateralAssetsUpdated(
        ISetToken indexed _setToken,
        bool indexed _added,
        IERC20[] _assets
    );

    /**
     * @dev Emitted on addBorrowAssets() and removeBorrowAssets()
     * @param _setToken Instance of SetToken whose borrow assets is updated
     * @param _added    true if assets are added false if removed
     * @param _assets   Array of borrow assets being added/removed
     */
    event BorrowAssetsUpdated(
        ISetToken indexed _setToken,
        bool indexed _added,
        IERC20[] _assets
    );
    
    /**
     * @dev Emitted when `underlyingToReserveTokensMappings` is updated
     * @param _underlying           Address of the underlying asset
     * @param _aToken               Updated aave reserve aToken
     * @param _variableDebtToken    Updated aave reserve variable debt token 
     */
    event ReserveTokensUpdated(
        IERC20 indexed _underlying,
        IAToken indexed _aToken,
        IVariableDebtToken indexed _variableDebtToken
    );
    
    /**
     * @dev Emitted on updateAllowedSetToken()
     * @param _setToken SetToken being whose allowance to initialize this module is being updated
     * @param _added    true if added false if removed
     */
    event SetTokenStatusUpdated(
        ISetToken indexed _setToken,
        bool indexed _added
    );

    /**
     * @dev Emitted on updateAnySetAllowed()
     * @param _anySetAllowed    true if any set is allowed to initialize this module, false otherwise
     */
    event AnySetAllowedUpdated(
        bool indexed _anySetAllowed    
    );

    /* ============ Constants ============ */

    // This module only supports borrowing in variable rate mode from Aave which is represented by 2
    uint256 constant internal BORROW_RATE_MODE = 2;
    
    // String identifying the DebtIssuanceModule in the IntegrationRegistry. Note: Governance must add DefaultIssuanceModule as
    // the string as the integration name
    string constant internal DEFAULT_ISSUANCE_MODULE_NAME = "DefaultIssuanceModule";

    // 0 index stores protocol fee % on the controller, charged in the _executeTrade function
    uint256 constant internal PROTOCOL_TRADE_FEE_INDEX = 0;

    /* ============ State Variables ============ */

    // Mapping to efficiently fetch reserve token addresses. Tracking Aave reserve token addresses and updating them 
    // upon requirement is more efficient than fetching them each time from Aave.
    // Note: For an underlying asset to be enabled as collateral/borrow asset on SetToken, it must be added to this mapping first.
    mapping(IERC20 => ReserveTokens) public underlyingToReserveTokens;

    // Used to fetch reserves and user data from AaveV2
    IProtocolDataProvider public immutable protocolDataProvider;
    
    // Used to fetch lendingPool address. This contract is immutable and its address will never change.
    ILendingPoolAddressesProvider public immutable lendingPoolAddressesProvider;
    
    // Mapping to efficiently check if collateral asset is enabled in SetToken
    mapping(ISetToken => mapping(IERC20 => bool)) public collateralAssetEnabled;
    
    // Mapping to efficiently check if a borrow asset is enabled in SetToken
    mapping(ISetToken => mapping(IERC20 => bool)) public borrowAssetEnabled;
    
    // Internal mapping of enabled collateral and borrow tokens for syncing positions
    mapping(ISetToken => EnabledAssets) internal enabledAssets;

    // Mapping of SetToken to boolean indicating if SetToken is on allow list. Updateable by governance
    mapping(ISetToken => bool) public allowedSetTokens;

    // Boolean that returns if any SetToken can initialize this module. If false, then subject to allow list. Updateable by governance.
    bool public anySetAllowed;
    
    /* ============ Constructor ============ */

    /**
     * @dev Instantiate addresses. Underlying to reserve tokens mapping is created.
     * @param _controller                       Address of controller contract
     * @param _lendingPoolAddressesProvider     Address of Aave LendingPoolAddressProvider
     */
    constructor(
        IController _controller,
        ILendingPoolAddressesProvider _lendingPoolAddressesProvider
    )
        public
        ModuleBase(_controller)
    {
        lendingPoolAddressesProvider = _lendingPoolAddressesProvider;
        IProtocolDataProvider _protocolDataProvider = IProtocolDataProvider(
            // Use the raw input vs bytes32() conversion. This is to ensure the input is an uint and not a string.
            _lendingPoolAddressesProvider.getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)
        );
        protocolDataProvider = _protocolDataProvider;
        
        IProtocolDataProvider.TokenData[] memory reserveTokens = _protocolDataProvider.getAllReservesTokens();
        for(uint256 i = 0; i < reserveTokens.length; i++) {
            (address aToken, , address variableDebtToken) = _protocolDataProvider.getReserveTokensAddresses(reserveTokens[i].tokenAddress);
            underlyingToReserveTokens[IERC20(reserveTokens[i].tokenAddress)] = ReserveTokens(IAToken(aToken), IVariableDebtToken(variableDebtToken));
        }
    }
    
    /* ============ External Functions ============ */
    
    /**
     * @dev MANAGER ONLY: Increases leverage for a given collateral position using an enabled borrow asset.
     * Borrows _borrowAsset from Aave. Performs a DEX trade, exchanging the _borrowAsset for _collateralAsset.
     * Deposits _collateralAsset to Aave and mints corresponding aToken.
     * Note: Both collateral and borrow assets need to be enabled, and they must not be the same asset.
     * @param _setToken                     Instance of the SetToken
     * @param _borrowAsset                  Address of underlying asset being borrowed for leverage
     * @param _collateralAsset              Address of underlying collateral asset
     * @param _borrowQuantityUnits          Borrow quantity of asset in position units
     * @param _minReceiveQuantityUnits      Min receive quantity of collateral asset to receive post-trade in position units
     * @param _tradeAdapterName             Name of trade adapter
     * @param _tradeData                    Arbitrary data for trade
     */
    function lever(
        ISetToken _setToken,
        IERC20 _borrowAsset,
        IERC20 _collateralAsset,
        uint256 _borrowQuantityUnits,
        uint256 _minReceiveQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    )
        external
        nonReentrant
        onlyManagerAndValidSet(_setToken)
    {
        // For levering up, send quantity is derived from borrow asset and receive quantity is derived from 
        // collateral asset
        ActionInfo memory leverInfo = _createAndValidateActionInfo(
            _setToken,
            _borrowAsset,
            _collateralAsset,
            _borrowQuantityUnits,
            _minReceiveQuantityUnits,
            _tradeAdapterName,
            true
        );

        _borrow(leverInfo.setToken, leverInfo.lendingPool, leverInfo.borrowAsset, leverInfo.notionalSendQuantity);

        uint256 postTradeReceiveQuantity = _executeTrade(leverInfo, _borrowAsset, _collateralAsset, _tradeData);

        uint256 protocolFee = _accrueProtocolFee(_setToken, _collateralAsset, postTradeReceiveQuantity);

        uint256 postTradeCollateralQuantity = postTradeReceiveQuantity.sub(protocolFee);

        _deposit(leverInfo.setToken, leverInfo.lendingPool, _collateralAsset, postTradeCollateralQuantity);

        _updateLeverPositions(leverInfo, _borrowAsset);

        emit LeverageIncreased(
            _setToken,
            _borrowAsset,
            _collateralAsset,
            leverInfo.exchangeAdapter,
            leverInfo.notionalSendQuantity,
            postTradeCollateralQuantity,
            protocolFee
        );
    }
    
    /**
     * @dev MANAGER ONLY: Decrease leverage for a given collateral position using an enabled borrow asset.
     * Withdraws _collateralAsset from Aave. Performs a DEX trade, exchanging the _collateralAsset for _repayAsset.
     * Repays _repayAsset to Aave and burns corresponding debt tokens.
     * Note: Both collateral and borrow assets need to be enabled, and they must not be the same asset.
     * @param _setToken                 Instance of the SetToken
     * @param _collateralAsset          Address of underlying collateral asset being withdrawn
     * @param _repayAsset               Address of underlying borrowed asset being repaid
     * @param _redeemQuantityUnits      Quantity of collateral asset to delever in position units
     * @param _minRepayQuantityUnits    Minimum amount of repay asset to receive post trade in position units
     * @param _tradeAdapterName         Name of trade adapter
     * @param _tradeData                Arbitrary data for trade
     */
    function delever(
        ISetToken _setToken,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        uint256 _minRepayQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    )
        external
        nonReentrant
        onlyManagerAndValidSet(_setToken)
    {
        // Note: for delevering, send quantity is derived from collateral asset and receive quantity is derived from 
        // repay asset
        ActionInfo memory deleverInfo = _createAndValidateActionInfo(
            _setToken,
            _collateralAsset,
            _repayAsset,
            _redeemQuantityUnits,
            _minRepayQuantityUnits,
            _tradeAdapterName,
            false
        );

        _withdraw(deleverInfo.setToken, deleverInfo.lendingPool, _collateralAsset, deleverInfo.notionalSendQuantity);

        uint256 postTradeReceiveQuantity = _executeTrade(deleverInfo, _collateralAsset, _repayAsset, _tradeData);

        uint256 protocolFee = _accrueProtocolFee(_setToken, _repayAsset, postTradeReceiveQuantity);

        uint256 repayQuantity = postTradeReceiveQuantity.sub(protocolFee);

        _repayBorrow(deleverInfo.setToken, deleverInfo.lendingPool, _repayAsset, repayQuantity);

        _updateDeleverPositions(deleverInfo, _repayAsset);

        emit LeverageDecreased(
            _setToken,
            _collateralAsset,
            _repayAsset,
            deleverInfo.exchangeAdapter,
            deleverInfo.notionalSendQuantity,
            repayQuantity,
            protocolFee
        );
    }

    /** @dev MANAGER ONLY: Pays down the borrow asset to 0 selling off a given amount of collateral asset. 
     * Withdraws _collateralAsset from Aave. Performs a DEX trade, exchanging the _collateralAsset for _repayAsset. 
     * Minimum receive amount for the DEX trade is set to the current variable debt balance of the borrow asset. 
     * Repays received _repayAsset to Aave which burns corresponding debt tokens. Any extra received borrow asset is .
     * updated as equity. No protocol fee is charged.
     * Note: Both collateral and borrow assets need to be enabled, and they must not be the same asset.
     * The function reverts if not enough collateral asset is redeemed to buy the required minimum amount of _repayAsset.
     * @param _setToken             Instance of the SetToken
     * @param _collateralAsset      Address of underlying collateral asset being redeemed
     * @param _repayAsset           Address of underlying asset being repaid
     * @param _redeemQuantityUnits  Quantity of collateral asset to delever in position units
     * @param _tradeAdapterName     Name of trade adapter
     * @param _tradeData            Arbitrary data for trade     
     * @return uint256              Notional repay quantity
     */
    function deleverToZeroBorrowBalance(
        ISetToken _setToken,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    )
        external
        nonReentrant
        onlyManagerAndValidSet(_setToken)
        returns (uint256)
    {
        uint256 setTotalSupply = _setToken.totalSupply();
        uint256 notionalRedeemQuantity = _redeemQuantityUnits.preciseMul(setTotalSupply);
        
        require(borrowAssetEnabled[_setToken][_repayAsset], "Borrow not enabled");
        uint256 notionalRepayQuantity = underlyingToReserveTokens[_repayAsset].variableDebtToken.balanceOf(address(_setToken));
        require(notionalRepayQuantity > 0, "Borrow balance is zero");

        ActionInfo memory deleverInfo = _createAndValidateActionInfoNotional(
            _setToken,
            _collateralAsset,
            _repayAsset,
            notionalRedeemQuantity,
            notionalRepayQuantity,
            _tradeAdapterName,
            false,
            setTotalSupply
        );

        _withdraw(deleverInfo.setToken, deleverInfo.lendingPool, _collateralAsset, deleverInfo.notionalSendQuantity);

        _executeTrade(deleverInfo, _collateralAsset, _repayAsset, _tradeData);

        _repayBorrow(deleverInfo.setToken, deleverInfo.lendingPool, _repayAsset, notionalRepayQuantity);

        _updateDeleverPositions(deleverInfo, _repayAsset);

        emit LeverageDecreased(
            _setToken,
            _collateralAsset,
            _repayAsset,
            deleverInfo.exchangeAdapter,
            deleverInfo.notionalSendQuantity,
            notionalRepayQuantity,
            0   // No protocol fee
        );

        return notionalRepayQuantity;
    }

    /**
     * @dev CALLABLE BY ANYBODY: Sync Set positions with ALL enabled Aave collateral and borrow positions. 
     * For collateral assets, update aToken default position. For borrow assets, update external borrow position.
     * - Collateral assets may come out of sync when interest is accrued or a position is liquidated
     * - Borrow assets may come out of sync when interest is accrued or position is liquidated and borrow is repaid
     * Note: In Aave, both collateral and borrow interest is accrued in each block by increasing the balance of
     * aTokens and debtTokens for each user, and 1 aToken = 1 variableDebtToken = 1 underlying.
     * @param _setToken               Instance of the SetToken
     */
    function sync(ISetToken _setToken) public nonReentrant onlyValidAndInitializedSet(_setToken) {
        uint256 setTotalSupply = _setToken.totalSupply();

        // Only sync positions when Set supply is not 0. Without this check, if sync is called by someone before the 
        // first issuance, then editDefaultPosition would remove the default positions from the SetToken
        if (setTotalSupply > 0) {
            address[] memory collateralAssets = enabledAssets[_setToken].collateralAssets;
            for(uint256 i = 0; i < collateralAssets.length; i++) {
                IAToken aToken = underlyingToReserveTokens[IERC20(collateralAssets[i])].aToken;
                
                uint256 previousPositionUnit = _setToken.getDefaultPositionRealUnit(address(aToken)).toUint256();
                uint256 newPositionUnit = _getCollateralPosition(_setToken, aToken, setTotalSupply);

                // Note: Accounts for if position does not exist on SetToken but is tracked in enabledAssets
                if (previousPositionUnit != newPositionUnit) {
                  _updateCollateralPosition(_setToken, aToken, newPositionUnit);
                }
            }
        
            address[] memory borrowAssets = enabledAssets[_setToken].borrowAssets;
            for(uint256 i = 0; i < borrowAssets.length; i++) {
                IERC20 borrowAsset = IERC20(borrowAssets[i]);

                int256 previousPositionUnit = _setToken.getExternalPositionRealUnit(address(borrowAsset), address(this));
                int256 newPositionUnit = _getBorrowPosition(_setToken, borrowAsset, setTotalSupply);

                // Note: Accounts for if position does not exist on SetToken but is tracked in enabledAssets
                if (newPositionUnit != previousPositionUnit) {
                    _updateBorrowPosition(_setToken, borrowAsset, newPositionUnit);
                }
            }
        }
    }

    /**
     * @dev MANAGER ONLY: Initializes this module to the SetToken. Either the SetToken needs to be on the allowed list
     * or anySetAllowed needs to be true. Only callable by the SetToken's manager.
     * Note: Managers can enable collateral and borrow assets that don't exist as positions on the SetToken
     * @param _setToken             Instance of the SetToken to initialize
     * @param _collateralAssets     Underlying tokens to be enabled as collateral in the SetToken
     * @param _borrowAssets         Underlying tokens to be enabled as borrow in the SetToken
     */
    function initialize(
        ISetToken _setToken,
        IERC20[] memory _collateralAssets,
        IERC20[] memory _borrowAssets
    )
        external
        onlySetManager(_setToken, msg.sender)
        onlyValidAndPendingSet(_setToken)
    {
        if (!anySetAllowed) {
            require(allowedSetTokens[_setToken], "Not allowed SetToken");
        }

        // Initialize module before trying register
        _setToken.initializeModule();

        // Get debt issuance module registered to this module and require that it is initialized
        require(_setToken.isInitializedModule(getAndValidateAdapter(DEFAULT_ISSUANCE_MODULE_NAME)), "Issuance not initialized");

        // Try if register exists on any of the modules including the debt issuance module
        address[] memory modules = _setToken.getModules();
        for(uint256 i = 0; i < modules.length; i++) {
            try IDebtIssuanceModule(modules[i]).registerToIssuanceModule(_setToken) {} catch {}
        }
        
        // _collateralAssets and _borrowAssets arrays are validated in their respective internal functions
        _addCollateralAssets(_setToken, _collateralAssets);
        _addBorrowAssets(_setToken, _borrowAssets);
    }

    /**
     * @dev MANAGER ONLY: Removes this module from the SetToken, via call by the SetToken. Any deposited collateral assets
     * are disabled to be used as collateral on Aave. Aave Settings and manager enabled assets state is deleted.      
     * Note: Function will revert is there is any debt remaining on Aave
     */
    function removeModule() external override onlyValidAndInitializedSet(ISetToken(msg.sender)) {
        ISetToken setToken = ISetToken(msg.sender);

        // Sync Aave and SetToken positions prior to any removal action
        sync(setToken);

        address[] memory borrowAssets = enabledAssets[setToken].borrowAssets;
        for(uint256 i = 0; i < borrowAssets.length; i++) {
            IERC20 borrowAsset = IERC20(borrowAssets[i]);
            require(underlyingToReserveTokens[borrowAsset].variableDebtToken.balanceOf(address(setToken)) == 0, "Variable debt remaining");
    
            delete borrowAssetEnabled[setToken][borrowAsset];
        }

        address[] memory collateralAssets = enabledAssets[setToken].collateralAssets;
        for(uint256 i = 0; i < collateralAssets.length; i++) {
            IERC20 collateralAsset = IERC20(collateralAssets[i]);
            _updateUseReserveAsCollateral(setToken, collateralAsset, false);

            delete collateralAssetEnabled[setToken][collateralAsset];
        }
        
        delete enabledAssets[setToken];

        // Try if unregister exists on any of the modules
        address[] memory modules = setToken.getModules();
        for(uint256 i = 0; i < modules.length; i++) {
            try IDebtIssuanceModule(modules[i]).unregisterFromIssuanceModule(setToken) {} catch {}
        }
    }

    /**
     * @dev MANAGER ONLY: Add registration of this module on the debt issuance module for the SetToken. 
     * Note: if the debt issuance module is not added to SetToken before this module is initialized, then this function
     * needs to be called if the debt issuance module is later added and initialized to prevent state inconsistencies
     * @param _setToken             Instance of the SetToken
     * @param _debtIssuanceModule   Debt issuance module address to register
     */
    function registerToModule(ISetToken _setToken, IDebtIssuanceModule _debtIssuanceModule) external onlyManagerAndValidSet(_setToken) {
        require(_setToken.isInitializedModule(address(_debtIssuanceModule)), "Issuance not initialized");

        _debtIssuanceModule.registerToIssuanceModule(_setToken);
    }

    /**
     * @dev CALLABLE BY ANYBODY: Updates `underlyingToReserveTokens` mappings. Reverts if mapping already exists
     * or the passed _underlying asset does not have a valid reserve on Aave.
     * Note: Call this function when Aave adds a new reserve.
     * @param _underlying               Address of underlying asset
     */
    function addUnderlyingToReserveTokensMapping(IERC20 _underlying) external {
        require(address(underlyingToReserveTokens[_underlying].aToken) == address(0), "Mapping already exists");

        // An active reserve is an alias for a valid reserve on Aave.
        (,,,,,,,, bool isActive,) = protocolDataProvider.getReserveConfigurationData(address(_underlying));
        require(isActive, "Invalid aave reserve");
        
        _addUnderlyingToReserveTokensMapping(_underlying);
    }

    /**
     * @dev MANAGER ONLY: Add collateral assets. aTokens corresponding to collateral assets are tracked for syncing positions.
     * Note: Reverts with "Collateral already enabled" if there are duplicate assets in the passed _newCollateralAssets array.
     * 
     * NOTE: ALL ADDED COLLATERAL ASSETS CAN BE ADDED AS A POSITION ON THE SET TOKEN WITHOUT MANAGER'S EXPLICIT PERMISSION.
     * UNWANTED EXTRA POSITIONS CAN BREAK EXTERNAL LOGIC, INCREASE COST OF MINT/REDEEM OF SET TOKEN, AMONG OTHER POTENTIAL UNINTENDED CONSEQUENCES.
     * SO, PLEASE ADD ONLY THOSE COLLATERAL ASSETS WHOSE CORRESPONDING aTOKENS ARE NEEDED AS DEFAULT POSITIONS ON THE SET TOKEN.
     *
     * @param _setToken             Instance of the SetToken
     * @param _newCollateralAssets  Addresses of new collateral underlying assets
     */
    function addCollateralAssets(ISetToken _setToken, IERC20[] memory _newCollateralAssets) external onlyManagerAndValidSet(_setToken) {
        _addCollateralAssets(_setToken, _newCollateralAssets);
    }
   
    /**
     * @dev MANAGER ONLY: Remove collateral assets. Disable deposited assets to be used as collateral on Aave market.
     * @param _setToken             Instance of the SetToken
     * @param _collateralAssets     Addresses of collateral underlying assets to remove
     */
    function removeCollateralAssets(ISetToken _setToken, IERC20[] memory _collateralAssets) external onlyManagerAndValidSet(_setToken) {
        
        for(uint256 i = 0; i < _collateralAssets.length; i++) {
            IERC20 collateralAsset = _collateralAssets[i];
            require(collateralAssetEnabled[_setToken][collateralAsset], "Collateral not enabled");
            
            _updateUseReserveAsCollateral(_setToken, collateralAsset, false);
            
            delete collateralAssetEnabled[_setToken][collateralAsset];
            enabledAssets[_setToken].collateralAssets.removeStorage(address(collateralAsset));
        }
        emit CollateralAssetsUpdated(_setToken, false, _collateralAssets);
    }

    /**
     * @dev MANAGER ONLY: Add borrow assets. Debt tokens corresponding to borrow assets are tracked for syncing positions.
     * Note: Reverts with "Borrow already enabled" if there are duplicate assets in the passed _newBorrowAssets array.
     * @param _setToken             Instance of the SetToken
     * @param _newBorrowAssets      Addresses of borrow underlying assets to add
     */
    function addBorrowAssets(ISetToken _setToken, IERC20[] memory _newBorrowAssets) external onlyManagerAndValidSet(_setToken) {
        _addBorrowAssets(_setToken, _newBorrowAssets);
    }

    /**
     * @dev MANAGER ONLY: Remove borrow assets.
     * Note: If there is a borrow balance, borrow asset cannot be removed
     * @param _setToken             Instance of the SetToken
     * @param _borrowAssets         Addresses of borrow underlying assets to remove
     */
    function removeBorrowAssets(ISetToken _setToken, IERC20[] memory _borrowAssets) external onlyManagerAndValidSet(_setToken) {
        
        for(uint256 i = 0; i < _borrowAssets.length; i++) {
            IERC20 borrowAsset = _borrowAssets[i];
            
            require(borrowAssetEnabled[_setToken][borrowAsset], "Borrow not enabled");
            require(underlyingToReserveTokens[borrowAsset].variableDebtToken.balanceOf(address(_setToken)) == 0, "Variable debt remaining");
    
            delete borrowAssetEnabled[_setToken][borrowAsset];
            enabledAssets[_setToken].borrowAssets.removeStorage(address(borrowAsset));
        }
        emit BorrowAssetsUpdated(_setToken, false, _borrowAssets);
    }

    /**
     * @dev GOVERNANCE ONLY: Enable/disable ability of a SetToken to initialize this module. Only callable by governance.
     * @param _setToken             Instance of the SetToken
     * @param _status               Bool indicating if _setToken is allowed to initialize this module
     */
    function updateAllowedSetToken(ISetToken _setToken, bool _status) external onlyOwner {
        require(controller.isSet(address(_setToken)) || allowedSetTokens[_setToken], "Invalid SetToken");
        allowedSetTokens[_setToken] = _status;
        emit SetTokenStatusUpdated(_setToken, _status);
    }

    /**
     * @dev GOVERNANCE ONLY: Toggle whether ANY SetToken is allowed to initialize this module. Only callable by governance.
     * @param _anySetAllowed             Bool indicating if ANY SetToken is allowed to initialize this module
     */
    function updateAnySetAllowed(bool _anySetAllowed) external onlyOwner {
        anySetAllowed = _anySetAllowed;
        emit AnySetAllowedUpdated(_anySetAllowed);
    }

    /**
     * @dev MODULE ONLY: Hook called prior to issuance to sync positions on SetToken. Only callable by valid module.
     * @param _setToken             Instance of the SetToken
     */
    function moduleIssueHook(ISetToken _setToken, uint256 /* _setTokenQuantity */) external override onlyModule(_setToken) {
        sync(_setToken);
    }

    /**
     * @dev MODULE ONLY: Hook called prior to redemption to sync positions on SetToken. For redemption, always use current borrowed
     * balance after interest accrual. Only callable by valid module.
     * @param _setToken             Instance of the SetToken
     */
    function moduleRedeemHook(ISetToken _setToken, uint256 /* _setTokenQuantity */) external override onlyModule(_setToken) {
        sync(_setToken);
    }

    /**
     * @dev MODULE ONLY: Hook called prior to looping through each component on issuance. Invokes borrow in order for 
     * module to return debt to issuer. Only callable by valid module.
     * @param _setToken             Instance of the SetToken
     * @param _setTokenQuantity     Quantity of SetToken
     * @param _component            Address of component
     */
    function componentIssueHook(ISetToken _setToken, uint256 _setTokenQuantity, IERC20 _component, bool _isEquity) external override onlyModule(_setToken) {
        // Check hook not being called for an equity position. If hook is called with equity position and outstanding borrow position
        // exists the loan would be taken out twice potentially leading to liquidation
        if (!_isEquity) {
            int256 componentDebt = _setToken.getExternalPositionRealUnit(address(_component), address(this));

            require(componentDebt < 0, "Component must be negative");

            uint256 notionalDebt = componentDebt.mul(-1).toUint256().preciseMul(_setTokenQuantity);
            _borrowForHook(_setToken, _component, notionalDebt);
        }
    }

    /**
     * @dev MODULE ONLY: Hook called prior to looping through each component on redemption. Invokes repay after 
     * the issuance module transfers debt from the issuer. Only callable by valid module.
     * @param _setToken             Instance of the SetToken
     * @param _setTokenQuantity     Quantity of SetToken
     * @param _component            Address of component
     */
    function componentRedeemHook(ISetToken _setToken, uint256 _setTokenQuantity, IERC20 _component, bool _isEquity) external override onlyModule(_setToken) {
        // Check hook not being called for an equity position. If hook is called with equity position and outstanding borrow position
        // exists the loan would be paid down twice, decollateralizing the Set
        if (!_isEquity) {
            int256 componentDebt = _setToken.getExternalPositionRealUnit(address(_component), address(this));

            require(componentDebt < 0, "Component must be negative");

            uint256 notionalDebt = componentDebt.mul(-1).toUint256().preciseMulCeil(_setTokenQuantity);
            _repayBorrowForHook(_setToken, _component, notionalDebt);
        }
    }
    
    /* ============ External Getter Functions ============ */

    /**
     * @dev Get enabled assets for SetToken. Returns an array of collateral and borrow assets.
     * @return Underlying collateral assets that are enabled
     * @return Underlying borrowed assets that are enabled
     */
    function getEnabledAssets(ISetToken _setToken) external view returns(address[] memory, address[] memory) {
        return (
            enabledAssets[_setToken].collateralAssets,
            enabledAssets[_setToken].borrowAssets
        );
    }

    /* ============ Internal Functions ============ */
    
    /**
     * @dev Invoke deposit from SetToken using AaveV2 library. Mints aTokens for SetToken.
     */
    function _deposit(ISetToken _setToken, ILendingPool _lendingPool, IERC20 _asset, uint256 _notionalQuantity) internal {
        _setToken.invokeApprove(address(_asset), address(_lendingPool), _notionalQuantity);
        _setToken.invokeDeposit(_lendingPool, address(_asset), _notionalQuantity);
    }

    /**
     * @dev Invoke withdraw from SetToken using AaveV2 library. Burns aTokens and returns underlying to SetToken.
     */
    function _withdraw(ISetToken _setToken, ILendingPool _lendingPool, IERC20 _asset, uint256 _notionalQuantity) internal {
        _setToken.invokeWithdraw(_lendingPool, address(_asset), _notionalQuantity);
    }

    /**
     * @dev Invoke repay from SetToken using AaveV2 library. Burns DebtTokens for SetToken.
     */
    function _repayBorrow(ISetToken _setToken, ILendingPool _lendingPool, IERC20 _asset, uint256 _notionalQuantity) internal {
        _setToken.invokeApprove(address(_asset), address(_lendingPool), _notionalQuantity);
        _setToken.invokeRepay(_lendingPool, address(_asset), _notionalQuantity, BORROW_RATE_MODE);
    }

    /**
     * @dev Invoke borrow from the SetToken during issuance hook. Since we only need to interact with AAVE once we fetch the
     * lending pool in this function to optimize vs forcing a fetch twice during lever/delever.
     */
    function _repayBorrowForHook(ISetToken _setToken, IERC20 _asset, uint256 _notionalQuantity) internal {
        _repayBorrow(_setToken, ILendingPool(lendingPoolAddressesProvider.getLendingPool()), _asset, _notionalQuantity);
    }

    /**
     * @dev Invoke borrow from the SetToken using AaveV2 library. Mints DebtTokens for SetToken.
     */
    function _borrow(ISetToken _setToken, ILendingPool _lendingPool, IERC20 _asset, uint256 _notionalQuantity) internal {
        _setToken.invokeBorrow(_lendingPool, address(_asset), _notionalQuantity, BORROW_RATE_MODE);
    }

    /**
     * @dev Invoke borrow from the SetToken during issuance hook. Since we only need to interact with AAVE once we fetch the
     * lending pool in this function to optimize vs forcing a fetch twice during lever/delever.
     */
    function _borrowForHook(ISetToken _setToken, IERC20 _asset, uint256 _notionalQuantity) internal {
        _borrow(_setToken, ILendingPool(lendingPoolAddressesProvider.getLendingPool()), _asset, _notionalQuantity);
    }
    
    /**
     * @dev Invokes approvals, gets trade call data from exchange adapter and invokes trade from SetToken
     * @return uint256     The quantity of tokens received post-trade
     */
    function _executeTrade(
        ActionInfo memory _actionInfo,
        IERC20 _sendToken,
        IERC20 _receiveToken,
        bytes memory _data
    )
        internal
        returns (uint256)
    {
        ISetToken setToken = _actionInfo.setToken;
        uint256 notionalSendQuantity = _actionInfo.notionalSendQuantity;

        setToken.invokeApprove(
            address(_sendToken),
            _actionInfo.exchangeAdapter.getSpender(),
            notionalSendQuantity
        );

        (
            address targetExchange,
            uint256 callValue,
            bytes memory methodData
        ) = _actionInfo.exchangeAdapter.getTradeCalldata(
            address(_sendToken),
            address(_receiveToken),
            address(setToken),
            notionalSendQuantity,
            _actionInfo.minNotionalReceiveQuantity,
            _data
        );

        setToken.invoke(targetExchange, callValue, methodData);

        uint256 receiveTokenQuantity = _receiveToken.balanceOf(address(setToken)).sub(_actionInfo.preTradeReceiveTokenBalance);
        require(
            receiveTokenQuantity >= _actionInfo.minNotionalReceiveQuantity,
            "Slippage too high"
        );

        return receiveTokenQuantity;
    }

    /**
     * @dev Calculates protocol fee on module and pays protocol fee from SetToken     
     * @return uint256          Total protocol fee paid
     */
    function _accrueProtocolFee(ISetToken _setToken, IERC20 _receiveToken, uint256 _exchangedQuantity) internal returns(uint256) {
        uint256 protocolFeeTotal = getModuleFee(PROTOCOL_TRADE_FEE_INDEX, _exchangedQuantity);
        
        payProtocolFeeFromSetToken(_setToken, address(_receiveToken), protocolFeeTotal);

        return protocolFeeTotal;
    }

    /**
     * @dev Updates the collateral (aToken held) and borrow position (variableDebtToken held) of the SetToken
     */
    function _updateLeverPositions(ActionInfo memory _actionInfo, IERC20 _borrowAsset) internal {
        IAToken aToken = underlyingToReserveTokens[_actionInfo.collateralAsset].aToken;
        _updateCollateralPosition(
            _actionInfo.setToken,
            aToken,
            _getCollateralPosition(
                _actionInfo.setToken,
                aToken,
                _actionInfo.setTotalSupply
            )
        );

        _updateBorrowPosition(
            _actionInfo.setToken,
            _borrowAsset,
            _getBorrowPosition(
                _actionInfo.setToken,
                _borrowAsset,
                _actionInfo.setTotalSupply
            )
        );
    }

    /**
     * @dev Updates positions as per _updateLeverPositions and updates Default position for borrow asset in case Set is
     * delevered all the way to zero any remaining borrow asset after the debt is paid can be added as a position.
     */
    function _updateDeleverPositions(ActionInfo memory _actionInfo, IERC20 _repayAsset) internal {
        // if amount of tokens traded for exceeds debt, update default position first to save gas on editing borrow position
        uint256 repayAssetBalance = _repayAsset.balanceOf(address(_actionInfo.setToken));
        if (repayAssetBalance != _actionInfo.preTradeReceiveTokenBalance) {
            _actionInfo.setToken.calculateAndEditDefaultPosition(
                address(_repayAsset),
                _actionInfo.setTotalSupply,
                _actionInfo.preTradeReceiveTokenBalance
            );
        }

        _updateLeverPositions(_actionInfo, _repayAsset);
    }
     
    /**
     * @dev Updates default position unit for given aToken on SetToken
     */
    function _updateCollateralPosition(ISetToken _setToken, IAToken _aToken, uint256 _newPositionUnit) internal {
        _setToken.editDefaultPosition(address(_aToken), _newPositionUnit);
    } 

    /**
     * @dev Updates external position unit for given borrow asset on SetToken
     */
    function _updateBorrowPosition(ISetToken _setToken, IERC20 _underlyingAsset, int256 _newPositionUnit) internal {
        _setToken.editExternalPosition(address(_underlyingAsset), address(this), _newPositionUnit, "");
    }

    /**
     * @dev Construct the ActionInfo struct for lever and delever
     * @return ActionInfo       Instance of constructed ActionInfo struct
     */
    function _createAndValidateActionInfo(
        ISetToken _setToken,
        IERC20 _sendToken,
        IERC20 _receiveToken,
        uint256 _sendQuantityUnits,
        uint256 _minReceiveQuantityUnits,
        string memory _tradeAdapterName,
        bool _isLever
    )
        internal
        view
        returns(ActionInfo memory)
    {
        uint256 totalSupply = _setToken.totalSupply();

        return _createAndValidateActionInfoNotional(
            _setToken,
            _sendToken,
            _receiveToken,
            _sendQuantityUnits.preciseMul(totalSupply),
            _minReceiveQuantityUnits.preciseMul(totalSupply),
            _tradeAdapterName,
            _isLever,
            totalSupply
        );
    }
    
    /**
     * @dev Construct the ActionInfo struct for lever and delever accepting notional units     
     * @return ActionInfo       Instance of constructed ActionInfo struct
     */
    function _createAndValidateActionInfoNotional(
        ISetToken _setToken,
        IERC20 _sendToken,
        IERC20 _receiveToken,
        uint256 _notionalSendQuantity,
        uint256 _minNotionalReceiveQuantity,
        string memory _tradeAdapterName,
        bool _isLever,
        uint256 _setTotalSupply
    )
        internal
        view
        returns(ActionInfo memory)
    {
        ActionInfo memory actionInfo = ActionInfo ({
            exchangeAdapter: IExchangeAdapter(getAndValidateAdapter(_tradeAdapterName)),
            lendingPool: ILendingPool(lendingPoolAddressesProvider.getLendingPool()),
            setToken: _setToken,
            collateralAsset: _isLever ? _receiveToken : _sendToken,
            borrowAsset: _isLever ? _sendToken : _receiveToken,
            setTotalSupply: _setTotalSupply,
            notionalSendQuantity: _notionalSendQuantity,
            minNotionalReceiveQuantity: _minNotionalReceiveQuantity,
            preTradeReceiveTokenBalance: IERC20(_receiveToken).balanceOf(address(_setToken))
        });

        _validateCommon(actionInfo);

        return actionInfo;
    }

    /**
     * @dev Updates `underlyingToReserveTokens` mappings for given `_underlying` asset. Emits ReserveTokensUpdated event.
     */
    function _addUnderlyingToReserveTokensMapping(IERC20 _underlying) internal {
        (address aToken, , address variableDebtToken) = protocolDataProvider.getReserveTokensAddresses(address(_underlying));
        underlyingToReserveTokens[_underlying].aToken = IAToken(aToken);
        underlyingToReserveTokens[_underlying].variableDebtToken = IVariableDebtToken(variableDebtToken);

        emit ReserveTokensUpdated(_underlying, IAToken(aToken), IVariableDebtToken(variableDebtToken));
    }

    /**
     * @dev Add collateral assets to SetToken. Updates the collateralAssetsEnabled and enabledAssets mappings.
     * Emits CollateralAssetsUpdated event.
     */
    function _addCollateralAssets(ISetToken _setToken, IERC20[] memory _newCollateralAssets) internal {
        for(uint256 i = 0; i < _newCollateralAssets.length; i++) {
            IERC20 collateralAsset = _newCollateralAssets[i];
            
            _validateNewCollateralAsset(_setToken, collateralAsset);
            _updateUseReserveAsCollateral(_setToken, collateralAsset, true);
            
            collateralAssetEnabled[_setToken][collateralAsset] = true;
            enabledAssets[_setToken].collateralAssets.push(address(collateralAsset));
        }
        emit CollateralAssetsUpdated(_setToken, true, _newCollateralAssets);
    }

    /**
     * @dev Add borrow assets to SetToken. Updates the borrowAssetsEnabled and enabledAssets mappings.
     * Emits BorrowAssetsUpdated event.
     */
    function _addBorrowAssets(ISetToken _setToken, IERC20[] memory _newBorrowAssets) internal {
        for(uint256 i = 0; i < _newBorrowAssets.length; i++) {
            IERC20 borrowAsset = _newBorrowAssets[i];
            
            _validateNewBorrowAsset(_setToken, borrowAsset);
            
            borrowAssetEnabled[_setToken][borrowAsset] = true;
            enabledAssets[_setToken].borrowAssets.push(address(borrowAsset));
        }
        emit BorrowAssetsUpdated(_setToken, true, _newBorrowAssets);
    }

    /**
     * @dev Updates SetToken's ability to use an asset as collateral on Aave
     */
    function _updateUseReserveAsCollateral(ISetToken _setToken, IERC20 _asset, bool _useAsCollateral) internal {
        /*
        Note: Aave ENABLES an asset to be used as collateral by `to` address in an `aToken.transfer(to, amount)` call provided 
            1. msg.sender (from address) isn't the same as `to` address
            2. `to` address had zero aToken balance before the transfer 
            3. transfer `amount` is greater than 0
        
        Note: Aave DISABLES an asset to be used as collateral by `msg.sender`in an `aToken.transfer(to, amount)` call provided 
            1. msg.sender (from address) isn't the same as `to` address
            2. msg.sender has zero balance after the transfer

        Different states of the SetToken and what this function does in those states:

            Case 1: Manager adds collateral asset to SetToken before first issuance
                - Since aToken.balanceOf(setToken) == 0, we do not call `setToken.invokeUserUseReserveAsCollateral` because Aave 
                requires aToken balance to be greater than 0 before enabling/disabling the underlying asset to be used as collateral 
                on Aave markets.
        
            Case 2: First issuance of the SetToken
                - SetToken was initialized with aToken as default position
                - DebtIssuanceModule reads the default position and transfers corresponding aToken from the issuer to the SetToken
                - Aave enables aToken to be used as collateral by the SetToken
                - Manager calls lever() and the aToken is used as collateral to borrow other assets

            Case 3: Manager removes collateral asset from the SetToken
                - Disable asset to be used as collateral on SetToken by calling `setToken.invokeSetUserUseReserveAsCollateral` with 
                useAsCollateral equals false
                - Note: If health factor goes below 1 by removing the collateral asset, then Aave reverts on the above call, thus whole
                transaction reverts, and manager can't remove corresponding collateral asset
        
            Case 4: Manager adds collateral asset after removing it
                - If aToken.balanceOf(setToken) > 0, we call `setToken.invokeUserUseReserveAsCollateral` and the corresponding aToken 
                is re-enabled as collateral on Aave
        
            Case 5: On redemption/delever/liquidated and aToken balance becomes zero
                - Aave disables aToken to be used as collateral by SetToken

        Values of variables in below if condition and corresponding action taken:

        ---------------------------------------------------------------------------------------------------------------------
        | usageAsCollateralEnabled |  _useAsCollateral |   aToken.balanceOf()  |     Action                                 |
        |--------------------------|-------------------|-----------------------|--------------------------------------------|
        |   true                   |   true            |      X                |   Skip invoke. Save gas.                   |
        |--------------------------|-------------------|-----------------------|--------------------------------------------|
        |   true                   |   false           |   greater than 0      |   Invoke and set to false.                 |
        |--------------------------|-------------------|-----------------------|--------------------------------------------|
        |   true                   |   false           |   = 0                 |   Impossible case. Aave disables usage as  |
        |                          |                   |                       |   collateral when aToken balance becomes 0 |
        |--------------------------|-------------------|-----------------------|--------------------------------------------|
        |   false                  |   false           |     X                 |   Skip invoke. Save gas.                   |
        |--------------------------|-------------------|-----------------------|--------------------------------------------|
        |   false                  |   true            |   greater than 0      |   Invoke and set to true.                  |
        |--------------------------|-------------------|-----------------------|--------------------------------------------|
        |   false                  |   true            |   = 0                 |   Don't invoke. Will revert.               |
        ---------------------------------------------------------------------------------------------------------------------
        */
        (,,,,,,,,bool usageAsCollateralEnabled) = protocolDataProvider.getUserReserveData(address(_asset), address(_setToken));
        if (
            usageAsCollateralEnabled != _useAsCollateral
            && underlyingToReserveTokens[_asset].aToken.balanceOf(address(_setToken)) > 0
        ) {
            _setToken.invokeSetUserUseReserveAsCollateral(
                ILendingPool(lendingPoolAddressesProvider.getLendingPool()),
                address(_asset),
                _useAsCollateral
            );
        }
    }

    /**
     * @dev Validate common requirements for lever and delever
     */
    function _validateCommon(ActionInfo memory _actionInfo) internal view {
        require(collateralAssetEnabled[_actionInfo.setToken][_actionInfo.collateralAsset], "Collateral not enabled");
        require(borrowAssetEnabled[_actionInfo.setToken][_actionInfo.borrowAsset], "Borrow not enabled");
        require(_actionInfo.collateralAsset != _actionInfo.borrowAsset, "Collateral and borrow asset must be different");
        require(_actionInfo.notionalSendQuantity > 0, "Quantity is 0");
    }

    /**
     * @dev Validates if a new asset can be added as collateral asset for given SetToken
     */
    function _validateNewCollateralAsset(ISetToken _setToken, IERC20 _asset) internal view {
        require(!collateralAssetEnabled[_setToken][_asset], "Collateral already enabled");
        
        (address aToken, , ) = protocolDataProvider.getReserveTokensAddresses(address(_asset));
        require(address(underlyingToReserveTokens[_asset].aToken) == aToken, "Invalid aToken address");
        
        ( , , , , , bool usageAsCollateralEnabled, , , bool isActive, bool isFrozen) = protocolDataProvider.getReserveConfigurationData(address(_asset));
        // An active reserve is an alias for a valid reserve on Aave.
        // We are checking for the availability of the reserve directly on Aave rather than checking our internal `underlyingToReserveTokens` mappings, 
        // because our mappings can be out-of-date if a new reserve is added to Aave
        require(isActive, "Invalid aave reserve");
        // A frozen reserve doesn't allow any new deposit, borrow or rate swap but allows repayments, liquidations and withdrawals
        require(!isFrozen, "Frozen aave reserve");
        require(usageAsCollateralEnabled, "Collateral disabled on Aave");
    }

    /**
     * @dev Validates if a new asset can be added as borrow asset for given SetToken
     */
    function _validateNewBorrowAsset(ISetToken _setToken, IERC20 _asset) internal view {
        require(!borrowAssetEnabled[_setToken][_asset], "Borrow already enabled");
        
        ( , , address variableDebtToken) = protocolDataProvider.getReserveTokensAddresses(address(_asset));
        require(address(underlyingToReserveTokens[_asset].variableDebtToken) == variableDebtToken, "Invalid variable debt token address");
        
        (, , , , , , bool borrowingEnabled, , bool isActive, bool isFrozen) = protocolDataProvider.getReserveConfigurationData(address(_asset));
        require(isActive, "Invalid aave reserve");
        require(!isFrozen, "Frozen aave reserve");
        require(borrowingEnabled, "Borrowing disabled on Aave");
    }

    /**
     * @dev Reads aToken balance and calculates default position unit for given collateral aToken and SetToken
     *
     * @return uint256       default collateral position unit          
     */
    function _getCollateralPosition(ISetToken _setToken, IAToken _aToken, uint256 _setTotalSupply) internal view returns (uint256) {
        uint256 collateralNotionalBalance = _aToken.balanceOf(address(_setToken));
        return collateralNotionalBalance.preciseDiv(_setTotalSupply);
    }
    
    /**
     * @dev Reads variableDebtToken balance and calculates external position unit for given borrow asset and SetToken
     *
     * @return int256       external borrow position unit
     */
    function _getBorrowPosition(ISetToken _setToken, IERC20 _borrowAsset, uint256 _setTotalSupply) internal view returns (int256) {
        uint256 borrowNotionalBalance = underlyingToReserveTokens[_borrowAsset].variableDebtToken.balanceOf(address(_setToken));
        return borrowNotionalBalance.preciseDivCeil(_setTotalSupply).toInt256().mul(-1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILendingPool } from "../../../interfaces/external/aave-v2/ILendingPool.sol";
import { ISetToken } from "../../../interfaces/ISetToken.sol";

/**
 * @title AaveV2
 * @author Set Protocol
 * 
 * Collection of helper functions for interacting with AaveV2 integrations.
 */
library AaveV2 {
    /* ============ External ============ */
    
    /**
     * Get deposit calldata from SetToken
     *
     * Deposits an `_amountNotional` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset to deposit
     * @param _amountNotional       The amount to be deposited
     * @param _onBehalfOf           The address that will receive the aTokens, same as msg.sender if the user
     *                              wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *                              is a different wallet
     * @param _referralCode         Code used to register the integrator originating the operation, for potential rewards.
     *                              0 if the action is executed directly by the user, without any middle-man
     *
     * @return address              Target contract address
     * @return uint256              Call value
     * @return bytes                Deposit calldata
     */
    function getDepositCalldata(
        ILendingPool _lendingPool,
        address _asset, 
        uint256 _amountNotional,
        address _onBehalfOf,
        uint16 _referralCode
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            _asset, 
            _amountNotional, 
            _onBehalfOf,
            _referralCode
        );
        
        return (address(_lendingPool), 0, callData);
    }
    
    /**
     * Invoke deposit on LendingPool from SetToken
     * 
     * Deposits an `_amountNotional` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. SetToken deposits 100 USDC and gets in return 100 aUSDC
     * @param _setToken             Address of the SetToken
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset to deposit
     * @param _amountNotional       The amount to be deposited
     */
    function invokeDeposit(
        ISetToken _setToken,
        ILendingPool _lendingPool,
        address _asset,
        uint256 _amountNotional        
    )
        external
    {
        ( , , bytes memory depositCalldata) = getDepositCalldata(
            _lendingPool,
            _asset,
            _amountNotional, 
            address(_setToken), 
            0
        );
        
        _setToken.invoke(address(_lendingPool), 0, depositCalldata);
    }
    
    /**
     * Get withdraw calldata from SetToken
     * 
     * Withdraws an `_amountNotional` of underlying asset from the reserve, burning the equivalent aTokens owned
     * - E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset to withdraw
     * @param _amountNotional       The underlying amount to be withdrawn
     *                              Note: Passing type(uint256).max will withdraw the entire aToken balance
     * @param _receiver             Address that will receive the underlying, same as msg.sender if the user
     *                              wants to receive it on his own wallet, or a different address if the beneficiary is a
     *                              different wallet
     *
     * @return address              Target contract address
     * @return uint256              Call value
     * @return bytes                Withdraw calldata
     */
    function getWithdrawCalldata(
        ILendingPool _lendingPool,
        address _asset, 
        uint256 _amountNotional,
        address _receiver        
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            _asset, 
            _amountNotional, 
            _receiver
        );
        
        return (address(_lendingPool), 0, callData);
    }
    
    /**
     * Invoke withdraw on LendingPool from SetToken
     * 
     * Withdraws an `_amountNotional` of underlying asset from the reserve, burning the equivalent aTokens owned
     * - E.g. SetToken has 100 aUSDC, and receives 100 USDC, burning the 100 aUSDC
     *     
     * @param _setToken         Address of the SetToken
     * @param _lendingPool      Address of the LendingPool contract
     * @param _asset            The address of the underlying asset to withdraw
     * @param _amountNotional   The underlying amount to be withdrawn
     *                          Note: Passing type(uint256).max will withdraw the entire aToken balance
     *
     * @return uint256          The final amount withdrawn
     */
    function invokeWithdraw(
        ISetToken _setToken,
        ILendingPool _lendingPool,
        address _asset,
        uint256 _amountNotional        
    )
        external
        returns (uint256)
    {
        ( , , bytes memory withdrawCalldata) = getWithdrawCalldata(
            _lendingPool,
            _asset,
            _amountNotional, 
            address(_setToken)
        );
        
        return abi.decode(_setToken.invoke(address(_lendingPool), 0, withdrawCalldata), (uint256));
    }
    
    /**
     * Get borrow calldata from SetToken
     *
     * Allows users to borrow a specific `_amountNotional` of the reserve underlying `_asset`, provided that 
     * the borrower already deposited enough collateral, or he was given enough allowance by a credit delegator
     * on the corresponding debt token (StableDebtToken or VariableDebtToken)
     *
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset to borrow
     * @param _amountNotional       The amount to be borrowed
     * @param _interestRateMode     The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param _referralCode         Code used to register the integrator originating the operation, for potential rewards.
     *                              0 if the action is executed directly by the user, without any middle-man
     * @param _onBehalfOf           Address of the user who will receive the debt. Should be the address of the borrower itself
     *                              calling the function if he wants to borrow against his own collateral, or the address of the
     *                              credit delegator if he has been given credit delegation allowance
     *
     * @return address              Target contract address
     * @return uint256              Call value
     * @return bytes                Borrow calldata
     */
    function getBorrowCalldata(
        ILendingPool _lendingPool,
        address _asset, 
        uint256 _amountNotional,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            _asset, 
            _amountNotional, 
            _interestRateMode,
            _referralCode,
            _onBehalfOf
        );
        
        return (address(_lendingPool), 0, callData);
    }
    
    /**
     * Invoke borrow on LendingPool from SetToken
     *
     * Allows SetToken to borrow a specific `_amountNotional` of the reserve underlying `_asset`, provided that 
     * the SetToken already deposited enough collateral, or it was given enough allowance by a credit delegator
     * on the corresponding debt token (StableDebtToken or VariableDebtToken)
     * @param _setToken             Address of the SetToken
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset to borrow
     * @param _amountNotional       The amount to be borrowed
     * @param _interestRateMode     The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     */
    function invokeBorrow(
        ISetToken _setToken,
        ILendingPool _lendingPool,
        address _asset,
        uint256 _amountNotional,
        uint256 _interestRateMode
    )
        external
    {
        ( , , bytes memory borrowCalldata) = getBorrowCalldata(
            _lendingPool,
            _asset,
            _amountNotional,
            _interestRateMode,
            0, 
            address(_setToken)
        );
        
        _setToken.invoke(address(_lendingPool), 0, borrowCalldata);
    }

    /**
     * Get repay calldata from SetToken
     *
     * Repays a borrowed `_amountNotional` on a specific `_asset` reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the borrowed underlying asset previously borrowed
     * @param _amountNotional       The amount to repay
     *                              Note: Passing type(uint256).max will repay the whole debt for `_asset` on the specific `_interestRateMode`
     * @param _interestRateMode     The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param _onBehalfOf           Address of the user who will get his debt reduced/removed. Should be the address of the
     *                              user calling the function if he wants to reduce/remove his own debt, or the address of any other
     *                              other borrower whose debt should be removed
     *
     * @return address              Target contract address
     * @return uint256              Call value
     * @return bytes                Repay calldata
     */
    function getRepayCalldata(
        ILendingPool _lendingPool,
        address _asset, 
        uint256 _amountNotional,
        uint256 _interestRateMode,        
        address _onBehalfOf
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            _asset, 
            _amountNotional, 
            _interestRateMode,            
            _onBehalfOf
        );
        
        return (address(_lendingPool), 0, callData);
    }

    /**
     * Invoke repay on LendingPool from SetToken
     *
     * Repays a borrowed `_amountNotional` on a specific `_asset` reserve, burning the equivalent debt tokens owned
     * - E.g. SetToken repays 100 USDC, burning 100 variable/stable debt tokens
     * @param _setToken             Address of the SetToken
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the borrowed underlying asset previously borrowed
     * @param _amountNotional       The amount to repay
     *                              Note: Passing type(uint256).max will repay the whole debt for `_asset` on the specific `_interestRateMode`
     * @param _interestRateMode     The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     *
     * @return uint256              The final amount repaid
     */
    function invokeRepay(
        ISetToken _setToken,
        ILendingPool _lendingPool,
        address _asset,
        uint256 _amountNotional,
        uint256 _interestRateMode
    )
        external
        returns (uint256)
    {
        ( , , bytes memory repayCalldata) = getRepayCalldata(
            _lendingPool,
            _asset,
            _amountNotional,
            _interestRateMode,
            address(_setToken)
        );
        
        return abi.decode(_setToken.invoke(address(_lendingPool), 0, repayCalldata), (uint256));
    }

    /**
     * Get setUserUseReserveAsCollateral calldata from SetToken
     * 
     * Allows borrower to enable/disable a specific deposited asset as collateral
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset deposited
     * @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
     *
     * @return address              Target contract address
     * @return uint256              Call value
     * @return bytes                SetUserUseReserveAsCollateral calldata
     */
    function getSetUserUseReserveAsCollateralCalldata(
        ILendingPool _lendingPool,
        address _asset,
        bool _useAsCollateral
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature(
            "setUserUseReserveAsCollateral(address,bool)", 
            _asset,
            _useAsCollateral
        );
        
        return (address(_lendingPool), 0, callData);
    }

    /**
     * Invoke an asset to be used as collateral on Aave from SetToken
     *
     * Allows SetToken to enable/disable a specific deposited asset as collateral
     * @param _setToken             Address of the SetToken
     * @param _lendingPool          Address of the LendingPool contract
     * @param _asset                The address of the underlying asset deposited
     * @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
     */
    function invokeSetUserUseReserveAsCollateral(
        ISetToken _setToken,
        ILendingPool _lendingPool,
        address _asset,
        bool _useAsCollateral
    )
        external
    {
        ( , , bytes memory callData) = getSetUserUseReserveAsCollateralCalldata(
            _lendingPool,
            _asset,
            _useAsCollateral
        );
        
        _setToken.invoke(address(_lendingPool), 0, callData);
    }
    
    /**
     * Get swapBorrowRate calldata from SetToken
     *
     * Allows a borrower to toggle his debt between stable and variable mode
     * @param _lendingPool      Address of the LendingPool contract
     * @param _asset            The address of the underlying asset borrowed
     * @param _rateMode         The rate mode that the user wants to swap to
     *
     * @return address          Target contract address
     * @return uint256          Call value
     * @return bytes            SwapBorrowRate calldata
     */
    function getSwapBorrowRateModeCalldata(
        ILendingPool _lendingPool,
        address _asset,
        uint256 _rateMode
    )
        public
        pure
        returns (address, uint256, bytes memory)
    {
        bytes memory callData = abi.encodeWithSignature(
            "swapBorrowRateMode(address,uint256)", 
            _asset,
            _rateMode
        );
        
        return (address(_lendingPool), 0, callData);
    }

    /**
     * Invoke to swap borrow rate of SetToken
     * 
     * Allows SetToken to toggle it's debt between stable and variable mode
     * @param _setToken         Address of the SetToken
     * @param _lendingPool      Address of the LendingPool contract
     * @param _asset            The address of the underlying asset borrowed
     * @param _rateMode         The rate mode that the user wants to swap to
     */
    function invokeSwapBorrowRateMode(
        ISetToken _setToken,
        ILendingPool _lendingPool,
        address _asset,
        uint256 _rateMode
    )
        external
    {
        ( , , bytes memory callData) = getSwapBorrowRateModeCalldata(
            _lendingPool,
            _asset,
            _rateMode
        );
        
        _setToken.invoke(address(_lendingPool), 0, callData);
    }
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IAToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { ISetToken } from "./ISetToken.sol";

/**
 * @title IDebtIssuanceModule
 * @author Set Protocol
 *
 * Interface for interacting with Debt Issuance module interface.
 */
interface IDebtIssuanceModule {

    /**
     * Called by another module to register itself on debt issuance module. Any logic can be included
     * in case checks need to be made or state needs to be updated.
     */
    function registerToIssuanceModule(ISetToken _setToken) external;

    /**
     * Called by another module to unregister itself on debt issuance module. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function unregisterFromIssuanceModule(ISetToken _setToken) external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IExchangeAdapter {
    function getSpender() external view returns(address);
    function getTradeCalldata(
        address _fromToken,
        address _toToken,
        address _toAddress,
        uint256 _fromQuantity,
        uint256 _minToQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";
import { DataTypes } from "./lib/DataTypes.sol";

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISetToken } from "./ISetToken.sol";


/**
 * CHANGELOG:
 *      - Added a module level issue hook that can be used to set state ahead of component level
 *        issue hooks
 */
interface IModuleIssuanceHook {

    function moduleIssueHook(ISetToken _setToken, uint256 _setTokenQuantity) external;
    function moduleRedeemHook(ISetToken _setToken, uint256 _setTokenQuantity) external;
    
    function componentIssueHook(
        ISetToken _setToken,
        uint256 _setTokenQuantity,
        IERC20 _component,
        bool _isEquity
    ) external;

    function componentRedeemHook(
        ISetToken _setToken,
        uint256 _setTokenQuantity,
        IERC20 _component,
        bool _isEquity
    ) external;
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);
  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);
  function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);
  function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IERC20 {}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "../../lib/ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ISetToken;
    using Position for ISetToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(ISetToken _setToken) {
        _validateOnlyManagerAndValidSet(_setToken);
        _;
    }

    modifier onlySetManager(ISetToken _setToken, address _caller) {
        _validateOnlySetManager(_setToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(ISetToken _setToken) {
        _validateOnlyValidAndInitializedSet(_setToken);
        _;
    }

    /**
     * Throws if the sender is not a SetToken's module or module not enabled
     */
    modifier onlyModule(ISetToken _setToken) {
        _validateOnlyModule(_setToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the SetToken is valid
     */
    modifier onlyValidAndPendingSet(ISetToken _setToken) {
        _validateOnlyValidAndPendingSet(_setToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter"); 
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _setToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(ISetToken _setToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _setToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the SetToken
     */
    function isSetPendingInitialization(ISetToken _setToken) internal view returns(bool) {
        return _setToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the SetToken's manager
     */
    function isSetManager(ISetToken _setToken, address _toCheck) internal view returns(bool) {
        return _setToken.manager() == _toCheck;
    }

    /**
     * Returns true if SetToken must be enabled on the controller 
     * and module is registered on the SetToken
     */
    function isSetValidAndInitialized(ISetToken _setToken) internal view returns(bool) {
        return controller.isSet(address(_setToken)) &&
            _setToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must SetToken manager and SetToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(ISetToken _setToken) internal view {
       require(isSetManager(_setToken, msg.sender), "Must be the SetToken manager");
       require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must SetToken manager
     */
    function _validateOnlySetManager(ISetToken _setToken, address _caller) internal view {
        require(isSetManager(_setToken, _caller), "Must be the SetToken manager");
    }

    /**
     * SetToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(ISetToken _setToken) internal view {
        require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ISetToken _setToken) internal view {
        require(
            _setToken.moduleStates(msg.sender) == ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * SetToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(ISetToken _setToken) internal view {
        require(controller.isSet(address(_setToken)), "Must be controller-enabled SetToken");
        require(isSetPendingInitialization(_setToken), "Must be pending initialization");
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

/*
  Copyright 2021 Set Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;


/**
 * @title IModule
 * @author Set Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a SetToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";


/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the SetToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the SetToken to set approvals of the ERC20 token to a spender.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the SetToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ISetToken _setToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _setToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _setToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     * The new SetToken balance must equal the existing balance less the quantity transferred
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the SetToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_setToken));

            Invoke.invokeTransfer(_setToken, _token, _to, _quantity);

            // Get new balance of transferred token for SetToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_setToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the SetToken to unwrap the passed quantity of WETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _setToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the SetToken to wrap the passed quantity of ETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _setToken.invoke(_weth, _quantity, callData);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";


/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating SetToken Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the SetToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the SetToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the SetToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(ISetToken _setToken, address _component, uint256 _unit) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the SetToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ISetToken _setToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _setToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the SetToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _setToken           Address of SetToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(ISetToken _setToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_setToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.removeComponent(_component);
            }
        }

        _setToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position. 
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _setToken         SetToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_setToken.isComponent(_component)) {
                _setToken.addComponent(_component);
                _setToken.addExternalPositionModule(_component, _module);
            } else if (!_setToken.isExternalPositionModule(_component, _module)) {
                _setToken.addExternalPositionModule(_component, _module);
            }
            _setToken.editExternalPositionUnit(_component, _module, _newUnit);
            _setToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_setToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _setToken.getExternalPositionModules(_component);
                if (_setToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _setToken.removeComponent(_component);
                }
                _setToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _setTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _setTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _setToken           Address of the SetToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(ISetToken _setToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _setToken.getDefaultPositionRealUnit(_component); 
        return _setToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _setToken                 Address of the SetToken
     * @param _component                Address of the component
     * @param _setTotalSupply           Current SetToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_setToken));
        uint256 positionUnit = _setToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_setToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes SetToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of SetToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_setTokenSupply));
        return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_setTokenSupply);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IController } from "../../interfaces/IController.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { ISetValuer } from "../../interfaces/ISetValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { ISetToken } from "../interfaces/ISetToken.sol";

interface ISetValuer {
    function calculateSetTokenValuation(ISetToken _setToken, address _quoteAsset) external view returns (uint256);
}

