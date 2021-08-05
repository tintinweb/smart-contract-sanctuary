/**
 *Submitted for verification at Etherscan.io on 2020-12-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

/**
 * TRY TOKENS ARE AUTOMATICALLY RETURNED TO ETH WALLET THAT SENT THE ETH.  DO NOT USE EXCHANGES TO PURCHASE IN THIS PRESALE.
 * 60% of ETH raised will be forwarded automatically to TRY token contract and be allocated for initial liquidity. ETH sent 
 * to TRY token contract can only be used to createUNISwapPair, it cannot be withdrawn for any other reasons.
 */
 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  address payable owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = payable(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface TRYToken {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address _owner) external returns (uint256 balance);
    function mint(address wallet, address buyer, uint256 tokenAmount) external;
    function showMyTokenBalance(address addr) external;
}

contract TRYpresale is Ownable {
    
    using SafeMath for uint256;
    
    uint256 public startTime;
    uint256 public endTime;
  
    mapping(address=>uint256) public ownerAddresses;  
    mapping(address=>uint256) public BuyerList;
    address payable[] owners;
    
    uint256 public MAX_BUY_LIMIT = 3000000000000000000;
    uint256 public majorOwnerShares = 100;
    uint256 public minorOwnerShares = 60;
    uint256 public coinPercentage = 0;
  
  
    uint public referralReward = 5;
    uint256 public rate = 200;

    uint256 public weiRaised;
  
    bool public isPresaleStopped = false;
  
    bool public isPresalePaused = false;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transfered(address indexed purchaser, address indexed referral, uint256 amount);

  
    TRYToken public token;
    
    
    constructor(address payable _walletMajorOwner) 
    {
        token = TRYToken(0xc12eCeE46ed65D970EE5C899FCC7AE133AfF9b03); 
        
        
        startTime = 1609603200;   
        endTime = startTime + 7 days;
        
       
        require(endTime >= startTime);
        require(_walletMajorOwner != address(0));
        
        ownerAddresses[_walletMajorOwner] = majorOwnerShares;
        
        owners.push(_walletMajorOwner);
        
        owner = _walletMajorOwner;
    }
    
    fallback() external payable {
        buy(msg.sender, owner);
    }
    
    receive() external payable {}
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        
        return (size > 0);
    }
    
    function buy(address beneficiary, address payable referral) public payable
    {
        require (isPresaleStopped != true, 'Presale is stopped');
        require (isPresalePaused != true, 'Presale is paused');
        require ( !(isContract(msg.sender)), 'Bots not allowed');
        require(beneficiary != address(0), 'user asking for tokens sent to be on 0 address');
        require(validPurchase(), 'its not a valid purchase');
        require(BuyerList[msg.sender] < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT Achieved already for this wallet');
        uint256 weiAmount = msg.value;
        require(weiAmount <3000000000000000001 , 'MAX_BUY_LIMIT is 3 ETH'); 
        uint256 tokens = weiAmount.mul(rate);
        
        uint256 weiMinusfee = msg.value - (msg.value * referralReward / 100);
        uint256 refReward = msg.value * referralReward / 100;
        
        weiRaised = weiRaised.add(weiAmount);
        splitFunds(referral, refReward);
        
        token.transfer(beneficiary,tokens);
         uint partnerCoins = tokens.mul(coinPercentage);
        partnerCoins = partnerCoins.div(100);
        
        BuyerList[msg.sender] = BuyerList[msg.sender].add(msg.value);
        
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds(partnerCoins, weiMinusfee);
    }
    
    function splitFunds(address payable _b, uint256 amount) internal {

        _b.transfer(amount);
        
         emit Transfered(msg.sender, _b, amount);
    }
    
    function forwardFunds(uint256 partnerTokenAmount, uint256 weiMinusfee) internal {
      for (uint i=0;i<owners.length;i++)
      {
         uint percent = ownerAddresses[owners[i]];
         uint amountToBeSent = weiMinusfee.mul(percent);
         amountToBeSent = amountToBeSent.div(100);
         owners[i].transfer(amountToBeSent);
         
         if (owners[i]!=owner &&  ownerAddresses[owners[i]]>0)
         {
             token.transfer(owners[i],partnerTokenAmount);
         }
      }
    }
 
    function addLiquidityPool(address payable partner) public onlyOwner {

        require(partner != address(0));
        require(ownerAddresses[owner] >=40);
        require(ownerAddresses[partner] == 0);
        owners.push(partner);
        ownerAddresses[partner] = 60;
        uint majorOwnerShare = ownerAddresses[owner];
        ownerAddresses[owner] = majorOwnerShare.sub(60);
    }

    function removeLiquidityPool(address partner) public onlyOwner  {
        require(partner != address(0));
        require(ownerAddresses[partner] >= 60);
        require(ownerAddresses[owner] <= 40);
        ownerAddresses[partner] = 0;
        uint majorOwnerShare = ownerAddresses[owner];
        ownerAddresses[owner] = majorOwnerShare.add(60);
    }

    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }
  
    function showMyTokenBalance(address myAddress) public returns (uint256 tokenBalance) {
       tokenBalance = token.balanceOf(myAddress);
    }

    function setEndDate(uint256 daysToEndFromToday) public onlyOwner returns(bool) {
        daysToEndFromToday = daysToEndFromToday * 1 days;
        endTime = block.timestamp + daysToEndFromToday;
        return true;
    }

    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
         return true;
    }
    
    function setReferralReward(uint256 newReward) public onlyOwner returns (bool) {
        referralReward = newReward;
         return true;
    }

    function pausePresale() public onlyOwner returns(bool) {
        isPresalePaused = true;
         return isPresalePaused;
    }

    function resumePresale() public onlyOwner returns (bool) {
        isPresalePaused = false;
        return !isPresalePaused;
    }
    
    function stopPresale() public onlyOwner returns (bool) {
        isPresaleStopped = true;
        return true;
    }

    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        startTime = block.timestamp; 
        return true;
    }
    
    function tokensRemainingForSale(address contractAddress) public returns (uint balance) {
        balance = token.balanceOf(contractAddress);
    }

    function checkOwnerShare (address owner) public view onlyOwner returns (uint) {
        uint share = ownerAddresses[owner];
        return share;
    }
}