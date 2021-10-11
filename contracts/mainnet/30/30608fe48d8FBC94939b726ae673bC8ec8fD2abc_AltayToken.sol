/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity >=0.4.22 <0.7.0;

contract ERC20Interface {

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint amount);
    
    function totalSupply() public view 
	returns (uint256);

    function balanceOf(address tokenOwner) public view 
	returns (uint256);
    
	function allowance(address tokenOwner, address spender) public view 
	returns (uint);

    function transfer(address to, uint amount) public 
	returns (bool);
    
	function approve(address spender, uint amount) public 
	returns (bool);

    function transferFrom(address from, address to, uint amount) public 
	returns (bool);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure 
    returns (uint c) {
    c = a + b;
    require(c >= a);
    }
    function safeSub(uint a, uint b) public pure 
    returns (uint c) {
    require(b <= a); 
    c = a - b; 
    } 
    function safeMul(uint a, uint b) public pure 
    returns (uint c) { 
    c = a * b; 
    require(a == 0 || c / a == b); 
    } 
    function safeDiv(uint a, uint b) public pure 
    returns (uint c) {
    require(b > 0);
    c = a / b;
    }
}

pragma solidity >=0.4.22 <0.7.0;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity >=0.4.22 <0.7.0;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity >=0.4.22 <0.7.0;

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor() public {
    _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }
    
    function removePauser(address account) public onlyPauser {
        _removePauser(account);
    }
    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

pragma solidity >=0.4.22 <0.7.0;

contract Pausable is Context, PauserRole {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () public {
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

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity >=0.4.22<0.7.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}


pragma solidity >=0.4.22 <0.7.0;

contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;
    
    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor() public {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyOwner {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public onlyOwner {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal onlyOwner{
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal onlyOwner {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
    function removeWhitelistAdmin(address account) public onlyOwner{
        _removeWhitelistAdmin(account);
    }
}


pragma solidity >=0.4.22 <0.7.0;

contract AltayToken is ERC20Interface, SafeMath, WhitelistAdminRole, Pausable {
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    mapping (address => bool) public lockedAccount;
    
    event Mint(address to, uint256 mintedAmount);
    event Locked(address target);
    event UnLocked(address target);
    event Burn(uint256 burnedAmount, address target);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    constructor () public {
        name = "Altay Fan Token";
        symbol = "ALTAY";
        decimals = 18;
        _totalSupply = 71775000000000000000000000;
        balances[msg.sender] = _totalSupply;
    }

    function lockAccount(address target) external onlyOwner onlyWhitelistAdmin whenNotPaused 
        returns(bool) {
        require(lockedAccount[target] == false,"This account is already locked!");
        lockedAccount[target] = true;
        emit Locked(target);
        return true;
    }
    
    function unlockAccount(address target) external onlyOwner onlyWhitelistAdmin whenNotPaused 
        returns(bool) {
        require(lockedAccount[target] == true,"This account is already unlocked!");
        lockedAccount[target] = false;
        emit UnLocked(target);
        return true;
    }

    function burnToken(uint256 burnedAmount, address tokenOwnerAddress) external onlyOwner onlyWhitelistAdmin whenNotPaused 
        returns(bool) {
        require(balances[tokenOwnerAddress] >= burnedAmount);
        balances[tokenOwnerAddress] = safeSub(balances[tokenOwnerAddress], burnedAmount);
        _totalSupply = safeSub(_totalSupply, burnedAmount);
        emit Burn(burnedAmount, tokenOwnerAddress);
        return true;
    }

    function totalSupply() public view 
        returns(uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view 
        returns(uint256) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view whenNotPaused
        returns(uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint amount) public whenNotPaused
        returns(bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) public whenNotPaused
        returns(bool) {
        _transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public whenNotPaused
        returns(bool) {
        _transfer(from, to, amount);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
    function mintToken(address to, uint256 mintedAmount) public onlyOwner onlyWhitelistAdmin whenNotPaused 
        returns(bool) {
        require(!lockedAccount[to], "To address is locked. Please try again!");
        balances[to] = safeAdd(balances[to], mintedAmount);
        _totalSupply = safeAdd(_totalSupply, mintedAmount);
        emit Mint(to, mintedAmount);
        emit Transfer(msg.sender, to, mintedAmount);
        return true;
    }

   function _transfer(address fromAddress, address toAddress, uint256 amount) internal whenNotPaused {
        require(!lockedAccount[fromAddress], "From address is locked. Please try again!");
        require(!lockedAccount[toAddress],  "To address is locked. Please try again!");
        uint previousTotalBalance = balances[fromAddress] + balances[toAddress];
        balances[fromAddress] = safeSub(balances[fromAddress], amount);
        balances[toAddress] = safeAdd(balances[toAddress], amount);
        assert(balances[fromAddress] + balances[toAddress] == previousTotalBalance);
    }
}


 // ©2021, Icrypex Crypto Exchange