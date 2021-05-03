// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../ERC20/IERC20.sol';
import {IAnyswapV4Token} from '../ERC20/IAnyswapV4Token.sol';

/**
 * @title  ARTHShares.
 * @author MahaDAO.
 */
interface IARTHX is IERC20, IAnyswapV4Token {
    function setTaxPercent(uint256 percent) external;

    function setOwner(address _ownerAddress) external;

    function setOracle(address newOracle) external;

    function setArthController(address _controller) external;

    function setTimelock(address newTimelock) external;

    function setARTHAddress(address arthContractAddress) external;

    function poolMint(address account, uint256 amount) external;

    function poolBurnFrom(address account, uint256 amount) external;

    function setTaxDestination(address _taxDestination) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '../ERC20/IERC20.sol';
import {IIncentiveController} from './IIncentive.sol';
import {IAnyswapV4Token} from '../ERC20/IAnyswapV4Token.sol';

interface IARTH is IERC20, IAnyswapV4Token {
    function addPool(address pool) external;

    function removePool(address pool) external;

    function setGovernance(address _governance) external;

    function poolMint(address who, uint256 amount) external;

    function poolBurnFrom(address who, uint256 amount) external;

    function setIncentiveController(IIncentiveController _incentiveController)
        external;

    function genesisSupply() external view returns (uint256);

    function pools(address pool) external view returns (bool);

    function sendToPool(
        address sender,
        address poolAddress,
        uint256 amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address receiver,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IARTHController {
    function toggleCollateralRatio() external;

    function refreshCollateralRatio() external;

    function addPool(address pool_address) external;

    function removePool(address pool_address) external;

    function getARTHSupply() external view returns (uint256);

    function getARTHInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function setMintingFee(uint256 fee) external;

    function setARTHXETHOracle(
        address _arthxOracleAddress,
        address _wethAddress
    ) external;

    function setARTHETHOracle(address _arthOracleAddress, address _wethAddress)
        external;

    function setArthStep(uint256 newStep) external;

    function setRedemptionFee(uint256 fee) external;

    function setOwner(address _ownerAddress) external;

    function setPriceBand(uint256 _priceBand) external;

    function setTimelock(address newTimelock) external;

    function setPriceTarget(uint256 newPriceTarget) external;

    function setARTHXAddress(address _arthxAddress) external;

    function setRefreshCooldown(uint256 newCooldown) external;

    function setETHGMUOracle(address _ethGMUConsumerAddress) external;

    function setGlobalCollateralRatio(uint256 _globalCollateralRatio) external;

    function getRefreshCooldown() external view returns (uint256);

    function getARTHPrice() external view returns (uint256);

    function getARTHXPrice() external view returns (uint256);

    function getETHGMUPrice() external view returns (uint256);

    function getGlobalCollateralRatio() external view returns (uint256);

    function getGlobalCollateralValue() external view returns (uint256);

    function arthPools(address pool) external view returns (bool);

    function toggleUseGlobalCRForMint(bool flag) external;

    function toggleUseGlobalCRForRecollateralize(bool flag) external;

    function setMintCollateralRatio(uint256 val) external;

    function setRedeemCollateralRatio(uint256 val) external;

    function toggleUseGlobalCRForRedeem(bool flag) external;

    function setRecollateralizeCollateralRatio(uint256 val) external;

    function getCRForMint() external view returns (uint256);

    function getCRForRedeem() external view returns (uint256);

    function getCRForRecollateralize() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title incentive contract interface
/// @author Fei Protocol
/// @notice Called by FEI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentiveController {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of the FEI
    /// @param receiver the receiver address of the FEI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of FEI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IARTH} from '../IARTH.sol';
import {IARTHPool} from './IARTHPool.sol';
import {IERC20} from '../../ERC20/IERC20.sol';
import {IARTHX} from '../../ARTHX/IARTHX.sol';
import {IOracle} from '../../Oracle/IOracle.sol';
import {ICurve} from '../../Curves/ICurve.sol';
import {SafeMath} from '../../utils/math/SafeMath.sol';
import {ArthPoolLibrary} from './ArthPoolLibrary.sol';
import {IARTHController} from '../IARTHController.sol';
import {ISimpleOracle} from '../../Oracle/ISimpleOracle.sol';
import {IERC20Burnable} from '../../ERC20/IERC20Burnable.sol';
import {AccessControl} from '../../access/AccessControl.sol';
import {IUniswapPairOracle} from '../../Oracle/IUniswapPairOracle.sol';

/**
 * @title  ARTHPool.
 * @author MahaDAO.
 *
 *  Original code written by:
 *  - Travis Moore, Jason Huan, Same Kazemian, Sam Sun.
 */
contract ArthPool is AccessControl, IARTHPool {
    using SafeMath for uint256;

    /**
     * @dev Contract instances.
     */

    IARTH private _ARTH;
    IARTHX private _ARTHX;
    IERC20 private _COLLATERAL;
    IERC20Burnable private _MAHA;
    ISimpleOracle private _ARTHMAHAOracle;
    IARTHController private _arthController;
    IOracle private _collateralGMUOracle;
    ICurve private _recollateralizeDiscountCruve;
    IUniswapPairOracle private _collateralETHOracle;

    /// @dev Necessary for fetching prices.
    bool public override isWETHPool = false;

    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public buyBackPaused = false;
    bool public recollateralizePaused = false;
    bool public override collateralPricePaused = false;

    uint256 public override buybackFee;
    uint256 public override mintingFee;
    uint256 public override recollatFee;
    uint256 public override redemptionFee;
    uint256 public stabilityFee = 1; // In %.
    uint256 public buybackCollateralBuffer = 20; // In %.

    uint256 public override pausedPrice = 0; // Stores price of the collateral, if price is paused
    uint256 public poolCeiling = 0; // Total units of collateral that a pool contract can hold
    uint256 public redemptionDelay = 1; // Number of blocks to wait before being able to collect redemption.

    uint256 public unclaimedPoolARTHX;
    uint256 public unclaimedPoolCollateral;

    address public override collateralGMUOracleAddress;

    mapping(address => uint256) public lastRedeemed;
    mapping(address => uint256) public borrowedCollateral;
    mapping(address => uint256) public redeemARTHXBalances;
    mapping(address => uint256) public redeemCollateralBalances;

    bytes32 private constant _RECOLLATERALIZE_PAUSER =
        keccak256('RECOLLATERALIZE_PAUSER');
    bytes32 private constant _COLLATERAL_PRICE_PAUSER =
        keccak256('COLLATERAL_PRICE_PAUSER');
    bytes32 private constant _AMO_ROLE = keccak256('AMO_ROLE');
    bytes32 private constant _MINT_PAUSER = keccak256('MINT_PAUSER');
    bytes32 private constant _REDEEM_PAUSER = keccak256('REDEEM_PAUSER');
    bytes32 private constant _BUYBACK_PAUSER = keccak256('BUYBACK_PAUSER');

    uint256 private immutable _missingDeciamls;
    uint256 private constant _PRICE_PRECISION = 1e6;
    uint256 private constant _COLLATERAL_RATIO_MAX = 1e6;
    uint256 private constant _COLLATERAL_RATIO_PRECISION = 1e6;

    address private _wethAddress;
    address private _ownerAddress;
    address private _timelockAddress;
    address private _collateralAddress;
    address private _arthContractAddress;
    address private _arthxContractAddress;

    /**
     * Events.
     */
    event Repay(address indexed from, uint256 amount);
    event Borrow(address indexed from, uint256 amount);
    event StabilityFeesCharged(address indexed from, uint256 fee);

    /**
     * Modifiers.
     */
    modifier onlyByOwnerOrGovernance() {
        require(
            msg.sender == _timelockAddress || msg.sender == _ownerAddress,
            'ArthPool: You are not the owner or the governance timelock'
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'ArthPool: You are not the admin'
        );
        _;
    }

    modifier onlyAdminOrOwnerOrGovernance() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                msg.sender == _timelockAddress ||
                msg.sender == _ownerAddress,
            'ArthPool: forbidden'
        );
        _;
    }

    modifier onlyAMOS {
        require(hasRole(_AMO_ROLE, _msgSender()), 'ArthPool: forbidden');
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, 'ArthPool: Redeeming is paused');
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, 'ArthPool: Minting is paused');
        _;
    }

