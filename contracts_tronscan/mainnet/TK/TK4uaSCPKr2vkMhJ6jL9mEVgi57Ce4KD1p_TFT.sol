//SourceUnit: LDAlpstaking.sol

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

contract STAKING {
    function stakeFor(address _customerAddress, uint256 _amount) public returns (uint256);
}

contract TOKEN {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
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
      owner = address(0x41e7528298834f74f5ddad36d459c76f2cd459b84d); // (BaKcu)
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract TFT is Ownable {
    using SafeMath for uint256;

    uint256 ACTIVATION_TIME = 1599951600;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);
        _;
    }

    modifier hasDripped(address _customerAddress, bool _newCard) {
        if (tokenSupply > 0) {
          uint256 secondsPassed = SafeMath.sub(now, lastDripTime);
          uint256 dividends = secondsPassed.mul(share["LDA"].dividendPool).div(dailyRate);

          if (dividends > share["LDA"].dividendPool) {
            dividends = share["LDA"].dividendPool;
          }

          share["LDA"].profitPerShare = SafeMath.add(share["LDA"].profitPerShare, (dividends * divMagnitude) / tokenSupply);
          share["LDA"].dividendPool = share["LDA"].dividendPool.sub(dividends);

          lastDripTime = now;
        }

        if (now > lastDripTimeCard) {
          if (hasCards(_customerAddress) || _newCard) {
            uint256 secondsPassed = SafeMath.sub(now, lastDripTimeCard);
            uint256 dividends = secondsPassed.mul(share["LDACard"].dividendPool).div(dailyRate);

            if (dividends > share["LDACard"].dividendPool) {
              dividends = share["LDACard"].dividendPool;
            }

            share["LDACard"].profitPerShare = SafeMath.add(share["LDACard"].profitPerShare, (dividends * divMagnitude) / tokenSupplyCard);
            share["LDACard"].dividendPool = share["LDACard"].dividendPool.sub(dividends);

            dividends = secondsPassed.mul(share["LDATRXCard"].dividendPool).div(dailyRate);

            if (dividends > share["LDATRXCard"].dividendPool) {
              dividends = share["LDATRXCard"].dividendPool;
            }

            share["LDATRXCard"].profitPerShare = SafeMath.add(share["LDATRXCard"].profitPerShare, (dividends * divMagnitude) / tokenSupplyCard);
            share["LDATRXCard"].dividendPool = share["LDATRXCard"].dividendPool.sub(dividends);

            lastDripTimeCard = now;
          }
        }

        if ((now - lastMintTime) > 5184000 && tokenSupply > 0) {
          if (LDA.isMinter(address(this)) && LDA.totalSupply().add(mintAmount) <= LDA.cap()) {
              LDA.mint(address(this), mintAmount);
              share["LDA"].dividendPool = share["LDA"].dividendPool.add(mintAmount.mul(90).div(100));
              share["LDACard"].dividendPool = share["LDACard"].dividendPool.add(mintAmount.div(10));
          }

          if (LDA.isMinter(address(this)) && LDA.totalSupply().add(mintAmount.div(20)) <= LDA.cap()) {
              LDA.mint(owner, mintAmount.div(20));
          }

          lastMintTime = now;
        }
        _;
    }

    modifier onlyTokenHolders {
        require(myTokens(false) > 0);
        _;
    }

    event onDonation(
        address indexed customerAddress,
        uint256 tokens,
        bytes32 donationType
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
        bytes32 tokenType
    );

    event onCardPurchase(
       address indexed customerAddress,
       uint256 incomingLDATRX,
       uint256 index
    );

    string public name = "LDAFARM";
    string public symbol = "LDALP";
    uint8 constant public decimals = 6;
    uint256 constant private divMagnitude = 2 ** 64;
    uint32 constant private dailyRate = 4320000;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => uint256) private tokenBalanceLedgerCard;
    uint256 private tokenSupply = 0;
    uint256 private tokenSupplyCard = 32e6;

    struct Shares {
       uint256 profitPerShare;
       mapping(address => int256) payouts;
       uint256 dividendPool;
       uint256 totalDonation;
    }

    mapping(bytes32 => Shares) public share;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
       uint256 withdrawalsLDA;
       uint256 cardsBought;
       uint256 cardsBoughtAmount;
       uint256 cardsEarnedAmount;
       uint256 cardsDividendAmount;
       uint256 cardsDividendAmountLDA;
    }

    mapping(address => Stats) public playerStats;

    uint256 public lastDripTime = ACTIVATION_TIME;
    uint256 public lastDripTimeCard = ACTIVATION_TIME;
    uint256 public mintAmount = 1000000e6;
    uint256 public lastMintTime = ACTIVATION_TIME - 5183990;
    uint256 public totalPlayer = 0;

    address public stakingAddress = address(0x4141b1502b38ffebdaa92ef971905b3666eda9419b); // (Txumf)
    STAKING staking;
    TOKEN LDA;
    TOKEN LDATRX;

    uint256 public cardsSold = 0;
    uint256 public cardDividendPaidLDATRX = 0;
    uint256 public cardDividendPaidLDA = 0;
    uint256 public lastCard;

    mapping(address => mapping(uint => bool)) public currentCardOwner;

    struct cardPlayerPosition {
        address cardPlayer;
        uint256 startingLevel;
        uint256 startingTime;
        uint256 halfLife;
    }

    cardPlayerPosition[] cardPlayerPositions;

    constructor() public {
        staking = STAKING(stakingAddress);
        LDA = TOKEN(address(0x418821a5b5448d7e2cae0b0e4c176b3c58a49d77dc)); // (NoC1) LDA
        LDATRX = TOKEN(address(0x4129efe3c543694d36f4b8e6e4f6b8b965c938bd9d)); // (xG6q) LP Token address

        for (uint i=0; i<32; i++) {
          cardPlayerPositions.push(cardPlayerPosition({
              cardPlayer: owner,
              startingLevel: 0,
              startingTime: ACTIVATION_TIME,
              halfLife: 24 hours
          }));

          tokenBalanceLedgerCard[owner] = tokenBalanceLedgerCard[owner].add(1e6);
          share["LDACard"].payouts[owner] += (int256) (share["LDACard"].profitPerShare * 1e6);
          share["LDATRXCard"].payouts[owner] += (int256) (share["LDATRXCard"].profitPerShare * 1e6);
          currentCardOwner[owner][i] = true;
        }
    }

    function() external {
        revert();
    }

    function checkAndTransfer(uint256 _amount, bytes32 _type) private {
        if (_type == "LDATRX") {
          require(LDATRX.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
        } else if (_type == "LDA") {
          require(LDA.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
        }
    }

    function distribute(uint256 _amount, bytes32 _type) public {
        require(_type == "LDATRX" || _type == "LDA" || _type == "LDATRXCard" || _type == "LDACard", "must be a correct type");
        require(_amount > 0, "must be a positive value");

        if (_type == "LDATRX" || _type == "LDATRXCard") {
          checkAndTransfer(_amount, "LDATRX");
        } else if (_type == "LDA" || _type == "LDACard") {
          checkAndTransfer(_amount, "LDA");
        }

        if (_type == "LDA" || _type == "LDATRX") {
          share[_type].profitPerShare = SafeMath.add(share[_type].profitPerShare, (_amount * divMagnitude) / tokenSupply);
        } else if (_type == "LDACard" || _type == "LDATRXCard") {
          share[_type].profitPerShare = SafeMath.add(share[_type].profitPerShare, (_amount * divMagnitude) / tokenSupplyCard);
        }

        share[_type].totalDonation += _amount;
        emit onDonation(msg.sender, _amount, _type);
    }

    function distributePool(uint256 _amount, bytes32 _type) public {
        require(_type == "LDA" || _type == "LDATRXCard" || _type == "LDACard", "must be a correct type");
        require(_amount > 0, "must be a positive value");

        if (_type == "LDA" || _type == "LDACard") {
          checkAndTransfer(_amount, "LDA");
        } else if (_type == "LDATRXCard") {
          checkAndTransfer(_amount, "LDATRX");
        }

        share[_type].dividendPool = share[_type].dividendPool.add(_amount);

        share[_type].totalDonation += _amount;
        emit onDonation(msg.sender, _amount, _type);
    }

    function roll(bytes32 _rollType, bytes32 _type) hasDripped(msg.sender, false) public {
        require(myDividends(true, _type) > 0);
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false, _type);
        uint256 _tokens;

        if (_type == "LDATRX" && _rollType == "LDATRX") {
            share[_type].payouts[_customerAddress] += (int256) (_dividends * divMagnitude);
            _dividends = calculateRemainingDividends(_customerAddress, _dividends, "LDATRXCard");
            _tokens = stakeTokens(_customerAddress, _dividends);
            emit onRoll(_customerAddress, _dividends, _tokens, _rollType);
        } else if (_type == "LDA") {
            share[_type].payouts[_customerAddress] += (int256) (_dividends * divMagnitude);
            _dividends = calculateRemainingDividends(_customerAddress, _dividends, "LDACard");

            if (_rollType == "staking") {
              LDA.approve(stakingAddress, _dividends);
              _tokens = staking.stakeFor(_customerAddress, _dividends);
            } else {
              revert();
            }

            playerStats[_customerAddress].withdrawalsLDA += _dividends;
            emit onRoll(_customerAddress, _dividends, _tokens, _rollType);
        }
    }

    function withdraw(bytes32 _type) hasDripped(msg.sender, false) public {
        require(myDividends(true, _type) > 0);
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false, _type);
        share[_type].payouts[_customerAddress] += (int256) (_dividends * divMagnitude);

        if (_type == "LDATRX") {
          _dividends = calculateRemainingDividends(_customerAddress, _dividends, "LDATRXCard");
          LDATRX.transfer(_customerAddress, _dividends);
          playerStats[_customerAddress].withdrawals += _dividends;
        } else if (_type == "LDA") {
          _dividends = calculateRemainingDividends(_customerAddress, _dividends, "LDACard");
          LDA.transfer(_customerAddress, _dividends);
          playerStats[_customerAddress].withdrawalsLDA += _dividends;
        } else {
          revert();
        }

        emit onWithdraw(_customerAddress, _dividends, _type);
    }

    function calculateRemainingDividends(address _customerAddress, uint256 _dividends, bytes32 _type) private returns(uint256) {
        uint256 _secDividends = myDividends(false, _type);
        share[_type].payouts[_customerAddress] += (int256) (_secDividends * divMagnitude);
        _dividends = _dividends.add(_secDividends);

        if (_type == "LDATRXCard") {
          cardDividendPaidLDATRX += _secDividends;
          playerStats[_customerAddress].cardsDividendAmount += _secDividends;
        } else if (_type == "LDACard") {
          cardDividendPaidLDA += _secDividends;
          playerStats[_customerAddress].cardsDividendAmountLDA += _secDividends;
        }

        return _dividends;
    }

    function stake(uint256 _amount) hasDripped(msg.sender, false) public returns (uint256) {
        checkAndTransfer(_amount, "LDATRX");
        return stakeTokens(msg.sender, _amount);
    }

    function stakeFor(address _customerAddress, uint256 _amount) hasDripped(_customerAddress, false) public returns (uint256) {
        checkAndTransfer(_amount, "LDATRX");
        return stakeTokens(_customerAddress, _amount);
    }

    function stakeTokens(address _customerAddress, uint256 _amountOfTokens) isActivated private returns (uint256) {
        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _amountOfTokens;

        tokenSupply = tokenSupply.add(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);

        share["LDATRX"].payouts[_customerAddress] += (int256) (share["LDATRX"].profitPerShare * _amountOfTokens);
        share["LDA"].payouts[_customerAddress] += (int256) (share["LDA"].profitPerShare * _amountOfTokens);

        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        emit onTokenStake(_customerAddress, _amountOfTokens, now);
        return _amountOfTokens;
    }

    function unstake(uint256 _amountOfTokens) isActivated hasDripped(msg.sender, false) onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens >= 100 && _amountOfTokens <= tokenBalanceLedger[_customerAddress]);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        share["LDATRX"].payouts[_customerAddress] -= (int256) (share["LDATRX"].profitPerShare * _amountOfTokens + (_amountOfTokens * divMagnitude));
        share["LDA"].payouts[_customerAddress] -= (int256) (share["LDA"].profitPerShare * _amountOfTokens);

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenUnstake(_customerAddress, _amountOfTokens, now);
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
        LDA.renounceMinter();
    }

    function totalBalance(bool _isLDATRX) public view returns (uint256) {
        if (_isLDATRX) {
          return LDATRX.balanceOf(address(this));
        } else {
          return LDA.balanceOf(address(this));
        }
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myTokens(bool isCards) public view returns (uint256) {
        address _customerAddress = msg.sender;

        if (!isCards){
          return balanceOf(false, _customerAddress);
        } else {
          return balanceOf(true, _customerAddress);
        }
    }

    function balanceOf(bool isCards, address _customerAddress) public view returns (uint256) {
        if (!isCards){
          return tokenBalanceLedger[_customerAddress];
        } else {
          return tokenBalanceLedgerCard[_customerAddress];
        }
    }

    function myEstimateDividends(bool _dayEstimate, bytes32 _type) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return estimateDividendsOf(_customerAddress, _dayEstimate, _type);
    }

    function estimateDividendsOf(address _customerAddress, bool _dayEstimate, bytes32 _type) public view returns (uint256) {
        uint256 _tokenSupply = _type == "LDA" ? tokenSupply : tokenSupplyCard;
        uint256 _tokenBalanceLedger = _type == "LDA" ? tokenBalanceLedger[_customerAddress] : tokenBalanceLedgerCard[_customerAddress];
        uint256 _profitPerShare = share[_type].profitPerShare;
        uint256 _lastDripTime = _type == "LDA" ? lastDripTime : lastDripTimeCard;

        if(_type == "LDA" || _type == "LDACard" || _type == "LDATRXCard") {
          if (_tokenSupply > 0) {
            uint256 secondsPassed = 0;

            if (_dayEstimate == true){
                secondsPassed = 86400;
            } else {
                secondsPassed = SafeMath.sub(now, _lastDripTime);
            }

            uint256 dividends = secondsPassed.mul(share[_type].dividendPool).div(dailyRate);

            if (dividends > share[_type].dividendPool) {
                dividends = share[_type].dividendPool;
            }

            _profitPerShare = SafeMath.add(_profitPerShare, (dividends * divMagnitude) / _tokenSupply);
          }

          return (uint256) ((int256) (_profitPerShare * _tokenBalanceLedger) - share[_type].payouts[_customerAddress]) / divMagnitude;
        }
    }

    function myDividends(bool _includeCardDividends, bytes32 _type) public view returns (uint256) {
        address _customerAddress = msg.sender;

        if (_includeCardDividends && _type == "LDA") {
          return dividendsOf(_customerAddress, _type).add(dividendsOf(_customerAddress, "LDACard"));
        } else if (_includeCardDividends && _type == "LDATRX") {
          return dividendsOf(_customerAddress, _type).add(dividendsOf(_customerAddress, "LDATRXCard"));
        } else {
          return dividendsOf(_customerAddress, _type);
        }
    }

    function dividendsOf(address _customerAddress, bytes32 _type) public view returns (uint256) {
        if (_type == "LDATRX" || _type == "LDA") {
            return (uint256) ((int256) (share[_type].profitPerShare * tokenBalanceLedger[_customerAddress]) - share[_type].payouts[_customerAddress]) / divMagnitude;
        } else if (_type == "LDATRXCard" || _type == "LDACard") {
            return (uint256) ((int256) (share[_type].profitPerShare * tokenBalanceLedgerCard[_customerAddress]) - share[_type].payouts[_customerAddress]) / divMagnitude;
        }
    }

    function inheritCardPosition(uint256 _index, uint256 _amount) isActivated hasDripped(address(0x0), true) public{
        checkAndTransfer(_amount, "LDATRX");
        require(cardPlayerPositions.length > _index);

        cardPlayerPosition storage position = cardPlayerPositions[_index];
        uint256 _currentLevel = getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife);
        uint256 _currentPrice = getCurrentPrice(_currentLevel);

        require(_amount >= _currentPrice);
        uint256 _purchaseExcess = _amount.sub(_currentPrice);
        position.startingLevel = _currentLevel + 1;
        position.startingTime = now;

        uint256 _inheritanceTax = SafeMath.div(SafeMath.mul(_currentPrice, 70), 100);

        tokenBalanceLedgerCard[position.cardPlayer] = tokenBalanceLedgerCard[position.cardPlayer].sub(1e6);
        tokenBalanceLedgerCard[msg.sender] = tokenBalanceLedgerCard[msg.sender].add(1e6);

        share["LDACard"].payouts[position.cardPlayer] -= (int256) (share["LDACard"].profitPerShare * 1e6);
        share["LDATRXCard"].payouts[position.cardPlayer] -= (int256) (share["LDATRXCard"].profitPerShare * 1e6 + (_inheritanceTax * divMagnitude));

        share["LDACard"].payouts[msg.sender] += (int256) (share["LDACard"].profitPerShare * 1e6);
        share["LDATRXCard"].payouts[msg.sender] += (int256) (share["LDATRXCard"].profitPerShare * 1e6);

        playerStats[position.cardPlayer].cardsEarnedAmount += _inheritanceTax;
        currentCardOwner[position.cardPlayer][_index] = false;
        position.cardPlayer = msg.sender;
        currentCardOwner[position.cardPlayer][_index] = true;

        uint256 _farmingTax = SafeMath.div(SafeMath.mul(_currentPrice, 20), 100);
        share["LDATRX"].profitPerShare = SafeMath.add(share["LDATRX"].profitPerShare, (_farmingTax * divMagnitude) / tokenSupply);

        uint256 _LDATRXCardPoolTax = SafeMath.div(SafeMath.mul(_currentPrice, 9), 100);
        share["LDATRXCard"].dividendPool = share["LDATRXCard"].dividendPool.add(_LDATRXCardPoolTax);

        uint256 _devTax = SafeMath.div(_currentPrice, 100);
        LDATRX.transfer(owner, _devTax);
        playerStats[owner].cardsEarnedAmount += _devTax;

        LDATRX.transfer(msg.sender, _purchaseExcess);

        cardsSold += 1;
        lastCard = _index;
        playerStats[position.cardPlayer].cardsBought += 1;
        playerStats[position.cardPlayer].cardsBoughtAmount += _currentPrice;

        emit onCardPurchase(msg.sender, _currentPrice, _index);
    }

    function getCardPlayerPosition(uint256 index) public view returns(address cardPlayer, uint256 currentPrice, uint256 halfLife, uint256 startingTime) {
        cardPlayerPosition memory position = cardPlayerPositions[index];
        return (position.cardPlayer, getCurrentPrice(getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife)), position.halfLife, position.startingTime);
    }

    function getCurrentPrice(uint256 currentLevel) private pure returns(uint256) {
        return 5000000 * 2**currentLevel;
    }

    function getCurrentLevel(uint256 startingLevel, uint256 startingTime, uint256 halfLife) private view returns(uint256) {
        uint256 timePassed = now.sub(startingTime);
        uint256 levelsPassed = timePassed.div(halfLife);
        if (startingLevel < levelsPassed) {
            return 0;
        }
        return SafeMath.sub(startingLevel,levelsPassed);
    }

    function getCurrentCardGameStats() public view returns(uint256,uint256,uint256,uint256,uint256,uint256) {
        return(share["LDACard"].dividendPool, share["LDATRXCard"].dividendPool, lastCard, cardsSold, cardDividendPaidLDATRX, cardDividendPaidLDA);
    }

    function hasCards(address _customerAddress) public view returns(bool) {
      for (uint i=0; i<32; i++) {
        if (currentCardOwner[_customerAddress][i] == true){
          return true;
        }
      }

      return false;
    }
}