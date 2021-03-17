// SPDX-License-Identifier: UNLICENSED
// Modified from: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/presets/ERC20PresetMinterPauserUpgradeable.sol

pragma solidity 0.6.12;

// MODIFIED: import paths
// import "../access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./interfaces/IManagementContract.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * - This is a slighlty modified version of {ERC20PresetMinterPauserUpgradeable} by OpenZeppelin.
 *
 * The contract uses {Initializable}, {ContextUpgradeable}, {ERC20BurnableUpgradeable}, {ERC20PausableUpgradeable} from OpenZeppelin
 *
 * This contract uses {HManagementContract} to control permissions using the
 * different roles..
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC20PresetMinterPauserUpgradeableModified is Initializable, ContextUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable { // MODIFIED
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; // ADDED
    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IManagementContract public managementContract; // ADDED

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * `managementContractAddress` is a custom variable pointing to the
     * Himalaya's management contract in order to offload certain functionality
     * to the shared contract
     *
     * See {ERC20-constructor}.
     */

    function initialize(string memory name, string memory symbol, address managementContractAddress) public virtual {
        // MODIFIED
        managementContract = IManagementContract(managementContractAddress); // ADDED
        __ERC20PresetMinterPauser_init(name, symbol);
    }

    /**
     * @dev Modified function. Two functions `__AccessControl_init_unchained` and `__ERC20PresetMinterPauser_init_unchained`
     * have been moved to the {HManagementContract}
     *
     */
    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        // __AccessControl_init_unchained();               // MODIFIED
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        // __ERC20PresetMinterPauser_init_unchained(name, symbol); // MODIFIED
    }

    /**
     * @dev Modified function. Setting up roles is moved to the {managamentContract}
     * Also the mint function is only in the `mainnet` version (not on `quorum` version)
     */
    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());    // MODIFIED
        // _setupRole(MINTER_ROLE, _msgSender());           // MODIFIED
        // _setupRole(PAUSER_ROLE, _msgSender());           // MODIFIED
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(managementContract.hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause"); // MODIFIED
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(managementContract.hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause"); // MODIFIED
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        // MODIFIED
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./ERC20tokenPresetModified.sol";
import "./interfaces/IERC1404.sol";
import "./interfaces/IERC165.sol";

/// @title HHH Himalaya HEX HPay
/**
 * @dev HHH is the main ERC20 compatible token with additional functionality provided by Himalaya Group
 * - 24 hours delays for non whitelisted users
 * - ability for Admin to recover stolen funds from pending deposits locked in 24 hours delay.
 * - connects with HManagementContract to check if users are whitelisted.
 *
 * See HManagementContract to find out more about whitelisting.
 *
 * The contract uses {ERC20PresetMinterPauserUpgradeableModified} (slightly modified version of OpenZeppelin of {ERC20PresetMinterPauserUpgradeable})
 * to manage minting, burning and pausing activities
 */
contract HHH is ERC20PresetMinterPauserUpgradeableModified, IERC1404, IERC165 {
    /// @dev Whitelisting role
    bytes32 private constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    /**
     * @dev Mapping of users to {Deposit}. It stores amount of tokens unavailable for immidiate transfer
     * for not whitelisted users.
     *
     * Tokens locked here are removed after {nonWhitelistedDelay}. Any changes to pendingDeposits do not change
     * user's balance. For example, if user has 100 tokens, but 60 of them are in pendingDeposits, the user's
     * balance is still 100 tokens, but available balance to spend would be 40. If 30 tokens in pendingDeposits
     * exceed the {nonWhitelistedDelay}, they will be removed from the deposits and the user's available balance
     * will become 70, while still have a full balance of 100.
     */
    mapping(address => Deposit[]) public pendingDeposits;

    /// @dev Minimum amount allowed to transfer
    uint256 public nonWhitelistedDustThreshold; // This is to prevent attacker making multiple small deposits and preventing legitimate user from receiving deposits

    /**
     * @dev Emitted when 'amount' is recovered from {pendingDeposits} in 'from' account
     * to 'to' account.
     */
    event RecoverFrozen(address from, address to, uint256 amount);

    /**
     * @dev Object which is stored in {pendingDeposits} mapping. It stored 'amount' deposited at 'time'.
     * It is used when non whitelisted user received funds.
     */
    struct Deposit {
        uint256 time;
        uint256 amount;
    }

    /// @dev Only address which is set to Admin role can call functions with this modifier
    modifier onlyAdmin virtual {
        require(managementContract.hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have ADMIN ROLE");
        _;
    }

    modifier onlyManagementContract virtual {
        require(_msgSender() == address(managementContract), "only management contract can call this function");
        _;
    }

    /**
     * @dev Sets the values for {name}, {symbol} and {HManagementContract}, initializes {nonWhitelistedDustThreshold} with
     * a default value of 0.1 of the coin.
     *
     * To select a different value for {nonWhitelistedDustThreshold}, use {setNonWhitelistedDustThreshold}.
     *
     * This function also initialized {ERC20PresetMinterPauserUpgradeableModified} extension contract.
     *
     * 'name' and 'symbol' values are immutable: they can only be set once during
     *
     * To update {HManagementContract}, use {changeManagementContract}
     * construction.
     */
    function initialize(string memory name, string memory symbol, address managementContractAddress) public virtual override initializer {
        require(managementContractAddress != address(0), "Management contract address cannot be zero.");
        ERC20PresetMinterPauserUpgradeableModified.initialize(name, symbol, managementContractAddress);

        nonWhitelistedDustThreshold = 10**17; // 0.1 of the coin
    }

    /**
     * @dev Updates the {nonWhitelistedDustThreshold}
     *
     * Requirements:
     *
     * - the caller must be admin - {onlyAdmin} modifier is applied.
     */
    function setNonWhitelistedDustThreshold(uint256 _nonWhitelistedDustThreshold) external virtual onlyAdmin {
        nonWhitelistedDustThreshold = _nonWhitelistedDustThreshold;
    }

    /**
     * @dev Atomically recovers stolen funds that are still in pending deposits.
     * In case of law enforcements notifying Himalaya Group about a theft, Himalaya Group
     * is able to freeze the account and recover funds from pendingDeposit.
     *
     * It calls {_transfer} function to move `amount` from theif's `from` address to
     * victim's `to` address
     *
     * If `from` is not whitelisted, it calls {removeAllPendingDeposits}.
     * See more at {HManagementContract.whitelist})
     *
     * Emits {RecoverFrozen}
     *
     * Requirements:
     *
     * - the `from` address must be frozen. See more at {HManagementContract.freeze}
     * - only Admin can call this function
     */
    function recoverFrozenFunds(address from, address to, uint256 amount) external virtual onlyAdmin {
        require(to != address(0), "Address 'to' cannot be zero.");
        require(managementContract.isFrozen(from), "Need to be frozen first");

        managementContract.unFreeze(from); // Make sure this contract has WHITELIST_ROLE on management contract
        if (!managementContract.isWhitelisted(from)) {
            removeAllPendingDeposits(from);
        }
        _transfer(from, to, amount);
        managementContract.freeze(from);

        emit RecoverFrozen(from, to, amount);
    }

    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant ERROR_REASON_GLOBAL_PAUSE = "Global pause is active";
    string public constant ERROR_REASON_TO_FROZEN = "`to` address is frozen";
    string public constant ERROR_REASON_FROM_FROZEN = "`from` address is frozen";
    string public constant ERROR_REASON_NOT_ENOUGH_UNLOCKED = "User's unlocked balance is less than transfer amount";
    string public constant ERROR_REASON_BELOW_THRESHOLD = "Deposit for non-whitelisted user is below threshold";
    string public constant ERROR_REASON_PENDING_DEPOSITS_LENGTH = "Too many pending deposits for non-whitelisted user";
    string public constant ERROR_DEFAULT = "Generic error message";

    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant ERROR_CODE_GLOBAL_PAUSE = 1;
    uint8 public constant ERROR_CODE_TO_FROZEN = 2;
    uint8 public constant ERROR_CODE_FROM_FROZEN = 3;
    uint8 public constant ERROR_CODE_NOT_ENOUGH_UNLOCKED = 4;
    uint8 public constant ERROR_CODE_BELOW_THRESHOLD = 5;
    uint8 public constant ERROR_CODE_PENDING_DEPOSITS_LENGTH = 6;

    
    /**
    * @dev Evaluates whether a transfer should be allowed or not.
    * Inspired by INX Token: https://etherscan.io/address/0xBBC7f7A6AADAc103769C66CBC69AB720f7F9Eae3#code
    */
    modifier notRestricted (address from, address to, uint256 value) virtual {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     * It also calls the extended contract's {ERC20Pausable._beforeTokenTransfer}.
     * The main purpose is to ensure that the 'from' account has enough unlocked balance
     * and to lock 'amount' in {pendingDeposits} if 'to' is not whitelisted.
     * Calling conditions:
     * - if `to` is SuperWhitelisted and the user doesn't have enough unlocked balance,
     * a part of the pendingDeposits will be unlocked to allow for instant transfer
     * - if 'from' is not Whitelisted, the 'from' is required to have at least 'amount' in available balance
     * - if 'to' is not Whitelisted, the 'to' account must have less {pendingDeposits} than {nonWhitelistedDepositLimit} or
     * there must be some pendingDeposits which will be released during the transfer as they are older than {nonWhitelistedDelay}
     * - `amount` must be bigger or equal to {nonWhitelistedDustThreshold}
     * Requirements:
     *
     * - The Global pause is not actived through {HManagementContract.pause}
     * - 'to' and 'from' addresses must not be frozen
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override notRestricted(from, to, amount) {
        super._beforeTokenTransfer(from, to, amount);

        if (managementContract.isSuperWhitelisted(to)) {
            // Unlock part of the locked balance, so user can make transfer to the superwhitelisted.
            // Do not unlock everything - it would be too easy to exploit it to circumvent the delay.
            // We unlock balance only when sending to SuperWhitelisted
            // Otherwise the simple check `unlockedBalance(from) >= amount`
            uint256 ub = unlockedBalance(from);

            if (ub < amount) {
                uint256 amountToUnlock = amount.sub(ub);
                releaseDepositsForSuperWhitelisted(from, amountToUnlock);
            }
        } else {
            if (!managementContract.isWhitelisted(to)) {
                Deposit memory deposit = Deposit({time: now, amount: amount}); // solium-disable-line security/no-block-members
                pendingDeposits[to].push(deposit);
            }
        }
    }

    /**
     * @dev Member of ERC-1404 Simple Restricted Token Standard: https://github.com/ethereum/EIPs/issues/1404
     */
    function detectTransferRestriction (address from, address to, uint256 value) public virtual override view returns (uint8) {
        // There are other typical error conditions that are part of ERC20 standard, not our custom code
        // "ERC20Pausable: token transfer while paused"
        // "ERC20: transfer amount exceeds balance"

        if (managementContract.paused()) {
            return ERROR_CODE_GLOBAL_PAUSE;
        }
        
        if (managementContract.isFrozen(to)) {
            return ERROR_CODE_TO_FROZEN;
        }

        if (managementContract.isFrozen(from)) {
            return ERROR_CODE_FROM_FROZEN;
        }

        if (!managementContract.isSuperWhitelisted(to)) {
            
            if (!managementContract.isWhitelisted(from)) {
                if (! (unlockedBalance(from) >= value)) {
                    return ERROR_CODE_NOT_ENOUGH_UNLOCKED;
                }
            }

            if (!managementContract.isWhitelisted(to)) {
                uint256 nonWhitelistedDelay = managementContract.nonWhitelistedDelay();
                uint256 nonWhitelistedDepositLimit = managementContract.nonWhitelistedDepositLimit();
                uint256 pendingDepositsLength = pendingDeposits[to].length;

                if (! (pendingDepositsLength < nonWhitelistedDepositLimit || (now > pendingDeposits[to][pendingDepositsLength - nonWhitelistedDepositLimit].time + nonWhitelistedDelay))) { // solium-disable-line security/no-block-members
                    return ERROR_CODE_PENDING_DEPOSITS_LENGTH;
                }

                if (! (value >= nonWhitelistedDustThreshold)) {
                    return ERROR_CODE_BELOW_THRESHOLD;
                }
            }
        }
    }

    /**
     * @dev Member of ERC-1404 Simple Restricted Token Standard: https://github.com/ethereum/EIPs/issues/1404
     */
    function messageForTransferRestriction (uint8 restrictionCode) public virtual override view returns (string memory) {
        if (restrictionCode == SUCCESS_CODE) {
            return SUCCESS_MESSAGE;
        } else if (restrictionCode == ERROR_CODE_GLOBAL_PAUSE) {
            return ERROR_REASON_GLOBAL_PAUSE;
        } else if (restrictionCode == ERROR_CODE_TO_FROZEN) {
            return ERROR_REASON_TO_FROZEN;
        } else if (restrictionCode == ERROR_CODE_FROM_FROZEN) {
            return ERROR_REASON_FROM_FROZEN;
        } else if (restrictionCode == ERROR_CODE_NOT_ENOUGH_UNLOCKED) {
            return ERROR_REASON_NOT_ENOUGH_UNLOCKED;
        } else if (restrictionCode == ERROR_CODE_BELOW_THRESHOLD) {
            return ERROR_REASON_BELOW_THRESHOLD;
        } else if (restrictionCode == ERROR_CODE_PENDING_DEPOSITS_LENGTH) {
            return ERROR_REASON_PENDING_DEPOSITS_LENGTH;
        } else {
            return ERROR_DEFAULT;
        }
    }

    /**
     * @dev Member of ERC-165 Standard Interface Detection: https://eips.ethereum.org/EIPS/eip-165
     * See issue on internal Github to see how it is calculated: https://ec2-18-130-7-129.eu-west-2.compute.amazonaws.com/Himalaya-Exchange/hpay-token/issues/39
     */
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0xab84a5c8;
    }

    /**
     * @dev Releases the `amount` from `from` user's {pendingDeposits}.
     * It is used only in one specific instance: sending to SuperWhitelisted
     * There is no need to remove old pending deposits, that happens only during whitelisting
     */
    function releaseDepositsForSuperWhitelisted(address from, uint256 amount) internal virtual {
        uint256 nonWhitelistedDelay = managementContract.nonWhitelistedDelay();

        uint256 pendingDepositsLength = pendingDeposits[from].length;

        // Iterating starting from the most recent deposits. Cannot check `>= 0`, as the `i--` will cause underflow and a very large integer
        // Second condition in the loop is checking the time. Unlocking from pending deposits makes sense only for the recent deposits that are within timelock
        for (uint256 i = pendingDepositsLength - 1; i != uint256(-1) && pendingDeposits[from][i].time > now - nonWhitelistedDelay; i--) { // solium-disable-line security/no-block-members
            if (amount < pendingDeposits[from][i].amount) {
                pendingDeposits[from][i].amount = pendingDeposits[from][i].amount.sub(amount);
                break;
            } else {
                amount = amount.sub(pendingDeposits[from][i].amount);
                pendingDeposits[from].pop();
            }
        }
    }

    /**
     * @dev Removes all pending deposits. See more at {pendingDeposits}
     */
    function removeAllPendingDeposits(address from) internal virtual {
        delete pendingDeposits[from];
    }

    /**
     * @dev Removes all pending deposits. See more at {pendingDeposits}. Can be called only from management contract.
     *
     * Requirements:
     *
     * - the caller must be `managementContract`.
     */
    function removeAllPendingDepositsExternal(address addr) external virtual onlyManagementContract {
        delete pendingDeposits[addr];
    }

    /**
     * @dev Adds total balance of `addr` to {pendingDeposits} with timestamp of the block.. Can be called only from management contract.
     *
     * Requirements:
     *
     * - the caller must be `managementContract`.
     */
    function putTotalBalanceToLock(address addr) external virtual onlyManagementContract {
        pendingDeposits[addr].push(Deposit({time: now, amount: balanceOf(addr)})); // solium-disable-line security/no-block-members
    }

    //////////////////////// VIEW
    /**
     * @dev Calculates `user`'s balance that is locked in {pendingDeposits}
     */
    function lockedBalance(address user) public virtual view returns (uint256) {
        uint256 balanceLocked = 0;
        uint256 pendingDepositsLength = pendingDeposits[user].length;
        uint256 nonWhitelistedDelay = managementContract.nonWhitelistedDelay();

        // Iterating starting from the most recent deposits. Cannot check `>= 0`, as the `i--` will cause underflow and a very large integer
        // Second condition in the loop is checking the time. We calculate `balanceLocked` using deposits that happened within `nonWhitelistedDelay` (most likely 24 hours)
        for (uint256 i = pendingDepositsLength - 1; i != uint256(-1) && pendingDeposits[user][i].time > now - nonWhitelistedDelay; i--) { // solium-disable-line security/no-block-members
            balanceLocked = balanceLocked.add(pendingDeposits[user][i].amount);
        }
        return balanceLocked;
    }

    /**
     * @dev Calculates `user`'s available balance for instant transfer
     * by subtracting the balance locked in {pendingDeposits} from the over
     * balance.
     */
    function unlockedBalance(address user) public virtual view returns (uint256) {
        return balanceOf(user).sub(lockedBalance(user));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./HHH.sol";

contract HHHmainnet is HHH {
    function initialize(string memory name, string memory symbol, address managementContractAddress, address newMintingAddress) public virtual initializer {
        require(managementContractAddress != address(0), "Management contract address cannot be zero.");
        require(newMintingAddress != address(0), "New minting address cannot be zero.");
        HHH.initialize(name, symbol, managementContractAddress);
        mintingAddress = newMintingAddress;
    }

    address private mintingAddress;

    function changeMintingAddress(address newMintingAddress) external virtual onlyAdmin {
        require(newMintingAddress != address(0), "New minting address cannot be zero.");
        mintingAddress = newMintingAddress;
    }

    /**
     * @dev Creates `amount` new tokens for `mingingAddress`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function mint(uint256 amount) public virtual onlyAdmin {
        // require(managementContract.hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint"); // MODIFIED
        _mint(mintingAddress, amount);
    }

    /**
     * @dev Burns `amount` tokens from `mingingAddress`.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function burn(uint256 amount) public virtual override onlyAdmin {
        _burn(mintingAddress, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

// Extracted from: https://github.com/simple-restricted-token/reference-implementation/blob/master/contracts/token/ERC1404/ERC1404.sol
interface IERC1404 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

// https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IManagementContract {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function whitelist(address addr) external view;

    function unWhitelist(address addr) external view;

    function isWhitelisted(address addr) external view returns (bool);

    function freeze(address addr) external;

    function unFreeze(address addr) external;

    function isFrozen(address addr) external view returns (bool);

    function addSuperWhitelisted(address addr) external;

    function removeSuperWhitelisted(address addr) external;

    function isSuperWhitelisted(address addr) external view returns (bool);

    function nonWhitelistedDelay() external view returns (uint256);

    function nonWhitelistedDepositLimit() external view returns (uint256);

    function setNonWhitelistedDelay(uint256 _nonWhitelistedDelay) external view;

    function setNonWhitelistedDepositLimit(uint256 _nonWhitelistedDepositLimit) external view;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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
library SafeMathUpgradeable {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../utils/PausableUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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