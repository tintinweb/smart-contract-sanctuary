pragma solidity ^0.4.21;

contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract Bitway is ERC20 {

    using SafeMath for uint256;
    
    string public constant name = "Bitway";
    string public constant symbol = "BTWN";
    uint256 public constant maxSupply = 21 * million * multiplier;
    uint256 public constant RATE = 1000;
    uint256 public constant decimals = 18;
    uint256 constant multiplier = 10 ** decimals;
    uint256 constant million = 10 ** 6;
    uint256 constant preSupply = 1 * million * multiplier;
    uint256 constant softCap = 2 * million * multiplier;
    uint256 constant bonusMiddleCriteria = 2 ether;
    uint256 constant bonusHighCriteria = 10 ether;
    uint256 constant stageTotal = 3;

    uint256[stageTotal] targetSupply = [
        1 * million * multiplier + preSupply,
        10 * million * multiplier + preSupply,
        20 * million * multiplier + preSupply
    ];

    uint8[stageTotal * 3] bonus = [
        30, 40, 50,
        20, 30, 40,
        10, 20, 30
    ];
    
    uint256 public totalSupply = 0;
    uint256 stage = 0;
    address public owner;
    bool public paused = true;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function () public payable {
        createCoins();
    }

    function Bitway() public {
        owner = msg.sender;
        mineCoins(preSupply);
    }

    function currentStage() public constant returns (uint256) {
        return stage + 1;
    }

    function softCapReached() public constant returns (bool) {
        return totalSupply >= softCap;
    }

    function hardCapReached() public constant returns (bool) {
        return stage >= stageTotal;
    }

    function createCoins() public payable {
        require(msg.value > 0);
        require(!paused);
        require(totalSupply < maxSupply);
        mineCoins(msg.value.mul(RATE + bonusPercent() * RATE / 100));
        owner.transfer(msg.value);
    }

    function setPause(bool _paused) public {
        require(msg.sender == owner);
        paused = _paused;
    }

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_from] >= _value);
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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

    function mineCoins(uint256 coins) internal {
        require(!hardCapReached());
        balances[msg.sender] = balances[msg.sender].add(coins);
        totalSupply = totalSupply.add(coins);
        if (totalSupply >= targetSupply[stage]) {
            stage = stage.add(1);
        }
    }

    function bonusPercent() internal constant returns (uint8) {
        if (msg.value > bonusHighCriteria) {
            return bonus[stage * stageTotal + 2];
        } else if (msg.value > bonusMiddleCriteria) {
            return bonus[stage * stageTotal + 1];
        } else {
            return bonus[stage * stageTotal];
        }
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}