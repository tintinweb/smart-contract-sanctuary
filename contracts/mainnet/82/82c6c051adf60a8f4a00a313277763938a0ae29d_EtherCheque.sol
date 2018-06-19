pragma solidity ^0.4.11;

// copyright <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e685898892878592a683928e8394858e83979383c885898b">[email&#160;protected]</a>

contract EtherCheque {
    enum Status { NONE, CREATED, LOCKED, EXPIRED }
    enum ResultCode { 
        SUCCESS,
        ERROR_MAX,
        ERROR_MIN,
        ERROR_EXIST,
        ERROR_NOT_EXIST,
        ERROR_INVALID_STATUS,
        ERROR_LOCKED,
        ERROR_EXPIRED,
        ERROR_INVALID_AMOUNT
    }
    struct Cheque {
        bytes32 pinHash; // we only save sha3 of cheque signature
        address creator;
        Status status;
        uint value;
        uint createTime;
        uint expiringPeriod; // in seconds - optional, 0 mean no expire
        uint8 attempt; // current attempt account to cash the cheque
    }
    address public owner;
    address[] public moderators;
    uint public totalCheque = 0;
    uint public totalChequeValue = 0;
    uint public totalRedeemedCheque = 0;
    uint public totalRedeemedValue = 0;
    uint public commissionFee = 10; // div 1000
    uint public minChequeValue = 0.01 ether;
    uint public maxChequeValue = 0; // optional, 0 mean no limit
    uint8 public maxAttempt = 3;
    bool public isMaintaining = false;
    
    // hash cheque no -> Cheque info
    mapping(bytes32 => Cheque) items;

    // modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier isActive {
        if(isMaintaining == true) throw;
        _;
    }
    
    modifier onlyModerators() {
        if (msg.sender != owner) {
            bool found = false;
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == msg.sender) {
                    found = true;
                    break;
                }
            }
            if (!found) throw;
        }
        _;
    }
    
    function EtherCheque() {
        owner = msg.sender;
    }

    // event
    event LogCreate(bytes32 indexed chequeIdHash, uint result, uint amount);
    event LogRedeem(bytes32 indexed chequeIdHash, ResultCode result, uint amount, address receiver);
    event LogWithdrawEther(address indexed sendTo, ResultCode result, uint amount);
    event LogRefundCheque(bytes32 indexed chequeIdHash, ResultCode result);
    
    // owner function
    function ChangeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
    
    function Kill() onlyOwner {
        suicide(owner);
    }
    
    function AddModerator(address _newModerator) onlyOwner {
        for (uint index = 0; index < moderators.length; index++) {
            if (moderators[index] == _newModerator) {
                return;
            }
        }
        moderators.push(_newModerator);
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner {
        uint foundIndex = 0;
        for (; foundIndex < moderators.length; foundIndex++) {
            if (moderators[foundIndex] == _oldModerator) {
                break;
            }
        }
        if (foundIndex < moderators.length)
        {
            moderators[foundIndex] = moderators[moderators.length-1];
            delete moderators[moderators.length-1];
            moderators.length--;
        }
    }
    
    // moderator function
    function SetCommissionValue(uint _commissionFee) onlyModerators {
        commissionFee = _commissionFee;
    }
    
    function SetMinChequeValue(uint _minChequeValue) onlyModerators {
        minChequeValue = _minChequeValue;
    }
    
    function SetMaxChequeValue(uint _maxChequeValue) onlyModerators {
        maxChequeValue = _maxChequeValue;
    }
    
    function SetMaxAttempt(uint8 _maxAttempt) onlyModerators {
        maxAttempt = _maxAttempt;
    }
    
    function UpdateMaintenance(bool _isMaintaining) onlyModerators {
        isMaintaining = _isMaintaining;
    }
    
    function WithdrawEther(address _sendTo, uint _amount) onlyModerators returns(ResultCode) {
        // can only can withdraw profit - unable to withdraw cheque value
        uint currentProfit = this.balance - (totalChequeValue - totalRedeemedValue);
        if (_amount > currentProfit) {
            LogWithdrawEther(_sendTo, ResultCode.ERROR_INVALID_AMOUNT, 0);
            return ResultCode.ERROR_INVALID_AMOUNT;
        }
        
        _sendTo.transfer(_amount);
        LogWithdrawEther(_sendTo, ResultCode.SUCCESS, _amount);
        return ResultCode.SUCCESS;
    }
    
    // only when creator wants to get the money back
    // only can refund back to creator
    function RefundChequeById(string _chequeId) onlyModerators returns(ResultCode) {
        bytes32 hashChequeId = sha3(_chequeId);
        Cheque cheque = items[hashChequeId];
        if (cheque.status == Status.NONE) {
            LogRefundCheque(hashChequeId, ResultCode.ERROR_NOT_EXIST);
            return ResultCode.ERROR_NOT_EXIST;
        }
        
        totalRedeemedCheque += 1;
        totalRedeemedValue += cheque.value;
        uint sendAmount = cheque.value;
        delete items[hashChequeId];
        cheque.creator.transfer(sendAmount);
        LogRefundCheque(hashChequeId, ResultCode.SUCCESS);
        return ResultCode.SUCCESS;
    }

    function RefundChequeByHash(uint256 _chequeIdHash) onlyModerators returns(ResultCode) {
        bytes32 hashChequeId = bytes32(_chequeIdHash);
        Cheque cheque = items[hashChequeId];
        if (cheque.status == Status.NONE) {
            LogRefundCheque(hashChequeId, ResultCode.ERROR_NOT_EXIST);
            return ResultCode.ERROR_NOT_EXIST;
        }
        
        totalRedeemedCheque += 1;
        totalRedeemedValue += cheque.value;
        uint sendAmount = cheque.value;
        delete items[hashChequeId];
        cheque.creator.transfer(sendAmount);
        LogRefundCheque(hashChequeId, ResultCode.SUCCESS);
        return ResultCode.SUCCESS;
    }

    function GetChequeInfoByHash(uint256 _chequeIdHash) onlyModerators constant returns(Status, uint, uint, uint) {
        bytes32 hashChequeId = bytes32(_chequeIdHash);
        Cheque cheque = items[hashChequeId];
        if (cheque.status == Status.NONE) 
            return (Status.NONE, 0, 0, 0);

        if (cheque.expiringPeriod > 0) {
            uint timeGap = now;
            if (timeGap > cheque.createTime)
                timeGap = timeGap - cheque.createTime;
            else
                timeGap = 0;

            if (cheque.expiringPeriod > timeGap)
                return (cheque.status, cheque.value, cheque.attempt, cheque.expiringPeriod - timeGap);
            else
                return (Status.EXPIRED, cheque.value, cheque.attempt, 0);
        }
        return (cheque.status, cheque.value, cheque.attempt, 0);
    }

    function VerifyCheque(string _chequeId, string _pin) onlyModerators constant returns(ResultCode, Status, uint, uint, uint) {
        bytes32 chequeIdHash = sha3(_chequeId);
        Cheque cheque = items[chequeIdHash];
        if (cheque.status == Status.NONE) {
            return (ResultCode.ERROR_NOT_EXIST, Status.NONE, 0, 0, 0);
        }
        if (cheque.pinHash != sha3(_chequeId, _pin)) {
            return (ResultCode.ERROR_INVALID_STATUS, Status.NONE, 0, 0, 0);
        }
        
        return (ResultCode.SUCCESS, cheque.status, cheque.value, cheque.attempt, 0);
    }
    
    // constant function
    function GetChequeInfo(string _chequeId) constant returns(Status, uint, uint, uint) {
        bytes32 hashChequeId = sha3(_chequeId);
        Cheque cheque = items[hashChequeId];
        if (cheque.status == Status.NONE) 
            return (Status.NONE, 0, 0, 0);

        if (cheque.expiringPeriod > 0) {
            uint timeGap = now;
            if (timeGap > cheque.createTime)
                timeGap = timeGap - cheque.createTime;
            else
                timeGap = 0;

            if (cheque.expiringPeriod > timeGap)
                return (cheque.status, cheque.value, cheque.attempt, cheque.expiringPeriod - timeGap);
            else
                return (Status.EXPIRED, cheque.value, cheque.attempt, 0);
        }
        return (cheque.status, cheque.value, cheque.attempt, 0);
    }
    
    // transaction
    function Create(uint256 _chequeIdHash, uint256 _pinHash, uint32 _expiringPeriod) payable isActive returns(ResultCode) {
        // condition: 
        // 1. check min value
        // 2. check _chequeId exist or not
        bytes32 chequeIdHash = bytes32(_chequeIdHash);
        bytes32 pinHash = bytes32(_pinHash);
        uint chequeValue = 0;
        if (msg.value < minChequeValue) {
            msg.sender.transfer(msg.value);
            LogCreate(chequeIdHash, uint(ResultCode.ERROR_MIN), chequeValue);
            return ResultCode.ERROR_MIN;
        }
        if (maxChequeValue > 0 && msg.value > maxChequeValue) {
            msg.sender.transfer(msg.value);
            LogCreate(chequeIdHash, uint(ResultCode.ERROR_MAX), chequeValue);
            return ResultCode.ERROR_MAX;
        }
        if (items[chequeIdHash].status != Status.NONE) {
            msg.sender.transfer(msg.value);
            LogCreate(chequeIdHash, uint(ResultCode.ERROR_EXIST), chequeValue);
            return ResultCode.ERROR_EXIST;
        }
        
        // deduct commission
        chequeValue = (msg.value / 1000) * (1000 - commissionFee);
        totalCheque += 1;
        totalChequeValue += chequeValue;
        items[chequeIdHash] = Cheque({
            pinHash: pinHash,
            creator: msg.sender,
            status: Status.CREATED,
            value: chequeValue,
            createTime: now,
            expiringPeriod: _expiringPeriod,
            attempt: 0
        });
        
        LogCreate(chequeIdHash, uint(ResultCode.SUCCESS), chequeValue);
        return ResultCode.SUCCESS;
    }
    
    function Redeem(string _chequeId, string _pin, address _sendTo) payable returns (ResultCode){
        // condition
        // 1. cheque status must exist
        // 2. cheque status must be CREATED status for non-creator
        // 3. verify attempt and expiry time for non-creator
        bytes32 chequeIdHash = sha3(_chequeId);
        Cheque cheque = items[chequeIdHash];
        if (cheque.status == Status.NONE) {
            LogRedeem(chequeIdHash, ResultCode.ERROR_NOT_EXIST, 0, _sendTo);
            return ResultCode.ERROR_NOT_EXIST;
        }
        if (msg.sender != cheque.creator) {
            if (cheque.status != Status.CREATED) {
                LogRedeem(chequeIdHash, ResultCode.ERROR_INVALID_STATUS, 0, _sendTo);
                return ResultCode.ERROR_INVALID_STATUS;
            }
            if (cheque.attempt > maxAttempt) {
                LogRedeem(chequeIdHash, ResultCode.ERROR_LOCKED, 0, _sendTo);
                return ResultCode.ERROR_LOCKED;
            }
            if (cheque.expiringPeriod > 0 && now > (cheque.createTime + cheque.expiringPeriod)) {
                LogRedeem(chequeIdHash, ResultCode.ERROR_EXPIRED, 0, _sendTo);
                return ResultCode.ERROR_EXPIRED;
            }
        }
        
        // check pin
        if (cheque.pinHash != sha3(_chequeId, _pin)) {
            cheque.attempt += 1;
            LogRedeem(chequeIdHash, ResultCode.ERROR_INVALID_STATUS, 0, _sendTo);
            return ResultCode.ERROR_INVALID_STATUS;
        }
        
        totalRedeemedCheque += 1;
        totalRedeemedValue += cheque.value;
        uint sendMount = cheque.value;
        delete items[chequeIdHash];
        _sendTo.transfer(sendMount);
        LogRedeem(chequeIdHash, ResultCode.SUCCESS, sendMount, _sendTo);
        return ResultCode.SUCCESS;
    }

}