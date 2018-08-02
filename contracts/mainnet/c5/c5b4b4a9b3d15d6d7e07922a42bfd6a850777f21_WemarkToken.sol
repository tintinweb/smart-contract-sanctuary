pragma solidity ^0.4.13;

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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

contract BurnableToken is StandardToken {

  // @notice An address for the transfer event where the burned tokens are transferred in a faux Transfer event
  address public constant BURN_ADDRESS = 0;

  /** How many tokens we burned */
  event Burned(address burner, uint burnedAmount);

  /**
   * Burn extra tokens from a balance.
   *
   */
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply_ = totalSupply_.sub(burnAmount);
    Burned(burner, burnAmount);

    // Inform the blockchain explores that track the
    // balances only by a transfer event that the balance in this
    // address has decreased
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

contract LimitedTransferToken is ERC20 {

    /**
     * @dev Checks whether it can transfer or otherwise throws.
     */
    modifier canTransferLimitedTransferToken(address _sender, uint256 _value) {
        require(_value <= transferableTokens(_sender, uint64(now)));
        _;
    }

    /**
     * @dev Default transferable tokens function returns all tokens for a holder (no limit).
     * @dev Overwriting transferableTokens(address holder, uint64 time) is the way to provide the
     * specific logic for limiting token transferability for a holder over time.
     */
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        return balanceOf(holder);
    }
}

contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
      revert();
    }
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
      revert();
    }
    _;
  }

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransferReleasable(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }

    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }
}

contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;
}

contract UpgradeableToken is StandardToken {

    /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
    address public upgradeMaster;

    /** The next contract where the tokens will be migrated. */
    UpgradeAgent public upgradeAgent;

    /** How many tokens we have upgraded by now. */
    uint256 public totalUpgraded;

    /**
     * Upgrade states.
     *
     * - NotAllowed: The child contract has not reached a condition where the upgrade can begin
     * - WaitingForAgent: Token allows upgrade, but we don&#39;t have a new agent yet
     * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
     * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
     *
     */
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

    /**
     * Somebody has upgraded some of his tokens.
     */
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    /**
     * New upgrade agent available.
     */
    event UpgradeAgentSet(address agent);

    /**
     * Do not allow construction without upgrade master set.
     */
    function UpgradeableToken(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

    /**
     * Allow the token holder to upgrade some of their tokens to a new contract.
     */
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
            // Called in a bad state
            revert();
        }

        // Validate input value.
        if (value == 0) revert();

        balances[msg.sender] = balances[msg.sender].sub(value);

        // Take tokens out from circulation
        totalSupply_ = totalSupply_.sub(value);
        totalUpgraded = totalUpgraded.add(value);

        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

    /**
     * Set an upgrade agent that handles
     */
    function setUpgradeAgent(address agent) external {
        if (!canUpgrade()) {
            // The token is not yet in a state that we could think upgrading
            revert();
        }

        if (agent == 0x0) revert();
        // Only a master can designate the next agent
        if (msg.sender != upgradeMaster) revert();
        // Upgrade has already begun for an agent
        if (getUpgradeState() == UpgradeState.Upgrading) revert();

        upgradeAgent = UpgradeAgent(agent);

        // Bad interface
        if (!upgradeAgent.isUpgradeAgent()) revert();
        // Make sure that token supplies match in source and target
        if (upgradeAgent.originalSupply() != totalSupply_) revert();

        UpgradeAgentSet(upgradeAgent);
    }

    /**
     * Get the state of the token upgrade.
     */
    function getUpgradeState() public constant returns (UpgradeState) {
        if (!canUpgrade()) return UpgradeState.NotAllowed;
        else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

    /**
     * Change the upgrade master.
     *
     * This allows us to set a new owner for the upgrade mechanism.
     */
    function setUpgradeMaster(address master) public {
        if (master == 0x0) revert();
        if (msg.sender != upgradeMaster) revert();
        upgradeMaster = master;
    }

    /**
     * Child contract can enable to provide the condition when the upgrade can begun.
     */
    function canUpgrade() public constant returns (bool) {
        return true;
    }
}

contract CrowdsaleToken is ReleasableToken, UpgradeableToken {

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint8 public decimals;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param _name Token name
   * @param _symbol Token symbol - should be all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   */
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals)
    UpgradeableToken(msg.sender) public {

    // Create any address, can be transferred
    // to team multisig via changeOwner(),
    // also remember to call setUpgradeMaster()
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply_ = _initialSupply;

    decimals = _decimals;

    // Create initially all balance on the team multisig
    balances[owner] = totalSupply_;
  }

  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    super.releaseTokenTransfer();
  }

  /**
   * Allow upgrade agent functionality kick in only if the crowdsale was success.
   */
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

  /**
   * Owner can update token information here.
   *
   * It is often useful to conceal the actual token association, until
   * the token operations, like central issuance or reissuance have been completed.
   *
   * This function allows the token owner to rename the token after the operations
   * have been completed and then point the audience to use the token contract.
   */
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}

