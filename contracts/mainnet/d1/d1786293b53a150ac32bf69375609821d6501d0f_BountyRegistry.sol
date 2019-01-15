pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts/NectarToken.sol

contract NectarToken is MintableToken {
    string public name = "Nectar";
    string public symbol = "NCT";
    uint8 public decimals = 18;

    bool public transfersEnabled = false;
    event TransfersEnabled();

    // Disable transfers until after the sale
    modifier whenTransfersEnabled() {
        require(transfersEnabled, "Transfers not enabled");
        _;
    }

    modifier whenTransfersNotEnabled() {
        require(!transfersEnabled, "Transfers enabled");
        _;
    }

    function enableTransfers() public onlyOwner whenTransfersNotEnabled {
        transfersEnabled = true;
        emit TransfersEnabled();
    }

    function transfer(address to, uint256 value) public whenTransfersEnabled returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenTransfersEnabled returns (bool) {
        return super.transferFrom(from, to, value);
    }

    // Approves and then calls the receiving contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        // Call the receiveApproval function on the contract you want to be notified.
        // This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //
        // receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //
        // It is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.

        // solium-disable-next-line security/no-low-level-calls, indentation
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))),
            msg.sender, _value, this, _extraData), "receiveApproval failed");
        return true;
    }
}

// File: contracts/BountyRegistry.sol

//import "./BountyRegistry.sol";

