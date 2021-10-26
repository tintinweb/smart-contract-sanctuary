/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: UNLICENSED

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

interface ScroogeToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address _owner) external returns (uint256 balance);
    function mint(address wallet, address buyer, uint256 tokenAmount) external;
}

contract Presale is Ownable ,Whitelisted {
    
    using SafeMath for uint256;
    
    uint256 public startTime;
    uint256 public endTime;

    mapping(address=>uint256) public BuyerList;
    mapping(address=>uint256) public BuyerTokenAmount;
    address public _burnaddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public MAX_BUY_LIMIT = 500000000000000001;  //0.5
    uint256 public rate = 10e3;
    uint256 public weiRaised;

    bool public isPresaleStopped = false;
  
    bool public isPresalePaused = false;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transfered(address indexed purchaser, address indexed referral, uint256 amount);

    ScroogeToken public token;
    
    constructor() 
    {
        token = ScroogeToken(0xA7b28d95eCa0C2d543B5725677237DAe3ca6CbCD); //Token Contract
        startTime = 1635186630;   
        endTime = startTime + 30 minutes;
        require(endTime >= startTime);
    }
    
    receive() external payable {}
    
    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {
        size := extcodesize(_addr)}
        return (size > 0);
    }
    //buy tokens
    function buy(address beneficiary) public onlyWhitelisted payable
    {
        require (isPresaleStopped != true, 'Presale is stopped');
        require (isPresalePaused != true, 'Presale is paused');
        require(beneficiary != address(0), 'user asking for tokens sent to be on 0 address');
        require(validPurchase(), 'its not a valid purchase');
        require(BuyerList[msg.sender] < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT Achieved already for this wallet');
        require(weiRaised.mul(rate) < token.balanceOf(address(this)), 'Token Balance of Presale is not enough, Please contact Community');
        uint256 weiAmount = msg.value;
        require(weiAmount <500000000000000001 , 'MAX_BUY_LIMIT is 5 BNB'); 
        uint256 tokens = weiAmount.mul(rate);
        
        weiRaised = weiRaised.add(weiAmount);
        
        BuyerTokenAmount[msg.sender] = BuyerTokenAmount[msg.sender] + tokens;
        
        BuyerList[msg.sender] = BuyerList[msg.sender].add(msg.value);
        
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
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

    function setEndDateHours(uint256 hoursToEndFromToday) public onlyOwner returns(bool) {
        hoursToEndFromToday = hoursToEndFromToday * 1 hours;
        endTime = block.timestamp + hoursToEndFromToday;
        return true;
    }

    function setEndDateMinutes(uint256 minutesToEndFromToday) public onlyOwner returns(bool) {
        minutesToEndFromToday = minutesToEndFromToday * 1 minutes;
        endTime = block.timestamp + minutesToEndFromToday;
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
    
    // Recover lost bnb and send it to the contract owner
    function recoverLostBNB() public onlyOwner {
         address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }
    // Ensure requested tokens aren't users Scrooge tokens
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount) public onlyOwner {
         require(_token != address(this), "Cannot recover Scrooge tokens");
         ScroogeToken(_token).transfer(msg.sender, amount);
    }
    
    function tokensRemainingForSale() public returns (uint256 balance) {
        balance = token.balanceOf(address(this));
    }

    function withdrawETH(address payable _withdrawETHAddr) external onlyOwner {
        _withdrawETHAddr.transfer(address(this).balance);
    }

    function withdrawToken(address _withdrawTokenAddrr) external onlyOwner {
        token.transfer(_withdrawTokenAddrr, token.balanceOf(address(this)));
    }

    function withdrawOwnToken() public {
        require(BuyerTokenAmount[msg.sender] > 0, "Token Balance should be over zero.");
        require(block.timestamp > endTime);
        
        token.transfer(msg.sender, BuyerTokenAmount[msg.sender]);
    }

}