// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";


/**
 * @title SQCoin (Version 1) Smart Contract
 * @author Swissquote Bank SA
 * @notice Simple ERC20 type smart contract with
 *    upgrable, pausable, blocklist, mint and burn features
 * @dev Each action have its own role which can be altered by `AccessControl`
 *    inherited methods: `grantRole`, `revokeRole`, `renounceRole`
 */
contract SQCoinV1 is Initializable, ContextUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20Upgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");

    /**
     * @dev Emitted when account is added to _blocklist
     */
    event Blocked(address indexed account, address blocker);

    /**
     * @dev Emitted when account is removed from _blocklist
     */
    event Unblocked(address indexed account, address unblocker);

    EnumerableSetUpgradeable.AddressSet private _transferBlockList;

    /**
     * @dev initialize the context, accessControl, ERC20, pausable and setups the DEFAULT_ADMIN_ROLE to administrator
     * @param name of the token
     * @param symbol of the token
     * @param decimals number of decimals of the token
     * @param administrator address that gets the DEFAULT_ADMIN_ROLE
     * NOTE : Decimals should be a number between 2 and 18
     */
    function initialize(string memory name, string memory symbol, uint8 decimals, address administrator) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        _setupDecimals(decimals);
        _setupRole(DEFAULT_ADMIN_ROLE, administrator);
    }


    /**
     * @dev Triggers paused state
     * Requires sender to be in PAUSER_ROLE
     */
    function pause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SQCoin: Caller is not pauser");
        _pause();
    }

    /**
     * @dev Triggers normal state
     * Requires sender to be in PAUSER_ROLE
     */
    function unpause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SQCoin: Caller is not pauser");
        _unpause();
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     *    the total supply.
     * Requires sender to be in MINTER_ROLE
     * @param account to mint tokens to
     * @param amount number of tokens to mint
     */
    function mint(address account, uint256 amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "SQCoin: Caller is not minter");
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     *    total supply.
     * Requires sender to be in BURNER_ROLE
     * @param account burn tokens from
     * @param amount number of tokens to burn
     */
    function burn(address account, uint256 amount) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "SQCoin: Caller is not burner");
        _burn(account, amount);
    }

    /**
     * @dev Adds array of accounts into _blocklist, 
     *    forbiding receving and sending to these addresses
     * Requires sender to be in BLOCKER_ROLE
     * @param accounts list of accounts to be added
     */
    function blockAccounts(address[] memory accounts) external {
        require(hasRole(BLOCKER_ROLE, _msgSender()), "SQCoin: Caller is not blocker");
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_transferBlockList.add(accounts[i])) {
                emit Blocked(accounts[i], _msgSender());
            }
        }
    }

    /**
     * @dev Removes array of accounts from _blocklist
     * Requires sender to be in BLOCKER_ROLE
     * @param accounts list of accounts to be removed
     */
    function unblockAccounts(address[] memory accounts) external {
        require(hasRole(BLOCKER_ROLE, _msgSender()), "SQCoin: Caller is not blocker");
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_transferBlockList.remove(accounts[i])) {
                emit Unblocked(accounts[i], _msgSender());
            }
        }
    }

    /**
     * @dev Returns `true` if `account` is in _blocklist
     * @param account to be ckecked
     */
    function isBlockedAccount(address account) public view returns (bool) {
        return _transferBlockList.contains(account);
    }

    /**
     * @dev Returns account in _blocklist at `index` position
     * @param index position of account in _blocklist
     */
    function getBlockedAccount(uint256 index) public view returns (address) {
        return _transferBlockList.at(index);
    }

    /**
     * @dev Returns the number of accounts in _blocklist
     */
    function getBlockedAccountCount() public view returns (uint256) {
        return _transferBlockList.length();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     *    minting and burning.
     * Requirements:
     * - not paused OR `to` has MINTER_ROLE
     * - `from` is not in _blocklist OR `to` is 0 (burn)
     * - `to` is not in _blocklist
     * - from ERC20.sol:
     *    - `from` cannot be the zero address
     *    - `to` cannot be the zero address
     *    - `from` must have a balance of at least `amount`
     * @param from sender address `from` cannot be the zero address
     * @param to receiver address `to` cannot be the zero address
     * @param amount number of tokens to be transfered `from` must have a balance of at least `amount`
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused() || hasRole(MINTER_ROLE, to), "SQCoin: token transfer while paused");
        require(!_transferBlockList.contains(from) || to == address(0), "SQCoin: from is in blocklist");
        require(!_transferBlockList.contains(to), "SQCoin: to is in blocklist");
    }
}