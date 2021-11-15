//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "../interfaces/IVault.sol";
import "../interfaces/IRhoStrategy.sol";
import "../interfaces/IRhoToken.sol";
import "../interfaces/IPriceOracle.sol";
import "../libraries/flurry.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Vault is IVault, PausableUpgradeable, AccessControlEnumerableUpgradeable {
    using Flurry for *;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant REBASE_ROLE = keccak256("REBASE_ROLE");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE");

    uint256 private _rhoOne;
    uint256 private _underlyingOne;

    IRhoToken public override rhoToken;
    IERC20MetadataUpgradeable public override underlying;

    /**
     * @notice Flurry Price Oracle to give price feed for native currency
     * For example, ETH on Ethereum, BNB on Binance Smart Chain...
     * Default base = underlying token, quote = native currency
     */
    IPriceOracle public override underlyingNativePriceOracle;
    // 18 decimal
    uint256 public override mintingFee;
    // 18 decimal
    uint256 public override redeemFee;
    // 18 decimal
    uint256[2] public override reserveBoundary;
    uint256 public override managementFee;

    Strategy[] public strategies;
    address[] public strategyAddrs;

    uint256 public feeInRho;

    function initialize(
        address _rhoAddr,
        address _underlyingAddr,
        address _udlyNativePriceOracleAddr,
        uint256 _mFee,
        uint256 _rFee,
        uint256 _mngtFee,
        uint256 _rLowerBound,
        uint256 _rUpperBound
    ) public initializer {
        PausableUpgradeable.__Pausable_init();
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setMintingFee(_mFee);
        _setRedeemFee(_rFee);
        _setManagementFee(_mngtFee);
        _setReserveBoundary(_rLowerBound, _rUpperBound);
        _setRhoToken(_rhoAddr);
        _setUnderlying(_underlyingAddr);
        _setUnderlyingNativePriceOracle(_udlyNativePriceOracleAddr);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setUnderlyingNativePriceOracle(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setUnderlyingNativePriceOracle(addr);
    }

    function _setUnderlyingNativePriceOracle(address addr) internal {
        underlyingNativePriceOracle = IPriceOracle(addr);
    }

    function setMintingFee(uint256 _feeInWei) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setMintingFee(_feeInWei);
    }

    function _setMintingFee(uint256 _feeInWei) internal {
        mintingFee = _feeInWei;
    }

    /* redeem Fee */
    function setRedeemFee(uint256 _feeInWei) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setRedeemFee(_feeInWei);
    }

    function _setRedeemFee(uint256 _feeInWei) internal {
        redeemFee = _feeInWei;
    }

    function setManagementFee(uint256 _feeInWei) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setManagementFee(_feeInWei);
    }

    function _setManagementFee(uint256 _feeInWei) internal {
        managementFee = _feeInWei;
    }

    /* alloc threshold */
    function setReserveBoundary(uint256 reserveLowerBound_, uint256 reserveUpperBound_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        _setReserveBoundary(reserveLowerBound_, reserveUpperBound_);
    }

    function _setReserveBoundary(uint256 reserveLowerBound_, uint256 reserveUpperBound_) internal {
        reserveBoundary = [reserveLowerBound_, reserveUpperBound_];
    }

    /* underlying */
    function _setUnderlying(address _addr) internal {
        underlying = IERC20MetadataUpgradeable(_addr);
        _underlyingOne = 10**underlying.decimals();
    }

    function supportsAsset(address _asset) external view override returns (bool) {
        if (_asset == address(underlying)) {
            return true;
        }
        return false;
    }

    function reserve() external view override returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /* rho token */
    function _setRhoToken(address _addr) internal {
        rhoToken = RhoToken(_addr);
        _rhoOne = 10**rhoToken.decimals();
    }

    /* distribution */
    function mint(uint256 amount) external override whenNotPaused {
        underlying.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 amountInRho = (amount * _rhoOne) / _underlyingOne;
        rhoToken.mint(_msgSender(), amountInRho);
        return;
    }

    function redeem(uint256 amountInRho) external override whenNotPaused {
        uint256 amountInUnderlying = (amountInRho * _underlyingOne) / _rhoOne;
        // uint256 residue = amountInRho - amountInUnderlying * _rhoOne / _underlyingOne ;
        require(rhoToken.balanceOf(_msgSender()) > amountInRho, "");

        uint256 reserveBalance = underlying.balanceOf(address(this));

        if (reserveBalance >= amountInUnderlying) {
            rhoToken.burn(_msgSender(), amountInRho);
            // if (residue > 0) {
            //     // gas ? does it worth?
            //     _mintResidue(residue);
            // }
            underlying.safeTransfer(_msgSender(), amountInUnderlying);
            return;
        }
        // reserveBalance hit zero, unallocate to replenish reserveBalance to lower bound
        (uint256[] memory balance, bool[] memory locked, , ) = _updateStrategiesDetail();

        uint256 totalUnderlyingToBe = (rhoToken.totalSupply() * _underlyingOne) / _rhoOne - amountInUnderlying;

        uint256 amountToWithdraw = amountInUnderlying - reserveBalance + _calcReserveLowerBound(totalUnderlyingToBe); // in underlying

        for (uint256 i = 0; i < strategies.length; i++) {
            if (!strategies[i].enabled) continue;
            if (balance[i] > amountToWithdraw) {
                _withdraw(amountToWithdraw, i);
                if (locked[i]) {
                    strategies[i].target.switchingLock(strategies[i].target.switchingLockTarget() - amountToWithdraw);
                }
                break;
            } else {
                if (balance[i] == 0) {
                    continue;
                }
                _withdrawAll(i);
                if (locked[i]) {
                    strategies[i].target.switchingLock(strategies[i].target.switchingLockTarget() - balance[i]);
                }
                amountToWithdraw -= balance[i];
            }
        }
        rhoToken.burn(_msgSender(), amountInRho);
        underlying.safeTransfer(_msgSender(), amountInUnderlying);
    }

    // function _mintResidue(uint256 residue) internal {
    //     feeInRho += residue;
    //     rhoToken.mint(address(this), residue);
    // }
    /* asset management */
    function rebase() external override onlyRole(REBASE_ROLE) whenNotPaused {
        uint256 originalTvlInRho = rhoToken.totalSupply();
        if (originalTvlInRho == 0) {
            return;
        }
        // rebalance fund
        _rebalance();
        uint256 underlyingInvested = _getUnderlyingInvested();
        uint256 underlyingUninvested = underlying.balanceOf(address(this));
        uint256 currentTvlInUnderlying = underlyingUninvested + underlyingInvested;
        uint256 currentTvlInRho = (currentTvlInUnderlying * _rhoOne) / _underlyingOne;
        uint256 rhoRebasing = rhoToken.unadjustedRebasingSupply();
        uint256 rhoNonRebasing = rhoToken.nonRebasingSupply();

        if (rhoRebasing == 0) {
            // in this case, rhoNonRebasing = rho TotalSupply
            uint256 originalTvlInUnderlying = (originalTvlInRho * _underlyingOne) / _rhoOne;
            if (currentTvlInUnderlying > originalTvlInUnderlying) {
                // invested accrued interest
                // all the interest goes to the fee pool since no one is entitled for the interest.
                uint256 feeToMint = ((currentTvlInUnderlying - originalTvlInUnderlying) * _rhoOne) / _underlyingOne;
                rhoToken.mint(address(this), feeToMint);
                feeInRho += feeToMint;
            }
            return;
        }

        // from this point forward, rhoRebasing > 0
        if (currentTvlInRho == originalTvlInRho) {
            // no fees charged, multiplier does not change
            return;
        }
        if (currentTvlInRho < originalTvlInRho) {
            // this happens when fund is initially deployed to compound and get balance of underlying right away
            // strategy losing money, no fees will be charged
            uint256 _newM = ((currentTvlInRho - rhoNonRebasing) * 1e36) / rhoRebasing;
            rhoToken.setMultiplier(_newM);
            return;
        }
        uint256 fee36 = (currentTvlInRho - originalTvlInRho) * managementFee;
        uint256 fee18 = fee36 / 1e18;
        if (fee18 > 0) {
            // mint vault's fee18
            rhoToken.mint(address(this), fee18);
            feeInRho += fee18;
        }
        uint256 newM = ((currentTvlInRho * 1e18 - rhoNonRebasing * 1e18 - fee36) * 1e18) / rhoRebasing;
        rhoToken.setMultiplier(newM);
    }

    function rebalance() external override onlyRole(REBASE_ROLE) whenNotPaused {
        _rebalance();
    }

    function _rebalance() internal {
        _allInAllOut();
    }

    function _updateStrategiesDetail()
        internal
        returns (
            uint256[] memory,
            bool[] memory,
            uint256,
            uint256
        )
    {
        uint256 underlyingInvested = 0;
        uint256 underlyingDeployable = 0;

        bool[] memory locked = new bool[](strategies.length);
        uint256[] memory balance = new uint256[](strategies.length);

        uint256 underlyingUninvested = underlying.balanceOf(address(this));

        for (uint256 i = 0; i < strategies.length; i++) {
            if (!strategies[i].enabled) continue;
            balance[i] = strategies[i].target.updateBalanceOfUnderlying();
            underlyingInvested += balance[i];
            if (strategies[i].target.isLocked()) {
                locked[i] = true;
            } else {
                underlyingDeployable += balance[i];
            }
        }

        uint256 tvl = underlyingUninvested + underlyingInvested;
        uint256 upperBound = _calcReserveUpperBound(tvl);
        if (underlyingUninvested > upperBound) {
            uint256 lowerBound = _calcReserveLowerBound(tvl);
            underlyingDeployable += underlyingUninvested - lowerBound;
        }

        // optimal strategy? worst strategy?

        uint256 optimalRate = 0;
        uint256 optimalIndex = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            if (!strategies[i].enabled) continue;
            uint256 rate;
            if (strategies[i].target.isLocked()) {
                // locked fund is not counted in underlyingDeployable
                rate = strategies[i].target.effectiveSupplyRate(underlyingDeployable, true);
            } else {
                // locked fund is counted in underlyingDeployable, offset the deployable by its own balance
                rate = strategies[i].target.effectiveSupplyRate(underlyingDeployable - balance[i], true);
            }
            if (rate > optimalRate) {
                optimalRate = rate;
                optimalIndex = i;
            }
        }
        return (balance, locked, optimalIndex, underlyingDeployable);
    }

    function _allInAllOut() internal {
        uint256 gasused = 0;
        (uint256[] memory balance, bool[] memory locked, uint256 optimalIndex, uint256 underlyingDeployable) =
            _updateStrategiesDetail();

        for (uint256 i = 0; i < strategies.length; i++) {
            if (!strategies[i].enabled) continue;
            if (balance[i] == 0) continue;
            if (locked[i]) continue;
            // withdraw
            uint256 gas0 = gasleft();
            _withdrawAll(i);
            gasused += gas0 - gasleft();
        }

        uint256 deployAmount;
        if (locked[optimalIndex]) {
            // locked fund is not counted in underlyingDeployable
            deployAmount = underlyingDeployable;
        } else {
            // locked fund is counted in underlyingDeployable, offset the deployable by its own balance
            deployAmount = underlyingDeployable - balance[optimalIndex];
        }
        if (deployAmount == 0) {
            return;
        }
        uint256 gas1 = gasleft();
        _deploy(deployAmount, optimalIndex);
        gasused += gas1 - gasleft();
        uint256 nativePrice = underlyingNativePriceOracle.priceByQuoteSymbol(address(underlying));
        uint256 switchingCost = Flurry.calculateGasFee(nativePrice, gasused); // in 18
        uint256 switchingCostInUnderlying = (switchingCost * _underlyingOne) / 1e18;
        uint256 newLockTarget = 0;
        if (locked[optimalIndex]) {
            newLockTarget =
                deployAmount +
                switchingCostInUnderlying +
                strategies[optimalIndex].target.switchingLockTarget();
        } else {
            newLockTarget = deployAmount + switchingCostInUnderlying;
        }
        strategies[optimalIndex].target.switchingLock(newLockTarget);
    }

    function _getUnderlyingInvested() internal returns (uint256) {
        uint256 underlyingInvested;
        for (uint256 i = 0; i < strategies.length; i++) {
            if (!strategies[i].enabled) continue;
            uint256 balance = strategies[i].target.updateBalanceOfUnderlying();
            underlyingInvested += balance;
        }
        return underlyingInvested;
    }

    // calculates underlying reserve at upper bound based on a rho total supply
    function _calcReserveUpperBound(uint256 tvl) internal view returns (uint256) {
        return ((tvl * reserveBoundary[1]) / 1e18);
    }

    // calculates underlying reserve at lower bound based on a rho total supply
    function _calcReserveLowerBound(uint256 tvl) internal view returns (uint256) {
        return ((tvl * reserveBoundary[0]) / 1e18);
    }

    function _withdraw(uint256 amount, uint256 from) internal {
        strategies[from].target.withdrawUnderlying(amount);
    }

    function _withdrawAll(uint256 from) internal {
        strategies[from].target.withdrawAll();
    }

    function _deploy(uint256 amount, uint256 to) internal {
        underlying.safeTransfer(address(strategies[to].target), amount);
        strategies[to].target.deploy(amount);
    }

    function addStrategy(
        string memory name,
        address s,
        bool enabled
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        strategies.push(Strategy(name, IRhoStrategy(s), enabled));
        strategyAddrs.push(s);
    }

    function isStrategyRegistered(address s) external view override returns (bool) {
        for (uint256 i = 0; i < strategyAddrs.length; i++) {
            if (strategyAddrs[i] == s) return true;
        }
        return false;
    }

    function disableStrategy(uint256 index) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        strategies[index].enabled = false;
    }

    function enableStrategy(uint256 index) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        strategies[index].enabled = true;
    }

    /* pause */
    function pause() external onlyRole(PAUSE_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    // withdraw random token transfer into this contract
    function sweepERC20Token(address token, address to) external override onlyRole(SWEEPER_ROLE) whenNotPaused {
        require(token != address(underlying), "!safe");
        IERC20Upgradeable tokenToSweep = IERC20Upgradeable(token);
        tokenToSweep.transfer(to, tokenToSweep.balanceOf(address(this)));
    }

    function sweepRhoTokenContractERC20Token(address token, address to)
        external
        override
        onlyRole(SWEEPER_ROLE)
        whenNotPaused
    {
        rhoToken.sweepERC20Token(token, to);
    }

    function supplyRate() external view returns (uint256) {
        uint256 totalInterestPerYear = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            if (!strategies[i].enabled) continue;
            totalInterestPerYear +=
                strategies[i].target.balanceOfUnderlying() *
                strategies[i].target.effectiveSupplyRate();
        }
        uint256 rebasingSupply = rhoToken.unadjustedRebasingSupply(); // in 18
        if (rebasingSupply == 0) return type(uint256).max;
        return (totalInterestPerYear * _rhoOne) / rebasingSupply / _underlyingOne;
    }

    function getStrategiesList() external view returns (Strategy[] memory) {
        return strategies;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../tokens/RhoToken.sol";
import "../interfaces/IPriceOracle.sol";
import "./IRhoStrategy.sol";

interface IVault {
    struct Strategy {
        string name;
        IRhoStrategy target;
        bool enabled;
    }
    struct VaultSupplyRateDetail {
        uint256 APY;
        StrategySupplyRateDetail[] strategies;
    }
    struct StrategySupplyRateDetail {
        string name;
        uint256 APY;
    }

    function underlyingNativePriceOracle() external view returns (IPriceOracle);

    function setUnderlyingNativePriceOracle(address addr) external;

    /**
     * @dev getter function for cash reserve
     * @return return cash reserve balance (in underlying) for vault
     */
    function reserve() external view returns (uint256);

    /**
     * @dev Getter function for Rho token minting fee
     * @return Return the minting fee (in bps)
     */
    function mintingFee() external view returns (uint256);

    /**
     * @dev Setter function for minting fee (in bps)
     */
    function setMintingFee(uint256 _feeInBps) external;

    /**
     * @dev Getter function for Rho token redemption fee
     * @return Return the redeem fee (in bps)
     */
    function redeemFee() external view returns (uint256);

    /**
     * @dev Setter function for Rho token redemption fee
     */
    function setRedeemFee(uint256 _feeInBps) external;

    /**
     * @dev set the allocation threshold (denominated in underlying asset)
     */
    function setReserveBoundary(uint256 _lowerBound, uint256 _upperBound) external;

    /**
     * @dev Getter function for allocation lowerbound and upperbound
     */
    function reserveBoundary(uint256 index) external view returns (uint256);

    /**
     * Each Vault currently only supports one underlying asset
     * @return Returns the contract address of the underlying asset
     */
    function underlying() external view returns (IERC20MetadataUpgradeable);

    /**
     * @return True if the asset is supported by this vault
     */
    function supportsAsset(address _asset) external view returns (bool);

    /**
     * @return Returns the address of the Rho token contract
     */
    function rhoToken() external view returns (IRhoToken);

    /**
     * @dev function that trigggers the distribution of interest earned to Rho token holders
     */
    function rebase() external;

    /**
     * @dev function that trigggers allocation and unallocation of funds based on reserve pool bounds
     */
    function rebalance() external;

    /**
     * @dev Add strategy object which implments the IRhoStrategy interface to the vault
     */
    function addStrategy(
        string memory name,
        address at,
        bool enabled
    ) external;

    /**
     * @dev Check if a strategy is registered
     * @param s address of strategy contract
     * @return boolean
     */
    function isStrategyRegistered(address s) external view returns (bool);

    /**
     * @dev Disable a strategy from the vaule
     * Before a strategy can be disabled, withdrawAll() should be called to liquidate and remove all funds from the strategy
     */
    function disableStrategy(uint256 index) external;

    function enableStrategy(uint256 index) external;

    /**
     * @dev function to mint RhoToken
     * @param amount amount in underlying stablecoin
     */
    function mint(uint256 amount) external;

    /**
     * @dev function to redeem RhoToken
     * @param amount amount of rhoTokens to be redeemed
     */
    function redeem(uint256 amount) external;

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function sweepRhoTokenContractERC20Token(address token, address to) external;

    function setManagementFee(uint256 _feeInBps) external;

    function managementFee() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./uniswap/IUniswapV2Router02.sol";

/**
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoStrategy {
    /**
     * Events
     */
    event WithdrawAll();
    event WithdrawUnderlying(uint256 amount);
    event Deploy(uint256 amount);

    /**
     * @dev  name of Protocol
     */

    function NAME() external view returns (string memory);

    function BLOCK_PER_YEAR() external view returns (uint256);

    /**
     * @dev the underlying token
     */
    function underlying() external view returns (IERC20MetadataUpgradeable);

    /**
     * @dev unlock when TVL exceed the this target
     */
    function switchingLockTarget() external view returns (uint256);

    /**
     * @dev duration of which the strategy is locked
     */
    function switchLockDuration() external view returns (uint256);

    /**
     * @dev unlock after this block
     */
    function switchLockedUntil() external view returns (uint256);

    /**
     * @dev setter of switchLockDuration
     */
    function setSwitchLockDuration(uint256 durationInBlock) external;

    /**
     * @dev lock the strategy with a lock target
     */
    function switchingLock(uint256 lockTarget) external;

    /**
     * @dev Deploy the underlying to DeFi platform
     */
    function balanceOfUnderlying() external view returns (uint256);

    /**
     * @dev Deploy the underlying to DeFi platform
     */
    function deploy(uint256 _amount) external;

    /**
     * @notice current supply rate per block excluding bonus token (such as Aave / Comp)
     * @dev Returns the current going supply rate per block available for the given underlying stablecoin
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice current bonus supply rate (such as Aave / Comp)
     * @dev Returns the current going bonus supply rate
     */
     function bonusSupplyRate() external view returns (uint256);

    /**
     * @notice current supply rate excluding bonus token (such as Aave / Comp)
     * @dev Returns the current going supply rate available for the given underlying stablecoin
     */
    function supplyRate() external view returns (uint256);

    /**
     * @notice current effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens
     * @return supply rate (in wei)
     */
    function effectiveSupplyRate() external view returns (uint256);

    /**
     * @notice current effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens AND the change in balance.
     * if balanceOffset >= current balance, returns the effective supply rate
     * as if balance is 0.
     * @return supply rate (in wei)
     */
    function effectiveSupplyRate(uint256 delta, bool isPositive) external view returns (uint256);

    /**
     * @dev Withdraw the amount in underlying from DeFi platform
     */
    function withdrawUnderlying(uint256 _amount) external;

    /**
     * @dev Withdraw all deployed assets and return them to vault
     */
    function withdrawAll() external;

    /**
     * @dev Return the updated balance of the underlying asset
     */
    function updateBalanceOfUnderlying() external returns (uint256);

    /**
     * @dev Collect any bonus reward tokens available for the strategy
     */
    function collectRewardToken() external;

    /**
     * @dev The threshold (denominated in reward tokens) over which rewards tokens will automatically
     * be converted into the underlying asset
     */
    function rewardConversionThreshold() external view returns (uint256);

    /**
     * @dev Set the threshold (denominated in reward tokens) over which rewards tokens will automatically
     * be converted into the underlying asset
     */
    function setRewardConversionThreshold(uint256 _threshold) external;

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function isLocked() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoToken is IERC20MetadataUpgradeable {
    event MultiplierChange(uint256 to);

    /**
     * @dev adjusted supply is multiplied by multiplier from rebasing
     * @return issued amount of rhoToken that is rebasing
     * Total supply = adjusted rebasing supply + non-rebasing supply
     * Adjusted rebasing supply = unadjusted rebasing supply * multiplier
     */
    function adjustedRebasingSupply() external view returns (uint256);

    /**
     * @dev unadjusted supply is NOT multiplied by multiplier from rebasing
     * @return internally stored amount of rhoTokens that is rebasing
     */
    function unadjustedRebasingSupply() external view returns (uint256);

    /**
     * @return issued amount of rhoTokens that is non-rebasing
     */
    function nonRebasingSupply() external view returns (uint256);

    /**
     * @notice The multiplier is set during a rebase
     * @param multiplier - scaled by 1e36
     */
    function setMultiplier(uint256 multiplier) external;

    /**
     * @return multiplier - returns the muliplier of the rhoToken, scaled by 1e36
     * @return lastUpdate - last update time of the multiplier, equivalent to last rebase time
     */
    function getMultiplier() external view returns (uint256 multiplier, uint256 lastUpdate);

    /**
     * @notice function to mint rhoTokens - callable only by owner
     * @param account account for sending new minted tokens to
     * @param amount amount of tokens to be minted
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice function to burn rhoTokens - callable only by owner
     * @param account the account address for burning tokens from
     * @param amount amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice switches the account type of `msg.sender` between rebasing and non-rebasing
     * @param isRebasing true if setting to rebasing, false if setting to non-rebasing
     * NOTE: this function does nothing if caller is already in the same option
     */
    function setRebasingOption(bool isRebasing) external;

    /**
     * @param account address of account to check
     * @return true if `account` is a rebasing account
     */
    function isRebasingAccount(address account) external view returns (bool);

    /**
     * @notice Admin function - set reference token rewards contract
     * @param tokenRewards token rewards contract address
     */
    function setTokenRewards(address tokenRewards) external;

    /**
     * @notice Admin function to sweep ERC20s (other than rhoToken) accidentally sent to this contract
     * @param token token contract address
     * @param to which address to send sweeped ERC20s to
     */
    function sweepERC20Token(address token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPriceOracle {
    /**
     * @return decimals of the "baseSymbol / quoteSymbol" rate
     */
    function decimals() external view returns (uint8);

    /**
     * @return name of the token pair, in the form of "baseSymbol / quoteSymbol"
     */
    function description() external view returns (string memory);

    /**
     * @return name of the base symbol
     */
    function baseSymbol() external view returns (string memory);

    /**
     * @return name of the quote symbol
     */
    function quoteSymbol() external view returns (string memory);

    /**
     * @return address of the base symbol, zero address if `baseSymbol` is USD
     */
    function baseAddr() external view returns (address);

    /**
     * @return address of the quote symbol, zero address if `baseSymbol` is USD
     */
    function quoteAddr() external view returns (address);

    /**
     * @return updateAt timestamp of the last update as seconds since unix epoch
     */
    function lastUpdate() external view returns (uint256 updateAt);

    /**
     * @param _baseAddr address of the base symbol
     * @return the price feed in `decimals`, or type(uint256).max if the rate is invalid
     * Example: priceFeed() == 2e18
     *          => 1 baseSymbol = 2 quoteSymbol
     */
    function price(address _baseAddr) external view returns (uint256);

    /**
     * @param _quoteAddr address of the quote symbol
     * @return the price feed in `decimals`, or type(uint256).max if the rate is invalid
     */
    function priceByQuoteSymbol(address _quoteAddr) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "../interfaces/chainlink/AggregatorV3Interface.sol";

library Flurry {
    function calculateGasFee(uint256 ethpriceIn18, uint256 gasused) internal view returns (uint256) {
        return (gasused * tx.gasprice * ethpriceIn18) / 1e18;
    }

    function quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IRhoTokenRewards.sol";
import "../interfaces/IRhoToken.sol";

contract RhoToken is OwnableUpgradeable, ERC20Upgradeable, IRhoToken {
    using AddressUpgradeable for address;

    /**
     * @dev internally stored without any multiplier
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev rebase option will be set when user calls setRebasingOption()
     * default is UNKNOWN, determined by EOA/contract type
     */
    enum RebaseOption {UNKNOWN, REBASING, NON_REBASING}

    /**
     * @dev this mapping is valid only for addresses that have already changed their options.
     * To query an account's rebase option, call `isRebasingAccount()` externally
     * or `isRebasingAccountInternal()` internally.
     */
    mapping(address => RebaseOption) private _rebaseOptions;

    uint256 private _rebasingTotalSupply;
    uint256 private _nonRebasingTotalSupply;

    uint256 private constant ONE = 1e36;
    uint256 private multiplier;
    address public tokenRewardsAddress;
    uint256 public lastUpdateTime;

    function __initialize(string memory name_, string memory symbol_) public initializer {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        OwnableUpgradeable.__Ownable_init();
        _setMultiplier(ONE);
    }

    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return _timesMultiplier(_rebasingTotalSupply) + _nonRebasingTotalSupply;
    }

    function adjustedRebasingSupply() external view override returns (uint256) {
        return _timesMultiplier(_rebasingTotalSupply);
    }

    function unadjustedRebasingSupply() external view override returns (uint256) {
        return _rebasingTotalSupply;
    }

    function nonRebasingSupply() external view override returns (uint256) {
        return _nonRebasingTotalSupply;
    }

    function balanceOf(address account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        if (isRebasingAccountInternal(account)) {
            return _timesMultiplier(_balances[account]);
        }
        return _balances[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override updateTokenRewards(sender) updateTokenRewards(recipient) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        // deducting from sender
        uint256 amountToDeduct = amount;
        if (isRebasingAccountInternal(sender)) {
            amountToDeduct = _dividedByMultiplier(amount);
            require(_balances[sender] >= amountToDeduct, "ERC20: transfer amount exceeds balance");
            _rebasingTotalSupply -= amountToDeduct;
        } else {
            require(_balances[sender] >= amountToDeduct, "ERC20: transfer amount exceeds balance");
            _nonRebasingTotalSupply -= amountToDeduct;
        }
        _balances[sender] -= amountToDeduct;
        // adding to recipient
        uint256 amountToAdd = amount;
        if (isRebasingAccountInternal(recipient)) {
            amountToAdd = _dividedByMultiplier(amount);
            _rebasingTotalSupply += amountToAdd;
        } else {
            _nonRebasingTotalSupply += amountToAdd;
        }
        _balances[recipient] += amountToAdd;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal override updateTokenRewards(account) {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        uint256 amountToAdd = amount;
        if (isRebasingAccountInternal(account)) {
            amountToAdd = _dividedByMultiplier(amount);
            _rebasingTotalSupply += amountToAdd;
        } else {
            _nonRebasingTotalSupply += amountToAdd;
        }
        _balances[account] += amountToAdd;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override updateTokenRewards(account) {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);
        uint256 amountToDeduct = amount;
        if (isRebasingAccountInternal(account)) {
            amountToDeduct = _dividedByMultiplier(amount);
            require(_balances[account] >= amountToDeduct, "ERC20: burn amount exceeds balance");
            _rebasingTotalSupply -= amountToDeduct;
        } else {
            require(_balances[account] >= amountToDeduct, "ERC20: burn amount exceeds balance");
            _nonRebasingTotalSupply -= amountToDeduct;
        }
        _balances[account] -= amountToDeduct;
        emit Transfer(account, address(0), amount);
    }

    /* multiplier */
    function setMultiplier(uint256 multiplier_) external override onlyOwner updateTokenRewards(address(0)) {
        _setMultiplier(multiplier_);
        emit MultiplierChange(multiplier_);
    }

    function _setMultiplier(uint256 multiplier_) internal {
        multiplier = multiplier_;
        lastUpdateTime = block.timestamp;
    }

    function getMultiplier() external view override returns (uint256 _multiplier, uint256 _lastUpdateTime) {
        _multiplier = multiplier;
        _lastUpdateTime = lastUpdateTime;
    }

    function mint(address account, uint256 amount) external override onlyOwner updateTokenRewards(account) {
        require(amount > 0, "amount must be greater than zero");
        return _mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyOwner updateTokenRewards(account) {
        require(amount > 0, "amount must be greater than zero");
        return _burn(account, amount);
    }

    /* utils */
    /* think of a way to group this in a library */
    function _timesMultiplier(uint256 input) internal view returns (uint256) {
        return (input * multiplier) / ONE;
    }

    function _dividedByMultiplier(uint256 input) internal view returns (uint256) {
        return (input * ONE) / multiplier;
    }

    function setRebasingOption(bool isRebasing) external override {
        if (isRebasingAccountInternal(_msgSender()) == isRebasing) {
            return;
        }
        uint256 userBalance = _balances[_msgSender()];
        if (isRebasing) {
            _rebaseOptions[_msgSender()] = RebaseOption.REBASING;
            _nonRebasingTotalSupply -= userBalance;
            _rebasingTotalSupply += _dividedByMultiplier(userBalance);
            _balances[_msgSender()] = _dividedByMultiplier(userBalance);
        } else {
            _rebaseOptions[_msgSender()] = RebaseOption.NON_REBASING;
            _rebasingTotalSupply -= userBalance;
            _nonRebasingTotalSupply += _timesMultiplier(userBalance);
            _balances[_msgSender()] = _timesMultiplier(userBalance);
        }
    }

    function isRebasingAccountInternal(address account) internal view returns (bool) {
        return
            (_rebaseOptions[account] == RebaseOption.REBASING) ||
            (_rebaseOptions[account] == RebaseOption.UNKNOWN && !account.isContract());
    }

    function isRebasingAccount(address account) external view override returns (bool) {
        return isRebasingAccountInternal(account);
    }

    /* token rewards */
    function setTokenRewards(address tokenRewards) external override onlyOwner {
        tokenRewardsAddress = tokenRewards;
    }

    // withdraw random token transfer into this contract
    function sweepERC20Token(address token, address to) external override onlyOwner {
        IERC20Upgradeable tokenToSweep = IERC20Upgradeable(token);
        tokenToSweep.transfer(to, tokenToSweep.balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */
    modifier updateTokenRewards(address account) {
        if (tokenRewardsAddress != address(0)) {
            IRhoTokenRewards(tokenRewardsAddress).updateReward(account, address(this));
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RhoToken Rewards Interface
 * @notice Interface for bonus FLURRY token rewards contract for RhoToken holders
 */
interface IRhoTokenRewards {
    /**
     * @notice checks whether a LP token is supported for staking
     * @param rhoToken address of LP Token contract
     * @return true if staking is supported for LP Token
     */
    function isSupported(address rhoToken) external returns (bool);

    /**
     * @return list of addresses of rhoTokens registered in this contract
     */
    function getRhoTokenList() external view returns (address[] memory);

    /**
     * @return reward rate for all rhoTokens earned per block
     */
    function rewardRate() external view returns (uint256);

    /**
     * @notice Admin function - set reward rate for all rhoTokens earned per block
     * @param newRewardRate - reward rate per block (number of FLURRY in wei)
     */
    function setRewardRate(uint256 newRewardRate) external;

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param user The stakeholder to check rewards for.
     * @param rhoToken Address of rhoToken contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address rhoToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all rhoToken
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    // function setRewardSpeed(uint256 flurrySpeed) public

    /**
     * @notice Total accumulated reward per token
     * @param rhoToken Address of rhoToken contract
     * @return Reward entitlement for rho token
     */
    function rewardsPerToken(address rhoToken) external view returns (uint256);

    /**
     * @notice current reward rate per token staked
     * @param rhoToken Address of rhoToken contract
     * @return reward rate denominated in FLURRY per block
     */
    function rewardRatePerRhoToken(address rhoToken) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param rhoToken Address of rhoToken contract
     * @param rewardDuration Reward duration in number of blocks
     */
    function startRewards(address rhoToken, uint256 rewardDuration) external;

    /**
     * @notice A method to get reward end block for a rhoToken
     * @param rhoToken Address of RHoToken contract
     */
    function getRewardsEndBlock(address rhoToken) external view returns (uint256);

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     * @param rhoToken Address of rhoToken contract
     */
    function endRewards(address rhoToken) external;

    /**
     * @notice Calculate and allocate rewards token for address holder
     * Rewards should accrue from _lastUpdateBlock to lastBlockApplicable
     * rewardsPerToken is based on the total supply of the RhoToken, hence
     * this function needs to be called every time total supply changes
     * @param user the user to update reward for
     * @param rhoToken the rhoToken to update reward for
     */
    function updateReward(address user, address rhoToken) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for one rhoToken
     * @param rhoToken Address of rhoToken contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address rhoToken) external;

    /**
     * @notice A method to allow staking rewards contract to claim rewards on behalf of users
     * @param user address of the user (NOT msg.sender, the immediate caller)
     * @param rhoToken Address of rhoToken contract
     */
    function claimReward(address user, address rhoToken) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for all rhoTokens
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward() external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for all rhoTokens
     * @param user address of the user (NOT msg.sender, the immediate caller)
     */
    function claimAllReward(address user) external;

    /**
     * @notice Admin function - register a rhoToken to this contract
     * @param rhoToken address of the rhoToken to be registered
     * @param allocPoint allocation points (weight) assigned to the given rhoToken
     */
    function addRhoToken(address rhoToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - change the allocation points of a rhoToken registered in this contract
     * @param rhoToken address of the rhoToken subject to change
     * @param allocPoint allocation points (weight) assigned to the given rhoToken
     */
    function setRhoToken(address rhoToken, uint256 allocPoint) external;

    /**
     * Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
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
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

