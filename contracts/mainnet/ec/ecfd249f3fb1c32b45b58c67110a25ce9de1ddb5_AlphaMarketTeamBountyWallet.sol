pragma solidity ^0.4.13;

contract Multiowned {

    // TYPES

    // struct for the status of a pending operation.
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

    // EVENTS

    // this contract only has five types of events: it can accept a confirmation, in which case
    // we record owner and operation (hash) alongside it.
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

    // MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }

    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

    // METHODS

    // constructor is given number of sigs required to do protected "onlymanyowners" transactions
    // as well as the selection of addresses capable of confirming them.
    function Multiowned(address[] _owners, uint _required) public {
        m_numOwners = _owners.length;
        m_chiefOwnerIndexBit = 2**1;
        for (uint i = 0; i < m_numOwners; i++) {
            m_owners[1 + i] = _owners[i];
            m_ownerIndex[uint(_owners[i])] = 1 + i;
        }
        m_required = _required;
    }
    
    // Revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they&#39;re an owner
        if (ownerIndex == 0) {
            return;
        }
        uint ownerIndexBit = 2**ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }
    
    // Replaces an owner `_from` with another `_to`.
    function changeOwner(address _from, address _to) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (isOwner(_to) || ownerIndex == 0) {
            return;
        }

        clearPending();
        m_owners[ownerIndex] = _to;
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }
    
    function addOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_owner)) {
            return;
        }

        if (m_numOwners >= c_maxOwners) {
            clearPending();
            reorganizeOwners();
        }
        require(m_numOwners < c_maxOwners);
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner);
    }
    
    function removeOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0 || m_required > m_numOwners - 1) {
            return;
        }

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners(); //make sure m_numOwner is equal to the number of owners and always points to the optimal free slot
        OwnerRemoved(_owner);
    }
    
    function changeRequirement(uint _newRequired) onlymanyowners(sha3(msg.data)) external {
        if (_newRequired > m_numOwners) {
            return;
        }
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }
    
    function isOwner(address _addr) internal view returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }
    
    function hasConfirmed(bytes32 _operation, address _owner) public view returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

        // make sure they&#39;re an owner
        if (ownerIndex == 0) {
            return false;
        }

        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        if (pending.ownersDone & ownerIndexBit == 0) {
            return false;
        } else {
            return true;
        }
    }
    
    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
        // determine what index the present sender is:
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they&#39;re an owner
        require(ownerIndex != 0);

        var pending = m_pending[_operation];
        // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // reset count of confirmations needed.
            pending.yetNeeded = c_maxOwners + m_required;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        // make sure we (the message sender) haven&#39;t confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead and chief owner confirmed operation.
            if ((pending.yetNeeded <= c_maxOwners + 1) && ((pending.ownersDone & m_chiefOwnerIndexBit != 0) || (ownerIndexBit == m_chiefOwnerIndexBit))) {
                // enough confirmations: reset and run interior.
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            } else {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private returns (bool) {
        uint free = 1;
        while (free < m_numOwners) {
            while (free < m_numOwners && m_owners[free] != 0) {
                free++;
            }
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) {
                m_numOwners--;
            }
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0) {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[uint(m_owners[free])] = free;
                m_owners[m_numOwners] = 0;
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

    // the number of owners that must confirm the same operation before it is run.
    uint public m_required;
    // pointer used to find a free slot in m_owners
    uint public m_numOwners;
    
    // list of owners
    address[8] public m_owners;
    uint public m_chiefOwnerIndexBit;
    uint constant c_maxOwners = 7;
    // index on the list of owners to allow reverse lookup
    mapping(uint => uint) public m_ownerIndex;
    // the ongoing operations.
    mapping(bytes32 => PendingState) public m_pending;
    bytes32[] public m_pendingIndex;
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

contract AlphaMarketTeamBountyWallet is Multiowned {
    function AlphaMarketTeamBountyWallet(address[] _owners, address _tokenAddress) Multiowned(_owners, _owners.length - 1) public {
        token = AlphaMarketCoin(_tokenAddress);
    }

    function transferTokens(address _to, uint256 _value) external onlymanyowners(sha3(msg.data)) {
        if(_value == 0 || token.balanceOf(this) < _value || _to == 0x0) {
            return;
        }
        token.transfer(_to, _value);
    }

    // Prevent sending ether to this address
    function () external payable {
        revert();
    }

    AlphaMarketCoin public token;
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

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
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

contract AlphaMarketCoin is StandardToken {

    function AlphaMarketCoin(address _controller) public {
        controller = _controller;
        earlyAccess[_controller] = true;
        totalSupply_ = 999999999 * 10 ** uint256(decimals);
        balances[_controller] = totalSupply_;
    }

    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    // Transfering should be enabled by ICO contract only when half of ICO is passed
    event TransferEnabled();

    function addEarlyAccessAddress(address _address) external onlyController {
        require(_address != 0x0);
        earlyAccess[_address] = true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled || earlyAccess[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        return super.approve(_spender, _value);
    }
    
    function enableTransfering() public onlyController {
        require(!isTransferEnabled);

        isTransferEnabled = true;
        emit TransferEnabled();
    }

    // Prevent sending ether to this address
    function () public payable {
        revert();
    }

    bool public isTransferEnabled = false;
    address public controller;
    mapping(address => bool) public earlyAccess;

    uint8 public constant decimals = 18;
    string public constant name = &#39;AlphaMarket Coin&#39;;
    string public constant symbol = &#39;AMC&#39;;
}