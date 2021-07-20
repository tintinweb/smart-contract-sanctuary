/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);
     function decimals() external returns (uint256);

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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
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
        // This method relies on extcodesize, which returns 0 for contracts in
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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
}

library ExtendedMath {
    /**
     * @return The given number raised to the power of 2
     */
    function pow2(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * a;
        require(c / a == a, "ExtendedMath: squaring overflow");
        return c;
    }

    
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



interface IERC20Mintable {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function mint(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface WarbotManufacturer {
    
    function setApprovalForAll(address operator, bool approved) external;
    function transfer(address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function incrementTokenId() external;
    function getLastWarbotManufactured() external returns(uint256);
    function mint(address to, uint256 tokenId) external;
    function setTokenURIWarbotStats(uint256 tokenId, string memory _tokenURI) external;
    function ownerOf(uint256 tokenId) external returns(address);
}


interface NanoNFT {
    
    function setApprovalForAll(address operator, bool approved) external;
    function transfer(address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
    function  getNanoNFTCardStats ( uint256 _nftcard ) external returns( uint256, uint256, uint256, uint256, bool);
    function deployNFTNanoset( uint256 _warbot, address _creator ) external;
}


interface WarbotStats {
    function WarbotLevel(uint256 tokenId) external returns(uint256);
    
}


interface WarbotStatsData {
    function WarbotLevel( uint256 _warbot ) external returns(uint256 );
    function setWarbotHandoff( uint256 _warbot ) external ;
    function getCurrentHitPoint( uint256 _warbot ) external;
    function damageWarbot (uint256 _warbot, uint256 _damage) external;
    function damageWarbotAttack (uint256 _warbot, uint256 _damage) external;
    function damageWarbotDefense (uint256 _warbot, uint256 _damage) external;
    function damageWarbotSpeed (uint256 _warbot, uint256 _damage) external;
    function damageWarbotMovement (uint256 _warbot, uint256 _damage) external;
}



contract WarContract is Ownable {
    
    using SafeMath for uint256;
    bytes4 ERC721_RECEIVED = 0x150b7a02;
    address public burnAddress;
    address public micromachines;
    address public nanomachines;
    address public nanonft;
    address public warbotstats;
    address public warbotstatsdata;
    address public micromachinemanufacturingplant;
 
    address public oracle;
    
    WarbotManufacturer  __warbotmanufacturer;
    WarbotStats __warbotstats;
    WarbotStatsData public __warbotstatsdata;
    
    mapping ( uint256 => mapping ( address => mapping ( uint256 => uint256[] ) )) public NFTCards;
    mapping ( uint256 => mapping ( address => mapping ( uint8 => uint8 ) ))     public NFTCardCount;
    mapping ( uint256 => mapping ( address => mapping ( uint8 => mapping ( uint8 => uint8 ) ) ))     public Rounds;
    mapping ( uint256 => bool) public warbotInWarZone;
    
    //status of war 1 = joining battle, 2 = round begins awaiting oracle to roll initiative, 3 = warbot order sequence plays out, 4 = battle over
    mapping ( uint256 => uint8 ) public warStatus;
    mapping ( uint256 => uint256[]) public warbotIDs;
    
    
    mapping ( uint256 => mapping ( address =>uint8 )) warBotWarCount;
      

    ///////
    uint256 public warCount = 0;
    uint8 public maxWarTeams=2;
    uint8 public maxBotsPerTeam=2;
    
    
    mapping ( uint256 => mapping( uint8 => address) ) public Wars; 
    mapping ( uint256 => uint8 ) public WarTeamCount; 
    mapping ( uint256 => mapping ( address => uint8 )) public TeamBotCount;
    mapping ( uint256 => uint256[] ) public BotsInWar;
    mapping ( uint256 => address ) public warbotOwner;
    mapping ( uint256 => uint256[] ) public warbotAt;
    mapping ( uint256 => address[] ) WarTeams;
    
    //battle mechanics
    mapping ( uint256 => uint256[]) public warbotOrder;      // oracle rolls initiative and sets order of battle 
    mapping ( uint256 => uint256) public warbotOrderPointer;   
    mapping ( uint256 => uint256 ) public warbotCommand;   
    mapping ( uint256 => uint256 ) public warbotTarget;
    mapping ( uint256 => int8[] ) public warbotMovement;
    mapping ( uint256 => uint256 ) public warbotCardPlay;
    
    
    event WarBotOrderSet ( uint256 indexed _war, uint256 [] _order );
    event PointerAdvaced ( uint256 indexed _war, uint256 _warbotOrderPointer ); 
    event  newBattleInitiated ( uint256 indexed warCount , address indexed _warinitiator, uint256 indexed _warbot);
    event WarStarted ( uint256 indexed _war , address[] _warteams );
    event MaxBotsPerTeamSet (  uint256 _maxsize );
    
   
    constructor() {
        micromachines = 0x8Bc3EB7ded0ec83D0A8EF18D327644c04191f7DD;
        nanomachines = 0x4C0AeEB37210b97956309BB4585c5433Cc015F6c;
        micromachinemanufacturingplant = 0xe7e92e4Ccc08f381984de6CF35E050CE7729B9C6;
        warbotstats = 0xC665dFa4CEe8D947f181ccE176264b143A063933;
        warbotstatsdata = 0x7FbF69de56dE05f3217e8FC350aBa8C973b7ff5f;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        oracle = 0x7cE0E55703F12D03Eb53B918aD6B9EB80d188afB;
        
        
        __warbotmanufacturer = WarbotManufacturer(micromachinemanufacturingplant);
        __warbotstats = WarbotStats ( warbotstats);
        __warbotstatsdata = WarbotStatsData ( warbotstatsdata);
       
    } 
  
    function newBattle ( uint256 _warbot ) public {
      
        __warbotmanufacturer.transferFrom ( msg.sender, address(this), _warbot );
         require ( __warbotstatsdata.WarbotLevel (_warbot) > 0, "Warbot Not Activated");
        warCount++;
        warStatus[warCount] = 1;
        WarTeamCount[warCount]++;
        Wars[warCount][WarTeamCount[warCount]] = msg.sender;
       
        warbotInWarZone[_warbot]=true;
        __warbotstatsdata.setWarbotHandoff( _warbot );
       
        
        BotsInWar[warCount].push(_warbot);
        TeamBotCount[warCount][msg.sender]++;
        warbotOwner[_warbot] = msg.sender;
        warbotAt[_warbot] = [warCount, BotsInWar[warCount].length -1  ];
        
        emit newBattleInitiated ( warCount , msg.sender, _warbot);
    }
    
    
    
     uint8  []   _temp;
     
     function checkIfTeamsAreEven( uint256 _war ) public  returns(bool)  {
        if ( WarTeamCount[_war ] <2 ) return false;
        
        uint8 [] memory __temp;
        _temp = __temp;
         
        for ( uint8 x = 1; x< WarTeamCount[_war ]+1; x++ ){
           _temp.push(countWarbotsOnTeam (_war, Wars[_war][x]));
        }
        
        for ( uint i = 1; i < _temp.length; i++) {
              if (_temp[i] != _temp[0]) {
                return false;
              }
        }
        
        
        return true;
     }
     
    
     function recordTeam ( uint256 _war ) internal returns (uint8) {
          if(checkIfTeamIsPartOfWar( msg.sender , _war ) > 0) return checkIfTeamIsPartOfWar( msg.sender , _war );
          WarTeamCount[_war]++;
          Wars[_war][WarTeamCount[_war]] = msg.sender ;  
          WarTeams[_war].push ( msg.sender);
          require (  WarTeamCount[_war]  <= maxWarTeams, "Maximum War Teams Limit Already Hit" );
          return WarTeamCount[_war];
    }
    
    address[] _teamtemp;
    
    function getWarTeams ( uint256 _war ) public view returns ( address[] memory ){
        return WarTeams[_war];
    }
   
   
    function checkIfTeamIsPartOfWar( address _address, uint256 _war ) public view returns(uint8)  {
        uint8 x;
        for ( x = 1; x< WarTeamCount[_war ]+1; x++ ){
            if ( Wars[_war][x] == _address ) return x;
        }
        return 0;
     }
    
     function countWarbotsOnTeam ( uint256 _war , address _address ) public view returns(uint8){
        uint8 _count;
        uint8 x;
        for ( x = 0; x< BotsInWar[_war].length ; x++ ){
            if ( _address == warbotOwner[BotsInWar[_war][x]] ) _count++;
        }
        return _count;
         
     }
     
    
     function joinBattle ( uint256 _warbot, uint256 _war ) public {
        require ( warStatus[_war] == 1, "Arena Not Available for New Warbots" );
        require ( __warbotstatsdata.WarbotLevel (_warbot) > 0);
       
        require ( countWarbotsOnTeam( _war, msg.sender) < maxBotsPerTeam , "Max Warbots for this team Already hit" );
        TeamBotCount[_war][msg.sender]++;
        uint8 _team = recordTeam ( _war );
        __warbotmanufacturer.transferFrom ( msg.sender, address(this), _warbot );
        Wars[warCount][_team] = msg.sender;
        warbotInWarZone[_warbot]=true;
        __warbotstatsdata.setWarbotHandoff( _warbot );
        BotsInWar[warCount].push(_warbot);
        warbotOwner[_warbot] = msg.sender;
        warbotAt[_warbot] = [_war, BotsInWar[_war].length -1  ];
                 
     }
    
      
    function returnWarbot ( uint256 _warbot ) public  {
     
        require ( warbotOwner[_warbot] == msg.sender, "Not Warbot Owner" );
        warbotOwner[_warbot]  = address(0);
        
        WarbotManufacturer _micromachinemanufacturingplant = WarbotManufacturer(micromachinemanufacturingplant);
        _micromachinemanufacturingplant.transferFrom ( address(this), msg.sender,  _warbot );
        warbotInWarZone[_warbot]=false;
        removeWarbotFromWar ( _warbot );
        warbotAt[_warbot] = [0,0];
    }
   
    function returnAllWarbots ( uint256 _war ) public  {
     
        for ( uint256 x = 0; x < getBotsInWar(_war).length; x++ ){
            address _owner = warbotOwner[ BotsInWar[_war][x] ];
            uint256 _botnumber = BotsInWar[_war][x];
            warbotOwner[ _botnumber ]  = address(0);
            
            WarbotManufacturer _micromachinemanufacturingplant = WarbotManufacturer(micromachinemanufacturingplant);
            _micromachinemanufacturingplant.transferFrom ( address(this), _owner,  _botnumber);
            warbotInWarZone[_botnumber]=false;
            removeWarbotFromWar ( _botnumber );
            warbotAt[ _botnumber ] = [0,0];
        }
    }
   
   
    function removeWarbotFromWar ( uint256 _warbot )public  {
         (uint256 _war, uint256 _position)  = whereIsWarbot( _warbot );
       if ( _war == 0 ) revert("Warbot Not Found ");
     
         delete BotsInWar[ _war][ _position   ];
         TeamBotCount[ _war][msg.sender]--;
          warbotOwner[_warbot] = address(0);   
    } 
    
  
     
 
    function getBotsInWar( uint256 _war ) public view returns ( uint256[] memory ){
            return BotsInWar[_war];
    }
    
    function whereIsWarbot( uint256 _warbot ) public view returns(uint256, uint256) {
        return ( warbotAt[_warbot][0], warbotAt[_warbot][1]);
        
    }
    
    function changeWarStatus ( uint256 _war, uint8 _status ) public {
         warStatus[_war] = _status;
    }

    function startWar ( uint256 _war ) public {
       require ( WarTeamCount[_war] >1, "Not Enough Contestants" );
       require (  checkIfTeamsAreEven( _war ), "Uneven teams ");
       warStatus[_war] = 2;
       emit WarStarted ( _war, getWarTeams(_war)  );
    }
    
    // attack + target  1 +  bot position
    // move   2 + target position
    // usecard 3 + card position number
    
    
    function goTurn ( uint256 _war , uint8 _option, uint256 _target, int8 _x, int8 _y, uint256 _cardnumber ) public {
        require ( _option >0 && _option < 4 );
        require ( warbotOwner[getCurrentTurn (  _war )] == msg.sender, "Not Warbot's Owner" );
        require ( warStatus[_war] == 3 , "Not Authorized");
        
        warbotCommand[_war] = _option;
        if ( _option == 1 ) warbotTarget[_war] = _target;
        if ( _option == 2 ) warbotMovement[_war] = [_x,_y];
        if ( _option == 1 ) warbotCardPlay[_war] = _cardnumber;
        warStatus[_war] = 4;
        
    }
    
  
    function advancePointer( uint256  _war ) public {
        
         warbotOrderPointer[_war]++;
        if( warbotOrderPointer[_war] >= warbotOrder[_war].length )  { 
            warbotOrderPointer[_war] = 0;
            warStatus[_war] = 2 ;}
        emit PointerAdvaced ( _war, warbotOrderPointer[_war] );    
    }
    
    function getCurrentTurn ( uint256 _war ) public view returns(uint256){
        
        uint256 _pointer =  warbotOrderPointer[_war];
        uint256 _warbot = warbotOrder[_war][_pointer];
        return _warbot;
        
    }
    
    
    function damageWarbot (uint256 _war, uint256 _warbot , uint256 _damage, uint8 _type ) public {
        
        if( _type == 1 )  __warbotstatsdata.damageWarbot ( _warbot, _damage );
        if( _type == 2 )  __warbotstatsdata.damageWarbotAttack ( _warbot, _damage );
        if( _type == 3 )  __warbotstatsdata.damageWarbotDefense ( _warbot, _damage );
        if( _type == 4 )  __warbotstatsdata.damageWarbotSpeed ( _warbot, _damage );
        if( _type == 5 )  __warbotstatsdata.damageWarbotMovement ( _warbot, _damage );
        advancePointer(_war);
        
    }
    
    
    function setWarbotOrder ( uint256 _war, uint256 [] memory _order ) public {
        
        warbotOrder[_war] = _order;
        warStatus[_war] = 3;
        warbotOrderPointer[_war] = 0;
        emit WarBotOrderSet ( _war, _order );
    }
    
    
    function setMaxBotsPerTeam( uint8 _maxsize ) public onlyOwner {
        maxBotsPerTeam = _maxsize;
        emit MaxBotsPerTeamSet (  _maxsize );
    }
    
    function setWarbotStatsData( address _address ) public onlyOwner {
        warbotstatsdata = _address;
        __warbotstatsdata = WarbotStatsData ( _address );
    }
    
    
    function setMicromachines( address _address ) public onlyOwner {
        micromachines = _address;
    }
    
    function setNanomachines( address _address ) public onlyOwner {
        nanomachines = _address;
    }
    
    function setNanoNFT( address _address ) public onlyOwner {
        nanonft = _address;
    }
    
    function setWarbotstats( address _address ) public onlyOwner {
        warbotstats = _address;
       
    }
    
    function setMicromachinesManufacturingplant( address _address ) public onlyOwner {
        micromachinemanufacturingplant = _address;
    }
    
    function levelRequirement ( uint256 _level ) public   returns (uint256 ){
        IERC20 _nano = IERC20 ( nanomachines );
        return  (  _level * _level ) * 10 ** _nano.decimals();
    }
    
   
    function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes memory _data) public view returns(bytes4){
        _operator; _from; _tokenId; _data; 
        return ERC721_RECEIVED;
    }
    
    modifier onlyOracle() {
        require( msg.sender == oracle, "Oracle Only");
        _;
    }
    
    
    modifier onlyWarbotManufacturer() {
        require( msg.sender == micromachinemanufacturingplant, "WarbotManufacturer Only");
        _;
    }
    
}