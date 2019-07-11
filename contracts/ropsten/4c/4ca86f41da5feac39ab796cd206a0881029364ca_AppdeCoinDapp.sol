/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.24;

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

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
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

/** Author : Hamza Yasin 
            (Github: HamzaYasin1) 
            (Linkedin: linkedin.com/in/hamzayasin)             
*/

contract AppdeCoinDapp  is Ownable {
   
    enum BuyStatus { Locked, Completed }
    event addressWhiteListed(address _address, bool whiteListed);
    event contributed(address _customer, uint _ethamount, uint _tokenamount);
    event released(address _customer, uint _tokenValue);
    event withdrawEthers(uint _value);
    event withdrawTokenss(uint _value);
    
    using SafeMath for uint;
    
    ERC20 public currency;
    uint startTime;
    uint endTime;
    uint weiRaised;
    address collectionAddress;
    uint public customerCount;
    uint public rate;
    
    struct Buy {
        uint customerId;
        address customer;
        uint ethValue;
        uint tokenValue;
        uint timeLock;
        BuyStatus status;
        bool paymentMade;
    }
   
   mapping(address => Buy) public buy;
   mapping(uint => Buy) public buyid;
   
   mapping(address=>bool) public whiteListedAddresses;
   
   constructor (uint _startTime, uint _endTime, ERC20 _currency, uint _rate, address _collectionAddress) public {
        currency = _currency;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        customerCount = 0;
        collectionAddress = _collectionAddress;
        
   }

    function () external payable {
        contribute(msg.sender);
    }
    
   function contribute(address _customer) public payable {
    require(whiteListedAddresses[_customer] == true);
    require(!isEnded());
    require(isStardted());
    
    uint weiAmount =  msg.value;
    preValidatePurchase(_customer, weiAmount);
     
    buy[_customer].customerId = customerCount;
    buy[_customer].customer = _customer;
    buy[_customer].ethValue = weiAmount;
       
    buy[_customer].tokenValue = (weiAmount * rate);
    buy[_customer].status = BuyStatus.Locked;
    buy[_customer].timeLock = SafeMath.add(now, 2 minutes);
    buy[_customer].paymentMade = false;
      
    weiRaised = weiRaised.add(weiAmount);
    updateID(_customer, weiAmount);
    emit contributed(_customer, weiAmount, (weiAmount * rate));
       
   }
   
   function preValidatePurchase(address beneficiary, uint weiAmount) internal pure {
        require(beneficiary != address(0), "beneficiary is the zero address");
        require(weiAmount != 0, "weiAmount is 0");
    }
    
   function isEnded() public view returns(bool) {
       if (now >= endTime)
       return true;
   }
   
    function isStardted() public view returns(bool) {
       if (now >= startTime)
       return true;
   }
   
   function setRate(uint _newRate) public onlyOwner {
       rate = _newRate;
   }
   
   function getRate() public view returns (uint) {
       return rate;
   }
   
   function createPayment(address _customer, uint _value) public onlyOwner {
      require(whiteListedAddresses[_customer] == true);
      
      buy[_customer].customerId = customerCount;
      buy[_customer].customer = _customer;
      buy[_customer].ethValue = _value;
       
      buy[_customer].tokenValue = (_value * rate);
      buy[_customer].status = BuyStatus.Locked;
      buy[_customer].timeLock = SafeMath.add(now, 2 minutes);
      buy[_customer].paymentMade = false;
      
      updateID(_customer, _value);
      emit contributed(_customer, _value, (_value * rate));
   }
   
   function updateID(address _customer, uint _value) internal {
      require(whiteListedAddresses[_customer] == true);
      
      buyid[customerCount].customerId = customerCount;
      buyid[customerCount].customer = _customer;
      buyid[customerCount].ethValue = _value;
       
      buyid[customerCount].tokenValue = (_value * rate);
      buyid[customerCount].status = BuyStatus.Locked;
      buyid[customerCount].timeLock = SafeMath.add(now, 2 minutes);
      buyid[customerCount].paymentMade = false;
      
      customerCount = customerCount.add(1);    
   }
   
   function whiteListAddress(address _customer, bool whiteListed) public onlyOwner {
        whiteListedAddresses[_customer] = whiteListed;
        emit addressWhiteListed(_customer, whiteListed);
    }
   
   function releaseTokens() external onlyOwner {

       for (uint i = 0; i < customerCount; i++){
            require(buyid[i].customer != address(0), "beneficiary is the zero address");
               if (buyid[i].paymentMade == false && buyid[i].timeLock < now) {
                   
                    currency.transfer(buyid[i].customer, buyid[i].tokenValue);
                    buyid[i].paymentMade = true;
                    buyid[i].status = BuyStatus.Completed;
                    emit released(buyid[i].customer, buyid[i].tokenValue);
               }
              
       }    
   }
   
   function manualRelease(address _customer, uint _tokenamount) external onlyOwner {
       require(buy[_customer].timeLock < now);
       currency.transfer(_customer, _tokenamount);
       emit released(_customer, _tokenamount);
   }
   
   function withdrawEther() external  onlyOwner {
       collectionAddress.transfer(address(this).balance);
       emit withdrawEthers(address(this).balance);
   }
   
   function withdrawTokens(uint _amount) external onlyOwner {
       currency.transfer(collectionAddress, _amount);
       emit withdrawTokenss(_amount);
   }
   
   
}