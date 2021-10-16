/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// File contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}


// File contracts/libraries/Address.sol

pragma solidity 0.7.5;


// TODO(zx): replace with OZ implementation.
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}


// File contracts/interfaces/IERC20.sol

pragma solidity 0.7.5;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/SafeERC20.sol

pragma solidity 0.7.5;


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IOwnable.sol

pragma solidity 0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}


// File contracts/interfaces/IERC20Metadata.sol

pragma solidity 0.7.5;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


// File contracts/interfaces/IOHMERC20.sol

pragma solidity 0.7.5;

interface IOHMERC20 is IERC20 {
    function mint( uint256 amount_ ) external;
    function mint( address account_, uint256 ammount_ ) external;
    function burnFrom(address account_, uint256 amount_) external;
}


// File contracts/interfaces/IBondingCalculator.sol


pragma solidity 0.7.5;

interface IBondingCalculator {
    function markdown( address _LP ) external view returns ( uint );

    function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}


// File contracts/types/Ownable.sol

pragma solidity 0.7.5;

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}


// File contracts/Treasury.sol

pragma solidity 0.7.5;






contract OlympusTreasury is Ownable {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint;
    using SafeERC20 for IERC20;



    /* ========== EVENTS ========== */

    event Deposit( address indexed token, uint amount, uint value );
    event Withdrawal( address indexed token, uint amount, uint value );
    event CreateDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event RepayDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event ReservesManaged( address indexed token, uint amount );
    event ReservesAudited( uint indexed totalReserves );
    event Minted( address indexed caller, address indexed recipient, uint amount );
    event PermissionQueued( STATUS indexed status, address queued );
    event Permissioned( address addr, STATUS indexed status, bool result );



    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN, 
        RESERVEMANAGER, 
        LIQUIDITYDEPOSITOR, 
        LIQUIDITYTOKEN, 
        LIQUIDITYMANAGER, 
        DEBTOR, 
        REWARDMANAGER, 
        SOHM 
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address calculator;
        uint timelockEnd;
        bool nullify;
        bool executed;
    }



    /* ========== STATE VARIABLES ========== */

    IOHMERC20 immutable OHM;
    IERC20 public sOHM;

    mapping( STATUS => address[] ) public registry;
    mapping( STATUS => mapping( address => bool ) ) public permissions;
    mapping( address => address ) public bondCalculator;

    mapping( address => uint ) public debtorBalance;
    
    uint public totalReserves;
    uint public totalDebt;

    Queue[] public permissionQueue;
    uint public immutable blocksNeededForQueue;

    bool public onChainGoverned;
    uint public onChainGovernanceTimelock;



    /* ========== CONSTRUCTOR ========== */

    constructor ( address _OHM, uint _timelock ) {
        require( _OHM != address(0) );
        OHM = IOHMERC20( _OHM );
        
        blocksNeededForQueue = _timelock;
    }



    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
        @notice allow approved address to deposit an asset for OHM
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ ) {
        if ( permissions[ STATUS.RESERVETOKEN ][ _token ] ) {
            require( permissions[ STATUS.RESERVEDEPOSITOR ][ msg.sender ], "Not approved" );
        } else if ( permissions[ STATUS.LIQUIDITYTOKEN ][ _token ] ) {
            require( permissions[ STATUS.LIQUIDITYDEPOSITOR ][ msg.sender ], "Not approved" );
        } else {
            require( 1 == 0 ); // guarantee revert
        }

        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        uint value = valueOfToken( _token, _amount );
        // mint OHM needed and store amount of rewards for distribution
        send_ = value.sub( _profit );
        OHM.mint( msg.sender, send_ );

        totalReserves = totalReserves.add( value );

        emit Deposit( _token, _amount, value );
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw( uint _amount, address _token ) external {
        require( permissions[ STATUS.RESERVETOKEN ][ _token ], "Not accepted" ); // Only reserves can be used for redemptions
        require( permissions[ STATUS.RESERVESPENDER ][ msg.sender ] == true, "Not approved" );

        uint value = valueOfToken( _token, _amount );
        OHM.burnFrom( msg.sender, value );

        totalReserves = totalReserves.sub( value );

        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit Withdrawal( _token, _amount, value );
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
    function incurDebt( uint _amount, address _token ) external {
        require( permissions[ STATUS.DEBTOR ][ msg.sender ], "Not approved" );
        require( permissions[ STATUS.RESERVETOKEN ][ _token ], "Not accepted" );

        uint value = valueOfToken( _token, _amount );
        require( value != 0 );

        uint availableDebt = sOHM.balanceOf( msg.sender ).sub( debtorBalance[ msg.sender ] );
        require( value <= availableDebt, "Exceeds debt limit" );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].add( value );
        totalDebt = totalDebt.add( value );

        totalReserves = totalReserves.sub( value );

        IERC20( _token ).transfer( msg.sender, _amount );
        
        emit CreateDebt( msg.sender, _token, _amount, value );
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
    function repayDebtWithReserve( uint _amount, address _token ) external {
        require( permissions[ STATUS.DEBTOR ][ msg.sender ], "Not approved" );
        require( permissions[ STATUS.RESERVETOKEN ][ _token ], "Not accepted" );

        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        uint value = valueOfToken( _token, _amount );
        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( value );
        totalDebt = totalDebt.sub( value );

        totalReserves = totalReserves.add( value );

        emit RepayDebt( msg.sender, _token, _amount, value );
    }

    /**
        @notice allow approved address to repay borrowed reserves with OHM
        @param _amount uint
     */
    function repayDebtWithOHM( uint _amount ) external {
        require( permissions[ STATUS.DEBTOR ][ msg.sender ], "Not approved" );

        OHM.burnFrom( msg.sender, _amount );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( _amount );
        totalDebt = totalDebt.sub( _amount );

        emit RepayDebt( msg.sender, address( OHM ), _amount, _amount );
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage( address _token, uint _amount ) external {
        if( permissions[ STATUS.LIQUIDITYTOKEN ][ _token ] ) {
            require( permissions[ STATUS.LIQUIDITYMANAGER ][ msg.sender ], "Not approved" );
        } else {
            require( permissions[ STATUS.RESERVEMANAGER ][ msg.sender ], "Not approved" );
        }

        uint value = valueOfToken( _token, _amount );
        require( value <= excessReserves(), "Insufficient reserves" );

        totalReserves = totalReserves.sub( value );

        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit ReservesManaged( _token, _amount );
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mint( address _recipient, uint _amount ) external {
        require( permissions[ STATUS.REWARDMANAGER ][ msg.sender ], "Not approved" );
        require( _amount <= excessReserves(), "Insufficient reserves" );

        OHM.mint( _recipient, _amount );

        emit Minted( msg.sender, _recipient, _amount );
    } 



    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyOwner() {
        uint reserves;
        address[] memory reserveToken = registry[ STATUS.RESERVETOKEN ];
        for( uint i = 0; i < reserveToken.length; i++ ) {
            reserves = reserves.add ( 
                valueOfToken( reserveToken[ i ], IERC20( reserveToken[ i ] ).balanceOf( address(this) ) )
            );
        }
        address[] memory liquidityToken = registry[ STATUS.LIQUIDITYTOKEN ];
        for( uint i = 0; i < liquidityToken.length; i++ ) {
            reserves = reserves.add (
                valueOfToken( liquidityToken[ i ], IERC20( liquidityToken[ i ] ).balanceOf( address(this) ) )
            );
        }
        totalReserves = reserves;
        emit ReservesAudited( reserves );
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable( STATUS _status, address _address, address _calculator ) external onlyOwner() {
        require( onChainGoverned, "OCG Not Enabled: Use queueTimelock" );
        if ( _status == STATUS.SOHM ) { // 9
            sOHM = IERC20( _address );
        } else {
            registry[ _status ].push( _address );
            permissions[ _status ][ _address ] = true;
            
            if ( _status == STATUS.LIQUIDITYTOKEN ) { // 5
                bondCalculator[ _address ] = _calculator;
            }
        }
        emit Permissioned( _address, _status, true );
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable( STATUS _status, address _toDisable ) external onlyOwner() {
        permissions[ _status ][ _toDisable ] = false;
        emit Permissioned( _toDisable, _status, false );
    }



    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
        @notice queue address to receive permission
        @param _status STATUS
        @param _address address
     */
    function queueTimelock( STATUS _status, address _address, address _calculator ) external onlyOwner() {
        require( _address != address(0) );
        require( !onChainGoverned, "OCG Enabled: Use enable" );

        uint timelock = block.number.add( blocksNeededForQueue );
        if ( _status == STATUS.RESERVEMANAGER || _status == STATUS.LIQUIDITYMANAGER ) {
            timelock = block.number.add( blocksNeededForQueue.mul( 2 ) );
        }
        permissionQueue.push( Queue({
            managing: _status,
            toPermit: _address,
            calculator: _calculator,
            timelockEnd: timelock,
            nullify: false,
            executed: false
        } ) );
        emit PermissionQueued( _status, _address );
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint
     */
    function execute( uint _index ) external {
        require( !onChainGoverned );

        Queue memory info = permissionQueue[ _index ];

        require( !info.nullify, "Action has been nullified" );
        require( !info.executed, "Action has already been executed" );
        require( block.number >= info.timelockEnd, "Timelock not complete" );

        if ( info.managing == STATUS.SOHM ) { // 9
            sOHM = IERC20( info.toPermit );
        } else {
            registry[ info.managing ].push( info.toPermit );
            permissions[ info.managing ][ info.toPermit ] = true;
            
            if ( info.managing == STATUS.LIQUIDITYTOKEN ) { // 5
                bondCalculator[ info.toPermit ] = info.calculator;
            }
        }
        permissionQueue[ _index ].executed = true;
        emit Permissioned( info.toPermit, info.managing, true );
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint
     */
    function nullify( uint _index ) external onlyOwner() {
        permissionQueue[ _index ].nullify = true;
    }

    /**
     * @notice disables timelocked functions
     */
    function enableOnChainGovernance() external onlyOwner() {
        if( onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number ) {
            onChainGoverned = true;
        } else {
            onChainGovernanceTimelock = block.number.add( blocksNeededForQueue.mul(7) ); // 7-day timelock
        }
    }



    /* ========== VIEW FUNCTIONS ========== */

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns ( uint ) {
        return totalReserves.sub( OHM.totalSupply().sub( totalDebt ) );
    }

    /**
        @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken( address _token, uint _amount ) public view returns ( uint value_ ) {
        value_ = _amount.mul( 10 ** IERC20Metadata( address(OHM) ).decimals() )
                    .div( 10 ** IERC20Metadata( _token ).decimals() );
        
        if ( permissions[ STATUS.LIQUIDITYTOKEN ][ _token ] ) {
            value_ = IBondingCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }
}