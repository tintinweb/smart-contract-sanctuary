//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "../roles/RolesManagerConsts.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract Base {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address private settings;

    /* Modifiers */

    modifier onlyOwner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyMinter(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).MINTER_ROLE(),
            account,
            "SENDER_ISNT_MINTER"
        );
        _;
    }

    /* Constructor */

    constructor(address settingsAddress) internal {
        require(settingsAddress.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        settings = settingsAddress;
    }

    /** Internal Functions */

    function _settings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(settings);
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(settings).rolesManager());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    bytes32 public constant VAULT_CONFIGURATOR_ROLE = keccak256("VAULT_CONFIGURATOR_ROLE");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IPlatformSettings {
    event PlatformPaused(address indexed pauser);

    event PlatformUnpaused(address indexed unpauser);

    event PlatformSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 minValue,
        uint256 value,
        uint256 maxValue
    );

    event PlatformSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event PlatformSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function pause() external;

    function unpause() external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IRolesManager {
    event MaxMultiItemsUpdated(address indexed updater, uint8 oldValue, uint8 newValue);

    function setMaxMultiItems(uint8 newMaxMultiItems) external;

    function multiGrantRole(bytes32 role, address[] calldata accounts) external;

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external;

    function consts() external view returns (address);

    function maxMultiItems() external view returns (uint8);

    function requireHasRole(bytes32 role, address account) external view;

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

library SettingsLib {
    /**
        It defines a setting. It includes: value, min, and max values.
     */
    struct Setting {
        uint256 value;
        uint256 min;
        uint256 max;
        bool exists;
    }

    /**
        @notice It creates a new setting given a name, min and max values.
        @param value initial value for the setting.
        @param min min value allowed for the setting.
        @param max max value allowed for the setting.
     */
    function create(
        Setting storage self,
        uint256 value,
        uint256 min,
        uint256 max
    ) internal {
        requireNotExists(self);
        require(value >= min, "VALUE_MUST_BE_GT_MIN_VALUE");
        require(value <= max, "VALUE_MUST_BE_LT_MAX_VALUE");
        self.value = value;
        self.min = min;
        self.max = max;
        self.exists = true;
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the setting already exists.
        @param self the current setting.
     */
    function requireNotExists(Setting storage self) internal view {
        require(!self.exists, "SETTING_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the current setting doesn't exist.
        @param self the current setting.
     */
    function requireExists(Setting storage self) internal view {
        require(self.exists, "SETTING_NOT_EXISTS");
    }

    /**
        @notice It updates a current setting.
        @dev It throws a require error if:
            - The new value is equal to the current value.
            - The new value is not lower than the max value.
            - The new value is not greater than the min value
        @param self the current setting.
        @param newValue the new value to set in the setting.
     */
    function update(Setting storage self, uint256 newValue) internal returns (uint256 oldValue) {
        requireExists(self);
        require(self.value != newValue, "NEW_VALUE_REQUIRED");
        require(newValue >= self.min, "NEW_VALUE_MUST_BE_GT_MIN_VALUE");
        require(newValue <= self.max, "NEW_VALUE_MUST_BE_LT_MAX_VALUE");
        oldValue = self.value;
        self.value = newValue;
    }

    /**
        @notice It removes a current setting.
        @param self the current setting to remove.
     */
    function remove(Setting storage self) internal {
        requireExists(self);
        self.value = 0;
        self.min = 0;
        self.max = 0;
        self.exists = false;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "../base/Base.sol";

contract BaseMinterPauserToken is Base, Context, ERC20Burnable {
    constructor(
        address settingsAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal Base(settingsAddress) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external onlyMinter(_msgSender()) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        _settings().requireIsNotPaused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./BaseMinterPauserToken.sol";

contract PGU is BaseMinterPauserToken {
    /* State Variables */
    string private constant NAME = "Polyient Games Unity";
    string private constant SYMBOL = "PGU";
    uint8 private constant DECIMALS = 18;

    /* Constructor */

    constructor(address settingsAddress)
        public
        BaseMinterPauserToken(settingsAddress, NAME, SYMBOL, DECIMALS)
    {}
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "../libs/SettingsLib.sol";

// Contracts
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../roles/RolesManagerConsts.sol";

// Interfaces
import "./IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

contract PlatformSettings is IPlatformSettings {
    using Address for address;
    using SettingsLib for SettingsLib.Setting;

    /** Constants */

    /* State Variables */

    /**
        @notice This mapping represents the platform settings where:

        - The key is the platform setting name.
        - The value is the platform setting. It includes the value, minimum and maximum values.
     */
    mapping(bytes32 => SettingsLib.Setting) public settings;

    bool public paused;

    address public override rolesManager;

    /** Modifiers */

    modifier onlyPauser(address account) {
        _rolesManager().requireHasRole(
            _rolesManagerConsts().PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    modifier onlyConfigurator(address account) {
        _rolesManager().requireHasRole(
            _rolesManagerConsts().CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    /* Constructor */

    constructor(address rolesManagerAddress) public {
        require(rolesManagerAddress.isContract(), "ROLES_MANAGER_MUST_BE_CONTRACT");
        rolesManager = rolesManagerAddress;
    }

    /** External Functions */

    /**
        @notice It creates a new platform setting given a name, value, min and max values.
        @param name setting name to create.
        @param value the initial value for the given setting name.
        @param min the min value for the setting.
        @param max the max value for the setting.
     */
    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external override onlyConfigurator(msg.sender) {
        require(name != "", "NAME_MUST_BE_PROVIDED");
        settings[name].create(value, min, max);

        emit PlatformSettingCreated(name, msg.sender, value, min, max);
    }

    /**
        @notice It updates an existent platform setting given a setting name.
        @notice It only allows to update the value (not the min or max values).
        @notice In case you need to update the min or max values, you need to remove it, and create it again.
        @param settingName setting name to update.
        @param newValue the new value to set.
     */
    function updateSetting(bytes32 settingName, uint256 newValue)
        external
        onlyConfigurator(msg.sender)
    {
        uint256 oldValue = settings[settingName].update(newValue);

        emit PlatformSettingUpdated(settingName, msg.sender, oldValue, newValue);
    }

    /**
        @notice Removes a current platform setting given a setting name.
        @param name to remove.
     */
    function removeSetting(bytes32 name) external override onlyConfigurator(msg.sender) {
        uint256 oldValue = settings[name].value;
        settings[name].remove();

        emit PlatformSettingRemoved(name, msg.sender, oldValue);
    }

    function pause() external override onlyPauser(msg.sender) {
        require(!paused, "PLATFORM_ALREADY_PAUSED");

        paused = true;

        emit PlatformPaused(msg.sender);
    }

    function unpause() external override onlyPauser(msg.sender) {
        require(paused, "PLATFORM_ISNT_PAUSED");

        paused = false;

        emit PlatformUnpaused(msg.sender);
    }

    /* View Functions */

    function requireIsPaused() external view override {
        require(paused, "PLATFORM_ISNT_PAUSED");
    }

    function requireIsNotPaused() external view override {
        require(!paused, "PLATFORM_IS_PAUSED");
    }

    /**
        @notice It gets the current platform setting for a given setting name
        @param name to get.
        @return the current platform setting.
     */
    function getSetting(bytes32 name) external view override returns (SettingsLib.Setting memory) {
        return _getSetting(name);
    }

    /**
        @notice It gets the current platform setting value for a given setting name
        @param name to get.
        @return the current platform setting value.
     */
    function getSettingValue(bytes32 name) external view override returns (uint256) {
        return _getSetting(name).value;
    }

    /**
        @notice It tests whether a setting name is already configured.
        @param name setting name to test.
        @return true if the setting is already configured. Otherwise it returns false.
     */
    function hasSetting(bytes32 name) external view override returns (bool) {
        return _getSetting(name).exists;
    }

    /**
        @notice It gets whether the platform is paused or not.
        @return true if platform is paused. Otherwise it returns false.
     */
    function isPaused() external view override returns (bool) {
        return paused;
    }

    /** Internal functions */

    /**
        @notice It gets the platform setting for a given setting name.
        @param name the setting name to look for.
        @return the current platform setting for the given setting name.
     */
    function _getSetting(bytes32 name) internal view returns (SettingsLib.Setting memory) {
        return settings[name];
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(rolesManager);
    }

    function _rolesManagerConsts() internal view returns (RolesManagerConsts) {
        return RolesManagerConsts(_rolesManager().consts());
    }

    /** Private functions */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
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
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./IRolesManager.sol";
import "./RolesManagerConsts.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RolesManager is AccessControl, IRolesManager {
    address public override consts;

    uint8 public override maxMultiItems;

    constructor(uint8 initialMaxMultiItems) public {
        maxMultiItems = initialMaxMultiItems;

        consts = address(new RolesManagerConsts());

        // Setting the role admin for all the platform roles.
        _setRoleAdmin(_consts().PAUSER_ROLE(), _consts().OWNER_ROLE());
        _setRoleAdmin(_consts().VAULT_CONFIGURATOR_ROLE(), _consts().OWNER_ROLE());
        _setRoleAdmin(_consts().MINTER_ROLE(), _consts().OWNER_ROLE());
        _setRoleAdmin(_consts().CONFIGURATOR_ROLE(), _consts().OWNER_ROLE());

        // Setting roles
        /*
            The OWNER_ROLE is its own admin role. See AccessControl.DEFAULT_ADMIN_ROLE.
        */
        _setupRole(_consts().OWNER_ROLE(), msg.sender);
        _setupRole(_consts().PAUSER_ROLE(), msg.sender);
        _setupRole(_consts().CONFIGURATOR_ROLE(), msg.sender);
    }

    function requireHasRole(bytes32 role, address account) external view override {
        require(hasRole(role, account), "ACCOUNT_HASNT_GIVEN_ROLE");
    }

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view override {
        require(hasRole(role, account), message);
    }

    function setMaxMultiItems(uint8 newMaxMultiItems) external override {
        require(hasRole(_consts().OWNER_ROLE(), _msgSender()), "SENDER_HASNT_OWNER_ROLE");
        require(maxMultiItems != newMaxMultiItems, "NEW_MAX_MULTI_ITEMS_REQUIRED");
        uint8 oldMaxMultiItems = maxMultiItems;

        maxMultiItems = newMaxMultiItems;

        emit MaxMultiItemsUpdated(msg.sender, oldMaxMultiItems, newMaxMultiItems);
    }

    function multiGrantRole(bytes32 role, address[] calldata accounts) external override {
        require(accounts.length <= maxMultiItems, "ACCOUNTS_LENGTH_EXCEEDS_MAX");
        for (uint256 i = 0; i < accounts.length; i++) {
            grantRole(role, accounts[i]);
        }
    }

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external override {
        require(accounts.length <= maxMultiItems, "ACCOUNTS_LENGTH_EXCEEDS_MAX");

        for (uint256 i = 0; i < accounts.length; i++) {
            revokeRole(role, accounts[i]);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        require(getRoleAdmin(role) == "", "ROLE_MUST_BE_NEW");
        require(hasRole(_consts().OWNER_ROLE(), _msgSender()), "SENDER_HASNT_OWNER_ROLE");

        _setRoleAdmin(role, adminRole);
    }

    function _consts() internal view returns (RolesManagerConsts) {
        return RolesManagerConsts(consts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IVaultsSettings {
    event VaultSettingCreated(
        address indexed creator,
        address indexed vault,
        uint256 value,
        uint256 min,
        uint256 maxs
    );

    event VaultSettingRemoved(address indexed remover, bytes32 name);

    function createVaultSetting(
        address vault,
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeVaultSetting(address vault, bytes32 name) external;

    function getVaultSetting(address vault, bytes32 name)
        external
        view
        returns (SettingsLib.Setting memory);

    function getVaultSettingValue(address vault, bytes32 name) external view returns (uint256);

    function hasVaultSetting(address vault, bytes32 name) external view returns (bool);

    function getVaultSettingOrDefaultValue(address vault, bytes32 name)
        external
        view
        returns (uint256);

    function getVaultSettingOrDefault(address vault, bytes32 name)
        external
        view
        returns (SettingsLib.Setting memory);

    function hasVaultSettingOrDefault(address vault, bytes32 name) external view returns (bool);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../minters/IRewardsMinter.sol";

abstract contract RewardsCalculatorBase {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address private rewardsMinter;

    /* Modifiers */

    modifier onlyRewardsMinter(address account) {
        _requireOnlyRewardsMinter(account);
        _;
    }

    /* Constructor */

    /** View Functions */

    function _rewardsMinter() internal view returns (IRewardsMinter) {
        return IRewardsMinter(rewardsMinter);
    }

    function _requireOnlyRewardsMinter(address account) internal view {
        require(
            rewardsMinter != address(0x0) && account == rewardsMinter,
            "ACCOUNT_ISNT_REWARDS_MINTER"
        );
    }

    /* Internal Funtions */

    function _setRewardsMinter(address rewardsMinterAddress) internal {
        require(rewardsMinterAddress.isContract(), "REWARDS_MINTER_MUST_BE_CONTRACT");
        rewardsMinter = rewardsMinterAddress;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "../tokens/IMintableERC20.sol";

interface IRewardsMinter {
    event NewCalculatorAdded(
        address indexed adder,
        address indexed newCalulator,
        uint256 calculatorPercentage,
        uint256 currentPercentage
    );

    event CalculatorRemoved(
        address indexed remover,
        address indexed calulator,
        uint256 calculatorPercentage,
        uint256 currentPercentage
    );

    event CalculatorPercentageUpdated(
        address indexed updater,
        address indexed calulator,
        uint256 newcalculatorPercentage,
        uint256 currentPercentage
    );

    event RewardsClaimed(address indexed account, uint256 indexed periodId, uint256 amount);

    function token() external view returns (IMintableERC20);

    function settings() external view returns (address);

    function rewardPeriodsRegistry() external view returns (address);

    function currentPercentage() external view returns (uint256);

    function getCalculators() external view returns (address[] memory);

    function getAvailableRewards(uint256 periodId, address account) external view returns (uint256);

    function claimRewards(uint256 periodId) external;

    function addCalculator(address newCalculator, uint256 percentage) external;

    function removeCalculator(address calculator) external;

    function hasCalculator(address calculator) external view returns (bool);

    function updateCalculatorPercentage(address calculator, uint256 percentage) external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address account, uint256 amount) external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "../base/MigratorBase.sol";

// Interfaces
import "../tokens/IMintableERC20.sol";
import "../rewards/IRewardsCalculator.sol";
import "./IRewardsMinter.sol";
import "../registries/IRewardPeriodsRegistry.sol";

// Libraries
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/RewardCalculatorLib.sol";
import "../libs/AddressesLib.sol";

contract RewardsMinter is MigratorBase, IRewardsMinter {
    using RewardCalculatorLib for RewardCalculatorLib.RewardCalculator;
    using AddressesLib for address[];
    using SafeMath for uint256;

    /* Constant Variables */
    uint256 private constant MAX_PERCENTAGE = 10000;

    /* State Variables */

    IMintableERC20 public override token;

    mapping(address => RewardCalculatorLib.RewardCalculator) public calculators;

    uint256 public override currentPercentage;

    address[] public calculatorsList;

    address public override rewardPeriodsRegistry;

    /* Modifiers */

    /* Constructor */

    constructor(
        address rewardPeriodsRegistryAddress,
        address settingsAddress,
        address tokenAddress
    ) public MigratorBase(settingsAddress) {
        require(rewardPeriodsRegistryAddress.isContract(), "PERIODS_REG_MUST_BE_CONTRACT");
        require(tokenAddress.isContract(), "TOKEN_MUST_BE_CONTRACT");

        rewardPeriodsRegistry = rewardPeriodsRegistryAddress;
        token = IMintableERC20(tokenAddress);
    }

    function claimRewards(uint256 periodId) external override {
        _settings().requireIsNotPaused();
        require(currentPercentage == MAX_PERCENTAGE, "CURRENT_PERCENTAGE_INVALID");

        (
            uint256 id,
            ,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            ,
            uint256 availableRewards,
            bool exists
        ) = _getRewardPeriod(periodId);
        require(exists, "PERIOD_ID_NOT_EXISTS");
        require(endPeriodTimestamp < block.timestamp, "REWARD_PERIOD_IN_PROGRESS");
        require(endRedeemablePeriodTimestamp > block.timestamp, "CLAIMABLE_PERIOD_FINISHED");

        address account = msg.sender;
        uint256 totalRewardsSent = 0;
        for (uint256 indexAt = 0; indexAt < calculatorsList.length; indexAt++) {
            IRewardsCalculator rewardsCalculator = IRewardsCalculator(calculatorsList[indexAt]);

            uint256 calculatorPercentage = calculators[calculatorsList[indexAt]].getPercentage();
            /*
                Available Rewards: 1000
                Calculator Percentage: 5000
                Calculator Available Rewards = 1000 * 5000 / 100
            */
            uint256 calculatorAvailableRewards =
                availableRewards.mul(calculatorPercentage).div(100);

            uint256 availableRewardsForAcount =
                rewardsCalculator.processRewards(
                    id,
                    account,
                    availableRewards,
                    calculatorAvailableRewards
                );
            totalRewardsSent = totalRewardsSent.add(availableRewardsForAcount);
            if (availableRewardsForAcount > 0) {
                token.mint(account, availableRewardsForAcount);
            }
        }
        if (totalRewardsSent > 0) {
            _notifyRewardsSent(id, totalRewardsSent);
            emit RewardsClaimed(account, id, totalRewardsSent);
        }
    }

    function updateCalculatorPercentage(address calculator, uint256 percentage)
        external
        override
        onlyOwner(msg.sender)
    {
        require(calculators[calculator].exists, "CALCULATOR_ISNT_ADDED");
        uint256 oldPercentage = calculators[calculator].percentage;

        uint256 newCurrentPercentage = currentPercentage.sub(oldPercentage).add(percentage);
        require(newCurrentPercentage <= MAX_PERCENTAGE, "ACCUM_PERCENTAGE_EXCEEDS_MAX");

        calculators[calculator].update(percentage);

        currentPercentage = newCurrentPercentage;

        emit CalculatorPercentageUpdated(msg.sender, calculator, percentage, currentPercentage);
    }

    function addCalculator(address newCalculator, uint256 percentage)
        external
        override
        onlyOwner(msg.sender)
    {
        require(newCalculator.isContract(), "NEW_CALCULATOR_MUST_BE_CONTRACT");
        require(!calculators[newCalculator].exists, "CALCULATOR_ALREADY_ADDED");
        uint256 newCurrentPercentage = currentPercentage.add(percentage);
        require(newCurrentPercentage <= MAX_PERCENTAGE, "ACCUM_PERCENTAGE_EXCEEDS_MAX");

        calculators[newCalculator].create(percentage);
        calculatorsList.add(newCalculator);

        currentPercentage = newCurrentPercentage;

        emit NewCalculatorAdded(msg.sender, newCalculator, percentage, currentPercentage);
    }

    function removeCalculator(address calculator) external override onlyOwner(msg.sender) {
        require(calculators[calculator].exists, "CALCULATOR_DOESNT_EXIST");
        uint256 percentage = calculators[calculator].percentage;

        calculatorsList.remove(calculator);
        calculators[calculator].remove();

        currentPercentage = currentPercentage.sub(percentage);

        emit CalculatorRemoved(msg.sender, calculator, percentage, currentPercentage);
    }

    /** View Functions */

    function settings() external view override returns (address) {
        return address(_settings());
    }

    function getAvailableRewards(uint256 periodId, address account)
        external
        view
        override
        returns (uint256)
    {
        if (currentPercentage != MAX_PERCENTAGE) {
            return 0;
        }
        (
            uint256 id,
            uint256 startPeriodTimestamp,
            ,
            uint256 endRedeemablePeriodTimestamp,
            ,
            uint256 availableRewards,
            bool exists
        ) = _getRewardPeriod(periodId);
        if (
            !exists ||
            startPeriodTimestamp > block.timestamp ||
            endRedeemablePeriodTimestamp < block.timestamp
        ) {
            return 0;
        }

        uint256 rewardsForAccount = 0;
        for (uint256 indexAt = 0; indexAt < calculatorsList.length; indexAt++) {
            IRewardsCalculator rewardsCalculator = IRewardsCalculator(calculatorsList[indexAt]);

            uint256 calculatorPercentage = calculators[calculatorsList[indexAt]].getPercentage();
            /*
                Available Rewards: 1000
                Calculator Percentage: 5000
                Calculator Available Rewards = 1000 * 5000 / 100
            */
            uint256 calculatorAvailableRewards =
                availableRewards.mul(calculatorPercentage).div(100);

            uint256 availableRewardsForAcount =
                rewardsCalculator.getRewards(
                    id,
                    account,
                    availableRewards,
                    calculatorAvailableRewards
                );
            rewardsForAccount = rewardsForAccount.add(availableRewardsForAcount);
        }
        return rewardsForAccount;
    }

    function getCalculators() external view override returns (address[] memory) {
        return calculatorsList;
    }

    function hasCalculator(address calculator) external view override returns (bool) {
        return calculators[calculator].exists;
    }

    /* Internal Functions */

    function _notifyRewardsSent(uint256 period, uint256 totalRewardsSent) internal {
        IRewardPeriodsRegistry rewardsRegistry = IRewardPeriodsRegistry(rewardPeriodsRegistry);
        rewardsRegistry.notifyRewardsSent(period, totalRewardsSent);
    }

    function _getRewardPeriod(uint256 periodId)
        internal
        view
        returns (
            uint256 id,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        )
    {
        IRewardPeriodsRegistry rewardsRegistry = IRewardPeriodsRegistry(rewardPeriodsRegistry);
        (
            id,
            startPeriodTimestamp,
            endPeriodTimestamp,
            endRedeemablePeriodTimestamp,
            totalRewards,
            availableRewards,
            exists
        ) = rewardsRegistry.getRewardPeriodById(periodId);
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "./Base.sol";

// Libraries

// Interfaces
import "../migrator/IMigrator.sol";

abstract contract MigratorBase is Base {
    /* Constant Variables */

    /* State Variables */

    address private migrator;

    /* Modifiers */

    /* Constructor */

    constructor(address settingsAddress) internal Base(settingsAddress) {}

    /* External Functions */

    function setMigrator(address newMigrator) external onlyOwner(msg.sender) {
        require(newMigrator.isContract(), "MIGRATOR_MUST_BE_CONTRACT");
        migrator = newMigrator;
    }

    function migrateTo(address newContract, bytes calldata extraData)
        external
        onlyOwner(msg.sender)
    {
        require(newContract != address(0x0), "MIGRATOR_IS_EMPTY");
        IMigrator(migrator).migrate(address(this), newContract, extraData);
    }

    function hasMigrator() external view returns (bool) {
        return migrator != address(0x0);
    }

    /** Internal Functions */

    function _migrator() internal view returns (address) {
        return migrator;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IRewardsCalculator {
    function getRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external view returns (uint256);

    function processRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external returns (uint256 rewardsForAccount);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/RewardPeriodLib.sol";

interface IRewardPeriodsRegistry {
    event RewardPeriodCreated(
        address indexed creator,
        uint256 period,
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    );

    event RewardPeriodRemoved(
        address indexed remover,
        uint256 period,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 availableRewards
    );

    function settings() external view returns (address);

    function getRewardPeriod(uint256 id)
        external
        view
        returns (RewardPeriodLib.RewardPeriod memory);

    function notifyRewardsSent(uint256 period, uint256 totalRewardsSent)
        external
        returns (uint256 newTotalAvailableRewards);

    function createRewardPeriod(
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    ) external;

    function getRewardPeriods() external view returns (RewardPeriodLib.RewardPeriod[] memory);

    function getLastRewardPeriod()
        external
        view
        returns (
            uint256 periodId,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        );

    function getRewardPeriodById(uint256 periodId)
        external
        view
        returns (
            uint256 id,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        );
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

library RewardCalculatorLib {
    uint256 private constant MAX_PERCENTAGE = 10000;

    struct RewardCalculator {
        uint256 percentage; // 1000 => 10% (10 * 100)
        bool paused;
        bool exists;
    }

    function create(RewardCalculator storage self, uint256 percentage) internal {
        requireNotExists(self);
        require(percentage <= MAX_PERCENTAGE, "PERCENTAGE_MUST_BE_LT_MAX");
        self.percentage = percentage;
        self.exists = true;
    }

    /**
        @notice It updates the current reward calculator.
        @param self the current reward calculator.
        @param newPercentage the new percentage to set in the reward calculator.
     */
    function update(RewardCalculator storage self, uint256 newPercentage)
        internal
        returns (uint256 oldPercentage)
    {
        requireExists(self);
        require(self.percentage != newPercentage, "NEW_PERCENTAGE_REQUIRED");
        require(newPercentage < MAX_PERCENTAGE, "PERCENTAGE_MUST_BE_LT_MAX");
        oldPercentage = self.percentage;
        self.percentage = newPercentage;
    }

    function pause(RewardCalculator storage self) internal {
        requireExists(self);
        require(!self.paused, "CALCULATOR_ALREADY_PAUSED");
        self.paused = true;
    }

    function unpause(RewardCalculator storage self) internal {
        requireExists(self);
        require(self.paused, "CALCULATOR_NOT_PAUSED");
        self.paused = false;
    }

    function getPercentage(RewardCalculator storage self) internal view returns (uint256) {
        return self.exists && !self.paused ? self.percentage : 0;
    }

    /**
        @notice Checks whether the current reward calculator exists or not.
        @dev It throws a require error if the reward calculator already exists.
        @param self the current reward calculator.
     */
    function requireNotExists(RewardCalculator storage self) internal view {
        require(!self.exists, "REWARD_CALC_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current reward calculator exists or not.
        @dev It throws a require error if the current reward calculator doesn't exist.
        @param self the current reward calculator.
     */
    function requireExists(RewardCalculator storage self) internal view {
        require(self.exists, "REWARD_CALC_NOT_EXISTS");
    }

    /**
        @notice It removes a current reward calculator.
        @param self the current reward calculator to remove.
     */
    function remove(RewardCalculator storage self) internal {
        requireExists(self);
        self.percentage = 0;
        self.exists = false;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

/**
    @notice Utility library of inline functions on the address arrays.
 */
library AddressesLib {
    /**
      @notice It adds an address value to the array.
      @param self current array.
      @param newItem new item to add.
    */
    function add(address[] storage self, address newItem) internal {
        require(newItem != address(0x0), "EMPTY_ADDRESS_NOT_ALLOWED");
        self.push(newItem);
    }

    /**
      @notice It removes the value at the given index in an array.
      @param self the current array.
      @param index remove an item in a specific index.
    */
    function removeAt(address[] storage self, uint256 index) internal {
        if (index >= self.length) return;

        if (index != self.length - 1) {
            address temp = self[self.length - 1];
            self[index] = temp;
        }

        delete self[self.length - 1];
        self.pop();
    }

    /**
      @notice It gets the index for a given item.
      @param self the current array.
      @param item to get the index.
      @return found true if the item was found. Otherwise it returns false. indexAt the current index for a given item.
    */
    function getIndex(address[] storage self, address item)
        internal
        view
        returns (bool found, uint256 indexAt)
    {
        for (indexAt = 0; indexAt < self.length; indexAt++) {
            found = self[indexAt] == item;
            if (found) {
                return (found, indexAt);
            }
        }
        return (found, indexAt);
    }

    /**
      @notice It removes an address value from the array.
      @param self the current array.
      @param item the item to remove.
    */
    function remove(address[] storage self, address item) internal {
        (bool found, uint256 indexAt) = getIndex(self, item);
        if (!found) return;

        removeAt(self, indexAt);
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IMigrator {
    event ContractMigrated(
        address indexed migrator,
        address indexed oldContract,
        address indexed newContract
    );

    function migrate(
        address oldContract,
        address newContract,
        bytes calldata extraData
    ) external returns (address);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library RewardPeriodLib {
    using SafeMath for uint256;

    struct RewardPeriod {
        uint256 id;
        uint256 startPeriodTimestamp;
        uint256 endPeriodTimestamp;
        uint256 endRedeemablePeriodTimestamp;
        uint256 totalRewards;
        uint256 availableRewards;
        bool exists;
    }

    function create(
        RewardPeriod storage self,
        uint256 id,
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    ) internal {
        requireNotExists(self);
        require(block.timestamp <= startPeriodTimestamp, "START_TIMESTAMP_IS_INVALID");
        require(startPeriodTimestamp < endPeriodTimestamp, "REWARD_PERIOD_IS_INVALID");
        require(endPeriodTimestamp < endRedeemablePeriodTimestamp, "END_REDEEM_PERIOD_IS_INVALID");
        require(availableRewards > 0, "REWARDS_MUST_BE_GT_ZERO");
        self.id = id;
        self.startPeriodTimestamp = startPeriodTimestamp;
        self.endPeriodTimestamp = endPeriodTimestamp;
        self.endRedeemablePeriodTimestamp = endRedeemablePeriodTimestamp;
        self.availableRewards = availableRewards;
        self.totalRewards = availableRewards;
        self.exists = true;
    }

    function isInProgress(RewardPeriod storage self) internal view returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return
            self.exists &&
            self.startPeriodTimestamp <= currentTimestamp &&
            currentTimestamp <= self.endPeriodTimestamp;
    }

    function isInRedemption(RewardPeriod storage self) internal view returns (bool) {
        return isFinished(self) && self.endRedeemablePeriodTimestamp > block.timestamp;
    }

    function isFinished(RewardPeriod storage self) internal view returns (bool) {
        return self.exists && self.endPeriodTimestamp < block.timestamp;
    }

    function isPending(RewardPeriod storage self) internal view returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return self.exists && self.startPeriodTimestamp > currentTimestamp;
    }

    /**
        @notice Checks whether the current reward period exists or not.
        @dev It throws a require error if the reward period already exists.
        @param self the current reward period.
     */
    function requireNotExists(RewardPeriod storage self) internal view {
        require(!self.exists, "REWARD_PERIOD_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current reward period exists or not.
        @dev It throws a require error if the current reward period doesn't exist.
        @param self the current reward period.
     */
    function requireExists(RewardPeriod storage self) internal view {
        require(self.exists, "REWARD_PERIOD_NOT_EXISTS");
    }

    function endsBefore(RewardPeriod storage self, uint256 startPeriodTimestamp)
        internal
        view
        returns (bool)
    {
        return self.exists && self.endPeriodTimestamp < startPeriodTimestamp;
    }

    function notifyRewardsSent(RewardPeriod storage self, uint256 amount) internal returns (bool) {
        self.availableRewards = self.availableRewards.sub(amount);
    }

    /**
        @notice It removes a current reward period.
        @param self the current reward period to remove.
     */
    function remove(RewardPeriod storage self) internal {
        requireExists(self);
        self.id = 0;
        self.startPeriodTimestamp = 0;
        self.endPeriodTimestamp = 0;
        self.endRedeemablePeriodTimestamp = 0;
        self.totalRewards = 0;
        self.availableRewards = 0;
        self.exists = false;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "../libs/AddressesLib.sol";
import "../libs/RewardPeriodLib.sol";

// Contracts
import "../base/MigratorBase.sol";

// Interfaces
import "./IRewardPeriodsRegistry.sol";

contract RewardPeriodsRegistry is MigratorBase, IRewardPeriodsRegistry {
    using RewardPeriodLib for RewardPeriodLib.RewardPeriod;
    using AddressesLib for address[];
    using Address for address;

    /* State Variables */

    mapping(uint256 => RewardPeriodLib.RewardPeriod) internal periods;

    RewardPeriodLib.RewardPeriod[] public periodsList;

    /** Modifiers */

    /* Constructor */

    constructor(address settingsAddress) public MigratorBase(settingsAddress) {}

    function createRewardPeriod(
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    ) external override onlyOwner(msg.sender) {
        uint256 newPeriodId = 1;
        if (periodsList.length > 0) {
            RewardPeriodLib.RewardPeriod storage lastPeriod = _getLastRewardPeriod();
            require(!lastPeriod.isPending(), "ALREADY_PENDING_PERIOD_REWARD");

            if (lastPeriod.isInProgress()) {
                require(
                    lastPeriod.endsBefore(startPeriodTimestamp),
                    "IN_PROGRESS_PERIOD_OVERLAPPED"
                );
            }
            newPeriodId = lastPeriod.id + 1;
        }

        periods[newPeriodId].create(
            newPeriodId,
            startPeriodTimestamp,
            endPeriodTimestamp,
            endRedeemablePeriodTimestamp,
            availableRewards
        );
        periodsList.push(periods[newPeriodId]);

        emit RewardPeriodCreated(
            msg.sender,
            newPeriodId,
            startPeriodTimestamp,
            endPeriodTimestamp,
            endRedeemablePeriodTimestamp,
            availableRewards
        );
    }

    function notifyRewardsSent(uint256 period, uint256 totalRewardsSent)
        external
        override
        onlyMinter(msg.sender)
        returns (uint256 newTotalAvailableRewards)
    {
        periods[period].notifyRewardsSent(totalRewardsSent);
        return periods[period].availableRewards;
    }

    function getRewardPeriod(uint256 id)
        external
        view
        override
        returns (RewardPeriodLib.RewardPeriod memory)
    {
        return periods[id];
    }

    function getRewardPeriods()
        external
        view
        override
        returns (RewardPeriodLib.RewardPeriod[] memory)
    {
        return periodsList;
    }

    function getLastRewardPeriod()
        external
        view
        override
        returns (
            uint256 periodId,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        )
    {
        RewardPeriodLib.RewardPeriod memory rewardPeriod = _getLastRewardPeriod();
        return (
            rewardPeriod.id,
            rewardPeriod.startPeriodTimestamp,
            rewardPeriod.endPeriodTimestamp,
            rewardPeriod.endRedeemablePeriodTimestamp,
            rewardPeriod.totalRewards,
            rewardPeriod.availableRewards,
            rewardPeriod.exists
        );
    }

    function getRewardPeriodById(uint256 periodId)
        external
        view
        override
        returns (
            uint256 id,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        )
    {
        RewardPeriodLib.RewardPeriod memory rewardPeriod = _getRewardPeriodById(periodId);
        return (
            rewardPeriod.id,
            rewardPeriod.startPeriodTimestamp,
            rewardPeriod.endPeriodTimestamp,
            rewardPeriod.endRedeemablePeriodTimestamp,
            rewardPeriod.totalRewards,
            rewardPeriod.availableRewards,
            rewardPeriod.exists
        );
    }

    function settings() external view override returns (address) {
        return address(_settings());
    }

    /** Internal Functions */

    function _getLastRewardPeriod() internal view returns (RewardPeriodLib.RewardPeriod storage) {
        return periodsList.length > 0 ? periodsList[periodsList.length - 1] : periods[0];
    }

    function _getRewardPeriodById(uint256 periodId)
        internal
        view
        returns (RewardPeriodLib.RewardPeriod storage)
    {
        return periods[periodId];
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library AccountRewardsLib {
    using Address for address;
    using SafeMath for uint256;

    struct AccountRewards {
        address account;
        uint256 amount;
        uint256 available;
        bool exists;
    }

    function create(
        AccountRewards storage self,
        address account,
        uint256 amount
    ) internal {
        requireNotExists(self);
        require(amount > 0, "AMOUNT_MUST_BE_GT_ZERO");
        self.account = account;
        self.amount = amount;
        self.available = amount;
        self.exists = true;
    }

    function increaseAmount(AccountRewards storage self, uint256 amount) internal {
        requireExists(self);
        require(amount > 0, "AMOUNT_MUST_BE_GT_ZERO");
        self.amount = self.amount.add(amount);
        self.available = self.available.add(amount);
    }

    function decreaseAmount(AccountRewards storage self, uint256 amount) internal {
        requireExists(self);
        require(amount > 0, "AMOUNT_MUST_BE_GT_ZERO");
        self.amount = self.amount.sub(amount);
        self.available = self.available.sub(amount);
    }

    function claimRewards(AccountRewards storage self, uint256 amount) internal {
        self.available = self.available.sub(amount);
    }

    /* View Functions */

    /**
        @notice Checks whether the current account rewards exists or not.
        @dev It throws a require error if the account rewards already exists.
        @param self the current account rewards.
     */
    function requireNotExists(AccountRewards storage self) internal view {
        require(!self.exists, "ACCOUNT_REWARD_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current account rewards exists or not.
        @dev It throws a require error if the current account rewards doesn't exist.
        @param self the current account rewards.
     */
    function requireExists(AccountRewards storage self) internal view {
        require(self.exists, "ACCOUNT_REWARD_NOT_EXISTS");
    }

    /**
        @notice It removes a current account rewards.
        @param self the current account rewards to remove.
     */
    function remove(AccountRewards storage self) internal {
        requireExists(self);
        self.amount = 0;
        self.available = 0;
        self.account = address(0x0);
        self.exists = false;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Contracts
import "../base/Base.sol";
import "./RewardsCalculatorBase.sol";

// Libraries
import "../libs/AccountRewardsLib.sol";

// Interfaces
import "./IRewardsCalculator.sol";

contract ManualPGURewardsCalculator is Base, RewardsCalculatorBase, IRewardsCalculator {
    using AccountRewardsLib for AccountRewardsLib.AccountRewards;

    /* Events */

    event ManualRewardsUpdated(
        address indexed updater,
        uint256 period,
        address account,
        uint256 amount
    );

    /* State Variables */
    mapping(uint256 => mapping(address => AccountRewardsLib.AccountRewards)) private rewards;

    /* Constructor */

    constructor(address settingsAddress, address rewardsMinterAddress)
        public
        Base(settingsAddress)
    {
        _setRewardsMinter(rewardsMinterAddress);
    }

    function setMultiRewardsForPeriod(
        uint256 rewardsPeriod,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyOwner(msg.sender) {
        require(accounts.length == amounts.length, "ARRAY_LENGTHS_NOT_EQUAL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _setRewardsForPeriod(rewardsPeriod, accounts[i], amounts[i]);
        }
    }

    function removeMultiRewardsForPeriod(uint256 rewardsPeriod, address[] calldata accounts)
        external
        onlyOwner(msg.sender)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _removeRewardsForPeriod(rewardsPeriod, accounts[i]);
        }
    }

    function processRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external override onlyRewardsMinter(msg.sender) returns (uint256 rewardsForAccount) {
        rewardsForAccount = _getRewards(period, account, totalRewards, totalAvailableRewards);
        if (rewardsForAccount > 0) {
            rewards[period][account].claimRewards(rewardsForAccount);
        }
    }

    /* View Functions */

    function getRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external view override returns (uint256) {
        return _getRewards(period, account, totalRewards, totalAvailableRewards);
    }

    function getAccountRewardsFor(uint256 period, address account)
        external
        view
        returns (AccountRewardsLib.AccountRewards memory)
    {
        return rewards[period][account];
    }

    /* Internal Functions */

    function _getRewards(
        uint256 period,
        address account,
        uint256,
        uint256 totalAvailableRewards
    ) internal view returns (uint256 rewardsForAccount) {
        rewardsForAccount = rewards[period][account].available;
        require(totalAvailableRewards >= rewardsForAccount, "NOT_ENOUGH_TOTAL_AVAILAB_REWARDS");
    }

    function _setRewardsForPeriod(
        uint256 rewardsPeriod,
        address account,
        uint256 amount
    ) internal {
        rewards[rewardsPeriod][account].create(account, amount);

        emit ManualRewardsUpdated(msg.sender, rewardsPeriod, account, amount);
    }

    function _removeRewardsForPeriod(uint256 rewardsPeriod, address account) internal {
        rewards[rewardsPeriod][account].remove();

        emit ManualRewardsUpdated(msg.sender, rewardsPeriod, account, 0);
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "../../libs/AddressesLib.sol";

contract AddressesLibMock {
    using AddressesLib for address[];

    address[] public result;

    constructor(address[] memory initialData) public {
        result = initialData;
    }

    function getResult() external view returns (address[] memory) {
        return result;
    }

    function add(address newItem) external {
        result.add(newItem);
    }

    function removeAt(uint256 indexAt) external {
        result.removeAt(indexAt);
    }

    function getIndex(address item) external view returns (bool found, uint256 indexAt) {
        return result.getIndex(item);
    }

    function remove(address item) external {
        result.remove(item);
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "./ITokensRegistry.sol";

contract TokensRegistry is ITokensRegistry {
    using Address for address;

    mapping(address => bool) allowedTokens;

    function addToken(address token) external override {
        require(token.isContract(), "TOKEN_MUST_BE_CONTRACT");

        allowedTokens[token] = true;

        emit TokenAdded(msg.sender, token);
    }

    function removeToken(address token) external override {
        allowedTokens[token] = false;

        emit TokenRemoved(msg.sender, token);
    }

    function hasToken(address token) external view override returns (bool) {
        return allowedTokens[token];
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface ITokensRegistry {
    event TokenAdded(address indexed adder, address indexed token);

    event TokenRemoved(address indexed remover, address indexed token);

    function addToken(address token) external;

    function removeToken(address token) external;

    function hasToken(address token) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}