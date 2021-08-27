// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface CurvePool {

    function get_virtual_price() external view returns(uint256);

    function calc_token_amount(
        uint256[3] memory, 
        bool
    )  external view returns(uint256);

    function add_liquidity(
        uint256[3] memory,
        uint256
    )  external;

    function remove_liquidity(
        uint256,
        uint256[3] memory
    )  external;

    function remove_liquidity_imbalance(
        uint256[3] memory,
        uint256
    )  external;


    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    )  external;
}

interface PoolGauge {
    function deposit(uint256)  external;
    function withdraw(uint256)  external;
    function balanceOf(address)  external view returns (uint256);
    function claimable_tokens(address) external view returns(uint256);
    function totalSupply()  external view returns(uint256);
}

interface Minter {
    function mint(address)  external;
}


interface DepositY{
    function add_liquidity(
        uint256[3] memory,
        uint256
    )  external;


    function remove_liquidity(uint256,uint256[3] memory)  external ;

      function remove_liquidity_imbalance(
        uint256[3] memory,
        uint256
    )  external;

    function calc_withdraw_one_coin(uint256, int128)  external returns(uint256);

    function remove_liquidity_one_coin(uint256, int128,uint256,bool) external ;

}

interface VoteEscrow{
    function create_lock(uint256,uint256) external ;
    function increase_amount(uint256)  external;
    function increase_unlock_time(uint256)  external;
    function withdraw()  external;
    function totalSupply()  external view returns(uint256);
}


interface FeeDistributor{
    function claim()  external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function approve( address, uint256)  external returns(bool);

    function allowance(address, address) external view returns (uint256);
    
    function balanceOf(address)  external view returns(uint256);

    function decimals()  external view returns(uint8);

    function totalSupply() external  view returns(uint256);

    function transferFrom(address,address,uint256) external  returns(bool);

    function transfer(address,uint256) external  returns(bool);
    
    function mint(address , uint256 ) external ;
    function burn(address , uint256 ) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Interface.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface UniswapI {
    
    function swapExactTokensForTokens(uint256,uint256,address[] calldata,address,uint256) external;

    function getAmountsOut(uint amountIn, address[] memory path) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './CurveInterface.sol';
import './UniswapInterface.sol';
import "./SafeERC20.sol";

contract CurveStrategy {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public X22Address;
    address public yieldDistributor;
    IERC20 public poolToken;
    IERC20[3] public tokens;  // DAI / USDC / USDT
    CurvePool public pool;
    PoolGauge public gauge;
    Minter public minter;
    VoteEscrow public voteEscrow;
    FeeDistributor public feeDistributor;
    UniswapI  public uniAddr;
    IERC20 public crvAddr;
    address public wethAddr;
     
    uint256 public constant DENOMINATOR = 10000;

    uint256 public depositSlip = 100;

    uint256 public withdrawSlip = 200;
    
    uint256 public uniswapSlippage=50;

    address public wallet;
    address public nominatedWallet;
    
   // uint256 public totalProfit;
    
    uint256 public crvBreak=10000;

   // uint256 public virtualPrice;
 
    bool public TEST = true; // For testing uniswap , should be removed on deployment to the mainnet

    modifier onlyAuthorized(){
      require(wallet == msg.sender|| msg.sender==X22Address, "Not authorized");
      _;
    }

    modifier onlyWallet(){
        require((wallet==msg.sender),"Not Authorized");
        _;
    }

    modifier onlyX22LP() {
        require(msg.sender == X22Address, "Not authorized");
        _;
    }

    constructor(
         IERC20[3] memory _tokens, 
         address _crvpool,  // #pool
         address _poolToken, //3crv
         address _gauge, //
         address _minter,
         address _uniAddress,// uniswap address
         address _crvAddress, // crv token
         address _wethAddress, // weth address
         address _voteEscrow, // vecrv token address
         address _feeDistributor
         ) {

        tokens = _tokens;
        pool = CurvePool(_crvpool);
        poolToken = IERC20(_poolToken);
        gauge = PoolGauge(_gauge);
        minter=Minter(_minter);
        uniAddr=UniswapI(_uniAddress);
        crvAddr=IERC20(_crvAddress);
        wethAddr=_wethAddress;  
        feeDistributor = FeeDistributor(_feeDistributor);
        voteEscrow = VoteEscrow(_voteEscrow);
    }

    function setCRVBreak(uint256 _percentage)external onlyWallet(){
        crvBreak=_percentage;
    }

    function nominateNewOwner(address _wallet) external onlyWallet {
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(wallet, nominatedWallet);
        wallet = nominatedWallet;
        nominatedWallet = address(0);
    }

    function changeX22LP(address _address)external onlyWallet(){
        X22Address=_address;
    }

    function changeYieldDistributor(address _address)external onlyWallet(){
        yieldDistributor=_address;
    }
    
    function changeDepositSlip(uint _value)external onlyWallet(){
        depositSlip=_value;
    }
    
    function changeWithdrawSlip(uint _value)external onlyWallet(){
        withdrawSlip=_value;
    }
    
    function changeUniswapSlippage(uint _value) external onlyWallet(){
        uniswapSlippage=_value;
    }

// deposits stable tokens into the 3pool and stake recived LPtoken(3CRV) in the curve 3pool gauge
    function deposit(uint[3] memory amounts) external onlyX22LP(){
        uint currentTotal;
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
               uint decimal;
               decimal=tokens[i].decimals();
               tokens[i].safeApprove(address(pool),0);
               tokens[i].safeApprove(address(pool), amounts[i]); 
               currentTotal =currentTotal.add(amounts[i].mul(1e18).div(10**decimal));
            }
        }
        uint256 mintAmount = currentTotal.mul(1e18).div(pool.get_virtual_price());
        pool.add_liquidity(amounts,  mintAmount.mul(DENOMINATOR.sub(depositSlip)).div(DENOMINATOR));
        stakeLP();   
    }

