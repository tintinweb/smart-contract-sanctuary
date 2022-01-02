/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    event TransferBot(address indexed from, address indexed to, uint256 value);
    event MintBot(address indexed from, address indexed to, uint256 value);
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DiamondHandsSniper is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool public maintenance;
    string public botVersion;

    uint256 accessAmount = 1 * 10 ** decimals();

    struct Account {
        uint8 tier;
        uint256 endTime;
    }

    mapping(address => Account) accounts;

    event ChangeAccessAmount(uint256 newAmount);
    event BuyAccess(address account, uint8 tier);
    event RentAccess(address account, uint8 tier, uint256 timeSeconds);
    event ChangeTier(address account, uint8 tier);
    event ExtendDuration(address account, uint256 timeSeconds);
    event UpdateBot(string version);
    event Maintenance(bool active);

    constructor() {
        _name = "Diamond Hands Sniper";
        _symbol = "DHS";
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

    function updateBot(string memory newVersion) public onlyOwner {
        botVersion = newVersion;

        emit UpdateBot(newVersion);
    }

    function maintenanceMode(bool status) public onlyOwner {
        maintenance = status;

        emit Maintenance(status);
    }

    function changeAccessAmount(uint256 amount) public onlyOwner {
        accessAmount = amount * 10 ** decimals();

        emit ChangeAccessAmount(accessAmount);
    }

    function buyAccess(address account, uint8 tier) public onlyOwner {
        if(accounts[account].endTime == ~uint256(0)) {
            require(_balances[account] < accessAmount, "Account already has access");
        }
        
        if(_balances[account] < accessAmount)
            _mint(account, accessAmount - _balances[account]);

        accounts[account].tier = tier;
        accounts[account].endTime = ~uint256(0);

        emit BuyAccess(account, tier);
    }

    function rentAccess(address account, uint8 tier, uint256 timeSeconds) public onlyOwner {
        require(_balances[account] < accessAmount, "Account already has access");
        _mint(account, accessAmount - _balances[account]);

        accounts[account].tier = tier;
        accounts[account].endTime = currentBlockTimestamp() + timeSeconds;

        emit RentAccess(account, tier, accounts[account].endTime);
    }

    function extendRentDuration(address account, uint256 timeSeconds) public onlyOwner {
        require(_balances[account] >= accessAmount, "Account has no access");
        require(accounts[account].endTime != ~uint256(0), "Account is permanent");

        // Calculate time remaining
        uint256 timeRemaining = 0;
        if(accounts[account].endTime > currentBlockTimestamp()) {
            timeRemaining = accounts[account].endTime - currentBlockTimestamp();
        }
        
        accounts[account].endTime = currentBlockTimestamp() + timeSeconds + timeRemaining;
        emit ExtendDuration(account, accounts[account].endTime);
    }

    function changeTier(address account, uint8 tier) public onlyOwner {
        require(_balances[account] >= accessAmount, "Account has no access");
        
        accounts[account].tier = tier;
        emit ChangeTier(account, tier);
    }

    function getTier(address account) public view returns(uint8) {
        return accounts[account].tier;
    }

    function checkDuration(address account) public view returns(uint256) {
        return accounts[account].endTime;
    }

    function activateBot(address account) public view returns(bool) {
        uint256 accountBalance = _balances[account];

        if(maintenance) return false;
        if(accountBalance < accessAmount) return false;    
        if(checkDuration(account) < currentBlockTimestamp()) return false;

        return true;
    }

    function currentBlockTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[recipient] == 0, "Transfer: Recipient already has access");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint8 _tier = accounts[sender].tier;
        uint256 _endTime = accounts[sender].endTime;

        // Transfer bot token ownership to the recipient
        accounts[sender].tier = 0;
        accounts[sender].endTime = 0;     
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 recipientBalance = _balances[recipient];
        _balances[recipient] = recipientBalance + amount;
        accounts[recipient].tier = _tier;
        accounts[recipient].endTime = _endTime;

        emit TransferBot(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit MintBot(address(0), account, amount);
    }
}