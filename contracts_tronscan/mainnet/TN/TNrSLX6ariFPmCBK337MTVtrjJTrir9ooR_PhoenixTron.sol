//SourceUnit: Phoenix.sol

/*
 _______  __                                  __          
|       \|  \                                |  \         
| ▓▓▓▓▓▓▓\ ▓▓____   ______   ______  _______  \▓▓__    __ 
| ▓▓__/ ▓▓ ▓▓    \ /      \ /      \|       \|  \  \  /  \
| ▓▓    ▓▓ ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\ ▓▓\▓▓\/  ▓▓
| ▓▓▓▓▓▓▓| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓    ▓▓ ▓▓  | ▓▓ ▓▓ >▓▓  ▓▓ 
| ▓▓     | ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓/  ▓▓▓▓\ 
| ▓▓     | ▓▓  | ▓▓\▓▓    ▓▓\▓▓     \ ▓▓  | ▓▓ ▓▓  ▓▓ \▓▓\
 \▓▓      \▓▓   \▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓   \▓▓\▓▓\▓▓   \▓▓                                                       
                                                          
  
www.trxphoenix.io
*/


pragma solidity >= 0.4.23 < 0.6.0;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PhoenixTRC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
   
    function _transferFromOwner(address _from, address _to, uint _value) internal {
        
        if(_to != 0x0){
        if(balanceOf[_from] >= _value){
        if(balanceOf[_to] + _value >= balanceOf[_to]){
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
                }
            }
        }
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}
contract PhoenixTron is PhoenixTRC20 {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint P3MaxLevel;
        uint P6MaxLevel;
        uint P3Income;
        uint P3P6Income;
        uint P3reinvestCount;
        uint P6reinvestCount;
        uint extraIncome;
        uint TokenBalance;
        uint P6Income;
        uint P3P6reinvestCount;

        mapping(uint8 => bool) activeP3Levels;
        mapping(uint8 => bool) downLineOverheadedP3;
        mapping(uint8 => bool) downLineOverheadedP6;
        mapping(uint8 => bool) activeP6Levels;
        mapping(uint8 => P3) P3Matrix;
        mapping(uint8 => P6) P6Matrix;
    }


    struct P3 {
        address currentReferrer;
        address[] referrals;
        uint[] reftype;
        bool blocked;
        uint reinvestCount;
        uint directSales;
    }



    struct P6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint[] firstLevelRefType;
        uint[] secondLevelRefType;
        bool blocked;
        uint reinvestCount;
        uint directSales;
        address closedPart;
    }



    uint8 public constant LAST_LEVEL = 18;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances;


    uint public lastUserId = 2;
    uint public totalearnedtrx = 0 trx;
    address public owner;
    mapping(uint8 => uint) public levelPrice;

    string eventtitle;
    string eventmessage;
    uint eventid;
    uint eventlevel;
    uint eventmatrix;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, uint indexed userId, address indexed referrer, uint referrerId, uint8 matrix, uint8 level, uint8 place,uint referrertype);
    event MissedTronReceive(address indexed receiver, uint receiverId, address indexed from, uint indexed fromId, uint8 matrix, uint8 level, uint price);
    event ImmediateAutoSponsor(address indexed receiver, uint receiverId, address indexed from, uint indexed fromId, uint price);
    event SentDividends(address indexed from, uint indexed fromId, address indexed receiver, uint receiverId, uint8 matrix, uint8 level, bool isExtra, uint price);

    constructor(address ownerAddress) public PhoenixTRC20(100000000,"Phoenix", "PHX"){
        levelPrice[1] = 40 trx;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        owner = ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            P3MaxLevel: uint(0),
            P6MaxLevel: uint(0),
            P3Income: uint8(0),
            P3reinvestCount: uint(0),
            P6reinvestCount: uint(0),
            P3P6Income: uint8(0),
            TokenBalance: 200*1000000000000000000,
            extraIncome: uint(0),
            P6Income: uint8(0),
            P3P6reinvestCount: uint8(0)
        });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for (uint8 j = 1; j <= LAST_LEVEL; j++) {
            users[ownerAddress].activeP3Levels[j] = true;
            users[ownerAddress].activeP6Levels[j] = true;
            users[ownerAddress].downLineOverheadedP3[j] = false;
            users[ownerAddress].downLineOverheadedP6[j] = false;
        }
        users[ownerAddress].P3MaxLevel = LAST_LEVEL;
        users[ownerAddress].P6MaxLevel = LAST_LEVEL;
        userIds[1] = ownerAddress;
    }



    function() external payable {
        if (msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawLostTRXFromBalance() public
    {
        require(msg.sender == owner, "onlyOwner");
        address(uint160(owner)).transfer(address(this).balance);
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);     
        
    }



    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            require(!users[msg.sender].activeP3Levels[level], "level already activated");
            require(users[msg.sender].activeP3Levels[level - 1], "previous level should be activated");
            if (users[msg.sender].P3Matrix[level - 1].blocked) {
                users[msg.sender].P3Matrix[level - 1].blocked = false;
            }

            address freeP3Referrer = findFreeP3Referrer(msg.sender, level);
            users[msg.sender].P3MaxLevel = level;
            users[msg.sender].P3Matrix[level].currentReferrer = freeP3Referrer;
            users[msg.sender].activeP3Levels[level] = true;
            if(users[msg.sender].downLineOverheadedP3[level])
                users[msg.sender].downLineOverheadedP3[level] = false;
            updateP3Referrer(msg.sender, freeP3Referrer, level);
            totalearnedtrx = totalearnedtrx + levelPrice[level];
            eventid = users[msg.sender].id;
            eventlevel = level;
            eventmatrix = 1;
            eventmessage = "User upgraded to the next level";
            eventtitle = "Upgrade";
            emit Upgrade(msg.sender, freeP3Referrer, 1, level);

        } else {
            require(!users[msg.sender].activeP6Levels[level], "level already activated");
            require(users[msg.sender].activeP6Levels[level - 1], "previous level should be activated");
            if (users[msg.sender].P6Matrix[level - 1].blocked) {
                users[msg.sender].P6Matrix[level - 1].blocked = false;
            }

            address freeP6Referrer = findFreeP6Referrer(msg.sender, level);
            users[msg.sender].P6MaxLevel = level;
            users[msg.sender].activeP6Levels[level] = true;
            if(users[msg.sender].downLineOverheadedP6[level])
                users[msg.sender].downLineOverheadedP6[level] = false;
            updateP6Referrer(msg.sender, freeP6Referrer, level);
            totalearnedtrx = totalearnedtrx + levelPrice[level];
            eventid = users[msg.sender].id;
            eventlevel = level;
            eventmatrix = 2;
            eventmessage = "User upgraded to the next level";
            eventtitle = "Upgrade";
            emit Upgrade(msg.sender, freeP6Referrer, 2, level);
        }
    }



    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 200 trx, "registration cost 200");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        uint32 size;
        assembly {
            size:= extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            P3MaxLevel: 1,
            P6MaxLevel: 1,
            P3Income: 0 trx,
            P3reinvestCount: 0,
            P6reinvestCount: 0,
            P3P6Income: 0 trx,
            P6Income: 0 trx,
            extraIncome: 0 trx,
            TokenBalance: 200*1000000000000000000,
            P3P6reinvestCount: 0

        });
        if(lastUserId <= 50000){
            _transferFromOwner(owner,userAddress,200*1000000000000000000);
        }
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeP3Levels[1] = true;
        users[userAddress].downLineOverheadedP3[1] = false;
        users[userAddress].downLineOverheadedP6[1] = false;
        users[userAddress].activeP6Levels[1] = true;
        userIds[lastUserId] = userAddress;
        
        users[owner].P3P6Income += 40 trx;
        address prevAddress = idToAddress[lastUserId - 1];
        address(uint160(prevAddress)).transfer(80 trx);
        emit ImmediateAutoSponsor(prevAddress,lastUserId - 1,msg.sender,lastUserId,80 trx);
        users[prevAddress].extraIncome += 80 trx;
        users[prevAddress].P3P6Income += 80 trx;
        lastUserId++;
        totalearnedtrx = totalearnedtrx + 200 trx;
        users[referrerAddress].partnersCount++;
        address freeP3Referrer = findFreeP3Referrer(userAddress, 1);
        users[userAddress].P3Matrix[1].currentReferrer = freeP3Referrer;
        updateP3Referrer(userAddress, freeP3Referrer, 1);
        updateP6Referrer(userAddress, findFreeP6Referrer(userAddress, 1), 1);
        
        eventid = users[userAddress].id;
        eventlevel = 1;
        eventmatrix = 1;
        eventmessage = "New User Registered";
        eventtitle = "Registeration";
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    
    function getTypeofNewUserPlacement(address userAddress,address receiverAddress,uint matrix,uint8 level) private returns(uint){
        address refaddress = users[userAddress].referrer;
        if(!isUserExists(refaddress))
            refaddress = idToAddress[1];
        if(!isUserExists(receiverAddress))
            receiverAddress = idToAddress[1];
        // type1 = invitedbyyou,type2 = bottomoverflow, type3 = overflowfromup, type4 = partner who is ahead of his inviter.
        uint referrertype = 1;
        if(receiverAddress == refaddress){
            referrertype = 1;
        }else{
            if(users[refaddress].id < users[receiverAddress].id){
                referrertype = 3;
            }else if(users[refaddress].id > users[receiverAddress].id){
                if(users[userAddress].P3MaxLevel > users[refaddress].P3MaxLevel && matrix == 1){
                    users[refaddress].downLineOverheadedP3[level] = true;
                    referrertype = 4;
                }else if(users[userAddress].P6MaxLevel > users[refaddress].P6MaxLevel && matrix == 2){
                    users[refaddress].downLineOverheadedP6[level] = true;
                    referrertype = 4;
                }else{
                    referrertype = 2;
                }
            }
        }
        return referrertype;
    }

    function updateP3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].P3Matrix[level].referrals.push(userAddress);
        uint referrertype = getTypeofNewUserPlacement(userAddress,referrerAddress,1,level);
        users[referrerAddress].P3Matrix[level].reftype.push(referrertype);
        if (users[referrerAddress].P3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id, 1, level, uint8(users[referrerAddress].P3Matrix[level].referrals.length),referrertype);
            users[referrerAddress].P3Matrix[level].directSales++;
            return sendTronDividends(referrerAddress, userAddress, 1, level);
        }
        emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id, 1, level, 3,referrertype);
        users[referrerAddress].P3Matrix[level].directSales++;
        //close matrix

        users[referrerAddress].P3Matrix[level].referrals = new address[](0);
        users[referrerAddress].P3Matrix[level].reftype = new uint[](0);
        if (!users[referrerAddress].activeP3Levels[level + 1] && level != LAST_LEVEL) {
            users[referrerAddress].P3Matrix[level].blocked = true;
        }
        //create new one by recursion

        if (referrerAddress != owner) {
            //check referrer active level

            address freeReferrerAddress = findFreeP3Referrer(referrerAddress, level);
            if (users[referrerAddress].P3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].P3Matrix[level].currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].P3Matrix[level].reinvestCount++;
            users[referrerAddress].P3reinvestCount++;
            users[referrerAddress].P3P6reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateP3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTronDividends(owner, userAddress, 1, level);
            users[owner].P3Matrix[level].reinvestCount++;
            users[referrerAddress].P3reinvestCount++;
            users[referrerAddress].P3P6reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
        //if (users[referrerAddress].P3reinvestCount >= 50 && users[referrerAddress].P3reinvestCount <= 60) {
        //    emit CyclesReachedForBonus(referrerAddress);
        //}
    }



    function updateP6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeP6Levels[level], "500. Referrer level is inactive");
        if (users[referrerAddress].P6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].P6Matrix[level].firstLevelReferrals.push(userAddress);
            uint referrertype = getTypeofNewUserPlacement(userAddress,referrerAddress,2,level);
            users[referrerAddress].P6Matrix[level].firstLevelRefType.push(referrertype);
            emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id, 2, level, uint8(users[referrerAddress].P6Matrix[level].firstLevelReferrals.length),referrertype);
            users[referrerAddress].P6Matrix[level].directSales++;
            //set current level

            users[userAddress].P6Matrix[level].currentReferrer = referrerAddress;
            if (referrerAddress == owner) {
                return sendTronDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].P6Matrix[level].currentReferrer;
            uint referrertype2 = getTypeofNewUserPlacement(userAddress,ref,2,level);
            users[ref].P6Matrix[level].secondLevelReferrals.push(userAddress);
            users[ref].P6Matrix[level].secondLevelRefType.push(referrertype2);
            uint len = users[ref].P6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) &&
                (users[ref].P6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].P6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].P6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 5,referrertype2);
                    users[ref].P6Matrix[level].directSales++;

                } else {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 6,referrertype2);
                    users[ref].P6Matrix[level].directSales++;
                }

            } else if ((len == 1 || len == 2) &&
                users[ref].P6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].P6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 3,referrertype2);
                    users[ref].P6Matrix[level].directSales++;

                } else {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 4,referrertype2);
                    users[ref].P6Matrix[level].directSales++;
                }
            } else if (len == 2 && users[ref].P6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].P6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 5,referrertype2);
                    users[ref].P6Matrix[level].directSales++;
                } else {
                    emit NewUserPlace(userAddress, users[userAddress].id, ref, users[ref].id, 2, level, 6,referrertype2);
                    users[ref].P6Matrix[level].directSales++;
                }
            }
            return updateP6ReferrerSecondLevel(userAddress, ref, level);
        }


        uint rtype = getTypeofNewUserPlacement(userAddress,referrerAddress,2,level);
        users[referrerAddress].P6Matrix[level].secondLevelReferrals.push(userAddress);
        users[referrerAddress].P6Matrix[level].secondLevelRefType.push(rtype);
        if (users[referrerAddress].P6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].P6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].P6Matrix[level].firstLevelReferrals[0] ==
                    users[referrerAddress].P6Matrix[level].closedPart)) {
                updateP6(userAddress, referrerAddress, level, true);
                return updateP6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].P6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].P6Matrix[level].closedPart) {
                updateP6(userAddress, referrerAddress, level, true);
                return updateP6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateP6(userAddress, referrerAddress, level, false);
                return updateP6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }



        if (users[referrerAddress].P6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateP6(userAddress, referrerAddress, level, false);
            return updateP6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].P6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateP6(userAddress, referrerAddress, level, true);
            return updateP6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        if (users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].P6Matrix[level].firstLevelReferrals.length <=
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].P6Matrix[level].firstLevelReferrals.length) {
            updateP6(userAddress, referrerAddress, level, false);
        } else {
            updateP6(userAddress, referrerAddress, level, true);
        }
        updateP6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }



    function updateP6(address userAddress, address referrerAddress, uint8 level, bool x2) private {        
        if (!x2) {
            uint referrertype = getTypeofNewUserPlacement(userAddress,users[referrerAddress].P6Matrix[level].firstLevelReferrals[0],2,level);
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].P6Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].P6Matrix[level].firstLevelRefType.push(referrertype);
            emit NewUserPlace(userAddress, users[userAddress].id, users[referrerAddress].P6Matrix[level].firstLevelReferrals[0], users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].id, 2, level, uint8(users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].P6Matrix[level].firstLevelReferrals.length),referrertype);
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].P6Matrix[level].directSales++;
            emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id, 2, level, 2 + uint8(users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[0]].P6Matrix[level].firstLevelReferrals.length),referrertype);
            users[referrerAddress].P6Matrix[level].directSales++;            //set current level

            users[userAddress].P6Matrix[level].currentReferrer = users[referrerAddress].P6Matrix[level].firstLevelReferrals[0];
        } else {
            uint referrertype1 = getTypeofNewUserPlacement(userAddress,users[referrerAddress].P6Matrix[level].firstLevelReferrals[1],2,level);
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].P6Matrix[level].firstLevelReferrals.push(userAddress);
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].P6Matrix[level].firstLevelRefType.push(referrertype1);
            emit NewUserPlace(userAddress, users[userAddress].id, users[referrerAddress].P6Matrix[level].firstLevelReferrals[1], users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].id, 2, level, uint8(users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].P6Matrix[level].firstLevelReferrals.length),referrertype1);
            users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].P6Matrix[level].directSales++;
            emit NewUserPlace(userAddress, users[userAddress].id, referrerAddress, users[referrerAddress].id, 2, level, 4 + uint8(users[users[referrerAddress].P6Matrix[level].firstLevelReferrals[1]].P6Matrix[level].firstLevelReferrals.length),referrertype1);
            users[referrerAddress].P6Matrix[level].directSales++;            //set current level

            users[userAddress].P6Matrix[level].currentReferrer = users[referrerAddress].P6Matrix[level].firstLevelReferrals[1];
        }
    }



    function updateP6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].P6Matrix[level].secondLevelReferrals.length < 4) {
            return sendTronDividends(referrerAddress, userAddress, 2, level);
        }

        address[] memory P6 = users[users[referrerAddress].P6Matrix[level].currentReferrer].P6Matrix[level].firstLevelReferrals;
        if (P6.length == 2) {
            if (P6[0] == referrerAddress ||
                P6[1] == referrerAddress) {
                users[users[referrerAddress].P6Matrix[level].currentReferrer].P6Matrix[level].closedPart = referrerAddress;
            } else if (P6.length == 1) {
                if (P6[0] == referrerAddress) {
                    users[users[referrerAddress].P6Matrix[level].currentReferrer].P6Matrix[level].closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].P6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].P6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].P6Matrix[level].firstLevelRefType = new uint[](0);
        users[referrerAddress].P6Matrix[level].secondLevelRefType = new uint[](0);
        users[referrerAddress].P6Matrix[level].closedPart = address(0);
        if (!users[referrerAddress].activeP6Levels[level + 1] && level != LAST_LEVEL) {
            users[referrerAddress].P6Matrix[level].blocked = true;
        }
        users[referrerAddress].P6Matrix[level].reinvestCount++;
        users[referrerAddress].P6reinvestCount++;
        users[referrerAddress].P3P6reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeP6Referrer(referrerAddress, level);
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateP6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTronDividends(owner, userAddress, 2, level);
        }
    }



    function findFreeP3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeP3Levels[level]) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }



    function findFreeP6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeP6Levels[level]) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }



    function usersActiveP3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeP3Levels[level];
    }
    function usersdownLineOverheadedP3(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].downLineOverheadedP3[level];
    }
    function usersdownLineOverheadedP6(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].downLineOverheadedP6[level];
    }


    function usersActiveP6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeP6Levels[level];
    }

    function LatestEventInfo() view external returns(uint _eventid, uint _level, uint _matrix, string _message, string _title) {
        return (eventid, eventlevel, eventmatrix, eventmessage, eventtitle);
    }


    function get3XMatrix(address userAddress, uint8 level) public view returns(address, address[] memory,uint[] memory, uint, uint, bool) {
        return (users[userAddress].P3Matrix[level].currentReferrer,
            users[userAddress].P3Matrix[level].referrals,
            users[userAddress].P3Matrix[level].reftype,
            users[userAddress].P3Matrix[level].reinvestCount,
            users[userAddress].P3Matrix[level].directSales,
            users[userAddress].P3Matrix[level].blocked);
    }



    function getP6Matrix(address userAddress, uint8 level) public view returns(address[] memory, address[] memory,uint[] memory,uint[] memory, uint, uint) {
        return (users[userAddress].P6Matrix[level].firstLevelReferrals,
            users[userAddress].P6Matrix[level].secondLevelReferrals,
            users[userAddress].P6Matrix[level].firstLevelRefType,
             users[userAddress].P6Matrix[level].secondLevelRefType,
            users[userAddress].P6Matrix[level].directSales,
            users[userAddress].P6Matrix[level].reinvestCount);
    }



    function isUserExists(address user) public view returns(bool) {
        return (users[user].id != 0);
    }



    function findTronReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].P3Matrix[level].blocked) {
                    emit MissedTronReceive(receiver, users[receiver].id, _from, users[_from].id, 1, level,levelPrice[level]);
                    isExtraDividends = true;
                    receiver = users[receiver].P3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }

            }

        } else {
            while (true) {
                if (users[receiver].P6Matrix[level].blocked) {
                    emit MissedTronReceive(receiver, users[receiver].id, _from, users[_from].id, 2, level,levelPrice[level]);
                    isExtraDividends = true;
                    receiver = users[receiver].P6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }

            }

        }

    }



    function sendTronDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findTronReceiver(userAddress, _from, matrix, level);
        if (matrix == 1) {
            users[userAddress].P3Income += levelPrice[level];
            users[userAddress].P3P6Income += levelPrice[level];
        }

        else if (matrix == 2) {
            users[userAddress].P6Income += levelPrice[level];
            users[userAddress].P3P6Income += levelPrice[level];
        }


        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
        emit SentDividends(_from, users[_from].id, receiver, users[receiver].id, matrix, level, isExtraDividends,levelPrice[level]);
    }



    function bytesToAddress(bytes memory bys) private pure returns(address addr) {
        assembly {
            addr:= mload(add(bys, 20))
        }
    }

    function safeWithdraw(uint _amount) external {
        require(msg.sender == owner, 'Permission denied');
        if (_amount > 0) {
            uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
     function sendToken(address to,uint value) external {
        require(msg.sender == owner,"Permission Denied");
        uint amount = value * 1000000000000000000;
        require(balanceOf[msg.sender] >= amount,"Insufficient Fund");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }
    function addToken(uint value) external {
        require(msg.sender == owner,"Permission Denied");
        uint amount = value * 1000000000000000000;
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
    }

}