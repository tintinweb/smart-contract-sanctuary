/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/binance/solidity/issues/2691
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
     address private _owner;

     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     /**
      * @dev Initializes the contract setting the deployer as the initial owner.
      */
     constructor ()  {
         address msgSender = _msgSender();
         _owner = msgSender;
         emit OwnershipTransferred(address(0), msgSender);
     }
     /**
      * @dev Returns the address of the current owner.
      */
     function owner() public view returns (address) {
         return _owner;
     }
     /**
      * @dev Throws if called by any account other than the owner.
      */
     modifier onlyOwner() {
         require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
interface iToken
{
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
}
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}
 contract SUPERHIVEZ_CLAIM is Context, Ownable {
     using SafeMath for uint256;
     using Address for address;
     address public bhfst;
     address public superhivezToken;
     uint256 public totalShv ;
     struct userInfo
     {
      uint256 lastclaimed ;
      uint256 userClaimed;
     }
     mapping(address => mapping(uint256 => bool)) public completedTask;
     mapping(address => userInfo) public users;
     mapping(uint256 => uint256) public CommunityAllocation;
     uint256 public lastWeekId;
     address public EACAggregatorProxyAddress;
     uint256 public totalClaimed;
     IUniswapV2Router02 public immutable uniswapV2Router;
     bool public safeguard;  //putting safeguard on will halt all non-owner functions
     mapping (address => bool) public frozenAccount;
     event FrozenAccounts(address target, bool frozen);
     event Claim(address indexed _user, uint256 weekid, uint256 amount);
     event Withdraw(address indexed _user, uint256 amount);
     constructor(address _superhivezToken, address _bhfst, address _EACAggregatorProxyAddress)  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //testnet
     // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);    // main net
        uniswapV2Router = _uniswapV2Router;
        bhfst = _bhfst;
        superhivezToken = _superhivezToken;
        //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
        totalShv =  iToken(superhivezToken).totalSupply();
     }

     function claimable(address _user) public view returns(uint256)
     {
       uint256 amount;
       uint256 shvbal = CommunityAllocation[lastWeekId]; // iToken(superhivezToken).balanceOf(address(this));

       if(shvbal > 0 && users[_user].lastclaimed  < lastWeekId)
       {
         uint256 bhfsttoshv = USDToToken(iToken(bhfst).balanceOf(_user));
         uint256 holderperc = ((bhfsttoshv * 1e6) / totalShv) * 100 ;
         uint startindex= users[_user].lastclaimed + 1;
         for(uint i=startindex;i <= lastWeekId ; i++)
         {
            if(completedTask[_user][i]){
              amount += (CommunityAllocation[i] * holderperc / 1e8) ;
            }
         }

       }
       return amount;
     }

     function claim() external returns(uint256)
     {
       require(!safeguard,"Safeguard is on");
       require(!frozenAccount[msg.sender], "caller has been frozen");
       require(!isContract(msg.sender),  "No contract address allowed");
       uint256 amount = claimable(msg.sender);
       require(amount > 0,"No claimable token");
        users[msg.sender].lastclaimed = lastWeekId;
        users[msg.sender].userClaimed += amount;
        emit Claim(msg.sender, lastWeekId, amount);
       return amount;
     }
     function withdraw() external returns(uint256)
     {
        require(!safeguard,"Safeguard is on");
        require(!frozenAccount[msg.sender], "caller has been frozen");
        require(!isContract(msg.sender),  "No contract address allowed");
        require(users[msg.sender].userClaimed > 0,"No token to withdraw");
        uint256 amount =users[msg.sender].userClaimed;
        users[msg.sender].userClaimed =0;
        iToken(superhivezToken).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
        return amount;
     }
     function BUSDToBNB(uint busdAmount) public view returns(uint256)
     {
         //result is in 9 decimals
         uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
         return (busdAmount  / bnbpreice) * (10 ** 8);
     }
     function USDToToken(uint256 usdamt) public view returns(uint256){
       uint256 tokenAmt = BUSDToBNB(usdamt);
       address BNBTokenAddress = uniswapV2Router.WETH(); //BNB
       address[] memory path = new address[](2);
       path[0]=BNBTokenAddress ;
       path[1]=superhivezToken ;
       uint amountOut = uniswapV2Router.getAmountsOut(tokenAmt, path)[1];
       return amountOut;
     }
     function setWeeklyPayment(uint256 transferAmount) external returns(bool)
     {
        require(msg.sender == superhivezToken, "Invalid caller");
        lastWeekId += 1;
        CommunityAllocation[lastWeekId] = transferAmount;
        return true;
     }
     function freezeAccount(address target, bool freeze) onlyOwner public {
         frozenAccount[target] = freeze;
         emit  FrozenAccounts(target, freeze);
     }
      //to receive BNB
     receive() external payable {}
    function setCompleted(address[] memory _users, uint256[] memory weekid) public onlyOwner{
        require(!safeguard,"Safeguard is on");
        require(!isContract(msg.sender),  "No contract address allowed");
        uint256 totalAddresses = _users.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
            completedTask[_users[i]][weekid[i]]= true;
        }
    }
   	function manualWithdrawOtherTokens(address _tokenaddress, uint256 tokenAmount) public onlyOwner{
           // no need for overflow checking as that will be done in transfer function
           iToken(_tokenaddress).transfer(owner(), tokenAmount);
       }

       //Just in rare case, owner wants to transfer Ether from contract to owner address
       function manualWithdrawBNB()onlyOwner public{
           payable(address(owner())).transfer(address(this).balance);
       }
       function changeSafeguardStatus() onlyOwner public{
           if (safeguard == false){
               safeguard = true;
           }
           else{
               safeguard = false;
           }
       }
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
  }