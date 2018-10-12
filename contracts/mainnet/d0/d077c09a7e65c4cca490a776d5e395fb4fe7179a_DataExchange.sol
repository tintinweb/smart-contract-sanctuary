pragma solidity ^0.4.24;

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
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
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

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


/**
 * @title TokenDestructible:
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="deacbbb3bdb19eec">[email&#160;protected]</span>π.com>
 * @dev Base contract that can be destroyed by owner. All funds in contract including
 * listed tokens will be sent to the owner.
 */
contract TokenDestructible is Ownable {

  constructor() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] tokens) onlyOwner public {

    // Transfer tokens to owner
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
  }
}

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


/**
 * @title Math
 * @dev Assorted math operations
 */
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


/**
 * @title WIBToken
 * @author Wibson Development Team <<span class="__cf_email__" data-cfemail="6f0b0a190a03001f0a1d1c2f18060d1c000141001d08">[email&#160;protected]</span>>
 * @notice Wibson Oficial Token, this is an ERC20 standard compliant token.
 * @dev WIBToken token has an initial supply of 9 billion tokens with 9 decimals.
 */
contract WIBToken is StandardToken {
  string public constant name = "WIBSON"; // solium-disable-line uppercase
  string public constant symbol = "WIB"; // solium-disable-line uppercase
  uint8 public constant decimals = 9; // solium-disable-line uppercase

  // solium-disable-next-line zeppelin/no-arithmetic-operations
  uint256 public constant INITIAL_SUPPLY = 9000000000 * (10 ** uint256(decimals));

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
}


/**
 * @title DataOrder
 * @author Wibson Development Team <<span class="__cf_email__" data-cfemail="77131201121b180712050437001e1504181959180510">[email&#160;protected]</span>>
 * @notice `DataOrder` is the contract between a given buyer and a set of sellers.
 *         This holds the information about the "deal" between them and how the
 *         transaction has evolved.
 */
