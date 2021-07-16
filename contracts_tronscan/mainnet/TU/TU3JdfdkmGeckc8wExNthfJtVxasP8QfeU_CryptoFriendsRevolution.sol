//SourceUnit: CryptoFriendsRevolution.sol

pragma solidity ^0.4.25;


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
  address public manager;
  address public ownerWallet;

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}

contract CryptoFriendsRevolution is Ownable {
	using SafeMath for uint256;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    event prolongateLevelEvent(address indexed _user, uint _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
    //------------------------------

    mapping (uint => uint) public LEVEL_PRICE;
    uint REFERRER_1_LEVEL_LIMIT = 3;
    uint PERIOD_LENGTH = 35 days;


    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        address[] referral;
        mapping (uint => uint) levelExpired;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint => bool) public userRefComplete;	
	mapping (address => uint) public profitStat;
	uint[8] public levelStat;
    uint public currUserID = 0;
	uint refCompleteDepth = 1;

    constructor(address _manager) public {
		owner = msg.sender;
		manager = _manager;
		ownerWallet = msg.sender;
	
        LEVEL_PRICE[1] = 200000000; //200trx
        LEVEL_PRICE[2] = LEVEL_PRICE[1] * 3;
        LEVEL_PRICE[3] = LEVEL_PRICE[2] * 3;
        LEVEL_PRICE[4] = LEVEL_PRICE[3] * 3;
        LEVEL_PRICE[5] = LEVEL_PRICE[4] * 3;
        LEVEL_PRICE[6] = LEVEL_PRICE[5] * 3;
        LEVEL_PRICE[7] = LEVEL_PRICE[6] * 3;
        LEVEL_PRICE[8] = LEVEL_PRICE[7] * 3;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        users[ownerWallet].levelExpired[1] = 77777777777;
        users[ownerWallet].levelExpired[2] = 77777777777;
        users[ownerWallet].levelExpired[3] = 77777777777;
        users[ownerWallet].levelExpired[4] = 77777777777;
        users[ownerWallet].levelExpired[5] = 77777777777;
        users[ownerWallet].levelExpired[6] = 77777777777;
        users[ownerWallet].levelExpired[7] = 77777777777;
        users[ownerWallet].levelExpired[8] = 77777777777;
    }

    function regUser(address _referrer) public payable {
        require(!users[msg.sender].isExist, 'User exist');

		uint _referrerID;
		
		if (users[_referrer].isExist){
			_referrerID = users[_referrer].id;
		} else if (_referrer == address(0)) {
			_referrerID = findFirstFreeReferrer();
			refCompleteDepth = _referrerID;
		} else {
			revert('Incorrect referrer');
		}		

        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');

        require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');


        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT)
        {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }


        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
        users[msg.sender].levelExpired[2] = 0;
        users[msg.sender].levelExpired[3] = 0;
        users[msg.sender].levelExpired[4] = 0;
        users[msg.sender].levelExpired[5] = 0;
        users[msg.sender].levelExpired[6] = 0;
        users[msg.sender].levelExpired[7] = 0;
        users[msg.sender].levelExpired[8] = 0;

        users[userList[_referrerID]].referral.push(msg.sender);
		
		if (users[userList[_referrerID]].referral.length == 3) {
			userRefComplete[_referrerID] = true;
		}

        payForLevel(1, msg.sender);

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist');

        require( _level>0 && _level<=8, 'Incorrect level');

        if(_level == 1){
            require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');
            users[msg.sender].levelExpired[1] += PERIOD_LENGTH;
        } else {
            require(msg.value==LEVEL_PRICE[_level], 'Incorrect Value');

            for(uint l =_level-1; l>0; l-- ){
                require(users[msg.sender].levelExpired[l] >= now, 'Buy the previous level');
            }

            if(users[msg.sender].levelExpired[_level] == 0){
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            } else {
                users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
            }
        }
        payForLevel(_level, msg.sender);
        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if(_level == 1 || _level == 5){
            referer = userList[users[_user].referrerID];
        } else if(_level == 2 || _level == 6){
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if(_level == 3 || _level == 7){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if(_level == 4 || _level == 8){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if(!users[referer].isExist){
            referer = userList[1];
        }

        if(users[referer].levelExpired[_level] >= now ){
			if (referer == userList[1]) {
	            referer.send(LEVEL_PRICE[_level].mul(70).div(100));
				manager.send(LEVEL_PRICE[_level].mul(30).div(100));
			} else {
				referer.send(LEVEL_PRICE[_level]);
				profitStat[referer] += LEVEL_PRICE[_level];
			}
			levelStat[_level-1]++;			
            emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
        } else {
            emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            payForLevel(_level,referer);
        }
		
    }
	
	function getRefDepth() public returns(uint) {
		return refCompleteDepth;
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
		if (noFreeReferrer) {
			freeReferrer = userList[findFirstFreeReferrer()];
			require(freeReferrer != address(0));
		}
        return freeReferrer;

    }
	
    function findFirstFreeReferrer() public view returns(uint) {	
		for(uint i = refCompleteDepth; i < 500+refCompleteDepth; i++) {
			if (!userRefComplete[i]) {
				return i;
			}
		}
	}

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserLevelExpired(address _user) public view returns(uint[8] levelExpired) {
		for (uint i = 0; i<8; i++) {
			if (now < users[_user].levelExpired[i+1]) {
				levelExpired[i] = users[_user].levelExpired[i+1].sub(now);
			} 
		}
    }

}