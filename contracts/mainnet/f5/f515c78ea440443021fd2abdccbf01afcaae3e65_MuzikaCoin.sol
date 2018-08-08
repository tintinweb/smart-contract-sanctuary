pragma solidity ^0.4.23;

// File: zeppelin-solidity\contracts\ownership\Ownable.sol

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity\contracts\lifecycle\Pausable.sol

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

// File: zeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: zeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity\contracts\token\ERC20\BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

// File: zeppelin-solidity\contracts\token\ERC20\ERC20.sol

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

// File: zeppelin-solidity\contracts\token\ERC20\StandardToken.sol

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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity\contracts\token\ERC20\MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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

// File: contracts\lib\PreSignedContract.sol

contract PreSignedContract is Ownable {
  mapping (uint8 => bytes) internal _prefixPreSignedFirst;
  mapping (uint8 => bytes) internal _prefixPreSignedSecond;

  function upgradePrefixPreSignedFirst(uint8 _version, bytes _prefix) public onlyOwner {
    _prefixPreSignedFirst[_version] = _prefix;
  }

  function upgradePrefixPreSignedSecond(uint8 _version, bytes _prefix) public onlyOwner {
    _prefixPreSignedSecond[_version] = _prefix;
  }

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  function messagePreSignedHashing(
    bytes8 _mode,
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version
  ) public view returns (bytes32 hash) {
    if (_version <= 2) {
      hash = keccak256(
        _mode,
        _token,
        _to,
        _value,
        _fee,
        _nonce
      );
    } else {
      // Support SignTypedData flexibly
      hash = keccak256(
        _prefixPreSignedFirst[_version],
        _mode,
        _token,
        _to,
        _value,
        _fee,
        _nonce
      );
    }
  }

  function preSignedHashing(
    bytes8 _mode,
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version
  ) public view returns (bytes32) {
    bytes32 hash = messagePreSignedHashing(
      _mode,
      _token,
      _to,
      _value,
      _fee,
      _nonce,
      _version
    );

    if (_version <= 2) {
      if (_version == 0) {
        return hash;
      } else if (_version == 1) {
        return keccak256(
          &#39;\x19Ethereum Signed Message:\n32&#39;,
          hash
        );
      } else {
        // Support Standard Prefix (Trezor)
        return keccak256(
          &#39;\x19Ethereum Signed Message:\n\x20&#39;,
          hash
        );
      }
    } else {
      // Support SignTypedData flexibly
      if (_prefixPreSignedSecond[_version].length > 0) {
        return keccak256(
          _prefixPreSignedSecond[_version],
          hash
        );
      } else {
        return hash;
      }
    }
  }

  function preSignedCheck(
    bytes8 _mode,
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) public view returns (address) {
    bytes32 hash = preSignedHashing(
      _mode,
      _token,
      _to,
      _value,
      _fee,
      _nonce,
      _version
    );

    address _from = recover(hash, _sig);
    require(_from != address(0));

    return _from;
  }

  function transferPreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck(&#39;Transfer&#39;, _token, _to, _value, _fee, _nonce, _version, _sig);
  }

  function approvePreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck(&#39;Approval&#39;, _token, _to, _value, _fee, _nonce, _version, _sig);
  }

  function increaseApprovalPreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck(&#39;IncApprv&#39;, _token, _to, _value, _fee, _nonce, _version, _sig);
  }

  function decreaseApprovalPreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck(&#39;DecApprv&#39;, _token, _to, _value, _fee, _nonce, _version, _sig);
  }
}

// File: contracts\token\MuzikaCoin.sol

