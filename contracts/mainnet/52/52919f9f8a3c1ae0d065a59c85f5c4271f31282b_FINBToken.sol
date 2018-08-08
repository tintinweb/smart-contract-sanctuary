pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        if (_x == 0) {
            return 0;
        }
        z = _x * _y;
        assert(z / _x == _y);
        return z;
    }

    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        return _x / _y;
    }

    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_y <= _x);
        return _x - _y;
    }

    function add(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        z = _x + _y;
        assert(z >= _x);
        return z;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));

        owner = _newOwner;

        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract Erc20Wrapper {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Erc20Wrapper {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[_from] && _value <= allowed[_from][msg.sender]);

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

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) whenNotPaused public returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused public returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract FINBToken is PausableToken {
    string public name = "FindBit.io Token";
    string public symbol = "FINB";
    uint8  public decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 50000000 ether;
    uint256 public constant MIN_FREEZE_DURATION = 1 days;

    struct Schedule {
        uint256 amount;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 released;
        uint256 lastReleased;
    }

    mapping (address => Schedule) freezed;

    event Freeze(address indexed _who, uint256 _value, uint256 _cliff, uint256 _duration);
    event Unfreeze(address indexed _who, uint256 _value);

    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _who, uint256 _value);

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function freezeOf(address _owner) public view returns (uint256) {
        return freezed[_owner].amount;
    }

    function freeze(uint256 _value, uint256 _duration) public {
        require(_value > 0 && _value <= balances[msg.sender]);
        require(freezed[msg.sender].amount == 0);
        require(_duration >= MIN_FREEZE_DURATION);

        balances[msg.sender] = balances[msg.sender].sub(_value);

        // solium-disable-next-line security/no-block-members
        uint256 timestamp = block.timestamp;
        freezed[msg.sender] = Schedule({
            amount: _value,
            start: timestamp,
            cliff: timestamp,
            duration: _duration,
            released: 0,
            lastReleased: timestamp
        });

        emit Freeze(msg.sender, _value, 0, _duration);
    }

    function freezeFrom(address _who, uint256 _value, uint256 _cliff, uint256 _duration) onlyOwner public {
        require(_who != address(0));
        require(_value > 0 && _value <= balances[_who]);
        require(freezed[_who].amount == 0);
        require(_cliff <= _duration);
        require(_duration >= MIN_FREEZE_DURATION);

        balances[_who] = balances[_who].sub(_value);

        // solium-disable-next-line security/no-block-members
        uint256 timestamp = block.timestamp;
        freezed[_who] = Schedule({
            amount: _value,
            start: timestamp,
            cliff: timestamp.add(_cliff),
            duration: _duration,
            released: 0,
            lastReleased: timestamp.add(_cliff)
        });

        emit Freeze(_who, _value, _cliff, _duration);
    }

    function unfreeze(address _who) public returns (uint256) {
        require(_who != address(0));

        Schedule storage schedule = freezed[_who];

        // solium-disable-next-line security/no-block-members
        uint256 timestamp = block.timestamp;

        require(schedule.lastReleased.add(MIN_FREEZE_DURATION) < timestamp);
        require(schedule.amount > 0 && timestamp > schedule.cliff);

        uint256 unreleased = 0;
        if (timestamp >= schedule.start.add(schedule.duration)) {
            unreleased = schedule.amount;
        } else {
            unreleased = (schedule.amount.add(schedule.released)).mul(timestamp.sub(schedule.start)).div(schedule.duration).sub(schedule.released);
        }
        require(unreleased > 0);

        schedule.released = schedule.released.add(unreleased);
        schedule.lastReleased = timestamp;
        schedule.amount = schedule.amount.sub(unreleased);

        balances[_who] = balances[_who].add(unreleased);

        emit Unfreeze(_who, unreleased);

        return unreleased;
    }

    function mint(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        totalSupply_ = totalSupply_.add(_value);
        balances[_to] = balances[_to].add(_value);

        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);

        return true;
    }

    function burn(address _who, uint256 _value) onlyOwner public returns (bool success) {
        require(_who != address(0));
        require(_value > 0 && _value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);

        return true;
    }
}