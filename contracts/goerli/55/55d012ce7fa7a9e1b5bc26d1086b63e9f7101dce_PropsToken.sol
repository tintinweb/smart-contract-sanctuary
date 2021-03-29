/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: 
// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.4.24;




/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
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
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-eth/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is Initializable, IERC20 {
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
  * @param owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
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
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
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
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {    
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
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
    require(value <= _balances[from]);
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
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
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
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {    
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }

  uint256[50] private ______gap;
}

// File: contracts/token/PropsTimeBasedTransfers.sol

pragma solidity ^0.4.24;
/*
 THIS CONTRACT IS OBSOLETE AND REMAINS ONLY FOR UPGRADABILITY/STORAGE CONSIDERATIONS
*/



/**
 * @title Props Time Based Transfers
 * @dev Contract allows to set a transfer start time (unix timestamp) from which transfers are allowed excluding one address defined in initialize
 **/
contract PropsTimeBasedTransfers is Initializable, ERC20 {
    uint256 public transfersStartTime;
    address public canTransferBeforeStartTime;
    /**
    Contract logic is no longer relevant.
    Leaving in the variables used for upgrade compatibility but the checks are no longer required
    */

    // modifier canTransfer(address _account)
    // {
    //     require(
    //         now > transfersStartTime ||
    //         _account==canTransferBeforeStartTime,
    //         "Cannot transfer before transfers start time from this account"
    //     );
    //     _;
    // }

    // /**
    // * @dev The initializer function, with transfers start time `transfersStartTime` (unix timestamp)
    // * and `canTransferBeforeStartTime` address which is exempt from start time restrictions
    // * @param start uint Unix timestamp of when transfers can start
    // * @param account uint256 address exempt from the start date check
    // */
    // function initialize(
    //     uint256 start,
    //     address account
    // )
    //     public
    //     initializer
    // {
    //     transfersStartTime = start;
    //     canTransferBeforeStartTime = account;
    // }
    // /**
    // * @dev Transfer token for a specified address if allowed
    // * @param to The address to transfer to.
    // * @param value The amount to be transferred.
    // */
    // function transfer(
    //     address to,
    //     uint256 value
    // )
    // public canTransfer(msg.sender)
    // returns (bool)
    // {
    //     return super.transfer(to, value);
    // }

    // /**
    //  * @dev Transfer tokens from one address to another if allowed
    //  * Note that while this function emits an Approval event, this is not required as per the specification,
    //  * and other compliant implementations may not emit the event.
    //  * @param from address The address which you want to send tokens from
    //  * @param to address The address which you want to transfer to
    //  * @param value uint256 the amount of tokens to be transferred
    //  */
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 value
    // )
    // public canTransfer(from)
    // returns (bool)
    // {
    //     return super.transferFrom(from, to, value);
    // }
}

// File: openzeppelin-eth/contracts/cryptography/ECDSA.sol

pragma solidity ^0.4.24;


/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
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

// File: contracts/token/IERC865.sol

pragma solidity ^0.4.24;

/*
 THIS CONTRACT IS OBSOLETE AND REMAINS ONLY FOR UPGRADABILITY/STORAGE CONSIDERATIONS
*/
/**
 * @title ERC865 Interface
 * @dev see https://github.com/ethereum/EIPs/issues/865
 *
 */

contract IERC865 {
    // event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    // event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    // function transferPreSigned(
    //     bytes _signature,
    //     address _to,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool);
    // function approvePreSigned(
    //     bytes _signature,
    //     address _spender,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool);
    // function increaseAllowancePreSigned(
    //     bytes _signature,
    //     address _spender,
    //     uint256 _addedValue,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool);
    // function decreaseAllowancePreSigned(
    //     bytes _signature,
    //     address _spender,
    //     uint256 _subtractedValue,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool);
    // function transferFromPreSigned(
    //     bytes _signature,
    //     address _from,
    //     address _to,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool);
}

// File: contracts/token/ERC865Token.sol

pragma solidity ^0.4.24;
/*
 THIS CONTRACT IS OBSOLETE AND REMAINS ONLY FOR UPGRADABILITY/STORAGE CONSIDERATIONS
*/





/**
 * @title ERC865Token Token
 *
 * ERC865Token allows users paying transfers in tokens instead of gas
 * https://github.com/ethereum/EIPs/issues/865
 *
 */

contract ERC865Token is Initializable, ERC20, IERC865 {
    /* hashed tx of transfers performed */
    mapping(bytes32 => bool) hashedTxs;
    // /**
    //  * @dev Submit a presigned transfer
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _signature bytes The signature, issued by the owner.
    //  * @param _to address The address which you want to transfer to.
    //  * @param _value uint256 The amount of tokens to be transferred.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function transferPreSigned(
    //     bytes _signature,
    //     address _to,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool)
    // {
    //     require(_to != address(0), "Invalid _to address");

    //     bytes32 hashedParams = getTransferPreSignedHash(address(this), _to, _value, _fee, _nonce);
    //     address from = ECDSA.recover(hashedParams, _signature);
    //     require(from != address(0), "Invalid from address recovered");
    //     bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
    //     require(hashedTxs[hashedTx] == false,"Transaction hash was already used");
    //     hashedTxs[hashedTx] = true;
    //     _transfer(from, _to, _value);
    //     _transfer(from, msg.sender, _fee);

    //     emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
    //     return true;
    // }

    // /**
    //  * @dev Submit a presigned approval
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _signature bytes The signature, issued by the owner.
    //  * @param _spender address The address which will spend the funds.
    //  * @param _value uint256 The amount of tokens to allow.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function approvePreSigned(
    //     bytes _signature,
    //     address _spender,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool)
    // {
    //     require(_spender != address(0),"Invalid _spender address");

    //     bytes32 hashedParams = getApprovePreSignedHash(address(this), _spender, _value, _fee, _nonce);
    //     address from = ECDSA.recover(hashedParams, _signature);
    //     require(from != address(0),"Invalid from address recovered");
    //     bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
    //     require(hashedTxs[hashedTx] == false,"Transaction hash was already used");
    //     hashedTxs[hashedTx] = true;
    //     _approve(from, _spender, _value);
    //     _transfer(from, msg.sender, _fee);

    //     emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
    //     return true;
    // }

    // /**
    //  * @dev Increase the amount of tokens that an owner allowed to a spender.
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _signature bytes The signature, issued by the owner.
    //  * @param _spender address The address which will spend the funds.
    //  * @param _addedValue uint256 The amount of tokens to increase the allowance by.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function increaseAllowancePreSigned(
    //     bytes _signature,
    //     address _spender,
    //     uint256 _addedValue,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool)
    // {
    //     require(_spender != address(0),"Invalid _spender address");

    //     bytes32 hashedParams = getIncreaseAllowancePreSignedHash(address(this), _spender, _addedValue, _fee, _nonce);
    //     address from = ECDSA.recover(hashedParams, _signature);
    //     require(from != address(0),"Invalid from address recovered");
    //     bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
    //     require(hashedTxs[hashedTx] == false,"Transaction hash was already used");
    //     hashedTxs[hashedTx] = true;
    //     _approve(from, _spender, allowance(from, _spender).add(_addedValue));
    //     _transfer(from, msg.sender, _fee);

    //     emit ApprovalPreSigned(from, _spender, msg.sender, allowance(from, _spender), _fee);
    //     return true;
    // }

    // /**
    //  * @dev Decrease the amount of tokens that an owner allowed to a spender.
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _signature bytes The signature, issued by the owner
    //  * @param _spender address The address which will spend the funds.
    //  * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function decreaseAllowancePreSigned(
    //     bytes _signature,
    //     address _spender,
    //     uint256 _subtractedValue,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool)
    // {
    //     require(_spender != address(0),"Invalid _spender address");

    //     bytes32 hashedParams = getDecreaseAllowancePreSignedHash(address(this), _spender, _subtractedValue, _fee, _nonce);
    //     address from = ECDSA.recover(hashedParams, _signature);
    //     require(from != address(0),"Invalid from address recovered");
    //     bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
    //     require(hashedTxs[hashedTx] == false,"Transaction hash was already used");
    //     // if substractedValue is greater than allowance will fail as allowance is uint256
    //     hashedTxs[hashedTx] = true;
    //     _approve(from, _spender, allowance(from,_spender).sub(_subtractedValue));
    //     _transfer(from, msg.sender, _fee);

    //     emit ApprovalPreSigned(from, _spender, msg.sender, allowance(from, _spender), _fee);
    //     return true;
    // }

    // /**
    //  * @dev Transfer tokens from one address to another
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _signature bytes The signature, issued by the spender.
    //  * @param _from address The address which you want to send tokens from.
    //  * @param _to address The address which you want to transfer to.
    //  * @param _value uint256 The amount of tokens to be transferred.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function transferFromPreSigned(
    //     bytes _signature,
    //     address _from,
    //     address _to,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     returns (bool)
    // {
    //     require(_to != address(0),"Invalid _to address");

    //     bytes32 hashedParams = getTransferFromPreSignedHash(address(this), _from, _to, _value, _fee, _nonce);

    //     address spender = ECDSA.recover(hashedParams, _signature);
    //     require(spender != address(0),"Invalid spender address recovered");
    //     bytes32 hashedTx = keccak256(abi.encodePacked(spender, hashedParams));
    //     require(hashedTxs[hashedTx] == false,"Transaction hash was already used");
    //     hashedTxs[hashedTx] = true;
    //     _transfer(_from, _to, _value);
    //     _approve(_from, spender, allowance(_from, spender).sub(_value));
    //     _transfer(spender, msg.sender, _fee);

    //     emit TransferPreSigned(_from, _to, msg.sender, _value, _fee);
    //     return true;
    // }

    // /**
    //  * @dev Hash (keccak256) of the payload used by transferPreSigned
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _token address The address of the token.
    //  * @param _to address The address which you want to transfer to.
    //  * @param _value uint256 The amount of tokens to be transferred.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function getTransferPreSignedHash(
    //     address _token,
    //     address _to,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     /* "0d98dcb1": getTransferPreSignedHash(address,address,uint256,uint256,uint256) */
    //     return keccak256(abi.encodePacked(bytes4(0x0d98dcb1), _token, _to, _value, _fee, _nonce));
    // }

    // /**
    //  * @dev Hash (keccak256) of the payload used by approvePreSigned
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _token address The address of the token
    //  * @param _spender address The address which will spend the funds.
    //  * @param _value uint256 The amount of tokens to allow.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function getApprovePreSignedHash(
    //     address _token,
    //     address _spender,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     /* "79250dcf": getApprovePreSignedHash(address,address,uint256,uint256,uint256) */
    //     return keccak256(abi.encodePacked(bytes4(0x79250dcf), _token, _spender, _value, _fee, _nonce));
    // }

    // /**
    //  * @dev Hash (keccak256) of the payload used by increaseAllowancePreSigned
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _token address The address of the token
    //  * @param _spender address The address which will spend the funds.
    //  * @param _addedValue uint256 The amount of tokens to increase the allowance by.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function getIncreaseAllowancePreSignedHash(
    //     address _token,
    //     address _spender,
    //     uint256 _addedValue,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     /* "138e8da1": getIncreaseAllowancePreSignedHash(address,address,uint256,uint256,uint256) */
    //     return keccak256(abi.encodePacked(bytes4(0x138e8da1), _token, _spender, _addedValue, _fee, _nonce));
    // }

    //  /**
    //   * @dev Hash (keccak256) of the payload used by decreaseAllowancePreSigned
    //   * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //   * @param _token address The address of the token
    //   * @param _spender address The address which will spend the funds.
    //   * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
    //   * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    //   * @param _nonce uint256 Presigned transaction number.
    //   */
    // function getDecreaseAllowancePreSignedHash(
    //     address _token,
    //     address _spender,
    //     uint256 _subtractedValue,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     /* "5229c56f": getDecreaseAllowancePreSignedHash(address,address,uint256,uint256,uint256) */
    //     return keccak256(abi.encodePacked(bytes4(0x5229c56f), _token, _spender, _subtractedValue, _fee, _nonce));
    // }

    // /**
    //  * @dev Hash (keccak256) of the payload used by transferFromPreSigned
    //  * @notice fee will be given to sender if it's a smart contract make sure it can accept funds
    //  * @param _token address The address of the token
    //  * @param _from address The address which you want to send tokens from.
    //  * @param _to address The address which you want to transfer to.
    //  * @param _value uint256 The amount of tokens to be transferred.
    //  * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
    //  * @param _nonce uint256 Presigned transaction number.
    //  */
    // function getTransferFromPreSignedHash(
    //     address _token,
    //     address _from,
    //     address _to,
    //     uint256 _value,
    //     uint256 _fee,
    //     uint256 _nonce
    // )
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     /* "a70c41b4": getTransferFromPreSignedHash(address,address,address,uint256,uint256,uint256) */
    //     return keccak256(abi.encodePacked(bytes4(0xa70c41b4), _token, _from, _to, _value, _fee, _nonce));
    // }
}

// File: openzeppelin-eth/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.4.24;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}

// File: contracts/token/PropsRewardsLib.sol

pragma solidity ^0.4.24;
/*
 THIS CONTRACT IS OBSOLETE AND REMAINS ONLY FOR UPGRADABILITY/STORAGE CONSIDERATIONS
*/


/**
 * @title Props Rewards Library
 * @dev Library to manage application and validators and parameters
 **/
library PropsRewardsLib {
    using SafeMath for uint256;
    /*
     *  Events
     */

    /*
     *  Storage
     */

    // The various parameters used by the contract
    enum ParameterName {
        ApplicationRewardsPercent,
        ApplicationRewardsMaxVariationPercent,
        ValidatorMajorityPercent,
        ValidatorRewardsPercent
    }
    enum RewardedEntityType {Application, Validator}

    // Represents a parameter current, previous and time of change
    struct Parameter {
        uint256 currentValue; // current value in Pphm valid after timestamp
        uint256 previousValue; // previous value in Pphm for use before timestamp
        uint256 rewardsDay; // timestamp of when the value was updated
    }
    // Represents application details
    struct RewardedEntity {
        bytes32 name; // Application name
        address rewardsAddress; // address where rewards will be minted to
        address sidechainAddress; // address used on the sidechain
        bool isInitializedState; // A way to check if there's something in the map and whether it is already added to the list
        RewardedEntityType entityType; // Type of rewarded entity
    }

    // Represents validators current and previous lists
    struct RewardedEntityList {
        mapping(address => bool) current;
        mapping(address => bool) previous;
        address[] currentList;
        address[] previousList;
        uint256 rewardsDay;
    }

    // Represents daily rewards submissions and confirmations
    struct DailyRewards {
        mapping(bytes32 => Submission) submissions;
        bytes32[] submittedRewardsHashes;
        uint256 totalSupply;
        bytes32 lastConfirmedRewardsHash;
        uint256 lastApplicationsRewardsDay;
    }

    struct Submission {
        mapping(address => bool) validators;
        address[] validatorsList;
        uint256 confirmations;
        uint256 finalizedStatus; // 0 - initialized, 1 - finalized
        bool isInitializedState; // A way to check if there's something in the map and whether it is already added to the list
    }

    // represent the storage structures
    struct Data {
        // applications data
        mapping(address => RewardedEntity) applications;
        address[] applicationsList;
        // validators data
        mapping(address => RewardedEntity) validators;
        address[] validatorsList;
        // adjustable parameters data
        mapping(uint256 => Parameter) parameters; // uint256 is the parameter enum index
        // the participating validators
        RewardedEntityList selectedValidators;
        // the participating applications
        RewardedEntityList selectedApplications;
        // daily rewards submission data
        DailyRewards dailyRewards;
        uint256 minSecondsBetweenDays;
        uint256 rewardsStartTimestamp;
        uint256 maxTotalSupply;
        uint256 lastValidatorsRewardsDay;
    }
}

// File: contracts/token/PropsRewards.sol

pragma solidity ^0.4.24;






/**
 * @title Props Rewards
 * @dev Contract allows to set approved apps and validators. Submit and mint rewards...
 **/
contract PropsRewards is Initializable, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    /*
     *  Events
     */

    event ControllerUpdated(address indexed newController);

    /*
     *  Storage
     */

    PropsRewardsLib.Data internal rewardsLibData;
    uint256 public maxTotalSupply;
    uint256 public rewardsStartTimestamp;
    address public controller; // controller entity
    mapping(address => bool) public minters;
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;
    uint256 public MY_CHAIN_ID;
    /*
     *  Modifiers
     */
    modifier onlyController() {
        require(msg.sender == controller, "Must be the controller");
        _;
    }

    /**
     * @dev The initializer function for upgrade as initialize was already called, get the decimals used in the token to initialize the params
     * @param _controller address that will have controller functionality on token
     */
    function initialize(address _controller) public {
        uint256 decimals = 18;
        _initialize(_controller, decimals);
    }

    /**
     * @dev Initialize post separation of rewards contract upgrade
     * @param _tokenName string token name
     */
    function initializePermitUpgrade(string memory _tokenName)
        public
        initializer
    {
        uint256 chainId;
        string memory one = "1";
        assembly {
            chainId := chainId
        }

        MY_CHAIN_ID = chainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_tokenName)),
                keccak256(bytes(one)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Allows for approvals to be made via secp256k1 signatures
     * @param _owner address owner
     * @param _spender address spender
     * @param _amount uint spender
     * @param _deadline uint spender
     * @param _v uint8 spender
     * @param _r bytes32 spender
     * @param _s bytes32 spender
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_deadline >= block.timestamp, "Permit Expired");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            _owner,
                            _spender,
                            _amount,
                            nonces[_owner]++,
                            _deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(
            recoveredAddress != address(0) && recoveredAddress == _owner,
            "Invalid Signature"
        );
        _approve(_owner, _spender, _amount);
    }

    /**
     * @dev Reclaim all ERC20 compatible tokens
     * @param _token ERC20 The address of the token contract
     */
    function reclaimToken(
        ERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyController {
        require(_to != address(0), "Must transfer to recipient");
        uint256 balance = _token.balanceOf(this);
        require(_amount <= balance, "Cannot transfer more than balance");
        _token.safeTransfer(_to, _amount);
    }

    /**
     * @dev Allows the controller/owner to update to a new controller
     * @param _controller address address of the new controller
     */
    function updateController(address _controller) public onlyController {
        require(
            _controller != address(0),
            "Controller cannot be the zero address"
        );
        controller = _controller;
        emit ControllerUpdated(_controller);
    }

    function addMinter(address _minter) public onlyController {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyController {
        minters[_minter] = false;
    }

    /**
     * @dev Allows minters to mint tokens to a given address
     * @param _account address of the receiving account
     * @param _amount uint256 how much to mint
     */
    function mint(address _account, uint256 _amount) public {
        require(minters[msg.sender], "Mint fn can be called only by minter");
        require(
            totalSupply().add(_amount) <= maxTotalSupply,
            "Max total supply exceeded"
        );
        _mint(_account, _amount);
    }

    /**
     * @dev internal intialize
     * @param _controller address that will have controller functionality on rewards protocol
     * @param _decimals uint256 number of decimals used in total supply
     */
    function _initialize(address _controller, uint256 _decimals) internal {
        require(
            maxTotalSupply == 0,
            "Initialize rewards upgrade1 can happen only once"
        );
        controller = _controller;
        // max total supply is 1,000,000,000 PROPS specified in AttoPROPS
        maxTotalSupply = 1 * 1e9 * (10**_decimals);
    }
}

// File: contracts/token/PropsToken.sol

pragma solidity ^0.4.24;






/**
 * @title PROPSToken
 * @dev PROPS token contract (based of ZEPToken by openzeppelin), a detailed ERC20 token
 * https://github.com/zeppelinos/zos-vouching/blob/master/contracts/ZEPToken.sol
 * PROPS are divisible by 1e18 base
 * units referred to as 'AttoPROPS'.
 *
 * PROPS are displayed using 18 decimal places of precision.
 *
 * 1 PROPS is equivalent to:
 *   1 * 1e18 == 1e18 == One Quintillion AttoPROPS
 *
 * 600 Million PROPS (total supply) is equivalent to:
 *   600000000 * 1e18 == 6e26 AttoPROPS
 *

 */

contract PropsToken is
    Initializable,
    ERC20Detailed,
    ERC865Token,
    PropsTimeBasedTransfers,
    PropsRewards
{
    /**
     * @dev Initializer function. Called only once when a proxy for the contract is created.
     * @param _holder address that will receive its initial supply and be able to transfer before transfers start time
     * @param _controller address that will have controller functionality on rewards protocol
     */
    function initialize(address _holder, address _controller)
        public
        initializer
    {
        uint8 decimals = 18;
        // total supply is 600,000,000 PROPS specified in AttoPROPS
        uint256 totalSupply = 680000000 * (10**uint256(decimals));

        ERC20Detailed.initialize("Props Token", "PROPS", decimals);
        PropsRewards.initialize(_controller);
        PropsRewards.initializePermitUpgrade("Props Token");
        _mint(_holder, totalSupply);
    }
}