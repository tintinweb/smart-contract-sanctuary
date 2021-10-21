/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000 * 10 ** 18;
    string public name = "token test";
    string public symbol = "test";
    uint public decimals = 18;
    address public owner = address(0);
    uint fee = 12;
    uint max = 3;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function ownerSetFee(uint _fee) public { 
        require(msg.sender == owner, 'only owner allowed');
        require(fee <= 99 && fee >= 0, 'fee must be between 0 and 99'); 
        fee = _fee;
    }
    
    function ownerSetMax(uint _max) public { 
        require(msg.sender == owner, 'only owner allowed');
        require(fee <= 99 && fee >= 1, 'max cap must be between 1 and 99'); 
        max = _max;
    }
    
    function ownerSetOwner(address _owner) public { 
        require(msg.sender == owner, 'only owner allowed');
        require(_owner != address(0), 'empty address not allowed'); 
        owner = _owner;
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint amount = percent(value, 100 - fee);
        require(balanceOf(to) + amount < percent(totalSupply, max), 'reached maximum token cap per account');
        balances[msg.sender] -= value;
        balances[owner] += percent(value, fee);
        balances[to] += amount;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        uint amount = percent(value, 100 - fee);
        require(balanceOf(to) + amount < percent(totalSupply, max), 'reached maximum token cap per account');
        balances[from] -= value;
        balances[owner] += percent(value, fee);
        balances[to] += percent(value, 100 - fee);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function percent(uint _amount, uint _prc) internal pure returns(uint) { return (_amount * _prc) / 100; }
}