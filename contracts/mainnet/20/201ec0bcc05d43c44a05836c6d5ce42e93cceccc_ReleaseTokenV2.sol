pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


interface iContract {
    function transferOwnership(address _newOwner) external;
    function owner() external view returns (address);
}

contract OwnerContract is Ownable {
    iContract public ownedContract;
    address origOwner;

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function setContract(address _contract) public onlyOwner {
        require(_contract != address(0));
        ownedContract = iContract(_contract);
        origOwner = ownedContract.owner();
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one. 
     *
     */
    function transferOwnershipBack() public onlyOwner {
        ownedContract.transferOwnership(origOwner);
        ownedContract = iContract(address(0));
        origOwner = address(0);
    }
}

interface itoken {
    // mapping (address => bool) public frozenAccount;
    function freezeAccount(address _target, bool _freeze) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
    // function transferOwnership(address newOwner) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
    function frozenAccount(address _account) external view returns (bool);
}

contract ReleaseToken is OwnerContract {
    using SafeMath for uint256;

    // record lock time period and related token amount
    struct TimeRec {
        uint256 amount;
        uint256 remain;
        uint256 endTime;
        uint256 releasePeriodEndTime;
    }

    itoken public owned;

    address[] public frozenAccounts;
    mapping (address => TimeRec[]) frozenTimes;
    // mapping (address => uint256) releasedAmounts;
    mapping (address => uint256) preReleaseAmounts;

    event ReleaseFunds(address _target, uint256 _amount);

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function setContract(address _contract) onlyOwner public {
        super.setContract(_contract);
        owned = itoken(_contract);
    }

    /**
     * @dev remove an account from the frozen accounts list
     *
     * @param _ind the index of the account in the list
     */
    function removeAccount(uint _ind) internal returns (bool) {
        require(_ind >= 0);
        require(_ind < frozenAccounts.length);
        
        uint256 i = _ind;
        while (i < frozenAccounts.length.sub(1)) {
            frozenAccounts[i] = frozenAccounts[i.add(1)];
            i = i.add(1);
        }

        frozenAccounts.length = frozenAccounts.length.sub(1);
        return true;
    }

    /**
     * @dev remove a time records from the time records list of one account
     *
     * @param _target the account that holds a list of time records which record the freeze period
     */
    function removeLockedTime(address _target, uint _ind) internal returns (bool) {
        require(_ind >= 0);
        require(_target != address(0));

        TimeRec[] storage lockedTimes = frozenTimes[_target];
        require(_ind < lockedTimes.length);
       
        uint256 i = _ind;
        while (i < lockedTimes.length.sub(1)) {
            lockedTimes[i] = lockedTimes[i.add(1)];
            i = i.add(1);
        }

        lockedTimes.length = lockedTimes.length.sub(1);
        return true;
    }

    /**
     * @dev get total remain locked tokens of an account
     *
     * @param _account the owner of some amount of tokens
     */
    function getRemainLockedOf(address _account) public view returns (uint256) {
        require(_account != address(0));

        uint256 totalRemain = 0;
        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _account) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;
                uint256 j = 0;
                while (j < timeRecLen) {
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    totalRemain = totalRemain.add(timePair.remain);

                    j = j.add(1);
                }
            }

            i = i.add(1);
        }

        return totalRemain;
    }

    /**
     * judge whether we need to release some of the locked token
     *
     */
    function needRelease() public view returns (bool) {
        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            uint256 timeRecLen = frozenTimes[frozenAddr].length;
            uint256 j = 0;
            while (j < timeRecLen) {
                TimeRec storage timePair = frozenTimes[frozenAddr][j];
                if (now >= timePair.endTime) {
                    return true;
                }

                j = j.add(1);
            }

            i = i.add(1);
        }

        return false;
    }

    /**
     * @dev freeze the amount of tokens of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _value the amount of the tokens
     * @param _frozenEndTime the end time of the lock period, unit is second
     * @param _releasePeriod the locking period, unit is second
     */
    function freeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0 && _releasePeriod >= 0);

        uint256 len = frozenAccounts.length;
        
        for (uint256 i = 0; i < len; i = i.add(1)) {
            if (frozenAccounts[i] == _target) {
                break;
            }            
        }

        if (i >= len) {
            frozenAccounts.push(_target); // add new account
        } 
        
        // each time the new locked time will be added to the backend
        frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _frozenEndTime.add(_releasePeriod)));
        owned.freezeAccount(_target, true);
        
        return true;
    }

    /**
     * @dev transfer an amount of tokens to an account, and then freeze the tokens
     *
     * @param _target the account address that will hold an amount of the tokens
     * @param _value the amount of the tokens which has been transferred
     * @param _frozenEndTime the end time of the lock period, unit is second
     * @param _releasePeriod the locking period, unit is second
     */
    function transferAndFreeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
        //require(_tokenOwner != address(0));
        require(_target != address(0));
        require(_value > 0);
        require(_frozenEndTime > 0 && _releasePeriod >= 0);

        // check firstly that the allowance of this contract has been set
        assert(owned.allowance(msg.sender, this) > 0);

        // freeze the account at first
        if (!freeze(_target, _value, _frozenEndTime, _releasePeriod)) {
            return false;
        }

        return (owned.transferFrom(msg.sender, _target, _value));
    }

    /**
     * release the token which are locked for once and will be total released at once 
     * after the end point of the lock period
     */
    function releaseAllOnceLock() onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address target = frozenAccounts[i];
            if (frozenTimes[target].length == 1 && frozenTimes[target][0].endTime == frozenTimes[target][0].releasePeriodEndTime && frozenTimes[target][0].endTime > 0 && now >= frozenTimes[target][0].endTime) {
                uint256 releasedAmount = frozenTimes[target][0].amount;
                    
                // remove current release period time record
                if (!removeLockedTime(target, 0)) {
                    return false;
                }

                // remove the froze account
                bool res = removeAccount(i);
                if (!res) {
                    return false;
                }
                
                owned.freezeAccount(target, false);
                //frozenTimes[destAddr][0].endTime = 0;
                //frozenTimes[destAddr][0].duration = 0;
                ReleaseFunds(target, releasedAmount);
                len = len.sub(1);
                //frozenTimes[destAddr][0].amount = 0;
                //frozenTimes[destAddr][0].remain = 0;
            } else { 
                // no account has been removed
                i = i.add(1);
            }
        }
        
        return true;
        //return (releaseMultiAccounts(frozenAccounts));
    }

    /**
     * @dev release the locked tokens owned by an account, which only have only one locked time
     * and don&#39;t have release stage.
     *
     * @param _target the account address that hold an amount of locked tokens
     */
    function releaseAccount(address _target) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address destAddr = frozenAccounts[i];
            if (destAddr == _target) {
                if (frozenTimes[destAddr].length == 1 && frozenTimes[destAddr][0].endTime == frozenTimes[destAddr][0].releasePeriodEndTime && frozenTimes[destAddr][0].endTime > 0 && now >= frozenTimes[destAddr][0].endTime) { 
                    uint256 releasedAmount = frozenTimes[destAddr][0].amount;
                    
                    // remove current release period time record
                    if (!removeLockedTime(destAddr, 0)) {
                        return false;
                    }

                    // remove the froze account
                    bool res = removeAccount(i);
                    if (!res) {
                        return false;
                    }

                    owned.freezeAccount(destAddr, false);
                    // frozenTimes[destAddr][0].endTime = 0;
                    // frozenTimes[destAddr][0].duration = 0;
                    ReleaseFunds(destAddr, releasedAmount);
                    // frozenTimes[destAddr][0].amount = 0;
                    // frozenTimes[destAddr][0].remain = 0;

                }

                // if the account are not locked for once, we will do nothing here
                return true; 
            }

            i = i.add(1);
        }
        
        return false;
    }    

    /**
     * @dev release the locked tokens owned by an account with several stages
     * this need the contract get approval from the account by call approve() in the token contract
     *
     * @param _target the account address that hold an amount of locked tokens
     * @param _dest the secondary address that will hold the released tokens
     */
    function releaseWithStage(address _target, address _dest) onlyOwner public returns (bool) {
        //require(_tokenaddr != address(0));
        require(_target != address(0));
        require(_dest != address(0));
        // require(_value > 0);
        
        // check firstly that the allowance of this contract from _target account has been set
        assert(owned.allowance(_target, this) > 0);

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            // firstly find the target address
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;

                bool released = false;
                uint256 nowTime = now;
                for (uint256 j = 0; j < timeRecLen; released = false) {
                    // iterate every time records to caculate how many tokens need to be released.
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    if (nowTime > timePair.endTime && timePair.endTime > 0 && timePair.releasePeriodEndTime > timePair.endTime) {                        
                        uint256 lastReleased = timePair.amount.sub(timePair.remain);
                        uint256 value = (timePair.amount * nowTime.sub(timePair.endTime) / timePair.releasePeriodEndTime.sub(timePair.endTime)).sub(lastReleased);
                        if (value > timePair.remain) {
                            value = timePair.remain;
                        } 
                        
                        // timePair.endTime = nowTime;        
                        timePair.remain = timePair.remain.sub(value);
                        ReleaseFunds(frozenAddr, value);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(value);
                        if (timePair.remain < 1e8) {
                            if (!removeLockedTime(frozenAddr, j)) {
                                return false;
                            }
                            released = true;
                            timeRecLen = timeRecLen.sub(1);
                        }
                        //owned.freezeAccount(frozenAddr, true);
                    } else if (nowTime >= timePair.endTime && timePair.endTime > 0 && timePair.releasePeriodEndTime == timePair.endTime) {
                        // owned.freezeAccount(frozenAddr, false);
                        timePair.remain = 0;
                        ReleaseFunds(frozenAddr, timePair.amount);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(timePair.amount);
                        if (!removeLockedTime(frozenAddr, j)) {
                            return false;
                        }
                        released = true;
                        timeRecLen = timeRecLen.sub(1);

                       //owned.freezeAccount(frozenAddr, true);
                    } 

                    if (!released) {
                        j = j.add(1);
                    }
                }

                // we got some amount need to be released
                if (preReleaseAmounts[frozenAddr] > 0) {
                    owned.freezeAccount(frozenAddr, false);
                    if (!owned.transferFrom(_target, _dest, preReleaseAmounts[frozenAddr])) {
                        return false;
                    }

                    // set the pre-release amount to 0 for next time
                    preReleaseAmounts[frozenAddr] = 0;
                }

                // if all the frozen amounts had been released, then unlock the account finally
                if (frozenTimes[frozenAddr].length == 0) {
                    if (!removeAccount(i)) {
                        return false;
                    }                    
                } else {
                    // still has some tokens need to be released in future
                    owned.freezeAccount(frozenAddr, true);
                }

                return true;
            }          

            i = i.add(1);
        }
        
        return false;
    }
}

