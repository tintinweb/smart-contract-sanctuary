/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BlueChip
{
    struct ProfileData
    {
        uint balance;
        uint locked;
        uint iteration;
        bool participated;
        bool verified;
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

    mapping(address => ProfileData) private profiles;
    mapping(uint => PoolData) private pools;
    PoolData[5000] private poolsMeta;
    
    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Permission(address indexed user, uint8 value);
    event Gate(address indexed user, uint iteration, string status);
    event Traffic(address indexed user, uint iteration, string status);
    event Fee(address indexed user, uint iteration, uint value);
    event Reward(address indexed user, uint iteration, uint locked, uint reward);
    
    constructor()
    {
        name_ = "BlueChip";
        symbol_ = "BCP";
        decimals_ = 18;
        totalSupply_ = 8000000000 * 10 ** decimals_;
        minimumValueFeeable = 100;
        verificationFee = 10000 * 10 ** decimals_;
        owner = msg.sender;
        iteration = 0;
        profiles[owner].balance = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
        openPool();
    }

    modifier onlyUnverified
    {
        require(!profiles[msg.sender].verified);
        _;
    }

    modifier onlyVerified
    {
        require(profiles[msg.sender].verified);
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
    
    function allowance(address _spender) public view returns (uint)
    {
        return allowance(msg.sender, _spender);
    }

    function allowance(address _owner, address _spender) public view returns (uint)
    {
        return profiles[_owner].allowance[_spender];
    }

    function cycle() public view returns (uint)
    {
        return iteration;
    }

    function verificationCost() public view returns (uint)
    {
        return verificationFee;
    }

    function isVerified(address _owner) public view returns (bool)
    {
        return profiles[_owner].verified;
    }

    function lockedValueOf(address _owner) public view returns (uint)
    {
        return profiles[_owner].locked;
    }

    function pool(uint _iteration) public view returns (PoolData memory)
    {
        require(validIteration(_iteration));
        return pools[_iteration];
    }

    function isPoolInitialized(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].opened > 0;
    }

    function isPoolGatesOpen(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadlineJoin >= block.timestamp ? true : false;
    }

    function isPoolRunning(uint _iteration) public view returns (bool)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadline >= block.timestamp ? true : false;
    }

    function isPoolJoined(address _owner) public view returns (bool)
    {
        return profiles[_owner].participated;
    }

    function poolOpened(uint _iteration) public view returns (uint)
    {
        require(validIteration(_iteration));
        return pools[_iteration].opened;
    }

    function poolDeadlineJoin(uint _iteration) public view returns (uint)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadlineJoin;
    }

    function poolDeadline(uint _iteration) public view returns (uint)
    {
        require(validIteration(_iteration));
        return pools[_iteration].deadline;
    }

    function poolJoined(address _owner) public view returns (uint itr, uint lkd)
    {
        require(_owner != address(0));
        return (profiles[_owner].iteration, profiles[_owner].locked);
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
        (uint base, uint fee, uint total) = calculateAmount(_value);
        profiles[_from].balance -= total;
        profiles[_to].balance += base;
        pools[iteration].volume += fee;
        poolsMeta[iteration].volume = pools[iteration].volume;
        emit Transfer(_from, _to, base);
        emit Fee(_from, iteration, fee);
    }

    function transfer(address _to, uint _value) public returns (bool success)
    {
        // require(_to != address(0));
        require(_to != msg.sender);
        (uint base, uint fee, uint total) = calculateAmount(_value);
        require (total <= profiles[msg.sender].balance);
        transfering(msg.sender, _to, base);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool success)
    {
        // require(_to != address(0));
        require(_to != _from);
        (uint base, uint fee, uint total) = calculateAmount(_value);
        require(total <= profiles[_from].balance);
        require(total <= profiles[_from].allowance[msg.sender]);//-------------------
        profiles[_from].allowance[msg.sender] -= total;
        transfering(_from, _to, base);
        return true;
    }

    function verify() onlyUnverified external returns (bool)
    {
        require(profiles[msg.sender].balance >= verificationFee);
        profiles[msg.sender].balance -= verificationFee;
        profiles[msg.sender].verified = true;
        pools[iteration].volume += verificationFee;
        poolsMeta[iteration].volume = pools[iteration].volume;
        emit Permission(msg.sender, 1);
        return true;
    }

    function managePool() external returns (bool)
    {
        require(isPoolInitialized(iteration));
        require(!isPoolRunning(iteration));
        closePool();
        openPool();

        return true;
    }

    function openPool() private
    {
        pools[iteration].opened = block.timestamp;
        pools[iteration].deadlineJoin = block.timestamp + 6 hours;
        pools[iteration].deadline = block.timestamp + 7 days;
        poolsMeta[iteration].opened = pools[iteration].opened;
        poolsMeta[iteration].deadlineJoin = pools[iteration].deadlineJoin;
        poolsMeta[iteration].deadline = pools[iteration].deadline;
        emit Gate(msg.sender, iteration, "open");
    }

    function closePool() private
    {
        emit Gate(msg.sender, iteration, "close");
        iteration++;
    }

    function joinPool(uint stake_) onlyVerified external returns (bool)
    {
        require(isPoolGatesOpen(iteration));
        require(profiles[msg.sender].participated == false);
        require(profiles[msg.sender].balance >= stake_);
        profiles[msg.sender].participated = true;
        profiles[msg.sender].iteration = iteration;
        profiles[msg.sender].balance -= stake_;
        profiles[msg.sender].locked = stake_;
        pools[iteration].locked += stake_;
        poolsMeta[iteration].locked = pools[iteration].locked;
        emit Traffic(msg.sender, iteration, "joined");
        return true;
    }

    function leavePool() onlyVerified external returns (bool)
    {
        uint index = profiles[msg.sender].iteration;
        uint locked = profiles[msg.sender].locked;
        require(index == iteration);
        profiles[msg.sender].participated = false;
        profiles[msg.sender].iteration = 0;
        profiles[msg.sender].locked = 0;
        profiles[msg.sender].balance += locked;
        pools[index].locked -= locked;
        poolsMeta[index].locked = pools[index].locked;
        emit Traffic(msg.sender, index, "left");
        return true;
    }

    function claimReward() onlyVerified external returns (uint itr, uint lkd, uint rwd)
    {
        uint index = profiles[msg.sender].iteration;
        require(profiles[msg.sender].participated);
        require(isPoolInitialized(index));
        require(!isPoolRunning(index));
        uint locked = profiles[msg.sender].locked;
        uint reward = pools[index].volume * locked / pools[index].locked;
        profiles[msg.sender].participated = false;
        profiles[msg.sender].locked = 0;
        profiles[msg.sender].iteration = 0;
        profiles[msg.sender].balance += locked + reward;
        emit Reward(msg.sender, index, locked, reward);
        emit Traffic(msg.sender, index, "left");
        return (index, locked, reward);
    }

    function validIteration(uint _iteration) private view returns (bool)
    {
        require(_iteration <= iteration);
        return true;
    }

    function calculateAmount(uint _value) private view returns (uint base, uint fee, uint total)
    {
        base = _value;
        fee = _value >= minimumValueFeeable ? (_value / 100) : 0;
        total = _value + fee;
        return (base, fee, total);
    }
}