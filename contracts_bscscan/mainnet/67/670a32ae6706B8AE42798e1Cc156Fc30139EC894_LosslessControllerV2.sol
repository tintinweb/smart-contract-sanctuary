/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


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
        return msg.data;
    }
    uint256[50] private __gap;
}

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

interface ProtectionStrategy {
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external;
}

contract LosslessControllerV2 is Initializable, ContextUpgradeable, PausableUpgradeable {
    address public pauseAdmin;
    address public admin;
    address public recoveryAdmin;

    // --- V2 VARIABLES ---

    address public guardian;
    mapping(address => Protections) private tokenProtections;

    struct Protection {
        bool isProtected;
        ProtectionStrategy strategy;
    }

    struct Protections {
        mapping(address => Protection) protections;
    }

    // --- EVENTS ---

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event PauseAdminChanged(address indexed previousAdmin, address indexed newAdmin);


    // --- V2 EVENTS ---

    event GuardianSet(address indexed oldGuardian, address indexed newGuardian);
    event ProtectedAddressSet(address indexed token, address indexed protectedAddress, address indexed strategy);
    event RemovedProtectedAddress(address indexed token, address indexed protectedAddress);

    // --- MODIFIERS ---

    modifier onlyLosslessRecoveryAdmin() {
        require(msg.sender == recoveryAdmin, "LOSSLESS: Must be recoveryAdmin");
        _;
    }

    modifier onlyLosslessAdmin() {
        require(admin == msg.sender, "LOSSLESS: Must be admin");
        _;
    }

    modifier onlyPauseAdmin() {
        require(msg.sender == pauseAdmin, "LOSSLESS: Must be pauseAdmin");
        _;
    }

    // --- V2 MODIFIERS ---

    modifier onlyGuardian() {
        require(msg.sender == guardian, "LOSSLESS: Must be Guardian");
        _;
    }

    // --- VIEWS ---

    function getVersion() external pure returns (uint256) {
        return 2;
    }

    // --- V2 VIEWS ---

    function isAddressProtected(address token, address protectedAddress) external view returns (bool) {
        return tokenProtections[token].protections[protectedAddress].isProtected;
    }

    function getProtectedAddressStrategy(address token, address protectedAddress) external view returns (address) {
        return address(tokenProtections[token].protections[protectedAddress].strategy);
    }

    // --- ADMINISTRATION ---

    function pause() external onlyPauseAdmin  {
        _pause();
    }    
    
    function unpause() external onlyPauseAdmin {
        _unpause();
    }

    function setAdmin(address newAdmin) external onlyLosslessRecoveryAdmin {
        require(newAdmin != address(0), "LERC20: Cannot be zero address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setRecoveryAdmin(address newRecoveryAdmin) external onlyLosslessRecoveryAdmin {
        require(newRecoveryAdmin != address(0), "LERC20: Cannot be zero address");
        emit RecoveryAdminChanged(recoveryAdmin, newRecoveryAdmin);
        recoveryAdmin = newRecoveryAdmin;
    }

    function setPauseAdmin(address newPauseAdmin) external onlyLosslessRecoveryAdmin {
        require(newPauseAdmin != address(0), "LERC20: Cannot be zero address");
        emit PauseAdminChanged(pauseAdmin, newPauseAdmin);
        pauseAdmin = newPauseAdmin;
    }

    // --- GUARD ---

    // @notice Set a guardian contract.
    // @dev Guardian contract must be trusted as it has some access rights and can modify controller's state.
    function setGuardian(address newGuardian) external onlyLosslessAdmin whenNotPaused {
        require(newGuardian != address(0), "LSS: Cannot be zero address");
        emit GuardianSet(guardian, newGuardian);
        guardian = newGuardian;
    }

    // @notice Sets protection for an address with the choosen strategy.
    // @dev Strategies are verified in the guardian contract.
    // @dev This call is initiated from a strategy, but guardian proxies it.
    function setProtectedAddress(address token, address protectedAddresss, ProtectionStrategy strategy) external onlyGuardian whenNotPaused {
        Protection storage protection = tokenProtections[token].protections[protectedAddresss];
        protection.isProtected = true;
        protection.strategy = strategy;
        emit ProtectedAddressSet(token, protectedAddresss, address(strategy));
    }

    // @notice Remove the protection from the address.
    // @dev Strategies are verified in the guardian contract.
    // @dev This call is initiated from a strategy, but guardian proxies it.
    function removeProtectedAddress(address token, address protectedAddresss) external onlyGuardian whenNotPaused {
        delete tokenProtections[token].protections[protectedAddresss];
        emit RemovedProtectedAddress(token, protectedAddresss);
    }

    // --- BEFORE HOOKS ---

    // @notice If address is protected, transfer validation rules have to be run inside the strategy.
    // @dev isTransferAllowed reverts in case transfer can not be done by the defined rules.
    function beforeTransfer(address sender, address recipient, uint256 amount) external {
        if (tokenProtections[msg.sender].protections[sender].isProtected) {
            tokenProtections[msg.sender].protections[sender].strategy.isTransferAllowed(msg.sender, sender, recipient, amount);
        }
    }

    // @notice If address is protected, transfer validation rules have to be run inside the strategy.
    // @dev isTransferAllowed reverts in case transfer can not be done by the defined rules.
    function beforeTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external {
        if (tokenProtections[msg.sender].protections[sender].isProtected) {
            tokenProtections[msg.sender].protections[sender].strategy.isTransferAllowed(msg.sender, sender, recipient, amount);
        }
    }

    function beforeApprove(address sender, address spender, uint256 amount) external {}

    function beforeIncreaseAllowance(address msgSender, address spender, uint256 addedValue) external {}

    function beforeDecreaseAllowance(address msgSender, address spender, uint256 subtractedValue) external {}

    // --- AFTER HOOKS ---
    // * After hooks are deprecated in LERC20 but we have to keep them
    //   here in order to support legacy LERC20.

    function afterApprove(address sender, address spender, uint256 amount) external {}

    function afterTransfer(address sender, address recipient, uint256 amount) external {}

    function afterTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external {}

    function afterIncreaseAllowance(address sender, address spender, uint256 addedValue) external {}

    function afterDecreaseAllowance(address sender, address spender, uint256 subtractedValue) external {}
}