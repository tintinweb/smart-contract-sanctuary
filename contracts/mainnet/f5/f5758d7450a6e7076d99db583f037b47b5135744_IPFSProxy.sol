pragma solidity ^0.4.19;

// File: contracts/IPFSEvents.sol

contract IPFSEvents {
    event HashAdded(string hash, uint ttl);
    event HashRemoved(string hash);

    event MetadataObjectAdded(string hash);
    event MetadataObjectRemoved(string hash);    
}

// File: contracts/Multimember.sol

contract Multimember {

    // TYPES

    // struct for the status of a pending operation.
    struct PendingState {
        uint yetNeeded;
        uint membersDone;
        uint index;
    }

    // EVENTS

    // this contract only has seven types of events: it can accept a confirmation, in which case
    // we record member and operation (hash) alongside it.
    event Confirmation(address member, bytes32 operation);
    event Revoke(address member, bytes32 operation);
    // some others are in the case of an member changing.
    event MemberChanged(address oldMember, address newMember);
    event MemberAdded(address newMember);
    event MemberRemoved(address oldMember);
    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

    // MODIFIERS

    // simple single-sig function modifier.
    modifier onlymember {
        if (isMember(msg.sender))
            _;
    }
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanymembers(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

    // METHODS

    // constructor is given number of sigs required to do protected "onlymanymembers" transactions
    // as well as the selection of addresses capable of confirming them.
    function Multimember(address[] _members, uint _required) public {
        m_numMembers = _members.length + 1;
        m_members[1] = uint(msg.sender);
        m_memberIndex[uint(msg.sender)] = 1;
        for (uint i = 0; i < _members.length; ++i) {
            m_members[2 + i] = uint(_members[i]);
            m_memberIndex[uint(_members[i])] = 2 + i;
        }
        m_required = _required;
    }
    
    // Revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        uint memberIndex = m_memberIndex[uint(msg.sender)];
        // make sure they&#39;re an member
        if (memberIndex == 0) 
            return;
        uint memberIndexBit = 2**memberIndex;
        var pending = m_pending[_operation];
        if (pending.membersDone & memberIndexBit > 0) {
            pending.yetNeeded++;
            pending.membersDone -= memberIndexBit;
            Revoke(msg.sender, _operation);
        }
    }
    
    // Replaces an member `_from` with another `_to`.
    function changeMember(address _from, address _to) onlymanymembers(keccak256(_from,_to)) external {
        if (isMember(_to)) 
            return;
        uint memberIndex = m_memberIndex[uint(_from)];
        if (memberIndex == 0) 
            return;

        clearPending();
        m_members[memberIndex] = uint(_to);
        m_memberIndex[uint(_from)] = 0;
        m_memberIndex[uint(_to)] = memberIndex;
        MemberChanged(_from, _to);
    }
    
    function addMember(address _member) onlymanymembers(keccak256(_member)) public {
        if (isMember(_member)) 
            return;

        clearPending();
        if (m_numMembers >= MAXMEMBERS)
            reorganizeMembers();
        if (m_numMembers >= MAXMEMBERS)
            return;
        m_numMembers++;
        m_members[m_numMembers] = uint(_member);
        m_memberIndex[uint(_member)] = m_numMembers;
        MemberAdded(_member);
    }
    
    function removeMember(address _member) onlymanymembers(keccak256(_member)) public {
        uint memberIndex = m_memberIndex[uint(_member)];
        if (memberIndex == 0) 
            return;
        if (m_required > m_numMembers - 1) 
            return;

        m_members[memberIndex] = 0;
        m_memberIndex[uint(_member)] = 0;
        clearPending();
        reorganizeMembers(); //make sure m_numMembers is equal to the number of members and always points to the optimal free slot
        MemberRemoved(_member);
    }
    
    function changeRequirement(uint _newRequired) onlymanymembers(keccak256(_newRequired)) external {
        if (_newRequired > m_numMembers) 
            return;
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }
    
    function isMember(address _addr) public constant returns (bool) { 
        return m_memberIndex[uint(_addr)] > 0;
    }
    
    function hasConfirmed(bytes32 _operation, address _member) external constant returns (bool) {
        var pending = m_pending[_operation];
        uint memberIndex = m_memberIndex[uint(_member)];

        // make sure they&#39;re an member
        if (memberIndex == 0) 
            return false;

        // determine the bit to set for this member.
        uint memberIndexBit = 2**memberIndex;
        return !(pending.membersDone & memberIndexBit == 0);
    }
    
    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
        // determine what index the present sender is:
        uint memberIndex = m_memberIndex[uint(msg.sender)];
        // make sure they&#39;re an member
        if (memberIndex == 0) 
            return;

        var pending = m_pending[_operation];
        // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_required;
            // reset which members have confirmed (none) - set our bitmap to 0.
            pending.membersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
        // determine the bit to set for this member.
        uint memberIndexBit = 2**memberIndex;
        // make sure we (the message sender) haven&#39;t confirmed this operation previously.
        if (pending.membersDone & memberIndexBit == 0) {
            Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead.
            if (pending.yetNeeded <= 1) {
                // enough confirmations: reset and run interior.
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            } else {
                // not enough: record that this member in particular confirmed.
                pending.yetNeeded--;
                pending.membersDone |= memberIndexBit;
            }
        }
    }

    function reorganizeMembers() private returns (bool) {
        uint free = 1;
        while (free < m_numMembers) {
            while (free < m_numMembers && m_members[free] != 0) {
                free++;
            } 

            while (m_numMembers > 1 && m_members[m_numMembers] == 0) {
                m_numMembers--;
            } 

            if (free < m_numMembers && m_members[m_numMembers] != 0 && m_members[free] == 0) {
                m_members[free] = m_members[m_numMembers];
                m_memberIndex[m_members[free]] = free;
                m_members[m_numMembers] = 0;
            }
        }
    }
    
    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i) {
            if (m_pendingIndex[i] != 0) {
                delete m_pending[m_pendingIndex[i]];
            }
        }
        delete m_pendingIndex;
    }
        
    // FIELDS

    // the number of members that must confirm the same operation before it is run.
    uint public m_required;
    // pointer used to find a free slot in m_members
    uint public m_numMembers;
    
    // list of members
    uint[256] m_members;
    uint constant MAXMEMBERS = 250;
    // index on the list of members to allow reverse lookup
    mapping(uint => uint) m_memberIndex;
    // the ongoing operations.
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}

