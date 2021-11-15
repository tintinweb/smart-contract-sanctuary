// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./common/DecimalConstants.sol";
import "./common/Controllable.sol";
import "./common/Whitelist.sol";
import "./interfaces/ILifeGuard.sol";
import "./interfaces/IBuoy.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IPnL.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWithdrawHandler.sol";
import "./interfaces/IDepositHandler.sol";
import "./interfaces/IEmergencyHandler.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @notice Entry point for withdrawal call to Gro Protocol - User withdrawals come as
///     either single asset or balanced withdrawals, which match the underling lifeguard Curve pool or our
///     Vault allocations. Like deposits, withdrawals come in three different sizes:
///         1) sardine - the smallest type of withdrawals, deemed to not affect the system exposure, and is
///            withdrawn directly from the vaults - Curve vault is used to price the withdrawal (buoy)
///         2) tuna - mid sized withdrawals, will withdraw from the most overexposed vault and exchange into
///            the desired asset (lifeguard). If the most overexposed asset is withdrawn, no exchange takes
///            place, this minimizes slippage as it doesn't need to perform any exchanges in the Curve pool
///         3) whale - the largest withdrawal - Withdraws from all stablecoin vaults in target deltas,
///            calculated as the difference between target allocations and vaults exposure (insurance). Uses
///            Curve pool to exchange withdrawns assets to desired assets.
contract WithdrawHandler is DecimalConstants, Controllable, Whitelist, IWithdrawHandler {
    // Pwrd (true) and gvt (false) mapped to respective withdrawal fee
    mapping(bool => uint256) public override withdrawalFee;
    // Lower bound for how many gvt can be burned before getting to close to the utilisation ratio
    uint256 public utilisationRatioLimitGvt;
    IEmergencyHandler emergencyHandler;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IController ctrl;
    ILifeGuard lg;
    IBuoy buoy;
    IInsurance insurance;
    mapping(bool => IToken) gTokens;

    event LogNewWithdrawalFee(address user, bool pwrd, uint256 newFee);
    event LogNewUtilLimit(bool indexed pwrd, uint256 limit);
    event LogNewEmergencyHandler(address EMH);
    event LogNewDependencies(
        address controller, 
        address lifeguard, 
        address buoy, 
        address insurance,
        address pwrd,
        address gvt
    );
    event LogNewWithdrawal(
        address indexed user,
        address indexed referral,
        bool pwrd,
        bool balanced,
        bool all,
        uint256 deductUsd,
        uint256 returnUsd,
        uint256 lpAmount,
        uint256[] tokenAmounts
    );

    // Data structure to hold data for withdrawals
    struct WithdrawParameter {
        address account;
        bool pwrd;
        bool balanced;
        bool all;
        uint256 index;
        uint256[] minAmounts;
        uint256 lpAmount;
    }

    /// @notice Update protocol dependencies
    function setDependencies() external onlyGovernance {
        ctrl = _controller();
        lg = ILifeGuard(ctrl.lifeGuard());
        buoy = IBuoy(lg.getBuoy());
        insurance = IInsurance(ctrl.insurance());
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

    /// @notice Set withdrawal fee for token
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param newFee New token fee
    function setWithdrawalFee(bool pwrd, uint256 newFee) external onlyGovernance {
        withdrawalFee[pwrd] = newFee;
        emit LogNewWithdrawalFee(msg.sender, pwrd, newFee);
    }

    /// @notice Set the lower bound for when to stop accepting gvt withdrawals
    /// @param _utilisationRatioLimitGvt Lower limit for pwrd (%BP)
    function setUtilisationRatioLimitGvt(uint256 _utilisationRatioLimitGvt)
        external
        onlyGovernance
    {
        utilisationRatioLimitGvt = _utilisationRatioLimitGvt;
        emit LogNewUtilLimit(false, _utilisationRatioLimitGvt);
    }

    function setEmergencyHandler(address EMH) external onlyGovernance {
        emergencyHandler = IEmergencyHandler(EMH);
        emit LogNewEmergencyHandler(EMH);
    }

    /// @notice Withdrawing by LP tokens will attempt to do a balanced
    ///     withdrawal from the lifeguard - Balanced meaning that the withdrawal
    ///     tries to match the token balances of the underlying Curve pool.
    ///     TODO: This should match gro protocol current delta between target allocation and actual assets.
    ///     This is calculated by dividing the individual token balances of
    ///     the pool by the total amount. This should give minimal slippage.
    /// @param pwrd Pwrd or Gvt (pwrd/gvt)
    /// @param lpAmount Amount of LP tokens to burn
    /// @param minAmounts Minimum accepted amount of tokens to get back
    function withdrawByLPToken(
        bool pwrd,
        uint256 lpAmount,
        uint256[] calldata minAmounts
    ) external override whenNotPaused {
        WithdrawParameter memory parameters =
            WithdrawParameter(
                msg.sender,
                pwrd,
                true,
                false,
                ctrl.stablecoinsCount(),
                minAmounts,
                lpAmount
            );
        _withdraw(parameters);
    }

    /// @notice Withdraws by one token from protocol.
    /// @param pwrd Pwrd or Gvt (pwrd/gvt)
    /// @param index Protocol index of stablecoin
    /// @param lpAmount LP token amount to burn
    /// @param minAmount Minimum amount of tokens to get back
    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external override whenNotStopped(pwrd) {
        uint256 count = ctrl.stablecoinsCount();
        require(index < count, "!withdrawByStablecoin: invalid index");
        uint256[] memory minAmounts = new uint256[](count);
        minAmounts[index] = minAmount;
        WithdrawParameter memory parameters =
            WithdrawParameter(msg.sender, pwrd, false, false, index, minAmounts, lpAmount);
        _withdraw(parameters);
    }

    /// @notice Withdraw all pwrd/gvt for a specifc stablecoin
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param index Protocol index of stablecoin
    /// @param minAmount Minimum amount of returned assets
    function withdrawAllSingle(
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) external override whenNotFullyStopped(pwrd) {
        if (stopped()) {
            emergencyHandler.emergencyWithdrawal(msg.sender, index, minAmount);
        } else {
            _withdrawAllSingleFromAccount(msg.sender, pwrd, index, minAmount);
        }
    }

    /// @notice Burn a pwrd/gvt for a balanced amount of stablecoin assets
    /// @param pwrd Pwrd or Gvt (pwrd/gvt)
    /// @param minAmounts Minimum amount of returned assets
    function withdrawAllBalanced(bool pwrd, uint256[] calldata minAmounts)
        external
        override
        whenNotPaused
    {
        WithdrawParameter memory parameters =
            WithdrawParameter(
                msg.sender,
                pwrd,
                true,
                true,
                ctrl.stablecoinsCount(),
                minAmounts,
                0
            );
        _withdraw(parameters);
    }

    /// @notice Function to get deltas for balanced withdrawals
    /// @param amount Amount to withdraw (denoted in LP tokens)
    /// @dev This function should be used to determine input values
    ///     when atempting a balanced withdrawal
    function getVaultDeltas(uint256 amount) external view returns (uint256[] memory tokenAmounts) {
        uint256[] memory delta = insurance.getDelta(buoy.lpToUsd(amount));
        uint256 coins = lg.N_COINS();
        tokenAmounts = new uint256[](coins);
        for (uint256 i; i < coins; i++) {
            uint256 withdraw = amount.mul(delta[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            if (withdraw > 0) tokenAmounts[i] = buoy.singleStableFromLp(withdraw, int128(i));
        }
    }

    /// @notice Prepare for a single sided withdraw all action
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param index Index of token
    /// @param minAmount Minimum amount accepted in return
    function _withdrawAllSingleFromAccount(
        address account,
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) private {
        uint256 count = ctrl.stablecoinsCount();
        require(index < count, "!withdrawAllSingleFromAccount: invalid index");
        uint256[] memory minAmounts = new uint256[](count);
        minAmounts[index] = minAmount;
        WithdrawParameter memory parameters =
            WithdrawParameter(account, pwrd, false, true, index, minAmounts, 0);
        _withdraw(parameters);
    }

    /// @notice Main withdraw logic
    /// @param parameters Struct holding withdraw info
    function _withdraw(WithdrawParameter memory parameters) private {
        ctrl.eoaOnly(msg.sender);
        // flash loan preventation
        ctrl.preventFLABegin();

        IToken gt = gTokens[parameters.pwrd];
        uint256 deductUsd;
        uint256 returnUsd;
        uint256 lpAmount;
        uint256 lpAmountFee;
        uint256[] memory tokenAmounts;
        // If it's a "withdraw all" action
        uint256 virtualPrice = buoy.getVirtualPrice();
        if (parameters.all) {
            (deductUsd, returnUsd) = calculateWithdrawalAmountForAll(
                parameters.pwrd,
                parameters.account
            );
            lpAmountFee = returnUsd.mul(DEFAULT_DECIMALS_FACTOR).div(virtualPrice);
            // If it's a normal withdrawal
        } else {
            lpAmount = parameters.lpAmount;
            uint256 fee =
                lpAmount.mul(withdrawalFee[parameters.pwrd]).div(PERCENTAGE_DECIMAL_FACTOR);
            lpAmountFee = lpAmount.sub(fee);
            returnUsd = lpAmountFee.mul(virtualPrice).div(DEFAULT_DECIMALS_FACTOR);
            deductUsd = lpAmount.mul(virtualPrice).div(DEFAULT_DECIMALS_FACTOR);
            require(
                deductUsd <= gt.getAssets(parameters.account),
                "!withdraw: not enough balance"
            );
        }

        bool whale = ctrl.isWhale(returnUsd, parameters.pwrd);
        if (whale) {
            IPnL pnl = IPnL(ctrl.pnl());
            if (pnl.pnlTrigger()) {
                pnl.execPnL(0);

                // Recalculate withdrawal amounts after pnl
                if (parameters.all) {
                    (deductUsd, returnUsd) = calculateWithdrawalAmountForAll(
                        parameters.pwrd,
                        parameters.account
                    );
                    lpAmountFee = returnUsd.mul(DEFAULT_DECIMALS_FACTOR).div(virtualPrice);
                }
            }
        }

        // If it's a balanced withdrawal
        if (parameters.balanced) {
            (returnUsd, tokenAmounts) = _withdrawBalanced(
                parameters.account,
                parameters.pwrd,
                lpAmountFee,
                parameters.minAmounts,
                returnUsd
            );
            // If it's a single asset withdrawal
        } else {
            tokenAmounts = new uint256[](parameters.minAmounts.length);
            (returnUsd, tokenAmounts[parameters.index]) = _withdrawSingle(
                parameters.account,
                parameters.pwrd,
                lpAmountFee,
                parameters.minAmounts[parameters.index],
                parameters.index,
                returnUsd,
                whale
            );
        }

        // Check if new token amount breaks utilisation ratio
        if (!parameters.pwrd) {
            require(validGTokenDecrease(deductUsd), "exceeds utilisation limit");
        }

        if (!parameters.all) {
            gt.burn(parameters.account, gt.factor(), deductUsd);
        } else {
            gt.burnAll(parameters.account);
        }
        // Update underlying assets held in pwrd/gvt
        IPnL(ctrl.pnl()).decreaseGTokenLastAmount(address(gt), deductUsd);

        emit LogNewWithdrawal(
            parameters.account,
            IDepositHandler(ctrl.depositHandler()).referral(parameters.account),
            parameters.pwrd,
            parameters.balanced,
            parameters.all,
            deductUsd,
            returnUsd,
            lpAmountFee,
            tokenAmounts
        );

        ctrl.preventFLAEnd();
    }

    /// @notice Withdrawal logic of single asset withdrawals
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param lpAmount LP token value of withdrawal
    /// @param minAmount Minimum amount accepted in return
    /// @param index Index of token
    /// @param withdrawUsd USD value of withdrawals
    /// @param whale Whale withdrawal
    function _withdrawSingle(
        address account,
        bool pwrd,
        uint256 lpAmount,
        uint256 minAmount,
        uint256 index,
        uint256 withdrawUsd,
        bool whale
    ) private returns (uint256 dollarAmount, uint256 tokenAmount) {
        dollarAmount = withdrawUsd;
        // Is the withdrawal large...
        if (whale) {
            (dollarAmount, tokenAmount) = _prepareForWithdrawalSingle(
                account,
                pwrd,
                lpAmount,
                index,
                minAmount,
                withdrawUsd
            );
        } else {
            // ... or small
            IVault adapter = IVault(ctrl.vaults()[index]);
            tokenAmount = buoy.singleStableFromLp(lpAmount, int128(index));
            adapter.withdrawByStrategyOrder(tokenAmount, account, pwrd);
        }
        require(tokenAmount >= minAmount, "!withdrawSingle: !minAmount");
    }

    /// @notice Withdrawal logic of balanced withdrawals - Balanced withdrawals
    ///     pull out assets from vault by delta difference between target allocations
    ///     and actual vault amounts ( insurane getDelta ). These withdrawals should
    ///     have minimal impact on user funds as they dont interact with curve (no slippage),
    ///     but are only possible as long as there are assets available to cover the withdrawal
    ///     in the stablecoin vaults - as no swapping or realancing will take place.
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param lpAmount LP token value of withdrawal
    /// @param minAmounts Minimum amounts accepted in return
    /// @param withdrawUsd USD value of withdrawals
    function _withdrawBalanced(
        address account,
        bool pwrd,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 withdrawUsd
    ) private returns (uint256 dollarAmount, uint256[] memory tokenAmounts) {
        uint256 coins = lg.N_COINS();
        tokenAmounts = new uint256[](coins);
        uint256[] memory delta = insurance.getDelta(withdrawUsd);
        for (uint256 i; i < coins; i++) {
            uint256 withdraw = lpAmount.mul(delta[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            if (withdraw > 0) tokenAmounts[i] = buoy.singleStableFromLp(withdraw, int128(i));
            require(tokenAmounts[i] >= minAmounts[i], "!withdrawBalanced: !minAmount");
            IVault adapter = IVault(ctrl.vaults()[i]);
            require(
                tokenAmounts[i] <= adapter.totalAssets(),
                "!withdrawBalanced: !adapterBalance"
            );
            adapter.withdrawByStrategyOrder(tokenAmounts[i], account, pwrd);
        }
        dollarAmount = buoy.stableToUsd(tokenAmounts, false);
    }

    /// @notice Withdrawal logic for large single asset withdrawals.
    ///     Large withdrawals are routed through the insurance layer to
    ///     ensure that withdrawal dont affect protocol exposure.
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param lpAmount LP token value of withdrawal
    /// @param minAmount Minimum amount accepted in return
    /// @param index Index of token
    /// @param withdrawUsd USD value of withdrawals
    function _prepareForWithdrawalSingle(
        address account,
        bool pwrd,
        uint256 lpAmount,
        uint256 index,
        uint256 minAmount,
        uint256 withdrawUsd
    ) private returns (uint256 dollarAmount, uint256 amount) {
        // PnL executes during the rebalance
        insurance.rebalanceForWithdraw(withdrawUsd, pwrd);
        (dollarAmount, amount) = lg.withdrawSingleCoin(lpAmount, index, minAmount, account);
        require(minAmount <= amount, "!prepareForWithdrawalSingle: !minAmount");
    }

    /// @notice Check if it's OK to burn the specified amount of tokens, this affects
    ///     gvt, as they have a lower bound set by the amount of pwrds
    /// @param amount Amount of token to burn
    function validGTokenDecrease(uint256 amount) private view returns (bool) {
        address gvt = ctrl.gvt();
        address pwrd = ctrl.pwrd();

        return
            IToken(gvt).totalAssets().sub(amount).mul(utilisationRatioLimitGvt).div(
                PERCENTAGE_DECIMAL_FACTOR
            ) >= IERC20(pwrd).totalSupply();
    }

    /// @notice Calcualte withdrawal value when withdrawing all
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param account User account
    function calculateWithdrawalAmountForAll(bool pwrd, address account)
        private
        view
        returns (uint256 deductUsd, uint256 returnUsd)
    {
        IToken gt = gTokens[pwrd];
        deductUsd = gt.getAssets(account);
        returnUsd = deductUsd.sub(
            deductUsd.mul(withdrawalFee[pwrd]).div(PERCENTAGE_DECIMAL_FACTOR)
        );
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

contract DecimalConstants {

    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR =
        uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant PRICE_DECIMALS = 10;
    uint256 public constant PRICE_DECIMAL_FACTOR = uint256(10)**PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR =
        uint256(10)**PERCENTAGE_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./Governable.sol";
import "../common/Pausable.sol";
import "../interfaces/IController.sol";
import "../interfaces/IPausable.sol";

contract Controllable is Governable {
    // The value of bytes32(uint256(keccak256("eip1967.tokenStorage.controller")) - 1)
    bytes32 private constant _CONTROLLER_SLOT =
        0xfdf48aecab6422687a311a9c0d7af40d74e1f71b7e8aac1fad2fa37ac4f39a73;

    event ChangeController(address indexed oldController, address indexed newController);

    modifier onlyController() {
        require(controller() == msg.sender, "only Controller");
        _;
    }

    /// Modifier to make a function callable only when the contract is not paused.
    /// Requirements:
    /// - The contract must not be paused.
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenNotStopped(bool pwrd) {
        if (paused()) {
            require(pwrd, 'Pausable: !pwrd');
        } 
        require(!stopped(), 'pausable: !Stopped');
        _;
    }

    modifier whenNotFullyStopped(bool pwrd) {
        if (paused()) {
            require(pwrd, 'Pausable: !pwrd');
        } 
        require(!halted(), "Pausable: fully stopped");
        _;
    }

    /// Modifier to make a function callable only when the contract is paused
    /// Requirements:
    /// - The contract must be paused
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenStopped() {
        require(stopped(), "Pausable: not stopped");
        _;
    }

    modifier whenFullyStopped() {
        require(halted(), "Pausable: not fully stopped");
        _;
    }
    function setController(address newController)
        external
        onlyGovernance
        notZeroAddress(newController)
    {
        address oldController = controller();
        setAddress(_CONTROLLER_SLOT, newController);
        emit ChangeController(oldController, newController);
    }

    function controller() public view returns (address) {
        return getAddress(_CONTROLLER_SLOT);
    }

    function _controller() internal view returns (IController) {
        address controllerAddr = controller();
        require(controllerAddr != address(0), "Controller not set");
        return IController(controllerAddr);
    }

    function _pausable() internal view returns (IPausable) {
        address controllerAddr = controller();
        require(controllerAddr != address(0), "Controller not set");
        return IPausable(controllerAddr);
    }

    /// @notice Returns true if the contract is paused, and false otherwise
    function paused() public view returns (bool) {
        return _pausable().paused();
    }

    /// @notice Returns true if the contract is stopped, and false otherwise
    function stopped() public view returns (bool) {
        return _pausable().stopped();
    }

    /// @notice Returns true if the contract is fully stopped, and false otherwise
    function halted() public view returns (bool) {
        return _pausable().halted();
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./SlotOperation.sol";

contract Governable is SlotOperation {

    // The value of bytes32(uint256(keccak256("eip1967.tokenStorage.governace")) - 1)
    bytes32 private constant _GOVERNANCE_SLOT =
        0xc341bc2d5d9caa883cf8c4557ce30f5c1b39188e2f5d7633be119a36a2c3721a;
    // The value of bytes32(uint256(keccak256("eip1967.tokenStorage.pendingGovernace")) - 1)
    bytes32 private constant _PENDING_GOVERNANCE_SLOT =
        0x811fecbef95912f83732eec949b6f044739489324f9c3f96d1b85814cbff0964;

    event SetPendingGovernance(address indexed pendingGovernance);
    event AcceptGovernance(
        address indexed oldGovernance,
        address indexed newGovernance
    );

    constructor() public {
        setAddress(_GOVERNANCE_SLOT, msg.sender);
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Address is empty.");
        _;
    }

    modifier onlyGovernance() {
        require(
            governance() == msg.sender,
            "Only governance can call this function."
        );
        _;
    }

    modifier onlyPendingGovernance() {
        require(
            pendingGovernance() == msg.sender,
            "Only pending governance can call this function."
        );
        _;
    }

    function changeGovernance(address govern)
        external
        onlyGovernance
        notZeroAddress(govern)
    {
        setAddress(_PENDING_GOVERNANCE_SLOT, govern);
        emit SetPendingGovernance(govern);
    }

    function acceptGovernance() external onlyPendingGovernance {
        address pendingGovernance = pendingGovernance();
        address oldGovernance = governance();
        setAddress(_GOVERNANCE_SLOT, pendingGovernance);
        setAddress(_PENDING_GOVERNANCE_SLOT, address(0));
        emit AcceptGovernance(oldGovernance, pendingGovernance);
    }

    function governance() public view returns (address) {
        return getAddress(_GOVERNANCE_SLOT);
    }

    function pendingGovernance() public view returns (address) {
        return getAddress(_PENDING_GOVERNANCE_SLOT);
    }

    function _setGovernance(address govern) internal notZeroAddress(govern) {
        setAddress(_GOVERNANCE_SLOT, govern);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

contract SlotOperation {

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function setBool(bytes32 slot, bool _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function getAddress(bytes32 slot) internal view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getBool(bytes32 slot) internal view returns (bool str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./Whitelist.sol";
import "../interfaces/IPausable.sol";

/// @notice Contract module which allows children to implement an emergency
///     stop mechanism that can be triggered by an authorized account.
///
///     This module is used through inheritance. It will make available 
///     modifiers such as `whenNotPaused` and `whenPaused`, which can be applied to
///     contract functions that need to be stopped in certain states. Note that they 
///     will not be pausable by simply including this module, only once the modifiers 
///     are put in place.
abstract contract Pausable is Whitelist, IPausable {
    /// @notice Emitted when pause is triggered by `account`
    event LogPaused(address account);

    /// @notice Emitted when pause is lifted by `account`
    event LogUnpaused(address account);

    /// @notice Emitted when stopped is triggered by `account`
    event LogStopped(address account);

    /// @notice Emitted when stopped is lifted by `account`
    event LogStarted(address account);

    /// @notice Emitted when the handbreak is engaged by `account`
    event Loghalted(address account);

    /// @notice Emitted when the handbreak is released by `account`
    event LogUnHalted(address account);

    /// @notice Returns true if the contract is paused, and false otherwise
    bool public override paused;
    /// @notice Returns true if the contract is stopped, and false otherwise
    bool public override stopped;
    /// @notice Returns true if the contract is fully stopped, and false otherwise
    bool public override halted;

    // Initializes the contract in unpaused state.
    constructor() internal {
    }

    /// Modifier to make a function callable only when the contract is not paused.
    /// Requirements:
    /// - The contract must not be paused.
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenNotStopped(bool pwrd) {
        if (paused) {
            require(pwrd, "Pausable: !pwrd");
        }
        require(!stopped, "pausable: !Stopped");
        _;
    }

    modifier whenNotFullyStopped(bool pwrd) {
        if (paused) {
            require(pwrd, "Pausable: !pwrd");
        }
        require(!halted, "Pausable: fully stopped");
        _;
    }

    /// Modifier to make a function callable only when the contract is paused
    /// Requirements:
    /// - The contract must be paused
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier whenStopped() {
        require(stopped, "Pausable: not stopped");
        _;
    }

    modifier whenFullyStopped() {
        require(halted, "Pausable: not fully stopped");
        _;
    }

    /// Triggers stopped state.
    /// Requirements:
    /// - The contract must not be paused.
    function pause() public onlyWhitelist {
        require(!paused, "Pausable: paused");
        paused = true;
        emit LogPaused(msg.sender);
    }

    function stop() public onlyWhitelist {
        require(!stopped, "Pausable: stopped");
        _setPaused(true);
        stopped = true;
        emit LogStopped(msg.sender);
    }

    function handbreakUp() public onlyWhitelist {
        require(!halted, "Pausable: halted");
        _setPaused(true);
        _setStop(true);
        halted = true;
        emit Loghalted(msg.sender);
    }

    // Returns to normal state
    //
    // Requirements:
    // - The contract must be paused
    function unpause() public onlyGovernance {
        require(!stopped, "Pausable: stopped");
        require(paused, "Pausable: !paused");
        paused = false;
        emit LogUnpaused(msg.sender);
    }

    function start() public onlyGovernance {
        require(!halted, "Pausable: halted");
        require(stopped, "Pausable: !stopped");
        stopped = false;
        emit LogStarted(msg.sender);
    }

    function handbrakeDown() public onlyGovernance {
        require(halted, "Pausable: !halted");
        halted = false;
        emit LogUnHalted(msg.sender);
    }

    function _setPaused(bool value) internal {
        paused = value;
        emit LogPaused(msg.sender);
    }

    function _setStop(bool value) internal {
        stopped = value;
        emit LogStopped(msg.sender);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./Governable.sol";

contract Whitelist is Governable {
    mapping(address => bool) public whitelist;

    event NewWhitelist(address indexed user);
    event RemoveWhitelist(address indexed user);

    modifier onlyWhitelist() {
        require(inWhitelist(msg.sender), "only whitelist");
        _;
    }

    function addToWhitelist(address user) external onlyGovernance notZeroAddress(user) {
        whitelist[user] = true;
        emit NewWhitelist(user);
    }

    function removeFromWhitelist(address user) external onlyGovernance notZeroAddress(user) {
        whitelist[user] = false;
        emit RemoveWhitelist(user);
    }

    function inWhitelist(address user) public view notZeroAddress(user) returns (bool) {
        return whitelist[user];
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);

    function stopped() external view returns (bool);

    function halted() external view returns (bool);
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

    function isWhale(uint256 amount, bool _pwrd) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function preventFLABegin() external;

    function preventFLAEnd() external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);
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

    function deposit(uint256[] calldata inAmounts) external returns (uint256 usdAmount);

    function withdraw(uint256 inAmount, address recipient)
        external
        returns (uint256 usdAmount, uint256[] memory amounts);

    function withdrawSingleCoin(
        uint256 inAmount,
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

interface IBuoy{

    function safetyCheck() external view returns (bool);

    function decimals(uint256 index) external view returns(uint256 _decimals);

    function lpToUsd(uint inAmount) external view returns(uint);

    function usdToLp(uint inAmount) external view returns(uint);

    function getRatio(uint256 token0, uint256 token1) external view returns(uint256, uint256);

    function stableToUsd(uint[] calldata inAmount, bool deposit) external view returns(uint);

    function stableToLp(uint[] calldata inAmount, bool deposit) external view returns(uint);

    function singleStableFromLp(uint inAmount, int128 i) external view returns(uint);

    function tokens(uint i) external view returns (address);

    function N_COINS() external view returns (uint);

    function curvePool() external view returns (ICurve3Pool);

    function getVirtualPrice() external view returns (uint256);

    function balancedCalculation(uint256 inAmount)
        external
        view
        returns (uint256[] memory outAmounts);

    function singleStableFromUsd(uint256 inAmount, int128 i)
        external
        view
        returns (uint256);

    function singleStableToUsd(uint256 inAmount, uint256 i)
        external
        view
        returns (uint256);
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

    function lastGvtAssets() external view returns (uint256);

    function lastPwrdAssets() external view returns (uint256);

    function utilisationRatio() external view returns (uint256);
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

interface IWithdrawHandler {
    function withdrawalFee(bool pwrd) external view returns (uint256);

    function withdrawByLPToken(
        bool pwrd,
        uint256 lpAmount,
        uint256[] calldata minAmounts
    ) external;

    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external;

    function withdrawAllSingle(
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) external;

    function withdrawAllBalanced(bool pwrd, uint256[] calldata minAmounts) external;
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

interface IEmergencyHandler {
    function emergencyWithdrawal(address user, uint256 tokenIndex, uint256 minAmounts) external;
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

