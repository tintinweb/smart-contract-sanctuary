// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../release/extensions/integration-manager/integrations/utils/AdapterBase.sol";

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

    // No need to specify the IntegrationManager
    constructor(address _integratee) public AdapterBase(address(0)) {
        INTEGRATEE = _integratee;
    }

    function identifier() external pure override returns (string memory) {
        return "MOCK_GENERIC";
    }

    function parseAssetsForMethod(bytes4 _selector, bytes calldata _callArgs)
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
        if (_selector == bytes4(keccak256("removeOnly(address,bytes,bytes)"))) {
            return IIntegrationManager.SpendAssetsHandleType.Remove;
        }
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
    ) external fundAssetsTransferHandler(_vaultProxy, _assetTransferArgs) {
        __decodeCallArgsAndSwap(_callArgs);
    }

    function swapB(
        address _vaultProxy,
        bytes calldata _callArgs,
        bytes calldata _assetTransferArgs
    ) external fundAssetsTransferHandler(_vaultProxy, _assetTransferArgs) {
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
    ) external fundAssetsTransferHandler(_vaultProxy, _assetTransferArgs) {
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../IIntegrationAdapter.sol";
import "./IntegrationSelectors.sol";

/// @title AdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract for integration adapters
abstract contract AdapterBase is IIntegrationAdapter, IntegrationSelectors {
    using SafeERC20 for ERC20;

    address internal immutable INTEGRATION_MANAGER;

    /// @dev Provides a standard implementation for transferring assets between
    /// the fund's VaultProxy and the adapter, by wrapping the adapter action.
    /// This modifier should be implemented in almost all adapter actions, unless they
    /// do not move assets or can spend and receive assets directly with the VaultProxy
    modifier fundAssetsTransferHandler(
        address _vaultProxy,
        bytes memory _encodedAssetTransferArgs
    ) {
        (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeEncodedAssetTransferArgs(_encodedAssetTransferArgs);

        // Take custody of spend assets (if necessary)
        if (spendAssetsHandleType == IIntegrationManager.SpendAssetsHandleType.Approve) {
            for (uint256 i = 0; i < spendAssets.length; i++) {
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
        __transferContractAssetBalancesToFund(_vaultProxy, incomingAssets);
        __transferContractAssetBalancesToFund(_vaultProxy, spendAssets);
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

    /// @dev Helper for adapters to approve their integratees with the max amount of an asset.
    /// Since everything is done atomically, and only the balances to-be-used are sent to adapters,
    /// there is no need to approve exact amounts on every call.
    function __approveMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if (ERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to decode the _encodedAssetTransferArgs param passed to adapter call
    function __decodeEncodedAssetTransferArgs(bytes memory _encodedAssetTransferArgs)
        internal
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_
        )
    {
        return
            abi.decode(
                _encodedAssetTransferArgs,
                (IIntegrationManager.SpendAssetsHandleType, address[], uint256[], address[])
            );
    }

    /// @dev Helper to transfer full contract balances of assets to the specified VaultProxy
    function __transferContractAssetBalancesToFund(address _vaultProxy, address[] memory _assets)
        private
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 postCallAmount = ERC20(_assets[i]).balanceOf(address(this));
            if (postCallAmount > 0) {
                ERC20(_assets[i]).safeTransfer(_vaultProxy, postCallAmount);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

import "../IIntegrationManager.sol";

/// @title Integration Adapter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all integration adapters
interface IIntegrationAdapter {
    function identifier() external pure returns (string memory identifier_);

    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
    bytes4 public constant ADD_TRACKED_ASSETS_SELECTOR = bytes4(
        keccak256("addTrackedAssets(address,bytes,bytes)")
    );

    // Trading
    bytes4 public constant TAKE_ORDER_SELECTOR = bytes4(
        keccak256("takeOrder(address,bytes,bytes)")
    );

    // Lending
    bytes4 public constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 public constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));
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
    enum SpendAssetsHandleType {None, Approve, Transfer, Remove}
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
import "../../../../interfaces/IZeroExV2.sol";
import "../../../../utils/MathHelpers.sol";
import "../../../../utils/AddressArrayLib.sol";
import "../../../utils/FundDeployerOwnerMixin.sol";
import "../utils/AdapterBase.sol";

/// @title ZeroExV2Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter to 0xV2 Exchange Contract
contract ZeroExV2Adapter is AdapterBase, FundDeployerOwnerMixin, MathHelpers {
    using AddressArrayLib for address[];
    using SafeMath for uint256;

    event AllowedMakerAdded(address indexed account);

    event AllowedMakerRemoved(address indexed account);

    address private immutable EXCHANGE;
    mapping(address => bool) private makerToIsAllowed;

    // Gas could be optimized for the end-user by also storing an immutable ZRX_ASSET_DATA,
    // for example, but in the narrow OTC use-case of this adapter, taker fees are unlikely.
    constructor(
        address _integrationManager,
        address _exchange,
        address _fundDeployer,
        address[] memory _allowedMakers
    ) public AdapterBase(_integrationManager) FundDeployerOwnerMixin(_fundDeployer) {
        EXCHANGE = _exchange;
        if (_allowedMakers.length > 0) {
            __addAllowedMakers(_allowedMakers);
        }
    }

    // EXTERNAL FUNCTIONS

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "ZERO_EX_V2";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForMethod: _selector invalid");

        (
            bytes memory encodedZeroExOrderArgs,
            uint256 takerAssetFillAmount
        ) = __decodeTakeOrderCallArgs(_encodedCallArgs);
        IZeroExV2.Order memory order = __constructOrderStruct(encodedZeroExOrderArgs);

        require(
            isAllowedMaker(order.makerAddress),
            "parseAssetsForMethod: Order maker is not allowed"
        );
        require(
            takerAssetFillAmount <= order.takerAssetAmount,
            "parseAssetsForMethod: Taker asset fill amount greater than available"
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
            address takerFeeAsset = __getAssetAddress(IZeroExV2(EXCHANGE).ZRX_ASSET_DATA());
            uint256 takerFeeFillAmount = __calcRelativeQuantity(
                order.takerAssetAmount,
                order.takerFee,
                takerAssetFillAmount
            ); // fee calculated relative to taker fill amount

            if (takerFeeAsset == makerAsset) {
                require(
                    order.takerFee < order.makerAssetAmount,
                    "parseAssetsForMethod: Fee greater than makerAssetAmount"
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

    /// @notice Take an order on 0x
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function takeOrder(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (
            bytes memory encodedZeroExOrderArgs,
            uint256 takerAssetFillAmount
        ) = __decodeTakeOrderCallArgs(_encodedCallArgs);
        IZeroExV2.Order memory order = __constructOrderStruct(encodedZeroExOrderArgs);

        // Approve spend assets as needed
        __approveMaxAsNeeded(
            __getAssetAddress(order.takerAssetData),
            __getAssetProxy(order.takerAssetData),
            takerAssetFillAmount
        );
        // Ignores whether makerAsset or takerAsset overlap with the takerFee asset for simplicity
        if (order.takerFee > 0) {
            bytes memory zrxData = IZeroExV2(EXCHANGE).ZRX_ASSET_DATA();
            __approveMaxAsNeeded(
                __getAssetAddress(zrxData),
                __getAssetProxy(zrxData),
                __calcRelativeQuantity(
                    order.takerAssetAmount,
                    order.takerFee,
                    takerAssetFillAmount
                ) // fee calculated relative to taker fill amount
            );
        }

        // Execute order
        (, , , bytes memory signature) = __decodeZeroExOrderArgs(encodedZeroExOrderArgs);
        IZeroExV2(EXCHANGE).fillOrder(order, takerAssetFillAmount, signature);
    }

    // PRIVATE FUNCTIONS

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

    /// @dev Decode the parameters of a takeOrder call
    /// @param _encodedCallArgs Encoded parameters passed from client side
    /// @return encodedZeroExOrderArgs_ Encoded args of the 0x order
    /// @return takerAssetFillAmount_ Amount of taker asset to fill
    function __decodeTakeOrderCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (bytes memory encodedZeroExOrderArgs_, uint256 takerAssetFillAmount_)
    {
        return abi.decode(_encodedCallArgs, (bytes, uint256));
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

    /// @dev Parses the asset address from 0x assetData
    function __getAssetAddress(bytes memory _assetData)
        private
        pure
        returns (address assetAddress_)
    {
        assembly {
            assetAddress_ := mload(add(_assetData, 36))
        }
    }

    /// @dev Gets the 0x assetProxy address for an ERC20 token
    function __getAssetProxy(bytes memory _assetData) private view returns (address assetProxy_) {
        bytes4 assetProxyId;

        assembly {
            assetProxyId := and(
                mload(add(_assetData, 32)),
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        assetProxy_ = IZeroExV2(EXCHANGE).getAssetProxy(assetProxyId);
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

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXCHANGE` variable value
    /// @return exchange_ The `EXCHANGE` variable value
    function getExchange() external view returns (address exchange_) {
        return EXCHANGE;
    }

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

    struct OrderInfo {
        uint8 orderStatus;
        bytes32 orderHash;
        uint256 orderTakerAssetFilledAmount;
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;
        uint256 takerAssetFilledAmount;
        uint256 makerFeePaid;
        uint256 takerFeePaid;
    }

    function ZRX_ASSET_DATA() external view returns (bytes memory);

    function filled(bytes32) external view returns (uint256);

    function cancelled(bytes32) external view returns (bool);

    function getOrderInfo(Order calldata) external view returns (OrderInfo memory);

    function getAssetProxy(bytes4) external view returns (address);

    function isValidSignature(
        bytes32,
        address,
        bytes calldata
    ) external view returns (bool);

    function preSign(
        bytes32,
        address,
        bytes calldata
    ) external;

    function cancelOrder(Order calldata) external;

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

    /// @dev Calculates a rate normalized to 10^18 precision,
    /// for given base and quote asset decimals and amounts
    function __calcNormalizedRate(
        uint256 _baseAssetDecimals,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetDecimals,
        uint256 _quoteAssetAmount
    ) internal pure returns (uint256 normalizedRate_) {
        return
            _quoteAssetAmount.mul(10**_baseAssetDecimals.add(18)).div(
                _baseAssetAmount.mul(10**_quoteAssetDecimals)
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

/// @title AddressArray Library
/// @author Enzyme Council <[email protected]>
/// @notice A library to extend the address array data type
library AddressArrayLib {
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

import "../../core/fund-deployer/IFundDeployer.sol";

/// @title FundDeployerOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
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
    function getFundDeployer() external view returns (address fundDeployer_) {
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

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    enum ReleaseStatus {PreLaunch, Live, Paused}

    function getOwner() external view returns (address);

    function getReleaseStatus() external view returns (ReleaseStatus);

    function isRegisteredVaultCall(address, bytes4) external view returns (bool);
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

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../../core/fund/vault/IVault.sol";
import "../utils/ExtensionBase.sol";
import "../utils/FundDeployerOwnerMixin.sol";
import "./IPolicy.sol";
import "./IPolicyManager.sol";

/// @title PolicyManager Contract
/// @author Enzyme Council <[email protected]>
/// @notice Manages policies for funds
contract PolicyManager is IPolicyManager, ExtensionBase, FundDeployerOwnerMixin {
    using EnumerableSet for EnumerableSet.AddressSet;

    event PolicyDeregistered(address indexed policy, string indexed identifier);

    event PolicyDisabledForFund(address indexed comptrollerProxy, address indexed policy);

    event PolicyEnabledForFund(
        address indexed comptrollerProxy,
        address indexed policy,
        bytes settingsData
    );

    event PolicyRegistered(
        address indexed policy,
        string indexed identifier,
        PolicyHook[] implementedHooks
    );

    EnumerableSet.AddressSet private registeredPolicies;
    mapping(address => mapping(PolicyHook => bool)) private policyToHookToIsImplemented;
    mapping(address => EnumerableSet.AddressSet) private comptrollerProxyToPolicies;

    modifier onlyBuySharesHooks(address _policy) {
        require(
            !policyImplementsHook(_policy, PolicyHook.PreCallOnIntegration) &&
                !policyImplementsHook(_policy, PolicyHook.PostCallOnIntegration),
            "onlyBuySharesHooks: Disallowed hook"
        );
        _;
    }

    modifier onlyEnabledPolicyForFund(address _comptrollerProxy, address _policy) {
        require(
            policyIsEnabledForFund(_comptrollerProxy, _policy),
            "onlyEnabledPolicyForFund: Policy not enabled"
        );
        _;
    }

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {}

    // EXTERNAL FUNCTIONS

    /// @notice Validates and initializes policies as necessary prior to fund activation
    /// @param _isMigratedFund True if the fund is migrating to this release
    /// @dev Caller is expected to be a valid ComptrollerProxy, but there isn't a need to validate.
    function activateForFund(bool _isMigratedFund) external override {
        address vaultProxy = __setValidatedVaultProxy(msg.sender);

        // Policies must assert that they are congruent with migrated vault state
        if (_isMigratedFund) {
            address[] memory enabledPolicies = getEnabledPoliciesForFund(msg.sender);
            for (uint256 i; i < enabledPolicies.length; i++) {
                __activatePolicyForFund(msg.sender, vaultProxy, enabledPolicies[i]);
            }
        }
    }

    /// @notice Deactivates policies for a fund by destroying storage
    function deactivateForFund() external override {
        delete comptrollerProxyToVaultProxy[msg.sender];

        for (uint256 i = comptrollerProxyToPolicies[msg.sender].length(); i > 0; i--) {
            comptrollerProxyToPolicies[msg.sender].remove(
                comptrollerProxyToPolicies[msg.sender].at(i - 1)
            );
        }
    }

    /// @notice Disables a policy for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _policy The policy address to disable
    function disablePolicyForFund(address _comptrollerProxy, address _policy)
        external
        onlyBuySharesHooks(_policy)
        onlyEnabledPolicyForFund(_comptrollerProxy, _policy)
    {
        __validateIsFundOwner(getVaultProxyForFund(_comptrollerProxy), msg.sender);

        comptrollerProxyToPolicies[_comptrollerProxy].remove(_policy);

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
    ) external onlyBuySharesHooks(_policy) {
        address vaultProxy = getVaultProxyForFund(_comptrollerProxy);
        __validateIsFundOwner(vaultProxy, msg.sender);

        __enablePolicyForFund(_comptrollerProxy, _policy, _settingsData);

        __activatePolicyForFund(_comptrollerProxy, vaultProxy, _policy);
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
            __enablePolicyForFund(msg.sender, policies[i], settingsData[i]);
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
    ) external onlyBuySharesHooks(_policy) onlyEnabledPolicyForFund(_comptrollerProxy, _policy) {
        address vaultProxy = getVaultProxyForFund(_comptrollerProxy);
        __validateIsFundOwner(vaultProxy, msg.sender);

        IPolicy(_policy).updateFundSettings(_comptrollerProxy, vaultProxy, _settingsData);
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
        address vaultProxy = getVaultProxyForFund(_comptrollerProxy);
        address[] memory policies = getEnabledPoliciesForFund(_comptrollerProxy);
        for (uint256 i; i < policies.length; i++) {
            if (!policyImplementsHook(policies[i], _hook)) {
                continue;
            }

            require(
                IPolicy(policies[i]).validateRule(
                    _comptrollerProxy,
                    vaultProxy,
                    _hook,
                    _validationData
                ),
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
    function __activatePolicyForFund(
        address _comptrollerProxy,
        address _vaultProxy,
        address _policy
    ) private {
        IPolicy(_policy).activateForFund(_comptrollerProxy, _vaultProxy);
    }

    /// @dev Helper to set config and enable policies for a fund
    function __enablePolicyForFund(
        address _comptrollerProxy,
        address _policy,
        bytes memory _settingsData
    ) private {
        require(
            !policyIsEnabledForFund(_comptrollerProxy, _policy),
            "__enablePolicyForFund: policy already enabled"
        );
        require(policyIsRegistered(_policy), "__enablePolicyForFund: Policy is not registered");

        // Set fund config on policy
        if (_settingsData.length > 0) {
            IPolicy(_policy).addFundSettings(_comptrollerProxy, _settingsData);
        }

        // Add policy
        comptrollerProxyToPolicies[_comptrollerProxy].add(_policy);

        emit PolicyEnabledForFund(_comptrollerProxy, _policy, _settingsData);
    }

    /// @dev Helper to validate fund owner.
    /// Preferred to a modifier because allows gas savings if re-using _vaultProxy.
    function __validateIsFundOwner(address _vaultProxy, address _who) private view {
        require(
            _who == IVault(_vaultProxy).getOwner(),
            "Only the fund owner can call this function"
        );
    }

    ///////////////////////
    // POLICIES REGISTRY //
    ///////////////////////

    /// @notice Remove policies from the list of registered policies
    /// @param _policies Addresses of policies to be registered
    function deregisterPolicies(address[] calldata _policies) external onlyFundDeployerOwner {
        require(_policies.length > 0, "deregisterPolicies: _policies cannot be empty");

        for (uint256 i; i < _policies.length; i++) {
            require(
                policyIsRegistered(_policies[i]),
                "deregisterPolicies: policy is not registered"
            );

            registeredPolicies.remove(_policies[i]);

            emit PolicyDeregistered(_policies[i], IPolicy(_policies[i]).identifier());
        }
    }

    /// @notice Add policies to the list of registered policies
    /// @param _policies Addresses of policies to be registered
    function registerPolicies(address[] calldata _policies) external onlyFundDeployerOwner {
        require(_policies.length > 0, "registerPolicies: _policies cannot be empty");

        for (uint256 i; i < _policies.length; i++) {
            require(
                !policyIsRegistered(_policies[i]),
                "registerPolicies: policy already registered"
            );

            registeredPolicies.add(_policies[i]);

            // Store the hooks that a policy implements for later use.
            // Fronts the gas for calls to check if a hook is implemented, and guarantees
            // that the implementsHooks return value does not change post-registration.
            IPolicy policyContract = IPolicy(_policies[i]);
            PolicyHook[] memory implementedHooks = policyContract.implementedHooks();
            for (uint256 j; j < implementedHooks.length; j++) {
                policyToHookToIsImplemented[_policies[i]][implementedHooks[j]] = true;
            }

            emit PolicyRegistered(_policies[i], policyContract.identifier(), implementedHooks);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Get all registered policies
    /// @return registeredPoliciesArray_ A list of all registered policy addresses
    function getRegisteredPolicies()
        external
        view
        returns (address[] memory registeredPoliciesArray_)
    {
        registeredPoliciesArray_ = new address[](registeredPolicies.length());
        for (uint256 i; i < registeredPoliciesArray_.length; i++) {
            registeredPoliciesArray_[i] = registeredPolicies.at(i);
        }
    }

    /// @notice Get a list of enabled policies for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return enabledPolicies_ An array of enabled policy addresses
    function getEnabledPoliciesForFund(address _comptrollerProxy)
        public
        view
        returns (address[] memory enabledPolicies_)
    {
        enabledPolicies_ = new address[](comptrollerProxyToPolicies[_comptrollerProxy].length());
        for (uint256 i; i < enabledPolicies_.length; i++) {
            enabledPolicies_[i] = comptrollerProxyToPolicies[_comptrollerProxy].at(i);
        }
    }

    /// @notice Checks if a policy implements a particular hook
    /// @param _policy The address of the policy to check
    /// @param _hook The PolicyHook to check
    /// @return implementsHook_ True if the policy implements the hook
    function policyImplementsHook(address _policy, PolicyHook _hook)
        public
        view
        returns (bool implementsHook_)
    {
        return policyToHookToIsImplemented[_policy][_hook];
    }

    /// @notice Check if a policy is enabled for the fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund to check
    /// @param _policy The address of the policy to check
    /// @return isEnabled_ True if the policy is enabled for the fund
    function policyIsEnabledForFund(address _comptrollerProxy, address _policy)
        public
        view
        returns (bool isEnabled_)
    {
        return comptrollerProxyToPolicies[_comptrollerProxy].contains(_policy);
    }

    /// @notice Check whether a policy is registered
    /// @param _policy The address of the policy to check
    /// @return isRegistered_ True if the policy is registered
    function policyIsRegistered(address _policy) public view returns (bool isRegistered_) {
        return registeredPolicies.contains(_policy);
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../persistent/utils/IMigratableVault.sol";

/// @title IVault Interface
/// @author Enzyme Council <[email protected]>
interface IVault is IMigratableVault {
    function addTrackedAsset(address) external;

    function approveAssetSpender(
        address,
        address,
        uint256
    ) external;

    function burnShares(address, uint256) external;

    function callOnContract(address, bytes calldata) external;

    function getAccessor() external view returns (address);

    function getOwner() external view returns (address);

    function getTrackedAssets() external view returns (address[] memory);

    function isTrackedAsset(address) external view returns (bool);

    function mintShares(address, uint256) external;

    function removeTrackedAsset(address) external;

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

import "./IPolicyManager.sol";

/// @title Policy Interface
/// @author Enzyme Council <[email protected]>
interface IPolicy {
    function activateForFund(address _comptrollerProxy, address _vaultProxy) external;

    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings) external;

    function identifier() external pure returns (string memory identifier_);

    function implementedHooks()
        external
        view
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_);

    function updateFundSettings(
        address _comptrollerProxy,
        address _vaultProxy,
        bytes calldata _encodedSettings
    ) external;

    function validateRule(
        address _comptrollerProxy,
        address _vaultProxy,
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

/// @title PolicyManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the PolicyManager
interface IPolicyManager {
    enum PolicyHook {
        BuySharesSetup,
        PreBuyShares,
        PostBuyShares,
        BuySharesCompleted,
        PreCallOnIntegration,
        PostCallOnIntegration
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

/// @title IComptroller Interface
/// @author Enzyme Council <[email protected]>
interface IComptroller {
    enum VaultAction {
        None,
        BurnShares,
        MintShares,
        TransferShares,
        ApproveAssetSpender,
        WithdrawAssetTo,
        AddTrackedAsset,
        RemoveTrackedAsset
    }

    function activate(address, bool) external;

    function calcGav(bool) external returns (uint256, bool);

    function calcGrossShareValue(bool) external returns (uint256, bool);

    function callOnExtension(
        address,
        uint256,
        bytes calldata
    ) external;

    function configureExtensions(bytes calldata, bytes calldata) external;

    function destruct() external;

    function getDenominationAsset() external view returns (address);

    function getVaultProxy() external view returns (address);

    function init(address, uint256) external;

    function permissionedVaultAction(VaultAction, bytes calldata) external;
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
    function activateForFund(address, address) external virtual override {
        return;
    }

    /// @notice Updates the policy settings for a fund
    /// @dev Disallowed by default, can be overridden by the policy
    function updateFundSettings(
        address,
        address,
        bytes calldata
    ) external virtual override {
        revert("updateFundSettings: Updates not allowed for this policy");
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

import "../../utils/PolicyBase.sol";

/// @title CallOnIntegrationPostValidatePolicyMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for policies that only implement the PostCallOnIntegration policy hook
abstract contract PostCallOnIntegrationValidatePolicyBase is PolicyBase {
    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        view
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PostCallOnIntegration;

        return implementedHooks_;
    }

    /// @notice Helper to decode rule arguments
    function __decodeRuleArgs(bytes memory _encodedRuleArgs)
        internal
        pure
        returns (
            address adapter_,
            bytes4 selector_,
            address[] memory incomingAssets_,
            uint256[] memory incomingAssetAmounts_,
            address[] memory outgoingAssets_,
            uint256[] memory outgoingAssetAmounts_
        )
    {
        return
            abi.decode(
                _encodedRuleArgs,
                (address, bytes4, address[], uint256[], address[], uint256[])
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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../core/fund/comptroller/ComptrollerLib.sol";
import "../../../../core/fund/vault/VaultLib.sol";
import "../../../../infrastructure/value-interpreter/ValueInterpreter.sol";
import "./utils/PostCallOnIntegrationValidatePolicyBase.sol";

/// @title MaxConcentration Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that defines a configurable threshold for the concentration of any one asset
/// in a fund's holdings
contract MaxConcentration is PostCallOnIntegrationValidatePolicyBase {
    using SafeMath for uint256;

    event MaxConcentrationSet(address indexed comptrollerProxy, uint256 value);

    uint256 private constant ONE_HUNDRED_PERCENT = 10**18; // 100%

    address private immutable VALUE_INTERPRETER;

    mapping(address => uint256) private comptrollerProxyToMaxConcentration;

    constructor(address _policyManager, address _valueInterpreter)
        public
        PolicyBase(_policyManager)
    {
        VALUE_INTERPRETER = _valueInterpreter;
    }

    /// @notice Validates and initializes a policy as necessary prior to fund activation
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _vaultProxy The fund's VaultProxy address
    /// @dev No need to authenticate access, as there are no state transitions
    function activateForFund(address _comptrollerProxy, address _vaultProxy)
        external
        override
        onlyPolicyManager
    {
        require(
            passesRule(_comptrollerProxy, _vaultProxy, VaultLib(_vaultProxy).getTrackedAssets()),
            "activateForFund: Max concentration exceeded"
        );
    }

    /// @notice Add the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        uint256 maxConcentration = abi.decode(_encodedSettings, (uint256));
        require(maxConcentration > 0, "addFundSettings: maxConcentration must be greater than 0");
        require(
            maxConcentration <= ONE_HUNDRED_PERCENT,
            "addFundSettings: maxConcentration cannot exceed 100%"
        );

        comptrollerProxyToMaxConcentration[_comptrollerProxy] = maxConcentration;

        emit MaxConcentrationSet(_comptrollerProxy, maxConcentration);
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "MAX_CONCENTRATION";
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _vaultProxy The fund's VaultProxy address
    /// @param _assets The assets with which to check the rule
    /// @return isValid_ True if the rule passes
    /// @dev The fund's denomination asset is exempt from the policy limit.
    function passesRule(
        address _comptrollerProxy,
        address _vaultProxy,
        address[] memory _assets
    ) public returns (bool isValid_) {
        uint256 maxConcentration = comptrollerProxyToMaxConcentration[_comptrollerProxy];
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);
        address denominationAsset = comptrollerProxyContract.getDenominationAsset();
        // Does not require asset finality, otherwise will fail when incoming asset is a Synth
        (uint256 totalGav, bool gavIsValid) = comptrollerProxyContract.calcGav(false);
        if (!gavIsValid) {
            return false;
        }

        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            if (
                !__rulePassesForAsset(
                    _vaultProxy,
                    denominationAsset,
                    maxConcentration,
                    totalGav,
                    asset
                )
            ) {
                return false;
            }
        }

        return true;
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _vaultProxy The fund's VaultProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        address _vaultProxy,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, , address[] memory incomingAssets, , , ) = __decodeRuleArgs(_encodedArgs);
        if (incomingAssets.length == 0) {
            return true;
        }

        return passesRule(_comptrollerProxy, _vaultProxy, incomingAssets);
    }

    /// @dev Helper to check if the rule holds for a particular asset.
    /// Avoids the stack-too-deep error.
    function __rulePassesForAsset(
        address _vaultProxy,
        address _denominationAsset,
        uint256 _maxConcentration,
        uint256 _totalGav,
        address _incomingAsset
    ) private returns (bool isValid_) {
        if (_incomingAsset == _denominationAsset) return true;

        uint256 assetBalance = ERC20(_incomingAsset).balanceOf(_vaultProxy);
        (uint256 assetGav, bool assetGavIsValid) = ValueInterpreter(VALUE_INTERPRETER)
            .calcLiveAssetValue(_incomingAsset, assetBalance, _denominationAsset);

        if (
            !assetGavIsValid ||
            assetGav.mul(ONE_HUNDRED_PERCENT).div(_totalGav) > _maxConcentration
        ) {
            return false;
        }

        return true;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the maxConcentration for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return maxConcentration_ The maxConcentration
    function getMaxConcentrationForFund(address _comptrollerProxy)
        external
        view
        returns (uint256 maxConcentration_)
    {
        return comptrollerProxyToMaxConcentration[_comptrollerProxy];
    }

    /// @notice Gets the `VALUE_INTERPRETER` variable
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../persistent/dispatcher/IDispatcher.sol";
import "../../../extensions/IExtension.sol";
import "../../../extensions/fee-manager/IFeeManager.sol";
import "../../../extensions/policy-manager/IPolicyManager.sol";
import "../../../infrastructure/price-feeds/primitives/IPrimitivePriceFeed.sol";
import "../../../infrastructure/value-interpreter/IValueInterpreter.sol";
import "../../../utils/AddressArrayLib.sol";
import "../../../utils/AssetFinalityResolver.sol";
import "../../fund-deployer/IFundDeployer.sol";
import "../vault/IVault.sol";
import "./IComptroller.sol";

/// @title ComptrollerLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The core logic library shared by all funds
contract ComptrollerLib is IComptroller, AssetFinalityResolver {
    using AddressArrayLib for address[];
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event MigratedSharesDuePaid(uint256 sharesDue);

    event OverridePauseSet(bool indexed overridePause);

    event PreRedeemSharesHookFailed(
        bytes failureReturnData,
        address redeemer,
        uint256 sharesQuantity
    );

    event SharesBought(
        address indexed caller,
        address indexed buyer,
        uint256 investmentAmount,
        uint256 sharesIssued,
        uint256 sharesReceived
    );

    event SharesRedeemed(
        address indexed redeemer,
        uint256 sharesQuantity,
        address[] receivedAssets,
        uint256[] receivedAssetQuantities
    );

    event VaultProxySet(address vaultProxy);

    // Constants and immutables - shared by all proxies
    uint256 private constant SHARES_UNIT = 10**18;
    address private immutable DISPATCHER;
    address private immutable FUND_DEPLOYER;
    address private immutable FEE_MANAGER;
    address private immutable INTEGRATION_MANAGER;
    address private immutable PRIMITIVE_PRICE_FEED;
    address private immutable POLICY_MANAGER;
    address private immutable VALUE_INTERPRETER;

    // Pseudo-constants (can only be set once)

    address internal denominationAsset;
    address internal vaultProxy;
    // True only for the one non-proxy
    bool internal isLib;

    // Storage

    // Allows a fund owner to override a release-level pause
    bool internal overridePause;
    // A reverse-mutex, granting atomic permission for particular contracts to make vault calls
    bool internal permissionedVaultActionAllowed;
    // A mutex to protect against reentrancy
    bool internal reentranceLocked;
    // A timelock between any "shares actions" (i.e., buy and redeem shares), per-account
    uint256 internal sharesActionTimelock;
    mapping(address => uint256) internal acctToLastSharesAction;

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

    modifier onlyActive() {
        __assertIsActive(vaultProxy);
        _;
    }

    modifier onlyNotPaused() {
        __assertNotPaused();
        _;
    }

    modifier onlyFundDeployer() {
        __assertIsFundDeployer(msg.sender);
        _;
    }

    modifier onlyOwner() {
        __assertIsOwner(msg.sender);
        _;
    }

    modifier timelockedSharesAction(address _account) {
        __assertSharesActionNotTimelocked(_account);
        _;
        acctToLastSharesAction[_account] = block.timestamp;
    }

    // ASSERTION HELPERS

    // Modifiers are inefficient in terms of contract size,
    // so we use helper functions to prevent repetitive inlining of expensive string values.

    /// @dev Since vaultProxy is set during activate(),
    /// we can check that var rather than storing additional state
    function __assertIsActive(address _vaultProxy) private pure {
        require(_vaultProxy != address(0), "Fund not active");
    }

    function __assertIsFundDeployer(address _who) private view {
        require(_who == FUND_DEPLOYER, "Only FundDeployer callable");
    }

    function __assertIsOwner(address _who) private view {
        require(_who == IVault(vaultProxy).getOwner(), "Only fund owner callable");
    }

    function __assertLowLevelCall(bool _success, bytes memory _returnData) private pure {
        require(_success, string(_returnData));
    }

    function __assertNotPaused() private view {
        require(!__fundIsPaused(), "Fund is paused");
    }

    function __assertNotReentranceLocked() private view {
        require(!reentranceLocked, "Re-entrance");
    }

    function __assertPermissionedVaultActionNotAllowed() private view {
        require(!permissionedVaultActionAllowed, "Vault action re-entrance");
    }

    function __assertSharesActionNotTimelocked(address _account) private view {
        require(
            block.timestamp.sub(acctToLastSharesAction[_account]) >= sharesActionTimelock,
            "Shares action timelocked"
        );
    }

    constructor(
        address _dispatcher,
        address _fundDeployer,
        address _valueInterpreter,
        address _feeManager,
        address _integrationManager,
        address _policyManager,
        address _primitivePriceFeed,
        address _synthetixPriceFeed,
        address _synthetixAddressResolver
    ) public AssetFinalityResolver(_synthetixPriceFeed, _synthetixAddressResolver) {
        DISPATCHER = _dispatcher;
        FEE_MANAGER = _feeManager;
        FUND_DEPLOYER = _fundDeployer;
        INTEGRATION_MANAGER = _integrationManager;
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
        POLICY_MANAGER = _policyManager;
        VALUE_INTERPRETER = _valueInterpreter;
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
    ) external override onlyNotPaused onlyActive locksReentrance allowsPermissionedVaultAction {
        require(
            _extension == FEE_MANAGER || _extension == INTEGRATION_MANAGER,
            "callOnExtension: _extension invalid"
        );

        IExtension(_extension).receiveCallFromComptroller(msg.sender, _actionId, _callArgs);
    }

    /// @notice Sets or unsets an override on a release-wide pause
    /// @param _nextOverridePause True if the pause should be overrode
    function setOverridePause(bool _nextOverridePause) external onlyOwner {
        require(_nextOverridePause != overridePause, "setOverridePause: Value already set");

        overridePause = _nextOverridePause;

        emit OverridePauseSet(_nextOverridePause);
    }

    /// @notice Makes an arbitrary call with the VaultProxy contract as the sender
    /// @param _contract The contract to call
    /// @param _selector The selector to call
    /// @param _encodedArgs The encoded arguments for the call
    function vaultCallOnContract(
        address _contract,
        bytes4 _selector,
        bytes calldata _encodedArgs
    ) external onlyNotPaused onlyActive onlyOwner {
        require(
            IFundDeployer(FUND_DEPLOYER).isRegisteredVaultCall(_contract, _selector),
            "vaultCallOnContract: Unregistered"
        );

        IVault(vaultProxy).callOnContract(_contract, abi.encodePacked(_selector, _encodedArgs));
    }

    /// @dev Helper to check whether the release is paused, and that there is no local override
    function __fundIsPaused() private view returns (bool) {
        return
            IFundDeployer(FUND_DEPLOYER).getReleaseStatus() ==
            IFundDeployer.ReleaseStatus.Paused &&
            !overridePause;
    }

    ////////////////////////////////
    // PERMISSIONED VAULT ACTIONS //
    ////////////////////////////////

    /// @notice Makes a permissioned, state-changing call on the VaultProxy contract
    /// @param _action The enum representing the VaultAction to perform on the VaultProxy
    /// @param _actionData The call data for the action to perform
    function permissionedVaultAction(VaultAction _action, bytes calldata _actionData)
        external
        override
        onlyNotPaused
        onlyActive
    {
        __assertPermissionedVaultAction(msg.sender, _action);

        if (_action == VaultAction.AddTrackedAsset) {
            __vaultActionAddTrackedAsset(_actionData);
        } else if (_action == VaultAction.ApproveAssetSpender) {
            __vaultActionApproveAssetSpender(_actionData);
        } else if (_action == VaultAction.BurnShares) {
            __vaultActionBurnShares(_actionData);
        } else if (_action == VaultAction.MintShares) {
            __vaultActionMintShares(_actionData);
        } else if (_action == VaultAction.RemoveTrackedAsset) {
            __vaultActionRemoveTrackedAsset(_actionData);
        } else if (_action == VaultAction.TransferShares) {
            __vaultActionTransferShares(_actionData);
        } else if (_action == VaultAction.WithdrawAssetTo) {
            __vaultActionWithdrawAssetTo(_actionData);
        }
    }

    /// @dev Helper to assert that a caller is allowed to perform a particular VaultAction
    function __assertPermissionedVaultAction(address _caller, VaultAction _action) private view {
        require(
            permissionedVaultActionAllowed,
            "__assertPermissionedVaultAction: No action allowed"
        );

        if (_caller == INTEGRATION_MANAGER) {
            require(
                _action == VaultAction.ApproveAssetSpender ||
                    _action == VaultAction.AddTrackedAsset ||
                    _action == VaultAction.RemoveTrackedAsset ||
                    _action == VaultAction.WithdrawAssetTo,
                "__assertPermissionedVaultAction: Not valid for IntegrationManager"
            );
        } else if (_caller == FEE_MANAGER) {
            require(
                _action == VaultAction.BurnShares ||
                    _action == VaultAction.MintShares ||
                    _action == VaultAction.TransferShares,
                "__assertPermissionedVaultAction: Not valid for FeeManager"
            );
        } else {
            revert("__assertPermissionedVaultAction: Not a valid actor");
        }
    }

    /// @dev Helper to add a tracked asset to the fund
    function __vaultActionAddTrackedAsset(bytes memory _actionData) private {
        address asset = abi.decode(_actionData, (address));
        IVault(vaultProxy).addTrackedAsset(asset);
    }

    /// @dev Helper to grant a spender an allowance for a fund's asset
    function __vaultActionApproveAssetSpender(bytes memory _actionData) private {
        (address asset, address target, uint256 amount) = abi.decode(
            _actionData,
            (address, address, uint256)
        );
        IVault(vaultProxy).approveAssetSpender(asset, target, amount);
    }

    /// @dev Helper to burn fund shares for a particular account
    function __vaultActionBurnShares(bytes memory _actionData) private {
        (address target, uint256 amount) = abi.decode(_actionData, (address, uint256));
        IVault(vaultProxy).burnShares(target, amount);
    }

    /// @dev Helper to mint fund shares to a particular account
    function __vaultActionMintShares(bytes memory _actionData) private {
        (address target, uint256 amount) = abi.decode(_actionData, (address, uint256));
        IVault(vaultProxy).mintShares(target, amount);
    }

    /// @dev Helper to remove a tracked asset from the fund
    function __vaultActionRemoveTrackedAsset(bytes memory _actionData) private {
        address asset = abi.decode(_actionData, (address));

        // Allowing this to fail silently makes it cheaper and simpler
        // for Extensions to not query for the denomination asset
        if (asset != denominationAsset) {
            IVault(vaultProxy).removeTrackedAsset(asset);
        }
    }

    /// @dev Helper to transfer fund shares from one account to another
    function __vaultActionTransferShares(bytes memory _actionData) private {
        (address from, address to, uint256 amount) = abi.decode(
            _actionData,
            (address, address, uint256)
        );
        IVault(vaultProxy).transferShares(from, to, amount);
    }

    /// @dev Helper to withdraw an asset from the VaultProxy to a given account
    function __vaultActionWithdrawAssetTo(bytes memory _actionData) private {
        (address asset, address target, uint256 amount) = abi.decode(
            _actionData,
            (address, address, uint256)
        );
        IVault(vaultProxy).withdrawAssetTo(asset, target, amount);
    }

    ///////////////
    // LIFECYCLE //
    ///////////////

    /// @notice Initializes a fund with its core config
    /// @param _denominationAsset The asset in which the fund's value should be denominated
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @dev Pseudo-constructor per proxy.
    /// No need to assert access because this is called atomically on deployment,
    /// and once it's called, it cannot be called again.
    function init(address _denominationAsset, uint256 _sharesActionTimelock) external override {
        require(denominationAsset == address(0), "init: Already initialized");
        require(
            IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).isSupportedAsset(_denominationAsset),
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
            IExtension(FEE_MANAGER).setConfigForFund(_feeManagerConfigData);
        }
        if (_policyManagerConfigData.length > 0) {
            IExtension(POLICY_MANAGER).setConfigForFund(_policyManagerConfigData);
        }
    }

    /// @notice Activates the fund by attaching a VaultProxy and activating all Extensions
    /// @param _vaultProxy The VaultProxy to attach to the fund
    /// @param _isMigration True if a migrated fund is being activated
    /// @dev No need to assert anything beyond FundDeployer access.
    function activate(address _vaultProxy, bool _isMigration) external override onlyFundDeployer {
        vaultProxy = _vaultProxy;

        emit VaultProxySet(_vaultProxy);

        if (_isMigration) {
            // Distribute any shares in the VaultProxy to the fund owner.
            // This is a mechanism to ensure that even in the edge case of a fund being unable
            // to payout fee shares owed during migration, these shares are not lost.
            uint256 sharesDue = ERC20(_vaultProxy).balanceOf(_vaultProxy);
            if (sharesDue > 0) {
                IVault(_vaultProxy).transferShares(
                    _vaultProxy,
                    IVault(_vaultProxy).getOwner(),
                    sharesDue
                );

                emit MigratedSharesDuePaid(sharesDue);
            }
        }

        // Note: a future release could consider forcing the adding of a tracked asset here,
        // just in case a fund is migrating from an old configuration where they are not able
        // to remove an asset to get under the tracked assets limit
        IVault(_vaultProxy).addTrackedAsset(denominationAsset);

        // Activate extensions
        IExtension(FEE_MANAGER).activateForFund(_isMigration);
        IExtension(INTEGRATION_MANAGER).activateForFund(_isMigration);
        IExtension(POLICY_MANAGER).activateForFund(_isMigration);
    }

    /// @notice Remove the config for a fund
    /// @dev No need to assert anything beyond FundDeployer access.
    /// Calling onlyNotPaused here rather than in the FundDeployer allows
    /// the owner to potentially override the pause and rescue unpaid fees.
    function destruct()
        external
        override
        onlyFundDeployer
        onlyNotPaused
        allowsPermissionedVaultAction
    {
        // Failsafe to protect the libs against selfdestruct
        require(!isLib, "destruct: Only delegate callable");

        // Deactivate the extensions
        IExtension(FEE_MANAGER).deactivateForFund();
        IExtension(INTEGRATION_MANAGER).deactivateForFund();
        IExtension(POLICY_MANAGER).deactivateForFund();

        // Delete storage of ComptrollerProxy
        // There should never be ETH in the ComptrollerLib, so no need to waste gas
        // to get the fund owner
        selfdestruct(address(0));
    }

    ////////////////
    // ACCOUNTING //
    ////////////////

    /// @notice Calculates the gross asset value (GAV) of the fund
    /// @param _requireFinality True if all assets must have exact final balances settled
    /// @return gav_ The fund GAV
    /// @return isValid_ True if the conversion rates used to derive the GAV are all valid
    function calcGav(bool _requireFinality) public override returns (uint256 gav_, bool isValid_) {
        address vaultProxyAddress = vaultProxy;
        address[] memory assets = IVault(vaultProxyAddress).getTrackedAssets();
        if (assets.length == 0) {
            return (0, true);
        }

        uint256[] memory balances = new uint256[](assets.length);
        for (uint256 i; i < assets.length; i++) {
            balances[i] = __finalizeIfSynthAndGetAssetBalance(
                vaultProxyAddress,
                assets[i],
                _requireFinality
            );
        }

        (gav_, isValid_) = IValueInterpreter(VALUE_INTERPRETER).calcCanonicalAssetsTotalValue(
            assets,
            balances,
            denominationAsset
        );

        return (gav_, isValid_);
    }

    /// @notice Calculates the gross value of 1 unit of shares in the fund's denomination asset
    /// @param _requireFinality True if all assets must have exact final balances settled
    /// @return grossShareValue_ The amount of the denomination asset per share
    /// @return isValid_ True if the conversion rates to derive the value are all valid
    /// @dev Does not account for any fees outstanding.
    function calcGrossShareValue(bool _requireFinality)
        external
        override
        returns (uint256 grossShareValue_, bool isValid_)
    {
        uint256 gav;
        (gav, isValid_) = calcGav(_requireFinality);

        grossShareValue_ = __calcGrossShareValue(
            gav,
            ERC20(vaultProxy).totalSupply(),
            10**uint256(ERC20(denominationAsset).decimals())
        );

        return (grossShareValue_, isValid_);
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

    /// @notice Buys shares in the fund for multiple sets of criteria
    /// @param _buyers The accounts for which to buy shares
    /// @param _investmentAmounts The amounts of the fund's denomination asset
    /// with which to buy shares for the corresponding _buyers
    /// @param _minSharesQuantities The minimum quantities of shares to buy
    /// with the corresponding _investmentAmounts
    /// @return sharesReceivedAmounts_ The actual amounts of shares received
    /// by the corresponding _buyers
    /// @dev Param arrays have indexes corresponding to individual __buyShares() orders.
    function buyShares(
        address[] calldata _buyers,
        uint256[] calldata _investmentAmounts,
        uint256[] calldata _minSharesQuantities
    )
        external
        onlyNotPaused
        locksReentrance
        allowsPermissionedVaultAction
        returns (uint256[] memory sharesReceivedAmounts_)
    {
        require(_buyers.length > 0, "buyShares: Empty _buyers");
        require(
            _buyers.length == _investmentAmounts.length &&
                _buyers.length == _minSharesQuantities.length,
            "buyShares: Unequal arrays"
        );

        address vaultProxyCopy = vaultProxy;
        __assertIsActive(vaultProxyCopy);
        require(
            !IDispatcher(DISPATCHER).hasMigrationRequest(vaultProxyCopy),
            "buyShares: Pending migration"
        );

        (uint256 gav, bool gavIsValid) = calcGav(true);
        require(gavIsValid, "buyShares: Invalid GAV");

        __buySharesSetupHook(msg.sender, _investmentAmounts, gav);

        address denominationAssetCopy = denominationAsset;
        uint256 sharePrice = __calcGrossShareValue(
            gav,
            ERC20(vaultProxyCopy).totalSupply(),
            10**uint256(ERC20(denominationAssetCopy).decimals())
        );

        sharesReceivedAmounts_ = new uint256[](_buyers.length);
        for (uint256 i; i < _buyers.length; i++) {
            sharesReceivedAmounts_[i] = __buyShares(
                _buyers[i],
                _investmentAmounts[i],
                _minSharesQuantities[i],
                vaultProxyCopy,
                sharePrice,
                gav,
                denominationAssetCopy
            );

            gav = gav.add(_investmentAmounts[i]);
        }

        __buySharesCompletedHook(msg.sender, sharesReceivedAmounts_, gav);

        return sharesReceivedAmounts_;
    }

    /// @dev Helper to buy shares
    function __buyShares(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _minSharesQuantity,
        address _vaultProxy,
        uint256 _sharePrice,
        uint256 _preBuySharesGav,
        address _denominationAsset
    ) private timelockedSharesAction(_buyer) returns (uint256 sharesReceived_) {
        require(_investmentAmount > 0, "__buyShares: Empty _investmentAmount");

        // Gives Extensions a chance to run logic prior to the minting of bought shares
        __preBuySharesHook(_buyer, _investmentAmount, _minSharesQuantity, _preBuySharesGav);

        // Calculate the amount of shares to issue with the investment amount
        uint256 sharesIssued = _investmentAmount.mul(SHARES_UNIT).div(_sharePrice);

        // Mint shares to the buyer
        uint256 prevBuyerShares = ERC20(_vaultProxy).balanceOf(_buyer);
        IVault(_vaultProxy).mintShares(_buyer, sharesIssued);

        // Transfer the investment asset to the fund.
        // Does not follow the checks-effects-interactions pattern, but it is preferred
        // to have the final state of the VaultProxy prior to running __postBuySharesHook().
        ERC20(_denominationAsset).safeTransferFrom(msg.sender, _vaultProxy, _investmentAmount);

        // Gives Extensions a chance to run logic after shares are issued
        __postBuySharesHook(_buyer, _investmentAmount, sharesIssued, _preBuySharesGav);

        // The number of actual shares received may differ from shares issued due to
        // how the PostBuyShares hooks are invoked by Extensions (i.e., fees)
        sharesReceived_ = ERC20(_vaultProxy).balanceOf(_buyer).sub(prevBuyerShares);
        require(
            sharesReceived_ >= _minSharesQuantity,
            "__buyShares: Shares received < _minSharesQuantity"
        );

        emit SharesBought(msg.sender, _buyer, _investmentAmount, sharesIssued, sharesReceived_);

        return sharesReceived_;
    }

    /// @dev Helper for Extension actions after all __buyShares() calls are made
    function __buySharesCompletedHook(
        address _caller,
        uint256[] memory _sharesReceivedAmounts,
        uint256 _gav
    ) private {
        IPolicyManager(POLICY_MANAGER).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.BuySharesCompleted,
            abi.encode(_caller, _sharesReceivedAmounts, _gav)
        );

        IFeeManager(FEE_MANAGER).invokeHook(
            IFeeManager.FeeHook.BuySharesCompleted,
            abi.encode(_caller, _sharesReceivedAmounts),
            _gav
        );
    }

    /// @dev Helper for Extension actions before any __buyShares() calls are made
    function __buySharesSetupHook(
        address _caller,
        uint256[] memory _investmentAmounts,
        uint256 _gav
    ) private {
        IPolicyManager(POLICY_MANAGER).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.BuySharesSetup,
            abi.encode(_caller, _investmentAmounts, _gav)
        );

        IFeeManager(FEE_MANAGER).invokeHook(
            IFeeManager.FeeHook.BuySharesSetup,
            abi.encode(_caller, _investmentAmounts),
            _gav
        );
    }

    /// @dev Helper for Extension actions immediately prior to issuing shares.
    /// This could be cleaned up so both Extensions take the same encoded args and handle GAV
    /// in the same way, but there is not the obvious need for gas savings of recycling
    /// the GAV value for the current policies as there is for the fees.
    function __preBuySharesHook(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _minSharesQuantity,
        uint256 _gav
    ) private {
        IFeeManager(FEE_MANAGER).invokeHook(
            IFeeManager.FeeHook.PreBuyShares,
            abi.encode(_buyer, _investmentAmount, _minSharesQuantity),
            _gav
        );

        IPolicyManager(POLICY_MANAGER).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.PreBuyShares,
            abi.encode(_buyer, _investmentAmount, _minSharesQuantity, _gav)
        );
    }

    /// @dev Helper for Extension actions immediately after issuing shares.
    /// Same comment applies from __preBuySharesHook() above.
    function __postBuySharesHook(
        address _buyer,
        uint256 _investmentAmount,
        uint256 _sharesIssued,
        uint256 _preBuySharesGav
    ) private {
        uint256 gav = _preBuySharesGav.add(_investmentAmount);
        IFeeManager(FEE_MANAGER).invokeHook(
            IFeeManager.FeeHook.PostBuyShares,
            abi.encode(_buyer, _investmentAmount, _sharesIssued),
            gav
        );

        IPolicyManager(POLICY_MANAGER).validatePolicies(
            address(this),
            IPolicyManager.PolicyHook.PostBuyShares,
            abi.encode(_buyer, _investmentAmount, _sharesIssued, gav)
        );
    }

    // REDEEM SHARES

    /// @notice Redeem all of the sender's shares for a proportionate slice of the fund's assets
    /// @return payoutAssets_ The assets paid out to the redeemer
    /// @return payoutAmounts_ The amount of each asset paid out to the redeemer
    /// @dev See __redeemShares() for further detail
    function redeemShares()
        external
        returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_)
    {
        return
            __redeemShares(
                msg.sender,
                ERC20(vaultProxy).balanceOf(msg.sender),
                new address[](0),
                new address[](0)
            );
    }

    /// @notice Redeem a specified quantity of the sender's shares for a proportionate slice of
    /// the fund's assets, optionally specifying additional assets and assets to skip.
    /// @param _sharesQuantity The quantity of shares to redeem
    /// @param _additionalAssets Additional (non-tracked) assets to claim
    /// @param _assetsToSkip Tracked assets to forfeit
    /// @return payoutAssets_ The assets paid out to the redeemer
    /// @return payoutAmounts_ The amount of each asset paid out to the redeemer
    /// @dev Any claim to passed _assetsToSkip will be forfeited entirely. This should generally
    /// only be exercised if a bad asset is causing redemption to fail.
    function redeemSharesDetailed(
        uint256 _sharesQuantity,
        address[] calldata _additionalAssets,
        address[] calldata _assetsToSkip
    ) external returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_) {
        return __redeemShares(msg.sender, _sharesQuantity, _additionalAssets, _assetsToSkip);
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

    /// @dev Helper for system actions immediately prior to redeeming shares.
    /// Policy validation is not currently allowed on redemption, to ensure continuous redeemability.
    function __preRedeemSharesHook(address _redeemer, uint256 _sharesQuantity)
        private
        allowsPermissionedVaultAction
    {
        try
            IFeeManager(FEE_MANAGER).invokeHook(
                IFeeManager.FeeHook.PreRedeemShares,
                abi.encode(_redeemer, _sharesQuantity),
                0
            )
         {} catch (bytes memory reason) {
            emit PreRedeemSharesHookFailed(reason, _redeemer, _sharesQuantity);
        }
    }

    /// @dev Helper to redeem shares.
    /// This function should never fail without a way to bypass the failure, which is assured
    /// through two mechanisms:
    /// 1. The FeeManager is called with the try/catch pattern to assure that calls to it
    /// can never block redemption.
    /// 2. If a token fails upon transfer(), that token can be skipped (and its balance forfeited)
    /// by explicitly specifying _assetsToSkip.
    /// Because of these assurances, shares should always be redeemable, with the exception
    /// of the timelock period on shares actions that must be respected.
    function __redeemShares(
        address _redeemer,
        uint256 _sharesQuantity,
        address[] memory _additionalAssets,
        address[] memory _assetsToSkip
    )
        private
        locksReentrance
        returns (address[] memory payoutAssets_, uint256[] memory payoutAmounts_)
    {
        require(_sharesQuantity > 0, "__redeemShares: _sharesQuantity must be >0");
        require(
            _additionalAssets.isUniqueSet(),
            "__redeemShares: _additionalAssets contains duplicates"
        );
        require(_assetsToSkip.isUniqueSet(), "__redeemShares: _assetsToSkip contains duplicates");

        IVault vaultProxyContract = IVault(vaultProxy);

        // Only apply the sharesActionTimelock when a migration is not pending
        if (!IDispatcher(DISPATCHER).hasMigrationRequest(address(vaultProxyContract))) {
            __assertSharesActionNotTimelocked(_redeemer);
            acctToLastSharesAction[_redeemer] = block.timestamp;
        }

        // When a fund is paused, settling fees will be skipped
        if (!__fundIsPaused()) {
            // Note that if a fee with `SettlementType.Direct` is charged here (i.e., not `Mint`),
            // then those fee shares will be transferred from the user's balance rather
            // than reallocated from the sharesQuantity being redeemed.
            __preRedeemSharesHook(_redeemer, _sharesQuantity);
        }

        // Check the shares quantity against the user's balance after settling fees
        ERC20 sharesContract = ERC20(address(vaultProxyContract));
        require(
            _sharesQuantity <= sharesContract.balanceOf(_redeemer),
            "__redeemShares: Insufficient shares"
        );

        // Parse the payout assets given optional params to add or skip assets.
        // Note that there is no validation that the _additionalAssets are known assets to
        // the protocol. This means that the redeemer could specify a malicious asset,
        // but since all state-changing, user-callable functions on this contract share the
        // non-reentrant modifier, there is nowhere to perform a reentrancy attack.
        payoutAssets_ = __parseRedemptionPayoutAssets(
            vaultProxyContract.getTrackedAssets(),
            _additionalAssets,
            _assetsToSkip
        );
        require(payoutAssets_.length > 0, "__redeemShares: No payout assets");

        // Destroy the shares.
        // Must get the shares supply before doing so.
        uint256 sharesSupply = sharesContract.totalSupply();
        vaultProxyContract.burnShares(_redeemer, _sharesQuantity);

        // Calculate and transfer payout asset amounts due to redeemer
        payoutAmounts_ = new uint256[](payoutAssets_.length);
        address denominationAssetCopy = denominationAsset;
        for (uint256 i; i < payoutAssets_.length; i++) {
            uint256 assetBalance = __finalizeIfSynthAndGetAssetBalance(
                address(vaultProxyContract),
                payoutAssets_[i],
                true
            );

            // If all remaining shares are being redeemed, the logic changes slightly
            if (_sharesQuantity == sharesSupply) {
                payoutAmounts_[i] = assetBalance;
                // Remove every tracked asset, except the denomination asset
                if (payoutAssets_[i] != denominationAssetCopy) {
                    vaultProxyContract.removeTrackedAsset(payoutAssets_[i]);
                }
            } else {
                payoutAmounts_[i] = assetBalance.mul(_sharesQuantity).div(sharesSupply);
            }

            // Transfer payout asset to redeemer
            if (payoutAmounts_[i] > 0) {
                vaultProxyContract.withdrawAssetTo(payoutAssets_[i], _redeemer, payoutAmounts_[i]);
            }
        }

        emit SharesRedeemed(_redeemer, _sharesQuantity, payoutAssets_, payoutAmounts_);

        return (payoutAssets_, payoutAmounts_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `denominationAsset` variable
    /// @return denominationAsset_ The `denominationAsset` variable value
    function getDenominationAsset() external view override returns (address denominationAsset_) {
        return denominationAsset;
    }

    /// @notice Gets the routes for the various contracts used by all funds
    /// @return dispatcher_ The `DISPATCHER` variable value
    /// @return feeManager_ The `FEE_MANAGER` variable value
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    /// @return integrationManager_ The `INTEGRATION_MANAGER` variable value
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    /// @return primitivePriceFeed_ The `PRIMITIVE_PRICE_FEED` variable value
    /// @return valueInterpreter_ The `VALUE_INTERPRETER` variable value
    function getLibRoutes()
        external
        view
        returns (
            address dispatcher_,
            address feeManager_,
            address fundDeployer_,
            address integrationManager_,
            address policyManager_,
            address primitivePriceFeed_,
            address valueInterpreter_
        )
    {
        return (
            DISPATCHER,
            FEE_MANAGER,
            FUND_DEPLOYER,
            INTEGRATION_MANAGER,
            POLICY_MANAGER,
            PRIMITIVE_PRICE_FEED,
            VALUE_INTERPRETER
        );
    }

    /// @notice Gets the `overridePause` variable
    /// @return overridePause_ The `overridePause` variable value
    function getOverridePause() external view returns (bool overridePause_) {
        return overridePause;
    }

    /// @notice Gets the `sharesActionTimelock` variable
    /// @return sharesActionTimelock_ The `sharesActionTimelock` variable value
    function getSharesActionTimelock() external view returns (uint256 sharesActionTimelock_) {
        return sharesActionTimelock;
    }

    /// @notice Gets the `vaultProxy` variable
    /// @return vaultProxy_ The `vaultProxy` variable value
    function getVaultProxy() external view override returns (address vaultProxy_) {
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../persistent/dispatcher/IDispatcher.sol";
import "../../../../persistent/vault/VaultLibBase1.sol";
import "./IVault.sol";

/// @title VaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The per-release proxiable library contract for VaultProxy
/// @dev The difference in terminology between "asset" and "trackedAsset" is intentional.
/// A fund might actually have asset balances of un-tracked assets,
/// but only tracked assets are used in gav calculations.
/// Note that this contract inherits VaultLibSafeMath (a verbatim Open Zeppelin SafeMath copy)
/// from SharesTokenBase via VaultLibBase1
contract VaultLib is VaultLibBase1, IVault {
    using SafeERC20 for ERC20;

    // Before updating TRACKED_ASSETS_LIMIT in the future, it is important to consider:
    // 1. The highest tracked assets limit ever allowed in the protocol
    // 2. That the next value will need to be respected by all future releases
    uint256 private constant TRACKED_ASSETS_LIMIT = 20;

    modifier onlyAccessor() {
        require(msg.sender == accessor, "Only the designated accessor can make this call");
        _;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Sets the account that is allowed to migrate a fund to new releases
    /// @param _nextMigrator The account to set as the allowed migrator
    /// @dev Set to address(0) to remove the migrator.
    function setMigrator(address _nextMigrator) external {
        require(msg.sender == owner, "setMigrator: Only the owner can call this function");
        address prevMigrator = migrator;
        require(_nextMigrator != prevMigrator, "setMigrator: Value already set");

        migrator = _nextMigrator;

        emit MigratorSet(prevMigrator, _nextMigrator);
    }

    ///////////
    // VAULT //
    ///////////

    /// @notice Adds a tracked asset to the fund
    /// @param _asset The asset to add
    /// @dev Allows addition of already tracked assets to fail silently.
    function addTrackedAsset(address _asset) external override onlyAccessor {
        if (!isTrackedAsset(_asset)) {
            require(
                trackedAssets.length < TRACKED_ASSETS_LIMIT,
                "addTrackedAsset: Limit exceeded"
            );

            assetToIsTracked[_asset] = true;
            trackedAssets.push(_asset);

            emit TrackedAssetAdded(_asset);
        }
    }

    /// @notice Grants an allowance to a spender to use the fund's asset
    /// @param _asset The asset for which to grant an allowance
    /// @param _target The spender of the allowance
    /// @param _amount The amount of the allowance
    function approveAssetSpender(
        address _asset,
        address _target,
        uint256 _amount
    ) external override onlyAccessor {
        ERC20(_asset).approve(_target, _amount);
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

    /// @notice Removes a tracked asset from the fund
    /// @param _asset The asset to remove
    function removeTrackedAsset(address _asset) external override onlyAccessor {
        __removeTrackedAsset(_asset);
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
        ERC20(_asset).safeTransfer(_target, _amount);

        emit AssetWithdrawn(_asset, _target, _amount);
    }

    /// @dev Helper to the get the Vault's balance of a given asset
    function __getAssetBalance(address _asset) private view returns (uint256 balance_) {
        return ERC20(_asset).balanceOf(address(this));
    }

    /// @dev Helper to remove an asset from a fund's tracked assets.
    /// Allows removal of non-tracked asset to fail silently.
    function __removeTrackedAsset(address _asset) private {
        if (isTrackedAsset(_asset)) {
            assetToIsTracked[_asset] = false;

            uint256 trackedAssetsCount = trackedAssets.length;
            for (uint256 i = 0; i < trackedAssetsCount; i++) {
                if (trackedAssets[i] == _asset) {
                    if (i < trackedAssetsCount - 1) {
                        trackedAssets[i] = trackedAssets[trackedAssetsCount - 1];
                    }
                    trackedAssets.pop();
                    break;
                }
            }

            emit TrackedAssetRemoved(_asset);
        }
    }

    ////////////
    // SHARES //
    ////////////

    /// @notice Burns fund shares from a particular account
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to burn
    function burnShares(address _target, uint256 _amount) external override onlyAccessor {
        __burn(_target, _amount);
    }

    /// @notice Mints fund shares to a particular account
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to mint
    function mintShares(address _target, uint256 _amount) external override onlyAccessor {
        __mint(_target, _amount);
    }

    /// @notice Transfers fund shares from one account to another
    /// @param _from The account from which to transfer shares
    /// @param _to The account to which to transfer shares
    /// @param _amount The amount of shares to transfer
    function transferShares(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyAccessor {
        __transfer(_from, _to, _amount);
    }

    // ERC20 overrides

    /// @dev Disallows the standard ERC20 approve() function
    function approve(address, uint256) public override returns (bool) {
        revert("Unimplemented");
    }

    /// @notice Gets the `symbol` value of the shares token
    /// @return symbol_ The `symbol` value
    /// @dev Defers the shares symbol value to the Dispatcher contract
    function symbol() public view override returns (string memory symbol_) {
        return IDispatcher(creator).getSharesTokenSymbol();
    }

    /// @dev Disallows the standard ERC20 transfer() function
    function transfer(address, uint256) public override returns (bool) {
        revert("Unimplemented");
    }

    /// @dev Disallows the standard ERC20 transferFrom() function
    function transferFrom(
        address,
        address,
        uint256
    ) public override returns (bool) {
        revert("Unimplemented");
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `accessor` variable
    /// @return accessor_ The `accessor` variable value
    function getAccessor() external view override returns (address accessor_) {
        return accessor;
    }

    /// @notice Gets the `creator` variable
    /// @return creator_ The `creator` variable value
    function getCreator() external view returns (address creator_) {
        return creator;
    }

    /// @notice Gets the `migrator` variable
    /// @return migrator_ The `migrator` variable value
    function getMigrator() external view returns (address migrator_) {
        return migrator;
    }

    /// @notice Gets the `owner` variable
    /// @return owner_ The `owner` variable value
    function getOwner() external view override returns (address owner_) {
        return owner;
    }

    /// @notice Gets the `trackedAssets` variable
    /// @return trackedAssets_ The `trackedAssets` variable value
    function getTrackedAssets() external view override returns (address[] memory trackedAssets_) {
        return trackedAssets;
    }

    /// @notice Check whether an address is a tracked asset of the fund
    /// @param _asset The address to check
    /// @return isTrackedAsset_ True if the address is a tracked asset of the fund
    function isTrackedAsset(address _asset) public view override returns (bool isTrackedAsset_) {
        return assetToIsTracked[_asset];
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
import "../price-feeds/derivatives/IAggregatedDerivativePriceFeed.sol";
import "../price-feeds/derivatives/IDerivativePriceFeed.sol";
import "../price-feeds/primitives/IPrimitivePriceFeed.sol";
import "./IValueInterpreter.sol";

/// @title ValueInterpreter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Interprets price feeds to provide covert value between asset pairs
/// @dev This contract contains several "live" value calculations, which for this release are simply
/// aliases to their "canonical" value counterparts since the only primitive price feed (Chainlink)
/// is immutable in this contract and only has one type of value. Including the "live" versions of
/// functions only serves as a placeholder for infrastructural components and plugins (e.g., policies)
/// to explicitly define the types of values that they should (and will) be using in a future release.
contract ValueInterpreter is IValueInterpreter {
    using SafeMath for uint256;

    address private immutable AGGREGATED_DERIVATIVE_PRICE_FEED;
    address private immutable PRIMITIVE_PRICE_FEED;

    constructor(address _primitivePriceFeed, address _aggregatedDerivativePriceFeed) public {
        AGGREGATED_DERIVATIVE_PRICE_FEED = _aggregatedDerivativePriceFeed;
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
    }

    // EXTERNAL FUNCTIONS

    /// @notice An alias of calcCanonicalAssetsTotalValue
    function calcLiveAssetsTotalValue(
        address[] calldata _baseAssets,
        uint256[] calldata _amounts,
        address _quoteAsset
    ) external override returns (uint256 value_, bool isValid_) {
        return calcCanonicalAssetsTotalValue(_baseAssets, _amounts, _quoteAsset);
    }

    /// @notice An alias of calcCanonicalAssetValue
    function calcLiveAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external override returns (uint256 value_, bool isValid_) {
        return calcCanonicalAssetValue(_baseAsset, _amount, _quoteAsset);
    }

    // PUBLIC FUNCTIONS

    /// @notice Calculates the total value of given amounts of assets in a single quote asset
    /// @param _baseAssets The assets to convert
    /// @param _amounts The amounts of the _baseAssets to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return value_ The sum value of _baseAssets, denominated in the _quoteAsset
    /// @return isValid_ True if the price feed rates used to derive value are all valid
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetsTotalValue(
        address[] memory _baseAssets,
        uint256[] memory _amounts,
        address _quoteAsset
    ) public override returns (uint256 value_, bool isValid_) {
        require(
            _baseAssets.length == _amounts.length,
            "calcCanonicalAssetsTotalValue: Arrays unequal lengths"
        );
        require(
            IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).isSupportedAsset(_quoteAsset),
            "calcCanonicalAssetsTotalValue: Unsupported _quoteAsset"
        );

        isValid_ = true;
        for (uint256 i; i < _baseAssets.length; i++) {
            (uint256 assetValue, bool assetValueIsValid) = __calcAssetValue(
                _baseAssets[i],
                _amounts[i],
                _quoteAsset
            );
            value_ = value_.add(assetValue);
            if (!assetValueIsValid) {
                isValid_ = false;
            }
        }

        return (value_, isValid_);
    }

    /// @notice Calculates the value of a given amount of one asset in terms of another asset
    /// @param _baseAsset The asset from which to convert
    /// @param _amount The amount of the _baseAsset to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return value_ The equivalent quantity in the _quoteAsset
    /// @return isValid_ True if the price feed rates used to derive value are all valid
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) public override returns (uint256 value_, bool isValid_) {
        if (_baseAsset == _quoteAsset || _amount == 0) {
            return (_amount, true);
        }

        require(
            IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).isSupportedAsset(_quoteAsset),
            "calcCanonicalAssetValue: Unsupported _quoteAsset"
        );

        return __calcAssetValue(_baseAsset, _amount, _quoteAsset);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to differentially calculate an asset value
    /// based on if it is a primitive or derivative asset.
    function __calcAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) private returns (uint256 value_, bool isValid_) {
        if (_baseAsset == _quoteAsset || _amount == 0) {
            return (_amount, true);
        }

        // Handle case that asset is a primitive
        if (IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).isSupportedAsset(_baseAsset)) {
            return
                IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).calcCanonicalValue(
                    _baseAsset,
                    _amount,
                    _quoteAsset
                );
        }

        // Handle case that asset is a derivative
        address derivativePriceFeed = IAggregatedDerivativePriceFeed(
            AGGREGATED_DERIVATIVE_PRICE_FEED
        )
            .getPriceFeedForDerivative(_baseAsset);
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
    ) private returns (uint256 value_, bool isValid_) {
        (address[] memory underlyings, uint256[] memory underlyingAmounts) = IDerivativePriceFeed(
            _derivativePriceFeed
        )
            .calcUnderlyingValues(_derivative, _amount);

        require(underlyings.length > 0, "__calcDerivativeValue: No underlyings");
        require(
            underlyings.length == underlyingAmounts.length,
            "__calcDerivativeValue: Arrays unequal lengths"
        );

        // Let validity be negated if any of the underlying value calculations are invalid
        isValid_ = true;
        for (uint256 i = 0; i < underlyings.length; i++) {
            (uint256 underlyingValue, bool underlyingValueIsValid) = __calcAssetValue(
                underlyings[i],
                underlyingAmounts[i],
                _quoteAsset
            );

            if (!underlyingValueIsValid) {
                isValid_ = false;
            }
            value_ = value_.add(underlyingValue);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `AGGREGATED_DERIVATIVE_PRICE_FEED` variable
    /// @return aggregatedDerivativePriceFeed_ The `AGGREGATED_DERIVATIVE_PRICE_FEED` variable value
    function getAggregatedDerivativePriceFeed()
        external
        view
        returns (address aggregatedDerivativePriceFeed_)
    {
        return AGGREGATED_DERIVATIVE_PRICE_FEED;
    }

    /// @notice Gets the `PRIMITIVE_PRICE_FEED` variable
    /// @return primitivePriceFeed_ The `PRIMITIVE_PRICE_FEED` variable value
    function getPrimitivePriceFeed() external view returns (address primitivePriceFeed_) {
        return PRIMITIVE_PRICE_FEED;
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
pragma experimental ABIEncoderV2;

/// @title FeeManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the FeeManager
interface IFeeManager {
    // No fees for the current release are implemented post-redeemShares
    enum FeeHook {
        Continuous,
        BuySharesSetup,
        PreBuyShares,
        PostBuyShares,
        BuySharesCompleted,
        PreRedeemShares
    }
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

/// @title IPrimitivePriceFeed Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for primitive price feeds
interface IPrimitivePriceFeed {
    function calcCanonicalValue(
        address,
        uint256,
        address
    ) external view returns (uint256, bool);

    function calcLiveValue(
        address,
        uint256,
        address
    ) external view returns (uint256, bool);

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

/// @title IValueInterpreter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for ValueInterpreter
interface IValueInterpreter {
    function calcCanonicalAssetValue(
        address,
        uint256,
        address
    ) external returns (uint256, bool);

    function calcCanonicalAssetsTotalValue(
        address[] calldata,
        uint256[] calldata,
        address
    ) external returns (uint256, bool);

    function calcLiveAssetValue(
        address,
        uint256,
        address
    ) external returns (uint256, bool);

    function calcLiveAssetsTotalValue(
        address[] calldata,
        uint256[] calldata,
        address
    ) external returns (uint256, bool);
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
import "../infrastructure/price-feeds/derivatives/feeds/SynthetixPriceFeed.sol";
import "../interfaces/ISynthetixAddressResolver.sol";
import "../interfaces/ISynthetixExchanger.sol";

/// @title AssetFinalityResolver Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that helps achieve asset finality
abstract contract AssetFinalityResolver {
    address internal immutable SYNTHETIX_ADDRESS_RESOLVER;
    address internal immutable SYNTHETIX_PRICE_FEED;

    constructor(address _synthetixPriceFeed, address _synthetixAddressResolver) public {
        SYNTHETIX_ADDRESS_RESOLVER = _synthetixAddressResolver;
        SYNTHETIX_PRICE_FEED = _synthetixPriceFeed;
    }

    /// @dev Helper to finalize a Synth balance at a given target address and return its balance
    function __finalizeIfSynthAndGetAssetBalance(
        address _target,
        address _asset,
        bool _requireFinality
    ) internal returns (uint256 assetBalance_) {
        bytes32 currencyKey = SynthetixPriceFeed(SYNTHETIX_PRICE_FEED).getCurrencyKeyForSynth(
            _asset
        );
        if (currencyKey != 0) {
            address synthetixExchanger = ISynthetixAddressResolver(SYNTHETIX_ADDRESS_RESOLVER)
                .requireAndGetAddress(
                "Exchanger",
                "finalizeAndGetAssetBalance: Missing Exchanger"
            );
            try ISynthetixExchanger(synthetixExchanger).settle(_target, currencyKey)  {} catch {
                require(!_requireFinality, "finalizeAndGetAssetBalance: Cannot settle Synth");
            }
        }

        return ERC20(_asset).balanceOf(_target);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `SYNTHETIX_ADDRESS_RESOLVER` variable
    /// @return synthetixAddressResolver_ The `SYNTHETIX_ADDRESS_RESOLVER` variable value
    function getSynthetixAddressResolver()
        external
        view
        returns (address synthetixAddressResolver_)
    {
        return SYNTHETIX_ADDRESS_RESOLVER;
    }

    /// @notice Gets the `SYNTHETIX_PRICE_FEED` variable
    /// @return synthetixPriceFeed_ The `SYNTHETIX_PRICE_FEED` variable value
    function getSynthetixPriceFeed() external view returns (address synthetixPriceFeed_) {
        return SYNTHETIX_PRICE_FEED;
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
import "../../../../interfaces/ISynthetix.sol";
import "../../../../interfaces/ISynthetixAddressResolver.sol";
import "../../../../interfaces/ISynthetixExchangeRates.sol";
import "../../../../interfaces/ISynthetixProxyERC20.sol";
import "../../../../interfaces/ISynthetixSynth.sol";
import "../../../utils/DispatcherOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title SynthetixPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice A price feed that uses Synthetix oracles as price sources
contract SynthetixPriceFeed is IDerivativePriceFeed, DispatcherOwnerMixin {
    using SafeMath for uint256;

    event SynthAdded(address indexed synth, bytes32 currencyKey);

    event SynthCurrencyKeyUpdated(
        address indexed synth,
        bytes32 prevCurrencyKey,
        bytes32 nextCurrencyKey
    );

    uint256 private constant SYNTH_UNIT = 10**18;
    address private immutable ADDRESS_RESOLVER;
    address private immutable SUSD;

    mapping(address => bytes32) private synthToCurrencyKey;

    constructor(
        address _dispatcher,
        address _addressResolver,
        address _sUSD,
        address[] memory _synths
    ) public DispatcherOwnerMixin(_dispatcher) {
        ADDRESS_RESOLVER = _addressResolver;
        SUSD = _sUSD;

        address[] memory sUSDSynths = new address[](1);
        sUSDSynths[0] = _sUSD;

        __addSynths(sUSDSynths);
        __addSynths(_synths);
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
        underlyings_[0] = SUSD;
        underlyingAmounts_ = new uint256[](1);

        bytes32 currencyKey = getCurrencyKeyForSynth(_derivative);
        require(currencyKey != 0, "calcUnderlyingValues: _derivative is not supported");

        address exchangeRates = ISynthetixAddressResolver(ADDRESS_RESOLVER).requireAndGetAddress(
            "ExchangeRates",
            "calcUnderlyingValues: Missing ExchangeRates"
        );

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
    function addSynths(address[] calldata _synths) external onlyDispatcherOwner {
        require(_synths.length > 0, "addSynths: Empty _synths");

        __addSynths(_synths);
    }

    /// @notice Updates the cached currencyKey value for specified Synths
    /// @param _synths Synths to update
    /// @dev Anybody can call this function
    function updateSynthCurrencyKeys(address[] calldata _synths) external {
        require(_synths.length > 0, "updateSynthCurrencyKeys: Empty _synths");

        for (uint256 i; i < _synths.length; i++) {
            bytes32 prevCurrencyKey = synthToCurrencyKey[_synths[i]];
            require(prevCurrencyKey != 0, "updateSynthCurrencyKeys: Synth not set");

            bytes32 nextCurrencyKey = __getCurrencyKey(_synths[i]);
            require(
                nextCurrencyKey != prevCurrencyKey,
                "updateSynthCurrencyKeys: Synth has correct currencyKey"
            );

            synthToCurrencyKey[_synths[i]] = nextCurrencyKey;

            emit SynthCurrencyKeyUpdated(_synths[i], prevCurrencyKey, nextCurrencyKey);
        }
    }

    /// @dev Helper to add Synths
    function __addSynths(address[] memory _synths) private {
        for (uint256 i; i < _synths.length; i++) {
            require(synthToCurrencyKey[_synths[i]] == 0, "__addSynths: Value already set");

            bytes32 currencyKey = __getCurrencyKey(_synths[i]);
            require(currencyKey != 0, "__addSynths: No currencyKey");

            synthToCurrencyKey[_synths[i]] = currencyKey;

            emit SynthAdded(_synths[i], currencyKey);
        }
    }

    /// @dev Helper to query a currencyKey from Synthetix
    function __getCurrencyKey(address _synthProxy) private view returns (bytes32 currencyKey_) {
        return ISynthetixSynth(ISynthetixProxyERC20(_synthProxy).target()).currencyKey();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ADDRESS_RESOLVER` variable
    /// @return addressResolver_ The `ADDRESS_RESOLVER` variable value
    function getAddressResolver() external view returns (address) {
        return ADDRESS_RESOLVER;
    }

    /// @notice Gets the currencyKey for multiple given Synths
    /// @return currencyKeys_ The currencyKey values
    function getCurrencyKeysForSynths(address[] calldata _synths)
        external
        view
        returns (bytes32[] memory currencyKeys_)
    {
        currencyKeys_ = new bytes32[](_synths.length);
        for (uint256 i; i < _synths.length; i++) {
            currencyKeys_[i] = synthToCurrencyKey[_synths[i]];
        }

        return currencyKeys_;
    }

    /// @notice Gets the `SUSD` variable
    /// @return susd_ The `SUSD` variable value
    function getSUSD() external view returns (address susd_) {
        return SUSD;
    }

    /// @notice Gets the currencyKey for a given Synth
    /// @return currencyKey_ The currencyKey value
    function getCurrencyKeyForSynth(address _synth) public view returns (bytes32 currencyKey_) {
        return synthToCurrencyKey[_synth];
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

import "../../../persistent/dispatcher/IDispatcher.sol";

/// @title DispatcherOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract that defers ownership to the owner of Dispatcher
abstract contract DispatcherOwnerMixin {
    address internal immutable DISPATCHER;

    modifier onlyDispatcherOwner() {
        require(
            msg.sender == getOwner(),
            "onlyDispatcherOwner: Only the Dispatcher owner can call this function"
        );
        _;
    }

    constructor(address _dispatcher) public {
        DISPATCHER = _dispatcher;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the Dispatcher contract
    function getOwner() public view returns (address owner_) {
        return IDispatcher(DISPATCHER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() external view returns (address dispatcher_) {
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

import "../utils/IMigratableVault.sol";
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

pragma solidity 0.6.12;

import "./IDerivativePriceFeed.sol";

/// @title IDerivativePriceFeed Interface
/// @author Enzyme Council <[email protected]>
interface IAggregatedDerivativePriceFeed is IDerivativePriceFeed {
    function getPriceFeedForDerivative(address) external view returns (address);
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
import "../../../../utils/MathHelpers.sol";
import "../../../utils/DispatcherOwnerMixin.sol";
import "../../../value-interpreter/ValueInterpreter.sol";
import "../../primitives/IPrimitivePriceFeed.sol";
import "../../utils/UniswapV2PoolTokenValueCalculator.sol";
import "../IDerivativePriceFeed.sol";

/// @title UniswapV2PoolPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed for Uniswap lending pool tokens
contract UniswapV2PoolPriceFeed is
    IDerivativePriceFeed,
    DispatcherOwnerMixin,
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
    address private immutable DERIVATIVE_PRICE_FEED;
    address private immutable FACTORY;
    address private immutable PRIMITIVE_PRICE_FEED;
    address private immutable VALUE_INTERPRETER;

    mapping(address => PoolTokenInfo) private poolTokenToInfo;

    constructor(
        address _dispatcher,
        address _derivativePriceFeed,
        address _primitivePriceFeed,
        address _valueInterpreter,
        address _factory,
        address[] memory _poolTokens
    ) public DispatcherOwnerMixin(_dispatcher) {
        DERIVATIVE_PRICE_FEED = _derivativePriceFeed;
        FACTORY = _factory;
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
        VALUE_INTERPRETER = _valueInterpreter;

        __addPoolTokens(_poolTokens, _derivativePriceFeed, _primitivePriceFeed);
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
        bool rateIsValid;
        // The quote asset of the value lookup must be a supported primitive asset,
        // so we cycle through the tokens until reaching a primitive.
        // If neither is a primitive, will revert at the ValueInterpreter
        if (IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).isSupportedAsset(_token0)) {
            token1RateAmount_ = 10**_token1Decimals;
            (token0RateAmount_, rateIsValid) = ValueInterpreter(VALUE_INTERPRETER)
                .calcCanonicalAssetValue(_token1, token1RateAmount_, _token0);
        } else {
            token0RateAmount_ = 10**_token0Decimals;
            (token1RateAmount_, rateIsValid) = ValueInterpreter(VALUE_INTERPRETER)
                .calcCanonicalAssetValue(_token0, token0RateAmount_, _token1);
        }

        require(rateIsValid, "__calcTrustedRate: Invalid rate");

        return (token0RateAmount_, token1RateAmount_);
    }

    //////////////////////////
    // POOL TOKENS REGISTRY //
    //////////////////////////

    /// @notice Adds Uniswap pool tokens to the price feed
    /// @param _poolTokens Uniswap pool tokens to add
    function addPoolTokens(address[] calldata _poolTokens) external onlyDispatcherOwner {
        require(_poolTokens.length > 0, "addPoolTokens: Empty _poolTokens");

        __addPoolTokens(_poolTokens, DERIVATIVE_PRICE_FEED, PRIMITIVE_PRICE_FEED);
    }

    /// @dev Helper to add Uniswap pool tokens
    function __addPoolTokens(
        address[] memory _poolTokens,
        address _derivativePriceFeed,
        address _primitivePriceFeed
    ) private {
        for (uint256 i; i < _poolTokens.length; i++) {
            require(_poolTokens[i] != address(0), "__addPoolTokens: Empty poolToken");
            require(
                poolTokenToInfo[_poolTokens[i]].token0 == address(0),
                "__addPoolTokens: Value already set"
            );

            IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(_poolTokens[i]);
            address token0 = uniswapV2Pair.token0();
            address token1 = uniswapV2Pair.token1();

            require(
                __poolTokenIsSupportable(
                    _derivativePriceFeed,
                    _primitivePriceFeed,
                    token0,
                    token1
                ),
                "__addPoolTokens: Unsupported pool token"
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
    function __poolTokenIsSupportable(
        address _derivativePriceFeed,
        address _primitivePriceFeed,
        address _token0,
        address _token1
    ) private view returns (bool isSupportable_) {
        IDerivativePriceFeed derivativePriceFeedContract = IDerivativePriceFeed(
            _derivativePriceFeed
        );
        IPrimitivePriceFeed primitivePriceFeedContract = IPrimitivePriceFeed(_primitivePriceFeed);

        if (primitivePriceFeedContract.isSupportedAsset(_token0)) {
            if (
                primitivePriceFeedContract.isSupportedAsset(_token1) ||
                derivativePriceFeedContract.isSupportedAsset(_token1)
            ) {
                return true;
            }
        } else if (
            derivativePriceFeedContract.isSupportedAsset(_token0) &&
            primitivePriceFeedContract.isSupportedAsset(_token1)
        ) {
            return true;
        }

        return false;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DERIVATIVE_PRICE_FEED` variable value
    /// @return derivativePriceFeed_ The `DERIVATIVE_PRICE_FEED` variable value
    function getDerivativePriceFeed() external view returns (address derivativePriceFeed_) {
        return DERIVATIVE_PRICE_FEED;
    }

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

    /// @notice Gets the `PRIMITIVE_PRICE_FEED` variable value
    /// @return primitivePriceFeed_ The `PRIMITIVE_PRICE_FEED` variable value
    function getPrimitivePriceFeed() external view returns (address primitivePriceFeed_) {
        return PRIMITIVE_PRICE_FEED;
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

/// @title ManagementFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice A management fee with a configurable annual rate
contract ManagementFee is FeeBase, MakerDaoMath {
    using SafeMath for uint256;

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
        if (VaultLib(_vaultProxy).totalSupply() > 0) {
            comptrollerProxyToFeeInfo[_comptrollerProxy].lastSettled = block.timestamp;
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
        uint256 scaledPerSecondRate = abi.decode(_settingsData, (uint256));
        require(
            scaledPerSecondRate > 0,
            "addFundSettings: scaledPerSecondRate must be greater than 0"
        );

        comptrollerProxyToFeeInfo[_comptrollerProxy] = FeeInfo({
            scaledPerSecondRate: scaledPerSecondRate,
            lastSettled: 0
        });

        emit FundSettingsAdded(_comptrollerProxy, scaledPerSecondRate);
    }

    /// @notice Provides a constant string identifier for a fee
    /// @return identifier_ The identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "MANAGEMENT";
    }

    /// @notice Gets the hooks that are implemented by the fee
    /// @return implementedHooksForSettle_ The hooks during which settle() is implemented
    /// @return implementedHooksForUpdate_ The hooks during which update() is implemented
    /// @return usesGavOnSettle_ True if GAV is used during the settle() implementation
    /// @return usesGavOnUpdate_ True if GAV is used during the update() implementation
    /// @dev Used only during fee registration
    function implementedHooks()
        external
        view
        override
        returns (
            IFeeManager.FeeHook[] memory implementedHooksForSettle_,
            IFeeManager.FeeHook[] memory implementedHooksForUpdate_,
            bool usesGavOnSettle_,
            bool usesGavOnUpdate_
        )
    {
        implementedHooksForSettle_ = new IFeeManager.FeeHook[](3);
        implementedHooksForSettle_[0] = IFeeManager.FeeHook.Continuous;
        implementedHooksForSettle_[1] = IFeeManager.FeeHook.BuySharesSetup;
        implementedHooksForSettle_[2] = IFeeManager.FeeHook.PreRedeemShares;

        return (implementedHooksForSettle_, new IFeeManager.FeeHook[](0), false, false);
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
        VaultLib vaultProxyContract = VaultLib(_vaultProxy);
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

    /// @notice Helper to parse settlement arguments from encoded data for PreBuyShares fee hook
    function __decodePreBuySharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (
            address buyer_,
            uint256 investmentAmount_,
            uint256 minSharesQuantity_
        )
    {
        return abi.decode(_settlementData, (address, uint256, uint256));
    }

    /// @notice Helper to parse settlement arguments from encoded data for PreRedeemShares fee hook
    function __decodePreRedeemSharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (address redeemer_, uint256 sharesQuantity_)
    {
        return abi.decode(_settlementData, (address, uint256));
    }

    /// @notice Helper to parse settlement arguments from encoded data for PostBuyShares fee hook
    function __decodePostBuySharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (
            address buyer_,
            uint256 investmentAmount_,
            uint256 sharesBought_
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

import "./IFeeManager.sol";

/// @title Fee Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all fees
interface IFee {
    function activateForFund(address _comptrollerProxy, address _vaultProxy) external;

    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData) external;

    function identifier() external pure returns (string memory identifier_);

    function implementedHooks()
        external
        view
        returns (
            IFeeManager.FeeHook[] memory implementedHooksForSettle_,
            IFeeManager.FeeHook[] memory implementedHooksForUpdate_,
            bool usesGavOnSettle_,
            bool usesGavOnUpdate_
        );

    function payout(address _comptrollerProxy, address _vaultProxy)
        external
        returns (bool isPayable_);

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

    function update(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../core/fund/comptroller/ComptrollerLib.sol";
import "../FeeManager.sol";
import "./utils/FeeBase.sol";

/// @title PerformanceFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice A performance-based fee with configurable rate and crystallization period, using
/// a high watermark
/// @dev This contract assumes that all shares in the VaultProxy are shares outstanding,
/// which is fine for this release. Even if they are not, they are still shares that
/// are only claimable by the fund owner.
contract PerformanceFee is FeeBase {
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

    uint256 private constant RATE_DIVISOR = 10**18;
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
        (uint256 grossSharePrice, bool sharePriceIsValid) = ComptrollerLib(_comptrollerProxy)
            .calcGrossShareValue(false);
        require(sharePriceIsValid, "activateForFund: Invalid share price");

        feeInfo.highWaterMark = grossSharePrice;
        feeInfo.lastSharePrice = grossSharePrice;
        feeInfo.activated = block.timestamp;

        emit ActivatedForFund(_comptrollerProxy, grossSharePrice);
    }

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the policy for the fund
    /// @dev `highWaterMark`, `lastSharePrice`, and `activated` are set during activation
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        external
        override
        onlyFeeManager
    {
        (uint256 feeRate, uint256 feePeriod) = abi.decode(_settingsData, (uint256, uint256));
        require(feeRate > 0, "addFundSettings: feeRate must be greater than 0");
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
    }

    /// @notice Provides a constant string identifier for a fee
    /// @return identifier_ The identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "PERFORMANCE";
    }

    /// @notice Gets the hooks that are implemented by the fee
    /// @return implementedHooksForSettle_ The hooks during which settle() is implemented
    /// @return implementedHooksForUpdate_ The hooks during which update() is implemented
    /// @return usesGavOnSettle_ True if GAV is used during the settle() implementation
    /// @return usesGavOnUpdate_ True if GAV is used during the update() implementation
    /// @dev Used only during fee registration
    function implementedHooks()
        external
        view
        override
        returns (
            IFeeManager.FeeHook[] memory implementedHooksForSettle_,
            IFeeManager.FeeHook[] memory implementedHooksForUpdate_,
            bool usesGavOnSettle_,
            bool usesGavOnUpdate_
        )
    {
        implementedHooksForSettle_ = new IFeeManager.FeeHook[](3);
        implementedHooksForSettle_[0] = IFeeManager.FeeHook.Continuous;
        implementedHooksForSettle_[1] = IFeeManager.FeeHook.BuySharesSetup;
        implementedHooksForSettle_[2] = IFeeManager.FeeHook.PreRedeemShares;

        implementedHooksForUpdate_ = new IFeeManager.FeeHook[](3);
        implementedHooksForUpdate_[0] = IFeeManager.FeeHook.Continuous;
        implementedHooksForUpdate_[1] = IFeeManager.FeeHook.BuySharesCompleted;
        implementedHooksForUpdate_[2] = IFeeManager.FeeHook.PreRedeemShares;

        return (implementedHooksForSettle_, implementedHooksForUpdate_, true, true);
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

    // PUBLIC FUNCTIONS

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
            int256(RATE_DIVISOR)
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
            (, uint256 sharesDecrease) = __decodePreRedeemSharesSettlementData(_settlementData);

            // Shares have not yet been burned
            nextNetSharesSupply = nextNetSharesSupply.sub(sharesDecrease);
            if (nextNetSharesSupply == 0) {
                return denominationAssetUnit;
            }

            // Assets have not yet been withdrawn
            uint256 gavDecrease = sharesDecrease
                .mul(_gav)
                .mul(SHARE_UNIT)
                .div(totalSharesSupply)
                .div(denominationAssetUnit);

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
        // If _nextAggregateValueDue > _gav, then no shares can be created.
        // This is a known limitation of the model, which is only reached for unrealistically
        // high performance fee rates (> 100%). A revert is allowed in such a case.
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

pragma solidity ^0.6.0;

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
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../../core/fund/comptroller/IComptroller.sol";
import "../../core/fund/vault/IVault.sol";
import "../../utils/AddressArrayLib.sol";
import "../utils/ExtensionBase.sol";
import "../utils/FundDeployerOwnerMixin.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./IFee.sol";
import "./IFeeManager.sol";

/// @title FeeManager Contract
/// @author Enzyme Council <[email protected]>
/// @notice Manages fees for funds
contract FeeManager is
    IFeeManager,
    ExtensionBase,
    FundDeployerOwnerMixin,
    PermissionedVaultActionMixin
{
    using AddressArrayLib for address[];
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    event AllSharesOutstandingForcePaidForFund(
        address indexed comptrollerProxy,
        address payee,
        uint256 sharesDue
    );

    event FeeDeregistered(address indexed fee, string indexed identifier);

    event FeeEnabledForFund(
        address indexed comptrollerProxy,
        address indexed fee,
        bytes settingsData
    );

    event FeeRegistered(
        address indexed fee,
        string indexed identifier,
        FeeHook[] implementedHooksForSettle,
        FeeHook[] implementedHooksForUpdate,
        bool usesGavOnSettle,
        bool usesGavOnUpdate
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
        uint256 sharesDue
    );

    event FeesRecipientSetForFund(
        address indexed comptrollerProxy,
        address prevFeesRecipient,
        address nextFeesRecipient
    );

    EnumerableSet.AddressSet private registeredFees;
    mapping(address => bool) private feeToUsesGavOnSettle;
    mapping(address => bool) private feeToUsesGavOnUpdate;
    mapping(address => mapping(FeeHook => bool)) private feeToHookToImplementsSettle;
    mapping(address => mapping(FeeHook => bool)) private feeToHookToImplementsUpdate;

    mapping(address => address[]) private comptrollerProxyToFees;
    mapping(address => mapping(address => uint256))
        private comptrollerProxyToFeeToSharesOutstanding;

    constructor(address _fundDeployer) public FundDeployerOwnerMixin(_fundDeployer) {}

    // EXTERNAL FUNCTIONS

    /// @notice Activate already-configured fees for use in the calling fund
    function activateForFund(bool) external override {
        address vaultProxy = __setValidatedVaultProxy(msg.sender);

        address[] memory enabledFees = comptrollerProxyToFees[msg.sender];
        for (uint256 i; i < enabledFees.length; i++) {
            IFee(enabledFees[i]).activateForFund(msg.sender, vaultProxy);
        }
    }

    /// @notice Deactivate fees for a fund
    /// @dev msg.sender is validated during __invokeHook()
    function deactivateForFund() external override {
        // Settle continuous fees one last time, but without calling Fee.update()
        __invokeHook(msg.sender, IFeeManager.FeeHook.Continuous, "", 0, false);

        // Force payout of remaining shares outstanding
        __forcePayoutAllSharesOutstanding(msg.sender);

        // Clean up storage
        __deleteFundStorage(msg.sender);
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
            require(isRegisteredFee(fees[i]), "setConfigForFund: Fee is not registered");

            // Set fund config on fee
            IFee(fees[i]).addFundSettings(msg.sender, settingsData[i]);

            // Enable fee for fund
            comptrollerProxyToFees[msg.sender].push(fees[i]);

            emit FeeEnabledForFund(msg.sender, fees[i], settingsData[i]);
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

    // PRIVATE FUNCTIONS

    /// @dev Helper to destroy local storage to get gas refund,
    /// and to prevent further calls to fee manager
    function __deleteFundStorage(address _comptrollerProxy) private {
        delete comptrollerProxyToFees[_comptrollerProxy];
        delete comptrollerProxyToVaultProxy[_comptrollerProxy];
    }

    /// @dev Helper to force the payout of shares outstanding across all fees.
    /// For the current release, all shares in the VaultProxy are assumed to be
    /// shares outstanding from fees. If not, then they were sent there by mistake
    /// and are otherwise unrecoverable. We can therefore take the VaultProxy's
    /// shares balance as the totalSharesOutstanding to payout to the fund owner.
    function __forcePayoutAllSharesOutstanding(address _comptrollerProxy) private {
        address vaultProxy = getVaultProxyForFund(_comptrollerProxy);

        uint256 totalSharesOutstanding = ERC20(vaultProxy).balanceOf(vaultProxy);
        if (totalSharesOutstanding == 0) {
            return;
        }

        // Destroy any shares outstanding storage
        address[] memory fees = comptrollerProxyToFees[_comptrollerProxy];
        for (uint256 i; i < fees.length; i++) {
            delete comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][fees[i]];
        }

        // Distribute all shares outstanding to the fees recipient
        address payee = IVault(vaultProxy).getOwner();
        __transferShares(_comptrollerProxy, vaultProxy, payee, totalSharesOutstanding);

        emit AllSharesOutstandingForcePaidForFund(
            _comptrollerProxy,
            payee,
            totalSharesOutstanding
        );
    }

    /// @dev Helper to get the canonical value of GAV if not yet set and required by fee
    function __getGavAsNecessary(
        address _comptrollerProxy,
        address _fee,
        uint256 _gavOrZero
    ) private returns (uint256 gav_) {
        if (_gavOrZero == 0 && feeUsesGavOnUpdate(_fee)) {
            // Assumes that any fee that requires GAV would need to revert if invalid or not final
            bool gavIsValid;
            (gav_, gavIsValid) = IComptroller(_comptrollerProxy).calcGav(true);
            require(gavIsValid, "__getGavAsNecessary: Invalid GAV");
        } else {
            gav_ = _gavOrZero;
        }

        return gav_;
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
        address[] memory fees = comptrollerProxyToFees[_comptrollerProxy];
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

    /// @dev Helper to payout the shares outstanding for the specified fees.
    /// Does not call settle() on fees.
    /// Only callable via ComptrollerProxy.callOnExtension().
    function __payoutSharesOutstandingForFees(address _comptrollerProxy, bytes memory _callArgs)
        private
    {
        address[] memory fees = abi.decode(_callArgs, (address[]));
        address vaultProxy = getVaultProxyForFund(msg.sender);

        uint256 sharesOutstandingDue;
        for (uint256 i; i < fees.length; i++) {
            if (!IFee(fees[i]).payout(_comptrollerProxy, vaultProxy)) {
                continue;
            }


                uint256 sharesOutstandingForFee
             = comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][fees[i]];
            if (sharesOutstandingForFee == 0) {
                continue;
            }

            sharesOutstandingDue = sharesOutstandingDue.add(sharesOutstandingForFee);

            // Delete shares outstanding and distribute from VaultProxy to the fees recipient
            comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][fees[i]] = 0;

            emit SharesOutstandingPaidForFund(_comptrollerProxy, fees[i], sharesOutstandingForFee);
        }

        if (sharesOutstandingDue > 0) {
            __transferShares(
                _comptrollerProxy,
                vaultProxy,
                IVault(vaultProxy).getOwner(),
                sharesOutstandingDue
            );
        }
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
            payee = IVault(_vaultProxy).getOwner();
            __transferShares(_comptrollerProxy, payer, payee, sharesDue);
        } else if (settlementType == SettlementType.Mint) {
            payee = IVault(_vaultProxy).getOwner();
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
            if (!feeSettlesOnHook(_fees[i], _hook)) {
                continue;
            }

            gav_ = __getGavAsNecessary(_comptrollerProxy, _fees[i], gav_);

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
            if (!feeUpdatesOnHook(_fees[i], _hook)) {
                continue;
            }

            gav = __getGavAsNecessary(_comptrollerProxy, _fees[i], gav);

            IFee(_fees[i]).update(_comptrollerProxy, _vaultProxy, _hook, _settlementData, gav);
        }
    }

    ///////////////////
    // FEES REGISTRY //
    ///////////////////

    /// @notice Remove fees from the list of registered fees
    /// @param _fees Addresses of fees to be deregistered
    function deregisterFees(address[] calldata _fees) external onlyFundDeployerOwner {
        require(_fees.length > 0, "deregisterFees: _fees cannot be empty");

        for (uint256 i; i < _fees.length; i++) {
            require(isRegisteredFee(_fees[i]), "deregisterFees: fee is not registered");

            registeredFees.remove(_fees[i]);

            emit FeeDeregistered(_fees[i], IFee(_fees[i]).identifier());
        }
    }

    /// @notice Add fees to the list of registered fees
    /// @param _fees Addresses of fees to be registered
    /// @dev Stores the hooks that a fee implements and whether each implementation uses GAV,
    /// which fronts the gas for calls to check if a hook is implemented, and guarantees
    /// that these hook implementation return values do not change post-registration.
    function registerFees(address[] calldata _fees) external onlyFundDeployerOwner {
        require(_fees.length > 0, "registerFees: _fees cannot be empty");

        for (uint256 i; i < _fees.length; i++) {
            require(!isRegisteredFee(_fees[i]), "registerFees: fee already registered");

            registeredFees.add(_fees[i]);

            IFee feeContract = IFee(_fees[i]);
            (
                FeeHook[] memory implementedHooksForSettle,
                FeeHook[] memory implementedHooksForUpdate,
                bool usesGavOnSettle,
                bool usesGavOnUpdate
            ) = feeContract.implementedHooks();

            // Stores the hooks for which each fee implements settle() and update()
            for (uint256 j; j < implementedHooksForSettle.length; j++) {
                feeToHookToImplementsSettle[_fees[i]][implementedHooksForSettle[j]] = true;
            }
            for (uint256 j; j < implementedHooksForUpdate.length; j++) {
                feeToHookToImplementsUpdate[_fees[i]][implementedHooksForUpdate[j]] = true;
            }

            // Stores whether each fee requires GAV during its implementations for settle() and update()
            if (usesGavOnSettle) {
                feeToUsesGavOnSettle[_fees[i]] = true;
            }
            if (usesGavOnUpdate) {
                feeToUsesGavOnUpdate[_fees[i]] = true;
            }

            emit FeeRegistered(
                _fees[i],
                feeContract.identifier(),
                implementedHooksForSettle,
                implementedHooksForUpdate,
                usesGavOnSettle,
                usesGavOnUpdate
            );
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Get a list of enabled fees for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return enabledFees_ An array of enabled fee addresses
    function getEnabledFeesForFund(address _comptrollerProxy)
        external
        view
        returns (address[] memory enabledFees_)
    {
        return comptrollerProxyToFees[_comptrollerProxy];
    }

    /// @notice Get the amount of shares outstanding for a particular fee for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _fee The fee address
    /// @return sharesOutstanding_ The amount of shares outstanding
    function getFeeSharesOutstandingForFund(address _comptrollerProxy, address _fee)
        external
        view
        returns (uint256 sharesOutstanding_)
    {
        return comptrollerProxyToFeeToSharesOutstanding[_comptrollerProxy][_fee];
    }

    /// @notice Get all registered fees
    /// @return registeredFees_ A list of all registered fee addresses
    function getRegisteredFees() external view returns (address[] memory registeredFees_) {
        registeredFees_ = new address[](registeredFees.length());
        for (uint256 i; i < registeredFees_.length; i++) {
            registeredFees_[i] = registeredFees.at(i);
        }

        return registeredFees_;
    }

    /// @notice Checks if a fee implements settle() on a particular hook
    /// @param _fee The address of the fee to check
    /// @param _hook The FeeHook to check
    /// @return settlesOnHook_ True if the fee settles on the given hook
    function feeSettlesOnHook(address _fee, FeeHook _hook)
        public
        view
        returns (bool settlesOnHook_)
    {
        return feeToHookToImplementsSettle[_fee][_hook];
    }

    /// @notice Checks if a fee implements update() on a particular hook
    /// @param _fee The address of the fee to check
    /// @param _hook The FeeHook to check
    /// @return updatesOnHook_ True if the fee updates on the given hook
    function feeUpdatesOnHook(address _fee, FeeHook _hook)
        public
        view
        returns (bool updatesOnHook_)
    {
        return feeToHookToImplementsUpdate[_fee][_hook];
    }

    /// @notice Checks if a fee uses GAV in its settle() implementation
    /// @param _fee The address of the fee to check
    /// @return usesGav_ True if the fee uses GAV during settle() implementation
    function feeUsesGavOnSettle(address _fee) public view returns (bool usesGav_) {
        return feeToUsesGavOnSettle[_fee];
    }

    /// @notice Checks if a fee uses GAV in its update() implementation
    /// @param _fee The address of the fee to check
    /// @return usesGav_ True if the fee uses GAV during update() implementation
    function feeUsesGavOnUpdate(address _fee) public view returns (bool usesGav_) {
        return feeToUsesGavOnUpdate[_fee];
    }

    /// @notice Check whether a fee is registered
    /// @param _fee The address of the fee to check
    /// @return isRegisteredFee_ True if the fee is registered
    function isRegisteredFee(address _fee) public view returns (bool isRegisteredFee_) {
        return registeredFees.contains(_fee);
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

/// @title PermissionedVaultActionMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for extensions that can make permissioned vault calls
abstract contract PermissionedVaultActionMixin {
    /// @notice Adds a tracked asset to the fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to add
    function __addTrackedAsset(address _comptrollerProxy, address _asset) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IComptroller.VaultAction.AddTrackedAsset,
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
            IComptroller.VaultAction.ApproveAssetSpender,
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
            IComptroller.VaultAction.BurnShares,
            abi.encode(_target, _amount)
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
            IComptroller.VaultAction.MintShares,
            abi.encode(_target, _amount)
        );
    }

    /// @notice Removes a tracked asset from the fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _asset The asset to remove
    function __removeTrackedAsset(address _comptrollerProxy, address _asset) internal {
        IComptroller(_comptrollerProxy).permissionedVaultAction(
            IComptroller.VaultAction.RemoveTrackedAsset,
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
            IComptroller.VaultAction.TransferShares,
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
            IComptroller.VaultAction.WithdrawAssetTo,
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IWETH.sol";
import "../core/fund/comptroller/ComptrollerLib.sol";
import "../extensions/fee-manager/FeeManager.sol";

/// @title FundActionsWrapper Contract
/// @author Enzyme Council <[email protected]>
/// @notice Logic related to wrapping fund actions, not necessary in the core protocol
contract FundActionsWrapper {
    using SafeERC20 for ERC20;

    address private immutable FEE_MANAGER;
    address private immutable WETH_TOKEN;

    mapping(address => bool) private accountToHasMaxWethAllowance;

    constructor(address _feeManager, address _weth) public {
        FEE_MANAGER = _feeManager;
        WETH_TOKEN = _weth;
    }

    /// @dev Needed in case WETH not fully used during exchangeAndBuyShares,
    /// to unwrap into ETH and refund
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the net value of 1 unit of shares in the fund's denomination asset
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @return netShareValue_ The amount of the denomination asset per share
    /// @return isValid_ True if the conversion rates to derive the value are all valid
    /// @dev Accounts for fees outstanding. This is a convenience function for external consumption
    /// that can be used to determine the cost of purchasing shares at any given point in time.
    /// It essentially just bundles settling all fees that implement the Continuous hook and then
    /// looking up the gross share value.
    function calcNetShareValueForFund(address _comptrollerProxy)
        external
        returns (uint256 netShareValue_, bool isValid_)
    {
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);
        comptrollerProxyContract.callOnExtension(FEE_MANAGER, 0, "");

        return comptrollerProxyContract.calcGrossShareValue(false);
    }

    /// @notice Exchanges ETH into a fund's denomination asset and then buys shares
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _buyer The account for which to buy shares
    /// @param _minSharesQuantity The minimum quantity of shares to buy with the sent ETH
    /// @param _exchange The exchange on which to execute the swap to the denomination asset
    /// @param _exchangeApproveTarget The address that should be given an allowance of WETH
    /// for the given _exchange
    /// @param _exchangeData The data with which to call the exchange to execute the swap
    /// to the denomination asset
    /// @param _minInvestmentAmount The minimum amount of the denomination asset
    /// to receive in the trade for investment (not necessary for WETH)
    /// @return sharesReceivedAmount_ The actual amount of shares received
    /// @dev Use a reasonable _minInvestmentAmount always, in case the exchange
    /// does not perform as expected (low incoming asset amount, blend of assets, etc).
    /// If the fund's denomination asset is WETH, _exchange, _exchangeApproveTarget, _exchangeData,
    /// and _minInvestmentAmount will be ignored.
    function exchangeAndBuyShares(
        address _comptrollerProxy,
        address _denominationAsset,
        address _buyer,
        uint256 _minSharesQuantity,
        address _exchange,
        address _exchangeApproveTarget,
        bytes calldata _exchangeData,
        uint256 _minInvestmentAmount
    ) external payable returns (uint256 sharesReceivedAmount_) {
        // Wrap ETH into WETH
        IWETH(payable(WETH_TOKEN)).deposit{value: msg.value}();

        // If denominationAsset is WETH, can just buy shares directly
        if (_denominationAsset == WETH_TOKEN) {
            __approveMaxWethAsNeeded(_comptrollerProxy);
            return __buyShares(_comptrollerProxy, _buyer, msg.value, _minSharesQuantity);
        }

        // Exchange ETH to the fund's denomination asset
        __approveMaxWethAsNeeded(_exchangeApproveTarget);
        (bool success, bytes memory returnData) = _exchange.call(_exchangeData);
        require(success, string(returnData));

        // Confirm the amount received in the exchange is above the min acceptable amount
        uint256 investmentAmount = ERC20(_denominationAsset).balanceOf(address(this));
        require(
            investmentAmount >= _minInvestmentAmount,
            "exchangeAndBuyShares: _minInvestmentAmount not met"
        );

        // Give the ComptrollerProxy max allowance for its denomination asset as necessary
        __approveMaxAsNeeded(_denominationAsset, _comptrollerProxy, investmentAmount);

        // Buy fund shares
        sharesReceivedAmount_ = __buyShares(
            _comptrollerProxy,
            _buyer,
            investmentAmount,
            _minSharesQuantity
        );

        // Unwrap and refund any remaining WETH not used in the exchange
        uint256 remainingWeth = ERC20(WETH_TOKEN).balanceOf(address(this));
        if (remainingWeth > 0) {
            IWETH(payable(WETH_TOKEN)).withdraw(remainingWeth);
            (success, returnData) = msg.sender.call{value: remainingWeth}("");
            require(success, string(returnData));
        }

        return sharesReceivedAmount_;
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

        comptrollerProxyContract.callOnExtension(FEE_MANAGER, 0, "");
        comptrollerProxyContract.callOnExtension(FEE_MANAGER, 1, abi.encode(_fees));
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
        FeeManager feeManagerContract = FeeManager(FEE_MANAGER);

        address[] memory fees = feeManagerContract.getEnabledFeesForFund(_comptrollerProxy);

        // Count the continuous fees
        uint256 continuousFeesCount;
        bool[] memory implementsContinuousHook = new bool[](fees.length);
        for (uint256 i; i < fees.length; i++) {
            if (feeManagerContract.feeSettlesOnHook(fees[i], IFeeManager.FeeHook.Continuous)) {
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

    // PRIVATE FUNCTIONS

    /// @dev Helper to approve a target with the max amount of an asset, only when necessary
    function __approveMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if (ERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to approve a target with the max amount of weth, only when necessary.
    /// Since WETH does not decrease the allowance if it uint256(-1), only ever need to do this
    /// once per target.
    function __approveMaxWethAsNeeded(address _target) internal {
        if (!accountHasMaxWethAllowance(_target)) {
            ERC20(WETH_TOKEN).safeApprove(_target, type(uint256).max);
            accountToHasMaxWethAllowance[_target] = true;
        }
    }

    /// @dev Helper for buying shares
    function __buyShares(
        address _comptrollerProxy,
        address _buyer,
        uint256 _investmentAmount,
        uint256 _minSharesQuantity
    ) private returns (uint256 sharesReceivedAmount_) {
        address[] memory buyers = new address[](1);
        buyers[0] = _buyer;
        uint256[] memory investmentAmounts = new uint256[](1);
        investmentAmounts[0] = _investmentAmount;
        uint256[] memory minSharesQuantities = new uint256[](1);
        minSharesQuantities[0] = _minSharesQuantity;

        return
            ComptrollerLib(_comptrollerProxy).buyShares(
                buyers,
                investmentAmounts,
                minSharesQuantities
            )[0];
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FEE_MANAGER` variable
    /// @return feeManager_ The `FEE_MANAGER` variable value
    function getFeeManager() external view returns (address feeManager_) {
        return FEE_MANAGER;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
        return WETH_TOKEN;
    }

    /// @notice Checks whether an account has the max allowance for WETH
    /// @param _who The account to check
    /// @return hasMaxWethAllowance_ True if the account has the max allowance
    function accountHasMaxWethAllowance(address _who)
        public
        view
        returns (bool hasMaxWethAllowance_)
    {
        return accountToHasMaxWethAllowance[_who];
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../core/fund/comptroller/ComptrollerLib.sol";
import "../../core/fund/vault/VaultLib.sol";
import "./IAuthUserExecutedSharesRequestor.sol";

/// @title AuthUserExecutedSharesRequestorLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice Provides the logic for AuthUserExecutedSharesRequestorProxy instances,
/// in which shares requests are manually executed by a permissioned user
/// @dev This will not work with a `denominationAsset` that does not transfer
/// the exact expected amount or has an elastic supply.
contract AuthUserExecutedSharesRequestorLib is IAuthUserExecutedSharesRequestor {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    event RequestCanceled(
        address indexed requestOwner,
        uint256 investmentAmount,
        uint256 minSharesQuantity
    );

    event RequestCreated(
        address indexed requestOwner,
        uint256 investmentAmount,
        uint256 minSharesQuantity
    );

    event RequestExecuted(
        address indexed caller,
        address indexed requestOwner,
        uint256 investmentAmount,
        uint256 minSharesQuantity
    );

    event RequestExecutorAdded(address indexed account);

    event RequestExecutorRemoved(address indexed account);

    struct RequestInfo {
        uint256 investmentAmount;
        uint256 minSharesQuantity;
    }

    uint256 private constant CANCELLATION_COOLDOWN_TIMELOCK = 10 minutes;

    address private comptrollerProxy;
    address private denominationAsset;
    address private fundOwner;

    mapping(address => RequestInfo) private ownerToRequestInfo;
    mapping(address => bool) private acctToIsRequestExecutor;
    mapping(address => uint256) private ownerToLastRequestCancellation;

    modifier onlyFundOwner() {
        require(msg.sender == fundOwner, "Only fund owner callable");
        _;
    }

    /// @notice Initializes a proxy instance that uses this library
    /// @dev Serves as a per-proxy pseudo-constructor
    function init(address _comptrollerProxy) external override {
        require(comptrollerProxy == address(0), "init: Already initialized");

        comptrollerProxy = _comptrollerProxy;

        // Cache frequently-used values that require external calls
        ComptrollerLib comptrollerProxyContract = ComptrollerLib(_comptrollerProxy);
        denominationAsset = comptrollerProxyContract.getDenominationAsset();
        fundOwner = VaultLib(comptrollerProxyContract.getVaultProxy()).getOwner();
    }

    /// @notice Cancels the shares request of the caller
    function cancelRequest() external {
        RequestInfo memory request = ownerToRequestInfo[msg.sender];
        require(request.investmentAmount > 0, "cancelRequest: Request does not exist");

        // Delete the request, start the cooldown period, and return the investment asset
        delete ownerToRequestInfo[msg.sender];
        ownerToLastRequestCancellation[msg.sender] = block.timestamp;
        ERC20(denominationAsset).safeTransfer(msg.sender, request.investmentAmount);

        emit RequestCanceled(msg.sender, request.investmentAmount, request.minSharesQuantity);
    }

    /// @notice Creates a shares request for the caller
    /// @param _investmentAmount The amount of the fund's denomination asset to use to buy shares
    /// @param _minSharesQuantity The minimum quantity of shares to buy with the _investmentAmount
    function createRequest(uint256 _investmentAmount, uint256 _minSharesQuantity) external {
        require(_investmentAmount > 0, "createRequest: _investmentAmount must be > 0");
        require(
            ownerToRequestInfo[msg.sender].investmentAmount == 0,
            "createRequest: The request owner can only create one request before executed or canceled"
        );
        require(
            ownerToLastRequestCancellation[msg.sender] <
                block.timestamp.sub(CANCELLATION_COOLDOWN_TIMELOCK),
            "createRequest: Cannot create request during cancellation cooldown period"
        );

        // Create the Request and take custody of investment asset
        ownerToRequestInfo[msg.sender] = RequestInfo({
            investmentAmount: _investmentAmount,
            minSharesQuantity: _minSharesQuantity
        });
        ERC20(denominationAsset).safeTransferFrom(msg.sender, address(this), _investmentAmount);

        emit RequestCreated(msg.sender, _investmentAmount, _minSharesQuantity);
    }

    /// @notice Executes multiple shares requests
    /// @param _requestOwners The owners of the pending shares requests
    function executeRequests(address[] calldata _requestOwners) external {
        require(
            msg.sender == fundOwner || isRequestExecutor(msg.sender),
            "executeRequests: Invalid caller"
        );
        require(_requestOwners.length > 0, "executeRequests: _requestOwners can not be empty");

        (
            address[] memory buyers,
            uint256[] memory investmentAmounts,
            uint256[] memory minSharesQuantities,
            uint256 totalInvestmentAmount
        ) = __convertRequestsToBuySharesParams(_requestOwners);

        // Since ComptrollerProxy instances are fully trusted,
        // we can approve them with the max amount of the denomination asset,
        // and only top the approval back to max if ever necessary.
        address comptrollerProxyCopy = comptrollerProxy;
        ERC20 denominationAssetContract = ERC20(denominationAsset);
        if (
            denominationAssetContract.allowance(address(this), comptrollerProxyCopy) <
            totalInvestmentAmount
        ) {
            denominationAssetContract.safeApprove(comptrollerProxyCopy, type(uint256).max);
        }

        ComptrollerLib(comptrollerProxyCopy).buyShares(
            buyers,
            investmentAmounts,
            minSharesQuantities
        );
    }

    /// @dev Helper to convert raw shares requests into the format required by buyShares().
    /// It also removes any empty requests, which is necessary to prevent a DoS attack where a user
    /// cancels their request earlier in the same block (can be repeated from multiple accounts).
    /// This function also removes shares requests and fires success events as it loops through them.
    function __convertRequestsToBuySharesParams(address[] memory _requestOwners)
        private
        returns (
            address[] memory buyers_,
            uint256[] memory investmentAmounts_,
            uint256[] memory minSharesQuantities_,
            uint256 totalInvestmentAmount_
        )
    {
        uint256 existingRequestsCount = _requestOwners.length;
        uint256[] memory allInvestmentAmounts = new uint256[](_requestOwners.length);

        // Loop through once to get the count of existing requests
        for (uint256 i; i < _requestOwners.length; i++) {
            allInvestmentAmounts[i] = ownerToRequestInfo[_requestOwners[i]].investmentAmount;

            if (allInvestmentAmounts[i] == 0) {
                existingRequestsCount--;
            }
        }

        // Loop through a second time to format requests for buyShares(),
        // and to delete the requests and emit events early so no further looping is needed.
        buyers_ = new address[](existingRequestsCount);
        investmentAmounts_ = new uint256[](existingRequestsCount);
        minSharesQuantities_ = new uint256[](existingRequestsCount);
        uint256 existingRequestsIndex;
        for (uint256 i; i < _requestOwners.length; i++) {
            if (allInvestmentAmounts[i] == 0) {
                continue;
            }

            buyers_[existingRequestsIndex] = _requestOwners[i];
            investmentAmounts_[existingRequestsIndex] = allInvestmentAmounts[i];
            minSharesQuantities_[existingRequestsIndex] = ownerToRequestInfo[_requestOwners[i]]
                .minSharesQuantity;
            totalInvestmentAmount_ = totalInvestmentAmount_.add(allInvestmentAmounts[i]);

            delete ownerToRequestInfo[_requestOwners[i]];

            emit RequestExecuted(
                msg.sender,
                buyers_[existingRequestsIndex],
                investmentAmounts_[existingRequestsIndex],
                minSharesQuantities_[existingRequestsIndex]
            );

            existingRequestsIndex++;
        }

        return (buyers_, investmentAmounts_, minSharesQuantities_, totalInvestmentAmount_);
    }

    ///////////////////////////////
    // REQUEST EXECUTOR REGISTRY //
    ///////////////////////////////

    /// @notice Adds accounts to request executors
    /// @param _requestExecutors Accounts to add
    function addRequestExecutors(address[] calldata _requestExecutors) external onlyFundOwner {
        require(_requestExecutors.length > 0, "addRequestExecutors: Empty _requestExecutors");

        for (uint256 i; i < _requestExecutors.length; i++) {
            require(
                !isRequestExecutor(_requestExecutors[i]),
                "addRequestExecutors: Value already set"
            );
            require(
                _requestExecutors[i] != fundOwner,
                "addRequestExecutors: The fund owner cannot be added"
            );

            acctToIsRequestExecutor[_requestExecutors[i]] = true;

            emit RequestExecutorAdded(_requestExecutors[i]);
        }
    }

    /// @notice Removes accounts from request executors
    /// @param _requestExecutors Accounts to remove
    function removeRequestExecutors(address[] calldata _requestExecutors) external onlyFundOwner {
        require(_requestExecutors.length > 0, "removeRequestExecutors: Empty _requestExecutors");

        for (uint256 i; i < _requestExecutors.length; i++) {
            require(
                isRequestExecutor(_requestExecutors[i]),
                "removeRequestExecutors: Account is not a request executor"
            );

            acctToIsRequestExecutor[_requestExecutors[i]] = false;

            emit RequestExecutorRemoved(_requestExecutors[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the value of `comptrollerProxy` variable
    /// @return comptrollerProxy_ The `comptrollerProxy` variable value
    function getComptrollerProxy() external view returns (address comptrollerProxy_) {
        return comptrollerProxy;
    }

    /// @notice Gets the value of `denominationAsset` variable
    /// @return denominationAsset_ The `denominationAsset` variable value
    function getDenominationAsset() external view returns (address denominationAsset_) {
        return denominationAsset;
    }

    /// @notice Gets the value of `fundOwner` variable
    /// @return fundOwner_ The `fundOwner` variable value
    function getFundOwner() external view returns (address fundOwner_) {
        return fundOwner;
    }

    /// @notice Gets the request info of a user
    /// @param _requestOwner The address of the user that creates the request
    /// @return requestInfo_ The request info created by the user
    function getSharesRequestInfoForOwner(address _requestOwner)
        external
        view
        returns (RequestInfo memory requestInfo_)
    {
        return ownerToRequestInfo[_requestOwner];
    }

    /// @notice Checks whether an account is a request executor
    /// @param _who The account to check
    /// @return isRequestExecutor_ True if _who is a request executor
    function isRequestExecutor(address _who) public view returns (bool isRequestExecutor_) {
        return acctToIsRequestExecutor[_who];
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

/// @title IAuthUserExecutedSharesRequestor Interface
/// @author Enzyme Council <[email protected]>
interface IAuthUserExecutedSharesRequestor {
    function init(address) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../core/fund/comptroller/ComptrollerLib.sol";
import "../../core/fund/vault/VaultLib.sol";
import "./AuthUserExecutedSharesRequestorProxy.sol";
import "./IAuthUserExecutedSharesRequestor.sol";

/// @title AuthUserExecutedSharesRequestorFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice Deploys and maintains a record of AuthUserExecutedSharesRequestorProxy instances
contract AuthUserExecutedSharesRequestorFactory {
    event SharesRequestorProxyDeployed(
        address indexed comptrollerProxy,
        address sharesRequestorProxy
    );

    address private immutable AUTH_USER_EXECUTED_SHARES_REQUESTOR_LIB;
    address private immutable DISPATCHER;

    mapping(address => address) private comptrollerProxyToSharesRequestorProxy;

    constructor(address _dispatcher, address _authUserExecutedSharesRequestorLib) public {
        AUTH_USER_EXECUTED_SHARES_REQUESTOR_LIB = _authUserExecutedSharesRequestorLib;
        DISPATCHER = _dispatcher;
    }

    /// @notice Deploys a shares requestor proxy instance for a given ComptrollerProxy instance
    /// @param _comptrollerProxy The ComptrollerProxy for which to deploy the shares requestor proxy
    /// @return sharesRequestorProxy_ The address of the newly-deployed shares requestor proxy
    function deploySharesRequestorProxy(address _comptrollerProxy)
        external
        returns (address sharesRequestorProxy_)
    {
        // Confirm fund is genuine
        VaultLib vaultProxyContract = VaultLib(ComptrollerLib(_comptrollerProxy).getVaultProxy());
        require(
            vaultProxyContract.getAccessor() == _comptrollerProxy,
            "deploySharesRequestorProxy: Invalid VaultProxy for ComptrollerProxy"
        );
        require(
            IDispatcher(DISPATCHER).getFundDeployerForVaultProxy(address(vaultProxyContract)) !=
                address(0),
            "deploySharesRequestorProxy: Not a genuine fund"
        );

        // Validate that the caller is the fund owner
        require(
            msg.sender == vaultProxyContract.getOwner(),
            "deploySharesRequestorProxy: Only fund owner callable"
        );

        // Validate that a proxy does not already exist
        require(
            comptrollerProxyToSharesRequestorProxy[_comptrollerProxy] == address(0),
            "deploySharesRequestorProxy: Proxy already exists"
        );

        // Deploy the proxy
        bytes memory constructData = abi.encodeWithSelector(
            IAuthUserExecutedSharesRequestor.init.selector,
            _comptrollerProxy
        );
        sharesRequestorProxy_ = address(
            new AuthUserExecutedSharesRequestorProxy(
                constructData,
                AUTH_USER_EXECUTED_SHARES_REQUESTOR_LIB
            )
        );

        comptrollerProxyToSharesRequestorProxy[_comptrollerProxy] = sharesRequestorProxy_;

        emit SharesRequestorProxyDeployed(_comptrollerProxy, sharesRequestorProxy_);

        return sharesRequestorProxy_;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the value of the `AUTH_USER_EXECUTED_SHARES_REQUESTOR_LIB` variable
    /// @return authUserExecutedSharesRequestorLib_ The `AUTH_USER_EXECUTED_SHARES_REQUESTOR_LIB` variable value
    function getAuthUserExecutedSharesRequestorLib()
        external
        view
        returns (address authUserExecutedSharesRequestorLib_)
    {
        return AUTH_USER_EXECUTED_SHARES_REQUESTOR_LIB;
    }

    /// @notice Gets the value of the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() external view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the AuthUserExecutedSharesRequestorProxy associated with the given ComptrollerProxy
    /// @param _comptrollerProxy The ComptrollerProxy for which to get the associated AuthUserExecutedSharesRequestorProxy
    /// @return sharesRequestorProxy_ The associated AuthUserExecutedSharesRequestorProxy address
    function getSharesRequestorProxyForComptrollerProxy(address _comptrollerProxy)
        external
        view
        returns (address sharesRequestorProxy_)
    {
        return comptrollerProxyToSharesRequestorProxy[_comptrollerProxy];
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

import "../../utils/Proxy.sol";

contract AuthUserExecutedSharesRequestorProxy is Proxy {
    constructor(bytes memory _constructData, address _authUserExecutedSharesRequestorLib)
        public
        Proxy(_constructData, _authUserExecutedSharesRequestorLib)
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

/// @title Proxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all Proxy instances
/// @dev The recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,
/// and using the EIP-1967 storage slot for the proxiable implementation.
/// i.e., `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`, which is
/// "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
/// See: https://eips.ethereum.org/EIPS/eip-1822
contract Proxy {
    constructor(bytes memory _constructData, address _contractLogic) public {
        assembly {
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _contractLogic
            )
        }
        (bool success, bytes memory returnData) = _contractLogic.delegatecall(_constructData);
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

import "../../../utils/Proxy.sol";

/// @title ComptrollerProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all ComptrollerProxy instances
contract ComptrollerProxy is Proxy {
    constructor(bytes memory _constructData, address _comptrollerLib)
        public
        Proxy(_constructData, _comptrollerLib)
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

import "../../../persistent/dispatcher/IDispatcher.sol";
import "../../../persistent/utils/IMigrationHookHandler.sol";
import "../fund/comptroller/IComptroller.sol";
import "../fund/comptroller/ComptrollerProxy.sol";
import "../fund/vault/IVault.sol";
import "./IFundDeployer.sol";

/// @title FundDeployer Contract
/// @author Enzyme Council <[email protected]>
/// @notice The top-level contract of the release.
/// It primarily coordinates fund deployment and fund migration, but
/// it is also deferred to for contract access control and for allowed calls
/// that can be made with a fund's VaultProxy as the msg.sender.
contract FundDeployer is IFundDeployer, IMigrationHookHandler {
    event ComptrollerLibSet(address comptrollerLib);

    event ComptrollerProxyDeployed(
        address indexed creator,
        address comptrollerProxy,
        address indexed denominationAsset,
        uint256 sharesActionTimelock,
        bytes feeManagerConfigData,
        bytes policyManagerConfigData,
        bool indexed forMigration
    );

    event NewFundCreated(
        address indexed creator,
        address comptrollerProxy,
        address vaultProxy,
        address indexed fundOwner,
        string fundName,
        address indexed denominationAsset,
        uint256 sharesActionTimelock,
        bytes feeManagerConfigData,
        bytes policyManagerConfigData
    );

    event ReleaseStatusSet(ReleaseStatus indexed prevStatus, ReleaseStatus indexed nextStatus);

    event VaultCallDeregistered(address indexed contractAddress, bytes4 selector);

    event VaultCallRegistered(address indexed contractAddress, bytes4 selector);

    // Constants
    address private immutable CREATOR;
    address private immutable DISPATCHER;
    address private immutable VAULT_LIB;

    // Pseudo-constants (can only be set once)
    address private comptrollerLib;

    // Storage
    ReleaseStatus private releaseStatus;
    mapping(address => mapping(bytes4 => bool)) private contractToSelectorToIsRegisteredVaultCall;
    mapping(address => address) private pendingComptrollerProxyToCreator;

    modifier onlyLiveRelease() {
        require(releaseStatus == ReleaseStatus.Live, "Release is not Live");
        _;
    }

    modifier onlyMigrator(address _vaultProxy) {
        require(
            IVault(_vaultProxy).canMigrate(msg.sender),
            "Only a permissioned migrator can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "Only the contract owner can call this function");
        _;
    }

    modifier onlyPendingComptrollerProxyCreator(address _comptrollerProxy) {
        require(
            msg.sender == pendingComptrollerProxyToCreator[_comptrollerProxy],
            "Only the ComptrollerProxy creator can call this function"
        );
        _;
    }

    constructor(
        address _dispatcher,
        address _vaultLib,
        address[] memory _vaultCallContracts,
        bytes4[] memory _vaultCallSelectors
    ) public {
        if (_vaultCallContracts.length > 0) {
            __registerVaultCalls(_vaultCallContracts, _vaultCallSelectors);
        }
        CREATOR = msg.sender;
        DISPATCHER = _dispatcher;
        VAULT_LIB = _vaultLib;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Sets the comptrollerLib
    /// @param _comptrollerLib The ComptrollerLib contract address
    /// @dev Can only be set once
    function setComptrollerLib(address _comptrollerLib) external onlyOwner {
        require(
            comptrollerLib == address(0),
            "setComptrollerLib: This value can only be set once"
        );

        comptrollerLib = _comptrollerLib;

        emit ComptrollerLibSet(_comptrollerLib);
    }

    /// @notice Sets the status of the protocol to a new state
    /// @param _nextStatus The next status state to set
    function setReleaseStatus(ReleaseStatus _nextStatus) external {
        require(
            msg.sender == IDispatcher(DISPATCHER).getOwner(),
            "setReleaseStatus: Only the Dispatcher owner can call this function"
        );
        require(
            _nextStatus != ReleaseStatus.PreLaunch,
            "setReleaseStatus: Cannot return to PreLaunch status"
        );
        require(
            comptrollerLib != address(0),
            "setReleaseStatus: Can only set the release status when comptrollerLib is set"
        );

        ReleaseStatus prevStatus = releaseStatus;
        require(_nextStatus != prevStatus, "setReleaseStatus: _nextStatus is the current status");

        releaseStatus = _nextStatus;

        emit ReleaseStatusSet(prevStatus, _nextStatus);
    }

    /// @notice Gets the current owner of the contract
    /// @return owner_ The contract owner address
    /// @dev Dynamically gets the owner based on the Protocol status. The owner is initially the
    /// contract's deployer, for convenience in setting up configuration.
    /// Ownership is claimed when the owner of the Dispatcher contract (the Enzyme Council)
    /// sets the releaseStatus to `Live`.
    function getOwner() public view override returns (address owner_) {
        if (releaseStatus == ReleaseStatus.PreLaunch) {
            return CREATOR;
        }

        return IDispatcher(DISPATCHER).getOwner();
    }

    ///////////////////
    // FUND CREATION //
    ///////////////////

    /// @notice Creates a fully-configured ComptrollerProxy, to which a fund from a previous
    /// release can migrate in a subsequent step
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    /// @return comptrollerProxy_ The address of the ComptrollerProxy deployed during this action
    function createMigratedFundConfig(
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external onlyLiveRelease returns (address comptrollerProxy_) {
        comptrollerProxy_ = __deployComptrollerProxy(
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            true
        );

        pendingComptrollerProxyToCreator[comptrollerProxy_] = msg.sender;

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
        return
            __createNewFund(
                _fundOwner,
                _fundName,
                _denominationAsset,
                _sharesActionTimelock,
                _feeManagerConfigData,
                _policyManagerConfigData
            );
    }

    /// @dev Helper to avoid the stack-too-deep error during createNewFund
    function __createNewFund(
        address _fundOwner,
        string memory _fundName,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData
    ) private returns (address comptrollerProxy_, address vaultProxy_) {
        require(_fundOwner != address(0), "__createNewFund: _owner cannot be empty");

        comptrollerProxy_ = __deployComptrollerProxy(
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            false
        );

        vaultProxy_ = IDispatcher(DISPATCHER).deployVaultProxy(
            VAULT_LIB,
            _fundOwner,
            comptrollerProxy_,
            _fundName
        );

        IComptroller(comptrollerProxy_).activate(vaultProxy_, false);

        emit NewFundCreated(
            msg.sender,
            comptrollerProxy_,
            vaultProxy_,
            _fundOwner,
            _fundName,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData
        );

        return (comptrollerProxy_, vaultProxy_);
    }

    /// @dev Helper function to deploy a configured ComptrollerProxy
    function __deployComptrollerProxy(
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes memory _feeManagerConfigData,
        bytes memory _policyManagerConfigData,
        bool _forMigration
    ) private returns (address comptrollerProxy_) {
        require(
            _denominationAsset != address(0),
            "__deployComptrollerProxy: _denominationAsset cannot be empty"
        );

        bytes memory constructData = abi.encodeWithSelector(
            IComptroller.init.selector,
            _denominationAsset,
            _sharesActionTimelock
        );
        comptrollerProxy_ = address(new ComptrollerProxy(constructData, comptrollerLib));

        if (_feeManagerConfigData.length > 0 || _policyManagerConfigData.length > 0) {
            IComptroller(comptrollerProxy_).configureExtensions(
                _feeManagerConfigData,
                _policyManagerConfigData
            );
        }

        emit ComptrollerProxyDeployed(
            msg.sender,
            comptrollerProxy_,
            _denominationAsset,
            _sharesActionTimelock,
            _feeManagerConfigData,
            _policyManagerConfigData,
            _forMigration
        );

        return comptrollerProxy_;
    }

    //////////////////
    // MIGRATION IN //
    //////////////////

    /// @notice Cancels fund migration
    /// @param _vaultProxy The VaultProxy for which to cancel migration
    function cancelMigration(address _vaultProxy) external {
        __cancelMigration(_vaultProxy, false);
    }

    /// @notice Cancels fund migration, bypassing any failures.
    /// Should be used in an emergency only.
    /// @param _vaultProxy The VaultProxy for which to cancel migration
    function cancelMigrationEmergency(address _vaultProxy) external {
        __cancelMigration(_vaultProxy, true);
    }

    /// @notice Executes fund migration
    /// @param _vaultProxy The VaultProxy for which to execute the migration
    function executeMigration(address _vaultProxy) external {
        __executeMigration(_vaultProxy, false);
    }

    /// @notice Executes fund migration, bypassing any failures.
    /// Should be used in an emergency only.
    /// @param _vaultProxy The VaultProxy for which to execute the migration
    function executeMigrationEmergency(address _vaultProxy) external {
        __executeMigration(_vaultProxy, true);
    }

    /// @dev Unimplemented
    function invokeMigrationInCancelHook(
        address,
        address,
        address,
        address
    ) external virtual override {
        return;
    }

    /// @notice Signal a fund migration
    /// @param _vaultProxy The VaultProxy for which to signal the migration
    /// @param _comptrollerProxy The ComptrollerProxy for which to signal the migration
    function signalMigration(address _vaultProxy, address _comptrollerProxy) external {
        __signalMigration(_vaultProxy, _comptrollerProxy, false);
    }

    /// @notice Signal a fund migration, bypassing any failures.
    /// Should be used in an emergency only.
    /// @param _vaultProxy The VaultProxy for which to signal the migration
    /// @param _comptrollerProxy The ComptrollerProxy for which to signal the migration
    function signalMigrationEmergency(address _vaultProxy, address _comptrollerProxy) external {
        __signalMigration(_vaultProxy, _comptrollerProxy, true);
    }

    /// @dev Helper to cancel a migration
    function __cancelMigration(address _vaultProxy, bool _bypassFailure)
        private
        onlyLiveRelease
        onlyMigrator(_vaultProxy)
    {
        IDispatcher(DISPATCHER).cancelMigration(_vaultProxy, _bypassFailure);
    }

    /// @dev Helper to execute a migration
    function __executeMigration(address _vaultProxy, bool _bypassFailure)
        private
        onlyLiveRelease
        onlyMigrator(_vaultProxy)
    {
        IDispatcher dispatcherContract = IDispatcher(DISPATCHER);

        (, address comptrollerProxy, , ) = dispatcherContract
            .getMigrationRequestDetailsForVaultProxy(_vaultProxy);

        dispatcherContract.executeMigration(_vaultProxy, _bypassFailure);

        IComptroller(comptrollerProxy).activate(_vaultProxy, true);

        delete pendingComptrollerProxyToCreator[comptrollerProxy];
    }

    /// @dev Helper to signal a migration
    function __signalMigration(
        address _vaultProxy,
        address _comptrollerProxy,
        bool _bypassFailure
    )
        private
        onlyLiveRelease
        onlyPendingComptrollerProxyCreator(_comptrollerProxy)
        onlyMigrator(_vaultProxy)
    {
        IDispatcher(DISPATCHER).signalMigration(
            _vaultProxy,
            _comptrollerProxy,
            VAULT_LIB,
            _bypassFailure
        );
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
    ) external override {
        if (_hook != MigrationOutHook.PreMigrate) {
            return;
        }

        require(
            msg.sender == DISPATCHER,
            "postMigrateOriginHook: Only Dispatcher can call this function"
        );

        // Must use PreMigrate hook to get the ComptrollerProxy from the VaultProxy
        address comptrollerProxy = IVault(_vaultProxy).getAccessor();

        // Wind down fund and destroy its config
        IComptroller(comptrollerProxy).destruct();
    }

    //////////////
    // REGISTRY //
    //////////////

    /// @notice De-registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to de-register
    /// @param _selectors The selectors of the calls to de-register
    function deregisterVaultCalls(address[] calldata _contracts, bytes4[] calldata _selectors)
        external
        onlyOwner
    {
        require(_contracts.length > 0, "deregisterVaultCalls: Empty _contracts");
        require(
            _contracts.length == _selectors.length,
            "deregisterVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                isRegisteredVaultCall(_contracts[i], _selectors[i]),
                "deregisterVaultCalls: Call not registered"
            );

            contractToSelectorToIsRegisteredVaultCall[_contracts[i]][_selectors[i]] = false;

            emit VaultCallDeregistered(_contracts[i], _selectors[i]);
        }
    }

    /// @notice Registers allowed arbitrary contract calls that can be sent from the VaultProxy
    /// @param _contracts The contracts of the calls to register
    /// @param _selectors The selectors of the calls to register
    function registerVaultCalls(address[] calldata _contracts, bytes4[] calldata _selectors)
        external
        onlyOwner
    {
        require(_contracts.length > 0, "registerVaultCalls: Empty _contracts");

        __registerVaultCalls(_contracts, _selectors);
    }

    /// @dev Helper to register allowed vault calls
    function __registerVaultCalls(address[] memory _contracts, bytes4[] memory _selectors)
        private
    {
        require(
            _contracts.length == _selectors.length,
            "__registerVaultCalls: Uneven input arrays"
        );

        for (uint256 i; i < _contracts.length; i++) {
            require(
                !isRegisteredVaultCall(_contracts[i], _selectors[i]),
                "__registerVaultCalls: Call already registered"
            );

            contractToSelectorToIsRegisteredVaultCall[_contracts[i]][_selectors[i]] = true;

            emit VaultCallRegistered(_contracts[i], _selectors[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `comptrollerLib` variable value
    /// @return comptrollerLib_ The `comptrollerLib` variable value
    function getComptrollerLib() external view returns (address comptrollerLib_) {
        return comptrollerLib;
    }

    /// @notice Gets the `CREATOR` variable value
    /// @return creator_ The `CREATOR` variable value
    function getCreator() external view returns (address creator_) {
        return CREATOR;
    }

    /// @notice Gets the `DISPATCHER` variable value
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() external view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the creator of a pending ComptrollerProxy
    /// @return pendingComptrollerProxyCreator_ The pending ComptrollerProxy creator
    function getPendingComptrollerProxyCreator(address _comptrollerProxy)
        external
        view
        returns (address pendingComptrollerProxyCreator_)
    {
        return pendingComptrollerProxyToCreator[_comptrollerProxy];
    }

    /// @notice Gets the `releaseStatus` variable value
    /// @return status_ The `releaseStatus` variable value
    function getReleaseStatus() external view override returns (ReleaseStatus status_) {
        return releaseStatus;
    }

    /// @notice Gets the `VAULT_LIB` variable value
    /// @return vaultLib_ The `VAULT_LIB` variable value
    function getVaultLib() external view returns (address vaultLib_) {
        return VAULT_LIB;
    }

    /// @notice Checks if a contract call is registered
    /// @param _contract The contract of the call to check
    /// @param _selector The selector of the call to check
    /// @return isRegistered_ True if the call is registered
    function isRegisteredVaultCall(address _contract, bytes4 _selector)
        public
        view
        override
        returns (bool isRegistered_)
    {
        return contractToSelectorToIsRegisteredVaultCall[_contract][_selector];
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../../core/fund/vault/IVault.sol";
import "../../infrastructure/price-feeds/derivatives/IDerivativePriceFeed.sol";
import "../../infrastructure/price-feeds/primitives/IPrimitivePriceFeed.sol";
import "../../utils/AddressArrayLib.sol";
import "../../utils/AssetFinalityResolver.sol";
import "../policy-manager/IPolicyManager.sol";
import "../utils/ExtensionBase.sol";
import "../utils/FundDeployerOwnerMixin.sol";
import "../utils/PermissionedVaultActionMixin.sol";
import "./integrations/IIntegrationAdapter.sol";
import "./IIntegrationManager.sol";

/// @title IntegrationManager
/// @author Enzyme Council <[email protected]>
/// @notice Extension to handle DeFi integration actions for funds
contract IntegrationManager is
    IIntegrationManager,
    ExtensionBase,
    FundDeployerOwnerMixin,
    PermissionedVaultActionMixin,
    AssetFinalityResolver
{
    using AddressArrayLib for address[];
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    event AdapterDeregistered(address indexed adapter, string indexed identifier);

    event AdapterRegistered(address indexed adapter, string indexed identifier);

    event AuthUserAddedForFund(address indexed comptrollerProxy, address indexed account);

    event AuthUserRemovedForFund(address indexed comptrollerProxy, address indexed account);

    event CallOnIntegrationExecutedForFund(
        address indexed comptrollerProxy,
        address vaultProxy,
        address caller,
        address indexed adapter,
        bytes4 indexed selector,
        bytes integrationData,
        address[] incomingAssets,
        uint256[] incomingAssetAmounts,
        address[] outgoingAssets,
        uint256[] outgoingAssetAmounts
    );

    address private immutable DERIVATIVE_PRICE_FEED;
    address private immutable POLICY_MANAGER;
    address private immutable PRIMITIVE_PRICE_FEED;

    EnumerableSet.AddressSet private registeredAdapters;

    mapping(address => mapping(address => bool)) private comptrollerProxyToAcctToIsAuthUser;

    constructor(
        address _fundDeployer,
        address _policyManager,
        address _derivativePriceFeed,
        address _primitivePriceFeed,
        address _synthetixPriceFeed,
        address _synthetixAddressResolver
    )
        public
        FundDeployerOwnerMixin(_fundDeployer)
        AssetFinalityResolver(_synthetixPriceFeed, _synthetixAddressResolver)
    {
        DERIVATIVE_PRICE_FEED = _derivativePriceFeed;
        POLICY_MANAGER = _policyManager;
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Activates the extension by storing the VaultProxy
    function activateForFund(bool) external override {
        __setValidatedVaultProxy(msg.sender);
    }

    /// @notice Authorizes a user to act on behalf of a fund via the IntegrationManager
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _who The user to authorize
    function addAuthUserForFund(address _comptrollerProxy, address _who) external {
        __validateSetAuthUser(_comptrollerProxy, _who, true);

        comptrollerProxyToAcctToIsAuthUser[_comptrollerProxy][_who] = true;

        emit AuthUserAddedForFund(_comptrollerProxy, _who);
    }

    /// @notice Deactivate the extension by destroying storage
    function deactivateForFund() external override {
        delete comptrollerProxyToVaultProxy[msg.sender];
    }

    /// @notice Removes an authorized user from the IntegrationManager for the given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _who The authorized user to remove
    function removeAuthUserForFund(address _comptrollerProxy, address _who) external {
        __validateSetAuthUser(_comptrollerProxy, _who, false);

        comptrollerProxyToAcctToIsAuthUser[_comptrollerProxy][_who] = false;

        emit AuthUserRemovedForFund(_comptrollerProxy, _who);
    }

    /// @notice Checks whether an account is an authorized IntegrationManager user for a given fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _who The account to check
    /// @return isAuthUser_ True if the account is an authorized user or the fund owner
    function isAuthUserForFund(address _comptrollerProxy, address _who)
        public
        view
        returns (bool isAuthUser_)
    {
        return
            comptrollerProxyToAcctToIsAuthUser[_comptrollerProxy][_who] ||
            _who == IVault(comptrollerProxyToVaultProxy[_comptrollerProxy]).getOwner();
    }

    /// @dev Helper to validate calls to update comptrollerProxyToAcctToIsAuthUser
    function __validateSetAuthUser(
        address _comptrollerProxy,
        address _who,
        bool _nextIsAuthUser
    ) private view {
        require(
            comptrollerProxyToVaultProxy[_comptrollerProxy] != address(0),
            "__validateSetAuthUser: Fund has not been activated"
        );

        address fundOwner = IVault(comptrollerProxyToVaultProxy[_comptrollerProxy]).getOwner();
        require(
            msg.sender == fundOwner,
            "__validateSetAuthUser: Only the fund owner can call this function"
        );
        require(_who != fundOwner, "__validateSetAuthUser: Cannot set for the fund owner");

        if (_nextIsAuthUser) {
            require(
                !comptrollerProxyToAcctToIsAuthUser[_comptrollerProxy][_who],
                "__validateSetAuthUser: Account is already an authorized user"
            );
        } else {
            require(
                comptrollerProxyToAcctToIsAuthUser[_comptrollerProxy][_who],
                "__validateSetAuthUser: Account is not an authorized user"
            );
        }
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
        // Since we validate and store the ComptrollerProxy-VaultProxy pairing during
        // activateForFund(), this function does not require further validation of the
        // sending ComptrollerProxy
        address vaultProxy = comptrollerProxyToVaultProxy[msg.sender];
        require(vaultProxy != address(0), "receiveCallFromComptroller: Fund is not active");
        require(
            isAuthUserForFund(msg.sender, _caller),
            "receiveCallFromComptroller: Not an authorized user"
        );

        // Dispatch the action
        if (_actionId == 0) {
            __callOnIntegration(_caller, vaultProxy, _callArgs);
        } else if (_actionId == 1) {
            __addZeroBalanceTrackedAssets(vaultProxy, _callArgs);
        } else if (_actionId == 2) {
            __removeZeroBalanceTrackedAssets(vaultProxy, _callArgs);
        } else {
            revert("receiveCallFromComptroller: Invalid _actionId");
        }
    }

    /// @dev Adds assets with a zero balance as tracked assets of the fund
    function __addZeroBalanceTrackedAssets(address _vaultProxy, bytes memory _callArgs) private {
        address[] memory assets = abi.decode(_callArgs, (address[]));
        for (uint256 i; i < assets.length; i++) {
            require(
                __finalizeIfSynthAndGetAssetBalance(_vaultProxy, assets[i], true) == 0,
                "__addZeroBalanceTrackedAssets: Balance is not zero"
            );

            __addTrackedAsset(msg.sender, assets[i]);
        }
    }

    /// @dev Removes assets with a zero balance from tracked assets of the fund
    function __removeZeroBalanceTrackedAssets(address _vaultProxy, bytes memory _callArgs)
        private
    {
        address[] memory assets = abi.decode(_callArgs, (address[]));
        address denominationAsset = IComptroller(msg.sender).getDenominationAsset();
        for (uint256 i; i < assets.length; i++) {
            require(
                assets[i] != denominationAsset,
                "__removeZeroBalanceTrackedAssets: Cannot remove denomination asset"
            );
            require(
                __finalizeIfSynthAndGetAssetBalance(_vaultProxy, assets[i], true) == 0,
                "__removeZeroBalanceTrackedAssets: Balance is not zero"
            );

            __removeTrackedAsset(msg.sender, assets[i]);
        }
    }

    /////////////////////////
    // CALL ON INTEGRATION //
    /////////////////////////

    /// @notice Universal method for calling third party contract functions through adapters
    /// @param _caller The caller of this function via the ComptrollerProxy
    /// @param _vaultProxy The VaultProxy of the fund
    /// @param _callArgs The encoded args for this function
    /// - _adapter Adapter of the integration on which to execute a call
    /// - _selector Method selector of the adapter method to execute
    /// - _integrationData Encoded arguments specific to the adapter
    /// @dev msg.sender is the ComptrollerProxy.
    /// Refer to specific adapter to see how to encode its arguments.
    function __callOnIntegration(
        address _caller,
        address _vaultProxy,
        bytes memory _callArgs
    ) private {
        (
            address adapter,
            bytes4 selector,
            bytes memory integrationData
        ) = __decodeCallOnIntegrationArgs(_callArgs);

        __preCoIHook(adapter, selector);

        /// Passing decoded _callArgs leads to stack-too-deep error
        (
            address[] memory incomingAssets,
            uint256[] memory incomingAssetAmounts,
            address[] memory outgoingAssets,
            uint256[] memory outgoingAssetAmounts
        ) = __callOnIntegrationInner(_vaultProxy, _callArgs);

        __postCoIHook(
            adapter,
            selector,
            incomingAssets,
            incomingAssetAmounts,
            outgoingAssets,
            outgoingAssetAmounts
        );

        __emitCoIEvent(
            _vaultProxy,
            _caller,
            adapter,
            selector,
            integrationData,
            incomingAssets,
            incomingAssetAmounts,
            outgoingAssets,
            outgoingAssetAmounts
        );
    }

    /// @dev Helper to execute the bulk of logic of callOnIntegration.
    /// Avoids the stack-too-deep-error.
    function __callOnIntegrationInner(address vaultProxy, bytes memory _callArgs)
        private
        returns (
            address[] memory incomingAssets_,
            uint256[] memory incomingAssetAmounts_,
            address[] memory outgoingAssets_,
            uint256[] memory outgoingAssetAmounts_
        )
    {
        (
            address[] memory expectedIncomingAssets,
            uint256[] memory preCallIncomingAssetBalances,
            uint256[] memory minIncomingAssetAmounts,
            SpendAssetsHandleType spendAssetsHandleType,
            address[] memory spendAssets,
            uint256[] memory maxSpendAssetAmounts,
            uint256[] memory preCallSpendAssetBalances
        ) = __preProcessCoI(vaultProxy, _callArgs);

        __executeCoI(
            vaultProxy,
            _callArgs,
            abi.encode(
                spendAssetsHandleType,
                spendAssets,
                maxSpendAssetAmounts,
                expectedIncomingAssets
            )
        );

        (
            incomingAssets_,
            incomingAssetAmounts_,
            outgoingAssets_,
            outgoingAssetAmounts_
        ) = __postProcessCoI(
            vaultProxy,
            expectedIncomingAssets,
            preCallIncomingAssetBalances,
            minIncomingAssetAmounts,
            spendAssetsHandleType,
            spendAssets,
            maxSpendAssetAmounts,
            preCallSpendAssetBalances
        );

        return (incomingAssets_, incomingAssetAmounts_, outgoingAssets_, outgoingAssetAmounts_);
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

    /// @dev Helper to emit the CallOnIntegrationExecuted event.
    /// Avoids stack-too-deep error.
    function __emitCoIEvent(
        address _vaultProxy,
        address _caller,
        address _adapter,
        bytes4 _selector,
        bytes memory _integrationData,
        address[] memory _incomingAssets,
        uint256[] memory _incomingAssetAmounts,
        address[] memory _outgoingAssets,
        uint256[] memory _outgoingAssetAmounts
    ) private {
        emit CallOnIntegrationExecutedForFund(
            msg.sender,
            _vaultProxy,
            _caller,
            _adapter,
            _selector,
            _integrationData,
            _incomingAssets,
            _incomingAssetAmounts,
            _outgoingAssets,
            _outgoingAssetAmounts
        );
    }

    /// @dev Helper to execute a call to an integration
    /// @dev Avoids stack-too-deep error
    function __executeCoI(
        address _vaultProxy,
        bytes memory _callArgs,
        bytes memory _encodedAssetTransferArgs
    ) private {
        (
            address adapter,
            bytes4 selector,
            bytes memory integrationData
        ) = __decodeCallOnIntegrationArgs(_callArgs);

        (bool success, bytes memory returnData) = adapter.call(
            abi.encodeWithSelector(
                selector,
                _vaultProxy,
                integrationData,
                _encodedAssetTransferArgs
            )
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

    /// @dev Helper to check if an asset is supported
    function __isSupportedAsset(address _asset) private view returns (bool isSupported_) {
        return
            IPrimitivePriceFeed(PRIMITIVE_PRICE_FEED).isSupportedAsset(_asset) ||
            IDerivativePriceFeed(DERIVATIVE_PRICE_FEED).isSupportedAsset(_asset);
    }

    /// @dev Helper for the actions to take on external contracts prior to executing CoI
    function __preCoIHook(address _adapter, bytes4 _selector) private {
        IPolicyManager(POLICY_MANAGER).validatePolicies(
            msg.sender,
            IPolicyManager.PolicyHook.PreCallOnIntegration,
            abi.encode(_adapter, _selector)
        );
    }

    /// @dev Helper for the internal actions to take prior to executing CoI
    function __preProcessCoI(address _vaultProxy, bytes memory _callArgs)
        private
        returns (
            address[] memory expectedIncomingAssets_,
            uint256[] memory preCallIncomingAssetBalances_,
            uint256[] memory minIncomingAssetAmounts_,
            SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory maxSpendAssetAmounts_,
            uint256[] memory preCallSpendAssetBalances_
        )
    {
        (
            address adapter,
            bytes4 selector,
            bytes memory integrationData
        ) = __decodeCallOnIntegrationArgs(_callArgs);

        require(adapterIsRegistered(adapter), "callOnIntegration: Adapter is not registered");

        // Note that expected incoming and spend assets are allowed to overlap
        // (e.g., a fee for the incomingAsset charged in a spend asset)
        (
            spendAssetsHandleType_,
            spendAssets_,
            maxSpendAssetAmounts_,
            expectedIncomingAssets_,
            minIncomingAssetAmounts_
        ) = IIntegrationAdapter(adapter).parseAssetsForMethod(selector, integrationData);
        require(
            spendAssets_.length == maxSpendAssetAmounts_.length,
            "__preProcessCoI: Spend assets arrays unequal"
        );
        require(
            expectedIncomingAssets_.length == minIncomingAssetAmounts_.length,
            "__preProcessCoI: Incoming assets arrays unequal"
        );
        require(spendAssets_.isUniqueSet(), "__preProcessCoI: Duplicate spend asset");
        require(
            expectedIncomingAssets_.isUniqueSet(),
            "__preProcessCoI: Duplicate incoming asset"
        );

        IVault vaultProxyContract = IVault(_vaultProxy);

        preCallIncomingAssetBalances_ = new uint256[](expectedIncomingAssets_.length);
        for (uint256 i = 0; i < expectedIncomingAssets_.length; i++) {
            require(
                expectedIncomingAssets_[i] != address(0),
                "__preProcessCoI: Empty incoming asset address"
            );
            require(
                minIncomingAssetAmounts_[i] > 0,
                "__preProcessCoI: minIncomingAssetAmount must be >0"
            );
            require(
                __isSupportedAsset(expectedIncomingAssets_[i]),
                "__preProcessCoI: Non-receivable incoming asset"
            );

            // Get pre-call balance of each incoming asset.
            // If the asset is not tracked by the fund, allow the balance to default to 0.
            if (vaultProxyContract.isTrackedAsset(expectedIncomingAssets_[i])) {
                // We do not require incoming asset finality, but we attempt to finalize so that
                // the final incoming asset amount is more accurate. There is no need to finalize
                // post-tx.
                preCallIncomingAssetBalances_[i] = __finalizeIfSynthAndGetAssetBalance(
                    _vaultProxy,
                    expectedIncomingAssets_[i],
                    false
                );
            }
        }

        // Get pre-call balances of spend assets and grant approvals to adapter
        preCallSpendAssetBalances_ = new uint256[](spendAssets_.length);
        for (uint256 i = 0; i < spendAssets_.length; i++) {
            require(spendAssets_[i] != address(0), "__preProcessCoI: Empty spend asset");
            require(maxSpendAssetAmounts_[i] > 0, "__preProcessCoI: Empty max spend asset amount");
            // A spend asset must either be a tracked asset of the fund or a supported asset,
            // in order to prevent seeding the fund with a malicious token and performing arbitrary
            // actions within an adapter.
            require(
                vaultProxyContract.isTrackedAsset(spendAssets_[i]) ||
                    __isSupportedAsset(spendAssets_[i]),
                "__preProcessCoI: Non-spendable spend asset"
            );

            // If spend asset is also an incoming asset, no need to record its balance
            if (!expectedIncomingAssets_.contains(spendAssets_[i])) {
                // By requiring spend asset finality before CoI, we will know whether or
                // not the asset balance was entirely spent during the call. There is no need
                // to finalize post-tx.
                preCallSpendAssetBalances_[i] = __finalizeIfSynthAndGetAssetBalance(
                    _vaultProxy,
                    spendAssets_[i],
                    true
                );
            }

            // Grant spend assets access to the adapter.
            // Note that spendAssets_ is already asserted to a unique set.
            if (spendAssetsHandleType_ == SpendAssetsHandleType.Approve) {
                // Use exact approve amount rather than increasing allowances,
                // because all adapters finish their actions atomically.
                __approveAssetSpender(
                    msg.sender,
                    spendAssets_[i],
                    adapter,
                    maxSpendAssetAmounts_[i]
                );
            } else if (spendAssetsHandleType_ == SpendAssetsHandleType.Transfer) {
                __withdrawAssetTo(msg.sender, spendAssets_[i], adapter, maxSpendAssetAmounts_[i]);
            } else if (spendAssetsHandleType_ == SpendAssetsHandleType.Remove) {
                __removeTrackedAsset(msg.sender, spendAssets_[i]);
            }
        }
    }

    /// @dev Helper for the actions to take on external contracts after executing CoI
    function __postCoIHook(
        address _adapter,
        bytes4 _selector,
        address[] memory _incomingAssets,
        uint256[] memory _incomingAssetAmounts,
        address[] memory _outgoingAssets,
        uint256[] memory _outgoingAssetAmounts
    ) private {
        IPolicyManager(POLICY_MANAGER).validatePolicies(
            msg.sender,
            IPolicyManager.PolicyHook.PostCallOnIntegration,
            abi.encode(
                _adapter,
                _selector,
                _incomingAssets,
                _incomingAssetAmounts,
                _outgoingAssets,
                _outgoingAssetAmounts
            )
        );
    }

    /// @dev Helper to reconcile and format incoming and outgoing assets after executing CoI
    function __postProcessCoI(
        address _vaultProxy,
        address[] memory _expectedIncomingAssets,
        uint256[] memory _preCallIncomingAssetBalances,
        uint256[] memory _minIncomingAssetAmounts,
        SpendAssetsHandleType _spendAssetsHandleType,
        address[] memory _spendAssets,
        uint256[] memory _maxSpendAssetAmounts,
        uint256[] memory _preCallSpendAssetBalances
    )
        private
        returns (
            address[] memory incomingAssets_,
            uint256[] memory incomingAssetAmounts_,
            address[] memory outgoingAssets_,
            uint256[] memory outgoingAssetAmounts_
        )
    {
        address[] memory increasedSpendAssets;
        uint256[] memory increasedSpendAssetAmounts;
        (
            outgoingAssets_,
            outgoingAssetAmounts_,
            increasedSpendAssets,
            increasedSpendAssetAmounts
        ) = __reconcileCoISpendAssets(
            _vaultProxy,
            _spendAssetsHandleType,
            _spendAssets,
            _maxSpendAssetAmounts,
            _preCallSpendAssetBalances
        );

        (incomingAssets_, incomingAssetAmounts_) = __reconcileCoIIncomingAssets(
            _vaultProxy,
            _expectedIncomingAssets,
            _preCallIncomingAssetBalances,
            _minIncomingAssetAmounts,
            increasedSpendAssets,
            increasedSpendAssetAmounts
        );

        return (incomingAssets_, incomingAssetAmounts_, outgoingAssets_, outgoingAssetAmounts_);
    }

    /// @dev Helper to process incoming asset balance changes.
    /// See __reconcileCoISpendAssets() for explanation on "increasedSpendAssets".
    function __reconcileCoIIncomingAssets(
        address _vaultProxy,
        address[] memory _expectedIncomingAssets,
        uint256[] memory _preCallIncomingAssetBalances,
        uint256[] memory _minIncomingAssetAmounts,
        address[] memory _increasedSpendAssets,
        uint256[] memory _increasedSpendAssetAmounts
    ) private returns (address[] memory incomingAssets_, uint256[] memory incomingAssetAmounts_) {
        // Incoming assets = expected incoming assets + spend assets with increased balances
        uint256 incomingAssetsCount = _expectedIncomingAssets.length.add(
            _increasedSpendAssets.length
        );

        // Calculate and validate incoming asset amounts
        incomingAssets_ = new address[](incomingAssetsCount);
        incomingAssetAmounts_ = new uint256[](incomingAssetsCount);
        for (uint256 i = 0; i < _expectedIncomingAssets.length; i++) {
            uint256 balanceDiff = __getVaultAssetBalance(_vaultProxy, _expectedIncomingAssets[i])
                .sub(_preCallIncomingAssetBalances[i]);
            require(
                balanceDiff >= _minIncomingAssetAmounts[i],
                "__reconcileCoIAssets: Received incoming asset less than expected"
            );

            // Even if the asset's previous balance was >0, it might not have been tracked
            __addTrackedAsset(msg.sender, _expectedIncomingAssets[i]);

            incomingAssets_[i] = _expectedIncomingAssets[i];
            incomingAssetAmounts_[i] = balanceDiff;
        }

        // Append increaseSpendAssets to incomingAsset vars
        if (_increasedSpendAssets.length > 0) {
            uint256 incomingAssetIndex = _expectedIncomingAssets.length;
            for (uint256 i = 0; i < _increasedSpendAssets.length; i++) {
                incomingAssets_[incomingAssetIndex] = _increasedSpendAssets[i];
                incomingAssetAmounts_[incomingAssetIndex] = _increasedSpendAssetAmounts[i];
                incomingAssetIndex++;
            }
        }

        return (incomingAssets_, incomingAssetAmounts_);
    }

    /// @dev Helper to process spend asset balance changes.
    /// "outgoingAssets" are the spend assets with a decrease in balance.
    /// "increasedSpendAssets" are the spend assets with an unexpected increase in balance.
    /// For example, "increasedSpendAssets" can occur if an adapter has a pre-balance of
    /// the spendAsset, which would be transferred to the fund at the end of the tx.
    function __reconcileCoISpendAssets(
        address _vaultProxy,
        SpendAssetsHandleType _spendAssetsHandleType,
        address[] memory _spendAssets,
        uint256[] memory _maxSpendAssetAmounts,
        uint256[] memory _preCallSpendAssetBalances
    )
        private
        returns (
            address[] memory outgoingAssets_,
            uint256[] memory outgoingAssetAmounts_,
            address[] memory increasedSpendAssets_,
            uint256[] memory increasedSpendAssetAmounts_
        )
    {
        // Determine spend asset balance changes
        uint256[] memory postCallSpendAssetBalances = new uint256[](_spendAssets.length);
        uint256 outgoingAssetsCount;
        uint256 increasedSpendAssetsCount;
        for (uint256 i = 0; i < _spendAssets.length; i++) {
            // If spend asset's initial balance is 0, then it is an incoming asset
            if (_preCallSpendAssetBalances[i] == 0) {
                continue;
            }

            // Handle SpendAssetsHandleType.Remove separately
            if (_spendAssetsHandleType == SpendAssetsHandleType.Remove) {
                outgoingAssetsCount++;
                continue;
            }

            // Determine if the asset is outgoing or incoming, and store the post-balance for later use
            postCallSpendAssetBalances[i] = __getVaultAssetBalance(_vaultProxy, _spendAssets[i]);
            // If the pre- and post- balances are equal, then the asset is neither incoming nor outgoing
            if (postCallSpendAssetBalances[i] < _preCallSpendAssetBalances[i]) {
                outgoingAssetsCount++;
            } else if (postCallSpendAssetBalances[i] > _preCallSpendAssetBalances[i]) {
                increasedSpendAssetsCount++;
            }
        }

        // Format outgoingAssets and increasedSpendAssets (spend assets with unexpected increase in balance)
        outgoingAssets_ = new address[](outgoingAssetsCount);
        outgoingAssetAmounts_ = new uint256[](outgoingAssetsCount);
        increasedSpendAssets_ = new address[](increasedSpendAssetsCount);
        increasedSpendAssetAmounts_ = new uint256[](increasedSpendAssetsCount);
        uint256 outgoingAssetsIndex;
        uint256 increasedSpendAssetsIndex;
        for (uint256 i = 0; i < _spendAssets.length; i++) {
            // If spend asset's initial balance is 0, then it is an incoming asset.
            if (_preCallSpendAssetBalances[i] == 0) {
                continue;
            }

            // Handle SpendAssetsHandleType.Remove separately.
            // No need to validate the max spend asset amount.
            if (_spendAssetsHandleType == SpendAssetsHandleType.Remove) {
                outgoingAssets_[outgoingAssetsIndex] = _spendAssets[i];
                outgoingAssetAmounts_[outgoingAssetsIndex] = _preCallSpendAssetBalances[i];
                outgoingAssetsIndex++;
                continue;
            }

            // If the pre- and post- balances are equal, then the asset is neither incoming nor outgoing
            if (postCallSpendAssetBalances[i] < _preCallSpendAssetBalances[i]) {
                if (postCallSpendAssetBalances[i] == 0) {
                    __removeTrackedAsset(msg.sender, _spendAssets[i]);
                    outgoingAssetAmounts_[outgoingAssetsIndex] = _preCallSpendAssetBalances[i];
                } else {
                    outgoingAssetAmounts_[outgoingAssetsIndex] = _preCallSpendAssetBalances[i].sub(
                        postCallSpendAssetBalances[i]
                    );
                }
                require(
                    outgoingAssetAmounts_[outgoingAssetsIndex] <= _maxSpendAssetAmounts[i],
                    "__reconcileCoISpendAssets: Spent amount greater than expected"
                );

                outgoingAssets_[outgoingAssetsIndex] = _spendAssets[i];
                outgoingAssetsIndex++;
            } else if (postCallSpendAssetBalances[i] > _preCallSpendAssetBalances[i]) {
                increasedSpendAssetAmounts_[increasedSpendAssetsIndex] = postCallSpendAssetBalances[i]
                    .sub(_preCallSpendAssetBalances[i]);
                increasedSpendAssets_[increasedSpendAssetsIndex] = _spendAssets[i];
                increasedSpendAssetsIndex++;
            }
        }

        return (
            outgoingAssets_,
            outgoingAssetAmounts_,
            increasedSpendAssets_,
            increasedSpendAssetAmounts_
        );
    }

    ///////////////////////////
    // INTEGRATIONS REGISTRY //
    ///////////////////////////

    /// @notice Remove integration adapters from the list of registered adapters
    /// @param _adapters Addresses of adapters to be deregistered
    function deregisterAdapters(address[] calldata _adapters) external onlyFundDeployerOwner {
        require(_adapters.length > 0, "deregisterAdapters: _adapters cannot be empty");

        for (uint256 i; i < _adapters.length; i++) {
            require(
                adapterIsRegistered(_adapters[i]),
                "deregisterAdapters: Adapter is not registered"
            );

            registeredAdapters.remove(_adapters[i]);

            emit AdapterDeregistered(_adapters[i], IIntegrationAdapter(_adapters[i]).identifier());
        }
    }

    /// @notice Add integration adapters to the list of registered adapters
    /// @param _adapters Addresses of adapters to be registered
    function registerAdapters(address[] calldata _adapters) external onlyFundDeployerOwner {
        require(_adapters.length > 0, "registerAdapters: _adapters cannot be empty");

        for (uint256 i; i < _adapters.length; i++) {
            require(_adapters[i] != address(0), "registerAdapters: Adapter cannot be empty");

            require(
                !adapterIsRegistered(_adapters[i]),
                "registerAdapters: Adapter already registered"
            );

            registeredAdapters.add(_adapters[i]);

            emit AdapterRegistered(_adapters[i], IIntegrationAdapter(_adapters[i]).identifier());
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Checks if an integration adapter is registered
    /// @param _adapter The adapter to check
    /// @return isRegistered_ True if the adapter is registered
    function adapterIsRegistered(address _adapter) public view returns (bool isRegistered_) {
        return registeredAdapters.contains(_adapter);
    }

    /// @notice Gets the `DERIVATIVE_PRICE_FEED` variable
    /// @return derivativePriceFeed_ The `DERIVATIVE_PRICE_FEED` variable value
    function getDerivativePriceFeed() external view returns (address derivativePriceFeed_) {
        return DERIVATIVE_PRICE_FEED;
    }

    /// @notice Gets the `POLICY_MANAGER` variable
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() external view returns (address policyManager_) {
        return POLICY_MANAGER;
    }

    /// @notice Gets the `PRIMITIVE_PRICE_FEED` variable
    /// @return primitivePriceFeed_ The `PRIMITIVE_PRICE_FEED` variable value
    function getPrimitivePriceFeed() external view returns (address primitivePriceFeed_) {
        return PRIMITIVE_PRICE_FEED;
    }

    /// @notice Gets all registered integration adapters
    /// @return registeredAdaptersArray_ A list of all registered integration adapters
    function getRegisteredAdapters()
        external
        view
        returns (address[] memory registeredAdaptersArray_)
    {
        registeredAdaptersArray_ = new address[](registeredAdapters.length());
        for (uint256 i = 0; i < registeredAdaptersArray_.length; i++) {
            registeredAdaptersArray_[i] = registeredAdapters.at(i);
        }

        return registeredAdaptersArray_;
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

import "../../../../infrastructure/price-feeds/derivatives/feeds/SynthetixPriceFeed.sol";
import "../../../../interfaces/ISynthetix.sol";
import "../utils/AdapterBase.sol";

/// @title SynthetixAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with Synthetix
contract SynthetixAdapter is AdapterBase {
    address private immutable ORIGINATOR;
    address private immutable SYNTHETIX;
    address private immutable SYNTHETIX_PRICE_FEED;
    bytes32 private immutable TRACKING_CODE;

    constructor(
        address _integrationManager,
        address _synthetixPriceFeed,
        address _originator,
        address _synthetix,
        bytes32 _trackingCode
    ) public AdapterBase(_integrationManager) {
        ORIGINATOR = _originator;
        SYNTHETIX = _synthetix;
        SYNTHETIX_PRICE_FEED = _synthetixPriceFeed;
        TRACKING_CODE = _trackingCode;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "SYNTHETIX";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForMethod: _selector invalid");

        (
            address incomingAsset,
            uint256 minIncomingAssetAmount,
            address outgoingAsset,
            uint256 outgoingAssetAmount
        ) = __decodeCallArgs(_encodedCallArgs);

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

    /// @notice Trades assets on Synthetix
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    function takeOrder(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata
    ) external onlyIntegrationManager {
        (
            address incomingAsset,
            ,
            address outgoingAsset,
            uint256 outgoingAssetAmount
        ) = __decodeCallArgs(_encodedCallArgs);

        address[] memory synths = new address[](2);
        synths[0] = outgoingAsset;
        synths[1] = incomingAsset;

        bytes32[] memory currencyKeys = SynthetixPriceFeed(SYNTHETIX_PRICE_FEED)
            .getCurrencyKeysForSynths(synths);

        ISynthetix(SYNTHETIX).exchangeOnBehalfWithTracking(
            _vaultProxy,
            currencyKeys[0],
            outgoingAssetAmount,
            currencyKeys[1],
            ORIGINATOR,
            TRACKING_CODE
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address incomingAsset_,
            uint256 minIncomingAssetAmount_,
            address outgoingAsset_,
            uint256 outgoingAssetAmount_
        )
    {
        return abi.decode(_encodedCallArgs, (address, uint256, address, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `ORIGINATOR` variable
    /// @return originator_ The `ORIGINATOR` variable value
    function getOriginator() external view returns (address originator_) {
        return ORIGINATOR;
    }

    /// @notice Gets the `SYNTHETIX` variable
    /// @return synthetix_ The `SYNTHETIX` variable value
    function getSynthetix() external view returns (address synthetix_) {
        return SYNTHETIX;
    }

    /// @notice Gets the `SYNTHETIX_PRICE_FEED` variable
    /// @return synthetixPriceFeed_ The `SYNTHETIX_PRICE_FEED` variable value
    function getSynthetixPriceFeed() external view returns (address synthetixPriceFeed_) {
        return SYNTHETIX_PRICE_FEED;
    }

    /// @notice Gets the `TRACKING_CODE` variable
    /// @return trackingCode_ The `TRACKING_CODE` variable value
    function getTrackingCode() external view returns (bytes32 trackingCode_) {
        return TRACKING_CODE;
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
import "../../../interfaces/IChainlinkAggregator.sol";
import "../../utils/DispatcherOwnerMixin.sol";
import "./IPrimitivePriceFeed.sol";

/// @title ChainlinkPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice A price feed that uses Chainlink oracles as price sources
contract ChainlinkPriceFeed is IPrimitivePriceFeed, DispatcherOwnerMixin {
    using SafeMath for uint256;

    event EthUsdAggregatorSet(address prevEthUsdAggregator, address nextEthUsdAggregator);

    event PrimitiveAdded(
        address indexed primitive,
        address aggregator,
        RateAsset rateAsset,
        uint256 unit
    );

    event PrimitiveRemoved(address indexed primitive);

    event PrimitiveUpdated(
        address indexed primitive,
        address prevAggregator,
        address nextAggregator
    );

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

    constructor(
        address _dispatcher,
        address _wethToken,
        address _ethUsdAggregator,
        address[] memory _primitives,
        address[] memory _aggregators,
        RateAsset[] memory _rateAssets
    ) public DispatcherOwnerMixin(_dispatcher) {
        WETH_TOKEN = _wethToken;
        staleRateThreshold = 25 hours; // 24 hour heartbeat + 1hr buffer
        __setEthUsdAggregator(_ethUsdAggregator);
        if (_primitives.length > 0) {
            __addPrimitives(_primitives, _aggregators, _rateAssets);
        }
    }

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the value of a base asset in terms of a quote asset (using a canonical rate)
    /// @param _baseAsset The base asset
    /// @param _baseAssetAmount The base asset amount to convert
    /// @param _quoteAsset The quote asset
    /// @return quoteAssetAmount_ The equivalent quote asset amount
    /// @return isValid_ True if the rates used in calculations are deemed valid
    function calcCanonicalValue(
        address _baseAsset,
        uint256 _baseAssetAmount,
        address _quoteAsset
    ) public view override returns (uint256 quoteAssetAmount_, bool isValid_) {
        // Case where _baseAsset == _quoteAsset is handled by ValueInterpreter

        int256 baseAssetRate = __getLatestRateData(_baseAsset);
        if (baseAssetRate <= 0) {
            return (0, false);
        }

        int256 quoteAssetRate = __getLatestRateData(_quoteAsset);
        if (quoteAssetRate <= 0) {
            return (0, false);
        }

        (quoteAssetAmount_, isValid_) = __calcConversionAmount(
            _baseAsset,
            _baseAssetAmount,
            uint256(baseAssetRate),
            _quoteAsset,
            uint256(quoteAssetRate)
        );

        return (quoteAssetAmount_, isValid_);
    }

    /// @notice Calculates the value of a base asset in terms of a quote asset (using a live rate)
    /// @param _baseAsset The base asset
    /// @param _baseAssetAmount The base asset amount to convert
    /// @param _quoteAsset The quote asset
    /// @return quoteAssetAmount_ The equivalent quote asset amount
    /// @return isValid_ True if the rates used in calculations are deemed valid
    /// @dev Live and canonical values are the same for Chainlink
    function calcLiveValue(
        address _baseAsset,
        uint256 _baseAssetAmount,
        address _quoteAsset
    ) external view override returns (uint256 quoteAssetAmount_, bool isValid_) {
        return calcCanonicalValue(_baseAsset, _baseAssetAmount, _quoteAsset);
    }

    /// @notice Checks whether an asset is a supported primitive of the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported primitive
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return _asset == WETH_TOKEN || primitiveToAggregatorInfo[_asset].aggregator != address(0);
    }

    /// @notice Sets the `ehUsdAggregator` variable value
    /// @param _nextEthUsdAggregator The `ehUsdAggregator` value to set
    function setEthUsdAggregator(address _nextEthUsdAggregator) external onlyDispatcherOwner {
        __setEthUsdAggregator(_nextEthUsdAggregator);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to convert an amount from a _baseAsset to a _quoteAsset
    function __calcConversionAmount(
        address _baseAsset,
        uint256 _baseAssetAmount,
        uint256 _baseAssetRate,
        address _quoteAsset,
        uint256 _quoteAssetRate
    ) private view returns (uint256 quoteAssetAmount_, bool isValid_) {
        RateAsset baseAssetRateAsset = getRateAssetForPrimitive(_baseAsset);
        RateAsset quoteAssetRateAsset = getRateAssetForPrimitive(_quoteAsset);
        uint256 baseAssetUnit = getUnitForPrimitive(_baseAsset);
        uint256 quoteAssetUnit = getUnitForPrimitive(_quoteAsset);

        // If rates are both in ETH or both in USD
        if (baseAssetRateAsset == quoteAssetRateAsset) {
            return (
                __calcConversionAmountSameRateAsset(
                    _baseAssetAmount,
                    baseAssetUnit,
                    _baseAssetRate,
                    quoteAssetUnit,
                    _quoteAssetRate
                ),
                true
            );
        }

        int256 ethPerUsdRate = IChainlinkAggregator(ethUsdAggregator).latestAnswer();
        if (ethPerUsdRate <= 0) {
            return (0, false);
        }

        // If _baseAsset's rate is in ETH and _quoteAsset's rate is in USD
        if (baseAssetRateAsset == RateAsset.ETH) {
            return (
                __calcConversionAmountEthRateAssetToUsdRateAsset(
                    _baseAssetAmount,
                    baseAssetUnit,
                    _baseAssetRate,
                    quoteAssetUnit,
                    _quoteAssetRate,
                    uint256(ethPerUsdRate)
                ),
                true
            );
        }

        // If _baseAsset's rate is in USD and _quoteAsset's rate is in ETH
        return (
            __calcConversionAmountUsdRateAssetToEthRateAsset(
                _baseAssetAmount,
                baseAssetUnit,
                _baseAssetRate,
                quoteAssetUnit,
                _quoteAssetRate,
                uint256(ethPerUsdRate)
            ),
            true
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
        if (_primitive == WETH_TOKEN) {
            return int256(ETH_UNIT);
        }

        address aggregator = primitiveToAggregatorInfo[_primitive].aggregator;
        require(aggregator != address(0), "__getLatestRateData: Primitive does not exist");

        return IChainlinkAggregator(aggregator).latestAnswer();
    }

    /// @dev Helper to set the `ethUsdAggregator` value
    function __setEthUsdAggregator(address _nextEthUsdAggregator) private {
        address prevEthUsdAggregator = ethUsdAggregator;
        require(
            _nextEthUsdAggregator != prevEthUsdAggregator,
            "__setEthUsdAggregator: Value already set"
        );

        __validateAggregator(_nextEthUsdAggregator);

        ethUsdAggregator = _nextEthUsdAggregator;

        emit EthUsdAggregatorSet(prevEthUsdAggregator, _nextEthUsdAggregator);
    }

    /////////////////////////
    // PRIMITIVES REGISTRY //
    /////////////////////////

    /// @notice Adds a list of primitives with the given aggregator and rateAsset values
    /// @param _primitives The primitives to add
    /// @param _aggregators The ordered aggregators corresponding to the list of _primitives
    /// @param _rateAssets The ordered rate assets corresponding to the list of _primitives
    function addPrimitives(
        address[] calldata _primitives,
        address[] calldata _aggregators,
        RateAsset[] calldata _rateAssets
    ) external onlyDispatcherOwner {
        require(_primitives.length > 0, "addPrimitives: _primitives cannot be empty");

        __addPrimitives(_primitives, _aggregators, _rateAssets);
    }

    /// @notice Removes a list of primitives from the feed
    /// @param _primitives The primitives to remove
    function removePrimitives(address[] calldata _primitives) external onlyDispatcherOwner {
        require(_primitives.length > 0, "removePrimitives: _primitives cannot be empty");

        for (uint256 i; i < _primitives.length; i++) {
            require(
                primitiveToAggregatorInfo[_primitives[i]].aggregator != address(0),
                "removePrimitives: Primitive not yet added"
            );

            delete primitiveToAggregatorInfo[_primitives[i]];
            delete primitiveToUnit[_primitives[i]];

            emit PrimitiveRemoved(_primitives[i]);
        }
    }

    /// @notice Removes stale primitives from the feed
    /// @param _primitives The stale primitives to remove
    /// @dev Callable by anybody
    function removeStalePrimitives(address[] calldata _primitives) external {
        require(_primitives.length > 0, "removeStalePrimitives: _primitives cannot be empty");

        for (uint256 i; i < _primitives.length; i++) {
            address aggregatorAddress = primitiveToAggregatorInfo[_primitives[i]].aggregator;
            require(aggregatorAddress != address(0), "removeStalePrimitives: Invalid primitive");
            require(rateIsStale(aggregatorAddress), "removeStalePrimitives: Rate is not stale");

            delete primitiveToAggregatorInfo[_primitives[i]];
            delete primitiveToUnit[_primitives[i]];

            emit StalePrimitiveRemoved(_primitives[i]);
        }
    }

    /// @notice Sets the `staleRateThreshold` variable
    /// @param _nextStaleRateThreshold The next `staleRateThreshold` value
    function setStaleRateThreshold(uint256 _nextStaleRateThreshold) external onlyDispatcherOwner {
        uint256 prevStaleRateThreshold = staleRateThreshold;
        require(
            _nextStaleRateThreshold != prevStaleRateThreshold,
            "__setStaleRateThreshold: Value already set"
        );

        staleRateThreshold = _nextStaleRateThreshold;

        emit StaleRateThresholdSet(prevStaleRateThreshold, _nextStaleRateThreshold);
    }

    /// @notice Updates the aggregators for given primitives
    /// @param _primitives The primitives to update
    /// @param _aggregators The ordered aggregators corresponding to the list of _primitives
    function updatePrimitives(address[] calldata _primitives, address[] calldata _aggregators)
        external
        onlyDispatcherOwner
    {
        require(_primitives.length > 0, "updatePrimitives: _primitives cannot be empty");
        require(
            _primitives.length == _aggregators.length,
            "updatePrimitives: Unequal _primitives and _aggregators array lengths"
        );

        for (uint256 i; i < _primitives.length; i++) {
            address prevAggregator = primitiveToAggregatorInfo[_primitives[i]].aggregator;
            require(prevAggregator != address(0), "updatePrimitives: Primitive not yet added");
            require(_aggregators[i] != prevAggregator, "updatePrimitives: Value already set");

            __validateAggregator(_aggregators[i]);

            primitiveToAggregatorInfo[_primitives[i]].aggregator = _aggregators[i];

            emit PrimitiveUpdated(_primitives[i], prevAggregator, _aggregators[i]);
        }
    }

    /// @notice Checks whether the current rate is considered stale for the specified aggregator
    /// @param _aggregator The Chainlink aggregator of which to check staleness
    /// @return rateIsStale_ True if the rate is considered stale
    function rateIsStale(address _aggregator) public view returns (bool rateIsStale_) {
        return
            IChainlinkAggregator(_aggregator).latestTimestamp() <
            block.timestamp.sub(staleRateThreshold);
    }

    /// @dev Helper to add primitives to the feed
    function __addPrimitives(
        address[] memory _primitives,
        address[] memory _aggregators,
        RateAsset[] memory _rateAssets
    ) private {
        require(
            _primitives.length == _aggregators.length,
            "__addPrimitives: Unequal _primitives and _aggregators array lengths"
        );
        require(
            _primitives.length == _rateAssets.length,
            "__addPrimitives: Unequal _primitives and _rateAssets array lengths"
        );

        for (uint256 i = 0; i < _primitives.length; i++) {
            require(
                primitiveToAggregatorInfo[_primitives[i]].aggregator == address(0),
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

    /// @dev Helper to validate an aggregator by checking its return values for the expected interface
    function __validateAggregator(address _aggregator) private view {
        require(_aggregator != address(0), "__validateAggregator: Empty _aggregator");

        require(
            IChainlinkAggregator(_aggregator).latestAnswer() > 0,
            "__validateAggregator: No rate detected"
        );
        require(!rateIsStale(_aggregator), "__validateAggregator: Stale rate detected");
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the aggregatorInfo variable value for a primitive
    /// @param _primitive The primitive asset for which to get the aggregatorInfo value
    /// @return aggregatorInfo_ The aggregatorInfo value
    function getAggregatorInfoForPrimitive(address _primitive)
        external
        view
        returns (AggregatorInfo memory aggregatorInfo_)
    {
        return primitiveToAggregatorInfo[_primitive];
    }

    /// @notice Gets the `ethUsdAggregator` variable value
    /// @return ethUsdAggregator_ The `ethUsdAggregator` variable value
    function getEthUsdAggregator() external view returns (address ethUsdAggregator_) {
        return ethUsdAggregator;
    }

    /// @notice Gets the `staleRateThreshold` variable value
    /// @return staleRateThreshold_ The `staleRateThreshold` variable value
    function getStaleRateThreshold() external view returns (uint256 staleRateThreshold_) {
        return staleRateThreshold;
    }

    /// @notice Gets the `WETH_TOKEN` variable value
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
        return WETH_TOKEN;
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
        if (_primitive == WETH_TOKEN) {
            return RateAsset.ETH;
        }

        return primitiveToAggregatorInfo[_primitive].rateAsset;
    }

    /// @notice Gets the unit variable value for a primitive
    /// @return unit_ The unit variable value
    function getUnitForPrimitive(address _primitive) public view returns (uint256 unit_) {
        if (_primitive == WETH_TOKEN) {
            return ETH_UNIT;
        }

        return primitiveToUnit[_primitive];
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../release/infrastructure/value-interpreter/IValueInterpreter.sol";
import "../../release/infrastructure/price-feeds/derivatives/IAggregatedDerivativePriceFeed.sol";
import "../../release/infrastructure/price-feeds/primitives/IPrimitivePriceFeed.sol";

/// @dev This contract acts as a centralized rate provider for mocks.
/// Suited for a dev environment, it doesn't take into account gas costs.
contract CentralizedRateProvider is Ownable {
    using SafeMath for uint256;

    address private immutable WETH;
    uint256 private maxDeviationPerSender;

    // Addresses are not immutable to facilitate lazy load (they're are not accessible at the mock env).
    address private valueInterpreter;
    address private aggregateDerivativePriceFeed;
    address private primitivePriceFeed;

    constructor(address _weth, uint256 _maxDeviationPerSender) public {
        maxDeviationPerSender = _maxDeviationPerSender;
        WETH = _weth;
    }

    /// @dev Calculates the value of a _baseAsset relative to a _quoteAsset.
    /// Label to ValueInterprete's calcLiveAssetValue
    function calcLiveAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) public returns (uint256 value_) {
        uint256 baseDecimalsRate = 10**uint256(ERC20(_baseAsset).decimals());
        uint256 quoteDecimalsRate = 10**uint256(ERC20(_quoteAsset).decimals());

        // 1. Check if quote asset is a primitive. If it is, use ValueInterpreter normally.
        if (IPrimitivePriceFeed(primitivePriceFeed).isSupportedAsset(_quoteAsset)) {
            (value_, ) = IValueInterpreter(valueInterpreter).calcLiveAssetValue(
                _baseAsset,
                _amount,
                _quoteAsset
            );
            return value_;
        }

        // 2. Otherwise, check if base asset is a primitive, and use inverse rate from Value Interpreter.
        if (IPrimitivePriceFeed(primitivePriceFeed).isSupportedAsset(_baseAsset)) {
            (uint256 inverseRate, ) = IValueInterpreter(valueInterpreter).calcLiveAssetValue(
                _quoteAsset,
                10**uint256(ERC20(_quoteAsset).decimals()),
                _baseAsset
            );

            uint256 rate = uint256(baseDecimalsRate).mul(quoteDecimalsRate).div(inverseRate);

            value_ = _amount.mul(rate).div(baseDecimalsRate);
            return value_;
        }

        // 3. If both assets are derivatives, calculate the rate against ETH.
        (uint256 baseToWeth, ) = IValueInterpreter(valueInterpreter).calcLiveAssetValue(
            _baseAsset,
            baseDecimalsRate,
            WETH
        );

        (uint256 quoteToWeth, ) = IValueInterpreter(valueInterpreter).calcLiveAssetValue(
            _quoteAsset,
            quoteDecimalsRate,
            WETH
        );

        value_ = _amount.mul(baseToWeth).mul(quoteDecimalsRate).div(quoteToWeth).div(
            baseDecimalsRate
        );
        return value_;
    }

    /// @dev Calculates a randomized live value of an asset
    /// Aggregation of two randomization seeds: msg.sender, and by block.number.
    function calcLiveAssetValueRandomized(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset,
        uint256 _maxDeviationPerBlock
    ) external returns (uint256 value_) {
        uint256 liveAssetValue = calcLiveAssetValue(_baseAsset, _amount, _quoteAsset);

        // Range [liveAssetValue * (1 - _blockNumberDeviation), liveAssetValue * (1 + _blockNumberDeviation)]
        uint256 senderRandomizedValue_ = __calcValueRandomizedByAddress(
            liveAssetValue,
            msg.sender,
            maxDeviationPerSender
        );

        // Range [liveAssetValue * (1 - _maxDeviationPerBlock - maxDeviationPerSender), liveAssetValue * (1 + _maxDeviationPerBlock + maxDeviationPerSender)]
        value_ = __calcValueRandomizedByUint(
            senderRandomizedValue_,
            block.number,
            _maxDeviationPerBlock
        );

        return value_;
    }

    /// @dev Calculates the live value of an asset including a grade of pseudo randomization, using msg.sender as the source of randomness
    function calcLiveAssetValueRandomizedByBlockNumber(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset,
        uint256 _maxDeviationPerBlock
    ) external returns (uint256 value_) {
        uint256 liveAssetValue = calcLiveAssetValue(_baseAsset, _amount, _quoteAsset);

        value_ = __calcValueRandomizedByUint(liveAssetValue, block.number, _maxDeviationPerBlock);

        return value_;
    }

    /// @dev Calculates the live value of an asset including a grade of pseudo-randomization, using `block.number` as the source of randomness
    function calcLiveAssetValueRandomizedBySender(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external returns (uint256 value_) {
        uint256 liveAssetValue = calcLiveAssetValue(_baseAsset, _amount, _quoteAsset);

        value_ = __calcValueRandomizedByAddress(liveAssetValue, msg.sender, maxDeviationPerSender);

        return value_;
    }

    function setMaxDeviationPerSender(uint256 _maxDeviationPerSender) external onlyOwner {
        maxDeviationPerSender = _maxDeviationPerSender;
    }

    /// @dev Connector from release environment, inject price variables into the provider.
    function setReleasePriceAddresses(
        address _valueInterpreter,
        address _aggregateDerivativePriceFeed,
        address _primitivePriceFeed
    ) external onlyOwner {
        valueInterpreter = _valueInterpreter;
        aggregateDerivativePriceFeed = _aggregateDerivativePriceFeed;
        primitivePriceFeed = _primitivePriceFeed;
    }

    // PRIVATE FUNCTIONS

    /// @dev Calculates a a pseudo-randomized value as a seed an address
    function __calcValueRandomizedByAddress(
        uint256 _meanValue,
        address _seed,
        uint256 _maxDeviation
    ) private pure returns (uint256 value_) {
        // Value between [0, 100]
        uint256 senderRandomFactor = uint256(uint8(_seed))
            .mul(100)
            .div(256)
            .mul(_maxDeviation)
            .div(100);

        value_ = __calcDeviatedValue(_meanValue, senderRandomFactor, _maxDeviation);

        return value_;
    }

    /// @dev Calculates a a pseudo-randomized value as a seed an uint256
    function __calcValueRandomizedByUint(
        uint256 _meanValue,
        uint256 _seed,
        uint256 _maxDeviation
    ) private pure returns (uint256 value_) {
        // Depending on the _seed number, it will be one of {20, 40, 60, 80, 100}
        uint256 randomFactor = (_seed.mod(2).mul(20))
            .add((_seed.mod(3).mul(40)))
            .mul(_maxDeviation)
            .div(100);

        value_ = __calcDeviatedValue(_meanValue, randomFactor, _maxDeviation);

        return value_;
    }

    /// @dev Given a mean value and a max deviation, returns a value in the spectrum between 0 (_meanValue - maxDeviation) and 100 (_mean + maxDeviation)
    /// TODO: Refactor to use 18 decimal precision
    function __calcDeviatedValue(
        uint256 _meanValue,
        uint256 _offset,
        uint256 _maxDeviation
    ) private pure returns (uint256 value_) {
        return
            _meanValue.add((_meanValue.mul((uint256(2)).mul(_offset)).div(uint256(100)))).sub(
                _meanValue.mul(_maxDeviation).div(uint256(100))
            );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    function getMaxDeviationPerSender() public view returns (uint256 maxDeviationPerSender_) {
        return maxDeviationPerSender;
    }

    function getValueInterpreter() public view returns (address valueInterpreter_) {
        return valueInterpreter;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../release/interfaces/IUniswapV2Pair.sol";
import "../prices/CentralizedRateProvider.sol";
import "../tokens/MockToken.sol";

/// @dev This price source mocks the integration with Uniswap Pair
/// Docs of Uniswap Pair implementation: <https://uniswap.org/docs/v2/smart-contracts/pair/>
contract MockUniswapV2PriceSource is MockToken("Uniswap V2", "UNI-V2", 18) {
    using SafeMath for uint256;

    address private immutable TOKEN_0;
    address private immutable TOKEN_1;
    address private immutable CENTRALIZED_RATE_PROVIDER;

    constructor(
        address _centralizedRateProvider,
        address _token0,
        address _token1
    ) public {
        CENTRALIZED_RATE_PROVIDER = _centralizedRateProvider;
        TOKEN_0 = _token0;
        TOKEN_1 = _token1;
    }

    /// @dev returns reserves for each token on the Uniswap Pair
    /// Reserves will be used to calculate the pair price
    /// Inherited from IUniswapV2Pair
    function getReserves()
        external
        returns (
            uint112 reserve0_,
            uint112 reserve1_,
            uint32 blockTimestampLast_
        )
    {
        uint256 baseAmount = ERC20(TOKEN_0).balanceOf(address(this));
        reserve0_ = uint112(baseAmount);
        reserve1_ = uint112(
            CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER).calcLiveAssetValue(
                TOKEN_0,
                baseAmount,
                TOKEN_1
            )
        );

        return (reserve0_, reserve1_, blockTimestampLast_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @dev Inherited from IUniswapV2Pair
    function token0() public view returns (address) {
        return TOKEN_0;
    }

    /// @dev Inherited from IUniswapV2Pair
    function token1() public view returns (address) {
        return TOKEN_1;
    }

    /// @dev Inherited from IUniswapV2Pair
    function kLast() public pure returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../release/core/fund/comptroller/ComptrollerLib.sol";
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
            ComptrollerLib(comptrollerProxy).redeemShares();
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
            ComptrollerLib(comptrollerProxy).buyShares(
                new address[](0),
                new uint256[](0),
                new uint256[](0)
            );
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./../../release/interfaces/ISynthetixProxyERC20.sol";
import "./../../release/interfaces/ISynthetixSynth.sol";
import "./MockToken.sol";

contract MockSynthetixToken is ISynthetixProxyERC20, ISynthetixSynth, MockToken {
    using SafeMath for uint256;

    bytes32 public override currencyKey;
    uint256 public constant WAITING_PERIOD_SECS = 3 * 60;

    mapping(address => uint256) public timelockByAccount;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bytes32 _currencyKey
    ) public MockToken(_name, _symbol, _decimals) {
        currencyKey = _currencyKey;
    }

    function setCurrencyKey(bytes32 _currencyKey) external onlyOwner {
        currencyKey = _currencyKey;
    }

    function _isLocked(address account) internal view returns (bool) {
        return timelockByAccount[account] >= now;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal override {
        require(!_isLocked(from), "Cannot settle during waiting period");
    }

    function target() external view override returns (address) {
        return address(this);
    }

    function isLocked(address account) external view returns (bool) {
        return _isLocked(account);
    }

    function burnFrom(address account, uint256 amount) public override {
        _burn(account, amount);
    }

    function lock(address account) public {
        timelockByAccount[account] = now.add(WAITING_PERIOD_SECS);
    }

    function unlock(address account) public {
        timelockByAccount[account] = 0;
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
import "../../../../interfaces/IUniswapV2Factory.sol";
import "../../../../interfaces/IUniswapV2Router2.sol";
import "../utils/AdapterBase.sol";

/// @title UniswapV2Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with Uniswap v2
contract UniswapV2Adapter is AdapterBase {
    using SafeMath for uint256;

    address private immutable FACTORY;
    address private immutable ROUTER;

    constructor(
        address _integrationManager,
        address _router,
        address _factory
    ) public AdapterBase(_integrationManager) {
        FACTORY = _factory;
        ROUTER = _router;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "UNISWAP_V2";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
            (
                address[2] memory outgoingAssets,
                uint256[2] memory maxOutgoingAssetAmounts,
                ,
                uint256 minIncomingAssetAmount
            ) = __decodeLendCallArgs(_encodedCallArgs);

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
        } else if (_selector == REDEEM_SELECTOR) {
            (
                uint256 outgoingAssetAmount,
                address[2] memory incomingAssets,
                uint256[2] memory minIncomingAssetAmounts
            ) = __decodeRedeemCallArgs(_encodedCallArgs);

            spendAssets_ = new address[](1);
            // No need to validate not address(0), this will be caught in IntegrationManager
            spendAssets_[0] = IUniswapV2Factory(FACTORY).getPair(
                incomingAssets[0],
                incomingAssets[1]
            );

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = outgoingAssetAmount;

            incomingAssets_ = new address[](2);
            incomingAssets_[0] = incomingAssets[0];
            incomingAssets_[1] = incomingAssets[1];

            minIncomingAssetAmounts_ = new uint256[](2);
            minIncomingAssetAmounts_[0] = minIncomingAssetAmounts[0];
            minIncomingAssetAmounts_[1] = minIncomingAssetAmounts[1];
        } else if (_selector == TAKE_ORDER_SELECTOR) {
            (
                address[] memory path,
                uint256 outgoingAssetAmount,
                uint256 minIncomingAssetAmount
            ) = __decodeTakeOrderCallArgs(_encodedCallArgs);

            require(path.length >= 2, "parseAssetsForMethod: _path must be >= 2");

            spendAssets_ = new address[](1);
            spendAssets_[0] = path[0];
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = outgoingAssetAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = path[path.length - 1];
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minIncomingAssetAmount;
        } else {
            revert("parseAssetsForMethod: _selector invalid");
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @notice Lends assets for pool tokens on Uniswap
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function lend(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (
            address[2] memory outgoingAssets,
            uint256[2] memory maxOutgoingAssetAmounts,
            uint256[2] memory minOutgoingAssetAmounts,

        ) = __decodeLendCallArgs(_encodedCallArgs);

        __lend(
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
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function redeem(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (
            uint256 outgoingAssetAmount,
            address[2] memory incomingAssets,
            uint256[2] memory minIncomingAssetAmounts
        ) = __decodeRedeemCallArgs(_encodedCallArgs);

        // More efficient to parse pool token from _encodedAssetTransferArgs than external call
        (, address[] memory spendAssets, , ) = __decodeEncodedAssetTransferArgs(
            _encodedAssetTransferArgs
        );

        __redeem(
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
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function takeOrder(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (
            address[] memory path,
            uint256 outgoingAssetAmount,
            uint256 minIncomingAssetAmount
        ) = __decodeTakeOrderCallArgs(_encodedCallArgs);

        __takeOrder(_vaultProxy, outgoingAssetAmount, minIncomingAssetAmount, path);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the lend encoded call arguments
    function __decodeLendCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address[2] memory outgoingAssets_,
            uint256[2] memory maxOutgoingAssetAmounts_,
            uint256[2] memory minOutgoingAssetAmounts_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_encodedCallArgs, (address[2], uint256[2], uint256[2], uint256));
    }

    /// @dev Helper to decode the redeem encoded call arguments
    function __decodeRedeemCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            uint256 outgoingAssetAmount_,
            address[2] memory incomingAssets_,
            uint256[2] memory minIncomingAssetAmounts_
        )
    {
        return abi.decode(_encodedCallArgs, (uint256, address[2], uint256[2]));
    }

    /// @dev Helper to decode the take order encoded call arguments
    function __decodeTakeOrderCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address[] memory path_,
            uint256 outgoingAssetAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_encodedCallArgs, (address[], uint256, uint256));
    }

    /// @dev Helper to execute lend. Avoids stack-too-deep error.
    function __lend(
        address _vaultProxy,
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) private {
        __approveMaxAsNeeded(_tokenA, ROUTER, _amountADesired);
        __approveMaxAsNeeded(_tokenB, ROUTER, _amountBDesired);

        // Execute lend on Uniswap
        IUniswapV2Router2(ROUTER).addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin,
            _vaultProxy,
            block.timestamp.add(1)
        );
    }

    /// @dev Helper to execute redeem. Avoids stack-too-deep error.
    function __redeem(
        address _vaultProxy,
        address _poolToken,
        uint256 _poolTokenAmount,
        address _tokenA,
        address _tokenB,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) private {
        __approveMaxAsNeeded(_poolToken, ROUTER, _poolTokenAmount);

        // Execute redeem on Uniswap
        IUniswapV2Router2(ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            _poolTokenAmount,
            _amountAMin,
            _amountBMin,
            _vaultProxy,
            block.timestamp.add(1)
        );
    }

    /// @dev Helper to execute takeOrder. Avoids stack-too-deep error.
    function __takeOrder(
        address _vaultProxy,
        uint256 _outgoingAssetAmount,
        uint256 _minIncomingAssetAmount,
        address[] memory _path
    ) private {
        __approveMaxAsNeeded(_path[0], ROUTER, _outgoingAssetAmount);

        // Execute fill
        IUniswapV2Router2(ROUTER).swapExactTokensForTokens(
            _outgoingAssetAmount,
            _minIncomingAssetAmount,
            _path,
            _vaultProxy,
            block.timestamp.add(1)
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FACTORY` variable
    /// @return factory_ The `FACTORY` variable value
    function getFactory() external view returns (address factory_) {
        return FACTORY;
    }

    /// @notice Gets the `ROUTER` variable
    /// @return router_ The `ROUTER` variable value
    function getRouter() external view returns (address router_) {
        return ROUTER;
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/IMakerDaoPot.sol";
import "../IDerivativePriceFeed.sol";

/// @title ChaiPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Chai
contract ChaiPriceFeed is IDerivativePriceFeed {
    using SafeMath for uint256;

    uint256 private constant CHI_DIVISOR = 10**27;
    address private immutable CHAI;
    address private immutable DAI;
    address private immutable DSR_POT;

    constructor(
        address _chai,
        address _dai,
        address _dsrPot
    ) public {
        CHAI = _chai;
        DAI = _dai;
        DSR_POT = _dsrPot;
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    /// @dev Calculation based on Chai source: https://github.com/dapphub/chai/blob/master/src/chai.sol
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        require(isSupportedAsset(_derivative), "calcUnderlyingValues: Only Chai is supported");

        underlyings_ = new address[](1);
        underlyings_[0] = DAI;
        underlyingAmounts_ = new uint256[](1);
        underlyingAmounts_[0] = _derivativeAmount.mul(IMakerDaoPot(DSR_POT).chi()).div(
            CHI_DIVISOR
        );
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return _asset == CHAI;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CHAI` variable value
    /// @return chai_ The `CHAI` variable value
    function getChai() external view returns (address chai_) {
        return CHAI;
    }

    /// @notice Gets the `DAI` variable value
    /// @return dai_ The `DAI` variable value
    function getDai() external view returns (address dai_) {
        return DAI;
    }

    /// @notice Gets the `DSR_POT` variable value
    /// @return dsrPot_ The `DSR_POT` variable value
    function getDsrPot() external view returns (address dsrPot_) {
        return DSR_POT;
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

/// @notice Limited interface for Maker DSR's Pot contract
/// @dev See DSR integration guide: https://github.com/makerdao/developerguides/blob/master/dai/dsr-integration-guide/dsr-integration-guide-01.md
interface IMakerDaoPot {
    function chi() external view returns (uint256);

    function rho() external view returns (uint256);

    function drip() external returns (uint256);
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
import "../../../../interfaces/IAlphaHomoraV1Bank.sol";
import "../IDerivativePriceFeed.sol";

/// @title AlphaHomoraV1PriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Alpha Homora v1 ibETH
contract AlphaHomoraV1PriceFeed is IDerivativePriceFeed {
    using SafeMath for uint256;

    address private immutable IBETH_TOKEN;
    address private immutable WETH_TOKEN;

    constructor(address _ibethToken, address _wethToken) public {
        IBETH_TOKEN = _ibethToken;
        WETH_TOKEN = _wethToken;
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
        require(isSupportedAsset(_derivative), "calcUnderlyingValues: Only ibETH is supported");

        underlyings_ = new address[](1);
        underlyings_[0] = WETH_TOKEN;
        underlyingAmounts_ = new uint256[](1);

        IAlphaHomoraV1Bank alphaHomoraBankContract = IAlphaHomoraV1Bank(IBETH_TOKEN);
        underlyingAmounts_[0] = _derivativeAmount.mul(alphaHomoraBankContract.totalETH()).div(
            alphaHomoraBankContract.totalSupply()
        );

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) public view override returns (bool isSupported_) {
        return _asset == IBETH_TOKEN;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `IBETH_TOKEN` variable
    /// @return ibethToken_ The `IBETH_TOKEN` variable value
    function getIbethToken() external view returns (address ibethToken_) {
        return IBETH_TOKEN;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
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

/// @title IAlphaHomoraV1Bank interface
/// @author Enzyme Council <[email protected]>
interface IAlphaHomoraV1Bank {
    function deposit() external payable;

    function totalETH() external view returns (uint256);

    function totalSupply() external view returns (uint256);

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

import "../../../../interfaces/IAlphaHomoraV1Bank.sol";
import "../../../../interfaces/IWETH.sol";
import "../utils/AdapterBase.sol";

/// @title AlphaHomoraV1Adapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Alpha Homora v1 <https://alphafinance.io/>
contract AlphaHomoraV1Adapter is AdapterBase {
    address private immutable IBETH_TOKEN;
    address private immutable WETH_TOKEN;

    constructor(
        address _integrationManager,
        address _ibethToken,
        address _wethToken
    ) public AdapterBase(_integrationManager) {
        IBETH_TOKEN = _ibethToken;
        WETH_TOKEN = _wethToken;
    }

    /// @dev Needed to receive ETH during redemption
    receive() external payable {}

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "ALPHA_HOMORA_V1";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
            (uint256 wethAmount, uint256 minIbethAmount) = __decodeCallArgs(_encodedCallArgs);

            spendAssets_ = new address[](1);
            spendAssets_[0] = WETH_TOKEN;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = wethAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = IBETH_TOKEN;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minIbethAmount;
        } else if (_selector == REDEEM_SELECTOR) {
            (uint256 ibethAmount, uint256 minWethAmount) = __decodeCallArgs(_encodedCallArgs);

            spendAssets_ = new address[](1);
            spendAssets_[0] = IBETH_TOKEN;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = ibethAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = WETH_TOKEN;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minWethAmount;
        } else {
            revert("parseAssetsForMethod: _selector invalid");
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @notice Lends WETH for ibETH
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function lend(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (uint256 wethAmount, ) = __decodeCallArgs(_encodedCallArgs);

        IWETH(payable(WETH_TOKEN)).withdraw(wethAmount);

        IAlphaHomoraV1Bank(IBETH_TOKEN).deposit{value: payable(address(this)).balance}();
    }

    /// @notice Redeems ibETH for WETH
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function redeem(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (uint256 ibethAmount, ) = __decodeCallArgs(_encodedCallArgs);

        IAlphaHomoraV1Bank(IBETH_TOKEN).withdraw(ibethAmount);

        IWETH(payable(WETH_TOKEN)).deposit{value: payable(address(this)).balance}();
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (uint256 outgoingAmount_, uint256 minIncomingAmount_)
    {
        return abi.decode(_encodedCallArgs, (uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `IBETH_TOKEN` variable
    /// @return ibethToken_ The `IBETH_TOKEN` variable value
    function getIbethToken() external view returns (address ibethToken_) {
        return IBETH_TOKEN;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/IParaSwapAugustusSwapper.sol";
import "../../../../interfaces/IWETH.sol";
import "../utils/AdapterBase.sol";

/// @title ParaSwapAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with ParaSwap
contract ParaSwapAdapter is AdapterBase {
    using SafeMath for uint256;

    string private constant REFERRER = "enzyme";

    address private immutable EXCHANGE;
    address private immutable TOKEN_TRANSFER_PROXY;
    address private immutable WETH_TOKEN;

    constructor(
        address _integrationManager,
        address _exchange,
        address _tokenTransferProxy,
        address _wethToken
    ) public AdapterBase(_integrationManager) {
        EXCHANGE = _exchange;
        TOKEN_TRANSFER_PROXY = _tokenTransferProxy;
        WETH_TOKEN = _wethToken;
    }

    /// @dev Needed to receive ETH refund from sent network fees
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "PARASWAP";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForMethod: _selector invalid");

        (
            address incomingAsset,
            uint256 minIncomingAssetAmount,
            ,
            address outgoingAsset,
            uint256 outgoingAssetAmount,
            IParaSwapAugustusSwapper.Path[] memory paths
        ) = __decodeCallArgs(_encodedCallArgs);

        // Format incoming assets
        incomingAssets_ = new address[](1);
        incomingAssets_[0] = incomingAsset;
        minIncomingAssetAmounts_ = new uint256[](1);
        minIncomingAssetAmounts_[0] = minIncomingAssetAmount;

        // Format outgoing assets depending on if there are network fees
        uint256 totalNetworkFees = __calcTotalNetworkFees(paths);
        if (totalNetworkFees > 0) {
            // We are not performing special logic if the incomingAsset is the fee asset
            if (outgoingAsset == WETH_TOKEN) {
                spendAssets_ = new address[](1);
                spendAssets_[0] = outgoingAsset;

                spendAssetAmounts_ = new uint256[](1);
                spendAssetAmounts_[0] = outgoingAssetAmount.add(totalNetworkFees);
            } else {
                spendAssets_ = new address[](2);
                spendAssets_[0] = outgoingAsset;
                spendAssets_[1] = WETH_TOKEN;

                spendAssetAmounts_ = new uint256[](2);
                spendAssetAmounts_[0] = outgoingAssetAmount;
                spendAssetAmounts_[1] = totalNetworkFees;
            }
        } else {
            spendAssets_ = new address[](1);
            spendAssets_[0] = outgoingAsset;

            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = outgoingAssetAmount;
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @notice Trades assets on ParaSwap
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function takeOrder(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        __takeOrder(_vaultProxy, _encodedCallArgs);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to parse the total amount of network fees (in ETH) for the multiSwap() call
    function __calcTotalNetworkFees(IParaSwapAugustusSwapper.Path[] memory _paths)
        private
        pure
        returns (uint256 totalNetworkFees_)
    {
        for (uint256 i; i < _paths.length; i++) {
            totalNetworkFees_ = totalNetworkFees_.add(_paths[i].totalNetworkFee);
        }

        return totalNetworkFees_;
    }

    /// @dev Helper to decode the encoded callOnIntegration call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address incomingAsset_,
            uint256 minIncomingAssetAmount_,
            uint256 expectedIncomingAssetAmount_, // Passed as a courtesy to ParaSwap for analytics
            address outgoingAsset_,
            uint256 outgoingAssetAmount_,
            IParaSwapAugustusSwapper.Path[] memory paths_
        )
    {
        return
            abi.decode(
                _encodedCallArgs,
                (address, uint256, uint256, address, uint256, IParaSwapAugustusSwapper.Path[])
            );
    }

    /// @dev Helper to encode the call to ParaSwap multiSwap() as low-level calldata.
    /// Avoids the stack-too-deep error.
    function __encodeMultiSwapCallData(
        address _vaultProxy,
        address _incomingAsset,
        uint256 _minIncomingAssetAmount,
        uint256 _expectedIncomingAssetAmount, // Passed as a courtesy to ParaSwap for analytics
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        IParaSwapAugustusSwapper.Path[] memory _paths
    ) private pure returns (bytes memory multiSwapCallData) {
        return
            abi.encodeWithSelector(
                IParaSwapAugustusSwapper.multiSwap.selector,
                _outgoingAsset, // fromToken
                _incomingAsset, // toToken
                _outgoingAssetAmount, // fromAmount
                _minIncomingAssetAmount, // toAmount
                _expectedIncomingAssetAmount, // expectedAmount
                _paths, // path
                0, // mintPrice
                payable(_vaultProxy), // beneficiary
                0, // donationPercentage
                REFERRER // referrer
            );
    }

    /// @dev Helper to execute ParaSwapAugustusSwapper.multiSwap() via a low-level call.
    /// Avoids the stack-too-deep error.
    function __executeMultiSwap(bytes memory _multiSwapCallData, uint256 _totalNetworkFees)
        private
    {
        (bool success, bytes memory returnData) = EXCHANGE.call{value: _totalNetworkFees}(
            _multiSwapCallData
        );
        require(success, string(returnData));
    }

    /// @dev Helper for the inner takeOrder() logic.
    /// Avoids the stack-too-deep error.
    function __takeOrder(address _vaultProxy, bytes memory _encodedCallArgs) private {
        (
            address incomingAsset,
            uint256 minIncomingAssetAmount,
            uint256 expectedIncomingAssetAmount,
            address outgoingAsset,
            uint256 outgoingAssetAmount,
            IParaSwapAugustusSwapper.Path[] memory paths
        ) = __decodeCallArgs(_encodedCallArgs);

        __approveMaxAsNeeded(outgoingAsset, TOKEN_TRANSFER_PROXY, outgoingAssetAmount);

        // If there are network fees, unwrap enough WETH to cover the fees
        uint256 totalNetworkFees = __calcTotalNetworkFees(paths);
        if (totalNetworkFees > 0) {
            __unwrapWeth(totalNetworkFees);
        }

        // Get the callData for the low-level multiSwap() call
        bytes memory multiSwapCallData = __encodeMultiSwapCallData(
            _vaultProxy,
            incomingAsset,
            minIncomingAssetAmount,
            expectedIncomingAssetAmount,
            outgoingAsset,
            outgoingAssetAmount,
            paths
        );

        // Execute the trade on ParaSwap
        __executeMultiSwap(multiSwapCallData, totalNetworkFees);

        // If fees were paid and ETH remains in the contract, wrap it as WETH so it can be returned
        if (totalNetworkFees > 0) {
            __wrapEth();
        }
    }

    /// @dev Helper to unwrap specified amount of WETH into ETH.
    /// Avoids the stack-too-deep error.
    function __unwrapWeth(uint256 _amount) private {
        IWETH(payable(WETH_TOKEN)).withdraw(_amount);
    }

    /// @dev Helper to wrap all ETH in contract as WETH.
    /// Avoids the stack-too-deep error.
    function __wrapEth() private {
        uint256 ethBalance = payable(address(this)).balance;
        if (ethBalance > 0) {
            IWETH(payable(WETH_TOKEN)).deposit{value: ethBalance}();
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXCHANGE` variable
    /// @return exchange_ The `EXCHANGE` variable value
    function getExchange() external view returns (address exchange_) {
        return EXCHANGE;
    }

    /// @notice Gets the `TOKEN_TRANSFER_PROXY` variable
    /// @return tokenTransferProxy_ The `TOKEN_TRANSFER_PROXY` variable value
    function getTokenTransferProxy() external view returns (address tokenTransferProxy_) {
        return TOKEN_TRANSFER_PROXY;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
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
pragma experimental ABIEncoderV2;

/// @title ParaSwap IAugustusSwapper interface
interface IParaSwapAugustusSwapper {
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

    function multiSwap(
        address,
        address,
        uint256,
        uint256,
        uint256,
        Path[] calldata,
        uint256,
        address payable,
        uint256,
        string calldata
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../release/interfaces/IParaSwapAugustusSwapper.sol";
import "../prices/CentralizedRateProvider.sol";
import "../utils/SwapperBase.sol";

contract MockParaSwapIntegratee is SwapperBase {
    using SafeMath for uint256;

    address private immutable MOCK_CENTRALIZED_RATE_PROVIDER;

    // Deviation set in % defines the MAX deviation per block from the mean rate
    uint256 private blockNumberDeviation;

    constructor(address _mockCentralizedRateProvider, uint256 _blockNumberDeviation) public {
        MOCK_CENTRALIZED_RATE_PROVIDER = _mockCentralizedRateProvider;
        blockNumberDeviation = _blockNumberDeviation;
    }

    /// @dev Must be `public` to avoid error
    function multiSwap(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256, // toAmount (min received amount)
        uint256, // expectedAmount
        IParaSwapAugustusSwapper.Path[] memory _paths,
        uint256, // mintPrice
        address, // beneficiary
        uint256, // donationPercentage
        string memory // referrer
    ) public payable returns (uint256) {
        return __multiSwap(_fromToken, _toToken, _fromAmount, _paths);
    }

    /// @dev Helper to parse the total amount of network fees (in ETH) for the multiSwap() call
    function __calcTotalNetworkFees(IParaSwapAugustusSwapper.Path[] memory _paths)
        private
        pure
        returns (uint256 totalNetworkFees_)
    {
        for (uint256 i; i < _paths.length; i++) {
            totalNetworkFees_ = totalNetworkFees_.add(_paths[i].totalNetworkFee);
        }

        return totalNetworkFees_;
    }

    /// @dev Helper to avoid the stack-too-deep error
    function __multiSwap(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        IParaSwapAugustusSwapper.Path[] memory _paths
    ) private returns (uint256) {
        address[] memory assetsFromIntegratee = new address[](1);
        assetsFromIntegratee[0] = _toToken;

        uint256[] memory assetsFromIntegrateeAmounts = new uint256[](1);
        assetsFromIntegrateeAmounts[0] = CentralizedRateProvider(MOCK_CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomized(_fromToken, _fromAmount, _toToken, blockNumberDeviation);

        uint256 totalNetworkFees = __calcTotalNetworkFees(_paths);
        address[] memory assetsToIntegratee;
        uint256[] memory assetsToIntegrateeAmounts;
        if (totalNetworkFees > 0) {
            assetsToIntegratee = new address[](2);
            assetsToIntegratee[1] = ETH_ADDRESS;

            assetsToIntegrateeAmounts = new uint256[](2);
            assetsToIntegrateeAmounts[1] = totalNetworkFees;
        } else {
            assetsToIntegratee = new address[](1);
            assetsToIntegrateeAmounts = new uint256[](1);
        }
        assetsToIntegratee[0] = _fromToken;
        assetsToIntegrateeAmounts[0] = _fromAmount;

        __swap(
            msg.sender,
            assetsToIntegratee,
            assetsToIntegrateeAmounts,
            assetsFromIntegratee,
            assetsFromIntegrateeAmounts
        );

        return assetsFromIntegrateeAmounts[0];
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    function getBlockNumberDeviation() external view returns (uint256 blockNumberDeviation_) {
        return blockNumberDeviation;
    }

    function getCentralizedRateProvider()
        external
        view
        returns (address centralizedRateProvider_)
    {
        return MOCK_CENTRALIZED_RATE_PROVIDER;
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

import "../../utils/NormalizedRateProviderBase.sol";
import "../../utils/SwapperBase.sol";

abstract contract MockIntegrateeBase is NormalizedRateProviderBase, SwapperBase {
    constructor(
        address[] memory _defaultRateAssets,
        address[] memory _specialAssets,
        uint8[] memory _specialAssetDecimals,
        uint256 _ratePrecision
    )
        public
        NormalizedRateProviderBase(
            _defaultRateAssets,
            _specialAssets,
            _specialAssetDecimals,
            _ratePrecision
        )
    {}

    function __getRate(address _baseAsset, address _quoteAsset)
        internal
        view
        override
        returns (uint256)
    {
        // 1. Return constant if base asset is quote asset
        if (_baseAsset == _quoteAsset) {
            return 10**RATE_PRECISION;
        }

        // 2. Check for a direct rate
        uint256 directRate = assetToAssetRate[_baseAsset][_quoteAsset];
        if (directRate > 0) {
            return directRate;
        }

        // 3. Check for inverse direct rate
        uint256 iDirectRate = assetToAssetRate[_quoteAsset][_baseAsset];
        if (iDirectRate > 0) {
            return 10**(RATE_PRECISION.mul(2)).div(iDirectRate);
        }

        // 4. Else return 1
        return 10**RATE_PRECISION;
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
import "./RateProviderBase.sol";

abstract contract NormalizedRateProviderBase is RateProviderBase {
    using SafeMath for uint256;

    uint256 public immutable RATE_PRECISION;

    constructor(
        address[] memory _defaultRateAssets,
        address[] memory _specialAssets,
        uint8[] memory _specialAssetDecimals,
        uint256 _ratePrecision
    ) public RateProviderBase(_specialAssets, _specialAssetDecimals) {
        RATE_PRECISION = _ratePrecision;

        for (uint256 i = 0; i < _defaultRateAssets.length; i++) {
            for (uint256 j = i + 1; j < _defaultRateAssets.length; j++) {
                assetToAssetRate[_defaultRateAssets[i]][_defaultRateAssets[j]] =
                    10**_ratePrecision;
                assetToAssetRate[_defaultRateAssets[j]][_defaultRateAssets[i]] =
                    10**_ratePrecision;
            }
        }
    }

    // TODO: move to main contracts' utils for use with prices
    function __calcDenormalizedQuoteAssetAmount(
        uint256 _baseAssetDecimals,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetDecimals,
        uint256 _rate
    ) internal view returns (uint256) {
        return
            _rate.mul(_baseAssetAmount).mul(10**_quoteAssetDecimals).div(
                10**(RATE_PRECISION.add(_baseAssetDecimals))
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

abstract contract RateProviderBase is EthConstantMixin {
    mapping(address => mapping(address => uint256)) public assetToAssetRate;

    // Handles non-ERC20 compliant assets like ETH and USD
    mapping(address => uint8) public specialAssetToDecimals;

    constructor(address[] memory _specialAssets, uint8[] memory _specialAssetDecimals) public {
        require(
            _specialAssets.length == _specialAssetDecimals.length,
            "constructor: _specialAssets and _specialAssetDecimals are uneven lengths"
        );
        for (uint256 i = 0; i < _specialAssets.length; i++) {
            specialAssetToDecimals[_specialAssets[i]] = _specialAssetDecimals[i];
        }

        specialAssetToDecimals[ETH_ADDRESS] = 18;
    }

    function __getDecimalsForAsset(address _asset) internal view returns (uint256) {
        uint256 decimals = specialAssetToDecimals[_asset];
        if (decimals == 0) {
            decimals = uint256(ERC20(_asset).decimals());
        }

        return decimals;
    }

    function __getRate(address _baseAsset, address _quoteAsset)
        internal
        view
        virtual
        returns (uint256)
    {
        return assetToAssetRate[_baseAsset][_quoteAsset];
    }

    function setRates(
        address[] calldata _baseAssets,
        address[] calldata _quoteAssets,
        uint256[] calldata _rates
    ) external {
        require(
            _baseAssets.length == _quoteAssets.length,
            "setRates: _baseAssets and _quoteAssets are uneven lengths"
        );
        require(
            _baseAssets.length == _rates.length,
            "setRates: _baseAssets and _rates are uneven lengths"
        );
        for (uint256 i = 0; i < _baseAssets.length; i++) {
            assetToAssetRate[_baseAssets[i]][_quoteAssets[i]] = _rates[i];
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

/// @title AssetUnitCacheMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin to store a cache of asset units
abstract contract AssetUnitCacheMixin {
    event AssetUnitCached(address indexed asset, uint256 prevUnit, uint256 nextUnit);

    mapping(address => uint256) private assetToUnit;

    /// @notice Caches the decimal-relative unit for a given asset
    /// @param _asset The asset for which to cache the decimal-relative unit
    /// @dev Callable by any account
    function cacheAssetUnit(address _asset) public {
        uint256 prevUnit = getCachedUnitForAsset(_asset);
        uint256 nextUnit = 10**uint256(ERC20(_asset).decimals());
        if (nextUnit != prevUnit) {
            assetToUnit[_asset] = nextUnit;
            emit AssetUnitCached(_asset, prevUnit, nextUnit);
        }
    }

    /// @notice Caches the decimal-relative units for multiple given assets
    /// @param _assets The assets for which to cache the decimal-relative units
    /// @dev Callable by any account
    function cacheAssetUnits(address[] memory _assets) public {
        for (uint256 i; i < _assets.length; i++) {
            cacheAssetUnit(_assets[i]);
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the cached decimal-relative unit for a given asset
    /// @param _asset The asset for which to get the cached decimal-relative unit
    /// @return unit_ The cached decimal-relative unit
    function getCachedUnitForAsset(address _asset) public view returns (uint256 unit_) {
        return assetToUnit[_asset];
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
    constructor(address _dispatcher) public SingleUnderlyingDerivativeRegistryMixin(_dispatcher) {}

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

import "../../../../utils/DispatcherOwnerMixin.sol";

/// @title SingleUnderlyingDerivativeRegistryMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice Mixin for derivative price feeds that handle multiple derivatives
/// that each have a single underlying asset
abstract contract SingleUnderlyingDerivativeRegistryMixin is DispatcherOwnerMixin {
    event DerivativeAdded(address indexed derivative, address indexed underlying);

    event DerivativeRemoved(address indexed derivative);

    mapping(address => address) private derivativeToUnderlying;

    constructor(address _dispatcher) public DispatcherOwnerMixin(_dispatcher) {}

    /// @notice Adds derivatives with corresponding underlyings to the price feed
    /// @param _derivatives The derivatives to add
    /// @param _underlyings The corresponding underlyings to add
    function addDerivatives(address[] memory _derivatives, address[] memory _underlyings)
        external
        virtual
        onlyDispatcherOwner
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
    function removeDerivatives(address[] memory _derivatives) external onlyDispatcherOwner {
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

import "../release/infrastructure/price-feeds/derivatives/feeds/utils/SingleUnderlyingDerivativeRegistryMixin.sol";

/// @title TestSingleUnderlyingDerivativeRegistry Contract
/// @author Enzyme Council <[email protected]finance>
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

import "../../../../interfaces/IAaveProtocolDataProvider.sol";
import "../IDerivativePriceFeed.sol";
import "./utils/PeggedDerivativesPriceFeedBase.sol";

/// @title AavePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Aave
contract AavePriceFeed is IDerivativePriceFeed, PeggedDerivativesPriceFeedBase {
    address private immutable AAVE_PROTOCOL_DATA_PROVIDER;

    constructor(address _dispatcher, address _aaveProtocolDataProvider)
        public
        PeggedDerivativesPriceFeedBase(_dispatcher)
    {
        AAVE_PROTOCOL_DATA_PROVIDER = _aaveProtocolDataProvider;
    }

    function __validateDerivative(address _derivative, address _underlying) internal override {
        super.__validateDerivative(_derivative, _underlying);

        (address aTokenAddress, , ) = IAaveProtocolDataProvider(AAVE_PROTOCOL_DATA_PROVIDER)
            .getReserveTokensAddresses(_underlying);

        require(
            aTokenAddress == _derivative,
            "__validateDerivative: Invalid aToken or token provided"
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `AAVE_PROTOCOL_DATA_PROVIDER` variable value
    /// @return aaveProtocolDataProvider_ The `AAVE_PROTOCOL_DATA_PROVIDER` variable value
    function getAaveProtocolDataProvider()
        external
        view
        returns (address aaveProtocolDataProvider_)
    {
        return AAVE_PROTOCOL_DATA_PROVIDER;
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../interfaces/IKyberNetworkProxy.sol";
import "../../../../interfaces/IWETH.sol";
import "../../../../utils/MathHelpers.sol";
import "../utils/AdapterBase.sol";

/// @title KyberAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for interacting with Kyber Network
contract KyberAdapter is AdapterBase, MathHelpers {
    address private immutable EXCHANGE;
    address private immutable WETH_TOKEN;

    constructor(
        address _integrationManager,
        address _exchange,
        address _wethToken
    ) public AdapterBase(_integrationManager) {
        EXCHANGE = _exchange;
        WETH_TOKEN = _wethToken;
    }

    /// @dev Needed to receive ETH from swap
    receive() external payable {}

    // EXTERNAL FUNCTIONS

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "KYBER_NETWORK";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
        require(_selector == TAKE_ORDER_SELECTOR, "parseAssetsForMethod: _selector invalid");

        (
            address incomingAsset,
            uint256 minIncomingAssetAmount,
            address outgoingAsset,
            uint256 outgoingAssetAmount
        ) = __decodeCallArgs(_encodedCallArgs);

        require(
            incomingAsset != outgoingAsset,
            "parseAssetsForMethod: incomingAsset and outgoingAsset asset cannot be the same"
        );
        require(outgoingAssetAmount > 0, "parseAssetsForMethod: outgoingAssetAmount must be >0");

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

    /// @notice Trades assets on Kyber
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function takeOrder(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (
            address incomingAsset,
            uint256 minIncomingAssetAmount,
            address outgoingAsset,
            uint256 outgoingAssetAmount
        ) = __decodeCallArgs(_encodedCallArgs);

        uint256 minExpectedRate = __calcNormalizedRate(
            ERC20(outgoingAsset).decimals(),
            outgoingAssetAmount,
            ERC20(incomingAsset).decimals(),
            minIncomingAssetAmount
        );

        if (outgoingAsset == WETH_TOKEN) {
            __swapNativeAssetToToken(incomingAsset, outgoingAssetAmount, minExpectedRate);
        } else if (incomingAsset == WETH_TOKEN) {
            __swapTokenToNativeAsset(outgoingAsset, outgoingAssetAmount, minExpectedRate);
        } else {
            __swapTokenToToken(incomingAsset, outgoingAsset, outgoingAssetAmount, minExpectedRate);
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address incomingAsset_,
            uint256 minIncomingAssetAmount_,
            address outgoingAsset_,
            uint256 outgoingAssetAmount_
        )
    {
        return abi.decode(_encodedCallArgs, (address, uint256, address, uint256));
    }

    /// @dev Executes a swap of ETH to ERC20
    function __swapNativeAssetToToken(
        address _incomingAsset,
        uint256 _outgoingAssetAmount,
        uint256 _minExpectedRate
    ) private {
        IWETH(payable(WETH_TOKEN)).withdraw(_outgoingAssetAmount);

        IKyberNetworkProxy(EXCHANGE).swapEtherToToken{value: _outgoingAssetAmount}(
            _incomingAsset,
            _minExpectedRate
        );
    }

    /// @dev Executes a swap of ERC20 to ETH
    function __swapTokenToNativeAsset(
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        uint256 _minExpectedRate
    ) private {
        __approveMaxAsNeeded(_outgoingAsset, EXCHANGE, _outgoingAssetAmount);

        IKyberNetworkProxy(EXCHANGE).swapTokenToEther(
            _outgoingAsset,
            _outgoingAssetAmount,
            _minExpectedRate
        );

        IWETH(payable(WETH_TOKEN)).deposit{value: payable(address(this)).balance}();
    }

    /// @dev Executes a swap of ERC20 to ERC20
    function __swapTokenToToken(
        address _incomingAsset,
        address _outgoingAsset,
        uint256 _outgoingAssetAmount,
        uint256 _minExpectedRate
    ) private {
        __approveMaxAsNeeded(_outgoingAsset, EXCHANGE, _outgoingAssetAmount);

        IKyberNetworkProxy(EXCHANGE).swapTokenToToken(
            _outgoingAsset,
            _outgoingAssetAmount,
            _incomingAsset,
            _minExpectedRate
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXCHANGE` variable
    /// @return exchange_ The `EXCHANGE` variable value
    function getExchange() external view returns (address exchange_) {
        return EXCHANGE;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
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

/// @title Kyber Network interface
interface IKyberNetworkProxy {
    function swapEtherToToken(address, uint256) external payable returns (uint256);

    function swapTokenToEther(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function swapTokenToToken(
        address,
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../release/utils/MathHelpers.sol";
import "../prices/CentralizedRateProvider.sol";
import "../utils/SwapperBase.sol";

contract MockKyberIntegratee is SwapperBase, Ownable, MathHelpers {
    using SafeMath for uint256;

    address private immutable CENTRALIZED_RATE_PROVIDER;
    address private immutable WETH;

    uint256 private constant PRECISION = 18;

    // Deviation set in % defines the MAX deviation per block from the mean rate
    uint256 private blockNumberDeviation;

    constructor(
        address _centralizedRateProvider,
        address _weth,
        uint256 _blockNumberDeviation
    ) public {
        CENTRALIZED_RATE_PROVIDER = _centralizedRateProvider;
        WETH = _weth;
        blockNumberDeviation = _blockNumberDeviation;
    }

    function swapEtherToToken(address _destToken, uint256) external payable returns (uint256) {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomized(WETH, msg.value, _destToken, blockNumberDeviation);

        __swapAssets(msg.sender, ETH_ADDRESS, msg.value, _destToken, destAmount);
        return msg.value;
    }

    function swapTokenToEther(
        address _srcToken,
        uint256 _srcAmount,
        uint256
    ) external returns (uint256) {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomized(_srcToken, _srcAmount, WETH, blockNumberDeviation);

        __swapAssets(msg.sender, _srcToken, _srcAmount, ETH_ADDRESS, destAmount);
        return _srcAmount;
    }

    function swapTokenToToken(
        address _srcToken,
        uint256 _srcAmount,
        address _destToken,
        uint256
    ) external returns (uint256) {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomized(_srcToken, _srcAmount, _destToken, blockNumberDeviation);

        __swapAssets(msg.sender, _srcToken, _srcAmount, _destToken, destAmount);
        return _srcAmount;
    }

    function setBlockNumberDeviation(uint256 _deviationPct) external onlyOwner {
        blockNumberDeviation = _deviationPct;
    }

    function getExpectedRate(
        address _srcToken,
        address _destToken,
        uint256 _amount
    ) external returns (uint256 rate_, uint256 worstRate_) {
        if (_srcToken == ETH_ADDRESS) {
            _srcToken = WETH;
        }
        if (_destToken == ETH_ADDRESS) {
            _destToken = WETH;
        }

        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomizedBySender(_srcToken, _amount, _destToken);
        rate_ = __calcNormalizedRate(
            ERC20(_srcToken).decimals(),
            _amount,
            ERC20(_destToken).decimals(),
            destAmount
        );
        worstRate_ = rate_.mul(uint256(100).sub(blockNumberDeviation)).div(100);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    function getCentralizedRateProvider() public view returns (address) {
        return CENTRALIZED_RATE_PROVIDER;
    }

    function getWeth() public view returns (address) {
        return WETH;
    }

    function getBlockNumberDeviation() public view returns (uint256) {
        return blockNumberDeviation;
    }

    function getPrecision() public pure returns (uint256) {
        return PRECISION;
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
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./../../release/interfaces/ISynthetixExchangeRates.sol";
import "../prices/MockChainlinkPriceSource.sol";

/// @dev This price source offers two different options getting prices
/// The first one is getting a fixed rate, which can be useful for tests
/// The second approach calculates dinamically the rate making use of a chainlink price source
/// Mocks the functionality of the folllowing Synthetix contracts: { Exchanger, ExchangeRates }
contract MockSynthetixPriceSource is Ownable, ISynthetixExchangeRates {
    using SafeMath for uint256;

    mapping(bytes32 => uint256) private fixedRate;
    mapping(bytes32 => AggregatorInfo) private currencyKeyToAggregator;

    enum RateAsset {ETH, USD}

    struct AggregatorInfo {
        address aggregator;
        RateAsset rateAsset;
    }

    constructor(address _ethUsdAggregator) public {
        currencyKeyToAggregator[bytes32("ETH")] = AggregatorInfo({
            aggregator: _ethUsdAggregator,
            rateAsset: RateAsset.USD
        });
    }

    function setPriceSourcesForCurrencyKeys(
        bytes32[] calldata _currencyKeys,
        address[] calldata _aggregators,
        RateAsset[] calldata _rateAssets
    ) external onlyOwner {
        require(
            _currencyKeys.length == _aggregators.length &&
                _rateAssets.length == _aggregators.length
        );
        for (uint256 i = 0; i < _currencyKeys.length; i++) {
            currencyKeyToAggregator[_currencyKeys[i]] = AggregatorInfo({
                aggregator: _aggregators[i],
                rateAsset: _rateAssets[i]
            });
        }
    }

    function setRate(bytes32 _currencyKey, uint256 _rate) external onlyOwner {
        fixedRate[_currencyKey] = _rate;
    }

    /// @dev Calculates the rate from a currency key against USD
    function rateAndInvalid(bytes32 _currencyKey)
        external
        view
        override
        returns (uint256 rate_, bool isInvalid_)
    {
        uint256 storedRate = getFixedRate(_currencyKey);
        if (storedRate != 0) {
            rate_ = storedRate;
        } else {
            AggregatorInfo memory aggregatorInfo = getAggregatorFromCurrencyKey(_currencyKey);
            address aggregator = aggregatorInfo.aggregator;
            if (aggregator == address(0)) {
                rate_ = 0;
                isInvalid_ = true;
                return (rate_, isInvalid_);
            }
            uint256 decimals = MockChainlinkPriceSource(aggregator).decimals();
            rate_ = uint256(MockChainlinkPriceSource(aggregator).latestAnswer()).mul(
                10**(uint256(18).sub(decimals))
            );

            if (aggregatorInfo.rateAsset == RateAsset.ETH) {
                uint256 ethToUsd = uint256(
                    MockChainlinkPriceSource(
                        getAggregatorFromCurrencyKey(bytes32("ETH"))
                            .aggregator
                    )
                        .latestAnswer()
                );
                rate_ = rate_.mul(ethToUsd).div(10**8);
            }
        }

        isInvalid_ = (rate_ == 0);
        return (rate_, isInvalid_);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    function getAggregatorFromCurrencyKey(bytes32 _currencyKey)
        public
        view
        returns (AggregatorInfo memory _aggregator)
    {
        return currencyKeyToAggregator[_currencyKey];
    }

    function getFixedRate(bytes32 _currencyKey) public view returns (uint256) {
        return fixedRate[_currencyKey];
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

contract MockChainlinkPriceSource {
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

    uint256 public DECIMALS;

    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint256 public roundId;
    address public aggregator;

    constructor(uint256 _decimals) public {
        DECIMALS = _decimals;
        latestAnswer = int256(10**_decimals);
        latestTimestamp = now;
        roundId = 1;
        aggregator = address(this);
    }

    function setLatestAnswer(int256 _nextAnswer, uint256 _nextTimestamp) external {
        latestAnswer = _nextAnswer;
        latestTimestamp = _nextTimestamp;
        roundId = roundId + 1;

        emit AnswerUpdated(latestAnswer, roundId, latestTimestamp);
    }

    function setAggregator(address _nextAggregator) external {
        aggregator = _nextAggregator;
    }

    function decimals() public view returns (uint256) {
        return DECIMALS;
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./../../release/interfaces/ISynthetixExchangeRates.sol";
import "../prices/CentralizedRateProvider.sol";
import "../tokens/MockSynthetixToken.sol";

/// @dev Synthetix Integratee. Mocks functionalities from the folllowing synthetix contracts
/// Synthetix, SynthetixAddressResolver, SynthetixDelegateApprovals
/// Link to contracts: <https://github.com/Synthetixio/synthetix/tree/develop/contracts>
contract MockSynthetixIntegratee is Ownable, MockToken {
    using SafeMath for uint256;

    mapping(address => mapping(address => bool)) private authorizerToDelegateToApproval;
    mapping(bytes32 => address) private currencyKeyToSynth;

    address private immutable CENTRALIZED_RATE_PROVIDER;
    address private immutable EXCHANGE_RATES;
    uint256 private immutable FEE;

    uint256 private constant UNIT_FEE = 1000;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _centralizedRateProvider,
        address _exchangeRates,
        uint256 _fee
    ) public MockToken(_name, _symbol, _decimals) {
        CENTRALIZED_RATE_PROVIDER = _centralizedRateProvider;
        EXCHANGE_RATES = address(_exchangeRates);
        FEE = _fee;
    }

    receive() external payable {}

    function exchangeOnBehalfWithTracking(
        address _exchangeForAddress,
        bytes32 _srcCurrencyKey,
        uint256 _srcAmount,
        bytes32 _destinationCurrencyKey,
        address,
        bytes32
    ) external returns (uint256 amountReceived_) {
        require(
            canExchangeFor(_exchangeForAddress, msg.sender),
            "exchangeOnBehalfWithTracking: Not approved to act on behalf"
        );

        amountReceived_ = __calculateAndSwap(
            _exchangeForAddress,
            _srcAmount,
            _srcCurrencyKey,
            _destinationCurrencyKey
        );

        return amountReceived_;
    }

    function getAmountsForExchange(
        uint256 _srcAmount,
        bytes32 _srcCurrencyKey,
        bytes32 _destCurrencyKey
    )
        public
        returns (
            uint256 amountReceived_,
            uint256 fee_,
            uint256 exchangeFeeRate_
        )
    {
        address srcToken = currencyKeyToSynth[_srcCurrencyKey];
        address destToken = currencyKeyToSynth[_destCurrencyKey];

        require(
            currencyKeyToSynth[_srcCurrencyKey] != address(0) &&
                currencyKeyToSynth[_destCurrencyKey] != address(0),
            "getAmountsForExchange: Currency key doesn't have an associated synth"
        );

        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomizedBySender(srcToken, _srcAmount, destToken);

        exchangeFeeRate_ = FEE;
        amountReceived_ = destAmount.mul(UNIT_FEE.sub(exchangeFeeRate_)).div(UNIT_FEE);
        fee_ = destAmount.sub(amountReceived_);

        return (amountReceived_, fee_, exchangeFeeRate_);
    }

    function setSynthFromCurrencyKeys(bytes32[] calldata _currencyKeys, address[] calldata _synths)
        external
    {
        require(
            _currencyKeys.length == _synths.length,
            "setSynthFromCurrencyKey: Unequal _currencyKeys and _synths lengths"
        );
        for (uint256 i = 0; i < _currencyKeys.length; i++) {
            currencyKeyToSynth[_currencyKeys[i]] = _synths[i];
        }
    }

    function approveExchangeOnBehalf(address _delegate) external {
        authorizerToDelegateToApproval[msg.sender][_delegate] = true;
    }

    function __calculateAndSwap(
        address _exchangeForAddress,
        uint256 _srcAmount,
        bytes32 _srcCurrencyKey,
        bytes32 _destCurrencyKey
    ) private returns (uint256 amountReceived_) {
        MockSynthetixToken srcSynth = MockSynthetixToken(currencyKeyToSynth[_srcCurrencyKey]);
        MockSynthetixToken destSynth = MockSynthetixToken(currencyKeyToSynth[_destCurrencyKey]);

        require(address(srcSynth) != address(0), "__calculateAndSwap: Source synth is not listed");
        require(
            address(destSynth) != address(0),
            "__calculateAndSwap: Destination synth is not listed"
        );
        require(
            !srcSynth.isLocked(_exchangeForAddress),
            "__calculateAndSwap: Cannot settle during waiting period"
        );

        (amountReceived_, , ) = getAmountsForExchange(
            _srcAmount,
            _srcCurrencyKey,
            _destCurrencyKey
        );

        srcSynth.burnFrom(_exchangeForAddress, _srcAmount);
        destSynth.mintFor(_exchangeForAddress, amountReceived_);
        destSynth.lock(_exchangeForAddress);

        return amountReceived_;
    }

    function requireAndGetAddress(bytes32 _name, string calldata)
        external
        view
        returns (address resolvedAddress_)
    {
        if (_name == "ExchangeRates") {
            return EXCHANGE_RATES;
        }
        return address(this);
    }

    function settle(address, bytes32)
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {}

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    function canExchangeFor(address _authorizer, address _delegate)
        public
        view
        returns (bool canExchange_)
    {
        return authorizerToDelegateToApproval[_authorizer][_delegate];
    }

    function getExchangeRates() public view returns (address exchangeRates_) {
        return EXCHANGE_RATES;
    }

    function getFee() public view returns (uint256 fee_) {
        return FEE;
    }

    function getSynthFromCurrencyKey(bytes32 _currencyKey) public view returns (address synth_) {
        return currencyKeyToSynth[_currencyKey];
    }

    function getUnitFee() public pure returns (uint256 fee_) {
        return UNIT_FEE;
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../prices/CentralizedRateProvider.sol";
import "./utils/SimpleMockIntegrateeBase.sol";

/// @dev Mocks the integration with `UniswapV2Router02` <https://uniswap.org/docs/v2/smart-contracts/router02/>
/// Additionally mocks the integration with `UniswapV2Factory` <https://uniswap.org/docs/v2/smart-contracts/factory/>
contract MockUniswapV2Integratee is SwapperBase, Ownable {
    using SafeMath for uint256;
    mapping(address => mapping(address => address)) private assetToAssetToPair;

    address private immutable CENTRALIZED_RATE_PROVIDER;
    uint256 private constant PRECISION = 18;

    // Set in %, defines the MAX deviation per block from the mean rate
    uint256 private blockNumberDeviation;

    constructor(
        address[] memory _listOfToken0,
        address[] memory _listOfToken1,
        address[] memory _listOfPair,
        address _centralizedRateProvider,
        uint256 _blockNumberDeviation
    ) public {
        addPair(_listOfToken0, _listOfToken1, _listOfPair);
        CENTRALIZED_RATE_PROVIDER = _centralizedRateProvider;
        blockNumberDeviation = _blockNumberDeviation;
    }

    /// @dev Adds the maximum possible value from {_amountADesired _amountBDesired}
    /// Makes use of the value interpreter to perform those calculations
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
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
    {
        __addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired);
    }

    /// @dev Removes the specified amount of liquidity
    /// Returns 50% of the incoming liquidity value on each token.
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256,
        uint256,
        address,
        uint256
    ) public returns (uint256, uint256) {
        __removeLiquidity(_tokenA, _tokenB, _liquidity);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address,
        uint256
    ) external returns (uint256[] memory) {
        uint256 amountOut = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomized(path[0], amountIn, path[1], blockNumberDeviation);

        __swapAssets(msg.sender, path[0], amountIn, path[path.length - 1], amountOut);
    }

    /// @dev We don't calculate any intermediate values here because they aren't actually used
    /// Returns the randomized by sender value of the edge path assets
    function getAmountsOut(uint256 _amountIn, address[] calldata _path)
        external
        returns (uint256[] memory amounts_)
    {
        require(_path.length >= 2, "getAmountsOut: path must be >= 2");

        address assetIn = _path[0];
        address assetOut = _path[_path.length - 1];

        uint256 amountOut = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValueRandomizedBySender(assetIn, _amountIn, assetOut);

        amounts_ = new uint256[](_path.length);
        amounts_[0] = _amountIn;
        amounts_[_path.length - 1] = amountOut;

        return amounts_;
    }

    function addPair(
        address[] memory _listOfToken0,
        address[] memory _listOfToken1,
        address[] memory _listOfPair
    ) public onlyOwner {
        require(
            _listOfPair.length == _listOfToken0.length,
            "constructor: _listOfPair and _listOfToken0 have an unequal length"
        );
        require(
            _listOfPair.length == _listOfToken1.length,
            "constructor: _listOfPair and _listOfToken1 have an unequal length"
        );
        for (uint256 i; i < _listOfPair.length; i++) {
            address token0 = _listOfToken0[i];
            address token1 = _listOfToken1[i];
            address pair = _listOfPair[i];
            assetToAssetToPair[token0][token1] = pair;
            assetToAssetToPair[token1][token0] = pair;
        }
    }

    function setBlockNumberDeviation(uint256 _deviationPct) external onlyOwner {
        blockNumberDeviation = _deviationPct;
    }

    // PRIVATE FUNCTIONS

    /// Avoids stack-too-deep error.
    function __addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) private {
        address pair = getPair(_tokenA, _tokenB);

        uint256 amountA;
        uint256 amountB;

        uint256 amountBFromA = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(_tokenA, _amountADesired, _tokenB);
        uint256 amountAFromB = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(_tokenB, _amountBDesired, _tokenA);

        if (amountBFromA >= _amountBDesired) {
            amountA = amountAFromB;
            amountB = _amountBDesired;
        } else {
            amountA = _amountADesired;
            amountB = amountBFromA;
        }

        uint256 tokenPerLPToken = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(pair, 10**uint256(PRECISION), _tokenA);

        // Calculate the inverse rate to know the amount of LPToken to return from a unit of token
        uint256 inverseRate = uint256(10**PRECISION).mul(10**PRECISION).div(tokenPerLPToken);

        // Total liquidity can be calculated as 2x liquidity from amount A
        uint256 totalLiquidity = uint256(2).mul(
            amountA.mul(inverseRate).div(uint256(10**PRECISION))
        );

        require(
            ERC20(pair).balanceOf(address(this)) >= totalLiquidity,
            "__addLiquidity: Integratee doesn't have enough pair balance to cover the expected amount"
        );

        address[] memory assetsToIntegratee = new address[](2);
        uint256[] memory assetsToIntegrateeAmounts = new uint256[](2);
        address[] memory assetsFromIntegratee = new address[](1);
        uint256[] memory assetsFromIntegrateeAmounts = new uint256[](1);

        assetsToIntegratee[0] = _tokenA;
        assetsToIntegrateeAmounts[0] = amountA;
        assetsToIntegratee[1] = _tokenB;
        assetsToIntegrateeAmounts[1] = amountB;
        assetsFromIntegratee[0] = pair;
        assetsFromIntegrateeAmounts[0] = totalLiquidity;

        __swap(
            msg.sender,
            assetsToIntegratee,
            assetsToIntegrateeAmounts,
            assetsFromIntegratee,
            assetsFromIntegrateeAmounts
        );
    }

    /// Avoids stack-too-deep error.
    function __removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity
    ) private {
        address pair = assetToAssetToPair[_tokenA][_tokenB];
        require(pair != address(0), "__removeLiquidity: this pair doesn't exist");

        uint256 amountA = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(pair, _liquidity, _tokenA)
            .div(uint256(2));

        uint256 amountB = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(pair, _liquidity, _tokenB)
            .div(uint256(2));

        address[] memory assetsToIntegratee = new address[](1);
        uint256[] memory assetsToIntegrateeAmounts = new uint256[](1);
        address[] memory assetsFromIntegratee = new address[](2);
        uint256[] memory assetsFromIntegrateeAmounts = new uint256[](2);

        assetsToIntegratee[0] = pair;
        assetsToIntegrateeAmounts[0] = _liquidity;
        assetsFromIntegratee[0] = _tokenA;
        assetsFromIntegrateeAmounts[0] = amountA;
        assetsFromIntegratee[1] = _tokenB;
        assetsFromIntegrateeAmounts[1] = amountB;

        require(
            ERC20(_tokenA).balanceOf(address(this)) >= amountA,
            "__removeLiquidity: Integratee doesn't have enough tokenA balance to cover the expected amount"
        );
        require(
            ERC20(_tokenB).balanceOf(address(this)) >= amountA,
            "__removeLiquidity: Integratee doesn't have enough tokenB balance to cover the expected amount"
        );

        __swap(
            msg.sender,
            assetsToIntegratee,
            assetsToIntegrateeAmounts,
            assetsFromIntegratee,
            assetsFromIntegrateeAmounts
        );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @dev By default set to address(0). It is read by UniswapV2PoolTokenValueCalculator: __calcPoolTokenValue
    function feeTo() external pure returns (address) {
        return address(0);
    }

    function getCentralizedRateProvider() public view returns (address) {
        return CENTRALIZED_RATE_PROVIDER;
    }

    function getBlockNumberDeviation() public view returns (uint256) {
        return blockNumberDeviation;
    }

    function getPrecision() public pure returns (uint256) {
        return PRECISION;
    }

    function getPair(address _token0, address _token1) public view returns (address) {
        return assetToAssetToPair[_token0][_token1];
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

import "./MockIntegrateeBase.sol";

abstract contract SimpleMockIntegrateeBase is MockIntegrateeBase {
    constructor(
        address[] memory _defaultRateAssets,
        address[] memory _specialAssets,
        uint8[] memory _specialAssetDecimals,
        uint256 _ratePrecision
    )
        public
        MockIntegrateeBase(
            _defaultRateAssets,
            _specialAssets,
            _specialAssetDecimals,
            _ratePrecision
        )
    {}

    function __getRateAndSwapAssets(
        address payable _trader,
        address _srcToken,
        uint256 _srcAmount,
        address _destToken
    ) internal returns (uint256 destAmount_) {
        uint256 actualRate = __getRate(_srcToken, _destToken);
        __swapAssets(_trader, _srcToken, _srcAmount, _destToken, actualRate);
        return actualRate;
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../../prices/CentralizedRateProvider.sol";
import "../../utils/SwapperBase.sol";

contract MockCTokenBase is ERC20, SwapperBase, Ownable {
    address internal immutable TOKEN;
    address internal immutable CENTRALIZED_RATE_PROVIDER;

    uint256 internal rate;

    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _token,
        address _centralizedRateProvider,
        uint256 _initialRate
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        TOKEN = _token;
        CENTRALIZED_RATE_PROVIDER = _centralizedRateProvider;
        rate = _initialRate;
    }

    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        _allowances[msg.sender][_spender] = _amount;
        return true;
    }

    /// @dev Overriden `allowance` function, give the integratee infinite approval by default
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        if (_spender == address(this) || _owner == _spender) {
            return 2**256 - 1;
        } else {
            return _allowances[_owner][_spender];
        }
    }

    /// @dev Necessary as this contract doesn't directly inherit from MockToken
    function mintFor(address _who, uint256 _amount) external onlyOwner {
        _mint(_who, _amount);
    }

    /// @dev Necessary to allow updates on persistent deployments (e.g Kovan)
    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    // INTERNAL FUNCTIONS

    /// @dev Calculates the cTokenAmount given a tokenAmount
    /// Makes use of a inverse rate with the CentralizedRateProvider as a derivative can't be used as quoteAsset
    function __calcCTokenAmount(uint256 _tokenAmount) internal returns (uint256 cTokenAmount_) {
        uint256 tokenDecimals = ERC20(TOKEN).decimals();
        uint256 cTokenDecimals = decimals();

        // Result in Token Decimals
        uint256 tokenPerCTokenUnit = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(address(this), 10**uint256(cTokenDecimals), TOKEN);

        // Result in cToken decimals
        uint256 inverseRate = uint256(10**tokenDecimals).mul(10**uint256(cTokenDecimals)).div(
            tokenPerCTokenUnit
        );

        // Amount in token decimals, result in cToken decimals
        cTokenAmount_ = _tokenAmount.mul(inverseRate).div(10**tokenDecimals);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @dev Part of ICERC20 token interface
    function underlying() public view returns (address) {
        return TOKEN;
    }

    /// @dev Part of ICERC20 token interface.
    /// Called from CompoundPriceFeed, returns the actual Rate cToken/Token
    function exchangeRateStored() public view returns (uint256) {
        return rate;
    }

    function getCentralizedRateProvider() public view returns (address) {
        return CENTRALIZED_RATE_PROVIDER;
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

import "./MockCTokenBase.sol";

contract MockCTokenIntegratee is MockCTokenBase {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _token,
        address _centralizedRateProvider,
        uint256 _initialRate
    )
        public
        MockCTokenBase(_name, _symbol, _decimals, _token, _centralizedRateProvider, _initialRate)
    {}

    function mint(uint256 _amount) external returns (uint256) {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER).calcLiveAssetValue(
            TOKEN,
            _amount,
            address(this)
        );

        __swapAssets(msg.sender, TOKEN, _amount, address(this), destAmount);
        return _amount;
    }

    function redeem(uint256 _amount) external returns (uint256) {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER).calcLiveAssetValue(
            address(this),
            _amount,
            TOKEN
        );
        __swapAssets(msg.sender, address(this), _amount, TOKEN, destAmount);
        return _amount;
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

import "./MockCTokenBase.sol";

contract MockCEtherIntegratee is MockCTokenBase {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _weth,
        address _centralizedRateProvider,
        uint256 _initialRate
    )
        public
        MockCTokenBase(_name, _symbol, _decimals, _weth, _centralizedRateProvider, _initialRate)
    {}

    function mint() external payable {
        uint256 amount = msg.value;
        uint256 destAmount = __calcCTokenAmount(amount);
        __swapAssets(msg.sender, ETH_ADDRESS, amount, address(this), destAmount);
    }

    function redeem(uint256 _amount) external returns (uint256) {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER).calcLiveAssetValue(
            address(this),
            _amount,
            TOKEN
        );
        __swapAssets(msg.sender, address(this), _amount, ETH_ADDRESS, destAmount);
        return _amount;
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
import "../../../../utils/AddressArrayLib.sol";
import "../utils/AddressListPolicyMixin.sol";
import "./utils/PostCallOnIntegrationValidatePolicyBase.sol";

/// @title AssetWhitelist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that only allows a configurable whitelist of assets in a fund's holdings
contract AssetWhitelist is PostCallOnIntegrationValidatePolicyBase, AddressListPolicyMixin {
    using AddressArrayLib for address[];

    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// @notice Validates and initializes a policy as necessary prior to fund activation
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _vaultProxy The fund's VaultProxy address
    function activateForFund(address _comptrollerProxy, address _vaultProxy)
        external
        override
        onlyPolicyManager
    {
        require(
            passesRule(_comptrollerProxy, VaultLib(_vaultProxy).getTrackedAssets()),
            "activateForFund: Non-whitelisted asset detected"
        );
    }

    /// @notice Add the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        address[] memory assets = abi.decode(_encodedSettings, (address[]));
        require(
            assets.contains(ComptrollerLib(_comptrollerProxy).getDenominationAsset()),
            "addFundSettings: Must whitelist denominationAsset"
        );

        __addToList(_comptrollerProxy, abi.decode(_encodedSettings, (address[])));
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "ASSET_WHITELIST";
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
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, , address[] memory incomingAssets, , , ) = __decodeRuleArgs(_encodedArgs);

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
import "../../../../utils/AddressArrayLib.sol";
import "../utils/AddressListPolicyMixin.sol";
import "./utils/PostCallOnIntegrationValidatePolicyBase.sol";

/// @title AssetBlacklist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that disallows a configurable blacklist of assets in a fund's holdings
contract AssetBlacklist is PostCallOnIntegrationValidatePolicyBase, AddressListPolicyMixin {
    using AddressArrayLib for address[];

    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// @notice Validates and initializes a policy as necessary prior to fund activation
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _vaultProxy The fund's VaultProxy address
    function activateForFund(address _comptrollerProxy, address _vaultProxy)
        external
        override
        onlyPolicyManager
    {
        require(
            passesRule(_comptrollerProxy, VaultLib(_vaultProxy).getTrackedAssets()),
            "activateForFund: Blacklisted asset detected"
        );
    }

    /// @notice Add the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        address[] memory assets = abi.decode(_encodedSettings, (address[]));
        require(
            !assets.contains(ComptrollerLib(_comptrollerProxy).getDenominationAsset()),
            "addFundSettings: Cannot blacklist denominationAsset"
        );

        __addToList(_comptrollerProxy, assets);
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "ASSET_BLACKLIST";
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
            if (isInList(_comptrollerProxy, _assets[i])) {
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
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, , address[] memory incomingAssets, , , ) = __decodeRuleArgs(_encodedArgs);

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

import "../utils/AddressListPolicyMixin.sol";
import "./utils/PreCallOnIntegrationValidatePolicyBase.sol";

/// @title AdapterWhitelist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that only allows a configurable whitelist of adapters for use by a fund
contract AdapterWhitelist is PreCallOnIntegrationValidatePolicyBase, AddressListPolicyMixin {
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
        return "ADAPTER_WHITELIST";
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _adapter The adapter with which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address _adapter)
        public
        view
        returns (bool isValid_)
    {
        return isInList(_comptrollerProxy, _adapter);
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address adapter, ) = __decodeRuleArgs(_encodedArgs);

        return passesRule(_comptrollerProxy, adapter);
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

import "../../utils/PolicyBase.sol";

/// @title CallOnIntegrationPreValidatePolicyMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for policies that only implement the PreCallOnIntegration policy hook
abstract contract PreCallOnIntegrationValidatePolicyBase is PolicyBase {
    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        view
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PreCallOnIntegration;

        return implementedHooks_;
    }

    /// @notice Helper to decode rule arguments
    function __decodeRuleArgs(bytes memory _encodedRuleArgs)
        internal
        pure
        returns (address adapter_, bytes4 selector_)
    {
        return abi.decode(_encodedRuleArgs, (address, bytes4));
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
import "../../../utils/FundDeployerOwnerMixin.sol";
import "./utils/PreCallOnIntegrationValidatePolicyBase.sol";

/// @title GuaranteedRedemption Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that guarantees that shares will either be continuously redeemable or
/// redeemable within a predictable daily window by preventing trading during a configurable daily period
contract GuaranteedRedemption is PreCallOnIntegrationValidatePolicyBase, FundDeployerOwnerMixin {
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
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address adapter, ) = __decodeRuleArgs(_encodedArgs);

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

import "../utils/AddressListPolicyMixin.sol";
import "./utils/PreCallOnIntegrationValidatePolicyBase.sol";

/// @title AdapterBlacklist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that disallows a configurable blacklist of adapters from use by a fund
contract AdapterBlacklist is PreCallOnIntegrationValidatePolicyBase, AddressListPolicyMixin {
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
        return "ADAPTER_BLACKLIST";
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _adapter The adapter with which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address _adapter)
        public
        view
        returns (bool isValid_)
    {
        return !isInList(_comptrollerProxy, _adapter);
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address adapter, ) = __decodeRuleArgs(_encodedArgs);

        return passesRule(_comptrollerProxy, adapter);
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
import "./utils/PreBuySharesValidatePolicyBase.sol";

/// @title InvestorWhitelist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that only allows a configurable whitelist of investors to buy shares in a fund
contract InvestorWhitelist is PreBuySharesValidatePolicyBase, AddressListPolicyMixin {
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

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "INVESTOR_WHITELIST";
    }

    /// @notice Updates the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(
        address _comptrollerProxy,
        address,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
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
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address buyer, , , ) = __decodeRuleArgs(_encodedArgs);

        return passesRule(_comptrollerProxy, buyer);
    }

    /// @dev Helper to update the investor whitelist by adding and/or removing addresses
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

import "../../utils/PolicyBase.sol";

/// @title BuySharesPolicyMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for policies that only implement the PreBuyShares policy hook
abstract contract PreBuySharesValidatePolicyBase is PolicyBase {
    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        view
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.PreBuyShares;

        return implementedHooks_;
    }

    /// @notice Helper to decode rule arguments
    function __decodeRuleArgs(bytes memory _encodedArgs)
        internal
        pure
        returns (
            address buyer_,
            uint256 investmentAmount_,
            uint256 minSharesQuantity_,
            uint256 gav_
        )
    {
        return abi.decode(_encodedArgs, (address, uint256, uint256, uint256));
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

import "./utils/PreBuySharesValidatePolicyBase.sol";

/// @title MinMaxInvestment Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that restricts the amount of the fund's denomination asset that a user can
/// send in a single call to buy shares in a fund
contract MinMaxInvestment is PreBuySharesValidatePolicyBase {
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

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "MIN_MAX_INVESTMENT";
    }

    /// @notice Updates the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(
        address _comptrollerProxy,
        address,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
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
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (, uint256 investmentAmount, , ) = __decodeRuleArgs(_encodedArgs);

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
import "./utils/BuySharesSetupPolicyBase.sol";

/// @title BuySharesCallerWhitelist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that only allows a configurable whitelist of buyShares callers for a fund
contract BuySharesCallerWhitelist is BuySharesSetupPolicyBase, AddressListPolicyMixin {
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

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "BUY_SHARES_CALLER_WHITELIST";
    }

    /// @notice Updates the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(
        address _comptrollerProxy,
        address,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
        __updateList(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _buySharesCaller The buyShares caller for which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address _buySharesCaller)
        public
        view
        returns (bool isValid_)
    {
        return isInList(_comptrollerProxy, _buySharesCaller);
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address caller, , ) = __decodeRuleArgs(_encodedArgs);

        return passesRule(_comptrollerProxy, caller);
    }

    /// @dev Helper to update the whitelist by adding and/or removing addresses
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

import "../../utils/PolicyBase.sol";

/// @title BuySharesSetupPolicyBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract for policies that only implement the BuySharesSetup policy hook
abstract contract BuySharesSetupPolicyBase is PolicyBase {
    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        view
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.BuySharesSetup;

        return implementedHooks_;
    }

    /// @notice Helper to decode rule arguments
    function __decodeRuleArgs(bytes memory _encodedArgs)
        internal
        pure
        returns (
            address caller_,
            uint256[] memory investmentAmounts_,
            uint256 gav_
        )
    {
        return abi.decode(_encodedArgs, (address, uint256[], uint256));
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

import "../../../../core/fund/vault/VaultLib.sol";
import "../utils/AdapterBase.sol";

/// @title TrackedAssetsAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter to add tracked assets to a fund (useful e.g. to handle token airdrops)
contract TrackedAssetsAdapter is AdapterBase {
    constructor(address _integrationManager) public AdapterBase(_integrationManager) {}

    /// @notice Add multiple assets to the Vault's list of tracked assets
    /// @dev No need to perform any validation or implement any logic
    function addTrackedAssets(
        address,
        bytes calldata,
        bytes calldata
    ) external view {}

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "TRACKED_ASSETS";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
        require(
            _selector == ADD_TRACKED_ASSETS_SELECTOR,
            "parseAssetsForMethod: _selector invalid"
        );

        incomingAssets_ = __decodeCallArgs(_encodedCallArgs);

        minIncomingAssetAmounts_ = new uint256[](incomingAssets_.length);
        for (uint256 i; i < minIncomingAssetAmounts_.length; i++) {
            minIncomingAssetAmounts_[i] = 1;
        }

        return (
            spendAssetsHandleType_,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (address[] memory incomingAssets_)
    {
        return abi.decode(_encodedCallArgs, (address[]));
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

import "../utils/IMigrationHookHandler.sol";
import "../utils/IMigratableVault.sol";
import "../vault/VaultProxy.sol";
import "./IDispatcher.sol";

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

pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ICERC20 Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with Compound tokens (cTokens)
interface ICERC20 is IERC20 {
    function decimals() external view returns (uint8);

    function mint(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../interfaces/ICERC20.sol";
import "../../../utils/DispatcherOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title CompoundPriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price source oracle for Compound Tokens (cTokens)
contract CompoundPriceFeed is IDerivativePriceFeed, DispatcherOwnerMixin {
    using SafeMath for uint256;

    event CTokenAdded(address indexed cToken, address indexed token);

    uint256 private constant CTOKEN_RATE_DIVISOR = 10**18;

    mapping(address => address) private cTokenToToken;

    constructor(
        address _dispatcher,
        address _weth,
        address _ceth,
        address[] memory cERC20Tokens
    ) public DispatcherOwnerMixin(_dispatcher) {
        // Set cEth
        cTokenToToken[_ceth] = _weth;
        emit CTokenAdded(_ceth, _weth);

        // Set any other cTokens
        if (cERC20Tokens.length > 0) {
            __addCERC20Tokens(cERC20Tokens);
        }
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
    function addCTokens(address[] calldata _cTokens) external onlyDispatcherOwner {
        __addCERC20Tokens(_cTokens);
    }

    /// @dev Helper to add cTokens
    function __addCERC20Tokens(address[] memory _cTokens) private {
        require(_cTokens.length > 0, "__addCTokens: Empty _cTokens");

        for (uint256 i; i < _cTokens.length; i++) {
            require(cTokenToToken[_cTokens[i]] == address(0), "__addCTokens: Value already set");

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

import "../../../../infrastructure/price-feeds/derivatives/feeds/CompoundPriceFeed.sol";
import "../../../../interfaces/ICERC20.sol";
import "../../../../interfaces/ICEther.sol";
import "../../../../interfaces/IWETH.sol";
import "../utils/AdapterBase.sol";

/// @title CompoundAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Compound <https://compound.finance/>
contract CompoundAdapter is AdapterBase {
    address private immutable COMPOUND_PRICE_FEED;
    address private immutable WETH_TOKEN;

    constructor(
        address _integrationManager,
        address _compoundPriceFeed,
        address _wethToken
    ) public AdapterBase(_integrationManager) {
        COMPOUND_PRICE_FEED = _compoundPriceFeed;
        WETH_TOKEN = _wethToken;
    }

    /// @dev Needed to receive ETH during cEther lend/redeem
    receive() external payable {}

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "COMPOUND";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
            (address cToken, uint256 tokenAmount, uint256 minCTokenAmount) = __decodeCallArgs(
                _encodedCallArgs
            );
            address token = CompoundPriceFeed(COMPOUND_PRICE_FEED).getTokenFromCToken(cToken);
            require(token != address(0), "parseAssetsForMethod: Unsupported cToken");

            spendAssets_ = new address[](1);
            spendAssets_[0] = token;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = tokenAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = cToken;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minCTokenAmount;
        } else if (_selector == REDEEM_SELECTOR) {
            (address cToken, uint256 cTokenAmount, uint256 minTokenAmount) = __decodeCallArgs(
                _encodedCallArgs
            );
            address token = CompoundPriceFeed(COMPOUND_PRICE_FEED).getTokenFromCToken(cToken);
            require(token != address(0), "parseAssetsForMethod: Unsupported cToken");

            spendAssets_ = new address[](1);
            spendAssets_[0] = cToken;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = cTokenAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = token;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minTokenAmount;
        } else {
            revert("parseAssetsForMethod: _selector invalid");
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @notice Lends an amount of a token to Compound
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function lend(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        // More efficient to parse all from _encodedAssetTransferArgs
        (
            ,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeEncodedAssetTransferArgs(_encodedAssetTransferArgs);

        if (spendAssets[0] == WETH_TOKEN) {
            IWETH(WETH_TOKEN).withdraw(spendAssetAmounts[0]);
            ICEther(incomingAssets[0]).mint{value: spendAssetAmounts[0]}();
        } else {
            __approveMaxAsNeeded(spendAssets[0], incomingAssets[0], spendAssetAmounts[0]);
            ICERC20(incomingAssets[0]).mint(spendAssetAmounts[0]);
        }
    }

    /// @notice Redeems an amount of cTokens from Compound
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function redeem(
        address _vaultProxy,
        bytes calldata,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        // More efficient to parse all from _encodedAssetTransferArgs
        (
            ,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeEncodedAssetTransferArgs(_encodedAssetTransferArgs);

        ICERC20(spendAssets[0]).redeem(spendAssetAmounts[0]);

        if (incomingAssets[0] == WETH_TOKEN) {
            IWETH(payable(WETH_TOKEN)).deposit{value: payable(address(this)).balance}();
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address cToken_,
            uint256 outgoingAssetAmount_,
            uint256 minIncomingAssetAmount_
        )
    {
        return abi.decode(_encodedCallArgs, (address, uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `COMPOUND_PRICE_FEED` variable
    /// @return compoundPriceFeed_ The `COMPOUND_PRICE_FEED` variable value
    function getCompoundPriceFeed() external view returns (address compoundPriceFeed_) {
        return COMPOUND_PRICE_FEED;
    }

    /// @notice Gets the `WETH_TOKEN` variable
    /// @return wethToken_ The `WETH_TOKEN` variable value
    function getWethToken() external view returns (address wethToken_) {
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

pragma solidity ^0.6.12;

/// @title ICEther Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for interactions with Compound Ether
interface ICEther {
    function mint() external payable;
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

/// @title IChai Interface
/// @author Enzyme Council <[email protected]>
/// @notice Minimal interface for our interactions with the Chai contract
interface IChai is IERC20 {
    function exit(address, uint256) external;

    function join(address, uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../interfaces/IChai.sol";
import "../utils/AdapterBase.sol";

/// @title ChaiAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Chai <https://github.com/dapphub/chai>
contract ChaiAdapter is AdapterBase {
    address private immutable CHAI;
    address private immutable DAI;

    constructor(
        address _integrationManager,
        address _chai,
        address _dai
    ) public AdapterBase(_integrationManager) {
        CHAI = _chai;
        DAI = _dai;
    }

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "CHAI";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
            (uint256 daiAmount, uint256 minChaiAmount) = __decodeCallArgs(_encodedCallArgs);

            spendAssets_ = new address[](1);
            spendAssets_[0] = DAI;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = daiAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = CHAI;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minChaiAmount;
        } else if (_selector == REDEEM_SELECTOR) {
            (uint256 chaiAmount, uint256 minDaiAmount) = __decodeCallArgs(_encodedCallArgs);

            spendAssets_ = new address[](1);
            spendAssets_[0] = CHAI;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = chaiAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = DAI;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = minDaiAmount;
        } else {
            revert("parseAssetsForMethod: _selector invalid");
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @notice Lend Dai for Chai
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function lend(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (uint256 daiAmount, ) = __decodeCallArgs(_encodedCallArgs);

        __approveMaxAsNeeded(DAI, CHAI, daiAmount);

        // Execute Lend on Chai
        // Chai.join allows specifying the vaultProxy as the destination of Chai tokens
        IChai(CHAI).join(_vaultProxy, daiAmount);
    }

    /// @notice Redeem Chai for Dai
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedCallArgs Encoded order parameters
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function redeem(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (uint256 chaiAmount, ) = __decodeCallArgs(_encodedCallArgs);

        // Execute redeem on Chai
        // Chai.exit sends Dai back to the adapter
        IChai(CHAI).exit(address(this), chaiAmount);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (uint256 outgoingAmount_, uint256 minIncomingAmount_)
    {
        return abi.decode(_encodedCallArgs, (uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `CHAI` variable value
    /// @return chai_ The `CHAI` variable value
    function getChai() external view returns (address chai_) {
        return CHAI;
    }

    /// @notice Gets the `DAI` variable value
    /// @return dai_ The `DAI` variable value
    function getDai() external view returns (address dai_) {
        return DAI;
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

import "../utils/SwapperBase.sol";

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

import "../prices/CentralizedRateProvider.sol";
import "../tokens/MockToken.sol";
import "../utils/SwapperBase.sol";

contract MockChaiIntegratee is MockToken, SwapperBase {
    address private immutable CENTRALIZED_RATE_PROVIDER;
    address public immutable DAI;

    constructor(
        address _dai,
        address _centralizedRateProvider,
        uint8 _decimals
    ) public MockToken("Chai", "CHAI", _decimals) {
        _setupDecimals(_decimals);
        CENTRALIZED_RATE_PROVIDER = _centralizedRateProvider;
        DAI = _dai;
    }

    function join(address, uint256 _daiAmount) external {
        uint256 tokenDecimals = ERC20(DAI).decimals();
        uint256 chaiDecimals = decimals();

        // Calculate the amount of tokens per one unit of DAI
        uint256 daiPerChaiUnit = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER)
            .calcLiveAssetValue(address(this), 10**uint256(chaiDecimals), DAI);

        // Calculate the inverse rate to know the amount of CHAI to return from a unit of DAI
        uint256 inverseRate = uint256(10**tokenDecimals).mul(10**uint256(chaiDecimals)).div(
            daiPerChaiUnit
        );
        // Mint and send those CHAI to sender
        uint256 destAmount = _daiAmount.mul(inverseRate).div(10**tokenDecimals);
        _mint(address(this), destAmount);
        __swapAssets(msg.sender, DAI, _daiAmount, address(this), destAmount);
    }

    function exit(address payable _trader, uint256 _chaiAmount) external {
        uint256 destAmount = CentralizedRateProvider(CENTRALIZED_RATE_PROVIDER).calcLiveAssetValue(
            address(this),
            _chaiAmount,
            DAI
        );
        // Burn CHAI of the trader.
        _burn(_trader, _chaiAmount);
        // Release DAI to the trader.
        ERC20(DAI).transfer(msg.sender, destAmount);
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

    uint256 private constant RATE_DIVISOR = 10**18;
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

    /// @notice Add the fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the policy for a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        external
        override
        onlyFeeManager
    {
        uint256 rate = abi.decode(_settingsData, (uint256));
        require(rate > 0, "addFundSettings: Fee rate must be >0");

        comptrollerProxyToRate[_comptrollerProxy] = rate;

        emit FundSettingsAdded(_comptrollerProxy, rate);
    }

    /// @notice Gets the hooks that are implemented by the fee
    /// @return implementedHooksForSettle_ The hooks during which settle() is implemented
    /// @return implementedHooksForUpdate_ The hooks during which update() is implemented
    /// @return usesGavOnSettle_ True if GAV is used during the settle() implementation
    /// @return usesGavOnUpdate_ True if GAV is used during the update() implementation
    /// @dev Used only during fee registration
    function implementedHooks()
        external
        view
        override
        returns (
            IFeeManager.FeeHook[] memory implementedHooksForSettle_,
            IFeeManager.FeeHook[] memory implementedHooksForUpdate_,
            bool usesGavOnSettle_,
            bool usesGavOnUpdate_
        )
    {
        implementedHooksForSettle_ = new IFeeManager.FeeHook[](1);
        implementedHooksForSettle_[0] = IFeeManager.FeeHook.PostBuyShares;

        return (implementedHooksForSettle_, new IFeeManager.FeeHook[](0), false, false);
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
        sharesDue_ = sharesBought.mul(rate).div(RATE_DIVISOR.add(rate));

        if (sharesDue_ == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        emit Settled(_comptrollerProxy, payer_, sharesDue_);

        return (SETTLEMENT_TYPE, payer_, sharesDue_);
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

/// @title EntranceRateDirectFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice An EntranceRateFee that transfers the fee shares to the fund manager
contract EntranceRateDirectFee is EntranceRateFeeBase {
    constructor(address _feeManager)
        public
        EntranceRateFeeBase(_feeManager, IFeeManager.SettlementType.Direct)
    {}

    /// @notice Provides a constant string identifier for a fee
    /// @return identifier_ The identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "ENTRANCE_RATE_DIRECT";
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

    /// @notice Provides a constant string identifier for a fee
    /// @return identifier_ The identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "ENTRANCE_RATE_BURN";
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

contract MockChaiPriceSource {
    using SafeMath for uint256;

    uint256 private chiStored = 10**27;
    uint256 private rhoStored = now;

    function drip() external returns (uint256) {
        require(now >= rhoStored, "drip: invalid now");
        rhoStored = now;
        chiStored = chiStored.mul(99).div(100);
        return chi();
    }

    ////////////////////
    // STATE GETTERS //
    ///////////////////

    function chi() public view returns (uint256) {
        return chiStored;
    }

    function rho() public view returns (uint256) {
        return rhoStored;
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

import "../../utils/DispatcherOwnerMixin.sol";
import "./IAggregatedDerivativePriceFeed.sol";

/// @title AggregatedDerivativePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Aggregates multiple derivative price feeds (e.g., Compound, Chai) and dispatches
/// rate requests to the appropriate feed
contract AggregatedDerivativePriceFeed is IAggregatedDerivativePriceFeed, DispatcherOwnerMixin {
    event DerivativeAdded(address indexed derivative, address priceFeed);

    event DerivativeRemoved(address indexed derivative);

    event DerivativeUpdated(
        address indexed derivative,
        address prevPriceFeed,
        address nextPriceFeed
    );

    mapping(address => address) private derivativeToPriceFeed;

    constructor(
        address _dispatcher,
        address[] memory _derivatives,
        address[] memory _priceFeeds
    ) public DispatcherOwnerMixin(_dispatcher) {
        if (_derivatives.length > 0) {
            __addDerivatives(_derivatives, _priceFeeds);
        }
    }

    /// @notice Gets the rates for 1 unit of the derivative to its underlying assets
    /// @param _derivative The derivative for which to get the rates
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The rates for the _derivative to the underlyings_
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address derivativePriceFeed = derivativeToPriceFeed[_derivative];
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

    /// @notice Checks whether an asset is a supported derivative
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is a supported derivative
    /// @dev This should be as low-cost and simple as possible
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return derivativeToPriceFeed[_asset] != address(0);
    }

    //////////////////////////
    // DERIVATIVES REGISTRY //
    //////////////////////////

    /// @notice Adds a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to add
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function addDerivatives(address[] calldata _derivatives, address[] calldata _priceFeeds)
        external
        onlyDispatcherOwner
    {
        require(_derivatives.length > 0, "addDerivatives: _derivatives cannot be empty");

        __addDerivatives(_derivatives, _priceFeeds);
    }

    /// @notice Removes a list of derivatives
    /// @param _derivatives The derivatives to remove
    function removeDerivatives(address[] calldata _derivatives) external onlyDispatcherOwner {
        require(_derivatives.length > 0, "removeDerivatives: _derivatives cannot be empty");

        for (uint256 i = 0; i < _derivatives.length; i++) {
            require(
                derivativeToPriceFeed[_derivatives[i]] != address(0),
                "removeDerivatives: Derivative not yet added"
            );

            delete derivativeToPriceFeed[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    /// @notice Updates a list of derivatives with the given price feed values
    /// @param _derivatives The derivatives to update
    /// @param _priceFeeds The ordered price feeds corresponding to the list of _derivatives
    function updateDerivatives(address[] calldata _derivatives, address[] calldata _priceFeeds)
        external
        onlyDispatcherOwner
    {
        require(_derivatives.length > 0, "updateDerivatives: _derivatives cannot be empty");
        require(
            _derivatives.length == _priceFeeds.length,
            "updateDerivatives: Unequal _derivatives and _priceFeeds array lengths"
        );

        for (uint256 i = 0; i < _derivatives.length; i++) {
            address prevPriceFeed = derivativeToPriceFeed[_derivatives[i]];

            require(prevPriceFeed != address(0), "updateDerivatives: Derivative not yet added");
            require(_priceFeeds[i] != prevPriceFeed, "updateDerivatives: Value already set");

            __validateDerivativePriceFeed(_derivatives[i], _priceFeeds[i]);

            derivativeToPriceFeed[_derivatives[i]] = _priceFeeds[i];

            emit DerivativeUpdated(_derivatives[i], prevPriceFeed, _priceFeeds[i]);
        }
    }

    /// @dev Helper to add derivative-feed pairs
    function __addDerivatives(address[] memory _derivatives, address[] memory _priceFeeds)
        private
    {
        require(
            _derivatives.length == _priceFeeds.length,
            "__addDerivatives: Unequal _derivatives and _priceFeeds array lengths"
        );

        for (uint256 i = 0; i < _derivatives.length; i++) {
            require(
                derivativeToPriceFeed[_derivatives[i]] == address(0),
                "__addDerivatives: Already added"
            );

            __validateDerivativePriceFeed(_derivatives[i], _priceFeeds[i]);

            derivativeToPriceFeed[_derivatives[i]] = _priceFeeds[i];

            emit DerivativeAdded(_derivatives[i], _priceFeeds[i]);
        }
    }

    /// @dev Helper to validate a derivative price feed
    function __validateDerivativePriceFeed(address _derivative, address _priceFeed) private view {
        require(_derivative != address(0), "__validateDerivativePriceFeed: Empty _derivative");
        require(_priceFeed != address(0), "__validateDerivativePriceFeed: Empty _priceFeed");
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
        external
        view
        override
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

import "../../../../interfaces/IAaveLendingPool.sol";
import "../../../../interfaces/IAaveLendingPoolAddressProvider.sol";
import "../utils/AdapterBase.sol";

/// @title AaveAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter for Aave Lending <https://aave.com/>
contract AaveAdapter is AdapterBase {
    address private immutable LENDING_POOL_ADDRESS_PROVIDER;
    uint16 private constant REFERRAL_CODE = 158;

    constructor(address _integrationManager, address _lendingPoolAddressProvider)
        public
        AdapterBase(_integrationManager)
    {
        LENDING_POOL_ADDRESS_PROVIDER = _lendingPoolAddressProvider;
    }

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "AAVE";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
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
            (address token, uint256 tokenAmount, address aToken) = __decodeCallArgs(
                _encodedCallArgs
            );
            spendAssets_ = new address[](1);
            spendAssets_[0] = token;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = tokenAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = aToken;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = tokenAmount;
        } else if (_selector == REDEEM_SELECTOR) {
            (address aToken, uint256 aTokenAmount, address token) = __decodeCallArgs(
                _encodedCallArgs
            );
            spendAssets_ = new address[](1);
            spendAssets_[0] = aToken;
            spendAssetAmounts_ = new uint256[](1);
            spendAssetAmounts_[0] = aTokenAmount;

            incomingAssets_ = new address[](1);
            incomingAssets_[0] = token;
            minIncomingAssetAmounts_ = new uint256[](1);
            minIncomingAssetAmounts_[0] = aTokenAmount;
        } else {
            revert("parseAssetsForMethod: _selector invalid");
        }

        return (
            IIntegrationManager.SpendAssetsHandleType.Transfer,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    /// @notice Lends an amount of a token to AAVE
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function lend(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (address token, uint256 amount, ) = __decodeCallArgs(_encodedCallArgs);

        __lend(_vaultProxy, token, amount);
    }

    /// @notice Redeems an amount of aTokens from AAVE
    /// @param _vaultProxy The VaultProxy of the calling fund
    /// @param _encodedAssetTransferArgs Encoded args for expected assets to spend and receive
    function redeem(
        address _vaultProxy,
        bytes calldata _encodedCallArgs,
        bytes calldata _encodedAssetTransferArgs
    )
        external
        onlyIntegrationManager
        fundAssetsTransferHandler(_vaultProxy, _encodedAssetTransferArgs)
    {
        (address aToken, uint256 amount, address token) = __decodeCallArgs(_encodedCallArgs);

        __redeem(_vaultProxy, token, aToken, amount);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode callArgs for lend and redeem
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address outgoingAsset_,
            uint256 outgoingAssetAmount_,
            address incomingAsset_
        )
    {
        return abi.decode(_encodedCallArgs, (address, uint256, address));
    }

    /// @dev Helper to execute lend. Avoids stack-too-deep error.
    function __lend(
        address _vaultProxy,
        address _token,
        uint256 _amount
    ) private {
        address lendingPoolAddress = IAaveLendingPoolAddressProvider(LENDING_POOL_ADDRESS_PROVIDER)
            .getLendingPool();

        __approveMaxAsNeeded(_token, lendingPoolAddress, _amount);

        IAaveLendingPool(lendingPoolAddress).deposit(_token, _amount, _vaultProxy, REFERRAL_CODE);
    }

    /// @dev Helper to execute redeem. Avoids stack-too-deep error.
    function __redeem(
        address _vaultProxy,
        address _token,
        address _aToken,
        uint256 _amount
    ) private {
        address lendingPoolAddress = IAaveLendingPoolAddressProvider(LENDING_POOL_ADDRESS_PROVIDER)
            .getLendingPool();

        __approveMaxAsNeeded(_aToken, lendingPoolAddress, _amount);

        IAaveLendingPool(lendingPoolAddress).withdraw(_token, _amount, _vaultProxy);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `LENDING_POOL_ADDRESS_PROVIDER` variable
    /// @return lendingPoolAddressProvider_ The `LENDING_POOL_ADDRESS_PROVIDER` variable value
    function getLendingPoolAddressProvider()
        external
        view
        returns (address lendingPoolAddressProvider_)
    {
        return LENDING_POOL_ADDRESS_PROVIDER;
    }

    /// @notice Gets the `REFERRAL_CODE` variable
    /// @return referralCode_ The `REFERRAL_CODE` variable value
    function getReferralCode() external pure returns (uint16 referralCode_) {
        return REFERRAL_CODE;
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