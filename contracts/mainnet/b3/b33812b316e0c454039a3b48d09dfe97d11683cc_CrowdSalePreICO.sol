pragma solidity ^0.4.13;

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

contract Controlled {
    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    address public controller;

    function Controlled() {
        controller = msg.sender;
    }

    address public newController;

    function changeOwner(address _newController) onlyController {
        newController = _newController;
    }

    function acceptOwnership() {
        if (msg.sender == newController) {
            controller = newController;
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
contract Haltable is Controlled {
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
  function halt() external onlyController {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyController onlyInEmergency {
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
    function setPricing() onlyController{
        uint factor = 10 ** decimals;
        priceList.push(PriceTier(uint(safeDiv(1 ether, 400 * factor)),0,5000 ether));
        priceList.push(PriceTier(uint(safeDiv(1 ether, 400 * factor)),0,1 ether));
        numTiers = 2;
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

contract CrowdSalePreICO is PricingMechanism, DAOController{
    SphereTokenFactory public tokenFactory;
    uint public hardCapAmount;
    bool public isStarted = false;
    bool public isFinalized = false;
    uint public duration = 7 days;
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
    function CrowdSalePreICO(){
        tokenFactory = SphereTokenFactory(0xf961eb0acf690bd8f92c5f9c486f3b30848d87aa);
        decimals = 4;
        setPricing();
        hardCapAmount = 5000 ether;
    }
    function startCrowdsale() onlyController {
        if (isStarted) throw;
        isStarted = true;
        startTime = now;
    }
    function setDAOAndMultiSig(address _dao, address _multiSig) onlyController{
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
    
    function finalize() payable onlyController afterFinalizeSet{
        if (hardCapAmount == totalDepositedEthers || (now - startTime) > duration){
            dao.call.gas(150000).value(totalDepositedEthers * 2 / 10)();
            multiSig.call.gas(150000).value(this.balance)();
            isFinalized = true;
        }
    }
    function emergency() payable onlyStarted onlyInEmergency onlyController afterFinalizeSet{
        isFinalized = true;
        isStarted = false;
        multiSig.call.gas(150000).value(this.balance)();
    }
}