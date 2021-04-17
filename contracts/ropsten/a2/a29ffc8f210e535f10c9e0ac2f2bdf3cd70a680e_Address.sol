/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-01
*/




// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

interface IERC20 {


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



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
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

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;
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

contract Sanction is Context {

    uint private approveFunction;
    address private approveAddress;
    uint256 private approveUint256;
    bool private approveBool;
    
    uint256 private _lockTime;

    uint private owner1Approval = 0;
    uint private owner2Approval = 0;
    uint private owner3Approval = 0;
    uint private owner4Approval = 0;

    address private _owner1;
    address private _owner2;
    address private _owner3;
    address private _owner4;

    address private _previousOwner1;
    address private _previousOwner2;
    address private _previousOwner3;
    address private _previousOwner4;
    
    // internal action indexes
    // set arbitriraly high so as not to affect main contract usage
    uint private _changeOwner1 = 94;
    uint private _changeOwner2 = 95;            
    uint private _changeOwner3 = 96;            
    uint private _changeOwner4 = 97;             
    uint private _lock = 98;                    
    uint private _renounceOwnership = 99;

    constructor (address owner1, address owner2, address owner3, address owner4) internal {
        _owner1 = owner1;
        _owner2 = owner2;
        _owner3 = owner3;
        _owner4 = owner4;
    }

    function owner1() public view returns (address) {
        return _owner1;
    }
    function owner2() public view returns (address) {
        return _owner2;
    }
    function owner3() public view returns (address) {
        return _owner3;
    }
    function owner4() public view returns (address) {
        return _owner4;
    }

    modifier onlyOwners() {
        require(_msgSender() == _owner1 || _msgSender() == _owner2 || _msgSender() == _owner3 || _msgSender() == _owner4, "Ownable: caller has to be one of the 4 owners");
        _;
    }
    
    function getApproveFunction() public view onlyOwners returns (uint) {
        return approveFunction;
    }
    
    function getApproveUint256() public view onlyOwners returns (uint256) {
        return approveUint256;
    }

    function getApproveAddress() public view onlyOwners returns (address) {
        return approveAddress;
    }

    function getApproveBool() public view onlyOwners returns (bool) {
        return approveBool;
    }
    
    function hasApproval(uint action, address value1, uint256 value2) internal returns (bool) {
        bool result = false;
        bool approved = (approveFunction == uint(action) && approveAddress == value1 && approveUint256 == value2);
        uint voteCount = owner1Approval + owner2Approval + owner3Approval + owner4Approval;
        
        if(approved && voteCount >= 3){
            result = true;
            resetApproval();
        }
        
        return result;
    }
    
    function hasApprovalAddress(uint action, address value) internal returns (bool) {
        bool result = false;
        bool approved = (approveFunction == uint(action) && approveAddress == value);
        uint voteCount = owner1Approval + owner2Approval + owner3Approval + owner4Approval;
        if(approved && voteCount >= 3)
        {
            result = true;
            resetApproval();
        }
        return result;
    }

    function hasApprovalUint(uint action, uint256 value) internal returns (bool) {
        bool result = false;
        bool approved = (approveFunction == uint(action) && approveUint256 == value);
        uint voteCount = owner1Approval + owner2Approval + owner3Approval + owner4Approval;
        
        if(approved && voteCount >= 3)
        {
            result = true;
            resetApproval();
        }
        return result;
    }

    function hasApprovalBool(uint action, bool value) internal returns (bool) {
        bool result = false;
        bool approved = (approveFunction == uint(action) && approveBool == value);
        uint voteCount = owner1Approval + owner2Approval + owner3Approval + owner4Approval;
        if(approved && voteCount >= 3)
        {
            result = true;
            resetApproval();
        }
        return result;
    }

    function confirmVote() private {
        if(_msgSender() == _owner1){            
            owner1Approval = 1;
        }
        if(_msgSender() == _owner2){
            owner2Approval = 1;
        }
        if(_msgSender() == _owner3){
            owner3Approval = 1;
        }
        if(_msgSender() == _owner4){
            owner4Approval = 1;
        }
    }

    function approveChangeAddress(uint action, address value) public onlyOwners {
        if(approveFunction == 0){ // first vote
            approveFunction = action;
            approveAddress = value;
            confirmVote();
        } else if (approveFunction == action && approveAddress == value){ //2nd & 3rd vote
            confirmVote();
        }          
    }

    function approveChangeUint(uint action, uint256 value) public onlyOwners {
        if(approveFunction == 0){
            approveFunction = action;
            approveUint256 = value;
            confirmVote();
        } else if (approveFunction == action && approveUint256 == value){
            confirmVote();
        }          
    }
    
    function approveChangeAddressUint(uint action, address value1, uint256 value2) public onlyOwners {
        if(approveFunction == 0){
            approveFunction = action;
            approveAddress = value1;
            approveUint256 = value2;
            confirmVote();
        } else if (approveFunction == action && approveAddress == value1 && approveUint256 == value2){
            confirmVote();
        }          
    }

    function approveChangeBool(uint action, bool value) public onlyOwners {
        if(approveFunction == 0){
            approveFunction = action;
            approveBool = value;
            confirmVote();
        } else if (approveFunction == action && approveBool == value){
            confirmVote();
        }          
    }

    function resetApproval() public onlyOwners {
        owner1Approval = 0;
        owner2Approval = 0;
        owner3Approval = 0;
        owner4Approval = 0;
        approveFunction = 0;
    }


    function renounceOwnership(bool agree) public onlyOwners {
        if(hasApprovalBool(_renounceOwnership, agree)){
            _owner1 = address(0);
            _owner2 = address(0);
            _owner3 = address(0);
            _owner4 = address(0);
        }
    }    

    function changeOwner1(address newOwner) public onlyOwners {
        if(hasApprovalAddress(_changeOwner1, newOwner)){
            _owner1 = newOwner;
        }           
    }


    function changeOwner2(address newOwner) public onlyOwners {
        if(hasApprovalAddress(_changeOwner2, newOwner)){
            _owner2 = newOwner;
        }        
    }

    function changeOwner3(address newOwner) public onlyOwners {
        if(hasApprovalAddress(_changeOwner3, newOwner)){
            _owner3 = newOwner;
        }        
    }
    
    function changeOwner4(address newOwner) public onlyOwners {
        if(hasApprovalAddress(_changeOwner3, newOwner)){
            _owner4 = newOwner;
        }  
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    // Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public onlyOwners {

        if(hasApprovalUint(_lock, time)){
            _previousOwner1 = _owner1;
            _previousOwner2 = _owner2;
            _previousOwner3 = _owner3;
            _previousOwner4 = _owner4;
            _owner1 = address(0);
            _owner2 = address(0);
            _owner3 = address(0);
            _owner4 = address(0);
            _lockTime = now + time;
        }
    }
    
    // Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public {
        require(_previousOwner1 == msg.sender || _previousOwner2 == msg.sender || _previousOwner3 == msg.sender || _previousOwner4 == msg.sender , "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");        
        _owner1 = _previousOwner1;
        _owner2 = _previousOwner2;
        _owner3 = _previousOwner3;
        _owner4 = _previousOwner4;
    }

}

