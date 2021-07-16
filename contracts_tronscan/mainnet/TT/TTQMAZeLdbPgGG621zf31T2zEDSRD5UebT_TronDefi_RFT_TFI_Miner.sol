//SourceUnit: rft_mine_tron_onine.sol

pragma solidity ^0.5.10;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
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

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}

contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
    }
}

interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function mint(address owner, uint value) external returns(bool);
}

library SafeTRC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        //require(address(token).isContract());

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)));
        }
    }
}

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint reward) external;

    modifier onlyRewardDistribution() {
        require(msg.sender == rewardDistribution);
        _;
    }

    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        rewardDistribution = _rewardDistribution;
    }
}

contract StakeWrapper {
    using SafeMath for uint;
    using SafeTRC20 for ITRC20;
    
    ITRC20 public stakeToken = ITRC20(0x416de2af327df5696ca7c5b778727975a5e61d171d);

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function stake(uint amount) public returns (uint) {
        uint o = stakeToken.balanceOf(address(this));
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        uint n = stakeToken.balanceOf(address(this));
        uint val = n.sub(o);
        _balances[msg.sender] = _balances[msg.sender].add(val);
        _totalSupply = _totalSupply.add(val);

        return val;
    }

    function withdraw(uint amount) public returns (uint) {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        uint o = stakeToken.balanceOf(msg.sender);
        stakeToken.safeTransfer(msg.sender, amount);
        uint n = stakeToken.balanceOf(msg.sender);
        uint val = n.sub(o);

        return val;
    }
}

contract TronDefi_RFT_TFI_Miner is StakeWrapper, IRewardDistributionRecipient {
    ITRC20 public tfi = ITRC20(0x410f46709e685093ccea996745025cb410c49b2b94);
    uint public constant DURATION = 3 days;

    uint public initreward = 4031496064*2;
    uint public starttime = 1600344000;  // 2020-09-17 12:00:00 UTC
    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    event RewardAdded(uint reward);
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);

    modifier checkhalve(){
        if (block.timestamp >= periodFinish) {
            initreward = initreward.mul(50).div(100); 
            tfi.mint(address(this),initreward);

            rewardRate = initreward.div(DURATION);
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initreward);
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        if (block.timestamp > periodFinish && periodFinish > 0) {
            return periodFinish;
        }
        return block.timestamp;
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

    function earned(address account) public view returns (uint) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e6)
                .add(rewards[account]);
            
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e6)
                    .div(totalSupply())
            );
    }

    function stake(uint amount) public checkStart updateReward(msg.sender) checkhalve returns (uint) { 
        require(amount > 0, "Cannot stake 0");
        uint val = super.stake(amount);
        emit Staked(msg.sender, val);

        return val;
    }
    
    function withdraw(uint amount) public checkStart updateReward(msg.sender) checkhalve returns (uint) {
        if (0 == amount) {
            amount = balanceOf(msg.sender);
        }
        uint val = super.withdraw(amount);
        emit Withdrawn(msg.sender, val);

        return val;
    }

    function exit() external returns (uint) {
        uint val = withdraw(balanceOf(msg.sender));
        getReward();
        
        return val;
    }
    
    function getReward() public updateReward(msg.sender) checkhalve checkStart {
        uint reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            tfi.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkStart(){
        require(block.timestamp > starttime, "not start");
        _;
    }

    function notifyRewardAmount(uint reward) external onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        tfi.mint(address(this),reward);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}