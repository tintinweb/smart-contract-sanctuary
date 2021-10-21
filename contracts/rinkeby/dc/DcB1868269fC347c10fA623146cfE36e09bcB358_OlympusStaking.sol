/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

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


// File contracts/interfaces/IgOHM.sol

pragma solidity 0.7.5;

interface IgOHM is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sOHM ) external;
}


// File contracts/interfaces/IDistributor.sol

pragma solidity 0.7.5;

interface IDistributor {
    function distribute() external returns ( bool );
}


// File contracts/interfaces/IGovernable.sol

pragma solidity 0.7.5;


interface IGovernable {
    function governor() external view returns (address);

    function renounceGovernor() external;
  
    function pushGovernor( address newGovernor_ ) external;

    function pullGovernor() external;
}


// File contracts/types/Governable.sol

pragma solidity 0.7.5;

contract Governable is IGovernable {

    address internal _governor;
    address internal _newGovernor;


    event GovernorPushed(address indexed previousGovernor, address indexed newGovernor);
    event GovernorPulled(address indexed previousGovernor, address indexed newGovernor);


    constructor () {
        _governor = msg.sender;
        emit GovernorPulled( address(0), _governor );
    }

    /* ========== GOVERNOR ========== */

    function governor() public view override returns (address) {
        return _governor;
    }

    modifier onlyGovernor() {
        require( _governor == msg.sender, "Governable: caller is not the governor" );
        _;
    }

    function renounceGovernor() public virtual override onlyGovernor() {
        emit GovernorPushed( _governor, address(0) );
        _governor = address(0);
    }

    function pushGovernor( address newGovernor_ ) public virtual override onlyGovernor() {
        require( newGovernor_ != address(0), "Governable: new governor is the zero address");
        emit GovernorPushed( _governor, newGovernor_ );
        _newGovernor = newGovernor_;
    }
    
    function pullGovernor() public virtual override {
        require( msg.sender == _newGovernor, "Governable: must be new governor to pull");
        emit GovernorPulled( _governor, _newGovernor );
        _governor = _newGovernor;
    }
}


// File contracts/Staking.sol

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;





