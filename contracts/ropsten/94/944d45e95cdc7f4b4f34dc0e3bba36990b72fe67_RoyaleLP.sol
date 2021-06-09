/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


library Address {
   
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

 
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

    constructor () internal {
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


interface IERC20{
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

interface rStrategy {

    function deposit(uint256[3] calldata) external;
    function withdraw(uint256[3] calldata,uint[3] calldata) external;
    function withdrawAll()  external returns(uint256[3] memory);
    
}


contract RoyaleLP is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 public constant DENOMINATOR = 10000;

    uint128 public fees = 25; // for .25% fee, for 1.75% fee => 175

    uint256 public poolPart = 750 ; // 7.5% of total Liquidity will remain in the pool

    uint256 public selfBalance;

    IERC20[3] public tokens;

    IERC20 public rpToken;

    rStrategy public strategy;
    
    address public wallet;
    
    address public nominatedWallet;

    uint public YieldPoolBalance;
    uint public liquidityProvidersAPY;

    //storage for user related to supply and withdraw
    
    uint256 public lock_period = 1 minutes;

    struct depositDetails {
        uint index;
        uint amount;
        uint256 time;
        uint256 remAmt;
    }
    
    mapping(address => depositDetails[]) public amountSupplied;
    mapping(address => uint256[3]) public amountWithdraw;
    mapping(address => uint256[3]) public amountBurnt;
    
    mapping(address => bool) public isInQ;
    
    address[] public withdrawRecipients;
    
    uint public maxWithdrawRequests=25;
    
    uint256[3] public totalWithdraw;
    
    uint[3] public reserveAmount;
    mapping(address => bool)public reserveRecipients;
    
    //storage to store total loan given
    uint256 public loanGiven;
    
    uint public loanPart=2000;
    
  
    modifier onlyWallet(){
      require(wallet ==msg.sender, "NA");
      _;
    }
  
     modifier validAmount(uint amount){
      require(amount > 0 , "NV");
      _;
    }
    
    // EVENTS 
    event userSupplied(address user,uint amount,uint index);
    event userRecieved(address user,uint amount,uint index);
    event userAddedToQ(address user,uint amount,uint index);
    event feesTransfered(address user,uint amount,uint index);
    event loanTransfered(address recipient,uint amount,uint index);
    event loanRepayed(uint amount,uint index);
    event yieldAdded(uint amount,uint index);
    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);
   
    
    constructor(address[3] memory _tokens,address _rpToken,address _wallet) public {
        require(_wallet != address(0), "Wallet address cannot be 0");
        for(uint8 i=0; i<3; i++) {
            tokens[i] = IERC20(_tokens[i]);
        }
        rpToken = IERC20(_rpToken);
        wallet=_wallet;
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


    /* INTERNAL FUNCTIONS */
   
    
    //For checking whether array contains any non zero elements or not.
    function checkValidArray(uint256[3] memory amounts)internal pure returns(bool){
        for(uint8 i=0;i<3;i++){
            if(amounts[i]>0){
                return true;
            }
        }
        return false;
    }

    // This function deposits the liquidity to yield generation pool using yield Strategy contract
    function _deposit(uint256[3] memory amounts) internal {
        strategy.deposit(amounts);
        uint decimal;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.add(amounts[i].mul(10**18).div(10**decimal));
        }
    }
   

    //This function is used to updating the array of user's individual deposit , called when users withdraw/claim tokens.
    function updateLockedRPT(address recipient,uint256 amount) internal{
        for(uint8 j=0; j<amountSupplied[recipient].length; j++) {
            if(amountSupplied[recipient][j].remAmt > 0 && amount > 0 ) {
                if(amount >= amountSupplied[recipient][j].remAmt) {
                        amount = amount.sub( amountSupplied[recipient][j].remAmt);
                        amountSupplied[recipient][j].remAmt = 0;
                }
                else {
                        amountSupplied[recipient][j].remAmt =(amountSupplied[recipient][j].remAmt).sub(amount);
                        amount = 0;
                }
            }
        }
     }

    //Funtion determines whether requested withdrawl amount is available in the pool or not.
    //If yes then fulfills withdraw request 
    //and if no then put the request into the withdraw queue.
    function checkWithdraw(uint256 amount,uint256 burnAmt,uint _index) internal{
        uint256 poolBalance;
        poolBalance = getBalances(_index);
        rpToken.burn(msg.sender, burnAmt);
        if(amount <= poolBalance) {
            uint decimal;
            decimal=tokens[_index].decimals();
            uint temp = amount.mul(fees).div(DENOMINATOR);
            selfBalance=selfBalance.sub(amount.mul(10**18).div(10**decimal));
            updateLockedRPT(msg.sender,burnAmt);
            tokens[_index].safeTransfer(msg.sender, amount.sub(temp));
            emit userRecieved(msg.sender, amount.sub(temp),_index); 
            tokens[_index].safeTransfer(wallet,temp);
            emit feesTransfered(wallet,temp,_index);
            
         }
         else {
             require(withdrawRecipients.length<maxWithdrawRequests || isInQ[msg.sender],"requests limit Exceeded");
            _takeBackQ(amount,burnAmt,_index);
            emit userAddedToQ(msg.sender, amount,_index);
        }
    }



    // this will add unfulfilled withdraw requests to the withdrawl queue
    function _takeBackQ(uint256 amount,uint256 _burnAmount,uint256 _index) internal {
        amountWithdraw[msg.sender][_index] =amountWithdraw[msg.sender][_index].add( amount);
        amountBurnt[msg.sender][_index]=amountBurnt[msg.sender][_index].add(_burnAmount);
        uint currentPoolAmount=getBalances(_index);
        uint withdrawAmount=amount.sub(currentPoolAmount);
        reserveAmount[_index] = reserveAmount[_index].add(currentPoolAmount);
        totalWithdraw[_index]=totalWithdraw[_index].add(withdrawAmount);
        uint total;
        total=(totalWithdraw[1].add(totalWithdraw[2])).mul(1e18).div(10**6);
        require((totalWithdraw[0]+total)<=YieldPoolBalance,"Not enough balance");
        if(!isInQ[msg.sender]) {
            isInQ[msg.sender] = true;
            withdrawRecipients.push(msg.sender);
            
        }

    }


    //this function is called when Royale Govenance withdrawl from yield generation pool.It add all the withdrawl amount in the reserve amount.
    //All the users who requested for the withdrawl are added to the reserveRecipients.
    function updateWithdrawQueue() internal{
        for(uint8 i=0;i<3;i++){
            reserveAmount[i]=reserveAmount[i].add(totalWithdraw[i]);
            totalWithdraw[i]=0;
        }
        for(uint i=0; i<withdrawRecipients.length; i++) {
            reserveRecipients[withdrawRecipients[i]]=true;
            isInQ[withdrawRecipients[i]]=false;
        }
        uint count=withdrawRecipients.length;
        for(uint i=0;i<count;i++){
            withdrawRecipients.pop();
        }
    }

    // this will withdraw Liquidity from yield genaration pool using yield Strategy
    function _withdraw(uint256[3] memory amounts , uint[3] memory max_burn) internal {
        strategy.withdraw(amounts,max_burn);
        uint decimal;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            YieldPoolBalance =YieldPoolBalance.sub(amounts[i].mul(10**18).div(10**decimal));
        }
    }

    //This function calculate RPT to be mint or burn
    //amount parameter is amount of token
    //_index can be 0/1/2 
    //0-DAI
    //1-USDC
    //2-USDT
    function calcRptAmount(uint256 amount,uint _index) public view returns(uint256) {
        uint256 total = calculateTotalToken(true);
        uint256 decimal = 0;
        decimal=tokens[_index].decimals();
        amount=amount.mul(1e18).div(10**decimal);
        if(total==0){
            return amount;
        }
        else{
          return (amount.mul(rpToken.totalSupply()).div(total)); 
        }
    }



    //function to check available amount to withdraw for user
    function availableLiquidity(address addr, uint coin,bool _time) public view returns(uint256 token,uint256 RPT) {
        uint256 amount=0;
        for(uint8 j=0; j<amountSupplied[addr].length; j++) {
                if( (!_time || (now - amountSupplied[addr][j].time)  > lock_period)&&amountSupplied[addr][j].remAmt >0)   {
                        amount =amount.add(amountSupplied[addr][j].remAmt);
                }
        }
        for(uint8 i=0;i<3;i++){
            amount =amount.sub(amountBurnt[addr][i]);
        }
        uint256 total=calculateTotalToken(true);
        uint256 decimal;
        decimal=tokens[coin].decimals();
        return ((amount.mul(total).mul(10**decimal).div(rpToken.totalSupply())).div(10**18),amount);
    }
    

    //calculated available total tokens in the pool by substracting withdrawal, reserve amount.
    //In case supply is true , it adds total loan given.
    function calculateTotalToken(bool _supply)public view returns(uint256){
        uint256 decimal;
        uint withdrawTotal;
        uint reserveTotal;
        for(uint8 i=0; i<3; i++) {
            decimal = tokens[i].decimals();
            withdrawTotal=withdrawTotal.add(totalWithdraw[i].mul(1e18).div(10**decimal));
            reserveTotal=reserveTotal.add(reserveAmount[i].mul(1e18).div(10**decimal));
        } 
        if(_supply){
            return selfBalance.sub(withdrawTotal).sub(reserveTotal).add(loanGiven);
        }
        else{
            return selfBalance.sub(withdrawTotal).sub(reserveTotal);
        }
        
    }
    
    /* USER FUNCTIONS (exposed to frontend) */
   
    //For depositing liquidity to the pool.
    //_index will be 0/1/2     0-DAI , 1-USDC , 2-USDT
    function supply(uint256 amount,uint256 _index) external nonReentrant  validAmount(amount){
        uint decimal;
        uint256 mintAmount=calcRptAmount(amount,_index);
        amountSupplied[msg.sender].push(depositDetails(_index,amount,now,mintAmount));
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(10**18).div(10**decimal));
        tokens[_index].safeTransferFrom(msg.sender, address(this), amount);
        rpToken.mint(msg.sender, mintAmount);
        emit userSupplied(msg.sender, amount,_index);
    }

    
    //for withdrawing the liquidity
    //First Parameter is amount of RPT
    //Second is which token to be withdrawal with this RPT.
    function requestWithdrawWithRPT(uint256 amount,uint256 _index) external nonReentrant validAmount(amount){
        require(!reserveRecipients[msg.sender],"Claim first");
        require(rpToken.balanceOf(msg.sender) >= amount, "low RPT");
        (,uint availableRPT)=availableLiquidity(msg.sender,_index,true );
        require(availableRPT>=amount,"NA");
        uint256 total = calculateTotalToken(true);
        uint256 tokenAmount;
        tokenAmount=amount.mul(total).div(rpToken.totalSupply());
        require(tokenAmount <= calculateTotalToken(false),"Not Enough Pool balance");
        uint decimal;
        decimal=tokens[_index].decimals();
        checkWithdraw(tokenAmount.mul(10**decimal).div(10**18),amount,_index);  
    }
    
    //For claiming withdrawal after user added to the reserve recipient.
    function claimTokens() external  nonReentrant{
        require(reserveRecipients[msg.sender] , "request withdraw first");
        uint totalBurnt;
        uint decimal;
        for(uint8 i=0; i<3; i++) {
            if(amountWithdraw[msg.sender][i] > 0) {
                decimal=tokens[i].decimals();
                uint temp = (amountWithdraw[msg.sender][i].mul(fees)).div(DENOMINATOR);
                reserveAmount[i] =reserveAmount[i].sub(amountWithdraw[msg.sender][i]);
                selfBalance = selfBalance.sub(amountWithdraw[msg.sender][i].mul(1e18).div(10**decimal));
                totalBurnt =totalBurnt.add(amountBurnt[msg.sender][i]);
                tokens[i].safeTransfer(msg.sender, amountWithdraw[msg.sender][i].sub(temp));
                emit userRecieved(msg.sender,amountWithdraw[msg.sender][i].sub(temp),i);
                amountWithdraw[msg.sender][i] = 0;
                amountBurnt[msg.sender][i]=0;
                tokens[i].safeTransfer(wallet,temp);
                emit feesTransfered(wallet,temp,i);
            }
        }
        updateLockedRPT(msg.sender,totalBurnt);
        reserveRecipients[msg.sender] = false;
    }

    // this function deposits without minting RPT.
    //Used to deposit Yield
    function depositYield(uint256 amount,uint _index) external{
        uint decimal;
        decimal=tokens[_index].decimals();
        selfBalance=selfBalance.add(amount.mul(1e18).div(10**decimal));
        liquidityProvidersAPY=liquidityProvidersAPY.add(amount.mul(1e18).div(10**decimal));
        tokens[_index].safeTransferFrom(msg.sender,address(this),amount);
        emit yieldAdded(amount,_index);
    }


    /* CORE FUNCTIONS (called by owner only) */

    //Transfer token z`1   o rStrategy by maintaining pool ratio.
    function deposit() onlyWallet() external  {
        uint256[3] memory amounts;
        uint256 totalAmount;
        uint256 decimal;
        totalAmount=calculateTotalToken(false);
        uint balanceAmount=totalAmount.mul(poolPart.div(3)).div(DENOMINATOR);
        uint tokenBalance;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            amounts[i]=getBalances(i);
            tokenBalance=balanceAmount.mul(10**decimal).div(10**18);
            if(amounts[i]>tokenBalance) {
                amounts[i]=amounts[i].sub(tokenBalance);
                tokens[i].safeTransfer(address(strategy),amounts[i]);
            }
            else{
                amounts[i]=0;
            }
        }
        if(checkValidArray(amounts)){
            _deposit(amounts);
        }
    }
    

    //Withdraw from Yield genaration pool.
    function withdraw(uint[3] memory max_burn) onlyWallet() external  {
        require(checkValidArray(totalWithdraw), "queue empty");
        _withdraw(totalWithdraw,max_burn);
        updateWithdrawQueue();
    }

   //Withdraw total liquidity from yield generation pool
    function withdrawAll() external onlyWallet() {
        uint[3] memory amounts;
        amounts=strategy.withdrawAll();
        uint decimal;
        selfBalance=0;
        for(uint8 i=0;i<3;i++){
            decimal=tokens[i].decimals();
            selfBalance=selfBalance.add((tokens[i].balanceOf(address(this))).mul(1e18).div(10**decimal));
        }
        YieldPoolBalance=0;
        updateWithdrawQueue();
    }


    //function for rebalancing royale pool(ratio)       
    function rebalance(uint[3] memory max_burn) onlyWallet() external {
        uint256 currentAmount;
        uint256[3] memory amountToWithdraw;
        uint256[3] memory amountToDeposit;
        uint totalAmount;
        uint256 decimal;
        totalAmount=calculateTotalToken(false);
        uint balanceAmount=totalAmount.mul(poolPart.div(3)).div(DENOMINATOR);
        uint tokenBalance;
        for(uint8 i=0;i<3;i++) {
           currentAmount=getBalances(i);
           decimal=tokens[i].decimals();
           tokenBalance=balanceAmount.mul(10**decimal).div(10**18);
           if(tokenBalance > currentAmount) {
              amountToWithdraw[i] = tokenBalance.sub(currentAmount);
           }
           else if(tokenBalance < currentAmount) {
               amountToDeposit[i] = currentAmount.sub(tokenBalance);
               tokens[i].safeTransfer(address(strategy), amountToDeposit[i]);
               
           }
           else {
               amountToWithdraw[i] = 0;
               amountToDeposit[i] = 0;
           }
        }
        if(checkValidArray(amountToDeposit)){
             _deposit(amountToDeposit);
             
        }
        if(checkValidArray(amountToWithdraw)) {
            _withdraw(amountToWithdraw,max_burn);
            
        }

    }
    
    //For withdrawing loan from the royale Pool
    function withdrawLoan(uint[3] memory amounts,address _recipient,uint[3] memory max_burn)external onlyWallet(){
        require(checkValidArray(amounts),"amount can not zero");
        uint decimal;
        uint total;
        for(uint i=0;i<3;i++){
           decimal=tokens[i].decimals();
           total=total.add(amounts[i].mul(1e18).div(10**decimal));
        }
        require(loanGiven.add(total)<=(calculateTotalToken(true).mul(loanPart).div(DENOMINATOR)),"Exceed limit");
        require(total<calculateTotalToken(false),"Not enough balance");
        bool strategyWithdraw=false;
        for(uint i=0;i<3;i++){
            if(amounts[i]>getBalances(i)){
                strategyWithdraw=true;
                break;
            }
        }
        if(strategyWithdraw){
           _withdraw(amounts,max_burn); 
        }
        loanGiven =loanGiven.add(total);
        selfBalance=selfBalance.sub(total);
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                tokens[i].safeTransfer(_recipient, amounts[i]);
                emit loanTransfered(_recipient,amounts[i],i);
            }
        }
        
    }
    
   // For repaying the loan to the royale Pool.
    function repayLoan(uint[3] memory amounts)external {
        require(checkValidArray(amounts),"amount can't be zero");
        uint decimal;
        for(uint8 i=0; i<3; i++) {
            if(amounts[i] > 0) {
                decimal=tokens[i].decimals();
                loanGiven =loanGiven.sub(amounts[i].mul(1e18).div(10**decimal));
                selfBalance=selfBalance.add(amounts[i].mul(1e18).div(10**decimal));
                tokens[i].safeTransferFrom(msg.sender,address(this),amounts[i]);
                emit loanRepayed(amounts[i],i);
            }
        }
    }
    

    //for changing pool ratio
    function changePoolPart(uint128 _newPoolPart) external onlyWallet()  {
        poolPart = _newPoolPart;
        
    }

   //For changing yield Strategy
    function changeStrategy(address _strategy) onlyWallet() external  {
        for(uint8 i=0;i<3;i++){
            require(YieldPoolBalance==0, "Call withdrawAll function first");
        } 
        strategy=rStrategy(_strategy);
        
    }

    function setLockPeriod(uint256 lockperiod) onlyWallet() external  {
        lock_period = lockperiod;
        
    }

     // for changing withdrawal fees  
    function setWithdrawFees(uint128 _fees) onlyWallet() external {
        fees = _fees;

    }
    
    function changeLoanPart(uint256 _value)onlyWallet() external{
        loanPart=_value;
    } 
    
    function getBalances(uint _index) public view returns(uint256) {
        return (tokens[_index].balanceOf(address(this)).sub(reserveAmount[_index]));
    }
}