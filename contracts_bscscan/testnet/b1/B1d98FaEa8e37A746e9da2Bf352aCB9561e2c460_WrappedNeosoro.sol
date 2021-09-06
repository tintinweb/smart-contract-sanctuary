/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity 0.8.4;

contract WrappedNeosoro {
    
    string public name = "Wrapped Neosoro";
    string public symbol = "WNEO";
    uint256 public totalSupply = 1000000000000000000000000;
    uint8 public decimals = 18;
    uint public donateFee = 3;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        uint _donateValue = (_value * donateFee / 100);
        balanceOf[_to] += _value - _donateValue;
        balanceOf[0x0000000000000000000000000000000000000000] += _donateValue;
        balanceOf[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}