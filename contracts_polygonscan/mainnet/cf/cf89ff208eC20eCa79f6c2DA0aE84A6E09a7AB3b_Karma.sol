// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// openzeppelin stuff
import "ERC20.sol";
import "ERC1967Upgrade.sol";
import "Ownable.sol";
import "BancorFormula.sol";

contract Karma is ERC20, Ownable, ERC1967Upgrade, BancorFormula {

    uint32 private reserveRatio = 500000;
    uint256 private supply = 1e18;
    uint256 private collateral = 1e18;

    constructor()
    ERC20("Good Karma Token", "KRM")
    {
        init();
    }

    function buy()
    public
    payable
    returns (uint256)
    {
        uint256 amount = msg.value;
        uint256 amountToken = purchaseTargetAmount(
            supply,
            collateral,
            reserveRatio,
            amount
        );

        _mint(msg.sender, amountToken);
        collateral = collateral + amount;
        supply = supply + amountToken;

        return amountToken;
    }

    function sell(uint256 amount)
    public
    returns (uint256)
    {
        require(balanceOf(msg.sender) >= amount);
        uint256 amountCollateral = saleTargetAmount(
            supply,
            collateral,
            reserveRatio,
            amount
        );

        _burn(msg.sender, amount);
        (bool succeed, bytes memory data) = payable(msg.sender).call{value : amountCollateral}("");


        supply = supply - amount;
        collateral = collateral - amountCollateral;
        return amountCollateral;
    }

    function upgrade(address newImplementation, bytes memory data)
    external
    onlyOwner
    {
        _upgradeToAndCall(newImplementation, data, true);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "IBeacon.sol";
import "Address.sol";
import "StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeMath.sol";

contract BancorFormula{
    using SafeMath for uint256;

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    // Auto-generated via 'PrintIntScalingFactors.py'
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    // Auto-generated via 'PrintLn2ScalingFactors.py'
    uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    // Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    // Auto-generated via 'PrintLambertFactors.py'
    uint256 private constant LAMBERT_CONV_RADIUS = 0x002f16ac6c59de6f8d5d6f63c1482a7c86;
    uint256 private constant LAMBERT_POS2_SAMPLE = 0x0003060c183060c183060c183060c18306;
    uint256 private constant LAMBERT_POS2_MAXVAL = 0x01af16ac6c59de6f8d5d6f63c1482a7c80;
    uint256 private constant LAMBERT_POS3_MAXVAL = 0x6b22d43e72c326539cceeef8bb48f255ff;

    // Auto-generated via 'PrintWeightFactors.py'
    uint256 private constant MAX_UNF_WEIGHT = 0x10c6f7a0b5ed8d36b4c7f34938583621fafc8b0079a2834d26fa3fcc9ea9;

    // Auto-generated via 'PrintMaxExpArray.py'
    uint256[128] private maxExpArray;

    function initMaxExpArray() private {
        //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    // Auto-generated via 'PrintLambertArray.py'
    uint256[128] private lambertArray;

    function initLambertArray() private {
        lambertArray[0] = 0x60e393c68d20b1bd09deaabc0373b9c5;
        lambertArray[1] = 0x5f8f46e4854120989ed94719fb4c2011;
        lambertArray[2] = 0x5e479ebb9129fb1b7e72a648f992b606;
        lambertArray[3] = 0x5d0bd23fe42dfedde2e9586be12b85fe;
        lambertArray[4] = 0x5bdb29ddee979308ddfca81aeeb8095a;
        lambertArray[5] = 0x5ab4fd8a260d2c7e2c0d2afcf0009dad;
        lambertArray[6] = 0x5998b31359a55d48724c65cf09001221;
        lambertArray[7] = 0x5885bcad2b322dfc43e8860f9c018cf5;
        lambertArray[8] = 0x577b97aa1fe222bb452fdf111b1f0be2;
        lambertArray[9] = 0x5679cb5e3575632e5baa27e2b949f704;
        lambertArray[10] = 0x557fe8241b3a31c83c732f1cdff4a1c5;
        lambertArray[11] = 0x548d868026504875d6e59bbe95fc2a6b;
        lambertArray[12] = 0x53a2465ce347cf34d05a867c17dd3088;
        lambertArray[13] = 0x52bdce5dcd4faed59c7f5511cf8f8acc;
        lambertArray[14] = 0x51dfcb453c07f8da817606e7885f7c3e;
        lambertArray[15] = 0x5107ef6b0a5a2be8f8ff15590daa3cce;
        lambertArray[16] = 0x5035f241d6eae0cd7bacba119993de7b;
        lambertArray[17] = 0x4f698fe90d5b53d532171e1210164c66;
        lambertArray[18] = 0x4ea288ca297a0e6a09a0eee240e16c85;
        lambertArray[19] = 0x4de0a13fdcf5d4213fc398ba6e3becde;
        lambertArray[20] = 0x4d23a145eef91fec06b06140804c4808;
        lambertArray[21] = 0x4c6b5430d4c1ee5526473db4ae0f11de;
        lambertArray[22] = 0x4bb7886c240562eba11f4963a53b4240;
        lambertArray[23] = 0x4b080f3f1cb491d2d521e0ea4583521e;
        lambertArray[24] = 0x4a5cbc96a05589cb4d86be1db3168364;
        lambertArray[25] = 0x49b566d40243517658d78c33162d6ece;
        lambertArray[26] = 0x4911e6a02e5507a30f947383fd9a3276;
        lambertArray[27] = 0x487216c2b31be4adc41db8a8d5cc0c88;
        lambertArray[28] = 0x47d5d3fc4a7a1b188cd3d788b5c5e9fc;
        lambertArray[29] = 0x473cfce4871a2c40bc4f9e1c32b955d0;
        lambertArray[30] = 0x46a771ca578ab878485810e285e31c67;
        lambertArray[31] = 0x4615149718aed4c258c373dc676aa72d;
        lambertArray[32] = 0x4585c8b3f8fe489c6e1833ca47871384;
        lambertArray[33] = 0x44f972f174e41e5efb7e9d63c29ce735;
        lambertArray[34] = 0x446ff970ba86d8b00beb05ecebf3c4dc;
        lambertArray[35] = 0x43e9438ec88971812d6f198b5ccaad96;
        lambertArray[36] = 0x436539d11ff7bea657aeddb394e809ef;
        lambertArray[37] = 0x42e3c5d3e5a913401d86f66db5d81c2c;
        lambertArray[38] = 0x4264d2395303070ea726cbe98df62174;
        lambertArray[39] = 0x41e84a9a593bb7194c3a6349ecae4eea;
        lambertArray[40] = 0x416e1b785d13eba07a08f3f18876a5ab;
        lambertArray[41] = 0x40f6322ff389d423ba9dd7e7e7b7e809;
        lambertArray[42] = 0x40807cec8a466880ecf4184545d240a4;
        lambertArray[43] = 0x400cea9ce88a8d3ae668e8ea0d9bf07f;
        lambertArray[44] = 0x3f9b6ae8772d4c55091e0ed7dfea0ac1;
        lambertArray[45] = 0x3f2bee253fd84594f54bcaafac383a13;
        lambertArray[46] = 0x3ebe654e95208bb9210c575c081c5958;
        lambertArray[47] = 0x3e52c1fc5665635b78ce1f05ad53c086;
        lambertArray[48] = 0x3de8f65ac388101ddf718a6f5c1eff65;
        lambertArray[49] = 0x3d80f522d59bd0b328ca012df4cd2d49;
        lambertArray[50] = 0x3d1ab193129ea72b23648a161163a85a;
        lambertArray[51] = 0x3cb61f68d32576c135b95cfb53f76d75;
        lambertArray[52] = 0x3c5332d9f1aae851a3619e77e4cc8473;
        lambertArray[53] = 0x3bf1e08edbe2aa109e1525f65759ef73;
        lambertArray[54] = 0x3b921d9cff13fa2c197746a3dfc4918f;
        lambertArray[55] = 0x3b33df818910bfc1a5aefb8f63ae2ac4;
        lambertArray[56] = 0x3ad71c1c77e34fa32a9f184967eccbf6;
        lambertArray[57] = 0x3a7bc9abf2c5bb53e2f7384a8a16521a;
        lambertArray[58] = 0x3a21dec7e76369783a68a0c6385a1c57;
        lambertArray[59] = 0x39c9525de6c9cdf7c1c157ca4a7a6ee3;
        lambertArray[60] = 0x39721bad3dc85d1240ff0190e0adaac3;
        lambertArray[61] = 0x391c324344d3248f0469eb28dd3d77e0;
        lambertArray[62] = 0x38c78df7e3c796279fb4ff84394ab3da;
        lambertArray[63] = 0x387426ea4638ae9aae08049d3554c20a;
        lambertArray[64] = 0x3821f57dbd2763256c1a99bbd2051378;
        lambertArray[65] = 0x37d0f256cb46a8c92ff62fbbef289698;
        lambertArray[66] = 0x37811658591ffc7abdd1feaf3cef9b73;
        lambertArray[67] = 0x37325aa10e9e82f7df0f380f7997154b;
        lambertArray[68] = 0x36e4b888cfb408d873b9a80d439311c6;
        lambertArray[69] = 0x3698299e59f4bb9de645fc9b08c64cca;
        lambertArray[70] = 0x364ca7a5012cb603023b57dd3ebfd50d;
        lambertArray[71] = 0x36022c928915b778ab1b06aaee7e61d4;
        lambertArray[72] = 0x35b8b28d1a73dc27500ffe35559cc028;
        lambertArray[73] = 0x357033e951fe250ec5eb4e60955132d7;
        lambertArray[74] = 0x3528ab2867934e3a21b5412e4c4f8881;
        lambertArray[75] = 0x34e212f66c55057f9676c80094a61d59;
        lambertArray[76] = 0x349c66289e5b3c4b540c24f42fa4b9bb;
        lambertArray[77] = 0x34579fbbd0c733a9c8d6af6b0f7d00f7;
        lambertArray[78] = 0x3413bad2e712288b924b5882b5b369bf;
        lambertArray[79] = 0x33d0b2b56286510ef730e213f71f12e9;
        lambertArray[80] = 0x338e82ce00e2496262c64457535ba1a1;
        lambertArray[81] = 0x334d26a96b373bb7c2f8ea1827f27a92;
        lambertArray[82] = 0x330c99f4f4211469e00b3e18c31475ea;
        lambertArray[83] = 0x32ccd87d6486094999c7d5e6f33237d8;
        lambertArray[84] = 0x328dde2dd617b6665a2e8556f250c1af;
        lambertArray[85] = 0x324fa70e9adc270f8262755af5a99af9;
        lambertArray[86] = 0x32122f443110611ca51040f41fa6e1e3;
        lambertArray[87] = 0x31d5730e42c0831482f0f1485c4263d8;
        lambertArray[88] = 0x31996ec6b07b4a83421b5ebc4ab4e1f1;
        lambertArray[89] = 0x315e1ee0a68ff46bb43ec2b85032e876;
        lambertArray[90] = 0x31237fe7bc4deacf6775b9efa1a145f8;
        lambertArray[91] = 0x30e98e7f1cc5a356e44627a6972ea2ff;
        lambertArray[92] = 0x30b04760b8917ec74205a3002650ec05;
        lambertArray[93] = 0x3077a75c803468e9132ce0cf3224241d;
        lambertArray[94] = 0x303fab57a6a275c36f19cda9bace667a;
        lambertArray[95] = 0x3008504beb8dcbd2cf3bc1f6d5a064f0;
        lambertArray[96] = 0x2fd19346ed17dac61219ce0c2c5ac4b0;
        lambertArray[97] = 0x2f9b7169808c324b5852fd3d54ba9714;
        lambertArray[98] = 0x2f65e7e711cf4b064eea9c08cbdad574;
        lambertArray[99] = 0x2f30f405093042ddff8a251b6bf6d103;
        lambertArray[100] = 0x2efc931a3750f2e8bfe323edfe037574;
        lambertArray[101] = 0x2ec8c28e46dbe56d98685278339400cb;
        lambertArray[102] = 0x2e957fd933c3926d8a599b602379b851;
        lambertArray[103] = 0x2e62c882c7c9ed4473412702f08ba0e5;
        lambertArray[104] = 0x2e309a221c12ba361e3ed695167feee2;
        lambertArray[105] = 0x2dfef25d1f865ae18dd07cfea4bcea10;
        lambertArray[106] = 0x2dcdcee821cdc80decc02c44344aeb31;
        lambertArray[107] = 0x2d9d2d8562b34944d0b201bb87260c83;
        lambertArray[108] = 0x2d6d0c04a5b62a2c42636308669b729a;
        lambertArray[109] = 0x2d3d6842c9a235517fc5a0332691528f;
        lambertArray[110] = 0x2d0e402963fe1ea2834abc408c437c10;
        lambertArray[111] = 0x2cdf91ae602647908aff975e4d6a2a8c;
        lambertArray[112] = 0x2cb15ad3a1eb65f6d74a75da09a1b6c5;
        lambertArray[113] = 0x2c8399a6ab8e9774d6fcff373d210727;
        lambertArray[114] = 0x2c564c4046f64edba6883ca06bbc4535;
        lambertArray[115] = 0x2c2970c431f952641e05cb493e23eed3;
        lambertArray[116] = 0x2bfd0560cd9eb14563bc7c0732856c18;
        lambertArray[117] = 0x2bd1084ed0332f7ff4150f9d0ef41a2c;
        lambertArray[118] = 0x2ba577d0fa1628b76d040b12a82492fb;
        lambertArray[119] = 0x2b7a5233cd21581e855e89dc2f1e8a92;
        lambertArray[120] = 0x2b4f95cd46904d05d72bdcde337d9cc7;
        lambertArray[121] = 0x2b2540fc9b4d9abba3faca6691914675;
        lambertArray[122] = 0x2afb5229f68d0830d8be8adb0a0db70f;
        lambertArray[123] = 0x2ad1c7c63a9b294c5bc73a3ba3ab7a2b;
        lambertArray[124] = 0x2aa8a04ac3cbe1ee1c9c86361465dbb8;
        lambertArray[125] = 0x2a7fda392d725a44a2c8aeb9ab35430d;
        lambertArray[126] = 0x2a57741b18cde618717792b4faa216db;
        lambertArray[127] = 0x2a2f6c81f5d84dd950a35626d6d5503a;
    }

    /**
     * @dev should be executed after construction (too large for the constructor)
     */
    function init() internal {
        initMaxExpArray();
        initLambertArray();
    }

    /**
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of reserve tokens to get the target amount for
     *
     * @return target
     */
    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT, "ERR_INVALID_RESERVE_WEIGHT");

        // special case for 0 deposit amount
        if (_amount == 0) return 0;

        // special case if the weight = 100%
        if (_reserveWeight == MAX_WEIGHT) return _supply.mul(_amount) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _amount.add(_reserveBalance);
        (result, precision) = power(baseN, _reserveBalance, _reserveWeight, MAX_WEIGHT);
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
     * calculates the target amount for a given conversion (in the reserve token)
     *
     * Formula:
     * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of liquid tokens to get the target amount for
     *
     * @return reserve token amount
     */
    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) internal view  returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT, "ERR_INVALID_RESERVE_WEIGHT");
        require(_amount <= _supply, "ERR_INVALID_AMOUNT");

        // special case for 0 sell amount
        if (_amount == 0) return 0;

        // special case for selling the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the weight = 100%
        if (_reserveWeight == MAX_WEIGHT) return _reserveBalance.mul(_amount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveWeight);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given two reserve balances/weights and a sell amount (in the first reserve token),
     * calculates the target amount for a conversion from the source reserve token to the target reserve token
     *
     * Formula:
     * return = _targetReserveBalance * (1 - (_sourceReserveBalance / (_sourceReserveBalance + _amount)) ^ (_sourceReserveWeight / _targetReserveWeight))
     *
     * @param _sourceReserveBalance    source reserve balance
     * @param _sourceReserveWeight     source reserve weight, represented in ppm (1-1000000)
     * @param _targetReserveBalance    target reserve balance
     * @param _targetReserveWeight     target reserve weight, represented in ppm (1-1000000)
     * @param _amount                  source reserve amount
     *
     * @return target reserve amount
     */
    function crossReserveTargetAmount(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) internal view  returns (uint256) {
        // validate input
        require(_sourceReserveBalance > 0 && _targetReserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(
            _sourceReserveWeight > 0 &&
            _sourceReserveWeight <= MAX_WEIGHT &&
            _targetReserveWeight > 0 &&
            _targetReserveWeight <= MAX_WEIGHT,
            "ERR_INVALID_RESERVE_WEIGHT"
        );

        // special case for equal weights
        if (_sourceReserveWeight == _targetReserveWeight)
            return _targetReserveBalance.mul(_amount) / _sourceReserveBalance.add(_amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = _sourceReserveBalance.add(_amount);
        (result, precision) = power(baseN, _sourceReserveBalance, _sourceReserveWeight, _targetReserveWeight);
        uint256 temp1 = _targetReserveBalance.mul(result);
        uint256 temp2 = _targetReserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of requested pool tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio) - 1)
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          requested amount of pool tokens
     *
     * @return reserve token amount
     */
    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) internal view  returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2, "ERR_INVALID_RESERVE_RATIO");

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT) return (_amount.mul(_reserveBalance) - 1) / _supply + 1;

        uint256 result;
        uint8 precision;
        uint256 baseN = _supply.add(_amount);
        (result, precision) = power(baseN, _supply, MAX_WEIGHT, _reserveRatio);
        uint256 temp = ((_reserveBalance.mul(result) - 1) >> precision) + 1;
        return temp - _reserveBalance;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of reserve tokens to fund with,
     * calculates the amount of pool tokens received for purchasing with the given amount of reserve tokens
     *
     * Formula:
     * return = _supply * ((_amount / _reserveBalance + 1) ^ (_reserveRatio / MAX_WEIGHT) - 1)
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          amount of reserve tokens to fund with
     *
     * @return pool token amount
     */
    function fundSupplyAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) internal view  returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2, "ERR_INVALID_RESERVE_RATIO");

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT) return _amount.mul(_supply) / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _reserveBalance.add(_amount);
        (result, precision) = power(baseN, _reserveBalance, _reserveRatio, MAX_WEIGHT);
        uint256 temp = _supply.mul(result) >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of pool tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio))
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          amount of pool tokens to liquidate
     *
     * @return reserve token amount
     */
    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) internal view  returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2, "ERR_INVALID_RESERVE_RATIO");
        require(_amount <= _supply, "ERR_INVALID_AMOUNT");

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case for liquidating the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT) return _amount.mul(_reserveBalance) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveRatio);
        uint256 temp1 = _reserveBalance.mul(result);
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
     * @dev The arbitrage incentive is to convert to the point where the on-chain price is equal to the off-chain price.
     * We want this operation to also impact the primary reserve balance becoming equal to the primary reserve staked balance.
     * In other words, we want the arbitrager to convert the difference between the reserve balance and the reserve staked balance.
     *
     * Formula input:
     * - let t denote the primary reserve token staked balance
     * - let s denote the primary reserve token balance
     * - let r denote the secondary reserve token balance
     * - let q denote the numerator of the rate between the tokens
     * - let p denote the denominator of the rate between the tokens
     * Where p primary tokens are equal to q secondary tokens
     *
     * Formula output:
     * - compute x = W(t / r * q / p * log(s / t)) / log(s / t)
     * - return x / (1 + x) as the weight of the primary reserve token
     * - return 1 / (1 + x) as the weight of the secondary reserve token
     * Where W is the Lambert W Function
     *
     * If the rate-provider provides the rates for a common unit, for example:
     * - P = 2 ==> 2 primary reserve tokens = 1 ether
     * - Q = 3 ==> 3 secondary reserve tokens = 1 ether
     * Then you can simply use p = P and q = Q
     *
     * If the rate-provider provides the rates for a single unit, for example:
     * - P = 2 ==> 1 primary reserve token = 2 ethers
     * - Q = 3 ==> 1 secondary reserve token = 3 ethers
     * Then you can simply use p = Q and q = P
     *
     * @param _primaryReserveStakedBalance the primary reserve token staked balance
     * @param _primaryReserveBalance       the primary reserve token balance
     * @param _secondaryReserveBalance     the secondary reserve token balance
     * @param _reserveRateNumerator        the numerator of the rate between the tokens
     * @param _reserveRateDenominator      the denominator of the rate between the tokens
     *
     * Note that `numerator / denominator` should represent the amount of secondary tokens equal to one primary token
     *
     * @return the weight of the primary reserve token and the weight of the secondary reserve token, both in ppm (0-1000000)
     */
    function balancedWeights(
        uint256 _primaryReserveStakedBalance,
        uint256 _primaryReserveBalance,
        uint256 _secondaryReserveBalance,
        uint256 _reserveRateNumerator,
        uint256 _reserveRateDenominator
    ) internal view  returns (uint32, uint32) {
        if (_primaryReserveStakedBalance == _primaryReserveBalance)
            require(_primaryReserveStakedBalance > 0 || _secondaryReserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        else
            require(
                _primaryReserveStakedBalance > 0 && _primaryReserveBalance > 0 && _secondaryReserveBalance > 0,
                "ERR_INVALID_RESERVE_BALANCE"
            );
        require(_reserveRateNumerator > 0 && _reserveRateDenominator > 0, "ERR_INVALID_RESERVE_RATE");

        uint256 tq = _primaryReserveStakedBalance.mul(_reserveRateNumerator);
        uint256 rp = _secondaryReserveBalance.mul(_reserveRateDenominator);

        if (_primaryReserveStakedBalance < _primaryReserveBalance)
            return balancedWeightsByStake(_primaryReserveBalance, _primaryReserveStakedBalance, tq, rp, true);

        if (_primaryReserveStakedBalance > _primaryReserveBalance)
            return balancedWeightsByStake(_primaryReserveStakedBalance, _primaryReserveBalance, tq, rp, false);

        return normalizedWeights(tq, rp);
    }

    /**
     * @dev General Description:
     *     Determine a value of precision.
     *     Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
     *     Return the result along with the precision used.
     *
     * Detailed Description:
     *     Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
     *     The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
     *     The larger "precision" is, the more accurately this value represents the real value.
     *     However, the larger "precision" is, the more bits are required in order to store this value.
     *     And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
     *     This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     *     Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     *     This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     *     This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
     *     Since we rely on unsigned-integer arithmetic and "base < 1" ==> "log(base) < 0", this function does not support "_baseN < _baseD".
     */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) internal view returns (uint256, uint8) {
        require(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = (_baseN * FIXED_1) / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = (baseLog * _expN) / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1.
     * This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }

    /**
     * @dev computes the largest integer smaller than or equal to the binary logarithm of the input.
     */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
     * @dev the global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x) lo = mid;
            else hi = mid;
        }

        if (maxExpArray[hi] >= _x) return hi;
        if (maxExpArray[lo] >= _x) return lo;

        require(false);
    }

    /**
     * @dev this function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
     * it approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
     * it returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
     * the global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
     * the maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
     * @dev computes log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {
            res += 0x40000000000000000000000000000000;
            x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd8;
        } // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {
            res += 0x20000000000000000000000000000000;
            x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a7;
        } // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {
            res += 0x10000000000000000000000000000000;
            x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a1;
        } // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {
            res += 0x08000000000000000000000000000000;
            x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a8;
        } // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {
            res += 0x04000000000000000000000000000000;
            x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd3;
        } // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {
            res += 0x02000000000000000000000000000000;
            x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a2;
        } // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {
            res += 0x01000000000000000000000000000000;
            x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e99;
        } // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {
            res += 0x00800000000000000000000000000000;
            x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f733;
        } // add 1 / 2^8

        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        res += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * @dev computes e ^ (x / FIXED_1) * FIXED_1
     * input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     */
    function lowerStake(uint256 _x) internal view returns (uint256) {
        if (_x <= LAMBERT_CONV_RADIUS) return lambertPos1(_x);
        if (_x <= LAMBERT_POS2_MAXVAL) return lambertPos2(_x);
        if (_x <= LAMBERT_POS3_MAXVAL) return lambertPos3(_x);
        require(false);
    }

    /**
     * @dev computes W(-x / FIXED_1) / (-x / FIXED_1) * FIXED_1
     */
    function higherStake(uint256 _x) internal pure returns (uint256) {
        if (_x <= LAMBERT_CONV_RADIUS) return lambertNeg1(_x);
        return (FIXED_1 * FIXED_1) / _x;
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     * input range: 1 <= x <= 1 / e * FIXED_1
     * auto-generated via 'PrintFunctionLambertPos1.py'
     */
    function lambertPos1(uint256 _x) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = (FIXED_1 - _x) * 0xde1bc4d19efcac82445da75b00000000; // x^(1-1) * (34! * 1^(1-1) / 1!) - x^(2-1) * (34! * 2^(2-1) / 2!)

        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000014d29a73a6e7b02c3668c7b0880000000; // add x^(03-1) * (34! * 03^(03-1) / 03!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000000002504a0cd9a7f7215b60f9be4800000000; // sub x^(04-1) * (34! * 04^(04-1) / 04!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000000484d0a1191c0ead267967c7a4a0000000; // add x^(05-1) * (34! * 05^(05-1) / 05!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00000000095ec580d7e8427a4baf26a90a00000000; // sub x^(06-1) * (34! * 06^(06-1) / 06!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000001440b0be1615a47dba6e5b3b1f10000000; // add x^(07-1) * (34! * 07^(07-1) / 07!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x000000002d207601f46a99b4112418400000000000; // sub x^(08-1) * (34! * 08^(08-1) / 08!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000066ebaac4c37c622dd8288a7eb1b2000000; // add x^(09-1) * (34! * 09^(09-1) / 09!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00000000ef17240135f7dbd43a1ba10cf200000000; // sub x^(10-1) * (34! * 10^(10-1) / 10!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000233c33c676a5eb2416094a87b3657000000; // add x^(11-1) * (34! * 11^(11-1) / 11!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000000541cde48bc0254bed49a9f8700000000000; // sub x^(12-1) * (34! * 12^(12-1) / 12!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000cae1fad2cdd4d4cb8d73abca0d19a400000; // add x^(13-1) * (34! * 13^(13-1) / 13!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000001edb2aa2f760d15c41ceedba956400000000; // sub x^(14-1) * (34! * 14^(14-1) / 14!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000004ba8d20d2dabd386c9529659841a2e200000; // add x^(15-1) * (34! * 15^(15-1) / 15!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x000000bac08546b867cdaa20000000000000000000; // sub x^(16-1) * (34! * 16^(16-1) / 16!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000001cfa8e70c03625b9db76c8ebf5bbf24820000; // add x^(17-1) * (34! * 17^(17-1) / 17!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x000004851d99f82060df265f3309b26f8200000000; // sub x^(18-1) * (34! * 18^(18-1) / 18!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000b550d19b129d270c44f6f55f027723cbb0000; // add x^(19-1) * (34! * 19^(19-1) / 19!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00001c877dadc761dc272deb65d4b0000000000000; // sub x^(20-1) * (34! * 20^(20-1) / 20!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000048178ece97479f33a77f2ad22a81b64406c000; // add x^(21-1) * (34! * 21^(21-1) / 21!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0000b6ca8268b9d810fedf6695ef2f8a6c00000000; // sub x^(22-1) * (34! * 22^(22-1) / 22!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0001d0e76631a5b05d007b8cb72a7c7f11ec36e000; // add x^(23-1) * (34! * 23^(23-1) / 23!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x0004a1c37bd9f85fd9c6c780000000000000000000; // sub x^(24-1) * (34! * 24^(24-1) / 24!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000bd8369f1b702bf491e2ebfcee08250313b65400; // add x^(25-1) * (34! * 25^(25-1) / 25!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x001e5c7c32a9f6c70ab2cb59d9225764d400000000; // sub x^(26-1) * (34! * 26^(26-1) / 26!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x004dff5820e165e910f95120a708e742496221e600; // add x^(27-1) * (34! * 27^(27-1) / 27!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x00c8c8f66db1fced378ee50e536000000000000000; // sub x^(28-1) * (34! * 28^(28-1) / 28!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0205db8dffff45bfa2938f128f599dbf16eb11d880; // add x^(29-1) * (34! * 29^(29-1) / 29!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x053a044ebd984351493e1786af38d39a0800000000; // sub x^(30-1) * (34! * 30^(30-1) / 30!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0d86dae2a4cc0f47633a544479735869b487b59c40; // add x^(31-1) * (34! * 31^(31-1) / 31!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0x231000000000000000000000000000000000000000; // sub x^(32-1) * (34! * 32^(32-1) / 32!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x5b0485a76f6646c2039db1507cdd51b08649680822; // add x^(33-1) * (34! * 33^(33-1) / 33!)
        xi = (xi * _x) / FIXED_1;
        res -= xi * 0xec983c46c49545bc17efa6b5b0055e242200000000; // sub x^(34-1) * (34! * 34^(34-1) / 34!)

        return res / 0xde1bc4d19efcac82445da75b00000000; // divide by 34!
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     * input range: LAMBERT_CONV_RADIUS + 1 <= x <= LAMBERT_POS2_MAXVAL
     */
    function lambertPos2(uint256 _x) internal view returns (uint256) {
        uint256 x = _x - LAMBERT_CONV_RADIUS - 1;
        uint256 i = x / LAMBERT_POS2_SAMPLE;
        uint256 a = LAMBERT_POS2_SAMPLE * i;
        uint256 b = LAMBERT_POS2_SAMPLE * (i + 1);
        uint256 c = lambertArray[i];
        uint256 d = lambertArray[i + 1];
        return (c * (b - x) + d * (x - a)) / LAMBERT_POS2_SAMPLE;
    }

    /**
     * @dev computes W(x / FIXED_1) / (x / FIXED_1) * FIXED_1
     * input range: LAMBERT_POS2_MAXVAL + 1 <= x <= LAMBERT_POS3_MAXVAL
     */
    function lambertPos3(uint256 _x) internal pure returns (uint256) {
        uint256 l1 = _x < OPT_LOG_MAX_VAL ? optimalLog(_x) : generalLog(_x);
        uint256 l2 = l1 < OPT_LOG_MAX_VAL ? optimalLog(l1) : generalLog(l1);
        return ((l1 - l2 + (l2 * FIXED_1) / l1) * FIXED_1) / _x;
    }

    /**
     * @dev computes W(-x / FIXED_1) / (-x / FIXED_1) * FIXED_1
     * input range: 1 <= x <= 1 / e * FIXED_1
     * auto-generated via 'PrintFunctionLambertNeg1.py'
     */
    function lambertNeg1(uint256 _x) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000014d29a73a6e7b02c3668c7b0880000000; // add x^(03-1) * (34! * 03^(03-1) / 03!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000002504a0cd9a7f7215b60f9be4800000000; // add x^(04-1) * (34! * 04^(04-1) / 04!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000000484d0a1191c0ead267967c7a4a0000000; // add x^(05-1) * (34! * 05^(05-1) / 05!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000095ec580d7e8427a4baf26a90a00000000; // add x^(06-1) * (34! * 06^(06-1) / 06!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000001440b0be1615a47dba6e5b3b1f10000000; // add x^(07-1) * (34! * 07^(07-1) / 07!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000002d207601f46a99b4112418400000000000; // add x^(08-1) * (34! * 08^(08-1) / 08!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000066ebaac4c37c622dd8288a7eb1b2000000; // add x^(09-1) * (34! * 09^(09-1) / 09!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000000ef17240135f7dbd43a1ba10cf200000000; // add x^(10-1) * (34! * 10^(10-1) / 10!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000233c33c676a5eb2416094a87b3657000000; // add x^(11-1) * (34! * 11^(11-1) / 11!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000541cde48bc0254bed49a9f8700000000000; // add x^(12-1) * (34! * 12^(12-1) / 12!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000000cae1fad2cdd4d4cb8d73abca0d19a400000; // add x^(13-1) * (34! * 13^(13-1) / 13!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000001edb2aa2f760d15c41ceedba956400000000; // add x^(14-1) * (34! * 14^(14-1) / 14!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000004ba8d20d2dabd386c9529659841a2e200000; // add x^(15-1) * (34! * 15^(15-1) / 15!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000000bac08546b867cdaa20000000000000000000; // add x^(16-1) * (34! * 16^(16-1) / 16!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000001cfa8e70c03625b9db76c8ebf5bbf24820000; // add x^(17-1) * (34! * 17^(17-1) / 17!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000004851d99f82060df265f3309b26f8200000000; // add x^(18-1) * (34! * 18^(18-1) / 18!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00000b550d19b129d270c44f6f55f027723cbb0000; // add x^(19-1) * (34! * 19^(19-1) / 19!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00001c877dadc761dc272deb65d4b0000000000000; // add x^(20-1) * (34! * 20^(20-1) / 20!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000048178ece97479f33a77f2ad22a81b64406c000; // add x^(21-1) * (34! * 21^(21-1) / 21!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0000b6ca8268b9d810fedf6695ef2f8a6c00000000; // add x^(22-1) * (34! * 22^(22-1) / 22!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0001d0e76631a5b05d007b8cb72a7c7f11ec36e000; // add x^(23-1) * (34! * 23^(23-1) / 23!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0004a1c37bd9f85fd9c6c780000000000000000000; // add x^(24-1) * (34! * 24^(24-1) / 24!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x000bd8369f1b702bf491e2ebfcee08250313b65400; // add x^(25-1) * (34! * 25^(25-1) / 25!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x001e5c7c32a9f6c70ab2cb59d9225764d400000000; // add x^(26-1) * (34! * 26^(26-1) / 26!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x004dff5820e165e910f95120a708e742496221e600; // add x^(27-1) * (34! * 27^(27-1) / 27!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x00c8c8f66db1fced378ee50e536000000000000000; // add x^(28-1) * (34! * 28^(28-1) / 28!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0205db8dffff45bfa2938f128f599dbf16eb11d880; // add x^(29-1) * (34! * 29^(29-1) / 29!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x053a044ebd984351493e1786af38d39a0800000000; // add x^(30-1) * (34! * 30^(30-1) / 30!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x0d86dae2a4cc0f47633a544479735869b487b59c40; // add x^(31-1) * (34! * 31^(31-1) / 31!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x231000000000000000000000000000000000000000; // add x^(32-1) * (34! * 32^(32-1) / 32!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0x5b0485a76f6646c2039db1507cdd51b08649680822; // add x^(33-1) * (34! * 33^(33-1) / 33!)
        xi = (xi * _x) / FIXED_1;
        res += xi * 0xec983c46c49545bc17efa6b5b0055e242200000000; // add x^(34-1) * (34! * 34^(34-1) / 34!)

        return res / 0xde1bc4d19efcac82445da75b00000000 + _x + FIXED_1; // divide by 34! and then add x^(2-1) * (34! * 2^(2-1) / 2!) + x^(1-1) * (34! * 1^(1-1) / 1!)
    }

    /**
     * @dev computes the weights based on "W(log(hi / lo) * tq / rp) * tq / rp", where "W" is a variation of the Lambert W function.
     */
    function balancedWeightsByStake(
        uint256 _hi,
        uint256 _lo,
        uint256 _tq,
        uint256 _rp,
        bool _lowerStake
    ) internal view returns (uint32, uint32) {
        (_tq, _rp) = safeFactors(_tq, _rp);
        uint256 f = _hi.mul(FIXED_1) / _lo;
        uint256 g = f < OPT_LOG_MAX_VAL ? optimalLog(f) : generalLog(f);
        uint256 x = g.mul(_tq) / _rp;
        uint256 y = _lowerStake ? lowerStake(x) : higherStake(x);
        return normalizedWeights(y.mul(_tq), _rp.mul(FIXED_1));
    }

    /**
     * @dev reduces "a" and "b" while maintaining their ratio.
     */
    function safeFactors(uint256 _a, uint256 _b) internal pure returns (uint256, uint256) {
        if (_a <= FIXED_2 && _b <= FIXED_2) return (_a, _b);
        if (_a < FIXED_2) return ((_a * FIXED_2) / _b, FIXED_2);
        if (_b < FIXED_2) return (FIXED_2, (_b * FIXED_2) / _a);
        uint256 c = _a > _b ? _a : _b;
        uint256 n = floorLog2(c / FIXED_1);
        return (_a >> n, _b >> n);
    }

    /**
     * @dev computes "MAX_WEIGHT * a / (a + b)" and "MAX_WEIGHT * b / (a + b)".
     */
    function normalizedWeights(uint256 _a, uint256 _b) internal pure returns (uint32, uint32) {
        if (_a <= _b) return accurateWeights(_a, _b);
        (uint32 y, uint32 x) = accurateWeights(_b, _a);
        return (x, y);
    }

    /**
     * @dev computes "MAX_WEIGHT * a / (a + b)" and "MAX_WEIGHT * b / (a + b)", assuming that "a <= b".
     */
    function accurateWeights(uint256 _a, uint256 _b) internal pure returns (uint32, uint32) {
        if (_a > MAX_UNF_WEIGHT) {
            uint256 c = _a / (MAX_UNF_WEIGHT + 1) + 1;
            _a /= c;
            _b /= c;
        }
        uint256 x = roundDiv(_a * MAX_WEIGHT, _a.add(_b));
        uint256 y = MAX_WEIGHT - x;
        return (uint32(x), uint32(y));
    }

    /**
     * @dev computes the nearest integer to a given quotient without overflowing or underflowing.
     */
    function roundDiv(uint256 _n, uint256 _d) internal pure returns (uint256) {
        return _n / _d + (_n % _d) / (_d - _d / 2);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return purchaseTargetAmount(_supply, _reserveBalance, _reserveWeight, _amount);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return saleTargetAmount(_supply, _reserveBalance, _reserveWeight, _amount);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateCrossReserveReturn(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return
        crossReserveTargetAmount(
            _sourceReserveBalance,
            _sourceReserveWeight,
            _targetReserveBalance,
            _targetReserveWeight,
            _amount
        );
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateCrossConnectorReturn(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return
        crossReserveTargetAmount(
            _sourceReserveBalance,
            _sourceReserveWeight,
            _targetReserveBalance,
            _targetReserveWeight,
            _amount
        );
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateFundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) internal view returns (uint256) {
        return fundCost(_supply, _reserveBalance, _reserveRatio, _amount);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function calculateLiquidateReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) internal view returns (uint256) {
        return liquidateReserveAmount(_supply, _reserveBalance, _reserveRatio, _amount);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function purchaseRate(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return purchaseTargetAmount(_supply, _reserveBalance, _reserveWeight, _amount);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function saleRate(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return saleTargetAmount(_supply, _reserveBalance, _reserveWeight, _amount);
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function crossReserveRate(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) internal view returns (uint256) {
        return
        crossReserveTargetAmount(
            _sourceReserveBalance,
            _sourceReserveWeight,
            _targetReserveBalance,
            _targetReserveWeight,
            _amount
        );
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function liquidateRate(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) internal view returns (uint256) {
        return liquidateReserveAmount(_supply, _reserveBalance, _reserveRatio, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}