contract MuzikaCoin is MintableToken, Pausable {
  string public name = &#39;MUZIKA COIN&#39;;
  string public symbol = &#39;MZK&#39;;
  uint8 public decimals = 18;

  event Burn(address indexed burner, uint256 value);

  event FreezeAddress(address indexed target);
  event UnfreezeAddress(address indexed target);

  event TransferPreSigned(
    address indexed from,
    address indexed to,
    address indexed delegate,
    uint256 value,
    uint256 fee
  );
  event ApprovalPreSigned(
    address indexed owner,
    address indexed spender,
    address indexed delegate,
    uint256 value,
    uint256 fee
  );

  mapping (address => bool) public frozenAddress;

  mapping (bytes => bool) internal _signatures;

  PreSignedContract internal _preSignedContract = PreSignedContract(0xE55b5f4fAd5cD3923C392e736F58dEF35d7657b8);

  modifier onlyNotFrozenAddress(address _target) {
    require(!frozenAddress[_target]);
    _;
  }

  modifier onlyFrozenAddress(address _target) {
    require(frozenAddress[_target]);
    _;
  }

  constructor(uint256 initialSupply) public {
    totalSupply_ = initialSupply;
    balances[msg.sender] = initialSupply;
    emit Transfer(address(0), msg.sender, initialSupply);
  }

  /**
   * @dev Freeze account(address)
   *
   * @param _target The address to freeze
   */
  function freezeAddress(address _target)
    public
    onlyOwner
    onlyNotFrozenAddress(_target)
  {
    frozenAddress[_target] = true;

    emit FreezeAddress(_target);
  }

  /**
   * @dev Unfreeze account(address)
   *
   * @param _target The address to unfreeze
   */
  function unfreezeAddress(address _target)
    public
    onlyOwner
    onlyFrozenAddress(_target)
  {
    delete frozenAddress[_target];

    emit UnfreezeAddress(_target);
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

  function transfer(
    address _to,
    uint256 _value
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyNotFrozenAddress(_from)
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  /**
   * @dev Be careful to use delegateTransfer.
   * @dev If attacker whose balance is less than sum of fee and amount
   * @dev requests constantly transferring using delegateTransfer/delegateApprove to someone,
   * @dev he or she may lose all ether to process these requests.
   */
  function transferPreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.transferPreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );
    require(!frozenAddress[_from]);

    uint256 _burden = _value.add(_fee);
    require(_burden <= balances[_from]);

    balances[_from] = balances[_from].sub(_burden);
    balances[_to] = balances[_to].add(_value);
    balances[msg.sender] = balances[msg.sender].add(_fee);
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, msg.sender, _fee);

    _signatures[_sig] = true;
    emit TransferPreSigned(_from, _to, msg.sender, _value, _fee);

    return true;
  }

  function approvePreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.approvePreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );

    require(!frozenAddress[_from]);
    require(_fee <= balances[_from]);

    allowed[_from][_to] = _value;
    emit Approval(_from, _to, _value);

    if (_fee > 0) {
      balances[_from] = balances[_from].sub(_fee);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      emit Transfer(_from, msg.sender, _fee);
    }

    _signatures[_sig] = true;
    emit ApprovalPreSigned(_from, _to, msg.sender, _value, _fee);

    return true;
  }

  function increaseApprovalPreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.increaseApprovalPreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );

    require(!frozenAddress[_from]);
    require(_fee <= balances[_from]);

    allowed[_from][_to] = allowed[_from][_to].add(_value);
    emit Approval(_from, _to, allowed[_from][_to]);

    if (_fee > 0) {
      balances[_from] = balances[_from].sub(_fee);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      emit Transfer(_from, msg.sender, _fee);
    }

    _signatures[_sig] = true;
    emit ApprovalPreSigned(_from, _to, msg.sender, allowed[_from][_to], _fee);

    return true;
  }

  function decreaseApprovalPreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.decreaseApprovalPreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );
    require(!frozenAddress[_from]);

    require(_fee <= balances[_from]);

    uint256 oldValue = allowed[_from][_to];
    if (_value > oldValue) {
      oldValue = 0;
    } else {
      oldValue = oldValue.sub(_value);
    }

    allowed[_from][_to] = oldValue;
    emit Approval(_from, _to, oldValue);

    if (_fee > 0) {
      balances[_from] = balances[_from].sub(_fee);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      emit Transfer(_from, msg.sender, _fee);
    }

    _signatures[_sig] = true;
    emit ApprovalPreSigned(_from, _to, msg.sender, oldValue, _fee);

    return true;
  }
}