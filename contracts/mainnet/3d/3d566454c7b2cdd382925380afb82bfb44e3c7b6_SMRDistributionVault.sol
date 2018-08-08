pragma solidity ^0.4.18;

contract ArgumentsChecker {

    /// @dev check which prevents short address attack
    modifier payloadSizeIs(uint size) {
       require(msg.data.length == size + 4 /* function selector */);
       _;
    }

    /// @dev check that address is valid
    modifier validAddress(address addr) {
        require(addr != address(0));
        _;
    }
}

contract multiowned {

	// TYPES

    // struct for the status of a pending operation.
    struct MultiOwnedOperationPendingState {
        // count of confirmations needed
        uint yetNeeded;

        // bitmap of confirmations where owner #ownerIndex&#39;s decision corresponds to 2**ownerIndex bit
        uint ownersDone;

        // position of this operation key in m_multiOwnedPendingIndex
        uint index;
    }

	// EVENTS

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event FinalConfirmation(address owner, bytes32 operation);

    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

	// MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        require(isOwner(msg.sender));
        _;
    }
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
            _;
        }
        // Even if required number of confirmations has&#39;t been collected yet,
        // we can&#39;t throw here - because changes to the state have to be preserved.
        // But, confirmAndCheck itself will throw in case sender is not an owner.
    }

    modifier validNumOwners(uint _numOwners) {
        require(_numOwners > 0 && _numOwners <= c_maxOwners);
        _;
    }

    modifier multiOwnedValidRequirement(uint _required, uint _numOwners) {
        require(_required > 0 && _required <= _numOwners);
        _;
    }

    modifier ownerExists(address _address) {
        require(isOwner(_address));
        _;
    }

    modifier ownerDoesNotExist(address _address) {
        require(!isOwner(_address));
        _;
    }

    modifier multiOwnedOperationIsActive(bytes32 _operation) {
        require(isOperationActive(_operation));
        _;
    }

	// METHODS

    // constructor is given number of sigs required to do protected "onlymanyowners" transactions
    // as well as the selection of addresses capable of confirming them (msg.sender is not added to the owners!).
    function multiowned(address[] _owners, uint _required)
        public
        validNumOwners(_owners.length)
        multiOwnedValidRequirement(_required, _owners.length)
    {
        assert(c_maxOwners <= 255);

        m_numOwners = _owners.length;
        m_multiOwnedRequired = _required;

        for (uint i = 0; i < _owners.length; ++i)
        {
            address owner = _owners[i];
            // invalid and duplicate addresses are not allowed
            require(0 != owner && !isOwner(owner) /* not isOwner yet! */);

            uint currentOwnerIndex = checkOwnerIndex(i + 1 /* first slot is unused */);
            m_owners[currentOwnerIndex] = owner;
            m_ownerIndex[owner] = currentOwnerIndex;
        }

        assertOwnersAreConsistent();
    }

    /// @notice replaces an owner `_from` with another `_to`.
    /// @param _from address of owner to replace
    /// @param _to address of new owner
    // All pending operations will be canceled!
    function changeOwner(address _from, address _to)
        external
        ownerExists(_from)
        ownerDoesNotExist(_to)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
        m_owners[ownerIndex] = _to;
        m_ownerIndex[_from] = 0;
        m_ownerIndex[_to] = ownerIndex;

        assertOwnersAreConsistent();
        OwnerChanged(_from, _to);
    }

    /// @notice adds an owner
    /// @param _owner address of new owner
    // All pending operations will be canceled!
    function addOwner(address _owner)
        external
        ownerDoesNotExist(_owner)
        validNumOwners(m_numOwners + 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

        assertOwnersAreConsistent();
        OwnerAdded(_owner);
    }

    /// @notice removes an owner
    /// @param _owner address of owner to remove
    // All pending operations will be canceled!
    function removeOwner(address _owner)
        external
        ownerExists(_owner)
        validNumOwners(m_numOwners - 1)
        multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
        m_owners[ownerIndex] = 0;
        m_ownerIndex[_owner] = 0;
        //make sure m_numOwners is equal to the number of owners and always points to the last owner
        reorganizeOwners();

        assertOwnersAreConsistent();
        OwnerRemoved(_owner);
    }

    /// @notice changes the required number of owner signatures
    /// @param _newRequired new number of signatures required
    // All pending operations will be canceled!
    function changeRequirement(uint _newRequired)
        external
        multiOwnedValidRequirement(_newRequired, m_numOwners)
        onlymanyowners(keccak256(msg.data))
    {
        m_multiOwnedRequired = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

    /// @notice Gets an owner by 0-indexed position
    /// @param ownerIndex 0-indexed owner position
    function getOwner(uint ownerIndex) public constant returns (address) {
        return m_owners[ownerIndex + 1];
    }

    /// @notice Gets owners
    /// @return memory array of owners
    function getOwners() public constant returns (address[]) {
        address[] memory result = new address[](m_numOwners);
        for (uint i = 0; i < m_numOwners; i++)
            result[i] = getOwner(i);

        return result;
    }

    /// @notice checks if provided address is an owner address
    /// @param _addr address to check
    /// @return true if it&#39;s an owner
    function isOwner(address _addr) public constant returns (bool) {
        return m_ownerIndex[_addr] > 0;
    }

    /// @notice Tests ownership of the current caller.
    /// @return true if it&#39;s an owner
    // It&#39;s advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
    // addOwner/changeOwner and to isOwner.
    function amIOwner() external constant onlyowner returns (bool) {
        return true;
    }

    /// @notice Revokes a prior confirmation of the given operation
    /// @param _operation operation value, typically keccak256(msg.data)
    function revoke(bytes32 _operation)
        external
        multiOwnedOperationIsActive(_operation)
        onlyowner
    {
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        var pending = m_multiOwnedPending[_operation];
        require(pending.ownersDone & ownerIndexBit > 0);

        assertOperationIsConsistent(_operation);

        pending.yetNeeded++;
        pending.ownersDone -= ownerIndexBit;

        assertOperationIsConsistent(_operation);
        Revoke(msg.sender, _operation);
    }

    /// @notice Checks if owner confirmed given operation
    /// @param _operation operation value, typically keccak256(msg.data)
    /// @param _owner an owner address
    function hasConfirmed(bytes32 _operation, address _owner)
        external
        constant
        multiOwnedOperationIsActive(_operation)
        ownerExists(_owner)
        returns (bool)
    {
        return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation)
        private
        onlyowner
        returns (bool)
    {
        if (512 == m_multiOwnedPendingIndex.length)
            // In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
            // we won&#39;t be able to do it because of block gas limit.
            // Yes, pending confirmations will be lost. Dont see any security or stability implications.
            // TODO use more graceful approach like compact or removal of clearPending completely
            clearPending();

        var pending = m_multiOwnedPending[_operation];

        // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
        if (! isOperationActive(_operation)) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_multiOwnedRequired;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_multiOwnedPendingIndex.length++;
            m_multiOwnedPendingIndex[pending.index] = _operation;
            assertOperationIsConsistent(_operation);
        }

        // determine the bit to set for this owner.
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        // make sure we (the message sender) haven&#39;t confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            // ok - check if count is enough to go ahead.
            assert(pending.yetNeeded > 0);
            if (pending.yetNeeded == 1) {
                // enough confirmations: reset and run interior.
                delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
                delete m_multiOwnedPending[_operation];
                FinalConfirmation(msg.sender, _operation);
                return true;
            }
            else
            {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
                assertOperationIsConsistent(_operation);
                Confirmation(msg.sender, _operation);
            }
        }
    }

    // Reclaims free slots between valid owners in m_owners.
    // TODO given that its called after each removal, it could be simplified.
    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            // iterating to the first free slot from the beginning
            while (free < m_numOwners && m_owners[free] != 0) free++;

            // iterating to the first occupied slot from the end
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;

            // swap, if possible, so free slot is located at the end after the swap
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                // owners between swapped slots should&#39;t be renumbered - that saves a lot of gas
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() private onlyowner {
        uint length = m_multiOwnedPendingIndex.length;
        // TODO block gas limit
        for (uint i = 0; i < length; ++i) {
            if (m_multiOwnedPendingIndex[i] != 0)
                delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
        }
        delete m_multiOwnedPendingIndex;
    }

    function checkOwnerIndex(uint ownerIndex) private pure returns (uint) {
        assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
        return ownerIndex;
    }

    function makeOwnerBitmapBit(address owner) private constant returns (uint) {
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
        return 2 ** ownerIndex;
    }

    function isOperationActive(bytes32 _operation) private constant returns (bool) {
        return 0 != m_multiOwnedPending[_operation].yetNeeded;
    }


    function assertOwnersAreConsistent() private constant {
        assert(m_numOwners > 0);
        assert(m_numOwners <= c_maxOwners);
        assert(m_owners[0] == 0);
        assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
    }

    function assertOperationIsConsistent(bytes32 _operation) private constant {
        var pending = m_multiOwnedPending[_operation];
        assert(0 != pending.yetNeeded);
        assert(m_multiOwnedPendingIndex[pending.index] == _operation);
        assert(pending.yetNeeded <= m_multiOwnedRequired);
    }


   	// FIELDS

    uint constant c_maxOwners = 250;

    // the number of owners that must confirm the same operation before it is run.
    uint public m_multiOwnedRequired;


    // pointer used to find a free slot in m_owners
    uint public m_numOwners;

    // list of owners (addresses),
    // slot 0 is unused so there are no owner which index is 0.
    // TODO could we save space at the end of the array for the common case of <10 owners? and should we?
    address[256] internal m_owners;

    // index on the list of owners to allow reverse lookup: owner address => index in m_owners
    mapping(address => uint) internal m_ownerIndex;


    // the ongoing operations.
    mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
    bytes32[] internal m_multiOwnedPendingIndex;
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISmartzToken {
    // multiowned
    function changeOwner(address _from, address _to) external;
    function addOwner(address _owner) external;
    function removeOwner(address _owner) external;
    function changeRequirement(uint _newRequired) external;
    function getOwner(uint ownerIndex) public view returns (address);
    function getOwners() public view returns (address[]);
    function isOwner(address _addr) public view returns (bool);
    function amIOwner() external view returns (bool);
    function revoke(bytes32 _operation) external;
    function hasConfirmed(bytes32 _operation, address _owner) external view returns (bool);

    // ERC20Basic
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    // ERC20
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    // BurnableToken
    function burn(uint256 _amount) public returns (bool);

    // TokenWithApproveAndCallMethod
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public;

    // SmartzToken
    function setKYCProvider(address KYCProvider) external;
    function setSale(address account, bool isSale) external;
    function disablePrivileged() external;

    function availableBalanceOf(address _owner) public view returns (uint256);
    function frozenCellCount(address owner) public view returns (uint);
    function frozenCell(address owner, uint index) public view returns (uint amount, uint thawTS, bool isKYCRequired);

    function frozenTransfer(address _to, uint256 _value, uint thawTS, bool isKYCRequired) external returns (bool);
    function frozenTransferFrom(address _from, address _to, uint256 _value, uint thawTS, bool isKYCRequired) external returns (bool);
}

