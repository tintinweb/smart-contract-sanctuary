//SourceUnit: CharryToken.sol

pragma solidity 0.6.2;

import "./EnumerableSet.sol";

contract CharryToken {

    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    struct RoleData {
        EnumerableSet.AddressSet members;
        address adminRole;
    }

    mapping (bytes32 => RoleData) roles;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;


    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public cap;
    bool public paused;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //Minting and Burning Events

    event Mint(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Burn(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    //Roles Hierarchy Events

    event RoleAdminChanged(
        bytes32 indexed role, 
        address indexed previousAdminRole, 
        address indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role, 
        address indexed account, 
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role, 
        address indexed account, 
        address indexed sender
    );

    //Pausing Events

    event Paused(address account);

    event Unpaused(address account);

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 cap_, uint256 initialTotalSupply_) public 
    {

        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = initialTotalSupply_;
        cap = cap_;
        paused = false;
        roles[MINTER_ROLE].adminRole = msg.sender;
        roles[PAUSER_ROLE].adminRole = msg.sender;
        roles[BURNER_ROLE].adminRole = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function getBalanceOf(address owner) public view returns(uint256) {
        return balanceOf[owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!paused, "Transfers are paused temporarily");
        require(balanceOf[msg.sender] >= _value, "Funds not sufficient for transfer");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address owner, address spender, uint256 amount) public returns(bool) {
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address owner, address spender, uint256 amount) public returns(bool) {
        _approve(owner, spender, allowance[owner][spender] + amount);
        return true;
    }

    function decreaseAllowance(address owner, address spender, uint256 amount) public returns(bool) {
        require(allowance[owner][spender] >= amount);
        _approve(owner, spender, allowance[owner][spender] - amount);
        return true;
    }

    function _approve(address _owner,address _spender, uint256 _value) public {
        require(!paused, "Transfers are paused temporarily");
        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function getAllowance(address owner, address spender) public view returns(uint256) {
        return allowance[owner][spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!paused, "Transfers are paused temporarily");
        require(_value <= balanceOf[_from], "Funds not sufficient for transfer");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    //Mint Functionality

    function mint(address account, uint256 amount) public {
        require(hasRole("MINTER_ROLE", msg.sender), "You do not have privileges to perform this action");
        require(totalSupply+amount <= cap, "This exceeds the limit of charry token production");
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Mint(address(0), account, amount);
    }

    //Burn Functionality

    function burn(uint256 amount) public {
        require(hasRole("BURNER_ROLE", msg.sender), "You do not have privileges to perform this action");
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burn(address(0), msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        require(hasRole("BURNER_ROLE", msg.sender), "You do not have privileges to perform this action");
        require(amount <= allowance[account][msg.sender]);
        balanceOf[account] -= amount;
        totalSupply -= amount;
        allowance[account][msg.sender] -= amount;
        emit Burn(address(0), account, amount);
    }

    //Roles Hierarchy

    function setRoleAdmin(string memory role, address _adminRole) public {
        bytes32 _role = keccak256(abi.encodePacked(role));

        require(roles[_role].adminRole == msg.sender, "You do not have privileges to perform this action");

        roles[_role].adminRole = _adminRole;
        emit RoleAdminChanged(_role, msg.sender, roles[_role].adminRole);
    }

    function hasRole(string memory role, address account) public view returns (bool) {
        bytes32 _role = keccak256(abi.encodePacked(role));
        return roles[_role].members.contains(account);
    }

    function getRoleMemberCount(string memory role) public view returns (uint256) {
        bytes32 _role = keccak256(abi.encodePacked(role));
        return roles[_role].members.length();
    }

    function getRoleAdmin(string memory role) public view returns(address) {
        bytes32 _role = keccak256(abi.encodePacked(role));
        return roles[_role].adminRole;
    }

    function grantRole(string memory role, address account) public {
        bytes32 _role = keccak256(abi.encodePacked(role));

        require(roles[_role].adminRole == msg.sender, "You do not have privileges to perform this action");

        roles[_role].members.add(account);
        emit RoleGranted(_role, account, msg.sender);
    }

    function _revokeRole(bytes32 role, address account) public{
        roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
        
    }

    function revokeRole(string memory role, address account) public {
        bytes32 _role = keccak256(abi.encodePacked(role));

        require(roles[_role].adminRole == msg.sender, "You do not have privileges to perform this action");

        _revokeRole(_role, account);
    }

    function renounceRole(string memory role, address account) public {
        bytes32 _role = keccak256(abi.encodePacked(role));

        require(account == msg.sender && hasRole(role,account), "You do not have privileges to perform this action");

        _revokeRole(_role,account);
    }

    function getRoleMember(string memory role, uint256 index) public view returns(address) {
        bytes32 _role = keccak256(abi.encodePacked(role));

        return roles[_role].members.at(index);
    }

    //Pause Functionality

    modifier whenNotPaused() {
        require(!paused, "The transfers are already paused");
        require(hasRole("PAUSER_ROLE", msg.sender), "You do not have privileges to perform this action");
        _;
    }

    modifier whenPaused() {
        require(paused, "The transfers have already resumed");
        require(hasRole("PAUSER_ROLE", msg.sender), "You do not have privileges to perform this action");
        _;
    }

    function pause() public whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }




}

//SourceUnit: EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
            
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            
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


    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    
}