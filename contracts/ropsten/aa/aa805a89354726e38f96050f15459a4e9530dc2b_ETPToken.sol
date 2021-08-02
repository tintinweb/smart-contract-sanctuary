/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

pragma solidity 0.5.16;
//SPDX-License-Identifier: MIT

contract ETPToken{
    
    string public name = "Educate The People";
    string public symbol = "ETP";
    string public version = "ETP v1.0";
    uint256 public feePercentage = 5;
    uint256 public totalSupply = 100000000;
    uint256 public fee;
    uint256 public maxFeeAmount = 20000;
    uint public totalFee;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner, 
        address indexed _spender,
        uint256 _value
    );

    constructor (uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalFee == 0;
    }

    function transfer(address _to, uint256 _value) public returns(bool succes) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        fee = _value / 100 * feePercentage;

        require(fee >= 0);
        if(fee >= maxFeeAmount){
        fee == maxFeeAmount;
        }

        totalFee += fee;

        _value -= fee;
        balanceOf[_to] += _value; 

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //Required but not in use: 
    function approve(address _spender, uint256 _value) public returns (bool succes){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool succes){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value; 
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFee() public returns (bool success){
        require(totalFee > 0);
        emit Transfer(msg.sender, 0x206708A8F51e61C9bD9c2329fE16FAFB38476E3D, totalFee);
        totalFee = 0;
        return true;
    }
}