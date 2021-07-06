/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity ^0.5.10;

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

contract TOKEN {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SFARM {
    address public owner;

    constructor() public {
      owner = address(0xA76b22C3e4737420862D6a48C683A70ef126A415);
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract SpiderFarm is SFARM {
    using SafeMath for uint256;

    uint256 ACTIVATION_TIME = 1625599500;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);
        _;
    }

    modifier hasDripped {
        if (dividendPool > 0) {
          uint256 secondsPassed = SafeMath.sub(now, lastDripTime);
          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          profitPerShare = SafeMath.add(profitPerShare, (dividends * divMagnitude) / tokenSupply);
          dividendPool = dividendPool.sub(dividends);
          lastDripTime = now;
        }
        _;
    }

    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDivis {
        require(myDividends() > 0);
        _;
    }

    event onDonation(
        address indexed customerAddress,
        uint256 tokens
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTokens,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tokensEarned,
        uint256 timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 tokensRolled,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tokensWithdrawn
    );

    string public name = "Spider Farm";
    string public symbol = "SPIDERF";
    uint8 constant public decimals = 18;
    uint256 constant private divMagnitude = 2 ** 64;

    uint32 constant private dailyRate = 8640000; //1% a day

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => int256) private payoutsTo;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
    }

    mapping(address => Stats) public playerStats;

    uint256 public dividendPool = 0;
    uint256 public lastDripTime = ACTIVATION_TIME;
    uint256 public totalPlayer = 0;
    uint256 public totalDonation = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShare = 0;

    address public burnAddress;
    TOKEN ERC20;

    constructor() public {
        burnAddress = address(0xdEaD); //burning address
        ERC20 = TOKEN(address(0xC76B9FCc1c9D2B5f7a105D86D6d6070ef5DD7C4E)); //Spider
    }

    function() payable external {
        revert();
    }
    
    function checkAndTransferSpider(uint256 _amount) private {
        require(ERC20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }
    
    function donateToPool(uint256 _amount) public {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        checkAndTransferSpider(_amount);
        totalDonation += _amount;
        dividendPool = dividendPool.add(_amount);
        emit onDonation(msg.sender, _amount);
    }

    function roll() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo[_customerAddress] +=  (int256) (_dividends * divMagnitude);
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);
        emit onRoll(_customerAddress, _dividends, _tokens);
    }

    function withdraw() hasDripped onlyDivis public {
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo[_customerAddress] += (int256) (_dividends * divMagnitude);
        ERC20.transfer(_customerAddress, _dividends);
        playerStats[_customerAddress].withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    function deposit(uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferSpider(_amount);
        return purchaseTokens(msg.sender, _amount);
    }

    function _purchaseTokens(address _customerAddress, uint256 _incomingTokens) private returns(uint256) {
        uint256 _amountOfTokens = _incomingTokens;

        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        tokenSupply = tokenSupply.add(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens);
        payoutsTo[_customerAddress] += _updatedPayouts;

        emit Transfer(address(0), _customerAddress, _amountOfTokens);

        return _amountOfTokens;
    }

    function purchaseTokens(address _customerAddress, uint256 _incomingTokens) isActivated private returns (uint256) {
        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _incomingTokens;

        require(_incomingTokens > 0);

        uint256 _amountOfTokens = _purchaseTokens(_customerAddress, _incomingTokens);

        emit onTokenPurchase(_customerAddress, _incomingTokens, _amountOfTokens, now);

        return _amountOfTokens;
    }

    function sell(uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens);
        payoutsTo[_customerAddress] -= _updatedPayouts;
        
        ERC20.transfer(_customerAddress, _amountOfTokens);
        
        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _amountOfTokens, now);
    }

    function setName(string memory _name) onlyOwner public
    {
        name = _name;
    }

    function setSymbol(string memory _symbol) onlyOwner public
    {
        symbol = _symbol;
    }

    function totalTokenBalance() public view returns (uint256) {
        return ERC20.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myEstimateDividends(bool _dayEstimate) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return estimateDividendsOf(_customerAddress, _dayEstimate) ;
    }

    function estimateDividendsOf(address _customerAddress, bool _dayEstimate) public view returns (uint256) {
        uint256 _profitPerShare = profitPerShare;

        if (dividendPool > 0) {
          uint256 secondsPassed = 0;

          if (_dayEstimate == true){
            secondsPassed = 86400;
          } else {
            secondsPassed = SafeMath.sub(now, lastDripTime);
          }

          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          _profitPerShare = SafeMath.add(_profitPerShare, (dividends * divMagnitude) / tokenSupply);
        }

        return (uint256) ((int256) (_profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function myDividends() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress) ;
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }
}