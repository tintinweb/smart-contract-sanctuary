// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Blacklistable.sol";
import "./Pausable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, BlacklistableToken, PausableToken {
    using SafeMathUpgradeable for uint256;

    /// @notice Number of decimals
    uint8 _decimals;

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
    ) internal virtual override (ERC20Upgradeable, PausableToken) notPaused {
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

        BlacklistableToken._beforeTokenTransfer(from, to, amount);
        ERC20Upgradeable._beforeTokenTransfer(from, to, amount);
    }
}