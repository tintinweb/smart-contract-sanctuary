pragma solidity ^0.4.24;

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



/**
 * @title Lock Token
 *
 * Token would be locked for thirty days after ICO.  During this period
 * new buyer could still trade their tokens.
 */

 contract LockToken is StandardToken {
   using SafeMath for uint256;

   bool public isPublic;
   uint256 public unLockTime;
   PrivateToken public privateToken;

   modifier onlyPrivateToken() {
     require(msg.sender == address(privateToken));
     _;
   }

   /**
   * @dev Deposit is the function should only be called from PrivateToken
   * When the user wants to deposit their private Token to Origin Token. They should
   * let the Private Token invoke this function.
   * @param _depositor address. The person who wants to deposit.
   */

   function deposit(address _depositor, uint256 _value) public onlyPrivateToken returns(bool){
     require(_value != 0);
     balances[_depositor] = balances[_depositor].add(_value);
     emit Transfer(privateToken, _depositor, _value);
     return true;
   }

   constructor() public {
     //2050/12/31 00:00:00.
     unLockTime = 2556057600;
   }
 }

contract BCNTToken is LockToken{
  string public constant name = "Bincentive SIT Token"; // solium-disable-line uppercase
  string public constant symbol = "BCNT-SIT"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
  mapping(bytes => bool) internal signatures;
  event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    /**
    * @notice Submit a presigned transfer
    * @param _signature bytes The signature, issued by the owner.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 The amount of tokens to be transferred.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);
        require(block.number <= _validUntil);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(transferPreSignedHashing(address(this), _to, _value, _fee, _nonce, _validUntil));

        address from = ECRecovery.recover(hashedTx, _signature);
        require(from != address(0));

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);
        signatures[_signature] = true;

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

    /**
    * @notice Hash (keccak256) of the payload used by transferPreSigned
    * @param _token address The address of the token.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 The amount of tokens to be transferred.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
        /* "0d2d1bf5": transferPreSigned(address,address,uint256,uint256,uint256,uint256) */
        return keccak256(bytes4(0x0a0fb66b), _token, _to, _value, _fee, _nonce, _validUntil);
    }
    function transferPreSignedHashingWithPrefix(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
        return ECRecovery.toEthSignedMessageHash(transferPreSignedHashing(_token, _to, _value, _fee, _nonce, _validUntil));
    }

    /**
    * @dev Constructor that gives _owner all of existing tokens.
    */
    constructor(address _admin) public {
        totalSupply_ = INITIAL_SUPPLY;
        privateToken = new PrivateToken(
          _admin, "Bincentive Private SIT Token", "BCNP-SIT", decimals, INITIAL_SUPPLY
       );
    }
}


/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
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

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}



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


pragma solidity ^0.4.24;
pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract PrivateToken is StandardToken {
    using SafeMath for uint256;

    string public name; // solium-disable-line uppercase
    string public symbol; // solium-disable-line uppercase
    uint8 public decimals; // solium-disable-line uppercase

    address public admin;
    bool public isPublic;
    uint256 public unLockTime;
    LockToken originToken;

    event StartPublicSale(uint256);
    event Deposit(address indexed from, uint256 value);
    /**
    *  @dev check if msg.sender is allowed to deposit Origin token.
    */
    function isDepositAllowed() internal view{
      // If the tokens isn&#39;t public yet all transfering are limited to origin tokens
      require(isPublic);
      require(msg.sender == admin || block.timestamp > unLockTime);
    }

    /**
    * @dev Deposit msg.sender&#39;s origin token to real token
    */
    function deposit() public returns (bool){
      isDepositAllowed();
      uint256 _value;
      _value = balances[msg.sender];
      require(_value > 0);
      balances[msg.sender] = 0;
      require(originToken.deposit(msg.sender, _value));
      emit Deposit(msg.sender, _value);
    }

    /**
    * @dev Deposit depositor&#39;s origin token from privateToken
    * @param _depositor address The address of whom deposit the token.
    */
    function adminDeposit(address _depositor) public onlyAdmin returns (bool){
      isDepositAllowed();
      uint256 _value;
      _value = balances[_depositor];
      require(_value > 0);
      balances[_depositor] = 0;
      require(originToken.deposit(_depositor, _value));
      emit Deposit(_depositor, _value);
    }

    /**
    *  @dev Start Public sale and allow admin to deposit the token.
    *  normal users could deposit their tokens after the tokens unlocked
    */
    function startPublicSale(uint256 _unLockTime) public onlyAdmin {
      require(!isPublic);
      isPublic = true;
      unLockTime = _unLockTime;
      emit StartPublicSale(_unLockTime);
    }

    /**
    *  @dev unLock the origin token and start the public sale.
    */
    function unLock() public onlyAdmin{
      require(isPublic);
      unLockTime = block.timestamp;
    }


    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

    constructor(address _admin, string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public{
      originToken = LockToken(msg.sender);
      admin = _admin;
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply_ = _totalSupply;
      balances[admin] = _totalSupply;
      emit Transfer(address(0), admin, _totalSupply);
    }
}