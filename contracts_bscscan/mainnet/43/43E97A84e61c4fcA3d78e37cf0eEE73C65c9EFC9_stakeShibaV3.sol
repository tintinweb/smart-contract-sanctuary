// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
interface IvotingTokens{
    function balanceOf(
        address account
    ) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function burn(
        uint256 amount
    ) external returns (bool);
    function mint(
        address account,
        uint256 amount
    ) external returns (bool);
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Staker{
    struct data{
        uint256 stakedAmount;
        uint256 package;
        uint256 lastRewardTime;
        uint256 claimed;
        bool status;
    }
 }

contract stakeShibaV3 is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Staker for Staker.data;
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20Upgradeable private  _token;
    IvotingTokens private _votingToken;
    
    uint private activeStakers;
    address private owner;
    mapping(address => Staker.data) public stakers;
    mapping(uint256 => uint256) private stakingAPYs;
    mapping(uint256 => uint256) packages;
    mapping(uint256 => uint256) updatedTime;
    uint256 public totalStaked;
    uint256 public totalClaimed;
    uint256 public stakersLimit;
    
    event NewStake(uint256 amount, address staker, uint256 package);

    function initialize(IERC20Upgradeable token_, uint256 apy0, uint256 apy1, uint256 apy2) public initializer  {
        _token = token_;
        owner = msg.sender;
        updatedTime[0] = block.timestamp;
        updatedTime[1] = block.timestamp;
        updatedTime[2] = block.timestamp;
        
        // 100 = 1% or 10 = 0.1% or 1 = 0.01% 
        
        stakingAPYs[0] = apy0; // APY Percentage in UINT for Package 1 
        stakingAPYs[1] = apy1; // APY Percentage in UINT for Package 2
        stakingAPYs[2] = apy2; // APY Percentage in UINT for Package 3
        

        stakersLimit = 1000;
        packages[0] = 100000 ether;
        packages[1] = 250000 ether;
        packages[2] = 500000 ether;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20Upgradeable) {
        return _token;
    }

    /**
     * @return the voting token being held.
     */
    function votingToken() public view virtual returns (IvotingTokens) {
        return _votingToken;
    }
    
    /**
     * Stake Amount in the contract.
     */
    function StakeAmount(uint _package) public{
        require(_package <= 2, 'Invalid Staking Package');
        require(stakersLimit > activeStakers,"Staking Limit Exceeded");
        require(!stakers[msg.sender].status,"Already staked with this account");
        
        // Stake Brownce
        if(_package == 0){
            _stakeBrownce();
        }
        // Stake Silver
        else if(_package == 1){
            _stakeSilver();
        }
        // Stake Gold
        else if(_package == 2){
            _stakeGold();
        }
    }
    
    function _stakeBrownce() internal{
        stakers[msg.sender].stakedAmount = packages[0];
        stakers[msg.sender].package = 1;
        stakers[msg.sender].lastRewardTime = block.timestamp;
        stakers[msg.sender].status = true;
        
        totalStaked += packages[0];
        token().safeTransferFrom(msg.sender, address(this), packages[0]);
        votingToken().mint(msg.sender,packages[0]);
        
        activeStakers++;
        emit NewStake(packages[0],msg.sender,1);
    }
    
    function _stakeSilver() internal{
        stakers[msg.sender].stakedAmount = packages[1];
        stakers[msg.sender].package = 2;
        stakers[msg.sender].lastRewardTime = block.timestamp;
        stakers[msg.sender].status = true;
        
        totalStaked += packages[1];
        token().safeTransferFrom(msg.sender, address(this), packages[1]);
        votingToken().mint(msg.sender,packages[1]);
        
        activeStakers++;
        emit NewStake(packages[1],msg.sender,2);
    }
    
    function _stakeGold() internal{
        stakers[msg.sender].stakedAmount = packages[2];
        stakers[msg.sender].package = 3;
        stakers[msg.sender].lastRewardTime = block.timestamp;
        stakers[msg.sender].status = true;
        
        totalStaked += packages[2];
        token().safeTransferFrom(msg.sender, address(this), packages[2]);
        votingToken().mint(msg.sender,packages[2]);
        
        activeStakers++;
        emit NewStake(packages[2],msg.sender,3);
    }
    
    function checkRewards() public view returns(uint256, uint256){
        require(stakers[msg.sender].status,'You are not a staker');
        Staker.data memory stakee = stakers[msg.sender];
        uint256 perDayReward = stakee.stakedAmount.mul(stakingAPYs[stakee.package]).div(10000).div(365);
        uint256 claimableDays;
        if(stakee.lastRewardTime > updatedTime[stakee.package - 1]){
            claimableDays = block.timestamp.sub(stakee.lastRewardTime).div(1 days);
        }else{
            claimableDays = block.timestamp.sub(updatedTime[stakee.package - 1]).div(1 days);
        }
        uint256 claimableReward = perDayReward.mul(claimableDays);
        return (claimableDays,claimableReward);
    }
    
