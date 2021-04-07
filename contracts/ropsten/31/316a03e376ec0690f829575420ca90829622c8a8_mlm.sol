/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.5.11;
contract mlm{
    address public owneraddress;
    
    struct Users{
        bool exsist;
        uint ID;
        uint ReferrerID;
        address[] referral;
        mapping(uint=>uint)levelExpired;
    }
    
    uint public  UserId=0;
    mapping(uint=>uint)public Levelprice;
    mapping(address=>Users)public userdetls;
    mapping(uint=>address) public userlist;
    uint Referrer_Limit=2;
    uint period_length=100 days;  
    
    
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event getmoney(address indexed user,address indexed referral,uint level,uint time);
    event losemoney(address indexed user,address indexed referral,uint level,uint time);
      constructor() public{
       owneraddress = msg.sender;
        
        Levelprice[1]=0.03 ether;
        Levelprice[2]=0.05 ether;
        Levelprice[3]=0.1 ether;
        Levelprice[4]=1 ether;
        Levelprice[5]=2 ether;
        Levelprice[6]=6 ether;
        Levelprice[7]=7 ether;
        Levelprice[8]=8 ether;
        Levelprice[9]=9 ether;
        Levelprice[10]=10 ether;
    
        UserId++;
        
      Users memory user=Users({
          exsist:true,
          ID:UserId,
          ReferrerID:0,
          referral:new address[](0)
      });
      userdetls[owneraddress]=user;
      userlist[UserId]=owneraddress;
      for(uint i=0;i<=10;i++){
          userdetls[owneraddress].levelExpired[i]= 555555555555;
      }
      }
      
      
      function regser(uint referrerId) public payable{
           require(msg.value==Levelprice[1], "invalid balance");
           require(!userdetls[msg.sender].exsist, "user already exsist");
          
          require(referrerId>0 && referrerId<= UserId,"incorrect referrer");
          if(userdetls[userlist[referrerId]].referral.length >= Referrer_Limit) referrerId = userdetls[findFreeReferrer(userlist[referrerId])].ID;
          UserId++;
          Users memory user=Users({
              exsist:true,
              ID:UserId,
              ReferrerID:referrerId,
              referral:new address[](0)
          });
           userdetls[msg.sender]=user;
           userlist[UserId]=msg.sender;
           userdetls[msg.sender].levelExpired[1]=now+period_length;
            userdetls[userlist[referrerId]].referral.push(msg.sender);
             payforlevel(1,msg.sender);
              emit regLevelEvent(msg.sender, userlist[referrerId], now);
           
      }
      
      function Buylevel(uint _level)public payable{
          require(_level>0 && _level<10, "invalid");
          require(userdetls[msg.sender].exsist,"user not exsist");
           
           
           if(_level==1){
               require(msg.value==Levelprice[1],"invalid balance");
               userdetls[msg.sender].levelExpired[1]+=period_length;
               
           }
           
           for(uint l=_level-1;l>0;l--) require(userdetls[msg.sender].levelExpired[l]>now,"buy exsisting level");
           if(userdetls[msg.sender].levelExpired[_level]==0) userdetls[msg.sender].levelExpired[_level]=now+period_length;
           else(userdetls[msg.sender].levelExpired[_level]+=period_length);
      
          payforlevel(_level,msg.sender);
        emit buyLevelEvent(msg.sender, _level, now);
    }
    
    function payforlevel(uint level,address _user) internal{
        address referrer;
        address referrer1;
        address referrer2;
        address referrer3;
        address referrer4;
        address referrer5;
        address referrer6;
        
        
        if(level==1){
           referrer =  userlist[userdetls[_user].ReferrerID];
        }
        else if(level==2){
            referrer1= userlist[userdetls[_user].ReferrerID];
            referrer = userlist[userdetls[referrer1].ReferrerID];
        }
        else if(level==3){
            referrer1= userlist[userdetls[_user].ReferrerID];
            referrer2= userlist[userdetls[referrer1].ReferrerID];
            referrer =userlist[userdetls[referrer2].ReferrerID];
        }
        
        else if(level==4){
            referrer1= userlist[userdetls[_user].ReferrerID];
            referrer2= userlist[userdetls[referrer1].ReferrerID];
            referrer3 =userlist[userdetls[referrer2].ReferrerID];
            referrer =userlist[userdetls[referrer3].ReferrerID];
            
        }
         else if(level==5){
            referrer1= userlist[userdetls[_user].ReferrerID];
            referrer2= userlist[userdetls[referrer1].ReferrerID];
            referrer3 =userlist[userdetls[referrer2].ReferrerID];
            referrer4 =userlist[userdetls[referrer3].ReferrerID];
            referrer =userlist[userdetls[referrer4].ReferrerID];
        }
        
        else if(level==6){
            referrer1= userlist[userdetls[_user].ReferrerID];
            referrer2= userlist[userdetls[referrer1].ReferrerID];
            referrer3 =userlist[userdetls[referrer2].ReferrerID];
            referrer4 =userlist[userdetls[referrer3].ReferrerID];
            referrer5 =userlist[userdetls[referrer4].ReferrerID];
            referrer =userlist[userdetls[referrer5].ReferrerID];
        }
        if(!userdetls[referrer].exsist) referrer=userlist[1];
        
        bool sent = false;
        if(userdetls[referrer].levelExpired[level]>now){
             sent = address(uint160(referrer)).send(Levelprice[level]);
             if(sent){
                emit getmoney(referrer,msg.sender,level,now);
            
                 }
        }
        if(!sent){
            emit losemoney(referrer,msg.sender,level,now);
            
            payforlevel(level,referrer);
        }
    }
        
        
        
        function findFreeReferrer(address user)public view returns(address){
             if(userdetls[user].referral.length < Referrer_Limit) return user;
             
           
             address[] memory referrals = new address[](126);
              referrals[0] = userdetls[user].referral[0];
               referrals[1] = userdetls[user].referral[1];

                   address freeReferrer;
                  bool noFreeReferrer = true;

        for(uint i = 0; i < 254; i++) {
            if(userdetls[referrals[i]].referral.length ==Referrer_Limit ) {
                if(i < 126) {
                    referrals[(i+1)*2] = userdetls[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userdetls[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        
        
             
               }
               
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userdetls[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userdetls[_user].levelExpired[_level];
    }
        
        
    }