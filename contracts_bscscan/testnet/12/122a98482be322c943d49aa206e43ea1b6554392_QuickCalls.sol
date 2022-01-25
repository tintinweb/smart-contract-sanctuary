/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: Staking 1 token for any LP Token

// Farmageddon's Staking contract

pragma solidity ^0.8.0;

interface routerAddress{

    function WETH() external pure returns (address);
    
// Token Swaps
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

// liquidity calls
 
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

// remove liquidity calls
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    
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

contract QuickCalls is Ownable {
    using SafeERC20 for IERC20;

    uint256 MAX_INT = 2**256 - 1;
    address router;
    address router2;
    // address bnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // mainnet
    address bnbAddress = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // testnet

    uint256 public MaxFee = 10000000000000000;    //    --  ((ExtraBNB - MaxFee) / (FeeFactor / 100)) sent back to user
    uint256 public FeeFactor = 400;               //    -- factor divide by  100    400 = divide by 4        
    uint256 public BNBSTORED = 0;
    uint256 public FeePercent = 2;                //  -- Fee Percent for unstake fee. 980 = 98%

// set Routers and Tokens
    routerAddress RA;
    routerAddress RA2;   

    IERC20 TokenLP;
    IERC20 TokenA;
    IERC20 TokenB;
    IERC20 TokenH;

// Fee required before the user gets funds back
    function _SetMaxFee(uint256 _MaxFee) external onlyOwner {
        MaxFee = _MaxFee;
    }

// divisor for Returned fees. 400 they get 1/4 , 200 they 1/2
    function _setFeeFactor(uint256 _feeFactor) external onlyOwner {
        FeeFactor = _feeFactor;
    }
    
    function _SetFeePercent(uint256 _FeePercent) external onlyOwner {
        FeePercent = _FeePercent;
    }
    
    function _1StakeUsingBNB (address _TokenA, address _TokenB, address _routerAddress, address _routerAddress2) external payable {
        router = _routerAddress;
        router2 = _routerAddress2;
        _1TokenInLPTokenOut(msg.value, bnbAddress, _TokenA, _TokenB);
    }

    function _1StakeToken (uint256 _TokenInput, address _TokenH, address _TokenA, address _TokenB, address _routerAddress, address _routerAddress2) external {
        router = _routerAddress;
        router2 = _routerAddress2;
        _1TokenInLPTokenOut(_TokenInput, _TokenH, _TokenA, _TokenB);
    }

    function _1TokenInLPTokenOut(uint256 _TokenInput, address _TokenH, address _TokenA, address _TokenB ) private {
    if (_TokenA == bnbAddress) {
        (_TokenA, _TokenB) = (_TokenB, _TokenA);
    }
    
    
        // Set variables;
    uint256 InitialB = 0;
    uint256 preTransfer = 0;
    uint256 Transfered = 0;
    uint256 preSwap1 = 0;
    uint256 postSwap1 = 0;
    uint256 preSwap2a = 0;
    uint256 swapAmount = 0;
    uint256 LPTokenAAmount = 0;
    uint256 QTTokenAmount = 0;
    
    if ( _TokenB == bnbAddress ) {
        InitialB = BNBSTORED;
      } else {
        InitialB = balanceCheck(_TokenB);
      }

        // set tokens for swaps
        RA = routerAddress(router);
        RA2 = routerAddress(router2); 
        TokenH = IERC20(_TokenH);
        TokenA = IERC20(_TokenA);
        TokenB = IERC20(_TokenB);
        

// Pre Transfer Check if BNB will use Token Input
        if (_TokenH != bnbAddress){
        preTransfer = balanceCheck(_TokenH);
        TokenH.safeTransferFrom(address(msg.sender), (address(this)), _TokenInput);
        }
                
//Post Transfer checks
        if (_TokenH == bnbAddress) {
            Transfered = _TokenInput;
        } else {
            Transfered = balanceCheck(_TokenH) - preTransfer;
        }

        
// calculate swap amount
        if (_TokenH == _TokenB) {
             swapAmount = 0;
        } else if (_TokenH == _TokenA) {
            swapAmount = (Transfered / 100 * (50 + FeePercent));
        } else {
            swapAmount = Transfered;
        }

    checkAllowance1(_TokenH, swapAmount, router);

// Pre Swap one balance
        preSwap1 = balanceCheck(_TokenB);

// perform swap One is swap amount 0 ie. tokenH == tokenB skip this swap as we already have token B
        if (swapAmount > 0) {
            
                uint256 midswap = balanceCheck(bnbAddress);
                address[] memory path = new address[](2);
                path[0] = _TokenH;
                path[1] = RA.WETH();
                RA.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
                );
// if tokenB is not BNB we will swap to Token B using ROUTER2
                if (_TokenB != bnbAddress){
                    swapAmount = balanceCheck(bnbAddress) - midswap;
                    address[] memory path2 = new address[](2);
                    path2[0] = RA2.WETH();
                    path2[1] = _TokenB;
                    RA2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount} (
                    0,
                    path2,
                    address(this),
                    block.timestamp
                    );  
                }
            
            }
// post swap checks for Token B
            if (_TokenH == _TokenB) {
                postSwap1 = Transfered;            
            } else { 
                postSwap1 = balanceCheck(_TokenB) - preSwap1;
            }

// Pre Swap 2 check for Token A
            preSwap2a = balanceCheck(_TokenA);
 // perform swap if Token H is Token A skipped to LP creation as we made the swap above.           
            if (_TokenH != _TokenA) {
// set swap amount
                swapAmount = (postSwap1 / 100 * (50 - FeePercent));

            checkAllowance1(_TokenB, swapAmount, router2);
// perform swap
                if (_TokenB == bnbAddress) {
                    address[] memory path3 = new address[](2);
                    path3[0] = RA2.WETH();
                    path3[1] = _TokenA;
                    RA2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount} (
                    0,
                    path3,
                    address(this),
                    block.timestamp
                    );  

                } else {
                    uint256 midswap2 = balanceCheck(bnbAddress);
                    address[] memory path4 = new address[](2);
                    path4[0] = _TokenB;
                    path4[1] = RA2.WETH();
                    RA2.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path4,
                    address(this),
                    block.timestamp
                    );
                    
