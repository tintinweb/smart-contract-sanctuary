// File: contracts/Owned.sol

pragma solidity 0.6.7;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Sender must be owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: contracts/thirdParty/ECDSA.sol

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
// Line 60 added to original source in accordance with recommendation on accepting signatures with 0/1 for v

pragma solidity ^0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v < 27) v += 27;

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/interfaces/IERC777.sol

pragma solidity 0.6.7;

// As defined in https://eips.ethereum.org/EIPS/eip-777
interface IERC777 {
  event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data,
      bytes operatorData);
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator,address indexed holder);
  event RevokedOperator(address indexed operator, address indexed holder);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function balanceOf(address holder) external view returns (uint256);
  function granularity() external view returns (uint256);
  function defaultOperators() external view returns (address[] memory);
  function isOperatorFor(address operator, address holder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function send(address to, uint256 amount, bytes calldata data) external;
  function operatorSend(address from, address to, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
  function burn(uint256 amount, bytes calldata data) external;
  function operatorBurn( address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.6.7;

// As described in https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory); // optional method - see eip spec
  function symbol() external view returns (string memory); // optional method - see eip spec
  function decimals() external view returns (uint8); // optional method - see eip spec
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts/thirdParty/interfaces/IERC1820Registry.sol

// From open https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/introspection/IERC1820Registry.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: contracts/interfaces/IERC777Sender.sol

pragma solidity 0.6.7;

// As defined in the 'ERC777TokensSender And The tokensToSend Hook' section of https://eips.ethereum.org/EIPS/eip-777
interface IERC777Sender {
  function tokensToSend(address operator, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata operatorData) external;
}

// File: contracts/interfaces/IERC777Recipient.sol

pragma solidity 0.6.7;

// As defined in the 'ERC777TokensRecipient And The tokensReceived Hook' section of https://eips.ethereum.org/EIPS/eip-777
interface IERC777Recipient {
  function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata operatorData) external;
}

// File: contracts/thirdParty/SafeMath.sol

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libraries/LToken.sol

pragma solidity 0.6.7;





struct TokenState {
  uint256 totalSupply;
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) approvals;
  mapping(address => mapping(address => bool)) authorizedOperators;
  address[] defaultOperators;
  mapping(address => bool) defaultOperatorIsRevoked;
  mapping(address => bool) minters;
}

library LToken {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data,
      bytes operatorData);
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed holder);
  event RevokedOperator(address indexed operator, address indexed holder);

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // precalculated hashes - see https://github.com/ethereum/solidity/issues/4024
  // keccak256("ERC777TokensSender")
  bytes32 constant internal ERC777_TOKENS_SENDER_HASH = 0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  modifier checkSenderNotOperator(address _operator) {
    require(_operator != msg.sender, "Cannot be operator for self");
    _;
  }

  function initState(TokenState storage _tokenState, uint8 _decimals, uint256 _initialSupply)
    external
  {
    _tokenState.defaultOperators.push(address(this));
    _tokenState.totalSupply = _initialSupply.mul(10**uint256(_decimals));
    _tokenState.balances[msg.sender] = _tokenState.totalSupply;
  }

  function transferFrom(TokenState storage _tokenState, address _from, address _to, uint256 _value)
    external
  {
    _tokenState.approvals[_from][msg.sender] = _tokenState.approvals[_from][msg.sender].sub(_value, "Amount not approved");
    doSend(_tokenState, msg.sender, _from, _to, _value, "", "", false);
  }

  function approve(TokenState storage _tokenState, address _spender, uint256 _value)
    external
  {
    require(_spender != address(0), "Cannot approve to zero address");
    _tokenState.approvals[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function authorizeOperator(TokenState storage _tokenState, address _operator)
    checkSenderNotOperator(_operator)
    external
  {
    if (_operator == address(this))
      _tokenState.defaultOperatorIsRevoked[msg.sender] = false;
    else
      _tokenState.authorizedOperators[_operator][msg.sender] = true;
    emit AuthorizedOperator(_operator, msg.sender);
  }

  function revokeOperator(TokenState storage _tokenState, address _operator)
    checkSenderNotOperator(_operator)
    external
  {
    if (_operator == address(this))
      _tokenState.defaultOperatorIsRevoked[msg.sender] = true;
    else
      _tokenState.authorizedOperators[_operator][msg.sender] = false;
    emit RevokedOperator(_operator, msg.sender);
  }

  function authorizeMinter(TokenState storage _tokenState, address _minter)
    external
  {
    _tokenState.minters[_minter] = true;
  }

  function revokeMinter(TokenState storage _tokenState, address _minter)
    external
  {
    _tokenState.minters[_minter] = false;
  }

  function doMint(TokenState storage _tokenState, address _to, uint256 _amount)
    external
  {
    assert(_to != address(0));

    _tokenState.totalSupply = _tokenState.totalSupply.add(_amount);
    _tokenState.balances[_to] = _tokenState.balances[_to].add(_amount);

    // From ERC777: The token contract MUST call the tokensReceived hook after updating the state.
    receiveHook(address(this), address(0), _to, _amount, "", "", true);

    emit Minted(address(this), _to, _amount, "", "");
    emit Transfer(address(0), _to, _amount);
  }

  function doBurn(TokenState storage _tokenState, address _operator, address _from, uint256 _amount, bytes calldata _data,
      bytes calldata _operatorData)
    external
  {
    assert(_from != address(0));
    // From ERC777: The token contract MUST call the tokensToSend hook before updating the state.
    sendHook(_operator, _from, address(0), _amount, _data, _operatorData);

    _tokenState.balances[_from] = _tokenState.balances[_from].sub(_amount, "Cannot burn more than balance");
    _tokenState.totalSupply = _tokenState.totalSupply.sub(_amount);

    emit Burned(_operator, _from, _amount, _data, _operatorData);
    emit Transfer(_from, address(0), _amount);
  }

  function doSend(TokenState storage _tokenState, address _operator, address _from, address _to, uint256 _amount,
      bytes memory _data, bytes memory _operatorData, bool _enforceERC777)
    public
  {
    assert(_from != address(0));

    require(_to != address(0), "Cannot send funds to 0 address");
    // From ERC777: The token contract MUST call the tokensToSend hook before updating the state.
    sendHook(_operator, _from, _to, _amount, _data, _operatorData);

    _tokenState.balances[_from] = _tokenState.balances[_from].sub(_amount, "Amount exceeds available funds");
    _tokenState.balances[_to] = _tokenState.balances[_to].add(_amount);

    emit Sent(_operator, _from, _to, _amount, _data, _operatorData);
    emit Transfer(_from, _to, _amount);

    // From ERC777: The token contract MUST call the tokensReceived hook after updating the state.
    receiveHook(_operator, _from, _to, _amount, _data, _operatorData, _enforceERC777);
  }

  function receiveHook(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData, bool _enforceERC777)
    public
  {
    address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_to, ERC777_TOKENS_RECIPIENT_HASH);
    if (implementer != address(0))
      IERC777Recipient(implementer).tokensReceived(_operator, _from, _to, _amount, _data, _operatorData);
    else if (_enforceERC777)
      require(!isContract(_to), "Must be registered with ERC1820");
  }

  function sendHook(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData)
    public
  {
    address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_from, ERC777_TOKENS_SENDER_HASH);
    if (implementer != address(0))
      IERC777Sender(implementer).tokensToSend(_operator, _from, _to, _amount, _data, _operatorData);
  }

  function isContract(address _account)
    private
    view
    returns (bool isContract_)
  {
    uint256 size;

    assembly {
      size := extcodesize(_account)
    }

    isContract_ = size != 0;
  }
}

// File: contracts/Token.sol

pragma solidity 0.6.7;




/**
 * Implements ERC777 with ERC20 as defined in https://eips.ethereum.org/EIPS/eip-777, with minting support.
 * NOTE: Minting is internal only: derive from this contract according to usage.
 */
