// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/DividendPayingTokenInterface.sol";
import "./interfaces/DividendPayingTokenOptionalInterface.sol";
import "./lib/SafeMath.sol";
import "./lib/SafeMathUint.sol";
import "./lib/SafeMathInt.sol";
import "./lib/ERC20.sol";

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 live
    // 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47 testnet
    address public BUSD;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol, address busdAddress) ERC20(_name, _symbol){BUSD = busdAddress;}

    /// @dev Distributes dividends whenever ether is paid to this contract.
    /// @dev removed distributeDividends since nothing should happen
    receive() external payable {}

    /// @notice Distributes tokens to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received BUSD is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends(uint256 amount) public virtual override {
        require(totalSupply() > 0, "DividendPayingToken: Supply must be greater than 0.");

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((amount).mul(magnitude) / totalSupply());
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal virtual returns (uint256){
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{value: _withdrawableDividend, gas: 3000}("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns (uint256){
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns (uint256){
        return withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns (uint256){
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe(); magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns(uint256);

    /// @notice Distributes ether to token holders as dividends.
    /// @dev SHOULD distribute the paid ether to token holders as dividends.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
    /// @dev this has been changed to take an amount for paying out in BUSD
    function distributeDividends(uint256 amount) external;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

// SPDX-License-Identifier: MIT

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) external view returns(uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) external view returns(uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

// SPDX-License-Identifier: MIT

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../lib/SafeMath.sol";
import "./Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
    constructor(string memory name_, string memory symbol_) public {
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
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
     * - `account` cannot be the zero address.
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
     * will be to transferred to `to`.
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
}

// SPDX-License-Identifier: MIT

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

import "../interfaces/IERC20.sol";

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './DividendPayingToken.sol';
import './lib/Ownable.sol';
import './lib/IterableMapping.sol';
import './interfaces/ISwapRouter.sol';
import './interfaces/IPazzive.sol';

contract PazDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    uint256 internal DECIMALS = 10 ** 18;

    uint256 public MIN_BALANCE_AUTO_DIVIDENDS = 10000000 * DECIMALS; // min balance for auto dividends
    uint256 public MIN_BALANCE_DIVIDENDS = 1000000 * DECIMALS; // min balance for dividends
    uint256 public MIN_DIVIDEND_DISTRIBUTION = 1 * DECIMALS; // 1 BUSD before auto send
    uint256 public MIN_CLAIM_INTERVAL = 1 hours; // min time before next auto claim

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;
    //    // todo think we can remove this
    //    mapping(address => bool) public excludedFromAutoClaim;
    mapping(address => bool) public autoReinvest;
    mapping(address => address) public userRewardToken;
    mapping(address => bool) public allowedTokens;
    mapping(address => bool) public allowedRouters;
    mapping(address => address) public tokenRouter;
    mapping(address => uint256) public tokenToUserCount; // Keep track of how many people have each reward token selected

    bool public allowCustomTokens;
    bool public allowAutoReinvest;
    bool public dividendsPaused = false;

    ISwapRouter public router;

    IPazzive public paz;

    mapping(address => uint256) public userLastClaimTime;
    mapping(address => uint256) public userSwappedBusd;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(address indexed account, uint256 busdAmount, address rewardTokenAddress, bool indexed automatic);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);
    event SetAllowAutoReinvest(bool allow);
    event TokenRouterSet(address token, address router);
    event AllowedRouterSet(address router, bool allow);
    event AllowedTokenSet(address router, bool allow);

    modifier onlyPaz() {
        require(msg.sender == address(paz), "PazDividendTracker: only paz");
        require(msg.sender == owner(), "PazDividendTracker: only owner");
        _;
    }

    constructor(address routerAddress, address busdAddress)DividendPayingToken("PazDividendTracker", "PazDividendTracker", busdAddress){
//        paz = IPazzive(pazziveAddress);
        router = ISwapRouter(routerAddress);
        allowCustomTokens = true;
        allowAutoReinvest = true;
    }

    function setMinBalanceAutoDividends(uint256 minBalanceAutoDividends) external onlyPaz {
        MIN_BALANCE_AUTO_DIVIDENDS = minBalanceAutoDividends;
    }

    function setMinBalanceDividends(uint256 minBalanceDividends) external onlyPaz {
        MIN_BALANCE_DIVIDENDS = minBalanceDividends;
    }

    function setMinDividendDistribution(uint256 minDividendDistribution) external onlyPaz {
        MIN_DIVIDEND_DISTRIBUTION = minDividendDistribution;
    }

    function setMinClaimInterval(uint256 minClaimInterval) external onlyPaz {
        MIN_CLAIM_INTERVAL = minClaimInterval;
    }

    // todo: prefer 18 decimals
    //    function decimals() public view virtual override returns (uint8) {
    //        return 9;
    //    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "PazDividendTracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "PazDividendTracker: withdrawDividend disabled. Use the 'claim' function on the main Pazzive contract.");
    }

    //    function isExcludedFromAutoClaim(address account) external view returns (bool){
    //        return excludedFromAutoClaim[account];
    //    }

    function isExcludedFromDividends(address account) external view returns (bool){
        return excludedFromDividends[account];
    }

    function isReinvest(address account) external view onlyPaz returns (bool){
        return autoReinvest[account];
    }

    function setAllowCustomTokens(bool allow) external onlyPaz {
        require(allowCustomTokens != allow, "PazDividendTracker: already set");
        allowCustomTokens = allow;
        emit SetAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) external onlyPaz {
        require(allowAutoReinvest != allow, "PazDividendTracker: already set");
        allowAutoReinvest = allow;
        emit SetAllowAutoReinvest(allow);
    }

    //    function excludeFromDividends(address account) external onlyPaz {
    //        require(!excludedFromDividends[account]);
    //        excludedFromDividends[account] = true;
    //
    //        _setBalance(account, 0);
    //        tokenHoldersMap.remove(account);
    //
    //        emit ExcludeFromDividends(account);
    //    }

    // @dev should check that account != address(this) &&  !swapPairs[account]
    function setExcludedFromDividends(address account, bool excluded) external onlyPaz {
        require(excludedFromDividends[account] != excluded, "PazDividendTracker: already set");
        excludedFromDividends[account] = excluded;
        if(excluded){
            _setBalance(account, 0);
            emit ExcludeFromDividends(account);
        }else{
            _setBalance(account, paz.getBalance(account));
        }
    }

    //    function setExcludedFromAutoClaim(address account, bool excluded) external onlyPaz {
    //        require(excludedFromAutoClaim[account] != excluded, "PazDividendTracker: already set");
    //        excludedFromAutoClaim[account] = excluded;
    //    }

    function setAutoReinvest(address account, bool shouldAutoReinvest) external onlyPaz {
        autoReinvest[account] = shouldAutoReinvest;
    }

    function setDividendsPaused(bool isPaused) external onlyPaz {
        require(dividendsPaused != isPaused, "PazDividendTracker: already set");
        dividendsPaused = isPaused;
        emit DividendsPaused(isPaused);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account) public view returns (address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable){
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
                ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = userLastClaimTime[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(MIN_CLAIM_INTERVAL) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256){
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function _canAutoClaim(address account) private view returns (bool canAutoClaim) {
        if(MIN_CLAIM_INTERVAL == 0 && MIN_DIVIDEND_DISTRIBUTION == 0) { canAutoClaim = true; }
        else if (userLastClaimTime[account] > block.timestamp) {canAutoClaim = false;}
        else{
            canAutoClaim = block.timestamp.sub(userLastClaimTime[account]) >= MIN_CLAIM_INTERVAL && withdrawableDividendOf(account) >= MIN_DIVIDEND_DISTRIBUTION;
        }
    }

    function setBalance(address account, uint256 newBalance) external onlyPaz {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance < MIN_BALANCE_DIVIDENDS) {
            tokenHoldersMap.remove(account);
            _setBalance(account, 0);
            return;
        }

        _setBalance(account, newBalance);

        if (newBalance >= MIN_BALANCE_AUTO_DIVIDENDS) {
            tokenHoldersMap.set(account, newBalance);
        } else {
            tokenHoldersMap.remove(account);
        }
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256){
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0 || dividendsPaused) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= numberOfTokenHolders) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (_canAutoClaim(account)) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyPaz returns (bool){
        if (dividendsPaused) {
            return false;
        }

        uint256 amount = _withdrawDividendOfUser(account);

        // todo: might get rid of autoreinvest and the next 3 lines
        bool reinvest = autoReinvest[account];
        if (automatic && reinvest && !allowAutoReinvest) {
            return false;
        }

        if (amount > 0) {
            userLastClaimTime[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function updateRouter(address newAddress) public onlyPaz {
        router = ISwapRouter(newAddress);
    }

    function setUserRewardToken(address account, address token) public onlyPaz {
        require(allowedTokens[token] || token == address(0), "PazDividendTracker: Token is not allowed");
        userRewardToken[account] = token;
    }

    function getUserRewardToken(address account) public view returns (address) {
        return userRewardToken[account];
    }

    function setAllowedTokens(address token, bool allow) public onlyPaz {
        allowedTokens[token] = allow;
        emit AllowedTokenSet(token, allow);
    }

    function setAllowedRouter(address routerAddress, bool allow) public onlyPaz {
        allowedRouters[routerAddress] = allow;
        emit AllowedRouterSet(routerAddress, allow);
    }

    function setTokenRouter(address token, address routerAddress) public onlyPaz {
        require(allowedRouters[routerAddress], "Pazzive: router is not allowed");
        tokenRouter[token] = routerAddress;
        emit TokenRouterSet(token, routerAddress);
    }

    function getAllowedTokens(address token) external view returns (bool) {
        return allowedTokens[token];
    }

    function isCustomRouter(address user) internal view returns (bool) {
        return tokenRouter[userRewardToken[user]] != address(router);
    }

    function swapBusdForTokens(address user, uint256 amount) private returns (uint256) {
        bool swapSuccess;
        IERC20 RewardToken = IERC20(userRewardToken[user]);
        ISwapRouter rewardRouter = getRouter(user);
        address[] memory path = new address[](3);
        path[0] = BUSD;
        path[1] = router.WETH();
        path[2] = address(RewardToken);

        IERC20(BUSD).approve(address(rewardRouter), amount);

        // no slippage needed as there is high liquidity for BUSD/BNB liquidity and all our tokens have tax
        try rewardRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(user), block.timestamp){
            userSwappedBusd[user]+=amount;
            swapSuccess = true;
            emit DividendReinvested(user, amount, address(RewardToken), true);
        }catch{swapSuccess = false;}

        // send busd
        if(!swapSuccess){
            amount = withdrawBusd(user, amount);
        }

        return amount;
    }

    // todo: external method for allowing people to reinvest later
    function taxFreeReinvest(uint256 amount, uint256 token) external {

    }

    function getRouter(address user) internal view returns (ISwapRouter) {
        address rewardToken = userRewardToken[user];
        address rewardTokenRouter = tokenRouter[rewardToken];
        bool isDefaultRouter = rewardTokenRouter == address(router);
        return isDefaultRouter ? router : ISwapRouter(rewardTokenRouter);
    }

    /// @dev will either withdraw BUSD or swap for user's reward token
    function _withdrawDividendOfUser(address payable user) internal override returns (uint256) {
        uint256 amount = withdrawableDividendOf(user);

        if(amount == 0){
            return 0;
        }

        address rewardToken = getUserActualRewardToken(user);
        amount = rewardToken == BUSD ? withdrawBusd(user, amount) : swapBusdForTokens(user, amount);

        if(amount > 0){
            withdrawnDividends[user] = withdrawnDividends[user].add(amount);
            emit DividendWithdrawn(user, amount);
        }

        return amount;
    }

    /// @dev this gets the actual reward token that the user will be paid out
    /// @dev versus getUserRewardToken which is a public getter for the variable
    function getUserActualRewardToken(address user) public view returns (address) {
        address tokenAddress = userRewardToken[user];
        if(!allowCustomTokens || tokenAddress == address(0) || !allowedTokens[tokenAddress]){
            tokenAddress = BUSD;
        }
        return tokenAddress;
    }

    function withdrawBusd(address user, uint256 amount) internal onlyPaz returns (uint256) {
        try IERC20(BUSD).transfer(user, amount) returns (bool) {} catch{
            amount = 0;
        }
        return amount;
    }

    function sweep() external onlyPaz {
        uint256 balance = address(this).balance;
        if(balance > 0){
            payable(paz.owner()).transfer(balance);
        }
    }

    function setPazAddress(address pazAddress) external onlyPaz {
        paz = IPazzive(pazAddress);
    }

    function recoverTokens(address _token, address _to) external onlyPaz returns(bool _sent){
        require(_token != address(this), "PazDividendTracker: Can not be PazDividendTracker");
        require(_token != BUSD, "PazDividendTracker: Can not be BUSD");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}

// SPDX-License-Identifier: MIT

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
    internal
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
    internal
    view
    returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface ISwapRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

interface IPazzive {
  function BUSD (  ) external view returns ( address );
  function DEAD (  ) external view returns ( address );
  function MAX_BUY_FEE (  ) external view returns ( uint256 );
  function MAX_SELL_AMOUNT (  ) external view returns ( uint256 );
  function MAX_SELL_FEE (  ) external view returns ( uint256 );
  function MAX_TEAM_FEE (  ) external view returns ( uint256 );
  function MAX_TOKENS_TO_SWAP (  ) external view returns ( uint256 );
  function MIN_BALANCE_AUTO_DIVIDENDS (  ) external view returns ( uint256 );
  function MIN_BALANCE_DIVIDENDS (  ) external view returns ( uint256 );
  function MIN_CLAIM_INTERVAL (  ) external view returns ( uint256 );
  function MIN_DIVIDEND_DISTRIBUTION (  ) external view returns ( uint256 );
  function MIN_MAX_SELL_AMOUNT (  ) external view returns ( uint256 );
  function MIN_TOKENS_TO_SWAP (  ) external view returns ( uint256 );
  function PROCESS_DIVIDEND_GAS_AMOUNT (  ) external view returns ( uint256 );
  function ZERO (  ) external view returns ( address );
  function afterIfo (  ) external;
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function autoLiquidityReceiver (  ) external view returns ( address );
  function balanceOf ( address account ) external view returns ( uint256 );
  function claim (  ) external;
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function devAddress (  ) external view returns ( address );
  function dividendTokenBalanceOf ( address account ) external view returns ( uint256 );
  function dividendTracker (  ) external view returns ( address );
  function enableTokenLocking ( bool enable ) external;
  function enableTrading (  ) external;
  function feeDenominator (  ) external view returns ( uint256 );
  function feesOnNormalTransfers (  ) external view returns ( bool );
  function getAccount ( address account ) external view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256 );
  function getAccountAtIndex ( uint256 index ) external view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256 );
  function getAllowedTokens ( address token ) external view returns ( bool );
  function getBalance ( address account ) external view returns ( uint256 );
  function getLastProcessedIndex (  ) external view returns ( uint256 );
  function getMultipliedFee (  ) external view returns ( uint256 );
  function getNumberOfDividendTokenHolders (  ) external view returns ( uint256 );
  function getStakingInfo ( address account ) external view returns ( uint256, uint256 );
  function getTotalDividendsDistributed (  ) external view returns ( uint256 );
  function getUserRewardToken ( address account ) external view returns ( address );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function isBlacklisted ( address account ) external view returns ( bool );
  function isExcludedFromAntiWhale ( address account ) external view returns ( bool );
  function isExcludedFromDividends ( address account ) external view returns ( bool );
  function isExcludedFromFees ( address account ) external view returns ( bool );
  function isReinvest ( address account ) external view returns ( bool );
  function isSwapPair ( address pair ) external view returns ( bool );
  function lastSale ( address ) external view returns ( uint256 );
  function launchedAt (  ) external view returns ( uint256 );
  function liquidityFee (  ) external view returns ( uint256 );
  function lockDurationToBonus ( uint256 ) external view returns ( uint256 );
  function lockTokens ( uint256 duration ) external;
  function marketingAddress (  ) external view returns ( address );
//  function name (  ) external view returns ( string );
  function owner (  ) external view returns ( address );
  function prepareForIfo ( address ifoContract ) external;
  function process ( uint256 gasAmount ) external;
  function processDividendTracker ( uint256 gas ) external;
  function recoverTokens ( address _token, address _to ) external returns ( bool _sent );
  function recoverTrackerTokens ( address _token, address _to ) external;
  function renounceOwnership (  ) external;
  function rewardFee (  ) external view returns ( uint256 );
  function router (  ) external view returns ( address );
  function routers ( address ) external view returns ( bool );
  function sellFeeMultiplier (  ) external view returns ( uint256 );
  function sellFeeMultiplierDenominator (  ) external view returns ( uint256 );
  function sendDividends ( uint256 tokens ) external;
  function setAllowAutoReinvest ( bool allow ) external;
  function setAllowCustomTokens ( bool allow ) external;
  function setAllowedTokens ( address token, bool allow ) external;
  function setDevAddress ( address _devAddress ) external;
  function setDividendsPaused ( bool value ) external;
  function setExcludedFromAntiWhale ( address _account, bool excluded ) external;
  function setExcludedFromDividends ( address account, bool excluded ) external;
  function setExcludedFromFees ( address account, bool isExcluded ) external;
  function setFees ( uint256 _liquidityFee, uint256 _rewardFee, uint256 _teamFee, uint256 _sellFeeMultiplier, uint256 _sellFeeMultiplierDenominator ) external;
  function setIsBlacklisted ( address adr, bool blacklisted ) external;
  function setMarketingAddress ( address _marketingAddress ) external;
  function setMaxSellAmount ( uint256 _maxSellAmount ) external;
  function setMinBalanceAutoDividends ( uint256 minBalanceAutoDividends ) external;
  function setMinBalanceDividends ( uint256 minBalanceDividends ) external;
  function setMinClaimInterval ( uint256 minClaimInterval ) external;
  function setMinDividendDistribution ( uint256 minDividendDistribution ) external;
  function setProcessDividendGasAmount ( uint256 dividendGasAmount ) external;
  function setReinvest ( bool value ) external;
  function setRouter ( address routerAddress ) external;
  function setRouters ( address routerAddress, bool allow ) external;
  function setStakingDurationToBonus ( uint256 duration, uint256 bonus ) external;
  function setSwapAndLiquify ( bool enabled ) external;
  function setSwapPair ( address pair, bool isPair ) external;
  function setUserRewardToken ( address token ) external;
  function swapAndLiquifyEnabled (  ) external view returns ( bool );
  function swapPair (  ) external view returns ( address );
  function swapPairs ( address ) external view returns ( bool );
  function sweep (  ) external;
  function sweepTracker (  ) external;
//  function symbol (  ) external view returns ( string );
  function teamFee (  ) external view returns ( uint256 );
  function totalBuyFee (  ) external view returns ( uint256 );
  function totalSellFee (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function tradingEnabled (  ) external view returns ( bool );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function updateDividendTracker ( address trackerAddress ) external;
  function updateLiquidityWallet ( address lpWallet ) external;
  function userLockBonus ( address ) external view returns ( uint256 );
  function userLockEndTime ( address ) external view returns ( uint256 );
  function withdrawableDividendOf ( address account ) external view returns ( uint256 );
}

