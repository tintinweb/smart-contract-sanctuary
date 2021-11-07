//SourceUnit: USDT-Forsage.sol

pragma solidity >=0.5.15;

//SPDX-License-Identifier: Apache 2.0

interface TRC20_Interface {

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transferFrom(address _from, address _to, uint _value) external returns (bool);

    function transfer(address direccion, uint cantidad) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
    
    function decimals() external view returns (uint256);
}

contract THE_MONOPOLY_CLUB {

    TRC20_Interface USDT_Contract;

    TRC20_Interface OTRO_Contract;

    address public tokenUSDT;
    address public tokenOTRO;

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

    uint8 public currentStartingLevel = 1;
    uint8 public constant LAST_LEVEL = 15;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId = 2;
    address payable public owner;

    mapping(uint8 => uint) public levelPrice;
    mapping(uint8 => uint) public ownerPrice;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);


    constructor(address _tokenUSDT)  public {

        (tokenUSDT, tokenOTRO) = (_tokenUSDT,_tokenUSDT);

        (USDT_Contract, OTRO_Contract) = (TRC20_Interface(_tokenUSDT),TRC20_Interface(_tokenUSDT));

        levelPrice[1] = 20 * 10**USDT_Contract.decimals();
        ownerPrice[4] = 4 * 10**USDT_Contract.decimals();
        uint8 i;
        for (i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
            if (i >= 5) {
                ownerPrice[i] = ownerPrice[i-1] * 2;
            } 
        }

        owner = msg.sender;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });

        users[owner] = user;
        idToAddress[1] = owner;

        for (i = 1; i <= LAST_LEVEL; i++) {
            users[owner].activeX3Levels[i] = true;
        }
    }

    function ChangeLevelPrice(uint8 _level, uint _value) public returns (bool){

        require( msg.sender == owner );

        levelPrice[_level] = _value * 10**USDT_Contract.decimals();
        
        return true;
    }

     function ChangeOwnerPrice(uint8 _level, uint _value) public returns (bool){

        require( msg.sender == owner );

        ownerPrice[_level] = _value * 10**USDT_Contract.decimals();

        return true;
    }

    function ChangeTokenUSDT(address _tokenTRC20) public returns (bool){

        require( msg.sender == owner );

        USDT_Contract = TRC20_Interface(_tokenTRC20);
        tokenUSDT= _tokenTRC20;

        return true;

    }

    function ChangeTokenOTRO(address _tokenTRC20) public returns (bool){

        require( msg.sender == owner );

        OTRO_Contract = TRC20_Interface(_tokenTRC20);
        tokenOTRO = _tokenTRC20;

        return true;

    }

    function withdrawLostTRXFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        owner.transfer(address(this).balance);
    }

    function withdrawLostUSDTFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        USDT_Contract.transfer(owner, USDT_Contract.balanceOf(address(this)));
    }

    function withdrawLostOTROFromBalance() public {
        require(msg.sender == owner, "onlyOwner");
        OTRO_Contract.transfer(owner, OTRO_Contract.balanceOf(address(this)));
    }


    function registrationExt(address referrerAddress, uint _value) external {
        require(USDT_Contract.balanceOf(msg.sender) >= _value , "insuficient balance");
        registration(msg.sender, referrerAddress, _value);
    }

    function buyNewLevel(uint8 level, uint _value) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(USDT_Contract.balanceOf(msg.sender) >= _value , "insuficient balance");
        require(_value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(users[msg.sender].activeX3Levels[level-1], "buy previous level first");
        require(!users[msg.sender].activeX3Levels[level], "level already activated");

        if (users[msg.sender].x3Matrix[level-1].blocked) {
            users[msg.sender].x3Matrix[level-1].blocked = false;
        }

        address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
        users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
        users[msg.sender].activeX3Levels[level] = true;
        updateX3Referrer(msg.sender, freeX3Referrer, level);

        emit Upgrade(msg.sender, freeX3Referrer, 1, level);

    
    }

    function registration(address userAddress, address referrerAddress, uint _value) private {
        require(USDT_Contract.balanceOf(msg.sender) >= _value , "insuficient balance");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        require(_value == levelPrice[currentStartingLevel] , "invalid registration cost");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeX3Levels[1] = true;

        lastUserId++;

        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
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
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }


    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }


    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }


    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                
                return (receiver, isExtraDividends);
                
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        if( level >= 4 ){
            USDT_Contract.transferFrom( msg.sender, address(uint160(owner)), ownerPrice[level]);
        }

        if ( !USDT_Contract.transferFrom( msg.sender, address(uint160(receiver)), levelPrice[level]-ownerPrice[level] ) )   {
            USDT_Contract.transfer(address(uint160(owner)), USDT_Contract.balanceOf(address(this)) );
            return;
        }

        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}