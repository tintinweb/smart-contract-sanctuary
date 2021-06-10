/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.4.26;

contract KarlSwap {
    string public symbol = "KCN";
    string public name = "KarlCoin";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 * decimals;
    address public owner;
    bool setupDone = false;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    // function KarlSwap() public  {
    //     owner = msg.sender;    
    //     balances[owner] = totalSupply;
    // }
    
    constructor() public {
        owner = msg.sender;   
        balances[msg.sender] = totalSupply; // 初始token数量给予消息发送者，因为是构造函数，所以这里也是合约的创建者
        
    }

    // function owner(string tokenName, string tokenSymbol, uint256 supply) public {
    //     if (msg.sender == owner && setupDone == false)
    //     {
    //         symbol = tokenSymbol;
    //         name = tokenName;
    //         balances[owner] = totalSupply;
    //         setupDone = true;
    //     }
    // }

    // function totalSupply() public returns ( uint256 supply)  {        
    //     return 100000000000;
    // }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success)   {
        if (balances[msg.sender] >= _amount
            && _amount != 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount != 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}