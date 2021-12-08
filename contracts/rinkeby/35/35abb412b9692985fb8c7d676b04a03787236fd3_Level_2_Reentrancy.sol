/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.6.0;

contract Level_2_Reentrancy {
    string constant name = "Token";
    string constant symbol = "T";
    uint8 constant decimals = 18;
    uint public totalSupply;
    bool public levelComplete;

    mapping (address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor () public payable {
    	require(msg.value >= 1 ether);
        totalSupply = msg.value;
        levelComplete = false;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function deposit() public payable returns (bool success) {
        if (balances[msg.sender] + msg.value < msg.value) return false;
        if (totalSupply + msg.value < msg.value) return false;
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        return true;
    }

    function withdraw(uint256 _value) public payable returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        msg.sender.call.value(_value)("");
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        if (balances[_to] + _value < _value) return false;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function completeLevel() external {
    	require(balances[msg.sender] > totalSupply || totalSupply < 1000000000000000000);
    	levelComplete = true;
    }

}