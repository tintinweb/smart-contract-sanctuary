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
    mapping(address => address) public userRewardToken;
    mapping(address => bool) public allowedTokens;
    mapping(address => bool) public allowedRouters;
    mapping(address => address) public tokenRouter;
    mapping(address => uint256) public tokenToUserCount; // Keep track of how many people have each reward token selected

    bool public allowCustomTokens;
    bool public dividendsPaused = false;

    ISwapRouter public router;

    IPazzive public paz;

    mapping(address => uint256) public userLastClaimTime;
    mapping(address => uint256) public userSwappedBusd;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(address indexed account, uint256 busdAmount, address rewardTokenAddress, uint256 tokenAmount);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);
    event TokenRouterSet(address token, address router);
    event AllowedRouterSet(address router, bool allow);
    event AllowedTokenSet(address router, bool allow);
    event BusdDeposited(address from, uint256 amount);
    event UserRewardTokenUpdated(address user, address token);

    modifier onlyPaz() {
        require(msg.sender == address(paz) || msg.sender == owner(), "PazDividendTracker: only paz or owner"); _;
    }

    constructor(address pazAddress, address routerAddress, address busdAddress)DividendPayingToken("PazDividendTracker", "PazDividendTracker", busdAddress){
        paz = IPazzive(pazAddress);
        router = ISwapRouter(routerAddress);
        allowCustomTokens = true;

        // add ts, rice, paz, bnb, busd
        setAllowedTokens(pazAddress, true);
        setAllowedTokens(BUSD, true);
//        setAllowedTokens(0x3504de9e61FDFf2Fc70f5cC8a6D1Ee493434C1Aa, true);
//        setAllowedTokens(0xC4eEFF5aab678C3FF32362D80946A3f5De4a1861, true);

        // add v1 router for ts
//        setAllowedRouter(0x05ff2b0db69458a0750badebc4f9e13add608c7f, true);
//        setTokenRouter(0x3504de9e61FDFf2Fc70f5cC8a6D1Ee493434C1Aa, 0x05ff2b0db69458a0750badebc4f9e13add608c7f);

        // v1 testnet
        setAllowedRouter(0x9aa68E4818A79E024d5a3bFd32Bca116EcB240ED, true); // rice router
        setAllowedTokens(0x4bCdd13aa5911b82dFDd873be81015a887754913, true); // teslasafe
        setTokenRouter(0x4bCdd13aa5911b82dFDd873be81015a887754913, 0x9aa68E4818A79E024d5a3bFd32Bca116EcB240ED);
    }

    /// @notice deposit BUSD to contract and share with everyone
    function depositBusd(uint256 amount) external {
        bool success = IERC20(BUSD).transferFrom(msg.sender, address(this), amount);
        if(success){
            distributeDividends(amount);
            emit BusdDeposited(msg.sender, amount);
        }
    }

    function getUserSwappedBusd(address user) external view returns (uint256){
        return userSwappedBusd[user];
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

    function setAllowCustomTokens(bool allow) external onlyPaz {
        require(allowCustomTokens != allow, "PazDividendTracker: already set");
        allowCustomTokens = allow;
        emit SetAllowCustomTokens(allow);
    }

    // @dev should check that account != address(this) &&  !swapPairs[account]
    function setExcludedFromDividends(address account, bool excluded) external onlyPaz {
//        require(excludedFromDividends[account] != excluded, "PazDividendTracker: already set");
        excludedFromDividends[account] = excluded;
        if(excluded){
            _setBalance(account, 0);
            emit ExcludeFromDividends(account);
        }else{
            _setBalance(account, paz.getBalance(account));
        }
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

        if (amount > 0) {
            userLastClaimTime[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function updateRouter(address newAddress) public onlyPaz {
        router = ISwapRouter(newAddress);
        // need to update all the previous tokenRouters to point to the new router
    }

    function setUserRewardToken(address account, address token) public onlyPaz {
        require(allowedTokens[token] || token == address(0), "PazDividendTracker: Token is not allowed");
        address oldToken = userRewardToken[account];
        // lower count if it isn't default
        if(oldToken != address(0) && oldToken != BUSD){
            tokenToUserCount[oldToken]-=1;
        }
        // increase count if it isn't default
        if(token != BUSD){
            userRewardToken[account] = token;
            tokenToUserCount[token]+=1;
        }

        userRewardToken[account] = token;
        emit UserRewardTokenUpdated(account, token);
    }

    function getUserRewardToken(address account) public view returns (address) {
        return userRewardToken[account];
    }

    function setAllowedTokens(address token, bool allow) public onlyPaz {
        require(token != address(this), "PazDividendTracker: do not set tracker");
        allowedTokens[token] = allow;
        emit AllowedTokenSet(token, allow);
    }

    function setAllowedRouter(address routerAddress, bool allow) public onlyPaz {
        allowedRouters[routerAddress] = allow;
        emit AllowedRouterSet(routerAddress, allow);
    }

    /// @dev if you want default router then better to set the router as address(0)
    function setTokenRouter(address token, address routerAddress) public onlyPaz {
        require(allowedRouters[routerAddress] || routerAddress == address(0), "PazDividendTracker: router is not allowed");
        tokenRouter[token] = routerAddress;
        emit TokenRouterSet(token, routerAddress);
    }

    function getAllowedTokens(address token) external view returns (bool) {
        return allowedTokens[token];
    }

    function isCustomRouter(address user) internal view returns (bool) {
        return tokenRouter[userRewardToken[user]] != address(router);
    }

    /// @dev returns the correct router for a token
    function getRouter(address token) public view returns (ISwapRouter _router){

        address routerAddress = tokenRouter[token];
        _router = routerAddress == address(0) || routerAddress == address(router) ? router : ISwapRouter(routerAddress);

        return _router;
    }


    /// @dev will either withdraw BUSD or swap for user's reward token
    function _withdrawDividendOfUser(address payable user) internal override returns (uint256) {
        uint256 amount = withdrawableDividendOf(user);

        if(amount == 0){
            return 0;
        }

        address rewardToken = getUserActualRewardToken(user);
        amount = rewardToken == BUSD ? withdrawBusd(user, amount) : swapBusdForTokens(user, rewardToken, amount);

        if(amount > 0){
            withdrawnDividends[user] = withdrawnDividends[user].add(amount);
            emit DividendWithdrawn(user, amount);
        }

        return amount;
    }

    /// @dev tax free swap for fuzion tokens
    function swapBusdForTokens(address user, address token, uint256 amount) internal returns (uint256) {
        require(allowedTokens[token], "PazDividendTracker: token selected is not allowed");
        bool swapSuccess;

        address[] memory path = new address[](3);
        path[0] = BUSD;
        path[1] = router.WETH();
        path[2] = token;

        ISwapRouter _router = getRouter(token);

        IERC20(BUSD).approve(address(_router), amount);

        // no slippage needed as there is high liquidity for BUSD/BNB liquidity and all our tokens have tax
        try _router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp) returns (uint[] memory amounts){
            IERC20(token).transfer(user, amounts[2]);
            userSwappedBusd[user]+=amount;
            swapSuccess = true;
            emit DividendReinvested(user, amount, token, amounts[2]);
        }catch{swapSuccess = false;}

        // send busd
        if(!swapSuccess){
            amount = withdrawBusd(user, amount);
        }

        return amount;
    }

    function setUserSwappedBusd(address user, uint256 amount) external onlyPaz {
        userSwappedBusd[user] = amount;
    }

//    // todo: external method for allowing people to reinvest later
//    function taxFreeReinvest(address token, uint256 amount) external {
//        // todo: check that they are eligible for tax free
//        require(amount < getUserTaxFreeReinvestAmount(msg.sender), "PazDividendTracker: Can only reinvest up to your total rewards");
//        swapBusdForTokens(msg.sender, token, amount);
//    }

    function getUserTaxFreeReinvestAmount(address user) public view returns (uint256){
        return withdrawnDividends[user] <= userSwappedBusd[user] ? 0 : withdrawnDividends[user].sub(userSwappedBusd[user]);
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
  function setDividendTracker ( address trackerAddress ) external;
  function setDividendsPaused ( bool value ) external;
  function setExcludedFromAntiWhale ( address _account, bool excluded ) external;
  function setExcludedFromDividends ( address account, bool excluded ) external;
  function setExcludedFromFees ( address account, bool isExcluded ) external;
  function setFees ( uint256 _liquidityFee, uint256 _rewardFee, uint256 _teamFee, uint256 _sellFeeMultiplier, uint256 _sellFeeMultiplierDenominator ) external;
  function setIsBlacklisted ( address adr, bool blacklisted ) external;
  function setLockDurationToBonus ( uint256 duration, uint256 bonus ) external;
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
  function updateLiquidityWallet ( address lpWallet ) external;
  function userLockBonus ( address ) external view returns ( uint256 );
  function userLockEndTime ( address ) external view returns ( uint256 );
  function userSwappedBusd ( address user ) external view returns ( uint256 );
  function withdrawableDividendOf ( address account ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISwapRouter.sol";
import "./interfaces/ISwapFactory.sol";
import "./interfaces/ISwapPair.sol";
import "./interfaces/IERC20.sol";
import "./lib/Ownable.sol";

contract RiceBusdToRiceBnb is Ownable {

    ISwapRouter public router;
    ISwapFactory public factory;

    address public BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
    address public RICE = 0xAb14aE27665F077AC2f8c08dFdCf011D80a3640C;

//    address RICE_BNB = '0xf2F10a571F47fadaD256de41C8ED6AC150606a19';
//    address RICE_BUSD = '0x089ea34C9b239F1c012f3a96C2B8987367B78dC4';
//    address BNB_BUSD = '0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16';

    address public RICE_BNB = 0x0cd6c8B18afd5586e54aE2CFF0F6da1391185e25;
    address public RICE_BUSD = 0x7bfdBDe6a7065BAF1Eb45CE15D546C15FeB4aDd0;
    address public BNB_BUSD = 0x23Ec7009caBA76d3a0756c98dF6a650a3B0eAC8E;

    address feeReceiver;

    uint256 slippage = 0;
    uint256 slippageDenominator = 1000;

    uint256 public fee = 50;
    uint256 public feeDenominator = 1000;

    constructor(address routerAddress, address busdAddress) {
        router = ISwapRouter(routerAddress);
        BUSD = busdAddress;
        feeReceiver = msg.sender;

        factory = ISwapFactory(router.factory());
        RICE_BNB = factory.getPair(router.WETH(), RICE);
        RICE_BUSD = factory.getPair(BUSD, RICE);
        BNB_BUSD = factory.getPair(BUSD, router.WETH());
    }

    receive() external payable {}

    function removeLiquidityTokens(address lpAddress, uint256 lpAmount) public {
        ISwapPair lp = ISwapPair(lpAddress);
        require(lp.transferFrom(msg.sender, address(this), lpAmount), "FuzionLiquidity: LP transfer failed.");
        lp.approve(address(router), lpAmount);

        address token1 = lp.token0();
        address token2 = lp.token1();

        uint256 token1Amount;
        uint256 token2Amount;

        try router.removeLiquidity(token1, token2, lpAmount, 0, 0, address(this), block.timestamp) returns (uint256 amountA, uint256 amountB) {
            token1Amount = amountA;
            token2Amount = amountB;
        } catch { revert("remove liquidity failed"); }

        uint256 token1Fee = token1Amount * fee / feeDenominator;
        uint256 token2Fee = token2Amount * fee / feeDenominator;

        IERC20(token1).transfer(msg.sender, token1Amount - token1Fee);
        IERC20(token2).transfer(msg.sender, token2Amount - token2Fee);

        IERC20(token1).transfer(feeReceiver, token1Fee);
        IERC20(token2).transfer(feeReceiver, token2Fee);
    }

    function swapRiceBusdForRiceBnb(uint256 amount) external {
        ISwapPair lp = ISwapPair(RICE_BUSD);
//        IERC20 rice = IERC20(RICE);
//        IERC20 busd = IERC20(BUSD);
        require(lp.balanceOf(msg.sender) >= amount, "FuzionLiquidity: Not enough lp.");
        lp.transferFrom(msg.sender, address(this), amount);
//        require(, "FuzionLiquidity: LP transfer failed.");
        lp.approve(address(router), amount);

        uint256 riceAmount;
        uint256 busdAmount;

        try router.removeLiquidity(RICE, BUSD, amount, 0, 0, address(this), block.timestamp) returns (uint256 amountA, uint256 amountB) {
            riceAmount = amountA;
            busdAmount = amountB;
        }catch{ revert("remove liquidity failed");}

        uint256 riceFee = riceAmount * fee / feeDenominator;
        uint256 busdFee = busdAmount * fee / feeDenominator;

        // swap busd for bnb
        uint256[] memory amounts = swapBusdForBnb(busdAmount - busdFee);

        IERC20(RICE).approve(address(router), riceAmount-riceFee);
        addLiquidityBnb(RICE, amounts[1], riceAmount - riceFee);
    }


    /// @dev we use 1 % slippage since there should be a lot of liquidity
    function swapBusdForBnb(uint256 amount) internal returns (uint256[] memory amounts) {
        // check reserves for price of BNB
        (uint112 amount1, uint112 amount2, ) = ISwapPair(BNB_BUSD).getReserves();
        uint256 priceOfBnb = amount1 > amount2 ? amount1 / amount2 : amount2 / amount1;

        require(priceOfBnb > 0, "Price of bnb should not be 0");

        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = router.WETH();

        IERC20(BUSD).approve(address(router), amount);
        try router.swapExactTokensForETH(amount, amount / priceOfBnb * 99 / 100, path, address(this), block.timestamp) returns (uint[] memory _amounts) {
            amounts = _amounts;
        }catch{revert("Swap failed");}
        return amounts;
    }


    function setRouter(address routerAddress) external onlyOwner {
        router = ISwapRouter(routerAddress);
    }

    function setBusd(address busdAddress) external onlyOwner {
        BUSD = busdAddress;
    }

    function setRice(address riceAddress) external onlyOwner {
        RICE = riceAddress;
    }

    function setRiceBnb(address riceBnbAddress) external onlyOwner {
        RICE_BNB = riceBnbAddress;
    }

    function setRiceBusd(address riceBusdAddress) external onlyOwner {
        RICE_BUSD = riceBusdAddress;
    }

    function setBusdBnb(address busdBnbAddress) external onlyOwner {
        BNB_BUSD = busdBnbAddress;
    }

    function setFeeReceiver(address feeAddress) external onlyOwner{
        feeReceiver = feeAddress;
    }

    /**
     * Not traditional slippage for front-run protection; the slippage value is calculated in the transaction.
     * However, this may be useful to prevent incorrect inputs to addLiquidity().
     */
    function setSlippage(uint _slippage, uint slippageDenom) external onlyOwner {
        slippage = _slippage;
        slippageDenominator = slippageDenom;
    }

    function setFee(uint256 _fee, uint256 _feeDenominator) external onlyOwner {
        require(_fee < _feeDenominator);
        fee = _fee;
        _feeDenominator = _feeDenominator;
    }

    function addLiquidityTokensAndBnb(address token, uint256 amount) public payable {
        IERC20 t = IERC20(token);
        t.approve(address(router), amount);
        require(t.balanceOf(msg.sender) >= amount, "FuzionLiquidity: Insufficient tokens.");
        require(t.transferFrom(msg.sender, address(this), amount), "FuzionLiquidity: Token transfer failed.");
        addLiquidityBnb(token, msg.value, amount);
    }

    function addLiquidityTokensAndBusd(address token, uint256 tokenAmount, uint256 busdAmount ) internal {
        IERC20 busd = IERC20(BUSD);
        IERC20 t = IERC20(token);
        busd.approve(address(router), busdAmount);
        t.approve(address(router), tokenAmount);
        require(t.transferFrom(msg.sender, address(this), tokenAmount), "FuzionLiquidity: Token transfer failed.");
        require(busd.transferFrom(msg.sender, address(this), busdAmount), "FuzionLiquidity: BUSD transfer failed.");
        addLiquidityTokens(token, tokenAmount, BUSD, busdAmount);
    }

    function addLiquidityBnb(address token, uint256 bnbAmount, uint256 tokenAmount) internal {
        router.addLiquidityETH{value: bnbAmount}(
            token,
            tokenAmount,
            tokenAmount * slippage / slippageDenominator,
            bnbAmount * slippage / slippageDenominator,
            msg.sender,
            block.timestamp
        );
    }

    function addLiquidityTokens(address token1, uint256 token1Amount, address token2, uint256 token2Amount) internal {
        router.addLiquidity(
            token1,
            token2,
            token1Amount,
            token2Amount,
            token1Amount * slippage / slippageDenominator,
            token2Amount * slippage / slippageDenominator,
            msg.sender,
            block.timestamp
        );
    }

    function removeLiquidityBnb(address lpAddress, address token, uint256 lpAmount) internal {
        IERC20 lp = IERC20(lpAddress);
        require(lp.transferFrom(msg.sender, address(this), lpAmount), "FuzionLiquidity: LP transfer failed.");
        lp.approve(address(router), lpAmount);
        router.removeLiquidityETH(token, lpAmount, 0, 0, msg.sender, block.timestamp);
    }

    function swapTokensForEth(address token, uint256 tokenAmount) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

        IERC20(token).approve(address(router), tokenAmount);
        return router.swapExactTokensForETH(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function retrieveTokens(address token) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this))), "Transfer failed");
    }

    function retrieveBnb() external onlyOwner {
        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Failed to retrieve BNB");
    }

}

// SPDX-License-Identifier: MIT

interface ISwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

interface ISwapPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISwapPair.sol";
import "./interfaces/ISwapFactory.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/DividendPayingTokenInterface.sol";
import "./interfaces/DividendPayingTokenOptionalInterface.sol";
import "./interfaces/IPazDividendTracker.sol";
import "./lib/SafeMathUint.sol";
import "./lib/SafeMathInt.sol";
import "./lib/SafeMath.sol";
import "./lib/IterableMapping.sol";
import "./lib/Ownable.sol";
import "./lib/ERC20.sol";



contract Pazzive is ERC20, Ownable {
    using SafeMath for uint256;

    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 live
    // 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47 testnet

    address public BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public DEAD = address(0x000000000000000000000000000000000000dEaD);
    address public ZERO = address(0x0000000000000000000000000000000000000000);
    address public PRIZE_WALLET;

    // amount of gas for auto-claiming dividends
    uint256 public PROCESS_DIVIDEND_GAS_AMOUNT = 300000;

    uint256 internal DECIMALS = 10 ** 18;

    ISwapRouter public router;
    address public swapPair;
    mapping(address => bool) public swapPairs;

    bool private swapping;
    bool private lockingEnabled = false;
    bool public tradingEnabled = false;
    bool public progressiveFeeEnabled = true;
    mapping(address => bool) public isDumper;

    IPazDividendTracker public dividendTracker;

    address public autoLiquidityReceiver;

    address payable public devAddress = payable(0x87500968B83f3f7091B85ea58dAaBc815935b553);
    address payable public marketingAddress = payable(0x76CAA60eF45C67462eF0d20EbC3C8aCC039eC26f);

    // 10k being the smallest antiwhale
    uint256 public MIN_MAX_SELL_AMOUNT = 10000 * DECIMALS;
    uint256 public MAX_SELL_AMOUNT = 0;

    uint256 public MIN_TOKENS_TO_SWAP = 40000000 * DECIMALS;
    uint256 public MAX_TOKENS_TO_SWAP = 250000000000 * DECIMALS;

    uint256 public MAX_TEAM_FEE = 50;
    uint256 public MAX_BUY_FEE = 150;
    uint256 public MAX_SELL_FEE = 999;
    uint256 public liquidityFee = 40;
    uint256 public rewardFee = 70;
    uint256 public teamFee = 30;
    uint256 public totalBuyFee = 140;
    uint256 public totalSellFee = 280;
    uint256 public feeDenominator = 1000;
    uint256 public sellFeeMultiplier = 200;
    uint256 public sellFeeMultiplierDenominator = 100;

    bool public swapAndLiquifyEnabled = true;

    uint256 public launchedAt;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _excludedFromAntiWhale;
    mapping(address => bool) private _isBlacklisted;

    mapping(address => uint256) public userLockBonus;
    mapping(address => uint256) public userLockEndTime;
    mapping(uint256 => uint256) public lockDurationToBonus;
    mapping(uint256 => uint256) public lockDurationToUserCount;
    mapping(address => bool) public userLockedForYear;

    mapping(address => uint256) public lastSale;
    mapping(uint256 => uint8) public lastSaleToPenalty;
    mapping(address => bool) public routers;

    event UserLockedTokens(address indexed account, uint256 duration);
    event EnableSwapAndLiquify(bool enabled);
    event SetDividendTracker(address indexed newAddress, address indexed oldAddress);
    event SetRouter(address indexed newAddress, address indexed oldAddress);
    event TradingEnabled(uint256 blockNumber, uint256 timestamp);
    event UpdateFees(uint256 dev, uint256 liquidity, uint256 rewardBuy, uint256 rewardSell);
    event SetSwapPair(address indexed pair, bool indexed value);
    event ProcessDividendGasAmountUpdated(uint256 indexed newGasAmount, uint256 indexed previousGasAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 pazAmount, uint256 busdAmount, bool success);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);
    event PrizeWalletDeposit(address prizeWallet, uint256 amount);
    event TaxFreeSwap(address user, address token, uint256 busdAmount, uint256 tokenAmount);
    event LockedForYear(address user, uint256 endTime);

    /**
    * @notice prevents sells that are too big
    * @dev 3 checks, 1: antiwhale turned on 2: is sending to pair aka sell 3. not coming from router
    */
    modifier antiWhale(address from, address to, uint256 amount) {
        // 1. antiwhale on 2. is Sell 3. is not remove liquidity 4,5. is not exempt from limit
        if (MAX_SELL_AMOUNT != 0 && swapPairs[to] && !routers[from] && !_excludedFromAntiWhale[from] && !_excludedFromAntiWhale[to]) {
            require(amount <= MAX_SELL_AMOUNT, "Pazzive: amount greater than maxSellAmount");
        }
        _;
    }

    constructor(address routerAddress, address busdAddress) ERC20("Pazzive", "PAZ") {
        BUSD = address(busdAddress);

        autoLiquidityReceiver = owner();

        router = ISwapRouter(routerAddress);

        swapPair = createPair();

        // exclude from fees
        _isExcludedFromFees[autoLiquidityReceiver] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[devAddress] = true;
        _isExcludedFromFees[marketingAddress] = true;

        // exclude from antiwhale
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[autoLiquidityReceiver] = true;
        _excludedFromAntiWhale[owner()] = true;
        _excludedFromAntiWhale[devAddress] = true;
        _excludedFromAntiWhale[marketingAddress] = true;

        // lock duration to bonus
        lockDurationToBonus[60 days] = 15;
        lockDurationToBonus[110 days] = 30;
        lockDurationToBonus[200 days] = 60;
        lockDurationToBonus[365 days] = 100;

        lastSaleToPenalty[1 days] = 100;
        lastSaleToPenalty[2 days] = 75;
        lastSaleToPenalty[3 days] = 50;
        lastSaleToPenalty[7 days] = 25;
        lastSaleToPenalty[14 days] = 10;

        totalBuyFee = rewardFee.add(liquidityFee).add(teamFee);
        totalSellFee = totalBuyFee.mul(sellFeeMultiplier).div(sellFeeMultiplierDenominator);

        // @dev _mint is internal to ERC20.sol this is the only time it will ever be called
        // total supply to be 1 Trillion
        _mint(owner(), 1000000000000 * DECIMALS);
    }

    function setLastSaleToPenalty(uint256 timePeriod, uint8 penalty) external onlyOwner {
        lastSaleToPenalty[timePeriod] = penalty;
    }

    function setProgressiveFeeEnabled(bool isEnabled) external onlyOwner {
        progressiveFeeEnabled = isEnabled;
    }

    function setIsDumper(address[] memory dumperList, bool _isDumper) external onlyOwner {
        for (uint i=0; i<dumperList.length; i++) {
            isDumper[dumperList[i]] = _isDumper;
        }
    }

    function createPair() public onlyOwner returns (address) {
        return ISwapFactory(router.factory()).createPair(address(this), router.WETH());
    }

    function setDividendTracker(address trackerAddress) external onlyOwner {
        require(trackerAddress != address(dividendTracker), "Pazzive: already current tracker");
        address previousTracker = address(dividendTracker);
        dividendTracker = IPazDividendTracker(trackerAddress);

        dividendTracker.setExcludedFromDividends(address(dividendTracker), true);
        dividendTracker.setExcludedFromDividends(address(this), true);
        dividendTracker.setExcludedFromDividends(DEAD, true);
        dividendTracker.setExcludedFromDividends(address(0), true);
        dividendTracker.setExcludedFromDividends(owner(), true);
        dividendTracker.setExcludedFromDividends(address(router), true);

        _isExcludedFromFees[address(dividendTracker)] = true;

        setRouters(address(router), true);
        setSwapPairs(swapPair, true);

        emit SetDividendTracker(trackerAddress, previousTracker);
    }

    /// Set the Prize Wallet
    /// @dev prize wallet will be excluded from dividends, fees, antiwhale
    function setPrizeWallet(address prizeWalletAddress) external onlyOwner{
        dividendTracker.setExcludedFromDividends(prizeWalletAddress, true);
        _isExcludedFromFees[prizeWalletAddress] = true;
        _excludedFromAntiWhale[prizeWalletAddress] = true;
        _approve(prizeWalletAddress, address(this), ~uint256(0));
//        emit PrizeWalletUpdated(PRIZE_WALLET, prizeWalletAddress);
        PRIZE_WALLET = prizeWalletAddress;
    }

    function deposit(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Pazzive: not enough pazzive");
        super._transfer(msg.sender, address(this), amount);
        swapAndSendDividends(amount);
    }

    function depositPrize(uint256 amount) external onlyOwner {
        require(balanceOf(msg.sender) >= amount, "Pazzive: not enough pazzive");
        _approve(PRIZE_WALLET, address(this), ~uint256(0));
        super._transfer(PRIZE_WALLET, address(this), amount);
        swapAndSendDividends(amount);
        emit PrizeWalletDeposit(PRIZE_WALLET, amount);
    }

    function userSwappedBusd(address user) external view returns (uint256){
        return dividendTracker.getUserSwappedBusd(user);
    }

    receive() external payable {}

    function setRouters(address routerAddress, bool allow) public onlyOwner {
        require(_isContract(routerAddress), "Pazzive: Router must be contract");
        routers[routerAddress] = allow;
        dividendTracker.setAllowedRouter(routerAddress, allow);
    }

    function setLockDurationToBonus(uint256 duration, uint256 bonus) public onlyOwner {
        require(lockDurationToBonus[duration] != bonus, "Pazzive: Bonus already set for duration");
        require(bonus <= 100, "Pazzive: Staking bonus can't exceed 100");
        lockDurationToBonus[duration] = bonus;
//        emit SetLockDurationToBonus(duration, bonus);
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Pazzive: trading already enabled");
        tradingEnabled = true;
        launchedAt = block.number;
        emit TradingEnabled(block.number, block.timestamp);
    }

    /**
    * @dev exclude ifo contract from fees and dividends
    */
    function prepareForIfo(address ifoContract) external onlyOwner {
        swapAndLiquifyEnabled = false;
        _isExcludedFromFees[ifoContract] = true;
        dividendTracker.setExcludedFromDividends(ifoContract, true);
//        emit SetIfoContract(ifoContract);
    }

    function afterIfo() external onlyOwner {
        swapAndLiquifyEnabled = true;
        enableTrading();
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function setLockingEnabled(bool enable) public onlyOwner {
        require(lockingEnabled != enable, "Pazzive: locking enabled already set");
        lockingEnabled = enable;
//        emit EnableTokenLocking(enable);
    }

    function lockTokens(uint256 duration) public {
        require(lockingEnabled, "Pazzive: Locking is not enabled");
        require(lockDurationToBonus[duration] != 0, "Pazzive: Invalid lock duration");
        require(userLockEndTime[_msgSender()] < block.timestamp.add(duration), "Pazzive: Already locked for a longer duration");

        userLockBonus[_msgSender()] = lockDurationToBonus[duration];
        userLockEndTime[_msgSender()] = block.timestamp.add(duration);

        dividendTracker.setBalance(_msgSender(), getBalance(_msgSender()));

        // if user locks for a year then they will be excluded from fees
        if(duration >= 365 days){
            userLockedForYear[msg.sender] = true;
            emit LockedForYear(msg.sender, userLockEndTime[msg.sender]);
        }

        emit UserLockedTokens(_msgSender(), duration);
    }

    function setMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(MAX_SELL_AMOUNT != _maxSellAmount, "Pazzive: antiwhale already set");
        require(_maxSellAmount == 0 || _maxSellAmount >= MIN_MAX_SELL_AMOUNT, "Pazzive: max sell amount must either be disabled or greater than 10000");
        MAX_SELL_AMOUNT = _maxSellAmount;
    }

    function setDevAddress(address payable _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }

    function setMarketingAddress(address payable _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(router), "Pazzive: already set to that router");
        emit SetRouter(routerAddress, address(router));
        router = ISwapRouter(routerAddress);
        dividendTracker.updateRouter(routerAddress);
    }

    function setSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled, "Pazzive: swap and liquify already set to that value");
        swapAndLiquifyEnabled = enabled;

        emit EnableSwapAndLiquify(enabled);
    }

    function setSwapPairs(address pair, bool isPair) public onlyOwner {
        swapPairs[pair] = isPair;

        if (isPair) {
            swapPair = pair;
            dividendTracker.setExcludedFromDividends(pair, true);
        }

        emit SetSwapPair(pair, isPair);
    }

    function setSwapPair(address pair) external onlyOwner {
        swapPair = pair;
    }