contract Token is IERC777, IERC20 {

  string private tokenName;
  string private tokenSymbol;
  uint8 constant private tokenDecimals = 18;
  uint256 constant private tokenGranularity = 1;
  TokenState public tokenState;

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // keccak256("ERC777Token")
  bytes32 constant internal ERC777_TOKEN_HASH = 0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;
  // keccak256("ERC20Token")
  bytes32 constant internal ERC20_TOKEN_HASH = 0xaea199e31a596269b42cdafd93407f14436db6e4cad65417994c2eb37381e05a;

  event AuthorizedMinter(address minter);
  event RevokedMinter(address minter);

  constructor(string memory _name, string memory _symbol, uint256 _initialSupply)
    internal
  {
    require(bytes(_name).length != 0, "Needs a name");
    require(bytes(_symbol).length != 0, "Needs a symbol");
    tokenName = _name;
    tokenSymbol = _symbol;
    LToken.initState(tokenState, tokenDecimals, _initialSupply);

    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKEN_HASH, address(this));
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC20_TOKEN_HASH, address(this));
  }

  modifier onlyOperator(address _holder) {
    require(isOperatorFor(msg.sender, _holder), "Not an operator");
    _;
  }

  modifier onlyMinter {
    require(tokenState.minters[msg.sender], "onlyMinter");
    _;
  }

  function name()
    external
    view
    override(IERC777, IERC20)
    returns (string memory name_)
  {
    name_ = tokenName;
  }

  function symbol()
    external
    view
    override(IERC777, IERC20)
    returns (string memory symbol_)
  {
    symbol_ = tokenSymbol;
  }

  function decimals()
    external
    view
    override
    returns (uint8 decimals_)
  {
    decimals_ = tokenDecimals;
  }

  function granularity()
    external
    view
    override
    returns (uint256 granularity_)
  {
    granularity_ = tokenGranularity;
  }

  function balanceOf(address _holder)
    external
    override(IERC777, IERC20)
    view
    returns (uint256 balance_)
  {
    balance_ = tokenState.balances[_holder];
  }

  function transfer(address _to, uint256 _value)
    external
    override
    returns (bool success_)
  {
    doSend(msg.sender, msg.sender, _to, _value, "", "", false);
    success_ = true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
    external
    override
    returns (bool success_)
  {
    LToken.transferFrom(tokenState, _from, _to, _value);
    success_ = true;
  }

  function approve(address _spender, uint256 _value)
    external
    override
    returns (bool success_)
  {
    LToken.approve(tokenState, _spender, _value);
    success_ = true;
  }

  function allowance(address _holder, address _spender)
    external
    view
    override
    returns (uint256 remaining_)
  {
    remaining_ = tokenState.approvals[_holder][_spender];
  }

  function defaultOperators()
    external
    view
    override
    returns (address[] memory)
  {
    return tokenState.defaultOperators;
  }

  function authorizeOperator(address _operator)
    external
    override
  {
    LToken.authorizeOperator(tokenState, _operator);
  }

  function revokeOperator(address _operator)
    external
    override
  {
    LToken.revokeOperator(tokenState, _operator);
  }

  function send(address _to, uint256 _amount, bytes calldata _data)
    external
    override
  {
    doSend(msg.sender, msg.sender, _to, _amount, _data, "", true);
  }

  function operatorSend(address _from, address _to, uint256 _amount, bytes calldata _data, bytes calldata _operatorData)
    external
    override
    onlyOperator(_from)
  {
    doSend(msg.sender, _from, _to, _amount, _data, _operatorData, true);
  }

  function burn(uint256 _amount, bytes calldata _data)
    external
    override
  {
    doBurn(msg.sender, msg.sender, _amount, _data, "");
  }

  function operatorBurn(address _from, uint256 _amount, bytes calldata _data, bytes calldata _operatorData)
    external
    override
    onlyOperator(_from)
  {
    doBurn(msg.sender, _from, _amount, _data, _operatorData);
  }

  function mint(address _to, uint256 _amount)
    external
    onlyMinter
  {
    LToken.doMint(tokenState, _to, _amount);
  }

  function totalSupply()
    external
    view
    override(IERC777, IERC20)
    returns (uint256 totalSupply_)
  {
    totalSupply_ = tokenState.totalSupply;
  }

  function isOperatorFor(address _operator, address _holder)
    public
    view
    override
    returns (bool isOperatorFor_)
  {
    isOperatorFor_ = (_operator == _holder || tokenState.authorizedOperators[_operator][_holder]
        || _operator == address(this) && !tokenState.defaultOperatorIsRevoked[_holder]);
  }

  function doSend(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData, bool _enforceERC777)
    internal
    virtual
  {
    LToken.doSend(tokenState, _operator, _from, _to, _amount, _data, _operatorData, _enforceERC777);
  }

  function doBurn(address _operator, address _from, uint256 _amount, bytes memory _data, bytes memory _operatorData)
    internal
  {
    LToken.doBurn(tokenState, _operator, _from, _amount, _data, _operatorData);
  }

  function authorizeMinter(address _minter)
    internal
  {
    LToken.authorizeMinter(tokenState, _minter);

    emit AuthorizedMinter(_minter);
  }

  function revokeMinter(address _minter)
    internal
  {
    LToken.revokeMinter(tokenState, _minter);

    emit RevokedMinter(_minter);
  }
}

// File: contracts/VOWToken.sol

pragma solidity 0.6.7;




/**
 * ERC777/20 contract which also:
 * - is owned
 * - supports proxying of own tokens (only if signed correctly)
 * - supports partner contracts, keyed by hash
 * - supports minting (only by owner approved contracts)
 * - has a USD price
 */
contract VOWToken is Token, IERC777Recipient, Owned {

  mapping (bytes32 => bool) public proxyProofs;
  uint256[2] public usdRate;
  address public usdRateSetter;
  mapping(bytes32 => address payable) public partnerContracts;

  // precalculated hash - see https://github.com/ethereum/solidity/issues/4024
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  event LogUSDRateSetterSet(address indexed usdRateSetter);
  event LogUSDRateSet(uint256 numTokens, uint256 numUSD);
  event LogProxiedTokens(address indexed from, address indexed to, uint256 amount, bytes data, uint256 nonce, bytes proof);
  event LogPartnerContractSet(bytes32 indexed keyHash, address indexed partnerContract);
  event LogMintPermissionSet(address indexed contractAddress, bool canMint);

  constructor(string memory _name, string memory _symbol, uint256 _initialSupply, uint256[2] memory _initialUSDRate)
    public
    Token(_name, _symbol, _initialSupply)
  {
    doSetUSDRate(_initialUSDRate[0], _initialUSDRate[1]);

    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));
  }

  modifier onlyUSDRateSetter() {
    require(msg.sender == usdRateSetter, "onlyUSDRateSetter");
    _;
  }

  modifier onlyOwnTokens {
    require(msg.sender == address(this), "onlyOwnTokens");
    _;
  }

  modifier addressNotNull(address _address) {
    require(_address != address(0), "Address cannot be null");
    _;
  }

  function tokensReceived(address /* _operator */, address /* _from */, address /* _to */, uint256 _amount,
      bytes calldata _data, bytes calldata /* _operatorData */)
    external
    override
    onlyOwnTokens
  {
    (address from, address to, uint256 amount, bytes memory data, uint256 nonce, bytes memory proof) =
        abi.decode(_data, (address, address, uint256, bytes, uint256, bytes));
    checkProxying(from, to, amount, data, nonce, proof);

    if (_amount != 0)
      this.send(from, _amount, "");

    this.operatorSend(from, to, amount, data, _data);

    emit LogProxiedTokens(from, to, amount, data, nonce, proof);
  }

  function setPartnerContract(bytes32 _keyHash, address payable _partnerContract)
    external
    onlyOwner
    addressNotNull(_partnerContract)
  {
    require(_keyHash != bytes32(0), "Missing key hash");
    partnerContracts[_keyHash] = _partnerContract;

    emit LogPartnerContractSet(_keyHash, _partnerContract);
  }

  function setUSDRateSetter(address _usdRateSetter)
    external
    onlyOwner
    addressNotNull(_usdRateSetter)
  {
    usdRateSetter = _usdRateSetter;

    emit LogUSDRateSetterSet(_usdRateSetter);
  }

  function setUSDRate(uint256 _numTokens, uint256 _numUSD)
    external
    onlyUSDRateSetter
  {
    doSetUSDRate(_numTokens, _numUSD);

    emit LogUSDRateSet(_numTokens, _numUSD);
  }

  function setMintPermission(address _contract, bool _canMint)
    external
    onlyOwner
    addressNotNull(_contract)
  {
    if (_canMint)
      authorizeMinter(_contract);
    else
      revokeMinter(_contract);

    emit LogMintPermissionSet(_contract, _canMint);
  }

  function doSetUSDRate(uint256 _numTokens, uint256 _numUSD)
    private
  {
    require(_numTokens != 0, "numTokens cannot be zero");
    require(_numUSD != 0, "numUSD cannot be zero");
    usdRate = [_numTokens, _numUSD];
  }

  function checkProxying(address _from, address _to, uint256 _amount, bytes memory _data, uint256 _nonce, bytes memory _proof)
    private
  {
    require(!proxyProofs[keccak256(_proof)], "Proxy proof not unique");
    proxyProofs[keccak256(_proof)] = true;
    bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _amount, _data, _nonce));
    address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _proof);
    require(signer == _from, "Bad signer");
  }
}

