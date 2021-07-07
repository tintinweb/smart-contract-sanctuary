/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address spender, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

 abstract contract Farm {
    function setWeeksRewards(uint256 amount) external virtual;
}

contract CookieFinance is ERC20 {
    string public constant name  = "Cookie Finance";
    string public constant symbol = "CHIPS";
    uint8 public constant decimals = 18;

    uint256 totalChips = 250000 * (10 ** 18);
    
    address public currentGovernance;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor() {
        currentGovernance = msg.sender;
        balances[msg.sender] = totalChips;
        emit Transfer(address(0), msg.sender, totalChips);
    }

    function totalSupply() public view override returns (uint256) {
        return totalChips;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address spender, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender]);
        require(spender != address(0));

        balances[msg.sender] -= value;
        balances[spender] += value;

        emit Transfer(msg.sender, spender, value);
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferFrom(address owner, address spender, uint256 value) public override returns (bool) {
        require(value <= balances[owner]);
        require(value <= allowed[owner][msg.sender]);
        require(spender != address(0));

        balances[owner] -= value;
        balances[spender] += value;

        allowed[owner][msg.sender] -= value;

        emit Transfer(owner, spender, value);
        return true;
    }

    function updateGovernance(address newGovernance) external {
        require(msg.sender == currentGovernance);
        currentGovernance = newGovernance;
    }
    
    function mint(uint256 amount, address recipient) external {
        require(msg.sender == currentGovernance);
        if (amount > 0) {
            balances[recipient] += amount;
            totalChips += amount;
            emit Transfer(address(0), recipient, amount);
        }
    }

    function burn(uint256 amount) external {
        if (amount > 0) {
            totalChips -= amount;
            balances[msg.sender] -= amount;
            emit Transfer(msg.sender, address(0), amount);
        }
    }
}

contract CookieGovernance {
    
    CookieFinance public CHIPS;
    address owner = msg.sender;
    
    uint256 maxRewardChips;
    uint256 maxExposureChips;
    
    mapping(address => uint256) public maxCompensation;
    mapping(uint256 => uint256) public newFarms;
    
    mapping(address => PendingUpdate) public pendingRewards;
    mapping(address => PendingUpdate) public pendingExposure;
    
    struct PendingUpdate {
        uint256 amount;
        uint256 timelock;
    }
    
    function initiate(address _CHIPS, uint256 _maxRewardChips, uint256 _maxExposureChips) external {
        require(address(CHIPS) == address(0) && _CHIPS != address(0));
        CHIPS = CookieFinance(_CHIPS);
        maxRewardChips = _maxRewardChips;
        maxExposureChips = _maxExposureChips;
    }
    
    function updateMaxRewardAndExposure( uint256 _maxRewardChips, uint256 _maxExposureChips) external {
        require(msg.sender == owner);
        maxRewardChips = _maxRewardChips;
        maxExposureChips = _maxExposureChips;
    }
    
    function setupFarm(address farm, uint256 rewards, uint256 exposure) external {
        require(msg.sender == owner);
        require(maxCompensation[farm] == 0); // New farm
        require(rewards > 0 && rewards <= maxRewardChips); 
        require(exposure > 0 && exposure <= maxExposureChips); 
        require(newFarms[epochDay()] < 2); // max 2 farms daily (safety)
        
        Farm(farm).setWeeksRewards(rewards);
        CHIPS.mint(rewards, farm);
        maxCompensation[farm] = exposure;
        newFarms[epochDay()]++;
    }
    
    
    function initiateWeeklyFarmIncentives(address farm, uint256 rewards) external {
        require(msg.sender == owner);
        pendingRewards[farm] = PendingUpdate(rewards, block.timestamp + 24 hours);
    }
    
    // Requires 24 hours to pass
    function provideWeeklyFarmIncentives(address farm) external {
        PendingUpdate memory pending = pendingRewards[farm];
        require(pending.timelock > 0 && block.timestamp > pending.timelock);
        
        Farm(farm).setWeeksRewards(pending.amount);
        CHIPS.mint(pending.amount, farm);
        delete pendingRewards[farm];
    }
    
    
    function initiateUpdateFarmExposure(address farm, uint256 _CHIPS) external {
        require(msg.sender == owner);
        pendingExposure[farm] = PendingUpdate(_CHIPS, block.timestamp + 24 hours);
    }
    
    // Requires 24 hours to pass
    function updateFarmExposure(address farm) external {
        PendingUpdate memory pending = pendingExposure[farm];
        require(pending.timelock > 0 && block.timestamp > pending.timelock);
        
        maxCompensation[farm] = pending.amount;
        delete pendingExposure[farm];
    }
    
    
    function pullCollateral(uint256 amount) external returns (uint256 compensation) {
        address farm = msg.sender;
        compensation = amount;
        if (compensation > maxCompensation[farm]) {
            compensation = maxCompensation[farm];
        }
        delete maxCompensation[farm]; // Farm is closed once compensation is triggered
        CHIPS.mint(compensation, farm);
    }
    
    
    // After beta will transition to DAO (using below timelock upgrade)
    address public nextGov;
    uint256 public nextGovTime;
    
    function beginGovernanceRequest(address newGovernance) external {
        require(msg.sender == owner);
        nextGov = newGovernance;
        nextGovTime = block.timestamp + 48 hours;
    }
    
    function triggerGovernanceUpdate() external {
        require(block.timestamp > nextGovTime && nextGov != address(0));
        CHIPS.updateGovernance(nextGov);
    }
    
    function epochDay() public view returns (uint256) {
        return block.timestamp / 86400;
    }
    
    function compensationAvailable(address farm) public view returns (uint256) {
        return maxCompensation[farm];   
    }
    
}