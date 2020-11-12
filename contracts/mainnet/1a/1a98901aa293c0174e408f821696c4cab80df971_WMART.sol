// SPDX-License-Identifier: MIT

pragma solidity ^0.7;

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

    event Stake(address account);    

    event Config(address account); 
    
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
        uint256 timestamp;
        uint256 stakeAmount;
    }
    
    mapping(address => stake) private _stake;

    string private _name;
    string private _symbol;
    bool private _staking;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _reward;
    uint256 private _rewardDuration;
    uint256 private _collateral;
    uint256 private _maxSupply;
    uint256 private _lockTime;
    uint256 private _totalStake;
    uint256 private _maxTxLimit;
  
    constructor () {
        _name = "Wrapped Martkist";
        _symbol = "WMARTK";
        _decimals = 8;
        _maxSupply = 3700000000000000;
        _reward = 1200000000;
        _rewardDuration = 86400;
        _collateral = 1800000000000; 
        _lockTime = 2592000;
        _maxTxLimit = 200;
        _staking = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());        
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
    
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
    
    function reward() public view returns (uint256) {
        return _reward;
    }

    function collateral() public view returns (uint256) {
        return _collateral;
    }

    function rewardDuration() public view returns (uint256) {
        return _rewardDuration;
    }
    
    function lockTime() public view returns (uint256) {
        return _lockTime;
    }    
    
    function isStaking() public view virtual returns (bool) {
       return _staking; 
    } 
    
    function maxTxLimit() public view virtual returns (uint256) {
       return _maxTxLimit; 
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
    
    function stakeClaimDate(address account) public view virtual returns (uint256) {
        if(_stake[account].stakeAmount > 0){
            return _stake[account].timestamp.add(_lockTime);
        }else{
            return 0;
        }
    }
    
    function stakeBalance(address account) public view virtual returns (uint256) {
       return _stake[account].stakeAmount; 
    } 
    
    function stakeReward(address account) public view virtual returns (uint256) {
        uint256 diff = (block.timestamp.sub(_stake[account].timestamp)).div(_rewardDuration);
        uint256 stakereward = diff.mul(_reward);
        if((_totalSupply.add(stakereward)) > _maxSupply){
            stakereward = 0;
        }
        return stakereward;
    }    
    
    function stakeDetails(address account) public view virtual returns (uint256, uint256, uint256) {
        uint256 stakeamount = _stake[account].stakeAmount;
        if(stakeamount > 0){
            uint256 diff = (block.timestamp.sub(_stake[account].timestamp)).div(_rewardDuration);
            uint256 stakereward = diff.mul(_reward);

            if((_totalSupply.add(stakereward)) > _maxSupply){
                stakereward = 0;
            }            
            return (stakeamount, stakereward, _stake[account].timestamp.add(_lockTime));
        }else{
            return (0, 0, 0);
        }
    }   
    
    function stakingPause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Only ADMIN can pause staking");
        require(_staking, "Staking: paused already");
        _staking = false;
        emit Stake(_msgSender());
    }

    function stakingUnpause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20: Only ADMIN can unpause staking");
        require(!_staking, "Staking: unpaused already");
        _staking = true;
        emit Stake(_msgSender());
    }     
    
    function totalStakeBalance() public view virtual returns (uint256) {
       return _totalStake; 
    }  
    
    function changeConfig(uint256 types, uint256 value) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only ADMIN can change config");
        if(types == 1){
        require(value >= _totalSupply, "Value is less than current total supply");    
        _maxSupply = value;
        } else if(types == 2){
        _reward = value;
        } else if(types == 3){
        _rewardDuration = value; 
        } else if(types == 4){
        _collateral = value; 
        } else if(types == 5){
        _lockTime = value;  
        } else if(types == 6){
        _maxTxLimit = value;  
        }
        emit Config(_msgSender());
    }
    
    function increaseStake() public virtual {
        uint256 amount = _collateral;
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(_staking, "Staking: paused");
        require(_stake[_msgSender()].stakeAmount > 0, "Not Staking");
        require(_totalSupply <= _maxSupply, "Exceeds Max Supply, you can't stake more");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount, "Stake amount 18000 exceeds balance");
        uint256 diff = (block.timestamp.sub(_stake[_msgSender()].timestamp)).div(_rewardDuration);
        uint256 stakeamount = diff.mul(_reward);
        if((_totalSupply.add(stakeamount)) > _maxSupply){
            stakeamount = 0;
        }
        _totalSupply = _totalSupply.add(stakeamount);
        _balances[_msgSender()] = _balances[_msgSender()].add(stakeamount);
        _stake[_msgSender()].timestamp = block.timestamp;
        _stake[_msgSender()].stakeAmount = _stake[_msgSender()].stakeAmount.add(amount);
        _totalStake = _totalStake.add(amount);
        emit Transfer(_msgSender(), address(0), amount);
        emit Transfer(address(0), _msgSender(), stakeamount);
    }
    
    function claimStake() public virtual {
        require(!paused(), "ERC20: Token paused by ADMIN");        
        require(_stake[_msgSender()].stakeAmount > 0, "Not Staking");
        require(block.timestamp >= (_stake[_msgSender()].timestamp + _lockTime), "Stake claim date not reached");
        uint256 diff = (block.timestamp.sub(_stake[_msgSender()].timestamp)).div(_rewardDuration);
        uint256 stakeamount = diff.mul(_reward);
        uint256 totstakeamount = _stake[_msgSender()].stakeAmount + stakeamount;
        if((_totalSupply.add(stakeamount)) > _maxSupply){
            stakeamount = 0;
        }         
        _totalSupply = _totalSupply.add(stakeamount);
        _balances[_msgSender()] = _balances[_msgSender()].add(totstakeamount);
        _totalStake = _totalStake.sub(_stake[_msgSender()].stakeAmount);
        _stake[_msgSender()].stakeAmount = 0;
        _stake[_msgSender()].timestamp = 0;
        emit Transfer(address(0), _msgSender(), totstakeamount);
    }    

    function startStake() public virtual {
        uint256 amount = _collateral;
        require(!paused(), "ERC20: Token paused by ADMIN");
        require(_staking, "Staking: paused");
        require(!(_stake[_msgSender()].stakeAmount > 0), "ALready Staking, use increaseStake");
        require(_totalSupply <= _maxSupply, "Exceeds Max Supply, you can't stake more");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount, "Stake amount 18000 exceeds balance");
        _stake[_msgSender()].timestamp = block.timestamp; 
        _stake[_msgSender()].stakeAmount = amount;
        _totalStake = _totalStake.add(amount);
        emit Transfer(_msgSender(), address(0), amount);
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