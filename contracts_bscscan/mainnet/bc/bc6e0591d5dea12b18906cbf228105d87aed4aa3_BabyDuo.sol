/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    address private _operator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        _operator = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator() == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the operator");
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
    function transferOwnership(address newOwner) public virtual onlyOperator {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function transferOperator(address newOperator) public virtual onlyOperator {
        require(newOperator != address(0), "Ownable: new operator is the zero address");
        _operator = newOperator;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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
library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2**255 && b == -1) && (b > 0));

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface AdditionalTypes {
    struct Tokens {
        uint256 BNB;
        uint256 WBTC;
    }

    struct TokensInt {
        int256 BNB;
        int256 WBTC;
    }

}

interface IDividendPayingToken is AdditionalTypes {
    function dividendOf(address _owner) external view returns(Tokens calldata);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount,
        string currency
    );
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount,
        string currency
    );
}

interface IDividendPayingTokenOptional is AdditionalTypes {
    function withdrawableDividendOf(address _owner) external view returns(Tokens memory);
    function withdrawnDividendOf(address _owner) external view returns(Tokens memory);
    function accumulativeDividendOf(address _owner) external view returns(Tokens memory);
}

contract DividendPayingToken is ERC20, Ownable, IDividendPayingToken, IDividendPayingTokenOptional {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address WBTC = 0xA01b9cAFE2230093fbf0000B43701E03717F77cE;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;


    uint256 constant internal magnitude = 2**128;

    Tokens internal magnifiedDividendPerShare;
    uint256 internal lastAmount;

    mapping(address => TokensInt) internal magnifiedDividendCorrections;
    mapping(address => Tokens) internal withdrawnDividends;

    Tokens private _totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

    }

    receive() external payable {}

    function distributeDividends() public override payable {}

    function totalDividendsDistributed() public view returns(Tokens memory) {
        return _totalDividendsDistributed;
    }

    function distributeDividendsWBTC(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare.WBTC = magnifiedDividendPerShare.WBTC.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount, "WBTC");

            _totalDividendsDistributed.WBTC = _totalDividendsDistributed.WBTC.add(amount);
        }
    }

    function distributeDividendsBNB(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare.BNB = magnifiedDividendPerShare.BNB.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount, "BNB");

            _totalDividendsDistributed.BNB = _totalDividendsDistributed.BNB.add(amount);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (Tokens memory withdrawable) {
        withdrawable = withdrawableDividendOf(user);
        if (withdrawable.BNB > 0 ) {
            withdrawnDividends[user].BNB = withdrawnDividends[user].BNB.add(withdrawable.BNB);
            emit DividendWithdrawn(user, withdrawable.BNB, "BNB");

            bool success = IERC20(WBNB).transfer(user, withdrawable.BNB);
            if(!success) {
                withdrawnDividends[user].BNB = withdrawnDividends[user].BNB.sub(withdrawable.BNB);
                withdrawable.BNB = 0;
            }
        }


        if (withdrawable.WBTC > 0 ) {
            withdrawnDividends[user].WBTC = withdrawnDividends[user].WBTC.add(withdrawable.WBTC);
            emit DividendWithdrawn(user, withdrawable.WBTC, "WBTC");

            bool success = IERC20(WBTC).transfer(user, withdrawable.WBTC);
            if(!success) {
                withdrawnDividends[user].WBTC = withdrawnDividends[user].WBTC.sub(withdrawable.WBTC);
                withdrawable.WBTC = 0;
            }
        }
    }


    function dividendOf(address _owner) public view override returns(Tokens memory) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns(Tokens memory acc) {
        acc = accumulativeDividendOf(_owner);
        acc.BNB -= withdrawnDividends[_owner].BNB;
        acc.WBTC -= withdrawnDividends[_owner].WBTC;
    }

    function withdrawnDividendOf(address _owner) public view override returns(Tokens memory) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns(Tokens memory) {
        Tokens memory acc;
        acc.BNB = magnifiedDividendPerShare.BNB.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner].BNB).toUint256Safe() / magnitude;
        acc.WBTC = magnifiedDividendPerShare.WBTC.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner].WBTC).toUint256Safe() / magnitude;
        return acc;
    }

    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);
        require(from != address(0));
        require(to != address(0));
        require(value != 0);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account].BNB = magnifiedDividendCorrections[account].BNB
        .sub((magnifiedDividendPerShare.BNB.mul(value)).toInt256Safe() );
        magnifiedDividendCorrections[account].WBTC = magnifiedDividendCorrections[account].WBTC
        .sub((magnifiedDividendPerShare.WBTC.mul(value)).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account].BNB = magnifiedDividendCorrections[account].BNB
        .add((magnifiedDividendPerShare.BNB.mul(value)).toInt256Safe() );
        magnifiedDividendCorrections[account].WBTC = magnifiedDividendCorrections[account].WBTC
        .add((magnifiedDividendPerShare.WBTC.mul(value)).toInt256Safe() );
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

