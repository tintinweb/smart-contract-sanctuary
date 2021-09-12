/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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
        assembly {
            size := extcodesize(account)
        }
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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



// File: gist-4b797c3b2b18c7686dfe0cc5d4798596/contracts/libraries/TimeLock.sol



pragma solidity ^0.8.7;






abstract contract TimeLock is Ownable {
    using Address for address;   
    
    /* =====================================================================================================================
                                                        Variables
    ===================================================================================================================== */
    bool public isLockEnabled = false;
    mapping(string => uint256) public timelock;
    uint256 private constant _TIMELOCK = 1 days;
    address private _maintainer;  
        
    /* =====================================================================================================================
                                                        Events
    ===================================================================================================================== */
    event MaintainerTransferred(address indexed previousMaintainer, address indexed newMaintainer);
    event UnlockedFunction(string indexed functionName, uint256 indexed unlockedAt);
    event EnabledLock();
    
    /* =====================================================================================================================
                                                        Modifier
    ===================================================================================================================== */
    //After unlock we have to wait for _TIMELOCK before we can call the Function
    //Additionally we have a time window of 24 hours to call the function to prevent pre-unlocked calls
    modifier locked(string memory _fn) {
        require(!isLockEnabled || (timelock[_fn] != 0 && timelock[_fn] <= block.timestamp && timelock[_fn] + 1 days >= block.timestamp), "Function is locked");
        _;
        lockFunction(_fn);
    }
        
    modifier onlyMaintainerOrOwner() {
        require(owner() == msg.sender || _maintainer == msg.sender, "operator: caller is not allowed to call this function");
        _;
    }

    constructor() {
        _maintainer = msg.sender;
    }
    
    /* =====================================================================================================================
                                                        Get Functions
    ===================================================================================================================== */
    function maintainer() public view returns (address) {
        return _maintainer;
    }
        
    /* =====================================================================================================================
                                                        Set Functions
    ===================================================================================================================== */
    function setMaintainer(address _newMaintainer) public onlyMaintainerOrOwner locked("maintainer") {
        require(_newMaintainer != _maintainer && _newMaintainer != address(0), "ABOAT::setMaintainer: Maintainer can\'t equal previous maintainer or zero address");
        address previousMaintainer = _maintainer;
        _maintainer = _newMaintainer;
        emit MaintainerTransferred(previousMaintainer, _maintainer);
    }
    
    function setTimelockEnabled() public onlyMaintainerOrOwner {
        isLockEnabled = true;
        emit EnabledLock();
    }

    /* =====================================================================================================================
                                                    Utility Functions
    ===================================================================================================================== */ 
    //unlock timelock
    function unlockFunction(string memory _fn) public onlyMaintainerOrOwner {
        timelock[_fn] = block.timestamp + _TIMELOCK;
        emit UnlockedFunction(_fn, timelock[_fn]);
     }
      
     //lock timelock
    function lockFunction(string memory _fn) public onlyMaintainerOrOwner {
        timelock[_fn] = 0;
    }
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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


// File: gist-4b797c3b2b18c7686dfe0cc5d4798596/contracts/libraries/PriceTicker.sol



pragma solidity ^0.8.7;


abstract contract PriceTicker is Ownable, TimeLock {
    using SafeMath for uint256;
    using Address for address;   
    
    /* =====================================================================================================================
                                                        Variables
    ===================================================================================================================== */
    AboatToken public coin;
    address public lpAddress;
    
    uint256[] public hourlyPrices;
    uint256 public hourlyIndex = 0;
    
    uint256 public lastPriceUpdateBlock;
    uint256 public lastAveragePrice = 0;
    uint256 public previousAveragePrice = 0;
        
    /* =====================================================================================================================
                                                        Events
    ===================================================================================================================== */
    event ChangedCoin(address indexed previousCoin, address indexed newCoin);
    event UpdatedAveragePrice(uint256 indexed previousAveragePrice, uint256 indexed newAveragePrice);

    constructor() {
        for(uint8 i = 0; i < 24; i++) {
            hourlyPrices.push(0);
        }
    }
    
        
    /* =====================================================================================================================
                                                        Set Functions
    ===================================================================================================================== */
    
    function setCoin(AboatToken _coin) public onlyOwner locked("setCoin") {
        require(coin != _coin, "ABOAT::setCoin: Can't replace the same coin");
        address previousCoin = address(coin);
        coin = _coin;
        lpAddress = coin.liquidityPair();
        hourlyIndex = 0;
        lastAveragePrice = 0;
        previousAveragePrice = 0;
        emit ChangedCoin(previousCoin, address(coin));
    }
        
    /* =====================================================================================================================
                                                        Get Functions
    ===================================================================================================================== */
    function getAveragePrice() public view returns (uint256) {
        uint256 averagePrice = 0;
        uint256 amount = 0;
        for (uint256 i = 0; i <= hourlyIndex; i++) {
            if(hourlyPrices[i] > 0) {
                averagePrice += hourlyPrices[i];
                amount++;
            }
        }
        return averagePrice.div(amount);
    }  
    
    function getPriceDifference(int256 newPrice, int256 oldPrice) public pure returns (uint256) {
        int256 percentageDifference = (newPrice - oldPrice) * 100  * 10000 / oldPrice; //mul 10000 for floating accuracy
        if(percentageDifference < 0) {
            percentageDifference *= -1;
        }
        uint256 absPercentageDifference = uint256(percentageDifference);
        return absPercentageDifference; 
    }

    /* =====================================================================================================================
                                                    Utility Functions
    ===================================================================================================================== */ 
    function getTokenPrice() public returns (uint256) {
        address coinLpAddress = coin.liquidityPair();
        if(coinLpAddress != lpAddress) {
            lpAddress = coinLpAddress;
            hourlyIndex = 0;
            lastAveragePrice = 0;
            previousAveragePrice = 0;
        }
        IUniswapV2Pair pair = IUniswapV2Pair(lpAddress);
        (uint256 res0, uint256 res1,) = pair.getReserves();
        if(res0 == 0 && res1 == 0) {
            return 0;
        }
        ERC20 tokenB = address(pair.token0()) == address(coin) ? ERC20(pair.token1()) : ERC20(pair.token1());
        uint256 mainRes = address(pair.token0()) == address(coin) ? res1 : res0;
        uint256 secondaryRes = mainRes == res0 ? res1: res0;
        return (mainRes * (10 ** tokenB.decimals())) / secondaryRes;
    }
    
    function updateLastAveragePrice(uint256 updatedPrice) internal {
        previousAveragePrice = lastAveragePrice;
        lastAveragePrice = updatedPrice;
        emit UpdatedAveragePrice(previousAveragePrice, lastAveragePrice);
    }
    
    function checkPriceUpdate() virtual public  {
        if (lastPriceUpdateBlock < block.timestamp - 1 hours) {
            uint256 tokenPrice = getTokenPrice();
            hourlyPrices[hourlyIndex++] = tokenPrice;
            lastPriceUpdateBlock = block.timestamp;
        }

    }
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



pragma solidity ^0.8.0;



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

// File: gist-4b797c3b2b18c7686dfe0cc5d4798596/contracts/MasterEntertainer.sol



pragma solidity ^0.8.7;














// File: gist-4b797c3b2b18c7686dfe0cc5d4798596/contracts/libraries/TransferHelper.sol



pragma solidity ^0.8.7;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract MasterEntertainer is Ownable, ReentrancyGuard, PriceTicker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;    
    
    /* =====================================================================================================================
                                                        Structs
    ===================================================================================================================== */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCoinPerShare;
        uint16 depositFee; 
    }
    
    /* =====================================================================================================================
                                                        Variables
    ===================================================================================================================== */
    mapping(uint256 => mapping(address => UserInfo)) public userInfos;
    mapping(IERC20 => bool) public poolExistence;
    
    PoolInfo[] public poolInfos;
    
    address public devAddress;
    address public feeAddress;
    
    uint256 public coinPerBlock;
    uint256 public startBlock;
    uint256 public totalAllocPoint = 0;
    uint256 public depositedCoins = 0;
    uint256 public lastEmissionUpdateBlock;
    uint256 public lastEmissionIncrease = 0;
    uint16 public maxEmissionIncrease = 25000;
    
    /* =====================================================================================================================
                                                        Events
    ===================================================================================================================== */
    event NewPool(address indexed pool, uint256 indexed pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetMaxEmissionIncrease(address indexed user, uint16 newMaxEmissionIncrease);
    event UpdateEmissionRate(address indexed user, uint256 newEmission);
    
    /* =====================================================================================================================
                                                        Modifier
    ===================================================================================================================== */
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: lpToken already exists in poolInfos");
        _;
    }
    
    constructor(AboatToken _coin, address _devaddr, address _feeAddress, uint256 _startBlock) {
        coin = _coin;
        devAddress = _devaddr;
        feeAddress = _feeAddress;
        coinPerBlock = 100 ether;
        startBlock = _startBlock;
    }  

    /* =====================================================================================================================
                                                        Set Functions
    ===================================================================================================================== */
    function setDevAddress(address _devAddress) public onlyOwner locked("setDevAddress") {
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }
    
    function massUpdatePools() public {
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    function setPoolVariables(uint256 _pid, uint256 _allocPoint, uint16 _depositFee, bool _withUpdate) public onlyOwner {
        require(_depositFee <= 10000,"set: deposit fee can't exceed 10 %");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfos[_pid].allocPoint).add(_allocPoint);
        poolInfos[_pid].allocPoint = _allocPoint;
        poolInfos[_pid].depositFee = _depositFee;
    }
    
    function updateEmissionRate(uint256 _coinPerBlock) public onlyOwner locked("updateEmissionRate") {
        massUpdatePools();
        coinPerBlock = _coinPerBlock;
        emit UpdateEmissionRate(msg.sender, _coinPerBlock);
    }
    
    function updateEmissionRateInternal(uint256 _coinPerBlock) internal {
        massUpdatePools();
        coinPerBlock = _coinPerBlock;
        emit UpdateEmissionRate(address(this), _coinPerBlock);
    }
    
    function setMaxEmissionIncrease(uint16 _maxEmissionIncrease) public onlyOwner {
        maxEmissionIncrease = _maxEmissionIncrease;
        emit SetMaxEmissionIncrease(msg.sender, _maxEmissionIncrease);
    }
    
    /* =====================================================================================================================
                                                        Get Functions
    ===================================================================================================================== */
    function poolLength() external view returns (uint256) {
        return poolInfos.length;
    }
    
    function canClaimRewards(uint256 _amount) public view returns (bool) {
        return coin.canMintNewCoins(_amount);
    }
    
    function getNewEmissionRate(uint256 percentage, bool isPositiveChange) public view returns (uint256) {
        uint256 newEmissionRate = coinPerBlock;
        if(isPositiveChange) {
            newEmissionRate = newEmissionRate.add(newEmissionRate.mul(percentage).div(1000000));
        } else {
            newEmissionRate = newEmissionRate.sub(newEmissionRate.mul(percentage).div(1000000));
        }
        return newEmissionRate;
    }
    
    function getLpSupply(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfos[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        return lpSupply;
    }
    
    function pendingCoin(uint256 _pid, address _user) external view returns (uint256)
    {
        PoolInfo storage pool = poolInfos[_pid];
        UserInfo storage user = userInfos[_pid][_user];
        uint256 accCoinPerShare = pool.accCoinPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            uint256 coinReward = multiplier.mul(coinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCoinPerShare = accCoinPerShare.add(coinReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCoinPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    /* =====================================================================================================================
                                                    Utility Functions
    ===================================================================================================================== */
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFee, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFee <= 10000,"set: deposit fee can't exceed 10 %");
        if(_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfos.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCoinPerShare: 0,
                depositFee: _depositFee
            })
        );
        emit NewPool(address(_lpToken), poolInfos.length - 1);
    }
    
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 coinReward = multiplier.mul(coinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if(canClaimRewards(coinReward + coinReward.div(10))) {
            coin.mint(devAddress, coinReward.div(10));
            coin.mint(address(this), coinReward);
        }
        pool.accCoinPerShare = pool.accCoinPerShare.add(coinReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender];
        updatePool(_pid);
        if(user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCoinPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeCoinTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFee > 0) {
                uint256 depositFeeAmount = _amount.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFeeAmount);
                user.amount = user.amount.add(_amount).sub(depositFeeAmount);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCoinPerShare).div(1e12);
        if(pool.lpToken == coin) {
            depositedCoins += _amount;
        }
        emit Deposit(msg.sender, _pid, _amount);
        checkPriceUpdate();
    }
    
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: withdraw amount can't exceed users deposited amount");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCoinPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeCoinTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCoinPerShare).div(1e12);
        if(pool.lpToken == coin) {
            depositedCoins -= _amount;
        }
        emit Withdraw(msg.sender, _pid, _amount);
        checkPriceUpdate();
    }
    
    function claim(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCoinPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeCoinTransfer(msg.sender, pending);
            emit Claim(msg.sender, _pid, pending);
        }
        user.rewardDebt = user.amount.mul(pool.accCoinPerShare).div(1e12);
        checkPriceUpdate();
    }
    
    // Withdraw without caring about rewards.
    function withdrawWithoutRewards(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    function safeCoinTransfer(address _to, uint256 _amount) internal {
        uint256 coinBalance = coin.balanceOf(address(this)).sub(depositedCoins);
        bool transferSuccess = false;
        if (_amount > coinBalance) {
            transferSuccess = coin.transfer(_to, coinBalance);
        } else {
            transferSuccess = coin.transfer(_to, _amount);
        }
        require(transferSuccess, "safeCoinTransfer: transfer failed");
    }
    
    function checkPriceUpdate() override public {
        if(address(coin) == address(0) || address(coin.liquidityPair()) == address(0)) {
            return;
        }
        if (lastPriceUpdateBlock < block.timestamp - 1 hours) {
            uint256 tokenPrice = getTokenPrice();
            hourlyPrices[hourlyIndex++] = tokenPrice;
            lastPriceUpdateBlock = block.timestamp;
        }
        if (lastEmissionUpdateBlock < block.timestamp - 24 hours && hourlyIndex > 2) {
            uint256 averagePrice = getAveragePrice();
            lastEmissionUpdateBlock = block.timestamp;
            hourlyIndex = 0;
            bool shouldUpdateEmissionRate = lastAveragePrice != 0;
            updateLastAveragePrice(averagePrice);
            if(shouldUpdateEmissionRate) {
                updateEmissionRateByPriceDifference();
            }
        }
    }
    
    function updateEmissionRateByPriceDifference() internal {
        uint256 percentageDifference = getPriceDifference(int256(lastAveragePrice), int256(previousAveragePrice));
        if(percentageDifference > maxEmissionIncrease) {
            percentageDifference = maxEmissionIncrease;
        }
        uint256 newEmissionRate = getNewEmissionRate(percentageDifference, lastAveragePrice > previousAveragePrice);
        lastEmissionIncrease = percentageDifference;
        lastAveragePrice = lastAveragePrice;
        updateEmissionRateInternal(newEmissionRate);
    }
}


