//SourceUnit: MegatronUpdated.sol

pragma solidity 0.5.9;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

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

contract Megatron {
      using SafeMath for uint256;
      address public ownerWallet;
      address public leaderPoolAddress;
      address public adminAddress;
      uint public currUserID = 0;
      uint public placeNextParent = 0;
      uint public maxDownLimit = 4;
      uint public maxDownAllChildLimit = 84;
      address public parentNewAddressNew;
      address public topaddressNew;
      address public ccc;
      address public ccc1;
      uint public ccc2;
      uint public ccc3;

      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint virtualID;
        uint referredUsers;
        uint totalEarnedreferral;
        uint currentlevel;
        mapping(uint => uint) levelExpired;
        mapping(uint => uint) totalChildCount;
        mapping (uint => uint) recyclecount;
        address[] referral;
     }

     struct PoolUserStruct {
        bool isExist;
        uint id;
        uint payment_received;
    }

    struct SuperStruct {
        uint id;
        address[] referral;
        mapping (uint => uint) reinvestcount;
        mapping (uint => address) matrixcount;
        mapping (uint => address) matrixcount1;
        mapping (uint => address) matrixcount2;
        mapping (uint => address) matrixcount3;
        mapping (uint => address) parentmatrixAddress;
        mapping (uint => bool) matrixExist;
        mapping (uint => bool) matrixvalid;
        mapping (uint => address[]) matrixchild;
        mapping (uint => address[]) directchild;
        mapping (uint => address[]) matrixchild1;
        mapping (uint => address[]) directchild1;
        mapping (uint => address[]) matrixchild2;
        mapping (uint => address[]) directchild2;
        mapping (uint => address[]) matrixchild3;
        mapping (uint => address[]) directchild3;
    }
    mapping (uint => uint) matrixUserID;
    mapping (uint => uint) eligibleUserID;

    mapping (uint => uint) matrixUserID1;
    mapping (uint => uint) eligibleUserID1;
    mapping (uint => uint) matrixUserID2;
    mapping (uint => uint) eligibleUserID2;
    mapping (uint => uint) matrixUserID3;
    mapping (uint => uint) eligibleUserID3;

    mapping (uint => uint)  matrixNextParent1;
    mapping (uint => uint)  matrixNextParent2;
    mapping (uint => uint)  matrixNextParent3;

    mapping (uint => uint)  matrixNextParent;
    mapping (uint => uint) matrixallChildInc;

    mapping (address => SuperStruct) public matrixusers;
    mapping (uint => SuperStruct) public matrixusersID;

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;

    mapping (uint => uint) public LEVEL_PRICE;
    uint REGESTRATION_FESS= 1000 trx;

    uint256 directreferpercentage = 500;
    uint256 indirectreferpercentage = 50;
    uint256 leaderpoolpercentage = 100;
    uint256 globalpoolpercentage = 200;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _pool, uint _time, uint _price);
    event regPoolEntry(address indexed _user,uint _level,   uint _time);
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getPoolSponsorPayment(address indexed _user,address indexed _receiver, uint _level, uint _time, uint _price);
    event getReInvestPoolPayment(address indexed _user, uint _level, uint _time, uint _price);

    UserStruct[] public requests;
    uint public totalEarned = 0;

    constructor(address _leaderPooladdress, address _adminaddress) public {
        ownerWallet = msg.sender;
        leaderPoolAddress =_leaderPooladdress;
        adminAddress =_adminaddress;
        parentNewAddressNew= address(0);

        LEVEL_PRICE[1] = 1000 trx;
        LEVEL_PRICE[2] = 3200 trx;
        LEVEL_PRICE[3] = 10240 trx;
        LEVEL_PRICE[4] = 32768 trx;
        LEVEL_PRICE[5] = 104857.6 trx;
        LEVEL_PRICE[6] = 335544.32 trx;
        LEVEL_PRICE[7] = 1073741.82 trx;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            virtualID : 0,
            referredUsers:0,
            totalEarnedreferral:0,
            currentlevel:7,
            referral : new address[](0)
        });

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

    }

  function payReferral(uint level,address _useraddress) internal {
      uint levelAmount = LEVEL_PRICE[level];
        address referer;
        referer = userList[users[_useraddress].referrerID];
        uint256 referAmount = levelAmount.mul(indirectreferpercentage).div(1000);
         for (uint i = 1; i <= 4; i++) {
            if(users[referer].isExist)
            {
                if(level == 1){
                    address(uint160(referer)).transfer(referAmount);
                    users[referer].totalEarnedreferral += referAmount;
                }else{
                    sendBalance(referer,referAmount);
                }
            }
            else
            {
                if(level == 1){
                    address(uint160(ownerWallet)).transfer(referAmount);
                }else{
                    sendBalance(ownerWallet,referAmount);
                }

            }
            referer = userList[users[referer].referrerID];
          }
    }

    function safepayReferral(uint level,address _useraddress) internal {
      uint levelAmount = LEVEL_PRICE[level];
        address referer;
        referer = userList[users[_useraddress].referrerID];
        uint256 referAmount = levelAmount.mul(indirectreferpercentage).div(1000);
         for (uint i = 1; i <= 4; i++) {
            if(users[referer].isExist)
            {
                if(level == 1){
                  users[referer].totalEarnedreferral += referAmount;
                }
            }
            referer = userList[users[referer].referrerID];
          }
    }

    function activatePool(uint _referrerID) public payable {
        require(!users[msg.sender].isExist, "User Exists");
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
        UserStruct memory userStruct;
        currUserID++;
        uint virtualID;
        virtualID = _referrerID;
        if(users[userList[virtualID]].referral.length >= maxDownLimit) virtualID = users[findFreeReferrer(userList[virtualID])].id;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            virtualID : virtualID,
            referredUsers:0,
            totalEarnedreferral :0,
            currentlevel:1,
            referral : new address[](0)
        });
        for(uint r=1;r<=7;r++){
           users[msg.sender].recyclecount[r]=0;
        }
        users[msg.sender] = userStruct;
        userList[currUserID]=msg.sender;
        users[userList[virtualID]].referral.push(msg.sender);
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
        uint256 referAmount = REGESTRATION_FESS.mul(directreferpercentage).div(1000);
        bool sent = false;
        address spreferer = userList[users[msg.sender].referrerID];
         if(users[spreferer].isExist)
            {
               sent = address(uint160(spreferer)).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         address payable leaderPooladdr = address(uint160(leaderPoolAddress));
         uint256 leaderPoolAmount = REGESTRATION_FESS.mul(leaderpoolpercentage).div(1000);
         leaderPooladdr.transfer(leaderPoolAmount);
         address virtualaddr =  userList[users[msg.sender].virtualID];
         pushCountchild(1,virtualaddr,1);
         if(users[userList[virtualID]].referral.length <= maxDownLimit.div(2)){
            address topaddress = userList[users[msg.sender].virtualID];
            payForMatrix(1,address(uint160(topaddress)));
         }
         payReferral(1,spreferer);
    }

    function safeactivatePool(uint _referrerID, address _user) external {
        require(msg.sender==adminAddress,'Permission denied');
        require(!users[_user].isExist, "User Exists");
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        UserStruct memory userStruct;
        currUserID++;
        uint virtualID;
        virtualID = _referrerID;
        if(users[userList[virtualID]].referral.length >= maxDownLimit) virtualID = users[findFreeReferrer(userList[virtualID])].id;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            virtualID : virtualID,
            referredUsers:0,
            totalEarnedreferral :0,
            currentlevel:1,
            referral : new address[](0)
        });
        for(uint r=1;r<=7;r++){
           users[_user].recyclecount[r]=0;
        }
        users[_user] = userStruct;
        userList[currUserID]=_user;
        users[userList[virtualID]].referral.push(_user);
        users[userList[users[_user].referrerID]].referredUsers=users[userList[users[_user].referrerID]].referredUsers+1;
        emit regLevelEvent(_user, userList[_referrerID], now);
        uint256 referAmount = REGESTRATION_FESS.mul(directreferpercentage).div(1000);
       
        address spreferer = userList[users[_user].referrerID];
         if(users[spreferer].isExist)
            {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
            }
         address virtualaddr =  userList[users[_user].virtualID];
         pushCountchild(1,virtualaddr,1);
         if(users[userList[virtualID]].referral.length <= maxDownLimit.div(2)){
            address topaddress = userList[users[_user].virtualID];
            safepayForMatrix(1,address(uint160(topaddress)));
            users[topaddress].totalEarnedreferral += LEVEL_PRICE[1];
         }
         safepayReferral(1,spreferer);
    }


    function pushCountchild(uint _level,address user,uint increment) internal {

        uint countchild = users[user].totalChildCount[_level];
        address eligibleaddress = user;

        if(users[eligibleaddress].currentlevel == _level){
            if(countchild <= 84 && user != address(0)){

                if(countchild < 84){
                    users[user].totalChildCount[_level]++;
                    address parentAddress = userList[users[user].virtualID];
                     if(parentAddress != address(0)){
                        increment = increment+1;
                        if(increment <=3){
                            pushCountchild(_level,parentAddress,increment);
                        }
                    }

                    if(users[user].totalChildCount[_level]==84){
                        users[user].totalChildCount[_level] = 0;
                        if(eligibleaddress !=ownerWallet){

                             users[eligibleaddress].recyclecount[_level]++;
                             uint recyclecountUser = users[eligibleaddress].recyclecount[_level];
                             if(recyclecountUser == 1){
                                 reactivatePool1(_level,eligibleaddress);
                             }else if(recyclecountUser == 2){
                                 reactivatePool2(_level,eligibleaddress);
                             }else if(recyclecountUser == 3){
                                 reactivatePool3(_level,eligibleaddress);
                             }

                             uint nextlevel =  _level.add(1);
                             payforProfit(_level,eligibleaddress);
                             buyNextLevel(nextlevel,eligibleaddress);
                             matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                             users[eligibleaddress].currentlevel = nextlevel;
                        }
                    }

                }else{

                    users[user].totalChildCount[_level] = 0;
                    if(eligibleaddress !=ownerWallet){

                         users[eligibleaddress].recyclecount[_level]++;
                         uint recyclecountUser = users[eligibleaddress].recyclecount[_level];
                         if(recyclecountUser == 1){
                             reactivatePool1(_level,eligibleaddress);
                         }else if(recyclecountUser == 2){
                             reactivatePool2(_level,eligibleaddress);
                         }else if(recyclecountUser == 3){
                             reactivatePool3(_level,eligibleaddress);
                         }

                         uint nextlevel =  _level.add(1);
                         payforProfit(_level,eligibleaddress);
                         buyNextLevel(nextlevel,eligibleaddress);
                         matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                         users[eligibleaddress].currentlevel = nextlevel;
                    }

                }
            }

        }

    }

    function payforProfit(uint level, address profitaddr) private {

        uint levelAmount = LEVEL_PRICE[level];
        uint256 globalPoolAmount = levelAmount.mul(globalpoolpercentage).div(1000);
        uint profitPrice = globalPoolAmount * 11;
        address payable leaderPollAddr = address(uint160(profitaddr));
        leaderPollAddr.transfer(profitPrice);
        users[profitaddr].totalEarnedreferral += profitPrice;

    }

    function reactivatePool1(uint level,address user) private {
        uint levelAmount = LEVEL_PRICE[level];
        matrixUserID1[level]++;
        matrixusersID[matrixUserID1[level]].matrixcount1[level]  = user;
        address topaddress = matrixusersID[matrixNextParent1[level]].matrixcount1[level];
        address eligibleaddress = matrixusersID[eligibleUserID1[level]].matrixcount1[level];

        matrixusers[topaddress].directchild1[level].push(user);

        if(matrixusers[topaddress].directchild1[level].length <= maxDownLimit.div(2)){
            payForMatrix(level,address(uint160(topaddress)));
        }

        pushmatrixchild1(level,user,topaddress);

        if(matrixusers[eligibleaddress].matrixchild1[level].length >= maxDownAllChildLimit ){

            if(eligibleaddress !=ownerWallet){

                 users[eligibleaddress].recyclecount[level]++;
                 uint recyclecountUser = users[eligibleaddress].recyclecount[level];
                 if(recyclecountUser == 1){
                     reactivatePool1(level,eligibleaddress);
                 }else if(recyclecountUser == 2){
                     reactivatePool2(level,eligibleaddress);
                 }else if(recyclecountUser == 3){
                     reactivatePool3(level,eligibleaddress);
                 }

                 uint nextlevel =  level.add(1);
                 payforProfit(level,eligibleaddress);
                 buyNextLevel(nextlevel,eligibleaddress);
                 matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                 users[eligibleaddress].currentlevel = nextlevel;
            }

            eligibleUserID1[level]++;
        }

        if(matrixusers[topaddress].directchild1[level].length >= maxDownLimit ){
          matrixNextParent1[level]++;
        }
        uint256 referAmount = levelAmount.mul(directreferpercentage).div(1000);
        bool sent = false;
        address payable spreferer = address(uint160(userList[users[user].referrerID]));
         if(users[spreferer].isExist)
            {
               sent = address(spreferer).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(1000);

         address payable leaderPollAddr = address(uint160(leaderPoolAddress));
         leaderPollAddr.transfer(leaderPoolAmount);
         //pushCountchild(level,user);
         //placeAutopool(level,user);
         payReferral(level,spreferer);

    }

    function reactivatePool2(uint level,address user) private {
        uint levelAmount = LEVEL_PRICE[level];
        matrixUserID2[level]++;
        matrixusersID[matrixUserID2[level]].matrixcount2[level]  = user;
        address topaddress = matrixusersID[matrixNextParent2[level]].matrixcount2[level];
        address eligibleaddress = matrixusersID[eligibleUserID2[level]].matrixcount2[level];

        matrixusers[topaddress].directchild2[level].push(user);
        if(matrixusers[topaddress].directchild2[level].length <= maxDownLimit.div(2)){
            payForMatrix(level,address(uint160(topaddress)));
        }

        pushmatrixchild2(level,user,topaddress);

        if(matrixusers[eligibleaddress].matrixchild2[level].length >= maxDownAllChildLimit ){

            if(eligibleaddress !=ownerWallet){

                 users[eligibleaddress].recyclecount[level]++;
                 uint recyclecountUser = users[eligibleaddress].recyclecount[level];
                 if(recyclecountUser == 1){
                     reactivatePool1(level,eligibleaddress);
                 }else if(recyclecountUser == 2){
                     reactivatePool2(level,eligibleaddress);
                 }else if(recyclecountUser == 3){
                     reactivatePool3(level,eligibleaddress);
                 }

                 uint nextlevel =  level.add(1);
                 payforProfit(level,eligibleaddress);
                 buyNextLevel(nextlevel,eligibleaddress);
                 matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                 users[eligibleaddress].currentlevel = nextlevel;
            }

            eligibleUserID2[level]++;
        }

        if(matrixusers[topaddress].directchild2[level].length >= maxDownLimit ){
          matrixNextParent2[level]++;
        }
        uint256 referAmount = levelAmount.mul(directreferpercentage).div(2000);
        bool sent = false;
        address payable spreferer = address(uint160(userList[users[user].referrerID]));
         if(users[spreferer].isExist)
            {
               sent = address(spreferer).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(2000);

         address payable leaderPollAddr = address(uint160(leaderPoolAddress));
         leaderPollAddr.transfer(leaderPoolAmount);
         //pushCountchild(level,user);
         //placeAutopool(level,user);
         payReferral(level,spreferer);

    }

    function reactivatePool3(uint level,address user) private {
        uint levelAmount = LEVEL_PRICE[level];
        matrixUserID3[level]++;
        matrixusersID[matrixUserID3[level]].matrixcount3[level]  = user;
        address topaddress = matrixusersID[matrixNextParent3[level]].matrixcount3[level];
        address eligibleaddress = matrixusersID[eligibleUserID3[level]].matrixcount3[level];

        matrixusers[topaddress].directchild3[level].push(user);
        if(matrixusers[topaddress].directchild3[level].length <= maxDownLimit.div(2)){
            payForMatrix(level,address(uint160(topaddress)));
        }

        pushmatrixchild3(level,user,topaddress);

        if(matrixusers[eligibleaddress].matrixchild3[level].length >= maxDownAllChildLimit ){

            if(eligibleaddress !=ownerWallet){
                 uint nextlevel =  level.add(1);
                 users[eligibleaddress].recyclecount[level]++;
                 payforProfit(level,eligibleaddress);
                 matrixusers[eligibleaddress].matrixvalid[nextlevel] = true;
                 users[eligibleaddress].currentlevel = nextlevel;
            }
            eligibleUserID3[level]++;
        }

        if(matrixusers[topaddress].directchild3[level].length >= maxDownLimit ){
          matrixNextParent3[level]++;
        }
        uint256 referAmount = levelAmount.mul(directreferpercentage).div(2000);
        bool sent = false;
        address payable spreferer = address(uint160(userList[users[user].referrerID]));
         if(users[spreferer].isExist)
            {
               sent = address(spreferer).send(referAmount);
                if (sent)
                {
                  totalEarned += referAmount;
                  users[spreferer].totalEarnedreferral += referAmount;
                }
            }
            else
            {
                address(uint160(ownerWallet)).transfer(referAmount);
            }
         uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(2000);

         address payable leaderPollAddr = address(uint160(leaderPoolAddress));
         leaderPollAddr.transfer(leaderPoolAmount);
         payReferral(level,spreferer);
    }



    function pushmatrixchild(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild[_level].length < 84){

         matrixusers[parentaddress].matrixchild[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
         ccc1 = parentNewAddress;
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }

    function pushmatrixchild1(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild1[_level].length < 84){
         matrixusers[parentaddress].matrixchild1[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild1[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild1[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild1(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }


    function pushmatrixchild2(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild2[_level].length < 84){
         matrixusers[parentaddress].matrixchild2[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild2[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild2[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild2(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }


    function pushmatrixchild3(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild3[_level].length < 84){
         matrixusers[parentaddress].matrixchild3[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild3[_level].length < 84){
                 matrixusers[parentNewAddress].matrixchild3[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild3(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }


    function recyclecount(address _user) public view returns(uint[7] memory recyclecount1) {
        for (uint i = 0; i<7; i++) {
            recyclecount1[i] = users[_user].recyclecount[i+1];
        }
    }


    function buyNextLevel(uint level,address user) private {
        if(level <=7){
            uint levelAmount = LEVEL_PRICE[level];
            matrixUserID[level]++;
            matrixusersID[matrixUserID[level]].matrixcount[level]  = user;
            address topaddress = matrixusersID[matrixNextParent[level]].matrixcount[level];
            address eligibleaddress = matrixusersID[eligibleUserID[level]].matrixcount[level];

            matrixusers[topaddress].directchild[level].push(user);
            if(matrixusers[topaddress].directchild[level].length <= maxDownLimit.div(2)){
                payForMatrix(level,address(uint160(topaddress)));
            }
            ccc = topaddress;
            ccc3 =2;
            pushmatrixchild(level,user,topaddress);

            if(matrixusers[eligibleaddress].matrixchild[level].length >= maxDownAllChildLimit ){
                eligibleUserID[level]++;
            }

            if(matrixusers[topaddress].directchild[level].length >= maxDownLimit ){
              matrixNextParent[level]++;
            }
            uint256 referAmount = levelAmount.mul(directreferpercentage).div(1000);
            bool sent = false;
            address payable spreferer = address(uint160(userList[users[user].referrerID]));
             if(users[spreferer].isExist)
                {
                   sent = address(spreferer).send(referAmount);
                    if (sent)
                    {
                      totalEarned += referAmount;
                      users[spreferer].totalEarnedreferral += referAmount;
                    }
                }
                else
                {
                    address(uint160(ownerWallet)).transfer(referAmount);
                }
             uint256 leaderPoolAmount = levelAmount.mul(leaderpoolpercentage).div(1000);

             address payable leaderPollAddr = address(uint160(leaderPoolAddress));
             leaderPollAddr.transfer(leaderPoolAmount);
             //pushCountchild(level,user);
             //placeAutopool(level,user);
             payReferral(level,spreferer);
        }

    }

    function safepayForMatrix(uint level,address payable _user) internal {
         uint levelAmount = LEVEL_PRICE[level];
         uint256 globalPoolAmount = levelAmount.mul(globalpoolpercentage).div(1000);
         users[_user].totalEarnedreferral += globalPoolAmount;
    }

    function payForMatrix(uint level,address payable _user) internal {
         uint levelAmount = LEVEL_PRICE[level];
         uint256 globalPoolAmount = levelAmount.mul(globalpoolpercentage).div(1000);
         users[_user].totalEarnedreferral += globalPoolAmount;
         _user.transfer(globalPoolAmount);
    }

    function getTrxBalance() public view returns(uint) {
       return address(this).balance;
    }

    function sendBalance(address user,uint amount) private
    {

        if(getTrxBalance() >= amount){
            if(address(uint160(user)).send(amount)){

            }
        }
    }

     function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < maxDownLimit) return _user;
        address[] memory referrals = new address[](500);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        referrals[3] = users[_user].referral[3];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 500; i++) {
            if(users[referrals[i]].referral.length == maxDownLimit) {
                //if(i < 62) {
                    referrals[(i+1)*4] = users[referrals[i]].referral[0];
                    referrals[(i+1)*4+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*4+2] = users[referrals[i]].referral[2];
                    referrals[(i+1)*4+3] = users[referrals[i]].referral[3];
                //}
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }


    function getMatrixchildcount(address _user,uint matrixlevel) public view returns(uint) {
        return matrixusers[_user].matrixchild[matrixlevel].length;
    }

    function getMatrixchildcountList(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild[matrixlevel];
    }

    function getDirectChildcountList(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild[matrixlevel];
    }

    function getMatrixCount(uint mcount,uint matrixlevel) public view returns(address) {
        return matrixusersID[mcount].matrixcount[matrixlevel];
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    function getTotalcount(address _user,uint matrixlevel) public view returns(uint) {
        return users[_user].totalChildCount[matrixlevel];
    }
    function getMatrixchildcountList1(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild1[matrixlevel];
    }
    function getMatrixchildcountList2(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild2[matrixlevel];
    }
    function getMatrixchildcountList3(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].matrixchild3[matrixlevel];
    }
    function getDirectChildcountList1(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild1[matrixlevel];
    }
    function getDirectChildcountList2(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild2[matrixlevel];
    }
    function getDirectChildcountList3(address _user,uint matrixlevel) public view returns(address[] memory) {
        return matrixusers[_user].directchild3[matrixlevel];
    }




     function withdrawSafe( uint _amount) external {
        require(msg.sender==ownerWallet,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }

    function safeEntry( ) external {
        require(msg.sender==ownerWallet,'Permission denied');
        for(uint m=1;m<=7;m++){
            matrixUserID[m] = 1;
            matrixUserID1[m] = 1;
            matrixUserID2[m] = 1;
            matrixUserID3[m] = 1;
            eligibleUserID[m] =1;
            matrixNextParent[m] = 1;
            matrixNextParent1[m] = 1;
            matrixNextParent2[m] = 1;
            matrixNextParent3[m] = 1;
            matrixusersID[1].matrixcount[m]  = ownerWallet;
            matrixusersID[1].matrixcount1[m]  = ownerWallet;
            matrixusersID[1].matrixcount2[m]  = ownerWallet;
            matrixusersID[1].matrixcount3[m]  = ownerWallet;
            users[ownerWallet].recyclecount[m]=0;
        }

    }
}