/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

//SPDX-License-Identifier: MIT
// File: Holdable.sol
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

contract Holdable {
    using SafeMath for uint256;
    
    constructor() {
        holdholders.push();
    }
    
    struct Hold{
        address user;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
    }
    struct Holdholder{
        address user;
        Hold[] holds;
    }
    struct HoldSummary{
        uint256 totalRewardAmount;
        Hold[] holds;
    }

    Holdholder[] internal holdholders;
    mapping(address => uint256) internal holdsIndex;
    
    event Holded(address indexed user, uint256 amount, uint256 startDate, uint256 endDate, uint256 index);

    function addHoldholder(address account) internal returns (uint256){
        holdholders.push();
        uint256 userIndex = holdholders.length - 1;
        
        holdholders[userIndex].user = account;
        holdsIndex[account] = userIndex;
        
        return userIndex;
    }

    function hold(address account, uint256 amount) internal{
        require(amount > 0, "Cannot stake nothing");
        
        uint256 index = holdsIndex[account];
        uint256 timestamp = block.timestamp;
        
        if(index == 0){
            index = addHoldholder(account);
        }

        holdholders[index].holds.push(Hold(account, amount, timestamp,  0));

        emit Holded(account, amount, timestamp, 0, index);
    }

    function withdrawHold(address account, uint256 amount) internal{
        uint256 txAmount = amount;
        Hold[] memory accountHolds = holdholders[holdsIndex[account]].holds;

        for (uint256 s = accountHolds.length; s > 0; s--){
            if (accountHolds[s - 1].endDate == 0 && txAmount > 0){
                if (accountHolds[s - 1].amount > txAmount){
                    //Add new hold
                    holdholders[holdsIndex[account]].holds.push(Hold(account, txAmount, 
                        accountHolds[s - 1].startDate, block.timestamp));
                        
                    emit Holded(account, txAmount, accountHolds[s - 1].startDate, 
                        block.timestamp, holdsIndex[account]);
                    
                    holdholders[holdsIndex[account]].holds[s - 1].amount = holdholders[holdsIndex[account]].holds[s - 1].amount - txAmount;

                    txAmount = 0;
                    break;
                } else {
                    holdholders[holdsIndex[account]].holds[s - 1].endDate = block.timestamp;
                    
                    txAmount = txAmount - holdholders[holdsIndex[account]].holds[s - 1].amount;
                }
            } else {
                break;
            }
        }
    }
    
    function calculateReward(address account, uint256 totalSupply, uint256 bnbPool, uint256 rewardCycleBlock) internal view returns(uint256){
        HoldSummary memory holdSummary = HoldSummary(0, getHoldsForAddress(account));
        
        for(uint256 s = 0; s < holdSummary.holds.length; s++){
            uint256 multiplier = 100;
            uint256 date = 0;
            uint256 rewardPerCycle = bnbPool.mul(multiplier).mul(holdSummary.holds[s].amount).div(100).div(totalSupply);

            if (holdSummary.holds[s].endDate == 0){
                date = block.timestamp.sub(holdSummary.holds[s].startDate);
            } else {
                date = holdSummary.holds[s].endDate.sub(holdSummary.holds[s].startDate);
            }

            uint256 rewardForAllCycles = rewardPerCycle.mul(multiplier).mul(date).div(100).div(rewardCycleBlock);
            
            holdSummary.totalRewardAmount = holdSummary.totalRewardAmount + rewardForAllCycles;
        }
        
        return holdSummary.totalRewardAmount;
    }
    
    function getHoldsForAddress(address account) internal view returns(Hold[] memory){
        return holdholders[holdsIndex[account]].holds;
    }
    
    function deleteHoldsForAddress(address account) internal{
        delete holdholders[holdsIndex[account]].holds;
        
    }
}

// File: Utils.sol
pragma solidity >=0.6.8;