contract OlympusStaking is Governable {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsOHM;
    using SafeERC20 for IgOHM;



    /* ========== EVENTS ========== */

    event gOHMSet( address gOHM );
    event DistributorSet( address distributor );
    event WarmupSet( uint warmup );

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }

    enum CONTRACTS { DISTRIBUTOR, gOHM }



    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable OHM;
    IsOHM public immutable sOHM;
    IgOHM public gOHM;

    Epoch public epoch;

    address public distributor;

    mapping( address => Claim ) public warmupInfo;
    uint public warmupPeriod;
    uint gonsInWarmup;

    

    /* ========== CONSTRUCTOR ========== */
    
    constructor ( 
        address _OHM, 
        address _sOHM, 
        uint _epochLength,
        uint _firstEpochNumber,
        uint _firstEpochBlock
    ) {
        require( _OHM != address(0) );
        OHM = IERC20( _OHM );
        require( _sOHM != address(0) );
        sOHM = IsOHM( _sOHM );
        
        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endBlock: _firstEpochBlock,
            distribute: 0
        });
    }

    

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake OHM to enter warmup
     * @param _amount uint
     * @param _recipient address
     * @param _claim bool
     * @param _rebasing bool
     */
    function stake( uint _amount, address _recipient, bool _rebasing, bool _claim ) external returns ( uint ) {
        rebase();

        OHM.safeTransferFrom( msg.sender, address(this), _amount );

        if ( _claim && warmupPeriod == 0 ) {
            return _send( _recipient, _amount, _rebasing );

        } else {
            Claim memory info = warmupInfo[ _recipient ];

            if ( !info.lock ) {
                require( _recipient == msg.sender, "External deposits for account are locked" );
            }

            warmupInfo[ _recipient ] = Claim ({
                deposit: info.deposit.add( _amount ),
                gons: info.gons.add( sOHM.gonsForBalance( _amount ) ),
                expiry: epoch.number.add( warmupPeriod ),
                lock: info.lock
            });

            gonsInWarmup = gonsInWarmup.add( sOHM.gonsForBalance( _amount ) );

            return _amount;
        }
    }

    /**
     * @notice retrieve stake from warmup
     * @param _recipient address
     * @param _rebasing bool
     */
    function claim ( address _recipient, bool _rebasing ) public returns ( uint ) {
        Claim memory info = warmupInfo[ _recipient ];

        if ( !info.lock ) {
            require( _recipient == msg.sender, "External claims for account are locked" );
        }

        if ( epoch.number >= info.expiry && info.expiry != 0 ) {
            delete warmupInfo[ _recipient ];

            gonsInWarmup = gonsInWarmup.sub( info.gons );

            return _send( _recipient, sOHM.balanceForGons( info.gons ), _rebasing );
        }
        return 0;
    }

    /**
     * @notice forfeit stake and retrieve OHM
     */
    function forfeit() external returns ( uint ) {
        Claim memory info = warmupInfo[ msg.sender ];
        delete warmupInfo[ msg.sender ];

        gonsInWarmup = gonsInWarmup.sub( info.gons );

        OHM.safeTransfer( msg.sender, info.deposit );

        return info.deposit;
    }

    /**
     * @notice prevent new deposits or claims from ext. address (protection from malicious activity)
     */
    function toggleLock() external {
        warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
    }

    /**
     * @notice redeem sOHM for OHM
     * @param _amount uint
     * @param _trigger bool
     * @param _rebasing bool
     */
    function unstake( uint _amount, bool _trigger, bool _rebasing ) external returns ( uint ) {
        if ( _trigger ) {
            rebase();
        }

        uint amount = _amount;
        if ( _rebasing ) {
            sOHM.safeTransferFrom( msg.sender, address(this), _amount );
        } else {
            gOHM.burn( msg.sender, _amount ); // amount was given in gOHM terms
            amount = gOHM.balanceFrom( _amount ); // convert amount to OHM terms
        }
        
        OHM.safeTransfer( msg.sender, amount );

        return amount;
    }

    /**
     * @notice convert _amount sOHM into gBalance_ gOHM
     * @param _amount uint
     * @return gBalance_ uint
     */
    function wrap( uint _amount ) external returns ( uint gBalance_ ) {
        sOHM.safeTransferFrom( msg.sender, address(this), _amount );

        gBalance_ = gOHM.balanceTo( _amount );
        gOHM.mint( msg.sender, gBalance_ );
    }

    /**
     * @notice convert _amount gOHM into sBalance_ sOHM
     * @param _amount uint
     * @return sBalance_ uint
     */
    function unwrap( uint _amount ) external returns ( uint sBalance_ ) {
        gOHM.burn( msg.sender, _amount );

        sBalance_ = gOHM.balanceFrom( _amount );
        sOHM.safeTransfer( msg.sender, sBalance_ );
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if( epoch.endBlock <= block.number ) {
            sOHM.rebase( epoch.distribute, epoch.number );

            epoch.endBlock = epoch.endBlock.add( epoch.length );
            epoch.number++;
            
            if ( distributor != address(0) ) {
                IDistributor( distributor ).distribute();
            }

            if( contractBalance() <= totalStaked() ) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = contractBalance().sub( totalStaked() );
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sOHM or gOHM
     * @param _recipient address
     * @param _amount uint
     * @param _rebasing bool
     */
    function _send( address _recipient, uint _amount, bool _rebasing ) internal returns ( uint ) {
        if ( _rebasing ) {
            sOHM.safeTransfer( _recipient, _amount ); // send as sOHM (equal unit as OHM)
            return _amount;
        } else {
            gOHM.mint( _recipient, gOHM.balanceTo( _amount ) ); // send as gOHM (convert units from OHM)
            return gOHM.balanceTo( _amount );
        }
    }



    /* ========== VIEW FUNCTIONS ========== */

    /**
        @notice returns the sOHM index, which tracks rebase growth
        @return uint
     */
    function index() public view returns ( uint ) {
        return sOHM.index();
    }

    /**
        @notice returns contract OHM holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns ( uint ) {
        return OHM.balanceOf( address(this) );
    }

    function totalStaked() public view returns ( uint ) {
        return sOHM.circulatingSupply();
    }

    function supplyInWarmup() public view returns ( uint ) {
        return sOHM.balanceForGons( gonsInWarmup );
    }



    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
    function setContract( CONTRACTS _contract, address _address ) external onlyGovernor() {
        if( _contract == CONTRACTS.DISTRIBUTOR ) { // 0
            distributor = _address;
            emit DistributorSet( _address );
        } else if ( _contract == CONTRACTS.gOHM ) { // 1
            require( address( gOHM ) == address( 0 ) ); // only set once
            gOHM = IgOHM( _address );
            emit gOHMSet( _address );
        }
    }
    
    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup( uint _warmupPeriod ) external onlyGovernor() {
        warmupPeriod = _warmupPeriod;
        emit WarmupSet( _warmupPeriod );
    }
}