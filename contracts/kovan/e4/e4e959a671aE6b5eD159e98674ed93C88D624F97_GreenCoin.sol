/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract GreenCoin
{
    struct ProfileData
    {
        uint8 permission;
        uint balance;
        uint locked;
        uint iteration;
        mapping(address => uint) allowance;
    }

    struct PoolData
    {
        uint opened;
        uint deadlineJoin;
        uint deadline;
        uint locked;
        uint volume;
    }

    string private name_;
    string private symbol_;
    uint private decimals_;
    uint private totalSupply_;
    
    address private owner;
    uint private minimumValueFeeable;
    uint private verificationFee;
    uint private iteration;

    mapping (address => ProfileData) private profiles;
    mapping (uint => PoolData) private pools;
    PoolData[] private poolsMeta;
    
    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Permission(address indexed user, uint8 value);
    event Gate(address indexed user, uint iteration, string status);
    event Traffic(address indexed user, uint iteration, string status);
    event Fee(address indexed user, uint iteration, uint value);
    event Reward(address indexed user, uint iteration, uint locked, uint reward);
    
    constructor()
    {
        name_ = "Green Coin";
        symbol_ = "GRC";
        decimals_ = 18;
        totalSupply_ = 8000000000 * 10 ** decimals_;
        minimumValueFeeable = 100;
        verificationFee = 10000 * 10 ** decimals_;
        owner = msg.sender;
        iteration = 1;
        profiles[owner].balance = totalSupply_;
        profiles[owner].permission = 2;
        emit Transfer(address(0), owner, totalSupply_);
        emit Permission(address(0), profiles[owner].permission);
    }

    modifier isNormal
    {
        require(profiles[msg.sender].permission == 0);
        _;
    }

    modifier isVerified
    {
        require(profiles[msg.sender].permission >= 1);
        _;
    }
    
    function name() public view returns (string memory)
    {
        return name_;
    }
    
    function symbol() public view returns (string memory)
    {
        return symbol_;
    }
    
    function decimals() public view returns (uint)
    {
        return decimals_;
    }
    
    function totalSupply() public view returns (uint)
    {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint)
    {
        return profiles[_owner].balance;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint)
    {
        return profiles[_owner].allowance[_spender];
    }

    function allowance(address _spender) public view returns (uint)
    {
        return profiles[msg.sender].allowance[_spender];
    }

    function lockedValue() public view returns (uint)
    {
        return lockedValueOf(msg.sender);
    }

    function lockedValueOf(address _owner) public view returns (uint)
    {
        return profiles[_owner].locked;
    }

    function permissionOf(address _owner) public view returns (uint)
    {
        return profiles[_owner].permission;
    }

    function verificationCost() public view returns (uint)
    {
        return verificationFee;
    }

    function verified() public view returns (bool)
    {
        return profiles[msg.sender].permission >= 1 ? true : false;
    }

    function cycle() public view returns (uint)
    {
        return iteration;
    }

    function pool() public view returns (PoolData memory)
    {
        return pool(iteration);
    }

    function pool(uint _iteration) public view returns (PoolData memory)
    {
        require(validIteration(_iteration));
        return pools[_iteration];
    }

    function poolArray() public view returns (PoolData[] memory)
    {
        return poolsMeta;
    }

    function poolInitialized() public view returns (bool)
    {
        return poolInitialized(iteration);
    }

    function poolInitialized(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].opened > 0;
    }

    function poolOpened() public view returns (uint)
    {
        return poolOpened(iteration);
    }

    function poolOpened(uint _iteration) public view returns (uint)
    {
        require(validIteration(_iteration));
        return pools[_iteration].opened;
    }

    function poolDeadlineJoin() public view returns (uint)
    {
        return poolDeadlineJoin(iteration);
    }

    function poolDeadlineJoin(uint _iteration) public view returns (uint)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadlineJoin;
    }

    function poolGatesOpen() public view returns (bool)
    {
        return poolGatesOpen(iteration);
    }

    function poolGatesOpen(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadlineJoin >= block.timestamp ? true : false;
    }

    function poolDeadline() public view returns (uint)
    {
        return poolDeadline(iteration);
    }

    function poolDeadline(uint _iteration) public view returns (uint)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadline;
    }

    function poolRunning() public view returns (bool)
    {
        return poolRunning(iteration);
    }

    function poolRunning(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadline >= block.timestamp ? true : false;
    }

    function approve(address _spender, uint _value) external returns (bool)
    {
        require(_spender != address(0));
        profiles[msg.sender].allowance[_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfering(address _from, address _to, uint _value) private
    {
        uint fee = _value >= minimumValueFeeable ? _value / 100 : 0;
        uint value = _value - fee;
        profiles[_from].balance -= _value;
        profiles[_to].balance += value;
        emit Transfer(_from, _to, value);
        if (fee > 0)
        {
            pools[iteration].volume += fee;
            poolsMeta[iteration].volume = pools[iteration].volume;
            emit Fee(_from, iteration, fee);
        }
    }

    function transfer(address _to, uint _value) public returns (bool success)
    {
        require(_to != msg.sender);
        require (_value <= profiles[msg.sender].balance);
        transfering(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool success)
    {
        require(_to != _from);
        require(_value <= profiles[_from].balance);
        require(_value <= profiles[_from].allowance[msg.sender]);
        profiles[_from].allowance[msg.sender] -= _value;
        transfering(_from, _to, _value);
        return true;
    }

    function verify() isNormal external returns (bool)
    {
        require(profiles[msg.sender].permission == 0);
        require(profiles[msg.sender].balance >= verificationFee);
        profiles[msg.sender].balance -= verificationFee;
        profiles[msg.sender].permission = 1;
        pools[iteration].volume += verificationFee;
        poolsMeta[iteration].volume = pools[iteration].volume;
        emit Permission(msg.sender, 1);
        return true;
    }

    function managePool() isVerified external returns (bool)
    {
        if (poolInitialized())
        {
            if (!poolRunning())
            {
                closePool();
                openPool();
                //reward
                transfering(owner, msg.sender, 100 * 10 ** decimals_);
            }
        }
        else
        {
            openPool();
        }

        return true;
    }

    function joinPool(uint stake_) isVerified external returns (bool)
    {
        require(poolGatesOpen());
        require(profiles[msg.sender].locked == 0);
        require(profiles[msg.sender].balance >= stake_);
        profiles[msg.sender].iteration = iteration;
        profiles[msg.sender].balance -= stake_;
        profiles[msg.sender].locked = stake_;
        pools[iteration].locked += stake_;
        poolsMeta[iteration].locked = pools[iteration].locked;
        emit Traffic(msg.sender, iteration, "joined");
        return true;
    }

    function leavePool() isVerified external returns (bool)
    {
        uint index = profiles[msg.sender].iteration;
        uint locked = profiles[msg.sender].locked;
        require(index == iteration);
        profiles[msg.sender].iteration = 0;
        profiles[msg.sender].locked = 0;
        profiles[msg.sender].balance += locked;
        pools[index].locked -= locked;
        poolsMeta[index].locked = pools[index].locked;
        emit Traffic(msg.sender, index, "left");
        return true;
    }

    function claimReward() isVerified external returns (bool)
    {
        uint index = profiles[msg.sender].iteration;
        require(validIteration(index));
        require(poolInitialized(index));//wenn index > 0 kann es nur valid sein. Call eig unnötig
        require(!poolRunning(index));
        uint locked = profiles[msg.sender].locked;
        uint shares = locked / pools[index].locked;
        uint reward = (pools[index].volume / 100) * shares;
        profiles[msg.sender].locked = 0;
        profiles[msg.sender].iteration = 0;
        profiles[msg.sender].balance += locked + reward;
        emit Reward(msg.sender, index, locked, reward);
        emit Traffic(msg.sender, index, "left");
        return true;
    }

    function validIteration(uint _iteration) private view returns (bool)
    {
        require(_iteration > 0);
        require(_iteration <= iteration);
        return true;
    }

    function openPool() private
    {
        pools[iteration].opened = block.timestamp;
        pools[iteration].deadlineJoin = block.timestamp + 6 hours;
        pools[iteration].deadline = block.timestamp + 30 days;
        poolsMeta[iteration].opened = pools[iteration].opened;
        poolsMeta[iteration].deadlineJoin = pools[iteration].deadlineJoin;
        poolsMeta[iteration].deadline = pools[iteration].deadline;
        emit Gate(msg.sender, iteration, "open");
    }

    function closePool() private
    {
        emit Gate(msg.sender, iteration, "close");
        poolsMeta.push();
        iteration++;
    }
}