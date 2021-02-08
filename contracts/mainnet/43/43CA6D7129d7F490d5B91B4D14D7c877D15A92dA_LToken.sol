// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../interface/IERC20.sol";
import "../interface/ILToken.sol";
import "./ERC20.sol";
import "../math/UnsignedSafeMath.sol";

/**
 * @title Deri Protocol liquidity provider token implementation
 */
contract LToken is IERC20, ILToken, ERC20 {

    using UnsignedSafeMath for uint256;

    // Pool address this LToken associated with
    address private _pool;

    modifier _pool_() {
        require(msg.sender == _pool, "LToken: called by non-associative pool, probably the original pool has been migrated");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token
     */
    constructor(string memory name_, string memory symbol_, address pool_) ERC20(name_, symbol_) {
        require(pool_ != address(0), "LToken: construct with 0 address pool");
        _pool = pool_;
    }

    /**
     * @dev See {ILToken}.{setPool}
     */
    function setPool(address newPool) public override {
        require(newPool != address(0), "LToken: setPool to 0 address");
        require(msg.sender == _pool, "LToken: setPool caller is not current pool");
        _pool = newPool;
    }

    /**
     * @dev See {ILToken}.{pool}
     */
    function pool() public view override returns (address) {
        return _pool;
    }

    /**
     * @dev See {ILToken}.{mint}
     */
    function mint(address account, uint256 amount) public override _pool_ {
        require(account != address(0), "LToken: mint to 0 address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {ILToken}.{burn}
     */
    function burn(address account, uint256 amount) public override _pool_ {
        require(account != address(0), "LToken: burn from 0 address");
        require(_balances[account] >= amount, "LToken: burn amount exceeds balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() external view returns (string memory);

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC20.sol";

/**
 * @title Deri Protocol liquidity provider token interface
 */
interface ILToken is IERC20 {

    /**
     * @dev Set the pool address of this LToken
     * pool is the only controller of this contract
     * can only be called by current pool
     */
    function setPool(address newPool) external;

    /**
     * @dev Returns address of pool
     */
    function pool() external view returns (address);

    /**
     * @dev Mint LToken to `account` of `amount`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burn `amount` LToken of `account`
     *
     * Can only be called by pool
     * `account` cannot be zero address
     * `account` must owns at least `amount` LToken
     */
    function burn(address account, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interface/IERC20.sol";
import "../math/UnsignedSafeMath.sol";

/**
 * @title ERC20 Implementation
 */
contract ERC20 is IERC20 {

    using UnsignedSafeMath for uint256;

    string _name;
    string _symbol;
    uint8 _decimals = 18;
    uint256 _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC20}.{name}
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC20}.{symbol}
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20}.{decimals}
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20}.{totalSupply}
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20}.{balanceOf}
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20}.{allowance}
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20}.{approve}
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "ERC20: approve to 0 address");
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20}.{transfer}
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to 0 address");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20}.{transferFrom}
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transferFrom to 0 address");
        if (_allowances[from][msg.sender] != uint256(-1)) {
            require(_allowances[from][msg.sender] >= amount, "ERC20: transferFrom not approved");
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`.
     * Emits an {Approval} event.
     *
     * Parameters check should be carried out before calling this function.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `from` to `to`.
     * Emits a {Transfer} event.
     *
     * Parameters check should be carried out before calling this function.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Unsigned safe math
 */
library UnsignedSafeMath {

    /**
     * @dev Addition of unsigned integers, counterpart to `+`
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "UnsignedSafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Subtraction of unsigned integers, counterpart to `-`
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "UnsignedSafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Multiplication of unsigned integers, counterpart to `*`
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero,
        // but the benefit is lost if 'b' is also tested
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "UnsignedSafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Division of unsigned integers, counterpart to `/`
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Modulo of unsigned integers, counterpart to `%`
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "UnsignedSafeMath: modulo by zero");
        uint256 c = a % b;
        return c;
    }

}