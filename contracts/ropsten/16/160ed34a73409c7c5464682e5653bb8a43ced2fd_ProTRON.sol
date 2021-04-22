/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity 0.5.15;

contract ProTRON {
     address private ownerWallet;
      uint public currUserID = 0;
      
      uint public uni_level_price=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint sponsorID;
        uint introducerID;
        uint sponsoredUsers;
        uint introducedUsers;
        address catchAndThrow;
        uint catchAndThrowReceived;
        uint income;
        uint batchPaid;
        uint autoPoolPayReceived;
        uint missedPoolPayment;
        address autopoolPayReciever;
        uint unilevelIncomeReceived;
        mapping(uint => uint) levelExpired;
      }
    
      
      // MATRIX CONFIG FOR AUTO-POOL FUND
      uint private batchSize;
      uint private height;

      struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
      }
    
      // USERS   
      mapping (address => UserStruct) public users;
      mapping (uint => address) public userList;
     



     
    mapping(uint => uint) private LEVEL_PRICE;
    
   uint private REGESTRATION_FESS;
   
   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
     event regPoolEntry(address indexed _user,uint _level,   uint _time);
     event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
     event successfulPay(string str, address ref);
     event autoPoolEvent(string str1, address add);

    UserStruct[] private requests;
     uint public pay_to_ref;
     uint public catchAndThrow;
     uint public pay_autopool;

      constructor() public {
          ownerWallet = msg.sender;
          REGESTRATION_FESS = 1000000000;
          batchSize = 2;
          height = 5;

           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 5 / 20;
           pay_to_ref = REGESTRATION_FESS / 5;
           catchAndThrow = REGESTRATION_FESS / 5;           
           uni_level_price=REGESTRATION_FESS / 5 / 20;
           pay_autopool = REGESTRATION_FESS / 5 / height;

           UserStruct memory userStruct;
           currUserID++;

           userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                sponsorID: 0,
                introducerID: 0, 
                sponsoredUsers:0,
                introducedUsers:0,
                catchAndThrow : ownerWallet,
                catchAndThrowReceived : 0,
                income : 0,
                batchPaid : 0,
                autoPoolPayReceived : 0,
                missedPoolPayment : 0,
                autopoolPayReciever : ownerWallet,
                unilevelIncomeReceived : 0
           });
            
          users[ownerWallet] = userStruct;
          userList[currUserID] = ownerWallet;
         
       
      }
     
     modifier onlyOwner(){
         require(msg.sender==ownerWallet,"Blockchain technology can change the world");
         _;
     }
     function setWelcomeMessage(uint  WelcomeMessage) public onlyOwner{
           REGESTRATION_FESS = WelcomeMessage;
           REGESTRATION_FESS = REGESTRATION_FESS * (10 ** 18);
           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 5 / 20;
           pay_to_ref = REGESTRATION_FESS / 5;
           catchAndThrow = REGESTRATION_FESS / 5; 
           pay_autopool = REGESTRATION_FESS / 5 / height;
           uni_level_price=REGESTRATION_FESS / 5 / 20;
     }

     

     function getRegistrationFess() public view returns(uint){
         return REGESTRATION_FESS / (10**18);
     }
       function regUser(uint introducer,uint _sponsorID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_sponsorID > 0 && _sponsorID <= currUserID, 'Incorrect referral ID');
      require(introducer > 0 && introducer <= currUserID, 'Incorrect referral ID');
      require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
      
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            sponsorID: _sponsorID,
            introducerID: introducer,   
            sponsoredUsers:0,
            introducedUsers:0,
            catchAndThrow : address(0),
            catchAndThrowReceived : 0,
            income : 0,
            batchPaid : 0,
            autoPoolPayReceived : 0,
            missedPoolPayment : 0,
            autopoolPayReciever : address(0),
            unilevelIncomeReceived : 0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].sponsorID]].sponsoredUsers=users[userList[users[msg.sender].sponsorID]].sponsoredUsers+1;
        

        users[userList[users[msg.sender].introducerID]].introducedUsers=users[userList[users[msg.sender].introducerID]].introducedUsers+1;
        

        checkEvenOrOdd(msg.sender);
        payToCoReferrer(3,msg.sender);     
        autoPool(msg.sender);            
        payReferral(1,msg.sender);
        
        
        
        emit regLevelEvent(msg.sender, userList[_sponsorID], now);
    }
     
     bool ownerPaid;
     function heightPayment(uint batch,uint id,uint h) internal{
        bool sent = false;
       
        if((users[userList[id]].autopoolPayReciever != address(0)) && (userList[batch] != users[userList[id]].autopoolPayReciever) && (h <= height && h<=2 && id > 0 && ownerPaid!=true)) {
            
            address nextLevel = userList[id];
            sent = address(uint160(nextLevel)).send(pay_autopool);   
            users[userList[id]].income = users[userList[id]].income + pay_autopool;
            users[userList[id]].autoPoolPayReceived = users[userList[id]].autoPoolPayReceived + 1;
            
            if(id==1){
              ownerPaid = true;
            }            
            if(sent){
                 emit autoPoolEvent("Auto-Pool Payment Successful",nextLevel);
            }
            id = users[users[userList[id]].autopoolPayReciever].id;
            heightPayment(batch,id,h+1);
            
        }else{
              if((h > 2 && h <= height) && users[userList[id]].introducedUsers>=1 
              && (id > 0 && ownerPaid!=true)){
                    
                    address nextLevel = userList[id];
                    sent = address(uint160(nextLevel)).send(pay_autopool);   
                    users[userList[id]].income = users[userList[id]].income + pay_autopool;
                    users[userList[id]].autoPoolPayReceived = users[userList[id]].autoPoolPayReceived + 1;
                    

                    if(id==1){
                        ownerPaid = true;
                    }   
                    if(sent){
                        emit autoPoolEvent("Auto-Pool Payment Successful",nextLevel);
                    }

                    id = users[users[userList[id]].autopoolPayReciever].id;
                    heightPayment(batch,id,h+1);   
              }
              
              else if(id>0 && h<=height && ownerPaid!=true){
                  if(id==1){
                        ownerPaid = true;
                  }
                  users[userList[id]].missedPoolPayment = users[userList[id]].missedPoolPayment +1;
                  id = users[users[userList[id]].autopoolPayReciever].id;
                  heightPayment(batch,id,h+1);
              }
              
        }



     }
     
     function autoPool(address _user) internal {
        bool sent = false;
        ownerPaid = false;
        uint i;  
        for(i = 1; i < currUserID; i++){
            if(users[userList[i]].batchPaid < batchSize){

                sent = address(uint160(userList[i])).send(pay_autopool);   
                users[userList[i]].batchPaid = users[userList[i]].batchPaid + 1;
                users[_user].autopoolPayReciever = userList[i];
                users[userList[i]].income = users[userList[i]].income + pay_autopool;
                users[userList[i]].autoPoolPayReceived = users[userList[i]].autoPoolPayReceived + 1;
                
                if(sent){
                 emit autoPoolEvent("Auto-Pool Payment Successful",userList[i]);
                }
                 
                uint heightCounter = 2;
                uint  temp = users[users[userList[i]].autopoolPayReciever].id;
                heightPayment(i,temp,heightCounter);

                
                i = currUserID;    
            }
        }
      }
     

     function payToCoReferrer(uint _level, address _user) internal{
        address introducer;
        introducer = userList[users[_user].introducerID];
        bool sent = false;
        uint level_price_local=0;
        
        if(_level==3){
             level_price_local = pay_to_ref;
        }
        
        sent = address(uint160(introducer)).send(level_price_local);
        users[userList[users[_user].introducerID]].income = users[userList[users[_user].introducerID]].income + level_price_local;

        
        if(sent){
            emit getMoneyForLevelEvent(introducer, msg.sender, _level, now);
        }
  
     }

     

     function checkEvenOrOdd(address _user) internal{
        address introducer;
        introducer = userList[users[_user].introducerID];
        
        address first_ref = users[userList[users[_user].introducerID]].catchAndThrow;
          
        
        uint number = users[userList[users[_user].introducerID]].introducedUsers;
        
        bool sent;

        
       
        if(number%2 == 0){
          
          sent = address(uint160(first_ref)).send(catchAndThrow);
          users[userList[users[_user].introducerID]].income = users[userList[users[_user].introducerID]].income + catchAndThrow;
          
          users[userList[users[_user].introducerID]].catchAndThrowReceived = users[userList[users[_user].introducerID]].catchAndThrowReceived + 1;  

          users[_user].catchAndThrow = first_ref;

          if(sent){
            emit successfulPay("Successfully pay to the even introducer",first_ref);
          }

        }else{
          sent = address(uint160(introducer)).send(catchAndThrow);
          users[userList[users[_user].introducerID]].income = users[userList[users[_user].introducerID]].income + catchAndThrow;
          
          users[userList[users[_user].introducerID]].catchAndThrowReceived = users[userList[users[_user].introducerID]].catchAndThrowReceived + 1;            

          users[_user].catchAndThrow = introducer;
        
          if(sent){
            emit successfulPay("Successfully pay to the odd referrer",introducer);
          }
        } 
        

       
     }

    
     function payReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].sponsorID];
       
       
         bool sent = false;
       
            uint level_price_local=0;
            if(_level>2){
            level_price_local=uni_level_price;
            }
            else{
            level_price_local=LEVEL_PRICE[_level];
            }
            sent = address(uint160(referer)).send(level_price_local);
            users[referer].unilevelIncomeReceived = users[referer].unilevelIncomeReceived +1; 
            users[userList[users[_user].sponsorID]].income = users[userList[users[_user].sponsorID]].income + level_price_local;

        
            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
                if(_level < 20 && users[referer].sponsorID >= 1){
                    payReferral(_level+1,referer);
                }
                
                else
                {
                    sendBalance();
                }
               
            }
       
        if(!sent) {
          //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payReferral(_level, referer);
        }
     }
   
   
    function gettrxBalance() private view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalance() private
    {
         users[ownerWallet].income = users[ownerWallet].income + gettrxBalance();
         if (!address(uint160(ownerWallet)).send(gettrxBalance()))
         {
             
         }
    }
   
   
}