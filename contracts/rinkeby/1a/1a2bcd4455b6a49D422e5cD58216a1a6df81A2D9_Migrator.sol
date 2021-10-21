/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

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


// File contracts/interfaces/IsOHM.sol

pragma solidity 0.7.5;

interface IsOHM is IERC20 {
    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external override view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );
    
    function index() external view returns ( uint );
}


// File contracts/interfaces/IwsOHM.sol

pragma solidity 0.7.5;

// Old wsOHM interface
interface IwsOHM is IERC20 {
  function wrap(uint256 _amount) external returns (uint256);

  function unwrap(uint256 _amount) external returns (uint256);

  function wOHMTosOHM(uint256 _amount) external view returns (uint256);

  function sOHMTowOHM(uint256 _amount) external view returns (uint256);
}


// File contracts/interfaces/IgOHM.sol

pragma solidity 0.7.5;

interface IgOHM is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sOHM ) external;
}


// File contracts/interfaces/ITreasury.sol

pragma solidity 0.7.5;


interface ITreasury {

    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint );
    
    function withdraw( uint _amount, address _token ) external;

    function tokenValue( address _token, uint _amount ) external view returns ( uint value_ );
  
    function mint( address _recipient, uint _amount ) external;

    function manage( address _token, uint _amount ) external;

    function incurDebt( uint amount_, address token_ ) external;
    
    function repayDebtWithReserve( uint amount_, address token_ ) external;

    function excessReserves() external view returns ( uint );
}


// File contracts/interfaces/IStaking.sol

pragma solidity 0.7.5;

interface IStaking {

    function stake( uint _amount, address _recipient, bool _rebasing, bool _claim ) external returns ( uint );

    function claim ( address _recipient, bool _rebasing ) external returns ( uint );

    function forfeit() external returns ( uint );

    function toggleLock() external;

    function unstake( uint _amount, bool _trigger, bool _rebasing ) external returns ( uint );

    function wrap( uint _amount ) external returns ( uint gBalance_ );

    function unwrap( uint _amount ) external returns ( uint sBalance_ );

    function rebase() external;

    function index() external view returns ( uint );

    function contractBalance() external view returns ( uint );

    function totalStaked() external view returns ( uint );

    function supplyInWarmup() external view returns ( uint );
}


// File contracts/interfaces/IOwnable.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}


// File contracts/interfaces/IUniswapV2Router.sol

pragma solidity 0.7.5;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity);
        
    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
        ) external returns (uint amountA, uint amountB);
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


// File contracts/libraries/SafeMath.sol

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


// File contracts/migration/TokenMigrator.sol

pragma solidity 0.7.5;









interface IRouter {
    function addLiquidity(
        address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity);
        
    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
        ) external returns (uint amountA, uint amountB);
}

interface IStakingV1 {
    function unstake( uint _amount, bool _trigger ) external;

    function index() external view returns ( uint );
}

