/**
 *Submitted for verification at Etherscan.io on 2020-12-19
*/

pragma solidity >=0.6.0 <0.8.0;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isUniswap;
    
    mapping (address => uint256) private lastReceive;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;

    uint256 private tokenLimit = 8000000000000000000;
    bool public limitEnabled = true;
    
    uint256 public onUniswap = 0;
    bool public presaleLocked = true;
    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        _name = "DegenAsgard";
        _symbol = "DASG";
        _decimals = 18;
        _mint(_msgSender(), 500000000000000000000);
    }
    
    function burnPercentage(address _addr) private view returns (uint256) {
        uint256 mins = (block.timestamp - lastReceive[_addr]) / 1 minutes;
        if(mins < 2){
            return 49;
        }
        else if(mins < 5){
            return 30;
        }
        else if(mins < 10){
            return 15;
        }
        else{
            return 5;
        }
    }
    
    function switchPresale() public onlyOwner {
        presaleLocked = !presaleLocked;
    }
    
    function switchLimit() public onlyOwner {
        limitEnabled = !limitEnabled;
    }
    
    function setUniswap(address _addr) public onlyOwner {
        if(onUniswap == 0){
            onUniswap = block.timestamp;
        }
        _isUniswap[_addr] = true;
    }
    
    function removeUniswap(address _addr) public onlyOwner {
        _isUniswap[_addr] = false;    
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!limitEnabled || amount <= tokenLimit || owner() == _msgSender(), "Only a maximum of 8 tokens can be transferred at once");


        if(_isUniswap[sender] || _isUniswap[recipient]){
            if((block.timestamp - onUniswap) / 1 minutes < 10 && presaleLocked && lastReceive[sender] > 0 && lastReceive[sender] < onUniswap){
                revert();
            }
    
            if(!_isUniswap[sender]){
                uint256 sellBurn = amount.mul(burnPercentage(sender)).div(100);
                _burn(sender, sellBurn);
                _balances[sender] = _balances[sender].sub(amount.sub(sellBurn), "ERC20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount.sub(sellBurn));
                emit Transfer(sender, recipient, amount.sub(sellBurn));
            }else if(_isUniswap[sender]){
                uint256 sellBurn = amount.mul(10).div(100);
                _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
                emit Transfer(sender, recipient, amount);
                _burn(recipient, sellBurn);
                lastReceive[recipient] = block.timestamp;
            }
        }else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            lastReceive[recipient] = block.timestamp;
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
}