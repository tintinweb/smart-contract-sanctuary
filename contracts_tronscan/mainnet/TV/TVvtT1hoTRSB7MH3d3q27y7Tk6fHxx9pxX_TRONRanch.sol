//SourceUnit: SunshineRanchPool.sol

pragma solidity ^0.5.9;

import "./SunshineRanchToken.sol";


contract TRONRanch is Ownable {

    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardPending;
    }


    // Info of each pool.
    struct PoolInfo {
        TRC20 lpToken;

        uint256 allocPoint;

        uint256 lastRewardBlock;

        uint256 accSSRPerShare;

        uint256 totalPool;
    }

    SunshineToken public ssr;
    address public devaddr;
    uint256 public bonusEndBlock;
    uint256 public ssrPerBlock;
    uint256 public constant BONUS_MULTIPLIER = 10;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        SunshineToken _ssr,
        address _devaddr,
        uint256 _ssrPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        ssr = _ssr;
        devaddr = _devaddr;
        ssrPerBlock = _ssrPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    modifier validatePool(uint256 _pid){
        require(_pid < poolInfo.length, "chef: pool exists.");
        _;
    }


    function add(uint256 _allocPoint, TRC20 _lpToken, bool _withUpdate) public onlyOwner {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].lpToken == _lpToken) {
                revert("Pool exits.");
            }
        }
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accSSRPerShare : 0,
            totalPool : 0
            }));
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public validatePool(_pid) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    function pendingSSR(uint256 _pid, address _user) external validatePool(_pid) view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSSRPerShare = pool.accSSRPerShare;
        uint256 lpSupply = pool.totalPool;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward = multiplier.mul(ssrPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSSRPerShare = accSSRPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSSRPerShare).div(1e12).sub(user.rewardDebt).add(user.rewardPending);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalPool;

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 sushiReward = multiplier.mul(ssrPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        ssr.mint(devaddr, sushiReward.div(100));
        ssr.mint(address(this), sushiReward);

        if (ssr.totalSupply() >= (10 ** (uint256(ssr.decimals()))).mul(210000000)) {
            ssrPerBlock = 0;
        }

        pool.accSSRPerShare = pool.accSSRPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public validatePool(_pid) payable {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSSRPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardPending = user.rewardPending.add(pending);
        }
        if (address(pool.lpToken) == address(0)) {
            _amount = msg.value;
        } else {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        }
        pool.totalPool = pool.totalPool.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSSRPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public validatePool(_pid) returns (uint){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        pool.totalPool = pool.totalPool.sub(_amount);
        uint256 pending = user.amount.mul(pool.accSSRPerShare).div(1e12).sub(user.rewardDebt).add(user.rewardPending);
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardPending = 0;
        user.rewardDebt = user.amount.mul(pool.accSSRPerShare).div(1e12);
        if (address(pool.lpToken) == address(0)) {
            address(msg.sender).transfer(_amount);
        } else {
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);

        return pending;
    }

    function emergencyWithdraw(uint256 _pid) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (address(pool.lpToken) == address(0)) {
            address(msg.sender).transfer(user.amount);
        } else {
            pool.lpToken.transfer(address(msg.sender), user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardPending = 0;
    }

    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = ssr.balanceOf(address(this));
        if (_amount > sushiBal) {
            ssr.transfer(_to, sushiBal);
        } else {
            ssr.transfer(_to, _amount);
        }
    }

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }


}


//SourceUnit: SunshineRanchToken.sol

pragma solidity ^0.5.9;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TRC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TRC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is TRC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function getBalance() public view returns (uint256){
        return balances[msg.sender];
    }
}

contract StandardToken is TRC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0),"address is null");
        require(_value <= balances[_from],"Insufficient balance");
        require(_value <= allowed[_from][msg.sender],"Insufficient allowed.");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract SunshineToken is StandardToken, Ownable {

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 10 ** uint256(_decimals);
    }

    function mint(address _to,uint256 _amount) public onlyOwner{
        require(_to != address(0), "TRC20: mint to the zero address");
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

}