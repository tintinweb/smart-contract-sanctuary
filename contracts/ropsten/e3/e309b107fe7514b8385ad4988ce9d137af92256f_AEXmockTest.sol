pragma solidity ^0.4.24;

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

contract ERC20Basic {

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {

    using SafeMath for uint;
    mapping(address => uint) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender)
    public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
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

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Ownable {

    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() canMint public onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract FreezableToken is StandardToken {

    mapping (bytes32 => uint64) internal chains;
    mapping (bytes32 => uint) internal freezings;
    mapping (address => uint) internal freezingBalance;
    event Freeze(address indexed to, uint64 release, uint256 amount);
    event Released(address indexed owner, uint256 amount);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }

    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }

    function numbOfFrozenAmCount(address _addr) public view returns (uint256 count) {
        uint64 release = chains[dbVal(_addr, 0)];
        while (release != 0) {
            count++;
            release = chains[dbVal(_addr, release)];
        }
    }

    function getFrozenAmData(address _addr, uint256 _index) public view returns (uint64 _releaseEpochStamp, uint256 _frozenBalance) {
        for (uint256 i = 0; i < _index + 1; i++) {
            _releaseEpochStamp = chains[dbVal(_addr, _releaseEpochStamp)];
            if (_releaseEpochStamp == 0) {
                return;
            }
        }
        _frozenBalance = freezings[dbVal(_addr, _releaseEpochStamp)];
    }

    function sendAndFreeze(address _to, uint256 _amount, uint64 _until) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        bytes32 actVal = dbVal(_to, _until);
        freezings[actVal] = freezings[actVal].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);
        freeze(_to, _until);
        emit Transfer(msg.sender, _to, _amount);
        emit Freeze(_to, _until, _amount);
    }

    function releaseSingleAm() public {
        bytes32 genVal = dbVal(msg.sender, 0);
        uint64 gen = chains[genVal];
        require(gen != 0);
        require(uint64(block.timestamp) > gen);
        bytes32 actVal = dbVal(msg.sender, gen);
        uint64 next = chains[actVal];
        uint256 amount = freezings[actVal];
        delete freezings[actVal];
        balances[msg.sender] = balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);
        if (next == 0) {
            delete chains[genVal];
        } else {
            chains[genVal] = next;
            delete chains[actVal];
        }
        emit Released(msg.sender, amount);
    }

    function releaseAllatOnce() public returns (uint256 tokens) {
        uint256 release;
        uint256 balance;
        (release, balance) = getFrozenAmData(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseSingleAm();
            tokens += balance;
            (release, balance) = getFrozenAmData(msg.sender, 0);
        }
    }

    function dbVal(address _addr, uint256 _releaseEpochStamp) internal pure returns (bytes32 datebin) {
        datebin = 0x0103200900100000080120180100000101001110010010010100010101011000;
        assembly {
            datebin := or(datebin, mul(_addr, 0x10000000000000000))
            datebin := or(datebin, _releaseEpochStamp)
        }
    }

    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = dbVal(_to, _until);
        bytes32 parentKey = dbVal(_to, uint64(0));
        uint64 next = chains[parentKey];
        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }
        bytes32 nextKey = dbVal(_to, next);
        uint256 parent;
        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;
            next = chains[nextKey];
            nextKey = dbVal(_to, next);
        }
        if (_until == next) {
            return;
        }
        if (next != 0) {
            chains[key] = next;
        }
        chains[parentKey] = _until;
    }
}

contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
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

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract FreezableMintableToken is FreezableToken, MintableToken {

    function mintAndFreeze(address _to, uint256 _amount, uint64 _until) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        bytes32 actVal = dbVal(_to, _until);
        freezings[actVal] = freezings[actVal].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);
        freeze(_to, _until);
        emit Mint(_to, _amount);
        emit Freeze(_to, _until, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}

contract ConstantValues {
    
    uint8 public constant decimals = 18;
    uint256 constant decimal_multiplier = 10 ** uint(decimals);
    string public constant name = &quot;AEXmock&quot;;
    string public constant symbol = &quot;AEXm&quot;;
}

contract AEXmockTest is ConstantValues, FreezableMintableToken, BurnableToken, Pausable {

    function token_name() public pure returns (string _tokenName) {
        return name;
    }

    function token_symbol() public pure returns (string _tokenSymbol) {
        return symbol;
    }

    function token_decimals() public pure returns (uint256 _tokenDecimals) {
        return decimals;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transfer(_to, _value);
    }
}