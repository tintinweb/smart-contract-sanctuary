pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
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


interface itoken {
    // mapping (address => bool) public frozenAccount;
    function freezeAccount(address _target, bool _freeze) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transferOwnership(address newOwner) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract OwnerContract is Ownable {
    itoken public owned;
    
    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function setContract(address _contract) public onlyOwner {
        require(_contract != address(0));
        owned = itoken(_contract);
    }

    /**
     * @dev change the owner of the contract from this contract to another 
     *
     * @param _newOwner the new contract/account address that will be the new owner
     */
    function changeContractOwner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0));
        owned.transferOwnership(_newOwner);
        owned = itoken(address(0));
        
        return true;
    }
}

contract ReleaseToken is OwnerContract {
    using SafeMath for uint256;

    // record lock time period and related token amount
    struct TimeRec {
        uint256 amount;
        uint256 remain;
        uint256 endTime;
        uint256 duration;
    }

    address[] public frozenAccounts;
    mapping (address => TimeRec[]) frozenTimes;
    // mapping (address => uint256) releasedAmounts;
    mapping (address => uint256) preReleaseAmounts;

    event ReleaseFunds(address _target, uint256 _amount);

    function removeAccount(uint _ind) internal returns (bool) {
        require(_ind >= 0);
        require(_ind < frozenAccounts.length);

        //if (_ind >= frozenAccounts.length) {
        //    return false;
        //}

        uint256 i = _ind;
        while (i < frozenAccounts.length.sub(1)) {
            frozenAccounts[i] = frozenAccounts[i.add(1)];
            i = i.add(1);
        }

        frozenAccounts.length = frozenAccounts.length.sub(1);
        return true;
    }

    function removeLockedTime(address _target, uint _ind) internal returns (bool) {
        require(_ind >= 0);
        require(_target != address(0));

        TimeRec[] storage lockedTimes = frozenTimes[_target];
        require(_ind < lockedTimes.length);
        //if (_ind >= lockedTimes.length) {
        //    return false;
        //}

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

            //frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _releasePeriod))
        } /* else {
            uint256 timeArrayLen = frozenTimes[_target].length;
            uint256 j = 0;
            while (j < timeArrayLen) {
                TimeRec storage lastTime = frozenTimes[_target][j];
                if (lastTime.amount == 0 && lastTime.remain == 0 && lastTime.endTime == 0 && lastTime.duration == 0) {
                    lastTime.amount = _value;
                    lastTime.remain = _value;
                    lastTime.endTime = _frozenEndTime;
                    lastTime.duration = _releasePeriod; 
                    
                    break;
                }

                j = j.add(1);
            }
            
            if (j >= timeArrayLen) {
                frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _releasePeriod));
            }
        } */

        // frozenTimes[_target] = _frozenEndTime;
        
        // each time the new locked time will be added to the backend
        frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _releasePeriod));
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
    function transferAndFreeze(/*address _tokenOwner, */address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) onlyOwner public returns (bool) {
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
            if (frozenTimes[target].length == 1 && 0 == frozenTimes[target][0].duration && frozenTimes[target][0].endTime > 0 && now >= frozenTimes[target][0].endTime) {
                bool res = removeAccount(i);
                if (!res) {
                    return false;
                }
                
                owned.freezeAccount(target, false);
                //frozenTimes[destAddr][0].endTime = 0;
                //frozenTimes[destAddr][0].duration = 0;
                ReleaseFunds(target, frozenTimes[target][0].amount);
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
                if (frozenTimes[destAddr].length == 1 && 0 == frozenTimes[destAddr][0].duration && frozenTimes[destAddr][0].endTime > 0 && now >= frozenTimes[destAddr][0].endTime) { 
                    bool res = removeAccount(i);
                    if (!res) {
                        return false;
                    }

                    owned.freezeAccount(destAddr, false);
                    // frozenTimes[destAddr][0].endTime = 0;
                    // frozenTimes[destAddr][0].duration = 0;
                    ReleaseFunds(destAddr, frozenTimes[destAddr][0].amount);
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
     * @dev release the locked tokens owned by a number of accounts
     *
     * @param _targets the accounts list that hold an amount of locked tokens 
     */
    function releaseMultiAccounts(address[] _targets) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_targets.length != 0);

        uint256 i = 0;
        while (i < _targets.length) {
            if (!releaseAccount(_targets[i])) {
                return false;
            }

            i = i.add(1);
        }

        return true;
    }

    /**
     * @dev release the locked tokens owned by an account with several stages
     * this need the contract get approval from the account by call approve() in the token contract
     *
     * @param _target the account address that hold an amount of locked tokens
     * @param _dest the secondary address that will hold the released tokens
     */
    function releaseWithStage(address _target, address _dest) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
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
                for (uint256 j = 0; j < timeRecLen; released = false) {
                    // iterate every time records to caculate how many tokens need to be released.
                    TimeRec storage timePair = frozenTimes[frozenAddr][j];
                    uint256 nowTime = now;
                    if (nowTime > timePair.endTime && timePair.endTime > 0 && timePair.duration > 0) {                        
                        uint256 value = timePair.amount * (nowTime - timePair.endTime) / timePair.duration;
                        if (value > timePair.remain) {
                            value = timePair.remain;
                        } 
                        
                        // owned.freezeAccount(frozenAddr, false);
                        
                        timePair.endTime = nowTime;        
                        timePair.remain = timePair.remain.sub(value);
                        if (timePair.remain < 1e8) {
                            if (!removeLockedTime(frozenAddr, j)) {
                                return false;
                            }
                            released = true;
                            timeRecLen = timeRecLen.sub(1);
                        }
                        // if (!owned.transferFrom(_target, _dest, value)) {
                        //     return false;
                        // }
                        ReleaseFunds(frozenAddr, value);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(value);
                        //owned.freezeAccount(frozenAddr, true);
                    } else if (nowTime >= timePair.endTime && timePair.endTime > 0 && timePair.duration == 0) {
                        // owned.freezeAccount(frozenAddr, false);
                        
                        if (!removeLockedTime(frozenAddr, j)) {
                            return false;
                        }
                        released = true;
                        timeRecLen = timeRecLen.sub(1);

                        // if (!owned.transferFrom(_target, _dest, timePair.amount)) {
                        //     return false;
                        // }
                        ReleaseFunds(frozenAddr, timePair.amount);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(timePair.amount);
                        //owned.freezeAccount(frozenAddr, true);
                    } //else if (timePair.amount == 0 && timePair.remain == 0 && timePair.endTime == 0 && timePair.duration == 0) {
                      //  removeLockedTime(frozenAddr, j);
                    //}

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

    /**
     * @dev release the locked tokens owned by an account
     *
     * @param _targets the account addresses list that hold amounts of locked tokens
     * @param _dests the secondary addresses list that will hold the released tokens for each target account
     */
    function releaseMultiWithStage(address[] _targets, address[] _dests) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_targets.length != 0);
        require(_dests.length != 0);
        assert(_targets.length == _dests.length);

        uint256 i = 0;
        while (i < _targets.length) {
            if (!releaseWithStage(_targets[i], _dests[i])) {
                return false;
            }

            i = i.add(1);
        }

        return true;
    }
}