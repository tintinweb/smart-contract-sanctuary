/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity ^0.5.0;

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

}

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  public {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract StandardToken  {

    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
    uint256 public prizingPool;
    uint256 public prizingPercent;
    uint256 public prizingFee;

    function getTotalSupply() public view returns (uint) {
        return totalSupply;
    }
    function getTotalSupplySubA0() public view returns (uint) {
        return totalSupply  - balances[address(0)];
    }
    function getPrizingPool() public view returns (uint) {
        return prizingPool;
    }
    function getPrizingPercent() public view returns (uint) {
        return prizingPercent;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //subtract value according to fee
        uint256 _fee = _value.mul(prizingFee);
        uint256 _valueSubFee=_value.sub(_fee);
        
        
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_valueSubFee);
            
            emit Transfer(msg.sender, _to, _value);
            
            //transfer fee to owner
            emit Transfer(msg.sender, msg.sender , _fee);
            
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //subtract value according to fee
        uint256 _fee = _value.mul(prizingFee);
        uint256 _valueSubFee=_value.sub(_fee);
        
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_valueSubFee);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            
            emit Transfer(_from, _to, _valueSubFee);
            
            //transfer fee to owner's pool
            prizingPool+=_fee;
            emit Transfer(_from, msg.sender, _fee);
            
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract ERC20Token is StandardToken, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    string public version = '1.0';
    uint256 public totalCoin;
    uint8 public decimals;
    uint8 public exchangeRate;

    event TokenNameChanged(string indexed previousName, string indexed newName);
    event TokenSymbolChanged(string indexed previousSymbol, string indexed newSymbol);

    constructor()  public {
        decimals        = 9;
        totalCoin       = 1000000000;                       // Total Supply of Coin
        totalSupply     = totalCoin * 10**uint(decimals); // Total Supply of Coin
        balances[owner] = totalSupply;                    // Total Supply sent to Owner's Address
        symbol          = "3GEAB";                       // Your Ticker Symbol  (changable)
        name            = "3GEAB";             // Your Coin Name      (changable)
        prizingPool     = 0;
        prizingPercent  = 5;
        prizingFee      = prizingPercent.div(100);
    }

    function changeTokenName(string memory newName) public isOwner returns (bool success) {
        emit TokenNameChanged(name, newName);
        name = newName;
        return true;
    }

    function changeTokenSymbol(string memory newSymbol) public isOwner returns (bool success) {
        emit TokenSymbolChanged(symbol, newSymbol);
        symbol = newSymbol;
        return true;
    }
    
    function setPrizingPercent(uint256 _newpercent) public isOwner returns (bool success) {
        prizingPercent = _newpercent;
        prizingPercent.div(100);
        return true;
    }

    

}