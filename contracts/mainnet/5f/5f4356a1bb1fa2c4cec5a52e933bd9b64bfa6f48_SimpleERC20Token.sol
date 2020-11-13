pragma solidity 0.7.1;

contract SimpleERC20Token {
    mapping (address => uint256) public balanceOf;

    string public name = "wrapped MALW";
    string public symbol = "wMALW";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _admin = address(0);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferToMALW(address indexed from, uint256 value, string toMalwAddress);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        _admin = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        mint(msg.sender, 100000 * 10**_decimals);
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender);
            _;
    }

    function setAdmin(address to) onlyAdmin public returns (bool success) {
        _admin = to;
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferMultiple(address[] memory to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        value /= to.length;
        for (uint256 i = 0; i < to.length; i++) {
            balanceOf[to[i]] += value;
            emit Transfer(msg.sender, to[i], value);
        }
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= _allowances[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) onlyAdmin public returns (bool success) {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool success) {
        require(value <= balanceOf[msg.sender]);
        totalSupply -= value;
        balanceOf[msg.sender] -= value;
        return true;
    }

    function transferToMALW(uint256 value, string memory malwAddress) public returns (bool) {
        require(value <= balanceOf[msg.sender]);
        burn(value);
        emit TransferToMALW(msg.sender, value, malwAddress);
        return true;
    }
}