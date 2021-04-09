/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// contracts/ReitCoin.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


contract Pausable is Context {

    event Paused(address account);
	
    event Unpaused(address account);
	
    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function freezeOf(address account) external view returns (uint256);
    function freeze(uint256 amount) external returns (bool);
    function unfreeze(uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
}


contract ERC20 is Context, IERC20, Ownable, Pausable ,MinterRole {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _freezes;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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

   function freezeOf(address account) public view virtual override returns (uint256) {
        return _freezes[account];
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

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }


    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
		_approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function freeze(uint256 amount) public virtual override returns (bool) {
        _freeze(_msgSender(), amount);
        return true;
    }

    function unfreeze(uint256 amount) public virtual override returns (bool) {
        _unfreeze(_msgSender(), amount);
        return true;
    }

    function distributeToken(address[] memory recipients, uint256[] memory amounts) public  onlyOwner  returns (bool) {
        require(recipients.length == amounts.length, "DistributeToken: recipients and amounts length mismatch");
        require(recipients.length > 0, "DistributeToken: no recipient");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
           totalAmount+=amounts[i];
        }
        require( _balances[_msgSender()] >= totalAmount, "DistributeToken: no enough balance");
	    for (uint256 i = 0; i < recipients.length; i++) {
           _transfer(_msgSender(), recipients[i], amounts[i]);
        }
	    return true;
    }

    function distributeIncreaseAllowance(address[] memory recipients, uint256[] memory amounts) public  onlyOwner  returns (bool) {
        require(recipients.length == amounts.length, "DistributeIncreaseAllowance: recipients and amounts length mismatch");
        require(recipients.length > 0, "DistributeIncreaseAllowance: no recipient");
       
	    for (uint256 i = 0; i < recipients.length; i++) {
           _approve(_msgSender(), recipients[i], _allowances[_msgSender()][recipients[i]].add(amounts[i]));
        }
	    return true;
    }

    function distributeDecreaseAllowance(address[] memory recipients, uint256[] memory amounts) public  onlyOwner  returns (bool) {
        require(recipients.length == amounts.length, "DistributeDecreaseAllowance: recipients and amounts length mismatch");
        require(recipients.length > 0, "DistributeDecreaseAllowance: no recipient");
       
	    for (uint256 i = 0; i < recipients.length; i++) {
           _approve(_msgSender(), recipients[i], _allowances[_msgSender()][recipients[i]].sub(amounts[i], "ERC20: decreased allowance below zero"));
        }
	    return true;
    }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function distributeMintToken(address[] memory recipients, uint256[] memory amounts) public  onlyOwner  returns (bool) {
        require(recipients.length == amounts.length, "DistributeMintToken: recipients and amounts length mismatch");
        require(recipients.length > 0, "DistributeMintToken: no recipient");
                
	    for (uint256 i = 0; i < recipients.length; i++) {
           _mint(recipients[i], amounts[i]);
        }
	    return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer to the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
		require(!paused(), "ERC20Pausable: token transfer while paused"); 
		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(!paused(), "ERC20Pausable: token mint transfer while paused");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
		require(!paused(), "ERC20Pausable: token burn while paused"); 
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
    
    function pause() public virtual onlyOwner {
        _pause();
    }
    
     function unpause() public virtual onlyOwner {
        _unpause();
    }
    
    function _freeze(address sender, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: freeze to the zero address");
        require(!paused(), "ERC20Pausable: token freeze while paused"); 
		_balances[sender] = _balances[sender].sub(amount, "ERC20: freeze amount exceeds balance");
        _freezes[sender] = _freezes[sender].add(amount);
        emit Freeze(sender,  amount);
    }

    function _unfreeze(address sender, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: unfreeze to the zero address");
        require(!paused(), "ERC20Pausable: token unfreeze while paused"); 
		_freezes[sender] = _freezes[sender].sub(amount, "ERC20: unfreeze amount exceeds balance");
        _balances[sender] = _balances[sender].add(amount);
        emit Unfreeze(sender,  amount);
    }
}

contract ReitCoin is ERC20 {
    constructor() public ERC20("Real Estate Investment Trust backed Crypto Currency", "REIT") {
        _mint(msg.sender, 50000000 * (10 ** 18));
    }
}