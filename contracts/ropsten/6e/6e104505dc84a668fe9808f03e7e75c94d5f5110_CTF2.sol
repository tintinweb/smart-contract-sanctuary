pragma solidity 0.5.2;

// 1. Deploy this contract
// 2. Empty account of 0x0000000000000000000000000000000000000000

contract CTF2 {
    string public name = "New Coin";
    string public symbol = "NEW";
    uint256 public totalSupply = 1000000;
    address public owner;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor() public {
        balanceOf[address(0)] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _from, address _to, uint _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function mint(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        balanceOf[_to] += _value;
        emit Mint(_to, _value);
        return true;
    }

}