contract Migrator is Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using SafeERC20 for IgOHM;
    using SafeERC20 for IsOHM;

    /* ========== MIGRATION ========== */

    event TimelockStarted( uint block, uint end );
    event Migrated( address staking, address treasury );
    event Funded( uint amount );
    event Defunded( uint amount );

    /* ========== STATE VARIABLES ========== */

    struct Token {
        address token;
        bool reserveToken;
    }

    struct LPToken {
        address token;
        address tokenA;
        address tokenB;
        bool sushi;
    }

    Token[] public tokens;
    LPToken[] public lpTokens;

    IERC20 public immutable oldOHM;
    IsOHM public immutable oldsOHM;
    IwsOHM public immutable oldwsOHM;
    ITreasury public immutable oldTreasury;
    IStakingV1 public immutable oldStaking;

    IRouter public immutable sushiRouter;
    IRouter public immutable uniRouter;

    IgOHM public gOHM;
    ITreasury public newTreasury;
    IStaking public newStaking;
    IERC20 public newOHM;

    IERC20 public immutable DAI;

    bool public ohmMigrated;
    uint public immutable timelockLength;
    uint public timelockEnd;

    uint public oldSupply;
    

    constructor(
        address _oldOHM,
        address _oldsOHM,
        address _oldTreasury,
        address _oldStaking,
        address _oldwsOHM,
        address _DAI,
        address _sushi,
        address _uni,
        uint _timelock
    ) {
        require( _oldOHM != address(0) );
        oldOHM = IERC20( _oldOHM );
        require( _oldsOHM != address(0) );
        oldsOHM = IsOHM( _oldsOHM );
        require( _oldTreasury != address(0) );
        oldTreasury = ITreasury( _oldTreasury );
        require( _oldStaking != address(0) );
        oldStaking = IStakingV1( _oldStaking );
        require( _oldwsOHM != address(0) );
        oldwsOHM = IwsOHM( _oldwsOHM );
        require( _DAI != address(0) );
        DAI = IERC20( _DAI );
        require( _sushi != address(0) );
        sushiRouter = IRouter(_sushi);
        require( _uni != address(0) );
        uniRouter = IRouter(_uni);
        timelockLength = _timelock;
    }

    /* ========== MIGRATION ========== */

    enum TYPE { UNSTAKED, STAKED, WRAPPED }

    // migrate OHM, sOHM, or wsOHM for gOHM
    function migrate( uint _amount, TYPE _from ) external {
        uint sAmount = _amount;
        uint wAmount = oldwsOHM.sOHMTowOHM( _amount );

        if ( _from == TYPE.UNSTAKED ) {
            oldOHM.safeTransferFrom( msg.sender, address(this), _amount );
        } else if ( _from == TYPE.STAKED ) {
            oldsOHM.safeTransferFrom( msg.sender, address(this), _amount );
        } else if ( _from == TYPE.WRAPPED ) {
            oldwsOHM.transferFrom( msg.sender, address(this), _amount );
            wAmount = _amount;
            sAmount = oldwsOHM.wOHMTosOHM( _amount );
        }

        if( ohmMigrated ) {
            require( oldSupply >= oldOHM.totalSupply(), "OHMv1 minted" );
            gOHM.safeTransfer( msg.sender, wAmount );
        } else {
            gOHM.mint( msg.sender, wAmount );
        }
    }

    // bridge back to OHM, sOHM, or wsOHM
    function bridgeBack( uint _amount, TYPE _to ) external {
        gOHM.burn( msg.sender, _amount );

        uint amount = oldwsOHM.wOHMTosOHM( _amount );
        // error throws if contract does not have enough of type to send
        if ( _to == TYPE.UNSTAKED ) {
            oldOHM.safeTransfer( msg.sender, amount );
        } else if ( _to == TYPE.STAKED ) {
            oldsOHM.safeTransfer( msg.sender, amount );
        } else if ( _to == TYPE.WRAPPED ) {
            oldwsOHM.transfer( msg.sender, _amount );
        }
    }

    /* ========== OWNABLE ========== */

    /**
    *   @notice adds tokens to tokens array
    *   @param _tokens address[]
    *   @param _reserveToken bool[]
    */
    function addTokens( address[] memory _tokens, bool[] memory _reserveToken  ) external onlyOwner() {
        require(_tokens.length == _reserveToken.length);

        for( uint i = 0; i < _tokens.length; i++ ) {
            tokens.push( Token({
                token: _tokens[i],
                reserveToken: _reserveToken[i]
            }));
        }
    }

    /**
    *   @notice adds tokens to tokens array
    *   @param _tokens address[]
    *   @param _tokenA address[]
    *   @param _tokenB address[]
    *   @param _sushi bool[]
    */
    function addLPTokens( address[] memory _tokens, address[] memory _tokenA, address[] memory _tokenB, bool[] memory _sushi  ) external onlyOwner() {
        require(_tokens.length == _sushi.length);

        for( uint i = 0; i < _tokens.length; i++ ) {
            lpTokens.push( LPToken({
                token: _tokens[i],
                tokenA: _tokenA[i],
                tokenB: _tokenB[i],
                sushi: _sushi[i]
            }));
        }
    }

    // withdraw backing of migrated OHM
    function defund() external onlyOwner() {
        require( ohmMigrated && timelockEnd < block.number && timelockEnd != 0 );
        oldwsOHM.unwrap( oldwsOHM.balanceOf( address(this) ) );
        oldStaking.unstake( oldsOHM.balanceOf( address(this) ), false );

        uint balance = oldOHM.balanceOf( address(this) );

        oldSupply = oldSupply.sub( balance );

        oldTreasury.withdraw( balance.mul( 1e9 ), address(DAI) );
        DAI.safeTransfer( address(newTreasury), DAI.balanceOf( address(this) ) ); 

        emit Defunded( balance );
    }

    // start timelock to send backing to new treasury
    function startTimelock() external onlyOwner() {
        timelockEnd = block.number.add( timelockLength );

        emit TimelockStarted( block.number, timelockEnd );
    }

    // set gOHM address
    function setgOHM( address _gOHM ) external onlyOwner() {
        require( address(gOHM) == address(0) );
        require( _gOHM != address(0) );

        gOHM = IgOHM( _gOHM );
    }

    // migrate contracts
    function migrateContracts( 
        address _newTreasury, 
        address _newStaking, 
        address _newOHM, 
        address _newsOHM
    ) external onlyOwner() {
        ohmMigrated = true;

        require( _newTreasury != address(0) );
        newTreasury = ITreasury( _newTreasury );
        require( _newStaking != address(0) );
        newStaking = IStaking( _newStaking );
        require( _newOHM != address(0) );
        newOHM = IERC20( _newOHM );

        oldSupply = oldOHM.totalSupply(); // log total supply at time of migration

        gOHM.migrate( _newStaking, _newsOHM ); // change gOHM minter

        _migrateLP();
        _migrateTokens();

        fund( oldsOHM.circulatingSupply() ); // fund with current staked supply for token migration
        
        emit Migrated( _newStaking, _newTreasury );
    }



    /* ========== INTERNAL FUNCTIONS ========== */

    // fund contract with gOHM 
    function fund( uint _amount ) internal {
        newTreasury.mint( address(this), _amount );
        newOHM.approve( address( newStaking ), _amount );
        newStaking.stake( _amount, address(this), false, true ); // stake and claim gOHM

        emit Funded( _amount );
    }

    /**
    *   @notice Migrates tokens from old treasury to new treasury
    */
    function _migrateTokens() internal {
        for( uint i = 0; i < tokens.length; i++ ) {
            Token memory _token = tokens[i];

            uint balance = IERC20(_token.token).balanceOf( address(oldTreasury) );

            uint excessReserves = oldTreasury.excessReserves();
            uint tokenValue = newTreasury.tokenValue(_token.token, balance);

            if ( tokenValue > excessReserves ) {
                tokenValue = excessReserves;
                balance = excessReserves * 10 ** 9;
            }

            oldTreasury.manage( _token.token, balance );

            if(_token.reserveToken) {

                IERC20(_token.token).approve(address(newTreasury), balance);
                newTreasury.deposit(balance, _token.token, tokenValue);
            } else {
                IERC20(_token.token).transfer( address(newTreasury), balance );
            }
        }
    }
    
    /**
    *   @notice Migrates LPs to be paired with new OHM and is sent to new treasury
    */
    function _migrateLP() internal {
        for( uint i = 0; i < lpTokens.length; i++ ) {
            LPToken memory _token = lpTokens[i];

            uint oldLPAmount = IERC20(_token.token).balanceOf(address(oldTreasury));
            oldTreasury.manage(_token.token, oldLPAmount);

            if(_token.sushi) {
                IERC20(_token.token).approve(address(sushiRouter), oldLPAmount);
                (uint amountA, uint amountB) = sushiRouter.removeLiquidity(_token.tokenA, _token.tokenB, oldLPAmount, 0, 0, address(this), 1000000000000);
                
                oldOHM.approve(address(oldTreasury), amountB);
                oldTreasury.withdraw(amountB * 10 ** 9, _token.token);
                
                IERC20(_token.token).approve(address(newTreasury), amountB * 10 ** 9);
                newTreasury.deposit(amountB * 10 ** 9, _token.token, 0);
                
                IERC20(_token.token).approve(address(sushiRouter), amountA);
                newOHM.approve(address(sushiRouter), amountB);

                sushiRouter.addLiquidity(_token.token, address(newOHM), amountA, amountB, amountA, amountB, address(newTreasury), 100000000000);
            } else {
                IERC20(_token.token).approve(address(uniRouter), oldLPAmount);
                (uint amountA, uint amountB) = uniRouter.removeLiquidity(_token.tokenA, _token.tokenB, oldLPAmount, 0, 0, address(this), 1000000000000);
                
                oldOHM.approve(address(oldTreasury), amountB);
                oldTreasury.withdraw(amountB * 10 ** 9, _token.token);
                
                IERC20(_token.token).approve(address(newTreasury), amountB * 10 ** 9);
                newTreasury.deposit(amountB * 10 ** 9, _token.token, 0);
                
                IERC20(_token.token).approve(address(uniRouter), amountA);
                newOHM.approve(address(uniRouter), amountB);

                uniRouter.addLiquidity(_token.token, address(newOHM), amountA, amountB, amountA, amountB, address(newTreasury), 100000000000);
            }
        
        }
    }
}