/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "./TransferHelper.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
 interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value)
    external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);

}

contract InvestmentContract {


    struct   X {
     string name;     // name of node
     uint256 parent;   // parent node’s path
     uint256 plan;     // node’s data
     uint256[] nodes;  // list of linked nodes’ paths
     bool isValue;
     uint256 balance;
    }
    struct Xmax {
     string name;     // name of node
     uint256 parent;   // parent node’s path
     uint256 plan;     // node’s data
     uint256[] nodes;  // list of linked nodes’ paths
     bool isValue;
     uint256 balance;
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

    mapping(address => string ) ids;
    address rootAdminAccount;
    address bonusAdminAccount;
    uint256 bonusAccountBalance;
    IERC20 token = IERC20(0x15E96A544a148dc96f8516716cd7144AEF5cca28);
   
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
             plan:5,
             nodes:tempArr,
              isValue:true,
              balance:0
         });
         groupXmax[id]=Xmax({
             name:"rootAdmin",
             parent:0,
             plan:5,
             nodes:tempArr,
             isValue:true,
             balance:0
         });
         
         upgradePlans[5]=10;
         upgradePlans[10]=25;
         upgradePlans[25]=50;
         upgradePlans[50]=100;
         
         planPrice[5]=10e18;
         planPrice[10]=10e18;
         planPrice[25]=25e18;
         planPrice[50]=50e18;
         planPrice[100]=200e18;
        //  IERC20(token).approve(address(bonusAdminAccount),50);
        //  TransferHelper.safeApprove(address(token),address(bonusAdminAccount),50);
        //  TransferHelper.safeApprove(address(token),address(this),50);
     }
    function addNewUser(string memory name, uint256 refererId) public  {
        
        // address NewUser=msg.sender;
        // address   NewUser=0x65E18b624C178391c6d40ab9cE04873c0C9188e5;
        if(address_Id[msg.sender].isValue) revert("Address already exists");
        if(!address_Id[id_address[refererId]].isValue) revert("RefererId not found");
        
        
        uint256 getAllowance = IERC20(token).allowance(msg.sender,address(this));
        uint256 getBalanceOfuser = IERC20(token).balanceOf(msg.sender);
        if(uint256(planPrice[5]) > getAllowance ) revert ("Insufficient allowance");
        if(uint256(planPrice[5]) >  getBalanceOfuser) revert ("Insufficient BUSD Balance");
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
             plan:5,
             nodes:tempArr,
             isValue:true,
             balance:0
         });
         uint[] memory tempParentArray = new uint[](2);
         tempParentArray[0]=refererId;
         uint256 availableParentId=findVacantChildId(tempParentArray);
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
             plan:5,
             nodes: tempArr,
             isValue:true,
             balance:0
         });
         
         // Group X logic
         uint256 transferAmount=1e18;
         uint256 groupXPercent=planPrice[5]/2;
         uint256 groupXbalance=planPrice[5]/2;
         if(groupX[groupX[id].parent].isValue){
             uint256 tempParent=groupX[id].parent;
             if(groupX[tempParent].plan==groupX[id].plan){
                 transferAmount=groupXPercent*70/100;
                //  payable(id_address[groupX[id].parent]).transfer(transferAmount);
                // IERC20(token).transfer(id_address[groupX[id].parent],transferAmount);
                IERC20(token).transfer(id_address[groupX[id].parent],transferAmount);
                 groupXbalance-=transferAmount;
                 groupX[tempParent].balance+=transferAmount;
             }
             if(groupX[groupX[tempParent].parent].isValue){
                 if(groupX[tempParent].plan==groupX[id].plan){
                     transferAmount=groupXPercent*25/100;
                    //  payable(id_address[groupX[tempParent].parent]).transfer(transferAmount);
                    //  IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                     IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                    groupXbalance-=transferAmount;
                    groupX[groupX[tempParent].parent].balance+=transferAmount;
                 }
             }
         }
         
         
         // Group xmax logic
         
         uint256 tempPar=refererId;
         uint256 i=1;
         uint256 groupXmaxPercent=planPrice[5]/2;
         uint256 groupXmaxbalance=planPrice[5]/2;
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
             if(groupXmax[tempPar].plan==groupXmax[id].plan){
                 transferAmount=groupXmaxPercent*distPerc/100;
                //  payable(id_address[tempPar]).transfer(transferAmount);
                //  IERC20(token).transfer(id_address[tempPar],transferAmount);
                 IERC20(token).transfer(id_address[tempPar],transferAmount);
                 groupXmaxbalance-=transferAmount;
                 groupXmax[tempPar].balance+=transferAmount;
             }
             i++;
             tempPar=groupXmax[tempPar].parent;
         }
         
         i=1;
         tempPar=refererId;
         while(groupXmax[tempPar].isValue && i<11){
             transferAmount=groupXmaxPercent*2/100;
             //payable(id_address[tempPar]).transfer(transferAmount);
            //  IERC20(token).transfer(id_address[tempPar],transferAmount);
            IERC20(token).transfer(id_address[tempPar],transferAmount);
             groupXmaxbalance-=transferAmount;
             groupXmax[tempPar].balance+=transferAmount;
              i++;
             tempPar=groupXmax[tempPar].parent;
         }
         bonusAccountBalance+=groupXbalance + groupXmaxbalance;
         
        //  payable(bonusAdminAccount).transfer(groupXbalance + groupXmaxbalance);
            // IERC20(token).transfer(bonusAdminAccount,groupXbalance + groupXmaxbalance);
         IERC20(token).transfer(bonusAdminAccount,groupXbalance + groupXmaxbalance);
         
    }
    
    
     function upgradeUser(string memory group) public   {
        if(!address_Id[msg.sender].isValue) revert("User not exists");
        
        
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
            // require(planPrice[upgradePlans[groupX[id].plan]]==msg.value);
            
            // uint256 newPlan=upgradePlan;
             
             uint256 groupXPercent=upgradeAmount;
             uint256 groupXbalance=upgradeAmount;
             if(groupX[groupX[id].parent].isValue){
                 uint256 tempParent=groupX[id].parent;
                 if(newPlan==groupX[tempParent].plan){
                     transferAmount=groupXPercent*70/100;
                    //  payable(id_address[tempParent]).transfer(transferAmount);
                     IERC20(token).transfer(id_address[tempParent],transferAmount);
                    // IERC20(token).transfer(id_address[tempParent],transferAmount);
                     groupXbalance-=transferAmount;
                     groupX[tempParent].balance+=transferAmount;
                 }
                 if(groupX[groupX[tempParent].parent].isValue){
                     if(newPlan==groupX[groupX[tempParent].parent].plan){
                         transferAmount=groupXPercent*25/100;
                        //  payable(id_address[groupX[tempParent].parent]).transfer(transferAmount);
                         IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                        //  IERC20(token).transfer(id_address[groupX[tempParent].parent],transferAmount);
                        groupXbalance-=transferAmount;
                        groupX[groupX[tempParent].parent].balance+=transferAmount;
                     }
                 }
             }
             
             bonusAccountBalance+=groupXbalance ;
         
        //  payable(bonusAdminAccount).transfer(groupXbalance);
            IERC20(token).transfer(bonusAdminAccount,groupXbalance);
            
            //  IERC20(token).transfer(bonusAdminAccount,groupXbalance);
         
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
             
             uint256 tempPar=groupXmax[id].parent;
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
                 if(newPlan==groupXmax[tempPar].plan){
                     transferAmount=groupXmaxPercent*distPerc/100;
                    //  payable(id_address[tempPar]).transfer(transferAmount);
                     IERC20(token).transfer(id_address[tempPar],transferAmount);
                    //   IERC20(token).transfer(id_address[tempPar],transferAmount);
                     groupXmaxbalance-=transferAmount;
                     groupXmax[tempPar].balance+=transferAmount;
                 }
                 i++;
                 tempPar=groupXmax[tempPar].parent;
             }
             i=1;
             tempPar=groupXmax[id].parent;
             while(groupXmax[tempPar].isValue && i<11){
                 transferAmount=groupXmaxPercent*2/100;
                //  payable(id_address[tempPar]).transfer(transferAmount);
                    IERC20(token).transfer(id_address[tempPar],transferAmount);
                    //  IERC20(token).transfer(id_address[tempPar],transferAmount);
                 groupXmaxbalance-=transferAmount;
                 groupXmax[tempPar].balance+=transferAmount;
                  i++;
                 tempPar=groupXmax[tempPar].parent;
             }
             
             bonusAccountBalance+=  groupXmaxbalance;
             
             
            //  payable(bonusAdminAccount).transfer(  groupXmaxbalance);
             IERC20(token).transfer(bonusAdminAccount,groupXmaxbalance);
            //   IERC20(token).transfer(bonusAdminAccount,groupXmaxbalance);
             
            groupXmax[id].plan=newPlan;
        }
       
        
        
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
    function getX (uint256  id) public view returns (X memory) {

        
        return groupX[id];
    }
    
    function getXmax (uint256  id) public view returns (Xmax memory) {

        
        return groupXmax[id];
    }
    
    function getUserId () public view returns (User memory) {
        return address_Id[msg.sender];
    }
    
    function getUserAdd (uint256  id) public view returns (address ) {
        return id_address[id];
    }
    
    function getBonusBalance () public view returns (uint256 ) {
        return bonusAccountBalance;
    }
    
}