contract DataOrder is Ownable {
  modifier validAddress(address addr) {
    require(addr != address(0));
    require(addr != address(this));
    _;
  }

  enum OrderStatus {
    OrderCreated,
    NotaryAdded,
    TransactionCompleted
  }

  enum DataResponseStatus {
    DataResponseAdded,
    RefundedToBuyer,
    TransactionCompleted
  }

  // --- Notary Information ---
  struct NotaryInfo {
    uint256 responsesPercentage;
    uint256 notarizationFee;
    string notarizationTermsOfService;
    uint32 addedAt;
  }

  // --- Seller Information ---
  struct SellerInfo {
    address notary;
    string dataHash;
    uint32 createdAt;
    uint32 closedAt;
    DataResponseStatus status;
  }

  address public buyer;
  string public filters;
  string public dataRequest;
  uint256 public price;
  string public termsAndConditions;
  string public buyerURL;
  string public buyerPublicKey;
  uint32 public createdAt;
  uint32 public transactionCompletedAt;
  OrderStatus public orderStatus;

  mapping(address => SellerInfo) public sellerInfo;
  mapping(address => NotaryInfo) internal notaryInfo;

  address[] public sellers;
  address[] public notaries;

  /**
   * @notice Contract&#39;s constructor.
   * @param _buyer Buyer address
   * @param _filters Target audience of the order.
   * @param _dataRequest Requested data type (Geolocation, Facebook, etc).
   * @param _price Price per added Data Response.
   * @param _termsAndConditions Copy of the terms and conditions for the order.
   * @param _buyerURL Public URL of the buyer where the data must be sent.
   * @param _buyerPublicKey Public Key of the buyer, which will be used to encrypt the
   *        data to be sent.
   */
  constructor(
    address _buyer,
    string _filters,
    string _dataRequest,
    uint256 _price,
    string _termsAndConditions,
    string _buyerURL,
    string _buyerPublicKey
  ) public validAddress(_buyer) {
    require(bytes(_buyerURL).length > 0);
    require(bytes(_buyerPublicKey).length > 0);

    buyer = _buyer;
    filters = _filters;
    dataRequest = _dataRequest;
    price = _price;
    termsAndConditions = _termsAndConditions;
    buyerURL = _buyerURL;
    buyerPublicKey = _buyerPublicKey;
    orderStatus = OrderStatus.OrderCreated;
    createdAt = uint32(block.timestamp);
    transactionCompletedAt = 0;
  }

  /**
   * @notice Adds a notary to the Data Order.
   * @param notary Notary&#39;s address.
   * @param responsesPercentage Percentage of DataResponses to audit per DataOrder.
            Value must be between 0 and 100.
   * @param notarizationFee Fee to be charged per validation done.
   * @param notarizationTermsOfService Notary&#39;s terms and conditions for the order.
   * @return true if the Notary was added successfully, reverts otherwise.
   */
  function addNotary(
    address notary,
    uint256 responsesPercentage,
    uint256 notarizationFee,
    string notarizationTermsOfService
  ) public onlyOwner validAddress(notary) returns (bool) {
    require(transactionCompletedAt == 0);
    require(responsesPercentage <= 100);
    require(!hasNotaryBeenAdded(notary));

    notaryInfo[notary] = NotaryInfo(
      responsesPercentage,
      notarizationFee,
      notarizationTermsOfService,
      uint32(block.timestamp)
    );
    notaries.push(notary);
    orderStatus = OrderStatus.NotaryAdded;
    return true;
  }

   /**
    * @notice Adds a new DataResponse.
    * @param seller Address of the Seller.
    * @param notary Notary address that the Seller chooses to use as notary,
    *        this must be one within the allowed notaries and within the
    *         DataOrder&#39;s notaries.
    * @param dataHash Hash of the data that must be sent, this is a SHA256.
    * @return true if the DataResponse was added successfully, reverts otherwise.
    */
  function addDataResponse(
    address seller,
    address notary,
    string dataHash
  ) public onlyOwner validAddress(seller) validAddress(notary) returns (bool) {
    require(orderStatus == OrderStatus.NotaryAdded);
    require(transactionCompletedAt == 0);
    require(!hasSellerBeenAccepted(seller));
    require(hasNotaryBeenAdded(notary));

    sellerInfo[seller] = SellerInfo(
      notary,
      dataHash,
      uint32(block.timestamp),
      0,
      DataResponseStatus.DataResponseAdded
    );

    sellers.push(seller);

    return true;
  }

  /**
   * @notice Closes a DataResponse.
   * @dev Once the buyer receives the seller&#39;s data and checks that it is valid
   *      or not, he must signal  DataResponse as completed.
   * @param seller Seller address.
   * @param transactionCompleted True, if the seller got paid for his/her data.
   * @return true if DataResponse was successfully closed, reverts otherwise.
   */
  function closeDataResponse(
    address seller,
    bool transactionCompleted
  ) public onlyOwner validAddress(seller) returns (bool) {
    require(orderStatus != OrderStatus.TransactionCompleted);
    require(transactionCompletedAt == 0);
    require(hasSellerBeenAccepted(seller));
    require(sellerInfo[seller].status == DataResponseStatus.DataResponseAdded);

    sellerInfo[seller].status = transactionCompleted
      ? DataResponseStatus.TransactionCompleted
      : DataResponseStatus.RefundedToBuyer;
    sellerInfo[seller].closedAt = uint32(block.timestamp);
    return true;
  }

  /**
   * @notice Closes the Data order.
   * @dev Once the DataOrder is closed it will no longer accept new DataResponses.
   * @return true if the DataOrder was successfully closed, reverts otherwise.
   */
  function close() public onlyOwner returns (bool) {
    require(orderStatus != OrderStatus.TransactionCompleted);
    require(transactionCompletedAt == 0);
    orderStatus = OrderStatus.TransactionCompleted;
    transactionCompletedAt = uint32(block.timestamp);
    return true;
  }

  /**
   * @notice Checks if a DataResponse for a given seller has been accepted.
   * @param seller Seller address.
   * @return true if the DataResponse was accepted, false otherwise.
   */
  function hasSellerBeenAccepted(
    address seller
  ) public view validAddress(seller) returns (bool) {
    return sellerInfo[seller].createdAt != 0;
  }

  /**
   * @notice Checks if the given notary was added to notarize this DataOrder.
   * @param notary Notary address to check.
   * @return true if the Notary was added, false otherwise.
   */
  function hasNotaryBeenAdded(
    address notary
  ) public view validAddress(notary) returns (bool) {
    return notaryInfo[notary].addedAt != 0;
  }

  /**
   * @notice Gets the notary information.
   * @param notary Notary address to get info for.
   * @return Notary information (address, responsesPercentage, notarizationFee,
   *         notarizationTermsOfService, addedAt)
   */
  function getNotaryInfo(
    address notary
  ) public view validAddress(notary) returns (
    address,
    uint256,
    uint256,
    string,
    uint32
  ) {
    require(hasNotaryBeenAdded(notary));
    NotaryInfo memory info = notaryInfo[notary];
    return (
      notary,
      info.responsesPercentage,
      info.notarizationFee,
      info.notarizationTermsOfService,
      uint32(info.addedAt)
    );
  }

  /**
   * @notice Gets the seller information.
   * @param seller Seller address to get info for.
   * @return Seller information (address, notary, dataHash, createdAt, closedAt,
   *         status)
   */
  function getSellerInfo(
    address seller
  ) public view validAddress(seller) returns (
    address,
    address,
    string,
    uint32,
    uint32,
    bytes32
  ) {
    require(hasSellerBeenAccepted(seller));
    SellerInfo memory info = sellerInfo[seller];
    return (
      seller,
      info.notary,
      info.dataHash,
      uint32(info.createdAt),
      uint32(info.closedAt),
      getDataResponseStatusAsString(info.status)
    );
  }

  /**
   * @notice Gets the selected notary for the given seller.
   * @param seller Seller address.
   * @return Address of the notary assigned to the given seller.
   */
  function getNotaryForSeller(
    address seller
  ) public view validAddress(seller) returns (address) {
    require(hasSellerBeenAccepted(seller));
    SellerInfo memory info = sellerInfo[seller];
    return info.notary;
  }

  function getDataResponseStatusAsString(
    DataResponseStatus drs
  ) internal pure returns (bytes32) {
    if (drs == DataResponseStatus.DataResponseAdded) {
      return bytes32("DataResponseAdded");
    }

    if (drs == DataResponseStatus.RefundedToBuyer) {
      return bytes32("RefundedToBuyer");
    }

    if (drs == DataResponseStatus.TransactionCompleted) {
      return bytes32("TransactionCompleted");
    }

    throw; // solium-disable-line security/no-throw
  }

}


