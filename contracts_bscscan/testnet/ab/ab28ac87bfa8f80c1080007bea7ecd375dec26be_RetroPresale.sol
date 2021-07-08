/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-29
*/

// RushMoon PROJECT Presale Contract, https://rushmoon.finance

// "SPDX-License-Identifier: MIT Retro DeFi"

pragma solidity ^0.7.6;
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
contract Whitelisted is Ownable {

    mapping (address => uint8) public whitelist;
    mapping (address => bool) public provider;

      // Only whitelisted
      modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender));
        _;
      }

      modifier onlyProvider {
        require(isProvider(msg.sender));
        _;
      }

      function isProvider(address _provider) public view returns (bool){
        return provider[_provider] == true ? true : false;
      }
      // Set new provider
      function setProvider(address _provider) public onlyOwner {
         provider[_provider] = true;
      }
      // Deactive current provider
      function deactivateProvider(address _provider) public onlyOwner {
         require(provider[_provider] == true);
         provider[_provider] = false;
      }
      // Set purchaser to whitelist with zone code
      function joinWhitelist(address _purchaser, uint8 _zone) public {
         whitelist[_purchaser] = _zone;
      }
      // Delete purchaser from whitelist
      function deleteFromWhitelist(address _purchaser) public onlyOwner {
         whitelist[_purchaser] = 0;
      }
      // Get purchaser zone code
      function getWhitelistedZone(address _purchaser) public view returns(uint8) {
        return whitelist[_purchaser] > 0 ? whitelist[_purchaser] : 0;
      }
      // Check if purchaser is whitelisted : return true or false
      function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
      }
}

interface RTRTOKEN {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract RetroPresale is Ownable ,Whitelisted {
    
    using SafeMath for uint256;
    
    uint256 public startTime;
    uint256 public endTime;
    uint256 public targetClaimTime;


    mapping(address=>uint256) public ownerAddresses;  
    mapping(address=>uint256) public buyersList;
    address public _burnaddress = 0x000000000000000000000000000000000000dEaD;
    address payable[] owners;

    uint256 public MAX_BUY_LIMIT = 500000000000000000000000;
    uint256 public majorOwnerShares = 100;
    uint256 public rate = 5e5;
    uint256 public weiRaised;
    uint256 public weiRaisedUpdated;
    uint256 public ownerShare = 1;
    address payable _pcswAddr;

    bool public isPresaleStopped = false;
  
    bool public isPresalePaused = false;
    
    event TokenPurchase(address indexed purchaser, uint256 amount);
    event Transfered(address indexed purchaser, uint256 amount);
    event AddedLiquidityToPool(uint256 amount);


    RTRTOKEN public token;
    
    constructor(address payable _walletMajorOwner, address _token, uint256 _startTime, uint256 _endTime){
        token = RTRTOKEN(_token); //Token Contract
        startTime = _startTime;  
        endTime = _endTime;
        _pcswAddr = _walletMajorOwner;
        targetClaimTime = endTime + 24 hours;
        require(endTime > startTime);
        require(_walletMajorOwner != address(0));
        
        ownerAddresses[_walletMajorOwner] = majorOwnerShares;
        
        owners.push(_walletMajorOwner);
        
        owner = _walletMajorOwner;
    }
    
    fallback() external payable {
        buy(msg.sender);
    }
    
    receive() external payable {}
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        return (size > 0);
    }
    
    //buy tokens
    function buy(address beneficiary) public payable
    {
        require (isPresaleStopped != true, 'Presale is stopped');
        require (isPresalePaused != true, 'Presale is paused');
        require(beneficiary != address(0), 'user asking for tokens sent to be on 0 address');
        require(validPurchase(), 'its not a valid purchase');
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);
    
        weiRaised = weiRaised.add(weiAmount);

        buyersList[msg.sender] = buyersList[msg.sender].add(tokens);
        require(buyersList[msg.sender]<MAX_BUY_LIMIT, 'Token limit per address has been reached');
    }

    function addLiquidityPool(address payable partner, uint256 value) public onlyOwner {

        require(partner != address(0));
        require(ownerAddresses[owner] >= ownerShare);
        require(ownerAddresses[partner] == 0);
        owners.push(partner);
        ownerAddresses[partner] = ownerShare;
        uint majorOwnerShare = ownerAddresses[owner];
        emit AddedLiquidityToPool(value);
        ownerAddresses[owner] = majorOwnerShare.sub(ownerShare);
        
    }

    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
    function claim() public {
        require(isClaimAvailable(), 'You can claim tokens during 24 hours');
        uint256 claimedAmount = buyersList[msg.sender];
        require(claimedAmount > 0, 'Address has not tokens for claim');
        token.transfer(msg.sender,claimedAmount);
        buyersList[msg.sender] = 0;
        emit TokenPurchase(msg.sender, claimedAmount);
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp >= endTime;
    }
    
    function isClaimAvailable() public view returns (bool) {
        return block.timestamp >= targetClaimTime;
    }

    function setEndDate(uint256 newEndTime) public onlyOwner returns(bool) {
        newEndTime = newEndTime * 1 seconds;
        // require(block.timestamp >  newEndDate, 'You can claim tokens during 24 hours');
        endTime = newEndTime;
        targetClaimTime = newEndTime + 24 hours; 
        return true;
    }

    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
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
    
    function BurnUnsoldTokens() public onlyOwner {
        uint256 unsold = token.balanceOf(address(this));
        token.transfer(_burnaddress,unsold);
    }
    
    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        startTime = block.timestamp; 
        return true;
    }
    
    // Recover lost bnb and send it to the contract owner from the fallback function
    function transferLiquidityToPancakeswap() public onlyOwner {
        require(_pcswAddr != address(0), 'invalid address');
        address payable _targetAddress = _pcswAddr;
        _targetAddress.transfer(address(this).balance);
        weiRaisedUpdated = weiRaised.add(address(this).balance);
    }
    
    // Ensure requested tokens aren't users RTR tokens from the fallback function
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount) public onlyOwner {
         require(_token != address(this), "Cannot recover RTR tokens");
         token.transfer(msg.sender, amount);
    }
 
    function tokensRemainingForSale() public view returns (uint256 balance) {
        return token.balanceOf(address(this));
    }

    function checkOwnerShare (address owner) public view onlyOwner returns (uint) {
        uint share = ownerAddresses[owner];
        return share;
    }
}