contract Phoenix is Context, IERC20, Sanction {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public Wallets;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 40000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Phoenix";
    string private _symbol = "PNX";
    uint8 private _decimals = 9;
    
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _burnFee = 1;
    uint256 private _previousburnFee = _burnFee;

    uint256 public _communityFee = 1;
    uint256 private _previousCommunityFee = _communityFee;

    uint256 public _charityFee = 1;
    uint256 private _previousCharityFee = _charityFee;
    
    address public _communityAddress;
    address public _charityAddress;  
    address public _liquidityTaxAddress; 

    address private _burnAddress = 0x1650E360b3d80b977184810ae8ae66F9F7763Fc4;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 1000 * 10**6 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 200 * 10**6 * 10**9;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );    
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (address _owner1, address _owner2, address _owner3, address _owner4, address communityAddress, address charityAddress)  public Sanction(_owner1, _owner2, _owner3, _owner4)  {
        
        _liquidityTaxAddress = _burnAddress;
        _communityAddress = communityAddress;
        _charityAddress = charityAddress;        
        
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
         // Create a uniswap pair for this new token                                                                        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner1 (deployer) and this contract from fee
        _isExcludedFromFee[owner1()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_communityAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);   
        
    }
    
    // identifiers used for approving a function
    enum ActionType {
        empty,                    // 0
        excludeFromFee,          // 1
        excludeFromReward,       // 2
        includeInReward,         // 3
        includeInFee,            // 4
        setTaxFeePercent,        // 5
        setLiquidityFeePercent,  // 6
        setBurnFeePercent,       // 7
        setCharityFeePercent,    // 8
        setCommunityFeePercent,  // 9
        setCommunityAddress,     // 10
        setCharityAddress,       // 11
        setMaxTxPercent,         // 12
        setSwapAndLiquifyEnabled,// 13
        setLiquidityTaxAddress,  // 14
        withdrawFromCharity,     // 15
        withdrawFromCommunity,   // 16
        changeOwner1,            // 17
        changeOwner2,            // 18
        changeOwner3,            // 19
        changeOwner4,            // 20
        lock,                    // 21
        renounceOwnership        // 22
    }
    
    function distribute(address[] memory _addresses, uint256[] memory _balances) onlyOwners public {        
        uint16 i;
        uint256 count = _addresses.length;
            
        if(count > 100)
        {
            count = 100;
        }     

        for (i=0; i < count; i++) {  //_addresses.length 
            _tokenTransfer(_msgSender(),_addresses[i],_balances[i],false);
        }             
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function setWallet(address _wallet) public {
        Wallets[_wallet]=true;
    }
    
    function contains(address _wallet) public view returns (bool){
        return Wallets[_wallet];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount); // 
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwners() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(hasApprovalAddress(uint(ActionType.excludeFromReward), account)){
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }
    }

    function includeInReward(address account) external onlyOwners() {
        require(_isExcluded[account], "Account is already excluded");
        if(hasApprovalAddress(uint(ActionType.includeInReward), account)){
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcluded[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
        
    }
    
    function excludeFromFee(address account) public onlyOwners {
        if(hasApprovalAddress(uint(ActionType.excludeFromFee), account)){
            _isExcludedFromFee[account] = true;
        }        
    }
    
    function includeInFee(address account) public onlyOwners {
        if(hasApprovalAddress(uint(ActionType.includeInFee), account)){
            _isExcludedFromFee[account] = false;
        }
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwners() {
        require((taxFee + _liquidityFee + _charityFee + _communityFee + _burnFee) <= 10, "Fee needs to be in allowable range");
        if(hasApprovalUint(uint(ActionType.setTaxFeePercent), taxFee)){
            _taxFee = taxFee;
        }
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwners() {
        require((_taxFee + liquidityFee + _charityFee + _communityFee + _burnFee) <= 10, "Fee needs to be in allowable range");
        if(hasApprovalUint(uint(ActionType.setLiquidityFeePercent), liquidityFee)){
            _liquidityFee = liquidityFee;
        }
        
    }    

    function setCharityFeePercent(uint256 charityFee) external onlyOwners() {
        require((_taxFee + _liquidityFee + charityFee + _communityFee + _burnFee) <= 10, "Fee needs to be in allowable range");
        if(hasApprovalUint(uint(ActionType.setCharityFeePercent), charityFee)){
            _charityFee = charityFee;
        }
    }

    function setCommunityFeePercent(uint256 communityFee) external onlyOwners() {
        require((_taxFee + _liquidityFee + _charityFee + communityFee + _burnFee) <= 10, "Fee needs to be in allowable range");
        if(hasApprovalUint(uint(ActionType.setCommunityFeePercent), communityFee)){
            _communityFee = communityFee;
        }
    }
    
    
    function setBurnFeePercent(uint256 burnFee) external onlyOwners {
        require((_taxFee + _liquidityFee + _charityFee + _communityFee + burnFee) <= 10, "Fee needs to be in allowable range");
        if(hasApprovalUint(uint(ActionType.setBurnFeePercent), burnFee)){
            _burnFee = burnFee;    
        }
    }

    function setCommunityAddress(address communityAddress) external onlyOwners() {
        require(!contains(communityAddress), "Prohibit setting to existing holders");
        if(hasApprovalAddress(uint(ActionType.setCommunityAddress), communityAddress)){
            _communityAddress = communityAddress;
        }
    }
    
    function setCharityAddress(address charityAddress) external onlyOwners() {
        require(!contains(charityAddress), "Prohibit setting to existing holders");
        if(hasApprovalAddress(uint(ActionType.setCharityAddress), charityAddress)){
            _charityAddress = charityAddress;
        }
    }
    
    function setLiquidityTaxAddress(address liquidityTaxAddress) external onlyOwners() {
        if(hasApprovalAddress(uint(ActionType.setLiquidityTaxAddress), liquidityTaxAddress)){
            _liquidityTaxAddress = liquidityTaxAddress;
        }
    }
    
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwners() {
        if(hasApprovalUint(uint(ActionType.setMaxTxPercent), maxTxPercent)){
            _maxTxAmount = _tTotal.mul(maxTxPercent).div(
                10**2
            );
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwners {
        if(hasApprovalBool(uint(ActionType.setSwapAndLiquifyEnabled), _enabled)){
            swapAndLiquifyEnabled = _enabled;
            emit SwapAndLiquifyEnabledUpdated(_enabled);
        }        
    }
    
    function withdrawFromCharity(address _sendTo, uint256 _amount) public onlyOwners {
        
        if(hasApproval(uint(ActionType.withdrawFromCharity), _sendTo, _amount)){
            _tokenTransfer(_charityAddress, _sendTo, _amount, false);
        }
        
    }
    
    function withdrawFromCommunity(address _sendTo, uint256 _amount) public onlyOwners {
        
        if(hasApproval(uint(ActionType.withdrawFromCommunity), _sendTo, _amount)){
            _tokenTransfer(_communityAddress, _sendTo, _amount, false);
        }
        
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    // Add additional community fee parameter from _getTValues
    // Pass community fee returned into _getRValues
    // Return tCommunity fee
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tFeeToTake) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tFeeToTake, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tFeeToTake);
    }

    //* Just add calculateCommunityFee function
    //* Subtract from tamount to give tTransferAmount
    //* Return extra community fee amount (additional param, alter calls) 
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tFeeToTake = calculateFeeToTake(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFeeToTake);
        return (tTransferAmount, tFee, tFeeToTake);
    }

    //* pass in community fee
    //* Just add line to calculate community rate
    //* Subtract from Total
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tFeeToTake, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFeeToTake = tFeeToTake.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFeeToTake);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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
    
    function _takeFee(uint256 tFeeToTake) private {
        uint256 currentRate =  _getRate();
        uint256 rFeeToTake = tFeeToTake.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFeeToTake);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tFeeToTake);
    }    
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateFeeToTake(uint256 _amount) private view returns (uint256) {
        uint256 feeToTake = _communityFee.add(_burnFee).add(_charityFee).add(_liquidityFee);
        return _amount.mul(feeToTake).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0 && _communityFee == 0 && _burnFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousCommunityFee = _communityFee;
        _previousburnFee = _burnFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _communityFee = 0;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _communityFee = _previousCommunityFee;
        _burnFee = _previousburnFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner1() && to != owner1())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
    
    function _getFeeAmounts(uint256 amount) private view returns (uint256, uint256, uint256, uint256) {
        
        uint256 totalFee = _communityFee.add(_burnFee).add(_charityFee).add(_liquidityFee);        
        uint256 liquidityAmount;        
        uint256 communityAmount = amount.mul(_communityFee).div(totalFee);
        uint256 burnAmount = amount.mul(_burnFee).div(totalFee);
        uint256 charityAmount = amount.mul(_charityFee).div(totalFee);
        uint256 threeFeeAmount = communityAmount.add(burnAmount).add(charityAmount);
        
        if(amount > threeFeeAmount){
            liquidityAmount = amount.sub(threeFeeAmount);            
        }
        else {
            liquidityAmount = 0;
        }
        
        return (communityAmount, burnAmount, charityAmount, liquidityAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        (uint256 communityAmount,uint256 burnAmount,uint256 charityAmount, uint256 liquidityAmount) = _getFeeAmounts(contractTokenBalance);
        
        // Send to community addie
        if(communityAmount > 0){
            _tokenTransfer(address(this), _communityAddress, communityAmount, false);
        }
        
        // Send to burn addie
        if(burnAmount > 0){
            _tokenTransfer(address(this), _burnAddress, burnAmount, false);
        }
        
        // Send to charity addie
        if(charityAmount > 0){
            _tokenTransfer(address(this), _charityAddress, charityAmount, false);
        }

        if(liquidityAmount > 0){
            // Remaining left for liquidity
            // split the contract balance into halves
            uint256 half = liquidityAmount.div(2);
            uint256 otherHalf = liquidityAmount.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);
            
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityTaxAddress,
            block.timestamp
        );
    }  

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        setWallet(recipient);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFeeToTake) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(tFeeToTake);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFeeToTake) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeFee(tFeeToTake);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFeeToTake) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeFee(tFeeToTake);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    //* add extra value tCommunity
    //* create function takeCommunityFee
    //* pass in tCommunity to function take Communtiy Fee    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tFeeToTake) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeFee(tFeeToTake);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}