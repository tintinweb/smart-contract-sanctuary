/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.6.0;

contract MTT {
    string constant public name = "My test token";
    string constant public symbol = "MTT";
    uint8 constant public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        _transfer(address(0), msg.sender, 114514 ether);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance.");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        if (_from == address(0)) {
            // mint
            totalSupply += _value;
        } else {
            // transfer from
            require(balanceOf[_from] >= _value, "Insufficient balance.");
            balanceOf[_from] -= _value;
        }
        if (_to == address(0)) {
            // burn
            totalSupply -= _value;
        } else {
            // transfer into
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
    }
}