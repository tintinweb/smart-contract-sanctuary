/**
 *Submitted for verification at Etherscan.io on 2020-06-26
*/

pragma solidity ^0.6.0;
/// @author Ur Lord and Saviour


contract Blessings {
    string public name;
    string public symbol;
    string public LordMessage;
    string public OurChurch;

    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    constructor() public{
        name = "Blessings";
        symbol = "BLS";
        decimals = 0;
        totalSupply = 21110000;
        balanceOf[msg.sender] = totalSupply;
        LordMessage = "2 Pedro 1:11. For so an entrance shall be ministered unto you abundantly into the everlasting kingdom of our Lord and Saviour JesusCrypto";
        OurChurch = "https://t.me/joinchat/AL7enxUK4e-DuuKkZJV22w";
        
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender]>= _value);
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
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from] [msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}