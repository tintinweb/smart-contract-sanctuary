// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Blacklistable.sol";
import "./Mintable.sol";
import "./Burnable.sol";
import "./Pausable.sol";
import "./Presignable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, Presignable, Burnable, Mintable, Blacklistable, Pausable {
    /// @notice Number of decimals
    uint8 _decimals;
    /// @notice Number of decimals
    mapping (address => bool) private _authorizedContracts;
    /// @notice Roles for access control
    bytes32 public constant CONTRACT_AUTHORIZER_ROLE = keccak256("CONTRACT_AUTHORIZER_ROLE");
    bytes32 public constant CONTRACT_AUTHORIZER_ADMIN_ROLE = keccak256("CONTRACT_AUTHORIZER_ADMIN_ROLE");

    /**
     * @dev Emitted when `contractAddress` is authorised.
     */
    event ContractAuthorizationGranted(address indexed contractAddress);

    /**
     * @dev Emitted when the authorisation for `contractAddress` is revoked.
     */
    event ContractAuthorizationRevoked(address indexed contractAddress);

    /**
     * @dev Emitted when an authorized contract `contractAddress` transfers
     * `value` tokens from `sender` to `recipient.
     */
    event AuthorizedTransfer(
        address indexed contractAddress,
        address indexed sender,
        address indexed recipient,
        uint256 value
    );

    function __GO_init_unchained(uint8 decimals_) internal initializer {
        _decimals = decimals_;
        _setRoleAdmin(CONTRACT_AUTHORIZER_ROLE, CONTRACT_AUTHORIZER_ADMIN_ROLE);
    }

    /**
     * @dev Initialises the token contract.
     */
    function initialize(string memory name_, string memory symbol_, uint8 decimals_) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        __AccessControl_init_unchained();
        __Presignable_init_unchained(name_, "1");
        __Burnable_init_unchained();
        __Mintable_init_unchained();
        __Blacklistable_init_unchained();
        __Pausable_init_unchained();

        __GO_init_unchained(decimals_);

        _setupRole(BLACKLISTER_ADMIN_ROLE, _msgSender());
        _setupRole(BURNER_ADMIN_ROLE, _msgSender());
        _setupRole(CONTRACT_AUTHORIZER_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Throws if the caller is not an authorized contract
     */
    modifier onlyAuthorizedContract() {
        require(isAuthorizedContract(_msgSender()), "caller is not authorized contract");
        _;
    }

    /**
     * @dev Authorize a contract address
     * @param contractAddress Address of new contract to authorize.
     *
     * Emits an {ContractAuthorizationGranted} with `contractAddress` set
     * according to the supplied argument.
     *
     * Requirements:
     *
     * - caller must have contract authorizer role.
     */
    function addAuthorizedContract(address contractAddress) public onlyRole(CONTRACT_AUTHORIZER_ROLE) {
        if (!_authorizedContracts[contractAddress]) {
            _authorizedContracts[contractAddress] = true;
            emit ContractAuthorizationGranted(contractAddress);
        }
    }

    /**
     * @dev Unilateral transfer for authorized contracts
     * @param sender Address sending tokens.
     * @param recipient Address receiving tokens.
     * @param value Amount of tokens being sent.
     *
     * Emits an {AuthorizedTransfer} event with `contractAddress` set to the
     * caller, and `sender`, `recipient`, and `value` set according to the
     * supplied arguments.
     *
     * Requirements:
     *
     * - caller must be an authorized contract.
     * - contract must not be paused.
     * - `sender` must not be blacklisted
     */
    function authorizedTransfer(
        address sender,
        address recipient,
        uint256 value
    ) public notPaused onlyAuthorizedContract notBlacklisted(sender) {
        _transfer(sender, recipient, value);
        emit AuthorizedTransfer(_msgSender(), sender, recipient, value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must not be blacklisted.
     * - contract must not be paused.
     * - caller must have burner role.
     */
    function burn(uint256 value) public override notPaused notBlacklisted(_msgSender()) onlyRole(BURNER_ROLE) {
        super.burn(value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must have burner role.
     * - `account` must not be blacklisted.
     * - contract must not be paused.
     */
    function burnFrom(
        address account,
        uint256 value
    ) public override notPaused notBlacklisted(account) onlyRole(BURNER_ROLE) {
        super.burnFrom(account, value);
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
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Check if `contractAddress` is an authorized contract
     * @param contractAddress Address of contract to check for authorization.
     * @return true if `contractAddress` is an authorized contract.
     */
    function isAuthorizedContract(address contractAddress) public view returns (bool) {
        return _authorizedContracts[contractAddress];
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must have minter role.
     * - contract must not be paused.
     */
    function mint(address account, uint256 value) public override notPaused onlyRole(MINTER_ROLE) {
        super.mint(account, value);
    }

    /**
     * @dev Revoke authorization from a contract address
     * @param contractAddress Address of contract to revoke authorization from.
     *
     * Emits an {ContractAuthorizationRevoked} with `contractAddress` set
     * according to the supplied argument.
     *
     * Requirements:
     *
     * - caller must have contract authorizer role.
     */
    function removeAuthorizedContract(address contractAddress) public onlyRole(CONTRACT_AUTHORIZER_ROLE) {
        if (_authorizedContracts[contractAddress]) {
            _authorizedContracts[contractAddress] = false;
            emit ContractAuthorizationRevoked(contractAddress);
        }
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must not be blacklisted.
     * - contract must not be paused.
     */
    function transfer(
        address recipient,
        uint256 value
    ) public override notPaused notBlacklisted(_msgSender()) returns (bool) {
        return super.transfer(recipient, value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 value
    ) public override notPaused notBlacklisted(sender) returns (bool) {
        return super.transferFrom(sender, recipient, value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 value,
        uint256 fee,
        address feeRecipient,
        uint256 deadline,
        uint256 nonce,
        bytes memory signature
    ) public override notPaused notBlacklisted(sender) {
        super.transferPresigned(sender, recipient, value, fee, feeRecipient, deadline, nonce, signature);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 value,
        uint256 fee,
        address feeRecipient,
        uint256 deadline,
        bytes memory signature
    ) public override notPaused notBlacklisted(sender) {
        super.transferPresigned(sender, recipient, value, fee, feeRecipient, deadline, signature);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 value,
        uint256 fee,
        address feeRecipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override notPaused notBlacklisted(sender) {
        super.transferPresigned(sender, recipient, value, fee, feeRecipient, deadline, v, r, s);
    }
}