    //withdraws stable tokens from the 3pool.Unstake required LPtokens and stake LP tokens if not used.
    function withdraw(uint[3] memory amounts,uint[3] memory max_burn) external onlyX22LP() {
        //uint256 max_burn = pool.calc_token_amount(amounts,false);
        uint burnAmount;
        for(uint i=0;i<3;i++){
             burnAmount = burnAmount.add(max_burn[i]);
        }
        burnAmount=burnAmount.mul(DENOMINATOR.add(withdrawSlip)).div(DENOMINATOR);
        unstakeLP(burnAmount);
        pool.remove_liquidity_imbalance(amounts, burnAmount);
        for(uint8 i=0;i<3;i++){
            if(amounts[i]!=0){
               tokens[i].safeTransfer(X22Address, tokens[i].balanceOf(address(this)));
            }
        }
        if(poolToken.balanceOf(address(this))>0){
            stakeLP();
        } 
    }

   //unstake all the LPtokens and withdraw all the Stable tokens from 3pool 
    function withdrawAll() external onlyX22LP() returns(uint256[3] memory){
        unstakeLP(gauge.balanceOf(address(this)));
        uint256[3] memory withdrawAmt;
        pool.remove_liquidity(poolToken.balanceOf(address(this)),withdrawAmt);
        for(uint8 i=0;i<3;i++){
            if(tokens[i].balanceOf(address(this))!=0){
                withdrawAmt[i]=tokens[i].balanceOf(address(this));
                tokens[i].safeTransfer(X22Address,withdrawAmt[i]); 
            }
        }
        return withdrawAmt; 
    } 
    
    // Functions to stake and unstake LPTokens(Ycrv) and claim CRV


    //Stakes LP token(3CRV) into the curve 3pool gauage
    function stakeLP() public onlyAuthorized() {
        uint depositAmt = poolToken.balanceOf(address(this)) ;
        poolToken.safeApprove(address(gauge),0);
        poolToken.safeApprove(address(gauge), depositAmt);
        gauge.deposit(depositAmt);  
        emit staked(depositAmt);
    }

    //For unstaking LP tokens(3CRV)
    function unstakeLP(uint _amount) public  onlyAuthorized(){
        require(gauge.balanceOf(address(this)) >= _amount,"You have not staked that much amount");
        gauge.withdraw(_amount);
        emit unstaked(_amount);
    }
    
