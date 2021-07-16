//SourceUnit: ttt.sol

pragma solidity 0.5.9;

contract TrxPeertopeer {
      address payable ownerWallet;
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool1activeUserID = 1;
      
      
      uint public unlimited_level_price=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint referredUsers;
        mapping(uint => uint) levelExpired;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        uint referred_purchase; 
        uint256 time1;
        uint256 time2;
        uint256 time3;
        uint256 time4;
        uint256 time5;
        uint256 time6;
    }
    
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
     
    mapping (address => PoolUserStruct) public pool1users;
    mapping (uint => address) public pool1userList;
     
    mapping(uint => uint) public LEVEL_PRICE;
    
    ////////////////////////////
    ////////////////////////////
    //mapping(address=>uint256) donRef;
    ////////////////////////////
    ////////////////////////////
    
    uint REGESTRATION_FESS=1000*1e6;
    ////////////////////////////////
    uint pool1_price=1000*1e6;
    ////////////////////////////////
    uint pool2_price=2000*1e6;
    /////////////////////////////////
    uint pool3_price=5000*1e6;
    /////////////////////////////////
    uint pool4_price=10000*1e6;
    //////////////////////////////////
    uint pool5_price=20000*1e6;
    //////////////////////////////////
    uint pool6_price=50000*1e6;
    //////////////////////////////////
   
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getRefBal(address indexed _user,uint level,uint amount ,address sender);
    event getProRefBal(address indexed _user,uint level,uint amount,address sender);
    event regPoolEntry(address indexed _user,uint _level,uint _time);
    event getPoolPayment(address indexed _receiver, uint product , uint amount ,uint purchaseid,address sender);
    event productPayClear(address indexed _user, uint product,uint purchaseid,address sender);
   
    UserStruct[] public requests;
     
    constructor() public {
        ownerWallet = address(0x410851fae17a66b544a8d1983631f6257b7052a3de); //TAjCcfUKou2t9iBVJUq6vSuChiaaoWqVpk

        LEVEL_PRICE[1] = 500*1e6;
        LEVEL_PRICE[2] = 300*1e6;
        LEVEL_PRICE[3] = 100*1e6;
        LEVEL_PRICE[4] =  40*1e6;
        LEVEL_PRICE[5] =  10*1e6;
        LEVEL_PRICE[6] =  10*1e6;
        LEVEL_PRICE[7] =  10*1e6;
        LEVEL_PRICE[8] =  10*1e6;
        LEVEL_PRICE[9] =  10*1e6;
        LEVEL_PRICE[10] =  10*1e6;
        
        UserStruct memory userStruct;
         /////////intial user 1*****************
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUsers:0
        });
        
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
      }
     
    function regUser(address _referrerAddress) public payable {
        uint referID = 0;
        for(uint p = 1 ; p <= currUserID ; p++){
            if(userList[p] == _referrerAddress){
                referID = p;
            }
        }
        require(!users[msg.sender].isExist, "User Exists");
        require(referID <= currUserID, 'Incorrect referral ID');
        require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
        //require(now>,"Registration Not Started!");
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: referID,
            referredUsers:0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        
        payReferral(1,msg.sender);
        emit regLevelEvent(msg.sender, userList[referID], now);
    }
   
   
    function payReferral(uint _level, address _user) internal {
        address referer;
        
        referer = userList[users[_user].referrerID];
        
        bool sent = false;
    
        uint level_price_local=0;
        
        level_price_local=LEVEL_PRICE[_level];
        
        sent = address(uint160(referer)).send(level_price_local);

        if (sent) {
            emit getRefBal(referer, _level, level_price_local,msg.sender);
            if(_level < 10 && users[referer].referrerID >= 1){
                payReferral(_level+1,referer);
            }
            else
            {
                sendBalance();
            }
            
        }
     }
     ////////////////////////////////////////////
     ////////////////////////////////////////////
     ///30 , 20 , 15 , 3
     mapping(uint => uint256) public P_LEVEL_PRICE;
     /////////////////
     uint256 public productRefAmount = 0;
     ////////////////
     
     function distributeProductRefferal(uint product) internal{
         
         if(product==1){
             productRefAmount = 100 * 1e6;
         }
         else if(product==2){
             productRefAmount = 200 * 1e6;
         }
         else if(product==3){
             productRefAmount = 500 * 1e6;
         }
         else if(product==4){
             productRefAmount = 1000 * 1e6;
         }
         else if(product==5){
             productRefAmount = 2000 * 1e6;
         }
         else if(product==6){
             productRefAmount = 5000 * 1e6;
         }
         else{
             productRefAmount = 0;
         }
         P_LEVEL_PRICE[1] = productRefAmount * 35/100; //35%
         P_LEVEL_PRICE[2] = productRefAmount * 20/100; //20%
         P_LEVEL_PRICE[3] = productRefAmount * 10/100;//10%
         P_LEVEL_PRICE[4] = productRefAmount * 5/100;//5%
         P_LEVEL_PRICE[5] = productRefAmount * 3/100;//3%
         P_LEVEL_PRICE[6] = productRefAmount * 3/100;//3%
         P_LEVEL_PRICE[7] = productRefAmount * 3/100;//3%
         P_LEVEL_PRICE[8] = productRefAmount * 2/100;//2%
         P_LEVEL_PRICE[9] = productRefAmount * 2/100;//2%
         P_LEVEL_PRICE[10] =productRefAmount * 2/100;//2%
         P_LEVEL_PRICE[11] =productRefAmount * 1/100;//1%
         
         productReferral(1,msg.sender); // 10% referer
         //ownerWallet.transfer(productRefAmount); // 10% owner
         //address(uint160(ownerWallet)).send(productRefAmount);
     }
     
     function productReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].referrerID];
       
         bool sent = false;
       
        uint level_price_local=0;
        if(_level>=11){
        level_price_local=P_LEVEL_PRICE[11];
        }
        else{
        level_price_local=P_LEVEL_PRICE[_level];
        }
        sent = address(uint160(referer)).send(level_price_local);

        if (sent) {
            emit getProRefBal(referer, _level, level_price_local,msg.sender);
            if(_level < 20 && users[referer].referrerID >= 1){
                productReferral(_level+1,referer);
            }
            else
            {
                sendBalance();
            }
            
        }
    
     }
     ////////////////////////////////////////////
    function enter() public payable{
        require(now>=1603940400,"Sale Not Started!");
            if(msg.value==1000*1e6){
                buyPool1(1);
            }
            else if(msg.value==2000*1e6){
                buyPool1(2);
            }
            else if(msg.value==5000*1e6){
                buyPool1(3);
            }
            else if(msg.value==10000*1e6){
                buyPool1(4);
            }
            else if(msg.value==20000*1e6){
                buyPool1(5);
            }
            else if(msg.value==50000*1e6){
                buyPool1(6);
            }
            else{
                revert("Invalid Amount!");
            }
            
    }
    mapping(uint=>uint) public productNumbera;
    
    function buyPool1(uint product) internal {
        require(users[msg.sender].isExist, "User Not Registered");
        
        if(pool1users[msg.sender].isExist){
            pool1currUserID++;
            productNumbera[pool1currUserID]=product;
            pool1userList[pool1currUserID]=msg.sender;   
        }
        else{
            //////////////////////////////////////////////
            PoolUserStruct memory userStruct;
            pool1currUserID++;
            productNumbera[pool1currUserID]=product;
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool1currUserID,
                payment_received:0,
                referred_purchase:0,
                time1:0,
                time2:0,
                time3:0,
                time4:0,
                time5:0,
                time6:0
            });
            pool1users[msg.sender] = userStruct;
            pool1userList[pool1currUserID]=msg.sender;
            ///////////////////////////////////////////////
        }
        if(product==1){
            require(pool1users[msg.sender].time1<now, "Wait for 180 minutes before next purchase");
            pool1users[msg.sender].time1=now+180 minutes;
            uint referrerId=users[msg.sender].referrerID;
            address referrerAddress=userList[referrerId];
            if(pool1users[referrerAddress].isExist){
                pool1users[referrerAddress].referred_purchase=pool1users[referrerAddress].referred_purchase+1000;
            }
            sendPayment(800*1e6);
        }
        else if(product==2){
            require(pool1users[msg.sender].time2<now, "Wait for 180 minutes before next purchase");
            pool1users[msg.sender].time2=now+180 minutes;
            uint referrerId=users[msg.sender].referrerID;
            address referrerAddress=userList[referrerId];
            if(pool1users[referrerAddress].isExist){
                pool1users[referrerAddress].referred_purchase=pool1users[referrerAddress].referred_purchase+2000;
            }
            sendPayment(1600*1e6);
        }
        else if(product==3){
            require(pool1users[msg.sender].time3<now, "Wait for 180 minutes before next purchase");
            pool1users[msg.sender].time3=now+180 minutes;
            uint referrerId=users[msg.sender].referrerID;
            address referrerAddress=userList[referrerId];
            if(pool1users[referrerAddress].isExist){
                pool1users[referrerAddress].referred_purchase=pool1users[referrerAddress].referred_purchase+5000;
            }
            sendPayment(4000*1e6);
        }
        else if(product==4){
            require(pool1users[msg.sender].time4<now, "Wait for 180 minutes before next purchase");
            pool1users[msg.sender].time4=now+180 minutes;
            uint referrerId=users[msg.sender].referrerID;
            address referrerAddress=userList[referrerId];
            if(pool1users[referrerAddress].isExist){
                pool1users[referrerAddress].referred_purchase=pool1users[referrerAddress].referred_purchase+10000;
            }
            sendPayment(8000*1e6);
        }
        else if(product==5){
            require(pool1users[msg.sender].time5<now, "Wait for 180 minutes before next purchase");
            pool1users[msg.sender].time5=now+180 minutes;
            uint referrerId=users[msg.sender].referrerID;
            address referrerAddress=userList[referrerId];
            if(pool1users[referrerAddress].isExist){
                pool1users[referrerAddress].referred_purchase=pool1users[referrerAddress].referred_purchase+20000;
            }
            sendPayment(16000*1e6);
        }
        else if(product==6){
            require(pool1users[msg.sender].time6<now, "Wait for 180 minutes before next purchase");
            pool1users[msg.sender].time6=now+180 minutes;
            uint referrerId=users[msg.sender].referrerID;
            address referrerAddress=userList[referrerId];
            if(pool1users[referrerAddress].isExist){
                pool1users[referrerAddress].referred_purchase=pool1users[referrerAddress].referred_purchase+50000;
            }
            sendPayment(40000*1e6);
        }
        
        emit regPoolEntry(msg.sender, product, now);
        distributeProductRefferal(product);
       /////////////////////
    }
    
    function sendPayment(uint256 amount) internal{
        for(uint p = 1 ; p < pool1currUserID ; p++){
            address getter = pool1userList[p];
            uint prod = productNumbera[p];
            if(prod > 0){
                if(prod==1){
                    if(pool1users[getter].referred_purchase>=1000){
                        pool1activeUserID=p;
                        break;
                    }
                }
                else if(prod==2){
                    if(pool1users[getter].referred_purchase>=2000){
                        pool1activeUserID=p;
                        break;
                    }
                }
                else if(prod==3){
                    if(pool1users[getter].referred_purchase>=5000){
                        pool1activeUserID=p;
                        break;
                    }
                }
                else if(prod==4){
                    if(pool1users[getter].referred_purchase>=10000){
                        pool1activeUserID=p;
                        break;
                    }
                }
                else if(prod==5){
                    if(pool1users[getter].referred_purchase>=20000){
                        pool1activeUserID=p;
                        break;
                    }
                }
                else if(prod==6){
                    if(pool1users[getter].referred_purchase>=50000){
                        pool1activeUserID=p;
                        break;
                    }
                }
            }
        }
        
        address poolCurrentuser=pool1userList[pool1activeUserID];
        uint256 amountReceived = pool1users[poolCurrentuser].payment_received;
        uint256 totalAmount=0;
        uint256 amountPending=0;
        bool sent;
        uint product = productNumbera[pool1activeUserID];
        uint mylimit = 0;
        if(product==1){
            totalAmount=1100*1e6;
            mylimit = 1000;
        }
        else if(product==2){
            totalAmount=2200*1e6;
            mylimit = 2000;
        }
        else if(product==3){
            totalAmount=5500*1e6;
            mylimit = 5000;
        }
        else if(product==4){
            totalAmount=11000*1e6;
            mylimit = 10000;
        }
        else if(product==5){
            totalAmount=22000*1e6;
            mylimit = 20000;
        }
        else if(product==6){
            totalAmount=55000*1e6;
            mylimit = 50000;
        }
        
        amountPending = totalAmount - amountReceived;
        if(amountPending>=amount){
            sent = address(uint160(poolCurrentuser)).send(amount);
            pool1users[poolCurrentuser].payment_received=pool1users[poolCurrentuser].payment_received+amount;
            
            emit getPoolPayment(poolCurrentuser, product, amount ,pool1activeUserID,msg.sender);
            
            if(amount==amountPending){
                pool1users[poolCurrentuser].payment_received=0;
                pool1users[poolCurrentuser].referred_purchase=pool1users[poolCurrentuser].referred_purchase-mylimit;
                productNumbera[pool1activeUserID]=0;
                emit productPayClear(poolCurrentuser, product,pool1activeUserID,msg.sender);
                pool1activeUserID++;
            }
        }
        else if(amountPending<amount){
            sent = address(uint160(poolCurrentuser)).send(amountPending);
            pool1users[poolCurrentuser].payment_received=0;
            
            emit getPoolPayment(poolCurrentuser, product, amountPending,pool1activeUserID,msg.sender);
            emit productPayClear(poolCurrentuser, product,pool1activeUserID,msg.sender);
            
            pool1activeUserID++;
            sendPayment(amount - amountPending);
        }
            
        
    }
    //**************************************************************
    function getBuyable() public view returns(uint){
        

    }
    function getEthBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getNow() public view returns(uint) {
        return now;
    }
    
    function sendBalance() private
    {
        
         if (!address(uint160(ownerWallet)).send(getEthBalance()))
         {
             
         }
    }
   
   
    // function withdraw() external {
    //     (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

    //     require(to_payout > 0, "Zero payout");

    //     users[msg.sender].total_payouts += to_payout;
    //     total_withdraw += to_payout;

    //     require(devFee <= address(this).balance, "invalid data");
    //     uint256 reducedBalace = address(this).balance - devFee;
    //     require(reducedBalace >= to_payout,"not enough balance");

    //     msg.sender.transfer(to_payout);

    //     emit Withdraw(msg.sender, to_payout);

    //     if(users[msg.sender].payouts >= max_payout) {
    //         emit LimitReached(msg.sender, users[msg.sender].payouts);
    //     }
    // }


    // function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
    //     max_payout = 0;
    //     for(uint p = 1 ; p <= pool1currUserID ; p++){
    //         if(pool1userList[p] == msg.sender){
    //             if(productNumbera[p] == 1){
    //                 if(pool1users[msg.sender].time1 > now){
    //                     max_payout += 1100*1e6 - pool1users[msg.sender].payment_received;
    //                 }
    //             }
    //             if(productNumbera[p] == 2){
    //                 if(pool1users[msg.sender].time2 > now){
    //                     max_payout += 2200*1e6 - pool1users[msg.sender].payment_received;
    //                 }
    //             }
    //             if(productNumbera[p] == 3){
    //                 if(pool1users[msg.sender].time3 > now){
    //                     max_payout += 5500*1e6 - pool1users[msg.sender].payment_received;
    //                 }
    //             }
    //             if(productNumbera[p] == 4){
    //                 if(pool1users[msg.sender].time4 > now){
    //                     max_payout += 11000*1e6 - pool1users[msg.sender].payment_received;
    //                 }
    //             }
    //             if(productNumbera[p] == 5){
    //                 if(pool1users[msg.sender].time5 > now){
    //                     max_payout += 22000*1e6 - pool1users[msg.sender].payment_received;
    //                 }
    //             }
    //             if(productNumbera[p] == 6){
    //                 if(pool1users[msg.sender].time6 > now){
    //                     max_payout += 55000*1e6 - pool1users[msg.sender].payment_received;
    //                 }
    //             }
    //         }
    //     }

    //     if(users[_addr].deposit_payouts < max_payout) {
    //         payout = (max_payout * ((now - pool1users[msg.sender].time6) / 1 days) / 100) * 1666/1000;
    //     }
    // }
}