                    swapAmount = balanceCheck(bnbAddress) - midswap2;
                    address[] memory path5 = new address[](2);
                    path5[0] = RA2.WETH();
                    path5[1] = _TokenA;
                    RA2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount} (
                    0,
                    path4,
                    address(this),
                    block.timestamp
                    );  
                }
            } 
                
// Check Actual tokens after Swap and prep for adding liquidity
        if ( _TokenA == _TokenH) {
            LPTokenAAmount = preSwap2a;
            QTTokenAmount = postSwap1;
        } else {
            LPTokenAAmount = balanceCheck(_TokenA) - preSwap2a;
            QTTokenAmount = balanceCheck(_TokenB) - InitialB;
        }
    
            checkAllowance1(_TokenA, LPTokenAAmount, router2);
            checkAllowance1(_TokenB, QTTokenAmount, router2);

// add liquidity
            if (_TokenB == bnbAddress) {
                RA2.addLiquidityETH{value: QTTokenAmount} (
                _TokenA,
                LPTokenAAmount,
                0,
                0,
                msg.sender,
                block.timestamp
                );
            } else {
                RA2.addLiquidity(
                _TokenA,
                _TokenB,
                LPTokenAAmount,
                QTTokenAmount,
                0,
                0,
                msg.sender,
                block.timestamp
                );
            }

// Return Extra BNB
   if (_TokenB == bnbAddress){
        if ((address(this).balance - BNBSTORED)  > MaxFee * 2) {
            returnBNB(((address(this).balance - BNBSTORED) - MaxFee) / (FeeFactor / 100));
        }
    }
// set stored BNB                  
        BNBSTORED = address(this).balance;
}

// Function for Breaking LP and returning 1 Token

    function _BreakLPReturnToken (address _LPToken, uint256 _TokenInput, address _TokenA, address _TokenB, address _router, address _TokenH, address _router2) external {
        
        if (_TokenA == bnbAddress) {
            (_TokenA, _TokenB) = (_TokenB, _TokenA);
        }

        uint256 initialA = 0;
        uint256 initialB = 0;
        uint256 initialH = 0;
        uint256 bnb2 = 0;
        uint256 post1A = 0;
        uint256 post1B = 0;

        RA = routerAddress(_router);
        RA2 = routerAddress(_router2);
        TokenLP = IERC20(_LPToken);
        TokenH = IERC20(_TokenH);
        TokenA = IERC20(_TokenA);
        TokenB = IERC20(_TokenB);
        
        initialA = balanceCheck(_TokenA);
        initialB = balanceCheck(_TokenB);
        initialH = balanceCheck(_TokenH);
        BNBSTORED = address(this).balance;
        
        TokenLP.safeTransferFrom(address(msg.sender), (address(this)), _TokenInput);
        
        checkAllowance1(_LPToken, _TokenInput, _router);
        
// Remove Liquidity to Tokens        
        if (_TokenB == bnbAddress) {
            RA.removeLiquidityETHSupportingFeeOnTransferTokens(
            _TokenA,
            _TokenInput,
            1,
            1,
            address(this),
            block.timestamp
            );
        } else {
            RA.removeLiquidity(
            _TokenA,
            _TokenB,
            _TokenInput,
            1,
            1,
            address(this),
            block.timestamp
            );
        }
// Set post quantities
    post1A = balanceCheck(_TokenA) - initialA;
    post1B = balanceCheck(_TokenB) - initialB;      
        

    
// Swap Token A to ETH
             if (_TokenA != _TokenH ) {
                checkAllowance1(_TokenA, post1A, _router);
                address[] memory path6 = new address[](2);
                path6[0] = _TokenA;
                path6[1] = RA.WETH();
                RA.swapExactTokensForETHSupportingFeeOnTransferTokens(
                post1A,
                0,
                path6,
                address(this),
                block.timestamp
                );
             }   

    
// IF B is not BNB swap token B to BNB
            if (_TokenB != _TokenH) {
                if (_TokenB != bnbAddress) {
                    checkAllowance1(_TokenB, post1B, _router);
                    address[] memory path7 = new address[](2);
                    path7[0] = _TokenB;
                    path7[1] = RA.WETH();
                    RA.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    post1B,
                    0,
                    path7,
                    address(this),
                    block.timestamp
                    );
                }
            }
            
     bnb2 = ((address(this).balance - BNBSTORED) * (100 - FeePercent) / 100 );
            
