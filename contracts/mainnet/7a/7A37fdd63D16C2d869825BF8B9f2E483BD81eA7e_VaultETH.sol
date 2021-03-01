pragma solidity 0.5.16;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {
    constructor() public {}

    function initialize(address _storage) public initializer {
        GovernableInit.initialize(_storage);
    }

    modifier onlyController() {
        require(
            Storage(_storage()).isController(msg.sender),
            "Not a controller"
        );
        _;
    }

    modifier onlyControllerOrGovernance() {
        require(
            (Storage(_storage()).isController(msg.sender) ||
                Storage(_storage()).isGovernance(msg.sender)),
            "The caller must be controller or governance"
        );
        _;
    }

    function controller() public view returns (address) {
        return Storage(_storage()).controller();
    }
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {
    bytes32 internal constant _STORAGE_SLOT =
        0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

    modifier onlyGovernance() {
        require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
        _;
    }

    constructor() public {
        assert(
            _STORAGE_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.governableInit.storage")) - 1
                )
        );
    }

    function initialize(address _store) public initializer {
        _setStorage(_store);
    }

    function _setStorage(address newStorage) private {
        bytes32 slot = _STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newStorage)
        }
    }

    function setStorage(address _store) public onlyGovernance {
        require(_store != address(0), "new storage shouldn't be empty");
        _setStorage(_store);
    }

    function _storage() internal view returns (address str) {
        bytes32 slot = _STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function governance() public view returns (address) {
        return Storage(_storage()).governance();
    }
}

pragma solidity 0.5.16;

contract Storage {
    address public governance;
    address public controller;

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "Not governance");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "new governance shouldn't be empty");
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0), "new controller shouldn't be empty");
        controller = _controller;
    }

    function isGovernance(address account) public view returns (bool) {
        return account == governance;
    }

    function isController(address account) public view returns (bool) {
        return account == controller;
    }
}

pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IController.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";
import "./weth/WETH9.sol";

