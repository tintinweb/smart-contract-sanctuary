/**
 *Submitted for verification at BscScan.com on 2021-12-26
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
}

contract Compost is Ownable {
    using SafeERC20 for IERC20;

    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public bnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public FGToken = 0x4492cA0AFF6D603e18Aea5075B49A5ff76b9Ea06;
    uint256 public FGMin = 0;
    uint256 public FeeFactor = 8000000000000000; //    --  ((ExtraBNB - FeeFactor) / 2) sent back to user
    uint256 public BNBSTORED = 0;

    routerAddress RA;
    IERC20 FG;

    IERC20 TokenA;
    IERC20 TokenB;
    IERC20 TokenH;

    function _SetupAddresses(address _routerAddress, address _bnbAddress, address _FGToken ) external onlyOwner {
        router = _routerAddress;
        RA = routerAddress(router);
        FGToken = _FGToken;
        FG = IERC20(FGToken);
        bnbAddress = _bnbAddress; 
    }

    function _SetFGMin(uint256 _FGMin) external onlyOwner {
        FGMin = _FGMin;
    }

    function _SetFeefactor(uint256 _MaxFee) external onlyOwner {
        FeeFactor = _MaxFee;
    }
    
    function _1StakeUsingBNB (address _TokenA, address _TokenB) external payable {
        _1TokenInLPTokenOut(msg.value, bnbAddress, _TokenA, _TokenB);
    }

    function _1StakeToken (uint256 _TokenInput, address _TokenH, address _TokenA, address _TokenB) external {
        _1TokenInLPTokenOut(_TokenInput, _TokenH, _TokenA, _TokenB);
    }

    function _1TokenInLPTokenOut(uint256 _TokenInput, address _TokenH, address _TokenA, address _TokenB ) private {
    if (_TokenA == bnbAddress) {
        (_TokenA, _TokenB) = (_TokenB, _TokenA);
    }
        // Set variablesuint256 Transfered;
    uint256 Transfered = 0;
    uint256 preSwap1 = 0;        // initial Balance of H    
    uint256 preSwap2 = 0;        // initial Balance of B
    uint256 postswap2 = 0;
    uint256 preSwap3a = 0;       // initial Balance of A
    uint256 swapAmount = 0;
    uint256 LPTokenAAmount = 0;
    uint256 QTTokenAmount = 0;

        // set tokens for swaps
        RA = routerAddress(router); 
        TokenH = IERC20(_TokenH);
        TokenA = IERC20(_TokenA);
        TokenB = IERC20(_TokenB);
        FG = IERC20(FGToken);

        // Confirm user has more than FGmin tokens
        uint256 fgbalance = FG.balanceOf(address(msg.sender));
        require(fgbalance > FGMin, "Farmageddon Token Balance too Low");
        
        // Pre Transfer Check ( if BNB will use BNBSTORED
        if (_TokenH != bnbAddress){
        preSwap1 = balanceCheck(_TokenH);
        }
        // Transfer Token To contract
        if (_TokenH != bnbAddress) {
            TokenH.safeTransferFrom(address(msg.sender), (address(this)), _TokenInput);
        }
        //Post Transfer checks
        if (_TokenH == bnbAddress) {
            Transfered = msg.value;
        } else {
            Transfered = balanceCheck(_TokenH) - preSwap1;
        }

        // Pre Swap two balances
        preSwap2 = balanceCheck(_TokenB);
        
        // calculate swap amount
        if (_TokenH == _TokenB) {
             swapAmount = 0;
        } else if (_TokenH == _TokenA) {
            swapAmount = (Transfered / 100 * 51);
        } else {
            swapAmount = Transfered;
        }

        checkAllowance1(_TokenH, swapAmount);
                
        // perform swap two
        if (swapAmount > 0) {
            if (_TokenB == bnbAddress) {
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
            } else {
                address[] memory path1 = new address[](3);
                path1[0] = _TokenH;
                path1[1] = RA.WETH();
                path1[2] = _TokenB;
                // Make the Swap
                RA.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path1,
                address(this),
                block.timestamp
                );
            }
        }
            // post swap checks
            if (_TokenH == _TokenB) {
                postswap2 = Transfered;            
            } else { 
                postswap2 = balanceCheck(_TokenB) - preSwap2;
            }
            // Pre Swap 3 check
            preSwap3a = balanceCheck(_TokenA);
            
            if ( _TokenH != _TokenA) {
                // set swap amount
                swapAmount = (postswap2 / 100 * 49);

                checkAllowance1(_TokenB, swapAmount);
                // perform swap
                if (_TokenB == bnbAddress) {
                    address[] memory path2 = new address[](2);
                    path2[0] = RA.WETH();
                    path2[1] = _TokenA;
                    RA.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapAmount} (
                    0,
                    path2,
                    address(this),
                    block.timestamp
                    );  

                } else {
                    address[] memory path3 = new address[](3);
                    path3[0] = _TokenB;
                    path3[1] = RA.WETH();
                    path3[2] = _TokenA;
                    RA.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path3,
                    address(this),
                    block.timestamp
                    );
                } 
            }        
        // Check Actual tokens after Swap and prep for adding liquidity
        if ( _TokenA == _TokenH) {
            LPTokenAAmount = preSwap3a;
            QTTokenAmount = postswap2;
        } else {
            LPTokenAAmount = balanceCheck(_TokenA) - preSwap3a;
            QTTokenAmount = postswap2 - balanceCheck(_TokenB);
        }
    
            checkAllowance1(_TokenA, LPTokenAAmount);
            checkAllowance1(_TokenB, QTTokenAmount);

            // add liquidity
            if (_TokenB == bnbAddress) {
                RA.addLiquidityETH{value: QTTokenAmount} (
                _TokenA,
                LPTokenAAmount,
                0,
                0,
                msg.sender,
                block.timestamp
                );
            } else {
                RA.addLiquidity(
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
        if ((address(this).balance - BNBSTORED)  > FeeFactor * 2) {
            returnBNB(((address(this).balance - BNBSTORED) - FeeFactor) / 2);
        }
    }
        // set stored BNB                  
        BNBSTORED = address(this).balance;
}

        function checkAllowance1(address _Token, uint256 _amount) private {
            if (IERC20(_Token).allowance(address(this),router) < _amount){
                    IERC20(_Token).approve(router,(_amount * 2));
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
        function rescueBNB(uint256 amount) external onlyOwner{
            payable(msg.sender).transfer(amount);
            BNBSTORED = address(this).balance;
        }

        function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
         IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

    // to receive Eth From Router when Swapping
    receive() external payable {}
}