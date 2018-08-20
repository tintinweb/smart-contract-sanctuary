pragma solidity ^0.4.18 ;


contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  
  constructor() public {
    owner = msg.sender;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
   
   
   
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
   
   
   
    return a / b;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ContractiumInterface {
    function balanceOf(address who) public view returns (uint256);
    function contractSpend(address _from, uint256 _value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    function owner() public view returns (address);

    function bonusRateOneEth() public view returns (uint256);
    function currentTotalTokenOffering() public view returns (uint256);
    function currentTokenOfferingRaised() public view returns (uint256);

    function isOfferingStarted() public view returns (bool);
    function offeringEnabled() public view returns (bool);
    function startTime() public view returns (uint256);
    function endTime() public view returns (uint256);
}


contract ContractiumKrypStrong is Ownable {

    using SafeMath for uint256;

    ContractiumInterface ctuContract;
    address public constant KRYPSTRONG = 0x9808bA6d86119ed7a801Cde0bdFE7FF4dC5b5298;
    address public constant CONTRACTIUM = 0x943ACa8ed65FBf188A7D369Cfc2BeE0aE435ee1B;
    address public ownerCtuContract;
    address public owner;

    uint8 public constant decimals = 18;
    uint256 public unitsOneEthCanBuy = 15000;

   
    uint256 public currentTokenOfferingRaised;

    function() public payable {

        require(msg.sender != owner);

       
        uint256 bonusRateOneEth = ctuContract.bonusRateOneEth();

       
        uint256 amount = msg.value.mul(unitsOneEthCanBuy);

       
        uint256 amountBonus = msg.value.mul(bonusRateOneEth);
        
       
        amount = amount.add(amountBonus);

       
        uint256 remain = ctuContract.balanceOf(ownerCtuContract);
        require(remain >= amount);
        preValidatePurchase(amount);

       
        address _from = ownerCtuContract;
        address _to = msg.sender;
        require(ctuContract.transferFrom(_from, _to, amount));
        
       
        currentTokenOfferingRaised = currentTokenOfferingRaised.add(amount);  

       
        uint256 oneHundredth = msg.value.div(100);
        uint256 sevenHundredths = oneHundredth.mul(7);
        uint256 ninetyThreeHundredths = msg.value.sub(sevenHundredths);

        KRYPSTRONG.transfer(sevenHundredths);
        ownerCtuContract.transfer(ninetyThreeHundredths);  
    }

    constructor() public {
        ctuContract = ContractiumInterface(CONTRACTIUM);
        ownerCtuContract = ctuContract.owner();
        owner = msg.sender;
    }

    
    function preValidatePurchase(uint256 _amount) internal {
        bool isOfferingStarted = ctuContract.isOfferingStarted();
        bool offeringEnabled = ctuContract.offeringEnabled();
        uint256 startTime = ctuContract.startTime();
        uint256 endTime = ctuContract.endTime();
        uint256 currentTotalTokenOffering = ctuContract.currentTotalTokenOffering();
        uint256 currentTokenOfferingRaisedContractium = ctuContract.currentTokenOfferingRaised();

        require(_amount > 0);
        require(isOfferingStarted);
        require(offeringEnabled);
        require(currentTokenOfferingRaised.add(currentTokenOfferingRaisedContractium.add(_amount)) <= currentTotalTokenOffering);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
    }
    
    
    function setCtuContract(address _ctuAddress) public onlyOwner {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        ownerCtuContract = ctuContract.owner();
    }

    
    function resetCurrentTokenOfferingRaised() public onlyOwner {
        currentTokenOfferingRaised = 0;
    }
}