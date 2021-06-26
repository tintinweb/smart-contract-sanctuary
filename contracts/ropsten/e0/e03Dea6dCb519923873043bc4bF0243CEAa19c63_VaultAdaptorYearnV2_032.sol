// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./IYearnV2Strategy.sol";
import "../../BaseVaultAdaptor.sol";

/// @notice YearnV2Vault adaptor - Implementation of the gro protocol vault adaptor used to
///     interact with Yearn v2 vaults. Gro protocol uses a modified version of the yearnV2Vault
///     to accomodate for additional functionality (see Vault.vy):
///         - Adaptor modifier:
///             Withdraw/Deposit methods can only be accessed by the vaultAdaptor
///         - Withdraw by StrategyOrder/Index:
///             In order to be able to ensure that protocol exposures are within given thresholds
///             inside the vault, the vault can now withdraw from the vault (underlying strategies)
///             by a specific strategy or order of strategies. The orginal yearnV2Vault has a set
///             withdrawalQueue.
///         - The vault adaptor now acts as the first withdraw layer. This means that the adaptor,
///             will always try to maintain a set amount of loose assets to make withdrawals cheaper.
///             The underlying yearn vault on the other hand will always have a total debt ratio of
///             100%, meaning that it will atempt to always have all its assets invested in the
///             underlying strategies.
///         - Asset availability:
///             - VaultAdaptor:
///                 - vaultReserve (%BP - see BaseVaultAdaptor)
///             - Vault:
///                 - target debt ratio => 100% (10000)
///                 - loose assets cannot be guranteed
///                     - after a vaultAdaptor invest action assets will be available
///                     - after each strategy has called harvest no assets should be available
contract VaultAdaptorYearnV2_032 is BaseVaultAdaptor {
    constructor(address _vault, address _token) public BaseVaultAdaptor(_vault, _token) {}

    /// @notice Withdraw from vault adaptor, if withdrawal amount exceeds adaptors
    ///     total available assets, withdraw from underlying vault, using a specific
    ///     strategy order for withdrawal -> the withdrawal order dictates which strategy
    ///     to withdraw from first, if this strategies assets are exhausted before the
    ///     withdraw amount has been covered, the ramainder will be withdrawn from the next
    ///     strategy in the list.
    /// @param share Number of shares to withdraw (yVault shares)
    /// @param recipient Recipient of withdrawal
    /// @param pwrd Pwrd or gvt
    function _withdrawByStrategyOrder(
        uint256 share,
        address recipient,
        bool pwrd
    ) internal override returns (uint256) {
        if (pwrd) {
            address[MAX_STRATS] memory _strategies;
            for (uint256 i = strategiesLength; i > 0; i--) {
                _strategies[i - 1] = IYearnV2Vault(vault).withdrawalQueue((strategiesLength - i));
            }
            return IYearnV2Vault(vault).withdrawByStrategy(_strategies, share, recipient, 1);
        } else {
            return _withdraw(share, recipient);
        }
    }

    /// @notice Withdraw from vault adaptor, if withdrawal amount exceeds adaptors,
    ///     withdraw from a specific strategy
    /// @param share Number of shares to withdraw (yVault shares)
    /// @param recipient Recipient of withdrawal
    /// @param index Index of strategy
    function _withdrawByStrategyIndex(
        uint256 share,
        address recipient,
        uint256 index
    ) internal override returns (uint256) {
        if (index != 0) {
            address[MAX_STRATS] memory _strategies;
            uint256 strategyIndex = 0;
            _strategies[strategyIndex] = IYearnV2Vault(vault).withdrawalQueue(index);
            for (uint256 i = 0; i < strategiesLength; i++) {
                if (i == index) {
                    continue;
                }
                strategyIndex++;
                _strategies[strategyIndex] = IYearnV2Vault(vault).withdrawalQueue(i);
            }
            return IYearnV2Vault(vault).withdrawByStrategy(_strategies, share, recipient, 0);
        } else {
            return _withdraw(share, recipient);
        }
    }

    /// @notice Deposit from vault adaptors to underlying vaults
    /// @param _amount Amount to deposit
    function depositToUnderlyingVault(uint256 _amount) internal override {
        if (_amount > 0) {
            IYearnV2Vault(vault).deposit(_amount, address(this));
        }
    }

    function _strategyHarvest(uint256 index) internal override {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        IYearnV2Strategy(yearnVault.withdrawalQueue(index)).harvest();
    }

    /// @notice Set debt ratio of underlying strategies to 0
    function resetStrategyDeltaRatio() private {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        for (uint256 i = 0; i < strategiesLength; i++) {
            yearnVault.updateStrategyDebtRatio(yearnVault.withdrawalQueue(i), 0);
        }
    }

    function updateStrategiesDebtRatio(uint256[] memory ratios) internal override {
        uint256 ratioTotal = 0;
        for (uint256 i = 0; i < ratios.length; i++) {
            ratioTotal = ratioTotal.add(ratios[i]);
        }
        require(ratioTotal <= 10**4, "The total of ratios is more than 10000");

        resetStrategyDeltaRatio();

        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        for (uint256 i = 0; i < ratios.length; i++) {
            yearnVault.updateStrategyDebtRatio(yearnVault.withdrawalQueue(i), ratios[i]);
        }
    }

    /// @notice Return debt ratio of underlying strategies
    function getStrategiesDebtRatio() internal view override returns (uint256[] memory ratios) {
        ratios = new uint256[](strategiesLength);
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        StrategyParams memory strategyParam;
        for (uint256 i; i < strategiesLength; i++) {
            strategyParam = yearnVault.strategies(yearnVault.withdrawalQueue(i));
            ratios[i] = strategyParam.debtRatio;
        }
    }

    function _strategyHarvestTrigger(uint256 index, uint256 callCost) internal view override returns (bool) {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        return IYearnV2Strategy(yearnVault.withdrawalQueue(index)).harvestTrigger(callCost);
    }

    function getStrategyEstimatedTotalAssets(uint256 index) internal view override returns (uint256) {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        return IYearnV2Strategy(yearnVault.withdrawalQueue(index)).estimatedTotalAssets();
    }

    function getStrategyTotalAssets(uint256 index) internal view override returns (uint256) {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        StrategyParams memory strategyParam = yearnVault.strategies(yearnVault.withdrawalQueue(index));
        return strategyParam.totalDebt;
    }

    function _withdraw(uint256 share, address recipient) internal override returns (uint256 withdrawalAmount) {
        (, , withdrawalAmount, ) = IYearnV2Vault(vault).withdraw(share, recipient, 1);
    }

    function vaultTotalAssets() internal view override returns (uint256) {
        return IYearnV2Vault(vault).totalAssets();
    }

    function _getVaultSharePrice() internal view override returns (uint256) {
        return IYearnV2Vault(vault).pricePerShare();
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IYearnV2Strategy {
    function vault() external view returns (address);

    function setVault(address _vault) external;

    function keeper() external view returns (address);

    function setKeeper(address _keeper) external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amount) external;

    function estimatedTotalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./yearnv2/v032/IYearnV2Vault.sol";
import "../common/Controllable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IController.sol";
import "../common/Constants.sol";
import "../interfaces/IERC20Detailed.sol";
import "../common/Whitelist.sol";

/// @notice Base contract for gro protocol vault adaptors - Vault adaptors act as a
///     layer between the protocol and any yield aggregator vault. They provides additional
///     functionality needed by the protocol, and allow the protocol to be agnostic
///     to the type of underlying vault it interacts with.
///
///     ###############################################
///     Base Vault Adaptor specifications
///     ###############################################
///
///     Any deposit/withdrawal into the system will always attempt to interact with the
///     appropriate vault adaptor (depending on token).
///     - Deposit: A deposit will move assets into the vault adaptor, which will be
///         available for investment into the underlying vault once a large enough amount
///         of assets has amassed in the vault adaptor.
///     - Withdrawal: A withdrawal will always attempt to pull from the vaultAdaptor if possible,
///         if the assets in the adaptor fail to cover the withdrawal, the adaptor will
///         attempt to withdraw assets from the underlying vaults strategies. The latter will
///         also depend on whether pwrd or gvt is being withdrawn, as strategy assets affect
///         system exposure levels.
///     - Invest: Once a significant amount of assets have amassed in the vault adaptor, the
///         invest trigger will signal that the adaptor is ready to invest assets. The adaptor
///         always aims to hold a percent of total assets as univested assets (vaultReserve).
///         This allows for smaller withdrawals to be cheaper as they dont have to interact with
///         the underlying strategies.
///     - Debt ratios: Ratio in %BP of assets to invest in the underlying strategies of a vault
abstract contract BaseVaultAdaptor is Controllable, Constants, Whitelist, IVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant MAX_STRATS = 20;

    // Underlying token
    address public immutable override token;
    uint256 public immutable decimals;
    // Underlying vault
    address public immutable override vault;
    // Number of strategies
    uint256 public strategiesLength;
    // Used to determine if its OK to invest assets to underlying vault
    uint256 public investThreshold;
    // Used to establish if the strategy debt ratios need to be updated
    uint256 public strategyRatioBuffer;
    // How much of total assets should be held in the vault adaptor (%BP)
    uint256 public vaultReserve;

    event LogAdaptorToken(address token);
    event LogAdaptorVault(address vault);
    event LogAdaptorReserve(uint256 reserve);
    event LogAdaptorStrategies(uint256 length);
    event LogNewAdaptorInvestThreshold(uint256 threshold);
    event LogNewAdaptorStrategyBuffer(uint256 buffer);
    event LogNewDebtRatios(uint256[] strategyRetios);
    event LogMigrate(address parent, address child, uint256 amount);

    /// @notice Only the underlying vault is allowed to call
    modifier onlyVault() {
        require(msg.sender == vault);
        _;
    }

    constructor(address _vault, address _token) public {
        vault = _vault;
        token = _token;
        decimals = IERC20Detailed(_token).decimals();
        IERC20(_token).safeApprove(address(_vault), 0);
        IERC20(_token).safeApprove(address(_vault), type(uint256).max);
    }

    function setVaultReserve(uint256 reserve) external onlyOwner {
        require(reserve <= PERCENTAGE_DECIMAL_FACTOR);
        vaultReserve = reserve;
        emit LogAdaptorReserve(reserve);
    }

    function setStrategiesLength(uint256 _strategiesLength) external onlyOwner {
        strategiesLength = _strategiesLength;
        emit LogAdaptorStrategies(_strategiesLength);
    }

    function setInvestThreshold(uint256 _investThreshold) external onlyOwner {
        investThreshold = _investThreshold;
        emit LogNewAdaptorInvestThreshold(_investThreshold);
    }

    function setStrategyRatioBuffer(uint256 _strategyRatioBuffer) external onlyOwner {
        strategyRatioBuffer = _strategyRatioBuffer;
        emit LogNewAdaptorStrategyBuffer(_strategyRatioBuffer);
    }

    /// @notice Determine if assets should be moved from the vault adaptors into the underlying vault
    function investTrigger() external view override returns (bool) {
        uint256 vaultHold = _totalAssets().mul(vaultReserve).div(PERCENTAGE_DECIMAL_FACTOR);
        uint256 _investThreshold = investThreshold.mul(uint256(10)**decimals);
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance < _investThreshold) {
            return false;
        } else if (balance.sub(_investThreshold) > vaultHold) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice Move assets from vault adaptor into the underlying vault
    function invest() external override onlyWhitelist {
        uint256 vaultHold = _totalAssets().mul(vaultReserve).div(PERCENTAGE_DECIMAL_FACTOR);
        uint256 _investThreshold = investThreshold.mul(uint256(10)**decimals);
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance <= vaultHold) return;

        if (balance.sub(vaultHold) > _investThreshold) {
            depositToUnderlyingVault(balance.sub(vaultHold));
        }

        // Check and update strategies debt ratio
        if (strategiesLength > 1) {
            // Only for stablecoin vaults
            uint256[] memory targetRatios = _controller().getStrategiesTargetRatio();
            uint256[] memory currentRatios = getStrategiesDebtRatio();
            bool update;
            for (uint256 i; i < strategiesLength; i++) {
                if (currentRatios[i] < targetRatios[i] && targetRatios[i].sub(currentRatios[i]) > strategyRatioBuffer) {
                    update = true;
                    break;
                }

                if (currentRatios[i] > targetRatios[i] && currentRatios[i].sub(targetRatios[i]) > strategyRatioBuffer) {
                    update = true;
                    break;
                }
            }
            if (update) {
                updateStrategiesDebtRatio(targetRatios);
            }
        }
    }

    /// @notice Calculate system total assets
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /// @notice Get number of strategies in underlying vault
    function getStrategiesLength() external view override returns (uint256) {
        return strategiesLength;
    }

    /// @notice Withdraw assets from underlying vault
    /// @param amount Amount to withdraw
    /// @dev Sends assets to msg.sender
    function withdraw(uint256 amount) external override {
        require(msg.sender == _controller().lifeGuard(), "withdraw: !lifeguard");
        if (!_withdrawFromAdapter(amount, msg.sender)) {
            amount = _withdraw(calculateShare(amount), msg.sender);
        }
    }

    /// @notice Withdraw assets from underlying vault
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    /// @dev Will try to pull assets from adaptor before moving on to pull
    ///     assets from unerlying vault/strategies
    function withdraw(uint256 amount, address recipient) external override {
        require(msg.sender == _controller().insurance(), "withdraw: !insurance");
        if (!_withdrawFromAdapter(amount, recipient)) {
            amount = _withdraw(calculateShare(amount), recipient);
        }
    }

    /// @notice Withdraw assets from vault to vault adaptor
    /// @param amount Amount to withdraw
    function withdrawToAdapter(uint256 amount) external onlyOwner {
        amount = _withdraw(calculateShare(amount), address(this));
    }

    /// @notice Withdraw assets from underlying vault, but do so in a specific strategy order
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    /// @param reversed reverse strategy order
    /// @dev This is an addaptation for yearn v2 vaults - these vaults have a defined withdraw
    ///     order. Gro protocol needs to respect prtocol exposure, and thus might have to withdraw
    ///     from different strategies depending on if pwrd or gvts are withdrawn.
    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external override {
        IController ctrl = _controller();
        require(
            msg.sender == ctrl.withdrawHandler() ||
                msg.sender == ctrl.insurance() ||
                msg.sender == ctrl.emergencyHandler(),
            "withdraw: !withdrawHandler/insurance"
        );
        if (!_withdrawFromAdapter(amount, recipient)) {
            amount = _withdrawByStrategyOrder(calculateShare(amount), recipient, reversed);
        }
    }

    /// @notice Withdraw assets from underlying vault, but do so from a specific strategy
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    /// @param strategyIndex Index of target strategy
    /// @dev Same as for withdrawByStrategyOrder, but now we withdraw from a specific strategy.
    ///     This functionality exists to be able to move assets from overExposed strategies.
    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external override {
        require(msg.sender == _controller().insurance(), "withdraw: !withdrawHandler/insurance");
        if (!_withdrawFromAdapter(amount, recipient)) {
            amount = _withdrawByStrategyIndex(calculateShare(amount), recipient, strategyIndex);
        }
    }

    /// @notice Withdraw assets from the vault adaptor itself
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    function _withdrawFromAdapter(uint256 amount, address recipient) private returns (bool _success) {
        uint256 adapterAmount = IERC20(token).balanceOf(address(this));
        if (adapterAmount >= amount) {
            IERC20(token).safeTransfer(recipient, amount);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Get total amount invested in strategy
    /// @param index Index of strategy
    function getStrategyAssets(uint256 index) external view override returns (uint256 amount) {
        return getStrategyTotalAssets(index);
    }

    /// @notice Deposit assets into the vault adaptor
    /// @param amount Deposit amount
    function deposit(uint256 amount) external override {
        require(msg.sender == _controller().lifeGuard(), "withdraw: !lifeguard");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Set new strategy debt ratios
    /// @param strategyRatios Array of new debt ratios
    function updateStrategyRatio(uint256[] calldata strategyRatios) external override {
        require(
            msg.sender == _controller().insurance() || msg.sender == owner(),
            "!updateStrategyRatio: !owner/insurance"
        );
        updateStrategiesDebtRatio(strategyRatios);
        emit LogNewDebtRatios(strategyRatios);
    }

    /// @notice Check if underlying strategy needs to be harvested
    /// @param index Index of stratey
    /// @param callCost Cost of harvest
    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view override returns (bool harvested) {
        require(index < strategiesLength, "invalid index");
        return _strategyHarvestTrigger(index, callCost);
    }

    /// @notice Harvest underlying strategy
    /// @param index Index of strategy
    function strategyHarvest(uint256 index) external override onlyWhitelist returns (bool harvested) {
        require(index < strategiesLength, "invalid index");
        uint256 beforeAssets = vaultTotalAssets();
        _strategyHarvest(index);
        uint256 afterAssets = vaultTotalAssets();
        if (afterAssets > beforeAssets) {
            _controller().distributeStrategyGainLoss(afterAssets.sub(beforeAssets), 0);
        } else if (afterAssets < beforeAssets) {
            _controller().distributeStrategyGainLoss(0, beforeAssets.sub(afterAssets));
        }
        harvested = true;
    }

    /// @notice Migrate assets to new vault
    /// @param child target for migration
    function migrate(address child) external onlyOwner {
        require(child != address(0), "migrate: child == 0x");
        IERC20 _token = IERC20(token);
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(child, balance);
        emit LogMigrate(address(this), child, balance);
    }

    // Virtual functions
    function _strategyHarvest(uint256 index) internal virtual;

    function updateStrategiesDebtRatio(uint256[] memory ratios) internal virtual;

    function getStrategiesDebtRatio() internal view virtual returns (uint256[] memory);

    /// @notice Deposit from vault adaptors to underlying vaults
    function depositToUnderlyingVault(uint256 amount) internal virtual;

    function _withdraw(uint256 share, address recipient) internal virtual returns (uint256);

    function _withdrawByStrategyOrder(
        uint256 share,
        address recipient,
        bool reversed
    ) internal virtual returns (uint256);

    function _withdrawByStrategyIndex(
        uint256 share,
        address recipient,
        uint256 index
    ) internal virtual returns (uint256);

    function _strategyHarvestTrigger(uint256 index, uint256 callCost) internal view virtual returns (bool);

    function getStrategyEstimatedTotalAssets(uint256 index) internal view virtual returns (uint256);

    function getStrategyTotalAssets(uint256 index) internal view virtual returns (uint256);

    function vaultTotalAssets() internal view virtual returns (uint256);

    function _totalAssets() internal view returns (uint256) {
        uint256 total = IERC20(token).balanceOf(address(this)).add(vaultTotalAssets());
        return total;
    }

    function calculateShare(uint256 amount) private view returns (uint256 share) {
        uint256 sharePrice = _getVaultSharePrice();
        share = amount.mul(uint256(10)**decimals).div(sharePrice);
        uint256 balance = IERC20(vault).balanceOf(address(this));
        share = share < balance ? share : balance;
    }

    /// @notice Calculate system total assets including estimated profits
    function totalEstimatedAssets() external view returns (uint256) {
        uint256 total = IERC20(token).balanceOf(address(this)).add(IERC20(token).balanceOf(address(vault)));
        for (uint256 i = 0; i < strategiesLength; i++) {
            total = total.add(getStrategyEstimatedTotalAssets(i));
        }
        return total;
    }

    function _getVaultSharePrice() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IYearnV2Vault {
    function strategies(address _strategy) external view returns (StrategyParams memory);

    function totalAssets() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256 _amount, address _recipient) external;

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function withdrawByStrategy(
        address[20] calldata _strategies,
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function depositLimit() external view returns (uint256);

    function debtOutstanding(address strategy) external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function updateStrategyDebtRatio(address strategy, uint256 ratio) external;

    function withdrawalQueue(uint256 index) external view returns (address);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

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

    function setController(address newController) external onlyOwner {
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
    function stablecoins() external view returns (address[3] memory);

    function vaults() external view returns (address[3] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function reward() external view returns (address);

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function emergencyHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external;

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external;

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external;

    function getUserAssets(bool pwrd, address account) external view returns (uint256 deductUsd);

    function referrals(address account) external view returns (address);

    function addReferral(address account, address referral) external;

    function getStrategiesTargetRatio() external view returns (uint256[] memory);

    function withdrawalFee(bool pwrd) external view returns (uint256);

    function validGTokenDecrease(uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);
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

    function updateStrategyRatio(uint256[] calldata strategyRetios) external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function vault() external view returns (address);

    function investTrigger() external view returns (bool);

    function invest() external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event LogAddToWhitelist(address indexed user);
    event LogRemoveFromWhitelist(address indexed user);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "only whitelist");
        _;
    }

    function addToWhitelist(address user) external onlyOwner {
        require(user != address(0), "WhiteList: 0x");
        whitelist[user] = true;
        emit LogAddToWhitelist(user);
    }

    function removeFromWhitelist(address user) external onlyOwner {
        require(user != address(0), "WhiteList: 0x");
        whitelist[user] = false;
        emit LogRemoveFromWhitelist(user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
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