contract VaultETH is
    ERC20,
    ERC20Detailed,
    IVault,
    IUpgradeSource,
    ControllableInit,
    VaultStorage
{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed beneficiary, uint256 amount);
    event Invest(uint256 amount);
    event StrategyAnnounced(address newStrategy, uint256 time);
    event StrategyChanged(address newStrategy, address oldStrategy);

    modifier whenStrategyDefined() {
        require(address(strategy()) != address(0), "Strategy must be defined");
        _;
    }

    // Only smart contracts will be affected by this modifier
    modifier defense() {
        require(
            (msg.sender == tx.origin) || // If it is a normal user and not smart contract,
                // then the requirement will pass
                !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
            "This smart contract has been grey listed" // make sure that it is not on our greyList.
        );
        _;
    }

    constructor() public {}

    // the function is name differently to not cause inheritance clash in truffle and allows tests
    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    ) public initializer {
        require(
            _toInvestNumerator <= _toInvestDenominator,
            "cannot invest more than 100%"
        );
        require(_toInvestDenominator != 0, "cannot divide by 0");

        ERC20Detailed.initialize("DELTA_ETH", "dETH", 18);
        ControllableInit.initialize(_storage);

        uint256 underlyingUnit =
            10**uint256(ERC20Detailed(address(_underlying)).decimals());
        uint256 implementationDelay = 12 hours;
        uint256 strategyChangeDelay = 12 hours;
        VaultStorage.initialize(
            _underlying,
            _toInvestNumerator,
            _toInvestDenominator,
            underlyingUnit,
            implementationDelay,
            strategyChangeDelay
        );
    }

    function strategy() public view returns (address) {
        return _strategy();
    }

    function underlying() public view returns (address) {
        return _underlying();
    }

    function underlyingUnit() public view returns (uint256) {
        return _underlyingUnit();
    }

    function vaultFractionToInvestNumerator() public view returns (uint256) {
        return _vaultFractionToInvestNumerator();
    }

    function vaultFractionToInvestDenominator() public view returns (uint256) {
        return _vaultFractionToInvestDenominator();
    }

    function withdrawFee() public view returns (uint256) {
        return _withdrawFee();
    }

    function totalDeposits() public view returns (uint256) {
        return _totalDeposits();
    }

    function nextImplementation() public view returns (address) {
        return _nextImplementation();
    }

    function nextImplementationTimestamp() public view returns (uint256) {
        return _nextImplementationTimestamp();
    }

    function nextImplementationDelay() public view returns (uint256) {
        return _nextImplementationDelay();
    }

    /**
     * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
     * forceUnleashed on the current strategy. Call this through controller to claim galactic rewards.
     */
    function forceUnleashed()
        external
        whenStrategyDefined
        onlyControllerOrGovernance
    {
        // ensure that new funds are invested too
        invest();
        IStrategy(strategy()).forceUnleashed();
    }

    /*
     * Returns the cash balance across all users in this contract.
     */
    function underlyingBalanceInVault() public view returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /* Returns the current underlying (e.g., DAI's) balance together with
     * the invested amount (if DAI is invested elsewhere by the strategy).
     */
    function underlyingBalanceWithInvestment() public view returns (uint256) {
        if (address(strategy()) == address(0)) {
            // initial state, when not set
            return underlyingBalanceInVault();
        }
        return
            underlyingBalanceInVault().add(
                IStrategy(strategy()).investedUnderlyingBalance()
            );
    }

    function getPricePerFullShare() public view returns (uint256) {
        return
            totalSupply() == 0
                ? underlyingUnit()
                : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(
                    totalSupply()
                );
    }

    /* get the user's share (in underlying)
     */
    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256)
    {
        if (totalSupply() == 0) {
            return 0;
        }
        return
            underlyingBalanceWithInvestment().mul(balanceOf(holder)).div(
                totalSupply()
            );
    }

    function futureStrategy() public view returns (address) {
        return _futureStrategy();
    }

    function strategyUpdateTime() public view returns (uint256) {
        return _strategyUpdateTime();
    }

    function strategyTimeLock() public view returns (uint256) {
        return _strategyTimeLock();
    }

    function canUpdateStrategy(address _strategy) public view returns (bool) {
        return
            strategy() == address(0) || // no strategy was set yet
            (_strategy == futureStrategy() &&
                block.timestamp > strategyUpdateTime() &&
                strategyUpdateTime() > 0); // or the timelock has passed
    }

    /**
     * Indicates that the strategy update will happen in the future
     */
    function announceStrategyUpdate(address _strategy)
        public
        onlyControllerOrGovernance
    {
        // records a new timestamp
        uint256 when = block.timestamp.add(strategyTimeLock());
        _setStrategyUpdateTime(when);
        _setFutureStrategy(_strategy);
        emit StrategyAnnounced(_strategy, when);
    }

    /**
     * Finalizes (or cancels) the strategy update by resetting the data
     */
    function finalizeStrategyUpdate() public onlyControllerOrGovernance {
        _setStrategyUpdateTime(0);
        _setFutureStrategy(address(0));
    }

    function setStrategy(address _strategy) public onlyControllerOrGovernance {
        require(
            canUpdateStrategy(_strategy),
            "The strategy exists and switch timelock did not elapse yet"
        );
        require(_strategy != address(0), "new _strategy cannot be empty");
        require(
            IStrategy(_strategy).underlying() == address(underlying()),
            "Vault underlying must match Strategy underlying"
        );
        require(
            IStrategy(_strategy).vault() == address(this),
            "the strategy does not belong to this vault"
        );

        emit StrategyChanged(_strategy, strategy());
        if (address(_strategy) != address(strategy())) {
            if (address(strategy()) != address(0)) {
                // if the original strategy (no underscore) is defined
                IERC20(underlying()).safeApprove(address(strategy()), 0);
                IStrategy(strategy()).withdrawAllToVault();
            }
            _setStrategy(_strategy);
            IERC20(underlying()).safeApprove(address(strategy()), 0);
            IERC20(underlying()).safeApprove(address(strategy()), uint256(~0));
        }
        finalizeStrategyUpdate();
    }

    function setVaultFractionToInvest(uint256 numerator, uint256 denominator)
        external
        onlyGovernance
    {
        require(denominator > 0, "denominator must be greater than 0");
        require(
            numerator <= denominator,
            "denominator must be greater than or equal to the numerator"
        );
        _setVaultFractionToInvestNumerator(numerator);
        _setVaultFractionToInvestDenominator(denominator);
    }

    function setWithdrawFee(uint256 value) external onlyGovernance {
        return _setWithdrawFee(value);
    }

    function rebalance() external onlyControllerOrGovernance {
        withdrawAll();
        invest();
    }

    function availableToInvestOut() public view returns (uint256) {
        uint256 wantInvestInTotal =
            underlyingBalanceWithInvestment()
                .mul(vaultFractionToInvestNumerator())
                .div(vaultFractionToInvestDenominator());
        uint256 alreadyInvested =
            IStrategy(strategy()).investedUnderlyingBalance();
        if (alreadyInvested >= wantInvestInTotal) {
            return 0;
        } else {
            uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
            return
                remainingToInvest <= underlyingBalanceInVault() // TODO: we think that the "else" branch of the ternary operation is not // going to get hit
                    ? remainingToInvest
                    : underlyingBalanceInVault();
        }
    }

    function invest() internal whenStrategyDefined {
        uint256 availableAmount = availableToInvestOut();
        if (availableAmount > 0) {
            IERC20(underlying()).safeTransfer(
                address(strategy()),
                availableAmount
            );
            emit Invest(availableAmount);
        }
    }

    /*
     * Allows for depositing the ETH in exchange for shares.
     */
    function depositETH() external payable defense {
        WETH9(underlying()).deposit.value(msg.value)();
        _deposit(msg.value, msg.sender);
    }

    /*
     * Allows for depositing the underlying asset in exchange for shares.
     * Approval is assumed.
     */
    function deposit(uint256 amount) external defense {
        IERC20(underlying()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _deposit(amount, msg.sender);
    }

    /*
     * Allows for depositing the underlying asset in exchange for shares
     * assigned to the holder.
     * This facilitates depositing for someone else (using DepositHelper)
     */
    function depositFor(uint256 amount, address holder) public defense {
        IERC20(underlying()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _deposit(amount, holder);
    }

    function withdrawAll()
        public
        onlyControllerOrGovernance
        whenStrategyDefined
    {
        IStrategy(strategy()).withdrawAllToVault();
    }

    function withdraw(uint256 numberOfShares) external {
        require(totalSupply() > 0, "Vault has no shares");
        require(numberOfShares > 0, "numberOfShares must be greater than 0");
        uint256 totalSupply = totalSupply();
        _burn(msg.sender, numberOfShares);

        uint256 underlyingAmountToWithdraw =
            underlyingBalanceWithInvestment().mul(numberOfShares).div(
                totalSupply
            );
        uint256 originalDepositsToWithdraw =
            _totalDeposits().mul(numberOfShares).div(totalSupply);
        if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
            // withdraw everything from the strategy to accurately check the share value
            if (numberOfShares == totalSupply) {
                IStrategy(strategy()).withdrawAllToVault();
            } else {
                uint256 missing =
                    underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
                IStrategy(strategy()).withdrawToVault(missing);
            }
            // recalculate to improve accuracy
            underlyingAmountToWithdraw = Math.min(
                underlyingBalanceWithInvestment().mul(numberOfShares).div(
                    totalSupply
                ),
                underlyingBalanceInVault()
            );
        }

        uint256 fee = underlyingAmountToWithdraw.mul(withdrawFee()).div(1000);
        uint256 amountWithoutFee = underlyingAmountToWithdraw.sub(fee);
        WETH9(underlying()).approve(underlying(), amountWithoutFee);
        WETH9(underlying()).withdraw(amountWithoutFee);
        msg.sender.transfer(amountWithoutFee);

        _setTotalDeposits(_totalDeposits().sub(originalDepositsToWithdraw));
        if (fee > 0) {
            IERC20(underlying()).safeTransfer(
                IController(controller()).treasury(),
                fee
            );
        }
        // update the withdrawal amount for the holder
        emit Withdraw(msg.sender, underlyingAmountToWithdraw);
    }

    function _deposit(uint256 amount, address beneficiary) internal {
        require(amount > 0, "Cannot deposit 0");
        require(beneficiary != address(0), "holder must be defined");

        if (address(strategy()) != address(0)) {
            require(IStrategy(strategy()).depositArbCheck(), "Too much arb");
        }

        uint256 toMint =
            totalSupply() == 0
                ? amount
                : amount.mul(totalSupply()).div(
                    underlyingBalanceWithInvestment()
                );
        _mint(beneficiary, toMint);
        _setTotalDeposits(_totalDeposits().add(amount));
        // update the contribution amount for the beneficiary
        emit Deposit(beneficiary, amount);
    }

    /**
     * Schedules an upgrade for this vault's proxy.
     */
    function scheduleUpgrade(address impl) public onlyGovernance {
        _setNextImplementation(impl);
        _setNextImplementationTimestamp(
            block.timestamp.add(nextImplementationDelay())
        );
    }

    function shouldUpgrade() external view returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0 &&
                block.timestamp > nextImplementationTimestamp() &&
                nextImplementation() != address(0),
            nextImplementation()
        );
    }

    function finalizeUpgrade() external onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    function() external payable {}
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