library Utils {
    using SafeMath for uint256;
    
    //Pancake Swap
    function swapTokensForBnb(
        address routerAddress,
        uint256 tokenAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        //Make the swap.
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //Accept any amount of BNB.
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBnbForTokens(
        address routerAddress,
        address pathTo,
        address recipient,
        uint256 bnbAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(pathTo);

        //Make the swap.
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, //Accept any amount of BNB.
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
    function swapTokensForTokens(
        address routerAddress,
        address recipient,
        uint256 bnbAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb.
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        //Make the swap
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bnbAmount, //Wbnb input.
            0, //Accept any amount of BNB.
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
    
    function getAmountsOut(uint256 amount,
        address routerAddress
    ) public view returns(uint256 _amount) {
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Generate the pancake pair path of token -> wbnb.
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        //Fetch current rate.
        uint[] memory amounts = pancakeRouter.getAmountsOut(amount,path);
        return amounts[1];
    }

    function addLiquidity(
        address routerAddress,
        uint256 tokenAmount,
        uint256 bnbAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        //Add the liquidity.
        pancakeRouter.addLiquidityETH{value : bnbAmount}(
            address(this),
            tokenAmount,
            0, //Slippage is unavoidable.
            0, //Slippage is unavoidable.
            address(this), // <- The liquidity is send to the contract itself.
            block.timestamp + 360
        );
    }
}

// File: IPancakeRouter.sol
pragma solidity >=0.6.8;

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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
// File: IPancakePair.sol
pragma solidity >=0.6.8;

interface IPancakePair {
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
// File: IPancakeFactory.sol
pragma solidity >=0.6.8;

interface IPancakeFactory {
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
// File: ReentrancyGuard.sol
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
     * by making the `nonReentrant` function external, and making it call a
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
    
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

// File: Context.sol
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

// File: Ownable.sol
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Address.sol
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

// File: SafeMath.sol
pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: IERC20.sol
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

// File: IERC20Metadata.sol
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

// File: ERC20.sol
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

// File: Draconite.sol

pragma solidity >=0.6.8;

contract Draconite is Context, IERC20, Ownable, Holdable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    //Tokenomics.
    string private constant _name = "Draconite";
    string private constant _symbol = "DCN";
    uint8 private constant _decimals = 15;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 public _maxTxAmount = _tTotal; 
    
    //Trace BNB claimed rewards. 
    mapping(address => uint256) public _userClaimedBNB;
    uint256 public _totalClaimedBNB = 0;
    
    //Trace reinvested token rewards.
    mapping(address => uint256) public _userReinvested;
    uint256 public _totalReinvested = 0;
    
    //Draconite wallets.
    address public _marketingAddress = 0xF123b7c24d122B2Bba509F399e611BA2A3086A8f;
    address public _charityAddress = 0x243685ae6bA5eC3F12e71d5923BeA5fA95bf53BF;
    
    address public immutable BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    
    //Tx fees in %.
    uint256 private _liquidityFee = 5;
    uint256 private _redistributionFee = 5;
    uint256 private _bnbRewardFee = 5;
    uint256 private _prizePoolFee = 2;
    uint256 private _marketingFee = 2;
    uint256 private _charityFee = 1;
    
    uint256 private _previousLiquidityFee;
    uint256 private _previousRedistributionFee;
    uint256 private _previousRewardFee;
    uint256 private _previousPricePoolFee;
    uint256 private _previousMarketingFee;
    uint256 private _previousCharityFee;
    
    //Fee for charity when account redeem reward in BNB.
    uint256 public _rewardPrizePoolFee = 10; //%
    uint256 public _rewardBNBThreshHold = 1 ether;
    
    //Indicator if a tx is a buy tx.
    bool private _buyTx = false;
    
    uint256 private unlockPrizePoolDate;
    uint256 private unlockPrizePoolCycle = 12 weeks;
    
    //Store tokens from each buy tx.
    uint256 private _tTokensFromBuyTxs;
    
    //Total reflected fee.
    uint256 private _tFeeTotal;
    
    //Total reward hard cap from the bnb pool size measured in %.
    uint256 public _rewardHardCap = 10; 
    
    //Reward availability.
    uint256 public _rewardCycleBlock = 1 weeks;
    mapping(address => uint256) public _nextAvailableClaimDate;

    uint256 public _minTokenNumberUpperLimit = _tTotal.mul(2).div(100).div(10); 
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;

    address[] private _excluded;
    
    bool private inPresale = false;
    
    //Swap bool and modifier.
    bool public _swapAndLiquifyEnabled = false; //Should be true in order to add liquidity.
    bool _inSwapAndLiquify = false;
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    //Router and pair.
    IPancakeRouter02 public _pancakeRouter;
    address public _pancakePair;
    
    //Events.
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    event SwapTokenForRewards(uint256 amount);
    event ClaimedBNBReward(address recipient, uint256 bnbReward, uint256 nextAvailableClaimDate, 
        uint256 timestamp);
    event ClaimedBNBReinvestment(address recipient, uint256 bnbReinvested, uint256 tokensReceived, 
        uint256 nextAvailableClaimDate, uint256 timestamp);
    event ExcludeAddressFromRewards(address account);
    event IncludeRewardsForAddress(address account);
    event ExcludeAddressFromFee(address account);
    event IncludeFeeForAddress(address account);
    event ChangeFeePercent(uint256 typeFee, uint256 taxFee, uint256 prevTaxFee);
    event ChangeMaxTxAmount(uint256 txAmount);
    event AddressExcludedFromMaxTxAmount(address account);
    event ChangeMarketingAddress(address account);
    event ChangeCharityAddress(address account);
    event ChangeRewardCycleBlock(uint256 rewardCycleBlock);
    event ChangeRewardHardCap(uint256 rewardHardCap);
    event PrizePoolSentToWinners(address firstwinner, address secondWinner, address thirdWinner, 
        uint256 firstPrize, uint256 secondPrize, uint256 thirdPrize, uint256 unlockPrizePoolDate);

    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _pancakePair = IPancakeFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());
        _pancakeRouter = pancakeRouter;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[_marketingAddress] = true;
        _isExcludedFromMaxTx[_charityAddress] = true;
        _isExcludedFromMaxTx[address(0)] = true;
       
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    /*
        Public functions.
    */
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function circulatingSupply() public view returns (uint256) {
        return uint256(_tTotal)
        .sub(balanceOf(address(0)));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        
        (,,,uint256 rAmount,,) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (,,,uint256 rAmount,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,,,,uint256 rTransferAmount,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function getRewardCycleBlock() public view returns (uint256) {
        return _rewardCycleBlock;
    }

    function calculateBNBReward(address ofAddress) public view returns (uint256) {
        uint256 bnbPool = address(this).balance;
        uint256 bnbReward = calculateReward(ofAddress, circulatingSupply(), bnbPool, getRewardCycleBlock());
        
        if (bnbReward > bnbPool.mul(_rewardHardCap).div(100))
            bnbReward = bnbPool.div(10);
            
        return bnbReward;
    }
    
    function redeemRewards(uint256 perc) isHuman nonReentrant public {
        uint256 timestamp = block.timestamp;
        require(_nextAvailableClaimDate[msg.sender] <= timestamp, 'Error: next available not reached');
        require(balanceOf(msg.sender) >= 0, 'Error: must own Draconite to claim reward');

        uint256 reward = calculateBNBReward(msg.sender);
        uint256 rewardBNB = reward.mul(perc).div(100);
        uint256 rewardReinvest = reward.sub(rewardBNB);
        
        uint256 expectedtoken = 0;
        
        _nextAvailableClaimDate[msg.sender] = timestamp + getRewardCycleBlock();
        
        if (rewardReinvest > 0) {
            //expectedtoken = Utils.getAmountsOut(rewardReinvest, address(_pancakeRouter)); 
            expectedtoken = balanceOf(msg.sender);
            
            Utils.swapBnbForTokens(address(_pancakeRouter), address(this), msg.sender, rewardReinvest);
            
            expectedtoken = balanceOf(msg.sender) - expectedtoken;
            
            _userReinvested[msg.sender] += expectedtoken;
            _totalReinvested = _totalReinvested + expectedtoken;
            
            emit ClaimedBNBReinvestment(msg.sender, rewardReinvest, expectedtoken, _nextAvailableClaimDate[msg.sender], timestamp);
        }
        
        if (rewardBNB > 0) { 
            //Collect 10% tax for price pool from each collected reward if more than threshhold
            if (rewardBNB > _rewardBNBThreshHold){
                uint256 rewardPricePoolFee = rewardBNB.mul(_rewardPrizePoolFee).div(100);
                
                (bool success, ) = address(_marketingAddress).call{ value: rewardPricePoolFee }("");
                require(success, " Error: Cannot send reward");
                
                rewardBNB = rewardBNB.sub(rewardPricePoolFee);
            }
            
            (bool sent,) = address(msg.sender).call{value : rewardBNB}("");
            require(sent, 'Error: Cannot withdraw reward');

            _userClaimedBNB[msg.sender] += rewardBNB;
            _totalClaimedBNB = _totalClaimedBNB.add(rewardBNB);
            
            emit ClaimedBNBReward(msg.sender, rewardBNB, _nextAvailableClaimDate[msg.sender], timestamp);
        }
        
        deleteHoldsForAddress(msg.sender);
        hold(msg.sender, balanceOf(msg.sender));
    }

    /*
        Functions that can be used by the owner of the contract.
    */
    function activateContract() public onlyOwner {
        prepareLaunch();
        
        //Protocol
        setMaxTxPercent(10000);
        setSwapAndLiquifyEnabled(true);
        unlockPrizePoolDate = block.timestamp.add(12 weeks);
        
        //Exclude Owner and Pair addresses from rewards
        excludeFromReward(address(0x652ccCdfaE41bfe346bA1C00a1CebD7b262AafF0));
        excludeFromReward(address(_pancakeRouter));
        
        //Approve contract
        _approve(address(this), address(_pancakeRouter), 2 ** 256 - 1);
    }
    
    function preparePresale() public onlyOwner {
        require (inPresale == false, "Presale is already activated!");
        
        if (_redistributionFee == 0 && _liquidityFee == 0 &&
            _prizePoolFee == 0 && _marketingFee == 0 &&
            _charityFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousRedistributionFee = _redistributionFee;
        _previousPricePoolFee = _prizePoolFee;
        _previousMarketingFee = _marketingFee;
        _previousCharityFee = _charityFee;
      
        _liquidityFee = 0;
        _redistributionFee = 0;
        _prizePoolFee = 0;
        _marketingFee = 0;
        _charityFee = 0;
        
        inPresale = true;
    }
    
    function prepareLaunch() private {
        if (inPresale == true){
            _redistributionFee = _previousRedistributionFee;
            _liquidityFee = _previousLiquidityFee;
            _prizePoolFee = _previousPricePoolFee;
            _marketingFee = _previousMarketingFee;
            _charityFee = _previousCharityFee;
        }
    }

    function changePancakeRouter(address newRouter) public onlyOwner {
        require(newRouter != address(_pancakeRouter), "Draconite: The router already has that address.");
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(newRouter);
        _pancakePair = IPancakeFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());

        _pancakeRouter = pancakeRouter;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        
        emit ExcludeAddressFromRewards(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        
        emit IncludeRewardsForAddress(account);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        
        emit ExcludeAddressFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        
        emit IncludeFeeForAddress(account);
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
        
        emit ChangeMaxTxAmount(_maxTxAmount);
    }   

    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = value;
        
        emit AddressExcludedFromMaxTxAmount(_address);
    }    

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        _swapAndLiquifyEnabled = _enabled;
        
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeMarketingAddress(address payable newAddress) public onlyOwner {
        _marketingAddress = newAddress;
        
        emit ChangeMarketingAddress(_marketingAddress);
    }
    
    function changeCharityAddress(address payable newAddress) public onlyOwner {
        _charityAddress = newAddress;
        
        emit ChangeCharityAddress(_charityAddress);
    }

    function changeRewardCycleBlock(uint256 newcycle) public onlyOwner {
        _rewardCycleBlock = newcycle;
        
        emit ChangeRewardCycleBlock(_rewardCycleBlock);
    }
    
    function migrateToken(address newAddress, uint256 amount) public onlyOwner {
        removeAllFee();
        
        _transferStandard(address(this), newAddress, amount);
        
        restoreAllFee();
    }

    function migrateBnb(address payable newAddress, uint256 amount) public onlyOwner {
        (bool success, ) = address(newAddress).call{ value: amount }("");
        require(success, "Address: unable to send value, charity may have reverted");    
    }
    
    function migrateBusd(address payable newAddress, uint256 amount) public onlyOwner {
        IERC20(BUSD).transfer(newAddress, amount);
    }

    function changeMinTokenNumberUpperLimit(uint256 newValue) public onlyOwner {
        _minTokenNumberUpperLimit = newValue;
    }
    
    function getTokensFromBuyTx() public view onlyOwner returns(uint256){
        return _tTokensFromBuyTxs;
    }
    
    function useTokensFromBuyTx() public onlyOwner {
        require(_tTokensFromBuyTxs > 0, "Not enough stashed tokens.");
        uint256 multiplier = 100;
        
        //Raw fee
        uint256 bnbRewardFee = _bnbRewardFee;
        uint256 prizePoolFee = _prizePoolFee;
        uint256 charityFee = _charityFee;
        
        //Total raw fees
        uint256 totalTxFees = bnbRewardFee.add(prizePoolFee).add(charityFee);
        
        uint256 totalTokensFromTxFees = _tTokensFromBuyTxs;
        
        uint256 percTokensForPrizePool = prizePoolFee.mul(multiplier).div(totalTxFees);
        uint256 percTokensForCharity = charityFee.mul(multiplier).div(totalTxFees);
        
        uint256 initialBalance = address(this).balance;

        Utils.swapTokensForBnb(address(_pancakeRouter), totalTokensFromTxFees);
        
        uint256 swappedBnb = address(this).balance.sub(initialBalance);
        
        //Send fees in busd to the correct addresses
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), address(this), swappedBnb.mul(percTokensForPrizePool).div(100));
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), _charityAddress, swappedBnb.mul(percTokensForCharity).div(100));
        
        _tTokensFromBuyTxs = 0;
    }
    
    function sendPrizePool(address payable firstwinner, address payable secondWinner, address payable thirdWinner) public onlyOwner {
        require(block.timestamp >= unlockPrizePoolDate);
        
        uint256 BUSDBalance = IERC20(BUSD).balanceOf(address(this));
        
        uint256 firstPrize = BUSDBalance.div(2);
        uint256 secondPrize = BUSDBalance.div(4);
        uint256 thirdPrize = BUSDBalance.div(4);
        
        IERC20(BUSD).transfer(firstwinner, firstPrize);
        IERC20(BUSD).transfer(secondWinner, secondPrize);
        IERC20(BUSD).transfer(thirdWinner, thirdPrize);
        
        unlockPrizePoolDate = block.timestamp.add(unlockPrizePoolCycle);
        
        emit PrizePoolSentToWinners(firstwinner, secondWinner, thirdWinner, firstPrize, secondPrize, thirdPrize, unlockPrizePoolDate);
    }

    /*
        Private functions for usage by the contract.
    */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeRefund(uint256 tSumFee) private {
        uint256 currentRate = _getRate();
        uint256 rSumFee = tSumFee.mul(currentRate);
        
        _rOwned[address(this)] = _rOwned[address(this)].add(rSumFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tSumFee);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10 ** 2
        );
    }
    
    function calculateRedistributionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_redistributionFee).div(
            10 ** 2
        );
    }

    function calculateBnbRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_bnbRewardFee).div(
            10 ** 2
        );
    }

    function calculatePrizePoolFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_prizePoolFee).div(
            10 ** 2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10 ** 2
        );
    }

    function calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(
            10 ** 2
        );
    }
    
    function prepareBuyTx() private {
        if (_redistributionFee == 0 && _liquidityFee == 0 &&_marketingFee == 0) {
            return;
        }
        
        _previousLiquidityFee = _liquidityFee;
        _previousRedistributionFee = _redistributionFee;
        _previousMarketingFee = _marketingFee;
      
        _liquidityFee = 0;
        _redistributionFee = 0;
        _marketingFee = 0;
    }
    
    function afterBuyTx() private {
        _redistributionFee = _previousRedistributionFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }
    
    function removeAllFee() private {
        if (_redistributionFee == 0 && _liquidityFee == 0 &&
            _prizePoolFee == 0 && _marketingFee == 0 &&
            _charityFee == 0 && _bnbRewardFee == 0) return;

        _previousLiquidityFee = _liquidityFee;
        _previousRedistributionFee = _redistributionFee;
        _previousPricePoolFee = _prizePoolFee;
        _previousMarketingFee = _marketingFee;
        _previousCharityFee = _charityFee;
        _previousRewardFee = _bnbRewardFee;
      
        _liquidityFee = 0;
        _redistributionFee = 0;
        _bnbRewardFee = 0;
        _prizePoolFee = 0;
        _marketingFee = 0;
        _charityFee = 0;
    }

    function restoreAllFee() private {
        _redistributionFee = _previousRedistributionFee;
        _liquidityFee = _previousLiquidityFee;
        _prizePoolFee = _previousPricePoolFee;
        _marketingFee = _previousMarketingFee;
        _charityFee = _previousCharityFee;
        _bnbRewardFee = _previousRewardFee;
    }
    
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tSumFee, _getRate());
        
        return (tTransferAmount, tFee, tSumFee, rAmount, rTransferAmount, rFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateRedistributionFee(tAmount);
        uint256 tSumFee = calculateLiquidityFee(tAmount).add(calculatePrizePoolFee(tAmount))
            .add(calculateMarketingFee(tAmount)).add(calculateCharityFee(tAmount))
            .add(calculateBnbRewardFee(tAmount));
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tSumFee);
        
        return (tTransferAmount, tFee, tSumFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tSumFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rSumFee = tSumFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rSumFee);
            
        return (rAmount, rTransferAmount, rFee);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function ensureMaxTxAmount(address from, address to, uint256 amount) private view {
        if (
            _isExcludedFromMaxTx[from] == false && 
            _isExcludedFromMaxTx[to] == false
        ) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        ensureMaxTxAmount(from, to, amount);
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool enoughUtilityTokens = contractTokenBalance >= _minTokenNumberUpperLimit;
        
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        if (from != address(_pancakePair)){
            if (
                !_inSwapAndLiquify &&
                _swapAndLiquifyEnabled &&
                enoughUtilityTokens &&
                !(from == address(this) && 
                to == address(_pancakePair)) &&
                !(from == address(this)) && 
                amount > 0
            ) {
                swapAndLiquify(calculateLiquidityFee(amount), calculateBnbRewardFee(amount),
                    calculatePrizePoolFee(amount), calculateMarketingFee(amount), calculateCharityFee(amount));
            }
            _buyTx = false;
        } else {
            _buyTx = true;
        }

        bool takeFee = true;

        //If any account belongs to _isExcludedFromFee account or reflections are disabled then remove the fee 
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        //Make the transfer
        _tokenTransfer(from, to, amount, takeFee);
    }
    
    function swapAndLiquify(uint256 tokensAmountForLiquidity, uint256 tokensAmountToBeSwappedForUserRewards,
        uint256 tokenAmountForPricePool, uint256 tokenAmountForMarketing, uint256 tokenAmountForCharity) private {

        //Add liquidity
        uint256 tokensAmountForLiquidityToBeSwapped = tokensAmountForLiquidity.div(2);
        uint256 tokensAmountToBeSwapped = tokensAmountForLiquidityToBeSwapped.add(tokensAmountToBeSwappedForUserRewards)
            .add(tokenAmountForPricePool).add(tokenAmountForMarketing).add(tokenAmountForCharity);
            
        uint256 initialBalance = address(this).balance;

        Utils.swapTokensForBnb(address(_pancakeRouter), tokensAmountToBeSwapped);
        
        uint256 swappedBnb = address(this).balance.sub(initialBalance);
        
        uint256 bnbToBeAddedToLiquidity = swappedBnb.div(5);
        
        swappedBnb = swappedBnb.sub(bnbToBeAddedToLiquidity);
        
        //Аdd liquidity to pancake
        Utils.addLiquidity(address(_pancakeRouter), tokensAmountForLiquidityToBeSwapped, bnbToBeAddedToLiquidity);
        
        emit SwapAndLiquify(
            tokensAmountForLiquidityToBeSwapped, 
            swappedBnb, 
            tokensAmountForLiquidityToBeSwapped
        );
        
        //Send fees in busd to the correct addresses
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), _marketingAddress, swappedBnb.div(5));
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), _charityAddress, swappedBnb.div(10));
        Utils.swapBnbForTokens(address(_pancakeRouter), address(BUSD), address(this), swappedBnb.div(5));
        
        emit SwapTokenForRewards(swappedBnb);
    }
    
    //To receive BNB from pancakeRouter when swapping
    receive() external payable {}

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        } else if (_buyTx) {
            prepareBuyTx();
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if (_nextAvailableClaimDate[recipient] == 0) {
            _nextAvailableClaimDate[recipient] = block.timestamp + getRewardCycleBlock();
        }
            
        if (!takeFee) {
            restoreAllFee();
        } else if (_buyTx) {
            afterBuyTx();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        
        //Set amount for sender and manage staked amounts.
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        //Check for excluded accounts
        withdrawHold(sender, tAmount);
        
        //Set amount for recipient and manage staked amounts.
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //Check for excluded accounts
        hold(recipient, tTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
            
        //Set amount for sender.
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        //Check for excluded accounts
        withdrawHold(sender, tAmount);
        
        //Set amount for recipient.
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        
        //Set amount for sender.
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        //Set amount for recipient.
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //Check for excluded accounts
        hold(recipient, rTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        //Set values.
        (uint256 tTransferAmount, uint256 tFee, uint256 tSumFee, 
        uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getValues(tAmount);
        
        //Set amount for sender.
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        //Set amount for recipient.
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        //Refund the liquidity and reward fees to the contract.
        _takeRefund(tSumFee);
        
        //Reflect fee calculation.
        _reflectFee(rFee, tFee);
        
        //If buy transaction indicate the number of tokens for handle.
        if (_buyTx)
            _tTokensFromBuyTxs = _tTokensFromBuyTxs + tSumFee;
        
        //Event for the completed transfer.
        emit Transfer(sender, recipient, tTransferAmount);
    }
}