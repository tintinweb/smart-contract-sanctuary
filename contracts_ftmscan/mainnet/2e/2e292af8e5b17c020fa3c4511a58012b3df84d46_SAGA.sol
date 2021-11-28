/**
 *Submitted for verification at FtmScan.com on 2021-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) internal virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

contract SAGA is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("SAGA", "SAGA") {}

    address private dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address private fusdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
    address private usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address private mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    uint256 public mimGate = 1;
    uint256 public daiGate = 1;
    uint256 public usdcGate = 1;
    uint256 public fusdtGate = 1;

    function mintFromDAI(uint256 amount) public {
        IERC20 daiToken = IERC20(dai);
        require(daiGate == 1);
        require(
            daiToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ) == true,
            'Could not transfer tokens from your address to this contract'
        );
        _mint(msg.sender, amount);
    }
    function mintFromUSDC(uint256 amount) public {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcGate == 1);
        require(
            usdcToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ) == true,
            'Could not transfer tokens from your address to this contract'
        );
        _mint(msg.sender, amount);
    }
    function mintFromFUSDT(uint256 amount) public {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtGate == 1);
        require(
            fusdtToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ) == true,
            'Could not transfer tokens from your address to this contract'
        );
        _mint(msg.sender, amount);
    }
    function mintFromMIM(uint256 amount) public {
        IERC20 mimToken = IERC20(mim);
        require(mimGate == 1);
        require(
            mimToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ) == true,
            'Could not transfer tokens from your address to this contract'
        );
        _mint(msg.sender, amount);
    }
        function sagaToDai(uint256 amount) public {
        IERC20 daiToken = IERC20(dai);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        daiToken.transfer(msg.sender, amount);
    }
        function sagaToFusdt(uint256 amount) public {
        IERC20 fusdtToken = IERC20(fusdt);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        fusdtToken.transfer(msg.sender, amount / 10**12);
    }
        function sagaToUsdc(uint256 amount) public {
        IERC20 usdcToken = IERC20(usdc);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        usdcToken.transfer(msg.sender, amount / 10**12);
    }
        function sagaToMim(uint256 amount) public {
        IERC20 mimToken = IERC20(mim);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        mimToken.transfer(msg.sender, amount);
    }
        function getUSDCBalance() public view returns(uint256) {
        return ERC20(usdc).balanceOf(address(this));
    }
        function getFUSDTBalance() public view returns(uint256) {
        return ERC20(fusdt).balanceOf(address(this));
    }
        function getDAIBalance() public view returns(uint256) {
        return ERC20(dai).balanceOf(address(this));
    }
        function getMIMBalance() public view returns(uint256) {
        return ERC20(mim).balanceOf(address(this));
    }
        function setMimGate(uint256 mimStatus) public onlyOwner {
            mimGate = mimStatus;
    }
        function setDaiGate(uint256 daiStatus) public onlyOwner {
            daiGate = daiStatus;
    }
        function setFusdtGate(uint256 fusdtStatus) public onlyOwner {
            fusdtGate = fusdtStatus;
    }
        function setUsdcGate(uint256 usdcStatus) public onlyOwner {
            usdcGate = usdcStatus;
    }
}