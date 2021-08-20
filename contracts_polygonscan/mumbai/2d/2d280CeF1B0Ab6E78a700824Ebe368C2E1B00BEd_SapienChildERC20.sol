/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

pragma solidity ^0.5.2;


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ChainIdMixin {
  bytes constant public networkId = abi.encodePacked("80001");
  uint256 constant public CHAINID = 80001;
}

contract LibEIP712Domain is ChainIdMixin {
  string constant internal EIP712_DOMAIN_SCHEMA = "EIP712Domain(string name,string version,uint256 chainId,address contract)";
  bytes32 constant public EIP712_DOMAIN_SCHEMA_HASH = keccak256(abi.encodePacked(EIP712_DOMAIN_SCHEMA));

  string constant internal EIP712_DOMAIN_NAME = "Matic Network";
  string constant internal EIP712_DOMAIN_VERSION = "1";
  uint256 constant internal EIP712_DOMAIN_CHAINID = CHAINID;

  bytes32 public EIP712_DOMAIN_HASH;

  constructor () public {
    EIP712_DOMAIN_HASH = keccak256(abi.encode(
      EIP712_DOMAIN_SCHEMA_HASH,
      keccak256(bytes(EIP712_DOMAIN_NAME)),
      keccak256(bytes(EIP712_DOMAIN_VERSION)),
      EIP712_DOMAIN_CHAINID,
      address(this)
    ));
  }

  function hashEIP712Message(bytes32 hashStruct) internal view returns (bytes32 result) {
    bytes32 domainHash = EIP712_DOMAIN_HASH;

    // Assembly for more efficient computing:
    // keccak256(abi.encode(
    //     EIP191_HEADER,
    //     domainHash,
    //     hashStruct
    // ));

    assembly {
      // Load free memory pointer
      let memPtr := mload(64)

      mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
      mstore(add(memPtr, 2), domainHash)                                          // EIP712 domain hash
      mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

      // Compute hash
      result := keccak256(memPtr, 66)
    }
    return result;
  }
}

contract LibTokenTransferOrder is LibEIP712Domain {
  string constant internal EIP712_TOKEN_TRANSFER_ORDER_SCHEMA = "TokenTransferOrder(address spender,uint256 tokenIdOrAmount,bytes32 data,uint256 expiration)";
  bytes32 constant public EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(EIP712_TOKEN_TRANSFER_ORDER_SCHEMA));

  struct TokenTransferOrder {
    address spender;
    uint256 tokenIdOrAmount;
    bytes32 data;
    uint256 expiration;
  }

  function getTokenTransferOrderHash(address spender, uint256 tokenIdOrAmount, bytes32 data, uint256 expiration)
    public
    view
    returns (bytes32 orderHash)
  {
    orderHash = hashEIP712Message(hashTokenTransferOrder(spender, tokenIdOrAmount, data, expiration));
  }

  function hashTokenTransferOrder(address spender, uint256 tokenIdOrAmount, bytes32 data, uint256 expiration)
    internal
    pure
    returns (bytes32 result)
  {
    bytes32 schemaHash = EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH;

    // Assembly for more efficiently computing:
    // return keccak256(abi.encode(
    //   schemaHash,
    //   spender,
    //   tokenIdOrAmount,
    //   data,
    //   expiration
    // ));

    assembly {
      // Load free memory pointer
      let memPtr := mload(64)

      mstore(memPtr, schemaHash)                                                         // hash of schema
      mstore(add(memPtr, 32), and(spender, 0xffffffffffffffffffffffffffffffffffffffff))  // spender
      mstore(add(memPtr, 64), tokenIdOrAmount)                                           // tokenIdOrAmount
      mstore(add(memPtr, 96), data)                                                      // hash of data
      mstore(add(memPtr, 128), expiration)                                               // expiration

      // Compute hash
      result := keccak256(memPtr, 160)
    }
    return result;
  }
}

contract ChildToken is Ownable, LibTokenTransferOrder {
  using SafeMath for uint256;

  // ERC721/ERC20 contract token address on root chain
  address public token;
  address public parent;
  address public parentOwner;

  mapping(bytes32 => bool) public disabledHashes;

  modifier isParentOwner() {
    require(msg.sender == parentOwner);
    _;
  }

  function deposit(address user, uint256 amountOrTokenId) public;
  function withdraw(uint256 amountOrTokenId) public payable;
  function setParent(address _parent) public;

  event LogFeeTransfer(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 input1,
    uint256 input2,
    uint256 output1,
    uint256 output2
  );

  function ecrecovery(
    bytes32 hash,
    bytes memory sig
  ) public pure returns (address result) {
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (sig.length != 65) {
      return address(0x0);
    }
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := and(mload(add(sig, 65)), 255)
    }
    // https://github.com/ethereum/go-ethereum/issues/2053
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return address(0x0);
    }
    // get address out of hash and signature
    result = ecrecover(hash, v, r, s);
    // ecrecover returns zero on error
    require(result != address(0x0), "Error in ecrecover");
  }
}

