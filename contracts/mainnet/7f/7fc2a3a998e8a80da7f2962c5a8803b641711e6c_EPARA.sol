/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

/**
 *Paralism.com EPARA Token V1 on Ethereum
*/
pragma solidity >=0.6.4 <0.8.0;
pragma experimental ABIEncoderV2;

/// @title Math library with safety checks
/// @author Paralism.com
library SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "add() overflow!");
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub() underflow!");
    }
    
    function toUint64(uint256 _value) internal pure returns (uint64 z){
        require(_value < 2**64, "toUint64() overflow!");
        return uint64(_value);
    }
}

/// @title Contract of EPARA
/// @author Paralism.com
/// @notice EPARA ERC20 contract with lock functionality extension 
/// @dev EPARA V1 March 2021 
contract EPARA {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 internal _supplyCap;
    uint256 public totalLocked;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public freezeOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Burn(address indexed from, uint256 value);

    struct TokensWithLock {
        address sender;
        uint256 lockValue;
        uint64 lockTime;
        bool allowLockTimeUpdate;      
        uint64 initAskTime;
        uint256 askToLock;
    }

    mapping (address => TokensWithLock) public lock;
    
    event TransferWithLock(address indexed sender, address indexed owner, uint256 value, uint256 lockTime ,uint256 initLockDays);
    event ReturnLockedTokens(address indexed owner, address indexed sender, uint256 value);
    event UpdateLockTime(address indexed sender, address indexed owner, uint256 lockDays);
    event AllowUpdateLock(address indexed owner, bool allow);
    event RequestToLock(address indexed sender, address indexed owner, uint256 value, uint256 intLockDays);
    event AcceptLock(address indexed owner,address indexed sender, uint256 value, uint256 lockTime);
    event ReduceLockValue(address indexed sender, address indexed owner, uint256 value);
 
    /*MultiSign*/
    struct Approver {address addr; uint64 score; bool activated; }
    struct ApproveTrans {address to; uint256 value; }
    struct MultiSign {
        uint256 multiSignBalance;
        Approver[] approvers;
        uint64 passScore;                // score of multi party signed to effective
        uint64 expiration;               // MultiSign account expiration time in UNIX seconds
        bool holdFlag;                // hold balance flag, for transfer check gas saving
        address backAccount;             // all tokens controled by MultiSign will return to backAccount when expired
    }
    mapping (address => MultiSign) public multiSign;
    struct Vote {
        ApproveTrans approveTrans;       // transfer request
        uint256 recall;                  // the requestion of recall from keeper's balance to multisign balance
        address backAccount;             // the account where the expired token return to
        bool holdBalance;                // true: freeze account keeper's balance
        uint64 expireDays;               // update expiration days 
    }
    mapping (address => mapping(address => Vote)) public vote;
    
    event MultiSignApprover(address indexed keeper, address indexed approver, uint individualScore);
    event CreateMultiSign(address indexed keeper, uint passScore, address backAccount, uint expiration);
    event FreezeKeeper(address indexed approver, address indexed keeper, bool freeze);
    event HoldBalance(address indexed keeper, bool _freeze);
    event ApproveTransferTo(address indexed approver,address indexed keeper, address indexed to, uint value);
    event MultiSignTransfer(address indexed keeper, address indexed to, uint value);
    event RecallToMultiSign(address indexed approver, address indexed keeper, uint value);
    event MultiSignRecall(address indexed keeper, uint value);
    event UpdateExpiration(address indexed approver, address indexed keeper,uint expireDays);
    event MultiSignExpirationUpdated(address indexed keeper,uint expireDays);
    event UpdateBackAccount(address indexed approver, address indexed keeper, address newBackAccount);
    event MultiSignBackAccountUpdated(address indexed keeper, address newBackAccount);
    event CancelVote(address indexed approver, address indexed keeper);
    event TransferToMultiSign(address indexed approver,address indexed keeper, uint valu);
    event ClearMutiSign(address indexed sender,address indexed keeper, address indexed backAccount,uint value);

    constructor() {
        decimals = 9;
        name = "Paralism-EPARA";  
        symbol = "EPARA";
        _supplyCap = 21000*10000*(10**9);
        totalLocked = 0;

        balanceOf[msg.sender] = _supplyCap;         //210M
    }

    /// @notice Return total available liquidity of token
    /// @return total available liquidity of token
    function totalSupply() public view returns (uint256){
        return _supplyCap - totalLocked;
    }
    
    /// @notice transfer tokens with a timer lock to an address, the timer lock would lock up the transfered funds from being spend for given days
    /// @dev this increase totalLocked and reduce the totalSupply
    /// @param _to the receiver address of token
    /// @param _value the amount of token
    /// @param _initLockdays the how long time in days the funds would be locked up, only can be set at when timer lock initializes
    /// @return success true if transaction accomplished
    function transferWithLockInit(address _to, uint256 _value, uint256 _initLockdays) public returns (bool success) {
        require (address(0) != _to,"transfer to address 0");
        require (false == isMutltiSignHoldBalance(msg.sender), "multisign balance hold");
        require (balanceOf[msg.sender] >= theLockValue(msg.sender).safeAdd(_value),"insufficient balance or locked");

        if (0 < theLockValue(_to)) {
            require (msg.sender == lock[_to].sender,"others lock detected") ;
            require (_initLockdays == 0,"Lock detected, init fail") ;
        }

        if (0 == theLockValue(_to)) {
            lock[_to].lockTime = (block.timestamp.safeAdd(_initLockdays * 1 days)).toUint64();           //init expriation day.
            lock[_to].sender= msg.sender;                                                   //init sender
        }

        lock[_to].lockValue = lock[_to].lockValue.safeAdd(_value);                          //add lock value
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                      //subtract from the sender
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                                    //add to the recipient
        
        if (true == lock[_to].allowLockTimeUpdate) 
            lock[_to].allowLockTimeUpdate = false;                                         //disable sender change lock time until owner allowed again
        
        emit TransferWithLock(msg.sender, _to, _value, lock[_to].lockTime , _initLockdays);

        totalLocked = totalLocked.safeAdd(_value);    //increase totalLocked
        return true;
    }
    
    /// @notice transfer more tokens to an existed lock
    /// @dev this increase totalLocked and reduce the totalSupply
    /// @param _to the receiver address of token
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function transferMoreToLock(address _to, uint256 _value) public returns (bool success) {
        if(0 == theLockValue(_to)) revert("NO lock detected");
        return transferWithLockInit(_to,_value,0);
    }

    /// @notice get timer locked value in effective on owner address.
    /// @dev contract inernal only,once timer expired, the value will update to 0.
    /// @param _addr the address of lock funds owner
    /// @return amount the effective value of timer lock 
    function theLockValue(address _addr) internal returns (uint256 amount){
        if (lock[_addr].lockTime <= block.timestamp) {
            totalLocked = totalLocked.safeSub(lock[_addr].lockValue);           //reduce totalLocked
            lock[_addr].lockValue = 0;                      //reset expired value
        }
        return lock[_addr].lockValue;
    }

    /// @notice Query timer locked balance of funds on owner address
    /// @param _addr the address of lock funds owner
    /// @return amount the effective value of timer lock 
    function getLockValue(address _addr) public view returns (uint256 amount){
        lock[_addr].lockTime > block.timestamp ? amount = lock[_addr].lockValue : amount = 0;
    }

    /// @notice get lock remaining time in seconds of funds on owner address
    /// @param _addr the address of lock funds owner
    /// @return sec the time in seconds of timer
    function getLockRemainSeconds(address _addr) public view returns (uint256 sec){
        lock[_addr].lockTime > block.timestamp ? sec = lock[_addr].lockTime - block.timestamp : sec = 0;
    }

    /// @notice the lock expiration could be modify by lock sender
    /// @dev none.
    /// @param _addr the address of lock funds owner
    /// @param _days the how long time in days the funds would be locked up
    /// @return success true if transaction accomplished
    function updateLockTime(address _addr, uint256 _days)public returns (bool success) {
        require(theLockValue(_addr) > 0,"NO lock detected");
        require(msg.sender == lock[_addr].sender, "others lock detected");
        require(true == lock[_addr].allowLockTimeUpdate,"allowUpdateLockTime is false");

        lock[_addr].lockTime = (block.timestamp.safeAdd(_days * 1 days)).toUint64();
        lock[_addr].allowLockTimeUpdate = false;
        emit UpdateLockTime(msg.sender, _addr, _days);
        return true;
    }

    /// @notice address Owner switch on to permit lock sender updating the lock expiration or switch off to prohibit the modification
    /// @param _allow the permssion flag
    /// @return success true if transaction accomplished
    function allowUpdateLockTime(bool _allow) public returns (bool success){
        lock[msg.sender].allowLockTimeUpdate = _allow;
        emit AllowUpdateLock(msg.sender, _allow);
        return true;
    }

    /// @notice address owner return given amount of locked tokens to the lock sender when the lock in effective
    /// @dev this would reduce totalLocked and increase totalSupply.
    /// @param _value the amount return to the lock funds sender
    /// @return success true if transaction accomplished
    function returnLockedTokens(uint256 _value) public returns (bool success){
        address _returnTo = lock[msg.sender].sender;
        address _returnFrom = msg.sender;

        uint256 lockValue = theLockValue(_returnFrom);
        require(0 < lockValue, "NO lock detected");
        require(_value <= lockValue,"insufficient lock value");
        require(balanceOf[_returnFrom] >= _value,"insufficient balance");

        balanceOf[_returnFrom] = balanceOf[_returnFrom].safeSub(_value);
        balanceOf[_returnTo] = balanceOf[_returnTo].safeAdd(_value);

        lock[_returnFrom].lockValue = lock[_returnFrom].lockValue.safeSub(_value);   //reduce locked amount

        emit ReturnLockedTokens(_returnFrom, _returnTo, _value);

        totalLocked = totalLocked.safeSub(_value);  //reduce totalLocked
        return true;
    }

    /// @notice send lock request to an address, the lock would take effective once the adderss owner accept the request
    /// @dev this would have not impact to totalLocked and totalSupply.
    /// @param _to the address of funds owner
    /// @param _value the amount of token requet to locked
    /// @param _initLockdays the how long time in days the funds would be locked up
    /// @return success true if transaction accomplished
    function askToLock(address _to, uint256 _value, uint256 _initLockdays) public returns(bool success) {
        require(balanceOf[_to] >= theLockValue(_to).safeAdd(_value), "insufficient balance to lock");
        if (0 < theLockValue(_to)) {
            require (msg.sender == lock[_to].sender,"others lock detected") ;
            require (_initLockdays == 0,"lock time exist") ;
        }
        lock[_to].askToLock = _value;
        lock[_to].initAskTime = (block.timestamp + _initLockdays * 1 days).toUint64();
        lock[_to].sender = msg.sender;
        
        emit RequestToLock(msg.sender, _to, _value, _initLockdays);
        return true;
    }

    /// @notice accept a lock request by address owner, the lock take effective
    /// @dev this would increase totalLocked and decrease totalSupply.
    /// @param _sender the address of timer lock request sender
    /// @param _value the amount return to the lock funds sender
    /// @return success true if transaction accomplished
    function acceptLockReq(address _sender, uint256 _value) public returns(bool success) {
        require(lock[msg.sender].askToLock == _value,"value incorrect");
        require(balanceOf[msg.sender] >= theLockValue(msg.sender).safeAdd(_value), "insufficient balance or locked");//
        require(_sender == lock[msg.sender].sender,"sender incorrect");

        if(0 == theLockValue(msg.sender)) {
            lock[msg.sender].lockTime = lock[msg.sender].initAskTime;
        }
        lock[msg.sender].lockValue = theLockValue(msg.sender).safeAdd(_value);
        totalLocked = totalLocked.safeAdd(_value);    //increase totalLocked
        
        if (true ==lock[msg.sender].allowLockTimeUpdate) 
            lock[msg.sender].allowLockTimeUpdate = false;           //disable sender change lock timer until owner permits
            
        emit AcceptLock(msg.sender, _sender, _value, lock[msg.sender].lockTime);
        resetLockReq();
        return true;
    }

    /// @notice reset a lock request received
    /// @dev this would have not impact to totalLocked and totalSupply.
    /// @return success true if transaction accomplished
    function resetLockReq() public returns(bool success) {
        lock[msg.sender].askToLock = 0;
        lock[msg.sender].initAskTime = 0;
        return true;
    }

    /// @notice lock sender reduce given amount of locked funds
    /// @dev this would reduce totalLocked and increase totalSupply.
    /// @param _to the address of funds owner
    /// @param _value the amount of locked token to be reudced
    /// @return success true if transaction accomplished
    function reduceLockValue(address _to, uint256 _value) public returns(bool success) {
        require(_value <= theLockValue(_to), "insufficient lock balance");
        require (msg.sender == lock[_to].sender,"others lock detected") ;

        lock[_to].lockValue = lock[_to].lockValue.safeSub(_value);
        totalLocked = totalLocked.safeSub(_value);  //reduce totalLocked
        emit ReduceLockValue(msg.sender, _to, _value);
        return true;
    }
    
    /// @notice create MultiSign Account on own address 
    /// @dev this function will clean previous MultiSign account if it is expired or not activated
    /// @param _approvers the approver address list
    /// @param _individualScores the array of vote weight of each approver
    /// @param _initPassScore passing score of approver's vote
    /// @param _backAccount the account to which MultiSignBalance will transfer when Multisign are cleared   
    /// @param _initExpireDays the days from now on MultiSign account will expire 
    /// @return success true if transaction accomplished
    function createMultiSign(address[] memory _approvers, 
                             uint[] memory _individualScores, 
                             uint _initPassScore, 
                             address _backAccount, 
                             uint _initExpireDays) 
                             public returns(bool) 
    {
        require(_initPassScore > 0,"invalid pass score");
        require(false == isMultiSignActivated(msg.sender), "multiSign existed");
        require(_individualScores.length == _approvers.length,"arrays length mismatch");

        if (0 < multiSign[address(this)].approvers.length) clearMultiSign(address(this));  //have multiSign not activated and not expired, clean
        
        for (uint i = 0; i < _approvers.length; i++) {
            Approver memory a = Approver(_approvers[i],_individualScores[i].toUint64(),false);
            multiSign[msg.sender].approvers.push(a);
            emit MultiSignApprover(msg.sender, _approvers[i], _individualScores[i]);
        }
        multiSign[msg.sender].passScore = _initPassScore.toUint64();
        multiSign[msg.sender].expiration = (block.timestamp+_initExpireDays*1 days).toUint64();
        
        if (address(0) != _backAccount){
            multiSign[msg.sender].backAccount = _backAccount;
        } else {
            multiSign[msg.sender].backAccount = msg.sender;
        }
        
        emit CreateMultiSign(msg.sender,_initPassScore,_backAccount, _initExpireDays);
        return true;
    }
    
    /// @notice check if MultiSign Account activated or not 
    /// @dev this function will clean previous MultiSign account if it is expired
    /// @param _multisign the keeper address of MultiSign Account
    /// @return activated true if activated
    function isMultiSignActivated(address _multisign) public returns (bool activated){
        uint score;
        uint length = multiSign[_multisign].approvers.length;
        if (multiSign[_multisign].expiration < block.timestamp && multiSign[_multisign].expiration != 0) { // if expired clean 
            clearMultiSign(_multisign); 
        }
        else{       //check if actived 
            for (uint i = 0; i < length; i++) {
                if(true == multiSign[_multisign].approvers[i].activated){
                    score += multiSign[_multisign].approvers[i].score;
                    if (score >= multiSign[_multisign].passScore) return true;
                }
            }
        }
        return false;
    }
    
    /// @notice check if msg.sender is an approver of MultiSign account 
    /// @param _multisign the keeper address of MultiSign Account
    /// @return presence true if msg.sender is approver
    function isApprover(address _multisign) public view returns (bool presence) {
        uint length = multiSign[_multisign].approvers.length;
        require(length > 0, "multiSign not found");
        for (uint i = 0; i < length; i++) {
            if (msg.sender == multiSign[_multisign].approvers[i].addr){
                return true;
            }
        }
        return false;
    }
    
    /// @notice activate an approver of MultiSign Account 
    /// @param _multisign the keeper address of MultiSign Account
    /// @return activated true if approver activated
    function activateApprover(address _multisign) public returns(bool activated) 
    {
        require(isApprover(_multisign),"approver only");
        uint length = multiSign[_multisign].approvers.length;
        for (uint i = 0; i < length; i++) {
            if (msg.sender == multiSign[_multisign].approvers[i].addr){
                if(false == multiSign[_multisign].approvers[i].activated){
                    multiSign[_multisign].approvers[i].activated = true;
                }
                activated = true;
            }
        }
        return activated;
    }
    
    /// @notice vote to agree on freeze or unfreeze keeper address balance   
    /// @dev the vote history of the option to which have just been voted and take effective will be cleaned after execution
    /// @param _multisign the keeper address of MultiSign Account
    /// @param _freeze true for freeze, false for unfreeze
    /// @return success true if transaction accomplished
    function freezeKeeper(address _multisign, bool _freeze) public returns(bool success) 
    {
        require(activateApprover(_multisign));
        vote[_multisign][msg.sender].holdBalance = _freeze;
        emit FreezeKeeper(msg.sender, _multisign, _freeze);

        uint length = multiSign[_multisign].approvers.length;
        uint score = 0;
        for (uint i = 0; i < length; i++) {                     //count score
            if (_freeze == vote[_multisign][multiSign[_multisign].approvers[i].addr].holdBalance) 
                score += multiSign[_multisign].approvers[i].score;            //count score by individual score weight
        }
        
        if (true == isMultiSignActivated(_multisign)
            && score >= multiSign[_multisign].passScore 
            && multiSign[_multisign].holdFlag != _freeze){           //check if reach passScore,and is necessary to update
            multiSign[_multisign].holdFlag = _freeze;                //update holdFlag
            emit HoldBalance(_multisign, _freeze);
        }
        
        return true;
    }
    
    /// @notice check if MultiSign account set to freeze keeper address balance or not  
    /// @param _multisign the keeper address of MultiSign Account
    /// @return flag the multiSign account holdFlag bool value
    function isMutltiSignHoldBalance(address _multisign) public view returns(bool flag){
        return multiSign[_multisign].holdFlag;
    }
    
    /// @notice vote to agree on tranfer from MultiSignBalance to an receiver address   
    /// @dev the vote history of the option to which have just been voted and take effective will be cleaned after execution
    /// @param _multisign the keeper address of MultiSign Account
    /// @param _to receiver address
    /// @param _value value to transfer
    /// @return success true if transaction accomplished
    function approveTransferTo(address _multisign, address _to, uint _value) public returns(bool success) 
    {
        require(address(0) != _to,"transfer to address 0");
        require(activateApprover(_multisign));

        vote[_multisign][msg.sender].approveTrans.to = _to;
        vote[_multisign][msg.sender].approveTrans.value = _value;
        emit ApproveTransferTo(msg.sender,_multisign, _to, _value);
        
        uint length = multiSign[_multisign].approvers.length;
        uint score = 0;
        for (uint i = 0; i < length; i++) {                                    //count score
            if (_to == vote[_multisign][multiSign[_multisign].approvers[i].addr].approveTrans.to
                && _value == vote[_multisign][multiSign[_multisign].approvers[i].addr].approveTrans.value) 
                score += multiSign[_multisign].approvers[i].score;             //count score by individual score weight
        }
        
        if (true == isMultiSignActivated(_multisign)
            && score >= multiSign[_multisign].passScore){//check if reach passScore, execute recall
            require(_value <= multiSign[_multisign].multiSignBalance,"insufficent MultiSign balance");
            //reset to prevent errorly repeat transfer trigger by more vote 
            for (uint i = 0; i < length; i++) {                                                                
                if (_to == vote[_multisign][multiSign[_multisign].approvers[i].addr].approveTrans.to
                    && _value == vote[_multisign][multiSign[_multisign].approvers[i].addr].approveTrans.value) 
                {   
                    vote[_multisign][multiSign[_multisign].approvers[i].addr].approveTrans.to = address(0);        //reset
                    vote[_multisign][multiSign[_multisign].approvers[i].addr].approveTrans.value = 0;              //reset
                }
            }
            
            multiSign[_multisign].multiSignBalance = multiSign[_multisign].multiSignBalance.safeSub(_value);     //reduce multiSignBalance
            balanceOf[_to] = balanceOf[_to].safeAdd(_value);                   //increase receiver balance
            emit MultiSignTransfer(_multisign, _to, _value);
            totalLocked = totalLocked.safeSub(_value);  //reduce totalLocked
            }
        
        return true;
    }
    
    /// @notice vote to agree on tranfer from keeper address balance to MultiSignBalances   
    /// @dev the vote history of the option to which have just been voted and take effective will be cleaned after execution
    /// @param _multisign the keeper address of MultiSign Account
    /// @param _value value to transfer
    /// @return success true if transaction accomplished
    function recallToMultiSign(address _multisign, uint _value) public returns(bool success) 
    {
        require(activateApprover(_multisign));
        require(0 <_value);
        
        vote[_multisign][msg.sender].recall = _value;         //vote recall
        emit RecallToMultiSign(msg.sender, _multisign, _value);
        
        uint length = multiSign[_multisign].approvers.length;
        uint score = 0;
        for (uint i = 0; i < length; i++) {                     //count score
            if (_value == vote[_multisign][multiSign[_multisign].approvers[i].addr].recall) 
                score += multiSign[_multisign].approvers[i].score;             //count score by individual score weight
        }

        if (true == isMultiSignActivated(_multisign)
            && score >= multiSign[_multisign].passScore
            && balanceOf[_multisign] >= theLockValue(_multisign).safeAdd(_value)){//check if reach passScore and have enough balance, execute recall
            //reset to prevent errorly repeat transfer trigger by more vote
            for (uint i = 0; i < length; i++) {                     
                if (_value == vote[_multisign][multiSign[_multisign].approvers[i].addr].recall) 
                    vote[_multisign][multiSign[_multisign].approvers[i].addr].recall = 0;             //reset
            }
            balanceOf[_multisign] = balanceOf[_multisign].safeSub(_value);                                   //reduce keeper's balance
            multiSign[_multisign].multiSignBalance = multiSign[_multisign].multiSignBalance.safeAdd(_value); //increase multiSignBalance
            emit MultiSignRecall(_multisign, _value);
            totalLocked = totalLocked.safeAdd(_value);                                                     //increase totalLocked
        }
        
        return true;
    }
    
    /// @notice vote to agree on update expiration time of MultiSign Account
    /// @dev the vote history of the option to which have just been voted and take effective will be cleaned after execution
    /// @param _multisign the keeper address of MultiSign Account
    /// @param _expireDays new expiration dayss
    /// @return success true if transaction accomplished
    function updateExpiration(address _multisign, uint _expireDays) public returns(bool success) 
    {
        require (activateApprover(_multisign));

        _expireDays = _expireDays.safeAdd(1);     //add vote guard
        
        vote[_multisign][msg.sender].expireDays = _expireDays.toUint64();     //vote expireDays
        emit UpdateExpiration(msg.sender, _multisign, _expireDays);
        
        uint length = multiSign[_multisign].approvers.length;
        uint score = 0;
        for (uint i = 0; i < length; i++) {                     //count score
            if (_expireDays == vote[_multisign][multiSign[_multisign].approvers[i].addr].expireDays) 
                score += multiSign[_multisign].approvers[i].score;            //count score by individual score weight
        }
        
        if (true == isMultiSignActivated(_multisign)
            && score >= multiSign[_multisign].passScore){                         //check if reach passScore,
            for (uint i = 0; i < length; i++) {
                vote[_multisign][multiSign[_multisign].approvers[i].addr].expireDays = 0;   //clear voted data
            }  
            _expireDays -= 1;   //clear vote guard
            multiSign[_multisign].expiration = (block.timestamp + (_expireDays) * 1 days).toUint64();             //update multisign expire
            emit MultiSignExpirationUpdated(_multisign, _expireDays);
        }
        
        return true;
    }
    
    /// @notice vote to agree on update back account of MultiSign Account
    /// @dev the vote history of the option to which have just been voted and take effective will be cleaned after execution
    /// @param _multisign the keeper address of MultiSign Account
    /// @param _newBackAccount new back account
    /// @return success true if transaction accomplished
    function updateBackAccount(address _multisign, address _newBackAccount) public returns(bool success)
    {
        require (address(0) != _newBackAccount,"invalid address");
        require (activateApprover(_multisign));
        vote[_multisign][msg.sender].backAccount = _newBackAccount;     //vote backAccount
        emit UpdateBackAccount(msg.sender, _multisign, _newBackAccount);
        
        uint length = multiSign[_multisign].approvers.length;
        uint score = 0;
        for (uint i = 0; i < length; i++) {                     //count score
            if (_newBackAccount == vote[_multisign][multiSign[_multisign].approvers[i].addr].backAccount) 
                score += multiSign[_multisign].approvers[i].score;            //count score by individual score weight
        }
        
        if (true == isMultiSignActivated(_multisign)
            && score >= multiSign[_multisign].passScore
            && multiSign[_multisign].backAccount != _newBackAccount){     //check if reach passScore,
            multiSign[_multisign].backAccount = _newBackAccount;             //update multisign backAccount
            emit MultiSignBackAccountUpdated(_multisign, _newBackAccount);
        }
        
        return true;
    }
    
    /// @notice clean all vote by msg.sender who is an approver of MultiSign Account
    /// @param _multisign the keeper address of MultiSign Account
    /// @return success true if transaction accomplished
    function cancelVote(address _multisign) public returns(bool success) 
    {
        require (activateApprover(_multisign));
        delete vote[_multisign][msg.sender];
        emit CancelVote(msg.sender,_multisign);
        return true;
    }
    
    /// @notice transfer tokens to MultiSign Account Balance if it is activated
    /// @param _multisign the keeper address of MultiSign Account
    /// @param _value token value to transfer
    /// @return success true if transaction accomplished
    function transferToMultiSign(address _multisign, uint _value) public returns(bool success) 
    {
        require (address(0) != _multisign,"transfer to address 0");
        require (balanceOf[msg.sender] >= theLockValue(msg.sender).safeAdd(_value),"insufficient balance or locked");
        require (isMultiSignActivated(_multisign),"multisign not activated");
        require (false == isMutltiSignHoldBalance(msg.sender), "multisign balance hold");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                                    //subtract from the sender
        multiSign[_multisign].multiSignBalance = multiSign[_multisign].multiSignBalance.safeAdd(_value);    //add to the multisignbalance
        emit TransferToMultiSign(msg.sender, _multisign, _value);
        totalLocked = totalLocked.safeAdd(_value);                                                     //increase totalLocked
        return true;
    }
    
    /// @notice get MultiSign account balance
    /// @param _multisign the keeper address of MultiSign Account
    /// @return balanceOfMultiSign value of balance
    function getBalanceOfMultiSign(address _multisign) public view returns(uint balanceOfMultiSign) 
    {
        return multiSign[_multisign].multiSignBalance;
    }
    
    /// @notice get MultiSign account approvers
    /// @param _multisign the keeper address of MultiSign Account
    /// @return approvers list
    function getApproversOfMultiSign(address _multisign) public view returns(Approver[] memory approvers) 
    {
        return multiSign[_multisign].approvers;
    }
    
    /// @notice clear MultiSign Account if it is not activated or expired
    /// @param _multisign the keeper address of MultiSign Account
    /// @return success true if transaction accomplished
    function clearMultiSign(address _multisign) public returns (bool success) {
        require(isApprover(_multisign) || msg.sender == _multisign);
        
        uint score;
        uint length = multiSign[_multisign].approvers.length;
        for (uint i = 0; i < length; i++) {
            if(true == multiSign[_multisign].approvers[i].activated){
                score += multiSign[_multisign].approvers[i].score;
            }
        }
        
        require(score < multiSign[_multisign].passScore || multiSign[_multisign].expiration < block.timestamp);
            
        for (uint i = 0; i < length; i++) {
            delete vote[_multisign][multiSign[_multisign].approvers[i].addr];   //clear votes
        }
           
        address bAccount = multiSign[_multisign].backAccount;
        uint value = multiSign[_multisign].multiSignBalance;
        if (address(0) != bAccount && 0 < value){                                 //transfer balance to backAccount
            balanceOf[bAccount] = balanceOf[bAccount].safeAdd(value); 
            totalLocked = totalLocked.safeSub(value);   //reduce totalLocked
        }

        delete multiSign[_multisign];                                           //remove multiSign
        emit ClearMutiSign(msg.sender,_multisign,bAccount,value);
        return true;
    }
    
    /// @notice Transfer tokens to multiple addresses
    /// @param _addresses the address list of token receivers
    /// @param _amounts the amount list one to one correspondence to the address list
    /// @return success true if transaction accomplished
    function transferForMultiAddresses(address[] memory _addresses, uint256[] memory _amounts) public returns (bool) {
        require(_addresses.length == _amounts.length,"arrays length mismatch");
        require (false == isMutltiSignHoldBalance(msg.sender), "multisign balance hold");

        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0),"transfer to address 0");
            if (balanceOf[msg.sender] < theLockValue(msg.sender).safeAdd(_amounts[i])) revert("insufficient balance or locked");

            balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_amounts[i]);
            balanceOf[_addresses[i]] = balanceOf[_addresses[i]].safeAdd(_amounts[i]);
            emit Transfer(msg.sender, _addresses[i], _amounts[i]);
        }
        return true;
    }
    
    /// @notice token plain transfer to given address
    /// @param _to the receiver address of token
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function transfer(address _to, uint256 _value) public returns (bool success){
        if (_to == address(0)) revert("transfert to address 0");
        require (false == isMutltiSignHoldBalance(msg.sender), "multisign balance hold");
        require (balanceOf[msg.sender] >= theLockValue(msg.sender).safeAdd(_value),"insufficient balance or locked");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /// @notice approve another address to spend giben tokens on your behalf
    /// @param _spender the address would be given permission
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /// @notice the permitted address spend the approved amount of tokens
    /// @param _from the address approved the spend
    /// @param _to the receiver address of token 
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0), "transfert to address 0");
        require (_value <= allowance[_from][msg.sender],"transfer more than allowance");
        require (false == isMutltiSignHoldBalance(_from), "multisign balance hold");
        require (balanceOf[_from] >= theLockValue(_from).safeAdd(_value),"insufficient balance or locked");

        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_value);
        balanceOf[_from] = balanceOf[_from].safeSub(_value);
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /// @notice burn a given amount of token, unrecoverable
    /// @dev this would reduce _supplyCap
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= theLockValue(msg.sender).safeAdd(_value), "insufficient balance or locked");
        require (false == isMutltiSignHoldBalance(msg.sender), "multisign balance hold");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        _supplyCap = _supplyCap.safeSub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /// @notice move given amount of token from balanceOf into freezeOf 
    /// @dev no size impact to _supplyCap
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert("insufficient balance");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(_value);
        emit Freeze(msg.sender, _value);
        return true;
    }

    /// @notice move given amount of token from freezeOf into balanceOf
    /// @dev no size impact to _supplyCap
    /// @param _value the amount of token
    /// @return success true if transaction accomplished
    function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert("insufficient balance.");

        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].safeAdd(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

 }