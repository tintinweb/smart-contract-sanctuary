/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

interface IUniswapV2Router02 {
  function addLiquidityETH(
  address token,
  uint amountTokenDesired,
  uint amountTokenMin,
  uint amountETHMin,
  address to,
  uint deadline
) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IUniswapV2Factory {
 function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniLockFactory {
    function fee() external view returns(uint);
    function uni_router() external view returns(address);
    function toFee() external view returns(uint);

    

    
}




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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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



 contract uniLock  {
    using Address for address;
    using SafeMath for uint;
    address factory;
    uint public locked = 0;
    uint public unlock_date = 0;
    address public owner;
    address public token;
    uint public softCap;
    uint public hardCap;
    uint public start_date;
    uint public end_date;
    uint public rate; // coin sale rate 1 ETH = 1 XYZ (rate = 1e18) <=> 1 ETH = 10 XYZ (rate = 1e19) 
    uint public min_allowed;
    uint public max_allowed; // Max ETH 
    uint public collected; // collected ETH
    uint public pool_rate; // uniswap liquidity pool rate  1 ETH = 1 XYZ (rate = 1e18) <=> 1 ETH = 10 XYZ (rate = 1e19)
    uint public lock_duration; // duration wished to keep the LP tokens locked
    uint public uniswap_rate;
    bool public doRefund = false;
    constructor() public{
        factory = msg.sender;
        
    }
   

    
    
    
    mapping(address => uint) participant;
    
    // Initilaize  a new campaign (can only be triggered by the factory contract)
    function initilaize(uint[] calldata _data,address _token,address _owner_Address,uint _pool_rate,uint _lock_duration,uint _uniswap_rate) external returns (uint){
      require(msg.sender == factory,'You are not allowed to initialize a new Campaign');
      owner = _owner_Address; 
      softCap = _data[0];
      hardCap = _data[1];
      start_date = _data[2];
      end_date = _data[3];
      rate = _data[4]; 
      min_allowed = _data[5];
      max_allowed = _data[6];
      token = _token;
      pool_rate = _pool_rate;
      lock_duration = _lock_duration;
      uniswap_rate = _uniswap_rate;
    }
    
    function buyTokens() public payable returns (uint){
        require(isLive(),'campaign is not live');
        require((msg.value>= min_allowed)&& (getGivenAmount(msg.sender).add(msg.value) <= max_allowed) && (msg.value <= getRemaining()),'The contract has insufficent funds or you are not allowed');
        participant[msg.sender] = participant[msg.sender].add(msg.value);
        collected = (collected).add(msg.value);
        return 1;
    }
    function withdrawTokens() public returns (uint){
        require(locked == 1,'liquidity is not yet added');
        require(IERC20(address(token)).transfer(msg.sender,calculateAmount(participant[msg.sender])),"can't transfer");
        participant[msg.sender] = 0;

    }
    function unlock(address _LPT,uint _amount) public returns (bool){
        require(locked == 1 || failed(),'liquidity is not yet locked');
        require(address(_LPT) != address(token),'You are not allowed to withdraw tokens');
        require(block.timestamp >= unlock_date ,"can't receive LP tokens");
        require(msg.sender == owner,'You are not the owner');
        IERC20(address(_LPT)).transfer(msg.sender,_amount);
    }
    
    // Add liquidity to uniswap and burn the remaining tokens, can be only executed when the campaign completes
    
    function uniLOCK() public returns(uint){
        require(locked ==0,'Liquidity is already locked');
        require(!isLive(),'Presale is still live');
        require(!failed(),"Presale failed , can't lock liquidity");
        require(softCap <= collected,"didn't reach soft cap");
        require(addLiquidity(),'error adding liquidity to uniswap');
        locked = 1;
        unlock_date = (block.timestamp).add(lock_duration);
        return 1;
    }
    
    function addLiquidity() internal returns(bool){
        if(IUniswapV2Factory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)).getPair(token,address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)) == address(0)){
        uint campaign_amount = collected.mul(uint(IUniLockFactory(factory).fee())).div(1000);
        IERC20(address(token)).approve(address(IUniLockFactory(factory).uni_router()),(hardCap.mul(rate)).div(1e18));
        if(uniswap_rate > 0){
                IUniswapV2Router02(address(IUniLockFactory(factory).uni_router())).addLiquidityETH{value : campaign_amount.mul(uniswap_rate).div(1000)}(address(token),((campaign_amount.mul(uniswap_rate).div(1000)).mul(pool_rate)).div(1e18),0,0,address(this),block.timestamp + 100000000);
        }
        payable(IUniLockFactory(factory).toFee()).transfer(collected.sub(campaign_amount));
        payable(owner).transfer(campaign_amount.sub(campaign_amount.mul(uniswap_rate).div(1000)));
        }else{
            doRefund = true;
        }
        return true;
    }
    
    // Check whether the campaign failed
    
    function failed() public view returns(bool){
        if((block.timestamp >= end_date) && (softCap > collected)){
            return true;
            
        }
        return false;
    }
    
    // Allows Participants to withdraw funds when campaign fails
    function withdrawFunds() public returns(uint){
        require(failed() || doRefund,"campaign didn't fail");
        require(participant[msg.sender] >0 ,"You didn't participate in the campaign");
        uint withdrawAmount = participant[msg.sender].mul(uint(IUniLockFactory(factory).fee())).div(1000);
        (msg.sender).transfer(withdrawAmount);
        payable(IUniLockFactory(factory).toFee()).transfer(participant[msg.sender].sub(withdrawAmount));
        participant[msg.sender] = 0;

    }
    // Checks whether the campaign is still Live
    
    function isLive() public view returns(bool){
       if((block.timestamp < start_date)) return false;
       if((block.timestamp >= end_date)) return false;
       if((collected >= hardCap)) return false;
       return true;
    }
    // Returns amount in XYZ.
    function calculateAmount(uint _amount) public view returns(uint){
        return (_amount.mul(rate)).div(1e18);
        
    }
    
    // Gets remaining ETH to reach hardCap
    function getRemaining() public view returns (uint){
        return (hardCap).sub(collected);
    }
    function getGivenAmount(address _address) public view returns (uint){
        return participant[_address];
    }
    
  
    


    
}