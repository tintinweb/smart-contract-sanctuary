//SourceUnit: ORACLETX.sol

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

interface OracletxConfig {
    function getOracletxCostForUnit(uint256 unitId, uint256 existing, uint256 amount) public constant returns (uint256);   
    function unitSellable(uint256 unitId) external constant returns (bool);
    function unitTronCost(uint256 unitId) external constant returns (uint256);
    function unitOracletxPower(uint256 unitId) external constant returns (uint256);  
    function powerUnitIdRange() external constant returns (uint256, uint256);   
    function getUnitInfo(uint256 unitId, uint256 existing, uint256 amount) external constant returns (uint256, uint256, uint256, uint256);
    function getCurrentNumberOfUnits() external constant returns (uint256);   
}

contract Oracletxdefi is TRC20 {

    using SafeMath for uint256;
    
    string public constant name  = "OracleTx";
    string public constant symbol = "OCTX";
    uint8 public constant decimals = 6;
    uint256 private roughSupply = 1000000000;
    uint256 public totalOracletxPower;
    address public owner;
    bool public tradingActive;
      
    uint256 public referralPercentage = 3;
    uint256 public devFee = 7;
    uint256 public totalTronOracletxSpeedPool;

    uint256[] private totalOracletxPowerSnapshots;
    uint256[] private totalOracletxDepositSnapshots;
    uint256[] private allocatedOracletxSpeedSnapshots;
    uint256[] private allocatedOracletxDepositSnapshots;

    uint256 nextSnapshotTime;
    uint256 nextOracletxDepositSnapshotTime;
    
    // Balances for each player
    mapping(address => uint256) private OracletxBalance;
    mapping(address => mapping(uint256 => uint256)) private OracletxPowerSnapshots;
    mapping(address => mapping(uint256 => uint256)) private OracletxDepositSnapshots;
    mapping(address => mapping(uint256 => bool)) private OracletxPowerZeroedSnapshots;
    
    mapping(address => address[]) public playerRefList;
    mapping(address => uint) public playerRefBonus;
    mapping(address => mapping(address => bool)) public playerRefLogged;
    
    mapping(address => uint256) private lastOracletxSaveTime;
    mapping(address => uint256) private lastOracletxPowerUpdate;
    
      
    // Stuff owned by each player
    mapping(address => mapping(uint256 => uint256)) private unitsOwned;
   
    // Mapping of approved ERC20 transfers (by player)
    mapping(address => mapping(address => uint256)) private allowed;
    
    event UnitBought(address player, uint256 unitId, uint256 amount); 
    event ReferalGain(address player, address referal, uint256 amount);
    
    OracletxConfig schema;
    
    // Constructor
    function Oracletxdefi(address schemaAddress) public payable {
        owner = msg.sender;
        schema = OracletxConfig(schemaAddress);  
        
    }
        
    function() external payable  {
        // Fallback will donate to pot
        totalTronOracletxSpeedPool += msg.value;
    }
 
    function initializeOracletx() external payable {
        require(msg.sender == owner);	
            tradingActive = true;
            nextSnapshotTime = block.timestamp + 1 seconds;
            nextOracletxDepositSnapshotTime = block.timestamp + 1 seconds;
            totalOracletxDepositSnapshots.push(0);
            totalTronOracletxSpeedPool += msg.value;	
	    OracletxBalance[msg.sender] += 1000000000;
    }
  
    function totalSupply() public constant returns(uint256) {
        return roughSupply;
    }
  
    function balanceOf(address player) public constant returns(uint256) {
        return OracletxBalance[player] + balanceOfUnclaimedOracletx(player);
    }
    
    function balanceOfUnclaimedOracletx(address player) internal constant returns (uint256) {
        uint256 lastSave = lastOracletxSaveTime[player];
        if (lastSave > 0 && lastSave < block.timestamp) {
            return (getOracletxPower(player) * (block.timestamp - lastSave)) / 100000000;
        }
        return 0;
    }

    // mitigates the ERC20 short address attack
        modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address recipient, uint256 amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        updatePlayersOracletx(msg.sender);
        require(amount <= OracletxBalance[msg.sender]);
        require(tradingActive);       
        OracletxBalance[msg.sender] -= amount;
        OracletxBalance[recipient] += amount;       
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address player, address recipient, uint256 amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        updatePlayersOracletx(player);
        require(amount <= allowed[player][msg.sender] && amount <= OracletxBalance[player]);
        require(tradingActive);      
        OracletxBalance[player] -= amount;
        OracletxBalance[recipient] += amount;
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
    
    function getOracletxPower(address player) public constant returns (uint256){
        return OracletxPowerSnapshots[player][lastOracletxPowerUpdate[player]];
    }
    
    function updatePlayersOracletx(address player) internal {
        uint256 OracletxGain = balanceOfUnclaimedOracletx(player);
        lastOracletxSaveTime[player] = block.timestamp;
        roughSupply += OracletxGain;
        OracletxBalance[player] += OracletxGain;
    }
    
    function updatePlayersOracletxFromPurchase(address player, uint256 purchaseCost) internal {
        uint256 unclaimedOracletx = balanceOfUnclaimedOracletx(player);
        
        if (purchaseCost > unclaimedOracletx) {
            uint256 OracletxDecrease = purchaseCost - unclaimedOracletx;
            require(OracletxBalance[player] >= OracletxDecrease);
            roughSupply -= OracletxDecrease;
            OracletxBalance[player] -= OracletxDecrease;
        } else {
            uint256 OracletxGain = unclaimedOracletx - purchaseCost;
            roughSupply += OracletxGain;
            OracletxBalance[player] += OracletxGain;
        }
        
        lastOracletxSaveTime[player] = block.timestamp;
    }
    
    function increasePlayersOracletxPower(address player, uint256 increase) internal {
        OracletxPowerSnapshots[player][allocatedOracletxSpeedSnapshots.length] = getOracletxPower(player) + increase;
        lastOracletxPowerUpdate[player] = allocatedOracletxSpeedSnapshots.length;
        totalOracletxPower += increase;
    }
    
    
    function startOracletx(uint256 unitId, uint256 amount) external payable {
        require(msg.sender == owner);
        uint256 schemaUnitId;
        uint256 OracletxPower;
        uint256 OracletxCost;
        uint256 tronCost;	
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, OracletxPower, OracletxCost, tronCost) = schema.getUnitInfo(unitId, existing, amount);
        require(schemaUnitId > 0);
        require(msg.value >= tronCost);
        uint256 devFund = SafeMath.div(SafeMath.mul(tronCost, devFee), 100);
        uint256 dividends = tronCost - devFund;
        totalTronOracletxSpeedPool += dividends;       
        uint256 newTotal = SafeMath.add(existing, amount);      
        // Update players
        updatePlayersOracletxFromPurchase(msg.sender, OracletxCost);    
        if (OracletxPower > 0) {
            increasePlayersOracletxPower(msg.sender, getUnitsPower(msg.sender, unitId, amount));
        }      
        unitsOwned[msg.sender][unitId] += amount;	
        emit UnitBought(msg.sender, unitId, amount);
        feeSplit(devFund);	
    }
      
    function buyTronUnit(address referer, uint256 unitId, uint256 amount) external payable {
        uint256 schemaUnitId;
        uint256 OracletxPower;
        uint256 OracletxCost;
        uint256 tronCost;
        uint256 existing = unitsOwned[msg.sender][unitId];
        (schemaUnitId, OracletxPower, OracletxCost, tronCost) = schema.getUnitInfo(unitId, existing, amount);      
        require(schemaUnitId > 0);
        require(msg.value >= tronCost);
        uint256 devFund = SafeMath.div(SafeMath.mul(tronCost, devFee), 100);
        uint256 dividends = (tronCost - devFund);
        uint256 newTotal = SafeMath.add(existing, amount);   
        // Update players Oracletx
        updatePlayersOracletxFromPurchase(msg.sender, OracletxCost);
        if (OracletxPower > 0) {
            increasePlayersOracletxPower(msg.sender, getUnitsPower(msg.sender, unitId, amount));
        }      
        unitsOwned[msg.sender][unitId] += amount;
        emit UnitBought(msg.sender, unitId, amount);
        feeSplit(devFund);       
        totalOracletxPowerSnapshots.push(totalOracletxPower);      
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

            totalTronOracletxSpeedPool += (dividends - referalDivs);
    }     
          

    function unstakeOracletx(uint256 unstakeAmount) external {
	 updatePlayersOracletx(msg.sender);
	 uint256 playerpower = getOracletxPower(msg.sender);
	 uint256 maxUnstackable = SafeMath.div(playerpower,10000000);
	 require (unstakeAmount >= 1);
	 require(unstakeAmount <= maxUnstackable); 
         totalTronOracletxSpeedPool -= SafeMath.mul(unstakeAmount,900000);
         msg.sender.transfer(SafeMath.mul(unstakeAmount,900000));	
	 reducePlayersOracletxPower(msg.sender, SafeMath.mul(unstakeAmount,10000000));
	 unitsOwned[msg.sender][2] -= unstakeAmount;  
        
    }

    function reducePlayersOracletxPower(address player, uint256 decrease) internal {
        uint256 previousPower = getOracletxPower(player);
        uint256 newPower = SafeMath.sub(previousPower, decrease);       
        OracletxPowerSnapshots[player][allocatedOracletxSpeedSnapshots.length] = newPower;      
        lastOracletxPowerUpdate[player] = allocatedOracletxSpeedSnapshots.length;
        totalOracletxPower -= decrease;
    }
        
    function feeSplit(uint value) internal {
        uint a = value;
        owner.send(a);        
    }
    
    function getUnitsPower(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return ((amount * schema.unitOracletxPower(unitId)) * 10);
    }
          
    function getPlayerRefs(address player) public view returns (uint) {
        return playerRefList[player].length;
    }
  
    
    // To display on website
    function getOracletxInfo() external constant returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[], uint256){
        
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
        
        return (block.timestamp, totalTronOracletxSpeedPool, totalOracletxPower, totalOracletxDepositSnapshots[totalOracletxDepositSnapshots.length - 1],  OracletxDepositSnapshots[msg.sender][totalOracletxDepositSnapshots.length - 1],
        nextSnapshotTime, balanceOf(msg.sender), getOracletxPower(msg.sender), units, nextOracletxDepositSnapshotTime);
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