contract VestedToken is StandardToken, LimitedTransferToken {

    uint256 MAX_GRANTS_PER_ADDRESS = 20;

    struct TokenGrant {
        address granter;     // 20 bytes
        uint256 value;       // 32 bytes
        uint64 cliff;
        uint64 vesting;
        uint64 start;        // 3 * 8 = 24 bytes
        bool revokable;
        bool burnsOnRevoke;  // 2 * 1 = 2 bits? or 2 bytes?
    } // total 78 bytes = 3 sstore per operation (32 per sstore)

    mapping (address => TokenGrant[]) public grants;

    event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

    /**
     * @dev Grant tokens to a specified address
     * @param _to address The address which the tokens will be granted to.
     * @param _value uint256 The amount of tokens to be granted.
     * @param _start uint64 Time of the beginning of the grant.
     * @param _cliff uint64 Time of the cliff period.
     * @param _vesting uint64 The vesting period.
     */
    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint64 _start,
        uint64 _cliff,
        uint64 _vesting,
        bool _revokable,
        bool _burnsOnRevoke
    ) public {

        // Check for date inconsistencies that may cause unexpected behavior
        require(_cliff >= _start && _vesting >= _cliff);

        require(tokenGrantsCount(_to) < MAX_GRANTS_PER_ADDRESS);   // To prevent a user being spammed and have his balance locked (out of gas attack when calculating vesting).

        uint256 count = grants[_to].push(
            TokenGrant(
                _revokable ? msg.sender : 0, // avoid storing an extra 20 bytes when it is non-revokable
                _value,
                _cliff,
                _vesting,
                _start,
                _revokable,
                _burnsOnRevoke
            )
        );

        transfer(_to, _value);

        NewTokenGrant(msg.sender, _to, _value, count - 1);
    }

    /**
     * @dev Revoke the grant of tokens of a specifed address.
     * @param _holder The address which will have its tokens revoked.
     * @param _grantId The id of the token grant.
     */
    function revokeTokenGrant(address _holder, uint256 _grantId) public {
        TokenGrant storage grant = grants[_holder][_grantId];

        require(grant.revokable);
        require(grant.granter == msg.sender); // Only granter can revoke it

        address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;

        uint256 nonVested = nonVestedTokens(grant, uint64(now));

        // remove grant from array
        delete grants[_holder][_grantId];
        grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
        grants[_holder].length -= 1;

        balances[receiver] = balances[receiver].add(nonVested);
        balances[_holder] = balances[_holder].sub(nonVested);

        Transfer(_holder, receiver, nonVested);
    }


    /**
     * @dev Calculate the total amount of transferable tokens of a holder at a given time
     * @param holder address The address of the holder
     * @param time uint64 The specific time.
     * @return An uint256 representing a holder&#39;s total amount of transferable tokens.
     */
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        uint256 grantIndex = tokenGrantsCount(holder);

        if (grantIndex == 0) return super.transferableTokens(holder, time); // shortcut for holder without grants

        // Iterate through all the grants the holder has, and add all non-vested tokens
        uint256 nonVested = 0;
        for (uint256 i = 0; i < grantIndex; i++) {
            nonVested = SafeMath.add(nonVested, nonVestedTokens(grants[holder][i], time));
        }

        // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
        uint256 vestedTransferable = SafeMath.sub(balanceOf(holder), nonVested);

        // Return the minimum of how many vested can transfer and other value
        // in case there are other limiting transferability factors (default is balanceOf)
        return Math.min256(vestedTransferable, super.transferableTokens(holder, time));
    }

    /**
     * @dev Check the amount of grants that an address has.
     * @param _holder The holder of the grants.
     * @return A uint256 representing the total amount of grants.
     */
    function tokenGrantsCount(address _holder) public constant returns (uint256 index) {
        return grants[_holder].length;
    }

    /**
     * @dev Calculate amount of vested tokens at a specific time
     * @param tokens uint256 The amount of tokens granted
     * @param time uint64 The time to be checked
     * @param start uint64 The time representing the beginning of the grant
     * @param cliff uint64  The cliff period, the period before nothing can be paid out
     * @param vesting uint64 The vesting period
     * @return An uint256 representing the amount of vested tokens of a specific grant
     *  transferableTokens
     *   |                         _/--------   vestedTokens rect
     *   |                       _/
     *   |                     _/
     *   |                   _/
     *   |                 _/
     *   |                /
     *   |              .|
     *   |            .  |
     *   |          .    |
     *   |        .      |
     *   |      .        |
     *   |    .          |
     *   +===+===========+---------+----------> time
     *      Start       Cliff    Vesting
     */
    function calculateVestedTokens(
        uint256 tokens,
        uint256 time,
        uint256 start,
        uint256 cliff,
        uint256 vesting) public pure returns (uint256)
    {
        // Shortcuts for before cliff and after vesting cases.
        if (time < cliff) return 0;
        if (time >= vesting) return tokens;

        // Interpolate all vested tokens.
        // As before cliff the shortcut returns 0, we can use just calculate a value
        // in the vesting rect (as shown in above&#39;s figure)

        // vestedTokens = (tokens * (time - start)) / (vesting - start)
        uint256 vestedTokens = SafeMath.div(
            SafeMath.mul(
                tokens,
                SafeMath.sub(time, start)
            ),
            SafeMath.sub(vesting, start)
        );

        return vestedTokens;
    }

    /**
     * @dev Get all information about a specific grant.
     * @param _holder The address which will have its tokens revoked.
     * @param _grantId The id of the token grant.
     * @return Returns all the values that represent a TokenGrant(address, value, start, cliff,
     * revokability, burnsOnRevoke, and vesting) plus the vested value at the current time.
     */
    function tokenGrant(address _holder, uint256 _grantId) public constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
        TokenGrant storage grant = grants[_holder][_grantId];

        granter = grant.granter;
        value = grant.value;
        start = grant.start;
        cliff = grant.cliff;
        vesting = grant.vesting;
        revokable = grant.revokable;
        burnsOnRevoke = grant.burnsOnRevoke;

        vested = vestedTokens(grant, uint64(now));
    }

    /**
     * @dev Get the amount of vested tokens at a specific time.
     * @param grant TokenGrant The grant to be checked.
     * @param time The time to be checked
     * @return An uint256 representing the amount of vested tokens of a specific grant at a specific time.
     */
    function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
        return calculateVestedTokens(
            grant.value,
            uint256(time),
            uint256(grant.start),
            uint256(grant.cliff),
            uint256(grant.vesting)
        );
    }

    /**
     * @dev Calculate the amount of non vested tokens at a specific time.
     * @param grant TokenGrant The grant to be checked.
     * @param time uint64 The time to be checked
     * @return An uint256 representing the amount of non vested tokens of a specific grant on the
     * passed time frame.
     */
    function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
        return grant.value.sub(vestedTokens(grant, time));
    }

    /**
     * @dev Calculate the date when the holder can transfer all its tokens
     * @param holder address The address of the holder
     * @return An uint256 representing the date of the last transferable tokens.
     */
    function lastTokenIsTransferableDate(address holder) public constant returns (uint64 date) {
        date = uint64(now);
        uint256 grantIndex = grants[holder].length;
        for (uint256 i = 0; i < grantIndex; i++) {
            date = Math.max64(grants[holder][i].vesting, date);
        }
    }
}