//    function setAllowCustomTokens(bool allow) public onlyOwner {
//        dividendTracker.setAllowCustomTokens(allow);
//    }

    function updateLiquidityWallet(address lpWallet) public onlyOwner {
        _isExcludedFromFees[lpWallet] = true;
        autoLiquidityReceiver = lpWallet;
    }

    function setProcessDividendGasAmount(uint256 dividendGasAmount) public onlyOwner {
        require(dividendGasAmount >= 200000 && dividendGasAmount <= 500000, "Pazzive: gas amount must be between 200000 and 500000");
        emit ProcessDividendGasAmountUpdated(dividendGasAmount, PROCESS_DIVIDEND_GAS_AMOUNT);
        PROCESS_DIVIDEND_GAS_AMOUNT = dividendGasAmount;
    }

    function setFees(uint256 _liquidityFee, uint256 _rewardFee, uint256 _teamFee, uint256 _sellFeeMultiplier, uint256 _sellFeeMultiplierDenominator) external onlyOwner {
        require(_teamFee <= MAX_TEAM_FEE, "Pazzive: Team fee too high");
        liquidityFee = _liquidityFee;
        rewardFee = _rewardFee;
        teamFee = _teamFee;
        totalBuyFee = _liquidityFee.add(_rewardFee).add(_teamFee);
        require(totalBuyFee <= MAX_BUY_FEE, "Pazzive: Buy fee too high");
        totalSellFee = totalBuyFee.mul(_sellFeeMultiplier).div(_sellFeeMultiplierDenominator);
        require(totalSellFee <= MAX_SELL_FEE, "Pazzive: Sell fee too high");
        sellFeeMultiplier = _sellFeeMultiplier;
        sellFeeMultiplierDenominator = _sellFeeMultiplierDenominator;
    }

