//SourceUnit: token.sol

pragma solidity ^0.5.0;

interface ITRC20 {
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Token is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private _name;
    
    string private _symbol;
    
    uint8 private _decimals;

    uint256 private _totalSupply;
    
    address private _owner;

    // 流动性提供者分配比例
    uint8 private _lperRate;
    
    // 持币者分配比例
    uint8 private _holderRate;
    
    // 基金会分配比例
    uint8 private _foundationRate;

    // 销毁比例
    uint8 private _burnRate;
    
    // 剩余比例
    uint8 private _othersRate;

    // 流动性提供者分配地址
    address private _lperAddress;
    
    // 持币者分配地址
    address private _holderAddress;
    
    // 基金会分配地址
    address private _foundationAddress;

    // 销毁地址
    address private _burnAddress;
    
    // 剩余地址
    address private _othersAddress;
    
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, uint8 lperRate, uint8 holderRate, uint8 foundationRate, uint8 burnRate, uint8 othersRate) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mint(msg.sender, totalSupply * (10 ** uint256(decimals)));
        
        _transferOwnership(msg.sender);
        
        _setRate(lperRate, holderRate, foundationRate, burnRate, othersRate);
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

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        
        uint256 lper = amount.mul(_lperRate).div(100);
        uint256 holder = amount.mul(_holderRate).div(100);
        uint256 foundation = amount.mul(_foundationRate).div(100);
        uint256 burn = amount.mul(_burnRate).div(100);
        uint256 others = amount.mul(_othersRate).div(100);
        uint256 fee = lper.add(holder).add(foundation).add(burn).add(others);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount.sub(fee));
        _balances[_lperAddress] = _balances[_lperAddress].add(lper);
        _balances[_holderAddress] = _balances[_holderAddress].add(holder);
        _balances[_foundationAddress] = _balances[_foundationAddress].add(foundation);
        _balances[_burnAddress] = _balances[_burnAddress].add(burn);
        _balances[_othersAddress] = _balances[_othersAddress].add(others);
        
        emit Transfer(sender, recipient, amount.sub(fee));
        emit Transfer(sender, _lperAddress, lper);
        emit Transfer(sender, _holderAddress, holder);
        emit Transfer(sender, _foundationAddress, foundation);
        emit Transfer(sender, _burnAddress, burn);
        emit Transfer(sender, _othersAddress, others);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        _owner = newOwner;
    }
    
    function lperRate() public view returns (uint8) {
        return _lperRate;
    }
    
    function holderRate() public view returns (uint8) {
        return _holderRate;
    }
    
    function burnRate() public view returns (uint8) {
        return _burnRate;
    }
    
    function othersRate() public view returns (uint8) {
        return _othersRate;
    }
    
    function lperAddress() public view returns (address) {
        return _lperAddress;
    }
    
    function holderAddress() public view returns (address) {
        return _holderAddress;
    }
    
    function foundationAddress() public view returns (address) {
        return _foundationAddress;
    }
    
    function burnAddress() public view returns (address) {
        return _burnAddress;
    }
    
    function othersAddress() public view returns (address) {
        return _othersAddress;
    }
    
    function setRate(uint8 lperRate, uint8 holderRate, uint8 foundationRate, uint8 burnRate, uint8 othersRate) public onlyOwner {
        _setRate(lperRate, holderRate, foundationRate, burnRate, othersRate);
    }

    function _setRate(uint8 lperRate, uint8 holderRate, uint8 foundationRate, uint8 burnRate, uint8 othersRate) internal {
        require(100 > lperRate + holderRate + foundationRate + burnRate + othersRate, "Parameters error");

        _lperRate = lperRate;
        _holderRate = holderRate;
        _foundationRate = foundationRate;
        _burnRate = burnRate;
        _othersRate = othersRate;
    }
    
    function setLperAddress(address lperAddress) public onlyOwner {
        _lperAddress = lperAddress;
    }
    
    function setHolderAddress(address holderAddress) public onlyOwner {
        _holderAddress = holderAddress;
    }
    
    function setFoundationAddress(address foundationAddress) public onlyOwner {
        _foundationAddress = foundationAddress;
    }
    
    function setBurnAddress(address burnAddress) public onlyOwner {
        _burnAddress = burnAddress;
    }
    
    function setOthersAddress(address othersAddress) public onlyOwner {
        _othersAddress = othersAddress;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == _lperAddress || msg.sender == _holderAddress, "Caller is not the admin");
        _;
    }
    
    function justTransfer(address recipient, uint256 amount) public onlyAdmin returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
}