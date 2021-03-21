/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-28
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
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Ownable {
    address public dev1 = address(0xF4210B747e44592035da0126f70C48Cb04634Eac);
    address public dev2 = address(0xB173500160B809AAA5136777113d313Dd4eFBCc7);
    
    mapping(address => bool) public ownerByAddress;

    constructor() public {
        ownerByAddress[dev1] = true;
        ownerByAddress[dev2] = true;
    }

    modifier onlyOwners() {
        require(ownerByAddress[msg.sender] == true);
        _;
    }
}

contract DevLock is Ownable {
    using SafeMath for uint256;
    
    mapping(address => bool) public isLocked;
    uint256 ACTIVATION_TIME = 1616299208;
    
    modifier isActivated {
        require(now >= ACTIVATION_TIME);
        _;
    }

    modifier hasDripped {
        require(isLocked[dev1] == false && isLocked[dev2] == false);
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
        require(myShares() > 0);
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

    event onAddShares(
        address indexed devAddress,
        uint256 incomingTokens,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onRemoveShares(
        address indexed devAddress,
        uint256 tokensBurned,
        uint256 tokensEarned,
        uint256 timestamp
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tokensWithdrawn
    );

    string public name = "Dev Lock";
    string public symbol = "DEV_SHARES";
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
    TOKEN bep20;

    constructor() public {
        bep20 = TOKEN(address(0xF4cD6749B183f83FA54735996e59CDfc96F062EC)); //toad
        isLocked[dev1] = false;
        isLocked[dev2] = false;
    }

    function() payable external {
        revert();
    }
    function lock() onlyOwners public returns (uint256) {
        isLocked[msg.sender] = true;
    }
    function unlock() onlyOwners public returns (uint256) {
         isLocked[msg.sender] = false;
         lastDripTime = now;
    }
    function checkAndTransferToad(uint256 _amount) private {
        require(bep20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }
    
    function donateToPool(uint256 _amount) public {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        checkAndTransferToad(_amount);
        totalDonation += _amount;
        dividendPool = dividendPool.add(_amount);
        emit onDonation(msg.sender, _amount);
    }

    function withdraw() hasDripped onlyDivis public {
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo[_customerAddress] += (int256) (_dividends * divMagnitude);
        bep20.transfer(_customerAddress, _dividends);
        playerStats[_customerAddress].withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    function addSharesFor(address _devAddress, uint256 _shares) hasDripped onlyOwners public returns (uint256) {
        return purchaseTokens(_devAddress, _shares);
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

        emit onAddShares(_customerAddress, _incomingTokens, _amountOfTokens, now);

        return _amountOfTokens;
    }

    function removeSharesFor(address _devAddress, uint256 _shares) isActivated hasDripped onlyOwners public {
        address _customerAddress =_devAddress;
        require(_shares > 0 && _shares <= tokenBalanceLedger[_customerAddress]);

        tokenSupply = tokenSupply.sub(_shares);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_shares);

        int256 _updatedPayouts = (int256) (profitPerShare * _shares);
        payoutsTo[_customerAddress] -= _updatedPayouts;
        
        bep20.transfer(_customerAddress, _shares);
        
        emit Transfer(_customerAddress, address(0), _shares);
        emit onRemoveShares(_customerAddress, _shares, _shares, now);
    }

    function totalTokenBalance() public view returns (uint256) {
        return bep20.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myShares() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return sharesOf(_customerAddress);
    }

    function myEstimateDividends() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return estimateDividendsOf(_customerAddress);
    }

    function estimateDividendsOf(address _customerAddress) public view returns (uint256) {
        if(isLocked[dev1] == true || isLocked[dev2] == true){
            return myDividends();
        }
        uint256 _profitPerShare = profitPerShare;

        if (dividendPool > 0) {
            uint256 secondsPassed = 0;

            secondsPassed = SafeMath.sub(now, lastDripTime);

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

    function sharesOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }
}