//    function getLockingInfo(address account) external view returns (uint256, uint256){
//        return (userLockEndTime[account], userLockBonus[account]);
//    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    // region Exclusions

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool isExcluded) external onlyOwner {
        require(_isExcludedFromFees[account] != isExcluded, "Pazzive: account already set to excluded value");
        _isExcludedFromFees[account] = isExcluded;
    }

    function isExcludedFromAntiWhale(address account) public view returns (bool) {
        return _excludedFromAntiWhale[account];
    }

    /**
    * @dev Exclude or include an address from antiWhale.
    * Can only be called by the current owner.
    */
    function setExcludedFromAntiWhale(address _account, bool excluded) external onlyOwner {
        _excludedFromAntiWhale[_account] = excluded;
    }

    function setIsBlacklisted(address user, bool blacklisted) external onlyOwner {
        _isBlacklisted[user] = blacklisted;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function isExcludedFromDividends(address account) external view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setExcludedFromDividends(address account, bool excluded) external onlyOwner {
        return dividendTracker.setExcludedFromDividends(account, excluded);
    }

    // endregion: exclusions

//    function setDividendsPaused(bool value) external onlyOwner {
//        dividendTracker.setDividendsPaused(value);
//    }

    function withdrawableDividendOf(address account) public view returns (uint256){
        return dividendTracker.withdrawableDividendOf(account);
    }

//    function dividendTokenBalanceOf(address account) public view returns (uint256){
//        return dividendTracker.balanceOf(account);
//    }

    function getAccount(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256){
        return dividendTracker.getAccount(account);
    }

//    function getAccountAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256){
//        return dividendTracker.getAccountAtIndex(index);
//    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

//    function getNumberOfDividendTokenHolders() external view returns (uint256) {
//        return dividendTracker.getNumberOfTokenHolders();
//    }

    function _transfer(address from, address to, uint256 amount) internal override antiWhale(from, to, amount) {
        require(from != address(0), "Pazzive: transfer from the zero address");
        require(to != address(0), "Pazzive: transfer to the zero address");
        // this is to prevent others from front running liquidity before the team can to set the price
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Pazzive: Trading not enabled");
        require(!_isBlacklisted[from], "Pazzive: Address is blacklisted");



        if (amount == 0){
            _basicTransfer(from, to, amount);
            return;
        }

        if(!swapping){
            handleLocking(from);
            if(swapPairs[to]){lastSale[from] = block.timestamp;}
            if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                amount = transferWithFee(from, to, amount);
            }
        }

        _basicTransfer(from, to, amount);
    }

    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {

        super._transfer(from, to, amount);
        if(amount > 0){
            dividendTracker.setBalance(from, getBalance(from));
            dividendTracker.setBalance(to, getBalance(to));
        }
        return true;
    }

    function handleLocking(address from) internal {

        if(!lockingEnabled){

            return;
        }

        // after locked for a year


        if(userLockEndTime[from] <= block.timestamp && userLockedForYear[from]){
            _isExcludedFromFees[from] = true;
        }

        // if they move their tokens after lock is over they lose the bonus
        if (!swapPairs[from]) {
            require(userLockEndTime[from] <= block.timestamp, "Pazzive: Tokens are locked.");
            if (userLockEndTime[from] != 0) {
                userLockEndTime[from] = 0;
                userLockBonus[from] = 0;
            }
        }
    }

    function transferWithFee(address from, address to, uint256 amount) internal returns (uint256) {

        bool isSell = swapPairs[to];

//        handleLocking(from);

        // update users's lastSale
        if(isSell){lastSale[from] = block.timestamp;}
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= MIN_TOKENS_TO_SWAP;

        if (canSwap && !swapPairs[from]) {
            swapping = true;
            uint256 swapAndLiquifyAmount;

            if (swapAndLiquifyEnabled) {
                contractTokenBalance = contractTokenBalance > MAX_TOKENS_TO_SWAP ? MAX_TOKENS_TO_SWAP : contractTokenBalance;
                swapAndLiquifyAmount = contractTokenBalance.mul(liquidityFee).div(totalBuyFee);
                swapAndLiquify(swapAndLiquifyAmount);
            }

            uint256 remainingBalance = contractTokenBalance.sub(swapAndLiquifyAmount);
            swapAndSendDividends(remainingBalance);
            swapping = false;
        }
        amount = takeFee(from, to, amount);

        try dividendTracker.process(PROCESS_DIVIDEND_GAS_AMOUNT) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, PROCESS_DIVIDEND_GAS_AMOUNT, tx.origin);
        } catch {}

        return amount;
    }

    function takeFee(address from, address to, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = amount.mul(getTotalFee(from, swapPairs[to])).div(feeDenominator);

        super._transfer(from, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function getTotalFee(address user, bool selling) internal view returns (uint256) {
        if (block.number <= launchedAt+1) {return feeDenominator.sub(1);}
        return selling ? getUserSellFee(user) : totalBuyFee;
    }

    /// Returns sell fee for a user
    /// @dev dumpers get 2x fee
    /// @dev if sold within 1 day - 100% increase
    /// @dev if sold within 2 day - 75% increase
    /// @dev if sold within 3 day - 50% increase
    /// @dev if sold within 7 day - 25% increase
    /// @dev if sold within 14 day - 10% increase
    function getUserSellFee(address user) public view returns (uint256){
        uint8 multiplier = 100;
        uint8 denominator = 100;

        // dumpers will have double
        if(isDumper[user]){
            return totalSellFee.mul(2);
        }

        if(lastSale[user] == 0 || !progressiveFeeEnabled){
            return totalSellFee;
        }

        uint256 timeSinceLastSale = block.timestamp.sub(lastSale[user]);

        if(timeSinceLastSale < 1 days){
            multiplier += lastSaleToPenalty[1 days];
        }else if(timeSinceLastSale < 2 days){
            multiplier += lastSaleToPenalty[2 days];
        } else if(timeSinceLastSale < 3 days){
            multiplier += lastSaleToPenalty[3 days];
        }else if(timeSinceLastSale < 7 days){
            multiplier += lastSaleToPenalty[7 days];
        }else if(timeSinceLastSale < 14 days){
            multiplier += lastSaleToPenalty[14 days];
        }

        return totalSellFee.mul(multiplier).div(denominator);
    }

    // todo: not used
//    function shouldTakeFee(address from, address to) internal view returns (bool){
//        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !launched()) return false;
//        if(swapPairs[from] || swapPairs[to]) return true;
//        return feesOnNormalTransfers;
//    }

    // todo: come back to this for multiplied fees
//    function getMultipliedFee() public view returns (uint256) {
//        uint totalFee = totalSellFee;
////        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
////        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
////        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
//        return totalFee;
//    }

    /// @dev gets the balance including any locking bonus
    function getBalance(address account) public view returns (uint256) {
        return lockingEnabled ? balanceOf(account).mul(userLockBonus[account].add(100)).div(100) : balanceOf(account);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 amountToEth = tokens.div(2);
        uint256 amountToLiquidity = tokens.sub(amountToEth);
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToEth);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToEth, 0, path, address(this), block.timestamp);

        uint256 ethAmount = address(this).balance.sub(initialBalance);

        _approve(address(this), address(router), amountToLiquidity);
        router.addLiquidityETH{value: ethAmount}(address(this), amountToLiquidity, 0, 0, autoLiquidityReceiver, block.timestamp);

        emit SwapAndLiquify(amountToEth, ethAmount, amountToLiquidity);
    }

