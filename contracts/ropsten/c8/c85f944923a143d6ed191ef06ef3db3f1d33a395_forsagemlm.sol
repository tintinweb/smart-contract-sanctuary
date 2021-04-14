/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.5.17;
contract forsagemlm{
    address public owner;
    struct Users{
        uint id;
        address referrer;
        uint partnercount;
        
        mapping(uint=>bool)activex5level;
        mapping(uint=>bool)activex16level;
        mapping(uint=>bool)activeunilevel;
        
        mapping(uint=>X5) x5Matrix;
        mapping(uint=>X16)x16Matrix;
        mapping(uint=>unilevel)Unilevel;
    }
    struct X5{
        address currentreferrer;
        address[] referrals;
        bool blocked;
        uint reinvestcount;
        
        
        
    }
    struct X16{
        
    address currentreferrer;
    address[] firstlevelreferrals;
    address[] secondlevelreferrals;
    bool blocked;
    uint reinvestcount;
    
    
    }
    
    struct unilevel{
        address currentreferrer;
        address[] referrals;
        bool blocked;
    
    }
    

uint public constant last_level=12;


mapping(address => uint) public balances;
mapping(uint=>uint)public levelprice;
mapping(address=>Users)public users;
mapping(uint=>address)public idToaddress;
mapping(uint=>address) public userIds;

constructor(address _owner)public{
    levelprice[1]=0.025 ether;
    for(uint i=2;i<=last_level;i++){
        levelprice[i]= (levelprice[i-1]*2);
    }
    owner=_owner;
    Users memory user;
    user=Users({
        id:1,
        referrer:address(0),
        partnercount:0
    
    });
    users[owner]=user;
    idToaddress[1]=owner;
    
    
    for(uint i=1;i<=last_level;i++){
        users[owner].activex5level[i]=true;
        users[owner].activex16level[i]=true;
    }
        
        userIds[1]=owner;
}
     function registrationExt(address referreraddress)external payable{
         
                Registration(msg.sender,referreraddress);
     }
     
     uint lastuserid=2;
     
     function isUserEXsist(address user)public view returns(bool){
         users[user].id !=0;
     }
     
     function buylevel(uint Matrix,uint level)external payable{
         require(msg.value==levelprice[level],"invalid amount");
         
         require(Matrix==1||Matrix==2||Matrix==3,"invalidmatrix");
         require(level>0&&level<last_level,"invalid level");
         
         if(Matrix==1){
           require(!users[msg.sender].activex5level[level],"user already exsist");
         
          
             if(users[msg.sender].x5Matrix[level-1].blocked){
               users[msg.sender].x5Matrix[level-1].blocked=false;
           }
           
           
           address freeX5referrer= findFreeX5referrer(msg.sender,level);
           users[msg.sender].x5Matrix[level].currentreferrer=freeX5referrer;
           
           users[msg.sender].activex5level[level]=true; 
           updateX5Referrer(msg.sender,freeX5referrer,level);
          
         }
         
         else if(Matrix==2) {
             require(!users[msg.sender].activex16level[level],"user already exsist");
             
             if(users[msg.sender].x16Matrix[level-1].blocked){
                 users[msg.sender].x16Matrix[level-1].blocked=false;
                 
             }
             address freeX16referrer= findFreeX16referrer(msg.sender,level);
           users[msg.sender].x16Matrix[level].currentreferrer=freeX16referrer;
           
           users[msg.sender].activex16level[level]=true;
           updatex16referrer(msg.sender,freeX16referrer,level);
           
             
         }
         
         else{
             require(!users[msg.sender].activeunilevel[level],"useralready exsist");
             
             if(users[msg.sender].Unilevel[level-1].blocked){
                 users[msg.sender].Unilevel[level-1].blocked=false;
                 
             }
             
             address freeunilevelreferrer=findFreeunilevelreferrer(msg.sender,level);
             users[msg.sender].Unilevel[level].currentreferrer=freeunilevelreferrer;
             users[msg.sender].activeunilevel[level]=true;
             updtaeunilevelreferrer(msg.sender,freeunilevelreferrer,level);
         }
           
           
         
     }
     
     function Registration(address useraddress,address referreraddress)private{
         require(msg.value==0.075 ether, "invalid amount");
         require(!isUserEXsist(useraddress), "user exsist");
        
         
         
          uint32 size;
        assembly {
            size := extcodesize(useraddress)
        }
        require(size == 0, "cannot be a contract");
        
         
            
         Users memory user;
         user = Users({
             id:lastuserid,
             referrer:referreraddress,
             partnercount:0
         });
         users[useraddress]=user;
         idToaddress[lastuserid]=useraddress;
         
         users[useraddress].referrer=referreraddress;
          
         users[useraddress].activex5level[1]=true;
         users[useraddress].activex16level[1]=true;
         users[useraddress].activeunilevel[1]=true;
          
         
          userIds[lastuserid]=useraddress;
          
          
          lastuserid++;
          
          users[referreraddress].partnercount++;
          
          
          address freeX5referrer= findFreeX5referrer(useraddress,1);
          
          users[useraddress].x5Matrix[1].currentreferrer=freeX5referrer;
          
          
          updateX5Referrer(useraddress,freeX5referrer,1);
          updatex16referrer(useraddress,findFreeX16referrer(useraddress,1),1);
        updtaeunilevelreferrer(useraddress,findFreeunilevelreferrer(useraddress,1),1);
          
          
     }
     
     function findFreeX5referrer(address useraddress,uint level)public view returns(address){
         while(true){
             if(users[users[useraddress].referrer].activex5level[level]){
                   return(users[useraddress].referrer);
         }
             useraddress=users[useraddress].referrer;
         }
     }
     
     
     
     function findFreeX16referrer(address useraddress,uint level)public view returns(address){
         while(true){
             if(users[users[useraddress].referrer].activex16level[level]){
                 return (users[useraddress].referrer);
             }
             useraddress=users[useraddress].referrer;
         }
     }
     
     function findFreeunilevelreferrer(address useraddress,uint level)public view returns(address){
            while(true){
                if(users[users[useraddress].referrer].activeunilevel[level]){
                    
                    return (users[useraddress].referrer);
                }
                useraddress=users[useraddress].referrer;
            }
        }
     
     
     function updateX5Referrer(address useraddress,address referreraddress,uint level)private{
         users[referreraddress].x5Matrix[level].referrals.push(useraddress); 
         
        if (users[referreraddress].x5Matrix[level].referrals.length<5){
           
            return SendETHDividends(referreraddress,useraddress,1,level);
        }
        
       
        
        
         users[referreraddress].x5Matrix[level].referrals = new address[](0);
         
          if (!users[referreraddress].activex5level[level+1] && level != last_level) {
            users[referreraddress].x5Matrix[level].blocked = true;
        }
        
        
        if(referreraddress!=owner){
            address freereferreraddress= findFreeX5referrer(referreraddress,level);
            if(users[referreraddress].x5Matrix[level].currentreferrer!=freereferreraddress){
                users[referreraddress].x5Matrix[level].currentreferrer =freereferreraddress;
            }
            users[referreraddress].x5Matrix[level].reinvestcount++;
            
        }
        else{
            SendETHDividends(owner,useraddress,1,level);
            users[owner].x5Matrix[level].reinvestcount++;
           
            
            
        }
     }
     
     function updtaeunilevelreferrer(address useraddress,address referreraddress,uint level)private{
         users[referreraddress].Unilevel[level].referrals.push(useraddress);
         
         
         
         
          if (!users[referreraddress].activeunilevel[level+1] && level != last_level) {
            users[referreraddress].Unilevel[level].blocked = true;
          }
        
           if(referreraddress!=owner){
            address freereferreraddress= findFreeunilevelreferrer(referreraddress,level);
              if(users[referreraddress].Unilevel[level].currentreferrer!=freereferreraddress){
                users[referreraddress].Unilevel[level].currentreferrer =freereferreraddress;
                
                return SendETHDividends(referreraddress,useraddress,3,level);
            }
           }
           else{
               return SendETHDividends(owner,useraddress,3,level);
           }
          
            
        
            
         
             
         
         
     }
        
        
        function updatex16referrer(address useraddress,address referreraddress,uint level)private{
           require (users[referreraddress].activex16level[level],"inactive referrer");
           
           
           if (users[referreraddress].x16Matrix[level].firstlevelreferrals.length<4){
           users[referreraddress].x16Matrix[level].firstlevelreferrals.push(useraddress);
         
        
        
            users[useraddress].x16Matrix[level].currentreferrer=referreraddress;
            
              if(referreraddress==owner){
               return SendETHDividends(referreraddress,useraddress,2,level);
              }
            
            
         address ref=users[referreraddress].x16Matrix[level].currentreferrer;
           
           users[ref].x16Matrix[level].secondlevelreferrals.push(useraddress);
           
           return updatex16secondlevelreferrer(useraddress,ref,level);
           }
               }
           
           
    function updatex16secondlevelreferrer(address useraddress,address referreraddress,uint level)private{
          if(users[referreraddress].x16Matrix[level].secondlevelreferrals.length<16){
              SendETHDividends(referreraddress,useraddress,2,level);
          }
          
          users[referreraddress].x16Matrix[level].firstlevelreferrals=new address[](0);
          users[referreraddress].x16Matrix[level].secondlevelreferrals=new address[](0);
          
          if(!users[referreraddress].activex16level[level+1]&&level!=last_level){
              users[referreraddress].x16Matrix[level].blocked=true;
          }
          users[referreraddress].x16Matrix[level].reinvestcount++;
          
          if(referreraddress!=owner){
               address freereferreraddress= findFreeX5referrer(referreraddress,level); 
               
               updatex16referrer(referreraddress,freereferreraddress,level);
          }
          else{
              SendETHDividends(owner,useraddress,2,level);
          }
          
          
         
              
          }
    
 function FindETHReceiver(address useraddress,address _from,uint matrix,uint level)private returns(address){
         address receiver=useraddress;
        
         if(matrix==1){
             while(true){
                 if(users[receiver].x5Matrix[level].blocked){
                    
                     
                     receiver=users[receiver].x5Matrix[level].currentreferrer;
                 }
                 else {
                     return (receiver);
                 }
             }
         }
         else if (matrix==2){
             while(true){
                 if(users[receiver].x16Matrix[level].blocked){
                      
                      
                     receiver=users[receiver].x16Matrix[level].currentreferrer;
                 }
                 else{
                     return(receiver);
                 }
                     
                 }
             }
             
             else{
                 while(true){
                     if(users[receiver].Unilevel[level].blocked){
                         receiver=users[receiver].Unilevel[level].currentreferrer;
                     }
                     else{
                         return(receiver);
                     }
                 }
             }
 }
         
         
     
     function SendETHDividends (address useraddress,address _from,uint Matrix,uint level)private{
         (address receiver)=FindETHReceiver(useraddress,_from,Matrix,level);
         
         if(!address(uint160(receiver)).send(levelprice[level])){
             return address(uint160(receiver)).transfer(address(this).balance);
             
         }
     }
       function usersActiveX5Levels(address useraddress, uint8 level) public view returns(bool) {
        return users[useraddress].activex5level[level];
       }
       
       
        function usersActiveX16Levels(address useraddress, uint8 level) public view returns(bool) {
        return users[useraddress].activex16level[level];
    }
    
    
    function userActiveUnilevel(address useraddress,uint8 level)public view returns(bool){
        return users[useraddress].activeunilevel[level];
    }
    
    
    function usersX5Matrix(address useraddress, uint8 level) public view returns(address, address[] memory, bool) {
        return (users[useraddress].x5Matrix[level].currentreferrer,
                users[useraddress].x5Matrix[level].referrals,
                users[useraddress].x5Matrix[level].blocked);
    }
    
    function usersX16Matrix(address useraddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool) {
        return (users[useraddress].x16Matrix[level].currentreferrer,
                users[useraddress].x16Matrix[level].firstlevelreferrals,
                users[useraddress].x16Matrix[level].secondlevelreferrals,
                users[useraddress].x16Matrix[level].blocked);
            
    }
    
    function usersUnilevel(address useraddress,uint8 level)public view returns(address,address[]memory,bool){
        return(users[useraddress].Unilevel[level].currentreferrer,
        users[useraddress].Unilevel[level].referrals,
        users[useraddress].Unilevel[level].blocked);
    }
    

    
}