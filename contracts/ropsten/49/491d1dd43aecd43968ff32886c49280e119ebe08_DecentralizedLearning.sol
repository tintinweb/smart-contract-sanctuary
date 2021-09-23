/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.4.17;

contract DecentralizedLearning {
    string  public name = "Decentralized Learning Coin";
    string  public symbol = "DLRN";
    string  public standard = "DLRN Token v1.0";
    uint8   public decimals = 4; // same value as wei
    uint256 public totalSupply = 100000000000;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

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

    function mint(uint256 _value) private {
        balanceOf[msg.sender] = totalSupply;
        totalSupply += _value;
        // TODO: Handle fractional tokens
        // TODO: Trigger a transfer event when deploying
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

}