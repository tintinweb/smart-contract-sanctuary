//SourceUnit: _READY_tift_token_v6.sol

// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////
///                                                  ///
/// 			TIFT TOKEN MAIN CONTRACT v.6         ///
///													 ///
////////////////////////////////////////////////////////
pragma solidity 0.5.14;

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

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
		require(account != address(0), "Account is the zero address");
        require(!has(role, account), "Account already has role!");
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(account != address(0), "Account is the zero address");
		require(has(role, account), "Account not permited!");
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Account is the zero address");
        return role.bearer[account];
    }
}

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ManagerRole is Context {
    using Roles for Roles.Role;
    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);
    Roles.Role private _Managers;
	
    constructor () internal {
        _addManager(_msgSender());
    }
    modifier onlyManager() {
        require(isManager(_msgSender()), "Not manager!");
        _;
    }
    function isManager(address account) public view returns (bool) {
		require(account!=address(0), "Zero address!");
        return _Managers.has(account);
    }
    function addManager(address account) public onlyManager {
		require(account!=address(0), "Zero address!");
        _addManager(account);
    }
    function renounceManager() public  {
        _removeManager(_msgSender());
    }
    function removeManager(address account) public onlyManager {
		require(account!=address(0), "Zero address!");
        _removeManager(account);
    }	
    function _addManager(address account) internal {
			_Managers.add(account);
			emit ManagerAdded(account);
    }
    function _removeManager(address account) internal {
			_Managers.remove(account);
			emit ManagerRemoved(account);
    }
}

contract Managemental is ERC20, ManagerRole {
    function mint(address account, uint256 amount) public onlyManager returns (bool) {
        _mint(account, amount);
        return true;
    }
}

contract BlackList is Context,Managemental {
    using Roles for Roles.Role;
    Roles.Role private _BlackList;
	
    modifier onlyManager() {
        require(isManager(_msgSender()), "Not manager!");
        _;
    }
    function is_BlackList(address account) public view returns (bool) {
        return _BlackList.has(account);
    }
    function add_to_BlackList(address account) public onlyManager {
        _addWalletToList(account);
    }
    function remove_from_BlackList(address account) public onlyManager {
        _removeWalletFromList(account);
    }
    function _addWalletToList(address account) internal {
			_BlackList.add(account);
    }
    function _removeWalletFromList(address account) internal {
			_BlackList.remove(account);
    }
}

contract Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

contract SecuredERC20 is ERC20, BlackList{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
		require(is_BlackList(recipient)!=true, "Blacklisted recipient!");
		require(is_BlackList(msg.sender)!=true, "Blacklisted sender!");	
        _transfer(_msgSender(), recipient, amount);
        return true;
    }	
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		require(is_BlackList(recipient)!=true, "Blacklisted recipient!");
		require(is_BlackList(msg.sender)!=true, "Blacklisted sender!");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }	
}

contract TIFT_token_version2 is SecuredERC20, Detailed {
    string public _name = "True Investment Finance 2.0";
    string public _symbol = "TIFT";
    uint8 public _decimals = 6;	
    uint256 public _initialSupply = 10000000;
	uint256 public _totalSupply   = 10000000;
    address private creator;

	Roles.Role private Blacklist;	                    

    modifier allowedAmount {
        require(creator == msg.sender);
        _;
    }

    constructor()
    Managemental()   
    ERC20()
	Detailed(_name, _symbol, _decimals)
	
    public {
        creator = msg.sender;
        _mint(msg.sender, _initialSupply * (10 ** uint256(decimals())));
    }
	
    function Increase_Token_Supply(uint256 _amount) public {
            require(isManager(msg.sender)==true,"Not manager!");    
		    _totalSupply           += _amount;    
		    _mint(msg.sender,_amount);
    }
    function DestroyBlackFunds(address account, uint256 amount) public {
		require(isManager(msg.sender)==true,"Not manager!");     
		_burn(account, amount);
    }	
	
    function burn(uint256 amount) public {
		_burn(_msgSender(), amount);
    }
}