    /**
        * ClaimRewards:
        * Calculate and transfer rewards to staker, calculate reward from last reward time or update time 
        * if staking apy event occurs between staking period
     **/
    function claimRewards() public{
        require(msg.sender == tx.origin, 'Invalid Request');
        require(stakers[msg.sender].status, 'You are not a staker');
        require(block.timestamp.sub(stakers[msg.sender].lastRewardTime).div(1 days) > 0,'Already Claimed Today');
        uint256 perDayReward = stakers[msg.sender].stakedAmount.mul(stakingAPYs[stakers[msg.sender].package]).div(10000).div(365);
        uint256 claimableDays;
        
        if(stakers[msg.sender].lastRewardTime > updatedTime[stakers[msg.sender].package - 1]){
            claimableDays = block.timestamp.sub(stakers[msg.sender].lastRewardTime).div(1 days);
        }else{
            claimableDays = block.timestamp.sub(updatedTime[stakers[msg.sender].package - 1]).div(1 days);
        }
        
        uint256 claimableReward = perDayReward.mul(claimableDays);
        require(claimableReward < RemainingRewardsPot(), 'Reward Pot is empty');
        
        _token.safeTransfer(msg.sender,claimableReward);
        
        stakers[msg.sender].lastRewardTime += block.timestamp;
        stakers[msg.sender].claimed += claimableReward;
        totalClaimed += claimableReward;
        
    }
    
    function endStake() public{
        require(msg.sender == tx.origin, 'Invalid Request');
        require(stakers[msg.sender].status, 'You are not a staker');
        require(votingToken().balanceOf(msg.sender) >= stakers[msg.sender].stakedAmount, 'You must have equal voting tokens to end the stake');
        uint256 claimableDays = block.timestamp.sub(stakers[msg.sender].lastRewardTime).div(1 days);
        uint256 claimableReward = 0;
        if(claimableDays > 0){
            if(stakers[msg.sender].lastRewardTime < updatedTime[stakers[msg.sender].package - 1]){
                claimableDays = block.timestamp.sub(updatedTime[stakers[msg.sender].package - 1]).div(1 days);
            }
            uint256 perDayReward = stakers[msg.sender].stakedAmount.mul(stakingAPYs[stakers[msg.sender].package]).div(10000).div(365);
            claimableReward = perDayReward.mul(claimableDays);
            require(claimableReward < RemainingRewardsPot(), 'Reward Pot is empty');
        }
        votingToken().transferFrom(msg.sender, address(this), stakers[msg.sender].stakedAmount);
        _token.safeTransfer(msg.sender, stakers[msg.sender].stakedAmount+claimableReward);
        votingToken().burn(stakers[msg.sender].stakedAmount);
        stakers[msg.sender].lastRewardTime += block.timestamp;
        stakers[msg.sender].claimed += claimableReward;
        totalClaimed += claimableReward;
        totalStaked -= stakers[msg.sender].stakedAmount;
        stakers[msg.sender].status = false;
        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].package = 0;
        activeStakers--;
    }

    function emergencyEndstake() public{
        require(msg.sender == tx.origin, 'Invalid Request');
        require(stakers[msg.sender].status, 'You are not a staker');
        require(votingToken().balanceOf(msg.sender) >= stakers[msg.sender].stakedAmount, 'You must have equal voting tokens to end the stake');
        votingToken().transferFrom(msg.sender, address(this), stakers[msg.sender].stakedAmount);
        _token.safeTransfer(msg.sender, stakers[msg.sender].stakedAmount);
        votingToken().burn(stakers[msg.sender].stakedAmount);
        totalStaked -= stakers[msg.sender].stakedAmount;
        stakers[msg.sender].status = false;
        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].package = 0;
        activeStakers--;
    }
    
    function calculatePerDayRewards(uint256 amount, uint256 stakePlan) public view returns(uint256){
        uint256 perDayReward = amount.mul(stakingAPYs[stakePlan]).div(10000).div(365);
        return (perDayReward);
    }
    
    function RemainingRewardsPot() public view virtual returns (uint256) {
        return token().balanceOf(address(this)) - totalStaked;
    }
    
    function withdrawRewardsPot(uint256 amount) public onlyOwner {
        require(amount < RemainingRewardsPot(), 'Insufficient funds in RewardPot');
        _token.safeTransfer(msg.sender, amount);
    }

    function setVotingToken(IvotingTokens vToken_) public onlyOwner {
        _votingToken = vToken_;
    }
    
    //For Testing Purpose
    // function changeLastRewardTime(uint256 _lastrewardTime) public onlyOwner{
    //     stakers[msg.sender].lastRewardTime = _lastrewardTime;
    // }

    function changeStakersLimit(uint256 _limit) public onlyOwner{
        require(_limit > 0,"Stakers Limit Must Be greater than 0");
        stakersLimit = _limit;
    }    

    function currentTimestamp() public view returns(uint256){
        return block.timestamp;
    }

    function cT() public view returns(uint256){
        return 123;
    }
    
    /**
     * Change APY Functions:
     * Change APY with update time , so every staker should need to claim their rewards,
     * before any change apy event occurs
    **/
    function changeBrownceAPY(uint256 newAPY, uint256 _updatedTime) public onlyOwner{
        require(newAPY < 100000, 'APY cannot exceet 1000%');
        stakingAPYs[0] = newAPY;
        updatedTime[0] = _updatedTime;
    }
    
    function changeSilverAPY(uint256 newAPY, uint256 _updatedTime) public onlyOwner{
        require(newAPY < 100000, 'APY cannot exceet 1000%');
        stakingAPYs[1] = newAPY;
        updatedTime[1] = _updatedTime;
    }
    
    function changeGoldAPY(uint256 newAPY, uint256 _updatedTime) public onlyOwner{
        require(newAPY < 100000, 'APY cannot exceet 1000%');
        stakingAPYs[2] = newAPY;
        updatedTime[2] = _updatedTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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