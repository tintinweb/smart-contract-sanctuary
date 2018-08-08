pragma solidity^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    mapping (uint256 => address) public owner;
    address[] public allOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner[0] = msg.sender;
        allOwner.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner[0] || msg.sender == owner[1] || msg.sender == owner[2]);
        _;
    }
    
    function addnewOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        uint256 len = allOwner.length;
        owner[len] = newOwner;
        allOwner.push(newOwner);
    }

    function setNewOwner(address newOwner, uint position) public onlyOwner {
        require(newOwner != address(0));
        require(position == 1 || position == 2);
        owner[position] = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner[0], newOwner);
        owner[0] = newOwner;
    }

}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
}

contract KNBaseToken is ERC20 {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) > balances[_to]);


        uint256 previousBalances = balances[_from].add(balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        assert(balances[_from].add(balances[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract KnowToken is KNBaseToken("Know Token", "KN", 18, 7795482309000000000000000000), Ownable {

    uint256 internal privateToken = 389774115000000000000000000;
    uint256 internal preSaleToken = 1169322346000000000000000000;
    uint256 internal crowdSaleToken = 3897741155000000000000000000;
    uint256 internal bountyToken;
    uint256 internal foundationToken;
    address public founderAddress;
    bool public unlockAllTokens;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool unfrozen);
    event UnLockAllTokens(bool unlock);

    constructor() public {
        founderAddress = msg.sender;
        balances[founderAddress] = totalSupply_;
        emit Transfer(address(0), founderAddress, totalSupply_);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0));                               
        require (balances[_from] >= _value);               
        require (balances[_to].add(_value) >= balances[_to]); 
        require(!frozenAccount[_from] || unlockAllTokens);

        balances[_from] = balances[_from].sub(_value);                  
        balances[_to] = balances[_to].add(_value);                  
        emit Transfer(_from, _to, _value);
    }

    function unlockAllTokens(bool _unlock) public onlyOwner {
        unlockAllTokens = _unlock;
        emit UnLockAllTokens(_unlock);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

contract KnowTokenPrivateSale is Ownable{
    using SafeMath for uint256;

    KnowToken public token;
    address public wallet;
    uint256 public currentRate;
    uint256 public limitTokenForSale;

    event ChangeRate(address indexed who, uint256 newrate);
    event FinishPrivateSale();

    constructor() public {
        currentRate = 100000;
        wallet = msg.sender; //address of founder
        limitTokenForSale = 389774115000000000000000000;
        token = KnowToken(0xbfd18F20423694a69e35d65cB9c9D74396CC2c2d);// address of KN Token
    }

    function changeRate(uint256 newrate) public onlyOwner{
        require(newrate > 0);
        currentRate = newrate;

        emit ChangeRate(msg.sender, newrate);
    }

    function remainTokens() view public returns(uint256) {
        return token.balanceOf(this);
    }

    function finish() public onlyOwner {
        uint256 reTokens = remainTokens();
        token.transfer(owner[0], reTokens);
        
        emit FinishPrivateSale();
    }

    function () public payable {
        assert(msg.value >= 50 ether);
        
        uint256 tokens = currentRate.mul(msg.value);
        uint256 bonus = tokens.div(2);
        uint256 totalTokens = tokens.add(bonus);
        token.transfer(msg.sender, totalTokens);
        token.freezeAccount(msg.sender, true);        
        wallet.transfer(msg.value);       
    }  
}