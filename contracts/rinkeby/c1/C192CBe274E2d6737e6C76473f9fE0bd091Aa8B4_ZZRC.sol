// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @custom:security-contact [email protected]
contract ZZRC {
    string public constant name = "Zazerkale";
    string public constant symbol = "ZZRC";
    uint8 public constant decimals = 18;
    uint public totalSupply;
    address public owner;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    constructor(uint _initialSupply) {
        owner = msg.sender;
        mint(msg.sender, _initialSupply * 10 ** decimals);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transfer(address _to, uint _value) public returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(balanceOf[_from] >= _value);
        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint).max) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;
        emit Transfer(msg.sender, address(0), _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}