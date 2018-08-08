pragma solidity ^0.4.18;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BTHBCoin is ERC20, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal initialSupply;
    uint256 internal _totalSupply;
    
                                 
    uint256 internal LOCKUP_TERM = 6 * 30 * 24 * 3600;

    mapping(address => uint256) internal _balances;    
    mapping(address => mapping(address => uint256)) internal _allowed;

    mapping(address => uint256) internal _lockupBalances;
    mapping(address => uint256) internal _lockupExpireTime;

    function BTHBCoin() public {
        name = "Bithumb Coin";
        symbol = "BTHB";
        decimals = 18;


        //Total Supply  10,000,000,000
        initialSupply = 10000000000;
        _totalSupply = initialSupply * 10 ** uint(decimals);
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(msg.sender != address(0));
        require(_value <= _balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _holder) public view returns (uint256 balance) {
        return _balances[_holder].add(_lockupBalances[_holder]);
    }

    function lockupBalanceOf(address _holder) public view returns (uint256 balance) {
        return _lockupBalances[_holder];
    }

    function unlockTimeOf(address _holder) public view returns (uint256 balance) {
        return _lockupExpireTime[_holder];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(_to != address(this));
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _holder, address _spender) public view returns (uint256) {
        return _allowed[_holder][_spender];
    }

    function () public payable {
        revert();
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= _balances[msg.sender]);
        address burner = msg.sender;
        _balances[burner] = _balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        return true;
    }

    function distribute(address _to, uint256 _value, uint256 _lockupRate) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(_value <= _balances[owner]);
        require(_lockupRate >= 50 && _lockupRate<=100 && _lockupRate.div(5).mul(5) == _lockupRate );

        _balances[owner] = _balances[owner].sub(_value);

        uint256 lockupValue = _value.mul(_lockupRate).div(100);
        uint256 givenValue = _value.sub(lockupValue);
        uint256 ExpireTime = now + LOCKUP_TERM;
        
        _balances[_to] = _balances[_to].add(givenValue);
        _lockupBalances[_to] = _lockupBalances[_to].add(lockupValue);
        _lockupExpireTime[_to] = ExpireTime;

        emit Transfer(owner, _to, _value);
        return true;
    }

    function unlock() public returns(bool) {
        address tokenHolder = msg.sender;
        require(_lockupBalances[tokenHolder] > 0);
        require(_lockupExpireTime[tokenHolder] <= now);

        uint256 value = _lockupBalances[tokenHolder];

        _balances[tokenHolder] = _balances[tokenHolder].add(value);  
        _lockupBalances[tokenHolder] = 0;             
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        uint256 ownerAmount = _balances[owner];
        _balances[owner] = _balances[owner].sub(ownerAmount);
        _balances[newOwner] = _balances[newOwner].add(ownerAmount);
        emit Transfer(owner, newOwner, ownerAmount);   
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, newOwner);
    }
    
}