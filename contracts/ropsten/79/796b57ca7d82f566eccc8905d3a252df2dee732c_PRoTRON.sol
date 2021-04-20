/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity 0.5.14;

contract PRoTRON {
     address public ownerWallet;
      uint public currUserID = 0;
      
      
      
      uint public unlimited_level_price=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint co_referrerID;
        uint referredUsers;
        uint co_referredUsers;
        address catchAndThrow;
        uint catchAndThrowReceived;
        uint income;
        uint batchPaid;
        uint autoPoolPayReceived;
        uint missedPoolPayment;
        address autopoolPayReciever;
        uint levelIncomeReceived;
        mapping(uint => uint) levelExpired;
      }
    
      
      // MATRIX CONFIG FOR AUTO-POOL FUND
      uint public batchSize;
      uint public height;

      struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
      }
    
      // USERS   
      mapping (address => UserStruct) public users;
      mapping (uint => address) public userList;
     



    mapping(uint => uint) public LEVEL_PRICE;
    
   uint public REGESTRATION_FESS;

   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
     event regPoolEntry(address indexed _user,uint _level,   uint _time);
     event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
     event successfulPay(string str, address ref);
     event autoPoolEvent(string str1, address add);

    UserStruct[] public requests;
     uint public pay_co_ref;
     uint public pay_evn_odd;
     uint public pay_autopool;

      constructor() public {
          ownerWallet = msg.sender;
          REGESTRATION_FESS = 1000000000;
          batchSize = 2;
          height = 5;

           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 5 / 20;
           pay_co_ref = REGESTRATION_FESS / 5;
           pay_evn_odd = REGESTRATION_FESS / 5;           
           unlimited_level_price=REGESTRATION_FESS / 5 / 20;
           pay_autopool = REGESTRATION_FESS / 5 / height;

           UserStruct memory userStruct;
           currUserID++;

           userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                referrerID: 0,
                co_referrerID: 0, 
                referredUsers:0,
                co_referredUsers:0,
                catchAndThrow : ownerWallet,
                catchAndThrowReceived : 0,
                income : 0,
                batchPaid : 0,
                autoPoolPayReceived : 0,
                missedPoolPayment : 0,
                autopoolPayReciever : ownerWallet,
                levelIncomeReceived : 0
           });
            
          users[ownerWallet] = userStruct;
          userList[currUserID] = ownerWallet;
         
       

       
       
      }
     
     modifier onlyOwner(){
         require(msg.sender==ownerWallet,"Only Owner can access this function.");
         _;
     }
     function setRegistrationFess(uint fess) public onlyOwner{
           REGESTRATION_FESS = fess;
           REGESTRATION_FESS = REGESTRATION_FESS * (10 ** 6);
           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 5 / 20;
           pay_co_ref = REGESTRATION_FESS / 5;
           pay_evn_odd = REGESTRATION_FESS / 5; 
           pay_autopool = REGESTRATION_FESS / 5 / height;
           unlimited_level_price=REGESTRATION_FESS / 5 / 20;
     }

     function setBatchSize(uint _batch) public{
        batchSize = _batch;
     }

     function setHeight(uint _height) public{
        height = _height;
     }

     function getRegistrationFess() public view returns(uint){
         return REGESTRATION_FESS;
     }
       function regUser(uint co_referrer,uint _referrerID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
      require(co_referrer > 0 && co_referrer <= currUserID, 'Incorrect referral ID');
      require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
      
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            co_referrerID: co_referrer,   
            referredUsers:0,
            co_referredUsers:0,
            catchAndThrow : address(0),
            catchAndThrowReceived : 0,
            income : 0,
            batchPaid : 0,
            autoPoolPayReceived : 0,
            missedPoolPayment : 0,
            autopoolPayReciever : address(0),
            levelIncomeReceived : 0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        

        users[userList[users[msg.sender].co_referrerID]].co_referredUsers=users[userList[users[msg.sender].co_referrerID]].co_referredUsers+1;
        

        checkEvenOrOdd(msg.sender);
        payToCoReferrer(3,msg.sender);     
        autoPool(msg.sender);            
        payReferral(1,msg.sender);
        
        
        
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
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
              if((h > 2 && h <= height) && users[userList[id]].co_referredUsers>=1 
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
        address co_referrer;
        co_referrer = userList[users[_user].co_referrerID];
        bool sent = false;
        uint level_price_local=0;
        
        if(_level==3){
             level_price_local = pay_co_ref;
        }
        
        sent = address(uint160(co_referrer)).send(level_price_local);
        users[userList[users[_user].co_referrerID]].income = users[userList[users[_user].co_referrerID]].income + level_price_local;

        
        if(sent){
            emit getMoneyForLevelEvent(co_referrer, msg.sender, _level, now);
        }
  
     }

     

     function checkEvenOrOdd(address _user) internal{
        address referer;
        referer = userList[users[_user].referrerID];
        
        address first_ref = users[userList[users[_user].referrerID]].catchAndThrow;
          
        
        uint number = users[userList[users[_user].referrerID]].referredUsers;
        
        bool sent;

        
       
        if(number%2 == 0){
          
          sent = address(uint160(first_ref)).send(pay_evn_odd);
          users[userList[users[_user].referrerID]].income = users[userList[users[_user].referrerID]].income + pay_evn_odd;
          
          users[userList[users[_user].referrerID]].catchAndThrowReceived = users[userList[users[_user].referrerID]].catchAndThrowReceived + 1;  

          users[_user].catchAndThrow = first_ref;

          if(sent){
            emit successfulPay("Successfully pay to the even referrer",first_ref);
          }

        }else{
          sent = address(uint160(referer)).send(pay_evn_odd);
          users[userList[users[_user].referrerID]].income = users[userList[users[_user].referrerID]].income + pay_evn_odd;
          
          users[userList[users[_user].referrerID]].catchAndThrowReceived = users[userList[users[_user].referrerID]].catchAndThrowReceived + 1;            

          users[_user].catchAndThrow = referer;
        
          if(sent){
            emit successfulPay("Successfully pay to the odd referrer",referer);
          }
        } 
        

       
     }

    
     function payReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].referrerID];
       
       
         bool sent = false;
       
            uint level_price_local=0;
            if(_level>2){
            level_price_local=unlimited_level_price;
            }
            else{
            level_price_local=LEVEL_PRICE[_level];
            }
            sent = address(uint160(referer)).send(level_price_local);
            users[referer].levelIncomeReceived = users[referer].levelIncomeReceived +1; 
            users[userList[users[_user].referrerID]].income = users[userList[users[_user].referrerID]].income + level_price_local;

        
            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
                if(_level < 20 && users[referer].referrerID >= 1){
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
   
   
   
   function gettrxBalance() public view returns(uint) {
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