    /**
     * Constructor.
     */

    constructor(
        address __arthContractAddress,
        address __arthxContractAddress,
        address __collateralAddress,
        address _creatorAddress,
        address __timelockAddress,
        address __MAHA,
        address __ARTHMAHAOracle,
        address __arthController,
        uint256 _poolCeiling
    )
    // bool isWETHPool_  // Commented because need to add in migrations as well.
    {
        _MAHA = IERC20Burnable(__MAHA);
        _ARTH = IARTH(__arthContractAddress);
        _COLLATERAL = IERC20(__collateralAddress);
        _ARTHX = IARTHX(__arthxContractAddress);
        _ARTHMAHAOracle = ISimpleOracle(__ARTHMAHAOracle);
        _arthController = IARTHController(__arthController);

        _ownerAddress = _creatorAddress;
        _timelockAddress = __timelockAddress;
        _collateralAddress = __collateralAddress;
        _arthContractAddress = __arthContractAddress;
        _arthxContractAddress = __arthxContractAddress;

        poolCeiling = _poolCeiling;
        _missingDeciamls = uint256(18).sub(_COLLATERAL.decimals());

        // isWETHPool = isWETHPool_;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        grantRole(_MINT_PAUSER, _timelockAddress);
        grantRole(_REDEEM_PAUSER, _timelockAddress);
        grantRole(_BUYBACK_PAUSER, _timelockAddress);
        grantRole(_RECOLLATERALIZE_PAUSER, _timelockAddress);
        grantRole(_COLLATERAL_PRICE_PAUSER, _timelockAddress);
    }

