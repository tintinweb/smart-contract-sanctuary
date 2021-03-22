/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity >=0.7.0 <0.8.0;

contract WrappedEther {
    string public name = "WrappedEther";
    string public symbols = "WETH";
    uint public decimals = 18;
    uint public totalSupply = 1000000000000000000000000;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );
    event Appoval(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) allowance;
    
    constructor(){
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Appoval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success){
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}