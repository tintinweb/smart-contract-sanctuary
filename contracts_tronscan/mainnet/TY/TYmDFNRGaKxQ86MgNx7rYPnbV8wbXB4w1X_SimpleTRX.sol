//SourceUnit: SimpleTRX.sol

pragma solidity 0.5.9;

contract ownerShip
{
    address payable public ownerWallet;
    address payable public newOwner;
    address payable public residualWallet;
    
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    constructor() public 
    {
        ownerWallet = msg.sender;
    }

    function setResidualWallet(address payable newResidualWallet) public onlyOwner 
    {
        require(msg.sender == ownerWallet);
        residualWallet = newResidualWallet;
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

contract SimpleTRX is ownerShip {

    uint public defaultRefID = 1;
    uint maxDownLimit = 3;

    uint public lastIDCount = 0;
    mapping (uint => uint[]) public testArray;

    uint public minActivity = 7776000;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint originalReferrer;
        uint gainAmountCounter;
        uint investAmountCounter;
        address payable[] referral;
        uint registeredAt;
        uint registeredAtBlock;
        uint lastDirectRegisteredAt;
        uint lastDirectRegisteredAtBlock;
        mapping(uint => uint) levelBuyCheck;
    }

    mapping(uint => uint) public priceOfLevel;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable ) public userAddressByID;

    event regLevelEv(address indexed useraddress, uint userid,uint placeid,uint refferalid, address indexed refferaladdress, uint _time);
    event LevelByEv(uint userid,address indexed useraddress, uint level, uint amount, uint time);    
    event paidForLevelEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint Type, uint packageAmount, uint time );
    event paidResidualEv(uint fromUserId, address fromAddress, uint toUserId,address toAddress, uint amount,uint level,uint Type, uint packageAmount, uint time );
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _time);
    event reInvestEv(address user,uint userid,uint amount, uint timeNow, uint level);

    constructor() public {
        priceOfLevel[1] = 300000000 ;
        priceOfLevel[2] = 600000000 ;
        priceOfLevel[3] = 1200000000 ;
        priceOfLevel[4] = 2400000000 ;
        priceOfLevel[5] = 4800000000 ;
        priceOfLevel[6] = 9600000000 ;
        priceOfLevel[7] = 19200000000 ;
        priceOfLevel[8] = 38400000000 ;
        priceOfLevel[9] = 76800000000 ;
        priceOfLevel[10] = 153600000000 ;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            originalReferrer: 1,
            gainAmountCounter: 0,
            investAmountCounter: priceOfLevel[1],
            referral: new address payable [](0),
            registeredAt: now,
            registeredAtBlock: block.number,
            lastDirectRegisteredAt: now,
            lastDirectRegisteredAtBlock: block.number
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 10; i++) {
            userInfos[ownerWallet].levelBuyCheck[i] = 0;
        }
        userInfos[ownerWallet].levelBuyCheck[1] = 1;
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

        else revert('Incorrect Value send');

        if(userInfos[msg.sender].joined) buyLevel(level);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;
            else revert('Incorrect referrer');

            regUser(refId);
        }
        else revert('Please buy first level');
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
            gainAmountCounter: 0,
            investAmountCounter: msg.value,
            referral: new address payable[](0),
            registeredAt: now,
            registeredAtBlock: block.number,
            lastDirectRegisteredAt: now,
            lastDirectRegisteredAtBlock: block.number
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].levelBuyCheck[1] = 1;

        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);

        userInfos[userAddressByID[originalReferrer]].lastDirectRegisteredAt = now;
        userInfos[userAddressByID[originalReferrer]].lastDirectRegisteredAtBlock = block.number;

        payForLevel(1, msg.sender, priceOfLevel[1]);

        emit regLevelEv(msg.sender, lastIDCount, _referrerID, originalReferrer, userAddressByID[originalReferrer], now);
    }

    function buyLevel(uint _level) public payable {
        require(userInfos[msg.sender].joined, 'User not exist'); 
        require(_level > 0 && _level <= 10, 'Incorrect level');

        uint payPrice = priceOfLevel[_level];

        if(_level == 1) {
            payPrice = priceOfLevel[1];
            require(msg.value == priceOfLevel[1], 'Incorrect Value');
            userInfos[msg.sender].levelBuyCheck[1] = 1;
        }
        else {

            if( userInfos[msg.sender].gainAmountCounter <= userInfos[msg.sender].investAmountCounter * 5 ) {
                payPrice = priceOfLevel[_level] / 10 * 8;
                require(msg.value == payPrice, 'Incorrect Value #1');
            }else {
                payPrice = priceOfLevel[_level];
                require(msg.value == payPrice, 'Incorrect Value #2');
            }

            for(uint l =_level - 1; l > 0; l--) require(userInfos[msg.sender].levelBuyCheck[l] == 1 , 'Buy the previous level');

            if(userInfos[msg.sender].levelBuyCheck[_level] == 0) userInfos[msg.sender].levelBuyCheck[_level] = 1;
            else userInfos[msg.sender].levelBuyCheck[_level] = 1;
        }
        userInfos[msg.sender].investAmountCounter += msg.value;
        payForLevel(_level, msg.sender, payPrice);
        emit LevelByEv(userInfos[msg.sender].id, msg.sender, _level, payPrice, now);
    }

    function payForLevel(uint _level, address payable _user, uint payPrice) internal {

        address payable orRef = userAddressByID[userInfos[_user].originalReferrer];
        if(_level>1)
        {
            if(userInfos[orRef].levelBuyCheck[_level] > 0 ) 
            {
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
                {
                    orRef.transfer(payPrice/2);
                    emit paidForLevelEv(userInfos[_user].id,_user,userInfos[orRef].id, orRef, payPrice/2, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/2;
                }
                else 
                {
                    residualWallet.transfer(payPrice/2);
                    emit paidResidualEv(userInfos[_user].id,_user, 0, residualWallet, payPrice/2, _level,0, priceOfLevel[_level], now);
                }
            }
            else
            {
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
                {
                    orRef.transfer(payPrice/4);
                    emit paidForLevelEv(userInfos[_user].id, _user, userInfos[orRef].id, orRef, payPrice/4, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/4;
                }
                else
                {
                    residualWallet.transfer(payPrice/4);
                    emit paidResidualEv(userInfos[_user].id, _user, 0, residualWallet, payPrice/4, _level,0, priceOfLevel[_level], now);
                }

                orRef = findNextEligible(orRef, _level);
                if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
                {
                    orRef.transfer(payPrice/4);
                    emit paidForLevelEv(userInfos[_user].id, _user, userInfos[orRef].id, orRef, payPrice/4, _level,0, priceOfLevel[_level], now);
                    userInfos[orRef].gainAmountCounter += payPrice/4;
                }
                else
                {
                    residualWallet.transfer(payPrice/4);
                    emit paidResidualEv(userInfos[_user].id, _user, 0, residualWallet, payPrice/4, _level,0, priceOfLevel[_level], now);
                }
            }
        }
        else
        {
            if(userInfos[orRef].gainAmountCounter < userInfos[orRef].investAmountCounter * 10)
            {
                orRef.transfer(payPrice/2);
                emit paidForLevelEv(userInfos[_user].id, _user, userInfos[orRef].id, orRef, payPrice/2, _level, 0, priceOfLevel[_level], now);
                userInfos[orRef].gainAmountCounter += payPrice/2;
            }
            else
            {
                residualWallet.transfer(payPrice/2);
                emit paidResidualEv(userInfos[_user].id, _user, 0, residualWallet, payPrice/2, _level, 0, priceOfLevel[_level], now);
            }
        }     
        splitForStack(_user, payPrice, _level);
    }

    function splitForStack(address _user, uint payPrice, uint _level) internal returns(bool)
    {
        address payable usrAddress = userAddressByID[userInfos[_user].referrerID];
        uint i;
        uint j;
        uint exceededUser1 = 0;
        payPrice = payPrice / 20;
        for(i=0;i<1000;i++)
        {
            if(j == 10 ) break;
            if( exceededUser1 == 0 )
            {
                if( ( userInfos[usrAddress].levelBuyCheck[_level] > 0 ) && ( (now - userInfos[usrAddress].lastDirectRegisteredAt) <= minActivity ) )
                {
                    if(userInfos[usrAddress].gainAmountCounter < userInfos[usrAddress].investAmountCounter * 10 || _level == 10)
                    {
                        usrAddress.transfer(payPrice);
                        userInfos[usrAddress].gainAmountCounter += payPrice;
                        emit paidForLevelEv(userInfos[_user].id, _user, userInfos[usrAddress].id, usrAddress, payPrice, j, 1, priceOfLevel[_level], now);
                    }
                    else
                    {
                        residualWallet.transfer(payPrice);
                        emit paidResidualEv(userInfos[_user].id, _user, 0, residualWallet, payPrice, j, 1, priceOfLevel[_level], now);
                    }
                    j++;
                }
                else
                {
                    emit lostForLevelEv(usrAddress, _user, _level, now);
                }
            }
            else
            {
                residualWallet.transfer(payPrice);
                emit paidResidualEv(userInfos[_user].id, _user, 0, residualWallet, payPrice, j, 1, priceOfLevel[_level], now);
                j++;
            }
            
            if( userInfos[usrAddress].id == 1 )
            {
                exceededUser1 = 1;
            }

            usrAddress = userAddressByID[userInfos[usrAddress].referrerID];
        }           
    }

    function findNextEligible(address payable orRef,uint _level) public view returns(address payable)
    {
        address payable rightAddress;
        for(uint i=0;i<1000;i++)
        {
            orRef = userAddressByID[userInfos[orRef].originalReferrer];
            if(userInfos[orRef].levelBuyCheck[_level] > 0)
            {
                rightAddress = orRef;
                break;
            }
        }
        if(rightAddress == address(0)) rightAddress = residualWallet;
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
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function getPriceOfLevel(uint level) public view returns(string memory){
        return(uint2str(priceOfLevel[level]));
    }

    function changePriceOfLevel(uint level, uint newPriceOfLevel) onlyOwner public returns(string memory){
        priceOfLevel[level] = newPriceOfLevel;
        return("Price of level changed successfully!");
    }

    function getMinActivity() public view returns(uint){
        return(minActivity);
    }

    function changeMinActivity(uint newMinActivity) onlyOwner public returns(string memory){
        minActivity = newMinActivity;
        return("Minimum activity changed successfully!");
    }

    function getResidualWallet() public view returns(address addr){
        return(residualWallet);
    }
}