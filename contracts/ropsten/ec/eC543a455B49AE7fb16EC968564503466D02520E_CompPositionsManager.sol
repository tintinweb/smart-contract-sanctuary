// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import "./libraries/RedBlackBinaryTree.sol";
import "./interfaces/ICompMarketsManager.sol";
import {ICErc20, IComptroller, ICompoundOracle} from "./interfaces/ICompound.sol";

/**
 *  @title CompPositionsManager
 *  @dev Smart contracts interacting with Compound to enable real P2P supply with cERC20 tokens as supply/borrow assets.
 */
contract CompPositionsManager is ReentrancyGuard {
    using RedBlackBinaryTree for RedBlackBinaryTree.Tree;
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;
    using Math for uint256;

    /* Structs */

    struct SupplyBalance {
        uint256 onMorpho; // In mUnit (a unit that grows in value, to keep track of the debt increase).
        uint256 onComp; // In cToken.
    }

    struct BorrowBalance {
        uint256 onMorpho; // In mUnit.
        uint256 onComp; // In cdUnit. (a unit that grows in value, to keep track of the  debt increase). Multiply by current borrowIndex to get the underlying amount.
    }

    // Struct to avoid stack too deep error
    struct StateBalance {
        uint256 debtValue; // The total debt value (in USD).
        uint256 maxDebtValue; // The maximum debt value available thanks to the collateral (in USD).
        uint256 collateralValue; // The collateral value (in USD).
        uint256 redeemedValue; // The redeemed value if any (in USD).
    }

    // Struct to avoid stack too deep error
    struct StateBalanceVars {
        uint256 toAddDebt;
        uint256 toAddCollateral;
        uint256 mExchangeRate;
        uint256 underlyingPrice;
        address cErc20Entered;
    }

    // Struct to avoid stack too deep error
    struct LiquidateVars {
        uint256 borrowBalance;
        uint256 priceCollateralMantissa;
        uint256 priceBorrowedMantissa;
        uint256 amountToSeize;
        uint256 onCompInUnderlying;
    }

    /* Storage */

    mapping(address => RedBlackBinaryTree.Tree) public suppliersOnMorpho; // Suppliers on Morpho.
    mapping(address => RedBlackBinaryTree.Tree) public suppliersOnComp; // Suppliers on Compound.
    mapping(address => RedBlackBinaryTree.Tree) public borrowersOnMorpho; // Borrowers on Morpho.
    mapping(address => RedBlackBinaryTree.Tree) public borrowersOnComp; // Borrowers on Compound.
    mapping(address => mapping(address => bool)) public accountMembership; // Whether the account is in the market or not.
    mapping(address => mapping(address => SupplyBalance)) public supplyBalanceInOf; // Supply balance of user.
    mapping(address => mapping(address => BorrowBalance)) public borrowBalanceInOf; // Borrow balance of user.
    mapping(address => address[]) public enteredMarkets; // Markets entered by a user.

    IComptroller public comptroller;
    ICompoundOracle public compoundOracle;
    ICompMarketsManager public compMarketsManager;

    /* Events */

    /** @dev Emitted when a deposit happens.
     *  @param _account The address of the depositor.
     *  @param _cErc20Address The address of the market where assets are deposited into.
     *  @param _amount The amount of assets.
     */
    event Deposited(address indexed _account, address indexed _cErc20Address, uint256 _amount);

    /** @dev Emitted when a redeem happens.
     *  @param _account The address of the redeemer.
     *  @param _cErc20Address The address of the market from where assets are redeemed.
     *  @param _amount The amount of assets.
     */
    event Redeemed(address indexed _account, address indexed _cErc20Address, uint256 _amount);

    /** @dev Emitted when a borrow happens.
     *  @param _account The address of the borrower.
     *  @param _cErc20Address The address of the market where assets are borrowed.
     *  @param _amount The amount of assets.
     */
    event Borrowed(address indexed _account, address indexed _cErc20Address, uint256 _amount);

    /** @dev Emitted when a deposit happens.
     *  @param _account The address of the depositor.
     *  @param _cErc20Address The address of the market where assets are deposited.
     *  @param _amount The amount of assets.
     */
    event Repaid(address indexed _account, address indexed _cErc20Address, uint256 _amount);

    /** @dev Emitted when a supplier position is moved from Morpho to Compound.
     *  @param _account The address of the supplier.
     *  @param _cErc20Address The address of the market.
     *  @param _amount The amount of assets.
     */
    event SupplierMovedFromMorphoToComp(
        address indexed _account,
        address indexed _cErc20Address,
        uint256 _amount
    );

    /** @dev Emitted when a supplier position is moved from Compound to Morpho.
     *  @param _account The address of the supplier.
     *  @param _cErc20Address The address of the market.
     *  @param _amount The amount of assets.
     */
    event SupplierMovedFromCompToMorpho(
        address indexed _account,
        address indexed _cErc20Address,
        uint256 _amount
    );

    /** @dev Emitted when a borrower position is moved from Morpho to Compound.
     *  @param _account The address of the borrower.
     *  @param _cErc20Address The address of the market.
     *  @param _amount The amount of assets.
     */
    event BorrowerMovedFromMorphoToComp(
        address indexed _account,
        address indexed _cErc20Address,
        uint256 _amount
    );

    /** @dev Emitted when a borrower position is moved from Compound to Morpho.
     *  @param _account The address of the borrower.
     *  @param _cErc20Address The address of the market.
     *  @param _amount The amount of assets.
     */
    event BorrowerMovedFromCompToMorpho(
        address indexed _account,
        address indexed _cErc20Address,
        uint256 _amount
    );

    /* Modifiers */

    /** @dev Prevents a user to access a market not listed.
     *  @param _cErc20Address The address of the market.
     */
    modifier isMarketListed(address _cErc20Address) {
        require(compMarketsManager.isListed(_cErc20Address), "mkt-not-listed");
        _;
    }

    /** @dev Prevents a user to deposit or borrow less than threshold.
     *  @param _cErc20Address The address of the market.
     *  @param _amount The amount in ERC20 tokens.
     */
    modifier isAboveThreshold(address _cErc20Address, uint256 _amount) {
        require(_amount >= compMarketsManager.thresholds(_cErc20Address), "amount<threshold");
        _;
    }

    /* Constructor */

    constructor(ICompMarketsManager _compMarketsManager, address _proxyComptrollerAddress) {
        compMarketsManager = _compMarketsManager;
        comptroller = IComptroller(_proxyComptrollerAddress);
        compoundOracle = ICompoundOracle(comptroller.oracle());
    }

    /* External */

    /** @dev Enters Compound's markets.
     *  @param markets The address of the market the user wants to deposit.
     *  @return The results of entered.
     */
    function enterMarkets(address[] memory markets) external returns (uint256[] memory) {
        require(msg.sender == address(compMarketsManager), "enter-mkt:only-mkt-manager");
        return comptroller.enterMarkets(markets);
    }

    /** @dev Sets the comptroller and oracle address.
     *  @param _proxyComptrollerAddress The address of Compound's comptroller.
     */
    function setComptroller(address _proxyComptrollerAddress) external {
        require(msg.sender == address(compMarketsManager), "set-comp:only-mkt-manager");
        comptroller = IComptroller(_proxyComptrollerAddress);
        compoundOracle = ICompoundOracle(comptroller.oracle());
    }

    /** @dev Deposits ERC20 tokens in a specific market.
     *  @param _cErc20Address The address of the market the user wants to deposit.
     *  @param _amount The amount to deposit in ERC20 tokens.
     */
    function deposit(address _cErc20Address, uint256 _amount)
        external
        nonReentrant
        isMarketListed(_cErc20Address)
        isAboveThreshold(_cErc20Address, _amount)
    {
        _handleMembership(_cErc20Address, msg.sender);
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        IERC20 erc20Token = IERC20(cErc20Token.underlying());
        erc20Token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 cExchangeRate = cErc20Token.exchangeRateCurrent();

        // If some borrowers are on Compound, we must move them to Morpho
        if (borrowersOnComp[_cErc20Address].isKeyInTree()) {
            uint256 mExchangeRate = compMarketsManager.updateMUnitExchangeRate(_cErc20Address);
            // Find borrowers and move them to Morpho
            uint256 remainingToSupplyToComp = _moveBorrowersFromCompToMorpho(
                _cErc20Address,
                _amount
            ); // In underlying

            // Repay Compound
            uint256 toRepay = _amount - remainingToSupplyToComp;
            // Update supplier balance
            supplyBalanceInOf[_cErc20Address][msg.sender].onMorpho += toRepay.div(mExchangeRate); // In mUnit
            erc20Token.safeApprove(_cErc20Address, toRepay);
            cErc20Token.repayBorrow(toRepay);

            if (remainingToSupplyToComp > 0) {
                supplyBalanceInOf[_cErc20Address][msg.sender].onComp += remainingToSupplyToComp.div(
                    cExchangeRate
                ); // In cToken
                _supplyErc20ToComp(_cErc20Address, remainingToSupplyToComp); // Revert on error
            }
        } else {
            supplyBalanceInOf[_cErc20Address][msg.sender].onComp += _amount.div(cExchangeRate); // In cToken
            _supplyErc20ToComp(_cErc20Address, _amount); // Revert on error
        }

        _updateSupplierList(_cErc20Address, msg.sender);
        emit Deposited(msg.sender, _cErc20Address, _amount);
    }

    /** @dev Borrows ERC20 tokens.
     *  @param _cErc20Address The address of the markets the user wants to enter.
     *  @param _amount The amount to borrow in ERC20 tokens.
     */
    function borrow(address _cErc20Address, uint256 _amount)
        external
        nonReentrant
        isMarketListed(_cErc20Address)
        isAboveThreshold(_cErc20Address, _amount)
    {
        _handleMembership(_cErc20Address, msg.sender);
        _checkAccountLiquidity(msg.sender, _cErc20Address, 0, _amount);
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        IERC20 erc20Token = IERC20(cErc20Token.underlying());
        uint256 mExchangeRate = compMarketsManager.updateMUnitExchangeRate(_cErc20Address);

        // If some suppliers are on Compound, we must move them to Morpho
        if (suppliersOnComp[_cErc20Address].isKeyInTree()) {
            uint256 remainingToBorrowOnComp = _moveSuppliersFromCompToMorpho(
                _cErc20Address,
                _amount
            ); // In underlying
            uint256 toRedeem = _amount - remainingToBorrowOnComp;

            if (toRedeem > 0) {
                borrowBalanceInOf[_cErc20Address][msg.sender].onMorpho += toRedeem.div(
                    mExchangeRate
                ); // In mUnit
                _redeemErc20FromComp(_cErc20Address, toRedeem); // Revert on error
            }

            // If not enough cTokens on Morpho, we must borrow it on Compound
            if (remainingToBorrowOnComp > 0) {
                require(cErc20Token.borrow(remainingToBorrowOnComp) == 0, "bor:borrow-comp-fail");
                borrowBalanceInOf[_cErc20Address][msg.sender].onComp += remainingToBorrowOnComp.div(
                    cErc20Token.borrowIndex()
                ); // In cdUnit
            }
        } else {
            _moveSupplierFromMorphoToComp(msg.sender);
            require(cErc20Token.borrow(_amount) == 0, "bor:borrow-comp-fail");
            borrowBalanceInOf[_cErc20Address][msg.sender].onComp += _amount.div(
                cErc20Token.borrowIndex()
            ); // In cdUnit
        }

        _updateBorrowerList(_cErc20Address, msg.sender);
        // Transfer ERC20 tokens to borrower
        erc20Token.safeTransfer(msg.sender, _amount);
        emit Borrowed(msg.sender, _cErc20Address, _amount);
    }

    /** @dev Repays debt of the user.
     *  @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
     *  @param _cErc20Address The address of the market the user wants to interact with.
     *  @param _amount The amount in ERC20 tokens to repay.
     */
    function repay(address _cErc20Address, uint256 _amount) external nonReentrant {
        _repay(_cErc20Address, msg.sender, _amount);
    }

    /** @dev Redeems ERC20 tokens from supply.
     *  @param _cErc20Address The address of the market the user wants to interact with.
     *  @param _amount The amount in tokens to withdraw from supply.
     */
    function redeem(address _cErc20Address, uint256 _amount)
        external
        nonReentrant
        isMarketListed(_cErc20Address)
    {
        require(_amount > 0, "red:amount=0");
        _checkAccountLiquidity(msg.sender, _cErc20Address, _amount, 0);

        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        IERC20 erc20Token = IERC20(cErc20Token.underlying());

        uint256 mExchangeRate = compMarketsManager.updateMUnitExchangeRate(_cErc20Address);
        uint256 cExchangeRate = cErc20Token.exchangeRateCurrent();
        uint256 amountOnCompInUnderlying = supplyBalanceInOf[_cErc20Address][msg.sender].onComp.mul(
            cExchangeRate
        );

        if (_amount <= amountOnCompInUnderlying) {
            // Simple case where we can directly withdraw unused liquidity from Compound
            supplyBalanceInOf[_cErc20Address][msg.sender].onComp -= _amount.div(cExchangeRate); // In cToken
            _redeemErc20FromComp(_cErc20Address, _amount); // Revert on error
        } else {
            // First, we take all the unused liquidy on Compound.
            _redeemErc20FromComp(_cErc20Address, amountOnCompInUnderlying); // Revert on error
            supplyBalanceInOf[_cErc20Address][msg.sender].onComp -= amountOnCompInUnderlying.div(
                cExchangeRate
            );
            // Then, search for the remaining liquidity on Morpho
            uint256 remainingToWithdraw = _amount - amountOnCompInUnderlying; // In underlying
            supplyBalanceInOf[_cErc20Address][msg.sender].onMorpho -= remainingToWithdraw.div(
                mExchangeRate
            ); // In mUnit
            uint256 cTokenContractBalanceInUnderlying = cErc20Token.balanceOf(address(this)).mul(
                cExchangeRate
            );

            if (remainingToWithdraw <= cTokenContractBalanceInUnderlying) {
                // There is enough cTokens in the contract to use
                require(
                    _moveSuppliersFromCompToMorpho(_cErc20Address, remainingToWithdraw) == 0,
                    "red:remaining-suppliers!=0"
                );
                _redeemErc20FromComp(_cErc20Address, remainingToWithdraw); // Revert on error
            } else {
                // The contract does not have enough cTokens for the withdraw
                // First, we use all the available cTokens in the contract
                uint256 toRedeem = cTokenContractBalanceInUnderlying -
                    _moveSuppliersFromCompToMorpho(
                        _cErc20Address,
                        cTokenContractBalanceInUnderlying
                    ); // The amount that can be redeemed for underlying
                // Update the remaining amount to withdraw to `msg.sender`
                remainingToWithdraw -= toRedeem;
                _redeemErc20FromComp(_cErc20Address, toRedeem); // Revert on error
                // Then, we move borrowers not matched anymore from Morpho to Compound and borrow the amount directly on Compound
                require(
                    _moveBorrowersFromMorphoToComp(_cErc20Address, remainingToWithdraw) == 0,
                    "red:remaining-borrowers!=0"
                );
                require(cErc20Token.borrow(remainingToWithdraw) == 0, "red:borrow-comp-fail");
            }
        }

        _updateSupplierList(_cErc20Address, msg.sender);
        // Transfer back the ERC20 tokens
        erc20Token.safeTransfer(msg.sender, _amount);
        emit Redeemed(msg.sender, _cErc20Address, _amount);
    }

    /** @dev Allows someone to liquidate a position.
     *  @param _cErc20BorrowedAddress The address of the debt token the liquidator wants to repay.
     *  @param _cErc20CollateralAddress The address of the collateral the liquidator wants to seize.
     *  @param _borrower The address of the borrower to liquidate.
     *  @param _amount The amount to repay in ERC20 tokens.
     */
    function liquidate(
        address _cErc20BorrowedAddress,
        address _cErc20CollateralAddress,
        address _borrower,
        uint256 _amount
    ) external nonReentrant {
        (uint256 debtValue, uint256 maxDebtValue, ) = _getUserHypotheticalStateBalances(
            _borrower,
            address(0),
            0,
            0
        );
        require(maxDebtValue > debtValue, "liq:debt-value<=max");
        LiquidateVars memory vars;
        vars.borrowBalance =
            borrowBalanceInOf[_cErc20BorrowedAddress][_borrower].onComp.mul(
                ICErc20(_cErc20BorrowedAddress).borrowIndex()
            ) +
            borrowBalanceInOf[_cErc20BorrowedAddress][_borrower].onMorpho.mul(
                compMarketsManager.mUnitExchangeRate(_cErc20BorrowedAddress)
            );
        require(
            _amount <= vars.borrowBalance.mul(comptroller.closeFactorMantissa()),
            "liq:amount>allowed"
        );

        _repay(_cErc20BorrowedAddress, _borrower, _amount);

        // Calculate the amount of token to seize from collateral
        vars.priceCollateralMantissa = compoundOracle.getUnderlyingPrice(_cErc20CollateralAddress);
        vars.priceBorrowedMantissa = compoundOracle.getUnderlyingPrice(_cErc20BorrowedAddress);
        require(
            vars.priceCollateralMantissa != 0 && vars.priceBorrowedMantissa != 0,
            "liq:oracle-fail"
        );

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        ICErc20 cErc20CollateralToken = ICErc20(_cErc20CollateralAddress);
        IERC20 erc20CollateralToken = IERC20(cErc20CollateralToken.underlying());

        vars.amountToSeize = _amount
            .mul(vars.priceBorrowedMantissa)
            .mul(comptroller.liquidationIncentiveMantissa())
            .div(vars.priceCollateralMantissa);

        vars.onCompInUnderlying = supplyBalanceInOf[_cErc20CollateralAddress][_borrower].onComp.mul(
            cErc20CollateralToken.exchangeRateStored()
        );
        uint256 totalCollateral = vars.onCompInUnderlying +
            supplyBalanceInOf[_cErc20CollateralAddress][_borrower].onMorpho.mul(
                compMarketsManager.updateMUnitExchangeRate(_cErc20CollateralAddress)
            );

        require(vars.amountToSeize <= totalCollateral, "liq:toseize>collateral");

        if (vars.amountToSeize <= vars.onCompInUnderlying) {
            // Seize tokens from Compound
            supplyBalanceInOf[_cErc20CollateralAddress][_borrower].onComp -= vars.amountToSeize.div(
                cErc20CollateralToken.exchangeRateStored()
            );
            _redeemErc20FromComp(_cErc20CollateralAddress, vars.amountToSeize);
        } else {
            // Seize tokens from Morpho and Compound
            uint256 toMove = vars.amountToSeize - vars.onCompInUnderlying;
            supplyBalanceInOf[_cErc20CollateralAddress][_borrower].onMorpho -= toMove.div(
                compMarketsManager.mUnitExchangeRate(_cErc20CollateralAddress)
            );

            // Check balances before and after to avoid round errors issues
            uint256 balanceBefore = erc20CollateralToken.balanceOf(address(this));
            require(
                cErc20CollateralToken.redeem(
                    supplyBalanceInOf[_cErc20CollateralAddress][_borrower].onComp
                ) == 0,
                "liq:redeem-cToken-fail"
            );
            supplyBalanceInOf[_cErc20CollateralAddress][_borrower].onComp = 0;
            require(cErc20CollateralToken.borrow(toMove) == 0, "liq:borrow-comp-fail");
            uint256 balanceAfter = erc20CollateralToken.balanceOf(address(this));
            vars.amountToSeize = balanceAfter - balanceBefore;
            _moveBorrowersFromMorphoToComp(_cErc20CollateralAddress, toMove);
        }

        _updateSupplierList(_cErc20CollateralAddress, _borrower);
        // Transfer ERC20 tokens to liquidator
        erc20CollateralToken.safeTransfer(msg.sender, vars.amountToSeize);
    }

    /* Internal */

    /** @dev Implements repay logic.
     *  @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
     *  @param _cErc20Address The address of the market the user wants to interact with.
     *  @param _borrower The address of the `_borrower` to repay the borrow.
     *  @param _amount The amount of ERC20 tokens to repay.
     */
    function _repay(
        address _cErc20Address,
        address _borrower,
        uint256 _amount
    ) internal isMarketListed(_cErc20Address) {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        IERC20 erc20Token = IERC20(cErc20Token.underlying());
        erc20Token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 mExchangeRate = compMarketsManager.updateMUnitExchangeRate(_cErc20Address);

        if (borrowBalanceInOf[_cErc20Address][_borrower].onComp > 0) {
            uint256 onCompInUnderlying = borrowBalanceInOf[_cErc20Address][_borrower].onComp.mul(
                cErc20Token.borrowIndex()
            );

            if (_amount <= onCompInUnderlying) {
                borrowBalanceInOf[_cErc20Address][_borrower].onComp -= _amount.div(
                    cErc20Token.borrowIndex()
                ); // In cdUnit
                // Repay Compound
                erc20Token.safeApprove(_cErc20Address, _amount);
                cErc20Token.repayBorrow(_amount);
            } else {
                // Move the remaining liquidity to Compound
                uint256 remainingToSupplyToComp = _amount - onCompInUnderlying; // In underlying
                borrowBalanceInOf[_cErc20Address][_borrower].onMorpho -= remainingToSupplyToComp
                    .div(mExchangeRate);
                uint256 index = cErc20Token.borrowIndex();
                borrowBalanceInOf[_cErc20Address][_borrower].onComp -= onCompInUnderlying.div(
                    index
                ); // We use a fresh new borrowIndex since the borrowIndex is updated after a repay

                require(
                    _moveSuppliersFromMorphoToComp(_cErc20Address, remainingToSupplyToComp) == 0,
                    "_rep(1):remaining-suppliers!=0"
                );

                // Repay Compound
                erc20Token.safeApprove(_cErc20Address, onCompInUnderlying);
                cErc20Token.repayBorrow(onCompInUnderlying); // Revert on error

                if (remainingToSupplyToComp > 0)
                    _supplyErc20ToComp(_cErc20Address, remainingToSupplyToComp);
            }
        } else {
            borrowBalanceInOf[_cErc20Address][_borrower].onMorpho -= _amount.div(mExchangeRate); // In mUnit
            require(
                _moveSuppliersFromMorphoToComp(_cErc20Address, _amount) == 0,
                "_rep(2):remaining-suppliers!=0"
            );
            _supplyErc20ToComp(_cErc20Address, _amount);
        }

        _updateBorrowerList(_cErc20Address, _borrower);
        emit Repaid(_borrower, _cErc20Address, _amount);
    }

    /** @dev Supplies ERC20 tokens to Compound.
     *  @param _cErc20Address The address of the market the user wants to interact with.
     *  @param _amount The amount in ERC20 tokens to supply.
     */
    function _supplyErc20ToComp(address _cErc20Address, uint256 _amount) internal {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        IERC20 erc20Token = IERC20(cErc20Token.underlying());
        // Approve transfer on the ERC20 contract
        erc20Token.safeApprove(_cErc20Address, _amount);
        // Mint cTokens
        require(cErc20Token.mint(_amount) == 0, "_supp-to-comp:cToken-mint-fail");
    }

    /** @dev Redeems ERC20 tokens from Compound.
     *  @param _cErc20Address The address of the market the user wants to interact with.
     *  @param _amount The amount of tokens to be redeemed.
     */
    function _redeemErc20FromComp(address _cErc20Address, uint256 _amount) internal {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        require(cErc20Token.redeemUnderlying(_amount) == 0, "_redeem-from-comp:redeem-comp-fail");
    }

    /** @dev Finds liquidity on Compound and moves it to Morpho.
     *  @dev Note: mUnitExchangeRate must have been upated before calling this function.
     *  @param _cErc20Address The address of the market on which we want to move users.
     *  @param _amount The amount to search for in underlying.
     *  @return remainingToMove The remaining liquidity to search for in underlying.
     */
    function _moveSuppliersFromCompToMorpho(address _cErc20Address, uint256 _amount)
        internal
        returns (uint256 remainingToMove)
    {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        remainingToMove = _amount; // In underlying
        uint256 mExchangeRate = compMarketsManager.mUnitExchangeRate(_cErc20Address);
        uint256 cExchangeRate = cErc20Token.exchangeRateCurrent();
        uint256 highestValue = suppliersOnComp[_cErc20Address].last();

        while (remainingToMove > 0 && highestValue != 0) {
            while (suppliersOnComp[_cErc20Address].getNumberOfKeysAtValue(highestValue) > 0) {
                address account = suppliersOnComp[_cErc20Address].valueKeyAtIndex(highestValue, 0);
                uint256 onComp = supplyBalanceInOf[_cErc20Address][account].onComp; // In cToken

                if (onComp > 0) {
                    uint256 toMove;
                    if (onComp.mul(cExchangeRate) <= remainingToMove) {
                        supplyBalanceInOf[_cErc20Address][account].onComp = 0;
                        toMove = onComp.mul(cExchangeRate);
                    } else {
                        toMove = remainingToMove;
                        supplyBalanceInOf[_cErc20Address][account].onComp -= toMove.div(
                            cExchangeRate
                        ); // In cToken
                    }
                    remainingToMove -= toMove;
                    supplyBalanceInOf[_cErc20Address][account].onMorpho += toMove.div(
                        mExchangeRate
                    ); // In mUnit

                    _updateSupplierList(_cErc20Address, account);
                    emit SupplierMovedFromCompToMorpho(account, _cErc20Address, toMove);
                }
            }
            highestValue = suppliersOnComp[_cErc20Address].last();
        }
    }

    /** @dev Finds liquidity on Morpho and moves it to Compound.
     *  @dev Note: mUnitExchangeRate must have been upated before calling this function.
     *  @param _cErc20Address The address of the market on which we want to move users.
     *  @param _amount The amount to search for in underlying.
     */
    function _moveSuppliersFromMorphoToComp(address _cErc20Address, uint256 _amount)
        internal
        returns (uint256 remainingToMove)
    {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        remainingToMove = _amount; // In underlying
        uint256 cExchangeRate = cErc20Token.exchangeRateCurrent();
        uint256 mExchangeRate = compMarketsManager.mUnitExchangeRate(_cErc20Address);
        uint256 highestValue = suppliersOnMorpho[_cErc20Address].last();

        while (remainingToMove > 0 && highestValue != 0) {
            while (suppliersOnMorpho[_cErc20Address].getNumberOfKeysAtValue(highestValue) > 0) {
                address account = suppliersOnMorpho[_cErc20Address].valueKeyAtIndex(
                    highestValue,
                    0
                );
                uint256 onMorpho = supplyBalanceInOf[_cErc20Address][account].onMorpho; // In cToken

                if (onMorpho > 0) {
                    uint256 toMove = Math.min(onMorpho.mul(mExchangeRate), remainingToMove); // In underlying
                    remainingToMove -= toMove;
                    supplyBalanceInOf[_cErc20Address][account].onComp += toMove.div(cExchangeRate); // In cToken
                    supplyBalanceInOf[_cErc20Address][account].onMorpho -= toMove.div(
                        mExchangeRate
                    ); // In mUnit

                    _updateSupplierList(_cErc20Address, account);
                    emit SupplierMovedFromMorphoToComp(account, _cErc20Address, toMove);
                }
            }
            highestValue = suppliersOnMorpho[_cErc20Address].last();
        }
    }

    /** @dev Finds borrowers on Morpho that match the given `_amount` and moves them to Compound.
     *  @dev Note: mUnitExchangeRate must have been upated before calling this function.
     *  @param _cErc20Address The address of the market on which we want to move users.
     *  @param _amount The amount to match in underlying.
     *  @return remainingToMove The amount remaining to match in underlying.
     */
    function _moveBorrowersFromMorphoToComp(address _cErc20Address, uint256 _amount)
        internal
        returns (uint256 remainingToMove)
    {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        remainingToMove = _amount;
        uint256 mExchangeRate = compMarketsManager.mUnitExchangeRate(_cErc20Address);
        uint256 borrowIndex = cErc20Token.borrowIndex();
        uint256 highestValue = borrowersOnMorpho[_cErc20Address].last();

        while (remainingToMove > 0 && highestValue != 0) {
            while (borrowersOnMorpho[_cErc20Address].getNumberOfKeysAtValue(highestValue) > 0) {
                address account = borrowersOnMorpho[_cErc20Address].valueKeyAtIndex(
                    highestValue,
                    0
                );
                uint256 onMorpho = borrowBalanceInOf[_cErc20Address][account].onMorpho;

                if (onMorpho > 0) {
                    uint256 toMatch = Math.min(onMorpho.mul(mExchangeRate), remainingToMove); // In underlying
                    remainingToMove -= toMatch;
                    borrowBalanceInOf[_cErc20Address][account].onComp += toMatch.div(borrowIndex);
                    borrowBalanceInOf[_cErc20Address][account].onMorpho -= toMatch.div(
                        mExchangeRate
                    );

                    _updateBorrowerList(_cErc20Address, account);
                    emit BorrowerMovedFromMorphoToComp(account, _cErc20Address, toMatch);
                }
            }
            highestValue = borrowersOnMorpho[_cErc20Address].last();
        }
    }

    /** @dev Finds borrowers on Compound that match the given `_amount` and moves them to Morpho.
     *  @dev Note: mUnitExchangeRate must have been upated before calling this function.
     *  @param _cErc20Address The address of the market on which we want to move users.
     *  @param _amount The amount to match in underlying.
     *  @return remainingToMove The amount remaining to match in underlying.
     */
    function _moveBorrowersFromCompToMorpho(address _cErc20Address, uint256 _amount)
        internal
        returns (uint256 remainingToMove)
    {
        ICErc20 cErc20Token = ICErc20(_cErc20Address);
        remainingToMove = _amount;
        uint256 mExchangeRate = compMarketsManager.mUnitExchangeRate(_cErc20Address);
        uint256 borrowIndex = cErc20Token.borrowIndex();
        uint256 highestValue = borrowersOnComp[_cErc20Address].last();

        while (remainingToMove > 0 && highestValue != 0) {
            while (borrowersOnComp[_cErc20Address].getNumberOfKeysAtValue(highestValue) > 0) {
                address account = borrowersOnComp[_cErc20Address].valueKeyAtIndex(highestValue, 0);
                uint256 onComp = borrowBalanceInOf[_cErc20Address][account].onComp; // In cToken

                if (onComp > 0) {
                    uint256 toMatch;
                    if (onComp.mul(borrowIndex) <= remainingToMove) {
                        toMatch = onComp.mul(borrowIndex);
                        borrowBalanceInOf[_cErc20Address][account].onComp = 0;
                    } else {
                        toMatch = remainingToMove;
                        borrowBalanceInOf[_cErc20Address][account].onComp -= toMatch.div(
                            borrowIndex
                        );
                    }
                    remainingToMove -= toMatch;
                    borrowBalanceInOf[_cErc20Address][account].onMorpho += toMatch.div(
                        mExchangeRate
                    );

                    _updateBorrowerList(_cErc20Address, account);
                    emit BorrowerMovedFromCompToMorpho(account, _cErc20Address, toMatch);
                }
            }
            highestValue = borrowersOnComp[_cErc20Address].last();
        }
    }

    /**
     * @dev Moves supply balance of an account from Morpho to Compound.
     * @param _account The address of the account to move balance.
     */
    function _moveSupplierFromMorphoToComp(address _account) internal {
        for (uint256 i; i < enteredMarkets[_account].length; i++) {
            address cErc20Entered = enteredMarkets[_account][i];
            uint256 mExchangeRate = compMarketsManager.mUnitExchangeRate(cErc20Entered);
            uint256 cExchangeRate = ICErc20(cErc20Entered).exchangeRateCurrent();
            uint256 onMorphoInUnderlying = supplyBalanceInOf[cErc20Entered][_account].onMorpho.mul(
                mExchangeRate
            );

            if (onMorphoInUnderlying > 0) {
                supplyBalanceInOf[cErc20Entered][_account].onComp += onMorphoInUnderlying.div(
                    cExchangeRate
                ); // In cToken
                supplyBalanceInOf[cErc20Entered][_account].onMorpho -= onMorphoInUnderlying.div(
                    mExchangeRate
                ); // In mUnit

                _moveBorrowersFromMorphoToComp(cErc20Entered, onMorphoInUnderlying);
                _updateSupplierList(cErc20Entered, _account);
                emit SupplierMovedFromMorphoToComp(_account, cErc20Entered, onMorphoInUnderlying);
            }
        }
    }

    /**
     * @dev Updates the account membership.
     * @param _account The address of the account to update.
     * @param _cTokenAddress The address of the market to check.
     */
    function _handleMembership(address _cTokenAddress, address _account) internal {
        if (!accountMembership[_cTokenAddress][_account]) {
            accountMembership[_cTokenAddress][_account] = true;
            enteredMarkets[_account].push(_cTokenAddress);
        }
    }

    /** @dev Checks whether the user can borrow/redeem or not.
     *  @param _account The user to determine liquidity for.
     *  @param _cErc20Address The market to hypothetically redeem/borrow in.
     *  @param _redeemAmount The number of tokens to hypothetically redeem.
     *  @param _borrowedAmount The amount of underlying to hypothetically borrow.
     */
    function _checkAccountLiquidity(
        address _account,
        address _cErc20Address,
        uint256 _redeemAmount,
        uint256 _borrowedAmount
    ) internal {
        (uint256 debtValue, uint256 maxDebtValue, ) = _getUserHypotheticalStateBalances(
            _account,
            _cErc20Address,
            _redeemAmount,
            _borrowedAmount
        );
        require(debtValue < maxDebtValue, "debt-value>max");
    }

    /** @dev Returns the debt price, max debt price and collateral price of a given user.
     *  @param _account The user to determine liquidity for.
     *  @param _cErc20Address The market to hypothetically redeem/borrow in.
     *  @param _redeemAmount The number of tokens to hypothetically redeem.
     *  @param _borrowedAmount The amount of underlying to hypothetically borrow.
     *  @return (debtPrice, maxDebtPrice, collateralPrice).
     */
    function _getUserHypotheticalStateBalances(
        address _account,
        address _cErc20Address,
        uint256 _redeemAmount,
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
        StateBalance memory stateBalance;

        for (uint256 i; i < enteredMarkets[_account].length; i++) {
            // Avoid stack too deep error
            StateBalanceVars memory vars;
            vars.cErc20Entered = enteredMarkets[_account][i];
            vars.mExchangeRate = compMarketsManager.updateMUnitExchangeRate(vars.cErc20Entered);

            vars.toAddDebt =
                borrowBalanceInOf[vars.cErc20Entered][_account].onComp.mul(
                    ICErc20(vars.cErc20Entered).borrowIndex()
                ) +
                borrowBalanceInOf[vars.cErc20Entered][_account].onMorpho.mul(vars.mExchangeRate);
            vars.toAddCollateral =
                supplyBalanceInOf[vars.cErc20Entered][_account].onComp.mul(
                    ICErc20(vars.cErc20Entered).exchangeRateCurrent()
                ) +
                supplyBalanceInOf[vars.cErc20Entered][_account].onMorpho.mul(vars.mExchangeRate);

            vars.underlyingPrice = compoundOracle.getUnderlyingPrice(vars.cErc20Entered);
            if (_cErc20Address == vars.cErc20Entered) {
                vars.toAddDebt += _borrowedAmount;
                stateBalance.redeemedValue = _redeemAmount.mul(vars.underlyingPrice);
            }

            vars.toAddCollateral = vars.toAddCollateral.mul(vars.underlyingPrice);

            stateBalance.debtValue += vars.toAddDebt.mul(vars.underlyingPrice);
            stateBalance.collateralValue += vars.toAddCollateral;
            (, uint256 collateralFactorMantissa, ) = comptroller.markets(vars.cErc20Entered);
            stateBalance.maxDebtValue += vars.toAddCollateral.mul(collateralFactorMantissa);
        }

        stateBalance.collateralValue -= stateBalance.redeemedValue;

        return (stateBalance.debtValue, stateBalance.maxDebtValue, stateBalance.collateralValue);
    }

    /** @dev Updates borrower lists.
     *  @param _cErc20Address The address of the market on which we want to update the borrower lists.
     *  @param _account The address of the borrower to move.
     */
    function _updateBorrowerList(address _cErc20Address, address _account) internal {
        if (borrowersOnComp[_cErc20Address].keyExists(_account))
            borrowersOnComp[_cErc20Address].remove(_account);
        if (borrowersOnMorpho[_cErc20Address].keyExists(_account))
            borrowersOnMorpho[_cErc20Address].remove(_account);
        if (borrowBalanceInOf[_cErc20Address][_account].onComp > 0) {
            borrowersOnComp[_cErc20Address].insert(
                _account,
                borrowBalanceInOf[_cErc20Address][_account].onComp
            );
        }
        if (borrowBalanceInOf[_cErc20Address][_account].onMorpho > 0) {
            borrowersOnMorpho[_cErc20Address].insert(
                _account,
                borrowBalanceInOf[_cErc20Address][_account].onMorpho
            );
        }
    }

    /** @dev Updates supplier lists.
     *  @param _cErc20Address The address of the market on which we want to update the supplier lists.
     *  @param _account The address of the supplier to move.
     */
    function _updateSupplierList(address _cErc20Address, address _account) internal {
        if (suppliersOnComp[_cErc20Address].keyExists(_account))
            suppliersOnComp[_cErc20Address].remove(_account);
        if (suppliersOnMorpho[_cErc20Address].keyExists(_account))
            suppliersOnMorpho[_cErc20Address].remove(_account);
        if (supplyBalanceInOf[_cErc20Address][_account].onComp > 0) {
            suppliersOnComp[_cErc20Address].insert(
                _account,
                supplyBalanceInOf[_cErc20Address][_account].onComp
            );
        }
        if (supplyBalanceInOf[_cErc20Address][_account].onMorpho > 0) {
            suppliersOnMorpho[_cErc20Address].insert(
                _account,
                supplyBalanceInOf[_cErc20Address][_account].onMorpho
            );
        }
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

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
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
        uint256 parent;
        uint256 left;
        uint256 right;
        bool red;
        address[] keys;
        mapping(address => uint256) keyMap;
    }

    struct Tree {
        uint256 root;
        mapping(uint256 => Node) nodes;
        mapping(address => uint256) keyToValue;
    }

    /** @dev Returns the smallest value in the tree `_self`.
     *  @param _self The tree to search in.
     */
    function first(Tree storage _self) public view returns (uint256 value) {
        value = _self.root;
        if (value == 0) return 0;
        while (_self.nodes[value].left != 0) {
            value = _self.nodes[value].left;
        }
    }

    /** @dev Returns the highest value in the tree `_self`.
     *  @param _self The tree to search in.
     */
    function last(Tree storage _self) public view returns (uint256 value) {
        value = _self.root;
        if (value == 0) return 0;
        while (_self.nodes[value].right != 0) {
            value = _self.nodes[value].right;
        }
    }

    /** @dev Returns the next value below `_value`.
     *  @param _self The tree to search in.
     *  @param _value The value to search after.
     */
    function next(Tree storage _self, uint256 _value) public view returns (uint256 cursor) {
        require(_value != 0, "RBBT(401):start-_value=0");
        if (_self.nodes[_value].right != 0) {
            cursor = treeMinimum(_self, _self.nodes[_value].right);
        } else {
            cursor = _self.nodes[_value].parent;
            while (cursor != 0 && _value == _self.nodes[cursor].right) {
                _value = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    /** @dev Returns the previous value above `_value`.
     *  @param _self The tree to search in.
     *  @param _value The value to search before.
     */
    function prev(Tree storage _self, uint256 _value) public view returns (uint256 cursor) {
        require(_value != 0, "RBBT(402):start-_value=0");
        if (_self.nodes[_value].left != 0) {
            cursor = treeMaximum(_self, _self.nodes[_value].left);
        } else {
            cursor = _self.nodes[_value].parent;
            while (cursor != 0 && _value == _self.nodes[cursor].left) {
                _value = cursor;
                cursor = _self.nodes[cursor].parent;
            }
        }
    }

    /** @dev Returns whether the `_value` exists in the tree or not.
     *  @param _self The tree to search in.
     *  @param _value The value to search.
     *  @return Whether the `_value` exists in the tree or not.
     */
    function exists(Tree storage _self, uint256 _value) public view returns (bool) {
        if (_value == 0) return false;
        if (_value == _self.root) return true;
        if (_self.nodes[_value].parent != 0) return true;
        return false;
    }

    /** @dev Returns whether the `_key` exists in the tree or not.
     *  @param _self The tree to search in.
     *  @param _key The key to search.
     *  @return Whether the `_key` exists in the tree or not.
     */
    function keyExists(Tree storage _self, address _key) public view returns (bool) {
        return _self.keyToValue[_key] != 0;
    }

    /** @dev Returns the `_key` that has the given `_value` at the specified `_index`.
     *  @param _self The tree to search in.
     *  @param _value The value to search.
     *  @param _index The index in the list of keys.
     *  @return The key address.
     */
    function valueKeyAtIndex(
        Tree storage _self,
        uint256 _value,
        uint256 _index
    ) public view returns (address) {
        require(exists(_self, _value), "RBBT(404):value-not-exist");
        return _self.nodes[_value].keys[_index];
    }

    /** @dev Returns the number of keys in a given node.
     *  @param _self The tree to search in.
     *  @param _value The value of the node to search for.
     *  @return The number of keys in this node.
     */
    function getNumberOfKeysAtValue(Tree storage _self, uint256 _value)
        public
        view
        returns (uint256)
    {
        if (!exists(_self, _value)) return 0;
        return _self.nodes[_value].keys.length;
    }

    /** @dev Returns whether or not there is any key in the tree.
     *  @param _self The tree to search in.
     *  @return Whether or not a key exist in the tree.
     */
    function isKeyInTree(Tree storage _self) public view returns (bool) {
        return _self.nodes[_self.root].keys.length > 0;
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
        require(_value != 0, "RBBT(405):value-cannot-be-0");
        require(_self.keyToValue[_key] == 0, "RBBT:account-already-in");
        _self.keyToValue[_key] = _value;
        uint256 cursor;
        uint256 probe = _self.root;
        while (probe != 0) {
            cursor = probe;
            if (_value < probe) {
                probe = _self.nodes[probe].left;
            } else if (_value > probe) {
                probe = _self.nodes[probe].right;
            } else if (_value == probe) {
                _self.nodes[probe].keys.push(_key);
                _self.nodes[probe].keyMap[_key] = _self.nodes[probe].keys.length - 1;
                return;
            }
        }
        Node storage nValue = _self.nodes[_value];
        nValue.parent = cursor;
        nValue.left = 0;
        nValue.right = 0;
        nValue.red = true;
        nValue.keys.push(_key);
        nValue.keyMap[_key] = nValue.keys.length - 1;
        if (cursor == 0) {
            _self.root = _value;
        } else if (_value < cursor) {
            _self.nodes[cursor].left = _value;
        } else {
            _self.nodes[cursor].right = _value;
        }
        insertFixup(_self, _value);
    }

    /** @dev Removes the `_key` in the tree and its related value if no-one shares the same value.
     *  @param _self The tree in which to remove the (key, value) pair.
     *  @param _key The key to remove.
     */
    function remove(Tree storage _self, address _key) public {
        require(_self.keyToValue[_key] != 0, "RBBT:account-not-exist");
        uint256 value = _self.keyToValue[_key];
        _self.keyToValue[_key] = 0;
        Node storage nValue = _self.nodes[value];
        uint256 rowToDelete = nValue.keyMap[_key];
        nValue.keys[rowToDelete] = nValue.keys[nValue.keys.length - 1];
        nValue.keys.pop();
        uint256 probe;
        uint256 cursor;
        if (nValue.keys.length == 0) {
            if (_self.nodes[value].left == 0 || _self.nodes[value].right == 0) {
                cursor = value;
            } else {
                cursor = _self.nodes[value].right;
                while (_self.nodes[cursor].left != 0) {
                    cursor = _self.nodes[cursor].left;
                }
            }
            if (_self.nodes[cursor].left != 0) {
                probe = _self.nodes[cursor].left;
            } else {
                probe = _self.nodes[cursor].right;
            }
            uint256 cursorParent = _self.nodes[cursor].parent;
            _self.nodes[probe].parent = cursorParent;
            if (cursorParent != 0) {
                if (cursor == _self.nodes[cursorParent].left) {
                    _self.nodes[cursorParent].left = probe;
                } else {
                    _self.nodes[cursorParent].right = probe;
                }
            } else {
                _self.root = probe;
            }
            bool doFixup = !_self.nodes[cursor].red;
            if (cursor != value) {
                replaceParent(_self, cursor, value);
                _self.nodes[cursor].left = _self.nodes[value].left;
                _self.nodes[_self.nodes[cursor].left].parent = cursor;
                _self.nodes[cursor].right = _self.nodes[value].right;
                _self.nodes[_self.nodes[cursor].right].parent = cursor;
                _self.nodes[cursor].red = _self.nodes[value].red;
                (cursor, value) = (value, cursor);
            }
            if (doFixup) {
                removeFixup(_self, probe);
            }
            delete _self.nodes[cursor];
        }
    }

    /** @dev Returns the minimum of the subtree beginning at a given node.
     *  @param _self The tree to search in.
     *  @param _value The value of the node to start at.
     */
    function treeMinimum(Tree storage _self, uint256 _value) private view returns (uint256) {
        while (_self.nodes[_value].left != 0) {
            _value = _self.nodes[_value].left;
        }
        return _value;
    }

    /** @dev Returns the maximum of the subtree beginning at a given node.
     *  @param _self The tree to search in.
     *  @param _value The value of the node to start at.
     */
    function treeMaximum(Tree storage _self, uint256 _value) private view returns (uint256) {
        while (_self.nodes[_value].right != 0) {
            _value = _self.nodes[_value].right;
        }
        return _value;
    }

    /** @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's right child), C (B's left child).
             After left rotation: B (Root), A (B's left child), C (B's right child)
     *  @param _self The tree to apply the rotation to.
     *  @param _value The value of the node to rotate.
     */
    function rotateLeft(Tree storage _self, uint256 _value) private {
        uint256 cursor = _self.nodes[_value].right;
        uint256 parent = _self.nodes[_value].parent;
        uint256 cursorLeft = _self.nodes[cursor].left;
        _self.nodes[_value].right = cursorLeft;
        if (cursorLeft != 0) {
            _self.nodes[cursorLeft].parent = _value;
        }
        _self.nodes[cursor].parent = parent;
        if (parent == 0) {
            _self.root = cursor;
        } else if (_value == _self.nodes[parent].left) {
            _self.nodes[parent].left = cursor;
        } else {
            _self.nodes[parent].right = cursor;
        }
        _self.nodes[cursor].left = _value;
        _self.nodes[_value].parent = cursor;
    }

    /** @dev Rotates the tree to keep the balance. Let's have three node, A (root), B (A's left child), C (B's right child).
             After right rotation: B (Root), A (B's right child), C (B's left child)
     *  @param _self The tree to apply the rotation to.
     *  @param _value The value of the node to rotate.
     */
    function rotateRight(Tree storage _self, uint256 _value) private {
        uint256 cursor = _self.nodes[_value].left;
        uint256 parent = _self.nodes[_value].parent;
        uint256 cursorRight = _self.nodes[cursor].right;
        _self.nodes[_value].left = cursorRight;
        if (cursorRight != 0) {
            _self.nodes[cursorRight].parent = _value;
        }
        _self.nodes[cursor].parent = parent;
        if (parent == 0) {
            _self.root = cursor;
        } else if (_value == _self.nodes[parent].right) {
            _self.nodes[parent].right = cursor;
        } else {
            _self.nodes[parent].left = cursor;
        }
        _self.nodes[cursor].right = _value;
        _self.nodes[_value].parent = cursor;
    }

    /** @dev Makes sure there is no violation of the tree properties after an insertion.
     *  @param _self The tree to check and correct if needed.
     *  @param _value The value that was inserted.
     */
    function insertFixup(Tree storage _self, uint256 _value) private {
        uint256 cursor;
        while (_value != _self.root && _self.nodes[_self.nodes[_value].parent].red) {
            uint256 valueParent = _self.nodes[_value].parent;
            if (valueParent == _self.nodes[_self.nodes[valueParent].parent].left) {
                cursor = _self.nodes[_self.nodes[valueParent].parent].right;
                if (_self.nodes[cursor].red) {
                    _self.nodes[valueParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    _value = _self.nodes[valueParent].parent;
                } else {
                    if (_value == _self.nodes[valueParent].right) {
                        _value = valueParent;
                        rotateLeft(_self, _value);
                    }
                    valueParent = _self.nodes[_value].parent;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    rotateRight(_self, _self.nodes[valueParent].parent);
                }
            } else {
                cursor = _self.nodes[_self.nodes[valueParent].parent].left;
                if (_self.nodes[cursor].red) {
                    _self.nodes[valueParent].red = false;
                    _self.nodes[cursor].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    _value = _self.nodes[valueParent].parent;
                } else {
                    if (_value == _self.nodes[valueParent].left) {
                        _value = valueParent;
                        rotateRight(_self, _value);
                    }
                    valueParent = _self.nodes[_value].parent;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[valueParent].parent].red = true;
                    rotateLeft(_self, _self.nodes[valueParent].parent);
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
        uint256 _a,
        uint256 _b
    ) private {
        uint256 bParent = _self.nodes[_b].parent;
        _self.nodes[_a].parent = bParent;
        if (bParent == 0) {
            _self.root = _a;
        } else {
            if (_b == _self.nodes[bParent].left) {
                _self.nodes[bParent].left = _a;
            } else {
                _self.nodes[bParent].right = _a;
            }
        }
    }

    /** @dev Makes sure there is no violation of the tree properties after removal.
     *  @param _self The tree to check and correct if needed.
     *  @param _value The probe value of the function remove.
     */
    function removeFixup(Tree storage _self, uint256 _value) private {
        uint256 cursor;
        while (_value != _self.root && !_self.nodes[_value].red) {
            uint256 valueParent = _self.nodes[_value].parent;
            if (_value == _self.nodes[valueParent].left) {
                cursor = _self.nodes[valueParent].right;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[valueParent].red = true;
                    rotateLeft(_self, valueParent);
                    cursor = _self.nodes[valueParent].right;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].left].red &&
                    !_self.nodes[_self.nodes[cursor].right].red
                ) {
                    _self.nodes[cursor].red = true;
                    _value = valueParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].right].red) {
                        _self.nodes[_self.nodes[cursor].left].red = false;
                        _self.nodes[cursor].red = true;
                        rotateRight(_self, cursor);
                        cursor = _self.nodes[valueParent].right;
                    }
                    _self.nodes[cursor].red = _self.nodes[valueParent].red;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[cursor].right].red = false;
                    rotateLeft(_self, valueParent);
                    _value = _self.root;
                }
            } else {
                cursor = _self.nodes[valueParent].left;
                if (_self.nodes[cursor].red) {
                    _self.nodes[cursor].red = false;
                    _self.nodes[valueParent].red = true;
                    rotateRight(_self, valueParent);
                    cursor = _self.nodes[valueParent].left;
                }
                if (
                    !_self.nodes[_self.nodes[cursor].right].red &&
                    !_self.nodes[_self.nodes[cursor].left].red
                ) {
                    _self.nodes[cursor].red = true;
                    _value = valueParent;
                } else {
                    if (!_self.nodes[_self.nodes[cursor].left].red) {
                        _self.nodes[_self.nodes[cursor].right].red = false;
                        _self.nodes[cursor].red = true;
                        rotateLeft(_self, cursor);
                        cursor = _self.nodes[valueParent].left;
                    }
                    _self.nodes[cursor].red = _self.nodes[valueParent].red;
                    _self.nodes[valueParent].red = false;
                    _self.nodes[_self.nodes[cursor].left].red = false;
                    rotateRight(_self, valueParent);
                    _value = _self.root;
                }
            }
        }
        _self.nodes[_value].red = false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface ICompMarketsManager {
    function isListed(address _marketAddress) external returns (bool);

    function p2pBPY(address _marketAddress) external returns (uint256);

    function collateralFactor(address _marketAddress) external returns (uint256);

    function liquidationIncentive(address _marketAddress) external returns (uint256);

    function mUnitExchangeRate(address _marketAddress) external returns (uint256);

    function lastUpdateBlockNumber(address _marketAddress) external returns (uint256);

    function thresholds(address _marketAddress) external returns (uint256);

    function updateMUnitExchangeRate(address _marketAddress) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
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

    function underlying() external returns (address);
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

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculting the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculting the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explictly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}