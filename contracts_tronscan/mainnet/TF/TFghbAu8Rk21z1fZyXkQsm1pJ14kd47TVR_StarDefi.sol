//SourceUnit: StarDefi.sol

pragma solidity ^0.5.0;

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    function burn(address account, uint amount) external;
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

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public pledge; // Stake Token address

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 _pledge) public {
        pledge = _pledge;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        pledge.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        pledge.safeTransfer(msg.sender, amount);
    }
}

contract StarDefi is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public mine;
    
    uint256 public constant DURATION = 60 days;

    uint256 public starttime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public validAmount;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => address) public referralRelationships; // store referall relationship: referree > referrer
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) private _teamCount;
    mapping(address => uint256) public directCount;
    mapping(address => uint256) private _teamAmount;

    uint256[] awardLevel = [50,20,10,4,4,4,4,4];

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

    constructor(IERC20 _pledge, IERC20 _mine, uint _starttime,uint256 _validAmount) public LPTokenWrapper(_pledge) {
        starttime = _starttime;
        mine = _mine;
        validAmount = _validAmount * 1e6;
    }

    function teamCount(address _addr) public view returns(uint256) {
        return _teamCount[_addr].add(1);
    }

    function teamAmount(address _addr) public view returns(uint256) {
        return _teamAmount[_addr].add(balanceOf(_addr));
    }

    function _updateReferralRelationship(address user, address referrer, uint256 amount,uint beforeAmount) internal {
        if (referrer == user) { // referrer cannot be user himself/herself
          return;
        }

        if (referrer == address(0)) { // Cannot be address 0
          return;
        }

        if(referralRelationships[user] == address(0)) {
            referralRelationships[user] = referrer;
        } else {
            referrer = referralRelationships[user];
        }
        // teamAmount[user] = teamAmount[user].add(amount);
        address parent = referrer;
        for (uint256 i = 0; i < 8; i++) {
            if(parent != address(0)) {
                _teamAmount[parent] = _teamAmount[parent].add(amount);
                parent = referralRelationships[parent];
            } else {
                break;
            }
        }

        if(balanceOf(user) >= validAmount && beforeAmount < validAmount) {
            directCount[referrer] = directCount[referrer].add(1);
            parent = referrer;
            for (uint256 i = 0; i < 8; i++) {
                if(parent != address(0)) {
                    _teamCount[parent] = _teamCount[parent].add(1);
                    parent = referralRelationships[parent];
                } else {
                    break;
                }
            }
        }
    }

    function _reducePerentPerformance(address user,uint256 amount) internal {
        address parent = referralRelationships[user];
        for (uint256 i = 0; i < 8; i++) {
            if(parent != address(0)) {
                _teamAmount[parent] = _teamAmount[parent].sub(amount);
                parent = referralRelationships[parent];
            } else {
                break;
            }
        }
    }

    function getReferrer(address account) public view returns (address) {
        return referralRelationships[account];
    }

    function getReferralRewards(address account) public view returns (uint256) {
        return referralRewards[account];
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

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function deposit(uint256 amount, address referrer) public updateReward(msg.sender)  checkStart{ 
        require(amount > 0, "Cannot stake 0");
        require(block.timestamp < periodFinish, "mint finish");
        uint beforeAmount = balanceOf(msg.sender);
        super.stake(amount);
        _updateReferralRelationship(msg.sender, referrer, amount,beforeAmount); //only update referrer when staking
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender)  checkStart{
        require(amount > 0, "Cannot withdraw 0");
        uint256 beforeBalance = balanceOf(msg.sender);
        super.withdraw(amount);
        
        if(beforeBalance >= validAmount && balanceOf(msg.sender) < validAmount) {
            address parent = referralRelationships[msg.sender];
            directCount[parent] = directCount[parent].sub(1);
            for (uint256 i = 0; i < 8; i++) {
                if(parent != address(0)) {
                    _teamCount[parent] = _teamCount[parent].sub(1);
                    parent = referralRelationships[parent];
                } else {
                    break;
                }
            }
        }
        _reducePerentPerformance(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) checkStart{
        
        require(block.timestamp > periodFinish, "mint not finish");
        
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
            safeMineTransfer(msg.sender, reward);

            address referrer = referralRelationships[msg.sender];
            for(uint i = 0; i < 8; i++) {
                if(referrer != address(0)) {
                    if(directCount[referrer] > i && balanceOf(referrer) >= validAmount) {
                        uint256 referrerFee = reward.mul(awardLevel[i]).div(100);
                        referralRewards[referrer] = referralRewards[referrer].add(referrerFee);
                        safeMineTransfer(referrer, referrerFee);
                    }
                    referrer = referralRelationships[referrer];
                } else {
                    break;
                }
            }
            emit RewardPaid(msg.sender, reward);
        }
    }

    function safeMineTransfer(address _to, uint256 _amount) internal {
        uint256 mineBalance = mine.balanceOf(address(this));
        if(_amount > mineBalance) {
            mine.safeTransfer(_to, mineBalance);
        } else {
            mine.safeTransfer(_to, _amount);
        }
        
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
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
            
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
        
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
            
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
        
        }
        
        emit RewardAdded(reward);
    }
}