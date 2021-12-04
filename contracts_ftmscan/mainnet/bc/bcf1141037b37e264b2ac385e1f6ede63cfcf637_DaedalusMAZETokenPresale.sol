/**
 *Submitted for verification at FtmScan.com on 2021-12-04
*/

//SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public deployer;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, address deployer_) {
        deployer = deployer_;
        _name = name_;
        _symbol = symbol_;
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "PreMAZE: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "PreMAZE: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(recipient != address(0), "PreMAZE: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "PreMAZE: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "PreMAZE: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function validate(uint supply_) external {
        require(deployer == msg.sender, "PreMAZE: Caller is not the deployer address");
        _mint(deployer, supply_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "PreMAZE: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "PreMAZE: approve from the zero address");
        require(spender != address(0), "PreMAZE: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



contract DaedalusMAZETokenPresale is ERC20 {
    mapping (address => uint256) public amountPurchased;
    mapping (address => bool) public whitelist;
    address public owner;
    bool public active;
    IERC20 public MIM = IERC20(0x2BC472832Eb20C65F82d6A869db845aB0C0099ba);
    // [email protected]: 0x2BC472832Eb20C65F82d6A869db845aB0C0099ba

    constructor() ERC20("MAZE Presale Token", "preMAZE", msg.sender) {
        owner = msg.sender;
        // _mint(msg.sender, supply);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "PreMaze: Caller is not the deployer address");
        _;
    }

    function isActive() public view virtual returns (bool) {
        return active;
    }

    function setActive(bool _active) external onlyOwner {
        active = _active;
    }

    function whitelistAddresses(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function buyPreMAZE(uint256 _amount) external {
        require((_amount > 0) && (_amount <= 25e18) && (whitelist[msg.sender]) && (amountPurchased[msg.sender] <= 25e18), "PreMaze: Invalid MIM input or already participated");
        require(active == true, "PreMaze: Presale is not active");
        MIM.transferFrom(msg.sender, address(this), _amount);

        require(amountPurchased[msg.sender] + _amount <= 25e18, "PreMaze: Exceeds limit of 2500 MIM tokens");

        _mint(msg.sender, (_amount*10)/75); // at 7.5 MIM per token
        amountPurchased[msg.sender] += _amount;
    }

    function withdrawMIMForLiquidity() external onlyOwner {
        require(MIM.balanceOf(address(this)) > 0, "PreMaze: No MIM stablecoins to withdraw");
        MIM.transfer(owner, MIM.balanceOf(address(this)));
    }
}