contract ArbiterStaking is Pausable {
    using SafeMath for uint256;
    using SafeERC20 for NectarToken;

    uint256 public constant MINIMUM_STAKE = 10000000 * 10 ** 18;
    uint256 public constant MAXIMUM_STAKE = 100000000 * 10 ** 18;
    uint8 public constant VOTE_RATIO_NUMERATOR = 9;
    uint8 public constant VOTE_RATIO_DENOMINATOR = 10;
    string public constant VERSION = "1.0.0";

    // Deposits
    struct Deposit {
        uint256 blockNumber;
        uint256 value;
    }

    event NewDeposit(
        address indexed from,
        uint256 value
    );

    event NewWithdrawal(
        address indexed to,
        uint256 value
    );

    mapping(address => Deposit[]) public deposits;

    // Bounties
    event BountyRecorded(
        uint128 indexed guid,
        uint256 blockNumber
    );

    event BountyVoteRecorded(
        address arbiter
    );

    uint256 public numBounties;
    mapping(uint128 => bool) public bounties;
    mapping(address => uint256) public bountyResponses;
    mapping(uint128 => mapping(address => bool)) public bountyResponseByGuidAndAddress;

    uint256 public stakeDuration;
    NectarToken internal token;
    BountyRegistry internal registry;

    /**
     * Construct a new ArbiterStaking
     *
     * @param _token address of NCT token to use
     */
    constructor(address _token, uint256 _stakeDuration) Ownable() public {
        token = NectarToken(_token);
        stakeDuration = _stakeDuration;
    }

    /**
     * Sets the registry value with the live BountyRegistry

     * @param _bountyRegistry Address of BountyRegistry contract
     */
    function setBountyRegistry(address _bountyRegistry) public onlyOwner {
        registry = BountyRegistry(_bountyRegistry);
    }

    /**
     * Handle a deposit upon receiving approval for a token transfer
     * Called from NectarToken.approveAndCall
     *
     * @param _from Account depositing NCT
     * @param _value Amount of NCT being deposited
     * @param _tokenContract Address of the NCT contract
     * @return true if successful else false
     */
    function receiveApproval(
        address _from,
        uint256 _value,
        address _tokenContract,
        bytes
    )
        public
        whenNotPaused
        returns (bool)
    {
        require(msg.sender == address(token), "Must be called from the token.");
        return receiveApprovalInternal(_from, _value, _tokenContract, new bytes(0));
    }

    function receiveApprovalInternal(
        address _from,
        uint256 _value,
        address _tokenContract,
        bytes
    )
        internal
        whenNotPaused
        returns (bool)
    {
        require(registry.isArbiter(_from), "Deposit target is not an arbiter");
        // Ensure we are depositing something
        require(_value > 0, "Zero value being deposited");
        // Ensure we are called from he right token contract
        require(_tokenContract == address(token), "Invalid token being deposited");
        // Ensure that we are not staking more than the maximum
        require(balanceOf(_from).add(_value) <= MAXIMUM_STAKE, "Value greater than maximum stake");

        token.safeTransferFrom(_from, this, _value);
        deposits[_from].push(Deposit(block.number, _value));
        emit NewDeposit(_from, _value);

        return true;
    }

    /**
     * Deposit NCT (requires prior approval)
     *
     * @param value The amount of NCT to deposit
     */
    function deposit(uint256 value) public whenNotPaused {
        require(receiveApprovalInternal(msg.sender, value, token, new bytes(0)), "Depositing stake failed");
    }

    /**
     * Retrieve the (total) current balance of staked NCT for an account
     *
     * @param addr The account whos balance to retrieve
     * @return The current (total) balance of the account
     */
    function balanceOf(address addr) public view returns (uint256) {
        uint256 ret = 0;
        Deposit[] storage ds = deposits[addr];
        for (uint256 i = 0; i < ds.length; i++) {
            ret = ret.add(ds[i].value);
        }
        return ret;
    }

    /**
     * Retrieve the withdrawable current balance of staked NCT for an account
     *
     * @param addr The account whos balance to retrieve
     * @return The current withdrawable balance of the account
     */
    function withdrawableBalanceOf(address addr) public view returns (uint256) {
        uint256 ret = 0;
        if (block.number < stakeDuration) {
            return ret;
        }
        uint256 latest_block = block.number.sub(stakeDuration);
        Deposit[] storage ds = deposits[addr];
        for (uint256 i = 0; i < ds.length; i++) {
            if (ds[i].blockNumber <= latest_block) {
                ret = ret.add(ds[i].value);
            } else {
                break;
            }
        }
        return ret;
    }

    /**
     * Withdraw staked NCT
     * @param value The amount of NCT to withdraw
     */
    function withdraw(uint256 value) public whenNotPaused {
        require(deposits[msg.sender].length > 0, "Cannot withdraw without some deposits.");
        uint256 remaining = value;
        uint256 latest_block = block.number.sub(stakeDuration);
        Deposit[] storage ds = deposits[msg.sender];

        require(value <= withdrawableBalanceOf(msg.sender), "Value exceeds withdrawable balance");

        // Determine which deposits we will modifiy
        for (uint256 end = 0; end < ds.length; end++) {
            if (ds[end].blockNumber <= latest_block) {
                if (ds[end].value >= remaining) {
                    ds[end].value = ds[end].value.sub(remaining);
                    if (ds[end].value == 0) {
                        end++;
                    }
                    remaining = 0;
                    break;
                } else {
                    remaining = remaining.sub(ds[end].value);
                }
            } else {
                break;
            }
        }

        // If we haven&#39;t hit our value by now, we don&#39;t have enough available
        // funds
        require(remaining == 0, "Value exceeds withdrawable balance");

        // Delete the obsolete deposits
        for (uint256 i = 0; i < ds.length.sub(end); i++) {
            ds[i] = ds[i.add(end)];
        }

        for (i = ds.length.sub(end); i < ds.length; i++) {
            delete ds[i];
        }

        ds.length = ds.length.sub(end);

        // Do the transfer
        token.safeTransfer(msg.sender, value);
        emit NewWithdrawal(msg.sender, value);
    }

    /**
     * Is an address an eligible arbiter?
     * @param addr The address to validate
     * @return true if address is eligible else false
     */
    function isEligible(address addr) public view returns (bool) {
        uint256 num;
        uint256 den;
        (num, den) = arbiterResponseRate(addr);

        return balanceOf(addr) >= MINIMUM_STAKE &&
            (den < VOTE_RATIO_DENOMINATOR || num.mul(VOTE_RATIO_DENOMINATOR).div(den) >= VOTE_RATIO_NUMERATOR);
    }

    /**
     * Record a bounty that an arbiter has voted on
     *
     * @param arbiter The address of the arbiter
     * @param bountyGuid The guid of the bounty
     */
    function recordBounty(address arbiter, uint128 bountyGuid, uint256 blockNumber) public {
        require(msg.sender == address(registry), "Can only be called by the BountyRegistry.");
        require(arbiter != address(0), "Invalid arbiter address");
        require(blockNumber != 0, "Invalid block number");

        // New bounty
        if (!bounties[bountyGuid]) {
            bounties[bountyGuid] = true;
            numBounties = numBounties.add(1);
            emit BountyRecorded(bountyGuid, blockNumber);
        }

        // First response to this bounty by this arbiter
        if (!bountyResponseByGuidAndAddress[bountyGuid][arbiter]) {
            bountyResponseByGuidAndAddress[bountyGuid][arbiter] = true;
            bountyResponses[arbiter] = bountyResponses[arbiter].add(1);
        }

        emit BountyVoteRecorded(arbiter);
    }

    /**
     * Determines the ratio of past bounties that the arbiter has responded to
     *
     * @param arbiter The address of the arbiter
     * @return number of bounties responded to, number of bounties considered
     */
    function arbiterResponseRate(address arbiter) public view returns (uint256 num, uint256 den) {
        num = bountyResponses[arbiter];
        den = numBounties;
    }
}
pragma solidity ^0.4.21;



//import "./ArbiterStaking.sol";