contract RewardDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(address token) DividendPayingToken("BabyDuoReward_Dividend_Tracker", "BabyDuoReward_Dividend_Tracker") {
        claimWait = 1800;
        minimumTokenBalanceForDividends = 10000 * (10**9); //must hold 10000+ tokens
        transferOwnership(token);
    }

    function setMinimumTokenBalanceForDividends(uint256 newValue) external onlyOperator {
        minimumTokenBalanceForDividends = newValue;
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "BabyDuoReward_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "BabyDuoReward_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BabyDuoReward contract.");
    }

    function excludeFromDividends(address account) external onlyOperator {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOperator {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "BabyDuoReward_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BabyDuoReward_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }


    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        Tokens memory withdrawableDividends,
        Tokens memory totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
        lastClaimTime.add(claimWait) :
        0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
        nextClaimTime.sub(block.timestamp) :
        0;
    }

    function getAccountAtIndex(uint256 index)
    public view returns (
        address,
        int256,
        int256,
        Tokens memory,
        Tokens memory,
        uint256,
        uint256,
        uint256) {
        if(index >= tokenHoldersMap.size()) {
            Tokens memory empty;
            return (0x0000000000000000000000000000000000000000, -1, -1, empty, empty, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        Tokens memory w = _withdrawDividendOfUser(account);
        bool res = true;

        if(w.BNB > 0) {
            emit Claim(account, w.BNB, automatic);
        } else {
            res = false;
        }
        if(w.WBTC > 0) {
            emit Claim(account, w.WBTC, automatic);
        } else {
            res = false;
        }

        if (res) {
            lastClaimTimes[account] = block.timestamp;
        }

        return res;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract BabyDuo is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address WBTC = 0xA01b9cAFE2230093fbf0000B43701E03717F77cE;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;

    RewardDividendTracker public dividendTracker;

    uint8 _decimals = 9;
    uint256 public maxBuyTranscationAmount = 1000000000000000 * (10**uint256(_decimals));
    uint256 public maxSellTransactionAmount = 1000000000000000 * (10**uint256(_decimals));
    uint256 public maxWalletToken = 1000000000000000 * (10**uint256(_decimals)); // 100% of total supply
    uint256 public swapTokensAtAmount = 2000000000 * (10**uint256(_decimals));
    bool public enableSwapAndLiquify = false;

    uint256 public dividendRewardsFee = 1600;
    uint256 public wbnbFee = 800;
    uint256 public wbtcFee = 800;
    uint256 public accumulatedForWBTC;
    uint256 public ethMultiplier = 100;
    uint256 public marketingFee = 300;
    uint256 public liquidityFee = 100;
    uint256 public totalFees = wbnbFee + wbtcFee + marketingFee + liquidityFee;
    uint256 public denom = 10000;
    address public marketingWallet = 0xffaE71185B7996AC3799346E3a3D13c4aEDf8b07;


    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedFromMaxTX;
    mapping (address => bool) public _isExcludedFromMaxHold;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateMarketingAddress(address newAddress, address oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxTX(address indexed account, bool isExcluded);
    event ExcludeFromMaxHold(address indexed account, bool isExcluded);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 amount,
        string currency
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("BabyDuplo", "BABYDUPLO") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;


        // exclude from receiving dividends



        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(_uniswapV2Router), true);

        _isExcludedFromMaxHold[uniswapV2Pair] = true;
        _isExcludedFromMaxHold[owner()] = true;
        _isExcludedFromMaxHold[address(this)] = true;

        _isExcludedFromMaxTX[owner()] = true;
        _isExcludedFromMaxTX[address(this)] = true;


        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000000000 * (10**uint256(_decimals)));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    receive() external payable {

    }

    function setSwapTokensAtAmount(uint256 value) external onlyOwner {
        swapTokensAtAmount = value * (10**uint256(_decimals));
    }

    function setEnableSwapAndLiquify(bool value) external onlyOwner {
        enableSwapAndLiquify = value;
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        emit UpdateMarketingAddress(_marketingWallet, marketingWallet);
        marketingWallet = _marketingWallet;
    }

    function setMaxBuyTransaction(uint256 maxTxn) external onlyOwner {
        maxBuyTranscationAmount = maxTxn * (10**uint256(_decimals));
    }

    function setMaxSellTransaction(uint256 maxTxn) external onlyOwner {
        maxSellTransactionAmount = maxTxn * (10**uint256(_decimals));
    }

    function setMaxWalletToken(uint256 maxToken) external onlyOwner {
        maxWalletToken = maxToken * (10**uint256(_decimals));
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "The dividend tracker already has that address");

        RewardDividendTracker newDividendTracker = RewardDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "The new dividend tracker must be owned by the token contract");


        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(uniswapV2Pair);
        newDividendTracker.excludeFromDividends(deadAddress);
        newDividendTracker.excludeFromDividends(address(0));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateDividendRewardFee(uint256 wbtc, uint256 wbnb) public onlyOwner {
        require(wbnb + wbtc <= 3000, "Dividend reward tax must be <= 3000");
        require(wbtc >= 4 * ethMultiplier, "WBTC fee must be >= 400");

        wbnbFee = wbnb;
        wbtcFee = wbtc;
    }

    function updateMarketingFee(uint8 newFee) public onlyOwner {
        require(newFee <= 30, "Marketing tax must be less than 30");
        marketingFee = newFee;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromMaxHold(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxHold[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromMaxHold[account] = excluded;

        emit ExcludeFromMaxHold(account, excluded);
    }

    function excludeFromMaxTX(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxTX[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromMaxTX[account] = excluded;

        emit ExcludeFromMaxTX(account, excluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (AdditionalTypes.Tokens memory) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(AdditionalTypes.Tokens memory) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        AdditionalTypes.Tokens memory,
        AdditionalTypes.Tokens memory,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        AdditionalTypes.Tokens memory,
        AdditionalTypes.Tokens memory,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!_isExcludedFromMaxHold[to]) {
            require(
                balanceOf(to) + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        }

        if (!_isExcludedFromMaxTX[to] && from == uniswapV2Pair) {
            require(
                amount <= maxBuyTranscationAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        } else if (!_isExcludedFromMaxTX[from] && to == uniswapV2Pair) {
            require(
                amount <= maxSellTransactionAmount,
                "Sell transfer amount exceeds the maxSellTransactionAmount."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (from != uniswapV2Pair && enableSwapAndLiquify && contractTokenBalance >= swapTokensAtAmount && !swapping) {
            swapping = true;
            uint256 feeWithoutWBTC = contractTokenBalance - accumulatedForWBTC;
            uint256 onePart = feeWithoutWBTC / (totalFees - wbtcFee);
            uint256 halfOfLiquidity = onePart.mul(liquidityFee).div(2);

            uint256 swapToBNB = contractTokenBalance - halfOfLiquidity; // all without half of liquidity part

            swapTokensForBNB(swapToBNB);
            uint256 contractBNBBalance = address(this).balance;
            uint256 bnbForWBTC = contractBNBBalance * accumulatedForWBTC / swapToBNB;
            uint256 bnbWithoutWBTC = contractBNBBalance - bnbForWBTC;
            onePart = bnbWithoutWBTC / (totalFees - wbtcFee - (liquidityFee / 2));
            uint256 bnbForLiquidity = onePart * liquidityFee / 2;
            uint256 bnbForMarketing = onePart * marketingFee;
            uint256 bnbForDividend = bnbWithoutWBTC - bnbForMarketing - bnbForLiquidity;

            if (bnbForMarketing > 0) {
                transferToMarketing(bnbForMarketing);
            }

            if (bnbForLiquidity > 0) {
                addLiquidity(halfOfLiquidity, bnbForLiquidity);
                emit SwapAndLiquify(halfOfLiquidity, bnbForLiquidity, halfOfLiquidity);
            }

            if (bnbForDividend > 0) {
                sendDividendsInBNB(bnbForDividend);
            }

            if (bnbForWBTC > 0 ) {
                swapAndSendDividends(bnbForWBTC, WBTC);
                accumulatedForWBTC = 0;
            }

            swapping = false;
        }

        bool takeFee = !swapping && !_isExcludedFromFees[from];

        if(takeFee) {
            uint256 minusWBTCFee;

            if (from == uniswapV2Pair) {
                uint256 ethAmount = amountInETH(amount);
                if (ethAmount > 4) {
                    ethAmount = 4;
                }

                minusWBTCFee = ethAmount * ethMultiplier;
            }

            uint256 fees = amount * (totalFees - minusWBTCFee) / denom;

            accumulatedForWBTC += fees * (wbtcFee - minusWBTCFee) / (totalFees - minusWBTCFee);

            amount -= fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping && from != uniswapV2Pair) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } catch {}
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function swapBNBForDividendTokens(uint256 amount, address recipient, address dividendToken) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = dividendToken;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            recipient,
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function swapAndSendDividends(uint256 bnbAmount, address dividendToken) private {
        swapBNBForDividendTokens(bnbAmount, address(this), dividendToken);
        uint256 dividends = IERC20(dividendToken).balanceOf(address(this));
        bool success = IERC20(dividendToken).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeDividendsWBTC(dividends);
            emit SendDividends(dividends, "WBTC");
        }
    }

    function sendDividendsInBNB(uint256 bnbAmount) private {
        (bool success,) = address(dividendTracker).call{value: bnbAmount}("");

        if (success) {
            dividendTracker.distributeDividendsBNB(bnbAmount);
            emit SendDividends(bnbAmount, "BNB");
        }
    }

    function transferToMarketing(uint256 amount) private {
        payable(marketingWallet).transfer(amount);
    }

    function amountInETH(uint256 amount) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uint256[] memory res = uniswapV2Router.getAmountsOut(amount, path);
        return res[1];
    }

    function updateEthMultiplier(uint256 _ethMultiplier) external onlyOwner {
        require(wbtcFee >= 4 * _ethMultiplier, "Discount cant be greater than WBTC fee");
        ethMultiplier = _ethMultiplier;
    }
}