// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '../ERC20/IERC20.sol';
import {IIncentiveController} from './IIncentive.sol';
import {IAnyswapV4Token} from '../ERC20/IAnyswapV4Token.sol';

interface IARTH is IERC20, IAnyswapV4Token {
    function poolMint(address who, uint256 amount) external;

    function poolBurnFrom(address who, uint256 amount) external;

    function setArthController(address _controller) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IARTHController {
    function toggleCollateralRatio() external;

    function addPool(address pool_address) external;

    function addPools(address[] memory poolAddress) external;

    function removePool(address pool_address) external;

    function getARTHSupply() external view returns (uint256);

    function isPool(address pool) external view returns (bool);

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
            // uint256,
            uint256
        );

    function setMintingFee(uint256 fee) external;

    function setMAHAGMUOracle(address oracle) external;

    function setFeesParameters(
        uint256 _mintingFee,
        uint256 _buybackFee,
        uint256 _redemptionFee
    ) external;

    function setRedemptionFee(uint256 fee) external;

    function setBuybackFee(uint256 fee) external;

    function setOwner(address _ownerAddress) external;

    function setTimelock(address newTimelock) external;

    function setGlobalCollateralRatio(uint256 _globalCollateralRatio) external;

    function getMintingFee() external view returns (uint256);

    function getMAHAPrice() external view returns (uint256);

    function getBuybackFee() external view returns (uint256);

    function getRedemptionFee() external view returns (uint256);

    function getGlobalCollateralRatio() external view returns (uint256);

    function getGlobalCollateralValue() external view returns (uint256);

    function arthPools(address pool) external view returns (bool);

    function setStabilityFee(uint256 val) external;

    function isBuybackPaused() external view returns (bool);

    function isRecollaterlizePaused() external view returns (bool);

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function getStabilityFee() external view returns (uint256);

    // todo add this here
    function mintingFee() external returns (uint256);

    function redemptionFee() external returns (uint256);

    function buybackFee() external returns (uint256);

    function getRecollateralizationDiscount() external returns (uint256);

    function getTargetCollateralValue() external view returns (uint256);

