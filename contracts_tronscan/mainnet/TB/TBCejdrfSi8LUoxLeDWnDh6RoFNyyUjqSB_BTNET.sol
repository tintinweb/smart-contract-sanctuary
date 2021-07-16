//SourceUnit: Btronet.sol

pragma solidity ^0.5.7;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}


contract Ownable {

  address public owner;
  
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }
  
  function withdraw(uint amount) public onlyOwner{
    address(uint160(owner)).call.value(amount)("");
  }
  
}

contract BTRO is Ownable {

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event chargeLevelEvent(address indexed _user, uint expireDate, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, bool success, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);

    mapping (uint => address) INITIAL_ACCOUNTS;
    mapping (uint => uint) public LEVEL_PRICE;
    uint REFERRER_1_LEVEL_LIMIT = 3;
    uint PERIOD_LENGTH = 183 days;
    uint CHARGIN_PRICE = 2650 trx;

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        uint expireDate;
        string securityKey;
        uint left;
        uint middle;
        uint right;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;


    constructor() public {

        LEVEL_PRICE[1] = 265 trx;
        LEVEL_PRICE[2] = 265 trx;
        LEVEL_PRICE[3] = 238.5 trx;
        LEVEL_PRICE[4] = 212 trx;
        LEVEL_PRICE[5] = 212 trx;
        LEVEL_PRICE[6] = 212 trx;
        LEVEL_PRICE[7] = 132.5 trx;
        LEVEL_PRICE[8] = 132.5 trx;
        LEVEL_PRICE[9] = 132.5 trx;
        LEVEL_PRICE[10] = 79.5 trx;
        LEVEL_PRICE[11] = 79.5 trx;
        LEVEL_PRICE[12] = 79.5 trx;
        LEVEL_PRICE[13] = 26.5 trx;
        LEVEL_PRICE[14] = 26.5 trx;
        LEVEL_PRICE[15] = 26.5 trx;
        
        // initial accounts
        addUser(address(0x413222927026D83CF0771657CAB32D25905F4E6658), 0, 99999999999, '');
        addUser(address(0x41CD2C73339176B05908569FA3609C9CB5A9394CA9), 1, 99999999999, '');
        addUser(address(0x417D8642DE70D0BE911EC0EE1CA8B003B2F55AE93B), 1, 99999999999, '');
        addUser(address(0x41CCDDFA9DA4BE29B17F29352C434E988E009D8826), 1, 99999999999, '');
        addUser(address(0x41F1280A62FC61DA7206642964D69676EB115E93F9), 2, 99999999999, '');
        addUser(address(0x410311D6621D605F3882FA937788C050666F695985), 2, 99999999999, '');
        addUser(address(0x4154033A570563DEC41B2881AAA696AAB7122DEE15), 2, 99999999999, '');
        addUser(address(0x41E2C40E8FB4D8C46114FD6237136830A5F02740CA), 5, 1612703475, '');
        addUser(address(0x41415ACF7B48C7B7736998C0726069CEEA0D2DBF6A), 6, 1612706799, '');
        addUser(address(0x4107E9BCE3680B95B256DB3F9E79448A094EAFE2B0), 9, 1612715370, '');
        addUser(address(0x4186E2144D64428FECF7B9A29496E51BC911C5C629), 10, 1612718955, '');
        addUser(address(0x41BCC5A19613128EDF7F0EB6DB0DDDCD7A8EAA9B04), 11, 1612720536, '');
        addUser(address(0x41CBDE90AAAA54C2B9E88DCA45EEA91D5EB6634422), 12, 1612727517, '');
        

    }
    
    function () external payable {

        if(users[msg.sender].isExist){
            chargeLevel();
        } else {
            
            address referrer = bytesToAddress(msg.data);
            regUser(referrer, "");
            
        }
    }
    
    function regUser(address _referrerAddr, string memory securityKey) public payable {
        
        require(!users[msg.sender].isExist, 'User exist');

        require(msg.value==CHARGIN_PRICE, 'Incorrect Value');
        
        uint _referrerID = 0;
        
        if (users[_referrerAddr].isExist){
            _referrerID = users[_referrerAddr].id;
        } else {
            revert('Incorrect referrer address');
        }


        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT)
        {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }


        addUser(msg.sender, _referrerID, now, securityKey);

        chargeLevel();

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
    
    function addUser(address user_address, uint _referrerID, uint expireDate, string memory securityKey) private {
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            referral : new address[](0),
            expireDate : expireDate,
            securityKey : securityKey,
            left: 0,
            middle: 0,
            right: 0
        });

        users[user_address] = userStruct;
        userList[currUserID] = user_address;

        users[userList[_referrerID]].referral.push(user_address);

        uint _curID = users[user_address].id;
        address referer = userList[_referrerID];
        while(users[referer].isExist){
            
            for(uint r=0; r<users[referer].referral.length; r++){
                if(users[referer].referral[r]==userList[_curID]){
                    if(r==0){
                        users[referer].left++;
                    }else if(r==1){
                        users[referer].middle++;
                    }else {
                        users[referer].right++;
                    }
                    break;
                }
            }

            _curID = users[referer].id;
            _referrerID = users[referer].referrerID;
            referer = userList[_referrerID];
            
        }

        
        
        
    }
    
    function chargeLevel() public payable {
        require(users[msg.sender].isExist, 'User not exist');

        require(msg.value==CHARGIN_PRICE, 'Incorrect Value');

        users[msg.sender].expireDate += PERIOD_LENGTH;
    
        uint _referrerID = users[msg.sender].referrerID;
        address referer = userList[_referrerID];
        uint _price = CHARGIN_PRICE;
        
        for(uint _l=1; _l<=15; _l++){
        
            if(!users[referer].isExist)
                break;
                
            if(users[referer].expireDate >= now ){
                (bool success, ) = address(uint160(referer)).call.value(LEVEL_PRICE[_l])("");
                if(success){
                    _price = _price - LEVEL_PRICE[_l];
                }
                emit getMoneyForLevelEvent(referer, msg.sender, _l, success, now);
            } else {
                emit lostMoneyForLevelEvent(referer, msg.sender, _l, now);
            }
            
            referer = userList[users[referer].referrerID];
            
        }
        
        (bool success, ) = address(uint160(owner)).call.value(_price)("");

        emit chargeLevelEvent(msg.sender, users[msg.sender].expireDate, now);
    }
    
    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT){
            return _user;
        }

        address[] memory referrals = new address[](363);
        referrals[0] = users[_user].referral[0]; 
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i =0; i<363;i++){
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT){
                if(i<120){
                    referrals[(i+1)*3] = users[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = users[referrals[i]].referral[2];
                }
            }else{
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;

    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address  addr ) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function setSecurityKey(string memory securityKey) public {
        
        require(users[msg.sender].isExist, 'User not exist');
        
        users[msg.sender].securityKey = securityKey;
        
    }

}