    //Checking claimable CRV tokens.
    function checkClaimableToken()public view  returns(uint256){
        return gauge.claimable_tokens(address(this));
    }

    //for claiming CRV tokens which accumalates on staking 3CRV.
    function claimCRV() public onlyAuthorized(){
        minter.mint(address(gauge));
        emit crvClaimed();
    }

    // Functions to lock and unlock CRV and recieve VeCRV


   //For locking CRV tokens in the curve lock
    function createLock(uint256 _value,uint256 _unlockTime) external onlyWallet(){
        crvAddr.safeApprove(address(voteEscrow), 0);
        crvAddr.safeApprove(address(voteEscrow), _value);
        voteEscrow.create_lock(_value, _unlockTime);
        emit locked(_value);
    }


    //Increasing lock CRV amount
    function increaseLockAmount(uint256 _value) external onlyWallet(){
        crvAddr.safeApprove(address(voteEscrow), 0);
        crvAddr.safeApprove(address(voteEscrow), _value);
        voteEscrow.increase_amount(_value);
        emit locked(_value);
    }

    //For unlocking CRV tokens
    function releaseLock() external onlyWallet(){
        voteEscrow.withdraw(); 
        emit unlocked();
    }

//For claiming recieved 3CRV tokens which are given for locking CRV and
   // withdrawing stable tokens from curve 3pool using those 3CRV and sending those stable tokens to an address
    function claim3CRV()public onlyWallet(){
        uint prevCoin=poolToken.balanceOf(address(this));
        feeDistributor.claim();
        uint postCoin=poolToken.balanceOf(address(this));
        uint[3] memory minimum;
        pool.remove_liquidity(postCoin-prevCoin,minimum);
        for(uint i=0;i<3;i++){
            emit yieldTransfered(i,tokens[i].balanceOf(address(this)));
            tokens[i].safeTransfer(yieldDistributor,tokens[i].balanceOf(address(this)));
        }
    }
    
    // Function to sell CRV using uniswap to any stable token and send that token to an address
    function sellCRV(uint8 _index,uint _amount) public onlyWallet() {  //here index=0 means convert crv into DAI , index=1 means crv into USDC , index=2 means crv into USDT
        uint256 crvAmt = IERC20(crvAddr).balanceOf(address(this));
        uint256 prevCoin = tokens[_index].balanceOf(address(this));
        require(crvAmt > 0, "insufficient CRV");
        crvAmt=crvAmt.mul(crvBreak).div(DENOMINATOR);
        crvAddr.safeApprove(address(uniAddr), 0);
        crvAddr.safeApprove(address(uniAddr), crvAmt);
        address[] memory path; 
        if(TEST) {
            path = new address[](2);
            path[0] = address(crvAddr);
            path[1] = address(tokens[_index]);

        } else {    
            path = new address[](3);
            path[0] = address(crvAddr);
            path[1] = wethAddr;
            path[2] = address(tokens[_index]);
        }
        uint minimumAmount=_amount.sub(_amount.mul(uniswapSlippage).div(DENOMINATOR));
        UniswapI(uniAddr).swapExactTokensForTokens(
            crvAmt, 
            minimumAmount, 
            path, 
            address(this), 
            block.timestamp + 1800
        );
        uint256 postCoin=tokens[_index].balanceOf(address(this));
        tokens[_index].safeTransfer(yieldDistributor,postCoin.sub(prevCoin));
        emit yieldTransfered(_index,postCoin.sub(prevCoin));
    }

    //calulates how much VeCRV is needed to get 2.5X boost.
    function gaugeVeCRVCalculator() public view returns(uint256){
          uint minimumVeCRV ;
          minimumVeCRV =(gauge.balanceOf(address(this)).mul(100)).sub((gauge.balanceOf(address(this)).mul(40))).mul(voteEscrow.totalSupply()).div(gauge.totalSupply().mul(60));
          return minimumVeCRV;
    }
    
    event yieldTransfered(uint index,uint coin);
    event staked(uint amount);
    event unstaked(uint amount);
    event crvClaimed();
    event locked(uint amount);
    event unlocked();
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}