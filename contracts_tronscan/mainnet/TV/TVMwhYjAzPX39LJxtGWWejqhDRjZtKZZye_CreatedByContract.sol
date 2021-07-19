//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SourceUnit: DividendPayingToken.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./Ownable.sol";

contract DividendPayingToken is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );

    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );

    constructor(string memory _name, string memory _symbol, uint8 _desimals) public ERC20(_name, _symbol, _desimals) {
    }

    function distributeDividends(uint256 amount) external onlyOwner {
        if (totalSupply() > 0 && amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount);
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function withdrawDividend() public virtual {
        _withdrawDividendOfUser(msg.sender);
    }

    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            ERC20(owner()).transfer(user, _withdrawableDividend);
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns(uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);
        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

//SourceUnit: ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

//SourceUnit: IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

//SourceUnit: Ownable.sol

pragma solidity ^0.6.2;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

//SourceUnit: SafeMathInt.sol

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.6.2;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
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

//SourceUnit: SafeMathUint.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

//SourceUnit: WMBT.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./DividendPayingToken.sol";

contract WMBTToken is ERC20, Ownable {
    using SafeMath for uint256;

    WMBTDividendTracker public dividendTracker;

    uint256 public totalFees = 28;
    uint256 public burnPct = 60;
    address private _team;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    constructor(address owner, address team) public ERC20("WMBT", "WMBT", 6) {
        _team = team;
        dividendTracker = new WMBTDividendTracker();

        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(_team, true);

        _mint(_team, 21 * 1e7 * (10 ** uint256(decimals())));

        transferOwnership(owner);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "WMBT: The dividend tracker already has that address");
        WMBTDividendTracker newDividendTracker = WMBTDividendTracker(newAddress);
        require(newDividendTracker.owner() == address(this), "WMBT: The new dividend tracker must be owned by the WMBT token contract");
        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
        excludeFromFees(address(dividendTracker), true);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "WMBT: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function includeFromDividends(address account, bool included) public onlyOwner {
        dividendTracker.includeFromDividends(account, included, balanceOf(account));
    }

    function includeMultipleAccountsFromDividends(address[] calldata accounts, bool included) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            dividendTracker.includeFromDividends(accounts[i], included, balanceOf(accounts[i]));
        }
    }

    function setTaxFeePercent(uint256 newTotalFees, uint256 newBurnPct) public onlyOwner {
        totalFees = newTotalFees;
        burnPct = newBurnPct;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isIncludedFromDividends(address account) public view returns(bool) {
        return dividendTracker.includedFromDividends(account);
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
    external view returns (
        address,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccount(account);
    }

    function claim() external {
        dividendTracker.processAccount(msg.sender, false);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        // bool freeFee = _isExcludedFromFees[from] || _isExcludedFromFees[to];
        bool freeFee = _isExcludedFromFees[from] || to == address(this);

        if(!freeFee && totalFees > 0) {
            uint256 fees = amount.mul(totalFees).div(100);
            amount = amount.sub(fees);
            uint256 burns = fees.mul(burnPct).div(100);
            super._burn(from, burns);
            super._transfer(from, address(dividendTracker), fees.sub(burns));
            dividendTracker.distributeDividends(fees.sub(burns));
        }

        super._transfer(from, to, amount);

    try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
    try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }
}

contract WMBT is WMBTToken {
    using SafeMath for uint256;

    mapping (address => mapping (uint256 => uint256)) private _products;
    mapping (address => mapping (uint256 => uint256)) private _nodes;
    mapping (address => uint256) private _totals;
    mapping (address => uint256) private _unfreezes;
    mapping (uint256 => uint256) private _totalProducts;
    mapping (uint256 => uint256) private _totalNodes;
    uint256 private _totalUnfreezes;
    uint256 public minAmount = 0;
    IERC20 public token = IERC20(address(this));

    event Active(address addr);
    event BuyProduct(address indexed user, uint256 amount, uint256 prod_id);
    event BackProduct(address indexed user, uint256 amount, uint256 prod_id);
    event WithdrawProduct(address indexed user, uint256 amount);
    event BuyNode(address indexed user, uint256 amount, uint256 node_id);
    event VBuyNode(address indexed user, uint256 amount, uint256 node_id);
    event BackNode(address indexed user, uint256 amount, uint256 node_id);
    event WithdrawNode(address indexed user, uint256 amount, uint256 node_id);
    event Freeze(address indexed user, uint256 amount);
    event Unfreeze(address[] indexed users, uint256[] amounts);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address owner, address team) public WMBTToken(owner, team) {
    }

    modifier updateIncluded(address account) {
        _;
        dividendTracker.includeFromDividends(account, _totals[account] > minAmount, balanceOf(account));
    }

    function changeMinAmount(uint256 amount) public onlyOwner{
        minAmount = amount;
    }

    function active(address addr) public {
        emit Active(addr);
    }

    function buyProduct(uint256 amount, uint256 prod_id) public updateIncluded(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _products[msg.sender][prod_id] = _products[msg.sender][prod_id].add(amount);
        _totals[msg.sender] = _totals[msg.sender].add(amount);
        _totalProducts[prod_id] = _totalProducts[prod_id].add(amount);
        token.transferFrom(msg.sender, address(this), amount);
        emit BuyProduct(msg.sender, amount, prod_id);
    }

    function backProduct(address addr, uint256 amount, uint256 prod_id) public onlyOwner updateIncluded(addr) {
        _products[addr][prod_id] = _products[addr][prod_id].sub(amount);
        _totals[addr] = _totals[addr].sub(amount);
        _totalProducts[prod_id] = _totalProducts[prod_id].sub(amount);
        token.transfer(addr, amount);
        emit BackProduct(addr, amount, prod_id);
    }

    function withdrawProduct(uint256 amount) public updateIncluded(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _products[msg.sender][0] = _products[msg.sender][0].sub(amount);
        _totals[msg.sender] = _totals[msg.sender].sub(amount);
        _totalProducts[0] = _totalProducts[0].sub(amount);
        token.transfer(msg.sender, amount);
        emit WithdrawProduct(msg.sender, amount);
    }

    function buyNode(uint256 amount, uint256 node_id) public updateIncluded(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(_nodes[msg.sender][node_id] == 0, "Already be node");
        token.transferFrom(msg.sender, address(this), amount);
        _nodes[msg.sender][node_id] = amount;
        _totals[msg.sender] = _totals[msg.sender].add(amount);
        _totalNodes[node_id] = _totalNodes[node_id].add(amount);
        emit BuyNode(msg.sender, amount, node_id);
    }

    function vBuyNode(address addr, uint256 amount, uint256 node_id) public onlyOwner updateIncluded(addr) {
        require(amount > 0, "Cannot stake 0");
        require(_nodes[addr][node_id] == 0, "Already be node");
        _nodes[addr][node_id] = amount;
        _totals[addr] = _totals[addr].add(amount);
        _totalNodes[node_id] = _totalNodes[node_id].add(amount);
        emit VBuyNode(addr, amount, node_id);
    }

    function backNode(address addr, uint256 node_id) public onlyOwner updateIncluded(addr) {
        uint256 amount = _nodes[addr][node_id];
        require(amount > 0, "Not node");
        _nodes[addr][node_id] = 0;
        _totals[addr] = _totals[addr].sub(amount);
        _totalNodes[node_id] = _totalNodes[node_id].sub(amount);
        token.transfer(addr, amount);
        emit BackNode(addr, amount, node_id);
    }

    function withdrawNode(uint256 node_id) public updateIncluded(msg.sender) {
        uint256 amount = _nodes[msg.sender][node_id];
        require(amount > 0, "Not node");
        _nodes[msg.sender][node_id] = 0;
        _totals[msg.sender] = _totals[msg.sender].sub(amount);
        _totalNodes[node_id] = _totalNodes[node_id].sub(amount);
        token.transfer(msg.sender, amount);
        emit WithdrawNode(msg.sender, amount, node_id);
    }

    function balanceOfProduct(address account,uint256 prod_id) public view returns (uint256) {
        return _products[account][prod_id];
    }

    function balanceOfNode(address account,uint256 node_id) public view returns (uint256) {
        return _nodes[account][node_id];
    }

    function balanceOfTotal(address account) public view returns (uint256) {
        return _totals[account];
    }

    function balanceOfUnfreeze(address account) public view returns (uint256) {
        return _unfreezes[account];
    }

    function totalProduct(uint256 prod_id) public view returns (uint256) {
        return _totalProducts[prod_id];
    }

    function totalNode(uint256 node_id) public view returns (uint256) {
        return _totalNodes[node_id];
    }

    function totalUnfreeze() public view returns (uint256) {
        return _totalUnfreezes;
    }

    function freeze(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        emit Freeze(msg.sender, amount);
    }

    function unfreeze(address[] memory addrs, uint256[] memory amounts) public onlyOwner {
        for(uint i = 0;i<addrs.length;i++){
            _unfreezes[addrs[i]] = _unfreezes[addrs[i]].add(amounts[i]);
            _totalUnfreezes = _totalUnfreezes.add(amounts[i]);
        }
        emit Unfreeze(addrs, amounts);
    }

    function withdraw(uint256 amount) public {
        if(amount == 0) amount = _unfreezes[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        _unfreezes[msg.sender] = _unfreezes[msg.sender].sub(amount);
        _totalUnfreezes = _totalUnfreezes.sub(amount);
        token.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}

contract WMBTDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    mapping (address => bool) public includedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    event IncludeFromDividends(address indexed account, bool isIncluded);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("WMBT_Dividend_Tracker", "WMBT_Dividend_Tracker", 6) {
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "WMBT_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "WMBT_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main WMBT contract.");
    }

    function includeFromDividends(address account, bool included, uint256 amount) external onlyOwner {
        if(includedFromDividends[account] == included) return;
        if(included){
            includedFromDividends[account] = true;
            _setBalance(account, amount);
        }else{
            includedFromDividends[account] = false;
            _setBalance(account, 0);
        }
        emit IncludeFromDividends(account, included);
    }

    function getAccount(address _account)
    public view returns (
        address account,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime) {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
        if(!includedFromDividends[account]) {
            return;
        }

        if(newBalance > 0) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function processAccount(address account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}