    function getPercentCollateralized() external view returns (uint256);
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

import {SafeMath} from '../../utils/math/SafeMath.sol';

library ArthPoolLibrary {
    using SafeMath for uint256;

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

        function calcOverCollateralizedMintAmounts(
        uint256 collateralRatio,
        uint256 collateralPrice,
        uint256 collateralAmountD18
    )
        public
        pure
        returns (
            uint256  // ARTH Mint amount.
        )
    {
        uint256 collateralValue = (
            collateralAmountD18
            .mul(collateralPrice)
            .div(1e6)
        );

        uint256 arthValueToMint = collateralValue.mul(collateralRatio).div(1e6);

        return (arthValueToMint);
    }


    function calcOverCollateralizedRedeemAmounts(
        uint256 collateralRatio,
        uint256 collateralPriceGMU,
        uint256 arthAmount
    )
        public
        pure
        returns (
            uint256 // Collateral amount to return.
        )
    {

        uint256 arthxValueNeeded = (
            arthAmount
                .mul(1e6)
                .div(collateralRatio)
                .sub(arthAmount)
        );


        return (arthAmount.add(arthxValueNeeded).mul(1e6).div(collateralPriceGMU)
        );
    }

    // useful
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
    )
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
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
            amountToRecollateralize,
            recollateralizePossible
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IARTHPool {

    function setCollatGMUOracle(address _collateralGMUOracleAddress) external;

    function setPoolParameters(uint256 newCeiling, uint256 newRedemptionDelay)
        external;

    function setTimelock(address newTimelock) external;

    function setOwner(address ownerAddress) external;

    function mint(uint256 collateralAmount, uint256 arthOutMin)
        external
       returns (uint256);

    function redeem(uint256 arthAmount, uint256 collateralOutMin)
        external;

    function collectRedemption() external;


    function getGlobalCR() external view returns (uint256);

    function getCollateralGMUBalance() external view returns (uint256);

    function getAvailableExcessCollateralDV() external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function collateralGMUOracleAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Test_ArthPool.sol';

contract Pool_USDC is TestArthPool {
    /**
     * State variable.
     */
    address public USDC_address;

    /**
     * Constructor.
     */
    constructor(
        address _arthContractAddres,
        address _collateralAddress,
        address _creatorAddress,
        address _timelockAddress,
        address _mahaToken,
        address _arthController,
        uint256 _poolCeiling
    )
        TestArthPool(
            _arthContractAddres,
            _collateralAddress,
            _creatorAddress,
            _timelockAddress,
            _mahaToken,
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
pragma experimental ABIEncoderV2;

import {IARTH} from '../IARTH.sol';
import {IARTHPool} from './IARTHPool.sol';
import {IERC20} from '../../ERC20/IERC20.sol';
import {IOracle} from '../../Oracle/IOracle.sol';
import {SafeMath} from '../../utils/math/SafeMath.sol';
import {ArthPoolLibrary} from './ArthPoolLibrary.sol';
import {IARTHController} from '../IARTHController.sol';
import {IERC20Burnable} from '../../ERC20/IERC20Burnable.sol';
import {AccessControl} from '../../access/AccessControl.sol';


contract TestArthPool is AccessControl, IARTHPool {
    using SafeMath for uint256;

    /**
     * @dev Contract instances.
     */

    IARTH public _ARTH;
    IERC20 public _COLLATERAL;
    IERC20Burnable public _MAHA;
    IARTHController public _arthController;
    IOracle public _collateralGMUOracle;
    address public fund = address(0xcaDAfdDBf7E4076b54f422f9Ba275f0EB6B3A146);

    uint256 public buybackCollateralBuffer = 20; // In %.
    // redeem fees in %, taken on Arth
    uint256 public redeemFees = 5;
    uint256 public poolCeiling = 0; // Total units of collateral that a pool contract can hold
    uint256 public redemptionDelay = 1; // Number of blocks to wait before being able to collect redemption.

    uint256 public unclaimedPoolCollateral;
    

    address public override collateralGMUOracleAddress;

    mapping(address => uint256) public lastRedeemed;
    mapping(address => uint256) public borrowedCollateral;
    mapping(address => uint256) public redeemCollateralBalances;

    struct amountsRecord {
    address id;
    uint256 amount;
    address sender;
    }
    mapping(address => amountsRecord) public mintersDetails;

    uint256 private immutable _missingDeciamls;
    uint256 private constant _PRICE_PRECISION = 1e6;
    //uint256 private constant _COLLATERAL_RATIO_MAX = 3e6; // Placeholder, need to replace this with apt. val.
    //uint256 private constant _COLLATERAL_RATIO_MIN = 1e6 + 1; // 100.0001 in 1e6 precision.
    uint256 private constant _COLLATERAL_RATIO_PRECISION = 1e6;

    address private _wethAddress;
    address private _ownerAddress;
    address private _timelockAddress;
    address private _collateralAddress;
    address private _arthContractAddress;
    uint256 public pcr;
    uint256 public mockUSDCPrice = 1000000;

    /**
     * Events.
     */
    event Repay(address indexed from, uint256 amount);
    event Borrow(address indexed from, uint256 amount);
    event StabilityFeesCharged(address indexed from, uint256 fee);
    event usedredeemNotMinter(address indexed from, uint256 amount);

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

    modifier onlyAdminOrOwnerOrGovernance() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                msg.sender == _timelockAddress ||
                msg.sender == _ownerAddress,
            'ArthPool: forbidden'
        );
        _;
    }

    /**
     * Constructor.
     */

    constructor(
        address __arthContractAddress,
        address __collateralAddress,
        address _creatorAddress,
        address __timelockAddress,
        address __MAHA,
        address __arthController,
        uint256 _poolCeiling
    ) {
        _MAHA = IERC20Burnable(__MAHA);
        _ARTH = IARTH(__arthContractAddress);
        _COLLATERAL = IERC20(__collateralAddress);
        _arthController = IARTHController(__arthController);

        _ownerAddress = _creatorAddress;
        _timelockAddress = __timelockAddress;
        _collateralAddress = __collateralAddress;
        _arthContractAddress = __arthContractAddress;

        poolCeiling = _poolCeiling;
        _missingDeciamls = uint256(18).sub(_COLLATERAL.decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

// Set functions //

    function setARTHController(IARTHController controller)
        external
        onlyAdminOrOwnerOrGovernance
    {
        _arthController = controller;
    }

    function setFund(address newFund) external onlyByOwnerOrGovernance {
        fund = newFund;
    }

    function setCollatGMUOracle(address _collateralGMUOracleAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        collateralGMUOracleAddress = _collateralGMUOracleAddress;
        _collateralGMUOracle = IOracle(_collateralGMUOracleAddress);
    }

    function setPoolParameters(uint256 newCeiling, uint256 newRedemptionDelay)
        external
        override
        onlyByOwnerOrGovernance
    {
        poolCeiling = newCeiling;
        redemptionDelay = newRedemptionDelay;
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

// End Set functions //

    function mint(
        uint256 collateralAmount,
        uint256 arthOutMin
    ) external override returns (uint256) {

        uint256 collateralAmountAfterFees = (collateralAmount.mul(uint256(1e6).sub(_arthController.getMintingFee()))).div(1e6);
        uint256 collateralAmountD18 = collateralAmountAfterFees * (10**_missingDeciamls);
        uint256 cr = _arthController.getGlobalCollateralRatio();


        // //check if collateral ratio is OK
        // require(
        //     cr <= _COLLATERAL_RATIO_MAX, ////2000000
        //     'ARHTPool: Collateral ratio > MAX'
        // );
        // require(
        //     cr >= _COLLATERAL_RATIO_MIN, //1000001
        //     'ARHTPool: Collateral ratio < MIN'
        // );

        require(
            (_COLLATERAL.balanceOf(address(this)))
                .sub(unclaimedPoolCollateral)
                .add(collateralAmountAfterFees) <= poolCeiling,
            'ARTHPool: ceiling reached'
        );


        uint256 collateralRatio = uint256(cr);

        // 1 ARTH for each $1 worth of collateral.
        (uint256 arthAmountD18) =
            ArthPoolLibrary.calcOverCollateralizedMintAmounts(
                collateralRatio,
                mockUSDCPrice, //500000
                collateralAmountD18
            );

        // require(
        //     arthOutMin <= arthAmountD18,
        //     'ARTHPool: ARTH Slippage limit reached'
        // );

        require(
            _COLLATERAL.balanceOf(msg.sender) >= collateralAmount,
            'ArthPool: balance < required'
        );
        require(
            _COLLATERAL.transferFrom(
                msg.sender,
                address(this),
                collateralAmount
            ),
            'ARTHPool: transfer from failed'
        );

        _ARTH.poolMint(msg.sender, arthAmountD18);

        _chargeTradingFee(
        collateralAmount.sub(collateralAmountAfterFees));
        
        amountsRecord storage mintersdetails = mintersDetails[msg.sender];
        mintersdetails.id = msg.sender;
        mintersdetails.amount = collateralAmountD18.add(mintersDetails[msg.sender].amount);
        mintersdetails.sender = msg.sender;

        return (arthAmountD18);
    }
    
    function calcCr(uint256 arthAmount,uint256 _cr) public view returns (uint256) {
         
        uint256 cr = _cr;
        // require(cr <= _COLLATERAL_RATIO_MAX, 'Collateral ratio > MAX');
        // require(cr >= _COLLATERAL_RATIO_MIN, 'Collateral ratio < MIN');

        uint256 arthAmountPrecision = arthAmount.div(10**_missingDeciamls);
        uint256 collateralRatio = uint256(cr);
        //(uint256 collateralNeeded) = ArthPoolLibrary.calcOverCollateralizedRedeemAmounts(collateralRatio,getCollateralPrice(),arthAmountPrecision);
        (uint256 collateralNeeded) = ArthPoolLibrary.calcOverCollateralizedRedeemAmounts(collateralRatio,mockUSDCPrice,arthAmountPrecision);

        return collateralNeeded;
        
    }


    function redeem(
        uint256 arthAmount,
        uint256 collateralOutMin
    ) external override {
        
        // we transfer the full ARTH amount first
        _ARTH.transferFrom(msg.sender, address(this), arthAmount);
        // we compute the fees amount based on the full amount
        uint256 feesAmount = arthAmount.mul(redeemFees).div(100);
        // for fund
        _ARTH.transfer(fund, feesAmount);
        // this amount is going into calculus
        uint256 compute = arthAmount.sub(feesAmount);
        uint256 collateralNeeded = calcCr(compute, _arthController.getGlobalCollateralRatio());

        // user cannot redeem more than for 200% collateral within the range they minted
        if (collateralNeeded <= mintersDetails[msg.sender].amount && msg.sender == mintersDetails[msg.sender].sender) {
            
            require(
            collateralNeeded <=
                _COLLATERAL.balanceOf(address(this)).sub(
                    unclaimedPoolCollateral
                ),
            'ARTHPool: Not enough collateral in pool'
        );
        

        // require(
        //     collateralOutMin <= collateralNeeded,
        //     'ARTHPool: Collateral Slippage limit reached'
        // );

        //adds amount to a mapping to prevent flashloans
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[
           msg.sender
        ]
            .add(collateralNeeded);
       unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateralNeeded);
       lastRedeemed[msg.sender] = block.number;

        //_chargeTradingFee(collateralNeededBeforeFee.sub(collateralNeededAfterFee));

        mintersDetails[msg.sender].amount = mintersDetails[msg.sender].amount.sub(collateralNeeded.mul(10e11));
        IERC20Burnable(_arthContractAddress).burn(compute);
            
        } else {
         redeemNotMinter(compute, collateralOutMin); 
            
        }
    }

    
    function setPCR(uint256 _pcr) public {
    uint256 pcr = _pcr;
    }

    // we use another function with 100% collateral ratio for users coming from the market
    function redeemNotMinter(uint256 arthAmount, uint256 collateralOutMin) public {
    
    //TO DO : add pcr to the controller
    uint256 pcr = 1000000;
    uint256 collateralNeeded = calcCr(arthAmount, pcr);
            
    require(collateralNeeded <= _COLLATERAL.balanceOf(address(this)).sub(unclaimedPoolCollateral),'ARTHPool: Not enough collateral in pool');

        // require(
        //     collateralOutMin <= collateralNeeded,
        //     'ARTHPool: Collateral Slippage limit reached'
        // );

        //adds amount to a mapping to prevent flashloans
    redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateralNeeded);
    unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateralNeeded);
    lastRedeemed[msg.sender] = block.number;

        // _chargeStabilityFee(arthAmount);
        // _chargeTradingFee(
        //     collateralNeededBeforeFee.sub(collateralNeededAfterFee),
        //     'Redeem fee charged'
        // );

        IERC20Burnable(_arthContractAddress).burn(arthAmount);
        emit usedredeemNotMinter(msg.sender, arthAmount);
    }

    // After a redemption happens, transfer the newly minted ARTHX and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out ARTH/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external override {
        require(
            (lastRedeemed[msg.sender].add(redemptionDelay)) <= block.number,
            'Must wait for redemptionDelay blocks before collecting redemption'
        );

        uint256 CollateralAmount;
        bool sendCollateral = false;

        if (redeemCollateralBalances[msg.sender] > 0) {
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(
                CollateralAmount
            );

            sendCollateral = true;
        }

        if (sendCollateral)
            require(
                _COLLATERAL.transfer(msg.sender, CollateralAmount),
                'ARTHPool: transfer failed'
            );
    }

    function getGlobalCR() public view override returns (uint256) {
        return _arthController.getGlobalCollateralRatio();
    }

    function getCollateralGMUBalance()
        external
        view
        override
        returns (uint256)
    {
        //to be replaced by 1
        uint256 collateralPrice = getCollateralPrice();

        return (
            (_COLLATERAL.balanceOf(address(this)).sub(unclaimedPoolCollateral))
                .mul(10**_missingDeciamls)
                .mul(collateralPrice)
                .div(_PRICE_PRECISION)
            // .div(10**_missingDeciamls)
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

    function getCollateralPrice() public view override returns (uint256) {
        return _collateralGMUOracle.getPrice();
    }

    function estimateStabilityFeeInMAHA(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 stabilityFeeInARTH =
            amount.mul(_arthController.getStabilityFee()).div(1e6);

        // ARTH is redeemed at 1$.
        return (
            stabilityFeeInARTH.mul(1e6).div(_arthController.getMAHAPrice())
        );
    }

    function _chargeTradingFee(uint256 amount) internal {
        _COLLATERAL.transfer(fund, amount);

        //good for ERC20 FUND, for simplicity we can just do a transfer
        //fund.deposit(address(_COLLATERAL), amount, reason);
    }

    //check if we want a stability fee that will be burned
    function _chargeStabilityFee(uint256 amount) internal {
        uint256 stabilityFeeInMAHA = estimateStabilityFeeInMAHA(amount);

        if (stabilityFeeInMAHA > 0) {
            _MAHA.burnFrom(msg.sender, stabilityFeeInMAHA);
            emit StabilityFeesCharged(msg.sender, stabilityFeeInMAHA);
        }
    }
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
    function getPrice() external view returns (uint256);

    function getDecimalPercision() external view returns (uint256);
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
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/var/www/html/boltfork/arthcoin-v2/contracts/Arth/Pools/ArthPoolLibrary.sol": {
      "ArthPoolLibrary": "0xEDF1821EDe1503a605c1bE12511B9dC10674b856"
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