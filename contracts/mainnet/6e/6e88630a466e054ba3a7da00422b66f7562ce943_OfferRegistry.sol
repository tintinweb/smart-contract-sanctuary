pragma solidity ^0.4.24;

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

// File: contracts/OfferMultiSig.sol

contract OfferMultiSig is Pausable {
    using SafeMath for uint256;
    
    string public constant NAME = "Offer MultiSig";
    string public constant VERSION = "0.0.1";
    uint256 public constant MIN_SETTLEMENT_PERIOD = 10;
    uint256 public constant MAX_SETTLEMENT_PERIOD = 3600;

    event CommunicationsSet(
        bytes32 websocketUri
    );

    event OpenedAgreement(
        address _ambassador
    );

    event CanceledAgreement(
        address _ambassador
    );

    event JoinedAgreement(
        address _expert
    );

    event ClosedAgreement(
        address _expert,
        address _ambassador
    );

    event FundsDeposited(
        address _ambassador,
        address _expert,
        uint256 ambassadorBalance,
        uint256 expertBalance
    );

    event StartedSettle(
        address initiator,
        uint sequence,
        uint settlementPeriodEnd
    );

    event SettleStateChallenged(
        address challenger,
        uint sequence,
        uint settlementPeriodEnd
    );

    address public nectarAddress; // Address of offer nectar token
    address public ambassador; // Address of first channel participant
    address public expert; // Address of second channel participant
    
    bool public isOpen = false; // true when both parties have joined
    bool public isPending = false; // true when waiting for counterparty to join agreement

    uint public settlementPeriodLength; // How long challengers have to reply to settle engagement
    uint public isClosed; // if the period has closed
    uint public sequence; // state nonce used in during settlement
    uint public isInSettlementState; // meta channel is in settling 1: Not settling 0
    uint public settlementPeriodEnd; // The time when challenges are no longer accepted after

    bytes public state; // the current state
    bytes32 public websocketUri; // a geth node running whisper (shh)

    constructor(address _nectarAddress, address _ambassador, address _expert, uint _settlementPeriodLength) public {
        require(_ambassador != address(0), "No ambassador lib provided to constructor");
        require(_expert != address(0), "No expert provided to constructor");
        require(_nectarAddress != address(0), "No token provided to constructor");

        // solium-disable-next-line indentation
        require(_settlementPeriodLength >= MIN_SETTLEMENT_PERIOD && _settlementPeriodLength <= MAX_SETTLEMENT_PERIOD,
            "Settlement period out of range");

        ambassador = _ambassador;
        expert = _expert;
        settlementPeriodLength = _settlementPeriodLength;
        nectarAddress = _nectarAddress;
    }

    /** Function only callable by participants */
    modifier onlyParticipants() {
        require(msg.sender == ambassador || msg.sender == expert, "msg.sender is not a participant");
        _;
    }

    /**
     * Function called by ambassador to open channel with _expert 
     * 
     * @param _state inital offer state
     * @param _v the recovery id from signature of state
     * @param _r output of ECDSA signature of state
     * @param _s output of ECDSA signature of state
     */
    function openAgreement(bytes _state, uint8 _v, bytes32 _r, bytes32 _s) public whenNotPaused {
        // require the channel is not open yet
        require(isOpen == false, "openAgreement already called, isOpen true");
        require(isPending == false, "openAgreement already called, isPending true");
        require(msg.sender == ambassador, "msg.sender is not the ambassador");
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");
        require(msg.sender == getPartyA(_state), "Party A does not match signature recovery");

        // check the account opening a channel signed the initial state
        address initiator = getSig(_state, _v, _r, _s);

        require(ambassador == initiator, "Initiator in state is not the ambassador");

        isPending = true;

        state = _state;

        open(_state);

        emit OpenedAgreement(ambassador);
    }

    /**
     * Function called by ambassador to cancel a channel that hasn&#39;t been joined yet
     */
    function cancelAgreement() public whenNotPaused {
        // require the channel is not open yet
        require(isPending == true, "Only a channel in a pending state can be canceled");
        require(msg.sender == ambassador, "Only an ambassador can cancel an agreement");

        isPending = false;

        cancel(nectarAddress);

        emit CanceledAgreement(ambassador);
    }

    /**
     * Function called by expert to complete opening the channel with an ambassador defined in the _state
     * 
     * @param _state offer state from ambassador
     * @param _v the recovery id from signature of state
     * @param _r output of ECDSA signature  of state
     * @param _s output of ECDSA signature of state
     */
    function joinAgreement(bytes _state, uint8 _v, bytes32 _r, bytes32 _s) public whenNotPaused {
        require(isOpen == false, "openAgreement already called, isOpen true");
        require(msg.sender == expert, "msg.sender is not the expert");
        require(isPending, "Offer not pending");
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");

        // check that the state is signed by the sender and sender is in the state
        address joiningParty = getSig(_state, _v, _r, _s);

        require(expert == joiningParty, "Joining party in state is not the expert");

        // no longer allow joining functions to be called
        isOpen = true;

        isPending = false;

        join(state);

        emit JoinedAgreement(expert);
    }

    /**
     * Function called by ambassador to update balance and add to escrow
     * by default to escrows the allowed balance
     * @param _state offer state from ambassador
     * @param _sigV the recovery id from signature of state by both parties
     * @param _sigR output of ECDSA signature  of state by both parties
     * @param _sigS output of ECDSA signature of state by both parties
     * @dev index 0 is the ambassador signature
     * @dev index 1 is the expert signature
     */
    function depositFunds(bytes _state, uint8[2] _sigV, bytes32[2] _sigR, bytes32[2] _sigS) public onlyParticipants whenNotPaused {
        require(isOpen == true, "Tried adding funds to a closed msig wallet");
        address _ambassador = getSig(_state, _sigV[0], _sigR[0], _sigS[0]);
        address _expert = getSig(_state, _sigV[1], _sigR[1], _sigS[1]);
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");
        // Require both signatures
        require(_hasAllSigs(_ambassador, _expert), "Missing signatures");

        state = _state;

        update(_state);

        emit FundsDeposited(_ambassador, _expert, getBalanceA(_state), getBalanceB(_state));
    }

    /**
     * Function called by ambassador or expert to close a their channel after a dispute has timedout
     *
     * @param _state final offer state agreed on by both parties through dispute settlement
     * @param _sigV the recovery id from signature of state by both parties
     * @param _sigR output of ECDSA signature  of state by both parties
     * @param _sigS output of ECDSA signature of state by both parties
     * @dev index 0 is the ambassador signature
     * @dev index 1 is the expert signature
     */
    function closeAgreementWithTimeout(bytes _state, uint8[2] _sigV, bytes32[2] _sigR, bytes32[2] _sigS) public onlyParticipants whenNotPaused {
        address _ambassador = getSig(_state, _sigV[0], _sigR[0], _sigS[0]);
        address _expert = getSig(_state, _sigV[1], _sigR[1], _sigS[1]);
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");
        require(settlementPeriodEnd <= block.number, "Settlement period hasn&#39;t ended");
        require(isClosed == 0, "Offer is closed");
        require(isInSettlementState == 1, "Offer is not in settlement state");

        require(_hasAllSigs(_ambassador, _expert), "Missing signatures");
        require(keccak256(state) == keccak256(_state), "State hash mismatch");

        isClosed = 1;

        finalize(_state);
        isOpen = false;

        emit ClosedAgreement(_expert, _ambassador);
    }


    /**
     * Function called by ambassador or expert to close a their channel with close flag
     *
     * @param _state final offer state agreed on by both parties with close flag
     * @param _sigV the recovery id from signature of state by both parties
     * @param _sigR output of ECDSA signature  of state by both parties
     * @param _sigS output of ECDSA signature of state by both parties
     * @dev index 0 is the ambassador signature
     * @dev index 1 is the expert signature
     */
    function closeAgreement(bytes _state, uint8[2] _sigV, bytes32[2] _sigR, bytes32[2] _sigS) public onlyParticipants whenNotPaused {
        address _ambassador = getSig(_state, _sigV[0], _sigR[0], _sigS[0]);
        address _expert = getSig(_state, _sigV[1], _sigR[1], _sigS[1]);
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");
        require(isClosed == 0, "Offer is closed");
        
        /// @dev make sure we&#39;re not in dispute
        require(isInSettlementState == 0, "Offer is in settlement state");

        /// @dev must have close flag
        require(_isClosed(_state), "State did not have a signed close out state");
        require(_hasAllSigs(_ambassador, _expert), "Missing signatures");

        isClosed = 1;
        state = _state;

        finalize(_state);
        isOpen = false;

        emit ClosedAgreement(_expert, _ambassador);

    }

    /**
     * Function called by ambassador or expert to start initalize a disputed settlement
     * using an agreed upon state. It starts a timeout for a reply using `settlementPeriodLength`
     * 
     * @param _state offer state agreed on by both parties
     * @param _sigV the recovery id from signature of state by both parties
     * @param _sigR output of ECDSA signature  of state by both parties
     * @param _sigS output of ECDSA signature of state by both parties
     */
    function startSettle(bytes _state, uint8[2] _sigV, bytes32[2] _sigR, bytes32[2] _sigS) public onlyParticipants whenNotPaused {
        address _ambassador = getSig(_state, _sigV[0], _sigR[0], _sigS[0]);
        address _expert = getSig(_state, _sigV[1], _sigR[1], _sigS[1]);
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");

        require(_hasAllSigs(_ambassador, _expert), "Missing signatures");

        require(isClosed == 0, "Offer is closed");
        require(isInSettlementState == 0, "Offer is in settlement state");

        state = _state;

        sequence = getSequence(_state);

        isInSettlementState = 1;
        settlementPeriodEnd = block.number.add(settlementPeriodLength);

        emit StartedSettle(msg.sender, sequence, settlementPeriodEnd);
    }

    /**
     * Function called by ambassador or expert to challenge a disputed state
     * The new state is accepted if it is signed by both parties and has a higher sequence number
     * 
     * @param _state offer state agreed on by both parties
     * @param _sigV the recovery id from signature of state by both parties
     * @param _sigR output of ECDSA signature  of state by both parties
     * @param _sigS output of ECDSA signature of state by both parties
     */
    function challengeSettle(bytes _state, uint8[2] _sigV, bytes32[2] _sigR, bytes32[2] _sigS) public onlyParticipants whenNotPaused {
        address _ambassador = getSig(_state, _sigV[0], _sigR[0], _sigS[0]);
        address _expert = getSig(_state, _sigV[1], _sigR[1], _sigS[1]);
        require(getTokenAddress(_state) == nectarAddress, "Invalid token address");
        require(_hasAllSigs(_ambassador, _expert), "Missing signatures");

        require(isInSettlementState == 1, "Offer is not in settlement state");
        require(block.number < settlementPeriodEnd, "Settlement period has ended");

        require(getSequence(_state) > sequence, "Sequence number is too old");

        settlementPeriodEnd = block.number.add(settlementPeriodLength);
        state = _state;
        sequence = getSequence(_state);

        emit SettleStateChallenged(msg.sender, sequence, settlementPeriodEnd);
    }

    /**
     * Return when the settlement period is going to end. This is the amount of time
     * an ambassor or expert has to reply with a new state
     */
    function getSettlementPeriodEnd() public view returns (uint) {
        return settlementPeriodEnd;
    }

    /**
    * Function to be called by ambassador to set comunication information
    *
    * @param _websocketUri uri of whisper node
    */
    function setCommunicationUri(bytes32 _websocketUri) external whenNotPaused {
        require(msg.sender == ambassador, "msg.sender is not the ambassador");

        websocketUri = _websocketUri;

        emit CommunicationsSet(websocketUri);
    }

    /**
     * Function called to get the state sequence/nonce
     *
     * @param _state offer state
     */
    function getSequence(bytes _state) public pure returns (uint _seq) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _seq := mload(add(_state, 64))
        }
    }

    function isChannelOpen() public view returns (bool) {
        return isOpen;
    }

    function getWebsocketUri() public view returns (bytes32) {
        return websocketUri;
    }

    /**
     * A utility function to check if both parties have signed
     *
     * @param _a ambassador address
     * @param _b expert address
     */

    function _hasAllSigs(address _a, address _b) internal view returns (bool) {
        require(_a == ambassador && _b == expert, "Signatures do not match parties in state");

        return true;
    }

    /**
     * A utility function to check for the closed flag in the offer state
     *
     * @param _state current offer state
     */
    function _isClosed(bytes _state) internal pure returns (bool) {
        require(getCloseFlag(_state) == 1, "Offer is not closed");

        return true;
    }

    function getCloseFlag(bytes _state) public pure returns (uint8 _flag) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _flag := mload(add(_state, 32))
        }
    }

    function getPartyA(bytes _state) public pure returns (address _ambassador) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _ambassador := mload(add(_state, 96))
        }
    }

    function getPartyB(bytes _state) public pure returns (address _expert) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _expert := mload(add(_state, 128))
        }
    }

    function getBalanceA(bytes _state) public pure returns (uint256 _balanceA) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _balanceA := mload(add(_state, 192))
        }
    }

    function getBalanceB(bytes _state) public pure returns (uint256 _balanceB) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _balanceB := mload(add(_state, 224))
        }
    }

    function getTokenAddress(bytes _state) public pure returns (address _token) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _token := mload(add(_state, 256))
        }
    }

    function getTotal(bytes _state) public pure returns (uint256) {
        uint256 _a = getBalanceA(_state);
        uint256 _b = getBalanceB(_state);

        return _a.add(_b);
    }

    function open(bytes _state) internal returns (bool) {
        require(msg.sender == getPartyA(_state), "Party A does not match signature recovery");

        // get the token instance used to allow funds to msig
        NectarToken _t = NectarToken(getTokenAddress(_state));

        // ensure the amount sent to open channel matches the signed state balance
        require(_t.allowance(getPartyA(_state), this) == getBalanceA(_state), "value does not match ambassador state balance");

        // complete the tranfer of ambassador approved tokens
        require(_t.transferFrom(getPartyA(_state), this, getBalanceA(_state)), "failed tranfering approved balance from ambassador");
        return true;
    }

    function join(bytes _state) internal view returns (bool) {
        // get the token instance used to allow funds to msig
        NectarToken _t = NectarToken(getTokenAddress(_state));

        // ensure the amount sent to join channel matches the signed state balance
        require(msg.sender == getPartyB(_state), "Party B does not match signature recovery");

        // Require bonded is the sum of balances in state
        require(getTotal(_state) == _t.balanceOf(this), "token total deposited does not match state balance");

        return true;
    }

    function update(bytes _state) internal returns (bool) {
        // get the token instance used to allow funds to msig
        NectarToken _t = NectarToken(getTokenAddress(_state));

        if(_t.allowance(getPartyA(_state), this) > 0) {
            require(_t.transferFrom(getPartyA(_state), this, _t.allowance(getPartyA(_state), this)), "failed transfering deposit from party A to contract");
        }

        require(getTotal(_state) == _t.balanceOf(this), "token total deposited does not match state balance");
    }

    function cancel(address tokenAddress) internal returns (bool) {
        NectarToken _t = NectarToken(tokenAddress);

        return _t.transfer(msg.sender, _t.balanceOf(this));
    }

    /**
     * Function called by closeAgreementWithTimeout or closeAgreement to disperse payouts
     *
     * @param _state final offer state agreed on by both parties with close flag
     */

    function finalize(bytes _state) internal returns (bool) {
        address _a = getPartyA(_state);
        address _b = getPartyB(_state);

        NectarToken _t = NectarToken(getTokenAddress(_state));
        require(getTotal(_state) == _t.balanceOf(this), "tried finalizing token state that does not match bonded value");

        require(_t.transfer(_a, getBalanceA(_state)), "failed transfering balance to party A");
        require(_t.transfer(_b, getBalanceB(_state)), "failed transfering balance to party B");
    }


    /**
     * A utility function to return the address of the person that signed the state
     *
     * @param _state offer state that was signed
     * @param _v the recovery id from signature of state by both parties
     * @param _r output of ECDSA signature  of state by both parties
     * @param _s output of ECDSA signature of state by both parties
     */
    function getSig(bytes _state, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_state);

        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));

        address a = ecrecover(prefixedHash, _v, _r, _s);

        return a;
    }
}

