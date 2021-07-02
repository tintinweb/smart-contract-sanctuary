// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BalanceLimitable.sol";
import "./Blacklistable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./Peggable.sol";
import "./Taxable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, PeggableToken, BalanceLimitableToken, BlacklistableToken, PausableToken, TaxableToken {
    using SafeMathUpgradeable for uint256;

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

    /// @notice Role for access control
    bytes32 public constant TOKEN_CUSTODIAN_ROLE = keccak256("TOKEN_CUSTODIAN_ROLE");

    /// @notice Record of single-used nonces for `permit` and `transferPresigned` operations
    mapping (address => mapping (bytes32 => bool)) private _permitNonces;
    mapping (address => mapping (bytes32 => bool)) private _transferPresignedNonces;

    /// @notice Number of decimals
    uint8 _decimals;

    /**
     * @dev Initialises the token contract
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address peggedToken,
        uint256 balanceLimit_,
        uint256 taxPercentage_
    ) public initializer {
        address self = address(this);
        initialize(name_, symbol_, decimals_, peggedToken, self, balanceLimit_, self, taxPercentage_);
    }

    /**
     * @dev Initialises the token contract
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address peggedToken,
        address mintingBeneficiary_,
        uint256 balanceLimit_,
        address taxBeneficiary_,
        uint256 taxPercentage_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        __AccessControl_init_unchained();

        __Token_init_unchained(decimals_);
        __Peggable_init_unchained(peggedToken, mintingBeneficiary_);
        __BalanceLimitableToken_init_unchained(balanceLimit_);
        __Paused_init_unchained();
        __TaxableToken_init_unchained(taxBeneficiary_, taxPercentage_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        initializeBeneficiaryPrivileges();
    }

    function __Token_init_unchained(uint8 decimals_) internal initializer {
        _decimals = decimals_;
    }

    /**
     * @dev Sets up the necessary roles and grants the beneficiaries sensible privileges
     */
    function initializeBeneficiaryPrivileges() internal initializer {
        _addBalanceBypasser(mintingBeneficiary());
        _addBalanceBypasser(taxBeneficiary());
    }

    /**
     * @dev Allow only the addresses with the TOKEN_CUSTODIAN_ROLE privileges
     */
    modifier onlyTokenCustodian() {
        _checkRole(TOKEN_CUSTODIAN_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Revoke balance limit bypass privileges from `exBypasser`
     */
    function addBalanceBypasser(address bypasser) public override notPaused onlyBalanceLimiter {
        super.addBalanceBypasser(bypasser);
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
     * @dev Burn the sender's tokens and return them the equivalent in the pegged token
     */
    function burn(uint256 amount) public override notBlacklisted notPaused {
        super.burn(amount);
    }

    /**
     * @dev Update the minting beneficiary and add the new beneficiary to the balance bypass list
     */
    function changeMintingBeneficiary(address newBeneficiary) public override notPaused onlyBeneficiaryManager {
        _changeMintingBeneficiary(newBeneficiary);
        _addBalanceBypasser(newBeneficiary);
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
     * @dev Mint `amount` tokens and send them to `recipient`
     */
    function mint(address recipient, uint256 amount) public override notBlacklisted notPaused {
        _mint(recipient, amount);
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
        _permit(designator, spender, amount, nonce, deadline, v, r, s);
        return true;
    }

    /**
     * @dev Check if the given address and nonce pair have been used for `permit` operations
     */
    function permitNonceUsed(address designator, bytes32 nonce) public view returns (bool) {
        return _permitNonces[designator][nonce];
    }

    /**
     * @dev Revoke balance limit bypass privileges from `exBypasser`
     */
    function removeBalanceBypasser(address exBypasser) public override onlyBalanceLimiter notPaused {
        super.removeBalanceBypasser(exBypasser);
    }

    /**
     * @dev Disable the ability to renounce ownership
     */
    function renounceOwnership() public virtual override onlyOwner {
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
     * @dev Update the max allowed balance
     */
    function setBalanceLimit(uint256 newBalanceLimit) public override notPaused onlyBalanceLimiter {
        super.setBalanceLimit(newBalanceLimit);
    }

    /**
     * @dev Change the beneficiary
     */
    function setTaxBeneficiary(address newBeneficiary) public override notPaused onlyTaxManager {
        super.setTaxBeneficiary(newBeneficiary);
        _addBalanceBypasser(newBeneficiary);
    }

    /**
     * @dev Set the tax percentage
     */
    function setTaxPercentage(uint256 newPercentage) public override notPaused onlyTaxManager {
        super.setTaxPercentage(newPercentage);
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
     * @dev Transfer `amount` tokens for contract `token` to `recipient`
     */
    function transferERC20Token(
        address token,
        address recipient,
        uint256 amount
    ) public notPaused onlyTokenCustodian returns (bool) {
        return IERC20(token).transfer(recipient, amount);
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
        _transferPresigned(sender, recipient, amount, nonce, deadline, v, r, s);
        return true;
    }

    /**
     * @dev Check if the given address and nonce pair have been used for `transferPresigned` operations
     */
    function transferPresignedNonceUsed(address sender, bytes32 nonce) public view returns (bool) {
        return _transferPresignedNonces[sender][nonce];
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
        address designator,
        address spender,
        uint256 amount
    ) internal virtual override (ERC20Upgradeable, PausableToken) {
        PausableToken._approve(designator, spender, amount);
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
    ) internal override (ERC20Upgradeable, BalanceLimitableToken, BlacklistableToken, PausableToken) {
        // avoid calling this to save gas and rely on the modifiers instead
        // PausableToken._beforeTokenTransfer(from, to, amount);

        BlacklistableToken._beforeTokenTransfer(from, to, amount);
        BalanceLimitableToken._beforeTokenTransfer(from, to, amount);
        ERC20Upgradeable._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Returns the current chain ID.
     */
    function _getChainId() public view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * @dev Mint `amount` tokens and send them to the sender
     */
    function _mint(
        address recipient,
        uint256 amount
    ) internal override (ERC20Upgradeable, PeggableToken) notBlacklisted notPaused {
        PeggableToken._mint(recipient, amount);
    }

    /**
     * @dev Validate and execute a pre-signed `allowance` operation
     *
     * The `allowance` operation can be carried out by another party by utilising the `permit` function, as long as the
     * address owner themselves have signed a structured hash containing the details necessary for execution.
     */
    function _permit(
        address designator,
        address spender,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(!permitNonceUsed(designator, nonce), "nonce used");

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), _getChainId(), address(this))
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
    }

    /**
     * @dev Validate and execute a pre-signed `transfer` operation
     *
     * The `transfer` operation can be carried out by another party by utilising the `transferPresigned` function, as
     * long as the address owner themselves have signed a structured hash containing the details necessary for
     * execution.
     */
    function _transferPresigned(
        address sender,
        address recipient,
        uint256 amount,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(!transferPresignedNonceUsed(sender, nonce), "nonce used");

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), _getChainId(), address(this))
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
        _transferTaxable(sender, recipient, amount);
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

    function generateDomainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), _getChainId(), address(this)));
    }
}