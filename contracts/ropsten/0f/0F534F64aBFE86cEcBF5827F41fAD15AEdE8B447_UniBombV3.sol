/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes calldata data) external;
}

interface IUniswapV2Pair {
    function sync() external;
}

contract UniBombV3 is ERC20 {
    using SafeMath for uint;

    modifier initialPhaseOver() {
        require(block.timestamp > initialPhaseEnd, 'Not yet');
        _;
    }

    modifier unclaimedRewards(address addr) {
        uint rewards = calculateRewards(addr);
        if (rewards > 0) {
            claimRewards(addr, rewards);
        }
        _;
    }

    modifier burnCheck() {
        if (lastPoolBalance != balanceOf(pool)) {
            burnUpdate();
        }
        _;
    }

    struct User {
        uint balance;
        mapping (address => uint) allowed;
        uint allTimeRewards;
        uint stakeBalance;
        int stakePayouts;
    }

    mapping (address => User) internal user;

    address pool;

    // ERC20 stuff
    string public constant name  = "UniBombV3";
    string public constant symbol = "UBOMB";
    uint8 public constant decimals = 18;

    // v2
    ERC20 private ubombv2;

    // burn stuff
    uint lastBurnTime;
    uint toBurn;
    uint day = 86400; // 86400 seconds in one day
    uint burnRate = 3; // 3% burn per day
    uint _totalSupply;
    uint startingSupply = 10000000 * (10 ** 18); // 10 million supply
    uint totalBurned;

    uint lastPoolBalance;

    uint constant private BURN_REWARD = 10;

    // staking stuff
    uint constant private STAKE_FEE = 10;
    uint constant private MAG = 2**64;

    uint internal initialPhaseEnd;
    uint internal totalStaked;
    uint internal divsPerShare;
    bool internal initialized;

    event Stake(address user, uint staked);
    event Unstake(address user, uint unstaked);
    event PoolBurn(address user, uint burned, uint newSupply, uint newPool);
    
    receive() external payable {
        revert('No');
    }

    // For UI

    function allInfoFor(address addr) public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        // User memory _user = user[addr];
        return (
            user[addr].balance,
            user[addr].stakeBalance,
            calculateRewards(addr),
            user[addr].allTimeRewards,
            user[pool].balance,
            _totalSupply,
            totalStaked,
            totalBurned,
            toBurn,
            lastBurnTime
        );
    }

    // Migration

    function initialize(uint _initialPhaseEnd, uint _poolSupply, address _ubombv2, address _poolAddr) external {
        require(!initialized);
        initialPhaseEnd = _initialPhaseEnd;
        user[msg.sender].balance = _poolSupply;
        _totalSupply = _poolSupply;
        ubombv2 = ERC20(_ubombv2);
        totalBurned = startingSupply - ubombv2.totalSupply();
        pool = _poolAddr;
        lastBurnTime = block.timestamp;
        initialized = true;
    }

    function receiveApproval(address from, uint tokens) public {
        require(ubombv2.transferFrom(from, address(this), tokens), 'Transfer failed');
        user[from].balance += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), msg.sender, tokens);
    }

    // Staking functions

    function distribute(uint amount) public {
        require(totalStaked > 0, 'Stake required');
        // User memory _user = user[msg.sender];
        require(user[msg.sender].balance >= amount, 'Not enough minerals');
        user[msg.sender].balance = user[msg.sender].balance.sub(amount);
        // user[msg.sender] = user[msg.sender];

        divsPerShare = divsPerShare.add((amount * MAG) / totalStaked);
    }

    function stake(address addr, uint amount) public unclaimedRewards(msg.sender) {
        require(user[msg.sender].balance >= amount, 'Not enough minerals');
        require(addr != pool, 'Pool cannot stake');
        // User memory _user = user[addr];

        if (block.timestamp < initialPhaseEnd) {
            totalStaked += amount;
            user[addr].stakeBalance += amount;
            user[addr].stakePayouts += (int)(divsPerShare.mul(amount));
            // user[addr] = _user;
            user[msg.sender].balance = user[msg.sender].balance.sub(amount);
            return;
        }

        uint fee = (amount * STAKE_FEE) / 100;
        uint newStake = amount.sub(fee);
        totalStaked += newStake;
        uint userFeeShare = fee - (fee - (newStake * ((fee * MAG) / totalStaked)));
        divsPerShare = divsPerShare.add((fee * MAG) / totalStaked);

        user[addr].stakeBalance += newStake;
        user[addr].stakePayouts += (int)(divsPerShare.mul(newStake).sub(userFeeShare));

        // user[addr] = _user;
        user[msg.sender].balance = user[msg.sender].balance.sub(amount);

        emit Stake(addr, amount);
    }

    function unstake(uint amount) public initialPhaseOver {
        address addr = msg.sender;
        // User memory _user = user[addr];
        require(amount <= user[addr].stakeBalance, 'Not enough staked');

        uint fee = (amount * STAKE_FEE) / 100;
        uint received = amount.sub(fee);

        totalStaked = totalStaked.sub(amount);
        user[addr].stakeBalance -= amount;
        user[addr].stakePayouts -= (int)(divsPerShare.mul(amount));
        user[addr].balance += received;

        divsPerShare = divsPerShare.add((fee * MAG).div(totalStaked));

        // user[addr] = _user;

        emit Unstake(addr, amount);
    }

    function calculateRewards(address addr) internal view returns (uint) {
        // User memory _user = user[addr];
        return (uint)((int)(divsPerShare.mul(user[addr].stakeBalance)) - user[addr].stakePayouts) / MAG;
    }

    function claimRewards(address addr, uint rewards) internal {
        // User memory _user = user[addr];
        user[addr].balance += rewards;
        user[addr].allTimeRewards += rewards;
        user[addr].stakePayouts += (int)(rewards * MAG);
        // user[addr] = _user;
    }

    // ERC20 functions

    function totalSupply() public view override returns (uint) {
       return _totalSupply.sub(toBurn + getBurnAmount());
    }

    function balanceOf(address addr) public view override returns (uint) {
        return user[addr].balance + calculateRewards(addr);
    }

    function allowance(address addr, address spender) public view override returns (uint) {
        return user[addr].allowed[spender];
    }

    function transfer(address to, uint value) public unclaimedRewards(msg.sender) burnCheck override returns (bool) {
        // User memory _user = user[msg.sender];
        require(user[msg.sender].balance >= value, 'Not enough minerals');

        user[msg.sender].balance = user[msg.sender].balance.sub(value);
        // user[msg.sender] = _user;
        user[to].balance += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) public override returns (bool) {
        user[msg.sender].allowed[spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint tokens, bytes calldata data) external unclaimedRewards(msg.sender) returns (bool) {
        user[msg.sender].allowed[spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferFrom(address from, address to, uint value) public unclaimedRewards(from) burnCheck override returns (bool) {
        // User storage _user = user[from];
        require(user[from].balance >= value, 'Not enough minerals');
        require(user[from].allowed[msg.sender] >= value, 'You require more vespene gas');

        user[from].balance = user[from].balance.sub(value);
        user[from].allowed[msg.sender] = user[from].allowed[msg.sender].sub(value);
        // user[from] = _user;
        user[to].balance += value;

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        user[msg.sender].allowed[spender] = user[msg.sender].allowed[spender].add(addedValue);
        emit Approval(msg.sender, spender, user[msg.sender].allowed[spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        user[msg.sender].allowed[spender] = user[msg.sender].allowed[spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, user[msg.sender].allowed[spender]);
        return true;
    }

    // burn functions

    function burnPool() external {
        require(totalStaked > 0, 'Stake required');
        uint _burnAmount = getBurnAmount() + toBurn;
        require(_burnAmount >= 10, "Nothing to burn...");
        lastBurnTime = block.timestamp;
        toBurn = 0;

        uint _userReward = _burnAmount * 10 / 100;
        uint _stakeReward = _burnAmount * 20 / 100;
        uint _finalBurn = _burnAmount - _userReward - _stakeReward;

        _totalSupply = _totalSupply.sub(_finalBurn);
        totalBurned += _finalBurn;
        user[msg.sender].balance += _userReward;
        divsPerShare = divsPerShare.add((_stakeReward * MAG) / totalStaked);
        user[pool].balance = user[pool].balance.sub(_finalBurn);

        IUniswapV2Pair(pool).sync();

        emit PoolBurn(msg.sender, _burnAmount, _totalSupply, balanceOf(pool));
    }

    function getBurnAmount() public view returns (uint) {
        uint _time = block.timestamp - lastBurnTime;
        uint _poolAmount = balanceOf(pool);
        uint _burnAmount = (_poolAmount * burnRate * _time) / (day * 100);
        return _burnAmount;
    }

    function burnUpdate() internal {
        toBurn += getBurnAmount();
        lastBurnTime = block.timestamp;
        lastPoolBalance = balanceOf(pool);
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "safemath mul");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "safemath sub");
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "safemath add");
        return c;
    }
}