// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Blacklistable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, BlacklistableToken, PausableToken {
    using SafeMathUpgradeable for uint256;

    /// @notice Number of decimals
    uint8 _decimals;

    /// @notice Maximum token balance addresses are allowed to have
    uint256 private _balanceLimit;
    /// @notice Record of addresses that are allowed to circumvent the balance limit
    mapping (address => bool) private _balanceLimitBypass;
    /// @notice Role for access control
    bytes32 public constant BALANCE_LIMITER_ROLE = keccak256("BALANCE_LIMITER_ROLE");

    /// @notice Beneficiary of taxes levied upon transfers
    address private _taxBeneficiary;
    /// @notice Tax amount
    uint256 private _taxAmount;
    /// @notice Role for access control
    bytes32 public constant TAX_MANAGER_ROLE = keccak256("TAX_MANAGER_ROLE");

    /// @notice EIP-712 typehash for contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );
    /// @notice EIP-712 typehash for the structured hash used by `permit`
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address designator,address spender,uint256 amount,bytes32 nonce,uint256 deadline)"
    );
    /// @notice EIP-712 typehash for the structured hash used by `transferPresigned`
    bytes32 public constant TRANSFER_PRESIGNED_TYPEHASH = keccak256(
        "TransferPresigned(address sender,address recipient,uint256 amount,bytes32 nonce,uint256 deadline)"
    );
    /// @notice Record of single-used nonces for `permit` and `transferPresigned` operations
    mapping (address => mapping (bytes32 => bool)) private _permitNonces;
    mapping (address => mapping (bytes32 => bool)) private _transferPresignedNonces;

    /// @notice Role for access control
    bytes32 public constant TOKEN_CUSTODIAN_ROLE = keccak256("TOKEN_CUSTODIAN_ROLE");

    /**
     * @dev Emitted when an address is added to the bypass list
     */
    event BalanceLimitBypassAdded(address bypasser);

    /**
     * @dev Emitted when an address is removed from the bypass list
     */
    event BalanceLimitBypassRemoved(address exBypasser);

    /**
     * @dev Emitted when the balance limit is changed
     */
    event BalanceLimitChange(uint256 oldLimit, uint256 newLimit);

    /**
     * @dev Allow only the addresses with the BALANCE_LIMITER_ROLE privileges
     */
    modifier onlyBalanceLimiter() {
        _checkRole(BALANCE_LIMITER_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Emitted when the tax beneficiary changes
     */
    event TaxBeneficiaryChanged(address oldBeneficiary, address newBeneficiary);

    /**
     * @dev Emitted when the tax amount changes
     */
    event TaxAmountChanged(uint256 oldAmount, uint256 newAmount);

    /**
     * @dev Allow only the addresses with the TAX_MANAGER_ROLE privileges
     */
    modifier onlyTaxManager() {
        _checkRole(TAX_MANAGER_ROLE, _msgSender());
        _;
    }


    /**
     * @dev Initialises the token contract
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 supply_,
        address initialOwner
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        __AccessControl_init_unchained();

        __Token_init_unchained(decimals_, supply_, initialOwner);
        __Paused_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Initialises the token
     */
    function __Token_init_unchained(uint8 decimals_, uint256 supply_, address initialOwner) internal initializer {
        _decimals = decimals_;
        _balanceLimitBypass[initialOwner] = true;
        _mint(initialOwner, supply_);
    }

    /**
     * @dev Allow `spender` to transfer up to `amount` tokens
     */
    function approve(address spender, uint256 amount) public override notPaused returns (bool) {
        return super.approve(spender, amount);
    }

    /**
     * @dev Add `convict` to the blacklist
     */
    function blacklist(address convict) public override notPaused onlyBlacklister {
        super.blacklist(convict);
    }

    /**
     * @dev Returns the number of decimal places for the contract
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override notPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev Grants `role` to `account`.
     */
    function grantRole(bytes32 role, address account) public override notPaused onlyRole(getRoleAdmin(role)) {
        super.grantRole(role, account);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public override notPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev Disable the ability to renounce ownership
     */
    function renounceOwnership() public view override onlyOwner {
        revert("disabled");
    }

    /**
     * @dev Revokes `role` from the calling account.
     */
    function renounceRole(bytes32 role, address account) public override notPaused {
        super.renounceRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     */
    function revokeRole(bytes32 role, address account) public override notPaused onlyRole(getRoleAdmin(role)) {
        super.revokeRole(role, account);
    }

    /**
     * @dev Transfer `amount` tokens to `recipient` from caller
     */
    function transfer(address recipient, uint256 amount) public override notBlacklisted notPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Transfer `amount` tokens from `sender` to `recipient`
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notBlacklisted notPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Remove `parolee` from the blacklist
     */
    function unblacklist(address parolee) public override notPaused onlyBlacklister {
        super.unblacklist(parolee);
    }

    /**
     * @dev Override `_approve` for method resolution
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override (ERC20Upgradeable, PausableToken) notPaused {
        PausableToken._approve(owner, spender, amount);
    }

    /**
     * @dev Pre-transfer hook for running validation.
     *
     * Overridden to perform validation in the most sensible order.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override (ERC20Upgradeable, BlacklistableToken, PausableToken) {
        // avoid calling this to save gas and rely on the modifiers instead
        // PausableToken._beforeTokenTransfer(from, to, amount);

        require(
            to == address(0) || bypassesBalanceLimit(to) || (balanceOf(to) + amount) <= _balanceLimit,
            "balance limit exceeded"
        );

        BlacklistableToken._beforeTokenTransfer(from, to, amount);
        ERC20Upgradeable._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Allow `bypasser` to circumvent the balance limit
     */
    function addBalanceBypasser(address bypasser) public onlyBalanceLimiter {
        _addBalanceBypasser(bypasser);
    }

    /**
     * @dev Allow `bypasser` to circumvent the balance limit
     */
    function _addBalanceBypasser(address bypasser) internal {
        if (!_balanceLimitBypass[bypasser]) {
            _balanceLimitBypass[bypasser] = true;
            emit BalanceLimitBypassAdded(bypasser);
        }
    }

    /**
     * @dev Returns the max allowed balance
     */
    function balanceLimit() public view returns (uint256) {
        return _balanceLimit;
    }

    /**
     * @dev Check if `target` is allowed to bypass the balance limit
     */
    function bypassesBalanceLimit(address target) public view returns (bool) {
        return _balanceLimitBypass[target];
    }

    /**
     * @dev Revoke balance limit bypass privileges from `exBypasser`
     */
    function removeBalanceBypasser(address exBypasser) public onlyBalanceLimiter {
        if (_balanceLimitBypass[exBypasser]) {
            _balanceLimitBypass[exBypasser] = false;
            emit BalanceLimitBypassRemoved(exBypasser);
        }
    }

    /**
     * @dev Update the max allowed balance
     */
    function setBalanceLimit(uint256 newBalanceLimit) public onlyBalanceLimiter {
        if (_balanceLimit != newBalanceLimit) {
            uint256 oldLimit = _balanceLimit;
            _balanceLimit = newBalanceLimit;
            emit BalanceLimitChange(oldLimit, newBalanceLimit);
        }
    }

    /**
     * @dev Change the beneficiary
     */
    function setTaxBeneficiary(address newBeneficiary) public onlyTaxManager {
        if (_taxBeneficiary != newBeneficiary) {
            address oldBeneficiary = _taxBeneficiary;
            _taxBeneficiary = newBeneficiary;
            emit TaxBeneficiaryChanged(oldBeneficiary, newBeneficiary);

            _addBalanceBypasser(newBeneficiary);
        }
    }

    /**
     * @dev Set the tax amount
     */
    function setTaxAmount(uint256 newAmount) public onlyTaxManager {
        if (_taxAmount != newAmount) {
            uint256 oldAmount = _taxAmount;
            _taxAmount = newAmount;
            emit TaxAmountChanged(oldAmount, newAmount);
        }
    }

    /**
     * @dev Returns the tax amount
     */
    function taxAmount() public view returns (uint256) {
        return _taxAmount;
    }

    /**
     * @dev Returns the address of the tax beneficiary
     */
    function taxBeneficiary() public view returns (address) {
        return _taxBeneficiary;
    }

    /**
     * @dev Transfer `amount` tokens for contract `token` to `recipient`
     */
    function transferERC20Token(
        address token,
        address recipient,
        uint256 amount
    ) public notPaused onlyRole(TOKEN_CUSTODIAN_ROLE) returns (bool) {
        IERC20(token).transfer(recipient, amount);
        return true;
    }

    /**
     * @dev Validate and execute a pre-signed `allowance` operation
     */
    function permit(
        address designator,
        address spender,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public notPaused returns (bool) {
        require(!permitNonceUsed(designator, nonce), "nonce used");

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                designator,
                spender,
                amount,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        _validateSignature(designator, digest, v, r, s, deadline, "permit");

        _permitNonces[designator][nonce] = true;
        _approve(designator, spender, amount);
        return true;
    }

    /**
     * @dev Check if the given address and nonce pair have been used for `permit` operations
     */
    function permitNonceUsed(address designator, bytes32 nonce) public view returns (bool) {
        return _permitNonces[designator][nonce];
    }

    /**
     * @dev Validate and execute a pre-signed `transfer` operation
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public notPaused returns (bool) {
        require(!transferPresignedNonceUsed(sender, nonce), "nonce used");

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_PRESIGNED_TYPEHASH,
                sender,
                recipient,
                amount,
                nonce,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        _validateSignature(sender, digest, v, r, s, deadline, "transferPresigned");

        _transferPresignedNonces[sender][nonce] = true;

        super._transfer(sender, recipient, amount);
        if (_taxAmount > 0) {
            super._transfer(sender, _taxBeneficiary, _taxAmount);
        }

        return true;
    }

    /**
     * @dev Check if the given address and nonce pair have been used for `transferPresigned` operations
     */
    function transferPresignedNonceUsed(address sender, bytes32 nonce) public view returns (bool) {
        return _transferPresignedNonces[sender][nonce];
    }

    /**
     * @dev Validates a signature
     *
     * Given a signature (made up of the (v, r, s) tuple) and the original message digest, this function recovers the
     * address of the original signatory. The address of the original signatory is compared against the given signatory
     * and the deadline is checked to ensure that the signature has not expired. The validation fails if either
     * condition is not fulfilled.
     */
    function _validateSignature(
        address sender,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline,
        string memory caller
    ) internal view returns (address) {
        require(block.timestamp <= deadline, string(abi.encodePacked(caller, ": signature expired")));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), string(abi.encodePacked(caller, ": invalid signature")));
        require(signatory == sender, string(abi.encodePacked(caller, ": unauthorized")));

        return signatory;
    }
}