// File: contracts/IPFSProxy.sol

contract IPFSProxy is IPFSEvents, Multimember {
    uint public persistLimit;

    event PersistLimitChanged(uint limit);	
    event ContractAdded(address pubKey,uint startBlock);
    event ContractRemoved(address pubKey);

    /**
    * @dev Constructor - adds the owner of the contract to the list of valid members
    */
    function IPFSProxy(address[] _members,uint _required, uint _persistlimit) Multimember (_members, _required) public {
        setTotalPersistLimit(_persistlimit);
        for (uint i = 0; i < _members.length; ++i) {
            MemberAdded(_members[i]);
        }
        addContract(this,block.number);
    }

    /**
    * @dev Add hash to persistent storage
    * @param _ipfsHash The ipfs hash to propagate.
    * @param _ttl amount of time is seconds to persist this. 0 = infinite
    */
    function addHash(string _ipfsHash, uint _ttl) public onlymember {
        HashAdded(_ipfsHash,_ttl);
    }

    /**
    * @dev Remove hash from persistent storage
    * @param _ipfsHash The ipfs hash to propagate.	
    */
    function removeHash(string _ipfsHash) public onlymember {
        HashRemoved(_ipfsHash);
    }

   /** 
    * Add a contract to watch list. Each proxy will then 
    * watch it for HashAdded and HashRemoved events 
    * and cache these events
    * @param _contractAddress The contract address.
    * @param _startBlock The startblock where to look for events.
    */
    function addContract(address _contractAddress,uint _startBlock) public onlymember {
        ContractAdded(_contractAddress,_startBlock);
    }

    /**
    * @dev Remove contract from watch list
    */
    function removeContract(address _contractAddress) public onlymember {
        require(_contractAddress != address(this));
        ContractRemoved(_contractAddress);
    }

   /** 
    * Add a metadata of an object. Each proxy will then 
    * read the ipfs hash file with the metadata about the object and parse it 
    */
    function addMetadataObject(string _metadataHash) public onlymember {
        HashAdded(_metadataHash,0);
        MetadataObjectAdded(_metadataHash);
    }

    /** 
    * removed a metadata of an object.
    */
    function removeMetadataObject(string _metadataHash) public onlymember {
        HashRemoved(_metadataHash);
        MetadataObjectRemoved(_metadataHash);
    }

    /**
    * @dev set total allowed upload
    *
    **/
    function setTotalPersistLimit (uint _limit) public onlymanymembers(keccak256(_limit)) {
        persistLimit = _limit;
        PersistLimitChanged(_limit);
    }
}