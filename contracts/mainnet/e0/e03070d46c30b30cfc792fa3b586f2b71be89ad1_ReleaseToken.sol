pragma solidity ^0.4.21;

interface itoken {
    function freezeAccount(address _target, bool _freeze) external;
    function freezeAccountPartialy(address _target, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
    // function transferOwnership(address newOwner) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
    function frozenAccount(address _account) external view returns (bool);
    function frozenAmount(address _account) external view returns (uint256);
}

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract OwnerContract is Claimable {
    Claimable public ownedContract;
    address internal origOwner;

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        origOwner = ownedContract.owner();

        // take ownership of the owned contract
        ownedContract.claimOwnership();

        return true;
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one.
     *
     */
    function transferOwnershipBack() onlyOwner public {
        ownedContract.transferOwnership(origOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }

    /**
     * @dev change the owner of the contract from this contract address to another one.
     *
     * @param _nextOwner the contract address that will be next Owner of the original Contract
     */
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }
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

    itoken internal owned;

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
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        owned = itoken(_contract);
        return super.bindContract(_contract);
    }

    /**
     * @dev remove an account from the frozen accounts list
     *
     * @param _ind the index of the account in the list
     */
    function removeAccount(uint _ind) internal returns (bool) {
        require(_ind < frozenAccounts.length);

        uint256 i = _ind;
        while (i < frozenAccounts.length.sub(1)) {
            frozenAccounts[i] = frozenAccounts[i.add(1)];
            i = i.add(1);
        }

        delete frozenAccounts[frozenAccounts.length.sub(1)];
        frozenAccounts.length = frozenAccounts.length.sub(1);
        return true;
    }

