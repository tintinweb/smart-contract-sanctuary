// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/Constants.sol";
import "./common/Whitelist.sol";
import "./interfaces/IVaultMK2.sol";
import "./interfaces/IERC20Detailed.sol";

interface IStrategy {
    function want() external view returns (address);

    function vault() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function migrate(address _newStrategy) external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;
}

/// @notice VaultAdapterMk2 - Gro protocol stand alone vault for strategy testing
///
///     Desing is based on a modified version of the yearnV2Vault
///
///     ###############################################
///     Vault Adaptor specifications
///     ###############################################
///
///     - Deposit: A deposit will move assets into the vault adaptor, which will be
///         available for investment into the underlying strategies
///     - Withdrawal: A withdrawal will always attempt to pull from the vaultAdaptor if possible,
///         if the assets in the adaptor fail to cover the withdrawal, the adaptor will
///         attempt to withdraw assets from the underlying strategies.
///     - Asset availability:
///         - VaultAdaptor
///         - Strategies
///     - Debt ratios: Ratio in %BP of assets to invest in the underlying strategies of a vault
contract VaultAdaptorMK2 is
    Constants,
    Whitelist,
    IVaultMK2,
    ERC20,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    uint256 public constant MAXIMUM_STRATEGIES = 5;
    address constant ZERO_ADDRESS = address(0);

    // Underlying token
    address public immutable override token;
    uint256 private immutable _decimals;

    struct StrategyParams {
        uint256 activation;
        bool active;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
    }

    // Allowance
    bool public allowance = true; // turn allowance on/off
    mapping(address => bool) public claimed;
    uint256 public immutable BASE_ALLOWANCE; // user BASE allowance
    mapping(address => uint256) public userAllowance; // user additional allowance

    mapping(address => StrategyParams) public strategies;

    address[MAXIMUM_STRATEGIES] public withdrawalQueue;

    // Slow release of profit
    uint256 public lockedProfit;
    uint256 public releaseFactor;

    uint256 public debtRatio;
    uint256 public totalDebt;
    uint256 public lastReport;
    uint256 public activation;
    uint256 public depositLimit;

    address public bouncer;
    address public rewards;
    uint256 public vaultFee;

    event LogStrategyAdded(
        address indexed strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest
    );
    event LogStrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );
    event LogUpdateWithdrawalQueue(address[] queue);
    event LogNewDebtRatio(address indexed strategy, uint256 debtRatio);
    event LogStrategyUpdateMinDebtPerHarvest(
        address indexed strategy,
        uint256 minDebtPerHarvest
    );
    event LogStrategyUpdateMaxDebtPerHarvest(
        address indexed strategy,
        uint256 maxDebtPerHarvest
    );
    event LogStrategyMigrated(
        address indexed newStrategy,
        address indexed oldStrategy
    );
    event LogStrategyRevoked(address indexed strategy);
    event LogStrategyRemovedFromQueue(address indexed strategy);
    event LogStrategyAddedToQueue(address indexed strategy);
    event LogStrategyStatusUpdate(address indexed strategy, bool status);

    event LogDepositLimit(uint256 newLimit);
    event LogDebtRatios(uint256[] strategyRetios);
    event LogMigrate(address parent, address child, uint256 amount);
    event LogNewBouncer(address bouncer);
    event LogNewRewards(address rewards);
    event LogNewReleaseFactor(uint256 factor);
    event LogNewVaultFee(uint256 vaultFee);
    event LogNewStrategyHarvest(bool loss, uint256 change);
    event LogNewAllowance(address user, uint256 amount);
    event LogAllowanceStatus(bool status);
    event LogDeposit(
        address indexed from,
        uint256 _amount,
        uint256 shares,
        uint256 allowance
    );
    event LogWithdrawal(
        address indexed from,
        uint256 value,
        uint256 shares,
        uint256 totalLoss,
        uint256 allowance
    );

    constructor(
        address _token,
        uint256 _baseAllowance,
        address _bouncer
    )
        ERC20(
            string(
                abi.encodePacked(
                    "Gro ",
                    IERC20Detailed(_token).symbol(),
                    " Lab"
                )
            ),
            string(abi.encodePacked("gro", IERC20Detailed(_token).symbol()))
        )
    {
        token = _token;
        activation = block.timestamp;
        uint256 decimals = IERC20Detailed(_token).decimals();
        _decimals = decimals;
        BASE_ALLOWANCE = _baseAllowance * 10**decimals;
        bouncer = _bouncer;
        // 6 hours release
        releaseFactor = (DEFAULT_DECIMALS_FACTOR * 46) / 10**6;
    }

    /// @notice Vault share decimals
    function decimals() public view override returns (uint8) {
        return uint8(_decimals);
    }

    /// @notice Set contract that controlls user allowance
    /// @param _bouncer address of new bouncer
    function setBouncer(address _bouncer) external onlyOwner {
        bouncer = _bouncer;
        emit LogNewBouncer(_bouncer);
    }

    /// @notice Set Vault to use allowance
    /// @param _status set allowance to on/off
    function activateAllowance(bool _status) external onlyOwner {
        allowance = _status;
        emit LogAllowanceStatus(_status);
    }

    /// @notice Set contract that will recieve vault fees
    /// @param _rewards address of rewards contract
    function setRewards(address _rewards) external onlyOwner {
        rewards = _rewards;
        emit LogNewRewards(_rewards);
    }

    /// @notice Set fee that is reduced from strategy yields when harvests are called
    /// @param _fee new strategy fee
    function setVaultFee(uint256 _fee) external onlyOwner {
        require(_fee < 3000, "setVaultFee: _fee > 30%");
        vaultFee = _fee;
        emit LogNewVaultFee(_fee);
    }

    /// @notice Total limit for vault deposits
    /// @param _newLimit new max deposit limit for the vault
    function setDepositLimit(uint256 _newLimit) external onlyOwner {
        depositLimit = _newLimit;
        emit LogDepositLimit(_newLimit);
    }

    /// @notice Limit for how much individual users are allowed to deposit
    /// @param _user user to set allowance for
    /// @param _amount new allowance amount
    function setUserAllowance(address _user, uint256 _amount) external {
        require(
            msg.sender == bouncer,
            "setUserAllowance: msg.sender != bouncer"
        );
        if (!claimed[_user]) {
            userAllowance[_user] += _amount * (10**_decimals) + BASE_ALLOWANCE;
            claimed[_user] = true;
        } else {
            userAllowance[_user] += _amount * (10**_decimals);
        }
        emit LogNewAllowance(_user, _amount);
    }

    /// @notice Set how quickly profits are released
    /// @param _factor how quickly profits are released
    function setProfitRelease(uint256 _factor) external onlyOwner {
        releaseFactor = _factor;
        emit LogNewReleaseFactor(_factor);
    }

    /// @notice Calculate system total assets
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /// @notice Get number of strategies in underlying vault
    function getStrategiesLength() external view override returns (uint256) {
        return strategyLength();
    }

    /// @notice Get total amount invested in strategy
    /// @param _index index of strategy
    function getStrategyAssets(uint256 _index)
        external
        view
        override
        returns (uint256 amount)
    {
        return _getStrategyTotalAssets(_index);
    }

    /// @notice Deposit assets into the vault adaptor
    /// @param _amount user deposit amount
    function deposit(uint256 _amount) external nonReentrant returns (uint256) {
        require(_amount > 0, "deposit: _amount !> 0");
        require(
            _totalAssets() + _amount <= depositLimit,
            "deposit: !depositLimit"
        );
        uint256 _allowance = 0;
        if (allowance) {
            _allowance = userAllowance[msg.sender];
            if (!claimed[msg.sender]) {
                require(_amount <= BASE_ALLOWANCE, "deposit: !userAllowance");
                _allowance = BASE_ALLOWANCE - _amount;
                claimed[msg.sender] = true;
            } else {
                require(
                    userAllowance[msg.sender] >= _amount,
                    "deposit: !userAllowance"
                );
                _allowance = userAllowance[msg.sender] - _amount;
            }
            userAllowance[msg.sender] = _allowance;
        }

        uint256 shares = _issueSharesForAmount(msg.sender, _amount);

        IERC20 _token = IERC20(token);
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        emit LogDeposit(msg.sender, _amount, shares, _allowance);
        return shares;
    }

    /// @notice Mint shares for user based on deposit amount
    /// @param _to recipient
    /// @param _amount amount of want deposited
    function _issueSharesForAmount(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 shares;
        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            shares = (_amount * _totalSupply) / _freeFunds();
        } else {
            shares = _amount;
        }
        // unlikely to happen, just here for added safety
        require(shares != 0, "_issueSharesForAmount: shares == 0");
        _mint(_to, shares);

        return shares;
    }

    /// @notice Check if underlying strategy needs to be harvested
    /// @param _index Index of stratey
    /// @param _callCost Cost of harvest in underlying token
    function strategyHarvestTrigger(uint256 _index, uint256 _callCost)
        external
        view
        override
        returns (bool)
    {
        require(_index < strategyLength(), "invalid index");
        return IStrategy(withdrawalQueue[_index]).harvestTrigger(_callCost);
    }

    /// @notice Harvest underlying strategy
    /// @param _index Index of strategy
    /// @dev Any Gains/Losses incurred by harvesting a streategy is accounted for in the vault adapter
    ///     and reported back to the Controller, which in turn updates current system total assets.
    function strategyHarvest(uint256 _index)
        external
        nonReentrant
        onlyWhitelist
    {
        require(_index < strategyLength(), "invalid index");
        IStrategy _strategy = IStrategy(withdrawalQueue[_index]);
        uint256 beforeAssets = _totalAssets();
        _strategy.harvest();
        uint256 afterAssets = _totalAssets();
        bool loss;
        uint256 change;
        if (beforeAssets > afterAssets) {
            change = beforeAssets - afterAssets;
            loss = true;
        } else {
            change = afterAssets - beforeAssets;
            loss = false;
        }
        emit LogNewStrategyHarvest(loss, change);
    }

    /// @notice Calculate how much profit is currently locked
    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - lastReport) *
            releaseFactor;
        if (lockedFundsRatio < DEFAULT_DECIMALS_FACTOR) {
            uint256 _lockedProfit = lockedProfit;
            return
                _lockedProfit -
                ((lockedFundsRatio * _lockedProfit) / DEFAULT_DECIMALS_FACTOR);
        } else {
            return 0;
        }
    }

    function _freeFunds() internal view returns (uint256) {
        return _totalAssets() - _calculateLockedProfit();
    }

    /// @notice Calculate system total assets including estimated profits
    function totalEstimatedAssets() external view returns (uint256) {
        uint256 total = IERC20(token).balanceOf(address(this));
        for (uint256 i = 0; i < strategyLength(); i++) {
            total += _getStrategyEstimatedTotalAssets(i);
        }
        return total;
    }

    /// @notice Update the withdrawal queue
    /// @param _queue New withdrawal queue order
    function setWithdrawalQueue(address[] calldata _queue) external onlyOwner {
        require(
            _queue.length <= MAXIMUM_STRATEGIES,
            "setWithdrawalQueue: > MAXIMUM_STRATEGIES"
        );
        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            if (i >= _queue.length) {
                withdrawalQueue[i] = address(0);
            } else {
                withdrawalQueue[i] = _queue[i];
            }
            emit LogUpdateWithdrawalQueue(_queue);
        }
    }

    /// @notice Number of active strategies in the vaultAdapter
    function strategyLength() internal view returns (uint256) {
        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawalQueue[i] == address(0)) {
                return i;
            }
        }
        return MAXIMUM_STRATEGIES;
    }

    /// @notice Update the debtRatio of a specific strategy
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    function setDebtRatio(address _strategy, uint256 _debtRatio) external {
        // If a strategy isnt the source of the call
        require(strategies[_strategy].active, "setDebtRatio: !active");
        require(
            msg.sender == owner() || whitelist[msg.sender],
            "setDebtRatio: !whitelist"
        );
        _setDebtRatio(_strategy, _debtRatio);
        require(
            debtRatio <= PERCENTAGE_DECIMAL_FACTOR,
            "setDebtRatio: debtRatio > 100%"
        );
    }

    /// @notice Set new strategy debt ratios
    /// @param _strategyDebtRatios array of new debt ratios
    /// @dev Can be used to forecfully change the debt ratios of the underlying strategies
    ///     by whitelisted parties/owner
    function setDebtRatios(uint256[] memory _strategyDebtRatios) external {
        require(
            msg.sender == owner() || whitelist[msg.sender],
            "setDebtRatios: !whitelist"
        );
        require(
            _strategyDebtRatios.length <= MAXIMUM_STRATEGIES,
            "setDebtRatios: > MAXIMUM_STRATEGIES"
        );
        address _strategy;
        uint256 _ratio;
        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            _strategy = withdrawalQueue[i];
            if (_strategy == address(0)) {
                break;
            } else {
                _ratio = _strategyDebtRatios[i];
            }
            _setDebtRatio(_strategy, _ratio);
        }
        require(
            debtRatio <= PERCENTAGE_DECIMAL_FACTOR,
            "setDebtRatios: debtRatio > 100%"
        );
    }

    /// @notice Add a new strategy to the vault adapter
    /// @param _strategy target strategy to add
    /// @param _debtRatio target debtRatio of strategy
    /// @param _minDebtPerHarvest min amount of debt the strategy can take on per harvest
    /// @param _maxDebtPerHarvest max amount of debt the strategy can take on per harvest
    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest
    ) external onlyOwner {
        require(
            withdrawalQueue[MAXIMUM_STRATEGIES - 1] == ZERO_ADDRESS,
            "addStrategy: > MAXIMUM_STRATEGIES"
        );
        require(_strategy != ZERO_ADDRESS, "addStrategy: address(0x)");
        require(!strategies[_strategy].active, "addStrategy: !activated");
        require(
            address(this) == IStrategy(_strategy).vault(),
            "addStrategy: !vault"
        );
        require(
            debtRatio + _debtRatio <= PERCENTAGE_DECIMAL_FACTOR,
            "addStrategy: debtRatio > 100%"
        );
        require(
            _minDebtPerHarvest <= _maxDebtPerHarvest,
            "addStrategy: min > max"
        );

        StrategyParams storage newStrat = strategies[_strategy];
        newStrat.activation = block.timestamp;
        newStrat.active = true;
        newStrat.debtRatio = _debtRatio;
        newStrat.minDebtPerHarvest = _minDebtPerHarvest;
        newStrat.maxDebtPerHarvest = _maxDebtPerHarvest;
        newStrat.lastReport = block.timestamp;

        emit LogStrategyAdded(
            _strategy,
            _debtRatio,
            _minDebtPerHarvest,
            _maxDebtPerHarvest
        );

        debtRatio += _debtRatio;

        withdrawalQueue[strategyLength()] = _strategy;
        _organizeWithdrawalQueue();
    }

    /// @notice Set a new min debt equired for assets to be made available to the strategy at harvest
    /// @param _strategy strategy address
    /// @param _minDebtPerHarvest new min debt
    function updateStrategyMinDebtPerHarvest(
        address _strategy,
        uint256 _minDebtPerHarvest
    ) external onlyOwner {
        require(
            strategies[_strategy].activation > 0,
            "updateStrategyMinDebtPerHarvest: !activated"
        );
        require(
            strategies[_strategy].maxDebtPerHarvest >= _minDebtPerHarvest,
            "updateStrategyMinDebtPerHarvest: min > max"
        );

        strategies[_strategy].minDebtPerHarvest = _minDebtPerHarvest;
        emit LogStrategyUpdateMinDebtPerHarvest(_strategy, _minDebtPerHarvest);
    }

    /// @notice Set a new max debt that can be made avilable to the stragey at harvest
    /// @param _strategy strategy address
    /// @param _maxDebtPerHarvest new max debt
    function updateStrategyMaxDebtPerHarvest(
        address _strategy,
        uint256 _maxDebtPerHarvest
    ) external onlyOwner {
        require(
            strategies[_strategy].activation > 0,
            "updateStrategyMaxDebtPerHarvest: !activated"
        );
        require(
            strategies[_strategy].minDebtPerHarvest <= _maxDebtPerHarvest,
            "updateStrategyMaxDebtPerHarvest: min > max"
        );

        strategies[_strategy].maxDebtPerHarvest = _maxDebtPerHarvest;
        emit LogStrategyUpdateMaxDebtPerHarvest(_strategy, _maxDebtPerHarvest);
    }

    /// @notice Replace existing strategy with a new one, removing he old one from the vault adapters
    ///     active strategies
    /// @param _oldVersion address of old strategy
    /// @param _newVersion address of new strategy
    function migrateStrategy(address _oldVersion, address _newVersion)
        external
        onlyOwner
    {
        require(_newVersion != ZERO_ADDRESS, "migrateStrategy: 0x");
        require(
            strategies[_oldVersion].activation > 0,
            "migrateStrategy: oldVersion !activated"
        );
        require(
            strategies[_oldVersion].active,
            "migrateStrategy: oldVersion !active"
        );
        require(
            strategies[_newVersion].activation == 0,
            "migrateStrategy: newVersion activated"
        );

        StrategyParams storage _strategy = strategies[_oldVersion];

        debtRatio += _strategy.debtRatio;

        StrategyParams storage newStrat = strategies[_newVersion];
        newStrat.activation = block.timestamp;
        newStrat.active = true;
        newStrat.debtRatio = _strategy.debtRatio;
        newStrat.minDebtPerHarvest = _strategy.minDebtPerHarvest;
        newStrat.maxDebtPerHarvest = _strategy.maxDebtPerHarvest;
        newStrat.lastReport = _strategy.lastReport;
        newStrat.totalDebt = _strategy.totalDebt;
        newStrat.totalDebt = 0;
        newStrat.totalGain = 0;
        newStrat.totalLoss = 0;

        IStrategy(_oldVersion).migrate(_newVersion);

        _strategy.totalDebt = 0;
        _strategy.minDebtPerHarvest = 0;
        _strategy.maxDebtPerHarvest = 0;

        emit LogStrategyMigrated(_oldVersion, _newVersion);

        _revokeStrategy(_oldVersion);

        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawalQueue[i] == _oldVersion) {
                withdrawalQueue[i] = _newVersion;
                return;
            }
        }
    }

    /// @notice Remove strategy from vault adapter, called by strategy on emergencyExit
    function revokeStrategy() external {
        require(
            strategies[msg.sender].active,
            "revokeStrategy: strategy not active"
        );
        _revokeStrategy(msg.sender);
    }

    /// @notice Manually add a strategy to the withdrawal queue
    /// @param _strategy target strategy to add
    function addStrategyToQueue(address _strategy) external {
        require(
            msg.sender == owner() || whitelist[msg.sender],
            "addStrategyToQueue: !owner|whitelist"
        );
        require(
            strategies[_strategy].activation > 0,
            "addStrategyToQueue: !activated"
        );
        require(
            withdrawalQueue[MAXIMUM_STRATEGIES - 1] == ZERO_ADDRESS,
            "addStrategyToQueue: queue full"
        );
        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            address strategy = withdrawalQueue[i];
            if (strategy == ZERO_ADDRESS) break;
            require(
                _strategy != strategy,
                "addStrategyToQueue: strategy already in queue"
            );
        }
        withdrawalQueue[MAXIMUM_STRATEGIES - 1] = _strategy;
        _organizeWithdrawalQueue();
        emit LogStrategyAddedToQueue(_strategy);
    }

    /// @notice Manually remove a strategy to the withdrawal queue
    /// @param _strategy Target strategy to remove
    function removeStrategyFromQueue(address _strategy) external {
        require(
            msg.sender == owner() || whitelist[msg.sender],
            "removeStrategyFromQueue: !owner|whitelist"
        );
        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            if (withdrawalQueue[i] == _strategy) {
                withdrawalQueue[i] = ZERO_ADDRESS;
                _organizeWithdrawalQueue();
                emit LogStrategyRemovedFromQueue(_strategy);
                return;
            }
        }
    }

    /// @notice Check how much credits are available for the strategy
    /// @param _strategy Target strategy
    function creditAvailable(address _strategy)
        external
        view
        returns (uint256)
    {
        return _creditAvailable(_strategy);
    }

    /// @notice Same as above but called by the streategy
    function creditAvailable() external view returns (uint256) {
        return _creditAvailable(msg.sender);
    }

    /// @notice Calculate the amount of assets the vault has available for the strategy to pull and invest,
    ///     the available credit is based of the strategies debt ratio and the total available assets
    ///     the vault has
    /// @param _strategy target strategy
    /// @dev called during harvest
    function _creditAvailable(address _strategy)
        internal
        view
        returns (uint256)
    {
        StrategyParams memory _strategyData = strategies[_strategy];
        uint256 vaultTotalAssets = _totalAssets();
        uint256 vaultDebtLimit = (debtRatio * vaultTotalAssets) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 vaultTotalDebt = totalDebt;
        uint256 strategyDebtLimit = (_strategyData.debtRatio *
            vaultTotalAssets) / PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = _strategyData.totalDebt;
        uint256 strategyMinDebtPerHarvest = _strategyData.minDebtPerHarvest;
        uint256 strategyMaxDebtPerHarvest = _strategyData.maxDebtPerHarvest;

        IERC20 _token = IERC20(token);

        if (
            strategyDebtLimit <= strategyTotalDebt ||
            vaultDebtLimit <= vaultTotalDebt
        ) {
            return 0;
        }

        uint256 available = strategyDebtLimit - strategyTotalDebt;

        available = Math.min(available, vaultDebtLimit - vaultTotalDebt);

        available = Math.min(available, _token.balanceOf(address(this)));

        if (available < strategyMinDebtPerHarvest) {
            return 0;
        } else {
            return Math.min(available, strategyMaxDebtPerHarvest);
        }
    }

    /// @notice Deal with any loss that a strategy has realized
    /// @param _strategy target strategy
    /// @param _loss amount of loss realized
    function _reportLoss(address _strategy, uint256 _loss) internal {
        StrategyParams storage strategy = strategies[_strategy];
        // Loss can only be up the amount of debt issued to strategy
        require(strategy.totalDebt >= _loss, "_reportLoss: totalDebt >= loss");
        // Add loss to srategy and remove loss from strategyDebt
        strategy.totalLoss += _loss;
        strategy.totalDebt -= _loss;
        totalDebt -= _loss;
    }

    /// @notice Amount by which a strategy exceeds its current debt limit
    /// @param _strategy target strategy
    function _debtOutstanding(address _strategy)
        internal
        view
        returns (uint256)
    {
        StrategyParams storage strategy = strategies[_strategy];
        uint256 strategyDebtLimit = (strategy.debtRatio * _totalAssets()) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = strategy.totalDebt;

        if (strategyTotalDebt <= strategyDebtLimit) {
            return 0;
        } else {
            return strategyTotalDebt - strategyDebtLimit;
        }
    }

    /// @notice Amount of debt the strategy has to pay back to the vault at next harvest
    /// @param _strategy target strategy
    function debtOutstanding(address _strategy)
        external
        view
        returns (uint256)
    {
        return _debtOutstanding(_strategy);
    }

    /// @notice Amount of debt the strategy has to pay back to the vault at next harvest
    /// @dev same as above but used by strategies
    function debtOutstanding() external view returns (uint256) {
        return _debtOutstanding(msg.sender);
    }

    /// @notice A strategies total debt to the vault
    /// @dev here to simplify strategies life when trying to get the totalDebt
    function strategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Remove unwanted token from contract
    /// @param _token Address of unwanted token, cannot be want token
    /// @param _recipient Reciever of unwanted token
    function sweep(address _token, address _recipient) external onlyOwner {
        require(_token != token, "sweep: token == want");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_recipient, amount);
    }

    /// @notice Withdraw desired amount from vault adapter, if the reserves are unable to
    ///     to cover the desired amount, start withdrawing from strategies in order specified.
    ///     The withdrawamount if set in shares and calculated in the underlying token the vault holds.
    /// @param _shares Amount to withdraw in shares
    /// @param _maxLoss Max accepted loss when withdrawing from strategy
    function withdraw(uint256 _shares, uint256 _maxLoss)
        external
        nonReentrant
        returns (uint256)
    {
        require(
            _maxLoss <= PERCENTAGE_DECIMAL_FACTOR,
            "withdraw: _maxLoss > 100%"
        );
        require(_shares > 0, "withdraw: _shares == 0");

        uint256 userBalance = balanceOf(msg.sender);
        uint256 shares = _shares == type(uint256).max
            ? balanceOf(msg.sender)
            : _shares;
        require(shares <= userBalance, "withdraw, shares > userBalance");
        uint256 value = _shareValue(shares);

        IERC20 _token = IERC20(token);
        uint256 totalLoss = 0;
        // If reserves dont cover the withdrawal, start withdrawing from strategies
        if (value > _token.balanceOf(address(this))) {
            address[MAXIMUM_STRATEGIES] memory _strategies = withdrawalQueue;
            for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
                address _strategy = _strategies[i];
                if (_strategy == ZERO_ADDRESS) break;
                uint256 vaultBalance = _token.balanceOf(address(this));
                // break if we have withdrawn all we need
                if (value <= vaultBalance) break;
                uint256 amountNeeded = value - vaultBalance;

                StrategyParams storage _strategyData = strategies[_strategy];
                amountNeeded = Math.min(amountNeeded, _strategyData.totalDebt);
                // If nothing is needed or strategy has no assets, continue
                if (amountNeeded == 0) {
                    continue;
                }

                uint256 loss = IStrategy(_strategy).withdraw(amountNeeded);
                // Amount withdraw from strategy
                uint256 withdrawn = _token.balanceOf(address(this)) -
                    vaultBalance;

                // Handle the loss if any
                if (loss > 0) {
                    value = value - loss;
                    totalLoss = totalLoss + loss;
                    _reportLoss(_strategy, loss);
                }
                // Remove withdrawn amount from strategy and vault debts
                _strategyData.totalDebt -= withdrawn;
                totalDebt -= withdrawn;
            }
            uint256 finalBalance = _token.balanceOf(address(this));
            // If we dont have enough assets to cover the withdrawal, lower it
            //      to what we have, this should technically never happen
            if (value > finalBalance) {
                value = finalBalance;
                shares = _sharesForAmount(value + totalLoss);
            }

            require(
                totalLoss <=
                    (_maxLoss * (value + totalLoss)) /
                        PERCENTAGE_DECIMAL_FACTOR,
                "withdraw: loss > maxloss"
            );
        }
        _burn(msg.sender, shares);
        _token.safeTransfer(msg.sender, value);
        // Hopefully get a bit more allowance - thx for participating!
        uint256 _allowance = 0;
        if (allowance) {
            _allowance = userAllowance[msg.sender] + (value + totalLoss);
            userAllowance[msg.sender] = _allowance;
        }

        emit LogWithdrawal(msg.sender, value, shares, totalLoss, _allowance);
        return value;
    }

    /// @notice Value of shares in underlying token
    /// @param _shares amount of shares to convert to tokens
    function _shareValue(uint256 _shares) internal view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return _shares;
        return ((_shares * _freeFunds()) / _totalSupply);
    }

    /// @notice Value of tokens in shares
    /// @param _amount amount of tokens to convert to shares
    function _sharesForAmount(uint256 _amount) internal view returns (uint256) {
        uint256 _assets = _freeFunds();
        if (_assets > 0) {
            return (_amount * totalSupply()) / _assets;
        }
        return 0;
    }

    function _calcFees(uint256 _gain) internal returns (uint256) {
        uint256 fees = (_gain * vaultFee) / PERCENTAGE_DECIMAL_FACTOR;
        if (fees > 0) _issueSharesForAmount(rewards, fees);
        return _gain - fees;
    }

    /// @notice Report back any gains/losses from a (strategy) harvest, vault adapetr
    ///     calls back debt or gives out more credit to the strategy depending on available
    ///     credit and the strategies current position.
    /// @param _gain Strategy gains from latest harvest
    /// @param _loss Strategy losses from latest harvest
    /// @param _debtPayment Amount strategy can pay back to vault
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256) {
        StrategyParams storage _strategy = strategies[msg.sender];
        require(_strategy.activation > 0, "report: !activated");
        IERC20 _token = IERC20(token);
        require(
            _token.balanceOf(msg.sender) >= _gain + _debtPayment,
            "report: balance(strategy) < _gain + _debtPayment"
        );

        if (_loss > 0) {
            _reportLoss(msg.sender, _loss);
        }

        _strategy.totalGain = _strategy.totalGain + _gain;

        uint256 debt = _debtOutstanding(msg.sender);
        uint256 debtPayment = Math.min(_debtPayment, debt);

        if (debtPayment > 0) {
            _strategy.totalDebt = _strategy.totalDebt - debtPayment;
            totalDebt -= debtPayment;
            debt -= debtPayment;
        }

        uint256 credit = _creditAvailable(msg.sender);

        if (credit > 0) {
            _strategy.totalDebt += credit;
            totalDebt += credit;
        }

        uint256 totalAvailable = _gain + debtPayment;

        if (totalAvailable < credit) {
            _token.safeTransfer(msg.sender, credit - totalAvailable);
        } else if (totalAvailable > credit) {
            _token.safeTransferFrom(
                msg.sender,
                address(this),
                totalAvailable - credit
            );
        }

        // Profit is locked and gradually released per block
        // NOTE: compute current locked profit and replace with sum of current and new
        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() +
            _calcFees(_gain);
        if (lockedProfitBeforeLoss > _loss) {
            lockedProfit = lockedProfitBeforeLoss - _loss;
        } else {
            lockedProfit = 0;
        }

        lastReport = block.timestamp;
        _strategy.lastReport = lastReport;

        emit LogStrategyReported(
            msg.sender,
            _gain,
            _loss,
            debtPayment,
            _strategy.totalGain,
            _strategy.totalLoss,
            _strategy.totalDebt,
            credit,
            _strategy.debtRatio
        );

        if (_strategy.debtRatio == 0) {
            return IStrategy(msg.sender).estimatedTotalAssets();
        } else {
            return debt;
        }
    }

    /// @notice Update a given strategies debt ratio
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    /// @dev See setDebtRatios and setDebtRatio functions
    function _setDebtRatio(address _strategy, uint256 _debtRatio) internal {
        debtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = _debtRatio;
        debtRatio += _debtRatio;
        emit LogNewDebtRatio(_strategy, _debtRatio);
    }

    /// @notice Gives the price for a single Vault share.
    /// @return The value of a single share.
    /// @dev See dev note on `withdraw`.
    function getPricePerShare() external view returns (uint256) {
        return _shareValue(10**_decimals);
    }

    /// @notice Get current enstimated amount of assets in strategy
    /// @param _index index of strategy
    function _getStrategyEstimatedTotalAssets(uint256 _index)
        internal
        view
        returns (uint256)
    {
        return IStrategy(withdrawalQueue[_index]).estimatedTotalAssets();
    }

    /// @notice Get strategy totalDebt
    /// @param _index index of strategy
    function _getStrategyTotalAssets(uint256 _index)
        internal
        view
        returns (uint256)
    {
        StrategyParams storage strategy = strategies[withdrawalQueue[_index]];
        return strategy.totalDebt;
    }

    /// @notice Remove strategy from vault
    /// @param _strategy address of strategy
    function _revokeStrategy(address _strategy) internal {
        debtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = 0;
        strategies[_strategy].active = false;
        emit LogStrategyRevoked(_strategy);
    }

    /// @notice Vault adapters total assets including loose assets and debts
    /// @dev note that this does not consider estimated gains/losses from the strategies
    function _totalAssets() private view returns (uint256) {
        return IERC20(token).balanceOf(address(this)) + totalDebt;
    }

    /// @notice Reorder the withdrawal queue to put the zero addresses at the end
    function _organizeWithdrawalQueue() internal {
        uint256 offset;
        for (uint256 i; i < MAXIMUM_STRATEGIES; i++) {
            address strategy = withdrawalQueue[i];
            if (strategy == ZERO_ADDRESS) {
                offset += 1;
            } else if (offset > 0) {
                withdrawalQueue[i - offset] = strategy;
                withdrawalQueue[i] = ZERO_ADDRESS;
            }
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

contract Constants {
    uint8 internal constant DEFAULT_DECIMALS = 18;
    uint256 internal constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 internal constant PERCENTAGE_DECIMALS = 4;
    uint256 internal constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

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

// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.4;

interface IVaultMK2 {
    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

/**
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
        return msg.data;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}