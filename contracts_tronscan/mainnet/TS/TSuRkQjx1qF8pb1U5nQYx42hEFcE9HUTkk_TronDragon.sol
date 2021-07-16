//SourceUnit: TronDragonFinal.sol

pragma solidity 0.5.10;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Ownable {

  address public owner;
  address public manager;
  address public roiaddress;
  address public ownerWallet;
  address public managerWallet1;
  address public managerWallet2;

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

}
contract TronDragon is Ownable {
    using SafeMath for uint256;
    event signUpLevelEvent(address indexed user, address indexed referrer, uint _time);
    event buyNextLevelEvent(address indexed user, uint level, uint _time);
    event getMoneyForLevelEvent(address indexed user, address indexed referral, uint level, uint time);
    event lostMoneyForLevelEvent(address indexed user, address indexed referral, uint level, uint time);
    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public POOL_PRICE;
    mapping (uint => uint) public ROI_PRICE;
    mapping (uint => address) referrerArr;
    mapping (uint => address) uplineArr;
    mapping(uint => address[]) slotreferrals;

    mapping(uint => address[]) snapreferal1;
    mapping(uint => address[]) snapreferal2;
    mapping(uint => address[]) snapreferal3;
    mapping(uint => address[]) snapreferal4;
    mapping(uint => address[]) snapreferal5;
    mapping(uint => address[]) snapreferal6;
    mapping(uint => address[]) snapreferal7;
    mapping(uint => address[]) snapreferal8;
    mapping(uint => address[]) snapreferal9;
    mapping(uint => address[]) snapreferal10;
    mapping(uint => address[]) snapreferal11;
    mapping(uint => address[]) snapreferal12;

    uint PERIOD_LENGTH = 365 days;
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping (uint => uint) levelExpired;
        mapping (uint => address[]) reBirthCountByLevel1;
        mapping(uint => address[]) regUsers;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint => bool) public userRefComplete;
    mapping (address => uint) public profitStat;
    uint[12] public levelStat;
    uint public currUserID = 0;
    uint refCompleteDepth = 1;
    uint public currentSnap1 = 1;
    uint public currentSnap2 = 2;
    uint public currentSnap3 = 3;
    uint public currentSnap4 = 4;
    uint public currentSnap5 = 5;
    uint public currentSnap6 = 6;
    uint public currentSnap7 = 7;
    uint public currentSnap8 = 8;
    uint public currentSnap9 = 9;
    uint public currentSnap10 = 10;
    uint public currentSnap11 = 11;
    uint public currentSnap12 = 12;

    constructor(address _manager,address _roiaddress,address companyWallet1,address companyWallet2) public {
        owner = msg.sender;
        manager = _manager;
        roiaddress = _roiaddress;
        ownerWallet = msg.sender;
        managerWallet1 = companyWallet1;
        managerWallet2 = companyWallet2;

        LEVEL_PRICE[1]  =    1500000000;
        LEVEL_PRICE[2]  =    2500000000;
        LEVEL_PRICE[3]  =    5000000000;
        LEVEL_PRICE[4]  =   10000000000;
        LEVEL_PRICE[5]  =   15000000000;
        LEVEL_PRICE[6]  =   25000000000;
        LEVEL_PRICE[7]  =   50000000000;
        LEVEL_PRICE[8]  =   75000000000;
        LEVEL_PRICE[9]  =  100000000000;
        LEVEL_PRICE[10] =  200000000000;
        LEVEL_PRICE[11] =  300000000000;
        LEVEL_PRICE[12] =  500000000000;


        POOL_PRICE[1]  =     600000000;
        POOL_PRICE[2]  =    1000000000;
        POOL_PRICE[3]  =    2000000000;
        POOL_PRICE[4]  =    4000000000;
        POOL_PRICE[5]  =    6000000000;
        POOL_PRICE[6]  =   10000000000;
        POOL_PRICE[7]  =   20000000000;
        POOL_PRICE[8]  =   30000000000;
        POOL_PRICE[9]  =   40000000000;
        POOL_PRICE[10] =   90000000000;
        POOL_PRICE[11] =  140000000000;
        POOL_PRICE[12] =  250000000000;


        ROI_PRICE[1]  =     600000000;
        ROI_PRICE[2]  =    1000000000;
        ROI_PRICE[3]  =    2000000000;
        ROI_PRICE[4]  =    4000000000;
        ROI_PRICE[5]  =    6000000000;
        ROI_PRICE[6]  =   10000000000;
        ROI_PRICE[7]  =   20000000000;
        ROI_PRICE[8]  =   30000000000;
        ROI_PRICE[9]  =   40000000000;
        ROI_PRICE[10] =   85000000000;
        ROI_PRICE[11] =  130000000000;
        ROI_PRICE[12] =  200000000000;
        UserStruct memory userStruct;
        currUserID++;
        uint256 refererIds = 0;
        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : refererIds,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        for(uint m=1;m<=12;m++){
            slotreferrals[m].push(ownerWallet);
            users[ownerWallet].levelExpired[m] = 77777777777;
        }
        userList[currUserID] = ownerWallet;
    }

    function applyInitial1(address _address1) onlyOwner external{
        UserStruct memory userStruct;
         currUserID++;
          userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 1,
            referral : new address[](0)
         });
         users[_address1] = userStruct;

         for(uint m=1;m<=12;m++){
            slotreferrals[m].push(_address1);
            snapreferal1[m].push(_address1);
            snapreferal2[m].push(_address1);
            snapreferal3[m].push(_address1);
            users[_address1].levelExpired[m] = 77777777777;
        }

    }

    function applyInitial2(address _address1) onlyOwner external{
         for(uint m=1;m<=12;m++){
            snapreferal4[m].push(_address1);
            snapreferal5[m].push(_address1);
            snapreferal6[m].push(_address1);
        }
    }

    function applyInitial3(address _address1) onlyOwner external{
         for(uint m=1;m<=12;m++){
            snapreferal7[m].push(_address1);
            snapreferal8[m].push(_address1);
            snapreferal9[m].push(_address1);
        }
    }

    function applyInitial4(address _address1) onlyOwner external{
         for(uint m=1;m<=12;m++){
            snapreferal10[m].push(_address1);
            snapreferal11[m].push(_address1);
            snapreferal12[m].push(_address1);
        }
    }

    function getslot(uint pid) public view returns(address[] memory) {
        return slotreferrals[pid];
    }

    function getprofitAddress(uint _level,address _parentAddress,address _poolAddress, address _regAddress) internal {
       users[_regAddress].regUsers[_level].push(_parentAddress);
       users[_regAddress].regUsers[_level].push(_poolAddress);
        if(_poolAddress!= manager && _poolAddress!= managerWallet1 && _poolAddress!= managerWallet2){
           users[_poolAddress].reBirthCountByLevel1[_level].push(_regAddress);
        }
    }

    function whogettingAmount(uint _level,address _regAddress) public view returns(address[] memory) {
        return users[_regAddress].regUsers[_level];
    }

     function rebirthcount(uint _level,address _regAddress) public view returns(address[] memory) {
          return users[_regAddress].reBirthCountByLevel1[_level];
     }

    function removeSlotmember(uint level,address _poolAddress) internal{
         uint countVal = users[_poolAddress].reBirthCountByLevel1[level].length;
         if(countVal >= 36){
             for(uint l = 3; l< slotreferrals[level].length-1; l++){
              slotreferrals[level][l] = slotreferrals[level][l+1];
             }
             delete slotreferrals[level][slotreferrals[level].length-1];
             slotreferrals[level].length--;
         }


    }


    function autopoolpay(uint level,address workingparent,address registerUser) internal
    {
        address poolreferer;
        if(level==1){
          poolreferer = snapreferal1[currentSnap1][0];
          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);
          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint i = 0; i<snapreferal1[currentSnap1].length-1; i++){
          snapreferal1[currentSnap1][i] = snapreferal1[currentSnap1][i+1];
         }

         delete snapreferal1[currentSnap1][snapreferal1[currentSnap1].length-1];
         snapreferal1[currentSnap1].length--;
         if(snapreferal1[currentSnap1].length==0){
             if(currentSnap1<12){
                 currentSnap1++;
             }else{
                  currentSnap1 =level;
                  for(uint s=1;s<=12;s++){
                      snapreferal1[s] = slotreferrals[s];
                  }
             }

         }
         removeSlotmember(level,poolreferer);
        }

         if(level==2){

          poolreferer = snapreferal2[currentSnap2][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint j = 0; j<snapreferal2[currentSnap2].length-1; j++){
          snapreferal2[currentSnap2][j] = snapreferal2[currentSnap2][j+1];
         }

         delete snapreferal2[currentSnap2][snapreferal2[currentSnap2].length-1];
         snapreferal2[currentSnap2].length--;

         if(snapreferal2[currentSnap2].length==0){

             if(currentSnap2<12){
                 currentSnap2++;
             }else{
                 currentSnap2 =level;
                  for(uint k=level;k<=12;k++){
                      snapreferal2[k] = slotreferrals[k];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==3){

          poolreferer = snapreferal3[currentSnap3][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint l = 0; l<snapreferal3[currentSnap3].length-1; l++){
          snapreferal3[currentSnap3][l] = snapreferal3[currentSnap3][l+1];
         }

         delete snapreferal3[currentSnap3][snapreferal3[currentSnap3].length-1];
         snapreferal3[currentSnap3].length--;

         if(snapreferal3[currentSnap3].length==0){

             if(currentSnap3<12){
                 currentSnap3++;
             }else{
                 currentSnap3 =level;
                  for(uint z=level;z<=12;z++){
                      snapreferal3[z] = slotreferrals[z];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }



         if(level==4){

          poolreferer = snapreferal4[currentSnap4][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint c = 0; c<snapreferal4[currentSnap4].length-1; c++){
          snapreferal4[currentSnap4][c] = snapreferal4[currentSnap4][c+1];
         }

         delete snapreferal4[currentSnap4][snapreferal4[currentSnap4].length-1];
         snapreferal4[currentSnap4].length--;

         if(snapreferal4[currentSnap4].length==0){

             if(currentSnap4<12){
                 currentSnap4++;
             }else{
                 currentSnap4 =level;
                 for(uint v=level;v<=12;v++){
                      snapreferal4[v] = slotreferrals[v];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==5){

          poolreferer = snapreferal5[currentSnap5][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint b = 0; b<snapreferal5[currentSnap5].length-1; b++){
          snapreferal5[currentSnap5][b] = snapreferal5[currentSnap5][b+1];
         }

         delete snapreferal5[currentSnap5][snapreferal5[currentSnap5].length-1];
         snapreferal5[currentSnap5].length--;

         if(snapreferal5[currentSnap5].length==0){

             if(currentSnap5<12){
                 currentSnap5++;
             }else{
                 currentSnap5 =level;
                 for(uint n=level;n<=12;n++){
                      snapreferal5[n] = slotreferrals[n];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==6){

          poolreferer = snapreferal6[currentSnap6][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint f = 0; f<snapreferal6[currentSnap6].length-1; f++){
          snapreferal6[currentSnap6][f] = snapreferal6[currentSnap6][f+1];
         }

         delete snapreferal6[currentSnap6][snapreferal6[currentSnap6].length-1];
         snapreferal6[currentSnap6].length--;

         if(snapreferal6[currentSnap6].length==0){

             if(currentSnap6<12){
                 currentSnap6++;
             }else{
                 currentSnap6 =level;
                 for(uint g=level;g<=12;g++){
                      snapreferal6[g] = slotreferrals[g];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }



         if(level==7){

          poolreferer = snapreferal7[currentSnap7][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint h = 0; h<snapreferal7[currentSnap7].length-1; h++){
          snapreferal7[currentSnap7][h] = snapreferal7[currentSnap7][h+1];
         }

         delete snapreferal7[currentSnap7][snapreferal7[currentSnap7].length-1];
         snapreferal7[currentSnap7].length--;

         if(snapreferal7[currentSnap7].length==0){

             if(currentSnap7<12){
                 currentSnap7++;
             }else{
                 currentSnap7 =level;
                 for(uint p=level;p<=12;p++){
                      snapreferal7[p] = slotreferrals[p];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==8){

          poolreferer = snapreferal8[currentSnap8][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint w = 0; w<snapreferal8[currentSnap8].length-1; w++){
          snapreferal8[currentSnap8][w] = snapreferal8[currentSnap8][w+1];
         }

         delete snapreferal8[currentSnap8][snapreferal8[currentSnap8].length-1];
         snapreferal8[currentSnap8].length--;

         if(snapreferal8[currentSnap8].length==0){

             if(currentSnap8<12){
                 currentSnap8++;
             }else{
                 currentSnap8 =level;
                 for(uint e=level;e<=12;e++){
                      snapreferal8[e] = slotreferrals[e];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==9){

          poolreferer = snapreferal9[currentSnap9][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint r = 0; r<snapreferal9[currentSnap9].length-1; r++){
          snapreferal9[currentSnap9][r] = snapreferal9[currentSnap9][r+1];
         }

         delete snapreferal9[currentSnap9][snapreferal9[currentSnap9].length-1];
         snapreferal9[currentSnap9].length--;

         if(snapreferal9[currentSnap9].length==0){

             if(currentSnap9<12){
                 currentSnap9++;
             }else{
                 currentSnap9 =level;
                 for(uint t=level;t<=12;t++){
                      snapreferal9[t] = slotreferrals[t];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }

         if(level==10){

          poolreferer = snapreferal10[currentSnap10][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint y = 0; y<snapreferal10[currentSnap10].length-1; y++){
          snapreferal10[currentSnap10][y] = snapreferal10[currentSnap10][y+1];
         }

         delete snapreferal10[currentSnap10][snapreferal10[currentSnap10].length-1];
         snapreferal10[currentSnap10].length--;

         if(snapreferal10[currentSnap10].length==0){

             if(currentSnap10<12){
                 currentSnap10++;
             }else{
                 currentSnap10 =level;
                 for(uint u=level;u<=12;u++){
                      snapreferal10[u] = slotreferrals[u];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==11){

          poolreferer = snapreferal11[currentSnap11][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint d = 0; d<snapreferal11[currentSnap11].length-1; d++){
          snapreferal11[currentSnap11][d] = snapreferal11[currentSnap11][d+1];
         }

         delete snapreferal11[currentSnap11][snapreferal11[currentSnap11].length-1];
         snapreferal11[currentSnap11].length--;

         if(snapreferal11[currentSnap11].length==0){

             if(currentSnap11<12){
                 currentSnap11++;
             }else{
                 currentSnap11 =level;
                 for(uint aa=level;aa<=12;aa++){
                      snapreferal11[aa] = slotreferrals[aa];
                  }
             }

         }
         removeSlotmember(level,poolreferer);

        }


         if(level==12){

          poolreferer = snapreferal12[currentSnap12][0];

          address(uint160(poolreferer)).transfer(POOL_PRICE[level]);

          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += POOL_PRICE[level];

         for(uint bb = 0; bb<snapreferal12[currentSnap12].length-1; bb++){
          snapreferal12[currentSnap12][bb] = snapreferal12[currentSnap12][bb+1];
         }

         delete snapreferal12[currentSnap12][snapreferal12[currentSnap12].length-1];
         snapreferal12[currentSnap12].length--;

         if(snapreferal12[currentSnap12].length==0){
             currentSnap12 =level;
             for(uint cc=level;cc<=12;cc++){
                  snapreferal12[cc] = slotreferrals[cc];
             }

          }

        }
        removeSlotmember(level,poolreferer);
    }

    function signupUser(address _referrer) public payable {
        require(!users[msg.sender].isExist, 'User exist');

        uint _referrerID;

        if (users[_referrer].isExist){
            _referrerID = users[_referrer].id;
        } else if (_referrer == address(0)) {
            _referrerID = findFirstFreeReferrer();
            refCompleteDepth = _referrerID;
        } else {
            revert('Incorrect referrer');
        }

        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');

        require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');

        UserStruct memory userStruct;

        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
        users[msg.sender].levelExpired[2] = 0;
        users[msg.sender].levelExpired[3] = 0;
        users[msg.sender].levelExpired[4] = 0;
        users[msg.sender].levelExpired[5] = 0;
        users[msg.sender].levelExpired[6] = 0;
        users[msg.sender].levelExpired[7] = 0;
        users[msg.sender].levelExpired[8] = 0;
        users[msg.sender].levelExpired[9] = 0;
        users[msg.sender].levelExpired[10] = 0;
        users[msg.sender].levelExpired[11] = 0;
        users[msg.sender].levelExpired[12] = 0;

        users[userList[_referrerID]].referral.push(msg.sender);
        payForLevel(1, msg.sender);
        emit signUpLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist');

        require( _level>0 && _level<=12, 'Incorrect level');

        if(_level == 1){

            require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        } else {
            require(msg.value==LEVEL_PRICE[_level], 'Incorrect Value');

            for(uint l =_level-1; l>0; l-- ){
                require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            }

            if(users[msg.sender].levelExpired[_level] == 0){
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            } else {
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
            }
        }


        payForLevel(_level, msg.sender);
        emit buyNextLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint _level, address _user) internal {
        address referer;

        for(uint i=1;i<= _level; i++){
            if(i== 1 && _level ==1){
             referer = userList[users[_user].referrerID];
            }else{
                if(i==1){
                    referrerArr[i] = userList[users[_user].referrerID];
                }else{
                    if(i != _level){
                        referrerArr[i] = userList[users[referrerArr[i-1]].referrerID];
                    }
                    if(i == _level){
                        referer =  userList[users[referrerArr[i-1]].referrerID];
                    }
                }

            }
         }

        if(!users[referer].isExist){
            referer = userList[1];
        }

        if(users[referer].levelExpired[_level] >= now ){
            address(uint160(referer)).transfer(LEVEL_PRICE[_level]-POOL_PRICE[_level]-ROI_PRICE[_level]);
            address(uint160(roiaddress)).transfer(ROI_PRICE[_level]);
            profitStat[referer] += LEVEL_PRICE[_level]-POOL_PRICE[_level]-ROI_PRICE[_level];
            slotreferrals[_level].push(msg.sender);
            levelStat[_level-1]++;
            autopoolpay(_level,referer,msg.sender);
            emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
        } else {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            payForLevel(_level,referer);
        }

    }

    function findFirstFreeReferrer() public view returns(uint) {
        for(uint i = refCompleteDepth; i < 500+refCompleteDepth; i++) {
            if (!userRefComplete[i]) {
                return i;
            }
        }
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }


    function withdrawSafe(uint amount) onlyOwner external {
        uint finalamount = amount * 1000000;
        address(uint160(owner)).transfer(finalamount);
     }

     function transfertoUser(uint amount,address useraddress) onlyOwner external {
        uint finalamount = amount * 1000000;
        address(uint160(useraddress)).transfer(finalamount);
     }

  function getUplineUser(uint _level,address _user) public onlyOwner returns(address) {
        address uplinereferer;
      for(uint u=1;u<= _level; u++){
             if(u== 1 && _level ==1){
              uplinereferer = userList[users[_user].referrerID];
             }else{
                 if(u==1){
                     uplineArr[u] = userList[users[_user].referrerID];
                 }else{
                     if(u != _level){
                         uplineArr[u] = userList[users[uplineArr[u-1]].referrerID];
                     }
                     if(u == _level){
                         uplinereferer =  userList[users[uplineArr[u-1]].referrerID];
                     }
                 }

             }
          }
        return uplinereferer;
    }

    function viewUserLevelExpired(address _user) public view returns(uint[12] memory levelExpired) {
        for (uint i = 0; i<12; i++) {
            if (now < users[_user].levelExpired[i+1]) {
                levelExpired[i] = users[_user].levelExpired[i+1].sub(now);
            }
        }
    }

}