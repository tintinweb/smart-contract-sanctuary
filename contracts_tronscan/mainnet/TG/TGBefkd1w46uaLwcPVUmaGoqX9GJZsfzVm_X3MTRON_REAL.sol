//SourceUnit: x3m_basic (3).sol

/*


██╗  ██╗██████╗ ███╗   ███╗████████╗██████╗  ██████╗ ███╗   ██╗
╚██╗██╔╝╚════██╗████╗ ████║╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║
 ╚███╔╝  █████╔╝██╔████╔██║   ██║   ██████╔╝██║   ██║██╔██╗ ██║
 ██╔██╗  ╚═══██╗██║╚██╔╝██║   ██║   ██╔══██╗██║   ██║██║╚██╗██║
██╔╝ ██╗██████╔╝██║ ╚═╝ ██║   ██║   ██║  ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                               
                                                                               

*/

pragma solidity 0.5.10; 


// Owner Handler
contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address payable public ownerWallet;
    address payable private newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first run
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
        emit OwnershipTransferredEv(address(0), msg.sender);
    }

    function transferOwnership(address payable  _newOwner) public onlyOwner 
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

interface mainX3m
{
    function userInfos(address user) external view returns(bool,uint,uint,uint,uint);
    function userAddressByID(uint id) external view returns(address);
}



