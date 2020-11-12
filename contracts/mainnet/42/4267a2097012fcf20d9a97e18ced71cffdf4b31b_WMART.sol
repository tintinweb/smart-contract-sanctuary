// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
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

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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


abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = "MINTER";

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
        require(hasRole(_roles[DEFAULT_ADMIN_ROLE].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");
        require(!hasRole(_roles[DEFAULT_ADMIN_ROLE].adminRole, account), "AccessControl: admin cannot grant himself");
        require(DEFAULT_ADMIN_ROLE != role, "AccessControl: cannot grant adminRole");
        _grantRole(role, account);
    }
    
    function transferAdminRole(address account) public virtual {
        require(hasRole(_roles[DEFAULT_ADMIN_ROLE].adminRole, _msgSender()), "AccessControl: sender must be an admin to transfer");
        require(_roles[DEFAULT_ADMIN_ROLE].members.at(0) != account, "AccessControl: admin cannot transfer himself");
        _removeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _removeRole(MINTER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, account);
    }    

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[DEFAULT_ADMIN_ROLE].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");
        require(!hasRole(_roles[DEFAULT_ADMIN_ROLE].adminRole, account), "AccessControl: admin cannot revoke himself");
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        require(!hasRole(_roles[DEFAULT_ADMIN_ROLE].adminRole, account), "AccessControl: admin cannot renounce himself");
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _removeRole(bytes32 role, address account) internal virtual {
        _revokeRole(role, account);
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


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event General(address account);
    
}

contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor () {
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


contract WMART is Context, IERC20, AccessControl, Pausable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    struct stake {
        uint256 col1;
        uint256 prew1;
        uint256 arew1;
        uint256 rrew1;
        uint256 date1;
        uint256 col2;
        uint256 prew2;
        uint256 arew2;
        uint256 rrew2;
        uint256 date2;
        uint256 col3;
        uint256 prew3;
        uint256 arew3;
        uint256 rrew3;
        uint256 date3; 
        uint256 bal;
        address refAdd;
        uint256 refPaid;
        uint256 stakePaid;
    } 
    
    mapping(address =>  stake) private _stake;
    
    string private _name;
    string private _symbol;
    bool private _staking;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    uint256 private _maxTxLimit;
    uint256 private _t1Collateral;
    uint256 private _t2Collateral;
    uint256 private _t3Collateral;
    uint256 private _t1LockTime;
    uint256 private _t2LockTime;
    uint256 private _t3LockTime; 
    uint256 private _rewardDuration;    
    uint256 private _t1Reward;
    uint256 private _t2Reward;
    uint256 private _t3Reward;  
    uint256 private _totalStake;   
    uint256 private _refCom;
    uint256 private _refPaid;
    uint256 private _stakePaid;
  
    constructor () {
        _name = "Wrapped Martkist";
        _symbol = "WMARTK";
        _decimals = 8;
        _maxSupply = 3700000000000000;
        _maxTxLimit = 200;
        _t1Collateral = 100000000000;
        _t2Collateral = 900000000000;
        _t3Collateral = 1800000000000;
        _t1LockTime = 2592000;
        _t2LockTime = 7776000;
        _t3LockTime = 31536000;
        _rewardDuration = 86400;
        _t1Reward = 33000000; 
        _t2Reward = 444000000;
        _t3Reward = 2466000000;
        _staking = true;
        _refCom = 10;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());        
    }    

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }
    
    function isStaking() public view virtual returns (bool) {
       return _staking; 
    } 
    
    function maxTxLimit() public view virtual returns (uint256) {
       return _maxTxLimit; 
    }    

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function allBalance(address account) public view virtual returns (stake memory) { 
        stake memory stb;
        stb = _stake[account];
        stb.arew1 = (block.timestamp.sub(_stake[account].date1)).div(_rewardDuration).mul(_t1Reward).mul(_stake[account].col1.div(_t1Collateral));
        stb.arew2 = (block.timestamp.sub(_stake[account].date2)).div(_rewardDuration).mul(_t2Reward).mul(_stake[account].col2.div(_t2Collateral));
        stb.arew3 = (block.timestamp.sub(_stake[account].date3)).div(_rewardDuration).mul(_t3Reward).mul(_stake[account].col3.div(_t3Collateral));
        stb.date1 = _stake[account].date1.add(_t1LockTime);
        stb.date2 = _stake[account].date2.add(_t2LockTime);
        stb.date3 = _stake[account].date3.add(_t3LockTime);
        stb.bal = _balances[account];
        return stb;
    }   
    
    function stakeDetails() public view virtual returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (_t1Collateral, _t1Reward, _t1LockTime, _t2Collateral, _t2Reward, _t2LockTime, _t3Collateral, _t3Reward, _t3LockTime, _rewardDuration, _totalStake, _staking);
    }
    
    function generalDetails() public view virtual returns (string memory, string memory, uint256, uint256, uint256, bool, uint256, uint256, uint256) {
        return (_name, _symbol, _decimals, _totalSupply, _maxSupply, paused(), _refCom, _refPaid, _stakePaid);
    }    
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    
    
    function stakingPause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Only ADMIN can pause staking");
        require(_staking, "Staking: paused already");
        _staking = false;
        emit General(_msgSender());
    }

    function stakingUnpause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Only ADMIN can unpause staking");
        require(!_staking, "Staking: unpaused already");
        _staking = true;
        emit General(_msgSender());
    }     
    
    function totalStakeBalance() public view virtual returns (uint256) {
       return _totalStake; 
    }  
    
    function generalConfig(uint256 no, uint256 value) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only ADMIN can change config");
        if(no == 1){
            require(value >= _totalSupply, "Value is less than _totalSupply");    
            _maxSupply = value;
        } else if(no == 2){
            _maxTxLimit = value;  
        } else if(no == 3){
            _refCom = value;
        }
        emit General(_msgSender());
    }
 
    function stakeConfig(uint256 no, uint256 value) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only ADMIN can change config");
        if(no == 1){    
            _t1Collateral = value;
        } else if(no == 2){
            _t1Reward = value; 
        } else if(no == 3){
            _t1LockTime = value;  
        } else if(no == 4){    
            _t2Collateral = value;
        } else if(no == 5){
            _t2Reward = value; 
        } else if(no == 6){
            _t2LockTime = value;  
        } else if(no == 7){    
            _t3Collateral = value;
        } else if(no == 8){
            _t3Reward = value; 
        } else if(no == 9){
            _t3LockTime = value;  
        } else if(no == 10){
            _rewardDuration = value; 
        }
        emit General(_msgSender());
    }    
    
    function increaseStake(uint256 tier, address refAdd) public virtual {
        require(tier < 4 && tier > 0, "Staking Tier Not Available");
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(_staking, "Staking: paused");        
        uint256 stakeAmount = 0;
        uint256 stakeReward = 0;
        uint256 collateral = 0;
        uint256 reward = 0;
        uint256 preward = 0;
        uint256 diff = 0;
        uint256 refRew = 0;
        if(_stake[_msgSender()].refAdd == 0x0000000000000000000000000000000000000000 && refAdd != 0x0000000000000000000000000000000000000000 && refAdd != _msgSender()){
            _stake[_msgSender()].refAdd = refAdd;
        }         
        if(tier == 1){
            require(_stake[_msgSender()].col1 > 0, "Not Staking");
            collateral = _t1Collateral;
            reward = _t1Reward;
            preward = _stake[_msgSender()].prew1;
            stakeAmount = _stake[_msgSender()].col1;
            diff = (block.timestamp.sub(_stake[_msgSender()].date1)).div(_rewardDuration);
            refRew = _t1LockTime.div(_rewardDuration).mul(_t1Reward).mul(_refCom).div(100);
            _balances[_msgSender()] = _balances[_msgSender()].sub(collateral, "Stake amount exceeds balance");
            stakeReward = diff.mul(reward).mul(stakeAmount.div(collateral)).add(preward);
            uint256 tempReward = diff.mul(reward).mul(stakeAmount.add(collateral).div(collateral)).add(preward);
            require(_totalSupply.add(tempReward) <= _maxSupply, "Exceeds Max Supply, you can't stake more");
            if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
                _stake[_stake[_msgSender()].refAdd].rrew1 = _stake[_stake[_msgSender()].refAdd].rrew1.add(refRew);
            } 
            _stake[_msgSender()].date1 = block.timestamp;
            _stake[_msgSender()].col1 = _stake[_msgSender()].col1.add(collateral);
            _stake[_msgSender()].prew1 = stakeReward;            
        } else if(tier == 2){
            require(_stake[_msgSender()].col2 > 0, "Not Staking");
            collateral = _t2Collateral;
            reward = _t2Reward; 
            preward = _stake[_msgSender()].prew1;
            stakeAmount = _stake[_msgSender()].col2;
            diff = (block.timestamp.sub(_stake[_msgSender()].date2)).div(_rewardDuration);
            refRew = _t2LockTime.div(_rewardDuration).mul(_t2Reward).mul(_refCom).div(100);
            _balances[_msgSender()] = _balances[_msgSender()].sub(collateral, "Stake amount exceeds balance");
            stakeReward = diff.mul(reward).mul(stakeAmount.div(collateral)).add(preward);
            uint256 tempReward = diff.mul(reward).mul(stakeAmount.add(collateral).div(collateral)).add(preward);
            require(_totalSupply.add(tempReward) <= _maxSupply, "Exceeds Max Supply, you can't stake more");    
            if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
                _stake[_stake[_msgSender()].refAdd].rrew2 = _stake[_stake[_msgSender()].refAdd].rrew2.add(refRew);
            } 
            _stake[_msgSender()].date2 = block.timestamp;
            _stake[_msgSender()].col2 = _stake[_msgSender()].col2.add(collateral);
            _stake[_msgSender()].prew2 = stakeReward;            
        } else if(tier == 3){
            require(_stake[_msgSender()].col3 > 0, "Not Staking");
            collateral = _t3Collateral;
            reward = _t3Reward; 
            preward = _stake[_msgSender()].prew1;
            stakeAmount = _stake[_msgSender()].col3;
            diff = (block.timestamp.sub(_stake[_msgSender()].date3)).div(_rewardDuration);
            refRew = _t3LockTime.div(_rewardDuration).mul(_t3Reward).mul(_refCom).div(100);
            _balances[_msgSender()] = _balances[_msgSender()].sub(collateral, "Stake amount exceeds balance");
            stakeReward = diff.mul(reward).mul(stakeAmount.div(collateral)).add(preward);
            uint256 tempReward = diff.mul(reward).mul(stakeAmount.add(collateral).div(collateral)).add(preward);
            require(_totalSupply.add(tempReward) <= _maxSupply, "Exceeds Max Supply, you can't stake more"); 
            if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
                _stake[_stake[_msgSender()].refAdd].rrew3 = _stake[_stake[_msgSender()].refAdd].rrew3.add(refRew);
            }
            _stake[_msgSender()].date3 = block.timestamp;
            _stake[_msgSender()].col3 = _stake[_msgSender()].col3.add(collateral);
            _stake[_msgSender()].prew3 = stakeReward;            
        } 
        if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
            _stake[_stake[_msgSender()].refAdd].refPaid = _stake[_stake[_msgSender()].refAdd].refPaid.add(refRew);
            _refPaid = _refPaid.add(refRew);
        }        
        _totalStake = _totalStake.add(collateral);
        emit Transfer(_msgSender(), address(0), collateral);
    }
    
    function claimStake(uint256 tier) public virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(tier < 4 && tier > 0, "Staking Tier Not Available");
        uint256 stakeAmount = 0;
        uint256 stakeReward = 0;
        uint256 collateral = 0;
        uint256 reward = 0;
        uint256 preward = 0;
        uint256 diff = 0;
        uint256 locktime = 0;
        uint256 rreward = 0;
        if(tier == 1){
            require(_stake[_msgSender()].col1 > 0, "Not Staking");
            require(block.timestamp >= (_stake[_msgSender()].date1 + locktime), "Stake claim date not reached");
            collateral = _t1Collateral;
            reward = _t1Reward;
            preward = _stake[_msgSender()].prew1;
            stakeAmount = _stake[_msgSender()].col1;
            locktime = _t1LockTime;
            diff = (block.timestamp.sub(_stake[_msgSender()].date1)).div(_rewardDuration);
            rreward = _stake[_msgSender()].rrew1;
            _stake[_msgSender()].rrew1 = 0;
            _stake[_msgSender()].col1 = 0;
            _stake[_msgSender()].date1 = 0;
            _stake[_msgSender()].prew1 = 0;            
        } else if(tier == 2){
            require(_stake[_msgSender()].col2 > 0, "Not Staking");
            require(block.timestamp >= (_stake[_msgSender()].date2 + locktime), "Stake claim date not reached");
            collateral = _t2Collateral;
            reward = _t2Reward; 
            preward = _stake[_msgSender()].prew1;
            stakeAmount = _stake[_msgSender()].col2;
            locktime = _t2LockTime;
            diff = (block.timestamp.sub(_stake[_msgSender()].date2)).div(_rewardDuration);
            rreward = _stake[_msgSender()].rrew2;
            _stake[_msgSender()].rrew1 = 0;
            _stake[_msgSender()].col2 = 0;
            _stake[_msgSender()].date2 = 0;
            _stake[_msgSender()].prew2 = 0;            
        } else if(tier == 3){
            require(_stake[_msgSender()].col3 > 0, "Not Staking");
            require(block.timestamp >= (_stake[_msgSender()].date3 + locktime), "Stake claim date not reached");
            collateral = _t3Collateral;
            reward = _t3Reward; 
            preward = _stake[_msgSender()].prew1;
            stakeAmount = _stake[_msgSender()].col3;
            locktime = _t3LockTime;
            diff = (block.timestamp.sub(_stake[_msgSender()].date3)).div(_rewardDuration);
            rreward = _stake[_msgSender()].rrew3;
            _stake[_msgSender()].rrew1 = 0;
            _stake[_msgSender()].col3 = 0;
            _stake[_msgSender()].date3 = 0;
            _stake[_msgSender()].prew3 = 0;            
        }
        stakeReward = diff.mul(reward).mul(stakeAmount.div(collateral)).add(preward).add(rreward);
        if((_totalSupply.add(stakeReward)) > _maxSupply){
            stakeReward = _maxSupply.sub(_totalSupply);
        }
        if(stakeReward.sub(rreward) > 0){
            _stake[_msgSender()].stakePaid = _stake[_msgSender()].stakePaid.add(stakeReward.sub(rreward));
            _stakePaid = _stakePaid.add(stakeReward);
        }
        _totalSupply = _totalSupply.add(stakeReward);
        _balances[_msgSender()] = _balances[_msgSender()].add(stakeAmount.add(stakeReward));
        _totalStake = _totalStake.sub(stakeAmount);        
        emit Transfer(address(0), _msgSender(), stakeAmount.add(stakeReward));
    }    

    function startStake(uint256 tier, address refAdd) public virtual {
        require(tier < 4 && tier > 0, "Staking Tier Not Available");
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(_staking, "Staking: paused");        
        uint256 collateral = 0;
        uint256 tempReward = 0;
        uint256 refRew = 0;
        if(_stake[_msgSender()].refAdd == 0x0000000000000000000000000000000000000000 && refAdd != 0x0000000000000000000000000000000000000000 && refAdd != _msgSender()){
            _stake[_msgSender()].refAdd = refAdd;
        }        
        if(tier == 1){
            require(!(_stake[_msgSender()].col1 > 0), "Already Staking, Use increaseStake");
            collateral = _t1Collateral;
            tempReward = _t1LockTime.div(_rewardDuration).mul(_t1Reward);
            refRew = tempReward.mul(_refCom).div(100);
            _balances[_msgSender()] = _balances[_msgSender()].sub(collateral, "Stake amount exceeds balance");
            require(_totalSupply.add(tempReward) <= _maxSupply, "Exceeds Max Supply, you can't stake more");  
            if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
                _stake[_stake[_msgSender()].refAdd].rrew1 = _stake[_stake[_msgSender()].refAdd].rrew1.add(refRew);
                _refPaid = _refPaid.add(refRew);
            }
            _stake[_msgSender()].date1 = block.timestamp; 
            _stake[_msgSender()].col1 = collateral;            
        } else if(tier == 2){
            require(!(_stake[_msgSender()].col2 > 0), "Already Staking, Use increaseStake");
            collateral = _t2Collateral;
            tempReward = _t2LockTime.div(_rewardDuration).mul(_t2Reward);
            refRew = tempReward.mul(_refCom).div(100);
            _balances[_msgSender()] = _balances[_msgSender()].sub(collateral, "Stake amount exceeds balance");
            require(_totalSupply.add(tempReward) <= _maxSupply, "Exceeds Max Supply, you can't stake more");
            if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
                _stake[_stake[_msgSender()].refAdd].rrew2 = _stake[_stake[_msgSender()].refAdd].rrew2.add(refRew);
                _refPaid = _refPaid.add(refRew);
            }  
            _stake[_msgSender()].date2 = block.timestamp; 
            _stake[_msgSender()].col2 = collateral;            
        } else if(tier == 3){
            require(!(_stake[_msgSender()].col3 > 0), "Already Staking, Use increaseStake");
            collateral = _t3Collateral;
            tempReward = _t3LockTime.div(_rewardDuration).mul(_t3Reward);
            refRew = tempReward.mul(_refCom).div(100);
            _balances[_msgSender()] = _balances[_msgSender()].sub(collateral, "Stake amount exceeds balance");
            require(_totalSupply.add(tempReward) <= _maxSupply, "Exceeds Max Supply, you can't stake more");  
            if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
                _stake[_stake[_msgSender()].refAdd].rrew3 = _stake[_stake[_msgSender()].refAdd].rrew3.add(refRew);
                _refPaid = _refPaid.add(refRew);
            } 
            _stake[_msgSender()].date3 = block.timestamp; 
            _stake[_msgSender()].col3 = collateral;            
        }
        if(_stake[_msgSender()].refAdd != 0x0000000000000000000000000000000000000000){
            _stake[_stake[_msgSender()].refAdd].refPaid = _stake[_stake[_msgSender()].refAdd].refPaid.add(refRew);
            _refPaid = _refPaid.add(refRew);
        }        
        _totalStake = _totalStake.add(collateral);
        emit Transfer(_msgSender(), address(0), collateral);
    }

    
	function transferMulti(address[] memory to, uint256[] memory amount) public virtual {
	    uint256 sum_ = 0;
	    require(!paused(), "ERC20: Token paused by ADMIN");
        require(_msgSender() != address(0), "Transfer from the zero address");
		require(to.length == amount.length, "Address array length not equal to value");
		require(to.length <= _maxTxLimit, "Payout list greater than _maxTxLimit");
        for (uint8 g = 0; g < to.length; g++) {
            require(to[g] != address(0), "Transfer to the zero address");
            sum_ += amount[g];            
        }		
        require(_balances[_msgSender()] >= sum_, "Transfer amount exceeds balance");
		for (uint8 i = 0; i < to.length; i++) {
		    _transfer(_msgSender(), to[i], amount[i]);
		}
	}	
	
	function transferMultiFrom(address sender, address[] memory to, uint256[] memory amount) public virtual {
	    uint256 sum_ = 0;
	    require(!paused(), "ERC20: Token paused by ADMIN");
        require(sender != address(0), "Transfer from the zero address");
		require(to.length == amount.length, "Address array length not equal to amount");
		require(to.length <= _maxTxLimit, "Payout list greater than _maxTxLimit");
        for (uint8 g = 0; g < to.length; g++) {
            require(to[g] != address(0), "Transfer to the zero address");
            sum_ += amount[g];
        }		
        require(_balances[sender] >= sum_, "Transfer amount exceeds balance");
        require(_allowances[sender][_msgSender()] >= sum_, "Transfer amount exceeds allowance");
		for (uint8 i = 0; i < to.length; i++) {
            _transfer(sender, to[i], amount[i]);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount[i], "ERC20: transfer amount exceeds allowance"));
		}
	}
	
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20: Only MINTER can Mint");
        require((_totalSupply.add(amount)) <= _maxSupply, "Exceeds Max Supply");
        _mint(to, amount);
    }
    
    function mintMulti(address[] memory to, uint256[] memory amount) public virtual {
        uint256 sum_ = 0;
        require(!paused(), "ERC20: Token paused by ADMIN");        
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20: Only MINTER can Mint");
		require(to.length == amount.length, "Address array length not equal to amount");
		require(to.length <= _maxTxLimit, "Payout list greater than _maxTxLimit");        
        for (uint8 g = 0; g < to.length; g++) {
            require(to[g] != address(0), "ERC20: mint to the zero address");
            sum_ += amount[g];
        }
        require((_totalSupply.add(sum_)) <= _maxSupply, "Exceeds Max Supply");
		for (uint8 i = 0; i < to.length; i++) {
		    _mint(to[i], amount[i]);
		}        
    }    
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }  
    
    function burnMultiFrom(address[] memory account, uint256[] memory amount) public virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");
		require(account.length == amount.length, "Address array length not equal to amount");
		require(account.length <= _maxTxLimit, "Payout list greater than _maxTxLimit");  
        for (uint8 g = 0; g < account.length; g++) {
            require(account[g] != address(0), "ERC20: burn from the zero address");
            require(_balances[account[g]] >= amount[g], "ERC20: burn amount exceeds balance");
            require(_allowances[account[g]][_msgSender()] >= amount[g], "Transfer amount exceeds allowance");
        }
		for (uint8 i = 0; i < account.length; i++) {
            uint256 decreasedAllowance = allowance(account[i], _msgSender()).sub(amount[i], "ERC20: burn amount exceeds allowance");
            _approve(account[i], _msgSender(), decreasedAllowance);
            _burn(account[i], amount[i]);
		}          
    }     
    
    function pause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Only ADMIN can pause transfer");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Only ADMIN can unpause transfer");
        _unpause();
    }    

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}