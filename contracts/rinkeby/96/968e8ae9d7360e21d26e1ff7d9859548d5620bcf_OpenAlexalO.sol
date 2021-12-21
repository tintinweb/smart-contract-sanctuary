/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity ^0.5.14;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}


contract OpenAlexalO {
    using SafeMath for uint256;

    uint public constant referrerLimit = 2;

    struct UserInfo {
        bool isExist;
        uint id;
        uint referrerID;
        uint currentLevel;
        uint totalEarningEth;
        address[] referral;
    }
    
    address public owner;
    address public charity; // charity wallet
    address public burner;  // burner wallet
    uint public currentId = 0;
    bool public lockStatus;
    uint256 public loopLimit = 64;

    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public profitPcent;
    mapping (address => UserInfo) public users;
    mapping (uint => address) public userList;
    mapping (address => mapping (uint => uint)) public EarnedEth;
    mapping (address => uint) public createdDate;
    
    event regLevelEvent(address indexed UserAddress, address indexed ReferrerAddress, uint Time);
    event buyLevelEvent(address indexed UserAddress, uint Levelno, uint Time);
    event getMoneyForLevelEvent(address indexed UserAddress, uint UserId, address indexed ReferrerAddress, uint ReferrerId, uint Levelno, uint LevelPrice, uint Time);
    event SetLoopLimit(address caller, uint256 newLimit);

    constructor(address _owner, address _charity, address _burner) public {
        require((_owner != address(0x000)) && (_charity != address(0x000)) && (_burner != address(0x000)), "Zero address");
        owner = _owner;
        charity = _charity;
        burner = _burner;

        LEVEL_PRICE[1] = 10 ether;
        LEVEL_PRICE[2] = 20 ether;
        LEVEL_PRICE[3] = 30 ether;
        LEVEL_PRICE[4] = 40 ether;
        LEVEL_PRICE[5] = 50 ether;
        LEVEL_PRICE[6] = 100 ether;
        LEVEL_PRICE[7] = 200 ether;
        LEVEL_PRICE[8] = 300 ether;
        LEVEL_PRICE[9] = 500 ether;
        LEVEL_PRICE[10] = 750 ether;
        LEVEL_PRICE[11] = 1000 ether;
        LEVEL_PRICE[12] = 2000 ether;

        profitPcent[1] = 36; // upline 1 profit
        profitPcent[2] = 27; // upline 2 profit
        profitPcent[3] = 18; // upline 3 profit
        profitPcent[4] = 9;  // upline 4 profit
        profitPcent[5] = 5;  // for charity
        profitPcent[6] = 5;  // burnt out of circulation

    } 

    modifier isLock(){
        require(lockStatus == false, "Contract locked");
        _;
    }

    modifier checkPayment(){
        require(msg.value == LEVEL_PRICE[1], "Incorrect value");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    /**
     * @dev User registration
     */ 
    function regUser(uint _referrerID) external isLock checkPayment payable {
        require(users[msg.sender].isExist == false, "User exist");
        require(_referrerID > 0 && _referrerID <= currentId, "Incorrect referrer Id");
        
        
        if (users[userList[_referrerID]].referral.length >= referrerLimit) 
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserInfo memory userStruct;
        currentId++;
        
        userStruct = UserInfo({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningEth:0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[userList[_referrerID]].referral.push(msg.sender);
        createdDate[msg.sender] = now;

        payForLevelOne(1, msg.sender, msg.value);
        _takeFee((msg.value*profitPcent[5]/100), (msg.value*profitPcent[6]/100));

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function _takeFee(uint256 _charityFee, uint256 _burnerFee ) internal {
            require((address(uint160(charity)).send(_charityFee)) && 
                    (address(uint160(burner)).send(_burnerFee)), "Transfer failed" );
    }
    
    /**
     * @dev To buy the next level by User
     */ 
    function buyLevel(uint256 _level) external isLock checkPayment payable {
        require(users[msg.sender].isExist, "User not exist"); 
        require(_level > 0 && _level <= 12, "Incorrect level");

        users[msg.sender].currentLevel = _level;
                  
        payForLevel(_level, msg.sender, msg.value);
        _takeFee((msg.value*profitPcent[5]/100), (msg.value*profitPcent[6]/100));

        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint _level, address _userAddress, uint256 levelPrice) internal {
      
        uint256 maxProfit = 90;
        uint256 unsettled;
        address ref = userList[users[_userAddress].referrerID];
        for(uint256 i=1; i<=loopLimit; i++){
            if( (ref == userList[1]) || (i == loopLimit) ){
                sendPayment(userList[1], (levelPrice*maxProfit/100), _level, levelPrice);
                break;
            } else{ 
                if(i <= 4){unsettled = unsettled + profitPcent[i];}

                if(users[_userAddress].currentLevel >= _level){
                    sendPayment(ref, (levelPrice*unsettled/100), _level, levelPrice);
                    maxProfit = maxProfit - unsettled;
                    unsettled = 0;
                    if(maxProfit == 0){break;}
                }        
            } 
                
                ref = userList[users[ref].referrerID];
            }
       }
    
    
    /**
     * @dev Internal function for payment
     */ 
    function payForLevelOne(uint _level, address _userAddress, uint256 levelPrice) internal {
      
        uint256 maxProfit = 90;
        address ref = userList[users[_userAddress].referrerID];
        for(uint256 i=1; i<=4; i++){
            if(ref == userList[1]){
                sendPayment(ref, (levelPrice*maxProfit/100), _level, levelPrice);
                break;
            } else{ 
                sendPayment(ref, (levelPrice*profitPcent[i]/100), _level, levelPrice);
                maxProfit = maxProfit - profitPcent[i];
                ref = userList[users[ref].referrerID];
            }
       }
    }

    function sendPayment(address _receiver, uint256 _amount, uint256 _level, uint256 levelPrice) private {
        require((address(uint160(_receiver)).send(_amount)), "Transfer failed" );           
        users[_receiver].totalEarningEth = users[_receiver].totalEarningEth.add(_amount);
        EarnedEth[_receiver][_level] = EarnedEth[_receiver][_level].add(_amount);
        emit getMoneyForLevelEvent(msg.sender, users[msg.sender].id, _receiver, users[_receiver].id, _level, levelPrice, now);
    }
    
    /**
     * @dev Contract balance withdraw
     */ 
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns (bool) {
        require(_toUser != address(0), "Zero address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
            
    /**
     * @dev Update contract status
     */ 
    function contractLock(bool _lockStatus) public onlyOwner returns (bool) {
        lockStatus = _lockStatus;
        return true;
    }    
    
    /**
     * @dev Update the loop limit
     */ 
    function setLoopLimit(uint256 _newLimit) public returns (bool) {        
        loopLimit = _newLimit;
        emit SetLoopLimit(msg.sender, _newLimit);
        return true;
    }   

    /**
     * @dev View free Referrer Address
     */ 
    function findFreeReferrer(address _userAddress) public view returns (address) {
        if (users[_userAddress].referral.length < referrerLimit) 
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 254; i++) { 
            if (users[referrals[i]].referral.length == referrerLimit) {
                if (i < 126) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[1];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }
    
    /**
     * @dev Total earned ETH
     */
    function getTotalEarnedEther() public view returns (uint) {
        uint totalEth;
        for (uint i = 1; i <= currentId; i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        return totalEth;
    }
        
   /**
     * @dev View referrals
     */ 
    function viewUserReferral(address _userAddress) external view returns (address[] memory) {
        return users[_userAddress].referral;
    }
    
    // fallback
    function () external payable {
        revert("Invalid Transaction");
    }
}