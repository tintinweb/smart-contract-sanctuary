/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.6.12;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public _feeWallet = 0x753ed7F33F8F4cA6cdaB85A47b273c554c430628;
    uint256 public _feeRate = 0;
    uint256 public _baseRate = 100;
    IERC20 public lpt;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpt.safeTransferFrom(msg.sender, address(this), amount);
    }
    
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uint256 fee = amount.mul(_feeRate).div(_baseRate);
        if(fee>0){
            lpt.safeTransfer(_feeWallet, fee);
        }
        uint256 leftAmount = amount.sub(fee);
        if(leftAmount>0){
            lpt.safeTransfer(msg.sender, leftAmount);
        }
    }
}

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

abstract contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            'Caller is not reward distribution'
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        virtual
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

contract AHABaseFarm is LPTokenWrapper, Ownable, IRewardDistributionRecipient {
    uint256 public constant DURATION = 180 days;
    address payable public  aha_address = 0x6558290be74c2b1B5a2f6E4bf7f1382d78B509eA;
    IERC20 public dynamicTracker = IERC20(aha_address);
    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public initreward = 0 * 180 * 10**18;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    uint256 public withdrawinterval = 7 days;
    uint256 public whitelistDays = 7 days;
    mapping(address => uint256) public t1Date;
    mapping(address => uint256) public t2Date;
    mapping(address => uint256) public t3Date;
    mapping(address => uint256) public lastStakeDate;
    uint256 public t1amount;
    uint256 public t2amount;
    uint256 public t3amount;
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    address payable internal creator;

    constructor(
        address lptoken_,
        uint256 starttime_
    ) public {
        lpt = IERC20(lptoken_);
        creator = msg.sender;
        starttime = starttime_;
        periodFinish = starttime.add(DURATION);
    }

    modifier checkStart() {
        require(
            block.timestamp >= starttime,
            'not started'
        );
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
    
    function setlastStakeDate(uint256 _lastStakeDate,address _addr) external onlyOwner{
        lastStakeDate[_addr] = _lastStakeDate;
    }
    
    function setT1Date(uint256 _t1Date,address _addr) external onlyOwner{
        t1Date[_addr] = _t1Date;
    }
    
    function setT2Date(uint256 _t2Date,address _addr) external onlyOwner{
        t2Date[_addr] = _t2Date;
    }
    

    function setT3Date(uint256 _t3Date,address _addr) external onlyOwner{
        t3Date[_addr] = _t3Date;
    }
    
    
    function setT1amount(uint256 _t1amount) external onlyOwner{
        t1amount= _t1amount;
    }
    
    function setT2amount(uint256 _t2amount) external onlyOwner{
        t2amount= _t2amount;
    }
    
    function setT3amount(uint256 _t3amount) external onlyOwner{
        t3amount= _t3amount;
    }
    
    function setwithdrawinterval(uint256 _withdrawinterval) external onlyOwner{
        withdrawinterval = _withdrawinterval;
    }
    
    function setWhitelistDays(uint256 _whitelistDays) external onlyOwner{
        whitelistDays = _whitelistDays;
    }
    
    function setRewardStop() external onlyOwner{
        rewardRate = 0;
    }
    
    function setFee(uint256 feerate) external onlyOwner{
        _feeRate = feerate;
    }
    function setRewardStart() external onlyOwner{
        rewardRate = initreward.div(DURATION);
    }
    
    function setstarttime(uint256 _startTime) external onlyOwner {
        starttime = _startTime;
    }
    function setAhaaddr(address payable _aha_address) external onlyOwner {
        aha_address = _aha_address;
    }
    
    function setinitreward(uint256 _initreward) external onlyOwner {
        initreward = _initreward;
    }
    
    function setperiodFinish(uint256 _periodFinish) external onlyOwner {
        periodFinish = _periodFinish;
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
                    .mul(1e30)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e30)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'Cannot stake 0');
        super.stake(amount);
        emit Staked(msg.sender, amount);
        if(balanceOf(msg.sender) >=t3amount && balanceOf(msg.sender) < t2amount){
            t3Date[msg.sender] = block.timestamp;
        }
        else if (balanceOf(msg.sender) >=t2amount && balanceOf(msg.sender) < t1amount){
            t2Date[msg.sender] = block.timestamp;
        }
        else if (balanceOf(msg.sender) >=t1amount){
            t1Date[msg.sender] = block.timestamp;
        }
        lastStakeDate[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {   
        require(lastStakeDate[msg.sender] + withdrawinterval < block.timestamp, 'cant withdraw');
        require(amount > 0, 'Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        if(balanceOf(msg.sender) < t1amount && balanceOf(msg.sender) >= t2amount){
            t1Date[msg.sender] = 0;
        }        
        else if(balanceOf(msg.sender) < t2amount && balanceOf(msg.sender) >= t3amount){
            t2Date[msg.sender] = 0;
        }
        else if(balanceOf(msg.sender) < t3amount){
            t3Date[msg.sender] = 0;
        }
    }

    function isWhitelist(address _addr)
        public
        view
        returns(uint256)
    {   
        if(t1Date[_addr] + whitelistDays < block.timestamp  && t1Date[_addr]!=0){
            return 1;
        }
        else if(t2Date[_addr] + whitelistDays < block.timestamp && t2Date[_addr]!=0){
            return 2;
        }
        else if(t3Date[_addr] + whitelistDays < block.timestamp && t3Date[_addr]!=0){
            return 3;
        }
        else{
            return 0;
        }
        
    }



    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            dynamicTracker.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
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

    // Fallback rescue

    receive() external payable{
        creator.transfer(msg.value);
    }
}