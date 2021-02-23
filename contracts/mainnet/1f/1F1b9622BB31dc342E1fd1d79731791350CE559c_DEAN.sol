/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity ^0.6.6;
contract DEAN {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    event ChangeSupply(uint amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event IsFrozenAccount(address target, bool isFrozen);
    event Burn(address target, uint amount);

    mapping(address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public frozenAccount;

    constructor() public {
        owner = msg.sender;
        name = "DEAN";
        symbol = "DEAN";
        decimals = 18;
        totalSupply = 200000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    modifier onlyOwner {
        if(msg.sender != owner) {
            return;
        }
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    function changeSupply(address target, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[target] += amount;

        emit ChangeSupply(amount);
        emit Transfer(address(0), target, amount);

    }
    function freezeAccount(address target, bool isFrozen) public onlyOwner{
        frozenAccount[target] = isFrozen;
        emit IsFrozenAccount(target, isFrozen);
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        if((_to != address(0)) && (!frozenAccount[msg.sender]) && (balanceOf[msg.sender] >= _value) && (balanceOf[_to] + _value >= balanceOf[_to])) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        if((_to != address(0)) && (!frozenAccount[_from]) && (allowed[_from][msg.sender] >= _value) && (balanceOf[msg.sender] >= _value) && (balanceOf[_to] + _value >= balanceOf[_to])) {
            allowed[msg.sender][_from] -= _value;
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            return true;
        }
        return false;
    }
    function allowance(address _owner, address _spender) view public returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function burn(uint256 _value) public onlyOwner returns(bool success){
        if(balanceOf[msg.sender] >= _value){
            totalSupply -= _value;
            balanceOf[msg.sender] -= _value;
            emit Burn(msg.sender, _value);
            return true;
        }
        return false;
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner returns(bool success){
        if((balanceOf[_from] >= _value) && (allowed[_from][msg.sender] >= _value)) {
            totalSupply -= _value;
            balanceOf[msg.sender] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Burn(msg.sender, _value);
            return true;
        }
        return false;
    }
}