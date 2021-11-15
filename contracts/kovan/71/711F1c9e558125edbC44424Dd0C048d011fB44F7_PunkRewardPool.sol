// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./OwnableStorage.sol";

contract Ownable{

    OwnableStorage _storage;

    function initialize( address storage_ ) public {
        _storage = OwnableStorage(storage_);
    }

    modifier OnlyAdmin(){
        require( _storage.isAdmin(msg.sender) );
        _;
    }

    modifier OnlyGovernance(){
        require( _storage.isGovernance( msg.sender ) );
        _;
    }

    modifier OnlyAdminOrGovernance(){
        require( _storage.isAdmin(msg.sender) || _storage.isGovernance( msg.sender ) );
        _;
    }

    function updateAdmin( address admin_ ) public OnlyAdmin {
        _storage.setAdmin(admin_);
    }

    function updateGovenance( address gov_ ) public OnlyAdminOrGovernance {
        _storage.setGovernance(gov_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract OwnableStorage {

    address public _admin;
    address public _governance;

    constructor() payable {
        _admin = msg.sender;
        _governance = msg.sender;
    }

    function setAdmin( address account ) public {
        require( isAdmin( msg.sender ), "OWNABLESTORAGE : Not a admin" );
        _admin = account;
    }

    function setGovernance( address account ) public {
        require( isAdmin( msg.sender ) || isGovernance( msg.sender ), "OWNABLESTORAGE : Not a admin or governance" );
        _admin = account;
    }

    function isAdmin( address account ) public view returns( bool ) {
        return account == _admin;
    }

    function isGovernance( address account ) public view returns( bool ) {
        return account == _admin;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Ownable.sol";

// Hard Work Now! For Punkers by 0xViktor...
contract PunkRewardPool is Ownable, Initializable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bool isStarting = false;
    bool isInitialize = false;

    uint constant MAX_WEIGHT = 500;
    uint constant BLOCK_YEAR = 2102400;
    
    IERC20 Punk;
    uint startBlock;
    
    address [] forges;

    mapping ( address => uint ) totalSupplies;
    mapping ( address => mapping( address=>uint ) ) balances;
    mapping ( address => mapping( address=>uint ) ) checkPointBlocks;
    
    mapping( address => uint ) weights;
    uint weightSum;
    
    mapping( address => uint ) distributed;
    uint totalDistributed;

    function initializePunkReward( address storage_, address punk_ ) public initializer {
        // Hard Work Now! For Punkers by 0xViktor...
        require(!isInitialize);
        Ownable.initialize( storage_ );
        Punk = IERC20( punk_ );
        startBlock = 0;
        weightSum = 0;
        totalDistributed = 0;

        isInitialize = true;
    }
    
    function addForge( address forge ) public OnlyAdminOrGovernance {
        // Hard Work Now! For Punkers by 0xViktor...
        require( !_checkForge( forge ), "PUNK_REWARD_POOL: Already Exist" );
        forges.push( forge );
        weights[ forge ] = 0;
    }
    
    function setForge( address forge, uint weight ) public OnlyAdminOrGovernance {
        // Hard Work Now! For Punkers by 0xViktor...
        require( _checkForge( forge ), "PUNK_REWARD_POOL: Not Exist Forge" );
        ( uint minWeight , uint maxWeight ) = getWeightRange( forge );
        require( minWeight <= weight && weight <= maxWeight, "PUNK_REWARD_POOL: Invalid weight" );
        weights[ forge ] = weight;
        
        weightSum = 0;
        for( uint i = 0 ; i < forges.length ; i++ ){
            weightSum += weights[ forges[ i ] ];
        }

        if( !isStarting && weightSum > 0 && forges.length > 0 ){
            startBlock = block.number;
            isStarting = true;
        }
    }

    function getWeightRange( address forge ) public view returns( uint, uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        if( forges.length == 0 ) return ( 1, MAX_WEIGHT );
        if( forges.length == 1 ) return ( weights[ forges[ 0 ] ], weights[ forges[ 0 ] ] );
        
        uint highestWeight = 0;
        uint excludeWeight = weightSum.sub( weights[ forge ] );

        for( uint i = 0 ; i < forges.length ; i++ ){
            if( forges[ i ] != forge && highestWeight < weights[ forges[ i ] ] ){
                highestWeight = weights[ forges[ i ] ];
            }
        }

        if( highestWeight > excludeWeight.sub( highestWeight ) ){
            return ( highestWeight.sub( excludeWeight.sub( highestWeight ) ), MAX_WEIGHT < excludeWeight ? MAX_WEIGHT : excludeWeight );
        }else{
            return ( 0, MAX_WEIGHT < excludeWeight ? MAX_WEIGHT : excludeWeight );
        }
    }

    function claimPunk( ) public {
        // Hard Work Now! For Punkers by 0xViktor...
        claimPunk( msg.sender );
    }
    
    function claimPunk( address to ) public {
        // Hard Work Now! For Punkers by 0xViktor...
        for( uint i = 0 ; i < forges.length ; i++ ){
            claimPunk( forges[ i ], to );
        }
    }

    function claimPunk( address forge, address to ) public {
        // Hard Work Now! For Punkers by 0xViktor...
        uint checkPointBlock = checkPointBlocks[ forge ][ to ];
        if( checkPointBlock > startBlock ){
            uint reward = _calcRewards( forge, to, checkPointBlock, block.number );
            checkPointBlocks[ forge ][ to ] = block.number;
            Punk.safeTransfer( to, reward );
            distributed[ forge ] = distributed[ forge ].add( reward );
            totalDistributed = totalDistributed.add( reward );
        }
    }
    
    function staking( address forge, uint amount ) public {
        // Hard Work Now! For Punkers by 0xViktor...
        require( weights[ forge ] > 0, "REWARD POOL : FORGE IS NOT READY" );
        claimPunk();
        checkPointBlocks[ forge ][ msg.sender ] = block.number;
        IERC20( forge ).safeTransferFrom( msg.sender, address( this ), amount );
        balances[ forge ][ msg.sender ] = balances[ forge ][ msg.sender ].add( amount );
        totalSupplies[ forge ] = totalSupplies[ forge ].add( amount );
    }
    
    function unstaking( address forge, uint amount ) public {
        // Hard Work Now! For Punkers by 0xViktor...
        require( weights[ forge ] > 0, "REWARD POOL : FORGE IS NOT READY" );
        claimPunk();
        checkPointBlocks[ forge ][ msg.sender ] = block.number;
        balances[ forge ][ msg.sender ] = balances[ forge ][ msg.sender ].sub( amount );
        IERC20( forge ).safeTransfer( msg.sender, amount );
        totalSupplies[ forge ] = totalSupplies[ forge ].sub( amount );
    }
    
    function _checkForge( address forge ) internal view returns( bool ){
        // Hard Work Now! For Punkers by 0xViktor...
        bool check = false;
        for( uint  i = 0 ; i < forges.length ; i++ ){
            if( forges[ i ] == forge ){
                check = true;
                break;
            }
        }
        return check;
    }
    
    function _calcRewards( address forge, address user, uint fromBlock, uint currentBlock ) internal view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        uint balance = balances[ forge ][ user ];
        uint totalSupply = totalSupplies[ forge ];
        uint weight = weights[ forge ];
        
        uint startPeriod = _getPeriodFromBlock( fromBlock );
        uint endPeriod = _getPeriodFromBlock( currentBlock );
        
        if( startPeriod == endPeriod ){
            
            uint during = currentBlock.sub( fromBlock ).mul( balance ).mul( weight ).mul( _perBlockRateFromPeriod( startPeriod ) );
            return during.div( weightSum ).div( totalSupply );
            
        }else{
            uint denominator = weightSum.mul( totalSupply );
            
            uint duringStartNumerator = _getBlockFromPeriod( startPeriod.add( 1 ) ).sub( fromBlock );
            duringStartNumerator = duringStartNumerator.mul( weight ).mul( _perBlockRateFromPeriod( startPeriod ) ).mul( balance );    
            
            uint duringEndNumerator = currentBlock.sub( _getBlockFromPeriod( endPeriod ) );
            duringEndNumerator = duringEndNumerator.mul( weight ).mul( _perBlockRateFromPeriod( endPeriod ) ).mul( balance );    

            uint duringMid = 0;
            
          for( uint i = startPeriod.add( 1 ) ; i < endPeriod ; i++ ) {
              uint numerator = BLOCK_YEAR.mul( 4 ).mul( balance ).mul( weight ).mul( _perBlockRateFromPeriod( i ) );
              duringMid += numerator.div( denominator );
          }
           
          uint duringStartAmount = duringStartNumerator.div( denominator );
          uint duringEndAmount = duringEndNumerator.div( denominator );
           
          return duringStartAmount + duringMid + duringEndAmount;
        }
    }
    
    function _getBlockFromPeriod( uint period ) internal view returns ( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return startBlock.add( period.sub( 1 ).mul( BLOCK_YEAR ).mul( 4 ) );
    }
    
    function _getPeriodFromBlock( uint blockNumber ) internal view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
       return blockNumber.sub( startBlock ).div( BLOCK_YEAR.mul( 4 ) ).add( 1 );
    }
    
    function _perBlockRateFromPeriod( uint period ) internal view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        uint totalDistribute = Punk.balanceOf( address( this ) ).add( totalDistributed ).div( period.mul( 2 ) );
        uint perBlock = totalDistribute.div( BLOCK_YEAR.mul( 4 ) );
        return perBlock;
    }
    
    function getClaimPunk( address to ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        uint reward = 0;
        for( uint i = 0 ; i < forges.length ; i++ ){
            reward += getClaimPunk( forges[ i ], to );
        }
        return reward;
    }

    function getClaimPunk( address forge, address to ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        uint checkPointBlock = checkPointBlocks[ forge ][ to ];
        return checkPointBlock > startBlock ? _calcRewards( forge, to, checkPointBlock, block.number ) : 0;
    }

    function getWeightSum() public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return weightSum;
    }

    function getWeight( address forge ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return weights[ forge ];
    }

    function getTotalDistributed( ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return totalDistributed;
    }

    function getDistributed( address forge ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return distributed[ forge ];
    }

    function getAllocation( ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return _perBlockRateFromPeriod( _getPeriodFromBlock( block.number ) );
    }

    function getAllocation( address forge ) public view returns( uint ){
        // Hard Work Now! For Punkers by 0xViktor...
        return getAllocation( ).mul( weights[ forge ] ).div( weightSum );
    }

}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