// if Output token is NOT bnb. swap to output token
            
           if (_TokenH == bnbAddress) {
                returnBNB(bnb2);
           } else {    

                    address[] memory path8 = new address[](2);
                    path8[0] = RA.WETH();
                    path8[1] = _TokenH;
                    RA2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnb2} (
                    0,
                    path8,
                    address(this),
                    block.timestamp
                    );
                    
                    TokenH.safeTransfer(address(msg.sender), (balanceCheck(_TokenH) - initialH)); 
            
           }
            
    
        BNBSTORED = address(this).balance;
    
    }
// HARVEST AND SWAP TO A TOKEN w/Fee
        function _harvestToToken(address _TokenIn, uint256 _AmountIn, address _TokenOut, address _RouterIn, address _RouterOut) external {
            require(_TokenIn != _TokenOut, "Token: Token In cannot be Token Out");
            require(_AmountIn > 0, "Token In Amount must be greater than 0");
            require(_TokenIn != bnbAddress, "Token: Token In Cannot be BNB");

        
        RA = routerAddress(_RouterIn);
        RA2 = routerAddress(_RouterOut);
        TokenA = IERC20(_TokenIn);
        TokenB = IERC20(_TokenOut);
        uint256 initialA = balanceCheck(_TokenIn);

                    TokenA.safeTransferFrom(address(msg.sender), (address(this)), _AmountIn);
        uint256 SwapAmount = balanceCheck(_TokenOut) - initialA;
                
                    checkAllowance1(_TokenIn, SwapAmount, _RouterIn);
                    address[] memory path7 = new address[](2);
                    path7[0] = _TokenIn;
                    path7[1] = RA.WETH();
                    RA.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    SwapAmount,
                    0,
                    path7,
                    address(this),
                    block.timestamp
                    );        

        uint256 bnb2 = ((address(this).balance - BNBSTORED) * (100 - FeePercent) / 100 );
            if (_TokenOut == bnbAddress) {
                returnBNB(bnb2);
            } else {
                    address[] memory path8 = new address[](2);
                    path8[0] = RA.WETH();
                    path8[1] = _TokenOut;
                    RA2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnb2} (
                    0,
                    path8,
                    msg.sender,
                    block.timestamp
                    );
            }

             BNBSTORED = address(this).balance;

    }

// calls used in functions
        function checkAllowance1(address _Token, uint256 _amount, address _router) private {
            if (IERC20(_Token).allowance(address(this),_router) < _amount){
                    IERC20(_Token).approve(_router, MAX_INT);
                }
        }

        function returnBNB(uint256 amount) private {
            payable(msg.sender).transfer(amount);
        }

        function balanceCheck(address _Token) private view returns (uint256) {
            if (_Token == bnbAddress){
                uint256 balance = address(this).balance;
                return balance;
            } else {
                uint256 balance = IERC20(_Token).balanceOf(address(this));
                return balance;
            }
        }

        // backup functions to recover tokens and/or BNB

        function withdawlBNB() external onlyOwner {
            payable(msg.sender).transfer(BNBSTORED);
            BNBSTORED = address(this).balance;
        }

        function withdrawlBUSD() external onlyOwner {
            address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
            uint256 Amount = balanceCheck(busd);
            IERC20(busd).safeTransfer(address(msg.sender), Amount);
        }

        function withdrawlToken(address _tokenAddress) external onlyOwner {
            uint256 _tokenAmount = balanceCheck(_tokenAddress);
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }  

    // to receive Eth From Router when Swapping
    receive() external payable {}
}