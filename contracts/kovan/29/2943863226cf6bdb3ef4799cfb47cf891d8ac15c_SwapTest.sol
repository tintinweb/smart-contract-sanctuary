/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT @GoPocketStudio
pragma solidity 0.7.5;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory) {
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
contract Ownable is Context {
    address public _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library UintLibrary {
    function toString(uint256 i) internal pure returns (string memory c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        c = string(bstr);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
}


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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
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
}

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

library SafeERC20 {
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function WETH() external pure returns (address);
    
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

contract SwapTest is Ownable{

    using StringLibrary for string;
    using UintLibrary for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    uint256 constant MAX_ALLOWANCE = ~uint256(0);

    constructor() {
    }

    function reverseArray(address[] memory path) public pure returns (address[] memory reversedPath){
        reversedPath = new address[](path.length);
        for(uint8 i = 0; i < path.length; i++){
            reversedPath[i] = path[path.length - i - 1];
        }
    }
    
    function getBalances(address[] memory path) internal view returns (uint256 balance0, uint256 balance1){
        IERC20 token0 = IERC20(path[0]);
        balance0 = token0.balanceOf(address(this));
        IERC20 token1 = IERC20(path[path.length - 1]);
        balance1 = token1.balanceOf(address(this));
    }
    
    function approveTokens(address[] memory path, address _routerAddress) internal {
        IERC20 token0 = IERC20(path[0]);
        token0.safeApprove(_routerAddress, MAX_ALLOWANCE);
        IERC20 token1 = IERC20(path[path.length - 1]);
        token1.safeApprove(_routerAddress, MAX_ALLOWANCE);
    }
    
    function testSwapTokensForTokens(uint amountBuyIn, address[] calldata path, address _routerAddress) external {
        require(amountBuyIn > 0, "amountBuyIn must > 0");
        require(path.length >= 2, "path.length must >= 2");
        
        approveTokens(path, _routerAddress);
        IUniswapV2Router uniswapV2Router = IUniswapV2Router(_routerAddress);
        
        //get origin balance of Token0 & Token1
        (, uint256 originToken1Balance) = getBalances(path);
        //calc expected buy amount out
        uint256[] memory amountBuyOuts = uniswapV2Router.getAmountsOut(amountBuyIn, path);
        uint256 expectedBuyOut = amountBuyOuts[amountBuyOuts.length - 1];
        //build result string
        string memory result = "[";
        result = result.append(expectedBuyOut.toString());
        result = result.append(",");
        //swap from path[0] to path[-1]
        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountBuyIn, 0, path, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        (uint256 swapOnceToken0Balance , uint256 swapOnceToken1Balance) = getBalances(path);
        uint256 realBuyOut = swapOnceToken1Balance - originToken1Balance;
        result = result.append(realBuyOut.toString());
        if (realBuyOut > 0) {
            result = result.append(",");
        } else {
            result = result.append("]");
            require(false, result);
        }

        address[] memory reversedPath = reverseArray(path);
        //calc expected sell amount out
        uint256[] memory amountSellOuts = uniswapV2Router.getAmountsOut(realBuyOut, reversedPath);
        uint256 expectedSellOut = amountSellOuts[amountSellOuts.length - 1];
        result = result.append(expectedSellOut.toString());
        result = result.append(",");
        //swap from path[-1] to path[0]
        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(realBuyOut, 0, reversedPath, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        (uint256 swapTwiceToken0Balance , ) = getBalances(path);
        uint256 realSellOut = swapTwiceToken0Balance - swapOnceToken0Balance;

        result = result.append(realSellOut.toString());
        result = result.append("]");
        require(false, result);
    }
    
    function testSwapETHForTokens(uint amountBuyIn, address[] calldata path, address _routerAddress) external {
        require(amountBuyIn > 0, "amountBuyIn must > 0");
        require(path.length >= 2, "path.length must >= 2");
        
        IUniswapV2Router uniswapV2Router = IUniswapV2Router(_routerAddress);
        address WETH = uniswapV2Router.WETH();
        require(path[0] == WETH, "path[0] must be WETH");
        approveTokens(path, _routerAddress);
        
        IERC20 token1 = IERC20(path[path.length - 1]);

        //get origin balance of Token0 & Token1
        uint256 originToken0Balance = address(this).balance;
        require(originToken0Balance > amountBuyIn, "Insufficient Balance Of ETH");
        uint256 originToken1Balance = token1.balanceOf(address(this));
        //calc expected buy amount out 
        uint256[] memory amountBuyOuts = uniswapV2Router.getAmountsOut(amountBuyIn, path);
        uint256 expectedBuyOut = amountBuyOuts[amountBuyOuts.length - 1];
        //build result string
        string memory result = "[";
        result = result.append(expectedBuyOut.toString());
        result = result.append(",");
        //swap from path[0] to path[-1]
        try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBuyIn}(0, path, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        uint256 swapOnceToken0Balance = address(this).balance;
        uint256 swapOnceToken1Balance = token1.balanceOf(address(this));
        uint256 realBuyOut = swapOnceToken1Balance - originToken1Balance;
        result = result.append(realBuyOut.toString());
        if (realBuyOut > 0) {
            result = result.append(",");
        } else {
            result = result.append("]");
            require(false, result);
        }

        address[] memory reversedPath = reverseArray(path);
        //calc expected sell amount out
        uint256[] memory amountSellOuts = uniswapV2Router.getAmountsOut(realBuyOut, reversedPath);
        uint256 expectedSellOut = amountSellOuts[amountSellOuts.length - 1];
        result = result.append(expectedSellOut.toString());
        result = result.append(",");
        //swap from path[-1] to path[0]
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(realBuyOut, 0, reversedPath, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        uint256 swapTwiceToken0Balance = address(this).balance;
        uint256 realSellOut = swapTwiceToken0Balance - swapOnceToken0Balance;

        result = result.append(realSellOut.toString());
        result = result.append("]");
        require(false, result);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address(_owner).toPayable().transfer(balance);
    }
    
    function withdraw(address tokenAddress, uint256 amount) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_owner, amount);
    }
    
    receive() external payable {
        
    }
}