//    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
//        _approve(address(this), address(router), tokenAmount);
//        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, autoLiquidityReceiver, block.timestamp);
//    }

//    function swapTokensForEth(uint256 tokenAmount) private {
//        address[] memory path = new address[](2);
//        path[0] = address(this);
//        path[1] = router.WETH();
//
//        _approve(address(this), address(router), tokenAmount);
//
//        // make the swap
//        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
//    }

    function swapTokensForBusd(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = BUSD;

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }


    function setUserRewardToken(address token) public {
        require(balanceOf(msg.sender) > 0, "Pazzive: User has no pazzive");
        dividendTracker.setUserRewardToken(msg.sender, token);
    }

    function getUserRewardToken(address account) public view returns (address) {
        return dividendTracker.getUserRewardToken(account);
    }

//    function setAllowedTokens(address token, bool allow) public onlyOwner {
//        dividendTracker.setAllowedTokens(token, allow);
//        emit SetAllowedTokens(token, allow);
//    }

//    function getAllowedTokens(address token) public view returns (bool) {
//        return dividendTracker.getAllowedTokens(token);
//    }

    function sendDividends(uint256 tokens) external onlyOwner {
        swapAndSendDividends(tokens);
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForBusd(tokens);
        uint256 busdAmount = IERC20(BUSD).balanceOf(address(this));
        uint256 teamAmount = busdAmount.mul(teamFee).div(feeDenominator);
        uint256 dividendAmount = busdAmount.sub(teamAmount);

        bool success = IERC20(BUSD).transfer(address(dividendTracker), dividendAmount);

        uint256 marketingShare = teamAmount.mul(4).div(10);
        uint256 devShare = teamAmount - marketingShare;
        bool successDev = IERC20(BUSD).transfer(address(devAddress), devShare);
        bool successMarketing = IERC20(BUSD).transfer(address(marketingAddress), marketingShare);

        if(success){
            dividendTracker.distributeDividends(dividendAmount);
        }

        emit SendDividends(tokens, busdAmount, success && successDev && successMarketing);
    }

    /**
    * Any user who has claimed BUSD dividends can invest those funds tax free into any fuzion token
    */
    function taxFreeReinvest(address token, uint256 amount) external {
        require(amount <= dividendTracker.getUserTaxFreeReinvestAmount(msg.sender), "Pazzive: Can only reinvest up to your total rewards");
        require(IERC20(BUSD).transferFrom(msg.sender, address(this), amount), "Pazzive: Did not receive BUSD");

        address[] memory path = new address[](3);
        path[0] = BUSD;
        path[1] = router.WETH();
        path[2] = token;

        ISwapRouter _router = dividendTracker.getRouter(token);
        IERC20(BUSD).approve(address(_router), amount);
        uint256 swappedBusd = dividendTracker.userSwappedBusd(msg.sender);

        // no slippage needed as there is high liquidity for BUSD/BNB liquidity and all our tokens have tax
        try _router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp) returns (uint[] memory amounts){
            IERC20(token).transfer(msg.sender, amounts[2]);
            swappedBusd+=amount;
            dividendTracker.setUserSwappedBusd(msg.sender, swappedBusd);
            emit TaxFreeSwap(msg.sender, token, amount, amounts[2]);
        }catch{}
    }

    /// Tax Free Liquidity for PAZ
    function taxFreeLiquidity(uint256 tokenAmount) external payable {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient tokens");
        _approve(msg.sender, address(this), tokenAmount);
        super._transfer(msg.sender, address(this), tokenAmount);
        router.addLiquidityETH{value: msg.value}(address(this), tokenAmount, 0, 0, msg.sender, block.timestamp);
    }

    /**
    * @notice Checks if address is a contract
    * @dev Technically this can be tricked by calling if this method was called in a
    * constructor but we are only adding existing contracts so should not be an issue.
    */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            payable(owner()).transfer(balance);
        }
    }

    function recoverTokens(address _token, address _to) external onlyOwner returns(bool _sent){
        require(_token != address(this), "Pazzive: Can not be pazzive token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

}

// SPDX-License-Identifier: MIT
import "./ISwapRouter.sol";

interface IPazDividendTracker {
//  function BUSD (  ) external view returns ( address );
//  function MIN_BALANCE_AUTO_DIVIDENDS (  ) external view returns ( uint256 );
//  function MIN_BALANCE_DIVIDENDS (  ) external view returns ( uint256 );
//  function MIN_CLAIM_INTERVAL (  ) external view returns ( uint256 );
//  function MIN_DIVIDEND_DISTRIBUTION (  ) external view returns ( uint256 );
//  function accumulativeDividendOf ( address _owner ) external view returns ( uint256 );
//  function allowAutoReinvest (  ) external view returns ( bool );
//  function allowCustomTokens (  ) external view returns ( bool );
//  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function allowedRouters ( address ) external view returns ( bool );
  function allowedTokens ( address ) external view returns ( bool );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function autoReinvest ( address ) external view returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function distributeDividends ( uint256 amount ) external;
  function dividendOf ( address _owner ) external view returns ( uint256 );
  function dividendsPaused (  ) external view returns ( bool );
  function excludedFromDividends ( address ) external view returns ( bool );
  function getAccount ( address _account ) external view returns ( address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable );
  function getAccountAtIndex ( uint256 index ) external view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256 );
  function getAllowedTokens ( address token ) external view returns ( bool );
  function getLastProcessedIndex (  ) external view returns ( uint256 );
  function getNumberOfTokenHolders (  ) external view returns ( uint256 );
  function getUserActualRewardToken ( address user ) external view returns ( address );
  function getUserRewardToken ( address account ) external view returns ( address );
  function getUserSwappedBusd ( address user ) external view returns ( uint256 );
  function getUserTaxFreeReinvestAmount ( address user ) external view returns ( uint256 );
  function getRouter ( address token ) external view returns ( ISwapRouter );
//  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function isExcludedFromDividends ( address account ) external view returns ( bool );
//  function isReinvest ( address account ) external view returns ( bool );
  function lastProcessedIndex (  ) external view returns ( uint256 );
//  function name (  ) external view returns ( string );
  function owner (  ) external view returns ( address );
//  function paz (  ) external view returns ( address );
  function process ( uint256 gas ) external returns ( uint256, uint256, uint256 );
  function processAccount ( address account, bool automatic ) external returns ( bool );
//  function recoverTokens ( address _token, address _to ) external returns ( bool _sent );
//  function renounceOwnership (  ) external;
//  function router (  ) external view returns ( address );
//  function setAllowAutoReinvest ( bool allow ) external;
//  function setAllowCustomTokens ( bool allow ) external;
  function setAllowedRouter ( address routerAddress, bool allow ) external;
  function setAllowedTokens ( address token, bool allow ) external;
  function setAutoReinvest ( address account, bool shouldAutoReinvest ) external;
  function setBalance ( address account, uint256 newBalance ) external;
  function setDividendsPaused ( bool isPaused ) external;
  function setExcludedFromDividends ( address account, bool excluded ) external;
  function setMinBalanceAutoDividends ( uint256 minBalanceAutoDividends ) external;
  function setMinBalanceDividends ( uint256 minBalanceDividends ) external;
  function setMinClaimInterval ( uint256 minClaimInterval ) external;
  function setMinDividendDistribution ( uint256 minDividendDistribution ) external;
  function setTokenRouter ( address token, address routerAddress ) external;
  function setUserRewardToken ( address account, address token ) external;
  function setUserSwappedBusd ( address user, uint256 amount ) external;
  function sweep (  ) external;
//  function symbol (  ) external view returns ( string );
  function taxFreeReinvest ( address token, uint256 amount ) external;
  function tokenRouter ( address ) external view returns ( address );
  function tokenToUserCount ( address ) external view returns ( uint256 );
  function totalDividendsDistributed (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function updateRouter ( address newAddress ) external;
  function userLastClaimTime ( address ) external view returns ( uint256 );
  function userRewardToken ( address ) external view returns ( address );
  function userSwappedBusd ( address ) external view returns ( uint256 );
  function withdrawDividend (  ) external pure;
  function withdrawableDividendOf ( address _owner ) external view returns ( uint256 );
  function withdrawnDividendOf ( address _owner ) external view returns ( uint256 );
}