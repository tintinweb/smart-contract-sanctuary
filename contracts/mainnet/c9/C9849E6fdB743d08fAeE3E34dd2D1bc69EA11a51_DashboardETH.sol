// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../cvaults/eth/CVaultETHLP.sol";
import "../cvaults/CVaultRelayer.sol";
import {PoolConstant} from "../library/PoolConstant.sol";


contract DashboardETH is OwnableUpgradeable {
    using SafeMath for uint;

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory private constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    AggregatorV3Interface private constant ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /* ========== STATE VARIABLES ========== */

    address payable public cvaultAddress;
    mapping(address => address) private pairAddresses;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== Restricted Operation ========== */

    function setCVaultAddress(address payable _cvaultAddress) external onlyOwner {
        cvaultAddress = _cvaultAddress;
    }

    function setPairAddress(address asset, address pair) external onlyOwner {
        pairAddresses[asset] = pair;
    }

    /* ========== Value Calculation ========== */

    function priceOfETH() view public returns (uint) {
        (, int price, , ,) = ethPriceFeed.latestRoundData();
        return uint(price).mul(1e10);
    }

    function pricesInUSD(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            (, uint valueInUSD) = valueOfAsset(assets[i], 1e18);
            prices[i] = valueInUSD;
        }
        return prices;
    }

    function valueOfAsset(address asset, uint amount) public view returns (uint valueInETH, uint valueInUSD) {
        if (asset == address(0) || asset == address(WETH)) {
            valueInETH = amount;
            valueInUSD = amount.mul(priceOfETH()).div(1e18);
        } else if (keccak256(abi.encodePacked(IUniswapV2Pair(asset).symbol())) == keccak256("UNI-V2")) {
            if (IUniswapV2Pair(asset).token0() == address(WETH) || IUniswapV2Pair(asset).token1() == address(WETH)) {
                valueInETH = amount.mul(WETH.balanceOf(address(asset))).mul(2).div(IUniswapV2Pair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            } else {
                uint balanceToken0 = IERC20(IUniswapV2Pair(asset).token0()).balanceOf(asset);
                (uint token0PriceInETH,) = valueOfAsset(IUniswapV2Pair(asset).token0(), 1e18);

                valueInETH = amount.mul(balanceToken0).mul(2).mul(token0PriceInETH).div(1e18).div(IUniswapV2Pair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            }
        } else {
            address pairAddress = pairAddresses[asset];
            if (pairAddress == address(0)) {
                pairAddress = address(WETH);
            }

            uint decimalModifier = 0;
            uint decimals = uint(ERC20(asset).decimals());
            if (decimals < 18) {
                decimalModifier = 18 - decimals;
            }

            address pair = factory.getPair(asset, pairAddress);
            valueInETH = IERC20(pairAddress).balanceOf(pair).mul(amount).div(IERC20(asset).balanceOf(pair).mul(10 ** decimalModifier));
            if (pairAddress != address(WETH)) {
                (uint pairValueInETH,) = valueOfAsset(pairAddress, 1e18);
                valueInETH = valueInETH.mul(pairValueInETH).div(1e18);
            }
            valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
        }
    }

    /* ========== Collateral Calculation ========== */

    function collateralOfPool(address pool, address account) public view returns (uint collateralETH, uint collateralBSC, uint bnbDebt, uint leverage) {
        CVaultETHLPState.Account memory accountState = CVaultETHLP(cvaultAddress).accountOf(pool, account);
        collateralETH = accountState.collateral;
        collateralBSC = accountState.bscFlipBalance;
        bnbDebt = accountState.bscBNBDebt;
        leverage = accountState.leverage;
    }

    /* ========== TVL Calculation ========== */

    function tvlOfPool(address pool) public view returns (uint) {
        if (pool == address(0)) return 0;
        (, uint tvlInUSD) = valueOfAsset(pool, CVaultETHLP(cvaultAddress).totalCollateralOf(pool));
        return tvlInUSD;
    }

    /* ========== Pool Information ========== */

    function infoOfPool(address pool, address account) public view returns (PoolConstant.PoolInfoETH memory) {
        PoolConstant.PoolInfoETH memory poolInfo;
        if (pool == address(0)) {
            return poolInfo;
        }

        CVaultETHLP cvault = CVaultETHLP(cvaultAddress);
        CVaultETHLPState.Account memory accountState = cvault.accountOf(pool, account);

        (uint collateralETH, uint collateralBSC, uint bnbDebt, uint leverage) = collateralOfPool(pool, account);
        poolInfo.pool = pool;
        poolInfo.collateralETH = collateralETH;
        poolInfo.collateralBSC = collateralBSC;
        poolInfo.bnbDebt = bnbDebt;
        poolInfo.leverage = leverage;
        poolInfo.tvl = tvlOfPool(pool);
        poolInfo.updatedAt = accountState.updatedAt;
        poolInfo.depositedAt = accountState.depositedAt;
        poolInfo.feeDuration = cvault.WITHDRAWAL_FEE_PERIOD();
        poolInfo.feePercentage = cvault.WITHDRAWAL_FEE();
        return poolInfo;
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

import "../../GSN/Context.sol";
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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

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

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IUniswapV2Pair.sol";
import "../interface/ICVaultETHLP.sol";
import "../interface/ICVaultRelayer.sol";
import "../../zap/IZap.sol";
import "../../library/Whitelist.sol";
import "./CVaultETHLPState.sol";
import "./CVaultETHLPStorage.sol";


contract CVaultETHLP is ICVaultETHLP, CVaultETHLPStorage, Whitelist {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint8 private constant SIG_DEPOSIT = 10;
    uint8 private constant SIG_LEVERAGE = 20;
    uint8 private constant SIG_WITHDRAW = 30;
    uint8 private constant SIG_LIQUIDATE = 40;
    uint8 private constant SIG_EMERGENCY = 50;
    uint8 private constant SIG_CLEAR = 63;          // only owner can execute if state is idle but the BSC position remains.

    /* ========== STATE VARIABLES ========== */

    IZap public zap;
    address public treasury;

    uint public relayerCost;
    uint public minimumDepositValue;
    uint public liquidationCollateralRatio;

    /* ========== EVENTS ========== */

    // Relay Request Events
    event DepositRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, uint leverage);
    event UpdateLeverageRequested(address indexed lp, address indexed account, uint indexed eventId, uint leverage, uint collateral);
    event WithdrawRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount);
    event WithdrawAllRequested(address indexed lp, address indexed account, uint indexed eventId);
    event LiquidateRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, address liquidator);
    event EmergencyExitRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount);

    // Impossible Situation: only owner can execute if state is idle but the BSC position remains.
    event ClearBSCState(address indexed lp, address indexed account, uint indexed eventId);

    // Relay Response Events
    event NotifyDeposited(address indexed lp, address indexed account, uint indexed eventId, uint bscBNBDebtShare, uint bscFlipBalance);
    event NotifyUpdatedLeverage(address indexed lp, address indexed account, uint indexed eventId, uint bscBNBDebtShare, uint bscFlipBalance);
    event NotifyWithdrawnAll(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, uint ethProfit, uint ethLoss);
    event NotifyLiquidated(address indexed lp, address indexed account, uint indexed eventId, uint ethProfit, uint ethLoss, uint penaltyLPAmount, address liquidator);
    event NotifyResolvedEmergency(address indexed lp, address indexed account, uint indexed eventId);

    // User Events
    event CollateralAdded(address indexed lp, address indexed account, uint lpAmount);
    event CollateralRemoved(address indexed lp, address indexed account, uint lpAmount);
    event UnpaidProfitClaimed(address indexed account, uint ethValue);
    event LossRealized(address indexed lp, address indexed account, uint indexed eventId, uint soldLPAmount, uint ethValue);

    /* ========== MODIFIERS ========== */

    modifier onlyCVaultRelayer() {
        require(address(relayer) != address(0) && msg.sender == address(relayer), "CVaultETHLP: caller is not the relayer");
        _;
    }

    modifier canRemoveCollateral(address lp, address _account, uint amount) {
        Account memory account = accountOf(lp, msg.sender);
        uint ratio = relayer.collateralRatioOnETH(lp, account.collateral.sub(amount), bscFlipOf(lp), account.bscFlipBalance, account.bscBNBDebt);
        require(ratio >= COLLATERAL_RATIO_MIN, "CVaultETHLP: can withdraw only up to 180% of the collateral ratio");
        _;
    }

    modifier hasEnoughBalance(uint value) {
        require(address(this).balance >= value, "CVaultETHLP: not enough balance, please try after UTC 00:00");
        _;
    }

    modifier costs {
        uint txFee = relayerCost;
        require(msg.value >= txFee, "CVaultETHLP: Not enough ether provided");
        _;
        if (msg.value > txFee) {
            msg.sender.transfer(msg.value.sub(txFee));
        }
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __CVaultETHLPStorage_init();
        __Whitelist_init();

        relayerCost = 0.015 ether;
        minimumDepositValue = 100e18;
        liquidationCollateralRatio = 125e16;        // 125% == debt ratio 80%
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setZap(address newZap) external onlyOwner {
        zap = IZap(newZap);
    }

    function setPool(address lp, address bscFlip) external onlyOwner {
        _setPool(lp, bscFlip);
        IERC20(lp).safeApprove(address(zap), uint(- 1));
    }

    function recoverToken(address token, uint amount) external onlyOwner {
        require(bscFlipOf(token) == address(0), "CVaultETHLP: lp token can't be recovered");
        IERC20(token).safeTransfer(owner(), amount);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "CVaultETHLP: invalid treasury address");
        treasury = newTreasury;
    }

    function setRelayerCost(uint newValue) external onlyOwner {
        relayerCost = newValue;
    }

    function setMinimumDepositValue(uint newValue) external onlyOwner {
        require(newValue > 0, "CVaultETHLP: minimum deposit value is zero");
        minimumDepositValue = newValue;
    }

    function updateLiquidationCollateralRatio(uint newCollateralRatio) external onlyOwner {
        require(newCollateralRatio < COLLATERAL_RATIO_MIN, "CVaultETHLP: liquidation collateral ratio must be lower than COLLATERAL_RATIO_MIN");
        liquidationCollateralRatio = newCollateralRatio;
    }

    function clearBSCState(address lp, address _account) external onlyOwner {
        require(stateOf(lp, _account) == State.Idle, "CVaultETHLP: account should be idle state");

        uint eventId = relayer.requestRelayOnETH(lp, _account, SIG_CLEAR, 0, 0, 0);
        emit ClearBSCState(lp, _account, eventId);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function validateRequest(uint8 signature, address _lp, address _account, uint128 _leverage, uint _collateral) external override view returns (uint8 validation, uint112 nonce) {
        Account memory account = accountOf(_lp, _account);
        bool isValid = false;
        if (signature == SIG_DEPOSIT) {
            isValid =
            account.state == State.Depositing
            && account.collateral > 0
            && account.collateral == _collateral
            && account.leverage == _leverage
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_LEVERAGE) {
            isValid =
            account.state == State.UpdatingLeverage
            && account.collateral > 0
            && account.collateral == _collateral
            && account.leverage == _leverage
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_WITHDRAW) {
            isValid =
            account.state == State.Withdrawing
            && account.collateral > 0
            && account.leverage == 0
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_EMERGENCY) {
            isValid =
            account.state == State.EmergencyExited
            && account.collateral == 0
            && account.leverage == 0;
        }
        else if (signature == SIG_LIQUIDATE) {
            isValid =
            account.state == State.Liquidating
            && account.liquidator != address(0);
        }
        else if (signature == SIG_CLEAR) {
            isValid = account.state == State.Idle && account.collateral == 0;
        }

        validation = isValid ? uint8(1) : uint8(0);
        nonce = account.nonce;
    }

    function canLiquidate(address lp, address _account) public override view returns (bool) {
        Account memory account = accountOf(lp, _account);
        return account.state == State.Farming && collateralRatioOf(lp, _account) < liquidationCollateralRatio;
    }

    function collateralRatioOf(address lp, address _account) public view returns (uint) {
        Account memory account = accountOf(lp, _account);
        return relayer.collateralRatioOnETH(lp, account.collateral, bscFlipOf(lp), account.bscFlipBalance, account.bscBNBDebt);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(address lp, uint amount, uint128 leverage) external notPaused notPausedPool(lp) validLeverage(leverage) onlyWhitelisted payable costs {
        require(relayer.isUtilizable(lp, amount, leverage), "CVaultETHLP: not enough balance to loan in the bank");
        require(relayer.valueOfAsset(lp, amount) >= minimumDepositValue, "CVaultETHLP: less than minimum deposit");

        convertState(lp, msg.sender, State.Depositing);

        uint collateral = _addCollateral(lp, msg.sender, amount);
        setLeverage(lp, msg.sender, leverage);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_DEPOSIT, leverage, collateral, amount);
        emit DepositRequested(lp, msg.sender, eventId, amount, leverage);
    }

    function updateLeverage(address lp, uint128 leverage) external notPaused notPausedPool(lp) validLeverage(leverage) payable costs {
        convertState(lp, msg.sender, State.UpdatingLeverage);
        Account memory account = accountOf(lp, msg.sender);
        uint leverageDiff = Math.max(account.leverage, leverage).sub(Math.min(account.leverage, leverage));

        setLeverage(lp, msg.sender, leverage);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_LEVERAGE, leverage, account.collateral, account.collateral.mul(leverageDiff).div(UNIT));
        emit UpdateLeverageRequested(lp, msg.sender, eventId, leverage, accountOf(lp, msg.sender).collateral);
    }

    function withdraw(address lp, uint amount) external payable costs {
        convertState(lp, msg.sender, State.UpdatingLeverage);

        Account memory account = accountOf(lp, msg.sender);
        uint targetCollateral = account.collateral.sub(amount);
        uint leverage = uint(account.leverage).mul(targetCollateral).div(account.collateral);
        require(LEVERAGE_MIN <= leverage && leverage <= LEVERAGE_MAX, "CVaultETHLP: leverage range should be [10%-150%]");

        setLeverage(lp, msg.sender, uint128(leverage));
        setWithdrawalRequestAmount(lp, msg.sender, amount);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_LEVERAGE, uint128(leverage), account.collateral, amount);
        emit UpdateLeverageRequested(lp, msg.sender, eventId, leverage, accountOf(lp, msg.sender).collateral);
        emit WithdrawRequested(lp, msg.sender, eventId, amount);
    }

    function withdrawAll(address lp) external payable costs {
        convertState(lp, msg.sender, State.Withdrawing);
        setLeverage(lp, msg.sender, 0);

        Account memory account = accountOf(lp, msg.sender);
        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_WITHDRAW, account.leverage, account.collateral, account.collateral);
        emit WithdrawAllRequested(lp, msg.sender, eventId);
    }

    function claimUnpaidETH(uint value) external hasEnoughBalance(value) {
        decreaseUnpaidETHValue(msg.sender, value);
        payable(msg.sender).transfer(value);
        emit UnpaidProfitClaimed(msg.sender, value);
    }

    function emergencyExit(address lp) external {
        convertState(lp, msg.sender, State.EmergencyExited);
        setLeverage(lp, msg.sender, 0);

        Account memory account = accountOf(lp, msg.sender);
        _removeCollateral(lp, msg.sender, account.collateral);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_EMERGENCY, 0, account.collateral, account.collateral);
        emit EmergencyExitRequested(lp, msg.sender, eventId, account.collateral);
    }

    function addCollateral(address lp, uint amount) external onlyStateFarming(lp) {
        _addCollateral(lp, msg.sender, amount);
        emit CollateralAdded(lp, msg.sender, amount);
    }

    function removeCollateral(address lp, uint amount) external onlyStateFarming(lp) canRemoveCollateral(lp, msg.sender, amount) {
        _removeCollateral(lp, msg.sender, amount);
        emit CollateralRemoved(lp, msg.sender, amount);
    }

    function askLiquidation(address lp, address account) external payable costs {
        relayer.askLiquidationFromCVaultETH(lp, account, msg.sender);
    }

    function executeLiquidation(address lp, address _account, address _liquidator) external override onlyCVaultRelayer {
        if (!canLiquidate(lp, _account)) return;

        setLiquidator(lp, _account, _liquidator);
        convertState(lp, _account, State.Liquidating);

        Account memory account = accountOf(lp, _account);
        uint eventId = relayer.requestRelayOnETH(lp, _account, SIG_LIQUIDATE, account.leverage, account.collateral, account.collateral);
        emit LiquidateRequested(lp, _account, eventId, account.collateral, _liquidator);
    }

    /* ========== RELAYER FUNCTIONS ========== */

    function notifyDeposited(address lp, address _account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        _notifyDeposited(lp, _account, bscBNBDebt, bscFlipBalance);
        emit NotifyDeposited(lp, _account, eventId, bscBNBDebt, bscFlipBalance);
    }

    function notifyUpdatedLeverage(address lp, address _account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        _notifyDeposited(lp, _account, bscBNBDebt, bscFlipBalance);
        emit NotifyUpdatedLeverage(lp, _account, eventId, bscBNBDebt, bscFlipBalance);

        uint withdrawalRequestAmount = accountOf(lp, _account).withdrawalRequestAmount;
        if (withdrawalRequestAmount > 0) {
            setWithdrawalRequestAmount(lp, _account, 0);
            _removeCollateral(lp, _account, withdrawalRequestAmount);
            emit CollateralRemoved(lp, _account, withdrawalRequestAmount);
        }
    }

    function notifyWithdrawnAll(address lp, address _account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.Withdrawing, "CVaultETHLP: state not Withdrawing");
        if (ethLoss > 0) {
            _repayLoss(lp, _account, eventId, ethLoss);
        }

        uint lpAmount = accountOf(lp, _account).collateral;
        _removeCollateral(lp, _account, lpAmount);

        if (ethProfit > 0) {
            _payProfit(_account, ethProfit);
        }

        convertState(lp, _account, State.Idle);
        emit NotifyWithdrawnAll(lp, _account, eventId, lpAmount, ethProfit, ethLoss);
    }

    function notifyLiquidated(address lp, address _account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.Liquidating, "CVaultETHLP: state not Liquidating");
        if (ethLoss > 0) {
            _repayLoss(lp, _account, eventId, ethLoss);
        }

        Account memory account = accountOf(lp, _account);
        address liquidator = account.liquidator;

        uint penalty = account.collateral.mul(LIQUIDATION_PENALTY).div(UNIT);
        _payLiquidationPenalty(lp, _account, penalty, account.liquidator);
        _removeCollateral(lp, _account, account.collateral.sub(penalty));

        if (ethProfit > 0) {
            _payProfit(_account, ethProfit);
        }
        convertState(lp, _account, State.Idle);
        emit NotifyLiquidated(lp, _account, eventId, ethProfit, ethLoss, penalty, liquidator);
    }

    function notifyResolvedEmergency(address lp, address _account, uint128 eventId, uint112 nonce) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.EmergencyExited, "CVaultETHLP: state not EmergencyExited");
        convertState(lp, _account, State.Idle);

        emit NotifyResolvedEmergency(lp, _account, eventId);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addCollateral(address lp, address _account, uint amount) private returns (uint collateral) {
        IERC20(lp).transferFrom(_account, address(this), amount);
        collateral = increaseCollateral(lp, _account, amount);
    }

    function _removeCollateral(address lp, address _account, uint amount) private returns (uint collateral) {
        collateral = decreaseCollateral(lp, _account, amount);

        uint _fee = withdrawalFee(lp, _account, amount);
        if (_fee > 0) {
            _zapOutAll(lp, _fee);
        }
        IERC20(lp).safeTransfer(_account, amount.sub(_fee));
    }

    function _notifyDeposited(address lp, address _account, uint bscBNBDebt, uint bscFlipBalance) private {
        convertState(lp, _account, State.Farming);

        setBSCBNBDebt(lp, _account, bscBNBDebt);
        setBSCFlipBalance(lp, _account, bscFlipBalance);
    }

    function _payProfit(address _account, uint value) private {
        uint transfer;
        uint balance = address(this).balance;
        if (balance >= value) {
            transfer = value;
        } else {
            transfer = balance;
            increaseUnpaidETHValue(_account, value.sub(balance));
        }

        if (transfer > 0) {
            payable(_account).transfer(transfer);
        }
    }

    function _repayLoss(address lp, address _account, uint128 eventId, uint value) private {
        if (unpaidETH(_account) >= value) {
            decreaseUnpaidETHValue(_account, value);
            return;
        }

        Account memory account = accountOf(lp, _account);
        uint price = relayer.priceOf(lp);
        uint amount = Math.min(value.mul(1e18).div(price).mul(1000).div(997), account.collateral);
        uint before = address(this).balance;
        _zapOutAll(lp, amount);
        uint soldValue = address(this).balance.sub(before);
        decreaseCollateral(lp, _account, amount);

        emit LossRealized(lp, _account, eventId, amount, soldValue);
    }

    function _payLiquidationPenalty(address lp, address _account, uint penalty, address liquidator) private {
        require(liquidator != address(0), "CVaultETHLP: liquidator should not be zero");
        decreaseCollateral(lp, _account, penalty);

        uint fee = penalty.mul(LIQUIDATION_FEE).div(UNIT);
        IERC20(lp).safeTransfer(treasury, fee);
        IERC20(lp).safeTransfer(liquidator, penalty.sub(fee));
    }

    function _zapOutAll(address lp, uint amount) private {
        zap.zapOut(lp, amount);

        address token0 = IUniswapV2Pair(lp).token0();
        address token1 = IUniswapV2Pair(lp).token1();
        if (token0 != WETH) {
            _approveZap(token0);
            zap.zapOut(token0, IERC20(token0).balanceOf(address(this)));
        }
        if (token1 != WETH) {
            _approveZap(token1);
            zap.zapOut(token1, IERC20(token1).balanceOf(address(this)));
        }
    }

    function _approveZap(address token) private {
        if (IERC20(token).allowance(address(this), address(zap)) == 0) {
            IERC20(token).safeApprove(address(zap), uint(-1));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interface/ICVaultRelayer.sol";
import "./interface/ICVaultETHLP.sol";
import "./interface/ICVaultBSCFlip.sol";


contract CVaultRelayer is ICVaultRelayer, OwnableUpgradeable {
    using SafeMath for uint;

    uint8 public constant SIG_DEPOSIT = 10;
    uint8 public constant SIG_LEVERAGE = 20;
    uint8 public constant SIG_WITHDRAW = 30;
    uint8 public constant SIG_LIQUIDATE = 40;
    uint8 public constant SIG_EMERGENCY = 50;
    uint8 public constant SIG_CLEAR = 63;

    address public constant BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    address public cvaultETH;
    address public cvaultBSC;

    uint public bankLiquidity;
    uint public bankUtilized;

    uint128 public pendingId;
    uint128 public completeId;
    uint128 public liqPendingId;
    uint128 public liqCompleteId;

    mapping(uint128 => RelayRequest) public requests;
    mapping(uint128 => RelayResponse) public responses;
    mapping(uint128 => RelayLiquidation) public liquidations;

    mapping(address => bool) private _relayHandlers;
    mapping(address => uint) private _tokenPrices;

    /* ========== EVENTS ========== */

    event RelayCompleted(uint128 indexed completeId, uint128 count);
    event RelayFailed(uint128 indexed requestId);

    /* ========== MODIFIERS ========== */

    modifier onlyCVaultETH() {
        require(cvaultETH != address(0) && msg.sender == cvaultETH, "CVaultRelayer: call is not the cvault eth");
        _;
    }

    modifier onlyRelayHandlers() {
        require(_relayHandlers[msg.sender], "CVaultRelayer: caller is not the relay handler");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "CVaultRelayer: owner must be set");
    }

    /* ========== RELAY VIEW FUNCTIONS ========== */

    function getPendingRequestsOnETH(uint128 limit) public view returns (RelayRequest[] memory) {
        if (pendingId < completeId) {
            return new RelayRequest[](0);
        }

        uint128 count = pendingId - completeId;
        count = count > limit ? limit : count;
        RelayRequest[] memory pendingRequests = new RelayRequest[](count);

        ICVaultETHLP cvaultETHLP = ICVaultETHLP(cvaultETH);
        for (uint128 index = 0; index < count; index++) {
            uint128 requestId = completeId + index + uint128(1);
            RelayRequest memory request = requests[requestId];

            (uint8 validation, uint112 nonce) = cvaultETHLP.validateRequest(request.signature, request.lp, request.account, request.leverage, request.collateral);
            request.validation = validation;
            request.nonce = nonce;

            pendingRequests[index] = request;
        }
        return pendingRequests;
    }

    function getPendingResponsesOnBSC(uint128 limit) public view returns (RelayResponse[] memory) {
        if (pendingId < completeId) {
            return new RelayResponse[](0);
        }

        uint128 count = pendingId - completeId;
        count = count > limit ? limit : count;
        RelayResponse[] memory pendingResponses = new RelayResponse[](count);

        uint128 returnCounter = count;
        for (uint128 requestId = pendingId; requestId > pendingId - count; requestId--) {
            returnCounter--;
            pendingResponses[returnCounter] = responses[requestId];
        }
        return pendingResponses;
    }

    function getPendingLiquidationCountOnETH() public view returns (uint) {
        if (liqPendingId < liqCompleteId) {
            return 0;
        }
        return liqPendingId - liqCompleteId;
    }

    function canAskLiquidation(address lp, address account) public view returns (bool) {
        if (liqPendingId < liqCompleteId) {
            return true;
        }

        uint128 count = liqPendingId - liqCompleteId;
        for (uint128 liqId = liqPendingId; liqId > liqPendingId - count; liqId--) {
            RelayLiquidation memory each = liquidations[liqId];
            if (each.lp == lp && each.account == account) {
                return false;
            }
        }
        return true;
    }

    function getHistoriesOf(uint128[] calldata selector) public view returns (RelayHistory[] memory) {
        RelayHistory[] memory histories = new RelayHistory[](selector.length);

        for (uint128 index = 0; index < selector.length; index++) {
            uint128 requestId = selector[index];
            histories[index] = RelayHistory({requestId : requestId, request : requests[requestId], response : responses[requestId]});
        }
        return histories;
    }

    /* ========== ORACLE VIEW FUNCTIONS ========== */

    function valueOfAsset(address token, uint amount) public override view returns (uint) {
        return priceOf(token).mul(amount).div(1e18);
    }

    function priceOf(address token) public override view returns (uint) {
        return _tokenPrices[token];
    }

    function collateralRatioOnETH(address lp, uint lpAmount, address flip, uint flipAmount, uint debt) external override view returns (uint) {
        uint lpValue = valueOfAsset(lp, lpAmount);
        uint flipValue = valueOfAsset(flip, flipAmount);
        uint debtValue = valueOfAsset(BNB, debt);

        if (debtValue == 0) {
            return uint(- 1);
        }
        return lpValue.add(flipValue).mul(1e18).div(debtValue);
    }

    function utilizationInfo() public override view returns (uint liquidity, uint utilized) {
        return (bankLiquidity, bankUtilized);
    }

    function utilizationInfoOnBSC() public view returns (uint liquidity, uint utilized) {
        return ICVaultBSCFlip(cvaultBSC).getUtilizationInfo();
    }

    function isUtilizable(address lp, uint amount, uint leverage) external override view returns (bool) {
        if (bankUtilized >= bankLiquidity) return false;

        uint availableBNBSupply = bankLiquidity.sub(bankUtilized);
        return valueOfAsset(BNB, availableBNBSupply) >= valueOfAsset(lp, amount).mul(leverage).div(1e18);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setCVaultETH(address _cvault) external onlyOwner {
        cvaultETH = _cvault;
    }

    function setCVaultBSC(address _cvault) external onlyOwner {
        cvaultBSC = _cvault;
    }

    function setRelayHandler(address newRelayHandler, bool permission) external onlyOwner {
        _relayHandlers[newRelayHandler] = permission;
    }

    /* ========== RELAY FUNCTIONS ========== */
    /*
    * tx 1.   CVaultETH           requestRelayOnETH          -> CVaultRelayer enqueues request
    * tx 2-1. CVaultRelayHandlers getPendingRequestsOnETH    -> CVaultRelayer returns pending request list
    * tx 2-2. CVaultRelayHandlers transferRelaysOnBSC        -> CVaultRelayer handles request list by signature and update response list
    * tx 3-1. CVaultRelayHandlers getPendingResponsesOnBSC   -> CVaultRelayer returns pending response list
    * tx 3-2. CVaultRelayHandlers completeRelaysOnETH        -> CVaultRelayer handles response list by signature and update completeId
    * tx 3-3. CVaultRelayHandlers syncCompletedRelaysOnBSC   -> CVaultRelayer synchronize completeId
    */

    function requestRelayOnETH(address lp, address account, uint8 signature, uint128 leverage, uint collateral, uint lpAmount) public override onlyCVaultETH returns (uint requestId) {
        pendingId++;
        RelayRequest memory request = RelayRequest({
        lp : lp, account : account, signature : signature, validation : uint8(0), nonce : uint112(0), requestId : pendingId,
        leverage : leverage, collateral : collateral, lpValue : valueOfAsset(lp, lpAmount)
        });
        requests[pendingId] = request;
        return pendingId;
    }

    function transferRelaysOnBSC(RelayRequest[] memory _requests) external onlyRelayHandlers {
        require(cvaultBSC != address(0), "CVaultRelayer: cvaultBSC must be set");

        ICVaultBSCFlip cvaultBSCFlip = ICVaultBSCFlip(cvaultBSC);
        for (uint index = 0; index < _requests.length; index++) {
            RelayRequest memory request = _requests[index];
            RelayResponse memory response = RelayResponse({
            lp : request.lp, account : request.account,
            signature : request.signature, validation : request.validation, nonce : request.nonce, requestId : request.requestId,
            bscBNBDebtShare : 0, bscFlipBalance : 0, ethProfit : 0, ethLoss : 0
            });

            if (request.validation != uint8(0)) {
                if (request.signature == SIG_DEPOSIT) {
                    (uint bscBNBDebtShare, uint bscFlipBalance) = cvaultBSCFlip.deposit(request.lp, request.account, request.requestId, request.nonce, request.leverage, request.collateral);
                    response.bscBNBDebtShare = bscBNBDebtShare;
                    response.bscFlipBalance = bscFlipBalance;
                }
                else if (request.signature == SIG_LEVERAGE) {
                    (uint bscBNBDebtShare, uint bscFlipBalance) = cvaultBSCFlip.updateLeverage(request.lp, request.account, request.requestId, request.nonce, request.leverage, request.collateral);
                    response.bscBNBDebtShare = bscBNBDebtShare;
                    response.bscFlipBalance = bscFlipBalance;
                }
                else if (request.signature == SIG_WITHDRAW) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.withdrawAll(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
                else if (request.signature == SIG_EMERGENCY) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.emergencyExit(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
                else if (request.signature == SIG_LIQUIDATE) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.liquidate(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
                else if (request.signature == SIG_CLEAR) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.withdrawAll(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
            }

            requests[request.requestId] = request;
            responses[response.requestId] = response;
            pendingId++;
        }

        (bankLiquidity, bankUtilized) = cvaultBSCFlip.getUtilizationInfo();
    }

    function completeRelaysOnETH(RelayResponse[] memory _responses, RelayUtilization memory utilization) external onlyRelayHandlers {
        bankLiquidity = utilization.liquidity;
        bankUtilized = utilization.utilized;

        for (uint index = 0; index < _responses.length; index++) {
            RelayResponse memory response = _responses[index];
            bool success;
            if (response.validation != uint8(0)) {
                if (response.signature == SIG_DEPOSIT) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyDeposited(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.bscBNBDebtShare, response.bscFlipBalance)
                    );
                } else if (response.signature == SIG_LEVERAGE) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyUpdatedLeverage(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.bscBNBDebtShare, response.bscFlipBalance)
                    );
                } else if (response.signature == SIG_WITHDRAW) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyWithdrawnAll(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.ethProfit, response.ethLoss)
                    );
                } else if (response.signature == SIG_EMERGENCY) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyResolvedEmergency(address,address,uint128,uint112)",
                        response.lp, response.account, response.requestId, response.nonce)
                    );
                } else if (response.signature == SIG_LIQUIDATE) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyLiquidated(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.ethProfit, response.ethLoss)
                    );
                } else if (response.signature == SIG_CLEAR) {
                    success = true;
                }

                if (!success) {
                    emit RelayFailed(response.requestId);
                }
            }

            responses[response.requestId] = response;
            completeId++;
        }
        emit RelayCompleted(completeId, uint128(_responses.length));
    }

    function syncCompletedRelaysOnBSC(uint128 _count) external onlyRelayHandlers {
        completeId = completeId + _count;
        emit RelayCompleted(completeId, _count);
    }

    function syncUtilization(RelayUtilization memory utilization) external onlyRelayHandlers {
        bankLiquidity = utilization.liquidity;
        bankUtilized = utilization.utilized;
    }

    /* ========== LIQUIDATION FUNCTIONS ========== */

    function askLiquidationFromHandler(RelayLiquidation[] memory asks) external override onlyRelayHandlers {
        for (uint index = 0; index < asks.length; index++) {
            RelayLiquidation memory each = asks[index];
            if (canAskLiquidation(each.lp, each.account)) {
                liqPendingId++;
                liquidations[liqPendingId] = each;
            }
        }
    }

    function askLiquidationFromCVaultETH(address lp, address account, address liquidator) public override onlyCVaultETH {
        if (canAskLiquidation(lp, account)) {
            liqPendingId++;
            RelayLiquidation memory liquidation = RelayLiquidation({lp : lp, account : account, liquidator : liquidator});
            liquidations[liqPendingId] = liquidation;
        }
    }

    function executeLiquidationOnETH() external override onlyRelayHandlers {
        require(liqPendingId > liqCompleteId, "CVaultRelayer: no pending liquidations");

        ICVaultETHLP cvaultETHLP = ICVaultETHLP(cvaultETH);
        for (uint128 index = 0; index < liqPendingId - liqCompleteId; index++) {
            RelayLiquidation memory each = liquidations[liqCompleteId + index + uint128(1)];
            cvaultETHLP.executeLiquidation(each.lp, each.account, each.liquidator);
            liqCompleteId++;
        }
    }

    /* ========== ORACLE FUNCTIONS ========== */

    function setOraclePairData(RelayOracleData[] calldata data) external onlyRelayHandlers {
        for (uint index = 0; index < data.length; index++) {
            RelayOracleData calldata each = data[index];
            _tokenPrices[each.token] = each.price;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


library PoolConstant {

    enum PoolTypes {
        BunnyStake, BunnyFlip, CakeStake, FlipToFlip, FlipToCake, Bunny, BunnyBNB, Liquidity
    }

    struct PoolInfoBSC {
        address pool;
        uint balance;
        uint principal;
        uint available;
        uint apyPool;
        uint apyBunny;
        uint tvl;
        uint pUSD;
        uint pBNB;
        uint pBUNNY;
        uint pCAKE;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
    }

    struct PoolInfoETH {
        address pool;
        uint collateralETH;
        uint collateralBSC;
        uint bnbDebt;
        uint leverage;
        uint tvl;
        uint updatedAt;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
    }

    struct LiquidityPoolInfo {
        address pool;
        uint balance;
        uint principal;
        uint holding;
        uint apyPool;
        uint apyBunny;
        uint apyBorrow;
        uint tvl;
        uint utilized;
        uint pBNB;
        uint pBUNNY;
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


interface ICVaultETHLP {
    function validateRequest(uint8 signature, address lp, address account, uint128 leverage, uint collateral) external view returns (uint8 validation, uint112 nonce);
    function canLiquidate(address lp, address account) external view returns (bool);
    function executeLiquidation(address lp, address _account, address _liquidator) external;

    function notifyDeposited(address lp, address account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external;
    function notifyUpdatedLeverage(address lp, address account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external;
    function notifyWithdrawnAll(address lp, address account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external;
    function notifyLiquidated(address lp, address account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external;
    function notifyResolvedEmergency(address lp, address account, uint128 eventId, uint112 nonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


interface ICVaultRelayer {

    struct RelayRequest {
        address lp;
        address account;
        uint8 signature;
        uint8 validation;
        uint112 nonce;
        uint128 requestId;
        uint128 leverage;
        uint collateral;
        uint lpValue;
    }

    struct RelayResponse {
        address lp;
        address account;
        uint8 signature;
        uint8 validation;
        uint112 nonce;
        uint128 requestId;
        uint bscBNBDebtShare;
        uint bscFlipBalance;
        uint ethProfit;
        uint ethLoss;
    }

    struct RelayLiquidation {
        address lp;
        address account;
        address liquidator;
    }

    struct RelayUtilization {
        uint liquidity;
        uint utilized;
    }

    struct RelayHistory {
        uint128 requestId;
        RelayRequest request;
        RelayResponse response;
    }

    struct RelayOracleData {
        address token;
        uint price;
    }

    function requestRelayOnETH(address lp, address account, uint8 signature, uint128 leverage, uint collateral, uint lpAmount) external returns(uint requestId);

    function askLiquidationFromHandler(RelayLiquidation[] memory _candidate) external;
    function askLiquidationFromCVaultETH(address lp, address account, address liquidator) external;
    function executeLiquidationOnETH() external;

    function valueOfAsset(address token, uint amount) external view returns(uint);
    function priceOf(address token) external view returns(uint);
    function collateralRatioOnETH(address lp, uint lpAmount, address flip, uint flipAmount, uint debt) external view returns(uint);
    function utilizationInfo() external view returns (uint total, uint utilized);
    function isUtilizable(address lp, uint amount, uint leverage) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IZap {
    function zapOut(address _from, uint amount) external;
    function zapIn(address _to) external payable;
    function zapInToken(address _from, uint amount, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Whitelist is OwnableUpgradeable {
    mapping (address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __Whitelist_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns(bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface CVaultETHLPState {
    enum State {
        Idle, Depositing, Farming, Withdrawing, UpdatingLeverage, Liquidating, EmergencyExited
    }

    struct Account {
        uint collateral;
        uint bscBNBDebt;         // BSC - Borrowing BNB shares
        uint bscFlipBalance;     // BSC - Farming FLIP amount
        uint128 leverage;
        uint112 nonce;
        uint64 updatedAt;
        uint64 depositedAt;
        address liquidator;
        State state;
        uint withdrawalRequestAmount;
    }

    struct Pool {
        address bscFlip;
        bool paused;
        uint totalCollateral;

        mapping (address => Account) accounts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./CVaultETHLPState.sol";
import "../../library/PausableUpgradeable.sol";
import "../interface/ICVaultRelayer.sol";


contract CVaultETHLPStorage is CVaultETHLPState, PausableUpgradeable {
    using SafeMath for uint;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint public constant EMERGENCY_EXIT_TIMELOCK = 72 hours;
    uint public constant COLLATERAL_RATIO_MIN = 18e17;  // 180%

    uint128 public constant LEVERAGE_MAX = 15e17;       // 150%
    uint128 public constant LEVERAGE_MIN = 1e17;        // 10%

    uint public constant LIQUIDATION_PENALTY = 5e16;    // 5%
    uint public constant LIQUIDATION_FEE = 30e16;       // 30%  *** 30% of 5% penalty goes to treasury
    uint public constant UNIT = 1e18;                   // 100%

    uint public constant WITHDRAWAL_FEE_PERIOD = 3 days;
    uint public constant WITHDRAWAL_FEE = 5e15;         // 0.5%

    ICVaultRelayer public relayer;
    mapping(address => Pool) private _pools;
    mapping(address => uint) private _unpaidETH;

    uint public totalUnpaidETH;

    uint[50] private _gap;

    modifier increaseNonceOnlyRelayers(address lp, address _account, uint112 nonce) {
        require(msg.sender == address(relayer), "CVaultETHLPStorage: not a relayer");
        require(accountOf(lp, _account).nonce == nonce, "CVaultETHLPStorage: invalid nonce");
        _;
        increaseNonce(lp, _account);
    }

    modifier onlyStateFarming(address lp) {
        require(stateOf(lp, msg.sender) == State.Farming, "CVaultETHLPStorage: not farming state");
        _;
    }

    modifier validLeverage(uint128 leverage) {
        require(LEVERAGE_MIN <= leverage && leverage <= LEVERAGE_MAX, "CVaultETHLPStorage: leverage range should be [10%-150%]");
        _;
    }

    modifier notPausedPool(address lp) {
        require(_pools[lp].paused == false, "CVaultETHLPStorage: paused pool");
        _;
    }

    receive() external payable {}

    // ---------- INITIALIZER ----------

    function __CVaultETHLPStorage_init() internal initializer {
        __PausableUpgradeable_init();
    }

    // ---------- RESTRICTED ----------

    function _setPool(address lp, address bscFlip) internal onlyOwner {
        require(_pools[lp].bscFlip == address(0), "CVaultETHLPStorage: setPool already");
        _pools[lp].bscFlip = bscFlip;
    }

    function pausePool(address lp, bool paused) external onlyOwner {
        _pools[lp].paused = paused;
    }

    function setCVaultRelayer(address newRelayer) external onlyOwner {
        relayer = ICVaultRelayer(newRelayer);
    }

    // ---------- VIEW ----------

    function bscFlipOf(address lp) public view returns (address) {
        return _pools[lp].bscFlip;
    }

    function totalCollateralOf(address lp) public view returns (uint) {
        return _pools[lp].totalCollateral;
    }

    function stateOf(address lp, address account) public view returns (State) {
        return _pools[lp].accounts[account].state;
    }

    function accountOf(address lp, address account) public view returns (Account memory) {
        return _pools[lp].accounts[account];
    }

    function unpaidETH(address account) public view returns (uint) {
        return _unpaidETH[account];
    }

    function withdrawalFee(address lp, address account, uint amount) public view returns (uint) {
        if (_pools[lp].accounts[account].depositedAt + WITHDRAWAL_FEE_PERIOD < block.timestamp) {
            return 0;
        }

        return amount.mul(WITHDRAWAL_FEE).div(UNIT);
    }

    // ---------- SET ----------
    function increaseUnpaidETHValue(address _account, uint value) internal {
        _unpaidETH[_account] = _unpaidETH[_account].add(value);
        totalUnpaidETH = totalUnpaidETH.add(value);
    }

    function decreaseUnpaidETHValue(address _account, uint value) internal {
        _unpaidETH[_account] = _unpaidETH[_account].sub(value);
        totalUnpaidETH = totalUnpaidETH.sub(value);
    }

    function increaseCollateral(address lp, address _account, uint amount) internal returns (uint collateral) {
        Account storage account = _pools[lp].accounts[_account];
        collateral = account.collateral.add(amount);
        account.collateral = collateral;

        _pools[lp].totalCollateral = _pools[lp].totalCollateral.add(amount);
    }

    function decreaseCollateral(address lp, address _account, uint amount) internal returns (uint collateral) {
        Account storage account = _pools[lp].accounts[_account];
        collateral = account.collateral.sub(amount);
        account.collateral = collateral;

        _pools[lp].totalCollateral = _pools[lp].totalCollateral.sub(amount);
    }

    function setLeverage(address lp, address _account, uint128 leverage) internal {
        _pools[lp].accounts[_account].leverage = leverage;
    }

    function setWithdrawalRequestAmount(address lp, address _account, uint amount) internal {
        _pools[lp].accounts[_account].withdrawalRequestAmount = amount;
    }

    function setBSCBNBDebt(address lp, address _account, uint bscBNBDebt) internal {
        _pools[lp].accounts[_account].bscBNBDebt = bscBNBDebt;
    }

    function setBSCFlipBalance(address lp, address _account, uint bscFlipBalance) internal {
        _pools[lp].accounts[_account].bscFlipBalance = bscFlipBalance;
    }

    function increaseNonce(address lp, address _account) private {
        _pools[lp].accounts[_account].nonce++;
    }

    function setUpdatedAt(address lp, address _account) private {
        _pools[lp].accounts[_account].updatedAt = uint64(block.timestamp);
    }

    function setDepositedAt(address lp, address _account) private {
        _pools[lp].accounts[_account].depositedAt = uint64(block.timestamp);
    }

    function setLiquidator(address lp, address _account, address liquidator) internal {
        _pools[lp].accounts[_account].liquidator = liquidator;
    }

    function setState(address lp, address _account, State state) private {
        _pools[lp].accounts[_account].state = state;
    }

    function resetAccountExceptNonceAndState(address lp, address _account) private {
        Account memory account = _pools[lp].accounts[_account];
        _pools[lp].accounts[_account] = Account(0, 0, 0, 0, account.nonce, 0, 0, address(0), account.state, 0);
    }

    function convertState(address lp, address _account, State state) internal {
        Account memory account = _pools[lp].accounts[_account];
        State currentState = account.state;
        if (state == State.Idle) {
            require(msg.sender == address(relayer), "CVaultETHLPStorage: only relayer can resolve emergency state");
            require(currentState == State.Withdrawing || currentState == State.Liquidating || currentState == State.EmergencyExited,
                "CVaultETHLPStorage: can't convert to Idle"
            );
            resetAccountExceptNonceAndState(lp, _account);
        } else if (state == State.Depositing) {
            require(currentState == State.Idle || currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to Depositing");
            setDepositedAt(lp, _account);
        } else if (state == State.Farming) {
            require(currentState == State.Depositing || currentState == State.UpdatingLeverage,
                "CVaultETHLPStorage: can't convert to Farming");
        } else if (state == State.Withdrawing) {
            require(currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to Withdrawing");
        } else if (state == State.UpdatingLeverage) {
            require(currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to UpdatingLeverage");
        } else if (state == State.Liquidating) {
            require(currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to Liquidating"
            );
        } else if (state == State.EmergencyExited) {
            require(_account == msg.sender, "CVaultETHLPStorage: msg.sender is not the owner of account");
            require(currentState == State.Depositing || currentState == State.Withdrawing || currentState == State.UpdatingLeverage, "CVaultETHLPStorage: unavailable state to emergency exit");
            require(account.updatedAt + EMERGENCY_EXIT_TIMELOCK < block.timestamp, "CVaultETHLPStorage: timelocked");
        } else {
            revert("Invalid state");
        }

        setState(lp, _account, state);
        setUpdatedAt(lp, _account);
    }
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

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "PausableUpgradeable: cannot be performed while the contract is paused");
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), "PausableUpgradeable: owner must be set");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./IBankBNB.sol";
import "./IBankETH.sol";


interface ICVaultBSCFlip {
    function getUtilizationInfo() external view returns(uint liquidity, uint utilized);
    function bankBNB() external view returns(IBankBNB);
    function bankETH() external view returns(IBankETH);
    function withdrawAmount(address lp, address account, uint ratio) external view returns(uint lpBalance, uint cakeBalance);

    function deposit(address lp, address account, uint128 eventId, uint112 nonce, uint128 leverage, uint collateral) external returns (uint bscBNBDebtShare, uint bscFlipBalance);
    function updateLeverage(address lp, address account, uint128 eventId, uint112 nonce, uint128 leverage, uint collateral) external returns (uint bscBNBDebtShare, uint bscFlipBalance);
    function withdrawAll(address lp, address account, uint128 eventId, uint112 nonce) external returns (uint ethProfit, uint ethLoss);
    function emergencyExit(address lp, address account, uint128 eventId, uint112 nonce) external returns (uint ethProfit, uint ethLoss);
    function liquidate(address lp, address account, uint128 eventId, uint112 nonce) external returns (uint ethProfit, uint ethLoss);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBankBNB {
    function priceInBNB() external view returns (uint);

    function debtValOf(address pool, address user) external view returns(uint);
    function debtShareOf(address pool, address user) external view returns(uint);
    function debtShareToVal(uint debtShare) external view returns (uint debtVal);
    function debtValToShare(uint debtVal) external view returns (uint);
    function getUtilizationInfo() external view returns(uint liquidity, uint utilized);

    function accruedDebtValOf(address pool, address user) external returns(uint);
    function borrow(address pool, address borrower, uint debtVal) external returns(uint debt);
    function repay(address pool, address borrower) external payable returns(uint debtShares);

    function handOverDebtToTreasury(address pool, address borrower) external returns(uint debtShares);
    function repayTreasuryDebt() external payable returns(uint debtShares);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBankETH {
    function transferProfit() external payable returns(uint ethAmount);
    function repayOrHandOverDebt(address lp, address account, uint debt) external returns(uint ethAmount);
}