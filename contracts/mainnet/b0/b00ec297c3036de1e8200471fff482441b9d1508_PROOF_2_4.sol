/**
 *Submitted for verification at Etherscan.io on 2020-05-20
*/

/*
! proof2.4.sol
Proof Ethereum Token v 2.4
(c) 2020 Krasava Digital Solutions
Develop by Krasava Digital Solutions (krasava.pro) & BelovITLab LLC (smartcontract.ru)
authors @sergeytyan & @stupidlovejoy
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
interface EthRateInterface {
    function EthToUsdRate() external view returns(uint256);
}
contract PROOF_2_4 is ERC20DecimalsMock("PROOF", "PRF", 6), Ownable, AccessControl, Pausable {
    using SafeERC20 for IERC20;
    struct User {address user_referer; uint32 last_transaction; uint256 user_profit;}
    bytes32 public constant contractAdmin = keccak256("contractAdmin");
    bool public ethBuyOn = true;
    bool public usdtBuyOn = true;
    bool public daiBuyOn = true;
    address[] public founders;
    address[] public cashiers;
    address[] public managers;
    uint256 private eth_custom_rate = 1000000;
    uint256 private usd_rate = 100;
    uint256 private fixed_total_suply;
    IERC20 public daiToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public usdtToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    EthRateInterface public EthRateSource = EthRateInterface(0x9dd4C0a264B53e26B61Fa27922Ac4697f0b9dD8b);
    event ProfitPayout(uint32 timestamp, address indexed addr, uint256 amount);
    event TimeProfit(uint32 timestamp, address indexed addr, uint32 last, uint256 balance, uint256 percent, uint256 tax, uint256 reward, uint256 total);
    event ReferalProfit(uint32 timestamp, address indexed addr, uint256 profit, uint256 balance, uint256 percent, uint256 tax,uint256 reward, uint256 total);
    mapping(address => User) public users;
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
        _setupRole(contractAdmin, msg.sender);
        _setupRole(contractAdmin, 0x2589171E72A4aaa7b0e7Cc493DB6db7e32aC97d4);
        _setupRole(contractAdmin, 0x3d027e252A275650643cE83934f492B6914D3341);
        _setupRole(contractAdmin, 0xe74400179854ca60bCD0d3dA3BB0A2BA9028FB76);
        _setupRole(contractAdmin, 0x30517CaE41977fc9d4a21e2423b7D5Ce8D19d0cb);
        _setupRole(contractAdmin, 0x5e646586E572D5D6B44153e81224D26F23B00651);
        founders.push(0x2589171E72A4aaa7b0e7Cc493DB6db7e32aC97d4);
        founders.push(0x3d027e252A275650643cE83934f492B6914D3341);
        founders.push(0xe74400179854ca60bCD0d3dA3BB0A2BA9028FB76);
        founders.push(0x30517CaE41977fc9d4a21e2423b7D5Ce8D19d0cb);
        cashiers.push(0x1411B85AaE2Dc11927566042401a6DE158cE4413);
        managers.push(0x5e646586E572D5D6B44153e81224D26F23B00651);
    }
    receive() payable external whenNotPaused {
        require(ethBuyOn, "ETH buy is off");
        require(this.ethRate() > 0, "Set ETH rate first");
        _buy(msg.sender, msg.value * this.ethRate() * 100 / usd_rate / 1e18);
    }
    function mintTax(uint256 _amount) external view returns(uint256) {
        return _amount * this.totalSupply() / 1e15;
    }
    function _timeProfit(address _account) private returns(uint256 value) {
        if(users[_account].last_transaction > 0) {
            uint256 balance = this.balanceOf(_account);
            uint256 percent = 0;                
            if(balance >= 1e7 && balance < 1e8) percent = 10;
            if(balance >= 1e8 && balance < 5e8) percent = 13;
            if(balance >= 5e8 && balance < 1e9) percent = 17;
            if(balance >= 1e9 && balance < 5e9) percent = 22;
            if(balance >= 5e9 && balance < 11e10) percent = 28;
            if(balance >= 1e10 && balance < 5e10) percent = 35;
            if(balance >= 5e10 && balance < 1e11) percent = 43;
            if(balance >= 1e11 && balance < 5e11) percent = 52;
            if(balance >= 5e11 && balance < 1e12) percent = 62;
            value = balance > 0 && percent > 0 ? (block.timestamp - users[_account].last_transaction) * balance * percent / 10000 / 1 days : 0;
            if(value > 0) {
                value -= this.mintTax(value);
                uint256 min = (block.timestamp - users[_account].last_transaction) * balance / 100 / 30 days;
                if(value < min) value = min;
                users[_account].user_profit += value;
            }
            emit TimeProfit(uint32(block.timestamp), _account, users[_account].last_transaction, balance, percent, this.mintTax(value), value, users[_account].user_profit);
        }
        users[_account].last_transaction = uint32(block.timestamp);
    }
    function _refReward(address _referer, uint256 _amount) private returns(uint256 value) {
        uint256 balance = this.balanceOf(_referer);
        uint256 percent = 0;
        if(balance >= 1e8 && balance < 1e9) percent = 520;
        if(balance >= 1e9 && balance < 1e10) percent = 750;
        if(balance >= 1e10 && balance < 1e11) percent = 1280;
        if(balance >= 1e11 && balance < 1e12) percent = 2650;
        if(percent > 0) {
            value = _amount * percent / 10000;
            value -= this.mintTax(value);
            uint256 min = _amount / 100;
            if(value < min) value = min;
            users[_referer].user_profit += value;
        }
        emit ReferalProfit(uint32(block.timestamp), _referer, _amount, balance, percent, this.mintTax(value), value, users[_referer].user_profit);
    }
    function _profitPayout(address _account) private returns(uint256) {
        uint256 userProfit = users[_account].user_profit;
        users[_account].user_profit = 0;
        if(userProfit > 0) {
            _mint(_account, userProfit);
        }
        emit ProfitPayout(uint32(block.timestamp), _account, userProfit);
    }
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        if(_from != address(0)) {
            uint256 f_profit = _timeProfit(_from);
            if(f_profit > 0 && users[_from].user_referer != address(0)) _refReward(users[_from].user_referer, f_profit);         
        }
        if(_from != _to) {
            uint256 t_profit = _timeProfit(_to);
            if(t_profit > 0 && users[_to].user_referer != address(0)) _refReward(users[_to].user_referer, t_profit);
            if(users[_to].user_referer == address(0) && _from != address(0) && users[_from].user_referer != _to && _amount > 0) users[_to].user_referer = _from; 
            if(users[_to].last_transaction == 0) users[_to].last_transaction = uint32(block.timestamp);
        } else {
            _profitPayout(_from);
        }
    }
    function _buy(address _account, uint256 _amount) private {
        require(_amount > 0, "Zero amount");
        _mint(_account, _amount);
    }
    function ethBuySwitch(bool _value) external {
        require(hasRole(contractAdmin, msg.sender), "Caller is not a CONTRACT ADMIN");
        ethBuyOn = _value;
    }
    function usdtBuySwitch(bool _value) external {
        require(hasRole(contractAdmin, msg.sender), "Caller is not a CONTRACT ADMIN");
        usdtBuyOn = _value;
    }
    function daiBuySwitch(bool _value) external {
        require(hasRole(contractAdmin, msg.sender), "Caller is not a CONTRACT ADMIN");
        daiBuyOn = _value;
    }
    function ethBuy() external payable whenNotPaused {
        require(ethBuyOn, "ETH buy is off");
        require(this.ethRate() > 0, "Set ETH rate first");
        _buy(msg.sender, msg.value * this.ethRate() * 100 / usd_rate / 1e18);
    }
    function usdtBuy(uint256 _value) external whenNotPaused {
        require(usdtBuyOn, "Tether buy is off");
        usdtToken.safeTransferFrom(msg.sender, address(this), _value);
        _buy(msg.sender, _value * 100 / usd_rate);
    }
    function daiBuy(uint256 _value) external whenNotPaused {
        require(daiBuyOn, "DAI buy is off");
        daiToken.safeTransferFrom(msg.sender, address(this), _value);
        _buy(msg.sender, _value * 100 / usd_rate / 1e12);
    }
    function ethRateSet(uint256 _value) external onlyFounders {
        eth_custom_rate = _value;
    }
    function usdRateSet(uint256 _value) external onlyFounders {
        require(_value > 100, "Wrong rate");
        usd_rate = _value;
    }
    function ethRateUp(uint256 _value) external {
        require(hasRole(contractAdmin, msg.sender), "Caller is not a CONTRACT ADMIN");
        require(eth_custom_rate > _value, "Wrong rate");
        eth_custom_rate = _value;
    }
    function usdRateUp(uint256 _value) external {
        require(hasRole(contractAdmin, msg.sender), "Caller is not a CONTRACT ADMIN");
        require(_value > usd_rate, "Wrong rate");
        usd_rate = _value;
    }
    function ethRateAddr(address _source) external onlyFounders {
        EthRateSource = EthRateInterface(_source);
    }
    function setDefaultReferer() external {
        users[msg.sender].user_referer = address(this);
    }
    function ethRate() external view returns(uint256) {
        uint256 ext_rate = EthRateSource.EthToUsdRate();
        return ext_rate > 0 && eth_custom_rate > ext_rate ? ext_rate : eth_custom_rate;
    }
    function usdRate() external view returns(uint256) {
        return usd_rate;
    }
    function onBoardBounty() external view returns(uint256) {
        return (this.totalSupply() - fixed_total_suply) / 100;
    }
    function onBoardPRF() external view returns(uint256) {
        return this.balanceOf(address(this));
    }
    function onBoardETH() external view returns(uint256) {
        return address(this).balance;
    }
    function onBoardUSDT() external view returns(uint256) {
        return usdtToken.balanceOf(address(this));
    }
    function onBoardDAI() external view returns(uint256) {
        return daiToken.balanceOf(address(this));
    }
    function onBoard() external view returns(uint256 proofs, uint256 ethers, uint256 tethers, uint256 dais) {
        return ((this.totalSupply() - fixed_total_suply) / 100, address(this).balance, usdtToken.balanceOf(address(this)), daiToken.balanceOf(address(this)));
    }
    function userInfo() external view returns(address referer, uint256 balance, uint256 last_transaction, uint256 profit) {
        return (users[msg.sender].user_referer, this.balanceOf(msg.sender), users[msg.sender].last_transaction, users[msg.sender].user_profit);
    }
    function setManagers(uint256 _index, address _account) external onlyFounders {
        if(managers.length > _index) {
            if(_account == address(0)) {
                for(uint256 i = 0; i < managers.length - 1; i++) {
                    managers[i] = i < _index ? managers[i] : managers[i + 1];
                }
                managers.pop();
            } else managers[_index] = _account;
        } else {
            require(_account != address(0), "Zero address");
            managers.push(_account);
        }
    }
    function setCashiers(uint256 _index, address _account) external onlyFounders {
        if(cashiers.length > _index) {
            if(_account == address(0)) {
                for(uint256 i = 0; i < cashiers.length - 1; i++) {
                    cashiers[i] =  i < _index ? cashiers[i] : cashiers[i + 1];
                }
                cashiers.pop();
            } else cashiers[_index] = _account;
        } else {
            require(_account != address(0), "Zero address");
            cashiers.push(_account);
        }
    }
    function getProfit() external {
        require(users[msg.sender].user_profit > 0, "This account has no PROFIT");
        _profitPayout(msg.sender);
    }
    function getProofs() external {
        require(this.balanceOf(address(this)) - founders.length > 1e8, "Not enougth PRF");
        uint256 amount = this.balanceOf(address(this)) - 1e8;
        for(uint8 i = 0; i < founders.length; i++) {
            _transfer(address(this), founders[i], amount / founders.length);
        }
    }
    function getBounties() external onlyFounders {
        require((this.totalSupply() - fixed_total_suply) / 200 > founders.length, "Not enougth PRF");
        require((this.totalSupply() - fixed_total_suply) / 200 > managers.length, "Not enougth PRF");
        uint256 amount = (this.totalSupply() - fixed_total_suply) / 200;
        for(uint8 i = 0; i < founders.length; i++) {
            _mint(founders[i], amount / founders.length);
        }
        for(uint8 i = 0; i < managers.length; i++) {
            _mint(managers[i], amount / managers.length);
        }
        fixed_total_suply = this.totalSupply();
    }
    function getEthers() external onlyFounders {
        require(address(this).balance / 2 > founders.length, "Not enougth ETH");
        require(address(this).balance / 2 > cashiers.length, "Not enougth ETH");
        uint256 amount = address(this).balance / 2;
        for(uint8 i = 0; i < founders.length; i++) {
            payable(founders[i]).transfer(amount / founders.length);
        }
        for(uint8 i = 0; i < cashiers.length; i++) {
            payable(cashiers[i]).transfer(amount / cashiers.length);
        }
    }
    function getTethers() external onlyFounders {
        require(usdtToken.balanceOf(address(this)) / 2 > founders.length, "Not enougth USDT");
        require(usdtToken.balanceOf(address(this)) / 2 > cashiers.length, "Not enougth USDT");
        uint256 amount = usdtToken.balanceOf(address(this)) / 2;
        for(uint8 i = 0; i < founders.length; i++) {
            usdtToken.safeTransfer(founders[i], amount / founders.length);
        }
        for(uint8 i = 0; i < cashiers.length; i++) {
            usdtToken.safeTransfer(cashiers[i], amount / cashiers.length);
        }
    }
    function getDais() external onlyFounders {
        require(daiToken.balanceOf(address(this)) / 2 > founders.length, "Not enougth DAI");
        require(daiToken.balanceOf(address(this)) / 2 > cashiers.length, "Not enougth DAI");
        uint256 amount = daiToken.balanceOf(address(this)) / 2;
        for(uint8 i = 0; i < founders.length; i++) {
            daiToken.safeTransfer(founders[i], amount / founders.length);
        }
        for(uint8 i = 0; i < cashiers.length; i++) {
            daiToken.safeTransfer(cashiers[i], amount / cashiers.length);
        }
    }
    function pauseOn() external onlyFounders {
        _pause();
    }
    function pauseOff() external onlyFounders {
        _unpause();
    }
    function burn(uint256 _amount) external{
        _burn(msg.sender, _amount);
    }
}