// File: gist-4b797c3b2b18c7686dfe0cc5d4798596/contracts/libraries/Liquify.sol



pragma solidity ^0.8.7;












abstract contract Liquify is ERC20, ReentrancyGuard, Ownable, TimeLock {
    using Address for address;
    using SafeMath for uint256;
    /* =====================================================================================================================
                                                        Variables
    ===================================================================================================================== */
    bool public isLiquifyDisabled = true;
    //Transfer Tax
    //Transfer tax rate in basis points. default 100 => 1%
    uint16 public minimumTransferTaxRate = 100;
    uint16 public maximumTransferTaxRate = 500;
    uint16 public constant MAXIMUM_TAX = 1000;
    
    uint16 public reDistributionRate = 40;
    uint16 public devRate = 20;
    uint16 public donationRate = 10;
    
    uint256 public _minAmountToLiquify = 100000 ether;
    
    address public _devWallet = 0x2EA9CA0ca8043575f2189CFF9897B575b0c7e857;          //Wallet where the dev fees will go to
    address public _donationWallet = 0xA7C08AEdCe8caDC3bFb622bd7B651993d1cd24e4;     //Wallet where donation fees will go to
    address public _rewardWallet = 0x2EA9CA0ca8043575f2189CFF9897B575b0c7e857;     //Wallet where rewards will be distributed
    
    address public _liquidityPair;
    
    IUniswapV2Router02 public _router;
    
    mapping(address => bool) public _excludedFromFeesAsSender;
    mapping(address => bool) public _excludedFromFeesAsReciever;
    
    /* =====================================================================================================================
                                                        Events
    ===================================================================================================================== */
    event MinimumTransferTaxRateUpdated(address indexed caller, uint256 previousRate, uint256 newRate);
    event MaximumTransferTaxRateUpdated(address indexed caller, uint256 previousRate, uint256 newRate);
    event ReDistributionRateUpdated(address indexed caller, uint256 previousRate, uint256 newRate);
    event DevRateUpdated(address indexed caller, uint256 previousRate, uint256 newRate);
    event DonationRateUpdated(address indexed caller, uint256 previousRate, uint256 newRate);
    event MinAmountToLiquifyUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event RouterUpdated(address indexed caller, address indexed router, address indexed pair);
    event ChangedLiqudityPair(address indexed caller, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    
    /* =====================================================================================================================
                                                        Modifier
    ===================================================================================================================== */
    modifier taxFree {
        uint16 _minimumTransferTaxRate = minimumTransferTaxRate;
        uint16 _maximumTransferTaxRate = maximumTransferTaxRate;
        minimumTransferTaxRate = 0;
        maximumTransferTaxRate = 0;
        _;
        minimumTransferTaxRate = _minimumTransferTaxRate;
        maximumTransferTaxRate = _maximumTransferTaxRate;
    }
    
    constructor() {
        excludeFromAll(_devWallet);
        excludeFromAll(_donationWallet);
        updateRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }
    
    /* =====================================================================================================================
                                                        Set Functions
    ===================================================================================================================== */
    function setLiquidityPair(address _tokenB) public onlyMaintainerOrOwner locked("lp_pair") {
        _liquidityPair = IUniswapV2Factory(_router.factory()).getPair(address(this), _tokenB);
        if(_liquidityPair == address(0)) {
            _liquidityPair = IUniswapV2Factory(_router.factory()).createPair(address(this), _tokenB);
        }
        excludeTransferFeeAsSender(address(_liquidityPair));
        emit ChangedLiqudityPair(msg.sender, _liquidityPair);
    }
    
    function setDevWallet(address wallet) public onlyMaintainerOrOwner {
        require(wallet != address(0), "ABOAT::setDevWallet: Address can't be zero address");
        _devWallet = wallet;
        excludeFromAll(_devWallet);
    }
    
    function setDonationWallet(address wallet) public onlyMaintainerOrOwner {
        require(wallet != address(0), "ABOAT::setDevWallet: Address can't be zero address");
        _donationWallet = wallet;
    }
    
    function setRewardWallet(address wallet) public onlyMaintainerOrOwner {
        require(wallet != address(0), "ABOAT::setDevWallet: Address can't be zero address");
        _rewardWallet = wallet;
        excludeFromAll(_rewardWallet);
    }
    
    /* =====================================================================================================================
                                                    Utility Functions
    ===================================================================================================================== */ 
    function disableLiquify() public onlyMaintainerOrOwner {
        isLiquifyDisabled = true;
    }
    
    function enableLiquify() public onlyMaintainerOrOwner {
        isLiquifyDisabled = false;
    }
    
    function excludeFromAll(address _excludee) public onlyMaintainerOrOwner {
        _excludedFromFeesAsSender[_excludee] = true;
        _excludedFromFeesAsReciever[_excludee] = true;
    }
    
    function excludeTransferFeeAsSender(address _excludee) public onlyMaintainerOrOwner {
        _excludedFromFeesAsSender[_excludee] = true;
    }
    
    function excludeFromFeesAsReciever(address _excludee) public onlyMaintainerOrOwner {
        _excludedFromFeesAsReciever[_excludee] = true;
    }
    
    function includeForAll(address _excludee) public onlyMaintainerOrOwner {
        _excludedFromFeesAsSender[_excludee] = false;
        _excludedFromFeesAsReciever[_excludee] = false;
    }
    
    function includeTransferFeeAsSender(address _excludee) public onlyMaintainerOrOwner {
        _excludedFromFeesAsSender[_excludee] = false;
    }
    
    function includeForFeesAsReciever(address _excludee) public onlyMaintainerOrOwner {
        _excludedFromFeesAsReciever[_excludee] = false;
    }
    
    function updateMinimumTransferTaxRate(uint16 _transferTaxRate) public onlyMaintainerOrOwner locked("min_tax") {
        require(_transferTaxRate <= maximumTransferTaxRate, "ABOAT::updateMinimumTransferTaxRate: minimumTransferTaxRate must not exceed maximumTransferTaxRate.");
        emit MinimumTransferTaxRateUpdated(msg.sender, minimumTransferTaxRate, _transferTaxRate);
        minimumTransferTaxRate = _transferTaxRate;
    }
    
    function updateMaximumTransferTaxRate(uint16 _transferTaxRate) public onlyMaintainerOrOwner locked("max_tax") {
        require(_transferTaxRate >= minimumTransferTaxRate, "ABOAT::updateMaximumTransferTaxRate: maximumTransferTaxRate must not be below minimumTransferTaxRate.");
        require(_transferTaxRate <= MAXIMUM_TAX, "ABOAT::updateMaximumTransferTaxRate: maximumTransferTaxRate must exceed MAXIMUM_TAX.");
        emit MaximumTransferTaxRateUpdated(msg.sender, minimumTransferTaxRate, _transferTaxRate);
        maximumTransferTaxRate = _transferTaxRate;
    }
    
    function updateRedistributionRate(uint16 _rate) public onlyMaintainerOrOwner locked("redistribution_rate") {
        require(_rate + devRate + donationRate <= 100, "ABOAT::updateRedistributionRate: Redistribution rate must not exceed the maximum rate.");
        emit ReDistributionRateUpdated(msg.sender, reDistributionRate, _rate);
        reDistributionRate = _rate;
    }
    
    function updateDevRate(uint16 _rate) public onlyMaintainerOrOwner locked("dev_rate") {
        require(_rate + donationRate + reDistributionRate <= 100, "ABOAT::updateDevRate: Burn rate must not exceed the maximum rate.");
        emit DevRateUpdated(msg.sender, devRate, _rate);
        devRate = _rate;
    }
    
    function updateDonationRate(uint16 _rate) public onlyMaintainerOrOwner locked("donation_rate") {
        require(_rate + devRate + reDistributionRate <= 100, "ABOAT::updateDonationRate: Burn rate must not exceed the maximum rate.");
        emit DonationRateUpdated(msg.sender, donationRate, _rate);
        donationRate = _rate;
    }
    
    function updateRouter(address router) public onlyMaintainerOrOwner locked("router") {
        _router = IUniswapV2Router02(router);
        setLiquidityPair(_router.WETH());
        excludeTransferFeeAsSender(router);
        emit RouterUpdated(msg.sender, router, _liquidityPair);
    }
    
    /* =====================================================================================================================
                                                    Liquidity Functions
    ===================================================================================================================== */
    
    /*
    * @dev Function to swap the stored liquidity fee tokens and add them to the current liquidity pool
    */
    function swapAndLiquify() public taxFree {
        if(isLiquifyDisabled) {
            return;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _minAmountToLiquify) {
            IUniswapV2Pair pair = IUniswapV2Pair(_liquidityPair);
            // only min amount to liquify
            uint256 liquifyAmount = _minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);


            address tokenA = address(pair.token0());
            address tokenB = address(pair.token1());
            require(tokenA != tokenB, "Invalid liqudity pair: Pair can\'t contain the same token twice");
            
            bool isWeth = tokenA == _router.WETH() || tokenB == _router.WETH();
            uint256 newBalance = 0;
            if(isWeth) {
               swapAndLiquifyEth(half, otherHalf);
            } else {
                swapAndLiquifyTokens(tokenA != address(this) ? tokenA : tokenB, half, otherHalf);
            }

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }
    
    function swapForEth(uint256 amount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
                
        // swap tokens for ETH
        swapTokensForEth(amount);
        
        return address(this).balance.sub(initialBalance);
    }
    
    function swapAndLiquifyEth(uint256 half, uint256 otherHalf) private {
        uint256 newBalance = swapForEth(half);
        addLiquidityETH(otherHalf, newBalance);
    }
    
    function swapAndLiquifyTokens(address tokenB, uint256 half, uint256 otherHalf) private {
        IERC20 tokenBContract = IERC20(tokenB);
        uint256 ethAmount = swapForEth(half);
        uint256 initialBalance = tokenBContract.balanceOf(address(this));
        swapEthForTokens(ethAmount, tokenB);
        uint256 newBalance = tokenBContract.balanceOf(address(this)).sub(initialBalance);
        addLiquidity(otherHalf, newBalance, tokenB);
    }
    
    function swapEthForTokens(uint256 tokenAmount, address tokenB) private {
        address[] memory path = new address[](2);
        path[0] = _router.WETH();
        path[1] = tokenB;
        
        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokenAmount}(
            0, // accept any amount of ETH
            path,
            address(this),
            0
        );
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the Enodi pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), tokenAmount);

        // make the swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            0
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 otherAmount, address tokenB) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_router), tokenAmount);
        IERC20(tokenB).approve(address(_router), otherAmount);
        _router.addLiquidity(
            address(this),
            tokenB,
            tokenAmount,
            otherAmount,
            0,
            0,
            address(0),
            0
        );
    }

    /// @dev Add liquidity
    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_router), tokenAmount);

        // add the liquidity
        _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0), //burn lp token
            0
        );
    }
    
}
// File: gist-4b797c3b2b18c7686dfe0cc5d4798596/contracts/AboatToken.sol


