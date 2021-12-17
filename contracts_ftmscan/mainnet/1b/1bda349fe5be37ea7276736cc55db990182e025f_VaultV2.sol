/**
 *Submitted for verification at FtmScan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Owner {
    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
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

contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract VaultV2 is Owner {
    uint public boxSize = 0;

    struct DepositBox {
        uint id;
        address ERC20Token;
        address depositor;
        bytes32 key;
        uint balance;
    }

    function hash(string memory text) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(text));
    }
    
    modifier verify(uint id, string memory key) {
        bytes32 boxKey = depositBoxes[id].key;
        bytes32 hashed = hash(key);
        require(boxKey != bytes32(0), "verify: Set key first");
        require(bytes(key).length > 0, "verify: Key required");
        require(hash(key) == boxKey, "verify: Key incorrect");
        _;
    }

    mapping(address => uint) public ERC20TokenBalances;
    mapping(uint => DepositBox) public depositBoxes;
    mapping(address => uint[]) public depositBoxesOf;
    mapping(address => uint) public depositBoxesSizeOf;
    mapping(address => uint) public activeDepositBoxesSizeOf;

    event Deposit(DepositBox box);
    event WithdrawAll(DepositBox box);

    function deposit(uint value, address ERC20Token, bytes32 key) public payable {
        require(key.length > 0, "deposit: key required");
        require(value > 0, "deposit: value required");
        require(ERC20Token != address(0x0), "deposit: ERC20Token address required");

        uint balance = IERC20(ERC20Token).balanceOf(msg.sender);

        require(value <= balance, "deposit: balance not enough");

        IERC20(ERC20Token).transferFrom(msg.sender, address(this), value);
        ERC20TokenBalances[ERC20Token] += value;
        uint id = boxSize + 1;
        boxSize = id;
        DepositBox memory box = DepositBox(id, ERC20Token, msg.sender, key, value);
        depositBoxes[box.id] = box;
        depositBoxesOf[msg.sender].push(box.id);
        depositBoxesSizeOf[msg.sender]++;
        activeDepositBoxesSizeOf[msg.sender]++;
        emit Deposit(box);
    }

    function withdrawAll(uint id, string memory key) verify(id, key) public payable {
        DepositBox memory box = depositBoxes[id];
        require(box.depositor == msg.sender, "withdrawAll: unauthorized");
        require(box.balance > 0, "withdrawAll: nothing to withdraw");

        IERC20(box.ERC20Token).transfer(msg.sender, box.balance);
        ERC20TokenBalances[box.ERC20Token] -= box.balance;
        depositBoxes[id] = box;
        activeDepositBoxesSizeOf[msg.sender]--;
        emit WithdrawAll(box);
    }

}