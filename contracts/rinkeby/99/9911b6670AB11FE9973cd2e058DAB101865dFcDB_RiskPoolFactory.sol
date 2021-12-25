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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RiskPoolERC20.sol";
import "./interfaces/ISingleSidedReinsurancePool.sol";
import "./interfaces/IRiskPool.sol";
import "./libraries/TransferHelper.sol";

contract RiskPool is IRiskPool, RiskPoolERC20 {
    // ERC20 attributes
    string public name;
    string public symbol;

    address public SSRP;
    address public override currency; // for now we should accept only UNO
    uint256 public override lpPriceUno;
    uint256 public MIN_LP_CAPITAL = 1e20;

    event LogCancelWithdrawRequest(address indexed _user, uint256 _amount, uint256 _amountInUno);
    event LogPolicyClaim(address indexed _user, uint256 _amount);
    event LogMigrateLP(address indexed _user, address indexed _migrateTo, uint256 _unoAmount);
    event LogLeaveFromPending(address indexed _user, uint256 _withdrawLpAmount, uint256 _withdrawUnoAmount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _SSRP,
        address _currency
    ) {
        name = _name;
        symbol = _symbol;
        SSRP = _SSRP;
        currency = _currency;
        lpPriceUno = 1e18;
    }

    modifier onlySSRP() {
        require(msg.sender == SSRP, "UnoRe: RiskPool Forbidden");
        _;
    }

    /**
     * @dev Users can stake only through Cohort
     */
    function enter(address _from, uint256 _amount) external override onlySSRP {
        _mint(_from, (_amount * 1e18) / lpPriceUno);
    }

    /**
     * @param _amount UNO amount to withdraw
     */
    function leaveFromPoolInPending(address _to, uint256 _amount) external override onlySSRP {
        require(totalSupply() > 0, "UnoRe: There's no remaining in the pool");
        uint256 requestAmountInLP = (_amount * 1e18) / lpPriceUno;
        require(
            (requestAmountInLP + uint256(withdrawRequestPerUser[_to].pendingAmount)) <= balanceOf(_to),
            "UnoRe: lp balance overflow"
        );
        _withdrawRequest(_to, requestAmountInLP, _amount);
    }

    function leaveFromPending(address _to) external override onlySSRP returns (uint256, uint256) {
        uint256 cryptoBalance = IERC20(currency).balanceOf(address(this));
        uint256 pendingAmount = uint256(withdrawRequestPerUser[_to].pendingAmount);
        require(cryptoBalance > 0, "UnoRe: zero uno balance");
        require(balanceOf(_to) >= pendingAmount, "UnoRe: lp balance overflow");
        _withdrawImplement(_to);
        uint256 pendingAmountInUno = (pendingAmount * lpPriceUno) / 1e18;
        if (cryptoBalance - MIN_LP_CAPITAL > pendingAmountInUno) {
            TransferHelper.safeTransfer(currency, _to, pendingAmountInUno);
            emit LogLeaveFromPending(_to, pendingAmount, pendingAmountInUno);
            return (pendingAmount, pendingAmountInUno);
        } else {
            TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            emit LogLeaveFromPending(_to, pendingAmount, cryptoBalance - MIN_LP_CAPITAL);
            return (pendingAmount, cryptoBalance - MIN_LP_CAPITAL);
        }
    }

    function cancelWithrawRequest(address _to) external override onlySSRP returns (uint256, uint256) {
        uint256 _pendingAmount = uint256(withdrawRequestPerUser[_to].pendingAmount);
        require(_pendingAmount > 0, "UnoRe: zero amount");
        _cancelWithdrawRequest(_to);
        emit LogCancelWithdrawRequest(_to, _pendingAmount, (_pendingAmount * lpPriceUno) / 1e18);
        return (_pendingAmount, (_pendingAmount * lpPriceUno) / 1e18);
    }

    function policyClaim(address _to, uint256 _amount) external override onlySSRP returns (uint256 realClaimAmount) {
        uint256 cryptoBalance = IERC20(currency).balanceOf(address(this));
        require(totalSupply() > 0, "UnoRe: zero lp balance");
        require(cryptoBalance > MIN_LP_CAPITAL, "UnoRe: minimum UNO capital underflow");
        if (cryptoBalance - MIN_LP_CAPITAL > _amount) {
            TransferHelper.safeTransfer(currency, _to, _amount);
            realClaimAmount = _amount;
            emit LogPolicyClaim(_to, _amount);
        } else {
            TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            realClaimAmount = cryptoBalance - MIN_LP_CAPITAL;
            emit LogPolicyClaim(_to, cryptoBalance - MIN_LP_CAPITAL);
        }
        cryptoBalance = IERC20(currency).balanceOf(address(this));
        lpPriceUno = (cryptoBalance * 1e18) / totalSupply(); // UNO value per lp
    }

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isUnLocked
    ) external override onlySSRP {
        require(_migrateTo != address(0), "UnoRe: zero address");
        if (_isUnLocked && withdrawRequestPerUser[_to].pendingAmount > 0) {
            uint256 pendingAmountInUno = (uint256(withdrawRequestPerUser[_to].pendingAmount) * lpPriceUno) / 1e18;
            uint256 cryptoBalance = IERC20(currency).balanceOf(address(this));
            if (pendingAmountInUno < cryptoBalance - MIN_LP_CAPITAL) {
                TransferHelper.safeTransfer(currency, _to, pendingAmountInUno);
            } else {
                TransferHelper.safeTransfer(currency, _to, cryptoBalance - MIN_LP_CAPITAL);
            }
            _withdrawImplement(_to);
        } else {
            if (withdrawRequestPerUser[_to].pendingAmount > 0) {
                _cancelWithdrawRequest(_to);
            }
        }
        uint256 unoBalance = (balanceOf(_to) * lpPriceUno) / 1e18;
        TransferHelper.safeTransfer(currency, _migrateTo, unoBalance);
        _burn(_to, balanceOf(_to));
        emit LogMigrateLP(_to, _migrateTo, unoBalance);
    }

    function setMinLPCapital(uint256 _minLPCapital) external override onlySSRP {
        require(_minLPCapital > 0, "UnoRe: not allow zero value");
        MIN_LP_CAPITAL = _minLPCapital;
    }

    function getWithdrawRequest(address _to)
        external
        view
        override
        onlySSRP
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            uint256(withdrawRequestPerUser[_to].pendingAmount),
            uint256(withdrawRequestPerUser[_to].requestTime),
            withdrawRequestPerUser[_to].pendingUno
        );
    }

    function getTotalWithdrawRequestAmount() external view override onlySSRP returns (uint256) {
        return totalWithdrawPending;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(
            balanceOf(msg.sender) - uint256(withdrawRequestPerUser[msg.sender].pendingAmount) >= amount,
            "ERC20: transfer amount exceeds balance or pending WR"
        );
        _transfer(msg.sender, recipient, amount);

        ISingleSidedReinsurancePool(SSRP).lpTransfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            balanceOf(sender) - uint256(withdrawRequestPerUser[sender].pendingAmount) >= amount,
            "ERC20: transfer amount exceeds balance or pending WR"
        );
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        ISingleSidedReinsurancePool(SSRP).lpTransfer(sender, recipient, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./interfaces/IRiskPoolERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
contract RiskPoolERC20 is Context, IRiskPoolERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    struct UserWithdrawRequestInfo {
        uint128 pendingAmount;
        uint128 requestTime;
        uint256 pendingUno;
    }
    mapping(address => UserWithdrawRequestInfo) internal withdrawRequestPerUser;
    uint256 internal totalWithdrawPending;

    uint256 private _totalSupply;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {}

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
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
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
        _balances[sender] = senderBalance - amount;
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
        _balances[account] = accountBalance - amount;
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

    function _withdrawRequest(
        address _user,
        uint256 _amount,
        uint256 _amountInUno
    ) internal {
        require(balanceOf(_user) >= _amount, "UnoRe: balance overflow");
        if (withdrawRequestPerUser[_user].pendingAmount == 0 && withdrawRequestPerUser[_user].requestTime == 0) {
            withdrawRequestPerUser[_user] = UserWithdrawRequestInfo({
                pendingAmount: uint128(_amount),
                requestTime: uint128(block.timestamp),
                pendingUno: _amountInUno
            });
        } else {
            withdrawRequestPerUser[_user].pendingAmount += uint128(_amount);
            withdrawRequestPerUser[_user].pendingUno += _amountInUno;
            withdrawRequestPerUser[_user].requestTime = uint128(block.timestamp);
        }
        totalWithdrawPending += _amount;
    }

    function _withdrawImplement(address _user) internal {
        require(uint256(withdrawRequestPerUser[_user].pendingAmount) > 0, "UnoRe: zero claim amount");
        uint256 _pendingAmount = withdrawRequestPerUser[_user].pendingAmount;
        totalWithdrawPending -= _pendingAmount;
        _burn(_user, _pendingAmount);
        delete withdrawRequestPerUser[_user];
    }

    function _cancelWithdrawRequest(address _user) internal {
        uint256 _pendingAmount = withdrawRequestPerUser[_user].pendingAmount;
        totalWithdrawPending -= _pendingAmount;
        delete withdrawRequestPerUser[_user];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../RiskPool.sol";
import "../interfaces/IRiskPoolFactory.sol";

contract RiskPoolFactory is IRiskPoolFactory {
    constructor() {}

    function newRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _cohort,
        address _currency
    ) external override returns (address) {
        RiskPool _riskPool = new RiskPool(_name, _symbol, _cohort, _currency);
        address _riskPoolAddr = address(_riskPool);

        return _riskPoolAddr;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPool {
    function enter(address _from, uint256 _amount) external;

    function leaveFromPoolInPending(address _to, uint256 _amount) external;

    function leaveFromPending(address _to) external returns (uint256, uint256);

    function cancelWithrawRequest(address _to) external returns (uint256, uint256);

    function policyClaim(address _to, uint256 _amount) external returns (uint256 realClaimAmount);

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isUnLocked
    ) external;

    function setMinLPCapital(uint256 _minLPCapital) external;

    function currency() external view returns (address);

    function getTotalWithdrawRequestAmount() external view returns (uint256);

    function getWithdrawRequest(address _to)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function lpPriceUno() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IRiskPoolERC20 {
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPoolFactory {
    function newRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _pool,
        address _currency
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISingleSidedReinsurancePool {
    function updatePool() external;

    function enterInPool(uint256 _amount) external;

    function leaveFromPoolInPending(uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function riskPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}