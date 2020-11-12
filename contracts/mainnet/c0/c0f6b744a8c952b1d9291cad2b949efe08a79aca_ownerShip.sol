/**
 *Submitted for verification at Etherscan.io on 2020-08-25
*/

/*
*
* ######## ##     ## ########  ######## ######## ##      ##    ###    ##    ##  ######      ##     ## ##    ## ######## 
*    ##    ##     ## ##     ## ##       ##       ##  ##  ##   ## ##    ##  ##  ##    ##      ##   ##   ##  ##       ##  
*    ##    ##     ## ##     ## ##       ##       ##  ##  ##  ##   ##    ####   ##             ## ##     ####       ##   
*    ##    ######### ########  ######   ######   ##  ##  ## ##     ##    ##     ######         ###       ##       ##    
*    ##    ##     ## ##   ##   ##       ##       ##  ##  ## #########    ##          ##       ## ##      ##      ##     
*    ##    ##     ## ##    ##  ##       ##       ##  ##  ## ##     ##    ##    ##    ## ###  ##   ##     ##     ##      
*    ##    ##     ## ##     ## ######## ########  ###  ###  ##     ##    ##     ######  ### ##     ##    ##    ######## 
*
* Hello
* This is ThreeWays 1.0
* https://threeways.xyz
*
*/

pragma solidity 0.5.16;

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

contract threeWays is ownerShip {

    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID
    uint public constant maxDownLimit = 2;
    uint public constant levelLifeTime = 31536000;  // = 365 days;
    uint public lastIDCount = 0;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint originalReferrer;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address) public userAddressByID;


    event regLevelEv(uint indexed _userID, address indexed _userWallet, uint indexed _referrerID, address _referrerWallet, uint _originalReferrer, uint _time);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(uint userID, address indexed _user, uint referralID, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(uint userID, address indexed _user, uint referralID, address indexed _referral, uint _level, uint _amount, uint _time);

    constructor() public {

        priceOfLevel[1] = 0.1 ether;
        priceOfLevel[2] = 0.2 ether;
        priceOfLevel[3] = 0.4 ether;
        priceOfLevel[4] = 0.8 ether;
        priceOfLevel[5] = 1.6 ether;
        priceOfLevel[6] = 3.2 ether;
        priceOfLevel[7] = 6.4 ether;
        priceOfLevel[8] = 12.8 ether;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 0,
            originalReferrer: 0,
            referral: new address[](0)
        });

        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 8; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            emit paidForLevelEv(lastIDCount, ownerWallet, 0, address(0), i, priceOfLevel[i], now);
        }
        
        emit regLevelEv(lastIDCount, msg.sender, 0, address(0), 0, now);
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
        else revert('Incorrect Value send');

        if(userInfos[msg.sender].joined) buyLevel(msg.sender, level);
        else if(level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if(userInfos[referrer].joined) refId = userInfos[referrer].id;
            else revert('Incorrect referrer');

            regUser(msg.sender, refId);
        }
        else revert('Please buy first level for 0.1 ETH');
    }

    function regUser(address _user, uint _referrerID) public payable returns(bool) {

        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        uint originalReferrer = _referrerID;

        require(!userInfos[_user].joined, 'User exists');

        if(msg.sender != ownerWallet){
            require(msg.value == priceOfLevel[1], 'Incorrect Value');
            require(msg.sender == _user, 'Invalid user');
        }

        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit){

            _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;
        }

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            originalReferrer: originalReferrer,
            referral: new address[](0)
        });

        userInfos[_user] = UserInfo;
        userAddressByID[lastIDCount] = _user;

        userInfos[_user].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(_user);

        if(msg.sender != ownerWallet){
            payForCycle(1, _user);  //pay to uplines
        }

        emit regLevelEv(lastIDCount, _user, _referrerID, userAddressByID[_referrerID], originalReferrer, now);
        return true;
    }

    function buyLevel(address _user, uint _level) public payable {
        
        require(userInfos[_user].joined, 'User not exist'); 
        require(_level > 0 && _level < 9, 'Incorrect level');

        if(msg.sender != ownerWallet){
            require(msg.value == priceOfLevel[_level], 'Incorrect Value');
            require(msg.sender == _user, 'Invalid user');
        }

        if(_level == 1) {
            userInfos[_user].levelExpired[1] += levelLifeTime;
        }
        else {
            for(uint l =_level - 1; l > 0; l--) require(userInfos[_user].levelExpired[l] >= now, 'Buy the previous level first');
            if(userInfos[_user].levelExpired[_level] == 0) userInfos[_user].levelExpired[_level] = now + levelLifeTime;
            else userInfos[_user].levelExpired[_level] += levelLifeTime;
        }
        
        if(msg.sender != ownerWallet){
            payForCycle(_level, _user);  //pay to uplines.
        }

        emit levelBuyEv(_user, _level, msg.value, now);
    }
    
    function payForCycle(uint _level, address _user) internal {

        address referrer;
        address referrer1;
        address def = userAddressByID[defaultRefID];
        uint256 price = priceOfLevel[_level] * 4500 / 10000;
        uint256 adminPart = price * 10000 / 45000;

        referrer = findValidUpline(_user, _level);
        referrer1 = findValidUpline(referrer, _level);

        if(!userInfos[referrer].joined)
        {
            address(uint160(def)).transfer(price);
            emit lostForLevelEv(userInfos[referrer].id, referrer, userInfos[_user].id, _user, _level, price, now);
        }
        else
        {
            address(uint160(referrer)).transfer(price);
            emit paidForLevelEv(userInfos[referrer].id, referrer, userInfos[_user].id, _user, _level, price, now);
        }

        if(!userInfos[referrer1].joined || !(userInfos[_user].levelExpired[_level] >= now ) )
        {
            address(uint160(def)).transfer(price);
            emit lostForLevelEv(userInfos[referrer1].id, referrer1, userInfos[_user].id, _user, _level, price, now);
        }
        else
        {
            address(uint160(referrer1)).transfer(price);
            emit paidForLevelEv(userInfos[referrer1].id, referrer1, userInfos[_user].id, _user, _level, price, now);
        }
        ownerWallet.transfer(adminPart);
    }

    function findValidUpline(address _user, uint _level) internal view returns(address)
    {
        for(uint i=0;i<64;i++)
        {
            _user = userAddressByID[userInfos[_user].referrerID];
            if(userInfos[_user].levelExpired[_level] >= now ) break;
        }
        if(!(userInfos[_user].levelExpired[_level] >= now )) _user = userAddressByID[defaultRefID];
        return _user;
    }

    function findFreeReferrer(address _user) public view returns(address) {

        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 62) {
                    referrals[(i+1)*2] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userInfos[referrals[i]].referral[1];
                }
                else {
                    break;
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

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
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
    
    function viewTimestampSinceJoined(address usr) public view returns(uint256[8] memory timeSinceJoined )
    {
        if(userInfos[usr].joined)
        {
            for(uint256 i=0;i<8;i++)
            {
                uint256 t = userInfos[usr].levelExpired[i+1];
                if(t>now)
                {
                    timeSinceJoined[i] = (t-now);
                }
            }
        }
        return timeSinceJoined;
    }
    
    function ownerOnlyCreateUser(address[] memory _user ) public onlyOwner returns(bool)
    {
        require(_user.length <= 50, "invalid input");
        for(uint i=0; i < _user.length; i++ )
        {
            require(regUser(_user[i], 1), "registration fail");
        }
        return true;
    }
    
}