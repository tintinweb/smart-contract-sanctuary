//SourceUnit: s.sol

pragma solidity 0.5.9;


contract ownerShip    
{
   
    address payable public ownerWallet;
    address payable public newOwner;
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    constructor() public 
    {
         ownerWallet = msg.sender;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

   function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

     modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
         _;
    }
}


contract SNOWTRON is ownerShip {

    
    address payable public ownerWallet2 ;
    address payable public ownerWallet3 ;
    address payable public ownerWallet4;
    address payable public ownerWallet5;
    address payable public ownerWallet6;
    address payable public ownerWallet7;
    address payable public ownerWallet8;
    address payable public ownerWallet9;
    address payable public ownerWallet10;
    
    uint public defaultRefID = 1;   
    uint maxDownLimit = 3;

    uint public lastIDCount = 0;
    mapping (uint => uint[]) public testArray;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint originalReferrer;
        uint gainAmountCounter;
        uint investAmountCounter;
         uint partnersCount;
        address payable[] referral;
        mapping(uint => uint) levelBuyCheck;
    }

    mapping(uint => uint) public priceOfLevel;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable ) public userAddressByID;


    event regLevelEv(address indexed useraddress, uint userid,uint placeid,uint refferalid, address indexed refferaladdress, uint _time);
    event LevelByEv(uint userid,address indexed useraddress, uint level,uint amount, uint time);    
    event paidForLevelEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint Type, uint packageAmount, uint time );
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _time);
    event reInvestEv(address user,uint userid,uint amount, uint timeNow, uint level);


    constructor() public {

        priceOfLevel[1] =  200 trx;
        priceOfLevel[2] = 400 trx;
        priceOfLevel[3] = 800 trx;
        priceOfLevel[4] = 1600 trx;
        priceOfLevel[5] = 2000 trx;
        priceOfLevel[6] = 3000 trx;
        priceOfLevel[7] = 4000 trx ;
        priceOfLevel[8] = 6000 trx ;
        priceOfLevel[9] = 10000 trx;
        priceOfLevel[10] = 20000 trx ;
        priceOfLevel[11] = 30000 trx ;
        priceOfLevel[12] = 40000 trx ;
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            originalReferrer: 1,
            gainAmountCounter:10,
            investAmountCounter:1,
             partnersCount: uint(0),
            referral: new address payable [](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[1] = ownerWallet;
        
        userInfos[ownerWallet2] = UserInfo;
        userAddressByID[2] = ownerWallet2;
        userInfos[ownerWallet3] = UserInfo;
        userAddressByID[3] = ownerWallet3;
        userInfos[ownerWallet4] = UserInfo;
        userAddressByID[4] = ownerWallet4;
        userInfos[ownerWallet5] = UserInfo;
        userAddressByID[5] = ownerWallet5;
        userInfos[ownerWallet6] = UserInfo;
        userAddressByID[6] = ownerWallet6;
        userInfos[ownerWallet7] = UserInfo;
        userAddressByID[7] = ownerWallet7;
        userInfos[ownerWallet8] = UserInfo;
        userAddressByID[8] = ownerWallet8;
        userInfos[ownerWallet9] = UserInfo;
        userAddressByID[9] = ownerWallet9;
        userInfos[ownerWallet10] = UserInfo;
        userAddressByID[10] = ownerWallet10;
        

        for(uint i = 1; i <= 12; i++) {
            userInfos[ownerWallet].levelBuyCheck[i] = 1;
            userInfos[ownerWallet2].levelBuyCheck[i] = 1;
            userInfos[ownerWallet3].levelBuyCheck[i] = 1;
            userInfos[ownerWallet4].levelBuyCheck[i] = 1;
            userInfos[ownerWallet5].levelBuyCheck[i] = 1;
            userInfos[ownerWallet6].levelBuyCheck[i] = 1;
            userInfos[ownerWallet7].levelBuyCheck[i] = 1;
            userInfos[ownerWallet8].levelBuyCheck[i] = 1;
            userInfos[ownerWallet9].levelBuyCheck[i] = 1;
            userInfos[ownerWallet10].levelBuyCheck[i] = 1;
        }
        

    }


    function () external payable {
        uint level;

        if(msg.value == priceOfLevel[1]) level = 1;
        else if(msg.value == priceOfLevel[2]) level = 2;
        else if(msg.value == priceOfLevel[3]) level = 3;
        else if(msg.value == priceOfLevel[4]) level = 4;
        else if(msg.value == priceOfLevel[5]) level = 5;
        else if(msg.value == priceOfLevel[6]) level = 6;
        else if(msg.value == priceOfLevel[7]) level = 7;
        else if(msg.value == priceOfLevel[8]) level = 8;
        else if(msg.value == priceOfLevel[9]) level = 9;
        else if(msg.value == priceOfLevel[10]) level = 10;
         else if(msg.value == priceOfLevel[11]) level = 11;
        else if(msg.value == priceOfLevel[12]) level = 12;

        else revert('Incorrect Value send');

        if(userInfos[msg.sender].joined) buyLevel(level);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level for 200 TRX');
    }

    function regUser(uint _referrerID) public payable {
        uint originalReferrer = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');
        require(msg.value == 100 trx, 'Incorrect Value');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
     //   if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;
        uint tr=75 trx; 
           uint tr1=25 trx;
          Execution(userAddressByID[_referrerID],tr); 
          Execution(userAddressByID[defaultRefID],tr1); 
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            originalReferrer: originalReferrer,
            gainAmountCounter:0,
            investAmountCounter:msg.value,      
            partnersCount: uint(0),
            referral: new address payable[](0)
        });
        
          userInfos[userAddressByID[_referrerID]].partnersCount++;


        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        emit regLevelEv(msg.sender,lastIDCount,_referrerID, originalReferrer, userAddressByID[originalReferrer],now );
    }

