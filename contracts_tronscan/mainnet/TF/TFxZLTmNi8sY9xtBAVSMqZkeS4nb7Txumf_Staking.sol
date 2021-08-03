//SourceUnit: LDAstaking.sol

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

contract JUNGLE {
    function buyFor(address _referredBy, address _customerAddress) public payable returns (uint256);
    function myDividends(bool _includeReferralBonus) public view returns (uint256);
    function withdraw() public;
}

contract TOKEN {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getMiningDifficulty() public view returns (uint256);
    function isMinter(address account) public view returns (bool);
    function renounceMinter() public;
    function mint(address account, uint256 amount) public returns (bool);
    function cap() public view returns (uint256);
}

contract BUYBACK {
    function transfer() public payable;
}

contract Ownable {
    address public owner;

    constructor() public {
      owner = address(0x41e7528298834f74f5ddad36d459c76f2cd459b84d);  // (BaKcu)
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract Staking is Ownable {
    using SafeMath for uint256;

    uint256 ACTIVATION_TIME = 1587855600;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodianAddress);
        _;
    }

    modifier hasDripped {
        if (dividendPool > 0) {
          uint256 secondsPassed = SafeMath.sub(now, lastDripTime);
          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          profitPerShareLDA = SafeMath.add(profitPerShareLDA, (dividends * divMagnitude) / tokenSupply);
          dividendPool = dividendPool.sub(dividends);
          lastDripTime = now;
        }

        if ((now - lastMintTime) > 5184000 && tokenSupply > 0) {
          if (trc20.isMinter(address(this)) && trc20.totalSupply().add(mintAmount) <= trc20.cap()) {
              trc20.mint(address(this), mintAmount);
              dividendPool = dividendPool.add(mintAmount);
          }

          lastMintTime = now;
        }

        if (externalSource && (jungle.myDividends(true) > 100e6)) {
          uint256 _balance = address(this).balance;

          if (jungle.myDividends(true) >= 100e6){
              jungle.withdraw();
          }

          uint256 _rewardFeeTRX = address(this).balance.sub(_balance);

          if (tokenSupply > 0) {
              profitPerShareTRX = SafeMath.add(profitPerShareTRX, (_rewardFeeTRX * divMagnitude) / tokenSupply);
          }
        }

        _;
    }

    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    event onDonationTRX(
        address indexed customerAddress,
        uint256 tokens
    );

    event onDonationLDA(
        address indexed customerAddress,
        uint256 tokens
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onTokenStake(
        address indexed customerAddress,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onTokenUnstake(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tokenEarned,
        uint256 timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 tokenRolled,
        uint256 tokensMinted,
        bytes32 tokenType
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tokenWithdrawn,
        bool tokenType
    );

    string public name = "LDA Staking";
    string public symbol = "LDASTAKE";
    uint8 constant public decimals = 6;
    uint256 constant private divMagnitude = 2 ** 64;

    uint32 constant private dailyRate = 4320000;
    uint8 constant private rewardFeeTRX = 50;
    uint8 constant private buyBackFeeTRX = 50;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => int256) private payoutsLDA;
    mapping(address => int256) private payoutsTRX;

    struct Stats {
       uint256 deposits;
       uint256 withdrawalLDA;
       uint256 withdrawalTRX;
    }

    mapping(address => Stats) public playerStats;

    bool externalSource = false;
    bool unstakeFee = true;

    address public custodianAddress;
    address public approvedAddress1;
    address public approvedAddress2;

    uint256 public dividendPool = 0;
    uint256 public lastDripTime = ACTIVATION_TIME;
    uint256 public totalPlayer = 0;
    uint256 public mintAmount = 1000000e6;
    uint256 public lastMintTime = ACTIVATION_TIME - 5183990;
    uint256 public totalDonationTRX = 0;
    uint256 public totalDonationLDA = 0;
    uint256 public buyBackFundReceived = 0;
    uint256 public buyBackFundCollected = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShareLDA = 0;
    uint256 private profitPerShareTRX = 0;

    JUNGLE jungle;
    TOKEN trc20;
    BUYBACK buyBack;

    constructor() public {
        jungle = JUNGLE(address(0x4178d42b9c47d1b3c42fdf955b69d4bf8967b88cae));  // (1nnQ) Jungle Contract
        trc20 = TOKEN(address(0x418821a5b5448d7e2cae0b0e4c176b3c58a49d77dc));  // (NoC1) LDA Token
        buyBack = BUYBACK(address(0x41321174bd17639ded66bf6aac388a2b54bb6d1e6b)); // (dev3)
        custodianAddress = address(0x41c9d58a224265845d5a913802ced276175942788f);  // (dev2)
    }

    function() payable external {
    }

    function checkAndTransferLDA(uint256 _amount) private {
        require(trc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function distributeTRX() public payable {
        require(msg.value > 0, "must be a positive value");
        totalDonationTRX += msg.value;
        profitPerShareTRX = SafeMath.add(profitPerShareTRX, (msg.value * divMagnitude) / tokenSupply);
        emit onDonationTRX(msg.sender, msg.value);
    }

    function distributeLDA(uint256 _amount) public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferLDA(_amount);
        totalDonationLDA += _amount;
        profitPerShareLDA = SafeMath.add(profitPerShareLDA, (_amount * divMagnitude) / tokenSupply);
        emit onDonationLDA(msg.sender, _amount);
    }

    function distributeLDAPool(uint256 _amount) public {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        checkAndTransferLDA(_amount);
        totalDonationLDA += _amount;
        dividendPool = dividendPool.add(_amount);
        emit onDonationLDA(msg.sender, _amount);
    }

    function payFund() public {
        uint256 _tronToPay = buyBackFundCollected.sub(buyBackFundReceived);
        require(_tronToPay > 0);
        buyBackFundReceived = buyBackFundReceived.add(_tronToPay);
        buyBack.transfer.value(_tronToPay)();
    }

    function roll(bool _isLDA, bytes32 _rollType) hasDripped public {
        uint256 _dividends = myDividends(_isLDA);
        require(_dividends > 0);

        address _customerAddress = msg.sender;
        uint256 _tokens;

        if (_isLDA && _rollType == "LDA") {
            payoutsLDA[_customerAddress] +=  (int256) (_dividends * divMagnitude);
            _tokens = stakeTokens(_customerAddress, _dividends);
            emit onRoll(_customerAddress, _dividends, _tokens, _rollType);
        } else if (!_isLDA && _rollType == "jungle") {
            payoutsTRX[_customerAddress] += (int256) (_dividends * divMagnitude);
            _tokens = jungle.buyFor.value(_dividends)(address(0), _customerAddress);
            emit onRoll(_customerAddress, _dividends, _tokens, _rollType);
        }
    }

    function withdraw(bool _isLDA) hasDripped public {
        uint256 _dividends = myDividends(_isLDA);
        require(_dividends > 0);

        address payable _customerAddress = msg.sender;

        if (_isLDA) {
          payoutsLDA[_customerAddress] += (int256) (_dividends * divMagnitude);
          trc20.transfer(_customerAddress, _dividends);
          playerStats[_customerAddress].withdrawalLDA += _dividends;
        } else {
          payoutsTRX[_customerAddress] += (int256) (_dividends * divMagnitude);
          _customerAddress.transfer(_dividends);
          playerStats[_customerAddress].withdrawalTRX += _dividends;
        }

        emit onWithdraw(_customerAddress, _dividends, _isLDA);
    }

    function stake(uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferLDA(_amount);
        return stakeTokens(msg.sender, _amount);
    }

    function stakeFor(address _customerAddress, uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferLDA(_amount);
        return stakeTokens(_customerAddress, _amount);
    }

    function _stakeTokens(address _customerAddress, uint256 _amountOfTokens) private returns(uint256) {
        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        tokenSupply = tokenSupply.add(_amountOfTokens);

        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);
        payoutsLDA[_customerAddress] += (int256) (profitPerShareLDA * _amountOfTokens);
        payoutsTRX[_customerAddress] += (int256) (profitPerShareTRX * _amountOfTokens);

        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }

    function stakeTokens(address _customerAddress, uint256 _incomingLDA) isActivated private returns (uint256) {
        require(_incomingLDA > 0);

        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _incomingLDA;

        uint256 _amountOfTokens = _stakeTokens(_customerAddress, _incomingLDA);

        if (tronToSendFund() >= 1000e6) {
            payFund();
        }

        uint256 _scaledToken = _incomingLDA.div(100);

        if (_scaledToken > 0 && trc20.isMinter(address(this)) && trc20.totalSupply().add(_scaledToken) <= trc20.cap()) {
            trc20.mint(owner, _scaledToken);
        }

        emit onTokenStake(_customerAddress, _amountOfTokens, now);
        return _amountOfTokens;
    }

    function unstake(uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders public payable {
        address _customerAddress = msg.sender;
        uint256 _incomingTron = msg.value;

        require(_amountOfTokens >= 100 &&_amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        uint256 _rewardFeeTRX = 0;
        uint256 _buyBackFeeTRX = 0;
        uint256 _dividendFee = 0;
        uint256 _taxedLDA = _amountOfTokens;

        if (unstakeFee == true) {
            require(_incomingTron >= _amountOfTokens.div(10) && _incomingTron < _amountOfTokens.div(10).add(1e6));
            _rewardFeeTRX = _incomingTron.mul(rewardFeeTRX).div(100);
            _buyBackFeeTRX = _incomingTron.mul(buyBackFeeTRX).div(100);
            buyBackFundCollected = buyBackFundCollected.add(_buyBackFeeTRX);
        } else {
            _dividendFee = _amountOfTokens.mul(10).div(100);
            _taxedLDA = _amountOfTokens.sub(_dividendFee);
            dividendPool = dividendPool.add(_dividendFee);
        }

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        payoutsLDA[_customerAddress] -= (int256) (profitPerShareLDA * _amountOfTokens + (_taxedLDA * divMagnitude));
        payoutsTRX[_customerAddress] -= (int256) (profitPerShareTRX * _amountOfTokens);

        if (tokenSupply > 0) {
            profitPerShareTRX = SafeMath.add(profitPerShareTRX, (_rewardFeeTRX * divMagnitude) / tokenSupply);
        }

        if (tronToSendFund() >= 1000e6) {
            payFund();
        }

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenUnstake(_customerAddress, _amountOfTokens, _taxedLDA, now);
    }

    function setName(string memory _name) onlyOwner public {
        name = _name;
    }

    function setSymbol(string memory _symbol) onlyOwner public {
        symbol = _symbol;
    }

    function setMintAmount(uint256 _amount) onlyOwner public {
        require(_amount > 0 && _amount <= 3000000e6);
        mintAmount = _amount;
    }

    function renounceMinter() onlyOwner public {
        trc20.renounceMinter();
    }

    function setExternalSource(bool _state) onlyOwner public {
        externalSource = _state;
    }

    function setUnstakeFee(bool _state) onlyOwner public {
        unstakeFee = _state;
    }

    function approveAddress1(address _proposedAddress) onlyOwner public {
       approvedAddress1 = _proposedAddress;
    }

    function approveAddress2(address _proposedAddress) onlyCustodian public {
       approvedAddress2 = _proposedAddress;
    }

    function setBuyBackFundAddress() onlyOwner public {
        require(approvedAddress1 != address(0) && approvedAddress1 == approvedAddress2);
        buyBack = BUYBACK(approvedAddress1);
    }

    function totalLDABalance() public view returns (uint256) {
        return trc20.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myEstimateLDADivs(bool _dayEstimate) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return estimateLDADivsOf(_customerAddress, _dayEstimate) ;
    }

    function estimateLDADivsOf(address _customerAddress, bool _dayEstimate) public view returns (uint256) {
        uint256 _profitPerShareLDA = profitPerShareLDA;

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

          _profitPerShareLDA = SafeMath.add(_profitPerShareLDA, (dividends * divMagnitude) / tokenSupply);
        }

        return (uint256) ((int256) (_profitPerShareLDA * tokenBalanceLedger[_customerAddress]) - payoutsLDA[_customerAddress]) / divMagnitude;
    }

    function myDividends(bool _isLDA) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress, _isLDA);
    }

    function dividendsOf(address _customerAddress, bool _isLDA) public view returns (uint256) {
        if (_isLDA) {
            return (uint256) ((int256) (profitPerShareLDA * tokenBalanceLedger[_customerAddress]) - payoutsLDA[_customerAddress]) / divMagnitude;
        } else {
            return (uint256) ((int256) (profitPerShareTRX * tokenBalanceLedger[_customerAddress]) - payoutsTRX[_customerAddress]) / divMagnitude;
        }
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function tronToSendFund() public view returns(uint256) {
        return buyBackFundCollected.sub(buyBackFundReceived);
    }
}