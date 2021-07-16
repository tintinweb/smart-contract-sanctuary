//SourceUnit: tronix.sol

pragma solidity ^0.4.0;

interface TRC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface TronixConfig {
    function getTronixCostForUnit(uint256 unitId, uint256 existing, uint256 amount) public constant returns (uint256);   
    function unitSellable(uint256 unitId) external constant returns (bool);
    function unitTronCost(uint256 unitId) external constant returns (uint256);
    function unitTronixPower(uint256 unitId) external constant returns (uint256);  
    function powerUnitIdRange() external constant returns (uint256, uint256);   
    function getUnitInfo(uint256 unitId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256);
    function getCurrentNumberOfUnits() external constant returns (uint256);   
}

contract Tronixdefi is TRC20 {

    using SafeMath for uint256;
    
    string public constant name  = "Tronix DeFi";
    string public constant symbol = "TRONIX";
    uint8 public constant decimals = 6;
    uint256 private roughSupply = 1000000000;
    uint256 public totalTronixPower;
    address public owner;
    bool public tradingActive;
      
    uint256 public referralPercentage = 3;
    uint256 public devFee = 7;
    uint256 public totalTronTronixSpeedPool;

    uint256[] private totalTronixPowerSnapshots;
    uint256[] private totalTronixDepositSnapshots;
    uint256[] private allocatedTronixSpeedSnapshots;
    uint256[] private allocatedTronixDepositSnapshots;

    uint256 nextSnapshotTime;
    uint256 nextTronixDepositSnapshotTime;
    
    // Balances for each player
    mapping(address => uint256) private TronixBalance;
    mapping(address => mapping(uint256 => uint256)) private TronixPowerSnapshots;
    mapping(address => mapping(uint256 => uint256)) private TronixDepositSnapshots;
    mapping(address => mapping(uint256 => bool)) private TronixPowerZeroedSnapshots;
    
    mapping(address => address[]) public playerRefList;
    mapping(address => uint) public playerRefBonus;
    mapping(address => mapping(address => bool)) public playerRefLogged;
    
    mapping(address => uint256) private lastTronixSaveTime;
    mapping(address => uint256) private lastTronixPowerUpdate;
    
      
    // Stuff owned by each player
    mapping(address => mapping(uint256 => uint256)) private unitsOwned;
   
    // Mapping of approved ERC20 transfers (by player)
    mapping(address => mapping(address => uint256)) private allowed;
    
    event UnitBought(address player, uint256 unitId, uint256 amount); 
    event ReferalGain(address player, address referal, uint256 amount);
    
    TronixConfig schema;
    
    // Constructor
    function Tronixdefi(address schemaAddress) public payable {
        owner = msg.sender;
        schema = TronixConfig(schemaAddress);  
        
    }
        
    function() external payable  {
        // Fallback will donate to pot
        totalTronTronixSpeedPool += msg.value;
    }
 
    function initializeTronix() external payable {
        require(msg.sender == owner);	
            tradingActive = true;
            nextSnapshotTime = block.timestamp + 1 seconds;
            nextTronixDepositSnapshotTime = block.timestamp + 1 seconds;
            totalTronixDepositSnapshots.push(0);
            totalTronTronixSpeedPool += msg.value;	
	    TronixBalance[msg.sender] += 1000000000;
    }
  
    function totalSupply() public constant returns(uint256) {
        return roughSupply;
    }
  
    function balanceOf(address player) public constant returns(uint256) {
        return TronixBalance[player] + balanceOfUnclaimedTronix(player);
    }
    
    function balanceOfUnclaimedTronix(address player) internal constant returns (uint256) {
        uint256 lastSave = lastTronixSaveTime[player];
        if (lastSave > 0 && lastSave < block.timestamp) {
            return (getTronixPower(player) * (block.timestamp - lastSave)) / 100000000;
        }
        return 0;
    }

    // mitigates the ERC20 short address attack
        modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address recipient, uint256 amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        updatePlayersTronix(msg.sender);
        require(amount <= TronixBalance[msg.sender]);
        require(tradingActive);       
        TronixBalance[msg.sender] -= amount;
        TronixBalance[recipient] += amount;       
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address player, address recipient, uint256 amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        updatePlayersTronix(player);
        require(amount <= allowed[player][msg.sender] && amount <= TronixBalance[player]);
        require(tradingActive);      
        TronixBalance[player] -= amount;
        TronixBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;       
        emit Transfer(player, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address player, address approvee) public constant returns(uint256){
        return allowed[player][approvee];
    }
    
    function getTronixPower(address player) public constant returns (uint256){
        return TronixPowerSnapshots[player][lastTronixPowerUpdate[player]];
    }
    
    function updatePlayersTronix(address player) internal {
        uint256 TronixGain = balanceOfUnclaimedTronix(player);
        lastTronixSaveTime[player] = block.timestamp;
        roughSupply += TronixGain;
        TronixBalance[player] += TronixGain;
    }
    
    function updatePlayersTronixFromPurchase(address player, uint256 purchaseCost) internal {
        uint256 unclaimedTronix = balanceOfUnclaimedTronix(player);
        
        if (purchaseCost > unclaimedTronix) {
            uint256 TronixDecrease = purchaseCost - unclaimedTronix;
            require(TronixBalance[player] >= TronixDecrease);
            roughSupply -= TronixDecrease;
            TronixBalance[player] -= TronixDecrease;
        } else {
            uint256 TronixGain = unclaimedTronix - purchaseCost;
            roughSupply += TronixGain;
            TronixBalance[player] += TronixGain;
        }
        
        lastTronixSaveTime[player] = block.timestamp;
    }
    
    function increasePlayersTronixPower(address player, uint256 increase) internal {
        TronixPowerSnapshots[player][allocatedTronixSpeedSnapshots.length] = getTronixPower(player) + increase;
        lastTronixPowerUpdate[player] = allocatedTronixSpeedSnapshots.length;
        totalTronixPower += increase;
    }
    
    
    function startTronix(uint256 unitId, uint256 amount) external payable {
        require(msg.sender == owner);
        uint256 schemaUnitId;
        uint256 TronixPower;
        uint256 TronixCost;
        uint256 tronCost;	
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, TronixPower, TronixCost, tronCost) = schema.getUnitInfo(unitId, existing, amount);
        require(schemaUnitId > 0);
        require(msg.value >= tronCost);
        uint256 devFund = SafeMath.div(SafeMath.mul(tronCost, devFee), 100);
        uint256 dividends = tronCost - devFund;
        totalTronTronixSpeedPool += dividends;       
        uint256 newTotal = SafeMath.add(existing, amount);      
        // Update players
        updatePlayersTronixFromPurchase(msg.sender, TronixCost);    
        if (TronixPower > 0) {
            increasePlayersTronixPower(msg.sender, getUnitsPower(msg.sender, unitId, amount));
        }      
        unitsOwned[msg.sender][unitId] += amount;	
        emit UnitBought(msg.sender, unitId, amount);
        feeSplit(devFund);	
    }
      
    function buyTronUnit(address referer, uint256 unitId, uint256 amount) external payable {
        uint256 schemaUnitId;
        uint256 TronixPower;
        uint256 TronixCost;
        uint256 tronCost;
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, TronixPower, TronixCost, tronCost) = schema.getUnitInfo(unitId, existing, amount);      
        require(schemaUnitId > 0);
        require(msg.value >= tronCost);
        uint256 devFund = SafeMath.div(SafeMath.mul(tronCost, devFee), 100);
        uint256 dividends = (tronCost - devFund);
        uint256 newTotal = SafeMath.add(existing, amount);   
        // Update players Tronix
        updatePlayersTronixFromPurchase(msg.sender, TronixCost);
        if (TronixPower > 0) {
            increasePlayersTronixPower(msg.sender, getUnitsPower(msg.sender, unitId, amount));
        }      
        unitsOwned[msg.sender][unitId] += amount;
        emit UnitBought(msg.sender, unitId, amount);
        feeSplit(devFund);       
        totalTronixPowerSnapshots.push(totalTronixPower);      
        uint256 referalDivs;
            if (referer != address(0) && referer != msg.sender) {
                referalDivs = (tronCost * referralPercentage) / 100;
                referer.send(referalDivs);
                playerRefBonus[referer] += referalDivs;
                if (!playerRefLogged[referer][msg.sender]) {
                    playerRefLogged[referer][msg.sender] = true;
                    playerRefList[referer].push(msg.sender);
                }
                emit ReferalGain(referer, msg.sender, referalDivs);
            }

            totalTronTronixSpeedPool += (dividends - referalDivs);
    }     
          

    function unstakeTronix(uint256 unstakeAmount) external {
	 updatePlayersTronix(msg.sender);
	 uint256 playerpower = getTronixPower(msg.sender);
	 uint256 maxUnstackable = SafeMath.div(playerpower,10000000);
	 require (unstakeAmount >= 1);
	 require(unstakeAmount <= maxUnstackable); 
         totalTronTronixSpeedPool -= SafeMath.mul(unstakeAmount,900000);
         msg.sender.transfer(SafeMath.mul(unstakeAmount,900000));	
	 reducePlayersTronixPower(msg.sender, SafeMath.mul(unstakeAmount,10000000));
	 unitsOwned[msg.sender][2] -= unstakeAmount;  
        
    }

    function reducePlayersTronixPower(address player, uint256 decrease) internal {
        uint256 previousPower = getTronixPower(player);
        uint256 newPower = SafeMath.sub(previousPower, decrease);       
        TronixPowerSnapshots[player][allocatedTronixSpeedSnapshots.length] = newPower;      
        lastTronixPowerUpdate[player] = allocatedTronixSpeedSnapshots.length;
        totalTronixPower -= decrease;
    }
        
    function feeSplit(uint value) internal {
        uint a = value;
        owner.send(a);        
    }
    
    function getUnitsPower(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return ((amount * schema.unitTronixPower(unitId)) * 10);
    }
          
    function getPlayerRefs(address player) public view returns (uint) {
        return playerRefList[player].length;
    }
  
    
    // To display on website
    function getTronixInfo() external constant returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[], uint256){
        
        uint256[] memory units = new uint256[](schema.getCurrentNumberOfUnits());     
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.powerUnitIdRange();     
        uint256 i;
        while (startId <= endId) {
            units[i] = unitsOwned[msg.sender][startId];
            i++;
            startId++;
        }      
        
        return (block.timestamp, totalTronTronixSpeedPool, totalTronixPower, totalTronixDepositSnapshots[totalTronixDepositSnapshots.length - 1],  TronixDepositSnapshots[msg.sender][totalTronixDepositSnapshots.length - 1],
        nextSnapshotTime, balanceOf(msg.sender), getTronixPower(msg.sender), units, nextTronixDepositSnapshotTime);
    }
    
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}