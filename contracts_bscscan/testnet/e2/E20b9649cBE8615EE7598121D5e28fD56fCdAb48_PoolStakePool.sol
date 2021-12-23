pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function burn(uint256 _amount) external;
}

interface relationship {
    function getFather(address _addr) external view returns (address);

    function getGrandFather(address _addr) external view returns (address);
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PoolStakePool is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct Node {
        string name;
        string introduction;
        address nodeOwner;
        uint256 depositAmount;
    }

    IERC20 awardToken;
    IERC20 public LPToken;
    //one day
    uint256 constant SEC_OF_DAY = 86400;

    uint256 public tokenPerSec;
    //用户总的存储量
    uint256 public supplyDeposit;
    //用户未领取的代币奖励
    uint256 public balOFUserReward;
    //上一次更新奖励d;
    uint256 public lastRewardSec;
    //每代币的持有奖励
    uint256 public accTokenPerShare;

    Node[] public node;

    mapping(uint256 => mapping(address => UserInfo)) public userInfoMap;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event AddNode(string indexed node, uint256 indexed nodeNumber, address indexed nodeOwner);
    event EmergencyWithdraw(address indexed user, uint256 indexed _pid, uint256 amount);

    function init(uint256 _startTime, address _awardToken) public onlyOwner {
        lastRewardSec = _startTime;
        awardToken = IERC20(_awardToken);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfoMap[_pid][_user];
        if (user.amount == 0) return 0;
        uint256 teaTokenPerShare = accTokenPerShare;
        if (block.timestamp > lastRewardSec && supplyDeposit != 0) {
            uint256 multiplier = getMultiplier(lastRewardSec, block.timestamp);
            uint256 TokenReward = multiplier.mul(tokenPerSec);
            teaTokenPerShare = accTokenPerShare.add(TokenReward.mul(1e12).div(supplyDeposit));
        }
        return (user.amount.mul(teaTokenPerShare).div(1e12).sub(user.rewardDebt)).mul(10).div(14);
    }

    function updatePool() public {
        if (block.timestamp <= lastRewardSec) {
            return;
        }
        if (supplyDeposit == 0) {
            lastRewardSec = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardSec, block.timestamp);
        uint256 TokenReward = multiplier.mul(tokenPerSec);
        accTokenPerShare = accTokenPerShare.add(TokenReward.mul(1e12).div(supplyDeposit));
        lastRewardSec = block.timestamp;
        balOFUserReward = balOFUserReward.add(TokenReward);
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        Node storage _node = node[_pid];

        updatePool();
        LPToken.transferFrom(address(msg.sender), address(this), _amount);

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);

        //减去用户领取的奖励
        _node.depositAmount = _node.depositAmount.add(_amount);
        supplyDeposit = supplyDeposit.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _Amount) public {
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        Node storage _node = node[_pid];

        require(user.amount >= _Amount, "withdraw: not good");
        updatePool();

        if (_Amount > 0) {
            user.amount = user.amount.sub(_Amount);
            LPToken.transfer(address(msg.sender), _Amount);
        }
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);

        _node.depositAmount = _node.depositAmount.sub(_Amount);
        supplyDeposit = supplyDeposit.sub(_Amount);
        emit Withdraw(msg.sender, _pid, _Amount);
    }

    //紧急提取，但是这不会改变池子的数据。
    function emergencyWithdraw(uint256 _pid) public {
        UserInfo storage user = userInfoMap[_pid][msg.sender];

        uint256 _trueAmount = LPToken.balanceOf(address(this)) > user.amount ? user.amount : LPToken.balanceOf(address(this));

        LPToken.transfer(msg.sender, _trueAmount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function nodeLength() public view returns (uint256){
        return node.length;
    }

    function nodeList() public view returns (Node[] memory){
        return node;
    }

    function bacthAddNode(string[] memory _names, string[] memory _introductions, address[] memory _nodeOwners) public onlyOwner {
        uint256 _length = _names.length;
        for (uint256 i; i < _length; i++) {
            node.push(Node({
            name : _names[i],
            introduction : _introductions[i],
            nodeOwner : _nodeOwners[i],
            depositAmount : 0
            }));
        }
    }

    //设置挖矿的开始时间
    function setStartTime(uint256 _startTime) public onlyOwner {
        lastRewardSec = _startTime;
    }

    //设置挖矿产出量，如果是0的话 就按照计算的来
    //1、打入Token后 需触发本函数，参数为0，设置挖矿产出
    function setTokenPerSec(uint256 _ownerTokenPerSec) public onlyOwner {
        updatePool();
        uint256 _TokenPerSec = referenceTokenPerSec();
        //返回计算出的下次的挖矿数量和计算的当前的已minted的数量
        if (_ownerTokenPerSec == 0) {
            tokenPerSec = _TokenPerSec;
        } else {
            tokenPerSec = _ownerTokenPerSec;
        }
    }

    function referenceTokenPerSec() public view returns (uint256){
        uint256 balTokenOfPool = awardToken.balanceOf(address(this));
        //（池子当前的总余额-用户未领取）=有效的奖励余额/平摊到每一秒
        uint256 tempTokenPerSec = balTokenOfPool.sub(balOFUserReward).mul(1).div(10).div(SEC_OF_DAY);
        return tempTokenPerSec;
    }
}