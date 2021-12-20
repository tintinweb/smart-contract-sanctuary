/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

pragma solidity 0.8.4;
    contract BidenLooser{
    string public name = "ELON 2024";
    string public symbol = "ELON24";
    uint256 public totalSupply = 100000000;
    uint8 public decimals = 12;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
    );

    mapping(address => uint256) public balanceOF;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOF[msg.sender] = totalSupply;

    }


    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
    require(balanceOF[msg.sender] >= _value);
    return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOF[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOF[_from] -= _value;
        balanceOF[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}