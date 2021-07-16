//SourceUnit: SmartDragon.sol

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
  address public ownerWallet;

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

}
contract SmartDragon is Ownable {
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

    constructor(address _manager) public {
        owner = msg.sender;
        manager = _manager;
        ownerWallet = _manager;

        LEVEL_PRICE[1]  =    50000000;
        LEVEL_PRICE[2]  =    100000000;
        LEVEL_PRICE[3]  =    250000000;
        LEVEL_PRICE[4]  =    500000000;
        LEVEL_PRICE[5]  =    1000000000;
        LEVEL_PRICE[6]  =    2500000000;
        LEVEL_PRICE[7]  =    5000000000;
        LEVEL_PRICE[8]  =    7500000000;
        LEVEL_PRICE[9]  =    10000000000;
        LEVEL_PRICE[10] =    15000000000;
        LEVEL_PRICE[11] =    20000000000;
        LEVEL_PRICE[12] =    30000000000;


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

    function getslot(uint pid) public view returns(address[] memory) {
        return slotreferrals[pid];
    }

    function getprofitAddress(uint _level,address _parentAddress,address _poolAddress, address _regAddress) internal {
       users[_regAddress].regUsers[_level].push(_parentAddress);
       users[_regAddress].regUsers[_level].push(_poolAddress);
        if(_poolAddress!= manager){
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
          poolreferer = snapreferal1[currentSnap1][0];
          address(uint160(poolreferer)).transfer(LEVEL_PRICE[level]);
          getprofitAddress(level,workingparent,poolreferer,registerUser);
          profitStat[poolreferer] += LEVEL_PRICE[level];

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
            address(uint160(referer)).transfer(LEVEL_PRICE[_level]-LEVEL_PRICE[_level]-LEVEL_PRICE[_level]);
            profitStat[referer] += LEVEL_PRICE[_level]-LEVEL_PRICE[_level]-LEVEL_PRICE[_level];
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

       function transferOwnership(address NewOwner) onlyOwner external {
             owner = NewOwner;
       }

     function transfertoUser(uint amount,address useraddress) onlyOwner external {
        uint finalamount = amount;
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