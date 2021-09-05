pragma solidity ^0.8.6;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";


contract SniperRoyale is  Context, Ownable, IERC20 {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    
    IUniswapV2Router02 router;
    string _name = "SniperRoyale";
    string _symbol = "SRYL";
    uint8  _decimals = 9;
    uint256 _totalSupply = 0;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    uint256 public block1Fee;
    uint256 public block2Fee;
    uint256 public block3Fee;
    uint256 public maxFee;
    uint256 private feeDenominator;
    
    constructor(uint256 _supply){
        _totalSupply = _supply * 10 ** 9;
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function startSniperRoyale (uint256 _supply, uint256 _block1Fee, uint256 _block2Fee, uint256 _block3Fee) public onlyOwner{
        _totalSupply = _supply * 10 ** 9;
        block1Fee = _block1Fee;
        block2Fee = _block2Fee;
        block3Fee = _block3Fee;
        maxFee = _block3Fee;
        feeDenominator = 100;
    }
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8){
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool){
        require(msg.sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        _balances[msg.sender] = _balances[msg.sender].sub(amount, "Transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}