// File: contracts/OfferRegistry.sol

/// @title Creates new Offer Channel contracts and keeps track of them
contract OfferRegistry is Pausable {

    struct OfferChannel {
        address msig;
        address ambassador;
        address expert;
    }

    event InitializedChannel(
        address msig,
        address ambassador,
        address expert,
        uint128 guid
    );

    uint128[] public channelsGuids;
    mapping (bytes32 => address) public participantsToChannel;
    mapping (uint128 => OfferChannel) public guidToChannel;

    address public nectarAddress;

    constructor(address _nectarAddress) public {
        require(_nectarAddress != address(0), "Invalid token address");

        nectarAddress = _nectarAddress;
    }

    /**
     * Function called by ambassador to initialize an offer contract
     * It deploys a new offer multi sig and saves it for each participant
     *
     * @param _ambassador address of ambassador
     * @param _expert address of expert
     * @param _settlementPeriodLength how long the parties have to dispute the settlement offer channel
     */
    function initializeOfferChannel(uint128 guid, address _ambassador, address _expert, uint _settlementPeriodLength) external whenNotPaused {
        require(address(0) != _expert, "Invalid expert address");
        require(address(0) != _ambassador, "Invalid ambassador address");
        require(msg.sender == _ambassador, "Initializer isn&#39;t ambassador");
        require(guidToChannel[guid].msig == address(0), "GUID already in use");

        bytes32 key = getParticipantsHash(_ambassador, _expert);

        if (participantsToChannel[key] != address(0)) {
            /// @dev check to make sure the participants don&#39;t already have an open channel
            // solium-disable-next-line indentation
            require(OfferMultiSig(participantsToChannel[key]).isChannelOpen() == false,
                "Channel already exists between parties");
        }

        address msig = new OfferMultiSig(nectarAddress, _ambassador, _expert, _settlementPeriodLength);

        participantsToChannel[key] = msig;

        guidToChannel[guid].msig = msig;
        guidToChannel[guid].ambassador = _ambassador;
        guidToChannel[guid].expert = _expert;

        channelsGuids.push(guid);

        emit InitializedChannel(msig, _ambassador, _expert, guid);
    }

    /**
     * Get the total number of offer channels tracked by the contract
     *
     * @return total number of offer channels
     */
    function getNumberOfOffers() external view returns (uint) {
        return channelsGuids.length;
    }

    /**
     * Function to get channel participants are on
     *
     * @param _ambassador the address of ambassador
     * @param _expert the address of ambassador
     */
    function getParticipantsChannel(address _ambassador, address _expert) external view returns (address) {
        bytes32 key = getParticipantsHash(_ambassador, _expert);

        require(participantsToChannel[key] != address(0), "Channel does not exist between parties");

        return participantsToChannel[key];
    }

    /**
     * Gets all the created channelsGuids
     *
     * @return list of every channel registered
     */
    function getChannelsGuids() external view returns (address[]) {
        require(channelsGuids.length != 0, "No channels initialized");

        address[] memory registeredChannelsGuids = new address[](channelsGuids.length);

        for (uint i = 0; i < channelsGuids.length; i++) {
            registeredChannelsGuids[i] = channelsGuids[i];
        }

        return registeredChannelsGuids;
    }

    /**
     * Pause all channels
     *
     * @return list of every channel registered
     */
    function pauseChannels() external onlyOwner whenNotPaused {
        require(channelsGuids.length != 0, "No channels initialized");

        pause();

        for (uint i = 0; i < channelsGuids.length; i++) {
            OfferMultiSig(guidToChannel[channelsGuids[i]].msig).pause();
        }

    }

    /**
     * Unpause all channels
     *
     * @return list of every channel registered
     */

    function unpauseChannels() external onlyOwner whenPaused {
        require(channelsGuids.length != 0, "No channels initialized");

        for (uint i = 0; i < channelsGuids.length; i++) {
            OfferMultiSig(guidToChannel[channelsGuids[i]].msig).unpause();
        }

    }

    /**
     * Return offer information from state
     *
     * @return list of every channel registered
     * @param _state offer state agreed on by both parties
     */

    function getOfferState(
        bytes _state
    )
    public
    pure
        returns (
            bytes32 _guid,
            uint256 _nonce,
            uint256 _amount,
            address _msigAddress,
            uint256 _balanceA,
            uint256 _balanceB,
            address _ambassador,
            address _expert,
            uint256 _isClosed,
            address _token,
            uint256 _mask,
            uint256 _assertion
        )
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
             _guid := mload(add(_state, 288)) // [256-287] - a globally-unique identifier for the listing
             _nonce:= mload(add(_state, 64)) // [32-63] - the sequence of state
             _amount := mload(add(_state, 320)) // [288-319] - the offer amount awarded to expert for responses
             _msigAddress := mload(add(_state, 160)) // [128-159] - msig address where funds and offer are managed
             _balanceA := mload(add(_state,192)) // [160-191] balance in nectar for ambassador
             _balanceB := mload(add(_state,224)) // [192-223] balance in nectar for expert
             _ambassador := mload(add(_state, 96)) // [64-95] - offer&#39;s ambassador address
             _expert := mload(add(_state, 128)) // [96-127] - offer&#39;s expert address
             _isClosed := mload(add(_state, 32)) // [0-31] - 0 or 1 for if the state is marked as closed
             _token := mload(add(_state, 256)) // [224-255] - nectar token address
             _mask := mload(add(_state, 480)) // [448-479] - assertion mask
             _assertion := mload(add(_state, 512)) // [480-511] - assertions from expert
        }
    }

    // Internals

    /**
     * Utility function to get hash
     *
     * @param _ambassador address of ambassador
     * @param _expert address of expert
     * @return hash of ambassador and expert
     */

    function getParticipantsHash(address _ambassador, address _expert) internal pure returns (bytes32) {
        string memory str_ambassador = toString(_ambassador);
        string memory str_expert = toString(_expert);

        return keccak256(abi.encodePacked(strConcat(str_ambassador, str_expert)));
    }

    function toString(address x) internal pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        }
        return string(b);
    }

    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;

        for (uint i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }

        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }

        return string(babcde);
    }


    /** Disable usage of the fallback function */
    function() public payable {
        revert("Do not allow sending Eth to this contract");
    }
}