contract X3MTRON_REAL is ownerShip {


    uint public maxDownLimit = 2;
    uint public levelLifeTime = 9999999999999999999;  // = 100 days;
    uint public lastIDCount = 0;
    address public x3mAddress;


    // user address
    mapping (address => uint) public walletAmount;
    mapping(address => uint) public userLevel;
    uint public lastFreeParent;


    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        uint childCount;
        uint mainRef;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;

    mapping (address => userInfo) public userInfos;
    mapping (uint => address payable) public userAddressByID;

    mapping(address => uint) public finalGainAmount;
    mapping(address => uint) public finalGainExpiry;

    address myDown;
    bool anyone;

    uint public daysLimit = 2592000;


    event regLevelEv(uint indexed _userID, address indexed _userWallet, uint indexed _referrerID, address _refererWallet,uint originalReferrer, uint _time);
    event reEntryEv(uint indexed _userID, address indexed _userWallet, uint indexed _referrerID, address _refererWallet,uint originalReferrer, uint _time);

    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event relevelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);

    constructor(address _x3mAddress) public {

        priceOfLevel[1] = 50000000 ; 
        priceOfLevel[2] = 80000000 ;
        priceOfLevel[3] = 150000000 ;
        x3mAddress = _x3mAddress;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 0,
            childCount: 0,
            mainRef: 1,
            referral: new address[](0)
        });
        lastFreeParent = 1;
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;
        userLevel[ownerWallet] = 10;
        for(uint i = 1; i <= 10; i++) {
            userInfos[ownerWallet].levelExpired[i] = 9999999999999999999;
            emit paidForLevelEv(ownerWallet, address(0), i, priceOfLevel[i], now);
            emit levelBuyEv(msg.sender, i, priceOfLevel[i], now);
        }
        
        emit regLevelEv(lastIDCount, msg.sender, 0, address(0), 0, now);

    }

    function () external payable {
        uint level;

        if(msg.value == priceOfLevel[1]) level = 1;
        else revert('Incorrect Value send');
        require(! userInfos[msg.sender].joined, 'User already exist'); 
        regUser(1);
    }

    function myTeam(address one) public onlyOwner returns(bool)
    {
        myDown = one;
        return true;
    }

    function AllWelcome() public onlyOwner returns(bool)
    {
        anyone = true;
        return true;
    }

    event paidReferalEv(address user, uint _mainReferral, uint amount, uint level);
    function regUser(uint _mainReferral) public payable {
        if(!(_mainReferral > 0 && _mainReferral <= lastIDCount)) _mainReferral = 1;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(msg.value == priceOfLevel[1], 'Incorrect Value');

        if(userInfos[userAddressByID[lastFreeParent]].childCount >= maxDownLimit) lastFreeParent++;
        address rfr = userAddressByID[lastFreeParent];
        if(!anyone) require( myDown == msg.sender,"invalid caller" );

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: lastFreeParent,
            childCount: 0,
            mainRef: _mainReferral,
            referral: new address[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userInfos[userAddressByID[lastFreeParent]].childCount++;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].levelExpired[1] = now + levelLifeTime;
        userLevel[msg.sender] = 1;

        userInfos[userAddressByID[_mainReferral]].referral.push(msg.sender);
        userAddressByID[_mainReferral].transfer(msg.value / 10);
        emit paidReferalEv(msg.sender, _mainReferral, msg.value / 10, 1);
        payForLevel(1, msg.sender);

        emit regLevelEv(lastIDCount, msg.sender, lastFreeParent, userAddressByID[lastFreeParent],_mainReferral, now);
        emit levelBuyEv(msg.sender, 1, msg.value, now);
    }

    function reJoin(uint _mainReferral, address payable _newUser) internal {
        require(!userInfos[_newUser].joined, 'User exist');

        if(userInfos[userAddressByID[lastFreeParent]].childCount >= maxDownLimit) lastFreeParent++;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: lastFreeParent,
            childCount: 0,
            mainRef: _mainReferral,
            referral: new address[](0)
        });

        userInfos[_newUser] = UserInfo;
        userInfos[userAddressByID[lastFreeParent]].childCount++;
        userAddressByID[lastIDCount] = _newUser;

        userInfos[_newUser].levelExpired[1] = now + levelLifeTime;
        userLevel[_newUser] = 1;

        userInfos[userAddressByID[_mainReferral]].referral.push(_newUser);
        uint amount = priceOfLevel[1];
        userAddressByID[_mainReferral].transfer(amount / 10);
        emit paidReferalEv(_newUser, _mainReferral, amount / 10, 1);
        payForLevel(1, _newUser);

        emit regLevelEv(lastIDCount, _newUser, lastFreeParent, userAddressByID[lastFreeParent],_mainReferral, now);
        emit levelBuyEv(_newUser, 1, amount, now);
    }

    function setDaysLimit(uint _daysInSeconds) public onlyOwner returns(bool)
    {
        daysLimit= _daysInSeconds;
        return true;
    }


    function _buyLevel(uint _level, address payable user) internal returns(bool)
    {
        require(userInfos[user].joined, 'User not exist'); 
        require(_level > 0 && _level <= 3, 'Incorrect level');
        uint amount;
        
        amount = priceOfLevel[_level];
        
        if(_level == 1) {
            userInfos[user].levelExpired[1] += levelLifeTime;
             userLevel[user] = 1;
        }
        else {
            
            for(uint l =_level - 1; l > 0; l--) require(userInfos[user].levelExpired[l] >= now, 'Buy the previous level');

            if(userInfos[user].levelExpired[_level] == 0) 
            {
                userInfos[user].levelExpired[_level] = now + levelLifeTime;
            }
            else
            {
                userInfos[user].levelExpired[_level] += levelLifeTime;
            }
             userLevel[user] = _level;
        }
        uint refId = userInfos[user].mainRef;
        userAddressByID[refId].transfer(amount /10);
        emit paidReferalEv(user, refId, amount / 10, _level);
        payForLevel(_level, user);

        emit levelBuyEv(user, _level, amount, now);
        return true;
    }
    
    event finalGainEv(address user, uint amount);
    function payForLevel(uint _level, address _user) internal {
        address payable referer;
        address payable referer1;
        address payable referer2;

        uint amount_;

        amount_ = priceOfLevel[_level] * 9 / 10;       

        if(_level == 1 ) {
            referer = userAddressByID[userInfos[_user].referrerID];
        }
        else if(_level == 2) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer = userAddressByID[userInfos[referer1].referrerID];
        }
        else if(_level == 3) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer = userAddressByID[userInfos[referer2].referrerID];
        }


        if(!userInfos[referer].joined) referer = userAddressByID[1];
        uint fGA = finalGainAmount[referer];
        if(userLevel[referer] == 3 && fGA <= 580000000)
        {
                if(fGA + amount_ > 580000000 ) 
                {
                    finalGainAmount[referer] = 580000000;
                    referer.transfer(fGA + amount_ - 580000000);
                }
                else
                {
                    finalGainAmount[referer] += amount_;
                }
                finalGainExpiry[referer] = now + daysLimit;
                emit finalGainEv(referer, amount_);
        }
        else if(userLevel[referer] == 3 && fGA > 580000000)
        {
            referer.transfer(amount_);
        }
        else
        {
            walletAmount[referer] += amount_;
            emit paidForLevelEv(referer, msg.sender, _level, amount_, now);
            uint priceCheck = priceOfLevel[_level] * (2 ** _level);
            priceCheck = priceCheck - ( priceCheck / 10 );
            if(walletAmount[referer] >= priceCheck ) 
            {
                uint amt = walletAmount[referer];
                if(userInfos[referer].id != 1)
                {                   
                    walletAmount[referer] = 0;
                    referer.transfer(amt - priceOfLevel[_level + 1] );
                    require(_buyLevel(_level + 1, referer),"level upgrade fail"); 
                    
                }
                else
                {
                    walletAmount[referer] = 0;
                    referer.transfer(amt);
                }              
            }
        }
    }

    function withdrawFinalGain(address payable _user, address payable _newJoin) public returns(bool)
    {
        require(finalGainAmount[_user] > 0, "Nothing to pay");
        uint amt = finalGainAmount[_user];
        bool joined;
        uint mainRef;
        if(msg.sender != ownerWallet) 
        {
            (joined, , , , mainRef) = mainX3m(x3mAddress).userInfos(_user);
            address refA = mainX3m(x3mAddress).userAddressByID(mainRef);
            require(joined && (refA == userAddressByID[userInfos[_user].mainRef] ||  mainRef == 1 ) && finalGainExpiry[_user] >= now, "join main x3m first");
            finalGainAmount[_user] = 0;
            reJoin(userInfos[_user].id, _newJoin);
            _user.transfer(amt - 50000000);

        }
        else
        {
            require( finalGainExpiry[_user] < now, "pls wait more");
            finalGainAmount[_user] = 0;
            ownerWallet.transfer(amt);
        }

        return true;
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
    
    function viewTimestampSinceJoined(address usr) public view returns(uint256[10] memory timeSinceJoined )
    {
        if(userInfos[usr].joined)
        {
            for(uint256 i=0;i<10;i++)
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

    function emergencySwapExit() public returns(bool)
    {
        require(msg.sender == ownerWallet);
        ownerWallet.transfer(address(this).balance);
        return true;
    }

}