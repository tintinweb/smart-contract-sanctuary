//"SPDX-License-Identifier: MIT"
pragma solidity ^0.7.0;


import './Consumer.sol';
import './Roles.sol';


contract Provider{
    using Roles for Roles.Role;

    Roles.Role private _Storage_Ownable;
    
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner,"NotOwner");
        _;
    }
    
    
     struct ProviderInfo{
        string name;
        address owner;
        string nodeSize;
        uint ClusterID;
        string CID;
        address[] peersList;
        string NodeType;
        string AvailableNodeSize;
        
     }
       
        //Node Type -> External,Native,Embedded,public
        
        // struct Node{
        //     string ClusterID;
        //     string CID;
        //     string TotalNodeSize;
        //     string NodeType;
        //     string AvailableNodeSize;
            
            
        // }
        
        
       
       mapping(address => ProviderInfo) public providers; 
        
      function CreateCluster(string memory clustername,string memory TotalNodeSize,uint clusterID,
      string memory CID,address[] memory consumers,string memory NodeType,string memory AvailableNodeSize) public
      {
           providers[msg.sender]=ProviderInfo(clustername,msg.sender,TotalNodeSize,clusterID,CID,consumers,NodeType,AvailableNodeSize);
      }
        
      function viewApplicationInfo(uint appId,address contractaddr) public view returns(address,string memory,string memory,bool,uint, Consumer.Status)
      {
          Consumer ctr=Consumer(contractaddr);
          return ctr.ViewApplication(appId);
          
      }
        
        
      
        
    function GrantAccess(address[] memory consumers) 
        
        public onlyOwner
       {
        for (uint256 i = 0; i < consumers.length; ++i) {
           _Storage_Ownable.add(consumers[i]);
        }

        
    }
    
    function RevokeAccess(address[] memory consumers)
        
        public onlyOwner
       {
        for (uint256 i = 0; i < consumers.length; ++i) {
           _Storage_Ownable.remove(consumers[i]);
        }

        
    }
    
    function CheckAccess() public view returns(string memory){
   
        require(_Storage_Ownable.has(msg.sender), "DOES_NOT_HAVE_STORAGE_OWNABLE_ROLE");

        return("hash value");
    }
    
    // function GrantStorage(uint appId,address consumer_addr,address contractaddr) 
        
    //     public onlyOwner returns(string memory)
    //   {
    //     require(_Storage_Ownable.has(consumer_addr), "DOES_NOT_HAVE_STORAGE_OWNABLE_ROLE");
    //     return("Hash Value");
    //     //After returning hash value to consumer,need to update the status of consumer application as Allocated.
       
        
    //  }

        
    
        
        
    
}