pragma solidity 0.6.2;
import "./HMTokenInterface.sol";
import "./SafeMath.sol";

contract HMToken is HMTokenInterface {
    using SafeMath for uint256;

    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant BULK_MAX_VALUE = 1000000000 * (10 ** 18);
    uint32  private constant BULK_MAX_COUNT = 100;

    event BulkTransfer(uint256 indexed _txId, uint256 _bulkCount);
    event BulkApproval(uint256 indexed _txId, uint256 _bulkCount);

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    string public name;
    uint8 public decimals;
    string public symbol;

    constructor(uint256 _totalSupply, string memory _name, uint8 _decimals, string memory _symbol) public {
        totalSupply = _totalSupply * (10 ** uint256(_decimals));
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        success = transferQuiet(_to, _value);
        require(success, "Transfer didn't succeed");
        return success;
    }

    function transferFrom(address _spender, address _to, uint256 _value) public override returns (bool success) {
        uint256 _allowance = allowed[_spender][msg.sender];
        require(_allowance >= _value, "Spender allowance too low");
        require(_to != address(0), "Can't send tokens to uninitialized address");

        balances[_spender] = balances[_spender].sub(_value, "Spender balance too low");
        balances[_to] = balances[_to].add(_value);

        if (_allowance != MAX_UINT256) { // Special case to approve unlimited transfers
            allowed[_spender][msg.sender] = allowed[_spender][msg.sender].sub(_value);
        }

        emit Transfer(_spender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(_spender != address(0), "Token spender is an uninitialized address");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function increaseApproval(address _spender, uint _delta) public returns (bool success) {
        require(_spender != address(0), "Token spender is an uninitialized address");

        uint _oldValue = allowed[msg.sender][_spender];
        if (_oldValue.add(_delta) < _oldValue || _oldValue.add(_delta) >= MAX_UINT256) { // Truncate upon overflow.
            allowed[msg.sender][_spender] = MAX_UINT256.sub(1);
        } else {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_delta);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _delta) public returns (bool success) {
        require(_spender != address(0), "Token spender is an uninitialized address");

        uint _oldValue = allowed[msg.sender][_spender];
        if (_delta > _oldValue) { // Truncate upon overflow.
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_delta);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferBulk(address[] memory _tos, uint256[] memory _values, uint256 _txId) public override returns (uint256 _bulkCount) {
        require(_tos.length == _values.length, "Amount of recipients and values don't match");
        require(_tos.length < BULK_MAX_COUNT, "Too many recipients");

        uint256 _bulkValue = 0;
        for (uint j = 0; j < _tos.length; ++j) {
            _bulkValue = _bulkValue.add(_values[j]);
        }
        require(_bulkValue < BULK_MAX_VALUE, "Bulk value too high");

        bool _success;
        for (uint i = 0; i < _tos.length; ++i) {
            _success = transferQuiet(_tos[i], _values[i]);
            if (_success) {
                _bulkCount = _bulkCount.add(1);
            }
        }
        emit BulkTransfer(_txId, _bulkCount);
        return _bulkCount;
    }

    function approveBulk(address[] memory _spenders, uint256[] memory _values, uint256 _txId) public returns (uint256 _bulkCount) {
        require(_spenders.length == _values.length, "Amount of spenders and values don't match");
        require(_spenders.length < BULK_MAX_COUNT, "Too many spenders");

        uint256 _bulkValue = 0;
        for (uint j = 0; j < _spenders.length; ++j) {
            _bulkValue = _bulkValue.add(_values[j]);
        }
        require(_bulkValue < BULK_MAX_VALUE, "Bulk value too high");

        bool _success;
        for (uint i = 0; i < _spenders.length; ++i) {
            _success = increaseApproval(_spenders[i], _values[i]);
            if (_success) {
                _bulkCount = _bulkCount.add(1);
            }
        }
        emit BulkApproval(_txId, _bulkCount);
        return _bulkCount;
    }

    // Like transfer, but fails quietly.
    function transferQuiet(address _to, uint256 _value) internal returns (bool success) {
        if (_to == address(0)) return false; // Preclude burning tokens to uninitialized address.
        if (_to == address(this)) return false; // Preclude sending tokens to the contract.
        if (balances[msg.sender] < _value) return false;

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}