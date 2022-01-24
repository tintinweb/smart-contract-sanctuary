//SourceUnit: ClaimReward.sol

/* SPDX-License-Identifier: MIT License */

pragma solidity ^0.8.0;

import './Staking.sol';




contract ClaimReward {
    using SafeTRC20 for ITRC20;
    using _SafeMath for uint256;


    address public owner;
    ITRC20 public SST_token;
    Staking _Staking;

    uint256 public decimals =6;
    uint256 public _rewardDistributed;

    // reward timeline
    uint256 public reward_timeline;


    //reward percentages in stages
    uint8 public reward_first_stage=25;
    uint8 public reward_second_stage=50;
    uint8 public reward_third_stage=75;
    uint8 public reward_final_stage=100;


    // stages of stakes for rewards
    uint256 public firstStageRewardBalance=100 * 10 ** decimals;
    uint256 public secondStageRewardBalance=1000 * 10 ** decimals;
    uint256 public thirdStageRewardBalance=10000 * 10 ** decimals;
    uint256 public FinalStageRewardBalance=100000 * 10 ** decimals;


    // owner 
    mapping(address => uint256 ) public ClaimableTokens; 
    mapping(address => uint256) public Eligible_Stakes; // pushed from backend how much stake user is eligible in one month

    // total refunds
    mapping(address => uint256) public ClaimedTokens;
    

    constructor(address _token, address Staking_) {
        owner = msg.sender; 
        SST_token = ITRC20(_token);
        _Staking=Staking(Staking_);
    }


    function updateOwner(address newOwner) external onlyOwner{
        owner = newOwner;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyOwner{
       ITRC20(_token).transfer( _to, _amount) ; 
    }

    // for user to claim Reward

    function claimReward() external {
        require(ClaimableTokens[msg.sender] > 0 , "Amount of Claimable Tokens is 0");
        require(_Staking._balance_SST(msg.sender) >= firstStageRewardBalance, "User is not eligible for rewards" );
        require(Eligible_Stakes[msg.sender] >= firstStageRewardBalance, "Should have a minimum witholding period of 1 month ");

        uint256 refund_amount= calculateRefund(ClaimableTokens[msg.sender],Eligible_Stakes[msg.sender],msg.sender);

        if(refund_amount == 0 ) revert();
        SST_token.safeTransfer(msg.sender, refund_amount);

        _rewardDistributed=_rewardDistributed.add(refund_amount);
        ClaimedTokens[msg.sender]=ClaimedTokens[msg.sender].add(refund_amount);
        ClaimableTokens[msg.sender] =0;
        Eligible_Stakes[msg.sender] =0;

        emit AirdropProcessed(msg.sender,refund_amount,block.timestamp);
    }

    /*
                            Reward structure
                            {
                                user: address,
                                claimable_tokens: no. of tokens spent in one month,
                                stakes: amount of eligible stakes for reward
                            }
                            
    */

    function updateRewards(        
        address[] memory _addresses, 
        uint256[] memory tokens, 
        uint256[] memory stakes) 
        external onlyOwner{

            for(uint i=0;i<_addresses.length;++i){
                address _address= _addresses[i];
                uint256 claimable_tokens= tokens[i];
                uint256 total_stakes= stakes[i];

                Eligible_Stakes[_address] = total_stakes;
                ClaimableTokens[_address] = claimable_tokens;
            }

    }

    function refund_percentage(uint256 tokens,uint refund_percent)internal pure returns(uint){
        return (tokens.mul(refund_percent.mul(100))).div(10000);

    }
    
    // Calculates how much refund a user can earn on the basis of no. of stakes for the number of tokens as input 
    // example===     tokens=100 and _stakes=100*10**decimals then refund should 25 as per the return refund percentage policy.

    function calculateRefund(uint256 tokens,uint256 _stakes,address person) public view returns(uint256){
        require(_Staking._balance_SST(person) >= firstStageRewardBalance,'Minimum amount of Staking balance not satisfied');

        uint256 return_refund=0;
        
        if(_stakes >= firstStageRewardBalance && _stakes < secondStageRewardBalance) return_refund= refund_percentage(tokens,reward_first_stage);
        else if(_stakes >= secondStageRewardBalance && _stakes < thirdStageRewardBalance) return_refund= refund_percentage(tokens,reward_second_stage);
        else if(_stakes >= thirdStageRewardBalance && _stakes < FinalStageRewardBalance) return_refund= refund_percentage(tokens,reward_third_stage);
        else if(_stakes >= FinalStageRewardBalance ) return_refund= refund_percentage(tokens,reward_final_stage);

        return return_refund;
    }


    //Calculates the eligible Stakes 
    function Calc_EligibleStakes(address _address) public view returns(uint256){
        (uint256[] memory StakedTime,uint256[] memory StakedAmount,bool[] memory isActive) = _Staking.getAllStakes(_address);

        uint256 total_Stakes=0;

        for(uint256 i=0;i<StakedTime.length;++i){
           if(! isActive[i]) continue;

           if((block.timestamp - StakedTime[i]) > (reward_timeline.mul(86400)) ) total_Stakes= total_Stakes.add(StakedAmount[i]); 
        }

        return total_Stakes;


    }


    // Calculates user is eligible for how much Refund in percentage
    function Calc_Eligible_RefundPercent(address _address) external view returns(uint256){
        uint256 _eligibleStakes=Calc_EligibleStakes(_address);
        return Calc_RefundAsPerStakes(_eligibleStakes);
   
    }


    //Calculate the refund as per the amount of stake 
    function Calc_RefundAsPerStakes(uint256 _eligibleStakes) public view returns(uint256){
        if(_eligibleStakes < firstStageRewardBalance ) return 0;
        if(_eligibleStakes >= firstStageRewardBalance && _eligibleStakes < secondStageRewardBalance) return reward_first_stage;
        else if(_eligibleStakes >= secondStageRewardBalance && _eligibleStakes < thirdStageRewardBalance) return reward_second_stage;
        else if(_eligibleStakes >= thirdStageRewardBalance && _eligibleStakes < FinalStageRewardBalance) return reward_third_stage;
        else if(_eligibleStakes >= FinalStageRewardBalance) return reward_final_stage;
        return 0;

    } 

    // Set the timeline of the rewards
    function SetRewardTimeline(uint256 _newTimeline)external onlyOwner{
        reward_timeline= _newTimeline;
    }

    function SetStakeRewards(
        uint256 firstStage,uint256 secondStage,uint256 thirdStage,uint256 finalStage 
        ) external onlyOwner{
        firstStageRewardBalance= firstStage * 10 ** decimals;
        secondStageRewardBalance = secondStage * 10 ** decimals;
        thirdStageRewardBalance = thirdStage * 10 ** decimals;
        FinalStageRewardBalance= finalStage * 10 ** decimals;   
    }


    function SetRewardPercentages(
        uint8 firstStage,uint8 secondStage,uint8 thirdStage,uint8 finalStage 
        ) external onlyOwner{
            reward_first_stage= firstStage;
            reward_second_stage=secondStage;
            reward_third_stage= thirdStage;
            reward_final_stage= finalStage;
        }


    function updateDecimals(uint256 _decimals) external onlyOwner{
        decimals=_decimals;
    }


    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event AirdropProcessed(
        address recipient,
        uint amount,
        uint date
    );

}

//SourceUnit: Staking.sol

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;


pragma experimental ABIEncoderV2;
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library _SafeMath {
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
        require(c >= a, "_SafeMath: addition overflow");
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
        require(b <= a, "_SafeMath: subtraction overflow");
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
        require(c / a == b, "_SafeMath: multiplication overflow");
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
        require(b > 0, "_SafeMath: division by zero");
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
        require(b > 0, "_SafeMath: modulo by zero");
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // This method relies on extcodesize, which returns 0 for contracts in
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
library SafeTRC20 {
    using _SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {SST-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(ITRC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ITRC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeTRC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeTRC20: ERC20 operation did not succeed");
        }
    }
}
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

    constructor () {
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





// https://docs.synthetix.io/contracts/Pausable





interface IStaking {
    // Views
   

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function Stake(uint256 amount) external;

    function withdraw( uint256 id) external;
    
    
  
}

interface ITRC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address owner, address spender) external view returns(uint256);
}


contract Staking is IStaking, ReentrancyGuard, Ownable {
    using _SafeMath for uint256;
    using SafeTRC20 for ITRC20;

    /* ========== STATE VARIABLES ========== */

   
    ITRC20 public SST_token;

    
      struct StakeRecord {
      uint256 stakedTime;
      uint256 stakedAmount;
      bool isActive;
      }

      
    mapping(address => uint256[]) public stakedTime;
    mapping(address => uint256[]) public stakedAmount;
    mapping(address => bool[]) public stake_isActive;



    uint256 public _totalSupply;
    mapping(address => uint256) public _balance_SST;



    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _SST
    )   {
        SST_token = ITRC20(_SST);
    }
    



    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balance_SST[account];
    }
    
    // withdraw funds
    
     function transferSST(address wallet, uint256 amount) external onlyOwner {
         require( amount <= SST_token.balanceOf(address(this)));
         SST_token.safeTransfer(wallet, amount);
         
    }
  

    /* ========== MUTATIVE FUNCTIONS ========== */
 

    function Stake(uint256 amount) external override  nonReentrant    {
        require(amount > 0, "Cannot stake 0");

         _totalSupply = _totalSupply.add(amount);
         _balance_SST[msg.sender] = _balance_SST[msg.sender].add(amount);
         SST_token.safeTransferFrom(msg.sender,(address(this)), amount);
         stakedTime[msg.sender].push(block.timestamp);
         stakedAmount[msg.sender].push(amount);
         stake_isActive[msg.sender].push(true);
         emit Staked(msg.sender, amount, block.timestamp);

    }                                                  
    
    function withdraw(  uint256 _amount) external override  nonReentrant{

        require(_amount > 0, "Cannot withdraw 0");
        require(_amount <= _balance_SST[msg.sender]);

        address recipient= msg.sender;
        uint withdraw_amount= _amount;

        if(_balance_SST[recipient] == _amount ) {
            delete stakedTime[recipient];
            delete stakedAmount[recipient];
            delete stake_isActive[recipient];
            withdraw_amount = 0;
        }


        for(uint256 i=stakedAmount[recipient].length ; i> 0 && withdraw_amount > 0 ; --i){

            StakeRecord memory _record= StakeRecord({
                    stakedTime: stakedTime[recipient][i-1],
                    stakedAmount: stakedAmount[recipient][i-1],
                    isActive: stake_isActive[recipient][i-1]
                });

            if(_record.isActive ){
                if(withdraw_amount >= _record.stakedAmount){
                    withdraw_amount = withdraw_amount.sub(_record.stakedAmount);
                    stakedAmount[recipient][i-1]=0;
                    stake_isActive[recipient][i-1]=false;
                }else{
                    stakedAmount[recipient][i-1]=stakedAmount[recipient][i-1].sub(withdraw_amount);
                    withdraw_amount=0;
                }
            }
        }

        if(withdraw_amount > 0 ) revert();

        _balance_SST[msg.sender] = _balance_SST[msg.sender].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        SST_token.safeTransfer( msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount, block.timestamp);
       
    }

    function getTotalStakes(address _address) external view returns (uint256){
        return stakedAmount[_address].length;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyOwner{
       ITRC20(_token).transfer( _to, _amount) ; 
    }

 

   function getAllStakes(address _address) external view returns (uint256[] memory,uint256[] memory,bool[] memory) {
    return (stakedTime[_address],stakedAmount[_address],stake_isActive[_address]);
  } 

    /* ========== EVENTS ========== */

    
    event Staked(address indexed user, uint256 amount, uint256 time);
    event Withdrawn(address indexed user, uint256 amount,uint256 time);
    
   
}