/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity 0.5.11;


contract MonsteringToken {
address public ownerWallet;
    string public constant name = "Monstering";
    string public constant symbol = "MTK";
    uint8 public constant decimals = 18; 




    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
event TransferFromContract(address indexed from, address indexed to, uint tokens,uint status);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
   
    uint256 totalSupply_=100000000000000000000000000000;

    using SafeMath for uint256;


   constructor() public { 
ownerWallet=msg.sender;
balances[ownerWallet] = totalSupply_;
    } 

    function totalSupply() public view returns (uint256) {
return totalSupply_;
    }
   
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
   
    function balanceOfOwner() public view returns (uint) {
        return balances[ownerWallet];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
   
    function transferFromOwner(address receiver, uint numTokens,uint status) internal returns (bool) {
        numTokens=numTokens*1000000000000000000;
        if(numTokens <= balances[ownerWallet]){
        balances[ownerWallet] = balances[ownerWallet].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit TransferFromContract(ownerWallet, receiver, numTokens,status);
        }
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) internal returns (bool) {
        require(numTokens <= balances[owner]);   
        require(numTokens <= allowed[owner][msg.sender]);
   
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract Monstering is MonsteringToken{
     address public ownerWallet;
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool2currUserID = 0;
      uint public pool3currUserID = 0;
       uint public jackpotcurrUserID = 0;
   
        uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
    
     
     
      uint public unlimited_level_price=0;
    
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
        mapping(uint => uint) levelExpired;
        uint referredUserspool3;
        uint referredUserspool1;
    }
   
 
   
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received;
       bool lucky_draw;
       address user;
    }
    struct UserRegStruct{
        bool isExist;
        uint userid;
        uint nooftime;
        uint payment_received;
        uint poolid;
    }
    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
    
     mapping (uint => PoolUserStruct) public pool1users;
    mapping (address => UserRegStruct) public pool1userList;
   
     mapping (uint => PoolUserStruct) public pool2users;
     mapping (address => UserRegStruct) public pool2userList;
    
     mapping (uint => PoolUserStruct) public pool3users;
     mapping (address => UserRegStruct) public pool3userList;
    
  mapping (uint => address) public jackoptuserList;
 
 
 
 
     uint counter =0;

  uint pool_payment_amount=0.02 ether;
 
      event getMoneyForPoolLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
      event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event regPoolEntry(address indexed _user,uint _level,   uint _time,uint poolid);
  
    
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
    event luckydraw(uint id,address indexed _receiver, uint _level, uint _time);
   event regJackpotPool(uint id,address indexed _user,uint _time);
    UserStruct[] public requests;
    
      constructor()MonsteringToken() public {
          ownerWallet = msg.sender;

  
  
        UserStruct memory userStruct;
        UserRegStruct memory pooluserreg;
       
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUsers:0,
           referredUserspool3:0,
           referredUserspool1:0
        });
       
        users[ownerWallet] = userStruct;
       userList[currUserID] = ownerWallet;
      
      
         PoolUserStruct memory pooluserStruct;

        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            lucky_draw:false,
            user:msg.sender
        });
    pool1activeUserID=pool1currUserID;
       pool1users[pool1currUserID] = pooluserStruct;
      
      pooluserreg = UserRegStruct({
            isExist: true,
            userid: currUserID,
            payment_received:0,
           nooftime:1,
           poolid:pool1currUserID
          
        });
       
   
     pool1userList[msg.sender]=pooluserreg;
     
       
        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            lucky_draw:false,
            user:msg.sender
        });
    pool2activeUserID=pool2currUserID;
       pool2users[pool2currUserID] = pooluserStruct;
      

       
    pooluserreg = UserRegStruct({
            isExist: true,
            userid: currUserID,
           nooftime:1,
           poolid:pool2currUserID,
           payment_received:0
        });
       
     pool2userList[msg.sender]=pooluserreg;
      
      
        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            lucky_draw:false,
            user:msg.sender
        });
    pool3activeUserID=pool3currUserID;
       pool3users[pool3currUserID] = pooluserStruct;
     
       pooluserreg = UserRegStruct({
            isExist: true,
            userid: currUserID,
           nooftime:1,
           poolid:pool3currUserID,
           payment_received:0
        });
       
     pool3userList[msg.sender]=pooluserreg;
      
      }
     
    
     
     
    
        function regUser(uint _referrerID) public {
      
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
      
      
      if(!users[msg.sender].isExist)
      {
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:0,
            referredUserspool3:0,
            referredUserspool1:0
        });
 
   
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
      
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
       
        transferFromOwner(msg.sender,1000,1);
         payReferral(msg.sender);
         emit regLevelEvent(msg.sender, userList[_referrerID], now);
      }
    }
  
  
     function payReferral( address _user) internal {
        address referer;
        referer = userList[users[_user].referrerID];
        transferFromOwner(referer,1000,2);
     }
  
  
  
   function payPoolReferral(uint _level, address _user) internal {
        address referer;
      
        referer = userList[users[_user].referrerID];
      
         bool sent = false;
            if(_level==1)
            {
                pool_payment_amount=0.04 ether;
            }
            else if(_level==2)
            {
                pool_payment_amount=0.1 ether;
            }
            else
            {
                pool_payment_amount=0.2 ether;
            }
            sent = address(uint160(referer)).send(pool_payment_amount);

            if (sent) {
                emit getMoneyForPoolLevelEvent(referer, msg.sender, _level, now);
                if(_level==1)
                {
                    transferFromOwner(referer,4000,3);
                }
                else if(_level==2)
                {
                    transferFromOwner(referer,10000,4);
                }
                else
                {
                    transferFromOwner(referer,20000,5);
                }
           
            }
           
           
            if(_level==1)
            {
                pool_payment_amount=0.034 ether;
            }
            else if(_level==2)
            {
                pool_payment_amount=0.085 ether;
            }
            else
            {
                pool_payment_amount=0.17 ether;
            }
           
           
             if (address(uint160(ownerWallet)).send(pool_payment_amount))
         {
             emit getMoneyForPoolLevelEvent(referer, ownerWallet, _level, now);
         }
      
     
     }
  
  
       function buyPool1() public payable {
      require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == 0.2 ether, 'Incorrect Value');
   
        PoolUserStruct memory userStruct;
        UserRegStruct memory userregStruct;
        pool1currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            lucky_draw:false,
            user:msg.sender
        });
       pool1users[pool1currUserID] = userStruct;

      
        if(pool1userList[msg.sender].isExist){
            pool1userList[msg.sender].nooftime=pool1userList[msg.sender].nooftime+1;
        }
        else{
        userregStruct=UserRegStruct({
            isExist:true,
            userid:users[msg.sender].id,
            nooftime:1,
            poolid:pool1currUserID,
            payment_received:0
        });
        pool1userList[msg.sender]=userregStruct;
        users[userList[users[msg.sender].referrerID]].referredUserspool1=users[userList[users[msg.sender].referrerID]].referredUserspool1+1;
        }
      
       transferFromOwner(msg.sender,20000,6);
      
      
      payPoolReferral(1,msg.sender);
      uint pool1activeUserID_local=pool1activeUserID;
      uint temp_i=6;
      for (uint i=0; i<6; i++) {
          if((pool1activeUserID_local+i)>pool1currUserID){
              temp_i=i;
              break;
          }
         uint pool1Currentuser=pool1users[pool1activeUserID_local+i].id;
        
      bool sent = false;
      sent = address(uint160(pool1users[pool1Currentuser].user)).send(0.02 ether);

            if (sent) {
                pool1users[pool1Currentuser].payment_received+=1;
                 pool1userList[pool1users[pool1Currentuser].user].payment_received+=1;
                if(pool1users[pool1Currentuser].payment_received>=14)
                {
                    pool1activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool1users[pool1Currentuser].user, 1, now);
                transferFromOwner(pool1users[pool1Currentuser].user,2000,9);
            }
      
      }
      if(temp_i<6)
      {
      bool s= address(uint160(ownerWallet)).send(0.02 ether * (6-temp_i)); 
      if(s){}
      }
      emit regPoolEntry(msg.sender, 1, now,pool1currUserID);
      counter=0;
        if(((pool1currUserID-1)%5)==0 && pool1currUserID>=7){
     luckydrawPool1();
        }
    }
   
   
      function buyPool2() public payable {
      require(pool1userList[msg.sender].isExist, "Need to buy Pool 1");   
        require(msg.value == 0.5 ether, 'Incorrect Value');
       
      
        PoolUserStruct memory userStruct;
        UserRegStruct memory userregStruct;
       
        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            lucky_draw:false,
            user:msg.sender
        });
       pool2users[pool2currUserID] = userStruct;
      
         if(pool2userList[msg.sender].isExist){
            pool2userList[msg.sender].nooftime=pool2userList[msg.sender].nooftime+1;
        }
        else{
            userregStruct=UserRegStruct({
                isExist:true,
                userid:users[msg.sender].id,
                nooftime:1,
                poolid:pool2currUserID,
                payment_received:0
            });
            pool2userList[msg.sender]=userregStruct;
        }
      
      
       transferFromOwner(msg.sender,50000,7);
       payPoolReferral(2,msg.sender);
       uint pool2activeUserID_local=pool2activeUserID;
       uint temp_i=3;
       for (uint i=0; i<3; i++) {
           if((pool2activeUserID_local+i)>pool2currUserID){
                temp_i=i;
               break;
           }
         uint pool2Currentuser=pool2users[pool2activeUserID_local+i].id;
        
       bool sent = false;
       sent = address(uint160(pool2users[pool2Currentuser].user)).send(0.1 ether);

            if (sent) {
                pool2users[pool2Currentuser].payment_received+=1;
                 pool2userList[pool2users[pool2Currentuser].user].payment_received+=1;
                if(pool2users[pool2Currentuser].payment_received>=9)
                {
                    pool2activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool2users[pool2Currentuser].user, 2, now);
                transferFromOwner(pool2users[pool2Currentuser].user,10000,10);
            }
      
       }
       if(temp_i<3)
       {
       bool s= address(uint160(ownerWallet)).send(0.1 ether * (3-temp_i)); 
       if(s){}
       }
       emit regPoolEntry(msg.sender, 2, now,pool2currUserID);
       counter=0;
        if(((pool2currUserID-1)%5)==0 && pool2currUserID>=7){
     luckydrawPool2();
        }
      
    }
   
    /*
    Autopool3 users who have one direct referral at autopool3 are eligible for Jackpot.Jackpot fund will be reserved at 'Jackpot reserved wallet'.
    Eligible user ETH wallet list will be fetched from this contract and Jackpot Smart contract will choose 'Random User' from eligible users. 
    */
     function buyPool3() public payable {
         require(pool2userList[msg.sender].isExist, "Need to buy Pool 1 and 2");  
     
        require(msg.value == 1 ether, 'Incorrect Value');
      
        PoolUserStruct memory userStruct;
        UserRegStruct memory userregStruct;
       
        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            lucky_draw:false,
            user:msg.sender
        });
       pool3users[pool3currUserID] = userStruct;
      
         if(pool3userList[msg.sender].isExist){
            pool3userList[msg.sender].nooftime=pool3userList[msg.sender].nooftime+1;
        }
        else{
            userregStruct=UserRegStruct({
                isExist:true,
                userid:users[msg.sender].id,
                nooftime:1,
                poolid:pool3currUserID,
                payment_received:0
            });
            pool3userList[msg.sender]=userregStruct;
        }
       
       
      
        users[userList[users[msg.sender].referrerID]].referredUserspool3=users[userList[users[msg.sender].referrerID]].referredUserspool3+1;
       
        if(users[userList[users[msg.sender].referrerID]].referredUserspool3==1 && pool3users[users[msg.sender].referrerID].isExist)
        {
            jackpotcurrUserID++;
            jackoptuserList[jackpotcurrUserID]=userList[users[msg.sender].referrerID];
           
             emit regJackpotPool(users[msg.sender].referrerID,userList[users[msg.sender].referrerID], now);
        }
       
        if(users[msg.sender].referredUserspool3==1)
        {
            jackpotcurrUserID++;
            jackoptuserList[jackpotcurrUserID]=userList[users[msg.sender].id];
           emit regJackpotPool(users[msg.sender].id,userList[users[msg.sender].id], now);
        }
        transferFromOwner(msg.sender,100000,8);
       payPoolReferral(3,msg.sender);
       uint pool3activeUserID_local=pool3activeUserID;
       uint temp_i=3;
       for (uint i=0; i<3; i++) {
           if((pool3activeUserID_local+i)>pool3currUserID){
               temp_i=i;
               break;
           }
         uint pool3Currentuser=pool3users[pool3activeUserID_local+i].id;
        
       bool sent = false;
       sent = address(uint160(pool3users[pool3Currentuser].user)).send(0.2 ether);

            if (sent) {
                pool3users[pool3Currentuser].payment_received+=1;
                pool3userList[pool3users[pool3Currentuser].user].payment_received+=1;
               
                if(pool3users[pool3Currentuser].payment_received>=10)
                {
                    pool3activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool3users[pool3Currentuser].user, 3, now);
                transferFromOwner(pool3users[pool3Currentuser].user,20000,11);
            }
     
       }
       if(temp_i<3)
       {
       bool s= address(uint160(ownerWallet)).send(0.2 ether * (3-temp_i)); 
       if(s){}
       }
       emit regPoolEntry(msg.sender, 3, now,pool3currUserID);
       counter=0;
        if(((pool3currUserID-1)%5)==0 && pool3currUserID>=7){
     luckydrawPool3();
        }
    
    }
  
   
    function luckydrawPool1() private
    {
        uint lower=pool1activeUserID+6;
        if(pool1currUserID >= 110)
        {
            lower=pool1currUserID-100;
        }
        uint num = (block.timestamp % ((pool1currUserID) - lower + 1)) + lower;
        uint pool1Currentuser=pool1users[num].id;  
        if(pool1users[pool1Currentuser].payment_received==0 && pool1users[pool1Currentuser].lucky_draw==false){
            bool sent = false;
            sent = address(uint160(pool1users[pool1Currentuser].user)).send(0.03 ether);

            if (sent) {
                pool1users[pool1Currentuser].lucky_draw=true;
               emit luckydraw(num,pool1users[pool1Currentuser].user,1,now);
               transferFromOwner(pool1users[pool1Currentuser].user,3000,12);
            }
         }
         else
         {
             counter++;
             if(counter<=(pool1currUserID- lower)){
             luckydrawPool1();   
             }
            
         }
   
       
    }
   
   
     function luckydrawPool2() private
    {
        uint lower=pool2activeUserID+6;
        if(pool2currUserID >= 110)
        {
            lower=pool2currUserID-100;
        }
        uint num = (block.timestamp % ((pool2currUserID) - lower + 1)) + lower;
         uint pool2Currentuser=pool2users[num].id; 
        if(pool2users[pool2Currentuser].payment_received==0 && pool2users[pool2Currentuser].lucky_draw==false){
            bool sent = false;
            sent = address(uint160(pool2users[pool2Currentuser].user)).send(0.075 ether);

            if (sent) {
                pool2users[pool2Currentuser].lucky_draw=true;
               emit luckydraw(num,pool2users[pool2Currentuser].user,2,now);
               transferFromOwner(pool2users[pool2Currentuser].user,7500,12);
            }
         }
         else
         {
             counter++;
             if(counter<=(pool2currUserID- lower)){
             luckydrawPool2();   
             }
            
         }
   
       
    }
   
   
    function luckydrawPool3() private
    {
        uint lower=pool3activeUserID+6;
        if(pool3currUserID >= 110)
        {
            lower=pool3currUserID-100;
        }
        uint num = (block.timestamp % ((pool3currUserID) - lower + 1)) + lower;
        uint pool3Currentuser=pool3users[num].id;  
        if(pool3users[pool3Currentuser].payment_received==0 && pool3users[pool3Currentuser].lucky_draw==false){
            bool sent = false;
            sent = address(uint160(pool3users[pool3Currentuser].user)).send(0.15 ether);

            if (sent) {
                pool3users[pool3Currentuser].lucky_draw=true;
               emit luckydraw(num,pool3users[pool3Currentuser].user,3,now);
               transferFromOwner(pool3users[pool3Currentuser].user,15000,12);
            }
         }
         else
         {
             counter++;
             if(counter<=(pool3currUserID- lower)){
             luckydrawPool3();   
             }
            
         }
   
       
    }
   
   
   
   
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
   
    function viewUserReferral(address _user) public view returns(address) {
        return userList[users[_user].referrerID];
    }
   
    function checkUserExist(address _user) public view returns(bool) {
        return users[_user].isExist;
    }
   
    function checkUserPool1Exist(address _user) public view returns(bool) {
        return pool1userList[_user].isExist;
    }
   
     function checkUserPool2Exist(address _user) public view returns(bool) {
        return pool2userList[_user].isExist;
    }
     function checkUserPool3Exist(address _user) public view returns(bool) {
        return pool2userList[_user].isExist;
    }
   
     function getCurrentJackpotId() public view returns(uint) {
        return jackpotcurrUserID;
    }
   
     function getPool3currId() public view returns(uint) {
        return pool3currUserID;
    }
   
    function getCurrentJackpotUser(uint id) public view returns(address) {
        return jackoptuserList[id];
    }
   
    function sendBalance() private
    {
        if(getEthBalance()>0){
         if (!address(uint160(ownerWallet)).send(getEthBalance()))
         {
            
         }
        }
    }
  
    function sendPendingBalance(uint amount) public
    {
         require(msg.sender==ownerWallet, "You are not authorized"); 
        if(msg.sender==ownerWallet){
        if(amount>0 && amount<=getEthBalance()){
         if (!address(uint160(ownerWallet)).send(amount))
         {
            
         }
        }
        }
    }
}