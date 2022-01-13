/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// File: contracts/library/Roles.sol


pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}
// File: contracts/library/MinterRole.sol


pragma solidity >=0.4.22 <0.9.0;


contract MinterRole {
    
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor ()  {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public virtual onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public virtual {
        _removeMinter(msg.sender);
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

// File: contracts/library/SafeMath.sol


pragma solidity >=0.4.22 <0.9.0;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// File: contracts/library/IERC20.sol


pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    /**
     * Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     *  Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     *  Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


}

// File: contracts/ERC20.sol


pragma solidity >=0.4.22 <0.9.0;



contract ERC20 is IERC20 {

    using SafeMath for uint256;

    //mapping(spender=>allownace)
    mapping (address=>uint256) private _balances;

    //mapping(owner=>mapping(spender,allowance))
    mapping (address=>mapping(address=>uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _symbol;
    string private _name;
    uint8 private _decimals;


    constructor(string memory name_, string memory symbol_)
    {
        _name = name_;
        _symbol=symbol_;
        _decimals=18;

    }

     function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8){
        return 18;
    }


    //returns the total supply of the tokens
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    //returns the balance of given account address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //return allowances of token that spender can spend on behalf of owner
    function allowance(address owner, address spender) public view override  returns (uint256) {
        return _allowances[owner][spender];
    }

    //sets the allownaces of spender as the given amount
    // emits approve event
    // ** spender cannot be zeo address
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //Transfer to a reciepient
    // emits transfer event
    // ** recipient cannot be zero address
    // ** sender must have balance >=amount
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    //Transfer from sender to receiver
    // emits transfer event
    // emits an approval event indicating the updated allowance
    // ** sender and recipient cannot be zero address
    // ** sender must have balance >=amount
    // ** the caller(msg.sender) of the function should have allowance for sender's token
    function transferFrom(address sender, address recipient, uint256 amount ) public override returns (bool) {
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance.sub(amount));
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        require( _balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _approve(address owner,  address spender,  uint256 amount ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance.sub(subtractedValue));
 
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
       
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);
        
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = _balances[account].sub(amount);
        _totalSupply =_totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowances[account][msg.sender]);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

}
// File: contracts/GenToken.sol


pragma solidity >=0.4.22 <0.9.0;



contract GenToken is ERC20,MinterRole {
    constructor(string memory _name, string memory _symbol) ERC20(_name,_symbol){
        
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount)public {
        _burn(to,amount);
    }
}