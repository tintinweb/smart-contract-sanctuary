/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: Unlicensed


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
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Test is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    string private _name = "test";
    string private _symbol = "test";
    uint256 private _decimals = 18;
    uint256 private _marketingFee = 5;
    uint256 private _liquidityFee = 5;
    uint256 private _totalSupply = 1000000 * 10 ** _decimals;
    uint256 public _maxTxAmount =  20000 * 10 ** _decimals;
    uint256 public _swapThreshold = _maxTxAmount.mul(_liquidityFee).div(1000);
    mapping (address => bool) private _isExcludedFromFee;
    IUniswapV2Router private _router = IUniswapV2Router(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    bool inSwap = false;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event intLog(string label, uint256 value);

    constructor() {
        _allowances[address(this)][address(_router)] = _totalSupply;
        _balances[msg.sender] = _totalSupply.div(2);
        _balances[msg.sender] = _totalSupply.div(2);
        _isExcludedFromFee[msg.sender] = true;
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
    function excludeFromFee(address guy) external onlyOwner {
        _isExcludedFromFee[guy] = true;
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "IERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _basicTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (true) {
            _basicTransfer(sender, recipient, amount);
        } else {

       /* require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "IERC20: transfer amount exceeds balance");
        uint256 feeAmount = 0;
        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && recipient != address(this) && recipient != pair() && !inSwap) {
            feeAmount = amount.mul(_marketingFee + _liquidityFee).div(100);

            _balances[address(this)] += feeAmount;
           require(amount <= _maxTxAmount);
           require(balanceOf(recipient) + amount <= _maxTxAmount);
        }

        uint256 amountReceived = amount;//.sub(feeAmount);
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);
        if (feeAmount > 0) {
            emit Transfer(sender, address(this), feeAmount);
         }
*/

            if (!inSwap && (_balances[address(this)] >= _swapThreshold) && sender != pair()) {
                swapBack();
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            _balances[recipient] = _balances[recipient].add(amount);
            _balances[address(this)] = _balances[address(this)].add(amount);
        }
    }
    function swapBack() public swapping {
        uint256 selfBalance = _balances[address(this)];
        emit intLog('selfBalance', selfBalance);
        uint256 amountToLiquify = selfBalance.mul(_liquidityFee).div(_liquidityFee + _marketingFee).div(2);
        emit intLog('amountToLiquify', amountToLiquify);
        uint256 amountToSwap = selfBalance.sub(amountToLiquify);
        emit intLog('amountToSwap',amountToSwap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        uint256 balanceBefore = address(this).balance;
        emit intLog('balanceBefore',balanceBefore);

        _approve(address(this), address(_router), amountToSwap);

        try _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            1000,
            0,
            path,
            address(this),
            block.timestamp + 200
        ) {} catch Error(string memory reason) {
            emit intLog(reason, 1);
        }

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        emit intLog('amountBNB',amountBNB);

    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
       // uint256 currentAllowance = _allowances[sender][_msgSender()];
      //  require(currentAllowance >= amount, "IERC20: transfer amount exceeds allowance");
       // _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function pair() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}