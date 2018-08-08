pragma solidity ^0.4.21;

contract IERC20 {
    function totalSupply() constant public returns (uint256);
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remianing);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract JAAGCoin is IERC20, Ownable {

    using SafeMath for uint256;

    uint public _totalSupply = 0;
    uint public constant INITIAL_SUPPLY = 160000000000000000000000000;
    uint public MAXUM_SUPPLY = 250000000000000000000000000;
    uint256 public _currentSupply = 0;

    string public constant symbol = "JAAG";
    string public constant name = "JAAGCoin";
    uint8 public constant decimals = 18;

    // 1 ether = 500 BC
    uint256 public RATE;

    bool public mintingFinished = false;

    mapping(address => uint256)balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) whitelisted;

    constructor() public {
        setRate(1);
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);

        owner = msg.sender;
    }

    function () public payable {
        revert();
    }

    function createTokens() payable public {
        require(msg.value > 0);
        require(whitelisted[msg.sender]);

        uint256 tokens = msg.value.mul(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);

        owner.transfer(msg.value);
    }

    function totalSupply() constant public returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(
            balances[msg.sender] >= _value
            && _value > 0
        );

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(
            balances[msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            && whitelisted[msg.sender]
        );
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        whitelisted[_spender] = true;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remianing) {
        return allowed[_owner][_spender];
    }

    function getRate() public constant returns (uint256) {
        return RATE;
    }

    function setRate(uint256 _rate) public returns (bool success) {
        RATE = _rate;
        return true;
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
        uint256 tokens = _amount.mul(RATE);
        require(
            _currentSupply.add(tokens) < MAXUM_SUPPLY
            && whitelisted[msg.sender]
        );

        if (_currentSupply >= INITIAL_SUPPLY) {
            _totalSupply = _totalSupply.add(tokens);
        }

        _currentSupply = _currentSupply.add(tokens);
        balances[_to] = balances[_to].add(tokens);
        emit Mint(_to, tokens);
        emit Transfer(address(0), _to, tokens);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    // Add a user to the whitelist
    function addUser(address user) onlyOwner public {
        whitelisted[user] = true;
        emit LogUserAdded(user);
    }

    // Remove an user from the whitelist
    function removeUser(address user) onlyOwner public {
        whitelisted[user] = false;
        emit LogUserRemoved(user);
    }

    function getCurrentOwnerBallence() constant public returns (uint256) {
        return balances[msg.sender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event LogUserAdded(address user);
    event LogUserRemoved(address user);
}