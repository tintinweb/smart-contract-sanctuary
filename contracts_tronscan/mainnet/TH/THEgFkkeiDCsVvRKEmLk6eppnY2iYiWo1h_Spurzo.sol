//SourceUnit: spurzo.sol

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


contract Spurzo{
    // SafeMath
    using SafeMath for uint;
    
    // User struct
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint totalEarnedTRX;
        uint sharesHoldings;
        uint directShare;
        uint totalInvest;
        uint referralShare;
        uint created;
        address[] referral;
    }
   
    
    // Public variables
    address public ownerWallet;
    address public signature;
    uint public qualifiedPoolHolding = 5000 trx;
    uint public poolMoney;
    uint public invest = 2500 trx;
    uint public feePercentage = 5 trx; 
    uint public currUserID = 1;
    uint public qualify = 1 days;
    bool public lockStatus;
    
    // Mapping
    mapping(address => UserStruct) public users;
    mapping (uint => address) public userList;
    
    // Events
    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event poolMoneyEvent(address indexed _user, uint _money, uint _time);
    event splitOverEvent(address indexed _user, uint _shareAmount, uint _time);
    event userInversement(address indexed _user, uint _noOfShares, uint _amount, uint _time, uint investType);
    event userWalletTransferEvent(address indexed _user, uint _amount, uint _percentage, uint _gasFee, uint _time);
    event ownerWalletTransferEvent(address indexed _user, uint _percentage, uint _gasFee, uint _time);
    
    // On Deploy
    constructor()public{
        ownerWallet = msg.sender;
        
        UserStruct memory userStruct;
        
        userStruct = UserStruct({
            isExist: true,
            id: 1,
            referrerID: 0,
            totalEarnedTRX: 0,
            sharesHoldings: 0,
            directShare: 0,
            referralShare: 0,
            totalInvest:0,
            created:now.add(qualify),
            referral: new address[](0)
        });
        
        users[ownerWallet] = userStruct;
        userList[1] = ownerWallet;
    }
    
    /**
     * @dev To register the User
     * @param _referrerID id of user/referrer 
     */
    function regUser(uint _referrerID) public payable returns(bool){
        require(
            lockStatus == false,
            "Contract is locked"
        );
        require(
            !users[msg.sender].isExist,
            "User exist"
        );
        require(
            _referrerID > 0 && _referrerID <= currUserID,
            "Incorrect referrer Id"
        );
        require(
            msg.value == invest,
            "Incorrect Value"
        );
        
        require(isContract( msg.sender) == 0, "invalid user address");
        
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            totalEarnedTRX: 0,
            sharesHoldings: 1,
            directShare: 0,
            referralShare: 0,
            totalInvest:0,
            created:now.add(qualify),
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;
        
        address referer;  
        
        referer = userList[_referrerID];
        
         if(referer == address(0))
            referer = ownerWallet;
        
        users[referer].sharesHoldings = users[referer].sharesHoldings.add(1);
        users[referer].referralShare = users[referer].referralShare.add(1);
        users[msg.sender].totalInvest = users[msg.sender].totalInvest.add(msg.value);
        users[referer].referral.push(msg.sender);
    
        uint _value = invest.div(2);
        
        require(
            address(uint160(referer)).send(_value),
            "Transaction failed"
        );
        
        users[referer].totalEarnedTRX = users[referer].totalEarnedTRX.add(_value);
        
        poolMoney = poolMoney.add(_value);
        
        emit poolMoneyEvent( msg.sender, _value, now);
        emit regEvent(msg.sender, referer, now);
        
        return true;
    }

    /**
     * @dev To invest on shares
     * @param _noOfShares No of shares 
     */
    function investOnShare(uint _noOfShares) public payable returns(bool){
        require(
            lockStatus == false,
            "Contract is locked"
        );
        
        require(
            msg.value == invest.mul(_noOfShares),
            "Incorrect Value"
        );
        
        require(users[msg.sender].isExist,"User not exist");
        
        require(isContract( msg.sender) == 0, "invalid user address");
        
        uint _value = (msg.value).div(2);
        
        address _referer;
        
        uint referrerID = users[msg.sender].referrerID;
        
        _referer = userList[referrerID];
        
        if(_referer == address(0))
            _referer = ownerWallet;
            
        require(
            address(uint160(_referer)).send(_value),
            "Transaction failed"
        ); 
        
        users[_referer].totalEarnedTRX = users[_referer].totalEarnedTRX.add(_value);
        
        users[msg.sender].directShare = users[msg.sender].directShare.add(_noOfShares);
        users[msg.sender].sharesHoldings = users[msg.sender].sharesHoldings.add(_noOfShares);
        users[msg.sender].totalInvest = users[msg.sender].totalInvest.add(msg.value);
        
        poolMoney = poolMoney.add(_value);
        
        emit poolMoneyEvent( msg.sender, _value, now);
        emit userInversement( msg.sender, _noOfShares, msg.value, now, 1);
        
        return true;
    }
    
    
    function shareWithdraw(address[] memory _userAddress, uint[] memory _shareAmount, uint _gasFee) public returns(bool){
        
        require(msg.sender == ownerWallet,"Only ownerWallet");
        
        require((_userAddress.length == _shareAmount.length),"invalid user length");
        
        for(uint i=0;i<_userAddress.length;i++){
        
            require(users[_userAddress[i]].isExist,"User not exist");
            
            require(address(this).balance/2 >= _shareAmount[i],"Insufficient balance");
            
            require(
                users[_userAddress[i]].created < now,
                "user is not qualified to withdraw"
            );
            
            
            address _useradd = _userAddress[i]; 
            
            require(isContract( _userAddress[i]) == 0, "invalid user address");
            
            address _referer;
            
            uint referrerID = users[_useradd].referrerID;
            
            _referer = userList[referrerID];
            
            if(_referer == address(0))
                _referer = ownerWallet;
            
            uint _totalInvestingShare = _shareAmount[i].div(qualifiedPoolHolding);
            uint _referervalue = invest.div(2);
            uint _value = (_referervalue.mul(_totalInvestingShare));
            
            poolMoney = poolMoney.sub(_shareAmount[i]);
            
            require(
                address(uint160(_referer)).send(_value),
                "re-inverset referer 50 percentage failed"
            );
            
            users[_referer].totalEarnedTRX = users[_referer].totalEarnedTRX.add(_value);
            
            users[_useradd].directShare = users[_useradd].directShare.add(_totalInvestingShare);
            users[_useradd].sharesHoldings = users[_useradd].sharesHoldings.add(_totalInvestingShare);
            
            poolMoney = poolMoney.add(_value);
            
            // wallet
            uint _walletAmount = invest.mul(_totalInvestingShare);
            uint _adminCommission = (_walletAmount.mul(feePercentage)).div(1e8);
            
            _walletAmount = _walletAmount.sub(_adminCommission.add(_gasFee));
            
            require(
                address(uint160(_useradd)).send(_walletAmount) &&
                address(uint160(ownerWallet)).send(_adminCommission.add(_gasFee)),
                "user wallet transfer failed"
            );  
            
            
            emit splitOverEvent(_useradd, _shareAmount[i], now);
            emit userInversement( _useradd, _totalInvestingShare, invest.mul(_totalInvestingShare), now, 2);
            emit poolMoneyEvent( _useradd, _value, now);
            emit userWalletTransferEvent(_useradd, _walletAmount, _adminCommission, _gasFee, now);
            emit ownerWalletTransferEvent(_useradd, _adminCommission, _gasFee, now);
        }
        
        return true;
    }
    
    
    /**
     * @dev Contract balance withdraw
     * @param _toUser  receiver addrress
     * @param _amount  withdraw amount
     */ 
    function failSafe(address payable _toUser, uint _amount) public returns (bool) {
        require(msg.sender == ownerWallet, "Only Owner Wallet");
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        return true;
    }

    /**
     * @dev To lock/unlock the contract
     * @param _lockStatus  status in bool
     */
    function contractLock(bool _lockStatus) public returns (bool) {
        require(msg.sender == ownerWallet, "Invalid ownerWallet");

        lockStatus = _lockStatus;
        return true;
    }
    
    /**
     * @dev To view the referrals
     * @param _user  User address
     */ 
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }
    
    function isContract( address _userAddress) internal view returns(uint32){
        uint32 size;
        
        assembly {
            size := extcodesize(_userAddress)
        }
        
        return size;
    }
    
    
    
}