contract BountyRegistry is Pausable {
    using SafeMath for uint256;
    using SafeERC20 for NectarToken;

    string public constant VERSION = "1.0.0";

    struct Bounty {
        uint128 guid;
        address author;
        uint256 amount;
        string artifactURI;
        uint256 numArtifacts;
        uint256 expirationBlock;
        address assignedArbiter;
        bool quorumReached;
        uint256 quorumBlock;
        uint256 quorumMask;
    }

    struct Assertion {
        address author;
        uint256 bid;
        uint256 mask;
        uint256 commitment;
        uint256 nonce;
        uint256 verdicts;
        string metadata;
    }

    struct Vote {
        address author;
        uint256 votes;
        bool validBloom;
    }

    event AddedArbiter(
        address arbiter,
        uint256 blockNumber
    );

    event RemovedArbiter(
        address arbiter,
        uint256 blockNumber
    );

    event NewBounty(
        uint128 guid,
        address author,
        uint256 amount,
        string artifactURI,
        uint256 expirationBlock
    );

    event NewAssertion(
        uint128 bountyGuid,
        address author,
        uint256 index,
        uint256 bid,
        uint256 mask,
        uint256 numArtifacts,
        uint256 commitment
    );

    event RevealedAssertion(
        uint128 bountyGuid,
        address author,
        uint256 index,
        uint256 nonce,
        uint256 verdicts,
        uint256 numArtifacts,
        string metadata
    );

    event NewVote(
        uint128 bountyGuid,
        uint256 votes,
        uint256 numArtifacts,
        address voter
    );

    event QuorumReached(
        uint128 bountyGuid
    );

    event SettledBounty(
        uint128 bountyGuid,
        address settler,
        uint256 payout
    );

    ArbiterStaking public staking;
    NectarToken internal token;

    uint256 public constant BOUNTY_FEE = 62500000000000000;
    uint256 public constant ASSERTION_FEE = 31250000000000000;
    uint256 public constant BOUNTY_AMOUNT_MINIMUM = 62500000000000000;
    uint256 public constant ASSERTION_BID_MINIMUM = 62500000000000000;
    uint256 public constant ARBITER_LOOKBACK_RANGE = 100;
    uint256 public constant MAX_DURATION = 100; // BLOCKS
    uint256 public constant ASSERTION_REVEAL_WINDOW = 25; // BLOCKS
    uint256 public constant MALICIOUS_VOTE_COEFFICIENT = 10;
    uint256 public constant BENIGN_VOTE_COEFFICIENT = 1;
    uint256 public constant VALID_HASH_PERIOD = 256; // number of blocks in the past you can still get a blockhash


    uint256 public arbiterCount;
    uint256 public arbiterVoteWindow;
    uint128[] public bountyGuids;
    mapping (uint128 => Bounty) public bountiesByGuid;
    mapping (uint128 => Assertion[]) public assertionsByGuid;
    mapping (uint128 => Vote[]) public votesByGuid;
    mapping (uint128 => uint256[8]) public bloomByGuid;
    mapping (uint128 => mapping (uint256 => uint256)) public quorumVotesByGuid;
    mapping (address => bool) public arbiters;
    mapping (uint256 => mapping (uint256 => uint256)) public voteCountByGuid;
    mapping (uint256 => mapping (address => bool)) public arbiterVoteRegistryByGuid;
    mapping (uint256 => mapping (address => bool)) public expertAssertionResgistryByGuid;
    mapping (uint128 => mapping (address => bool)) public bountySettled;

    /**
     * Construct a new BountyRegistry
     *
     * @param _token address of NCT token to use
     */
    constructor(address _token, address _arbiterStaking, uint256 _arbiterVoteWindow) Ownable() public {
        owner = msg.sender;
        token = NectarToken(_token);
        staking = ArbiterStaking(_arbiterStaking);
        arbiterVoteWindow = _arbiterVoteWindow;
    }

    /**
     * Function to check if an address is a valid arbiter
     *
     * @param addr The address to check
     * @return true if addr is a valid arbiter else false
     */
    function isArbiter(address addr) public view returns (bool) {
        // Remove arbiter requirements for now, while we are whitelisting
        // arbiters on the platform
        //return arbiters[addr] && staking.isEligible(addr);
        return arbiters[addr];
    }

    /** Function only callable by arbiter */
    modifier onlyArbiter() {
        require(isArbiter(msg.sender), "msg.sender is not an arbiter");
        _;
    }

    /**
     * Function called to add an arbiter, emits an evevnt with the added arbiter
     * and block number used to calculate their arbiter status based on public
     * arbiter selection algorithm.
     *
     * @param newArbiter the arbiter to add
     * @param blockNumber the block number the determination to add was
     *      calculated from
     */
    function addArbiter(address newArbiter, uint256 blockNumber) external whenNotPaused onlyOwner {
        require(newArbiter != address(0), "Invalid arbiter address");
        require(!arbiters[newArbiter], "Address is already an arbiter");
        arbiterCount = arbiterCount.add(1);
        arbiters[newArbiter] = true;
        emit AddedArbiter(newArbiter, blockNumber);
    }

    /**
     * Function called to remove an arbiter, emits an evevnt with the removed
     * arbiter and block number used to calculate their arbiter status based on
     * public arbiter selection algorithm.
     *
     * @param arbiter the arbiter to remove
     * @param blockNumber the block number the determination to remove was
     *      calculated from
     */
    function removeArbiter(address arbiter, uint256 blockNumber) external whenNotPaused onlyOwner {
        arbiters[arbiter] = false;
        arbiterCount = arbiterCount.sub(1);
        emit RemovedArbiter(arbiter, blockNumber);
    }

    /**
     * Function called by end users and ambassadors to post a bounty
     *
     * @param guid the guid of the bounty, must be unique
     * @param amount the amount of NCT to post as a reward
     * @param artifactURI uri of the artifacts comprising this bounty
     * @param durationBlocks duration of this bounty in blocks
     */
    function postBounty(
        uint128 guid,
        uint256 amount,
        string artifactURI,
        uint256 numArtifacts,
        uint256 durationBlocks,
        uint256[8] bloom
    )
    external
    whenNotPaused
    {
        // Check if a bounty with this GUID has already been initialized
        require(bountiesByGuid[guid].author == address(0), "GUID already in use");
        // Check that our bounty amount is sufficient
        require(amount >= BOUNTY_AMOUNT_MINIMUM, "Bounty amount below minimum");
        // Check that our URI is non-empty
        require(bytes(artifactURI).length > 0, "Invalid artifact URI");
        // Check that our number of artifacts is valid
        require(numArtifacts <= 256, "Too many artifacts in bounty");
        require(numArtifacts > 0, "Not enough artifacts in bounty");
        // Check that our duration is non-zero and less than or equal to the max
        require(durationBlocks > 0 && durationBlocks <= MAX_DURATION, "Invalid bounty duration");

        // Assess fees and transfer bounty amount into escrow
        token.safeTransferFrom(msg.sender, address(this), amount.add(BOUNTY_FEE));

        bountiesByGuid[guid].guid = guid;
        bountiesByGuid[guid].author = msg.sender;
        bountiesByGuid[guid].amount = amount;
        bountiesByGuid[guid].artifactURI = artifactURI;

        // Number of artifacts is submitted as part of the bounty, we have no
        // way to check how many exist in this IPFS resource. For an IPFS
        // resource with N artifacts, if numArtifacts < N only the first
        // numArtifacts artifacts are included in this bounty, if numArtifacts >
        // N then the last N - numArtifacts bounties are considered benign.
        bountiesByGuid[guid].numArtifacts = numArtifacts;
        bountiesByGuid[guid].expirationBlock = durationBlocks.add(block.number);

        bountyGuids.push(guid);

        bloomByGuid[guid] = bloom;

        emit NewBounty(
            bountiesByGuid[guid].guid,
            bountiesByGuid[guid].author,
            bountiesByGuid[guid].amount,
            bountiesByGuid[guid].artifactURI,
            bountiesByGuid[guid].expirationBlock
        );
    }

    /**
     * Function called by security experts to post an assertion on a bounty
     *
     * @param bountyGuid the guid of the bounty to assert on
     * @param bid the amount of NCT to stake
     * @param mask the artifacts to assert on from the set in the bounty
     * @param commitment a commitment hash of the verdicts being asserted, equal
     *      to keccak256(verdicts ^ keccak256(nonce)) where nonce != 0
     */
    function postAssertion(
        uint128 bountyGuid,
        uint256 bid,
        uint256 mask,
        uint256 commitment
    )
        external
        whenNotPaused
    {
        // Check if this bounty has been initialized
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");
        // Check that our bid amount is sufficient
        require(bid >= ASSERTION_BID_MINIMUM, "Assertion bid below minimum");
        // Check if this bounty is active
        require(bountiesByGuid[bountyGuid].expirationBlock > block.number, "Bounty inactive");
        // Check if the sender has already made an assertion
        require(expertAssertionResgistryByGuid[bountyGuid][msg.sender] == false, "Sender has already asserted");
        // Assess fees and transfer bid amount into escrow
        token.safeTransferFrom(msg.sender, address(this), bid.add(ASSERTION_FEE));

        expertAssertionResgistryByGuid[bountyGuid][msg.sender] = true;

        Assertion memory a = Assertion(
            msg.sender,
            bid,
            mask,
            commitment,
            0,
            0,
            ""
        );

        uint256 index = assertionsByGuid[bountyGuid].push(a) - 1;
        uint256 numArtifacts = bountiesByGuid[bountyGuid].numArtifacts;

        emit NewAssertion(
            bountyGuid,
            a.author,
            index,
            a.bid,
            a.mask,
            numArtifacts,
            a.commitment
        );
    }

    // https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
    function uint256_to_bytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        // solium-disable-next-line security/no-inline-assembly
        assembly { mstore(add(b, 32), x) }
    }

    /**
     * Function called by security experts to reveal an assertion after bounty
     * expiration
     *
     * @param bountyGuid the guid of the bounty to assert on
     * @param assertionId the id of the assertion to reveal
     * @param assertionId the id of the assertion to reveal
     * @param nonce the nonce used to generate the commitment hash
     * @param verdicts the verdicts making up this assertion
     * @param metadata optional metadata to include in the assertion
     */
    function revealAssertion(
        uint128 bountyGuid,
        uint256 assertionId,
        uint256 nonce,
        uint256 verdicts,
        string metadata
    )
        external
        whenNotPaused
    {
        // Check if this bounty has been initialized
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");
        // Check that the bounty is no longer active
        require(bountiesByGuid[bountyGuid].expirationBlock <= block.number, "Bounty is still active");
        // Check if the reveal round has closed
        require(bountiesByGuid[bountyGuid].expirationBlock.add(ASSERTION_REVEAL_WINDOW) > block.number, "Reveal round has closed");
        // Get numArtifacts to help decode all zero verdicts
        uint256 numArtifacts = bountiesByGuid[bountyGuid].numArtifacts;

        // Zero is defined as an invalid nonce
        require(nonce != 0, "Invalid nonce");

        // Check our id
        require(assertionId < assertionsByGuid[bountyGuid].length, "Invalid assertion ID");

        Assertion storage a = assertionsByGuid[bountyGuid][assertionId];
        require(a.author == msg.sender, "Incorrect assertion author");
        require(a.nonce == 0, "Bounty already revealed");

        // Check our commitment hash, by xor-ing verdicts with the hashed nonce
        // and the sender&#39;s address prevent copying assertions by submitting the
        // same commitment hash and nonce during the reveal round
        uint256 hashed_nonce = uint256(keccak256(uint256_to_bytes(nonce)));
        uint256 commitment = uint256(keccak256(uint256_to_bytes(verdicts ^ hashed_nonce ^ uint256(msg.sender))));
        require(commitment == a.commitment, "Commitment hash mismatch");

        a.nonce = nonce;
        a.verdicts = verdicts;
        a.metadata = metadata;

        emit RevealedAssertion(
            bountyGuid,
            a.author,
            assertionId,
            a.nonce,
            a.verdicts,
            numArtifacts,
            a.metadata
        );
    }

    /**
     * Function called by arbiter after bounty expiration to settle with their
     * ground truth determination and pay out assertion rewards
     *
     * @param bountyGuid the guid of the bounty to settle
     * @param votes bitset of votes representing ground truth for the
     *      bounty&#39;s artifacts
     */
    function voteOnBounty(
        uint128 bountyGuid,
        uint256 votes,
        bool validBloom
    )
        external
        onlyArbiter
        whenNotPaused
    {
        Bounty storage bounty = bountiesByGuid[bountyGuid];
        Vote[] storage bountyVotes = votesByGuid[bountyGuid];

        // Check if this bounty has been initialized
        require(bounty.author != address(0), "Bounty has not been initialized");
        // Check that the reveal round has closed
        require(bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW) <= block.number, "Reveal round is still active");
        // Check if the voting round has closed
        require(bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow) > block.number, "Voting round has closed");
        // Check to make sure arbiters can&#39;t double vote
        require(arbiterVoteRegistryByGuid[bountyGuid][msg.sender] == false, "Arbiter has already voted");

        Vote memory a = Vote(
            msg.sender,
            votes,
            validBloom
        );

        votesByGuid[bountyGuid].push(a);

        staking.recordBounty(msg.sender, bountyGuid, block.number);
        arbiterVoteRegistryByGuid[bountyGuid][msg.sender] = true;
        uint256 tempQuorumMask = 0;
        uint256 quorumCount = 0;
        mapping (uint256 => uint256) quorumVotes = quorumVotesByGuid[bountyGuid];
        for (uint256 i = 0; i < bounty.numArtifacts; i++) {

            if (bounty.quorumMask != 0 && (bounty.quorumMask & (1 << i) != 0)) {
                tempQuorumMask = tempQuorumMask.add(calculateMask(i, 1));
                quorumCount = quorumCount.add(1);
                continue;
            }

            if (votes & (1 << i) != 0) {
                quorumVotes[i] = quorumVotes[i].add(1);
            }

            uint256 benignVotes = bountyVotes.length.sub(quorumVotes[i]);
            uint256 maxBenignValue = arbiterCount.sub(quorumVotes[i]).mul(BENIGN_VOTE_COEFFICIENT);
            uint256 maxMalValue = arbiterCount.sub(benignVotes).mul(MALICIOUS_VOTE_COEFFICIENT);

            if (quorumVotes[i].mul(MALICIOUS_VOTE_COEFFICIENT) >= maxBenignValue || benignVotes.mul(BENIGN_VOTE_COEFFICIENT) > maxMalValue) {
                tempQuorumMask = tempQuorumMask.add(calculateMask(i, 1));
                quorumCount = quorumCount.add(1);
            }
        }

        // set new mask
        bounty.quorumMask = tempQuorumMask;

        // check if all arbiters have voted or if we have quorum for all the artifacts
        if ((bountyVotes.length == arbiterCount || quorumCount == bounty.numArtifacts) && !bounty.quorumReached)  {
            bounty.quorumReached = true;
            bounty.quorumBlock = block.number.sub(bountiesByGuid[bountyGuid].expirationBlock);
            emit QuorumReached(bountyGuid);
        }

        emit NewVote(bountyGuid, votes, bounty.numArtifacts, msg.sender);
    }

    // This struct exists to move state from settleBounty into memory from stack
    // to avoid solidity limitations
    struct ArtifactPot {
        uint256 numWinners;
        uint256 numLosers;
        uint256 winnerPool;
        uint256 loserPool;
    }

    /**
     * Function to calculate the reward disbursment of a bounty
     *
     * @param bountyGuid the guid of the bounty to calculate
     * @return Rewards distributed by the bounty
     */
    function calculateBountyRewards(
        uint128 bountyGuid
    )
        public
        view
        returns (uint256 bountyRefund, uint256 arbiterReward, uint256[] expertRewards)
    {
        Bounty storage bounty = bountiesByGuid[bountyGuid];
        Assertion[] storage assertions = assertionsByGuid[bountyGuid];
        Vote[] storage votes = votesByGuid[bountyGuid];
        mapping (uint256 => uint256) quorumVotes = quorumVotesByGuid[bountyGuid];

        // Check if this bountiesByGuid[bountyGuid] has been initialized
        require(bounty.author != address(0), "Bounty has not been initialized");
        // Check if this bounty has been previously resolved for the sender
        require(!bountySettled[bountyGuid][msg.sender], "Bounty has already been settled for sender");
        // Check that the voting round has closed
        // solium-disable-next-line indentation
        require(bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow) <= block.number || bounty.quorumReached,
            "Voting round is still active and quorum has not been reached");

        expertRewards = new uint256[](assertions.length);

        ArtifactPot memory ap = ArtifactPot({numWinners: 0, numLosers: 0, winnerPool: 0, loserPool: 0});

        uint256 i = 0;
        uint256 j = 0;

        if (assertions.length == 0 && votes.length == 0) {
            // Refund the bounty amount and fees to ambassador
            bountyRefund = bounty.numArtifacts.mul(bounty.amount.add(BOUNTY_FEE));
        } else if (assertions.length == 0) {
            // Refund the bounty amount ambassador
            bountyRefund = bounty.amount.mul(bounty.numArtifacts);
        } else if (votes.length == 0) {
            // Refund bids, fees, and distribute the bounty amount evenly to experts
            bountyRefund = BOUNTY_FEE.mul(bounty.numArtifacts);
            for (j = 0; j < assertions.length; j++) {
                expertRewards[j] = expertRewards[j].add(ASSERTION_FEE);
                expertRewards[j] = expertRewards[j].add(assertions[j].bid);
                expertRewards[j] = expertRewards[j].add(bounty.amount.div(assertions.length));
                expertRewards[j] = expertRewards[j].mul(bounty.numArtifacts);
            }
        } else {
            for (i = 0; i < bounty.numArtifacts; i++) {
                ap = ArtifactPot({numWinners: 0, numLosers: 0, winnerPool: 0, loserPool: 0});
                bool consensus = quorumVotes[i].mul(MALICIOUS_VOTE_COEFFICIENT) >= votes.length.sub(quorumVotes[i]).mul(BENIGN_VOTE_COEFFICIENT);

                for (j = 0; j < assertions.length; j++) {
                    bool malicious;

                    // If we didn&#39;t assert on this artifact
                    if (assertions[j].mask & (1 << i) == 0) {
                        continue;
                    }

                    // If we haven&#39;t revealed set to incorrect value
                    if (assertions[j].nonce == 0) {
                        malicious = !consensus;
                    } else {
                        malicious = (assertions[j].verdicts & assertions[j].mask) & (1 << i) != 0;
                    }

                    if (malicious == consensus) {
                        ap.numWinners = ap.numWinners.add(1);
                        ap.winnerPool = ap.winnerPool.add(assertions[j].bid);
                    } else {
                        ap.numLosers = ap.numLosers.add(1);
                        ap.loserPool = ap.loserPool.add(assertions[j].bid);
                    }
                }

                // If nobody asserted on this artifact, refund the ambassador
                if (ap.numWinners == 0 && ap.numLosers == 0) {
                    bountyRefund = bountyRefund.add(bounty.amount);
                    for (j = 0; j < assertions.length; j++) {
                        expertRewards[j] = expertRewards[j].add(assertions[j].bid);
                    }
                } else {
                    for (j = 0; j < assertions.length; j++) {
                        expertRewards[j] = expertRewards[j].add(assertions[j].bid);

                        // If we didn&#39;t assert on this artifact
                        if (assertions[j].mask & (1 << i) == 0) {
                            continue;
                        }

                        // If we haven&#39;t revealed set to incorrect value
                        if (assertions[j].nonce == 0) {
                            malicious = !consensus;
                        } else {
                            malicious = (assertions[j].verdicts & assertions[j].mask) & (1 << i) != 0;
                        }

                        if (malicious == consensus) {
                            expertRewards[j] = expertRewards[j].add(assertions[j].bid.mul(ap.loserPool).div(ap.winnerPool));
                            expertRewards[j] = expertRewards[j].add(bounty.amount.mul(assertions[j].bid).div(ap.winnerPool));
                        } else {
                            expertRewards[j] = expertRewards[j].sub(assertions[j].bid);
                        }
                    }
                }
            }
        }

        // Calculate rewards
        uint256 pot = bounty.amount.add(BOUNTY_FEE.add(ASSERTION_FEE.mul(assertions.length)));
        for (i = 0; i < assertions.length; i++) {
            pot = pot.add(assertions[i].bid);
        }

        bountyRefund = bountyRefund.div(bounty.numArtifacts);
        pot = pot.sub(bountyRefund);

        for (i = 0; i < assertions.length; i++) {
            expertRewards[i] = expertRewards[i].div(bounty.numArtifacts);
            pot = pot.sub(expertRewards[i]);
        }

        arbiterReward = pot;
    }

    /**
     * Function called after window has closed to handle reward disbursal
     *
     * This function will pay out rewards if the the bounty has a super majority
     * @param bountyGuid the guid of the bounty to settle
     */
    function settleBounty(uint128 bountyGuid) external whenNotPaused {
        Bounty storage bounty = bountiesByGuid[bountyGuid];
        Assertion[] storage assertions = assertionsByGuid[bountyGuid];

        // Check if this bountiesByGuid[bountyGuid] has been initialized
        require(bounty.author != address(0), "Bounty has not been initialized");
        // Check if this bounty has been previously resolved for the sender
        require(!bountySettled[bountyGuid][msg.sender], "Bounty has already been settled for sender");
        // Check that the voting round has closed
        // solium-disable-next-line indentation
        require(bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow) <= block.number || bounty.quorumReached,
            "Voting round is still active and quorum has not been reached");

        if (isArbiter(msg.sender)) {
            require(bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow) <= block.number, "Voting round still active");
            if (bounty.assignedArbiter == address(0)) {
                if (bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow).add(VALID_HASH_PERIOD) >= block.number) {
                    bounty.assignedArbiter = getWeightedRandomArbiter(bountyGuid);
                } else {
                    bounty.assignedArbiter = msg.sender;
                }
            }
        }

        uint256 payout = 0;
        uint256 bountyRefund;
        uint256 arbiterReward;
        uint256[] memory expertRewards;
        (bountyRefund, arbiterReward, expertRewards) = calculateBountyRewards(bountyGuid);

        bountySettled[bountyGuid][msg.sender] = true;

        // Disburse rewards
        if (bountyRefund != 0 && bounty.author == msg.sender) {
            token.safeTransfer(bounty.author, bountyRefund);
            payout = payout.add(bountyRefund);
        }

        for (uint256 i = 0; i < assertions.length; i++) {
            if (expertRewards[i] != 0 && assertions[i].author == msg.sender) {
                token.safeTransfer(assertions[i].author, expertRewards[i]);
                payout = payout.add(expertRewards[i]);
            }
        }

        if (arbiterReward != 0 && bounty.assignedArbiter == msg.sender) {
            token.safeTransfer(bounty.assignedArbiter, arbiterReward);
            payout = payout.add(arbiterReward);
        }

        emit SettledBounty(bountyGuid, msg.sender, payout);
    }

    /**
     *  Generates a random number from 0 to range based on the last block hash
     *
     *  @param seed random number for reproducing
     *  @param range end range for random number
     */
    function randomGen(uint256 targetBlock, uint seed, uint256 range) private view returns (int256 randomNumber) {
        return int256(uint256(keccak256(abi.encodePacked(blockhash(targetBlock), seed))) % range);
    }

    /**
     * Gets a random Arbiter weighted by the amount of Nectar they have
     *
     * @param bountyGuid the guid of the bounty
     */
    function getWeightedRandomArbiter(uint128 bountyGuid) public view returns (address voter) {
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");

        Bounty memory bounty = bountiesByGuid[bountyGuid];
        Vote[] memory votes = votesByGuid[bountyGuid];

        if (votes.length == 0) {
            return address(0);
        }

        uint i;
        uint256 sum = 0;
        int256 randomNum;

        for (i = 0; i < votes.length; i++) {
            sum = sum.add(staking.balanceOf(votes[i].author));
        }

        randomNum = randomGen(bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow), block.number, sum);

        for (i = 0; i < votes.length; i++) {
            randomNum -= int256(staking.balanceOf(votes[i].author));

            if (randomNum <= 0) {
                voter = votes[i].author;
                break;
            }
        }

    }

    /**
     * Get the total number of bounties tracked by the contract
     * @return total number of bounties
     */
    function getNumberOfBounties() external view returns (uint) {
        return bountyGuids.length;
    }

    /**
     * Get the current round for a bounty
     *
     * @param bountyGuid the guid of the bounty
     * @return the current round
     *      0 = assertions being accepted
     *      1 = assertions being revealed
     *      2 = arbiters voting
     *      3 = bounty finished
     */
    function getCurrentRound(uint128 bountyGuid) external view returns (uint) {
        // Check if this bounty has been initialized
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");

        Bounty memory bounty = bountiesByGuid[bountyGuid];

        if (bounty.expirationBlock > block.number) {
            return 0;
        } else if (bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW) > block.number) {
            return 1;
        } else if (bounty.expirationBlock.add(ASSERTION_REVEAL_WINDOW).add(arbiterVoteWindow) > block.number &&
                  !bounty.quorumReached) {
            return 2;
        } else {
            return 3;
        }
    }

    /**
     * Gets the number of assertions for a bounty
     *
     * @param bountyGuid the guid of the bounty
     * @return number of assertions for the given bounty
     */
    function getNumberOfAssertions(uint128 bountyGuid) external view returns (uint) {
        // Check if this bounty has been initialized
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");

        return assertionsByGuid[bountyGuid].length;
    }

    /**
     * Gets the vote count for a specific bounty
     *
     * @param bountyGuid the guid of the bounty
     */
    function getNumberOfVotes(uint128 bountyGuid) external view returns (uint) {
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");

        return votesByGuid[bountyGuid].length;
    }

    /**
     * Gets all the voters for a specific bounty
     *
     * @param bountyGuid the guid of the bounty
     */
    function getVoters(uint128 bountyGuid) external view returns (address[]) {
        require(bountiesByGuid[bountyGuid].author != address(0), "Bounty has not been initialized");

        Vote[] memory votes = votesByGuid[bountyGuid];
        uint count = votes.length;

        address[] memory voters = new address[](count);

        for (uint i = 0; i < count; i++) {
            voters[i] = votes[i].author;
        }

        return voters;
    }

    /** Candidate for future arbiter */
    struct Candidate {
        address addr;
        uint256 count;
    }

    /**
     * View function displays most active bounty posters over past
     * ARBITER_LOOKBACK_RANGE bounties to select future arbiters
     *
     * @return sorted array of most active bounty posters
     */
    function getArbiterCandidates() external view returns (address[]) {
        require(bountyGuids.length > 0, "No bounties have been placed");

        uint256 count = 0;
        Candidate[] memory candidates = new Candidate[](ARBITER_LOOKBACK_RANGE);

        uint256 lastBounty = 0;
        if (bountyGuids.length > ARBITER_LOOKBACK_RANGE) {
            lastBounty = bountyGuids.length.sub(ARBITER_LOOKBACK_RANGE);
        }

        for (uint256 i = bountyGuids.length; i > lastBounty; i--) {
            address addr = bountiesByGuid[bountyGuids[i.sub(1)]].author;
            bool found = false;
            for (uint256 j = 0; j < count; j++) {
                if (candidates[j].addr == addr) {
                    candidates[j].count = candidates[j].count.add(1);
                    found = true;
                    break;
                }
            }

            if (!found) {
                candidates[count] = Candidate(addr, 1);
                count = count.add(1);
            }
        }

        address[] memory ret = new address[](count);

        for (i = 0; i < ret.length; i++) {
            uint256 next = 0;
            uint256 value = candidates[0].count;



            for (j = 0; j < count; j++) {
                if (candidates[j].count > value) {
                    next = j;
                    value = candidates[j].count;
                }
            }

            ret[i] = candidates[next].addr;
            candidates[next] = candidates[count.sub(1)];
            count = count.sub(1);
        }

        return ret;
    }

    function calculateMask(uint256 i, uint256 b) public pure returns(uint256) {
        if (b != 0) {
            return 1 << i;
        }

        return 0;
    }

    /**
     * View function displays the most active bounty voters over past
     * ARBITER_LOOKBACK_RANGE bounties to select future arbiters
     *
     * @return a sorted array of most active bounty voters and a boolean array of whether
     * or not they were active in 90% of bounty votes
     */

    function getActiveArbiters() external view returns (address[], bool[]) {
        require(bountyGuids.length > 0, "No bounties have been placed");
        uint256 count = 0;
        uint256 threshold = bountyGuids.length.div(10).mul(9);
        address[] memory ret_addr = new address[](count);
        bool[] memory ret_arbiter_ativity_threshold = new bool[](count);

        Candidate[] memory candidates = new Candidate[](ARBITER_LOOKBACK_RANGE);

        uint256 lastBounty = 0;
        if (bountyGuids.length > ARBITER_LOOKBACK_RANGE) {
            lastBounty = bountyGuids.length.sub(ARBITER_LOOKBACK_RANGE);
            threshold = lastBounty.div(10).mul(9);
        }

        for (uint256 i = bountyGuids.length.sub(1); i > lastBounty; i--) {
            Vote[] memory votes = votesByGuid[bountyGuids[i]];

            for (uint256 j = 0; j < votes.length; j++) {
                bool found = false;
                address addr = votes[j].author;

                for (uint256 k = 0; k < count; k++) {
                    if (candidates[k].addr == addr) {
                        candidates[k].count = candidates[k].count.add(1);
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    candidates[count] = Candidate(addr, 1);
                    count = count.add(1);
                }

            }

        }


        for (i = 0; i < ret_addr.length; i++) {
            uint256 next = 0;
            uint256 value = candidates[0].count;

            for (j = 0; j < count; j++) {
                if (candidates[j].count > value) {
                    next = j;
                    value = candidates[j].count;
                }
            }

            ret_addr[i] = candidates[next].addr;
            if (candidates[next].count.div(10).mul(9) < threshold) {
                ret_arbiter_ativity_threshold[i] = false;
            } else {
                ret_arbiter_ativity_threshold[i] = true;
            }

            count = count.sub(1);
            candidates[next] = candidates[count];
        }

        return (ret_addr, ret_arbiter_ativity_threshold);

    }

}