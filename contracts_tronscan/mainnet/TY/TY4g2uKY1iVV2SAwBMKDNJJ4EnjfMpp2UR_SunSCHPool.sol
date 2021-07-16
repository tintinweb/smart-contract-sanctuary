//SourceUnit: SunSCHPool.sol

pragma solidity ^0.5.8;

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

library SafeTRC20 {
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        if (address(token) == USDTAddr) {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success, "SafeTRC20: low-level call failed");
        } else {
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeTRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}

contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
    external
    onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

contract SCHTokenWrapper {
    using SafeMath for uint256;
    using SafeTRC20 for ITRC20;
    ITRC20 public tokenAddr = ITRC20(0x410c40ac790d482d486811471ff20f9ddf78ff1455);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        tokenAddr.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        tokenAddr.safeTransfer(msg.sender, amount);
    }

    function withdrawTo(address to, uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        tokenAddr.safeTransfer(to, amount);
    }

    function _stakeTo(address to, uint256 amount) internal returns (bool){
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        return true;
    }
}

contract ISaleChainCrowdsale{
    function parent(address account) public view returns (address);
}

/**
  * @title SunSCHPool
  * @dev SunSCHPool designed for sale sun token to sch token holders.
  * Source: SunSUNV3Pool
  */
contract SunSCHPool is SCHTokenWrapper, IRewardDistributionRecipient {
    // sunToken
    ITRC20 public sunToken = ITRC20(0x6b5151320359Ec18b08607c70a3b7439Af626aa3);
    
    ISaleChainCrowdsale public mainChain = ISaleChainCrowdsale(0x411e772d4ba5a995bb58c149d89b2ae7f66b414305);
    uint256 public sunRate;
    address payable constant public MARKETING_WALLET = address(0x418476322b439f85eb8e6064cd113c484352b085a7);
    
    uint256 public constant DURATION = 259200; // 3 days

    uint256 public starttime = 1602700200; // Wednesday, October 14, 2020 6:30:00 PM UTC
    uint256 public starttimeSale = 1603132200; // Monday, October 19, 2020 6:30:00 PM UTC
    uint256 public endtimeSale = 1603218600; // Tuesday, October 20, 2020 6:30:00 PM UTC
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public oldPool;
    uint256 public weiRaised;
    uint256 public minSaleAmount;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public referralEarn;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event ReferralCommissionPaid(address indexed user, uint256 amount);
    event Rescue(address indexed dst, uint sad);
    event RescueToken(address indexed dst, address indexed token, uint sad);

    constructor(address _pool) public{
        rewardDistribution = _msgSender();
        oldPool = _pool;
    }

    modifier checkStakePeriod() {
        require(block.timestamp >= starttime && block.timestamp <= periodFinish, "Not in stake period");
        _;
    }

    modifier checkEnd() {
        require(block.timestamp >= periodFinish, "Not end");
        _;
    }

    modifier checkSalePeriod() {
        require(block.timestamp >= starttimeSale && block.timestamp <= endtimeSale, "Not in sale period");
        _;
    }

    modifier onlyOldPool(){
        require(msg.sender == oldPool, "Not oldPool");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function setSaleParam(uint256 min, uint256 rate) public onlyOwner {
        minSaleAmount = min;
        sunRate = rate;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    function statAccount(address account) public view returns (uint256, uint256, uint256) {
        return
        (earned(account), balanceOf(account), referralEarn[account]);
    }

    // stake visibility is public as overriding SCHTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) checkStakePeriod {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkEnd {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= balanceOf(msg.sender), "Cannot withdraw exceed the balance");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function getReward() public payable checkSalePeriod {
        if (balanceOf(msg.sender) > 0){
            withdraw(balanceOf(msg.sender));
        }
        uint256 trueReward = rewards[msg.sender];
        uint256 weiAmount = msg.value;
        require(weiAmount >= minSaleAmount, "Contributions must be at least minSaleAmount during the sale");
        uint256 tokenAmount = weiAmount.div(sunRate).mul(1000000000000);
        require(tokenAmount <= trueReward, "Cannot sale token exceed the reward");
        rewards[msg.sender] = trueReward.sub(tokenAmount);
        weiRaised = weiRaised.add(weiAmount);      
        sunToken.safeTransfer(msg.sender, tokenAmount);
        address payable refWallet = address(uint160(mainChain.parent(msg.sender)));
        if (refWallet != address(0)){
            uint256 refAmount = weiAmount.mul(5).div(100);
            weiAmount = weiAmount.sub(refAmount);
            referralEarn[refWallet] = referralEarn[refWallet].add(refAmount);
        }
        MARKETING_WALLET.transfer(weiAmount);
        emit RewardPaid(msg.sender, tokenAmount);
    }

    function notifyRewardAmount(uint256 reward)
    external
    onlyRewardDistribution
    updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }

    /**
    * @dev rescue simple transfered TRX.
    */
    function rescue(address payable to_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "Must not 0");
        require(amount_ > 0, "Must gt 0");

        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }

    /**
     * @dev rescue simple transfered unrelated token.
     */
    function rescue(address to_, ITRC20 token_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "Must not 0");
        require(amount_ > 0, "Must gt 0");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }

    function stakeTo(address user, uint256 amount) public onlyOldPool updateReward(user) returns (bool){
        require(amount > 0, "Cannot stake 0");
        require(_stakeTo(user, amount), "Stake to failed");
        emit Staked(user, amount);
        return true;
    }

    function migrate(address nextPool) public returns (bool){
        require(balanceOf(msg.sender) > 0, "Must gt 0");
        uint256 userBalance = balanceOf(msg.sender);

        require(SunSCHPool(nextPool).stakeTo(msg.sender, userBalance), "StakeTo failed");
        super.withdrawTo(nextPool, userBalance);

        return true;
    }

    function getReferralCommission() public {        
        uint256 amount = referralEarn[msg.sender];
        require(amount > 0, "Your referral commission balance is zero!");
        referralEarn[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit ReferralCommissionPaid(msg.sender, amount);
    }
}