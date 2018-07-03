pragma solidity ^0.4.18;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract TokenSale is Ownable ,Pausable {
  
  uint256 public weiRaised;       
  uint256 public saleHardcap;   
  uint256 public personalMincap;  
  uint256 public startTime;    
  uint256 public endTime;       
  bool    public isFinalized;     
  
  uint256 public mtStartTime; 
  uint256 public mtEndTime;      

  mapping (address => uint256) public beneficiaryFunded; 

  function TokenSale() public 
    { 
      startTime = 1526634000; //  (2018.05.15 09:00:00 UTC);
      endTime = 1527778800;   //  (2018.05.31 15:00:00 UTC);
      saleHardcap = 17411.9813 * (1 ether);
      personalMincap = 1 ether;
      isFinalized = false;
      weiRaised = 0x00;
    }

  function () public payable {
    buyPresale();
  }

  function buyPresale() public payable 
  whenNotPaused
  {
    address beneficiary = msg.sender;
    uint256 toFund = msg.value;  
    // check validity
    require(!isFinalized);
    require(validPurchase());   
        
    uint256 postWeiRaised = SafeMath.add(weiRaised, toFund); 
    require(postWeiRaised <= saleHardcap);

    weiRaised = SafeMath.add(weiRaised, toFund);     
    beneficiaryFunded[beneficiary] = SafeMath.add(beneficiaryFunded[msg.sender], toFund);
  }

  function validPurchase() internal constant returns (bool) {
    bool validValue = msg.value >= personalMincap;                                                       
    bool validTime = now >= startTime && now <= endTime && !checkMaintenanceTime(); 
    return validValue && !maxReached() && validTime;  
  }

  function maxReached() public constant returns (bool) {
    return weiRaised >= saleHardcap;
  }

  function getNowTime() public constant returns(uint256) {
      return now;
  }

  // Owner only Functions
  function changeStartTime( uint64 newStartTime ) public onlyOwner {
    startTime = newStartTime;
  }

  function changeEndTime( uint64 newEndTime ) public onlyOwner {
    endTime = newEndTime;
  }

  function changeSaleHardcap( uint256 newsaleHardcap ) public onlyOwner {
    saleHardcap = newsaleHardcap * (1 ether);
  }

  function changePersonalMincap( uint256 newpersonalMincap ) public onlyOwner {
    personalMincap = newpersonalMincap * (1 ether);
  }

  function FinishTokensale() public onlyOwner {
    require(maxReached() || now > endTime);
    isFinalized = true;
    
    owner.transfer(address(this).balance);
  }
  
  function changeMaintenanceTime(uint256 _starttime, uint256 _endtime) public onlyOwner{
    mtStartTime = _starttime;
    mtEndTime = _endtime;
  }
  
  function checkMaintenanceTime() public view returns (bool)
  {
    uint256 datetime = now % (60 * 60 * 24);
    return (datetime >= mtStartTime && datetime < mtEndTime);
  }

}