/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// File: libraries/Address.sol


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
// File: libraries/SafeMath.sol


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
// File: interfaces/IERC20.sol


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

// File: libraries/SafeERC20.sol


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
// File: interfaces/IOwnable.sol


pragma solidity 0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
// File: types/Ownable.sol


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

// File: dai_flat.sol


pragma solidity 0.7.5;






interface ITreasury {
    function manage( address token, uint amount ) external;

    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ );

    function incurDebt( uint _amount, address _token ) external;

    function repayDebtWithReserve( uint _amount, address _token ) external;

    function repayDebtWithOHM( uint _amount ) external;
}

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim ( address _recipient ) external;
    function unstake( uint _amount, bool _trigger ) external;
}

interface IRouter02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IwsOHM {
    function wOHMTosOHM( uint _amount ) external view returns ( uint );
    function sOHMTowOHM( uint _amount ) external view returns ( uint );
}

interface IOHMIE is IERC20 {
    function mint(address to, uint amount) external;
}

// The LP debt facility is the hearth of OhmieSwap. It allows users to borrow OHM against
// their sOHM, which removes the opportunity cost of unstaking and encourages them to LP.

contract LPDebtFacility is Ownable {
    
    using SafeERC20 for IERC20;
    using SafeERC20 for IOHMIE;
    using SafeMath for uint;

    event Check(uint i);

    /* ========== STRUCTS ========== */

    struct UserInfo {
        uint balance; // staked balance (wsOHM)
        uint last; // last balance (OHM)
        uint debt; // OHM borrowed
        uint lp; // How many LP tokens the user has created.
        uint rewardDebt; // Reward debt. See explanation below.
    }

    struct Info {
        uint balance; // total staked (in wsOHM)
        uint last; // last total balance (in OHM)
        uint debt; // total OHM borrowed
        uint ceiling; // debt ceiling
        uint lp; // total LP deposited
        IERC20 lpToken; // pool token
        uint accrued; // fees accrued (in wsOHM)
        uint rewardPerBlock; // OHMIE rewards per block
        uint lastRewardBlock; // last update
        uint accOhmiePerShare; // accumulated OHMIE per share, times 1e12.
    }



    /* ========== STATE VARIABLES ========== */

    IwsOHM immutable wsOHM; // Used for conversions
    IERC20 immutable sOHM; // Collateral token
    address immutable OHM; // Debt token
    address immutable DAI; // Reserve token used
    IOHMIE immutable OHMIE; // Pair token

    IRouter02 immutable router; // Sushiswap router
    ITreasury immutable treasury; // Olympus treasury
    IStaking immutable staking; // Olympus staking

    mapping(address => UserInfo) public userInfo;

    Info public global; // fee info



    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _wsOHM,
        address _sOHM,
        address _OHM,
        address _DAI,
        address _OHMIE,
        address _LP,
        address _treasury,
        address _router,
        address _staking
    ) {
        require( _wsOHM != address(0));
        wsOHM = IwsOHM(_wsOHM);
        require( _sOHM != address(0));
        sOHM = IERC20(_sOHM);
        require( _OHM != address(0));
        OHM = _OHM;
        require( _DAI != address(0));
        DAI = _DAI;
        require( _OHMIE != address(0));
        OHMIE = IOHMIE(_OHMIE);
        require( _LP != address(0));
        global.lpToken = IERC20(_LP);
        require( _treasury != address(0));
        treasury = ITreasury(_treasury);
        require( _router != address(0));
        router = IRouter02(_router);
        require( _staking != address(0));
        staking = IStaking(_staking);
    }



    /* ========== MUTABLE FUNCTIONS ========== */

    // add sOHM collateral
    function add (uint amount) external {
        sOHM.safeTransferFrom(msg.sender, address(this), amount); 

        _updateCollateral(amount, true); 
    }

    // remove sOHM collateral
    function remove(uint amount) external {
        collectInterest(msg.sender);
        emit Check(1);

        require(amount <= equity(msg.sender), "amount greater than equity");

        _updateCollateral(amount, false);
        emit Check(2);

        sOHM.safeTransfer(msg.sender, amount);
    }

    // create position and deposit for OHMIE allocation
    function open (
        uint[] calldata args // [ohmDesired, ohmMin, ohmieDesired, ohmieMin, deadline]
    ) external returns (
        uint ohmAdded,
        uint ohmieAdded,
        uint liquidity
    ) {        
        OHMIE.safeTransferFrom(msg.sender, address(this), args[2]); // transfer paired token

        _borrow(args[0]); // leverage sOHM for OHM to pool
        emit Check(1);

        (ohmAdded, ohmieAdded, liquidity) = _openPosition(args);
        emit Check(3);

        _update(); // refresh rewards
        emit Check(4);
    }

    // args: [liquidity, ohmMin, ohmieMin, deadline]
    function close (uint[] calldata args) external returns (uint ohmRemoved, uint ohmieRemoved) {
        _update();
        emit Check(0);

        (ohmRemoved, ohmieRemoved) = _closePosition(args);
        emit Check(2);

        _settle(args[0], ohmRemoved);
        emit Check(4);

        OHMIE.safeTransfer(msg.sender, ohmieRemoved);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= global.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = global.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            global.lastRewardBlock = block.number;
            return;
        }
        uint256 reward = global.rewardPerBlock.mul(block.number.sub(global.lastRewardBlock));

        OHMIE.mint(_owner, reward.div(10));
        OHMIE.mint(address(this), reward);

        global.accOhmiePerShare = global.accOhmiePerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        global.lastRewardBlock = block.number;
    }

    // charge interest (only on collateral remove)
    function collectInterest(address user) public {
        UserInfo memory info = userInfo[user];
        uint balance = wsOHM.wOHMTosOHM(info.balance);
        uint growth = balance.sub(info.last);
        emit Check(growth);

        if (growth > 0) {
            uint interest = wsOHM.sOHMTowOHM(growth.div(30));
            uint newBalance = info.balance.sub(interest);

            userInfo[user].balance = newBalance;
            userInfo[user].last = wsOHM.wOHMTosOHM(newBalance);

            global.accrued = global.accrued.add(interest);
        }
    }



    /* ========== OWNABLE FUNCTIONS ========== */

    // collect interest fees from depositors
    function collect(address to) external onlyOwner() {
        if (global.accrued > 0) {
            sOHM.safeTransfer(to, wsOHM.wOHMTosOHM(global.accrued));
            global.balance = global.balance.sub(global.accrued);
            global.accrued = 0;
        }
    }

    // sets OHMIE reward per block
    function setRate(uint rewards) external onlyOwner() {
        updatePool();
        global.rewardPerBlock = rewards;
    }

    // sets debt ceiling for OHM borrowing
    function setCeiling(uint ceiling) external onlyOwner() {
        global.ceiling = ceiling;
    }



    /* ========== VIEW FUNCTIONS ========== */

    // sOHM minus borrowed OHM
    function equity(address user) public view returns (uint) {
        return wsOHM.wOHMTosOHM(userInfo[user].balance).sub(userInfo[user].debt);
    }

    // View function to see pending OHMIE on frontend.
    function pending (address _user) external view returns (uint) {
        uint256 accOhmiePerShare = global.accOhmiePerShare;
        uint256 lpSupply = global.lpToken.balanceOf(address(this));
        if (block.number > global.lastRewardBlock && lpSupply != 0) {
            uint reward = global.rewardPerBlock.mul(block.number.sub(global.lastRewardBlock));
            accOhmiePerShare = accOhmiePerShare.add(
                reward.mul(1e12).div(lpSupply)
            );
        }
        UserInfo storage user = userInfo[_user];
        return user.lp.mul(accOhmiePerShare).div(1e12).sub(user.rewardDebt);
    }



    /* ========== INTERNAL FUNCTIONS ========== */

    // mint OHM against sOHM
    function _borrow (uint amount) internal {
        require(amount <= equity(msg.sender), "Amount greater than equity");
        require(global.debt.add(amount) <= global.ceiling, "Debt ceiling hit");

        userInfo[msg.sender].debt = userInfo[msg.sender].debt.add(amount);
        global.debt = global.debt.add(amount);

        amount = amount.mul(1e9);
        treasury.incurDebt(amount, DAI); // borrow backing

        emit Check(0);

        IERC20(DAI).approve(address(treasury), amount);
        treasury.deposit(amount, DAI, 0); // mint new OHM with backing
    }

    // repay OHM debt
    function _settle (uint lp, uint ohmRemoved) internal {
        UserInfo memory user = userInfo[msg.sender];

        uint amount = user.debt.mul(lp).div(user.lp);
        if (amount > ohmRemoved) {
            sOHM.approve(address(staking), amount.sub(ohmRemoved));
            staking.unstake(amount.sub(ohmRemoved), false);
            emit Check(3);
        } else if (amount < ohmRemoved) {
            uint profits = ohmRemoved.sub(amount);
            
            IERC20(OHM).approve(address(staking), profits);
            staking.stake(profits, address(this));
            staking.claim(address(this));
            
            _updateCollateral(profits, true);
            emit Check(3);
        }
        treasury.repayDebtWithOHM(amount);

        userInfo[msg.sender].debt = user.debt.sub(amount);
        global.debt = global.debt.sub(amount);
    }

    // adds liquidity and returns excess tokens
    function _openPosition (uint[] calldata args) internal returns (
        uint ohmAdded,
        uint ohmieAdded,
        uint liquidity
    ) {
        IERC20(OHM).approve(address(router), args[0]);
        OHMIE.approve(address(router), args[2]);

        (ohmAdded, ohmieAdded, liquidity) = // add liquidity
            router.addLiquidity(OHM, address(OHMIE), args[0], args[2], args[1], args[3], address(this), args[4]);

        emit Check(2);

        userInfo[msg.sender].lp = userInfo[msg.sender].lp.add(liquidity);
        global.lp = global.lp.add(liquidity);

        _returnExcess(ohmAdded, args[0], ohmieAdded, args[2]); // return overflow
    }

    // removes liquidity
    function _closePosition (uint[] calldata args) internal returns (uint ohmRemoved, uint ohmieRemoved) {
        uint lp = userInfo[msg.sender].lp;
        require(lp >= args[0], "withdraw: not good");

        global.lpToken.approve(address(router), args[0]); // remove liquidity
        (ohmRemoved, ohmieRemoved) = router.removeLiquidity(OHM, address(OHMIE), args[0], args[1], args[2], address(this), args[3]);
        emit Check(1);

        userInfo[msg.sender].lp = lp.sub(args[0]);
        global.lp = global.lp.sub(args[0]);
    }

    // Deposit LP tokens to MasterChef for OHMIE allocation.
    function _update() internal {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.lp > 0) {
            uint reward =
                user.lp.mul(global.accOhmiePerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeOhmieTransfer(msg.sender, reward);
        }
        user.rewardDebt = user.lp.mul(global.accOhmiePerShare).div(1e12);
    }

    // accounting to remove sOHM collateral
    function _updateCollateral(uint amount, bool addition) internal {
        uint staticAmount = wsOHM.sOHMTowOHM(amount);
        UserInfo memory info = userInfo[msg.sender];
        
        if (addition) {
            userInfo[msg.sender].balance = info.balance.add(staticAmount); // user info
            userInfo[msg.sender].last = info.last.add(amount);

            global.balance = global.balance.add(staticAmount); // global info
        } else {
            userInfo[msg.sender].balance = info.balance.sub(staticAmount); // user info
            userInfo[msg.sender].last = info.last.sub(amount);

            global.balance = global.balance.sub(staticAmount); // global info
        }
    }

    // return excess token if less than amount desired when adding liquidity
    function _returnExcess(uint amountOhm, uint ohmDesired, uint amountOhmie, uint ohmieDesired) internal {
        if (amountOhm < ohmDesired) {
            treasury.repayDebtWithOHM(ohmDesired.sub(amountOhm));
        }
        if (amountOhmie < ohmieDesired) {
            OHMIE.safeTransfer(msg.sender, ohmieDesired.sub(amountOhmie));
        }
    }

    // Safe ohmie transfer function, just in case if rounding error causes pool to not have enough OHMIE.
    function safeOhmieTransfer(address _to, uint256 _amount) internal {
        uint256 ohmieBal = OHMIE.balanceOf(address(this));
        if (_amount > ohmieBal) {
            OHMIE.transfer(_to, ohmieBal);
        } else {
            OHMIE.transfer(_to, _amount);
        }
    }
}