contract ReleaseTokenV2 is ReleaseToken {
    mapping (address => uint256) oldBalances;
    mapping (address => address) public releaseAddrs;
    
    
    /**
     * @dev set the new endtime of the released time of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _oldEndTime the original endtime for the lock period
     * @param _newEndTime the new endtime for the lock period
     */
    function setNewEndtime(address _target, uint256 _oldEndTime, uint256 _newEndTime) public returns (bool) {
        require(_target != address(0));
        require(_oldEndTime > 0 && _newEndTime > 0);

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;
                uint256 j = 0;
                while (j < timeRecLen) {
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    if (_oldEndTime == timePair.endTime) {
                        uint256 duration = timePair.releasePeriodEndTime.sub(timePair.endTime);
                        timePair.endTime = _newEndTime;
                        timePair.releasePeriodEndTime = timePair.endTime.add(duration);                        
                        
                        return true;
                    }

                    j = j.add(1);
                }

                return false;
            }

            i = i.add(1);
        }

        return false;
    }

    /**
     * @dev set the new released period length of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _origEndTime the original endtime for the lock period
     * @param _duration the new releasing period
     */
    function setNewReleasePeriod(address _target, uint256 _origEndTime, uint256 _duration) public returns (bool) {
        require(_target != address(0));
        require(_origEndTime > 0 && _duration > 0);

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                uint256 timeRecLen = frozenTimes[frozenAddr].length;
                uint256 j = 0;
                while (j < timeRecLen) {
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    if (_origEndTime == timePair.endTime) {
                        timePair.releasePeriodEndTime = _origEndTime.add(_duration);
                        return true;
                    }

                    j = j.add(1);
                }

                return false;
            }

            i = i.add(1);
        }

        return false;
    }

    /**
     * @dev set the new released period length of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _releaseTo the address that will receive the released tokens
     */
    function setReleasedAddress(address _target, address _releaseTo) public {
        require(_target != address(0));
        require(_releaseTo != address(0));

        releaseAddrs[_target] = _releaseTo;
    }

    /**
     * @dev get the locked stages of an account
     *
     * @param _target the owner of some amount of tokens
     */
    function getLockedStages(address _target) public view returns (uint) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                return frozenTimes[frozenAddr].length;               
            }

            i = i.add(1);
        }

        return 0;
    }

    /**
     * @dev get the endtime of the locked stages of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _num the stage number of the releasing period
     */
    function getEndTimeOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                TimeRec storage timePair = frozenTimes[frozenAddr][_num];                
                return timePair.endTime;               
            }

            i = i.add(1);
        }

        return 0;
    }

    /**
     * @dev get the remain unrleased tokens of the locked stages of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _num the stage number of the releasing period
     */
    function getRemainOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                TimeRec storage timePair = frozenTimes[frozenAddr][_num];                
                return timePair.remain;               
            }

            i = i.add(1);
        }

        return 0;
    }

    /**
     * @dev get the remain releasing period of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _num the stage number of the releasing period
     */
    function getRemainReleaseTimeOfStage(address _target, uint _num) public view returns (uint256) {
        require(_target != address(0));

        uint256 len = frozenAccounts.length;
        uint256 i = 0;
        while (i < len) {
            address frozenAddr = frozenAccounts[i];
            if (frozenAddr == _target) {
                TimeRec storage timePair = frozenTimes[frozenAddr][_num];  
                if (timePair.releasePeriodEndTime == timePair.endTime || now <= timePair.endTime ) {
                    return (timePair.releasePeriodEndTime.sub(timePair.endTime));
                }    

                if (timePair.releasePeriodEndTime < now) {
                    return 0;
                }

                return (timePair.releasePeriodEndTime.sub(now));               
            }

            i = i.add(1);
        }

        return 0;
    }

    /**
     * @dev get the remain original tokens belong to an account before this time locking
     *
     * @param _target the owner of some amount of tokens
     */
    function gatherOldBalanceOf(address _target) public returns (uint256) {
        require(_target != address(0));
        require(frozenTimes[_target].length == 0); // no freeze action on this address

        // store the original balance if this the new freeze
        uint256 origBalance = owned.balanceOf(_target);
        if (origBalance > 0) {
            oldBalances[_target] = origBalance;
        }

        return origBalance;
    }

    /**
     * @dev get all the remain original tokens belong to a serial of accounts before this time locking
     *
     * @param _targets the owner of some amount of tokens
     */
    function gatherAllOldBalanceOf(address[] _targets) public returns (uint256) {
        require(_targets.length != 0);
        
        uint256 res = 0;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = res.add(gatherOldBalanceOf(_targets[i]));
        }

        return res;
    }
    
    /**
     * @dev freeze the amount of tokens of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _value the amount of the tokens
     * @param _frozenEndTime the end time of the lock period, unit is second
     * @param _releasePeriod the locking period, unit is second
     */
    function freeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
        if (frozenTimes[_target].length == 0) {
            gatherOldBalanceOf(_target);
        }
        return super.freeze(_target, _value, _frozenEndTime, _releasePeriod);
    }    

    /**
     * @dev release the locked tokens owned by an account, which are the tokens
     * that belong to this account before being locked.
     * this need the releasing-to address has already been set.
     *
     * @param _target the account address that hold an amount of locked tokens
     */
    function releaseOldBalanceOf(address _target) onlyOwner public returns (bool) {
        require(_target != address(0));
        require(releaseAddrs[_target] != address(0));

        // check firstly that the allowance of this contract from _target account has been set
        assert(owned.allowance(_target, this) > 0);

        // we got some amount need to be released
        if (oldBalances[_target] > 0) {
            bool freezeStatus = owned.frozenAccount(_target);
            owned.freezeAccount(_target, false);
            if (!owned.transferFrom(_target, releaseAddrs[_target], oldBalances[_target])) {
                return false;
            }

            // in this situation, the account should be still in original locked status
            owned.freezeAccount(_target, freezeStatus);
        }

        return true;
    }    

    /**
     * @dev release the locked tokens owned by an account with several stages
     * this need the contract get approval from the account by call approve() in the token contract
     * and also need the releasing-to address has already been set.
     *
     * @param _target the account address that hold an amount of locked tokens
     */
    function releaseByStage(address _target) onlyOwner public returns (bool) {
        require(_target != address(0));

        return releaseWithStage(_target, releaseAddrs[_target]);
    }  
}