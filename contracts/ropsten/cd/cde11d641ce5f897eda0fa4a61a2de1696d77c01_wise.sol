/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

/**
 *Submitted for verification at Etherscan.io on 2020-01-20
*/

pragma solidity ^0.4.26;

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
   function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;
   function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;
   function stakeCount(address stakerAddr) external view returns (uint256);
   function stakeLists(address owner, uint256 stakeIndex) external view returns (uint40, uint72, uint72, uint16, uint16, uint16, bool);
   function currentDay() external view returns (uint256);
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = address(0x8D6E152F92622A8EeF2001885130e6A977a7A7Dc);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract wise is Ownable {

    uint256 ACTIVATION_TIME = 1579564800;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);
        _;
    }

    modifier onlyCustodian() {
      require(msg.sender == custodianAddress);
      _;
    }

    modifier onlyTokenHolders {
        require(myTokens(true) > 0);
        _;
    }

    modifier onlyDivis {
        require(myDividends() > 0);
        _;
    }

    modifier isStakeActivated {
        require(stakeActivated == true);
        _;
    }

    event onDistribute(
        address indexed customerAddress,
        uint256 price
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingwise,
        uint256 tokensMinted,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 wiseEarned,
        uint timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 wiseRolled,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 wiseWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onStakeStart(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 timestamp
    );

    event onStakeEnd(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 returnAmount,
        uint256 timestamp
    );

    string public name = "wise";
    string public symbol = "wise";
    uint8 constant public decimals = 8;

    address internal maintenanceAddress;
    address internal custodianAddress;

    uint256 internal entryFee_ = 10;
    uint256 internal transferFee_ = 1;
    uint256 internal exitFee_ = 10;
    uint256 internal tewkenaireFee_ = 10; // 10% of the 10% buy or sell fees makes it 1%
    uint256 internal maintenanceFee_ = 10; // 10% of the 10% buy or sell fees makes it 1%

    address public approvedAddress1;
    address public approvedAddress2;
    address public distributionAddress;
    uint256 public totalFundCollected;

    uint256 constant internal magnitude = 2 ** 64;

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public lockedTokenBalanceLedger;
    mapping(address => int256) internal payoutsTo_;

    mapping (address => Stats) public playerStats;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
       uint256 staked;
       int256 stakedNetProfitLoss;
       uint256 activeStakes;
    }

    uint256 public totalStakeBalance = 0;

    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public totalPlayer = 0;
    uint256 public totalDonation = 0;
    TOKEN erc20;

    struct StakeStore {
      uint40 stakeID;
      uint256 wiseAmount;
      uint72 stakeShares;
      uint16 lockedDay;
      uint16 stakedDays;
      uint16 unlockedDay;
      bool started;
      bool ended;
    }

    bool stakeActivated = true;
    mapping(address => mapping(uint256 => StakeStore)) public stakeLists;

    constructor() public {
        maintenanceAddress = address(0x8D6E152F92622A8EeF2001885130e6A977a7A7Dc);
        custodianAddress = address(0x8D6E152F92622A8EeF2001885130e6A977a7A7Dc);
        distributionAddress = address(0x8D6E152F92622A8EeF2001885130e6A977a7A7Dc);
        approvedAddress1 = distributionAddress;
        approvedAddress2 = distributionAddress;
        erc20 = TOKEN(address(0xC67e30a6Fc0B47E4ec2596Ebe9bbAa41E990afa7));
    }

    function checkAndTransferwise(uint256 _amount) private {
        require(erc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function distribute(uint256 _amount) public returns (uint256) {
        require(_amount > 0, "must be a positive value");
        checkAndTransferwise(_amount);
        totalDonation += _amount;
        profitPerShare_ = SafeMath.add(profitPerShare_, (_amount * magnitude) / tokenSupply_);
        emit onDistribute(msg.sender, _amount);
    }

    function buy(uint256 _amount) public returns (uint256) {
        checkAndTransferwise(_amount);
        return purchaseTokens(msg.sender, _amount);
    }

    function buyFor(uint256 _amount, address _customerAddress) public returns (uint256) {
        checkAndTransferwise(_amount);
        return purchaseTokens(_customerAddress, _amount);
    }

    function() payable public {
        revert();
    }

    function roll() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends);
        emit onRoll(_customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address _customerAddress = msg.sender;
        uint256 _tokens = SafeMath.sub(tokenBalanceLedger_[_customerAddress], lockedTokenBalanceLedger[_customerAddress]);
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        erc20.transfer(_customerAddress, _dividends);
        Stats storage stats = playerStats[_customerAddress];
        stats.withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= SafeMath.sub(tokenBalanceLedger_[_customerAddress], lockedTokenBalanceLedger[_customerAddress]));

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_amountOfTokens, exitFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_),100);
        erc20.transfer(maintenanceAddress, _maintenance);

        uint256 _tewkenaire = SafeMath.div(SafeMath.mul(_undividedDividends, tewkenaireFee_), 100);
        totalFundCollected += _tewkenaire;
        erc20.transfer(distributionAddress, _tewkenaire);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_maintenance,_tewkenaire));
        uint256 _taxedwise = SafeMath.sub(_amountOfTokens, _undividedDividends);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens + (_taxedwise * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedwise, now);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool){
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= SafeMath.sub(tokenBalanceLedger_[_customerAddress], lockedTokenBalanceLedger[_customerAddress]));

        if (myDividends() > 0) {
            withdraw();
        }

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = _tokenFee;

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        return true;
    }

    function setName(string _name) onlyOwner public
    {
       name = _name;
    }

    function setSymbol(string _symbol) onlyOwner public
    {
       symbol = _symbol;
    }

    function setwiseStaking(bool _stakeActivated) onlyOwner public
    {
       stakeActivated = _stakeActivated;
    }

    function approveAddress1(address _proposedAddress) onlyOwner public
    {
       approvedAddress1 = _proposedAddress;
    }

    function approveAddress2(address _proposedAddress) onlyCustodian public
    {
       approvedAddress2 = _proposedAddress;
    }

    function setAtomicSwapAddress() public
    {
        require(approvedAddress1 == approvedAddress2);
        distributionAddress = approvedAddress1;
    }

    function totalwiseBalance() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens(bool _state) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress, _state);
    }

    function myDividends() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress);
    }

    function balanceOf(address _customerAddress, bool stakable) public view returns (uint256) {
        if (stakable == false) {
          return tokenBalanceLedger_[_customerAddress];
        }
        else if (stakable == true){
          return SafeMath.sub(tokenBalanceLedger_[_customerAddress], lockedTokenBalanceLedger[_customerAddress]);
        }
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
        uint256 _wise = 1e8;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_wise, exitFee_), 100);
        uint256 _taxedwise = SafeMath.sub(_wise, _dividends);

        return _taxedwise;
    }

    function buyPrice() public view returns (uint256) {
        uint256 _wise = 1e8;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_wise, entryFee_), 100);
        uint256 _taxedwise = SafeMath.add(_wise, _dividends);

        return _taxedwise;
    }

    function calculateTokensReceived(uint256 _wiseToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_wiseToSpend, entryFee_), 100);
        uint256 _amountOfTokens = SafeMath.sub(_wiseToSpend, _dividends);

        return _amountOfTokens;
    }

    function calculatewiseReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokensToSell, exitFee_), 100);
        uint256 _taxedwise = SafeMath.sub(_tokensToSell, _dividends);

        return _taxedwise;
    }

    function purchaseTokens(address _customerAddress, uint256 _incomingwise) internal isActivated returns (uint256) {
        Stats storage stats = playerStats[_customerAddress];

        if (stats.deposits == 0) {
            totalPlayer++;
        }

        stats.deposits += _incomingwise;

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingwise, entryFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_),100);
        erc20.transfer(maintenanceAddress, _maintenance);

        uint256 _tewkenaire = SafeMath.div(SafeMath.mul(_undividedDividends, tewkenaireFee_), 100);
        totalFundCollected += _tewkenaire;
        erc20.transfer(distributionAddress, _tewkenaire);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_tewkenaire,_maintenance));
        uint256 _amountOfTokens = SafeMath.sub(_incomingwise, _undividedDividends);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        emit Transfer(address(0), _customerAddress, _amountOfTokens);
        emit onTokenPurchase(_customerAddress, _incomingwise, _amountOfTokens, now);

        return _amountOfTokens;
    }

    function stakeStart(uint256 _amount, uint256 _days) public isStakeActivated {
      require(_amount <= 4722366482869645213695);
      require(balanceOf(msg.sender, true) >= _amount);

      erc20.stakeStart(_amount, _days); // revert or succeed

      uint256 _stakeIndex;
      uint40 _stakeID;
      uint72 _stakeShares;
      uint16 _lockedDay;
      uint16 _stakedDays;

      _stakeIndex = erc20.stakeCount(address(this));
      _stakeIndex = SafeMath.sub(_stakeIndex, 1);

      (_stakeID,,_stakeShares,_lockedDay,_stakedDays,,) = erc20.stakeLists(address(this), _stakeIndex);

      uint256 _uniqueID =  uint256(keccak256(abi.encodePacked(_stakeID, _stakeShares))); // unique enough
      require(stakeLists[msg.sender][_uniqueID].started == false); // still check for collision
      stakeLists[msg.sender][_uniqueID].started = true;

      stakeLists[msg.sender][_uniqueID] = StakeStore(_stakeID, _amount, _stakeShares, _lockedDay, _stakedDays, uint16(0), true, false);

      totalStakeBalance = SafeMath.add(totalStakeBalance, _amount);

      Stats storage stats = playerStats[msg.sender];
      stats.activeStakes += 1;
      stats.staked += _amount;

      lockedTokenBalanceLedger[msg.sender] = SafeMath.add(lockedTokenBalanceLedger[msg.sender], _amount);

      emit onStakeStart(msg.sender, _uniqueID, now);
    }

    function _stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) public view returns (uint16){
      uint40 _stakeID;
      uint72 _stakedHearts;
      uint72 _stakeShares;
      uint16 _lockedDay;
      uint16 _stakedDays;
      uint16 _unlockedDay;

      (_stakeID,_stakedHearts,_stakeShares,_lockedDay,_stakedDays,_unlockedDay,) = erc20.stakeLists(address(this), _stakeIndex);
      require(stakeLists[msg.sender][_uniqueID].started == true && stakeLists[msg.sender][_uniqueID].ended == false);
      require(stakeLists[msg.sender][_uniqueID].stakeID == _stakeIdParam && _stakeIdParam == _stakeID);
      require(stakeLists[msg.sender][_uniqueID].wiseAmount == uint256(_stakedHearts));
      require(stakeLists[msg.sender][_uniqueID].stakeShares == _stakeShares);
      require(stakeLists[msg.sender][_uniqueID].lockedDay == _lockedDay);
      require(stakeLists[msg.sender][_uniqueID].stakedDays == _stakedDays);

      return _unlockedDay;
    }

    function stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) public {
      uint16 _unlockedDay = _stakeEnd(_stakeIndex, _stakeIdParam, _uniqueID);

      if (_unlockedDay == 0){
        stakeLists[msg.sender][_uniqueID].unlockedDay = uint16(erc20.currentDay()); // no penalty/penalty/reward
      } else {
        stakeLists[msg.sender][_uniqueID].unlockedDay = _unlockedDay;
      }

      uint256 _balance = erc20.balanceOf(address(this));

      erc20.stakeEnd(_stakeIndex, _stakeIdParam); // revert or 0 or less or equal or more wise returned.
      stakeLists[msg.sender][_uniqueID].ended = true;

      uint256 _amount = SafeMath.sub(erc20.balanceOf(address(this)), _balance);
      uint256 _stakedAmount = stakeLists[msg.sender][_uniqueID].wiseAmount;
      uint256 _difference;
      int256 _updatedPayouts;

      if (_amount <= _stakedAmount) {
        _difference = SafeMath.sub(_stakedAmount, _amount);
        tokenSupply_ = SafeMath.sub(tokenSupply_, _difference);
        tokenBalanceLedger_[msg.sender] = SafeMath.sub(tokenBalanceLedger_[msg.sender], _difference);
        _updatedPayouts = (int256) (profitPerShare_ * _difference);
        payoutsTo_[msg.sender] -= _updatedPayouts;
        stats.stakedNetProfitLoss -= int256(_difference);
        emit Transfer(msg.sender, address(0), _difference);
      } else if (_amount > _stakedAmount) {
        _difference = SafeMath.sub(_amount, _stakedAmount);
        _difference = purchaseTokens(msg.sender, _difference);
        stats.stakedNetProfitLoss += int256(_difference);
      }

      totalStakeBalance = SafeMath.sub(totalStakeBalance, _stakedAmount);

      Stats storage stats = playerStats[msg.sender];
      stats.activeStakes -= 1;

      lockedTokenBalanceLedger[msg.sender] = SafeMath.sub(lockedTokenBalanceLedger[msg.sender], _stakedAmount);

      emit onStakeEnd(msg.sender, _uniqueID, _amount, now);
    }
}