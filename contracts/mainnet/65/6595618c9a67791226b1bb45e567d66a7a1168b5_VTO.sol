/**
 *Submitted for verification at Etherscan.io on 2021-04-08
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
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

    function acceptOwnership() public onlyNewOwner returns (bool) {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
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

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract VTO is ERC20, Ownable, Pausable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 internal initialSupply;
    uint256 internal totalSupply_;
    uint256 internal mintCap;

    mapping(address => uint256) internal balances;
    mapping(address => bool) public frozen;
    mapping(address => mapping(address => uint256)) internal allowed;

    address implementation;

    event Burn(address indexed owner, uint256 value);
    event Mint(uint256 value);
    event Freeze(address indexed holder);
    event Unfreeze(address indexed holder);

    modifier notFrozen(address _holder) {
        require(!frozen[_holder]);
        _;
    }

    constructor() public {
        name = "VictoryTournament";
        symbol = "VTO";
        initialSupply = 100000000; 
        totalSupply_ = initialSupply * 10**uint256(decimals);
        mintCap = 100000000 * 10**uint256(decimals); //100,000,000
        balances[owner] = totalSupply_;

        emit Transfer(address(0), owner, totalSupply_);
    }

    function() external payable {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }

    function upgradeTo(address _newImplementation) public onlyOwner {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value)
        public
        whenNotPaused
        notFrozen(msg.sender)
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function multiTransfer(
        address[] memory _toList,
        uint256[] memory _valueList
    ) public whenNotPaused notFrozen(msg.sender) returns (bool) {
        if (_toList.length != _valueList.length) {
            revert();
        }

        for (uint256 i = 0; i < _toList.length; i++) {
            transfer(_toList[i], _valueList[i]);
        }

        return true;
    }

    function balanceOf(address _holder) public view returns (uint256 balance) {
        return balances[_holder];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused notFrozen(_from) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = (
            allowed[msg.sender][spender].add(addedValue)
        );

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        require(spender != address(0));
        allowed[msg.sender][spender] = (
            allowed[msg.sender][spender].sub(subtractedValue)
        );

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function allowance(address _holder, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_holder][_spender];
    }

    function freezeAccount(address _holder) public onlyOwner returns (bool) {
        require(!frozen[_holder]);
        frozen[_holder] = true;
        emit Freeze(_holder);
        return true;
    }

    function unfreezeAccount(address _holder) public onlyOwner returns (bool) {
        require(frozen[_holder]);
        frozen[_holder] = false;
        emit Unfreeze(_holder);
        return true;
    }

    function distribute(address _to, uint256 _value)
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function claimToken(
        ERC20 token,
        address _to,
        uint256 _value
    ) public onlyOwner returns (bool) {
        token.transfer(_to, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
        return true;
    }

    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(mintCap >= totalSupply_.add(_amount));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}