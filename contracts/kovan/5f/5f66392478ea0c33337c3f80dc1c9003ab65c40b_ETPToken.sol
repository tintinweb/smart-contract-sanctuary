/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract ETPToken{
    
    string public name = "Educate The People";
    string public symbol = "ETP";
    string public version = "ETP v1.0";
    uint256 public feePercentage = 5*10**9;
    uint256 public feeDivider = 100*10**9;
    uint256 public decimals = 10**9; // 9 decimals
    uint256 public totalSupply = 100000000*decimals ; //100 milllion 100000000
    uint256 public maxFeeAmount = 50000*10**9;
    uint public totalFee;
    address public feeCollector;
    
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
    
    
    modifier onlyFeeCollector(){
        require(msg.sender == feeCollector, 'Only Fee collector can run this function.');
        _;
    }

    constructor (address _owner) {
        balanceOf[_owner] = balanceOf[_owner]+totalSupply;
        totalFee == 0;
        feeCollector = _owner;
    }
    
    // Fee calculator for every transcation 
    function feeCalculation(uint value) public view returns(uint){
        uint feeDeduction = (value * feePercentage) / feeDivider;
        return feeDeduction;
    }
    
    
    // 5% fee on every transcation and it will go to single address 
    function transfer(address _to, uint256 _value) public returns(bool succes) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        uint feeDuduction = feeCalculation(_value);
        require(feeDuduction >= 0 , 'Fee should be more then zero Or not more then 50000');
        if(feeDuduction > maxFeeAmount){
            totalFee = totalFee+maxFeeAmount;
            balanceOf[feeCollector] = balanceOf[feeCollector] + maxFeeAmount; 
            _value -= maxFeeAmount;
            balanceOf[_to] = balanceOf[_to]+_value; 
            emit Transfer(msg.sender, _to, _value);
            return true;    
        }else{
            totalFee = totalFee+feeDuduction;
            balanceOf[feeCollector] = balanceOf[feeCollector] + feeDuduction; 
            _value -= feeDuduction;
            balanceOf[_to] = balanceOf[_to]+_value; 
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
    }

    //Required but not in use: 
    function approve(address _spender, uint256 _value) public returns (bool succes){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool succes){
        require( balanceOf[_from] >= _value );
        require( allowance[_from][msg.sender] >= _value);
        uint256 feeDuduction = feeCalculation(_value);
        if(feeDuduction <= maxFeeAmount){
            totalFee = totalFee+feeDuduction;
            _value -= feeDuduction;
            balanceOf[feeCollector] = balanceOf[feeCollector]+feeDuduction; 
            balanceOf[_from] = balanceOf[_from]-_value;
            balanceOf[_to] = balanceOf[_to] +_value; 
            allowance[_from][msg.sender] = allowance[_from][msg.sender] -_value;
            emit Transfer(_from, _to, _value);
            return true;
        }else{
            totalFee = totalFee+maxFeeAmount;
            _value -= maxFeeAmount;
            balanceOf[feeCollector] = balanceOf[feeCollector]+maxFeeAmount; 
            balanceOf[_from] = balanceOf[_from]-_value;
            balanceOf[_to] = balanceOf[_to] +_value; 
            allowance[_from][msg.sender] = allowance[_from][msg.sender] -_value;
            emit Transfer(_from, _to, _value);
            return true;
        }
    }

    function transferFee(address ecoAddress) external onlyFeeCollector() returns (bool success){
        require(totalFee > 0);
        balanceOf[ecoAddress] = balanceOf[ecoAddress]+totalFee;
        balanceOf[msg.sender] = balanceOf[msg.sender]-totalFee;
        emit Transfer(msg.sender, ecoAddress, totalFee);
        totalFee = 0;
        return true;
    }
    
    function distributePayouts(address _to, uint256 _value) public returns (bool succes){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value; 
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    
}