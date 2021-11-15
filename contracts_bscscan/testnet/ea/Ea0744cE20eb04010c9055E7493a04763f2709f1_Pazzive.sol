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
    // todo: not needed
    receive() external payable {
        distributeDividends();
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
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
    function distributeDividends() public payable virtual override {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    function distributeBusdDividends(uint256 amount) public payable {
        require(totalSupply() > 0, "DividendPayingToken: Supply must be greater than 0.");

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
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
    function distributeDividends() external payable;

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

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

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

pragma solidity ^0.8.0;

import "./interfaces/ISwapPair.sol";
import "./interfaces/ISwapFactory.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/DividendPayingTokenInterface.sol";
import "./interfaces/DividendPayingTokenOptionalInterface.sol";
import "./lib/SafeMathUint.sol";
import "./lib/SafeMathInt.sol";
import "./lib/SafeMath.sol";
import "./lib/IterableMapping.sol";
import "./lib/Ownable.sol";
import "./DividendPayingToken.sol";



contract Pazzive is ERC20, Ownable {
    using SafeMath for uint256;

    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 live
    // 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47 testnet
    address public BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public DEAD = address(0x000000000000000000000000000000000000dEaD);
    // address public TS = address();
    // address public RICE = address();

    // amount of gas for auto-claiming dividends
    uint256 public PROCESS_DIVIDEND_GAS_AMOUNT = 300000;

    uint256 public DECIMALS = 10 ** 9;

    ISwapRouter public router;
    address public swapPair;
    mapping(address => bool) public swapPairs;

    bool private swapping;
    bool private stakingEnabled = false;
    bool public tradingEnabled = false;
    uint256 public sellAmount = 0;
    uint256 public buyAmount = 0;
    uint256 private totalSellFees;
    uint256 private totalBuyFees;

    bool public feesOnNormalTransfers = false;

    PazDividendTracker public dividendTracker;

    address public autoLiquidityReceiver;

    address payable public devAddress = payable(0x87500968B83f3f7091B85ea58dAaBc815935b553);
    address payable public marketingAddress = payable(0x76CAA60eF45C67462eF0d20EbC3C8aCC039eC26f);

    // 1 million being the smallest antiwhale
    uint256 public MIN_MAX_SELL_AMOUNT = 1000000 * DECIMALS;
    uint256 public maxSellAmount = 0;
    uint256 public swapTokensAtAmount = 40000000 * DECIMALS;
    uint256 public maxTokensToSwap = 250000000000 * DECIMALS;

    uint256 public MAX_TEAM_FEE = 50;
    uint256 public MAX_BUY_FEE = 150;
    uint256 public MAX_SELL_FEE = 999;
    uint256 public liquidityFee = 40;
    uint256 public rewardFee = 80;
    uint256 public teamFee = 20;
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

    mapping(address => uint256) public stakingBonus;
    mapping(address => uint256) public stakingUntilDate;
    mapping(uint256 => uint256) public stakingAmounts;

    mapping(address => uint256) public lastSale;
    mapping(address => bool) public routers;

    event EnableAccountStaking(address indexed account, uint256 duration);
    event UpdateStakingAmounts(uint256 duration, uint256 amount);
    event EnableSwapAndLiquify(bool enabled);
    event EnableStaking(bool enabled);
    event SetIfoContract(address ifoContract);
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event TradingEnabled(uint256 blockNumber, uint256 timestamp);
    event UpdateFees(uint256 dev, uint256 liquidity, uint256 rewardBuy, uint256 rewardSell);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetSwapPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event ProcessDividendGasAmountUpdated(uint256 indexed newGasAmount, uint256 indexed previousGasAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 pazAmount, uint256 busdAmount, bool success);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);
    event UpdatePayoutToken(address account, address token);
    event UpdateAllowTokens(address token, bool allow);

    /**
    * @notice prevents sells that are too big
    * @dev 3 checks, 1: antiwhale turned on 2: is sending to pair aka sell 3. not coming from router
    */
    modifier antiWhale(address from, address to, uint256 amount) {
        // 1. antiwhale on 2. is Sell 3. is not remove liquidity 4,5. is not exempt from limit
        if (maxSellAmount != 0 && swapPairs[to] && !routers[from] && !_excludedFromAntiWhale[from] && !_excludedFromAntiWhale[to]) {
            require(amount <= maxSellAmount, "Pazzive: amount greater than maxSellAmount");
        }
        _;
    }

    constructor(address routerAddress, address busdAddress) ERC20("Pazzive", "PAZ") {
        dividendTracker = new PazDividendTracker(payable(this), routerAddress, busdAddress);
        BUSD = address(busdAddress);

        autoLiquidityReceiver = owner();

        router = ISwapRouter(routerAddress);
        setRouters(routerAddress, true);

        // Create a uniswap pair for this new token
        swapPair = ISwapFactory(router.factory()).createPair(address(this), router.WETH());

        setSwapPair(swapPair, true);

        // exclude from dividends
        dividendTracker.setExcludedFromDividends(address(dividendTracker), true);
        dividendTracker.setExcludedFromDividends(address(this), true);
        dividendTracker.setExcludedFromDividends(DEAD, true);
        dividendTracker.setExcludedFromDividends(address(0), true);
        dividendTracker.setExcludedFromDividends(owner(), true);
        dividendTracker.setExcludedFromDividends(address(router), true);

        // exclude from fees
        _isExcludedFromFees[autoLiquidityReceiver] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;
        _isExcludedFromFees[devAddress] = true;
        _isExcludedFromFees[marketingAddress] = true;

        // exclude from antiwhale
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[autoLiquidityReceiver] = true;
        _excludedFromAntiWhale[owner()] = true;
        _excludedFromAntiWhale[devAddress] = true;
        _excludedFromAntiWhale[marketingAddress] = true;

        totalBuyFee = rewardFee.add(liquidityFee).add(teamFee);
        totalSellFee = totalBuyFee.mul(sellFeeMultiplier).div(sellFeeMultiplierDenominator);

        // @dev _mint is internal to ERC20.sol this is the only time it will ever be called
        // total supply to be 1 Trillion
        _mint(owner(), 1000000000000 * DECIMALS);
    }

    function MIN_BALANCE_AUTO_DIVIDENDS() external view returns (uint256) {
        return dividendTracker.MIN_BALANCE_AUTO_DIVIDENDS();
    }

    function setMinBalanceAutoDividends(uint256 minBalanceAutoDividends) external onlyOwner {
        dividendTracker.setMinBalanceAutoDividends(minBalanceAutoDividends);
    }

    function MIN_BALANCE_DIVIDENDS() external view returns (uint256) {
        return dividendTracker.MIN_BALANCE_DIVIDENDS();
    }

    function setMinBalanceDividends(uint256 minBalanceDividends) external onlyOwner {
        dividendTracker.setMinBalanceDividends(minBalanceDividends);
    }

    function MIN_DIVIDEND_DISTRIBUTION() external view returns (uint256) {
        return dividendTracker.MIN_DIVIDEND_DISTRIBUTION();
    }

    function setMinDividendDistribution(uint256 minDividendDistribution) external onlyOwner {
        dividendTracker.setMinDividendDistribution(minDividendDistribution);
    }

    function MIN_CLAIM_INTERVAL() external view returns (uint256) {
        return dividendTracker.MIN_CLAIM_INTERVAL();
    }

    function setMinClaimInterval(uint256 minClaimInterval) external onlyOwner {
        dividendTracker.setMinClaimInterval(minClaimInterval);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    receive() external payable {}

    function setRouters(address routerAddress, bool allow) public onlyOwner {
        require(_isContract(routerAddress), "Pazzive: Router must be contract");
        routers[routerAddress] = allow;
        dividendTracker.setAllowedRouter(routerAddress, allow);
    }

    function updateStakingAmounts(uint256 duration, uint256 bonus) public onlyOwner {
        require(stakingAmounts[duration] != bonus, "Pazzive: Bonus already set for duration");
        require(bonus <= 100, "Pazzive: Staking bonus can't exceed 100");

        stakingAmounts[duration] = bonus;
        emit UpdateStakingAmounts(duration, bonus);
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
        emit SetIfoContract(ifoContract);
    }

    function afterIfo() external onlyOwner {
        swapAndLiquifyEnabled = true;
        enableTrading();
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function enableStaking(bool enable) public onlyOwner {
        require(stakingEnabled != enable, "Pazzive: staking already set");
        stakingEnabled = enable;
        emit EnableStaking(enable);
    }

    function stake(uint256 duration) public {
        require(stakingEnabled, "Pazzive: Staking is not enabled");
        require(stakingAmounts[duration] != 0, "Pazzive: Invalid staking duration");
        require(stakingUntilDate[_msgSender()] < block.timestamp.add(duration), "Pazzive: Already staked for a longer duration");

        stakingBonus[_msgSender()] = stakingAmounts[duration];
        stakingUntilDate[_msgSender()] = block.timestamp.add(duration);

        dividendTracker.setBalance(_msgSender(), getBalance(_msgSender()));

        emit EnableAccountStaking(_msgSender(), duration);
    }

    function setMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(maxSellAmount != _maxSellAmount, "Pazzive: antiwhale already set");
        require(_maxSellAmount == 0 || _maxSellAmount >= MIN_MAX_SELL_AMOUNT, "Pazzive: max sell amount must either be disabled or greater than 1 million");
        maxSellAmount = _maxSellAmount;
    }

    function updateDividendTracker(address trackerAddress) public onlyOwner {
        require(trackerAddress != address(dividendTracker), "Pazzive: already current tracker");

        PazDividendTracker newDividendTracker = PazDividendTracker(payable(trackerAddress));

        require(newDividendTracker.owner() == address(this));

        newDividendTracker.setExcludedFromDividends(address(newDividendTracker), true);
        newDividendTracker.setExcludedFromDividends(address(this), true);
        newDividendTracker.setExcludedFromDividends(owner(), true);
        newDividendTracker.setExcludedFromDividends(address(router), true);
        newDividendTracker.setExcludedFromDividends(address(swapPair), true);

        emit UpdateDividendTracker(trackerAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function setDevAddress(address payable _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }

    function setMarketingAddress(address payable _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setRouter(address routerAddress) public onlyOwner {
        require(routerAddress != address(router), "Pazzive: already set to that router");
        emit UpdateUniswapV2Router(routerAddress, address(router));
        router = ISwapRouter(routerAddress);
        dividendTracker.updateRouter(routerAddress);
    }

    function setSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled, "Pazzive: swap and liquify already set to that value");
        swapAndLiquifyEnabled = enabled;

        emit EnableSwapAndLiquify(enabled);
    }

    function setSwapPair(address pair, bool isPair) public onlyOwner {
        require(swapPairs[pair] != isPair, "Pazzive: already set");
        swapPairs[pair] = isPair;

        if (isPair) {
            swapPair = pair;
            dividendTracker.setExcludedFromDividends(pair, true);
        }

        emit SetSwapPair(pair, isPair);
    }

    function setAllowCustomTokens(bool allow) public onlyOwner {
        dividendTracker.setAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) public onlyOwner {
        dividendTracker.setAllowAutoReinvest(allow);
    }

    function updateLiquidityWallet(address lpWallet) public onlyOwner {
        _isExcludedFromFees[lpWallet] = true;
        emit LiquidityWalletUpdated(lpWallet, autoLiquidityReceiver);
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

    function getStakingInfo(address account) external view returns (uint256, uint256){
        return (stakingUntilDate[account], stakingBonus[account]);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isSwapPair(address pair) public view returns (bool){
        return swapPairs[pair];
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

    function setIsBlacklisted(address adr, bool blacklisted) external onlyOwner {
        _isBlacklisted[adr] = blacklisted;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    /// @dev this calls the tracker to get info
    function isExcludedFromDividends(address account) external view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setExcludedFromDividends(address account, bool excluded) external onlyOwner {
        return dividendTracker.setExcludedFromDividends(account, excluded);
    }

    /// @dev this calls the tracker to get info
    function isExcludedFromAutoClaim(address account) external view returns (bool) {
        return dividendTracker.isExcludedFromAutoClaim(account);
    }

    function setExcludedFromAutoClaim(address account, bool excluded) external onlyOwner {
        return dividendTracker.setExcludedFromAutoClaim(account, excluded);
    }

    // endregion: exclusions

    function setAutoClaim(bool value) external {
        dividendTracker.setExcludedFromAutoClaim(msg.sender, value);
    }

    function setReinvest(bool value) external {
        dividendTracker.setAutoReinvest(msg.sender, value);
    }

    function setDividendsPaused(bool value) external onlyOwner {
        dividendTracker.setDividendsPaused(value);
    }

    function isReinvest(address account) external view returns (bool) {
        return dividendTracker.isReinvest(account);
    }

    function withdrawableDividendOf(address account) public view returns (uint256){
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256){
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256){
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256){
        return dividendTracker.getAccountAtIndex(index);
    }

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

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

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

        if (!swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            amount = transferWithFee(from, to, amount);
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

    function handleStaking(address from) internal {
        if (!swapPairs[from] && stakingEnabled) {
            require(stakingUntilDate[from] <= block.timestamp, "Pazzive: Tokens are locked during staking period");
            if (stakingUntilDate[from] != 0) {
                stakingUntilDate[from] = 0;
                stakingBonus[from] = 0;
            }
        }
    }

    function transferWithFee(address from, address to, uint256 amount) internal returns (uint256) {

        bool isSell = swapPairs[to];
        handleStaking(from);

        // update users's lastSale
        if(isSell){lastSale[from] = block.timestamp;}
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapPairs[from]) {
            swapping = true;
            uint256 swapAndLiquifyAmount;

            if (swapAndLiquifyEnabled) {
                contractTokenBalance = contractTokenBalance > maxTokensToSwap ? maxTokensToSwap : contractTokenBalance;
                swapAndLiquifyAmount = contractTokenBalance.mul(liquidityFee).div(totalBuyFee);
                swapAndLiquify(swapAndLiquifyAmount);
            }

            uint256 remainingBalance = contractTokenBalance.sub(swapAndLiquifyAmount);
            swapAndSendDividends(remainingBalance);
            swapping = false;
        }
        amount = takeFee(from, to, amount);

        process(PROCESS_DIVIDEND_GAS_AMOUNT);

        return amount;
    }

    function process(uint256 gasAmount) public {
        gasAmount = gasAmount == 0 ? PROCESS_DIVIDEND_GAS_AMOUNT : gasAmount;
        try dividendTracker.process(PROCESS_DIVIDEND_GAS_AMOUNT) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, PROCESS_DIVIDEND_GAS_AMOUNT, tx.origin);
        } catch {}
    }

//    function isSell(address to) internal view returns (bool) {
//        return swapPairs[to];
//    }

    function takeFee(address from, address to, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = amount.mul(getTotalFee(swapPairs[to])).div(feeDenominator);

        super._transfer(from, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function getTotalFee(bool selling) public view returns (uint256) {


        if (block.number <= launchedAt+1) {return feeDenominator.sub(1);}
        return selling ? totalSellFee : totalBuyFee;
    }

    // todo: not used
    function shouldTakeFee(address from, address to) internal view returns (bool){
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !launched()) return false;
        if(swapPairs[from] || swapPairs[to]) return true;
        return feesOnNormalTransfers;
    }

    // todo: come back to this for multiplied fees
    function getMultipliedFee() public view returns (uint256) {
        uint totalFee = totalSellFee;
//        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
//        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
//        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        return totalFee;
    }

    /// @dev gets the balance including any staking bonus
    function getBalance(address account) public view returns (uint256) {
        return stakingEnabled ? balanceOf(account).mul(stakingBonus[account].add(100)).div(100) : balanceOf(account);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 amountToEth = tokens.div(2);
        uint256 amountToLiquidity = tokens.sub(amountToEth);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(amountToEth);
        uint256 ethAmount = address(this).balance.sub(initialBalance);
        addLiquidity(amountToLiquidity, ethAmount);
        emit SwapAndLiquify(amountToEth, ethAmount, amountToLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapTokensForBusd(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = BUSD;

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setUserRewardToken(address token) public {
        require(balanceOf(msg.sender) > 0, "Pazzive: User has no pazzive");
        require(token != address(this), "Can not set reward token for pazzive contract");

        dividendTracker.setUserRewardToken(msg.sender, token);
        emit UpdatePayoutToken(msg.sender, token);
    }

    function getUserRewardToken(address account) public view returns (address) {
        return dividendTracker.getUserRewardToken(account);
    }

    function updateAllowTokens(address token, bool allow) public onlyOwner {
        require(token != address(this));

        dividendTracker.setAllowedToken(token, allow);
        emit UpdateAllowTokens(token, allow);
    }

    function getAllowTokens(address token) public view returns (bool) {
        return dividendTracker.getAllowTokens(token);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, autoLiquidityReceiver, block.timestamp);
    }

    function sendDividends(uint256 tokens) external onlyOwner {
        swapAndSendDividends(tokens);
    }

    function swapAndSendDividends(uint256 tokens) private {
         swapTokensForBusd(tokens);
//        swapTokensForEth(tokens);
        uint256 busdAmount = IERC20(BUSD).balanceOf(address(this));
        uint256 teamAmount = busdAmount.mul(teamFee).div(feeDenominator);
        uint256 dividends = busdAmount.sub(teamAmount);

//        (bool success,) = address(dividendTracker).call{value: dividends}("");
        bool success = IERC20(BUSD).transfer(address(dividendTracker), dividends);

        uint256 marketingShare = teamAmount.mul(4).div(10);
        uint256 devShare = teamAmount - marketingShare;
//        (bool successDev,) = address(devAddress).call{value: devShare}("");
//        (bool successMarketing,) = address(marketingAddress).call{value: marketingShare}("");
        bool successDev = IERC20(BUSD).transfer(address(devAddress), devShare);
        bool successMarketing = IERC20(BUSD).transfer(address(marketingAddress), marketingShare);

        if(success){
            dividendTracker.distributeBusdDividends(dividends);
        }

        emit SendDividends(tokens, busdAmount, success && successDev && successMarketing);
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
}

contract PazDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    uint256 public DECIMALS = 10 ** 9;

    uint256 public MIN_BALANCE_AUTO_DIVIDENDS = 10000000 * DECIMALS; // min balance for auto dividends
    uint256 public MIN_BALANCE_DIVIDENDS = 1000000 * DECIMALS; // min balance for dividends
    uint256 public MIN_DIVIDEND_DISTRIBUTION = 1 * (10 ** 18); // 1 BUSD before auto send
    uint256 public MIN_CLAIM_INTERVAL = 1 hours; // min time before next auto claim

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => bool) public excludedFromAutoClaim;
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

    Pazzive public paz;

    mapping(address => uint256) public userLastClaimTime;
    mapping(address => uint256) public userSwappedBusd;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(address indexed acount, uint256 value, bool indexed automatic);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);
    event SetAllowAutoReinvest(bool allow);
    event TokenRouterSet(address token, address router);
    event AllowedRouterSet(address router, bool allow);
    event AllowedTokenSet(address router, bool allow);

    constructor(address payable pazziveAddress, address routerAddress, address busdAddress)DividendPayingToken("PazDividendTracker", "PazDividendTracker", busdAddress){
        paz = Pazzive(pazziveAddress);
        router = ISwapRouter(routerAddress);
        allowCustomTokens = true;
        allowAutoReinvest = true;
    }

    function setMinBalanceAutoDividends(uint256 minBalanceAutoDividends) external onlyOwner {
        MIN_BALANCE_AUTO_DIVIDENDS = minBalanceAutoDividends;
    }

    function setMinBalanceDividends(uint256 minBalanceDividends) external onlyOwner {
        MIN_BALANCE_DIVIDENDS = minBalanceDividends;
    }

    function setMinDividendDistribution(uint256 minDividendDistribution) external onlyOwner {
        MIN_DIVIDEND_DISTRIBUTION = minDividendDistribution;
    }

    function setMinClaimInterval(uint256 minClaimInterval) external onlyOwner {
        MIN_CLAIM_INTERVAL = minClaimInterval;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "PazDividendTracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "PazDividendTracker: withdrawDividend disabled. Use the 'claim' function on the main Pazzive contract.");
    }

    function isExcludedFromAutoClaim(address account) external view returns (bool){
        return excludedFromAutoClaim[account];
    }

    function isExcludedFromDividends(address account) external view returns (bool){
        return excludedFromDividends[account];
    }

    function isReinvest(address account) external view onlyOwner returns (bool){
        return autoReinvest[account];
    }

    function setAllowCustomTokens(bool allow) external onlyOwner {
        require(allowCustomTokens != allow, "PazDividendTracker: already set");
        allowCustomTokens = allow;
        emit SetAllowCustomTokens(allow);
    }

    function setAllowAutoReinvest(bool allow) external onlyOwner {
        require(allowAutoReinvest != allow, "PazDividendTracker: already set");
        allowAutoReinvest = allow;
        emit SetAllowAutoReinvest(allow);
    }

//    function excludeFromDividends(address account) external onlyOwner {
//        require(!excludedFromDividends[account]);
//        excludedFromDividends[account] = true;
//
//        _setBalance(account, 0);
//        tokenHoldersMap.remove(account);
//
//        emit ExcludeFromDividends(account);
//    }

    function setExcludedFromDividends(address account, bool excluded) external onlyOwner {

        // require(account != address(this) && !paz.isSwapPair(account), "PazDividendTracker: can not change contract or lp contracts");
        require(excludedFromDividends[account] != excluded, "PazDividendTracker: already set");
        excludedFromDividends[account] = excluded;
        if(excluded){
            _setBalance(account, 0);
        }else{
            _setBalance(account, paz.getBalance(account));
        }
    }

    function setExcludedFromAutoClaim(address account, bool excluded) external onlyOwner {
        require(excludedFromAutoClaim[account] != excluded, "PazDividendTracker: already set");
        excludedFromAutoClaim[account] = excluded;
    }

    function setAutoReinvest(address account, bool shouldAutoReinvest) external onlyOwner {
        autoReinvest[account] = shouldAutoReinvest;
    }

    function setDividendsPaused(bool isPaused) external onlyOwner {
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

    function getAccount(address _account) public view returns (address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime){
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

        // todo: see if we can use this
        uint256 nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(MIN_CLAIM_INTERVAL) : 0;
    }

    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256){
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
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

            if (!excludedFromAutoClaim[account]) {
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

//    function _processAccount(address payable account, bool automatic) public onlyOwner returns (bool){
//        if (dividendsPaused) {
//            return false;
//        }
//
//        bool reinvest = autoReinvest[account];
//
//        if (automatic && reinvest && !allowAutoReinvest) {
//            return false;
//        }
//
//        uint256 amount = reinvest ? _reinvestDividendOfUser(account) : _withdrawDividendOfUser(account);
//
//        if (amount > 0) {
//            userLastClaimTime[account] = block.timestamp;
//            if (reinvest) {
//                emit DividendReinvested(account, amount, automatic);
//            } else {
//                emit Claim(account, amount, automatic);
//            }
//            return true;
//        }
//
//        return false;
//    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool){
        if (dividendsPaused) {
            return false;
        }

        bool reinvest = autoReinvest[account];

        if (automatic && reinvest && !allowAutoReinvest) {
            return false;
        }

        // auto send only every MIN_CLAIM_INTERVAL
        if(automatic && userLastClaimTime[account] + MIN_CLAIM_INTERVAL <= block.timestamp){
            return false;
        }

        // auto send only if more than 1 BUSD
        if(automatic && withdrawableDividendOf(account) < MIN_DIVIDEND_DISTRIBUTION){
            return false;
        }

        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            userLastClaimTime[account] = block.timestamp;
            if (reinvest) {
                emit DividendReinvested(account, amount, automatic);
            } else {
                emit Claim(account, amount, automatic);
            }
            return true;
        }

        return false;
    }

    function updateRouter(address newAddress) public onlyOwner {
        router = ISwapRouter(newAddress);
    }

    function setUserRewardToken(address account, address token) public onlyOwner {
        require(allowedTokens[token] || token == address(0), "PazDividendTracker: Token is not allowed");
        userRewardToken[account] = token;
    }

    function getUserRewardToken(address account) public view returns (address) {
        return userRewardToken[account];
    }

    function setAllowedToken(address token, bool allow) public onlyOwner {
        allowedTokens[token] = allow;
        emit AllowedTokenSet(token, allow);
    }

    function setAllowedRouter(address routerAddress, bool allow) public onlyOwner {
        allowedRouters[routerAddress] = allow;
        emit AllowedRouterSet(routerAddress, allow);
    }

    function setTokenRouter(address token, address routerAddress) public onlyOwner {
        require(allowedRouters[routerAddress], "Pazzive: router is not allowed");
        tokenRouter[token] = routerAddress;
        emit TokenRouterSet(token, routerAddress);
    }

    function getAllowTokens(address token) public view returns (bool) {
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

        uint[] memory swapReturnAmounts;
        // no slippage needed as there is high liquidity for BUSD/BNB liquidity and all our tokens have tax
        try rewardRouter.swapExactTokensForTokens(amount, 0, path, address(user), block.timestamp) returns(uint[] memory amounts){
            swapReturnAmounts = amounts;
            userSwappedBusd[user]+=amount;
            swapSuccess = true;
        }catch{swapSuccess = false;}

        // send busd
        if(!swapSuccess){
            amount = withdrawBusd(user, amount);
        }

        if(address(RewardToken) == address(paz)){
            // emit reinvest event
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

//    function _reinvestDividendOfUser(address account) private returns (uint256){
//        uint256 _withdrawableDividend = withdrawableDividendOf(account);
//        if (_withdrawableDividend > 0) {
//            bool success;
//
//            withdrawnDividends[account] = withdrawnDividends[account].add(_withdrawableDividend);
//
//            address[] memory path = new address[](2);
//            path[0] = router.WETH();
//            path[1] = address(paz);
//
//            uint256 prevBalance = paz.balanceOf(address(this));
//
//            // make the swap
//            try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : _withdrawableDividend}(0, path, address(this), block.timestamp){
//                uint256 received = paz.balanceOf(address(this)).sub(prevBalance);
//                if (received > 0) {
//                    success = true;
//                    paz.transfer(account, received);
//                } else {
//                    success = false;
//                }
//            } catch {
//                success = false;
//            }
//
//            if (!success) {
//                withdrawnDividends[account] = withdrawnDividends[account].sub(_withdrawableDividend);
//                return 0;
//            }
//
//            return _withdrawableDividend;
//        }
//
//        return 0;
//    }

//    function _withdrawDividendOfUser(address payable user) internal override returns (uint256){
//        uint256 amountToWithdraw = withdrawableDividendOf(user);
//
//        if(amountToWithdraw == 0){
//            return 0;
//        }
//
//        withdrawnDividends[user] = withdrawnDividends[user].add(amountToWithdraw);
//
//        address tokenAddress = userRewardToken[user];
//        bool success;
//
//        // if no tokenAddress assume bnb payout
//        // todo: this will be BUSD payout
//        if (!allowCustomTokens || tokenAddress == address(0) || !allowedTokens[tokenAddress]) {
//            success = IERC20(BUSD).transfer(user, amountToWithdraw);
////            (success,) = user.call{value : amountToWithdraw, gas : 3000}("");
//        } else {
//            //investor wants to be payed out in a custom token
//            address[] memory path = new address[](2);
//            path[0] = router.WETH();
//            path[1] = tokenAddress;
//
//            try
//            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToWithdraw}(0, path, user, block.timestamp)
//            {success = true;} catch {success = false;}
//        }
//
//        if (!success) {
//            withdrawnDividends[user] = withdrawnDividends[user].sub(amountToWithdraw);
//            return 0;
//        } else {
//            emit DividendWithdrawn(user, amountToWithdraw);
//        }
//
//        return amountToWithdraw;
//    }

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

//    function withdrawBusd(address user, uint256 amount) internal onlyOwner returns (uint256) {
//        bool success = IERC20(BUSD).transfer(user, amount);
//        if(!success){
//            amount = 0;
//        }
//        return amount;
//    }

    function withdrawBusd(address user, uint256 amount) internal onlyOwner returns (uint256) {
        try IERC20(BUSD).transfer(user, amount) returns (bool) {} catch{
            amount = 0;
        }
        return amount;
    }
}

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

