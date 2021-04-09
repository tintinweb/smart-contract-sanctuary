// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt ([email protected]).
*/

import "./interfaces/ITimelockController.sol";
import "./lib/0.8/Initializable.sol";

/**
 * @title TipJarManager
 * @dev Responsible for enacting decisions related to sensitive TipJar parameters
 * Decisions are made via a timelock contract
 */
contract TipJarManager is Initializable {

    /// @notice TipJarManager admin
    address public admin;

    /// @notice Delay for critical changes
    uint256 public criticalDelay;

    /// @notice Delay for non-critical changes
    uint256 public regularDelay;

    /// @notice TipJarProxy address
    address public tipJar;

    /// @notice Timelock contract
    ITimelockController public timelock;

    /// @notice Admin modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    /// @notice Timelock modifier
    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "not timelock");
        _;
    }

    /// @notice Miner Split Proposal event
    event MinerSplitProposal(address indexed proposer, address indexed miner, address indexed splitTo, uint32 splitPct, uint256 eta, bytes32 proposalID, bytes32 salt);

    /// @notice Miner Split Approval event
    event MinerSplitApproval(address indexed approver, address indexed miner, address indexed splitTo, uint32 splitPct);

    /// @notice Fee Proposal event
    event FeeProposal(address indexed proposer, uint32 newFee, uint256 eta, bytes32 proposalID, bytes32 salt);

    /// @notice Fee Approval event
    event FeeApproval(address indexed approver, uint32 newFee);

    /// @notice Fee Collector Proposal event
    event FeeCollectorProposal(address indexed proposer, address indexed newCollector, uint256 eta, bytes32 proposalID, bytes32 salt);

    /// @notice Fee Collector Approval event
    event FeeCollectorApproval(address indexed approver, address indexed newCollector);

    /// @notice New admin event
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    /// @notice New delay event
    event DelayChanged(string indexed delayType, uint256 indexed oldDelay, uint256 indexed newDelay);

    /// @notice New timelock event
    event TimelockChanged(address indexed oldTimelock, address indexed newTimelock);

    /// @notice New tip jar event
    event TipJarChanged(address indexed oldTipJar, address indexed newTipJar);

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /// @notice Fallback function to allow contract to accept ETH
    fallback() external payable {}

    /**
     * @notice Construct new TipJarManager contract, setting msg.sender as admin
     */
    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), msg.sender);
    }

    /**
     * @notice Initialize contract
     * @param _tipJar TipJar proxy contract address
     * @param _admin Admin address
     * @param _timelock TimelockController contract address
     */
    function initialize(
        address _tipJar,
        address _admin,
        address payable _timelock,
        uint256 _criticalDelay,
        uint256 _regularDelay
    ) external initializer onlyAdmin {
        emit AdminChanged(admin, _admin);
        admin = _admin;

        tipJar = _tipJar;
        emit TipJarChanged(address(0), _tipJar);
        
        timelock = ITimelockController(_timelock);
        emit TimelockChanged(address(0), _timelock);

        criticalDelay = _criticalDelay;
        emit DelayChanged("critical", 0, _criticalDelay);

        regularDelay = _regularDelay;
        emit DelayChanged("regular", 0, _regularDelay);
    }

    /**
     * @notice Propose a new miner split
     * @param minerAddress Address of miner
     * @param splitTo Address that receives split
     * @param splitPct % of tip that splitTo receives
     * @param salt salt
     */
    function proposeNewMinerSplit(
        address minerAddress,
        address splitTo,
        uint32 splitPct,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("updateMinerSplit(address,address,uint32)")) = 0x8d916340
        bytes32 id = _schedule(tipJar, 0, abi.encodeWithSelector(hex"8d916340", minerAddress, splitTo, splitPct), bytes32(0), salt, regularDelay);
        emit MinerSplitProposal(msg.sender, minerAddress, splitTo, splitPct, block.timestamp + regularDelay, id, salt);
    }

    /**
     * @notice Approve a new miner split
     * @param minerAddress Address of miner
     * @param splitTo Address that receives split
     * @param splitPct % of tip that splitTo receives
     * @param salt salt
     */
    function approveNewMinerSplit(
        address minerAddress,
        address splitTo,
        uint32 splitPct,
        bytes32 salt
    ) external {
        // bytes4(keccak256("updateMinerSplit(address,address,uint32)")) = 0x8d916340
        _execute(tipJar, 0, abi.encodeWithSelector(hex"8d916340", minerAddress, splitTo, splitPct), bytes32(0), salt);
        emit MinerSplitApproval(msg.sender, minerAddress, splitTo, splitPct);
    }

    /**
     * @notice Propose a new network fee
     * @param newFee New fee
     * @param salt salt
     */
    function proposeNewFee(
        uint32 newFee, 
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setFee(uint32)")) = 0x1ab971ab
        bytes32 id = _schedule(tipJar, 0, abi.encodeWithSelector(hex"1ab971ab", newFee), bytes32(0), salt, criticalDelay);
        emit FeeProposal(msg.sender, newFee, block.timestamp + regularDelay, id, salt);
    }

    /**
     * @notice Approve a new network fee
     * @param newFee New fee
     * @param salt salt
     */
    function approveNewFee(
        uint32 newFee, 
        bytes32 salt
    ) external {
        // bytes4(keccak256("setFee(uint32)")) = 0x1ab971ab
        _execute(tipJar, 0, abi.encodeWithSelector(hex"1ab971ab", newFee), bytes32(0), salt);
        emit FeeApproval(msg.sender, newFee);
    }

    /**
     * @notice Propose a new fee collector
     * @param newFeeCollector New fee collector
     * @param salt salt
     */
    function proposeNewFeeCollector(
        address newFeeCollector, 
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setFeeCollector(address)")) = 0xa42dce80
        bytes32 id = _schedule(tipJar, 0, abi.encodeWithSelector(hex"a42dce80", newFeeCollector), bytes32(0), salt, criticalDelay);
        emit FeeCollectorProposal(msg.sender, newFeeCollector, block.timestamp + regularDelay, id, salt);
    }

    /**
     * @notice Approve a new fee collector
     * @param newFeeCollector New fee collector
     * @param salt salt
     */
    function approveNewFeeCollector(
        address newFeeCollector, 
        bytes32 salt
    ) external {
        // bytes4(keccak256("setFeeCollector(address)")) = 0xa42dce80
        _execute(tipJar, 0, abi.encodeWithSelector(hex"a42dce80", newFeeCollector), bytes32(0), salt);
        emit FeeCollectorApproval(msg.sender, newFeeCollector);
    }

    /**
     * @notice Propose new admin for this contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function proposeNewAdmin(
        address newAdmin,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setAdmin(address)")) = 0x704b6c02
        _schedule(address(this), 0, abi.encodeWithSelector(hex"704b6c02", newAdmin), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new admin for this contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function approveNewAdmin(
        address newAdmin,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setAdmin(address)")) = 0x704b6c02
        _execute(address(this), 0, abi.encodeWithSelector(hex"704b6c02", newAdmin), bytes32(0), salt);
    }

    /**
     * @notice Set new admin for this contract
     * @dev Can only be executed by Timelock contract
     * @param newAdmin new admin address
     */
    function setAdmin(
        address newAdmin
    ) external onlyTimelock {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @notice Propose new critical delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function proposeNewCriticalDelay(
        uint256 newDelay,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setCriticalDelay(uint256)")) = 0xdad8a096
        _schedule(address(this), 0, abi.encodeWithSelector(hex"dad8a096", newDelay), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new critical delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function approveNewCriticalDelay(
        uint256 newDelay,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setCriticalDelay(uint256)")) = 0xdad8a096
        _execute(address(this), 0, abi.encodeWithSelector(hex"dad8a096", newDelay), bytes32(0), salt);
    }

    /**
     * @notice Set new critical delay for this contract
     * @dev Can only be executed by Timelock contract
     * @param newDelay new delay time
     */
    function setCriticalDelay(
        uint256 newDelay
    ) external onlyTimelock {
        emit DelayChanged("critical", criticalDelay, newDelay);
        criticalDelay = newDelay;
    }

    /**
     * @notice Propose new regular delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function proposeNewRegularDelay(
        uint256 newDelay,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setRegularDelay(uint256)")) = 0x8023dc81
        _schedule(address(this), 0, abi.encodeWithSelector(hex"8023dc81", newDelay), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new regular delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function approveNewRegularDelay(
        uint256 newDelay,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setRegularDelay(uint256)")) = 0x8023dc81
        _execute(address(this), 0, abi.encodeWithSelector(hex"8023dc81", newDelay), bytes32(0), salt);
    }

    /**
     * @notice Set new regular delay for this contract
     * @dev Can only be executed by Timelock contract
     * @param newDelay new delay time
     */
    function setRegularDelay(
        uint256 newDelay
    ) external onlyTimelock {
        emit DelayChanged("regular", regularDelay, newDelay);
        regularDelay = newDelay;
    }

    /**
     * @notice Propose new tip jar contract
     * @param newTipJar new tip jar address
     * @param salt salt
     */
    function proposeNewTipJar(
        address newTipJar,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setTipJar(address)")) = 0x5c66e3da
        _schedule(address(this), 0, abi.encodeWithSelector(hex"5c66e3da", newTipJar), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new tip jar contract
     * @param newTipJar new tip jar address
     * @param salt salt
     */
    function approveNewTipJar(
        address newTipJar,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setTipJar(address)")) = 0x5c66e3da
        _execute(address(this), 0, abi.encodeWithSelector(hex"5c66e3da", newTipJar), bytes32(0), salt);
    }

    /**
     * @notice Set new tip jar contract
     * @dev Can only be executed by Timelock contract
     * @param newTipJar new tip jar address
     */
    function setTipJar(
        address newTipJar
    ) external onlyTimelock {
        emit TipJarChanged(tipJar, newTipJar);
        tipJar = newTipJar;
    }

    /**
     * @notice Propose new timelock contract
     * @param newTimelock new timelock address
     * @param salt salt
     */
    function proposeNewTimelock(
        address newTimelock,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setTimelock(address)")) = 0xbdacb303
        _schedule(address(this), 0, abi.encodeWithSelector(hex"bdacb303", newTimelock), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new timelock contract
     * @param newTimelock new timelock address
     * @param salt salt
     */
    function approveNewTimelock(
        address newTimelock,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setTimelock(address)")) = 0xbdacb303
        _execute(address(this), 0, abi.encodeWithSelector(hex"bdacb303", newTimelock), bytes32(0), salt);
    }

    /**
     * @notice Set new timelock contract
     * @dev Can only be executed by Timelock contract or anyone if timelock has not yet been set
     * @param newTimelock new timelock address
     */
    function setTimelock(
        address payable newTimelock
    ) external onlyTimelock {
        emit TimelockChanged(address(timelock), newTimelock);
        timelock = ITimelockController(newTimelock);
    }

    /**
     * @notice Public getter for TipJar Proxy implementation contract address
     */
    function getProxyImplementation() public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = tipJar.staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @notice Public getter for TipJar Proxy admin address
     */
    function getProxyAdmin() public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = tipJar.staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @notice Propose new admin for TipJar proxy contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function proposeNewProxyAdmin(
        address newAdmin,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setProxyAdmin(address)")) = 0x47c02661
        _schedule(address(this), 0, abi.encodeWithSelector(hex"47c02661", newAdmin), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new admin for TipJar proxy contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function approveNewProxyAdmin(
        address newAdmin,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setProxyAdmin(address)")) = 0x47c02661
        _execute(address(this), 0, abi.encodeWithSelector(hex"47c02661", newAdmin), bytes32(0), salt);
    }

    /**
     * @notice Set new admin for TipJar proxy contract
     * @param newAdmin new admin address
     */
    function setProxyAdmin(
        address newAdmin
    ) external onlyTimelock {
        // bytes4(keccak256("changeAdmin(address)")) = 0x8f283970
        (bool success, ) = tipJar.call(abi.encodeWithSelector(hex"8f283970", newAdmin));
        require(success, "setProxyAdmin failed");
    }

    /**
     * @notice Propose new implementation for TipJar proxy contract
     * @param newImplementation new implementation address
     * @param salt salt
     */
    function proposeUpgrade(
        address newImplementation,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("upgrade(address)")) = 0x0900f010
        _schedule(address(this), 0, abi.encodeWithSelector(hex"0900f010", newImplementation), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new implementation for TipJar proxy
     * @param newImplementation new implementation address
     * @param salt salt
     */
    function approveUpgrade(
        address newImplementation,
        bytes32 salt
    ) external {
        // bytes4(keccak256("upgrade(address)")) = 0x0900f010
        _execute(address(this), 0, abi.encodeWithSelector(hex"0900f010", newImplementation), bytes32(0), salt);
    }

    /**
     * @notice Set new implementation for TipJar proxy contract
     * @param newImplementation new implementation address
     */
    function upgrade(
        address newImplementation
    ) external onlyTimelock {
        // bytes4(keccak256("upgradeTo(address)")) = 0x3659cfe6
        (bool success, ) = tipJar.call(abi.encodeWithSelector(hex"3659cfe6", newImplementation));
        require(success, "upgrade failed");
    }

    /**
     * @notice Propose new implementation for TipJar proxy contract + call function after
     * @param newImplementation new implementation address
     * @param data Bytes-encoded function to call
     * @param value Amount of ETH to send on call
     * @param salt salt
     */
    function proposeUpgradeAndCall(
        address newImplementation,
        bytes memory data,
        uint256 value,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("upgradeAndCall(address,bytes)")) = 0x2a6a833b
        _schedule(tipJar, value, abi.encodeWithSelector(hex"2a6a833b", newImplementation, data), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new implementation for TipJar proxy + call function after
     * @param newImplementation new implementation address
     * @param data Bytes-encoded function to call
     * @param value Amount of ETH to send on call
     * @param salt salt
     */
    function approveUpgradeAndCall(
        address newImplementation,
        bytes memory data,
        uint256 value,
        bytes32 salt
    ) external payable {
        // bytes4(keccak256("upgradeAndCall(address,bytes)")) = 0x2a6a833b
        _execute(tipJar, value, abi.encodeWithSelector(hex"2a6a833b", newImplementation, data), bytes32(0), salt);
    }

    /**
     * @notice Set new implementation for TipJar proxy contract + call function after
     * @param newImplementation new implementation address
     * @param data Bytes-encoded function to call
     */
    function upgradeAndCall(
        address newImplementation,
        bytes memory data
    ) external payable onlyTimelock {
        // bytes4(keccak256("upgradeToAndCall(address,bytes)")) = 0x4f1ef286
        (bool success, ) = tipJar.call{value: msg.value}(abi.encodeWithSelector(hex"4f1ef286", newImplementation, data));
        require(success, "upgradeAndCall failed");
    }

    /**
     * @notice Create proposal
     * @param target target address
     * @param value ETH value
     * @param data function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function createProposal(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt
    ) external onlyAdmin {
        _schedule(target, value, data, predecessor, salt, criticalDelay);
    }

    /**
     * @notice Create batch proposal
     * @param targets target address
     * @param values ETH value
     * @param datas function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function createProposalBatch(
        address[] calldata targets, 
        uint256[] calldata values, 
        bytes[] calldata datas, 
        bytes32 predecessor, 
        bytes32 salt
    ) external onlyAdmin {
        timelock.scheduleBatch(targets, values, datas, predecessor, salt, criticalDelay);
    }

    /**
     * @notice Execute proposal
     * @param target target address
     * @param value ETH value
     * @param data function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function executeProposal(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt
    ) external payable onlyAdmin {
        _execute(target, value, data, predecessor, salt);
    }

    /**
     * @notice Execute batch proposal
     * @param targets target address
     * @param values ETH value
     * @param datas function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function executeProposalBatch(
        address[] calldata targets, 
        uint256[] calldata values, 
        bytes[] calldata datas, 
        bytes32 predecessor, 
        bytes32 salt
    ) external payable onlyAdmin {
        timelock.executeBatch{value: msg.value}(targets, values, datas, predecessor, salt);
    }

    /**
     * @notice Cancel proposal
     * @param id ID of proposal
     */
    function cancelProposal(bytes32 id) external onlyAdmin {
        timelock.cancel(id);
    }

    /**
     * @notice Internal schedule implementation
     * @param target target address
     * @param value ETH value
     * @param data Bytes-encoded function call
     * @param predecessor scheduled item to execute before this call
     * @param salt salt
     * @param delay delay for proposal
     */
    function _schedule(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt, 
        uint256 delay
    ) private returns (bytes32 id) {
        return timelock.schedule(target, value, data, predecessor, salt, delay);
    }

    /**
     * @notice Internal execute implementation
     * @param target target address
     * @param value ETH value
     * @param data Bytes-encoded function call
     * @param predecessor scheduled item to execute before this call
     * @param salt salt
     */
    function _execute(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt
    ) private {
        timelock.execute{value: value}(target, value, data, predecessor, salt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimelockController {
    function TIMELOCK_ADMIN_ROLE() external view returns (bytes32);
    function PROPOSER_ROLE() external view returns (bytes32);
    function EXECUTOR_ROLE() external view returns (bytes32);
    function _DONE_TIMESTAMP() external view returns (uint256);
    receive() external payable;
    function isOperation(bytes32 id) external view returns (bool pending);
    function isOperationPending(bytes32 id) external view returns (bool pending);
    function isOperationReady(bytes32 id) external view returns (bool ready);
    function isOperationDone(bytes32 id) external view returns (bool done);
    function getTimestamp(bytes32 id) external view returns (uint256 timestamp);
    function getMinDelay() external view returns (uint256 duration);
    function hashOperation(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) external pure returns (bytes32 hash);
    function hashOperationBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) external pure returns (bytes32 hash);
    function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) external returns (bytes32 id);
    function scheduleBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt, uint256 delay) external returns (bytes32 id);
    function cancel(bytes32 id) external;
    function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) external payable;
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) external payable;
    function updateDelay(uint256 newDelay) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    event CallScheduled(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data, bytes32 predecessor, uint256 delay);
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);
    event Cancelled(bytes32 indexed id);
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 99999
  },
  "remappings": [],
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