/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

pragma solidity ^0.4.20;

contract ERC20Interace{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
contract UpChain is ERC20Interace {

    mapping(address => uint256) public blanceOf;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public{
        name = "UpChain";
        symbol = "UPT";
        decimals = 0;
        totalSupply = 1000000;
        blanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        
        require(blanceOf[msg.sender] >= _value);
        require(blanceOf[_to] + _value >= blanceOf[_to]);
        
        blanceOf[msg.sender] -= _value;
        blanceOf[_to] += _value;

        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

        require(allowed[_from][msg.sender] >= _value);
        require(blanceOf[_from] >= _value);
        require(blanceOf[_to] + _value >= blanceOf[_to]);
        
        blanceOf[_from] -= _value;
        blanceOf[_to] += _value;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(msg.sender,_to,_value);

        return true;

    }
    function approve(address _spender, uint256 _value) public returns (bool success){

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;

    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

}