pragma solidity^0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

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
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = address(0x072F140DcCCE18F9966Aeb6D71ffcD0b42748683);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
}

contract PO8BaseToken is ERC20 {
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

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract PO8Token is PO8BaseToken("PO8 Token", "PO8", 18, 10000000000000000000000000000), Ownable {

    uint256 internal privateToken;
    uint256 internal preSaleToken;
    uint256 internal crowdSaleToken;
    uint256 internal bountyToken;
    uint256 internal foundationToken;
    address public founderAddress;
    bool public unlockAllTokens;

    mapping (address => bool) public approvedAccount;

    event UnFrozenFunds(address target, bool unfrozen);
    event UnLockAllTokens(bool unlock);

    constructor() public {
        founderAddress = address(0x072F140DcCCE18F9966Aeb6D71ffcD0b42748683);
        balances[founderAddress] = totalSupply_;
        emit Transfer(address(0), founderAddress, totalSupply_);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0));                               
        require (balances[_from] >= _value);               
        require (balances[_to].add(_value) >= balances[_to]); 
        require(approvedAccount[_from] || unlockAllTokens);

        balances[_from] = balances[_from].sub(_value);                  
        balances[_to] = balances[_to].add(_value);                  
        emit Transfer(_from, _to, _value);
    }

    function unlockAllTokens(bool _unlock) public onlyOwner {
        unlockAllTokens = _unlock;
        emit UnLockAllTokens(_unlock);
    }

    function approvedAccount(address target, bool approval) public onlyOwner {
        approvedAccount[target] = approval;
        emit UnFrozenFunds(target, approval);
    }
}

contract PO8InDependenceDaySale is Ownable{
    using SafeMath for uint256;

    PO8Token public token;
    address public wallet;
    uint256 public currentRate;

    event ChangeRate(address indexed who, uint256 newrate);
    event FinishPreSale();

    constructor() public {
        currentRate = 48000;
        wallet = address(0x072F140DcCCE18F9966Aeb6D71ffcD0b42748683); //address of founder
        token = PO8Token(0x8744a672D5a2df51Da92B4BAb608CE7ff4Ddd804);// address of PO8 Token
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
        token.transfer(owner, reTokens);
        
        emit FinishPreSale();
    }

    function () public payable {
        assert(msg.value >= 0.1 ether);
        
        uint256 tokens = currentRate.mul(msg.value);
        token.transfer(msg.sender, tokens);        
        wallet.transfer(msg.value);       
    }  
}