/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "./TransferHelper.sol";

 
 interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value)
    external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
//  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

}

contract Investment {


    struct   X {
     string name;     // name of node
     uint256 parent;   // parent node’s path
     uint256 refererId;
     uint256 plan;     // node’s data
     uint256[] nodes;  // list of linked nodes’ paths
     bool isValue;
     uint256 balance;
     uint256 investmentAmount;
    }
    struct Xmax {
     string name;     // name of node
     uint256 parent;   // parent node’s path
     uint256 refererId;
     uint256 plan;     // node’s data
     uint256[] nodes;  // list of linked nodes’ paths
     bool isValue;
     uint256 balance;
     uint256 investmentAmount;
     uint256 totalUsersReferred;
    }
    struct User{
        uint256 uniqueId;
        bool isValue;
    }
    
    mapping(uint256=>uint256) upgradePlans;
    mapping(uint256=>uint256) planPrice;
    
    mapping(uint256 => X) groupX;
    mapping(uint256 => Xmax) groupXmax;
    mapping(address=>User) address_Id;
    mapping(uint256=> address) id_address;
    uint256 lastId=1;

    mapping(address => bool) adminMembers;
    mapping(address => string ) ids;
    address rootAdminAccount;
    address bonusAdminAccount;
    uint256 XbonusAccountBalance;
    uint256 XMaxbonusAccountBalance;
    IERC20 token = IERC20(0xF615aeFd54f738d0bAB1c38ed736BD1669e64e39);
    
    uint256 nextRefreshTIme;
    uint256 usersRegisteredLastOneDay=0;
    uint256 amountInvestedLastOneDay=0;
    uint256 xmaxAmountInvestedLastOneDay=0;
    uint256 xAmountInvestedLastOneDay=0;
    
    uint256 lastInvestedId;
    uint256 totalAmountInvestedAllTime;
    // uint256 lastInvestedTime;
   
     constructor (address RootAdmin,address BonusAdmin){
         rootAdminAccount=RootAdmin;
         bonusAdminAccount=BonusAdmin;
         uint256 id=lastId;
         uint256[] memory tempArr;
         id_address[id]=RootAdmin;
         address_Id[RootAdmin]=User({
            uniqueId:id,
            isValue:true
        });
         lastId+=1;
         groupX[id]=X({
             name:"rootAdmin",
             parent:0,
             refererId:0,
             plan:9900,
             nodes:tempArr,
              isValue:true,
              balance:0,
              investmentAmount:0
         });
         groupXmax[id]=Xmax({
             name:"rootAdmin",
             parent:0,
             refererId:0,
             plan:9900,
             nodes:tempArr,
             isValue:true,
             balance:0,
             investmentAmount:0,
             totalUsersReferred:0
         });
         
         upgradePlans[5]=10;
         upgradePlans[10]=20;
         upgradePlans[20]=40;
         upgradePlans[40]=80;
         upgradePlans[80]=160;
         upgradePlans[160]=320;
         upgradePlans[320]=640;
         upgradePlans[640]=1250;
         upgradePlans[1250]=2500;
         upgradePlans[2500]=5000;
         upgradePlans[5000]=9900;
         
         planPrice[5]=10e18;
         planPrice[10]=10e18;
         planPrice[20]=20e18;
         planPrice[40]=40e18;
         planPrice[80]=80e18;
         planPrice[160]=160e18;
         planPrice[320]=320e18;
         planPrice[640]=640e18;
         planPrice[1250]=1250e18;
         planPrice[2500]=2500e18;
         planPrice[5000]=5000e18;
         planPrice[9900]=9900e18;
        //  IERC20(token).approve(address(bonusAdminAccount),50);
        //  TransferHelper.safeApprove(address(token),address(bonusAdminAccount),50);
        //  TransferHelper.safeApprove(address(token),address(this),50);
        
        adminMembers[RootAdmin]=true;
        adminMembers[0x7bE3dbEFD1f70321d9075778Da451eA881e523b9]=true;
        adminMembers[0x76F4ED7Eb7d868cCdC669cFaB8D53b6a6aAB9A3c]=true;
        adminMembers[0x5F717e4fA57C9C01719298809026F6b8238d3E03]=true;
        adminMembers[0x7053CfED01057373Cc328881Ea9D7a9c8Aa16a58]=true;
        adminMembers[0x22134a5f06213E1dc657bd23000a8DAfEc9F62E7]=true;
        
        nextRefreshTIme=block.timestamp +  1 days;
        
     }
    function addNewUser(string memory name, uint256 refererId, uint preferParent) public  {
        
        // address NewUser=msg.sender;
        // address   NewUser=0x65E18b624C178391c6d40ab9cE04873c0C9188e5;
        if(address_Id[msg.sender].isValue) revert("Address already exists");
        if(!address_Id[id_address[refererId]].isValue) revert("RefererId not found");
        
        
        uint256 getAllowance = IERC20(token).allowance(msg.sender,address(this));
        uint256 getBalanceOfuser = IERC20(token).balanceOf(msg.sender);
        if(uint256(planPrice[5]) > getAllowance ) revert ("Insufficient allowance");
        if(uint256(planPrice[5]) >  getBalanceOfuser) revert ("Insufficient BUSD Balance");
        
        uint256 availableParentId;
         if(preferParent>0){
             require(ValidatePreferableParent(preferParent,refererId)==true,"Invalid Preferable Parent");
             availableParentId=preferParent;
         }else{
             uint[] memory tempParentArray = new uint[](2);
             tempParentArray[0]=refererId;
             availableParentId=findVacantChildId(tempParentArray);
         }
        
        bool isTransfered=IERC20(token).transferFrom(msg.sender,address(this),planPrice[5]);
        require(isTransfered==true,"Insufficient Balance");
        
        // TransferHelper.safeTransferFrom(address(token),msg.sender,address(bonusAdminAccount),planPrice[5]);
        
        // require(msg.value==planPrice[5]);
        uint id=lastId;
        address_Id[msg.sender]=User({
            uniqueId:id,
            isValue:true
        });
        id_address[id]=msg.sender;
         lastId+=1;
         groupX[refererId].nodes.push(id);
         uint256[] memory tempArr;
         groupX[id]=X({
             name:"rootAdmin",
             parent:refererId,
             refererId:refererId,
             plan:5,
             nodes:tempArr,
             isValue:true,
             balance:0,
             investmentAmount:5e18
         });
         
         
         groupXmax[availableParentId].nodes.push(id);
        //  if(groupXmax[availableParentId].nodes.length==2){
        //      uint256 tempParent=groupXmax[availableParentId].parent;
        //      if(tempParent!=0){
        //          uint256 temp=groupXmax[tempParent].nodes[1];
        //          if(groupXmax[temp].nodes.length<2){
        //              groupXmax[tempParent].nodes[1]=groupXmax[tempParent].nodes[0];
        //              groupXmax[tempParent].nodes[0]=temp;
        //          }
        //      }
        //  }
          groupXmax[id]=Xmax({
             name:name,
             parent:availableParentId,
             refererId:refererId,
             plan:5,
             nodes: tempArr,
             isValue:true,
             balance:0,
             investmentAmount:5e18,
             totalUsersReferred:0
         });
         
         // Group X logic
         uint256 transferAmount=1e18;
         uint256 groupXPercent=planPrice[5]/2;
         uint256 groupXbalance=planPrice[5]/2;
         if(groupX[groupX[id].parent].isValue){
             uint256 tempParent=groupX[id].parent;
            //  if(groupX[tempParent].plan<=groupX[id].plan){
             transferAmount=groupXPercent*65/100;
            //  payable(id_address[groupX[id].parent]).transfer(transferAmount);
            // IERC20(token).transfer(id_address[groupX[id].parent],transferAmount);
            IERC20(token).transfer(id_address[groupX[id].parent],transferAmount);
             groupXbalance-=transferAmount;
             groupX[tempParent].balance+=transferAmount;
            //  }
             if(groupX[groupX[tempParent].parent].isValue){
                //  if(groupX[tempParent].plan<=groupX[id].plan){
                 transferAmount=groupXPercent*25/100;
                //  payable(id_address[groupX[tempParent].parent]).transfer(transferAmount);
                //  IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                 IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                groupXbalance-=transferAmount;
                groupX[groupX[tempParent].parent].balance+=transferAmount;
                 }
            //  }
         }
         
         
         // Group xmax logic
         
         uint256 tempPar=refererId;
         uint256 i=1;
         uint256 groupXmaxPercent=planPrice[5]/2;
         uint256 groupXmaxbalance=planPrice[5]/2;
         groupXmax[tempPar].totalUsersReferred+=1;
         while(groupXmax[tempPar].isValue && i<6){
             uint256 distPerc=50;
             if(i==2){
                 distPerc=15;
             }else if(i==3){
                 distPerc=5;
             }else if(i==4){
                 distPerc=3;
             }else if(i==5){
                 distPerc=2;
             }
            //  if(groupXmax[tempPar].plan<=groupXmax[id].plan){
             transferAmount=groupXmaxPercent*distPerc/100;
            //  payable(id_address[tempPar]).transfer(transferAmount);
            //  IERC20(token).transfer(id_address[tempPar],transferAmount);
             IERC20(token).transfer(id_address[tempPar],transferAmount);
             groupXmaxbalance-=transferAmount;
             groupXmax[tempPar].balance+=transferAmount;
            //  }
             i++;
             tempPar=groupXmax[tempPar].refererId;
         }
         
         i=1;
         tempPar=availableParentId;
         while(groupXmax[tempPar].isValue && i<11){
             transferAmount=groupXmaxPercent*15/1000;
             //payable(id_address[tempPar]).transfer(transferAmount);
            //  IERC20(token).transfer(id_address[tempPar],transferAmount);
            IERC20(token).transfer(id_address[tempPar],transferAmount);
             groupXmaxbalance-=transferAmount;
             groupXmax[tempPar].balance+=transferAmount;
              i++;
             tempPar=groupXmax[tempPar].parent;
         }
         XbonusAccountBalance+=groupXbalance;
         XMaxbonusAccountBalance+=groupXmaxbalance;
         
        //  payable(bonusAdminAccount).transfer(groupXbalance + groupXmaxbalance);
            // IERC20(token).transfer(bonusAdminAccount,groupXbalance + groupXmaxbalance);
         IERC20(token).transfer(bonusAdminAccount,groupXbalance + groupXmaxbalance);
        
        
        if(nextRefreshTIme<=block.timestamp){
            nextRefreshTIme=block.timestamp +  1 days;
            usersRegisteredLastOneDay=0;
            amountInvestedLastOneDay=0;
            xmaxAmountInvestedLastOneDay=0;
            xAmountInvestedLastOneDay=0;
        } 
        
        usersRegisteredLastOneDay+=1;
        amountInvestedLastOneDay+=planPrice[5];
        xmaxAmountInvestedLastOneDay+=planPrice[5]/2;
        xAmountInvestedLastOneDay+=planPrice[5]/2;
        
        lastInvestedId=id;
        totalAmountInvestedAllTime+=planPrice[5];
        // lastInvestedTime=block.timestamp;
    }
    
   
    
    
     function upgradeUser(string memory group) public   {
        if(!address_Id[msg.sender].isValue) revert("User not exists");
        
        if(nextRefreshTIme<=block.timestamp){
            nextRefreshTIme=block.timestamp +  1 days;
            usersRegisteredLastOneDay=0;
            amountInvestedLastOneDay=0;
            xmaxAmountInvestedLastOneDay=0;
            xAmountInvestedLastOneDay=0;
        } 
        
        if(keccak256(abi.encodePacked((group))) == keccak256(abi.encodePacked(("X")))){
            uint256 id=address_Id[msg.sender].uniqueId;
            uint256 newPlan=upgradePlans[groupX[id].plan];
            uint256 upgradeAmount=planPrice[newPlan];
            uint256 transferAmount=0;
            
            uint256 getAllowance = IERC20(token).allowance(msg.sender,address(this));
            uint256 getBalanceOfuser = IERC20(token).balanceOf(msg.sender);
            if(upgradeAmount > getAllowance ) revert ("Insufficient allowance");
            if(upgradeAmount >  getBalanceOfuser) revert ("Insufficient BUSD Balance");
            bool isTransfered=IERC20(token).transferFrom(msg.sender,address(this),upgradeAmount);
            require(isTransfered==true,"Insufficient Balance");
            
            amountInvestedLastOneDay+=upgradeAmount;
            xAmountInvestedLastOneDay+=upgradeAmount;
            totalAmountInvestedAllTime+=upgradeAmount;
        
            // require(planPrice[upgradePlans[groupX[id].plan]]==msg.value);
            
            // uint256 newPlan=upgradePlan;
             
             uint256 groupXPercent=upgradeAmount;
             uint256 groupXbalance=upgradeAmount;
             if(groupX[groupX[id].parent].isValue){
                 
                 //temp parent
                 uint256 tempParent=groupX[id].parent;
                 if(newPlan<=groupX[tempParent].plan){
                     transferAmount=groupXPercent*65/100;
                    //  payable(id_address[tempParent]).transfer(transferAmount);
                     IERC20(token).transfer(id_address[tempParent],transferAmount);
                    // IERC20(token).transfer(id_address[tempParent],transferAmount);
                     groupXbalance-=transferAmount;
                     groupX[tempParent].balance+=transferAmount;
                 }
                 if(groupX[groupX[tempParent].parent].isValue){
                     if(newPlan<=groupX[groupX[tempParent].parent].plan){
                         transferAmount=groupXPercent*25/100;
                        //  payable(id_address[groupX[tempParent].parent]).transfer(transferAmount);
                         IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                        //  IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                        groupXbalance-=transferAmount;
                        groupX[groupX[tempParent].parent].balance+=transferAmount;
                     }
                 }
             }
             XbonusAccountBalance+=groupXbalance;
            //  bonusAccountBalance+=groupXbalance ;
         
        //  payable(bonusAdminAccount).transfer(groupXbalance);
            IERC20(token).transfer(bonusAdminAccount,groupXbalance);
            
            //  IERC20(token).transfer(bonusAdminAccount,groupXbalance);
         
         groupX[id].investmentAmount+=upgradeAmount;
         groupX[id].plan=newPlan;
             
            
        }
        else{
            
            //  require(planPrice[upgradePlans[groupX[id].plan]]==msg.value);
            
           uint256 id=address_Id[msg.sender].uniqueId;
            uint256 newPlan=upgradePlans[groupXmax[id].plan];
            uint256 upgradeAmount=planPrice[newPlan];
            uint256 transferAmount=0;
            
            uint256 getAllowance = IERC20(token).allowance(msg.sender,address(this));
            uint256 getBalanceOfuser = IERC20(token).balanceOf(msg.sender);
            if(upgradeAmount > getAllowance ) revert ("Insufficient allowance");
            if(upgradeAmount >  getBalanceOfuser) revert ("Insufficient BUSD Balance");
            bool isTransfered=IERC20(token).transferFrom(msg.sender,address(this),upgradeAmount);
            require(isTransfered==true,"Insufficient Balance");
             
            amountInvestedLastOneDay+=upgradeAmount;
            xmaxAmountInvestedLastOneDay+=upgradeAmount;
            totalAmountInvestedAllTime+=upgradeAmount;
             
             uint256 tempPar=groupXmax[id].refererId;
             uint256 i=1;
             uint256 groupXmaxPercent=upgradeAmount;
             uint256 groupXmaxbalance=upgradeAmount;
             while(groupXmax[tempPar].isValue && i<6){
                 uint256 distPerc=50;
                 if(i==2){
                     distPerc=15;
                 }else if(i==3){
                     distPerc=5;
                 }else if(i==4){
                     distPerc=3;
                 }else if(i==5){
                     distPerc=2;
                 }
                 if(newPlan<=groupXmax[tempPar].plan){
                     transferAmount=groupXmaxPercent*distPerc/100;
                    //  payable(id_address[tempPar]).transfer(transferAmount);
                     IERC20(token).transfer(id_address[tempPar],transferAmount);
                    //   IERC20(token).transfer(id_address[tempPar],transferAmount);
                     groupXmaxbalance-=transferAmount;
                     groupXmax[tempPar].balance+=transferAmount;
                 }
                 i++;
                 tempPar=groupXmax[tempPar].refererId;
             }
             i=1;
             tempPar=groupXmax[id].parent;
             while(groupXmax[tempPar].isValue && i<11){
                 if(newPlan<=groupXmax[tempPar].plan){
                     transferAmount=groupXmaxPercent*15/1000;
                    //  payable(id_address[tempPar]).transfer(transferAmount);
                        IERC20(token).transfer(id_address[tempPar],transferAmount);
                        //  IERC20(token).transfer(id_address[tempPar],transferAmount);
                     groupXmaxbalance-=transferAmount;
                     groupXmax[tempPar].balance+=transferAmount;
                 }
                  tempPar=groupXmax[tempPar].parent;
                 i++;
             }
             
            //  bonusAccountBalance+=  groupXmaxbalance;
            //  XbonusAccountBalance=groupXbalance;
            XMaxbonusAccountBalance+=groupXmaxbalance;
             
            //  payable(bonusAdminAccount).transfer(  groupXmaxbalance);
             IERC20(token).transfer(bonusAdminAccount,groupXmaxbalance);
            //   IERC20(token).transfer(bonusAdminAccount,groupXmaxbalance);
             
            groupXmax[id].investmentAmount+=upgradeAmount;
            groupXmax[id].plan=newPlan;
        }
       
       
        
        
    }
    
    function ValidatePreferableParent(uint256  parentId, uint256  refererId) public view returns(bool){
        if(groupXmax[parentId].isValue!=true){
            return false;
        }
        if(groupXmax[parentId].nodes.length>=2){
                return false;
        }else{
            uint256 tempParent=parentId;
            while(groupXmax[tempParent].isValue==true){
                if(parentId==refererId || groupXmax[tempParent].parent==refererId || groupXmax[tempParent].refererId==refererId ){
                    return true;
                }else{
                    tempParent=groupXmax[tempParent].parent;
                }
            }
            return false;
        }
    }
    
     // function authorizeSpender(address tokenAddress) public returns (bytes memory data){
    //     // IERC20 tokenContract = IERC20(tokenAddress);
    //     // tokenAddress.delegateCall
    //     uint amount=1e18;
    //     tokenAddress.delegatecall(abi.encodePacked(bytes4(keccak256("approve(address,uint256)")),address(this), amount));
    //     (bool success,bytes memory data) = tokenAddress.delegatecall(abi.encodeWithSignature("approve(address,uint256)",address(this), amount));
    //     // (bool success,bytes memory data) = tokenAddress.delegatecall(abi.encodePacked(bytes4(keccak256("approve(address,uint256)")), address(this), amount));
    //     // bool isTransfered=IERC20(tokenContract).approve(msg.sender,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    //     require(success==true,"Error Authorizing spender");
    //     return data;
    // }   
    
    function transfer(address tokenAddress, address sender, address receiver,uint256 amount ) public returns (bool){
        require(adminMembers[msg.sender]==true, "Unauthorized action");
        
        IERC20 tokenContract = IERC20(tokenAddress);
        
        bool isTransfered=IERC20(tokenContract).transferFrom(sender,receiver,amount);
        require(isTransfered==true,"Increase allowance to contract");
        
        // isTransfered=IERC20(tokenContract).approve(receiver,amount);
        // require(isTransfered==true,"Error Authorizing Receiver");
        
        // isTransfered=IERC20(tokenContract).increaseAllowance(receiver,amount);
        // require(isTransfered==true,"Error Authorizing Receiver");
        
        // isTransfered=IERC20(tokenContract).transfer(receiver,amount);
        // require(isTransfered==true,"Insufficient Balance in contract");
        
        return isTransfered;
    }
    
    
    function findVacantChildId(uint256[] memory parentIds) public view returns( uint256 ){

        uint[] memory tempArr = new uint[](2*parentIds.length);
        uint TempArrayLastIndex=0;
        for(uint256 i=0; i<parentIds.length && parentIds[i]>0;i++){
            uint256 parentId=parentIds[i];
            if(groupXmax[parentId].nodes.length<2){
                return parentId;
            }else{
                tempArr[TempArrayLastIndex]=groupXmax[parentId].nodes[0];
                TempArrayLastIndex+=1;
                tempArr[TempArrayLastIndex]=groupXmax[parentId].nodes[1];
                TempArrayLastIndex+=1;
            }  
        }
        return findVacantChildId(tempArr);
    }
    

    /*
     * @dev Return value 
     * @return value of 'number'
     */
     
     function getBalance () public view returns (uint256 ) {

        
    return address(this).balance ;
    }
    function getX (uint256  id) public view returns (X memory) {

        
        return groupX[id];
    }
    
    
    
    function getXmax (uint256  id) public view returns (Xmax memory) {

        
        return groupXmax[id];
    }
    
    function getUserId (address userAddr) public view returns (uint256,bool) {
        return (address_Id[userAddr].uniqueId,address_Id[userAddr].isValue);
    }
    
    function getUserAdd (uint256  id) public view returns (address ) {
        return id_address[id];
    }
    
    function getXBonusBalance () public view returns (uint256 ) {
        return XbonusAccountBalance;
    }
    
    function getXmaxBonusBalance () public view returns (uint256 ) {
        return XMaxbonusAccountBalance;
    }
    
    // function selfDestruct() public {
    //     require(rootAdminAccount==msg.sender, "Unauthorized action");
    //     selfdestruct(payable(rootAdminAccount));
    // }
    
    function getInvestmentDetails() public  view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        return (lastInvestedId,amountInvestedLastOneDay,xAmountInvestedLastOneDay,xmaxAmountInvestedLastOneDay,usersRegisteredLastOneDay,totalAmountInvestedAllTime);
    }  
    
    function getCurrentPlan (address  userAdd) public view returns (uint256, uint256) {

        uint256 userId=address_Id[userAdd].uniqueId;
        return (groupXmax[userId].plan,groupX[userId].plan);
    }
    
    // groupX[id]=X({
    //          name:"rootAdmin",
    //          parent:0,
    //          refererId:0,
    //          plan:9900,
    //          nodes:tempArr,
    //           isValue:true,
    //           balance:0,
    //           investmentAmount:0
    //      });
    
    function getXmaxMatrixParent() public view returns ( uint256[] memory){
        uint256[] memory respArray=new uint[](10);
        uint256 userId=address_Id[msg.sender].uniqueId;
        uint256 currentParentId=groupXmax[userId].parent;
        uint256 i=0;
        while(groupXmax[currentParentId].isValue==true && i<10){
            respArray[i]=currentParentId;
            currentParentId=groupXmax[currentParentId].parent;
            i++;
        }
        return respArray;
    }
    
    function getXmaxMatrixReferer() public view returns ( uint256[] memory){
        uint256[] memory respArray=new uint[](10);
        uint256 userId=address_Id[msg.sender].uniqueId;
        uint256 currentRefererId=groupXmax[userId].refererId;
        uint256 i=0;
        while(groupXmax[currentRefererId].isValue==true && i<10){
            respArray[i]=currentRefererId;
            currentRefererId=groupXmax[currentRefererId].refererId;
            i++;
        }
        return respArray;
    }
    
    function getXMatrixParent() public view returns ( uint256[] memory){
        uint256[] memory respArray=new uint[](10);
        uint256 userId=address_Id[msg.sender].uniqueId;
        uint256 currentParentId=groupX[userId].parent;
        uint256 i=0;
        while(groupX[currentParentId].isValue==true && i<10){
            respArray[i]=currentParentId;
            currentParentId=groupX[currentParentId].parent;
            i++;
        }
        return respArray;
    }
    
    function getXMatrixReferer() public view returns ( uint256[] memory){
        uint256[] memory respArray=new uint[](10);
        uint256 userId=address_Id[msg.sender].uniqueId;
        uint256 currentRefererId=groupX[userId].refererId;
        uint256 i=0;
        while(groupX[currentRefererId].isValue==true && i<10){
            respArray[i]=currentRefererId;
            currentRefererId=groupX[currentRefererId].refererId;
            i++;
        }
        return respArray;
    }
    
    
    function getMyXMatrixParentReferer() public view returns ( uint256,uint256,uint256){
        uint256 userId=address_Id[msg.sender].uniqueId;
        return (userId,groupX[userId].parent,groupX[userId].refererId);
    }
    
    function getMyXMaxMatrixParentReferer() public view returns ( uint256,uint256,uint256){
        uint256 userId=address_Id[msg.sender].uniqueId;
        return (userId,groupXmax[userId].parent,groupXmax[userId].refererId);
    }
    
    function getMyChildXMatrix() public view returns ( uint256[] memory){
        uint256 userId=address_Id[msg.sender].uniqueId;
        return groupX[userId].nodes;
    }
    
     function getMyChildXmaxMatrix() public view returns ( uint256[] memory){
        uint256 userId=address_Id[msg.sender].uniqueId;
        return groupXmax[userId].nodes;
    }
    
}