contract VaultStorage is Initializable {
    bytes32 internal constant _STRATEGY_SLOT =
        0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;
    bytes32 internal constant _UNDERLYING_SLOT =
        0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
    bytes32 internal constant _UNDERLYING_UNIT_SLOT =
        0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;
    bytes32 internal constant _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT =
        0x39122c9adfb653455d0c05043bd52fcfbc2be864e832efd3abc72ce5a3d7ed5a;
    bytes32 internal constant _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT =
        0x469a3bad2fab7b936c45eecd1f5da52af89cead3e2ed7f732b6f3fc92ed32308;
    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT =
        0xb1acf527cd7cd1668b30e5a9a1c0d845714604de29ce560150922c9d8c0937df;
    bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT =
        0x3bc747f4b148b37be485de3223c90b4468252967d2ea7f9fcbd8b6e653f434c9;
    bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT =
        0x82ddc3be3f0c1a6870327f78f4979a0b37b21b16736ef5be6a7a7a35e530bcf0;
    bytes32 internal constant _STRATEGY_TIME_LOCK_SLOT =
        0x6d02338b2e4c913c0f7d380e2798409838a48a2c4d57d52742a808c82d713d8b;
    bytes32 internal constant _FUTURE_STRATEGY_SLOT =
        0xb441b53a4e42c2ca9182bc7ede99bedba7a5d9360d9dfbd31fa8ee2dc8590610;
    bytes32 internal constant _STRATEGY_UPDATE_TIME_SLOT =
        0x56e7c0e75875c6497f0de657009613a32558904b5c10771a825cc330feff7e72;
    bytes32 internal constant _WITHDRAW_FEE =
        0x3405c96d34f8f0e36eac648034ca7e687437f795bbdbdc2cb7db90a89d519f57;
    bytes32 internal constant _TOTAL_DEPOSITS =
        0xaf765835ed5af0d235b6c686724ad31fa90e06b3daf1c074d6cc398b8fcef213;

    constructor() public {
        assert(
            _STRATEGY_SLOT ==
                bytes32(uint256(keccak256("eip1967.vaultStorage.strategy")) - 1)
        );
        assert(
            _UNDERLYING_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.underlying")) - 1
                )
        );
        assert(
            _UNDERLYING_UNIT_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) -
                        1
                )
        );
        assert(
            _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.vaultFractionToInvestNumerator"
                        )
                    ) - 1
                )
        );
        assert(
            _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.vaultFractionToInvestDenominator"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.vaultStorage.nextImplementation")
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.nextImplementationTimestamp"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_DELAY_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.nextImplementationDelay"
                        )
                    ) - 1
                )
        );
        assert(
            _STRATEGY_TIME_LOCK_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.vaultStorage.strategyTimeLock")
                    ) - 1
                )
        );
        assert(
            _FUTURE_STRATEGY_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.futureStrategy")) -
                        1
                )
        );
        assert(
            _STRATEGY_UPDATE_TIME_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.vaultStorage.strategyUpdateTime")
                    ) - 1
                )
        );
        assert(
            _WITHDRAW_FEE ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.withdrawFee")) - 1
                )
        );
        assert(
            _TOTAL_DEPOSITS ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.totalDeposits")) - 1
                )
        );
    }

    function initialize(
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator,
        uint256 _underlyingUnit,
        uint256 _implementationChangeDelay,
        uint256 _strategyChangeDelay
    ) public initializer {
        _setUnderlying(_underlying);
        _setVaultFractionToInvestNumerator(_toInvestNumerator);
        _setVaultFractionToInvestDenominator(_toInvestDenominator);
        _setUnderlyingUnit(_underlyingUnit);
        _setNextImplementationDelay(_implementationChangeDelay);
        _setStrategyTimeLock(_strategyChangeDelay);
        _setStrategyUpdateTime(0);
        _setFutureStrategy(address(0));
    }

    function _setStrategy(address _address) internal {
        setAddress(_STRATEGY_SLOT, _address);
    }

    function _strategy() internal view returns (address) {
        return getAddress(_STRATEGY_SLOT);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _underlying() internal view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        setUint256(_UNDERLYING_UNIT_SLOT, _value);
    }

    function _underlyingUnit() internal view returns (uint256) {
        return getUint256(_UNDERLYING_UNIT_SLOT);
    }

    function _setVaultFractionToInvestNumerator(uint256 _value) internal {
        setUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT, _value);
    }

    function _vaultFractionToInvestNumerator() internal view returns (uint256) {
        return getUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT);
    }

    function _setVaultFractionToInvestDenominator(uint256 _value) internal {
        setUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT, _value);
    }

    function _vaultFractionToInvestDenominator()
        internal
        view
        returns (uint256)
    {
        return getUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT);
    }

    function _setWithdrawFee(uint256 _value) internal {
        setUint256(_WITHDRAW_FEE, _value);
    }

    function _withdrawFee() internal view returns (uint256) {
        return getUint256(_WITHDRAW_FEE);
    }

    function _setTotalDeposits(uint256 _value) internal {
        setUint256(_TOTAL_DEPOSITS, _value);
    }

    function _totalDeposits() internal view returns (uint256) {
        return getUint256(_TOTAL_DEPOSITS);
    }

    function _setNextImplementation(address _address) internal {
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
    }

    function _nextImplementation() internal view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
    }

    function _nextImplementationTimestamp() internal view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
    }

    function _setNextImplementationDelay(uint256 _value) internal {
        setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
    }

    function _nextImplementationDelay() internal view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
    }

    function _setStrategyTimeLock(uint256 _value) internal {
        setUint256(_STRATEGY_TIME_LOCK_SLOT, _value);
    }

    function _strategyTimeLock() internal view returns (uint256) {
        return getUint256(_STRATEGY_TIME_LOCK_SLOT);
    }

    function _setFutureStrategy(address _value) internal {
        setAddress(_FUTURE_STRATEGY_SLOT, _value);
    }

    function _futureStrategy() internal view returns (address) {
        return getAddress(_FUTURE_STRATEGY_SLOT);
    }

    function _setStrategyUpdateTime(uint256 _value) internal {
        setUint256(_STRATEGY_UPDATE_TIME_SLOT, _value);
    }

    function _strategyUpdateTime() internal view returns (uint256) {
        return getUint256(_STRATEGY_UPDATE_TIME_SLOT);
    }

    function setAddress(bytes32 slot, address _address) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function getAddress(bytes32 slot) private view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) private view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    uint256[50] private ______gap;
}

pragma solidity 0.5.16;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns (bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function forceUnleashed(address _vault) external;

    function hasVault(address _vault) external returns (bool);

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(
        address _strategy,
        address _token,
        uint256 amount
    ) external;

    function notifyFee(address _underlying, uint256 fee) external;

    function profitSharingNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);

    function treasury() external view returns (address);
}

pragma solidity 0.5.16;

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external;

    function forceUnleashed() external;

    function depositArbCheck() external view returns (bool);
}

pragma solidity 0.5.16;

interface IUpgradeSource {
    function shouldUpgrade() external view returns (bool, address);

    function finalizeUpgrade() external;
}

pragma solidity 0.5.16;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function setVaultFractionToInvest(uint256 numerator, uint256 denominator)
        external;

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);

    // force unleash should be callable only by the controller (by the force unleasher) or by governance
    function forceUnleashed() external;

    function rebalance() external;
}

// based on https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
 */

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.5.16;

contract WETH9 {
    function balanceOf(address target) public view returns (uint256);

    function deposit() public payable;

    function withdraw(uint256 wad) public;

    function totalSupply() public view returns (uint256);

    function approve(address guy, uint256 wad) public returns (bool);

    function transfer(address dst, uint256 wad) public returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool);
}

/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}