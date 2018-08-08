pragma solidity ^0.4.11;

/**
 * @title Owned contract with safe ownership pass.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public contractOwner;

    /**
     * Contract owner address
     */
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    /**
    * @dev Owner check modifier
    */
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only owner can call it
     */
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

    /**
     * Prepares ownership pass.
     *
     * Can only be called by current owner.
     *
     * @param _to address of the next owner. 0x0 is not allowed.
     *
     * @return success.
     */
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

    /**
     * Finalize ownership pass.
     *
     * Can only be called by pending owner.
     *
     * @return success.
     */
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}



contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}


/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    /**
    *  Common result code. Means everything is fine.
    */
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}



//import "../contracts/ContractsManagerInterface.sol";

/**
 * @title General MultiEventsHistory user.
 *
 */
contract MultiEventsHistoryAdapter {

    /**
    *   @dev It is address of MultiEventsHistory caller assuming we are inside of delegate call.
    */
    function _self() constant internal returns (address) {
        return msg.sender;
    }
}


contract DelayedPaymentsEmitter is MultiEventsHistoryAdapter {
        event Error(bytes32 message);

        function emitError(bytes32 _message) {
           Error(_message);
        }
}

contract Lockup6m_20180801 is Object {

    uint constant TIME_LOCK_SCOPE = 51000;
    uint constant TIME_LOCK_TRANSFER_ERROR = TIME_LOCK_SCOPE + 10;
    uint constant TIME_LOCK_TRANSFERFROM_ERROR = TIME_LOCK_SCOPE + 11;
    uint constant TIME_LOCK_BALANCE_ERROR = TIME_LOCK_SCOPE + 12;
    uint constant TIME_LOCK_TIMESTAMP_ERROR = TIME_LOCK_SCOPE + 13;
    uint constant TIME_LOCK_INVALID_INVOCATION = TIME_LOCK_SCOPE + 17;


    // custom data structure to hold locked funds and time
    struct accountData {
        uint balance;
        uint releaseTime;
    }

    // Should use interface of the emitter, but address of events history.
    address public eventsHistory;

    address asset;

    accountData lock;

    function Lockup6m_20180801(address _asset) {
        asset = _asset;
    }

    /**
     * Emits Error event with specified error message.
     *
     * Should only be used if no state changes happened.
     *
     * @param _errorCode code of an error
     * @param _message error message.
     */
    function _error(uint _errorCode, bytes32 _message) internal returns(uint) {
        DelayedPaymentsEmitter(eventsHistory).emitError(_message);
        return _errorCode;
    }

    /**
     * Sets EventsHstory contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _eventsHistory MultiEventsHistory contract address.
     *
     * @return success.
     */
    function setupEventsHistory(address _eventsHistory) returns(uint errorCode) {
        errorCode = checkOnlyContractOwner();
        if (errorCode != OK) {
            return errorCode;
        }
        if (eventsHistory != 0x0 && eventsHistory != _eventsHistory) {
            return TIME_LOCK_INVALID_INVOCATION;
        }
        eventsHistory = _eventsHistory;
        return OK;
    }

    function payIn() onlyContractOwner returns(uint errorCode) {
        // send some amount (in Wei) when calling this function.
        // the amount will then be placed in a locked account
        // the funds will be released once the indicated lock time in seconds
        // passed and can only be retrieved by the same account which was
        // depositing them - highlighting the intrinsic security model
        // offered by a blockchain system like Ethereum
        uint amount = ERC20Interface(asset).balanceOf(this);
        if(lock.balance != 0) {
            if(lock.balance != amount) {
                lock.balance = amount;
                return OK;
            }
            return TIME_LOCK_INVALID_INVOCATION;
        }
        if (amount == 0) {
            return TIME_LOCK_BALANCE_ERROR;
        }
        //1533081600 => 2018-08-01
        lock = accountData(amount, 1533081600);
        return OK;
    }

    function payOut(address _getter) onlyContractOwner returns(uint errorCode) {
        // check if user has funds due for pay out because lock time is over
        uint amount = lock.balance;
        if (now < lock.releaseTime) {
            return TIME_LOCK_TIMESTAMP_ERROR;
        }
        if (amount == 0) {
            return TIME_LOCK_BALANCE_ERROR;
        }
        if(!ERC20Interface(asset).transfer(_getter,amount)) {
            return TIME_LOCK_TRANSFER_ERROR;
        } 
        selfdestruct(msg.sender);     
        return OK;
    }

    function getLockedFunds() constant returns (uint) {
        return lock.balance;
    }
    
    function getLockedFundsReleaseTime() constant returns (uint) {
	    return lock.releaseTime;
    }

}