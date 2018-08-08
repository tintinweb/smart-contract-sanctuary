pragma solidity ^0.4.18;

// File: contracts/IEscrow.sol

/**
 * @title Escrow interface
 *
 * @dev https://send.sd/token
 */
interface IEscrow {

  event Created(
    address indexed sender,
    address indexed recipient,
    address indexed arbitrator,
    uint256 transactionId
  );
  event Released(address indexed arbitrator, address indexed sentTo, uint256 transactionId);
  event Dispute(address indexed arbitrator, uint256 transactionId);
  event Paid(address indexed arbitrator, uint256 transactionId);

  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public;

  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public;

}

// File: contracts/ISendToken.sol

/**
 * @title ISendToken - Send Consensus Network Token interface
 * @dev token interface built on top of ERC20 standard interface
 * @dev see https://send.sd/token
 */
interface ISendToken {
  function transfer(address to, uint256 value) public returns (bool);

  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function verifiedTransferFrom(
      address from,
      address to,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate,
      uint256 fee
  ) public;

  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate
  ) public;

  event VerifiedTransfer(
      address indexed from,
      address indexed to,
      address indexed verifiedAddress,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate
  );
}

// File: contracts/ISnapshotToken.sol

/**
 * @title Snapshot Token
 *
 * @dev Snapshot Token interface
 * @dev https://send.sd/token
 */
