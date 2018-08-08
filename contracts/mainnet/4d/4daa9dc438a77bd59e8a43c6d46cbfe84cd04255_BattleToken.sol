pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract BattleToken is Ownable {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    string public name = "https://cryptobots.me/cbtb - CryptoBotsBattle";
    uint8 public decimals = 0;
    string public symbol = "CBTB";

    address public fights;

    function setFightsAddress(address _fights) public onlyOwner {
        fights = _fights;
    }

    function create(uint _amount) public onlyOwner {
        balances[msg.sender] = safeAdd(balances[msg.sender], _amount);
        totalSupply = safeAdd(totalSupply, _amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function batchTransfer(address[] _to, uint _value) public {
        balances[msg.sender] = safeSub(
            balances[msg.sender], _to.length * _value
        );
        for (uint i = 0; i < _to.length; i++) {
            balances[_to[i]] = safeAdd(balances[_to[i]], _value);
            Transfer(msg.sender, _to[i], _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        if (_to != fights) {
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}