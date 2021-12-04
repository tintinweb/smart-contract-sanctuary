/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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

    function transferMultiple(
        address[] memory recipients, 
        uint256[] memory amounts
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract GCARS is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint private _saleOn=0;
    uint private _price;
    
    constructor() {
        _name = "GCCAR";
        _symbol = "GCCAR";
        _decimals = 18;
        _mint(_msgSender(), 1000000 * 10 ** _decimals);
        _mint(address(this), 1000000 * 10 ** _decimals);
    }

    modifier saleOn() {
        require(_saleOn == 1, "Sale is disabled");
        _;
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

    function transferMultiple(
        address[] memory recipients, 
        uint256[] memory amounts
    ) public virtual override returns (bool success) {
        require(recipients.length == amounts.length, "ERC20: the length of the arrays does not match");
        require(_msgSender() != address(0), "ERC20: transfer from the zero address");
        
        address sender = _msgSender();
        uint256 senderBalance = _balances[sender];

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "ERC20: transfer to the zero address");
            require(senderBalance >= amounts[i], "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amounts[i];
            }

            _balances[recipients[i]] += amounts[i];
            emit Transfer(sender, recipients[i], amounts[i]);
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
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
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
    
    function mint(address to, uint256 amount) external virtual onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external virtual {
        require(balanceOf(_msgSender()) >= amount, "ERC20: burn amount exceeds allowance");
        _burn(_msgSender(), amount);
    }

    function setPrice(uint price) external virtual onlyOwner{
        //  tokens = ETH * price / 10^18
        //  price = 10^16, 1 token = 100 ETH
        //  price = 10^17, 1 token = 10 ETH
        //  price = 10^18, 1 token = 1 ETH
        //  price = 10^19, 1 token = 0.1 ETH
        //  price = 10^20, 1 token = 0.01 ETH
        _price = price;
    }

    function getPrice()external view virtual returns(uint price){
        return _price;
    }

    function buyToken() external payable saleOn {
        uint amount = _price * msg.value / (10 ** _decimals);
        require(amount >  0 && msg.value > 0, "Zero tokens not valid");
        require(amount <= balanceOf(address(this)), "No tokens available for trade");
        _transfer(address(this), _msgSender(), amount );
    }

    function sellToken(uint amount) external saleOn {
        require(amount <= balanceOf(_msgSender()), "No enough tokens for selling");
        //uint amount = _price * msg.value / (10 ** _decimals);
        uint value = amount * (10 ** _decimals) / _price;
        (bool success,) = _msgSender().call{value: value}("");
        require(success);
    }

    function isSaleActive() external view returns(bool){
        if (_saleOn == 1) return true;
        return false;
    }

    function switchSale(uint switcher) external onlyOwner {
        require(switcher == 0 || switcher==1, "Only 1 or 0 acceptable");
        _saleOn = switcher;
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address prohibited");
        require(amount <= address(this).balance, "Insufficient contract balance");
        to.transfer(amount);
    }
}