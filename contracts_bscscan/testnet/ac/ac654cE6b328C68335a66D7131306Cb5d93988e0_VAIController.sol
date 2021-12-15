pragma solidity ^0.5.16;

import "./VToken.sol";
import "./PriceOracle.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./VAIControllerStorage.sol";
import "./VAIUnitroller.sol";
import "./VAI.sol";

interface ComptrollerImplInterface {
    function protocolPaused() external view returns (bool);
    function mintedVAIs(address account) external view returns (uint);
    function vaiMintRate() external view returns (uint);
    function venusVAIRate() external view returns (uint);
    function venusAccrued(address account) external view returns(uint);
    function getAssetsIn(address account) external view returns (VToken[] memory);
    function oracle() external view returns (PriceOracle);

    function distributeVAIMinterVenus(address vaiMinter) external;
}

/**
 * @title Venus's VAI Comptroller Contract
 * @author Venus
 */
contract VAIController is VAIControllerStorageG2, VAIControllerErrorReporter, Exponential {

    /// @notice Emitted when Comptroller is changed
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when VAI is minted
     */
    event MintVAI(address minter, uint mintVAIAmount);

    /**
     * @notice Event emitted when VAI is repaid
     */
    event RepayVAI(address payer, address borrower, uint repayVAIAmount);

    /// @notice The initial Venus index for a market
    uint224 public constant venusInitialIndex = 1e36;

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateVAI(address liquidator, address borrower, uint repayAmount, address vTokenCollateral, uint seizeTokens);

    /**
     * @notice Emitted when treasury guardian is changed
     */
    event NewTreasuryGuardian(address oldTreasuryGuardian, address newTreasuryGuardian);

    /**
     * @notice Emitted when treasury address is changed
     */
    event NewTreasuryAddress(address oldTreasuryAddress, address newTreasuryAddress);

    /**
     * @notice Emitted when treasury percent is changed
     */
    event NewTreasuryPercent(uint oldTreasuryPercent, uint newTreasuryPercent);

    /**
     * @notice Event emitted when VAIs are minted and fee are transferred
     */
    event MintFee(address minter, uint feeAmount);

    /*** Main Actions ***/
    struct MintLocalVars {
        Error err;
        MathError mathErr;
        uint mintAmount;
    }

    function mintVAI(uint mintVAIAmount) external nonReentrant returns (uint) {
        if(address(comptroller) != address(0)) {
            require(mintVAIAmount > 0, "mintVAIAmount cannt be zero");

            require(!ComptrollerImplInterface(address(comptroller)).protocolPaused(), "protocol is paused");

            MintLocalVars memory vars;

            address minter = msg.sender;

            // Keep the flywheel moving
            updateVenusVAIMintIndex();
            ComptrollerImplInterface(address(comptroller)).distributeVAIMinterVenus(minter);

            uint oErr;
            MathError mErr;
            uint accountMintVAINew;
            uint accountMintableVAI;

            (oErr, accountMintableVAI) = getMintableVAI(minter);
            if (oErr != uint(Error.NO_ERROR)) {
                return uint(Error.REJECTION);
            }

            // check that user have sufficient mintableVAI balance
            if (mintVAIAmount > accountMintableVAI) {
                return fail(Error.REJECTION, FailureInfo.VAI_MINT_REJECTION);
            }

            (mErr, accountMintVAINew) = addUInt(ComptrollerImplInterface(address(comptroller)).mintedVAIs(minter), mintVAIAmount);
            require(mErr == MathError.NO_ERROR, "VAI_MINT_AMOUNT_CALCULATION_FAILED");
            uint error = comptroller.setMintedVAIOf(minter, accountMintVAINew);
            if (error != 0 ) {
                return error;
            }

            uint feeAmount;
            uint remainedAmount;
            vars.mintAmount = mintVAIAmount;
            if (treasuryPercent != 0) {
                (vars.mathErr, feeAmount) = mulUInt(vars.mintAmount, treasuryPercent);
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.MINT_FEE_CALCULATION_FAILED, uint(vars.mathErr));
                }

                (vars.mathErr, feeAmount) = divUInt(feeAmount, 1e18);
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.MINT_FEE_CALCULATION_FAILED, uint(vars.mathErr));
                }

                (vars.mathErr, remainedAmount) = subUInt(vars.mintAmount, feeAmount);
                if (vars.mathErr != MathError.NO_ERROR) {
                    return failOpaque(Error.MATH_ERROR, FailureInfo.MINT_FEE_CALCULATION_FAILED, uint(vars.mathErr));
                }

                VAI(getVAIAddress()).mint(treasuryAddress, feeAmount);

                emit MintFee(minter, feeAmount);
            } else {
                remainedAmount = vars.mintAmount;
            }

            VAI(getVAIAddress()).mint(minter, remainedAmount);

            emit MintVAI(minter, remainedAmount);

            return uint(Error.NO_ERROR);
        }
    }

    /**
     * @notice Repay VAI
     */
    function repayVAI(uint repayVAIAmount) external nonReentrant returns (uint, uint) {
        if(address(comptroller) != address(0)) {
            require(repayVAIAmount > 0, "repayVAIAmount cannt be zero");

            require(!ComptrollerImplInterface(address(comptroller)).protocolPaused(), "protocol is paused");

            address payer = msg.sender;

            updateVenusVAIMintIndex();
            ComptrollerImplInterface(address(comptroller)).distributeVAIMinterVenus(payer);

            return repayVAIFresh(msg.sender, msg.sender, repayVAIAmount);
        }
    }

    /**
     * @notice Repay VAI Internal
     * @notice Borrowed VAIs are repaid by another user (possibly the borrower).
     * @param payer the account paying off the VAI
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of VAI being returned
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayVAIFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
        uint actualBurnAmount;

        uint vaiBalanceBorrower = ComptrollerImplInterface(address(comptroller)).mintedVAIs(borrower);

        if(vaiBalanceBorrower > repayAmount) {
            actualBurnAmount = repayAmount;
        } else {
            actualBurnAmount = vaiBalanceBorrower;
        }

        MathError mErr;
        uint accountVAINew;

        VAI(getVAIAddress()).burn(payer, actualBurnAmount);

        (mErr, accountVAINew) = subUInt(vaiBalanceBorrower, actualBurnAmount);
        require(mErr == MathError.NO_ERROR, "VAI_BURN_AMOUNT_CALCULATION_FAILED");

        uint error = comptroller.setMintedVAIOf(borrower, accountVAINew);
        if (error != 0) {
            return (error, 0);
        }
        emit RepayVAI(payer, borrower, actualBurnAmount);

        return (uint(Error.NO_ERROR), actualBurnAmount);
    }

    /**
     * @notice The sender liquidates the vai minters collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of vai to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateVAI(address borrower, uint repayAmount, VTokenInterface vTokenCollateral) external nonReentrant returns (uint, uint) {
        require(!ComptrollerImplInterface(address(comptroller)).protocolPaused(), "protocol is paused");

        uint error = vTokenCollateral.accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.VAI_LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
        }

        // liquidateVAIFresh emits borrow-specific logs on errors, so we don't need to
        return liquidateVAIFresh(msg.sender, borrower, repayAmount, vTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral by repay borrowers VAI.
     *  The collateral seized is transferred to the liquidator.
     * @param liquidator The address repaying the VAI and seizing collateral
     * @param borrower The borrower of this VAI to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the VAI to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment VAI.
     */
    function liquidateVAIFresh(address liquidator, address borrower, uint repayAmount, VTokenInterface vTokenCollateral) internal returns (uint, uint) {
        if(address(comptroller) != address(0)) {
            /* Fail if liquidate not allowed */
            uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(vTokenCollateral), liquidator, borrower, repayAmount);
            if (allowed != 0) {
                return (failOpaque(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
            }

            /* Verify vTokenCollateral market's block number equals current block number */
            //if (vTokenCollateral.accrualBlockNumber() != accrualBlockNumber) {
            if (vTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
            }

            /* Fail if borrower = liquidator */
            if (borrower == liquidator) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
            }

            /* Fail if repayAmount = 0 */
            if (repayAmount == 0) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
            }

            /* Fail if repayAmount = -1 */
            if (repayAmount == uint(-1)) {
                return (fail(Error.REJECTION, FailureInfo.VAI_LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
            }


            /* Fail if repayVAI fails */
            (uint repayBorrowError, uint actualRepayAmount) = repayVAIFresh(liquidator, borrower, repayAmount);
            if (repayBorrowError != uint(Error.NO_ERROR)) {
                return (fail(Error(repayBorrowError), FailureInfo.VAI_LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
            }

            /////////////////////////
            // EFFECTS & INTERACTIONS
            // (No safe failures beyond this point)

            /* We calculate the number of collateral tokens that will be seized */
            (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateVAICalculateSeizeTokens(address(vTokenCollateral), actualRepayAmount);
            require(amountSeizeError == uint(Error.NO_ERROR), "VAI_LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

            /* Revert if borrower collateral token balance < seizeTokens */
            require(vTokenCollateral.balanceOf(borrower) >= seizeTokens, "VAI_LIQUIDATE_SEIZE_TOO_MUCH");

            uint seizeError;
            seizeError = vTokenCollateral.seize(liquidator, borrower, seizeTokens);

            /* Revert if seize tokens fails (since we cannot be sure of side effects) */
            require(seizeError == uint(Error.NO_ERROR), "token seizure failed");

            /* We emit a LiquidateBorrow event */
            emit LiquidateVAI(liquidator, borrower, actualRepayAmount, address(vTokenCollateral), seizeTokens);

            /* We call the defense hook */
            comptroller.liquidateBorrowVerify(address(this), address(vTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

            return (uint(Error.NO_ERROR), actualRepayAmount);
        }
    }

    /**
     * @notice Initialize the VenusVAIState
     */
    function _initializeVenusVAIState(uint blockNumber) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COMPTROLLER_OWNER_CHECK);
        }

        if (isVenusVAIInitialized == false) {
            isVenusVAIInitialized = true;
            uint vaiBlockNumber = blockNumber == 0 ? getBlockNumber() : blockNumber;
            venusVAIState = VenusVAIState({
                index: venusInitialIndex,
                block: safe32(vaiBlockNumber, "block number overflows")
            });
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrue XVS to by updating the VAI minter index
     */
    function updateVenusVAIMintIndex() public returns (uint) {
        uint vaiMinterSpeed = ComptrollerImplInterface(address(comptroller)).venusVAIRate();
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(venusVAIState.block));
        if (deltaBlocks > 0 && vaiMinterSpeed > 0) {
            uint vaiAmount = VAI(getVAIAddress()).totalSupply();
            uint venusAccrued = mul_(deltaBlocks, vaiMinterSpeed);
            Double memory ratio = vaiAmount > 0 ? fraction(venusAccrued, vaiAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: venusVAIState.index}), ratio);
            venusVAIState = VenusVAIState({
                index: safe224(index.mantissa, "new index overflows"),
                block: safe32(blockNumber, "block number overflows")
            });
        } else if (deltaBlocks > 0) {
            venusVAIState.block = safe32(blockNumber, "block number overflows");
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Calculate XVS accrued by a VAI minter
     * @param vaiMinter The address of the VAI minter to distribute XVS to
     */
    function calcDistributeVAIMinterVenus(address vaiMinter) public returns(uint, uint, uint, uint) {
        // Check caller is comptroller
        if (msg.sender != address(comptroller)) {
            return (fail(Error.UNAUTHORIZED, FailureInfo.SET_COMPTROLLER_OWNER_CHECK), 0, 0, 0);
        }

        Double memory vaiMintIndex = Double({mantissa: venusVAIState.index});
        Double memory vaiMinterIndex = Double({mantissa: venusVAIMinterIndex[vaiMinter]});
        venusVAIMinterIndex[vaiMinter] = vaiMintIndex.mantissa;

        if (vaiMinterIndex.mantissa == 0 && vaiMintIndex.mantissa > 0) {
            vaiMinterIndex.mantissa = venusInitialIndex;
        }

        Double memory deltaIndex = sub_(vaiMintIndex, vaiMinterIndex);
        uint vaiMinterAmount = ComptrollerImplInterface(address(comptroller)).mintedVAIs(vaiMinter);
        uint vaiMinterDelta = mul_(vaiMinterAmount, deltaIndex);
        uint vaiMinterAccrued = add_(ComptrollerImplInterface(address(comptroller)).venusAccrued(vaiMinter), vaiMinterDelta);
        return (uint(Error.NO_ERROR), vaiMinterAccrued, vaiMinterDelta, vaiMintIndex.mantissa);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new comptroller
      * @dev Admin function to set a new comptroller
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setComptroller(ComptrollerInterface comptroller_) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COMPTROLLER_OWNER_CHECK);
        }

        ComptrollerInterface oldComptroller = comptroller;
        comptroller = comptroller_;
        emit NewComptroller(oldComptroller, comptroller_);

        return uint(Error.NO_ERROR);
    }

    function _become(VAIUnitroller unitroller) external {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        require(unitroller._acceptImplementation() == 0, "change not authorized");
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account total supply balance.
     *  Note that `vTokenBalance` is the number of vTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountAmountLocalVars {
        uint totalSupplyAmount;
        uint sumSupply;
        uint sumBorrowPlusEffects;
        uint vTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    function getMintableVAI(address minter) public view returns (uint, uint) {
        PriceOracle oracle = ComptrollerImplInterface(address(comptroller)).oracle();
        VToken[] memory enteredMarkets = ComptrollerImplInterface(address(comptroller)).getAssetsIn(minter);

        AccountAmountLocalVars memory vars; // Holds all our calculation results

        uint oErr;
        MathError mErr;

        uint accountMintableVAI;
        uint i;

        /**
         * We use this formula to calculate mintable VAI amount.
         * totalSupplyAmount * VAIMintRate - (totalBorrowAmount + mintedVAIOf)
         */
        for (i = 0; i < enteredMarkets.length; i++) {
            (oErr, vars.vTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = enteredMarkets[i].getAccountSnapshot(minter);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (uint(Error.SNAPSHOT_ERROR), 0);
            }
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(enteredMarkets[i]);
            if (vars.oraclePriceMantissa == 0) {
                return (uint(Error.PRICE_ERROR), 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            (mErr, vars.tokensToDenom) = mulExp(vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR), 0);
            }

            // sumSupply += tokensToDenom * vTokenBalance
            (mErr, vars.sumSupply) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.vTokenBalance, vars.sumSupply);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR), 0);
            }

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.MATH_ERROR), 0);
            }
        }

        (mErr, vars.sumBorrowPlusEffects) = addUInt(vars.sumBorrowPlusEffects, ComptrollerImplInterface(address(comptroller)).mintedVAIs(minter));
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mErr, accountMintableVAI) = mulUInt(vars.sumSupply, ComptrollerImplInterface(address(comptroller)).vaiMintRate());
        require(mErr == MathError.NO_ERROR, "VAI_MINT_AMOUNT_CALCULATION_FAILED");

        (mErr, accountMintableVAI) = divUInt(accountMintableVAI, 10000);
        require(mErr == MathError.NO_ERROR, "VAI_MINT_AMOUNT_CALCULATION_FAILED");


        (mErr, accountMintableVAI) = subUInt(accountMintableVAI, vars.sumBorrowPlusEffects);
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.REJECTION), 0);
        }

        return (uint(Error.NO_ERROR), accountMintableVAI);
    }

    function _setTreasuryData(address newTreasuryGuardian, address newTreasuryAddress, uint newTreasuryPercent) external returns (uint) {
        // Check caller is admin
        if (!(msg.sender == admin || msg.sender == treasuryGuardian)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_TREASURY_OWNER_CHECK);
        }

        require(newTreasuryPercent < 1e18, "treasury percent cap overflow");

        address oldTreasuryGuardian = treasuryGuardian;
        address oldTreasuryAddress = treasuryAddress;
        uint oldTreasuryPercent = treasuryPercent;

        treasuryGuardian = newTreasuryGuardian;
        treasuryAddress = newTreasuryAddress;
        treasuryPercent = newTreasuryPercent;

        emit NewTreasuryGuardian(oldTreasuryGuardian, newTreasuryGuardian);
        emit NewTreasuryAddress(oldTreasuryAddress, newTreasuryAddress);
        emit NewTreasuryPercent(oldTreasuryPercent, newTreasuryPercent);

        return uint(Error.NO_ERROR);
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the VAI token
     * @return The address of VAI
     */
    function getVAIAddress() public view returns (address) {
        return 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
    }

    function initialize() onlyAdmin public {
        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can");
        _;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}