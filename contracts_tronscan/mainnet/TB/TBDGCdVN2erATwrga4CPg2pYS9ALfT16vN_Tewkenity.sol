//SourceUnit: Tewkenity.sol

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

contract Ownable {
    address public owner;

    constructor() public {
      owner = address(0x41a4f7f3b8b2984434d71b50c4127ecec3621c334b);
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract Tewkenity is Ownable {
    using SafeMath for uint256;

    uint256 ACTIVATION_TIME = 1593298800;

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

    event onTokenAppreciation(
        uint256 tokenPrice,
        uint256 timestamp
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTewken,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tewkenEarned,
        uint256 timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 tewkenRolled,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tewkenWithdrawn
    );

    event onCardDividendPayout(
       uint256 time,
       uint256 value
    );

    event onCardPurchase(
       address indexed customerAddress,
       uint256 incomingTewken,
       uint256 index
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    string public name = "Tewkenity";
    string public symbol = "Tewkenity";
    uint8 constant public decimals = 6;
    uint256 constant private priceMagnitude = 1e6;
    uint256 constant private divMagnitude = 2 ** 64;

    uint32 constant private dailyRate = 4320000;
    uint8 constant private buyInFee = 35;
    uint8 constant private rewardFee = 5;
    uint8 constant private appreciateFee = 2;
    uint8 constant private cardFee = 4;
    uint8 constant private sellCardFee = 2;
    uint8 constant private devFee = 1;
    uint8 constant private sellOutFee = 5;
    uint8 constant private transferFee = 1;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => uint256) private cardBalance;
    mapping(address => int256) private payoutsTo;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
       uint256 cardsBought;
       uint256 cardsBoughtAmount;
       uint256 cardsEarnedAmount;
       uint256 cardsDividendAmount;
    }

    mapping(address => Stats) public playerStats;

    uint256 public dividendPool = 0;
    uint256 public cardDividendPool = 0;
    uint256 public lastDripTime = ACTIVATION_TIME;
    uint256 public totalPlayer = 0;
    uint256 public totalDonation = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShare = 0;
    uint256 private contractValue = 0;
    uint256 private tokenPrice = 1e6;

    TOKEN trc20;

    uint256 public redScore = 0;
    uint256 public greenScore = 0;
    uint256 public cardsSold = 0;
    uint256 public cardDividendPaid = 0;
    uint256 public lastCard;
    uint256 public cardTimer = ACTIVATION_TIME + 48 hours;

    struct cardPlayerPosition {
        address cardPlayer;
        address ambassador;
        uint256 startingLevel;
        uint256 startingTime;
        uint256 halfLife;
    }

    cardPlayerPosition[] cardPlayerPositions;

    constructor() public {
        trc20 = TOKEN(address(0x41130e4c9746e2f7b0a9d1f5eab71aa13896037ae8));

        for (uint i=0; i<32; i++) {
          cardPlayerPositions.push(cardPlayerPosition({
              cardPlayer: owner,
              ambassador: address(0),
              startingLevel: 0,
              startingTime: ACTIVATION_TIME,
              halfLife: 12 hours
          }));
        }
    }

    function() payable external {
        revert();
    }

    function checkAndTransferTewken(uint256 _amount) private {
        require(trc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function distribute(uint256 _amount) public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferTewken(_amount);
        totalDonation += _amount;
        profitPerShare = SafeMath.add(profitPerShare, (_amount * divMagnitude) / tokenSupply);
        emit onDonation(msg.sender, _amount);
    }

    function distributePool(uint256 _amount) public {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        checkAndTransferTewken(_amount);
        totalDonation += _amount;
        dividendPool = dividendPool.add(_amount);
        emit onDonation(msg.sender, _amount);
    }

    function appreciateTokenPrice(uint256 _amount) isActivated public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferTewken(_amount);
        totalDonation += _amount;
        contractValue = contractValue.add(_amount);

        if (tokenSupply > priceMagnitude) {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        emit onTokenAppreciation(tokenPrice, now);
    }

    function roll() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] +=  (int256) (_dividends * divMagnitude);
        _dividends += cardBalance[_customerAddress];
        cardBalance[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);
        emit onRoll(_customerAddress, _dividends, _tokens);
    }

    function withdraw() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] += (int256) (_dividends * divMagnitude);
        _dividends += cardBalance[_customerAddress];
        cardBalance[_customerAddress] = 0;
        trc20.transfer(_customerAddress, _dividends);
        playerStats[_customerAddress].withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }

    function buy(uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferTewken(_amount);
        return purchaseTokens(msg.sender, _amount);
    }

    function buyFor(address _customerAddress, uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferTewken(_amount);
        return purchaseTokens(_customerAddress, _amount);
    }

    function _purchaseTokens(address _customerAddress, uint256 _incomingTewken, uint256 _rewards) private returns(uint256) {
        uint256 _amountOfTokens = (_incomingTewken.mul(priceMagnitude)) / tokenPrice;
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

    function purchaseTokens(address _customerAddress, uint256 _incomingTewken) isActivated private returns (uint256) {
        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _incomingTewken;

        require(_incomingTewken > 0);

        uint256 _dividendFee = _incomingTewken.mul(buyInFee).div(100);
        uint256 _rewardFee = _incomingTewken.mul(rewardFee).div(100);
        //uint256 _appreciateFee = _incomingTewken.mul(appreciateFee).div(100);
        uint256 _cardFee = _incomingTewken.mul(cardFee).div(100);
        uint256 _devFee = _incomingTewken.mul(devFee).div(100);
        uint256 _entryFee = _incomingTewken.mul(50).div(100);
        uint256 _taxedTewken = _incomingTewken.sub(_entryFee);
        uint256 _exemptedAppreciation = _incomingTewken.sub(_dividendFee).sub(_rewardFee).sub(_cardFee);

        _purchaseTokens(owner, _devFee, 0);
        uint256 _amountOfTokens = _purchaseTokens(_customerAddress, _taxedTewken, _rewardFee);

        cardDividendPool = cardDividendPool.add(_cardFee);
        dividendPool = dividendPool.add(_dividendFee);
        contractValue = contractValue.add(_exemptedAppreciation);

        if (tokenSupply > priceMagnitude) {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        emit onTokenPurchase(_customerAddress, _incomingTewken, _amountOfTokens, now);
        emit onTokenAppreciation(tokenPrice, now);
        return _amountOfTokens;
    }

    function sell(uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        uint256 _tewken = _amountOfTokens.mul(tokenPrice).div(priceMagnitude);
        uint256 _dividendFee = _tewken.mul(sellOutFee).div(100);
        uint256 _appreciateFee = _tewken.mul(appreciateFee).div(100);
        uint256 _cardFee = _tewken.mul(sellCardFee).div(100);
        uint256 _devFee = _tewken.mul(devFee).div(100);

        _purchaseTokens(owner, _devFee, 0);
        _tewken = _tewken.sub(_dividendFee).sub(_appreciateFee).sub(_cardFee).sub(_devFee);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens + (_tewken * divMagnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;

        cardDividendPool = cardDividendPool.add(_cardFee);
        dividendPool = dividendPool.add(_dividendFee);
        contractValue = contractValue.sub(_tewken.add(_dividendFee).add(_cardFee));

        if (tokenSupply > priceMagnitude) {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _tewken, now);
        emit onTokenAppreciation(tokenPrice, now);
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

    function setName(string memory _name) onlyOwner public {
        name = _name;
    }

    function setSymbol(string memory _symbol) onlyOwner public {
        symbol = _symbol;
    }

    function totalTewkenBalance() public view returns (uint256) {
        return trc20.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myEstimateDividends(bool _includeCardBonus, bool _dayEstimate) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeCardBonus ? estimateDividendsOf(_customerAddress, _dayEstimate) + cardBalance[_customerAddress] : estimateDividendsOf(_customerAddress, _dayEstimate) ;
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

    function myDividends(bool _includeCardBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeCardBonus ? dividendsOf(_customerAddress) + cardBalance[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger[_customerAddress];
    }

    function buyPrice() public view returns(uint256) {
        uint256 _entryFee = tokenPrice.mul(50).div(100);
        return (tokenPrice.add(_entryFee));
    }

    function sellPrice() public view returns (uint256) {
        uint256 _exitFee = tokenPrice.mul(10).div(100);
        return (tokenPrice.sub(_exitFee));
    }

    function calculateTokensReceived(uint256 _tewkenToSpend) public view returns (uint256) {
        uint256 _entryFee = _tewkenToSpend.mul(50).div(100);
        uint256 _taxedTewken = _tewkenToSpend.sub(_entryFee);
        uint256 _amountOfTokens = (_taxedTewken.mul(priceMagnitude)) / tokenPrice;

        return _amountOfTokens;
    }

    function calculateTewkenReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply);
        uint256 _tewken = _tokensToSell.mul(tokenPrice).div(priceMagnitude);
        uint256 _exitFee = _tewken.mul(10).div(100);
        uint256 _taxedTewken = _tewken.sub(_exitFee);

        return _taxedTewken;
    }

    function inheritCardPosition(uint256 _index, uint256 _amount) isActivated public{
        checkAndTransferTewken(_amount);
        require(cardPlayerPositions.length > _index);

        cardPlayerPosition storage position = cardPlayerPositions[_index];
        uint256 _currentLevel = getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife);
        uint256 _currentPrice = getCurrentPrice(_currentLevel);

        require(_amount >= _currentPrice);
        uint256 _purchaseExcess = _amount.sub(_currentPrice);
        position.startingLevel = _currentLevel + 1;
        position.startingTime = now;

        uint256 _dividendFee = SafeMath.div(SafeMath.mul(_currentPrice, 5), 100);
        processDividend(_dividendFee, true);

        uint256 _inheritanceTax = SafeMath.div(SafeMath.mul(_currentPrice, 85), 100);
        cardBalance[position.cardPlayer] = cardBalance[position.cardPlayer].add(_inheritanceTax);
        playerStats[position.cardPlayer].cardsEarnedAmount += _inheritanceTax;
        position.cardPlayer = msg.sender;

        uint256 _ambassadorTax = SafeMath.div(SafeMath.mul(_currentPrice, 4), 100);
        cardBalance[position.ambassador] = cardBalance[position.ambassador].add(_ambassadorTax);
        playerStats[position.ambassador].cardsEarnedAmount += _ambassadorTax;

        uint256 _devTax = SafeMath.div(SafeMath.mul(_currentPrice, 1), 100);
        cardBalance[owner] = cardBalance[owner].add(_devTax);
        playerStats[owner].cardsEarnedAmount += _devTax;

        trc20.transfer(msg.sender, _purchaseExcess);

        cardsSold += 1;
        lastCard = _index;
        playerStats[position.cardPlayer].cardsBought += 1;
        playerStats[position.cardPlayer].cardsBoughtAmount += _currentPrice;

        if (_index >= 0 && _index <= 15){
            redScore += _amount;
        } else if (_index >= 16 && _index <= 31){
            greenScore += _amount;
        }

        emit onCardPurchase(msg.sender, _currentPrice, _index);
    }

    function triggerPayout() isActivated public {
        processDividend(0, false);
    }

    function processDividend(uint256 _dividendFee, bool boughtCard) internal {
        if (now >= cardTimer) {
            if (cardDividendPool >= 32) {
                cardDividendPaid += cardDividendPool;

                uint256 cursor;
                uint256 end;
                uint256 dividendRate;

                if (getWinningTeam() == 0){
                    cursor = 0;
                    end = 15;
                    dividendRate = 16;
                } else if (getWinningTeam() == 1){
                    cursor = 16;
                    end = 31;
                    dividendRate = 16;
                } else if (getWinningTeam() == 2){
                    cursor = 0;
                    end = 31;
                    dividendRate = 32;
                }

                for(; cursor <= end; cursor++) {
                    cardPlayerPosition memory position = cardPlayerPositions[cursor];

                    uint256 cardDividend = cardDividendPool.div(dividendRate);
                    cardBalance[position.cardPlayer] = cardBalance[position.cardPlayer].add(cardDividend);
                    playerStats[position.cardPlayer].cardsDividendAmount += cardDividend;
                }

                redScore = 0;
                greenScore = 0;
                cardDividendPool = 0;

                emit onCardDividendPayout(now, cardDividendPool);
          }

          cardTimer = SafeMath.add(now, 48 hours);
        }

        if (boughtCard == true) {
            cardDividendPool = cardDividendPool.add(_dividendFee);
            dividendPool = dividendPool.add(_dividendFee);
            cardTimer = cardTimer.add(15 minutes);

            if (cardTimer.sub(now) > 48 hours){
                uint256 _timeExcess = SafeMath.sub(SafeMath.sub(cardTimer, now), 48 hours);
                cardTimer = cardTimer.sub(_timeExcess);
            }
        }
    }

    function getCardPlayerPosition(uint256 index) public view returns(address cardPlayer, uint256 currentPrice, uint256 halfLife, uint256 startingTime) {
        cardPlayerPosition memory position = cardPlayerPositions[index];
        return (position.cardPlayer, getCurrentPrice(getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife)), position.halfLife, position.startingTime);
    }

    function getCurrentPrice(uint256 currentLevel) internal pure returns(uint256) {
        return 10000000 * 2**currentLevel;
    }

    function getCurrentLevel(uint256 startingLevel, uint256 startingTime, uint256 halfLife) internal view returns(uint256) {
        uint256 timePassed = now.sub(startingTime);
        uint256 levelsPassed = timePassed.div(halfLife);
        if (startingLevel < levelsPassed) {
            return 0;
        }
        return SafeMath.sub(startingLevel,levelsPassed);
    }

    function getDividendInfo() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        return(cardDividendPool, cardTimer, getWinningTeam(), redScore, greenScore, cardsSold, cardDividendPaid, lastCard);
    }

    function getWinningTeam() public view returns(uint256) {
        if (redScore > greenScore) {
            return 0;
        } else if (greenScore > redScore) {
            return 1;
        } else if (redScore == greenScore) {
            return 2;
        }
    }

    function setCardAmbassadors(address[] memory _addresses, uint8 _cursor, uint8 _end) onlyOwner public {
        require(_addresses.length == 32);
        require(_cursor >= 0 && _end < 32);

        for (; _cursor < _end; _cursor++) {
            cardPlayerPositions[_cursor].ambassador = _addresses[_cursor];
        }
    }
}