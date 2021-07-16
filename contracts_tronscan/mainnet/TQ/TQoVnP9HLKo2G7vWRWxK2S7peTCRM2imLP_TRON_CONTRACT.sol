//SourceUnit: tron_contract.sol

pragma solidity 0.5.9;

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

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}
contract TRON_CONTRACT is Ownable {
    using SafeMath for uint256;
    address public matrixwallet;
    event signUpLevelEvent(address indexed user, address indexed referrer, uint _time);
    event buyNextLevelEvent(address indexed user, uint level, uint _time);
    event getMoneyForLevelEvent(address indexed user, address indexed referral, uint level, uint time);
    event lostMoneyForLevelEvent(address indexed user, address indexed referral, uint level, uint time);
    
    event Registration(string  member_name, string  sponcer_id,address indexed sender);
	event LevelUpgrade(string  member_name, string  current_level,string promoter,address indexed sender);
	event MatrixUpgrade(string  member_name, string  matrix,string  promoter,string payment_promoter,address indexed sender);

    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public POOL_PRICE;
    mapping (address => address) referrerAdd;
    mapping (address => address) uplineAdd;
    mapping (uint => address) referrerArr;
    mapping (uint => address) uplineArr;
    mapping (uint256 => address payable) public uplineAddress;
    mapping(uint => address[]) slotreferrals;
    uint public maxDownLimit = 2;
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint originalReferrer;
        uint directCount;
        address[] referral;
        mapping(uint => address[]) regUsers;
        mapping (uint => uint) levelExpired;
    }
    struct SuperStruct {
        bool isExist;
        uint id;
        address[] referral;
        mapping (uint => uint) levelExpired;
        mapping (uint => address) matrixcount;
        mapping (uint => address) parentmatrixAddress;
        mapping (uint => bool) matrixvalid;
        mapping (uint => address[]) matrixchild;
        mapping (uint => address[]) directchild;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userAddressByID;
    mapping (address => SuperStruct) public matrixusers;
    mapping (uint => SuperStruct) public matrixusersID;
    mapping (uint => address) public userList;
    mapping (address => uint) public userAddress;
    mapping (uint => address) public matricuserList;
    mapping (uint => bool) public userRefComplete;
    mapping (address => uint) public profitStat;
    mapping(uint => address[]) childAddresses;
    mapping(address => address[]) teammembers;
    mapping (uint => uint) matrixUserID;
    mapping (uint => uint) eligibleUserID;
    mapping (uint => uint) matrixNextParent;
    mapping (uint => uint) matrixallChildInc;
    uint[8] public levelStat;
    uint public currUserID = 0;
    uint refCompleteDepth = 1;
    uint public placeNextParent = 0;
    address public parentNewAddressNew;

    constructor(address _manager) public {
        owner = msg.sender;
        manager = _manager;
        ownerWallet = msg.sender;
        matrixwallet = _manager;
        parentNewAddressNew= address(0);


         LEVEL_PRICE[1]  =    500; 
         LEVEL_PRICE[2]  =   1000; 
         LEVEL_PRICE[3]  =   1500;
         LEVEL_PRICE[4]  =   3000; 
         LEVEL_PRICE[5]  =  5000; 
         LEVEL_PRICE[6]  =  10000; 
         LEVEL_PRICE[7]  =  25000; 
         LEVEL_PRICE[8]  = 15000; 
         LEVEL_PRICE[9]  = 8000; 
         LEVEL_PRICE[10]  = 4500; 
         LEVEL_PRICE[10]  = 2500;

         POOL_PRICE[1]  =   1200; 
         POOL_PRICE[2]  =  4000; 
         POOL_PRICE[3]  =  10000;
         POOL_PRICE[4]  = 25000;
         POOL_PRICE[5]  = 50000; 
         POOL_PRICE[6]  = 140000; 
         POOL_PRICE[7]  = 400000; 
         POOL_PRICE[8]  = 1000000; 
         POOL_PRICE[9]  = 3000000; 


        UserStruct memory userStruct;

        currUserID++;
        for(uint m=1;m<=5;m++){
            matrixUserID[m] = 1;
            eligibleUserID[m] =1;
            matrixNextParent[m] = 1;
            matrixusersID[1].matrixcount[m]  = ownerWallet;
        }

        placeNextParent++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID: 1,
            originalReferrer: 1,
            directCount: 0,
            referral : new address[](0)
        });

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
        userAddressByID[currUserID] = ownerWallet;
        userAddress[ownerWallet] = currUserID;

        for(uint l =1; l<9;l++){
            users[ownerWallet].levelExpired[l] = 77777777777;
            if(l<=5){
                matrixusers[ownerWallet].levelExpired[l] = 77777777777;
                matrixusers[ownerWallet].matrixvalid[l] = true;
            }
         }
    }


    function signupUser(address _referrer) private {
        require(!users[msg.sender].isExist, 'User exist');
        uint _referrerID;

        if (users[_referrer].isExist){
            _referrerID = users[_referrer].id;
        }
        uint originalReferrer = userAddress[_referrer];
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');
        if(users[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = users[findFreeReferrer(userAddressByID[_referrerID])].id;


        require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');

        UserStruct memory userStruct;

        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            originalReferrer : originalReferrer,
            directCount : 0,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;
        userAddress[msg.sender] = currUserID;
        userAddressByID[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now ;
        users[msg.sender].levelExpired[2] = 0;
        users[msg.sender].levelExpired[3] = 0;
        users[msg.sender].levelExpired[4] = 0;
        users[msg.sender].levelExpired[5] = 0;
        users[msg.sender].levelExpired[6] = 0;
        users[msg.sender].levelExpired[7] = 0;
        users[msg.sender].levelExpired[8] = 0;
        matrixusers[msg.sender].levelExpired[1] = 0;
        matrixusers[msg.sender].levelExpired[2] = 0;
        matrixusers[msg.sender].levelExpired[3] = 0;
        matrixusers[msg.sender].levelExpired[4] = 0;
        matrixusers[msg.sender].levelExpired[5] = 0;

        users[userAddressByID[_referrerID]].referral.push(msg.sender);
        users[userAddressByID[originalReferrer]].directCount++;

         directPayment(originalReferrer,1);

         for(uint m=1; m<=5;m++){
            matrixusers[msg.sender].matrixvalid[m] = false;
         }
         emit signUpLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function directPayment(uint referrerID,uint _level) internal {
         address referAddress = userAddressByID[referrerID];
         address(uint160(referAddress)).transfer(LEVEL_PRICE[_level]);
         profitStat[referAddress] += LEVEL_PRICE[_level];
    }


     function pushmatrixchild(uint _level,address matrixbuyer,address parentaddress) internal {
        if(matrixusers[parentaddress].matrixchild[_level].length <= 39){
         matrixusers[parentaddress].matrixchild[_level].push(matrixbuyer);
         address parentNewAddress = matrixusers[parentaddress].parentmatrixAddress[_level];
          if(parentNewAddress == ownerWallet){
              if(matrixusers[parentNewAddress].matrixchild[_level].length <= 39){
                 matrixusers[parentNewAddress].matrixchild[_level].push(matrixbuyer);
              }
          }else{
              if(parentNewAddress != parentNewAddressNew){
                  pushmatrixchild(_level,matrixbuyer,parentNewAddress);
              }
          }

        }
    }

    function buyGlobal(uint _level) private  {

        require(users[msg.sender].isExist, 'User not exist');

        require( _level>0 && _level<=5, 'Incorrect level');
        require(msg.value==POOL_PRICE[_level], 'Incorrect Value');
        require(matrixusers[msg.sender].matrixvalid[_level] == true,'You are not eligible to buy this package');

        matrixusers[msg.sender].levelExpired[_level] = now;

        for(uint l =_level-1; l>0; l-- ){
         require(matrixusers[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
        }

        matrixUserID[_level]++;
        matrixusersID[matrixUserID[_level]].matrixcount[_level]  = msg.sender;

        address topaddress = matrixusersID[matrixNextParent[_level]].matrixcount[_level];
        address eligibleaddress = matrixusersID[eligibleUserID[_level]].matrixcount[_level];

        matrixusers[topaddress].directchild[_level].push(msg.sender);

        matrixusers[msg.sender].parentmatrixAddress[_level] = topaddress;

        if(matrixusers[eligibleaddress].matrixchild[_level].length == 39 ){
            eligibleUserID[_level]++;
        }

        if(matrixusers[topaddress].directchild[_level].length == 3 ){
           matrixNextParent[_level]++;
        }

        pushmatrixchild(_level,msg.sender,topaddress);

        if(matrixusers[topaddress].directchild[_level].length <= 3 ){
              if(matrixusers[topaddress].directchild[_level].length <= 2 && matrixusers[ownerWallet].matrixchild[_level].length <= 12){
                   // payForMatrix(_level,matrixwallet);
                }else if(matrixusers[eligibleaddress].matrixchild[_level].length >12  && matrixusers[eligibleaddress].matrixchild[_level].length < 40){
                    if(matrixusers[topaddress].directchild[_level].length <= 2 ){
                        payForMatrix(_level,eligibleaddress);
                    }else{
                        payForMatrix(_level,topaddress);
                    }
                }else{
                    payForMatrix(_level,topaddress);
                }
        }
    }

    function getprofitAddress(uint level,address user, address profitaddress) internal {
        users[user].regUsers[level].push(profitaddress);
    }

    function payForMatrix(uint _level, address _user) internal {
         address(uint160(_user)).transfer(POOL_PRICE[_level]);
         profitStat[_user] += POOL_PRICE[_level];
    }


    function whogettingAmount(uint _level,address _regAddress) public view returns(address[] memory) {
        return users[_regAddress].regUsers[_level];
    }

    function getuplinerAddress(uint _level, address _user) private returns(address){
        address  uplinerAddress;
        for(uint u=1;u<= _level; u++){
             if(u== 1 && _level ==1){
              uplinerAddress = userList[users[_user].referrerID];
             }else{
                 if(u==1){
                         uplineArr[u] = userList[users[_user].referrerID];
                 }else{
                     if(u != _level){
                         uplineArr[u] = userList[users[uplineArr[u-1]].referrerID];
                     }
                     if(u == _level){
                         uplinerAddress =  userList[users[uplineArr[u-1]].referrerID];
                     }
                 }

             }
          }
        return uplinerAddress;
    }

    function payForLevel(uint _level, address _user,address _originaluser) internal {
        address originaluser = _originaluser;
        address referer;
        for(uint i=1;i<= _level; i++){
            if(i== 1 && _level ==1){
             referer = userAddressByID[users[_user].referrerID];
            }else{
                if(i==1){
                    referrerArr[i] = userAddressByID[users[_user].referrerID];
                }else{
                    if(i != _level){
                        referrerArr[i] = userAddressByID[users[referrerArr[i-1]].referrerID];
                    }
                    if(i == _level){
                        referer =  userAddressByID[users[referrerArr[i-1]].referrerID];
                    }
                }

            }
         }

         if(!users[referer].isExist){
            referer = userAddressByID[1];
          }
         if(_level >= 3){
            matrixusers[msg.sender].matrixvalid[_level-2] = true;
        }

        if(users[referer].levelExpired[_level] >= now ){

            uint sponcerId = users[_originaluser].originalReferrer;
            address sponcerAddress = userAddressByID[sponcerId];
            address(uint160(referer)).transfer(LEVEL_PRICE[_level].mul(80).div(100));
            address(uint160(sponcerAddress)).transfer(LEVEL_PRICE[_level].mul(20).div(100));
            profitStat[referer] += LEVEL_PRICE[_level].mul(80).div(100);
            profitStat[sponcerAddress] += LEVEL_PRICE[_level].mul(20).div(100);
            getprofitAddress(_level,_originaluser,referer);
            slotreferrals[_level].push(msg.sender);
            levelStat[_level-1]++;
            emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
        } else {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payForLevel(_level,referer,originaluser);
        }
    }

     function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < maxDownLimit) return _user;
        address[] memory referrals = new address[](500);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 500; i++) {
            if(users[referrals[i]].referral.length == maxDownLimit) {
                //if(i < 62) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
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

    function viewUserSponcer(address _user) public view returns(uint) {
        return users[_user].originalReferrer;
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

    function viewUserLevelExpired(address _user) public view returns(uint[8] memory levelExpired) {
        for (uint i = 0; i<8; i++) {
            if (now < users[_user].levelExpired[i+1]) {
                levelExpired[i] = users[_user].levelExpired[i+1].sub(now);
            }
        }
    }

    function viewUserLevelMatrixExpired(address _user) public view returns(uint[5] memory levelExpired) {
        for (uint i = 0; i<5; i++) {
            if (now < matrixusers[_user].levelExpired[i+1]) {
                levelExpired[i] = matrixusers[_user].levelExpired[i+1].sub(now);
            }
        }
    }

      function NewRegistration(string memory member_name, string memory sponcer_id,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		multisendTRX(_contributors,_balances);
		emit Registration(member_name, sponcer_id,msg.sender);
	}

	function buyLevel(string memory member_name, string memory current_level,string memory promoter,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		multisendTRX(_contributors,_balances);
		emit LevelUpgrade(member_name, current_level,promoter,msg.sender);
	}
	function buyMatrix(string memory member_name, string memory matrix,string memory promoter,string memory payment_promoter,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		multisendTRX(_contributors,_balances);
		emit MatrixUpgrade( member_name,  matrix, promoter,payment_promoter,msg.sender);
	
	}
	 function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
	

    function viewAllChildByuser(uint id) public view returns(address[] memory) {
        return childAddresses[id];
    }
    
     function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
    
    }

}