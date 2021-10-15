/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: apache 2.0

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract wallet{
    
    bool public contract_is_active;
    address[4] public boardMember;
    address public dev_address;
    mapping( address => mapping(address => mapping(uint256 => uint256))) public allowed_amount;
 
    constructor( address member_1, address member_2, address member_3, address member_4) public {
        boardMember[0] = member_1;
        boardMember[1] = member_2;
        boardMember[2] = member_3;
        boardMember[3] = member_4;
        dev_address = msg.sender;

    }
    
    function pause ( bool _isActive) public{
           require(dev_address == msg.sender);
           contract_is_active = _isActive;
    }
        
    function vote (address token_contract_address, address _to, uint256 _amount) public{
     
        if(boardMember[0]== msg.sender){
            allowed_amount[token_contract_address][_to][0]=_amount;
            return();
        }
        if(boardMember[1]== msg.sender){
            allowed_amount[token_contract_address][_to][1]=_amount;
            return();
        }
        if(boardMember[2]== msg.sender){
            allowed_amount[token_contract_address][_to][2]=_amount;
            return();
        }
        if(boardMember[3]== msg.sender){
            allowed_amount[token_contract_address][_to][3]=_amount;
            return();
        }
        revert();
        
    }
    
    function check_allowence (address token_contract_address, address _to, uint256 _amount) public view returns(bool){
        
        uint256 approved_vote = 0;
        if(allowed_amount[token_contract_address][_to][0]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[token_contract_address][_to][1]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[token_contract_address][_to][2]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[token_contract_address][_to][3]>= _amount){
            approved_vote+=1;
           
        }
        
       if (approved_vote>=3){
           return(true);
       }
    
        return(false);
            
        
    }
    
    function transferToken (address token_contract_address, address _to, uint256 _amount) public{
        require(contract_is_active == true);
        require(msg.sender == dev_address);
        require(check_allowence(token_contract_address, _to, _amount) == true);
        allowed_amount[token_contract_address][_to][0]=0;
        allowed_amount[token_contract_address][_to][1]=0;
        allowed_amount[token_contract_address][_to][2]=0;
        allowed_amount[token_contract_address][_to][3]=0;
                             
        IERC20(token_contract_address).transfer(_to, _amount);
    }
}