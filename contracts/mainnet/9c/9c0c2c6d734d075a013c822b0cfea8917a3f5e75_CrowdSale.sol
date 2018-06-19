pragma solidity ^0.4.11;

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}


contract SphereTokenFactory{
	function mint(address target, uint amount);
}
/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Owned {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract PricingMechanism is Haltable, SafeMath{
    uint public decimals;
    PriceTier[] public priceList;
    uint8 public numTiers;
    uint public currentTierIndex;
    uint public totalDepositedEthers;
    
    struct  PriceTier {
        uint costPerToken;
        uint ethersDepositedInTier;
        uint maxEthersInTier;
    }
    function setPricing() onlyOwner{
        uint factor = 10 ** decimals;
        priceList.push(PriceTier(uint(safeDiv(1 ether, 100 * factor)),0,5000 ether));
        priceList.push(PriceTier(uint((1 ether - (10 wei * factor)) / (90 * factor)),0,5000 ether));
        priceList.push(PriceTier(uint(1 ether / (80* factor)),0,5000 ether));
        priceList.push(PriceTier(uint((1 ether - (50 wei * factor)) / (70* factor)),0,5000 ether));
        priceList.push(PriceTier(uint((1 ether - (40 wei * factor)) / (60* factor)),0,5000 ether));
        priceList.push(PriceTier(uint(1 ether / (50* factor)),0,5000 ether));
        priceList.push(PriceTier(uint(1 ether / (40* factor)),0,5000 ether));
        priceList.push(PriceTier(uint((1 ether - (10 wei * factor))/ (30* factor)),0,5000 ether));
        priceList.push(PriceTier(uint((1 ether - (10 wei * factor))/ (15* factor)),0,30000 ether));
        numTiers = 9;
    }
    function allocateTokensInternally(uint value) internal constant returns(uint numTokens){
        if (numTiers == 0) return 0;
        numTokens = 0;
        uint8 tierIndex = 0;
        for (uint8 i = 0; i < numTiers; i++){
            if (priceList[i].ethersDepositedInTier < priceList[i].maxEthersInTier){
                uint ethersToDepositInTier = min256(priceList[i].maxEthersInTier - priceList[i].ethersDepositedInTier, value);
                numTokens = safeAdd(numTokens, ethersToDepositInTier / priceList[i].costPerToken);
                priceList[i].ethersDepositedInTier = safeAdd(ethersToDepositInTier, priceList[i].ethersDepositedInTier);
                totalDepositedEthers = safeAdd(ethersToDepositInTier, totalDepositedEthers);
                value = safeSub(value, ethersToDepositInTier);
                if (priceList[i].ethersDepositedInTier > 0)
                    tierIndex = i;
            }
        }
        currentTierIndex = tierIndex;
        return numTokens;
    }
    
}

contract DAOController{
    address public dao;
    modifier onlyDAO{
        if (msg.sender != dao) throw;
        _;
    }
}

contract CrowdSale is PricingMechanism, DAOController{
    SphereTokenFactory public tokenFactory;
    uint public hardCapAmount;
    bool public isStarted = false;
    bool public isFinalized = false;
    uint public duration = 30 days;
    uint public startTime;
    address public multiSig;
    bool public finalizeSet = false;
    
    modifier onlyStarted{
        if (!isStarted) throw;
        _;
    }
    modifier notFinalized{
        if (isFinalized) throw;
        _;
    }
    modifier afterFinalizeSet{
        if (!finalizeSet) throw;
        _;
    }
    function CrowdSale(){
        tokenFactory = SphereTokenFactory(0xf961eb0acf690bd8f92c5f9c486f3b30848d87aa);
        decimals = 4;
        setPricing();
        hardCapAmount = 75000 ether;
    }
    function startCrowdsale() onlyOwner {
        if (isStarted) throw;
        isStarted = true;
        startTime = now;
    }
    function setDAOAndMultiSig(address _dao, address _multiSig) onlyOwner{
        dao = _dao;
        multiSig = _multiSig;
        finalizeSet = true;
    }
    function() payable stopInEmergency onlyStarted notFinalized{
        if (totalDepositedEthers >= hardCapAmount) throw;
        uint contribution = msg.value;
        if (safeAdd(totalDepositedEthers, msg.value) > hardCapAmount){
            contribution = safeSub(hardCapAmount, totalDepositedEthers);
        }
        uint excess = safeSub(msg.value, contribution);
        uint numTokensToAllocate = allocateTokensInternally(contribution);
        tokenFactory.mint(msg.sender, numTokensToAllocate);
        if (excess > 0){
            msg.sender.send(excess);
        }
    }
    
    function finalize() payable onlyOwner afterFinalizeSet{
        if (hardCapAmount == totalDepositedEthers || (now - startTime) > duration){
            dao.call.gas(150000).value(totalDepositedEthers * 3 / 10)();
            multiSig.call.gas(150000).value(this.balance)();
            isFinalized = true;
        }
    }
    function emergencyCease() payable onlyStarted onlyInEmergency onlyOwner afterFinalizeSet{
        isFinalized = true;
        isStarted = false;
        multiSig.call.gas(150000).value(this.balance)();
    }
}