contract WemarkToken is CrowdsaleToken, BurnableToken, VestedToken {

    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }


    function WemarkToken() CrowdsaleToken(&#39;WemarkToken-Test&#39;, &#39;WMK&#39;, 135000000 * (10 ** 18), 18) public {
        /** Initially allow only token creator to transfer tokens */
        setTransferAgent(msg.sender, true);
    }

    /**
     * @dev Checks modifier and allows transfer if tokens are not locked or not released.
     * @param _to The address that will receive the tokens.
     * @param _value The amount of tokens to be transferred.
     */
    function transfer(address _to, uint _value)
        validDestination(_to)
        canTransferReleasable(msg.sender)
        canTransferLimitedTransferToken(msg.sender, _value) public returns (bool) {
        // Call BasicToken.transfer()
        return super.transfer(_to, _value);
    }

    /**
     * @dev Checks modifier and allows transfer if tokens are not locked or not released.
     * @param _from The address that will send the tokens.
     * @param _to The address that will receive the tokens.
     * @param _value The amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint _value)
        validDestination(_to)
        canTransferReleasable(_from)
        canTransferLimitedTransferToken(_from, _value) public returns (bool) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Prevent accounts that are blocked for transferring their tokens, from calling approve()
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        // Call StandardToken.transferForm()
        return super.approve(_spender, _value);
    }

    /**
     * @dev Prevent accounts that are blocked for transferring their tokens, from calling increaseApproval()
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        // Call StandardToken.transferForm()
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Can upgrade token contract only if token is released and super class allows too.
     */
    function canUpgrade() public constant returns(bool) {
        return released && super.canUpgrade();
    }

    /**
     * @dev Calculate the total amount of transferable tokens of a holder for the current moment of calling.
     * @param holder address The address of the holder
     * @return An uint256 representing a holder&#39;s total amount of transferable tokens.
     */
    function transferableTokensNow(address holder) public constant returns (uint) {
        return transferableTokens(holder, uint64(now));
    }

    function () payable {
        // If ether is sent to this address, send it back
        revert();
    }
}