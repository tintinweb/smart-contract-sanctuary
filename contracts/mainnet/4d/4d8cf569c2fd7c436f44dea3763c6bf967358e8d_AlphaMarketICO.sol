pragma solidity ^0.4.13;

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

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

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

contract AlphaMarketICO is Multiowned, ReentrancyGuard {
    using SafeMath for uint256;
    enum State { DEFINED, IN_PROGRESS_TOKEN_FREEZE, IN_PROGRESS, FAILED, SUCCEEDED }

    event EtherTransfered(address indexed to, uint value);
    event StateUpdated(State state);
    event InvestmentProcessed(address from, uint value);

    function AlphaMarketICO(address[] _owners) Multiowned(_owners, _owners.length - 1) public {}

    function setToken(address _token) external onlyowner {
        require(address(token) == 0x0);
        require(address(_token) != 0x0);
        token = AlphaMarketCoin(_token);
        tokensToSold = token.totalSupply().mul(60).div(100);
    }

    function setExchanger(address _exchanger) external onlyowner {
        require(_exchanger != 0x0 && exchanger == 0x0);
        exchanger = _exchanger;
    }

    function sendTokensToBountyWallet(address _bountyWallet) external onlyowner {
        require(!isBountySent && _bountyWallet != 0x0);

        token.addEarlyAccessAddress(_bountyWallet);
        uint256 tokensForBounty = token.totalSupply().mul(20).div(100);
        token.transfer(_bountyWallet, tokensForBounty);
        isBountySent = true;
    }
    

    modifier processState {
        updateState();
        _;
    }

    modifier icoInProgress {
        require((icoState == State.IN_PROGRESS || icoState == State.IN_PROGRESS_TOKEN_FREEZE) && currentTime() < endTime);
        _;
    }

    function updateState() public {
        uint currTime = currentTime();
        
        if (icoState == State.IN_PROGRESS_TOKEN_FREEZE || icoState == State.IN_PROGRESS) {
            if (icoState == State.IN_PROGRESS_TOKEN_FREEZE) {
                if (currTime >= tokenUnfreezeTime) {
                    token.enableTransfering();
                    icoState = State.IN_PROGRESS;
                    emit StateUpdated(icoState);
                }
            }
            if (currTime >= endTime || totalInvestment >= hardCap || totalSold >= tokensToSold) {
                token.transfer(exchanger, token.balanceOf(this));
                icoState = State.SUCCEEDED;
                emit StateUpdated(icoState);
            }
        } else if (icoState == State.DEFINED) {
            if (currTime >= startTime) {
                icoState = State.IN_PROGRESS_TOKEN_FREEZE;
                emit StateUpdated(icoState);
            }
        }
    }

    function rewardContributors(address[] _contributors, uint256[] _tokenAmounts) external onlymanyowners(sha3(msg.data)) {
        if(isContributorsRewarded || _contributors.length != _tokenAmounts.length) {
            return;
        }

        uint256 sum = 0;
        for (uint64 i = 0; i < _contributors.length; i++) {
            require(_contributors[i] != 0x0);
            sum = sum.add(_tokenAmounts[i]);
            token.transfer(_contributors[i], _tokenAmounts[i]);
        }
        require(sum == token.totalSupply().mul(20).div(100));
        isContributorsRewarded = true;
    }

    function getTokensCountPerEther() internal view returns (uint256) {
        uint currTime = currentTime();
        require(currTime >= startTime);

        if (currTime < startTime + 1 weeks) {return  27778;}
        if (currTime < startTime + 2 weeks) {return  25000;}
        if (currTime < startTime + 3 weeks) {return  22727;}
        if (currTime < startTime + 4 weeks) {return  20833;}
        if (currTime < startTime + 5 weeks) {return  19230;}
        if (currTime < startTime + 6 weeks) {return  17857;}
        if (currTime < startTime + 7 weeks) {return  16667;}
        if (currTime < startTime + 8 weeks) {return  15625;}
        if (currTime < startTime + 9 weeks) {return  14706;}
        if (currTime < startTime + 10 weeks) {return 13889;}
        if (currTime < startTime + 11 weeks) {return 13158;}
        if (currTime < startTime + 12 weeks) {return 12500;}
        if (currTime < endTime) {return              12500;}
    }

    function getBonus() internal view returns (uint) {
        uint currTime = currentTime();
        require(currTime >= startTime);

        if (currTime < startTime + 1 weeks) {return  20;}
        if (currTime < startTime + 2 weeks) {return  18;}
        if (currTime < startTime + 3 weeks) {return  16;}
        if (currTime < startTime + 4 weeks) {return  14;}
        if (currTime < startTime + 5 weeks) {return  12;}
        if (currTime < startTime + 6 weeks) {return  10;}
        if (currTime < startTime + 7 weeks) {return  8;}
        if (currTime < startTime + 8 weeks) {return  6;}
        if (currTime < startTime + 9 weeks) {return  4;}
        if (currTime < startTime + 10 weeks) {return 3;}
        if (currTime < startTime + 11 weeks) {return 2;}
        if (currTime < startTime + 12 weeks) {return 1;}
        if (currTime < endTime) {return              0;}
    }

    function processInvestment(address investor, uint256 value, address referrer) internal processState icoInProgress {
        require(value >= minInvestment && value <= maxInvestment);
        uint256 tokensCount = uint256(value).mul(getTokensCountPerEther());

        // Add bonus tokens
        uint256 tokensSold = tokensCount.add(tokensCount.mul(getBonus()).div(100));
        token.transfer(investor, tokensSold);

        if (referrer != 0x0) {
            require(referrer != investor);
            uint256 tokensForReferrer = tokensCount.mul(5).div(100);
            token.transfer(referrer, tokensForReferrer);
            tokensSold = tokensSold.add(tokensForReferrer);
        }

        investments[investor] = investments[investor].add(value);
        totalInvestment = totalInvestment.add(value);
        totalSold = totalSold.add(tokensSold);
        emit InvestmentProcessed(investor, value);
    }

    function buyTokensWithRef(address referrer) public payable {
        processInvestment(msg.sender, msg.value, referrer);
    }

    function buyTokens() public payable {
        processInvestment(msg.sender, msg.value, 0x0);
    }
    
    function() external payable {
        require(0 == msg.data.length);
        buyTokens();
    }

    function transferEther(address to, uint value) external nonReentrant onlymanyowners(sha3(msg.data)) {
        if(value == 0 || this.balance < value || to == 0x0){
            return;
        }
        to.transfer(value);
        EtherTransfered(to, value);
    }

    function failICO() external onlymanyowners(sha3(msg.data)) {
        icoState = State.FAILED;
        emit StateUpdated(icoState);
    }

    function withdrawRefund() external nonReentrant {
        require(icoState == State.FAILED);

        uint256 investment = investments[msg.sender];
        require(investment > 0 && this.balance >= investment);

        totalInvestment = totalInvestment.sub(investment);
        investments[msg.sender] = 0;
        msg.sender.transfer(investment);
    }

    function currentTime() internal view returns (uint) {
        return now;
    }

    uint public startTime = 1523880000; // Unix epoch timestamp. Wednesday, April 16, 2018 12:00:00 PM
    uint public tokenUnfreezeTime = startTime + 12 weeks;
    uint public endTime = startTime + 24 weeks; 
    uint public hardCap = 48000 ether;
    uint public minInvestment = 10 finney;
    uint public maxInvestment = hardCap;
    uint public tokensToSold;
    State public icoState = State.DEFINED;

    mapping(address => uint256) public investments;
    uint256 public totalInvestment = 0;
    uint256 public totalSold = 0;

    bool public isContributorsRewarded = false;
    bool public isBountySent = false;
    AlphaMarketCoin public token;
    address public exchanger;
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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