/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.4.2;

contract Token {
    string  public name = "USDT";
    string  public symbol = "USDT";

    uint256 public decimals = 18;
    uint256 public totalSupply;

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
    address owner;

    function Token (string _initialSupply) public {
        uint256 amount = stringToUint(_initialSupply) * 1000000000000000000;
        balanceOf[msg.sender] = amount;
        totalSupply = amount;
        owner = msg.sender;
    }

    function stringToUint(string s) constant public returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
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

    // function terminate() public {
    //     require(msg.sender == owner, "Only the owner account may destroy token");
    //     selfdestruct(owner);
    // }
}