// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IStrategy {
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function emergencyWithdraw() external;
    function updateMinTokensToReinvest(uint newValue) external;
    function updateAdminFee(uint newValue) external;
    function updateReinvestReward(uint newValue) external;
    function recoverERC20(address tokenAddress, uint tokenAmount) external;
    function recoverAVAX(uint amount) external;
}

contract YakTimelockForDexStrategyV2 {

    uint public constant timelockLengthForAssetRecovery = 2 minutes;
    uint public constant timelockLengthForOwnershipTransfer = 5 minutes;
    uint public constant timelockLengthForFeeChanges = 1 minutes;

    address public manager;
    address public feeCollector;

    mapping(address => address) public pendingOwners;
    mapping(address => uint) public pendingAdminFees;
    mapping(address => uint) public pendingReinvestRewards;
    mapping(address => address) public pendingTokenAddressesToRecover;
    mapping(address => uint) public pendingTokenAmountsToRecover;
    mapping(address => uint) public pendingAVAXToRecover;

    event ProposeOwner(address indexed strategy, address indexed proposedValue, uint timelock);
    event ProposeAdminFee(address indexed strategy, uint proposedValue, uint timelock);
    event ProposeReinvestReward(address indexed strategy, uint proposedValue, uint timelock);
    event ProposeRecovery(address indexed strategy, address indexed proposedToken, uint proposedValue, uint timelock);

    event SetOwner(address indexed strategy, address indexed newValue);
    event SetAdminFee(address indexed strategy, uint newValue);
    event SetReinvestReward(address indexed strategy, uint newValue);
    event SetMinTokensToReinvest(address indexed strategy, uint newValue);
    event Sweep(address indexed token, uint amount);
    event Recover(address indexed strategy, address indexed token, uint amount);
    event EmergencyWithdraw(address indexed strategy);

    enum Functions {
        renounceOwnership,
        transferOwnership,
        emergencyWithdraw,
        updateMinTokensToReinvest,
        updateAdminFee,
        updateReinvestReward,
        recoverERC20,
        recoverAVAX
    }

    mapping(address => mapping(Functions => uint)) public timelock;

    constructor() {
        manager = msg.sender;
        feeCollector = msg.sender;
    }

    // Modifiers

    /**
     * @notice Restrict to `manager`
     * @dev To change manager, deploy new timelock and transfer strategy ownership
     */
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    /**
     * @notice Restrict to `feeCollector`
     * @dev To change feeCollector, deploy new timelock and transfer strategy ownership
     */
    modifier onlyFeeCollector {
        require(msg.sender == feeCollector);
        _;
    }

    /**
     * @notice Set timelock when changing pending values
     * @param _strategy address
     * @param _fn Function enum value
     * @param timelockLength in seconds
     */
    modifier setTimelock(address _strategy, Functions _fn, uint timelockLength) {
        timelock[_strategy][_fn] = block.timestamp + timelockLength;
        _;
    }

    /**
     * @notice Enforce timelock for a given function
     * @dev Ends execution by resetting timelock to avoid replay
     * @param _strategy address
     * @param _fn Function enum value
     */
    modifier enforceTimelock(address _strategy, Functions _fn) {
        require(timelock[_strategy][_fn] != 0 && timelock[_strategy][_fn] <= block.timestamp, "YakTimelockManager::enforceTimelock");
        _;
        timelock[_strategy][_fn] = 0;
    }

    /**
     * @notice Sweep tokens from the timelock to `feeCollector`
     * @dev The timelock contract may receive assets from both revenue and asset recovery.
     * @dev The sweep function is NOT timelocked, because recovered assets must go through separate timelock functions.
     * @param tokenAddress address
     * @param tokenAmount amount
     */
    function sweepTokens(address tokenAddress, uint tokenAmount) external onlyFeeCollector {
        require(tokenAmount > 0, "YakTimelockManager::sweepTokens, amount too low");
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "YakTimelockManager::sweepTokens, transfer failed");
        emit Sweep(tokenAddress, tokenAmount);
    }

    /**
     * @notice Sweep AVAX from the timelock to the `feeCollector` address
     * @dev The timelock contract may receive assets from both revenue and asset recovery.
     * @dev The sweep function is NOT timelocked, because recovered assets must go through separate timelock functions.
     * @param amount amount
     */
    function sweepAVAX(uint amount) external onlyFeeCollector {
        require(amount > 0, 'YakTimelockManager::sweepAVAX, amount too low');
        msg.sender.transfer(amount);
        emit Sweep(address(0), amount);
    }

    // Functions with timelocks

    /**
     * @notice Pass new value of `owner` through timelock
     * @dev Restricted to `manager` to avoid griefing
     * @dev Resets timelock duration through modifier
     * @param _strategy address
     * @param _pendingOwner new value
     */
    function proposeOwner(address _strategy, address _pendingOwner) external onlyManager 
    setTimelock(_strategy, Functions.transferOwnership, timelockLengthForOwnershipTransfer) {
        pendingOwners[_strategy] = _pendingOwner;
        emit ProposeOwner(_strategy, _pendingOwner, timelock[_strategy][Functions.transferOwnership]);
    }

    /**
     * @notice Set new value of `owner` and resets timelock
     * @dev This can be called by anyone
     * @param _strategy address
     */
    function setOwner(address _strategy) external 
    enforceTimelock(_strategy, Functions.transferOwnership) {
        IStrategy(_strategy).transferOwnership(pendingOwners[_strategy]);
        emit SetOwner(_strategy, pendingOwners[_strategy]);
        pendingOwners[_strategy] = address(0);
    }

    /**
     * @notice Pass new value of `adminFee` through timelock
     * @dev Restricted to `manager` to avoid griefing
     * @dev Resets timelock duration through modifier
     * @param _strategy address
     * @param _pendingAdminFee new value
     */
    function proposeAdminFee(address _strategy, uint _pendingAdminFee) external onlyManager 
    setTimelock(_strategy, Functions.updateAdminFee, timelockLengthForFeeChanges) {
        pendingAdminFees[_strategy] = _pendingAdminFee;
        emit ProposeAdminFee(_strategy, _pendingAdminFee, timelock[_strategy][Functions.updateAdminFee]);
    }

    /**
     * @notice Set new value of `adminFee` and reset timelock
     * @dev This can be called by anyone
     * @param _strategy address
     */
    function setAdminFee(address _strategy) external 
    enforceTimelock(_strategy, Functions.updateAdminFee) {
        IStrategy(_strategy).updateAdminFee(pendingAdminFees[_strategy]);
        emit SetAdminFee(_strategy, pendingAdminFees[_strategy]);
        pendingAdminFees[_strategy] = 0;
    }

    /**
     * @notice Pass new value of `reinvestReward` through timelock
     * @dev Restricted to `manager` to avoid griefing
     * @dev Resets timelock duration through modifier
     * @param _strategy address
     * @param _pendingReinvestReward new value
     */
    function proposeReinvestReward(address _strategy, uint _pendingReinvestReward) external onlyManager 
    setTimelock(_strategy, Functions.updateReinvestReward, timelockLengthForFeeChanges) {
        pendingReinvestRewards[_strategy] = _pendingReinvestReward;
        emit ProposeReinvestReward(_strategy, _pendingReinvestReward, timelock[_strategy][Functions.updateReinvestReward]);
    }

    /**
     * @notice Set new value of `reinvestReward` and reset timelock
     * @dev This can be called by anyone
     * @param _strategy address
     */
    function setReinvestReward(address _strategy) external 
    enforceTimelock(_strategy, Functions.updateReinvestReward) {
        IStrategy(_strategy).updateReinvestReward(pendingReinvestRewards[_strategy]);
        emit SetReinvestReward(_strategy, pendingReinvestRewards[_strategy]);
        pendingReinvestRewards[_strategy] = 0;
    }

    /**
     * @notice Pass values for `recoverERC20` through timelock
     * @dev Restricted to `manager` to avoid griefing
     * @dev Resets timelock duration through modifier
     * @param _strategy address
     * @param _pendingTokenAddressToRecover address
     * @param _pendingTokenAmountToRecover amount
     */
    function proposeRecoverERC20(address _strategy, address _pendingTokenAddressToRecover, uint _pendingTokenAmountToRecover) external onlyManager 
    setTimelock(_strategy, Functions.recoverERC20, timelockLengthForAssetRecovery) {
        pendingTokenAddressesToRecover[_strategy] = _pendingTokenAddressToRecover;
        pendingTokenAmountsToRecover[_strategy] = _pendingTokenAmountToRecover;
        emit ProposeRecovery(_strategy, _pendingTokenAddressToRecover, _pendingTokenAmountToRecover, timelock[_strategy][Functions.recoverERC20]);
    }

    /**
     * @notice Call `recoverERC20` and reset timelock
     * @dev This can be called by anyone
     * @dev Recoverd funds are collected to this timelock and may be swept
     * @param _strategy address
     */
    function setRecoverERC20(address _strategy) external 
    enforceTimelock(_strategy, Functions.recoverERC20) {
        IStrategy(_strategy).recoverERC20(pendingTokenAddressesToRecover[_strategy], pendingTokenAmountsToRecover[_strategy]);
        emit Recover(_strategy, pendingTokenAddressesToRecover[_strategy], pendingTokenAmountsToRecover[_strategy]);
        pendingTokenAddressesToRecover[_strategy] = address(0);
        pendingTokenAmountsToRecover[_strategy] = 0;
    }

    /**
     * @notice Pass values for `recoverAVAX` through timelock
     * @dev Restricted to `manager` to avoid griefing
     * @dev Resets timelock duration through modifier
     * @param _strategy address
     * @param _pendingAVAXToRecover amount
     */
    function proposeRecoverAVAX(address _strategy, uint _pendingAVAXToRecover) external onlyManager 
    setTimelock(_strategy, Functions.recoverAVAX, timelockLengthForAssetRecovery) {
        pendingAVAXToRecover[_strategy] = _pendingAVAXToRecover;
        emit ProposeRecovery(_strategy, address(0), _pendingAVAXToRecover, timelock[_strategy][Functions.recoverAVAX]);
    }

    /**
     * @notice Call `recoverAVAX` and reset timelock
     * @dev This can be called by anyone
     * @dev Recoverd funds are collected to this timelock and may be swept
     * @param _strategy address
     */
    function setRecoverAVAX(address _strategy) external 
    enforceTimelock(_strategy, Functions.recoverAVAX) {
        IStrategy(_strategy).recoverAVAX(pendingAVAXToRecover[_strategy]);
        emit Recover(_strategy, address(0), pendingAVAXToRecover[_strategy]);
        pendingAVAXToRecover[_strategy] = 0;
    }

    // Functions without timelocks

    /**
     * @notice Set new value of `minTokensToReinvest`
     * @dev Restricted to `manager` to avoid griefing
     * @param _strategy address
     * @param minTokensToReinvest new value
     */
    function setMinTokensToReinvest(address _strategy, uint minTokensToReinvest) external onlyManager {
        IStrategy(_strategy).updateMinTokensToReinvest(minTokensToReinvest);
        emit SetMinTokensToReinvest(_strategy, minTokensToReinvest);
    }

    /**
     * @notice Rescues deployed assets to the strategy contract
     * @dev Restricted to `manager` to avoid griefing
     * @dev In case of emergency, assets will be transferred to the timelock and may be swept
     * @param _strategy address
     */
    function emergencyWithdraw(address _strategy) external onlyManager {
        IStrategy(_strategy).emergencyWithdraw();
        emit EmergencyWithdraw(_strategy);
    }
}