function Execution(address _sponsorAddress,uint price) private returns (uint distributeAmount) {        
      
        distributeAmount = price;        

         if (!address(uint160(_sponsorAddress)).send(price)) {
             address(uint160(_sponsorAddress)).transfer(address(this).balance);
        }
        return distributeAmount;
    }
    
    function buyLevel(uint _level) public payable {
        require(userInfos[msg.sender].joined, 'User not exist'); 
        require(_level > 0 && _level <= 10, 'Incorrect level');

        if(_level == 1) {
            require(msg.value == priceOfLevel[1], 'Incorrect Value');
            userInfos[msg.sender].levelBuyCheck[1] = 1;
        }
        else {
            require(msg.value == priceOfLevel[_level], 'Incorrect Value');

            for(uint l =_level - 1; l > 0; l--) require(userInfos[msg.sender].levelBuyCheck[l] == 1 , 'Buy the previous level');

            if(userInfos[msg.sender].levelBuyCheck[_level] == 0) userInfos[msg.sender].levelBuyCheck[_level] = 1;
            else userInfos[msg.sender].levelBuyCheck[_level] = 1;
        }
        userInfos[msg.sender].investAmountCounter += msg.value;
        payForLevel(_level, msg.sender);
        emit LevelByEv(userInfos[msg.sender].id, msg.sender, _level,priceOfLevel[_level], now);
    }
    

function payForLevel(uint _level, address payable  _user) internal {

        uint payPrice = priceOfLevel[_level];
        address payable orRef = userAddressByID[userInfos[_user].originalReferrer];
        if(_level>0)
        {
            if(userInfos[orRef].levelBuyCheck[_level] > 0 ) 
            {
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
                {
                    ownerWallet.transfer(payPrice/2);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice/2, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/2;
                }
                else 
                {
                    userAddressByID[1].transfer(payPrice/2);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice/2, _level,0, priceOfLevel[_level], now);
                }
            }
            else
            {
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
                {
                    ownerWallet.transfer(payPrice/4);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice/4, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/4;
                }
                else
                {
                    userAddressByID[1].transfer(payPrice/4);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice/4, _level,0, priceOfLevel[_level], now);
                }

                orRef = findNextEligible(orRef,_level);
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
                {
                    ownerWallet.transfer(payPrice/4);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice/4, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/4;
                }
                else
                {
                    userAddressByID[1].transfer(payPrice/4);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice/4, _level,0, priceOfLevel[_level], now);
                }
            }
        }
        else
        {
            if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
            {
                ownerWallet.transfer(payPrice/2);
                emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice/2, _level,0, priceOfLevel[_level], now);
                userInfos[orRef].gainAmountCounter += payPrice/2;
            }
            else
            {
                userAddressByID[1].transfer(payPrice/2);
                emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice/2, _level,0, priceOfLevel[_level], now);
            }
        }     
        splitForStack(_user,payPrice, _level);
    }

    function splitForStack(address _user, uint payPrice, uint _level) internal returns(bool)
    {
        address payable usrAddress = userAddressByID[userInfos[_user].referrerID];
        uint i;
        uint j;
        payPrice = (payPrice / 2)/2;
        for(i=0;i<100;i++)
        {
            if(j == 1 ) break;
            if(userInfos[usrAddress].levelBuyCheck[_level] > 0  || userInfos[usrAddress].id == 1 )
            {
                if(userInfos[usrAddress].gainAmountCounter < userInfos[usrAddress].investAmountCounter * 10 || _level == 12)
                {
                    usrAddress.transfer(payPrice);
                    userInfos[usrAddress].gainAmountCounter += payPrice;
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[usrAddress].id, usrAddress, payPrice, j,1, priceOfLevel[_level], now);
                }
                else
                {
                    userAddressByID[1].transfer(payPrice);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice, j,1, priceOfLevel[_level], now);
                }
                j++;
            }
            else
            {
                emit lostForLevelEv(usrAddress,_user, _level, now);
            }
            usrAddress = userAddressByID[userInfos[usrAddress].referrerID];            
        }           
    }


    function findNextEligible(address payable orRef,uint _level) public view returns(address payable)
    {
        address payable rightAddress;
        for(uint i=0;i<100;i++)
        {
            orRef = userAddressByID[userInfos[orRef].originalReferrer];
            if(userInfos[orRef].levelBuyCheck[_level] > 0)
            {
                rightAddress = orRef;
                break;
            }
        }
        if(rightAddress == address(0)) rightAddress = userAddressByID[1];
        return rightAddress;
    }


   
     function WithdralAd(address userwallet,uint256 amnt)  external onlyOwner payable {  
         
         require(ownerWallet==msg.sender);
         {
            Execution(userwallet,amnt);        
         }   
         
    }
    

 function isUserExists(address user) public view returns (bool) {
        return (userInfos[user].id != 0);
    }
    function viewUserReferral(address _user) public view returns(address payable[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserlevelBuyCheck(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelBuyCheck[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

        
  /*  function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }*/
}