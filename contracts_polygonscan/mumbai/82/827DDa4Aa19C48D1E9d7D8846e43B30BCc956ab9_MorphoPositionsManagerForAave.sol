// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../libraries/RedBlackBinaryTree.sol";
import "./libraries/aave/WadRayMath.sol";
import "./interfaces/aave/ILendingPoolAddressesProvider.sol";
import "./interfaces/aave/IProtocolDataProvider.sol";
import "./interfaces/aave/ILendingPool.sol";
import "./interfaces/aave/IPriceOracleGetter.sol";
import {IVariableDebtToken} from "./interfaces/aave/IVariableDebtToken.sol";
import {IAToken} from "./interfaces/aave/IAToken.sol";
import "./interfaces/IMarketsManagerForAave.sol";

/**
 *  @title MorphoPositionsManagerForAave
 *  @dev Smart contract interacting with Aave to enable P2P supply/borrow positions that can fallback on Aave's pool using poolToken tokens.
 */
contract MorphoPositionsManagerForAave is ReentrancyGuard {
    using RedBlackBinaryTree for RedBlackBinaryTree.Tree;
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Math for uint256;

    /* Structs */

    struct SupplyBalance {
        uint256 inP2P; // In p2pUnit, a unit that grows in value, to keep track of the interests/debt increase when users are in p2p.
        uint256 onPool; // In scaled balance.
    }

    struct BorrowBalance {
        uint256 inP2P; // In p2pUnit.
        uint256 onPool; // In adUnit, a unit that grows in value, to keep track of the debt increase when users are in Aave. Multiply by current borrowIndex to get the underlying amount.
    }

    // Struct to avoid stack too deep error
    struct BalanceStateVars {
        uint256 debtValue; // The total debt value (in ETH).
        uint256 maxDebtValue; // The maximum debt value available thanks to the collateral (in ETH).
        uint256 redeemedValue; // The redeemed value if any (in ETH).
        uint256 collateralValue; // The collateral value (in ETH).
        uint256 debtToAdd; // The debt to add at the current iteration (in ETH).
        uint256 collateralToAdd; // The collateral to add at the current iteration (in ETH).
        uint256 p2pExchangeRate; // The p2pUnit exchange rate of the `poolTokenEntered`.
        uint256 underlyingPrice; // The price of the underlying linked to the `poolTokenEntered` (in ETH).
        uint256 normalizedVariableDebt; // Normalized variable debt of the market.
        uint256 normalizedIncome; // Noramlized income of the market.
        uint256 liquidationThreshold; // The liquidation threshold on Aave.
        uint256 reserveDecimals; // The number of decimals of the asset in the reserve.
        uint256 tokenUnit; // The unit of tokens considering its decimals.
        address poolTokenEntered; // The poolToken token entered by the user.
        address underlyingAddress; // The address of the underlying.
        IPriceOracleGetter oracle; // Aave oracle.
    }

    // Struct to avoid stack too deep error
    struct LiquidateVars {
        uint256 debtValue; // The debt value (in ETH).
        uint256 maxDebtValue; // The maximum debt value possible (in ETH).
        uint256 borrowBalance; // Total borrow balance of the user for a given asset (in underlying).
        uint256 amountToSeize; // The amount of collateral the liquidator can seize (in underlying).
        uint256 borrowedPrice; // The price of the asset borrowed (in ETH).
        uint256 collateralPrice; // The price of the collateral asset (in ETH).
        uint256 normalizedIncome; // The normalized income of the asset.
        uint256 totalCollateral; // The total of collateral of the user (in underlying).
        uint256 liquidationBonus; // The liquidation bonus on Aave.
        uint256 collateralReserveDecimals; // The number of decimals of the collateral asset in the reserve.
        uint256 collateralTokenUnit; // The unit of collateral token considering its decimals.
        uint256 borrowedReserveDecimals; // The number of decimals of the borrowed asset in the reserve.
        uint256 borrowedTokenUnit; // The unit of borrowed token considering its decimals.
        address tokenBorrowedAddress; // The address of the borrowed asset.
        address tokenCollateralAddress; // The address of the collateral asset.
        IPriceOracleGetter oracle; // Aave oracle.
    }

    /* Storage */

    uint256 public constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5000; // In basis points.
    bytes32 public constant DATA_PROVIDER_ID =
        0x1000000000000000000000000000000000000000000000000000000000000000; // Id of the data provider.

    mapping(address => RedBlackBinaryTree.Tree) private suppliersInP2P; // Suppliers in peer-to-peer.
    mapping(address => RedBlackBinaryTree.Tree) private suppliersOnPool; // Suppliers on Aave.
    mapping(address => RedBlackBinaryTree.Tree) private borrowersInP2P; // Borrowers in peer-to-peer.
    mapping(address => RedBlackBinaryTree.Tree) private borrowersOnPool; // Borrowers on Aave.
    mapping(address => mapping(address => SupplyBalance)) public supplyBalanceInOf; // For a given market, the supply balance of user.
    mapping(address => mapping(address => BorrowBalance)) public borrowBalanceInOf; // For a given market, the borrow balance of user.
    mapping(address => mapping(address => bool)) public accountMembership; // Whether the account is in the market or not.
    mapping(address => address[]) public enteredMarkets; // Markets entered by a user.
    mapping(address => uint256) public threshold; // Thresholds below the ones suppliers and borrowers cannot enter markets.

    IMarketsManagerForAave public marketsManagerForAave;
    ILendingPoolAddressesProvider public addressesProvider;
    IProtocolDataProvider public dataProvider;
    ILendingPool public lendingPool;

    /* Events */

    /** @dev Emitted when a supply happens.
     *  @param _account The address of the supplier.
     *  @param _poolTokenAddress The address of the market where assets are supplied into.
     *  @param _amount The amount of assets.
     */
    event Supplied(address indexed _account, address indexed _poolTokenAddress, uint256 _amount);

    /** @dev Emitted when a withdraw happens.
     *  @param _account The address of the withdrawer.
     *  @param _poolTokenAddress The address of the market from where assets are withdrawn.
     *  @param _amount The amount of assets.
     */
    event Withdrawn(address indexed _account, address indexed _poolTokenAddress, uint256 _amount);

    /** @dev Emitted when a borrow happens.
     *  @param _account The address of the borrower.
     *  @param _poolTokenAddress The address of the market where assets are borrowed.
     *  @param _amount The amount of assets.
     */
    event Borrowed(address indexed _account, address indexed _poolTokenAddress, uint256 _amount);

    /** @dev Emitted when a repay happens.
     *  @param _account The address of the repayer.
     *  @param _poolTokenAddress The address of the market where assets are repaid.
     *  @param _amount The amount of assets.
     */
    event Repaid(address indexed _account, address indexed _poolTokenAddress, uint256 _amount);

    /** @dev Emitted when a supplier position is moved from Aave to P2P.
     *  @param _account The address of the supplier.
     *  @param _poolTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event SupplierMatched(
        address indexed _account,
        address indexed _poolTokenAddress,
        uint256 _amount
    );

    /** @dev Emitted when a supplier position is moved from P2P to Aave.
     *  @param _account The address of the supplier.
     *  @param _poolTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event SupplierUnmatched(
        address indexed _account,
        address indexed _poolTokenAddress,
        uint256 _amount
    );

    /** @dev Emitted when a borrower position is moved from Aave to P2P.
     *  @param _account The address of the borrower.
     *  @param _poolTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event BorrowerMatched(
        address indexed _account,
        address indexed _poolTokenAddress,
        uint256 _amount
    );

    /** @dev Emitted when a borrower position is moved from P2P to Aave.
     *  @param _account The address of the borrower.
     *  @param _poolTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event BorrowerUnmatched(
        address indexed _account,
        address indexed _poolTokenAddress,
        uint256 _amount
    );

    /* Modifiers */

    /** @dev Prevents a user to access a market not created yet.
     *  @param _poolTokenAddress The address of the market.
     */
    modifier isMarketCreated(address _poolTokenAddress) {
        require(marketsManagerForAave.isCreated(_poolTokenAddress), "mkt-not-created");
        _;
    }

    /** @dev Prevents a user to supply or borrow less than threshold.
     *  @param _poolTokenAddress The address of the market.
     *  @param _amount The amount in ERC20 tokens.
     */
    modifier isAboveThreshold(address _poolTokenAddress, uint256 _amount) {
        require(_amount >= threshold[_poolTokenAddress], "amount<threshold");
        _;
    }

    /** @dev Prevents a user to call function authorized only to the markets manager..
     */
    modifier onlyMarketsManager() {
        require(msg.sender == address(marketsManagerForAave), "only-mkt-manager");
        _;
    }

    /* Constructor */

    constructor(address _aaveMarketsManager, address _lendingPoolAddressesProvider) {
        marketsManagerForAave = IMarketsManagerForAave(_aaveMarketsManager);
        addressesProvider = ILendingPoolAddressesProvider(_lendingPoolAddressesProvider);
        dataProvider = IProtocolDataProvider(addressesProvider.getAddress(DATA_PROVIDER_ID));
        lendingPool = ILendingPool(addressesProvider.getLendingPool());
    }

    /* External */

    /** @dev Updates the lending pool and the data provider.
     */
    function updateAaveContracts() external {
        dataProvider = IProtocolDataProvider(addressesProvider.getAddress(DATA_PROVIDER_ID));
        lendingPool = ILendingPool(addressesProvider.getLendingPool());
    }

    /** @dev Sets the threshold of a market.
     *  @param _poolTokenAddress The address of the market to set the threshold.
     *  @param _newThreshold The new threshold.
     */
    function setThreshold(address _poolTokenAddress, uint256 _newThreshold)
        external
        onlyMarketsManager
    {
        threshold[_poolTokenAddress] = _newThreshold;
    }

    /** @dev Supplies ERC20 tokens in a specific market.
     *  @param _poolTokenAddress The address of the market the user wants to supply.
     *  @param _amount The amount to supply in ERC20 tokens.
     */
    function supply(address _poolTokenAddress, uint256 _amount)
        external
        nonReentrant
        isMarketCreated(_poolTokenAddress)
        isAboveThreshold(_poolTokenAddress, _amount)
    {
        _handleMembership(_poolTokenAddress, msg.sender);
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(address(underlyingToken));
        /* DEFAULT CASE: There aren't any borrowers waiting on Aave, Morpho supplies all the tokens to Aave */
        uint256 remainingToSupplyToAave = _amount;

        /* If some borrowers are waiting on Aave, Morpho matches the supplier in P2P with them as much as possible */
        if (borrowersOnPool[_poolTokenAddress].isNotEmpty()) {
            uint256 p2pExchangeRate = marketsManagerForAave.updateP2PUnitExchangeRate(
                _poolTokenAddress
            );
            remainingToSupplyToAave = _matchBorrowers(_poolTokenAddress, _amount); // In underlying
            uint256 matched = _amount - remainingToSupplyToAave;
            if (matched > 0) {
                supplyBalanceInOf[_poolTokenAddress][msg.sender].inP2P += matched
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad(); // In p2pUnit
            }
        }

        /* If there aren't enough borrowers waiting on Aave to match all the tokens supplied, the rest is supplied to Aave */
        if (remainingToSupplyToAave > 0) {
            supplyBalanceInOf[_poolTokenAddress][msg.sender].onPool += remainingToSupplyToAave
                .wadToRay()
                .rayDiv(normalizedIncome)
                .rayToWad(); // Scaled Balance
            _supplyERC20ToAave(_poolTokenAddress, remainingToSupplyToAave); // Revert on error
        }

        _updateSupplierList(_poolTokenAddress, msg.sender);
        emit Supplied(msg.sender, _poolTokenAddress, _amount);
    }

    /** @dev Borrows ERC20 tokens.
     *  @param _poolTokenAddress The address of the markets the user wants to enter.
     *  @param _amount The amount to borrow in ERC20 tokens.
     */
    function borrow(address _poolTokenAddress, uint256 _amount)
        external
        nonReentrant
        isMarketCreated(_poolTokenAddress)
        isAboveThreshold(_poolTokenAddress, _amount)
    {
        _handleMembership(_poolTokenAddress, msg.sender);
        _checkAccountLiquidity(msg.sender, _poolTokenAddress, 0, _amount);
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        /* DEFAULT CASE: There aren't any borrowers waiting on Cream, Morpho borrows all the tokens from Cream */
        uint256 remainingToBorrowOnAave = _amount;

        /* If some suppliers are waiting on Cream, Morpho matches the borrower in P2P with them as much as possible */
        if (suppliersOnPool[_poolTokenAddress].isNotEmpty()) {
            // No need to update p2pUnitExchangeRate here as it's done in `_checkAccountLiquidity`
            uint256 p2pExchangeRate = marketsManagerForAave.p2pUnitExchangeRate(_poolTokenAddress);
            remainingToBorrowOnAave = _matchSuppliers(_poolTokenAddress, _amount); // In underlying
            uint256 matched = _amount - remainingToBorrowOnAave;

            if (matched > 0) {
                borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P += matched
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad(); // In p2pUnit
            }
        }

        /* If there aren't enough suppliers waiting on Aave to match all the tokens borrowed, the rest is borrowed from Aave */
        if (remainingToBorrowOnAave > 0) {
            _unmatchTheSupplier(msg.sender); // Before borrowing on Aave, we put all the collateral of the borrower on Aave (cf Liquidation Invariant in docs)
            lendingPool.borrow(
                address(underlyingToken),
                remainingToBorrowOnAave,
                2,
                0,
                address(this)
            );
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool += remainingToBorrowOnAave
                .wadToRay()
                .rayDiv(lendingPool.getReserveNormalizedVariableDebt(address(underlyingToken)))
                .rayToWad(); // In adUnit
        }

        _updateBorrowerList(_poolTokenAddress, msg.sender);
        underlyingToken.safeTransfer(msg.sender, _amount);
        emit Borrowed(msg.sender, _poolTokenAddress, _amount);
    }

    /** @dev Withdraws ERC20 tokens from supply.
     *  @param _poolTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in tokens to withdraw from supply.
     */
    function withdraw(address _poolTokenAddress, uint256 _amount) external nonReentrant {
        _withdraw(_poolTokenAddress, _amount, msg.sender, msg.sender);
    }

    /** @dev Repays debt of the user.
     *  @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
     *  @param _poolTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in ERC20 tokens to repay.
     */
    function repay(address _poolTokenAddress, uint256 _amount) external nonReentrant {
        _repay(_poolTokenAddress, msg.sender, _amount);
    }

    /** @dev Allows someone to liquidate a position.
     *  @param _poolTokenBorrowedAddress The address of the debt token the liquidator wants to repay.
     *  @param _poolTokenCollateralAddress The address of the collateral the liquidator wants to seize.
     *  @param _borrower The address of the borrower to liquidate.
     *  @param _amount The amount to repay in ERC20 tokens.
     */
    function liquidate(
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external nonReentrant {
        require(_amount > 0, "liquidate:amount=0");
        LiquidateVars memory vars;
        (vars.debtValue, vars.maxDebtValue, ) = _getUserHypotheticalBalanceStates(
            _borrower,
            address(0),
            0,
            0
        );
        require(vars.debtValue > vars.maxDebtValue, "liquidate:debt-value<=max");
        IAToken poolTokenBorrowed = IAToken(_poolTokenBorrowedAddress);
        IAToken poolTokenCollateral = IAToken(_poolTokenCollateralAddress);
        vars.tokenBorrowedAddress = poolTokenBorrowed.UNDERLYING_ASSET_ADDRESS();
        vars.tokenCollateralAddress = poolTokenCollateral.UNDERLYING_ASSET_ADDRESS();
        vars.borrowBalance =
            borrowBalanceInOf[_poolTokenBorrowedAddress][_borrower]
                .onPool
                .wadToRay()
                .rayMul(lendingPool.getReserveNormalizedVariableDebt(vars.tokenBorrowedAddress))
                .wadToRay() +
            borrowBalanceInOf[_poolTokenBorrowedAddress][_borrower]
                .inP2P
                .wadToRay()
                .rayMul(marketsManagerForAave.p2pUnitExchangeRate(_poolTokenBorrowedAddress))
                .rayToWad();
        require(
            _amount <= vars.borrowBalance.mul(LIQUIDATION_CLOSE_FACTOR_PERCENT).div(10000),
            "liquidate:amount>allowed"
        );

        vars.oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        _repay(_poolTokenBorrowedAddress, _borrower, _amount);

        // Calculate the amount of token to seize from collateral
        vars.collateralPrice = vars.oracle.getAssetPrice(vars.tokenCollateralAddress); // In ETH
        vars.borrowedPrice = vars.oracle.getAssetPrice(vars.tokenBorrowedAddress); // In ETH
        (vars.collateralReserveDecimals, , , vars.liquidationBonus, , , , , , ) = dataProvider
            .getReserveConfigurationData(vars.tokenCollateralAddress);
        (vars.borrowedReserveDecimals, , , , , , , , , ) = dataProvider.getReserveConfigurationData(
            vars.tokenBorrowedAddress
        );
        vars.collateralTokenUnit = 10**vars.collateralReserveDecimals;
        vars.borrowedTokenUnit = 10**vars.borrowedReserveDecimals;
        vars.amountToSeize = _amount
            .mul(vars.borrowedPrice)
            .div(vars.borrowedTokenUnit)
            .mul(vars.collateralTokenUnit)
            .div(vars.collateralPrice)
            .mul(vars.liquidationBonus)
            .div(10000);
        vars.normalizedIncome = lendingPool.getReserveNormalizedIncome(vars.tokenCollateralAddress);
        vars.totalCollateral =
            supplyBalanceInOf[_poolTokenCollateralAddress][_borrower]
                .onPool
                .wadToRay()
                .rayMul(vars.normalizedIncome)
                .rayToWad() +
            supplyBalanceInOf[_poolTokenCollateralAddress][_borrower]
                .inP2P
                .wadToRay()
                .rayMul(
                    marketsManagerForAave.updateP2PUnitExchangeRate(_poolTokenCollateralAddress)
                )
                .rayToWad();
        require(vars.amountToSeize <= vars.totalCollateral, "liquidate:to-seize>collateral");

        _withdraw(_poolTokenCollateralAddress, vars.amountToSeize, _borrower, msg.sender);
    }

    /* Internal */

    /** @dev Withdraws ERC20 tokens from supply.
     *  @param _poolTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in tokens to withdraw from supply.
     *  @param _holder the user to whom Morpho will withdraw the supply.
     *  @param _receiver The address of the user that will receive the tokens.
     */
    function _withdraw(
        address _poolTokenAddress,
        uint256 _amount,
        address _holder,
        address _receiver
    ) internal isMarketCreated(_poolTokenAddress) {
        require(_amount > 0, "_withdraw:amount=0");
        _checkAccountLiquidity(_holder, _poolTokenAddress, _amount, 0);
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(address(underlyingToken));
        uint256 remainingToWithdraw = _amount;

        /* If user has some tokens waiting on Aave */
        if (supplyBalanceInOf[_poolTokenAddress][_holder].onPool > 0) {
            uint256 amountOnAaveInUnderlying = supplyBalanceInOf[_poolTokenAddress][_holder]
                .onPool
                .wadToRay()
                .rayMul(normalizedIncome)
                .rayToWad();
            /* CASE 1: User withdraws less than his Aave supply balance */
            if (_amount <= amountOnAaveInUnderlying) {
                _withdrawERC20FromAave(_poolTokenAddress, _amount); // Revert on error
                supplyBalanceInOf[_poolTokenAddress][_holder].onPool -= _amount
                    .wadToRay()
                    .rayDiv(normalizedIncome)
                    .rayToWad(); // In poolToken
                remainingToWithdraw = 0; // In underlying
            }
            /* CASE 2: User withdraws more than his Aave supply balance */
            else {
                _withdrawERC20FromAave(_poolTokenAddress, amountOnAaveInUnderlying); // Revert on error
                supplyBalanceInOf[_poolTokenAddress][_holder].onPool = 0;
                remainingToWithdraw = _amount - amountOnAaveInUnderlying; // In underlying
            }
        }

        /* If there remains some tokens to withdraw (CASE 2), Morpho breaks credit lines and repair them either with other users or with Aave itself */
        if (remainingToWithdraw > 0) {
            uint256 p2pExchangeRate = marketsManagerForAave.p2pUnitExchangeRate(_poolTokenAddress);
            uint256 aTokenContractBalance = poolToken.balanceOf(address(this));
            /* CASE 1: Other suppliers have enough tokens on Aave to compensate user's position*/
            if (remainingToWithdraw <= aTokenContractBalance) {
                require(
                    _matchSuppliers(_poolTokenAddress, remainingToWithdraw) == 0,
                    "_withdraw:_matchSuppliers!=0"
                );
                supplyBalanceInOf[_poolTokenAddress][_holder].inP2P -= remainingToWithdraw
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad(); // In p2pUnit
            }
            /* CASE 2: Other suppliers don't have enough tokens on Aave. Such scenario is called the Hard-Withdraw */
            else {
                uint256 remaining = _matchSuppliers(_poolTokenAddress, aTokenContractBalance);
                supplyBalanceInOf[_poolTokenAddress][_holder].inP2P -= remainingToWithdraw
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad(); // In p2pUnit
                remainingToWithdraw -= remaining;
                require(
                    _unmatchBorrowers(_poolTokenAddress, remainingToWithdraw) == 0, // We break some P2P credit lines the user had with borrowers and fallback on Aave.
                    "_withdraw:_unmatchBorrowers!=0"
                );
            }
        }

        _updateSupplierList(_poolTokenAddress, _holder);
        underlyingToken.safeTransfer(_receiver, _amount);
        emit Withdrawn(_holder, _poolTokenAddress, _amount);
    }

    /** @dev Implements repay logic.
     *  @dev `msg.sender` must have approved this contract to spend the underlying `_amount`.
     *  @param _poolTokenAddress The address of the market the user wants to interact with.
     *  @param _borrower The address of the `_borrower` to repay the borrow.
     *  @param _amount The amount of ERC20 tokens to repay.
     */
    function _repay(
        address _poolTokenAddress,
        address _borrower,
        uint256 _amount
    ) internal isMarketCreated(_poolTokenAddress) {
        require(_amount > 0, "_repay:amount=0");
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 remainingToRepay = _amount;

        /* If user is borrowing tokens on Aave */
        if (borrowBalanceInOf[_poolTokenAddress][_borrower].onPool > 0) {
            uint256 normalizedVariableDebt = lendingPool.getReserveNormalizedVariableDebt(
                address(underlyingToken)
            );
            uint256 onAaveInUnderlying = borrowBalanceInOf[_poolTokenAddress][_borrower]
                .onPool
                .wadToRay()
                .rayMul(normalizedVariableDebt)
                .rayToWad();
            /* CASE 1: User repays less than his Aave borrow balance */
            if (_amount <= onAaveInUnderlying) {
                underlyingToken.safeApprove(address(lendingPool), _amount);
                lendingPool.repay(address(underlyingToken), _amount, 2, address(this));
                borrowBalanceInOf[_poolTokenAddress][_borrower].onPool -= _amount
                    .wadToRay()
                    .rayDiv(normalizedVariableDebt)
                    .rayToWad(); // In adUnit
                remainingToRepay = 0;
            }
            /* CASE 2: User repays more than his Aave borrow balance */
            else {
                underlyingToken.safeApprove(address(lendingPool), onAaveInUnderlying);
                lendingPool.repay(address(underlyingToken), onAaveInUnderlying, 2, address(this));
                borrowBalanceInOf[_poolTokenAddress][_borrower].onPool = 0;
                remainingToRepay -= onAaveInUnderlying; // In underlying
            }
        }

        /* If there remains some tokens to repay (CASE 2), Morpho breaks credit lines and repair them either with other users or with Aave itself */
        if (remainingToRepay > 0) {
            DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(
                address(underlyingToken)
            );
            IVariableDebtToken variableDebtToken = IVariableDebtToken(
                reserveData.variableDebtTokenAddress
            );
            uint256 p2pExchangeRate = marketsManagerForAave.updateP2PUnitExchangeRate(
                _poolTokenAddress
            );
            uint256 contractBorrowBalanceOnAave = variableDebtToken.scaledBalanceOf(address(this));
            /* CASE 1: Other borrowers are borrowing enough on Aave to compensate user's position */
            if (remainingToRepay <= contractBorrowBalanceOnAave) {
                _matchBorrowers(_poolTokenAddress, remainingToRepay);
                borrowBalanceInOf[_poolTokenAddress][_borrower].inP2P -= remainingToRepay
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad();
            }
            /* CASE 2: Other borrowers aren't borrowing enough on Aave to compensate user's position */
            else {
                _matchBorrowers(_poolTokenAddress, contractBorrowBalanceOnAave);
                borrowBalanceInOf[_poolTokenAddress][_borrower].inP2P -= remainingToRepay
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad(); // In p2pUnit
                remainingToRepay -= contractBorrowBalanceOnAave;
                require(
                    _unmatchSuppliers(_poolTokenAddress, remainingToRepay) == 0, // We break some P2P credit lines the user had with suppliers and fallback on Aave.
                    "_repay:_unmatchSuppliers!=0"
                );
            }
        }

        _updateBorrowerList(_poolTokenAddress, _borrower);
        emit Repaid(_borrower, _poolTokenAddress, _amount);
    }

    /** @dev Supplies ERC20 tokens to Aave.
     *  @param _poolTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in ERC20 tokens to supply.
     */
    function _supplyERC20ToAave(address _poolTokenAddress, uint256 _amount) internal {
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        underlyingToken.safeApprove(address(lendingPool), _amount);
        lendingPool.deposit(address(underlyingToken), _amount, address(this), 0);
        lendingPool.setUserUseReserveAsCollateral(address(underlyingToken), true);
    }

    /** @dev Withdraws ERC20 tokens from Aave.
     *  @param _poolTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount of tokens to be withdrawn.
     */
    function _withdrawERC20FromAave(address _poolTokenAddress, uint256 _amount) internal {
        IAToken poolToken = IAToken(_poolTokenAddress);
        lendingPool.withdraw(poolToken.UNDERLYING_ASSET_ADDRESS(), _amount, address(this));
    }

    /** @dev Finds liquidity on Aave and matches it in P2P.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _poolTokenAddress The address of the market on which Morpho want to move users.
     *  @param _amount The amount to search for in underlying.
     *  @return remainingToMatch The remaining liquidity to search for in underlying.
     */
    function _matchSuppliers(address _poolTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToMatch)
    {
        IAToken poolToken = IAToken(_poolTokenAddress);
        remainingToMatch = _amount; // In underlying
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(
            poolToken.UNDERLYING_ASSET_ADDRESS()
        );
        address account = suppliersOnPool[_poolTokenAddress].last();

        bool metAccountWithDebtOnPool; // Stores whether or not we already met an account having debt on pools
        while (remainingToMatch > 0 && account != address(0)) {
            address tmpAccount;
            // Check if this user is not borrowing on Aave (cf Liquidation Invariant in docs)
            if (!_hasDebtOnPool(account)) {
                uint256 onAaveInUnderlying = supplyBalanceInOf[_poolTokenAddress][account]
                    .onPool
                    .wadToRay()
                    .rayMul(normalizedIncome)
                    .rayToWad();
                uint256 toMatch = Math.min(onAaveInUnderlying, remainingToMatch);
                supplyBalanceInOf[_poolTokenAddress][account].onPool -= toMatch
                    .wadToRay()
                    .rayDiv(normalizedIncome)
                    .rayToWad();
                remainingToMatch -= toMatch;
                supplyBalanceInOf[_poolTokenAddress][account].inP2P += toMatch
                    .wadToRay()
                    .rayDiv(marketsManagerForAave.p2pUnitExchangeRate(_poolTokenAddress))
                    .rayToWad(); // In p2pUnit
                if (metAccountWithDebtOnPool)
                    tmpAccount = suppliersOnPool[_poolTokenAddress].prev(account);
                else tmpAccount = suppliersOnPool[_poolTokenAddress].last();
                _updateSupplierList(_poolTokenAddress, account);
                emit SupplierMatched(account, _poolTokenAddress, toMatch);
            } else {
                metAccountWithDebtOnPool = true;
                tmpAccount = suppliersOnPool[_poolTokenAddress].prev(account);
            }
            account = tmpAccount;
        }
        // Withdraw from Aave
        uint256 toWithdraw = _amount - remainingToMatch;
        if (toWithdraw > 0) _withdrawERC20FromAave(_poolTokenAddress, toWithdraw);
    }

    /** @dev Finds liquidity in peer-to-peer and unmatches it to reconnect Aave.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _poolTokenAddress The address of the market on which Morpho want to move users.
     *  @param _amount The amount to search for in underlying.
     *  @return remainingToUnmatch The amount remaining to munmatchatch in underlying.
     */
    function _unmatchSuppliers(address _poolTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToUnmatch)
    {
        IAToken poolToken = IAToken(_poolTokenAddress);
        uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(
            poolToken.UNDERLYING_ASSET_ADDRESS()
        );
        remainingToUnmatch = _amount; // In underlying
        uint256 p2pExchangeRate = marketsManagerForAave.p2pUnitExchangeRate(_poolTokenAddress);
        address account = suppliersInP2P[_poolTokenAddress].last();

        while (remainingToUnmatch > 0 && account != address(0)) {
            uint256 inP2P = supplyBalanceInOf[_poolTokenAddress][account].inP2P; // In poolToken
            uint256 toUnmatch = Math.min(inP2P.mul(p2pExchangeRate), remainingToUnmatch); // In underlying
            remainingToUnmatch -= toUnmatch;
            supplyBalanceInOf[_poolTokenAddress][account].onPool += toUnmatch
                .wadToRay()
                .rayDiv(normalizedIncome)
                .rayToWad();
            supplyBalanceInOf[_poolTokenAddress][account].inP2P -= toUnmatch
                .wadToRay()
                .rayDiv(p2pExchangeRate)
                .rayToWad(); // In p2pUnit
            _updateSupplierList(_poolTokenAddress, account);
            emit SupplierUnmatched(account, _poolTokenAddress, toUnmatch);
            account = suppliersInP2P[_poolTokenAddress].last();
        }
        // Supply on Aave
        uint256 toSupply = _amount - remainingToUnmatch;
        if (toSupply > 0) _supplyERC20ToAave(_poolTokenAddress, _amount - remainingToUnmatch);
    }

    /** @dev Finds borrowers on Aave that match the given `_amount` and move them in P2P.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _poolTokenAddress The address of the market on which Morpho wants to move users.
     *  @param _amount The amount to match in underlying.
     *  @return remainingToMatch The amount remaining to match in underlying.
     */
    function _matchBorrowers(address _poolTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToMatch)
    {
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        remainingToMatch = _amount;
        uint256 normalizedVariableDebt = lendingPool.getReserveNormalizedVariableDebt(
            address(underlyingToken)
        );
        uint256 p2pExchangeRate = marketsManagerForAave.p2pUnitExchangeRate(_poolTokenAddress);
        address account = borrowersOnPool[_poolTokenAddress].last();

        while (remainingToMatch > 0 && account != address(0)) {
            uint256 onAaveInUnderlying = borrowBalanceInOf[_poolTokenAddress][account]
                .onPool
                .wadToRay()
                .rayMul(normalizedVariableDebt)
                .rayToWad();
            uint256 toMatch = Math.min(onAaveInUnderlying, remainingToMatch);
            borrowBalanceInOf[_poolTokenAddress][account].onPool -= toMatch
                .wadToRay()
                .rayDiv(normalizedVariableDebt)
                .rayToWad();
            remainingToMatch -= toMatch;
            borrowBalanceInOf[_poolTokenAddress][account].inP2P += toMatch
                .wadToRay()
                .rayDiv(p2pExchangeRate)
                .rayToWad();
            _updateBorrowerList(_poolTokenAddress, account);
            emit BorrowerMatched(account, _poolTokenAddress, toMatch);
            account = borrowersOnPool[_poolTokenAddress].last();
        }
        // Repay Aave
        uint256 toRepay = _amount - remainingToMatch;
        if (toRepay > 0) {
            underlyingToken.safeApprove(address(lendingPool), toRepay);
            lendingPool.repay(address(underlyingToken), toRepay, 2, address(this));
        }
    }

    /** @dev Finds borrowers in peer-to-peer that match the given `_amount` and move them to Aave.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _poolTokenAddress The address of the market on which Morpho wants to move users.
     *  @param _amount The amount to match in underlying.
     *  @return remainingToUnmatch The amount remaining to munmatchatch in underlying.
     */
    function _unmatchBorrowers(address _poolTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToUnmatch)
    {
        IAToken poolToken = IAToken(_poolTokenAddress);
        IERC20 underlyingToken = IERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        remainingToUnmatch = _amount;
        uint256 p2pExchangeRate = marketsManagerForAave.p2pUnitExchangeRate(_poolTokenAddress);
        uint256 normalizedVariableDebt = lendingPool.getReserveNormalizedVariableDebt(
            address(underlyingToken)
        );
        address account = borrowersInP2P[_poolTokenAddress].last();

        while (remainingToUnmatch > 0 && account != address(0)) {
            uint256 inP2P = borrowBalanceInOf[_poolTokenAddress][account].inP2P;
            _unmatchTheSupplier(account); // Before borrowing on Aave, we put all the collateral of the borrower on Aave (cf Liquidation Invariant in docs)
            uint256 toUnmatch = Math.min(inP2P.mul(p2pExchangeRate), remainingToUnmatch); // In underlying
            remainingToUnmatch -= toUnmatch;
            borrowBalanceInOf[_poolTokenAddress][account].onPool += toUnmatch
                .wadToRay()
                .rayDiv(normalizedVariableDebt)
                .rayToWad();
            borrowBalanceInOf[_poolTokenAddress][account].inP2P -= toUnmatch
                .wadToRay()
                .rayDiv(p2pExchangeRate)
                .rayToWad();
            _updateBorrowerList(_poolTokenAddress, account);
            emit BorrowerUnmatched(account, _poolTokenAddress, toUnmatch);
            account = borrowersInP2P[_poolTokenAddress].last();
        }
        // Borrow on Aave
        lendingPool.borrow(
            address(underlyingToken),
            _amount - remainingToUnmatch,
            2,
            0,
            address(this)
        );
    }

    /**
     * @dev Moves supply balance of an account from Morpho to Aave.
     * @param _account The address of the account to move balance.
     */
    function _unmatchTheSupplier(address _account) internal {
        for (uint256 i; i < enteredMarkets[_account].length; i++) {
            address poolTokenEntered = enteredMarkets[_account][i];
            uint256 normalizedIncome = lendingPool.getReserveNormalizedIncome(
                IAToken(poolTokenEntered).UNDERLYING_ASSET_ADDRESS()
            );
            uint256 inP2P = supplyBalanceInOf[poolTokenEntered][_account].inP2P;

            if (inP2P > 0) {
                uint256 p2pExchangeRate = marketsManagerForAave.p2pUnitExchangeRate(
                    poolTokenEntered
                );
                uint256 inP2PInUnderlying = inP2P.wadToRay().rayMul(p2pExchangeRate).rayToWad();
                supplyBalanceInOf[poolTokenEntered][_account].onPool += inP2PInUnderlying
                    .wadToRay()
                    .rayDiv(normalizedIncome)
                    .rayToWad();
                supplyBalanceInOf[poolTokenEntered][_account].inP2P -= inP2PInUnderlying
                    .wadToRay()
                    .rayDiv(p2pExchangeRate)
                    .rayToWad(); // In p2pUnit
                _unmatchBorrowers(poolTokenEntered, inP2PInUnderlying);
                _updateSupplierList(poolTokenEntered, _account);
                // Supply to Aave
                _supplyERC20ToAave(poolTokenEntered, inP2PInUnderlying);
                emit SupplierUnmatched(_account, poolTokenEntered, inP2PInUnderlying);
            }
        }
    }

    /**
     * @dev Enters the user into the market if he is not already there.
     * @param _account The address of the account to update.
     * @param _poolTokenAddress The address of the market to check.
     */
    function _handleMembership(address _poolTokenAddress, address _account) internal {
        if (!accountMembership[_poolTokenAddress][_account]) {
            accountMembership[_poolTokenAddress][_account] = true;
            enteredMarkets[_account].push(_poolTokenAddress);
        }
    }

    /** @dev Checks whether the user can borrow/withdraw or not.
     *  @param _account The user to determine liquidity for.
     *  @param _poolTokenAddress The market to hypothetically withdraw/borrow in.
     *  @param _withdrawnAmount The number of tokens to hypothetically withdraw.
     *  @param _borrowedAmount The amount of underlying to hypothetically borrow.
     */
    function _checkAccountLiquidity(
        address _account,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) internal {
        (uint256 debtValue, uint256 maxDebtValue, ) = _getUserHypotheticalBalanceStates(
            _account,
            _poolTokenAddress,
            _withdrawnAmount,
            _borrowedAmount
        );
        require(debtValue < maxDebtValue, "_checkAccountLiquidity:debt-value>max");
    }

    /** @dev Returns the debt value, max debt value and collateral value of a given user.
     *  @param _account The user to determine liquidity for.
     *  @param _poolTokenAddress The market to hypothetically withdraw/borrow in.
     *  @param _withdrawnAmount The number of tokens to hypothetically withdraw.
     *  @param _borrowedAmount The amount of underlying to hypothetically borrow.
     *  @return (debtValue, maxDebtValue collateralValue).
     */
    function _getUserHypotheticalBalanceStates(
        address _account,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Avoid stack too deep error
        BalanceStateVars memory vars;
        vars.oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());

        for (uint256 i; i < enteredMarkets[_account].length; i++) {
            vars.poolTokenEntered = enteredMarkets[_account][i];
            vars.p2pExchangeRate = marketsManagerForAave.updateP2PUnitExchangeRate(
                vars.poolTokenEntered
            );
            // Calculation of the current debt (in underlying)
            vars.underlyingAddress = IAToken(vars.poolTokenEntered).UNDERLYING_ASSET_ADDRESS();
            vars.normalizedVariableDebt = lendingPool.getReserveNormalizedVariableDebt(
                vars.underlyingAddress
            );
            vars.debtToAdd =
                borrowBalanceInOf[vars.poolTokenEntered][_account]
                    .onPool
                    .wadToRay()
                    .rayMul(vars.normalizedVariableDebt)
                    .rayToWad() +
                borrowBalanceInOf[vars.poolTokenEntered][_account].inP2P.mul(vars.p2pExchangeRate);
            // Calculation of the current collateral (in underlying)
            vars.normalizedIncome = lendingPool.getReserveNormalizedIncome(vars.underlyingAddress);
            vars.collateralToAdd =
                supplyBalanceInOf[vars.poolTokenEntered][_account]
                    .onPool
                    .wadToRay()
                    .rayMul(vars.normalizedIncome)
                    .rayToWad() +
                supplyBalanceInOf[vars.poolTokenEntered][_account].inP2P.mul(vars.p2pExchangeRate);
            vars.underlyingPrice = vars.oracle.getAssetPrice(vars.underlyingAddress); // In ETH

            (vars.reserveDecimals, , vars.liquidationThreshold, , , , , , , ) = dataProvider
                .getReserveConfigurationData(vars.underlyingAddress);
            vars.tokenUnit = 10**vars.reserveDecimals;
            if (_poolTokenAddress == vars.poolTokenEntered) {
                vars.debtToAdd += _borrowedAmount;
                vars.redeemedValue = _withdrawnAmount.mul(vars.underlyingPrice).div(vars.tokenUnit);
            }
            // Conversion of the collateral to ETH
            vars.collateralToAdd = vars.collateralToAdd.mul(vars.underlyingPrice).div(
                vars.tokenUnit
            );
            // Add the debt in this market to the global debt (in ETH)
            vars.debtValue += vars.debtToAdd.mul(vars.underlyingPrice).div(vars.tokenUnit);
            // Add the collateral value in this asset to the global collateral value (in ETH)
            vars.collateralValue += vars.collateralToAdd;
            // Add the max debt value allowed by the collateral in this asset to the global max debt value (in ETH)
            vars.maxDebtValue += vars.collateralToAdd.mul(vars.liquidationThreshold).div(10000);
        }

        vars.collateralValue -= vars.redeemedValue;

        return (vars.debtValue, vars.maxDebtValue, vars.collateralValue);
    }

    /** @dev Updates borrowers tree with the new balances of a given account.
     *  @param _poolTokenAddress The address of the market on which Morpho want to update the borrower lists.
     *  @param _account The address of the borrower to move.
     */
    function _updateBorrowerList(address _poolTokenAddress, address _account) internal {
        if (borrowersOnPool[_poolTokenAddress].keyExists(_account))
            borrowersOnPool[_poolTokenAddress].remove(_account);
        if (borrowersInP2P[_poolTokenAddress].keyExists(_account))
            borrowersInP2P[_poolTokenAddress].remove(_account);
        uint256 onPool = borrowBalanceInOf[_poolTokenAddress][_account].onPool;
        if (onPool > 0) borrowersOnPool[_poolTokenAddress].insert(_account, onPool);
        uint256 inP2P = borrowBalanceInOf[_poolTokenAddress][_account].inP2P;
        if (inP2P > 0) borrowersInP2P[_poolTokenAddress].insert(_account, inP2P);
    }

    /** @dev Updates suppliers tree with the new balances of a given account.
     *  @param _poolTokenAddress The address of the market on which Morpho want to update the supplier lists.
     *  @param _account The address of the supplier to move.
     */
    function _updateSupplierList(address _poolTokenAddress, address _account) internal {
        if (suppliersOnPool[_poolTokenAddress].keyExists(_account))
            suppliersOnPool[_poolTokenAddress].remove(_account);
        if (suppliersInP2P[_poolTokenAddress].keyExists(_account))
            suppliersInP2P[_poolTokenAddress].remove(_account);
        uint256 onPool = supplyBalanceInOf[_poolTokenAddress][_account].onPool;
        if (onPool > 0) suppliersOnPool[_poolTokenAddress].insert(_account, onPool);
        uint256 inP2P = supplyBalanceInOf[_poolTokenAddress][_account].inP2P;
        if (inP2P > 0) suppliersInP2P[_poolTokenAddress].insert(_account, inP2P);
    }

    function _hasDebtOnPool(address _account) internal view returns (bool) {
        for (uint256 i; i < enteredMarkets[_account].length; i++) {
            if (borrowBalanceInOf[enteredMarkets[_account][i]][_account].onPool > 0) return true;
        }
        return false;
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

    constructor() {
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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

// A Solidity Red-Black Tree library to store and maintain a sorted data structure in a Red-Black binary search tree,
// with O(log 2n) insert, remove and search time (and gas, approximately) based on https://github.com/rob-Hitchens/OrderStatisticsTree
// Copyright (c) Rob Hitchens. the MIT License.
// Significant portions from BokkyPooBahsRedBlackTreeLibrary,
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

library RedBlackBinaryTree {
    struct Node {
        address parent; // The parent node of the current node.
        address leftChild; // The left child of the current node.
        address rightChild; // The right child of the current node.
        bool red; // Whether the current node is red or black.
    }

    struct Tree {
        address root; // address of the root node
        mapping(address => Node) nodes; // Map user's address to node
        mapping(address => uint256) keyToValue; // Maps key to its value
    }

    /** @dev Returns the address of the smallest value in the tree `_self`.
     *  @param _self The tree to search in.
     */
    function first(Tree storage _self) public view returns (address key) {
        key = _self.root;
        if (key == address(0)) return address(0);
        while (_self.nodes[key].leftChild != address(0)) {
            key = _self.nodes[key].leftChild;
        }
    }

    /** @dev Returns the address of the highest value in the tree `_self`.
     *  @param _self The tree to search in.
     */
    function last(Tree storage _self) public view returns (address key) {
        key = _self.root;
        if (key == address(0)) return address(0);
        while (_self.nodes[key].rightChild != address(0)) {
            key = _self.nodes[key].rightChild;
        }
    }

    /** @dev Returns the address of the next user after `_key`.
     *  @param _self The tree to search in.
     *  @param _key The address to search after.
     */
    function next(Tree storage _self, address _key) public view returns (address cursor) {
        require(_key != address(0), "RBBT(1):key-is-nul-address");
        if (_self.nodes[_key].rightChild != address(0)) {
            cursor = subTreeMin(_self, _self.nodes[_key].rightChild);
        } else {
            cursor = _self.nodes[_key].parent;
            while (cursor != address(0) && _key == _self.nodes[cursor].rightChild) {
                _key = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    /** @dev Returns the address of the previous user above `_key`.
     *  @param _self The tree to search in.
     *  @param _key The address to search before.
     */
    function prev(Tree storage _self, address _key) public view returns (address cursor) {
        require(_key != address(0), "RBBT(2):start-value=0");
        if (_self.nodes[_key].leftChild != address(0)) {
            cursor = subTreeMax(_self, _self.nodes[_key].leftChild);
        } else {
            cursor = _self.nodes[_key].parent;
            while (cursor != address(0) && _key == _self.nodes[cursor].leftChild) {
                _key = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    /** @dev Returns whether the `_key` exists in the tree or not.
     *  @param _self The tree to search in.
     *  @param _key The key to search.
     *  @return Whether the `_key` exists in the tree or not.
     */
    function keyExists(Tree storage _self, address _key) public view returns (bool) {
        return _self.keyToValue[_key] != 0;
    }

    /** @dev Returns true if A>B according to the order relationship.
     *  @param _valueA value for user A.
     *  @param _addressA Address for user A.
     *  @param _valueB value for user B.
     *  @param _addressB Address for user B.
     */
    function compare(
        uint256 _valueA,
        address _addressA,
        uint256 _valueB,
        address _addressB
    ) public pure returns (bool) {
        if (_valueA == _valueB) {
            if (_addressA > _addressB) {
                return true;
            }
        }
        if (_valueA > _valueB) {
            return true;
        }
        return false;
    }

    /** @dev Returns whether or not there is any key in the tree.
     *  @param _self The tree to search in.
     *  @return Whether or not a key exist in the tree.
     */
    function isNotEmpty(Tree storage _self) public view returns (bool) {
        return _self.root != address(0);
    }

    /** @dev Inserts the `_key` with `_value` in the tree.
     *  @param _self The tree in which to add the (key, value) pair.
     *  @param _key The key to add.
     *  @param _value The value to add.
     */
    function insert(
        Tree storage _self,
        address _key,
        uint256 _value
    ) public {
        require(_value != 0, "RBBT:value-cannot-be-0");
        require(_self.keyToValue[_key] == 0, "RBBT:account-already-in");
        _self.keyToValue[_key] = _value;
        address cursor;
        address probe = _self.root;
        while (probe != address(0)) {
            cursor = probe;
            if (compare(_self.keyToValue[probe], probe, _value, _key)) {
                probe = _self.nodes[probe].leftChild;
            } else {
                probe = _self.nodes[probe].rightChild;
            }
        }
        Node storage nValue = _self.nodes[_key];
        nValue.parent = cursor;
        nValue.leftChild = address(0);
        nValue.rightChild = address(0);
        nValue.red = true;
        if (cursor == address(0)) {
            _self.root = _key;
        } else if (compare(_self.keyToValue[cursor], cursor, _value, _key)) {
            _self.nodes[cursor].leftChild = _key;
        } else {
            _self.nodes[cursor].rightChild = _key;
        }
        insertFixup(_self, _key);
    }

    /** @dev Removes the `_key` in the tree and its related value if no-one shares the same value.
     *  @param _self The tree in which to remove the (key, value) pair.
     *  @param _key The key to remove.
     */
    function remove(Tree storage _self, address _key) public {
        require(_self.keyToValue[_key] != 0, "RBBT:account-not-exist");
        _self.keyToValue[_key] = 0;
        address probe;
        address cursor;
        if (
            _self.nodes[_key].leftChild == address(0) || _self.nodes[_key].rightChild == address(0)
        ) {
            cursor = _key;
        } else {
            cursor = _self.nodes[_key].rightChild;
            while (_self.nodes[cursor].leftChild != address(0)) {
                cursor = _self.nodes[cursor].leftChild;
            }
        }
        if (_self.nodes[cursor].leftChild != address(0)) {
            probe = _self.nodes[cursor].leftChild;
        } else {
            probe = _self.nodes[cursor].rightChild;
        }
        address cursorParent = _self.nodes[cursor].parent;
        _self.nodes[probe].parent = cursorParent;
        if (cursorParent != address(0)) {
            if (cursor == _self.nodes[cursorParent].leftChild) {
                _self.nodes[cursorParent].leftChild = probe;
            } else {
                _self.nodes[cursorParent].rightChild = probe;
            }
        } else {
            _self.root = probe;
        }
        bool doFixup = !_self.nodes[cursor].red;
        if (cursor != _key) {
            replaceParent(_self, cursor, _key);
            _self.nodes[cursor].leftChild = _self.nodes[_key].leftChild;
            _self.nodes[_self.nodes[cursor].leftChild].parent = cursor;
            _self.nodes[cursor].rightChild = _self.nodes[_key].rightChild;
            _self.nodes[_self.nodes[cursor].rightChild].parent = cursor;
            _self.nodes[cursor].red = _self.nodes[_key].red;
            (cursor, _key) = (_key, cursor);
        }
        if (doFixup) {
            removeFixup(_self, probe);
        }
        delete _self.nodes[cursor];
    }

    /** @dev Returns the minimum of the subtree beginning at a given node.
     *  @param _self The tree to search in.
     *  @param _key The value of the node to start at.
     */
    function subTreeMin(Tree storage _self, address _key) private view returns (address) {
        while (_self.nodes[_key].leftChild != address(0)) {
            _key = _self.nodes[_key].leftChild;
        }
        return _key;
    }

    /** @dev Returns the maximum of the subtree beginning at a given node.
     *  @param _self The tree to search in.
     *  @param _key The address of the node to start at.
     */
    function subTreeMax(Tree storage _self, address _key) private view returns (address) {
        while (_self.nodes[_key].rightChild != address(0)) {
            _key = _self.nodes[_key].rightChild;
        }
        return _key;
    }

    /** @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's rightChild child), C (B's leftChild child).
     *       After leftChild rotation: B (Root), A (B's leftChild child), C (B's rightChild child)
     *  @param _self The tree to apply the rotation to.
     *  @param _key The address of the node to rotate.
     */
    function rotateLeft(Tree storage _self, address _key) private {
        address cursor = _self.nodes[_key].rightChild;
        address parent = _self.nodes[_key].parent;
        address cursorLeft = _self.nodes[cursor].leftChild;
        _self.nodes[_key].rightChild = cursorLeft;

        if (cursorLeft != address(0)) {
            _self.nodes[cursorLeft].parent = _key;
        }
        _self.nodes[cursor].parent = parent;
        if (parent == address(0)) {
            _self.root = cursor;
        } else if (_key == _self.nodes[parent].leftChild) {
            _self.nodes[parent].leftChild = cursor;
        } else {
            _self.nodes[parent].rightChild = cursor;
        }
        _self.nodes[cursor].leftChild = _key;
        _self.nodes[_key].parent = cursor;
    }

    /** @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's leftChild child), C (B's rightChild child).
             After rightChild rotation: B (Root), A (B's rightChild child), C (B's leftChild child)
     *  @param _self The tree to apply the rotation to.
     *  @param _key The address of the node to rotate.
     */
    function rotateRight(Tree storage _self, address _key) private {
        address cursor = _self.nodes[_key].leftChild;
        address parent = _self.nodes[_key].parent;
        address cursorRight = _self.nodes[cursor].rightChild;
        _self.nodes[_key].leftChild = cursorRight;
        if (cursorRight != address(0)) {
            _self.nodes[cursorRight].parent = _key;
        }
        _self.nodes[cursor].parent = parent;
        if (parent == address(0)) {
            _self.root = cursor;
        } else if (_key == _self.nodes[parent].rightChild) {
            _self.nodes[parent].rightChild = cursor;
        } else {
            _self.nodes[parent].leftChild = cursor;
        }
        _self.nodes[cursor].rightChild = _key;
        _self.nodes[_key].parent = cursor;
    }

    /** @dev Makes sure there is no violation of the tree properties after an insertion.
     *  @param _self The tree to check and correct if needed.
     *  @param _key The address of the user that was inserted.
     */
    function insertFixup(Tree storage _self, address _key) private {
        address cursor;
        while (_key != _self.root && _self.nodes[_self.nodes[_key].parent].red) {
            address keyParent = _self.nodes[_key].parent;
            if (keyParent == _self.nodes[_self.nodes[keyParent].parent].leftChild) {
                cursor = _self.nodes[_self.nodes[keyParent].parent].rightChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[keyParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    _key = keyParent;
                } else {
                    if (_key == _self.nodes[keyParent].rightChild) {
                        _key = keyParent;
                        rotateLeft(_self, _key);
                    }
                    keyParent = _self.nodes[_key].parent;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    rotateRight(_self, _self.nodes[keyParent].parent);
                }
            } else {
                cursor = _self.nodes[_self.nodes[keyParent].parent].leftChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[keyParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    _key = _self.nodes[keyParent].parent;
                } else {
                    if (_key == _self.nodes[keyParent].leftChild) {
                        _key = keyParent;
                        rotateRight(_self, _key);
                    }
                    keyParent = _self.nodes[_key].parent;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[keyParent].parent].red = true;
                    rotateLeft(_self, _self.nodes[keyParent].parent);
                }
            }
        }
        _self.nodes[_self.root].red = false;
    }

    /** @dev Replace the parent of A by B's parent.
     *  @param _self The tree to work with.
     *  @param _a The node that will get the new parents.
     *  @param _b The node that gives its parent.
     */
    function replaceParent(
        Tree storage _self,
        address _a,
        address _b
    ) private {
        address bParent = _self.nodes[_b].parent;
        _self.nodes[_a].parent = bParent;
        if (bParent == address(0)) {
            _self.root = _a;
        } else {
            if (_b == _self.nodes[bParent].leftChild) {
                _self.nodes[bParent].leftChild = _a;
            } else {
                _self.nodes[bParent].rightChild = _a;
            }
        }
    }

    /** @dev Makes sure there is no violation of the tree properties after removal.
     *  @param _self The tree to check and correct if needed.
     *  @param _key The address requested in the function remove.
     */
    function removeFixup(Tree storage _self, address _key) private {
        address cursor;
        while (_key != _self.root && !_self.nodes[_key].red) {
            address keyParent = _self.nodes[_key].parent;
            if (_key == _self.nodes[keyParent].leftChild) {
                cursor = _self.nodes[keyParent].rightChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[keyParent].red = true;
                    rotateLeft(_self, keyParent);
                    cursor = _self.nodes[keyParent].rightChild;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].leftChild].red &&
                    !_self.nodes[_self.nodes[cursor].rightChild].red
                ) {
                    _self.nodes[cursor].red = true;
                    _key = keyParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].rightChild].red) {
                        _self.nodes[_self.nodes[cursor].leftChild].red = false;
                        _self.nodes[cursor].red = true;
                        rotateRight(_self, cursor);
                        cursor = _self.nodes[keyParent].rightChild;
                    }
                    _self.nodes[cursor].red = _self.nodes[keyParent].red;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[cursor].rightChild].red = false;
                    rotateLeft(_self, keyParent);
                    _key = _self.root;
                }
            } else {
                cursor = _self.nodes[keyParent].leftChild;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[keyParent].red = true;
                    rotateRight(_self, keyParent);
                    cursor = _self.nodes[keyParent].leftChild;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].rightChild].red &&
                    !_self.nodes[_self.nodes[cursor].leftChild].red
                ) {
                    _self.nodes[cursor].red = true;
                    _key = keyParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].leftChild].red) {
                        _self.nodes[_self.nodes[cursor].rightChild].red = false;
                        _self.nodes[cursor].red = true;
                        rotateLeft(_self, cursor);
                        cursor = _self.nodes[keyParent].leftChild;
                    }
                    _self.nodes[cursor].red = _self.nodes[keyParent].red;
                    _self.nodes[keyParent].red = false;
                    _self.nodes[_self.nodes[cursor].leftChild].red = false;
                    rotateRight(_self, keyParent);
                    _key = _self.root;
                }
            }
        }
        _self.nodes[_key].red = false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    /**
     * @dev calculates base^exp. The code uses the ModExp precompile
     * @return z base^exp, in ray
     */
    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

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
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

/************
@title IPriceOracleGetter interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param onBehalfOf The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted when variable debt is burnt
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event Burn(address indexed user, uint256 amount, uint256 index);

    /**
     * @dev Burns user variable debt
     * @param user The user which debt is burnt
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IERC20} from "./IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface IAToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IMarketsManagerForAave {
    function isCreated(address _marketAddress) external returns (bool);

    function p2pSPY(address _marketAddress) external returns (uint256);

    function collateralFactor(address _marketAddress) external returns (uint256);

    function liquidationIncentive(address _marketAddress) external returns (uint256);

    function p2pUnitExchangeRate(address _marketAddress) external returns (uint256);

    function lastUpdateBlockNumber(address _marketAddress) external returns (uint256);

    function thresholds(address _marketAddress) external returns (uint256);

    function updateP2PUnitExchangeRate(address _marketAddress) external returns (uint256);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

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

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

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