contract BaseERC20 is ChildToken {

  event Deposit(
    address indexed token,
    address indexed from,
    uint256 amount,
    uint256 input1,
    uint256 output1
  );

  event Withdraw(
    address indexed token,
    address indexed from,
    uint256 amount,
    uint256 input1,
    uint256 output1
  );

  event LogTransfer(
    address indexed token,
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 input1,
    uint256 input2,
    uint256 output1,
    uint256 output2
  );

  constructor() public {}

  function transferWithSig(bytes calldata sig, uint256 amount, bytes32 data, uint256 expiration, address to) external returns (address from) {
    require(amount > 0);
    require(expiration == 0 || block.number <= expiration, "Signature is expired");

    bytes32 dataHash = getTokenTransferOrderHash(
      msg.sender,
      amount,
      data,
      expiration
    );
    require(disabledHashes[dataHash] == false, "Sig deactivated");
    disabledHashes[dataHash] = true;

    from = ecrecovery(dataHash, sig);
    _transferFrom(from, address(uint160(to)), amount);
  }

  function balanceOf(address account) external view returns (uint256);
  function _transfer(address sender, address recipient, uint256 amount) internal;

  /// @param from Address from where tokens are withdrawn.
  /// @param to Address to where tokens are sent.
  /// @param value Number of tokens to transfer.
  /// @return Returns success of function call.
  function _transferFrom(address from, address to, uint256 value) internal returns (bool) {
    uint256 input1 = this.balanceOf(from);
    uint256 input2 = this.balanceOf(to);
    _transfer(from, to, value);
    emit LogTransfer(
      token,
      from,
      to,
      value,
      input1,
      input2,
      this.balanceOf(from),
      this.balanceOf(to)
    );
    return true;
  }
}

//interface for parent contract of any child token
interface IParentToken {
  function beforeTransfer(address sender, address to, uint256 value) external returns(bool);
}

contract ChildERC20 is BaseERC20, ERC20, ERC20Detailed {

  constructor (address _owner, address _token, string memory _name, string memory _symbol, uint8 _decimals)
    public
    ERC20Detailed(_name, _symbol, _decimals) {
    require(_token != address(0x0) && _owner != address(0x0));
    parentOwner = _owner;
    token = _token;
  }

  function setParent(address _parent) public isParentOwner {
    require(_parent != address(0x0));
    parent = _parent;
  }

  /**
   * Deposit tokens
   *
   * @param user address for address
   * @param amount token balance
   */
  function deposit(address user, uint256 amount) public onlyOwner {
    // check for amount and user
    require(amount > 0 && user != address(0x0));

    // input balance
    uint256 input1 = balanceOf(user);

    // increase balance
    _mint(user, amount);

    // deposit events
    emit Deposit(token, user, amount, input1, balanceOf(user));
  }

  /**
   * Withdraw tokens
   *
   * @param amount tokens
   */
  function withdraw(uint256 amount) public payable {
    address user = msg.sender;
    // input balance
    uint256 input = balanceOf(user);

    // check for amount
    require(amount > 0 && input >= amount);

    // decrease balance
    _burn(user, amount);

    // withdraw event
    emit Withdraw(token, user, amount, input, balanceOf(user));
  }

  /// @dev Function that is called when a user or another contract wants to transfer funds.
  /// @param to Address of token receiver.
  /// @param value Number of tokens to transfer.
  /// @return Returns success of function call.
  function transfer(address to, uint256 value) public returns (bool) {
    if (parent != address(0x0) && !IParentToken(parent).beforeTransfer(msg.sender, to, value)) {
      return false;
    }
    return _transferFrom(msg.sender, to, value);
  }

  function allowance(address, address) public view returns (uint256) {
    revert("Disabled feature");
  }

  function approve(address, uint256) public returns (bool) {
    revert("Disabled feature");
  }

  function transferFrom(address, address, uint256 ) public returns (bool){
    revert("Disabled feature");
  }
}

interface ISapienParentToken {
  function beforeTransfer(address sender, address to, uint256 value, bytes calldata purpose) external returns(bool);
}

contract SapienChildERC20 is ChildERC20 {

  constructor (address _owner, address _token, string memory _name, string memory _symbol, uint8 _decimals)
    public
    ChildERC20(_owner, _token, _name, _symbol, _decimals) {}

  /// @dev Function that is called when a user or another contract wants to transfer funds.
  /// @param to Address of token receiver.
  /// @param value Number of tokens to transfer.
  /// @return Returns success of function call.
  function transfer(address to, uint256 value) public returns (bool) {
    return transferWithPurpose(to, value, hex"");
  }

  /// @dev Function that is called when a user or another contract wants to transfer funds, including a purpose.
  /// @param to Address of token receiver.
  /// @param value Number of tokens to transfer.
  /// @param purpose Arbitrary data attached to the transaction.
  /// @return Returns success of function call.
  function transferWithPurpose(address to, uint256 value, bytes memory purpose) public returns (bool) {
    if (parent != address(0x0) && !ISapienParentToken(parent).beforeTransfer(msg.sender, to, value, purpose)) {
      return false;
    }
    return _transferFrom(msg.sender, to, value);
  }

  /// @dev Transfer to many addresses in a single transaction.
  /// @dev Call transfer(to, amount) with the arguments taken from two arrays.
  /// @dev If one transfer is invalid, everything is aborted.
  /// @dev The `expectZero` option is intended for the initial batch minting.
  ///      It allows operations to be retried and prevents double-minting due to the
  ///      asynchronous and uncertain nature of blockchain transactions.
  ///      It should be avoided after trading has started.
  /// @param toArray Addresses that will receive tokens.
  /// @param amountArray Amounts of tokens to transfer, in the same order as `toArray`.
  /// @param expectZero If false, transfer the tokens immediately.
  ///                    If true, expect the current balance of `to` to be zero before
  ///                    the transfer. If not zero, skip this transfer but continue.
  function transferBatchIdempotent(address[] memory toArray, uint256[] memory amountArray, bool expectZero) public {
    // Check that the arrays are the same size
    uint256 _count = toArray.length;
    require(amountArray.length == _count, "Array length mismatch");

    for (uint256 i = 0; i < _count; i++) {
      address to = toArray[i];
      // Either regular transfer, or check that BasicToken.balances is zero.
      if (!expectZero || (balanceOf(to) == 0)) {
        transfer(to, amountArray[i]);
      }
    }
  }
}