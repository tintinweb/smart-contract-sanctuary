// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../release/extensions/integration-manager/integrations/utils/AdapterBase.sol";

/// @title IMockGenericIntegratee Interface
/// @author Enzyme Council <[email protected]>
interface IMockGenericIntegratee {
    function swap(
        address[] calldata,
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata
    ) external payable;

    function swapOnBehalf(
        address payable,
        address[] calldata,
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata
    ) external payable;
}

/// @title MockGenericAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Provides a generic adapter that:
/// 1. Provides swapping functions that use various `SpendAssetsTransferType` values
/// 2. Directly parses the _actual_ values to swap from provided call data (e.g., `actualIncomingAssetAmounts`)
/// 3. Directly parses values needed by the IntegrationManager from provided call data (e.g., `minIncomingAssetAmounts`)
contract MockGenericAdapter is AdapterBase {
    address public immutable INTEGRATEE;

    modifier fundAssetsTransferHandler(
        address _vaultProxy,
        bytes memory _assetData,
        IIntegrationManager.SpendAssetsHandleType _handleType
    ) {
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        // Take custody of spend assets (if necessary)
        if (_handleType == IIntegrationManager.SpendAssetsHandleType.Approve) {
            for (uint256 i; i < spendAssets.length; i++) {
                ERC20(spendAssets[i]).safeTransferFrom(
                    _vaultProxy,
                    address(this),
                    spendAssetAmounts[i]
                );
            }
        }

        // Execute call
        _;

        // Transfer remaining assets back to the fund's VaultProxy
        __pushFullAssetBalances(_vaultProxy, incomingAssets);
        __pushFullAssetBalances(_vaultProxy, spendAssets);
    }

    // No need to specify the IntegrationManager
    constructor(address _integratee) public AdapterBase(address(0)) {
        INTEGRATEE = _integratee;
    }

    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _callArgs
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory maxSpendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            spendAssets_,
            maxSpendAssetAmounts_,
            ,
            incomingAssets_,
            minIncomingAssetAmounts_,

        ) = __decodeCallArgs(_callArgs);

        return (
            __getSpendAssetsHandleTypeForSelector(_selector),
            spendAssets_,
            maxSpendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Assumes SpendAssetsHandleType.Transfer unless otherwise specified
    function __getSpendAssetsHandleTypeForSelector(bytes4 _selector)
        private
        pure
        returns (IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_)
    {
        if (_selector == bytes4(keccak256("swapDirectFromVault(address,bytes,bytes)"))) {
            return IIntegrationManager.SpendAssetsHandleType.None;
        }
        if (_selector == bytes4(keccak256("swapViaApproval(address,bytes,bytes)"))) {
            return IIntegrationManager.SpendAssetsHandleType.Approve;
        }
        return IIntegrationManager.SpendAssetsHandleType.Transfer;
    }

    function removeOnly(
        address,
        bytes calldata,
        bytes calldata
    ) external {}

    function swapA(
        address _vaultProxy,
        bytes calldata _callArgs,
        bytes calldata _assetTransferArgs
    )
        external
        fundAssetsTransferHandler(
            _vaultProxy,
            _assetTransferArgs,
            __getSpendAssetsHandleTypeForSelector(bytes4(keccak256("swapA(address,bytes,bytes)")))
        )
    {
        __decodeCallArgsAndSwap(_callArgs);
    }

    function swapB(
        address _vaultProxy,
        bytes calldata _callArgs,
        bytes calldata _assetTransferArgs
    )
        external
        fundAssetsTransferHandler(
            _vaultProxy,
            _assetTransferArgs,
            __getSpendAssetsHandleTypeForSelector(bytes4(keccak256("swapB(address,bytes,bytes)")))
        )
    {
        __decodeCallArgsAndSwap(_callArgs);
    }

    function swapDirectFromVault(
        address _vaultProxy,
        bytes calldata _callArgs,
        bytes calldata
    ) external {
        (
            address[] memory spendAssets,
            ,
            uint256[] memory actualSpendAssetAmounts,
            address[] memory incomingAssets,
            ,
            uint256[] memory actualIncomingAssetAmounts
        ) = __decodeCallArgs(_callArgs);

        IMockGenericIntegratee(INTEGRATEE).swapOnBehalf(
            payable(_vaultProxy),
            spendAssets,
            actualSpendAssetAmounts,
            incomingAssets,
            actualIncomingAssetAmounts
        );
    }

    function swapViaApproval(
        address _vaultProxy,
        bytes calldata _callArgs,
        bytes calldata _assetTransferArgs
    )
        external
        fundAssetsTransferHandler(
            _vaultProxy,
            _assetTransferArgs,
            __getSpendAssetsHandleTypeForSelector(
                bytes4(keccak256("swapViaApproval(address,bytes,bytes)"))
            )
        )
    {
        __decodeCallArgsAndSwap(_callArgs);
    }

    function __decodeCallArgs(bytes memory _callArgs)
        internal
        pure
        returns (
            address[] memory spendAssets_,
            uint256[] memory maxSpendAssetAmounts_,
            uint256[] memory actualSpendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_,
            uint256[] memory actualIncomingAssetAmounts_
        )
    {
        return
            abi.decode(
                _callArgs,
                (address[], uint256[], uint256[], address[], uint256[], uint256[])
            );
    }

    function __decodeCallArgsAndSwap(bytes memory _callArgs) internal {
        (
            address[] memory spendAssets,
            ,
            uint256[] memory actualSpendAssetAmounts,
            address[] memory incomingAssets,
            ,
            uint256[] memory actualIncomingAssetAmounts
        ) = __decodeCallArgs(_callArgs);

        for (uint256 i; i < spendAssets.length; i++) {
            ERC20(spendAssets[i]).approve(INTEGRATEE, actualSpendAssetAmounts[i]);
        }
        IMockGenericIntegratee(INTEGRATEE).swap(
            spendAssets,
            actualSpendAssetAmounts,
            incomingAssets,
            actualIncomingAssetAmounts
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../utils/AssetHelpers.sol";
import "../IIntegrationAdapter.sol";
import "./IntegrationSelectors.sol";

/// @title AdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract for integration adapters
abstract contract AdapterBase is IIntegrationAdapter, IntegrationSelectors, AssetHelpers {
    using SafeERC20 for ERC20;

    address internal immutable INTEGRATION_MANAGER;

    /// @dev Provides a standard implementation for transferring incoming assets
    /// from an adapter to a VaultProxy at the end of an adapter action
    modifier postActionIncomingAssetsTransferHandler(
        address _vaultProxy,
        bytes memory _assetData
    ) {
        _;

        (, , address[] memory incomingAssets) = __decodeAssetData(_assetData);

        __pushFullAssetBalances(_vaultProxy, incomingAssets);
    }

    /// @dev Provides a standard implementation for transferring unspent spend assets
    /// from an adapter to a VaultProxy at the end of an adapter action
    modifier postActionSpendAssetsTransferHandler(address _vaultProxy, bytes memory _assetData) {
        _;

        (address[] memory spendAssets, , ) = __decodeAssetData(_assetData);

        __pushFullAssetBalances(_vaultProxy, spendAssets);
    }

    modifier onlyIntegrationManager {
        require(
            msg.sender == INTEGRATION_MANAGER,
            "Only the IntegrationManager can call this function"
        );
        _;
    }

    constructor(address _integrationManager) public {
        INTEGRATION_MANAGER = _integrationManager;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to decode the _assetData param passed to adapter call
    function __decodeAssetData(bytes memory _assetData)
        internal
        pure
        returns (
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_
        )
    {
        return abi.decode(_assetData, (address[], uint256[], address[]));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `INTEGRATION_MANAGER` variable
    /// @return integrationManager_ The `INTEGRATION_MANAGER` variable value
    function getIntegrationManager() external view returns (address integrationManager_) {
        return INTEGRATION_MANAGER;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title AssetHelpers Contract
/// @author Enzyme Council <[email protected]>
/// @notice A util contract for common token actions
abstract contract AssetHelpers {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev Helper to approve a target account with the max amount of an asset.
    /// This is helpful for fully trusted contracts, such as adapters that
    /// interact with external protocol like Uniswap, Compound, etc.
    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        uint256 allowance = ERC20(_asset).allowance(address(this), _target);
        if (allowance < _neededAmount) {
            if (allowance > 0) {
                ERC20(_asset).safeApprove(_target, 0);
            }
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to transfer full asset balances from the current contract to a target
    function __pushFullAssetBalances(address _target, address[] memory _assets)
        internal
        returns (uint256[] memory amountsTransferred_)
    {
        amountsTransferred_ = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            ERC20 assetContract = ERC20(_assets[i]);
            amountsTransferred_[i] = assetContract.balanceOf(address(this));
            if (amountsTransferred_[i] > 0) {
                assetContract.safeTransfer(_target, amountsTransferred_[i]);
            }
        }

        return amountsTransferred_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../IIntegrationManager.sol";

/// @title Integration Adapter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all integration adapters
interface IIntegrationAdapter {
    function parseAssetsForAction(
        address _vaultProxy,
        bytes4 _selector,
        bytes calldata _encodedCallArgs
    )
        external
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IntegrationSelectors Contract
/// @author Enzyme Council <[email protected]>
/// @notice Selectors for integration actions
/// @dev Selectors are created from their signatures rather than hardcoded for easy verification
abstract contract IntegrationSelectors {
    // Trading
    bytes4 public constant TAKE_ORDER_SELECTOR = bytes4(
        keccak256("takeOrder(address,bytes,bytes)")
    );

    // Lending
    bytes4 public constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 public constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));

    // Staking
    bytes4 public constant STAKE_SELECTOR = bytes4(keccak256("stake(address,bytes,bytes)"));
    bytes4 public constant UNSTAKE_SELECTOR = bytes4(keccak256("unstake(address,bytes,bytes)"));

    // Rewards
    bytes4 public constant CLAIM_REWARDS_SELECTOR = bytes4(
        keccak256("claimRewards(address,bytes,bytes)")
    );

    // Combined
    bytes4 public constant LEND_AND_STAKE_SELECTOR = bytes4(
        keccak256("lendAndStake(address,bytes,bytes)")
    );
    bytes4 public constant UNSTAKE_AND_REDEEM_SELECTOR = bytes4(
        keccak256("unstakeAndRedeem(address,bytes,bytes)")
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IIntegrationManager interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the IntegrationManager
interface IIntegrationManager {
    enum SpendAssetsHandleType {None, Approve, Transfer}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../utils/actions/ZeroExV2ActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title ZeroExV2Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter to 0xV2 Exchange Contract
contract ZeroExV2Adapter is AdapterBase, FundDeployerOwnerMixin, ZeroExV2ActionsMixin {
    event AllowedMakerAdded(address indexed account);

    event AllowedMakerRemoved(address indexed account);

    mapping(address => bool) private makerToIsAllowed;

    // Gas could be optimized for the end-user by also storing an immutable ZRX_ASSET_DATA,
    // for example, but in the narrow OTC use-case of this adapter, taker fees are unlikely.
    constructor(
        address _integrationManager,
        address _exchange,
        address _fundDeployer,
        address[] memory _allowedMakers
    )
        public
        AdapterBase(_integrationManager)
        FundDeployerOwnerMixin(_fundDeployer)
        ZeroExV2ActionsMixin(_exchange)
    {
        if (_allowedMakers.length > 0) {
            __addAllowedMakers(_allowedMakers);
        }
    }

    // EXTERNAL FUNCTIONS

    /// @notice Take an order on 0x
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function takeOrder(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            bytes memory encodedZeroExOrderArgs,
            uint256 takerAssetFillAmount
        ) = __decodeTakeOrderCallArgs(_actionData);

        IZeroExV2.Order memory order = __constructOrderStruct(encodedZeroExOrderArgs);
        (, , , bytes memory signature) = __decodeZeroExOrderArgs(encodedZeroExOrderArgs);

        __zeroExV2TakeOrder(order, takerAssetFillAmount, signature);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForAction: _selector invalid");

        (
            bytes memory encodedZeroExOrderArgs,
            uint256 takerAssetFillAmount
        ) = __decodeTakeOrderCallArgs(_actionData);
        IZeroExV2.Order memory order = __constructOrderStruct(encodedZeroExOrderArgs);

        require(
            isAllowedMaker(order.makerAddress),
            "parseAssetsForAction: Order maker is not allowed"
        );
        require(
            takerAssetFillAmount <= order.takerAssetAmount,
            "parseAssetsForAction: Taker asset fill amount greater than available"
        );

        address makerAsset = __getAssetAddress(order.makerAssetData);
        address takerAsset = __getAssetAddress(order.takerAssetData);

        // Format incoming assets
        incomingAssets_ = new address[](1);
        incomingAssets_[0] = makerAsset;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = __calcRelativeQuantity(
            order.takerAssetAmount,
            order.makerAssetAmount,
            takerAssetFillAmount
        );

        if (order.takerFee > 0) {
            address takerFeeAsset = __getAssetAddress(
                IZeroExV2(getZeroExV2Exchange()).ZRX_ASSET_DATA()
            );
            uint256 takerFeeFillAmount = __calcRelativeQuantity(
                order.takerAssetAmount,
                order.takerFee,
                takerAssetFillAmount
            ); // fee calculated relative to taker fill amount

            if (takerFeeAsset == makerAsset) {
                require(
                    order.takerFee < order.makerAssetAmount,
                    "parseAssetsForAction: Fee greater than makerAssetAmount"
                );

                spendAssets_ = new address[](1);
                spendAssets_[0] = takerAsset;

                spendAssetAmounts_ = new uint256[](1);
                spendAssetAmounts_[0] = takerAssetFillAmount;

                minIncomingAssetAmounts_[0] = minIncomingAssetAmounts_[0].sub(takerFeeFillAmount);
            } else if (takerFeeAsset == takerAsset) {
                spendAssets_ = new address[](1);
                spendAssets_[0] = takerAsset;

                spendAssetAmounts_ = new uint256[](1);
                spendAssetAmounts_[0] = takerAssetFillAmount.add(takerFeeFillAmount);
            } else {
                spendAssets_ = new address[](2);
                spendAssets_[0] = takerAsset;
                spendAssets_[1] = takerFeeAsset;

                spendAssetAmounts_ = new uint256[](2);
                spendAssetAmounts_[0] = takerAssetFillAmount;
                spendAssetAmounts_[1] = takerFeeFillAmount;
            }
        } else {
            spendAssets_ = new address[](1);
            spendAssets_[0] = takerAsset;

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = takerAssetFillAmount;
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Decode the parameters of a takeOrder call
    /// @param _actionData Encoded parameters passed from client side
    /// @return encodedZeroExOrderArgs_ Encoded args of the 0x order
    /// @return takerAssetFillAmount_ Amount of taker asset to fill
    function __decodeTakeOrderCallArgs(bytes memory _actionData)
        private
        pure
        returns (bytes memory encodedZeroExOrderArgs_, uint256 takerAssetFillAmount_)
    {
        return abi.decode(_actionData, (bytes, uint256));
    }

    /////////////////////////////
    // ALLOWED MAKERS REGISTRY //
    /////////////////////////////

    /// @notice Adds accounts to the list of allowed 0x order makers
    /// @param _accountsToAdd Accounts to add
    function addAllowedMakers(address[] calldata _accountsToAdd) external onlyFundDeployerOwner {
        __addAllowedMakers(_accountsToAdd);
    }

    /// @notice Removes accounts from the list of allowed 0x order makers
    /// @param _accountsToRemove Accounts to remove
    function removeAllowedMakers(address[] calldata _accountsToRemove)
        external
        onlyFundDeployerOwner
    {
        require(_accountsToRemove.length > 0, "removeAllowedMakers: Empty _accountsToRemove");

        for (uint256 i; i < _accountsToRemove.length; i++) {
            require(
                isAllowedMaker(_accountsToRemove[i]),
                "removeAllowedMakers: Account is not an allowed maker"
            );

            makerToIsAllowed[_accountsToRemove[i]] = false;

            emit AllowedMakerRemoved(_accountsToRemove[i]);
        }
    }

    /// @dev Helper to add accounts to the list of allowed makers
    function __addAllowedMakers(address[] memory _accountsToAdd) private {
        require(_accountsToAdd.length > 0, "__addAllowedMakers: Empty _accountsToAdd");

        for (uint256 i; i < _accountsToAdd.length; i++) {
            require(!isAllowedMaker(_accountsToAdd[i]), "__addAllowedMakers: Value already set");

            makerToIsAllowed[_accountsToAdd[i]] = true;

            emit AllowedMakerAdded(_accountsToAdd[i]);
        }
    }

    /// @dev Parses user inputs into a ZeroExV2.Order format
    function __constructOrderStruct(bytes memory _encodedOrderArgs)
        private
        pure
        returns (IZeroExV2.Order memory order_)
    {
        (
            address[4] memory orderAddresses,
            uint256[6] memory orderValues,
            bytes[2] memory orderData,

        ) = __decodeZeroExOrderArgs(_encodedOrderArgs);

        return
            IZeroExV2.Order({
                makerAddress: orderAddresses[0],
                takerAddress: orderAddresses[1],
                feeRecipientAddress: orderAddresses[2],
                senderAddress: orderAddresses[3],
                makerAssetAmount: orderValues[0],
                takerAssetAmount: orderValues[1],
                makerFee: orderValues[2],
                takerFee: orderValues[3],
                expirationTimeSeconds: orderValues[4],
                salt: orderValues[5],
                makerAssetData: orderData[0],
                takerAssetData: orderData[1]
            });
    }

    /// @dev Decode the parameters of a 0x order
    /// @param _encodedZeroExOrderArgs Encoded parameters of the 0x order
    /// @return orderAddresses_ Addresses used in the order
    /// - [0] 0x Order param: makerAddress
    /// - [1] 0x Order param: takerAddress
    /// - [2] 0x Order param: feeRecipientAddress
    /// - [3] 0x Order param: senderAddress
    /// @return orderValues_ Values used in the order
    /// - [0] 0x Order param: makerAssetAmount
    /// - [1] 0x Order param: takerAssetAmount
    /// - [2] 0x Order param: makerFee
    /// - [3] 0x Order param: takerFee
    /// - [4] 0x Order param: expirationTimeSeconds
    /// - [5] 0x Order param: salt
    /// @return orderData_ Bytes data used in the order
    /// - [0] 0x Order param: makerAssetData
    /// - [1] 0x Order param: takerAssetData
    /// @return signature_ Signature of the order
    function __decodeZeroExOrderArgs(bytes memory _encodedZeroExOrderArgs)
        private
        pure
        returns (
            address[4] memory orderAddresses_,
            uint256[6] memory orderValues_,
            bytes[2] memory orderData_,
            bytes memory signature_
        )
    {
        return abi.decode(_encodedZeroExOrderArgs, (address[4], uint256[6], bytes[2], bytes));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Checks whether an account is an allowed maker of 0x orders
    /// @param _who The account to check
    /// @return isAllowedMaker_ True if _who is an allowed maker
    function isAllowedMaker(address _who) public view returns (bool isAllowedMaker_) {
        return makerToIsAllowed[_who];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../core/fund-deployer/IFundDeployer.sol";

/// @title FundDeployerOwnerMixin Contract
/// @author Enzyme Council <sec[email protected]>
/// @notice A mixin contract that defers ownership to the owner of FundDeployer
abstract contract FundDeployerOwnerMixin {
    address internal immutable FUND_DEPLOYER;

    modifier onlyFundDeployerOwner() {
        require(
            msg.sender == getOwner(),
            "onlyFundDeployerOwner: Only the FundDeployer owner can call this function"
        );
        _;
    }

    constructor(address _fundDeployer) public {
        FUND_DEPLOYER = _fundDeployer;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the FundDeployer contract
    function getOwner() public view returns (address owner_) {
        return IFundDeployer(FUND_DEPLOYER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FUND_DEPLOYER` variable
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    function getFundDeployer() public view returns (address fundDeployer_) {
        return FUND_DEPLOYER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../../../interfaces/IZeroExV2.sol";
import "../../../../../utils/AssetHelpers.sol";
import "../../../../../utils/MathHelpers.sol";

/// @title ZeroExV2ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the ZeroExV2 exchange functions
abstract contract ZeroExV2ActionsMixin is AssetHelpers, MathHelpers {
    address private immutable ZERO_EX_V2_EXCHANGE;

    constructor(address _exchange) public {
        ZERO_EX_V2_EXCHANGE = _exchange;
    }

    /// @dev Helper to execute takeOrder
    function __zeroExV2TakeOrder(
        IZeroExV2.Order memory _order,
        uint256 _takerAssetFillAmount,
        bytes memory _signature
    ) internal {
        // Approve spend assets as needed
        __approveAssetMaxAsNeeded(
            __getAssetAddress(_order.takerAssetData),
            __getAssetProxy(_order.takerAssetData),
            _takerAssetFillAmount
        );
        // Ignores whether makerAsset or takerAsset overlap with the takerFee asset for simplicity
        if (_order.takerFee > 0) {
            bytes memory zrxData = IZeroExV2(ZERO_EX_V2_EXCHANGE).ZRX_ASSET_DATA();
            __approveAssetMaxAsNeeded(
                __getAssetAddress(zrxData),
                __getAssetProxy(zrxData),
                __calcRelativeQuantity(
                    _order.takerAssetAmount,
                    _order.takerFee,
                    _takerAssetFillAmount
                ) // fee calculated relative to taker fill amount
            );
        }

        // Execute order
        IZeroExV2(ZERO_EX_V2_EXCHANGE).fillOrder(_order, _takerAssetFillAmount, _signature);
    }

    /// @dev Parses the asset address from 0x assetData
    function __getAssetAddress(bytes memory _assetData)
        internal
        pure
        returns (address assetAddress_)
    {
        assembly {
            assetAddress_ := mload(add(_assetData, 36))
        }
    }

    /// @dev Gets the 0x assetProxy address for an ERC20 token
    function __getAssetProxy(bytes memory _assetData) internal view returns (address assetProxy_) {
        bytes4 assetProxyId;

        assembly {
            assetProxyId := and(
                mload(add(_assetData, 32)),
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        assetProxy_ = IZeroExV2(getZeroExV2Exchange()).getAssetProxy(assetProxyId);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ZERO_EX_V2_EXCHANGE` variable value
    /// @return zeroExV2Exchange_ The `ZERO_EX_V2_EXCHANGE` variable value
    function getZeroExV2Exchange() public view returns (address zeroExV2Exchange_) {
        return ZERO_EX_V2_EXCHANGE;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    function getOwner() external view returns (address);

    function hasReconfigurationRequest(address) external view returns (bool);

    function isAllowedBuySharesOnBehalfCaller(address) external view returns (bool);

    function isAllowedVaultCall(
        address,
        bytes4,
        bytes32
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @dev Minimal interface for our interactions with the ZeroEx Exchange contract
interface IZeroExV2 {
    struct Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;
        uint256 takerAssetFilledAmount;
        uint256 makerFeePaid;
        uint256 takerFeePaid;
    }

    function ZRX_ASSET_DATA() external view returns (bytes memory);

    function getAssetProxy(bytes4) external view returns (address);

    function fillOrder(
        Order calldata,
        uint256,
        bytes calldata
    ) external returns (FillResults memory);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title MathHelpers Contract
/// @author Enzyme Council <[email protected]>
/// @notice Helper functions for common math operations
abstract contract MathHelpers {
    using SafeMath for uint256;

    /// @dev Calculates a proportional value relative to a known ratio
    function __calcRelativeQuantity(
        uint256 _quantity1,
        uint256 _quantity2,
        uint256 _relativeQuantity1
    ) internal pure returns (uint256 relativeQuantity2_) {
        return _relativeQuantity1.mul(_quantity2).div(_quantity1);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../interfaces/IUniswapV2Pair.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../../../../utils/MathHelpers.sol";
import "../../../value-interpreter/ValueInterpreter.sol";
import "../../utils/UniswapV2PoolTokenValueCalculator.sol";
import "../IDerivativePriceFeed.sol";

/// @title UniswapV2PoolPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed for Uniswap lending pool tokens
contract UniswapV2PoolPriceFeed is
    IDerivativePriceFeed,
    FundDeployerOwnerMixin,
    MathHelpers,
    UniswapV2PoolTokenValueCalculator
{
    event PoolTokenAdded(address indexed poolToken, address token0, address token1);

    struct PoolTokenInfo {
        address token0;
        address token1;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    uint256 private constant POOL_TOKEN_UNIT = 10**18;
    address private immutable FACTORY;
    address private immutable VALUE_INTERPRETER;

    mapping(address => PoolTokenInfo) private poolTokenToInfo;

    constructor(
        address _fundDeployer,
        address _valueInterpreter,
        address _factory
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        FACTORY = _factory;
        VALUE_INTERPRETER = _valueInterpreter;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        PoolTokenInfo memory poolTokenInfo = poolTokenToInfo[_derivative];

        underlyings_ = new address[](2);
        underlyings_[0] = poolTokenInfo.token0;
        underlyings_[1] = poolTokenInfo.token1;

        // Calculate the amounts underlying one unit of a pool token,
        // taking into account the known, trusted rate between the two underlyings
        (uint256 token0TrustedRateAmount, uint256 token1TrustedRateAmount) = __calcTrustedRate(
            poolTokenInfo.token0,
            poolTokenInfo.token1,
            poolTokenInfo.token0Decimals,
            poolTokenInfo.token1Decimals
        );

        (
            uint256 token0DenormalizedRate,
            uint256 token1DenormalizedRate
        ) = __calcTrustedPoolTokenValue(
            FACTORY,
            _derivative,
            token0TrustedRateAmount,
            token1TrustedRateAmount
        );

        // Define normalized rates for each underlying
        underlyingAmounts_ = new uint256[](2);
        underlyingAmounts_[0] = _derivativeAmount.mul(token0DenormalizedRate).div(POOL_TOKEN_UNIT);
        underlyingAmounts_[1] = _derivativeAmount.mul(token1DenormalizedRate).div(POOL_TOKEN_UNIT);

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return poolTokenToInfo[_asset].token0 != address(0);
    }

    // PRIVATE FUNCTIONS

    /// @dev Calculates the trusted rate of two assets based on our price feeds.
    /// Uses the decimals-derived unit for whichever asset is used as the quote asset.
    function __calcTrustedRate(
        address _token0,
        address _token1,
        uint256 _token0Decimals,
        uint256 _token1Decimals
    ) private returns (uint256 token0RateAmount_, uint256 token1RateAmount_) {
        // The quote asset of the value lookup must be a supported primitive asset,
        // so we cycle through the tokens until reaching a primitive.
        // If neither is a primitive, will revert at the ValueInterpreter
        if (IValueInterpreter(VALUE_INTERPRETER).isSupportedPrimitiveAsset(_token0)) {
            token1RateAmount_ = 10**_token1Decimals;
            token0RateAmount_ = ValueInterpreter(VALUE_INTERPRETER).calcCanonicalAssetValue(
                _token1,
                token1RateAmount_,
                _token0
            );
        } else {
            token0RateAmount_ = 10**_token0Decimals;
            token1RateAmount_ = ValueInterpreter(VALUE_INTERPRETER).calcCanonicalAssetValue(
                _token0,
                token0RateAmount_,
                _token1
            );
        }

        return (token0RateAmount_, token1RateAmount_);
    }

    //////////////////////////
    // POOL TOKENS REGISTRY //
    //////////////////////////

    /// @notice Adds Uniswap pool tokens to the price feed
    /// @param _poolTokens Uniswap pool tokens to add
    function addPoolTokens(address[] calldata _poolTokens) external onlyFundDeployerOwner {
        require(_poolTokens.length > 0, "addPoolTokens: Empty _poolTokens");

        for (uint256 i; i < _poolTokens.length; i++) {
            require(_poolTokens[i] != address(0), "addPoolTokens: Empty poolToken");
            require(
                poolTokenToInfo[_poolTokens[i]].token0 == address(0),
                "addPoolTokens: Value already set"
            );

            IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(_poolTokens[i]);
            address token0 = uniswapV2Pair.token0();
            address token1 = uniswapV2Pair.token1();

            require(
                __poolTokenIsSupportable(token0, token1),
                "addPoolTokens: Unsupported pool token"
            );

            poolTokenToInfo[_poolTokens[i]] = PoolTokenInfo({
                token0: token0,
                token1: token1,
                token0Decimals: ERC20(token0).decimals(),
                token1Decimals: ERC20(token1).decimals()
            });

            emit PoolTokenAdded(_poolTokens[i], token0, token1);
        }
    }

    /// @dev Helper to determine if a pool token is supportable, based on whether price feeds are
    /// available for its underlying feeds. At least one of the underlying tokens must be
    /// a supported primitive asset, and the other must be a primitive or derivative.
    function __poolTokenIsSupportable(address _token0, address _token1)
        private
        view
        returns (bool isSupportable_)
    {
        IValueInterpreter valueInterpreterContract = IValueInterpreter(VALUE_INTERPRETER);

        if (valueInterpreterContract.isSupportedPrimitiveAsset(_token0)) {
            if (valueInterpreterContract.isSupportedAsset(_token1)) {
                return true;
            }
        } else if (
            valueInterpreterContract.isSupportedDerivativeAsset(_token0) &&
            valueInterpreterContract.isSupportedPrimitiveAsset(_token1)
        ) {
            return true;
        }

        return false;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FACTORY` variable value
    /// @return factory_ The `FACTORY` variable value
    function getFactory() external view returns (address factory_) {
        return FACTORY;
    }

    /// @notice Gets the `PoolTokenInfo` for a given pool token
    /// @param _poolToken The pool token for which to get the `PoolTokenInfo`
    /// @return poolTokenInfo_ The `PoolTokenInfo` value
    function getPoolTokenInfo(address _poolToken)
        external
        view
        returns (PoolTokenInfo memory poolTokenInfo_)
    {
        return poolTokenToInfo[_poolToken];
    }

    /// @notice Gets the underlyings for a given pool token
    /// @param _poolToken The pool token for which to get its underlyings
    /// @return token0_ The UniswapV2Pair.token0 value
    /// @return token1_ The UniswapV2Pair.token1 value
    function getPoolTokenUnderlyings(address _poolToken)
        external
        view
        returns (address token0_, address token1_)
    {
        return (poolTokenToInfo[_poolToken].token0, poolTokenToInfo[_poolToken].token1);
    }

    /// @notice Gets the `VALUE_INTERPRETER` variable value
    /// @return valueInterpreter_ The `VALUE_INTERPRETER` variable value
    function getValueInterpreter() external view returns (address valueInterpreter_) {
        return VALUE_INTERPRETER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IUniswapV2Pair Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with the Uniswap V2's Pair contract
interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function kLast() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../price-feeds/derivatives/AggregatedDerivativePriceFeedMixin.sol";
import "../price-feeds/derivatives/IDerivativePriceFeed.sol";
import "../price-feeds/primitives/ChainlinkPriceFeedMixin.sol";
import "./IValueInterpreter.sol";

/// @title ValueInterpreter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Interprets price feeds to provide covert value between asset pairs
contract ValueInterpreter is
    IValueInterpreter,
    FundDeployerOwnerMixin,
    AggregatedDerivativePriceFeedMixin,
    ChainlinkPriceFeedMixin
{
    using SafeMath for uint256;

    constructor(address _fundDeployer, address _wethToken)
        public
        FundDeployerOwnerMixin(_fundDeployer)
        ChainlinkPriceFeedMixin(_wethToken)
    {}

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the total value of given amounts of assets in a single quote asset
    /// @param _baseAssets The assets to convert
    /// @param _amounts The amounts of the _baseAssets to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return value_ The sum value of _baseAssets, denominated in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetsTotalValue(
        address[] memory _baseAssets,
        uint256[] memory _amounts,
        address _quoteAsset
    ) external override returns (uint256 value_) {
        require(
            _baseAssets.length == _amounts.length,
            "calcCanonicalAssetsTotalValue: Arrays unequal lengths"
        );
        require(
            isSupportedPrimitiveAsset(_quoteAsset),
            "calcCanonicalAssetsTotalValue: Unsupported _quoteAsset"
        );

        for (uint256 i; i < _baseAssets.length; i++) {
            uint256 assetValue = __calcAssetValue(_baseAssets[i], _amounts[i], _quoteAsset);
            value_ = value_.add(assetValue);
        }

        return value_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Calculates the value of a given amount of one asset in terms of another asset
    /// @param _baseAsset The asset from which to convert
    /// @param _amount The amount of the _baseAsset to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return value_ The equivalent quantity in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external override returns (uint256 value_) {
        if (_baseAsset == _quoteAsset || _amount == 0) {
            return _amount;
        }

        require(
            isSupportedPrimitiveAsset(_quoteAsset),
            "calcCanonicalAssetValue: Unsupported _quoteAsset"
        );

        return __calcAssetValue(_baseAsset, _amount, _quoteAsset);
    }

    /// @notice Checks whether an asset is a supported asset
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported asset
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return isSupportedPrimitiveAsset(_asset) || isSupportedDerivativeAsset(_asset);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to differentially calculate an asset value
    /// based on if it is a primitive or derivative asset.
    function __calcAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) private returns (uint256 value_) {
        if (_baseAsset == _quoteAsset || _amount == 0) {
            return _amount;
        }

        // Handle case that asset is a primitive
        if (isSupportedPrimitiveAsset(_baseAsset)) {
            return __calcCanonicalValue(_baseAsset, _amount, _quoteAsset);
        }

        // Handle case that asset is a derivative
        address derivativePriceFeed = getPriceFeedForDerivative(_baseAsset);
        if (derivativePriceFeed != address(0)) {
            return __calcDerivativeValue(derivativePriceFeed, _baseAsset, _amount, _quoteAsset);
        }

        revert("__calcAssetValue: Unsupported _baseAsset");
    }

    /// @dev Helper to calculate the value of a derivative in an arbitrary asset.
    /// Handles multiple underlying assets (e.g., Uniswap and Balancer pool tokens).
    /// Handles underlying assets that are also derivatives (e.g., a cDAI-ETH LP)
    function __calcDerivativeValue(
        address _derivativePriceFeed,
        address _derivative,
        uint256 _amount,
        address _quoteAsset
    ) private returns (uint256 value_) {
        (address[] memory underlyings, uint256[] memory underlyingAmounts) = IDerivativePriceFeed(
            _derivativePriceFeed
        )
            .calcUnderlyingValues(_derivative, _amount);

        require(underlyings.length > 0, "__calcDerivativeValue: No underlyings");
        require(
            underlyings.length == underlyingAmounts.length,
            "__calcDerivativeValue: Arrays unequal lengths"
        );

        for (uint256 i = 0; i < underlyings.length; i++) {
            uint256 underlyingValue = __calcAssetValue(
                underlyings[i],
                underlyingAmounts[i],
                _quoteAsset
            );

            value_ = value_.add(underlyingValue);
        }
    }

    ////////////////////////////
    // PRIMITIVES (CHAINLINK) //
    ////////////////////////////

    /// @notice Adds a list of primitives with the given aggregator and rateAsset values
    /// @param _primitives The primitives to add
    /// @param _aggregators The ordered aggregators corresponding to the list of _primitives
    /// @param _rateAssets The ordered rate assets corresponding to the list of _primitives
    function addPrimitives(
        address[] calldata _primitives,
        address[] calldata _aggregators,
        RateAsset[] calldata _rateAssets
    ) external onlyFundDeployerOwner {
        __addPrimitives(_primitives, _aggregators, _rateAssets);
    }

    /// @notice Removes a list of primitives from the feed
    /// @param _primitives The primitives to remove
    function removePrimitives(address[] calldata _primitives) external onlyFundDeployerOwner {
        __removePrimitives(_primitives);
    }

    /// @notice Sets the `ehUsdAggregator` variable value
    /// @param _nextEthUsdAggregator The `ehUsdAggregator` value to set
    function setEthUsdAggregator(address _nextEthUsdAggregator) external onlyFundDeployerOwner {
        __setEthUsdAggregator(_nextEthUsdAggregator);
    }

    /// @notice Sets the `staleRateThreshold` variable
    /// @param _nextStaleRateThreshold The next `staleRateThreshold` value
    function setStaleRateThreshold(uint256 _nextStaleRateThreshold)
        external
        onlyFundDeployerOwner
    {
        __setStaleRateThreshold(_nextStaleRateThreshold);
    }

    /// @notice Updates a list of primitives with the given aggregator and rateAsset values
    /// @param _primitives The primitives to update
    /// @param _aggregators The ordered aggregators corresponding to the list of _primitives
    /// @param _rateAssets The ordered rate assets corresponding to the list of _primitives
    function updatePrimitives(
        address[] calldata _primitives,
        address[] calldata _aggregators,
        RateAsset[] calldata _rateAssets
    ) external onlyFundDeployerOwner {
        __removePrimitives(_primitives);
        __addPrimitives(_primitives, _aggregators, _rateAssets);
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether an asset is a supported primitive
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported primitive
    function isSupportedPrimitiveAsset(address _asset)
        public
        view
        override
        returns (bool isSupported_)
    {
        return _asset == getWethToken() || getAggregatorForPrimitive(_asset) != address(0);
    }

    ////////////////////////////////////
    // DERIVATIVE PRICE FEED REGISTRY //
    ////////////////////////////////////

    /// @notice Adds a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to add
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function addDerivatives(address[] calldata _derivatives, address[] calldata _priceFeeds)
        external
        onlyFundDeployerOwner
    {
        __addDerivatives(_derivatives, _priceFeeds);
    }

    /// @notice Removes a list of derivatives
    /// @param _derivatives The derivatives to remove
    function removeDerivatives(address[] calldata _derivatives) external onlyFundDeployerOwner {
        __removeDerivatives(_derivatives);
    }

    /// @notice Updates a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to update
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function updateDerivatives(address[] calldata _derivatives, address[] calldata _priceFeeds)
        external
        onlyFundDeployerOwner
    {
        __removeDerivatives(_derivatives);
        __addDerivatives(_derivatives, _priceFeeds);
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether an asset is a supported derivative
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported derivative
    function isSupportedDerivativeAsset(address _asset)
        public
        view
        override
        returns (bool isSupported_)
    {
        return getPriceFeedForDerivative(_asset) != address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../interfaces/IUniswapV2Factory.sol";
import "../../../interfaces/IUniswapV2Pair.sol";

/// @title UniswapV2PoolTokenValueCalculator Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract contract for computing the value of Uniswap liquidity pool tokens
/// @dev Unless otherwise noted, these functions are adapted to our needs and style guide from
/// an un-merged Uniswap branch:
/// https://github.com/Uniswap/uniswap-v2-periphery/blob/267ba44471f3357071a2fe2573fe4da42d5ad969/contracts/libraries/UniswapV2LiquidityMathLibrary.sol
abstract contract UniswapV2PoolTokenValueCalculator {
    using SafeMath for uint256;

    uint256 private constant POOL_TOKEN_UNIT = 10**18;

    // INTERNAL FUNCTIONS

    /// @dev Given a Uniswap pool with token0 and token1 and their trusted rate,
    /// returns the value of one pool token unit in terms of token0 and token1.
    /// This is the only function used outside of this contract.
    function __calcTrustedPoolTokenValue(
        address _factory,
        address _pair,
        uint256 _token0TrustedRateAmount,
        uint256 _token1TrustedRateAmount
    ) internal view returns (uint256 token0Amount_, uint256 token1Amount_) {
        (uint256 reserve0, uint256 reserve1) = __calcReservesAfterArbitrage(
            _pair,
            _token0TrustedRateAmount,
            _token1TrustedRateAmount
        );

        return __calcPoolTokenValue(_factory, _pair, reserve0, reserve1);
    }

    // PRIVATE FUNCTIONS

    /// @dev Computes liquidity value given all the parameters of the pair
    function __calcPoolTokenValue(
        address _factory,
        address _pair,
        uint256 _reserve0,
        uint256 _reserve1
    ) private view returns (uint256 token0Amount_, uint256 token1Amount_) {
        IUniswapV2Pair pairContract = IUniswapV2Pair(_pair);
        uint256 totalSupply = pairContract.totalSupply();

        if (IUniswapV2Factory(_factory).feeTo() != address(0)) {
            uint256 kLast = pairContract.kLast();
            if (kLast > 0) {
                uint256 rootK = __uniswapSqrt(_reserve0.mul(_reserve1));
                uint256 rootKLast = __uniswapSqrt(kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 feeLiquidity = numerator.div(denominator);
                    totalSupply = totalSupply.add(feeLiquidity);
                }
            }
        }
        return (
            _reserve0.mul(POOL_TOKEN_UNIT).div(totalSupply),
            _reserve1.mul(POOL_TOKEN_UNIT).div(totalSupply)
        );
    }

    /// @dev Calculates the direction and magnitude of the profit-maximizing trade
    function __calcProfitMaximizingTrade(
        uint256 _token0TrustedRateAmount,
        uint256 _token1TrustedRateAmount,
        uint256 _reserve0,
        uint256 _reserve1
    ) private pure returns (bool token0ToToken1_, uint256 amountIn_) {
        token0ToToken1_ =
            _reserve0.mul(_token1TrustedRateAmount).div(_reserve1) < _token0TrustedRateAmount;

        uint256 leftSide;
        uint256 rightSide;
        if (token0ToToken1_) {
            leftSide = __uniswapSqrt(
                _reserve0.mul(_reserve1).mul(_token0TrustedRateAmount).mul(1000).div(
                    _token1TrustedRateAmount.mul(997)
                )
            );
            rightSide = _reserve0.mul(1000).div(997);
        } else {
            leftSide = __uniswapSqrt(
                _reserve0.mul(_reserve1).mul(_token1TrustedRateAmount).mul(1000).div(
                    _token0TrustedRateAmount.mul(997)
                )
            );
            rightSide = _reserve1.mul(1000).div(997);
        }

        if (leftSide < rightSide) {
            return (false, 0);
        }

        // Calculate the amount that must be sent to move the price to the profit-maximizing price
        amountIn_ = leftSide.sub(rightSide);

        return (token0ToToken1_, amountIn_);
    }

    /// @dev Calculates the pool reserves after an arbitrage moves the price to
    /// the profit-maximizing rate, given an externally-observed trusted rate
    /// between the two pooled assets
    function __calcReservesAfterArbitrage(
        address _pair,
        uint256 _token0TrustedRateAmount,
        uint256 _token1TrustedRateAmount
    ) private view returns (uint256 reserve0_, uint256 reserve1_) {
        (reserve0_, reserve1_, ) = IUniswapV2Pair(_pair).getReserves();

        // Skip checking whether the reserve is 0, as this is extremely unlikely given how
        // initial pool liquidity is locked, and since we maintain a list of registered pool tokens

        // Calculate how much to swap to arb to the trusted price
        (bool token0ToToken1, uint256 amountIn) = __calcProfitMaximizingTrade(
            _token0TrustedRateAmount,
            _token1TrustedRateAmount,
            reserve0_,
            reserve1_
        );
        if (amountIn == 0) {
            return (reserve0_, reserve1_);
        }

        // Adjust the reserves to account for the arb trade to the trusted price
        if (token0ToToken1) {
            uint256 amountOut = __uniswapV2GetAmountOut(amountIn, reserve0_, reserve1_);
            reserve0_ = reserve0_.add(amountIn);
            reserve1_ = reserve1_.sub(amountOut);
        } else {
            uint256 amountOut = __uniswapV2GetAmountOut(amountIn, reserve1_, reserve0_);
            reserve1_ = reserve1_.add(amountIn);
            reserve0_ = reserve0_.sub(amountOut);
        }

        return (reserve0_, reserve1_);
    }

    /// @dev Uniswap square root function. See:
    /// https://github.com/Uniswap/uniswap-lib/blob/6ddfedd5716ba85b905bf34d7f1f3c659101a1bc/contracts/libraries/Babylonian.sol
    function __uniswapSqrt(uint256 _y) private pure returns (uint256 z_) {
        if (_y > 3) {
            z_ = _y;
            uint256 x = _y / 2 + 1;
            while (x < z_) {
                z_ = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z_ = 1;
        }
        // else z_ = 0

        return z_;
    }

    /// @dev Simplified version of UniswapV2Library's getAmountOut() function. See:
    /// https://github.com/Uniswap/uniswap-v2-periphery/blob/87edfdcaf49ccc52591502993db4c8c08ea9eec0/contracts/libraries/UniswapV2Library.sol#L42-L50
    function __uniswapV2GetAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) private pure returns (uint256 amountOut_) {
        uint256 amountInWithFee = _amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(_reserveOut);
        uint256 denominator = _reserveIn.mul(1000).add(amountInWithFee);

        return numerator.div(denominator);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDerivativePriceFeed Interface
/// @author Enzyme Council <[email protected]>
/// @notice Simple interface for derivative price source oracle implementations
interface IDerivativePriceFeed {
    function calcUnderlyingValues(address, uint256)
        external
        returns (address[] memory, uint256[] memory);

    function isSupportedAsset(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./IDerivativePriceFeed.sol";

/// @title AggregatedDerivativePriceFeedMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Aggregates multiple derivative price feeds (e.g., Compound, Chai) and dispatches
/// rate requests to the appropriate feed
abstract contract AggregatedDerivativePriceFeedMixin {
    event DerivativeAdded(address indexed derivative, address priceFeed);

    event DerivativeRemoved(address indexed derivative);

    mapping(address => address) private derivativeToPriceFeed;

    /// @notice Gets the rates for 1 unit of the derivative to its underlying assets
    /// @param _derivative The derivative for which to get the rates
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The rates for the _derivative to the underlyings_
    function __calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        internal
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address derivativePriceFeed = getPriceFeedForDerivative(_derivative);
        require(
            derivativePriceFeed != address(0),
            "calcUnderlyingValues: _derivative is not supported"
        );

        return
            IDerivativePriceFeed(derivativePriceFeed).calcUnderlyingValues(
                _derivative,
                _derivativeAmount
            );
    }

    //////////////////////////
    // DERIVATIVES REGISTRY //
    //////////////////////////

    /// @notice Adds a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to add
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function __addDerivatives(address[] memory _derivatives, address[] memory _priceFeeds)
        internal
    {
        require(
            _derivatives.length == _priceFeeds.length,
            "__addDerivatives: Unequal _derivatives and _priceFeeds array lengths"
        );

        for (uint256 i = 0; i < _derivatives.length; i++) {
            require(
                getPriceFeedForDerivative(_derivatives[i]) == address(0),
                "__addDerivatives: Already added"
            );

            __validateDerivativePriceFeed(_derivatives[i], _priceFeeds[i]);

            derivativeToPriceFeed[_derivatives[i]] = _priceFeeds[i];

            emit DerivativeAdded(_derivatives[i], _priceFeeds[i]);
        }
    }

    /// @notice Removes a list of derivatives
    /// @param _derivatives The derivatives to remove
    function __removeDerivatives(address[] memory _derivatives) internal {
        for (uint256 i = 0; i < _derivatives.length; i++) {
            require(
                getPriceFeedForDerivative(_derivatives[i]) != address(0),
                "removeDerivatives: Derivative not yet added"
            );

            delete derivativeToPriceFeed[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to validate a derivative price feed
    function __validateDerivativePriceFeed(address _derivative, address _priceFeed) private view {
        require(
            IDerivativePriceFeed(_priceFeed).isSupportedAsset(_derivative),
            "__validateDerivativePriceFeed: Unsupported derivative"
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the registered price feed for a given derivative
    /// @return priceFeed_ The price feed contract address
    function getPriceFeedForDerivative(address _derivative)
        public
        view
        returns (address priceFeed_)
    {
        return derivativeToPriceFeed[_derivative];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../interfaces/IChainlinkAggregator.sol";

/// @title ChainlinkPriceFeedMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A price feed that uses Chainlink oracles as price sources
abstract contract ChainlinkPriceFeedMixin {
    using SafeMath for uint256;

    event EthUsdAggregatorSet(address prevEthUsdAggregator, address nextEthUsdAggregator);

    event PrimitiveAdded(
        address indexed primitive,
        address aggregator,
        RateAsset rateAsset,
        uint256 unit
    );

    event PrimitiveRemoved(address indexed primitive);

    event StalePrimitiveRemoved(address indexed primitive);

    event StaleRateThresholdSet(uint256 prevStaleRateThreshold, uint256 nextStaleRateThreshold);

    enum RateAsset {ETH, USD}

    struct AggregatorInfo {
        address aggregator;
        RateAsset rateAsset;
    }

    uint256 private constant ETH_UNIT = 10**18;
    address private immutable WETH_TOKEN;

    address private ethUsdAggregator;
    uint256 private staleRateThreshold;
    mapping(address => AggregatorInfo) private primitiveToAggregatorInfo;
    mapping(address => uint256) private primitiveToUnit;

    constructor(address _wethToken) public {
        WETH_TOKEN = _wethToken;
        staleRateThreshold = 25 hours; // 24 hour heartbeat + 1hr buffer
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether the current rate is considered stale for the specified aggregator
    /// @param _aggregator The Chainlink aggregator of which to check staleness
    /// @return rateIsStale_ True if the rate is considered stale
    function rateIsStale(address _aggregator) public view returns (bool rateIsStale_) {
        return
            IChainlinkAggregator(_aggregator).latestTimestamp() <
            block.timestamp.sub(getStaleRateThreshold());
    }

    // INTERNAL FUNCTIONS

    /// @notice Calculates the value of a base asset in terms of a quote asset (using a canonical rate)
    /// @param _baseAsset The base asset
    /// @param _baseAssetAmount The base asset amount to convert
    /// @param _quoteAsset The quote asset
    /// @return quoteAssetAmount_ The equivalent quote asset amount
    function __calcCanonicalValue(
        address _baseAsset,
        uint256 _baseAssetAmount,
        address _quoteAsset
    ) internal view returns (uint256 quoteAssetAmount_) {
        // Case where _baseAsset == _quoteAsset is handled by ValueInterpreter

        int256 baseAssetRate = __getLatestRateData(_baseAsset);
        require(baseAssetRate > 0, "__calcCanonicalValue: Invalid base asset rate");

        int256 quoteAssetRate = __getLatestRateData(_quoteAsset);
        require(quoteAssetRate > 0, "__calcCanonicalValue: Invalid quote asset rate");

        return
            __calcConversionAmount(
                _baseAsset,
                _baseAssetAmount,
                uint256(baseAssetRate),
                _quoteAsset,
                uint256(quoteAssetRate)
            );
    }

    /// @dev Helper to set the `ethUsdAggregator` value
    function __setEthUsdAggregator(address _nextEthUsdAggregator) internal {
        address prevEthUsdAggregator = getEthUsdAggregator();
        require(
            _nextEthUsdAggregator != prevEthUsdAggregator,
            "__setEthUsdAggregator: Value already set"
        );

        __validateAggregator(_nextEthUsdAggregator);

        ethUsdAggregator = _nextEthUsdAggregator;

        emit EthUsdAggregatorSet(prevEthUsdAggregator, _nextEthUsdAggregator);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to convert an amount from a _baseAsset to a _quoteAsset
    function __calcConversionAmount(
        address _baseAsset,
        uint256 _baseAssetAmount,
        uint256 _baseAssetRate,
        address _quoteAsset,
        uint256 _quoteAssetRate
    ) private view returns (uint256 quoteAssetAmount_) {
        RateAsset baseAssetRateAsset = getRateAssetForPrimitive(_baseAsset);
        RateAsset quoteAssetRateAsset = getRateAssetForPrimitive(_quoteAsset);
        uint256 baseAssetUnit = getUnitForPrimitive(_baseAsset);
        uint256 quoteAssetUnit = getUnitForPrimitive(_quoteAsset);

        // If rates are both in ETH or both in USD
        if (baseAssetRateAsset == quoteAssetRateAsset) {
            return
                __calcConversionAmountSameRateAsset(
                    _baseAssetAmount,
                    baseAssetUnit,
                    _baseAssetRate,
                    quoteAssetUnit,
                    _quoteAssetRate
                );
        }

        int256 ethPerUsdRate = IChainlinkAggregator(getEthUsdAggregator()).latestAnswer();
        require(ethPerUsdRate > 0, "__calcConversionAmount: Bad ethUsd rate");

        // If _baseAsset's rate is in ETH and _quoteAsset's rate is in USD
        if (baseAssetRateAsset == RateAsset.ETH) {
            return
                __calcConversionAmountEthRateAssetToUsdRateAsset(
                    _baseAssetAmount,
                    baseAssetUnit,
                    _baseAssetRate,
                    quoteAssetUnit,
                    _quoteAssetRate,
                    uint256(ethPerUsdRate)
                );
        }

        // If _baseAsset's rate is in USD and _quoteAsset's rate is in ETH
        return
            __calcConversionAmountUsdRateAssetToEthRateAsset(
                _baseAssetAmount,
                baseAssetUnit,
                _baseAssetRate,
                quoteAssetUnit,
                _quoteAssetRate,
                uint256(ethPerUsdRate)
            );
    }

    /// @dev Helper to convert amounts where the base asset has an ETH rate and the quote asset has a USD rate
    function __calcConversionAmountEthRateAssetToUsdRateAsset(
        uint256 _baseAssetAmount,
        uint256 _baseAssetUnit,
        uint256 _baseAssetRate,
        uint256 _quoteAssetUnit,
        uint256 _quoteAssetRate,
        uint256 _ethPerUsdRate
    ) private pure returns (uint256 quoteAssetAmount_) {
        // Only allows two consecutive multiplication operations to avoid potential overflow.
        // Intermediate step needed to resolve stack-too-deep error.
        uint256 intermediateStep = _baseAssetAmount.mul(_baseAssetRate).mul(_ethPerUsdRate).div(
            ETH_UNIT
        );

        return intermediateStep.mul(_quoteAssetUnit).div(_baseAssetUnit).div(_quoteAssetRate);
    }

    /// @dev Helper to convert amounts where base and quote assets both have ETH rates or both have USD rates
    function __calcConversionAmountSameRateAsset(
        uint256 _baseAssetAmount,
        uint256 _baseAssetUnit,
        uint256 _baseAssetRate,
        uint256 _quoteAssetUnit,
        uint256 _quoteAssetRate
    ) private pure returns (uint256 quoteAssetAmount_) {
        // Only allows two consecutive multiplication operations to avoid potential overflow
        return
            _baseAssetAmount.mul(_baseAssetRate).mul(_quoteAssetUnit).div(
                _baseAssetUnit.mul(_quoteAssetRate)
            );
    }

    /// @dev Helper to convert amounts where the base asset has a USD rate and the quote asset has an ETH rate
    function __calcConversionAmountUsdRateAssetToEthRateAsset(
        uint256 _baseAssetAmount,
        uint256 _baseAssetUnit,
        uint256 _baseAssetRate,
        uint256 _quoteAssetUnit,
        uint256 _quoteAssetRate,
        uint256 _ethPerUsdRate
    ) private pure returns (uint256 quoteAssetAmount_) {
        // Only allows two consecutive multiplication operations to avoid potential overflow
        // Intermediate step needed to resolve stack-too-deep error.
        uint256 intermediateStep = _baseAssetAmount.mul(_baseAssetRate).mul(_quoteAssetUnit).div(
            _ethPerUsdRate
        );

        return intermediateStep.mul(ETH_UNIT).div(_baseAssetUnit).div(_quoteAssetRate);
    }

    /// @dev Helper to get the latest rate for a given primitive
    function __getLatestRateData(address _primitive) private view returns (int256 rate_) {
        if (_primitive == getWethToken()) {
            return int256(ETH_UNIT);
        }

        address aggregator = getAggregatorForPrimitive(_primitive);
        require(aggregator != address(0), "__getLatestRateData: Primitive does not exist");

        return IChainlinkAggregator(aggregator).latestAnswer();
    }

    /////////////////////////
    // PRIMITIVES REGISTRY //
    /////////////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Removes stale primitives from the feed
    /// @param _primitives The stale primitives to remove
    /// @dev Callable by anybody
    function removeStalePrimitives(address[] calldata _primitives) external {
        for (uint256 i; i < _primitives.length; i++) {
            address aggregatorAddress = getAggregatorForPrimitive(_primitives[i]);
            require(aggregatorAddress != address(0), "removeStalePrimitives: Invalid primitive");
            require(rateIsStale(aggregatorAddress), "removeStalePrimitives: Rate is not stale");

            delete primitiveToAggregatorInfo[_primitives[i]];
            delete primitiveToUnit[_primitives[i]];

            emit StalePrimitiveRemoved(_primitives[i]);
        }
    }

    // INTERNAL FUNCTIONS

    /// @notice Adds a list of primitives with the given aggregator and rateAsset values
    /// @param _primitives The primitives to add
    /// @param _aggregators The ordered aggregators corresponding to the list of _primitives
    /// @param _rateAssets The ordered rate assets corresponding to the list of _primitives
    function __addPrimitives(
        address[] calldata _primitives,
        address[] calldata _aggregators,
        RateAsset[] calldata _rateAssets
    ) internal {
        require(
            _primitives.length == _aggregators.length,
            "__addPrimitives: Unequal _primitives and _aggregators array lengths"
        );
        require(
            _primitives.length == _rateAssets.length,
            "__addPrimitives: Unequal _primitives and _rateAssets array lengths"
        );

        for (uint256 i; i < _primitives.length; i++) {
            require(
                getAggregatorForPrimitive(_primitives[i]) == address(0),
                "__addPrimitives: Value already set"
            );

            __validateAggregator(_aggregators[i]);

            primitiveToAggregatorInfo[_primitives[i]] = AggregatorInfo({
                aggregator: _aggregators[i],
                rateAsset: _rateAssets[i]
            });

            // Store the amount that makes up 1 unit given the asset's decimals
            uint256 unit = 10**uint256(ERC20(_primitives[i]).decimals());
            primitiveToUnit[_primitives[i]] = unit;

            emit PrimitiveAdded(_primitives[i], _aggregators[i], _rateAssets[i], unit);
        }
    }

    /// @notice Removes a list of primitives from the feed
    /// @param _primitives The primitives to remove
    function __removePrimitives(address[] calldata _primitives) internal {
        for (uint256 i; i < _primitives.length; i++) {
            require(
                getAggregatorForPrimitive(_primitives[i]) != address(0),
                "__removePrimitives: Primitive not yet added"
            );

            delete primitiveToAggregatorInfo[_primitives[i]];
            delete primitiveToUnit[_primitives[i]];

            emit PrimitiveRemoved(_primitives[i]);
        }
    }

    /// @notice Sets the `staleRateThreshold` variable
    /// @param _nextStaleRateThreshold The next `staleRateThreshold` value
    function __setStaleRateThreshold(uint256 _nextStaleRateThreshold) internal {
        uint256 prevStaleRateThreshold = getStaleRateThreshold();
        require(
            _nextStaleRateThreshold != prevStaleRateThreshold,
            "__setStaleRateThreshold: Value already set"
        );

        staleRateThreshold = _nextStaleRateThreshold;

        emit StaleRateThresholdSet(prevStaleRateThreshold, _nextStaleRateThreshold);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to validate an aggregator by checking its return values for the expected interface
    function __validateAggregator(address _aggregator) private view {
        require(
            IChainlinkAggregator(_aggregator).latestAnswer() > 0,
            "__validateAggregator: No rate detected"
        );
        require(!rateIsStale(_aggregator), "__validateAggregator: Stale rate detected");
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the aggregator for a primitive
    /// @param _primitive The primitive asset for which to get the aggregator value
    /// @return aggregator_ The aggregator address
    function getAggregatorForPrimitive(address _primitive)
        public
        view
        returns (address aggregator_)
    {
        return primitiveToAggregatorInfo[_primitive].aggregator;
    }

    /// @notice Gets the `ethUsdAggregator` variable value
    /// @return ethUsdAggregator_ The `ethUsdAggregator` variable value
    function getEthUsdAggregator() public view returns (address ethUsdAggregator_) {
        return ethUsdAggregator;
    }

    /// @notice Gets the rateAsset variable value for a primitive
    /// @return rateAsset_ The rateAsset variable value
    /// @dev This isn't strictly necessary as WETH_TOKEN will be undefined and thus
    /// the RateAsset will be the 0-position of the enum (i.e. ETH), but it makes the
    /// behavior more explicit
    function getRateAssetForPrimitive(address _primitive)
        public
        view
        returns (RateAsset rateAsset_)
    {
        if (_primitive == getWethToken()) {
            return RateAsset.ETH;
        }

        return primitiveToAggregatorInfo[_primitive].rateAsset;
    }

    /// @notice Gets the `staleRateThreshold` variable value
    /// @return staleRateThreshold_ The `staleRateThreshold` variable value
    function getStaleRateThreshold() public view returns (uint256 staleRateThreshold_) {
        return staleRateThreshold;
    }

    /// @notice Gets the unit variable value for a primitive
    /// @return unit_ The unit variable value
    function getUnitForPrimitive(address _primitive) public view returns (uint256 unit_) {
        if (_primitive == getWethToken()) {
            return ETH_UNIT;
        }

        return primitiveToUnit[_primitive];
    }

    /// @notice Gets the `WETH_TOKEN` variable value
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IValueInterpreter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for ValueInterpreter
interface IValueInterpreter {
    function calcCanonicalAssetValue(
        address,
        uint256,
        address
    ) external returns (uint256);

    function calcCanonicalAssetsTotalValue(
        address[] calldata,
        uint256[] calldata,
        address
    ) external returns (uint256);

    function isSupportedAsset(address) external view returns (bool);

    function isSupportedDerivativeAsset(address) external view returns (bool);

    function isSupportedPrimitiveAsset(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IChainlinkAggregator Interface
/// @author Enzyme Council <[email protected]>
interface IChainlinkAggregator {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IUniswapV2Factory Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with the Uniswap V2's Factory contract
interface IUniswapV2Factory {
    function feeTo() external view returns (address);

    function getPair(address, address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/IChainlinkAggregator.sol";
import "../../../../utils/MakerDaoMath.sol";
import "../IDerivativePriceFeed.sol";

/// @title WdgldPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for WDGLD <https://dgld.ch/>
contract WdgldPriceFeed is IDerivativePriceFeed, MakerDaoMath {
    using SafeMath for uint256;

    address private immutable XAU_AGGREGATOR;
    address private immutable ETH_AGGREGATOR;

    address private immutable WDGLD;
    address private immutable WETH;

    // GTR_CONSTANT aggregates all the invariants in the GTR formula to save gas
    uint256 private constant GTR_CONSTANT = 999990821653213975346065101;
    uint256 private constant GTR_PRECISION = 10**27;
    uint256 private constant WDGLD_GENESIS_TIMESTAMP = 1568700000;

    constructor(
        address _wdgld,
        address _weth,
        address _ethAggregator,
        address _xauAggregator
    ) public {
        WDGLD = _wdgld;
        WETH = _weth;
        ETH_AGGREGATOR = _ethAggregator;
        XAU_AGGREGATOR = _xauAggregator;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        require(isSupportedAsset(_derivative), "calcUnderlyingValues: Only WDGLD is supported");

        underlyings_ = new address[](1);
        underlyings_[0] = WETH;
        underlyingAmounts_ = new uint256[](1);

        // Get price rates from xau and eth aggregators
        int256 xauToUsdRate = IChainlinkAggregator(XAU_AGGREGATOR).latestAnswer();
        int256 ethToUsdRate = IChainlinkAggregator(ETH_AGGREGATOR).latestAnswer();
        require(xauToUsdRate > 0 && ethToUsdRate > 0, "calcUnderlyingValues: rate invalid");

        uint256 wdgldToXauRate = calcWdgldToXauRate();

        // 10**17 is a combination of ETH_UNIT / WDGLD_UNIT * GTR_PRECISION
        underlyingAmounts_[0] = _derivativeAmount
            .mul(wdgldToXauRate)
            .mul(uint256(xauToUsdRate))
            .div(uint256(ethToUsdRate))
            .div(10**17);

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Calculates the rate of WDGLD to XAU.
    /// @return wdgldToXauRate_ The current rate of WDGLD to XAU
    /// @dev Full formula available <https://dgld.ch/assets/documents/dgld-whitepaper.pdf>
    function calcWdgldToXauRate() public view returns (uint256 wdgldToXauRate_) {
        return
            __rpow(
                GTR_CONSTANT,
                ((block.timestamp).sub(WDGLD_GENESIS_TIMESTAMP)).div(28800), // 60 * 60 * 8 (8 hour periods)
                GTR_PRECISION
            )
                .div(10);
    }

    /// @notice Checks if an asset is supported by this price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return _asset == WDGLD;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ETH_AGGREGATOR` address
    /// @return ethAggregatorAddress_ The `ETH_AGGREGATOR` address
    function getEthAggregator() external view returns (address ethAggregatorAddress_) {
        return ETH_AGGREGATOR;
    }

    /// @notice Gets the `WDGLD` token address
    /// @return wdgld_ The `WDGLD` token address
    function getWdgld() external view returns (address wdgld_) {
        return WDGLD;
    }

    /// @notice Gets the `WETH` token address
    /// @return weth_ The `WETH` token address
    function getWeth() external view returns (address weth_) {
        return WETH;
    }

    /// @notice Gets the `XAU_AGGREGATOR` address
    /// @return xauAggregatorAddress_ The `XAU_AGGREGATOR` address
    function getXauAggregator() external view returns (address xauAggregatorAddress_) {
        return XAU_AGGREGATOR;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

/// @title MakerDaoMath Contract
/// @author Enzyme Council <[email protected]>
/// @notice Helper functions for math operations adapted from MakerDao contracts
abstract contract MakerDaoMath {
    /// @dev Performs scaled, fixed-point exponentiation.
    /// Verbatim code, adapted to our style guide for variable naming only, see:
    /// https://github.com/makerdao/dss/blob/master/src/pot.sol#L83-L105
    // prettier-ignore
    function __rpow(uint256 _x, uint256 _n, uint256 _base) internal pure returns (uint256 z_) {
        assembly {
            switch _x case 0 {switch _n case 0 {z_ := _base} default {z_ := 0}}
            default {
                switch mod(_n, 2) case 0 { z_ := _base } default { z_ := _x }
                let half := div(_base, 2)
                for { _n := div(_n, 2) } _n { _n := div(_n,2) } {
                    let xx := mul(_x, _x)
                    if iszero(eq(div(xx, _x), _x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    _x := div(xxRound, _base)
                    if mod(_n,2) {
                        let zx := mul(z_, _x)
                        if and(iszero(iszero(_x)), iszero(eq(div(zx, _x), z_))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z_ := div(zxRound, _base)
                    }
                }
            }
        }

        return z_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../core/fund/vault/VaultLib.sol";
import "../../../utils/MakerDaoMath.sol";
import "./utils/FeeBase.sol";
import "./utils/UpdatableFeeRecipientBase.sol";

/// @title ManagementFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice A management fee with a configurable annual rate
contract ManagementFee is FeeBase, UpdatableFeeRecipientBase, MakerDaoMath {
    using SafeMath for uint256;

    event ActivatedForMigratedFund(address indexed comptrollerProxy);

    event FundSettingsAdded(address indexed comptrollerProxy, uint256 scaledPerSecondRate);

    event Settled(
        address indexed comptrollerProxy,
        uint256 sharesQuantity,
        uint256 secondsSinceSettlement
    );

    struct FeeInfo {
        uint256 scaledPerSecondRate;
        uint256 lastSettled;
    }

    uint256 private constant RATE_SCALE_BASE = 10**27;

    mapping(address => FeeInfo) private comptrollerProxyToFeeInfo;

    constructor(address _feeManager) public FeeBase(_feeManager) {}

    // EXTERNAL FUNCTIONS

    /// @notice Activates the fee for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _vaultProxy The VaultProxy of the fund
    function activateForFund(address _comptrollerProxy, address _vaultProxy)
        external
        override
        onlyFeeManager
    {
        // It is only necessary to set `lastSettled` for a migrated fund
        if (VaultLib(payable(_vaultProxy)).totalSupply() > 0) {
            comptrollerProxyToFeeInfo[_comptrollerProxy].lastSettled = block.timestamp;

            emit ActivatedForMigratedFund(_comptrollerProxy);
        }
    }

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        external
        override
        onlyFeeManager
    {
        (uint256 scaledPerSecondRate, address recipient) = abi.decode(
            _settingsData,
            (uint256, address)
        );
        require(
            scaledPerSecondRate > 0,
            "addFundSettings: scaledPerSecondRate must be greater than 0"
        );

        comptrollerProxyToFeeInfo[_comptrollerProxy] = FeeInfo({
            scaledPerSecondRate: scaledPerSecondRate,
            lastSettled: 0
        });

        emit FundSettingsAdded(_comptrollerProxy, scaledPerSecondRate);

        if (recipient != address(0)) {
            __setRecipientForFund(_comptrollerProxy, recipient);
        }
    }

    /// @notice Settle the fee and calculate shares due
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @return settlementType_ The type of settlement
    /// @return (unused) The payer of shares due
    /// @return sharesDue_ The amount of shares due
    function settle(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook,
        bytes calldata,
        uint256
    )
        external
        override
        onlyFeeManager
        returns (
            IFeeManager.SettlementType settlementType_,
            address,
            uint256 sharesDue_
        )
    {
        FeeInfo storage feeInfo = comptrollerProxyToFeeInfo[_comptrollerProxy];

        // If this fee was settled in the current block, we can return early
        uint256 secondsSinceSettlement = block.timestamp.sub(feeInfo.lastSettled);
        if (secondsSinceSettlement == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        // If there are shares issued for the fund, calculate the shares due
        VaultLib vaultProxyContract = VaultLib(payable(_vaultProxy));
        uint256 sharesSupply = vaultProxyContract.totalSupply();
        if (sharesSupply > 0) {
            // This assumes that all shares in the VaultProxy are shares outstanding,
            // which is fine for this release. Even if they are not, they are still shares that
            // are only claimable by the fund owner.
            uint256 netSharesSupply = sharesSupply.sub(vaultProxyContract.balanceOf(_vaultProxy));
            if (netSharesSupply > 0) {
                sharesDue_ = netSharesSupply
                    .mul(
                    __rpow(feeInfo.scaledPerSecondRate, secondsSinceSettlement, RATE_SCALE_BASE)
                        .sub(RATE_SCALE_BASE)
                )
                    .div(RATE_SCALE_BASE);
            }
        }

        // Must settle even when no shares are due, for the case that settlement is being
        // done when there are no shares in the fund (i.e. at the first investment, or at the
        // first investment after all shares have been redeemed)
        comptrollerProxyToFeeInfo[_comptrollerProxy].lastSettled = block.timestamp;
        emit Settled(_comptrollerProxy, sharesDue_, secondsSinceSettlement);

        if (sharesDue_ == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        return (IFeeManager.SettlementType.Mint, address(0), sharesDue_);
    }

    /// @notice Gets whether the fee settles and requires GAV on a particular hook
    /// @param _hook The FeeHook
    /// @return settles_ True if the fee settles on the _hook
    /// @return usesGav_ True if the fee uses GAV during settle() for the _hook
    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        override
        returns (bool settles_, bool usesGav_)
    {
        if (
            _hook == IFeeManager.FeeHook.PreBuyShares ||
            _hook == IFeeManager.FeeHook.PreRedeemShares ||
            _hook == IFeeManager.FeeHook.Continuous
        ) {
            return (true, false);
        }

        return (false, false);
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the recipient of the fee for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return recipient_ The recipient
    function getRecipientForFund(address _comptrollerProxy)
        public
        view
        override(FeeBase, SettableFeeRecipientBase)
        returns (address recipient_)
    {
        return SettableFeeRecipientBase.getRecipientForFund(_comptrollerProxy);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the feeInfo for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract of the fund
    /// @return feeInfo_ The feeInfo
    function getFeeInfoForFund(address _comptrollerProxy)
        external
        view
        returns (FeeInfo memory feeInfo_)
    {
        return comptrollerProxyToFeeInfo[_comptrollerProxy];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../persistent/dispatcher/IDispatcher.sol";
import "../../../../persistent/external-positions/IExternalPosition.sol";
import "../../../../persistent/protocol-fee-reserve/interfaces/IProtocolFeeReserve1.sol";
import "../../../../persistent/vault/VaultLibBase2.sol";
import "../../../infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "../../../infrastructure/protocol-fees/IProtocolFeeTracker.sol";
import "../../../extensions/external-position-manager/IExternalPositionManager.sol";
import "../../../interfaces/IWETH.sol";
import "../../../utils/AddressArrayLib.sol";
import "../comptroller/IComptroller.sol";
import "./IVault.sol";

/// @title VaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The per-release proxiable library contract for VaultProxy
/// @dev The difference in terminology between "asset" and "trackedAsset" is intentional.
/// A fund might actually have asset balances of un-tracked assets,
/// but only tracked assets are used in gav calculations.
/// Note that this contract inherits VaultLibSafeMath (a verbatim Open Zeppelin SafeMath copy)
/// from SharesTokenBase via VaultLibBase2
contract VaultLib is VaultLibBase2, IVault, GasRelayRecipientMixin {
    using AddressArrayLib for address[];
    using SafeERC20 for ERC20;

    // "Positions" are "tracked assets" + active "external positions"
    // Before updating POSITIONS_LIMIT in the future, it is important to consider:
    // 1. The highest positions limit ever allowed in the protocol
    // 2. That the next value will need to be respected by all future releases
    uint256 private constant POSITIONS_LIMIT = 20;

    address private immutable EXTERNAL_POSITION_MANAGER;
    address private immutable MLN_TOKEN;
    address private immutable PROTOCOL_FEE_RESERVE;
    address private immutable PROTOCOL_FEE_TRACKER;
    address private immutable WETH_TOKEN;

    modifier notShares(address _asset) {
        require(_asset != address(this), "Cannot act on shares");
        _;
    }

    modifier onlyAccessor() {
        require(msg.sender == accessor, "Only the designated accessor can make this call");
        _;
    }

    modifier onlyOwner() {
        require(__msgSender() == owner, "Only the owner can call this function");
        _;
    }

    constructor(
        address _externalPositionManager,
        address _gasRelayPaymasterFactory,
        address _protocolFeeReserve,
        address _protocolFeeTracker,
        address _mlnToken,
        address _wethToken
    ) public GasRelayRecipientMixin(_gasRelayPaymasterFactory) {
        EXTERNAL_POSITION_MANAGER = _externalPositionManager;
        MLN_TOKEN = _mlnToken;
        PROTOCOL_FEE_RESERVE = _protocolFeeReserve;
        PROTOCOL_FEE_TRACKER = _protocolFeeTracker;
        WETH_TOKEN = _wethToken;
    }

    /// @dev If a VaultProxy receives ETH, immediately wrap into WETH.
    /// Will not be able to receive ETH via .transfer() or .send() due to limited gas forwarding.
    receive() external payable {
        IWETH(payable(getWethToken())).deposit{value: payable(address(this)).balance}();
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Gets the external position library contract for a given type
    /// @param _typeId The type for which to get the external position library
    /// @return externalPositionLib_ The external position library
    function getExternalPositionLibForType(uint256 _typeId)
        external
        view
        override
        returns (address externalPositionLib_)
    {
        return
            IExternalPositionManager(getExternalPositionManager()).getExternalPositionLibForType(
                _typeId
            );
    }

    /// @notice Sets shares as (permanently) freely transferable
    /// @dev Once set, this can never be allowed to be unset, as it provides a critical
    /// transferability guarantee to liquidity pools and other smart contract holders
    /// that rely on transfers to function properly. Enabling this option will skip all
    /// policies run upon transferring shares, but will still respect the shares action timelock.
    function setFreelyTransferableShares() external onlyOwner {
        require(!sharesAreFreelyTransferable(), "setFreelyTransferableShares: Already set");

        freelyTransferableShares = true;

        emit FreelyTransferableSharesSet();
    }

    ////////////////////////
    // PERMISSIONED ROLES //
    ////////////////////////

    /// @notice Registers accounts that can manage vault holdings within the protocol
    /// @param _managers The accounts to add as asset managers
    function addAssetManagers(address[] calldata _managers) external onlyOwner {
        for (uint256 i; i < _managers.length; i++) {
            require(!isAssetManager(_managers[i]), "addAssetManagers: Manager already registered");

            accountToIsAssetManager[_managers[i]] = true;

            emit AssetManagerAdded(_managers[i]);
        }
    }

    /// @notice Claim ownership of the contract
    function claimOwnership() external {
        address nextOwner = nominatedOwner;
        require(
            msg.sender == nextOwner,
            "claimOwnership: Only the nominatedOwner can call this function"
        );

        delete nominatedOwner;

        address prevOwner = owner;
        owner = nextOwner;

        emit OwnershipTransferred(prevOwner, nextOwner);
    }

    /// @notice Deregisters accounts that can manage vault holdings within the protocol
    /// @param _managers The accounts to remove as asset managers
    function removeAssetManagers(address[] calldata _managers) external onlyOwner {
        for (uint256 i; i < _managers.length; i++) {
            require(isAssetManager(_managers[i]), "removeAssetManagers: Manager not registered");

            accountToIsAssetManager[_managers[i]] = false;

            emit AssetManagerRemoved(_managers[i]);
        }
    }

    /// @notice Revoke the nomination of a new contract owner
    function removeNominatedOwner() external onlyOwner {
        address removedNominatedOwner = nominatedOwner;
        require(
            removedNominatedOwner != address(0),
            "removeNominatedOwner: There is no nominated owner"
        );

        delete nominatedOwner;

        emit NominatedOwnerRemoved(removedNominatedOwner);
    }

    /// @notice Sets the account that is allowed to migrate a fund to new releases
    /// @param _nextMigrator The account to set as the allowed migrator
    /// @dev Set to address(0) to remove the migrator.
    function setMigrator(address _nextMigrator) external onlyOwner {
        address prevMigrator = migrator;
        require(_nextMigrator != prevMigrator, "setMigrator: Value already set");

        migrator = _nextMigrator;

        emit MigratorSet(prevMigrator, _nextMigrator);
    }

    /// @notice Nominate a new contract owner
    /// @param _nextNominatedOwner The account to nominate
    /// @dev Does not prohibit overwriting the current nominatedOwner
    function setNominatedOwner(address _nextNominatedOwner) external onlyOwner {
        require(
            _nextNominatedOwner != address(0),
            "setNominatedOwner: _nextNominatedOwner cannot be empty"
        );
        require(
            _nextNominatedOwner != owner,
            "setNominatedOwner: _nextNominatedOwner is already the owner"
        );
        require(
            _nextNominatedOwner != nominatedOwner,
            "setNominatedOwner: _nextNominatedOwner is already nominated"
        );

        nominatedOwner = _nextNominatedOwner;

        emit NominatedOwnerSet(_nextNominatedOwner);
    }

    ////////////////////////
    // FUND DEPLOYER ONLY //
    ////////////////////////

    /// @notice Updates the accessor during a config change within this release
    /// @param _nextAccessor The next accessor
    function setAccessorForFundReconfiguration(address _nextAccessor) external override {
        require(msg.sender == getFundDeployer(), "Only the FundDeployer can make this call");

        __setAccessor(_nextAccessor);
    }

    ///////////////////////////////////////
    // ACCESSOR (COMPTROLLER PROXY) ONLY //
    ///////////////////////////////////////

    /// @notice Adds a tracked asset
    /// @param _asset The asset to add as a tracked asset
    function addTrackedAsset(address _asset) external override onlyAccessor {
        __addTrackedAsset(_asset);
    }

    /// @notice Burns fund shares from a particular account
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to burn
    function burnShares(address _target, uint256 _amount) external override onlyAccessor {
        __burn(_target, _amount);
    }

    /// @notice Buys back shares collected as protocol fee at a discounted shares price, using MLN
    /// @param _sharesAmount The amount of shares to buy back
    /// @param _mlnValue The MLN-denominated market value of _sharesAmount
    /// @param _gav The total fund GAV
    /// @dev Since the vault controls both the MLN to burn and the admin function to burn any user's
    /// fund shares, there is no need to transfer assets back-and-forth with the ProtocolFeeReserve.
    /// We only need to know the correct discounted amount of MLN to burn.
    function buyBackProtocolFeeShares(
        uint256 _sharesAmount,
        uint256 _mlnValue,
        uint256 _gav
    ) external override onlyAccessor {
        uint256 mlnAmountToBurn = IProtocolFeeReserve1(getProtocolFeeReserve())
            .buyBackSharesViaTrustedVaultProxy(_sharesAmount, _mlnValue, _gav);

        if (mlnAmountToBurn == 0) {
            return;
        }

        // Burn shares and MLN amounts
        // If shares or MLN balance is insufficient, will revert
        __burn(getProtocolFeeReserve(), _sharesAmount);
        ERC20Burnable(getMlnToken()).burn(mlnAmountToBurn);

        emit ProtocolFeeSharesBoughtBack(_sharesAmount, _mlnValue, mlnAmountToBurn);
    }

    /// @notice Makes an arbitrary call with this contract as the sender
    /// @param _contract The contract to call
    /// @param _callData The call data for the call
    function callOnContract(address _contract, bytes calldata _callData)
        external
        override
        onlyAccessor
    {
        (bool success, bytes memory returnData) = _contract.call(_callData);
        require(success, string(returnData));
    }

    /// @notice Mints fund shares to a particular account
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to mint
    function mintShares(address _target, uint256 _amount) external override onlyAccessor {
        __mint(_target, _amount);
    }

    /// @notice Pays the due protocol fee by minting shares to the ProtocolFeeReserve
    function payProtocolFee() external override onlyAccessor {
        uint256 sharesDue = IProtocolFeeTracker(getProtocolFeeTracker()).payFee();

        if (sharesDue == 0) {
            return;
        }

        __mint(getProtocolFeeReserve(), sharesDue);

        emit ProtocolFeePaidInShares(sharesDue);
    }

    /// @notice Transfers fund shares from one account to another
    /// @param _from The account from which to transfer shares
    /// @param _to The account to which to transfer shares
    /// @param _amount The amount of shares to transfer
    /// @dev For protocol use only, all other transfers should operate
    /// via standard ERC20 functions
    function transferShares(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyAccessor {
        __transfer(_from, _to, _amount);
    }

    /// @notice Withdraws an asset from the VaultProxy to a given account
    /// @param _asset The asset to withdraw
    /// @param _target The account to which to withdraw the asset
    /// @param _amount The amount of asset to withdraw
    function withdrawAssetTo(
        address _asset,
        address _target,
        uint256 _amount
    ) external override onlyAccessor {
        __withdrawAssetTo(_asset, _target, _amount);
    }

    ///////////////////////////
    // VAULT ACTION DISPATCH //
    ///////////////////////////

    /// @notice Dispatches a call initiated from an Extension, validated by the ComptrollerProxy
    /// @param _action The VaultAction to perform
    /// @param _actionData The call data for the action to perform
    function receiveValidatedVaultAction(VaultAction _action, bytes calldata _actionData)
        external
        override
        onlyAccessor
    {
        if (_action == VaultAction.AddExternalPosition) {
            __executeVaultActionAddExternalPosition(_actionData);
        } else if (_action == VaultAction.AddTrackedAsset) {
            __executeVaultActionAddTrackedAsset(_actionData);
        } else if (_action == VaultAction.ApproveAssetSpender) {
            __executeVaultActionApproveAssetSpender(_actionData);
        } else if (_action == VaultAction.BurnShares) {
            __executeVaultActionBurnShares(_actionData);
        } else if (_action == VaultAction.CallOnExternalPosition) {
            __executeVaultActionCallOnExternalPosition(_actionData);
        } else if (_action == VaultAction.MintShares) {
            __executeVaultActionMintShares(_actionData);
        } else if (_action == VaultAction.RemoveExternalPosition) {
            __executeVaultActionRemoveExternalPosition(_actionData);
        } else if (_action == VaultAction.RemoveTrackedAsset) {
            __executeVaultActionRemoveTrackedAsset(_actionData);
        } else if (_action == VaultAction.TransferShares) {
            __executeVaultActionTransferShares(_actionData);
        } else if (_action == VaultAction.WithdrawAssetTo) {
            __executeVaultActionWithdrawAssetTo(_actionData);
        }
    }

    /// @dev Helper to decode actionData and execute VaultAction.AddExternalPosition
    function __executeVaultActionAddExternalPosition(bytes memory _actionData) private {
        __addExternalPosition(abi.decode(_actionData, (address)));
    }

    /// @dev Helper to decode actionData and execute VaultAction.AddTrackedAsset
    function __executeVaultActionAddTrackedAsset(bytes memory _actionData) private {
        __addTrackedAsset(abi.decode(_actionData, (address)));
    }

    /// @dev Helper to decode actionData and execute VaultAction.ApproveAssetSpender
    function __executeVaultActionApproveAssetSpender(bytes memory _actionData) private {
        (address asset, address target, uint256 amount) = abi.decode(
            _actionData,
            (address, address, uint256)
        );

        __approveAssetSpender(asset, target, amount);
    }

    /// @dev Helper to decode actionData and execute VaultAction.BurnShares
    function __executeVaultActionBurnShares(bytes memory _actionData) private {
        (address target, uint256 amount) = abi.decode(_actionData, (address, uint256));

        __burn(target, amount);
    }

    /// @dev Helper to decode actionData and execute VaultAction.CallOnExternalPosition
    function __executeVaultActionCallOnExternalPosition(bytes memory _actionData) private {
        (
            address externalPosition,
            bytes memory callOnExternalPositionActionData,
            address[] memory assetsToTransfer,
            uint256[] memory amountsToTransfer,
            address[] memory assetsToReceive
        ) = abi.decode(_actionData, (address, bytes, address[], uint256[], address[]));

        __callOnExternalPosition(
            externalPosition,
            callOnExternalPositionActionData,
            assetsToTransfer,
            amountsToTransfer,
            assetsToReceive
        );
    }

    /// @dev Helper to decode actionData and execute VaultAction.MintShares
    function __executeVaultActionMintShares(bytes memory _actionData) private {
        (address target, uint256 amount) = abi.decode(_actionData, (address, uint256));

        __mint(target, amount);
    }

    /// @dev Helper to decode actionData and execute VaultAction.RemoveExternalPosition
    function __executeVaultActionRemoveExternalPosition(bytes memory _actionData) private {
        __removeExternalPosition(abi.decode(_actionData, (address)));
    }

    /// @dev Helper to decode actionData and execute VaultAction.RemoveTrackedAsset
    function __executeVaultActionRemoveTrackedAsset(bytes memory _actionData) private {
        __removeTrackedAsset(abi.decode(_actionData, (address)));
    }

    /// @dev Helper to decode actionData and execute VaultAction.TransferShares
    function __executeVaultActionTransferShares(bytes memory _actionData) private {
        (address from, address to, uint256 amount) = abi.decode(
            _actionData,
            (address, address, uint256)
        );

        __transfer(from, to, amount);
    }

    /// @dev Helper to decode actionData and execute VaultAction.WithdrawAssetTo
    function __executeVaultActionWithdrawAssetTo(bytes memory _actionData) private {
        (address asset, address target, uint256 amount) = abi.decode(
            _actionData,
            (address, address, uint256)
        );

        __withdrawAssetTo(asset, target, amount);
    }

    ///////////////////
    // VAULT ACTIONS //
    ///////////////////

    /// @dev Helper to track a new active external position
    function __addExternalPosition(address _externalPosition) private {
        if (!isActiveExternalPosition(_externalPosition)) {
            __validatePositionsLimit();

            externalPositionToIsActive[_externalPosition] = true;
            activeExternalPositions.push(_externalPosition);

            emit ExternalPositionAdded(_externalPosition);
        }
    }

    /// @dev Helper to add a tracked asset
    function __addTrackedAsset(address _asset) private notShares(_asset) {
        if (!isTrackedAsset(_asset)) {
            __validatePositionsLimit();

            assetToIsTracked[_asset] = true;
            trackedAssets.push(_asset);

            emit TrackedAssetAdded(_asset);
        }
    }

    /// @dev Helper to grant an allowance to a spender to use a vault asset
    function __approveAssetSpender(
        address _asset,
        address _target,
        uint256 _amount
    ) private notShares(_asset) {
        ERC20 assetContract = ERC20(_asset);
        if (assetContract.allowance(address(this), _target) > 0) {
            assetContract.safeApprove(_target, 0);
        }
        assetContract.safeApprove(_target, _amount);
    }

    /// @dev Helper to make a call on a external position contract
    /// @param _externalPosition The external position to call
    /// @param _actionData The action data for the call
    /// @param _assetsToTransfer The assets to transfer to the external position
    /// @param _amountsToTransfer The amount of assets to be transferred to the external position
    /// @param _assetsToReceive The assets that will be received from the call
    function __callOnExternalPosition(
        address _externalPosition,
        bytes memory _actionData,
        address[] memory _assetsToTransfer,
        uint256[] memory _amountsToTransfer,
        address[] memory _assetsToReceive
    ) private {
        require(
            isActiveExternalPosition(_externalPosition),
            "__callOnExternalPosition: Not an active external position"
        );

        for (uint256 i; i < _assetsToTransfer.length; i++) {
            __withdrawAssetTo(_assetsToTransfer[i], _externalPosition, _amountsToTransfer[i]);
        }

        IExternalPosition(_externalPosition).receiveCallFromVault(_actionData);

        for (uint256 i; i < _assetsToReceive.length; i++) {
            __addTrackedAsset(_assetsToReceive[i]);
        }
    }

    /// @dev Helper to the get the Vault's balance of a given asset
    function __getAssetBalance(address _asset) private view returns (uint256 balance_) {
        return ERC20(_asset).balanceOf(address(this));
    }

    /// @dev Helper to remove a external position from the vault
    function __removeExternalPosition(address _externalPosition) private {
        if (isActiveExternalPosition(_externalPosition)) {
            externalPositionToIsActive[_externalPosition] = false;

            activeExternalPositions.removeStorageItem(_externalPosition);

            emit ExternalPositionRemoved(_externalPosition);
        }
    }

    /// @dev Helper to remove a tracked asset
    function __removeTrackedAsset(address _asset) private {
        if (isTrackedAsset(_asset)) {
            assetToIsTracked[_asset] = false;

            trackedAssets.removeStorageItem(_asset);

            emit TrackedAssetRemoved(_asset);
        }
    }

    /// @dev Helper to validate that the positions limit has not been reached
    function __validatePositionsLimit() private view {
        require(
            trackedAssets.length + activeExternalPositions.length < POSITIONS_LIMIT,
            "__validatePositionsLimit: Limit exceeded"
        );
    }

    /// @dev Helper to withdraw an asset from the vault to a specified recipient
    function __withdrawAssetTo(
        address _asset,
        address _target,
        uint256 _amount
    ) private notShares(_asset) {
        ERC20(_asset).safeTransfer(_target, _amount);

        emit AssetWithdrawn(_asset, _target, _amount);
    }

    ////////////////////////////
    // SHARES ERC20 OVERRIDES //
    ////////////////////////////

    /// @notice Gets the `symbol` value of the shares token
    /// @return symbol_ The `symbol` value
    /// @dev Defers the shares symbol value to the Dispatcher contract
    function symbol() public view override returns (string memory symbol_) {
        return IDispatcher(creator).getSharesTokenSymbol();
    }

    /// @dev Standard implementation of ERC20's transfer().
    /// Overridden to allow arbitrary logic in ComptrollerProxy prior to transfer.
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        __invokePreTransferSharesHook(msg.sender, _recipient, _amount);

        return super.transfer(_recipient, _amount);
    }

    /// @dev Standard implementation of ERC20's transferFrom().
    /// Overridden to allow arbitrary logic in ComptrollerProxy prior to transfer.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        __invokePreTransferSharesHook(_sender, _recipient, _amount);

        return super.transferFrom(_sender, _recipient, _amount);
    }

    /// @dev Helper to call the relevant preTransferShares hook
    function __invokePreTransferSharesHook(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        if (sharesAreFreelyTransferable()) {
            IComptroller(accessor).preTransferSharesHookFreelyTransferable(_sender);
        } else {
            IComptroller(accessor).preTransferSharesHook(_sender, _recipient, _amount);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Checks whether an account can manage assets
    /// @param _who The account to check
    /// @return canManageAssets_ True if the account can manage assets
    function canManageAssets(address _who) external view override returns (bool canManageAssets_) {
        return _who == getOwner() || isAssetManager(_who);
    }

    /// @notice Checks whether an account can use gas relaying
    /// @param _who The account to check
    /// @return canRelayCalls_ True if the account can use gas relaying on this fund
    function canRelayCalls(address _who) external view override returns (bool canRelayCalls_) {
        return _who == getOwner() || isAssetManager(_who) || _who == getMigrator();
    }

    /// @notice Gets the `accessor` variable
    /// @return accessor_ The `accessor` variable value
    function getAccessor() public view override returns (address accessor_) {
        return accessor;
    }

    /// @notice Gets the `creator` variable
    /// @return creator_ The `creator` variable value
    function getCreator() external view returns (address creator_) {
        return creator;
    }

    /// @notice Gets the `migrator` variable
    /// @return migrator_ The `migrator` variable value
    function getMigrator() public view returns (address migrator_) {
        return migrator;
    }

    /// @notice Gets the account that is nominated to be the next owner of this contract
    /// @return nominatedOwner_ The account that is nominated to be the owner
    function getNominatedOwner() external view returns (address nominatedOwner_) {
        return nominatedOwner;
    }

    /// @notice Gets the `activeExternalPositions` variable
    /// @return activeExternalPositions_ The `activeExternalPositions` variable value
    function getActiveExternalPositions()
        external
        view
        override
        returns (address[] memory activeExternalPositions_)
    {
        return activeExternalPositions;
    }

    /// @notice Gets the `trackedAssets` variable
    /// @return trackedAssets_ The `trackedAssets` variable value
    function getTrackedAssets() external view override returns (address[] memory trackedAssets_) {
        return trackedAssets;
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the `EXTERNAL_POSITION_MANAGER` variable
    /// @return externalPositionManager_ The `EXTERNAL_POSITION_MANAGER` variable value
    function getExternalPositionManager() public view returns (address externalPositionManager_) {
        return EXTERNAL_POSITION_MANAGER;
    }

    /// @notice Gets the vaults fund deployer
    /// @return fundDeployer_ The fund deployer contract associated with this vault
    function getFundDeployer() public view returns (address fundDeployer_) {
        return IDispatcher(creator).getFundDeployerForVaultProxy(address(this));
    }

    /// @notice Gets the `MLN_TOKEN` variable
    /// @return mlnToken_ The `MLN_TOKEN` variable value
    function getMlnToken() public view returns (address mlnToken_) {
        return MLN_TOKEN;
    }

    /// @notice Gets the `owner` variable
    /// @return owner_ The `owner` variable value
    function getOwner() public view override returns (address owner_) {
        return owner;
    }

    /// @notice Gets the `PROTOCOL_FEE_RESERVE` variable
    /// @return protocolFeeReserve_ The `PROTOCOL_FEE_RESERVE` variable value
    function getProtocolFeeReserve() public view returns (address protocolFeeReserve_) {
        return PROTOCOL_FEE_RESERVE;
    }

    /// @notice Gets the `PROTOCOL_FEE_TRACKER` variable
    /// @return protocolFeeTracker_ The `PROTOCOL_FEE_TRACKER` variable value
    function getProtocolFeeTracker() public view returns (address protocolFeeTracker_) {
        return PROTOCOL_FEE_TRACKER;
    }

    /// @notice Check whether an external position is active on the vault
    /// @param _externalPosition The externalPosition to check
    /// @return isActiveExternalPosition_ True if the address is an active external position on the vault
    function isActiveExternalPosition(address _externalPosition)
        public
        view
        override
        returns (bool isActiveExternalPosition_)
    {
        return externalPositionToIsActive[_externalPosition];
    }

    /// @notice Checks whether an account is an allowed asset manager
    /// @param _who The account to check
    /// @return isAssetManager_ True if the account is an allowed asset manager
    function isAssetManager(address _who) public view returns (bool isAssetManager_) {
        return accountToIsAssetManager[_who];
    }

    /// @notice Checks whether an address is a tracked asset of the vault
    /// @param _asset The address to check
    /// @return isTrackedAsset_ True if the address is a tracked asset
    function isTrackedAsset(address _asset) public view override returns (bool isTrackedAsset_) {
        return assetToIsTracked[_asset];
    }

    /// @notice Checks whether shares are (permanently) freely transferable
    /// @return sharesAreFreelyTransferable_ True if shares are (permanently) freely transferable
    function sharesAreFreelyTransferable()
        public
        view
        override
        returns (bool sharesAreFreelyTransferable_)
    {
        return freelyTransferableShares;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../IFee.sol";

/// @title FeeBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract base contract for all fees
abstract contract FeeBase is IFee {
    address internal immutable FEE_MANAGER;

    modifier onlyFeeManager {
        require(msg.sender == FEE_MANAGER, "Only the FeeManger can make this call");
        _;
    }

    constructor(address _feeManager) public {
        FEE_MANAGER = _feeManager;
    }

    /// @notice Allows Fee to run logic during fund activation
    /// @dev Unimplemented by default, may be overrode.
    function activateForFund(address, address) external virtual override {
        return;
    }

    /// @notice Gets the recipient of the fee for a given fund
    /// @dev address(0) signifies the VaultProxy owner.
    /// Returns address(0) by default, can be overridden by fee.
    function getRecipientForFund(address)
        external
        view
        virtual
        override
        returns (address recipient_)
    {
        return address(0);
    }

    /// @notice Runs payout logic for a fee that utilizes shares outstanding as its settlement type
    /// @dev Returns false by default, can be overridden by fee
    function payout(address, address) external virtual override returns (bool) {
        return false;
    }

    /// @notice Update fee state after all settlement has occurred during a given fee hook
    /// @dev Unimplemented by default, can be overridden by fee
    function update(
        address,
        address,
        IFeeManager.FeeHook,
        bytes calldata,
        uint256
    ) external virtual override {
        return;
    }

    /// @notice Gets whether the fee updates and requires GAV on a particular hook
    /// @return updates_ True if the fee updates on the _hook
    /// @return usesGav_ True if the fee uses GAV during update() for the _hook
    /// @dev Returns false values by default, can be overridden by fee
    function updatesOnHook(IFeeManager.FeeHook)
        external
        view
        virtual
        override
        returns (bool updates_, bool usesGav_)
    {
        return (false, false);
    }

    /// @notice Helper to parse settlement arguments from encoded data for PreBuyShares fee hook
    function __decodePreBuySharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (address buyer_, uint256 investmentAmount_)
    {
        return abi.decode(_settlementData, (address, uint256));
    }

    /// @notice Helper to parse settlement arguments from encoded data for PreRedeemShares fee hook
    function __decodePreRedeemSharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (
            address redeemer_,
            uint256 sharesQuantity_,
            bool forSpecificAssets_
        )
    {
        return abi.decode(_settlementData, (address, uint256, bool));
    }

    /// @notice Helper to parse settlement arguments from encoded data for PostBuyShares fee hook
    function __decodePostBuySharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (
            address buyer_,
            uint256 investmentAmount_,
            uint256 sharesIssued_
        )
    {
        return abi.decode(_settlementData, (address, uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FEE_MANAGER` variable
    /// @return feeManager_ The `FEE_MANAGER` variable value
    function getFeeManager() external view returns (address feeManager_) {
        return FEE_MANAGER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../core/fund/comptroller/ComptrollerLib.sol";
import "../../../../core/fund/vault/VaultLib.sol";
import "./SettableFeeRecipientBase.sol";

/// @title UpdatableFeeRecipientBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract that provides an updatable fee recipient for the inheriting fee
abstract contract UpdatableFeeRecipientBase is SettableFeeRecipientBase {
    /// @notice Sets the fee recipient for the given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @param _recipient The fee recipient
    function setRecipientForFund(address _comptrollerProxy, address _recipient) external {
        require(
            msg.sender ==
                VaultLib(payable(ComptrollerLib(_comptrollerProxy).getVaultProxy())).getOwner(),
            "__setRecipientForFund: Only vault owner callable"
        );

        __setRecipientForFund(_comptrollerProxy, _recipient);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPosition Contract
/// @author Enzyme Council <[email protected]>
interface IExternalPosition {
    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IProtocolFeeReserve1 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Each interface should inherit the previous interface,
/// e.g., `IProtocolFeeReserve2 is IProtocolFeeReserve1`
interface IProtocolFeeReserve1 {
    function buyBackSharesViaTrustedVaultProxy(
        uint256 _sharesAmount,
        uint256 _mlnValue,
        uint256 _gav
    ) external returns (uint256 mlnAmountToBurn_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./VaultLibBase1.sol";

/// @title VaultLibBase2 Contract
/// @author Enzyme Council <[email protected]>
/// @notice The first implementation of VaultLibBase1, with additional events and storage
/// @dev All subsequent implementations should inherit the previous implementation,
/// e.g., `VaultLibBase2 is VaultLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract VaultLibBase2 is VaultLibBase1 {
    event AssetManagerAdded(address manager);

    event AssetManagerRemoved(address manager);

    event ExternalPositionAdded(address indexed externalPosition);

    event ExternalPositionRemoved(address indexed externalPosition);

    event FreelyTransferableSharesSet();

    event NominatedOwnerRemoved(address indexed nominatedOwner);

    event NominatedOwnerSet(address indexed nominatedOwner);

    event ProtocolFeePaidInShares(uint256 sharesAmount);

    event ProtocolFeeSharesBoughtBack(uint256 sharesAmount, uint256 mlnValue, uint256 mlnBurned);

    event OwnershipTransferred(address indexed prevOwner, address indexed nextOwner);

    // In order to make transferability guarantees to liquidity pools and other smart contracts
    // that hold/treat shares as generic ERC20 tokens, a permanent guarantee on transferability
    // is required. Once set as `true`, freelyTransferableShares should never be unset.
    bool internal freelyTransferableShares;
    address internal nominatedOwner;
    address[] internal activeExternalPositions;
    mapping(address => bool) internal accountToIsAssetManager;
    mapping(address => bool) internal externalPositionToIsActive;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../utils/beacon-proxy/IBeaconProxyFactory.sol";
import "./IGasRelayPaymaster.sol";

pragma solidity 0.6.12;

/// @title GasRelayRecipientMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin that enables receiving GSN-relayed calls
/// @dev IMPORTANT: Do not use storage var in this contract,
/// unless it is no longer inherited by the VaultLib
abstract contract GasRelayRecipientMixin {
    address internal immutable GAS_RELAY_PAYMASTER_FACTORY;

    constructor(address _gasRelayPaymasterFactory) internal {
        GAS_RELAY_PAYMASTER_FACTORY = _gasRelayPaymasterFactory;
    }

    /// @dev Helper to parse the canonical sender of a tx based on whether it has been relayed
    function __msgSender() internal view returns (address payable canonicalSender_) {
        if (msg.data.length >= 24 && msg.sender == getGasRelayTrustedForwarder()) {
            assembly {
                canonicalSender_ := shr(96, calldataload(sub(calldatasize(), 20)))
            }

            return canonicalSender_;
        }

        return msg.sender;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `GAS_RELAY_PAYMASTER_FACTORY` variable
    /// @return gasRelayPaymasterFactory_ The `GAS_RELAY_PAYMASTER_FACTORY` variable value
    function getGasRelayPaymasterFactory()
        public
        view
        returns (address gasRelayPaymasterFactory_)
    {
        return GAS_RELAY_PAYMASTER_FACTORY;
    }

    /// @notice Gets the trusted forwarder for GSN relaying
    /// @return trustedForwarder_ The trusted forwarder
    function getGasRelayTrustedForwarder() public view returns (address trustedForwarder_) {
        return
            IGasRelayPaymaster(
                IBeaconProxyFactory(getGasRelayPaymasterFactory()).getCanonicalLib()
            )
                .trustedForwarder();
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IProtocolFeeTracker Interface
/// @author Enzyme Council <[email protected]>
interface IProtocolFeeTracker {
    function initializeForVault(address) external;

    function payFee() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionManager interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the ExternalPositionManager
interface IExternalPositionManager {
    struct ExternalPositionTypeInfo {
        address parser;
        address lib;
    }
    enum ExternalPositionManagerActions {
        CreateExternalPosition,
        CallOnExternalPosition,
        RemoveExternalPosition,
        ReactivateExternalPosition
    }

    function getExternalPositionLibForType(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title WETH Interface
/// @author Enzyme Council <[email protected]>
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title AddressArray Library
/// @author Enzyme Council <[email protected]>
/// @notice A library to extend the address array data type
library AddressArrayLib {
    /////////////
    // STORAGE //
    /////////////

    /// @dev Helper to remove an item from a storage array
    function removeStorageItem(address[] storage _self, address _itemToRemove)
        internal
        returns (bool removed_)
    {
        uint256 itemCount = _self.length;
        for (uint256 i; i < itemCount; i++) {
            if (_self[i] == _itemToRemove) {
                if (i < itemCount - 1) {
                    _self[i] = _self[itemCount - 1];
                }
                _self.pop();
                removed_ = true;
                break;
            }
        }

        return removed_;
    }

    ////////////
    // MEMORY //
    ////////////

    /// @dev Helper to add an item to an array. Does not assert uniqueness of the new item.
    function addItem(address[] memory _self, address _itemToAdd)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        nextArray_ = new address[](_self.length + 1);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        nextArray_[_self.length] = _itemToAdd;

        return nextArray_;
    }

    /// @dev Helper to add an item to an array, only if it is not already in the array.
    function addUniqueItem(address[] memory _self, address _itemToAdd)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        if (contains(_self, _itemToAdd)) {
            return _self;
        }

        return addItem(_self, _itemToAdd);
    }

    /// @dev Helper to verify if an array contains a particular value
    function contains(address[] memory _self, address _target)
        internal
        pure
        returns (bool doesContain_)
    {
        for (uint256 i; i < _self.length; i++) {
            if (_target == _self[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Helper to merge the unique items of a second array.
    /// Does not consider uniqueness of either array, only relative uniqueness.
    /// Preserves ordering.
    function mergeArray(address[] memory _self, address[] memory _arrayToMerge)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        uint256 newUniqueItemCount;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                newUniqueItemCount++;
            }
        }

        if (newUniqueItemCount == 0) {
            return _self;
        }

        nextArray_ = new address[](_self.length + newUniqueItemCount);
        for (uint256 i; i < _self.length; i++) {
            nextArray_[i] = _self[i];
        }
        uint256 nextArrayIndex = _self.length;
        for (uint256 i; i < _arrayToMerge.length; i++) {
            if (!contains(_self, _arrayToMerge[i])) {
                nextArray_[nextArrayIndex] = _arrayToMerge[i];
                nextArrayIndex++;
            }
        }

        return nextArray_;
    }

    /// @dev Helper to verify if array is a set of unique values.
    /// Does not assert length > 0.
    function isUniqueSet(address[] memory _self) internal pure returns (bool isUnique_) {
        if (_self.length <= 1) {
            return true;
        }

        uint256 arrayLength = _self.length;
        for (uint256 i; i < arrayLength; i++) {
            for (uint256 j = i + 1; j < arrayLength; j++) {
                if (_self[i] == _self[j]) {
                    return false;
                }
            }
        }

        return true;
    }

    /// @dev Helper to remove items from an array. Removes all matching occurrences of each item.
    /// Does not assert uniqueness of either array.
    function removeItems(address[] memory _self, address[] memory _itemsToRemove)
        internal
        pure
        returns (address[] memory nextArray_)
    {
        if (_itemsToRemove.length == 0) {
            return _self;
        }

        bool[] memory indexesToRemove = new bool[](_self.length);
        uint256 remainingItemsCount = _self.length;
        for (uint256 i; i < _self.length; i++) {
            if (contains(_itemsToRemove, _self[i])) {
                indexesToRemove[i] = true;
                remainingItemsCount--;
            }
        }

        if (remainingItemsCount == _self.length) {
            nextArray_ = _self;
        } else if (remainingItemsCount > 0) {
            nextArray_ = new address[](remainingItemsCount);
            uint256 nextArrayIndex;
            for (uint256 i; i < _self.length; i++) {
                if (!indexesToRemove[i]) {
                    nextArray_[nextArrayIndex] = _self[i];
                    nextArrayIndex++;
                }
            }
        }

        return nextArray_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../vault/IVault.sol";

/// @title IComptroller Interface
/// @author Enzyme Council <[email protected]>
interface IComptroller {
    function activate(bool) external;

    function calcGav(bool) external returns (uint256);

    function calcGrossShareValue(bool) external returns (uint256);

    function callOnExtension(
        address,
        uint256,
        bytes calldata
    ) external;

    function configureExtensions(bytes calldata, bytes calldata) external;

    function destructActivated() external;

    function destructUnactivated() external;

    function getDenominationAsset() external view returns (address);

    function getExternalPositionManager() external view returns (address);

    function getFundDeployer() external view returns (address);

    function getGasRelayPaymaster() external view returns (address);

    function getIntegrationManager() external view returns (address);

    function getVaultProxy() external view returns (address);

    function init(address, uint256) external;

    function permissionedVaultAction(IVault.VaultAction, bytes calldata) external;

    function preTransferSharesHook(
        address,
        address,
        uint256
    ) external;

    function preTransferSharesHookFreelyTransferable(address) external view;

    function setGasRelayPaymaster(address) external;

    function setVaultProxy(address) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../persistent/vault/interfaces/IExternalPositionVault.sol";
import "../../../../persistent/vault/interfaces/IFreelyTransferableSharesVault.sol";
import "../../../../persistent/vault/interfaces/IMigratableVault.sol";

/// @title IVault Interface
/// @author Enzyme Council <[email protected]>
interface IVault is IMigratableVault, IFreelyTransferableSharesVault, IExternalPositionVault {
    enum VaultAction {
        None,
        // Shares management
        BurnShares,
        MintShares,
        TransferShares,
        // Asset management
        AddTrackedAsset,
        ApproveAssetSpender,
        RemoveTrackedAsset,
        WithdrawAssetTo,
        // External position management
        AddExternalPosition,
        CallOnExternalPosition,
        RemoveExternalPosition
    }

    function addTrackedAsset(address) external;

    function burnShares(address, uint256) external;

    function buyBackProtocolFeeShares(
        uint256,
        uint256,
        uint256
    ) external;

    function callOnContract(address, bytes calldata) external;

    function canManageAssets(address) external view returns (bool);

    function canRelayCalls(address) external view returns (bool);

    function getAccessor() external view returns (address);

    function getOwner() external view returns (address);

    function getActiveExternalPositions() external view returns (address[] memory);

    function getTrackedAssets() external view returns (address[] memory);

    function isActiveExternalPosition(address) external view returns (bool);

    function isTrackedAsset(address) external view returns (bool);

    function mintShares(address, uint256) external;

    function payProtocolFee() external;

    function receiveValidatedVaultAction(VaultAction, bytes calldata) external;

    function setAccessorForFundReconfiguration(address) external;

    function transferShares(
        address,
        address,
        uint256
    ) external;

    function withdrawAssetTo(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./VaultLibBaseCore.sol";

/// @title VaultLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice The first implementation of VaultLibBaseCore, with additional events and storage
/// @dev All subsequent implementations should inherit the previous implementation,
/// e.g., `VaultLibBase2 is VaultLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract VaultLibBase1 is VaultLibBaseCore {
    event AssetWithdrawn(address indexed asset, address indexed target, uint256 amount);

    event TrackedAssetAdded(address asset);

    event TrackedAssetRemoved(address asset);

    address[] internal trackedAssets;
    mapping(address => bool) internal assetToIsTracked;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./interfaces/IMigratableVault.sol";
import "./utils/ProxiableVaultLib.sol";
import "./utils/SharesTokenBase.sol";

/// @title VaultLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a VaultLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered VaultLibBaseXXX that inherits the previous base. See VaultLibBase1.
abstract contract VaultLibBaseCore is IMigratableVault, ProxiableVaultLib, SharesTokenBase {
    event AccessorSet(address prevAccessor, address nextAccessor);

    event MigratorSet(address prevMigrator, address nextMigrator);

    event OwnerSet(address prevOwner, address nextOwner);

    event VaultLibSet(address prevVaultLib, address nextVaultLib);

    address internal accessor;
    address internal creator;
    address internal migrator;
    address internal owner;

    // EXTERNAL FUNCTIONS

    /// @notice Initializes the VaultProxy with core configuration
    /// @param _owner The address to set as the fund owner
    /// @param _accessor The address to set as the permissioned accessor of the VaultLib
    /// @param _fundName The name of the fund
    /// @dev Serves as a per-proxy pseudo-constructor
    function init(
        address _owner,
        address _accessor,
        string calldata _fundName
    ) external override {
        require(creator == address(0), "init: Proxy already initialized");
        creator = msg.sender;
        sharesName = _fundName;

        __setAccessor(_accessor);
        __setOwner(_owner);

        emit VaultLibSet(address(0), getVaultLib());
    }

    /// @notice Sets the permissioned accessor of the VaultLib
    /// @param _nextAccessor The address to set as the permissioned accessor of the VaultLib
    function setAccessor(address _nextAccessor) external override {
        require(msg.sender == creator, "setAccessor: Only callable by the contract creator");

        __setAccessor(_nextAccessor);
    }

    /// @notice Sets the VaultLib target for the VaultProxy
    /// @param _nextVaultLib The address to set as the VaultLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextVaultLib from being the same as the current VaultLib
    function setVaultLib(address _nextVaultLib) external override {
        require(msg.sender == creator, "setVaultLib: Only callable by the contract creator");

        address prevVaultLib = getVaultLib();

        __updateCodeAddress(_nextVaultLib);

        emit VaultLibSet(prevVaultLib, _nextVaultLib);
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether an account is allowed to migrate the VaultProxy
    /// @param _who The account to check
    /// @return canMigrate_ True if the account is allowed to migrate the VaultProxy
    function canMigrate(address _who) public view virtual override returns (bool canMigrate_) {
        return _who == owner || _who == migrator;
    }

    /// @notice Gets the VaultLib target for the VaultProxy
    /// @return vaultLib_ The address of the VaultLib target
    function getVaultLib() public view returns (address vaultLib_) {
        assembly {
            // solium-disable-line
            vaultLib_ := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        return vaultLib_;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to set the permissioned accessor of the VaultProxy.
    /// Does not prevent the prevAccessor from being the _nextAccessor.
    function __setAccessor(address _nextAccessor) internal {
        require(_nextAccessor != address(0), "__setAccessor: _nextAccessor cannot be empty");
        address prevAccessor = accessor;

        accessor = _nextAccessor;

        emit AccessorSet(prevAccessor, _nextAccessor);
    }

    /// @dev Helper to set the owner of the VaultProxy
    function __setOwner(address _nextOwner) internal {
        require(_nextOwner != address(0), "__setOwner: _nextOwner cannot be empty");
        address prevOwner = owner;
        require(_nextOwner != prevOwner, "__setOwner: _nextOwner is the current owner");

        owner = _nextOwner;

        emit OwnerSet(prevOwner, _nextOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMigratableVault Interface
/// @author Enzyme Council <[email protected]>
/// @dev DO NOT EDIT CONTRACT
interface IMigratableVault {
    function canMigrate(address _who) external view returns (bool canMigrate_);

    function init(
        address _owner,
        address _accessor,
        string calldata _fundName
    ) external;

    function setAccessor(address _nextAccessor) external;

    function setVaultLib(address _nextVaultLib) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ProxiableVaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for VaultLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// Code position in storage is `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`,
/// which is "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc".
abstract contract ProxiableVaultLib {
    /// @dev Updates the target of the proxy to be the contract at _nextVaultLib
    function __updateCodeAddress(address _nextVaultLib) internal {
        require(
            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==
                ProxiableVaultLib(_nextVaultLib).proxiableUUID(),
            "__updateCodeAddress: _nextVaultLib not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _nextVaultLib
            )
        }
    }

    /// @notice Returns a unique bytes32 hash for VaultLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    /// @dev The UUID is `bytes32(keccak256('mln.proxiable.vaultlib'))`
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return 0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./VaultLibSafeMath.sol";

/// @title StandardERC20 Contract
/// @author Enzyme Council <[email protected]>
/// @notice Contains the storage, events, and default logic of an ERC20-compliant contract.
/// @dev The logic can be overridden by VaultLib implementations.
/// Adapted from OpenZeppelin 3.2.0.
/// DO NOT EDIT THIS CONTRACT.
abstract contract SharesTokenBase {
    using VaultLibSafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    string internal sharesName;
    string internal sharesSymbol;
    uint256 internal sharesTotalSupply;
    mapping(address => uint256) internal sharesBalances;
    mapping(address => mapping(address => uint256)) internal sharesAllowances;

    // EXTERNAL FUNCTIONS

    /// @dev Standard implementation of ERC20's approve(). Can be overridden.
    function approve(address _spender, uint256 _amount) public virtual returns (bool) {
        __approve(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev Standard implementation of ERC20's transfer(). Can be overridden.
    function transfer(address _recipient, uint256 _amount) public virtual returns (bool) {
        __transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /// @dev Standard implementation of ERC20's transferFrom(). Can be overridden.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual returns (bool) {
        __transfer(_sender, _recipient, _amount);
        __approve(
            _sender,
            msg.sender,
            sharesAllowances[_sender][msg.sender].sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // EXTERNAL FUNCTIONS - VIEW

    /// @dev Standard implementation of ERC20's allowance(). Can be overridden.
    function allowance(address _owner, address _spender) public view virtual returns (uint256) {
        return sharesAllowances[_owner][_spender];
    }

    /// @dev Standard implementation of ERC20's balanceOf(). Can be overridden.
    function balanceOf(address _account) public view virtual returns (uint256) {
        return sharesBalances[_account];
    }

    /// @dev Standard implementation of ERC20's decimals(). Can not be overridden.
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /// @dev Standard implementation of ERC20's name(). Can be overridden.
    function name() public view virtual returns (string memory) {
        return sharesName;
    }

    /// @dev Standard implementation of ERC20's symbol(). Can be overridden.
    function symbol() public view virtual returns (string memory) {
        return sharesSymbol;
    }

    /// @dev Standard implementation of ERC20's totalSupply(). Can be overridden.
    function totalSupply() public view virtual returns (uint256) {
        return sharesTotalSupply;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper for approve(). Can be overridden.
    function __approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        sharesAllowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /// @dev Helper to burn tokens from an account. Can be overridden.
    function __burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: burn from the zero address");

        sharesBalances[_account] = sharesBalances[_account].sub(
            _amount,
            "ERC20: burn amount exceeds balance"
        );
        sharesTotalSupply = sharesTotalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /// @dev Helper to mint tokens to an account. Can be overridden.
    function __mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        sharesTotalSupply = sharesTotalSupply.add(_amount);
        sharesBalances[_account] = sharesBalances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /// @dev Helper to transfer tokens between accounts. Can be overridden.
    function __transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        sharesBalances[_sender] = sharesBalances[_sender].sub(
            _amount,
            "ERC20: transfer amount exceeds balance"
        );
        sharesBalances[_recipient] = sharesBalances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title VaultLibSafeMath library
/// @notice A narrowed, verbatim implementation of OpenZeppelin 3.2.0 SafeMath
/// for use with VaultLib
/// @dev Preferred to importing from npm to guarantee consistent logic and revert reasons
/// between VaultLib implementations
/// DO NOT EDIT THIS CONTRACT
library VaultLibSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "VaultLibSafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "VaultLibSafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "VaultLibSafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "VaultLibSafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "VaultLibSafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "./IBeacon.sol";

pragma solidity 0.6.12;

/// @title IBeaconProxyFactory interface
/// @author Enzyme Council <[email protected]>
interface IBeaconProxyFactory is IBeacon {
    function deployProxy(bytes memory _constructData) external returns (address proxy_);

    function setCanonicalLib(address _canonicalLib) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../interfaces/IGsnPaymaster.sol";

/// @title IGasRelayPaymaster Interface
/// @author Enzyme Council <[email protected]>
interface IGasRelayPaymaster is IGsnPaymaster {
    function deposit() external;

    function withdrawBalance() external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IBeacon interface
/// @author Enzyme Council <[email protected]>
interface IBeacon {
    function getCanonicalLib() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IGsnTypes.sol";

/// @title IGsnPaymaster interface
/// @author Enzyme Council <[email protected]>
interface IGsnPaymaster {
    struct GasAndDataLimits {
        uint256 acceptanceBudget;
        uint256 preRelayedCallGasLimit;
        uint256 postRelayedCallGasLimit;
        uint256 calldataSizeLimit;
    }

    function getGasAndDataLimits() external view returns (GasAndDataLimits memory limits);

    function getHubAddr() external view returns (address);

    function getRelayHubDeposit() external view returns (uint256);

    function preRelayedCall(
        IGsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    ) external returns (bytes memory context, bool rejectOnRecipientRevert);

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        IGsnTypes.RelayData calldata relayData
    ) external;

    function trustedForwarder() external view returns (address);

    function versionPaymaster() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IGsnForwarder.sol";

/// @title IGsnTypes Interface
/// @author Enzyme Council <[email protected]>
interface IGsnTypes {
    struct RelayData {
        uint256 gasPrice;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    struct RelayRequest {
        IGsnForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IGsnForwarder interface
/// @author Enzyme Council <[email protected]>
interface IGsnForwarder {
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionVault interface
/// @author Enzyme Council <[email protected]>
/// Provides an interface to get the externalPositionLib for a given type from the Vault
interface IExternalPositionVault {
    function getExternalPositionLibForType(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFreelyTransferableSharesVault Interface
/// @author Enzyme Council <[email protected]>
/// @notice Provides the interface for determining whether a vault's shares
/// are guaranteed to be freely transferable.
/// @dev DO NOT EDIT CONTRACT
interface IFreelyTransferableSharesVault {
    function sharesAreFreelyTransferable()
        external
        view
        returns (bool sharesAreFreelyTransferable_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./IFeeManager.sol";

/// @title Fee Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all fees
interface IFee {
    function activateForFund(address _comptrollerProxy, address _vaultProxy) external;

    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData) external;

    function payout(address _comptrollerProxy, address _vaultProxy)
        external
        returns (bool isPayable_);

    function getRecipientForFund(address _comptrollerProxy)
        external
        view
        returns (address recipient_);

    function settle(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    )
        external
        returns (
            IFeeManager.SettlementType settlementType_,
            address payer_,
            uint256 sharesDue_
        );

    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        returns (bool settles_, bool usesGav_);

    function update(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    ) external;

    function updatesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        returns (bool updates_, bool usesGav_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title FeeManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the FeeManager
interface IFeeManager {
    // No fees for the current release are implemented post-redeemShares
    enum FeeHook {Continuous, PreBuyShares, PostBuyShares, PreRedeemShares}
    enum SettlementType {None, Direct, Mint, Burn, MintSharesOutstanding, BurnSharesOutstanding}

    function invokeHook(
        FeeHook,
        bytes calldata,
        uint256
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../persistent/dispatcher/IDispatcher.sol";
import "../../../../persistent/external-positions/IExternalPosition.sol";
import "../../../extensions/IExtension.sol";
import "../../../extensions/fee-manager/IFeeManager.sol";
import "../../../extensions/policy-manager/IPolicyManager.sol";
import "../../../infrastructure/asset-finality/IAssetFinalityResolver.sol";
import "../../../infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "../../../infrastructure/gas-relayer/IGasRelayPaymaster.sol";
import "../../../infrastructure/gas-relayer/IGasRelayPaymasterDepositor.sol";
import "../../../infrastructure/value-interpreter/IValueInterpreter.sol";
import "../../../utils/beacon-proxy/IBeaconProxyFactory.sol";
import "../../../utils/AddressArrayLib.sol";
import "../../fund-deployer/IFundDeployer.sol";
import "../vault/IVault.sol";
import "./IComptroller.sol";

/// @title ComptrollerLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core logic library shared by all funds
contract ComptrollerLib is IComptroller, IGasRelayPaymasterDepositor, GasRelayRecipientMixin {
    using AddressArrayLib for address[];
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event AutoProtocolFeeSharesBuybackSet(bool autoProtocolFeeSharesBuyback);

    event BuyBackMaxProtocolFeeSharesFailed(
        bytes failureReturnData,
        uint256 sharesAmount,
        uint256 buybackValueInMln,
        uint256 gav
    );
    event DeactivateFeeManagerFailed();

    event GasRelayPaymasterSet(address gasRelayPaymaster);

    event MigratedSharesDuePaid(uint256 sharesDue);

    event PayProtocolFeeDuringDestructFailed();

    event PreRedeemSharesHookFailed(
        bytes failureReturnData,
        address redeemer,
        uint256 sharesAmount
    );

    event RedeemSharesInKindCalcGavFailed();

    event SharesBought(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 sharesIssued,
        uint256 sharesReceived
    );

    event SharesRedeemed(
        address indexed redeemer,
        address indexed recipient,
        uint256 sharesAmount,
        address[] receivedAssets,
        uint256[] receivedAssetAmounts
    );

    event VaultProxySet(address vaultProxy);

    // Constants and immutables - shared by all proxies
    uint256 private constant ONE_HUNDRED_PERCENT = 10000;
    uint256 private constant SHARES_UNIT = 10**18;
    address private immutable ASSET_FINALITY_RESOLVER;
    address private immutable DISPATCHER;
    address private immutable EXTERNAL_POSITION_MANAGER;
    address private immutable FUND_DEPLOYER;
    address private immutable FEE_MANAGER;
    address private immutable INTEGRATION_MANAGER;
    address private immutable MLN_TOKEN;
    address private immutable POLICY_MANAGER;
    address private immutable PROTOCOL_FEE_RESERVE;
    address private immutable VALUE_INTERPRETER;
    address private immutable WETH_TOKEN;

    // Pseudo-constants (can only be set once)

    address internal denominationAsset;
    address internal vaultProxy;
    // True only for the one non-proxy
    bool internal isLib;

    // Storage

    // Attempts to buy back protocol fee shares immediately after collection
    bool internal autoProtocolFeeSharesBuyback;
    // A reverse-mutex, granting atomic permission for particular contracts to make vault calls
    bool internal permissionedVaultActionAllowed;
    // A mutex to protect against reentrancy
    bool internal reentranceLocked;
    // A timelock after the last time shares were bought for an account
    // that must expire before that account transfers or redeems their shares
    uint256 internal sharesActionTimelock;
    mapping(address => uint256) internal acctToLastSharesBoughtTimestamp;
    // The contract which manages paying gas relayers
    address private gasRelayPaymaster;

    ///////////////
    // MODIFIERS //
    ///////////////

    modifier allowsPermissionedVaultAction {
        __assertPermissionedVaultActionNotAllowed();
        permissionedVaultActionAllowed = true;
        _;
        permissionedVaultActionAllowed = false;
    }

    modifier locksReentrance() {
        __assertNotReentranceLocked();
        reentranceLocked = true;
        _;
        reentranceLocked = false;
    }

    modifier onlyFundDeployer() {
        __assertIsFundDeployer();
        _;
    }
    modifier onlyGasRelayPaymaster() {
        __assertIsGasRelayPaymaster();
        _;
    }

    modifier onlyOwner() {
        __assertIsOwner(__msgSender());
        _;
    }

    modifier onlyOwnerNotRelayable() {
        __assertIsOwner(msg.sender);
        _;
    }

    // ASSERTION HELPERS

    // Modifiers are inefficient in terms of contract size,
    // so we use helper functions to prevent repetitive inlining of expensive string values.

    function __assertIsFundDeployer() private view {
        require(msg.sender == getFundDeployer(), "Only FundDeployer callable");
    }

    function __assertIsGasRelayPaymaster() private view {
        require(msg.sender == getGasRelayPaymaster(), "Only Gas Relay Paymaster callable");
    }

    function __assertIsOwner(address _who) private view {
        require(_who == IVault(getVaultProxy()).getOwner(), "Only fund owner callable");
    }

    function __assertNotReentranceLocked() private view {
        require(!reentranceLocked, "Re-entrance");
    }

    function __assertPermissionedVaultActionNotAllowed() private view {
        require(!permissionedVaultActionAllowed, "Vault action re-entrance");
    }

    function __assertSharesActionNotTimelocked(address _vaultProxy, address _account)
        private
        view
    {
        uint256 lastSharesBoughtTimestamp = getLastSharesBoughtTimestampForAccount(_account);

        require(
            lastSharesBoughtTimestamp == 0 ||
                block.timestamp.sub(lastSharesBoughtTimestamp) >= getSharesActionTimelock() ||
                __hasPendingMigrationOrReconfiguration(_vaultProxy),
            "Shares action timelocked"
        );
    }

    constructor(
        address _dispatcher,
        address _protocolFeeReserve,
        address _fundDeployer,
        address _valueInterpreter,
        address _externalPositionManager,
        address _feeManager,
        address _integrationManager,
        address _policyManager,
        address _assetFinalityResolver,
        address _gasRelayPaymasterFactory,
        address _mlnToken,
        address _wethToken
    ) public GasRelayRecipientMixin(_gasRelayPaymasterFactory) {
        ASSET_FINALITY_RESOLVER = _assetFinalityResolver;
        DISPATCHER = _dispatcher;
        EXTERNAL_POSITION_MANAGER = _externalPositionManager;
        FEE_MANAGER = _feeManager;
        FUND_DEPLOYER = _fundDeployer;
        INTEGRATION_MANAGER = _integrationManager;
        MLN_TOKEN = _mlnToken;
        POLICY_MANAGER = _policyManager;
        PROTOCOL_FEE_RESERVE = _protocolFeeReserve;
        VALUE_INTERPRETER = _valueInterpreter;
        WETH_TOKEN = _wethToken;
        isLib = true;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Calls a specified action on an Extension
    /// @param _extension The Extension contract to call (e.g., FeeManager)
    /// @param _actionId An ID representing the action to take on the extension (see extension)
    /// @param _callArgs The encoded data for the call
    /// @dev Used to route arbitrary calls, so that msg.sender is the ComptrollerProxy
    /// (for access control). Uses a mutex of sorts that allows "permissioned vault actions"
    /// during calls originating from this function.
    function callOnExtension(
        address _extension,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external override locksReentrance allowsPermissionedVaultAction {
        require(
            _extension == getFeeManager() ||
                _extension == getIntegrationManager() ||
                _extension == getExternalPositionManager(),
            "callOnExtension: _extension invalid"
        );

        IExtension(_extension).receiveCallFromComptroller(__msgSender(), _actionId, _callArgs);
    }

    /// @notice Makes an arbitrary call with the VaultProxy contract as the sender
    /// @param _contract The contract to call
    /// @param _selector The selector to call
    /// @param _encodedArgs The encoded arguments for the call
    function vaultCallOnContract(
        address _contract,
        bytes4 _selector,
        bytes calldata _encodedArgs
    ) external onlyOwner {
        require(
            IFundDeployer(getFundDeployer()).isAllowedVaultCall(
                _contract,
                _selector,
                keccak256(_encodedArgs)
            ),
            "vaultCallOnContract: Not allowed"
        );

        IVault(getVaultProxy()).callOnContract(
            _contract,
            abi.encodePacked(_selector, _encodedArgs)
        );
    }

    /// @dev Helper to check if a VaultProxy has a pending migration or reconfiguration request
    function __hasPendingMigrationOrReconfiguration(address _vaultProxy)
        private
        view
        returns (bool hasPendingMigrationOrReconfiguration)
    {
        return
            IDispatcher(getDispatcher()).hasMigrationRequest(_vaultProxy) ||
            IFundDeployer(getFundDeployer()).hasReconfigurationRequest(_vaultProxy);
    }

    //////////////////
    // PROTOCOL FEE //
    //////////////////

    /// @notice Buys back shares collected as protocol fee at a discounted shares price, using MLN
    /// @param _sharesAmount The amount of shares to buy back
    function buyBackProtocolFeeShares(uint256 _sharesAmount) external {
        address vaultProxyCopy = vaultProxy;
        require(
            IVault(vaultProxyCopy).canManageAssets(__msgSender()),
            "buyBackProtocolFeeShares: Unauthorized"
        );

        uint256 gav = calcGav(true);

        IVault(vaultProxyCopy).buyBackProtocolFeeShares(
            _sharesAmount,
            __getBuybackValueInMln(vaultProxyCopy, _sharesAmount, gav),
            gav
        );
    }

    /// @notice Sets whether to attempt to buyback protocol fee shares immediately when collected
    /// @param _nextAutoProtocolFeeSharesBuyback True if protocol fee shares should be attempted
    /// to be bought back immediately when collected
    function setAutoProtocolFeeSharesBuyback(bool _nextAutoProtocolFeeSharesBuyback)
        external
        onlyOwner
    {
        autoProtocolFeeSharesBuyback = _nextAutoProtocolFeeSharesBuyback;

        emit AutoProtocolFeeSharesBuybackSet(_nextAutoProtocolFeeSharesBuyback);
    }

    /// @dev Helper to buyback the max available protocol fee shares, during an auto-buyback
    function __buyBackMaxProtocolFeeShares(address _vaultProxy, uint256 _gav) private {
        uint256 sharesAmount = ERC20(_vaultProxy).balanceOf(getProtocolFeeReserve());
        uint256 buybackValueInMln = __getBuybackValueInMln(_vaultProxy, sharesAmount, _gav);

        try
            IVault(_vaultProxy).buyBackProtocolFeeShares(sharesAmount, buybackValueInMln, _gav)
         {} catch (bytes memory reason) {
            emit BuyBackMaxProtocolFeeSharesFailed(reason, sharesAmount, buybackValueInMln, _gav);
        }
    }

    /// @dev Helper to buyback the max available protocol fee shares
    function __getBuybackValueInMln(
        address _vaultProxy,
        uint256 _sharesAmount,
        uint256 _gav
    ) private returns (uint256 buybackValueInMln_) {
        address denominationAssetCopy = getDenominationAsset();

        uint256 grossShareValue = __calcGrossShareValue(
            _gav,
            ERC20(_vaultProxy).totalSupply(),
            10**uint256(ERC20(denominationAssetCopy).decimals())
        );

        uint256 buybackValueInDenominationAsset = grossShareValue.mul(_sharesAmount).div(
            SHARES_UNIT
        );

        return
            IValueInterpreter(getValueInterpreter()).calcCanonicalAssetValue(
                denominationAssetCopy,
                buybackValueInDenominationAsset,
                getMlnToken()
            );
    }

    ////////////////////////////////
    // PERMISSIONED VAULT ACTIONS //
    ////////////////////////////////

    /// @notice Makes a permissioned, state-changing call on the VaultProxy contract
    /// @param _action The enum representing the VaultAction to perform on the VaultProxy
    /// @param _actionData The call data for the action to perform
    function permissionedVaultAction(IVault.VaultAction _action, bytes calldata _actionData)
        external
        override
    {
        __assertPermissionedVaultAction(msg.sender, _action);

        // Validate action as needed
        if (_action == IVault.VaultAction.RemoveTrackedAsset) {
            require(
                abi.decode(_actionData, (address)) != getDenominationAsset(),
                "permissionedVaultAction: Cannot untrack denomination asset"
            );
        }

        IVault(getVaultProxy()).receiveValidatedVaultAction(_action, _actionData);
    }

    /// @dev Helper to assert that a caller is allowed to perform a particular VaultAction.
    /// Uses this pattern rather than multiple `require` statements to save on contract size.
    function __assertPermissionedVaultAction(address _caller, IVault.VaultAction _action)
        private
        view
    {
        bool validAction;
        if (permissionedVaultActionAllowed) {
            // Calls are roughly ordered by likely frequency
            if (_caller == getIntegrationManager()) {
                if (
                    _action == IVault.VaultAction.AddTrackedAsset ||
                    _action == IVault.VaultAction.RemoveTrackedAsset ||
                    _action == IVault.VaultAction.WithdrawAssetTo ||
                    _action == IVault.VaultAction.ApproveAssetSpender
                ) {
                    validAction = true;
                }
            } else if (_caller == getFeeManager()) {
                if (
                    _action == IVault.VaultAction.MintShares ||
                    _action == IVault.VaultAction.BurnShares ||
                    _action == IVault.VaultAction.TransferShares
                ) {
                    validAction = true;
                }
            } else if (_caller == getExternalPositionManager()) {
                if (
                    _action == IVault.VaultAction.CallOnExternalPosition ||
                    _action == IVault.VaultAction.AddExternalPosition ||
                    _action == IVault.VaultAction.RemoveExternalPosition
                ) {
                    validAction = true;
                }
            }
        }

        require(validAction, "__assertPermissionedVaultAction: Action not allowed");
    }

    ///////////////
    // LIFECYCLE //
    ///////////////

    // Ordered by execution in the lifecycle

    /// @notice Initializes a fund with its core config
    /// @param _denominationAsset The asset in which the fund's value should be denominated
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @dev Pseudo-constructor per proxy.
    /// No need to assert access because this is called atomically on deployment,
    /// and once it's called, it cannot be called again.
    function init(address _denominationAsset, uint256 _sharesActionTimelock) external override {
        require(getDenominationAsset() == address(0), "init: Already initialized");
        require(
            IValueInterpreter(getValueInterpreter()).isSupportedPrimitiveAsset(_denominationAsset),
            "init: Bad denomination asset"
        );

        denominationAsset = _denominationAsset;
        sharesActionTimelock = _sharesActionTimelock;
    }

    /// @notice Configure the extensions of a fund
    /// @param _feeManagerConfigData Encoded config for fees to enable
    /// @param _policyManagerConfigData Encoded config for policies to enable
    /// @dev No need to assert anything beyond FundDeployer access.
    /// Called atomically with init(), but after ComptrollerLib has been deployed,
    /// giving access to its state and interface
    function configureExtensions(
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external override onlyFundDeployer {
        if (_feeManagerConfigData.length > 0) {
            IExtension(getFeeManager()).setConfigForFund(_feeManagerConfigData);
        }
        if (_policyManagerConfigData.length > 0) {
            IExtension(getPolicyManager()).setConfigForFund(_policyManagerConfigData);
        }
    }

    /// @notice Sets the VaultProxy
    /// @param _vaultProxy The VaultProxy contract
    /// @dev No need to assert anything beyond FundDeployer access.
    /// Called atomically with init(), but after ComptrollerLib and VaultLib have both been deployed.
    function setVaultProxy(address _vaultProxy) external override onlyFundDeployer {
        vaultProxy = _vaultProxy;

        emit VaultProxySet(_vaultProxy);
    }

    /// @notice Runs atomic logic after a ComptrollerProxy has become its vaultProxy's `accessor`
    /// @param _isMigration True if a migrated fund is being activated
    /// @dev No need to assert anything beyond FundDeployer access.
    function activate(bool _isMigration) external override onlyFundDeployer {
        address vaultProxyCopy = getVaultProxy();

        if (_isMigration) {
            // Distribute any shares in the VaultProxy to the fund owner.
            // This is a mechanism to ensure that even in the edge case of a fund being unable
            // to payout fee shares owed during migration, these shares are not lost.
            uint256 sharesDue = ERC20(vaultProxyCopy).balanceOf(vaultProxyCopy);
            if (sharesDue > 0) {
                IVault(vaultProxyCopy).transferShares(
                    vaultProxyCopy,
                    IVault(vaultProxyCopy).getOwner(),
                    sharesDue
                );

                emit MigratedSharesDuePaid(sharesDue);
            }
        }

        IVault(vaultProxyCopy).addTrackedAsset(getDenominationAsset());

        // Activate extensions
        IExtension(getExternalPositionManager()).activateForFund(_isMigration);
        IExtension(getFeeManager()).activateForFund(_isMigration);
        IExtension(getIntegrationManager()).activateForFund(_isMigration);
        IExtension(getPolicyManager()).activateForFund(_isMigration);
    }

    /// @notice Wind down and destroy a ComptrollerProxy that is active
    /// @dev No need to assert anything beyond FundDeployer access.
    /// Use the try/catch pattern throughout out of an abundance of caution,
    /// and forward limited gas to each call within.
    function destructActivated() external override onlyFundDeployer allowsPermissionedVaultAction {
        // Cost: 50k
        try IVault(getVaultProxy()).payProtocolFee{gas: 200000}()  {} catch {
            emit PayProtocolFeeDuringDestructFailed();
        }

        // Do not attempt to auto-buyback protocol fee shares in this case,
        // as the call is gav-dependent and can consume too much gas

        // Deactivate extensions only as-necessary

        // Pays out shares outstanding for fees.
        // Forward limited gas in case external call to fetch fee recipient eats gas
        // Base cost: 17k
        // Per fee that uses shares outstanding (default recipient): 33k
        // 300k accommodates up to 8 such fees
        try IExtension(getFeeManager()).deactivateForFund{gas: 300000}()  {} catch {
            emit DeactivateFeeManagerFailed();
        }

        __selfDestruct();
    }

    /// @notice Destroy a ComptrollerProxy that has not been activated
    function destructUnactivated() external override onlyFundDeployer {
        __selfDestruct();
    }

    /// @dev Helper to self-destruct the contract.
    /// There should never be ETH in the ComptrollerLib,
    /// so no need to waste gas to get the fund owner
    function __selfDestruct() private {
        // Not necessary, but failsafe to protect the lib against selfdestruct
        require(!isLib, "__selfDestruct: Only delegate callable");

        selfdestruct(payable(address(this)));
    }

    ////////////////
    // ACCOUNTING //
    ////////////////

    /// @notice Calculates the gross asset value (GAV) of the fund
    /// @param _finalizeAssets True if all assets must have exact final balances settled
    /// @return gav_ The fund GAV
    function calcGav(bool _finalizeAssets) public override returns (uint256 gav_) {
        address vaultProxyAddress = getVaultProxy();
        address[] memory assets = IVault(vaultProxyAddress).getTrackedAssets();
        address[] memory externalPositions = IVault(vaultProxyAddress)
            .getActiveExternalPositions();

        if (assets.length == 0 && externalPositions.length == 0) {
            return 0;
        }

        // It is not necessary to finalize assets in external positions, as synths will have
        // already been settled prior to transferring to the external position contract
        if (_finalizeAssets) {
            IAssetFinalityResolver(getAssetFinalityResolver()).finalizeAssets(
                vaultProxyAddress,
                assets
            );
        }

        uint256[] memory balances = new uint256[](assets.length);
        for (uint256 i; i < assets.length; i++) {
            balances[i] = ERC20(assets[i]).balanceOf(vaultProxyAddress);
        }

        gav_ = IValueInterpreter(getValueInterpreter()).calcCanonicalAssetsTotalValue(
            assets,
            balances,
            getDenominationAsset()
        );

        if (externalPositions.length > 0) {
            for (uint256 i; i < externalPositions.length; i++) {
                uint256 externalPositionValue = __calcExternalPositionValue(externalPositions[i]);

                gav_ = gav_.add(externalPositionValue);
            }
        }

        return gav_;
    }

    /// @notice Calculates the gross value of 1 unit of shares in the fund's denomination asset
    /// @param _requireFinality True if all assets must have exact final balances settled
    /// @return grossShareValue_ The amount of the denomination asset per share
    /// @dev Does not account for any fees outstanding.
    function calcGrossShareValue(bool _requireFinality)
        external
        override
        returns (uint256 grossShareValue_)
    {
        uint256 gav = calcGav(_requireFinality);

        grossShareValue_ = __calcGrossShareValue(
            gav,
            ERC20(getVaultProxy()).totalSupply(),
            10**uint256(ERC20(getDenominationAsset()).decimals())
        );

        return grossShareValue_;
    }

    // @dev Helper for calculating a external position value. Prevents from stack too deep
    function __calcExternalPositionValue(address _externalPosition)
        private
        returns (uint256 value_)
    {
        (
            address[] memory collateralAssets,
            uint256[] memory collateralBalances
        ) = IExternalPosition(_externalPosition).getManagedAssets();

        uint256 collateralValue = IValueInterpreter(getValueInterpreter())
            .calcCanonicalAssetsTotalValue(
            collateralAssets,
            collateralBalances,
            getDenominationAsset()
        );

        (address[] memory borrowedAssets, uint256[] memory borrowedBalances) = IExternalPosition(
            _externalPosition
        )
            .getDebtAssets();

        uint256 borrowedValue = IValueInterpreter(getValueInterpreter())
            .calcCanonicalAssetsTotalValue(
            borrowedAssets,
            borrowedBalances,
            getDenominationAsset()
        );

        if (collateralValue > borrowedValue) {
            value_ = collateralValue.sub(borrowedValue);
        }

        return value_;
    }

    /// @dev Helper for calculating the gross share value
    function __calcGrossShareValue(
        uint256 _gav,
        uint256 _sharesSupply,
        uint256 _denominationAssetUnit
    ) private pure returns (uint256 grossShareValue_) {
        if (_sharesSupply == 0) {
            return _denominationAssetUnit;
        }

        return _gav.mul(SHARES_UNIT).div(_sharesSupply);
    }

    ///////////////////
    // PARTICIPATION //
    ///////////////////

    // BUY SHARES

    /// @notice Buys shares on behalf of another user
    /// @param _buyer The account on behalf of whom to buy shares
    /// @param _investmentAmount The amount of the fund's denomination asset with which to buy shares
    /// @param _minSharesQuantity The minimum quantity of shares to buy
    /// @return sharesReceived_ The actual amount of shares received
    /// @dev This function is freely callable if there is no sharesActionTimelock set, but it is
    /// limited to a list of trusted callers otherwise, in order to prevent a griefing attack
    /// where the caller buys shares for a _buyer, thereby resetting their lastSharesBought value.
    function buySharesOnBehalf(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _minSharesQuantity
    ) external returns (uint256 sharesReceived_) {
        bool hasSharesActionTimelock = getSharesActionTimelock() > 0;
        address canonicalSender = __msgSender();

        require(
            !hasSharesActionTimelock ||
                IFundDeployer(getFundDeployer()).isAllowedBuySharesOnBehalfCaller(canonicalSender),
            "buySharesOnBehalf: Unauthorized"
        );

        return
            __buyShares(
                _buyer,
                _investmentAmount,
                _minSharesQuantity,
                hasSharesActionTimelock,
                canonicalSender
            );
    }

    /// @notice Buys shares
    /// @param _investmentAmount The amount of the fund's denomination asset
    /// with which to buy shares
    /// @param _minSharesQuantity The minimum quantity of shares to buy
    /// @return sharesReceived_ The actual amount of shares received
    function buyShares(uint256 _investmentAmount, uint256 _minSharesQuantity)
        external
        returns (uint256 sharesReceived_)
    {
        bool hasSharesActionTimelock = getSharesActionTimelock() > 0;
        address canonicalSender = __msgSender();

        return
            __buyShares(
                canonicalSender,
                _investmentAmount,
                _minSharesQuantity,
                hasSharesActionTimelock,
                canonicalSender
            );
    }

    /// @dev Helper for buy shares logic
    function __buyShares(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _minSharesQuantity,
        bool _hasSharesActionTimelock,
        address _canonicalSender
    ) private locksReentrance allowsPermissionedVaultAction returns (uint256 sharesReceived_) {
        // Enforcing a _minSharesQuantity also validates `_investmentAmount > 0`
        // and guarantees the function cannot succeed while minting 0 shares
        require(_minSharesQuantity > 0, "__buyShares: _minSharesQuantity must be >0");

        address vaultProxyCopy = getVaultProxy();
        require(
            !_hasSharesActionTimelock || !__hasPendingMigrationOrReconfiguration(vaultProxyCopy),
            "__buyShares: Pending migration or reconfiguration"
        );

        uint256 gav = calcGav(true);

        // Gives Extensions a chance to run logic prior to the minting of bought shares
        __preBuySharesHook(_buyer, _investmentAmount, gav);

        // Pay the protocol fee after running other fees, but before minting new shares
        IVault(vaultProxyCopy).payProtocolFee();
        if (doesAutoProtocolFeeSharesBuyback()) {
            __buyBackMaxProtocolFeeShares(vaultProxyCopy, gav);
        }

        // Calculate the amount of shares to issue with the investment amount
        address denominationAssetCopy = getDenominationAsset();
        uint256 sharePrice = __calcGrossShareValue(
            gav,
            ERC20(vaultProxyCopy).totalSupply(),
            10**uint256(ERC20(denominationAssetCopy).decimals())
        );
        uint256 sharesIssued = _investmentAmount.mul(SHARES_UNIT).div(sharePrice);

        // Mint shares to the buyer
        uint256 prevBuyerShares = ERC20(vaultProxyCopy).balanceOf(_buyer);
        IVault(vaultProxyCopy).mintShares(_buyer, sharesIssued);

        // Transfer the investment asset to the fund.
        // Does not follow the checks-effects-interactions pattern, but it is preferred
        // to have the final state of the VaultProxy prior to running __postBuySharesHook().
        ERC20(denominationAssetCopy).safeTransferFrom(
            _canonicalSender,
            vaultProxyCopy,
            _investmentAmount
        );

        // Gives Extensions a chance to run logic after shares are issued
        __postBuySharesHook(_buyer, _investmentAmount, sharesIssued, gav);

        // The number of actual shares received may differ from shares issued due to
        // how the PostBuyShares hooks are invoked by Extensions (i.e., fees)
        sharesReceived_ = ERC20(vaultProxyCopy).balanceOf(_buyer).sub(prevBuyerShares);
        require(
            sharesReceived_ >= _minSharesQuantity,
            "__buyShares: Shares received < _minSharesQuantity"
        );

        if (_hasSharesActionTimelock) {
            acctToLastSharesBoughtTimestamp[_buyer] = block.timestamp;
        }

        emit SharesBought(_buyer, _investmentAmount, sharesIssued, sharesReceived_);

        return sharesReceived_;
    }

    /// @dev Helper for Extension actions immediately prior to issuing shares
    function __preBuySharesHook(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _gav
    ) private {
        IFeeManager(getFeeManager()).invokeHook(
            IFeeManager.FeeHook.PreBuyShares,
            abi.encode(_buyer, _investmentAmount),
            _gav
        );
    }

    /// @dev Helper for Extension actions immediately after issuing shares.
    /// This could be cleaned up so both Extensions take the same encoded args and handle GAV
    /// in the same way, but there is not the obvious need for gas savings of recycling
    /// the GAV value for the current policies as there is for the fees.
    function __postBuySharesHook(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _sharesIssued,
        uint256 _preBuySharesGav
    ) private {
        uint256 gav = _preBuySharesGav.add(_investmentAmount);
        IFeeManager(getFeeManager()).invokeHook(
            IFeeManager.FeeHook.PostBuyShares,
            abi.encode(_buyer, _investmentAmount, _sharesIssued),
            gav
        );

        IPolicyManager(getPolicyManager()).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.PostBuyShares,
            abi.encode(_buyer, _investmentAmount, _sharesIssued, gav)
        );
    }

    // REDEEM SHARES

    /// @notice Redeems a specified amount of the sender's shares for specified asset proportions
    /// @param _recipient The account that will receive the specified assets
    /// @param _sharesQuantity The quantity of shares to redeem
    /// @param _payoutAssets The assets to payout
    /// @param _payoutAssetPercentages The percentage of the owed amount to pay out in each asset
    /// @return payoutAmounts_ The amount of each asset paid out to the _recipient
    /// @dev Redeem all shares of the sender by setting _sharesQuantity to the max uint value.
    /// _payoutAssetPercentages must total exactly 100%. In order to specify less and forgo the
    /// remaining gav owed on the redeemed shares, pass in address(0) with the percentage to forego.
    /// Unlike redeemSharesInKind(), this function allows policies to run and prevent redemption.
    function redeemSharesForSpecificAssets(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _payoutAssets,
        uint256[] calldata _payoutAssetPercentages
    ) external locksReentrance returns (uint256[] memory payoutAmounts_) {
        address canonicalSender = __msgSender();
        require(
            _payoutAssets.length == _payoutAssetPercentages.length,
            "redeemSharesForSpecificAssets: Unequal arrays"
        );
        require(
            _payoutAssets.isUniqueSet(),
            "redeemSharesForSpecificAssets: Duplicate payout asset"
        );

        uint256 gav = calcGav(true);

        IVault vaultProxyContract = IVault(getVaultProxy());
        (uint256 sharesToRedeem, uint256 sharesSupply) = __redeemSharesSetup(
            vaultProxyContract,
            canonicalSender,
            _sharesQuantity,
            true,
            gav
        );

        payoutAmounts_ = __payoutSpecifiedAssetPercentages(
            vaultProxyContract,
            _recipient,
            _payoutAssets,
            _payoutAssetPercentages,
            gav.mul(sharesToRedeem).div(sharesSupply)
        );

        // Run post-redemption in order to have access to the payoutAmounts
        __postRedeemSharesForSpecificAssetsHook(
            canonicalSender,
            _recipient,
            sharesToRedeem,
            _payoutAssets,
            payoutAmounts_,
            gav
        );

        emit SharesRedeemed(
            canonicalSender,
            _recipient,
            sharesToRedeem,
            _payoutAssets,
            payoutAmounts_
        );

        return payoutAmounts_;
    }

    /// @notice Redeems a specified amount of the sender's shares
    /// for a proportionate slice of the vault's assets
    /// @param _recipient The account that will receive the proportionate slice of assets
    /// @param _sharesQuantity The quantity of shares to redeem
    /// @param _additionalAssets Additional (non-tracked) assets to claim
    /// @param _assetsToSkip Tracked assets to forfeit
    /// @return payoutAssets_ The assets paid out to the _recipient
    /// @return payoutAmounts_ The amount of each asset paid out to the _recipient
    /// @dev Redeem all shares of the sender by setting _sharesQuantity to the max uint value.
    /// Any claim to passed _assetsToSkip will be forfeited entirely. This should generally
    /// only be exercised if a bad asset is causing redemption to fail.
    /// This function should never fail without a way to bypass the failure, which is assured
    /// through two mechanisms:
    /// 1. The FeeManager is called with the try/catch pattern to assure that calls to it
    /// can never block redemption.
    /// 2. If a token fails upon transfer(), that token can be skipped (and its balance forfeited)
    /// by explicitly specifying _assetsToSkip.
    /// Because of these assurances, shares should always be redeemable, with the exception
    /// of the timelock period on shares actions that must be respected.
    function redeemSharesInKind(
        address _recipient,
        uint256 _sharesQuantity,
        address[] calldata _additionalAssets,
        address[] calldata _assetsToSkip
    )
        external
        locksReentrance
        returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_)
    {
        address canonicalSender = __msgSender();
        require(
            _additionalAssets.isUniqueSet(),
            "redeemSharesInKind: _additionalAssets contains duplicates"
        );
        require(
            _assetsToSkip.isUniqueSet(),
            "redeemSharesInKind: _assetsToSkip contains duplicates"
        );

        // Parse the payout assets given optional params to add or skip assets.
        // Note that there is no validation that the _additionalAssets are known assets to
        // the protocol. This means that the redeemer could specify a malicious asset,
        // but since all state-changing, user-callable functions on this contract share the
        // non-reentrant modifier, there is nowhere to perform a reentrancy attack.
        payoutAssets_ = __parseRedemptionPayoutAssets(
            IVault(vaultProxy).getTrackedAssets(),
            _additionalAssets,
            _assetsToSkip
        );

        // Resolve finality of all assets as needed.
        // Run this prior to calculating GAV.
        IAssetFinalityResolver(getAssetFinalityResolver()).finalizeAssets(
            vaultProxy,
            payoutAssets_
        );

        // If protocol fee shares will be auto-bought back, attempt to calculate GAV to pass into fees,
        // as we will require GAV later during the buyback.
        uint256 gavOrZero;
        if (doesAutoProtocolFeeSharesBuyback()) {
            // Since GAV calculation can fail with a revering price or a no-longer-supported asset,
            // we must try/catch GAV calculation to ensure that in-kind redemption can still succeed
            try this.calcGav(false) returns (uint256 gav) {
                gavOrZero = gav;
            } catch {
                emit RedeemSharesInKindCalcGavFailed();
            }
        }

        (uint256 sharesToRedeem, uint256 sharesSupply) = __redeemSharesSetup(
            IVault(vaultProxy),
            canonicalSender,
            _sharesQuantity,
            false,
            gavOrZero
        );

        // Calculate and transfer payout asset amounts due to _recipient
        payoutAmounts_ = new uint256[](payoutAssets_.length);
        for (uint256 i; i < payoutAssets_.length; i++) {
            payoutAmounts_[i] = ERC20(payoutAssets_[i])
                .balanceOf(vaultProxy)
                .mul(sharesToRedeem)
                .div(sharesSupply);

            // Transfer payout asset to _recipient
            if (payoutAmounts_[i] > 0) {
                IVault(vaultProxy).withdrawAssetTo(
                    payoutAssets_[i],
                    _recipient,
                    payoutAmounts_[i]
                );
            }
        }

        emit SharesRedeemed(
            canonicalSender,
            _recipient,
            sharesToRedeem,
            payoutAssets_,
            payoutAmounts_
        );

        return (payoutAssets_, payoutAmounts_);
    }

    /// @dev Helper to parse an array of payout assets during redemption, taking into account
    /// additional assets and assets to skip. _assetsToSkip ignores _additionalAssets.
    /// All input arrays are assumed to be unique.
    function __parseRedemptionPayoutAssets(
        address[] memory _trackedAssets,
        address[] memory _additionalAssets,
        address[] memory _assetsToSkip
    ) private pure returns (address[] memory payoutAssets_) {
        address[] memory trackedAssetsToPayout = _trackedAssets.removeItems(_assetsToSkip);
        if (_additionalAssets.length == 0) {
            return trackedAssetsToPayout;
        }

        // Add additional assets. Duplicates of trackedAssets are ignored.
        bool[] memory indexesToAdd = new bool[](_additionalAssets.length);
        uint256 additionalItemsCount;
        for (uint256 i; i < _additionalAssets.length; i++) {
            if (!trackedAssetsToPayout.contains(_additionalAssets[i])) {
                indexesToAdd[i] = true;
                additionalItemsCount++;
            }
        }
        if (additionalItemsCount == 0) {
            return trackedAssetsToPayout;
        }

        payoutAssets_ = new address[](trackedAssetsToPayout.length.add(additionalItemsCount));
        for (uint256 i; i < trackedAssetsToPayout.length; i++) {
            payoutAssets_[i] = trackedAssetsToPayout[i];
        }
        uint256 payoutAssetsIndex = trackedAssetsToPayout.length;
        for (uint256 i; i < _additionalAssets.length; i++) {
            if (indexesToAdd[i]) {
                payoutAssets_[payoutAssetsIndex] = _additionalAssets[i];
                payoutAssetsIndex++;
            }
        }

        return payoutAssets_;
    }

    /// @dev Helper to payout specified asset percentages during redeemSharesForSpecificAssets()
    function __payoutSpecifiedAssetPercentages(
        IVault vaultProxyContract,
        address _recipient,
        address[] calldata _payoutAssets,
        uint256[] calldata _payoutAssetPercentages,
        uint256 _owedGav
    ) private returns (uint256[] memory payoutAmounts_) {
        address denominationAssetCopy = getDenominationAsset();
        uint256 percentagesTotal;
        payoutAmounts_ = new uint256[](_payoutAssets.length);
        for (uint256 i; i < _payoutAssets.length; i++) {
            percentagesTotal = percentagesTotal.add(_payoutAssetPercentages[i]);

            // Used to explicitly specify less than 100% in total _payoutAssetPercentages
            if (_payoutAssets[i] == address(0)) {
                continue;
            }

            payoutAmounts_[i] = IValueInterpreter(getValueInterpreter()).calcCanonicalAssetValue(
                denominationAssetCopy,
                _owedGav.mul(_payoutAssetPercentages[i]).div(ONE_HUNDRED_PERCENT),
                _payoutAssets[i]
            );

            vaultProxyContract.withdrawAssetTo(_payoutAssets[i], _recipient, payoutAmounts_[i]);
        }

        require(
            percentagesTotal == ONE_HUNDRED_PERCENT,
            "__payoutSpecifiedAssetPercentages: Percents must total 100%"
        );

        return payoutAmounts_;
    }

    /// @dev Helper for system actions immediately prior to redeeming shares.
    /// Policy validation is not currently allowed on redemption, to ensure continuous redeemability.
    function __preRedeemSharesHook(
        address _redeemer,
        uint256 _sharesToRedeem,
        bool _forSpecifiedAssets,
        uint256 _gavIfCalculated
    ) private allowsPermissionedVaultAction {
        try
            IFeeManager(getFeeManager()).invokeHook(
                IFeeManager.FeeHook.PreRedeemShares,
                abi.encode(_redeemer, _sharesToRedeem, _forSpecifiedAssets),
                _gavIfCalculated
            )
         {} catch (bytes memory reason) {
            emit PreRedeemSharesHookFailed(reason, _redeemer, _sharesToRedeem);
        }
    }

    /// @dev Helper to run policy validation after other logic for redeeming shares for specific assets.
    /// Avoids stack-too-deep error.
    function __postRedeemSharesForSpecificAssetsHook(
        address _redeemer,
        address _recipient,
        uint256 _sharesToRedeemPostFees,
        address[] memory _assets,
        uint256[] memory _assetAmounts,
        uint256 _gavPreRedeem
    ) private {
        IPolicyManager(getPolicyManager()).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.RedeemSharesForSpecificAssets,
            abi.encode(
                _redeemer,
                _recipient,
                _sharesToRedeemPostFees,
                _assets,
                _assetAmounts,
                _gavPreRedeem
            )
        );
    }

    /// @dev Helper to execute common pre-shares redemption logic
    function __redeemSharesSetup(
        IVault vaultProxyContract,
        address _redeemer,
        uint256 _sharesQuantityInput,
        bool _forSpecifiedAssets,
        uint256 _gavIfCalculated
    ) private returns (uint256 sharesToRedeem_, uint256 sharesSupply_) {
        __assertSharesActionNotTimelocked(address(vaultProxyContract), _redeemer);

        ERC20 sharesContract = ERC20(address(vaultProxyContract));

        uint256 preFeesRedeemerSharesBalance = sharesContract.balanceOf(_redeemer);

        if (_sharesQuantityInput == type(uint256).max) {
            sharesToRedeem_ = preFeesRedeemerSharesBalance;
        } else {
            sharesToRedeem_ = _sharesQuantityInput;
        }
        require(sharesToRedeem_ > 0, "__redeemSharesSetup: No shares to redeem");

        __preRedeemSharesHook(_redeemer, sharesToRedeem_, _forSpecifiedAssets, _gavIfCalculated);

        // Update the redemption amount if fees were charged (or accrued) to the redeemer
        uint256 postFeesRedeemerSharesBalance = sharesContract.balanceOf(_redeemer);
        if (_sharesQuantityInput == type(uint256).max) {
            sharesToRedeem_ = postFeesRedeemerSharesBalance;
        } else if (postFeesRedeemerSharesBalance < preFeesRedeemerSharesBalance) {
            sharesToRedeem_ = sharesToRedeem_.sub(
                preFeesRedeemerSharesBalance.sub(postFeesRedeemerSharesBalance)
            );
        }

        // Pay the protocol fee after running other fees, but before burning shares
        vaultProxyContract.payProtocolFee();

        if (_gavIfCalculated > 0 && doesAutoProtocolFeeSharesBuyback()) {
            __buyBackMaxProtocolFeeShares(address(vaultProxyContract), _gavIfCalculated);
        }

        // Destroy the shares after getting the shares supply
        sharesSupply_ = sharesContract.totalSupply();
        vaultProxyContract.burnShares(_redeemer, sharesToRedeem_);

        return (sharesToRedeem_, sharesSupply_);
    }

    // TRANSFER SHARES

    /// @notice Runs logic prior to transferring shares that are not freely transferable
    /// @param _sender The sender of the shares
    /// @param _recipient The recipient of the shares
    /// @param _amount The amount of shares
    function preTransferSharesHook(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override {
        address vaultProxyCopy = getVaultProxy();
        require(msg.sender == vaultProxyCopy, "preTransferSharesHook: Only VaultProxy callable");
        __assertSharesActionNotTimelocked(vaultProxyCopy, _sender);

        IPolicyManager(getPolicyManager()).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.PreTransferShares,
            abi.encode(_sender, _recipient, _amount)
        );
    }

    /// @notice Runs logic prior to transferring shares that are freely transferable
    /// @param _sender The sender of the shares
    /// @dev No need to validate caller, as policies are not run
    function preTransferSharesHookFreelyTransferable(address _sender) external view override {
        __assertSharesActionNotTimelocked(getVaultProxy(), _sender);
    }

    /////////////////
    // GAS RELAYER //
    /////////////////

    /// @notice Deploys a paymaster contract and deposits WETH, enabling gas relaying
    function deployGasRelayPaymaster() external onlyOwnerNotRelayable {
        require(
            getGasRelayPaymaster() == address(0),
            "deployGasRelayPaymaster: Paymaster already deployed"
        );

        bytes memory constructData = abi.encodeWithSignature("init(address)", getVaultProxy());
        address paymaster = IBeaconProxyFactory(getGasRelayPaymasterFactory()).deployProxy(
            constructData
        );

        __setGasRelayPaymaster(paymaster);

        __depositToGasRelayPaymaster(paymaster);
    }

    /// @notice Tops up the gas relay paymaster deposit
    function depositToGasRelayPaymaster() external onlyOwner {
        __depositToGasRelayPaymaster(getGasRelayPaymaster());
    }

    /// @notice Pull WETH from vault to gas relay paymaster
    /// @param _amount Amount of the WETH to pull from the vault
    function pullWethForGasRelayer(uint256 _amount) external override onlyGasRelayPaymaster {
        IVault(getVaultProxy()).withdrawAssetTo(getWethToken(), getGasRelayPaymaster(), _amount);
    }

    /// @notice Sets the gasRelayPaymaster variable value
    /// @param _nextGasRelayPaymaster The next gasRelayPaymaster value
    function setGasRelayPaymaster(address _nextGasRelayPaymaster)
        external
        override
        onlyFundDeployer
    {
        __setGasRelayPaymaster(_nextGasRelayPaymaster);
    }

    /// @notice Removes the gas relay paymaster, withdrawing the remaining WETH balance
    /// and disabling gas relaying
    function shutdownGasRelayPaymaster() external onlyOwnerNotRelayable {
        IGasRelayPaymaster(gasRelayPaymaster).withdrawBalance();

        delete gasRelayPaymaster;

        emit GasRelayPaymasterSet(address(0));
    }

    /// @dev Helper to deposit to the gas relay paymaster
    function __depositToGasRelayPaymaster(address _paymaster) private {
        IGasRelayPaymaster(_paymaster).deposit();
    }

    /// @dev Helper to set the next `gasRelayPaymaster` variable
    function __setGasRelayPaymaster(address _nextGasRelayPaymaster) private {
        gasRelayPaymaster = _nextGasRelayPaymaster;

        emit GasRelayPaymasterSet(_nextGasRelayPaymaster);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // LIB IMMUTABLES

    /// @notice Gets the `ASSET_FINALITY_RESOLVER` variable
    /// @return assetFinalityResolver_ The `ASSET_FINALITY_RESOLVER` variable value
    function getAssetFinalityResolver() public view returns (address assetFinalityResolver_) {
        return ASSET_FINALITY_RESOLVER;
    }

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the `EXTERNAL_POSITION_MANAGER` variable
    /// @return externalPositionManager_ The `EXTERNAL_POSITION_MANAGER` variable value
    function getExternalPositionManager()
        public
        view
        override
        returns (address externalPositionManager_)
    {
        return EXTERNAL_POSITION_MANAGER;
    }

    /// @notice Gets the `FEE_MANAGER` variable
    /// @return feeManager_ The `FEE_MANAGER` variable value
    function getFeeManager() public view returns (address feeManager_) {
        return FEE_MANAGER;
    }

    /// @notice Gets the `FUND_DEPLOYER` variable
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    function getFundDeployer() public view override returns (address fundDeployer_) {
        return FUND_DEPLOYER;
    }

    /// @notice Gets the `INTEGRATION_MANAGER` variable
    /// @return integrationManager_ The `INTEGRATION_MANAGER` variable value
    function getIntegrationManager() public view override returns (address integrationManager_) {
        return INTEGRATION_MANAGER;
    }

    /// @notice Gets the `MLN_TOKEN` variable
    /// @return mlnToken_ The `MLN_TOKEN` variable value
    function getMlnToken() public view returns (address mlnToken_) {
        return MLN_TOKEN;
    }

    /// @notice Gets the `POLICY_MANAGER` variable
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() public view returns (address policyManager_) {
        return POLICY_MANAGER;
    }

    /// @notice Gets the `PROTOCOL_FEE_RESERVE` variable
    /// @return protocolFeeReserve_ The `PROTOCOL_FEE_RESERVE` variable value
    function getProtocolFeeReserve() public view returns (address protocolFeeReserve_) {
        return PROTOCOL_FEE_RESERVE;
    }

    /// @notice Gets the `VALUE_INTERPRETER` variable
    /// @return valueInterpreter_ The `VALUE_INTERPRETER` variable value
    function getValueInterpreter() public view returns (address valueInterpreter_) {
        return VALUE_INTERPRETER;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }

    // PROXY STORAGE

    /// @notice Checks if collected protocol fee shares are automatically bought back
    /// while buying or redeeming shares
    /// @return doesAutoBuyback_ True if shares are automatically bought back
    function doesAutoProtocolFeeSharesBuyback() public view returns (bool doesAutoBuyback_) {
        return autoProtocolFeeSharesBuyback;
    }

    /// @notice Gets the `denominationAsset` variable
    /// @return denominationAsset_ The `denominationAsset` variable value
    function getDenominationAsset() public view override returns (address denominationAsset_) {
        return denominationAsset;
    }

    /// @notice Gets the `gasRelayPaymaster` variable
    /// @return gasRelayPaymaster_ The `gasRelayPaymaster` variable value
    function getGasRelayPaymaster() public view override returns (address gasRelayPaymaster_) {
        return gasRelayPaymaster;
    }

    /// @notice Gets the timestamp of the last time shares were bought for a given account
    /// @param _who The account for which to get the timestamp
    /// @return lastSharesBoughtTimestamp_ The timestamp of the last shares bought
    function getLastSharesBoughtTimestampForAccount(address _who)
        public
        view
        returns (uint256 lastSharesBoughtTimestamp_)
    {
        return acctToLastSharesBoughtTimestamp[_who];
    }

    /// @notice Gets the `sharesActionTimelock` variable
    /// @return sharesActionTimelock_ The `sharesActionTimelock` variable value
    function getSharesActionTimelock() public view returns (uint256 sharesActionTimelock_) {
        return sharesActionTimelock;
    }

    /// @notice Gets the `vaultProxy` variable
    /// @return vaultProxy_ The `vaultProxy` variable value
    function getVaultProxy() public view override returns (address vaultProxy_) {
        return vaultProxy;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title SettableFeeRecipientBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract to set and get a fee recipient for the inheriting fee
abstract contract SettableFeeRecipientBase {
    event RecipientSetForFund(address indexed comptrollerProxy, address indexed recipient);

    mapping(address => address) private comptrollerProxyToRecipient;

    /// @dev Helper to set a fee recipient
    function __setRecipientForFund(address _comptrollerProxy, address _recipient) internal {
        comptrollerProxyToRecipient[_comptrollerProxy] = _recipient;

        emit RecipientSetForFund(_comptrollerProxy, _recipient);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the recipient of the fee for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return recipient_ The recipient
    /// @dev address(0) signifies the VaultProxy owner
    function getRecipientForFund(address _comptrollerProxy)
        public
        view
        virtual
        returns (address recipient_)
    {
        return comptrollerProxyToRecipient[_comptrollerProxy];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExtension Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all extensions
interface IExtension {
    function activateForFund(bool _isMigration) external;

    function deactivateForFund() external;

    function receiveCallFromComptroller(
        address _comptrollerProxy,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external;

    function setConfigForFund(bytes calldata _configData) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title PolicyManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the PolicyManager
interface IPolicyManager {
    // When updating PolicyHook, also update these functions in PolicyManager:
    // 1. __getAllPolicyHooks()
    // 2. __policyHookRestrictsCurrentInvestorActions()
    enum PolicyHook {
        PostBuyShares,
        PostCallOnIntegration,
        PreTransferShares,
        RedeemSharesForSpecificAssets,
        AddTrackedAssets,
        RemoveTrackedAssets,
        CreateExternalPosition,
        PostCallOnExternalPosition,
        RemoveExternalPosition,
        ReactivateExternalPosition
    }

    function validatePolicies(
        address,
        PolicyHook,
        bytes calldata
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAssetFinalityResolver Interface
/// @author Enzyme Council <[email protected]>
interface IAssetFinalityResolver {
    function finalizeAssets(address, address[] calldata) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IGasRelayPaymasterDepositor Interface
/// @author Enzyme Council <[email protected]>
interface IGasRelayPaymasterDepositor {
    function pullWethForGasRelayer(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/extensions/fee-manager/fees/utils/UpdatableFeeRecipientBase.sol";

/// @title TestUpdatableFeeRecipientBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A test implementation of UpdatableFeeRecipientBase
contract TestUpdatableFeeRecipientBase is UpdatableFeeRecipientBase {

}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../core/fund/comptroller/ComptrollerLib.sol";
import "../FeeManager.sol";
import "./utils/FeeBase.sol";
import "./utils/UpdatableFeeRecipientBase.sol";

/// @title PerformanceFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice A performance-based fee with configurable rate and crystallization period, using
/// a high watermark
/// @dev This contract assumes that all shares in the VaultProxy are shares outstanding,
/// which is fine for this release. Even if they are not, they are still shares that
/// are only claimable by the fund owner.
contract PerformanceFee is FeeBase, UpdatableFeeRecipientBase {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    event ActivatedForFund(address indexed comptrollerProxy, uint256 highWaterMark);

    event FundSettingsAdded(address indexed comptrollerProxy, uint256 rate, uint256 period);

    event LastSharePriceUpdated(
        address indexed comptrollerProxy,
        uint256 prevSharePrice,
        uint256 nextSharePrice
    );

    event PaidOut(
        address indexed comptrollerProxy,
        uint256 prevHighWaterMark,
        uint256 nextHighWaterMark,
        uint256 aggregateValueDue
    );

    event PerformanceUpdated(
        address indexed comptrollerProxy,
        uint256 prevAggregateValueDue,
        uint256 nextAggregateValueDue,
        int256 sharesOutstandingDiff
    );

    struct FeeInfo {
        uint256 rate;
        uint256 period;
        uint256 activated;
        uint256 lastPaid;
        uint256 highWaterMark;
        uint256 lastSharePrice;
        uint256 aggregateValueDue;
    }

    uint256 private constant ONE_HUNDRED_PERCENT = 10000;
    uint256 private constant SHARE_UNIT = 10**18;

    mapping(address => FeeInfo) private comptrollerProxyToFeeInfo;

    constructor(address _feeManager) public FeeBase(_feeManager) {}

    // EXTERNAL FUNCTIONS

    /// @notice Activates the fee for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    function activateForFund(address _comptrollerProxy, address) external override onlyFeeManager {
        FeeInfo storage feeInfo = comptrollerProxyToFeeInfo[_comptrollerProxy];

        // We must not force asset finality, otherwise funds that have Synths as tracked assets
        // would be susceptible to a DoS attack when attempting to migrate to a release that uses
        // this fee: an attacker trades a negligible amount of a tracked Synth with the VaultProxy
        // as the recipient, thus causing `calcGrossShareValue(true)` to fail.
        uint256 grossSharePrice = ComptrollerLib(_comptrollerProxy).calcGrossShareValue(false);

        feeInfo.highWaterMark = grossSharePrice;
        feeInfo.lastSharePrice = grossSharePrice;
        feeInfo.activated = block.timestamp;

        emit ActivatedForFund(_comptrollerProxy, grossSharePrice);
    }

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    /// @dev `highWaterMark`, `lastSharePrice`, and `activated` are set during activation
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        external
        override
        onlyFeeManager
    {
        (uint256 feeRate, uint256 feePeriod, address recipient) = abi.decode(
            _settingsData,
            (uint256, uint256, address)
        );
        require(feeRate > 0, "addFundSettings: feeRate must be greater than 0");
        // Unlike most other fees, there could be a case for using a rate of exactly 100%,
        // i.e., pay out all profits to a specified recipient
        require(feeRate <= ONE_HUNDRED_PERCENT, "addFundSettings: feeRate max exceeded");
        require(feePeriod > 0, "addFundSettings: feePeriod must be greater than 0");

        comptrollerProxyToFeeInfo[_comptrollerProxy] = FeeInfo({
            rate: feeRate,
            period: feePeriod,
            activated: 0,
            lastPaid: 0,
            highWaterMark: 0,
            lastSharePrice: 0,
            aggregateValueDue: 0
        });

        emit FundSettingsAdded(_comptrollerProxy, feeRate, feePeriod);

        if (recipient != address(0)) {
            __setRecipientForFund(_comptrollerProxy, recipient);
        }
    }

    /// @notice Checks whether the shares outstanding for the fee can be paid out, and updates
    /// the info for the fee's last payout
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return isPayable_ True if shares outstanding can be paid out
    function payout(address _comptrollerProxy, address)
        external
        override
        onlyFeeManager
        returns (bool isPayable_)
    {
        if (!payoutAllowed(_comptrollerProxy)) {
            return false;
        }

        FeeInfo storage feeInfo = comptrollerProxyToFeeInfo[_comptrollerProxy];
        feeInfo.lastPaid = block.timestamp;

        uint256 prevHighWaterMark = feeInfo.highWaterMark;
        uint256 nextHighWaterMark = __calcUint256Max(feeInfo.lastSharePrice, prevHighWaterMark);
        uint256 prevAggregateValueDue = feeInfo.aggregateValueDue;

        // Update state as necessary
        if (prevAggregateValueDue > 0) {
            feeInfo.aggregateValueDue = 0;
        }
        if (nextHighWaterMark > prevHighWaterMark) {
            feeInfo.highWaterMark = nextHighWaterMark;
        }

        emit PaidOut(
            _comptrollerProxy,
            prevHighWaterMark,
            nextHighWaterMark,
            prevAggregateValueDue
        );

        return true;
    }

    /// @notice Settles the fee and calculates shares due
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _gav The GAV of the fund
    /// @return settlementType_ The type of settlement
    /// @return (unused) The payer of shares due
    /// @return sharesDue_ The amount of shares due
    function settle(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook,
        bytes calldata,
        uint256 _gav
    )
        external
        override
        onlyFeeManager
        returns (
            IFeeManager.SettlementType settlementType_,
            address,
            uint256 sharesDue_
        )
    {
        if (_gav == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        int256 settlementSharesDue = __settleAndUpdatePerformance(
            _comptrollerProxy,
            _vaultProxy,
            _gav
        );
        if (settlementSharesDue == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        } else if (settlementSharesDue > 0) {
            // Settle by minting shares outstanding for custody
            return (
                IFeeManager.SettlementType.MintSharesOutstanding,
                address(0),
                uint256(settlementSharesDue)
            );
        } else {
            // Settle by burning from shares outstanding
            return (
                IFeeManager.SettlementType.BurnSharesOutstanding,
                address(0),
                uint256(-settlementSharesDue)
            );
        }
    }

    /// @notice Gets whether the fee settles and requires GAV on a particular hook
    /// @param _hook The FeeHook
    /// @return settles_ True if the fee settles on the _hook
    /// @return usesGav_ True if the fee uses GAV during settle() for the _hook
    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        override
        returns (bool settles_, bool usesGav_)
    {
        if (
            _hook == IFeeManager.FeeHook.PreBuyShares ||
            _hook == IFeeManager.FeeHook.PreRedeemShares ||
            _hook == IFeeManager.FeeHook.Continuous
        ) {
            return (true, true);
        }

        return (false, false);
    }

    /// @notice Updates the fee state after all fees have finished settle()
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _hook The FeeHook being executed
    /// @param _settlementData Encoded args to use in calculating the settlement
    /// @param _gav The GAV of the fund
    function update(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    ) external override onlyFeeManager {
        uint256 prevSharePrice = comptrollerProxyToFeeInfo[_comptrollerProxy].lastSharePrice;
        uint256 nextSharePrice = __calcNextSharePrice(
            _comptrollerProxy,
            _vaultProxy,
            _hook,
            _settlementData,
            _gav
        );

        if (nextSharePrice == prevSharePrice) {
            return;
        }

        comptrollerProxyToFeeInfo[_comptrollerProxy].lastSharePrice = nextSharePrice;

        emit LastSharePriceUpdated(_comptrollerProxy, prevSharePrice, nextSharePrice);
    }

    /// @notice Gets whether the fee updates and requires GAV on a particular hook
    /// @param _hook The FeeHook
    /// @return updates_ True if the fee updates on the _hook
    /// @return usesGav_ True if the fee uses GAV during update() for the _hook
    function updatesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        override
        returns (bool updates_, bool usesGav_)
    {
        if (
            _hook == IFeeManager.FeeHook.PostBuyShares ||
            _hook == IFeeManager.FeeHook.PreRedeemShares ||
            _hook == IFeeManager.FeeHook.Continuous
        ) {
            return (true, true);
        }

        return (false, false);
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the recipient of the fee for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return recipient_ The recipient
    function getRecipientForFund(address _comptrollerProxy)
        public
        view
        override(FeeBase, SettableFeeRecipientBase)
        returns (address recipient_)
    {
        return SettableFeeRecipientBase.getRecipientForFund(_comptrollerProxy);
    }

    /// @notice Checks whether the shares outstanding can be paid out
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return payoutAllowed_ True if the fee payment is due
    /// @dev Payout is allowed if fees have not yet been settled in a crystallization period,
    /// and at least 1 crystallization period has passed since activation
    function payoutAllowed(address _comptrollerProxy) public view returns (bool payoutAllowed_) {
        FeeInfo memory feeInfo = comptrollerProxyToFeeInfo[_comptrollerProxy];
        uint256 period = feeInfo.period;

        uint256 timeSinceActivated = block.timestamp.sub(feeInfo.activated);

        // Check if at least 1 crystallization period has passed since activation
        if (timeSinceActivated < period) {
            return false;
        }

        // Check that a full crystallization period has passed since the last payout
        uint256 timeSincePeriodStart = timeSinceActivated % period;
        uint256 periodStart = block.timestamp.sub(timeSincePeriodStart);
        return feeInfo.lastPaid < periodStart;
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to calculate the aggregated value accumulated to a fund since the last
    /// settlement (happening at investment/redemption)
    /// Validated:
    /// _netSharesSupply > 0
    /// _sharePriceWithoutPerformance != _prevSharePrice
    function __calcAggregateValueDue(
        uint256 _netSharesSupply,
        uint256 _sharePriceWithoutPerformance,
        uint256 _prevSharePrice,
        uint256 _prevAggregateValueDue,
        uint256 _feeRate,
        uint256 _highWaterMark
    ) private pure returns (uint256) {
        int256 superHWMValueSinceLastSettled = (
            int256(__calcUint256Max(_highWaterMark, _sharePriceWithoutPerformance)).sub(
                int256(__calcUint256Max(_highWaterMark, _prevSharePrice))
            )
        )
            .mul(int256(_netSharesSupply))
            .div(int256(SHARE_UNIT));

        int256 valueDueSinceLastSettled = superHWMValueSinceLastSettled.mul(int256(_feeRate)).div(
            int256(ONE_HUNDRED_PERCENT)
        );

        return
            uint256(
                __calcInt256Max(0, int256(_prevAggregateValueDue).add(valueDueSinceLastSettled))
            );
    }

    /// @dev Helper to calculate the max of two int values
    function __calcInt256Max(int256 _a, int256 _b) private pure returns (int256) {
        if (_a >= _b) {
            return _a;
        }

        return _b;
    }

    /// @dev Helper to calculate the next `lastSharePrice` value
    function __calcNextSharePrice(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gav
    ) private view returns (uint256 nextSharePrice_) {
        uint256 denominationAssetUnit = 10 **
            uint256(ERC20(ComptrollerLib(_comptrollerProxy).getDenominationAsset()).decimals());
        if (_gav == 0) {
            return denominationAssetUnit;
        }

        // Get shares outstanding via VaultProxy balance and calc shares supply to get net shares supply
        ERC20 vaultProxyContract = ERC20(_vaultProxy);
        uint256 totalSharesSupply = vaultProxyContract.totalSupply();
        uint256 nextNetSharesSupply = totalSharesSupply.sub(
            vaultProxyContract.balanceOf(_vaultProxy)
        );
        if (nextNetSharesSupply == 0) {
            return denominationAssetUnit;
        }

        uint256 nextGav = _gav;

        // For both Continuous and BuySharesCompleted hooks, _gav and shares supply will not change,
        // we only need additional calculations for PreRedeemShares
        if (_hook == IFeeManager.FeeHook.PreRedeemShares) {
            (, uint256 sharesDecrease, ) = __decodePreRedeemSharesSettlementData(_settlementData);

            // Shares have not yet been burned
            nextNetSharesSupply = nextNetSharesSupply.sub(sharesDecrease);
            if (nextNetSharesSupply == 0) {
                return denominationAssetUnit;
            }

            // Assets have not yet been withdrawn
            uint256 gavDecrease = _gav.mul(sharesDecrease).div(totalSharesSupply);

            nextGav = nextGav.sub(gavDecrease);
            if (nextGav == 0) {
                return denominationAssetUnit;
            }
        }

        return nextGav.mul(SHARE_UNIT).div(nextNetSharesSupply);
    }

    /// @dev Helper to calculate the performance metrics for a fund.
    /// Validated:
    /// _totalSharesSupply > 0
    /// _gav > 0
    /// _totalSharesSupply != _totalSharesOutstanding
    function __calcPerformance(
        address _comptrollerProxy,
        uint256 _totalSharesSupply,
        uint256 _totalSharesOutstanding,
        uint256 _prevAggregateValueDue,
        FeeInfo memory feeInfo,
        uint256 _gav
    ) private view returns (uint256 nextAggregateValueDue_, int256 sharesDue_) {
        // Use the 'shares supply net shares outstanding' for performance calcs.
        // Cannot be 0, as _totalSharesSupply != _totalSharesOutstanding
        uint256 netSharesSupply = _totalSharesSupply.sub(_totalSharesOutstanding);
        uint256 sharePriceWithoutPerformance = _gav.mul(SHARE_UNIT).div(netSharesSupply);

        // If gross share price has not changed, can exit early
        uint256 prevSharePrice = feeInfo.lastSharePrice;
        if (sharePriceWithoutPerformance == prevSharePrice) {
            return (_prevAggregateValueDue, 0);
        }

        nextAggregateValueDue_ = __calcAggregateValueDue(
            netSharesSupply,
            sharePriceWithoutPerformance,
            prevSharePrice,
            _prevAggregateValueDue,
            feeInfo.rate,
            feeInfo.highWaterMark
        );

        sharesDue_ = __calcSharesDue(
            _comptrollerProxy,
            netSharesSupply,
            _gav,
            nextAggregateValueDue_
        );

        return (nextAggregateValueDue_, sharesDue_);
    }

    /// @dev Helper to calculate sharesDue during settlement.
    /// Validated:
    /// _netSharesSupply > 0
    /// _gav > 0
    function __calcSharesDue(
        address _comptrollerProxy,
        uint256 _netSharesSupply,
        uint256 _gav,
        uint256 _nextAggregateValueDue
    ) private view returns (int256 sharesDue_) {
        // _nextAggregateValueDue should never be greater than _gav, as the max fee rate is 100%
        uint256 sharesDueForAggregateValueDue = _nextAggregateValueDue.mul(_netSharesSupply).div(
            _gav.sub(_nextAggregateValueDue)
        );

        // Shares due is the +/- diff or the total shares outstanding already minted
        return
            int256(sharesDueForAggregateValueDue).sub(
                int256(
                    FeeManager(FEE_MANAGER).getFeeSharesOutstandingForFund(
                        _comptrollerProxy,
                        address(this)
                    )
                )
            );
    }

    /// @dev Helper to calculate the max of two uint values
    function __calcUint256Max(uint256 _a, uint256 _b) private pure returns (uint256) {
        if (_a >= _b) {
            return _a;
        }

        return _b;
    }

    /// @dev Helper to settle the fee and update performance state.
    /// Validated:
    /// _gav > 0
    function __settleAndUpdatePerformance(
        address _comptrollerProxy,
        address _vaultProxy,
        uint256 _gav
    ) private returns (int256 sharesDue_) {
        ERC20 sharesTokenContract = ERC20(_vaultProxy);

        uint256 totalSharesSupply = sharesTokenContract.totalSupply();
        if (totalSharesSupply == 0) {
            return 0;
        }

        uint256 totalSharesOutstanding = sharesTokenContract.balanceOf(_vaultProxy);
        if (totalSharesOutstanding == totalSharesSupply) {
            return 0;
        }

        FeeInfo storage feeInfo = comptrollerProxyToFeeInfo[_comptrollerProxy];
        uint256 prevAggregateValueDue = feeInfo.aggregateValueDue;

        uint256 nextAggregateValueDue;
        (nextAggregateValueDue, sharesDue_) = __calcPerformance(
            _comptrollerProxy,
            totalSharesSupply,
            totalSharesOutstanding,
            prevAggregateValueDue,
            feeInfo,
            _gav
        );
        if (nextAggregateValueDue == prevAggregateValueDue) {
            return 0;
        }

        // Update fee state
        feeInfo.aggregateValueDue = nextAggregateValueDue;

        emit PerformanceUpdated(
            _comptrollerProxy,
            prevAggregateValueDue,
            nextAggregateValueDue,
            sharesDue_
        );

        return sharesDue_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the feeInfo for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract of the fund
    /// @return feeInfo_ The feeInfo
    function getFeeInfoForFund(address _comptrollerProxy)
        external
        view
        returns (FeeInfo memory feeInfo_)
    {
        return comptrollerProxyToFeeInfo[_comptrollerProxy];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";
import "../../utils/AddressArrayLib.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../utils/ExtensionBase.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./IFee.sol";
import "./IFeeManager.sol";

/// @title FeeManager Contract
/// @author Enzyme Council <[email protected]>
/// @notice Manages fees for funds
/// @dev Any arbitrary fee is allowed by default, so all participants must be aware of
/// their fund's configuration, especially whether they use official fees only.
/// Fees can only be added upon fund setup, migration, or reconfiguration.
contract FeeManager is
    IFeeManager,
    ExtensionBase,
    FundDeployerOwnerMixin,
    PermissionedVaultActionMixin
{
    using AddressArrayLib for address[];
    using SafeMath for uint256;

    event FeeEnabledForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        bytes settingsData
    );

    event FeeSettledForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        SettlementType indexed settlementType,
        address payer,
        address payee,
        uint256 sharesDue
    );

    event SharesOutstandingPaidForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        address indexed payee,
        uint256 sharesDue
    );

    mapping(address => address[]) private comptrollerProxyToFees;
    mapping(address => mapping(address => uint256))
        private comptrollerProxyToFeeToSharesOutstanding;

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {}

    // EXTERNAL FUNCTIONS

    /// @notice Activate already-configured fees for use in the calling fund
    function activateForFund(bool) external override {
        address comptrollerProxy = msg.sender;
        address vaultProxy = __setValidatedVaultProxy(comptrollerProxy);

        address[] memory enabledFees = getEnabledFeesForFund(comptrollerProxy);
        for (uint256 i; i < enabledFees.length; i++) {
            IFee(enabledFees[i]).activateForFund(comptrollerProxy, vaultProxy);
        }
    }

    /// @notice Deactivate fees for a fund
    function deactivateForFund() external override {
        address comptrollerProxy = msg.sender;
        address vaultProxy = getVaultProxyForFund(comptrollerProxy);

        // Force payout of remaining shares outstanding
        address[] memory fees = getEnabledFeesForFund(comptrollerProxy);
        for (uint256 i; i < fees.length; i++) {
            __payoutSharesOutstanding(comptrollerProxy, vaultProxy, fees[i]);
        }
    }

    /// @notice Allows all fees for a particular FeeHook to implement settle() and update() logic
    /// @param _hook The FeeHook to invoke
    /// @param _settlementData The encoded settlement parameters specific to the FeeHook
    /// @param _gav The GAV for a fund if known in the invocating code, otherwise 0
    function invokeHook(
        FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    ) external override {
        __invokeHook(msg.sender, _hook, _settlementData, _gav, true);
    }

    /// @notice Receives a dispatched `callOnExtension` from a fund's ComptrollerProxy
    /// @param _actionId An ID representing the desired action
    /// @param _callArgs Encoded arguments specific to the _actionId
    /// @dev This is the only way to call a function on this contract that updates VaultProxy state.
    /// For both of these actions, any caller is allowed, so we don't use the caller param.
    function receiveCallFromComptroller(
        address,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external override {
        if (_actionId == 0) {
            // Settle and update all continuous fees
            __invokeHook(msg.sender, IFeeManager.FeeHook.Continuous, "", 0, true);
        } else if (_actionId == 1) {
            __payoutSharesOutstandingForFees(msg.sender, _callArgs);
        } else {
            revert("receiveCallFromComptroller: Invalid _actionId");
        }
    }

    /// @notice Enable and configure fees for use in the calling fund
    /// @param _configData Encoded config data
    /// @dev Caller is expected to be a valid ComptrollerProxy, but there isn't a need to validate.
    /// The order of `fees` determines the order in which fees of the same FeeHook will be applied.
    /// It is recommended to run ManagementFee before PerformanceFee in order to achieve precise
    /// PerformanceFee calcs.
    function setConfigForFund(bytes calldata _configData) external override {
        (address[] memory fees, bytes[] memory settingsData) = abi.decode(
            _configData,
            (address[], bytes[])
        );

        // Sanity checks
        require(
            fees.length == settingsData.length,
            "setConfigForFund: fees and settingsData array lengths unequal"
        );
        require(fees.isUniqueSet(), "setConfigForFund: fees cannot include duplicates");

        // Enable each fee with settings
        for (uint256 i; i < fees.length; i++) {
            // Set fund config on fee
            IFee(fees[i]).addFundSettings(msg.sender, settingsData[i]);

            // Enable fee for fund
            comptrollerProxyToFees[msg.sender].push(fees[i]);

            emit FeeEnabledForFund(msg.sender, fees[i], settingsData[i]);
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to get the canonical value of GAV if not yet set and required by fee
    function __getGavAsNecessary(address _comptrollerProxy, uint256 _gavOrZero)
        private
        returns (uint256 gav_)
    {
        if (_gavOrZero == 0) {
            // Do not finalize synths, as this can lead to lost fees when redeeming shares
            return IComptroller(_comptrollerProxy).calcGav(false);
        } else {
            return _gavOrZero;
        }
    }

    /// @dev Helper to run settle() on all enabled fees for a fund that implement a given hook, and then to
    /// optionally run update() on the same fees. This order allows fees an opportunity to update
    /// their local state after all VaultProxy state transitions (i.e., minting, burning,
    /// transferring shares) have finished. To optimize for the expensive operation of calculating
    /// GAV, once one fee requires GAV, we recycle that `gav` value for subsequent fees.
    /// Assumes that _gav is either 0 or has already been validated.
    function __invokeHook(
        address _comptrollerProxy,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gavOrZero,
        bool _updateFees
    ) private {
        address[] memory fees = getEnabledFeesForFund(_comptrollerProxy);
        if (fees.length == 0) {
            return;
        }

        address vaultProxy = getVaultProxyForFund(_comptrollerProxy);

        // This check isn't strictly necessary, but its cost is insignificant,
        // and helps to preserve data integrity.
        require(vaultProxy != address(0), "__invokeHook: Fund is not active");

        // First, allow all fees to implement settle()
        uint256 gav = __settleFees(
            _comptrollerProxy,
            vaultProxy,
            fees,
            _hook,
            _settlementData,
            _gavOrZero
        );

        // Second, allow fees to implement update()
        // This function does not allow any further altering of VaultProxy state
        // (i.e., burning, minting, or transferring shares)
        if (_updateFees) {
            __updateFees(_comptrollerProxy, vaultProxy, fees, _hook, _settlementData, gav);
        }
    }

    /// @dev Helper to get the end recipient for a given fee and fund
    function __parseFeeRecipientForFund(
        address _comptrollerProxy,
        address _vaultProxy,
        address _fee
    ) private view returns (address recipient_) {
        recipient_ = IFee(_fee).getRecipientForFund(_comptrollerProxy);
        if (recipient_ == address(0)) {
            recipient_ = IVault(_vaultProxy).getOwner();
        }

        return recipient_;
    }

    /// @dev Helper to payout the shares outstanding for the specified fees.
    /// Does not call settle() on fees.
    /// Only callable via ComptrollerProxy.callOnExtension().
    function __payoutSharesOutstandingForFees(address _comptrollerProxy, bytes memory _callArgs)
        private
    {
        address[] memory fees = abi.decode(_callArgs, (address[]));
        address vaultProxy = getVaultProxyForFund(msg.sender);

        for (uint256 i; i < fees.length; i++) {
            if (IFee(fees[i]).payout(_comptrollerProxy, vaultProxy)) {
                __payoutSharesOutstanding(_comptrollerProxy, vaultProxy, fees[i]);
            }
        }
    }

    /// @dev Helper to payout shares outstanding for a given fee.
    /// Assumes the fee is payout-able.
    function __payoutSharesOutstanding(
        address _comptrollerProxy,
        address _vaultProxy,
        address _fee
    ) private {
        uint256 sharesOutstanding = getFeeSharesOutstandingForFund(_comptrollerProxy, _fee);
        if (sharesOutstanding == 0) {
            return;
        }

        delete comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee];

        address payee = __parseFeeRecipientForFund(_comptrollerProxy, _vaultProxy, _fee);

        __transferShares(_comptrollerProxy, _vaultProxy, payee, sharesOutstanding);

        emit SharesOutstandingPaidForFund(_comptrollerProxy, _fee, payee, sharesOutstanding);
    }

    /// @dev Helper to settle a fee
    function __settleFee(
        address _comptrollerProxy,
        address _vaultProxy,
        address _fee,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gav
    ) private {
        (SettlementType settlementType, address payer, uint256 sharesDue) = IFee(_fee).settle(
            _comptrollerProxy,
            _vaultProxy,
            _hook,
            _settlementData,
            _gav
        );
        if (settlementType == SettlementType.None) {
            return;
        }

        address payee;
        if (settlementType == SettlementType.Direct) {
            payee = __parseFeeRecipientForFund(_comptrollerProxy, _vaultProxy, _fee);
            __transferShares(_comptrollerProxy, payer, payee, sharesDue);
        } else if (settlementType == SettlementType.Mint) {
            payee = __parseFeeRecipientForFund(_comptrollerProxy, _vaultProxy, _fee);
            __mintShares(_comptrollerProxy, payee, sharesDue);
        } else if (settlementType == SettlementType.Burn) {
            __burnShares(_comptrollerProxy, payer, sharesDue);
        } else if (settlementType == SettlementType.MintSharesOutstanding) {
            comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee] = comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee]
                .add(sharesDue);

            payee = _vaultProxy;
            __mintShares(_comptrollerProxy, payee, sharesDue);
        } else if (settlementType == SettlementType.BurnSharesOutstanding) {
            comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee] = comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee]
                .sub(sharesDue);

            payer = _vaultProxy;
            __burnShares(_comptrollerProxy, payer, sharesDue);
        } else {
            revert("__settleFee: Invalid SettlementType");
        }

        emit FeeSettledForFund(_comptrollerProxy, _fee, settlementType, payer, payee, sharesDue);
    }

    /// @dev Helper to settle fees that implement a given fee hook
    function __settleFees(
        address _comptrollerProxy,
        address _vaultProxy,
        address[] memory _fees,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gavOrZero
    ) private returns (uint256 gav_) {
        gav_ = _gavOrZero;

        for (uint256 i; i < _fees.length; i++) {
            (bool settles, bool usesGav) = IFee(_fees[i]).settlesOnHook(_hook);
            if (!settles) {
                continue;
            }

            if (usesGav) {
                gav_ = __getGavAsNecessary(_comptrollerProxy, gav_);
            }

            __settleFee(_comptrollerProxy, _vaultProxy, _fees[i], _hook, _settlementData, gav_);
        }

        return gav_;
    }

    /// @dev Helper to update fees that implement a given fee hook
    function __updateFees(
        address _comptrollerProxy,
        address _vaultProxy,
        address[] memory _fees,
        FeeHook _hook,
        bytes memory _settlementData,
        uint256 _gavOrZero
    ) private {
        uint256 gav = _gavOrZero;

        for (uint256 i; i < _fees.length; i++) {
            (bool updates, bool usesGav) = IFee(_fees[i]).updatesOnHook(_hook);
            if (!updates) {
                continue;
            }

            if (usesGav) {
                gav = __getGavAsNecessary(_comptrollerProxy, gav);
            }

            IFee(_fees[i]).update(_comptrollerProxy, _vaultProxy, _hook, _settlementData, gav);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Get a list of enabled fees for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return enabledFees_ An array of enabled fee addresses
    function getEnabledFeesForFund(address _comptrollerProxy)
        public
        view
        returns (address[] memory enabledFees_)
    {
        return comptrollerProxyToFees[_comptrollerProxy];
    }

    // PUBLIC FUNCTIONS

    /// @notice Get the amount of shares outstanding for a particular fee for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _fee The fee address
    /// @return sharesOutstanding_ The amount of shares outstanding
    function getFeeSharesOutstandingForFund(address _comptrollerProxy, address _fee)
        public
        view
        returns (uint256 sharesOutstanding_)
    {
        return comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";
import "../IExtension.sol";

/// @title ExtensionBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base class for an extension
abstract contract ExtensionBase is IExtension {
    mapping(address => address) internal comptrollerProxyToVaultProxy;

    /// @notice Allows extension to run logic during fund activation
    /// @dev Unimplemented by default, may be overridden.
    function activateForFund(bool) external virtual override {
        return;
    }

    /// @notice Allows extension to run logic during fund deactivation (destruct)
    /// @dev Unimplemented by default, may be overridden.
    function deactivateForFund() external virtual override {
        return;
    }

    /// @notice Receives calls from ComptrollerLib.callOnExtension()
    /// and dispatches the appropriate action
    /// @dev Unimplemented by default, may be overridden.
    function receiveCallFromComptroller(
        address,
        uint256,
        bytes calldata
    ) external virtual override {
        revert("receiveCallFromComptroller: Unimplemented for Extension");
    }

    /// @notice Allows extension to run logic during fund configuration
    /// @dev Unimplemented by default, may be overridden.
    function setConfigForFund(bytes calldata) external virtual override {
        return;
    }

    /// @dev Helper to validate a ComptrollerProxy-VaultProxy relation, which we store for both
    /// gas savings and to guarantee a spoofed ComptrollerProxy does not change getVaultProxy().
    /// Will revert without reason if the expected interfaces do not exist.
    function __setValidatedVaultProxy(address _comptrollerProxy)
        internal
        returns (address vaultProxy_)
    {
        require(
            comptrollerProxyToVaultProxy[_comptrollerProxy] == address(0),
            "__setValidatedVaultProxy: Already set"
        );

        vaultProxy_ = IComptroller(_comptrollerProxy).getVaultProxy();
        require(vaultProxy_ != address(0), "__setValidatedVaultProxy: Missing vaultProxy");

        require(
            _comptrollerProxy == IVault(vaultProxy_).getAccessor(),
            "__setValidatedVaultProxy: Not the VaultProxy accessor"
        );

        comptrollerProxyToVaultProxy[_comptrollerProxy] = vaultProxy_;

        return vaultProxy_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the verified VaultProxy for a given ComptrollerProxy
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return vaultProxy_ The VaultProxy of the fund
    function getVaultProxyForFund(address _comptrollerProxy)
        public
        view
        returns (address vaultProxy_)
    {
        return comptrollerProxyToVaultProxy[_comptrollerProxy];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";

/// @title PermissionedVaultActionMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for extensions that can make permissioned vault calls
abstract contract PermissionedVaultActionMixin {
    /// @notice Adds an external position to active external positions
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _externalPosition The external position to be added
    function __addExternalPosition(address _comptrollerProxy, address _externalPosition) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.AddExternalPosition,
            abi.encode(_externalPosition)
        );
    }

    /// @notice Adds a tracked asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to add
    function __addTrackedAsset(address _comptrollerProxy, address _asset) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.AddTrackedAsset,
            abi.encode(_asset)
        );
    }

    /// @notice Grants an allowance to a spender to use a fund's asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset for which to grant an allowance
    /// @param _target The spender of the allowance
    /// @param _amount The amount of the allowance
    function __approveAssetSpender(
        address _comptrollerProxy,
        address _asset,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.ApproveAssetSpender,
            abi.encode(_asset, _target, _amount)
        );
    }

    /// @notice Burns fund shares for a particular account
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to burn
    function __burnShares(
        address _comptrollerProxy,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.BurnShares,
            abi.encode(_target, _amount)
        );
    }

    /// @notice Executes a callOnExternalPosition
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _data The encoded data for the call
    function __callOnExternalPosition(address _comptrollerProxy, bytes memory _data) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.CallOnExternalPosition,
            _data
        );
    }

    /// @notice Mints fund shares to a particular account
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _target The account to which to mint shares
    /// @param _amount The amount of shares to mint
    function __mintShares(
        address _comptrollerProxy,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.MintShares,
            abi.encode(_target, _amount)
        );
    }

    /// @notice Removes an external position from the vaultProxy
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _externalPosition The ExternalPosition to remove
    function __removeExternalPosition(address _comptrollerProxy, address _externalPosition)
        internal
    {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.RemoveExternalPosition,
            abi.encode(_externalPosition)
        );
    }

    /// @notice Removes a tracked asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to remove
    function __removeTrackedAsset(address _comptrollerProxy, address _asset) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.RemoveTrackedAsset,
            abi.encode(_asset)
        );
    }

    /// @notice Transfers fund shares from one account to another
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _from The account from which to transfer shares
    /// @param _to The account to which to transfer shares
    /// @param _amount The amount of shares to transfer
    function __transferShares(
        address _comptrollerProxy,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.TransferShares,
            abi.encode(_from, _to, _amount)
        );
    }

    /// @notice Withdraws an asset from the VaultProxy to a given account
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to withdraw
    /// @param _target The account to which to withdraw the asset
    /// @param _amount The amount of asset to withdraw
    function __withdrawAssetTo(
        address _comptrollerProxy,
        address _asset,
        address _target,
        uint256 _amount
    ) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IVault.VaultAction.WithdrawAssetTo,
            abi.encode(_asset, _target, _amount)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FeeBase.sol";

/// @title ExitRateFeeBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Calculates a fee based on a rate to be charged to an investor upon exiting a fund
abstract contract ExitRateFeeBase is FeeBase {
    using SafeMath for uint256;

    event FundSettingsAdded(
        address indexed comptrollerProxy,
        uint256 inKindRate,
        uint256 specificAssetsRate
    );

    event Settled(
        address indexed comptrollerProxy,
        address indexed payer,
        uint256 sharesQuantity,
        bool indexed forSpecificAssets
    );

    struct FeeInfo {
        uint16 inKindRate;
        uint16 specificAssetsRate;
    }

    uint256 private constant ONE_HUNDRED_PERCENT = 10000;
    IFeeManager.SettlementType private immutable SETTLEMENT_TYPE;

    mapping(address => FeeInfo) private comptrollerProxyToFeeInfo;

    constructor(address _feeManager, IFeeManager.SettlementType _settlementType)
        public
        FeeBase(_feeManager)
    {
        require(
            _settlementType == IFeeManager.SettlementType.Burn ||
                _settlementType == IFeeManager.SettlementType.Direct,
            "constructor: Invalid _settlementType"
        );
        SETTLEMENT_TYPE = _settlementType;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        public
        virtual
        override
        onlyFeeManager
    {
        (uint16 inKindRate, uint16 specificAssetsRate) = abi.decode(
            _settingsData,
            (uint16, uint16)
        );
        require(inKindRate < ONE_HUNDRED_PERCENT, "addFundSettings: inKindRate max exceeded");
        require(
            specificAssetsRate < ONE_HUNDRED_PERCENT,
            "addFundSettings: specificAssetsRate max exceeded"
        );

        comptrollerProxyToFeeInfo[_comptrollerProxy] = FeeInfo({
            inKindRate: inKindRate,
            specificAssetsRate: specificAssetsRate
        });

        emit FundSettingsAdded(_comptrollerProxy, inKindRate, specificAssetsRate);
    }

    /// @notice Settles the fee
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settlementData Encoded args to use in calculating the settlement
    /// @return settlementType_ The type of settlement
    /// @return payer_ The payer of shares due
    /// @return sharesDue_ The amount of shares due
    function settle(
        address _comptrollerProxy,
        address,
        IFeeManager.FeeHook,
        bytes calldata _settlementData,
        uint256
    )
        external
        override
        onlyFeeManager
        returns (
            IFeeManager.SettlementType settlementType_,
            address payer_,
            uint256 sharesDue_
        )
    {
        bool forSpecificAssets;
        uint256 sharesRedeemed;
        (payer_, sharesRedeemed, forSpecificAssets) = __decodePreRedeemSharesSettlementData(
            _settlementData
        );

        uint256 rate;
        if (forSpecificAssets) {
            rate = getSpecificAssetsRateForFund(_comptrollerProxy);
        } else {
            rate = getInKindRateForFund(_comptrollerProxy);
        }

        sharesDue_ = sharesRedeemed.mul(rate).div(ONE_HUNDRED_PERCENT);

        if (sharesDue_ == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        emit Settled(_comptrollerProxy, payer_, sharesDue_, forSpecificAssets);

        return (getSettlementType(), payer_, sharesDue_);
    }

    /// @notice Gets whether the fee settles and requires GAV on a particular hook
    /// @param _hook The FeeHook
    /// @return settles_ True if the fee settles on the _hook
    /// @return usesGav_ True if the fee uses GAV during settle() for the _hook
    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        override
        returns (bool settles_, bool usesGav_)
    {
        if (_hook == IFeeManager.FeeHook.PreRedeemShares) {
            return (true, false);
        }

        return (false, false);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the fee rate for an in-kind redemption
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return rate_ The fee rate
    function getInKindRateForFund(address _comptrollerProxy) public view returns (uint256 rate_) {
        return comptrollerProxyToFeeInfo[_comptrollerProxy].inKindRate;
    }

    /// @notice Gets the `SETTLEMENT_TYPE` variable
    /// @return settlementType_ The `SETTLEMENT_TYPE` variable value
    function getSettlementType() public view returns (IFeeManager.SettlementType settlementType_) {
        return SETTLEMENT_TYPE;
    }

    /// @notice Gets the fee rate for a specific assets redemption
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return rate_ The fee rate
    function getSpecificAssetsRateForFund(address _comptrollerProxy)
        public
        view
        returns (uint256 rate_)
    {
        return comptrollerProxyToFeeInfo[_comptrollerProxy].specificAssetsRate;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ExitRateFeeBase.sol";
import "./utils/UpdatableFeeRecipientBase.sol";

/// @title ExitRateDirectFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice An ExitRateFee that transfers the fee shares to a recipient
contract ExitRateDirectFee is ExitRateFeeBase, UpdatableFeeRecipientBase {
    constructor(address _feeManager)
        public
        ExitRateFeeBase(_feeManager, IFeeManager.SettlementType.Direct)
    {}

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    /// @dev onlyFeeManager validated by parent
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        public
        override
    {
        super.addFundSettings(_comptrollerProxy, _settingsData);

        (, , address recipient) = abi.decode(_settingsData, (uint256, uint256, address));

        if (recipient != address(0)) {
            __setRecipientForFund(_comptrollerProxy, recipient);
        }
    }

    /// @notice Gets the recipient of the fee for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return recipient_ The recipient
    function getRecipientForFund(address _comptrollerProxy)
        public
        view
        override(FeeBase, SettableFeeRecipientBase)
        returns (address recipient_)
    {
        return SettableFeeRecipientBase.getRecipientForFund(_comptrollerProxy);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestnetToken is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    function burnFrom(address _account, uint256 _amount) public override onlyOwner {
        _burn(_account, _amount);
    }

    function mintFor(address _who, uint256 _amount) external onlyOwner {
        _mint(_who, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/TreasuryEnabledMixin.sol";
import "../release/infrastructure/value-interpreter/IValueInterpreter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestnetValueInterpreter is IValueInterpreter, Ownable, TreasuryEnabledMixin {

    uint256 private constant ETH_UNIT = 10**18;

    address public immutable WETH;

    constructor(address _treasury, address _weth) public TreasuryEnabledMixin(_treasury) {
        WETH = _weth;
    }

    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external override returns (uint256 value_) {
        uint256 baseAssetPrice = __getPrice(_baseAsset);
        uint256 quoteAssetPrice = __getPrice(_quoteAsset);

        uint256 baseAssetDivider = 10**uint256(TestnetToken(_baseAsset).decimals());
        uint256 quoteAssetDivider = 10**uint256(TestnetToken(_quoteAsset).decimals());

        return _amount * baseAssetPrice * quoteAssetDivider / quoteAssetPrice / baseAssetDivider;
    }

    function calcCanonicalAssetsTotalValue(
        address[] calldata _baseAssets,
        uint256[] calldata _amounts,
        address _quoteAsset
    ) external override returns (uint256 value_) {
        require(
            _baseAssets.length == _amounts.length,
            "calcCanonicalAssetsTotalValue: Arrays unequal lengths"
        );

        uint256 quoteAssetPrice = __getPrice(_quoteAsset);
        uint256 quoteAssetDivider = 10**uint256(TestnetToken(_quoteAsset).decimals());

        uint256 total;
        for (uint256 i; i < _baseAssets.length; i++) {
            total += _amounts[i] * __getPrice(_baseAssets[i]) * quoteAssetDivider / quoteAssetPrice / 10**uint256(TestnetToken(_baseAssets[i]).decimals());
        }

        return total;
    }

    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return __isSupportedAsset(_asset);
    }

    function isSupportedPrimitiveAsset(address _asset)
        external
        view
        override
        returns (bool isSupported_)
    {
        return __isSupportedAsset(_asset);
    }

    function isSupportedDerivativeAsset(address)
        external
        view
        override
        returns (bool isSupported_)
    {
        return false;
    }

    function __getPrice(address _asset) private view returns (uint256 assetPrice_) {
        if (_asset == WETH) {
            return uint256(ETH_UNIT);
        }

        return TREASURY.getPrice(_asset);
    }

    function __isSupportedAsset(address _asset) private view returns (bool isSupported_) {
        if (_asset == WETH) {
            return true;
        }

        return TREASURY.isToken(_asset);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../TestnetTreasuryController.sol";

abstract contract TreasuryEnabledMixin {
    TestnetTreasuryController public immutable TREASURY;

    constructor(address _treasury) public {
        TREASURY = TestnetTreasuryController(_treasury);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TestnetToken.sol";

contract TestnetTreasuryController is Ownable {
    event TokenDeployed(address indexed asset, string name, string symbol, uint8 decimals);
    event PriceUpdated(address indexed asset, uint256 price);

    mapping(address => bool) private managers;
    mapping(address => bool) private tokens;
    mapping(address => uint256) private prices;

    modifier onlyManager {
        require(managers[msg.sender] || msg.sender == owner());
        _;
    }

    function addManager(address _manager) public onlyOwner {
        managers[_manager] = true;
    }

    function removeManager(address _manager) public onlyOwner {
        managers[_manager] = false;
    }

    function updatePrices(address[] memory _assets, uint256[] memory _prices)
        external
        onlyManager
    {
        for (uint256 i; i < _assets.length; i++) {
            require(isToken(_assets[i]), "getPrice: Invalid asset");
            prices[_assets[i]] = _prices[i];
            emit PriceUpdated(_assets[i], _prices[i]);
        }
    }

    function getPrice(address _asset) external view returns (uint256 assetPrice_) {
        require(isToken(_asset), "getPrice: Invalid asset");
        return prices[_asset];
    }

    function isToken(address _asset) public view returns (bool isToken_) {
        return tokens[_asset];
    }

    function deployTokens(
        string[] memory _names,
        string[] memory _symbols,
        uint8[] memory _decimals
    ) public onlyManager {
        require(
            _names.length == _symbols.length && _names.length == _decimals.length,
            "batchDeploy: array lengths don't match"
        );

        for (uint256 i; i < _names.length; i++) {
            address deployed = address(new TestnetToken(_names[i], _symbols[i], _decimals[i]));
            tokens[deployed] = true;
            emit TokenDeployed(deployed, _names[i], _symbols[i], _decimals[i]);
        }
    }

    function burnFrom(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyManager {
        TestnetToken(_token).burnFrom(_to, _amount);
    }

    function mintFor(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyManager {
        TestnetToken(_token).mintFor(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../core/fund/vault/IVault.sol";
import "../../infrastructure/value-interpreter/IValueInterpreter.sol";
import "../../utils/AddressArrayLib.sol";
import "../../utils/AssetHelpers.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../policy-manager/IPolicyManager.sol";
import "../utils/ExtensionBase.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./integrations/IIntegrationAdapter.sol";
import "./IIntegrationManager.sol";

/// @title IntegrationManager
/// @author Enzyme Council <[email protected]>
/// @notice Extension to handle DeFi integration actions for funds
/// @dev Any arbitrary adapter is allowed by default, so all participants must be aware of
/// their fund's configuration, especially whether they use a policy that only allows
/// official adapters. Owners and asset managers must also establish trust for any
/// arbitrary adapters that they interact with.
contract IntegrationManager is
    IIntegrationManager,
    ExtensionBase,
    FundDeployerOwnerMixin,
    PermissionedVaultActionMixin,
    AssetHelpers
{
    using AddressArrayLib for address[];
    using SafeMath for uint256;

    event CallOnIntegrationExecutedForFund(
        address indexed comptrollerProxy,
        address caller,
        address indexed adapter,
        bytes4 indexed selector,
        bytes integrationData,
        address[] incomingAssets,
        uint256[] incomingAssetAmounts,
        address[] spendAssets,
        uint256[] spendAssetAmounts
    );

    address private immutable POLICY_MANAGER;
    address private immutable VALUE_INTERPRETER;

    constructor(
        address _fundDeployer,
        address _policyManager,
        address _valueInterpreter
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        POLICY_MANAGER = _policyManager;
        VALUE_INTERPRETER = _valueInterpreter;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Activates the extension by storing the VaultProxy
    function activateForFund(bool) external override {
        __setValidatedVaultProxy(msg.sender);
    }

    ///////////////////////////////
    // CALL-ON-EXTENSION ACTIONS //
    ///////////////////////////////

    /// @notice Receives a dispatched `callOnExtension` from a fund's ComptrollerProxy
    /// @param _caller The user who called for this action
    /// @param _actionId An ID representing the desired action
    /// @param _callArgs The encoded args for the action
    function receiveCallFromComptroller(
        address _caller,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external override {
        address comptrollerProxy = msg.sender;

        // Since we validate and store the ComptrollerProxy-VaultProxy pairing during
        // activateForFund(), this function does not require further validation of the
        // sending ComptrollerProxy
        address vaultProxy = comptrollerProxyToVaultProxy[comptrollerProxy];
        require(vaultProxy != address(0), "receiveCallFromComptroller: Fund is not active");

        require(
            IVault(vaultProxy).canManageAssets(_caller),
            "receiveCallFromComptroller: Unauthorized"
        );

        // Dispatch the action
        if (_actionId == 0) {
            __callOnIntegration(_caller, comptrollerProxy, vaultProxy, _callArgs);
        } else if (_actionId == 1) {
            __addTrackedAssetsToVault(_caller, comptrollerProxy, _callArgs);
        } else if (_actionId == 2) {
            __removeTrackedAssetsFromVault(_caller, comptrollerProxy, _callArgs);
        } else {
            revert("receiveCallFromComptroller: Invalid _actionId");
        }
    }

    /// @dev Adds assets as tracked assets of the vault.
    /// Does not validate that assets are not already tracked.
    function __addTrackedAssetsToVault(
        address _caller,
        address _comptrollerProxy,
        bytes memory _callArgs
    ) private {
        address[] memory assets = abi.decode(_callArgs, (address[]));

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.AddTrackedAssets,
            abi.encode(_caller, assets)
        );

        for (uint256 i; i < assets.length; i++) {
            require(
                IValueInterpreter(getValueInterpreter()).isSupportedAsset(assets[i]),
                "__addTrackedAssetsToVault: Unsupported asset"
            );

            __addTrackedAsset(_comptrollerProxy, assets[i]);
        }
    }

    /// @dev Removes assets from the tracked assets of the vault.
    /// Does not validate that assets are not already tracked.
    function __removeTrackedAssetsFromVault(
        address _caller,
        address _comptrollerProxy,
        bytes memory _callArgs
    ) private {
        address[] memory assets = abi.decode(_callArgs, (address[]));

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.RemoveTrackedAssets,
            abi.encode(_caller, assets)
        );

        for (uint256 i; i < assets.length; i++) {
            __removeTrackedAsset(_comptrollerProxy, assets[i]);
        }
    }

    /////////////////////////
    // CALL ON INTEGRATION //
    /////////////////////////

    /// @notice Universal method for calling third party contract functions through adapters
    /// @param _caller The caller of this function via the ComptrollerProxy
    /// @param _comptrollerProxy The ComptrollerProxy
    /// @param _vaultProxy The VaultProxy
    /// @param _callArgs The encoded args for this function
    /// - _adapter Adapter of the integration on which to execute a call
    /// - _selector Method selector of the adapter method to execute
    /// - _integrationData Encoded arguments specific to the adapter
    /// @dev Refer to specific adapter to see how to encode its arguments.
    function __callOnIntegration(
        address _caller,
        address _comptrollerProxy,
        address _vaultProxy,
        bytes memory _callArgs
    ) private {
        (
            address adapter,
            bytes4 selector,
            bytes memory integrationData
        ) = __decodeCallOnIntegrationArgs(_callArgs);

        (
            address[] memory incomingAssets,
            uint256[] memory incomingAssetAmounts,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts
        ) = __callOnIntegrationInner(
            _comptrollerProxy,
            _vaultProxy,
            adapter,
            selector,
            integrationData
        );

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.PostCallOnIntegration,
            abi.encode(
                _caller,
                adapter,
                selector,
                incomingAssets,
                incomingAssetAmounts,
                spendAssets,
                spendAssetAmounts
            )
        );

        emit CallOnIntegrationExecutedForFund(
            _comptrollerProxy,
            _caller,
            adapter,
            selector,
            integrationData,
            incomingAssets,
            incomingAssetAmounts,
            spendAssets,
            spendAssetAmounts
        );
    }

    /// @dev Helper to execute the bulk of logic of callOnIntegration.
    /// Avoids the stack-too-deep-error.
    function __callOnIntegrationInner(
        address _comptrollerProxy,
        address _vaultProxy,
        address _adapter,
        bytes4 _selector,
        bytes memory _integrationData
    )
        private
        returns (
            address[] memory incomingAssets_,
            uint256[] memory incomingAssetAmounts_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_
        )
    {
        uint256[] memory preCallIncomingAssetBalances;
        uint256[] memory minIncomingAssetAmounts;
        SpendAssetsHandleType spendAssetsHandleType;
        uint256[] memory maxSpendAssetAmounts;
        uint256[] memory preCallSpendAssetBalances;

        (
            incomingAssets_,
            preCallIncomingAssetBalances,
            minIncomingAssetAmounts,
            spendAssetsHandleType,
            spendAssets_,
            maxSpendAssetAmounts,
            preCallSpendAssetBalances
        ) = __preProcessCoI(_comptrollerProxy, _vaultProxy, _adapter, _selector, _integrationData);

        __executeCoI(
            _vaultProxy,
            _adapter,
            _selector,
            _integrationData,
            abi.encode(spendAssets_, maxSpendAssetAmounts, incomingAssets_)
        );

        (incomingAssetAmounts_, spendAssetAmounts_) = __postProcessCoI(
            _comptrollerProxy,
            _vaultProxy,
            _adapter,
            incomingAssets_,
            preCallIncomingAssetBalances,
            minIncomingAssetAmounts,
            spendAssetsHandleType,
            spendAssets_,
            maxSpendAssetAmounts,
            preCallSpendAssetBalances
        );

        return (incomingAssets_, incomingAssetAmounts_, spendAssets_, spendAssetAmounts_);
    }

    /// @dev Helper to decode CoI args
    function __decodeCallOnIntegrationArgs(bytes memory _callArgs)
        private
        pure
        returns (
            address adapter_,
            bytes4 selector_,
            bytes memory integrationData_
        )
    {
        return abi.decode(_callArgs, (address, bytes4, bytes));
    }

    /// @dev Helper to execute a call to an integration
    /// @dev Avoids stack-too-deep error
    function __executeCoI(
        address _vaultProxy,
        address _adapter,
        bytes4 _selector,
        bytes memory _integrationData,
        bytes memory _assetData
    ) private {
        (bool success, bytes memory returnData) = _adapter.call(
            abi.encodeWithSelector(_selector, _vaultProxy, _integrationData, _assetData)
        );
        require(success, string(returnData));
    }

    /// @dev Helper to get the vault's balance of a particular asset
    function __getVaultAssetBalance(address _vaultProxy, address _asset)
        private
        view
        returns (uint256)
    {
        return ERC20(_asset).balanceOf(_vaultProxy);
    }

    /// @dev Helper for the internal actions to take prior to executing CoI
    function __preProcessCoI(
        address _comptrollerProxy,
        address _vaultProxy,
        address _adapter,
        bytes4 _selector,
        bytes memory _integrationData
    )
        private
        returns (
            address[] memory incomingAssets_,
            uint256[] memory preCallIncomingAssetBalances_,
            uint256[] memory minIncomingAssetAmounts_,
            SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory maxSpendAssetAmounts_,
            uint256[] memory preCallSpendAssetBalances_
        )
    {
        // Note that incoming and spend assets are allowed to overlap
        // (e.g., a fee for the incomingAsset charged in a spend asset)
        (
            spendAssetsHandleType_,
            spendAssets_,
            maxSpendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        ) = IIntegrationAdapter(_adapter).parseAssetsForAction(
            _vaultProxy,
            _selector,
            _integrationData
        );
        require(
            spendAssets_.length == maxSpendAssetAmounts_.length,
            "__preProcessCoI: Spend assets arrays unequal"
        );
        require(
            incomingAssets_.length == minIncomingAssetAmounts_.length,
            "__preProcessCoI: Incoming assets arrays unequal"
        );
        require(spendAssets_.isUniqueSet(), "__preProcessCoI: Duplicate spend asset");
        require(incomingAssets_.isUniqueSet(), "__preProcessCoI: Duplicate incoming asset");

        // INCOMING ASSETS

        // Incoming asset balances must be recorded prior to spend asset balances in case there
        // is an overlap (an asset that is both a spend asset and an incoming asset),
        // as a spend asset can be immediately transferred after recording its balance
        preCallIncomingAssetBalances_ = new uint256[](incomingAssets_.length);
        for (uint256 i; i < incomingAssets_.length; i++) {
            require(
                IValueInterpreter(getValueInterpreter()).isSupportedAsset(incomingAssets_[i]),
                "__preProcessCoI: Non-receivable incoming asset"
            );

            preCallIncomingAssetBalances_[i] = ERC20(incomingAssets_[i]).balanceOf(_vaultProxy);
        }

        // SPEND ASSETS

        preCallSpendAssetBalances_ = new uint256[](spendAssets_.length);
        for (uint256 i; i < spendAssets_.length; i++) {
            preCallSpendAssetBalances_[i] = ERC20(spendAssets_[i]).balanceOf(_vaultProxy);

            // Grant adapter access to the spend assets.
            // spendAssets_ is already asserted to be a unique set.
            if (spendAssetsHandleType_ == SpendAssetsHandleType.Approve) {
                // Use exact approve amount, and reset afterwards
                __approveAssetSpender(
                    _comptrollerProxy,
                    spendAssets_[i],
                    _adapter,
                    maxSpendAssetAmounts_[i]
                );
            } else if (spendAssetsHandleType_ == SpendAssetsHandleType.Transfer) {
                __withdrawAssetTo(
                    _comptrollerProxy,
                    spendAssets_[i],
                    _adapter,
                    maxSpendAssetAmounts_[i]
                );
            }
        }
    }

    /// @dev Helper to reconcile incoming and spend assets after executing CoI
    function __postProcessCoI(
        address _comptrollerProxy,
        address _vaultProxy,
        address _adapter,
        address[] memory _incomingAssets,
        uint256[] memory _preCallIncomingAssetBalances,
        uint256[] memory _minIncomingAssetAmounts,
        SpendAssetsHandleType _spendAssetsHandleType,
        address[] memory _spendAssets,
        uint256[] memory _maxSpendAssetAmounts,
        uint256[] memory _preCallSpendAssetBalances
    )
        private
        returns (uint256[] memory incomingAssetAmounts_, uint256[] memory spendAssetAmounts_)
    {
        // INCOMING ASSETS

        incomingAssetAmounts_ = new uint256[](_incomingAssets.length);
        for (uint256 i; i < _incomingAssets.length; i++) {
            incomingAssetAmounts_[i] = __getVaultAssetBalance(_vaultProxy, _incomingAssets[i]).sub(
                _preCallIncomingAssetBalances[i]
            );
            require(
                incomingAssetAmounts_[i] >= _minIncomingAssetAmounts[i],
                "__postProcessCoI: Received incoming asset less than expected"
            );

            // Even if the asset's previous balance was >0, it might not have been tracked
            __addTrackedAsset(_comptrollerProxy, _incomingAssets[i]);
        }

        // SPEND ASSETS

        spendAssetAmounts_ = new uint256[](_spendAssets.length);
        for (uint256 i; i < _spendAssets.length; i++) {
            // Calculate the balance change of spend assets. Ignore if balance increased.
            uint256 postCallSpendAssetBalance = __getVaultAssetBalance(
                _vaultProxy,
                _spendAssets[i]
            );
            if (postCallSpendAssetBalance < _preCallSpendAssetBalances[i]) {
                spendAssetAmounts_[i] = _preCallSpendAssetBalances[i].sub(
                    postCallSpendAssetBalance
                );
            }

            // Reset any unused approvals
            if (
                _spendAssetsHandleType == SpendAssetsHandleType.Approve &&
                ERC20(_spendAssets[i]).allowance(_vaultProxy, _adapter) > 0
            ) {
                __approveAssetSpender(_comptrollerProxy, _spendAssets[i], _adapter, 0);
            } else if (_spendAssetsHandleType == SpendAssetsHandleType.None) {
                // Only need to validate _maxSpendAssetAmounts if not SpendAssetsHandleType.Approve
                // or SpendAssetsHandleType.Transfer, as each of those implicitly validate the max
                require(
                    spendAssetAmounts_[i] <= _maxSpendAssetAmounts[i],
                    "__postProcessCoI: Spent amount greater than expected"
                );
            }
        }

        return (incomingAssetAmounts_, spendAssetAmounts_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `POLICY_MANAGER` variable
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() public view returns (address policyManager_) {
        return POLICY_MANAGER;
    }

    /// @notice Gets the `VALUE_INTERPRETER` variable
    /// @return valueInterpreter_ The `VALUE_INTERPRETER` variable value
    function getValueInterpreter() public view returns (address valueInterpreter_) {
        return VALUE_INTERPRETER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../core/fund/comptroller/ComptrollerLib.sol";
import "../extensions/fee-manager/FeeManager.sol";

/// @title UnpermissionedActionsWrapper Contract
/// @author Enzyme Council <[email protected]>
/// @notice Logic related to wrapping actions that do not need access control
contract UnpermissionedActionsWrapper {
    address private immutable FEE_MANAGER;

    constructor(address _feeManager) public {
        FEE_MANAGER = _feeManager;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the net value of 1 unit of shares in the fund's denomination asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return netShareValue_ The amount of the denomination asset per share
    /// @dev Accounts for fees outstanding. This is a convenience function for external consumption
    /// that can be used to determine the cost of purchasing shares at any given point in time.
    /// It essentially just bundles settling all fees that implement the Continuous hook and then
    /// looking up the gross share value.
    function calcNetShareValueForFund(address _comptrollerProxy)
        external
        returns (uint256 netShareValue_)
    {
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);
        comptrollerProxyContract.callOnExtension(getFeeManager(), 0, "");

        return comptrollerProxyContract.calcGrossShareValue(false);
    }

    /// @notice Invokes the Continuous fee hook on all specified fees, and then attempts to payout
    /// any shares outstanding on those fees
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _fees The fees for which to run these actions
    /// @dev This is just a wrapper to execute two callOnExtension() actions atomically, in sequence.
    /// The caller must pass in the fees that they want to run this logic on.
    function invokeContinuousFeeHookAndPayoutSharesOutstandingForFund(
        address _comptrollerProxy,
        address[] calldata _fees
    ) external {
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);

        comptrollerProxyContract.callOnExtension(getFeeManager(), 0, "");
        comptrollerProxyContract.callOnExtension(getFeeManager(), 1, abi.encode(_fees));
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets all fees that implement the `Continuous` fee hook for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return continuousFees_ The fees that implement the `Continuous` fee hook
    function getContinuousFeesForFund(address _comptrollerProxy)
        public
        view
        returns (address[] memory continuousFees_)
    {
        FeeManager feeManagerContract = FeeManager(getFeeManager());

        address[] memory fees = feeManagerContract.getEnabledFeesForFund(_comptrollerProxy);

        // Count the continuous fees
        uint256 continuousFeesCount;
        bool[] memory implementsContinuousHook = new bool[](fees.length);
        for (uint256 i; i < fees.length; i++) {
            (bool settles, ) = IFee(fees[i]).settlesOnHook(IFeeManager.FeeHook.Continuous);
            if (settles) {
                continuousFeesCount++;
                implementsContinuousHook[i] = true;
            }
        }

        // Return early if no continuous fees
        if (continuousFeesCount == 0) {
            return new address[](0);
        }

        // Create continuous fees array
        continuousFees_ = new address[](continuousFeesCount);
        uint256 continuousFeesIndex;
        for (uint256 i; i < fees.length; i++) {
            if (implementsContinuousHook[i]) {
                continuousFees_[continuousFeesIndex] = fees[i];
                continuousFeesIndex++;
            }
        }

        return continuousFees_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FEE_MANAGER` variable
    /// @return feeManager_ The `FEE_MANAGER` variable value
    function getFeeManager() public view returns (address feeManager_) {
        return FEE_MANAGER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../core/fund/comptroller/ComptrollerLib.sol";
import "../interfaces/IWETH.sol";
import "../utils/AssetHelpers.sol";

/// @title DepositWrapper Contract
/// @author Enzyme Council <[email protected]>
/// @notice Logic related to wrapping deposit actions
contract DepositWrapper is AssetHelpers {
    address private immutable WETH_TOKEN;

    constructor(address _weth) public {
        WETH_TOKEN = _weth;
    }

    /// @dev Needed in case WETH not fully used during exchangeAndBuyShares,
    /// to unwrap into ETH and refund
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Exchanges ETH into a fund's denomination asset and then buys shares
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _minSharesQuantity The minimum quantity of shares to buy with the sent ETH
    /// @param _exchange The exchange on which to execute the swap to the denomination asset
    /// @param _exchangeApproveTarget The address that should be given an allowance of WETH
    /// for the given _exchange
    /// @param _exchangeData The data with which to call the exchange to execute the swap
    /// to the denomination asset
    /// @param _minInvestmentAmount The minimum amount of the denomination asset
    /// to receive in the trade for investment (not necessary for WETH)
    /// @return sharesReceived_ The actual amount of shares received
    /// @dev Use a reasonable _minInvestmentAmount always, in case the exchange
    /// does not perform as expected (low incoming asset amount, blend of assets, etc).
    /// If the fund's denomination asset is WETH, _exchange, _exchangeApproveTarget, _exchangeData,
    /// and _minInvestmentAmount will be ignored.
    function exchangeEthAndBuyShares(
        address _comptrollerProxy,
        address _denominationAsset,
        uint256 _minSharesQuantity,
        address _exchange,
        address _exchangeApproveTarget,
        bytes calldata _exchangeData,
        uint256 _minInvestmentAmount
    ) external payable returns (uint256 sharesReceived_) {
        // Wrap ETH into WETH
        IWETH(payable(getWethToken())).deposit{value: msg.value}();

        // If denominationAsset is WETH, can just buy shares directly
        if (_denominationAsset == getWethToken()) {
            __approveAssetMaxAsNeeded(getWethToken(), _comptrollerProxy, msg.value);

            return __buyShares(_comptrollerProxy, msg.sender, msg.value, _minSharesQuantity);
        }

        // Exchange ETH to the fund's denomination asset
        __approveAssetMaxAsNeeded(getWethToken(), _exchangeApproveTarget, msg.value);
        (bool success, bytes memory returnData) = _exchange.call(_exchangeData);
        require(success, string(returnData));

        // Confirm the amount received in the exchange is above the min acceptable amount
        uint256 investmentAmount = ERC20(_denominationAsset).balanceOf(address(this));
        require(
            investmentAmount >= _minInvestmentAmount,
            "exchangeAndBuyShares: _minInvestmentAmount not met"
        );

        // Give the ComptrollerProxy max allowance for its denomination asset as necessary
        __approveAssetMaxAsNeeded(_denominationAsset, _comptrollerProxy, investmentAmount);

        // Buy fund shares
        sharesReceived_ = __buyShares(
            _comptrollerProxy,
            msg.sender,
            investmentAmount,
            _minSharesQuantity
        );

        // Unwrap and refund any remaining WETH not used in the exchange
        uint256 remainingWeth = ERC20(getWethToken()).balanceOf(address(this));
        if (remainingWeth > 0) {
            IWETH(payable(getWethToken())).withdraw(remainingWeth);
            (success, returnData) = msg.sender.call{value: remainingWeth}("");
            require(success, string(returnData));
        }

        return sharesReceived_;
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper for buying shares
    function __buyShares(
        address _comptrollerProxy,
        address _buyer,
        uint256 _investmentAmount,
        uint256 _minSharesQuantity
    ) private returns (uint256 sharesReceived_) {
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);
        sharesReceived_ = comptrollerProxyContract.buySharesOnBehalf(
            _buyer,
            _investmentAmount,
            _minSharesQuantity
        );

        return sharesReceived_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IYearnVaultV2.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title YearnVaultV2ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with Yearn v2 vaults
abstract contract YearnVaultV2ActionsMixin is AssetHelpers {
    /// @dev Helper to lend underlying for yVault shares
    function __yearnVaultV2Lend(
        address _recipient,
        address _yVault,
        address _underlying,
        uint256 _underlyingAmount
    ) internal {
        __approveAssetMaxAsNeeded(_underlying, _yVault, _underlyingAmount);
        IYearnVaultV2(_yVault).deposit(_underlyingAmount, _recipient);
    }

    /// @dev Helper to redeem yVault shares for underlying
    function __yearnVaultV2Redeem(
        address _recipient,
        address _yVault,
        uint256 _yVaultSharesAmount,
        uint256 _slippageToleranceBps
    ) internal {
        IYearnVaultV2(_yVault).withdraw(_yVaultSharesAmount, _recipient, _slippageToleranceBps);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IYearnVaultV2 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with Yearn Vault V2 contracts
interface IYearnVaultV2 {
    function deposit(uint256, address) external returns (uint256);

    function pricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function withdraw(
        uint256,
        address,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../interfaces/IYearnVaultV2.sol";
import "../../../../interfaces/IYearnVaultV2Registry.sol";
import "../IDerivativePriceFeed.sol";
import "./utils/SingleUnderlyingDerivativeRegistryMixin.sol";

/// @title YearnVaultV2PriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Yearn Vault V2 shares
contract YearnVaultV2PriceFeed is IDerivativePriceFeed, SingleUnderlyingDerivativeRegistryMixin {
    using SafeMath for uint256;

    address private immutable YEARN_VAULT_V2_REGISTRY;

    constructor(address _fundDeployer, address _yearnVaultV2Registry)
        public
        SingleUnderlyingDerivativeRegistryMixin(_fundDeployer)
    {
        YEARN_VAULT_V2_REGISTRY = _yearnVaultV2Registry;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        underlyings_ = new address[](1);
        underlyings_[0] = getUnderlyingForDerivative(_derivative);
        require(underlyings_[0] != address(0), "calcUnderlyingValues: Unsupported derivative");

        underlyingAmounts_ = new uint256[](1);
        underlyingAmounts_[0] = _derivativeAmount
            .mul(IYearnVaultV2(_derivative).pricePerShare())
            .div(10**uint256(ERC20(_derivative).decimals()));
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return getUnderlyingForDerivative(_asset) != address(0);
    }

    /// @dev Helper to validate the derivative-underlying pair.
    /// Inherited from SingleUnderlyingDerivativeRegistryMixin.
    function __validateDerivative(address _derivative, address _underlying) internal override {
        // Only validate that the _derivative is a valid yVault using the V2 contract,
        // not that it is the latest vault for a particular _underlying
        bool isValidYearnVaultV2;
        IYearnVaultV2Registry yearnRegistryContract = IYearnVaultV2Registry(
            getYearnVaultV2Registry()
        );
        for (uint256 i; i < yearnRegistryContract.numVaults(_underlying); i++) {
            if (yearnRegistryContract.vaults(_underlying, i) == _derivative) {
                isValidYearnVaultV2 = true;
                break;
            }
        }
        require(isValidYearnVaultV2, "__validateDerivative: Invalid yVault for underlying");

        // Validates our assumption that yVaults and underlyings will have the same decimals
        require(
            ERC20(_derivative).decimals() == ERC20(_underlying).decimals(),
            "__validateDerivative: Incongruent decimals"
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `YEARN_VAULT_V2_REGISTRY` variable
    /// @return yearnVaultV2Registry_ The `YEARN_VAULT_V2_REGISTRY` variable value
    function getYearnVaultV2Registry() public view returns (address yearnVaultV2Registry_) {
        return YEARN_VAULT_V2_REGISTRY;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IYearnVaultV2Registry Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with the Yearn Vault V2 registry
interface IYearnVaultV2Registry {
    function numVaults(address) external view returns (uint256);

    function vaults(address, uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../utils/FundDeployerOwnerMixin.sol";

/// @title SingleUnderlyingDerivativeRegistryMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin for derivative price feeds that handle multiple derivatives
/// that each have a single underlying asset
abstract contract SingleUnderlyingDerivativeRegistryMixin is FundDeployerOwnerMixin {
    event DerivativeAdded(address indexed derivative, address indexed underlying);

    event DerivativeRemoved(address indexed derivative);

    mapping(address => address) private derivativeToUnderlying;

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {}

    /// @notice Adds derivatives with corresponding underlyings to the price feed
    /// @param _derivatives The derivatives to add
    /// @param _underlyings The corresponding underlyings to add
    function addDerivatives(address[] memory _derivatives, address[] memory _underlyings)
        external
        virtual
        onlyFundDeployerOwner
    {
        require(_derivatives.length > 0, "addDerivatives: Empty _derivatives");
        require(_derivatives.length == _underlyings.length, "addDerivatives: Unequal arrays");

        for (uint256 i; i < _derivatives.length; i++) {
            require(_derivatives[i] != address(0), "addDerivatives: Empty derivative");
            require(_underlyings[i] != address(0), "addDerivatives: Empty underlying");
            require(
                getUnderlyingForDerivative(_derivatives[i]) == address(0),
                "addDerivatives: Value already set"
            );

            __validateDerivative(_derivatives[i], _underlyings[i]);

            derivativeToUnderlying[_derivatives[i]] = _underlyings[i];

            emit DerivativeAdded(_derivatives[i], _underlyings[i]);
        }
    }

    /// @notice Removes derivatives from the price feed
    /// @param _derivatives The derivatives to remove
    function removeDerivatives(address[] memory _derivatives) external onlyFundDeployerOwner {
        require(_derivatives.length > 0, "removeDerivatives: Empty _derivatives");

        for (uint256 i; i < _derivatives.length; i++) {
            require(
                getUnderlyingForDerivative(_derivatives[i]) != address(0),
                "removeDerivatives: Value not set"
            );

            delete derivativeToUnderlying[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    /// @dev Optionally allow the inheriting price feed to validate the derivative-underlying pair
    function __validateDerivative(address, address) internal virtual {
        // UNIMPLEMENTED
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the underlying asset for a given derivative
    /// @param _derivative The derivative for which to get the underlying asset
    /// @return underlying_ The underlying asset
    function getUnderlyingForDerivative(address _derivative)
        public
        view
        returns (address underlying_)
    {
        return derivativeToUnderlying[_derivative];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/infrastructure/price-feeds/derivatives/feeds/utils/SingleUnderlyingDerivativeRegistryMixin.sol";

/// @title TestSingleUnderlyingDerivativeRegistry Contract
/// @author Enzyme Council <[email protected]>
/// @notice A test implementation of SingleUnderlyingDerivativeRegistryMixin
contract TestSingleUnderlyingDerivativeRegistry is SingleUnderlyingDerivativeRegistryMixin {
    constructor(address _dispatcher) public SingleUnderlyingDerivativeRegistryMixin(_dispatcher) {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/IIdleTokenV4.sol";
import "../IDerivativePriceFeed.sol";
import "./utils/SingleUnderlyingDerivativeRegistryMixin.sol";

/// @title IdlePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for IdleTokens
contract IdlePriceFeed is IDerivativePriceFeed, SingleUnderlyingDerivativeRegistryMixin {
    using SafeMath for uint256;

    uint256 private constant IDLE_TOKEN_UNIT = 10**18;

    constructor(address _fundDeployer)
        public
        SingleUnderlyingDerivativeRegistryMixin(_fundDeployer)
    {}

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        underlyings_ = new address[](1);
        underlyings_[0] = getUnderlyingForDerivative(_derivative);
        require(underlyings_[0] != address(0), "calcUnderlyingValues: Unsupported derivative");

        underlyingAmounts_ = new uint256[](1);
        underlyingAmounts_[0] = _derivativeAmount.mul(IIdleTokenV4(_derivative).tokenPrice()).div(
            IDLE_TOKEN_UNIT
        );
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return getUnderlyingForDerivative(_asset) != address(0);
    }

    /// @dev Helper to validate the derivative-underlying pair.
    /// Inherited from SingleUnderlyingDerivativeRegistryMixin.
    function __validateDerivative(address _derivative, address _underlying) internal override {
        require(
            IIdleTokenV4(_derivative).token() == _underlying,
            "__validateDerivative: Invalid underlying for IdleToken"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IIdleTokenV4 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with IdleToken (V4) contracts
interface IIdleTokenV4 {
    function getGovTokensAmounts(address) external view returns (uint256[] calldata);

    function govTokens(uint256) external view returns (address);

    function mintIdleToken(
        uint256,
        bool,
        address
    ) external returns (uint256);

    function redeemIdleToken(uint256) external returns (uint256);

    function token() external view returns (address);

    function tokenPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IIdleTokenV4.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title IdleV4ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with Idle tokens (V4)
abstract contract IdleV4ActionsMixin is AssetHelpers {
    address private constant IDLE_V4_REFERRAL_ACCOUNT = 0x1ad1fc9964c551f456238Dd88D6a38344B5319D7;

    /// @dev Helper to claim gov token rewards for an IdleToken balance.
    /// Requires that the current contract has already been transferred the idleToken balance.
    function __idleV4ClaimRewards(address _idleToken) internal {
        IIdleTokenV4(_idleToken).redeemIdleToken(0);
    }

    /// @dev Helper to get all rewards tokens for a specified idleToken
    function __idleV4GetRewardsTokens(address _idleToken)
        internal
        view
        returns (address[] memory rewardsTokens_)
    {
        IIdleTokenV4 idleTokenContract = IIdleTokenV4(_idleToken);

        rewardsTokens_ = new address[](idleTokenContract.getGovTokensAmounts(address(0)).length);
        for (uint256 i; i < rewardsTokens_.length; i++) {
            rewardsTokens_[i] = IIdleTokenV4(idleTokenContract).govTokens(i);
        }

        return rewardsTokens_;
    }

    /// @dev Helper to lend underlying for IdleToken
    function __idleV4Lend(
        address _idleToken,
        address _underlying,
        uint256 _underlyingAmount
    ) internal {
        __approveAssetMaxAsNeeded(_underlying, _idleToken, _underlyingAmount);
        IIdleTokenV4(_idleToken).mintIdleToken(_underlyingAmount, true, IDLE_V4_REFERRAL_ACCOUNT);
    }

    /// @dev Helper to redeem IdleToken for underlying
    function __idleV4Redeem(address _idleToken, uint256 _idleTokenAmount) internal {
        IIdleTokenV4(_idleToken).redeemIdleToken(_idleTokenAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../infrastructure/price-feeds/derivatives/feeds/IdlePriceFeed.sol";
import "../../../../interfaces/IIdleTokenV4.sol";
import "../../../../utils/AddressArrayLib.sol";
import "../utils/actions/IdleV4ActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title IdleAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Idle Lending <https://idle.finance/>
/// @dev There are some idiosyncrasies of reward accrual and claiming in IdleTokens that
/// are handled by this adapter:
/// - Rewards accrue to the IdleToken holder, but the accrued
/// amount is passed to the recipient of a transfer.
/// - Claiming rewards cannot be done on behalf of a holder, but must be done directly.
/// - Claiming rewards occurs automatically upon redeeming, but there are situations when
/// it is difficult to know whether to expect incoming rewards (e.g., after a user mints
/// idleTokens and then redeems before any other user has interacted with the protocol,
/// then getGovTokensAmounts() will return 0 balances). Because of this difficulty -
/// and in keeping with how other adapters treat claimed rewards -
/// this adapter does not report claimed rewards as incomingAssets.
contract IdleAdapter is AdapterBase, IdleV4ActionsMixin {
    using AddressArrayLib for address[];

    address private immutable IDLE_PRICE_FEED;

    constructor(address _integrationManager, address _idlePriceFeed)
        public
        AdapterBase(_integrationManager)
    {
        IDLE_PRICE_FEED = _idlePriceFeed;
    }

    /// @notice Claims rewards for a given IdleToken
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function claimRewards(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionSpendAssetsTransferHandler(_vaultProxy, _assetData)
    {
        address idleToken = __decodeClaimRewardsCallArgs(_actionData);

        __idleV4ClaimRewards(idleToken);

        __pushFullAssetBalances(_vaultProxy, __idleV4GetRewardsTokens(idleToken));
    }

    /// @notice Lends an amount of a token for idleToken
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        // More efficient to parse all from _assetData
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __idleV4Lend(incomingAssets[0], spendAssets[0], spendAssetAmounts[0]);
    }

    /// @notice Redeems an amount of idleToken for its underlying asset
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    /// @dev This will also pay out any due gov token rewards.
    /// We use the full IdleToken balance of the current contract rather than the user input
    /// for the corner case of a prior balance existing in the current contract, which would
    /// throw off the per-user avg price of the IdleToken used by Idle, and would leave the
    /// initial token balance in the current contract post-tx.
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (address idleToken, , ) = __decodeRedeemCallArgs(_actionData);

        __idleV4Redeem(idleToken, ERC20(idleToken).balanceOf(address(this)));

        __pushFullAssetBalances(_vaultProxy, __idleV4GetRewardsTokens(idleToken));
    }

    /// @dev Helper to get the underlying for a given IdleToken
    function __getUnderlyingForIdleToken(address _idleToken)
        private
        view
        returns (address underlying_)
    {
        return IdlePriceFeed(IDLE_PRICE_FEED).getUnderlyingForDerivative(_idleToken);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address _vaultProxy,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards(_vaultProxy, _actionData);
        } else if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls
    function __parseAssetsForClaimRewards(address _vaultProxy, bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        address idleToken = __decodeClaimRewardsCallArgs(_actionData);

        require(
            __getUnderlyingForIdleToken(idleToken) != address(0),
            "__parseAssetsForClaimRewards: Unsupported idleToken"
        );

        spendAssets_ = new address[](1);
        spendAssets_[0] = idleToken;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = ERC20(idleToken).balanceOf(_vaultProxy);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            new address[](0),
            new uint256[](0)
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address idleToken,
            uint256 outgoingUnderlyingAmount,
            uint256 minIncomingIdleTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        address underlying = __getUnderlyingForIdleToken(idleToken);
        require(underlying != address(0), "__parseAssetsForLend: Unsupported idleToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = underlying;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingUnderlyingAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = idleToken;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingIdleTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address idleToken,
            uint256 outgoingIdleTokenAmount,
            uint256 minIncomingUnderlyingAmount
        ) = __decodeRedeemCallArgs(_actionData);

        address underlying = __getUnderlyingForIdleToken(idleToken);
        require(underlying != address(0), "__parseAssetsForRedeem: Unsupported idleToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = idleToken;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingIdleTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = underlying;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingUnderlyingAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    /// @dev Helper to decode callArgs for claiming rewards tokens
    function __decodeClaimRewardsCallArgs(bytes memory _actionData)
        private
        pure
        returns (address idleToken_)
    {
        return abi.decode(_actionData, (address));
    }

    /// @dev Helper to decode callArgs for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address idleToken_,
            uint256 outgoingUnderlyingAmount_,
            uint256 minIncomingIdleTokenAmount_
        )
    {
        return abi.decode(_actionData, (address, uint256, uint256));
    }

    /// @dev Helper to decode callArgs for redeeming
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address idleToken_,
            uint256 outgoingIdleTokenAmount_,
            uint256 minIncomingUnderlyingAmount_
        )
    {
        return abi.decode(_actionData, (address, uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `IDLE_PRICE_FEED` variable
    /// @return idlePriceFeed_ The `IDLE_PRICE_FEED` variable value
    function getIdlePriceFeed() external view returns (address idlePriceFeed_) {
        return IDLE_PRICE_FEED;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/utils/AddressArrayLib.sol";

/// @title TestAddressArrayLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A test implementation of AddressArrayLib
contract TestAddressArrayLib {
    using AddressArrayLib for address[];

    function mergeArray(address[] memory _array, address[] memory _arrayToMerge)
        external
        pure
        returns (address[] memory nextArray_)
    {
        return _array.mergeArray(_arrayToMerge);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../core/fund/vault/IVault.sol";
import "../../infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "../../utils/AddressArrayLib.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../utils/ExtensionBase.sol";
import "./IPolicy.sol";
import "./IPolicyManager.sol";

/// @title PolicyManager Contract
/// @author Enzyme Council <[email protected]>
/// @notice Manages policies for funds
/// @dev Any arbitrary fee is allowed by default, so all participants must be aware of
/// their fund's configuration, especially whether they use official policies only.
/// Policies that restrict current investors can only be added upon fund setup, migration, or reconfiguration.
/// Policies that restrict new investors or asset management actions can be added at any time.
/// Policies themselves specify whether or not they are allowed to be updated or removed.
contract PolicyManager is
    IPolicyManager,
    ExtensionBase,
    FundDeployerOwnerMixin,
    GasRelayRecipientMixin
{
    using AddressArrayLib for address[];

    event PolicyDisabledForFund(address indexed comptrollerProxy, address indexed policy);

    event PolicyEnabledForFund(
        address indexed comptrollerProxy,
        address indexed policy,
        bytes settingsData
    );

    mapping(address => mapping(PolicyHook => address[])) private comptrollerProxyToHookToPolicies;

    modifier onlyFundOwner(address _comptrollerProxy) {
        require(
            __msgSender() == IVault(IComptroller(_comptrollerProxy).getVaultProxy()).getOwner(),
            "Only the fund owner can call this function"
        );
        _;
    }

    constructor(address _fundDeployer, address _gasRelayPaymasterFactory)
        public
        FundDeployerOwnerMixin(_fundDeployer)
        GasRelayRecipientMixin(_gasRelayPaymasterFactory)
    {}

    // EXTERNAL FUNCTIONS

    /// @notice Validates and initializes policies as necessary prior to fund activation
    /// @param _isMigratedFund True if the fund is migrating to this release
    /// @dev Caller is expected to be a valid ComptrollerProxy, but there isn't a need to validate.
    function activateForFund(bool _isMigratedFund) external override {
        // Policies must assert that they are congruent with migrated vault state
        if (_isMigratedFund) {
            address[] memory enabledPolicies = getEnabledPoliciesForFund(msg.sender);
            for (uint256 i; i < enabledPolicies.length; i++) {
                __activatePolicyForFund(msg.sender, enabledPolicies[i]);
            }
        }
    }

    /// @notice Disables a policy for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _policy The policy address to disable
    /// @dev If an arbitrary policy changes its `implementedHooks()` return values after it is
    /// already enabled on a fund, then this will not correctly disable the policy from any
    /// removed hook values
    function disablePolicyForFund(address _comptrollerProxy, address _policy)
        external
        onlyFundOwner(_comptrollerProxy)
    {
        require(IPolicy(_policy).canDisable(), "disablePolicyForFund: _policy cannot be disabled");

        bool disabled;
        PolicyHook[] memory implementedHooks = IPolicy(_policy).implementedHooks();
        for (uint256 i; i < implementedHooks.length; i++) {
            disabled = comptrollerProxyToHookToPolicies[_comptrollerProxy][implementedHooks[i]]
                .removeStorageItem(_policy);
        }
        require(disabled, "disablePolicyForFund: _policy is not enabled");

        emit PolicyDisabledForFund(_comptrollerProxy, _policy);
    }

    /// @notice Enables a policy for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _policy The policy address to enable
    /// @param _settingsData The encoded settings data with which to configure the policy
    /// @dev Disabling a policy does not delete fund config on the policy, so if a policy is
    /// disabled and then enabled again, its initial state will be the previous config. It is the
    /// policy's job to determine how to merge that config with the _settingsData param in this function.
    function enablePolicyForFund(
        address _comptrollerProxy,
        address _policy,
        bytes calldata _settingsData
    ) external onlyFundOwner(_comptrollerProxy) {
        PolicyHook[] memory implementedHooks = IPolicy(_policy).implementedHooks();
        for (uint256 i; i < implementedHooks.length; i++) {
            require(
                !__policyHookRestrictsCurrentInvestorActions(implementedHooks[i]),
                "enablePolicyForFund: _policy restricts actions of current investors"
            );
        }

        __enablePolicyForFund(_comptrollerProxy, _policy, _settingsData, implementedHooks);

        __activatePolicyForFund(_comptrollerProxy, _policy);
    }

    /// @notice Enable policies for use in a fund
    /// @param _configData Encoded config data
    /// @dev Only called during init() on ComptrollerProxy deployment
    function setConfigForFund(bytes calldata _configData) external override {
        (address[] memory policies, bytes[] memory settingsData) = abi.decode(
            _configData,
            (address[], bytes[])
        );

        // Sanity check
        require(
            policies.length == settingsData.length,
            "setConfigForFund: policies and settingsData array lengths unequal"
        );

        // Enable each policy with settings
        for (uint256 i; i < policies.length; i++) {
            __enablePolicyForFund(
                msg.sender,
                policies[i],
                settingsData[i],
                IPolicy(policies[i]).implementedHooks()
            );
        }
    }

    /// @notice Updates policy settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _policy The Policy contract to update
    /// @param _settingsData The encoded settings data with which to update the policy config
    function updatePolicySettingsForFund(
        address _comptrollerProxy,
        address _policy,
        bytes calldata _settingsData
    ) external onlyFundOwner(_comptrollerProxy) {
        IPolicy(_policy).updateFundSettings(_comptrollerProxy, _settingsData);
    }

    /// @notice Validates all policies that apply to a given hook for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _hook The PolicyHook for which to validate policies
    /// @param _validationData The encoded data with which to validate the filtered policies
    function validatePolicies(
        address _comptrollerProxy,
        PolicyHook _hook,
        bytes calldata _validationData
    ) external override {
        // Return as quickly as possible if no policies to run
        address[] memory policies = getEnabledPoliciesOnHookForFund(_comptrollerProxy, _hook);
        if (policies.length == 0) {
            return;
        }

        // Limit calls to trusted components, in case policies update local storage upon runs
        require(
            msg.sender == _comptrollerProxy ||
                msg.sender == IComptroller(_comptrollerProxy).getIntegrationManager() ||
                msg.sender == IComptroller(_comptrollerProxy).getExternalPositionManager(),
            "validatePolicies: Caller not allowed"
        );

        for (uint256 i; i < policies.length; i++) {
            require(
                IPolicy(policies[i]).validateRule(_comptrollerProxy, _hook, _validationData),
                string(
                    abi.encodePacked(
                        "Rule evaluated to false: ",
                        IPolicy(policies[i]).identifier()
                    )
                )
            );
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to activate a policy for a fund
    function __activatePolicyForFund(address _comptrollerProxy, address _policy) private {
        IPolicy(_policy).activateForFund(_comptrollerProxy);
    }

    /// @dev Helper to set config and enable policies for a fund
    function __enablePolicyForFund(
        address _comptrollerProxy,
        address _policy,
        bytes memory _settingsData,
        PolicyHook[] memory _hooks
    ) private {
        // Set fund config on policy
        if (_settingsData.length > 0) {
            IPolicy(_policy).addFundSettings(_comptrollerProxy, _settingsData);
        }

        // Add policy
        for (uint256 i; i < _hooks.length; i++) {
            require(
                !policyIsEnabledOnHookForFund(_comptrollerProxy, _hooks[i], _policy),
                "__enablePolicyForFund: Policy is already enabled"
            );
            comptrollerProxyToHookToPolicies[_comptrollerProxy][_hooks[i]].push(_policy);
        }

        emit PolicyEnabledForFund(_comptrollerProxy, _policy, _settingsData);
    }

    /// @dev Helper to get all the hooks available to policies
    function __getAllPolicyHooks() private pure returns (PolicyHook[10] memory hooks_) {
        return [
            PolicyHook.PostBuyShares,
            PolicyHook.PostCallOnIntegration,
            PolicyHook.PreTransferShares,
            PolicyHook.RedeemSharesForSpecificAssets,
            PolicyHook.AddTrackedAssets,
            PolicyHook.RemoveTrackedAssets,
            PolicyHook.CreateExternalPosition,
            PolicyHook.PostCallOnExternalPosition,
            PolicyHook.RemoveExternalPosition,
            PolicyHook.ReactivateExternalPosition
        ];
    }

    /// @dev Helper to check if a policy hook restricts the actions of current investors.
    /// These hooks should not allow policy additions post-deployment or post-migration.
    function __policyHookRestrictsCurrentInvestorActions(PolicyHook _hook)
        private
        pure
        returns (bool restrictsActions_)
    {
        return
            _hook == PolicyHook.PreTransferShares ||
            _hook == PolicyHook.RedeemSharesForSpecificAssets;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Get a list of enabled policies for the given fund
    /// @param _comptrollerProxy The ComptrollerProxy
    /// @return enabledPolicies_ The array of enabled policy addresses
    function getEnabledPoliciesForFund(address _comptrollerProxy)
        public
        view
        returns (address[] memory enabledPolicies_)
    {
        PolicyHook[10] memory hooks = __getAllPolicyHooks();

        for (uint256 i; i < hooks.length; i++) {
            enabledPolicies_ = enabledPolicies_.mergeArray(
                getEnabledPoliciesOnHookForFund(_comptrollerProxy, hooks[i])
            );
        }

        return enabledPolicies_;
    }

    /// @notice Get a list of enabled policies that run on a given hook for the given fund
    /// @param _comptrollerProxy The ComptrollerProxy
    /// @param _hook The PolicyHook
    /// @return enabledPolicies_ The array of enabled policy addresses
    function getEnabledPoliciesOnHookForFund(address _comptrollerProxy, PolicyHook _hook)
        public
        view
        returns (address[] memory enabledPolicies_)
    {
        return comptrollerProxyToHookToPolicies[_comptrollerProxy][_hook];
    }

    /// @notice Check whether a given policy runs on a given hook for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy
    /// @param _hook The PolicyHook
    /// @param _policy The policy
    /// @return isEnabled_ True if the policy is enabled
    function policyIsEnabledOnHookForFund(
        address _comptrollerProxy,
        PolicyHook _hook,
        address _policy
    ) public view returns (bool isEnabled_) {
        return getEnabledPoliciesOnHookForFund(_comptrollerProxy, _hook).contains(_policy);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./IPolicyManager.sol";

/// @title Policy Interface
/// @author Enzyme Council <[email protected]>
interface IPolicy {
    function activateForFund(address _comptrollerProxy) external;

    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings) external;

    function canDisable() external pure returns (bool canDisable_);

    function identifier() external pure returns (string memory identifier_);

    function implementedHooks()
        external
        pure
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_);

    function updateFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external;

    function validateRule(
        address _comptrollerProxy,
        IPolicyManager.PolicyHook _hook,
        bytes calldata _encodedArgs
    ) external returns (bool isValid_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/IGsnRelayHub.sol";
import "../../interfaces/IGsnTypes.sol";
import "../../interfaces/IWETH.sol";
import "../../core/fund/comptroller/ComptrollerLib.sol";
import "../../core/fund/vault/IVault.sol";
import "../../core/fund-deployer/FundDeployer.sol";
import "../../extensions/policy-manager/PolicyManager.sol";
import "./bases/GasRelayPaymasterLibBase1.sol";
import "./IGasRelayPaymaster.sol";
import "./IGasRelayPaymasterDepositor.sol";

/// @title GasRelayPaymasterLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core logic library for the "paymaster" contract which refunds GSN relayers
contract GasRelayPaymasterLib is IGasRelayPaymaster, GasRelayPaymasterLibBase1 {
    using SafeMath for uint256;

    // Immutable and constants
    // Sane defaults, subject to change after gas profiling
    uint256 private constant CALLDATA_SIZE_LIMIT = 10500;
    // Deposit in wei
    uint256 private constant DEPOSIT = 0.2 ether;
    // Sane defaults, subject to change after gas profiling
    uint256 private constant PRE_RELAYED_CALL_GAS_LIMIT = 100000;
    uint256 private constant POST_RELAYED_CALL_GAS_LIMIT = 110000;
    // FORWARDER_HUB_OVERHEAD = 50000;
    // PAYMASTER_ACCEPTANCE_BUDGET = FORWARDER_HUB_OVERHEAD + PRE_RELAYED_CALL_GAS_LIMIT
    uint256 private constant PAYMASTER_ACCEPTANCE_BUDGET = 150000;

    address private immutable RELAY_HUB;
    address private immutable TRUSTED_FORWARDER;
    address private immutable WETH_TOKEN;

    modifier onlyComptroller() {
        require(
            msg.sender == getParentComptroller(),
            "Can only be called by the parent comptroller"
        );
        _;
    }

    modifier relayHubOnly() {
        require(msg.sender == getHubAddr(), "Can only be called by RelayHub");
        _;
    }

    constructor(
        address _wethToken,
        address _relayHub,
        address _trustedForwarder
    ) public {
        RELAY_HUB = _relayHub;
        TRUSTED_FORWARDER = _trustedForwarder;
        WETH_TOKEN = _wethToken;
    }

    // INIT

    /// @notice Initializes a paymaster proxy
    /// @param _vault The VaultProxy associated with the paymaster proxy
    /// @dev Used to set the owning vault
    function init(address _vault) external {
        require(getParentVault() == address(0), "init: Paymaster already initialized");

        parentVault = _vault;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Pull deposit from the vault and reactivate relaying
    function deposit() external override onlyComptroller {
        __depositMax();
    }

    /// @notice Checks whether the paymaster will pay for a given relayed tx
    /// @param _relayRequest The full relay request structure
    /// @return context_ The tx signer and the fn sig, encoded so that it can be passed to `postRelayCall`
    /// @return rejectOnRecipientRevert_ ALways false
    function preRelayedCall(
        IGsnTypes.RelayRequest calldata _relayRequest,
        bytes calldata,
        bytes calldata,
        uint256
    )
        external
        override
        relayHubOnly
        returns (bytes memory context_, bool rejectOnRecipientRevert_)
    {
        address vaultProxy = getParentVault();
        require(
            IVault(vaultProxy).canRelayCalls(_relayRequest.request.from),
            "preRelayedCall: Unauthorized caller"
        );

        bytes4 selector = __parseTxDataFunctionSelector(_relayRequest.request.data);
        require(
            __isAllowedCall(
                vaultProxy,
                _relayRequest.request.to,
                selector,
                _relayRequest.request.data
            ),
            "preRelayedCall: Function call not permitted"
        );

        return (abi.encode(_relayRequest.request.from, selector), false);
    }

    /// @notice Called by the relay hub after the relayed tx is executed, tops up deposit if flag passed through paymasterdata is true
    /// @param _context The context constructed by preRelayedCall (used to pass data from pre to post relayed call)
    /// @param _success Whether or not the relayed tx succeed
    /// @param _relayData The relay params of the request. can be used by relayHub.calculateCharge()
    function postRelayedCall(
        bytes calldata _context,
        bool _success,
        uint256,
        IGsnTypes.RelayData calldata _relayData
    ) external override relayHubOnly {
        bool shouldTopUpDeposit = abi.decode(_relayData.paymasterData, (bool));
        if (shouldTopUpDeposit) {
            __depositMax();
        }

        (address spender, bytes4 selector) = abi.decode(_context, (address, bytes4));
        emit TransactionRelayed(spender, selector, _success);
    }

    /// @notice Send any deposited ETH back to the vault
    function withdrawBalance() external override {
        address vaultProxy = getParentVault();
        require(
            msg.sender == IVault(vaultProxy).getOwner() ||
                msg.sender == __getComptrollerForVault(vaultProxy),
            "shutdownRelayer: Only owner or comptroller is authorized"
        );

        IGsnRelayHub(getHubAddr()).withdraw(getRelayHubDeposit(), payable(address(this)));

        uint256 amount = address(this).balance;

        Address.sendValue(payable(vaultProxy), amount);

        emit Withdrawn(amount);
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the current ComptrollerProxy of the VaultProxy associated with this contract
    /// @return parentComptroller_ The ComptrollerProxy
    function getParentComptroller() public view returns (address parentComptroller_) {
        return __getComptrollerForVault(parentVault);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to pull WETH from the associated vault to top up to the max ETH deposit in the relay hub
    function __depositMax() private {
        uint256 amount = DEPOSIT.sub(getRelayHubDeposit());

        IGasRelayPaymasterDepositor(getParentComptroller()).pullWethForGasRelayer(amount);

        IWETH(getWethToken()).withdraw(amount);

        IGsnRelayHub(getHubAddr()).depositFor{value: amount}(address(this));

        emit Deposited(amount);
    }

    /// @dev Helper to get the ComptrollerProxy for a given VaultProxy
    function __getComptrollerForVault(address _vaultProxy)
        private
        view
        returns (address comptrollerProxy_)
    {
        return IVault(_vaultProxy).getAccessor();
    }

    /// @dev Helper to check if a contract call is allowed to be relayed using this paymaster
    /// Allowed contracts are:
    /// - VaultProxy
    /// - ComptrollerProxy
    /// - PolicyManager
    /// - FundDeployer
    function __isAllowedCall(
        address _vaultProxy,
        address _contract,
        bytes4 _selector,
        bytes calldata _txData
    ) private view returns (bool allowed_) {
        if (_contract == _vaultProxy) {
            // All calls to the VaultProxy are allowed
            return true;
        }

        address parentComptroller = __getComptrollerForVault(_vaultProxy);
        if (_contract == parentComptroller) {
            if (
                _selector == ComptrollerLib.callOnExtension.selector ||
                _selector == ComptrollerLib.vaultCallOnContract.selector ||
                _selector == ComptrollerLib.buyBackProtocolFeeShares.selector ||
                _selector == ComptrollerLib.depositToGasRelayPaymaster.selector ||
                _selector == ComptrollerLib.setAutoProtocolFeeSharesBuyback.selector
            ) {
                return true;
            }
        } else if (_contract == ComptrollerLib(parentComptroller).getPolicyManager()) {
            if (
                _selector == PolicyManager.updatePolicySettingsForFund.selector ||
                _selector == PolicyManager.enablePolicyForFund.selector ||
                _selector == PolicyManager.disablePolicyForFund.selector
            ) {
                return __parseTxDataFirstParameterAsAddress(_txData) == getParentComptroller();
            }
        } else if (_contract == ComptrollerLib(parentComptroller).getFundDeployer()) {
            if (
                _selector == FundDeployer.createReconfigurationRequest.selector ||
                _selector == FundDeployer.executeReconfiguration.selector ||
                _selector == FundDeployer.cancelReconfiguration.selector
            ) {
                return __parseTxDataFirstParameterAsAddress(_txData) == getParentVault();
            }
        }

        return false;
    }

    /// @notice Parses the first parameter of tx data as an address
    /// @param _txData The tx data to retrieve the address from
    /// @return retrievedAddress_ The extracted address
    function __parseTxDataFirstParameterAsAddress(bytes calldata _txData)
        private
        pure
        returns (address retrievedAddress_)
    {
        require(
            _txData.length >= 36,
            "__parseTxDataFirstParameterAsAddress: _txData is not a valid length"
        );

        return abi.decode(_txData[4:36], (address));
    }

    /// @notice Parses the function selector from tx data
    /// @param _txData The tx data
    /// @return functionSelector_ The extracted function selector
    function __parseTxDataFunctionSelector(bytes calldata _txData)
        private
        pure
        returns (bytes4 functionSelector_)
    {
        /// convert bytes[:4] to bytes4
        require(
            _txData.length >= 4,
            "__parseTxDataFunctionSelector: _txData is not a valid length"
        );

        functionSelector_ =
            _txData[0] |
            (bytes4(_txData[1]) >> 8) |
            (bytes4(_txData[2]) >> 16) |
            (bytes4(_txData[3]) >> 24);

        return functionSelector_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets gas limits used by the relay hub for the pre and post relay calls
    /// @return limits_ `GasAndDataLimits(PAYMASTER_ACCEPTANCE_BUDGET, PRE_RELAYED_CALL_GAS_LIMIT, POST_RELAYED_CALL_GAS_LIMIT, CALLDATA_SIZE_LIMIT)`
    function getGasAndDataLimits()
        external
        view
        override
        returns (IGsnPaymaster.GasAndDataLimits memory limits_)
    {
        return
            IGsnPaymaster.GasAndDataLimits(
                PAYMASTER_ACCEPTANCE_BUDGET,
                PRE_RELAYED_CALL_GAS_LIMIT,
                POST_RELAYED_CALL_GAS_LIMIT,
                CALLDATA_SIZE_LIMIT
            );
    }

    /// @notice Gets the `RELAY_HUB` variable value
    /// @return relayHub_ The `RELAY_HUB` value
    function getHubAddr() public view override returns (address relayHub_) {
        return RELAY_HUB;
    }

    /// @notice Gets the `parentVault` variable value
    /// @return parentVault_ The `parentVault` value
    function getParentVault() public view returns (address parentVault_) {
        return parentVault;
    }

    /// @notice Look up amount of ETH deposited on the relay hub
    /// @return depositBalance_ amount of ETH deposited on the relay hub
    function getRelayHubDeposit() public view override returns (uint256 depositBalance_) {
        return IGsnRelayHub(getHubAddr()).balanceOf(address(this));
    }

    /// @notice Gets the `WETH_TOKEN` variable value
    /// @return wethToken_ The `WETH_TOKEN` value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }

    /// @notice Gets the `TRUSTED_FORWARDER` variable value
    /// @return trustedForwarder_ The forwarder contract which is trusted to validated the relayed tx signature
    function trustedForwarder() external view override returns (address trustedForwarder_) {
        return TRUSTED_FORWARDER;
    }

    /// @notice Gets the string representation of the contract version (fulfills interface)
    /// @return versionString_ The version string
    function versionPaymaster() external view override returns (string memory versionString_) {
        return "2.2.3+opengsn.enzymefund.ipaymaster";
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IGsnTypes.sol";

/// @title IGsnRelayHub Interface
/// @author Enzyme Council <[email protected]>
interface IGsnRelayHub {
    function balanceOf(address target) external view returns (uint256);

    function calculateCharge(uint256 gasUsed, IGsnTypes.RelayData calldata relayData)
        external
        view
        returns (uint256);

    function depositFor(address target) external payable;

    function relayCall(
        uint256 maxAcceptanceBudget,
        IGsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 externalGasLimit
    ) external returns (bool paymasterAccepted, bytes memory returnValue);

    function withdraw(uint256 amount, address payable dest) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../../../persistent/dispatcher/IMigrationHookHandler.sol";
import "../../infrastructure/gas-relayer/GasRelayRecipientMixin.sol";
import "../../infrastructure/protocol-fees/IProtocolFeeTracker.sol";
import "../fund/comptroller/ComptrollerProxy.sol";
import "../fund/comptroller/IComptroller.sol";
import "../fund/vault/IVault.sol";
import "./IFundDeployer.sol";

/// @title FundDeployer Contract
/// @author Enzyme Council <[email protected]>
/// @notice The top-level contract of the release.
/// It primarily coordinates fund deployment and fund migration, but
/// it is also deferred to for contract access control and for allowed calls
/// that can be made with a fund's VaultProxy as the msg.sender.
contract FundDeployer is IFundDeployer, IMigrationHookHandler, GasRelayRecipientMixin {
    event BuySharesOnBehalfCallerDeregistered(address caller);

    event BuySharesOnBehalfCallerRegistered(address caller);

    event ComptrollerLibSet(address comptrollerLib);

    event ComptrollerProxyDeployed(
        address indexed creator,
        address comptrollerProxy,
        address indexed denominationAsset,
        uint256 sharesActionTimelock,
        bytes feeManagerConfigData,
        bytes policyManagerConfigData
    );

    event MigrationRequestCreated(
        address indexed creator,
        address indexed vaultProxy,
        address comptrollerProxy
    );

    event NewFundCreated(address indexed creator, address vaultProxy, address comptrollerProxy);

    event ProtocolFeeTrackerSet(address protocolFeeTracker);

    event ReconfigurationRequestCancelled(
        address indexed vaultProxy,
        address indexed nextComptrollerProxy
    );

    event ReconfigurationRequestCreated(
        address indexed creator,
        address indexed vaultProxy,
        address comptrollerProxy,
        uint256 executableTimestamp
    );

    event ReconfigurationRequestExecuted(
        address indexed vaultProxy,
        address indexed prevComptrollerProxy,
        address indexed nextComptrollerProxy
    );

    event ReconfigurationTimelockSet(uint256 nextTimelock);

    event ReleaseIsLive();

    event VaultCallDeregistered(
        address indexed contractAddress,
        bytes4 selector,
        bytes32 dataHash
    );

    event VaultCallRegistered(address indexed contractAddress, bytes4 selector, bytes32 dataHash);

    event VaultLibSet(address vaultLib);

    struct ReconfigurationRequest {
        address nextComptrollerProxy;
        uint256 executableTimestamp;
    }

    // Constants
    // keccak256(abi.encodePacked("mln.vaultCall.any")
    bytes32
        private constant ANY_VAULT_CALL = 0x5bf1898dd28c4d29f33c4c1bb9b8a7e2f6322847d70be63e8f89de024d08a669;

    address private immutable CREATOR;
    address private immutable DISPATCHER;

    // Pseudo-constants (can only be set once)
    address private comptrollerLib;
    address private protocolFeeTracker;
    address private vaultLib;

    // Storage
    bool private isLive;
    uint256 private reconfigurationTimelock;

    mapping(address => bool) private acctToIsAllowedBuySharesOnBehalfCaller;
    mapping(bytes32 => mapping(bytes32 => bool)) private vaultCallToPayloadToIsAllowed;
    mapping(address => ReconfigurationRequest) private vaultProxyToReconfigurationRequest;

    modifier onlyDispatcher() {
        require(msg.sender == DISPATCHER, "Only Dispatcher can call this function");
        _;
    }

    modifier onlyLiveRelease() {
        require(releaseIsLive(), "Release is not yet live");
        _;
    }

    modifier onlyMigrator(address _vaultProxy) {
        __assertIsMigrator(_vaultProxy, __msgSender());
        _;
    }

    modifier onlyMigratorNotRelayable(address _vaultProxy) {
        __assertIsMigrator(_vaultProxy, msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "Only the contract owner can call this function");
        _;
    }

    modifier pseudoConstant(address _storageValue) {
        require(_storageValue == address(0), "This value can only be set once");
        _;
    }

    function __assertIsMigrator(address _vaultProxy, address _who) private view {
        require(
            IVault(_vaultProxy).canMigrate(_who),
            "Only a permissioned migrator can call this function"
        );
    }

    constructor(address _dispatcher, address _gasRelayPaymasterFactory)
        public
        GasRelayRecipientMixin(_gasRelayPaymasterFactory)
    {
        // Validate constants
        require(
            ANY_VAULT_CALL == keccak256(abi.encodePacked("mln.vaultCall.any")),
            "constructor: Incorrect ANY_VAULT_CALL"
        );

        CREATOR = msg.sender;
        DISPATCHER = _dispatcher;

        reconfigurationTimelock = 2 days;
    }

    //////////////////////////////////////
    // PSEUDO-CONSTANTS (only set once) //
    //////////////////////////////////////

    /// @notice Sets the ComptrollerLib
    /// @param _comptrollerLib The ComptrollerLib contract address
    function setComptrollerLib(address _comptrollerLib)
        external
        onlyOwner
        pseudoConstant(getComptrollerLib())
    {
        comptrollerLib = _comptrollerLib;

        emit ComptrollerLibSet(_comptrollerLib);
    }

    /// @notice Sets the ProtocolFeeTracker
    /// @param _protocolFeeTracker The ProtocolFeeTracker contract address
    function setProtocolFeeTracker(address _protocolFeeTracker)
        external
        onlyOwner
        pseudoConstant(getProtocolFeeTracker())
    {
        protocolFeeTracker = _protocolFeeTracker;

        emit ProtocolFeeTrackerSet(_protocolFeeTracker);
    }

    /// @notice Sets the VaultLib
    /// @param _vaultLib The VaultLib contract address
    function setVaultLib(address _vaultLib) external onlyOwner pseudoConstant(getVaultLib()) {
        vaultLib = _vaultLib;

        emit VaultLibSet(_vaultLib);
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Gets the current owner of the contract
    /// @return owner_ The contract owner address
    /// @dev The owner is initially the contract's creator, for convenience in setting up configuration.
    /// Ownership is handed-off when the creator calls setReleaseLive().
    function getOwner() public view override returns (address owner_) {
        if (!releaseIsLive()) {
            return getCreator();
        }

        return IDispatcher(getDispatcher()).getOwner();
    }

    /// @notice Sets the release as live
    /// @dev A live release allows funds to be created and migrated once this contract
    /// is set as the Dispatcher.currentFundDeployer
    function setReleaseLive() external {
        require(
            msg.sender == getCreator(),
            "setReleaseLive: Only the creator can call this function"
        );
        require(!releaseIsLive(), "setReleaseLive: Already live");

        // All pseudo-constants should be set
        require(getComptrollerLib() != address(0), "setReleaseLive: comptrollerLib is not set");
        require(
            getProtocolFeeTracker() != address(0),
            "setReleaseLive: protocolFeeTracker is not set"
        );
        require(getVaultLib() != address(0), "setReleaseLive: vaultLib is not set");

        isLive = true;

        emit ReleaseIsLive();
    }

    ///////////////////
    // FUND CREATION //
    ///////////////////

    /// @notice Creates a fully-configured ComptrollerProxy instance for a VaultProxy and signals the migration process
    /// @param _vaultProxy The VaultProxy to migrate
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    /// @param _bypassPrevReleaseFailure True if should override a failure in the previous release while signaling migration
    /// @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
    function createMigrationRequest(
        address _vaultProxy,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData,
        bool _bypassPrevReleaseFailure
    )
        external
        onlyLiveRelease
        onlyMigratorNotRelayable(_vaultProxy)
        returns (address comptrollerProxy_)
    {
        // Bad _vaultProxy value is validated by Dispatcher.signalMigration()

        comptrollerProxy_ = __deployComptrollerProxy(
            msg.sender,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData
        );

        IComptroller(comptrollerProxy_).setVaultProxy(_vaultProxy);

        IDispatcher(getDispatcher()).signalMigration(
            _vaultProxy,
            comptrollerProxy_,
            getVaultLib(),
            _bypassPrevReleaseFailure
        );

        emit MigrationRequestCreated(msg.sender, _vaultProxy, comptrollerProxy_);

        return comptrollerProxy_;
    }

    /// @notice Creates a new fund
    /// @param _fundOwner The address of the owner for the fund
    /// @param _fundName The name of the fund
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    /// @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
    function createNewFund(
        address _fundOwner,
        string calldata _fundName,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external onlyLiveRelease returns (address comptrollerProxy_, address vaultProxy_) {
        // _fundOwner is validated by VaultLib.__setOwner()
        address canonicalSender = __msgSender();

        comptrollerProxy_ = __deployComptrollerProxy(
            canonicalSender,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData
        );

        vaultProxy_ = IDispatcher(getDispatcher()).deployVaultProxy(
            getVaultLib(),
            _fundOwner,
            comptrollerProxy_,
            _fundName
        );

        IComptroller comptrollerContract = IComptroller(comptrollerProxy_);
        comptrollerContract.setVaultProxy(vaultProxy_);
        comptrollerContract.activate(false);

        IProtocolFeeTracker(getProtocolFeeTracker()).initializeForVault(vaultProxy_);

        emit NewFundCreated(canonicalSender, vaultProxy_, comptrollerProxy_);

        return (comptrollerProxy_, vaultProxy_);
    }

    /// @notice Creates a fully-configured ComptrollerProxy instance for a VaultProxy and signals the reconfiguration process
    /// @param _vaultProxy The VaultProxy to reconfigure
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    /// @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
    function createReconfigurationRequest(
        address _vaultProxy,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external returns (address comptrollerProxy_) {
        address canonicalSender = __msgSender();
        __assertIsMigrator(_vaultProxy, canonicalSender);
        require(
            IDispatcher(getDispatcher()).getFundDeployerForVaultProxy(_vaultProxy) ==
                address(this),
            "createReconfigurationRequest: VaultProxy not on this release"
        );
        require(
            !hasReconfigurationRequest(_vaultProxy),
            "createReconfigurationRequest: VaultProxy has a pending reconfiguration request"
        );

        comptrollerProxy_ = __deployComptrollerProxy(
            canonicalSender,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData
        );

        IComptroller(comptrollerProxy_).setVaultProxy(_vaultProxy);

        uint256 executableTimestamp = block.timestamp + getReconfigurationTimelock();
        vaultProxyToReconfigurationRequest[_vaultProxy] = ReconfigurationRequest({
            nextComptrollerProxy: comptrollerProxy_,
            executableTimestamp: executableTimestamp
        });

        emit ReconfigurationRequestCreated(
            canonicalSender,
            _vaultProxy,
            comptrollerProxy_,
            executableTimestamp
        );

        return comptrollerProxy_;
    }

    /// @dev Helper function to deploy a configured ComptrollerProxy
    function __deployComptrollerProxy(
        address _canonicalSender,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData
    ) private returns (address comptrollerProxy_) {
        // _denominationAsset is validated by ComptrollerLib.init()

        bytes memory constructData = abi.encodeWithSelector(
            IComptroller.init.selector,
            _denominationAsset,
            _sharesActionTimelock
        );
        comptrollerProxy_ = address(new ComptrollerProxy(constructData, getComptrollerLib()));

        if (_feeManagerConfigData.length > 0 || _policyManagerConfigData.length > 0) {
            IComptroller(comptrollerProxy_).configureExtensions(
                _feeManagerConfigData,
                _policyManagerConfigData
            );
        }

        emit ComptrollerProxyDeployed(
            _canonicalSender,
            comptrollerProxy_,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData
        );

        return comptrollerProxy_;
    }

    ///////////////////////////////////////////////
    // RECONFIGURATION (INTRA-RELEASE MIGRATION) //
    ///////////////////////////////////////////////

    /// @notice Cancels a pending reconfiguration request
    /// @param _vaultProxy The VaultProxy contract for which to cancel the reconfiguration request
    function cancelReconfiguration(address _vaultProxy) external onlyMigrator(_vaultProxy) {
        address nextComptrollerProxy = vaultProxyToReconfigurationRequest[_vaultProxy]
            .nextComptrollerProxy;
        require(
            nextComptrollerProxy != address(0),
            "cancelReconfiguration: No reconfiguration request exists for _vaultProxy"
        );

        // Destroy the nextComptrollerProxy
        IComptroller(nextComptrollerProxy).destructUnactivated();

        // Remove the reconfiguration request
        delete vaultProxyToReconfigurationRequest[_vaultProxy];

        emit ReconfigurationRequestCancelled(_vaultProxy, nextComptrollerProxy);
    }

    /// @notice Executes a pending reconfiguration request
    /// @param _vaultProxy The VaultProxy contract for which to execute the reconfiguration request
    /// @dev ProtocolFeeTracker.initializeForVault() does not need to be included in a reconfiguration,
    /// as it refers to the vault and not the new ComptrollerProxy
    function executeReconfiguration(address _vaultProxy) external onlyMigrator(_vaultProxy) {
        ReconfigurationRequest memory request = getReconfigurationRequestForVaultProxy(
            _vaultProxy
        );
        require(
            request.nextComptrollerProxy != address(0),
            "executeReconfiguration: No reconfiguration request exists for _vaultProxy"
        );
        require(
            block.timestamp >= request.executableTimestamp,
            "executeReconfiguration: The reconfiguration timelock has not elapsed"
        );
        // Not technically necessary, but a nice assurance
        require(
            IDispatcher(getDispatcher()).getFundDeployerForVaultProxy(_vaultProxy) ==
                address(this),
            "executeReconfiguration: _vaultProxy is no longer on this release"
        );

        // Unwind and destroy the prevComptrollerProxy before setting the nextComptrollerProxy as the VaultProxy.accessor
        address prevComptrollerProxy = IVault(_vaultProxy).getAccessor();
        address paymaster = IComptroller(prevComptrollerProxy).getGasRelayPaymaster();
        IComptroller(prevComptrollerProxy).destructActivated();

        // Execute the reconfiguration
        IVault(_vaultProxy).setAccessorForFundReconfiguration(request.nextComptrollerProxy);

        // Activate the new ComptrollerProxy
        IComptroller(request.nextComptrollerProxy).activate(true);
        if (paymaster != address(0)) {
            IComptroller(request.nextComptrollerProxy).setGasRelayPaymaster(paymaster);
        }

        // Remove the reconfiguration request
        delete vaultProxyToReconfigurationRequest[_vaultProxy];

        emit ReconfigurationRequestExecuted(
            _vaultProxy,
            prevComptrollerProxy,
            request.nextComptrollerProxy
        );
    }

    /// @notice Sets a new reconfiguration timelock
    /// @param _nextTimelock The number of seconds for the new timelock
    function setReconfigurationTimelock(uint256 _nextTimelock) external onlyOwner {
        reconfigurationTimelock = _nextTimelock;

        emit ReconfigurationTimelockSet(_nextTimelock);
    }

    //////////////////
    // MIGRATION IN //
    //////////////////

    /// @notice Cancels fund migration
    /// @param _vaultProxy The VaultProxy for which to cancel migration
    /// @param _bypassPrevReleaseFailure True if should override a failure in the previous release while canceling migration
    function cancelMigration(address _vaultProxy, bool _bypassPrevReleaseFailure)
        external
        onlyMigratorNotRelayable(_vaultProxy)
    {
        IDispatcher(getDispatcher()).cancelMigration(_vaultProxy, _bypassPrevReleaseFailure);
    }

    /// @notice Executes fund migration
    /// @param _vaultProxy The VaultProxy for which to execute the migration
    /// @param _bypassPrevReleaseFailure True if should override a failure in the previous release while executing migration
    function executeMigration(address _vaultProxy, bool _bypassPrevReleaseFailure)
        external
        onlyMigratorNotRelayable(_vaultProxy)
    {
        IDispatcher dispatcherContract = IDispatcher(getDispatcher());

        (, address comptrollerProxy, , ) = dispatcherContract
            .getMigrationRequestDetailsForVaultProxy(_vaultProxy);

        dispatcherContract.executeMigration(_vaultProxy, _bypassPrevReleaseFailure);

        IComptroller(comptrollerProxy).activate(true);

        IProtocolFeeTracker(getProtocolFeeTracker()).initializeForVault(_vaultProxy);
    }

    /// @notice Executes logic when a migration is canceled on the Dispatcher
    /// @param _nextComptrollerProxy The ComptrollerProxy created on this release
    function invokeMigrationInCancelHook(
        address,
        address,
        address _nextComptrollerProxy,
        address
    ) external override onlyDispatcher {
        IComptroller(_nextComptrollerProxy).destructUnactivated();
    }

    ///////////////////
    // MIGRATION OUT //
    ///////////////////

    /// @notice Allows "hooking into" specific moments in the migration pipeline
    /// to execute arbitrary logic during a migration out of this release
    /// @param _vaultProxy The VaultProxy being migrated
    function invokeMigrationOutHook(
        MigrationOutHook _hook,
        address _vaultProxy,
        address,
        address,
        address
    ) external override onlyDispatcher {
        if (_hook != MigrationOutHook.PreMigrate) {
            return;
        }

        // Must use PreMigrate hook to get the ComptrollerProxy from the VaultProxy
        address comptrollerProxy = IVault(_vaultProxy).getAccessor();

        // Wind down fund and destroy its config
        IComptroller(comptrollerProxy).destructActivated();
    }

    //////////////
    // REGISTRY //
    //////////////

    // BUY SHARES CALLERS

    /// @notice Deregisters allowed callers of ComptrollerProxy.buySharesOnBehalf()
    /// @param _callers The callers to deregister
    function deregisterBuySharesOnBehalfCallers(address[] calldata _callers) external onlyOwner {
        for (uint256 i; i < _callers.length; i++) {
            require(
                isAllowedBuySharesOnBehalfCaller(_callers[i]),
                "deregisterBuySharesOnBehalfCallers: Caller not registered"
            );

            acctToIsAllowedBuySharesOnBehalfCaller[_callers[i]] = false;

            emit BuySharesOnBehalfCallerDeregistered(_callers[i]);
        }
    }

    /// @notice Registers allowed callers of ComptrollerProxy.buySharesOnBehalf()
    /// @param _callers The allowed callers
    /// @dev Validate that each registered caller only forwards requests to buy shares that
    /// originate from the same _buyer passed into buySharesOnBehalf(). This is critical
    /// to the integrity of VaultProxy.freelyTransferableShares.
    function registerBuySharesOnBehalfCallers(address[] calldata _callers) external onlyOwner {
        for (uint256 i; i < _callers.length; i++) {
            require(
                !isAllowedBuySharesOnBehalfCaller(_callers[i]),
                "registerBuySharesOnBehalfCallers: Caller already registered"
            );

            acctToIsAllowedBuySharesOnBehalfCaller[_callers[i]] = true;

            emit BuySharesOnBehalfCallerRegistered(_callers[i]);
        }
    }

    // VAULT CALLS

    /// @notice De-registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to de-register
    /// @param _selectors The selectors of the calls to de-register
    /// @param _dataHashes The keccak call data hashes of the calls to de-register
    /// @dev ANY_VAULT_CALL is a wildcard that allows any payload
    function deregisterVaultCalls(
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        bytes32[] memory _dataHashes
    ) external onlyOwner {
        require(_contracts.length > 0, "deregisterVaultCalls: Empty _contracts");
        require(
            _contracts.length == _selectors.length && _contracts.length == _dataHashes.length,
            "deregisterVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                isRegisteredVaultCall(_contracts[i], _selectors[i], _dataHashes[i]),
                "deregisterVaultCalls: Call not registered"
            );

            vaultCallToPayloadToIsAllowed[keccak256(
                abi.encodePacked(_contracts[i], _selectors[i])
            )][_dataHashes[i]] = false;

            emit VaultCallDeregistered(_contracts[i], _selectors[i], _dataHashes[i]);
        }
    }

    /// @notice Registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to register
    /// @param _selectors The selectors of the calls to register
    /// @param _dataHashes The keccak call data hashes of the calls to register
    /// @dev ANY_VAULT_CALL is a wildcard that allows any payload
    function registerVaultCalls(
        address[] calldata _contracts,
        bytes4[] calldata _selectors,
        bytes32[] memory _dataHashes
    ) external onlyOwner {
        require(_contracts.length > 0, "registerVaultCalls: Empty _contracts");
        require(
            _contracts.length == _selectors.length && _contracts.length == _dataHashes.length,
            "registerVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                !isRegisteredVaultCall(_contracts[i], _selectors[i], _dataHashes[i]),
                "registerVaultCalls: Call already registered"
            );

            vaultCallToPayloadToIsAllowed[keccak256(
                abi.encodePacked(_contracts[i], _selectors[i])
            )][_dataHashes[i]] = true;

            emit VaultCallRegistered(_contracts[i], _selectors[i], _dataHashes[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Checks if a contract call is allowed
    /// @param _contract The contract of the call to check
    /// @param _selector The selector of the call to check
    /// @param _dataHash The keccak call data hash of the call to check
    /// @return isAllowed_ True if the call is allowed
    /// @dev A vault call is allowed if the _dataHash is specifically allowed,
    /// or if any _dataHash is allowed
    function isAllowedVaultCall(
        address _contract,
        bytes4 _selector,
        bytes32 _dataHash
    ) external view override returns (bool isAllowed_) {
        bytes32 contractFunctionHash = keccak256(abi.encodePacked(_contract, _selector));

        return
            vaultCallToPayloadToIsAllowed[contractFunctionHash][_dataHash] ||
            vaultCallToPayloadToIsAllowed[contractFunctionHash][ANY_VAULT_CALL];
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the `comptrollerLib` variable value
    /// @return comptrollerLib_ The `comptrollerLib` variable value
    function getComptrollerLib() public view returns (address comptrollerLib_) {
        return comptrollerLib;
    }

    /// @notice Gets the `CREATOR` variable value
    /// @return creator_ The `CREATOR` variable value
    function getCreator() public view returns (address creator_) {
        return CREATOR;
    }

    /// @notice Gets the `DISPATCHER` variable value
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the `protocolFeeTracker` variable value
    /// @return protocolFeeTracker_ The `protocolFeeTracker` variable value
    function getProtocolFeeTracker() public view returns (address protocolFeeTracker_) {
        return protocolFeeTracker;
    }

    /// @notice Gets the pending ReconfigurationRequest for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return reconfigurationRequest_ The pending ReconfigurationRequest
    function getReconfigurationRequestForVaultProxy(address _vaultProxy)
        public
        view
        returns (ReconfigurationRequest memory reconfigurationRequest_)
    {
        return vaultProxyToReconfigurationRequest[_vaultProxy];
    }

    /// @notice Gets the amount of time that must pass before executing a ReconfigurationRequest
    /// @return reconfigurationTimelock_ The timelock value (in seconds)
    function getReconfigurationTimelock() public view returns (uint256 reconfigurationTimelock_) {
        return reconfigurationTimelock;
    }

    /// @notice Gets the `vaultLib` variable value
    /// @return vaultLib_ The `vaultLib` variable value
    function getVaultLib() public view returns (address vaultLib_) {
        return vaultLib;
    }

    /// @notice Checks whether a ReconfigurationRequest exists for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return hasReconfigurationRequest_ True if a ReconfigurationRequest exists
    function hasReconfigurationRequest(address _vaultProxy)
        public
        view
        override
        returns (bool hasReconfigurationRequest_)
    {
        return vaultProxyToReconfigurationRequest[_vaultProxy].nextComptrollerProxy != address(0);
    }

    /// @notice Checks if an account is an allowed caller of ComptrollerProxy.buySharesOnBehalf()
    /// @param _who The account to check
    /// @return isAllowed_ True if the account is an allowed caller
    function isAllowedBuySharesOnBehalfCaller(address _who)
        public
        view
        override
        returns (bool isAllowed_)
    {
        return acctToIsAllowedBuySharesOnBehalfCaller[_who];
    }

    /// @notice Checks if a contract call is registered
    /// @param _contract The contract of the call to check
    /// @param _selector The selector of the call to check
    /// @param _dataHash The keccak call data hash of the call to check
    /// @return isRegistered_ True if the call is registered
    function isRegisteredVaultCall(
        address _contract,
        bytes4 _selector,
        bytes32 _dataHash
    ) public view returns (bool isRegistered_) {
        return
            vaultCallToPayloadToIsAllowed[keccak256(
                abi.encodePacked(_contract, _selector)
            )][_dataHash];
    }

    /// @notice Gets the `isLive` variable value
    /// @return isLive_ The `isLive` variable value
    function releaseIsLive() public view returns (bool isLive_) {
        return isLive;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title GasRelayPaymasterLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and events
/// for a GasRelayPaymasterLib
/// @dev DO NOT EDIT CONTRACT ONCE DEPLOYED. If new events or storage are necessary,
/// they should be added to a numbered GasRelayPaymasterLibBaseXXX that inherits the previous base.
/// e.g., `GasRelayPaymasterLibBase2 is GasRelayPaymasterLibBase1`
abstract contract GasRelayPaymasterLibBase1 {
    event Deposited(uint256 amount);

    event TransactionRelayed(address indexed authorizer, bytes4 invokedSelector, bool successful);

    event Withdrawn(uint256 amount);

    // Pseudo-constants
    address internal parentVault;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMigrationHookHandler Interface
/// @author Enzyme Council <[email protected]>
interface IMigrationHookHandler {
    enum MigrationOutHook {PreSignal, PostSignal, PreMigrate, PostMigrate, PostCancel}

    function invokeMigrationInCancelHook(
        address _vaultProxy,
        address _prevFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib
    ) external;

    function invokeMigrationOutHook(
        MigrationOutHook _hook,
        address _vaultProxy,
        address _nextFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../utils/NonUpgradableProxy.sol";

/// @title ComptrollerProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all ComptrollerProxy instances
contract ComptrollerProxy is NonUpgradableProxy {
    constructor(bytes memory _constructData, address _comptrollerLib)
        public
        NonUpgradableProxy(_constructData, _comptrollerLib)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title NonUpgradableProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for use with non-upgradable libs
/// @dev The recommended constructor-fallback pattern of a proxy in EIP-1822, updated for solc 0.6.12,
/// and using an immutable lib value to save on gas (since not upgradable).
/// The EIP-1967 storage slot for the lib is still assigned,
/// for ease of referring to UIs that understand the pattern, i.e., Etherscan.
abstract contract NonUpgradableProxy {
    address private immutable CONTRACT_LOGIC;

    constructor(bytes memory _constructData, address _contractLogic) public {
        CONTRACT_LOGIC = _contractLogic;

        assembly {
            // EIP-1967 slot: `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _contractLogic
            )
        }
        (bool success, bytes memory returnData) = _contractLogic.delegatecall(_constructData);
        require(success, string(returnData));
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = CONTRACT_LOGIC;

        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "./IProtocolFeeTracker.sol";

/// @title ProtocolFeeTracker Contract
/// @author Enzyme Council <[email protected]>
/// @notice The contract responsible for tracking owed protocol fees
contract ProtocolFeeTracker is IProtocolFeeTracker, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event InitializedForVault(address vaultProxy);

    event FeeBpsDefaultSet(uint256 nextFeeBpsDefault);

    event FeeBpsOverrideSetForVault(address indexed vaultProxy, uint256 nextFeeBpsOverride);

    event FeePaidForVault(address indexed vaultProxy, uint256 sharesAmount, uint256 secondsPaid);

    event LastPaidSetForVault(
        address indexed vaultProxy,
        uint256 prevTimestamp,
        uint256 nextTimestamp
    );

    uint256 private constant MAX_BPS = 10000;
    uint256 private constant SECONDS_IN_YEAR = 31557600; // 60*60*24*365.25

    uint256 private feeBpsDefault;
    mapping(address => uint256) private vaultProxyToFeeBpsOverride;
    mapping(address => uint256) private vaultProxyToLastPaid;

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {
        // Validate constants
        require(
            SECONDS_IN_YEAR == (60 * 60 * 24 * 36525) / 100,
            "constructor: Incorrect SECONDS_IN_YEAR"
        );
    }

    // EXTERNAL FUNCTIONS

    /// @notice Initializes protocol fee tracking for a given VaultProxy
    /// @param _vaultProxy The VaultProxy
    /// @dev Does not validate whether _vaultProxy is already initialized,
    /// as FundDeployer will only do this once
    function initializeForVault(address _vaultProxy) external override {
        require(msg.sender == getFundDeployer(), "Only the FundDeployer can call this function");

        __setLastPaidForVault(_vaultProxy, block.timestamp);

        emit InitializedForVault(_vaultProxy);
    }

    /// @notice Marks the protocol fee as paid for the sender, and gets the amount of shares that
    /// should be minted for payment
    /// @return sharesDue_ The amount of shares to be minted for payment
    /// @dev This trusts the VaultProxy to mint the correct sharesDue_.
    /// There is no need to validate that the VaultProxy is still on this release.
    function payFee() external override returns (uint256 sharesDue_) {
        address vaultProxy = msg.sender;

        // VaultProxy is validated during initialization
        uint256 lastPaid = getLastPaidForVault(vaultProxy);
        if (lastPaid >= block.timestamp) {
            return 0;
        }

        // Not strictly necessary as we trust the FundDeployer to have already initialized the
        // VaultProxy, but inexpensive
        require(lastPaid > 0, "payFee: VaultProxy not initialized");

        uint256 secondsDue = block.timestamp.sub(lastPaid);
        sharesDue_ = __calcSharesDueForVault(vaultProxy, secondsDue);

        // Even if sharesDue_ is 0, we update the lastPaid timestamp and emit the event
        __setLastPaidForVault(vaultProxy, block.timestamp);

        emit FeePaidForVault(vaultProxy, sharesDue_, secondsDue);

        return sharesDue_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the protocol fee rate (in bps) for a given VaultProxy
    /// @param _vaultProxy The VaultProxy
    /// @return feeBps_ The protocol fee (in bps)
    function getFeeBpsForVault(address _vaultProxy) public view returns (uint256 feeBps_) {
        feeBps_ = getFeeBpsOverrideForVault(_vaultProxy);

        if (feeBps_ == 0) {
            feeBps_ = getFeeBpsDefault();
        }

        return feeBps_;
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to calculate the protocol fee shares due for a given VaultProxy
    function __calcSharesDueForVault(address _vaultProxy, uint256 _secondsDue)
        private
        view
        returns (uint256 sharesDue_)
    {
        uint256 sharesSupply = ERC20(_vaultProxy).totalSupply();

        uint256 rawSharesDue = sharesSupply
            .mul(getFeeBpsForVault(_vaultProxy))
            .mul(_secondsDue)
            .div(SECONDS_IN_YEAR)
            .div(MAX_BPS);

        uint256 supplyNetRawSharesDue = sharesSupply.sub(rawSharesDue);
        if (supplyNetRawSharesDue == 0) {
            return 0;
        }

        return rawSharesDue.mul(sharesSupply).div(supplyNetRawSharesDue);
    }

    /// @dev Helper to set the lastPaid timestamp for a given VaultProxy
    function __setLastPaidForVault(address _vaultProxy, uint256 _nextTimestamp) private {
        vaultProxyToLastPaid[_vaultProxy] = _nextTimestamp;
    }

    ////////////////
    // ADMIN ONLY //
    ////////////////

    /// @notice Sets the default protocol fee rate (in bps)
    /// @param _nextFeeBpsDefault The default protocol fee rate (in bps) to set
    function setFeeBpsDefault(uint256 _nextFeeBpsDefault) external onlyFundDeployerOwner {
        require(_nextFeeBpsDefault < MAX_BPS, "setDefaultFeeBps: Exceeds max");

        feeBpsDefault = _nextFeeBpsDefault;

        emit FeeBpsDefaultSet(_nextFeeBpsDefault);
    }

    /// @notice Sets a specified protocol fee rate (in bps) for a particular VaultProxy
    /// @param _vaultProxy The VaultProxy
    /// @param _nextFeeBpsOverride The protocol fee rate (in bps) to set
    function setFeeBpsOverrideForVault(address _vaultProxy, uint256 _nextFeeBpsOverride)
        external
        onlyFundDeployerOwner
    {
        require(_nextFeeBpsOverride < MAX_BPS, "setFeeBpsOverrideForVault: Exceeds max");

        vaultProxyToFeeBpsOverride[_vaultProxy] = _nextFeeBpsOverride;

        emit FeeBpsOverrideSetForVault(_vaultProxy, _nextFeeBpsOverride);
    }

    /// @notice Sets the lastPaid timestamp for a specified VaultProxy
    /// @param _vaultProxy The VaultProxy
    /// @param _nextTimestamp The lastPaid timestamp to set
    function setLastPaidForVault(address _vaultProxy, uint256 _nextTimestamp)
        external
        onlyFundDeployerOwner
    {
        uint256 prevTimestamp = getLastPaidForVault(_vaultProxy);
        require(prevTimestamp > 0, "setLastPaidForVault: _vaultProxy not initialized");
        require(
            _nextTimestamp > prevTimestamp || _nextTimestamp > block.timestamp,
            "setLastPaidForVault: Can only increase or set a future timestamp"
        );

        __setLastPaidForVault(_vaultProxy, _nextTimestamp);

        emit LastPaidSetForVault(_vaultProxy, prevTimestamp, _nextTimestamp);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `feeBpsDefault` variable value
    /// @return feeBpsDefault_ The `feeBpsDefault` variable value
    function getFeeBpsDefault() public view returns (uint256 feeBpsDefault_) {
        return feeBpsDefault;
    }

    /// @notice Gets the feeBpsOverride value for the given VaultProxy
    /// @param _vaultProxy The VaultProxy
    /// @return feeBpsOverride_ The feeBpsOverride value
    function getFeeBpsOverrideForVault(address _vaultProxy)
        public
        view
        returns (uint256 feeBpsOverride_)
    {
        return vaultProxyToFeeBpsOverride[_vaultProxy];
    }

    /// @notice Gets the lastPaid value for the given VaultProxy
    /// @param _vaultProxy The VaultProxy
    /// @return lastPaid_ The lastPaid value
    function getLastPaidForVault(address _vaultProxy) public view returns (uint256 lastPaid_) {
        return vaultProxyToLastPaid[_vaultProxy];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../IDerivativePriceFeed.sol";

/// @title SinglePeggedDerivativePriceFeedBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed base for any single derivative that is pegged 1:1 to its underlying
abstract contract SinglePeggedDerivativePriceFeedBase is IDerivativePriceFeed {
    address private immutable DERIVATIVE;
    address private immutable UNDERLYING;

    constructor(address _derivative, address _underlying) public {
        require(
            ERC20(_derivative).decimals() == ERC20(_underlying).decimals(),
            "constructor: Unequal decimals"
        );

        DERIVATIVE = _derivative;
        UNDERLYING = _underlying;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        require(isSupportedAsset(_derivative), "calcUnderlyingValues: Not a supported derivative");

        underlyings_ = new address[](1);
        underlyings_[0] = UNDERLYING;
        underlyingAmounts_ = new uint256[](1);
        underlyingAmounts_[0] = _derivativeAmount;

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return _asset == DERIVATIVE;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DERIVATIVE` variable value
    /// @return derivative_ The `DERIVATIVE` variable value
    function getDerivative() external view returns (address derivative_) {
        return DERIVATIVE;
    }

    /// @notice Gets the `UNDERLYING` variable value
    /// @return underlying_ The `UNDERLYING` variable value
    function getUnderlying() external view returns (address underlying_) {
        return UNDERLYING;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/infrastructure/price-feeds/derivatives/feeds/utils/SinglePeggedDerivativePriceFeedBase.sol";

/// @title TestSingleUnderlyingDerivativeRegistry Contract
/// @author Enzyme Council <[email protected]>
/// @notice A test implementation of SinglePeggedDerivativePriceFeedBase
contract TestSinglePeggedDerivativePriceFeed is SinglePeggedDerivativePriceFeedBase {
    constructor(address _derivative, address _underlying)
        public
        SinglePeggedDerivativePriceFeedBase(_derivative, _underlying)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/SinglePeggedDerivativePriceFeedBase.sol";

/// @title StakehoundEthPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Stakehound stETH, which maps 1:1 with ETH
contract StakehoundEthPriceFeed is SinglePeggedDerivativePriceFeedBase {
    constructor(address _steth, address _weth)
        public
        SinglePeggedDerivativePriceFeedBase(_steth, _weth)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/SinglePeggedDerivativePriceFeedBase.sol";

/// @title LidoStethPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Lido stETH, which maps 1:1 with ETH (https://lido.fi/)
contract LidoStethPriceFeed is SinglePeggedDerivativePriceFeedBase {
    constructor(address _steth, address _weth)
        public
        SinglePeggedDerivativePriceFeedBase(_steth, _weth)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../interfaces/ICurveAddressProvider.sol";
import "../../../../interfaces/ICurveLiquidityGaugeToken.sol";
import "../../../../interfaces/ICurveLiquidityPool.sol";
import "../../../../interfaces/ICurveRegistry.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title CurvePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed for Curve pool tokens
contract CurvePriceFeed is IDerivativePriceFeed, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event DerivativeAdded(
        address indexed derivative,
        address indexed pool,
        address indexed invariantProxyAsset,
        uint256 invariantProxyAssetDecimals
    );

    event DerivativeRemoved(address indexed derivative);

    // Both pool tokens and liquidity gauge tokens are treated the same for pricing purposes.
    // We take one asset as representative of the pool's invariant, e.g., WETH for ETH-based pools.
    struct DerivativeInfo {
        address pool;
        address invariantProxyAsset;
        uint256 invariantProxyAssetDecimals;
    }

    uint256 private constant VIRTUAL_PRICE_UNIT = 10**18;

    address private immutable ADDRESS_PROVIDER;

    mapping(address => DerivativeInfo) private derivativeToInfo;

    constructor(address _fundDeployer, address _addressProvider)
        public
        FundDeployerOwnerMixin(_fundDeployer)
    {
        ADDRESS_PROVIDER = _addressProvider;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        public
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        DerivativeInfo memory derivativeInfo = derivativeToInfo[_derivative];
        require(
            derivativeInfo.pool != address(0),
            "calcUnderlyingValues: _derivative is not supported"
        );

        underlyings_ = new address[](1);
        underlyings_[0] = derivativeInfo.invariantProxyAsset;

        underlyingAmounts_ = new uint256[](1);
        if (derivativeInfo.invariantProxyAssetDecimals == 18) {
            underlyingAmounts_[0] = _derivativeAmount
                .mul(ICurveLiquidityPool(derivativeInfo.pool).get_virtual_price())
                .div(VIRTUAL_PRICE_UNIT);
        } else {
            underlyingAmounts_[0] = _derivativeAmount
                .mul(ICurveLiquidityPool(derivativeInfo.pool).get_virtual_price())
                .mul(10**derivativeInfo.invariantProxyAssetDecimals)
                .div(VIRTUAL_PRICE_UNIT)
                .div(VIRTUAL_PRICE_UNIT);
        }

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return derivativeToInfo[_asset].pool != address(0);
    }

    //////////////////////////
    // DERIVATIVES REGISTRY //
    //////////////////////////

    /// @notice Adds Curve LP and/or liquidity gauge tokens to the price feed
    /// @param _derivatives Curve LP and/or liquidity gauge tokens to add
    /// @param _invariantProxyAssets The ordered assets that act as proxies to the pool invariants,
    /// corresponding to each item in _derivatives, e.g., WETH for ETH-based pools
    function addDerivatives(
        address[] calldata _derivatives,
        address[] calldata _invariantProxyAssets
    ) external onlyFundDeployerOwner {
        require(_derivatives.length > 0, "addDerivatives: Empty _derivatives");
        require(
            _derivatives.length == _invariantProxyAssets.length,
            "addDerivatives: Unequal arrays"
        );

        ICurveRegistry curveRegistryContract = ICurveRegistry(
            ICurveAddressProvider(ADDRESS_PROVIDER).get_registry()
        );

        for (uint256 i; i < _derivatives.length; i++) {
            require(_derivatives[i] != address(0), "addDerivatives: Empty derivative");
            require(
                _invariantProxyAssets[i] != address(0),
                "addDerivatives: Empty invariantProxyAsset"
            );
            require(!isSupportedAsset(_derivatives[i]), "addDerivatives: Value already set");

            // First, try assuming that the derivative is an LP token
            address pool = curveRegistryContract.get_pool_from_lp_token(_derivatives[i]);

            // If the derivative is not a valid LP token, try to treat it as a liquidity gauge token
            if (pool == address(0)) {
                // We cannot confirm whether a liquidity gauge token is a valid token
                // for a particular liquidity gauge, due to some pools using
                // old liquidity gauge contracts that did not incorporate a token
                pool = curveRegistryContract.get_pool_from_lp_token(
                    ICurveLiquidityGaugeToken(_derivatives[i]).lp_token()
                );

                // Likely unreachable as above calls will revert on Curve, but doesn't hurt
                require(
                    pool != address(0),
                    "addDerivatives: Not a valid LP token or liquidity gauge token"
                );
            }

            uint256 invariantProxyAssetDecimals = ERC20(_invariantProxyAssets[i]).decimals();
            derivativeToInfo[_derivatives[i]] = DerivativeInfo({
                pool: pool,
                invariantProxyAsset: _invariantProxyAssets[i],
                invariantProxyAssetDecimals: invariantProxyAssetDecimals
            });

            // Confirm that a non-zero price can be returned for the registered derivative
            (, uint256[] memory underlyingAmounts) = calcUnderlyingValues(
                _derivatives[i],
                1 ether
            );
            require(underlyingAmounts[0] > 0, "addDerivatives: could not calculate valid price");

            emit DerivativeAdded(
                _derivatives[i],
                pool,
                _invariantProxyAssets[i],
                invariantProxyAssetDecimals
            );
        }
    }

    /// @notice Removes Curve LP and/or liquidity gauge tokens from the price feed
    /// @param _derivatives Curve LP and/or liquidity gauge tokens to add
    function removeDerivatives(address[] calldata _derivatives) external onlyFundDeployerOwner {
        require(_derivatives.length > 0, "removeDerivatives: Empty _derivatives");
        for (uint256 i; i < _derivatives.length; i++) {
            require(_derivatives[i] != address(0), "removeDerivatives: Empty derivative");
            require(isSupportedAsset(_derivatives[i]), "removeDerivatives: Value is not set");

            delete derivativeToInfo[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ADDRESS_PROVIDER` variable
    /// @return addressProvider_ The `ADDRESS_PROVIDER` variable value
    function getAddressProvider() external view returns (address addressProvider_) {
        return ADDRESS_PROVIDER;
    }

    /// @notice Gets the `DerivativeInfo` for a given derivative
    /// @param _derivative The derivative for which to get the `DerivativeInfo`
    /// @return derivativeInfo_ The `DerivativeInfo` value
    function getDerivativeInfo(address _derivative)
        external
        view
        returns (DerivativeInfo memory derivativeInfo_)
    {
        return derivativeToInfo[_derivative];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <[email protected]>
interface ICurveAddressProvider {
    function get_address(uint256) external view returns (address);

    function get_registry() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveLiquidityGaugeToken interface
/// @author Enzyme Council <[email protected]>
/// @notice Common interface functions for all Curve liquidity gauge token contracts
interface ICurveLiquidityGaugeToken {
    function lp_token() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveLiquidityPool interface
/// @author Enzyme Council <[email protected]>
interface ICurveLiquidityPool {
    function coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveRegistry interface
/// @author Enzyme Council <[email protected]>
interface ICurveRegistry {
    function get_gauges(address) external view returns (address[10] memory, int128[10] memory);

    function get_lp_token(address) external view returns (address);

    function get_pool_from_lp_token(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/ICurveAddressProvider.sol";
import "../../../../../interfaces/ICurveSwapsERC20.sol";
import "../../../../../interfaces/ICurveSwapsEther.sol";
import "../../../../../interfaces/IWETH.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title CurveExchangeActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Curve exchange functions
/// @dev Inheriting contract must have a receive() function
abstract contract CurveExchangeActionsMixin is AssetHelpers {
    address
        private constant CURVE_EXCHANGE_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address private immutable CURVE_EXCHANGE_ADDRESS_PROVIDER;
    address private immutable CURVE_EXCHANGE_WETH_TOKEN;

    constructor(address _addressProvider, address _wethToken) public {
        CURVE_EXCHANGE_ADDRESS_PROVIDER = _addressProvider;
        CURVE_EXCHANGE_WETH_TOKEN = _wethToken;
    }

    /// @dev Helper to execute takeOrder
    function __curveTakeOrder(
        address _recipient,
        address _pool,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        address _incomingAsset,
        uint256 _minIncomingAssetAmount
    ) internal {
        address swaps = ICurveAddressProvider(CURVE_EXCHANGE_ADDRESS_PROVIDER).get_address(2);

        if (_outgoingAsset == CURVE_EXCHANGE_WETH_TOKEN) {
            IWETH(CURVE_EXCHANGE_WETH_TOKEN).withdraw(_outgoingAssetAmount);

            ICurveSwapsEther(swaps).exchange{value: _outgoingAssetAmount}(
                _pool,
                CURVE_EXCHANGE_ETH_ADDRESS,
                _incomingAsset,
                _outgoingAssetAmount,
                _minIncomingAssetAmount,
                _recipient
            );
        } else if (_incomingAsset == CURVE_EXCHANGE_WETH_TOKEN) {
            __approveAssetMaxAsNeeded(_outgoingAsset, swaps, _outgoingAssetAmount);

            ICurveSwapsERC20(swaps).exchange(
                _pool,
                _outgoingAsset,
                CURVE_EXCHANGE_ETH_ADDRESS,
                _outgoingAssetAmount,
                _minIncomingAssetAmount,
                address(this)
            );

            // Wrap received ETH and send back to the recipient
            uint256 receivedAmount = payable(address(this)).balance;
            IWETH(payable(CURVE_EXCHANGE_WETH_TOKEN)).deposit{value: receivedAmount}();
            ERC20(CURVE_EXCHANGE_WETH_TOKEN).safeTransfer(_recipient, receivedAmount);
        } else {
            __approveAssetMaxAsNeeded(_outgoingAsset, swaps, _outgoingAssetAmount);

            ICurveSwapsERC20(swaps).exchange(
                _pool,
                _outgoingAsset,
                _incomingAsset,
                _outgoingAssetAmount,
                _minIncomingAssetAmount,
                _recipient
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_EXCHANGE_ADDRESS_PROVIDER` variable
    /// @return curveExchangeAddressProvider_ The `CURVE_EXCHANGE_ADDRESS_PROVIDER` variable value
    function getCurveExchangeAddressProvider()
        public
        view
        returns (address curveExchangeAddressProvider_)
    {
        return CURVE_EXCHANGE_ADDRESS_PROVIDER;
    }

    /// @notice Gets the `CURVE_EXCHANGE_WETH_TOKEN` variable
    /// @return curveExchangeWethToken_ The `CURVE_EXCHANGE_WETH_TOKEN` variable value
    function getCurveExchangeWethToken() public view returns (address curveExchangeWethToken_) {
        return CURVE_EXCHANGE_WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveSwapsERC20 Interface
/// @author Enzyme Council <[email protected]>
interface ICurveSwapsERC20 {
    function exchange(
        address,
        address,
        address,
        uint256,
        uint256,
        address
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveSwapsEther Interface
/// @author Enzyme Council <[email protected]>
interface ICurveSwapsEther {
    function exchange(
        address,
        address,
        address,
        uint256,
        uint256,
        address
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../../interfaces/ICurveStableSwapSteth.sol";
import "../../../../../interfaces/IWETH.sol";

/// @title CurveStethLiquidityActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Curve steth pool's liquidity functions
/// @dev Inheriting contract must have a receive() function
abstract contract CurveStethLiquidityActionsMixin {
    using SafeERC20 for ERC20;

    int128 private constant CURVE_STETH_POOL_INDEX_ETH = 0;
    int128 private constant CURVE_STETH_POOL_INDEX_STETH = 1;

    address private immutable CURVE_STETH_LIQUIDITY_POOL;
    address private immutable CURVE_STETH_LIQUIDITY_WETH_TOKEN;

    constructor(
        address _pool,
        address _stethToken,
        address _wethToken
    ) public {
        CURVE_STETH_LIQUIDITY_POOL = _pool;
        CURVE_STETH_LIQUIDITY_WETH_TOKEN = _wethToken;

        // Pre-approve pool to use max of steth token
        ERC20(_stethToken).safeApprove(_pool, type(uint256).max);
    }

    /// @dev Helper to add liquidity to the pool
    function __curveStethLend(
        uint256 _outgoingWethAmount,
        uint256 _outgoingStethAmount,
        uint256 _minIncomingLPTokenAmount
    ) internal {
        if (_outgoingWethAmount > 0) {
            IWETH((CURVE_STETH_LIQUIDITY_WETH_TOKEN)).withdraw(_outgoingWethAmount);
        }

        ICurveStableSwapSteth(CURVE_STETH_LIQUIDITY_POOL).add_liquidity{
            value: _outgoingWethAmount
        }([_outgoingWethAmount, _outgoingStethAmount], _minIncomingLPTokenAmount);
    }

    /// @dev Helper to remove liquidity from the pool.
    // Assumes that if _redeemSingleAsset is true, then
    // "_minIncomingWethAmount > 0 XOR _minIncomingStethAmount > 0" has already been validated.
    function __curveStethRedeem(
        uint256 _outgoingLPTokenAmount,
        uint256 _minIncomingWethAmount,
        uint256 _minIncomingStethAmount,
        bool _redeemSingleAsset
    ) internal {
        if (_redeemSingleAsset) {
            if (_minIncomingWethAmount > 0) {
                ICurveStableSwapSteth(CURVE_STETH_LIQUIDITY_POOL).remove_liquidity_one_coin(
                    _outgoingLPTokenAmount,
                    CURVE_STETH_POOL_INDEX_ETH,
                    _minIncomingWethAmount
                );

                IWETH(payable(CURVE_STETH_LIQUIDITY_WETH_TOKEN)).deposit{
                    value: payable(address(this)).balance
                }();
            } else {
                ICurveStableSwapSteth(CURVE_STETH_LIQUIDITY_POOL).remove_liquidity_one_coin(
                    _outgoingLPTokenAmount,
                    CURVE_STETH_POOL_INDEX_STETH,
                    _minIncomingStethAmount
                );
            }
        } else {
            ICurveStableSwapSteth(CURVE_STETH_LIQUIDITY_POOL).remove_liquidity(
                _outgoingLPTokenAmount,
                [_minIncomingWethAmount, _minIncomingStethAmount]
            );

            IWETH(payable(CURVE_STETH_LIQUIDITY_WETH_TOKEN)).deposit{
                value: payable(address(this)).balance
            }();
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_STETH_LIQUIDITY_POOL` variable
    /// @return pool_ The `CURVE_STETH_LIQUIDITY_POOL` variable value
    function getCurveStethLiquidityPool() public view returns (address pool_) {
        return CURVE_STETH_LIQUIDITY_POOL;
    }

    /// @notice Gets the `CURVE_STETH_LIQUIDITY_WETH_TOKEN` variable
    /// @return wethToken_ The `CURVE_STETH_LIQUIDITY_WETH_TOKEN` variable value
    function getCurveStethLiquidityWethToken() public view returns (address wethToken_) {
        return CURVE_STETH_LIQUIDITY_WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveStableSwapSteth interface
/// @author Enzyme Council <[email protected]>
interface ICurveStableSwapSteth {
    function add_liquidity(uint256[2] calldata, uint256) external payable returns (uint256);

    function remove_liquidity(uint256, uint256[2] calldata) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../../interfaces/ICurveStableSwapSeth.sol";
import "../../../../../interfaces/IWETH.sol";

/// @title CurveSethLiquidityActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Curve seth pool's liquidity functions
/// @dev Inheriting contract must have a receive() function
abstract contract CurveSethLiquidityActionsMixin {
    using SafeERC20 for ERC20;

    int128 private constant CURVE_SETH_POOL_INDEX_ETH = 0;
    int128 private constant CURVE_SETH_POOL_INDEX_SETH = 1;

    address private immutable CURVE_SETH_LIQUIDITY_POOL;
    address private immutable CURVE_SETH_LIQUIDITY_WETH_TOKEN;

    constructor(
        address _pool,
        address _sethToken,
        address _wethToken
    ) public {
        CURVE_SETH_LIQUIDITY_POOL = _pool;
        CURVE_SETH_LIQUIDITY_WETH_TOKEN = _wethToken;

        // Pre-approve pool to use max of seth token
        ERC20(_sethToken).safeApprove(_pool, type(uint256).max);
    }

    /// @dev Helper to add liquidity to the pool
    function __curveSethLend(
        uint256 _outgoingWethAmount,
        uint256 _outgoingSethAmount,
        uint256 _minIncomingLPTokenAmount
    ) internal {
        if (_outgoingWethAmount > 0) {
            IWETH((CURVE_SETH_LIQUIDITY_WETH_TOKEN)).withdraw(_outgoingWethAmount);
        }

        ICurveStableSwapSeth(CURVE_SETH_LIQUIDITY_POOL).add_liquidity{value: _outgoingWethAmount}(
            [_outgoingWethAmount, _outgoingSethAmount],
            _minIncomingLPTokenAmount
        );
    }

    /// @dev Helper to remove liquidity from the pool.
    // Assumes that if _redeemSingleAsset is true, then
    // "_minIncomingWethAmount > 0 XOR _minIncomingSethAmount > 0" has already been validated.
    function __curveSethRedeem(
        uint256 _outgoingLPTokenAmount,
        uint256 _minIncomingWethAmount,
        uint256 _minIncomingSethAmount,
        bool _redeemSingleAsset
    ) internal {
        if (_redeemSingleAsset) {
            if (_minIncomingWethAmount > 0) {
                ICurveStableSwapSeth(CURVE_SETH_LIQUIDITY_POOL).remove_liquidity_one_coin(
                    _outgoingLPTokenAmount,
                    CURVE_SETH_POOL_INDEX_ETH,
                    _minIncomingWethAmount
                );

                IWETH(payable(CURVE_SETH_LIQUIDITY_WETH_TOKEN)).deposit{
                    value: payable(address(this)).balance
                }();
            } else {
                ICurveStableSwapSeth(CURVE_SETH_LIQUIDITY_POOL).remove_liquidity_one_coin(
                    _outgoingLPTokenAmount,
                    CURVE_SETH_POOL_INDEX_SETH,
                    _minIncomingSethAmount
                );
            }
        } else {
            ICurveStableSwapSeth(CURVE_SETH_LIQUIDITY_POOL).remove_liquidity(
                _outgoingLPTokenAmount,
                [_minIncomingWethAmount, _minIncomingSethAmount]
            );

            IWETH(payable(CURVE_SETH_LIQUIDITY_WETH_TOKEN)).deposit{
                value: payable(address(this)).balance
            }();
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_SETH_LIQUIDITY_POOL` variable
    /// @return pool_ The `CURVE_SETH_LIQUIDITY_POOL` variable value
    function getCurveSethLiquidityPool() public view returns (address pool_) {
        return CURVE_SETH_LIQUIDITY_POOL;
    }

    /// @notice Gets the `CURVE_SETH_LIQUIDITY_WETH_TOKEN` variable
    /// @return wethToken_ The `CURVE_SETH_LIQUIDITY_WETH_TOKEN` variable value
    function getCurveSethLiquidityWethToken() public view returns (address wethToken_) {
        return CURVE_SETH_LIQUIDITY_WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveStableSwapSeth interface
/// @author Enzyme Council <[email protected]>
interface ICurveStableSwapSeth {
    function add_liquidity(uint256[2] calldata, uint256) external payable returns (uint256);

    function remove_liquidity(uint256, uint256[2] calldata) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../utils/actions/CurveGaugeV2RewardsHandlerBase.sol";
import "../utils/actions/CurveSethLiquidityActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title CurveLiquiditySethAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for liquidity provision in Curve's seth pool (https://www.curve.fi/seth)
/// @dev Rewards tokens are not included as spend assets or incoming assets for claimRewards()
/// or claimRewardsAndReinvest(). Rationale:
/// - rewards tokens can be claimed to the vault outside of the IntegrationManager, so no need
/// to enforce policy management or emit an event
/// - rewards tokens can be outside of the asset universe, in which case they cannot be tracked
contract CurveLiquiditySethAdapter is
    AdapterBase,
    CurveGaugeV2RewardsHandlerBase,
    CurveSethLiquidityActionsMixin
{
    address private immutable LIQUIDITY_GAUGE_TOKEN;
    address private immutable LP_TOKEN;
    address private immutable SETH_TOKEN;

    constructor(
        address _integrationManager,
        address _liquidityGaugeToken,
        address _lpToken,
        address _minter,
        address _pool,
        address _crvToken,
        address _sethToken,
        address _wethToken
    )
        public
        AdapterBase(_integrationManager)
        CurveGaugeV2RewardsHandlerBase(_minter, _crvToken)
        CurveSethLiquidityActionsMixin(_pool, _sethToken, _wethToken)
    {
        LIQUIDITY_GAUGE_TOKEN = _liquidityGaugeToken;
        LP_TOKEN = _lpToken;
        SETH_TOKEN = _sethToken;

        // Max approve contracts to spend relevant tokens
        ERC20(_lpToken).safeApprove(_liquidityGaugeToken, type(uint256).max);
    }

    /// @dev Needed to receive ETH from redemption and to unwrap WETH
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Claims rewards from the Curve Minter as well as pool-specific rewards
    /// @param _vaultProxy The VaultProxy of the calling fund
    function claimRewards(
        address _vaultProxy,
        bytes calldata,
        bytes calldata
    ) external onlyIntegrationManager {
        __curveGaugeV2ClaimAllRewards(LIQUIDITY_GAUGE_TOKEN, _vaultProxy);
    }

    /// @notice Lends assets for seth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingSethAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        __curveSethLend(
            outgoingWethAmount,
            outgoingSethAmount,
            minIncomingLiquidityGaugeTokenAmount
        );
    }

    /// @notice Lends assets for seth LP tokens, then stakes the received LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lendAndStake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingSethAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        __curveSethLend(
            outgoingWethAmount,
            outgoingSethAmount,
            minIncomingLiquidityGaugeTokenAmount
        );
        __curveGaugeV2Stake(
            LIQUIDITY_GAUGE_TOKEN,
            LP_TOKEN,
            ERC20(LP_TOKEN).balanceOf(address(this))
        );
    }

    /// @notice Redeems seth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingSethAmount,
            bool redeemSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        __curveSethRedeem(
            outgoingLpTokenAmount,
            minIncomingWethAmount,
            minIncomingSethAmount,
            redeemSingleAsset
        );
    }

    /// @notice Stakes seth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function stake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        __curveGaugeV2Stake(LIQUIDITY_GAUGE_TOKEN, LP_TOKEN, __decodeStakeCallArgs(_actionData));
    }

    /// @notice Unstakes seth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        __curveGaugeV2Unstake(LIQUIDITY_GAUGE_TOKEN, __decodeUnstakeCallArgs(_actionData));
    }

    /// @notice Unstakes seth LP tokens, then redeems them
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstakeAndRedeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingSethAmount,
            bool redeemSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        __curveGaugeV2Unstake(LIQUIDITY_GAUGE_TOKEN, outgoingLiquidityGaugeTokenAmount);
        __curveSethRedeem(
            outgoingLiquidityGaugeTokenAmount,
            minIncomingWethAmount,
            minIncomingSethAmount,
            redeemSingleAsset
        );
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards();
        } else if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == LEND_AND_STAKE_SELECTOR) {
            return __parseAssetsForLendAndStake(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        } else if (_selector == STAKE_SELECTOR) {
            return __parseAssetsForStake(_actionData);
        } else if (_selector == UNSTAKE_SELECTOR) {
            return __parseAssetsForUnstake(_actionData);
        } else if (_selector == UNSTAKE_AND_REDEEM_SELECTOR) {
            return __parseAssetsForUnstakeAndRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls.
    /// No action required, all values empty.
    function __parseAssetsForClaimRewards()
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        return (
            IIntegrationManager.SpendAssetsHandleType.None,
            new address[](0),
            new uint256[](0),
            new address[](0),
            new uint256[](0)
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingSethAmount,
            uint256 minIncomingLpTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            outgoingWethAmount,
            outgoingSethAmount
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LP_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lendAndStake() calls
    function __parseAssetsForLendAndStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingSethAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            outgoingWethAmount,
            outgoingSethAmount
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingSethAmount,
            bool receiveSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LP_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            minIncomingWethAmount,
            minIncomingSethAmount,
            receiveSingleAsset
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during stake() calls
    function __parseAssetsForStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLpTokenAmount = __decodeStakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LP_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstake() calls
    function __parseAssetsForUnstake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLiquidityGaugeTokenAmount = __decodeUnstakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LP_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstakeAndRedeem() calls
    function __parseAssetsForUnstakeAndRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingSethAmount,
            bool receiveSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            minIncomingWethAmount,
            minIncomingSethAmount,
            receiveSingleAsset
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend assets for redeem() and unstakeAndRedeem() calls
    function __parseIncomingAssetsForRedemptionCalls(
        uint256 _minIncomingWethAmount,
        uint256 _minIncomingSethAmount,
        bool _receiveSingleAsset
    )
        private
        view
        returns (address[] memory incomingAssets_, uint256[] memory minIncomingAssetAmounts_)
    {
        if (_receiveSingleAsset) {
            incomingAssets_ = new address[](1);
            minIncomingAssetAmounts_ = new uint256[](1);

            if (_minIncomingWethAmount == 0) {
                require(
                    _minIncomingSethAmount > 0,
                    "__parseIncomingAssetsForRedemptionCalls: No min asset amount specified"
                );
                incomingAssets_[0] = SETH_TOKEN;
                minIncomingAssetAmounts_[0] = _minIncomingSethAmount;
            } else {
                require(
                    _minIncomingSethAmount == 0,
                    "__parseIncomingAssetsForRedemptionCalls: Too many min asset amounts specified"
                );
                incomingAssets_[0] = getCurveSethLiquidityWethToken();
                minIncomingAssetAmounts_[0] = _minIncomingWethAmount;
            }
        } else {
            incomingAssets_ = new address[](2);
            incomingAssets_[0] = getCurveSethLiquidityWethToken();
            incomingAssets_[1] = SETH_TOKEN;

            minIncomingAssetAmounts_ = new uint256[](2);
            minIncomingAssetAmounts_[0] = _minIncomingWethAmount;
            minIncomingAssetAmounts_[1] = _minIncomingSethAmount;
        }

        return (incomingAssets_, minIncomingAssetAmounts_);
    }

    /// @dev Helper function to parse spend assets for lend() and lendAndStake() calls
    function __parseSpendAssetsForLendingCalls(
        uint256 _outgoingWethAmount,
        uint256 _outgoingSethAmount
    ) private view returns (address[] memory spendAssets_, uint256[] memory spendAssetAmounts_) {
        if (_outgoingWethAmount > 0 && _outgoingSethAmount > 0) {
            spendAssets_ = new address[](2);
            spendAssets_[0] = getCurveSethLiquidityWethToken();
            spendAssets_[1] = SETH_TOKEN;

            spendAssetAmounts_ = new uint256[](2);
            spendAssetAmounts_[0] = _outgoingWethAmount;
            spendAssetAmounts_[1] = _outgoingSethAmount;
        } else if (_outgoingWethAmount > 0) {
            spendAssets_ = new address[](1);
            spendAssets_[0] = getCurveSethLiquidityWethToken();

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = _outgoingWethAmount;
        } else {
            spendAssets_ = new address[](1);
            spendAssets_[0] = SETH_TOKEN;

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = _outgoingSethAmount;
        }

        return (spendAssets_, spendAssetAmounts_);
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    /// @dev Helper to decode the encoded call arguments for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingWethAmount_,
            uint256 outgoingSethAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (uint256, uint256, uint256));
    }

    /// @dev Helper to decode the encoded call arguments for redeeming.
    /// If `receiveSingleAsset_` is `true`, then one (and only one) of
    /// `minIncomingWethAmount_` and `minIncomingSethAmount_` must be >0
    /// to indicate which asset is to be received.
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingAssetAmount_,
            uint256 minIncomingWethAmount_,
            uint256 minIncomingSethAmount_,
            bool receiveSingleAsset_
        )
    {
        return abi.decode(_actionData, (uint256, uint256, uint256, bool));
    }

    /// @dev Helper to decode the encoded call arguments for staking
    function __decodeStakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLpTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    /// @dev Helper to decode the encoded call arguments for unstaking
    function __decodeUnstakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLiquidityGaugeTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `LIQUIDITY_GAUGE_TOKEN` variable
    /// @return liquidityGaugeToken_ The `LIQUIDITY_GAUGE_TOKEN` variable value
    function getLiquidityGaugeToken() external view returns (address liquidityGaugeToken_) {
        return LIQUIDITY_GAUGE_TOKEN;
    }

    /// @notice Gets the `LP_TOKEN` variable
    /// @return lpToken_ The `LP_TOKEN` variable value
    function getLpToken() external view returns (address lpToken_) {
        return LP_TOKEN;
    }

    /// @notice Gets the `SETH_TOKEN` variable
    /// @return sethToken_ The `SETH_TOKEN` variable value
    function getSethToken() external view returns (address sethToken_) {
        return SETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/ICurveMinter.sol";
import "../../../../../utils/AddressArrayLib.sol";
import "./CurveGaugeV2ActionsMixin.sol";

/// @title CurveGaugeV2RewardsHandlerBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base contract for handling claiming and reinvesting rewards for a Curve pool
/// that uses the LiquidityGaugeV2 contract
abstract contract CurveGaugeV2RewardsHandlerBase is CurveGaugeV2ActionsMixin {
    using AddressArrayLib for address[];

    address private immutable CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN;
    address private immutable CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER;

    constructor(address _minter, address _crvToken) public {
        CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN = _crvToken;
        CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER = _minter;
    }

    /// @dev Helper to claim all rewards (CRV and pool-specific).
    /// Requires contract to be approved to use mint_for().
    function __curveGaugeV2ClaimAllRewards(address _gauge, address _target) internal {
        // Claim owed $CRV
        ICurveMinter(CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER).mint_for(_gauge, _target);

        // Claim owed pool-specific rewards
        __curveGaugeV2ClaimRewards(_gauge, _target);
    }

    /// @dev Helper to get all rewards tokens for staking LP tokens
    function __curveGaugeV2GetRewardsTokensWithCrv(address _gauge)
        internal
        view
        returns (address[] memory rewardsTokens_)
    {
        return
            __curveGaugeV2GetRewardsTokens(_gauge).addUniqueItem(
                CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN
            );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN` variable
    /// @return crvToken_ The `CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN` variable value
    function getCurveGaugeV2RewardsHandlerCrvToken() public view returns (address crvToken_) {
        return CURVE_GAUGE_V2_REWARDS_HANDLER_CRV_TOKEN;
    }

    /// @notice Gets the `CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER` variable
    /// @return minter_ The `CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER` variable value
    function getCurveGaugeV2RewardsHandlerMinter() public view returns (address minter_) {
        return CURVE_GAUGE_V2_REWARDS_HANDLER_MINTER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveMinter interface
/// @author Enzyme Council <[email protected]>
interface ICurveMinter {
    function mint_for(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/ICurveLiquidityGaugeV2.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title CurveGaugeV2ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with any Curve LiquidityGaugeV2 contract
abstract contract CurveGaugeV2ActionsMixin is AssetHelpers {
    uint256 private constant CURVE_GAUGE_V2_MAX_REWARDS = 8;

    /// @dev Helper to claim pool-specific rewards
    function __curveGaugeV2ClaimRewards(address _gauge, address _target) internal {
        ICurveLiquidityGaugeV2(_gauge).claim_rewards(_target);
    }

    /// @dev Helper to get list of pool-specific rewards tokens
    function __curveGaugeV2GetRewardsTokens(address _gauge)
        internal
        view
        returns (address[] memory rewardsTokens_)
    {
        address[] memory lpRewardsTokensWithEmpties = new address[](CURVE_GAUGE_V2_MAX_REWARDS);
        uint256 rewardsTokensCount;
        for (uint256 i; i < CURVE_GAUGE_V2_MAX_REWARDS; i++) {
            address rewardToken = ICurveLiquidityGaugeV2(_gauge).reward_tokens(i);
            if (rewardToken != address(0)) {
                lpRewardsTokensWithEmpties[i] = rewardToken;
                rewardsTokensCount++;
            } else {
                break;
            }
        }

        rewardsTokens_ = new address[](rewardsTokensCount);
        for (uint256 i; i < rewardsTokensCount; i++) {
            rewardsTokens_[i] = lpRewardsTokensWithEmpties[i];
        }

        return rewardsTokens_;
    }

    /// @dev Helper to stake LP tokens
    function __curveGaugeV2Stake(
        address _gauge,
        address _lpToken,
        uint256 _amount
    ) internal {
        __approveAssetMaxAsNeeded(_lpToken, _gauge, _amount);
        ICurveLiquidityGaugeV2(_gauge).deposit(_amount, address(this));
    }

    /// @dev Helper to unstake LP tokens
    function __curveGaugeV2Unstake(address _gauge, uint256 _amount) internal {
        ICurveLiquidityGaugeV2(_gauge).withdraw(_amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveLiquidityGaugeV2 interface
/// @author Enzyme Council <[email protected]>
interface ICurveLiquidityGaugeV2 {
    function claim_rewards(address) external;

    function deposit(uint256, address) external;

    function reward_tokens(uint256) external view returns (address);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../utils/actions/CurveGaugeV2RewardsHandlerBase.sol";
import "../utils/actions/CurveStethLiquidityActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title CurveLiquidityStethAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for liquidity provision in Curve's steth pool (https://www.curve.fi/steth)
/// @dev Rewards tokens are not included as spend assets or incoming assets for claimRewards()
/// or claimRewardsAndReinvest(). Rationale:
/// - rewards tokens can be claimed to the vault outside of the IntegrationManager, so no need
/// to enforce policy management or emit an event
/// - rewards tokens can be outside of the asset universe, in which case they cannot be tracked
contract CurveLiquidityStethAdapter is
    AdapterBase,
    CurveGaugeV2RewardsHandlerBase,
    CurveStethLiquidityActionsMixin
{
    address private immutable LIQUIDITY_GAUGE_TOKEN;
    address private immutable LP_TOKEN;
    address private immutable STETH_TOKEN;

    constructor(
        address _integrationManager,
        address _liquidityGaugeToken,
        address _lpToken,
        address _minter,
        address _pool,
        address _crvToken,
        address _stethToken,
        address _wethToken
    )
        public
        AdapterBase(_integrationManager)
        CurveGaugeV2RewardsHandlerBase(_minter, _crvToken)
        CurveStethLiquidityActionsMixin(_pool, _stethToken, _wethToken)
    {
        LIQUIDITY_GAUGE_TOKEN = _liquidityGaugeToken;
        LP_TOKEN = _lpToken;
        STETH_TOKEN = _stethToken;

        // Max approve contracts to spend relevant tokens
        ERC20(_lpToken).safeApprove(_liquidityGaugeToken, type(uint256).max);
    }

    /// @dev Needed to receive ETH from redemption and to unwrap WETH
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Claims rewards from the Curve Minter as well as pool-specific rewards
    /// @param _vaultProxy The VaultProxy of the calling fund
    function claimRewards(
        address _vaultProxy,
        bytes calldata,
        bytes calldata
    ) external onlyIntegrationManager {
        __curveGaugeV2ClaimAllRewards(LIQUIDITY_GAUGE_TOKEN, _vaultProxy);
    }

    /// @notice Lends assets for steth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingStethAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        __curveStethLend(
            outgoingWethAmount,
            outgoingStethAmount,
            minIncomingLiquidityGaugeTokenAmount
        );
    }

    /// @notice Lends assets for steth LP tokens, then stakes the received LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lendAndStake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingStethAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        __curveStethLend(
            outgoingWethAmount,
            outgoingStethAmount,
            minIncomingLiquidityGaugeTokenAmount
        );
        __curveGaugeV2Stake(
            LIQUIDITY_GAUGE_TOKEN,
            LP_TOKEN,
            ERC20(LP_TOKEN).balanceOf(address(this))
        );
    }

    /// @notice Redeems steth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingStethAmount,
            bool redeemSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        __curveStethRedeem(
            outgoingLpTokenAmount,
            minIncomingWethAmount,
            minIncomingStethAmount,
            redeemSingleAsset
        );
    }

    /// @notice Stakes steth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function stake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        __curveGaugeV2Stake(LIQUIDITY_GAUGE_TOKEN, LP_TOKEN, __decodeStakeCallArgs(_actionData));
    }

    /// @notice Unstakes steth LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        __curveGaugeV2Unstake(LIQUIDITY_GAUGE_TOKEN, __decodeUnstakeCallArgs(_actionData));
    }

    /// @notice Unstakes steth LP tokens, then redeems them
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstakeAndRedeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingStethAmount,
            bool redeemSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        __curveGaugeV2Unstake(LIQUIDITY_GAUGE_TOKEN, outgoingLiquidityGaugeTokenAmount);
        __curveStethRedeem(
            outgoingLiquidityGaugeTokenAmount,
            minIncomingWethAmount,
            minIncomingStethAmount,
            redeemSingleAsset
        );
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards();
        } else if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == LEND_AND_STAKE_SELECTOR) {
            return __parseAssetsForLendAndStake(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        } else if (_selector == STAKE_SELECTOR) {
            return __parseAssetsForStake(_actionData);
        } else if (_selector == UNSTAKE_SELECTOR) {
            return __parseAssetsForUnstake(_actionData);
        } else if (_selector == UNSTAKE_AND_REDEEM_SELECTOR) {
            return __parseAssetsForUnstakeAndRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls.
    /// No action required, all values empty.
    function __parseAssetsForClaimRewards()
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        return (
            IIntegrationManager.SpendAssetsHandleType.None,
            new address[](0),
            new uint256[](0),
            new address[](0),
            new uint256[](0)
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingStethAmount,
            uint256 minIncomingLpTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            outgoingWethAmount,
            outgoingStethAmount
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LP_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lendAndStake() calls
    function __parseAssetsForLendAndStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingWethAmount,
            uint256 outgoingStethAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            outgoingWethAmount,
            outgoingStethAmount
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingStethAmount,
            bool receiveSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LP_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            minIncomingWethAmount,
            minIncomingStethAmount,
            receiveSingleAsset
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during stake() calls
    function __parseAssetsForStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLpTokenAmount = __decodeStakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LP_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstake() calls
    function __parseAssetsForUnstake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLiquidityGaugeTokenAmount = __decodeUnstakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LP_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstakeAndRedeem() calls
    function __parseAssetsForUnstakeAndRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256 minIncomingWethAmount,
            uint256 minIncomingStethAmount,
            bool receiveSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            minIncomingWethAmount,
            minIncomingStethAmount,
            receiveSingleAsset
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend assets for redeem() and unstakeAndRedeem() calls
    function __parseIncomingAssetsForRedemptionCalls(
        uint256 _minIncomingWethAmount,
        uint256 _minIncomingStethAmount,
        bool _receiveSingleAsset
    )
        private
        view
        returns (address[] memory incomingAssets_, uint256[] memory minIncomingAssetAmounts_)
    {
        if (_receiveSingleAsset) {
            incomingAssets_ = new address[](1);
            minIncomingAssetAmounts_ = new uint256[](1);

            if (_minIncomingWethAmount == 0) {
                require(
                    _minIncomingStethAmount > 0,
                    "__parseIncomingAssetsForRedemptionCalls: No min asset amount specified"
                );
                incomingAssets_[0] = STETH_TOKEN;
                minIncomingAssetAmounts_[0] = _minIncomingStethAmount;
            } else {
                require(
                    _minIncomingStethAmount == 0,
                    "__parseIncomingAssetsForRedemptionCalls: Too many min asset amounts specified"
                );
                incomingAssets_[0] = getCurveStethLiquidityWethToken();
                minIncomingAssetAmounts_[0] = _minIncomingWethAmount;
            }
        } else {
            incomingAssets_ = new address[](2);
            incomingAssets_[0] = getCurveStethLiquidityWethToken();
            incomingAssets_[1] = STETH_TOKEN;

            minIncomingAssetAmounts_ = new uint256[](2);
            minIncomingAssetAmounts_[0] = _minIncomingWethAmount;
            minIncomingAssetAmounts_[1] = _minIncomingStethAmount;
        }

        return (incomingAssets_, minIncomingAssetAmounts_);
    }

    /// @dev Helper function to parse spend assets for lend() and lendAndStake() calls
    function __parseSpendAssetsForLendingCalls(
        uint256 _outgoingWethAmount,
        uint256 _outgoingStethAmount
    ) private view returns (address[] memory spendAssets_, uint256[] memory spendAssetAmounts_) {
        if (_outgoingWethAmount > 0 && _outgoingStethAmount > 0) {
            spendAssets_ = new address[](2);
            spendAssets_[0] = getCurveStethLiquidityWethToken();
            spendAssets_[1] = STETH_TOKEN;

            spendAssetAmounts_ = new uint256[](2);
            spendAssetAmounts_[0] = _outgoingWethAmount;
            spendAssetAmounts_[1] = _outgoingStethAmount;
        } else if (_outgoingWethAmount > 0) {
            spendAssets_ = new address[](1);
            spendAssets_[0] = getCurveStethLiquidityWethToken();

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = _outgoingWethAmount;
        } else {
            spendAssets_ = new address[](1);
            spendAssets_[0] = STETH_TOKEN;

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = _outgoingStethAmount;
        }

        return (spendAssets_, spendAssetAmounts_);
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    /// @dev Helper to decode the encoded call arguments for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingWethAmount_,
            uint256 outgoingStethAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (uint256, uint256, uint256));
    }

    /// @dev Helper to decode the encoded call arguments for redeeming.
    /// If `receiveSingleAsset_` is `true`, then one (and only one) of
    /// `minIncomingWethAmount_` and `minIncomingStethAmount_` must be >0
    /// to indicate which asset is to be received.
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingAssetAmount_,
            uint256 minIncomingWethAmount_,
            uint256 minIncomingStethAmount_,
            bool receiveSingleAsset_
        )
    {
        return abi.decode(_actionData, (uint256, uint256, uint256, bool));
    }

    /// @dev Helper to decode the encoded call arguments for staking
    function __decodeStakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLpTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    /// @dev Helper to decode the encoded call arguments for unstaking
    function __decodeUnstakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLiquidityGaugeTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `LIQUIDITY_GAUGE_TOKEN` variable
    /// @return liquidityGaugeToken_ The `LIQUIDITY_GAUGE_TOKEN` variable value
    function getLiquidityGaugeToken() external view returns (address liquidityGaugeToken_) {
        return LIQUIDITY_GAUGE_TOKEN;
    }

    /// @notice Gets the `LP_TOKEN` variable
    /// @return lpToken_ The `LP_TOKEN` variable value
    function getLpToken() external view returns (address lpToken_) {
        return LP_TOKEN;
    }

    /// @notice Gets the `STETH_TOKEN` variable
    /// @return stethToken_ The `STETH_TOKEN` variable value
    function getStethToken() external view returns (address stethToken_) {
        return STETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../utils/actions/CurveGaugeV2RewardsHandlerBase.sol";
import "../utils/actions/CurveEursLiquidityActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title CurveLiquidityEursAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for liquidity provision in Curve's eurs pool (https://www.curve.fi/eurs)
/// @dev Rewards tokens are not included as spend assets or incoming assets for claimRewards()
/// Rationale:
/// - rewards tokens can be claimed to the vault outside of the IntegrationManager, so no need
/// to enforce policy management or emit an event
/// - rewards tokens can be outside of the asset universe, in which case they cannot be tracked
contract CurveLiquidityEursAdapter is
    AdapterBase,
    CurveGaugeV2RewardsHandlerBase,
    CurveEursLiquidityActionsMixin
{
    address private immutable EURS_TOKEN;
    address private immutable LIQUIDITY_GAUGE_TOKEN;
    address private immutable LP_TOKEN;
    address private immutable SEUR_TOKEN;

    constructor(
        address _integrationManager,
        address _liquidityGaugeToken,
        address _lpToken,
        address _minter,
        address _pool,
        address _crvToken,
        address _eursToken,
        address _seurToken
    )
        public
        AdapterBase(_integrationManager)
        CurveGaugeV2RewardsHandlerBase(_minter, _crvToken)
        CurveEursLiquidityActionsMixin(_pool, _eursToken, _seurToken)
    {
        EURS_TOKEN = _eursToken;
        LIQUIDITY_GAUGE_TOKEN = _liquidityGaugeToken;
        LP_TOKEN = _lpToken;
        SEUR_TOKEN = _seurToken;

        // Max approve contracts to spend relevant tokens
        ERC20(_lpToken).safeApprove(_liquidityGaugeToken, type(uint256).max);
    }

    // EXTERNAL FUNCTIONS

    /// @notice Claims rewards from the Curve Minter as well as pool-specific rewards
    /// @param _vaultProxy The VaultProxy of the calling fund
    function claimRewards(
        address _vaultProxy,
        bytes calldata,
        bytes calldata
    ) external onlyIntegrationManager {
        __curveGaugeV2ClaimAllRewards(getLiquidityGaugeToken(), _vaultProxy);
    }

    /// @notice Lends assets for eurs LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingEursAmount,
            uint256 outgoingSeurAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        __curveEursLend(
            outgoingEursAmount,
            outgoingSeurAmount,
            minIncomingLiquidityGaugeTokenAmount
        );
    }

    /// @notice Lends assets for eurs LP tokens, then stakes the received LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lendAndStake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingEursAmount,
            uint256 outgoingSeurAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        __curveEursLend(
            outgoingEursAmount,
            outgoingSeurAmount,
            minIncomingLiquidityGaugeTokenAmount
        );
        __curveGaugeV2Stake(
            getLiquidityGaugeToken(),
            getLpToken(),
            ERC20(getLpToken()).balanceOf(address(this))
        );
    }

    /// @notice Redeems eurs LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256 minIncomingEursAmount,
            uint256 minIncomingSeurAmount,
            bool redeemSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        __curveEursRedeem(
            outgoingLpTokenAmount,
            minIncomingEursAmount,
            minIncomingSeurAmount,
            redeemSingleAsset
        );
    }

    /// @notice Stakes eurs LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function stake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        __curveGaugeV2Stake(
            getLiquidityGaugeToken(),
            getLpToken(),
            __decodeStakeCallArgs(_actionData)
        );
    }

    /// @notice Unstakes eurs LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        __curveGaugeV2Unstake(getLiquidityGaugeToken(), __decodeUnstakeCallArgs(_actionData));
    }

    /// @notice Unstakes eurs LP tokens, then redeems them
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstakeAndRedeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256 minIncomingEursAmount,
            uint256 minIncomingSeurAmount,
            bool redeemSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        __curveGaugeV2Unstake(getLiquidityGaugeToken(), outgoingLiquidityGaugeTokenAmount);
        __curveEursRedeem(
            outgoingLiquidityGaugeTokenAmount,
            minIncomingEursAmount,
            minIncomingSeurAmount,
            redeemSingleAsset
        );
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards();
        } else if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == LEND_AND_STAKE_SELECTOR) {
            return __parseAssetsForLendAndStake(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        } else if (_selector == STAKE_SELECTOR) {
            return __parseAssetsForStake(_actionData);
        } else if (_selector == UNSTAKE_SELECTOR) {
            return __parseAssetsForUnstake(_actionData);
        } else if (_selector == UNSTAKE_AND_REDEEM_SELECTOR) {
            return __parseAssetsForUnstakeAndRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls.
    /// No action required, all values empty.
    function __parseAssetsForClaimRewards()
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        return (
            IIntegrationManager.SpendAssetsHandleType.None,
            new address[](0),
            new uint256[](0),
            new address[](0),
            new uint256[](0)
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingEursAmount,
            uint256 outgoingSeurAmount,
            uint256 minIncomingLpTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            outgoingEursAmount,
            outgoingSeurAmount
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = getLpToken();

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lendAndStake() calls
    function __parseAssetsForLendAndStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingEursAmount,
            uint256 outgoingSeurAmount,
            uint256 minIncomingLiquidityGaugeTokenAmount
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            outgoingEursAmount,
            outgoingSeurAmount
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = getLiquidityGaugeToken();

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256 minIncomingEursAmount,
            uint256 minIncomingSeurAmount,
            bool receiveSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = getLpToken();

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            minIncomingEursAmount,
            minIncomingSeurAmount,
            receiveSingleAsset
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during stake() calls
    function __parseAssetsForStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLpTokenAmount = __decodeStakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = getLpToken();

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = getLiquidityGaugeToken();

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstake() calls
    function __parseAssetsForUnstake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLiquidityGaugeTokenAmount = __decodeUnstakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = getLiquidityGaugeToken();

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = getLpToken();

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstakeAndRedeem() calls
    function __parseAssetsForUnstakeAndRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256 minIncomingEursAmount,
            uint256 minIncomingSeurAmount,
            bool receiveSingleAsset
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = getLiquidityGaugeToken();

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            minIncomingEursAmount,
            minIncomingSeurAmount,
            receiveSingleAsset
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend assets for redeem() and unstakeAndRedeem() calls
    function __parseIncomingAssetsForRedemptionCalls(
        uint256 _minIncomingEursAmount,
        uint256 _minIncomingSeurAmount,
        bool _receiveSingleAsset
    )
        private
        view
        returns (address[] memory incomingAssets_, uint256[] memory minIncomingAssetAmounts_)
    {
        if (_receiveSingleAsset) {
            incomingAssets_ = new address[](1);
            minIncomingAssetAmounts_ = new uint256[](1);

            if (_minIncomingEursAmount == 0) {
                require(
                    _minIncomingSeurAmount > 0,
                    "__parseIncomingAssetsForRedemptionCalls: No min asset amount specified"
                );
                incomingAssets_[0] = getSeurToken();
                minIncomingAssetAmounts_[0] = _minIncomingSeurAmount;
            } else {
                require(
                    _minIncomingSeurAmount == 0,
                    "__parseIncomingAssetsForRedemptionCalls: Too many min asset amounts specified"
                );
                incomingAssets_[0] = getEursToken();
                minIncomingAssetAmounts_[0] = _minIncomingEursAmount;
            }
        } else {
            incomingAssets_ = new address[](2);
            incomingAssets_[0] = getEursToken();
            incomingAssets_[1] = getSeurToken();

            minIncomingAssetAmounts_ = new uint256[](2);
            minIncomingAssetAmounts_[0] = _minIncomingEursAmount;
            minIncomingAssetAmounts_[1] = _minIncomingSeurAmount;
        }

        return (incomingAssets_, minIncomingAssetAmounts_);
    }

    /// @dev Helper function to parse spend assets for lend() and lendAndStake() calls
    function __parseSpendAssetsForLendingCalls(
        uint256 _outgoingEursAmount,
        uint256 _outgoingSeurAmount
    ) private view returns (address[] memory spendAssets_, uint256[] memory spendAssetAmounts_) {
        if (_outgoingEursAmount > 0 && _outgoingSeurAmount > 0) {
            spendAssets_ = new address[](2);
            spendAssets_[0] = getEursToken();
            spendAssets_[1] = getSeurToken();

            spendAssetAmounts_ = new uint256[](2);
            spendAssetAmounts_[0] = _outgoingEursAmount;
            spendAssetAmounts_[1] = _outgoingSeurAmount;
        } else if (_outgoingEursAmount > 0) {
            spendAssets_ = new address[](1);
            spendAssets_[0] = getEursToken();

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = _outgoingEursAmount;
        } else {
            spendAssets_ = new address[](1);
            spendAssets_[0] = getSeurToken();

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = _outgoingSeurAmount;
        }

        return (spendAssets_, spendAssetAmounts_);
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    /// @dev Helper to decode the encoded call arguments for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingEursAmount_,
            uint256 outgoingSeurAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (uint256, uint256, uint256));
    }

    /// @dev Helper to decode the encoded call arguments for redeeming.
    /// If `receiveSingleAsset_` is `true`, then one (and only one) of
    /// `minIncomingEursAmount_` and `minIncomingSeurAmount_` must be >0
    /// to indicate which asset is to be received.
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingAssetAmount_,
            uint256 minIncomingEursAmount_,
            uint256 minIncomingSeurAmount_,
            bool receiveSingleAsset_
        )
    {
        return abi.decode(_actionData, (uint256, uint256, uint256, bool));
    }

    /// @dev Helper to decode the encoded call arguments for staking
    function __decodeStakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLpTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    /// @dev Helper to decode the encoded call arguments for unstaking
    function __decodeUnstakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLiquidityGaugeTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EURS_TOKEN` variable
    /// @return eursToken_ The `EURS_TOKEN` variable value
    function getEursToken() public view returns (address eursToken_) {
        return EURS_TOKEN;
    }

    /// @notice Gets the `LIQUIDITY_GAUGE_TOKEN` variable
    /// @return liquidityGaugeToken_ The `LIQUIDITY_GAUGE_TOKEN` variable value
    function getLiquidityGaugeToken() public view returns (address liquidityGaugeToken_) {
        return LIQUIDITY_GAUGE_TOKEN;
    }

    /// @notice Gets the `LP_TOKEN` variable
    /// @return lpToken_ The `LP_TOKEN` variable value
    function getLpToken() public view returns (address lpToken_) {
        return LP_TOKEN;
    }

    /// @notice Gets the `SEUR_TOKEN` variable
    /// @return seurToken_ The `SEUR_TOKEN` variable value
    function getSeurToken() public view returns (address seurToken_) {
        return SEUR_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../../interfaces/ICurveStableSwapEurs.sol";

/// @title CurveEursLiquidityActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Curve eurs pool's liquidity functions
/// @dev Inheriting contract must have a receive() function
abstract contract CurveEursLiquidityActionsMixin {
    using SafeERC20 for ERC20;

    int128 private constant CURVE_EURS_POOL_INDEX_EURS = 0;
    int128 private constant CURVE_EURS_POOL_INDEX_SEUR = 1;

    address private immutable CURVE_EURS_LIQUIDITY_POOL;

    constructor(
        address _pool,
        address _eursToken,
        address _seurToken
    ) public {
        CURVE_EURS_LIQUIDITY_POOL = _pool;

        // Pre-approve pool to use max of both tokens
        ERC20(_eursToken).safeApprove(_pool, type(uint256).max);
        ERC20(_seurToken).safeApprove(_pool, type(uint256).max);
    }

    /// @dev Helper to add liquidity to the pool
    function __curveEursLend(
        uint256 _outgoingEursAmount,
        uint256 _outgoingSeurAmount,
        uint256 _minIncomingLPTokenAmount
    ) internal {
        ICurveStableSwapEurs(CURVE_EURS_LIQUIDITY_POOL).add_liquidity(
            [_outgoingEursAmount, _outgoingSeurAmount],
            _minIncomingLPTokenAmount
        );
    }

    /// @dev Helper to remove liquidity from the pool.
    // Assumes that if _redeemSingleAsset is true, then
    // "_minIncomingEursAmount > 0 XOR _minIncomingSeurAmount > 0" has already been validated.
    function __curveEursRedeem(
        uint256 _outgoingLPTokenAmount,
        uint256 _minIncomingEursAmount,
        uint256 _minIncomingSeurAmount,
        bool _redeemSingleAsset
    ) internal {
        if (_redeemSingleAsset) {
            if (_minIncomingEursAmount > 0) {
                ICurveStableSwapEurs(CURVE_EURS_LIQUIDITY_POOL).remove_liquidity_one_coin(
                    _outgoingLPTokenAmount,
                    CURVE_EURS_POOL_INDEX_EURS,
                    _minIncomingEursAmount
                );
            } else {
                ICurveStableSwapEurs(CURVE_EURS_LIQUIDITY_POOL).remove_liquidity_one_coin(
                    _outgoingLPTokenAmount,
                    CURVE_EURS_POOL_INDEX_SEUR,
                    _minIncomingSeurAmount
                );
            }
        } else {
            ICurveStableSwapEurs(CURVE_EURS_LIQUIDITY_POOL).remove_liquidity(
                _outgoingLPTokenAmount,
                [_minIncomingEursAmount, _minIncomingSeurAmount]
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_EURS_LIQUIDITY_POOL` variable
    /// @return pool_ The `CURVE_EURS_LIQUIDITY_POOL` variable value
    function getCurveEursLiquidityPool() public view returns (address pool_) {
        return CURVE_EURS_LIQUIDITY_POOL;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveStableSwapEurs interface
/// @author Enzyme Council <[email protected]>
interface ICurveStableSwapEurs {
    function add_liquidity(uint256[2] calldata, uint256) external returns (uint256);

    function remove_liquidity(uint256, uint256[2] calldata) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../utils/actions/CurveAaveLiquidityActionsMixin.sol";
import "../utils/actions/CurveGaugeV2RewardsHandlerBase.sol";
import "../utils/AdapterBase.sol";

/// @title CurveLiquidityAaveAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for liquidity provision in Curve's aave pool (https://www.curve.fi/aave)
/// @dev Rewards tokens are not included as spend assets or incoming assets for claimRewards()
/// or claimRewardsAndReinvest(). Rationale:
/// - rewards tokens can be claimed to the vault outside of the IntegrationManager, so no need
/// to enforce policy management or emit an event
/// - rewards tokens can be outside of the asset universe, in which case they cannot be tracked
contract CurveLiquidityAaveAdapter is
    AdapterBase,
    CurveGaugeV2RewardsHandlerBase,
    CurveAaveLiquidityActionsMixin
{
    address private immutable AAVE_DAI_TOKEN;
    address private immutable AAVE_USDC_TOKEN;
    address private immutable AAVE_USDT_TOKEN;

    address private immutable DAI_TOKEN;
    address private immutable USDC_TOKEN;
    address private immutable USDT_TOKEN;

    address private immutable LIQUIDITY_GAUGE_TOKEN;
    address private immutable LP_TOKEN;

    constructor(
        address _integrationManager,
        address _liquidityGaugeToken,
        address _lpToken,
        address _minter,
        address _pool,
        address _crvToken,
        address[3] memory _aaveTokens, // [aDAI, aUSDC, aUSDT]
        address[3] memory _underlyingTokens // [DAI, USDC, USDT]
    )
        public
        AdapterBase(_integrationManager)
        CurveAaveLiquidityActionsMixin(_pool, _aaveTokens, _underlyingTokens)
        CurveGaugeV2RewardsHandlerBase(_minter, _crvToken)
    {
        AAVE_DAI_TOKEN = _aaveTokens[0];
        AAVE_USDC_TOKEN = _aaveTokens[1];
        AAVE_USDT_TOKEN = _aaveTokens[2];

        DAI_TOKEN = _underlyingTokens[0];
        USDC_TOKEN = _underlyingTokens[1];
        USDT_TOKEN = _underlyingTokens[2];

        LIQUIDITY_GAUGE_TOKEN = _liquidityGaugeToken;
        LP_TOKEN = _lpToken;

        // Max approve liquidity gauge to spend LP token
        ERC20(_lpToken).safeApprove(_liquidityGaugeToken, type(uint256).max);
    }

    // EXTERNAL FUNCTIONS

    /// @notice Claims rewards from the Curve liquidity gauge as well as pool-specific rewards
    /// @param _vaultProxy The VaultProxy of the calling fund
    function claimRewards(
        address _vaultProxy,
        bytes calldata,
        bytes calldata
    ) external onlyIntegrationManager {
        __curveGaugeV2ClaimAllRewards(LIQUIDITY_GAUGE_TOKEN, _vaultProxy);
    }

    /// @notice Lends assets for LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256[3] memory orderedOutgoingAmounts,
            uint256 minIncomingLPTokenAmount,
            bool useUnderlyings
        ) = __decodeLendCallArgs(_actionData);

        __curveAaveLend(orderedOutgoingAmounts, minIncomingLPTokenAmount, useUnderlyings);
    }

    /// @notice Lends assets for LP tokens, then stakes the received LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lendAndStake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256[3] memory orderedOutgoingAmounts,
            uint256 minIncomingLiquidityGaugeTokenAmount,
            bool useUnderlyings
        ) = __decodeLendCallArgs(_actionData);

        __curveAaveLend(
            orderedOutgoingAmounts,
            minIncomingLiquidityGaugeTokenAmount,
            useUnderlyings
        );
        __curveGaugeV2Stake(
            LIQUIDITY_GAUGE_TOKEN,
            LP_TOKEN,
            ERC20(LP_TOKEN).balanceOf(address(this))
        );
    }

    /// @notice Redeems LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLPTokenAmount,
            uint256[3] memory orderedMinIncomingAssetAmounts,
            bool redeemSingleAsset,
            bool useUnderlyings
        ) = __decodeRedeemCallArgs(_actionData);

        __curveAaveRedeem(
            outgoingLPTokenAmount,
            orderedMinIncomingAssetAmounts,
            redeemSingleAsset,
            useUnderlyings
        );
    }

    /// @notice Stakes LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function stake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        uint256 outgoingLPTokenAmount = __decodeStakeCallArgs(_actionData);

        __curveGaugeV2Stake(LIQUIDITY_GAUGE_TOKEN, LP_TOKEN, outgoingLPTokenAmount);
    }

    /// @notice Unstakes LP tokens
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstake(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        uint256 outgoingLiquidityGaugeTokenAmount = __decodeUnstakeCallArgs(_actionData);

        __curveGaugeV2Unstake(LIQUIDITY_GAUGE_TOKEN, outgoingLiquidityGaugeTokenAmount);
    }

    /// @notice Unstakes LP tokens, then redeems them
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function unstakeAndRedeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256[3] memory orderedMinIncomingAssetAmounts,
            bool redeemSingleAsset,
            bool useUnderlyings
        ) = __decodeRedeemCallArgs(_actionData);

        __curveGaugeV2Unstake(LIQUIDITY_GAUGE_TOKEN, outgoingLiquidityGaugeTokenAmount);
        __curveAaveRedeem(
            outgoingLiquidityGaugeTokenAmount,
            orderedMinIncomingAssetAmounts,
            redeemSingleAsset,
            useUnderlyings
        );
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == CLAIM_REWARDS_SELECTOR) {
            return __parseAssetsForClaimRewards();
        } else if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == LEND_AND_STAKE_SELECTOR) {
            return __parseAssetsForLendAndStake(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        } else if (_selector == STAKE_SELECTOR) {
            return __parseAssetsForStake(_actionData);
        } else if (_selector == UNSTAKE_SELECTOR) {
            return __parseAssetsForUnstake(_actionData);
        } else if (_selector == UNSTAKE_AND_REDEEM_SELECTOR) {
            return __parseAssetsForUnstakeAndRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during claimRewards() calls.
    /// No action required, all values empty.
    function __parseAssetsForClaimRewards()
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        return (
            IIntegrationManager.SpendAssetsHandleType.None,
            new address[](0),
            new uint256[](0),
            new address[](0),
            new uint256[](0)
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256[3] memory orderedOutgoingAssetAmounts,
            uint256 minIncomingLpTokenAmount,
            bool useUnderlyings
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            orderedOutgoingAssetAmounts,
            useUnderlyings
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LP_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lendAndStake() calls
    function __parseAssetsForLendAndStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256[3] memory orderedOutgoingAssetAmounts,
            uint256 minIncomingLiquidityGaugeTokenAmount,
            bool useUnderlyings
        ) = __decodeLendCallArgs(_actionData);

        (spendAssets_, spendAssetAmounts_) = __parseSpendAssetsForLendingCalls(
            orderedOutgoingAssetAmounts,
            useUnderlyings
        );

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLpTokenAmount,
            uint256[3] memory orderedMinIncomingAssetAmounts,
            bool receiveSingleAsset,
            bool useUnderlyings
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LP_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            orderedMinIncomingAssetAmounts,
            receiveSingleAsset,
            useUnderlyings
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during stake() calls
    function __parseAssetsForStake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLpTokenAmount = __decodeStakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LP_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLpTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLpTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstake() calls
    function __parseAssetsForUnstake(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        uint256 outgoingLiquidityGaugeTokenAmount = __decodeUnstakeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = LP_TOKEN;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during unstakeAndRedeem() calls
    function __parseAssetsForUnstakeAndRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingLiquidityGaugeTokenAmount,
            uint256[3] memory orderedMinIncomingAssetAmounts,
            bool receiveSingleAsset,
            bool useUnderlyings
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = LIQUIDITY_GAUGE_TOKEN;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingLiquidityGaugeTokenAmount;

        (incomingAssets_, minIncomingAssetAmounts_) = __parseIncomingAssetsForRedemptionCalls(
            orderedMinIncomingAssetAmounts,
            receiveSingleAsset,
            useUnderlyings
        );

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend assets for redeem() and unstakeAndRedeem() calls
    function __parseIncomingAssetsForRedemptionCalls(
        uint256[3] memory _orderedMinIncomingAssetAmounts,
        bool _receiveSingleAsset,
        bool _useUnderlyings
    )
        private
        view
        returns (address[] memory incomingAssets_, uint256[] memory minIncomingAssetAmounts_)
    {
        if (_receiveSingleAsset) {
            incomingAssets_ = new address[](1);
            minIncomingAssetAmounts_ = new uint256[](1);

            for (uint256 i; i < _orderedMinIncomingAssetAmounts.length; i++) {
                if (_orderedMinIncomingAssetAmounts[i] == 0) {
                    continue;
                }

                // Validate that only one min asset amount is set
                for (uint256 j = i + 1; j < _orderedMinIncomingAssetAmounts.length; j++) {
                    require(
                        _orderedMinIncomingAssetAmounts[j] == 0,
                        "__parseIncomingAssetsForRedemptionCalls: Too many min asset amounts specified"
                    );
                }

                incomingAssets_[0] = getAssetByPoolIndex(i, _useUnderlyings);
                minIncomingAssetAmounts_[0] = _orderedMinIncomingAssetAmounts[i];

                break;
            }
            require(
                incomingAssets_[0] != address(0),
                "__parseIncomingAssetsForRedemptionCalls: No min asset amount"
            );
        } else {
            incomingAssets_ = new address[](3);
            minIncomingAssetAmounts_ = new uint256[](3);
            for (uint256 i; i < incomingAssets_.length; i++) {
                incomingAssets_[i] = getAssetByPoolIndex(i, _useUnderlyings);
                minIncomingAssetAmounts_[i] = _orderedMinIncomingAssetAmounts[i];
            }
        }

        return (incomingAssets_, minIncomingAssetAmounts_);
    }

    /// @dev Helper function to parse spend assets for lend() and lendAndStake() calls
    function __parseSpendAssetsForLendingCalls(
        uint256[3] memory _orderedOutgoingAssetAmounts,
        bool _useUnderlyings
    ) private view returns (address[] memory spendAssets_, uint256[] memory spendAssetAmounts_) {
        uint256 spendAssetsCount;
        for (uint256 i; i < _orderedOutgoingAssetAmounts.length; i++) {
            if (_orderedOutgoingAssetAmounts[i] > 0) {
                spendAssetsCount++;
            }
        }

        spendAssets_ = new address[](spendAssetsCount);
        spendAssetAmounts_ = new uint256[](spendAssetsCount);
        uint256 spendAssetsIndex;
        for (uint256 i; i < _orderedOutgoingAssetAmounts.length; i++) {
            if (_orderedOutgoingAssetAmounts[i] > 0) {
                spendAssets_[spendAssetsIndex] = getAssetByPoolIndex(i, _useUnderlyings);
                spendAssetAmounts_[spendAssetsIndex] = _orderedOutgoingAssetAmounts[i];
                spendAssetsIndex++;
            }
        }

        return (spendAssets_, spendAssetAmounts_);
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    /// @dev Helper to decode the encoded call arguments for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256[3] memory orderedOutgoingAmounts_,
            uint256 minIncomingAssetAmount_,
            bool useUnderlyings_
        )
    {
        return abi.decode(_actionData, (uint256[3], uint256, bool));
    }

    /// @dev Helper to decode the encoded call arguments for redeeming.
    /// If `receiveSingleAsset_` is `true`, then one (and only one) of
    /// the orderedMinIncomingAmounts_ must be >0 to indicate which asset is to be received.
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingAssetAmount_,
            uint256[3] memory orderedMinIncomingAmounts_,
            bool receiveSingleAsset_,
            bool useUnderlyings_
        )
    {
        return abi.decode(_actionData, (uint256, uint256[3], bool, bool));
    }

    /// @dev Helper to decode the encoded call arguments for staking
    function __decodeStakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLPTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    /// @dev Helper to decode the encoded call arguments for unstaking
    function __decodeUnstakeCallArgs(bytes memory _actionData)
        private
        pure
        returns (uint256 outgoingLiquidityGaugeTokenAmount_)
    {
        return abi.decode(_actionData, (uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `LIQUIDITY_GAUGE_TOKEN` variable
    /// @return liquidityGaugeToken_ The `LIQUIDITY_GAUGE_TOKEN` variable value
    function getLiquidityGaugeToken() external view returns (address liquidityGaugeToken_) {
        return LIQUIDITY_GAUGE_TOKEN;
    }

    /// @notice Gets the `LP_TOKEN` variable
    /// @return lpToken_ The `LP_TOKEN` variable value
    function getLpToken() external view returns (address lpToken_) {
        return LP_TOKEN;
    }

    /// @notice Gets an asset by its pool index and whether or not to use the underlying
    /// instead of the aToken
    function getAssetByPoolIndex(uint256 _index, bool _useUnderlying)
        public
        view
        returns (address asset_)
    {
        if (_index == 0) {
            if (_useUnderlying) {
                return DAI_TOKEN;
            }
            return AAVE_DAI_TOKEN;
        } else if (_index == 1) {
            if (_useUnderlying) {
                return USDC_TOKEN;
            }
            return AAVE_USDC_TOKEN;
        } else if (_index == 2) {
            if (_useUnderlying) {
                return USDT_TOKEN;
            }
            return AAVE_USDT_TOKEN;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../../interfaces/ICurveStableSwapAave.sol";

/// @title CurveAaveLiquidityActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Curve Aave pool's liquidity functions
abstract contract CurveAaveLiquidityActionsMixin {
    using SafeERC20 for ERC20;

    address private immutable CURVE_AAVE_LIQUIDITY_POOL;

    constructor(
        address _pool,
        address[3] memory _aaveTokensToApprove,
        address[3] memory _underlyingTokensToApprove
    ) public {
        CURVE_AAVE_LIQUIDITY_POOL = _pool;

        // Pre-approve pool to use max of each aToken and underlying,
        // as specified by the inheriting contract.
        // Use address(0) to skip a particular ordered asset.
        for (uint256 i; i < 3; i++) {
            if (_aaveTokensToApprove[i] != address(0)) {
                ERC20(_aaveTokensToApprove[i]).safeApprove(_pool, type(uint256).max);
            }
            if (_underlyingTokensToApprove[i] != address(0)) {
                ERC20(_underlyingTokensToApprove[i]).safeApprove(_pool, type(uint256).max);
            }
        }
    }

    /// @dev Helper to add liquidity to the pool.
    /// _orderedOutgoingAssetAmounts = [aDAI, aUSDC, aUSDT].
    function __curveAaveLend(
        uint256[3] memory _orderedOutgoingAssetAmounts,
        uint256 _minIncomingLPTokenAmount,
        bool _useUnderlyings
    ) internal {
        ICurveStableSwapAave(CURVE_AAVE_LIQUIDITY_POOL).add_liquidity(
            _orderedOutgoingAssetAmounts,
            _minIncomingLPTokenAmount,
            _useUnderlyings
        );
    }

    /// @dev Helper to remove liquidity from the pool.
    /// if using _redeemSingleAsset, must pre-validate that one - and only one - asset
    /// has a non-zero _orderedMinIncomingAssetAmounts value.
    /// _orderedOutgoingAssetAmounts = [aDAI, aUSDC, aUSDT].
    function __curveAaveRedeem(
        uint256 _outgoingLPTokenAmount,
        uint256[3] memory _orderedMinIncomingAssetAmounts,
        bool _redeemSingleAsset,
        bool _useUnderlyings
    ) internal {
        if (_redeemSingleAsset) {
            // Assume that one - and only one - asset has a non-zero min incoming asset amount
            for (uint256 i; i < _orderedMinIncomingAssetAmounts.length; i++) {
                if (_orderedMinIncomingAssetAmounts[i] > 0) {
                    ICurveStableSwapAave(CURVE_AAVE_LIQUIDITY_POOL).remove_liquidity_one_coin(
                        _outgoingLPTokenAmount,
                        int128(i),
                        _orderedMinIncomingAssetAmounts[i],
                        _useUnderlyings
                    );
                    return;
                }
            }
        } else {
            ICurveStableSwapAave(CURVE_AAVE_LIQUIDITY_POOL).remove_liquidity(
                _outgoingLPTokenAmount,
                _orderedMinIncomingAssetAmounts,
                _useUnderlyings
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CURVE_AAVE_LIQUIDITY_POOL` variable
    /// @return pool_ The `CURVE_AAVE_LIQUIDITY_POOL` variable value
    function getCurveAaveLiquidityPool() public view returns (address pool_) {
        return CURVE_AAVE_LIQUIDITY_POOL;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveStableSwapAave interface
/// @author Enzyme Council <[email protected]>
interface ICurveStableSwapAave {
    function add_liquidity(
        uint256[3] calldata,
        uint256,
        bool
    ) external returns (uint256);

    function remove_liquidity(
        uint256,
        uint256[3] calldata,
        bool
    ) external returns (uint256[3] memory);

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256,
        bool
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../../persistent/external-positions/compound-debt/CompoundDebtPositionLibBase1.sol";
import "../../../../interfaces/ICERC20.sol";
import "../../../../interfaces/ICEther.sol";
import "../../../../interfaces/ICompoundComptroller.sol";
import "../../../../interfaces/IWETH.sol";
import "../../../../utils/AddressArrayLib.sol";
import "./ICompoundDebtPosition.sol";

/// @title CompoundDebtPositionLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice An External Position library contract for Compound debt positions
contract CompoundDebtPositionLib is CompoundDebtPositionLibBase1, ICompoundDebtPosition {
    using AddressArrayLib for address[];
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    address private immutable COMP_TOKEN;
    address private immutable COMPOUND_COMPTROLLER;
    address private immutable WETH_TOKEN;

    constructor(
        address _compoundComptroller,
        address _compToken,
        address _weth
    ) public {
        COMPOUND_COMPTROLLER = _compoundComptroller;
        COMP_TOKEN = _compToken;
        WETH_TOKEN = _weth;
    }

    /// @notice Initializes the external position
    /// @dev Nothing to initialize for this contract
    function init(bytes memory) external override {}

    /// @notice Receives and executes a call from the Vault
    /// @param _actionData Encoded data to execute the action
    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));

        (address[] memory assets, uint256[] memory amounts, bytes memory data) = abi.decode(
            actionArgs,
            (address[], uint256[], bytes)
        );

        if (actionId == uint256(ExternalPositionActions.AddCollateral)) {
            __addCollateralAssets(assets, amounts);
        } else if (actionId == uint256(ExternalPositionActions.RemoveCollateral)) {
            __removeCollateralAssets(assets, amounts);
        } else if (actionId == uint256(ExternalPositionActions.Borrow)) {
            __borrowAssets(assets, amounts, data);
        } else if (actionId == uint256(ExternalPositionActions.RepayBorrow)) {
            __repayBorrowedAssets(assets, amounts, data);
        } else if (actionId == uint256(ExternalPositionActions.ClaimComp)) {
            __claimComp();
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    /// @dev Adds assets as collateral
    function __addCollateralAssets(address[] memory _assets, uint256[] memory _amounts) private {
        uint256[] memory enterMarketErrorCodes = ICompoundComptroller(getCompoundComptroller())
            .enterMarkets(_assets);

        for (uint256 i; i < _assets.length; i++) {
            require(
                enterMarketErrorCodes[i] == 0,
                "__addCollateralAssets: Error while calling enterMarkets on Compound"
            );

            if (!assetIsCollateral(_assets[i])) {
                assetToIsCollateral[_assets[i]] = true;
                collateralAssets.push(_assets[i]);
            }

            emit CollateralAssetAdded(_assets[i], _amounts[i]);
        }
    }

    /// @dev Borrows assets using the available collateral
    function __borrowAssets(
        address[] memory _assets,
        uint256[] memory _amounts,
        bytes memory _data
    ) private {
        address[] memory cTokens = abi.decode(_data, (address[]));

        for (uint256 i; i < _assets.length; i++) {
            require(
                ICERC20(cTokens[i]).borrow(_amounts[i]) == 0,
                "__borrowAssets: Problem while borrowing from Compound"
            );

            // The cToken-token pair is already validated by the parser
            if (getCTokenFromBorrowedAsset(_assets[i]) == address(0)) {
                borrowedAssetToCToken[_assets[i]] = cTokens[i];
                borrowedAssets.push(_assets[i]);
            }

            if (_assets[i] == getWethToken()) {
                IWETH(payable(getWethToken())).deposit{value: _amounts[i]}();
            }

            ERC20(_assets[i]).safeTransfer(msg.sender, _amounts[i]);

            emit AssetBorrowed(_assets[i], _amounts[i]);
        }
    }

    /// @dev Claims the COMP_TOKEN accrued in all markets
    function __claimComp() private {
        ICompoundComptroller(getCompoundComptroller()).claimComp(address(this));

        ERC20 compToken = ERC20(getCompToken());

        compToken.safeTransfer(msg.sender, compToken.balanceOf(address(this)));
    }

    /// @dev Removes assets from collateral
    function __removeCollateralAssets(address[] memory _assets, uint256[] memory _amounts)
        private
    {
        for (uint256 i; i < _assets.length; i++) {
            require(
                assetIsCollateral(_assets[i]),
                "__removeCollateralAssets: Asset is not collateral"
            );

            if (ERC20(_assets[i]).balanceOf(address(this)) == _amounts[i]) {
                // If the full collateral of an asset is removed, it can be removed from collateral assets
                assetToIsCollateral[_assets[i]] = false;

                collateralAssets.removeStorageItem(_assets[i]);
            }

            ERC20(_assets[i]).safeTransfer(msg.sender, _amounts[i]);

            emit CollateralAssetRemoved(_assets[i], _amounts[i]);
        }
    }

    /// @notice Repays borrowed assets, reducing the borrow balance
    function __repayBorrowedAssets(
        address[] memory _assets,
        uint256[] memory _amounts,
        bytes memory _data
    ) private {
        address[] memory cTokens = abi.decode(_data, (address[]));

        for (uint256 i; i < _assets.length; i++) {
            require(
                getCTokenFromBorrowedAsset(_assets[i]) != address(0),
                "__repayBorrowedAssets: Asset has not been borrowed"
            );

            require(
                ERC20(_assets[i]).balanceOf(address(this)) >= _amounts[i],
                "__repayBorrowedAssets: Insufficient balance"
            );

            // Accrue interest to get the current borrow balance
            // NOTE: Used instead of borrow-balance-current: https://compound.finance/docs/ctokens#borrow-balance
            ICERC20(cTokens[i]).accrueInterest();
            uint256 borrowBalance = ICERC20(cTokens[i]).borrowBalanceStored(address(this));

            if (_amounts[i] < borrowBalance) {
                // Repaid amount doesn't cover the full balance
                __repayBorrowedAsset(cTokens[i], _assets[i], _amounts[i]);
            } else {
                // Amount covers the full borrow balance, so it can be removed from borrowed balances
                __repayBorrowedAsset(cTokens[i], _assets[i], borrowBalance);

                // Reset borrowed asset cToken and remove it from the list of borrowed assets
                delete borrowedAssetToCToken[_assets[i]];
                borrowedAssets.removeStorageItem(_assets[i]);

                // Send back the remaining token amount after paying the loan
                if (_amounts[i] > borrowBalance) {
                    ERC20(_assets[i]).safeTransfer(msg.sender, _amounts[i].sub(borrowBalance));
                }
            }

            emit BorrowedAssetRepaid(_assets[i], _amounts[i]);
        }
    }

    /// @dev Helper used to repay a borrowed asset to a Compound cToken
    function __repayBorrowedAsset(
        address _cToken,
        address _token,
        uint256 _amount
    ) private {
        if (_token == getWethToken()) {
            IWETH(payable(getWethToken())).withdraw(_amount);
            ICEther(_cToken).repayBorrow{value: _amount}();
        } else {
            ERC20(_token).safeApprove(_cToken, _amount);

            require(
                ICERC20(_cToken).repayBorrow(_amount) == 0,
                "__repayBorrowedAsset: Error while repaying borrow"
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Retrieves the borrowed assets and balances of the current external position
    /// @return assets_ Assets with an active loan
    /// @return amounts_ Amount of assets in external
    function getDebtAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        assets_ = borrowedAssets;
        amounts_ = new uint256[](assets_.length);

        for (uint256 i; i < assets_.length; i++) {
            address cToken = getCTokenFromBorrowedAsset(assets_[i]);
            amounts_[i] = ICERC20(cToken).borrowBalanceStored(address(this));
        }

        return (assets_, amounts_);
    }

    /// @notice Retrieves the collateral assets and balances of the current external position
    /// @return assets_ Assets with balance > 0 that are being used as collateral
    /// @return amounts_ Amount of assets being used as collateral
    function getManagedAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        assets_ = collateralAssets;
        amounts_ = new uint256[](collateralAssets.length);

        for (uint256 i; i < assets_.length; i++) {
            amounts_[i] = ERC20(assets_[i]).balanceOf(address(this));
        }

        return (assets_, amounts_);
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether an asset is collateral
    /// @return isCollateral True if the asset is part of the collateral assets of the external position
    function assetIsCollateral(address _asset) public view returns (bool isCollateral) {
        return assetToIsCollateral[_asset];
    }

    /// @notice Gets the `COMPOUND_COMPTROLLER` variable
    /// @return compoundComptroller_ The `COMPOUND_COMPTROLLER` variable value
    function getCompoundComptroller() public view returns (address compoundComptroller_) {
        return COMPOUND_COMPTROLLER;
    }

    /// @notice Gets the `COMP_TOKEN` variable
    /// @return compToken_ The `COMP_TOKEN` variable value
    function getCompToken() public view returns (address compToken_) {
        return COMP_TOKEN;
    }

    /// @notice Returns the cToken of a given borrowed asset
    /// @param _borrowedAsset The token for which to get the cToken
    /// @return cToken_ The cToken
    function getCTokenFromBorrowedAsset(address _borrowedAsset)
        public
        view
        returns (address cToken_)
    {
        return borrowedAssetToCToken[_borrowedAsset];
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() public view returns (address wethToken_) {
        return WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title CompoundDebtPositionLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a CompoundDebtPositionLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered CompoundDebtPositionLibBaseXXX that inherits the previous base.
/// e.g., `CompoundDebtPositionLibBase2 is CompoundDebtPositionLibBase1`

contract CompoundDebtPositionLibBase1 {
    event AssetBorrowed(address indexed asset, uint256 amount);

    event BorrowedAssetRepaid(address indexed asset, uint256 amount);

    event CollateralAssetAdded(address indexed asset, uint256 amount);

    event CollateralAssetRemoved(address indexed asset, uint256 amount);

    address[] internal borrowedAssets;
    address[] internal collateralAssets;

    mapping(address => bool) internal assetToIsCollateral;
    mapping(address => address) internal borrowedAssetToCToken;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ICERC20 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with Compound tokens (cTokens)
interface ICERC20 is IERC20 {
    function accrueInterest() external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function mint(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.6.12;

/// @title ICEther Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with Compound Ether
interface ICEther {
    function mint() external payable;

    function repayBorrow() external payable;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.6.12;

/// @title ICompoundComptroller Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with Compound Comptroller
interface ICompoundComptroller {
    function claimComp(address) external;

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function exitMarket(address) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../../persistent/external-positions/IExternalPosition.sol";

pragma solidity 0.6.12;

/// @title ICompoundDebtPosition Interface
/// @author Enzyme Council <[email protected]>
interface ICompoundDebtPosition is IExternalPosition {
    enum ExternalPositionActions {AddCollateral, RemoveCollateral, Borrow, RepayBorrow, ClaimComp}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "../../../../../persistent/external-positions/IExternalPosition.sol";
import "../../../../infrastructure/price-feeds/derivatives/feeds/CompoundPriceFeed.sol";
import "../../../../infrastructure/value-interpreter/ValueInterpreter.sol";
import "../IExternalPositionParser.sol";
import "./ICompoundDebtPosition.sol";

pragma solidity 0.6.12;

/// @title CompoundDebtPositionParser
/// @author Enzyme Council <[email protected]>
/// @notice Parser for Compound Debt Positions
contract CompoundDebtPositionParser is IExternalPositionParser {
    address private immutable COMP_TOKEN;
    address private immutable COMPOUND_PRICE_FEED;
    address private immutable VALUE_INTERPRETER;

    constructor(
        address _compoundPriceFeed,
        address _compToken,
        address _valueInterpreter
    ) public {
        COMPOUND_PRICE_FEED = _compoundPriceFeed;
        COMP_TOKEN = _compToken;
        VALUE_INTERPRETER = _valueInterpreter;
    }

    /// @notice Parses the assets to send and receive for the callOnExternalPosition
    /// @param _actionId The _actionId for the callOnExternalPosition
    /// @param _encodedActionArgs The encoded parameters for the callOnExternalPosition
    /// @return assetsToTransfer_ The assets to be transfered from the Vault
    /// @return amountsToTransfer_ The amounts to be transfered from the Vault
    /// @return assetsToReceive_ The assets to be received at the Vault
    function parseAssetsForAction(uint256 _actionId, bytes memory _encodedActionArgs)
        external
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        (
            address[] memory assets,
            uint256[] memory amounts,
            bytes memory data
        ) = __decodeEncodedActionArgs(_encodedActionArgs);

        __validateActionData(_actionId, assets, data);

        if (
            _actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.AddCollateral) ||
            _actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.RepayBorrow)
        ) {
            assetsToTransfer_ = assets;
            amountsToTransfer_ = amounts;
        } else if (
            _actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.Borrow) ||
            _actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.RemoveCollateral)
        ) {
            assetsToReceive_ = assets;
        } else if (_actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.ClaimComp)) {
            assetsToReceive_ = new address[](1);
            assetsToReceive_[0] = getCompToken();
        }

        return (assetsToTransfer_, amountsToTransfer_, assetsToReceive_);
    }

    /// @notice Parse and validate input arguments to be used when initializing a newly-deployed ExternalPositionProxy
    /// @return initArgs_ Parsed and encoded args for ExternalPositionProxy.init()
    function parseInitArgs(address, bytes memory)
        external
        override
        returns (bytes memory initArgs_)
    {
        return "";
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode action args
    function __decodeEncodedActionArgs(bytes memory _encodeActionArgs)
        private
        pure
        returns (
            address[] memory assets_,
            uint256[] memory amounts_,
            bytes memory data_
        )
    {
        (assets_, amounts_, data_) = abi.decode(_encodeActionArgs, (address[], uint256[], bytes));

        return (assets_, amounts_, data_);
    }

    /// @dev Runs validations before running a callOnExternalPosition.
    function __validateActionData(
        uint256 _actionId,
        address[] memory _assets,
        bytes memory _data
    ) private view {
        // Borrow and RepayBorrow actions make use of cTokens, that also need to be validated
        if (_actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.Borrow)) {
            for (uint256 i; i < _assets.length; i++) {
                require(
                    IValueInterpreter(getValueInterpreter()).isSupportedAsset(_assets[i]),
                    "__validateActionData: Unsupported asset"
                );
            }
            __validateCTokens(abi.decode(_data, (address[])), _assets);
        } else if (
            _actionId == uint256(ICompoundDebtPosition.ExternalPositionActions.RepayBorrow)
        ) {
            __validateCTokens(abi.decode(_data, (address[])), _assets);
        }
    }

    /// @dev Validates a set of cTokens and the underlying tokens
    function __validateCTokens(address[] memory _cTokens, address[] memory _tokens) private view {
        require(
            _cTokens.length == _tokens.length,
            "__validateCTokens: Unequal assets and cTokens length"
        );

        for (uint256 i; i < _cTokens.length; i++) {
            require(
                CompoundPriceFeed(getCompoundPriceFeed()).getTokenFromCToken(_cTokens[i]) ==
                    _tokens[i],
                "__validateCTokens: Bad token cToken pair"
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `COMPOUND_PRICE_FEED` variable
    /// @return compoundPriceFeed_ The `COMPOUND_PRICE_FEED` variable value
    function getCompoundPriceFeed() public view returns (address compoundPriceFeed_) {
        return COMPOUND_PRICE_FEED;
    }

    /// @notice Gets the `COMP_TOKEN` variable
    /// @return compToken_ The `COMP_TOKEN` variable value
    function getCompToken() public view returns (address compToken_) {
        return COMP_TOKEN;
    }

    /// @notice Gets the `VALUE_INTERPRETER` variable
    /// @return valueInterpreter_ The `VALUE_INTERPRETER` variable value
    function getValueInterpreter() public view returns (address valueInterpreter_) {
        return VALUE_INTERPRETER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/ICERC20.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title CompoundPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Compound Tokens (cTokens)
contract CompoundPriceFeed is IDerivativePriceFeed, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event CTokenAdded(address indexed cToken, address indexed token);

    uint256 private constant CTOKEN_RATE_DIVISOR = 10**18;

    mapping(address => address) private cTokenToToken;

    constructor(
        address _fundDeployer,
        address _weth,
        address _ceth
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        // Set cEth
        cTokenToToken[_ceth] = _weth;
        emit CTokenAdded(_ceth, _weth);
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        underlyings_ = new address[](1);
        underlyings_[0] = cTokenToToken[_derivative];
        require(underlyings_[0] != address(0), "calcUnderlyingValues: Unsupported derivative");

        underlyingAmounts_ = new uint256[](1);
        // Returns a rate scaled to 10^18
        underlyingAmounts_[0] = _derivativeAmount
            .mul(ICERC20(_derivative).exchangeRateStored())
            .div(CTOKEN_RATE_DIVISOR);

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return cTokenToToken[_asset] != address(0);
    }

    //////////////////////
    // CTOKENS REGISTRY //
    //////////////////////

    /// @notice Adds cTokens to the price feed
    /// @param _cTokens cTokens to add
    /// @dev Only allows CERC20 tokens. CEther is set in the constructor.
    function addCTokens(address[] calldata _cTokens) external onlyFundDeployerOwner {
        require(_cTokens.length > 0, "addCTokens: Empty _cTokens");

        for (uint256 i; i < _cTokens.length; i++) {
            require(cTokenToToken[_cTokens[i]] == address(0), "addCTokens: Value already set");

            address token = ICERC20(_cTokens[i]).underlying();
            cTokenToToken[_cTokens[i]] = token;

            emit CTokenAdded(_cTokens[i], token);
        }
    }

    ////////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Returns the underlying asset of a given cToken
    /// @param _cToken The cToken for which to get the underlying asset
    /// @return token_ The underlying token
    function getTokenFromCToken(address _cToken) public view returns (address token_) {
        return cTokenToToken[_cToken];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionParser Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all external position parsers
interface IExternalPositionParser {
    function parseAssetsForAction(uint256 _actionId, bytes memory _encodedActionArgs)
        external
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        );

    function parseInitArgs(address _vaultProxy, bytes memory _initializationData)
        external
        returns (bytes memory initArgs_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    
    (c) Enzyme Council <[email protected]>
    
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../persistent/external-positions/ExternalPositionFactory.sol";
import "../../../persistent/external-positions/IExternalPosition.sol";
import "../../../persistent/external-positions/IExternalPositionProxy.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../policy-manager/IPolicyManager.sol";
import "../utils/ExtensionBase.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./external-positions/IExternalPositionParser.sol";
import "./IExternalPositionManager.sol";

/// @title ExternalPositionManager
/// @author Enzyme Council <[email protected]>
/// @notice Extension to handle external position actions for funds
contract ExternalPositionManager is
    IExternalPositionManager,
    ExtensionBase,
    PermissionedVaultActionMixin,
    FundDeployerOwnerMixin
{
    event CallOnExternalPositionExecutedForFund(
        address indexed caller,
        address indexed comptrollerProxy,
        address indexed externalPosition,
        uint256 actionId,
        bytes actionArgs,
        address[] assetsToTransfer,
        uint256[] amountsToTransfer,
        address[] assetsToReceive
    );

    event ExternalPositionDeployedForFund(
        address indexed comptrollerProxy,
        address indexed vaultProxy,
        address externalPosition,
        uint256 indexed externalPositionTypeId,
        bytes data
    );

    event ExternalPositionTypeInfoUpdated(uint256 indexed typeId, address lib, address parser);

    address private immutable EXTERNAL_POSITION_FACTORY;
    address private immutable POLICY_MANAGER;

    mapping(uint256 => ExternalPositionTypeInfo) private typeIdToTypeInfo;

    constructor(
        address _fundDeployer,
        address _externalPositionFactory,
        address _policyManager
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        EXTERNAL_POSITION_FACTORY = _externalPositionFactory;
        POLICY_MANAGER = _policyManager;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Activates the extension by storing the VaultProxy
    function activateForFund(bool) external override {
        __setValidatedVaultProxy(msg.sender);
    }

    /// @notice Receives a dispatched `callOnExtension` from a fund's ComptrollerProxy
    /// @param _caller The user who called for this action
    /// @param _actionId An ID representing the desired action
    /// @param _callArgs The encoded args for the action
    function receiveCallFromComptroller(
        address _caller,
        uint256 _actionId,
        bytes calldata _callArgs
    ) external override {
        address comptrollerProxy = msg.sender;

        address vaultProxy = comptrollerProxyToVaultProxy[comptrollerProxy];
        require(vaultProxy != address(0), "receiveCallFromComptroller: Fund is not active");

        require(
            IVault(vaultProxy).canManageAssets(_caller),
            "receiveCallFromComptroller: Unauthorized"
        );

        // Dispatch the action
        if (_actionId == uint256(ExternalPositionManagerActions.CreateExternalPosition)) {
            __createExternalPosition(_caller, comptrollerProxy, vaultProxy, _callArgs);
        } else if (_actionId == uint256(ExternalPositionManagerActions.CallOnExternalPosition)) {
            __executeCallOnExternalPosition(_caller, comptrollerProxy, _callArgs);
        } else if (_actionId == uint256(ExternalPositionManagerActions.RemoveExternalPosition)) {
            __executeRemoveExternalPosition(_caller, comptrollerProxy, _callArgs);
        } else if (
            _actionId == uint256(ExternalPositionManagerActions.ReactivateExternalPosition)
        ) {
            __reactivateExternalPosition(_caller, comptrollerProxy, vaultProxy, _callArgs);
        } else {
            revert("receiveCallFromComptroller: Invalid _actionId");
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Creates a new external position and links it to the _vaultProxy
    function __createExternalPosition(
        address _caller,
        address _comptrollerProxy,
        address _vaultProxy,
        bytes memory _callArgs
    ) private {
        (uint256 typeId, bytes memory initializationData) = abi.decode(
            _callArgs,
            (uint256, bytes)
        );

        address parser = getExternalPositionParserForType(typeId);
        require(parser != address(0), "__createExternalPosition: Invalid typeId");

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.CreateExternalPosition,
            abi.encode(_caller, typeId, initializationData)
        );

        // Pass in _vaultProxy in case the external position requires it during init() or further operations
        bytes memory initArgs = IExternalPositionParser(parser).parseInitArgs(
            _vaultProxy,
            initializationData
        );

        bytes memory constructData = abi.encodeWithSelector(
            IExternalPosition.init.selector,
            initArgs
        );

        address externalPosition = ExternalPositionFactory(EXTERNAL_POSITION_FACTORY).deploy(
            _vaultProxy,
            typeId,
            getExternalPositionLibForType(typeId),
            constructData
        );

        emit ExternalPositionDeployedForFund(
            _comptrollerProxy,
            _vaultProxy,
            externalPosition,
            typeId,
            initArgs
        );

        __addExternalPosition(_comptrollerProxy, externalPosition);
    }

    /// @dev Performs an action on a specific external position
    function __executeCallOnExternalPosition(
        address _caller,
        address _comptrollerProxy,
        bytes memory _callArgs
    ) private {
        (address payable externalPosition, uint256 actionId, bytes memory actionArgs) = abi.decode(
            _callArgs,
            (address, uint256, bytes)
        );

        address parser = getExternalPositionParserForType(
            IExternalPositionProxy(externalPosition).getExternalPositionType()
        );

        (
            address[] memory assetsToTransfer,
            uint256[] memory amountsToTransfer,
            address[] memory assetsToReceive
        ) = IExternalPositionParser(parser).parseAssetsForAction(actionId, actionArgs);

        bytes memory encodedActionData = abi.encode(actionId, actionArgs);

        __callOnExternalPosition(
            _comptrollerProxy,
            abi.encode(
                externalPosition,
                encodedActionData,
                assetsToTransfer,
                amountsToTransfer,
                assetsToReceive
            )
        );

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.PostCallOnExternalPosition,
            abi.encode(
                _caller,
                externalPosition,
                assetsToTransfer,
                amountsToTransfer,
                assetsToReceive,
                encodedActionData
            )
        );

        emit CallOnExternalPositionExecutedForFund(
            _caller,
            _comptrollerProxy,
            externalPosition,
            actionId,
            actionArgs,
            assetsToTransfer,
            amountsToTransfer,
            assetsToReceive
        );
    }

    /// @dev Removes an external position from the VaultProxy
    function __executeRemoveExternalPosition(
        address _caller,
        address _comptrollerProxy,
        bytes memory _callArgs
    ) private {
        address externalPosition = abi.decode(_callArgs, (address));

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.RemoveExternalPosition,
            abi.encode(_caller, externalPosition)
        );

        __removeExternalPosition(_comptrollerProxy, externalPosition);
    }

    ///@dev Reactivates an existing externalPosition
    function __reactivateExternalPosition(
        address _caller,
        address _comptrollerProxy,
        address _vaultProxy,
        bytes memory _callArgs
    ) private {
        address externalPosition = abi.decode(_callArgs, (address));

        require(
            ExternalPositionFactory(getExternalPositionFactory()).isExternalPositionProxy(
                externalPosition
            ),
            "__reactivateExternalPosition: Account provided is not a valid external position"
        );

        require(
            IExternalPositionProxy(externalPosition).getVaultProxy() == _vaultProxy,
            "__reactivateExternalPosition: External position belongs to a different vault"
        );

        IPolicyManager(getPolicyManager()).validatePolicies(
            _comptrollerProxy,
            IPolicyManager.PolicyHook.ReactivateExternalPosition,
            abi.encode(_caller, externalPosition)
        );

        __addExternalPosition(_comptrollerProxy, externalPosition);
    }

    ///////////////////////////////////////////
    // EXTERNAL POSITION TYPES INFO REGISTRY //
    ///////////////////////////////////////////

    /// @notice Updates the libs and parsers for a set of external position type ids
    /// @param _typeIds The external position type ids for which to set the libs and parsers
    /// @param _libs The libs
    /// @param _parsers The parsers
    function updateExternalPositionTypesInfo(
        uint256[] memory _typeIds,
        address[] memory _libs,
        address[] memory _parsers
    ) external onlyFundDeployerOwner {
        require(
            _typeIds.length == _parsers.length && _libs.length == _parsers.length,
            "updateExternalPositionTypesInfo: Unequal arrays"
        );

        for (uint256 i; i < _typeIds.length; i++) {
            require(
                _typeIds[i] <
                    ExternalPositionFactory(getExternalPositionFactory()).getPositionTypeCounter(),
                "updateExternalPositionTypesInfo: Type does not exist"
            );

            typeIdToTypeInfo[_typeIds[i]] = ExternalPositionTypeInfo({
                lib: _libs[i],
                parser: _parsers[i]
            });

            emit ExternalPositionTypeInfoUpdated(_typeIds[i], _libs[i], _parsers[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXTERNAL_POSITION_FACTORY` variable
    /// @return externalPositionFactory_ The `EXTERNAL_POSITION_FACTORY` variable value
    function getExternalPositionFactory() public view returns (address externalPositionFactory_) {
        return EXTERNAL_POSITION_FACTORY;
    }

    /// @notice Gets the external position library contract for a given type
    /// @param _typeId The type for which to get the external position library
    /// @return lib_ The external position library
    function getExternalPositionLibForType(uint256 _typeId)
        public
        view
        override
        returns (address lib_)
    {
        return typeIdToTypeInfo[_typeId].lib;
    }

    /// @notice Gets the external position parser contract for a given type
    /// @param _typeId The type for which to get the external position's parser
    /// @return parser_ The external position parser
    function getExternalPositionParserForType(uint256 _typeId)
        public
        view
        returns (address parser_)
    {
        return typeIdToTypeInfo[_typeId].parser;
    }

    /// @notice Gets the `POLICY_MANAGER` variable
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() public view returns (address policyManager_) {
        return POLICY_MANAGER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../dispatcher/IDispatcher.sol";
import "./ExternalPositionProxy.sol";

/// @title ExternalPositionFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract factory for External Positions
contract ExternalPositionFactory {
    event PositionDeployed(
        address indexed vaultProxy,
        uint256 indexed typeId,
        address indexed constructLib,
        bytes constructData
    );

    event PositionDeployerAdded(address positionDeployer);

    event PositionDeployerRemoved(address positionDeployer);

    event PositionTypeAdded(uint256 typeId, string label);

    event PositionTypeLabelUpdated(uint256 indexed typeId, string label);

    address private immutable DISPATCHER;

    uint256 private positionTypeCounter;
    mapping(uint256 => string) private positionTypeIdToLabel;
    mapping(address => bool) private accountToIsExternalPositionProxy;
    mapping(address => bool) private accountToIsPositionDeployer;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );
        _;
    }

    constructor(address _dispatcher) public {
        DISPATCHER = _dispatcher;
    }

    /// @notice Creates a new external position proxy and adds it to the list of supported external positions
    /// @param _constructData Encoded data to be used on the ExternalPositionProxy constructor
    /// @param _vaultProxy The _vaultProxy owner of the external position
    /// @param _typeId The type of external position to be created
    /// @param _constructLib The external position lib contract that will be used on the constructor
    function deploy(
        address _vaultProxy,
        uint256 _typeId,
        address _constructLib,
        bytes memory _constructData
    ) external returns (address externalPositionProxy_) {
        require(
            isPositionDeployer(msg.sender),
            "deploy: Only a position deployer can call this function"
        );

        externalPositionProxy_ = address(
            new ExternalPositionProxy(_vaultProxy, _typeId, _constructLib, _constructData)
        );

        accountToIsExternalPositionProxy[externalPositionProxy_] = true;

        emit PositionDeployed(_vaultProxy, _typeId, _constructLib, _constructData);

        return externalPositionProxy_;
    }

    ////////////////////
    // TYPES REGISTRY //
    ////////////////////

    /// @notice Adds a set of new position types
    /// @param _labels Labels for each new position type
    function addNewPositionTypes(string[] calldata _labels) external onlyDispatcherOwner {
        for (uint256 i; i < _labels.length; i++) {
            uint256 typeId = getPositionTypeCounter();
            positionTypeCounter++;

            positionTypeIdToLabel[typeId] = _labels[i];

            emit PositionTypeAdded(typeId, _labels[i]);
        }
    }

    /// @notice Updates a set of position type labels
    /// @param _typeIds The position type ids
    /// @param _labels The updated labels
    function updatePositionTypeLabels(uint256[] calldata _typeIds, string[] calldata _labels)
        external
        onlyDispatcherOwner
    {
        require(_typeIds.length == _labels.length, "updatePositionTypeLabels: Unequal arrays");
        for (uint256 i; i < _typeIds.length; i++) {
            positionTypeIdToLabel[_typeIds[i]] = _labels[i];

            emit PositionTypeLabelUpdated(_typeIds[i], _labels[i]);
        }
    }

    /////////////////////////////////
    // POSITION DEPLOYERS REGISTRY //
    /////////////////////////////////

    /// @notice Adds a set of new position deployers
    /// @param _accounts Accounts to be added as position deployers
    function addPositionDeployers(address[] memory _accounts) external onlyDispatcherOwner {
        for (uint256 i; i < _accounts.length; i++) {
            require(
                !isPositionDeployer(_accounts[i]),
                "addPositionDeployers: Account is already a position deployer"
            );

            accountToIsPositionDeployer[_accounts[i]] = true;

            emit PositionDeployerAdded(_accounts[i]);
        }
    }

    /// @notice Removes a set of existing position deployers
    /// @param _accounts Existing position deployers to be removed from their role
    function removePositionDeployers(address[] memory _accounts) external onlyDispatcherOwner {
        for (uint256 i; i < _accounts.length; i++) {
            require(
                isPositionDeployer(_accounts[i]),
                "removePositionDeployers: Account is not a position deployer"
            );

            accountToIsPositionDeployer[_accounts[i]] = false;

            emit PositionDeployerRemoved(_accounts[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Gets the label for a position type
    /// @param _typeId The position type id
    /// @return label_ The label
    function getLabelForPositionType(uint256 _typeId)
        external
        view
        returns (string memory label_)
    {
        return positionTypeIdToLabel[_typeId];
    }

    /// @notice Checks if an account is an external position proxy
    /// @param _account The account to check
    /// @return isExternalPositionProxy_ True if the account is an externalPositionProxy
    function isExternalPositionProxy(address _account)
        external
        view
        returns (bool isExternalPositionProxy_)
    {
        return accountToIsExternalPositionProxy[_account];
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the `positionTypeCounter` variable
    /// @return positionTypeCounter_ The `positionTypeCounter` variable value
    function getPositionTypeCounter() public view returns (uint256 positionTypeCounter_) {
        return positionTypeCounter;
    }

    /// @notice Checks if an account is a position deployer
    /// @param _account The account to check
    /// @return isPositionDeployer_ True if the account is a position deployer
    function isPositionDeployer(address _account) public view returns (bool isPositionDeployer_) {
        return accountToIsPositionDeployer[_account];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionProxy interface
/// @author Enzyme Council <[email protected]>
/// @notice An interface for publicly accessible functions on the ExternalPositionProxy
interface IExternalPositionProxy {
    function getExternalPositionType() external view returns (uint256);

    function getVaultProxy() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../vault/interfaces/IExternalPositionVault.sol";
import "./IExternalPosition.sol";
import "./IExternalPositionProxy.sol";

/// @title ExternalPositionProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy for all external positions, modified from EIP-1822
contract ExternalPositionProxy is IExternalPositionProxy {
    uint256 private immutable EXTERNAL_POSITION_TYPE;
    address private immutable VAULT_PROXY;

    /// @dev Needed to receive ETH on external positions
    receive() external payable {}

    constructor(
        address _vaultProxy,
        uint256 _typeId,
        address _constructLib,
        bytes memory _constructData
    ) public {
        VAULT_PROXY = _vaultProxy;
        EXTERNAL_POSITION_TYPE = _typeId;

        (bool success, bytes memory returnData) = _constructLib.delegatecall(_constructData);

        require(success, string(returnData));
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = IExternalPositionVault(getVaultProxy())
            .getExternalPositionLibForType(getExternalPositionType());
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }

    /// @notice Delegates call to IExternalPosition.receiveCallFromVault
    /// @param _data The bytes data variable to be decoded at the External Position
    function receiveCallFromVault(bytes calldata _data) external {
        require(
            msg.sender == getVaultProxy(),
            "receiveCallFromVault: Only the vault can make this call"
        );
        address contractLogic = IExternalPositionVault(getVaultProxy())
            .getExternalPositionLibForType(getExternalPositionType());
        (bool success, bytes memory returnData) = contractLogic.delegatecall(
            abi.encodeWithSelector(IExternalPosition.receiveCallFromVault.selector, _data)
        );

        require(success, string(returnData));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXTERNAL_POSITION_TYPE` variable
    /// @return externalPositionType_ The `EXTERNAL_POSITION_TYPE` variable value
    function getExternalPositionType()
        public
        view
        override
        returns (uint256 externalPositionType_)
    {
        return EXTERNAL_POSITION_TYPE;
    }

    /// @notice Gets the `VAULT_PROXY` variable
    /// @return vaultProxy_ The `VAULT_PROXY` variable value
    function getVaultProxy() public view override returns (address vaultProxy_) {
        return VAULT_PROXY;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../IPolicy.sol";

/// @title PolicyBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract base contract for all policies
abstract contract PolicyBase is IPolicy {
    address internal immutable POLICY_MANAGER;

    modifier onlyPolicyManager {
        require(msg.sender == POLICY_MANAGER, "Only the PolicyManager can make this call");
        _;
    }

    constructor(address _policyManager) public {
        POLICY_MANAGER = _policyManager;
    }

    /// @notice Validates and initializes a policy as necessary prior to fund activation
    /// @dev Unimplemented by default, can be overridden by the policy
    function activateForFund(address) external virtual override {
        return;
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    /// @dev False by default, can be overridden by the policy
    function canDisable() external pure virtual override returns (bool canDisable_) {
        return false;
    }

    /// @notice Updates the policy settings for a fund
    /// @dev Disallowed by default, can be overridden by the policy
    function updateFundSettings(address, bytes calldata) external virtual override {
        revert("updateFundSettings: Updates not allowed for this policy");
    }

    //////////////////////////////
    // VALIDATION DATA DECODING //
    //////////////////////////////

    /// @dev Helper to parse validation arguments from encoded data for AddTrackedAssets policy hook
    function __decodeAddTrackedAssetsValidationData(bytes memory _validationData)
        internal
        pure
        returns (address caller_, address[] memory assets_)
    {
        return abi.decode(_validationData, (address, address[]));
    }

    /// @dev Helper to parse validation arguments from encoded data for CreateExternalPosition policy hook
    function __decodeCreateExternalPositionValidationData(bytes memory _validationData)
        internal
        pure
        returns (
            address caller_,
            uint256 typeId_,
            bytes memory initializationData_
        )
    {
        return abi.decode(_validationData, (address, uint256, bytes));
    }

    /// @dev Helper to parse validation arguments from encoded data for PreTransferShares policy hook
    function __decodePreTransferSharesValidationData(bytes memory _validationData)
        internal
        pure
        returns (
            address sender_,
            address recipient_,
            uint256 amount_
        )
    {
        return abi.decode(_validationData, (address, address, uint256));
    }

    /// @dev Helper to parse validation arguments from encoded data for PostBuyShares policy hook
    function __decodePostBuySharesValidationData(bytes memory _validationData)
        internal
        pure
        returns (
            address buyer_,
            uint256 investmentAmount_,
            uint256 sharesIssued_,
            uint256 gav_
        )
    {
        return abi.decode(_validationData, (address, uint256, uint256, uint256));
    }

    /// @dev Helper to parse validation arguments from encoded data for PostCallOnExternalPosition policy hook
    function __decodePostCallOnExternalPositionValidationData(bytes memory _validationData)
        internal
        pure
        returns (
            address caller_,
            address externalPosition_,
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_,
            bytes memory encodedActionData_
        )
    {
        return
            abi.decode(
                _validationData,
                (address, address, address[], uint256[], address[], bytes)
            );
    }

    /// @dev Helper to parse validation arguments from encoded data for PostCallOnIntegration policy hook
    function __decodePostCallOnIntegrationValidationData(bytes memory _validationData)
        internal
        pure
        returns (
            address caller_,
            address adapter_,
            bytes4 selector_,
            address[] memory incomingAssets_,
            uint256[] memory incomingAssetAmounts_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_
        )
    {
        return
            abi.decode(
                _validationData,
                (address, address, bytes4, address[], uint256[], address[], uint256[])
            );
    }

    /// @dev Helper to parse validation arguments from encoded data for ReactivateExternalPosition policy hook
    function __decodeReactivateExternalPositionValidationData(bytes memory _validationData)
        internal
        pure
        returns (address caller_, address externalPosition_)
    {
        return abi.decode(_validationData, (address, address));
    }

    /// @dev Helper to parse validation arguments from encoded data for RedeemSharesForSpecificAssets policy hook
    function __decodeRedeemSharesForSpecificAssetsValidationData(bytes memory _validationData)
        internal
        pure
        returns (
            address redeemer_,
            address recipient_,
            uint256 sharesToRedeemPostFees_,
            address[] memory assets_,
            uint256[] memory assetAmounts_,
            uint256 gavPreRedeem_
        )
    {
        return
            abi.decode(
                _validationData,
                (address, address, uint256, address[], uint256[], uint256)
            );
    }

    /// @dev Helper to parse validation arguments from encoded data for RemoveExternalPosition policy hook
    function __decodeRemoveExternalPositionValidationData(bytes memory _validationData)
        internal
        pure
        returns (address caller_, address externalPosition_)
    {
        return abi.decode(_validationData, (address, address));
    }

    /// @dev Helper to parse validation arguments from encoded data for RemoveTrackedAssets policy hook
    function __decodeRemoveTrackedAssetsValidationData(bytes memory _validationData)
        internal
        pure
        returns (address caller_, address[] memory assets_)
    {
        return abi.decode(_validationData, (address, address[]));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `POLICY_MANAGER` variable value
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() external view returns (address policyManager_) {
        return POLICY_MANAGER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/PolicyBase.sol";

/// @title MinMaxInvestmentPolicy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that restricts the amount of the fund's denomination asset that a user can
/// send in a single call to buy shares in a fund
contract MinMaxInvestmentPolicy is PolicyBase {
    event FundSettingsSet(
        address indexed comptrollerProxy,
        uint256 minInvestmentAmount,
        uint256 maxInvestmentAmount
    );

    struct FundSettings {
        uint256 minInvestmentAmount;
        uint256 maxInvestmentAmount;
    }

    mapping(address => FundSettings) private comptrollerProxyToFundSettings;

    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// @notice Adds the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __setFundSettings(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    function canDisable() external pure virtual override returns (bool canDisable_) {
        return true;
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "MIN_MAX_INVESTMENT";
    }

    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PostBuyShares;

        return implementedHooks_;
    }

    /// @notice Updates the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __setFundSettings(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _investmentAmount The investment amount for which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, uint256 _investmentAmount)
        public
        view
        returns (bool isValid_)
    {
        uint256 minInvestmentAmount = comptrollerProxyToFundSettings[_comptrollerProxy]
            .minInvestmentAmount;
        uint256 maxInvestmentAmount = comptrollerProxyToFundSettings[_comptrollerProxy]
            .maxInvestmentAmount;

        // Both minInvestmentAmount and maxInvestmentAmount can be 0 in order to close the fund
        // temporarily
        if (minInvestmentAmount == 0) {
            return _investmentAmount <= maxInvestmentAmount;
        } else if (maxInvestmentAmount == 0) {
            return _investmentAmount >= minInvestmentAmount;
        }
        return
            _investmentAmount >= minInvestmentAmount && _investmentAmount <= maxInvestmentAmount;
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, uint256 investmentAmount, , ) = __decodePostBuySharesValidationData(_encodedArgs);

        return passesRule(_comptrollerProxy, investmentAmount);
    }

    /// @dev Helper to set the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function __setFundSettings(address _comptrollerProxy, bytes memory _encodedSettings) private {
        (uint256 minInvestmentAmount, uint256 maxInvestmentAmount) = abi.decode(
            _encodedSettings,
            (uint256, uint256)
        );

        require(
            maxInvestmentAmount == 0 || minInvestmentAmount < maxInvestmentAmount,
            "__setFundSettings: minInvestmentAmount must be less than maxInvestmentAmount"
        );

        comptrollerProxyToFundSettings[_comptrollerProxy]
            .minInvestmentAmount = minInvestmentAmount;
        comptrollerProxyToFundSettings[_comptrollerProxy]
            .maxInvestmentAmount = maxInvestmentAmount;

        emit FundSettingsSet(_comptrollerProxy, minInvestmentAmount, maxInvestmentAmount);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the min and max investment amount for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return fundSettings_ The fund settings
    function getFundSettings(address _comptrollerProxy)
        external
        view
        returns (FundSettings memory fundSettings_)
    {
        return comptrollerProxyToFundSettings[_comptrollerProxy];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/AddressListPolicyMixin.sol";
import "../utils/PolicyBase.sol";

/// @title AllowedDepositRecipientsPolicy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that limits the accounts that can receive shares via deposit
contract AllowedDepositRecipientsPolicy is PolicyBase, AddressListPolicyMixin {
    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// @notice Adds the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __updateList(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    function canDisable() external pure virtual override returns (bool canDisable_) {
        return true;
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "ALLOWED_DEPOSIT_RECIPIENTS";
    }

    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PostBuyShares;

        return implementedHooks_;
    }

    /// @notice Updates the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __updateList(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _investor The investor for which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address _investor)
        public
        view
        returns (bool isValid_)
    {
        return isInList(_comptrollerProxy, _investor);
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address buyer, , , ) = __decodePostBuySharesValidationData(_encodedArgs);

        return passesRule(_comptrollerProxy, buyer);
    }

    /// @dev Helper to update the allowed deposit recipients list by adding and/or removing addresses
    function __updateList(address _comptrollerProxy, bytes memory _settingsData) private {
        (address[] memory itemsToAdd, address[] memory itemsToRemove) = abi.decode(
            _settingsData,
            (address[], address[])
        );

        // If an address is in both add and remove arrays, they will not be in the final list.
        // We do not check for uniqueness between the two arrays for efficiency.
        if (itemsToAdd.length > 0) {
            __addToList(_comptrollerProxy, itemsToAdd);
        }
        if (itemsToRemove.length > 0) {
            __removeFromList(_comptrollerProxy, itemsToRemove);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

/// @title AddressListPolicyMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice An abstract mixin contract for policies that use an address list
abstract contract AddressListPolicyMixin {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddressesAdded(address indexed comptrollerProxy, address[] items);

    event AddressesRemoved(address indexed comptrollerProxy, address[] items);

    mapping(address => EnumerableSet.AddressSet) private comptrollerProxyToList;

    // EXTERNAL FUNCTIONS

    /// @notice Get all addresses in a fund's list
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @return list_ The addresses in the fund's list
    function getList(address _comptrollerProxy) external view returns (address[] memory list_) {
        list_ = new address[](comptrollerProxyToList[_comptrollerProxy].length());
        for (uint256 i = 0; i < list_.length; i++) {
            list_[i] = comptrollerProxyToList[_comptrollerProxy].at(i);
        }
        return list_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Check if an address is in a fund's list
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _item The address to check against the list
    /// @return isInList_ True if the address is in the list
    function isInList(address _comptrollerProxy, address _item)
        public
        view
        returns (bool isInList_)
    {
        return comptrollerProxyToList[_comptrollerProxy].contains(_item);
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to add addresses to the calling fund's list
    function __addToList(address _comptrollerProxy, address[] memory _items) internal {
        require(_items.length > 0, "__addToList: No addresses provided");

        for (uint256 i = 0; i < _items.length; i++) {
            require(
                comptrollerProxyToList[_comptrollerProxy].add(_items[i]),
                "__addToList: Address already exists in list"
            );
        }

        emit AddressesAdded(_comptrollerProxy, _items);
    }

    /// @dev Helper to remove addresses from the calling fund's list
    function __removeFromList(address _comptrollerProxy, address[] memory _items) internal {
        require(_items.length > 0, "__removeFromList: No addresses provided");

        for (uint256 i = 0; i < _items.length; i++) {
            require(
                comptrollerProxyToList[_comptrollerProxy].remove(_items[i]),
                "__removeFromList: Address does not exist in list"
            );
        }

        emit AddressesRemoved(_comptrollerProxy, _items);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
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

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/AddressListPolicyMixin.sol";
import "../utils/PolicyBase.sol";

/// @title AllowedAdapterIncomingAssetsPolicy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that limits assets that can be received via an adapter action
contract AllowedAdapterIncomingAssetsPolicy is PolicyBase, AddressListPolicyMixin {
    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// @notice Add the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __addToList(_comptrollerProxy, abi.decode(_encodedSettings, (address[])));
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "ALLOWED_ADAPTER_INCOMING_ASSETS";
    }

    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PostCallOnIntegration;

        return implementedHooks_;
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _assets The assets with which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address[] memory _assets)
        public
        view
        returns (bool isValid_)
    {
        for (uint256 i; i < _assets.length; i++) {
            if (!isInList(_comptrollerProxy, _assets[i])) {
                return false;
            }
        }

        return true;
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (
            ,
            ,
            ,
            address[] memory incomingAssets,
            ,
            ,

        ) = __decodePostCallOnIntegrationValidationData(_encodedArgs);

        return passesRule(_comptrollerProxy, incomingAssets);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../utils/PolicyBase.sol";

/// @title GuaranteedRedemptionPolicy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that guarantees that shares will either be continuously redeemable or
/// redeemable within a predictable daily window by preventing trading during a configurable daily period
contract GuaranteedRedemptionPolicy is PolicyBase, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event AdapterAdded(address adapter);

    event AdapterRemoved(address adapter);

    event FundSettingsSet(
        address indexed comptrollerProxy,
        uint256 startTimestamp,
        uint256 duration
    );

    event RedemptionWindowBufferSet(uint256 prevBuffer, uint256 nextBuffer);

    struct RedemptionWindow {
        uint256 startTimestamp;
        uint256 duration;
    }

    uint256 private constant ONE_DAY = 24 * 60 * 60;

    mapping(address => bool) private adapterToCanBlockRedemption;
    mapping(address => RedemptionWindow) private comptrollerProxyToRedemptionWindow;
    uint256 private redemptionWindowBuffer;

    constructor(
        address _policyManager,
        address _fundDeployer,
        uint256 _redemptionWindowBuffer,
        address[] memory _redemptionBlockingAdapters
    ) public PolicyBase(_policyManager) FundDeployerOwnerMixin(_fundDeployer) {
        redemptionWindowBuffer = _redemptionWindowBuffer;

        __addRedemptionBlockingAdapters(_redemptionBlockingAdapters);
    }

    // EXTERNAL FUNCTIONS

    /// @notice Add the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        (uint256 startTimestamp, uint256 duration) = abi.decode(
            _encodedSettings,
            (uint256, uint256)
        );

        if (startTimestamp == 0) {
            require(duration == 0, "addFundSettings: duration must be 0 if startTimestamp is 0");
            return;
        }

        // Use 23 hours instead of 1 day to allow up to 1 hr of redemptionWindowBuffer
        require(
            duration > 0 && duration <= 23 hours,
            "addFundSettings: duration must be between 1 second and 23 hours"
        );

        comptrollerProxyToRedemptionWindow[_comptrollerProxy].startTimestamp = startTimestamp;
        comptrollerProxyToRedemptionWindow[_comptrollerProxy].duration = duration;

        emit FundSettingsSet(_comptrollerProxy, startTimestamp, duration);
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "GUARANTEED_REDEMPTION";
    }

    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PostCallOnIntegration;

        return implementedHooks_;
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _adapter The adapter for which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address _adapter)
        public
        view
        returns (bool isValid_)
    {
        if (!adapterCanBlockRedemption(_adapter)) {
            return true;
        }


            RedemptionWindow memory redemptionWindow
         = comptrollerProxyToRedemptionWindow[_comptrollerProxy];

        // If no RedemptionWindow is set, the fund can never use redemption-blocking adapters
        if (redemptionWindow.startTimestamp == 0) {
            return false;
        }

        uint256 latestRedemptionWindowStart = calcLatestRedemptionWindowStart(
            redemptionWindow.startTimestamp
        );

        // A fund can't trade during its redemption window, nor in the buffer beforehand.
        // The lower bound is only relevant when the startTimestamp is in the future,
        // so we check it last.
        if (
            block.timestamp >= latestRedemptionWindowStart.add(redemptionWindow.duration) ||
            block.timestamp <= latestRedemptionWindowStart.sub(redemptionWindowBuffer)
        ) {
            return true;
        }

        return false;
    }

    /// @notice Sets a new value for the redemptionWindowBuffer variable
    /// @param _nextRedemptionWindowBuffer The number of seconds for the redemptionWindowBuffer
    /// @dev The redemptionWindowBuffer is added to the beginning of the redemption window,
    /// and should always be >= the longest potential block on redemption amongst all adapters.
    /// (e.g., Synthetix blocks token transfers during a timelock after trading synths)
    function setRedemptionWindowBuffer(uint256 _nextRedemptionWindowBuffer)
        external
        onlyFundDeployerOwner
    {
        uint256 prevRedemptionWindowBuffer = redemptionWindowBuffer;
        require(
            _nextRedemptionWindowBuffer != prevRedemptionWindowBuffer,
            "setRedemptionWindowBuffer: Value already set"
        );

        redemptionWindowBuffer = _nextRedemptionWindowBuffer;

        emit RedemptionWindowBufferSet(prevRedemptionWindowBuffer, _nextRedemptionWindowBuffer);
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, address adapter, , , , , ) = __decodePostCallOnIntegrationValidationData(_encodedArgs);

        return passesRule(_comptrollerProxy, adapter);
    }

    // PUBLIC FUNCTIONS

    /// @notice Calculates the start of the most recent redemption window
    /// @param _startTimestamp The initial startTimestamp for the redemption window
    /// @return latestRedemptionWindowStart_ The starting timestamp of the most recent redemption window
    function calcLatestRedemptionWindowStart(uint256 _startTimestamp)
        public
        view
        returns (uint256 latestRedemptionWindowStart_)
    {
        if (block.timestamp <= _startTimestamp) {
            return _startTimestamp;
        }

        uint256 timeSinceStartTimestamp = block.timestamp.sub(_startTimestamp);
        uint256 timeSincePeriodStart = timeSinceStartTimestamp.mod(ONE_DAY);

        return block.timestamp.sub(timeSincePeriodStart);
    }

    ///////////////////////////////////////////
    // REDEMPTION-BLOCKING ADAPTERS REGISTRY //
    ///////////////////////////////////////////

    /// @notice Add adapters which can block shares redemption
    /// @param _adapters The addresses of adapters to be added
    function addRedemptionBlockingAdapters(address[] calldata _adapters)
        external
        onlyFundDeployerOwner
    {
        require(
            _adapters.length > 0,
            "__addRedemptionBlockingAdapters: _adapters cannot be empty"
        );

        __addRedemptionBlockingAdapters(_adapters);
    }

    /// @notice Remove adapters which can block shares redemption
    /// @param _adapters The addresses of adapters to be removed
    function removeRedemptionBlockingAdapters(address[] calldata _adapters)
        external
        onlyFundDeployerOwner
    {
        require(
            _adapters.length > 0,
            "removeRedemptionBlockingAdapters: _adapters cannot be empty"
        );

        for (uint256 i; i < _adapters.length; i++) {
            require(
                adapterCanBlockRedemption(_adapters[i]),
                "removeRedemptionBlockingAdapters: adapter is not added"
            );

            adapterToCanBlockRedemption[_adapters[i]] = false;

            emit AdapterRemoved(_adapters[i]);
        }
    }

    /// @dev Helper to mark adapters that can block shares redemption
    function __addRedemptionBlockingAdapters(address[] memory _adapters) private {
        for (uint256 i; i < _adapters.length; i++) {
            require(
                _adapters[i] != address(0),
                "__addRedemptionBlockingAdapters: adapter cannot be empty"
            );
            require(
                !adapterCanBlockRedemption(_adapters[i]),
                "__addRedemptionBlockingAdapters: adapter already added"
            );

            adapterToCanBlockRedemption[_adapters[i]] = true;

            emit AdapterAdded(_adapters[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `redemptionWindowBuffer` variable
    /// @return redemptionWindowBuffer_ The `redemptionWindowBuffer` variable value
    function getRedemptionWindowBuffer() external view returns (uint256 redemptionWindowBuffer_) {
        return redemptionWindowBuffer;
    }

    /// @notice Gets the RedemptionWindow settings for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return redemptionWindow_ The RedemptionWindow settings
    function getRedemptionWindowForFund(address _comptrollerProxy)
        external
        view
        returns (RedemptionWindow memory redemptionWindow_)
    {
        return comptrollerProxyToRedemptionWindow[_comptrollerProxy];
    }

    /// @notice Checks whether an adapter can block shares redemption
    /// @param _adapter The address of the adapter to check
    /// @return canBlockRedemption_ True if the adapter can block shares redemption
    function adapterCanBlockRedemption(address _adapter)
        public
        view
        returns (bool canBlockRedemption_)
    {
        return adapterToCanBlockRedemption[_adapter];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../persistent/external-positions/IExternalPosition.sol";
import "../release/utils/AddressArrayLib.sol";

/// @title MockGenericExternalPosition Contract
/// @author Enzyme Council <[email protected]>
/// @notice Provides a generic external position to be used on tests
contract MockGenericExternalPositionLib is IExternalPosition {
    using AddressArrayLib for address[];

    enum MockGenericExternalPositionActions {
        AddManagedAssets,
        RemoveManagedAssets,
        AddDebtAssets,
        RemoveDebtAssets
    }

    address[] private debtAssets;
    address[] private managedAssets;

    mapping(address => uint256) private debtAssetsToAmounts;
    mapping(address => uint256) private managedAssetsToAmounts;

    function init(bytes memory) external override {}

    function receiveCallFromVault(bytes memory _actionData) external override {
        (uint256 actionId, bytes memory actionArgs) = abi.decode(_actionData, (uint256, bytes));

        (address[] memory assets, uint256[] memory amounts) = abi.decode(
            actionArgs,
            (address[], uint256[])
        );
        if (actionId == uint256(MockGenericExternalPositionActions.AddManagedAssets)) {
            __addManagedAssets(assets, amounts);
        } else if (actionId == uint256(MockGenericExternalPositionActions.RemoveManagedAssets)) {
            __removeManagedAssets(assets);
        } else if (actionId == uint256(MockGenericExternalPositionActions.AddDebtAssets)) {
            __addDebtAssets(assets, amounts);
        } else if (actionId == uint256(MockGenericExternalPositionActions.RemoveDebtAssets)) {
            __removeDebtAssets(assets);
        } else {
            revert("receiveCallFromVault: Invalid actionId");
        }
    }

    /// @dev Adds an array of assets to the existing debt assets
    function __addDebtAssets(address[] memory _assets, uint256[] memory _amounts) private {
        for (uint256 i; i < _assets.length; i++) {
            debtAssets.push(_assets[i]);

            debtAssetsToAmounts[_assets[i]] = _amounts[i];
        }
    }

    /// @dev Adds an array of assets to the existing managed assets
    function __addManagedAssets(address[] memory _assets, uint256[] memory _amounts) private {
        for (uint256 i; i < _assets.length; i++) {
            managedAssets.push(_assets[i]);

            managedAssetsToAmounts[_assets[i]] = _amounts[i];
        }
    }

    /// @dev Removes an array of assets from the existing debt assets
    function __removeDebtAssets(address[] memory _assets) private {
        for (uint256 i; i < _assets.length; i++) {
            if (debtAssetsToAmounts[_assets[i]] > 0) {
                debtAssets.removeStorageItem(_assets[i]);
                debtAssetsToAmounts[_assets[i]] = 0;
            }
        }
    }

    /// @dev Removes an array of assets from the existing managed assets
    function __removeManagedAssets(address[] memory _assets) private {
        for (uint256 i; i < _assets.length; i++) {
            if (managedAssetsToAmounts[_assets[i]] > 0) {
                managedAssets.removeStorageItem(_assets[i]);
                managedAssetsToAmounts[_assets[i]] = 0;
            }
        }
    }

    /// @dev Gets the array of debt assets
    function getDebtAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        assets_ = new address[](debtAssets.length);
        amounts_ = new uint256[](debtAssets.length);

        for (uint256 i; i < debtAssets.length; i++) {
            assets_[i] = debtAssets[i];
            amounts_[i] = debtAssetsToAmounts[assets_[i]];
        }
        return (assets_, amounts_);
    }

    /// @dev Gets the array of managed assets
    function getManagedAssets()
        external
        override
        returns (address[] memory assets_, uint256[] memory amounts_)
    {
        assets_ = new address[](managedAssets.length);
        amounts_ = new uint256[](managedAssets.length);

        for (uint256 i; i < managedAssets.length; i++) {
            assets_[i] = managedAssets[i];
            amounts_[i] = managedAssetsToAmounts[assets_[i]];
        }
        return (assets_, amounts_);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../../utils/beacon-proxy/BeaconProxyFactory.sol";

/// @title GasRelayPaymasterFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice Factory contract that deploys paymaster proxies for gas relaying
contract GasRelayPaymasterFactory is BeaconProxyFactory {
    address private immutable DISPATCHER;

    constructor(address _dispatcher, address _paymasterLib)
        public
        BeaconProxyFactory(_paymasterLib)
    {
        DISPATCHER = _dispatcher;
    }

    /// @notice Gets the contract owner
    /// @return owner_ The contract owner
    function getOwner() public view override returns (address owner_) {
        return IDispatcher(getDispatcher()).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../FundDeployerOwnerMixin.sol";
import "./BeaconProxy.sol";
import "./IBeaconProxyFactory.sol";

/// @title BeaconProxyFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice Factory contract that deploys beacon proxies
abstract contract BeaconProxyFactory is IBeaconProxyFactory {
    event CanonicalLibSet(address nextCanonicalLib);

    event ProxyDeployed(address indexed caller, address proxy, bytes constructData);

    address private canonicalLib;

    constructor(address _canonicalLib) public {
        __setCanonicalLib(_canonicalLib);
    }

    /// @notice Deploys a new proxy instance
    /// @param _constructData The constructor data with which to call `init()` on the deployed proxy
    /// @return proxy_ The proxy address
    function deployProxy(bytes memory _constructData) external override returns (address proxy_) {
        proxy_ = address(new BeaconProxy(_constructData, address(this)));

        emit ProxyDeployed(msg.sender, proxy_, _constructData);

        return proxy_;
    }

    /// @notice Gets the canonical lib used by all proxies
    /// @return canonicalLib_ The canonical lib
    function getCanonicalLib() public view override returns (address canonicalLib_) {
        return canonicalLib;
    }

    /// @notice Gets the contract owner
    /// @return owner_ The contract owner
    function getOwner() public view virtual returns (address owner_);

    /// @notice Sets the next canonical lib used by all proxies
    /// @param _nextCanonicalLib The next canonical lib
    function setCanonicalLib(address _nextCanonicalLib) public override {
        require(
            msg.sender == getOwner(),
            "setCanonicalLib: Only the owner can call this function"
        );

        __setCanonicalLib(_nextCanonicalLib);
    }

    /// @dev Helper to set the next canonical lib
    function __setCanonicalLib(address _nextCanonicalLib) private {
        canonicalLib = _nextCanonicalLib;

        emit CanonicalLibSet(_nextCanonicalLib);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./IBeacon.sol";

/// @title BeaconProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract that uses the beacon pattern for instant upgrades
contract BeaconProxy {
    address private immutable BEACON;

    constructor(bytes memory _constructData, address _beacon) public {
        BEACON = _beacon;

        (bool success, bytes memory returnData) = IBeacon(_beacon).getCanonicalLib().delegatecall(
            _constructData
        );
        require(success, string(returnData));
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = IBeacon(BEACON).getCanonicalLib();
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../dispatcher/IDispatcher.sol";
import "../utils/ProxiableProtocolFeeReserveLib.sol";

/// @title ProtocolFeeReserveLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core implementation of ProtocolFeeReserveLib
/// @dev To be inherited by the first ProtocolFeeReserveLibBase implementation only.
/// DO NOT EDIT CONTRACT.
abstract contract ProtocolFeeReserveLibBaseCore is ProxiableProtocolFeeReserveLib {
    event ProtocolFeeReserveLibSet(address nextProtocolFeeReserveLib);

    address private dispatcher;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(getDispatcher()).getOwner(),
            "Only the Dispatcher owner can call this function"
        );

        _;
    }

    /// @notice Initializes the ProtocolFeeReserveProxy with core configuration
    /// @param _dispatcher The Dispatcher contract
    /// @dev Serves as a pseudo-constructor
    function init(address _dispatcher) external {
        require(getDispatcher() == address(0), "init: Proxy already initialized");

        dispatcher = _dispatcher;

        emit ProtocolFeeReserveLibSet(getProtocolFeeReserveLib());
    }

    /// @notice Sets the ProtocolFeeReserveLib target for the ProtocolFeeReserveProxy
    /// @param _nextProtocolFeeReserveLib The address to set as the ProtocolFeeReserveLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextProtocolFeeReserveLib from being the same as the current ProtocolFeeReserveLib
    function setProtocolFeeReserveLib(address _nextProtocolFeeReserveLib)
        external
        onlyDispatcherOwner
    {
        __updateCodeAddress(_nextProtocolFeeReserveLib);

        emit ProtocolFeeReserveLibSet(_nextProtocolFeeReserveLib);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `dispatcher` variable
    /// @return dispatcher_ The `dispatcher` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return dispatcher;
    }

    /// @notice Gets the ProtocolFeeReserveLib target for the ProtocolFeeReserveProxy
    /// @return protocolFeeReserveLib_ The address of the ProtocolFeeReserveLib target
    function getProtocolFeeReserveLib() public view returns (address protocolFeeReserveLib_) {
        assembly {
            protocolFeeReserveLib_ := sload(EIP_1967_SLOT)
        }

        return protocolFeeReserveLib_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

import "./ProtocolFeeProxyConstants.sol";

pragma solidity 0.6.12;

/// @title ProxiableProtocolFeeReserveLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for ProtocolFeeReserveLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// See: https://eips.ethereum.org/EIPS/eip-1822
/// See: https://eips.ethereum.org/EIPS/eip-1967
abstract contract ProxiableProtocolFeeReserveLib is ProtocolFeeProxyConstants {
    /// @dev Updates the target of the proxy to be the contract at _nextProtocolFeeReserveLib
    function __updateCodeAddress(address _nextProtocolFeeReserveLib) internal {
        require(
            ProxiableProtocolFeeReserveLib(_nextProtocolFeeReserveLib).proxiableUUID() ==
                bytes32(EIP_1822_PROXIABLE_UUID),
            "__updateCodeAddress: _nextProtocolFeeReserveLib not compatible"
        );
        assembly {
            sstore(EIP_1967_SLOT, _nextProtocolFeeReserveLib)
        }
    }

    /// @notice Returns a unique bytes32 hash for ProtocolFeeReserveLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return EIP_1822_PROXIABLE_UUID;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ProtocolFeeProxyConstants Contract
/// @author Enzyme Council <[email protected]>
/// @notice Constant values used in ProtocolFee proxy-related contracts
abstract contract ProtocolFeeProxyConstants {
    // `bytes32(keccak256('mln.proxiable.protocolFeeReserveLib'))`
    bytes32
        internal constant EIP_1822_PROXIABLE_UUID = 0xbc966524590ce702cc9340e80d86ea9095afa6b8eecbb5d6213f576332239181;
    // `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32
        internal constant EIP_1967_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ProtocolFeeProxyConstants.sol";
import "./utils/ProxiableProtocolFeeReserveLib.sol";

/// @title ProtocolFeeReserveProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for a protocol fee reserve, slightly modified from EIP-1822
/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// See: https://eips.ethereum.org/EIPS/eip-1822
/// See: https://eips.ethereum.org/EIPS/eip-1967
contract ProtocolFeeReserveProxy is ProtocolFeeProxyConstants {
    constructor(bytes memory _constructData, address _protocolFeeReserveLib) public {
        // Validate constants
        require(
            EIP_1822_PROXIABLE_UUID == bytes32(keccak256("mln.proxiable.protocolFeeReserveLib")),
            "constructor: Invalid EIP_1822_PROXIABLE_UUID"
        );
        require(
            EIP_1967_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1),
            "constructor: Invalid EIP_1967_SLOT"
        );

        require(
            ProxiableProtocolFeeReserveLib(_protocolFeeReserveLib).proxiableUUID() ==
                EIP_1822_PROXIABLE_UUID,
            "constructor: _protocolFeeReserveLib not compatible"
        );

        assembly {
            sstore(EIP_1967_SLOT, _protocolFeeReserveLib)
        }

        (bool success, bytes memory returnData) = _protocolFeeReserveLib.delegatecall(
            _constructData
        );
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            let contractLogic := sload(EIP_1967_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./ProtocolFeeReserveLibBaseCore.sol";

/// @title ProtocolFeeReserveLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base implementation for ProtocolFeeReserveLib
/// @dev Each next base implementation inherits the previous base implementation,
/// e.g., `ProtocolFeeReserveLibBase2 is ProtocolFeeReserveLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract ProtocolFeeReserveLibBase1 is ProtocolFeeReserveLibBaseCore {
    event SharesBoughtBack(
        address indexed vaultProxy,
        uint256 sharesAmount,
        uint256 mlnValue,
        uint256 mlnBurned
    );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./bases/ProtocolFeeReserveLibBase1.sol";
import "./interfaces/IProtocolFeeReserve1.sol";

/// @title ProtocolFeeReserveLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The proxiable library contract for ProtocolFeeReserveProxy
contract ProtocolFeeReserveLib is IProtocolFeeReserve1, ProtocolFeeReserveLibBase1 {
    using SafeMath for uint256;

    // Equates to a 50% discount
    uint256 private constant BUYBACK_DISCOUNT_DIVISOR = 2;

    /// @notice Indicates that the calling VaultProxy is buying back shares collected as protocol fee,
    /// and returns the amount of MLN that should be burned for the buyback
    /// @param _sharesAmount The amount of shares to buy back
    /// @param _mlnValue The MLN-denominated market value of _sharesAmount
    /// @return mlnAmountToBurn_ The amount of MLN to burn
    /// @dev Since VaultProxy instances are completely trusted, all the work of calculating and
    /// burning the appropriate amount of shares and MLN can be done by the calling VaultProxy.
    /// This contract only needs to provide the discounted MLN amount to burn.
    /// Though it is currently unused, passing in GAV would allow creating a tiered system of
    /// discounts in a new library, for example.
    function buyBackSharesViaTrustedVaultProxy(
        uint256 _sharesAmount,
        uint256 _mlnValue,
        uint256
    ) external override returns (uint256 mlnAmountToBurn_) {
        mlnAmountToBurn_ = _mlnValue.div(BUYBACK_DISCOUNT_DIVISOR);

        if (mlnAmountToBurn_ == 0) {
            return 0;
        }

        emit SharesBoughtBack(msg.sender, _sharesAmount, _mlnValue, mlnAmountToBurn_);

        return mlnAmountToBurn_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../utils/ProxiableGlobalConfigLib.sol";

/// @title GlobalConfigLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core implementation of GlobalConfigLib
/// @dev To be inherited by the first GlobalConfigLibBase implementation only.
/// DO NOT EDIT CONTRACT.
abstract contract GlobalConfigLibBaseCore is ProxiableGlobalConfigLib {
    event GlobalConfigLibSet(address nextGlobalConfigLib);

    address internal dispatcher;

    modifier onlyDispatcherOwner {
        require(
            msg.sender == IDispatcher(dispatcher).getOwner(),
            "Only the Dispatcher owner can call this function"
        );

        _;
    }

    /// @notice Initializes the GlobalConfigProxy with core configuration
    /// @param _dispatcher The Dispatcher contract
    /// @dev Serves as a pseudo-constructor
    function init(address _dispatcher) external {
        require(dispatcher == address(0), "init: Proxy already initialized");

        dispatcher = _dispatcher;

        emit GlobalConfigLibSet(getGlobalConfigLib());
    }

    /// @notice Gets the GlobalConfigLib target for the GlobalConfigProxy
    /// @return globalConfigLib_ The address of the GlobalConfigLib target
    function getGlobalConfigLib() public view returns (address globalConfigLib_) {
        assembly {
            globalConfigLib_ := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
        }

        return globalConfigLib_;
    }

    /// @notice Sets the GlobalConfigLib target for the GlobalConfigProxy
    /// @param _nextGlobalConfigLib The address to set as the GlobalConfigLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextGlobalConfigLib from being the same as the current GlobalConfigLib
    function setGlobalConfigLib(address _nextGlobalConfigLib) external onlyDispatcherOwner {
        __updateCodeAddress(_nextGlobalConfigLib);

        emit GlobalConfigLibSet(_nextGlobalConfigLib);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ProxiableGlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for GlobalConfigLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// Code position in storage is `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`,
/// which is "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc".
abstract contract ProxiableGlobalConfigLib {
    /// @dev Updates the target of the proxy to be the contract at _nextGlobalConfigLib
    function __updateCodeAddress(address _nextGlobalConfigLib) internal {
        require(
            bytes32(0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c) ==
                ProxiableGlobalConfigLib(_nextGlobalConfigLib).proxiableUUID(),
            "__updateCodeAddress: _nextGlobalConfigLib not compatible"
        );
        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _nextGlobalConfigLib
            )
        }
    }

    /// @notice Returns a unique bytes32 hash for GlobalConfigLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    /// @dev The UUID is `bytes32(keccak256('mln.proxiable.globalConfigLib'))`
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return 0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./bases/GlobalConfigLibBaseCore.sol";

/// @title GlobalConfigLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The proxiable library contract for GlobalConfigProxy
contract GlobalConfigLib is GlobalConfigLibBaseCore {
    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `dispatcher` variable
    /// @return dispatcher_ The `dispatcher` variable value
    function getDispatcher() external view returns (address dispatcher_) {
        return dispatcher;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ProxiableGlobalConfigLib.sol";

/// @title GlobalConfigProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for global configuration, slightly modified from EIP-1822
/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// i.e., `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`, which is
/// "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
/// See: https://eips.ethereum.org/EIPS/eip-1822
contract GlobalConfigProxy {
    constructor(bytes memory _constructData, address _globalConfigLib) public {
        // "0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c" corresponds to
        // `bytes32(keccak256('mln.proxiable.globalConfigLib'))`
        require(
            bytes32(0xf25d88d51901d7fabc9924b03f4c2fe4300e6fe1aae4b5134c0a90b68cd8e81c) ==
                ProxiableGlobalConfigLib(_globalConfigLib).proxiableUUID(),
            "constructor: _globalConfigLib not compatible"
        );

        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _globalConfigLib
            )
        }

        (bool success, bytes memory returnData) = _globalConfigLib.delegatecall(_constructData);
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            let contractLogic := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../vault/interfaces/IMigratableVault.sol";
import "../vault/VaultProxy.sol";
import "./IDispatcher.sol";
import "./IMigrationHookHandler.sol";

/// @title Dispatcher Contract
/// @author Enzyme Council <[email protected]>
/// @notice The top-level contract linking multiple releases.
/// It handles the deployment of new VaultProxy instances,
/// and the regulation of fund migration from a previous release to the current one.
/// It can also be referred to for access-control based on this contract's owner.
/// @dev DO NOT EDIT CONTRACT
contract Dispatcher is IDispatcher {
    event CurrentFundDeployerSet(address prevFundDeployer, address nextFundDeployer);

    event MigrationCancelled(
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib,
        uint256 executableTimestamp
    );

    event MigrationExecuted(
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib,
        uint256 executableTimestamp
    );

    event MigrationSignaled(
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib,
        uint256 executableTimestamp
    );

    event MigrationTimelockSet(uint256 prevTimelock, uint256 nextTimelock);

    event NominatedOwnerSet(address indexed nominatedOwner);

    event NominatedOwnerRemoved(address indexed nominatedOwner);

    event OwnershipTransferred(address indexed prevOwner, address indexed nextOwner);

    event MigrationInCancelHookFailed(
        bytes failureReturnData,
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib
    );

    event MigrationOutHookFailed(
        bytes failureReturnData,
        IMigrationHookHandler.MigrationOutHook hook,
        address indexed vaultProxy,
        address indexed prevFundDeployer,
        address indexed nextFundDeployer,
        address nextVaultAccessor,
        address nextVaultLib
    );

    event SharesTokenSymbolSet(string _nextSymbol);

    event VaultProxyDeployed(
        address indexed fundDeployer,
        address indexed owner,
        address vaultProxy,
        address indexed vaultLib,
        address vaultAccessor,
        string fundName
    );

    struct MigrationRequest {
        address nextFundDeployer;
        address nextVaultAccessor;
        address nextVaultLib;
        uint256 executableTimestamp;
    }

    address private currentFundDeployer;
    address private nominatedOwner;
    address private owner;
    uint256 private migrationTimelock;
    string private sharesTokenSymbol;
    mapping(address => address) private vaultProxyToFundDeployer;
    mapping(address => MigrationRequest) private vaultProxyToMigrationRequest;

    modifier onlyCurrentFundDeployer() {
        require(
            msg.sender == currentFundDeployer,
            "Only the current FundDeployer can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() public {
        migrationTimelock = 2 days;
        owner = msg.sender;
        sharesTokenSymbol = "ENZF";
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Sets a new `symbol` value for VaultProxy instances
    /// @param _nextSymbol The symbol value to set
    function setSharesTokenSymbol(string calldata _nextSymbol) external override onlyOwner {
        sharesTokenSymbol = _nextSymbol;

        emit SharesTokenSymbolSet(_nextSymbol);
    }

    ////////////////////
    // ACCESS CONTROL //
    ////////////////////

    /// @notice Claim ownership of the contract
    function claimOwnership() external override {
        address nextOwner = nominatedOwner;
        require(
            msg.sender == nextOwner,
            "claimOwnership: Only the nominatedOwner can call this function"
        );

        delete nominatedOwner;

        address prevOwner = owner;
        owner = nextOwner;

        emit OwnershipTransferred(prevOwner, nextOwner);
    }

    /// @notice Revoke the nomination of a new contract owner
    function removeNominatedOwner() external override onlyOwner {
        address removedNominatedOwner = nominatedOwner;
        require(
            removedNominatedOwner != address(0),
            "removeNominatedOwner: There is no nominated owner"
        );

        delete nominatedOwner;

        emit NominatedOwnerRemoved(removedNominatedOwner);
    }

    /// @notice Set a new FundDeployer for use within the contract
    /// @param _nextFundDeployer The address of the FundDeployer contract
    function setCurrentFundDeployer(address _nextFundDeployer) external override onlyOwner {
        require(
            _nextFundDeployer != address(0),
            "setCurrentFundDeployer: _nextFundDeployer cannot be empty"
        );
        require(
            __isContract(_nextFundDeployer),
            "setCurrentFundDeployer: Non-contract _nextFundDeployer"
        );

        address prevFundDeployer = currentFundDeployer;
        require(
            _nextFundDeployer != prevFundDeployer,
            "setCurrentFundDeployer: _nextFundDeployer is already currentFundDeployer"
        );

        currentFundDeployer = _nextFundDeployer;

        emit CurrentFundDeployerSet(prevFundDeployer, _nextFundDeployer);
    }

    /// @notice Nominate a new contract owner
    /// @param _nextNominatedOwner The account to nominate
    /// @dev Does not prohibit overwriting the current nominatedOwner
    function setNominatedOwner(address _nextNominatedOwner) external override onlyOwner {
        require(
            _nextNominatedOwner != address(0),
            "setNominatedOwner: _nextNominatedOwner cannot be empty"
        );
        require(
            _nextNominatedOwner != owner,
            "setNominatedOwner: _nextNominatedOwner is already the owner"
        );
        require(
            _nextNominatedOwner != nominatedOwner,
            "setNominatedOwner: _nextNominatedOwner is already nominated"
        );

        nominatedOwner = _nextNominatedOwner;

        emit NominatedOwnerSet(_nextNominatedOwner);
    }

    /// @dev Helper to check whether an address is a deployed contract
    function __isContract(address _who) private view returns (bool isContract_) {
        uint256 size;
        assembly {
            size := extcodesize(_who)
        }

        return size > 0;
    }

    ////////////////
    // DEPLOYMENT //
    ////////////////

    /// @notice Deploys a VaultProxy
    /// @param _vaultLib The VaultLib library with which to instantiate the VaultProxy
    /// @param _owner The account to set as the VaultProxy's owner
    /// @param _vaultAccessor The account to set as the VaultProxy's permissioned accessor
    /// @param _fundName The name of the fund
    /// @dev Input validation should be handled by the VaultProxy during deployment
    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external override onlyCurrentFundDeployer returns (address vaultProxy_) {
        require(__isContract(_vaultAccessor), "deployVaultProxy: Non-contract _vaultAccessor");

        bytes memory constructData = abi.encodeWithSelector(
            IMigratableVault.init.selector,
            _owner,
            _vaultAccessor,
            _fundName
        );
        vaultProxy_ = address(new VaultProxy(constructData, _vaultLib));

        address fundDeployer = msg.sender;
        vaultProxyToFundDeployer[vaultProxy_] = fundDeployer;

        emit VaultProxyDeployed(
            fundDeployer,
            _owner,
            vaultProxy_,
            _vaultLib,
            _vaultAccessor,
            _fundName
        );

        return vaultProxy_;
    }

    ////////////////
    // MIGRATIONS //
    ////////////////

    /// @notice Cancels a pending migration request
    /// @param _vaultProxy The VaultProxy contract for which to cancel the migration request
    /// @param _bypassFailure True if a failure in either migration hook should be ignored
    /// @dev Because this function must also be callable by a permissioned migrator, it has an
    /// extra migration hook to the nextFundDeployer for the case where cancelMigration()
    /// is called directly (rather than via the nextFundDeployer).
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external override {
        MigrationRequest memory request = vaultProxyToMigrationRequest[_vaultProxy];
        address nextFundDeployer = request.nextFundDeployer;
        require(nextFundDeployer != address(0), "cancelMigration: No migration request exists");

        // TODO: confirm that if canMigrate() does not exist but the caller is a valid FundDeployer, this still works.
        require(
            msg.sender == nextFundDeployer || IMigratableVault(_vaultProxy).canMigrate(msg.sender),
            "cancelMigration: Not an allowed caller"
        );

        address prevFundDeployer = vaultProxyToFundDeployer[_vaultProxy];
        address nextVaultAccessor = request.nextVaultAccessor;
        address nextVaultLib = request.nextVaultLib;
        uint256 executableTimestamp = request.executableTimestamp;

        delete vaultProxyToMigrationRequest[_vaultProxy];

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PostCancel,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );
        __invokeMigrationInCancelHook(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );

        emit MigrationCancelled(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            executableTimestamp
        );
    }

    /// @notice Executes a pending migration request
    /// @param _vaultProxy The VaultProxy contract for which to execute the migration request
    /// @param _bypassFailure True if a failure in either migration hook should be ignored
    function executeMigration(address _vaultProxy, bool _bypassFailure) external override {
        MigrationRequest memory request = vaultProxyToMigrationRequest[_vaultProxy];
        address nextFundDeployer = request.nextFundDeployer;
        require(
            nextFundDeployer != address(0),
            "executeMigration: No migration request exists for _vaultProxy"
        );
        require(
            msg.sender == nextFundDeployer,
            "executeMigration: Only the target FundDeployer can call this function"
        );
        require(
            nextFundDeployer == currentFundDeployer,
            "executeMigration: The target FundDeployer is no longer the current FundDeployer"
        );
        uint256 executableTimestamp = request.executableTimestamp;
        require(
            block.timestamp >= executableTimestamp,
            "executeMigration: The migration timelock has not elapsed"
        );

        address prevFundDeployer = vaultProxyToFundDeployer[_vaultProxy];
        address nextVaultAccessor = request.nextVaultAccessor;
        address nextVaultLib = request.nextVaultLib;

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PreMigrate,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );

        // Upgrade the VaultProxy to a new VaultLib and update the accessor via the new VaultLib
        IMigratableVault(_vaultProxy).setVaultLib(nextVaultLib);
        IMigratableVault(_vaultProxy).setAccessor(nextVaultAccessor);

        // Update the FundDeployer that migrated the VaultProxy
        vaultProxyToFundDeployer[_vaultProxy] = nextFundDeployer;

        // Remove the migration request
        delete vaultProxyToMigrationRequest[_vaultProxy];

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PostMigrate,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            _bypassFailure
        );

        emit MigrationExecuted(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            nextVaultAccessor,
            nextVaultLib,
            executableTimestamp
        );
    }

    /// @notice Sets a new migration timelock
    /// @param _nextTimelock The number of seconds for the new timelock
    function setMigrationTimelock(uint256 _nextTimelock) external override onlyOwner {
        uint256 prevTimelock = migrationTimelock;
        require(
            _nextTimelock != prevTimelock,
            "setMigrationTimelock: _nextTimelock is the current timelock"
        );

        migrationTimelock = _nextTimelock;

        emit MigrationTimelockSet(prevTimelock, _nextTimelock);
    }

    /// @notice Signals a migration by creating a migration request
    /// @param _vaultProxy The VaultProxy contract for which to signal migration
    /// @param _nextVaultAccessor The account that will be the next `accessor` on the VaultProxy
    /// @param _nextVaultLib The next VaultLib library contract address to set on the VaultProxy
    /// @param _bypassFailure True if a failure in either migration hook should be ignored
    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external override onlyCurrentFundDeployer {
        require(
            __isContract(_nextVaultAccessor),
            "signalMigration: Non-contract _nextVaultAccessor"
        );

        address prevFundDeployer = vaultProxyToFundDeployer[_vaultProxy];
        require(prevFundDeployer != address(0), "signalMigration: _vaultProxy does not exist");

        address nextFundDeployer = msg.sender;
        require(
            nextFundDeployer != prevFundDeployer,
            "signalMigration: Can only migrate to a new FundDeployer"
        );

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PreSignal,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            _nextVaultAccessor,
            _nextVaultLib,
            _bypassFailure
        );

        uint256 executableTimestamp = block.timestamp + migrationTimelock;
        vaultProxyToMigrationRequest[_vaultProxy] = MigrationRequest({
            nextFundDeployer: nextFundDeployer,
            nextVaultAccessor: _nextVaultAccessor,
            nextVaultLib: _nextVaultLib,
            executableTimestamp: executableTimestamp
        });

        __invokeMigrationOutHook(
            IMigrationHookHandler.MigrationOutHook.PostSignal,
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            _nextVaultAccessor,
            _nextVaultLib,
            _bypassFailure
        );

        emit MigrationSignaled(
            _vaultProxy,
            prevFundDeployer,
            nextFundDeployer,
            _nextVaultAccessor,
            _nextVaultLib,
            executableTimestamp
        );
    }

    /// @dev Helper to invoke a MigrationInCancelHook on the next FundDeployer being "migrated in" to,
    /// which can optionally be implemented on the FundDeployer
    function __invokeMigrationInCancelHook(
        address _vaultProxy,
        address _prevFundDeployer,
        address _nextFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) private {
        (bool success, bytes memory returnData) = _nextFundDeployer.call(
            abi.encodeWithSelector(
                IMigrationHookHandler.invokeMigrationInCancelHook.selector,
                _vaultProxy,
                _prevFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            )
        );
        if (!success) {
            require(
                _bypassFailure,
                string(abi.encodePacked("MigrationOutCancelHook: ", returnData))
            );

            emit MigrationInCancelHookFailed(
                returnData,
                _vaultProxy,
                _prevFundDeployer,
                _nextFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            );
        }
    }

    /// @dev Helper to invoke a IMigrationHookHandler.MigrationOutHook on the previous FundDeployer being "migrated out" of,
    /// which can optionally be implemented on the FundDeployer
    function __invokeMigrationOutHook(
        IMigrationHookHandler.MigrationOutHook _hook,
        address _vaultProxy,
        address _prevFundDeployer,
        address _nextFundDeployer,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) private {
        (bool success, bytes memory returnData) = _prevFundDeployer.call(
            abi.encodeWithSelector(
                IMigrationHookHandler.invokeMigrationOutHook.selector,
                _hook,
                _vaultProxy,
                _nextFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            )
        );
        if (!success) {
            require(
                _bypassFailure,
                string(abi.encodePacked(__migrationOutHookFailureReasonPrefix(_hook), returnData))
            );

            emit MigrationOutHookFailed(
                returnData,
                _hook,
                _vaultProxy,
                _prevFundDeployer,
                _nextFundDeployer,
                _nextVaultAccessor,
                _nextVaultLib
            );
        }
    }

    /// @dev Helper to return a revert reason string prefix for a given MigrationOutHook
    function __migrationOutHookFailureReasonPrefix(IMigrationHookHandler.MigrationOutHook _hook)
        private
        pure
        returns (string memory failureReasonPrefix_)
    {
        if (_hook == IMigrationHookHandler.MigrationOutHook.PreSignal) {
            return "MigrationOutHook.PreSignal: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PostSignal) {
            return "MigrationOutHook.PostSignal: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PreMigrate) {
            return "MigrationOutHook.PreMigrate: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PostMigrate) {
            return "MigrationOutHook.PostMigrate: ";
        }
        if (_hook == IMigrationHookHandler.MigrationOutHook.PostCancel) {
            return "MigrationOutHook.PostCancel: ";
        }

        return "";
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // Provides several potentially helpful getters that are not strictly necessary

    /// @notice Gets the current FundDeployer that is allowed to deploy and migrate funds
    /// @return currentFundDeployer_ The current FundDeployer contract address
    function getCurrentFundDeployer()
        external
        view
        override
        returns (address currentFundDeployer_)
    {
        return currentFundDeployer;
    }

    /// @notice Gets the FundDeployer with which a given VaultProxy is associated
    /// @param _vaultProxy The VaultProxy instance
    /// @return fundDeployer_ The FundDeployer contract address
    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        override
        returns (address fundDeployer_)
    {
        return vaultProxyToFundDeployer[_vaultProxy];
    }

    /// @notice Gets the details of a pending migration request for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return nextFundDeployer_ The FundDeployer contract address from which the migration
    /// request was made
    /// @return nextVaultAccessor_ The account that will be the next `accessor` on the VaultProxy
    /// @return nextVaultLib_ The next VaultLib library contract address to set on the VaultProxy
    /// @return executableTimestamp_ The timestamp at which the migration request can be executed
    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        override
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        )
    {
        MigrationRequest memory r = vaultProxyToMigrationRequest[_vaultProxy];
        if (r.executableTimestamp > 0) {
            return (
                r.nextFundDeployer,
                r.nextVaultAccessor,
                r.nextVaultLib,
                r.executableTimestamp
            );
        }
    }

    /// @notice Gets the amount of time that must pass between signaling and executing a migration
    /// @return migrationTimelock_ The timelock value (in seconds)
    function getMigrationTimelock() external view override returns (uint256 migrationTimelock_) {
        return migrationTimelock;
    }

    /// @notice Gets the account that is nominated to be the next owner of this contract
    /// @return nominatedOwner_ The account that is nominated to be the owner
    function getNominatedOwner() external view override returns (address nominatedOwner_) {
        return nominatedOwner;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The account that is the owner
    function getOwner() external view override returns (address owner_) {
        return owner;
    }

    /// @notice Gets the shares token `symbol` value for use in VaultProxy instances
    /// @return sharesTokenSymbol_ The `symbol` value
    function getSharesTokenSymbol()
        external
        view
        override
        returns (string memory sharesTokenSymbol_)
    {
        return sharesTokenSymbol;
    }

    /// @notice Gets the time remaining until the migration request of a given VaultProxy can be executed
    /// @param _vaultProxy The VaultProxy instance
    /// @return secondsRemaining_ The number of seconds remaining on the timelock
    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        override
        returns (uint256 secondsRemaining_)
    {
        uint256 executableTimestamp = vaultProxyToMigrationRequest[_vaultProxy]
            .executableTimestamp;
        if (executableTimestamp == 0) {
            return 0;
        }

        if (block.timestamp >= executableTimestamp) {
            return 0;
        }

        return executableTimestamp - block.timestamp;
    }

    /// @notice Checks whether a migration request that is executable exists for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return hasExecutableRequest_ True if a migration request exists and is executable
    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        override
        returns (bool hasExecutableRequest_)
    {
        uint256 executableTimestamp = vaultProxyToMigrationRequest[_vaultProxy]
            .executableTimestamp;

        return executableTimestamp > 0 && block.timestamp >= executableTimestamp;
    }

    /// @notice Checks whether a migration request exists for a given VaultProxy
    /// @param _vaultProxy The VaultProxy instance
    /// @return hasMigrationRequest_ True if a migration request exists
    function hasMigrationRequest(address _vaultProxy)
        external
        view
        override
        returns (bool hasMigrationRequest_)
    {
        return vaultProxyToMigrationRequest[_vaultProxy].executableTimestamp > 0;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ProxiableVaultLib.sol";

/// @title VaultProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all VaultProxy instances, slightly modified from EIP-1822
/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// i.e., `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`, which is
/// "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
/// See: https://eips.ethereum.org/EIPS/eip-1822
contract VaultProxy {
    constructor(bytes memory _constructData, address _vaultLib) public {
        // "0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5" corresponds to
        // `bytes32(keccak256('mln.proxiable.vaultlib'))`
        require(
            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==
                ProxiableVaultLib(_vaultLib).proxiableUUID(),
            "constructor: _vaultLib not compatible"
        );

        assembly {
            // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _vaultLib)
        }

        (bool success, bytes memory returnData) = _vaultLib.delegatecall(_constructData); // solium-disable-line
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../persistent/vault/VaultLibBaseCore.sol";

/// @title MockVaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mock VaultLib implementation that only extends VaultLibBaseCore
contract MockVaultLib is VaultLibBaseCore {
    function getAccessor() external view returns (address) {
        return accessor;
    }

    function getCreator() external view returns (address) {
        return creator;
    }

    function getMigrator() external view returns (address) {
        return migrator;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/extensions/external-position-manager/external-positions/IExternalPositionParser.sol";

/// @title MockGenericExternalPositionParser Contract
/// @author Enzyme Council <[email protected]>
/// @notice Provides a generic external position parser to be used on tests
contract MockGenericExternalPositionParser is IExternalPositionParser {
    struct AssetsForAction {
        address[] assetsToTransfer;
        uint256[] amountsToTransfer;
        address[] assetsToReceive;
    }

    bytes private initArgs;

    mapping(uint256 => AssetsForAction) private actionIdToAssetsForAction;

    /// @dev Returns the default assetsForAction stored for a given actionID
    function parseAssetsForAction(uint256 _actionId, bytes memory)
        external
        override
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        )
    {
        AssetsForAction memory assetsForAction = actionIdToAssetsForAction[_actionId];
        return (
            assetsForAction.assetsToTransfer,
            assetsForAction.amountsToTransfer,
            assetsForAction.assetsToReceive
        );
    }

    /// @dev Sets the assets for action for a given actionId
    function setAssetsForAction(
        uint256 actionId,
        address[] memory _assetsToTransfer,
        uint256[] memory _amountsToTransfer,
        address[] memory _assetsToReceive
    ) external {
        actionIdToAssetsForAction[actionId] = AssetsForAction({
            assetsToTransfer: _assetsToTransfer,
            amountsToTransfer: _amountsToTransfer,
            assetsToReceive: _assetsToReceive
        });
    }

    /// @dev Sets the initArgs variable
    function setInitArgs(bytes memory _initArgs) external {
        initArgs = _initArgs;
    }

    /// @dev Sets the initArgs variable
    function parseInitArgs(address, bytes memory)
        external
        override
        returns (bytes memory initArgs_)
    {
        return initArgs;
    }

    /// @dev Returns the initArgs variable
    function getInitArgs() public view returns (bytes memory initArgs_) {
        return initArgs;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../infrastructure/price-feeds/derivatives/feeds/CompoundPriceFeed.sol";
import "../utils/actions/CompoundActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title CompoundAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Compound <https://compound.finance/>
contract CompoundAdapter is AdapterBase, CompoundActionsMixin {
    address private immutable COMPOUND_PRICE_FEED;

    constructor(
        address _integrationManager,
        address _compoundPriceFeed,
        address _wethToken
    ) public AdapterBase(_integrationManager) CompoundActionsMixin(_wethToken) {
        COMPOUND_PRICE_FEED = _compoundPriceFeed;
    }

    /// @dev Needed to receive ETH during cEther lend/redeem
    receive() external payable {}

    /// @notice Lends an amount of a token to Compound
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        // More efficient to parse all from _assetData
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __compoundLend(spendAssets[0], spendAssetAmounts[0], incomingAssets[0]);
    }

    /// @notice Redeems an amount of cTokens from Compound
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionIncomingAssetsTransferHandler(_vaultProxy, _assetData)
    {
        // More efficient to parse all from _assetData
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __compoundRedeem(spendAssets[0], spendAssetAmounts[0], incomingAssets[0]);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address cToken, uint256 tokenAmount, uint256 minCTokenAmount) = __decodeCallArgs(
            _actionData
        );
        address token = CompoundPriceFeed(COMPOUND_PRICE_FEED).getTokenFromCToken(cToken);
        require(token != address(0), "__parseAssetsForLend: Unsupported cToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = token;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = tokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = cToken;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minCTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address cToken, uint256 cTokenAmount, uint256 minTokenAmount) = __decodeCallArgs(
            _actionData
        );
        address token = CompoundPriceFeed(COMPOUND_PRICE_FEED).getTokenFromCToken(cToken);
        require(token != address(0), "__parseAssetsForRedeem: Unsupported cToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = cToken;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = cTokenAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = token;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minTokenAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address cToken_,
            uint256 outgoingAssetAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (address, uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `COMPOUND_PRICE_FEED` variable
    /// @return compoundPriceFeed_ The `COMPOUND_PRICE_FEED` variable value
    function getCompoundPriceFeed() external view returns (address compoundPriceFeed_) {
        return COMPOUND_PRICE_FEED;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/ICERC20.sol";
import "../../../../../interfaces/ICEther.sol";
import "../../../../../interfaces/IWETH.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title CompoundActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Compound lending functions
/// @dev Inheriting contract must have a receive() function
abstract contract CompoundActionsMixin is AssetHelpers {
    address private immutable COMPOUND_WETH_TOKEN;

    constructor(address _wethToken) public {
        COMPOUND_WETH_TOKEN = _wethToken;
    }

    /// @dev Helper to execute lending
    function __compoundLend(
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        address _incomingAsset
    ) internal {
        if (_outgoingAsset == COMPOUND_WETH_TOKEN) {
            IWETH(COMPOUND_WETH_TOKEN).withdraw(_outgoingAssetAmount);
            ICEther(_incomingAsset).mint{value: _outgoingAssetAmount}();
        } else {
            __approveAssetMaxAsNeeded(_outgoingAsset, _incomingAsset, _outgoingAssetAmount);
            ICERC20(_incomingAsset).mint(_outgoingAssetAmount);
        }
    }

    /// @dev Helper to execute redeeming
    function __compoundRedeem(
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        address _incomingAsset
    ) internal {
        ICERC20(_outgoingAsset).redeem(_outgoingAssetAmount);

        if (_incomingAsset == COMPOUND_WETH_TOKEN) {
            IWETH(payable(COMPOUND_WETH_TOKEN)).deposit{value: payable(address(this)).balance}();
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `COMPOUND_WETH_TOKEN` variable
    /// @return compoundWethToken_ The `COMPOUND_WETH_TOKEN` variable value
    function getCompoundWethToken() public view returns (address compoundWethToken_) {
        return COMPOUND_WETH_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../release/interfaces/ICurveSwapsEther.sol";
import "../../mocks/utils/EthConstantMixin.sol";
import "../utils/TreasuryEnabledMixin.sol";

/// @title Curve Exchange Testnet
/// @author Enzyme Council <[email protected]>
/// @notice Curve Exchange Testnet
contract TestnetCurveExchange is ICurveSwapsEther, EthConstantMixin, TreasuryEnabledMixin {
    constructor(address _treasury) public TreasuryEnabledMixin(_treasury) {}

    function exchange(
        address,
        address _outgoingAsset,
        address _incomingAsset,
        uint256 _outgoingAssetAmount,
        uint256 _minIncomingAssetAmount,
        address _recipient
    ) external payable override returns (uint256) {
        if (_outgoingAsset != ETH_ADDRESS) {
            TREASURY.burnFrom(_outgoingAsset, msg.sender, _outgoingAssetAmount);
        }

        // TODO: think the behaviour here should be sending WETH directly into the vault,
        // but there's a intermediate step of wrappig in the adapter
        if (_incomingAsset != ETH_ADDRESS) {
            TREASURY.mintFor(_incomingAsset, _recipient, _minIncomingAssetAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

abstract contract EthConstantMixin {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../release/interfaces/IZeroExV2.sol";
import "../utils/TreasuryEnabledMixin.sol";

/// @title ZeroEx v2 Testnet
/// @author Enzyme Council <[email protected]>
/// @notice ZeroEx v2 Testnet
contract TestnetZeroExV2 is IZeroExV2, TreasuryEnabledMixin {
    constructor(address _treasury) public TreasuryEnabledMixin(_treasury) {}

    function fillOrder(
        Order calldata _order,
        uint256,
        bytes calldata
    ) external override returns (FillResults memory) {
        TREASURY.burnFrom(
            __getAssetAddress(_order.takerAssetData),
            msg.sender,
            _order.takerAssetAmount
        );
        TREASURY.mintFor(
            __getAssetAddress(_order.makerAssetData),
            _order.takerAddress,
            _order.makerAssetAmount
        );
    }

    // TODO: Implement this.
    function ZRX_ASSET_DATA() external view override returns (bytes memory) {
        revert("Not implemented");
    }

    // TODO: Implement this.
    function getAssetProxy(bytes4) external view override returns (address) {
        revert("Not implemented");
    }

    /// @dev Parses the asset address from 0x assetData
    function __getAssetAddress(bytes memory _assetData)
        internal
        pure
        returns (address assetAddress_)
    {
        assembly {
            assetAddress_ := mload(add(_assetData, 36))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../release/interfaces/IUniswapV3SwapRouter.sol";
import "../utils/TreasuryEnabledMixin.sol";

/// @title Uniswap v3 Testnet
/// @author Enzyme Council <[email protected]>
/// @notice Uniswap v3 Testnet
contract TestnetUniswapV3 is IUniswapV3SwapRouter, TreasuryEnabledMixin {
    constructor(address _treasury) public TreasuryEnabledMixin(_treasury) {}

    function exactInput(ExactInputParams calldata exact)
        external
        payable
        override
        returns (uint256)
    {
        TREASURY.burnFrom(
            abi.decode(abi.encodePacked(exact.path[0:20], bytes12(0)), (address)),
            msg.sender,
            exact.amountIn
        );
        TREASURY.mintFor(
            abi.decode(
                abi.encodePacked(exact.path[exact.path.length - 20:], bytes12(0)),
                (address)
            ),
            exact.recipient,
            exact.amountOutMinimum
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title IUniswapV3Router Interface
/// @author Enzyme Council <[email protected]>
/// @dev Minimal interface for our interactions with Uniswap V3's Router
interface IUniswapV3SwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../../../interfaces/IUniswapV3SwapRouter.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title UniswapV3ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with Uniswap v3
abstract contract UniswapV3ActionsMixin is AssetHelpers {
    address private immutable UNISWAP_V3_ROUTER;

    constructor(address _router) public {
        UNISWAP_V3_ROUTER = _router;
    }

    /// @dev Helper to execute a swap
    // UniswapV3 paths are packed encoded as (address(_pathAddresses[i]), uint24(_pathFees[i]), address(_pathAddresses[i + 1]), [...])
    // _pathFees[i] represents the fee for the pool between _pathAddresses(i) and _pathAddresses(i+1)
    function __uniswapV3Swap(
        address _recipient,
        address[] memory _pathAddresses,
        uint24[] memory _pathFees,
        uint256 _outgoingAssetAmount,
        uint256 _minIncomingAssetAmount
    ) internal {
        __approveAssetMaxAsNeeded(_pathAddresses[0], UNISWAP_V3_ROUTER, _outgoingAssetAmount);

        bytes memory encodedPath;

        for (uint256 i; i < _pathAddresses.length; i++) {
            if (i != _pathAddresses.length - 1) {
                encodedPath = abi.encodePacked(encodedPath, _pathAddresses[i], _pathFees[i]);
            } else {
                encodedPath = abi.encodePacked(encodedPath, _pathAddresses[i]);
            }
        }

        IUniswapV3SwapRouter.ExactInputParams memory input = IUniswapV3SwapRouter
            .ExactInputParams({
            path: encodedPath,
            recipient: _recipient,
            deadline: block.timestamp + 1,
            amountIn: _outgoingAssetAmount,
            amountOutMinimum: _minIncomingAssetAmount
        });

        // Execute fill
        IUniswapV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(input);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `UNISWAP_V3_ROUTER` variable
    /// @return router_ The `UNISWAP_V3_ROUTER` variable value
    function getUniswapV3Router() public view returns (address router_) {
        return UNISWAP_V3_ROUTER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/actions/UniswapV3ActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title UniswapV3SwapAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with UniswapV3 swaps
contract UniswapV3Adapter is AdapterBase, UniswapV3ActionsMixin {
    constructor(address _integrationManager, address _router)
        public
        AdapterBase(_integrationManager)
        UniswapV3ActionsMixin(_router)
    {}

    // EXTERNAL FUNCTIONS

    /// @notice Trades assets on UniswapV3
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function takeOrder(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address[] memory pathAddresses,
            uint24[] memory pathFees,
            uint256 outgoingAssetAmount,
            uint256 minIncomingAssetAmount
        ) = __decodeCallArgs(_actionData);

        __uniswapV3Swap(
            _vaultProxy,
            pathAddresses,
            pathFees,
            outgoingAssetAmount,
            minIncomingAssetAmount
        );
    }

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForAction: _selector invalid");

        (
            address[] memory pathAddresses,
            uint24[] memory pathFees,
            uint256 outgoingAssetAmount,
            uint256 minIncomingAssetAmount
        ) = __decodeCallArgs(_actionData);

        require(pathAddresses.length >= 2, "parseAssetsForAction: pathAddresses must be >= 2");
        require(
            pathAddresses.length == pathFees.length + 1,
            "parseAssetsForAction: incorrect pathAddresses or pathFees length"
        );

        spendAssets_ = new address[](1);
        spendAssets_[0] = pathAddresses[0];
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingAssetAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = pathAddresses[pathAddresses.length - 1];
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper to decode the encoded callOnIntegration call arguments
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address[] memory pathAddresses,
            uint24[] memory pathFees,
            uint256 outgoingAssetAmount,
            uint256 minIncomingAssetAmount
        )
    {
        return abi.decode(_actionData, (address[], uint24[], uint256, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/TreasuryEnabledMixin.sol";

/// @title Uniswap v2 Testnet
/// @author Enzyme Council <[email protected]>
/// @notice Uniswap v2 Testnet
contract TestnetUniswapV2 is TreasuryEnabledMixin {
    constructor(address _treasury) public TreasuryEnabledMixin(_treasury) {}

    function addLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {}

    function removeLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external returns (uint256, uint256) {}

    function swapExactTokensForTokens(
        uint256 _outgoingAmount,
        uint256 _incomingAmount,
        address[] calldata _path,
        address _recipient,
        uint256
    ) external returns (uint256[] memory) {
        TREASURY.burnFrom(_path[0], msg.sender, _outgoingAmount);
        TREASURY.mintFor(_path[_path.length - 1], _recipient, _incomingAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../release/interfaces/IParaSwapV4AugustusSwapper.sol";
import "../utils/TreasuryEnabledMixin.sol";

/// @title ParaSwap v4 Testnet
/// @author Enzyme Council <[email protected]>
/// @notice ParaSwap v4 Testnet
contract TestnetParaSwapV4 is IParaSwapV4AugustusSwapper, TreasuryEnabledMixin {
    constructor(address _treasury) public TreasuryEnabledMixin(_treasury) {}

    function multiSwap(SellData calldata sD) external payable override returns (uint256) {
        TREASURY.burnFrom(sD.fromToken, msg.sender, sD.fromAmount);
        TREASURY.mintFor(sD.path[sD.path.length - 1].to, sD.beneficiary, sD.expectedAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title ParaSwap V4 IAugustusSwapper interface
interface IParaSwapV4AugustusSwapper {
    struct Route {
        address payable exchange;
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;
        Route[] routes;
    }

    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Path[] path;
    }

    function multiSwap(SellData calldata) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IParaSwapV4AugustusSwapper.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title ParaSwapV4ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with ParaSwap (v4)
abstract contract ParaSwapV4ActionsMixin is AssetHelpers {
    string private constant REFERRER = "enzyme";

    address private immutable PARA_SWAP_V4_AUGUSTUS_SWAPPER;
    address private immutable PARA_SWAP_V4_TOKEN_TRANSFER_PROXY;

    constructor(address _augustusSwapper, address _tokenTransferProxy) public {
        PARA_SWAP_V4_AUGUSTUS_SWAPPER = _augustusSwapper;
        PARA_SWAP_V4_TOKEN_TRANSFER_PROXY = _tokenTransferProxy;
    }

    /// @dev Helper to execute a multiSwap() order
    function __paraSwapV4MultiSwap(
        address _fromToken,
        uint256 _fromAmount,
        uint256 _toAmount,
        uint256 _expectedAmount,
        address payable _beneficiary,
        IParaSwapV4AugustusSwapper.Path[] memory _path
    ) internal {
        __approveAssetMaxAsNeeded(_fromToken, PARA_SWAP_V4_TOKEN_TRANSFER_PROXY, _fromAmount);

        IParaSwapV4AugustusSwapper.SellData memory sellData = IParaSwapV4AugustusSwapper.SellData({
            fromToken: _fromToken,
            fromAmount: _fromAmount,
            toAmount: _toAmount,
            expectedAmount: _expectedAmount,
            beneficiary: _beneficiary,
            referrer: REFERRER,
            useReduxToken: false,
            path: _path
        });

        IParaSwapV4AugustusSwapper(PARA_SWAP_V4_AUGUSTUS_SWAPPER).multiSwap(sellData);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `PARA_SWAP_V4_AUGUSTUS_SWAPPER` variable
    /// @return augustusSwapper_ The `PARA_SWAP_V4_AUGUSTUS_SWAPPER` variable value
    function getParaSwapV4AugustusSwapper() public view returns (address augustusSwapper_) {
        return PARA_SWAP_V4_AUGUSTUS_SWAPPER;
    }

    /// @notice Gets the `PARA_SWAP_V4_TOKEN_TRANSFER_PROXY` variable
    /// @return tokenTransferProxy_ The `PARA_SWAP_V4_TOKEN_TRANSFER_PROXY` variable value
    function getParaSwapV4TokenTransferProxy() public view returns (address tokenTransferProxy_) {
        return PARA_SWAP_V4_TOKEN_TRANSFER_PROXY;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/actions/ParaSwapV4ActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title ParaSwapV4Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with ParaSwap (v4)
/// @dev Does not allow any protocol that collects protocol fees in ETH, e.g., 0x v3
contract ParaSwapV4Adapter is AdapterBase, ParaSwapV4ActionsMixin {
    constructor(
        address _integrationManager,
        address _augustusSwapper,
        address _tokenTransferProxy
    )
        public
        AdapterBase(_integrationManager)
        ParaSwapV4ActionsMixin(_augustusSwapper, _tokenTransferProxy)
    {}

    // EXTERNAL FUNCTIONS

    /// @notice Trades assets on ParaSwap
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @dev ParaSwap v4 completely uses entire outgoing asset balance and incoming asset
    /// is sent directly to the beneficiary (the _vaultProxy)
    function takeOrder(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            uint256 minIncomingAssetAmount,
            uint256 expectedIncomingAssetAmount,
            address outgoingAsset,
            uint256 outgoingAssetAmount,
            IParaSwapV4AugustusSwapper.Path[] memory paths
        ) = __decodeCallArgs(_actionData);

        __paraSwapV4MultiSwap(
            outgoingAsset,
            outgoingAssetAmount,
            minIncomingAssetAmount,
            expectedIncomingAssetAmount,
            payable(_vaultProxy),
            paths
        );
    }

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForAction: _selector invalid");

        (
            uint256 minIncomingAssetAmount,
            ,
            address outgoingAsset,
            uint256 outgoingAssetAmount,
            IParaSwapV4AugustusSwapper.Path[] memory paths
        ) = __decodeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = outgoingAsset;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingAssetAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = paths[paths.length - 1].to;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper to decode the encoded callOnIntegration call arguments
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 minIncomingAssetAmount_,
            uint256 expectedIncomingAssetAmount_, // Passed as a courtesy to ParaSwap for analytics
            address outgoingAsset_,
            uint256 outgoingAssetAmount_,
            IParaSwapV4AugustusSwapper.Path[] memory paths_
        )
    {
        return
            abi.decode(
                _actionData,
                (uint256, uint256, address, uint256, IParaSwapV4AugustusSwapper.Path[])
            );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./EthConstantMixin.sol";

abstract contract SwapperBase is EthConstantMixin {
    receive() external payable {}

    function __swapAssets(
        address payable _trader,
        address _srcToken,
        uint256 _srcAmount,
        address _destToken,
        uint256 _actualRate
    ) internal returns (uint256 destAmount_) {
        address[] memory assetsToIntegratee = new address[](1);
        assetsToIntegratee[0] = _srcToken;
        uint256[] memory assetsToIntegrateeAmounts = new uint256[](1);
        assetsToIntegrateeAmounts[0] = _srcAmount;

        address[] memory assetsFromIntegratee = new address[](1);
        assetsFromIntegratee[0] = _destToken;
        uint256[] memory assetsFromIntegrateeAmounts = new uint256[](1);
        assetsFromIntegrateeAmounts[0] = _actualRate;
        __swap(
            _trader,
            assetsToIntegratee,
            assetsToIntegrateeAmounts,
            assetsFromIntegratee,
            assetsFromIntegrateeAmounts
        );

        return assetsFromIntegrateeAmounts[0];
    }

    function __swap(
        address payable _trader,
        address[] memory _assetsToIntegratee,
        uint256[] memory _assetsToIntegrateeAmounts,
        address[] memory _assetsFromIntegratee,
        uint256[] memory _assetsFromIntegrateeAmounts
    ) internal {
        // Take custody of incoming assets
        for (uint256 i = 0; i < _assetsToIntegratee.length; i++) {
            address asset = _assetsToIntegratee[i];
            uint256 amount = _assetsToIntegrateeAmounts[i];
            require(asset != address(0), "__swap: empty value in _assetsToIntegratee");
            require(amount > 0, "__swap: empty value in _assetsToIntegrateeAmounts");
            // Incoming ETH amounts can be ignored
            if (asset == ETH_ADDRESS) {
                continue;
            }
            ERC20(asset).transferFrom(_trader, address(this), amount);
        }

        // Distribute outgoing assets
        for (uint256 i = 0; i < _assetsFromIntegratee.length; i++) {
            address asset = _assetsFromIntegratee[i];
            uint256 amount = _assetsFromIntegrateeAmounts[i];
            require(asset != address(0), "__swap: empty value in _assetsFromIntegratee");
            require(amount > 0, "__swap: empty value in _assetsFromIntegrateeAmounts");
            if (asset == ETH_ADDRESS) {
                _trader.transfer(amount);
            } else {
                ERC20(asset).transfer(_trader, amount);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/SwapperBase.sol";

contract MockGenericIntegratee is SwapperBase {
    function swap(
        address[] calldata _assetsToIntegratee,
        uint256[] calldata _assetsToIntegrateeAmounts,
        address[] calldata _assetsFromIntegratee,
        uint256[] calldata _assetsFromIntegrateeAmounts
    ) external payable {
        __swap(
            msg.sender,
            _assetsToIntegratee,
            _assetsToIntegrateeAmounts,
            _assetsFromIntegratee,
            _assetsFromIntegrateeAmounts
        );
    }

    function swapOnBehalf(
        address payable _trader,
        address[] calldata _assetsToIntegratee,
        uint256[] calldata _assetsToIntegrateeAmounts,
        address[] calldata _assetsFromIntegratee,
        uint256[] calldata _assetsFromIntegrateeAmounts
    ) external payable {
        __swap(
            _trader,
            _assetsToIntegratee,
            _assetsToIntegrateeAmounts,
            _assetsFromIntegratee,
            _assetsFromIntegrateeAmounts
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/actions/CurveExchangeActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title CurveExchangeAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for swapping assets on Curve <https://www.curve.fi/>
contract CurveExchangeAdapter is AdapterBase, CurveExchangeActionsMixin {
    constructor(
        address _integrationManager,
        address _addressProvider,
        address _wethToken
    )
        public
        AdapterBase(_integrationManager)
        CurveExchangeActionsMixin(_addressProvider, _wethToken)
    {}

    /// @dev Needed to receive ETH from swap and to unwrap WETH
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Trades assets on Curve
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function takeOrder(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address pool,
            address outgoingAsset,
            uint256 outgoingAssetAmount,
            address incomingAsset,
            uint256 minIncomingAssetAmount
        ) = __decodeCallArgs(_actionData);

        __curveTakeOrder(
            _vaultProxy,
            pool,
            outgoingAsset,
            outgoingAssetAmount,
            incomingAsset,
            minIncomingAssetAmount
        );
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForAction: _selector invalid");
        (
            address pool,
            address outgoingAsset,
            uint256 outgoingAssetAmount,
            address incomingAsset,
            uint256 minIncomingAssetAmount
        ) = __decodeCallArgs(_actionData);

        require(pool != address(0), "parseAssetsForAction: No pool address provided");

        spendAssets_ = new address[](1);
        spendAssets_[0] = outgoingAsset;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingAssetAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = incomingAsset;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the take order encoded call arguments
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address pool_,
            address outgoingAsset_,
            uint256 outgoingAssetAmount_,
            address incomingAsset_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (address, address, uint256, address, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../IDerivativePriceFeed.sol";
import "./SingleUnderlyingDerivativeRegistryMixin.sol";

/// @title PeggedDerivativesPriceFeedBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed base for multiple derivatives that are pegged 1:1 to their underlyings,
/// and have the same decimals as their underlying
abstract contract PeggedDerivativesPriceFeedBase is
    IDerivativePriceFeed,
    SingleUnderlyingDerivativeRegistryMixin
{
    constructor(address _fundDeployer)
        public
        SingleUnderlyingDerivativeRegistryMixin(_fundDeployer)
    {}

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address underlying = getUnderlyingForDerivative(_derivative);
        require(underlying != address(0), "calcUnderlyingValues: Not a supported derivative");

        underlyings_ = new address[](1);
        underlyings_[0] = underlying;

        underlyingAmounts_ = new uint256[](1);
        underlyingAmounts_[0] = _derivativeAmount;

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return getUnderlyingForDerivative(_asset) != address(0);
    }

    /// @dev Provides validation that the derivative and underlying have the same decimals.
    /// Can be overrode by the inheriting price feed using super() to implement further validation.
    function __validateDerivative(address _derivative, address _underlying)
        internal
        virtual
        override
    {
        require(
            ERC20(_derivative).decimals() == ERC20(_underlying).decimals(),
            "__validateDerivative: Unequal decimals"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/infrastructure/price-feeds/derivatives/feeds/utils/PeggedDerivativesPriceFeedBase.sol";

/// @title TestSingleUnderlyingDerivativeRegistry Contract
/// @author Enzyme Council <[email protected]>
/// @notice A test implementation of PeggedDerivativesPriceFeedBase
contract TestPeggedDerivativesPriceFeed is PeggedDerivativesPriceFeedBase {
    constructor(address _dispatcher) public PeggedDerivativesPriceFeedBase(_dispatcher) {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../interfaces/IAaveProtocolDataProvider.sol";
import "./utils/PeggedDerivativesPriceFeedBase.sol";

/// @title AavePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Aave
contract AavePriceFeed is PeggedDerivativesPriceFeedBase {
    address private immutable PROTOCOL_DATA_PROVIDER;

    constructor(address _fundDeployer, address _protocolDataProvider)
        public
        PeggedDerivativesPriceFeedBase(_fundDeployer)
    {
        PROTOCOL_DATA_PROVIDER = _protocolDataProvider;
    }

    function __validateDerivative(address _derivative, address _underlying) internal override {
        super.__validateDerivative(_derivative, _underlying);

        (address aTokenAddress, , ) = IAaveProtocolDataProvider(PROTOCOL_DATA_PROVIDER)
            .getReserveTokensAddresses(_underlying);

        require(
            aTokenAddress == _derivative,
            "__validateDerivative: Invalid aToken or token provided"
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `PROTOCOL_DATA_PROVIDER` variable value
    /// @return protocolDataProvider_ The `PROTOCOL_DATA_PROVIDER` variable value
    function getProtocolDataProvider() external view returns (address protocolDataProvider_) {
        return PROTOCOL_DATA_PROVIDER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveProtocolDataProvider interface
/// @author Enzyme Council <[email protected]>
interface IAaveProtocolDataProvider {
    function getReserveTokensAddresses(address)
        external
        view
        returns (
            address,
            address,
            address
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../infrastructure/price-feeds/derivatives/feeds/AavePriceFeed.sol";
import "../utils/actions/AaveActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title AaveAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Aave Lending <https://aave.com/>
/// @dev When lending and redeeming, a small `ROUNDING_BUFFER` is subtracted from the min incoming asset amount.
/// This is a workaround for problematic quirks in `aToken` balance rounding (due to RayMath and rebasing logic),
/// which would otherwise lead to tx failures during IntegrationManager validation of incoming asset amounts.
/// Due to this workaround, an `aToken` value less than `ROUNDING_BUFFER` is not usable in this adapter,
/// which is fine because those values would not make sense (gas-wise) to lend or redeem.
contract AaveAdapter is AdapterBase, AaveActionsMixin {
    using SafeMath for uint256;

    uint256 private constant ROUNDING_BUFFER = 2;

    address private immutable AAVE_PRICE_FEED;

    constructor(
        address _integrationManager,
        address _lendingPoolAddressProvider,
        address _aavePriceFeed
    ) public AdapterBase(_integrationManager) AaveActionsMixin(_lendingPoolAddressProvider) {
        AAVE_PRICE_FEED = _aavePriceFeed;
    }

    /// @notice Lends an amount of a token to AAVE
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function lend(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    ) external onlyIntegrationManager {
        (address[] memory spendAssets, uint256[] memory spendAssetAmounts, ) = __decodeAssetData(
            _assetData
        );

        __aaveLend(_vaultProxy, spendAssets[0], spendAssetAmounts[0]);
    }

    /// @notice Redeems an amount of aTokens from AAVE
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    ) external onlyIntegrationManager {
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __aaveRedeem(_vaultProxy, spendAssets[0], spendAssetAmounts[0], incomingAssets[0]);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address aToken, uint256 amount) = __decodeCallArgs(_actionData);

        // Prevent from invalid token/aToken combination
        address token = AavePriceFeed(AAVE_PRICE_FEED).getUnderlyingForDerivative(aToken);
        require(token != address(0), "__parseAssetsForLend: Unsupported aToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = token;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = amount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = aToken;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = amount.sub(ROUNDING_BUFFER);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (address aToken, uint256 amount) = __decodeCallArgs(_actionData);

        // Prevent from invalid token/aToken combination
        address token = AavePriceFeed(AAVE_PRICE_FEED).getUnderlyingForDerivative(aToken);
        require(token != address(0), "__parseAssetsForRedeem: Unsupported aToken");

        spendAssets_ = new address[](1);
        spendAssets_[0] = aToken;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = amount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = token;
        minIncomingAssetAmounts_ = new uint256[](1);
        // The `ROUNDING_BUFFER` is overly cautious in this case, but it comes at minimal expense
        minIncomingAssetAmounts_[0] = amount.sub(ROUNDING_BUFFER);

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (address aToken, uint256 amount)
    {
        return abi.decode(_actionData, (address, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `AAVE_PRICE_FEED` variable
    /// @return aavePriceFeed_ The `AAVE_PRICE_FEED` variable value
    function getAavePriceFeed() external view returns (address aavePriceFeed_) {
        return AAVE_PRICE_FEED;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IAaveLendingPool.sol";
import "../../../../../interfaces/IAaveLendingPoolAddressProvider.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title AaveActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Aave lending functions
abstract contract AaveActionsMixin is AssetHelpers {
    uint16 private constant AAVE_REFERRAL_CODE = 158;

    address private immutable AAVE_LENDING_POOL_ADDRESS_PROVIDER;

    constructor(address _lendingPoolAddressProvider) public {
        AAVE_LENDING_POOL_ADDRESS_PROVIDER = _lendingPoolAddressProvider;
    }

    /// @dev Helper to execute lending
    function __aaveLend(
        address _recipient,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount
    ) internal {
        address lendingPoolAddress = IAaveLendingPoolAddressProvider(
            AAVE_LENDING_POOL_ADDRESS_PROVIDER
        )
            .getLendingPool();

        __approveAssetMaxAsNeeded(_outgoingAsset, lendingPoolAddress, _outgoingAssetAmount);

        IAaveLendingPool(lendingPoolAddress).deposit(
            _outgoingAsset,
            _outgoingAssetAmount,
            _recipient,
            AAVE_REFERRAL_CODE
        );
    }

    /// @dev Helper to execute redeeming
    function __aaveRedeem(
        address _recipient,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        address _incomingAsset
    ) internal {
        address lendingPoolAddress = IAaveLendingPoolAddressProvider(
            AAVE_LENDING_POOL_ADDRESS_PROVIDER
        )
            .getLendingPool();

        __approveAssetMaxAsNeeded(_outgoingAsset, lendingPoolAddress, _outgoingAssetAmount);

        IAaveLendingPool(lendingPoolAddress).withdraw(
            _incomingAsset,
            _outgoingAssetAmount,
            _recipient
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `AAVE_LENDING_POOL_ADDRESS_PROVIDER` variable
    /// @return aaveLendingPoolAddressProvider_ The `AAVE_LENDING_POOL_ADDRESS_PROVIDER` variable value
    function getAaveLendingPoolAddressProvider()
        public
        view
        returns (address aaveLendingPoolAddressProvider_)
    {
        return AAVE_LENDING_POOL_ADDRESS_PROVIDER;
    }

    /// @notice Gets the `AAVE_REFERRAL_CODE` variable
    /// @return aaveReferralCode_ The `AAVE_REFERRAL_CODE` variable value
    function getAaveReferralCode() public pure returns (uint16 aaveReferralCode_) {
        return AAVE_REFERRAL_CODE;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveLendingPool interface
/// @author Enzyme Council <[email protected]>
interface IAaveLendingPool {
    function deposit(
        address,
        uint256,
        address,
        uint16
    ) external;

    function withdraw(
        address,
        uint256,
        address
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveLendingPoolAddressProvider interface
/// @author Enzyme Council <[email protected]>
interface IAaveLendingPoolAddressProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private addressToIsMinter;

    modifier onlyMinter() {
        require(
            addressToIsMinter[msg.sender] || owner() == msg.sender,
            "msg.sender is not owner or minter"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        _mint(msg.sender, uint256(100000000).mul(10**uint256(_decimals)));
    }

    function burnFrom(address _account, uint256 _amount) public override onlyMinter {
        _burn(_account, _amount);
    }

    function mintFor(address _who, uint256 _amount) external onlyMinter {
        _mint(_who, _amount);
    }

    function mint(uint256 _amount) external onlyMinter {
        _mint(msg.sender, _amount);
    }

    function addMinters(address[] memory _minters) public onlyOwner {
        for (uint256 i = 0; i < _minters.length; i++) {
            addressToIsMinter[_minters[i]] = true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/core/fund/comptroller/ComptrollerLib.sol";
import "./MockToken.sol";

/// @title MockReentrancyToken Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mock ERC20 token implementation that is able to re-entrance redeemShares and buyShares functions
contract MockReentrancyToken is MockToken("Mock Reentrancy Token", "MRT", 18) {
    bool public bad;
    address public comptrollerProxy;

    function makeItReentracyToken(address _comptrollerProxy) external {
        bad = true;
        comptrollerProxy = _comptrollerProxy;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (bad) {
            ComptrollerLib(comptrollerProxy).redeemSharesInKind(
                address(this),
                amount,
                new address[](0),
                new address[](0)
            );
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (bad) {
            ComptrollerLib(comptrollerProxy).buyShares(0, 0);
        } else {
            _transfer(sender, recipient, amount);
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../interfaces/ISynthetixAddressResolver.sol";
import "../../interfaces/ISynthetixExchanger.sol";
import "../../utils/FundDeployerOwnerMixin.sol";
import "../price-feeds/derivatives/feeds/SynthetixPriceFeed.sol";
import "./IAssetFinalityResolver.sol";

/// @title AssetFinalityResolver Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that helps achieve asset finality
contract AssetFinalityResolver is IAssetFinalityResolver, FundDeployerOwnerMixin {
    event SynthetixPriceFeedSet(address nextSynthetixPriceFeed);

    address private immutable SYNTHETIX_ADDRESS_RESOLVER;

    address private synthetixPriceFeed;

    constructor(
        address _fundDeployer,
        address _synthetixPriceFeed,
        address _synthetixAddressResolver
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        SYNTHETIX_ADDRESS_RESOLVER = _synthetixAddressResolver;
        __setSynthetixPriceFeed(_synthetixPriceFeed);
    }

    /// @notice Helper to finalize asset balances according to the procedures of their protocols
    /// @param _target The account that the assets belong to
    /// @param _assets The assets to finalize
    /// @dev Currently only handles Synths, and uses the SynthetixPriceFeed as a shortcut
    /// to validate supported Synths
    function finalizeAssets(address _target, address[] memory _assets) external override {
        if (_assets.length == 0) {
            return;
        }

        bytes32[] memory currencyKeys = SynthetixPriceFeed(getSynthetixPriceFeed())
            .getCurrencyKeysForSynths(_assets);
        address synthetixExchanger;
        for (uint256 i; i < _assets.length; i++) {
            if (currencyKeys[i] != 0) {
                if (synthetixExchanger == address(0)) {
                    synthetixExchanger = ISynthetixAddressResolver(getSynthetixAddressResolver())
                        .requireAndGetAddress(
                        "Exchanger",
                        "finalizeAssets: Missing Synthetix Exchanger"
                    );
                }
                ISynthetixExchanger(synthetixExchanger).settle(_target, currencyKeys[i]);
            }
        }
    }

    /// @notice Sets a new SynthetixPriceFeed for use within the contract
    /// @param _nextSynthetixPriceFeed The address of the SynthetixPriceFeed contract
    function setSynthetixPriceFeed(address _nextSynthetixPriceFeed)
        external
        onlyFundDeployerOwner
    {
        __setSynthetixPriceFeed(_nextSynthetixPriceFeed);
    }

    /// @dev Helper to set the synthetixPriceFeed
    function __setSynthetixPriceFeed(address _nextSynthetixPriceFeed) private {
        // Validates that the next SynthetixPriceFeed implements the required function
        SynthetixPriceFeed(_nextSynthetixPriceFeed).getCurrencyKeysForSynths(new address[](0));

        synthetixPriceFeed = _nextSynthetixPriceFeed;

        emit SynthetixPriceFeedSet(_nextSynthetixPriceFeed);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `SYNTHETIX_ADDRESS_RESOLVER` variable
    /// @return synthetixAddressResolver_ The `SYNTHETIX_ADDRESS_RESOLVER` variable value
    function getSynthetixAddressResolver()
        public
        view
        returns (address synthetixAddressResolver_)
    {
        return SYNTHETIX_ADDRESS_RESOLVER;
    }

    /// @notice Gets the `synthetixPriceFeed` variable
    /// @return synthetixPriceFeed_ The `synthetixPriceFeed` variable value
    function getSynthetixPriceFeed() public view returns (address synthetixPriceFeed_) {
        return synthetixPriceFeed;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ISynthetixAddressResolver Interface
/// @author Enzyme Council <[email protected]>
interface ISynthetixAddressResolver {
    function requireAndGetAddress(bytes32, string calldata) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ISynthetixExchanger Interface
/// @author Enzyme Council <[email protected]>
interface ISynthetixExchanger {
    function getAmountsForExchange(
        uint256,
        bytes32,
        bytes32
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function settle(address, bytes32)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/ISynthetix.sol";
import "../../../../interfaces/ISynthetixAddressResolver.sol";
import "../../../../interfaces/ISynthetixExchangeRates.sol";
import "../../../../interfaces/ISynthetixProxyERC20.sol";
import "../../../../interfaces/ISynthetixSynth.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title SynthetixPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice A price feed that uses Synthetix oracles as price sources
contract SynthetixPriceFeed is IDerivativePriceFeed, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event SynthAdded(address indexed synth, bytes32 currencyKey);

    event SynthRemoved(address indexed synth, bytes32 currencyKey);

    uint256 private constant SYNTH_UNIT = 10**18;
    address private immutable ADDRESS_RESOLVER;
    address private immutable SUSD;

    mapping(address => bytes32) private synthToCurrencyKey;

    constructor(
        address _fundDeployer,
        address _addressResolver,
        address _sUSD
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        ADDRESS_RESOLVER = _addressResolver;
        SUSD = _sUSD;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        underlyings_ = new address[](1);
        underlyings_[0] = getSUSD();
        underlyingAmounts_ = new uint256[](1);

        bytes32 currencyKey = getCurrencyKeyForSynth(_derivative);
        require(currencyKey != 0, "calcUnderlyingValues: _derivative is not supported");

        address exchangeRates = ISynthetixAddressResolver(getAddressResolver())
            .requireAndGetAddress("ExchangeRates", "calcUnderlyingValues: Missing ExchangeRates");

        (uint256 rate, bool isInvalid) = ISynthetixExchangeRates(exchangeRates).rateAndInvalid(
            currencyKey
        );
        require(!isInvalid, "calcUnderlyingValues: _derivative rate is not valid");

        underlyingAmounts_[0] = _derivativeAmount.mul(rate).div(SYNTH_UNIT);

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks whether an asset is a supported primitive of the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported primitive
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return getCurrencyKeyForSynth(_asset) != 0;
    }

    /////////////////////
    // SYNTHS REGISTRY //
    /////////////////////

    /// @notice Adds Synths to the price feed
    /// @param _synths Synths to add
    function addSynths(address[] calldata _synths) external onlyFundDeployerOwner {
        for (uint256 i; i < _synths.length; i++) {
            require(getCurrencyKeyForSynth(_synths[i]) == 0, "addSynths: Value already set");

            bytes32 currencyKey = __getCanonicalCurrencyKey(_synths[i]);
            require(currencyKey != 0, "addSynths: No currencyKey");

            synthToCurrencyKey[_synths[i]] = currencyKey;

            emit SynthAdded(_synths[i], currencyKey);
        }
    }

    /// @notice Removes Synths from the price feed
    /// @param _synths Synths to remove
    /// @dev Removing Synths from this feed will also affect the AssetFinalityResolver,
    /// as this contract is its shortcut determining whether assets are Synths
    function removeSynths(address[] calldata _synths) external onlyFundDeployerOwner {
        for (uint256 i; i < _synths.length; i++) {
            bytes32 currencyKey = getCurrencyKeyForSynth(_synths[i]);
            require(currencyKey != 0, "removeSynths: Synth not set");

            delete synthToCurrencyKey[_synths[i]];

            emit SynthRemoved(_synths[i], currencyKey);
        }
    }

    /// @dev Helper to query a currencyKey from Synthetix
    function __getCanonicalCurrencyKey(address _synthProxy)
        private
        view
        returns (bytes32 currencyKey_)
    {
        return ISynthetixSynth(ISynthetixProxyERC20(_synthProxy).target()).currencyKey();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    // EXTERNAL FUNCTIONS

    /// @notice Gets the currencyKey for multiple given Synths
    /// @return currencyKeys_ The currencyKey values
    function getCurrencyKeysForSynths(address[] calldata _synths)
        external
        view
        returns (bytes32[] memory currencyKeys_)
    {
        currencyKeys_ = new bytes32[](_synths.length);
        for (uint256 i; i < _synths.length; i++) {
            currencyKeys_[i] = getCurrencyKeyForSynth(_synths[i]);
        }

        return currencyKeys_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Gets the `ADDRESS_RESOLVER` variable
    /// @return addressResolver_ The `ADDRESS_RESOLVER` variable value
    function getAddressResolver() public view returns (address) {
        return ADDRESS_RESOLVER;
    }

    /// @notice Gets the currencyKey for a given Synth
    /// @return currencyKey_ The currencyKey value
    function getCurrencyKeyForSynth(address _synth) public view returns (bytes32 currencyKey_) {
        return synthToCurrencyKey[_synth];
    }

    /// @notice Gets the `SUSD` variable
    /// @return susd_ The `SUSD` variable value
    function getSUSD() public view returns (address susd_) {
        return SUSD;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ISynthetix Interface
/// @author Enzyme Council <[email protected]>
interface ISynthetix {
    function exchangeOnBehalfWithTracking(
        address,
        bytes32,
        uint256,
        bytes32,
        address,
        bytes32
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ISynthetixExchangeRates Interface
/// @author Enzyme Council <[email protected]>
interface ISynthetixExchangeRates {
    function rateAndInvalid(bytes32) external view returns (uint256, bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ISynthetixProxyERC20 Interface
/// @author Enzyme Council <[email protected]>
interface ISynthetixProxyERC20 {
    function target() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ISynthetixSynth Interface
/// @author Enzyme Council <[email protected]>
interface ISynthetixSynth {
    function currencyKey() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../release/infrastructure/asset-finality/IAssetFinalityResolver.sol";

contract TestnetAssetFinalityResolver is IAssetFinalityResolver {
    function finalizeAssets(address _target, address[] memory _assets) external override {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../infrastructure/price-feeds/derivatives/feeds/SynthetixPriceFeed.sol";
import "../../../../../interfaces/ISynthetix.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title SynthetixActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with the Synthetix exchange functions
abstract contract SynthetixActionsMixin is AssetHelpers {
    address private immutable SYNTHETIX;
    address private immutable SYNTHETIX_ORIGINATOR;
    address private immutable SYNTHETIX_PRICE_FEED;
    bytes32 private immutable SYNTHETIX_TRACKING_CODE;

    constructor(
        address _priceFeed,
        address _originator,
        address _synthetix,
        bytes32 _trackingCode
    ) public {
        SYNTHETIX_PRICE_FEED = _priceFeed;
        SYNTHETIX_ORIGINATOR = _originator;
        SYNTHETIX = _synthetix;
        SYNTHETIX_TRACKING_CODE = _trackingCode;
    }

    /// @dev Helper to execute takeOrder
    function __synthetixTakeOrder(
        address _recipient,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        address _incomingAsset
    ) internal {
        address[] memory synths = new address[](2);
        synths[0] = _outgoingAsset;
        synths[1] = _incomingAsset;

        bytes32[] memory currencyKeys = SynthetixPriceFeed(SYNTHETIX_PRICE_FEED)
            .getCurrencyKeysForSynths(synths);

        ISynthetix(SYNTHETIX).exchangeOnBehalfWithTracking(
            _recipient,
            currencyKeys[0],
            _outgoingAssetAmount,
            currencyKeys[1],
            SYNTHETIX_ORIGINATOR,
            SYNTHETIX_TRACKING_CODE
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `SYNTHETIX` variable
    /// @return synthetix_ The `SYNTHETIX` variable value
    function getSynthetix() public view returns (address synthetix_) {
        return SYNTHETIX;
    }

    /// @notice Gets the `SYNTHETIX_ORIGINATOR` variable
    /// @return synthetixOriginator_ The `SYNTHETIX_ORIGINATOR` variable value
    function getSynthetixOriginator() public view returns (address synthetixOriginator_) {
        return SYNTHETIX_ORIGINATOR;
    }

    /// @notice Gets the `SYNTHETIX_PRICE_FEED` variable
    /// @return synthetixPriceFeed_ The `SYNTHETIX_PRICE_FEED` variable value
    function getSynthetixPriceFeed() public view returns (address synthetixPriceFeed_) {
        return SYNTHETIX_PRICE_FEED;
    }

    /// @notice Gets the `SYNTHETIX_TRACKING_CODE` variable
    /// @return synthetixTrackingCode_ The `SYNTHETIX_TRACKING_CODE` variable value
    function getSynthetixTrackingCode() public view returns (bytes32 synthetixTrackingCode_) {
        return SYNTHETIX_TRACKING_CODE;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/actions/SynthetixActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title SynthetixAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with Synthetix
contract SynthetixAdapter is AdapterBase, SynthetixActionsMixin {
    constructor(
        address _integrationManager,
        address _synthetixPriceFeed,
        address _originator,
        address _synthetix,
        bytes32 _trackingCode
    )
        public
        AdapterBase(_integrationManager)
        SynthetixActionsMixin(_synthetixPriceFeed, _originator, _synthetix, _trackingCode)
    {}

    // EXTERNAL FUNCTIONS

    /// @notice Trades assets on Synthetix
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function takeOrder(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address incomingAsset,
            ,
            address outgoingAsset,
            uint256 outgoingAssetAmount
        ) = __decodeCallArgs(_actionData);

        __synthetixTakeOrder(_vaultProxy, outgoingAsset, outgoingAssetAmount, incomingAsset);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForAction: _selector invalid");

        (
            address incomingAsset,
            uint256 minIncomingAssetAmount,
            address outgoingAsset,
            uint256 outgoingAssetAmount
        ) = __decodeCallArgs(_actionData);

        spendAssets_ = new address[](1);
        spendAssets_[0] = outgoingAsset;
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingAssetAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = incomingAsset;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.None,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address incomingAsset_,
            uint256 minIncomingAssetAmount_,
            address outgoingAsset_,
            uint256 outgoingAssetAmount_
        )
    {
        return abi.decode(_actionData, (address, uint256, address, uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../infrastructure/price-feeds/derivatives/feeds/YearnVaultV2PriceFeed.sol";
import "../utils/actions/YearnVaultV2ActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title YearnVaultV2Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with Yearn v2 vaults
contract YearnVaultV2Adapter is AdapterBase, YearnVaultV2ActionsMixin {
    address private immutable YEARN_VAULT_V2_PRICE_FEED;

    constructor(address _integrationManager, address _yearnVaultV2PriceFeed)
        public
        AdapterBase(_integrationManager)
    {
        YEARN_VAULT_V2_PRICE_FEED = _yearnVaultV2PriceFeed;
    }

    /// @notice Deposits an amount of an underlying asset into its corresponding yVault
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    /// @dev Using postActionSpendAssetsTransferHandler is probably overkill, but since new
    /// yVault v2 contracts can update logic, this protects against a future implementation in
    /// which a partial underlying deposit amount is used if the desired amount exceeds the
    /// deposit limit, for example.
    function lend(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionSpendAssetsTransferHandler(_vaultProxy, _assetData)
    {
        // More efficient to parse all from _assetData
        (
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeAssetData(_assetData);

        __yearnVaultV2Lend(_vaultProxy, incomingAssets[0], spendAssets[0], spendAssetAmounts[0]);
    }

    /// @notice Redeems an amount of yVault shares for its underlying asset
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    /// @dev The amount of yVault shares to be redeemed can be adjusted in yVault.withdraw()
    /// depending on the available underlying balance, so we must send unredeemed yVault shares
    /// back to the _vaultProxy
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    )
        external
        onlyIntegrationManager
        postActionSpendAssetsTransferHandler(_vaultProxy, _assetData)
    {
        (
            address yVault,
            uint256 maxOutgoingYVaultSharesAmount,
            ,
            uint256 slippageToleranceBps
        ) = __decodeRedeemCallArgs(_actionData);

        __yearnVaultV2Redeem(
            _vaultProxy,
            yVault,
            maxOutgoingYVaultSharesAmount,
            slippageToleranceBps
        );
    }

    /// @dev Helper to get the underlying for a given Yearn Vault
    function __getUnderlyingForYVault(address _yVault) private view returns (address underlying_) {
        return
            YearnVaultV2PriceFeed(getYearnVaultV2PriceFeed()).getUnderlyingForDerivative(_yVault);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address yVault,
            uint256 outgoingUnderlyingAmount,
            uint256 minIncomingYVaultSharesAmount
        ) = __decodeLendCallArgs(_actionData);

        address underlying = __getUnderlyingForYVault(yVault);
        require(underlying != address(0), "__parseAssetsForLend: Unsupported yVault");

        spendAssets_ = new address[](1);
        spendAssets_[0] = underlying;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingUnderlyingAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = yVault;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingYVaultSharesAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address yVault,
            uint256 maxOutgoingYVaultSharesAmount,
            uint256 minIncomingUnderlyingAmount,

        ) = __decodeRedeemCallArgs(_actionData);

        address underlying = __getUnderlyingForYVault(yVault);
        require(underlying != address(0), "__parseAssetsForRedeem: Unsupported yVault");

        spendAssets_ = new address[](1);
        spendAssets_[0] = yVault;

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = maxOutgoingYVaultSharesAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = underlying;

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingUnderlyingAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    ///////////////////////
    // ENCODED CALL ARGS //
    ///////////////////////

    /// @dev Helper to decode callArgs for lending
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address yVault_,
            uint256 outgoingUnderlyingAmount_,
            uint256 minIncomingYVaultSharesAmount_
        )
    {
        return abi.decode(_actionData, (address, uint256, uint256));
    }

    /// @dev Helper to decode callArgs for redeeming
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address yVault_,
            uint256 maxOutgoingYVaultSharesAmount_,
            uint256 minIncomingUnderlyingAmount_,
            uint256 slippageToleranceBps_
        )
    {
        return abi.decode(_actionData, (address, uint256, uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `YEARN_VAULT_V2_PRICE_FEED` variable
    /// @return yearnVaultV2PriceFeed_ The `YEARN_VAULT_V2_PRICE_FEED` variable value
    function getYearnVaultV2PriceFeed() public view returns (address yearnVaultV2PriceFeed_) {
        return YEARN_VAULT_V2_PRICE_FEED;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../../interfaces/IUniswapV2Router2.sol";
import "../../../../../utils/AssetHelpers.sol";

/// @title UniswapV2ActionsMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin contract for interacting with Uniswap v2
abstract contract UniswapV2ActionsMixin is AssetHelpers {
    address private immutable UNISWAP_V2_ROUTER2;

    constructor(address _router) public {
        UNISWAP_V2_ROUTER2 = _router;
    }

    /// @dev Helper to add liquidity
    function __uniswapV2Lend(
        address _recipient,
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) internal {
        __approveAssetMaxAsNeeded(_tokenA, UNISWAP_V2_ROUTER2, _amountADesired);
        __approveAssetMaxAsNeeded(_tokenB, UNISWAP_V2_ROUTER2, _amountBDesired);

        // Execute lend on Uniswap
        IUniswapV2Router2(UNISWAP_V2_ROUTER2).addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin,
            _recipient,
            __uniswapV2GetActionDeadline()
        );
    }

    /// @dev Helper to remove liquidity
    function __uniswapV2Redeem(
        address _recipient,
        address _poolToken,
        uint256 _poolTokenAmount,
        address _tokenA,
        address _tokenB,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) internal {
        __approveAssetMaxAsNeeded(_poolToken, UNISWAP_V2_ROUTER2, _poolTokenAmount);

        // Execute redeem on Uniswap
        IUniswapV2Router2(UNISWAP_V2_ROUTER2).removeLiquidity(
            _tokenA,
            _tokenB,
            _poolTokenAmount,
            _amountAMin,
            _amountBMin,
            _recipient,
            __uniswapV2GetActionDeadline()
        );
    }

    /// @dev Helper to execute a swap
    function __uniswapV2Swap(
        address _recipient,
        uint256 _outgoingAssetAmount,
        uint256 _minIncomingAssetAmount,
        address[] memory _path
    ) internal {
        __approveAssetMaxAsNeeded(_path[0], UNISWAP_V2_ROUTER2, _outgoingAssetAmount);

        // Execute fill
        IUniswapV2Router2(UNISWAP_V2_ROUTER2).swapExactTokensForTokens(
            _outgoingAssetAmount,
            _minIncomingAssetAmount,
            _path,
            _recipient,
            __uniswapV2GetActionDeadline()
        );
    }

    /// @dev Helper to swap many assets to a single target asset.
    /// The intermediary asset will generally be WETH, and though we could make it
    // per-outgoing asset, seems like overkill until there is a need.
    function __uniswapV2SwapManyToOne(
        address _recipient,
        address[] memory _outgoingAssets,
        uint256[] memory _outgoingAssetAmounts,
        address _incomingAsset,
        address _intermediaryAsset
    ) internal {
        bool noIntermediary = _intermediaryAsset == address(0) ||
            _intermediaryAsset == _incomingAsset;
        for (uint256 i; i < _outgoingAssets.length; i++) {
            // Skip cases where outgoing and incoming assets are the same, or
            // there is no specified outgoing asset or amount
            if (
                _outgoingAssetAmounts[i] == 0 ||
                _outgoingAssets[i] == address(0) ||
                _outgoingAssets[i] == _incomingAsset
            ) {
                continue;
            }

            address[] memory uniswapPath;
            if (noIntermediary || _outgoingAssets[i] == _intermediaryAsset) {
                uniswapPath = new address[](2);
                uniswapPath[0] = _outgoingAssets[i];
                uniswapPath[1] = _incomingAsset;
            } else {
                uniswapPath = new address[](3);
                uniswapPath[0] = _outgoingAssets[i];
                uniswapPath[1] = _intermediaryAsset;
                uniswapPath[2] = _incomingAsset;
            }

            __uniswapV2Swap(_recipient, _outgoingAssetAmounts[i], 1, uniswapPath);
        }
    }

    /// @dev Helper to get the deadline for a Uniswap V2 action in a standardized way
    function __uniswapV2GetActionDeadline() private view returns (uint256 deadline_) {
        return block.timestamp + 1;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `UNISWAP_V2_ROUTER2` variable
    /// @return router_ The `UNISWAP_V2_ROUTER2` variable value
    function getUniswapV2Router2() public view returns (address router_) {
        return UNISWAP_V2_ROUTER2;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title UniswapV2Router2 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Minimal interface for our interactions with Uniswap V2's Router2
interface IUniswapV2Router2 {
    function addLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external returns (uint256, uint256);

    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../interfaces/IUniswapV2Factory.sol";
import "../utils/actions/UniswapV2ActionsMixin.sol";
import "../utils/AdapterBase.sol";

/// @title UniswapV2Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with Uniswap v2
contract UniswapV2Adapter is AdapterBase, UniswapV2ActionsMixin {
    address private immutable FACTORY;

    constructor(
        address _integrationManager,
        address _router,
        address _factory
    ) public AdapterBase(_integrationManager) UniswapV2ActionsMixin(_router) {
        FACTORY = _factory;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Lends assets for pool tokens on Uniswap
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function lend(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address[2] memory outgoingAssets,
            uint256[2] memory maxOutgoingAssetAmounts,
            uint256[2] memory minOutgoingAssetAmounts,

        ) = __decodeLendCallArgs(_actionData);

        __uniswapV2Lend(
            _vaultProxy,
            outgoingAssets[0],
            outgoingAssets[1],
            maxOutgoingAssetAmounts[0],
            maxOutgoingAssetAmounts[1],
            minOutgoingAssetAmounts[0],
            minOutgoingAssetAmounts[1]
        );
    }

    /// @notice Redeems pool tokens on Uniswap
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    /// @param _assetData Parsed spend assets and incoming assets data for this action
    function redeem(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata _assetData
    ) external onlyIntegrationManager {
        (
            uint256 outgoingAssetAmount,
            address[2] memory incomingAssets,
            uint256[2] memory minIncomingAssetAmounts
        ) = __decodeRedeemCallArgs(_actionData);

        // More efficient to parse pool token from _assetData than external call
        (address[] memory spendAssets, , ) = __decodeAssetData(_assetData);

        __uniswapV2Redeem(
            _vaultProxy,
            spendAssets[0],
            outgoingAssetAmount,
            incomingAssets[0],
            incomingAssets[1],
            minIncomingAssetAmounts[0],
            minIncomingAssetAmounts[1]
        );
    }

    /// @notice Trades assets on Uniswap
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _actionData Data specific to this action
    function takeOrder(
        address _vaultProxy,
        bytes calldata _actionData,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address[] memory path,
            uint256 outgoingAssetAmount,
            uint256 minIncomingAssetAmount
        ) = __decodeTakeOrderCallArgs(_actionData);

        __uniswapV2Swap(_vaultProxy, outgoingAssetAmount, minIncomingAssetAmount, path);
    }

    /////////////////////////////
    // PARSE ASSETS FOR METHOD //
    /////////////////////////////

    /// @notice Parses the expected assets in a particular action
    /// @param _selector The function selector for the callOnIntegration
    /// @param _actionData Data specific to this action
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForAction(
        address,
        bytes4 _selector,
        bytes calldata _actionData
    )
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        if (_selector == LEND_SELECTOR) {
            return __parseAssetsForLend(_actionData);
        } else if (_selector == REDEEM_SELECTOR) {
            return __parseAssetsForRedeem(_actionData);
        } else if (_selector == TAKE_ORDER_SELECTOR) {
            return __parseAssetsForTakeOrder(_actionData);
        }

        revert("parseAssetsForAction: _selector invalid");
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during lend() calls
    function __parseAssetsForLend(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address[2] memory outgoingAssets,
            uint256[2] memory maxOutgoingAssetAmounts,
            ,
            uint256 minIncomingAssetAmount
        ) = __decodeLendCallArgs(_actionData);

        spendAssets_ = new address[](2);
        spendAssets_[0] = outgoingAssets[0];
        spendAssets_[1] = outgoingAssets[1];

        spendAssetAmounts_ = new uint256[](2);
        spendAssetAmounts_[0] = maxOutgoingAssetAmounts[0];
        spendAssetAmounts_[1] = maxOutgoingAssetAmounts[1];

        incomingAssets_ = new address[](1);
        // No need to validate not address(0), this will be caught in IntegrationManager
        incomingAssets_[0] = IUniswapV2Factory(FACTORY).getPair(
            outgoingAssets[0],
            outgoingAssets[1]
        );

        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during redeem() calls
    function __parseAssetsForRedeem(bytes calldata _actionData)
        private
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            uint256 outgoingAssetAmount,
            address[2] memory incomingAssets,
            uint256[2] memory minIncomingAssetAmounts
        ) = __decodeRedeemCallArgs(_actionData);

        spendAssets_ = new address[](1);
        // No need to validate not address(0), this will be caught in IntegrationManager
        spendAssets_[0] = IUniswapV2Factory(FACTORY).getPair(incomingAssets[0], incomingAssets[1]);

        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingAssetAmount;

        incomingAssets_ = new address[](2);
        incomingAssets_[0] = incomingAssets[0];
        incomingAssets_[1] = incomingAssets[1];

        minIncomingAssetAmounts_ = new uint256[](2);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmounts[0];
        minIncomingAssetAmounts_[1] = minIncomingAssetAmounts[1];

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @dev Helper function to parse spend and incoming assets from encoded call args
    /// during takeOrder() calls
    function __parseAssetsForTakeOrder(bytes calldata _actionData)
        private
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        (
            address[] memory path,
            uint256 outgoingAssetAmount,
            uint256 minIncomingAssetAmount
        ) = __decodeTakeOrderCallArgs(_actionData);

        require(path.length >= 2, "__parseAssetsForTakeOrder: _path must be >= 2");

        spendAssets_ = new address[](1);
        spendAssets_[0] = path[0];
        spendAssetAmounts_ = new uint256[](1);
        spendAssetAmounts_[0] = outgoingAssetAmount;

        incomingAssets_ = new address[](1);
        incomingAssets_[0] = path[path.length - 1];
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the lend encoded call arguments
    function __decodeLendCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address[2] memory outgoingAssets_,
            uint256[2] memory maxOutgoingAssetAmounts_,
            uint256[2] memory minOutgoingAssetAmounts_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (address[2], uint256[2], uint256[2], uint256));
    }

    /// @dev Helper to decode the redeem encoded call arguments
    function __decodeRedeemCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            uint256 outgoingAssetAmount_,
            address[2] memory incomingAssets_,
            uint256[2] memory minIncomingAssetAmounts_
        )
    {
        return abi.decode(_actionData, (uint256, address[2], uint256[2]));
    }

    /// @dev Helper to decode the take order encoded call arguments
    function __decodeTakeOrderCallArgs(bytes memory _actionData)
        private
        pure
        returns (
            address[] memory path_,
            uint256 outgoingAssetAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_actionData, (address[], uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FACTORY` variable
    /// @return factory_ The `FACTORY` variable value
    function getFactory() external view returns (address factory_) {
        return FACTORY;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FeeBase.sol";

/// @title EntranceRateFeeBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Calculates a fee based on a rate to be charged to an investor upon entering a fund
abstract contract EntranceRateFeeBase is FeeBase {
    using SafeMath for uint256;

    event FundSettingsAdded(address indexed comptrollerProxy, uint256 rate);

    event Settled(address indexed comptrollerProxy, address indexed payer, uint256 sharesQuantity);

    uint256 private constant ONE_HUNDRED_PERCENT = 10000;
    IFeeManager.SettlementType private immutable SETTLEMENT_TYPE;

    mapping(address => uint256) private comptrollerProxyToRate;

    constructor(address _feeManager, IFeeManager.SettlementType _settlementType)
        public
        FeeBase(_feeManager)
    {
        require(
            _settlementType == IFeeManager.SettlementType.Burn ||
                _settlementType == IFeeManager.SettlementType.Direct,
            "constructor: Invalid _settlementType"
        );
        SETTLEMENT_TYPE = _settlementType;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        public
        virtual
        override
        onlyFeeManager
    {
        uint256 rate = abi.decode(_settingsData, (uint256));
        require(rate > 0, "addFundSettings: Fee rate must be >0");
        require(rate < ONE_HUNDRED_PERCENT, "addFundSettings: Fee rate max exceeded");

        comptrollerProxyToRate[_comptrollerProxy] = rate;

        emit FundSettingsAdded(_comptrollerProxy, rate);
    }

    /// @notice Settles the fee
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settlementData Encoded args to use in calculating the settlement
    /// @return settlementType_ The type of settlement
    /// @return payer_ The payer of shares due
    /// @return sharesDue_ The amount of shares due
    function settle(
        address _comptrollerProxy,
        address,
        IFeeManager.FeeHook,
        bytes calldata _settlementData,
        uint256
    )
        external
        override
        onlyFeeManager
        returns (
            IFeeManager.SettlementType settlementType_,
            address payer_,
            uint256 sharesDue_
        )
    {
        uint256 sharesBought;
        (payer_, , sharesBought) = __decodePostBuySharesSettlementData(_settlementData);

        uint256 rate = comptrollerProxyToRate[_comptrollerProxy];
        sharesDue_ = sharesBought.mul(rate).div(ONE_HUNDRED_PERCENT);

        if (sharesDue_ == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        emit Settled(_comptrollerProxy, payer_, sharesDue_);

        return (SETTLEMENT_TYPE, payer_, sharesDue_);
    }

    /// @notice Gets whether the fee settles and requires GAV on a particular hook
    /// @param _hook The FeeHook
    /// @return settles_ True if the fee settles on the _hook
    /// @return usesGav_ True if the fee uses GAV during settle() for the _hook
    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        override
        returns (bool settles_, bool usesGav_)
    {
        if (_hook == IFeeManager.FeeHook.PostBuyShares) {
            return (true, false);
        }

        return (false, false);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `rate` variable for a fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return rate_ The `rate` variable value
    function getRateForFund(address _comptrollerProxy) external view returns (uint256 rate_) {
        return comptrollerProxyToRate[_comptrollerProxy];
    }

    /// @notice Gets the `SETTLEMENT_TYPE` variable
    /// @return settlementType_ The `SETTLEMENT_TYPE` variable value
    function getSettlementType()
        external
        view
        returns (IFeeManager.SettlementType settlementType_)
    {
        return SETTLEMENT_TYPE;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/EntranceRateFeeBase.sol";
import "./utils/UpdatableFeeRecipientBase.sol";

/// @title EntranceRateDirectFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice An EntranceRateFee that transfers the fee shares to a recipient
contract EntranceRateDirectFee is EntranceRateFeeBase, UpdatableFeeRecipientBase {
    constructor(address _feeManager)
        public
        EntranceRateFeeBase(_feeManager, IFeeManager.SettlementType.Direct)
    {}

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    /// @dev onlyFeeManager validated by parent
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        public
        override
    {
        super.addFundSettings(_comptrollerProxy, _settingsData);

        (, address recipient) = abi.decode(_settingsData, (uint256, address));

        if (recipient != address(0)) {
            __setRecipientForFund(_comptrollerProxy, recipient);
        }
    }

    /// @notice Gets the recipient of the fee for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return recipient_ The recipient
    function getRecipientForFund(address _comptrollerProxy)
        public
        view
        override(FeeBase, SettableFeeRecipientBase)
        returns (address recipient_)
    {
        return SettableFeeRecipientBase.getRecipientForFund(_comptrollerProxy);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/EntranceRateFeeBase.sol";

/// @title EntranceRateBurnFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice An EntranceRateFee that burns the fee shares
contract EntranceRateBurnFee is EntranceRateFeeBase {
    constructor(address _feeManager)
        public
        EntranceRateFeeBase(_feeManager, IFeeManager.SettlementType.Burn)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/ExitRateFeeBase.sol";

/// @title ExitRateBurnFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice An ExitRateFee that burns the fee shares
contract ExitRateBurnFee is ExitRateFeeBase {
    constructor(address _feeManager)
        public
        ExitRateFeeBase(_feeManager, IFeeManager.SettlementType.Burn)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../IDerivativePriceFeed.sol";

/// @title RevertingPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed that always reverts on value conversion
/// @dev Used purely for extraordinary circumstances where we want to prevent value calculations,
/// while allowing an asset to continue to be in the asset universe
contract RevertingPriceFeed is IDerivativePriceFeed {
    /// @notice Converts a given amount of a derivative to its underlying asset values
    function calcUnderlyingValues(address, uint256)
        external
        override
        returns (address[] memory, uint256[] memory)
    {
        revert("calcUnderlyingValues: RevertingPriceFeed");
    }

    /// @notice Checks whether an asset is a supported primitive of the price feed
    /// @return isSupported_ True if the asset is a supported primitive
    function isSupportedAsset(address) public view override returns (bool isSupported_) {
        return true;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200,
    "details": {
      "yul": false
    }
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
  "metadata": {
    "useLiteralContent": true
  }
}