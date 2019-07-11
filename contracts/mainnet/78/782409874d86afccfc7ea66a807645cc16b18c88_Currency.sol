/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.1;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {

    address public owner;

    address newOwner = address(0x0);

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function changeOwner(address _newOwner) public isOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

}

contract Controlled is Owned {

    bool public transferEnable = true;

    bool public lockFlag = true;

    constructor() public {
       setExclude(msg.sender);
    }

    mapping(address => bool) public locked;

    mapping(address => bool) public exclude;

    function disableLock(bool _enable) public isOwner returns (bool success){
        lockFlag = _enable;
        return true;
    }

    function enableTransfer(bool _enable) public isOwner{
        transferEnable = _enable;
    }

    function addLock(address _addr) public isOwner returns (bool success){
        require(_addr != msg.sender);
        locked[_addr] = true;
        return true;
    }

    function setExclude(address _addr) public isOwner returns (bool success){
        exclude[_addr] = true;
        return true;
    }

    function removeLock(address _addr) public isOwner returns (bool success){
        locked[_addr] = false;
        return true;
    }

    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            assert(transferEnable);
            if(lockFlag){
                assert(!locked[_addr]);
            }
        }
        _;
    }

    modifier validAddress(address _addr) {
        assert(address(0x0) != _addr && address(0x0) != msg.sender);
        _;
    }
}

contract StandardToken is Token, Controlled {

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) validAddress(_to) returns (bool success) {
        require(_value > 0);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(msg.sender) validAddress(_to) returns (bool success) {
        require(_value > 0);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Currency is StandardToken {

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    constructor (address _addr, uint256 initialSupply, string memory _tokenName, string memory _tokenSymbol) public {
        setExclude(_addr);
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[_addr] = totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
    }

}