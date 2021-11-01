/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity ^0.4.0;


contract Raise{
    
    
    address public owner;
    
    address public investmentAddresss;
    
    event Record(
        
        address investmentAddress,
        
        address raisesAddress,
        
        uint investmentNumber
        
        );
    
    
    event TotalValue(
        
        uint investmentNumber
        
        );
    
    
    // 投资者 
    struct investment{
        
        address investmentAddress;
        
        uint  investmentNumber;
        
    }
    
    // 发起者 
    struct raises{
        
        address  raisesAddress;
        
        uint  raisesNumber;
        
        uint  nowAccount;
        
        mapping(uint => investment) map;
    }
    
    
    constructor() public{
        
        owner = msg.sender;
        
    }
    
    
    uint investmentId;
    
    mapping(uint => raises) raisesMap;
    
    // 发起众筹 
    function Create(address _raisesAddress,uint _raisesNumber) public{
        
        investmentId++;
        
        raisesMap[investmentId] = raises(_raisesAddress,_raisesNumber,0);
        
    }
    
    // 转账 
    function transfer(address _investmentAddress,uint _investmentId) payable public{
        
        raises storage _raises = raisesMap[_investmentId];
        
        _raises.nowAccount += msg.value;
        
        investmentAddresss = _investmentAddress;
        
        emit Record(_investmentAddress,owner,msg.value);
        
        emit TotalValue(msg.value);
        
        _raises.map[_investmentId] = investment(_investmentAddress,msg.value);
        
    }
    
    // 判断众筹是否结束  
    function IsEnd(uint _investmentId) public{
        
        raises storage _raises = raisesMap[_investmentId];
        
        if(_raises.nowAccount >= _raises.raisesNumber){
            
            _raises.raisesAddress.transfer(_raises.raisesNumber);
    
        }
        
    }
    
}