pragma solidity ^0.8.7;














/** @dev Implements Liquify which implements the TimeLock library.
 * @dev We use the maintainer for to hold the ability to change important attributes
 * @dev Owner will be given to the MasterEntertainer contract to mint new tokens for staking/yield farming
*/
contract AboatToken is ERC20, Liquify {
    using SafeMath for uint256;
    using Address for address;
    
    /* =====================================================================================================================
                                                        Variables
    ===================================================================================================================== */
    uint256 public maxDistribution = 1000000000000 ether;
    
    bool public isContractActive = false;
    bool public isHighFeeActive = true;
    uint16 public maxTxQuantity = 100;
    uint16 public maxAccBalance = 300;
    uint256 public gasCost = 2100000000000000;
    
    uint public totalFeesPaid;
    uint public devFeesPaid;
    uint public donationFeesPaid;
    uint public reDistributionFeesPaid;
    uint public liquidityFeesPaid;
    
    //Master Entertainer contract
    MasterEntertainer public _masterEntertainer;
    
    mapping(address => bool) private blacklisted;
    mapping(address => bool) private requestedWhitelist;
    
    /* =====================================================================================================================
                                                        Events
    ===================================================================================================================== */
    event ChangedHighFeeState(bool indexed state);
    event MasteEntertainerTransferred(address indexed previousMasterEntertainer, address indexed newMasterEntertainer);
    event MaxDistributionChanged(uint256 indexed newMaxDistribution);
    event RequestedWhitelist(address indexed requestee);
    event Blacklisted(address indexed user);
    event MaxAccBalanceChanged(uint16 indexed previousMaxBalance, uint16 indexed newMaxBalance);
    event MaxTransactionQuantityChanged(uint16 indexed previousMaxTxQuantity, uint16 indexed newMaxTxQuantity);
    event GasCostChanged(uint256 indexed previousGasCost, uint256 indexed newGasCost);
    /* =====================================================================================================================
                                                        Modifier
    ===================================================================================================================== */
    
    constructor() ERC20("Aboat Token", "ABOAT") {
        // Token distribution: https://documentation.talkaboat.online/tokenomics/talkaboat-basics.html
        mint(msg.sender, 600000000000 ether);
        excludeFromAll(msg.sender);
    }
    
    /* =====================================================================================================================
                                                        Set Functions
    ===================================================================================================================== */
    function setMasterEntertainer(address _newMasterEntertainer) public onlyMaintainerOrOwner locked("masterEntertainer") {
        require(_newMasterEntertainer != address(_masterEntertainer) && _newMasterEntertainer != address(0), "ABOAT::setMasterEntertainer: Master entertainer can\'t equal previous master entertainer or zero address");
        address previousEntertainer = address(_masterEntertainer);
        _masterEntertainer = MasterEntertainer(_newMasterEntertainer);
        excludeFromAll(_newMasterEntertainer);
        transferOwnership(_newMasterEntertainer);
        emit MasteEntertainerTransferred(previousEntertainer, _newMasterEntertainer);
    }
    
    function setMaxDistribution(uint256 _newDistribution) public onlyMaintainerOrOwner locked("max_distribution") {
        require(_newDistribution > totalSupply(), "ABOAT::setMaxDistribution: Distribution can't be lower than the current total supply");
        maxDistribution = _newDistribution;
        emit MaxDistributionChanged(_newDistribution);
    }
    
    function setMaxAccBalance(uint16 maxBalance) public onlyMaintainerOrOwner {
        uint16 previousMaxBalance = maxAccBalance;
        maxAccBalance = maxBalance;
        emit MaxAccBalanceChanged(previousMaxBalance, maxAccBalance);
    }
    
    function setMaxTransactionQuantity(uint16 quantity) public onlyMaintainerOrOwner {
        uint16 previous = maxTxQuantity;
        maxTxQuantity = quantity;
        emit MaxTransactionQuantityChanged(previous, maxTxQuantity);
    }
    
    function setGasCost(uint256 cost) public onlyMaintainerOrOwner {
        uint256 previous = gasCost;
        gasCost = cost;
        emit GasCostChanged(previous, gasCost);
    }

    
    /* =====================================================================================================================
                                                        Get Functions
    ===================================================================================================================== */
    function isExcludedFromSenderTax(address _account) public view returns (bool) {
        return _excludedFromFeesAsSender[_account];
    }
    
    function isExcludedFromRecieverTax(address _account) public view returns (bool) {
        return _excludedFromFeesAsReciever[_account];
    }
    
    function hasRequestedWhitelist(address user) public onlyMaintainerOrOwner view returns (bool) {
        return requestedWhitelist[user];
    }
    
    function getTaxFee(address _sender) public view returns (uint256) {
        //Anti-Bot: The first Blocks will have a 99% fee
        if(isHighFeeActive) {
            return 9000;
        }
        uint balance = balanceOf(_sender);
        if(balance > totalSupply()) {
            return maximumTransferTaxRate;
        }
        else if(balance < totalSupply() / 100000) {
            return minimumTransferTaxRate;
        }
        uint tax = balance * 100000 / totalSupply();
        if(tax >= maximumTransferTaxRate) {
            return maximumTransferTaxRate;
        } else if(tax <= minimumTransferTaxRate) {
            return minimumTransferTaxRate;
        }
        return tax;
    }
    
    function liquidityPair() public view returns (address) {
        return _liquidityPair;
    }
    
    function getLiquidityTokenAddress() public view returns (address) {
        IUniswapV2Pair pair = IUniswapV2Pair(_liquidityPair);
        address tokenA = address(pair.token0());
        address tokenB = address(pair.token1());
        return tokenA != address(this) ? tokenA : tokenB;
    }
    
    function liquidityTokenBalance() public view returns (uint256) {
        return IERC20(getLiquidityTokenAddress()).balanceOf(address(this));
    }
    
    function canMintNewCoins(uint256 _amount) public view returns (bool) {
        return totalSupply() + _amount <= maxDistribution;
    }
    
    /* =====================================================================================================================
                                                    Utility Functions
    ===================================================================================================================== */
    
    receive() external payable {}
    
    function activateHighFee() public onlyMaintainerOrOwner {
        isHighFeeActive = true;
        emit ChangedHighFeeState(isHighFeeActive);
    }
    
    function deactivateHighFee() public onlyMaintainerOrOwner {
        isHighFeeActive = false;
        isContractActive = true;
        emit ChangedHighFeeState(isHighFeeActive);
    }
    
    function blacklist(address user) public onlyMaintainerOrOwner {
        blacklisted[user] = true;
        emit Blacklisted(user);
    }
    
    function whitelist(address user) public onlyMaintainerOrOwner {
        blacklisted[user] = true;
        requestedWhitelist[user] = false;
    }
    
    function requestWhitelist() public payable {
        require(blacklisted[msg.sender], "ABOAT::requestWhitelist: You are not blacklisted!");
        require(!requestedWhitelist[msg.sender], "ABOAT::requestWhitelist: You already requested whitelist!");
        require(msg.value >= gasCost, "ABOAT::requestWhitelist: Amount of bnb to claim should carry the cost to add the claimable");
        TransferHelper.safeTransferETH(_devWallet, msg.value);
        requestedWhitelist[msg.sender] = true;
        emit RequestedWhitelist(msg.sender);
    }
    
    function claimExceedingETH() public onlyMaintainerOrOwner {
        require(address(this).balance > 0, "ABOAT::claimExceedingLiquidityTokenBalance: No exceeding balance");
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(canMintNewCoins(_amount), "ABOAT::mint: Can't mint more aboat token than maxDistribution allows");
        _mint(_to, _amount);
    }
    
    function burn(uint256 _amount) public onlyMaintainerOrOwner {
        require(_amount <= balanceOf(address(this)), "ABOAT::burn: amount exceeds balance");
        _burn(address(this), _amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "ABOAT::_transfer: transfer from the zero address");
        require(recipient != address(0), "ABOAT::_transfer: transfer to the zero address");
        require(amount > 0, "ABOAT::_transfer:Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender), "ABOAT::_transfer:Transfer amount must be lower or equal senders balance");
        //Anti-Bot: If someone sends too many recurrent transactions in a short amount of time he will be blacklisted
        require(!blacklisted[sender], "ABOAT::_transfer:You're currently blacklisted. Please report to [email protected] if you want to get removed from blacklist!");
        //Anti-Bot: Disable transactions with more than 1% of total supply
        require(amount * 10000 / totalSupply() <= maxTxQuantity || sender == owner() || sender == maintainer() || _excludedFromFeesAsSender[sender] || _excludedFromFeesAsReciever[sender], "Your transfer exceeds the maximum possible amount per transaction");
        //Anti-Whale: Only allow wallets to hold a certain percentage of total supply
        require((amount + balanceOf(recipient)) * 10000 / totalSupply() <= maxAccBalance || recipient == owner() || recipient == maintainer() || recipient == address(this) || _excludedFromFeesAsReciever[recipient] || _excludedFromFeesAsSender[recipient], "ABOAT::_transfer:Balance of recipient can't exceed maxAccBalance");
        //Liquidity Provision safety
        require(isContractActive || sender == owner() || sender == maintainer() || _excludedFromFeesAsReciever[recipient] || _excludedFromFeesAsSender[sender], "ABOAT::_transfer:Contract is not yet open for community");
        if (address(_router) != address(0)
            && _liquidityPair != address(0)
            && sender != _liquidityPair
            && !_excludedFromFeesAsSender[sender]
            && sender != owner()
            && sender != maintainer()) {
            swapAndLiquify();
        }
        if ((!isHighFeeActive || sender == maintainer() || sender == owner() || _excludedFromFeesAsSender[sender] && _excludedFromFeesAsReciever[recipient]) && (recipient == address(0) || maximumTransferTaxRate == 0 || _excludedFromFeesAsReciever[recipient] || _excludedFromFeesAsSender[sender])) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 0.5% of every transfer
            uint256 taxAmount = amount.mul(getTaxFee(sender)).div(10000);
            uint256 reDistributionAmount = taxAmount.mul(reDistributionRate).div(100);
            uint256 devAmount = taxAmount.mul(devRate).div(100);
            uint256 donationAmount = taxAmount.mul(donationRate).div(100);
            uint256 liquidityAmount = taxAmount.sub(reDistributionAmount.add(devAmount).add(donationAmount));
            require(taxAmount == reDistributionAmount + liquidityAmount + devAmount + donationAmount, "ABOAT::transfer: Fee amount does not equal the split fee amount");
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "ABOAT::transfer: amount to send with tax amount exceeds maximum possible amount");
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            super._transfer(sender, _devWallet, devAmount);
            super._transfer(sender, _donationWallet, donationAmount);
            super._transfer(sender, _rewardWallet, reDistributionAmount);
            amount = sendAmount;
            totalFeesPaid += taxAmount;
            devFeesPaid += devAmount;
            donationFeesPaid += donationAmount;
            liquidityFeesPaid += liquidityAmount;
        }
        checkPriceUpdate();
    }

    function checkPriceUpdate() public {
        if(address(_masterEntertainer) != address(0)) {
            _masterEntertainer.checkPriceUpdate();
        }
    }
}