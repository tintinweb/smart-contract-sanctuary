/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.5.0;
contract roy{
    address public admin;
    
    
    struct Users{
        bool exsist;
        address Account;
        string Name;
        uint Time;
        
        
    }
    mapping(address=>uint) public balance;
    mapping(address=>Users)public details;
    modifier onlyowner{
        require (msg.sender== admin,"invalis admin");
        _;
    }
    constructor()public {
        admin = msg.sender;
    }
    
    function userdetails(address _account,string memory _Name)onlyowner public {
       Users memory users;
       users= Users(true,_account,_Name,now);
       details[_account]=users;
    }
    function deposit()payable public{
       
        require(admin!= msg.sender,"invalid user");
        balance[msg.sender]= msg.value;
        details[msg.sender].Time=block.timestamp;
        
        
    }
    
    function withdraw() public returns(bool success){
        
        
        //calculation interest = principal*rate of interest*time//
         // 1 seconds = 2% (1 seconds = 0.1 ether);
         // 100 seconds = 10 ether;
          uint withdrawtime = block.timestamp;
          uint time= withdrawtime - details[msg.sender].Time ;
          uint value= balance[msg.sender];
          uint Interest= value *2/100*time;
          
          
         msg.sender.transfer(Interest);
          return true;
          
        
       
    }
       function fallback() payable  external{
       }
     
        
       
          
          
          
        
        
        
    }