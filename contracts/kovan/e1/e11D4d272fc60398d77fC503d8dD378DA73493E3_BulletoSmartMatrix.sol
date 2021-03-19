/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.5.17;



interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId, uint256 time);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    function getUsedTokens(address owner, address operator) external view returns(uint256[] memory);

    function getSoldTokens(address owner) external view returns(uint256[] memory);

    function getAllTokens(address owner) external view returns(uint256[] memory);

}



interface IERC20 {
    
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BulletoSmartMatrix {
    
    IERC20 public _token;
    IERC721 public _nftToken;
    
    // We need contractStartTime becasue we'll allow users to buy new level after 5 days of our blockchain launch
    uint256 public contractStartTime;
    uint256 public totalInvested;
    uint256 public totalWithdraw;
    
    struct User {
        uint256 id;
        address referrer;
        uint256 refCount; // User refferal count
        mapping(uint8 => bool) activePlanLevel; // Which user level is active we have 8 levels
        mapping(uint8 => Matrix) ActiveMatrix; // Whcih matirx is currently active in user
    }

    // User Tree Branch 3 levels
    struct Matrix {
        address currentReferrer;
        address[] firstLevelReferrals; // 2
        address[] secondLevelReferrals; // 4
        address[] thirdLevelReferrals; // 8
        bool blocked;
        uint256 reinvestCount;
        address closedPart;
        // address currentReciever;
    }

    // General User level
    uint8 public constant LAST_LEVEL = 8;

    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public userIds;
    mapping(address => uint256) public balances;
    mapping(uint8 => uint256) public levelPrice;

    // Numbers of user in contract - 2 and last userId
    uint256 public lastUserId = 2;

    // Global owner is admin
    address public owner;

    


    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        uint256 referrerId
    );
    event Reinvest(
        address indexed user,
        address indexed currentReferrer,
        address indexed caller,
        uint8 level
    );
    event Upgrade(
        address indexed user,
        address indexed referrer,
        uint8 level
    );
    event NewUserPlace(
        address indexed user,
        address indexed referrer,
        uint8 level,
        uint256 place
    );
    event MissedBondReciever(
        address indexed receiver,
        address indexed from,
        uint8 level
    );
    event SentBondDividends(
        address indexed from,
        uint256 reciverId,
        uint256 amount,
        uint256 time,
        uint8 level
    );

    constructor(address ownerAddress, IERC20 token, IERC721 nftToken) public {
        
        owner = ownerAddress;  // 0xA793E745Da26b540aDf639A5a70748a25b00F1FD
        _token = token;  // 0x3768665101ea5b84f353bc6d6E7637F1c45822db
        _nftToken = nftToken;   // 0x9F3763ecc820d62BCa747ccCAEFD78272F565962
        
        require(
            LAST_LEVEL <= 8 && !(LAST_LEVEL <= 0),
            "select level between 1 to 8"
        );
        contractStartTime = block.timestamp;
        levelPrice[1] = 1; // First 5 days lvl 1 is unlimited but you can't go to next lvl
        levelPrice[2] = 2; // After 5 days if you completeted your lvl 1 then you can go to lvl 2
        levelPrice[3] = 6; // If you've completed lvl 2 and what to go to lvl 3 you have to but the nextg lvl(3) otherwise you'll be blocked from all levels
        levelPrice[4] = 24; // To keep using next and previous level you have to but the next level
        levelPrice[5] = 96;
        levelPrice[6] = 384;
        levelPrice[7] = 1152;
        levelPrice[8] = 2304;

        

        User memory user =
            User({id: 1, referrer: address(0), refCount: uint256(0)});

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activePlanLevel[i] = true; //   users[userAddress].ActiveMatrix[level].currentReferrer
             users[ownerAddress].ActiveMatrix[i].currentReferrer =  ownerAddress;
        }

