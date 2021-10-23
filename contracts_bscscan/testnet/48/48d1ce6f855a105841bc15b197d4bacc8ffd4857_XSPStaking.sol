/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity ^0.4.24;


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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

    function mint(address to, uint256 amount) external;

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



pragma solidity ^0.4.24;

interface IRepF {
    function reputations(address staker) external view returns (uint256);

    function stakers(uint256 index) external view returns (address);

    function getReputation(address staker) external view returns (uint256);

    function isStaker(address staker) external view returns (bool);

    function getStakerIndex(address staker) external view returns (bool, uint256);
}



pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    /// @notice
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: sender not owner');
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}


pragma solidity ^0.4.24;

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param _addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}


pragma solidity ^0.4.24;

////import '../AddressUtils.sol';
////import './SafeMath.sol';
////import './Ownable.sol';
////import './IREF.sol';
////import './IERC20.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _value
    ) internal {
        require(_token.transfer(_to, _value));
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_token.transferFrom(_from, _to, _value));
    }

    function safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _value
    ) internal {
        require(_token.approve(_spender, _value));
    }
}

contract XSPStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AddressUtils for address;

    uint256 private ONE_DAY = 86400;
    uint256 private ONE_YEAR_TO_DAY = 365;

    struct Stake {
        address stakerHolder;
        uint256 stakedAmount;
        bool staked;
        bool exists;
        bool unstaked;
        uint256 stakedTime;
        uint256 unstakedTime;
        uint256 totalRedeemed;
        uint256 lastRedeemedAt;
        uint256 balance; // ? required
    }

    mapping(address => Stake) public stakes;
    address[] public stakeHolders;

    IERC20 public token; // initialized in constructor
    IRepF public iRepF;
    uint256 public reputationThreshold;
    uint256 public hostingCompensation = 750 * 12 * 10**18;
    uint256 public totalStaked;
    uint256 public minStakeAmount = 1000000 * 10**18;
    uint256 public maxStakeAmount = 10000000 * 10**18;
    uint256 public coolOff = ONE_DAY * 1;
    uint256 public interest;
    uint256 public totalRedeemed = 0;
    uint256 public redeemInterval = 1 * ONE_DAY;
    uint256 public maxEarningsCap = 7000000 * 10**18;

    uint256 public interestPrecision = 100;

    event Staked(address staker, uint256 amount);

    event Unstaked(address staker, uint256 amount);
    event WithdrewStake(address staker, uint256 principal, uint256 earnings);
    event ClaimedRewards(address staker, uint256 amount);
    event MissedRewards(address staker, uint256 threshold, uint256 reputation);
    event MaxEarningsCapReached(address staker, uint256 earnings, uint256 cap);

    // Parameter Change Events
    event MinStakeAmountChanged(uint256 prevValue, uint256 newValue);
    event MaxStakeAmountChanged(uint256 prevValue, uint256 newValue);
    event RateChanged(uint256 prevValue, uint256 newValue);
    event CoolOffChanged(uint256 prevValue, uint256 newValue);
    event RedeemIntervalChanged(uint256 prevValue, uint256 newValue);
    event ReputationFeedChanged(address prevValue, address newValue);
    event ReputationThresholdChanged(uint256 prevValue, uint256 newValue);
    event HostingCompensationChanged(uint256 prevValue, uint256 newValue);
    event MaxEarningCapChanged(uint256 prevValue, uint256 newValue);
    event InterestPrecisionChanged(uint256 prevValue, uint256 newValue);

    event WithdrewTokens(address beneficiary, uint256 amount);
    event WithdrewXdc(address beneficiary, uint256 amount);

    modifier whenStaked() {
        require(stakes[msg.sender].staked == true, 'XSP: not staked');
        _;
    }

    modifier whenNotStaked() {
        require(stakes[msg.sender].staked == false, 'XSP: already staked');
        _;
    }

    modifier whenNotUnStaked() {
        require(stakes[msg.sender].unstaked == false, 'XSP: in unstake period');
        _;
    }

    modifier whenUnStaked() {
        require(stakes[msg.sender].unstaked == true, 'XSP: not un-staked');
        _;
    }

    modifier canRedeemDrip(address staker) {
        require(stakes[staker].exists, 'XSP: staker does not exist');
        require(
            stakes[staker].lastRedeemedAt + redeemInterval <= block.timestamp,
            'XSP: cannot claim drip yet'
        );
        _;
    }

    function canWithdrawStake(address staker) public view returns (bool) {
        require(stakes[staker].exists, 'XSP: stakeholder does not exists');
        require(stakes[staker].staked == false, 'XSP: stakeholder still has stake');
        require(stakes[staker].unstaked == true, 'XSP: not in unstake period');
        uint256 unstakeTenure = block.timestamp - stakes[staker].unstakedTime;
        return coolOff < unstakeTenure;
    }

    constructor(
        IERC20 token_,
        uint256 interest_,
        IRepF reputationContract_
    ) public {
        token = token_;
        interest = interest_;
        iRepF = reputationContract_;
    }

    function stake(uint256 amount_) public whenNotStaked whenNotUnStaked {
        require(amount_ >= minStakeAmount, 'XSP: invalid amount');
        require(amount_ <= maxStakeAmount, 'XSP: invalid amount');
        require(iRepF.isStaker(msg.sender), 'XSP: sender not staker');

        stakes[msg.sender].staked = true;
        if (stakes[msg.sender].exists == false) {
            stakes[msg.sender].exists = true;
            stakes[msg.sender].stakerHolder = msg.sender;
        }

        stakeHolders.push(msg.sender);
        stakes[msg.sender].stakedTime = block.timestamp;
        stakes[msg.sender].totalRedeemed = 0;
        stakes[msg.sender].lastRedeemedAt = block.timestamp;
        stakes[msg.sender].stakedAmount = amount_;
        stakes[msg.sender].balance = 0;

        totalStaked = totalStaked.add(amount_);

        token.safeTransferFrom(msg.sender, address(this), amount_);

        emit Staked(msg.sender, amount_);
    }

    function unstake() public whenStaked whenNotUnStaked {
        uint256 leftoverBalance = _earned(msg.sender);
        stakes[msg.sender].unstakedTime = block.timestamp;
        stakes[msg.sender].staked = false;
        stakes[msg.sender].balance = leftoverBalance;
        stakes[msg.sender].unstaked = true;

        totalStaked = totalStaked.sub(stakes[msg.sender].stakedAmount);
        (bool exists, uint256 stakerIndex) = getStakerIndex(msg.sender);
        require(exists, 'XSP: staker does not exist');
        stakeHolders[stakerIndex] = stakeHolders[stakeHolders.length - 1];
        delete stakeHolders[stakeHolders.length - 1];
        stakeHolders.length--;

        emit Unstaked(msg.sender, stakes[msg.sender].stakedAmount);
    }

    function _earned(address beneficiary_) internal view returns (uint256 earned) {
        if (stakes[beneficiary_].staked == false) return 0;
        uint256 tenure = (block.timestamp - stakes[beneficiary_].lastRedeemedAt);
        uint256 earnedStake =
            tenure
                .div(ONE_DAY)
                .mul(stakes[beneficiary_].stakedAmount)
                .mul(interest.div(interestPrecision))
                .div(100)
                .div(365);
        uint256 earnedHost = tenure.div(ONE_DAY).mul(hostingCompensation).div(365);
        earned = earnedStake.add(earnedHost);
    }

    function earned(address staker) public view returns (uint256 earnings) {
        earnings = _earned(staker);
    }

    function claimEarned(address claimAddress) public canRedeemDrip(claimAddress) {
        require(stakes[claimAddress].staked == true, 'XSP: not staked');

        uint256 claimerReputation = iRepF.getReputation(claimAddress);
        if (claimerReputation < reputationThreshold) {
            // mark as redeemed and exit early
            stakes[claimAddress].lastRedeemedAt = block.timestamp;
            emit MissedRewards(claimAddress, reputationThreshold, claimerReputation);
            return;
        }

        // update the redeemdate even if earnings are 0
        uint256 earnings = _earned(claimAddress);

        if (earnings >= maxEarningsCap) {
            emit MaxEarningsCapReached(claimAddress, earnings, maxEarningsCap);
            earnings = maxEarningsCap;
        }

        if (earnings > 0) {
            token.mint(claimAddress, earnings);
        }

        stakes[claimAddress].totalRedeemed += earnings;
        stakes[claimAddress].lastRedeemedAt = block.timestamp;

        totalRedeemed += earnings;

        emit ClaimedRewards(claimAddress, earnings);
    }

    function withdrawStake() public whenUnStaked {
        require(canWithdrawStake(msg.sender), 'XSP: cannot withdraw yet');
        uint256 withdrawAmount = stakes[msg.sender].stakedAmount;
        uint256 leftoverBalance = stakes[msg.sender].balance;
        token.transfer(msg.sender, withdrawAmount);
        if (leftoverBalance > 0) token.mint(msg.sender, leftoverBalance);
        stakes[msg.sender].stakedAmount = 0;
        stakes[msg.sender].balance = 0;
        stakes[msg.sender].unstaked = false;
        stakes[msg.sender].totalRedeemed += leftoverBalance;
        stakes[msg.sender].lastRedeemedAt = block.timestamp;
        totalRedeemed += leftoverBalance;
        emit WithdrewStake(msg.sender, withdrawAmount, leftoverBalance);
    }

    function nextDripAt(address claimerAddress) public view returns (uint256) {
        require(stakes[claimerAddress].staked == true, 'XSP: address has not staked');
        return stakes[claimerAddress].lastRedeemedAt + redeemInterval;
    }

    function canWithdrawStakeIn(address staker) public view returns (uint256) {
        require(stakes[staker].exists, 'XSP: stakeholder does not exists');
        require(stakes[staker].staked == false, 'XSP: stakeholder still has stake');
        uint256 unstakeTenure = block.timestamp - stakes[staker].unstakedTime;
        if (coolOff < unstakeTenure) return 0;
        return coolOff - unstakeTenure;
    }

    function thresholdMet(address staker) public view returns (bool) {
        return iRepF.getReputation(staker) >= reputationThreshold;
    }

    function getAllStakeHolder() public view returns (address[]) {
        return stakeHolders;
    }

    function getStakerIndex(address staker) public view returns (bool, uint256) {
        for (uint256 i = 0; i < stakeHolders.length; i++) {
            if (stakeHolders[i] == staker) return (true, i);
        }
        return (false, 0);
    }

    /**
    
    Owner Functionality Starts

     */

    function setMinStakeAmount(uint256 minStakeAmount_) public onlyOwner {
        require(minStakeAmount_ > 0, 'XSP: minimum stake amount should be greater than 0');
        uint256 prevValue = minStakeAmount;
        minStakeAmount = minStakeAmount_;
        emit MinStakeAmountChanged(prevValue, minStakeAmount);
    }

    function setMaxStakeAmount(uint256 maxStakeAmount_) public onlyOwner {
        require(maxStakeAmount_ > 0, 'XSP: maximum stake amount should be greater than 0');
        uint256 prevValue = maxStakeAmount;
        maxStakeAmount = maxStakeAmount_;
        emit MaxStakeAmountChanged(prevValue, maxStakeAmount);
    }

    function setRate(uint256 interest_) public onlyOwner {
        uint256 prevValue = interest;
        interest = interest_;
        emit RateChanged(prevValue, interest);
    }

    function setCoolOff(uint256 coolOff_) public onlyOwner {
        uint256 prevValue = coolOff;
        coolOff = coolOff_;
        emit CoolOffChanged(prevValue, coolOff);
    }

    function setRedeemInterval(uint256 redeemInterval_) public onlyOwner {
        uint256 prevValue = redeemInterval;
        redeemInterval = redeemInterval_;
        emit RedeemIntervalChanged(prevValue, redeemInterval);
    }

    function setIRepF(IRepF repAddr_) public onlyOwner {
        address prevValue = address(iRepF);
        iRepF = repAddr_;
        emit ReputationFeedChanged(prevValue, address(iRepF));
    }

    function setReputationThreshold(uint256 threshold) public onlyOwner {
        uint256 prevValue = reputationThreshold;
        reputationThreshold = threshold;
        emit ReputationThresholdChanged(prevValue, reputationThreshold);
    }

    function setHostingCompensation(uint256 hostingCompensation_) public onlyOwner {
        uint256 prevValue = hostingCompensation;
        hostingCompensation = hostingCompensation_;
        emit HostingCompensationChanged(prevValue, hostingCompensation);
    }

    function setMaxEarningCap(uint256 maxEarningCap_) public onlyOwner {
        uint256 prevValue = maxEarningCap_;
        maxEarningsCap = maxEarningCap_;
        emit MaxEarningCapChanged(prevValue, maxEarningsCap);
    }

    function setInterestPrecision(uint256 interestPrecision_) public onlyOwner {
        require(interestPrecision_ > 0, 'XSP: precision cannot be 0');
        uint256 prevValue = interestPrecision;
        interestPrecision = interestPrecision_;
        emit InterestPrecisionChanged(prevValue, interestPrecision);
    }

    function withdrawTokens(address beneficiary_, uint256 amount_) public onlyOwner {
        require(amount_ > 0, 'XSP: token amount has to be greater than 0');
        token.safeTransfer(beneficiary_, amount_);
        emit WithdrewTokens(beneficiary_, amount_);
    }

    function withdrawXdc(address beneficiary_, uint256 amount_) public onlyOwner {
        require(amount_ > 0, 'XSP: xdc amount has to be greater than 0');
        beneficiary_.transfer(amount_);
        emit WithdrewXdc(beneficiary_, amount_);
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}