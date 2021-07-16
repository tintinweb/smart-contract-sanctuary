//SourceUnit: UltimateChainToken.sol

pragma solidity 0.5.14;

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
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
}
contract Ownable is Context {
    address private _owner;
    constructor () internal {
        _owner = _msgSender();
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}
contract BaseTRC20 is Ownable, ITRC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    bool private _mintingFinished = false;
    event MintFinished();
    modifier canMint() {
        require(
            !_mintingFinished,
            "BaseTRC20: minting is finished");
        _;
    }
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BaseTRC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BaseTRC20: decreased allowance below zero"));
        return true;
    }
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "BaseTRC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    function recoverTRC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        ITRC20(tokenAddress).transfer(owner(), tokenAmount);
    }
    function recoverTRX(uint256 amount) public onlyOwner {
        _msgSender().transfer(amount);
    }
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }
    function mint(address to, uint256 value) public canMint onlyOwner {
        _mint(to, value);
    }
    function finishMinting() public canMint onlyOwner {
        _mintingFinished = true;
        emit MintFinished();
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BaseTRC20: transfer from the zero address");
        require(recipient != address(0), "BaseTRC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BaseTRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) private {
        require(account != address(0), "BaseTRC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) private {
        require(account != address(0), "BaseTRC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BaseTRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BaseTRC20: approve from the zero address");
        require(spender != address(0), "BaseTRC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
contract TRC20Detailed is BaseTRC20 {
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
contract UltimateChainToken is ITRC20, TRC20Detailed {
    constructor() public TRC20Detailed("UltimateChainToken", "UCHT", 6){
        mint(owner(), 666e12);
    }
}