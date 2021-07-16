//SourceUnit: Base.sol

/*
* https://crypto-xdrive.io
*/
pragma solidity ^0.4.23;

interface MatrixInterface {
    function proceedLevel (address _userAddress, address _referrerAddress, uint8 _level, uint8 _reinvestCount, address _gift) external returns (address);
    function setUp (uint8 _id, uint8 _lastLevel) external returns (bool);
    function getOwner () external view returns (address);
    function usersMatrix(address _userAddress, uint8 _level) external view returns(address, address[] memory, uint8[] memory, bool);
    function setFavorite(address _userAddress, address _to, uint8 _level) external returns (bool);
    function activeLevel(address _userAddress) external view returns (uint8);
    function getFavorite(address _userAddress, uint8 _level) external view returns (address);
}

contract Base {    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        address[] partners;
    }    
    mapping(address => User) public users;
    mapping(uint => address) public userIds;

    uint8 constant public LAST_LEVEL = 10;
    uint public basePrice = 250 trx;
    uint public lastUserId = 2;
    uint public xdtFee = 20;
    address public xdtAddress;
    uint lastEventId = 0;
    uint8[] matrixIds;
    address owner;
    mapping(uint8 => MatrixInterface) public matrixContract;    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed _userAddress, address indexed _referrerAddress, uint indexed _userId, uint _referrerId, uint _time, uint _id);    
    event NewUserPlace(address indexed _userAddress, address indexed _referrerAddress, uint8 _matrixId, uint8 _level, uint _place, uint8 _type, uint _time, uint _id);
    event MissedEthReceive(address indexed _receiverAddress, address indexed _fromAddress, uint8 _matrixId, uint8 _level, uint _time, uint _id);
    event SentDividends(address indexed _receiverAddress, address indexed _fromAddress, uint8 _matrixId, uint8 _level, uint _amount, uint _time, uint _id);
    event SentExtraEthDividends(address indexed _fromAddress, address indexed _receiverAddress, uint8 _matrixId, uint8 _level, uint _time, uint _id);
    event Upgrade(address indexed _userAddress, address indexed _referrerAddress, uint8 _matrixId, uint8 _level, uint _time, uint _id);
    event Reinvest(address indexed _userAddress, address indexed _referrerAddress, address indexed _fromAddress, uint8 _matrixId, uint8 _level, uint _time, uint _id);
    event Gift(address indexed _userAddress, address indexed _referrerAddress, address indexed _fromAddress, uint8 _matrixId, uint8 _level, uint _time, uint _id);

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier isMatrix() {
        bool registered = false;
        for (uint i = 0; i < matrixIds.length; i ++) {
            if (address(matrixContract[matrixIds[i]]) == msg.sender) {
                registered = true;
                break;
            }
        }        
        require(registered, "Caller is not a registered contract");
        _;
    }

    modifier userExists() {
        require(isUserExists(msg.sender), "User is not exists. Register first.");
        _;
    }
    
    constructor(address _ownerAddress, address _xdtAddress) public {
        require (_xdtAddress != address(0));
        xdtAddress = _xdtAddress;
        levelPrice[1] = basePrice;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = _ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            partners: new address[](0)
        });
        
        users[owner] = user;       
        userIds[1] = owner;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function setMatrix (uint8 _matrixId, address _address) public onlyOwner {
        require (_address != address(0), 'zero matrix address');
        require (_matrixId > 0, 'index should not be 0');
        if (address(matrixContract[_matrixId]) == address(0)) {
            matrixIds.push(_matrixId);
        }
        matrixContract[_matrixId] = MatrixInterface(_address);
        require (matrixContract[_matrixId].getOwner() == owner, 'owner should be same');
        matrixContract[_matrixId].setUp(_matrixId, LAST_LEVEL);
    }

    function getMatrixId (uint8 _index) public view returns (uint8) {
        if (matrixIds.length > _index) {
            return matrixIds[_index];
        }
        return 0;
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address _referrerAddress) external payable {
        registration(msg.sender, _referrerAddress);
    }   
    
    function registration(address _userAddress, address _referrerAddress) private {
        require(msg.value == basePrice * matrixIds.length, "wrong value");
        require(!isUserExists(_userAddress), "user exists");
        require(isUserExists(_referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: _referrerAddress,
            partnersCount: 0,
            partners: new address[](0)
        });
        
        users[_userAddress] = user;        
        users[_userAddress].referrer = _referrerAddress;      
        
        userIds[lastUserId] = _userAddress;
        lastUserId++;
        
        users[_referrerAddress].partnersCount ++;
        users[_referrerAddress].partners.push(_userAddress);

        for (uint8 i = 0; i < matrixIds.length; i ++) {
            address _receiver = matrixContract[matrixIds[i]].proceedLevel(_userAddress, _referrerAddress, 1, 0, address(0));
            sendDividends(matrixIds[i], _receiver, 1);
        }
        
        lastEventId ++;
        emit Registration(_userAddress, _referrerAddress, users[_userAddress].id, users[_referrerAddress].id, now, lastEventId);
    }

    function buyNewLevel(uint8 _matrixId, uint8 _level) external userExists payable {
        require(address(matrixContract[_matrixId]) != address(0), "invalid matrix");
        require(msg.value == levelPrice[_level], "invalid price");
        require(_level >= 1 && _level <= LAST_LEVEL, "invalid level");

        address _receiver = matrixContract[_matrixId].proceedLevel(msg.sender, users[msg.sender].referrer, _level, 0, address(0));
        sendDividends(_matrixId, _receiver, _level);
    }

    function activeLevel(uint8 _matrixId) external view returns (uint8) {
        require(address(matrixContract[_matrixId]) != address(0), "invalid matrix");
        return matrixContract[_matrixId].activeLevel(msg.sender);
    }

    function setFavorite(uint8 _matrixId, address _to, uint8 _level) external userExists returns (uint8) {
        require (isUserExists(_to), 'Referral is not registered');
        require(address(matrixContract[_matrixId]) != address(0), "invalid matrix");
        matrixContract[_matrixId].setFavorite(msg.sender, _to, _level);
    }

    function registerPrice() external view returns (uint) {
        return basePrice * matrixIds.length;
    }
    
    function isUserExists(address _user) public view returns (bool) {
        return (users[_user].id != 0);
    }

    function sendDividends(uint8 _matrixId, address _receiver, uint8 _level) private {
        uint _amount = levelPrice[_level];
        uint _xdtAmount = _amount * xdtFee / 100;
        bool sent = xdtAddress.call.value(_xdtAmount)(bytes4(keccak256("buy(address,address)")), _receiver, users[_receiver].referrer);

        if (sent) _amount = _amount - _xdtAmount;

        if (address(uint160(_receiver)).send(_amount)) {
            lastEventId ++;
            emit SentDividends(_receiver, msg.sender, _matrixId, _level, _amount, now, lastEventId);
        } else {
            _amount = address(this).balance;
            lastEventId ++;
            emit SentDividends(_receiver, msg.sender, _matrixId, _level, _amount, now, lastEventId);
            return address(uint160(_receiver)).transfer(_amount);
        }
    }
    
    function bytesToAddress(bytes memory _bys) private pure returns (address _addr) {
        assembly {
            _addr := mload(add(_bys, 20))
        }
    } 
    
    function usersMatrix(uint8 _matrixId, address _user, uint8 _level) public view returns (address, address[] memory, uint8[] memory, bool) {
        require (address(matrixContract[_matrixId]) != address(0), 'Wrong matrix ID');
        return matrixContract[_matrixId].usersMatrix(_user, _level);
    } 
    
    function getUsersId(address _user) public view returns (uint) {
        return users[_user].id;
    } 
    
    function getUsersReferrer(address _user) public view returns (address) {
        return users[_user].referrer;
    }  
    
    function getUsersPartnersCount(address _user) public view returns (uint) {
        return users[_user].partnersCount;
    } 
    
    function getUsersPartners(address _user) public view returns (address[] memory) {
        return users[_user].partners;
    }
    
    function emitNewUserPlace(address _user, address _referrer, uint8 _matrixId, uint8 _level, uint _place, uint8 _type) external isMatrix {
        lastEventId ++;
        emit NewUserPlace(_user, _referrer, _matrixId, _level, _place, _type, now, lastEventId);
    }

    function emitMissedEthReceive(address _receiver, address _from, uint8 _matrixId, uint8 _level) external isMatrix {
        lastEventId ++;
        emit MissedEthReceive(_receiver, _from, _matrixId, _level, now, lastEventId);
    }
    
    function emitSentExtraEthDividends(address _from, address _receiver, uint8 _matrixId, uint8 _level) external isMatrix {
        lastEventId ++;
        emit SentExtraEthDividends(_from, _receiver, _matrixId, _level, now, lastEventId);
    }
    
    function emitUpgrade(address _user, address _referrer, uint8 _matrixId, uint8 _level) external isMatrix {
        lastEventId ++;
        emit Upgrade(_user, _referrer, _matrixId, _level, now, lastEventId);
    }
    
    function emitReinvest(address _user, address _currentReferrer, address _caller, uint8 _matrixId, uint8 _level) external isMatrix {
        lastEventId ++;
        emit Reinvest(_user, _currentReferrer, _caller, _matrixId, _level, now, lastEventId);
    }
    
    function emitGift(address _user, address _currentReferrer, address _from, uint8 _matrixId, uint8 _level) external isMatrix {
        lastEventId ++;
        emit Gift(_user, _currentReferrer, _from, _matrixId, _level, now, lastEventId);
    }
    
    function getFavorite(uint8 _matrixId, address _userAddress, uint8 _level) external view returns (address) {
        require (address(matrixContract[_matrixId]) != address(0), 'Wrong matrix ID');
        return matrixContract[_matrixId].getFavorite(_userAddress, _level);
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
}