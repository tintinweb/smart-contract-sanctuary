//"SPDX-License-Identifier: MIT"
pragma solidity ^0.7.0;

import {BlockSpaceToken} from './ERC20.sol';

contract Consumer is BlockSpaceToken{
    
      enum Status{
            Initiated, // raised Application
            Processed, // Payment completion
            Allocated // Storage Allocation
        }
        
        struct StorageApplication{
            string name;
            address ConsumerAddress;
            string NodeSize;// storage size
            string NodeType;//Node Type -> External,Native,Embedded,public
            bool EMI;
            uint duration;
            Status status;
   
        }
        
    
    mapping(uint => StorageApplication) public applications;
    uint public  numapplications;
    
    function CreateApplication(string memory name,string memory NodeSize,string memory NodeType,bool EMI,uint duration) public {
        address consumer_address = msg.sender;
        applications[numapplications] = StorageApplication(name,consumer_address,NodeSize,NodeType,EMI,duration,Status.Initiated);
        numapplications++;
        
    }
    
    function getStatus(uint appID) public view returns(Status)
    {
        return applications[appID].status;
        
    }
    
    // use javascript to view the application created by consumer
    
    function ViewApplication(uint appId) public view returns(address,string memory,string memory,bool,uint,Status)
    {
        return (applications[appId].ConsumerAddress,
                applications[appId].NodeSize,
                applications[appId].NodeType,
                applications[appId].EMI,
                applications[appId].duration,
                applications[appId].status);
    }
    
    // function PayEMI(uint amount) public{
    //     uint EMI_AMT= amount;
    // }
    
    function JoinCluster(uint clusterID) public view returns(address,uint){
        return(msg.sender,clusterID);
        
    }
}