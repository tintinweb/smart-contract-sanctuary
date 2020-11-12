pragma solidity ^0.4.18;

interface IApprovalRecipient {
    /**
     * @notice Signals that token holder approved spending of tokens and some action should be taken.
     *
     * @param _sender token holder which approved spending of his tokens
     * @param _value amount of tokens approved to be spent
     * @param _extraData any extra data token holder provided to the call
     *
     * @dev warning: implementors should validate sender of this message (it should be the token) and make no further
     *      assumptions unless validated them via ERC20 methods.
     */
    function receiveApproval(address _sender, uint256 _value, bytes _extraData) public;
}

interface IKYCProvider {
    function isKYCPassed(address _address) public view returns (bool);
}

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

        // bitmap of confirmations where owner #ownerIndex's decision corresponds to 2**ownerIndex bit
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
        // Even if required number of confirmations has't been collected yet,
        // we can't throw here - because changes to the state have to be preserved.
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
    /// @return true if it's an owner
    function isOwner(address _addr) public constant returns (bool) {
        return m_ownerIndex[_addr] > 0;
    }

    /// @notice Tests ownership of the current caller.
    /// @return true if it's an owner
    // It's advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
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
            // we won't be able to do it because of block gas limit.
            // Yes, pending confirmations will be lost. Dont see any security or stability implications.
            // TODO use more graceful approach like compact or removal of clearPending completely
            clearPending();

        var pending = m_multiOwnedPending[_operation];

        // if we're not yet working on this operation, switch over and reset the confirmation status.
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
        // make sure we (the message sender) haven't confirmed this operation previously.
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
                // owners between swapped slots should't be renumbered - that saves a lot of gas
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed from, uint256 amount);

    /**
     * Function to burn msg.sender's tokens.
     *
     * @param _amount amount of tokens to burn
     *
     * @return boolean that indicates if the operation was successful
     */
    function burn(uint256 _amount)
        public
        returns (bool)
    {
        address from = msg.sender;

        require(_amount > 0);
        require(_amount <= balances[from]);

        totalSupply = totalSupply.sub(_amount);
        balances[from] = balances[from].sub(_amount);
        Burn(from, _amount);
        Transfer(from, address(0), _amount);

        return true;
    }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract TokenWithApproveAndCallMethod is StandardToken {

    /**
     * @notice Approves spending tokens and immediately triggers token recipient logic.
     *
     * @param _spender contract which supports IApprovalRecipient and allowed to receive tokens
     * @param _value amount of tokens approved to be spent
     * @param _extraData any extra data which to be provided to the _spender
     *
     * By invoking this utility function token holder could do two things in one transaction: approve spending his
     * tokens and execute some external contract which spends them on token holder's behalf.
     * It can't be known if _spender's invocation succeed or not.
     * This function will throw if approval failed.
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public {
        require(approve(_spender, _value));
        IApprovalRecipient(_spender).receiveApproval(msg.sender, _value, _extraData);
    }
}

contract SmartzToken is ArgumentsChecker, multiowned, BurnableToken, StandardToken, TokenWithApproveAndCallMethod {

    /// @title Unit of frozen tokens - tokens which can't be spent until certain conditions is met.
    struct FrozenCell {
        /// @notice amount of frozen tokens
        uint amount;

        /// @notice until this unix time the cell is considered frozen
        uint128 thawTS;

        /// @notice is KYC required for a token holder to spend this cell?
        uint128 isKYCRequired;
    }


    // MODIFIERS

    modifier onlySale(address account) {
        require(isSale(account));
        _;
    }

    modifier validUnixTS(uint ts) {
        require(ts >= 1522046326 && ts <= 1800000000);
        _;
    }

    modifier checkTransferInvariant(address from, address to) {
        uint initial = balanceOf(from).add(balanceOf(to));
        _;
        assert(balanceOf(from).add(balanceOf(to)) == initial);
    }

    modifier privilegedAllowed {
        require(m_allowPrivileged);
        _;
    }


    // PUBLIC FUNCTIONS

    /**
     * @notice Constructs token.
     *
     * Initial owners have power over the token contract only during bootstrap phase (early investments and token
     * sales). To be precise, the owners can set KYC provider and sales (which can freeze transfered tokens) during
     * bootstrap phase. After final token sale any control over the token removed by issuing disablePrivileged call.
     */
    function SmartzToken()
        public
        payable
        multiowned(getInitialOwners(), 2)
    {
        if (0 != 100000) {
            totalSupply = 100000;
            balances[msg.sender] = totalSupply;
            Transfer(address(0), msg.sender, totalSupply);
        }

        
totalSupply = totalSupply.add(0);

        
        address(0xfF20387Dd4dbfA3e72AbC7Ee9B03393A941EE36E).transfer(60000000000000000 wei);
        address(0xfF20387Dd4dbfA3e72AbC7Ee9B03393A941EE36E).transfer(240000000000000000 wei);
            
    }

    function getInitialOwners() private pure returns (address[]) {
        address[] memory result = new address[](2);
result[0] = address(0x730417D2f4565b8FEcB8d9A8e6da80F9b801F000);
result[1] = address(0xfA5bbBea18c0214CbBd7794d5a088789c902f0A7);
        return result;
    }

    /**
     * @notice Version of balanceOf() which includes all frozen tokens.
     *
     * @param _owner the address to query the balance of
     *
     * @return an uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        uint256 balance = balances[_owner];

        for (uint cellIndex = 0; cellIndex < frozenBalances[_owner].length; ++cellIndex) {
            balance = balance.add(frozenBalances[_owner][cellIndex].amount);
        }

        return balance;
    }

    /**
     * @notice Version of balanceOf() which includes only currently spendable tokens.
     *
     * @param _owner the address to query the balance of
     *
     * @return an uint256 representing the amount spendable by the passed address
     */
    function availableBalanceOf(address _owner) public view returns (uint256) {
        uint256 balance = balances[_owner];

        for (uint cellIndex = 0; cellIndex < frozenBalances[_owner].length; ++cellIndex) {
            if (isSpendableFrozenCell(_owner, cellIndex))
                balance = balance.add(frozenBalances[_owner][cellIndex].amount);
        }

        return balance;
    }

    /**
     * @notice Standard transfer() overridden to have a chance to thaw sender's tokens.
     *
     * @param _to the address to transfer to
     * @param _value the amount to be transferred
     *
     * @return true iff operation was successfully completed
     */
    function transfer(address _to, uint256 _value)
        public
        payloadSizeIs(2 * 32)
        returns (bool)
    {
        thawSomeTokens(msg.sender, _value);
        return super.transfer(_to, _value);
    }

    /**
     * @notice Standard transferFrom overridden to have a chance to thaw sender's tokens.
     *
     * @param _from address the address which you want to send tokens from
     * @param _to address the address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     *
     * @return true iff operation was successfully completed
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        payloadSizeIs(3 * 32)
        returns (bool)
    {
        thawSomeTokens(_from, _value);
        return super.transferFrom(_from, _to, _value);
    }

    
    /**
     * Function to burn msg.sender's tokens. Overridden to have a chance to thaw sender's tokens.
     *
     * @param _amount amount of tokens to burn
     *
     * @return boolean that indicates if the operation was successful
     */
    function burn(uint256 _amount)
        public
        payloadSizeIs(1 * 32)
        returns (bool)
    {
        thawSomeTokens(msg.sender, _amount);
        return super.burn(_amount);
    }


    // INFORMATIONAL FUNCTIONS (VIEWS)

    /**
     * @notice Number of frozen cells of an account.
     *
     * @param owner account address
     *
     * @return number of frozen cells
     */
    function frozenCellCount(address owner) public view returns (uint) {
        return frozenBalances[owner].length;
    }

    /**
     * @notice Retrieves information about account frozen tokens.
     *
     * @param owner account address
     * @param index index of so-called frozen cell from 0 (inclusive) up to frozenCellCount(owner) exclusive
     *
     * @return amount amount of tokens frozen in this cell
     * @return thawTS unix timestamp at which tokens'll become available
     * @return isKYCRequired it's required to pass KYC to spend tokens iff isKYCRequired is true
     */
    function frozenCell(address owner, uint index) public view returns (uint amount, uint thawTS, bool isKYCRequired) {
        require(index < frozenCellCount(owner));

        amount = frozenBalances[owner][index].amount;
        thawTS = uint(frozenBalances[owner][index].thawTS);
        isKYCRequired = decodeKYCFlag(frozenBalances[owner][index].isKYCRequired);
    }


    // ADMINISTRATIVE FUNCTIONS

    /**
     * @notice Sets current KYC provider of the token.
     *
     * @param KYCProvider address of the IKYCProvider-compatible contract
     *
     * Function is used only during token sale phase, before disablePrivileged() is called.
     */
    function setKYCProvider(address KYCProvider)
        external
        validAddress(KYCProvider)
        privilegedAllowed
        onlymanyowners(keccak256(msg.data))
    {
        m_KYCProvider = IKYCProvider(KYCProvider);
    }

    /**
     * @notice Sets sale status of an account.
     *
     * @param account account address
     * @param isSale is this account has access to frozen* functions
     *
     * Function is used only during token sale phase, before disablePrivileged() is called.
     */
    function setSale(address account, bool isSale)
        external
        validAddress(account)
        privilegedAllowed
        onlymanyowners(keccak256(msg.data))
    {
        m_sales[account] = isSale;
    }


    /**
     * @notice Transfers tokens to a recipient and freezes it.
     *
     * @param _to account to which tokens are sent
     * @param _value amount of tokens to send
     * @param thawTS unix timestamp at which tokens'll become available
     * @param isKYCRequired it's required to pass KYC to spend tokens iff isKYCRequired is true
     *
     * Function is used only during token sale phase and available only to sale accounts.
     */
    function frozenTransfer(address _to, uint256 _value, uint thawTS, bool isKYCRequired)
        external
        validAddress(_to)
        validUnixTS(thawTS)
        payloadSizeIs(4 * 32)
        privilegedAllowed
        onlySale(msg.sender)
        checkTransferInvariant(msg.sender, _to)
        returns (bool)
    {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        addFrozen(_to, _value, thawTS, isKYCRequired);
        Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Transfers frozen tokens back.
     *
     * @param _from account to send tokens from
     * @param _to account to which tokens are sent
     * @param _value amount of tokens to send
     * @param thawTS unix timestamp at which tokens'll become available
     * @param isKYCRequired it's required to pass KYC to spend tokens iff isKYCRequired is true
     *
     * Function is used only during token sale phase to make a refunds and available only to sale accounts.
     * _from account has to explicitly approve spending with the approve() call.
     * thawTS and isKYCRequired parameters are required to withdraw exact "same" tokens (to not affect availability of
     * other tokens of the account).
     */
    function frozenTransferFrom(address _from, address _to, uint256 _value, uint thawTS, bool isKYCRequired)
        external
        validAddress(_to)
        validUnixTS(thawTS)
        payloadSizeIs(5 * 32)
        privilegedAllowed
        //onlySale(msg.sender) too many local variables - compiler fails
        //onlySale(_to)
        checkTransferInvariant(_from, _to)
        returns (bool)
    {
        require(isSale(msg.sender) && isSale(_to));
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        subFrozen(_from, _value, thawTS, isKYCRequired);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Disables further use of any privileged functions like freezing tokens.
    function disablePrivileged()
        external
        privilegedAllowed
        onlymanyowners(keccak256(msg.data))
    {
        m_allowPrivileged = false;
    }


    // INTERNAL FUNCTIONS

    function isSale(address account) private view returns (bool) {
        return m_sales[account];
    }

    /**
     * @dev Tries to find existent FrozenCell that matches (thawTS, isKYCRequired).
     *
     * @return index in frozenBalances[_owner] which equals to frozenBalances[_owner].length in case cell is not found
     *
     * Because frozen* functions are only for token sales and token sale number is limited, expecting cellIndex
     * to be ~ 1-5 and the following loop to be O(1).
     */
    function findFrozenCell(address owner, uint128 thawTSEncoded, uint128 isKYCRequiredEncoded)
        private
        view
        returns (uint cellIndex)
    {
        for (cellIndex = 0; cellIndex < frozenBalances[owner].length; ++cellIndex) {
            FrozenCell storage checkedCell = frozenBalances[owner][cellIndex];
            if (checkedCell.thawTS == thawTSEncoded && checkedCell.isKYCRequired == isKYCRequiredEncoded)
                break;
        }

        assert(cellIndex <= frozenBalances[owner].length);
    }

    /// @dev Says if the given cell could be spent now
    function isSpendableFrozenCell(address owner, uint cellIndex)
        private
        view
        returns (bool)
    {
        FrozenCell storage cell = frozenBalances[owner][cellIndex];
        if (uint(cell.thawTS) > getTime())
            return false;

        if (0 == cell.amount)   // already spent
            return false;

        if (decodeKYCFlag(cell.isKYCRequired) && !m_KYCProvider.isKYCPassed(owner))
            return false;

        return true;
    }

    /// @dev Internal function to increment or create frozen cell.
    function addFrozen(address _to, uint256 _value, uint thawTS, bool isKYCRequired)
        private
        validAddress(_to)
        validUnixTS(thawTS)
    {
        uint128 thawTSEncoded = uint128(thawTS);
        uint128 isKYCRequiredEncoded = encodeKYCFlag(isKYCRequired);

        uint cellIndex = findFrozenCell(_to, thawTSEncoded, isKYCRequiredEncoded);

        // In case cell is not found - creating new.
        if (cellIndex == frozenBalances[_to].length) {
            frozenBalances[_to].length++;
            targetCell = frozenBalances[_to][cellIndex];
            assert(0 == targetCell.amount);

            targetCell.thawTS = thawTSEncoded;
            targetCell.isKYCRequired = isKYCRequiredEncoded;
        }

        FrozenCell storage targetCell = frozenBalances[_to][cellIndex];
        assert(targetCell.thawTS == thawTSEncoded && targetCell.isKYCRequired == isKYCRequiredEncoded);

        targetCell.amount = targetCell.amount.add(_value);
    }

    /// @dev Internal function to decrement frozen cell.
    function subFrozen(address _from, uint256 _value, uint thawTS, bool isKYCRequired)
        private
        validUnixTS(thawTS)
    {
        uint cellIndex = findFrozenCell(_from, uint128(thawTS), encodeKYCFlag(isKYCRequired));
        require(cellIndex != frozenBalances[_from].length);   // has to be found

        FrozenCell storage cell = frozenBalances[_from][cellIndex];
        require(cell.amount >= _value);

        cell.amount = cell.amount.sub(_value);
    }

    /// @dev Thaws tokens of owner until enough tokens could be spent or no more such tokens found.
    function thawSomeTokens(address owner, uint requiredAmount)
        private
    {
        if (balances[owner] >= requiredAmount)
            return;     // fast path

        // Checking that our goal is reachable before issuing expensive storage modifications.
        require(availableBalanceOf(owner) >= requiredAmount);

        for (uint cellIndex = 0; cellIndex < frozenBalances[owner].length; ++cellIndex) {
            if (isSpendableFrozenCell(owner, cellIndex)) {
                uint amount = frozenBalances[owner][cellIndex].amount;
                frozenBalances[owner][cellIndex].amount = 0;
                balances[owner] = balances[owner].add(amount);
            }
        }

        assert(balances[owner] >= requiredAmount);
    }

    /// @dev to be overridden in tests
    function getTime() internal view returns (uint) {
        return now;
    }

    function encodeKYCFlag(bool isKYCRequired) private pure returns (uint128) {
        return isKYCRequired ? uint128(1) : uint128(0);
    }

    function decodeKYCFlag(uint128 isKYCRequired) private pure returns (bool) {
        return isKYCRequired != uint128(0);
    }


    // FIELDS

    /// @notice current KYC provider of the token
    IKYCProvider public m_KYCProvider;

    /// @notice set of sale accounts which can freeze tokens
    mapping (address => bool) public m_sales;

    /// @notice frozen tokens
    mapping (address => FrozenCell[]) public frozenBalances;

    /// @notice allows privileged functions (token sale phase)
    bool public m_allowPrivileged = true;


    // CONSTANTS

    string public constant name = 'Hunk Finance';
    string public constant symbol = 'HUNK';
    uint8 public constant decimals = 0;
}