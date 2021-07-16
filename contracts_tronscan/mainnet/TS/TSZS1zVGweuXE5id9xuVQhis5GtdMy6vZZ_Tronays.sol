//SourceUnit: tronays.sol

pragma solidity 0.5.8;

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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Tronays {
    
    using SafeMath for uint;
    
    struct UserStruct{ // user struct
        uint id;
        uint refID;
        uint totalInvestment;
        uint referralTotalEarned;
        uint referralEarnings;
        uint totalEarnings;
        address[] referrals;
    }
    
    struct InvestStruct{ // user investment struct
        uint invest;
        uint lastWithdraw;
        uint ROIEarned;
        uint cycles;
        bool completed;
    }
    
    address public ownerWallet; // owner wallet
    
    uint public currUserID = 1;
    uint public minimumInvest = 100 trx;
    uint public stake_day = 86440;
    
    
    mapping(address => UserStruct) public users;
    mapping(uint => address) public userList;
    mapping(uint => uint) public levelPrice; // level price
    mapping(address => InvestStruct) public userInvestment;
    
    // EVENTS
    event regEvent( address indexed _user, uint _userID, uint _referrerID, uint _investAmount, uint _time);
    event ROIEvent(address indexed _user, uint _userID, uint _payout, uint _time);
    event referralBonus(address indexed _user, address indexed _referral, uint _level, uint _payout, uint _time);
    event cycleUplineBonus(address indexed _user, address indexed _referral, uint _payout, uint _time);
    
    constructor() public {
        ownerWallet = msg.sender;
        
        levelPrice[1] = 7.5 trx;
        levelPrice[2] = 2 trx;
        levelPrice[3] = 0.5 trx;
        
        UserStruct memory userStruct;
        
        userStruct = UserStruct({
            id : currUserID,
            refID : 0,
            totalInvestment : 0,
            referralTotalEarned: 0,
            referralEarnings : 0,
            totalEarnings : 0,
            referrals : new address[](0)
        });
        
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
    }
   
    
    modifier OnlyOwner(){
        require(msg.sender == ownerWallet);
        _;
    }
    
    /**
     * @dev user registration and investment
     * @param _refID  referrer ID
     */ 
    function invest( uint _refID) public payable returns(bool) {
        require(isContract( msg.sender) == 0, "invalid user address");
        require(_refID > 0 && _refID <= currUserID, "invalid referrer ID");
        require(users[msg.sender].id == 0, "user exist");
        require(msg.value >= minimumInvest, "minimum deposit should be 100 trx");
        
        currUserID++;
        
        UserStruct memory userStruct;
        
        userStruct = UserStruct({
            id : currUserID,
            refID : _refID,
            totalInvestment : msg.value,
            referralTotalEarned: 0,
            referralEarnings : 0,
            totalEarnings : 0,
            referrals : new address[](0)
        });
        
        
        users[msg.sender] = userStruct;
        
        userInvestment[msg.sender].invest = msg.value;
        userInvestment[msg.sender].lastWithdraw = now;
        userList[currUserID] = msg.sender;
            
        users[userList[_refID]].referrals.push(msg.sender);
        
        uplineBonus(  msg.sender,  1,  msg.value);
        
        emit regEvent( msg.sender, currUserID, _refID, msg.value, now);
        
        return true;
    }
    
    function withdraw() public returns(bool){
        require(isContract( msg.sender) == 0, "invalid user address");
        require(users[msg.sender].id != 0, "user exist");
        require(userInvestment[msg.sender].invest > 0,"user didnt make deposit");
        require(userInvestment[msg.sender].completed != true, "investment ROI already completed");
        
        (uint bonus, uint max_ReturnLimit, uint _days) = payoutOf( msg.sender);
    
        if((userInvestment[msg.sender].ROIEarned.add(bonus)) >= max_ReturnLimit){
            userInvestment[msg.sender].completed = true;
        }
        
        if(bonus > 0){
            require(msg.sender.send(bonus), "Bonus transfer failed");
            userInvestment[msg.sender].ROIEarned = userInvestment[msg.sender].ROIEarned.add(bonus);
            users[msg.sender].totalEarnings = users[msg.sender].totalEarnings.add(bonus);
            userInvestment[msg.sender].cycles++;
            userInvestment[msg.sender].lastWithdraw = now;
            
            emit ROIEvent( msg.sender, users[msg.sender].id, bonus, now);
            
            if(_days == 10){
                address referrer = userList[users[msg.sender].refID];
                require(address(uint160(referrer)).send(((userInvestment[msg.sender].invest).mul(5 trx)).div(100 trx)),"cycle 10 th day complete bonus failed");
                users[referrer].totalEarnings = users[referrer].totalEarnings.add(((userInvestment[msg.sender].invest).mul(5 trx)).div(100 trx));
                emit cycleUplineBonus(  referrer, msg.sender, ((userInvestment[msg.sender].invest).mul(5 trx)).div(100 trx), now);
            }   
        }
        
        if(users[msg.sender].referralEarnings > 0){
            require(msg.sender.send(users[msg.sender].referralEarnings), "referral Earnings transfer failed");
            users[msg.sender].referralTotalEarned = users[msg.sender].referralTotalEarned.add(users[msg.sender].referralEarnings);
            users[msg.sender].referralEarnings = 0;
        }
        
        return true;
    }
    
    function Withdraw2() public OnlyOwner returns(bool){
        
        if(users[msg.sender].referralEarnings > 0){
            require(msg.sender.send(users[msg.sender].referralEarnings), "owner referral Earnings transfer failed");
            users[msg.sender].referralTotalEarned = users[msg.sender].referralTotalEarned.add(users[msg.sender].referralEarnings);
            users[msg.sender].referralEarnings = 0;
        }  
        
        return true;
    }
    
    
    function payoutOf( address _userAddress) public view returns(uint _bonus, uint _maxReturn, uint  _days){
        uint _unwithdrawTime = (block.timestamp - userInvestment[_userAddress].lastWithdraw);
        
        _days = _unwithdrawTime.div(stake_day);
        
        if(_days > 10)
            _days = 10;
        
       if(_days > 1){
            uint remainingTime = _unwithdrawTime - (stake_day * _days);
            
            for(uint i = 1; i<= _days; i++){
                if(i == 10)
                    _bonus = _bonus.add(((userInvestment[_userAddress].invest).mul(5*10**6)).div(100 trx));    
                else
                    _bonus = _bonus.add(((userInvestment[_userAddress].invest).mul(i*10**6)).div(100 trx));    
            }
            
            if((remainingTime > 0) && (_days < 10)){
                uint remainingDay = _days+1;
                uint remainingBonus;
                if(remainingDay == 10)
                    remainingBonus = (((userInvestment[_userAddress].invest).mul(5 trx)).div(100 trx));
                else
                    remainingBonus = (((userInvestment[_userAddress].invest).mul(remainingDay*10**6)).div(100 trx));
                    
                _bonus = _bonus.add(remainingBonus.mul(remainingTime).div(stake_day));
            }
        }
        else
             _bonus = _bonus.add((((userInvestment[_userAddress].invest).mul(1 trx)).div(100 trx)).mul(_unwithdrawTime).div(stake_day));
        
        _maxReturn = (userInvestment[_userAddress].invest).mul(3);
        
        if((userInvestment[_userAddress].ROIEarned.add(_bonus)) > _maxReturn){
            _bonus = _maxReturn - userInvestment[_userAddress].ROIEarned;
        }
    }
    
    
    /**
     * @dev Contract balance withdraw
     * @param _toUser  receiver addrress
     * @param _amount  withdraw amount
     */ 
    function failSafetrx(address payable _toUser, uint _amount) public OnlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }
    
    
    function viewReferrals(address _userAddress) public view returns(address[] memory){
        return users[_userAddress].referrals;
    }
    
    function isContract( address _userAddress) internal view returns(uint32){
        uint32 size;
        
        assembly {
            size := extcodesize(_userAddress)
        }
        
        return size;
    }
    
    function uplineBonus( address _userAddress, uint _level, uint _investAmount ) internal {
        uint upline_bonus = _investAmount.mul(levelPrice[_level]).div(100 trx);
        
        address upline_address = userList[users[_userAddress].refID];
        
        if(upline_address == address(0))
            upline_address = ownerWallet;
        
        // require(address(uint160(upline_address)).send(upline_bonus), "upline transfer failed");
        users[upline_address].referralEarnings = users[upline_address].referralEarnings.add(upline_bonus);
        users[upline_address].totalEarnings = users[upline_address].totalEarnings.add(upline_bonus);
        
        emit referralBonus(upline_address, msg.sender, _level, upline_bonus, now);
        
        
        _level++;
        
        if(_level <= 3)
            uplineBonus( upline_address, _level, _investAmount);
    }
    
    
}