interface ISnapshotToken {
  function requestSnapshots(uint256 _blockNumber) public;
  function takeSnapshot(address _owner) public returns(uint256);
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

// File: zeppelin-solidity/contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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

// File: contracts/SnapshotToken.sol

/**
 * @title Snapshot Token
 *
 * @dev Snapshot Token implementtion
 * @dev https://send.sd/token
 */
contract SnapshotToken is ISnapshotToken, StandardToken, Ownable {
  uint256 public snapshotBlock;

  mapping (address => Snapshot) internal snapshots;

  struct Snapshot {
    uint256 block;
    uint256 balance;
  }

  address public polls;

  modifier isPolls() {
    require(msg.sender == address(polls));
    _;
  }

  /**
   * @dev Remove Verified status of a given address
   * @notice Only contract owner
   * @param _address Address to unverify
   */
  function setPolls(address _address) public onlyOwner {
    polls = _address;
  }

  /**
   * @dev Extend OpenZeppelin&#39;s BasicToken transfer function to store snapshot
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    takeSnapshot(msg.sender);
    takeSnapshot(_to);
    return BasicToken.transfer(_to, _value);
  }

  /**
   * @dev Extend OpenZeppelin&#39;s StandardToken transferFrom function to store snapshot
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    takeSnapshot(_from);
    takeSnapshot(_to);
    return StandardToken.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Take snapshot
   * @param _owner address The address to take snapshot from
   */
  function takeSnapshot(address _owner) public returns(uint256) {
    if (snapshots[_owner].block < snapshotBlock) {
      snapshots[_owner].block = snapshotBlock;
      snapshots[_owner].balance = balanceOf(_owner);
    }
    return snapshots[_owner].balance;
  }

  /**
   * @dev Set snacpshot block
   * @param _blockNumber uint256 The new blocknumber for snapshots
   */
  function requestSnapshots(uint256 _blockNumber) public isPolls {
    snapshotBlock = _blockNumber;
  }
}

// File: zeppelin-solidity/contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

// File: contracts/SendToken.sol

/**
 * @title Send token
 *
 * @dev Implementation of Send Consensus network Standard
 * @dev https://send.sd/token
 */
contract SendToken is ISendToken, SnapshotToken, BurnableToken {
  IEscrow public escrow;

  mapping (address => bool) internal verifiedAddresses;

  modifier verifiedResticted() {
    require(verifiedAddresses[msg.sender]);
    _;
  }

  modifier escrowResticted() {
    require(msg.sender == address(escrow));
    _;
  }

  /**
   * @dev Check if an address is whitelisted by SEND
   * @param _address Address to check
   * @return bool
   */
  function isVerified(address _address) public view returns(bool) {
    return verifiedAddresses[_address];
  }

  /**
   * @dev Verify an addres
   * @notice Only contract owner
   * @param _address Address to verify
   */
  function verify(address _address) public onlyOwner {
    verifiedAddresses[_address] = true;
  }

  /**
   * @dev Remove Verified status of a given address
   * @notice Only contract owner
   * @param _address Address to unverify
   */
  function unverify(address _address) public onlyOwner {
    verifiedAddresses[_address] = false;
  }

  /**
   * @dev Remove Verified status of a given address
   * @notice Only contract owner
   * @param _address Address to unverify
   */
  function setEscrow(address _address) public onlyOwner {
    escrow = IEscrow(_address);
  }

  /**
   * @dev Transfer from one address to another issuing ane xchange rate
   * @notice Only verified addresses
   * @notice Exchange rate has 18 decimal places
   * @notice Value + fee <= allowance
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @param _referenceId internal app/user ID
   * @param _exchangeRate Exchange rate to sign transaction
   * @param _fee fee tot ake from sender
   */
  function verifiedTransferFrom(
      address _from,
      address _to,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate,
      uint256 _fee
  ) public verifiedResticted {
    require(_exchangeRate > 0);

    transferFrom(_from, _to, _value);
    transferFrom(_from, msg.sender, _fee);

    VerifiedTransfer(
      _from,
      _to,
      msg.sender,
      _value,
      _referenceId,
      _exchangeRate
    );
  }

  /**
   * @dev create an escrow transfer being the arbitrator
   * @param _sender Address to send tokens
   * @param _recipient Address to receive tokens
   * @param _transactionId internal ID for arbitrator
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to arbitrator (may be 0)
   * @param _expiration After this timestamp, user can claim tokens back.
   */
  function createEscrow(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public {
    escrow.create(
      _sender,
      _recipient,
      msg.sender,
      _transactionId,
      _tokens,
      _fee,
      _expiration
    );
  }

  /**
   * @dev fund escrow
   * @dev specified amount will be locked on escrow contract
   * @param _arbitrator Address of escrow arbitrator
   * @param _transactionId internal ID for arbitrator
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to arbitrator (may be 0)
   */
  function fundEscrow(
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public {
    uint256 total = _tokens.add(_fee);
    transfer(escrow, total);

    escrow.fund(
      msg.sender,
      _arbitrator,
      _transactionId,
      _tokens,
      _fee
    );
  }

  /**
   * @dev Issue exchange rates from escrow contract
   * @param _from Address to send tokens
   * @param _to Address to receive tokens
   * @param _verifiedAddress Address issuing the exchange rate
   * @param _value amount
   * @param _transactionId internal ID for issuer&#39;s reference
   * @param _exchangeRate exchange rate
   */
  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public escrowResticted {
    bool noRate = (_exchangeRate == 0);
    if (isVerified(_verifiedAddress)) {
      require(!noRate);
      VerifiedTransfer(
        _from,
        _to,
        _verifiedAddress,
        _value,
        _transactionId,
        _exchangeRate
      );
    } else {
      require(noRate);
    }
  }
}

// File: contracts/SDT.sol

/**
 * @title To instance SendToken for SEND foundation crowdasale
 * @dev see https://send.sd/token
 */
contract SDT is SendToken {
  string constant public name = "SEND Token";
  string constant public symbol = "SDT";
  uint256 constant public decimals = 18;

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  /**
  * @dev Constructor
  * @param _sale Address that will hold all vesting allocated tokens
  * @notice contract owner will have special powers in the contract
  * @notice _sale should hold all tokens in production as all pool will be vested
  * @return A uint256 representing the locked amount of tokens
  */
  function SDT(address _sale) public validAddress(_sale) {
    verifiedAddresses[owner] = true;
    totalSupply = 700000000 * 10 ** decimals;
    balances[_sale] = totalSupply;
  }
}