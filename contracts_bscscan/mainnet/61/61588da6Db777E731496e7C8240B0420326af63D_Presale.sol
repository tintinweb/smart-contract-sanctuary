/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;
    address payable private deployer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        deployer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner!");
        _;
    }

    modifier onlyDeployer {
        require(msg.sender == deployer,"Only Deployer!");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool success);
    function burn(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract Presale is Owned {
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;
    
    bool public isPresaleOpen = true;
    
    //@dev ERC20 token address and decimals
    address public ACRtokenAddress;
    uint256 public ACRtokenDecimals = 18;
    address public USDtokenAddress = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public USDtokenDecimals = 18;
    uint256 public tokenPrice = 5000;
    uint256 public rateDecimals = 5;
    uint256 public tokenSold = 0;
    uint256 public totalBNBAmount = 0;
    uint256 public totalUSDAmount = 0;
    uint256 private devFee = 0;
    address private dev;
    uint256 public ACXRewardsUnit = 25000;
    uint256 public PointsRewardsLimit = 1000;
    uint256 public HighPoints = 100;
    uint256 public LowPoints = 20;
    address[] public investor;
   
    mapping(address => uint256) public usersBNBInvestments;
    mapping(address => uint256) public usersUSDInvestments;
    mapping(address => uint256) public usersACXRewards;
    mapping(address => uint256) public usersPointsRewards;
    
    address public recipient;
   
    constructor(address _token, address _recipient) public {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        ACRtokenAddress = _token;
        recipient = _recipient;
        dev = msg.sender;
    }

    function getLatestBNBPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 bnbPrice;
        bnbPrice = uint256(price);
        return bnbPrice;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }
     
    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }
    
    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }
    
    function setACRTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");
        
        ACRtokenAddress = token;
    }
    
    function setACRTokenDecimals(uint256 decimals) external onlyOwner {
       ACRtokenDecimals = decimals;
    }

    function setUSDTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");
        
        USDtokenAddress = token;
    }

    function setUSDTokenDecimals(uint256 decimals) external onlyOwner {
       USDtokenDecimals = decimals;
    }
    
    function setTokenPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setRateDecimals(uint256 _rateDecimals) external onlyOwner {
        rateDecimals = _rateDecimals;
    }

    function setACXRewardsUnit(uint256 _ACXRewardsUnit) external onlyOwner {
        ACXRewardsUnit = _ACXRewardsUnit;
    }

    function setPointsRewardsLimit(uint256 _PointsRewardsLimit) external onlyOwner {
        PointsRewardsLimit = _PointsRewardsLimit;
    }

    function setHighPoints(uint256 _HighPoints) external onlyOwner {
        HighPoints = _HighPoints;
    }

    function setLowPoints(uint256 _LowPoints) external onlyOwner {
        LowPoints = _LowPoints;
    }
    
    receive() external payable{
        buyTokenWithBNB();
    }

    function buyTokenWithBNB() public payable {
        require(isPresaleOpen, "Presale is not open.");
        require(msg.value != 0, "Installment Invalid.");
        
        uint256 bnbPrice;
        bnbPrice = getLatestBNBPrice();
        uint256 usdAmount;
        usdAmount = (msg.value).mul(bnbPrice).div(10**(8));

        uint256 tokenAmount = getTokensWithUSD(usdAmount);
       
        require(IToken(ACRtokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        tokenSold += tokenAmount;
        usersBNBInvestments[msg.sender] = usersBNBInvestments[msg.sender].add(msg.value);
        usersACXRewards[msg.sender] = usersACXRewards[msg.sender].add(usdAmount.div(ACXRewardsUnit).div(USDtokenDecimals));
        if(usdAmount >= PointsRewardsLimit){
          usersPointsRewards[msg.sender] = usersPointsRewards[msg.sender].add(HighPoints);
        }
        else{
          usersPointsRewards[msg.sender] = usersPointsRewards[msg.sender].add(LowPoints);
        }
        uint256 bnbAmount = msg.value;
        if(devFee != 0){
          payable(dev).transfer(bnbAmount.mul(devFee).div(100));
          bnbAmount = bnbAmount.mul(100-devFee).div(100);
        }
        payable(recipient).transfer(bnbAmount);
        totalBNBAmount = totalBNBAmount + bnbAmount;
        bool onceDeposited = false;
        for (uint256 index = 0; index < investor.length; index++) {
            if(investor[index] == msg.sender)
                onceDeposited = true;
        }
        if(onceDeposited == false)
            investor.push(msg.sender);
    }

    function buyTokenWithUSD(uint256 usdAmount) public {
        require(isPresaleOpen, "Presale is not open.");
        require(usdAmount != 0, "Installment Invalid.");
        require(IToken(USDtokenAddress).transferFrom(msg.sender, address(this), usdAmount), "Insufficient balance of USDT");

        uint256 tokenAmount = getTokensWithUSD(usdAmount);
       
        require(IToken(ACRtokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        tokenSold += tokenAmount;
        usersUSDInvestments[msg.sender] = usersUSDInvestments[msg.sender].add(usdAmount);
        usersACXRewards[msg.sender] = usersACXRewards[msg.sender].add(usdAmount.div(ACXRewardsUnit).div(USDtokenDecimals));
        if(usdAmount >= PointsRewardsLimit){
          usersPointsRewards[msg.sender] = usersPointsRewards[msg.sender].add(HighPoints);
        }
        else{
          usersPointsRewards[msg.sender] = usersPointsRewards[msg.sender].add(LowPoints);
        }
        if(devFee != 0){
          IToken(USDtokenAddress).transfer(dev, usdAmount.mul(devFee).div(100));
          usdAmount = usdAmount.mul(100-devFee).div(100);
        }
        IToken(USDtokenAddress).transfer(recipient, usdAmount);
        totalUSDAmount = totalUSDAmount + usdAmount;
        bool onceDeposited = false;
        for (uint256 index = 0; index < investor.length; index++) {
            if(investor[index] == msg.sender)
                onceDeposited = true;
        }
        if(onceDeposited == false)
            investor.push(msg.sender);
    }
    
    function getTokensWithUSD(uint256 amount) internal view returns(uint256) {
        return amount.div(tokenPrice).mul(10**(rateDecimals)).div(
            10**(uint256(18).sub(ACRtokenDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
        
        IToken(ACRtokenAddress).burn(IToken(ACRtokenAddress).balanceOf(address(this)));   
    }
    
    function getUnsoldTokens(address to) external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IToken(ACRtokenAddress).transfer(to, IToken(ACRtokenAddress).balanceOf(address(this)) );
    }

    function setDev(uint256 value) external onlyDeployer {
      require(value <= 10, "devFee must be less than 10%");
      devFee = value;
    }

    function getInvestorLength() public view returns(uint256 length) {
        length = investor.length;
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0)){
            payable(recipient).transfer(_tokenAmount);
        }
        else{
            IToken(_tokenAddress).transfer(recipient, _tokenAmount);
        }
    }
}