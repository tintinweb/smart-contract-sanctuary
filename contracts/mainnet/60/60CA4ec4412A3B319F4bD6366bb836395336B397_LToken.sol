// File: contracts\thirdParty\interfaces\IERC1820Registry.sol

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

// File: contracts\interfaces\IERC777Sender.sol

pragma solidity 0.6.7;

// As defined in the 'ERC777TokensSender And The tokensToSend Hook' section of https://eips.ethereum.org/EIPS/eip-777
interface IERC777Sender {
  function tokensToSend(address operator, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata operatorData) external;
}

// File: contracts\interfaces\IERC777Recipient.sol

pragma solidity 0.6.7;

// As defined in the 'ERC777TokensRecipient And The tokensReceived Hook' section of https://eips.ethereum.org/EIPS/eip-777
interface IERC777Recipient {
  function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata operatorData) external;
}

// File: contracts\thirdParty\SafeMath.sol

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

// File: contracts\libraries\LToken.sol

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