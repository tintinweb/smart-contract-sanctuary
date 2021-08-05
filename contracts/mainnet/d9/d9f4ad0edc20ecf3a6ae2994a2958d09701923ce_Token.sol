/**
 *Submitted for verification at Etherscan.io on 2020-05-15
*/

/*
! proof.sol
(c) 2020 Krasava Digital Solutions
Develop by BelovITLab LLC (smartcontract.ru) & Krasava Digital Solutions (krasava.pro)
authors @stupidlovejoy, @sergeytyan
License: MIT 
*/

pragma solidity 0.6.6;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract ERC20DecimalsMock is ERC20 {
    constructor (string memory name, string memory symbol, uint8 decimals) public ERC20(name, symbol) {
        _setupDecimals(decimals);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface OrFeed {
    function getExchangeRate(string calldata from, string calldata to, string calldata venue, uint256 amount) external view returns(uint256);
}

contract Token is ERC20DecimalsMock("PROOF", "PRF", 6), Ownable, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    struct KeyVal {uint256 key; uint256 val;}
    struct User {address referrer; uint32 last_transaction;}
    bytes32 public constant contract_admin = keccak256("CONTRACT_ADMIN");
    bool public ethBuySwitch = true;
    bool public usdtBuySwitch = true;
    address[] public founders;
    address[] public cashiers;
    address[] public managers;
    uint256 private eth_custom_rate;
    uint256 private tether_rate = 1;
    uint256 private project_reward;
    KeyVal[] private days_percent;
    KeyVal[] private refs_percent;
    KeyVal[] private refs_multiply;
    IERC20 public tether = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    OrFeed public orfeed = OrFeed(0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336);
    mapping(address => User) public users;
    event Buy(address indexed addr, uint32 datetime, uint256 balance, uint256 amount);
    event DayPayout(address indexed addr, uint32 datetime, uint256 balance, uint256 amount);
    event RefPayout(address indexed addr, uint32 datetime, uint256 amount);

    modifier onlyFounders() {
        for(uint256 i = 0; i < founders.length; i++) {
            if(founders[i] == msg.sender) {
                _;
                return;
            }
        }
        revert("Access denied");
    }

    constructor() public {    
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(contract_admin, msg.sender);
        founders.push(0x2589171E72A4aaa7b0e7Cc493DB6db7e32aC97d4);
        founders.push(0x3d027e252A275650643cE83934f492B6914D3341);
        founders.push(0xe74400179854ca60bCD0d3dA3BB0A2BA9028FB76);
        founders.push(0x30517CaE41977fc9d4a21e2423b7D5Ce8D19d0cb);
        cashiers.push(0x1411B85AaE2Dc11927566042401a6DE158cE4413);
        managers.push(0x5e646586E572D5D6B44153e81224D26F23B00651);
        days_percent.push(KeyVal(1e6, 10));
        days_percent.push(KeyVal(1e8, 13));
        days_percent.push(KeyVal(5e8, 17));
        days_percent.push(KeyVal(1e9, 22));
        days_percent.push(KeyVal(5e9, 28));
        days_percent.push(KeyVal(1e10, 35));
        days_percent.push(KeyVal(5e10, 43));
        days_percent.push(KeyVal(1e11, 52));
        days_percent.push(KeyVal(5e11, 62));
        days_percent.push(KeyVal(1e12, 0));
        refs_percent.push(KeyVal(1e6, 100));
        refs_percent.push(KeyVal(1e8, 200));
        refs_percent.push(KeyVal(1e9, 300));
        refs_percent.push(KeyVal(1e10, 400));
        refs_percent.push(KeyVal(1e11, 500));
        refs_multiply.push(KeyVal(1e6, 100));
        refs_multiply.push(KeyVal(1e8, 150));
        refs_multiply.push(KeyVal(1e9, 210));
        refs_multiply.push(KeyVal(1e10, 310));
        refs_multiply.push(KeyVal(1e11, 460));
    }
  
    receive() payable external whenNotPaused {
        require(ethBuySwitch, "ETH buy is off");
        _buy(msg.sender, msg.value * this.eth_rate() / tether_rate / 1e12);
    }

    function _findInKeyVal(KeyVal[] memory _arr, uint256 _val) private pure returns(uint256) {
        for(uint8 i = uint8(_arr.length); i > 0; i--) {
            if(_val >= _arr[i - 1].key) {
                return _arr[i - 1].val;
            }
        }
    }
    
    function mintcomp(uint256 _amount) external view returns(uint256) {
        return _amount * this.totalSupply() / 1e15;
    }

    function _timeProfit(address _account) private returns(uint256 value) {
        uint256 balance = this.balanceOf(_account);
        uint256 percent = _findInKeyVal(days_percent, balance);
        value = balance > 0 && percent > 0 ? (block.timestamp - users[_account].last_transaction) * balance * percent / 10000 / 1 days : 0;
        if(value > 0 && users[_account].last_transaction > 0) {
            value -= this.mintcomp(value);
            uint256 min = (block.timestamp - users[_account].last_transaction) * balance * 100 / 10000 / 30 days;
            if(value < min) value = min;
            users[_account].last_transaction = uint32(block.timestamp);
            _mint(_account, value);
            emit DayPayout(_account, users[_account].last_transaction, balance, value);
        }
    }

    function _refReward(address _referal, address _referrer, uint256 _amount) private returns(uint256 value) {
        uint256 percent = _findInKeyVal(refs_percent, this.balanceOf(_referal));
        uint256 multiply = _findInKeyVal(refs_multiply, this.balanceOf(_referrer));
        if(percent > 0 && multiply > 0) {
            value = _amount * percent * multiply / 1000000;
            value -= this.mintcomp(value);
            uint256 min = _amount / 100;            
            if(value < min) value = min;            
            _mint(_referrer, value);
            emit RefPayout(_referrer, uint32(block.timestamp), value);
        }
    }

    function _beforeTokenTransfer(address _from, address _to, uint256) internal override {
        if(_from != address(0)) {
            uint256 f_profit = _timeProfit(_from);
            if(f_profit > 0 && users[_from].referrer != address(0)) {
                _refReward(_from, users[_from].referrer, f_profit);
            }            
        }
        if(_from != _to) {
            uint256 t_profit = _timeProfit(_to);
            if(t_profit > 0 && users[_to].referrer != address(0)) {
                _refReward(_to, users[_to].referrer, t_profit);
            }
            if(users[_to].referrer == address(0) && _from != address(0)) {
                users[_to].referrer = _from;
            }
            if(users[_to].last_transaction == 0) users[_to].last_transaction = uint32(block.timestamp);
        }
    }
    
    function _buy(address _to, uint256 _amount) private {
        require(_amount > 0, "Zero amount");
        _mint(_to, _amount);
        emit Buy(_to, uint32(block.timestamp), this.balanceOf(_to), _amount);
    }

    function eth_buy_switch(bool _value) external {
        require(hasRole(contract_admin, msg.sender), "Caller is not a CONTRACT ADMIN");
        ethBuySwitch = _value;
    }

    function usd_buy_switch(bool _value) external {
        require(hasRole(contract_admin, msg.sender), "Caller is not a CONTRACT ADMIN");
        usdtBuySwitch = _value;
    }

    function eth_buy() external payable whenNotPaused {
        require(ethBuySwitch, "ETH buy is off");
        _buy(msg.sender, msg.value * this.eth_rate() / tether_rate / 1e12);
    }

    function usdt_buy(uint256 _value) external whenNotPaused {
        require(usdtBuySwitch, "Tether buy is off");
        tether.safeTransferFrom(msg.sender, address(this), _value);
        _buy(msg.sender, _value / tether_rate);
    }

    function eth_rate_set(uint256 _value) external onlyFounders {
        eth_custom_rate = _value;
    }

    function usdt_rate_set(uint256 _value) external onlyFounders {
        tether_rate = _value;
    }

    function eth_rate_up(uint256 _value) external {
        require(hasRole(contract_admin, msg.sender), "Caller is not a CONTRACT ADMIN");
        eth_custom_rate = _value > eth_custom_rate ? _value : eth_custom_rate;
    }

    function usdt_rate_up(uint256 _value) external {
        require(hasRole(contract_admin, msg.sender), "Caller is not a CONTRACT ADMIN");
        tether_rate = _value > tether_rate ? _value : tether_rate;
    }

    function eth_rate() external view returns(uint256) {
        return eth_custom_rate > 0 ? eth_custom_rate : orfeed.getExchangeRate("ETH", "USDC", "DEFAULT", 1e12);
    }

    function usdt_rate() external view returns(uint256) {
        return tether_rate;
    }

    function eth_balance() external view returns(uint256) {
        return address(this).balance;
    }

    function usdt_balance() external view returns(uint256) {
        return tether.balanceOf(address(this));
    }
    
    function balance() external view returns(uint256, uint256) {
        return (address(this).balance, tether.balanceOf(address(this)));
    }

    function managers_set(uint256 _index, address _account) external onlyFounders {
        if(managers.length > _index) {
            if(_account == address(0)) {
                for(uint256 i = 0; i < managers.length - 1; i++) {
                    if(i < _index) {
                        managers[i] = managers[i];
                    }
                    else managers[i] = managers[i + 1];
                }
                managers.pop();
            }
            else managers[_index] = _account;
        }
        else {
            require(_account != address(0), "Zero address");
            managers.push(_account);
        }
    }

    function cashiers_set(uint256 _index, address _account) external onlyFounders {
        if(cashiers.length > _index) {
            if(_account == address(0)) {
                for(uint256 i = 0; i < cashiers.length - 1; i++) {
                    if(i < _index) {
                        cashiers[i] = cashiers[i];
                    }
                    else cashiers[i] = cashiers[i + 1];
                }
                cashiers.pop();
            }
            else cashiers[_index] = _account;
        }
        else {
            require(_account != address(0), "Zero address");
            cashiers.push(_account);
        }
    }
    
    function prf_reward() external onlyFounders {
        require(this.totalSupply() - project_reward >= 1e6, "Not enough totalSuply");
        uint256 value = (this.totalSupply() - project_reward) / 200;
        for(uint8 i = 0; i < founders.length; i++) {
            _mint(founders[i], value / founders.length);
        }
        for(uint8 i = 0; i < managers.length; i++) {
            _mint(managers[i], value / managers.length);
        }
        project_reward = this.totalSupply();
    }

    function eth_withdraw(uint256 _value) external onlyFounders {
        require(address(this).balance >= 1e6, "Not enough ETH");
        uint256 value = (_value > 0 ? _value : address(this).balance) / 2;
        for(uint8 i = 0; i < founders.length; i++) {
            payable(founders[i]).transfer(value / founders.length);
        }
        for(uint8 i = 0; i < cashiers.length; i++) {
            payable(cashiers[i]).transfer(value / cashiers.length);
        }
    }
    
    function usdt_withdraw(uint256 _value) external onlyFounders {
        require(tether.balanceOf(address(this)) >= 1e6, "Not enough USDT");
        uint256 value = (_value > 0 ? _value : tether.balanceOf(address(this))) / 2;
        for(uint8 i = 0; i < founders.length; i++) {
            tether.safeTransfer(founders[i], value / founders.length);
        }
        for(uint8 i = 0; i < cashiers.length; i++) {
            tether.safeTransfer(cashiers[i], value / cashiers.length);
        }
    }
    
    function pause() external onlyFounders {
        _pause();
    }

    function unpause() external onlyFounders {
        _unpause();
    }
    
    function burn(uint256 _amount) external{
        _burn(msg.sender, _amount);
    }
}