/**
 * @title MultiMap
 * @author Wibson Development Team <<span class="__cf_email__" data-cfemail="99fdfceffcf5f6e9fcebead9eef0fbeaf6f7b7f6ebfe">[email&#160;protected]</span>>
 * @notice An address `MultiMap`.
 * @dev `MultiMap` is useful when you need to keep track of a set of addresses.
 */
library MultiMap {

  struct MapStorage {
    mapping(address => uint) addressToIndex;
    address[] addresses;
  }

  /**
   * @notice Retrieves a address from the given `MapStorage` using a index Key.
   * @param self `MapStorage` where the index must be searched.
   * @param index Index to find.
   * @return Address of the given Index.
   */
  function get(
    MapStorage storage self,
    uint index
  ) public view returns (address) {
    require(index < self.addresses.length);
    return self.addresses[index];
  }

  /**
   * @notice Checks if the given address exists in the storage.
   * @param self `MapStorage` where the key must be searched.
   * @param _key Address to find.
   * @return true if `_key` exists in the storage, false otherwise.
   */
  function exist(
    MapStorage storage self,
    address _key
  ) public view returns (bool) {
    if (_key != address(0)) {
      uint targetIndex = self.addressToIndex[_key];
      return targetIndex < self.addresses.length && self.addresses[targetIndex] == _key;
    } else {
      return false;
    }
  }

  /**
   * @notice Inserts a new address within the given storage.
   * @param self `MapStorage` where the key must be inserted.
   * @param _key Address to insert.
   * @return true if `_key` was added, reverts otherwise.
   */
  function insert(
    MapStorage storage self,
    address _key
  ) public returns (bool) {
    require(_key != address(0));
    if (exist(self, _key)) {
      return true;
    }

    self.addressToIndex[_key] = self.addresses.length;
    self.addresses.push(_key);

    return true;
  }

  /**
   * @notice Removes the given index from the storage.
   * @param self MapStorage` where the index lives.
   * @param index Index to remove.
   * @return true if address at `index` was removed, false otherwise.
   */
  function removeAt(MapStorage storage self, uint index) public returns (bool) {
    return remove(self, self.addresses[index]);
  }

  /**
   * @notice Removes the given address from the storage.
   * @param self `MapStorage` where the address lives.
   * @param _key Address to remove.
   * @return true if `_key` was removed, false otherwise.
   */
  function remove(MapStorage storage self, address _key) public returns (bool) {
    require(_key != address(0));
    if (!exist(self, _key)) {
      return false;
    }

    uint currentIndex = self.addressToIndex[_key];

    uint lastIndex = SafeMath.sub(self.addresses.length, 1);
    address lastAddress = self.addresses[lastIndex];
    self.addressToIndex[lastAddress] = currentIndex;
    self.addresses[currentIndex] = lastAddress;

    delete self.addresses[lastIndex];
    delete self.addressToIndex[_key];

    self.addresses.length--;
    return true;
  }

  /**
   * @notice Gets the current length of the Map.
   * @param self `MapStorage` to get the length from.
   * @return The length of the MultiMap.
   */
  function length(MapStorage storage self) public view returns (uint) {
    return self.addresses.length;
  }
}