// File: contracts/VSCToken.sol

pragma solidity 0.6.7;


/**
 * VSCToken is a VOWToken with:
 * - a linked parent Vow token
 * - tier 1 burn (with owner aproved exceptions)
 * - tier 2 delegated lifting (only by owner approved contracts)
 */
contract VSCToken is VOWToken {
  using SafeMath for uint256;

  address public immutable vowContract;
  mapping(address => bool) public canLift;
  mapping(address => bool) public skipTier1Burn;
  uint256[2] public tier1BurnVSC;

  event LogTier1BurnVSCUpdated(uint256[2] ratio);
  event LogLiftPermissionSet(address indexed liftingAddress, bool canLift);
  event LogSkipTier1BurnSet(address indexed skipTier1BurnAddress, bool skipTier1Burn);

  constructor(string memory _name, string memory _symbol, uint256[2] memory _initialVSCUSD, address _vowContract)
    VOWToken(_name, _symbol, 0, _initialVSCUSD)
    public
  {
    vowContract = _vowContract;

    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));

    tier1BurnVSC = [0, 1]; // Default to no burn: ie burn 0 VSC for every 1 VSC sent on tier 1

    setSkipTier1Burn(address(this), true);
  }

  modifier onlyLifter() {
    require(canLift[msg.sender], "onlyLifter");
    _;
  }

  function setLiftPermission(address _liftingAddress, bool _canLift)
    external
    onlyOwner
    addressNotNull(_liftingAddress)
  {
    canLift[_liftingAddress] = _canLift;

    emit LogLiftPermissionSet(_liftingAddress, _canLift);
  }

  function setTier1BurnVSC(uint256 _numVSCBurned, uint256 _numVSCSent)
    external
    onlyOwner
  {
    require(_numVSCSent != 0, "Invalid burn ratio: div by zero");
    require(_numVSCSent >= _numVSCBurned, "Invalid burn ratio: above 100%");
    tier1BurnVSC = [_numVSCBurned, _numVSCSent];

    emit LogTier1BurnVSCUpdated(tier1BurnVSC);
  }

  function lift(address _liftAccount, uint256 _amount, bytes calldata _data)
    external
    onlyLifter
  {
    address tier2ScalingManager = partnerContracts[keccak256(abi.encodePacked("FTScalingManager"))];
    this.operatorSend(_liftAccount, tier2ScalingManager, _amount , _data, "");
  }

  function setSkipTier1Burn(address _skipTier1BurnAddress, bool _skipTier1Burn)
    public
    onlyOwner
    addressNotNull(_skipTier1BurnAddress)
  {
    skipTier1Burn[_skipTier1BurnAddress] = _skipTier1Burn;

    emit LogSkipTier1BurnSet(_skipTier1BurnAddress, _skipTier1Burn);
  }

  function doSend(address _operator, address _from, address _to, uint256 _amount, bytes memory _data,
      bytes memory _operatorData, bool _enforceERC777)
    internal
    virtual
    override
  {
    uint256 actualSendAmount = _amount;

    if (!skipTier1Burn[_from] && !skipTier1Burn[_to]) {
      uint256 burnAmount = _amount.mul(tier1BurnVSC[0]).div(tier1BurnVSC[1]);
      doBurn(_operator, _from, burnAmount, _data, _operatorData);
      actualSendAmount = actualSendAmount.sub(burnAmount);
    }
    super.doSend(_operator, _from, _to, actualSendAmount, _data, _operatorData, _enforceERC777);
  }
}

// File: contracts/thirdParty/provableAPI_06.sol

// Source: https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol

// <provableAPI>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016-2019 Oraclize LTD
Copyright (c) 2019-2020 Provable Things Limited
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
pragma solidity > 0.6.1 < 0.7.0; // Incompatible compiler version - please select a compiler within the stated pragma range, or use a different version of the provableAPI!

// Dummy contract only used to emit to end-user they are using wrong solc
abstract contract solcChecker {
/* INCOMPATIBLE SOLC: import the following instead: "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol" */ function f(bytes calldata x) virtual external;
}

interface ProvableI {

    function cbAddress() external returns (address _cbAddress);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string calldata _datasource) external returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string calldata _datasource, uint _gasLimit)  external returns (uint _dsprice);
    function queryN(uint _timestamp, string calldata _datasource, bytes calldata _argN) external payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

interface OracleAddrResolverI {
    function getAddress() external returns (address _address);
}
/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils
MIT License
Copyright (c) 2018 SmartContract ChainLink, Ltd.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
    /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      *
      */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}
