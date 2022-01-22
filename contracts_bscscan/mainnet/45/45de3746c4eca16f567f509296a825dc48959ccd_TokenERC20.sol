/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
contract TokenERC20{
    string public name = "BabyFist";
    string public symbol = "BabyFist";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000;

    address marketAddress = 0x552691C0c287b0a5509A3f79012c23FC8B865DE3;
    address hold = address(0);
    uint256 marketFee = 2;
    uint256 holdFee = 6;
 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
 
    constructor () public {
        totalSupply = totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
 
 
    function _transfer(address _from, address _to, uint _value) internal {
        uint256 mFee = _value * marketFee / 100;
        uint256 hFee = _value * holdFee / 100;
        _transfers(_from, address(0), hFee);
        _transfers(_from, marketAddress, mFee);
        _transfers(_from, _to, _value - mFee - hFee);
    }

    function _transfers(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
 
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        uint256 mFee = _value * marketFee / 100;
        uint256 hFee = _value * holdFee / 100;
        _transfer(_from, address(0), hFee);
        _transfer(_from, marketAddress, mFee);
        _transfer(_from, _to, _value - mFee - hFee);
        return true;
    }
 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}