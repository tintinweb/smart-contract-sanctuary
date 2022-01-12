// SPDX-License-Identifier: none

pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: none

pragma solidity >=0.8.0 <0.9.0;

import "Context.sol";

abstract contract Managable is Context {
    address private _owner;

    mapping (address => bool) private _Admin;

    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    event BecomeAdministrator(
        address indexed admin,
        bool indexed fact
    );
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _Admin[msgSender] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    function isAdministrator(
        address user
    ) public view virtual returns (bool) {
        return _Admin[user];
    }

    function addAdmin(
        address user
    ) external virtual onlyOwner{
        _Admin[user] = true;

        emit BecomeAdministrator(
            user,
            true
        );
    }

    function removeAdmin(
        address user
    ) external virtual onlyOwner{
        _Admin[user] = false;

        emit BecomeAdministrator(
            user,
            false
        );
    }

    modifier onlyOwner() {
        require(
            getOwner() == _msgSender(),
            "Managable: caller is not the owner"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            isAdministrator(
                _msgSender()
            ),
            "Managable: caller is not the administrator"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0), 
            "Managable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: none

pragma solidity >=0.8.0 <0.9.0;

import "Managable.sol";

abstract contract Restrictable is Managable{
    event Paused(address account);
    event Unpaused(address account);
    event UserBanned(
        address[] indexed user,
        bool indexed status
    );
    event UserRestricted(
        address[] indexed user,
        bool indexed status
    );
    event UserLocked(
        address[] indexed user,
        uint256 indexed deadline
    );
    event LimitSetting(
        bool indexed status,
        uint256 indexed amount,
        uint256 indexed delay
    );

    struct limit{
        uint256 limitAmount;
        uint256 delay;
    }

    mapping (address => bool) private _banned;
    mapping (address => uint256) private _waitUntil;
    mapping (address => uint256) private _totalWhitelist;
    mapping (address => mapping (uint256 => address)) private _whitelistDestination;

    bool private _paused;
    limit private _txLimit;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function limitInfo() public view virtual returns (limit memory){
        return _txLimit;
    }

    function isBanned(
        address user
    ) public view virtual returns (bool) {
        return _banned[user];
    }

    function _userTxDelay(
        address user
    ) internal view virtual returns (uint256) {
        return _waitUntil[user];
    }

    function userTotalWhitelist(
        address user
    ) public view virtual returns (uint256) {
        return _totalWhitelist[user];
    }

    function userWhitelistView(
        address user,
        uint256 index
    ) public view virtual returns (address) {
        return _whitelistDestination[user][index];
    }

    modifier whenNotPaused() {
        require(!paused(), "Restrictable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Restrictable: not paused");
        _;
    }

    modifier whenNotBanned() {
        require(
            !isBanned(
                _msgSender()
            ),
            "Restrictable: caller is banned"
        );
        _;
    }

    modifier whenRestricted(address dest){
        if(userTotalWhitelist(_msgSender()) > 0){
            bool continueTx;

            for(uint256 a = 0; a < userTotalWhitelist(_msgSender()); a++){
                if(dest == userWhitelistView(_msgSender(), a)){
                    continueTx = true;
                }
            }

            require(
                continueTx,
                "Restrictable: caller is restricted"
            );
        }
        _;
    }

    modifier whenLimited(uint256 amount){
        if(limitInfo().limitAmount > 0){
            require(
                amount <= limitInfo().limitAmount,
                "Restrictable: transaction amount is limited"
            );
        }

        require(
            block.timestamp > _userTxDelay(_msgSender()),
            "Restrictable: wait until unlocked"
        );

        _;

        if(limitInfo().delay > 0){
            _waitUntil[_msgSender()] = block.timestamp + limitInfo().delay;
        }
    }

    function bannedUser(
        address[] memory user
    ) external virtual onlyAdmin{
        for(uint256 a = 0; a < user.length; a++){
            _banned[user[a]] = true;
        }

        emit UserBanned(
            user,
            true
        );
    }

    function lockUser(
        address[] memory user,
        uint256 deadline
    ) external virtual onlyAdmin{
        for(uint256 a = 0; a < user.length; a++){
            _waitUntil[user[a]] = deadline;
        }

        emit UserLocked(
            user,
            deadline
        );
    }

    function restrictUser(
        address[] memory user,
        address[] memory whitelist
    ) external virtual onlyAdmin{
        for(uint256 a = 0; a < user.length; a++){
            for(uint256 b = 0; b < whitelist.length; b++){
                _whitelistDestination[user[a]][b] = whitelist[b];
            }

            _totalWhitelist[user[a]] = whitelist.length;
        }

        emit UserRestricted(
            user,
            true
        );
    }

    function unbannedUser(
        address[] memory user
    ) external virtual onlyAdmin{
        for(uint256 a = 0; a < user.length; a++){
            _banned[user[a]] = false;
        }

        emit UserBanned(
            user,
            false
        );
    }

    function unlockUser(
        address[] memory user
    ) external virtual onlyAdmin{
        for(uint256 a = 0; a < user.length; a++){
            _waitUntil[user[a]] = 0;
        }

        emit UserLocked(
            user,
            0
        );
    }

    function unrestrictUser(
        address[] memory user
    ) external virtual onlyAdmin{
        for(uint256 a = 0; a < user.length; a++){
            for(uint256 b = 0; b < _totalWhitelist[user[a]]; b++){
                _whitelistDestination[user[a]][b] = address(0);
            }

            _totalWhitelist[user[a]] = 0;
        }
        
        emit UserRestricted(
            user,
            false
        );
    }

    function setLimit(
        uint256 amount,
        uint256 delays
    ) external virtual onlyAdmin {
        require(
            _txLimit.limitAmount == 0 &&
            _txLimit.delay == 0,
            "Restrictable: already limited"
        );

        _txLimit = limit(
            amount,
            delays
        );

        emit LimitSetting(
            true,
            amount,
            delays
        );
    }

    function unsetLimit() external virtual onlyAdmin {
        require(
            _txLimit.limitAmount > 0 &&
            _txLimit.delay > 0,
            "Restrictable: already unlimited"
        );

        _txLimit = limit(
            0,
            0
        );

        emit LimitSetting(
            false,
            0,
            0
        );
    }

    function pause() external virtual whenNotPaused onlyAdmin {
        _paused = true;
        emit Paused(address(this));
    }
    
    function unpause() external virtual whenPaused onlyAdmin {
        _paused = false;
        emit Unpaused(address(this));
    }
}

// SPDX-License-Identifier: none

pragma solidity >=0.8.0 <0.9.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
    
    function symbol() external view returns (string memory);
    
    function name() external view returns (string memory);
    
    function balanceOf(
        address account
    ) external view returns (uint256);
    
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);
    
    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: none

import "Restrictable.sol";
import "IBEP20.sol";

pragma solidity >=0.8.0 <0.9.0;

contract ProtectProcotol is Restrictable, IBEP20{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply += supply_;
        _balances[_msgSender()] += supply_;

        emit Transfer(address(0), _msgSender(), supply_);
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

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IBEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "IBEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function userLimitInfo(
        address account
    ) public view virtual returns (uint256, uint256) {
        unchecked{
            uint256 limitAmount;
            uint256 limitTime;

            if(limitInfo().limitAmount > 0){
                if(balanceOf(account) >= limitInfo().limitAmount){
                    limitAmount = limitInfo().limitAmount;
                }else{
                    limitAmount = balanceOf(account);
                }
            }

            if(block.timestamp < _userTxDelay(account)){
                limitTime = _userTxDelay(account);
            }

            return(
                limitAmount,
                limitTime
            );
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual whenNotPaused whenNotBanned whenRestricted(recipient) whenLimited(amount){
        require(sender != address(0), "IBEP20: transfer from the zero address");
        require(recipient != address(0), "IBEP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "IBEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual whenNotPaused onlyAdmin {
        require(account != address(0), "IBEP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "IBEP20: burn amount exceeds balance");
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
    ) internal virtual whenNotPaused whenNotBanned whenRestricted(spender){
        require(owner != address(0), "IBEP20: approve from the zero address");
        require(spender != address(0), "IBEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}