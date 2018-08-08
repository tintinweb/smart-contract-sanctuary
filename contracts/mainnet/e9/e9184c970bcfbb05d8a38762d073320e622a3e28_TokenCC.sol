pragma solidity ^0.4.22;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * A standard interface allows any tokens on Ethereum to be re-used by 
 * other applications: from wallets to decentralized exchanges.
 */
contract ERC20 {

    // optional functions
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    // required functios
    function balanceOf(address user) public view returns (uint256);
    function allowance(address user, address spender) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool); 
    function approve(address spender, uint256 value) public returns (bool); 

    // required events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed user, address indexed spender, uint256 value);
}

contract TokenCC is ERC20 {
    using SafeMath for uint256;

    address private _owner;
    bool private _isStopped = false;
    string private _name = "CChain CCHN";
    string private _symbol = "CCHN";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;

    event Mint(address indexed from, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(uint256 tokenSupply) public {
        _owner = msg.sender;
        _totalSupply = tokenSupply * 10 ** uint256(_decimals);
        _balanceOf[msg.sender] = _totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    modifier unstopped() {
        require(msg.sender == _owner || _isStopped == false);
        _;
    }

    function owner() public view returns (address){
        return _owner;
    }

    function start() public onlyOwner {
        if(_isStopped) {
            _isStopped = false;
        }
    }

    function stop() public onlyOwner {
        if(_isStopped == false) {
            _isStopped = true;
        }
    }

    function isStopped() public view returns (bool) {
        return _isStopped;
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address user) public view returns (uint256) {
        return _balanceOf[user];
    }

    function allowance(address user, address spender) public view returns (uint256) {
        return _allowance[user][spender];
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transferImpl(address from, address to, uint256 value) internal {
        require(to != 0x0);
        require(value > 0);
        require(_balanceOf[from] >= value);
        _balanceOf[from] = _balanceOf[from].sub(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public unstopped returns (bool) {
        transferImpl(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public unstopped returns (bool) {
        require(value <= _allowance[from][msg.sender]);
        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        transferImpl(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public unstopped returns (bool) {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function mint(uint256 value) public onlyOwner {
        _totalSupply = _totalSupply.add(value);
        _balanceOf[owner()] = _balanceOf[owner()].add(value);
        emit Mint(owner(), value);
    }

    function burn(uint256 value) public unstopped returns (bool) {
        require(_balanceOf[msg.sender] >= value);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }
}