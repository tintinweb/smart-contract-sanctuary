/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-02-07
*/

pragma solidity =0.6.6;


contract HOORC20Factory {
    event HOORC20Created(address token_address, string symbol, uint id);
    event TokenManagerDeleted(string symbol,address token_address);
    event TokenManagerAdded(string symbol,address token_address);

    event TokenPauserChanged(string symbol, address new_pauser);
    event TokenOperatorChanged(string symbol, address new_operator);
    event TokenFactoryAdded(string symbol, address new_factory);
    event TokenFactoryDeleted(string symbol, address factory);

    event SuperAdminAdded(address new_admin);
    event SuperAdminRemoved(address admin);

    mapping(string => address) public all_tokens;
    mapping(address => bool) public super_admins;

    uint public token_count;

    constructor(address admin) public {
        super_admins[admin] = true;
    }

    modifier onlySuperAdmin(){
        require(super_admins[msg.sender] == true, "not allowed");
        _;
    }

    function createToken(address operator, address pauser, string memory name, string memory symbol, uint8 decimal) onlySuperAdmin public returns (address token_address) {
        require(all_tokens[symbol] == address(0), "duplicate coin");
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, decimal));
        HOORC20Template token = new HOORC20Template{salt : salt}(operator, pauser, name, symbol, decimal);
        token_address = address(token);
        all_tokens[symbol] = token_address;
        token_count += 1;
        emit HOORC20Created(token_address, symbol, token_count);
    }

    function addTokenManager(string memory symbol,address token_address) onlySuperAdmin public{
        require(all_tokens[symbol] == address(0),"token have in management");
        all_tokens[symbol] = token_address;
        token_count += 1;
        emit TokenManagerAdded(symbol,token_address);
    }

    function deleteTokenManager(string memory symbol) onlySuperAdmin public{
        require(all_tokens[symbol] != address(0),"token not in management");
        address token_address = all_tokens[symbol];
        delete all_tokens[symbol];
        token_count -= 1;
        emit TokenManagerDeleted(symbol,token_address);
    }

    function changeTokenPauser(string memory symbol, address new_pauser) onlySuperAdmin public {
        require(all_tokens[symbol] != address(0),"token not in management");
        HOORC20Template token = HOORC20Template(all_tokens[symbol]);
        token.changePauser(new_pauser);
        emit TokenPauserChanged(symbol,new_pauser);
    }

    function changeTokenOperator(string memory symbol, address new_operator) onlySuperAdmin public {
        require(all_tokens[symbol] != address(0),"token not in management");
        HOORC20Template token = HOORC20Template(all_tokens[symbol]);
        token.changeOperator(new_operator);
        emit TokenOperatorChanged(symbol,new_operator);
    }

    function addTokenFactor(string memory symbol, address new_factory) onlySuperAdmin public {
        require(all_tokens[symbol] != address(0),"token not in management");
        HOORC20Template token = HOORC20Template(all_tokens[symbol]);
        token.addFactory(new_factory);
        emit TokenFactoryAdded(symbol,new_factory);
    }

    function deteleTokenFactor(string memory symbol, address factory) onlySuperAdmin public {
        require(all_tokens[symbol] != address(0),"token not in management");
        HOORC20Template token = HOORC20Template(all_tokens[symbol]);
        token.removeFactory(factory);
        emit TokenFactoryDeleted(symbol,factory);
    }

    function addSuperAdmin(address new_admin) onlySuperAdmin public {
        super_admins[new_admin] = true;
        emit SuperAdminAdded(new_admin);
    }

    function removeSuperAdmin(address admin) onlySuperAdmin public {
        require(msg.sender != admin,"delete self not allowed");
        delete super_admins[admin];
        emit SuperAdminRemoved(admin);
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


interface IHOORC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Pausable is Context {

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

contract HOORC20 is Context, IHOORC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "HOORC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "HOORC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "HOORC20: transfer from the zero address");
        require(recipient != address(0), "HOORC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "HOORC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "HOORC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "HOORC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "HOORC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "HOORC20: approve from the zero address");
        require(spender != address(0), "HOORC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract HOORC20Pausable is HOORC20, Pausable {
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "HOORC20Pausable: token transfer while paused");
    }
}

contract HOORC20Template is HOORC20Pausable {
//    address factory;
//    address _operator;
//    address _pauser;
    mapping(address => bool) public _factory;
    address public _operator;
    address public _pauser;

    constructor(address operator, address pauser, string memory name, string memory symbol, uint8 decimal) public HOORC20(name, symbol) {
        _operator = operator;
        _pauser = pauser;
        _setupDecimals(decimal);
        _factory[msg.sender] = true;
    }

    modifier onlyFactory(){
        require(_factory[msg.sender] == true, "only Factory");
        _;
    }
    modifier onlyOperator(){
        require(msg.sender == _operator, "not allowed");
        _;
    }
    modifier onlyPauser(){
        require(msg.sender == _pauser, "not allowed");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function changeOperator(address new_operator) public onlyFactory {
        _operator = new_operator;
    }

    function changePauser(address new_pauser) public onlyFactory {
        _pauser = new_pauser;
    }

    function addFactory(address new_factory) public onlyFactory{
        _factory[new_factory] = true;
    }

    function removeFactory(address factory) public onlyFactory{
        delete _factory[factory];
    }

    function mint(address account, uint256 amount) public whenNotPaused onlyOperator {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public whenNotPaused onlyOperator {
        _burn(account, amount);
    }
}