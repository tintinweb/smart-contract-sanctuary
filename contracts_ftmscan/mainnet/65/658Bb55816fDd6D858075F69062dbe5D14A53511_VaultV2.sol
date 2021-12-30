/**
 *Submitted for verification at FtmScan.com on 2021-12-30
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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
}

contract VaultV2 is Owner {
    uint256 public boxSize = 0;
    string public name = "Protector";
    string public symbol = "PROTECTOR";
    uint256 totalSupply = 0;

    struct DepositBox {
        uint256 id;
        address ERC20Token;
        address payable depositor;
        bytes32 key;
        uint256 balance;
    }

    function bytes32ToString(bytes32 _bytes32)
        private
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function hash(string memory text) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(text));
    }

    modifier verify(uint256 id, string memory key) {
        bytes32 boxKey = depositBoxes[id].key;
        bytes32 hashed = hash(key);
        require(boxKey != bytes32(0), "verify: Set key first");
        require(bytes(key).length > 0, "verify: Key required");
        require(hash(key) == boxKey, "verify: Key incorrect");
        _;
    }

    mapping(address => uint256) public ERC20TokenBalances;
    mapping(uint256 => DepositBox) public depositBoxes;
    mapping(address => uint256[]) public depositBoxesOf;
    mapping(address => uint256) public depositBoxesSizeOf;
    mapping(address => uint256) public activeDepositBoxesSizeOf;

    event Deposit(DepositBox box);
    event WithdrawAll(DepositBox box);
    event Withdraw(DepositBox box, uint256 value);
    event ChangeKey(DepositBox box);

    function deposit(
        uint256 value,
        address ERC20Token,
        bytes32 key
    ) public payable {
        require(key.length > 0, "deposit: key required");

        uint256 depositedValue = 0;

        if (ERC20Token == address(0)) {
            require(msg.value > 0, "deposit: value required");
            depositedValue = msg.value;
            ERC20TokenBalances[ERC20Token] += depositedValue;
        } else {
            require(value > 0, "deposit: value required");
            uint256 balance = IERC20(ERC20Token).balanceOf(msg.sender);
            require(value <= balance, "deposit: value exceeds balance");
            IERC20(ERC20Token).transferFrom(msg.sender, address(this), value);
            depositedValue = value;
            ERC20TokenBalances[ERC20Token] += depositedValue;
        }

        require(depositedValue > 0, "deposit: value required");

        uint256 id = boxSize + 1;
        boxSize = id;
        DepositBox memory box = DepositBox(
            id,
            address(ERC20Token),
            payable(address(msg.sender)),
            key,
            depositedValue
        );
        depositBoxes[box.id] = box;
        depositBoxesOf[msg.sender].push(box.id);
        depositBoxesSizeOf[msg.sender]++;
        activeDepositBoxesSizeOf[msg.sender]++;
        emit Deposit(box);
    }

    function withdrawAll(uint256 id, string memory key) public verify(id, key) {
        DepositBox memory box = depositBoxes[id];
        require(box.depositor == msg.sender, "withdrawAll: unauthorized");
        require(box.balance > 0, "withdrawAll: nothing to withdraw");

        if (box.ERC20Token == address(0)) {
            box.depositor.transfer(box.balance);
        } else {
            IERC20(box.ERC20Token).transfer(msg.sender, box.balance);
        }

        ERC20TokenBalances[box.ERC20Token] -= box.balance;
        box.balance = 0;
        depositBoxes[id] = box;
        activeDepositBoxesSizeOf[msg.sender]--;
        emit WithdrawAll(box);
    }

    function _changeKey(
        uint256 id,
        string memory key,
        bytes32 newKey
    ) private verify(id, key) returns (DepositBox memory) {
        DepositBox memory box = depositBoxes[id];
        require(
            hash(bytes32ToString(box.key)) != hash(bytes32ToString(newKey)),
            "changeKey: provide a new key"
        );
        box.key = newKey;
        depositBoxes[id] = box;
        emit ChangeKey(box);
        return box;
    }

    function changeKey(
        uint256 id,
        string memory key,
        bytes32 newKey
    ) public returns (DepositBox memory) {
        DepositBox memory box = depositBoxes[id];
        require(box.depositor == msg.sender, "changeKey: unauthorized");
        return _changeKey(id, key, newKey);
    }

    function withdraw(
        uint256 id,
        string memory key,
        bytes32 newKey,
        uint256 value
    ) public {
        DepositBox memory box = _changeKey(id, key, newKey); // verifies
        require(box.depositor == msg.sender, "withdraw: unauthorized");
        require(value > 0, "withdraw: value required");
        require(box.balance > 0, "withdraw: nothing to withdraw");
        require(value <= box.balance, "withdraw: value exceeds balance");

        if (box.ERC20Token == address(0)) {
            box.depositor.transfer(value);
        } else {
            IERC20(box.ERC20Token).transfer(msg.sender, value);
        }

        ERC20TokenBalances[box.ERC20Token] -= value;
        box.balance = box.balance -= value;
        depositBoxes[id] = box;

        if (box.balance == 0) {
            activeDepositBoxesSizeOf[msg.sender]--;
        }

        emit Withdraw(box, value);
    }
}