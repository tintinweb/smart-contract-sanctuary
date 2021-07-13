/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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
     * - the calling contract must have an BNB balance of at least `value`.
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

//import './interfaces/IPancakePair.sol';
pragma solidity >=0.5.0;

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

pragma solidity >=0.4.18;

contract WBNB {
    string public name     = "Wrapped BNB";
    string public symbol   = "WBNB";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    // function() public payable {
    //     deposit();
    // }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

interface IPancakeRouter02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPool {
    function notifyReward() external payable ;
}

interface ICakeVaultFactory {
    function fee() external view returns(uint);
    function pancake_router() external view returns(address);
    function toFee() external view returns(uint);    
}

/**
 * @dev Implementation of the {IBEP20} interface.
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
 * allowances. See {IBEP20-approve}.
 */

 
 contract SiliconVault  {
    using Address for address;
    using SafeMath for uint;
    address public factory;
    address public factory_owner;
    uint public locked = 0;
    uint public unlock_date = 0;
    address public owner;
    address public token;
    address public slk_address; // SLK token
    address public platformFeesCollector;
    address public slk_bnb_lp_address;
    uint public softCap;
    uint public hardCap;
    uint public start_date;
    uint public end_date;
    uint public rate;               // presale rate 1 BNB = 1 SLK (rate = 1e18) <=> 1 BNB = 10 SLK (rate = 1e19) 
    uint public min_allowed;
    uint public max_allowed;        // Max BNB 
    uint public collected;          // collected BNB
    uint public pool_rate;          // Pancakeswap liquidity pool rate  1 BNB = 1 SLK (rate = 1e18) <=> 1 BNB = 10 SLK (rate = 1e19)
    uint public lock_duration;      // duration wished to keep the LP tokens locked
    uint public withdrewToken;
    uint public pancake_rate;
    uint public prime_member_balance = 10000 * 1e18;
    bool public doRefund = false;
    
    constructor() public{
        factory = msg.sender;
    }
    
    mapping(address => uint) participant;
    
    modifier only_factory_authorised(){
        require(owner == msg.sender || factory_owner == msg.sender,'Error:Unauthorised');
        _;
    }
    
    // Initilaize  a new campaign (can only be triggered by the factory contract)
    function initilaize(uint[] calldata _data,address _token,address _owner_Address,uint _pool_rate,uint _lock_duration,uint _pancake_rate, address slk_address_, address platformFeesCollector_, address slk_bnb_lp_address_, address factory_owner_) external returns (uint){
      require(msg.sender == factory,'You are not allowed to initialize a new Campaign');
      owner = _owner_Address; 
      softCap = _data[0];
      hardCap = _data[1];
      start_date = _data[2];
      end_date = _data[3];
      rate = _data[4];                                  
      min_allowed = _data[5];
      max_allowed = _data[6];
      token = _token;                                   // Presale token
      lock_duration = _lock_duration;                   // Liquidity Lock
      pool_rate = _pool_rate;                           // In Percentage
      pancake_rate = _pancake_rate;                     // 1 BNB = ?
      slk_address = slk_address_;
      platformFeesCollector = platformFeesCollector_;
      slk_bnb_lp_address = slk_bnb_lp_address_;
      factory_owner = factory_owner_;
    }
    
    function buyTokens() public payable returns (uint){
        require(isLive(),'campaign is not live');
        require((msg.value>= min_allowed)&& (getGivenAmount(msg.sender).add(msg.value) <= max_allowed),'The contract has insufficent funds or you are not allowed');
        participant[msg.sender] = participant[msg.sender].add(msg.value);
        collected = (collected).add(msg.value);
        return 1;
    }

    function withdrawTokens() public returns (uint){
        require(locked == 1,'liquidity is not yet added');
        withdrewToken = withdrewToken.add(calculateAmount(participant[msg.sender]));
        require(IBEP20(address(token)).transfer(msg.sender,calculateAmount(participant[msg.sender])),"can't transfer");
        participant[msg.sender] = 0;
    }

    // unlock liquidity provider (lp) tokens
    function unlock(address _LPT,uint _amount) public returns (bool){
        require(locked == 1 || failed(),'liquidity is not yet locked');
        require(address(_LPT) != address(token),'You are not allowed to withdraw tokens');
        require(block.timestamp >= unlock_date ,"can't receive LP tokens");
        require(msg.sender == owner,'You are not the owner');
        IBEP20(address(_LPT)).transfer(msg.sender,_amount);
    }
       
    // Add liquidity to pancake can be only executed by authorised when the campaign completes
    function siliconVAULT() public only_factory_authorised returns(uint){
        require(locked == 0,'Liquidity is already locked');
        require(!isLive(),'Presale is still live');
        require(!failed(),"Presale failed , can't lock liquidity");
        require(softCap <= collected,"didn't reach soft cap");
        require(addLiquidity(),'error adding liquidity to uniswap');
        locked = 1;
        unlock_date = (block.timestamp).add(lock_duration);
        return 1;
    }

    function addLiquidity() internal returns(bool){
        
        uint platform_fees = collected.mul(uint(ICakeVaultFactory(factory).fee())).div(1000);
        
        payable(platformFeesCollector).transfer(platform_fees.mul(500).div(1000));              // pool fees 50% of (3)% raised BNB 
            
        IPool(slk_bnb_lp_address).notifyReward{value: platform_fees.mul(500).div(1000)}();    // pool fees 50% of (3)% raised BNB
        IBEP20(address(token)).transfer(platformFeesCollector, collected.mul(rate).div(1e20));  // 1% TOKEN
        
        if(pancake_rate > 0){

                IBEP20(address(token)).approve(address(ICakeVaultFactory(factory).pancake_router()),0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

                // lock liquidity
                if(IPancakeFactory(address(0xBCfCcbde45cE874adCB698cC183deBcF17952812)).getPair(token,address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)) == address(0)){
                    //
                    IPancakeRouter02(address(ICakeVaultFactory(factory).pancake_router())).addLiquidityETH{value : collected.mul(pancake_rate).div(1000)}(address(token), ((collected.mul(pancake_rate).div(1000)).mul(pool_rate)).div(1e18), 0, 0, address(this), block.timestamp + 100000000);
                    
                } else if(IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812).getPair(token,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)  != address(0) ) {
                    
                    uint _totalSupply = IPancakePair(IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812).getPair(token,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)).totalSupply();
                    
                    if(_totalSupply > 0) {
                        //
                        WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).deposit{value: collected.mul(pancake_rate).div(1000)}();
                        WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).transfer(IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812).getPair(token,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balanceOf(address(this)));
                        
                        IBEP20(address(token)).transfer(IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812).getPair(token,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), ((collected.mul(pancake_rate).div(1000)).mul(pool_rate)).div(1e18));  // Transfer Token
                        
                        // Sync
                        IPancakePair(IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812).getPair(token,0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)).sync();
                    } else {
                        IPancakeRouter02(address(ICakeVaultFactory(factory).pancake_router())).addLiquidityETH{value : collected.mul(pancake_rate).div(1000)}(address(token), ((collected.mul(pancake_rate).div(1000)).mul(pool_rate)).div(1e18), 0, 0, address(this), block.timestamp + 100000000);    
                    }
                }
            } else {
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
    
    // Allows Participants to withdraw funds in case of campaign fails
    function withdrawFunds() public returns(uint){
        require(failed() || doRefund || ( locked == 0 && block.timestamp >= end_date.add(24 hours)), "error : allowed re-fund in case of campaign failed or liquidity couldn't locked within 24 hours from end date.");
        require(participant[msg.sender] > 0 ,"error : you didn't participate in the campaign");
        uint withdrawAmount = participant[msg.sender];
        participant[msg.sender] = 0;
        (msg.sender).transfer(withdrawAmount);
    }

    // Checks whether the campaign is still Live
    // SLK Holder ( > 10000) can participate 2 hour earlier in pre-sale
    function isLive() public view returns(bool){
        if((collected >= hardCap)) return false;
        if(collected >= softCap && block.timestamp >= end_date) return false;
        if(IBEP20(address(slk_address)).balanceOf(msg.sender) >= uint(prime_member_balance)) {    // add condition if user may have 100000 SLK   
            if(block.timestamp >= start_date.sub(2 hours)) return true;
        }
        if((block.timestamp < start_date )) return false; 
        if((block.timestamp >= end_date)) return false;
       
        return true;
    }

    modifier campaignConclude() {
        require((failed() || doRefund || locked == 1), "error : allowed withdraw in case of campaign failed or liquidity couldn't locked within 24 hours from end date.");
        require(msg.sender == owner,'error : you are not the owner');
        _;
    }    

    // Owner withdraw remaining assets only when
    // if campaign success && locked liqudity pancake successfully, asset remained.
    // if campaign success && liquidity couldn't locked within 24 hours of enddate
    // Campaign owner unable to withdraw all the assets
    function withDrawRemainingAssets() public campaignConclude {
        
        uint256 totalToken = 0;
        
        if(locked == 1) {
            
            uint256 _data1 = hardCap.add(max_allowed);
         
            totalToken  =   _data1.mul(rate).div(1e18).add(_data1.mul(pancake_rate.mul(pool_rate)).div(1e21).add(_data1.mul(rate).div(1e20)));
         
            totalToken  =    totalToken
                            .sub(collected.mul(rate).div(1e18))                                         // Total token withdraw by staker
                            .sub(((collected.mul(pancake_rate).div(1000)).mul(pool_rate)).div(1e18))    // Locked token to pancake
                            .sub(collected.mul(rate).div(1e20))                                         // 1% Platform fees
                            .sub(withdrewToken);
            
            // Able to withdraw in case of locked liquidity
            (msg.sender).transfer(collected.sub((collected.mul(uint(ICakeVaultFactory(factory).fee())).div(1000)).add(collected.mul(pancake_rate).div(1000))));
            
        } else {
            totalToken = IBEP20(address(token)).balanceOf(address(this));
        }
                
        if(totalToken > 0)
            IBEP20(address(token)).transfer(msg.sender, totalToken);
           
    }
    
    // emergency withdraw
    function exit() public {
        require(factory_owner == msg.sender, "error: unauthorised wallet");
        require((block.timestamp >= end_date.add(72 hours)), "error : emergency exit accessible after 72 hours from campaign end");

        // withdraw all the remaining token
        if(IBEP20(address(token)).balanceOf(address(this)) > 0)
            IBEP20(address(token)).transfer(msg.sender, IBEP20(address(token)).balanceOf(address(this)));

        // withdraw all the remaining BNB
        (bool success,) = msg.sender.call{ value: address(this).balance}("");
        require(success, "error : withdrawl failed");
    }

    // Calculate tokens based on _bnb amount
    function calculateAmount(uint _amount) public view returns(uint){
        return (_amount.mul(rate)).div(1e18);
    }
    
    // Gets remaining BNB to reach hardCap
    function getRemaining() public view returns (uint){
        return (hardCap).sub(collected);
    }

    // Check invested BNB in pre-sale
    function getGivenAmount(address _address) public view returns (uint){
        return participant[_address];
    }
  
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

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

/**
 * @dev Collection of functions related to the address type
 */

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


/**
 * @dev Implementation of the {IBEP20} interface.
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
 * allowances. See {IBEP20-approve}.
 */

// Name : SiliconPresaleFactory
contract SiliconPresaleFactory  {
    using Address for address;
    using SafeMath for uint;
    address[] public campaigns;
    address public toFee;
    uint public fee;
    address factory_owner;
    address public slk_address;
    address public pancake_router;
    address public platformFeesCollector;
    address public slk_bnb_lp_address;
    mapping(address=>address) public tokenCampaign;
    uint balance_required;              // In percentage 5  10000
    
    event CreateCampaign(address indexed _campaign_address, uint _index);
    
    constructor(address _slk_address,uint min_balance,uint _fee,address _pancakeRouter, address _platformFeesCollector, address _slk_bnb_lp_address) public {
        factory_owner = msg.sender;
        toFee = msg.sender;
        slk_address = _slk_address;                         // SLK Token Contract Address       
        balance_required = min_balance;                    // In percentage 50 / 10000
        fee = _fee;
        pancake_router = _pancakeRouter;                   // Pancake Router
        slk_bnb_lp_address = _slk_bnb_lp_address;
        platformFeesCollector = _platformFeesCollector;    
    }
    
    modifier only_factory_Owner(){
        require(factory_owner == msg.sender,'You are not the owner');
        _;
    }
    
    //  1 BNB = 1 SLK (_pool_rate = 1e18) <=> 1 BNB = 10 SLK (_pool_rate = 1e19) <=> SLK (decimals = 18)
    //  _data = _softCap,_hardCap,_start_date, _end_date,_rate,_min_allowed,_max_allowed
    function createCampaign(uint[] memory _data,address _token,uint _pool_rate,uint _lock_duration,uint _pancake_ratio) external returns (address campaign_address){
        
        require(IBEP20(address(slk_address)).balanceOf(msg.sender) >= _data[1].mul(_data[4]).mul(balance_required).div(1e23), "You don't have the minimum SLK tokens required to launch a campaign");
        
        // startdate must be greater than current time
        require(_data[0] < _data[1],"Error :  soft cap can't be higher than hard cap" );
        require(_data[2] >= block.timestamp, "Error : start date must be higher than current date");
        require(_data[2] < _data[3] ,"Error :  start date can't be higher than end date");
        require(block.timestamp < _data[3] ,"Error : end date can't be higher than current date");
        require(_data[5] < _data[1],"Error : minimum allowed can't be higher than hard cap");
        require(_data[4] != 0,"Error : rate can't be null");
        require(_pancake_ratio >= 0 && _pancake_ratio <= 980, "Error : pancake liquidity ratio required between 1 to 98%");           
        
        bytes memory bytecode = type(SiliconVault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender));
        assembly {
            campaign_address := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        SiliconVault(campaign_address).initilaize(_data,_token,msg.sender,_pool_rate,_lock_duration,_pancake_ratio, slk_address, platformFeesCollector, slk_bnb_lp_address, factory_owner);
        campaigns.push(campaign_address);
        tokenCampaign[_token] = campaign_address;
        require(transferToCampaign(_data[1].add(_data[6]), _data[4], _pool_rate, _pancake_ratio, _token,campaign_address),"unable to transfer funds");
        
        emit CreateCampaign(campaign_address, campaigns.length);
        
        return campaign_address;
    }
    
    function transferToCampaign(uint _data1,uint _data4,uint _pool_rate, uint _pancake_ratio,address _token,address _campaign_address) internal returns(bool){
        require(ApproveTransferTo(_data1.mul(_data4).div(1e18), _data1.mul(_pancake_ratio.mul(_pool_rate)).div(1e21), _data1.mul(_data4).div(1e20), _token, _campaign_address), "unable to transfer token amount to the campaign"); 
        return true;
    }
    
    function ApproveTransferTo(uint _presaleToken, uint _pancakeLockingToken, uint _onePercTokenInPresale, address _token, address _campaign_address) internal returns(bool){
        require(IBEP20(address(_token)).transferFrom(msg.sender, address(_campaign_address), _presaleToken.add(_pancakeLockingToken.add(_onePercTokenInPresale))),"unable to transfer token amount to the campaign");
        return true;
    }
    
    function changeConfig(uint _fee,address _to,uint _balance_required) external only_factory_Owner returns(uint){
        fee = _fee;
        toFee = _to;
        balance_required = _balance_required;
    }
    
}