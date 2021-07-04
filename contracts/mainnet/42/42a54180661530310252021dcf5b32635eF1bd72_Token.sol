/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity ^0.8.2;

contract Token {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public decimals = 18;
    uint public totalSupply = 250000000 * 10 ** decimals;
    uint public _totalSupply = totalSupply / (10**decimals);
    string public name = "FiveCoin";
    string public symbol = "FIVE";

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    address private owner;
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier _ownerOnly() {
      require(msg.sender == owner);
      _;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function issue(uint _amount) _ownerOnly public returns (bool) {
        uint amount = _amount * 10**decimals;
        require(totalSupply + amount > totalSupply , 'cannot issue a negative resultant');
        require(balances[owner] + amount > balances[owner] , 'cannot issue a negative resultant');

        balances[owner] += amount;
        totalSupply += amount;
        _totalSupply += _amount;
        emit Issue(amount);
        return true;
    }

    function burn(uint _amount) _ownerOnly public returns (bool) {
        uint amount = _amount * 10**decimals;
        require(totalSupply + amount > totalSupply , 'cannot burn, burn fewer coins');
        require(balances[msg.sender] + amount > balances[msg.sender] , 'cannot burn. Not enough coins in owner wallet');

        balances[owner] += amount;
        totalSupply -= amount;
        _totalSupply -= _amount;
        emit Burn(amount);
        return true;
    }

    event Issue(uint amount);
    event Burn(uint amount);
}