//SourceUnit: LGT_TRX.sol

pragma solidity 0.6.12;

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
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);
        // Solidity already throws when dividing by 0.
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
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

contract Ownable {
    address payable private _owner;

    constructor () public{
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

contract LGT_TRX is Ownable {
    IERC20 private immutable c_lgt_trx_pair;
    IERC20 private immutable c_lgt;

    uint256 private constant DURATION = 365 days;

    uint256 public immutable starttime = block.timestamp;
    uint256 public periodFinish = block.timestamp + DURATION;

    uint256 public initRewardDay = 1500*10**6;
    uint256 public rewardRate = 17361;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    struct User {
        address upline;
        uint256 reward;
        uint256 totalReward;
        uint256 gen20;
    }
    mapping(address => User) public users;
    address private immutable firstAddress;
    mapping(uint => address) public id2Address;
    uint256 public nextUserId = 2;

    mapping (uint8 => uint256) public refRewardRates;

    uint256 public minRef = 1000*10**6;


    uint256 constant private magnitude = 2**128;
    uint256 private magnifiedDividendPerShare;

    mapping(address => int256) private magnifiedDividendCorrections;
    mapping(address => uint256) private withdrawnDividends;

    uint256 public totalDividendsDistributed;
    IERC20 private immutable c_usdt;

    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    constructor(address pair, address lgt, address usdt, address first) public {
        c_lgt_trx_pair = IERC20(pair);
        c_lgt = IERC20(lgt);
        c_usdt = IERC20(usdt);
        firstAddress = first;
        id2Address[1] = first;
        
        refRewardRates[0] = 200000;
        refRewardRates[1] = 133333;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        
        rewards[account] = _balances[account].mul(rewardPerTokenStored.sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    modifier checkhalve() {
        if (block.timestamp >= periodFinish) {
            initRewardDay += 750*10**6;
            if ( initRewardDay <= 4500*10**6 ) {
                rewardRate = initRewardDay / 1 days;
            }else {
                rewardRate = 0;
            }
            periodFinish = block.timestamp.add(DURATION);
        }
        _;
    }

    function setMinRef(uint256 newMin) public onlyOwner() {
        minRef = newMin;
    }

    function setRef(uint256 new0, uint256 new1) public onlyOwner() {
        refRewardRates[0] = new0;
        refRewardRates[1] = new1;
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add( lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply) );
    }
    
    function stake(address referrer, uint256 amount) public updateReward(msg.sender) checkhalve {
        require(amount > 0, 'LPPool: Cannot stake 0');
        c_lgt_trx_pair.transferFrom(msg.sender, address(this), amount);

        if (!isUserExists(msg.sender)) {
            require(isUserExists(referrer), "referrer not exists");
            users[msg.sender].upline = referrer;
            id2Address[nextUserId] = msg.sender;
            nextUserId++;
        }

        _mint(msg.sender, amount);
    }

    function isUserExists(address addr) public view returns (bool) {
        return (addr == firstAddress || users[addr].upline != address(0));
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkhalve {
        if (amount > 0) {
            _burn(msg.sender, amount);
            c_lgt_trx_pair.transfer(msg.sender, amount);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
        withdrawDividend();
    }

    function getReward() public updateReward(msg.sender) checkhalve {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            _refPayout(msg.sender, reward);
            rewards[msg.sender] = 0;
        }

        reward += users[msg.sender].reward;
        users[msg.sender].reward = 0;

        if (reward > 0) {
            c_lgt.transfer(msg.sender, reward);
            users[msg.sender].totalReward += reward;
        }
    }

    function _refPayout(address addr, uint256 amount) private {
        address up = users[addr].upline;
        for(uint8 i = 0; i < 2; i++) {
            if(up == address(0)) break;
            if (_balances[up] >= minRef){
                users[up].reward += amount * refRewardRates[i] / 1000000;
            }
            up = users[up].upline;
        }
    }


    function _addGen20(address addr, uint256 amount) private {
        address up = users[addr].upline;
        for(uint8 i = 0; i < 20; i++) {
            if(up == address(0)) break;
            users[up].gen20 += amount;
            up = users[up].upline;
        }
    }

    function _removeGen20(address addr, uint256 amount) private {
        address up = users[addr].upline;
        for(uint8 i = 0; i < 20; i++) {
            if(up == address(0)) break;
            users[up].gen20 -= amount;
            up = users[up].upline;
        }
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(amount)).toInt256Safe() );

        _addGen20(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount, "burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(amount)).toInt256Safe() );

        _removeGen20(account, amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function distributeDividends(uint256 amount) public {
        c_usdt.transferFrom(msg.sender, address(this), amount);
        require(totalSupply() > 0);
        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((amount).mul(magnitude) / totalSupply());
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function withdrawDividend() public {
        _withdrawDividendOfUser(msg.sender);
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            c_usdt.transfer(msg.sender, _withdrawableDividend);
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns(uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return magnifiedDividendPerShare.mul(_balances[_owner]).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }
    
    function userUSDTLGT(address addr) public view returns(uint256, uint256, uint256, uint256, uint256, uint256){
        uint256 withdrawableDividend = withdrawableDividendOf(addr);
        uint256 earned = getEarned(addr);
        return (totalDividendsDistributed, withdrawableDividend, withdrawnDividends[addr], earned, users[addr].reward, users[addr].totalReward);
    }

    function getEarned(address addr) public view returns(uint256)  {
        return _balances[addr].mul(rewardPerToken().sub(userRewardPerTokenPaid[addr])).div(1e18).add(rewards[addr]);
    }
    
    function userInfo(address addr) public view returns(uint256, uint256, uint256, uint256, uint256, address, uint256) {
        return (_totalSupply, c_lgt.balanceOf(address(this)), c_usdt.balanceOf(address(this)), _balances[addr], c_lgt_trx_pair.balanceOf(addr), users[addr].upline, users[addr].gen20);
    }

    function contractInfo() public view returns (uint256, uint256) {
        return (_totalSupply, nextUserId);
    }

    function idInfo(uint256 id) public view returns(address, address, uint256, uint256) {
        address addr = id2Address[id];
        return (addr, users[addr].upline, _balances[addr], users[addr].gen20);
    }
}