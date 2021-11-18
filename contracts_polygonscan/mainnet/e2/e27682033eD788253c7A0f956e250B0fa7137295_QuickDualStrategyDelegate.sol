/**
 *Submitted for verification at polygonscan.com on 2021-11-18
*/

/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

////import "../utils/AddressUpgradeable.sol";

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}




/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;
////import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}




/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
pragma solidity 0.6.12;

interface IProfitStrategy {
    /**
     * @notice stake LP
     */
    function stake(uint256 _amount) external;  // owner
    /**
     * @notice withdraw LP
     */
    function withdraw(uint256 _amount) external;  // owner
    /**
     * @notice the stakeReward address
     */
    function stakeToken() external view  returns (address);
    /**
     * @notice the earn Token address
     */
    function earnToken() external view  returns (address);
    /**
     * @notice returns pending earn amount
     */
    function earnPending(address _account) external view returns (uint256);
    /**
     * @notice withdaw earnToken
     */
    function earn() external;
    /**
     * @notice return ERC20(earnToken).balanceOf(_account)
     */
    function earnTokenBalance(address _account) external view returns (uint256);
    /**
     * @notice return LP amount in staking
     */
    function balanceOfLP(address _account) external view  returns (uint256);
    /**
     * @notice withdraw staked LP and earnToken assets
     */
    function exit() external;  // owner

    function burn(address _to, uint256 _amount) external returns (uint256 amount0, uint256 amount1);
}



/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.6.12;

contract MasterCaller {
    address private _master;

    event MastershipTransferred(address indexed previousMaster, address indexed newMaster);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _master = msg.sender;
        emit MastershipTransferred(address(0), _master);
    }

    /**
     * @dev Returns the address of the current MasterCaller.
     */
    function masterCaller() public view returns (address) {
        return _master;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMasterCaller() {
        require(_master == msg.sender, "Master: caller is not the master");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferMastership(address newMaster) public virtual onlyMasterCaller {
        require(newMaster != address(0), "Master: new owner is the zero address");
        emit MastershipTransferred(_master, newMaster);
        _master = newMaster;
    }
}



/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}




/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity >=0.6.0 <0.8.0;

////import "../utils/ContextUpgradeable.sol";
////import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


/** 
 *  SourceUnit: /Users/dingyp/vsCode/sister-in-law/contracts/strategy/quick/QuickDualStrategyDelegate.sol
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

////import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "../../uniswapv2/interfaces/IUniswapV2Pair.sol";
////import '../../uniswapv2/libraries/TransferHelper.sol';
////import "../../utils/MasterCaller.sol";
////import "../../interfaces/IProfitStrategy.sol";

interface IQuickSwapRouter {
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IQuickDualChef {

    function balanceOf(address account) external view returns (uint256);

    function rewardsTokenA() external view returns (address);
    function rewardsTokenB() external view returns (address);

    function earnedA(address account) external view returns (uint256);
    function earnedB(address account) external view returns (uint256);

    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external ;
}
interface IDquick {
    function leave(uint256 _amount) external;
    function balanceOf(address account) external view returns(uint256);
}
/**
 * Qucik StakingDualRewards, every Contract has diff `stakeRewards`, `stakeLpPair`, 
 * 1. Clain RewardTokenA & rewardTokenB (D_QUICK & WMATIC) from DualReward 
 * 2. convert D_QUICK to QuickToken via call `leafe` method to D_QUICK
 * 3. swap Quick to WMATIC (all lp build by WMATIC_XXX)
 * 4. transfer WMATIC to Gatling to compound
 *
 * add in 
 */
