/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.5.16;

contract wXLA {
    string  public name = "Wrapped Scala";
    string  public symbol = "wXLA-t1";
    string  public standard = "wXLA Token v1.0";
    uint256 public totalSupply;
    address public owner;

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

    constructor () public {
        owner = msg.sender;
    }

    
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

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
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function mintToken(uint256 _amountToMint, address _to) public onlyOwner {
        require(_amountToMint > 0);

        balanceOf[_to] += _amountToMint;
        totalSupply += _amountToMint;
    }
}