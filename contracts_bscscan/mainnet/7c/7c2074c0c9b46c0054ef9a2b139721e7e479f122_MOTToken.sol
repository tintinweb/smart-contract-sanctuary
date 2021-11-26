pragma solidity 0.5.8;

import "./ITRC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract MOTToken is ITRC20, Ownable {
    using SafeMath for uint256;

    string private _name = "MOT";
    string private _symbol = "MOT";
    uint8 private _decimals = 18;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    mapping (address => bool) private _isIncludedFromFee;

    address public burnPool = 0x000000000000000000000000000000000000dEaD;
    address public fixedWallet = 0x000000000000000000000000000000000000dEaD;

    constructor (address recipient) public {
        _mint(recipient, 21e25);
        fixedWallet = msg.sender;
    }

    function setBurnPool(address _pool) public onlyOwner {
        burnPool = _pool;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isIncludedFromFee[account] = false;
    }

    function includeInFee(address account) public onlyOwner {
        _isIncludedFromFee[account] = true;
    }

    function isIncludedFromFee(address account) public view returns(bool) {
        return _isIncludedFromFee[account];
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256 burnAmount, uint256 fixedAmount, uint256 leftover) {
        burnAmount = _amount.mul(5).div(100);
        fixedAmount = _amount.mul(3).div(100);
        leftover = _amount.sub(burnAmount).sub(fixedAmount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!_isIncludedFromFee[recipient]) { // no fee
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 leftover;
            uint256 burnAmount;
            uint256 fixedAmount;
            (burnAmount, fixedAmount, leftover) = calculateTaxFee(amount);

            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(leftover);
            _balances[fixedWallet] = _balances[fixedWallet].add(fixedAmount);
            _balances[burnPool] = _balances[burnPool].add(burnAmount);

            emit Transfer(sender, recipient, leftover);
            emit Transfer(sender, fixedWallet, fixedAmount);
            emit Transfer(sender, burnPool, burnAmount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}