/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11; 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract OneStepCoin is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _isWhitelisted;

    uint256 private _totalSupply = 0;
    uint256 private constant _initialSupply = 20_000_000_000;

    string  private constant _name     = "One Step Coin";
    string  private constant _symbol   = "OSC";
    uint8   private constant _decimals = 18;

    uint256 public _txFee1 = 4; 
    uint256 public _txFee2 = 5; 
    address private _feWallet1 = 0x756B7775c93C6Fb0ef7207f566402FE1cC87e4Ce;
    address private _feWallet2 = 0x503CF12afE78A998B8C90206EC19e3C70f25afca;

    constructor() {
        _mint(_msgSender(), _initialSupply * 10 ** uint256(_decimals));
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 txFee1 = calculateTxFee1(amount);
        uint256 txFee2 = calculateTxFee2(amount);
        uint256 transferAmount = amount;
        if (sender != owner() && recipient != owner() && !isWhitelisted(sender) && !isWhitelisted(recipient)) {
            transferAmount = transferAmount - txFee1 - txFee2;

            _balances[_feWallet1] = _balances[_feWallet1] + txFee1;
            _balances[_feWallet2] = _balances[_feWallet2] + txFee2;
        }
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += transferAmount;

        emit Transfer(sender, recipient, amount);
    }

    function calculateTxFee1(uint256 _amount) private view returns (uint256) {
        return _amount * _txFee1 / 100;
    }

    function calculateTxFee2(uint256 _amount) private view returns (uint256) {
        return _amount * _txFee2 / 100;
    }

    function setTxFee1(uint256 txFee) public onlyOwner {
        _txFee1 = txFee;
    }

    function setTxFee2(uint256 txFee) public onlyOwner {
        _txFee2 = txFee;
    }

    function excludeFromWhitelist(address account) public onlyOwner {
        _isWhitelisted[account] = false;
    }

    function includeInWhitelist(address account) public onlyOwner {
        _isWhitelisted[account] = true;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _isWhitelisted[account];
    }
}