/*
End solidity-cborutils
*/
contract usingProvable {

    using CBOR for Buffer.buffer;

    ProvableI provable;
    OracleAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string provable_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) provable_randomDS_args;
    mapping(bytes32 => bool) provable_randomDS_sessionKeysHashVerified;

    modifier provableAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            provable_setNetwork(networkID_auto);
        }
        if (address(provable) != OAR.getAddress()) {
            provable = ProvableI(OAR.getAddress());
        }
        _;
    }

    modifier provable_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        require(proofVerified);
        _;
    }

    function provable_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID; // NOTE: Silence the warning and remain backwards compatible
      return provable_setNetwork();
    }

    function provable_setNetworkName(string memory _network_name) internal {
        provable_network_name = _network_name;
    }

    function provable_getNetworkName() internal view returns (string memory _networkName) {
        return provable_network_name;
    }

    function provable_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { //mainnet
            OAR = OracleAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            provable_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { //ropsten testnet
            OAR = OracleAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            provable_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { //kovan testnet
            OAR = OracleAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            provable_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OracleAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            provable_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) { //goerli testnet
            OAR = OracleAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            provable_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OracleAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { //ether.camp ide
            OAR = OracleAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OracleAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }
    /**
     * @dev The following `__callback` functions are just placeholders ideally
     *      meant to be defined in child contract when proofs are used.
     *      The function bodies simply silence compiler warnings.
     */
    function __callback(bytes32 _myid, string memory _result) virtual public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) virtual public {
      _myid; _result; _proof;
      provable_randomDS_args[bytes32(0)] = bytes32(0);
    }

    function provable_getPrice(string memory _datasource) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource);
    }

    function provable_getPrice(string memory _datasource, uint _gasLimit) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(0, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(_timestamp, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(_timestamp, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(0, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(0, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(_timestamp, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_setProof(byte _proofP) provableAPI internal {
        return provable.setProofType(_proofP);
    }


    function provable_cbAddress() provableAPI internal returns (address _callbackAddress) {
        return provable.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function provable_setCustomGasPrice(uint _gasPrice) provableAPI internal {
        return provable.setCustomGasPrice(_gasPrice);
    }

    function provable_randomDS_getSessionPubKeyHash() provableAPI internal returns (bytes32 _sessionKeyHash) {
        return provable.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function provable_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = provable_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(add(unonce, 0x20), xor(blockhash(sub(number(), 1)), xor(coinbase(), timestamp())))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = provable_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        provable_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function provable_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        provable_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function provable_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function provable_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function provable_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (provable_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) { //unonce, nbytes and sessionKeyHash match
            delete provable_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = provable_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize(), sub(msize(), fmem))
        }
    }
}
// </provableAPI>

// File: contracts/libraries/LTokenManager.sol

pragma solidity 0.6.7;

library LTokenManager {

  function decimalPriceToRate(string calldata _priceString)
    external
    pure
    returns (uint256[2] memory rate_)
  {
    bool hasDp;
    uint256 dp;
    uint256 result;
    uint256 oldResult;
    bytes memory priceBytes = bytes(_priceString);

    require(priceBytes.length != 0, "Empty string");

    if (priceBytes[0] == "0" && priceBytes.length > 1)
      require(priceBytes[1] == ".", "Bad format: leading zeros");

    for (uint i = 0; i < priceBytes.length; i++) {
      if (priceBytes[i] == "." && !hasDp) {
        require(i < priceBytes.length - 1, "Bad format: expected mantissa");
        hasDp = true;
      } else if (uint8(priceBytes[i]) >= 48 && uint8(priceBytes[i]) <= 57) {
        if (hasDp) dp++;
        oldResult = result;
        result = result * 10 + (uint8(priceBytes[i]) - 48);
        if (oldResult > result || 10**dp < 10**(dp -1))
          revert("Overflow");
      }
      else
        revert("Bad character");
    }

    require(result != 0, "Zero value");

    while (result % 10 == 0) {
      result = result / 10;
      dp--;
    }

    rate_ = [result, 10**dp];
  }
}

// File: contracts/TokenManager.sol

pragma solidity 0.6.7;





contract TokenManager is Owned, usingProvable {

  address public immutable token;
  uint256 public provableUpdateInterval;
  string public provableQuery;
  byte public provableProofType;
  uint256 public provableGasPrice;
  uint256 public provableGasLimit;
  bool public autoUpdate;
  bytes32 private provableQueryID;

  event LogFundsReceived(address indexed sender, uint256 amount);
  event LogFundsRecovered(address recipient, uint256 amount);
  event LogNewRateReceived(uint256[2] rate, bytes indexed proof, string status);
  event LogNewQuery(uint256 cost, string status);
  event LogProvableSettingsUpdated(uint256 interval, string query, byte proofType, uint256 gasPrice, uint256 gasLimit,
      bool autoUpdate);

  constructor(address _token)
    internal
  {
    token = _token;
  }

  modifier onlyProvable() {
    require(msg.sender == provable_cbAddress(), "Not Provable");
    _;
  }

  modifier onlyCurrentQuery(bytes32 _id) {
    require(provableQueryID == _id, "Bad ID");
    _;
  }

  receive() external payable {
    emit LogFundsReceived(msg.sender, msg.value);
  }

  // TODO: Consider removing gasPrice from here.
  function updateProvableSettings(uint256 _interval, string calldata _query, byte _proofType, uint256 _gasPrice,
      uint256 _gasLimit, bool _autoUpdate)
    onlyOwner
    external
  {
    provableUpdateInterval = _interval;
    provableQuery = _query;

    if (provableProofType != _proofType) {
      provableProofType = _proofType;
      provable_setProof(provableProofType);
    }

    autoUpdate = _autoUpdate;

    updateProvableGasPrice(_gasPrice);

    provableGasLimit = _gasLimit;

    emit LogProvableSettingsUpdated(provableUpdateInterval, provableQuery, provableProofType, provableGasPrice,
        provableGasLimit, autoUpdate);
  }

  function recoverFunds()
    onlyOwner
    external
  {
    uint256 balance = address(this).balance;
    (bool success,) = msg.sender.call{value:balance}("");
    require(success);
    emit LogFundsRecovered(msg.sender, balance);
  }

  function updateExchangeRate()
    external
    payable
    onlyOwner
  {
    if (msg.value > 0)
      emit LogFundsReceived(msg.sender, msg.value);
    doUpdateExchangeRate();
  }

  function updateProvableGasPrice(uint256 _gasPrice)
    onlyOwner
    public
  {
    if (provableGasPrice != _gasPrice) {
      provableGasPrice = _gasPrice;
      provable_setCustomGasPrice(provableGasPrice);
    }

    // TODO: Consider emitting a log.
  }

  function __callback(bytes32 _id, string memory _result, bytes memory _proof)
    override
    public
    onlyProvable
  {
    try this.decimalPriceToRate(_id, _result) returns (uint256[2] memory rate) {
      emit LogNewRateReceived(rate, _proof, "Success");
      VOWToken(token).setUSDRate(rate[0], rate[1]);
      if (autoUpdate)
        doUpdateExchangeRate();
    } catch Error(string memory reason) {
      emit LogNewRateReceived([uint256(0),uint256(0)], _proof, reason);
    }
  }

  function decimalPriceToRate(bytes32 _id, string memory _priceString)
    public
    view
    onlyCurrentQuery(_id)
    returns (uint256[2] memory rate_)
  {
    rate_ = LTokenManager.decimalPriceToRate(_priceString);
  }

  function doUpdateExchangeRate()
    private
  {
    uint256 cost = provable_getPrice("URL", provableGasLimit);
    if (cost > address(this).balance)
      emit LogNewQuery(cost, "Query not sent, requires ETH");
    else {
      provableQueryID = provable_query(provableUpdateInterval, "URL", provableQuery, provableGasLimit);
      emit LogNewQuery(cost, "Query sent, awaiting result...");
    }
  }
}

// File: contracts/VSCTokenManager.sol

pragma solidity 0.6.7;




contract VSCTokenManager is TokenManager, IERC777Recipient {
  using SafeMath for uint256;

  enum RatioType {
    MerchantLockBurnVOW,
    MerchantLockMintVSC,
    Liquidity
  }

  address public immutable vowContract;
  mapping(address => uint256[2]) public merchantVOWToVSCLock;
  mapping(address => bool) public registeredMVD;
  mapping(RatioType => uint256[2]) public ratios;

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant private ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // precalculated hash - see https://github.com/ethereum/solidity/issues/4024
  // keccak256("ERC777TokensRecipient")
  bytes32 constant private ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  event LogMVDRegistered(address indexed mvd);
  event LogMVDDeregistered(address indexed mvd);
  event LogRatioUpdated(uint256[2] ratio, RatioType ratioType);
  event LogBurnAndMint(address indexed from, uint256 vowAmount, uint256 vscAmount);
  event LogMerchantVOWLocked(address indexed mvd, address indexed merchant, uint256 lockedVOW, uint256 mintedVSC);
  event LogMerchantVOWUnlocked(address indexed unlocker, address indexed merchant, uint256 unlockedVOW, uint256 returnedVSC);

  constructor(address _token)
    TokenManager(_token)
    public
  {
    vowContract = VSCToken(_token).vowContract();
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));

    ratios[RatioType.MerchantLockBurnVOW] = [1,5]; // ie: burn 1 VOW for every 5 VOW locked
    ratios[RatioType.MerchantLockMintVSC] = [5,1]; // ie: mint 5 VSC for every 1 VSC
    ratios[RatioType.Liquidity] = [984,1000]; // ie: expect a 1.6% burn on tier2, a liquidity ratio of 62.5
  }

  modifier mvdNotNull(address _mvd) {
    require(_mvd != address(0), "MVD address cannot be null");
    _;
  }

  function setRatio(uint256[2] calldata _ratio, RatioType _ratioType)
    external
    onlyOwner
  {
    require(_ratio[1] != 0, "Invalid ratio: div by zero");

    if (_ratioType != RatioType.MerchantLockMintVSC)
      require(_ratio[1] >= _ratio[0], "Invalid lock ratio: above 100%");

    ratios[_ratioType] = _ratio;
    emit LogRatioUpdated(_ratio, _ratioType);
  }

  function getLiquidityRatio()
    external
    view
    returns (uint256[2] memory liquidity_)
  {
    liquidity_ = ratios[RatioType.Liquidity];
  }

  function registerMVD(address _mvd)
    external
    onlyOwner
    mvdNotNull(_mvd)
  {
    registeredMVD[_mvd] = true;
    emit LogMVDRegistered(_mvd);
  }

  function deregisterMVD(address _mvd)
    external
    onlyOwner
    mvdNotNull(_mvd)
  {
    registeredMVD[_mvd] = false;
    emit LogMVDDeregistered(_mvd);
  }

  function tokensReceived(address /* _operator */, address _from, address /* _to */, uint256 _amount, bytes calldata _data,
      bytes calldata /* _operatorData */)
    external
    virtual
    override
  {
    if (msg.sender == vowContract)
      tokensReceivedVOW(_from, _data, _amount);
    else if (msg.sender == token)
      tokensReceivedThisVSC(_from, _data, _amount);
    else
      revert("Bad token");
  }

  function getVOWVSCRate()
    public
    view
    returns (uint256 numVOW_, uint256 numVSC_)
  {
    VSCToken vscToken = VSCToken(token);
    VOWToken vowToken = VOWToken(vowContract);
    numVOW_ = vowToken.usdRate(0).mul(vscToken.usdRate(1));
    numVSC_ = vowToken.usdRate(1).mul(vscToken.usdRate(0));
  }

  function tokensReceivedVOW(address _from, bytes memory _data, uint256 _amount)
    private
  {
    if (registeredMVD[_from]) {
      (address merchant, bytes memory data) = abi.decode(_data, (address, bytes));
      doMerchantLock(_from, merchant, _amount, data);
      return;
    }

    VOWToken(vowContract).burn(_amount, "");
    (uint256 numVOW, uint256 numVSC) = getVOWVSCRate();
    uint256 vscAmount = _amount.mul(numVSC).div(numVOW);
    VSCToken(token).mint(_from, vscAmount);

    emit LogBurnAndMint(_from, _amount, vscAmount);
  }

  function tokensReceivedThisVSC(address _from, bytes memory _data, uint256 _amount)
    private
  {
    doMerchantUnlock(_from, abi.decode(_data, (address)), _amount);
  }

  function doMerchantLock(address _mvd, address _merchant, uint256 _vowAmount, bytes memory _data)
    private
  {
    require(merchantVOWToVSCLock[_merchant][0] == 0, "Merchant is locked");

    (uint256 numVOW, uint256 numVSC) = getVOWVSCRate();

    uint256 burnAmount = _vowAmount.mul(ratios[RatioType.MerchantLockBurnVOW][0]).div(ratios[RatioType.MerchantLockBurnVOW][1]);

    uint256 vscAmount = _vowAmount.mul(numVSC).mul(ratios[RatioType.MerchantLockMintVSC][0]).
        div(numVOW.mul(ratios[RatioType.MerchantLockMintVSC][1]));

    merchantVOWToVSCLock[_merchant][0] = _vowAmount.sub(burnAmount);
    merchantVOWToVSCLock[_merchant][1] = vscAmount;

    VOWToken(vowContract).burn(burnAmount, "");
    VSCToken(token).mint(_mvd, vscAmount);
    VSCToken(token).lift(_mvd, vscAmount, _data);

    emit LogMerchantVOWLocked(_mvd, _merchant, merchantVOWToVSCLock[_merchant][0], vscAmount);
  }

  function doMerchantUnlock(address _unlocker, address _merchant, uint256 _vscAmount)
    private
  {
    require(merchantVOWToVSCLock[_merchant][0] > 0, "No VOW to unlock");
    require(merchantVOWToVSCLock[_merchant][1] == _vscAmount, "Incorrect VSC amount");

    VSCToken(token).burn(_vscAmount, "");
    VOWToken(vowContract).send(_merchant, merchantVOWToVSCLock[_merchant][0], "");
    emit LogMerchantVOWUnlocked(_unlocker, _merchant, merchantVOWToVSCLock[_merchant][0], _vscAmount);
    delete merchantVOWToVSCLock[_merchant];
  }
}

// File: contracts/libraries/LOrdersDLL.sol

pragma solidity 0.6.7;


library LOrdersDLL {
  using SafeMath for uint256;

  struct EntriesDLL {
    mapping(bytes32 => Entry) entries;
    bytes32 head;
    bytes32 tail;
  }

  struct Entry {
    EntryData entryData;
    bytes32 prevHash;
    bytes32 nextHash;
  }

  struct EntryData {
    address seller;
    uint256 sellAmount; // in atto units
    uint256 buyAmount; // in atto units
    uint256 timestamp; // when the entry was submitted
  }

  function getPositionInOrderBook(EntriesDLL storage _dll, bytes32 _entryHash)
    external
    view
    returns (uint256 position_)
  {
    bytes32 checkHash = _dll.head;
    while(_entryHash != checkHash) {
      require(checkHash != 0, "Entry not found");
      checkHash = _dll.entries[checkHash].prevHash;
      ++position_;
    }
  }

  // Split the DLL of entries: everything from the head to the splitEntry is separated from the DLL, the entry that is closer to
  // the tail, if there is one, is now the head.
  function splitBookDLLAtEntry(EntriesDLL storage _dll, bytes32 splitEntryHash)
    external
  {
    Entry storage splitEntry = _dll.entries[splitEntryHash];
    assert(splitEntry.entryData.timestamp != 0); // Entry must exist!

    // Make splitEntry's previous entry the new head.
    if (splitEntry.prevHash != 0)
      _dll.entries[splitEntry.prevHash].nextHash = 0;
    _dll.head = splitEntry.prevHash;

    if (_dll.tail == splitEntryHash)
      _dll.tail = 0;

    splitEntry.prevHash = 0;
  }

  function addEntryForRemainder(EntriesDLL storage _dll, uint256 _lastEntryAmountBought, uint256 _lastEntryAmountSold,
        Entry storage _lastEntry)
    external
    returns (bytes32 newHeadEntryHash_, uint256 remainingSellAmount_)
  {
    Entry memory remainderEntry;
    remainderEntry.entryData = cloneEntryDataStruct(_lastEntry.entryData);
    remainingSellAmount_ = remainderEntry.entryData.sellAmount.sub(_lastEntryAmountSold);
    remainderEntry.entryData.sellAmount = remainingSellAmount_;
    remainderEntry.entryData.buyAmount = remainderEntry.entryData.buyAmount.sub(_lastEntryAmountBought);

    newHeadEntryHash_ = addEntryToHeadOfBookDLL(_dll, remainderEntry);

    assert(_dll.entries[newHeadEntryHash_].entryData.timestamp == 0);
    _dll.entries[newHeadEntryHash_] = remainderEntry;
  }

  function removeEntryFromBookDLL(EntriesDLL storage _dll, Entry storage _entryToRemove)
    external
  {
    if (_entryToRemove.prevHash != 0) {
      Entry storage prevEntry = _dll.entries[_entryToRemove.prevHash];
      prevEntry.nextHash = _entryToRemove.nextHash;
    } else
      _dll.tail = _entryToRemove.nextHash;

    if (_entryToRemove.nextHash != 0) {
      Entry storage nextEntry = _dll.entries[_entryToRemove.nextHash];
      nextEntry.prevHash = _entryToRemove.prevHash;
    } else
      _dll.head = _entryToRemove.prevHash;
  }

  function addEntryToOrderBook(EntriesDLL storage _dll, address _from, uint256 _amount, bytes calldata _params)
    external
    returns (bytes32 entryHash_)
  {
    EntryData memory entryData;
    bytes32 expectedPrevHash;
    (entryData.seller, entryData.sellAmount, entryData.buyAmount, expectedPrevHash) = abi.decode(_params,
        (address, uint256, uint256, bytes32));
    require(entryData.seller == _from, "From must match encoded seller");
    require(entryData.sellAmount == _amount, "Amount must match encoded amount");
    assert(entryData.buyAmount != 0);
    entryData.timestamp = now;

    entryHash_ = insertEntryIntoBookDLL(_dll, entryData, expectedPrevHash);
  }

  function findActualPrevHash(EntriesDLL storage _dll, uint256 _sellAmount, uint256 _buyAmount)
    external
    view
    returns (bytes32 prevHash_)
  {
    EntryData memory entryData = EntryData(msg.sender, _sellAmount, _buyAmount, now);
    prevHash_ = findActualPrevHash(_dll, _dll.head, entryData);
  }

  function addEntryToHeadOfBookDLL(EntriesDLL storage _dll, Entry memory newEntry)
    private
    returns (bytes32 newEntryHash)
  {
    newEntryHash = getEntryHash(newEntry.entryData);

    if (_dll.head == 0)
      _dll.tail = newEntryHash;
    else
      _dll.entries[_dll.head].nextHash = newEntryHash;

    newEntry.prevHash = _dll.head;
    newEntry.nextHash = 0;
    _dll.head = newEntryHash;
  }

  function insertEntryIntoBookDLL(EntriesDLL storage _dll, EntryData memory _entryData, bytes32 _expectedPrevHash)
    private
    returns (bytes32 entryHash_)
  {
    bytes32 actualPrevHash = findActualPrevHash(_dll, _expectedPrevHash, _entryData);

    entryHash_ = getEntryHash(_entryData);
    require(_dll.entries[entryHash_].entryData.timestamp == 0, "Entry already in order book");

    bytes32 nextHash;
    if (actualPrevHash == 0) {
      nextHash = _dll.tail;
      _dll.tail = entryHash_;
    } else {
      Entry storage prevEntry = _dll.entries[actualPrevHash];
      nextHash = prevEntry.nextHash;
      prevEntry.nextHash = entryHash_;
    }

    if (nextHash == 0)
      _dll.head = entryHash_;
    else {
      Entry storage nextEntry = _dll.entries[nextHash];
      require(pricesOrTimestampsAreDifferent(_entryData, nextEntry.entryData), "Price at time not unique: retry");
      nextEntry.prevHash = entryHash_;
    }

    Entry memory entry = Entry(_entryData, actualPrevHash, nextHash);
    _dll.entries[entryHash_] = entry;
  }

  function findActualPrevHash(EntriesDLL storage _dll, bytes32 _expectedPrevHash, EntryData memory _entryData)
    private
    view
    returns (bytes32)
  {
    Entry memory actualPrev = (_expectedPrevHash == 0) ? _dll.entries[_dll.tail] :
        _dll.entries[_expectedPrevHash];

    // If the price is greater than the prev entry & less than or equal to the next entry then the position is correct
    if (priceIsGreaterThan(_entryData, actualPrev.entryData) &&
        priceIsLessThanOrEqualTo(_entryData, _dll.entries[actualPrev.nextHash].entryData))
      return _expectedPrevHash;

    // If the price is less than or equal to the prev entry search down for the lowest equal or greater than entry
    if (priceIsLessThanOrEqualTo(_entryData, actualPrev.entryData)) {
      while (priceIsLessThanOrEqualTo(_entryData, actualPrev.entryData)) {
        if (actualPrev.prevHash == 0) return 0;
        actualPrev = _dll.entries[actualPrev.prevHash];
      }
      return getEntryHash(actualPrev.entryData);
    }

    // Otherwise search up whilst the price remains greater than the next entry
    while (actualPrev.nextHash != 0 && priceIsGreaterThan(_entryData, actualPrev.entryData))
      actualPrev = _dll.entries[actualPrev.nextHash];
    return getEntryHash(actualPrev.entryData);
  }

  function getEntryHash(EntryData memory _entryData)
    private
    pure
    returns (bytes32 entryHash_)
  {
    entryHash_ = keccak256(abi.encodePacked(_entryData.seller, _entryData.sellAmount, _entryData.buyAmount,
        _entryData.timestamp));
  }

  function priceIsLessThanOrEqualTo(EntryData memory _entryData, EntryData memory _otherEntryData)
    private
    pure
    returns (bool)
  {
    return _entryData.sellAmount.mul(_otherEntryData.buyAmount) <= _otherEntryData.sellAmount.mul(_entryData.buyAmount);
  }

  function priceIsGreaterThan(EntryData memory _entryData, EntryData memory _otherEntryData)
    private
    pure
    returns (bool)
  {
    return _entryData.sellAmount.mul(_otherEntryData.buyAmount) > _otherEntryData.sellAmount.mul(_entryData.buyAmount);
  }

  function priceIsNotEqualTo(EntryData memory _entryData, EntryData memory _otherEntryData)
    private
    pure
    returns (bool)
  {
    return _entryData.sellAmount.mul(_otherEntryData.buyAmount) != _otherEntryData.sellAmount.mul(_entryData.buyAmount);
  }

  function pricesOrTimestampsAreDifferent(EntryData memory _entryData, EntryData memory _otherEntryData)
    private
    pure
    returns (bool areDifferent_)
  {
    areDifferent_ = _entryData.timestamp != _otherEntryData.timestamp;
    if (!areDifferent_)
      areDifferent_ = priceIsNotEqualTo(_entryData, _otherEntryData);
  }

  function cloneEntryDataStruct(EntryData storage _entryData)
    private
    view
    returns (EntryData memory entryData_)
  {
    entryData_ = EntryData(_entryData.seller, _entryData.sellAmount, _entryData.buyAmount, _entryData.timestamp);
  }
}

// File: contracts/libraries/LOrderBooks.sol

pragma solidity 0.6.7;



library LOrderBooks {
  using SafeMath for uint256;

  struct Market {
    OrderBook vowToVSC;
    uint256 lastFinalised;
    uint256 period;
    uint256 minimumVSCAmount;
    uint8 mintVOWCounter;
    Frozen frozen;
  }

  struct OrderBook {
    LOrdersDLL.EntriesDLL dll;
    FinalisedBook[] finalisedBooks;
    bool isFrozen;
  }

  struct Frozen {
    uint256 timestamp;
    uint256 amountBurnedInTier2;
    uint256 amountInIlliquidAccounts;
    uint256 amountOfVSC;
  }

  struct FinalisedBook {
    Frozen frozen;  // Separate struct due to stack depth issue when decoding
    uint256 amountMintedForBook;
    uint256 amountBurnedForBook;
    uint256[2] winningPrice;
    bytes32 lastEntryHash; // The last "winner"
    uint256 lastEntryAmountBought; // The amount bought by the last entry
    uint256 lastEntryAmountSold; // The amount sold by the last entry
    uint256 lastEntryTimestamp;
  }

  event LogOrderBookSplitWinner(address indexed vscContract, address indexed seller, bytes32 indexed lastEntryHash,
      uint256 amountBought, bytes32 remainderEntryHash, uint256 remainingSellAmount);

  modifier onlyAfterOrderBooksPeriod(Market storage _market) {
    require(_market.lastFinalised.add(_market.period) <= now, "Not enough time elapsed");
    _;
  }

  function getPositionInOrderBook(Market storage _market, bytes32 _entryHash)
    external
    view
    returns (uint256 position_)
  {
    OrderBook storage orderBook = _market.vowToVSC;
    position_ = LOrdersDLL.getPositionInOrderBook (orderBook.dll, _entryHash);
  }

  function addEntryToOrderBook(Market storage _market, address _from, uint256 _amount, bytes calldata _params)
    external
    returns (bytes32 entryHash_)
  {
    OrderBook storage orderBook = _market.vowToVSC;
    entryHash_ = LOrdersDLL.addEntryToOrderBook(orderBook.dll, _from, _amount, _params);
  }

  function getAddEntryToOrderBookParams(Market storage _market, uint256 _sellAmount, uint256 _buyAmount)
    external
    view
    returns (bytes memory params_)
  {
    OrderBook storage orderBook = _market.vowToVSC;

    require(_sellAmount != 0, "Cannot sell zero");
    require(_buyAmount != 0, "Cannot buy zero");

    bytes32 prevHash = LOrdersDLL.findActualPrevHash(orderBook.dll, _sellAmount, _buyAmount);
    params_ = abi.encode(msg.sender, _sellAmount, _buyAmount, prevHash);
  }

  function removeEntryFromOrderBook(Market storage _market, bytes32 _entryHash, address _from)
    external
    returns (uint256 amountToReturn_)
  {
    OrderBook storage orderBook = _market.vowToVSC;

    LOrdersDLL.Entry storage entryToRemove = orderBook.dll.entries[_entryHash];
    require(entryToRemove.entryData.timestamp != 0, "Entry not in order book");
    require(entryToRemove.entryData.seller == _from, "Only order owner can remove");

    (bool isFound, ) = isInAFinalisedBook(orderBook.finalisedBooks, _entryHash, entryToRemove.entryData);
    require(!isFound, "Please call completeOrder");

    LOrdersDLL.removeEntryFromBookDLL(orderBook.dll, entryToRemove);

    amountToReturn_ = entryToRemove.entryData.sellAmount;
    delete orderBook.dll.entries[_entryHash];
  }

  function completeEntryFromFinalisedBook(Market storage _market, bytes32 _entryHash, address _from)
    external
    returns (uint256 amountToReturn_)
  {
    OrderBook storage orderBook = _market.vowToVSC;
    LOrdersDLL.Entry memory entryToComplete = orderBook.dll.entries[_entryHash];

    require(entryToComplete.entryData.timestamp != 0, "Entry not in finalised book");
    require(entryToComplete.entryData.seller == _from, "Only order owner can complete");

    bool isFound;
    (isFound, amountToReturn_) = isInAFinalisedBook(orderBook.finalisedBooks, _entryHash, entryToComplete.entryData);
    require(isFound, "Please call removeOrder");

    delete orderBook.dll.entries[_entryHash];
  }

  function freezeOrderBook(Market storage _market, uint256 _totalSupply, uint256 _amountBurnedInTier2,
      uint256 _amountInIlliquidAccounts, uint256[2] calldata _liquidityRatio)
    external
    onlyAfterOrderBooksPeriod(_market)
    returns(string memory noOrderBookReason_)
  {
    uint256 amountOfVSC;

    amountOfVSC = getAmountOfVSCForOrderBook(_totalSupply, _amountBurnedInTier2, _amountInIlliquidAccounts,
          _liquidityRatio, _market.minimumVSCAmount);

    if (amountOfVSC == 0) {
      noOrderBookReason_ = "No mint required";
      _market.lastFinalised = now;
      _market.mintVOWCounter = 0;
    } else {
      OrderBook storage orderBook = _market.vowToVSC;
      require(orderBook.dll.head != 0, "No entries in order book");
      _market.frozen.timestamp = now;
      _market.frozen.amountBurnedInTier2 = _amountBurnedInTier2;
      _market.frozen.amountInIlliquidAccounts = _amountInIlliquidAccounts;
      _market.frozen.amountOfVSC = amountOfVSC;
      orderBook.isFrozen = true;
    }
  }

  function getFinaliseOrderBookParams(Market storage _market)
    external
    view
    returns (bytes memory params_)
  {
    uint256 amountOfVSC = _market.frozen.amountOfVSC;
    assert(amountOfVSC > 0);

    FinalisedBook memory finalisedBook = getFinalisedBookWithLastEntry(_market.vowToVSC, amountOfVSC);
    finalisedBook.frozen.timestamp = _market.frozen.timestamp;

    bytes memory encodedFinalisedBook = encodeFinaliseOrderBookParams(finalisedBook);
    params_ = abi.encode(address(this), encodedFinalisedBook);

  }

  function finaliseOrderBook(address _vscContract, Market storage _market, bytes calldata _encodedParams)
    external
  {
    OrderBook storage frozenBook = _market.vowToVSC;
    (address encoder, bytes memory encodedParams) = abi.decode(_encodedParams, (address, bytes));
    require(encoder == address(this), "Wrong encoder");
    (FinalisedBook memory finalisedBook) = decodeFinaliseOrderBookParams(encodedParams);
    require(finalisedBook.frozen.timestamp == _market.frozen.timestamp, "Wrong encoded params");
    finalisedBook.frozen = cloneFrozenStruct(_market.frozen);

    frozenBook.finalisedBooks.push(finalisedBook);

    LOrdersDLL.Entry storage lastEntry = frozenBook.dll.entries[finalisedBook.lastEntryHash];

    LOrdersDLL.splitBookDLLAtEntry(frozenBook.dll, finalisedBook.lastEntryHash);

    uint256 lastEntryAmountBought = finalisedBook.lastEntryAmountBought;

    if (lastEntryAmountBought < lastEntry.entryData.buyAmount) {
      (bytes32 newHeadEntryHash, uint256 remainingSellAmount) = LOrdersDLL.addEntryForRemainder(frozenBook.dll,
          lastEntryAmountBought, finalisedBook.lastEntryAmountSold, lastEntry);
      emit LogOrderBookSplitWinner(_vscContract, lastEntry.entryData.seller, finalisedBook.lastEntryHash, lastEntryAmountBought,
          newHeadEntryHash, remainingSellAmount);
    }
    _market.mintVOWCounter = 0;
  }

  function getAmountOfVSCForOrderBook(uint256 _totalSupply, uint256 _amountBurnedInTier2, uint256 _amountInIlliquidAccounts,
      uint256[2] memory _liquidityRatio, uint256 _minimumVSCAmount)
    internal
    pure
    returns(uint256 amountOfVSC_)
  {
    if (_totalSupply == 0) return (0);

    require(_totalSupply >= _amountInIlliquidAccounts, "Illiquid amount exceeds supply");
    uint256 liquidSupply = _totalSupply.sub(_amountInIlliquidAccounts);
    require(liquidSupply >= _amountBurnedInTier2, "Tier2 burn exceeds liquid supply");
    uint256 expectedSupply = liquidSupply.mul(_liquidityRatio[0]).div(_liquidityRatio[1]);
    uint256 actualSupply = liquidSupply.sub(_amountBurnedInTier2);

    if (expectedSupply > actualSupply && expectedSupply.sub(actualSupply) >= _minimumVSCAmount)
      amountOfVSC_ = expectedSupply.sub(actualSupply);
  }

  function getFinalisedBookWithLastEntry(OrderBook storage _orderBook, uint256 _amountOfVSC)
    private
    view
    returns (FinalisedBook memory finalisedBook_)
  {
    finalisedBook_.amountMintedForBook = _amountOfVSC;
    uint256 vscRemainingForUsersToBuy = _amountOfVSC;
    uint256 vowBurnedForBook;
    uint256 userBuysVSCAmount;
    uint256 userSellsVOWAmount;

    bytes32 entryHash = _orderBook.dll.head;

    while (true) {
      LOrdersDLL.Entry storage entry = _orderBook.dll.entries[entryHash];
      LOrdersDLL.EntryData storage entryData = entry.entryData;
      userBuysVSCAmount = entryData.buyAmount;
      userSellsVOWAmount = entryData.sellAmount;

      if (vscRemainingForUsersToBuy > userBuysVSCAmount) {
        vscRemainingForUsersToBuy = vscRemainingForUsersToBuy.sub(userBuysVSCAmount);
        vowBurnedForBook = vowBurnedForBook.add(userSellsVOWAmount);
        entryHash = entry.prevHash;
        require(entryHash != 0, "Not enough entries: unfreeze");
      } else {
        // We have found the last entry.
        finalisedBook_.lastEntryTimestamp = entryData.timestamp;
        break;
      }
    }

    if (vscRemainingForUsersToBuy == userBuysVSCAmount) {
      finalisedBook_.lastEntryAmountSold = userSellsVOWAmount;
      finalisedBook_.amountBurnedForBook = vowBurnedForBook.add(userSellsVOWAmount);
    } else {
      uint256 partialSellAmount = vscRemainingForUsersToBuy.mul(userSellsVOWAmount).div(userBuysVSCAmount);
      if (partialSellAmount == 0) {
        // Special case for fractional remaining amount.
        partialSellAmount = 1;
      }
      finalisedBook_.lastEntryAmountSold = partialSellAmount;
      finalisedBook_.amountBurnedForBook = vowBurnedForBook.add(partialSellAmount);
    }

    finalisedBook_.lastEntryHash = entryHash;
    finalisedBook_.winningPrice = [userSellsVOWAmount, userBuysVSCAmount];
    finalisedBook_.lastEntryAmountBought = vscRemainingForUsersToBuy;
  }

  function encodeFinaliseOrderBookParams(FinalisedBook memory _finalisedBook)
    private
    pure
    returns (bytes memory encodedParams_)
  {
    encodedParams_ = abi.encode(_finalisedBook.frozen.timestamp, _finalisedBook.amountMintedForBook,
        _finalisedBook.amountBurnedForBook, _finalisedBook.winningPrice, _finalisedBook.lastEntryHash,
        _finalisedBook.lastEntryAmountBought, _finalisedBook.lastEntryAmountSold, _finalisedBook.lastEntryTimestamp);
  }

  function decodeFinaliseOrderBookParams(bytes memory _encodedParams)
    private
    pure
    returns (FinalisedBook memory book_)
  {
    (book_.frozen.timestamp, book_.amountMintedForBook, book_.amountBurnedForBook, book_.winningPrice, book_.lastEntryHash,
        book_.lastEntryAmountBought, book_.lastEntryAmountSold, book_.lastEntryTimestamp) =
            abi.decode(_encodedParams, (uint256, uint256, uint256, uint256[2], bytes32, uint256, uint256, uint256));
  }

  function cloneFrozenStruct(Frozen storage _frozen)
    private
    view
    returns (Frozen memory frozen_)
  {
    frozen_ = Frozen(_frozen.timestamp, _frozen.amountBurnedInTier2, _frozen.amountInIlliquidAccounts, _frozen.amountOfVSC);
  }

  function isInAFinalisedBook(FinalisedBook[] storage _finalisedBooks, bytes32 _entryHash,
      LOrdersDLL.EntryData memory _entryData)
    private
    view
    returns (bool isFound_, uint256 lastEntryAmountBought_)
  {
    for (uint i = 0; i < _finalisedBooks.length; i++) {
      FinalisedBook storage finalisedBook = _finalisedBooks[i];
      if (_entryData.timestamp > finalisedBook.frozen.timestamp)
        continue;

      if (finalisedBook.lastEntryHash == _entryHash)
        return (true, finalisedBook.lastEntryAmountBought);

      // If entry is NOT the last entry, but has the same timestamp, then it is the partial remainder entry.
      if (finalisedBook.lastEntryTimestamp == _entryData.timestamp)
        continue;

      // If entryPrice  > winningPrice, then entry is a winner.
      if (finalisedBook.winningPrice[0].mul(_entryData.buyAmount) < finalisedBook.winningPrice[1].mul(_entryData.sellAmount))
        return (true, _entryData.buyAmount);

      // If entryPrice  < winningPrice, then entry is NOT a winner.
      if (finalisedBook.winningPrice[0].mul(_entryData.buyAmount) != finalisedBook.winningPrice[1].mul(_entryData.sellAmount))
        continue;

      // If entryPrice == winningPrice, then entry is a winner IFF the entry timestamp was before that of the last winner.
      if (finalisedBook.lastEntryTimestamp > _entryData.timestamp)
        return (true, _entryData.buyAmount);
    }
  }
}

// File: contracts/OrderBooksManager.sol

pragma solidity 0.6.7;






contract OrderBooksManager is IERC777Recipient, Owned {
  using SafeMath for uint256;

  bytes32 constant VSC_TOKEN_MANAGER_KEY = keccak256(abi.encodePacked("VSCTokenManager"));

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // precalculated hash - see https://github.com/ethereum/solidity/issues/4024
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  address public immutable vscContract;
  address public immutable vowContract;
  address public artosFTSM;
  LOrderBooks.Market private market;
  mapping (bytes => bool) private proofs;

  event LogOrderBookPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
  event LogOrderBookMinimumVSCAmountUpdated(uint256 oldAmount, uint256 newAmount);
  event LogOrderBookEntryAdded(address indexed vscContract, address indexed from, bytes params, bytes32 indexed orderEntryHash);
  event LogOrderBookEntryRemoved(address indexed vscContract, address indexed from, bytes32 indexed orderEntryHash,
      uint256 returnedAmount);
  event LogOrderBookEntryCompleted(address indexed vscContract, address indexed from, bytes32 indexed orderEntryHash,
      uint256 returnedAmount);
  event LogOrderBookFrozen(address indexed vscContract, uint256 timestamp, uint256 amountBurnedInTier2,
      uint256 amountInIlliquidAccounts, uint256 amountOfVSC);
  event LogOrderBookNotFrozen(address indexed vscContract, string reason);
  event LogOrderBookUnfrozen(address indexed vscContract);
  event LogOrderBookSplitWinner(address indexed vscContract, address indexed seller, bytes32 indexed lastEntryHash,
      uint256 amountBought, bytes32 remainderEntryHash, uint256 remainingSellAmount);
  event LogOrderBookFinalised(address indexed vscContract, uint256 amountBurnedForBook, uint256 amountMintedForBook,
      uint256[2] winningPrice, bytes32 indexed lastEntryHash, uint256 lastEntryAmountBought, uint256 lastEntryTimestamp);

  constructor(address _vscContract)
    public
  {
    vowContract = VSCToken(_vscContract).vowContract();
    vscContract = _vscContract;
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));

    market.period = 30 days;
    market.lastFinalised = now;
    market.minimumVSCAmount = 1000; // 1 * 10^-15 VSC
  }

  modifier proxyCheck(address _from) {
    require(msg.sender == _from || msg.sender == address(this), "Failed proxy check");
    _;
  }

  modifier onlyRegisteredMVD(address _from) {
    require(getVSCTokenManager().registeredMVD(_from), "Registered MVD only");
    _;
  }

  modifier onlyWhenBookIsFrozen() {
     require(market.vowToVSC.isFrozen, "Order book not frozen");
    _;
  }

  modifier onlyWhenBookIsNotFrozen() {
    require(!market.vowToVSC.isFrozen, "Order book is frozen");
    _;
  }

  function getPositionInOrderBook(bytes32 _entryHash)
    external
    view
    returns (uint256 position_)
  {
    position_ = LOrderBooks.getPositionInOrderBook(market, _entryHash);
  }

  function setOrderBooksPeriod(uint256 _orderBooksPeriod)
    external
    onlyOwner
  {
    require(_orderBooksPeriod != 0, "Cannot set 0 period");
    emit LogOrderBookPeriodUpdated(market.period, _orderBooksPeriod);
    market.period = _orderBooksPeriod;
  }

  function setOrderBooksMinimumVSCAmount(uint256 _amount)
    external
    onlyOwner
  {
    emit LogOrderBookMinimumVSCAmountUpdated(market.minimumVSCAmount, _amount);
    market.minimumVSCAmount = _amount;
  }

  function tokensReceived(address /* _operator */, address _from, address /* _to */, uint256 _amount, bytes calldata _data,
      bytes calldata /* _operatorData */)
    external
    override
  {
    // If we just minted to ourselves as a result of finalising the order book then ignore.
    if (_from == address(0)) return;

    if (_amount == 0) {
      require(msg.sender == vscContract, "Cannot proxy for unknown token");
      (bool success,) = address(this).call(_data);
      require(success, "Execution failed");
    } else {
      require(msg.sender == vowContract, "Can only add entry with VOW");
      addOrderBookEntry(_from, _amount, _data);
    }
  }

  function freezeOrderBook(address _from, uint256 _amountBurnedInTier2, uint256 _amountInIlliquidAccounts)
    onlyRegisteredMVD(_from)
    proxyCheck(_from)
    onlyWhenBookIsNotFrozen
    external
  {
    VSCTokenManager vscTokenManager = getVSCTokenManager();

    string memory notFrozenReason = LOrderBooks.freezeOrderBook(market, VSCToken(vscContract).totalSupply(),
        _amountBurnedInTier2, _amountInIlliquidAccounts, vscTokenManager.getLiquidityRatio());

    if (bytes(notFrozenReason).length != 0)
      emit LogOrderBookNotFrozen(vscContract, notFrozenReason);
    else {
      LOrderBooks.Frozen storage frozen = market.frozen;
      emit LogOrderBookFrozen(vscContract, frozen.timestamp, frozen.amountBurnedInTier2, frozen.amountInIlliquidAccounts,
          frozen.amountOfVSC);
    }
  }

  function unfreezeOrderBook(address _from)
    onlyRegisteredMVD(_from)
    proxyCheck(_from)
    onlyWhenBookIsFrozen
    external
  {
    market.vowToVSC.isFrozen = false;
    emit LogOrderBookUnfrozen(vscContract);
  }

  function getFinaliseOrderBookParams()
    onlyWhenBookIsFrozen
    external
    view
    returns (bytes memory encodedParams_)
  {
    encodedParams_ = LOrderBooks.getFinaliseOrderBookParams(market);
  }

  function finaliseOrderBook(address _from, bytes calldata _encodedParams)
    onlyRegisteredMVD(_from)
    proxyCheck(_from)
    onlyWhenBookIsFrozen
    external
  {
    LOrderBooks.finaliseOrderBook(vscContract, market, _encodedParams);

    LOrderBooks.OrderBook storage orderBook = market.vowToVSC;
    LOrderBooks.FinalisedBook storage finalisedBook = orderBook.finalisedBooks[orderBook.finalisedBooks.length.sub(1)];
    VSCToken(vscContract).mint(address(this), finalisedBook.amountMintedForBook);
    VOWToken(vowContract).burn(finalisedBook.amountBurnedForBook, "");

    orderBook.isFrozen = false;
    market.lastFinalised = now;

    emit LogOrderBookFinalised(vscContract, finalisedBook.amountBurnedForBook, finalisedBook.amountMintedForBook,
        finalisedBook.winningPrice, finalisedBook.lastEntryHash, finalisedBook.lastEntryAmountBought,
        finalisedBook.lastEntryTimestamp);
  }

  function getAddEntryToOrderBookParams(uint256 _sellAmount, uint256 _buyAmount)
    onlyWhenBookIsNotFrozen
    external
    view
    returns (bytes memory encodedOrderBookSaleParams_)
  {
    return LOrderBooks.getAddEntryToOrderBookParams(market, _sellAmount, _buyAmount);
  }

  function removeOrder(address _from, bytes32 _orderBookEntryHash)
    proxyCheck(_from)
    onlyWhenBookIsNotFrozen
    external
  {
    uint256 amountToReturn = LOrderBooks.removeEntryFromOrderBook(market, _orderBookEntryHash, _from);

    VOWToken(vowContract).send(_from, amountToReturn, "");

    emit LogOrderBookEntryRemoved(vscContract, _from, _orderBookEntryHash, amountToReturn);
  }

  function completeOrder(address _from, bytes32 _orderBookEntryHash)
    proxyCheck(_from)
    onlyWhenBookIsNotFrozen
    external
  {
    uint256 amountToReturn = LOrderBooks.completeEntryFromFinalisedBook(market, _orderBookEntryHash, _from);
    VSCToken(vscContract).send(_from, amountToReturn, "");

    emit LogOrderBookEntryCompleted(vscContract, _from, _orderBookEntryHash, amountToReturn);
  }

  function getVSCTokenManager()
    private
    view
    returns (VSCTokenManager vscTokenManager_)
  {
    vscTokenManager_ = VSCTokenManager(VSCToken(vscContract).partnerContracts(VSC_TOKEN_MANAGER_KEY));
  }

  function addOrderBookEntry(address _from, uint256 _amount, bytes memory _params)
    onlyWhenBookIsNotFrozen
    private
  {
    bytes32 orderEntryHash = LOrderBooks.addEntryToOrderBook(market, _from, _amount,
        _params);

    emit LogOrderBookEntryAdded(vscContract, _from, _params, orderEntryHash);
  }
}