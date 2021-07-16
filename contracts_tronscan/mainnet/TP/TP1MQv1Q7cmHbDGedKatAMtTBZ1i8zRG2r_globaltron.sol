//SourceUnit: tronglobaltest.sol

pragma solidity 0.5.9;

contract globaltron {


    struct User {

        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => X3) x3Matrix;
        
    }
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }


    uint8 public constant LAST_LEVEL = 8;

    mapping(address => User) public users;

    mapping(uint => address) public idToAddress;

    mapping(uint => address) public userIds;

    mapping(address => uint) public balances;
    
    mapping(uint => uint) public distForLevel;
    
    mapping(uint => uint) public uniLevelDistPart;
    
    mapping(address => uint) public totalGainInUniLevel; 
    mapping(address => uint) public totalGainInDirect; 
    
    mapping(address => uint) public netTotalUserWithdrawable;  //Dividend is not included in it

    uint public lastUserId = 1;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
   
   // Events
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user,uint indexed userId, address indexed referrer,uint referrerId, uint8 matrix, uint8 level, uint8 place);
    event MissedTronReceive(address indexed receiver,uint receiverId, address indexed from,uint indexed fromId, uint8 matrix, uint8 level);
    event SentDividends(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 matrix, uint8 level, bool isExtra);
    event SentDividendaas(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 level, bool isExtra);
    event SentDividendbbs(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 level, bool isExtra);
    event SentDividendccs(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 level, bool isExtra);
    event SentDividenddds(address indexed from,uint indexed fromId, address indexed receiver,uint receiverId, uint8 level, bool isExtra);
    event paidForUniLevelEv(uint timeNow,address PaitTo,uint Amount);
    event paidForLevelEv(address indexed user, address indexed  referrer, uint level, uint amount, uint timeNow);

   

    constructor(address ownerAddress) public {
       
        levelPrice[1] = 600 * 1e6;
        
        uniLevelDistPart[1] = (1200*2)/100;
        uniLevelDistPart[2] = (1200*2)/100;
        uniLevelDistPart[3] = (1200*2)/100;
        uniLevelDistPart[4] = (1200*2)/100;
        uniLevelDistPart[5] = (1200*2)/100;
        uniLevelDistPart[6] = (1200*2)/100;
        uniLevelDistPart[7] = (1200*2)/100;
        uniLevelDistPart[8] = (1200*2)/100;
        uniLevelDistPart[9] = (1200*2)/100;
        uniLevelDistPart[10] = (1200*2)/100;
        
        distForLevel[1] = 600;

        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }

        owner = ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
        }
      
       userIds[1] = ownerAddress;

    }
   

    function() external payable {

        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));

    }



    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

   

    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        
        
        
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);

            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;

            users[msg.sender].activeX3Levels[level] = true;

            updateX3Referrer(msg.sender, freeX3Referrer, level);

            emit Upgrade(msg.sender, freeX3Referrer, 1, level);
            
            sendTronDividendccs(owner, msg.sender,1);
        
    }    

            
   

    function registration(address userAddress, address referrerAddress) private {

        require(msg.value == 1200 trx, "registration cost 1200");

        require(!isUserExists(userAddress), "user exists");

        require(isUserExists(referrerAddress), "referrer not exists");

       

        uint32 size;

        assembly {

            size := extcodesize(userAddress)

        }

        require(size == 0, "cannot be a contract");

       lastUserId++;
        User memory user = User({
            id: lastUserId, 
            referrer: referrerAddress,
            partnersCount: 0

        });

       

        users[userAddress] = user;

        idToAddress[lastUserId] = userAddress;
        
        

       

        users[userAddress].referrer = referrerAddress;

       

        userIds[lastUserId] = userAddress;

        
        payForUniLevel(userAddress);
       
        for(uint i = 1; i <= 1; i++) {
            totalGainInDirect[referrerAddress] += distForLevel[i];
            netTotalUserWithdrawable[referrerAddress] += distForLevel[i];
            emit paidForLevelEv(address(0), referrerAddress, i, distForLevel[i], now);
            
        }
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
        sendTronDividendaas(referrerAddress, userAddress,1);
        
        sendTronDividenddds(owner, msg.sender,1);
        
    }
    
    function payForUniLevel(address _useraddress) internal returns(bool)
                {
                    address userAddress=_useraddress;
                    address receiver;
                    uint i=0;
                    while(i<10)
                    {
                        User storage UserAddress=users[_useraddress];
                        receiver=UserAddress.referrer;
                        
                        
                        
                        uint Amount = uniLevelDistPart[i + 1 ];
                        totalGainInUniLevel[receiver] += Amount;
                        netTotalUserWithdrawable[receiver] += Amount;
                        emit paidForUniLevelEv(now,receiver, Amount);
                        
                        sendTronDividendbbs(receiver, userAddress,1);
                        
                        _useraddress=receiver;
                        
                        
                        
                        i++;
                       
                    }
                    return true;
                }
            

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {

        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);



        if (users[referrerAddress].x3Matrix[level].referrals.length < 2) {

            emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress, users[referrerAddress].id, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));

            return sendTronDividends(referrerAddress, userAddress, 1, level);
            
        }

       

        emit NewUserPlace(userAddress,users[userAddress].id, referrerAddress,users[referrerAddress].id, 1, level, 2);
        
        //close matrix

        users[referrerAddress].x3Matrix[level].referrals = new address[](0);

        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL) {

            users[referrerAddress].x3Matrix[level].blocked = true;

        }



        //create new one by recursion

        if (referrerAddress != owner) {

            //check referrer active level

            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);

            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {

                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;

            }

           

            users[referrerAddress].x3Matrix[level].reinvestCount++;

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);

            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
            
           

        } else {

            sendTronDividends(owner, userAddress, 1, level);
            
            
            users[owner].x3Matrix[level].reinvestCount++;

            emit Reinvest(owner, address(0), userAddress, 1, level);

        }
        
    }
    

    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        uint cv=0;
        while(cv<10)
        {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;

        }
        
        
        
        
    }

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {

        return users[userAddress].activeX3Levels[level];

    }

    function get3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory, uint, bool) {

        return (users[userAddress].x3Matrix[level].currentReferrer,

                users[userAddress].x3Matrix[level].referrals,

                users[userAddress].x3Matrix[level].reinvestCount,

                users[userAddress].x3Matrix[level].blocked);

    }




    function isUserExists(address user) public view returns (bool) {

        return (users[user].id != 0);

    }



    function findTronReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {

        address receiver = userAddress;

        bool isExtraDividends;

        if (matrix == 1) {

            while (true) {

                if (users[receiver].x3Matrix[level].blocked) {

                    emit MissedTronReceive(receiver,users[receiver].id, _from,users[_from].id, 1, level);

                    isExtraDividends = true;

                    receiver = users[receiver].x3Matrix[level].currentReferrer;

                } else {

                    return (receiver, isExtraDividends);

                }

            }

        }

    }
    
    function findTronReceiveraa(address userAddress, address _from, uint8 level) private returns(address, bool) {

        address receiver = userAddress;

        bool isExtraDividends;
        
         return (receiver, isExtraDividends);


    }
    
    function findTronReceiverbb(address userAddress, address _from, uint8 level) private returns(address, bool) {

        address receiver = userAddress;

        bool isExtraDividends;
        
         return (receiver, isExtraDividends);


    }
    
    function findTronReceivercc(address userAddress, address _from, uint8 level) private returns(address, bool) {
        
        address receiver = userAddress;

        bool isExtraDividends;
        
         return (receiver, isExtraDividends);


    }
    
    function findTronReceiverdd(address userAddress, address _from, uint8 level) private returns(address, bool) {
        
        address receiver = userAddress;

        bool isExtraDividends;
        
         return (receiver, isExtraDividends);


    }



    function sendTronDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {

        (address receiver, bool isExtraDividends) = findTronReceiver(userAddress, _from, matrix, level);
        uint AMTT;
         if(level==1)
         {
             AMTT=1200000000;
         }
         else if(level==2)
         {
             AMTT=2400000000;
         }
         else if(level==3)
         {
             AMTT=4800000000;
         }
         else if(level==4)
         {
             AMTT=9600000000;
         }
         else if(level==5)
         {
             AMTT=19200000000;
         }
         else if(level==6)
         {
             AMTT=38400000000;
         }
         else if(level==7)
         {
             AMTT=76800000000;
         }
         else if(level==8)
         {
             AMTT=153600000000;
         }
         else
         {
             AMTT=0;
         }


        if (!address(uint160(receiver)).send(AMTT)) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividends(_from,users[_from].id, receiver,users[receiver].id, matrix, level, isExtraDividends);

    }


     function sendTronDividendaas(address userAddress, address _from,  uint8 level) private {

        (address receiver, bool isExtraDividends) = findTronReceiveraa(userAddress, _from, level);



        if (!address(uint160(receiver)).send(600000000)) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividendaas(_from,users[_from].id, receiver,users[receiver].id, level, isExtraDividends);

    }
    
    function sendTronDividendbbs(address userAddress, address _from,  uint8 level) private {

        (address receiver, bool isExtraDividends) = findTronReceiverbb(userAddress, _from, level);



        if (!address(uint160(receiver)).send(24000000)) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividendbbs(_from,users[_from].id, receiver,users[receiver].id, level, isExtraDividends);

    }
    
    function sendTronDividendccs(address userAddress, address _from,  uint8 level) private {
        

        (address receiver, bool isExtraDividends) = findTronReceivercc(userAddress, _from, level);

           uint AMTTX;
         if(level==1)
         {
             AMTTX=1200000000;
         }
         else if(level==2)
         {
             AMTTX=2400000000;
         }
         else if(level==3)
         {
             AMTTX=4800000000;
         }
         else if(level==4)
         {
             AMTTX=9600000000;
         }
         else if(level==5)
         {
             AMTTX=19200000000;
         }
         else if(level==6)
         {
             AMTTX=38400000000;
         }
         else if(level==7)
         {
             AMTTX=76800000000;
         }
         else if(level==8)
         {
             AMTTX=153600000000;
         }
         else
         {
             AMTTX=0;
         }

        if (!address(uint160(receiver)).send(AMTTX)) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividendccs(_from,users[_from].id, receiver,users[receiver].id, level, isExtraDividends);

    }
    
    function sendTronDividenddds(address userAddress, address _from,  uint8 level) private {
        

        (address receiver, bool isExtraDividends) = findTronReceiverdd(userAddress, _from, level);

           uint AMTTX;
           AMTTX=360000000;
        if (!address(uint160(receiver)).send(AMTTX)) {

            return address(uint160(receiver)).transfer(address(this).balance);

        }

       

        emit SentDividenddds(_from,users[_from].id, receiver,users[receiver].id, level, isExtraDividends);

    }

   

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {

        assembly {

            addr := mload(add(bys, 20))

        }

    }

}