contract QuickDualStrategyDelegate is OwnableUpgradeable, IProfitStrategy {

    //earnToken //CP
    address public constant earnTokenAddr = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public stakeGatling;

    address public constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;   // QUICK
    address public constant D_QUICK = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1; // RewardTokenA
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;  // RewardTokenB
    

    address public constant v2Router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;


    //Qucik StakingDualRewards
    address public stakeRewards;
    // UniLP ([usdt-eth].part)
    address public  stakeLpPair;

    address public admin;  
    address[] public routerPath;

    address public dQuickLounge;
    address public wMaticLounge;
    uint256 public dQuickFee; // 1000 based
    uint256 public wMaticFee; // 1000 based

    function initialize(address _stakeLpPair, address _stakeRewards, address _stakeGatling)
        public 
        initializer
    {
        __Ownable_init();
        stakeLpPair  = _stakeLpPair;
        stakeGatling = _stakeGatling;
        stakeRewards = _stakeRewards;

        
        safeApprove(stakeLpPair, address(stakeRewards), ~uint256(0));
        admin = msg.sender;
        // transferOwnership(_stakeGatling);
    }

    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

     /**
     * Stake LP
     */
    function stake(uint256 _amount) external override onlyOwner() {

        if(stakeRewards != address(0)) {
            IQuickDualChef(stakeRewards).stake(_amount);
        }
    }

    /**
     * withdraw LP
     */
    function withdraw(uint256 _amount) public override onlyOwner() {

        if(stakeRewards != address(0) && _amount > 0) {
            IQuickDualChef(stakeRewards).withdraw(_amount);
            TransferHelper.safeTransfer(stakeLpPair, address(stakeGatling),_amount);
        }
    }

    function burn(address _to, uint256 _amount) external override onlyOwner() returns (uint256 amount0, uint256 amount1) {

        if(stakeRewards != address(0) && _amount > 0) {
            IQuickDualChef(stakeRewards).withdraw(_amount);
            uint256 bal = IERC20(stakeLpPair).balanceOf(address(this));

            TransferHelper.safeTransfer(stakeLpPair, stakeLpPair, bal);
            (amount0, amount1) =  IUniswapV2Pair(stakeLpPair).burn(_to);
        }
    }

    function stakeToken() external view override returns (address) {
        return stakeRewards;
    }

    function earnToken() external view override returns (address) {
        return earnTokenAddr;
    }

    function earnPending(address _account) external view override returns (uint256) {
        return _earnPending(_account);
    }
    function _earnPending(address _account) private view returns (uint256) {
        return IQuickDualChef(stakeRewards).earnedA(_account) + IQuickDualChef(stakeRewards).earnedB(_account);
    }
    function earn() external override onlyOwner() {
        
        IQuickDualChef(stakeRewards).getReward();
        transferEarn2Gatling();
    }
    function earnTokenBalance(address _account) external view override returns (uint256) {
        return IERC20(earnTokenAddr).balanceOf(_account) + _earnPending(_account);
    }

    function balanceOfLP(address _account) external view override  returns (uint256) {
        return IQuickDualChef(stakeRewards).balanceOf(_account);
    }
    
    /**
     * withdraw LP && earnToken
     */
    function exit() external override  onlyOwner() {

        withdraw(IQuickDualChef(stakeRewards).balanceOf(address(this)));
        transferLP2Gatling();
        transferEarn2Gatling();
    }
    function transferLP2Gatling() private {

        uint256 _lpAmount = IERC20(stakeLpPair).balanceOf(address(this));
        if(_lpAmount > 0) {
            TransferHelper.safeTransfer(stakeLpPair, stakeGatling, IERC20(stakeLpPair).balanceOf(address(this)));
        }
    }

    function transferEarn2Gatling() private {

        transferFeeToLounge();

        IDquick(D_QUICK).leave(IDquick(D_QUICK).balanceOf(address(this)));

        swapDQucik2Matic();
        uint256 _tokenAmount = IERC20(earnTokenAddr).balanceOf(address(this));
        if(_tokenAmount > 0) {
            TransferHelper.safeTransfer(earnTokenAddr, address(stakeGatling), _tokenAmount);
        }
    }

    function transferFeeToLounge() private {
        if( dQuickFee > 0 &&  dQuickLounge != address(0)) {
            uint256 balDquick = IERC20(D_QUICK).balanceOf(address(this));
            IERC20(D_QUICK).transfer(dQuickLounge, balDquick * dQuickFee / 1000);
        }
        if( wMaticFee > 0 &&  wMaticLounge != address(0)) {
            uint256 balWMatic = IERC20(WMATIC).balanceOf(address(this));
            IERC20(WMATIC).transfer(wMaticLounge, balWMatic * wMaticFee / 1000);
        }
    }

    function swapDQucik2Matic() private {

        uint256 _amount = IERC20(QUICK).balanceOf(address(this));
        if (_amount > 1000) {
            if(routerPath.length > 1) {
                address[] memory _path = routerPath;
                IQuickSwapRouter(v2Router).swapExactTokensForTokens( _amount, 0, _path, address(this), block.timestamp);
            } else {
                address[] memory _path = new address[](2);
                _path[0] = QUICK;
                _path[1] = WMATIC;
                IQuickSwapRouter(v2Router).swapExactTokensForTokens( _amount, 0, _path, address(this), block.timestamp);
            }
        }
    }

    function setRouterPath(address[] calldata path) external {
        require(tx.origin == admin, 'Only admin allowed');
        require(path.length > 1, 'Invalid path');

        require(path[0] == QUICK, 'Invalid path start token');
        require(path[path.length -1] == earnTokenAddr, "Invalid path target token");

        delete routerPath;
        routerPath = path;

        address _erc20Token = path[0];
        TransferHelper.safeApprove(_erc20Token, v2Router, 0);
        TransferHelper.safeApprove(_erc20Token, v2Router, ~uint256(0));
    }

    function setDqickFee(uint256 feeRate, address feeTo) external {
        require(tx.origin == admin, 'Only admin allowed');
        require(feeRate < 1000, "Fee out of range");
        dQuickFee = feeRate;
        dQuickLounge = feeTo;
    }

    function setWmaticFee(uint256 feeRate, address feeTo) external {
        require(tx.origin == admin, 'Only admin allowed');
        require(feeRate < 1000, "Fee out of range");
        wMaticFee = feeRate;
        wMaticLounge = feeTo;
    }

    function setAdmin(address _admin) external {
        require(tx.origin == admin, 'Only Sil.deploy allowed');
        admin = _admin;
    }
}