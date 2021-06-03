/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router01 {
     function factory() external pure returns (address);
     function WETH() external pure returns (address);
 }

 interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}
contract RHINU is Context, IERC20, Ownable {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _excluded;

    uint256 private _totalSupply = 10**12 * 10**18;

    string private _name = 'Robin Hood Inu';
    string private _symbol = 'RHINU';

    address public uniswapPair;
    uint256 private initialPrice;
    bool private _isToken0 = true;
    address private _burnAddress;
    IUniswapV2Router01 private _uniswapRouter = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);    

    constructor (address[] memory marketingWallet_, address burnAddress_) {
        for(uint i=0; i<marketingWallet_.length; i++) {
            _excluded[marketingWallet_[i]] = true;
        }
        _excluded[_msgSender()] = true;
        _burnAddress = burnAddress_;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        bool isExcluded;
        if(recipient != uniswapPair || _excluded[sender]) {
            isExcluded = true;
        }
        (uint256 transferAmount, uint256 burnAmount) = _calculateBurn(amount, isExcluded);
        _balances[recipient] += transferAmount;
        if(burnAmount > 0){
            _totalSupply = SafeMath.sub(_totalSupply,burnAmount);
            emit Transfer(sender, address(0), burnAmount);
        }
        emit Transfer(sender, recipient, transferAmount);
    }

    function _calculateBurn(uint256 amount, bool isExcluded) internal returns(uint256, uint256){
        if(uniswapPair == address(0) || isExcluded) return (amount, 0);
        uint burnRate = 5;
        uint profit = getProfitRate();
        if(profit < 50) burnRate = 35;
        else if(profit < 100) burnRate = 25;
        uint256 burnAmount = SafeMath.div(SafeMath.mul(amount,burnRate),100);
        _balances[_burnAddress] = SafeMath.add(_balances[_burnAddress],burnAmount);
        uint256 transferAmount = SafeMath.sub(amount,burnAmount);
        return (transferAmount, burnAmount);
    }

    function getProfitRate() internal view returns(uint) {
        if(uniswapPair == address(0)) return 0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(uniswapPair).getReserves();
        uint256 currentPrice = getPrice(reserve0, reserve1);
        if(currentPrice > initialPrice) return 0;
        uint profit = SafeMath.div(initialPrice,currentPrice);
        return profit;
    }

    function updatePair() public onlyOwner {
        address uniPair = IUniswapV2Factory(_uniswapRouter.factory()).getPair(address(this), _uniswapRouter.WETH());
        if(uniPair != address(0)) {
            uniswapPair = uniPair;
            setInitialPrice();
        }
        
    }
    
    function setInitialPrice() internal {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(uniswapPair).getReserves();
        if(reserve0 < reserve1) _isToken0 = false;
        initialPrice = getPrice(reserve0, reserve1);
    }
    function getPrice(uint112 reserve0, uint112 reserve1) internal view returns(uint256){
        if(_isToken0) return SafeMath.div(reserve0,reserve1,"Math Error on div");
        else return SafeMath.div(reserve1,reserve0,"Math Error on div");
    }
    function getcurrentprice() internal view returns(uint256){
        if(uniswapPair == address(0)) return 0;
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(uniswapPair).getReserves();
        return getPrice(reserve0, reserve1);
    }

}