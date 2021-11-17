// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./libraries/CompoundMath.sol";
import {ICErc20, IComptroller, ICompoundOracle} from "./interfaces/compound/ICompound.sol";
import "./interfaces/IMarketsManagerForCompound.sol";
import "./interfaces/IUpdatePositions.sol";
import "./PositionsManagerStorageForCompound.sol";

/**
 *  @title MorphoPositionsManagerForComp?
 *  @dev Smart contract interacting with Comp to enable P2P supply/borrow positions that can fallback on Comp's pool using cToken tokens.
 */
contract PositionsManagerForCompound is ReentrancyGuard, PositionsManagerStorageForCompound {
    using RedBlackBinaryTree for RedBlackBinaryTree.Tree;
    using EnumerableSet for EnumerableSet.AddressSet;
    using CompoundMath for uint256;
    using SafeERC20 for IERC20;
    using Math for uint256;

    /* Structs */

    // Struct to avoid stack too deep error
    struct BalanceStateVars {
        uint256 debtValue; // The total debt value (in USD).
        uint256 maxDebtValue; // The maximum debt value available thanks to the collateral (in USD).
        uint256 redeemedValue; // The redeemed value if any (in USD).
        uint256 collateralValue; // The collateral value (in USD).
        uint256 debtToAdd; // The debt to add at the current iteration.
        uint256 collateralToAdd; // The collateral to add at the current iteration.
        address cTokenEntered; // The cToken token entered by the user.
        uint256 p2pExchangeRate; // The p2pUnit exchange rate of the `cErc20Entered`.
        uint256 underlyingPrice; // The price of the underlying linked to the `cErc20Entered`.
    }

    // Struct to avoid stack too deep error
    struct LiquidateVars {
        uint256 borrowBalance; // Total borrow balance of the user in underlying for a given asset.
        uint256 amountToSeize; // The amount of collateral underlying the liquidator can seize.
        uint256 priceBorrowedMantissa; // The price of the asset borrowed (in USD).
        uint256 priceCollateralMantissa; // The price of the collateral asset (in USD).
        uint256 collateralOnPoolInUnderlying; // The amount of underlying the liquidatee has on Comp.
    }

    /* Events */

    /** @dev Emitted when a supply happens.
     *  @param _account The address of the supplier.
     *  @param _cTokenAddress The address of the market where assets are supplied into.
     *  @param _amount The amount of assets.
     */
    event Supplied(address indexed _account, address indexed _cTokenAddress, uint256 _amount);

    /** @dev Emitted when a withdraw happens.
     *  @param _account The address of the withdrawer.
     *  @param _cTokenAddress The address of the market from where assets are withdrawn.
     *  @param _amount The amount of assets.
     */
    event Withdrawn(address indexed _account, address indexed _cTokenAddress, uint256 _amount);

    /** @dev Emitted when a borrow happens.
     *  @param _account The address of the borrower.
     *  @param _cTokenAddress The address of the market where assets are borrowed.
     *  @param _amount The amount of assets.
     */
    event Borrowed(address indexed _account, address indexed _cTokenAddress, uint256 _amount);

    /** @dev Emitted when a repay happens.
     *  @param _account The address of the repayer.
     *  @param _cTokenAddress The address of the market where assets are repaid.
     *  @param _amount The amount of assets.
     */
    event Repaid(address indexed _account, address indexed _cTokenAddress, uint256 _amount);

    /** @dev Emitted when a supplier position is moved from Comp to P2P.
     *  @param _account The address of the supplier.
     *  @param _cTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event SupplierMatched(
        address indexed _account,
        address indexed _cTokenAddress,
        uint256 _amount
    );

    /** @dev Emitted when a supplier position is moved from P2P to Comp.
     *  @param _account The address of the supplier.
     *  @param _cTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event SupplierUnmatched(
        address indexed _account,
        address indexed _cTokenAddress,
        uint256 _amount
    );

    /** @dev Emitted when a borrower position is moved from Comp to P2P.
     *  @param _account The address of the borrower.
     *  @param _cTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event BorrowerMatched(
        address indexed _account,
        address indexed _cTokenAddress,
        uint256 _amount
    );

    /** @dev Emitted when a borrower position is moved from P2P to Comp.
     *  @param _account The address of the borrower.
     *  @param _cTokenAddress The address of the market.
     *  @param _amount The amount of assets.
     */
    event BorrowerUnmatched(
        address indexed _account,
        address indexed _cTokenAddress,
        uint256 _amount
    );

    /* Modifiers */

    /** @dev Prevents a user to access a market not created yet.
     *  @param _cTokenAddress The address of the market.
     */
    modifier isMarketCreated(address _cTokenAddress) {
        require(marketsManagerForCompound.isCreated(_cTokenAddress), "0");
        _;
    }

    /** @dev Prevents a user to supply or borrow less than threshold.
     *  @param _cTokenAddress The address of the market.
     *  @param _amount The amount in ERC20 tokens.
     */
    modifier isAboveThreshold(address _cTokenAddress, uint256 _amount) {
        require(_amount >= threshold[_cTokenAddress], "1");
        _;
    }

    /** @dev Prevents a user to call function only allowed for the markets manager.
     */
    modifier onlyMarketsManager() {
        require(msg.sender == address(marketsManagerForCompound), "2");
        _;
    }

    /** @dev Skips the operation if it is unsafe due to coumpound's revert on low levels of precision
     *  @param _amount The amount of token considered for depositing/redeeming
     *  @param _cTokenAddress cToken address of the considered market
     */
    modifier isAboveCompoundThreshold(address _cTokenAddress, uint256 _amount) {
        IERC20Metadata token = IERC20Metadata(ICErc20(_cTokenAddress).underlying());
        uint8 tokenDecimals = token.decimals();
        if (tokenDecimals > CTOKEN_DECIMALS) {
            // Multiply by 2 to have a safety buffer
            if (_amount > 2 * 10**(tokenDecimals - CTOKEN_DECIMALS)) {
                _;
            }
        } else {
            _;
        }
    }

    /* Constructor */

    /** @dev Constructs the PositionsManagerForCompound contract.
     *  @param _compoundMarketsManager The address of the markets manager.
     *  @param _proxyComptrollerAddress The address of the proxy comptroller.
     *  @param _updatePositionsAddress The address of the contract implementing the logic for positions updates.
     */
    constructor(
        address _compoundMarketsManager,
        address _proxyComptrollerAddress,
        address _updatePositionsAddress
    ) {
        marketsManagerForCompound = IMarketsManagerForCompound(_compoundMarketsManager);
        comptroller = IComptroller(_proxyComptrollerAddress);
        updatePositions = IUpdatePositions(_updatePositionsAddress);
    }

    /* External */

    /** @dev Creates Comp's markets.
     *  @param _cTokenAddress The address of the market the user wants to supply.
     *  @return The results of entered.
     */
    function createMarket(address _cTokenAddress)
        external
        onlyMarketsManager
        returns (uint256[] memory)
    {
        address[] memory marketToEnter = new address[](1);
        marketToEnter[0] = _cTokenAddress;
        return comptroller.enterMarkets(marketToEnter);
    }

    /** @dev Sets the comptroller address.
     *  @param _proxyComptrollerAddress The address of Comp's comptroller.
     */
    function setComptroller(address _proxyComptrollerAddress) external onlyMarketsManager {
        comptroller = IComptroller(_proxyComptrollerAddress);
    }

    /** @dev Sets the maximum number of users in tree.
     *  @param _newMaxNumber The maximum number of users to have in the tree.
     */
    function setMaxNumberOfUsersInTree(uint16 _newMaxNumber) external onlyMarketsManager {
        NMAX = _newMaxNumber;
    }

    /** @dev Sets the threshold of a market.
     *  @param _cTokenAddress The address of the market to set the threshold.
     *  @param _newThreshold The new threshold.
     */
    function setThreshold(address _cTokenAddress, uint256 _newThreshold)
        external
        onlyMarketsManager
    {
        threshold[_cTokenAddress] = _newThreshold;
    }

    /** @dev Supplies ERC20 tokens in a specific market.
     *  @param _cTokenAddress The address of the market the user wants to supply.
     *  @param _amount The amount to supply in ERC20 tokens.
     */
    function supply(address _cTokenAddress, uint256 _amount)
        external
        nonReentrant
        isMarketCreated(_cTokenAddress)
        isAboveThreshold(_cTokenAddress, _amount)
    {
        _handleMembership(_cTokenAddress, msg.sender);
        ICErc20 cToken = ICErc20(_cTokenAddress);
        IERC20 underlyingToken = IERC20(cToken.underlying());
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 cTokenExchangeRate = cToken.exchangeRateCurrent();
        /* DEFAULT CASE: There aren't any borrowers waiting on Comp, Morpho supplies all the tokens to Comp */
        uint256 remainingToSupplyToPool = _amount;

        /* If some borrowers are waiting on Comp, Morpho matches the supplier in P2P with them as much as possible */
        if (borrowersOnPool[_cTokenAddress].isNotEmpty()) {
            uint256 p2pExchangeRate = marketsManagerForCompound.updateP2pUnitExchangeRate(
                _cTokenAddress
            );
            remainingToSupplyToPool = _matchBorrowers(_cTokenAddress, _amount); // In underlying
            uint256 matched = _amount - remainingToSupplyToPool;

            if (matched > 0) {
                supplyBalanceInOf[_cTokenAddress][msg.sender].inP2P += matched.div(p2pExchangeRate); // In p2pUnit
            }
        }

        /* If there aren't enough borrowers waiting on Comp to match all the tokens supplied, the rest is supplied to Comp */
        if (remainingToSupplyToPool > 0) {
            supplyBalanceInOf[_cTokenAddress][msg.sender].onPool += remainingToSupplyToPool.div(
                cTokenExchangeRate
            ); // In cToken
            _supplyERC20ToPool(_cTokenAddress, remainingToSupplyToPool); // Revert on error
        }

        _updateSupplierList(_cTokenAddress, msg.sender);
        emit Supplied(msg.sender, _cTokenAddress, _amount);
    }

    /** @dev Borrows ERC20 tokens.
     *  @param _cTokenAddress The address of the markets the user wants to enter.
     *  @param _amount The amount to borrow in ERC20 tokens.
     */
    function borrow(address _cTokenAddress, uint256 _amount)
        external
        nonReentrant
        isMarketCreated(_cTokenAddress)
        isAboveThreshold(_cTokenAddress, _amount)
    {
        _handleMembership(_cTokenAddress, msg.sender);
        _checkAccountLiquidity(msg.sender, _cTokenAddress, 0, _amount);
        ICErc20 cToken = ICErc20(_cTokenAddress);
        IERC20 underlyingToken = IERC20(cToken.underlying());
        /* DEFAULT CASE: There aren't any borrowers waiting on Comp, Morpho borrows all the tokens from Comp */
        uint256 remainingToBorrowOnPool = _amount;

        /* If some suppliers are waiting on Comp, Morpho matches the borrower in P2P with them as much as possible */
        if (suppliersOnPool[_cTokenAddress].isNotEmpty()) {
            uint256 p2pExchangeRate = marketsManagerForCompound.p2pUnitExchangeRate(_cTokenAddress);
            remainingToBorrowOnPool = _matchSuppliers(_cTokenAddress, _amount); // In underlying
            uint256 matched = _amount - remainingToBorrowOnPool;
            if (matched > 0) {
                borrowBalanceInOf[_cTokenAddress][msg.sender].inP2P += matched.div(p2pExchangeRate); // In p2pUnit
            }
        }

        /* If there aren't enough suppliers waiting on Comp to match all the tokens borrowed, the rest is borrowed from Comp */
        if (remainingToBorrowOnPool > 0) {
            require(cToken.borrow(remainingToBorrowOnPool) == 0, "3");
            borrowBalanceInOf[_cTokenAddress][msg.sender].onPool += remainingToBorrowOnPool.div(
                cToken.borrowIndex()
            ); // In cdUnit
        }

        _updateBorrowerList(_cTokenAddress, msg.sender);
        underlyingToken.safeTransfer(msg.sender, _amount);
        emit Borrowed(msg.sender, _cTokenAddress, _amount);
    }

    /** @dev Withdraws ERC20 tokens from supply.
     *  @param _cTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in tokens to withdraw from supply.
     */
    function withdraw(address _cTokenAddress, uint256 _amount) external nonReentrant {
        _withdraw(_cTokenAddress, _amount, msg.sender, msg.sender);
    }

    /** @dev Repays debt of the user.
     *  @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
     *  @param _cTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in ERC20 tokens to repay.
     */
    function repay(address _cTokenAddress, uint256 _amount) external nonReentrant {
        _repay(_cTokenAddress, msg.sender, _amount);
    }

    /** @dev Allows someone to liquidate a position.
     *  @param _cTokenBorrowedAddress The address of the debt token the liquidator wants to repay.
     *  @param _cTokenCollateralAddress The address of the collateral the liquidator wants to seize.
     *  @param _borrower The address of the borrower to liquidate.
     *  @param _amount The amount to repay in ERC20 tokens.
     */
    function liquidate(
        address _cTokenBorrowedAddress,
        address _cTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external nonReentrant {
        require(_amount > 0, "4");
        (uint256 debtValue, uint256 maxDebtValue, ) = _getUserHypotheticalBalanceStates(
            _borrower,
            address(0),
            0,
            0
        );
        require(debtValue > maxDebtValue, "5");
        LiquidateVars memory vars;
        vars.borrowBalance =
            borrowBalanceInOf[_cTokenBorrowedAddress][_borrower].onPool.mul(
                ICErc20(_cTokenBorrowedAddress).borrowIndex()
            ) +
            borrowBalanceInOf[_cTokenBorrowedAddress][_borrower].inP2P.mul(
                marketsManagerForCompound.p2pUnitExchangeRate(_cTokenBorrowedAddress)
            );
        require(_amount <= vars.borrowBalance.mul(comptroller.closeFactorMantissa()), "6");

        _repay(_cTokenBorrowedAddress, _borrower, _amount);

        // Calculate the amount of token to seize from collateral
        ICompoundOracle compoundOracle = ICompoundOracle(comptroller.oracle());
        vars.priceCollateralMantissa = compoundOracle.getUnderlyingPrice(_cTokenCollateralAddress);
        vars.priceBorrowedMantissa = compoundOracle.getUnderlyingPrice(_cTokenBorrowedAddress);
        require(vars.priceCollateralMantissa != 0 && vars.priceBorrowedMantissa != 0, "7");

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        ICErc20 cTokenCollateralToken = ICErc20(_cTokenCollateralAddress);

        vars.amountToSeize = _amount
            .mul(vars.priceBorrowedMantissa)
            .mul(comptroller.liquidationIncentiveMantissa())
            .div(vars.priceCollateralMantissa);

        vars.collateralOnPoolInUnderlying = supplyBalanceInOf[_cTokenCollateralAddress][_borrower]
            .onPool
            .mul(cTokenCollateralToken.exchangeRateStored());
        uint256 totalCollateral = vars.collateralOnPoolInUnderlying +
            supplyBalanceInOf[_cTokenCollateralAddress][_borrower].inP2P.mul(
                marketsManagerForCompound.updateP2pUnitExchangeRate(_cTokenCollateralAddress)
            );

        require(vars.amountToSeize <= totalCollateral, "8");
        _withdraw(_cTokenCollateralAddress, vars.amountToSeize, _borrower, msg.sender);
    }

    /* Internal */

    /** @dev Withdraws ERC20 tokens from supply.
     *  @param _cTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in tokens to withdraw from supply.
     *  @param _holder the user to whom Morpho will withdraw the supply.
     *  @param _receiver The address of the user that will receive the tokens.
     */
    function _withdraw(
        address _cTokenAddress,
        uint256 _amount,
        address _holder,
        address _receiver
    ) internal isMarketCreated(_cTokenAddress) {
        require(_amount > 0, "9");
        _checkAccountLiquidity(_holder, _cTokenAddress, _amount, 0);
        ICErc20 cToken = ICErc20(_cTokenAddress);
        IERC20 underlyingToken = IERC20(cToken.underlying());
        uint256 cTokenExchangeRate = cToken.exchangeRateCurrent();
        uint256 remainingToWithdraw = _amount;

        /* If user has some tokens waiting on Comp */
        if (supplyBalanceInOf[_cTokenAddress][_holder].onPool > 0) {
            uint256 amountOnPoolInUnderlying = supplyBalanceInOf[_cTokenAddress][_holder]
                .onPool
                .mul(cTokenExchangeRate);
            /* CASE 1: User withdraws less than his Comp supply balance */
            if (_amount <= amountOnPoolInUnderlying) {
                _withdrawERC20FromComp(_cTokenAddress, _amount); // Revert on error
                supplyBalanceInOf[_cTokenAddress][_holder].onPool -= _amount.div(
                    cTokenExchangeRate
                ); // In cToken
                remainingToWithdraw = 0; // In underlying
            }
            /* CASE 2: User withdraws more than his Comp supply balance */
            else {
                require(
                    cToken.redeem(supplyBalanceInOf[_cTokenAddress][_holder].onPool) == 0,
                    "10"
                );
                supplyBalanceInOf[_cTokenAddress][_holder].onPool = 0;
                remainingToWithdraw = _amount - amountOnPoolInUnderlying; // In underlying
            }
        }

        /* If there remains some tokens to withdraw (CASE 2), Morpho breaks credit lines and repair them either with other users or with Comp itself */
        if (remainingToWithdraw > 0) {
            uint256 p2pExchangeRate = marketsManagerForCompound.p2pUnitExchangeRate(_cTokenAddress);
            uint256 cTokenContractBalanceInUnderlying = cToken.balanceOf(address(this)).mul(
                cTokenExchangeRate
            );
            /* CASE 1: Other suppliers have enough tokens on Comp to compensate user's position*/
            if (remainingToWithdraw <= cTokenContractBalanceInUnderlying) {
                require(_matchSuppliers(_cTokenAddress, remainingToWithdraw) == 0, "11");
                supplyBalanceInOf[_cTokenAddress][_holder].inP2P -= remainingToWithdraw.div(
                    p2pExchangeRate
                ); // In p2pUnit
            }
            /* CASE 2: Other suppliers don't have enough tokens on Comp. Such scenario is called the Hard-Withdraw */
            else {
                uint256 remaining = _matchSuppliers(
                    _cTokenAddress,
                    cTokenContractBalanceInUnderlying
                );
                supplyBalanceInOf[_cTokenAddress][_holder].inP2P -= remainingToWithdraw.div(
                    p2pExchangeRate
                ); // In p2pUnit
                remainingToWithdraw -= remaining;
                require(
                    _unmatchBorrowers(_cTokenAddress, remainingToWithdraw) == 0, // We break some P2P credit lines the user had with borrowers and fallback on Comp.
                    "12"
                );
            }
        }

        _updateSupplierList(_cTokenAddress, _holder);
        underlyingToken.safeTransfer(_receiver, _amount);
        emit Withdrawn(_holder, _cTokenAddress, _amount);
    }

    /** @dev Implements repay updatePositions.
     *  @dev `msg.sender` must have approved this contract to spend the underlying `_amount`.
     *  @param _cTokenAddress The address of the market the user wants to interact with.
     *  @param _borrower The address of the `_borrower` to repay the borrow.
     *  @param _amount The amount of ERC20 tokens to repay.
     */
    function _repay(
        address _cTokenAddress,
        address _borrower,
        uint256 _amount
    ) internal isMarketCreated(_cTokenAddress) {
        require(_amount > 0, "13");
        ICErc20 cToken = ICErc20(_cTokenAddress);
        IERC20 underlyingToken = IERC20(cToken.underlying());
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 remainingToRepay = _amount;

        /* If user is borrowing tokens on Comp */
        if (borrowBalanceInOf[_cTokenAddress][_borrower].onPool > 0) {
            uint256 borrowIndex = cToken.borrowIndex();
            uint256 onPoolInUnderlying = borrowBalanceInOf[_cTokenAddress][_borrower].onPool.mul(
                borrowIndex
            );
            /* CASE 1: User repays less than his Comp borrow balance */
            if (_amount <= onPoolInUnderlying) {
                underlyingToken.safeApprove(_cTokenAddress, _amount);
                cToken.repayBorrow(_amount);
                borrowBalanceInOf[_cTokenAddress][_borrower].onPool -= _amount.div(borrowIndex); // In cdUnit
                remainingToRepay = 0;
            }
            /* CASE 2: User repays more than his Comp borrow balance */
            else {
                underlyingToken.safeApprove(_cTokenAddress, onPoolInUnderlying);
                cToken.repayBorrow(onPoolInUnderlying); // Revert on error
                borrowBalanceInOf[_cTokenAddress][_borrower].onPool = 0;
                remainingToRepay -= onPoolInUnderlying; // In underlying
            }
        }

        /* If there remains some tokens to repay (CASE 2), Morpho breaks credit lines and repair them either with other users or with Comp itself */
        if (remainingToRepay > 0) {
            // No need to update p2pUnitExchangeRate here as it's done in `_checkAccountLiquidity`
            uint256 p2pExchangeRate = marketsManagerForCompound.updateP2pUnitExchangeRate(
                _cTokenAddress
            );
            uint256 contractBorrowBalanceOnPool = cToken.borrowBalanceCurrent(address(this)); // In underlying
            /* CASE 1: Other borrowers are borrowing enough on Comp to compensate user's position */
            if (remainingToRepay <= contractBorrowBalanceOnPool) {
                _matchBorrowers(_cTokenAddress, remainingToRepay);
                borrowBalanceInOf[_cTokenAddress][_borrower].inP2P -= remainingToRepay.div(
                    p2pExchangeRate
                );
            }
            /* CASE 2: Other borrowers aren't borrowing enough on Comp to compensate user's position */
            else {
                _matchBorrowers(_cTokenAddress, contractBorrowBalanceOnPool);
                borrowBalanceInOf[_cTokenAddress][_borrower].inP2P -= remainingToRepay.div(
                    p2pExchangeRate
                ); // In p2pUnit
                remainingToRepay -= contractBorrowBalanceOnPool;
                require(
                    _unmatchSuppliers(_cTokenAddress, remainingToRepay) == 0, // We break some P2P credit lines the user had with suppliers and fallback on Comp.
                    "14"
                );
            }
        }

        _updateBorrowerList(_cTokenAddress, _borrower);
        emit Repaid(_borrower, _cTokenAddress, _amount);
    }

    /** @dev Supplies ERC20 tokens to Comp.
     *  @param _cTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount in ERC20 tokens to supply.
     */
    function _supplyERC20ToPool(address _cTokenAddress, uint256 _amount)
        internal
        isAboveCompoundThreshold(_cTokenAddress, _amount)
    {
        ICErc20 cToken = ICErc20(_cTokenAddress);
        IERC20 underlyingToken = IERC20(cToken.underlying());
        underlyingToken.safeApprove(_cTokenAddress, _amount);
        require(cToken.mint(_amount) == 0, "15");
    }

    /** @dev Withdraws ERC20 tokens from Comp.
     *  @param _cTokenAddress The address of the market the user wants to interact with.
     *  @param _amount The amount of tokens to be withdrawn.
     */
    function _withdrawERC20FromComp(address _cTokenAddress, uint256 _amount)
        internal
        isAboveCompoundThreshold(_cTokenAddress, _amount)
    {
        ICErc20 cToken = ICErc20(_cTokenAddress);
        require(cToken.redeemUnderlying(_amount) == 0, "16");
    }

    /** @dev Finds liquidity on Comp and matches it in P2P.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _cTokenAddress The address of the market on which Morpho want to move users.
     *  @param _amount The amount to search for in underlying.
     *  @return remainingToMatch The remaining liquidity to search for in underlying.
     */
    function _matchSuppliers(address _cTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToMatch)
    {
        ICErc20 cToken = ICErc20(_cTokenAddress);
        remainingToMatch = _amount; // In underlying
        uint256 p2pExchangeRate = marketsManagerForCompound.p2pUnitExchangeRate(_cTokenAddress);
        uint256 cTokenExchangeRate = cToken.exchangeRateCurrent();
        (, address account) = suppliersOnPool[_cTokenAddress].getMaximum();

        while (remainingToMatch > 0 && account != address(0)) {
            address tmpAccount;
            // Check if this user is not borrowing on Pool (cf Liquidation Invariant in docs)
            uint256 onPoolInUnderlying = supplyBalanceInOf[_cTokenAddress][account].onPool.mul(
                cTokenExchangeRate
            ); // In underlying
            uint256 toMatch;
            // This is done to prevent rounding errors
            if (onPoolInUnderlying <= remainingToMatch) {
                supplyBalanceInOf[_cTokenAddress][account].onPool = 0;
                toMatch = onPoolInUnderlying;
            } else {
                toMatch = remainingToMatch;
                supplyBalanceInOf[_cTokenAddress][account].onPool -= toMatch.div(
                    cTokenExchangeRate
                ); // In cToken
            }
            remainingToMatch -= toMatch;
            supplyBalanceInOf[_cTokenAddress][account].inP2P += toMatch.div(p2pExchangeRate); // In p2pUnit
            _updateSupplierList(_cTokenAddress, account);
            emit SupplierMatched(account, _cTokenAddress, toMatch);
            account = tmpAccount;
        }
        // Withdraw from Comp
        _withdrawERC20FromComp(_cTokenAddress, _amount - remainingToMatch);
    }

    /** @dev Finds liquidity in peer-to-peer and unmatches it to reconnect Comp.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _cTokenAddress The address of the market on which Morpho want to move users.
     *  @param _amount The amount to search for in underlying.
     *  @return remainingToUnmatch The amount remaining to munmatchatch in underlying.
     */
    function _unmatchSuppliers(address _cTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToUnmatch)
    {
        ICErc20 cToken = ICErc20(_cTokenAddress);
        remainingToUnmatch = _amount; // In underlying
        uint256 cTokenExchangeRate = cToken.exchangeRateCurrent();
        uint256 p2pExchangeRate = marketsManagerForCompound.p2pUnitExchangeRate(_cTokenAddress);
        (, address account) = suppliersInP2P[_cTokenAddress].getMaximum();

        while (remainingToUnmatch > 0 && account != address(0)) {
            uint256 inP2P = supplyBalanceInOf[_cTokenAddress][account].inP2P; // In cToken
            uint256 toUnmatch = Math.min(inP2P.mul(p2pExchangeRate), remainingToUnmatch); // In underlying
            remainingToUnmatch -= toUnmatch;
            supplyBalanceInOf[_cTokenAddress][account].onPool += toUnmatch.div(cTokenExchangeRate); // In cToken
            supplyBalanceInOf[_cTokenAddress][account].inP2P -= toUnmatch.div(p2pExchangeRate); // In p2pUnit
            _updateSupplierList(_cTokenAddress, account);
            emit SupplierUnmatched(account, _cTokenAddress, toUnmatch);
            (, account) = suppliersInP2P[_cTokenAddress].getMaximum();
        }
        // Supply on Comp
        _supplyERC20ToPool(_cTokenAddress, _amount - remainingToUnmatch);
    }

    /** @dev Finds borrowers on Comp that match the given `_amount` and move them in P2P.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _cTokenAddress The address of the market on which Morpho wants to move users.
     *  @param _amount The amount to match in underlying.
     *  @return remainingToMatch The amount remaining to match in underlying.
     */
    function _matchBorrowers(address _cTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToMatch)
    {
        ICErc20 cToken = ICErc20(_cTokenAddress);
        IERC20 underlyingToken = IERC20(cToken.underlying());
        remainingToMatch = _amount;
        uint256 p2pExchangeRate = marketsManagerForCompound.p2pUnitExchangeRate(_cTokenAddress);
        uint256 borrowIndex = cToken.borrowIndex();
        (, address account) = borrowersOnPool[_cTokenAddress].getMaximum();

        while (remainingToMatch > 0 && account != address(0)) {
            uint256 onPoolInUnderlying = borrowBalanceInOf[_cTokenAddress][account].onPool.mul(
                borrowIndex
            ); // In underlying
            uint256 toMatch;
            if (onPoolInUnderlying <= remainingToMatch) {
                toMatch = onPoolInUnderlying;
                borrowBalanceInOf[_cTokenAddress][account].onPool = 0;
            } else {
                toMatch = remainingToMatch;
                borrowBalanceInOf[_cTokenAddress][account].onPool -= toMatch.div(borrowIndex);
            }
            remainingToMatch -= toMatch;
            borrowBalanceInOf[_cTokenAddress][account].inP2P += toMatch.div(p2pExchangeRate);
            _updateBorrowerList(_cTokenAddress, account);
            emit BorrowerMatched(account, _cTokenAddress, toMatch);
            (, account) = borrowersOnPool[_cTokenAddress].getMaximum();
        }
        // Repay Comp
        uint256 toRepay = _amount - remainingToMatch;
        underlyingToken.safeApprove(_cTokenAddress, toRepay);
        require(cToken.repayBorrow(toRepay) == 0, "17");
    }

    /** @dev Finds borrowers in peer-to-peer that match the given `_amount` and move them to Comp.
     *  @dev Note: p2pUnitExchangeRate must have been updated before calling this function.
     *  @param _cTokenAddress The address of the market on which Morpho wants to move users.
     *  @param _amount The amount to match in underlying.
     *  @return remainingToUnmatch The amount remaining to munmatchatch in underlying.
     */
    function _unmatchBorrowers(address _cTokenAddress, uint256 _amount)
        internal
        returns (uint256 remainingToUnmatch)
    {
        ICErc20 cToken = ICErc20(_cTokenAddress);
        remainingToUnmatch = _amount;
        uint256 p2pExchangeRate = marketsManagerForCompound.p2pUnitExchangeRate(_cTokenAddress);
        uint256 borrowIndex = cToken.borrowIndex();
        (, address account) = borrowersInP2P[_cTokenAddress].getMaximum();

        while (remainingToUnmatch > 0 && account != address(0)) {
            uint256 inP2P = borrowBalanceInOf[_cTokenAddress][account].inP2P;
            uint256 toUnmatch = Math.min(inP2P.mul(p2pExchangeRate), remainingToUnmatch); // In underlying
            remainingToUnmatch -= toUnmatch;
            borrowBalanceInOf[_cTokenAddress][account].onPool += toUnmatch.div(borrowIndex);
            borrowBalanceInOf[_cTokenAddress][account].inP2P -= toUnmatch.div(p2pExchangeRate);
            _updateBorrowerList(_cTokenAddress, account);
            emit BorrowerUnmatched(account, _cTokenAddress, toUnmatch);
            (, account) = borrowersInP2P[_cTokenAddress].getMaximum();
        }
        // Borrow on Comp
        require(cToken.borrow(_amount - remainingToUnmatch) == 0);
    }

    /**
     * @dev Enters the user into the market if he is not already there.
     * @param _account The address of the account to update.
     * @param _cTokenAddress The address of the market to check.
     */
    function _handleMembership(address _cTokenAddress, address _account) internal {
        if (!accountMembership[_cTokenAddress][_account]) {
            accountMembership[_cTokenAddress][_account] = true;
            enteredMarkets[_account].push(_cTokenAddress);
        }
    }

    /** @dev Checks whether the user can borrow/withdraw or not.
     *  @param _account The user to determine liquidity for.
     *  @param _cTokenAddress The market to hypothetically withdraw/borrow in.
     *  @param _withdrawnAmount The number of tokens to hypothetically withdraw.
     *  @param _borrowedAmount The amount of underlying to hypothetically borrow.
     */
    function _checkAccountLiquidity(
        address _account,
        address _cTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) internal {
        (uint256 debtValue, uint256 maxDebtValue, ) = _getUserHypotheticalBalanceStates(
            _account,
            _cTokenAddress,
            _withdrawnAmount,
            _borrowedAmount
        );
        require(debtValue < maxDebtValue, "18");
    }

    /** @dev Returns the debt value, max debt value and collateral value of a given user.
     *  @param _account The user to determine liquidity for.
     *  @param _cTokenAddress The market to hypothetically withdraw/borrow in.
     *  @param _withdrawnAmount The number of tokens to hypothetically withdraw.
     *  @param _borrowedAmount The amount of underlying to hypothetically borrow.
     *  @return (debtValue, maxDebtValue collateralValue).
     */
    function _getUserHypotheticalBalanceStates(
        address _account,
        address _cTokenAddress,
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
        ICompoundOracle compoundOracle = ICompoundOracle(comptroller.oracle());

        for (uint256 i; i < enteredMarkets[_account].length; i++) {
            vars.cTokenEntered = enteredMarkets[_account][i];
            vars.p2pExchangeRate = marketsManagerForCompound.updateP2pUnitExchangeRate(
                vars.cTokenEntered
            );
            // Calculation of the current debt (in underlying)
            vars.debtToAdd =
                borrowBalanceInOf[vars.cTokenEntered][_account].onPool.mul(
                    ICErc20(vars.cTokenEntered).borrowIndex()
                ) +
                borrowBalanceInOf[vars.cTokenEntered][_account].inP2P.mul(vars.p2pExchangeRate);
            // Calculation of the current collateral (in underlying)
            vars.collateralToAdd =
                supplyBalanceInOf[vars.cTokenEntered][_account].onPool.mul(
                    ICErc20(vars.cTokenEntered).exchangeRateCurrent()
                ) +
                supplyBalanceInOf[vars.cTokenEntered][_account].inP2P.mul(vars.p2pExchangeRate);
            // Price recovery
            vars.underlyingPrice = compoundOracle.getUnderlyingPrice(vars.cTokenEntered);
            require(vars.underlyingPrice != 0, "19");

            if (_cTokenAddress == vars.cTokenEntered) {
                vars.debtToAdd += _borrowedAmount;
                vars.redeemedValue = _withdrawnAmount.mul(vars.underlyingPrice);
            }
            // Conversion of the collateral to dollars
            vars.collateralToAdd = vars.collateralToAdd.mul(vars.underlyingPrice);
            // Add the debt in this market to the global debt (in dollars)
            vars.debtValue += vars.debtToAdd.mul(vars.underlyingPrice);
            // Add the collateral value in this asset to the global collateral value (in dollars)
            vars.collateralValue += vars.collateralToAdd;
            (, uint256 collateralFactorMantissa, ) = comptroller.markets(vars.cTokenEntered);
            // Add the max debt value allowed by the collateral in this asset to the global max debt value (in dollars)
            vars.maxDebtValue += vars.collateralToAdd.mul(collateralFactorMantissa);
        }

        vars.collateralValue -= vars.redeemedValue;

        return (vars.debtValue, vars.maxDebtValue, vars.collateralValue);
    }

    /** @dev Updates borrowers tree with the new balances of a given account.
     *  @param _cTokenAddress The address of the market on which Morpho want to update the borrower lists.
     *  @param _account The address of the borrower to move.
     */
    function _updateBorrowerList(address _cTokenAddress, address _account) internal {
        (bool success, ) = address(updatePositions).delegatecall(
            abi.encodeWithSignature("updateBorrowerList(address,address)", _cTokenAddress, _account)
        );
        require(success, "");
    }

    /** @dev Updates suppliers tree with the new balances of a given account.
     *  @param _cTokenAddress The address of the market on which Morpho want to update the supplier lists.
     *  @param _account The address of the supplier to move.
     */
    function _updateSupplierList(address _cTokenAddress, address _account) internal {
        (bool success, ) = address(updatePositions).delegatecall(
            abi.encodeWithSignature("updateSupplierList(address,address)", _cTokenAddress, _account)
        );
        require(success, "");
    }
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

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity 0.8.7;

/**
 *  @title CompoundMath
 *  @dev library emulating in solidity 8+ the behavior of Compound's mulScalarTruncate and divScalarByExpTruncate functions.
 */
library CompoundMath {
    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / 1e18;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((1e18 * x * 1e18) / y) / 1e18;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

interface ICErc20 {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256); // The user's underlying balance, representing their assets in the protocol, is equal to the user's cToken balance multiplied by the Exchange Rate.

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function underlying() external view returns (address);
}

interface ICEth {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface IComptroller {
    function liquidationIncentiveMantissa() external returns (uint256);

    function closeFactorMantissa() external returns (uint256);

    function oracle() external returns (address);

    function markets(address)
        external
        returns (
            bool,
            uint256,
            bool
        );

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address,
        address,
        uint256,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function checkMembership(address, address) external view returns (bool);
}

interface IInterestRateModel {
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICToken {
    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

interface IMarketsManagerForCompound {
    function isCreated(address _marketAddress) external returns (bool);

    function p2pBPY(address _marketAddress) external returns (uint256);

    function collateralFactor(address _marketAddress) external returns (uint256);

    function liquidationIncentive(address _marketAddress) external returns (uint256);

    function p2pUnitExchangeRate(address _marketAddress) external returns (uint256);

    function lastUpdateBlockNumber(address _marketAddress) external returns (uint256);

    function threshold(address _marketAddress) external returns (uint256);

    function updateP2pUnitExchangeRate(address _marketAddress) external returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

interface IUpdatePositions {
    function updateBorrowerList(address _cTokenAddress, address _account) external;

    function updateSupplierList(address _cTokenAddress, address _account) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./libraries/RedBlackBinaryTree.sol";
import {IComptroller} from "./interfaces/compound/ICompound.sol";
import "./interfaces/IMarketsManagerForCompound.sol";
import "./interfaces/IUpdatePositions.sol";

/**
 *  @title MorphoPositionsManagerForComp.
 *  @dev Smart contract interacting with Comp to enable P2P supply/borrow positions that can fallback on Comp's pool using cToken tokens.
 */
contract PositionsManagerStorageForCompound {
    /* Structs */

    struct SupplyBalance {
        uint256 inP2P; // In p2pUnit, a unit that grows in value, to keep track of the interests/debt increase when users are in p2p.
        uint256 onPool; // In cToken.
    }

    struct BorrowBalance {
        uint256 inP2P; // In p2pUnit.
        uint256 onPool; // In cdUnit, a unit that grows in value, to keep track of the debt increase when users are in Comp. Multiply by current borrowIndex to get the underlying amount.
    }

    /* Storage */

    uint16 public NMAX = 1000;
    uint8 public constant CTOKEN_DECIMALS = 8;
    mapping(address => RedBlackBinaryTree.Tree) internal suppliersInP2P; // Suppliers in peer-to-peer.
    mapping(address => RedBlackBinaryTree.Tree) internal suppliersOnPool; // Suppliers on Comp.
    mapping(address => RedBlackBinaryTree.Tree) internal borrowersInP2P; // Borrowers in peer-to-peer.
    mapping(address => RedBlackBinaryTree.Tree) internal borrowersOnPool; // Borrowers on Comp.
    mapping(address => EnumerableSet.AddressSet) internal suppliersInP2PBuffer; // Buffer of suppliers in peer-to-peer.
    mapping(address => EnumerableSet.AddressSet) internal suppliersOnPoolBuffer; // Buffer of suppliers on Comp.
    mapping(address => EnumerableSet.AddressSet) internal borrowersInP2PBuffer; // Buffer of borrowers in peer-to-peer.
    mapping(address => EnumerableSet.AddressSet) internal borrowersOnPoolBuffer; // Buffer of borrowers on Comp.
    mapping(address => mapping(address => SupplyBalance)) public supplyBalanceInOf; // For a given market, the supply balance of user.
    mapping(address => mapping(address => BorrowBalance)) public borrowBalanceInOf; // For a given market, the borrow balance of user.
    mapping(address => mapping(address => bool)) public accountMembership; // Whether the account is in the market or not.
    mapping(address => address[]) public enteredMarkets; // Markets entered by a user.
    mapping(address => uint256) public threshold; // Thresholds below the ones suppliers and borrowers cannot enter markets.

    IUpdatePositions public updatePositions;
    IComptroller public comptroller;
    IMarketsManagerForCompound public marketsManagerForCompound;
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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

// SPDX-License-Identifier: BSD-2-Clause
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
        uint256 count; // The number of nodes in the tree.
        uint256 minimum; // The minimum value of the tree.
        address minimumKey; // The key related to the minimum value.
        uint256 maximum; // The maximum value of the tree.
        address maximumKey; // Key related to the maximum value.
        address root; // the ddress of the root node.
        mapping(address => Node) nodes; // Maps user's address to node.
        mapping(address => uint256) keyToValue; // Maps key to its value.
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

    /** @dev Returns the number of keys in the tree.
     *  @param _self The tree to search in.
     *  @return The number of keys.
     */
    function numberOfKeys(Tree storage _self) public view returns (uint256) {
        return _self.count;
    }

    /** @dev Returns the value related to the given the `_key`.
     *  @param _self The tree to search in.
     *  @param _key The key to search for.
     *  @return The value related to the given the `_key`. 0 if the key does not exist.
     */
    function getValueOfKey(Tree storage _self, address _key) public view returns (uint256) {
        return _self.keyToValue[_key];
    }

    /** @dev Returns the minimum value of the tree and the related address.
     *  @param _self The tree to search in.
     *  @return (The minimum of the tree, The address related to the minimum).
     */
    function getMinimum(Tree storage _self) public view returns (uint256, address) {
        return (_self.minimum, _self.minimumKey);
    }

    /** @dev Returns the maximum value of the tree and the related address.
     *  @param _self The tree to search in.
     *  @return (The minimum of the tree, The address related to the maximum).
     */
    function getMaximum(Tree storage _self) public view returns (uint256, address) {
        return (_self.maximum, _self.maximumKey);
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
        if (_self.minimum == 0 || compare(_self.minimum, _self.minimumKey, _value, _key)) {
            _self.minimumKey = _key;
            _self.minimum = _value;
        }
        if (_self.maximum == 0 || compare(_value, _key, _self.maximum, _self.maximumKey)) {
            _self.maximumKey = _key;
            _self.maximum = _value;
        }
        _self.count++;
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
        uint256 value = _self.keyToValue[_key];
        require(value != 0, "RBBT:account-not-exist");
        if (value == _self.minimum && _key == _self.minimumKey) {
            address newMinimumKey = next(_self, _key);
            _self.minimumKey = newMinimumKey;
            _self.minimum = _self.keyToValue[newMinimumKey];
        }
        if (value == _self.maximum && _key == _self.maximumKey) {
            address newMaximumKey = prev(_self, _key);
            _self.maximumKey = newMaximumKey;
            _self.maximum = _self.keyToValue[newMaximumKey];
        }
        _self.count--;
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
        address keyParent = _self.nodes[_key].parent;
        address cursorLeft = _self.nodes[cursor].leftChild;
        _self.nodes[_key].rightChild = cursorLeft;

        if (cursorLeft != address(0)) {
            _self.nodes[cursorLeft].parent = _key;
        }
        _self.nodes[cursor].parent = keyParent;
        if (keyParent == address(0)) {
            _self.root = cursor;
        } else if (_key == _self.nodes[keyParent].leftChild) {
            _self.nodes[keyParent].leftChild = cursor;
        } else {
            _self.nodes[keyParent].rightChild = cursor;
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
        address keyParent = _self.nodes[_key].parent;
        address cursorRight = _self.nodes[cursor].rightChild;
        _self.nodes[_key].leftChild = cursorRight;
        if (cursorRight != address(0)) {
            _self.nodes[cursorRight].parent = _key;
        }
        _self.nodes[cursor].parent = keyParent;
        if (keyParent == address(0)) {
            _self.root = cursor;
        } else if (_key == _self.nodes[keyParent].rightChild) {
            _self.nodes[keyParent].rightChild = cursor;
        } else {
            _self.nodes[keyParent].leftChild = cursor;
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
                    _key = _self.nodes[keyParent].parent;
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