// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./common/DecimalConstants.sol";
import "./common/Controllable.sol";
import "./interfaces/ILifeGuard.sol";
import "./interfaces/IBuoy.sol";
import "./interfaces/IDepositHandler.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IPnL.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @notice Entry point for deposits into Gro protocol - User deposits can be done with one or
///     multiple assets, being more expensive gas wise for each additional asset that is deposited.
///     The deposits are treated differently depending on size:
///         1) sardine - the smallest type of deposit, deemed to not affect the system exposure, and
///            is deposited directly into the system - Curve vault is used to price the deposit (buoy)
///         2) tuna - mid sized deposits, will be swapped to least exposed vault asset using Curve's
///            exchange function (lifeguard). Targeting the desired asset (single sided deposit
///            against the least exposed stablecoin) minimizes slippage as it doesn't need to perform
///            any exchanges in the Curve pool
///         3) whale - the largest deposits - deposit will be distributed across all stablecoin vaults
///
///     Tuna and Whale deposits will go through the lifeguard, which in turn will perform all
///     necessary asset swaps.
contract DepositHandler is DecimalConstants, Controllable, IDepositHandler {
    uint256 public utilisationRatioLimitPwrd;
    IController ctrl;
    ILifeGuard lg;
    IBuoy buoy;
    IPnL pnl;
    IInsurance insurance;
    IVault[] vaults;
    uint256[] decimals;
    mapping(bool => IToken) gTokens;

    mapping(address => address) public override referral;
    mapping(uint256 => bool) public feeToken; // (USDT might have a fee)

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event LogNewUtilLimit(bool indexed pwrd, uint256 limit);
    event LogNewFeeToken(address indexed token, uint256 index);
    event LogNewDependencies(
        address controller, 
        address lifeguard, 
        address buoy, 
        address insurance,
        address pwrd,
        address gvt
    );
    event LogNewDeposit(
        address indexed user,
        address indexed referral,
        bool pwrd,
        uint256 usdAmount,
        uint256[] tokens
    );

    /// @notice Update protocol dependencies
    function setDependencies() external onlyOwner {
        ctrl = _controller();
        address[] memory _vaults = ctrl.vaults();
        delete vaults;
        delete decimals;
        for (uint256 i; i < _vaults.length; i++) {
            IVault vault = IVault(_vaults[i]);
            decimals.push(uint256(10)**(IERC20Detailed(vault.token()).decimals()));
            vaults.push(vault);
        }
        lg = ILifeGuard(ctrl.lifeGuard());
        buoy = IBuoy(lg.getBuoy());
        insurance = IInsurance(ctrl.insurance());
        pnl = IPnL(ctrl.pnl());
        gTokens[true] = IToken(ctrl.gToken(true));
        gTokens[false] = IToken(ctrl.gToken(false));
        emit LogNewDependencies(
            address(ctrl), 
            address(lg), 
            address(buoy), 
            address(insurance), 
            address(gTokens[true]),
            address(gTokens[false])
        );
    }

    /// @notice Set the lower bound for when to stop accepting deposits for pwrd - this allows for a bit of legroom
    ///     for gvt to be sold (if this limit is reached, this contract only accepts deposits for gvt)
    /// @param _utilisationRatioLimitPwrd Lower limit for pwrd (%BP)
    function setUtilisationRatioLimitPwrd(uint256 _utilisationRatioLimitPwrd)
        external
        onlyOwner
    {
        utilisationRatioLimitPwrd = _utilisationRatioLimitPwrd;
        emit LogNewUtilLimit(true, _utilisationRatioLimitPwrd);
    }

    /// @notice Some tokens might have fees associated with them (e.g. USDT)
    /// @param index Index (of system tokens) that could have fees
    function setFeeToken(uint256 index) external onlyOwner {
        address token = ctrl.stablecoins()[index];
        require(token != address(0), 'setFeeToken: !invalid token');
        feeToken[index] = true;
        emit LogNewFeeToken(token, index);
    }

    /// @notice Entry when depositing for pwrd
    /// @param inAmounts Amount of each stablecoin deposited
    /// @param minAmount Minimum ammount to expect in return for deposit
    /// @param _referral Referral address (only useful for first deposit)
    function depositPwrd(
        uint256[] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external override whenNotPaused {
        depositGToken(inAmounts, minAmount, _referral, true);
    }

    /// @notice Entry when depositing for gvt
    /// @param inAmounts Amount of each stablecoin deposited
    /// @param minAmount Minimum ammount to expect in return for deposit
    /// @param _referral Referral address (only useful for first deposit)
    function depositGvt(
        uint256[] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external override whenNotPaused {
        depositGToken(inAmounts, minAmount, _referral, false);
    }

    /// @notice Deposit logic
    /// @param inAmounts Amount of each stablecoin deposited
    /// @param minAmount Minimum amount to expect in return for deposit
    /// @param _referral Referral address (only useful for first deposit)
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    function depositGToken(
        uint256[] memory inAmounts,
        uint256 minAmount,
        address _referral,
        bool pwrd
    ) private {
        ctrl.eoaOnly(msg.sender);
        require(minAmount > 0, "minAmount is 0");
        if (_referral != address(0) && referral[msg.sender] == address(0)) {
            referral[msg.sender] = _referral;
        }

        IToken gt = gTokens[pwrd];

        uint256 factor = gt.factor();
        uint256 roughUsd = roughUsd(inAmounts, decimals);

        // Make sure we don't increase the amount of pwrd above the utilization limit

        if (pwrd) {
            require(validGTokenIncrease(roughUsd), "exceeds utilisation limit");
        }

        (uint256 dollarAmount, uint256 _factor) = _deposit(pwrd, roughUsd, minAmount, inAmounts);
        if (_factor > 0) {
            factor = _factor;
        }
        gt.mint(msg.sender, factor, dollarAmount);
        pnl.increaseGTokenLastAmount(address(gt), dollarAmount);
        // Update underlying assets held in pwrd/gvt
        emit LogNewDeposit(msg.sender, referral[msg.sender], pwrd, dollarAmount, inAmounts);
    }

    /// @notice Determine the size of the deposit, and route it accordingly:
    ///     sardine (small) - gets sent directly to the vault adapter
    ///     tuna (middle) - tokens get routed through lifeguard and exchanged to
    ///             target token (based on current vault exposure)
    ///     whale (large) - tokens get deposited into lifeguard Curve pool, withdraw
    ///             into target amounts and deposited across all vaults
    /// @param pwrd Pwrd or gvt
    /// @param roughUsd Estimated USD value of deposit, used to determine size
    /// @param minAmount Minimum amount to return (in Curve LP tokens)
    /// @param inAmounts Input token amounts
    function _deposit(
        bool pwrd,
        uint256 roughUsd,
        uint256 minAmount,
        uint256[] memory inAmounts
    ) private returns (uint256 dollarAmount, uint256 factor) {
        // If a large fish, transfer assets to lifeguard before determening what to do with them
        if (ctrl.isBigFish(roughUsd, pwrd)) {
            for (uint256 i = 0; i < lg.N_COINS(); i++) {
                // Transfer token to target (lifeguard)
                if (inAmounts[i] > 0) {
                    IERC20 token = IERC20(lg.underlyingCoins(i));
                    if (feeToken[i]) {
                        // Separate logic for USDT
                        uint256 current = token.balanceOf(address(lg));
                        token.safeTransferFrom(msg.sender, address(lg), inAmounts[i]);
                        inAmounts[i] = token.balanceOf(address(lg)).sub(current);
                    } else {
                        token.safeTransferFrom(msg.sender, address(lg), inAmounts[i]);
                    }
                }
            }
            (dollarAmount, factor) = _invest(pwrd, inAmounts, roughUsd);
        } else {
            // If sardine, send the assets directly to the vault adapter
            for (uint256 i = 0; i < lg.N_COINS(); i++) {
                if (inAmounts[i] > 0) {
                    // Transfer token to vaultadaptor
                    IERC20 token = IERC20(lg.underlyingCoins(i));
                    address _vault = address(vaults[i]);
                    if (feeToken[i]) {
                        // Seperate logic for USDT
                        uint256 current = token.balanceOf(_vault);
                        token.safeTransferFrom(msg.sender, _vault, inAmounts[i]);
                        inAmounts[i] = token.balanceOf(_vault).sub(current);
                    } else {
                        token.safeTransferFrom(msg.sender, _vault, inAmounts[i]);
                    }
                    // Update vaultadaptor assets
                    vaults[i].updatePnL(inAmounts[i]);
                }
            }
            // Establish USD vault of deposit
            dollarAmount = buoy.stableToUsd(inAmounts, true);
        }
        require(dollarAmount >= buoy.lpToUsd(minAmount), "!minAmount");
    }

    /// @notice Determine how to handle the deposit - get stored vault deltas and indexes,
    ///     and determine if the deposit will be a tuna (deposits into least exposed vaults)
    ///        or a whale (spread across all three vaults)
    ///     Tuna - Deposit swaps all overexposed assets into least exposed asset before investing,
    ///         deposited assets into the two least exposed vaults
    ///     Whale - Deposits all assets into the lifeguard Curve pool, and withdraws
    ///         them in target allocation (insurance underlyingTokensPercents) amounts before
    ///        investing them into all vaults
    /// @param pwrd Pwrd or gvt
    /// @param _inAmounts Input token amounts
    /// @param roughUsd Estimated rough USD value of deposit
    function _invest(
        bool pwrd,
        uint256[] memory _inAmounts,
        uint256 roughUsd
    ) internal returns (uint256 dollarAmount, uint256 factor) {
        // Calculate asset distribution - for large deposits, we will want to spread the
        // assets across all stablecoin vaults to avoid overexposure, otherwise we only
        // ensure that the deposit doesn't target the most overexposed vault
        (, uint256[] memory vaultIndexes, uint256 _vaults) = insurance.getVaultDelta(roughUsd);
        if (_vaults < 3) {
            dollarAmount = lg.investSingle(_inAmounts, vaultIndexes[0], vaultIndexes[1]);
        } else {
            uint256 outAmount = lg.deposit();
            uint256[] memory delta = insurance.calculateDepositDeltasOnAllVaults();
            dollarAmount = lg.invest(outAmount, delta);
            if (pnl.pnlTrigger()) {
                // Deposited assets is in lifeguard now and accounted into system total assets
                // Should remove this deposited assets to handle PnL, otherwise will distribute it between gvt and pwrd
                pnl.execPnL(dollarAmount);
                // GToken total assets is incorrect here because system total assets includes this deposited assets
                // Re-calculate factor based on PnL result instead of GToken total assets
                factor = gTokens[pwrd].factor();
            }
        }
    }

    /// @notice Check if it's OK to mint the specified amount of tokens, this affects
    ///     pwrds, as they have an upper bound set by the amount of gvt
    /// @param amount Amount of token to burn
    function validGTokenIncrease(uint256 amount) private view returns (bool) {
        return
            gTokens[false].totalAssets().mul(utilisationRatioLimitPwrd).div(
                PERCENTAGE_DECIMAL_FACTOR
            ) >= amount.add(gTokens[true].totalAssets());
    }

    /// @notice Give a USD estimate of the deposit - this is purely used to determine deposit size
    ///     and does not impact amount of tokens minted
    /// @param inAmounts Amount of tokens deposited
    /// @param _decimals Decimals for token denoted in (10**X)
    function roughUsd(uint256[] memory inAmounts, uint256[] memory _decimals)
        private
        pure
        returns (uint256 usdAmount)
    {
        for (uint256 i; i < inAmounts.length; i++) {
            if (inAmounts[i] > 0) {
                usdAmount = usdAmount.add(inAmounts[i].mul(10**18).div(_decimals[i]));
            }
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

contract DecimalConstants {
    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IController.sol";
import "../interfaces/IPausable.sol";

contract Controllable is Ownable {
    address public controller;

    event ChangeController(address indexed oldController, address indexed newController);

    /// Modifier to make a function callable only when the contract is not paused.
    /// Requirements:
    /// - The contract must not be paused.
    modifier whenNotPaused() {
        require(!_pausable().paused(), "Pausable: paused");
        _;
    }

    /// Modifier to make a function callable only when the contract is paused
    /// Requirements:
    /// - The contract must be paused
    modifier whenPaused() {
        require(_pausable().paused(), "Pausable: not paused");
        _;
    }

    /// @notice Returns true if the contract is paused, and false otherwise
    function ctrlPaused() public view returns (bool) {
        return _pausable().paused();
    }

    function setController(address newController)
        external
        onlyOwner
    {
        require(newController != address(0), "setController: !0x");
        address oldController = controller;
        controller = newController;
        emit ChangeController(oldController, newController);
    }

    function _controller() internal view returns (IController) {
        require(controller != address(0), "Controller not set");
        return IController(controller);
    }

    function _pausable() internal view returns (IPausable) {
        require(controller != address(0), "Controller not set");
        return IPausable(controller);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IController {
    function stablecoins() external view returns (address[] memory);

    function stablecoinsCount() external view returns (uint256);

    function vaults() external view returns (address[] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function gvt() external view returns (address);

    function pwrd() external view returns (address);

    function reward() external view returns (address);

    function isBigFish(uint256 amount, bool _pwrd) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

// LP -> Liquidity pool token
interface ILifeGuard {
    function assets(uint256 i) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalAssetsUsd() external view returns (uint256);

    function availableUsd() external view returns (uint256 dollar);

    function availableLP() external view returns (uint256);

    function N_COINS() external view returns (uint256);

    function underlyingCoins(uint256 index) external view returns (address coin);

    function depositStable(bool rebalance) external returns (uint256);

    function investToCurveVault() external;

    function distributeCurveVault(uint256 amount, uint256[] memory delta)
        external
        returns (uint256[] memory);

    function deposit() external returns (uint256 usdAmount);

    function withdraw(uint256 inAmount, address recipient)
        external
        returns (uint256 usdAmount, uint256[] memory amounts);

    function withdrawSingleCoin(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function invest(uint256 whaleDepositAmount, uint256[] calldata delta)
        external
        returns (uint256 dollarAmount);

    function emergencyWithdrawal(uint256 token) external view returns (uint256, uint256);

    function getBuoy() external view returns (address);

    function investSingle(uint256[] calldata inAmounts, uint256 i, uint256 j)
        external
        returns (uint256 dollarAmount);

    function investToCurveVaultTrigger() external view returns (bool _invest);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import {ICurve3Pool} from "./ICurve.sol";
import "./IChainPrice.sol";

interface IBuoy {
    function safetyCheck() external view returns (bool);

    function decimals(uint256 index) external view returns (uint256 _decimals);

    function lpToUsd(uint256 inAmount) external view returns (uint256);

    function usdToLp(uint256 inAmount) external view returns (uint256);

    function getRatio(uint256 token0, uint256 token1) external view returns (uint256, uint256);

    function stableToUsd(uint256[] calldata inAmount, bool deposit)
        external
        view
        returns (uint256);

    function stableToLp(uint256[] calldata inAmount, bool deposit) external view returns (uint256);

    function singleStableFromLp(uint256 inAmount, int128 i) external view returns (uint256);

    function tokens(uint256 i) external view returns (address);

    function N_COINS() external view returns (uint256);

    function curvePool() external view returns (ICurve3Pool);

    function chainOracle() external view returns (IChainPrice);

    function getVirtualPrice() external view returns (uint256);

    function balancedCalculation(uint256 inAmount)
        external
        view
        returns (uint256[] memory outAmounts);

    function singleStableFromUsd(uint256 inAmount, int128 i) external view returns (uint256);

    function singleStableToUsd(uint256 inAmount, uint256 i) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface ICurve3Pool {

    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns(uint);

    function calc_token_amount(uint[3] calldata inAmounts, bool deposit) external view returns(uint);

    function balances(int128 i) external view returns(uint);
}

interface ICurve3Deposit {

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function add_liquidity(uint[3] calldata uamounts, uint min_mint_amount) external;

    function remove_liquidity(uint amount, uint[3] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_uamount) external;

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

interface ICurveMetaPool {

    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns(uint);

    function calc_token_amount(uint[2] calldata inAmounts, bool deposit) external view returns(uint);

    function balances(int128 i) external view returns(uint);
}

interface ICurveMetaDeposit {

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function add_liquidity(uint[2] calldata uamounts, uint min_mint_amount) external;

    function remove_liquidity(uint amount, uint[2] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_uamount) external;
}

interface ICurveZap {

    function add_liquidity(uint[4] calldata uamounts, uint min_mint_amount) external;

    function remove_liquidity(uint amount, uint[4] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_uamount) external;

    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns(uint);

    function calc_token_amount(uint[4] calldata inAmounts, bool deposit) external view returns(uint);

    function pool() external view returns(address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IChainPrice{

    function updateTokenRatios(address token) external; 

    function getRatio(uint i, uint j) external view returns (uint, uint);

    function priceUpdateCheck(address _token) external view returns (bool _priceCheck);

    function getPriceFeed(address _token) external view returns (uint _price); 
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IDepositHandler {
    function referral(address referee) external view returns (address);

    function depositGvt(
        uint256[] calldata inAmounts,
        uint256 minAmount,
        address _referral
    ) external;

    function depositPwrd(
        uint256[] calldata inAmounts,
        uint256 minAmount,
        address _referral
    ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IToken {
    function factor() external view returns (uint256);

    function factor(uint256 totalAssets) external view returns (uint256);

    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burnAll(address account) external;

    function totalAssets() external view returns (uint256);

    function getPricePerShare() external view returns (uint256);

    function getShareAssets(uint256 shares) external view returns (uint256);

    function getAssets(address account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IPnL {
    function calcPnL() external view returns (uint256, uint256);

    function pnlTrigger() external view returns (bool);

    function execPnL(uint256 deductedAssets) external;

    function increaseGTokenLastAmount(address gTokenAddress, uint256 dollarAmount) external;

    function decreaseGTokenLastAmount(address gTokenAddress, uint256 dollarAmount) external;

    function increaseWithdrawalBonus(uint256 newBonus) external;

    function lastGvtAssets() external view returns (uint256);

    function lastPwrdAssets() external view returns (uint256);

    function utilisationRatio() external view returns (uint256);

    function emergencyPnL() external;

    function recover() external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IInsurance {
    function calculateDepositDeltasOnAllVaults() external view returns (uint256[] memory);

    function rebalanceTrigger() external view returns (bool sysNeedRebalance);

    function rebalance() external;

    function calcSkim() external view returns (uint256);

    function rebalanceForWithdraw(uint256 withdrawUsd, bool pwrd) external;

    function getDelta(uint256 withdrawUsd) external view returns (uint256[] memory delta);

    function getVaultDelta(uint256 amount)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256
        );

    function getStrategiesTargetRatio() external view returns (uint256[] memory);

    function setUnderlyingTokenPercent(uint256 coinIndex, uint256 percent) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IVault {
    function withdraw(uint256 amount) external;

    function withdraw(uint256 amount, address recipient) external;

    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external;

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external;

    function deposit(uint256 amount) external;

    function updatePnL(uint256 amount) external;

    function updateStrategyRatio(uint256[] calldata strategyRetios) external;

    function execPnL() external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index, uint256 callCost) external returns (bool);

    function calcPnL() external view returns (uint256 gain, uint256 loss);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function vault() external view returns (address);

    function investTrigger() external view returns (bool);

    function invest() external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IERC20Detailed {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1337
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