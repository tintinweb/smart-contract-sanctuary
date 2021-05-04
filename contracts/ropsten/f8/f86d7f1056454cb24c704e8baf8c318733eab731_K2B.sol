/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity >=0.7.0 <0.9.0;

contract K2B{
    // instansiasi
    string  public name         = "Kita Kaya Bersama";
    string  public symbol       = "K2B";
    uint256 public totalSupply  = 10000000000000000000;
    uint256 public decimals     = 8;
    
    // event tx
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    
    // event approve
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // constructor
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}