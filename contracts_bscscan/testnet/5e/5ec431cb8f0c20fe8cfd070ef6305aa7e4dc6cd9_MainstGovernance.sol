/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity 0.8.0;

// SPDX-License-Identifier: UNLICENSED

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

contract BuyMainStreet is ERC20 {
    string public constant name  = "BuyMainStreet";
    string public constant symbol = "$MAINST";
    uint8 public constant decimals = 9;

    uint256 totalMainst = 500000 * (10 ** 9);
    
    address public currentGovernance;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor() {
        currentGovernance = msg.sender;
        balances[msg.sender] = totalMainst;
        emit Transfer(address(0), msg.sender, totalMainst);
    }

    function totalSupply() public view override returns (uint256) {
        return totalMainst;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address spender, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender], "BuyMainStreet :: insufficient amount");
        require(spender != address(0), "BuyMainStreet :: invalid spender");

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
        require(spender != address(0), "BuyMainStreet :: invalid spender");
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
        require(value <= balances[owner], "BuyMainStreet :: insufficient value");
        require(value <= allowed[owner][msg.sender], "BuyMainStreet :: insufficient allowance");
        require(spender != address(0), "BuyMainStreet :: invalid spender");

        balances[owner] -= value;
        balances[spender] += value;

        allowed[owner][msg.sender] -= value;

        emit Transfer(owner, spender, value);
        return true;
    }

    function updateGovernance(address newGovernance) external {
        require(msg.sender == currentGovernance, "BuyMainStreet :: invalid call. must be called by governance");
        currentGovernance = newGovernance;
    }
    
    function burn(uint256 amount) external {
        if (amount > 0) {
            totalMainst -= amount;
            balances[msg.sender] -= amount;
            emit Transfer(msg.sender, address(0), amount);
        }
    }
}

contract MainstGovernance {
    
    BuyMainStreet public $MAINST;
    address owner = msg.sender;
    
    uint256 maxRewardMainst;
    uint256 maxExposureMainst;
    
    mapping(address => uint256) public maxCompensation;
    mapping(uint256 => uint256) public newFarms;
    
    mapping(address => PendingUpdate) public pendingRewards;
    mapping(address => PendingUpdate) public pendingExposure;
    
    struct PendingUpdate {
        uint256 amount;
        uint256 timelock;
    }
    
    function initiate(address _$MAINST, uint256 _maxRewardMainst, uint256 _maxExposureMainst) external {
        require(address($MAINST) == address(0) && _$MAINST != address(0), "MainstGovernance :: initiate : Invalid mainst address or mainst address may set already");
        $MAINST = BuyMainStreet(_$MAINST);
        maxRewardMainst = _maxRewardMainst;
        maxExposureMainst = _maxExposureMainst;
    }
    
    function updateMaxRewardAndExposure( uint256 _maxRewardMainst, uint256 _maxExposureMainst) external {
        require(msg.sender == owner, "MainstGovernance :: updateMaxRewardAndExposure :  Only owner");
        maxRewardMainst = _maxRewardMainst;
        maxExposureMainst = _maxExposureMainst;
    }
    
    function setupFarm(address farm, uint256 rewards, uint256 exposure) external {
        require(msg.sender == owner, "MainstGovernance :: setupFarm : Only owner");
        require(maxCompensation[farm] == 0, "MainstGovernance :: setupFarm : maximum compensation already set"); // New farm
        require(rewards > 0 && rewards <= maxRewardMainst, "MainstGovernance :: setupFarm : invalid reward amount"); 
        require(exposure > 0 && exposure <= maxExposureMainst, "MainstGovernance :: setupFarm : Invalid exposure"); 
        require(newFarms[epochDay()] < 2, "MAINSTGovernance :: setupFarm : max 2 farms daily"); // max 2 farms daily (safety)
        
        Farm(farm).setWeeksRewards(rewards);
        $MAINST.transfer(farm, rewards);
        maxCompensation[farm] = exposure;
        newFarms[epochDay()]++;
    }
    
    function initiateWeeklyFarmIncentives(address farm, uint256 rewards) external {
        require(msg.sender == owner, "MainstGovernance :: initiateWeeklyFarmIncentives : Only owner");
        pendingRewards[farm] = PendingUpdate(rewards, block.timestamp + 1 hours);
    }
    
    // Requires 24 hours to pass
    function provideWeeklyFarmIncentives(address farm) external {
        PendingUpdate memory pending = pendingRewards[farm];
        require(pending.timelock > 0 && block.timestamp > pending.timelock, "MainstGovernance :: provideWeeklyFarmIncentives : Requires 24 hours to pass");
        
        Farm(farm).setWeeksRewards(pending.amount);
        $MAINST.transfer(farm, pending.amount);
        delete pendingRewards[farm];
    }
    
    function initiateUpdateFarmExposure(address farm, uint256 _$MAINST) external {
        require(msg.sender == owner, "MainstGovernance :: initiateUpdateFarmExposure: only owner");
        pendingExposure[farm] = PendingUpdate(_$MAINST, block.timestamp + 1 hours);
    }
    
    // Requires 24 hours to pass
    function updateFarmExposure(address farm) external {
        PendingUpdate memory pending = pendingExposure[farm];
        require(pending.timelock > 0 && block.timestamp > pending.timelock, "MainstGovernance :: updateFarmExposure : Requires 24 hours to pass");
        
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
        $MAINST.transfer(farm, compensation);
    }
    
    // After beta will transition to DAO (using below timelock upgrade)
    address public nextGov;
    uint256 public nextGovTime;
    
    function beginGovernanceRequest(address newGovernance) external {
        require(msg.sender == owner, "MainstGovernance :: beginGovernanceRequest : Only owner");
        nextGov = newGovernance;
        nextGovTime = block.timestamp + 48 hours;
    }
    
    function triggerGovernanceUpdate() external {
        require(block.timestamp > nextGovTime && nextGov != address(0), "MainstGovernance :: triggerGovernanceUpdate : Invalid newGovernance address or requires time to pass");
        $MAINST.updateGovernance(nextGov);
    }
    
    function epochDay() public view returns (uint256) {
        return block.timestamp / 86400;
    }
    
    function compensationAvailable(address farm) public view returns (uint256) {
        return maxCompensation[farm];   
    }
}