    /**
     * External.
     */
    function setBuyBackCollateralBuffer(uint256 percent)
        external
        override
        onlyAdminOrOwnerOrGovernance
    {
        require(percent <= 100, 'ArthPool: percent > 100');
        buybackCollateralBuffer = percent;
    }

    function setRecollateralizationCurve(ICurve curve)
        external
        onlyAdminOrOwnerOrGovernance
    {
        _recollateralizeDiscountCruve = curve;
    }

    function setARTHController(IARTHController controller)
        external
        onlyAdminOrOwnerOrGovernance
    {
        _arthController = controller;
    }

    function setARTHMAHAOracle(ISimpleOracle oracle)
        external
        onlyAdminOrOwnerOrGovernance
    {
        _ARTHMAHAOracle = oracle;
    }

    function setStabilityFee(uint256 percent)
        external
        override
        onlyAdminOrOwnerOrGovernance
    {
        require(percent <= 100, 'ArthPool: percent > 100');

        stabilityFee = percent;
    }

    function setCollatGMUOracle(address _collateralGMUOracleAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        collateralGMUOracleAddress = _collateralGMUOracleAddress;
        _collateralGMUOracle = IOracle(_collateralGMUOracleAddress);
    }

    function toggleMinting() external override {
        require(hasRole(_MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }

    function toggleRedeeming() external override {
        require(hasRole(_REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external override {
        require(hasRole(_RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }

    function toggleBuyBack() external override {
        require(hasRole(_BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
    }

    function toggleCollateralPrice(uint256 newPrice) external override {
        require(hasRole(_COLLATERAL_PRICE_PAUSER, msg.sender));

        // If pausing, set paused price; else if unpausing, clear pausedPrice.
        if (collateralPricePaused == false) pausedPrice = newPrice;
        else pausedPrice = 0;

        collateralPricePaused = !collateralPricePaused;
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(
        uint256 newCeiling,
        uint256 newRedemptionDelay,
        uint256 newMintFee,
        uint256 newRedeemFee,
        uint256 newBuybackFee,
        uint256 newRecollateralizeFee
    ) external override onlyByOwnerOrGovernance {
        poolCeiling = newCeiling;
        redemptionDelay = newRedemptionDelay;
        mintingFee = newMintFee;
        redemptionFee = newRedeemFee;
        buybackFee = newBuybackFee;
        recollatFee = newRecollateralizeFee;
    }

    function setTimelock(address new_timelock)
        external
        override
        onlyByOwnerOrGovernance
    {
        _timelockAddress = new_timelock;
    }

    function setOwner(address __ownerAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        _ownerAddress = __ownerAddress;
    }

    function borrow(uint256 _amount) external override onlyAMOS {
        require(
            _COLLATERAL.balanceOf(address(this)) > _amount,
            'ArthPool: Insufficent funds in the pool'
        );

        _COLLATERAL.transfer(msg.sender, _amount);
        borrowedCollateral[msg.sender] += _amount;

        emit Borrow(msg.sender, _amount);
    }

    function repay(uint256 amount) external override onlyAMOS {
        require(
            borrowedCollateral[msg.sender] > 0,
            "ArthPool: Repayer doesn't not have any debt"
        );

        require(
            _COLLATERAL.balanceOf(msg.sender) >= amount,
            'ArthPool: balance < required'
        );
        _COLLATERAL.transferFrom(msg.sender, address(this), amount);

        borrowedCollateral[msg.sender] -= amount;

        emit Repay(msg.sender, amount);
    }

    function mint1t1ARTH(uint256 collateralAmount, uint256 arthOutMin)
        external
        override
        notMintPaused
        returns (uint256)
    {
        uint256 collateralAmountD18 = collateralAmount * (10**_missingDeciamls);

        require(
            _arthController.getCRForMint() >= _COLLATERAL_RATIO_MAX,
            'ARHTPool: Collateral ratio < 1'
        );
        require(
            (_COLLATERAL.balanceOf(address(this)))
                .sub(unclaimedPoolCollateral)
                .add(collateralAmount) <= poolCeiling,
            'ARTHPool: ceiling reached'
        );

        // 1 ARTH for each $1 worth of collateral.
        uint256 arthAmountD18 =
            ArthPoolLibrary.calcMint1t1ARTH(
                getCollateralPrice(),
                collateralAmountD18
            );

        // Remove precision at the end.
        arthAmountD18 = (arthAmountD18.mul(uint256(1e6).sub(mintingFee))).div(
            1e6
        );

        require(
            arthOutMin <= arthAmountD18,
            'ARTHPool: Slippage limit reached'
        );

        require(
            _COLLATERAL.balanceOf(msg.sender) >= collateralAmount,
            'ArthPool: balance < required'
        );
        _COLLATERAL.transferFrom(msg.sender, address(this), collateralAmount);

        _ARTH.poolMint(msg.sender, arthAmountD18);

        return arthAmountD18;
    }

    function mintAlgorithmicARTH(uint256 arthxAmountD18, uint256 arthOutMin)
        external
        override
        notMintPaused
        returns (uint256)
    {
        uint256 arthxPrice = _arthController.getARTHXPrice();

        require(
            _arthController.getCRForMint() == 0,
            'ARTHPool: Collateral ratio != 0'
        );

        uint256 arthAmountD18 =
            ArthPoolLibrary.calcMintAlgorithmicARTH(
                arthxPrice, // X ARTHX / 1 USD
                arthxAmountD18
            );
        arthAmountD18 = (arthAmountD18.mul(uint256(1e6).sub(mintingFee))).div(
            1e6
        );

        require(arthOutMin <= arthAmountD18, 'Slippage limit reached');

        _ARTH.poolMint(msg.sender, arthAmountD18);
        _ARTHX.poolBurnFrom(msg.sender, arthxAmountD18);

        return arthAmountD18;
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalARTH(
        uint256 collateralAmount,
        uint256 arthxAmount,
        uint256 arthOutMin
    ) external override notMintPaused returns (uint256) {
        uint256 arthxPrice = _arthController.getARTHXPrice();
        uint256 collateralRatioForMint = _arthController.getCRForMint();

        require(
            collateralRatioForMint < _COLLATERAL_RATIO_MAX &&
                collateralRatioForMint > 0,
            'ARTHPool: fails (.000001 <= Collateral ratio <= .999999)'
        );

        require(
            _COLLATERAL
                .balanceOf(address(this))
                .sub(unclaimedPoolCollateral)
                .add(collateralAmount) <= poolCeiling,
            'ARTHPool: ceiling reached.'
        );

        uint256 collateralAmountD18 = collateralAmount * (10**_missingDeciamls);
        ArthPoolLibrary.MintFAParams memory inputParams =
            ArthPoolLibrary.MintFAParams(
                arthxPrice,
                getCollateralPrice(),
                arthxAmount,
                collateralAmountD18,
                collateralRatioForMint
            );

        (uint256 mintAmount, uint256 arthxNeeded) =
            ArthPoolLibrary.calcMintFractionalARTH(inputParams);

        mintAmount = (mintAmount.mul(uint256(1e6).sub(mintingFee))).div(1e6);

        require(arthOutMin <= mintAmount, 'ARTHPool: Slippage limit reached');
        require(arthxNeeded <= arthxAmount, 'ARTHPool: ARTHX < required');

        _ARTHX.poolBurnFrom(msg.sender, arthxNeeded);

        require(
            _COLLATERAL.balanceOf(msg.sender) >= collateralAmount,
            'ArthPool: balance < require'
        );
        _COLLATERAL.transferFrom(msg.sender, address(this), collateralAmount);

        _ARTH.poolMint(msg.sender, mintAmount);

        return mintAmount;
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1ARTH(uint256 arthAmount, uint256 collateralOutMin)
        external
        override
        notRedeemPaused
    {
        require(
            _arthController.getCRForRedeem() == _COLLATERAL_RATIO_MAX,
            'Collateral ratio must be == 1'
        );

        // Need to adjust for decimals of collateral
        uint256 arthAmountPrecision = arthAmount.div(10**_missingDeciamls);
        uint256 collateralNeeded =
            ArthPoolLibrary.calcRedeem1t1ARTH(
                getCollateralPrice(),
                arthAmountPrecision
            );

        collateralNeeded = (
            collateralNeeded.mul(uint256(1e6).sub(redemptionFee))
        )
            .div(1e6);

        require(
            collateralNeeded <=
                _COLLATERAL.balanceOf(address(this)).sub(
                    unclaimedPoolCollateral
                ),
            'ARTHPool: Not enough collateral in pool'
        );
        require(
            collateralOutMin <= collateralNeeded,
            'ARTHPool: Slippage limit reached'
        );

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[
            msg.sender
        ]
            .add(collateralNeeded);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateralNeeded);
        lastRedeemed[msg.sender] = block.number;

        _chargeStabilityFee(arthAmount);

        // Move all external functions to the end
        _ARTH.poolBurnFrom(msg.sender, arthAmount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem ARTH for collateral and ARTHX. > 0% and < 100% collateral-backed
    function redeemFractionalARTH(
        uint256 arthAmount,
        uint256 arthxOutMin,
        uint256 collateralOutMin
    ) external override notRedeemPaused {
        uint256 arthxPrice = _arthController.getARTHXPrice();
        uint256 collateralRatioForRedeem = _arthController.getCRForRedeem();

        require(
            collateralRatioForRedeem < _COLLATERAL_RATIO_MAX &&
                collateralRatioForRedeem > 0,
            'ARTHPool: Collateral ratio needs to be between .000001 and .999999'
        );

        uint256 collateralPriceGMU = getCollateralPrice();
        uint256 arthAmountPostFee =
            (arthAmount.mul(uint256(1e6).sub(redemptionFee))).div(
                _PRICE_PRECISION
            );

        uint256 arthxGMUValueD18 =
            arthAmountPostFee.sub(
                arthAmountPostFee.mul(collateralRatioForRedeem).div(
                    _PRICE_PRECISION
                )
            );
        uint256 arthxAmount =
            arthxGMUValueD18.mul(_PRICE_PRECISION).div(arthxPrice);

        // Need to adjust for decimals of collateral
        uint256 arthAmountPrecision =
            arthAmountPostFee.div(10**_missingDeciamls);
        uint256 collateralDollatValue =
            arthAmountPrecision.mul(collateralRatioForRedeem).div(
                _PRICE_PRECISION
            );
        uint256 collateralAmount =
            collateralDollatValue.mul(_PRICE_PRECISION).div(collateralPriceGMU);

        require(
            collateralAmount <=
                _COLLATERAL.balanceOf(address(this)).sub(
                    unclaimedPoolCollateral
                ),
            'Not enough collateral in pool'
        );
        require(
            collateralOutMin <= collateralAmount,
            'Slippage limit reached [collateral]'
        );
        require(arthxOutMin <= arthxAmount, 'Slippage limit reached [ARTHX]');

        redeemCollateralBalances[msg.sender] += collateralAmount;
        unclaimedPoolCollateral += collateralAmount;

        redeemARTHXBalances[msg.sender] += arthxAmount;
        unclaimedPoolARTHX += arthxAmount;

        lastRedeemed[msg.sender] = block.number;

        _chargeStabilityFee(arthAmount);

        // Move all external functions to the end
        _ARTH.poolBurnFrom(msg.sender, arthAmount);
        _ARTHX.poolMint(address(this), arthxAmount);
    }

    // Redeem ARTH for ARTHX. 0% collateral-backed
    function redeemAlgorithmicARTH(uint256 arthAmount, uint256 arthxOutMin)
        external
        override
        notRedeemPaused
    {
        uint256 arthxPrice = _arthController.getARTHXPrice();
        uint256 collateralRatioForRedeem = _arthController.getCRForRedeem();

        require(collateralRatioForRedeem == 0, 'Collateral ratio must be 0');
        uint256 arthxGMUValueD18 = arthAmount;

        arthxGMUValueD18 = (
            arthxGMUValueD18.mul(uint256(1e6).sub(redemptionFee))
        )
            .div(_PRICE_PRECISION); // apply fees

        uint256 arthxAmount =
            arthxGMUValueD18.mul(_PRICE_PRECISION).div(arthxPrice);

        redeemARTHXBalances[msg.sender] = redeemARTHXBalances[msg.sender].add(
            arthxAmount
        );
        unclaimedPoolARTHX += arthxAmount;

        lastRedeemed[msg.sender] = block.number;

        require(arthxOutMin <= arthxAmount, 'Slippage limit reached');

        _chargeStabilityFee(arthAmount);

        // Move all external functions to the end
        _ARTH.poolBurnFrom(msg.sender, arthAmount);
        _ARTHX.poolMint(address(this), arthxAmount);
    }

    // After a redemption happens, transfer the newly minted ARTHX and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out ARTH/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external override {
        require(
            (lastRedeemed[msg.sender].add(redemptionDelay)) <= block.number,
            'Must wait for redemptionDelay blocks before collecting redemption'
        );

        uint256 ARTHXAmount;
        uint256 CollateralAmount;
        bool sendARTHX = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if (redeemARTHXBalances[msg.sender] > 0) {
            ARTHXAmount = redeemARTHXBalances[msg.sender];
            redeemARTHXBalances[msg.sender] = 0;
            unclaimedPoolARTHX = unclaimedPoolARTHX.sub(ARTHXAmount);

            sendARTHX = true;
        }

        if (redeemCollateralBalances[msg.sender] > 0) {
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(
                CollateralAmount
            );

            sendCollateral = true;
        }

        if (sendARTHX == true) _ARTHX.transfer(msg.sender, ARTHXAmount);
        if (sendCollateral == true)
            _COLLATERAL.transfer(msg.sender, CollateralAmount);
    }

    // When the protocol is recollateralizing, we need to give a discount of ARTHX to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get ARTHX for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of ARTHX + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra ARTHX value from the bonus rate as an arb opportunity
    function recollateralizeARTH(uint256 collateralAmount, uint256 arthxOutMin)
        external
        override
        returns (uint256)
    {
        require(recollateralizePaused == false, 'Recollateralize is paused');

        uint256 collateralAmountD18 = collateralAmount * (10**_missingDeciamls);
        uint256 arthxPrice = _arthController.getARTHXPrice();
        uint256 arthTotalSupply = _arthController.getARTHSupply();
        uint256 collateralRatioForRecollateralize =
            _arthController.getCRForRecollateralize();
        uint256 globalCollatValue = _arthController.getGlobalCollateralValue();

        (uint256 collateralUnits, uint256 amountToRecollateralize) =
            ArthPoolLibrary.calcRecollateralizeARTHInner(
                collateralAmountD18,
                getCollateralPrice(),
                globalCollatValue,
                arthTotalSupply,
                collateralRatioForRecollateralize
            );

        uint256 collateralUnitsPrecision =
            collateralUnits.div(10**_missingDeciamls);

        // NEED to make sure that recollatFee is less than 1e6.
        uint256 arthxPaidBack =
            amountToRecollateralize
                .mul(
                uint256(1e6).add(getRecollateralizationDiscount()).sub(
                    recollatFee
                )
            )
                .div(arthxPrice);

        require(arthxOutMin <= arthxPaidBack, 'Slippage limit reached');
        require(
            _COLLATERAL.balanceOf(msg.sender) >= collateralUnitsPrecision,
            'ArthPool: balance < required'
        );
        _COLLATERAL.transferFrom(
            msg.sender,
            address(this),
            collateralUnitsPrecision
        );

        _ARTHX.poolMint(msg.sender, arthxPaidBack);

        return arthxPaidBack;
    }

    // Function can be called by an ARTHX holder to have the protocol buy back ARTHX with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackARTHX(uint256 arthxAmount, uint256 collateralOutMin)
        external
        override
    {
        require(buyBackPaused == false, 'Buyback is paused');

        uint256 arthxPrice = _arthController.getARTHXPrice();

        ArthPoolLibrary.BuybackARTHXParams memory inputParams =
            ArthPoolLibrary.BuybackARTHXParams(
                getAvailableExcessCollateralDV(),
                arthxPrice,
                getCollateralPrice(),
                arthxAmount
            );

        uint256 collateralEquivalentD18 =
            (ArthPoolLibrary.calcBuyBackARTHX(inputParams))
                .mul(uint256(1e6).sub(buybackFee))
                .div(1e6);
        uint256 collateralPrecision =
            collateralEquivalentD18.div(10**_missingDeciamls);

        require(
            collateralOutMin <= collateralPrecision,
            'Slippage limit reached'
        );

        // Give the sender their desired collateral and burn the ARTHX
        _ARTHX.poolBurnFrom(msg.sender, arthxAmount);
        _COLLATERAL.transfer(msg.sender, collateralPrecision);
    }

    function getARTHMAHAPrice() public view override returns (uint256) {
        return _ARTHMAHAOracle.getPrice();
    }

    function getGlobalCR() public view override returns (uint256) {
        return _arthController.getGlobalCollateralRatio();
    }

    function getCollateralGMUBalance() public view override returns (uint256) {
        uint256 collateralPrice = getCollateralPrice();

        return (
            (_COLLATERAL.balanceOf(address(this)).sub(unclaimedPoolCollateral))
                .mul(10**_missingDeciamls)
                .mul(collateralPrice)
                .div(_PRICE_PRECISION)
                .div(10**_missingDeciamls)
        );
    }

    // Returns the value of excess collateral held in this Arth pool, compared to what is
    // needed to maintain the global collateral ratio
    function getAvailableExcessCollateralDV()
        public
        view
        override
        returns (uint256)
    {
        uint256 totalSupply = _arthController.getARTHSupply();
        uint256 globalCollateralRatio = getGlobalCR();
        uint256 globalCollatValue = _arthController.getGlobalCollateralValue();

        // Check if overcollateralized contract with CR > 1.
        if (globalCollateralRatio > _COLLATERAL_RATIO_PRECISION)
            globalCollateralRatio = _COLLATERAL_RATIO_PRECISION;

        // Calculates collateral needed to back each 1 ARTH with $1 of collateral at current CR.
        uint256 reqCollateralGMUValue =
            (totalSupply.mul(globalCollateralRatio)).div(
                _COLLATERAL_RATIO_PRECISION
            );

        // TODO: add a 10-20% buffer for volatile collaterals.
        if (globalCollatValue > reqCollateralGMUValue) {
            uint256 excessCollateral =
                globalCollatValue.sub(reqCollateralGMUValue);
            uint256 bufferValue =
                excessCollateral.mul(buybackCollateralBuffer).div(100);

            return excessCollateral.sub(bufferValue);
        }

        return 0;
    }

    function getTargetCollateralValue() public view returns (uint256) {
        return
            _arthController
                .getARTHSupply()
                .mul(_arthController.getGlobalCollateralRatio())
                .div(1e6);
    }

    function getRecollateralizationDiscount()
        public
        view
        override
        returns (uint256)
    {
        uint256 targetCollatValue = getTargetCollateralValue();
        uint256 currentCollatValue = _arthController.getGlobalCollateralValue();

        uint256 percentCollateral =
            currentCollatValue.mul(100).div(targetCollatValue);

        return
            _recollateralizeDiscountCruve
                .getY(percentCollateral)
                .mul(_PRICE_PRECISION)
                .div(1e18);
    }

    function getCollateralPrice() public view override returns (uint256) {
        if (collateralPricePaused) return pausedPrice;
        if (isWETHPool) return _arthController.getETHGMUPrice();
        return _collateralGMUOracle.getPrice();
    }

    function estimateStabilityFeeInMAHA(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 stabilityFeeInARTH = amount.mul(stabilityFee).div(100);
        // Considering Simple oracle precision is set to 1e6 and ARTH is in 18 decimals.
        return getARTHMAHAPrice().mul(stabilityFeeInARTH).div(1e6);
    }

    /**
     * Internal.
     */

    function _chargeStabilityFee(uint256 amount) internal {
        require(amount > 0, 'ArthPool: amount = 0');

        if (stabilityFee > 0) {
            uint256 stabilityFeeInMAHA = estimateStabilityFeeInMAHA(amount);
            _MAHA.burnFrom(msg.sender, stabilityFeeInMAHA);
            emit StabilityFeesCharged(msg.sender, stabilityFeeInMAHA);
        }

        return;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {SafeMath} from '../../utils/math/SafeMath.sol';

library ArthPoolLibrary {
    using SafeMath for uint256;

    /**
     * Data structs.
     */

    struct MintFAParams {
        uint256 arthxPriceGMU;
        uint256 collateralPriceGMU;
        uint256 arthxAmount;
        uint256 collateralAmount;
        uint256 collateralRatio;
    }

    struct BuybackARTHXParams {
        uint256 excessCollateralGMUValueD18;
        uint256 arthxPriceGMU;
        uint256 collateralPriceGMU;
        uint256 arthxAmount;
    }

    uint256 private constant _PRICE_PRECISION = 1e6;

    /**
     * Public.
     */

    function calcMint1t1ARTH(
        uint256 collateralPrice,
        uint256 collateralAmountD18
    ) public pure returns (uint256) {
        return (collateralAmountD18.mul(collateralPrice)).div(1e6);
    }

    function calcMintAlgorithmicARTH(
        uint256 arthxPriceGMU,
        uint256 collateralAmountD18
    ) public pure returns (uint256) {
        return collateralAmountD18.mul(arthxPriceGMU).div(1e6);
    }

    // Must be internal because of the struct
    function calcMintFractionalARTH(MintFAParams memory params)
        internal
        pure
        returns (uint256, uint256)
    {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint ARTH. We do this by seeing the minimum mintable ARTH based on each amount
        uint256 arthxGMUValueD18;
        uint256 collateralGMUValueD18;

        // Scoping for stack concerns
        {
            // USD amounts of the collateral and the ARTHX
            arthxGMUValueD18 = params.arthxAmount.mul(params.arthxPriceGMU).div(
                1e6
            );
            collateralGMUValueD18 = params
                .collateralAmount
                .mul(params.collateralPriceGMU)
                .div(1e6);
        }
        uint256 calcARTHXGMUValueD18 =
            (collateralGMUValueD18.mul(1e6).div(params.collateralRatio)).sub(
                collateralGMUValueD18
            );

        uint256 calcARTHXNeeded =
            calcARTHXGMUValueD18.mul(1e6).div(params.arthxPriceGMU);

        return (
            collateralGMUValueD18.add(calcARTHXGMUValueD18),
            calcARTHXNeeded
        );
    }

    function calcRedeem1t1ARTH(uint256 collateralPriceGMU, uint256 arthAmount)
        public
        pure
        returns (uint256)
    {
        return arthAmount.mul(1e6).div(collateralPriceGMU);
    }

    // Must be internal because of the struct
    function calcBuyBackARTHX(BuybackARTHXParams memory params)
        internal
        pure
        returns (uint256)
    {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible ARTHX with the desired collateral
        require(
            params.excessCollateralGMUValueD18 > 0,
            'No excess collateral to buy back!'
        );

        // Make sure not to take more than is available
        uint256 arthxGMUValueD18 =
            params.arthxAmount.mul(params.arthxPriceGMU).div(1e6);
        require(
            arthxGMUValueD18 <= params.excessCollateralGMUValueD18,
            'You are trying to buy back more than the excess!'
        );

        // Get the equivalent amount of collateral based on the market value of ARTHX provided
        uint256 collateralEquivalentD18 =
            arthxGMUValueD18.mul(1e6).div(params.collateralPriceGMU);
        // collateralEquivalentD18 = collateralEquivalentD18.sub((collateralEquivalentD18.mul(params.buybackFee)).div(1e6));

        return (collateralEquivalentD18);
    }

    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(
        uint256 totalSupply,
        uint256 globalCollateralRatio,
        uint256 globalCollatValue
    ) public pure returns (uint256) {
        uint256 targetCollateralValue =
            totalSupply.mul(globalCollateralRatio).div(1e6); // We want 18 decimals of precision so divide by 1e6; totalSupply is 1e18 and globalCollateralRatio is 1e6

        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return targetCollateralValue.sub(globalCollatValue); // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }

    function calcRecollateralizeARTHInner(
        uint256 collateralAmount,
        uint256 collateralPrice,
        uint256 globalCollatValue,
        uint256 arthTotalSupply,
        uint256 globalCollateralRatio
    ) public pure returns (uint256, uint256) {
        uint256 collateralValueAttempted =
            collateralAmount.mul(collateralPrice).div(1e6);
        uint256 effectiveCollateralRatio =
            globalCollatValue.mul(1e6).div(arthTotalSupply); //returns it in 1e6

        uint256 recollateralizePossible =
            (
                globalCollateralRatio.mul(arthTotalSupply).sub(
                    arthTotalSupply.mul(effectiveCollateralRatio)
                )
            )
                .div(1e6);

        uint256 amountToRecollateralize;
        if (collateralValueAttempted <= recollateralizePossible) {
            amountToRecollateralize = collateralValueAttempted;
        } else {
            amountToRecollateralize = recollateralizePossible;
        }

        return (
            amountToRecollateralize.mul(1e6).div(collateralPrice),
            amountToRecollateralize
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IARTHPool {
    function repay(uint256 amount) external;

    function borrow(uint256 amount) external;

    function setStabilityFee(uint256 percent) external;

    function setBuyBackCollateralBuffer(uint256 percent) external;

    function setCollatGMUOracle(
        address _collateralGMUOracleAddress
    ) external;

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function toggleCollateralPrice(uint256 newPrice) external;

    function setPoolParameters(
        uint256 newCeiling,
        uint256 newRedemptionDelay,
        uint256 newMintFee,
        uint256 newRedeemFee,
        uint256 newBuybackFee,
        uint256 newRecollateralizeFee
    ) external;

    function setTimelock(address newTimelock) external;

    function setOwner(address ownerAddress) external;

    function mint1t1ARTH(uint256 collateralAmount, uint256 ARTHOutMin)
        external
        returns (uint256);

    function mintAlgorithmicARTH(uint256 arthxAmountD18, uint256 arthOutMin)
        external
        returns (uint256);

    function mintFractionalARTH(
        uint256 collateralAmount,
        uint256 arthxAmount,
        uint256 ARTHOutMin
    ) external returns (uint256);

    function redeem1t1ARTH(uint256 arthAmount, uint256 collateralOutMin)
        external;

    function redeemFractionalARTH(
        uint256 arthAmount,
        uint256 arthxOutMin,
        uint256 collateralOutMin
    ) external;

    function redeemAlgorithmicARTH(uint256 arthAmounnt, uint256 arthxOutMin)
        external;

    function collectRedemption() external;

    function recollateralizeARTH(uint256 collateralAmount, uint256 arthxOutMin)
        external
        returns (uint256);

    function buyBackARTHX(uint256 arthxAmount, uint256 collateralOutMin)
        external;

    function getGlobalCR() external view returns (uint256);

    function mintingFee() external returns (uint256);

    function isWETHPool() external returns (bool);

    function redemptionFee() external returns (uint256);

    function buybackFee() external returns (uint256);

    function getRecollateralizationDiscount() external view returns (uint256);

    function recollatFee() external returns (uint256);

    function getCollateralGMUBalance() external view returns (uint256);

    function getAvailableExcessCollateralDV() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function getARTHMAHAPrice() external view returns (uint256);

    function collateralPricePaused() external view returns (bool);

    function pausedPrice() external view returns (uint256);

    function collateralGMUOracleAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ArthPool.sol';

contract Pool_USDC is ArthPool {
    /**
     * State variable.
     */
    address public USDC_address;

    /**
     * Constructor.
     */
    constructor(
        address _arthContractAddres,
        address _arthxContractAddres,
        address _collateralAddress,
        address _creatorAddress,
        address _timelockAddress,
        address _mahaToken,
        address _arthMAHAOracle,
        address _arthController,
        uint256 _poolCeiling
    )
        ArthPool(
            _arthContractAddres,
            _arthxContractAddres,
            _collateralAddress,
            _creatorAddress,
            _timelockAddress,
            _mahaToken,
            _arthMAHAOracle,
            _arthController,
            _poolCeiling
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        USDC_address = _collateralAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    function fixedY() external view returns (uint256);

    function minX() external view returns (uint256);

    function maxX() external view returns (uint256);

    function minY() external view returns (uint256);

    function maxY() external view returns (uint256);

    function getY(uint256 x) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAnyswapV4Token {
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) external returns (bool);

    function Swapout(uint256 amount, address bindaddr) external returns (bool);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals for token.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20.sol';

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function getPairWETHPrice() external view returns(uint256);

    function getETHGMUPrice() external view returns(uint256);

    function getPairPrice() external view returns(uint256);

    function getChainlinkPrice() external view returns(uint256);

    function getPrice() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleOracle {
    function getPrice() external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapPairOracle {
    function update() external;

    function setPeriod(uint256 _period) external;

    function setOwner(address _ownerAddress) external;

    function setTimelock(address _timelockAddress) external;

    function setConsultLeniency(uint256 _consultLeniency) external;

    function setAllowStaleConsults(bool _allowStaleConsults) external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function canUpdate() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../utils/Context.sol';
import '../utils/introspection/ERC165.sol';

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            'AccessControl: sender must be an admin to grant'
        );

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(
            hasRole(getRoleAdmin(role), _msgSender()),
            'AccessControl: sender must be an admin to revoke'
        );

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            'AccessControl: can only renounce roles for self'
        );

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100000
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/Users/newsgate/Work/arthcoin-v2/contracts/Arth/Pools/ArthPoolLibrary.sol": {
      "ArthPoolLibrary": "0xe3d3B52EcA3b69ac3261df36f3a0E608EB2A9f14"
    }
  },
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