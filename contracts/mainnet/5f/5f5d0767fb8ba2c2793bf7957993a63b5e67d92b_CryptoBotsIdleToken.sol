pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Extension is Ownable {

    mapping(address => bool) extensions;

    function addExtension(address _contract) public onlyOwner {
        extensions[_contract] = true;
    }

    function hasExtension(address _contract) public view returns (bool){
        return extensions[_contract];
    }

    function removeExtension(address _contract) public onlyOwner {
        delete extensions[_contract];
    }

    modifier onlyExtension() {
        require(extensions[msg.sender] == true);
        _;
    }
}

contract CryptoBotsIdleToken is Ownable, Extension {

    string public name = "CryptoBots: Idle Token";
    string public symbol = "CBIT";
    uint8 public decimals = 2;

    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    //Event which is triggered to log all transfers to this contract&#39;s event log
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //Event which is triggered whenever an owner approves a new allowance for a spender.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function batchTransfer(address[] _to, uint256 _value) public {
        balances[msg.sender] = safeSub(balances[msg.sender], safeMul(_to.length, _value));

        for (uint i = 0; i < _to.length; i++) {
            balances[_to[i]] += safeAdd(balances[_to[i]], _value);
            emit Transfer(msg.sender, _to[i], _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);

        if (hasExtension(_to) == false && hasExtension(_from) == false) {
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function create(uint _amount) public onlyOwner {
        balances[msg.sender] = safeAdd(balances[msg.sender], _amount);
        totalSupply = safeAdd(totalSupply, _amount);
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
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