/**
 * @title CryptoUtils
 * @author Wibson Development Team <<span class="__cf_email__" data-cfemail="284c4d5e4d4447584d5a5b685f414a5b474606475a4f">[email&#160;protected]</span>>
 * @notice Cryptographic utilities used by the Wibson protocol.
 * @dev In order to get the same hashes using `Web3` upon which the signatures
 *      are checked, you must use `web3.utils.soliditySha3` in v1.0 (or the
 *      homonymous function in the `web3-utils` package)
 *      http://web3js.readthedocs.io/en/1.0/web3-utils.html#utils-soliditysha3
 */
library CryptoUtils {

  /**
   * @notice Checks if the signature was created by the signer.
   * @param hash Hash of the data using the `keccak256` algorithm.
   * @param signer Signer address.
   * @param signature Signature over the hash.
   * @return true if `signer` is the one who signed the `hash`, false otherwise.
   */
  function isSignedBy(
    bytes32 hash,
    address signer,
    bytes signature
  ) private pure returns (bool) {
    require(signer != address(0));
    bytes32 prefixedHash = ECRecovery.toEthSignedMessageHash(hash);
    address recovered = ECRecovery.recover(prefixedHash, signature);
    return recovered == signer;
  }

  /**
   * @notice Checks if the notary&#39;s signature to be added to the DataOrder is valid.
   * @param order Order address.
   * @param notary Notary address.
   * @param responsesPercentage Percentage of DataResponses to audit per DataOrder.
   * @param notarizationFee Fee to be charged per validation done.
   * @param notarizationTermsOfService Notary terms and conditions for the order.
   * @param notarySignature Off-chain Notary signature.
   * @return true if `notarySignature` is valid, false otherwise.
   */
  function isNotaryAdditionValid(
    address order,
    address notary,
    uint256 responsesPercentage,
    uint256 notarizationFee,
    string notarizationTermsOfService,
    bytes notarySignature
  ) public pure returns (bool) {
    require(order != address(0));
    require(notary != address(0));
    bytes32 hash = keccak256(
      abi.encodePacked(
        order,
        responsesPercentage,
        notarizationFee,
        notarizationTermsOfService
      )
    );

    return isSignedBy(hash, notary, notarySignature);
  }

  /**
   * @notice Checks if the parameters passed correspond to the seller&#39;s signature used.
   * @param order Order address.
   * @param seller Seller address.
   * @param notary Notary address.
   * @param dataHash Hash of the data that must be sent, this is a SHA256.
   * @param signature Signature of DataResponse.
   * @return true if arguments are signed by the `seller`, false otherwise.
   */
  function isDataResponseValid(
    address order,
    address seller,
    address notary,
    string dataHash,
    bytes signature
  ) public pure returns (bool) {
    require(order != address(0));
    require(seller != address(0));
    require(notary != address(0));

    bytes memory packed = bytes(dataHash).length > 0
      ? abi.encodePacked(order, notary, dataHash)
      : abi.encodePacked(order, notary);

    bytes32 hash = keccak256(packed);
    return isSignedBy(hash, seller, signature);
  }

  /**
   * @notice Checks if the notary&#39;s signature to close the `DataResponse` is valid.
   * @param order Order address.
   * @param seller Seller address.
   * @param notary Notary address.
   * @param wasAudited Indicates whether the data was audited or not.
   * @param isDataValid Indicates the result of the audit, if happened.
   * @param notarySignature Off-chain Notary signature.
   * @return true if `notarySignature` is valid, false otherwise.
   */
  function isNotaryVeredictValid(
    address order,
    address seller,
    address notary,
    bool wasAudited,
    bool isDataValid,
    bytes notarySignature
  ) public pure returns (bool) {
    require(order != address(0));
    require(seller != address(0));
    require(notary != address(0));
    bytes32 hash = keccak256(
      abi.encodePacked(
        order,
        seller,
        wasAudited,
        isDataValid
      )
    );

    return isSignedBy(hash, notary, notarySignature);
  }
}



