//SourceUnit: BTCReward.sol


pragma solidity ^0.5.0;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
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
        // Solidity only automatically asserts when dividing by 0
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

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {

    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
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

interface IRel{
    function stakeR(address _ply,uint256 _amount,address _plyParent) external ;
    function withdrawR(address _ply,uint256 _amount) external;
    function checkParent(address _ply) external view returns(bool,address);
}

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

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

contract TokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    IERC20 public y = IERC20(0x84716914C0fDf7110A44030d04D0C4923504D9CC); 
    //IERC20 public y = IERC20(0x3A3e639A7970C5c740069F50AB6eaB1502b2539B); // test
 
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        y.transferFrom(msg.sender, address(this), amount);
    }

    function _withdraw(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        y.transfer(msg.sender,amount);
    }
}

contract BTCReward is TokenWrapper, IRewardDistributionRecipient {
    IERC20 public xCoin = IERC20(0x41A97A5EB5F398C79FB666DA87677C8E82EBCCB919);
    address public relAddr ;
    uint256 public  DURATION = 50 days;
    uint256 public TIEM5 = 432000;
    uint256 public initreward = 25000*1e18;
    uint256 public totalReward = 25000*1e18;
    
    
    uint256 public starttime ;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public waitClearn;
    mapping(address => uint256) public InviteReward;
    mapping(address => uint256) public plyGetRewardTime;
    mapping(address => uint256) public totalInviteReward;
    
    bool public endCalcReward;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    constructor(uint256 _startTime,address _rAddr) public{
        starttime = _startTime;
        periodFinish = starttime.add(DURATION);
        rewardRate = initreward.div(DURATION);
        relAddr = _rAddr;
        rewardDistribution = msg.sender;
    }
    
    function setRelAddr(address _relAddr) public onlyRewardDistribution{
        relAddr = _relAddr;
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
    
    function earnedInfo(address account) public view returns(uint256 ,uint256){
        uint256 reward = earned(account);
        uint256 timeNow = periodFinish;
            if(now < periodFinish){
                timeNow = now;
            }
        uint256 timelen = timeNow.sub(plyGetRewardTime[account]);
        uint256 fiveAmount;
        if(timelen >TIEM5*2){
            reward = reward.mul(110).div(100);
            fiveAmount = reward.mul(10).div(100);
        }else if(timelen > TIEM5){
            reward = reward.mul(105).div(100);
            fiveAmount = reward.mul(5).div(100);
        }
        if(totalReward <= reward){
            reward = totalReward;
        }
        
        bool result;
        address parent;
        uint256 parentAmount1;
        uint256 parentAmount2;
        uint256 selfAmount;
        bool result2;
        address parent2;
        (result,parent) = IRel(relAddr).checkParent(account);
        if(result){
            parentAmount1 = reward.mul(5).div(100);
                
            (result2,parent2) = IRel(relAddr).checkParent(parent);
            if(result2){
                parentAmount2 = reward.mul(3).div(100);
            }
            selfAmount = reward.sub(parentAmount1.add(parentAmount2));
                
        }else{
                selfAmount = reward;
        }
        return(selfAmount,fiveAmount);
    }
    
    function poolInfo() public view returns(uint256,uint256){
        return(super.totalSupply(),totalReward);
    }
    
    function stake(uint256 amount,address _plyParent) public updateReward(msg.sender)  checkStart{ 
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        IRel(relAddr).stakeR(msg.sender,amount,_plyParent);
        if(plyGetRewardTime[msg.sender] ==0){
            plyGetRewardTime[msg.sender] = now;
        }
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender)  checkStart{
        require(amount > 0, "Cannot withdraw 0");
        super._withdraw(amount);
        IRel(relAddr).withdrawR(msg.sender,amount);
        emit Withdrawn(msg.sender, amount);
    }
    function withdrawPIW() public checkStart {
         require(now >= periodFinish,"not end");
         uint256 balanceAmount = waitClearn[msg.sender];
         if(balanceAmount > 0){
             waitClearn[msg.sender] = 0;
             xCoin.safeTransfer(msg.sender,balanceAmount);
         }
    }
    function exit() external {
        //require(now <= periodFinish,"not end this exit");
        withdraw(balanceOf(msg.sender));
        getReward();
        withdrawPIW();
    }

    function getReward() public updateReward(msg.sender)  checkStart{
        if(endCalcReward && totalReward == 0){
            return;
        }
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 timeNow = periodFinish;
            if(now < periodFinish){
                timeNow = now;
            }
            uint256 timelen = timeNow.sub(plyGetRewardTime[msg.sender]);
            if(timelen >TIEM5*2){
                reward = reward.mul(110).div(100);
            }else if(timelen > TIEM5){
                reward = reward.mul(105).div(100);
            }
            if(totalReward <= reward){
                reward = totalReward;
            }
            
            totalReward = totalReward.sub(reward);
            bool result;
            address parent;
            uint256 parentAmount1;
            uint256 parentAmount2;
            uint256 selfAmount;
            bool result2;
            address parent2;
            (result,parent) = IRel(relAddr).checkParent(msg.sender);
            if(result){
                parentAmount1 = reward.mul(5).div(100);
                
                (result2,parent2) = IRel(relAddr).checkParent(parent);
                if(result2){
                    parentAmount2 = reward.mul(3).div(100);
                }
                selfAmount = reward.sub(parentAmount1.add(parentAmount2));
                
            }else{
                selfAmount = reward;
            }
            waitClearn[msg.sender] = waitClearn[msg.sender].add(selfAmount);
            waitClearn[msg.sender] = waitClearn[msg.sender].add(InviteReward[msg.sender]);
            InviteReward[msg.sender] = 0;
            InviteReward[parent] = InviteReward[parent].add(parentAmount1);
            InviteReward[parent2] = InviteReward[parent2].add(parentAmount2);
            totalInviteReward[parent] = totalInviteReward[parent].add(parentAmount1);
            totalInviteReward[parent2] = totalInviteReward[parent2].add(parentAmount2);
            
            emit RewardPaid(msg.sender, reward);
        }
        plyGetRewardTime[msg.sender] = now;
    }
    
    function setRewardStop() public onlyRewardDistribution{
        endCalcReward = true;
    }
   
    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        rewardRate = reward.div(DURATION);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}