    /**
     * @dev remove a time records from the time records list of one account
     *
     * @param _target the account that holds a list of time records which record the freeze period
     */
    function removeLockedTime(address _target, uint _ind) internal returns (bool) {
        require(_target != address(0));

        TimeRec[] storage lockedTimes = frozenTimes[_target];
        require(_ind < lockedTimes.length);

        uint256 i = _ind;
        while (i < lockedTimes.length.sub(1)) {
            lockedTimes[i] = lockedTimes[i.add(1)];
            i = i.add(1);
        }

        delete lockedTimes[lockedTimes.length.sub(1)];
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
        require(_frozenEndTime > 0);

        uint256 len = frozenAccounts.length;

        uint256 i = 0;
        for (; i < len; i = i.add(1)) {
            if (frozenAccounts[i] == _target) {
                break;
            }
        }

        if (i >= len) {
            frozenAccounts.push(_target); // add new account
        }

        // each time the new locked time will be added to the backend
        frozenTimes[_target].push(TimeRec(_value, _value, _frozenEndTime, _frozenEndTime.add(_releasePeriod)));
        if (owned.frozenAccount(_target)) {
            uint256 preFrozenAmount = owned.frozenAmount(_target);
            owned.freezeAccountPartialy(_target, _value.add(preFrozenAmount));
        } else {
            owned.freezeAccountPartialy(_target, _value);
        }

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
        require(_frozenEndTime > 0);

        // check firstly that the allowance of this contract has been set
        require(owned.allowance(msg.sender, this) > 0);

        // now we need transfer the funds before freeze them
        require(owned.transferFrom(msg.sender, _target, _value));

        // freeze the account after transfering funds
        if (!freeze(_target, _value, _frozenEndTime, _releasePeriod)) {
            return false;
        }

        return true;
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
                if (!removeAccount(i)) {
                    return false;
                }

                uint256 preFrozenAmount = owned.frozenAmount(target);
                if (preFrozenAmount > releasedAmount) {
                    owned.freezeAccountPartialy(target, preFrozenAmount.sub(releasedAmount));
                } else {
                    owned.freezeAccount(target, false);
                }

                ReleaseFunds(target, releasedAmount);
                len = len.sub(1);
            } else {
                // no account has been removed
                i = i.add(1);
            }
        }

        return true;
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
                    if (!removeAccount(i)) {
                        return false;
                    }

                    uint256 preFrozenAmount = owned.frozenAmount(destAddr);
                    if (preFrozenAmount > releasedAmount) {
                        owned.freezeAccountPartialy(destAddr, preFrozenAmount.sub(releasedAmount));
                    } else {
                        owned.freezeAccount(destAddr, false);
                    }

                    ReleaseFunds(destAddr, releasedAmount);
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
     */
    function releaseWithStage(address _target/*, address _dest*/) onlyOwner public returns (bool) {
        //require(_tokenaddr != address(0));
        require(_target != address(0));
        // require(_dest != address(0));
        // require(_value > 0);

        // check firstly that the allowance of this contract from _target account has been set
        // require(owned.allowance(_target, this) > 0);

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
                    } else if (nowTime >= timePair.endTime && timePair.endTime > 0 && timePair.releasePeriodEndTime == timePair.endTime) {
                        timePair.remain = 0;
                        ReleaseFunds(frozenAddr, timePair.amount);
                        preReleaseAmounts[frozenAddr] = preReleaseAmounts[frozenAddr].add(timePair.amount);
                        if (!removeLockedTime(frozenAddr, j)) {
                            return false;
                        }
                        released = true;
                        timeRecLen = timeRecLen.sub(1);
                    }

                    if (!released) {
                        j = j.add(1);
                    }
                }

                // we got some amount need to be released
                if (preReleaseAmounts[frozenAddr] > 0) {
                    uint256 preReleasedAmount = preReleaseAmounts[frozenAddr];
                    uint256 preFrozenAmount = owned.frozenAmount(frozenAddr);

                    // set the pre-release amount to 0 for next time
                    preReleaseAmounts[frozenAddr] = 0;
                    if (preFrozenAmount > preReleasedAmount) {
                        owned.freezeAccountPartialy(frozenAddr, preFrozenAmount.sub(preReleasedAmount));
                    } else {
                        owned.freezeAccount(frozenAddr, false);
                    }
                    // if (!owned.transferFrom(_target, _dest, preReleaseAmounts[frozenAddr])) {
                    //     return false;
                    // }
                }

                // if all the frozen amounts had been released, then unlock the account finally
                if (frozenTimes[frozenAddr].length == 0) {
                    if (!removeAccount(i)) {
                        return false;
                    }
                } /*else {
                    // still has some tokens need to be released in future
                    owned.freezeAccount(frozenAddr, true);
                }*/

                return true;
            }

            i = i.add(1);
        }

        return false;
    }

    /**
     * @dev set the new endtime of the released time of an account
     *
     * @param _target the owner of some amount of tokens
     * @param _oldEndTime the original endtime for the lock period
     * @param _newEndTime the new endtime for the lock period
     */
    function setNewEndtime(address _target, uint256 _oldEndTime, uint256 _newEndTime) onlyOwner public returns (bool) {
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
    function setNewReleasePeriod(address _target, uint256 _origEndTime, uint256 _duration) onlyOwner public returns (bool) {
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
                uint256 nowTime = now;
                if (timePair.releasePeriodEndTime == timePair.endTime || nowTime <= timePair.endTime ) {
                    return (timePair.releasePeriodEndTime.sub(timePair.endTime));
                }

                if (timePair.releasePeriodEndTime < nowTime) {
                    return 0;
                }

                return (timePair.releasePeriodEndTime.sub(nowTime));
            }

            i = i.add(1);
        }

        return 0;
    }

    /**
     * @dev release the locked tokens owned by a number of accounts
     *
     * @param _targets the accounts list that hold an amount of locked tokens
     */
    function releaseMultiAccounts(address[] _targets) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            res = releaseAccount(_targets[i]) || res;
            i = i.add(1);
        }

        return res;
    }

    /**
     * @dev release the locked tokens owned by an account
     *
     * @param _targets the account addresses list that hold amounts of locked tokens
     */
    function releaseMultiWithStage(address[] _targets) onlyOwner public returns (bool) {
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            require(_targets[i] != address(0));

            res = releaseWithStage(_targets[i]) || res; // as long as there is one true transaction, then the result will be true
            i = i.add(1);
        }

        return res;
    }

     /**
     * @dev freeze multiple of the accounts
     *
     * @param _targets the owners of some amount of tokens
     * @param _values the amounts of the tokens
     * @param _frozenEndTimes the list of the end time of the lock period, unit is second
     * @param _releasePeriods the list of the locking period, unit is second
     */
    function freezeMulti(address[] _targets, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = freeze(_targets[i], _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res;
        }

        return res;
    }

    /**
     * @dev transfer a list of amounts of tokens to a list of accounts, and then freeze the tokens
     *
     * @param _targets the account addresses that will hold a list of amounts of the tokens
     * @param _values the amounts of the tokens which have been transferred
     * @param _frozenEndTimes the end time list of the locked periods, unit is second
     * @param _releasePeriods the list of locking periods, unit is second
     */
    function transferAndFreezeMulti(address[] _targets, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = transferAndFreeze(_targets[i], _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res;
        }

        return res;
    }
}