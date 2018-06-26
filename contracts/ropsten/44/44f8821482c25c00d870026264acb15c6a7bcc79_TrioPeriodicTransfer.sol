pragma solidity ^0.4.21;
contract TripioToken {
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}
/**
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    function Owned() public {
        owner = msg.sender;
    }

    /**
     * Only the owner of contract
     */ 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * transfer the ownership to other
     * - Only the owner can operate
     */ 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /** 
     * Accept the ownership from last owner
     */ 
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract TPTData {
    address public trioContract;

    struct Contributor {
        uint256 next;
        uint256 prev;
        uint256 cid;
        address contributor;
        bytes32 name;
    }
    
    struct ContributorChain {
        uint256 balance;
        uint256 head;
        uint256 tail;
        uint256 index;
        mapping(uint256 => Contributor) nodes; // cid -> Contributor
    }

    struct Schedule {
        uint256 next;
        uint256 prev;
        uint256 sid;
        uint32 timestamp;
        uint256 trio;
    }

    struct ScheduleChain {
        uint256 balance;
        uint256 head;
        uint256 tail;
        uint256 index;
        mapping (uint256 => Schedule) nodes;
    }

    // The contributors chain
    ContributorChain contributorChain;

    // The schedules chains
    mapping (uint256 => ScheduleChain) scheduleChains;

    /**
     * The contributor is valid
     */
    modifier contributorValid(uint256 _cid) {
        require(contributorChain.nodes[_cid].cid == _cid);
        _;
    }

    /**
     * The schedule is valid
     */
    modifier scheduleValid(uint256 _cid, uint256 _sid) {
        require(scheduleChains[_cid].nodes[_sid].sid == _sid);
        _;
    }
}
contract TPTContributors is TPTData, Owned {
    function TPTContributors() public {
        
    }

    /**
     * This emits when contributors are added
     */
    event ContributorsAdded(address[] indexed _contributors);

    /**
     * This emits when contributors are removed
     */
    event ContributorsRemoved(uint256[] indexed _cids);


    /**
     * Record `_contributor`
     */
    function _pushContributor(address _contributor, bytes32 _name) internal {
        require(_contributor != address(0));
        uint256 prev = 0;
        uint256 cid = contributorChain.index + 1;
        if (contributorChain.balance == 0) {
            contributorChain = ContributorChain(1, cid, cid, cid);
            contributorChain.nodes[cid] = Contributor(0, 0, cid, _contributor, _name);
        } else {
            contributorChain.index = cid;
            prev = contributorChain.tail;
            contributorChain.balance++;

            contributorChain.nodes[cid] = Contributor(0, prev, cid, _contributor, _name);
            contributorChain.nodes[prev].next = cid;
            contributorChain.tail = cid;
        }
    }

    /**
     * Remove contributor by `_cid`
     */
    function _removeContributor(uint _cid) internal contributorValid(_cid) {
        require(_cid != 0);
        uint256 next = 0;
        uint256 prev = 0;
        require(contributorChain.nodes[_cid].cid == _cid);
        next = contributorChain.nodes[_cid].next;
        prev = contributorChain.nodes[_cid].prev;
        if (next == 0) {
            if(prev != 0) {
                contributorChain.nodes[prev].next = 0;
                delete contributorChain.nodes[_cid];
                contributorChain.tail = prev;
            }else {
                delete contributorChain.nodes[_cid];
                delete contributorChain;
            }
        } else {
            if (prev == 0) {
                contributorChain.head = next;
                contributorChain.nodes[next].prev = 0;
                delete contributorChain.nodes[_cid];
            } else {
                contributorChain.nodes[prev].next = next;
                contributorChain.nodes[next].prev = prev;
                delete contributorChain.nodes[_cid];
            }
        }
        if(contributorChain.balance > 0) {
            contributorChain.balance--;
        }
    }

    /**
     * Record `_contributors`
     * @param _contributors The contributor
     */
    function addContributors(address[] _contributors, bytes32[] _names) external onlyOwner {
        require(_contributors.length == _names.length && _contributors.length > 0);
        for(uint256 i = 0; i < _contributors.length; i++) {
            _pushContributor(_contributors[i], _names[i]);
        }

        // Event
        emit ContributorsAdded(_contributors);
    }

    /**
     * Remove contributor by `_cids`
     * @param _cids The contributor&#39;s ids
     */
    function removeContributors(uint256[] _cids) external onlyOwner {
        for(uint256 i = 0; i < _cids.length; i++) {
            _removeContributor(_cids[i]);
        }

        // Event
        emit ContributorsRemoved(_cids);
    }

    /**
     * Returns all the contributors
     * @return All the contributors
     */
    function contributors() public view returns(uint256[]) {
        uint256 count;
        uint256 index;
        uint256 next;
        index = 0;
        next = contributorChain.head;
        count = contributorChain.balance;
        if (count > 0) {
            uint256[] memory result = new uint256[](count);
            while(next != 0 && index < count) {
                result[index] = contributorChain.nodes[next].cid;
                next = contributorChain.nodes[next].next;
                index++;
            }
            return result;
        } else {
            return new uint256[](0);
        }
    }

    /**
     * Return the contributor by `_cid`
     * @return The contributor
     */
    function contributor(uint _cid) external view returns(address, bytes32) {
        return (contributorChain.nodes[_cid].contributor, contributorChain.nodes[_cid].name);
    }  
}
contract TPTSchedules is TPTData, Owned {
    function TPTSchedules() public {
        
    }

    /**
     * This emits when schedules are inserted
     */
    event SchedulesInserted(uint256 _cid);

    /**
     * This emits when schedules are removed
     */
    event SchedulesRemoved(uint _cid, uint256[] _sids);

    /**
     * Record TRIO transfer schedule to  `_contributor`
     * @param _cid The contributor
     * @param _timestamps The transfer timestamps
     * @param _trios The transfer trios
     */
    function insertSchedules(uint256 _cid, uint32[] _timestamps, uint256[] _trios) 
        external 
        onlyOwner 
        contributorValid(_cid) {
        require(_timestamps.length > 0 && _timestamps.length == _trios.length);
        for (uint256 i = 0; i < _timestamps.length; i++) {
            uint256 prev = 0;
            uint256 next = 0;
            uint256 sid = scheduleChains[_cid].index + 1;
            if (scheduleChains[_cid].balance == 0) {
                scheduleChains[_cid] = ScheduleChain(1, sid, sid, sid);
                scheduleChains[_cid].nodes[sid] = Schedule(0, 0, sid, _timestamps[i], _trios[i]);
            } else {
                scheduleChains[_cid].index = sid;
                scheduleChains[_cid].balance++;
                prev = scheduleChains[_cid].tail;
                while(scheduleChains[_cid].nodes[prev].timestamp > _timestamps[i] && prev != 0) {
                    prev = scheduleChains[_cid].nodes[prev].prev;
                }
                if (prev == 0) {
                    next = scheduleChains[_cid].head;
                    scheduleChains[_cid].nodes[sid] = Schedule(next, 0, sid, _timestamps[i], _trios[i]);
                    scheduleChains[_cid].nodes[next].prev = sid;
                    scheduleChains[_cid].head = sid;
                } else {
                    next = scheduleChains[_cid].nodes[prev].next;
                    scheduleChains[_cid].nodes[sid] = Schedule(next, prev, sid, _timestamps[i], _trios[i]);
                    scheduleChains[_cid].nodes[prev].next = sid;
                    if (next == 0) {
                        scheduleChains[_cid].tail = sid;
                    }else {
                        scheduleChains[_cid].nodes[next].prev = sid;
                    }
                }
            }
        }

        // Event
        emit SchedulesInserted(_cid);
    }

    /**
     * Remove schedule by `_cid` and `_sids`
     * @param _cid The contributor&#39;s id
     * @param _sids The schedule&#39;s ids
     */
    function removeSchedules(uint _cid, uint256[] _sids) 
        public 
        onlyOwner 
        contributorValid(_cid) {
        uint256 next = 0;
        uint256 prev = 0;
        uint256 sid;
        for (uint256 i = 0; i < _sids.length; i++) {
            sid = _sids[i];
            require(scheduleChains[_cid].nodes[sid].sid == sid);
            next = scheduleChains[_cid].nodes[sid].next;
            prev = scheduleChains[_cid].nodes[sid].prev;
            if (next == 0) {
                if(prev != 0) {
                    scheduleChains[_cid].nodes[prev].next = 0;
                    delete scheduleChains[_cid].nodes[sid];
                    scheduleChains[_cid].tail = prev;
                }else {
                    delete scheduleChains[_cid].nodes[sid];
                    delete scheduleChains[_cid];
                }
            } else {
                if (prev == 0) {
                    scheduleChains[_cid].head = next;
                    scheduleChains[_cid].nodes[next].prev = 0;
                    delete scheduleChains[_cid].nodes[sid];
                } else {
                    scheduleChains[_cid].nodes[prev].next = next;
                    scheduleChains[_cid].nodes[next].prev = prev;
                    delete scheduleChains[_cid].nodes[sid];
                }
            }
            if(scheduleChains[_cid].balance > 0) {
                scheduleChains[_cid].balance--;
            }   
        }

        // Event
        emit SchedulesRemoved(_cid, _sids);
    }

    /**
     * Return all the schedules of `_cid`
     * @param _cid The contributor&#39;s id 
     * @return All the schedules of `_cid`
     */
    function schedules(uint256 _cid) 
        public 
        contributorValid(_cid) 
        view 
        returns(uint256[]) {
        uint256 count;
        uint256 index;
        uint256 next;
        index = 0;
        next = scheduleChains[_cid].head;
        count = scheduleChains[_cid].balance;
        if (count > 0) {
            uint256[] memory result = new uint256[](count);
            while(next != 0 && index < count) {
                result[index] = scheduleChains[_cid].nodes[next].sid;
                next = scheduleChains[_cid].nodes[next].next;
                index++;
            }
            return result;
        } else {
            return new uint256[](0);
        }
    }

    /**
     * Return the schedule by `_cid` and `_sid`
     * @param _cid The contributor&#39;s id
     * @param _sid The schedule&#39;s id
     * @return The schedule
     */
    function schedule(uint256 _cid, uint256 _sid) 
        public
        scheduleValid(_cid, _sid) 
        view 
        returns(uint32, uint256) {
        return (scheduleChains[_cid].nodes[_sid].timestamp, scheduleChains[_cid].nodes[_sid].trio);
    }
}
contract TPTTransfer is TPTContributors, TPTSchedules {
    function TPTTransfer() public {
        
    }

    /**
     * This emits when transfer 
     */
    event AutoTransfer(address indexed _to, uint256 _trio);

    /**
     * This emits when 
     */
    event AutoTransferCompleted();

    /**
     * Withdraw TRIO TOKEN balance from contract account, the balance will transfer to the contract owner
     */
    function withdrawToken() external onlyOwner {
        TripioToken tripio = TripioToken(trioContract);
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(owner, tokens);
    }

    /**
     * Auto Transfer All Schedules
     */
    function autoTransfer() external onlyOwner {
        // TRIO contract
        TripioToken tripio = TripioToken(trioContract);
        
        // All contributors
        uint256[] memory _contributors = contributors();
        for (uint256 i = 0; i < _contributors.length; i++) {
            // cid and contributor address
            uint256 _cid = _contributors[i];
            address _contributor = contributorChain.nodes[_cid].contributor;
            
            // All schedules
            uint256[] memory _schedules = schedules(_cid);
            for (uint256 j = 0; j < _schedules.length; j++) {
                // sid, trio and timestamp
                uint256 _sid = _schedules[j];
                uint256 _trio = scheduleChains[_cid].nodes[_sid].trio;
                uint256 _timestamp = scheduleChains[_cid].nodes[_sid].timestamp;

                // hasn&#39;t arrived
                if(_timestamp > now) {
                    break;
                }
                // Transfer TRIO to contributor
                tripio.transfer(_contributor, _trio);

                // Remove schedule of contributor
                uint256[] memory _sids = new uint256[](1);
                _sids[0] = _sid;
                removeSchedules(_cid, _sids);
                emit AutoTransfer(_contributor, _trio);
            }
        }

        emit AutoTransferCompleted();
    }

    /**
     * Is there any transfer in schedule
     */
    function totalTransfersInSchedule() external view returns(uint256,uint256) {
        // All contributors
        uint256[] memory _contributors = contributors();
        uint256 total = 0;
        uint256 amount = 0;
        for (uint256 i = 0; i < _contributors.length; i++) {
            // cid and contributor address
            uint256 _cid = _contributors[i];            
            // All schedules
            uint256[] memory _schedules = schedules(_cid);
            for (uint256 j = 0; j < _schedules.length; j++) {
                // sid, trio and timestamp
                uint256 _sid = _schedules[j];
                uint256 _timestamp = scheduleChains[_cid].nodes[_sid].timestamp;
                if(_timestamp < now) {
                    total++;
                    amount += scheduleChains[_cid].nodes[_sid].trio;
                }
            }
        }
        return (total,amount);
    }
}

contract TrioPeriodicTransfer is TPTTransfer {
    function TrioPeriodicTransfer(address _trio) public {
        trioContract = _trio;
    }
}