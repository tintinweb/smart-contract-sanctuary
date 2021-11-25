/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

contract Mama is Ownable, ERC20 {
    uint256 private _startTime;
    uint16 private _lastRewardPeriod;
    uint256 private _buyPrice;
    uint256 private _sellPrice;
    uint256 private _minAmountToStake;
    uint256 private _apr;
    uint256 private _stakeId;
    uint256 private _totalStakeSupply;
    uint256 private _stakeBalance;
    uint256 private _lockBlock;
    uint256 private _toBlock;
    bool private _exchangePause;
    bool private _stakePause;
    mapping(uint256 => Stake) private _stakeOwners;
    mapping(address => uint256) private _numberOfStake;

    struct Stake {
        uint256 fromBlock;
        uint256 amount;
        uint256 apr;
        uint256 lockBlock;
        address owner;
        bool settled;
        uint256 toBlock;
    }

    constructor() ERC20("MAMA token", "MAMAZY") {
        _mint(_msgSender(), 1_000_000_000_000_000_000_000_000_000); //1e9
        _buyPrice = 10_000_000_000_000_000;
        _sellPrice = 9_500_000_000_000_000;
        _minAmountToStake = 300_000_000_000_000_000_000;
        _totalStakeSupply = 1_000_000_000_000_000_000_000_000;
        _apr = 200_000; //100% ~ 100_100
        _stakeId = 0;
        _stakeBalance = 0;
        _lockBlock = 144000;
        _toBlock = 10512000;
        _exchangePause = false;
        _stakePause = false;
    }

    function buyMazy() public payable {
        require(!_exchangePause, "The exchange is paused");
        require(
            msg.value >= 1_000_000_000_000_000,
            "The amount of BNB is too small, the minimum is 0.01"
        );
        uint256 amount = Math.ceilDiv(
            msg.value * 1_000_000_000_000_000_000,
            _buyPrice
        );
        _mint(_msgSender(), amount);
        emit BuyMazy(_msgSender(), amount, _buyPrice);
    }

    function sellMazy(uint256 amount) public {
        require(!_exchangePause, "The exchange is paused");
        require(
            amount <= balanceOf(_msgSender()),
            "You don't have enough USD to sell"
        );
        uint256 amountToSell = Math.ceilDiv(
            amount * _sellPrice,
            1_000_000_000_000_000_000
        );
        require(
            address(this).balance >= amountToSell,
            "The BNB balance of Smart Contract is not enough to make this transaction"
        );
        _burn(_msgSender(), amount);
        payable(msg.sender).transfer(amountToSell);
        emit SellMazy(_msgSender(), amount, _sellPrice);
    }

    function staking(uint256 amount) public {
        require(!_stakePause, "The stake system is paused");
        require(
            amount <= balanceOf(_msgSender()),
            "You don't have enough MAZY to staking"
        );
        require(amount >= _minAmountToStake, "Amount less than minimum stake");
        require(
            _stakeBalance + amount <= _totalStakeSupply,
            "Exceeded the maximum total stake supply"
        );
        _burn(_msgSender(), amount);
        _stakeOwners[_stakeId] = Stake(
            block.number,
            amount,
            _apr,
            block.number + _lockBlock,
            _msgSender(),
            false,
            block.number + _toBlock
        );
        _numberOfStake[_msgSender()] = _numberOfStake[_msgSender()] + 1;
        emit NewStake(_stakeId, _msgSender(), amount);
        _stakeId = _stakeId + 1;
        _stakeBalance = _stakeBalance + amount;
    }

    function unstaking(uint256 stakeId) public {
        require(!_stakePause, "The stake system is paused");
        require(stakeId < _stakeId, "Stake does not exist");
        require(
            _stakeOwners[stakeId].owner == _msgSender(),
            "You do not own this stake"
        );
        require(
            block.number >= _stakeOwners[stakeId].lockBlock,
            "unexpired stake"
        );
        require(!_stakeOwners[stakeId].settled, "Stake have been settled");

        _stakeOwners[stakeId].settled = true;

        uint256 numberOfBlock = block.number - _stakeOwners[stakeId].fromBlock;
        if (block.number >= _stakeOwners[stakeId].toBlock) {
            numberOfBlock =
                _stakeOwners[stakeId].toBlock -
                _stakeOwners[stakeId].fromBlock;
        }

        uint256 amount = _stakeOwners[stakeId].amount +
            (_stakeOwners[stakeId].amount *
                numberOfBlock *
                _stakeOwners[stakeId].apr) /
            1051200000000;
        _mint(_msgSender(), amount);
        emit SettleStake(stakeId, _msgSender(), amount);
    }

    function bnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function apr() public view returns (uint256) {
        return _apr;
    }

    function minAmountToStake() public view returns (uint256) {
        return _minAmountToStake;
    }

    function stakeBalance() public view returns (uint256) {
        return _stakeBalance;
    }

    function lockBlock() public view returns (uint256) {
        return _lockBlock;
    }

    function toBlock() public view returns (uint256) {
        return _toBlock;
    }

    function totalStakeSupply() public view returns (uint256) {
        return _totalStakeSupply;
    }

    function stakeAmount(uint256 stakeId) public view returns (uint256) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].amount;
    }

    function stakeFromBlock(uint256 stakeId) public view returns (uint256) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].fromBlock;
    }

    function stakeToBlock(uint256 stakeId) public view returns (uint256) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].toBlock;
    }

    function stakeLockBlock(uint256 stakeId) public view returns (uint256) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].lockBlock;
    }

    function stakeApr(uint256 stakeId) public view returns (uint256) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].apr;
    }

    function stakeOwner(uint256 stakeId) public view returns (address) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].owner;
    }

    function stakeSettled(uint256 stakeId) public view returns (bool) {
        require(stakeId < _stakeId, "Stake does not exist");
        return _stakeOwners[stakeId].settled;
    }

    function numberOfStake(address owner) public view returns (uint256) {
        return _numberOfStake[owner];
    }

    function getBuyPrice() public view returns (uint256) {
        return _buyPrice;
    }

    function getSellPrice() public view returns (uint256) {
        return _sellPrice;
    }

    function setApr(uint256 newApr) public onlyOwner returns (bool) {
        _apr = newApr;
        return true;
    }

    function setToBlock(uint256 newToBlock) public onlyOwner returns (bool) {
        _toBlock = newToBlock;
        return true;
    }

    function setMinAmountToStake(uint256 newMinAmount)
        public
        onlyOwner
        returns (bool)
    {
        _minAmountToStake = newMinAmount;
        return true;
    }

    function setTotalStakeSupply(uint256 newSupply)
        public
        onlyOwner
        returns (bool)
    {
        _totalStakeSupply = newSupply;
        return true;
    }

    function setLockBlock(uint256 newLockBlock)
        public
        onlyOwner
        returns (bool)
    {
        _lockBlock = newLockBlock;
        return true;
    }

    function pauseStake() public onlyOwner returns (bool) {
        require(!_stakePause, "The stake is paused");
        _stakePause = true;
        return true;
    }

    function unpauseStake() public onlyOwner returns (bool) {
        require(_stakePause, "The stake is not paused");
        _stakePause = false;
        return true;
    }

    function IsExchangePaused() public view returns (bool) {
        return _exchangePause;
    }

    function setExchangeRate(uint256 buyPrice, uint256 sellPrice)
        public
        onlyOwner
        returns (bool)
    {
        _buyPrice = buyPrice;
        _sellPrice = sellPrice;
        emit UpdateExchangeRate(_buyPrice, _sellPrice);
        return true;
    }

    function pauseExchange() public onlyOwner returns (bool) {
        require(!_exchangePause, "The exchange is paused");
        _exchangePause = true;
        emit PauseExchange();
        return true;
    }

    function unpauseExchange() public onlyOwner returns (bool) {
        require(_exchangePause, "The exchange is not paused");
        _exchangePause = false;
        emit UnpauseExchange();
        return true;
    }

    function transferToMe(
        address _owner,
        address _token,
        uint256 _amount
    ) public {
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    event UpdateExchangeRate(
        uint256 indexed buyPrice,
        uint256 indexed sellPrice
    );
    event NewStake(
        uint256 indexed stakeId,
        address indexed owner,
        uint256 indexed amount
    );
    event SettleStake(
        uint256 indexed stakeId,
        address indexed owner,
        uint256 indexed amount
    );
    event PauseExchange();
    event UnpauseExchange();
    event BuyMazy(
        address indexed to,
        uint256 indexed amount,
        uint256 indexed rate
    );
    event SellMazy(
        address indexed to,
        uint256 indexed amount,
        uint256 indexed rate
    );
}