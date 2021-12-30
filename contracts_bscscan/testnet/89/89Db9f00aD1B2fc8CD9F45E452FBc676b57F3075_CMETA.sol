/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
        _transfer(_msgSender(), recipient, amount, 0, address(0));
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
        return _transferFrom(sender, recipient, amount, 0, address(0));
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee,
        address feeReceiveAddress
    ) internal virtual returns (bool) {
        _transfer(sender, recipient, amount, fee, feeReceiveAddress);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        //unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
        //}

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
        //unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        //}

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee,
        address feeReceiveAddress
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(fee >= 0, "ERC20: invalid fee value");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        //unchecked {
        _balances[sender] = senderBalance - amount;
        //}
        uint256 feeValue = 0;
        if (fee > 0) {
            require(
                feeReceiveAddress != address(0),
                "ERC20: Fee receive address is zero"
            );
            feeValue = fee;
            _balances[feeReceiveAddress] += feeValue;
            emit Transfer(sender, feeReceiveAddress, feeValue);
        }
        _balances[recipient] += (amount - feeValue);
        emit Transfer(sender, recipient, (amount - feeValue));

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
        //unchecked {
        _balances[account] = accountBalance - amount;
        //}
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

    uint256[45] private __gap;
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

contract Limiter is Ownable {
    uint256 private _maxBuy;
    uint256 private _maxSell;
    uint256 private _limitBuy;
    mapping(address => uint256) private _totalBuy;

    constructor(
        uint256 maxBuy,
        uint256 maxSell,
        uint256 limitBuy
    ) {
        _maxBuy = maxBuy;
        _maxSell = maxSell;
        _limitBuy = limitBuy;
    }

    function getMaxBuy() public view returns (uint256) {
        return _maxBuy;
    }

    function getMaxSell() public view returns (uint256) {
        return _maxSell;
    }

    function getLimitBuy() public view returns (uint256) {
        return _limitBuy;
    }

    function isValidBuy(address _sender, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (_amount > _maxBuy) {
            return false;
        }
        uint256 totalBuyOfAddress = _totalBuy[_sender];
        if (totalBuyOfAddress + _amount > _limitBuy) {
            return false;
        }
        return true;
    }

    function isValidSell(uint256 _amount) public view returns (bool) {
        if (_amount > _maxSell) {
            return false;
        }
        return true;
    }

    function setMaxBuyLimit(uint256 maxBuy) public onlyOwner {
        _maxBuy = maxBuy;
    }

    function setMaxSellLimit(uint256 maxSell) public onlyOwner {
        _maxSell = maxSell;
    }

    function setLimitBuy(uint256 limitBuy) public onlyOwner {
        _limitBuy = limitBuy;
    }

    function onBuySuccess(address _sender, uint256 _amount) public {
        _totalBuy[_sender] += _amount;
    }

    function onSellSuccess(address _sender, uint256 _amount) public {
        uint256 value = _totalBuy[_sender];
        if (value < _amount) {
            _totalBuy[_sender] = 0;
        } else {
            _totalBuy[_sender] = (value - _amount);
        }
    }

    function getAddressTotalBuy(address _sender) public view returns (int256) {
        return int256(_totalBuy[_sender]);
    }
}

contract CMETA is Ownable, ERC20, Pausable {
    address private _rewardAddress; // For deposit

    address private _feeReceiveAddress; // For fee charge
    uint256 private _buyFee; // Per-mille
    uint256 private _sellFee; // Per-mille

    address private _pancakeLPAddress; // For Fee on Pancake

    Limiter private _limiter;

    address private _lpCreatorAddress;
    bool private _isLockTransferForAntiBot;

    mapping(address => bool) _lpAddresses;

    event Deposit(address from, uint256 amount);
    event Withdraw(address to, uint256 amount);

    constructor() ERC20("CrystalMetaverse", "CMETA") {
        // Buy/Sell fee
        _buyFee = 19 * (10**(decimals() - 1));
        _sellFee = 20 * (10**(decimals() - 1));

        // Address
        _rewardAddress = msg.sender;
        _feeReceiveAddress = msg.sender;
        _pancakeLPAddress = msg.sender;
        _isLockTransferForAntiBot = false;
        _lpCreatorAddress = msg.sender;

        _limiter = new Limiter(
            25000 * (10**decimals()),
            25000 * (10**decimals()),
            5000000 * (10**decimals())
        );

        _mint(msg.sender, 200000000 * 10**decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // BUY/SELL FEE
    function setBuyFee(uint256 fee) public onlyOwner {
        _buyFee = fee;
    }

    function setSellFee(uint256 _fee) public onlyOwner {
        _sellFee = _fee;
    }

    function getFees() external view returns (uint256 buyFee, uint256 sellFee) {
        return (_buyFee, _sellFee);
    }

    // REWARDS:
    function setRewardAddress(address newAddress) public onlyOwner {
        _rewardAddress = newAddress;
    }

    // FEE RECEIVE ADDRESS
    function setFeeReceiveAddress(address addr) public onlyOwner {
        require(addr != address(0), "ERC20: Invalid receive address");
        _feeReceiveAddress = addr;
    }

    function getAddressesData()
        external
        view
        returns (
            address reward,
            address fee,
            address pancakeLP
        )
    {
        return (_rewardAddress, _feeReceiveAddress, _pancakeLPAddress);
    }

    function setMaxBuy(uint256 max) public onlyOwner {
        _limiter.setMaxBuyLimit(max);
    }

    function setMaxSell(uint256 max) public onlyOwner {
        _limiter.setMaxSellLimit(max);
    }

    function setLimitBuy(uint256 _limit) public onlyOwner {
        _limiter.setLimitBuy(_limit);
    }

    function getLimitData()
        external
        view
        returns (
            uint256 maxBuy,
            uint256 maxSell,
            uint256 totalBuy
        )
    {
        return (
            _limiter.getMaxBuy(),
            _limiter.getMaxSell(),
            _limiter.getLimitBuy()
        );
    }

    function getAddressTotalBuy(address _sender)
        public
        view
        virtual
        returns (int256)
    {
        return _limiter.getAddressTotalBuy(_sender);
    }

    function deposit(uint256 amount) external virtual {
        require(
            _rewardAddress != address(0) && _msgSender() != address(0),
            "ERC20: Invalid address"
        );
        transfer(_rewardAddress, amount);
        emit Deposit(_msgSender(), amount);
    }

    function withdraw(address recipient, uint256 amount) external virtual {
        require(
            _msgSender() != address(0) && _msgSender() == _rewardAddress,
            "Invalid sender"
        );
        transfer(recipient, amount);
        emit Withdraw(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(
            !_isLockTransferForAntiBot || sender == _lpCreatorAddress,
            "Antibot revert"
        );
        if (isAddressLP(recipient)) {
            // SELL
            uint256 _fee = 0;
            if (sender != _lpCreatorAddress) {
                require(_limiter.isValidSell(amount), "Sell limit reach");
                _fee = calculateFee(amount, _sellFee);
            }
            return
                _transferFrom(
                    sender,
                    recipient,
                    amount,
                    _fee,
                    _feeReceiveAddress
                );
        }
        return _transferFrom(sender, recipient, amount, 0, address(0));
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (isAddressLP(_msgSender()) || isAddressLP(recipient)) {
            // BUY
            require(
                !_isLockTransferForAntiBot || recipient == _lpCreatorAddress,
                "Antibot revert"
            );
            uint256 _fee = 0;
            if (recipient != _lpCreatorAddress) {
                require(
                    _limiter.isValidBuy(recipient, amount),
                    "Buy limit reach"
                );
                _fee = calculateFee(amount, _buyFee);
                if (isAddressLP(recipient)) {
                    _fee = calculateFee(amount, _sellFee);
                }
            }
            _transfer(
                _msgSender(),
                recipient,
                amount,
                _fee,
                _feeReceiveAddress
            );
            if (recipient != _lpCreatorAddress) {
                _limiter.onBuySuccess(recipient, amount);
            }
        } else {
            require(recipient != address(this), "Failed to transfer");
            _transfer(_msgSender(), recipient, amount, 0, address(0));
        }
        return true;
    }

    function calculateFee(uint256 amount, uint256 _fee)
        private
        view
        returns (uint256)
    {
        uint256 fraction = decimals() + 2;
        return (amount * _fee) / (10**fraction);
    }

    function setLPCreatorAddress(address _addr) external onlyOwner {
        _lpCreatorAddress = _addr;
    }

    function setEnableAntibot(bool enable) external onlyOwner {
        _isLockTransferForAntiBot = enable;
    }

    function getAntibotData()
        external
        view
        returns (bool isEnable, address lpCreator)
    {
        return (_isLockTransferForAntiBot, _lpCreatorAddress);
    }

    function setLPAddress(address _addr, bool enable) external onlyOwner {
        _lpAddresses[_addr] = enable;
    }

    function isAddressLP(address _addr) public view returns (bool) {
        return _lpAddresses[_addr];
    }
}