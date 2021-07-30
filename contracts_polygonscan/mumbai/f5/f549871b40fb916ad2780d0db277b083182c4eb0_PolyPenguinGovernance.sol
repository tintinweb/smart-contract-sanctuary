/**
 *Submitted for verification at polygonscan.com on 2021-07-30
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

contract PolyPenguin is ERC20 {
    string public constant name  = "PolyPenguin ";
    string public constant symbol = "PENGS";
    uint8 public constant decimals = 18;

    uint256 totalPengs = 250000 * (10 ** 18);
    
    address public currentGovernance;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor() {
        currentGovernance = msg.sender;
        balances[msg.sender] = totalPengs;
        emit Transfer(address(0), msg.sender, totalPengs);
    }

    function totalSupply() public view override returns (uint256) {
        return totalPengs;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address spender, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender], "PolyPenguin :: insufficient amount");
        require(spender != address(0), "PolyPenguin :: invalid spender");

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
        require(spender != address(0), "PolyPenguin :: invalid spender");
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
        require(value <= balances[owner], "PolyPenguin :: insufficient value");
        require(value <= allowed[owner][msg.sender], "PolyPenguin :: insufficient allowance");
        require(spender != address(0), "PolyPenguin :: invalid spender");

        balances[owner] -= value;
        balances[spender] += value;

        allowed[owner][msg.sender] -= value;

        emit Transfer(owner, spender, value);
        return true;
    }

    function updateGovernance(address newGovernance) external {
        require(msg.sender == currentGovernance, "PolyPenguin :: invalid call. must be called by governance");
        currentGovernance = newGovernance;
    }
    
    function mint(uint256 amount, address recipient) external {
        require(msg.sender == currentGovernance, "PolyPenguin :: invalid call. must be called by governance");
        if (amount > 0) {
            balances[recipient] += amount;
            totalPengs += amount;
            emit Transfer(address(0), recipient, amount);
        }
    }

    function burn(uint256 amount) external {
        if (amount > 0) {
            totalPengs -= amount;
            balances[msg.sender] -= amount;
            emit Transfer(msg.sender, address(0), amount);
        }
    }
}

contract PolyPenguinGovernance {
    
    PolyPenguin public PENGS;
    address owner = msg.sender;
    
    mapping(address => uint256) public maxCompensation;
    mapping(uint256 => uint256) public newFarms;
    
    mapping(address => PendingUpdate) public pendingRewards;
    mapping(address => PendingUpdate) public pendingExposure;
    
    struct PendingUpdate {
        uint256 amount;
        uint256 timelock;
    }
    
    function initiate(address _PENGS) external {
        require(address(PENGS) == address(0) && _PENGS != address(0), "PolyPenguinGovernance :: initiate : Invalid pengs address or pengs address may set already");
        PENGS = PolyPenguin(_PENGS);
    }
    
    function setupFarm(address farm, uint256 rewards, uint256 exposure) external {
        require(msg.sender == owner, "PolyPenguinGovernance :: setupFarm : Only owner");
        require(maxCompensation[farm] == 0, "PolyPenguinGovernance :: setupFarm : maximum compensation already set"); // New farm
        require(rewards > 0 && rewards <= (20000 * (10 ** 18)), "PolyPenguinGovernance :: setupFarm : invalid reward amount"); 
        require(exposure > 0 && exposure <= (40000 * (10 ** 18)), "PolyPenguinGovernance :: setupFarm : Invalid exposure"); 
        require(newFarms[epochDay()] < 2, "PolyPenguinGovernance :: setupFarm : max 2 farms daily"); // max 2 farms daily (safety)
        
        Farm(farm).setWeeksRewards(rewards);
        PENGS.mint(rewards, farm);
        maxCompensation[farm] = exposure;
        newFarms[epochDay()]++;
    }
    
    
    function initiateWeeklyFarmIncentives(address farm, uint256 rewards) external {
        require(msg.sender == owner, "PolyPenguinGovernance :: initiateWeeklyFarmIncentives : Only owner");
        pendingRewards[farm] = PendingUpdate(rewards, block.timestamp + 24 hours);
    }
    
    // Requires 24 hours to pass
    function provideWeeklyFarmIncentives(address farm) external {
        PendingUpdate memory pending = pendingRewards[farm];
        require(pending.timelock > 0 && block.timestamp > pending.timelock, "PolyPenguinGovernance :: provideWeeklyFarmIncentives : Requires 24 hours to pass");
        
        Farm(farm).setWeeksRewards(pending.amount);
        PENGS.mint(pending.amount, farm);
        delete pendingRewards[farm];
    }
    
    
    function initiateUpdateFarmExposure(address farm, uint256 _PENGS) external {
        require(msg.sender == owner, "PolyPenguinGovernance :: initiateUpdateFarmExposure: only owner");
        pendingExposure[farm] = PendingUpdate(_PENGS, block.timestamp + 24 hours);
    }
    
    // Requires 24 hours to pass
    function updateFarmExposure(address farm) external {
        PendingUpdate memory pending = pendingExposure[farm];
        require(pending.timelock > 0 && block.timestamp > pending.timelock, "PolyPenguinGovernance :: updateFarmExposure : Requires 24 hours to pass");
        
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
        PENGS.mint(compensation, farm);
    }
    
    
    // After beta will transition to DAO (using below timelock upgrade)
    address public nextGov;
    uint256 public nextGovTime;
    
    function beginGovernanceRequest(address newGovernance) external {
        require(msg.sender == owner, "PolyPenguinGovernance :: beginGovernanceRequest : Only owner");
        nextGov = newGovernance;
        nextGovTime = block.timestamp + 48 hours;
    }
    
    function triggerGovernanceUpdate() external {
        require(block.timestamp > nextGovTime && nextGov != address(0), "PolyPenguinGovernance :: triggerGovernanceUpdate : Invalid newGovernance address or requires time to pass");
        PENGS.updateGovernance(nextGov);
    }
    
    function epochDay() public view returns (uint256) {
        return block.timestamp / 86400;
    }
    
    function compensationAvailable(address farm) public view returns (uint256) {
        return maxCompensation[farm];   
    }
    
}