/**
 * @title DataExchange
 * @author Wibson Development Team <<span class="__cf_email__" data-cfemail="96f2f3e0f3faf9e6f3e4e5d6e1fff4e5f9f8b8f9e4f1">[email&#160;protected]</span>>
 * @notice `DataExchange` is the core contract of the Wibson Protocol.
 *         This allows the creation, management, and tracking of DataOrders.
 * @dev This contract also contains some helper methods to access the data
 *      needed by the different parties involved in the Protocol.
 */
contract DataExchange is TokenDestructible, Pausable {
  using SafeMath for uint256;
  using MultiMap for MultiMap.MapStorage;

  event NotaryRegistered(address indexed notary);
  event NotaryUpdated(address indexed notary);
  event NotaryUnregistered(address indexed notary);

  event NewOrder(address indexed orderAddr);
  event NotaryAddedToOrder(address indexed orderAddr, address indexed notary);
  event DataAdded(address indexed orderAddr, address indexed seller);
  event TransactionCompleted(address indexed orderAddr, address indexed seller);
  event RefundedToBuyer(address indexed orderAddr, address indexed buyer);
  event OrderClosed(address indexed orderAddr);

  struct NotaryInfo {
    address addr;
    string name;
    string notaryUrl;
    string publicKey;
  }

  MultiMap.MapStorage openOrders;
  MultiMap.MapStorage allowedNotaries;

  mapping(address => address[]) public ordersBySeller;
  mapping(address => address[]) public ordersByNotary;
  mapping(address => address[]) public ordersByBuyer;
  mapping(address => NotaryInfo) internal notaryInfo;
  // Tracks the orders created by this contract.
  mapping(address => bool) private orders;

  // @dev buyerBalance Keeps track of the buyer&#39;s balance per order-seller.
  // TODO: Is there a better way to do this?
  mapping(
    address => mapping(address => mapping(address => uint256))
  ) public buyerBalance;

  // @dev buyerRemainingBudgetForAudits Keeps track of the buyer&#39;s remaining
  // budget from the initial one set on the `DataOrder`
  mapping(address => mapping(address => uint256)) public buyerRemainingBudgetForAudits;

  modifier validAddress(address addr) {
    require(addr != address(0));
    require(addr != address(this));
    _;
  }

  modifier isOrderLegit(address order) {
    require(orders[order]);
    _;
  }

  // @dev token A WIBToken implementation of an ERC20 standard token.
  WIBToken token;

  // @dev The minimum for initial budget for audits per `DataOrder`.
  uint256 public minimumInitialBudgetForAudits;

  /**
   * @notice Contract constructor.
   * @param tokenAddress Address of the WIBToken token address.
   * @param ownerAddress Address of the DataExchange owner.
   */
  constructor(
    address tokenAddress,
    address ownerAddress
  ) public validAddress(tokenAddress) validAddress(ownerAddress) {
    require(tokenAddress != ownerAddress);

    token = WIBToken(tokenAddress);
    minimumInitialBudgetForAudits = 0;
    transferOwnership(ownerAddress);
  }

  /**
   * @notice Registers a new notary or replaces an already existing one.
   * @dev At least one notary is needed to enable `DataExchange` operation.
   * @param notary Address of a Notary to add.
   * @param name Name Of the Notary.
   * @param notaryUrl Public URL of the notary where the data must be sent.
   * @param publicKey PublicKey used by the Notary.
   * @return true if the notary was successfully registered, reverts otherwise.
   */
  function registerNotary(
    address notary,
    string name,
    string notaryUrl,
    string publicKey
  ) public onlyOwner whenNotPaused validAddress(notary) returns (bool) {
    bool isNew = notaryInfo[notary].addr == address(0);

    require(allowedNotaries.insert(notary));
    notaryInfo[notary] = NotaryInfo(
      notary,
      name,
      notaryUrl,
      publicKey
    );

    if (isNew) {
      emit NotaryRegistered(notary);
    } else {
      emit NotaryUpdated(notary);
    }
    return true;
  }

  /**
   * @notice Unregisters an existing notary.
   * @param notary Address of a Notary to unregister.
   * @return true if the notary was successfully unregistered, reverts otherwise.
   */
  function unregisterNotary(
    address notary
  ) public onlyOwner whenNotPaused validAddress(notary) returns (bool) {
    require(allowedNotaries.remove(notary));

    emit NotaryUnregistered(notary);
    return true;
  }

  /**
   * @notice Sets the minimum initial budget for audits to be placed by a buyer
   * on DataOrder creation.
   * @dev The initial budget for audit is used as a preventive method to reduce
   *      spam DataOrders in the network.
   * @param _minimumInitialBudgetForAudits The new minimum for initial budget for
   * audits per DataOrder.
   * @return true if the value was successfully set, reverts otherwise.
   */
  function setMinimumInitialBudgetForAudits(
    uint256 _minimumInitialBudgetForAudits
  ) public onlyOwner whenNotPaused returns (bool) {
    minimumInitialBudgetForAudits = _minimumInitialBudgetForAudits;
    return true;
  }

  /**
   * @notice Creates a new DataOrder.
   * @dev The `msg.sender` will become the buyer of the order.
   * @param filters Target audience of the order.
   * @param dataRequest Requested data type (Geolocation, Facebook, etc).
   * @param price Price per added Data Response.
   * @param initialBudgetForAudits The initial budget set for future audits.
   * @param termsAndConditions Buyer&#39;s terms and conditions for the order.
   * @param buyerURL Public URL of the buyer where the data must be sent.
   * @param publicKey Public Key of the buyer, which will be used to encrypt the
   *        data to be sent.
   * @return The address of the newly created DataOrder. If the DataOrder could
   *         not be created, reverts.
   */
  function newOrder(
    string filters,
    string dataRequest,
    uint256 price,
    uint256 initialBudgetForAudits,
    string termsAndConditions,
    string buyerURL,
    string publicKey
  ) public whenNotPaused returns (address) {
    require(initialBudgetForAudits >= minimumInitialBudgetForAudits);
    require(token.allowance(msg.sender, this) >= initialBudgetForAudits);

    address newOrderAddr = new DataOrder(
      msg.sender,
      filters,
      dataRequest,
      price,
      termsAndConditions,
      buyerURL,
      publicKey
    );

    token.transferFrom(msg.sender, this, initialBudgetForAudits);
    buyerRemainingBudgetForAudits[msg.sender][newOrderAddr] = initialBudgetForAudits;

    ordersByBuyer[msg.sender].push(newOrderAddr);
    orders[newOrderAddr] = true;

    emit NewOrder(newOrderAddr);
    return newOrderAddr;
  }

  /**
   * @notice Adds a notary to the Data Order.
   * @dev The `msg.sender` must be the buyer.
   * @param orderAddr Order Address to accept notarize.
   * @param notary Notary address.
   * @param responsesPercentage Percentage of `DataResponses` to audit per DataOrder.
   *        Value must be between 0 and 100.
   * @param notarizationFee Fee to be charged per validation done.
   * @param notarizationTermsOfService Notary&#39;s terms and conditions for the order.
   * @param notarySignature Notary&#39;s signature over the other arguments.
   * @return true if the Notary was added successfully, reverts otherwise.
   */
  function addNotaryToOrder(
    address orderAddr,
    address notary,
    uint256 responsesPercentage,
    uint256 notarizationFee,
    string notarizationTermsOfService,
    bytes notarySignature
  ) public whenNotPaused isOrderLegit(orderAddr) validAddress(notary) returns (bool) {
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(msg.sender == buyer);

    require(!order.hasNotaryBeenAdded(notary));
    require(allowedNotaries.exist(notary));

    require(
      CryptoUtils.isNotaryAdditionValid(
        orderAddr,
        notary,
        responsesPercentage,
        notarizationFee,
        notarizationTermsOfService,
        notarySignature
      )
    );

    bool okay = order.addNotary(
      notary,
      responsesPercentage,
      notarizationFee,
      notarizationTermsOfService
    );

    if (okay) {
      openOrders.insert(orderAddr);
      ordersByNotary[notary].push(orderAddr);
      emit NotaryAddedToOrder(order, notary);
    }
    return okay;
  }

  /**
   * @notice Adds a new DataResponse to the given order.
   * @dev 1. The `msg.sender` must be the buyer of the order.
   *      2. The buyer must allow the DataExchange to withdraw the price of the
   *         order.
   * @param orderAddr Order address where the DataResponse must be added.
   * @param seller Address of the Seller.
   * @param notary Notary address that the Seller chose to use as notarizer,
   *        this must be one within the allowed notaries and within the
   *        DataOrder&#39;s notaries.
   * @param dataHash Hash of the data that must be sent, this is a SHA256.
   * @param signature Signature of DataResponse.
   * @return true if the DataResponse was set successfully, reverts otherwise.
   */
  function addDataResponseToOrder(
    address orderAddr,
    address seller,
    address notary,
    string dataHash,
    bytes signature
  ) public whenNotPaused isOrderLegit(orderAddr) returns (bool) {
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(msg.sender == buyer);
    allDistinct(
      [
        orderAddr,
        buyer,
        seller,
        notary,
        address(this)
      ]
    );
    require(order.hasNotaryBeenAdded(notary));

    require(
      CryptoUtils.isDataResponseValid(
        orderAddr,
        seller,
        notary,
        dataHash,
        signature
      )
    );

    bool okay = order.addDataResponse(
      seller,
      notary,
      dataHash
    );
    require(okay);

    chargeBuyer(order, seller);

    ordersBySeller[seller].push(orderAddr);
    emit DataAdded(order, seller);
    return true;
  }

  /**
   * @notice Closes a DataResponse.
   * @dev Once the buyer receives the seller&#39;s data and checks that it is valid
   *      or not, he must close the DataResponse signaling the result.
   *        1. This method requires an offline signature from the notary set in
   *           the DataResponse, which will indicate the audit result or if
   *           the data was not audited at all.
   *             - If the notary did not audit the data or it verifies that it was
   *               valid, funds will be sent to the Seller.
   *             - If the notary signals the data as invalid, funds will be
   *               handed back to the Buyer.
   *             - Otherwise, funds will be locked at the `DataExchange` contract
   *               until the issue is solved.
   *        2. This also works as a pause mechanism in case the system is
   *           working under abnormal scenarios while allowing the parties to keep
   *           exchanging information without losing their funds until the system
   *           is back up.
   *        3. The `msg.sender` must be the buyer or the notary in case the
   *           former does not show up. Only through the notary&#39;s signature it is
   *           decided who must receive the funds.
   * @param orderAddr Order address where the DataResponse belongs to.
   * @param seller Seller address.
   * @param wasAudited Indicates whether the data was audited or not.
   * @param isDataValid Indicates the result of the audit, if happened.
   * @param notarySignature Off-chain Notary signature
   * @return true if the DataResponse was successfully closed, reverts otherwise.
   */
  function closeDataResponse(
    address orderAddr,
    address seller,
    bool wasAudited,
    bool isDataValid,
    bytes notarySignature
  ) public whenNotPaused isOrderLegit(orderAddr) returns (bool) {
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(order.hasSellerBeenAccepted(seller));

    address notary = order.getNotaryForSeller(seller);
    require(msg.sender == buyer || msg.sender == notary);
    require(
      CryptoUtils.isNotaryVeredictValid(
        orderAddr,
        seller,
        notary,
        wasAudited,
        isDataValid,
        notarySignature
      )
    );
    bool transactionCompleted = !wasAudited || isDataValid;
    require(order.closeDataResponse(seller, transactionCompleted));
    payPlayers(
      order,
      buyer,
      seller,
      notary,
      wasAudited,
      isDataValid
    );

    if (transactionCompleted) {
      emit TransactionCompleted(order, seller);
    } else {
      emit RefundedToBuyer(order, buyer);
    }
    return true;
  }

  /**
   * @notice Closes the DataOrder.
   * @dev Onces the data is closed it will no longer accept new DataResponses.
   *      The `msg.sender` must be the buyer of the order or the owner of the
   *      contract in a emergency case.
   * @param orderAddr Order address to close.
   * @return true if the DataOrder was successfully closed, reverts otherwise.
   */
  function closeOrder(
    address orderAddr
  ) public whenNotPaused isOrderLegit(orderAddr) returns (bool) {
    require(openOrders.exist(orderAddr));
    DataOrder order = DataOrder(orderAddr);
    address buyer = order.buyer();
    require(msg.sender == buyer || msg.sender == owner);

    bool okay = order.close();
    if (okay) {
      // remaining budget for audits go back to buyer.
      uint256 remainingBudget = buyerRemainingBudgetForAudits[buyer][order];
      buyerRemainingBudgetForAudits[buyer][order] = 0;
      require(token.transfer(buyer, remainingBudget));

      openOrders.remove(orderAddr);
      emit OrderClosed(orderAddr);
    }

    return okay;
  }

  /**
   * @notice Gets all the data orders associated with a notary.
   * @param notary Notary address to get orders for.
   * @return A list of DataOrder addresses.
   */
  function getOrdersForNotary(
    address notary
  ) public view validAddress(notary) returns (address[]) {
    return ordersByNotary[notary];
  }

  /**
   * @notice Gets all the data orders associated with a seller.
   * @param seller Seller address to get orders for.
   * @return List of DataOrder addresses.
   */
  function getOrdersForSeller(
    address seller
  ) public view validAddress(seller) returns (address[]) {
    return ordersBySeller[seller];
  }

  /**
   * @notice Gets all the data orders associated with a buyer.
   * @param buyer Buyer address to get orders for.
   * @return List of DataOrder addresses.
   */
  function getOrdersForBuyer(
    address buyer
  ) public view validAddress(buyer) returns (address[]) {
    return ordersByBuyer[buyer];
  }

  /**
   * @notice Gets all the open data orders, that is all the DataOrders that are
   *         still receiving new DataResponses.
   * @return List of DataOrder addresses.
   */
  function getOpenOrders() public view returns (address[]) {
    return openOrders.addresses;
  }

  /**
   * @dev Gets the list of allowed notaries.
   * @return List of notary addresses.
   */
  function getAllowedNotaries() public view returns (address[]) {
    return allowedNotaries.addresses;
  }

  /**
   * @dev Gets information about a give notary.
   * @param notary Notary address to get info for.
   * @return Notary information (address, name, notaryUrl, publicKey, isActive).
   */
  function getNotaryInfo(
    address notary
  ) public view validAddress(notary) returns (address, string, string, string, bool) {
    NotaryInfo memory info = notaryInfo[notary];

    return (
      info.addr,
      info.name,
      info.notaryUrl,
      info.publicKey,
      allowedNotaries.exist(notary)
    );
  }

  /**
   * @dev Requires that five addresses are distinct between themselves and zero.
   * @param addresses array of five addresses to explore.
   */
  function allDistinct(address[5] addresses) private pure {
    for (uint i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0));
      for (uint j = i + 1; j < addresses.length; j++) { // solium-disable-line zeppelin/no-arithmetic-operations
        require(addresses[i] != addresses[j]);
      }
    }
  }

  /**
   * @dev Charges a buyer the final charges for a given `DataResponse`.
   * @notice 1. Tokens are held in the DataExchange contract until players are paid.
   *         2. This function follows a basic invoice flow:
   *
   *               DataOrder price
   *            + Notarization fee
   *            ------------------
   *                 Total charges
   *            -  Prepaid charges (Minimum between Notarization fee and Buyer remaining budget)
   *            ------------------
   *                 Final charges
   *
   * @param order DataOrder to which the DataResponse applies.
   * @param seller Address of the Seller.
   */
  function chargeBuyer(DataOrder order, address seller) private whenNotPaused {
    address buyer = order.buyer();
    address notary = order.getNotaryForSeller(seller);
    uint256 remainingBudget = buyerRemainingBudgetForAudits[buyer][order];

    uint256 orderPrice = order.price();
    (,, uint256 notarizationFee,,) = order.getNotaryInfo(notary);
    uint256 totalCharges = orderPrice.add(notarizationFee);

    uint256 prePaid = Math.min256(notarizationFee, remainingBudget);
    uint256 finalCharges = totalCharges.sub(prePaid);

    buyerRemainingBudgetForAudits[buyer][order] = remainingBudget.sub(prePaid);
    require(token.transferFrom(buyer, this, finalCharges));

    // Bookkeeping of the available tokens paid by the Buyer and now in control
    // of the DataExchange takes into account the total charges (final + pre-paid)
    buyerBalance[buyer][order][seller] = buyerBalance[buyer][order][seller].add(totalCharges);
  }

  /**
   * @dev Pays the seller, notary and/or buyer according to the notary&#39;s veredict.
   * @param order DataOrder to which the payments apply.
   * @param buyer Address of the Buyer.
   * @param seller Address of the Seller.
   * @param notary Address of the Notary.
   * @param wasAudited Indicates whether the data was audited or not.
   * @param isDataValid Indicates the result of the audit, if happened.
   */
  function payPlayers(
    DataOrder order,
    address buyer,
    address seller,
    address notary,
    bool wasAudited,
    bool isDataValid
  ) private whenNotPaused {
    uint256 orderPrice = order.price();
    (,, uint256 notarizationFee,,) = order.getNotaryInfo(notary);
    uint256 totalCharges = orderPrice.add(notarizationFee);

    require(buyerBalance[buyer][order][seller] >= totalCharges);
    buyerBalance[buyer][order][seller] = buyerBalance[buyer][order][seller].sub(totalCharges);

    // if no notarization was done, notarization fee tokens go back to buyer.
    address notarizationFeeReceiver = wasAudited ? notary : buyer;

    // if no notarization was done or data is valid, tokens go to the seller
    address orderPriceReceiver = (!wasAudited || isDataValid) ? seller : buyer;

    require(token.transfer(notarizationFeeReceiver, notarizationFee));
    require(token.transfer(orderPriceReceiver, orderPrice));
  }

}