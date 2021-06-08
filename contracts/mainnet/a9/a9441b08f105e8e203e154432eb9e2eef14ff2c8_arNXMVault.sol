/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev We've added a second owner to share control of the timelocked owner contract.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;
    
    // Second allows a DAO to share control.
    address private _secondOwner;
    address private _pendingSecond;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecondOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        _secondOwner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        emit SecondOwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return the address of the owner.
     */
    function secondOwner() public view returns (address) {
        return _secondOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }
    
    modifier onlyFirstOwner() {
        require(msg.sender == _owner, "msg.sender is not owner");
        _;
    }
    
    modifier onlySecondOwner() {
        require(msg.sender == _secondOwner, "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner || msg.sender == _secondOwner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyFirstOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferSecondOwnership(address newOwner) public onlySecondOwner {
        _pendingSecond = newOwner;
    }

    function receiveSecondOwnership() public {
        require(msg.sender == _pendingSecond, "only pending owner can call this function");
        _transferSecondOwnership(_pendingSecond);
        _pendingSecond = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferSecondOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit SecondOwnershipTransferred(_secondOwner, newOwner);
        _secondOwner = newOwner;
    }

    uint256[50] private __gap;
}



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
    
    function burn(address from, uint256 amount) external returns (bool);

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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IWNXM {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
    
    function burn(address from, uint256 amount) external returns (bool);

    function wrap(uint256 amount) external;
    
    function unwrap(uint256 amount) external;

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
 * @dev Quick interface for the Nexus Mutual contract to work with the Armor Contracts.
 **/

// to get nexus mutual contract address
interface INxmMaster {
    function tokenAddress() external view returns(address);
    function owner() external view returns(address);
    function pauseTime() external view returns(uint);
    function masterInitialized() external view returns(bool);
    function isPause() external view returns(bool check);
    function isMember(address _add) external view returns(bool);
    function getLatestAddress(bytes2 _contractName) external view returns(address payable contractAddress);
}

interface IPooledStaking {
    function lastUnstakeRequestId() external view returns(uint256);
    function stakerDeposit(address user) external view returns (uint256);
    function stakerMaxWithdrawable(address user) external view returns (uint256);
    function withdrawReward(address user) external;
    function requestUnstake(address[] calldata protocols, uint256[] calldata amounts, uint256 insertAfter) external;
    function depositAndStake(uint256 deposit, address[] calldata protocols, uint256[] calldata amounts) external;
    function stakerContractStake(address staker, address protocol) external view returns (uint256);
    function stakerContractPendingUnstakeTotal(address staker, address protocol) external view returns(uint256);
    function withdraw(uint256 amount) external;
    function stakerReward(address staker) external view returns (uint256);
}

interface IClaimsData {
    function getClaimStatusNumber(uint256 claimId) external view returns (uint256, uint256);
    function getClaimDateUpd(uint256 claimId) external view returns (uint256);
}

interface INXMPool {
    function buyNXM(uint minTokensOut) external payable;
}

interface IRewardDistributionRecipient {
    function notifyRewardAmount(uint256 reward) payable external;
}

interface IRewardManager is IRewardDistributionRecipient {
  function initialize(address _rewardToken, address _stakeController) external;
  function stake(address _user, address _referral, uint256 _coverPrice) external;
  function withdraw(address _user, address _referral, uint256 _coverPrice) external;
  function getReward(address payable _user) external;
}

interface IShieldMining {
  function claimRewards(
    address[] calldata stakedContracts,
    address[] calldata sponsors,
    address[] calldata tokenAddresses
  ) external returns (uint[] memory tokensRewarded);
}
/**
 * @title arNXM Vault
 * @dev Vault to stake wNXM or NXM in Nexus Mutual while maintaining your liquidity.
 *      This is V2 which replaces V1 behind a proxy. Updated variables at the bottom.
 * @author Armor.fi -- Robert M.C. Forster, Taek Lee
 * SPDX-License-Identifier: (c) Armor.Fi DAO, 2021
**/
contract arNXMVault is Ownable {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint256 constant private DENOMINATOR = 1000;
    
    // Amount of time between 
    uint256 public restakePeriod;
    
    // Amount of time that rewards are distributed over.
    uint256 public rewardDuration;
    
    // This used to be unstake percent but has now been deprecated in favor of individual unstakes.
    // Paranoia results in this not being replaced but rather deprecated and new variables placed at the bottom. 
    uint256 public ____deprecated____;
    
    // Amount of wNXM (in token Wei) to reserve each period.
    // Overwrites reservePercent in update.
    uint256 public reserveAmount;
    
    // Withdrawals may be paused if a hack has recently happened. Timestamp of when the pause happened.
    uint256 public withdrawalsPaused;
    
    // Amount of time withdrawals may be paused after a hack.
    uint256 public pauseDuration;
    
    // Address that will receive administration funds from the contract.
    address public beneficiary;
    
    // Percent of funds to be distributed for administration of the contract. 10 == 1%; 1000 == 100%.
    uint256 public adminPercent;
    
    // Percent of staking rewards that referrers get.
    uint256 public referPercent;

    // Timestamp of when the last restake took place--7 days between each.
    uint256 public lastRestake;
    
    // The amount of the last reward.
    uint256 public lastReward;
    
    // Uniswap, Maker, Compound, Aave, Curve, Synthetix, Yearn, RenVM, Balancer, dForce.
    address[] public protocols;
    
    // Amount to unstake each time.
    uint256[] private amounts;
    
    // Protocols being actively used in staking or unstaking.
    address[] private activeProtocols;

    struct WithdrawalRequest {
        uint48 requestTime;
        uint104 nAmount;
        uint104 arAmount;
    }

    // Nxm tokens.
    IERC20 public wNxm;
    IERC20 public nxm;
    IERC20 public arNxm;
    
    // Nxm Master address.
    INxmMaster public nxmMaster;
    
    // Reward manager for referrers.
    IRewardManager public rewardManager;
    
    // Referral => referrer
    mapping (address => address) public referrers;

    event Deposit(address indexed user, uint256 nAmount, uint256 arAmount, uint256 timestamp);
    event WithdrawRequested(address indexed user, uint256 arAmount, uint256 nAmount, uint256 requestTime, uint256 withdrawTime);
    event Withdrawal(address indexed user, uint256 nAmount, uint256 arAmount, uint256 timestamp);
    event Restake(uint256 withdrawn, uint256 unstaked, uint256 staked, uint256 totalAum, uint256 timestamp);
    event NxmReward(uint256 reward, uint256 timestamp, uint256 totalAum);
    
    // Avoid composability issues for liquidation.
    modifier notContract {
        require(msg.sender == tx.origin, "Sender must be an EOA.");
        _;
    }
    
    // Functions as re-entrancy protection and more.
    // Mapping down below with other update variables.
    modifier oncePerTx {
        require(block.timestamp > lastCall[tx.origin], "May only call this contract once per transaction.");
        lastCall[tx.origin] = block.timestamp;
        _;
    }

    /**
     * @param _protocols List of the 10 protocols we're using.
     * @param _wNxm Address of the wNxm contract.
     * @param _arNxm Address of the arNxm contract.
     * @param _nxmMaster Address of Nexus' master address (to fetch others).
     * @param _rewardManager Address of the ReferralRewards smart contract.
    **/
    function initialize(address[] memory _protocols, 
                address _wNxm, 
                address _arNxm,
                address _nxm,
                address _nxmMaster,
                address _rewardManager)
      public
    {
        require(address(arNxm) == address(0), "Contract has already been initialized.");
        
        for (uint256 i = 0; i < _protocols.length; i++) protocols.push(_protocols[i]);
        
        Ownable.initializeOwnable();
        wNxm = IERC20(_wNxm);
        nxm = IERC20(_nxm);
        arNxm = IERC20(_arNxm);
        nxmMaster = INxmMaster(_nxmMaster);
        rewardManager = IRewardManager(_rewardManager);
        // unstakePercent = 100;
        adminPercent = 0;
        referPercent = 25;
        reserveAmount = 30 ether;
        pauseDuration = 10 days;
        beneficiary = msg.sender;
        restakePeriod = 3 days;
        rewardDuration = 9 days;

        // Approve to wrap and send funds to reward manager.
        _approveNxm(_wNxm);
        arNxm.approve( _rewardManager, uint256(-1) );
    }
    
    /**
     * @dev Deposit wNxm or NXM to get arNxm in return.
     * @param _nAmount The amount of NXM to stake.
     * @param _referrer The address that referred this user.
     * @param _isNxm True if the token is NXM, false if the token is wNXM.
    **/
    function deposit(uint256 _nAmount, address _referrer, bool _isNxm)
      external
      oncePerTx
    {
        if ( referrers[msg.sender] == address(0) ) {
            referrers[msg.sender] = _referrer != address(0) ? _referrer : beneficiary;
            address refToSet = _referrer != address(0) ? _referrer : beneficiary;
            referrers[msg.sender] = refToSet;

            // A wallet with a previous arNXM balance would be able to subtract referral weight that it never added.
            uint256 prevBal = arNxm.balanceOf(msg.sender);
            if (prevBal > 0) rewardManager.stake(refToSet, msg.sender, prevBal); 
        }
        
        // This amount must be determined before arNxm mint.
        uint256 arAmount = arNxmValue(_nAmount);

        if (_isNxm) {
            nxm.safeTransferFrom(msg.sender, address(this), _nAmount);
        } else {
            wNxm.safeTransferFrom(msg.sender, address(this), _nAmount);
            _unwrapWnxm(_nAmount);
        }

        // Mint also increases sender's referral balance through alertTransfer.
        arNxm.mint(msg.sender, arAmount);
        
        emit Deposit(msg.sender, _nAmount, arAmount, block.timestamp);
    }
    
    /**
     * @dev Withdraw an amount of wNxm or NXM by burning arNxm.
     * @param _arAmount The amount of arNxm to burn for the wNxm withdraw.
     * @param _payFee Flag to pay fee to withdraw without delay.
    **/
    function withdraw(uint256 _arAmount, bool _payFee)
      external
      oncePerTx
    {
        require(block.timestamp.sub(withdrawalsPaused) > pauseDuration, "Withdrawals are temporarily paused.");

        // This amount must be determined before arNxm burn.
        uint256 nAmount = nxmValue(_arAmount);
        require(totalPending.add(nAmount) <= nxm.balanceOf(address(this)), "Not enough NXM available for witthdrawal.");

        if (_payFee) {
            uint256 fee = nAmount.mul(withdrawFee).div(1000);
            uint256 disbursement = nAmount.sub(fee);

            // Burn also decreases sender's referral balance through alertTransfer.
            arNxm.burn(msg.sender, _arAmount);
            _wrapNxm(disbursement);
            wNxm.safeTransfer(msg.sender, disbursement);
            
            emit Withdrawal(msg.sender, nAmount, _arAmount, block.timestamp);
        } else {
            totalPending = totalPending.add(nAmount);
            arNxm.safeTransferFrom(msg.sender, address(this), _arAmount);
            WithdrawalRequest memory prevWithdrawal = withdrawals[msg.sender];
            withdrawals[msg.sender] = WithdrawalRequest(
                                        uint48(block.timestamp), 
                                        prevWithdrawal.nAmount + uint104(nAmount), 
                                        prevWithdrawal.arAmount + uint104(_arAmount)
                                      );

            emit WithdrawRequested(msg.sender, _arAmount, nAmount, block.timestamp, block.timestamp.add(withdrawDelay));
        }
    }

    /**
     * @dev Withdraw from request
    **/
    function withdrawFinalize()
      external
      oncePerTx
    {
        WithdrawalRequest memory withdrawal = withdrawals[msg.sender];
        uint256 nAmount = uint256(withdrawal.nAmount);
        uint256 arAmount = uint256(withdrawal.arAmount);
        uint256 requestTime = uint256(withdrawal.requestTime);

        require(block.timestamp.sub(withdrawalsPaused) > pauseDuration, "Withdrawals are temporarily paused.");
        require(requestTime.add(withdrawDelay) <= block.timestamp, "Not ready to withdraw");
        require(nAmount > 0, "No pending amount to withdraw");

        // Burn also decreases sender's referral balance through alertTransfer.
        arNxm.burn(address(this), arAmount);
        _wrapNxm(nAmount);
        wNxm.safeTransfer(msg.sender, nAmount);
        delete withdrawals[msg.sender];
        totalPending = totalPending.sub(nAmount);

        emit Withdrawal(msg.sender, nAmount, arAmount, block.timestamp);
    }

    /**
     * @dev Restake that may be called by anyone.
     * @param _lastId Last unstake request ID on Nexus Mutual.
    **/
    function restake(uint256 _lastId)
      external
    {
        // Check that this is only called once per week.
        require(lastRestake.add(restakePeriod) <= block.timestamp, "It has not been enough time since the last restake.");
        _restake(_lastId);
    }

    /**
     * @dev Restake that may be called only by owner. Bypasses restake period restrictions.
     * @param _lastId Last unstake request ID on Nexus Mutual.
    **/
    function ownerRestake(uint256 _lastId)
      external
      onlyOwner
    {
        _restake(_lastId);
    }

    /**
     * @dev Restake is to be called weekly. It unstakes 7% of what's currently staked, then restakes.
     * @param _lastId Frontend must submit last ID because it doesn't work direct from Nexus Mutual.
    **/
    function _restake(uint256 _lastId)
      internal
      notContract
      oncePerTx
    {   
        // All Nexus functions.
        uint256 withdrawn = _withdrawNxm();
        // This will stake for all protocols, including unstaking protocols
        uint256 staked = _stakeNxm();
        // This will unstake from all unstaking protocols
        uint256 unstaked = _unstakeNxm(_lastId);

        startProtocol = startProtocol + bucketSize >= protocols.length ? 0 : startProtocol + bucketSize;
        if (startProtocol < checkpointProtocol) startProtocol = checkpointProtocol;
        lastRestake = block.timestamp;

        emit Restake(withdrawn, unstaked, staked, aum(), block.timestamp);
    }

    /**
     * @dev Split off from restake() function to enable reward fetching at any time.
    **/
    function getRewardNxm() 
      external 
      notContract 
    {
        uint256 prevAum = aum();
        uint256 rewards = _getRewardsNxm();

        if (rewards > 0) {
            lastRewardTimestamp = block.timestamp;
            emit NxmReward(rewards, block.timestamp, prevAum);
        } else if(lastRewardTimestamp == 0) {
            lastRewardTimestamp = block.timestamp;
        }
    }
    
    /**
     * @dev claim rewards from shield mining
     * @param _shieldMining shield mining contract address
     * @param _protocol Protocol funding the rewards.
     * @param _sponsor sponsor address who funded the shield mining
     * @param _token token address that sponsor is distributing
    **/
    function getShieldMiningRewards(address _shieldMining, address _protocol, address _sponsor, address _token) 
      external
      notContract
    {
        address[] memory protocol = new address[](1);
        protocol[0] = _protocol;
        address[] memory sponsor = new address[](1);
        sponsor[0] = _sponsor;
        address[] memory token = new address[](1);
        token[0] = _token;
        IShieldMining(_shieldMining).claimRewards(protocol, sponsor, token);
    }

    /**
     * @dev Find the arNxm value of a certain amount of wNxm.
     * @param _nAmount The amount of NXM to check arNxm value of.
     * @return arAmount The amount of arNxm the input amount of wNxm is worth.
    **/
    function arNxmValue(uint256 _nAmount)
      public
      view
    returns (uint256 arAmount)
    {
        // Get reward allowed to be distributed.
        uint256 reward = _currentReward();
        
        // aum() holds full reward so we sub lastReward (which needs to be distributed over time)
        // and add reward that has been distributed
        uint256 totalN = aum().add(reward).sub(lastReward);
        uint256 totalAr = arNxm.totalSupply();
        
        // Find exchange amount of one token, then find exchange amount for full value.
        if (totalN == 0) {
            arAmount = _nAmount;
        } else {
            uint256 oneAmount = ( totalAr.mul(1e18) ).div(totalN);
            arAmount = _nAmount.mul(oneAmount).div(1e18);
        }
    }
    
    /**
     * @dev Find the wNxm value of a certain amount of arNxm.
     * @param _arAmount The amount of arNxm to check wNxm value of.
     * @return nAmount The amount of wNxm the input amount of arNxm is worth.
    **/
    function nxmValue(uint256 _arAmount)
      public
      view
    returns (uint256 nAmount)
    {
        // Get reward allowed to be distributed.
        uint256 reward = _currentReward();
        
        // aum() holds full reward so we sub lastReward (which needs to be distributed over time)
        // and add reward that has been distributed
        uint256 totalN = aum().add(reward).sub(lastReward);
        uint256 totalAr = arNxm.totalSupply();
        
        // Find exchange amount of one token, then find exchange amount for full value.
        uint256 oneAmount = ( totalN.mul(1e18) ).div(totalAr);
        nAmount = _arAmount.mul(oneAmount).div(1e18);
    }
    
    /**
     * @dev Used to determine total Assets Under Management.
     * @return aumTotal Full amount of assets under management (wNXM balance + stake deposit).
    **/
    function aum()
      public
      view
    returns (uint256 aumTotal)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        uint256 balance = nxm.balanceOf( address(this) );
        uint256 stakeDeposit = pool.stakerDeposit( address(this) );
        aumTotal = balance.add(stakeDeposit);
    }

    /**
     * @dev Used to determine staked nxm amount in pooled staking contract.
     * @return staked Staked nxm amount.
    **/
    function stakedNxm()
      public
      view
    returns (uint256 staked)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        staked = pool.stakerDeposit( address(this) );
    }
    
    /**
     * @dev Used to unwrap wnxm tokens to nxm
    **/
    function unwrapWnxm()
      external
    {
        uint256 balance = wNxm.balanceOf(address(this));
        _unwrapWnxm(balance);
    }
    
    /**
     * @dev Used to determine distributed reward amount 
     * @return reward distributed reward amount
    **/
    function currentReward()
      external
      view
    returns (uint256 reward)
    {
        reward = _currentReward();
    }
    
    /**
     * @dev Anyone may call this function to pause withdrawals for a certain amount of time.
     *      We check Nexus contracts for a recent accepted claim, then can pause to avoid further withdrawals.
     * @param _claimId The ID of the cover that has been accepted for a confirmed hack.
    **/
    function pauseWithdrawals(uint256 _claimId)
      external
    {
        IClaimsData claimsData = IClaimsData( _getClaimsData() );
        
        (/*coverId*/, uint256 status) = claimsData.getClaimStatusNumber(_claimId);
        uint256 dateUpdate = claimsData.getClaimDateUpd(_claimId);
        
        // Status must be 14 and date update must be within the past 7 days.
        if (status == 14 && block.timestamp.sub(dateUpdate) <= 7 days) {
            withdrawalsPaused = block.timestamp;
        }
    }
    
    /**
     * @dev When arNXM tokens are transferred, the referrer stakes must be adjusted on RewardManager.
     *      This is taken care of by a "_beforeTokenTransfer" function on the arNXM ERC20.
     * @param _from The user that tokens are being transferred from.
     * @param _to The user that tokens are being transferred to.
     * @param _amount The amount of tokens that are being transferred.
    **/
    function alertTransfer(address _from, address _to, uint256 _amount)
      external
    {
        require(msg.sender == address(arNxm), "Sender must be the token contract.");
        
        // address(0) means the contract or EOA has not interacted directly with arNXM Vault.
        if ( referrers[_from] != address(0) ) rewardManager.withdraw(referrers[_from], _from, _amount);
        if ( referrers[_to] != address(0) ) rewardManager.stake(referrers[_to], _to, _amount);
    }

    /**
     * @dev Withdraw any Nxm we can from the staking pool.
     * @return amount The amount of funds that are being withdrawn.
    **/
    function _withdrawNxm()
      internal
      returns (uint256 amount)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        amount = pool.stakerMaxWithdrawable( address(this) );
        pool.withdraw(amount);
    }

    /**
     * @dev Withdraw any available rewards from Nexus.
     * @return finalReward The amount of rewards to be given to users (full reward - admin reward - referral reward).
    **/
    function _getRewardsNxm()
      internal
      returns (uint256 finalReward)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        
        // Find current reward, find user reward (transfers reward to admin within this).
        uint256 fullReward = pool.stakerReward( address(this) );
        finalReward = _feeRewardsNxm(fullReward);
        
        pool.withdrawReward( address(this) );
        lastReward = finalReward;
    }
    
    /**
     * @dev Find and distribute administrator rewards.
     * @param reward Full reward given from this week.
     * @return userReward Reward amount given to users (full reward - admin reward).
    **/
    function _feeRewardsNxm(uint256 reward)
      internal
    returns (uint256 userReward)
    {
        // Find both rewards before minting any.
        uint256 adminReward = arNxmValue( reward.mul(adminPercent).div(DENOMINATOR) );
        uint256 referReward = arNxmValue( reward.mul(referPercent).div(DENOMINATOR) );

        // Mint to beneficary then this address (to then transfer to rewardManager).
        if (adminReward > 0) {
            arNxm.mint(beneficiary, adminReward);
        }
        if (referReward > 0) {
            arNxm.mint(address(this), referReward);
            rewardManager.notifyRewardAmount(referReward);
        }
        
        userReward = reward.sub(adminReward).sub(referReward);
    }

    /**
     * @dev Unstake an amount from each protocol on Nxm (takes 30 days to unstake).
     * @param _lastId The ID of the last unstake request on Nexus Mutual (needed for unstaking).
     * @return unstakeAmount The amount of each token that we're unstaking.
    **/
    function _unstakeNxm(uint256 _lastId)
      internal
    returns (uint256 unstakeAmount)
    {
        IPooledStaking pool = IPooledStaking( _getPool() );
        uint256 start = startProtocol;
        uint256 end = start + bucketSize > protocols.length ? protocols.length : start + bucketSize;

        for (uint256 i = startProtocol; i < end; i++) {
            uint256 unstakePercent = unstakePercents[i];
            address unstakeProtocol = protocols[i];
            uint256 stake = pool.stakerContractStake(address(this), unstakeProtocol);
            
            unstakeAmount = stake.mul(unstakePercent).div(DENOMINATOR);
            uint256 trueUnstakeAmount = _protocolUnstakeable(unstakeProtocol, unstakeAmount);

            // Can't unstake less than 20 NXM.
            if (trueUnstakeAmount < 20 ether) continue;

            amounts.push(trueUnstakeAmount);
            activeProtocols.push(unstakeProtocol);
        }
        
        pool.requestUnstake(activeProtocols, amounts, _lastId);
        
        delete amounts;
        delete activeProtocols;
    }

    /**
     * @dev Returns the amount we can unstake (if we can't unstake the full amount desired).
     * @param _protocol The address of the protocol we're checking.
     * @param _unstakeAmount Amount we want to unstake.
     * @return The amount of funds that can be unstaked from this protocol if not the full amount desired.
    **/
    function _protocolUnstakeable(address _protocol, uint256 _unstakeAmount) 
      internal 
      view
    returns (uint256) {
        IPooledStaking pool = IPooledStaking( _getPool() );
        uint256 stake = pool.stakerContractStake(address(this), _protocol);
        uint256 requested = pool.stakerContractPendingUnstakeTotal(address(this), _protocol);

        // Scenario in which all staked has already been requested to be unstaked.
        if (requested >= stake) {
            return 0;
        }

        uint256 available = stake - requested;

        return _unstakeAmount <= available ? _unstakeAmount : available;
    }

    function stakeNxmManual(address[] calldata _protocols, uint256[] calldata _stakeAmounts) external onlyOwner{
        _stakeNxmManual(_protocols, _stakeAmounts);
    }
    
    /**
     * @dev Stake any wNxm over the amount we need to keep in reserve (bufferPercent% more than withdrawals last week).
     * @param _protocols List of protocols to stake in (NOT list of all protocols).
     * @param _stakeAmounts List of amounts to stake in each relevant protocol--this is only ADDITIONAL stake rather than full stake.
     * @return toStake Amount of token that we will be staking.
     **/
    function _stakeNxmManual(address[] memory _protocols, uint256[] memory _stakeAmounts)
      internal
    returns (uint256 toStake)
    {
        _approveNxm(_getTokenController());
        uint256 balance = nxm.balanceOf( address(this) );

        // If we do need to restake funds...
        if (reserveAmount.add(totalPending) < balance) {
            IPooledStaking pool = IPooledStaking( _getPool() );

            // Determine how much to stake. Can't stake less than 20 NXM.
            toStake = balance.sub(reserveAmount.add(totalPending));
            if (toStake < 20 ether) return 0;

            for (uint256 i = 0; i < protocols.length; i++) {
                address protocol = protocols[i];
                uint256 stakeAmount = pool.stakerContractStake(address(this), protocol);

                for (uint256 j = 0; j < _protocols.length; j++) {
                    if (protocol == _protocols[j]){
                        stakeAmount += _stakeAmounts[j];
                        break;
                    }
                }
                if (stakeAmount == 0) continue;

                amounts.push(stakeAmount);
                activeProtocols.push(protocol);
            }

            pool.depositAndStake(toStake, activeProtocols, amounts);
            delete amounts;
            delete activeProtocols;
        }
    }

    /**
     * @dev Stake any Nxm over the amount we need to keep in reserve (bufferPercent% more than withdrawals last week).
     * @return toStake Amount of token that we will be staking. 
    **/
    function _stakeNxm()
      internal
    returns (uint256 toStake)
    {
        _approveNxm(_getTokenController());
        uint256 balance = nxm.balanceOf( address(this) );

        // If we do need to restake funds...
        if (reserveAmount.add(totalPending) < balance) {
            IPooledStaking pool = IPooledStaking( _getPool() );
            
            // Determine how much to stake. Can't stake less than 20 NXM.
            toStake = balance.sub(reserveAmount.add(totalPending));
            if (toStake < 20 ether) return 0;
                        
            uint256 startPos = startProtocol;
            for (uint256 i = 0; i < protocols.length; i++) {
                address protocol = protocols[i];

                uint256 stake = pool.stakerContractStake(address(this), protocol);
                uint256 stakeAmount = i >= startPos && i < startPos + bucketSize ? toStake.add(stake) : stake;
                if (stakeAmount == 0) continue;

                amounts.push(stakeAmount);
                activeProtocols.push(protocol);
            }

            pool.depositAndStake(toStake, activeProtocols, amounts);
            delete amounts;
            delete activeProtocols;
        }
    }

    /**
     * @dev Calculate what the current reward is. We stream this to arNxm value to avoid dumps.
     * @return reward Amount of reward currently calculated into arNxm value.
    **/
    function _currentReward()
      internal
      view
    returns (uint256 reward)
    {
        uint256 duration = rewardDuration;
        uint256 timeElapsed = block.timestamp.sub(lastRewardTimestamp);
        if(timeElapsed == 0){
            return 0;
        }
        
        // Full reward is added to the balance if it's been more than the disbursement duration.
        if (timeElapsed >= duration) {
            reward = lastReward;
        // Otherwise, disburse amounts linearly over duration.
        } else {
            // 1e18 just for a buffer.
            uint256 portion = ( duration.mul(1e18) ).div(timeElapsed);
            reward = ( lastReward.mul(1e18) ).div(portion);
        }
    }
    
    /**
     * @dev Wrap Nxm tokens to be able to be withdrawn as wNxm.
    **/
    function _wrapNxm(uint256 _amount)
      internal
    {
        IWNXM(address(wNxm)).wrap(_amount);
    }
    
    /**
     * @dev Unwrap wNxm tokens to be able to be used within the Nexus Mutual system.
     * @param _amount Amount of wNxm tokens to be unwrapped.
    **/
    function _unwrapWnxm(uint256 _amount)
      internal
    {
        IWNXM(address(wNxm)).unwrap(_amount);
    }
    
    /**
     * @dev Get current address of the Nexus staking pool.
     * @return pool Address of the Nexus staking pool contract.
    **/
    function _getPool()
      internal
      view
    returns (address pool)
    {
        pool = nxmMaster.getLatestAddress("PS");
    }
    
    /**
     * @dev Get the current NXM token controller (for NXM actions) from Nexus Mutual.
     * @return controller Address of the token controller.
    **/
    function _getTokenController()
      internal
      view
    returns(address controller)
    {
        controller = nxmMaster.getLatestAddress("TC");
    }

    /**
     * @dev Get current address of the Nexus Claims Data contract.
     * @return claimsData Address of the Nexus Claims Data contract.
    **/
    function _getClaimsData()
      internal
      view
    returns (address claimsData)
    {
        claimsData = nxmMaster.getLatestAddress("CD");
    }
    
    /**
     * @dev Approve wNxm contract to be able to transferFrom Nxm from this contract.
    **/
    function _approveNxm(address _to)
      internal
    {
        nxm.approve( _to, uint256(-1) );
    }
    
    /**
     * @dev Buy NXM direct from Nexus Mutual. Used by ExchangeManager.
     * @param _minNxm Minimum amount of NXM tokens to receive in return for the Ether.
    **/
    function buyNxmWithEther(uint256 _minNxm)
      external
      payable
    {
        require(msg.sender == 0x1337DEF157EfdeF167a81B3baB95385Ce5A14477, "Sender must be ExchangeManager.");
        INXMPool pool = INXMPool(nxmMaster.getLatestAddress("P1"));
        pool.buyNXM{value:address(this).balance}(_minNxm);
    }
    
    /**
     * @dev rescue tokens locked in contract
     * @param token address of token to withdraw
     */
    function rescueToken(address token) 
      external 
      onlyOwner 
    {
        require(token != address(nxm) && token != address(wNxm) && token != address(arNxm), "Cannot rescue NXM-based tokens");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);
    }

    /**
     * @dev Owner may change how much of the AUM should be saved in reserve each period.
     * @param _reserveAmount The amount of wNXM (in token Wei) to reserve each period.
    **/
    function changeReserveAmount(uint256 _reserveAmount)
      external
      onlyOwner
    {
        reserveAmount = _reserveAmount;
    }
    
    /**
     * @dev Owner can change the size of a bucket.
     * @param _bucketSize The new amount of protocols to stake on each week.
    **/
    function changeBucketSize(uint256 _bucketSize)
      external
      onlyOwner
    {
        // 20 is somewhat arbitrary (max plus a bit in case max expands in the future).
        require(_bucketSize <= 10 && _bucketSize <= protocols.length, "Bucket size is too large.");
        bucketSize = _bucketSize;
    }

    /**
     * @dev Owner can change checkpoint for where we want all rotations to start and the start of the upcoming rotation.
     * @param _checkpointProtocol The protocol to begin rotations on if we don't want to stake or unstake on some.
     * @param _startProtocol The protocol that the upcoming rotation will begin on.
    **/
    function changeCheckpointAndStart(uint256 _checkpointProtocol, uint256 _startProtocol)
      external
      onlyOwner
    {
        require(_checkpointProtocol < protocols.length && _startProtocol < protocols.length, "Checkpoint or start is too high.");
        checkpointProtocol = _checkpointProtocol;
        startProtocol = _startProtocol;
    }

    /**
     * @dev Owner may change the percent of insurance fees referrers receive.
     * @param _referPercent The percent of fees referrers receive. 50 == 5%.
    **/
    function changeReferPercent(uint256 _referPercent)
      external
      onlyOwner
    {
        require(_referPercent <= 500, "Cannot give referrer more than 50% of rewards.");
        referPercent = _referPercent;
    }
    
    /**
     * @dev Owner may change the withdraw fee.
     * @param _withdrawFee The fee of withdraw.
    **/
    function changeWithdrawFee(uint256 _withdrawFee)
      external
      onlyOwner
    {
        require(_withdrawFee <= DENOMINATOR, "Cannot take more than 100% of withdraw");
        withdrawFee = _withdrawFee;
    }

    /**
     * @dev Owner may change the withdraw delay.
     * @param _withdrawDelay Withdraw delay.
    **/
    function changeWithdrawDelay(uint256 _withdrawDelay)
      external
      onlyOwner
    {
        withdrawDelay = _withdrawDelay;
    }

    /**
     * @dev Change the percent of rewards that are given for administration of the contract.
     * @param _adminPercent The percent of rewards to be given for administration (10 == 1%, 1000 == 100%)
    **/
    function changeAdminPercent(uint256 _adminPercent)
      external
      onlyOwner
    {
        require(_adminPercent <= 500, "Cannot give admin more than 50% of rewards.");
        adminPercent = _adminPercent;
    }

    /**
     * @dev Owner may change protocols that we stake for and remove any.
     * @param _protocols New list of protocols to stake for.
     * @param _unstakePercents Percent to unstake for each protocol.
     * @param _removedProtocols Protocols removed from our staking that must be 100% unstaked.
    **/
    function changeProtocols(address[] calldata _protocols, uint256[] calldata _unstakePercents, address[] calldata _removedProtocols, uint256 _lastId)
      external
      onlyOwner
    {
        require(_protocols.length == _unstakePercents.length, "array length diff");
        protocols = _protocols;
        unstakePercents = _unstakePercents;

        if (_removedProtocols.length > 0) {
            IPooledStaking pool = IPooledStaking( _getPool() );
            
            for (uint256 i = 0; i < _removedProtocols.length; i++) {
                uint256 indUnstakeAmount = _protocolUnstakeable(_removedProtocols[i], uint256(~0));
                if(indUnstakeAmount == 0){
                    // skip already fully requested protocols
                    continue;
                }
                amounts.push(indUnstakeAmount);
                activeProtocols.push(_removedProtocols[i]);
            }

            pool.requestUnstake(activeProtocols, amounts, _lastId);
            
            delete amounts;
            delete activeProtocols;
        }
    }
    
    /**
     * @dev Owner may change the amount of time required to be waited between restaking.
     * @param _restakePeriod Amount of time required between restakes (starts at 6 days or 86400 * 6).
    **/
    function changeRestakePeriod(uint256 _restakePeriod)
      external
      onlyOwner
    {
        require(_restakePeriod <= 30 days, "Restake period cannot be more than 30 days.");
        restakePeriod = _restakePeriod;
    }
    
    /**
     * @dev Owner may change the amount of time it takes to distribute rewards from Nexus.
     * @param _rewardDuration The amount of time it takes to fully distribute rewards.
    **/
    function changeRewardDuration(uint256 _rewardDuration)
      external
      onlyOwner
    {
        require(_rewardDuration <= 30 days, "Reward duration cannot be more than 30 days.");
        rewardDuration = _rewardDuration;
    }
    
    /**
     * @dev Owner may change the amount of time that withdrawals are paused after a hack is confirmed.
     * @param _pauseDuration The new amount of time that withdrawals will be paused.
    **/
    function changePauseDuration(uint256 _pauseDuration)
      external
      onlyOwner
    {
        require(_pauseDuration <= 30 days, "Pause duration cannot be more than 30 days.");
        pauseDuration = _pauseDuration;
    }
    
    /**
     * @dev Change beneficiary of the administration funds.
     * @param _newBeneficiary Address of the new beneficiary to receive funds.
    **/
    function changeBeneficiary(address _newBeneficiary) 
      external 
      onlyOwner 
    {
        beneficiary = _newBeneficiary;
    }
    
    //// Update addition. Proxy paranoia brought it down here. ////
    
    uint256 public lastRewardTimestamp;

    //// Second update additions. ////

    // Protocol that the next restaking will begin on.
    uint256 public startProtocol;

    // Checkpoint in case we want to cut off certain buckets (where we begin the rotations).
    // To bar protocols from being staked/unstaked, move them to before checkpointProtocol.
    uint256 public checkpointProtocol;

    // Number of protocols to stake each time.
    uint256 public bucketSize;
    
    // Individual percent to unstake.
    uint256[] public unstakePercents;
    
    // Last time an EOA has called this contract.
    mapping (address => uint256) public lastCall;

    ///// Third update additions. /////

    // Withdraw fee to withdraw immediately.
    uint256 public withdrawFee;

    // Delay to withdraw
    uint256 public withdrawDelay;

    // Total amount of withdrawals pending.
    uint256 public totalPending;

    mapping (address => WithdrawalRequest) public withdrawals;

}