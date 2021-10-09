/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity ^0.8.7;

contract Sothc {
    string  public name = "Sothc";
    string  public symbol = "Sothc";
    string  public standard = "Sothc v1.0";
    uint256 public totalSupply = 10000000000;
    address private admyn;

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

    constructor() {
        admyn = msg.sender;
        balanceOf[admyn] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function mint() public returns (bool success) {
        balanceOf[msg.sender] += 10000;
        return true;
    }


    function burn(uint256 ammount) public returns (bool success) {
        require(admyn == msg.sender);
        emit Transfer(msg.sender, admyn, ammount);
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