/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

pragma solidity ^0.5.0;

contract ZKTESTToken {
    string  public name = "ZKTEST Token";
    string  public symbol = "ZKTEST";
	uint256 public totalSupply = 1000000000000000000000000000000000; 
    uint8   public decimals = 18;

    // Wei smallest units
    // 1000000000000000000000000
    // 100000000000000000

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value,'balance too low');
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from]>=_value,'balance too low');
        require(allowance[_from][msg.sender]>=_value,'allowance too low');
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}