contract SMRDistributionVault is ArgumentsChecker, multiowned, ERC20 {


    // PUBLIC FUNCTIONS

    function SMRDistributionVault()
        public
        payable
        multiowned(getInitialOwners(), 1)
    {
        m_SMR = ISmartzToken(address(0x40ae4acd08e65714b093bf2495fd7941aedfa231));
        m_thawTS = 1551398400;

        totalSupply = m_SMR.totalSupply();

        
    }

    function getInitialOwners() private pure returns (address[]) {
        address[] memory result = new address[](2);
result[0] = address(0x4ff9a68a832398c6b013633bb5682595ebb7b92e);
result[1] = address(0xe4074bb7bd4828baed9d2bece1e386408428dfb7);
        return result;
    }


    /// @notice Balance of tokens.
    /// @dev Owners are considered to possess all the tokens of this vault.
    function balanceOf(address who) public view returns (uint256) {
        return isOwner(who) ? m_SMR.balanceOf(this) : 0;
    }

    /// @notice Looks like transfer of this token, but actually frozenTransfers SMR.
    function transfer(address to, uint256 value)
        public
        payloadSizeIs(2 * 32)
        onlyowner
        returns (bool)
    {
        return m_SMR.frozenTransfer(to, value, m_thawTS, false);
    }

    /// @notice Transfers using plain transfer remaining tokens.
    function withdrawRemaining(address to)
        external
        payloadSizeIs(1 * 32)
        onlyowner
        returns (bool)
    {
        return m_SMR.transfer(to, m_SMR.balanceOf(this));
    }


    /// @dev There is no need to support this function.
    function allowance(address , address ) public view returns (uint256) {
        revert();
    }

    /// @dev There is no need to support this function.
    function transferFrom(address , address , uint256 ) public returns (bool) {
        revert();
    }

    /// @dev There is no need to support this function.
    function approve(address , uint256 ) public returns (bool) {
        revert();
    }

    function decimals() public view returns (uint8) {
        return m_SMR.decimals();
    }


    // FIELDS

    /// @notice link to the SMR
    ISmartzToken public m_SMR;

    /// @notice Thaw timestamp of frozenTransfers issued by this vault
    uint public m_thawTS;


    // CONSTANTS

    string public constant name = "SMR Community Fund Vault 1";
    string public constant symbol = "SMRDV";
}