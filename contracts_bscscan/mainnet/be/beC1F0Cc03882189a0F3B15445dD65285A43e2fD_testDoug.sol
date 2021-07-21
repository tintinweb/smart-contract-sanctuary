/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
}

contract testDoug is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 _totalSupply;

    mapping (address => bool) isFeeExempt;
    
    address public receiverFee;

    uint256 public feeBuy = 600;
    uint256 public feeSell = 800;
    uint256 public feeDenominator = 10000;

    IDEXRouter public router;
    address public pair;

    constructor() {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(this));
        _name = "testDoug";
        _symbol = "testDoug";
        _decimals = 9;
        _totalSupply = 1000 * 10**9 * 10**_decimals;
        _balances[_msgSender()] = _totalSupply;

        receiverFee = 0x04fC814F09cC180B1dE97668091Fe6cE673878fE;

        isFeeExempt[_msgSender()] = true;
        isFeeExempt[receiverFee] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function getOwner() override external view returns (address) { return owner(); }
    function decimals() override external view returns (uint8) { return _decimals; }
    function symbol() override external view returns (string memory) { return _symbol; }
    function name() override external view returns (string memory) { return _name; }
    function totalSupply() override external view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) override external view returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) override external view returns (uint256) { return _allowances[owner][spender]; }

    function approve(address spender, uint256 amount) override external returns (bool) { 
        return _approve(_msgSender(), spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        return _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    }

    function _approve(address owner, address spender, uint256 amount) internal returns (bool) {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) override external returns (bool) { 
        return _transfer(_msgSender(), recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");

        bool isSelling = recipient == pair;
        bool isBuying = sender == pair;
        bool simpleTransfer = !isSelling && !isBuying;
        bool shouldTakeFee = isBuying ? isFeeExempt[recipient] : isFeeExempt[sender]; 
        if(simpleTransfer || shouldTakeFee) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 amountFee = amount.mul(isBuying ? feeBuy : feeSell).div(feeDenominator);
        _basicTransfer(sender, receiverFee, amountFee);
        _basicTransfer(sender, recipient, amount.sub(amountFee));

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function clearFund() external {
        payable(receiverFee).call{value: address(this).balance}(new bytes(0));
        _basicTransfer(address(this), receiverFee, _balances[address(this)]);
    }

    receive() external payable {
    }
}