        userIds[ownerAddress] = 1;
    }


    //This one will be avalibel for web3
    function registrationExt(address referrerAddress,uint256 tokenId) external  {
        registration(msg.sender, referrerAddress, 1);
        _token.transferFrom(owner,msg.sender,1e8);
        

        _nftToken.safeTransferFrom(msg.sender, owner, tokenId, "");
        totalInvested ++;
    }

    function bytesToAddress(bytes memory ads)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(ads, 20))
        }
    }

    function userExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }



    function buyNewLevel(uint8 level, uint256 amount) external {
        require(
            isUserExists(msg.sender),
            "user does not exists. Register first."
        );
        require(
            (now > contractStartTime + 30 days) || (users[msg.sender].ActiveMatrix[level-1].reinvestCount > 0),
            "You can't buy for first 30 days of Buleto release."
        );
        require(amount == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        require(
            users[msg.sender].activePlanLevel[level - 1],
            "buy previous level first"
        );
        require(
            !users[msg.sender].activePlanLevel[level],
            "level already activated"
        );

        if (users[msg.sender].ActiveMatrix[level - 1].blocked) {
            users[msg.sender].ActiveMatrix[level - 1].blocked = false;
        }
        
        uint256[] memory tokenIdList = _nftToken.getAllTokens(msg.sender);
    
        for(uint256 i=0 ; i < levelPrice[level] ; i++){
            
            _nftToken.safeTransferFrom(msg.sender, owner, tokenIdList[i], "");

        }
        
        totalInvested += levelPrice[level];

        address freeReferrer = findFreeReferrer(msg.sender, level);

        users[msg.sender].activePlanLevel[level] = true;
        updateMatrixReferrer(msg.sender, freeReferrer, level);

        emit Upgrade(msg.sender, freeReferrer, level);
    }

    function registration(address userAddress, address referrerAddress,uint256 amount)
        private
    {
        require(amount == 1, "registration cost 1");
        require(!userExists(userAddress), "user exists");
        require(userExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        // Inseting new User in global user array/mapping
        // lastUserId from global
        // refferId user reffer address it can be 1 to point admin
        // refCount initilially will be zero
        User memory user =
            User({id: lastUserId, referrer: referrerAddress, refCount: 0});

        users[userAddress] = user;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activePlanLevel[1] = true;

        balances[userAddress] = 0;

        // Updating global variable
        idToAddress[lastUserId] = userAddress;
        userIds[userAddress] = lastUserId;
        lastUserId++;

        // Increasing the reffer user refCount == reffered users;
        users[referrerAddress].refCount++;

        // Now check if the current reffer's level is active.
        address freeReferrer = findFreeReferrer(userAddress, 1);

        // Now this is the reffer of yours current matrix
        users[userAddress].ActiveMatrix[1].currentReferrer = freeReferrer;
        updateMatrixReferrer(userAddress, freeReferrer, 1);

        /**
        require(now - contractStartTime  >= 432000000,"You need to pass")
        */

        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id
        );
    }

    function findFreeReferrer(address userAddress, uint8 level)
        public
        view
        returns (address)
    {
        while (true) {
            // If our current reffer level is active we'll return the same referrer 
            // otherwise we'll search on tree upware for user who's lvl is active
            
            if (users[users[userAddress].referrer].activePlanLevel[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function updateMatrixReferrer(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        require(
            users[referrerAddress].activePlanLevel[level],
            "500. Referrer level is inactive"
        );
        
        if (users[referrerAddress].ActiveMatrix[level].firstLevelReferrals.length < 2 ) { // 1st and 2nd point
            users[referrerAddress].ActiveMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(users[referrerAddress].ActiveMatrix[level].firstLevelReferrals.length));
            
            // users[userAddress].ActiveMatrix[level].currentReferrer = referrerAddress;

            // If owner is reciver close the case here
            if (referrerAddress == owner) {
                
                // If owner end the send the either and end the operation. In this case Admin is the reciver
            
                return sendETHDividends(referrerAddress, userAddress, level);
            }
            // Update user reffer
            address ref = users[referrerAddress].ActiveMatrix[level].currentReferrer;
            
             // Why we don't have any length check

            if(users[referrerAddress].ActiveMatrix[level].firstLevelReferrals.length == 1){
                setReflection(userAddress, ref, level);
            }else{
                setReflection(userAddress, users[ref].ActiveMatrix[level].currentReferrer, level);
            }
        }
        else if (
            // 3rd, 4th, 5th, 6th
            users[referrerAddress].ActiveMatrix[level].secondLevelReferrals.length < 4
        ) {
            return updateActiveReferrerSecondLevel(userAddress, referrerAddress, level); // For parent
        }
        
        // 7ht, 8th, 9th, 10th, 11th, 12th, 13th, 14th
        else{
            updateActiveReferrerThirdLevel(userAddress, referrerAddress, level);
            
        }
    }
    
    function updateActiveReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (
            users[referrerAddress].ActiveMatrix[level].secondLevelReferrals.length < 4
        ) {
            // users[userAddress].ActiveMatrix[level].currentReferrer = referrerAddress;
            users[referrerAddress].ActiveMatrix[level].secondLevelReferrals.push(userAddress);
            
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                level,
                users[referrerAddress].ActiveMatrix[level].secondLevelReferrals.length);

            return sendETHDividends(referrerAddress, userAddress, level);
        }
    }

    function updateActiveReferrerThirdLevel(address userAddress, address referrerAddress, uint8 level) private {
        
        if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[0] == address(0)){  // Means its 7th place, we'll give data to 1st downline
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[0] = userAddress;
            
            address reciver1stDownlineFirst = users[referrerAddress].ActiveMatrix[level].firstLevelReferrals[0]; // First Upline here
            if(users[reciver1stDownlineFirst].ActiveMatrix[level].blocked){
                emit MissedBondReciever(reciver1stDownlineFirst, userAddress, level);
                address reciver1stDownlineSecond = users[referrerAddress].ActiveMatrix[level].firstLevelReferrals[1];
                if(users[reciver1stDownlineSecond].ActiveMatrix[level].blocked){
                    emit MissedBondReciever(reciver1stDownlineSecond, userAddress, level);
                    address reciverParallel;
                    if(users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[0] == referrerAddress){
                        reciverParallel = users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[1];
                    }else{
                        reciverParallel = users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[0];
                    }
                    if(users[reciverParallel].ActiveMatrix[level].blocked){
                        emit MissedBondReciever(reciverParallel, userAddress, level);
                        return sendETHDividends(owner, userAddress, level);
                    }
                    return setReflection(userAddress, reciverParallel, level);
                   
                }
                return setReflection(userAddress, reciver1stDownlineSecond, level);
            }
            return setReflection(userAddress, reciver1stDownlineFirst, level);
        }
        
        else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 1 || // To give investment to 8th and 9th place
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 2
        ){
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.push(userAddress);
            return sendETHDividends(referrerAddress, userAddress, level);
        }
        
        else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[3] == address(0)){ // Now at 10th place we'll give data to 2nd downline
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[3] = userAddress;
            
            for(uint8 i = 0 ; i < 4 ; i++){
                address reciver2ndDownline = users[referrerAddress].ActiveMatrix[level].secondLevelReferrals[i];
                if(!users[reciver2ndDownline].ActiveMatrix[level].blocked){
                    return setReflection(userAddress, reciver2ndDownline, level);
                }
                emit MissedBondReciever(reciver2ndDownline, userAddress, level);
            }
            address reciverParallel;
            if(users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[0] == referrerAddress){
                reciverParallel = users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[1];
            }else{
                reciverParallel = users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[0];
            }
            if(users[reciverParallel].ActiveMatrix[level].blocked){
                emit MissedBondReciever(reciverParallel, userAddress, level);
                return sendETHDividends(owner, userAddress, level);
            }
            return setReflection(userAddress, reciverParallel, level);
        }

        else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 4 || // To give investment to 11th and 12th place
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 5
        ){
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.push(userAddress);
            return sendETHDividends(referrerAddress, userAddress, level);
        }
        
        else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[6] == address(0)){ // Now at 13th place we'll give data to 3nd downline
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.push(userAddress);
          
            for(uint8  i = 0 ; i < 7 ; i++){
                address reciver3rdDownline = users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[i];
                if(!users[reciver3rdDownline].ActiveMatrix[level].blocked){
                    return setReflection(reciver3rdDownline,userAddress,level);
                }
                emit MissedBondReciever(reciver3rdDownline, userAddress, level);
            }
            address reciverParallel;
            if(users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[0] == referrerAddress){
                reciverParallel = users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[1];
            }else{
                reciverParallel = users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].firstLevelReferrals[0];
            }
            if(users[reciverParallel].ActiveMatrix[level].blocked){
                emit MissedBondReciever(reciverParallel, userAddress, level);
                return sendETHDividends(owner, userAddress, level);
            }
            return setReflection(userAddress, reciverParallel, level);
        }
        
        // Now 14th place and we need to reset the matrix and send investement to 3rd upline
        else if (users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length > 7){
            users[referrerAddress].ActiveMatrix[level].firstLevelReferrals = new address[](0);
            users[referrerAddress].ActiveMatrix[level].secondLevelReferrals = new address[](0);
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals = new address[](0);
            users[referrerAddress].ActiveMatrix[level].closedPart = userAddress;
            users[referrerAddress].ActiveMatrix[level].blocked = false;
            users[referrerAddress].ActiveMatrix[level].reinvestCount++;
            if(referrerAddress == owner){
                 return sendETHDividends(owner,userAddress,level); // 3rd upline
            }
            address thirdUpline = users[users[users[referrerAddress].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].currentReferrer].ActiveMatrix[level].currentReferrer;
            return setReflection(userAddress,thirdUpline, level); // 3rd upline
        }
        // return sendETHDividends(owner, userAddress, level);
    }
    
    function setReflection(address userAddress, address referrerAddress, uint8 level) private{
        
        while(true){   
            if(referrerAddress != address(0)){
                if(users[referrerAddress].ActiveMatrix[level].secondLevelReferrals.length < 4){
                    return updateActiveReferrerSecondLevel(userAddress, referrerAddress, level);
                }else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length < 6){
                    return updateActiveReferrerThirdLevelReflection(userAddress, referrerAddress, level);
                }
                referrerAddress = users[referrerAddress].ActiveMatrix[level].currentReferrer;
                
            }else return sendETHDividends(owner, userAddress, level);
        }
    }
    
    function updateActiveReferrerThirdLevelReflection(address userAddress, address referrerAddress, uint8 level) private{
        
        if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 0       // set reflection at 8th place
        || users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 1){
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[1] = userAddress; 
            sendETHDividends(referrerAddress, userAddress, level);
        }else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 2){   // set reflection at 9th place
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[2] = userAddress;
            sendETHDividends(referrerAddress, userAddress, level);
        }else if(users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 3    // set reflection 11t 8th place
        || users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals.length == 4){
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[4] = userAddress;
            sendETHDividends(referrerAddress, userAddress, level);
        }else{                                                                                  // set reflection at 12th place
            users[referrerAddress].ActiveMatrix[level].thirdLevelReferrals[5] = userAddress;
            sendETHDividends(referrerAddress, userAddress, level);
            users[referrerAddress].ActiveMatrix[level].blocked = true;
        }
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function getUserMatrix(address user, uint8 level)
        public
        view
        returns (
            address currentReferrer,
            address[] memory firstLevelReferrals,
            address[] memory secondLevelReferrals,
            address[] memory thirdLevelReferrals,
            bool blocked,
            uint256 reinvestCount,
            address closedPart,
            bool activePlanLevel
            // address currentReciever
        )
    {
        bool isPlanActive = users[user].activePlanLevel[level];
        Matrix memory m = (users[user].ActiveMatrix[level]);
        return (
            m.currentReferrer,
            m.firstLevelReferrals,
            m.secondLevelReferrals,
            m.thirdLevelReferrals,
            m.blocked,
            m.reinvestCount,
            m.closedPart,
            isPlanActive
            // m.currentReciever
        );
    }

    function sendETHDividends(
        address receiver,
        address _from,
        uint8 level
    ) private {
        
        balances[receiver] += levelPrice[level];
        totalWithdraw += levelPrice[level];

        uint256[] memory tokenIdList = _nftToken.getAllTokens(owner);
    
        for(uint256 i=0 ; i < levelPrice[level] ; i++){
            
            _nftToken.safeTransferFrom(owner, receiver, tokenIdList[i], "");

        }
        
        // users[_from].ActiveMatrix[level].currentReciever = receiver;
        
        emit SentBondDividends(_from, userIds[receiver], levelPrice[level], block.timestamp, level);
    
}
}