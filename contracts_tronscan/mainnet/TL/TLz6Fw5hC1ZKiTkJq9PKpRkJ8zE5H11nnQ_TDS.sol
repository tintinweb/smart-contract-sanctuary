//SourceUnit: JungleLDAfreshstart.sol

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

contract EXCH {
    function distribute() public payable returns (uint256);
}

contract TOKEN {
    function totalSupply() external view returns (uint256);
    function getMiningDifficulty() public view returns (uint256);
    function isMinter(address account) public view returns (bool);
    function mint(address account, uint256 amount) public returns (bool);
    function cap() public view returns (uint256);
}

contract Ownable {
    address public owner;

    constructor() public {
      owner = address(0x41e7528298834f74f5ddad36d459c76f2cd459b84d); // (BaKcu)
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract TDS is Ownable {
    using SafeMath for uint256;

    uint256 ACTIVATION_TIME = 1586649600;

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
        require(myDividends(true) > 0);
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
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy,
        uint256 timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned,
        uint256 timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 tronRolled,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tronWithdrawn
    );

    string public name = "Jungle";
    string public symbol = "JUNG";
    uint8 constant public decimals = 6;
    uint256 constant private divMagnitude = 2 ** 64;

    uint32 constant private dailyRate = 4320000;
    uint8 constant private buyInFee = 40;
    uint8 constant private rewardFee = 5;
    uint8 constant private referralFee = 2;
    uint8 constant private devFee = 1;
    uint8 constant private exchangeFee = 1;
    uint8 constant private sellOutFee = 9;
    uint8 constant private transferFee = 1;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => uint256) private referralBalance;
    mapping(address => int256) private payoutsTo;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
       uint256 minedlda;
    }

    mapping(address => Stats) public playerStats;

    uint256 public dividendPool = 0;
    uint256 public lastDripTime = ACTIVATION_TIME;
    uint256 public referralRequirement = 100e6;
    uint256 public totalPlayer = 0;
    uint256 public totalDonation = 0;
    uint256 public totaldev6FundReceived = 0;
    uint256 public totaldev6FundCollected = 0;
    uint256 public totaldev2FundReceived = 0;
    uint256 public totaldev2FundCollected = 0;
    uint256 public totalMinedlda = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShare = 0;

    address payable public dev2;
    EXCH dev6;
    TOKEN trc20;

    constructor() public {
        dev6 = EXCH(address(0x4110ba08783b9b816d4f65d6133b83f78b9f764c99));  // dev6 was (stable) contract
        dev2 = address(0x41c9d58a224265845d5a913802ced276175942788f); // dev2 (snEd) was (dlda) distribution contract 0x41a07018dd223c200f1b074af704211435132b5281
        trc20 = TOKEN(address(0x418821a5b5448d7e2cae0b0e4c176b3c58a49d77dc)); // Lion Digital Alliance Token (NoC1)
    }

    function() payable external {
        revert();
    }

    function distribute() public payable {
        require(msg.value > 0, "must be a positive value");
        totalDonation += msg.value;
        profitPerShare = SafeMath.add(profitPerShare, (msg.value * divMagnitude) / tokenSupply);
        emit onDonation(msg.sender, msg.value);
    }

    function distributePool() public payable {
        require(msg.value > 0 && tokenSupply > 0, "must be a positive value and have supply");
        totalDonation += msg.value;
        dividendPool = dividendPool.add(msg.value);
        emit onDonation(msg.sender, msg.value);
    }

    function payFund(bytes32 exchange) public {
        if (exchange == "dev6") {
          uint256 _tronToPay = totaldev6FundCollected.sub(totaldev6FundReceived);
          require(_tronToPay > 0);
          totaldev6FundReceived = totaldev6FundReceived.add(_tronToPay);
            dev6.distribute.value(_tronToPay)();
        } else if (exchange == "dev2") {
          uint256 _tronToPay = totaldev2FundCollected.sub(totaldev2FundReceived);
          require(_tronToPay > 0);
          totaldev2FundReceived = totaldev2FundReceived.add(_tronToPay);
          dev2.transfer(_tronToPay);
        }
    }

    function roll() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] +=  (int256) (_dividends * divMagnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(address(0), _customerAddress, _dividends);
        emit onRoll(_customerAddress, _dividends, _tokens);
    }

    function withdraw() hasDripped onlyDivis public {
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] += (int256) (_dividends * divMagnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        playerStats[_customerAddress].withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }

    function buy(address _referredBy) hasDripped public payable returns (uint256) {
        return purchaseTokens(_referredBy, msg.sender, msg.value);
    }

    function buyFor(address _referredBy, address _customerAddress) hasDripped public payable returns (uint256) {
        return purchaseTokens(_referredBy, _customerAddress, msg.value);
    }

    function _purchaseTokens(address _customerAddress, uint256 _incomingTron, uint256 _rewards) private returns(uint256) {
        uint256 _amountOfTokens = _incomingTron;
        uint256 _fee = _rewards * divMagnitude;

        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        if (tokenSupply > 0) {
            tokenSupply = tokenSupply.add(_amountOfTokens);
            profitPerShare += (_rewards * divMagnitude / tokenSupply);
            _fee = _fee - (_fee - (_amountOfTokens * (_rewards * divMagnitude / tokenSupply)));
        } else {
            tokenSupply = _amountOfTokens;
        }

        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens - _fee);
        payoutsTo[_customerAddress] += _updatedPayouts;

        emit Transfer(address(0), _customerAddress, _amountOfTokens);

        return _amountOfTokens;
    }

    function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingTron) isActivated private returns (uint256) {
        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _incomingTron;

        require(_incomingTron > 0);

        uint256 _dividendFee = _incomingTron.mul(buyInFee).div(100);
        uint256 _rewardFee = _incomingTron.mul(rewardFee).div(100);
        uint256 _referralBonus = _incomingTron.mul(referralFee).div(100);
        uint256 _devFee = _incomingTron.mul(devFee).div(100);
        uint256 _exchangeFee = _incomingTron.mul(exchangeFee).div(100);

        uint256 _entryFee = _incomingTron.mul(50).div(100);
        uint256 _taxedTron = _incomingTron.sub(_entryFee);

        _purchaseTokens(owner, _devFee, 0);

        if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger[_referredBy] >= referralRequirement) {
            referralBalance[_referredBy] = referralBalance[_referredBy].add(_referralBonus);
        } else {
            _rewardFee = _rewardFee.add(_referralBonus);
        }

        uint256 _amountOfTokens = _purchaseTokens(_customerAddress, _taxedTron, _rewardFee);

        dividendPool = dividendPool.add(_dividendFee);
        totaldev6FundCollected = totaldev6FundCollected.add(_exchangeFee);
        totaldev2FundCollected = totaldev2FundCollected.add(_exchangeFee);

        if (tronToSendFund("dev6") >= 10000000e6) {
            payFund("dev6");
        }

        if (tronToSendFund("dev2") >= 10000000e6) {
            payFund("dev2");
        }

        distributeTRC20(owner, _devFee);
        distributeTRC20(_customerAddress, _incomingTron);

        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, _referredBy, now);

        return _amountOfTokens;
    }

    function sell(uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        uint256 _dividendFee = _amountOfTokens.mul(sellOutFee).div(100);
        uint256 _devFee = _amountOfTokens.mul(devFee).div(100);
        uint256 _taxedTron = _amountOfTokens.sub(_dividendFee).sub(_devFee);

        _purchaseTokens(owner, _devFee, 0);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens + (_taxedTron * divMagnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;

        dividendPool = dividendPool.add(_dividendFee);

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedTron, now);
    }

    function distributeTRC20(address _customerAddress, uint256 _tron) private {
        uint256 _scaledToken = _tron.div(trc20.getMiningDifficulty());

        if (_scaledToken > 0 && trc20.isMinter(address(this)) && trc20.totalSupply().add(_scaledToken) <= trc20.cap()) {
            trc20.mint(_customerAddress, _scaledToken);
            totalMinedlda += _scaledToken;
            playerStats[_customerAddress].minedlda += _scaledToken;
        }
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders external returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = _amountOfTokens.mul(transferFee).div(100);
        uint256 _taxedTokens = _amountOfTokens.sub(_tokenFee);

        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_taxedTokens);
        tokenBalanceLedger[owner] = tokenBalanceLedger[owner].add(_tokenFee);

        payoutsTo[_customerAddress] -= (int256) (profitPerShare * _amountOfTokens);
        payoutsTo[_toAddress] += (int256) (profitPerShare * _taxedTokens);
        payoutsTo[owner] += (int256) (profitPerShare * _tokenFee);

        emit Transfer(_customerAddress, owner, _tokenFee);
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        return true;
    }

    function setName(string memory _name) onlyOwner public
    {
        name = _name;
    }

    function setSymbol(string memory _symbol) onlyOwner public
    {
        symbol = _symbol;
    }

    function totalTronBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myEstimateDividends(bool _includeReferralBonus, bool _dayEstimate) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? estimateDividendsOf(_customerAddress, _dayEstimate) + referralBalance[_customerAddress] : estimateDividendsOf(_customerAddress, _dayEstimate) ;
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

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function sellPrice() public view returns (uint256) {
        uint256 _tron = 1e6;
        uint256 _dividendFee = _tron.mul(sellOutFee).div(100);
        uint256 _devFee = _tron.mul(devFee).div(100);

        return (_tron.sub(_dividendFee).sub(_devFee));
    }

    function buyPrice() public view returns(uint256) {
        uint256 _tron = 1e6;
        uint256 _entryFee = _tron.mul(50).div(100);
        return (_tron.add(_entryFee));
    }

    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _entryFee = _tronToSpend.mul(50).div(100);
        uint256 _amountOfTokens = _tronToSpend.sub(_entryFee);

        return _amountOfTokens;
    }

    function calculateTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply);
        uint256 _exitFee = _tokensToSell.mul(10).div(100);
        uint256 _taxedTron = _tokensToSell.sub(_exitFee);

        return _taxedTron;
    }

    function tronToSendFund(bytes32 exchange) public view returns(uint256) {
        if (exchange == "dev6") {
          return totaldev6FundCollected.sub(totaldev6FundReceived);
        } else if (exchange == "dev2") {
          return totaldev2FundCollected.sub(totaldev2FundReceived);
        }
    }
}