//SourceUnit: Chezz no comments.sol

pragma solidity 0.5.10;

interface ITRC20 {
    function balanceOf(address account) external view returns (uint);
    function allowance(address _firstUser, address _spender) external view returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
}

contract Chezz {
    uint public currentUserID;
    address public owner;
    address public tokenAddress;
    uint internal subscriptionDuration;
    uint internal subscriptionRenewalOffset;
    uint[] internal prices;
    uint[] internal stages;

    mapping (uint => User) public users;
    mapping (address => uint) public userWallets;
    
    ITRC20 private TOKEN;

    struct User {
        bool exists;
        address wallet;
        uint upline;
        uint referrer;
        uint subscriptionExpiry;
        uint chargebackTill;
        uint acceptedPayments;
    }

    struct RefList {
        uint id;
        uint referrer;
        uint upline;
        address wallet;
        uint8 qState;
    }

    mapping (uint => uint[]) internal referrals;
    mapping (uint => uint[]) internal migratedReferrals;
    

    event RegisterUserEvent(address indexed user, address indexed referrer, address indexed upline, uint userID, uint referrerID, uint uplineID, uint time);
    event SubscriptionRenewalEvent(address indexed user, uint time, uint userID);
    event TransferEvent(address indexed recipient, address indexed sender, uint indexed amount, uint time, uint recipientID, uint senderID, bool superProfit);
    event LostProfitEvent(address indexed loser, address indexed sender, uint indexed amount, uint time, uint loserID, uint senderID);
    event WalletChangeEvent(address indexed oldWallet, address indexed newWallet, uint time, uint userID);

    constructor(address _firstUser, address _token) public {
        prices = [2, 20, 50, 100];
        stages = [0, 1e4, 1e5, 1e6];
        subscriptionDuration = 30 days;
        subscriptionRenewalOffset = 1 days;
        
        owner = msg.sender;
        
        tokenAddress = _token;

        TOKEN = ITRC20(tokenAddress);

        currentUserID++;

        users[currentUserID] =  User({ 
            exists: true, 
            wallet: _firstUser, 
            upline: 1,
            referrer: 1, 
            subscriptionExpiry: 1 << 37,
            chargebackTill: 0,
            acceptedPayments: 0
        });

        userWallets[_firstUser] = currentUserID;

        emit RegisterUserEvent(msg.sender, msg.sender, msg.sender,currentUserID, currentUserID, currentUserID, now);
      
    }

    function () noTRX external payable {
    }

    function registerUser(uint _referrer) noTRX public payable returns (bool){
        require(_referrer > 0 && _referrer <= currentUserID, 'Invalid referrer ID');
        require(userWallets[msg.sender] == 0, 'User already registered');
        (bool pass,,,,,) = solvencyCheck();
        require(pass, 'Insufficient funds');


        if(!createUser(msg.sender, _referrer)) return false;
        

        return true;
    }


    function renewSubscription() noTRX public payable returns (bool){
        require(userWallets[msg.sender] != 0, 'User not found');
        require(isCanRenew(), 'Renewal not available');
        (bool pass,,,,,) = solvencyCheck();
        require(pass, 'Insufficient funds');

        uint userid = userWallets[msg.sender];
        
        if(payForSubscription(userid)){
            users[userid].subscriptionExpiry = (users[userid].subscriptionExpiry > now) ? users[userid].subscriptionExpiry + subscriptionDuration : now + subscriptionDuration;
            users[userid].acceptedPayments = 0;
            emit SubscriptionRenewalEvent(msg.sender, now, userid);
            return true;
        }

        return false;
    }

    function payForSubscription(uint _userid) internal returns (bool){
        (uint recipient, bool superProfit) = findPaymentRecipient(_userid);

        uint amount = getPrice(false);
        address recipientWallet = users[recipient].wallet;

        if(TOKEN.transferFrom(msg.sender, recipientWallet, amount)){
            emit TransferEvent(recipientWallet, msg.sender, amount, now, recipient, _userid, superProfit);
            return true;
        }

        return false;
    }

    function isCanRenew() public view returns (bool){
        uint userid = userWallets[msg.sender];
        return (users[userid].exists && users[userid].subscriptionExpiry - subscriptionRenewalOffset < now);
    }

    function changeWallet(address _newWalletAddress) noTRX public payable returns (bool){
        require(userWallets[msg.sender] != 0, 'User not found');
        require(userWallets[_newWalletAddress] == 0, 'User already registered');

        uint userid = userWallets[msg.sender];
        userWallets[msg.sender] = 0;
        userWallets[_newWalletAddress] = userid;
        users[userid].wallet = _newWalletAddress;
        emit WalletChangeEvent(msg.sender, _newWalletAddress, now, userid);
        return true;

    }

    function changeToken(address _newTokenAddress) onlyOwner noTRX public payable returns (bool){
        require(_newTokenAddress != address(0), "Wrong address");

        tokenAddress = _newTokenAddress;
        TOKEN = ITRC20(tokenAddress);

        return true;
    }


    function findUpline(uint _referrer) internal returns (uint) {
        require(_referrer > 0 && _referrer <= currentUserID, 'Invalid referrer ID');
 
        if(referrals[_referrer].length >= 1 && migratedReferrals[_referrer].length < 2 && users[_referrer].upline != _referrer) {
            migratedReferrals[_referrer].push(currentUserID);
            return users[_referrer].upline;
        }
        
        return _referrer;
        
    }

    function findPaymentRecipient(uint _userid) internal returns (uint, bool) {


        if(users[_userid].chargebackTill > now && users[users[_userid].referrer].subscriptionExpiry > now){
            users[_userid].chargebackTill = 0;
            users[users[_userid].referrer].acceptedPayments++;
            return (users[_userid].referrer, false);
        }

        return findPaymentRecipientRecursive(users[_userid].upline, _userid);

    }

    function findPaymentRecipientRecursive(uint _recipient, uint _sender) internal returns (uint, bool){


        bool[] memory qualif = getQualification(_recipient);


        if(!qualif[0]) {
            if(users[_sender].upline == _recipient)
                emit LostProfitEvent(users[_recipient].wallet, users[_sender].wallet, getPrice(false), now,_recipient, _sender);
            return findPaymentRecipientRecursive(users[_recipient].upline, _sender);
        }

        if(!qualif[1]) {
            if(users[_sender].upline == _recipient){
                users[_recipient].acceptedPayments++;
                return (_recipient, false);
            }
            
            return findPaymentRecipientRecursive(users[_recipient].upline, _sender);
        }
        
        if(!qualif[2] || !qualif[3]){
            for(uint i = 0; i < migratedReferrals[_recipient].length; i++){

                uint migratedReferral = migratedReferrals[_recipient][i];
                if(users[migratedReferral].subscriptionExpiry < now && users[migratedReferral].chargebackTill < now){
                    

                    users[migratedReferral].chargebackTill = now + subscriptionDuration;
                    return findPaymentRecipientRecursive(users[migratedReferral].upline, _sender);
                }
                
            }
            
            return findPaymentRecipientRecursive(users[_recipient].upline, _sender);
        }
        
        bool superProfit = false;
        if(users[_sender].upline == _recipient){
            users[_recipient].acceptedPayments++;
        }else{
            superProfit = true;
        }
        return (_recipient, superProfit);
    }


    function createUser(address _wallet, uint _referrer) internal returns (bool) {
        
        currentUserID++;

        uint upline = findUpline(_referrer);

        users[currentUserID] =  User({ 
            exists: true, 
            wallet: _wallet, 
            upline: upline,
            referrer: _referrer, 
            subscriptionExpiry:  now + subscriptionDuration,
            chargebackTill: 0,
            acceptedPayments: 0
        });

        userWallets[msg.sender] = currentUserID;

        emit RegisterUserEvent(msg.sender, users[_referrer].wallet, users[upline].wallet, currentUserID, _referrer, upline, now);   

        if(!payForSubscription(currentUserID)) return false;
        

        if(upline != currentUserID)
            referrals[upline].push(currentUserID);
        
        emit SubscriptionRenewalEvent(msg.sender, now, currentUserID);

        return true;
    }

    function getAllowance() public view returns (uint) {
        return TOKEN.allowance(msg.sender, address(this));
    }
    

    function isQualified(uint _userid) public view returns (bool){
        bool[] memory qualif = getQualification(_userid);
        bool fullQualif = true;
        for(uint8 i = 0; i<qualif.length-1; i++) if(!qualif[i]) fullQualif = qualif[i];
        return fullQualif;
    }

    function getQualification(uint _userid) public view returns (bool[] memory){
        bool[] memory qualif = new bool[](5);
        

        if(_userid == users[_userid].upline){
            for(uint i=0;i<qualif.length;i++) qualif[i] = true;
            return qualif;
        }


        qualif[0] = (users[_userid].subscriptionExpiry > now);


        qualif[1] = (qualif[0] && users[_userid].acceptedPayments > 0);

        qualif[2] = ( qualif[0]
            &&  migratedReferrals[_userid].length > 0
            && (users[migratedReferrals[_userid][0]].subscriptionExpiry > now
                || users[migratedReferrals[_userid][0]].chargebackTill > now)
            );

        qualif[3] = ( qualif[0]
            &&  migratedReferrals[_userid].length > 1
            && (users[migratedReferrals[_userid][1]].subscriptionExpiry > now
                || users[migratedReferrals[_userid][1]].chargebackTill > now)
            );

        qualif[4] = (qualif[0] && users[_userid].acceptedPayments > 1);

        return qualif;
    }

    function isSubscriptionActive(uint _userid) public view returns (bool){
        return (users[_userid].subscriptionExpiry > now);
    }

    function getStats(uint _userid) public view returns (uint refsCount, uint payedRefsCount, uint qualifiedRefsCount) {
        refsCount = referrals[_userid].length;

        for(uint i = 0; i < referrals[_userid].length; i++){
            uint refid = referrals[_userid][i];
            if(isSubscriptionActive(refid)) payedRefsCount++;
            if(isQualified(refid)) qualifiedRefsCount++;
        }
    }

    function getRefList(uint _userid, uint _count, uint _offset) public view 
        returns (
            uint _maxCount,
            uint _returnCount,
            uint[] memory _ids,
            address[] memory _wallets,
            uint8[] memory _types,
            uint[] memory _refups,
            bool[] memory _qState,
            uint[] memory _refCounts
        )
    {
        
        _maxCount = migratedReferrals[_userid].length + referrals[_userid].length;
        _returnCount = 0;
        _ids = new uint[](_count);
        _wallets = new address[](_count);
        _types = new uint8[](_count);
        _refups = new uint[](_count);
        _qState = new bool[](_count);
        _refCounts = new uint[](_count);
        
        if(_offset < migratedReferrals[_userid].length) {
            for(uint i = _offset; i < _count+_offset && i < migratedReferrals[_userid].length; i++){
                uint refid = migratedReferrals[_userid][i];
                User memory ref = users[refid];
                _ids[_returnCount] = refid;
                _wallets[_returnCount] = ref.wallet;
                _types[_returnCount] = 1;
                _refups[_returnCount] = ( _types[_returnCount] == 1) ? ref.upline: ref.referrer;
                _qState[_returnCount] = isSubscriptionActive(refid);
                _refCounts[_returnCount] = referrals[refid].length;
                _returnCount++;
            }
            _offset = 0;
        }else{
            _offset -= migratedReferrals[_userid].length;
        }

        uint migratedRefsReturnCount = _returnCount;
        
        for(uint i = _offset; i < _count-migratedRefsReturnCount+_offset && i < referrals[_userid].length; i++){
            uint refid = referrals[_userid][i];
            User memory ref = users[refid];
            _ids[_returnCount] = refid;
            _wallets[_returnCount] = ref.wallet;
            _types[_returnCount] = (ref.referrer == _userid)? 0:2;
            _refups[_returnCount] = ( _types[_returnCount] == 1) ? ref.upline: ref.referrer;
            _qState[_returnCount] = isSubscriptionActive(refid);
            _refCounts[_returnCount] = referrals[refid].length;
            _returnCount++;
        }
        
    }

    function getStage(bool _preRegister) public view returns (uint){

        for(uint i = 0; i < stages.length; i++){
            if( ( (_preRegister)? currentUserID + 1 : currentUserID ) > stages[i]) continue;
            return i-1;
        }

        return stages.length-1;
    }


    function getPrice(bool _preRegister) public view returns (uint){
        uint stage = getStage(_preRegister);
        return prices[stage] * 1e6;
    }

    function solvencyCheck() public view returns (bool _pass, address _tokenAddress, uint _userBalance, uint _currentAllowance, uint _approvalAmount, uint _actualPrice){
        uint balance = TOKEN.balanceOf(msg.sender);
        uint currentAllowance = TOKEN.allowance(msg.sender, address(this));
        uint actualPrice = getPrice( (userWallets[msg.sender] == 0) );
        uint approvalAmount = (actualPrice > currentAllowance) ? actualPrice - currentAllowance : 0;
        bool pass = (currentAllowance >= actualPrice && balance >= actualPrice);

        return (pass, tokenAddress, balance, currentAllowance, approvalAmount, actualPrice);
    }

    function getUserInfo(uint _userid) public view returns (uint id, address wallet, uint subscriptionExpiry, uint refsCount, uint migratedRefsCount, uint upline, uint referrer) {
        require(users[_userid].exists, 'User not exists');
        return (_userid, users[_userid].wallet, users[_userid].subscriptionExpiry, referrals[_userid].length, migratedReferrals[_userid].length, users[_userid].upline, users[_userid].referrer);
    }

    function getUserInfoByWallet(address _wallet) public view returns (uint id, address wallet, uint subscriptionExpiry, uint refsCount, uint migratedRefsCount, uint upline, uint referrer)  {
        return getUserInfo(userWallets[_wallet]);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Access denied");
        _;
    }

    modifier noTRX(){
        require(msg.value == 0, 'No TRX allowed');
        _;
    }
    
}