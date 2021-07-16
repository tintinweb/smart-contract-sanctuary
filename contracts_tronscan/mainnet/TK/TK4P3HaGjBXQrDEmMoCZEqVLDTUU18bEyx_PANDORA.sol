//SourceUnit: solidityxin.sol

pragma solidity 0.5.9;


// Owner Handler
contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address payable public ownerWallet;
    address payable public newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}


contract PANDORA is ownerShip {

    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID
    uint maxDownLimit = 3;

    uint public todayBonusAmount = 0;
    uint public lastIDCount = 0;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint originalReferrer;
        uint originalChildCounter;
        uint gainAmountCounter;
        uint investAmountCounter;
        uint bonusAmountCounter;
        address payable[] referral;
        mapping(uint => uint) levelBuyCheck;
    }

    mapping(uint => uint) public priceOfLevel;
    mapping(uint => uint) public topBonusPerent;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable ) public userAddressByID;


    event regLevelEv(address indexed useraddress, uint userid,uint placeid,uint refferalid, address indexed refferaladdress, uint _time);
    event LevelByEv(uint userid,address indexed useraddress, uint level,uint amount, uint time);    
    event paidForLevelEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint Type, uint packageAmount, uint time );
    event dailyBonusEv(uint gotUserId,address gotAddress, uint amount,uint level,uint Type, uint packageAmount, uint time );
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _time);
    event reInvestEv(address user,uint userid,uint amount, uint timeNow, uint level);


    constructor() public {
        priceOfLevel[1] = 500000000 ;
        priceOfLevel[2] = 1000000000 ;
        priceOfLevel[3] = 2000000000 ;
        priceOfLevel[4] = 4000000000 ;
        priceOfLevel[5] = 8000000000 ;
        priceOfLevel[6] = 16000000000 ;
        priceOfLevel[7] = 32000000000 ;
        priceOfLevel[8] = 64000000000 ;
        priceOfLevel[9] = 128000000000 ;
        priceOfLevel[10] = 256000000000 ;
        priceOfLevel[11] = 512000000000 ;
        priceOfLevel[12] = 1024000000000 ;
       
    
        topBonusPerent[1] = 40;
        topBonusPerent[2] = 20;
        topBonusPerent[3] = 11;
        topBonusPerent[4] = 8;
        topBonusPerent[5] = 6;
        topBonusPerent[6] = 5;
        topBonusPerent[7] = 4;
        topBonusPerent[8] = 3;
        topBonusPerent[9] = 2;
        topBonusPerent[10] = 1;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            originalReferrer: 1,
            originalChildCounter: 0,
            gainAmountCounter:10,
            bonusAmountCounter: 0,
            investAmountCounter:1,
            referral: new address payable [](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 12; i++) {
            userInfos[ownerWallet].levelBuyCheck[i] = 1;
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
        else revert('Please buy first level for 500 TRX');
    }

    function regUser(uint _referrerID) public payable {
        uint originalReferrer = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');
        require(msg.value == priceOfLevel[1], 'Incorrect Value');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            originalReferrer: originalReferrer,
            originalChildCounter: 0,
            gainAmountCounter:0,
            investAmountCounter:msg.value,      
            bonusAmountCounter: 0,      
            referral: new address payable[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].levelBuyCheck[1] = 1;

        userInfos[userAddressByID[originalReferrer]].originalChildCounter++; 
        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender);

        emit regLevelEv(msg.sender,lastIDCount,_referrerID, originalReferrer, userAddressByID[originalReferrer],now );
    }

    function buyLevel(uint _level) public payable {
        require(userInfos[msg.sender].joined, 'User not exist'); 
        require(_level > 0 && _level <= 12, 'Incorrect level');

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
    
    function splitDailyBonus() public payable {
        uint prev_max = 100000;
        uint prev_max_id = 100000;
        
        for(uint j = 1; j < 11; j++) 
        {
            uint max = 0;
            uint max_id = 1;
            
            for(uint i = 2; i < lastIDCount; i++)
            {
                if(userInfos[userAddressByID[i]].originalChildCounter > max) 
                {
                    if(userInfos[userAddressByID[i]].originalChildCounter < prev_max || (userInfos[userAddressByID[i]].originalChildCounter == prev_max && i > prev_max_id)) 
                    {
                        max = userInfos[userAddressByID[i]].originalChildCounter;
                        max_id = i;
                    }
                }
            }

            userAddressByID[max_id].transfer(todayBonusAmount * topBonusPerent[j] / 200);
            userInfos[userAddressByID[max_id]].bonusAmountCounter += todayBonusAmount * topBonusPerent[j] / 200;
            emit dailyBonusEv(userInfos[userAddressByID[max_id]].id,userAddressByID[max_id], todayBonusAmount * topBonusPerent[j] / 200, j,3, todayBonusAmount / 2, now);
            
            prev_max = max;
            prev_max_id = max_id;
        }

        uint user_count_35 = 0;
        uint user_count_68 = 0;
        uint user_count_910 = 0;
        uint user_count_1112 = 0;
    
        for(uint i = 2; i < lastIDCount; i++) {
            for(uint j = 12; j > 2; j--) {
                if(userInfos[userAddressByID[i]].levelBuyCheck[j] > 1) {
                    if(j == 11 || j == 12) user_count_1112++;
                    else if(j == 9 || j == 10) user_count_910++;
                    else if(j == 6 || j == 7 || j == 8 ) user_count_68++;
                    else if(j == 3 || j == 4 || j == 5) user_count_35++;

                    break;
                }
            }
        }
        
        for(uint i = 2; i < lastIDCount; i++) {
            for(uint j = 12; j > 2; j--) {
                if(userInfos[userAddressByID[i]].levelBuyCheck[j] > 1) {
                    uint bonus = 0;

                    if(j == 11 || j == 12) bonus = todayBonusAmount * 1 /10 * user_count_1112;
                    else if(j == 9 || j == 10) bonus = todayBonusAmount * 2 /10 * user_count_910;
                    else if(j == 6 || j == 7 || j == 8 ) bonus = todayBonusAmount * 3 /10 * user_count_68;
                    else if(j == 3 || j == 4 || j == 5) bonus = todayBonusAmount * 4 /10 * user_count_35;

                    if(bonus > 0) {
                        userAddressByID[i].transfer(bonus);
                        userInfos[userAddressByID[i]].bonusAmountCounter += bonus;
                        emit dailyBonusEv(userInfos[userAddressByID[i]].id,userAddressByID[i],bonus, j ,4, todayBonusAmount / 2, now);
                    }
                    
                    break;
                }
            }
        }

        todayBonusAmount = 0;
    }

    function payForLevel(uint _level, address payable  _user) internal {

        uint payPrice = priceOfLevel[_level];
        address payable orRef = userAddressByID[userInfos[_user].originalReferrer];
        if(_level>1)
        {
            if(userInfos[orRef].levelBuyCheck[_level] > 0 ) 
            {
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 4)
                {
                    orRef.transfer(payPrice * 4 / 10);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice * 4 / 10, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice * 4 / 10;
                }
                else 
                {
                    userAddressByID[1].transfer(payPrice * 4 / 10);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice * 4 / 10, _level,0, priceOfLevel[_level], now);
                }
            }
            else
            {
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 4)
                {
                    orRef.transfer(payPrice/5);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice/5, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/5;
                }
                else
                {
                    userAddressByID[1].transfer(payPrice/5);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice/5, _level,0, priceOfLevel[_level], now);
                }

                orRef = findNextEligible(orRef,_level);
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 4)
                {
                    orRef.transfer(payPrice / 5);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice / 5, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice / 5;
                }
                else
                {
                    userAddressByID[1].transfer(payPrice / 5);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice / 5, _level,0, priceOfLevel[_level], now);
                }
            }
        }
        else
        {
            if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 4)
            {
                orRef.transfer(payPrice * 4 / 10);
                emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice * 4 / 10, _level,0, priceOfLevel[_level], now);
                userInfos[orRef].gainAmountCounter += payPrice * 4 / 10;
            }
            else
            {
                userAddressByID[1].transfer(payPrice * 4 /10);
                emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice * 4 /10, _level,0, priceOfLevel[_level], now);
            }
        }    

        userAddressByID[1].transfer(payPrice / 5);
        emit paidForLevelEv(userInfos[_user].id,_user,userInfos[userAddressByID[1]].id, userAddressByID[1], payPrice / 5, _level,2, priceOfLevel[_level], now);
        todayBonusAmount += payPrice / 5;

        splitForStack(_user,payPrice, _level);
    }

    function splitForStack(address _user, uint payPrice, uint _level) internal returns(bool)
    {
        address payable usrAddress = userAddressByID[userInfos[_user].referrerID];
        uint i;
        uint j;
        payPrice = payPrice / 50;
        for(i=0;i<100;i++)
        {
            if(j == 20 ) break;
            if(userInfos[usrAddress].levelBuyCheck[_level] > 0  || userInfos[usrAddress].id == 1 )
            {
                if(userInfos[usrAddress].gainAmountCounter < userInfos[usrAddress].investAmountCounter * 4 || _level == 12)
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


    function findFreeReferrer1(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](3);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        referrals[2] = userInfos[_user].referral[2];
        address found = searchForFirst(referrals);
        if(found == address(0)) found = searchForSecond(referrals);
        if(found == address(0)) found = searchForThird(referrals);
        return found;
    }

    function searchForFirst(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 0) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;       
    }

    function searchForSecond(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 1) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;       
    }

    function searchForThird(address[] memory _user) internal view returns (address)
    {
        address freeReferrer;
        for(uint i = 0; i < _user.length; i++) {
            if(userInfos[_user[i]].referral.length == 2) {
                freeReferrer = _user[i];
                break;
            }
        }
        return freeReferrer;        
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;
        address found = findFreeReferrer1(_user);
        if(found != address(0)) return found;
        address[] memory referrals = new address[](363);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];
        referrals[2] = userInfos[_user].referral[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 363; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 120) {
                    referrals[(i+1)*3] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = userInfos[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = userInfos[referrals[i]].referral[2];
                }
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

        
    function changeDefaultRefID(uint newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }
}